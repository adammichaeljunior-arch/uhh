-- === SETTINGS ===
local messages = {
    "join ⁄|olz for ekittens",
    "bored?? join ⁄|olz and chat",
    "join ⁄|olz  4 nitro",
    "⁄|olz 4 headless",
    "Face 4 Face (polls) active in ⁄|olz",
    "join  /|olz 4 robuxx",
    "goon in  /|olz",
    "join  /|olz for fun",
    "join  /|olz for friends"
}
local chatDelay = 0.5
local tpDelay = 2
local overlayDelay = 1
local minPlayers = 8
local walkSpeed = 16

-- === TOGGLES ===
_G.AutoTP = true
_G.AutoEmote = true
_G.CPUSaver = true

-- === SERVICES ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")
local player = Players.LocalPlayer

-- === SAFE CHAT SETUP ===
local SayMessageRequest
local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
if chatEvents then
    SayMessageRequest = chatEvents:FindFirstChild("SayMessageRequest")
    if not SayMessageRequest then
        warn("SayMessageRequest not found in DefaultChatSystemChatEvents")
    end
else
    warn("DefaultChatSystemChatEvents not found in ReplicatedStorage")
end

local function SendPublicMessage(msg)
    if SayMessageRequest then
        SayMessageRequest:FireServer(msg, "All")
    else
        warn("Cannot send message, SayMessageRequest missing")
    end
end

-- === UI CREATION ===
local overlay = Instance.new("ScreenGui")
overlay.Name = "FancyOverlay"
overlay.IgnoreGuiInset = true
overlay.ResetOnSpawn = false
overlay.Parent = player:WaitForChild("PlayerGui")

local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BorderSizePixel = 0
background.Visible = false
background.Parent = overlay

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0.5, 0, 0.5, 0)
panel.Position = UDim2.new(0.25, 0, 0.25, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
panel.BorderSizePixel = 0
panel.Parent = background

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.15, 0)
title.BackgroundTransparency = 1
title.Text = "🌐 Auto System Overlay"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(200,200,200)
title.Parent = panel

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0.8, -20)
info.Position = UDim2.new(0, 10, 0.18, 0)
info.BackgroundTransparency = 1
info.Font = Enum.Font.Gotham
info.TextScaled = true
info.TextWrapped = true
info.TextColor3 = Color3.fromRGB(180,180,180)
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Text = "Loading..."
info.Parent = panel

task.delay(overlayDelay, function()
    background.Visible = true
end)

-- === CPU SAVER ===
pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    RunService:Set3dRenderingEnabled(false)
    Lighting.GlobalShadows = false
    Lighting.Brightness = 0
    Lighting.FogEnd = 9e9
    Lighting.Ambient = Color3.new(0,0,0)
    Lighting.OutdoorAmbient = Color3.new(0,0,0)
end)

-- === TRACK PLAYERS AND SERVERS ===
local messagedPlayers = {}
local visitedServers = {}

-- === SERVER LIST FUNCTION ===
local function GetServerList(placeId, minPlayers, maxPages)
    maxPages = maxPages or 5
    local servers = {}
    local cursor
    for i = 1, maxPages do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100%s"):format(placeId, cursor and "&cursor="..cursor or "")
        local success, response = pcall(function() return HttpService:GetAsync(url) end)
        if success then
            local data = HttpService:JSONDecode(response)
            for _, v in ipairs(data.data) do
                if v.playing >= minPlayers and not visitedServers[v.id] then
                    table.insert(servers, v.id)
                end
            end
            cursor = data.nextPageCursor
            if not cursor then break end
        else
            break
        end
    end
    return servers
end

-- === CHECK IF PLAYER IS TYPING SAME MESSAGE ===
local function IsTypingSameMessage(pl)
    if pl:FindFirstChild("PlayerGui") and pl.PlayerGui:FindFirstChild("Chat") then
        local success, chatBar = pcall(function()
            return pl.PlayerGui.Chat.Frame.ChatBarParentFrame.Frame.BoxFrame.Frame.TextBox
        end)
        if success and chatBar.Text ~= "" then
            for _, msg in ipairs(messages) do
                if chatBar.Text:lower():find(msg:lower()) then
                    return true
                end
            end
        end
    end
    return false
end

-- === WALK TO PLAYER WITH PATHFINDING (CORRECTED) ===
local function WalkTo(targetPos)
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end
    humanoid.WalkSpeed = walkSpeed

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 10,
        AgentMaxSlope = 45
    })
    
    path:ComputeAsync(hrp.Position, targetPos)
    local waypoints = path:GetWaypoints()
    
    for _, waypoint in ipairs(waypoints) do
        humanoid:MoveTo(waypoint.Position)
        humanoid.MoveToFinished:Wait()
    end
end

-- === MAIN LOOP ===
task.spawn(function()
    task.wait(3)
    while true do
        local allPlayers = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and
               not messagedPlayers[pl.UserId] and not IsTypingSameMessage(pl) then
                table.insert(allPlayers, pl)
            end
        end

        if #allPlayers < 1 then
            info.Text = "✅ All players messaged or typing. Searching new server..."
            task.wait(2)

            local servers = GetServerList(game.PlaceId, minPlayers)
            if #servers < 1 then
                info.Text = "⚠️ No full servers found, trying smaller servers..."
                servers = GetServerList(game.PlaceId, 1)
            end

            if #servers > 0 then
                local nextServer = servers[math.random(1, #servers)]
                visitedServers[nextServer] = true
                TeleportService:TeleportToPlaceInstance(game.PlaceId, nextServer, player)
                break
            else
                info.Text = "❌ No servers available. Retrying..."
                task.wait(5)
            end
        else
            for _, target in ipairs(allPlayers) do
                local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    info.Text = "🎯 Walking to: "..target.DisplayName
                    WalkTo(hrp.Position)

                    if _G.AutoEmote then
                        info.Text = "🤖 Emote simulated..."
                        task.wait(0.5)
                    end

                    for _, msg in ipairs(messages) do
                        SendPublicMessage(msg)
                        task.wait(chatDelay)
                    end

                    messagedPlayers[target.UserId] = true
                    task.wait(tpDelay)
                end
            end
        end
    end
end)
