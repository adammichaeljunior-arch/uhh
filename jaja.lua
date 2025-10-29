local function isCharacterReady()
    local char = player.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return humanoid ~= nil and hrp ~= nil
end

local function followAndReach(targetPosition, timeout)
    -- Move towards position, follow if moving
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return false end
    
    local startTime = os.clock()
    humanoid.WalkSpeed = 40 -- faster speed
    
    while (hrp.Position - targetPosition).Magnitude > 3 do
        -- Move towards target
        humanoid:MoveTo(targetPosition)
        task.wait(0.5)
        -- Check timeout
        if os.clock() - startTime > timeout then
            humanoid.WalkSpeed = 16 -- reset speed
            return false -- timeout reached
        end
        -- Update target position if moving
        -- optional: add logic to follow moving target
    end

    humanoid.WalkSpeed = 16 -- reset to default
    return true
end

local function teleportTo(position)
    -- Teleport your character
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hrp and humanoid then
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    end
end

local function askPlayer(player)
    local questions = {
        "Wanna join a server with Nitro, Robux, and E-girls?",
        "Interested in a server with free Nitro and Robux?",
        "Join a server with E-girls and free Robux?",
        "Wanna join for Nitro, Robux, and cute egirls?",
        "Up for a server with free Robux and Nitro?"
    }
    local question = questions[math.random(1, #questions)]
    sendChat(question)

    local responseMsg = nil
    local responseReceived = false

    local connections = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        table.insert(connections, pl.Chatted:Connect(function(msg)
            if pl == player then
                responseMsg = msg
                responseReceived = true
            end
        end))
    end

    local timeout = 20
    local elapsed = 0
    while not responseReceived and elapsed < timeout do
        task.wait(1)
        elapsed = elapsed + 1
    end

    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end

    if responseMsg then
        if isResponseYes(responseMsg) then
            sendChat("join gg/slowly")
        else
            sendChat("Alright, maybe later!")
        end
    else
        sendChat("No response, moving on.")
    end
end

local function visitPlayer(pl)
    local targetPos = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and pl.Character.HumanoidRootPart.Position
    if not targetPos then return end

    local reached = false
    local success = false
    local startTime = os.clock()

    -- Try to follow and reach
    repeat
        if isCharacterReady() then
            success = followAndReach(targetPos, 20)
        end
        if success then break end

        -- if not reached within time, teleport
        if os.clock() - startTime > 20 then
            teleportTo(targetPos)
            success = true
            break
        end
        task.wait(0.5)
    until false

    -- Once reached, ask the player
    askPlayer(pl)
end

local function serverHop(reason)
    sendWebhook("Hopping server: " .. reason, false)
    -- Queue reinjection
    local SRC = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/adammichaeljunior-arch/uhh/main/jaja.lua"))()
    ]]
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(SRC)
    elseif queue_on_teleport then
        queue_on_teleport(SRC)
    end
    -- Teleport to another server
    game:GetService("TeleportService"):Teleport(game.PlaceId)
end

-- Main process
task.spawn(function()
    local visitedCount = 0
    local totalPlayers = #Players:GetPlayers()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= Players.LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
            visitPlayer(pl)
            visitedCount = visitedCount + 1
        end
    end
    -- After visiting all, hop server
    serverHop("Finished visiting all players")
end)
