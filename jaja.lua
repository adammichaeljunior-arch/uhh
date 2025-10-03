-- === SETTINGS ===
local WEBHOOK_URL = "https://discord.com/api/webhooks/XXXXXXXXX/XXXXXXXXX" -- replace
local minPlayers = 10 -- won't join servers smaller than this
local chatDelay = 2.5
local tpDelay = 6
local overlayDelay = 3
local hoverTime = 4 -- seconds to hover over each player

-- === TOGGLES ===
_G.AutoSay = true
_G.AutoTP = true
_G.AutoEmote = true
_G.CPUSaver = true

-- === SERVICES ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local channel = nil
pcall(function() channel = TextChatService.TextChannels:WaitForChild("RBXGeneral", 5) end)

-- === WEBHOOK ===
local function sendWebhookEmbed(title, description, color)
    local payload = HttpService:JSONEncode({
        embeds = {{
            title = title,
            description = description,
            color = color or 16753920,
            timestamp = DateTime.now():ToIsoDate()
        }}
    })
    local requestBody = {
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = payload,
    }
    if syn and syn.request then return syn.request(requestBody) end
    if http_request then return http_request(requestBody) end
    if request then return request(requestBody) end
end

-- === CHAT HELPER ===
local function sendChat(msg)
    if not channel then return end
    pcall(function() channel:SendAsync(msg) end)
end

-- === OVERLAY ===
local overlay = Instance.new("ScreenGui")
overlay.Name = "Overlay"
overlay.IgnoreGuiInset = true
overlay.ResetOnSpawn = false
overlay.Parent = player:WaitForChild("PlayerGui")

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1,0,1,0)
bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
bg.BorderSizePixel = 0
bg.Visible = false
bg.Parent = overlay

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0.5,0,0.5,0)
panel.Position = UDim2.new(0.25,0,0.25,0)
panel.BackgroundColor3 = Color3.fromRGB(25,25,25)
panel.BorderSizePixel = 0
panel.Parent = bg

local corner = Instance.new("UICorner", panel)
corner.CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1,0,0.15,0)
title.BackgroundTransparency = 1
title.Text = "🌐 Auto System Overlay"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(200,200,200)

local info = Instance.new("TextLabel", panel)
info.Size = UDim2.new(1,-20,0.8,-20)
info.Position = UDim2.new(0,10,0.18,0)
info.BackgroundTransparency = 1
info.Font = Enum.Font.Gotham
info.TextScaled = true
info.TextWrapped = true
info.TextColor3 = Color3.fromRGB(180,180,180)
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Text = "Loading..."

task.delay(overlayDelay, function() bg.Visible = true end)

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

-- === MOD PROTECTION ===
local MOD_IDS = {
    419612796, 82591348, 540190518, 9125708679,
    4992470579, 38701072, 7423673502, 3724230698,
    418307435, 73344996, 37343237, 2862215389,
    103578797, 1562079996, 2542703855, 210949,
    337367059, 1159074474
}

local function checkForMods()
    for _, pl in ipairs(Players:GetPlayers()) do
        for _, id in ipairs(MOD_IDS) do
            if pl.UserId == id then
                sendWebhookEmbed("🚨 Mod Detected", pl.Name .. " ("..pl.UserId..")", 16711680)
                return true
            end
        end
    end
    return false
end

Players.PlayerAdded:Connect(function(pl)
    if table.find(MOD_IDS, pl.UserId) then
        sendWebhookEmbed("🚨 Mod Detected", pl.Name .. " joined.", 16711680)
        task.wait(2)
        TeleportService:Teleport(game.PlaceId, player)
    end
end)

-- === SERVER HOP ===
local function serverHop(reason)
    info.Text = "⏭ Hopping... ("..(reason or "rotation")..")"
    sendWebhookEmbed("🌐 Server Hop", "Reason: "..(reason or "rotation"), 65535)

    local success, body = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100")
    end)
    if success then
        local data = HttpService:JSONDecode(body)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId and server.playing >= minPlayers then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                    return
                end
            end
        end
    end
    TeleportService:Teleport(game.PlaceId, player)
end

-- === AUTO CHAT LOOP ===
task.spawn(function()
    task.wait(4) -- wait before spamming
    if checkForMods() then serverHop("Mod present on join") return end

    while _G.AutoSay do
        sendChat("join /Εnvyy for fansigns")
        task.wait(chatDelay + math.random())
    end
end)

-- === HOVER FOLLOW LOOP ===
task.spawn(function()
    task.wait(4) -- initial mod check delay
    if checkForMods() then serverHop("Mod present on join") return end

    while _G.AutoTP do
        local allPlayers = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(allPlayers, pl)
            end
        end

        if #allPlayers < minPlayers then
            serverHop("Too small")
            return
        end

        for _, target in ipairs(allPlayers) do
            if checkForMods() then serverHop("Mod detected mid-run") return end

            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and hrp then
                local startTime = tick()
                while tick() - startTime < hoverTime do
                    local targetPos = target.Character.HumanoidRootPart.Position + Vector3.new(0,5,0)
                    hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(targetPos, target.Character.HumanoidRootPart.Position), 0.25)
                    task.wait(0.1)
                end
            end

            if _G.AutoEmote then
                sendChat("/e point")
            end

            task.wait(1)
        end

        serverHop("Rotation done")
        task.wait(1)
    end
end)
