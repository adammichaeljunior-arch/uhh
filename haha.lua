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
local tpDelay = 8.5
local minPlayers = 2 -- minimal players in server to start

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
local MOD_ID = 943340328 -- change this to your mod's ID

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

-- === CPU SAVER & Overlay ===
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

    local gui = Instance.new("ScreenGui")
    gui.Name = "CPUSaverOverlay"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.3,0,0.1,0)
    frame.Position = UDim2.new(0.35,0,0.9,0)
    frame.BackgroundColor3 = Color3.new(0,0,0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Text = "Players left: 0"
    label.Parent = frame

    -- Extra CPU: disable particles
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

-- === AUTO JUMP (anti seat/AFK) ===
task.spawn(function()
    while true do
        if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
            player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
        end
        task.wait(15)
    end
end)

-- === MODERATOR DETECTION & SERVER HOP ===
local function serverHop(reason)
    label.Text = "Server hopping..."
    task.wait(2)
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/haha.lua'))()")
    end
    TeleportService:Teleport(game.PlaceId, player)
end

local function onMod(reason)
    serverHop("Moderator detected: "..reason)
end

-- Check existing players
for _, pl in ipairs(Players:GetPlayers()) do
    if pl.UserId == MOD_ID then
        onMod("already in server")
    end
end

-- Check future joins
Players.PlayerAdded:Connect(function(pl)
    if pl.UserId == MOD_ID then
        onMod("joined")
    end
end)

-- === AUTO TELEPORT + EMOTE with proper countdown ===
task.spawn(function()
    while _G.AutoTP do
        local allPlayers = Players:GetPlayers()
        local targets = {}
        for _, pl in ipairs(allPlayers) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(targets, pl)
            end
        end

        if #targets < minPlayers then
            game:Shutdown()
            return
        end

        while #targets > 0 do
            local target = targets[1]
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local targetHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if hrp and targetHRP then
                hrp.CFrame = CFrame.new(targetHRP.Position + targetHRP.CFrame.LookVector*3, targetHRP.Position)
            end

            -- Remove player from list
            table.remove(targets,1)

            -- Update overlay countdown
            label.Text = "Players left: "..#targets

            -- Emote spam
            if _G.AutoEmote then
                for _ = 1, math.floor(tpDelay/0.5) do
                    pcall(function() player:FindFirstChildOfClass("Player"):Chat("/e point") end)
                    task.wait(0.5)
                end
            end

            task.wait(tpDelay)
        end

        -- All players reached, hop
        serverHop("All players reached")
        break
    end
end)
