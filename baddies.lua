-- Define a function to execute your initial script
local function runInitialScript()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/refs/heads/main/baddies.lua"))()
end

-- Run it immediately
coroutine.wrap(runInitialScript)()

-- Rest of your code continues here
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Queue this script and the external script on teleport
local function queueScript()
    local SRC = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/refs/heads/main/baddies.lua"))()
    ]]
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(SRC)
    elseif queue_on_teleport then
        queue_on_teleport(SRC)
    end
end

-- CPU Saver
if _G.CPUSaver then
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        RunService:Set3dRenderingEnabled(false)
        local Lighting = game:GetService("Lighting")
        Lighting.GlobalShadows = false
        Lighting.Brightness = 0
        Lighting.FogEnd = 9e9
        Lighting.Ambient = Color3.new(0,0,0)
        Lighting.OutdoorAmbient = Color3.new(0,0,0)
        for _, sound in pairs(workspace:GetDescendants()) do
            if sound:IsA("Sound") then
                sound.Volume = 0
                sound.Playing = false
            end
        end
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
    end)
end

local lastServerId = nil

-- Server hop after 5 minutes
delay(300, function()
    queueScript()
    local function getPublicServers()
        local servers = {}
        local cursor = ""
        repeat
            local success, result = pcall(function()
                return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor="..cursor or ""))
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
                warn("[ServerHop] Failed to fetch servers.")
                break
            end
            task.wait(0.5)
        until cursor == "" or #servers >= 400
        return servers
    end

    local servers = getPublicServers()
    if #servers == 0 then
        TeleportService:Teleport(game.PlaceId, player)
        return
    end

    local validServers = {}
    for _, server in ipairs(servers) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId and server.id ~= lastServerId then
            table.insert(validServers, server)
        end
    end

    if #validServers == 0 then
        TeleportService:Teleport(game.PlaceId, player)
        return
    end

    local target = validServers[math.random(1, #validServers)]
    lastServerId = target.id
    print("[ServerHop] Hop to server:", target.id)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, player)
end)

-- Auto-equip and activate tools with "mask" in their name
local function equipAndUseMask()
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    local character = player.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local backpack = player:WaitForChild("Backpack")
    task.wait(1)

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and string.find(string.lower(tool.Name), "mask") then
            humanoid:EquipTool(tool)
            print("Equipped mask tool:", tool.Name)
            -- Activate the tool (simulate click)
            if typeof(tool) == "Instance" and typeof(tool.Activate) == "function" then
                task.wait(0.1)
                pcall(function()
                    tool:Activate()
                end)
                print("Activated mask tool:", tool.Name)
            end
            break
        end
    end
end

player.CharacterAdded:Connect(equipAndUseMask)
if player.Character then
    equipAndUseMask()
end
