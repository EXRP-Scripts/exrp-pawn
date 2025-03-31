local QBCore = exports['qb-core']:GetCoreObject()
local spawnedPeds = {}

local itemList = {}
for _, itemName in pairs(Config.ShowOnlyItemsList) do
    local item = exports.ox_inventory:Items()[itemName]
    if item then
        itemList[#itemList+1] = {
            label = item.label,
            value = itemName
        }
    end
end

function hasJobAccess(requiredJob)
    local PlayerData = QBCore.Functions.GetPlayerData()
    return PlayerData and PlayerData.job and PlayerData.job.name == requiredJob
end

function GetImage(img)
    if GetResourceState('ox_inventory') ~= 'started' then return 'Missing Image' end

    local Items = exports['ox_inventory']:Items()
    if not Items[img] then
        print(("[OX ERROR] Item '%s' not found in ox_inventory"):format(img))
        return 'Missing Image'
    end

    local itemClient = Items[img].client
    if itemClient and itemClient.image then
        return itemClient.image
    end

    return "nui://ox_inventory/web/images/" .. img .. ".png"
end


RegisterNetEvent('exrp-pawn:client:openAddSellMenu', function(invOptions)
    local oxItems = exports.ox_inventory:Items()
    local filteredOptions = {}

    for _, item in pairs(invOptions) do
        local itemData = oxItems[item.value]
        if item.value ~= "money" and not (itemData and itemData.blacklisted) then
            table.insert(filteredOptions, item)
        end
    end

    if #filteredOptions == 0 then lib.notify({ title = 'Pawnshop', description = 'No items found in your inventory to sell.', type = 'error' }) return end

    local input = lib.inputDialog('Add Item to Sell to Players', {
        {type = 'select', label = 'Item', options = filteredOptions, required = true, searchable = true},
        {type = 'number', label = 'Price per Item', required = true},
        {type = 'number', label = 'Quantity to List', required = true}
    })

    if input then TriggerServerEvent('exrp-pawn:server:addSellableFromInventory', input[1], input[2], input[3]) end
end)


RegisterNetEvent('exrp-pawn:client:addBuyFromPlayerMenu', function(existingShopItems)
    local oxItems = exports.ox_inventory:Items()
    local itemOptions = {}

    existingShopItems = existingShopItems or {}

    for _, itemName in pairs(Config.ShowOnlyItemsList) do
        local itemData = existingShopItems[itemName]
        if not itemData or itemData.type ~= 'buy' then
            local label = (oxItems[itemName] and oxItems[itemName].label) or itemName
            itemOptions[#itemOptions+1] = {
                label = label,
                value = itemName
            }
        end
    end    

    if #itemOptions == 0 then
        lib.notify({ title = 'Pawnshop', description = 'All buyable items are already listed.', type = 'error' })
        return
    end

    local input = lib.inputDialog('Create Buy Listing', {
        {type = 'select', label = 'Item', options = itemOptions, required = true, searchable = true},
        {type = 'number', label = 'Price to Offer', required = true},
        {type = 'number', label = 'Max Quantity You Want', required = true}
    })

    if input then  TriggerServerEvent('exrp-pawn:server:addItemToList', input[1], input[2], 'buy', input[3]) end
end)

