local QBCore = exports['qb-core']:GetCoreObject()
local ShopPrices = {}

local ShopItems = {
    selling = {
        items = {
        }
    },
    buying = {
        items = {
            painting = math.random(170, 3432),
            television = math.random(70, 306),
            microwave = math.random(14, 62),
            safe = math.random(0, 6800),
            phone = math.random(12, 52),
            goldcoin = math.random(38, 102),
            silvercoin = math.random(10, 48),
            rarecoin = math.random(70, 280),
            copperore = math.random(27, 34),
            goldore = math.random(32, 45),
            silverore = math.random(12, 18),
            ironore = math.random(4, 9),
            carbon = math.random(5, 38),
            goldingot = math.random(78, 138),
            silveringot = math.random(15, 70),
            uncut_emerald = math.random(54, 68),
            uncut_ruby = math.random(62, 108),
            uncut_diamond = math.random(86, 156),
            uncut_sapphire = math.random(58, 95),
            emerald = math.random(90, 214),
            ruby = math.random(124, 238),
            diamond = math.random(138, 272),
            sapphire = math.random(90, 204),
            gembag = math.random(1520, 6200),
            diamond_ring = math.random(280, 408),
            emerald_ring = math.random(206, 340),
            ruby_ring = math.random(240, 374),
            sapphire_ring = math.random(308, 442),
            diamond_ring_silver = math.random(206, 340),
            emerald_ring_silver = math.random(158, 272),
            ruby_ring_silver = math.random(178, 306),
            sapphire_ring_silver = math.random(178, 306),
            diamond_necklace = math.random(376, 510),
            emerald_necklace = math.random(274, 408),
            ruby_necklace = math.random(274, 408),
            sapphire_necklace = math.random(260, 374),
            diamond_necklace_silver = math.random(360, 374),
            emerald_necklace_silver = math.random(206, 320),
            ruby_necklace_silver = math.random(240, 374),
            sapphire_necklace_silver = math.random(186, 312),
            iced_chain = math.random(22360, 44400),
            iced_rolex = math.random(6900, 12240),
            iced_cartier = math.random(15160, 25840),
            iced_mille = math.random(31000, 54400),
            ruby_egg = math.random(10320, 17000),
            emerald_egg = math.random(8960, 15640),
            sapphire_egg = math.random(10600, 14280),
            diamond_earring = math.random(299, 306),
            emerald_earring = math.random(170, 187),
            ruby_earring = math.random(211, 224),
            sapphire_earring = math.random(190, 204),
            diamond_earring_silver = math.random(104, 218),
            emerald_earring_silver = math.random(99, 163),
            ruby_earring_silver = math.random(86, 146),
            sapphire_earring_silver = math.random(72, 108),
            gold_ring = math.random(22, 48),
            goldchain = math.random(22, 95),
            goldearring = math.random(16, 35),
            silver_ring = math.random(14, 37),
            silverchain = math.random(18, 71),
            silverearring = math.random(14, 27),
            casino_chips = math.random(1, 1),
            houselaptop = math.random(130, 805),
            mansionlaptop = math.random(100, 875),
            art1 = math.random(225, 630),
            art2 = math.random(225, 630),
            art3 = math.random(160, 665),
            art4 = math.random(95, 800),
            art5 = math.random(212, 735),
            art6 = math.random(360, 665),
            art7 = math.random(60, 665),
            boombox = math.random(65, 100),
            checkbook = math.random(25, 595),
            mdlaptop = math.random(100, 875),
            mddesktop = math.random(365, 840),
            mdmonitor = math.random(560, 700),
            mdtablet = math.random(95, 770),
            mdspeakers = math.random(125, 630),
            copper = math.random(1, 13),
            plastic = math.random(1, 15),
            metalscrap = math.random(1, 15),
            steel = math.random(3, 14),
            glass = math.random(2, 18),
            iron = math.random(8, 18),
            rubber = math.random(1, 8),
            aluminum = math.random(1, 16),
            bottle = math.random(1, 2),
            can = math.random(1, 2),
            
        }
    }
}

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    GenerateShopPrices()

    CreateThread(function()
        Wait(500) 
        for _, shop in pairs(Config.ShopLocations) do
            local exists = exports.oxmysql:executeSync('SELECT id FROM pawnshop_job_items WHERE job = ?', { shop.job })
            if not exists or #exists == 0 then
                exports.oxmysql:insert('INSERT INTO pawnshop_job_items (job, label, items, valuations) VALUES (?, ?, ?, ?)', {
                    shop.job,
                    shop.label or (shop.job:upper() .. " Pawnshop"),
                    '{}',
                    '{}'
                })
                print("^2[exrp-pawn]^7 Initialized pawnshop entry for job: " .. shop.job)
            end
        end
    end)
    
end)

function GenerateShopPrices()
    for item, range in pairs(ShopItems.buying.items) do
        ShopPrices[item] = range
    end
end

lib.callback.register('exrp-pawn:getPrices', function(source)
    return ShopPrices
end)

RegisterNetEvent('exrp-pawn:sellItems', function(items, total)
    local src = source
    local desc = {}
    if not src or not total or not items then return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local ped = GetPlayerPed(src)
    if not ped or not DoesEntityExist(ped) then return end

    local job = Player.PlayerData.job.name
    local shop = Config.ShopLocations[job]
    if not shop or not shop.sell then return end

    local coords = GetEntityCoords(ped)
    if #(coords - shop.sell) > 5.0 then return end
    
    for _, data in pairs(items) do
        local item = data.name
        local amount = tonumber(data.amount)

        if not item or not amount or amount < 1 then return end

        local priceInfo = ShopPrices[item]
        if not priceInfo then return end

        local count = exports.ox_inventory:GetItemCount(src, item)
        if count < amount then return end
    end

    for _, data in pairs(items) do
        exports.ox_inventory:RemoveItem(src, data.name, data.amount)
    end
    
    exports.ox_inventory:AddItem(src, 'money', total)
    TriggerClientEvent('QBCore:Notify', src, ("You sold items for $%s"):format(total), "success")
    
    for _, data in pairs(items) do
        desc[#desc+1] = ("**%sx %s**"):format(data.amount, data.name)
    end    
    PawnLogs(job, "Bulk Sale at Pawnshop", ("**%s** \nsold items for **$%s**:\n- %s \n\n Sold at %s"):format(GetPlayerName(src), total, table.concat(desc, "\n- "),job))    
end)
