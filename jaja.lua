-- ================== SERVICES ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local channel = nil
pcall(function() channel = TextChatService.TextChannels:WaitForChild("RBXGeneral", 5) end)

local WEBHOOK_URL = "https://discord.com/api/webhooks/1423446494152884295/rip25iG9fUAoY63CE5uYRqpKNeNz5HJoS0jTH0X4CRpXkS2hJqBk6xn8KLq1yNu_BHxI"

-- ================== HELPERS ==================
local function sendWebhook(content, isPlainText)
    if not content then return end
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

local function sendChat(msg)
    if not channel then return end
    pcall(function()
        channel:SendAsync(msg)
    end)
end

-- ================== CPU Saver ==================
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

-- ================== Queue on teleport ==================
local function queueScript()
    local SRC = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/haha.lua"))()
    ]]
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(SRC)
    elseif queue_on_teleport then
        queue_on_teleport(SRC)
    end
end

-- ================== Server Hop ==================
local lastServerId = nil
local function serverHop(reason)
    sendWebhook("Hopping server: " .. reason, false)
    queueScript()
    -- Fetch servers
    local function getServers()
        local servers = {}
        local cursor = ""
        repeat
            local success, result = pcall(function()
                return game:HttpGet("https://games.roblox.com/v1/games/"..game.GameId.."/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor="..cursor or ""))
            end)
            if success and result then
                local data = HttpService:JSONDecode(result)
                if data and data.data then
                    for _, server in ipairs(data.data) do
                        table.insert(servers, server)
                    end
                end
                cursor = data.nextPageCursor or ""
            else
                break
            end
            task.wait(0.5)
        until cursor == "" or #servers >= 400
        return servers
    end

    local servers = getServers()
    if not servers or #servers == 0 then
        -- fallback
        TeleportService:Teleport(game.PlaceId)
        return
    end

    -- Filter servers
    local validServers = {}
    for _, server in ipairs(servers) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId and server.id ~= lastServerId and server.playing >= 10 then
            table.insert(validServers, server)
        end
    end

    if #validServers == 0 then
        TeleportService:Teleport(game.PlaceId)
        return
    end

    table.sort(validServers, function(a,b) return a.playing > b.playing end)
    local target = validServers[math.random(1, math.min(5, #validServers))]
    lastServerId = target.id
    TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id)
end

-- ================== Get Front Position of Player ==================
local function getFrontPosition(pl)
    local hrp = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local lookVector = hrp.CFrame.LookVector
    local frontPos = hrp.CFrame.Position + lookVector * 3 -- 3 studs in front
    return frontPos
end

-- ================== Character & Movement ==================
local function isCharacterReady()
    local c = player.Character
    if not c then return false end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    return hrp ~= nil and hum ~= nil
end

local function teleportTo(pos)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        task.wait(0.2)
    end
end

local function followAndReach(targetPos, timeout)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return false end
    humanoid.WalkSpeed = 40
    local startTime = os.clock()
    repeat
        humanoid:MoveTo(targetPos)
        task.wait(0.5)
        if (hrp.Position - targetPos).Magnitude < 3 then
            humanoid.WalkSpeed = 16
            return true
        end
        if os.clock() - startTime > timeout then
            humanoid.WalkSpeed = 16
            return false
        end
    until false
end

local function visitPlayer(pl)
    local targetPos = getFrontPosition(pl)
    if not targetPos then return end

    local success = false
    local startTime = os.clock()

    -- Follow/Reach with timeout of 20s
    repeat
        if isCharacterReady() then
            success = followAndReach(targetPos, 20)
        end
        if success then break end
        -- If not reached in 20s, teleport
        if os.clock() - startTime > 20 then
            teleportTo(targetPos)
            success = true
            break
        end
        task.wait(0.5)
    until false

    -- Small wait after reaching
    task.wait(2)

    -- Ask question
    local questions = {
        "we got hella egirls in gg/slowly",
        "join gg/slowly!",
        "come goon in gg/slowly",
        "we giving out rbx in gg/slowly",
        "someone was talking about u in gg/slowly LOL"
    }
    local question = questions[math.random(1, #questions)]
    sendChat(question)

    -- Wait 15s for response
    local responseMsg = nil
    local responseReceived = false
    local connections = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        table.insert(connections, pl.Chatted:Connect(function(msg)
            if pl == player then return end
            responseMsg = msg
            responseReceived = true
        end))
    end
    local responseTimeout = 20
    local elapsed = 0
    repeat
        task.wait(1)
        elapsed = elapsed + 1
    until responseReceived or elapsed >= responseTimeout
    for _, conn in ipairs(connections) do conn:Disconnect() end

    -- Small delay after response
    task.wait(3)

    -- Send "gg/slowly" regardless of answer
    sendChat("join gg/slowly")
    task.wait(5)
end

-- ================== Main Loop ==================
task.spawn(function()
    local allPlayers = Players:GetPlayers()
    for _, pl in ipairs(allPlayers) do
        if pl ~= Players.LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
            visitPlayer(pl)
        end
    end
    -- After all players are visited, hop server
    serverHop("Finished visiting all players")
end)
