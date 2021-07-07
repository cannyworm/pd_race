-- error handleing (register error callback when call function and check the result of error)
-- becare full about multithread
-- make callback system


CMatch = {}
Matchlist = {}

function CMatch:new(object)
    object = object or {}

    setmetatable(object, self)
    self.__index = self
    return object
end

function CMatch:NetUpdate( keys , data)
    sv_net_update('match' , { self.id , table.unpack(keys) } , data)
end

function CMatch:NetCreate( custom_id , name , password , route_id , use_finishline , max_players , max_laps )
    sv_net_update('matchlist',{'create'}, {
         custom_id = custom_id, 
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


function CMatch:SetRoute( route )
    self.route = route
end

-- init CRace
function CMatch:RaceInit()
    self.race = CRace:new()
    self.race:SetRoute(self.route)
    self.race:Init()
end

-- tell server that we are ready
function CMatch:SetReady(ready)
    self.ready = ready
    self:NetUpdate({'player','ready'},{ready = ready})
end

function CMatch:Start()
    self:NetUpdate({'start'})
end

function CMatch:NetUpdatePlayer( keys , data)
    local pl = desk.find(self.playerlist , function(v) return v.id == data.id end)

    if pl == nil then
        return false
    end

    if keys[1] == 'ready' then
        if data.ready == true then
            pl.ready = true
        else
            pl.ready = false
        end
    end

end

function MatchList_Get()

    local matchlist = nil
    local cb = Callbacks:add_callback('matchlist_get_fns', function(ms)
        matchlist = ms
    end) 

    sv_net_update('matchlist' , {'get'})
    
    while matchlist == nil do
        Citizen.Wait(1)
    end

    return matchlist
end

Callbacks = {
    matchrecv_fns = {},
    matchplistup_fns = {},
    matchleave_fns = {},
    matchlist_get_fns = {}      
}

function Callbacks:add_callback(name , callback)
    desk.insert_beg(self[name],callback)
end

function Callbacks:remove_callback(name , callback)
    
    if typeof (callback) == 'number' then
        local fn , k = desk.find(self[name] , function(v) return v == callback end)
        callback = k
    end
    
    table.remove(self[name],callback)

end

function invoke_callback(name , args)
    if Callbacks[name] == nil or #Callbacks[name] == 0 then return end
    for k , v in pairs(Callbacks[name]) do
        v(args)
    end
end


Match = nil

RegisterNetEvent('pd_race:cl_net_update')
AddEventHandler('pd_race:cl_net_update' , function(target , keys , data)

    if target == 'match' then
        print('[match]', json.encode(keys) , json.encode(data))
        if keys[1] == 'recv' then            
            
            if data.error == true then
                invoke_callback('matchrecv_fns', data)
                return
            end

            Match = CMatch:new(data.match)
            Match:RaceInit()
            Match.id = data.id

            invoke_callback('matchrecv_fns',{ Match = Match})
            
        end
        
        if Match == nil then
            return
        end

        if keys[1] == 'player' then

            if Match:NetUpdatePlayer( { table.unpack(keys,2) } ,data) == false then
                print('[match] can\'t update player #' .. src .. '(invalid player id ?)')
            end

        elseif keys[1] == 'playerlist' then
            if keys[2] == 'update' then
                Match.playerlist = data.playerlist
            end

        elseif keys[1] == 'removed' then -- kicked , leave 
            Match = nil
            invoke_callback('matchclear_fns' , {data.action , data.reason})
        end

    elseif target == 'matchlist' then
        if keys[1] == 'recv' then
            Matchlist = data.matchlist

            for k , v in ipairs(Matchlist) do
                print(string.format('#%d [%s] %s {%d/%d}',v.host,v.id,v.name,#v.playerlist,v.max_players))
            end
            invoke_callback('matchlist_get_fns',{Matchlist})
        end
    end

end)



RegisterCommand('m', function(source , args ,rawCommands)
    local cmd = args[1]

    if cmd == 'c' then
        
    elseif cmd == 'list' then
        sv_net_update('matchlist' , {'get'})
    elseif cmd == 'j' then
        CMatch:NetJoin(args[2])
    elseif cmd == 'l' then
        CMatch:NetLeave(args[2])
    elseif cmd == 'r' then
        Match:SetReady(Match.ready)
    elseif cmd == 's' then
        Match:Start()
    else
        print('invalid cmd')
    end
    

end,false)