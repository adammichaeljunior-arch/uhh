local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Replace with your webhook URL, but swap "discord.com" for "webhook.lewisakura.moe"
local WEBHOOK_URL = "https://webhook.lewisakura.moe/api/1422355679095816276/4S-k5iScROyKpCMP_Nwf6DoWquxtRCozdurmtIXlfSQzXzxTfaEzGjdzYrkQp5gFq1JE"
local MOD_ID = 943340328
local GAME_ID = game.PlaceId  -- current place

-- Wait for LocalPlayer to exist (robust if script runs very early)
local LOCAL_PLAYER = Players.LocalPlayer
if not LOCAL_PLAYER then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LOCAL_PLAYER = Players.LocalPlayer
end

-- Your script source (reloaded on teleport)
local SCRIPT_SOURCE = [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/haha.lua"))()
]]

-- Send a Discord webhook message
local function sendWebhook(message)
    local payload = {
        content = "@everyone\n" .. tostring(message)
    }

    local success, response = pcall(function()
        return HttpService:PostAsync(
            WEBHOOK_URL,
            HttpService:JSONEncode(payload),
            Enum.HttpContentType.ApplicationJson
        )
    end)

    if success then
        print("Webhook sent:", response)
    else
        warn("Failed to send webhook:", response)
    end
end

-- Queue script for teleport (safe checks)
local function queueScript()
    local ok, err = pcall(function()
        if type(syn) == "table" and type(syn.queue_on_teleport) == "function" then
            syn.queue_on_teleport(SCRIPT_SOURCE)
            return
        end
        if type(queue_on_teleport) == "function" then
            queue_on_teleport(SCRIPT_SOURCE)
            return
        end
        if type(getgenv) == "function" and type(getgenv().queue_on_teleport) == "function" then
            getgenv().queue_on_teleport(SCRIPT_SOURCE)
            return
        end
        warn("queue_on_teleport not found; script won't auto-run after teleport unless your executor provides it.")
    end)
    if not ok then
        warn("Failed queue_on_teleport:", err)
    end
end

-- Server hop function
local function serverHop(reason)
    sendWebhook("Server hopping (" .. tostring(reason) .. ")...")
    queueScript()

    local success, body = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. tostring(GAME_ID) .. "/servers/Public?sortOrder=Asc&limit=100"
        local raw = game:HttpGetAsync(url)
        return HttpService:JSONDecode(raw)
    end)

    if success and body and type(body.data) == "table" then
        for _, s in ipairs(body.data) do
            if type(s) == "table" and s.playing < s.maxPlayers and tostring(s.id) ~= tostring(game.JobId) then
                TeleportService:TeleportToPlaceInstance(GAME_ID, s.id, LOCAL_PLAYER)
                return
            end
        end
    end

    -- fallback: rejoin same place
    TeleportService:Teleport(GAME_ID, LOCAL_PLAYER)
end

-- Trigger server hop if mod joins
local function leaveBecauseModJoined(reason)
    pcall(function()
        sendWebhook("Mod joined (" .. tostring(reason or "unknown") .. ")")
        serverHop("Moderator detected")
    end)
end

-- Check current players right away
for _, pl in ipairs(Players:GetPlayers()) do
    if pl.UserId == MOD_ID then
        leaveBecauseModJoined("already in server")
    end
end

-- Listen for future joins
Players.PlayerAdded:Connect(function(pl)
    if pl.UserId == MOD_ID then
        leaveBecauseModJoined("joined")
    end
end)

-- Detect when YOU leave/disconnect (client-side)
if LOCAL_PLAYER then
    if LOCAL_PLAYER.OnTeleport then
        LOCAL_PLAYER.OnTeleport:Connect(function(state)
            sendWebhook("Player disconnected (teleport) - state: " .. tostring(state))
        end)
    end

    LOCAL_PLAYER.AncestryChanged:Connect(function(_, parent)
        if not parent then
            sendWebhook("Player disconnected (left game)")
        end
    end)
end

-- OPTIONAL: remove or comment out this heartbeat if it spams your webhook
spawn(function()
    while wait(60) do
        sendWebhook("Script still active in server: " .. tostring(game.JobId))
    end
end)
