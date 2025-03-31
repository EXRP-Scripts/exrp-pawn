local QBCore = exports['qb-core']:GetCoreObject()


local VanItems = {
    buying = {
        items = {
            phone = { price = math.random(12, 52), minAmount = 1, maxAmount = 3 },
            copperore = { price = math.random(27, 34), minAmount = 2, maxAmount = 10 },
            goldore = { price = math.random(32, 45), minAmount = 2, maxAmount = 10 },
            silverore = { price = math.random(12, 18), minAmount = 2, maxAmount = 10 },
            ironore = { price = math.random(4, 9), minAmount = 2, maxAmount = 10 },
            carbon = { price = math.random(5, 38), minAmount = 1, maxAmount = 10 },
            goldingot = { price = math.random(78, 138), minAmount = 1, maxAmount = 5 },
            silveringot = { price = math.random(15, 70), minAmount = 1, maxAmount = 5 },
            uncut_emerald = { price = math.random(54, 68), minAmount = 1, maxAmount = 5 },
            uncut_ruby = { price = math.random(62, 108), minAmount = 1, maxAmount = 5 },
            uncut_diamond = { price = math.random(86, 156), minAmount = 1, maxAmount = 5 },
            uncut_sapphire = { price = math.random(58, 95), minAmount = 1, maxAmount = 5 },
            emerald = { price = math.random(90, 214), minAmount = 1, maxAmount = 5 },
            ruby = { price = math.random(124, 238), minAmount = 1, maxAmount = 5 },
            diamond = { price = math.random(138, 272), minAmount = 1, maxAmount = 5 },
            sapphire = { price = math.random(90, 204), minAmount = 1, maxAmount = 5 },
            diamond_ring = { price = math.random(280, 408), minAmount = 1, maxAmount = 3 },
            emerald_ring = { price = math.random(206, 340), minAmount = 1, maxAmount = 3 },
            ruby_ring = { price = math.random(240, 374), minAmount = 1, maxAmount = 3 },
            sapphire_ring = { price = math.random(308, 442), minAmount = 1, maxAmount = 3 },
            diamond_ring_silver = { price = math.random(206, 340), minAmount = 1, maxAmount = 3 },
            emerald_ring_silver = { price = math.random(158, 272), minAmount = 1, maxAmount = 3 },
            ruby_ring_silver = { price = math.random(178, 306), minAmount = 1, maxAmount = 3 },
            sapphire_ring_silver = { price = math.random(178, 306), minAmount = 1, maxAmount = 3 },
            diamond_necklace = { price = math.random(376, 510), minAmount = 1, maxAmount = 3 },
            emerald_necklace = { price = math.random(274, 408), minAmount = 1, maxAmount = 3 },
            ruby_necklace = { price = math.random(274, 408), minAmount = 1, maxAmount = 3 },
            sapphire_necklace = { price = math.random(260, 374), minAmount = 1, maxAmount = 3 },
            diamond_necklace_silver = { price = math.random(360, 374), minAmount = 1, maxAmount = 3 },
            emerald_necklace_silver = { price = math.random(206, 320), minAmount = 1, maxAmount = 3 },
            ruby_necklace_silver = { price = math.random(240, 374), minAmount = 1, maxAmount = 3 },
            sapphire_necklace_silver = { price = math.random(186, 312), minAmount = 1, maxAmount = 3 },
            diamond_earring = { price = math.random(299, 306), minAmount = 1, maxAmount = 3 },
            emerald_earring = { price = math.random(170, 187), minAmount = 1, maxAmount = 3 },
            ruby_earring = { price = math.random(211, 224), minAmount = 1, maxAmount = 3 },
            sapphire_earring = { price = math.random(190, 204), minAmount = 1, maxAmount = 3 },
            diamond_earring_silver = { price = math.random(104, 218), minAmount = 1, maxAmount = 3 },
            emerald_earring_silver = { price = math.random(99, 163), minAmount = 1, maxAmount = 3 },
            ruby_earring_silver = { price = math.random(86, 146), minAmount = 1, maxAmount = 3 },
            sapphire_earring_silver = { price = math.random(72, 108), minAmount = 1, maxAmount = 3 },
            gold_ring = { price = math.random(22, 48), minAmount = 1, maxAmount = 5 },
            goldchain = { price = math.random(22, 95), minAmount = 1, maxAmount = 5 },
            goldearring = { price = math.random(16, 35), minAmount = 1, maxAmount = 5 },
            silver_ring = { price = math.random(14, 37), minAmount = 1, maxAmount = 5 },
            silverchain = { price = math.random(18, 71), minAmount = 1, maxAmount = 5 },
            silverearring = { price = math.random(14, 27), minAmount = 1, maxAmount = 5 },
            copper = { price = math.random(1, 13), minAmount = 5, maxAmount = 20 },
            plastic = { price = math.random(1, 15), minAmount = 5, maxAmount = 20 },
            metalscrap = { price = math.random(1, 15), minAmount = 5, maxAmount = 20 },
            steel = { price = math.random(3, 14), minAmount = 5, maxAmount = 20 },
            glass = { price = math.random(2, 18), minAmount = 5, maxAmount = 20 },
            iron = { price = math.random(8, 18), minAmount = 5, maxAmount = 20 },
            rubber = { price = math.random(1, 8), minAmount = 5, maxAmount = 20 },
            aluminum = { price = math.random(1, 16), minAmount = 5, maxAmount = 20 },
            bottle = { price = math.random(1, 2), minAmount = 10, maxAmount = 50 },
            can = { price = math.random(1, 2), minAmount = 10, maxAmount = 50 }
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
