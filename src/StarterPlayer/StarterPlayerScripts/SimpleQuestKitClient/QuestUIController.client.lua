-- Simple runtime quest UI.
-- Builds one MainGui > QuestButton + QuestFrame and only clones QuestCardTemplate.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local kit = ReplicatedStorage:WaitForChild("SimpleQuestKit", 10)
if not kit then
    warn("[SimpleQuestKit] ReplicatedStorage.SimpleQuestKit was not found after 10 seconds. QuestUIController stopped.")
    return
end

local configFolder = kit:WaitForChild("Config", 10)
if not configFolder then
    warn("[SimpleQuestKit] ReplicatedStorage.SimpleQuestKit.Config was not found after 10 seconds. QuestUIController stopped.")
    return
end

local demoConfigModule = configFolder:WaitForChild("DemoConfig", 10)
if not demoConfigModule then
    warn("[SimpleQuestKit] DemoConfig was not found after 10 seconds. QuestUIController stopped.")
    return
end

local DemoConfig = require(demoConfigModule)
local Debug = DemoConfig.Debug == true

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
    warn("[SimpleQuestKit] PlayerGui was not found after 10 seconds. QuestUIController stopped.")
    return
end

local COLORS = {
    Panel = Color3.fromRGB(18, 20, 30),
    Card = Color3.fromRGB(29, 33, 48),
    Button = Color3.fromRGB(42, 49, 72),
    ButtonActive = Color3.fromRGB(0, 190, 170),
    ButtonDisabled = Color3.fromRGB(70, 75, 92),
    Text = Color3.fromRGB(245, 247, 255),
    Muted = Color3.fromRGB(175, 183, 203),
    Stroke = Color3.fromRGB(85, 96, 125),
    ProgressBack = Color3.fromRGB(48, 55, 76),
    ProgressFill = Color3.fromRGB(0, 210, 190),
}

local QuestUI = {
    _data = nil,
    _activeTab = "Progress",
    _onClaim = nil,
    _onClaimAll = nil,
    _onTrack = nil,
    _onUntrack = nil,
    _screenGui = nil,
    _questButton = nil,
    _questFrame = nil,
    _questList = nil,
    _cardTemplate = nil,
    _uiScale = nil,
    _isOpen = false,
}

local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

local function addStroke(parent)
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Stroke
    stroke.Thickness = 1
    stroke.Transparency = 0.25
    stroke.Parent = parent
end

local function makeLabel(parent, name, text, size, bold)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    label.Text = text or ""
    label.TextColor3 = COLORS.Text
    label.TextSize = size
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

local function makeButton(parent, name, text)
    local button = Instance.new("TextButton")
    button.Name = name
    button.BackgroundColor3 = COLORS.Button
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.TextColor3 = COLORS.Text
    button.TextSize = 15
    button.AutoButtonColor = true
    button.Parent = parent
    addCorner(button, 8)
    return button
end

local function formatRewards(rewards)
    local parts = {}

    for rewardName, amount in pairs(rewards or {}) do
        table.insert(parts, tostring(amount) .. " " .. tostring(rewardName))
    end

    table.sort(parts)
    return #parts > 0 and table.concat(parts, ", ") or "Reward"
end

local function containsId(list, questId)
    for _, id in ipairs(list or {}) do
        if id == questId then
            return true
        end
    end

    return false
end

local function isDailyQuest(playerData, quest)
    return quest.Type == "Daily" or containsId(playerData.ActiveDailyQuestIds, quest.Id)
end

local function arePrerequisitesComplete(playerQuests, quest)
    for _, prerequisiteId in ipairs(quest.PrerequisiteQuests or {}) do
        local state = playerQuests and playerQuests[prerequisiteId]

        if not state or not state.Completed then
            return false
        end
    end

    return true
end

function QuestUI:_getAllQuests()
    if self._data and self._data.AllQuests then
        return self._data.AllQuests
    end

    if self._data and self._data.Config and self._data.Config.Quests then
        return self._data.Config.Quests
    end

    return {}
end

function QuestUI:_getState(quest)
    local quests = self._data and self._data.PlayerData and self._data.PlayerData.Quests or {}
    return quest and quests[quest.Id] or nil
