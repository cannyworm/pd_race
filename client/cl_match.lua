-- server doesn't know what match we are in
-- check file netcode

CMatch = {}
Matchlist = {}

function CMatch:new(object,shared)
    
    object = object or {}
    object.shared = shared
    object.race = CRace:new({},object)

    setmetatable(object, self)
    self.__index = self
    return object
end


function CMatch:SetRoute( route )
    self.route = route
end

function CMatch:Clear()
    self.race:Clear()
end

function CMatch:NetUpdate( keys , data)
    sv_net_update('match' , { self.id , table.unpack(keys) } , data)
end

function CMatch:NetCreate(name , password , route_id , use_finishline , max_players , max_laps )
    sv_net_update('matchlist',{'create'}, {
         name = name,
         password = password , 
         route_id = route_id, 
         use_finishline = use_finishline,
         max_players = max_players,
         max_laps = max_laps
    })
end

function CMatch:NetJoin( id ,password )
    sv_net_update('matchlist',{'join'}, {
         id = id, 
         password = password
    })
end

function CMatch:NetLeave( )
    sv_net_update('matchlist',{'leave'})
end

function CMatch:NetSetRouteById( route_Id )
    self:NetUpdate({'update' , 'route'} , {value = route_Id})
end

function CMatch:NetSetName( Name )
    self:NetUpdate({'update' , 'name'} , {value = Name})
end

function CMatch:NetSetUseFinishline( use_finishline )
    self:NetUpdate({'update' , 'use_finishline'} , {value = use_finishline})
end

-- tell server that we are ready
function CMatch:NetSetReady(ready)
    self:NetUpdate({'player','ready'},{ready = ready})

end

function CMatch:NetStart()
    self:NetUpdate({'start'})
end

function CMatch:NetUpdatePlayer( keys , data)
    
    local pl = desk.find(self.playerlist , function(v) return v.id == data.id end)
    if pl == nil then
        return false
    end

    local prop = keys:pop()
    if prop == 'ready' then
        pl.ready = data.ready == true
        if data.id == GetPlayerServerId(GetPlayerIndex()) then
            self.ready = pl.ready
        end

    end

end

function CMatch:AddPlayer( player )
    local pl = desk.insert_end(self.playerlist, {
        id = player
    })
end

function CMatch:RemovePlayer( player )
    local pl , k = desk.find( self.playerlist , function (v) return v.id == player end)

    if pl ~= nil then
        table.remove(self.playerlist , k)

        if self.race ~= nil and self.race.running == true then
            self.race:RemovePlayer(src)
        end
    end
end

function CMatch:UpatePlayerlist( playerlist )
    self.playerlist = playerlist
end


function CMatch:Start() -- called by server becasuse fuck you
    for k , pl in ipairs(self.playerlist) do 
        self.race:AddPlayer(pl.id)
    end
    self.race:NetStart()
end

function CMatch:NetHandle(keys , data)
    local target = keys:pop()
    if target == 'race' then
        if self.race:NetHandle(keys,data) == false then
            -- TODO error handling : some thing
        end
    elseif target == 'start' and self.shared == false then
        self:Start()
    elseif target == 'player' then
        
        if self:NetUpdatePlayer(keys , data) == false then 
            -- TODO error handling
        end
    elseif target == 'update' then
        local prop = keys:pop()
        if prop == 'route' then
            self:SetRoute(data.value)
        elseif prop == 'name' then
            self.name = data.value
        elseif prop == 'use_finishline' then
            self.route.use_finishline = data.value
        elseif prop == 'max_players' then
            self.max_players = data.value
        elseif prop == 'max_laps' then
            self.max_laps = data.value
        elseif prop == 'host' then
            self.host = data.value
        else
            -- TODO error handling : invalid prop
        end
    elseif target == 'playerlist' then

        local action = keys:pop()
        if action == 'add' then
            self:AddPlayer(data.value)
        elseif action == 'remove' then
            self:RemovePlayer(data.value)
        elseif action == 'update' then
            self:UpatePlayerlist(data.value)
        end
    else
        -- TODO error handling : invalid target
    end

end

Match = nil

RegisterNetEvent('pd_race:cl_net_update')
AddEventHandler('pd_race:cl_net_update' , function(target , rawkeys , data)
    print(target , json.encode(rawkeys) , data)
    
    local keys = CKeys:new(rawkeys)
    if target == 'match' and Match ~= nil then
        if Match:NetHandle(keys,data) == false then
            print('[Match:NetHandle(keys,data)]', target , json.encode(keys) , json.encode(data))
        end
    elseif target == 'matchlist' then

        local action = keys:pop()
        if action == 'recive' then

            local prop = keys:pop()
            if prop == 'match' then
                Match = data.value
            elseif prrop == 'matchlist' then
                Matchlist = data.value
            end
        elseif action == 'removed' then
            
            Match:Clear()
            Match = nil
        end

    end
end)