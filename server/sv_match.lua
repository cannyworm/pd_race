local avc_str = 'access viowation # cw_get_pwayew_match( { mode = \'aes128\' , key = data.pwivate }).host ~= swc'
-- add ready player to race playerlist 
-- cleanup cl_race classes
-- check if player in anymatch then return
-- check for invalid id
-- handle player leave between match

local matches = {}
local matches_lock = Locks:new()

SMatch = {}

function SMatch:new( host  , name , password , max_players ,  max_laps )

    o = {
        host  = host,
        name  = name,
        password  = password,
        route  = nil,
        race = nil, -- SRace class
        max_laps = max_laps,
        ready = false,
        disconnected = false,
        bet = {},
        env = {
            weather = nil,
            time = nil
        },
        rules = {
            disable_collusion = false
        },
        max_players = max_players,
        playerlist = {}
    }

    setmetatable(o, self)
    self.__index = self

    return o
end


function SMatch:SetName( name )
    self.name = name
end

function SMatch:SetPassword( password )
    self.password = password
end

function SMatch:SetRoute( route )
    self.route = route
end

function SMatch:SetId( id )
    self.id = id
end

function SMatch:RaceInit( )
    self.race = SRace:new()
    self.race:SetId(self.id)
    self.race.route = self.route
    self.race.max_laps = self.max_laps

end

function SMatch:Clear()
    if self.race ~= nil then
        self.race:Clear()
    end
    matches[self.id] = nil
end

function SMatch:AddPlayer( player , err_callback)

    if player == nil then
        print('SMatch:AddPlayer player is nil')
        return false
    end

    if #self.playerlist == self.max_players then 
        err_callback('this match is full')
        return false
    end

    local pl = desk.find( self.playerlist , function (v) return v.id == player end )

    if pl == nil then
        table.insert(self.playerlist, {
            id = player,
            ent = GetPlayerPed(player),
            ready = false
        })

        self:NetAllClientUpdate({'playerlist' , 'update'}, { value = self.playerlist , action = 'add' })

    else 
        err_callback('player ' .. player .. ' already joined this match')
        return false
    end
    

    return true

end

function SMatch:RemovePlayer( player , reason)

    local pl , k = desk.find( self.playerlist , function (v) return v.id == player end)

    if pl ~= nil then
        
        table.remove(self.playerlist , k)

        if self.race ~= nil and self.race.running == true then
            self.race:RemovePlayer(src , { RemoveCar = true })
        end

        self:NetAllClientUpdate({'playerlist' , 'remove'}, {value = player, reason = reason})
        cl_net_update(player,'matchlist' , {'removed'} , {reason = reason})

        if #self.playerlist == 0 then
            self:Clear()
        end

    else 
        err_callback('player ' .. v.id .. ' isn\'t in this match')
        return false
    end

    return true

end

function SMatch:NetClientUpdate(client , keys , data)
    TriggerClientEvent('pd_race:cl_net_update', client, 'match' , keys , data)
end

function SMatch:NetAllClientUpdate( keys , data)
    
    if #self.playerlist == 0 then
        return
    end

    for k , v in ipairs(self.playerlist) do
        self:NetClientUpdate(v.id,keys,data)
    end
end

function SMatch:NetUpdatePlayer( client , keys , data)
    local pl = desk.find(self.playerlist , function(v) return v.id == client end)

    if pl == nil then
        return false
    end
    local prop = keys:pop()
    if prop == 'ready' then
        local veh = GetVehiclePedIsIn(pl.ent,false)
        
        if veh == nil then
            cl_net_error(client , 'you need to be inside vehicle to ready')
        end

        pl.ready = data.ready == true
        self:NetAllClientUpdate({'player','ready'} , { id = client , ready = pl.ready})
    end

end

function SMatch:Start(src)
    local players = desk.map(self.playerlist,function(v)
        if v.ready == false then
            return nil
        end
        return v
    end)
    
    if #players == 0 then
        cl_net_error(src , string.format('not enough player to start a game'))
        return
    end

    self.running = true
    
    self:RaceInit()
    self.race:AddPlayers(players)
    self.race:Start()
    
    Citizen.CreateThread(function()
        while self.running == true do
            Citizen.Wait(0)
            if self.race.finish == true then
                -- send to client that the match is finished
                print('finish match')
                
                -- self:NetAllClientUpdate( {'cleanup'} )
                -- matches[self.id] = nil
                self.race = nil
                self.running = false
            end
        end
    end)

end

