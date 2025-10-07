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
local chatDelay = 3.5
local tpDelay = 5
local overlayDelay = 1
local minPlayers = 8 -- minimum players in a server

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
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

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

-- === EXPLOIT-SPECIFIC WHISPER FUNCTION ===
local function SendWhisper(targetPlayer, message)
    if syn and syn.send_message then
        syn.send_message(targetPlayer.UserId, message) -- Synapse X API
    else
        warn("Whisper function not supported in this executor")
    end
end

-- === TRACK PLAYERS ALREADY MESSAGED ===
local messagedPlayers = {}
local visitedServers = {}

-- === GET SERVER LIST FUNCTION ===
local function GetServerList(placeId, minPlayers, maxPages)
    maxPages = maxPages or 5
    local servers = {}
    local cursor
    for i = 1, maxPages do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100%s"):format(placeId, cursor and "&cursor="..cursor or "")
        local success, response = pcall(function()
            return HttpService:GetAsync(url)
        end)
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

-- === CHECK IF PLAYER IS TYPING A MESSAGE ===
local function IsTypingSameMessage(pl)
    if pl:FindFirstChild("PlayerGui") and pl.PlayerGui:FindFirstChild("Chat") then
        local chatBar = pl.PlayerGui.Chat.Frame.ChatBarParentFrame.Frame.BoxFrame.Frame.TextBox
        if chatBar.Text ~= "" then
            for _, msg in ipairs(messages) do
                if chatBar.Text:lower():find(msg:lower()) then
                    return true
                end
            end
        end
    end
    return false
end

-- === AUTO TELEPORT + EMOTE + WHISPER LOOP ===
task.spawn(function()
    task.wait(3)
    while _G.AutoTP do
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
                servers = GetServerList(game.PlaceId, 1) -- fallback
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
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local targetHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                if hrp and targetHRP then
                    info.Text = string.format("🎯 Approaching: %s\n👤 You: %s", target.DisplayName or target.Name, player.DisplayName)

                    -- Move close
                    hrp.CFrame = CFrame.new(targetHRP.Position + targetHRP.CFrame.LookVector * 3, targetHRP.Position)
                    task.wait(0.8)

                    -- Placeholder for emote
                    if _G.AutoEmote then
                        info.Text = "🤖 Emote simulated..."
                        task.wait(0.5)
                    end

                    -- Whisper each message
                    for _, msg in ipairs(messages) do
                        pcall(function()
                            SendWhisper(target, msg)
                        end)
                        task.wait(0.3)
                    end

                    -- Mark as messaged
                    messagedPlayers[target.UserId] = true

                    task.wait(tpDelay)
                end
            end
        end
    end
end)
