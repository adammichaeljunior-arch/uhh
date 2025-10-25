-- === SETTINGS ===
local WEBHOOK_URL = "https://discord.com/api/webhooks/1423446494152884295/rip25iG9fUAoY63CE5uYRqpKNeNz5HJoS0jTH0X4CRpXkS2hJqBk6xn8KLq1yNu_BHxI"

local messages = {
    "join /sIowly for friends",
    "join /sIowly 4 nitro",
    "/sIowly 4 headless",
    "goon in /sIowly",
    "get active in /sIowly",
    "join /sIowly 4 Ekittens",
    "join /sIowly for friends"
}

local chatDelay = 2.5
local tpDelay = 3
local overlayDelay = 3 -- seconds before showing overlay

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
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- === FPS Cap ===
if setfpscap then
    setfpscap(6)
else
    warn("Executor does not support setfpscap!")
end

-- === Webhook Helper ===
local function sendWebhook(content, isPlainText)
    if not content then return false end
    
    local payload
    if isPlainText then
        payload = { content = content }
    else
        payload = {
            embeds = {{
                title = "Notification",
                description = content,
                color = 16711680,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
    end

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

-- === Universal Chat Function ===
local function sendChat(msg)
    if not msg or msg == "" then return end
    local success = false

    -- Try new TextChatService
    local tcs = game:GetService("TextChatService")
    if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
        local general = tcs:FindFirstChildOfClass("TextChannel")
        if general then
            pcall(function()
                general:SendAsync(msg)
                success = true
            end)
        end
    end

    -- Fallback to legacy chat
    if not success then
        local chatEvent = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvent and chatEvent:FindFirstChild("SayMessageRequest") then
            pcall(function()
                chatEvent.SayMessageRequest:FireServer(msg, "All")
                success = true
            end)
        end
    end

    -- Last fallback
    if not success then
        pcall(function()
            player:Chat(msg)
        end)
    end
end

-- === Overlay UI ===
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

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

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

-- === CPU Saver ===
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
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
        end
        workspace.DescendantAdded:Connect(function(v)
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
        end)
    end)
end

-- === Server Hop System ===
local lastServerId = nil
local MIN_PLAYERS = 10
local isHopping = false

local function queueScript()
    local SRC = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/jaja.lua"))()
    ]]
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(SRC)
    elseif queue_on_teleport then
        queue_on_teleport(SRC)
    end
end

local function getPublicServers(placeId)
    local servers = {}
    local cursor = ""
    repeat
        local success, result = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. cursor or ""))
        end)
        if success then
            local data = HttpService:JSONDecode(result)
            if data and data.data then
                for _, server in ipairs(data.data) do
                    table.insert(servers, server)
                end
            end
            cursor = data.nextPageCursor or ""
        else
            warn("[ServerHop] Failed to fetch server list.")
            break
        end
        task.wait(0.5)
    until cursor == "" or #servers >= 400
    return servers
end

local function serverHop(reason)
    if isHopping then return end
    isHopping = true

    sendWebhook(("User: %s (%s)\nReason: %s\nPlayers: %d\nJobId: %s")
        :format(player.Name, player.DisplayName, reason or "rotation", #Players:GetPlayers(), game.JobId), false)

    queueScript()

    local tries = 0
    while true do
        tries += 1
        local servers = getPublicServers(game.PlaceId)
        if not servers or #servers == 0 then
            warn("[ServerHop] No servers found, retrying ("..tries..")...")
            task.wait(5)
            continue
        end

        local validServers = {}
        for _, server in ipairs(servers) do
            if server.playing < server.maxPlayers
                and server.id ~= game.JobId
                and server.id ~= lastServerId
                and server.playing >= MIN_PLAYERS then
                table.insert(validServers, server)
            end
        end

        if #validServers == 0 then
            warn("[ServerHop] No valid servers found, retrying ("..tries..")...")
            task.wait(5)
            continue
        end

        table.sort(validServers, function(a, b)
            return a.playing > b.playing
        end)

        local target = validServers[math.random(1, math.min(5, #validServers))]
        lastServerId = target.id

        print(string.format("[ServerHop] Targeting server %s (%d/%d)", target.id, target.playing, target.maxPlayers))
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, player)
        end)
        if not success then
            warn("[ServerHop] Teleport failed: " .. tostring(err) .. " (retrying)")
            task.wait(5)
        else
            break
        end
    end
end

-- === Auto Chat ===
task.spawn(function()
    task.wait(3)
    local i = 1
    while _G.AutoSay do
        sendChat(messages[i])
        i = (i % #messages) + 1
        task.wait(chatDelay + math.random())
    end
end)

-- === Auto Teleport ===
task.spawn(function()
    while _G.AutoTP do
        local allPlayers = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(allPlayers, pl)
            end
        end

        if #allPlayers < 1 then
            info.Text = "⚠️ No players found. Hopping..."
            sendWebhook("No players found. Rotating server...", false)
            serverHop("Empty server")
            return
        end

        local reached = {}
        for _, target in ipairs(allPlayers) do
            info.Text = string.format(
                "👤 User: %s (%s)\n🎯 Target: %s\n👥 Players left: %d\n🗂 JobId: %s\n",
                player.Name, player.DisplayName,
                target.DisplayName or target.Name,
                #allPlayers - #reached,
                string.sub(game.JobId,1,8) .. "..."
            )

            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and hrp then
                hrp.CFrame = CFrame.new(
                    target.Character.HumanoidRootPart.Position + target.Character.HumanoidRootPart.CFrame.LookVector*3,
                    target.Character.HumanoidRootPart.Position
                )
            end

            if _G.AutoEmote then
                task.spawn(function()
                    for _ = 1, math.floor(tpDelay/0.5) do
                        sendChat("/e point")
                        task.wait(0.5)
                    end
                end)
            end

            table.insert(reached, target)
            task.wait(tpDelay + 1)
        end

        info.Text = "🔄 Finished all players. Hopping..."
        sendWebhook("Finished all players. Rotating server...", false)
        serverHop("Rotation after reaching players")
        task.wait(1)
    end
end)

-- === Idle Detection ===
local idleTime = 0
local idleThreshold = 300

UserInputService.InputBegan:Connect(function() idleTime = 0 end)
UserInputService.InputChanged:Connect(function() idleTime = 0 end)

task.spawn(function()
    while true do
        task.wait(1)
        idleTime += 1
        if idleTime >= idleThreshold then
            sendWebhook("@everyone Player has been idle for 5 minutes.", false)
            idleTime = 0
        end
    end
end)
