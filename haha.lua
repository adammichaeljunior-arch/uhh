local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Replace with your webhook URL
local WEBHOOK_URL = "https://webhook.lewisakura.moe/api/1422355679095816276/4S-k5iScROyKpCMP_Nwf6DoWquxtRCozdurmtIXlfSQzXzxTfaEzGjdzYrkQp5gFq1JE"
local MOD_ID = 943340328
local GAME_ID = game.PlaceId
local LOCAL_PLAYER = Players.LocalPlayer

-- script source (auto-load on teleport)
local SCRIPT_SOURCE = [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/haha.lua"))()
]]

-- webhook sender
local function sendWebhook(message)
    local payload = { content = "@everyone\n" .. tostring(message) }
    local ok, res = pcall(function()
        return HttpService:PostAsync(
            WEBHOOK_URL,
            HttpService:JSONEncode(payload),
            Enum.HttpContentType.ApplicationJson
        )
    end)
    if ok then
        print("Webhook sent:", res)
    else
        warn("Webhook failed:", res)
    end
end

-- queue for teleport
local function queueScript()
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(SCRIPT_SOURCE)
    elseif queue_on_teleport then
        queue_on_teleport(SCRIPT_SOURCE)
    elseif getgenv and getgenv().queue_on_teleport then
        getgenv().queue_on_teleport(SCRIPT_SOURCE)
    else
        warn("queue_on_teleport not found")
    end
end

-- server hop
local function serverHop(reason)
    sendWebhook("Server hopping (" .. tostring(reason) .. ")...")
    queueScript()

    local ok, body = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. GAME_ID .. "/servers/Public?sortOrder=Asc&limit=100"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if ok and body and body.data then
        for _, s in ipairs(body.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(GAME_ID, s.id, LOCAL_PLAYER)
                return
            end
        end
    end

    TeleportService:Teleport(GAME_ID, LOCAL_PLAYER)
end

-- moderator detected
local function onMod(reason)
    sendWebhook("Moderator detected (" .. tostring(reason) .. ")")
    serverHop("Moderator detected")
end

-- scan players
for _, pl in ipairs(Players:GetPlayers()) do
    if pl.UserId == MOD_ID then
        onMod("already in server")
    end
end

-- future joins
Players.PlayerAdded:Connect(function(pl)
    if pl.UserId == MOD_ID then
        onMod("joined")
    end
end)

-- teleport events
LOCAL_PLAYER.OnTeleport:Connect(function(state)
    sendWebhook("Teleporting... state=" .. tostring(state))
end)

-- ancestry changed
LOCAL_PLAYER.AncestryChanged:Connect(function(_, parent)
    if not parent then
        sendWebhook("Player disconnected (left game)")
    end
end)

-- optional heartbeat
task.spawn(function()
    while task.wait(60) do
        sendWebhook("Still alive in server " .. tostring(game.JobId))
    end
end)
