-- === SETTINGS ===
local WEBHOOK_URL = "https://discord.com/api/webhooks/xxxxxxxx/xxxxxxxx" -- change
local STAFF_GROUP_ID = 12940498 -- your staff group

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

-- === EMBED WEBHOOK SENDER ===
local function sendEmbed(title, description, color)
    local payload = {
        embeds = {{
            title = title,
            description = description,
            color = color or 0x2F3136,
            footer = { text = "Auto System Overlay" },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }
    local requestBody = {
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload),
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
panel.Size = UDim2.new(0.5, 0, 0.5, 0)
panel.Position = UDim2.new(0.25, 0, 0.25, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
panel.BorderSizePixel = 0
panel.Parent = background

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.15, 0)
title.BackgroundTransparency = 1
title.Text = "🌐 Auto System Overlay"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(200,200,200)
title.Parent = panel

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0.6, -20)
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

-- Animated status bar
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(0, 0, 0.05, 0)
statusBar.Position = UDim2.new(0, 10, 0.9, 0)
statusBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
statusBar.BorderSizePixel = 0
statusBar.Parent = panel

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 8)
statusCorner.Parent = statusBar

-- show overlay
task.delay(overlayDelay, function() background.Visible = true end)

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

-- === SAFE MOD CHECK ===
local MOD_IDS = {
    419612796, 82591348, 540190518, 9125708679, 4992470579, 38701072,
    7423673502, 3724230698, 418307435, 73344996, 37343237, 2862215389,
    103578797, 1562079996, 2542703855, 210949, 337367059, 1159074474
}

local function safeIsInGroup(plr, groupId)
    local ok, result = pcall(function() return plr:IsInGroup(groupId) end)
    return ok and result
end

local function checkForMods(pl)
    if not pl or not pl.UserId then return end
    task.wait(1)
    for _, id in ipairs(MOD_IDS) do
        if pl.UserId == id or safeIsInGroup(pl, STAFF_GROUP_ID) then
            sendEmbed("🚨 Mod Detected", pl.Name .. " ("..pl.UserId..") flagged as staff!", 0xED4245)
            serverHop("Staff detected: " .. pl.Name)
            return true
        end
    end
    return false
end

-- === SERVER HOP (LARGEST SERVERS FIRST) ===
function serverHop(reason)
    info.Text = "⏭ Hopping... " .. (reason or "")
    sendEmbed("🌐 Server Hop", "Reason: " .. (reason or "rotation"), 0x5865F2)

    queueScript()
    local success, body = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100")
    end)
    if success then
        local data = HttpService:JSONDecode(body)
        if data and data.data then
            table.sort(data.data, function(a,b) return a.playing > b.playing end)
            for _, server in ipairs(data.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId and server.playing > 5 then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                    return
                end
            end
        end
    end
    TeleportService:Teleport(game.PlaceId, player)
end

-- check mods before starting
for _, pl in ipairs(Players:GetPlayers()) do
    if checkForMods(pl) then return end
end
Players.PlayerAdded:Connect(checkForMods)

-- === AUTO CHAT LOOP (AFTER MOD CHECK) ===
task.spawn(function()
    task.wait(3)
    local i = 1
    while _G.AutoSay do
        sendChat(messages[i])
        i = (i % #messages) + 1
        task.wait(chatDelay + math.random())
    end
end)

-- === AUTO TELEPORT LOOP WITH STATUS BAR ===
task.spawn(function()
    while _G.AutoTP do
        local allPlayers = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(allPlayers, pl)
            end
        end

        if #allPlayers < 1 then
            serverHop("Empty server")
            return
        end

        for idx, target in ipairs(allPlayers) do
            local progress = idx / #allPlayers
            statusBar:TweenSize(UDim2.new(progress,0,0.05,0), "Out", "Quad", 0.5, true)
            info.Text = string.format("👤 User: %s\n🎯 Target: %s\nProgress: %d/%d",
                player.Name, target.DisplayName or target.Name, idx, #allPlayers)

            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
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
            task.wait(tpDelay + 2)
        end

        statusBar.Size = UDim2.new(0,0,0.05,0)
        serverHop("Cycle complete")
        task.wait(1)
    end
end)
