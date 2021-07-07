
-- add keys system to prevent id spoof
-- add ready player to race playerlist 
-- cleanup cl_race classes
-- check if player in anymatch then return
-- check for invalid id

local matches = {}
local matches_lock = Locks:new()

SMatch = {}

function SMatch:new( host  , name , password , max_players ,  max_laps )

    o = {
        host  = host,
        name  = name,
        password  = password,
        route  = nil,
        race = SRace:new(), -- SRace class
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
    self.race.route = route
end

function SMatch:SetId( id )
    self.id = id
    self.race:SetId(id)
end

function SMatch:RaceInit( )
    self.race.route = self.route
    self.race:SetId(self.id)
    self.race.max_laps = self.max_laps
end



function SMatch:AddPlayer( player , err_callback)
    
    if #self.playerlist == self.maxplayer then 
        err_callback('this match is full')
        return false
    end

    local pl = desk.find( self.playerlist , function (v) return v.pl == player end )

    if pl == nil then
        table.insert(self.playerlist, {
            id = player,
            ready = false
        })

        self:NetAllClientUpdate({'playerlist' , 'update'}, { playerlist = self.playerlist , action = 'add' })

    else 
        err_callback('player ' .. v.id .. ' already joined this match')
        return false
    end
    

    return true

end

function SMatch:RemovePlayer( player )

    local pl , k = desk.find( self.playerlist , function (v) return v.id == player end)

    if pl ~= nil then
        table.remove(self.playerlist , k)
        self:NetAllClientUpdate({'playerlist' , 'update'}, {playerlist = self.playerlist, action = 'remove'})
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

    if keys[1] == 'ready' then
        if data.ready == true then
            pl.ready = true
        else
            pl.ready = false
        end
        self:NetAllClientUpdate({'player','ready'} , { id = client , ready = pl.ready})
    end

end

function SMatch:Start()
    self.running = true
    self.race.route = self.route
    
    for k , pl in ipairs(self.playerlist) do
        self.race:AddPlayer(pl.id)
    end

    self.race:Start()
    
    Citizen.CreateThread(function()
        while self.running == true do
            Citizen.Wait(0)
            if self.race.finish == true then
                -- send to client that the match is finished
                print('finish match')
                
                -- self:NetAllClientUpdate( {'cleanup'} )
                -- matches[self.id] = nil
                self.running = false
            end
        end
    end)
end



function match_register( host , name , password , max_players , max_laps, id  , err_callback )

    while matches_lock:__is_lock() == true do
        Citizen.Wait(500)
    end
    
    id = id or rnd_string(3)
    
    matches_lock:__lock()
    
    
    if matches[id] ~= nil then
        err_callback("This matches id (" .. id .. ") already exits")
        return nil
    end

    local match = SMatch:new(host , name , password ,  max_players , max_laps)
    match:AddPlayer(host , print)
    
    matches[id] = match
    
    match:SetId(id)
    match:RaceInit()

    matches_lock:__unlock()
    
    return id , match

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
AddEventHandler('pd_race:sv_net_update' , function(target , keys , data)
    print('['..target..']', json.encode(keys) , json.encode(data))
    
    local src = source
    if target == 'match' and matches[keys[1]] ~= nil then

        local match = matches[keys[1]]
        
        if keys[2] == 'race' then
            if match.race:net_update(src , { table.unpack(keys,3) } , data) == false then
                print('[race] can\'t update player #' .. src .. '(invalid player/match id ?)')
            end

        elseif keys[2] == 'player' then -- update specify player

            if match:NetUpdatePlayer(src , { table.unpack(keys,3) } ,data) == false then
                print('[match] can\'t update player #' .. src .. '(invalid player/match id ?)')
            end
        
        elseif keys[2] == 'update' then

            if src ~= match.host then
                return
            end

            if keys[3] == 'name' then
            elseif keys[3] == 'route' then
            elseif keys[3] == 'passwaord' then
            end

        elseif keys[2] == 'start' then
            if src == match.host then
                match:Start()
            end
        end

    elseif target == 'matchlist' then
        
        if keys[1] == 'get' then
            cl_net_update(src , 'matchlist'  , {'recv'} ,{
                matchlist = desk.map(matches , function(v)
                    local hax = json.decode(json.encode(v))
                    if hax.password ~= nil then
                        hax.password = GetPasswordHash('dick')
                    end
                    return hax
                end)
            })

        elseif keys[1] == 'create' then
            
            if get_player_match(src) ~= nil then
                print(string.format("[match] can't create match #%d already in one" , src))
                SMatch:NetClientUpdate(src, {'recv'} , { error = true , reason = string.format('cam\'t create match when  already in one') })
                return
            end

            TriggerEvent('sv_routes:sv_get_route', data.route_id , function(route)

                if route == nil then
                    SMatch:NetClientUpdate(src, {'recv'} , { error = true , reason = string.format('route id %s didn\'t exits',data.route_id) })
                    return
                end
                if data.max_players > #route.cars then
                    SMatch:NetClientUpdate(src, {'recv'} ,{ error = true , reason = string.format('route max cars is %d',#route.cars) } )
                    return
                end
                local id , match = match_register(src , data.name , data.password , data.max_players,data.max_laps,data.custom_id,print)
                match:SetRoute(route)
                if match.race:SetUseFinishline(data.use_finishline)  == false then
                    SMatch:NetClientUpdate(src, {'recv'} ,{ error = true , reason = string.format('this route doenn\'t have finishline ') } )
                    return
                end
                SMatch:NetClientUpdate(src, {'recv'} , {match = match , id = id})
            end)

        elseif keys[1] == 'join' then

            if get_player_match(src) ~= nil then
                print(string.format("[match] can't join match #%d already in one" , src))
                SMatch:NetClientUpdate(src, {'recv'} , { error = true , reason = string.format('can\'t join match when  already in one') })
                return
            end

            local match = matches[data.id]
            if match ~= nil then -- if match exits
                if match.password == nil or match.password == data.password then 
                    if match:AddPlayer(src,print) == true then
                        SMatch:NetClientUpdate(src, {'recv'} , {match = match , id = data.id})                  
                        return
                    else
                        SMatch:NetClientUpdate(src, {'recv'} , { error = true , reason = string.format('match is full') })
                    end
                else
                    SMatch:NetClientUpdate(src, {'recv'} , { error = true , reason = string.format('invalid password') })
                end
            end
        elseif keys[1] == 'leave' then
            local match = get_player_match(src)
            if match ~= nil then
                match:RemovePlayer(src,print)
                cl_net_update(src , 'match' , {'removed'} , {action = 'leave' , reason = 'leave match'})
                if #match.playerlist == 0 then -- auto delete match when empty
                    matches[match.id] = nil
                end
                return
            end
        end
    end
end)