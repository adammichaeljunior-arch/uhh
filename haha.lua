local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Replace with your webhook URL, but swap "discord.com" for "webhook.lewisakura.moe"
local WEBHOOK_URL = "https://webhook.lewisakura.moe/api/1422355679095816276/4S-k5iScROyKpCMP_Nwf6DoWquxtRCozdurmtIXlfSQzXzxTfaEzGjdzYrkQp5gFq1JE"
local MOD_ID = 943340328
local GAME_ID = game.PlaceId  -- current place
local LOCAL_PLAYER = Players.LocalPlayer

-- Your script source (reloaded on teleport)
local SCRIPT_SOURCE = [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/haha.lua"))()
]]

-- Send a Discord webhook message
local function sendWebhook(message)
    local payload = {
        content = "@everyone\n" .. message
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

-- Queue script for teleport
local function queueScript()
    local ok, err = pcall(function()
        if syn and syn.queue_on_teleport then
            syn.queue_on_teleport(SCRIPT_SOURCE)
        elseif queue_on_teleport then
            queue_on_teleport(SCRIPT_SOURCE)
        elseif getgenv and getgenv().queue_on_teleport then
            getgenv().queue_on_teleport(SCRIPT_SOURCE)
        else
            warn("queue_on_teleport not found")
        end
    end)
    if not ok then warn("Failed queue_on_teleport:", err) end
end

-- Server hop function
local function serverHop(reason)
    sendWebhook("Server hopping (" .. tostring(reason) .. ")...")
    queueScript()

    local success, body = pcall(function()
        return HttpService:JSONDecode(game:HttpGetAsync(
            "https://games.roblox.com/v1/games/" .. GAME_ID .. "/servers/Public?sortOrder=Asc&limit=100"
        ))
    end)

    if success and body and body.data then
        for _, s in ipairs(body.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(GAME_ID, s.id, LOCAL_PLAYER)
                return
            end
        end
    end

    -- fallback: just rejoin game
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

-- Detect when YOU leave/disconnect
LOCAL_PLAYER.OnTeleport:Connect(function(state)
    sendWebhook("Player disconnected (teleport)")
end)

game:BindToClose(function()
    sendWebhook("Player disconnected (shutdown)")
end)

LOCAL_PLAYER.AncestryChanged:Connect(function(_, parent)
    if not parent then
        sendWebhook("Player disconnected (left game)")
    end
end)
