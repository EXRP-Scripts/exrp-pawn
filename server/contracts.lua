local QBCore = exports['qb-core']:GetCoreObject()


local VanItems = {
    buying = {
        items = {
            phone = { price = math.random(12, 52), minAmount = 1, maxAmount = 3 },
            goldcoin = { price = math.random(12, 52), minAmount = 1, maxAmount = 3 },
            silvercoin = { price = math.random(12, 52), minAmount = 1, maxAmount = 3 }
        }
    }
}

lib.callback.register('pawnshop:generateContract', function(source, shopJob)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or Player.PlayerData.job.name ~= shopJob then
        return false
    end

    local active = MySQL.query.await('SELECT 1 FROM pawn_store_orders WHERE job = ? AND completed = 0 LIMIT 1', { shopJob })
    if active and #active > 0 then
        return false
    end

    local last = MySQL.query.await('SELECT completed_at FROM pawn_store_orders WHERE job = ? AND completed = 1 ORDER BY completed_at DESC LIMIT 1', { shopJob })
    if last[1] and tonumber(last[1].completed_at) then
        local timeSince = os.time() - tonumber(last[1].completed_at)
        if timeSince < Config.ContractCooldown then
            local minutesLeft = math.ceil((Config.ContractCooldown - timeSince) / 60)
            return false, "Wait " .. minutesLeft .. " more minute(s) before a new contract."
        end
    end

    local availableItems = {}
    for item, data in pairs(VanItems.buying.items) do
        table.insert(availableItems, { name = item, data = data })
    end
    for i = #availableItems, 2, -1 do
        local j = math.random(i)
        availableItems[i], availableItems[j] = availableItems[j], availableItems[i]
    end

    local toPick = math.random(Config.ContractItemCount.min, Config.ContractItemCount.max)
    local items, totalReward = {}, 0
    for i = 1, math.min(toPick, #availableItems) do
        local entry = availableItems[i]
        local amt = math.random(entry.data.minAmount, entry.data.maxAmount)
        table.insert(items, { item = entry.name, amount = amt })
        totalReward = totalReward + (amt * entry.data.price)
    end
    if #items == 0 then return false, "No suitable items found." end

    local drop = Config.ContractDropoffs[math.random(#Config.ContractDropoffs)]
    local dropLabel = drop.label or "Unknown Drop"
    local now = os.time()

    MySQL.insert.await([[
        INSERT INTO pawn_store_orders (job, items, reward, location, created_by, created_at, dueby)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        shopJob,
        json.encode(items),
        totalReward,
        dropLabel,
        GetPlayerIdentifiers(source)[1],
        now,
        now + Config.ContractDuration
    })

    return true, totalReward
end)

lib.callback.register('pawnshop:getActiveContractDetails', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end

    local job = Player.PlayerData.job.name
    local result = MySQL.query.await('SELECT * FROM pawn_store_orders WHERE job = ? AND completed = 0 LIMIT 1', { job })

    if not result or #result == 0 then return nil end

    local contract = result[1]
    local items = json.decode(contract.items or "[]")

    for i = 1, #items do
        local configItem = VanItems.buying.items[items[i].item]
        if configItem then items[i].price = configItem.price end
    end

    local timeLeft = contract.dueby - os.time()
    if timeLeft <= 0 then
        MySQL.update.await('UPDATE pawn_store_orders SET completed = 1, completed_at = ? WHERE id = ?', { os.time(), contract.id })
        return { expired = true }
    end

    return {
        items = items,
        reward = contract.reward,
        location = contract.location,
        timeLeft = timeLeft
    }
end)

RegisterNetEvent('exrp-pawn:completeContract', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local job = Player.PlayerData.job.name
    local contractResult = MySQL.query.await('SELECT * FROM pawn_store_orders WHERE job = ? AND completed = 0 LIMIT 1', { job })
    if not contractResult or #contractResult == 0 then return end

    local contract = contractResult[1]
    local items = json.decode(contract.items or "[]")

    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local targetDrop = nil

    for _, drop in pairs(Config.ContractDropoffs) do
        if drop.label == contract.location then
            targetDrop = drop
            break
        end
    end

    if not targetDrop then return end

    local dropCoords = vector3(targetDrop.location.x, targetDrop.location.y, targetDrop.location.z)
    local distance = #(playerCoords - dropCoords)
    if distance > 5.0 then return end

    for _, item in pairs(items) do
        if exports.ox_inventory:GetItemCount(src, item.item) < item.amount then
            TriggerClientEvent('ox_lib:notify', src, {title = 'Missing Items', description = "You don't have enough " .. item.item, type = 'error' })
            return
        end
    end
    for _, item in pairs(items) do
        exports.ox_inventory:RemoveItem(src, item.item, item.amount)
    end

    exports.ox_inventory:AddItem(src, 'money', contract.reward)
    
    MySQL.update.await('UPDATE pawn_store_orders SET completed = 1, completed_at = ? WHERE id = ?', {os.time(), contract.id})
    TriggerClientEvent('ox_lib:notify', src, {title = 'Contract Complete', description = 'Delivered and earned $' .. contract.reward,  type = 'success'})
end)
