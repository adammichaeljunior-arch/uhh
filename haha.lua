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
local tpDelay = 4 -- teleport per player
local minPlayers = 2

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

-- === CHAT HELPER ===
local lastMessageTime = 0
local function sendChat(msg)
    local ok, err = pcall(function()
        channel:SendAsync(msg)
    end)
    if ok then
        lastMessageTime = os.time()
    else
        warn("Chat error/rate limit:", err)
    end
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

-- === CPU SAVER / OVERLAY ===
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

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.5,0,0,50)
label.Position = UDim2.new(0.5,0,0,10)
label.AnchorPoint = Vector2.new(0.5,0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1,1,1)
label.TextScaled = true
label.Text = "Players left: 0"
label.Parent = frame

-- CPU optimization
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

    -- disable particles/trails
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

-- === SERVER HOP FUNCTION ===
local function serverHop(reason)
    label.Text = "Server hopping..."
    task.wait(1)
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/haha.lua"))
    end
    TeleportService:Teleport(game.PlaceId, player)
end

-- === AUTO TELEPORT + EMOTE WITH COUNTDOWN ===
task.spawn(function()
    while _G.AutoTP do
        -- create target list once
        local allPlayers = Players:GetPlayers()
        local targets = {}
        for _, pl in ipairs(allPlayers) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(targets, pl)
            end
        end

        label.Text = "Players left: "..#targets

        if #targets < minPlayers then
            game:Shutdown()
            return
        end

        for i, target in ipairs(targets) do
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local targetHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if hrp and targetHRP then
                hrp.CFrame = CFrame.new(targetHRP.Position + targetHRP.CFrame.LookVector*3, targetHRP.Position)
            end

            -- Emote spam
            if _G.AutoEmote then
                for _ = 1, math.floor(tpDelay/0.5) do
                    pcall(function() player:FindFirstChildOfClass("Player"):Chat("/e point") end)
                    task.wait(0.5)
                end
            end

            -- remove from counter and update overlay
            label.Text = "Players left: "..(#targets - i)
            task.wait(tpDelay)
        end

        -- Hop after all players
        serverHop("All players reached")
        break
    end
end)

-- === AUTO JUMP (anti-AFK) ===
task.spawn(function()
    while true do
        if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
            player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
        end
        task.wait(15)
    end
end)
