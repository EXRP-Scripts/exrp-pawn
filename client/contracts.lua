local QBCore = exports['qb-core']:GetCoreObject()
local dropPed, dropBlip, lastDropLabel = nil, nil, nil

RegisterNetEvent('exrp-pawn:client:openContractMenu', function(jobName)
    local playerJob = QBCore.Functions.GetPlayerData().job.name
    if playerJob ~= jobName then return end

    lib.callback('pawnshop:getActiveContractDetails', false, function(contract)
        local options = {}
        local itemData = exports.ox_inventory:Items()

        if not contract or contract.expired then
            table.insert(options, {
                title = 'Generate New Contract',
                icon = 'fas fa-file-signature',
                description = 'Start a new pawn job delivery',
                onSelect = function()
                    lib.callback('pawnshop:generateContract', false, function(success, result)
                        if success then
                            lib.notify({ title = 'Contract', description = 'Contract created! Reward: $' .. result, type = 'success' })
                        else
                            lib.notify({ title = 'Contract', description = result, type = 'error' })
                        end
                    end, jobName)
                end
            })
        else
            local function FormatTimeLeft(seconds)
                if seconds <= 0 then return "Expired" end
                local minutes = math.floor(seconds / 60)
                local secs = seconds % 60
                return string.format("%dm %02ds", minutes, secs)
            end

            local timeLeftStr = FormatTimeLeft(contract.timeLeft or 0)
            local summary = ("Delivery: %s\nTime Left: %s\n\nItems:\n"):format(contract.location, timeLeftStr)

            for _, v in ipairs(contract.items or {}) do
                local label = itemData[v.item] and itemData[v.item].label or v.item
                local amount = v.amount or 1
                local price = (v.price and (v.price * amount)) or nil
                local line = string.format(". %s x%d", label, amount)
                if price then
                    line = line .. string.format(" - $%d", price)
                end
                summary = summary .. line .. "\n"
            end

            table.insert(options, {
                title = "Contract Summary",
                icon = 'fas fa-clipboard-list',
                description = summary:sub(1, 300),
                readOnly = true
            })

            table.insert(options, {
                title = "Set Waypoint",
                description = "Drop-Off: " .. contract.location .. "\nReward: $" .. contract.reward,
                icon = 'fas fa-map-marker-alt',
                onSelect = function()
                    for _, drop in pairs(Config.ContractDropoffs) do
                        if drop.label == contract.location then
                            SetNewWaypoint(drop.location.x, drop.location.y)
                            lib.notify({ title = 'Waypoint Set', description = 'Head to ' .. drop.label, type = 'info' })
                            break
                        end
                    end
                end
            })
        end

        lib.registerContext({
            id = 'pawn_contract_combined',
            title = contract and 'Active Pawn Contract' or 'Pawn Contract',
            options = options
        })
        lib.showContext('pawn_contract_combined')
    end)
end)

RegisterNetEvent('exrp-pawn:client:setupContractDrop', function()
    lib.callback('pawnshop:getActiveContractDetails', false, function(contract)
        if not contract or not contract.location or contract.expired then return end

        if lastDropLabel == contract.location then return end 
        lastDropLabel = contract.location

        for _, drop in pairs(Config.ContractDropoffs) do
            if drop.label == contract.location then
                if dropPed then DeleteEntity(dropPed) dropPed = nil end
                if dropBlip then RemoveBlip(dropBlip) dropBlip = nil end

                if not IsModelInCdimage(drop.ped) then return end

                RequestModel(drop.ped)
                while not HasModelLoaded(drop.ped) do Wait(0) end

                dropPed = CreatePed(0, drop.ped, drop.location.x, drop.location.y, drop.location.z - 1.0, drop.heading, false, true)
                FreezeEntityPosition(dropPed, true)
                SetEntityInvincible(dropPed, true)
                SetBlockingOfNonTemporaryEvents(dropPed, true)
                SetEntityHeading(dropPed, drop.heading)

                exports.ox_target:addBoxZone({
                    coords = drop.location,
                    size = vec3(2, 2, 2),
                    rotation = drop.heading,
                    debug = false,
                    options = {
                        {
                            name = 'contract_dropoff',
                            icon = 'fas fa-box',
                            label = 'Deliver Contract Items',
                            onSelect = function()
                                TriggerServerEvent('pawnshop:completeContract')
                            end
                        }
                    }
                })

                dropBlip = AddBlipForCoord(drop.location)
                SetBlipSprite(dropBlip, 568)
                SetBlipScale(dropBlip, 0.85)
                SetBlipColour(dropBlip, 5)
                SetBlipDisplay(dropBlip, 4)
                SetBlipAsShortRange(dropBlip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("Pawn Drop-Off")
                EndTextCommandSetBlipName(dropBlip)

                if contract.timeLeft and contract.timeLeft > 0 then
                    CreateThread(function()
                        Wait(contract.timeLeft * 1000)
                        if dropPed then DeleteEntity(dropPed) dropPed = nil end
                        if dropBlip then RemoveBlip(dropBlip) dropBlip = nil end
                        lastDropLabel = nil
                    end)
                end

                break
            end
        end
    end)
end)

CreateThread(function()
    Wait(3000)
    TriggerEvent('exrp-pawn:client:setupContractDrop')
end)
