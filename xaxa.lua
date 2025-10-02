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
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- === CHAT HELPER (supports old/new chat) ===
local lastMessageTime = 0
local function sendChat(msg)
    local ok = false
    pcall(function()
        local tcs = game:GetService("TextChatService")
        if tcs:FindFirstChild("TextChannels") and tcs.TextChannels:FindFirstChild("RBXGeneral") then
            tcs.TextChannels.RBXGeneral:SendAsync(msg)
            ok = true
        else
            player:Chat(msg)
            ok = true
        end
    end)
    if ok then
        lastMessageTime = os.time()
    end
end

-- === FANCY UI OVERLAY ===
local overlay = Instance.new("ScreenGui")
overlay.Name = "FancyOverlay"
overlay.IgnoreGuiInset = true
overlay.ResetOnSpawn = false
overlay.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.3, 0, 0.22, 0)
mainFrame.Position = UDim2.new(0.35, 0, 0.05, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BackgroundTransparency = 0.15
mainFrame.Parent = overlay

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Parent = mainFrame

local function createLabel(name, order)
    local lbl = Instance.new("TextLabel")
    lbl.Name = name
    lbl.Size = UDim2.new(1, -10, 0, 22)
    lbl.Position = UDim2.new(0, 5, 0, (order-1)*24 + 5)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextSize = 16
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = name..": ..."
    lbl.Parent = mainFrame
    return lbl
end

local lblAccount = createLabel("Account", 1)
local lblPlayers = createLabel("PlayersLeft", 2)
local lblStatus = createLabel("Status", 3)
local lblMods = createLabel("Mods", 4)
local lblServer = createLabel("ServerID", 5)

local function setStatus(txt)
    lblStatus.Text = "Status: " .. txt
end

local function setModsDetected(flag)
    if flag then
        lblMods.Text = "Mods: YES ⚠️"
        lblMods.TextColor3 = Color3.fromRGB(255,0,0)
    else
        lblMods.Text = "Mods: NO"
        lblMods.TextColor3 = Color3.fromRGB(0,255,0)
    end
end

task.spawn(function()
    while true do
        pcall(function()
            lblAccount.Text = "Account: " .. player.Name
            lblPlayers.Text = "Players Left: " .. math.max(0, #Players:GetPlayers()-1)
            lblServer.Text = "ServerID: " .. string.sub(game.JobId,1,8)
        end)
        task.wait(1)
    end
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
    pcall(function()
        task.wait(0.2)
        if syn and syn.queue_on_teleport then
            syn.queue_on_teleport(SCRIPT_SOURCE)
        elseif queue_on_teleport then
            queue_on_teleport(SCRIPT_SOURCE)
        end
    end)
end

-- === SERVER HOP ===
local function serverHop()
    setStatus("Server hopping...")
    queueScript()

    local success, body = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
    end)
    
    if success then
        local data = HttpService:JSONDecode(body)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing > 1 and server.playing < server.maxPlayers and server.id ~= game.JobId then
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
            setModsDetected(true)
            serverHop()
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
task.spawn(function()
    local i = 1
    while _G.AutoSay do
        sendChat(messages[i])
        i = i + 1
        if i > #messages then i = 1 end
        task.wait(chatDelay)
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
            setStatus("Too few players, hopping...")
            serverHop()
            return
        end

        local reachedPlayers = {}

        for _, target in ipairs(allPlayers) do
            setStatus("Teleporting to " .. target.Name)
            lblPlayers.Text = ("Players Left: %d"):format(#allPlayers - #reachedPlayers)
            
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
                    for _ = 1, math.floor(tpDelay / 0.5) do
                        sendChat("/e point")
                        task.wait(0.5)
                    end
                end)
            end

            table.insert(reachedPlayers, target)
            task.wait(tpDelay)
        end

        setStatus("Finished, hopping...")
        serverHop()
        task.wait(1)
    end
end)
