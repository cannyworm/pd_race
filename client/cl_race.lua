-- https://vespura.com/fivem/scaleform/#RACE_POSITION
-- win screen
-- move count down to cl_scalforms 
-- re align function to proper order
-- don't clean up untill x secound

local _C = RaceConfig
local _cp = _C.Checkpoint
local _fn = _C.Finishline

CRace = {}

function CRace:new(object)

    object = object or {}

    object.id = nil -- match id lol
    object.rmk = RouteMaker:new()
    
    object.running = nil
    object.route = nil
    object.server_id = nil
    object.local_key = nil
    object.checkpoints = {} -- for preview
    object.blips = {}
    object.target_checkpoint = nil -- for actual game
    
    object.small_blip = nil -- for next target
    object.big_blip = nil -- for current target
    object.start_time = nil
    object.lap_time = nil
    object.draw_timer = nil
    
    setmetatable(object, self)
    self.__index = self

    return object

end


function CRace:SetRoute(route)
    self.route = route
end

-- because bad design lol
function CRace:SetMatchId(id)
    self.id = id
end

function CRace:GetCheckpointCoords(i)
    if i < #self.route.checkpoints then -- next target is checkpoint
        return  self.route.checkpoints[i].Pos , self.route.checkpoints[ i + 1 ].Pos 
    elseif i == #self.route.checkpoints then
        if self.use_finishline == true then
            return self.route.checkpoints[i].Pos  , self.route.finish.Pos
        else
            return self.route.checkpoints[i].Pos  , self.route.checkpoints[1].Pos 
        end
    elseif i > #self.route.checkpoints then
        return select(2,self:GetCheckpointCoords(i-1)) , nil
    end
end

function CRace:UpdateCheckpoint()
    if self.target_checkpoint ~= nil then
        DeleteCheckpoint(self.target_checkpoint)
    end
    
    local localpl = self:GetLocalPlayer()

    local coords , next_coords = self:GetCheckpointCoords(localpl.checkpoint+1)
    if localpl.checkpoint + 1 > #self.route.checkpoints and localpl.laps == self.max_laps - 1 then
        self.show_finishline = true
        self.target_checkpoint = AddCheckpoint(_fn.Type,0,coords, next_coords,_fn.Size,_fn.Color.r,_fn.Color.g,_fn.Color.b,_fn.Color.a)
        SetCheckpointCylinderHeight(self.target_checkpoint,_fn.Height,_fn.Height,_fn.Size)
    else
        
        self.target_checkpoint = AddCheckpoint(_cp.Type,0,coords, next_coords,_cp.Size,_cp.Color.r,_cp.Color.g,_cp.Color.b,_cp.Color.a)
        SetCheckpointCylinderHeight(self.target_checkpoint,_cp.Height,_cp.Height,_cp.Size)
    end        
end

function CRace:ClearCheckpoint()
    for i , v in ipairs(self.checkpoints) do
        DeleteCheckpoint(v)
    end
    DeleteCheckpoint(self.target_checkpoint)
end

function CRace:UpdateBlips()
    local localpl = self:GetLocalPlayer()
    local coords , next_coords = self:GetCheckpointCoords(localpl.checkpoint+1)
    
    if self.big_blip == nil then
        self.big_blip = AddBlip(coords,1,5,255,nil,1.0)
    end

    if self.small_blip == nil then
        self.small_blip = AddBlip(next_coords,1,5,190,nil,0.8)
        SetBlipAsShortRange(self.small_blip, true)
    end

    SetBlipCoords(self.big_blip,coords.x,coords.y,coords.z)
    if next_coords ~= nil then
        SetBlipCoords(self.small_blip,next_coords.x,next_coords.y,next_coords.z)
    end

    if localpl.checkpoint + 1 > #self.route.checkpoints and localpl.laps == self.max_laps - 1 then -- last check point
        RemoveBlip(self.small_blip)
        self.small_blip = nil
    end

end

function CRace:ClearBlips()
    RemoveBlip(self.small_blip)
    self.small_blip = nil
    RemoveBlip(self.big_blip)
    self.big_blip = nil
end

function CRace:Clear()
    self:StopTimer()
    self:ClearCheckpoint()
    self:ClearBlips()
    Citizen.Wait(500)

    self.running = nil
    self.started = nil
    
    self.route = nil
    self.server_id = nil
    self.local_key = nil
    self.checkpoints = {} -- for preview
    self.blips = {}
    self.target_checkpoint = nil -- for actual game
    
    self.small_blip = nil -- for next target
    self.big_blip = nil -- for current target

end


-- load from server side struct
function CRace:LoadSVRace(sv)
    
    self.id = sv.id
    self.server_id = GetPlayerServerId(PlayerId())
    
    self.max_laps  = sv.max_laps
    self.use_finishline  = sv.use_finishline
    
    self.playerlist  = sv.playerlist
    self.localplayer = desk.find( self.playerlist , function (v , k) return v.id == self.server_id end)

    for k , v in ipairs(self.playerlist) do
        v.ent = GetPlayerPed(GetPlayerFromServerId(v.id))
        v.veh = GetVehiclePedIsIn(v.ent,false)
    end

    self.route = sv.route