end

function QuestUI:_getVisibleQuests()
    local data = self._data or {}
    local playerData = data.PlayerData or {}
    local playerQuests = playerData.Quests or {}
    local visible = {}

    for _, quest in ipairs(self:_getAllQuests()) do
        local daily = isDailyQuest(playerData, quest)

        if arePrerequisitesComplete(playerQuests, quest) then
            if self._activeTab == "Daily" and daily then
                table.insert(visible, quest)
            elseif self._activeTab == "Progress" and not daily then
                table.insert(visible, quest)
            end
        end
    end

    return visible
end

function QuestUI:_countClaimable()
    local count = 0

    for _, quest in ipairs(self:_getAllQuests()) do
        local state = self:_getState(quest)
        if state and state.Completed and not state.Claimed then
            count += 1
        end
    end

    return count
end

function QuestUI:_clearCards()
    for _, child in ipairs(self._questList:GetChildren()) do
        if child:IsA("GuiObject") and child ~= self._cardTemplate then
            child:Destroy()
        end
    end
end

function QuestUI:_updateScale()
    if not self._uiScale then
        return
    end

    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    self._uiScale.Scale = math.clamp(math.min(viewport.X / 900, viewport.Y / 650), 0.82, 1)
end

function QuestUI:_build()
    if self._screenGui then
        return
    end

    local oldGenerated = playerGui:FindFirstChild("SimpleQuestKitUI")
    if oldGenerated then
        oldGenerated:Destroy()
    end

    local mainGui = playerGui:FindFirstChild("MainGui")
    if not mainGui then
        mainGui = Instance.new("ScreenGui")
        mainGui.Name = "MainGui"
        mainGui.ResetOnSpawn = false
        mainGui.IgnoreGuiInset = false
        mainGui.Parent = playerGui
    end

    local oldButton = mainGui:FindFirstChild("QuestButton")
    if oldButton then
        oldButton:Destroy()
    end

    local oldFrame = mainGui:FindFirstChild("QuestFrame")
    if oldFrame then
        oldFrame:Destroy()
    end

    local questButton = makeButton(mainGui, "QuestButton", "Quests")
    questButton.AnchorPoint = Vector2.new(0, 0.5)
    questButton.Position = UDim2.fromScale(0.02, 0.5)
    questButton.Size = UDim2.fromScale(0.095, 0.065)
    questButton.TextSize = 14

    local questFrame = Instance.new("Frame")
    questFrame.Name = "QuestFrame"
    questFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    questFrame.BackgroundColor3 = COLORS.Panel
    questFrame.Position = UDim2.fromScale(0.5, 0.5)
    questFrame.Size = UDim2.fromScale(0.42, 0.62)
    questFrame.Visible = false
    questFrame.Parent = mainGui
    addCorner(questFrame, 12)
    addStroke(questFrame)

    local uiScale = Instance.new("UIScale")
    uiScale.Name = "UIScale"
    uiScale.Parent = questFrame

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(320, 360)
    sizeConstraint.MaxSize = Vector2.new(520, 560)
    sizeConstraint.Parent = questFrame

    local framePadding = Instance.new("UIPadding")
    framePadding.PaddingLeft = UDim.new(0, 14)
    framePadding.PaddingRight = UDim.new(0, 14)
    framePadding.PaddingTop = UDim.new(0, 14)
    framePadding.PaddingBottom = UDim.new(0, 14)
    framePadding.Parent = questFrame

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.Size = UDim2.fromScale(1, 0.12)
    header.Parent = questFrame

    local title = makeLabel(header, "Title", "Quests", 24, true)
    title.Size = UDim2.fromScale(0.78, 1)

    local closeButton = makeButton(header, "CloseButton", "X")
    closeButton.AnchorPoint = Vector2.new(1, 0.5)
    closeButton.Position = UDim2.fromScale(1, 0.5)
    closeButton.Size = UDim2.fromScale(0.14, 0.72)

    local tabs = Instance.new("Frame")
    tabs.Name = "Tabs"
    tabs.BackgroundTransparency = 1
    tabs.Position = UDim2.fromScale(0, 0.14)
    tabs.Size = UDim2.fromScale(1, 0.09)
    tabs.Parent = questFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabs

    local dailyButton = makeButton(tabs, "DailyButton", "Daily")
    dailyButton.Size = UDim2.new(0.5, -4, 1, 0)

    local progressButton = makeButton(tabs, "ProgressButton", "Progress")
    progressButton.Size = UDim2.new(0.5, -4, 1, 0)

    local questList = Instance.new("ScrollingFrame")
    questList.Name = "QuestList"
    questList.Active = true
    questList.BackgroundTransparency = 1
    questList.BorderSizePixel = 0
    questList.CanvasSize = UDim2.fromOffset(0, 0)
    questList.Position = UDim2.fromScale(0, 0.26)
    questList.ScrollBarThickness = 5
    questList.Size = UDim2.fromScale(1, 0.74)
    questList.Parent = questFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = questList

    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingRight = UDim.new(0, 8)
    listPadding.PaddingBottom = UDim.new(0, 8)
    listPadding.Parent = questList

    local template = Instance.new("Frame")
    template.Name = "QuestCardTemplate"
    template.BackgroundColor3 = COLORS.Card
    template.Size = UDim2.new(1, -8, 0, 132)
    template.Visible = false
    template.Parent = questFrame
    addCorner(template, 10)
    addStroke(template)

    local templatePadding = Instance.new("UIPadding")
    templatePadding.PaddingLeft = UDim.new(0, 12)
    templatePadding.PaddingRight = UDim.new(0, 12)
    templatePadding.PaddingTop = UDim.new(0, 10)
    templatePadding.PaddingBottom = UDim.new(0, 10)
    templatePadding.Parent = template

    local cardTitle = makeLabel(template, "Title", "Quest Title", 17, true)
    cardTitle.Position = UDim2.fromScale(0, 0)
    cardTitle.Size = UDim2.fromScale(0.68, 0.18)

    local description = makeLabel(template, "Description", "Quest description", 13, false)
    description.Position = UDim2.fromScale(0, 0.2)
    description.Size = UDim2.fromScale(1, 0.2)
    description.TextColor3 = COLORS.Muted

    local progressText = makeLabel(template, "ProgressText", "0 / 1", 13, true)
    progressText.Position = UDim2.fromScale(0, 0.44)
    progressText.Size = UDim2.fromScale(0.5, 0.16)

    local progressBack = Instance.new("Frame")
    progressBack.Name = "ProgressBack"
    progressBack.BackgroundColor3 = COLORS.ProgressBack
    progressBack.Position = UDim2.fromScale(0, 0.63)
    progressBack.Size = UDim2.fromScale(0.68, 0.08)
    progressBack.Parent = template
    addCorner(progressBack, 6)

    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.BackgroundColor3 = COLORS.ProgressFill
    progressFill.Size = UDim2.fromScale(0, 1)
    progressFill.Parent = progressBack
    addCorner(progressFill, 6)

    local reward = makeLabel(template, "RewardText", "Reward", 12, false)
    reward.Position = UDim2.fromScale(0, 0.78)
    reward.Size = UDim2.fromScale(0.68, 0.16)
    reward.TextColor3 = COLORS.Muted

    local claimButton = makeButton(template, "ClaimButton", "Claim")
    claimButton.AnchorPoint = Vector2.new(1, 1)
    claimButton.Position = UDim2.fromScale(1, 1)
    claimButton.Size = UDim2.fromScale(0.26, 0.3)

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        questList.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 8)
    end)

    questButton.Activated:Connect(function()
        self:Toggle()
    end)

    closeButton.Activated:Connect(function()
        self:SetOpen(false)
    end)

    dailyButton.Activated:Connect(function()
        self._activeTab = "Daily"
        self:Render(self._data)
    end)

    progressButton.Activated:Connect(function()
        self._activeTab = "Progress"
        self:Render(self._data)
    end)

    self._screenGui = mainGui
    self._questButton = questButton
    self._questFrame = questFrame
    self._questList = questList
    self._cardTemplate = template
    self._uiScale = uiScale

    self:_updateScale()
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            self:_updateScale()
        end)
    end
