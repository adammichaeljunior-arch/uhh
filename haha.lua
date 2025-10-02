-- === Overlay UI ===
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Create ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "TeleportOverlay"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- Create black frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.3, 0, 0.1, 0)
frame.Position = UDim2.new(0.35, 0, 0.9, 0)
frame.BackgroundColor3 = Color3.new(0,0,0)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Parent = gui

-- Create text label
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1,0,1,0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1,1,1)
label.TextScaled = true
label.Font = Enum.Font.SourceSansBold
label.Text = "Players left: 0"
label.Parent = frame

-- === Teleport loop with overlay update ===
task.spawn(function()
    while true do
        local allPlayers = Players:GetPlayers()
        local toTeleport = {}

        for _, pl in ipairs(allPlayers) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(toTeleport, pl)
            end
        end

        for i = 1, #toTeleport do
            local target = toTeleport[i]
            -- teleport in front of target
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local targetHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if hrp and targetHRP then
                hrp.CFrame = CFrame.new(targetHRP.Position + targetHRP.CFrame.LookVector*3, targetHRP.Position)
            end

            -- update overlay countdown
            label.Text = "Players left: "..(#toTeleport - i)
            task.wait(6) -- wait time per player
        end

        -- After teleporting to all
        label.Text = "Server hopping..."
        task.wait(2) -- short delay before hop

        -- server hop logic (replace with your existing server hop function)
        if syn and syn.queue_on_teleport then
            syn.queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/haha.lua'))()")
        end
        game:GetService("TeleportService"):Teleport(game.PlaceId, player)
        break
    end
end)
