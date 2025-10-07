-- === SETTINGS ===
local WEBHOOK_URL = "https://discord.com/api/webhooks/1423446494152884295/rip25iG9fUAoY63CE5uYRqpKNeNz5HJoS0jTH0X4CRpXkS2hJqBk6xn8KLq1yNu_BHxI"

local messages = {
    "join ⁄LoIz for ekittens",
    "bored?? join ⁄LoIz and chat",
    "join ⁄LoIz  4 nitro",
    "⁄LoIz 4 headless",
    "Face 4 Face (polls) active in ⁄LoIz",
    "join  ⁄LoIz 4 robuxx",
    "goon in  ⁄LoIz",
    "join  ⁄LoIz for fun",
    "join  ⁄LoIz for friends"
}
local chatDelay = 3.5
local overlayDelay = 1
local walkSpeed = 16

-- === TOGGLES ===
_G.AutoSay = true
_G.AutoEmote = true
_G.CPUSaver = true

-- === SERVICES ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")
local player = Players.LocalPlayer
local channel = nil
pcall(function() channel = TextChatService.TextChannels:WaitForChild("RBXGeneral", 10) end)

-- === WEBHOOK SENDER ===
local HttpService = game:GetService("HttpService")
local function sendWebhook(content, title, color)
    if not content then return false end
    color = color or 16711680
    title = title or "Notification"

    local payload = {
        embeds = {{
            title = title,
            description = content,
            color = color,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    local requestBody = {
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload),
    }

    if syn and syn.request then return syn.request(requestBody) end
    if http_request then return http_request(requestBody) end
    if http and http.request then return http.request(requestBody) end
    if request then return request(requestBody) end
end

-- === CHAT HELPER ===
local function sendChat(msg)
    if not channel then return end
    pcall(function()
        channel:SendAsync(msg)
    end)
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
end

-- === WALK TO PLAYER FUNCTION ===
local function walkTo(targetPos)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return end
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
    for _, wp in ipairs(waypoints) do
        humanoid:MoveTo(wp.Position)
        humanoid.MoveToFinished:Wait()
    end
end

-- === AUTO CHAT LOOP ===
task.spawn(function()
    task.wait(3)
    local i = 1
    while _G.AutoSay do
        sendChat(messages[i])
        i = (i % #messages) + 1
        task.wait(chatDelay + math.random())
    end
end)

-- === AUTO WALK + EMOTE LOOP ===
task.spawn(function()
    task.wait(3)
    while true do
        local allPlayers = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(allPlayers, pl)
            end
        end

        if #allPlayers < 1 then
            info.Text = "⚠️ No players found. Waiting..."
            task.wait(5)
        else
            for _, target in ipairs(allPlayers) do
                local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    info.Text = "🎯 Walking to: "..target.DisplayName
                    walkTo(hrp.Position)

                    if _G.AutoEmote then
                        for _ = 1, 3 do
                            sendChat("/e point")
                            task.wait(0.5)
                        end
                    end

                    for _, msg in ipairs(messages) do
                        sendChat(msg)
                        task.wait(1)
                    end

                    task.wait(2)
                end
            end
            info.Text = "✅ Finished walking all players. Looping..."
            task.wait(3)
        end
    end
end)
