-- TODO 


Citizen.CreateThread(function() -- Waypoint mark mode
    while true do 
        if IsWaypointActive() then
            local waypoint = GetFirstBlipInfoId(8)
            if AddMark(GetBlipInfoIdCoord(waypoint)) then
                SetWaypointOff()
            end
        end
        Citizen.Wait(100) -- Always put Wait in loop or else.
    end
end)

local Blip = nil

function AddMark(Pos,UseGroundPos) -- return true if mode exits
    
    if Blip ~= nil then
        RemoveBlip(Blip)
    end

    local ground_pos = GetGroundZFor_3dCoord(Pos.x, Pos.y, 99999.0, 1) -- it's just work
    Pos = Pos + vector3(0,0,ground_pos.z)

    Blip = AddBlip(Pos,1,25)

    return true
end