-- === SETTINGS ===
local WEBHOOK_URL = "https://discord.com/api/webhooks/1423446494152884295/rip25iG9fUAoY63CE5uYRqpKNeNz5HJoS0jTH0X4CRpXkS2hJqBk6xn8KLq1yNu_BHxI"

if setfpscap then
    setfpscap(20) -- Change this value to your desired FPS
else
    warn("Executor does not support setfpscap!")
end


local messages = {
    "LOLZ\\ for ekittens",
    "bored?? get active in LOLZ\\ and chat",
    "LOLZ\\  4 nitro",
    "LOLZ\\ 4 headless",
    "LOLZ\\",
    " LOLZ\\ 4 robuxx",
    "goon in  LOLZ\\",
    "LOLZ\\ for friends"
}
local chatDelay = 6.5
local tpDelay = 5
local overlayDelay = 1 -- seconds before showing overlay

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
local channel = nil
pcall(function() channel = TextChatService.TextChannels:WaitForChild("RBXGeneral", 5) end)

-- === WEBHOOK SENDER (WITH EMBEDS & TIMESTAMPS) ===
local function sendWebhook(content, title, color)
    if not content then return false end
    color = color or 16711680 -- default red
    title = title or "Notification"
    
    local payload = {
        embeds = {{
            title = title,
            description = content,
            color = color,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") -- UTC ISO format
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
local lastMessageTime = 0
local function sendChat(msg)
    if not channel then return end
    local ok = pcall(function()
        channel:SendAsync(msg)
    end)
    if ok then lastMessageTime = os.time() end
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

-- main panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0.5, 0, 0.5, 0)
panel.Position = UDim2.new(0.25, 0, 0.25, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
panel.BorderSizePixel = 0
panel.Parent = background

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = panel

-- title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.15, 0)
title.BackgroundTransparency = 1
title.Text = "🌐 Auto System Overlay"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(200,200,200)
title.Parent = panel

-- info section
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

-- show overlay after delay
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
    task.spawn(function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
        end
        workspace.DescendantAdded:Connect(function(v)
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
        end)
    end)
end

-- === QUEUE SCRIPT ===
local function queueScript()
    local SRC = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/xaxa.lua"))()
    ]]
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(SRC)
    elseif queue_on_teleport then
        queue_on_teleport(SRC)
    end
end

-- === SERVER HOP (Persistent, No Back-to-Back Rejoin) ===
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local DATA_FILE = "lastServerId.txt"
local lastServerId = nil

-- Try to load last server ID from file (persistent memory)
pcall(function()
	if isfile and isfile(DATA_FILE) then
		lastServerId = readfile(DATA_FILE)
	end
end)

-- Helper: fetch servers
local function getAvailableServers(minPlayers)
	local success, body = pcall(function()
		return game:HttpGet(
			("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
		)
	end)

	if not success then
		warn("[ServerHop] Failed to fetch servers.")
		return {}
	end

	local data = HttpService:JSONDecode(body)
	if not data or not data.data then return {} end

	local servers = {}
	for _, server in ipairs(data.data) do
		if server.id ~= game.JobId
			and server.id ~= lastServerId -- skip same server as last
			and server.playing >= (minPlayers or 2)
			and server.playing < server.maxPlayers then
			table.insert(servers, server)
		end
	end
	return servers
end

-- Main function
local function serverHop(reason)
	info.Text = "⏭ Server hopping...\nReason: " .. (reason or "rotation")

	sendWebhook(
		("User: %s (%s)\nReason: %s\nPlayers: %d\nJobId: %s")
			:format(player.Name, player.DisplayName, reason or "rotation", #Players:GetPlayers(), game.JobId),
		"🌐 Server Hop",
		3447003
	)

	queueScript()

	local attempt = 0
	while attempt < 6 do
		attempt += 1
		local servers = getAvailableServers(10)
		if #servers == 0 then
			warn("[ServerHop] No suitable servers found (attempt " .. attempt .. "). Retrying in 3s...")
			task.wait(3)
			continue
		end

		local target = servers[math.random(1, #servers)]
		print("[ServerHop] Attempting teleport to:", target.id)

		local success, err = pcall(function()
			-- Save last server before teleport
			lastServerId = game.JobId
			if writefile then
				writefile(DATA_FILE, game.JobId)
			end
			TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, player)
		end)

		if success then
			return
		else
			warn("[ServerHop] Teleport failed:", err)
			task.wait(2)
		end
	end

	-- Fallback
	warn("[ServerHop] All attempts failed, teleporting to new instance...")
	if writefile then
		writefile(DATA_FILE, game.JobId)
	end
	lastServerId = game.JobId
	TeleportService:Teleport(game.PlaceId, player)
end
-- === MOD DETECTION ===
local MOD_IDS = {
    419612796, 82591348, 540190518, 9125708679, 4992470579, 38701072,
    7423673502, 3724230698, 418307435, 943340328, 37343237, 2862215389,
    103578797, 1562079996, 2542703855, 210949, 337367059, 1159074474,
    9526977984, 9562355874, 8531293745, 9504701959, 9411319434, 9530045945,
	4992470579, 337367059
}

local function checkForMods(pl)
    for _, id in ipairs(MOD_IDS) do
        if pl.UserId == id then
            sendWebhook(
                "🚨 Mod detected: " .. pl.Name .. " ("..pl.UserId..")",
                "⚠️ Mod Alert",
                16711680 -- red
            )
            serverHop("Mod detected: " .. pl.Name)
            break
        end
    end
end

for _, pl in ipairs(Players:GetPlayers()) do checkForMods(pl) end
Players.PlayerAdded:Connect(checkForMods)


-- Spam detection parameters
local spamThreshold = 3 -- number of repeated messages
local spamTimeWindow = 10 -- seconds

local recentMessages = {} -- {message = {count, firstTimestamp}}

local function checkSpam(msg)
    local currentTime = os.time()
    if recentMessages[msg] then
        local data = recentMessages[msg]
        if currentTime - data.firstTimestamp <= spamTimeWindow then
            data.count = data.count + 1
            if data.count >= spamThreshold then
                -- Spam detected, trigger server hop
                warn("Spam detected: " .. msg)
                sendWebhook("Spam detected: " .. msg, "⚠️ Spam Alert", 16711680)
                serverHop("Spam detected in chat")
                -- Reset after hopping
                recentMessages = {}
                return true
            end
        else
            -- Reset count if outside time window
            recentMessages[msg] = {count = 1, firstTimestamp = currentTime}
        end
    else
        recentMessages[msg] = {count = 1, firstTimestamp = currentTime}
    end
    return false
end

-- Override or hook into your sendChat function to include spam check
local originalSendChat = sendChat
sendChat = function(msg)
    if checkSpam(msg) then
        -- Spam detected, do not send message
        return
    end
    originalSendChat(msg)
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

-- === AUTO TELEPORT LOOP ===
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
            sendWebhook("No players found. Rotating server...", "⚠️ Auto Rotation", 16776960) -- yellow
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
            task.wait(tpDelay + 3)
        end

        info.Text = "🔄 Finished all players. Hopping..."
        sendWebhook("Finished all players. Rotating server...", "🔄 Auto Rotation", 65280) -- green
        serverHop("Rotation after reaching players")
        task.wait(1)
    end
end)

