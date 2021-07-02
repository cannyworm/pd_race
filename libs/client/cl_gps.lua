-- Contain gps stuff like blip , waypoint , etc ...

function AddBlip(pos ,type,color,number,scale)

    local blip = AddBlipForCoord(pos.x,pos.y,pos.z)
    SetBlipSprite(blip, type)
    SetBlipColour(blip, color)
    SetBlipScale(blip, scale or 1.0)
    -- SetBlipRoute(blip, true)
    -- SetBlipRouteColour(blip, color)
    
    if number ~= nil then
        ShowNumberOnBlip(blip,number)
    end

   -- BeginTextCommandSetBlipName('STRING')
   -- AddTextComponentSubstringPlayerName('LMAO XD')
   -- EndTextCommandSetBlipName(blip)

    return blip
end

