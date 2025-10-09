-- Robust server-hopper + reattach bootstrap
-- Supports syn.queue_on_teleport, generic queue_on_teleport, fluxus, and a writefile/readfile fallback.

-- ============ CONFIG ============
local messages = {
    "hop in /LOLZ for ekittens",
    "bored?? /LOLZ and chat",
    "/LOLZ  4 nitro",
    "/LOLZ 4 headless",
    "BEEF IN /LOLZ",
    "/LOLZ 4 robuxx",
    "goon in  /LOLZ",
    "/LOLZ for fun",
    " /LOLZ for friends"
}
local fpsCap = 5
local loader_url = "https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/qaqa.lua"
-- ================================

-- Cap FPS (if executor provides)
if setfpscap then
    pcall(function() setfpscap(fpsCap) end)
end

-- Extreme GPU saver (optional)
if _G.CPUSaver ~= false then
    pcall(function()
        if settings and settings().Rendering then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end
        game:GetService("RunService"):Set3dRenderingEnabled(false)
        local Lighting = game:GetService("Lighting")
        Lighting.GlobalShadows = false
        Lighting.Brightness = 0
        Lighting.FogEnd = 9e9
        Lighting.Ambient = Color3.new(0,0,0)
        Lighting.OutdoorAmbient = Color3.new(0,0,0)
    end)
end

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
if not player then
    Players.PlayerAdded:Wait()
    player = Players.LocalPlayer
end

-- Robust queue-on-teleport helper:
-- It will try multiple common executor APIs. It queues code which will run on the next server.
local function queue_on_teleport_robust(code)
    -- code must be a string of Lua code that can run on the next server.
    local succeeded = false
    local success, err

    -- synapse vX
    if type(syn) == "table" and syn.queue_on_teleport then
        success, err = pcall(function() syn.queue_on_teleport(code) end)
        succeeded = success or succeeded
    end

    -- generic global queue_on_teleport (some executors expose this global)
    if not succeeded and type(queue_on_teleport) == "function" then
        success, err = pcall(function() queue_on_teleport(code) end)
        succeeded = success or succeeded
    end

    -- fluxus style
    if not succeeded and type(fluxus) == "table" and fluxus.queue_on_teleport then
        success, err = pcall(function() fluxus.queue_on_teleport(code) end)
        succeeded = success or succeeded
    end

    -- fallback: write the payload to disk (if available) and queue a small loader that reads file on next boot
    if not succeeded and type(writefile) == "function" and type(isfile) == "function" and type(readfile) == "function" then
        pcall(function()
            writefile("qaqa_bootstrap.lua", code)
        end)
        local disk_loader = "if isfile('qaqa_bootstrap.lua') then pcall(function() loadstring(readfile('qaqa_bootstrap.lua'))() end) end"
        if type(syn) == "table" and syn.queue_on_teleport then
            pcall(function() syn.queue_on_teleport(disk_loader) end)
            succeeded = true
        elseif type(queue_on_teleport) == "function" then
            pcall(function() queue_on_teleport(disk_loader) end)
            succeeded = true
        end
    end

    return succeeded
end

-- Prepare the loader payload string (safe-quoted)
local loader_payload = "pcall(function() loadstring(game:HttpGet(\"" .. loader_url .. "\"))() end)"

-- Robust send chat (TextChatService first, fallback to legacy chat event)
local function sendChat(msg)
    local ok, err = pcall(function()
        local TextChatService = game:GetService("TextChatService")
        if TextChatService then
            local success, channel = pcall(function()
                return TextChatService:WaitForChild("RBXGeneral", 3)
            end)
            if success and channel and channel.SendAsync then
                channel:SendAsync(msg)
                return
            end
        end

        -- fallback: DefaultChatSystemChatEvents
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local DefaultChat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if DefaultChat and DefaultChat:FindFirstChild("SayMessageRequest") then
            DefaultChat.SayMessageRequest:FireServer(msg, "All")
            return
        end

        -- last resort: try Chat service (may not be available in all games)
        local ChatService = game:GetService("Chat")
        if ChatService and ChatService.Chat then
            -- This is a Hail-Mary — not guaranteed to work in all games
            pcall(function() ChatService:Chat(player.Character and player.Character:FindFirstChild("Head") or player.Character, msg, Enum.ChatColor.Red) end)
            return
        end
    end)
    if not ok then
        warn("sendChat failed:", err)
    end
end

-- Get other players with HRP
local function getOtherPlayers()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(t, p)
        end
    end
    return t
end

-- Load your custom script immediately (bootstrap)
pcall(function()
    loadstring(game:HttpGet(loader_url))()
end)

-- Helper: get position directly in front of target facing them
local function getFrontCFrame(targetHRP)
    local offset = targetHRP.CFrame.LookVector * 3 -- 3 studs in front
    local position = targetHRP.CFrame.Position + offset
    return CFrame.new(position, targetHRP.CFrame.Position)
end

-- Main cycle
local function main()
    while true do
        local targets = getOtherPlayers()
        if #targets == 0 then
            -- No players, queue loader and hop server
            local ok = queue_on_teleport_robust(loader_payload)
            if not ok then
                warn("queue_on_teleport failed: your executor may not support queueing. If possible use Synapse/Krnl/Fluxus or ensure writefile/readfile exist.")
            end
            wait(0.12) -- small buffer to allow queue to register
            pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
            return
        end

        for _, p in ipairs(targets) do
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            local hrpPlayer = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hrpPlayer then
                -- safe pcall in case changing CFrame is blocked by the server or anti-cheat
                pcall(function()
                    hrpPlayer.CFrame = getFrontCFrame(hrp)
                end)
            end

            -- Spam message & emote (be careful: spamming may trigger moderation/anti-cheat)
            sendChat(messages[math.random(#messages)])
            sendChat("/e point")
            wait(3)
        end

        -- After visiting all players, queue and hop server
        local ok = queue_on_teleport_robust(loader_payload)
        if not ok then
            warn("queue_on_teleport failed before final teleport.")
        end
        wait(0.12)
        pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
        return
    end
end

-- Run the main cycle
coroutine.wrap(main)()
