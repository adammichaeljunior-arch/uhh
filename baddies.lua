--loadstring(game:HttpGet("https://raw.githubusercontent.com/mafuasahina/whatever/main/baddies"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Backpack = LocalPlayer:WaitForChild("Backpack")

local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")

Net:FindFirstChild("RF/EquipWeaponSkin"):InvokeServer("Pan")
Net:FindFirstChild("RF/EquipWeaponSkin"):InvokeServer("BeachShovel")

local hitRemotes = {
	Net:WaitForChild("RE/BeachShovelHit"),
	Net:WaitForChild("RE/panHit"),
	Net:WaitForChild("RE/pinkStopSignalHit"),
	Net:WaitForChild("RE/baseballBatHit"),
}

local stompEvent = ReplicatedStorage:WaitForChild("STOMPEVENT")

local function buyTool(toolName, buttonName)
	if Backpack:FindFirstChild(toolName) or Character:FindFirstChild(toolName) then return end

	local button = workspace:FindFirstChild(buttonName, true)
	local prompt = button and button:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt then return end

	Character:PivotTo(button.CFrame + Vector3.new(0, 2, 0))

	while not (Backpack:FindFirstChild(toolName) or Character:FindFirstChild(toolName)) do
		fireproximityprompt(prompt)
		task.wait()
	end
end

buyTool("Pan", "Pan Buy button")
buyTool("BeachShovel", "botonComprarShovel")

local slayTarget = nil
local isSlaying = false

local function fireHits()
	for _, remote in ipairs(hitRemotes) do
		pcall(function()
			remote:FireServer(1)
		end)
	end
end

local function fireSlay()
	pcall(function()
		stompEvent:FireServer()
	end)
end

local function teleportUnderLowestHealthPlayer(localRoot)
	local lowestHealthPlayer = nil
	local lowestHealth = 1e9

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			if not char then continue end

			local humanoid = char:FindFirstChild("Humanoid")
			local root = char:FindFirstChild("HumanoidRootPart")
			local pvp = char:FindFirstChild("hasPvpOn")
			local stompable = char:FindFirstChild("canBeStomped")
			local carried = char:FindFirstChild("BeingCarried")

			if humanoid and root and pvp and humanoid.Health > 1 and (not stompable or not carried) then
				if humanoid.Health < lowestHealth then
					lowestHealth = humanoid.Health
					lowestHealthPlayer = player
				end
			end
		end
	end

	if lowestHealthPlayer and lowestHealthPlayer.Character then
		local targetRoot = lowestHealthPlayer.Character:FindFirstChild("HumanoidRootPart")
		if targetRoot and localRoot then
			localRoot.AssemblyLinearVelocity = Vector3.zero
			localRoot.AssemblyAngularVelocity = Vector3.zero
			localRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, -8, 0))
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local root = player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				root.CanCollide = false
				root.Size = Vector3.new(20, 20, 20)
			end
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	if player == slayTarget then
		slayTarget = nil
		isSlaying = false
	end
end)

RunService.Heartbeat:Connect(function()
	if slayTarget and slayTarget.Character then
		local char = slayTarget.Character
		local humanoid = char:FindFirstChild("Humanoid")
		local stompable = char:FindFirstChild("canBeStomped")
		local carried = char:FindFirstChild("BeingCarried")
		local pvp = char:FindFirstChild("hasPvpOn")

		if humanoid and (not stompable or humanoid.Health < 1 or humanoid.Health > 5 or carried or not pvp) then
			slayTarget = nil
			isSlaying = false
		end
	end

	if not slayTarget then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local char = player.Character
				if not char then continue end

				local humanoid = char:FindFirstChild("Humanoid")
				local root = char:FindFirstChild("HumanoidRootPart")
				local stompable = char:FindFirstChild("canBeStomped")
				local carried = char:FindFirstChild("BeingCarried")
				local pvp = char:FindFirstChild("hasPvpOn")

				if humanoid and stompable and humanoid.Health >= 1 and humanoid.Health <= 5 and not carried and pvp then
					slayTarget = player
					isSlaying = true
					break
				end
			end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if isSlaying and slayTarget and slayTarget.Character then
		local targetChar = slayTarget.Character
		local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
		local tHead = targetChar:FindFirstChild("Head")

		if tRoot then
			root.CFrame = CFrame.new(((math.random(1, 2) == 1 and tRoot or tHead).Position) + Vector3.new(0, 4, 0))
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			fireSlay()
		end
	else
		fireHits()
		teleportUnderLowestHealthPlayer(root)
	end
end)

RunService.RenderStepped:Connect(function()
	Net:FindFirstChild("RF/SalonPunch"):InvokeServer()
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
	if humanoid and humanoid.Health < 70 then
		Net:FindFirstChild("RF/RequestSurgery"):InvokeServer()
	end
end)


-----------------------------------------------------------------
-- === AUTO EQUIP + USE ANY TOOL WITH "MASK" IN ITS NAME ===
-----------------------------------------------------------------
task.spawn(function()
	while task.wait(0.5) do
		pcall(function()
			local char = LocalPlayer.Character
			local backpack = LocalPlayer.Backpack
			if not char then return end

			local mask = nil

			for _, t in ipairs(backpack:GetChildren()) do
				if t:IsA("Tool") and t.Name:lower():find("mask") then
					mask = t
					break
				end
			end

			if not mask then
				for _, t in ipairs(char:GetChildren()) do
					if t:IsA("Tool") and t.Name:lower():find("mask") then
						mask = t
						break
					end
				end
			end

			if mask and backpack:FindFirstChild(mask.Name) then
				char.Humanoid:EquipTool(mask)
			end

			if mask and mask:FindFirstChild("Activator") then
				pcall(function()
					firesignal(mask.Activator.MouseButton1Click)
				end)
			end

			if mask then
				pcall(function()
					mask:Activate()
				end)
			end
		end)
	end
end)


-----------------------------------------------------------------
-- === QUEUE SCRIPT ON TELEPORT ===
-----------------------------------------------------------------
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

queueScript()


-----------------------------------------------------------------
-- === AUTO SERVERHOP EVERY 3 MINUTES ===
-----------------------------------------------------------------
task.spawn(function()
	while task.wait(180) do
		pcall(function()
			local TeleportService = game:GetService("TeleportService")
			local HttpService = game:GetService("HttpService")

			queueScript()

			local servers = HttpService:JSONDecode(
				game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
			)

			for _, s in ipairs(servers.data) do
				if s.id ~= game.JobId and s.playing < s.maxPlayers then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
					break
				end
			end
		end)
	end
end)
