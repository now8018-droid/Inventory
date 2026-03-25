shared_script "@bt_defender/module/shared.lua"


lua54("yes")
fx_version 'cerulean'
game 'gta5'

author 'D9_DevDEK'
description 'D9 DevDEK Inventory'

shared_scripts {
	"@ox_lib/init.lua",
	'config/Config.lua',
	'config/SettingItem.lua',
	'config/Infoitem.lua',
	'config/Template.lua',
	'shared/function.lua',
	'config/weaponskin/**.*',
	'config/skinweapon.lua',
}

client_scripts {
	'config/Config.lua',
	'config/Function/ClientFunction.lua',
	'client/client.lua',
	'client/function.lua',
	'client/nui.lua',
	'client/player.lua',
	'client/trunk.lua',
	'client/vault.lua',
	'client/skinweapon.lua',
	'client/secondInventory.lua',
	'@xzero_trunk/export/trunk.lua',
	'client/Init.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/ServerConfig.lua',
    'server/Init.lua',
    'server/function.lua',
    'server/Skinweapon.lua',
    'server/ServerFunction.lua',
    'server/sv_keys.lua',
    'server/sv_security.lua',
    'server/sv_skins.lua',
    'server/server.lua'
}

ui_page {
    -- "http://localhost:5173/",
	'web/dist/index.html'
}

files {
    'web/dist/**',
    'web/image/**',
    --'web/sound/**',
}

dependency 'oxmysql'
