-- make gui
-- update checkpoint on add mark
-- fix 'rmk move' doesn't add heading

RouteMaker = {}

function RouteMaker:new(object)
    object = object or {
    
        Route = {
            checkpoints = {},
            cars = {},
            finish = {}
        },
        show_checkpoints = false,
        Mode = 'off', 
        OldMode = nil,
        Target = nil 
    }
    
    setmetatable(object, self)
    self.__index = self

    return object
end

function RouteMaker:AddMark(Pos , Heading , Type) -- return true if mode exits
    Type = Type or self.Mode

    if self.Mode == 'move' then
        self:MoveSelectedMark(Pos)
        return true
    end


    if Type == 'checkpoints' then 
        
        table.insert(self.Route.checkpoints,#self.Route.checkpoints+1,{
            Blip = AddBlip(Pos,1,0,255,#self.Route.checkpoints+1,nil,"Checkpoint"),
            Pos = Pos
        })

    elseif Type == 'cars' then
        table.insert(self.Route.cars,#self.Route.cars+1,{
            Blip = AddBlip(Pos,669,0,255,#self.Route.cars+1,nil,"Start pos"),
            Pos = Pos,
            Heading = Heading
        })

    elseif Type == 'finish' then

        if self.Route.finish.Blip == nil then
            self.Route.finish.Blip = AddBlip(Pos,38,0,255,nil,nil,"Finish Line")
        end
        
        self.Route.finish.Pos = Pos
        SetBlipCoords(self.Route.finish.Blip,Pos.x,Pos.y,Pos.z)

    end

    return true
end


function RouteMaker:RemoveMark(Target)

    if self.Mode == 'checkpoints' or self.Mode == 'cars' then

        local mark = self.Route[self.Mode][Target]
        
        if mark == nil then
            return false
        end

        RemoveBlip(mark.Blip) -- remove blip
        table.remove(self.Route[self.Mode],target) -- remove target from array
        
        for i , v in ipairs(self.Route[self.Mode]) do
            ShowNumberOnBlip(v.Blip,i) -- realign number on blip
        end

        return true

    elseif self.Mode == 'finish' then
        
        RemoveBlip(self.Route.finish.Blip)
        self.Route.finish = {}

    end
    
    return false

end

function RouteMaker:SelectMark(Target)
    self:ClearSelectMark()

    if self.Mode == 'checkpoints' or self.Mode == 'cars' then

        local mark = self.Route[self.Mode][Target]
        
        if mark == nil then
            return false
        end
        
        SetBlipColour(mark.Blip,5)
        
        self.OldMode = self.Mode
        self.Target = {
            set = function(pos) 
                local t = self.Route[self.OldMode][Target] 
                self.Route[self.OldMode][Target].Pos = pos
                SetBlipCoords(t.Blip,pos.x,pos.y,pos.z)
                SetBlipColour(t.Blip,0)
            end
        }
        self.Mode = 'move'
    elseif self.Mode == 'finish' then
        
        SetBlipColour(self.Route.finish.Blip,5)

        self.Target = {
            set = function(pos) 
                self.Route.finish.Pos = pos
                SetBlipCoords(self.Route.finish.Blip,pos.x,pos.y,pos.z)
                SetBlipColour(self.Route.finish.Blip,0)
            end
        }

        self.Mode = 'move'
    end

end

function RouteMaker:ClearSelectMark()
    if self.Target ~= nil then
        SetBlipColour(self.Target.Blip,0)
        self.Target = nil
    end
end

function RouteMaker:MoveSelectedMark(Pos)
    if self.Target == nil then 
        return false
    end
    
    self.Target.set(Pos)
    self.Mode = self.OldMode
    self.OldMode = nil
    return true
end

function RouteMaker:SelectMode(Mode)

    if Mode == 'cps' or Mode == 'checkpoints' then
        self.Mode = 'checkpoints'
    elseif Mode == 'cars' then
        self.Mode = 'cars'
    elseif Mode == 'fn' or Mode == 'finish' then
        self.Mode = 'finish'
    elseif Mode == 'off' then
        self.Mode = 'off'
    else
        return false
    end
    
    return true
end

function RouteMaker:Clear()

    if self.show_checkpoints == true then
        self:ClearCheckpoints()
    end

    for i , v in ipairs(self.Route.checkpoints) do
        RemoveBlip(v.Blip)
    end
    
    self.Route.checkpoints = {}

    for i , v in ipairs(self.Route.cars) do
        RemoveBlip(v.Blip)
    end

    self.Route.cars = {}

    RemoveBlip(self.Route.finish.Blip)
    self.Route.finish = {}

   

end

function RouteMaker:Export( Name , Title )
    local route = self.Route
    
    for i , v in ipairs(route.checkpoints) do
        v.Blip = nil
        v.Checkpoint = nil
    end

    for i , v in ipairs(route.cars) do
        v.Blip = nil
        v.Checkpoint = nil
    end
    
    route.finish.Blip = nil
    route.finish.checkpoint = nil

    route.Name = Name
    route.Title = Title
    
    return json.encode(route)

end

