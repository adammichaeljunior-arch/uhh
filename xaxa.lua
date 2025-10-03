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
local overlayDelay = 3
local STAFF_GROUP_ID = 12940498 -- Group with staff

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

-- === WEBHOOK EMBED SENDER ===
local function sendEmbed(title, description, color)
    local payload = {
        embeds = {{
            title = title,
            description = description,
            color = color or 0x2F3136,
            footer = { text = "Envyy System" },
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
local lastMessageTime = 0
local function sendChat(msg)
    if not channel then return end
    local ok = pcall(function()
        channel:SendAsync(msg)
    end)
    if ok then lastMessageTime = os.time() end
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

-- panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0.5, 0, 0.5, 0)
panel.Position = UDim2.new(0.25, 0, 0.25, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
panel.BorderSizePixel = 0
panel.Parent = background

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = panel

-- title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.15, 0)
title.BackgroundTransparency = 1
title.Text = "🌐 Envyy System Overlay"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(200,200,200)
title.Parent = panel

-- info
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

-- progress bar
local barBG = Instance.new("Frame")
barBG.Size = UDim2.new(1, -20, 0.1, 0)
barBG.Position = UDim2.new(0, 10, 0.85, 0)
barBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
barBG.BorderSizePixel = 0
barBG.Parent = panel
local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 8)
barCorner.Parent = barBG

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
barFill.BorderSizePixel = 0
barFill.Parent = barBG
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 8)
fillCorner.Parent = barFill

-- show overlay
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

-- === QUEUE SCRIPT ===
local function queueScript()
    local SRC = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/xaxa.lua"))()
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
    sendEmbed("🔄 Server Hop", ("User: %s (%s)\nReason: %s\nPlayers: %d\nJobId: %s")
        :format(player.Name, player.DisplayName, reason or "rotation", #Players:GetPlayers(), game.JobId), 0x5865F2)

    queueScript()

    local success, body = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100")
    end)
    if success then
        local data = HttpService:JSONDecode(body)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId and server.playing > 0 then
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
    for _, id in ipairs(MOD_IDS) do
        if pl.UserId == id or pl:IsInGroup(STAFF_GROUP_ID) then
            sendEmbed("🚨 Mod Detected", pl.Name .. " ("..pl.UserId..") is staff!", 0xED4245)
            serverHop("Mod detected: " .. pl.Name)
            break
        end
    end
end

for _, pl in ipairs(Players:GetPlayers()) do checkForMods(pl) end
Players.PlayerAdded:Connect(checkForMods)

-- === AUTO CHAT LOOP (safe only) ===
task.spawn(function()
    task.wait(3)
    local safe = true
    while _G.AutoSay do
        -- check mods before each message
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player then
                if pl:IsInGroup(STAFF_GROUP_ID) then
                    safe = false
                    serverHop("Staff detected before chatting")
                end
            end
        end

        if safe and channel then
            sendChat(messages[math.random(1, #messages)])
        end
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
            local progress = (#reached / #allPlayers)
            barFill:TweenSize(UDim2.new(progress, 0, 1, 0), "Out", "Quad", 0.5, true)

            info.Text = string.format(
                "👤 User: %s (%s)\n🎯 Target: %s\n👥 Players left: %d\n🗂 JobId: %s\n",
                player.Name, player.DisplayName,
                target.DisplayName or target.Name,
                #allPlayers - #reached,
                string.sub(game.JobId,1,8) .. "..."
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

        barFill:TweenSize(UDim2.new(1, 0, 1, 0), "Out", "Quad", 0.5, true)
        info.Text = "🔄 Finished all players. Hopping..."
        serverHop("Rotation after reaching players")
        task.wait(1)
    end
end)