end

function CRace:GetLocalPlayer()
    return self.localplayer
end

function CRace:UpadtePlayer(keys , data)    
    local player = desk.find( self.playerlist , function (v , k) return v.id == data.id end)

    if keys[1] == 'checkpoint' then
        player.checkpoint = data.value
        if data.id == self.server_id then
            self:UpdateCheckpoint()
            self:UpdateBlips()
            PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS")
        end
    elseif keys[1] == 'laps' then
        player.laps = data.value
    elseif keys[1] == 'finish' then
        player.finish = true
        
        if data.id == self.server_id then
            AnimpostfxPlay("MinigameEndNeutral", 0, 0)
            PlaySoundFrontend(-1, "SCREEN_FLASH", "CELEBRATION_SOUNDSET")
            self:MpMessageShow(data.place .. ' place', GetTimeAsString(GetNetworkTime() - self.start_time),5000)
            self:Clear()
        end
    
    end


end

function CRace:NetUpdate( keys , data)
    sv_net_update('match' , { self.id , 'race' , table.unpack(keys) } , data)
end

function CRace:Init()
    self.big_message = scaleform:new('mp_big_message_freemode',true)
    self.countdown_scalfrom = scaleform:new('countdown',true)
    
    self:NetUpdate({'player' , 'ready'})
end


function CRace:Start() -- only get called from server because fuck client
    self.running = true

    Citizen.CreateThread(function() -- main thread

        self.countdown_scalfrom:start_render()
        self:UpdateCheckpoint()
        self:UpdateBlips()
        
        SetVehicleBurnout(self:GetLocalPlayer().veh, true)
        
        while self.running == true do
            Citizen.Wait(0)
        
            if self.started == true then    
                self.pos = 1
                local localpl = self:GetLocalPlayer()
                for k , v in ipairs(self.playerlist) do
                    
                    if v.id ~= self.server_id then
                        
                        if v.checkpoint > localpl.checkpoint then
                            self.pos = self.pos + 1
                        elseif v.checkpoint == localpl.checkpoint then
                            local cpcoords , next = self:GetCheckpointCoords(v.checkpoint) 
                            if #(next - GetEntityCoords(v.ent)) > #(next -  GetEntityCoords(localpl.ent)) then
                                self.pos = self.pos + 1
                            end
                        end

                    end 

                end
            end

        end
    end)
end

function CRace:MpMessageShow(message, subtitle, ms) 
    self.big_message:call_func('SHOW_SHARD_CENTERED_MP_MESSAGE',message,subtitle,1)
    self.big_message:render_for(ms)
end

function CRace:CountdownShow(str , r ,g ,b ) 
    self.countdown_scalfrom:call_func('SET_MESSAGE', str , r , g , b , true)
end

function CRace:StartTimer()
    self.start_time = GetNetworkTime()
    self.lap_time = GetNetworkTime()
    self.draw_timer = true
        
    Citizen.CreateThread(function()
        while self.draw_timer == true do
            
            Citizen.Wait(0)
            local cur_time = GetNetworkTime()
            local localpl = self:GetLocalPlayer()
            if localpl == nil or self.route == nil then return end

            DrawTextBar('Checkpoints' , string.format('%d/%d',localpl.checkpoint,#self.route.checkpoints ),4)
            DrawTextBar('Pos' , string.format('%d/%d',self.pos,#self.playerlist),3)
            DrawTextBar('Lap' , string.format('%d/%d',localpl.laps+1,self.max_laps) ,2)
            DrawTimerBar('Time',(cur_time - self.start_time),1)
        end
    end)
end

function CRace:StopTimer()
    self.draw_timer = false
end

Race = nil

AddEventHandler('pd_race:cl_net_update' , function(target , keys , data)
    
    if target == 'race' then
        
        print('[race]', json.encode(keys) , json.encode(data))

        if keys[1] == 'initialize' then
            Race = nil
            Race = CRace:new()
            Race:LoadSVRace(data.race)
            Race:Init()
        elseif keys[1] == 'cleanup' then
            Race = nil
        elseif keys[1] == 'start' then
            Race.started = true
            Race:Start()
        elseif keys[1] == 'countdown' then
            Race:CountdownShow(data.max - data.value,0,0,0)
            
        elseif keys[1] == 'go' then
            SetVehicleBurnout(Race:GetLocalPlayer().veh, false)

            Race:CountdownShow('GO',0,255,0)
            Race:StartTimer()

        elseif keys[1] == 'player' then

            if Race:UpadtePlayer( {table.unpack(keys,2)} , data) == false then
                print('[race] self:UpadtePlayer return false')
            end

        elseif keys[1] == 'playerlist' then
            -- call once before 
            if keys[2] == 'init' then
                Race.playerlist = data.race.playerlist
            end
            
        end
    end

end)