end

function QuestUI:_setTabButtons()
    local tabs = self._questFrame:FindFirstChild("Tabs")
    if not tabs then
        return
    end

    local dailyButton = tabs:FindFirstChild("DailyButton")
    local progressButton = tabs:FindFirstChild("ProgressButton")

    if dailyButton then
        dailyButton.BackgroundColor3 = self._activeTab == "Daily" and COLORS.ButtonActive or COLORS.Button
    end

    if progressButton then
        progressButton.BackgroundColor3 = self._activeTab == "Progress" and COLORS.ButtonActive or COLORS.Button
    end
end

function QuestUI:_renderEmptyCard(message)
    local card = self._cardTemplate:Clone()
    card.Name = "QuestCard_Empty"
    card.Visible = true
    card.Parent = self._questList

    card.Title.Text = message
    card.Description.Text = ""
    card.ProgressText.Text = ""
    card.ProgressBack.ProgressFill.Size = UDim2.fromScale(0, 1)
    card.RewardText.Text = ""
    card.ClaimButton.Visible = false
end

function QuestUI:_renderQuestCard(quest, state, layoutOrder)
    state = state or {}

    local progress = tonumber(state.Progress) or 0
    local required = math.max(tonumber(quest.RequiredAmount) or 1, 1)
    local complete = state.Completed == true
    local claimed = state.Claimed == true
    local ratio = math.clamp(progress / required, 0, 1)

    local card = self._cardTemplate:Clone()
    card.Name = "QuestCard_" .. tostring(quest.Id)
    card.LayoutOrder = layoutOrder
    card.Visible = true
    card.Parent = self._questList

    card.Title.Text = quest.Title or quest.Id
    card.Description.Text = quest.Description or ""
    card.ProgressText.Text = string.format("%d / %d", math.floor(progress), math.floor(required))
    card.ProgressBack.ProgressFill.Size = UDim2.fromScale(ratio, 1)
    card.RewardText.Text = "Reward: " .. formatRewards(quest.Rewards)
    card.ClaimButton.Text = claimed and "Claimed" or (complete and "Claim" or "Locked")
    card.ClaimButton.BackgroundColor3 = complete and not claimed and COLORS.ButtonActive or COLORS.ButtonDisabled
    card.ClaimButton.Active = complete and not claimed

    card.ClaimButton.Activated:Connect(function()
        if complete and not claimed and self._onClaim then
            self._onClaim(quest.Id)
        end
    end)
