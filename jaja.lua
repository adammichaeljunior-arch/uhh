-- === SETTINGS ===
local WEBHOOK_URL = "https://discord.com/api/webhooks/xxxxxx/xxxxxx"

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
local overlayDelay = 3
local minPlayers = 10 -- ✅ won’t stay in servers smaller than this

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

-- === WEBHOOK SENDER ===
local function sendWebhook(content)
    if not content then return false end
    local payload = HttpService:JSONEncode({ content = tostring(content) })

    local requestBody = {
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = payload,
    }

    if syn and syn.request then return syn.request(requestBody) end
    if http_request then return http_request(requestBody) end
    if http and http.request then return http.request(requestBody) end
    if request then return request(requestBody) end
end

-- === CHAT HELPER ===
local function sendChat(msg)
    if not channel then return end
    pcall(function() channel:SendAsync(msg) end)
end

-- === MODERATION IDS ===
local MOD_IDS = {
    419612796, 82591348, 540190518, 9125708679, 4992470579,
    38701072, 7423673502, 3724230698, 418307435, 73344996,
    37343237, 2862215389, 103578797, 1562079996, 2542703855,
    210949, 337367059, 1159074474
}

local function checkForMods()
    for _, pl in ipairs(Players:GetPlayers()) do
        if table.find(MOD_IDS, pl.UserId) then
            sendWebhook("🚨 Mod detected: " .. pl.Name .. " ("..pl.UserId..")")
            return true
        end
    end
    return false
end

-- === QUEUE SCRIPT ===
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

-- === SERVER HOP ===
local function serverHop(reason)
    sendWebhook(("🌐 Hop\nUser: %s (%s)\nReason: %s\nPlayers: %d\nJobId: %s")
        :format(player.Name, player.DisplayName, reason or "rotation", #Players:GetPlayers(), game.JobId))

    queueScript()

    local success, body = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100")
    end)
    if success then
        local data = HttpService:JSONDecode(body)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing >= minPlayers and server.playing < server.maxPlayers and server.id ~= game.JobId then
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
    task.wait(4) -- ✅ delay before starting chat spam (mod check first)
    local i = 1
    while _G.AutoSay do
        if checkForMods() then
            serverHop("Mod detected")
            break
        end
        sendChat(messages[i])
        i = (i % #messages) + 1
        task.wait(chatDelay + math.random())
    end
end)

-- === AUTO TELEPORT LOOP (hover + follow) ===
task.spawn(function()
    while _G.AutoTP do
        if checkForMods() then
            serverHop("Mod detected")
            break
        end

        local allPlayers = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(allPlayers, pl)
            end
        end

        if #allPlayers < minPlayers then
            serverHop("Empty/small server")
            return
        end

        for _, target in ipairs(allPlayers) do
            if checkForMods() then
                serverHop("Mod detected")
                break
            end

            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and hrp then
                local followTime = tick()
                while tick() - followTime < 4 do -- ✅ hover + follow for 4s
                    if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then break end
                    hrp.CFrame = CFrame.new(
                        target.Character.HumanoidRootPart.Position + Vector3.new(0, 5, 0), -- hover above
                        target.Character.HumanoidRootPart.Position
                    )
                    task.wait(0.1)
                end
            end

            if _G.AutoEmote then
                task.spawn(function()
                    for _ = 1, math.floor(tpDelay/0.5) do
                        sendChat("/e point")
                        task.wait(0.5)
                    end
                end)
            end

            task.wait(1) -- small buffer before next target
        end

        serverHop("Rotation done")
        task.wait(1)
    end
end)
