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
local tpDelay = 6
local emoteDelay = 3

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

-- === CPU SAVER ===
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

-- === OVERLAY ===
local gui = Instance.new("ScreenGui")
gui.Name = "Overlay"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.25,0,0.1,0)
frame.Position = UDim2.new(0.01,0,0.01,0)
frame.BackgroundColor3 = Color3.new(0,0,0)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = gui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1,0,1,0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1,1,1)
label.TextScaled = true
label.Text = "Initializing..."
label.Parent = frame

-- === AUTO TELEPORT + EMOTE + PLAYER COUNT ===
task.spawn(function()
    while true do
        -- get all current players except yourself
        local targets = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(targets, pl)
            end
        end

        local remaining = #targets
        for i, target in ipairs(targets) do
            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and
               player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                local targetPos = target.Character.HumanoidRootPart.Position
                hrp.CFrame = CFrame.new(targetPos + target.Character.HumanoidRootPart.CFrame.LookVector * 3, targetPos)
            end

            -- emote loop
            if _G.AutoEmote then
                local emotes = math.floor(tpDelay / emoteDelay)
                for _ = 1, emotes do
                    sendChat("/e point")
                    task.wait(emoteDelay)
                end
            else
                task.wait(tpDelay)
            end

            remaining = remaining - 1
            label.Text = "Players left: "..remaining
        end

        -- done all players
        label.Text = "Server hopping..."
        task.wait(1)

        -- teleport to new server
        if syn and syn.queue_on_teleport then
            syn.queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/haha.lua'))()")
        end

        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId, player)
        break
    end
end)

-- === AUTO JUMP ===
task.spawn(function()
    while true do
        if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
            player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
        end
        task.wait(15)
    end
end)
