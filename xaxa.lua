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

local player = Players.LocalPlayer
local channel = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

-- === CHAT HELPER ===
local lastMessageTime = 0
local function sendChat(msg)
    if not channel then return end
    local ok = pcall(function()
        channel:SendAsync(msg)
    end)
    if ok then
        lastMessageTime = os.time()
    end
end

-- === MAIN OVERLAY (INFO) ===
local overlay = Instance.new("ScreenGui")
overlay.Name = "PlayerOverlay"
overlay.IgnoreGuiInset = true
overlay.ResetOnSpawn = false
overlay.Parent = player:WaitForChild("PlayerGui")

local overlayFrame = Instance.new("Frame")
overlayFrame.Size = UDim2.new(0.3,0,0.15,0)
overlayFrame.Position = UDim2.new(0.35,0,0.05,0)
overlayFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
overlayFrame.BorderSizePixel = 0
overlayFrame.Parent = overlay

local overlayCorner = Instance.new("UICorner")
overlayCorner.CornerRadius = UDim.new(0,12)
overlayCorner.Parent = overlayFrame

local overlayLabel = Instance.new("TextLabel")
overlayLabel.Size = UDim2.new(1,0,1,0)
overlayLabel.BackgroundTransparency = 1
overlayLabel.TextColor3 = Color3.fromRGB(220,220,220)
overlayLabel.TextScaled = true
overlayLabel.Text = "⏳ Initializing..."
overlayLabel.Font = Enum.Font.SourceSansBold
overlayLabel.Parent = overlayFrame

-- === CHAT LOGGER UI ===
local chatGui = Instance.new("ScreenGui")
chatGui.Name = "ChatLogger"
chatGui.IgnoreGuiInset = true
chatGui.ResetOnSpawn = false
chatGui.Parent = player:WaitForChild("PlayerGui")

local chatFrame = Instance.new("ScrollingFrame")
chatFrame.Size = UDim2.new(0.35, 0, 0.6, 0)
chatFrame.Position = UDim2.new(0.02, 0, 0.2, 0)
chatFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
chatFrame.BorderSizePixel = 0
chatFrame.CanvasSize = UDim2.new(0,0,0,0)
chatFrame.ScrollBarThickness = 4
chatFrame.Parent = chatGui

local chatCorner = Instance.new("UICorner")
chatCorner.CornerRadius = UDim.new(0,12)
chatCorner.Parent = chatFrame

local chatList = Instance.new("UIListLayout")
chatList.Parent = chatFrame
chatList.Padding = UDim.new(0, 6)
chatList.FillDirection = Enum.FillDirection.Vertical
chatList.SortOrder = Enum.SortOrder.LayoutOrder

-- Function to add a chat message
local function addChatMessage(plr, message)
    if plr == player then return end -- skip your own messages

    local msgFrame = Instance.new("Frame")
    msgFrame.Size = UDim2.new(1, 0, 0, 50)
    msgFrame.BackgroundTransparency = 1
    msgFrame.Parent = chatFrame

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(0, 40, 0, 40)
    img.Position = UDim2.new(0, 5, 0, 5)
    img.BackgroundTransparency = 1
    img.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..plr.UserId.."&width=48&height=48&format=png"
    img.Parent = msgFrame

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -55, 1, 0)
    txt.Position = UDim2.new(0, 55, 0, 0)
    txt.BackgroundTransparency = 1
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextYAlignment = Enum.TextYAlignment.Center
    txt.Font = Enum.Font.SourceSansBold
    txt.TextSize = 18
    txt.TextColor3 = Color3.fromRGB(220,220,220)
    txt.Text = plr.Name..": "..message
    txt.Parent = msgFrame

    chatFrame.CanvasSize = UDim2.new(0,0,0,chatList.AbsoluteContentSize.Y + 10)
end

-- Hook chat system
if TextChatService.OnIncomingMessage then
    TextChatService.OnIncomingMessage = function(msg)
        local plr = Players:GetPlayerByUserId(msg.TextSource and msg.TextSource.UserId or 0)
        if plr and plr ~= player then
            addChatMessage(plr, msg.Text)
        end
    end
end

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

-- === SERVER HOP ===
local function serverHop()
    overlayLabel.Text = "🔄 Server hopping..."
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
            serverHop()
            return
        end
    end
end
for _, pl in ipairs(Players:GetPlayers()) do
    checkForMods(pl)
end
Players.PlayerAdded:Connect(checkForMods)

-- === AUTO CHAT LOOP (with delay before start) ===
task.delay(3, function()
    task.spawn(function()
        local i = 1
        while _G.AutoSay do
            sendChat(messages[i])
            i = i + 1
            if i > #messages then i = 1 end
            task.wait(chatDelay)
        end
    end)
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
        if #allPlayers <= 0 then
            overlayLabel.Text = "⚠️ No players here. Hopping..."
            serverHop()
            return
        end
        local reachedPlayers = {}
        for _, target in ipairs(allPlayers) do
            overlayLabel.Text = ("👥 Players left: %d"):format(#allPlayers - #reachedPlayers)
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
        overlayLabel.Text = "🔄 Server hopping..."
        serverHop()
        task.wait(1)
    end
end)
