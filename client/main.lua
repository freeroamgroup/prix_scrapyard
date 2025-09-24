-- client/main.lua
local scrappingActive = false
local activeToken = nil

-- check jestli hráč je ve scrapyard lokaci
local function IsInScrapyard(coords)
    for _, yard in ipairs(Config.Scrapyards) do
        if #(coords - yard.coords) <= (yard.radius or 6.0) then
            return true
        end
    end
    return false
end

-- vytvoření blipů (nezmizí!)
CreateThread(function()
    for _, yard in ipairs(Config.Scrapyards) do
        if yard.blip and yard.blip.enabled then
            local b = AddBlipForCoord(yard.coords.x, yard.coords.y, yard.coords.z)
            SetBlipSprite(b, yard.blip.sprite)
            SetBlipColour(b, yard.blip.color)
            SetBlipScale(b, yard.blip.scale)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(yard.blip.label)
            EndTextCommandSetBlipName(b)
        end
    end
end)

-- ox_target: interakce přímo na auta
CreateThread(function()
    exports.ox_target:addGlobalVehicle({
        {
            icon = 'fa-solid fa-car',
            label = Locales['press_to_scrap'],
            canInteract = function(entity)
                if scrappingActive then return false end
                if IsPedInAnyVehicle(PlayerPedId(), false) then return false end
                if not IsInScrapyard(GetEntityCoords(PlayerPedId())) then return false end

                local vclass = GetVehicleClass(entity)
                for _, c in ipairs(Config.AllowedClasses) do
                    if vclass == c then return true end
                end
                return false
            end,
            onSelect = function(data)
                if scrappingActive then return end
                TriggerServerEvent('prix_scrapyard:requestStart', VehToNet(data.entity))
            end
        }
    })
end)

-- server odpověď
RegisterNetEvent('prix_scrapyard:startResult', function(success, tokenOrReason)
    if not success then
        local reason = tokenOrReason or 'unknown'
        if reason == 'cooldown' then
            lib.notify({ title = 'Scrapyard', description = Locales['cooldown'], type = 'error' })
        else
            lib.notify({ title = 'Scrapyard', description = Locales['anti_cheat_failed'], type = 'error' })
        end
        return
    end

    scrappingActive = true
    activeToken = tokenOrReason
    local token = activeToken
    local ped = PlayerPedId()

    lib.requestAnimDict('mini@repair')

    -- spustit progress v separátním threadu
    CreateThread(function()
        local successProgress = lib.progressBar({
            duration = Config.TotalScrapTime,
            label = Locales[Config.ProgressLabelKey],
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = {
                dict = 'mini@repair',
                clip = 'fix_engine'
            }
        })

        ClearPedTasks(ped)

        if successProgress then
            scrappingActive = false
            TriggerServerEvent('prix_scrapyard:complete', token)
        else
            scrappingActive = false
            TriggerServerEvent('prix_scrapyard:cancel', token)
            lib.notify({ title = 'Scrapyard', description = Locales['scrap_canceled'], type = 'error' })
        end
    end)

    -- plánované notifikace během stage (trvá celou dobu každé stage)
    CreateThread(function()
        local token = activeToken
        for i, dur in ipairs(Config.StageDurations) do
            if not scrappingActive or activeToken ~= token then break end
            local localeKey = Config.StageLocaleKeys[i]
            lib.notify({
                id = 'scrapyard_stage', -- aktualizuje stejnou notifikaci
                title = 'Scrapyard',
                description = Locales[localeKey],
                type = 'inform',
                duration = dur -- zůstane aktivní po dobu stage
            })
            Wait(dur)
        end
    end)
end)

-- smazání auta
RegisterNetEvent('prix_scrapyard:forceDelete', function(netVeh)
    if not netVeh then return end
    local entity = NetToVeh(netVeh)
    if DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end)
