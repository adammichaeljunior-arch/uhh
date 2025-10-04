-- === SAFE TELEPORT FAILURE HANDLER ===
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- UI helper to show a simple error popup
local function showTeleportError(msg)
    if not LocalPlayer or not LocalPlayer:FindFirstChild("PlayerGui") then return end
    local gui = LocalPlayer.PlayerGui:FindFirstChild("TeleportErrorPopup")
    if gui then gui:Destroy() end

    gui = Instance.new("ScreenGui")
    gui.Name = "TeleportErrorPopup"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer.PlayerGui

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0.4, 0, 0.12, 0)
    frame.Position = UDim2.new(0.3, 0, 0.44, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BorderSizePixel = 0
    frame.ZIndex = 10

    local txt = Instance.new("TextLabel", frame)
    txt.Size = UDim2.new(1,0,1,0)
    txt.BackgroundTransparency = 1
    txt.TextColor3 = Color3.fromRGB(255,200,0)
    txt.Font = Enum.Font.GothamBold
    txt.TextScaled = true
    txt.Text = "Teleport failed: " .. tostring(msg or "Unknown") .. "\nAuto-hop paused."
end

-- Teleport retry control
local teleportRetries = 0
local MAX_TELEPORT_RETRIES = 3
local TELEPORT_RETRY_DELAY = 2 -- seconds

-- Flag to control auto-hop behavior safely
_G.AllowAutoHop = true

-- Safe serverHop: use random Teleport (Roblox-chosen server). Do NOT attempt instance IDs.
local function safeServerHop(reason)
    if not _G.AllowAutoHop then
        warn("Auto-hop disabled; not attempting server hop.")
        return
    end

    -- Optional: update an overlay label if you have one
    pcall(function()
        if overlayLabel then overlayLabel.Text = "🔄 Attempting random server hop... (" .. tostring(reason or "rotation") .. ")" end
    end)

    -- Request a random server from Roblox (no instance id used)
    -- This does not enumerate or bypass restrictions — it's the standard allowed API.
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- Robust handler for teleport failures
TeleportService.TeleportInitFailed:Connect(function(playerArg, teleportResult, errorMessage)
    -- Log locally
    warn("Teleport failed:", teleportResult, errorMessage)

    -- Show the user an explanatory popup and disable autos
    showTeleportError(errorMessage)
    teleportRetries = teleportRetries + 1

    -- If we haven't exceeded retries, try a single random teleport after a short delay.
    if teleportRetries <= MAX_TELEPORT_RETRIES and _G.AllowAutoHop then
        task.delay(TELEPORT_RETRY_DELAY, function()
            -- try one random teleport (Roblox picks server)
            safeServerHop("retry after failure")
        end)
    else
        -- Too many failures: stop auto-hop and leave user in control
        _G.AllowAutoHop = false
        warn("Max teleport retries reached — auto-hopping disabled.")
    end
end)

-- OPTIONAL: when a successful teleport completes you may want to reset retry counter
TeleportService.TeleportComplete:Connect(function(playerArg)
    teleportRetries = 0
    -- If desired, re-enable auto-hop only if you explicitly want that behavior:
    -- _G.AllowAutoHop = true
end)
