Config = {}

Config.TimeOpen = 8
Config.TimeClosed = 17

Config.PlayerTimeOpen = 9
Config.PlayerTimeClosed = 9

Config.ContractCooldown = 30 * 60 -- 30 minutes 
Config.ContractDuration = 60 * 60 -- 1 hour 

Config.ContractItemCount = { min = 2, max = 7 } -- Range of items that show up in each delivery not per item

Config.ShopLocations = {          
["pawnone"] = {
shop = vector3(173.36, -1319.31, 29.36),
boss = vector3(169.10, -1315.36, 29.36),
sell = vector3(171.38, -1317.11, 29.36),
value = vector3(173.15, -1322.09, 29.69),
job = "pawnone", 
label = "Pawn Crackers", 
blip = {sprite = 617, color = 5, scale = 0.6, }, 
ped = {model = "u_f_m_debbie_01", heading = 285.58},
stashes = {
    {name = "pawnone_stash_1", coords = vector3(171.43, -1323.26, 29.36), slots = 50, weight = 50000},
    {name = "pawnone_stash_2", coords = vector3(157.81, -1316.18, 29.36), slots = 50, weight = 50000},
},
trays = {
    {name = "pawnone_tray_1", coords = vector3(173.86, -1320.92, 29.36), slots = 50, weight = 50000},
    {name = "pawnone_tray_2", coords = vector3(175.81, -1323.48, 29.35), slots = 50, weight = 50000},
}
},

["pawntwo"] = {
shop = vector3(-783.09, -608.85, 30.28),
boss = vector3(-785.45, -617.05, 30.15), 
sell = vector3(-785.45, -617.05, 30.15), 
value = vector3(-782.28, -608.87, 30.28),
job = "pawntwo", 
label = "Pawn Stars", 
blip = {sprite = 617, color = 5, scale = 0.6 }, 
ped = {model = "u_m_m_edtoh", heading = 345.33},
stashes = {
    {name = "Pawnstar_Stash_1", coords = vector3(-786.21, -616.39, 30.28), slots = 50, weight = 50000},
    {name = "Pawnstar_Stash_2", coords = vector3(-783.74, -612.76, 30.28), slots = 50, weight = 50000},
},
trays = {
    {name = "Pawnstar_Tray_1", coords = vector3(-782.24, -607.99, 30.34), slots = 30, weight = 70000},
    
}
},
}


Config.ContractDropoffs = {
    {location = vector4(321.72, -559.07, 28.74, 28.78),   label = 'Pillbox Hospital',      heading = 180.0,      ped = 's_m_m_doctor_01'},
    {location = vector4(-4.93, -1107.83, 29.0, 161.55),   label = 'Ammunation',             heading = 180.0,     ped = 's_m_y_ammucity_01' },
    {location = vector4(-1083.0, -248.0, 37.76, 0.0),     label = 'Weazel News',             heading = 180.0,    ped = 'cs_priest'},
    {location = vector4(433.9, -977.89, 30.71, 75.57),    label = 'Police Station',          heading = 180.0,    ped = 'cs_priest'},
    {location = vector4(236.56, -409.57, 47.92, 337.28),  label = 'Courthouse',               heading = 180.0,   ped = 's_m_m_janitor'},
    {location = vector4(-1681.28, -290.94, 51.88, 231.5), label = 'Sister Deloris Gospel Choir', ped = 'cs_priest'},
    {location = vector4(217.99, -1647.05, 29.79, 320.57), label = 'Fire Department',          heading = 180.0,   ped = 's_m_y_fireman_01'},
    {location = vector4(897.7, -174.69, 73.81, 236.47),   label = 'Taxi Depot',                  model = 'csb_prologuedrive'},
    {location = vector4(559.23, 2741.34, 42.2, 186.05),   label = 'Animal Shop',           heading = 180.0,      ped = 'csb_screen_writer'},
    {location = vector4(1216.86, 2727.55, 38.0, 177.02),  label = 'Larrys Auto Sales',     heading = 180.0,      ped = 'csb_cletus'},
    {location = vector4(-1043.68, 4918.7, 208.32, 277.83),label = 'Children Of The Son',   heading = 180.0,      ped = 'a_m_y_acult_01'},
    {location = vector4(1696.03, 4783.06, 42.0, 100.48),  label = 'Arcade',                heading = 180.0,      ped = 's_m_y_clown_01'},
    {location = vector4(-50.08, 6361.62, 31.51, 223.2),   label = 'Feed And Supplies',     heading = 180.0,      ped = 'a_m_m_salton_02'},
}


Config.BlacklistedItems = { 'weapon_grenade', 'weapon_bzgas', 'weapon_rpg' } 

Config.ShowOnlyItemsList = {
"painting",
"television",
"microwave",
"safe",
"phone",
"goldcoin",
"silvercoin",
"rarecoin",
"copperore",
"goldore",
"silverore",
"ironore",
"carbon",
"goldingot",
"silveringot",
"uncut_emerald",
"uncut_ruby",
"uncut_diamond",
"uncut_sapphire",
"emerald",
"ruby",
"diamond",
"sapphire",
"gembag",
"diamond_ring",
"emerald_ring",
"ruby_ring",
"sapphire_ring",
"diamond_ring_silver",
"emerald_ring_silver",
"ruby_ring_silver",
"sapphire_ring_silver",
"diamond_necklace",
"emerald_necklace",
"ruby_necklace",
"sapphire_necklace",
"diamond_necklace_silver",
"emerald_necklace_silver",
"ruby_necklace_silver",
"sapphire_necklace_silver",
"iced_chain",
"iced_rolex",
"iced_cartier",
"iced_mille",
"ruby_egg",
"emerald_egg",
"sapphire_egg",
"diamond_earring",
"emerald_earring",
"ruby_earring",
"sapphire_earring",
"diamond_earring_silver",
"emerald_earring_silver",
"ruby_earring_silver",
"sapphire_earring_silver",
"gold_ring",
"goldchain",
"goldearring",
"silver_ring",
"silverchain",
"silverearring",
"casino_chips",
"houselaptop",
"mansionlaptop",
"art1",
"art2",
"art3",
"art4",
"art5",
"art6",
"art7",
"boombox",
"checkbook",
"mdlaptop",
"mddesktop",
"mdmonitor",
"mdtablet",
"mdspeakers",
"copper",
"plastic",
"metalscrap",
"steel",
"glass",
"iron",
"rubber",
"aluminum",
"bottle",
"can"
}

