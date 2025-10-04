-- === SETTINGS ===
local messages = {
    "join /LOLZ for fansignss",
    "join /LOLZ 4 nitro",
    "/LOLZ 4 headless",
    "goon in /LOLZ",
    "join /LOLZ 4 eheadd",
    "join /LOLZ for friends"
}
local chatDelay = 2.5
local tpDelay = 6
local minPlayers = 5 -- skip tiny servers

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

-- === STATS ===
local stats = {
    ServersHopped = 0,
    MessagesSent = 0,
    PlayersLeft = 0,
    TotalPlayers = 0,
    PlayersReached = 0
}

-- === UI CREATION ===
local overlay, infoText, barFill
task.delay(1, function()
    overlay = Instance.new("ScreenGui")
    overlay.Name = "OverlayMenu"
    overlay.IgnoreGuiInset = true
    overlay.ResetOnSpawn = false
    overlay.Parent = player:WaitForChild("PlayerGui")

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bg.BorderSizePixel = 0
    bg.Parent = overlay

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0.35,0,0.45,0)
    panel.Position = UDim2.new(0.325,0,0.28,0)
    panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
    panel.BorderSizePixel = 0
    panel.Parent = bg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,15)
    corner.Parent = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0.2,0)
    title.BackgroundTransparency = 1
    title.Text = "🌐 Auto System Overlay"
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.TextColor3 = Color3.fromRGB(200,200,200)
    title.Parent = panel

    infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1,-20,0.6,-10)
    infoText.Position = UDim2.new(0,10,0.25,0)
    infoText.BackgroundTransparency = 1
    infoText.TextColor3 = Color3.fromRGB(180,180,180)
    infoText.Font = Enum.Font.Gotham
    infoText.TextScaled = true
    infoText.TextWrapped = true
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.TextYAlignment = Enum.TextYAlignment.Top
    infoText.Text = "Initializing..."
    infoText.Parent = panel

    -- Progress Bar
    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(0.9,0,0.08,0)
    barBG.Position = UDim2.new(0.05,0,0.88,0)
    barBG.BackgroundColor3 = Color3.fromRGB(40,40,40)
    barBG.BorderSizePixel = 0
    barBG.Parent = panel
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0,8)
    bgCorner.Parent = barBG

    barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0,0,1,0)
    barFill.BackgroundColor3 = Color3.fromRGB(0,170,255)
    barFill.BorderSizePixel = 0
    barFill.Parent = barBG
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0,8)
    fillCorner.Parent = barFill
end)

local function updateOverlay()
    if infoText then
        infoText.Text = string.format(
            "🧑 Account: %s\n👥 Players left: %d\n🔄 Servers hopped: %d\n💬 Messages sent: %d",
            player.Name, stats.PlayersLeft, stats.ServersHopped, stats.MessagesSent
        )
    end
    if barFill and stats.TotalPlayers > 0 then
        local progress = stats.PlayersReached / stats.TotalPlayers
        barFill:TweenSize(UDim2.new(progress,0,1,0), "Out", "Sine", 0.3, true)
    end
end

-- === CHAT HELPER ===
local function sendChat(msg)
    if not channel then return end
    local ok = pcall(function() channel:SendAsync(msg) end)
    if ok then
        stats.MessagesSent += 1
        updateOverlay()
    end
end

-- === QUEUE SCRIPT ===
local function queueScript()
    local SRC = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/jaja.lua"))()
    ]]
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(SRC)
    elseif queue_on_teleport then
        queue_on_teleport(SRC)
    end
end

-- === SERVER HOP ===
local function serverHop()
    if infoText then infoText.Text = "🔄 Searching servers..." end
    queueScript()
    stats.ServersHopped += 1
    updateOverlay()

    local success, body = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100")
    end)

    if success then
        local data = HttpService:JSONDecode(body)
        if data and data.data then
            table.sort(data.data, function(a,b) return a.playing > b.playing end)
            for _, server in ipairs(data.data) do
                if server.playing >= minPlayers and server.playing < server.maxPlayers and server.id ~= game.JobId then
                    local ok = pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                    end)
                    if ok then return end
                end
            end
        end
    end

    TeleportService:Teleport(game.PlaceId, player)
end

TeleportService.TeleportInitFailed:Connect(function(_, result, msg)
    task.wait(2)
    serverHop()
end)

-- === MOD DETECTION ===
local MOD_IDS = {
    419612796, 82591348, 540190518, 9125708679, 4992470579, 38701072,
    7423673502, 3724230698, 418307435, 73344996, 37343237, 2862215389,
    103578797, 1562079996, 2542703855, 210949, 337367059, 1159074474
}

local function checkForMods()
    for _, pl in ipairs(Players:GetPlayers()) do
        for _, id in ipairs(MOD_IDS) do
            if pl.UserId == id then
                serverHop()
                return
            end
        end
    end
end

task.spawn(function()
    while task.wait(5) do checkForMods() end
end)

-- === AUTO CHAT LOOP ===
task.spawn(function()
    local i = 1
    task.wait(4)
    while _G.AutoSay do
        sendChat(messages[i])
        i = i % #messages + 1
        task.wait(chatDelay + math.random())
    end
end)

-- === AUTO TELEPORT ===
task.spawn(function()
    while _G.AutoTP do
        local allPlayers = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(allPlayers, pl)
            end
        end

        stats.TotalPlayers = #allPlayers
        stats.PlayersReached = 0
        updateOverlay()

        if #allPlayers < minPlayers then
            serverHop()
        end

        stats.PlayersLeft = #allPlayers
        updateOverlay()

        for _, target in ipairs(allPlayers) do
            stats.PlayersLeft -= 1
            stats.PlayersReached += 1
            updateOverlay()

            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = target.Character.HumanoidRootPart.CFrame
                end
            end

            if _G.AutoEmote then
                task.spawn(function()
                    for _ = 1, math.floor(tpDelay/0.5) do
                        sendChat("/e point")
                        task.wait(0.5)
                    end
                end)
            end

            task.wait(tpDelay)
        end

        serverHop()
        task.wait(1)
    end
end)

-- === CPU SAVER ===
if _G.CPUSaver then
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100000
    Lighting.Brightness = 1
    RunService:Set3dRenderingEnabled(false)
    task.spawn(function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
        end
    end)
end
