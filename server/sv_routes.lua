-- add title 
local file_content = LoadResourceFile(GetCurrentResourceName(),'./routes.json')

Citizen.CreateThread(function() -- convert from table of xyz to vector3

    routes = json.decode(file_content)
    
    for k ,v in pairs(routes) do
        for _k , _v in pairs(v.checkpoints) do
            _v.Pos = __vec3(_v.Pos)
        end
        for _k , _v in pairs(v.cars) do
            _v.Pos = __vec3(_v.Pos)
        end
        if v.finish.Pos then
            v.finish.Pos = __vec3(v.finish.Pos)
        end
        v.id = k
    end

end)

RegisterNetEvent("sv_routes:get_route")
AddEventHandler('sv_routes:get_route' , function(id)
    TriggerClientEvent("cl_routes:recv_route",source, id ,routes[id])
end)


AddEventHandler('sv_routes:sv_get_route' ,function(id,callback)
    if callback ~= nil then
        callback(routes[id])
    end
end)



