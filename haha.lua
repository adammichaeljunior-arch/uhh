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
local minPlayers = 2 -- Minimum players to run script
local MOD_ID = 943340328 -- replace with mod ID
local GAME_ID = game.PlaceId

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

-- Wait for PlayerGui safely
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
    warn("PlayerGui not found, cannot create overlay")
    return
end

local channel = TextChatService.TextChannels:WaitForChild("RBXGeneral")

-- === CHAT HELPER ===
local lastMessageTime = 0
local function sendChat(msg)
    local ok, err = pcall(function()
        channel:SendAsync(msg)
    end)
    if ok then lastMessageTime = os.time() end
    return ok, err
end

-- === QUEUE SCRIPT ON TELEPORT ===
local SCRIPT_SOURCE = [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/haha.lua"))()
]]
local function queueScript()
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(SCRIPT_SOURCE)
    elseif queue_on_teleport then
        queue_on_teleport(SCRIPT_SOURCE)
    elseif getgenv and getgenv().queue_on_teleport then
        getgenv().queue_on_teleport(SCRIPT_SOURCE)
    else
        warn("queue_on_teleport not found")
    end
end

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

    if setfpscap then setfpscap(8) end
end

-- === GUI OVERLAY ===
local gui = Instance.new("ScreenGui")
gui.Name = "Overlay"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.25, 0, 0.15, 0)
frame.Position = UDim2.new(0.01, 0, 0.01, 0)
frame.BackgroundColor3 = Color3.new(0,0,0)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = gui

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -10, 1, -10)
infoLabel.Position = UDim2.new(0,5,0,5)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.new(1,1,1)
infoLabel.TextScaled = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Text = ""
infoLabel.Parent = frame

local playersLeft = 0
local isServerHopping = false

task.spawn(function()
    while true do
        local others = Players:GetPlayers()
        playersLeft = math.max(0, #others - 1)
        infoLabel.Text = ("Account: %s\nPlayers left: %d%s"):format(
            player.Name,
            playersLeft,
            isServerHopping and "\nServer hopping..." or ""
        )
        task.wait(0.5)
    end
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

-- === TELEPORT + EMOTE LOOP ===
task.spawn(function()
    while _G.AutoTP do
        local others = Players:GetPlayers()
        if #others < minPlayers then
            game:Shutdown()
            return
        end

        -- Check for mod
        for _, pl in ipairs(others) do
            if pl.UserId == MOD_ID then
                isServerHopping = true
                queueScript()
                local ok, body = pcall(function()
                    local url = "https://games.roblox.com/v1/games/"..GAME_ID.."/servers/Public?sortOrder=Asc&limit=100"
                    return HttpService:JSONDecode(game:HttpGet(url))
                end)
                if ok and body and body.data then
                    for _, s in ipairs(body.data) do
                        if s.playing < s.maxPlayers and s.id ~= game.JobId then
                            TeleportService:TeleportToPlaceInstance(GAME_ID, s.id, player)
                            return
                        end
                    end
                end
                TeleportService:Teleport(GAME_ID, player)
                return
            end
        end

        isServerHopping = false

        local targets = {}
        for _, pl in ipairs(others) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(targets, pl)
            end
        end

        for _, target in ipairs(targets) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                local targetPos = target.Character.HumanoidRootPart.Position
                hrp.CFrame = CFrame.new(targetPos + target.Character.HumanoidRootPart.CFrame.LookVector * 3, targetPos)
            end

            if _G.AutoEmote then
                local emoteCount = math.floor(tpDelay / 3)
                for _ = 1, emoteCount do
                    sendChat("/e point")
                    task.wait(3)
                end
            else
                task.wait(tpDelay)
            end
        end
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
