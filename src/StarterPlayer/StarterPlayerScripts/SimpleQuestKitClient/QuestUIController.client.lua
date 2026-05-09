local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DemoConfig = require(ReplicatedStorage:WaitForChild("SimpleQuestKit"):WaitForChild("Config"):WaitForChild("DemoConfig"))
local Debug = DemoConfig.Debug == true

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local QuestUI = {
    _data = nil,
    _onClaim = nil,
    _screenGui = nil,
    _panel = nil,
    _list = nil,
    _isOpen = false,
}

local COLORS = {
    Ink = Color3.fromRGB(26, 31, 36),
    Muted = Color3.fromRGB(92, 101, 110),
    Paper = Color3.fromRGB(250, 247, 239),
    Panel = Color3.fromRGB(255, 252, 244),
    Green = Color3.fromRGB(49, 143, 102),
    Gold = Color3.fromRGB(221, 166, 66),
    Blue = Color3.fromRGB(76, 132, 196),
    Stroke = Color3.fromRGB(217, 209, 191),
}

local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

local function addStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
end

local function makeLabel(parent, text, size, color, bold)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = color or COLORS.Ink
    label.TextSize = size
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Parent = parent
    return label
end

local function formatRewards(rewards)
    local parts = {}

    for rewardName, amount in pairs(rewards or {}) do
        table.insert(parts, tostring(amount) .. " " .. tostring(rewardName))
    end

    table.sort(parts)
    return table.concat(parts, ", ")
end

local function clearList(list)
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
end

function QuestUI:_build()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SimpleQuestKitUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = false
    screenGui.Parent = playerGui

    local openButton = Instance.new("TextButton")
    openButton.Name = "QuestButton"
    openButton.AnchorPoint = Vector2.new(1, 0)
    openButton.BackgroundColor3 = COLORS.Green
    openButton.Position = UDim2.fromScale(0.97, 0.08)
    openButton.Size = UDim2.fromOffset(132, 44)
    openButton.Font = Enum.Font.GothamBold
    openButton.Text = "Quests"
    openButton.TextColor3 = Color3.new(1, 1, 1)
    openButton.TextSize = 17
    openButton.Parent = screenGui
    addCorner(openButton, 8)

    local panel = Instance.new("Frame")
    panel.Name = "QuestPanel"
    panel.AnchorPoint = Vector2.new(1, 0.5)
    panel.BackgroundColor3 = COLORS.Panel
    panel.Position = UDim2.fromScale(1.42, 0.5)
    panel.Size = UDim2.new(0, 390, 0.82, 0)
    panel.Parent = screenGui
    addCorner(panel, 8)
    addStroke(panel, COLORS.Stroke, 1)

    local maxSize = Instance.new("UISizeConstraint")
    maxSize.MaxSize = Vector2.new(430, 680)
    maxSize.MinSize = Vector2.new(300, 360)
    maxSize.Parent = panel

    local header = Instance.new("Frame")
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, -28, 0, 58)
    header.Position = UDim2.fromOffset(14, 12)
    header.Parent = panel

    local title = makeLabel(header, "Quest Board", 22, COLORS.Ink, true)
    title.Size = UDim2.new(1, -46, 0, 28)

    local subtitle = makeLabel(header, "Complete quests and claim rewards.", 13, COLORS.Muted, false)
    subtitle.Position = UDim2.fromOffset(0, 31)
    subtitle.Size = UDim2.new(1, -46, 0, 20)

    local closeButton = Instance.new("TextButton")
    closeButton.AnchorPoint = Vector2.new(1, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(238, 232, 218)
    closeButton.Position = UDim2.new(1, 0, 0, 2)
    closeButton.Size = UDim2.fromOffset(36, 36)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "X"
    closeButton.TextColor3 = COLORS.Ink
    closeButton.TextSize = 16
    closeButton.Parent = header
    addCorner(closeButton, 8)

    local list = Instance.new("ScrollingFrame")
    list.Name = "QuestList"
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.CanvasSize = UDim2.fromOffset(0, 0)
    list.Position = UDim2.fromOffset(14, 80)
    list.ScrollBarThickness = 5
    list.Size = UDim2.new(1, -28, 1, -94)
    list.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 12)
    end)

    openButton.Activated:Connect(function()
        self:Toggle()
    end)

    closeButton.Activated:Connect(function()
        self:SetOpen(false)
    end)

    self._screenGui = screenGui
    self._panel = panel
    self._list = list
end

function QuestUI:SetOpen(isOpen)
    self._isOpen = isOpen

    local targetPosition = isOpen and UDim2.fromScale(0.98, 0.5) or UDim2.fromScale(1.42, 0.5)
    TweenService:Create(self._panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = targetPosition,
    }):Play()
