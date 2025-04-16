local QBCore = exports['qb-core']:GetCoreObject()
local ShopPrices = {}

local ShopItems = {
    selling = {
        items = {
        }
    },
    buying = {
        items = {
            phone = math.random(12, 52),
            goldcoin = math.random(38, 102),
            silvercoin = math.random(10, 48),
            
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
