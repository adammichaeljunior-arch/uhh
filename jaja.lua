-- === SETTINGS ===
local messages = {
    "join /Εnvyy for fansignss",
    "join /Εnvyy for emommys",
    "bored? hop in /Εnvyy",
    "THEYRE WHIMPERING IN VC LOL /envyy",
    "join /Εnvyy 4 nitro",
    "/Εnvyy 4 headless",
    "goon in /Εnvyy",
    "join /Εnvyy 4 eheadd",
    "join /Εnvyy for ROBUX"
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

local player = Players.LocalPlayer

-- Safe TextChannel reference (some games may not have RBXGeneral)
local channel
pcall(function()
    channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
end)

-- === CHAT HELPER ===
local function sendChat(msg)
    if channel then
        pcall(function()
            channel:SendAsync(msg)
        end)
    end
end

-- === PLAYER COUNTDOWN & OVERLAY ===
local overlay = Instance.new("ScreenGui")
overlay.Name = "PlayerOverlay"
overlay.IgnoreGuiInset = true
overlay.ResetOnSpawn = false
overlay.Parent = player:WaitForChild("PlayerGui")

local overlayLabel = Instance.new("TextLabel")
overlayLabel.Size = UDim2.new(0.3,0,0.1,0)
overlayLabel.Position = UDim2.new(0.35,0,0.05,0)
overlayLabel.BackgroundColor3 = Color3.new(0,0,0)
overlayLabel.TextColor3 = Color3.new(1,1,1)
overlayLabel.TextScaled = true
overlayLabel.Text = "Initializing..."
overlayLabel.Parent = overlay

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
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
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

-- === AUTO TELEPORT + EMOTE + EMPTY SERVER CHECK ===
task.spawn(function()
    while _G.AutoTP do
        local allPlayers = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(allPlayers, pl)
            end
        end

        -- Auto-hop if no other players
        if #allPlayers < minPlayers then
            overlayLabel.Text = "Server empty, hopping..."
            serverHop()
            task.wait(2)
        end

        local reachedPlayers = {}

        for _, target in ipairs(allPlayers) do
            overlayLabel.Text = ("Players left: %d"):format(#allPlayers - #reachedPlayers)
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

-- === AUTO-I AGREE BUTTON ===
local function autoAgreeButton(gui)
    if gui:IsA("TextButton") or gui:IsA("ImageButton") then
        if gui.Text:lower():find("i agree") or gui.Name:lower():find("iagree") then
            pcall(function()
                gui:Activate() -- clicks the button
            end)
        end
    end
end

-- Check existing buttons in PlayerGui
for _, gui in ipairs(player:WaitForChild("PlayerGui"):GetDescendants()) do
    autoAgreeButton(gui)
end

-- Listen for new buttons added to PlayerGui
player.PlayerGui.DescendantAdded:Connect(autoAgreeButton)

-- Check CoreGui too
for _, gui in ipairs(game:GetService("CoreGui"):GetDescendants()) do
    autoAgreeButton(gui)
end

game:GetService("CoreGui").DescendantAdded:Connect(autoAgreeButton)
