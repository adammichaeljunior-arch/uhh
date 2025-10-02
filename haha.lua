-- === SETTINGS ===
local messages = {
    "join /envyy for fansignss",
    "join /envyy 4 nitro",
    "/envyy 4 headless",
    "goon in /envyy",
    "join /envyy 4 eheadd",
    "join /envyy for friends"
}
local chatDelay = 2.5
local tpDelay = 6       -- seconds near each player
local emoteDelay = 3    -- /e point spam
local MOD_ID = 943340328
local CPU_SAVE = true

-- === SERVICES ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer
local channel = TextChatService.TextChannels:WaitForChild("RBXGeneral")

-- === UTILITY FUNCTIONS ===
local function sendChat(msg)
    pcall(function()
        channel:SendAsync(msg)
    end)
end

local function queueScript()
    local SCRIPT_SOURCE = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/haha.lua"))()
    ]]
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(SCRIPT_SOURCE)
    elseif queue_on_teleport then
        queue_on_teleport(SCRIPT_SOURCE)
    end
end

local function serverHop(reason)
    overlayLabel.Text = "Server hopping..."
    queueScript()
    
    local ok, body = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        return game:HttpGet(url)
    end)
    
    if ok then
        local data = game:GetService("HttpService"):JSONDecode(body)
        if data and data.data then
            for _, s in ipairs(data.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, player)
                    return
                end
            end
        end
    end
    
    TeleportService:Teleport(game.PlaceId, player)
end

-- === OVERLAY ===
local playerGui = player:WaitForChild("PlayerGui",10)
if playerGui then
    local gui = Instance.new("ScreenGui")
    gui.Name = "Overlay"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.25,0,0.1,0)
    frame.Position = UDim2.new(0.01,0,0.01,0)
    frame.BackgroundColor3 = Color3.new(0,0,0)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = gui

    overlayLabel = Instance.new("TextLabel")
    overlayLabel.Size = UDim2.new(1,0,1,0)
    overlayLabel.BackgroundTransparency = 1
    overlayLabel.TextColor3 = Color3.new(1,1,1)
    overlayLabel.TextScaled = true
    overlayLabel.Text = "Initializing..."
    overlayLabel.Parent = frame
else
    warn("PlayerGui not found, overlay disabled")
end

-- === CPU SAVER ===
if CPU_SAVE then
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

-- === CHECK FOR MODERATOR ===
for _, pl in ipairs(Players:GetPlayers()) do
    if pl.UserId == MOD_ID then
        serverHop("mod in server")
    end
end
Players.PlayerAdded:Connect(function(pl)
    if pl.UserId == MOD_ID then
        serverHop("mod joined")
    end
end)

-- === AUTO CHAT ===
task.spawn(function()
    local i = 1
    while true do
        sendChat(messages[i])
        i = i + 1
        if i > #messages then i = 1 end
        task.wait(chatDelay)
    end
end)

-- === PLAYER TP + EMOTE ===
task.spawn(function()
    local unvisited = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= player then
            table.insert(unvisited, pl)
        end
    end
    
    while #unvisited > 0 do
        local target = table.remove(unvisited,1)
        if overlayLabel then
            overlayLabel.Text = string.format("Account: %s\nPlayers left: %d", player.Name, #unvisited)
        end

        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and
           player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local targetPos = target.Character.HumanoidRootPart.Position
            hrp.CFrame = CFrame.new(targetPos + target.Character.HumanoidRootPart.CFrame.LookVector*3, targetPos)
        end

        -- Emote spam while near
        local elapsed = 0
        while elapsed < tpDelay do
            sendChat("/e point")
            task.wait(emoteDelay)
            elapsed = elapsed + emoteDelay
        end
    end

    if overlayLabel then
        overlayLabel.Text = "Server hopping..."
    end

    task.wait(1)
    queueScript()
    TeleportService:Teleport(game.PlaceId, player)
end)
