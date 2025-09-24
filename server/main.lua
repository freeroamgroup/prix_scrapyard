if not GetResourceState('prix_core'):find('start') then
    print("^1[prix_scrapyard] ERROR: prix_core is not running. This resource will stop.^0")
    StopResource(GetCurrentResourceName())
    return
end

-- server/main.lua
local ESX = nil
-- pokusit se získat ESX (fallback)
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local tokens = {}          -- tokens[token] = { src, netVeh, expires }
local scrappedVehicles = {} -- scrappedVehicles[netVeh] = true
local cooldowns = {}       -- cooldowns[src] = timestamp when allowed again

-- pomocná fce na generování tokenu
local function makeToken()
    return tostring(math.random(100000,999999)) .. "-" .. tostring(os.time())
end

-- requestStart: client žádá token (server provede základní kontroly)
RegisterNetEvent('source_scrapyard:requestStart', function(netVeh)
    local src = source
    if not netVeh then
        TriggerClientEvent('source_scrapyard:startResult', src, false, 'no_vehicle')
        return
    end

    -- cooldown check
    if cooldowns[src] and cooldowns[src] > os.time() then
        TriggerClientEvent('source_scrapyard:startResult', src, false, 'cooldown')
        return
    end

    -- už rozebrané auto?
    if scrappedVehicles[netVeh] then
        TriggerClientEvent('source_scrapyard:startResult', src, false, 'already')
        return
    end

    -- vytvořit token a uložit do tabulky (vyprší po TotalScrapTime + 15s)
    local token = makeToken()
    local expires = os.time() + math.ceil((Config.TotalScrapTime / 1000)) + 15
    tokens[token] = { src = src, netVeh = netVeh, expires = expires }

    if Config.Debug then
        print(("[source_scrapyard] token created %s for src:%d netVeh:%s expires:%d"):format(token, src, tostring(netVeh), expires))
    end

    TriggerClientEvent('source_scrapyard:startResult', src, true, token)
end)

-- complete: client hlásí dokončení (po progressbaru)
RegisterNetEvent('source_scrapyard:complete', function(token)
    local src = source
    if not token or not tokens[token] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Scrapyard', description = Locales['anti_cheat_failed'], type = 'error' })
        return
    end

    local data = tokens[token]
    if data.src ~= src then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Scrapyard', description = Locales['anti_cheat_failed'], type = 'error' })
        tokens[token] = nil
        return
    end

    -- další ochrana: jestli už někdo rozebral to auto mezi tím
    if scrappedVehicles[data.netVeh] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Scrapyard', description = Locales['already_in_progress'], type = 'error' })
        tokens[token] = nil
        return
    end

    -- přidělit reward (ox_inventory pokud dostupné, jinak ESX fallback)
    local amount = math.random(Config.ScrapReward.min, Config.ScrapReward.max)
    local gave = false
    local ok, resp

    if Config.UseOxInventory and exports and exports.ox_inventory then
        ok, resp = exports.ox_inventory:AddItem(src, Config.ScrapyItem, amount)
        if ok then
            gave = true
        else
            -- pokud AddItem vrátí nil/false, fallback níže
            gave = false
        end
    end

    if not gave and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.addInventoryItem(Config.ScrapyItem, amount)
            gave = true
        end
    end

    if gave then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Scrapyard', description = Locales['scrap_gained']:format(amount), type = 'success' })
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'Scrapyard', description = Locales['scrap_gained_failed'], type = 'error' })
    end

    -- označit vehicle jako rozebrané a nastavit cooldown
    scrappedVehicles[data.netVeh] = true
    cooldowns[src] = os.time() + Config.Cooldown
    tokens[token] = nil

    -- požádat klienty aby vozidlo smazali (server -> všem klientům)
    TriggerClientEvent('source_scrapyard:forceDelete', -1, data.netVeh)
end)

-- cancel: client zrušil rozebírání (např. přerušil progress)
RegisterNetEvent('source_scrapyard:cancel', function(token)
    if token and tokens[token] then
        tokens[token] = nil
    end
end)

-- cleanup thread (vymaže expirované tokeny)
CreateThread(function()
    while true do
        Wait(30 * 1000)
        local now = os.time()
        for token, v in pairs(tokens) do
            if v.expires and v.expires < now then
                tokens[token] = nil
            end
        end
    end
end)
