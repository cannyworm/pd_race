function rnd_string( lenght )
    math.randomseed(os.time())
    math.randomseed(math.random() * os.time())

    
    local str = ''
    for i = 0 , lenght do
        str = str .. string.char(math.random(string.byte('a'),string.byte('z')))
    end

    return str
end

function __vec3(t)
    return vector3(t.x,t.y,t.z)
end