RegisterNetEvent('exrp-pawn:client:showShop', function(items)
    lib.callback('exrp-pawn:server:getNearestPawnshopLabel', false, function(shopLabel)
    local buyOptions = {}
    local sellOptions = {}

    local oxItems = exports.ox_inventory:Items()

    for itemName, data in pairs(items) do
        local label = (oxItems[itemName] and oxItems[itemName].label) or itemName

        if data.type == "sell" then
            local stock = tonumber(data.stock or 0)
            if stock > 0 then
                table.insert(buyOptions, {
                    title = label,
                    description = ("Buy for $%s | In Stock: %s"):format(data.price, stock),
                    icon = GetImage(itemName),
                    onSelect = function()
                        TriggerServerEvent('exrp-pawn:server:buyItem', itemName)
                    end
                })
            end

        elseif data.type == "buy" then
            local max = tonumber(data.max or 0)
            local stock = tonumber(data.stock or 0)
            local remaining = max - stock
            if remaining > 0 then
                table.insert(sellOptions, {
                    title = label,
                    description = ("Sell for $%s | Wanted: %s"):format(data.price, remaining),
                    icon = GetImage(itemName),
                    onSelect = function()
                        local input = lib.inputDialog("Sell to Pawnshop", {
                            {type = 'number', label = 'Amount', default = 1, min = 1, max = remaining}
                        })
                        if input and input[1] then
                            TriggerServerEvent('exrp-pawn:server:sellItem', itemName, input[1])
                        end
                    end
                })
            end
        end
    end

    lib.registerContext({
        id = 'pawnshop_main_menu',
       title = shopLabel,
        options = {
            {title = 'Buy from Shop', icon = 'fa-shop', menu = 'pawnshop_buy_from_shop'},
            {title = 'Sell to Shop', icon = 'fa-hand-holding-dollar', menu = 'pawnshop_sell_to_shop'}
        }
    })

    lib.registerContext({
        id = 'pawnshop_buy_from_shop',
        title = 'Buy Items from shop ',
        options = buyOptions,
        menu = 'pawnshop_main_menu'
    })

    lib.registerContext({
        id = 'pawnshop_sell_to_shop',
        title = 'Sell Items to shop ',
        options = sellOptions,
        menu = 'pawnshop_main_menu'
    })

    lib.showContext('pawnshop_main_menu')
end)
end)

