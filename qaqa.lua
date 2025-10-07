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
local overlayDelay = 1 -- seconds before showing overlay

-- === TOGGLES ===
_G.AutoSay = false
_G.AutoTP = true
_G.AutoEmote = true
_G.CPUSaver = true

-- === SERVICES ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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

-- === AUTO CHAT LOOP ===
task.spawn(function()
    task.wait(3)
    local i = 1
    while _G.AutoSay do
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player then
                local msg = messages[i]
                pl:SendChatMessage(msg) -- whisper to each player
            end
        end
        i = (i % #messages) + 1
        task.wait(chatDelay)
    end
end)

-- === AUTO TELEPORT + EMOTE + MESSAGE ===
task.spawn(function()
    task.wait(3)
    while _G.AutoTP do
        local allPlayers = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(allPlayers, pl)
            end
        end

        if #allPlayers < 1 then
            info.Text = "⚠️ No players found. Waiting..."
            task.wait(tpDelay)
            continue
        end

        for _, target in ipairs(allPlayers) do
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp and targetHRP then
                info.Text = string.format("🎯 Approaching: %s\n👤 You: %s", target.DisplayName or target.Name, player.DisplayName)

                -- Move close
                hrp.CFrame = CFrame.new(targetHRP.Position + targetHRP.CFrame.LookVector * 3, targetHRP.Position)
                task.wait(0.8)

                -- Emote
                if _G.AutoEmote then
                    pcall(function()
                        game:GetService("Players").LocalPlayer:LoadCharacter() -- optional simple emote simulation
                    end)
                    task.wait(0.5)
                end

                -- Whisper using messages list
                for _, msg in ipairs(messages) do
                    pcall(function()
                        target:SendChatMessage(msg)
                    end)
                    task.wait(0.5)
                end

                task.wait(tpDelay)
            end
        end
        info.Text = "🔄 Finished all players. Looping..."
        task.wait(1)
    end
end)
