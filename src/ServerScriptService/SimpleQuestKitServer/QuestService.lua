local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local kit = ReplicatedStorage:WaitForChild("SimpleQuestKit")
local QuestConfig = require(kit:WaitForChild("Config"):WaitForChild("QuestConfig"))
local QuestUtil = require(kit:WaitForChild("Shared"):WaitForChild("QuestUtil"))

local serverRoot = script.Parent
local QuestDataService = require(serverRoot:WaitForChild("QuestDataService"))
local RewardService = require(serverRoot:WaitForChild("RewardService"))
local DailyQuestService = require(serverRoot:WaitForChild("DailyQuestService"))

local QuestService = {
    _questMap = QuestUtil.BuildQuestMap(QuestConfig),
    _remotes = nil,
}

local function createRemoteFolder()
    local remotes = kit:FindFirstChild("Remotes")

    if not remotes then
        remotes = Instance.new("Folder")
        remotes.Name = "Remotes"
        remotes.Parent = kit
    end

    local remoteDefinitions = {
        RequestQuestData = "RemoteFunction",
        ClaimQuest = "RemoteFunction",
        QuestUpdated = "RemoteEvent",
        QuestClaimed = "RemoteEvent",
        OpenQuestUI = "RemoteEvent",
    }

    for remoteName, className in pairs(remoteDefinitions) do
        if not remotes:FindFirstChild(remoteName) then
            local remote = Instance.new(className)
            remote.Name = remoteName
            remote.Parent = remotes
        end
    end

    return remotes
end

local function publicQuestData(data)
    local clean = QuestUtil.CopyDictionary(data or {})
    clean._Dirty = nil
    return clean
end

function QuestService:_getQuestState(player, questId)
    local data = QuestDataService:GetOrLoadData(player)
    local quest = self._questMap[questId]

    if not quest then
        return nil, nil, data
    end

    data.Quests[questId] = data.Quests[questId] or {
        Progress = 0,
        Completed = false,
        Claimed = false,
        LastReset = os.time(),
        UpdatedAt = os.time(),
    }

    return data.Quests[questId], quest, data
end

function QuestService:_fireDataChanged(player)
    if self._remotes and player.Parent then
        self._remotes.QuestUpdated:FireClient(player, self:GetPlayerQuestData(player))
    end
end

function QuestService:Init()
    self._remotes = createRemoteFolder()

    self._remotes.RequestQuestData.OnServerInvoke = function(player)
        return self:GetPlayerQuestData(player)
    end

    self._remotes.ClaimQuest.OnServerInvoke = function(player, questId)
        if type(questId) ~= "string" then
            return false
        end

        return self:ClaimReward(player, questId)
    end

    Players.PlayerAdded:Connect(function(player)
        QuestDataService:LoadPlayer(player)
        DailyQuestService:ResetExpiredDailies(player)
        self:_fireDataChanged(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        QuestDataService:ReleasePlayer(player)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            QuestDataService:LoadPlayer(player)
            DailyQuestService:ResetExpiredDailies(player)
            self:_fireDataChanged(player)
        end)
    end

    task.spawn(function()
        while true do
            task.wait(1)

            for _, player in ipairs(Players:GetPlayers()) do
                for _, quest in ipairs(QuestConfig.Quests or {}) do
                    if QuestUtil.GetQuestType(quest) == "Playtime" then
                        self:AddProgress(player, quest.Id, 1)
                    end
                end
            end
        end
    end)

    print("[SimpleQuestKit] QuestService initialized")
end

-- Adds progress to a quest from trusted server code only.
function QuestService:AddProgress(player, questId, amount)
    amount = tonumber(amount) or 1
    local state, quest = self:_getQuestState(player, questId)

    if not state or amount <= 0 or state.Claimed then
        return false
    end

    if state.Completed and not quest.Repeatable then
        return false
    end

    return self:SetProgress(player, questId, state.Progress + amount)
end

-- Sets quest progress to a specific amount from trusted server code only.
function QuestService:SetProgress(player, questId, amount)
    local state, quest = self:_getQuestState(player, questId)

    if not state or state.Claimed then
        return false
    end

    state.Progress = QuestUtil.ClampProgress(amount, quest.RequiredAmount)
    state.UpdatedAt = os.time()

    if QuestUtil.IsCompleted(state.Progress, quest.RequiredAmount) then
        state.Completed = true
    end

    QuestDataService:MarkDirty(player)
    QuestDataService:SavePlayer(player, false)
    self:_fireDataChanged(player)

    return true
end

-- Marks a quest complete without granting rewards.
function QuestService:CompleteQuest(player, questId)
    local state, quest = self:_getQuestState(player, questId)

    if not state then
        return false
    end

    state.Progress = quest.RequiredAmount
    state.Completed = true
    state.UpdatedAt = os.time()

    QuestDataService:MarkDirty(player)
    QuestDataService:SavePlayer(player, false)
    self:_fireDataChanged(player)

    return true
end

-- Grants configured rewards for a completed quest once.
function QuestService:ClaimReward(player, questId)
    local state, quest = self:_getQuestState(player, questId)

    if not state or not state.Completed or state.Claimed then
        return false
    end

    state.Claimed = true
    state.UpdatedAt = os.time()

    RewardService:GrantRewards(player, quest.Rewards)
    QuestDataService:MarkDirty(player)
    QuestDataService:SavePlayer(player, true)

    if self._remotes and player.Parent then
        self._remotes.QuestClaimed:FireClient(player, questId, quest.Rewards or {})
    end

    self:_fireDataChanged(player)
    return true
end

-- Returns a safe copy of the player's quest data for UI rendering.
function QuestService:GetPlayerQuestData(player)
    return {
        Config = QuestConfig,
        PlayerData = publicQuestData(QuestDataService:GetOrLoadData(player)),
        ServerTime = os.time(),
    }
end

-- Resets daily quests for a player so they can be completed again.
function QuestService:ResetDailyQuests(player)
    local data = QuestDataService:GetOrLoadData(player)
    local now = os.time()

    for _, quest in ipairs(QuestConfig.Quests or {}) do
        if quest.Type == "Daily" then
            data.Quests[quest.Id] = {
                Progress = 0,
                Completed = false,
                Claimed = false,
                LastReset = now,
                UpdatedAt = now,
            }
        end
    end

    data.LastDailyReset = now
    QuestDataService:MarkDirty(player)
    QuestDataService:SavePlayer(player, true)
    self:_fireDataChanged(player)
    return true
end

return QuestService
