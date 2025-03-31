fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Stephen'
description 'Player Owned Pawnshops with a sharp mind!'
version '0.0.4'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/sell.lua',
    'client/contracts.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/sell.lua',
    'server/contracts.lua'
}
