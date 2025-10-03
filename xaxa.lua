-- === SETTINGS ===
local WEBHOOK_URL = "https://discord.com/api/webhooks/1423446494152884295/rip25iG9fUAoY63CE5uYRqpKNeNz5HJoS0jTH0X4CRpXkS2hJqBk6xn8KLq1yNu_BHxI"

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
local overlayDelay = 3 -- seconds before showing overlay
local MIN_PLAYERS = 10 -- minimum players per server
local STATUS_BAR_LENGTH = 20

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
local channel = nil
pcall(function() channel = TextChatService.TextChannels:WaitForChild("RBXGeneral", 5) end)

-- === EMBED SENDER ===
local function sendWebhookEmbed(title, description, color)
    local payload = HttpService:JSONEncode({
        embeds = {{
            title = title,
            description = description,
            color = color or 3447003,
            footer = { text = "Auto System Logger" },
            timestamp = DateTime.now():ToIsoDate()
        }}
    })

    local requestBody = {
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = payload,
    }

    if syn and syn.request then return syn.request(requestBody) end
    if http_request then return http_request(requestBody) end
    if http and http.request then return http.request(requestBody) end
    if request then return request(requestBody) end
end

-- === CHAT HELPER ===
local function sendChat(msg)
    if not channel then return end
    pcall(function() channel:SendAsync(msg) end)
end

-- === UI CREATION ===
local overlay = Instance.new("ScreenGui")
overlay.Name = "FancyOverlay"
overlay.IgnoreGuiInset = true
overlay.ResetOnSpawn = false
overlay.Parent = player:WaitForChild("PlayerGui")

local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BorderSizePixel = 0
background.Visible = false
background.Parent = overlay

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0.6, 0, 0.6, 0)
panel.Position = UDim2.new(0.2, 0, 0.2, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
panel.BorderSizePixel = 0
panel.Parent = background
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.15, 0)
title.BackgroundTransparency = 1
title.Text = "🌐 Auto System Overlay"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(200,200,200)
title.Parent = panel

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0.8, -20)
info.Position = UDim2.new(0, 10, 0.18, 0)
info.BackgroundTransparency = 1
info.Font = Enum.Font.Gotham
info.TextScaled = true
info.TextWrapped = true
info.TextColor3 = Color3.fromRGB(180,180,180)
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Text = "Loading..."
info.Parent = panel

task.delay(overlayDelay, function()
    background.Visible = true
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
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
        end
        workspace.DescendantAdded:Connect(function(v)
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
        end)
    end)
end

-- === STATUS BAR ===
local function makeStatusBar(progress)
    local filled = math.floor(progress * STATUS_BAR_LENGTH)
    local empty = STATUS_BAR_LENGTH - filled
    return string.rep("█", filled) .. string.rep("░", empty)
end

-- === QUEUE SCRIPT ===
local function queueScript()
    local SRC = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/haha.lua"))()
    ]]
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(SRC)
    elseif queue_on_teleport then
        queue_on_teleport(SRC)
    end
end

-- === SERVER HOP ===
local function serverHop(reason)
    info.Text = "⏭ Server hopping...\nReason: " .. (reason or "rotation")
    sendWebhookEmbed("🌐 Server Hop", ("Reason: %s\nPlayers: %d\nJobId: %s"):format(reason or "rotation", #Players:GetPlayers(), game.JobId), 3066993)

    queueScript()

    local success, body = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100")
    end)
    if success then
        local data = HttpService:JSONDecode(body)
        if data and data.data then
            table.sort(data.data, function(a, b)
                return a.playing > b.playing
            end)

            for i, server in ipairs(data.data) do
                local progress = i / #data.data
                local bar = makeStatusBar(progress)
                info.Text = string.format(
                    "🔎 Searching servers...\n📊 %s %d%%\n👥 Players: %d/%d",
                    bar,
                    math.floor(progress * 100),
                    server.playing,
                    server.maxPlayers
                )
                task.wait(0.25)

                if server.playing < server.maxPlayers and server.id ~= game.JobId and server.playing >= MIN_PLAYERS then
                    info.Text = string.format("✅ Found server!\n👥 %d/%d players", server.playing, server.maxPlayers)
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                    return
                end
            end
        end
    end
    TeleportService:Teleport(game.PlaceId, player)
end

-- === MODERATION PROTECTION ===
local STAFF_GROUP_ID = 12940498
local MOD_IDS = {419612796, 82591348, 540190518, 9125708679}

local function isStaff(pl)
    return (pl:IsInGroup(STAFF_GROUP_ID) or table.find(MOD_IDS, pl.UserId))
end

local function checkForMods(pl)
    if isStaff(pl) then
        sendWebhookEmbed("🚨 Staff/Mod Detected", ("User: %s (%d)"):format(pl.Name, pl.UserId), 15158332)
        serverHop("Staff detected: " .. pl.Name)
        return true
    end
    return false
end

-- Initial check
for _, pl in ipairs(Players:GetPlayers()) do if checkForMods(pl) then return end end
Players.PlayerAdded:Connect(checkForMods)

-- Continuous recheck every second
task.spawn(function()
    while true do
        for _, pl in ipairs(Players:GetPlayers()) do
            if checkForMods(pl) then return end
        end
        task.wait(1)
    end
end)

-- === AUTO CHAT LOOP ===
task.spawn(function()
    task.wait(5)
    local i = 1
    while _G.AutoSay do
        sendChat(messages[i])
        i = (i % #messages) + 1
        task.wait(chatDelay + math.random())
    end
end)

-- === AUTO TELEPORT LOOP ===
task.spawn(function()
    while _G.AutoTP do
        local allPlayers = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(allPlayers, pl)
            end
        end

        if #allPlayers < 1 then
            info.Text = "⚠️ No players found. Hopping..."
            serverHop("Empty server")
            return
        end

        local reached = {}
        for _, target in ipairs(allPlayers) do
            info.Text = string.format(
                "👤 User: %s (%s)\n🎯 Target: %s\n👥 Remaining: %d\n📊 %s",
                player.Name, player.DisplayName,
                target.DisplayName or target.Name,
                #allPlayers - #reached,
                makeStatusBar(#reached / #allPlayers)
            )
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and hrp then
                hrp.CFrame = CFrame.new(
                    target.Character.HumanoidRootPart.Position + target.Character.HumanoidRootPart.CFrame.LookVector*3,
                    target.Character.HumanoidRootPart.Position
                )
            end

            if _G.AutoEmote then
                task.spawn(function()
                    for _ = 1, math.floor(tpDelay/0.5) do
                        sendChat("/e point")
                        task.wait(0.5)
                    end
                end)
            end

            table.insert(reached, target)
            task.wait(tpDelay + 3)
        end

        info.Text = "🔄 Finished all players. Hopping..."
        serverHop("Rotation after reaching players")
        task.wait(1)
    end
end)