end

function QuestUI:Toggle()
    self:SetOpen(not self._isOpen)
end

function QuestUI:SetOnClaim(callback)
    self._onClaim = callback
end

function QuestUI:_makeCard(quest, state, layoutOrder)
    state = state or {}

    local progress = tonumber(state.Progress) or 0
    local required = tonumber(quest.RequiredAmount) or 1
    local ratio = math.clamp(progress / required, 0, 1)
    local isComplete = state.Completed == true
    local isClaimed = state.Claimed == true

    local card = Instance.new("Frame")
    card.BackgroundColor3 = COLORS.Paper
    card.LayoutOrder = layoutOrder
    card.Size = UDim2.new(1, -4, 0, 148)
    card.Parent = self._list
    addCorner(card, 8)
    addStroke(card, isComplete and COLORS.Green or COLORS.Stroke, 1)

    local category = makeLabel(card, quest.Category or quest.Type, 12, isComplete and COLORS.Green or COLORS.Blue, true)
    category.Position = UDim2.fromOffset(12, 10)
    category.Size = UDim2.new(1, -24, 0, 16)

    local title = makeLabel(card, quest.Title or quest.Id, 17, COLORS.Ink, true)
    title.Position = UDim2.fromOffset(12, 29)
    title.Size = UDim2.new(1, -24, 0, 24)

    local description = makeLabel(card, quest.Description or "", 13, COLORS.Muted, false)
    description.Position = UDim2.fromOffset(12, 55)
    description.Size = UDim2.new(1, -24, 0, 34)

    local progressBack = Instance.new("Frame")
    progressBack.BackgroundColor3 = Color3.fromRGB(229, 222, 207)
    progressBack.Position = UDim2.new(0, 12, 0, 95)
    progressBack.Size = UDim2.new(1, -120, 0, 12)
    progressBack.Parent = card
    addCorner(progressBack, 6)

    local progressFill = Instance.new("Frame")
    progressFill.BackgroundColor3 = isComplete and COLORS.Green or COLORS.Gold
    progressFill.Size = UDim2.new(ratio, 0, 1, 0)
    progressFill.Parent = progressBack
    addCorner(progressFill, 6)

    local progressText = makeLabel(card, string.format("%d / %d", math.floor(progress), math.floor(required)), 12, COLORS.Muted, true)
    progressText.Position = UDim2.new(1, -98, 0, 91)
    progressText.Size = UDim2.fromOffset(86, 20)
    progressText.TextXAlignment = Enum.TextXAlignment.Right

    local reward = makeLabel(card, "Reward: " .. formatRewards(quest.Rewards), 12, COLORS.Muted, false)
    reward.Position = UDim2.fromOffset(12, 118)
    reward.Size = UDim2.new(1, -132, 0, 20)

    local claimButton = Instance.new("TextButton")
    claimButton.AnchorPoint = Vector2.new(1, 1)
    claimButton.BackgroundColor3 = isClaimed and Color3.fromRGB(190, 190, 190) or (isComplete and COLORS.Green or Color3.fromRGB(215, 209, 196))
    claimButton.Position = UDim2.new(1, -12, 1, -10)
    claimButton.Size = UDim2.fromOffset(104, 34)
    claimButton.Font = Enum.Font.GothamBold
    claimButton.Text = isClaimed and "Claimed" or (isComplete and "Claim" or "Locked")
    claimButton.TextColor3 = isComplete and Color3.new(1, 1, 1) or COLORS.Muted
    claimButton.TextSize = 14
    claimButton.AutoButtonColor = isComplete and not isClaimed
    claimButton.Parent = card
    addCorner(claimButton, 8)

    claimButton.Activated:Connect(function()
        if isComplete and not isClaimed and self._onClaim then
            self._onClaim(quest.Id)
        end
    end)
end

function QuestUI:Render(data)
    self._data = data
    clearList(self._list)

    if not data or not data.Config then
        return
    end

    local playerQuests = data.PlayerData and data.PlayerData.Quests or {}
    local regularOrder = 0
    local dailyOrder = 1000

    for _, quest in ipairs(data.Config.Quests or {}) do
        if quest.Type == "Daily" then
            dailyOrder += 1
            self:_makeCard(quest, playerQuests[quest.Id], dailyOrder)
        else
            regularOrder += 1
            self:_makeCard(quest, playerQuests[quest.Id], regularOrder)
        end
    end
end

QuestUI:_build()
_G.SimpleQuestKitUI = QuestUI

if Debug then
    print("[SimpleQuestKit] QuestUIController loaded")
end
