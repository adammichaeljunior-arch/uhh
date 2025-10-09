-- Settings
local messages = {
    "hop in /LOLZ for ekittens",
    "bored?? /LOLZ and chat",
    "/LOLZ  4 nitro",
    "/LOLZ 4 headless",
    "BEEF IN /LOLZ",
    " /LOLZ 4 robuxx",
    "goon in  /LOLZ",
    "/LOLZ for fun",
    " /LOLZ for friends"
}
local fpsCap = 5

-- Cap FPS
if setfpscap then
    setfpscap(fpsCap)
end

-- Save CPU (Extreme GPU saver)
if _G.CPUSaver ~= false then
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
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

-- === QUEUE SCRIPT ===
local function queueScript()
    local SRC = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/qaqa.lua"))()
    ]]
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(SRC)
    elseif queue_on_teleport then
        queue_on_teleport(SRC)
    end
end


-- Send chat message
local function sendChat(msg)
    local success, err = pcall(function()
        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService:WaitForChild("RBXGeneral", 5)
        channel:SendAsync(msg)
    end)
end

-- Get other players
local function getOtherPlayers()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(t, p)
        end
    end
    return t
end

-- Load your custom script
loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/qaqa.lua"))()

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
            -- No players, hop server
            queueOnTeleport()
            TeleportService:Teleport(game.PlaceId)
            return
        end

        for _, p in ipairs(targets) do
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            local hrpPlayer = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hrpPlayer then
                hrpPlayer.CFrame = getFrontCFrame(hrp)
            end

            -- Spam message
            sendChat(messages[math.random(#messages)])
            -- Spam emote
            sendChat("/e point")
            wait(2)
        end

        -- After visiting all players, hop server
        queueOnTeleport()
        TeleportService:Teleport(game.PlaceId)
        return
    end
end

-- Run the main cycle
coroutine.wrap(main)()
