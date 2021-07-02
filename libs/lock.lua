
function get_fn_sig() 
    -- get_fn_sig : 1
    -- Locks:fn : 2
    -- actual_fn : 3
    return debug.getinfo(3,"f").func
end

function Locks:new(o)
    o = o or {}
    o.locks = []
    setmetatable(o, self)
    self.__index = self
    return o
end

function Locks:__lock(fn)
    fn = fn or get_fn_sig()

    if self.locks[fn] == true then
        return false
    end

    self.locks[fn] = true
end

function Locks:__unlock(fn)
    fn = fn or get_fn_sig()

    if self.locks[fn] == false then
        return false
    end

    self.locks[fn] = false
end

function Locks:__is_lock(fn)
    return self.locks[fn or get_fn_sig()]
end