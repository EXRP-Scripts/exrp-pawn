local QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
    for shopId, shopData in pairs(Config.ShopLocations) do
        if shopData.sell then
            exports.ox_target:addBoxZone({
                coords = shopData.sell,
                size = vec3(2, 2, 2),
                rotation = 0,
                debug = false,
                options = {
                    {
                        name = 'sell_items_' .. shopId,
                        icon = 'fas fa-dollar-sign',
                        label = 'Sell Items',
                        canInteract = function(_, distance)
                            local playerJob = QBCore.Functions.GetPlayerData().job.name
                            return distance <= 3.0 and playerJob == shopData.job
                        end,
                        onSelect = function()
                            local hour = GetClockHours()
                            if hour >= Config.TimeOpen and hour <= Config.TimeClosed then
                                TriggerEvent('exrp-pawn:client:OpenSellMenu')
                            else
                                QBCore.Functions.Notify(("Shop is closed. Open from %02d:00 to %02d:00."):format(Config.TimeOpen, Config.TimeClosed), "error")
                            end
                        end
                    },
                    {
                        name = 'check_prices_' .. shopId,
                        icon = 'fas fa-tags',
                        label = 'View Current Offers',
                        canInteract = function(_, distance)
                            local playerJob = QBCore.Functions.GetPlayerData().job.name
                            return distance <= 3.0 and playerJob == shopData.job
                        end,
                        onSelect = function()
                            TriggerEvent('exrp-pawn:client:OpenPriceList')
                        end
                    }
                }
            })
        end
    end
end)

RegisterNetEvent('exrp-pawn:client:OpenSellMenu', function()
    local oxItems = exports.ox_inventory:Items()

    lib.callback('exrp-pawn:getPrices', false, function(prices)
        local menu = {}
        local itemsToSell = {}
        local total = 0

        for item, price in pairs(prices) do
            local count = exports.ox_inventory:Search('count', item)
            if count and count > 0 then
                local itemLabel = oxItems[item] and oxItems[item].label or item
                local itemTotal = price * count
                total = total + itemTotal
                table.insert(menu, {
                    title = itemLabel .. " x" .. count,
                    description = "$" .. price .. " each | Total: $" .. itemTotal,
                    icon = GetImage(item),
                    readOnly = true
                })
                table.insert(itemsToSell, {name = item, amount = count})
            end
        end

        if total == 0 then lib.notify({title = 'Pawnshop', description = 'You have no items to sell.', type = 'error'}) return end

        table.insert(menu, {
            title = "Sell All for $" .. total,
            icon = 'fas fa-hand-holding-usd',
            onSelect = function()
                TriggerServerEvent('exrp-pawn:sellItems', itemsToSell, total)
            end
        })

        lib.registerContext({
            id = 'sell_items_menu',
            title = 'Sell Your Items',
            options = menu
        })

        lib.showContext('sell_items_menu')
    end)
end)

RegisterNetEvent('exrp-pawn:client:OpenPriceList', function()
    local oxItems = exports.ox_inventory:Items()

    lib.callback('exrp-pawn:getPrices', false, function(prices)
    if not prices or next(prices) == nil then lib.notify({title = 'Pawnshop', description = 'No prices available.', type = 'error'}) return end

        local menu = {}

        for item, price in pairs(prices) do
            local itemLabel = oxItems[item] and oxItems[item].label or item
            table.insert(menu, {
                title = itemLabel,
                description = '$' .. price,
                icon = GetImage(item),
                readOnly = true
            })
        end

        lib.registerContext({
            id = 'price_check_menu',
            title = 'Current Offers',
            options = menu
        })

        lib.showContext('price_check_menu')
    end)
end)