RegisterNetEvent('exrp-pawn:client:openManageStock', function(items, stock)
    local buyOptions = {}
    local sellOptions = {}

    for itemName, data in pairs(items) do
        local label = exports.ox_inventory:Items()[itemName]?.label or itemName

        if data.type == "buy" then
            local currentStock = stock[itemName] or 0
            local max = data.max or 0

            buyOptions[#buyOptions+1] = {
                title = label,
                description = ("Price: $%s | Max: %s | Stock: %s"):format(data.price, max, currentStock),
                icon = GetImage(itemName),
                onSelect = function()
                    local subOptions = {
                        {
                            title = "Edit Price / Max",
                            icon = "fa-pen",
                            onSelect = function()
                                local input = lib.inputDialog("Edit " .. label, {
                                    {type = 'number', label = 'New Price', default = data.price, required = true},
                                    {type = 'number', label = 'New Max Quantity', default = max, required = true}
                                })
                                if input then
                                    TriggerServerEvent('exrp-pawn:server:updateItemSettings', itemName, input[1], input[2], 'buy')
                                end
                            end
                        }
                    }

                    if currentStock > 0 then
                        subOptions[#subOptions+1] = {
                            title = "Withdraw Items",
                            icon = "fa-box-open",
                            onSelect = function()
                                local input = lib.inputDialog("Withdraw from Stock - " .. label, {
                                    {type = 'number', label = 'Amount to withdraw', default = 1, min = 1, max = currentStock}
                                })
                                if input and input[1] then
                                    TriggerServerEvent('exrp-pawn:server:withdrawItemStock', itemName, input[1], 'buy')
                                end
                            end
                        }
                    end

                    if currentStock == 0 then
                        subOptions[#subOptions+1] = {
                            title = "Delete Listing",
                            icon = "fa-trash",
                            onSelect = function()
                                TriggerServerEvent('exrp-pawn:server:removeItemFromList', itemName)
                            end
                        }
                    end

                    lib.registerContext({
                        id = 'pawnshop_manage_item_' .. itemName,
                        title = label,
                        menu = 'pawnshop_manage_stock',
                        options = subOptions
                    })

                    lib.showContext('pawnshop_manage_item_' .. itemName)
                end
            }

        elseif data.type == "sell" then
            local currentStock = data.stock or 0
            sellOptions[#sellOptions+1] = {
                title = label,
                description = ("Price: $%s | In Stock: %s"):format(data.price, currentStock),
                icon = GetImage(itemName),
                onSelect = function()
                    local subOptions = {
                        {
                            title = "Edit Price",
                            icon = "fa-pen",
                            onSelect = function()
                                local input = lib.inputDialog("Edit Sell Item - " .. label, {
                                    {type = 'number', label = 'New Price', default = data.price, required = true}
                                })
                                if input then
                                    TriggerServerEvent('exrp-pawn:server:updateItemSettings', itemName, input[1], nil, 'sell')
                                end
                            end
                        },
                        {
                            title = "Add Quantity",
                            icon = "fa-plus",
                            onSelect = function()
                                local input = lib.inputDialog("Add More - " .. label, {
                                    {type = 'number', label = 'Amount to Add', default = 1, min = 1}
                                })
                                if input and input[1] then
                                    TriggerServerEvent('exrp-pawn:server:addSellableFromInventory', itemName, data.price, input[1])
                                end
                            end
                        }
                    }

                    if currentStock > 0 then
                        subOptions[#subOptions+1] = {
                            title = "Delete Listing",
                            icon = "fa-trash",
                            onSelect = function()
                                TriggerServerEvent('exrp-pawn:server:removeItemFromList', itemName)
                            end
                        }
                    end

                    if currentStock > 0 then
                        subOptions[#subOptions+1] = {
                            title = "Withdraw Items",
                            icon = "fa-box-open",
                            onSelect = function()
                                local input = lib.inputDialog("Withdraw from Stock - " .. label, {
                                    {type = 'number', label = 'Amount to withdraw', default = 1, min = 1, max = currentStock}
                                })
                                if input and input[1] then
                                    TriggerServerEvent('exrp-pawn:server:withdrawItemStock', itemName, input[1], 'sell')
                                end
                            end
                        }
                    end

                    lib.registerContext({
                        id = 'pawnshop_manage_sell_item_' .. itemName,
                        title = label,
                        menu = 'pawnshop_manage_stock_sell',
                        options = subOptions
                    })

                    lib.showContext('pawnshop_manage_sell_item_' .. itemName)
                end
            }
        end
    end

    lib.registerContext({
        id = 'pawnshop_manage_stock',
        title = 'Manage Buy Items',
        search = true,
        options = buyOptions,
        menu = 'pawnshop_manage_menu'
    })

    lib.registerContext({
        id = 'pawnshop_manage_stock_sell',
        title = 'Manage Sell Items',
        search = true,
        options = sellOptions,
        menu = 'pawnshop_manage_menu'
    })  
    
    lib.registerContext({
        id = 'pawnshop_add_type_menu',
        title = 'Add Pawn Item',
        options = {
            {
                title = 'Sell to Players',
                description = 'Sell items to customers',
                icon = 'fa-box',
                onSelect = function()
                    TriggerServerEvent('exrp-pawn:server:requestSellableInventory')
                end
            },               
            {
                title = 'Buy from Players',
                description = 'Create listings to buy items from players',
                icon = 'fa-hand-holding-dollar',
                onSelect = function()
                    lib.callback('exrp-pawn:server:getCurrentShopItems', false, function(items)
                        TriggerEvent('exrp-pawn:client:addBuyFromPlayerMenu', items)
                    end)
                end
                
            }
        }
    })
    
    lib.registerContext({
        id = 'pawnshop_manage_menu',
        title = 'Manage Store Listings',
        options = {
            { title = "Add Listing", menu = "pawnshop_add_type_menu", icon = "fa-tag" },
            { title = "Buy Listings", menu = "pawnshop_manage_stock", icon = "fa-box" },
            { title = "Sell Listings", menu = "pawnshop_manage_stock_sell", icon = "fa-tag" },
            {title = 'Setup Valuation Prices', icon = 'fa-calculator', onSelect = function() TriggerEvent('exrp-pawn:client:openValuationManager')  end}
        
        }
    })

    lib.showContext('pawnshop_manage_menu')
end)

