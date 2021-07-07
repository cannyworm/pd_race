local routes = {}

RegisterNetEvent("cl_routes:recv_route")
AddEventHandler("cl_routes:recv_route" , function(id , route)
    print(id , route)
    routes[id] = route
end)

AddEventHandler("cl_routes:get_route" , function(id , callback)

    if routes[id] == nil then 
        TriggerServerEvent('sv_routes:get_route',id)
        local count = 0
        while routes[id] == nil do
            Citizen.Wait(100)
            if count > 20 then 
                callback(nil)
                return 
            end
            count = count + 1
        end

    end
    
    if callback ~= nil then
        callback(routes[id])
    end

end)


