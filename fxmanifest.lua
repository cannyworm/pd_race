fx_version 'cerulean'
game 'gta5'

author ''
description 'Race script'
version '0.0.1'




client_scripts {
    'config.lua',
    'libs/lock.lua',
    'libs/misc.lua',
    'libs/desk.lua',
    
    'libs/client/fn_wrapper.lua',
    'client/cl_net_update.lua',
    'client/cl_scalforms.lua',
    'client/cl_routes.lua',
    'client/cl_route_maker.lua',
    'client/cl_race.lua',
    'client/cl_match.lua',

    "client/ui/rage_ui/RageUI.lua",
	"client/ui/rage_ui/Menu.lua",
	"client/ui/rage_ui/MenuController.lua",
	"client/ui/rage_ui/components/*.lua",
	"client/ui/rage_ui/elements/*.lua",
	"client/ui/rage_ui/items/*.lua",
	"client/ui/rage_ui/panels/*.lua",
	"client/ui/rage_ui/windows/*.lua",
	"client/ui/cl_ui.lua"

}

server_scripts {
    'config.lua',
    'libs/lock.lua',
    'libs/desk.lua',
    'libs/misc.lua',
    
    'server/sv_net_update.lua',
    'server/sv_routes.lua',
    'server/sv_route_maker.lua',
    'server/sv_race.lua',
    'server/sv_match.lua'
    
}
