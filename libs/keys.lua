CKeys = {}

function CKeys:new(keys)
    object = {
        keys = keys,
        pos = 1
    }

setmetatable(object,self)
self.__index = self
return object
end

function CKeys:set(keys)
    self.keys = keys
end

function CKeys:pop() -- pop keys from self.pos start at "FIRST" key left to right
    local v = self.keys[self.pos]
    self.pos = self.pos + 1 -- because debugging
    return v
end

function CKeys:push(key)
   return desk.insert_end(self.keys,key)
end

function CKeys:past(pos) -- past key to another function 
    local p = pos or self.pos
    return { table.unpack(self.keys,p) }
end