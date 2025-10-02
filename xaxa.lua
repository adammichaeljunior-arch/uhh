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
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local channel = nil
pcall(function()
    channel = TextChatService.TextChannels:WaitForChild("RBXGeneral", 5)
end)

-- === CHAT HELPER ===
local lastMessageTime = 0
local function sendChat(msg)
    if not channel then return end
    local ok, _ = pcall(function()
        channel:SendAsync(msg)
    end)
    if ok then
        lastMessageTime = os.time()
    end
end

-- === PLAYER COUNTDOWN & OVERLAY ===
local overlay = Instance.new("ScreenGui")
overlay.Name = "PlayerOverlay"
overlay.IgnoreGuiInset = true
overlay.ResetOnSpawn = false
overlay.Parent = player:WaitForChild("PlayerGui")

local overlayFrame = Instance.new("Frame")
overlayFrame.Size = UDim2.new(0.35,0,0.15,0)
overlayFrame.Position = UDim2.new(0.325,0,0.05,0)
overlayFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
overlayFrame.BorderSizePixel = 0
overlayFrame.Parent = overlay

local uicorner = Instance.new("UICorner", overlayFrame)
uicorner.CornerRadius = UDim.new(0,12)

local overlayLabel = Instance.new("TextLabel")
overlayLabel.Size = UDim2.new(1,0,1,0)
overlayLabel.BackgroundTransparency = 1
overlayLabel.TextColor3 = Color3.fromRGB(0,255,0)
overlayLabel.Font = Enum.Font.Code
overlayLabel.TextScaled = true
overlayLabel.Text = "Initializing..."
overlayLabel.Parent = overlayFrame

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
    elseif game:GetService("TeleportService").OnTeleport then
        game:GetService("TeleportService").OnTeleport:Connect(function()
            queue_on_teleport(SCRIPT_SOURCE)
        end)
    end
end

-- === SERVER HOP ===
local function serverHop()
    overlayLabel.Text = "Server hopping..."
    queueScript()

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

-- === MOD DETECTION ===
local MOD_IDS = {
    419612796, 82591348, 540190518, 9125708679, 4992470579, 38701072,
    7423673502, 3724230698, 418307435, 73344996, 37343237, 2862215389,
    103578797, 1562079996, 2542703855, 210949, 337367059, 1159074474
}

local function checkForMods(pl)
    for _, modId in ipairs(MOD_IDS) do
        if pl.UserId == modId then
            serverHop()
            break
        end
    end
end

-- Check existing players
for _, pl in ipairs(Players:GetPlayers()) do
    checkForMods(pl)
end

-- Listen for new players
Players.PlayerAdded:Connect(function(pl)
    checkForMods(pl)
end)

-- === AUTO ACCEPT BUTTON ===
task.spawn(function()
    while task.wait(1) do
        local gui = player:FindFirstChildOfClass("PlayerGui")
        if gui then
            local btn = gui:FindFirstChild("I agree", true)
            if btn and btn:IsA("TextButton") then
                pcall(function() btn.Activated:Connect(function() end) end)
                pcall(function() btn:Activate() end)
            end
        end
    end
end)

-- === AUTO CHAT LOOP ===
task.spawn(function()
    local i = 1
    task.wait(4) -- 4s delay before first message
    while _G.AutoSay do
        sendChat(messages[i])
        i = i + 1
        if i > #messages then i = 1 end
        local randomDelay = chatDelay + math.random()
        task.wait(randomDelay)
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

        for _, target in ipairs(allPlayers) do
            overlayLabel.Text = ("Players left: %d"):format(#allPlayers - #reachedPlayers)

            -- add a 3s delay before teleporting
            task.wait(3)

            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(target.Character.HumanoidRootPart.Position + target.Character.HumanoidRootPart.CFrame.LookVector*3, target.Character.HumanoidRootPart.Position)
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

        overlayLabel.Text = "Server hopping..."
        serverHop()
        task.wait(1)
    end
end)
