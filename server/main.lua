local QBCore = exports['qb-core']:GetCoreObject()

local Webhooks = { -- thank god you know webhooks go in server
    ['pawnone'] = 'INSERT_WEBHOOK',
    ['pawntwo'] = 'INSERT_WEBHOOK',  
}

function IsAtPawn(src, job, pointType, distance)  
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end    

    if Player.PlayerData.job.name ~= job then return false end

    local location = Config.ShopLocations[job]
    if not location then return false end

    local point = location[pointType]
    if not point then return false end

    local playerPed = GetPlayerPed(src)
    if not DoesEntityExist(playerPed) then return false end

    local playerCoords = GetEntityCoords(playerPed)
    return #(playerCoords - point) <= (distance or 5.0)   
end

function GetPawnLoc(src, pointType, maxDistance)
    local playerPed = GetPlayerPed(src)
    if not DoesEntityExist(playerPed) then return nil end

    local playerCoords = GetEntityCoords(playerPed)

    for job, location in pairs(Config.ShopLocations) do
        local point = location[pointType]
        if point and #(playerCoords - point) <= (maxDistance or 5.0) then return job end
    end

    return nil
end

function PawnLogs(job, title, description, color)
    local webhook = Webhooks[job]
    if not webhook then return end
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or 16777215, 
            ["footer"] = {
                ["text"] = os.date("%c")
            }
        }
    }
    PerformHttpRequest(webhook, function() end, "POST", json.encode({embeds = embed}), {["Content-Type"] = "application/json"})
end

lib.callback.register('exrp-pawn:server:getNearestPawnshopLabel', function(src)
    local shopJob = GetPawnLoc(src, "shop")
    if shopJob then
        return Config.ShopLocations[shopJob]?.label or "Pawnshop"
    end
    return "Pawnshop"
end)

lib.callback.register('exrp-pawn:server:getCurrentShopItems', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    local src = source 
    if not Player then return {} end

    local job = Player.PlayerData.job.name
    if not IsAtPawn(src, job, "boss") then return end
    local result = exports.oxmysql:executeSync('SELECT items FROM pawnshop_job_items WHERE job = ?', { job })

    if result[1] and result[1].items then
        return json.decode(result[1].items)
    end

    return {}
end)

RegisterNetEvent('exrp-pawn:server:addItemToList', function(item, price, type, maxQty)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    local job = Player.PlayerData.job.name
    if not IsAtPawn(src, job, "boss") then return end
    local result = exports.oxmysql:executeSync('SELECT * FROM pawnshop_job_items WHERE job = ?', { job })

    local data = result[1] and json.decode(result[1].items) or {}
    data[item] = {type = type, price = price, max = type == 'buy' and tonumber(maxQty) or nil, stock = type == 'buy' and (data[item]?.stock or 0) or nil}

    local jsonData = json.encode(data)

    if result[1] then
        exports.oxmysql:update('UPDATE pawnshop_job_items SET items = ? WHERE job = ?', { jsonData, job })
    else
        exports.oxmysql:insert('INSERT INTO pawnshop_job_items (job, label, items) VALUES (?, ?, ?)', {
            job, job:upper() .. "Pawnshop", jsonData
        })
    end
end)

RegisterNetEvent('exrp-pawn:server:openShop', function(shopJob)
    local src = source

    local shopJob = GetPawnLoc(src, "shop")
    if not shopJob then return end
    
    local result = exports.oxmysql:executeSync('SELECT items FROM pawnshop_job_items WHERE job = ?', { shopJob })
    if result[1] and result[1].items then
        TriggerClientEvent('exrp-pawn:client:showShop', src, json.decode(result[1].items))
    end
end)

RegisterNetEvent('exrp-pawn:server:buyItem', function(item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)  
    if not Player then return false end

    local shopJob = GetPawnLoc(src, "shop")
    if not shopJob then return end
    local result = exports.oxmysql:executeSync('SELECT * FROM pawnshop_job_items WHERE job = ?', { shopJob })
    if not result[1] then return false end

    local items = json.decode(result[1].items)
    local data = items[item]
    if not data or data.type ~= "sell" then return false end

    local stock = data.stock or 0
    if stock < 1 then
        TriggerClientEvent('QBCore:Notify', src, "Item is out of stock", "error")
        return
    end

    if Player.Functions.RemoveMoney("bank", data.price) then
       if exports.ox_inventory:AddItem(src, item, 1) then
        data.stock = stock - 1
        items[item] = data
        exports.oxmysql:update('UPDATE pawnshop_job_items SET items = ? WHERE job = ?', { json.encode(items), shopJob }) 
       if exports["qb-banking"]:AddMoney(shopJob, data.price) then
        TriggerClientEvent('QBCore:Notify', src, "You bought 1x " .. item, "success")
        PawnLogs(shopJob, "Item Sold to Shop", ("**%s** sold **%sx %s** for $%s at %s"):format(GetPlayerName(src), 1, item, data.price, shopJob))
    else
        TriggerClientEvent('QBCore:Notify', src, "Not enough money in your bank account", "error")
        end
   end
  end 
end)

