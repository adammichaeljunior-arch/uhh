-- === CHAT LOGGER UI ===
local chatGui = Instance.new("ScreenGui")
chatGui.Name = "ChatLogger"
chatGui.IgnoreGuiInset = true
chatGui.ResetOnSpawn = false
chatGui.Parent = player:WaitForChild("PlayerGui")

local chatFrame = Instance.new("Frame")
chatFrame.Size = UDim2.new(0.3, 0, 0.6, 0)
chatFrame.Position = UDim2.new(0.02, 0, 0.2, 0)
chatFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
chatFrame.BorderSizePixel = 0
chatFrame.Parent = chatGui

local chatList = Instance.new("UIListLayout")
chatList.Parent = chatFrame
chatList.Padding = UDim.new(0, 4)
chatList.FillDirection = Enum.FillDirection.Vertical
chatList.SortOrder = Enum.SortOrder.LayoutOrder

-- Function to add a chat message
local function addChatMessage(plr, message)
    if plr == player then return end -- skip your own messages

    local msgFrame = Instance.new("Frame")
    msgFrame.Size = UDim2.new(1, 0, 0, 50)
    msgFrame.BackgroundTransparency = 1
    msgFrame.Parent = chatFrame

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(0, 40, 0, 40)
    img.Position = UDim2.new(0, 5, 0, 5)
    img.BackgroundTransparency = 1
    img.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..plr.UserId.."&width=48&height=48&format=png"
    img.Parent = msgFrame

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -55, 1, 0)
    txt.Position = UDim2.new(0, 55, 0, 0)
    txt.BackgroundTransparency = 1
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextYAlignment = Enum.TextYAlignment.Center
    txt.Font = Enum.Font.SourceSansBold
    txt.TextSize = 18
    txt.TextColor3 = Color3.fromRGB(220,220,220)
    txt.Text = plr.Name..": "..message
    txt.Parent = msgFrame
end

-- Hook chat system
TextChatService.OnIncomingMessage = function(msg)
    local plr = Players:GetPlayerByUserId(msg.TextSource and msg.TextSource.UserId or 0)
    if plr and plr ~= player then
        addChatMessage(plr, msg.Text)
    end
end
