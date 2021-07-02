local matches = {}
local matches_lock = Locks:new()

Match = {}

function Match:new( host  , name , password , max_player ,  max_laps )

    o = {
        host  = host,
        name  = name,
        password  = password,
        route  = nil,
        max_laps = max_laps,
        status = 'not_ready',
        bet = {
        },
        env = {
            weather = nil,
            time = nil
        },
        rules = {
            disable_collusion = false
        },

        max_player = max_player,
        playerlist = []
    }

    setmetatable(o, self)
    self.__index = self

end

function Match:set_name( name )
    self.name = name
end

function Match:set_password( password )
    self.password = password
end

function Match:set_route( route )
    self.route = route
end

function Match:add_player( player , err_callback)
    
    if #self.playerlist == self.maxplayer then 
        err_callback('this match is full')
        return false
    end

    local pl = desk.find( self.playerlist , function (v) v.pl == player end )

    if pl == nil then
        table.insert(self.playerlist, {
            pl = player_id
        })
    else 
        err_callback('player ' .. player_id .. ' already joined this match')
        return false
    end

    return true

end

function Match:remove_player( player )

    local pl , k = desk.find( self.playerlist , function (v) v.pl == player end)

    if pl == nil then
        table.remove(self.playerlist , k)
    else 
        err_callback('player ' .. player_id .. ' isn\'t in this match')
        return false
    end

    return true

end

function match_register( host , name , password , force_id  , err_callback )

    while matches_lock:__is_lock() == true do
        Citizen.Wait(500)
    end

    matches_lock:__lock()
    
    local id = force_id or rnd_string(5)
    
    if matches[id] ~= nil then
        err_callback("This matches id (" .. id .. ") already exits")
        return nil
    end

    local match = Match:new(host , name , password )

    matches_lock:__unlock()
    
    return id , match

end


