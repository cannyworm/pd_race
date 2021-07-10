-- problem 
-- recode netupdate handeling
-- kick player out if player isn't in a vehicle

SRace = {}

SRace.estatus = {
    disconnect = -1,
    loading = 0,
    ready = 1,
    playing = 2
}

function SRace:new(object)
    object = object or {}

    object.id = nil
    object.playerlist = {}
    object.route = {}
    object.running = false
    object.max_laps = 1
    object.use_finishline = false -- set to false will use first check point as finish line
    object.finish_count = 0
    object.countdown = 5
    object.finish = false -- match is finish
    object.status = 'loading'
    
    setmetatable(object, self)
    self.__index = self

    return object
end

function SRace:Clear()
    self.stop = true
    self.playerlist = {}
    self.finish_count = 0
end


function SRace:SetMaxLaps(laps)
    self.max_laps = laps
end
function SRace:SetUseFinishline(use_finishline)
    if self.route.finish == nil then
        return false
    end
    self.use_finishline = use_finishline
    return true
end


function SRace:AddPlayer(player)
    
    if desk.find(self.playerlist , function(v) return v.id == player end) ~= nil then 
        return false
    end

    table.insert(self.playerlist,#self.playerlist+1,{
        id = player, -- player indentify
        ent = GetPlayerPed(player),
        veh = GetVehiclePedIsIn(GetPlayerPed(player),false),
        checkpoint = 0, -- start at 0 because lua start index at 1
        laps = 0, -- current laps
        finish = false, -- finish this race
        status = self.estatus.loading --[[
            loading : client still loading 
            ready : client send ready event 
            playing : in match
            disconnect : do as it named
        ]] 
    })
end

function SRace:AddPlayers(playerlist)
    for k , v in ipairs(playerlist) do
        self:AddPlayer(v.id)
    end
end

function SRace:RemovePlayer(player , option)
    local v , k = desk.find(self.playerlist , function(v) return v.id == player end)
    if v == nil then 
        return false
    end
    
    if option.RemoveCar == true then
        if DoesEntityExist(v.veh) then
            DeleteVehicle(v.veh)
        end
    end

    table.remove(self.playerlist,k)
end


-- SRace:Update~ will return true if player need update
function SRace:UpdatePlayerCheckpoint(v)
    
    local player = v.id
    local ent = GetPlayerPed(player)
    local ent_coords = GetEntityCoords(ent)
    
    local next_coords = nil 
    local size = nil
    
    if v.checkpoint < #self.route.checkpoints then -- next target is chekcpoint
        next_coords = self.route.checkpoints[ v.checkpoint  + 1].Pos 
        size = RaceConfig.Checkpoint.Size
    elseif self.use_finishline == true then
        next_coords = self.route.finish.Pos
        size = RaceConfig.Finishline.Size
    else
        next_coords = self.route.checkpoints[1].Pos 
        size = RaceConfig.Checkpoint.Size
    end

    local distance = #(next_coords - ent_coords)
    
    if distance < size then
        v.checkpoint = v.checkpoint + 1
        return true
    end
    
    return false

end


function SRace:NetClientUpdate(client , keys , data)
    TriggerClientEvent('pd_race:cl_net_update', client , 'match' , {'race' , table.unpack(keys) } , data)
end

function SRace:NetAllClientUpdate( keys , data)
    
    if #self.playerlist == 0 then
        return
    end

    for k , v in ipairs(self.playerlist) do
        self:NetClientUpdate(v.id,keys,data)
    end
end

function SRace:UpdatePlayer()
    for i , v in ipairs(self.playerlist) do

        if v.finish == false  then 
        
            if self:UpdatePlayerCheckpoint(v) then

                if v.checkpoint > #self.route.checkpoints then -- if player past last checkpoint
                    v.laps = v.laps + 1 -- inc laps count
    
                    if v.laps >= self.max_laps then 
                        self.finish_count = self.finish_count + 1
                        v.finish = true
                        self:NetAllClientUpdate( {'player' , 'finish'}  , { id = v.id , place = self.finish_count  }) -- win                
                        SetVehicleDoorsLocked(v.veh , 6)
        
                    else 
                        v.checkpoint = 0 -- reset checkpoint
                        self:NetAllClientUpdate({'player' ,  'laps' }, { id = v.id , value = v.laps })
                    end  
                end
                if v.checkpoint <= #self.route.checkpoints  then
                    self:NetAllClientUpdate({'player','checkpoint'}  , { id = v.id , value = v.checkpoint })
                end
            end
        
        end
        
    end
end

function SRace:SetPos()
    for i , v in ipairs(self.playerlist) do
        local pos = self.route.cars[i].Pos
        local heading = self.route.cars[i].Heading
        if v.veh ~= nil then
            SetVehicleDoorsLocked(v.veh,6)
            SetEntityCoords(v.veh,pos.x,pos.y,pos.z,true,false,false)
            SetEntityHeading(v.veh,heading)
        end
    end
end

function SRace:Start()
    for i , v in ipairs(self.playerlist) do
        v.veh = GetVehiclePedIsIn(v.ent,false)
    end

    self:NetAllClientUpdate( {'init'} , { race = self} ) -- start Initialize CRace         
    
    -- anti cheat ?

    self:SetPos()
    self:Run()
end

function SRace:Run()
    self.running = true
    Citizen.CreateThread(function()
        while self.running == true do
            
            if self.started == true then
                self:UpdatePlayer()

                if self:ShoulStop() == true then
                    self:NetAllClientUpdate( {'cleanup'} )
                    self:Clear()
                    self.running = false
                    self.finish = true
                    return
                end
            end

            Citizen.Wait(0)
        end
    end)
end

function SRace:SetId(id)
    self.id = id
end

function SRace:ShoulStop()
    if self.stop == true then
        self.stop = false
        return true
    end
    for i , v in ipairs(self.playerlist) do
        if v.finish == false then
            return false
        end
    end
    return true
end

function SRace:StartCountdown()
    Citizen.CreateThread(function()
        local start_time = GetGameTimer()
        local countdown = 0
        self:NetAllClientUpdate({'countdown'} , {value = countdown , max = self.countdown})
        
        while true do
            Citizen.Wait(0)
        
            local current_time = GetGameTimer()
            local time_diff = current_time - start_time

            if time_diff > 1000 then
                countdown = countdown + 1
                
                if countdown == self.countdown then
                    break
                end

                start_time = current_time
                self:NetAllClientUpdate({'countdown'} , {value = countdown , max = self.countdown})
            end

       
        end

        -- anti cheat
        -- self:SetPos()
        self.started = true
        self:NetAllClientUpdate({'go'})

    end)
end


-- return false if id didn't exits
function SRace:NetPlayerUpdate(source , keys , data)
    local player  = desk.find( self.playerlist , function (v , k) 
        return v.id == source 
    end)
    local target = keys:pop()
    if target == 'ready' then -- client finish initialize CRace
        if player.status == self.estatus.ready then return true end

        player.status = self.estatus.ready
        
        for _ , pl in ipairs(self.playerlist) do
            if pl.status ~= self.estatus.ready then
                return false
            end
        end

        self:NetAllClientUpdate({'start'})
        self:StartCountdown()
    else
        return false
    end

    return true
end


function SRace:NetHandle( src , keys , data)
    local target = keys:pop()
    if target == 'player' then
        if self:NetPlayerUpdate(src , keys , data) == false then
            -- TODO error handling : invalid player
        end
    else
        -- TODO error handling : invalid target
    end
end