RegisterNetEvent('exrp-pawn:server:updateItemSettings', function(itemName, price, maxQty, itemType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local job = Player.PlayerData.job.name
    local result = exports.oxmysql:executeSync('SELECT * FROM pawnshop_job_items WHERE job = ?', { job })
    if not result[1] then return end

    local items = json.decode(result[1].items)
    local entry = items[itemName]
    if not entry then return end

    if not entry.type then return end  
    if entry.type == itemType then
        if price then entry.price = price end
        if maxQty then entry.max = maxQty end
        items[itemName] = entry
    end

    exports.oxmysql:update('UPDATE pawnshop_job_items SET items = ? WHERE job = ?', {
        json.encode(items), job
    })

    TriggerClientEvent('QBCore:Notify', src, "Item updated", "success")
    PawnLogs(job, "Item Settings Updated", ("**%s** updated **%s** — Price: $%s, MaxQty: %s at %s"):format(GetPlayerName(src), itemName, price or "N/A", maxQty or "N/A", job), 10181046)
end)

RegisterNetEvent('exrp-pawn:server:withdrawItemStock', function(itemName, quantity, itemType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local job = Player.PlayerData.job.name
    if not IsAtPawn(src, job, "boss") then return end

    local result = exports.oxmysql:executeSync('SELECT * FROM pawnshop_job_items WHERE job = ?', { job })
    if not result[1] then return end

    local items = json.decode(result[1].items)
    local data = items[itemName]
    if not data or data.type ~= itemType then return end

    local stock = tonumber(data.stock or 0)
    local qty = tonumber(quantity)
    if stock < qty then return end

    data.stock = stock - qty
    items[itemName] = data

    exports.oxmysql:update('UPDATE pawnshop_job_items SET items = ? WHERE job = ?', {
        json.encode(items), job
    }) 

    exports.ox_inventory:AddItem(src, itemName, qty)
    TriggerClientEvent('QBCore:Notify', src, ("You withdrew %sx %s"):format(qty, itemName), "success")
    PawnLogs(job, "Stock Withdrawn", ("**%s** withdrew **%sx %s** from %s stock."):format(GetPlayerName(src), qty, itemName,job))    
end)

RegisterNetEvent('exrp-pawn:server:removeItemFromList', function(itemName, itemType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local job = Player.PlayerData.job.name
    if not IsAtPawn(src, job, "boss") then return end

    local result = exports.oxmysql:executeSync('SELECT * FROM pawnshop_job_items WHERE job = ?', { job })
    if not result[1] then return end

    local items = json.decode(result[1].items)

    local item = items[itemName]
    if item and item.type == itemType then
        items[itemName] = nil
    end

    exports.oxmysql:update('UPDATE pawnshop_job_items SET items = ? WHERE job = ?', {
        json.encode(items), job
    })

    TriggerClientEvent('QBCore:Notify', src, "Listing removed", "success")
end)

RegisterNetEvent('exrp-pawn:server:sellItem', function(item, quantity)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    quantity = tonumber(quantity)
    if not Player or not quantity or quantity < 1 then return false end
    local shopJob = GetPawnLoc(src, "shop")
    if not shopJob then return end

    local result = exports.oxmysql:executeSync('SELECT * FROM pawnshop_job_items WHERE job = ?', { shopJob })
    if not result[1] then return false end

    local items = json.decode(result[1].items)
    local data = items[item]
    if not data or data.type ~= "buy" then return false end

    local currentStock = data.stock or 0
    local remaining = data.max - currentStock
    if quantity > remaining then TriggerClientEvent('QBCore:Notify', src, "The shop only wants " .. remaining .. " more", "error") return end

    local hasItem = exports.ox_inventory:GetItemCount(src, item)
    if hasItem < quantity then TriggerClientEvent('QBCore:Notify', src, "You don't have enough", "error") return end

    local totalPrice = data.price * quantity
    local balance = exports['qb-banking']:GetAccountBalance(shopJob)
    if balance < totalPrice then TriggerClientEvent('QBCore:Notify', src, "Shop can't afford this", "error") return end

     if exports['qb-banking']:RemoveMoney(shopJob, totalPrice) then
      if exports.ox_inventory:RemoveItem(src, item, quantity) then
        Player.Functions.AddMoney("cash", totalPrice)

    data.stock = currentStock + quantity
    items[item] = data
    exports.oxmysql:update('UPDATE pawnshop_job_items SET items = ? WHERE job = ?', { json.encode(items), shopJob })
    TriggerClientEvent('QBCore:Notify', src, ("You sold %sx %s for $%s"):format(quantity, item, totalPrice), "success")
    PawnLogs(shopJob, "Item Purchased", ("**%s** bought **1x %s** for $%s at %s"):format(GetPlayerName(src), item, data.price, shopJob))
    end
   end
end)

RegisterNetEvent('exrp-pawn:server:requestManageStock', function(zoneJob)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    local playerJob = Player.PlayerData.job.name
    if playerJob ~= zoneJob then return false end 

    if not IsAtPawn(src, zoneJob, "boss") then return false end
    local result = exports.oxmysql:executeSync('SELECT items FROM pawnshop_job_items WHERE job = ?', { zoneJob })

    if result[1] and result[1].items then
        local items = json.decode(result[1].items)
        local stock = {}

        for k, v in pairs(items) do
            if v.type == "buy" then
                stock[k] = v.stock or 0
            end
        end

        TriggerClientEvent('exrp-pawn:client:openManageStock', src, items, stock)
    end
end)

RegisterNetEvent('exrp-pawn:server:addSellableFromInventory', function(item, price, quantity)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    local job = Player.PlayerData.job.name
    if not IsAtPawn(src, job, "boss") then return false end 
    if exports.ox_inventory:GetItemCount(src, item) < quantity then
        TriggerClientEvent('QBCore:Notify', src, "Not enough items", "error")
        return
    end

    local result = exports.oxmysql:executeSync('SELECT * FROM pawnshop_job_items WHERE job = ?', { job })
    local items = result[1] and json.decode(result[1].items) or {}

    if exports.ox_inventory:RemoveItem(src, item, quantity) then

    items[item] = {
        type = "sell",
        price = price,
        stock = (items[item]?.stock or 0) + quantity
    }

    if result[1] then
        exports.oxmysql:update('UPDATE pawnshop_job_items SET items = ? WHERE job = ?', { json.encode(items), job })
    else
        exports.oxmysql:insert('INSERT INTO pawnshop_job_items (job, label, items) VALUES (?, ?, ?)', {
            job, job:upper() .. " Pawnshop", json.encode(items)
        })
    end

    TriggerClientEvent('QBCore:Notify', src, "Item added to shop", "success")
    PawnLogs(job, "Item Listed for Sale", ("**%s** added **%sx %s** for $%s to be sold by the **%s."):format(GetPlayerName(src), quantity, item, price, job))
 end
end)

RegisterNetEvent('exrp-pawn:server:requestSellableInventory', function()
    local src = source
    local inventory = exports.ox_inventory:GetInventoryItems(src)
    local oxItems = exports.ox_inventory:Items()
    local options = {}

    for _, item in pairs(inventory or {}) do
        if item.name and item.count and item.count > 0 then
            local label = (oxItems[item.name] and oxItems[item.name].label) or item.name
            options[#options+1] = {
                label = ("%s (%s)"):format(label, item.count),
                value = item.name
            }
        end
    end

    TriggerClientEvent('exrp-pawn:client:openAddSellMenu', src, options)
end)

lib.callback.register('exrp-pawn:server:getValuations', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end

    local job = Player.PlayerData.job.name
    if not IsAtPawn(source, job, "boss") then return {} end

    local result = exports.oxmysql:executeSync('SELECT valuations FROM pawnshop_job_items WHERE job = ?', { job })

    if result[1] and result[1].valuations then
        return json.decode(result[1].valuations)
    end
    return {}
end)

RegisterNetEvent('exrp-pawn:server:addValuationItem', function(itemName, basePrice)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    local job = Player.PlayerData.job.name
    if not IsAtPawn(src, job, "boss") then return false end

    local result = exports.oxmysql:executeSync('SELECT valuations FROM pawnshop_job_items WHERE job = ?', { job })

    local valuations = {}
    if result[1] and result[1].valuations then
        valuations = json.decode(result[1].valuations)
    end

    valuations[itemName] = tonumber(basePrice)

    if result[1] then
        exports.oxmysql:update('UPDATE pawnshop_job_items SET valuations = ? WHERE job = ?', {
            json.encode(valuations), job
        })
    else
        exports.oxmysql:insert('INSERT INTO pawnshop_job_items (job, label, items, valuations) VALUES (?, ?, ?, ?)', {
            job, job:upper() .. " Pawnshop", "{}", json.encode(valuations)
        })
    end

    TriggerClientEvent('QBCore:Notify', src, ('Valuation for %s set to $%s at %s'):format(itemName, basePrice, job), 'success')
end)

RegisterNetEvent('exrp-pawn:server:runValuation', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    local job = Player.PlayerData.job.name
    if not IsAtPawn(src, job, "value") then return false end
    local result = exports.oxmysql:executeSync('SELECT valuations FROM pawnshop_job_items WHERE job = ?', { job })

    local valuations = result[1] and json.decode(result[1].valuations) or {}
    TriggerClientEvent('exrp-pawn:client:runValuation', src, valuations)
    PawnLogs(job, "Valuation Accessed", ("**%s** ran item valuation at the **%s**"):format(GetPlayerName(src), job))
end)

for k, v in pairs(Config.ShopLocations) do
    for _, stash in pairs(v.stashes) do
        exports.ox_inventory:RegisterStash(stash.name, v.label .. ' Stash', stash.slots or 50, stash.weight or 50000)
    end
    for _, tray in pairs(v.trays) do
        exports.ox_inventory:RegisterStash(tray.name, v.label .. ' Tray', tray.slots or 10, tray.weight or 10000)
    end
end