end

function QuestUI:Render(data)
    self:_build()
    self._data = data
    self:_clearCards()
    self:_setTabButtons()

    if not data or not data.PlayerData then
        self:_renderEmptyCard("Loading quests...")
        return
    end

    local visibleQuests = self:_getVisibleQuests()
    if #visibleQuests == 0 then
        self:_renderEmptyCard(self._activeTab == "Daily" and "No daily quests yet." or "No progress quests yet.")
        return
    end

    for index, quest in ipairs(visibleQuests) do
        self:_renderQuestCard(quest, self:_getState(quest), index)
    end
end

function QuestUI:RenderLoading()
    self:Render(nil)
end

function QuestUI:ShowError(message)
    self:_build()
    self:_clearCards()
    self:_renderEmptyCard(message or "Quest data unavailable.")
end

function QuestUI:SetOpen(isOpen)
    self:_build()
    self._isOpen = isOpen == true
    self._questFrame.Visible = self._isOpen
end

function QuestUI:Toggle()
    self:SetOpen(not self._isOpen)
end

function QuestUI:SetOnClaim(callback)
    self._onClaim = callback
end

function QuestUI:SetOnClaimAll(callback)
    self._onClaimAll = callback
end

function QuestUI:SetOnTrack(callback)
    self._onTrack = callback
end

function QuestUI:SetOnUntrack(callback)
    self._onUntrack = callback
end

function QuestUI:ClearPendingClaim()
end

function QuestUI:SetClaimAllPending()
end

function QuestUI:ShowToast()
end

QuestUI:_build()
QuestUI:RenderLoading()
_G.SimpleQuestKitUI = QuestUI

if Debug then
    print("[SimpleQuestKit] QuestUIController loaded")
end