function SMatch:NetHandle( src ,   keys , data)
    local target = keys:pop()
    if target == 'race' then
        if self.race:NetHandle( src , keys , data) == false then 
            -- TODO error handling
        end
    elseif target == 'player' then
        if self:NetUpdatePlayer( src , keys , data) == false then 
            -- TODO error handling
        end
    elseif target == 'start' then
        if src ~= self.host then
            cl_net_error(src , string.format('access viowation # cw_get_pwayew_match( { mode = \'aes128\' , key = data.pwivate }).host ~= swc'))
            return 
        end
        if self.running == true then
            cl_net_error(src , string.format('can\'t start already stated match'))
            return
        end
        self:Start(src)
    elseif target == 'leave' then
        self:RemovePlayer(src)
        if #self.playerlist == 0 then -- auto delete match when empty
            self.race.stop = true
            matches[self.id] = nil
        end
    elseif target == 'update' then
        if src ~= self.host then
            cl_net_error(src , string.format(avc_str))
            return 
        end
        local prop = keys:pop()
        if prop == 'route' then
            TriggerEvent('sv_routes:sv_get_route', data.value , function(route)

                if route == nil then
                    -- TODO error handling : error route doesn't exits
                    cl_net_error(src , string.format("can't find route \"%s\" ",data.value))
                    return
                end

                self:SetRoute(route)
                self:NetAllClientUpdate( {'update' , 'route'}  , {value = route})
            end)
        elseif prop == 'name' then
            self.name = data.value
            self:NetAllClientUpdate({'update' , 'name'} , {value = data.value})
        elseif prop == 'use_finishline' then
            self.route.use_finishline = data.value
            self:NetAllClientUpdate({'update' , 'use_finishline'} , {value = data.value})
        elseif prop == 'max_players' then
            self.max_players = data.value
            self:NetAllClientUpdate({'update' , 'max_players'} , {value = data.value})
        elseif prop == 'max_laps' then
            self.max_laps = data.value
            self:NetAllClientUpdate({'update' , 'max_laps'} , {value = data.value})
        elseif prop == 'host' then
            self.host = data.value
            self:NetAllClientUpdate({'update' , 'host'} , {value = data.value})
        else
            -- error handling
        end
    else 
        -- TODO error handling : error target doesn't exits
    end
end


function match_register( host , args , error_callback )

    if args.max_players == nil then
        error_callback('args.max_players is nil' )
        return nil
    end

    if args.max_laps == nil then
        error_callback( 'args.max_laps is nil' )
        return nil
    end

    if args.name == nil then
        error_callback('args.name is nil' )
        return nil
    end

    -- TODO check if name is invalid

    while matches_lock:__is_lock() == true do
        Citizen.Wait(500)
    end
    
    id = tostring(math.random(100,999))
    
    matches_lock:__lock()
    
    
    if matches[id] ~= nil then
        error_callback("This matches id (" .. id .. ") already exits")
        return nil
    end

    local match = SMatch:new(host , args.name , args.password ,  args.max_players , args.max_laps)
    match:AddPlayer(host , print)
    
    matches[id] = match
    
    match:SetId(id)

    local stop_waiting = false
  
    TriggerEvent('sv_routes:sv_get_route', args.route_id , function(_route)
        
        match:SetRoute(_route)
        stop_waiting = true
    end)


    Citizen.SetTimeout(1000 * 20, function()
        if stop_waiting == true then return end
        stop_waiting = true
        print('[error] server take to long to response (20 secound) { \'' .. args.route_id .. '\'}')
        error_callback( 'server take to long to response (20 secound) { \'' .. args.route_id .. '\'}')
        
    end)

    while stop_waiting == false do
        Citizen.Wait(1)
    end

    if match.route == nil then
        error_callback('route \'' .. args.route .. '\' doesn\' exits' )
        return nil 
    end

    match:RaceInit()

    matches_lock:__unlock()
    
    return match

end

function get_player_match(source)
    
    for k , v in pairs(matches) do
        if desk.find(v.playerlist , function(v) return v.id == source end ) ~= nil then
            return v
        end
    end

    return nil
end

RegisterNetEvent('pd_race:sv_net_update')
AddEventHandler('pd_race:sv_net_update' , function(target , rawkeys , data)
    -- { match_id , ... }

    print(target , json.encode(rawkeys) , json.encode(data))

    local src = source
    local keys = CKeys:new(rawkeys)
    if target == 'match' then
        local match = matches[keys:pop()]
        if match ~= nil then
            if match:NetHandle(source,keys,data) == false then
                cl_net_error(src , 'action invalid')
            end
        else
            cl_net_error(src , 'match invalid')
        end
    elseif target == 'matchlist' then
        local action = keys:pop()
        if action == 'get' then
            local mlist = desk.map(matches , function(v , k) 
                local m = desk.pcopy(v)
                
                if m.password ~= nil then
                    m.password = '123456789'
                end

                return m
            end)
            cl_net_update( src, 'matchlist' , {'recive' ,  'matchlist'} , { value = mlist })
        elseif action == 'create' then
            local m = match_register(src , data , function(error_msg)
                cl_net_error(src , string.format("Can't create match because %s",error_msg))
            end)
            m.race:SetUseFinishline(data.use_finishline == true)
            if m ~= nil then
                cl_net_update(src , 'matchlist' , {'recive' , 'match'} , {value = m})
            end
        elseif action == 'join' then
            local id = data.id
            local match = matches[id]
            if match ~= nil then
                if match:AddPlayer(src,function(error_msg)
                    cl_net_error(src , string.format("Can't join match because %s",error_msg))
                end) == false then
                    
                end
            else
                cl_net_error(src , string.format('match %s doesn\'t exits',id))
            end
        elseif action == 'leave' then
            local match = get_player_match(src)
            if match ~= nil then
                match:RemovePlayer(src , 'leaved')
            else
                cl_net_error(src , string.format('you aren\'t in any match'))
            end
        else

        end
    end
    -- get match , call NetHandle
end)

RegisterCommand('debug_join', function(source , args , rawcommand)
    local id = args[2]
    local match = matches[id]
    if match ~= nil then
        if match:AddPlayer(args[1],function(error_msg)
            print(string.format("Can't join match because %s",error_msg))

        end) == false then
            
        end
    else
        print(string.format('match %s doesn\'t exits',id))
    end

end, true)