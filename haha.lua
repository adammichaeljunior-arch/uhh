
local messages = {
    "join /Εnvyy for fansignss",
    "join /Εnvyy 4 nitro",
    "/Εnvyy 4 headless",
    "goon in /Εnvyy",
    "join /Εnvyy 4 eheadd",
    "join /Εnvyy for friends"
}
local chatDelay = 2.5
local tpDelay = 8.5
local minPlayers = 10

-- === TOGGLES ===
_G.AutoSay = true
_G.AutoTP = true
_G.AutoEmote = true
_G.CPUSaver = true

-- === SERVICES ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local channel = TextChatService.TextChannels:WaitForChild("RBXGeneral")

-- === MOD DETECTION ===
local MOD_IDS = {
    419612796, 82591348, 540190518, 9125708679, 4992470579, 38701072,
    7423673502, 3724230698, 418307435, 73344996, 37343237, 2862215389,
    103578797, 1562079996, 2542703855, 210949, 337367059, 1159074474
}

local SCRIPT_SOURCE = [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/haha.lua"))()
]]

local function onModDetected(reason)
    if overlayLabel then
        overlayLabel.Text = "Moderator detected: " .. reason .. "\nServer hopping..."
    end
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(SCRIPT_SOURCE)
    elseif queue_on_teleport then
        queue_on_teleport(SCRIPT_SOURCE)
    end
    TeleportService:Teleport(game.PlaceId, player)
end

for _, pl in ipairs(Players:GetPlayers()) do
    for _, modId in ipairs(MOD_IDS) do
        if pl.UserId == modId then
            onModDetected("Already in server")
        end
    end
end

Players.PlayerAdded:Connect(function(pl)
    for _, modId in ipairs(MOD_IDS) do
        if pl.UserId == modId then
            onModDetected("Joined server")
        end
    end
end)

-- === CHAT HELPER ===
local lastMessageTime = 0
local function sendChat(msg)
    local ok, err = pcall(function()
        channel:SendAsync(msg)
    end)
    if ok then lastMessageTime = os.time() else warn("Chat error:", err) end
    return ok, err
end

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

-- === PLAYER QUEUE + TELEPORT + EMOTE ===
local playersLeft = {}
local overlayLabel

local function initOverlay()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CPUSaverOverlay"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = Color3.new(0,0,0)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    overlayLabel = Instance.new("TextLabel")
    overlayLabel.Size = UDim2.new(0.8,0,0,100)
    overlayLabel.AnchorPoint = Vector2.new(0.5,0.5)
    overlayLabel.Position = UDim2.new(0.5,0,0.5,0)
    overlayLabel.BackgroundTransparency = 1
    overlayLabel.TextColor3 = Color3.new(1,1,1)
    overlayLabel.TextScaled = true
    overlayLabel.Text = "Initializing..."
    overlayLabel.Parent = frame
end

initOverlay()

task.spawn(function()
    while task.wait(1) do
        if overlayLabel then
            overlayLabel.Text = string.format("User: %s\nPlayers left: %d\nLast Msg: %ds ago", player.Name, #playersLeft, os.time() - lastMessageTime)
        end
    end
end)

task.spawn(function()
    while _G.AutoTP do
        -- initialize playersLeft once
        if #playersLeft == 0 then
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= player then
                    table.insert(playersLeft, pl)
                end
            end
        end

        if #playersLeft == 0 then
            overlayLabel.Text = "Server hopping..."
            if syn and syn.queue_on_teleport then
                syn.queue_on_teleport(SCRIPT_SOURCE)
            elseif queue_on_teleport then
                queue_on_teleport(SCRIPT_SOURCE)
            end
            TeleportService:Teleport(game.PlaceId, player)
            break
        end

        local target = table.remove(playersLeft, 1)
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and
           player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local targetPos = target.Character.HumanoidRootPart.Position
            hrp.CFrame = CFrame.new(targetPos + target.Character.HumanoidRootPart.CFrame.LookVector*3, targetPos)
        end

        if _G.AutoEmote then
            for _ = 1, math.floor(tpDelay/0.5) do
                sendChat("/e point")
                task.wait(0.5)
            end
        end
        task.wait(tpDelay)
    end
end)

-- === CPU Saver ===
if _G.CPUSaver then
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        RunService:Set3dRenderingEnabled(false)
        UserSettings():GetService("UserGameSettings").MasterVolume = 0
        Lighting.GlobalShadows = false
        Lighting.Brightness = 0
        Lighting.FogEnd = 9e9
        Lighting.Ambient = Color3.new(0,0,0)
        Lighting.OutdoorAmbient = Color3.new(0,0,0)
    end)
    -- Disable particles
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

