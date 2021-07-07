RegisterNetEvent("sv_rmk:submit")
AddEventHandler('sv_rmk:submit' , function(route)
    print(route)
    out = route
end)



-- concep
-- Route tabl
-- [ID : int] [Owner : int] [Title : string] [Description : string] [RouteContent : string]

local out = 'null'



SetHttpHandler(function(req,res)
    local id = string.gsub(req.path,'/','')
    
    res.send(out)

    -- local str = json.encode(req) .. '\n' .. json.encode(res)
    -- res.send(id)
    
	return 201
end)
