function cl_net_update(client,target , rawkeys , data)
    TriggerClientEvent('pd_race:cl_net_update',client, target , rawkeys , data)
end

function cl_net_error(client , msg, keys , data)
    cl_net_update(client , 'error' , {} , { msg = msg , data = data} )
end