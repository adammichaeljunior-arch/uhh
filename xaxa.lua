-- === SETTINGS ===
local messages = {
    "join /Εnvyy for fansignss",
    "join /Εnvyy 4 nitro",
    "/Εnvyy 4 headless",
    "goon in /Εnvyy",
    "join /Εnvyy 4 eheadd",
    "join /Εnvyy for friends"
}
local chatDelay = 2.5
local tpDelay = 6
local minPlayers = 2 -- minimum players to avoid leaving empty servers
local uiDelay = 3 -- delay before UI shows
local msgStartDelay = 3 -- delay before first message
local WEBHOOK_URL = "https://discord.com/api/webhooks/1423446494152884295/rip25iG9fUAoY63CE5uYRqpKNeNz5HJoS0jTH0X4CRpXkS2hJqBk6xn8KLq1yNu_BHxI"

-- === TOGGLES ===
_G.AutoSay = true
_G.AutoTP = true
_G.AutoEmote = true
_G.CPUSaver = true

-- === SERVICES ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local channel = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

-- === WEBHOOK FUNCTION ===
local function sendWebhook(msg)
    local data = {
        content = msg
    }
    local jsonData = HttpService:JSONEncode(data)
    pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, jsonData, Enum.HttpContentType.ApplicationJson)
    end)
end

-- === OVERLAY ===
local overlay = Instance.new("ScreenGui")
overlay.Name = "PlayerOverlay"
overlay.IgnoreGuiInset = true
overlay.ResetOnSpawn = false
overlay.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1,0,1,0)
frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
frame.BorderSizePixel = 0
frame.Parent = overlay
frame.Visible = false

local text = Instance.new("TextLabel")
text.Size = UDim2.new(1, -40, 0.2, 0)
text.Position = UDim2.new(0,20,0.05,0)
text.BackgroundTransparency = 1
text.TextColor3 = Color3.fromRGB(200,200,200)
text.Font = Enum.Font.GothamBold
text.TextScaled = true
text.Text = "⌛ Initializing..."
text.Parent = frame

task.delay(uiDelay, function()
    frame.Visible = true
end)

-- === CPU SAVER ===
if _G.CPUSaver then
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        RunService:Set3dRenderingEnabled(false)
        Lighting.GlobalShadows = false
        Lighting.Brightness = 0
        Lighting.FogEnd = 9e9
        Lighting.Ambient = Color3.new(0,0,0)
        Lighting.OutdoorAmbient = Color3.new(0,0,0)
    end)
    task.spawn(function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
        workspace.DescendantAdded:Connect(function(v)
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end)
    end)
end

-- === QUEUE ON TELEPORT ===
local function queueScript()
    local SCRIPT_SOURCE = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/haha.lua"))()
    ]]
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(SCRIPT_SOURCE)
    elseif queue_on_teleport then
        queue_on_teleport(SCRIPT_SOURCE)
    elseif game:GetService("Players").LocalPlayer.OnTeleport then
        game.Players.LocalPlayer.OnTeleport:Connect(function()
            loadstring(SCRIPT_SOURCE)()
        end)
    end
end

-- === SERVER HOP ===
local function serverHop(reason)
    reason = reason or "Normal cycle"
    text.Text = "🌐 Server hopping..."
    queueScript()

    sendWebhook("🌐 **Server hop initiated!**\nReason: "..reason..
        "\n👤 Account: "..player.Name..
        "\n🕒 Time: "..os.date("%H:%M:%S"))

    local success, body = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
    end)
    
    if success then
        local data = HttpService:JSONDecode(body)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing < server.maxPlayers and server.playing > 0 and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                    return
                end
            end
        end
    end
    TeleportService:Teleport(game.PlaceId, player)
end

-- === MOD DETECTION ===
local MOD_IDS = {
    419612796, 82591348, 540190518, 9125708679, 4992470579, 38701072,
    7423673502, 3724230698, 418307435, 73344996, 37343237, 2862215389,
    103578797, 1562079996, 2542703855, 210949, 337367059, 1159074474
}
local function checkForMods(pl)
    for _, modId in ipairs(MOD_IDS) do
        if pl.UserId == modId then
            serverHop("Moderator detected: "..pl.Name)
            break
        end
    end
end
for _, pl in ipairs(Players:GetPlayers()) do
    checkForMods(pl)
end
Players.PlayerAdded:Connect(function(pl)
    checkForMods(pl)
end)

-- === AUTO CHAT LOOP ===
task.delay(msgStartDelay, function()
    task.spawn(function()
        local i = 1
        while _G.AutoSay do
            if channel then
                channel:SendAsync(messages[i])
            end
            i = i + 1
            if i > #messages then i = 1 end
            task.wait(chatDelay)
        end
    end)
end)

-- === AUTO TELEPORT + EMOTE ===
task.spawn(function()
    while _G.AutoTP do
        local allPlayers = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("Huma
