scaleform = {}

function is_float(num)
    return "." == string.match(tostring(num), "%.")
end

function scaleform:new(id , load_now)
    local o =  {
        id = id,
        color = {
          r = 255,
          g = 255,
          b = 255,
          a = 255
        },
        handle = nil,
        rendering = false
    }

    
    if load_now == true then
        o.handle = scaleform.load_scalform(o.id)
    end

    setmetatable(o, self)
    self.__index = self

    return o
end

function scaleform.load_scalform(id)
    local handle = RequestScaleformMovie(id)
    while not HasScaleformMovieLoaded(handle) do -- Ensure the scaleform is actually loaded before using
        Citizen.Wait(0)
    end
    return handle
end

function scaleform:load()
    if self.handle == nil then
        self.handle = self.load_scalform(self.id)
    end
    return self.handle == nil
end

function scaleform:call_func(name, ...)
    local args = {...}
    BeginScaleformMovieMethod(self.handle, name)

    for k, v in ipairs(args) do
        if (type(v) == "number") then
            if is_float(v) then
                PushScaleformMovieFunctionParameterFloat(v)
            else
                PushScaleformMovieFunctionParameterInt(v)
            end
        end

        if (type(v) == "string") and (string.len(v) > 99) then
            BeginTextCommandScaleformString()

            for i = 0, count, 1 do
                substring = string.sub(v, ((count * i) - 99), (count * i))
                AddTextComponentScaleform(v)
            end

            EndTextCommandScaleformString()
        end

        if (type(v) == "string") and (string.len(v) <= 99) then
            PushScaleformMovieFunctionParameterString(v)
        end

        if type(v) == "boolean" then
            PushScaleformMovieFunctionParameterBool(v)
        end
    end
    EndScaleformMovieMethod()
end

function scaleform:render_fullscreen()
    DrawScaleformMovieFullscreen(self.handle, self.color.r, self.color.g, self.color.b, self.color.a)
end

function scaleform:start_render()
    self.rendering = true

    Citizen.CreateThread(
        function()
            while self.rendering == true do
                self:render_fullscreen()
                Citizen.Wait(0)
            end
        end
    )
end

function scaleform:render_for(ms)
    self:start_render()

    Citizen.SetTimeout(
        ms,
        function()
            self:stop_render()
        end
    )
end

function scaleform:stop_render()
    self.rendering = false
end

function scaleform:unload()
    SetScaleformMovieAsNoLongerNeeded(self.handle)
end


-- Citizen.CreateThread(function()
--     -- ShowMPMessage('test','TESTT',5000)
--     while true do
--         Citizen.Wait(0)
--     end
-- end)