RegisterNetEvent('exrp-pawn:client:openValuationSetup', function()
    lib.callback('exrp-pawn:server:getValuations', false, function(existingValuations)   
        existingValuations = existingValuations or {}
        local options = {}
        for _, itemName in ipairs(Config.ShowOnlyItemsList) do
            if not existingValuations[itemName] then
                local label = exports.ox_inventory:Items()[itemName]?.label or itemName
                table.insert(options, {
                    label = label,
                    value = itemName
                })
            end
        end

        if #options == 0 then lib.notify({title = 'Pawnshop', description = 'All items already have valuations set.', type = 'error' }) return end

        local input = lib.inputDialog('Add New Valuation Item', {
            {type = 'select', label = 'Item', options = options, required = true, searchable = true},
            {type = 'number', label = 'Base Price ($)', required = true, min = 1}
        })

        if input then
            TriggerServerEvent('exrp-pawn:server:addValuationItem', input[1], input[2])
        end
    end)
end)

RegisterNetEvent('exrp-pawn:client:runValuation', function(valuations)
    local input = lib.inputDialog("Discount", {
        {type = 'number', label = 'Discount %', default = 0, min = 0, max = 100}
    })

    if not input then return false end
    local profitPercent = tonumber(input[1])

    lib.callback('ox_inventory:getInventory', false, function(inventory)
        local valuationList = {}
        local totalValue = 0
        local grouped = {}

        for _, item in pairs(inventory.items or {}) do
            if item.name and valuations[item.name] then
                grouped[item.name] = grouped[item.name] or {
                    label = item.label or item.name,
                    count = 0
                }
                grouped[item.name].count = grouped[item.name].count + (item.count or 1)
            end
        end

        for itemName, data in pairs(grouped) do
            local basePrice = valuations[itemName]
            local finalPrice = math.floor(basePrice * (1 - profitPercent / 100) + 0.5)
            local subtotal = finalPrice * data.count
            totalValue = totalValue + subtotal

            table.insert(valuationList, {
                title = ("%s x%s"):format(data.label, data.count),
                description = ("$%s each → Total: $%s"):format(finalPrice, subtotal),
                 icon = GetImage(itemName)
            })
        end

        if #valuationList == 0 then
            lib.notify({type = 'error', description = "No valuated items found in your inventory"})
            return
        end

        table.insert(valuationList, {
            title = "TOTAL VALUE",
            description = ("$%s"):format(totalValue),
            icon = "fa-money-bill"
        })

        lib.registerContext({
            id = 'pawnshop_valuation_breakdown',
            title = 'Item Valuation',
            options = valuationList
        })

        lib.showContext('pawnshop_valuation_breakdown')
    end)
end)

RegisterNetEvent('exrp-pawn:client:openValuationManager', function()
    lib.callback('exrp-pawn:server:getValuations', false, function(valuations)
        local options = {
            {
                title = 'Add New Valuation',
                icon = 'fa-plus',
                onSelect = function()
                    TriggerEvent('exrp-pawn:client:openValuationSetup')
                end
            }
        }

        for itemName, value in pairs(valuations or {}) do
            local label = exports.ox_inventory:Items()[itemName]?.label or itemName
            options[#options+1] = {
                title = label,
                description = "Current Base Price: $" .. value,
                icon = GetImage(itemName),
                onSelect = function()
                    local input = lib.inputDialog("Edit Valuation - " .. label, {
                        {type = 'number', label = 'New Base Price', default = value, min = 1, required = true}
                    })
                    if input and input[1] then
                        TriggerServerEvent('exrp-pawn:server:updateValuationPrice', itemName, input[1])
                    end
                end
            }
        end

        lib.registerContext({
            id = 'pawnshop_manage_value',
            title = 'Manage Valuations',
            options = options,
            menu = 'pawnshop_manage_menu'
        })

        lib.showContext('pawnshop_manage_value')
    end)
end)