function RouteMaker:LoadRoute ( Route )
    
    if Route == nil then
        return
    end

    self:Clear()

    for i , v in ipairs(Route.checkpoints) do
        self:AddMark(vector3(v.Pos.x,v.Pos.y,v.Pos.z), nil , "checkpoints")
    end
    
    for i , v in ipairs(Route.cars) do
        self:AddMark(vector3(v.Pos.x,v.Pos.y,v.Pos.z), nil , "cars")
    end
    if Route.finish ~= nil then
        self:AddMark(vector3(Route.finish.Pos.x,Route.finish.Pos.y,Route.finish.Pos.z), Route.finish.heading , "finish")
    end
end

function RouteMaker:ShowCheckpoints()
    self.show_checkpoints = true
    for i , v in ipairs(self.Route.checkpoints) do
        if v.Checkpoint == nil then
            
            local Pos = v.Pos
            local Dest = vector3(0,0,0)
            if i < #self.Route.checkpoints then
                Dest = self.Route.checkpoints[i+1].Pos
            end
            
            v.Checkpoint = AddCheckpoint(0,0,Pos, Dest,10.0,255,255,255)
        end

    end

    for i , v in ipairs(self.Route.cars) do
        if v.Checkpoint == nil then
            v.Checkpoint = AddCheckpoint(44,i,v.Pos, vector3(0,0,0),5.0,100,100,255)
        end

    end

end

function RouteMaker:ClearCheckpoints()
    self.show_checkpoints = false
    for i , v in ipairs(self.Route.checkpoints) do
        DeleteCheckpoint(v.Checkpoint)
        v.Checkpoint = nil
    end

    for i , v in ipairs(self.Route.cars) do
        DeleteCheckpoint(v.Checkpoint)
        v.Checkpoint = nil
    end
end


RMK = RouteMaker:new()


RegisterCommand('rmk' , function(source , args , rawCommand)
    if #args == 0 then
        print('invalid usesed (need atleast 1 recive 0)')
        return
    end
    
    local cmd = args[1]

    if cmd == 'type' then 

        local type = args[2]
        
        if type == nil then
            print('invalid usesed (need atleast 2 recive 1)')
            return
        end
        
        if RMK:SelectMode(type) == false then
            print('invalid mode')
        end

    elseif cmd == 'rm' or cmd == 'remove' then

        local target = tonumber(args[2])
        if target == nil then
            print('invalid usesed for checkpoint or car type (need atleast 2 recive 1)')
            return
        end

        if RMK:RemoveMark(target) == false then
            print('invalid target')
        end

    elseif cmd == 'mv' or cmd == 'move' then

        local target = tonumber(args[2])
        if target == nil then
            print('invalid usesed for checkpoint or car type (need atleast 2 recive 1)')
            return
        end

        RMK:SelectMark(target)
    elseif cmd == 'me' then 
        
        local local_ped = GetPlayerPed(-1)
        if local_ped == nil then
            print('local_ped == nil (what?)')
            return
        end

        local ped_pos = GetEntityCoords(local_ped)
        local _ , ground_pos = GetGroundZFor_3dCoord(ped_pos.x, ped_pos.y, 99999.0, 1) -- it's just work


        RMK:AddMark( vector3(ped_pos.x, ped_pos.y,ground_pos), GetEntityHeading(local_ped))

    elseif cmd == 'fixground' or cmd == 'fg' then
        for i , v in ipairs(RMK.Route.checkpoints) do
            local _ , ground_pos = GetGroundZFor_3dCoord(v.Pos.x, v.Pos.y, 99999.0, 1) -- it's just work
            v.Pos = vector3(v.Pos.x, v.Pos.y,ground_pos)
        end

        for i , v in ipairs(RMK.Route.cars) do
            local _ , ground_pos = GetGroundZFor_3dCoord(v.Pos.x, v.Pos.y, 99999.0, 1) -- it's just work
            v.Pos = vector3(v.Pos.x, v.Pos.y,ground_pos)
        end

        local p = RMK.Route.finish.Pos
        local _ , ground_pos = GetGroundZFor_3dCoord(p.x, p.y, 99999.0, 1) -- it's just work
        local Pos = vector3(p.x, p.y,ground_pos)
        RMK.Route.finish.Pos = Pos


    elseif cmd == 'submit' then
        TriggerServerEvent('sv_rmk:submit',RMK:Export(),args[2],args[3])
    elseif cmd == 'show' then
        local type = args[2]
        if type == 'checkpoint' or type == 'cp' then
            if RMK.show_checkpoints == false then
                RMK:ShowCheckpoints()
            else
                RMK:ClearCheckpoints()
            end

        end
    elseif cmd == 'load'then

        TriggerEvent('cl_routes:get_route' , args[2] , function(route)
            RMK:LoadRoute(route)
        end)

    elseif cmd == 'clear' then
         RMK:Clear()
    else
        print('invalid cmd')
    end

end)




Citizen.CreateThread(function() -- Waypoint mark mode
    while true do 
        if IsWaypointActive() and RMK.Mode ~= 'off' then
            local waypoint = GetFirstBlipInfoId(8)
            local wp_pos = GetBlipInfoIdCoord(waypoint)
            local _ , ground_pos = GetGroundZFor_3dCoord(wp_pos.x, wp_pos.y, 99999.0, 1) -- it's just work
            local Pos = vector3(wp_pos.x, wp_pos.y,ground_pos)

            if RMK:AddMark(Pos) then
                SetWaypointOff()
            end
        end
        Citizen.Wait(100) -- Always put Wait in loop or else.
    end
end)
