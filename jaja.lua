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
local minPlayers = 2 -- minimum players to avoid leaving empty servers

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
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local channel = nil
pcall(function()
    channel = TextChatService.TextChannels:WaitForChild("RBXGeneral", 5)
end)

-- === PERFORMANCE OPTIMIZATIONS ===
-- Disable shadows, reduce brightness and ambient
Lighting.GlobalShadows = false
Lighting.FogEnd = 0
Lighting.Brightness = 0
Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)

-- Disable particles, beams, and trails
local function disableParticles(obj)
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
            v.Enabled = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("SurfaceGui") or v:IsA("BillboardGui") then
            v.Enabled = false
        elseif v:IsA("SpecialMesh") then
            v.MeshType = Enum.MeshType.FileMesh
        elseif v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.CastShadow = false
        end
    end
end

disableParticles(Workspace)

-- Disable newly added objects
Workspace.DescendantAdded:Connect(disableParticles)

-- === STATS ===
local stats = {
    ServersHopped = 0,
    MessagesSent = 0,
    PlayersLeft = 0
}

-- === FULLSCREEN OVERLAY ===
local overlay, overlayLabel
task.delay(1, function()
    overlay = Instance.new("ScreenGui")
    overlay.Name = "PlayerOverlay"
    overlay.IgnoreGuiInset = true
    overlay.ResetOnSpawn = false
    overlay.Parent = player:WaitForChild("PlayerGui")

    local overlayFrame = Instance.new("Frame")
    overlayFrame.Size = UDim2.new(1,0,1,0)
    overlayFrame.Position = UDim2.new(0,0,0,0)
    overlayFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    overlayFrame.BackgroundTransparency = 0.25
    overlayFrame.BorderSizePixel = 0
    overlayFrame.ZIndex = 999
    overlayFrame.Parent = overlay

    overlayLabel = Instance.new("TextLabel")
    overlayLabel.Size = UDim2.new(1,0,1,0)
    overlayLabel.Position = UDim2.new(0,0,0,0)
    overlayLabel.BackgroundTransparency = 1
    overlayLabel.TextColor3 = Color3.fromRGB(0,255,0)
    overlayLabel.Font = Enum.Font.GothamBold
    overlayLabel.TextScaled = true
    overlayLabel.Text = "🌐 Initializing..."
    overlayLabel.ZIndex = 1000
    overlayLabel.Parent = overlayFrame
end)

-- === OVERLAY UPDATER ===
local function updateOverlay()
    if overlayLabel then
        overlayLabel.Text =
            "🧑 Account: " .. player.Name ..
            "\n👥 Players left: " .. stats.PlayersLeft ..
            "\n🔄 Servers hopped: " .. stats.ServersHopped ..
            "\n💬 Messages sent: " .. stats.MessagesSent
    end
end

-- === CHAT HELPER ===
local function sendChat(msg)
    if not channel then return end
    local ok = pcall(function()
        channel:SendAsync(msg)
    end)
    if ok then
        stats.MessagesSent += 1
        updateOverlay()
    end
end

-- === QUEUE ON TELEPORT ===
local function queueScript()
    local SCRIPT_SOURCE = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/jaja.lua"))()
    ]]
    pcall(function()
        if syn and syn.queue_on_teleport then
            syn.queue_on_teleport(SCRIPT_SOURCE)
        elseif queue_on_teleport then
            queue_on_teleport(SCRIPT_SOURCE)
        end
    end)
end

-- === SERVER HOP ===
local function serverHop()
    if overlayLabel then overlayLabel.Text = "🔄 Server hopping..." end
    queueScript()
    stats.ServersHopped += 1
    updateOverlay()

    local success, body = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
    end)
    
    if success then
        local data = HttpService:JSONDecode(body)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing >= minPlayers and server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                    return
                end
            end
        end
    end

    TeleportService:Teleport(game.PlaceId, player)
end

-- === MOD DETECTION (INTERVAL 5s) ===
local MOD_IDS = {
    419612796, 82591348, 540190518, 9125708679, 4992470579, 38701072,
    7423673502, 3724230698, 418307435, 73344996, 37343237, 2862215389,
    103578797, 1562079996, 2542703855, 210949, 337367059, 1159074474
}

local checkedPlayers = {}

local function checkForMods(pl)
    if checkedPlayers[pl.UserId] then return end
    for _, modId in ipairs(MOD_IDS) do
        if pl.UserId == modId then
            serverHop()
            return
        end
    end
    checkedPlayers[pl.UserId] = true
end

task.spawn(function()
    while true do
        for _, pl in ipairs(Players:GetPlayers()) do
            checkForMods(pl)
        end
        task.wait(5)
    end
end)

-- === AUTO ACCEPT BUTTON ===
task.spawn(function()
    while task.wait(1) do
        local gui = player:FindFirstChildOfClass("PlayerGui")
        if gui then
            local btn = gui:FindFirstChild("I agree", true)
            if btn and btn:IsA("TextButton") then
                pcall(function() btn:Activate() end)
            end
        end
    end
end)

-- === AUTO CHAT LOOP ===
task.spawn(function()
    local i = 1
    task.wait(4)
    while _G.AutoSay do
        sendChat(messages[i])
        i = i + 1
        if i > #messages then i = 1 end
        task.wait(chatDelay + math.random())
    end
end)

-- === AUTO TELEPORT + EMOTE ===
task.spawn(function()
    while _G.AutoTP do
        local allPlayers = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(allPlayers, pl)
            end
        end

        if #allPlayers < minPlayers then
            serverHop()
        end

        local reachedPlayers = {}
        stats.PlayersLeft = #allPlayers
        updateOverlay()

        for _, target in ipairs(allPlayers) do
            stats.PlayersLeft = #allPlayers - #reachedPlayers
            updateOverlay()
            task.wait(3)

            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(
                        target.Character.HumanoidRootPart.Position + target.Character.HumanoidRootPart.CFrame.LookVector*3,
                        target.Character.HumanoidRootPart.Position
                    )
                end
            end

            if _G.AutoEmote then
                task.spawn(function()
                    local emotes = math.floor(tpDelay / 0.5)
                    for _ = 1, emotes do
                        sendChat("/e point")
                        task.wait(0.5)
                    end
                end)
            end

            table.insert(reachedPlayers, target)
            task.wait(tpDelay)
        end

        if overlayLabel then overlayLabel.Text = "✅ Loop complete, restarting..." end
        task.wait(1)
    end
end)
