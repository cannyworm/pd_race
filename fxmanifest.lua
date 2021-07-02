fx_version 'cerulean'
game 'gta5'

author ''
description 'Race script'
version '0.0.1'


client_scripts {
    'libs/lock.lua',
    'libs/misc.lua',
    'libs/client/cl_gps.lua',
    
    'client/cl_route_maker.lua'
}

server_scripts {
    'libs/lock.lua',
    'libs/misc.lua',
    'server/sv_match.lua',
    'server/sv_route_maker.lua'
}
