-- // SETTINGS
local WEBHOOK = "https://discord.com/api/webhooks/1423446494152884295/rip25iG9fUAoY63CE5uYRqpKNeNz5HJoS0jTH0X4CRpXkS2hJqBk6xn8KLq1yNu_BHxI"
local STAFF_GROUP_ID = 12940498
local KNOWN_MODS = {
    419612796, 82591348, 540190518, 9125708679, 4992470579, 38701072,
    7423673502, 3724230698, 418307435, 73344996, 37343237, 2862215389,
    103578797, 1562079996, 2542703855, 210949, 337367059, 1159074474
}
local MESSAGES = {
    "join /envyy for fansignss",
    "join /envyy 4 nitro",
    "/envyy 4 headless",
    "goon in /envyy",
    "join /envyy 4 eheadd",
    "join /envyy for friends"
}
local MIN_PLAYERS = 10 -- ✅ only join servers with this many players or more
local START_DELAY = 4 -- ✅ delay after join before checks start

-- // SERVICES
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- // UI OVERLAY
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(1,0,1,0)
Frame.BackgroundColor3 = Color3.fromRGB(0,0,0)

local Info = Instance.new("TextLabel", Frame)
Info.Size = UDim2.new(1,0,0,100)
Info.BackgroundTransparency = 1
Info.TextColor3 = Color3.fromRGB(200,200,200)
Info.TextScaled = true
Info.Font = Enum.Font.GothamBold
Info.Text = "🔄 Connecting..."

-- status bar
local StatusBar = Instance.new("Frame", Frame)
StatusBar.Size = UDim2.new(1,0,0,5)
StatusBar.Position = UDim2.new(0,0,1,-5)
StatusBar.BackgroundColor3 = Color3.fromRGB(50,50,50)

local Bar = Instance.new("Frame", StatusBar)
Bar.Size = UDim2.new(0,0,1,0)
Bar.BackgroundColor3 = Color3.fromRGB(0,200,0)

-- animate bar randomly
task.spawn(function()
    while task.wait(0.5) do
        Bar:TweenSize(UDim2.new(math.random(),0,1,0),"Out","Quad",0.5,true)
    end
end)

-- // WEBHOOK LOGGER
local function sendWebhook(msg)
    local data = {
        ["embeds"] = {{
            ["title"] = "📡 Server Hopper Status",
            ["description"] = msg,
            ["type"] = "rich",
            ["color"] = tonumber(0x00ffcc),
            ["footer"] = {["text"] = "Auto System | " .. os.date("%X")}
        }}
    }
    pcall(function()
        request({
            Url = WEBHOOK,
            Body = HttpService:JSONEncode(data),
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"}
        })
    end)
end

-- // STAFF CHECK
local function isStaff(player)
    if table.find(KNOWN_MODS, player.UserId) then return true end
    local ok, inGroup = pcall(function()
        return player:IsInGroup(STAFF_GROUP_ID)
    end)
    return ok and inGroup
end

local function checkForMods()
    for _,p in pairs(Players:GetPlayers()) do
        if isStaff(p) then
            return true, p
        end
    end
    return false
end

-- // SERVER HOP
local function serverHop(reason)
    Info.Text = "🌍 Hopping to another server...\nReason: " .. (reason or "rotation")
    sendWebhook("🌍 Switching server. Reason: "..(reason or "rotation"))

    local servers = {}
    local cursor
    repeat
        local response = game:HttpGet(string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100%s",
            game.PlaceId, cursor and "&cursor="..cursor or ""
        ))
        local data = HttpService:JSONDecode(response)
        for _,srv in ipairs(data.data) do
            -- ✅ only add servers above MIN_PLAYERS and not full
            if srv.playing >= MIN_PLAYERS and srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                table.insert(servers, srv)
            end
        end
        cursor = data.nextPageCursor
    until not cursor

    table.sort(servers, function(a,b) return a.playing > b.playing end)

    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[1].id, LocalPlayer)
    else
        Info.Text = "❌ No valid servers found."
        sendWebhook("❌ No valid servers found to hop.")
    end
end

-- // SPAM FUNCTION
local function startSpamming()
    task.spawn(function()
        while task.wait(3) do
            -- staff check before every message
            local hasMod,modPlayer = checkForMods()
            if hasMod then
                Info.Text = "⚠️ Staff detected: " .. modPlayer.Name
                sendWebhook("⚠️ Staff detected ("..modPlayer.Name..") — hopping...")
                serverHop("Staff detected")
                break
            end

            -- empty server failsafe
            if #Players:GetPlayers() < MIN_PLAYERS then
                Info.Text = "⚠️ Too few players, hopping..."
                sendWebhook("⚠️ Server has less than "..MIN_PLAYERS.." players — hopping...")
                serverHop("Empty/Small server")
                break
            end

            -- send message
            local msg = MESSAGES[math.random(1,#MESSAGES)]
            Info.Text = "💬 Sending: " .. msg
            pcall(function()
                game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
            end)
        end
    end)
end

-- // QUEUE SAFE LOAD
local function queueScript()
    local SRC = [[
        task.spawn(function()
            repeat task.wait() until game:IsLoaded()
            local Players = game:GetService("Players")
            repeat task.wait() until Players.LocalPlayer
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/haha.lua"))()
            end)
        end)
    ]]
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(SRC)
    elseif queue_on_teleport then
        queue_on_teleport(SRC)
    end
end

-- // STARTUP
queueScript()
task.wait(START_DELAY) -- ✅ delay after join

local hasMod,modPlayer = checkForMods()
if hasMod then
    Info.Text = "⚠️ Staff in server ("..modPlayer.Name..")"
    sendWebhook("⚠️ Staff in server ("..modPlayer.Name..") — hopping...")
    serverHop("Staff in server")
elseif #Players:GetPlayers() < MIN_PLAYERS then
    Info.Text = "⚠️ Too few players in server."
    sendWebhook("⚠️ Too few players (<"..MIN_PLAYERS..") — hopping...")
    serverHop("Empty/Small server")
else
    Info.Text = "✅ Safe. Starting spam..."
    sendWebhook("✅ No staff detected. Safe to start spam.")
    startSpamming()
end
