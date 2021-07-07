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
    table.insert(self.playerlist,#self.playerlist+1,{
        id = player, -- player indentify
        ent = GetPlayerPed(player),
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
    TriggerClientEvent('pd_race:cl_net_update', client , 'race' , keys , data)
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
        if v.finish == false then 
        
            if self:UpdatePlayerCheckpoint(v) then

                if v.checkpoint > #self.route.checkpoints then -- if player past last checkpoint
                    v.laps = v.laps + 1 -- inc laps count
    
                    if v.laps >= self.max_laps then 
                        self.finish_count = self.finish_count + 1
                        v.finish = true
                        self:NetAllClientUpdate( {'player' , 'finish'}  , { id = v.id , place = self.finish_count  }) -- win
                        
                        SetVehicleDoorsLocked(v.veh , 0)
                        
                    else 
                        v.checkpoint = 0 -- reset checkpoint
                        self:NetAllClientUpdate({'player' ,  'laps' }, { id = v.id , value = v.laps })
                    end  
                end

                self:NetAllClientUpdate({'player','checkpoint'}  , { id = v.id , value = v.checkpoint })
            end
        
        end
        
    end
end

function SRace:SetPos()
    for i , v in ipairs(self.playerlist) do
        local pos = self.route.cars[i].Pos
        local heading = self.route.cars[i].Heading
        if v.veh ~= nil then
            SetVehicleDoorsLocked(v.veh , 10)
            SetEntityCoords(v.veh,pos.x,pos.y,pos.z,true,false,false)
            SetEntityHeading(v.veh,heading)
        end
    end
end

function SRace:Start()
    
    self:NetAllClientUpdate( {'initialize'} , { race = self} ) -- start Initialize CRace         
    
    for i , v in ipairs(self.playerlist) do
        v.veh = GetVehiclePedIsIn(v.ent,false)
    end


    self:SetPos()
    Citizen.Wait(1000)
    self:Run()
end

function SRace:Run()
    self.running = true
    Citizen.CreateThread(function()
        while self.running == true do
            
            if self.started == true then
                self:UpdatePlayer()

                if self:ShoulStop() == true then
                    self:Clear()
                    self:NetAllClientUpdate( {'cleanup'} )
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
                    self:NetAllClientUpdate({'go'})
                    break
                end

                start_time = current_time
                self:NetAllClientUpdate({'countdown'} , {value = countdown , max = self.countdown})
            end

       
        end

        self:SetPos()
        self.started = true
        self:NetAllClientUpdate({'go'})

    end)
end


-- return false if id didn't exits
function SRace:NetPlayerUpdate(source , keys , data)
    local pl_id = source
    local v , pl_key = desk.find( self.playerlist , function (v , k) 
        return v.id == pl_id 
    end)

    if keys[1] == 'ready' then -- client finish initialize CRace
        if v.status == self.estatus.ready then return false end

        v.status = self.estatus.ready
        
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


function SRace:net_update( source , keys , data)
    if keys[1] == 'player' then
        if self:NetPlayerUpdate(source , { table.unpack(keys,2)  }, data) == false then
            print(string.format('SRace:NetPlayerUpdate(%d,%s,%s) return false',source,json.encode(keys),json.encode(data)))
        end
    else
        return false
    end
    return true
end

