local language = "en"  -- en and de

local blacklistURL = "YOUR_URL_TO_BLACKLIST.JSON"
local discordWebhookURL = "YOUR_WEBHOOK"  -- server starts / stops , and when a server starts with blacklist

local messages = {
    de = {
        heartbeat = "^2[^3FlowService.xyz^2]^2 ^7 >> 💓  〢 Sende Herzschlag zu FlowService.xyz",
        ServiceOffline = "^2[^3FlowService.xyz^2]^2 ^7 >> ❌  〢 FlowService ist offline!",
        checkBlacklist = "^2[^3FlowService.xyz^2]^2 ^7 >> ⏳  〢 Überprüfe ^1Blacklist^7 Status..",
        blacklisted = "^2[^3FlowService.xyz^2]^2 ^7 >> ❌  〢 ^4%s^7 ist ^1geblacklistet! ^7 Grund: %s",
        contactSupport = "^2[^3FlowService.xyz^2]^2 ^7 >> ❌  〢 Bitte kontaktiere ^4dasentlein_backup",
        shutdown = "^2[^3FlowService.xyz^2]^2 ^7 >> ❌  〢 Server wird heruntergefahren!",
        noBlacklist = "^2[^3FlowService.xyz^2]^2 ^7 >> ✅  〢 Keine ^1Blacklist ^7für ^4%s^7 gefunden!",
        scriptStarted = "^2[^3FlowService.xyz^2]^2 ^7 >> ✅  〢 Script ^2erfolgreich ^7gestartet!",
        ipError = "^1[FlowService.xyz] >> 🧿  〢 Fehler beim Abrufen der Server-IP!",
        blacklistError = "^1[FlowService.xyz] >> 🧿  〢 Fehler: Unerwartetes Format von der Blacklist-API"
    },
    en = {
        heartbeat = "^2[^3FlowService.xyz^2]^2 ^7 >> 💓  〢 Sending Heartbeat to FlowService.xyz",
        ServiceOffline = "^2[^3FlowService.xyz^2]^2 ^7 >> ❌  〢 FlowService is offline!",
        checkBlacklist = "^2[^3FlowService.xyz^2]^2 ^7 >> ⏳  〢 Checking ^1Blacklist^7 status..",
        blacklisted = "^2[^3FlowService.xyz^2]^2 ^7 >> ❌  〢 ^4%s^7 is ^1blacklisted! ^7 Reason: %s",
        contactSupport = "^2[^3FlowService.xyz^2]^2 ^7 >> ❌  〢 Please contact ^4dasentlein_backup",
        shutdown = "^2[^3FlowService.xyz^2]^2 ^7 >> ❌  〢 Server shutting down!",
        noBlacklist = "^2[^3FlowService.xyz^2]^2 ^7 >> ✅  〢 No ^1Blacklist ^7for ^4%s^7 found!",
        scriptStarted = "^2[^3FlowService.xyz^2]^2 ^7 >> ✅  〢 Script ^2successfully ^7started!",
        ipError = "^1[FlowService.xyz] >> 🧿  〢 Error retrieving Server IP!",
        blacklistError = "^1[FlowService.xyz] >> 🧿  〢 Error: Unexpected format from Blacklist API"
    }
  -- ADD MORE HERE
}


local function sendToDiscord(embed)
    local payload = {
        embeds = { embed },
    }
    PerformHttpRequest(discordWebhookURL, function(err, text, headers) end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

-- Function to print messages
local function printMessage(key, ...)
    local msg = messages[language][key]
    if msg then
        print(msg:format(...))
    end
end

-- Check if IP is blacklisted
function isBlacklisted(ip, callback)
    PerformHttpRequest(blacklistURL, function(err, text, headers)
        if err == 200 then
            local data = json.decode(text)
            if data and type(data) == "table" then
                for _, entry in pairs(data) do
                    if entry.ip == ip then
                        callback(entry.reason)
                        return
                    end
                end
            else
                printMessage("blacklistError")
            end
        else
            printMessage("ServiceOffline")
            printMessage("contactSupport")
            Wait(500)
            printMessage("shutdown")
            Wait(5000)
            os.exit()
            sendToDiscord({ 
                title = "Service Offline", 
                description = "The server is offline! Please contact support.", 
                color = 0xFF0000  -- Red
            })
            return
        end 
        callback(nil)
    end, "GET")
end

-- Get Server IP
function getServerIP(callback)
    PerformHttpRequest("http://api.ipify.org", function(err, ip, headers)
        if err == 200 then
            callback(ip)
        else
            printMessage("ipError")
            callback(nil)
        end
    end, "GET")
end

-- Event when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        local serverName = GetConvar("sv_hostname", "Unknown Server")
        
        getServerIP(function(serverIP)
            if serverIP then
                printMessage("heartbeat")
                sendToDiscord({
                    title = "Server Started / Ressource started",
                    description = "The server **" .. serverName .. "** is starting up.",
                    fields = {
                        { name = "Server IP", value = serverIP, inline = true },
                        { name = "Status", value = "Online", inline = true }
                    },
                    color = 0x00FF00
                })
                printMessage("checkBlacklist")
                Wait(2000)
                
                isBlacklisted(serverIP, function(reason)
                    if reason then
                        printMessage("blacklisted", serverName, reason)
                        sendToDiscord({
                            title = "Blacklisted IP Detected",
                            description = "The server **" .. serverName .. "** has a blacklisted IP.",
                            fields = {
                                { name = "Server IP", value = serverIP, inline = true },
                                { name = "Reason", value = reason, inline = false }
                            },
                            color = 0xFF0000
                        })
                        printMessage("contactSupport")
                        Wait(500)
                        printMessage("shutdown")
                        Wait(5000)
                        os.exit()
                    else
                        printMessage("noBlacklist", serverName)
                        Wait(2000)
                        printMessage("scriptStarted")
                    end
                end)
            else
                printMessage("ipError")
            end
        end)
    end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        sendToDiscord({
            title = "Server Stopped / Ressource Stop",
            description = "The server **" .. GetConvar("sv_hostname", "Unknown Server") .. "** has stopped.",
            color = 0xFFA500
        })
    end
end)