CreateThread(function()
    for job, locs in pairs(Config.ShopLocations) do
        if locs.ped and locs.ped.model and not spawnedPeds[job] then
            local model = locs.ped.model
            RequestModel(model)
            while not HasModelLoaded(model) do Wait(0) end
            local ped = CreatePed(0, model, locs.shop.x, locs.shop.y, locs.shop.z - 1.0, locs.ped.heading or 0.0, false, true)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            spawnedPeds[job] = ped

            exports.ox_target:addLocalEntity(ped, {
                {
                    icon = 'fa-solid fa-shop',
                    label = 'Open Pawnshop',
                    canInteract = function(_, distance)
                        return distance <= 3.0
                    end,
                    onSelect = function()
                        local hour = GetClockHours()
                        if hour >= Config.TimeOpen and hour <= Config.TimeClosed then
                            TriggerServerEvent('exrp-pawn:server:openShop', job)
                        else
                            QBCore.Functions.Notify(("Shop is closed. Open from %02d:00 to %02d:00."):format(Config.TimeOpen, Config.TimeClosed), "error")
                        end
                    end
                }
            })
        end
            
    for k, shop in pairs(Config.ShopLocations) do
        if shop.label and shop.shop then
            local blip = AddBlipForCoord(shop.shop)
            SetBlipSprite(blip, shop.blip and shop.blip.sprite or 617)
            SetBlipScale(blip, shop.blip and shop.blip.scale or 0.7)
            SetBlipColour(blip, shop.blip and shop.blip.color or 5)
            SetBlipDisplay(blip, 4)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(shop.label or "Pawnshop")
            EndTextCommandSetBlipName(blip)
        end
    end

    exports.ox_target:addBoxZone({
        coords = locs.boss,
        size = vec3(1, 1, 1),
        rotation = 0,
        options = {
            {
                icon = 'fa-solid fa-cash-register',
                label = 'Manage Pawnshop',
                canInteract = function(_, distance)
                    local jobName = locs.job  
                    return distance <= 3.0 and hasJobAccess(jobName)  
                end,
                onSelect = function()
                    local jobName = locs.job  
                    TriggerServerEvent('exrp-pawn:server:requestManageStock', jobName)
                end
            },
            {
                name = 'contract_manager',
                icon = 'fas fa-clipboard-list',
                label = 'Manage Contract',
                canInteract = function(_, distance)
                    local jobName = locs.job  
                    return distance <= 3.0 and hasJobAccess(jobName)                
                end,
                onSelect = function()      
                    local jobName = locs.job       
                    TriggerEvent('exrp-pawn:client:openContractMenu', jobName)
                end               
            }
            
        }
    })
    
    exports.ox_target:addBoxZone({
        coords = locs.value,
        size = vec3(1.0, 1.0, 1.0),
        rotation = 0,
        debug = false,
        options = {
            {
                label = 'Run Inventory Valuation',
                icon = 'fas fa-scale-balanced',
                canInteract = function(_, distance)
                    local jobName = locs.job  
                    return distance <= 3.0 and hasJobAccess(jobName)  
                end,
                onSelect = function()              
                    TriggerServerEvent('exrp-pawn:server:runValuation')
                end
            },
        }
    })
    end       

    for k, v in pairs(Config.ShopLocations) do
        for _, stash in pairs(v.stashes) do
            exports.ox_target:addBoxZone({
                coords = stash.coords,
                size = vec3(1.0, 1.0, 1.0),
                rotation = 0,
                debug = false,
                options = {
                    {
                        name = stash.name,
                        icon = "fas fa-box",
                        label = "Open Stash",
                        canInteract = function(entity, distance, data)                         
                            return distance <= 3.0 and hasJobAccess(v.job)  
                        end,
                        onSelect = function()
                            exports.ox_inventory:openInventory('stash', stash.name)
                        end,
                    }
                }
            })
        end   
        
        for _, tray in pairs(v.trays) do
            exports.ox_target:addBoxZone({
                coords = tray.coords,
                size = vec3(1.0, 1.0, 1.0),
                rotation = 0,
                debug = false,
                options = {
                    {
                        name = tray.name,
                        icon = "fas fa-box",
                        label = "Open Tray",
                        canInteract = function(entity, distance, data)
                            return distance <= 2.0
                        end,
                        onSelect = function()
                            exports.ox_inventory:openInventory('stash', tray.name)
                        end,
                    }
                }
            })
        end
    end    
end)
