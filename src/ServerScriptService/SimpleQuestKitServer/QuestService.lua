-- Core server-authoritative quest API.
-- Required core file. Buyers usually should not edit this.
-- Other server scripts should use this module to add progress, complete quests, and claim rewards.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local kit = ReplicatedStorage:WaitForChild("SimpleQuestKit")
local DemoConfig = require(kit:WaitForChild("Config"):WaitForChild("DemoConfig"))
local QuestConfig = require(kit:WaitForChild("Config"):WaitForChild("QuestConfig"))
local DailyQuestConfig = require(kit:WaitForChild("Config"):WaitForChild("DailyQuestConfig"))
local WeeklyQuestConfig = require(kit:WaitForChild("Config"):WaitForChild("WeeklyQuestConfig"))
local AchievementConfig = require(kit:WaitForChild("Config"):WaitForChild("AchievementConfig"))
local EventQuestConfig = require(kit:WaitForChild("Config"):WaitForChild("EventQuestConfig"))
local QuestUtil = require(kit:WaitForChild("Shared"):WaitForChild("QuestUtil"))
local Debug = DemoConfig.Debug == true

local serverRoot = script.Parent
local QuestDataService = require(serverRoot:WaitForChild("QuestDataService"))
local RewardService = require(serverRoot:WaitForChild("RewardService"))

local QuestService = {
    _questMap = nil,
    _questList = nil,
    _remotes = nil,
}

QuestService._questMap, QuestService._questList = QuestUtil.BuildQuestMapFromConfigs(QuestConfig, DailyQuestConfig, WeeklyQuestConfig, AchievementConfig, EventQuestConfig)

local function getUtcTimestamp(year, month, day, hour, minute, second)
    return DateTime.fromUniversalTime(year, month, day, hour or 0, minute or 0, second or 0).UnixTimestamp
end

local function getUtcMidnight(now)
    local utc = os.date("!*t", now or os.time())
    return getUtcTimestamp(utc.year, utc.month, utc.day, 0, 0, 0)
end

local function getUtcDayKey(now)
    return os.date("!%Y-%m-%d", now or os.time())
end

local function getUtcDayIndex(now)
    return math.floor(getUtcMidnight(now) / 86400)
end

local function getUtcWeekKey(now)
    local utc = os.date("!*t", now or os.time())
    local dayOfWeek = utc.wday == 1 and 7 or utc.wday - 1
    local mondayMidnight = getUtcMidnight(now) - ((dayOfWeek - 1) * 86400)

    return os.date("!%Y-%m-%d", mondayMidnight)
end

local function getNextUtcMidnight(now)
    return getUtcMidnight(now) + 86400
end

local function getNextUtcWeek(now)
    local utc = os.date("!*t", now or os.time())
    local dayOfWeek = utc.wday == 1 and 7 or utc.wday - 1
    return getUtcMidnight(now) + ((8 - dayOfWeek) * 86400)
end

local function getStableScore(player, periodKey, questId)
    local total = player.UserId + #periodKey * 97

    for index = 1, #questId do
        total += string.byte(questId, index) * index
    end

    return total
end

local function selectQuestIds(player, periodKey, quests, count)
    local scored = {}

    for _, quest in ipairs(quests or {}) do
        table.insert(scored, {
            Id = quest.Id,
            Score = getStableScore(player, periodKey, quest.Id),
        })
    end

    table.sort(scored, function(left, right)
        if left.Score == right.Score then
            return left.Id < right.Id
        end

        return left.Score < right.Score
    end)

    local selected = {}

    for index = 1, math.min(count, #scored) do
        table.insert(selected, scored[index].Id)
    end

    return selected
end

local function getDailyPool()
    return DailyQuestConfig.DailyQuestPool or DailyQuestConfig.Quests or {}
end

local function getWeeklyPool()
    return WeeklyQuestConfig.WeeklyQuestPool or WeeklyQuestConfig.Quests or {}
end

local function getEventPool()
    return EventQuestConfig.EventQuestPool or EventQuestConfig.Quests or {}
end

local function isEventQuest(quest)
    return quest and (quest.Type == "Event" or quest.Category == "Event")
end

local function isEventQuestActive(quest, now)
    if not isEventQuest(quest) then
        return true
    end

    now = now or os.time()
    local startTime = tonumber(quest.StartTime) or 0
    local endTime = tonumber(quest.EndTime) or 32503680000

    return now >= startTime and now <= endTime
end

local function getCurrentEventInfo(now)
    now = now or os.time()
    local activeCount = 0
    local nextStartTime = nil
    local activeEndTime = nil

    for _, quest in ipairs(getEventPool()) do
        local startTime = tonumber(quest.StartTime) or 0
        local endTime = tonumber(quest.EndTime) or 32503680000

        if now >= startTime and now <= endTime then
            activeCount += 1
            activeEndTime = math.min(activeEndTime or endTime, endTime)
        elseif now < startTime then
            nextStartTime = math.min(nextStartTime or startTime, startTime)
        end
    end

    return {
        EventName = EventQuestConfig.EventName or "Event",
        ActiveCount = activeCount,
        Active = activeCount > 0,
        EndsAt = activeEndTime,
        StartsAt = nextStartTime,
        SecondsRemaining = activeEndTime and math.max(0, activeEndTime - now) or 0,
        SecondsUntilStart = nextStartTime and math.max(0, nextStartTime - now) or 0,
    }
end

local function containsId(list, questId)
    if type(list) ~= "table" then
        return false
    end

    for _, storedQuestId in ipairs(list or {}) do
        if storedQuestId == questId then
            return true
        end
    end

    return false
end

local function questMatchesTarget(quest, targetId)
    return quest and (quest.Target == targetId or quest.BaseType == targetId)
end

local function addRewardSummary(summary, rewards, player)
    local rewardAmounts = player and RewardService:GetRewardAmounts(player, rewards) or rewards

    for rewardName, amount in pairs(rewardAmounts or {}) do
        summary[rewardName] = (summary[rewardName] or 0) + (tonumber(amount) or 0)
    end
end

local function getStreakReward(streakCount)
    local rewards = DailyQuestConfig.StreakRewards or {}
    return rewards[streakCount] or rewards[tostring(streakCount)]
end

local function wouldClaimAllQuestIds(data, questIds, questIdBeingClaimed)
    if type(questIds) ~= "table" then
        return false
    end

    if #questIds == 0 then
        return false
    end

    for _, questId in ipairs(questIds or {}) do
        local state = data.Quests[questId]

        if questId ~= questIdBeingClaimed and (not state or not state.Claimed) then
            return false
        end
    end

    return true
end

local function getQuestCategory(quest)
    if not quest then
        return "Main"
    end

    if quest.Type == "Daily" then
        return "Daily"
    elseif quest.Type == "Weekly" then
        return "Weekly"
    elseif quest.Type == "Achievement" then
        return "Achievement"
    elseif isEventQuest(quest) then
        return "Event"
    end

    return QuestUtil.GetQuestCategory(quest)
end

local function arePrerequisitesComplete(data, quest)
    for _, prerequisiteQuestId in ipairs(quest.PrerequisiteQuests or {}) do
        local prerequisiteState = data.Quests and data.Quests[prerequisiteQuestId]

        if not prerequisiteState or not prerequisiteState.Completed then
            return false
        end
    end

    return true
end

local function isAdminPlayer(player)
    if DemoConfig.EnableAdminDebugPanel ~= true then
        return false
    end

    for _, userId in ipairs(DemoConfig.AdminUserIds or {}) do
        if tonumber(userId) == player.UserId then
            return true
        end
    end

    return false
end

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
        ClaimAllCompleted = "RemoteFunction",
        TrackQuest = "RemoteFunction",
        UntrackQuest = "RemoteFunction",
    }

    for remoteName, className in pairs(remoteDefinitions) do
        if not remotes:FindFirstChild(remoteName) then
            local remote = Instance.new(className)
            remote.Name = remoteName
            remote.Parent = remotes
        end
    end

    if DemoConfig.EnableAdminDebugPanel == true and not remotes:FindFirstChild("AdminQuestDebug") then
        local remote = Instance.new("RemoteFunction")
        remote.Name = "AdminQuestDebug"
        remote.Parent = remotes
    end

    return remotes
end

local function publicQuestData(data)
    local clean = QuestUtil.CopyDictionary(data or {})
    clean._Dirty = nil
    return clean
end

function QuestService:_getQuestState(player, questId)
    self:RefreshRotatingQuests(player)

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

function QuestService:_getQuestStateNoRefresh(player, questId)
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

function QuestService:_isQuestActiveForPlayer(player, quest)
    if not quest then
        return false
    end

    local data = QuestDataService:GetOrLoadData(player)

    if isEventQuest(quest) and not isEventQuestActive(quest) then
        return false
    elseif quest.Type == "Daily" then
        return containsId(data.ActiveDailyQuestIds, quest.Id) and arePrerequisitesComplete(data, quest)
    elseif quest.Type == "Weekly" then
        return containsId(data.ActiveWeeklyQuestIds, quest.Id) and arePrerequisitesComplete(data, quest)
    end

    return arePrerequisitesComplete(data, quest)
end

function QuestService:_areQuestIdsClaimed(player, questIds)
    local data = QuestDataService:GetOrLoadData(player)

    if type(questIds) ~= "table" then
        return false
    end

    if #questIds == 0 then
        return false
    end

    for _, questId in ipairs(questIds or {}) do
        local state = data.Quests[questId]

        if not state or not state.Claimed then
            return false
        end
    end

    return true
end

function QuestService:_tryGrantPeriodBonus(player, periodType)
    local data = QuestDataService:GetOrLoadData(player)

    if periodType == "Daily" then
        if data.DailyBonusClaimed or not self:_areQuestIdsClaimed(player, data.ActiveDailyQuestIds or {}) then
            return
        end

        data.DailyBonusClaimed = true
        RewardService:GrantRewards(player, DailyQuestConfig.CompletionBonus)
    elseif periodType == "Weekly" then
        if data.WeeklyBonusClaimed or not self:_areQuestIdsClaimed(player, data.ActiveWeeklyQuestIds or {}) then
            return
        end

        data.WeeklyBonusClaimed = true
        RewardService:GrantRewards(player, WeeklyQuestConfig.CompletionBonus)
    end
end

-- Updates the player's UTC daily login streak and grants the configured streak reward once.
function QuestService:RefreshDailyLoginStreak(player)
    local data = QuestDataService:GetOrLoadData(player)
    local now = os.time()
    local todayIndex = getUtcDayIndex(now)
    local todayKey = getUtcDayKey(now)
    local lastIndex = tonumber(data.LastLoginDayIndex) or 0

    if lastIndex == todayIndex then
        return false
    end

    if lastIndex == todayIndex - 1 then
        data.DailyStreakCount = (tonumber(data.DailyStreakCount) or 0) + 1
    else
        data.DailyStreakCount = 1
    end

    data.BestDailyStreak = math.max(tonumber(data.BestDailyStreak) or 0, data.DailyStreakCount)
    data.LastLoginDayIndex = todayIndex
    data.LastLoginDayKey = todayKey

    local reward = getStreakReward(data.DailyStreakCount)
    if reward then
        RewardService:GrantRewards(player, reward)
        data.LastStreakRewardDayKey = todayKey
        data.LastStreakReward = QuestUtil.CopyDictionary(reward)
    else
        data.LastStreakReward = {}
    end

    QuestDataService:MarkDirty(player)
    QuestDataService:SavePlayer(player, true)

    if Debug then
        print(string.format("[SimpleQuestKit] %s daily streak is now %d", player.Name, data.DailyStreakCount))
    end

    return true
end

-- Refreshes daily and weekly selections when UTC reset keys change.
function QuestService:RefreshRotatingQuests(player)
    local data = QuestDataService:GetOrLoadData(player)
    local now = os.time()
    local dayKey = getUtcDayKey(now)
    local weekKey = getUtcWeekKey(now)
    local dailyPool = getDailyPool()
    local weeklyPool = getWeeklyPool()
    local changed = false

    if data.DailyKey ~= dayKey or (#data.ActiveDailyQuestIds == 0 and #dailyPool > 0) then
        data.DailyKey = dayKey
        data.ActiveDailyQuestIds = selectQuestIds(player, dayKey, dailyPool, DailyQuestConfig.Count or 3)
        data.DailyBonusClaimed = false
        data.LastDailyReset = now

        for _, questId in ipairs(data.ActiveDailyQuestIds) do
            data.Quests[questId] = {
                Progress = 0,
                Completed = false,
                Claimed = false,
                LastReset = now,
                UpdatedAt = now,
            }
        end

        changed = true
    end

    if data.WeeklyKey ~= weekKey or (#data.ActiveWeeklyQuestIds == 0 and #weeklyPool > 0) then
        local minCount = WeeklyQuestConfig.MinCount or 3
        local maxCount = WeeklyQuestConfig.MaxCount or minCount
        local range = math.max(0, maxCount - minCount)
        local count = minCount + ((player.UserId + #weekKey) % (range + 1))

        data.WeeklyKey = weekKey
        data.ActiveWeeklyQuestIds = selectQuestIds(player, weekKey, weeklyPool, count)
        data.WeeklyBonusClaimed = false

        for _, questId in ipairs(data.ActiveWeeklyQuestIds) do
            data.Quests[questId] = {
                Progress = 0,
                Completed = false,
                Claimed = false,
                LastReset = now,
                UpdatedAt = now,
            }
        end

        changed = true
    end

    if changed then
        QuestDataService:MarkDirty(player)
    end

    return changed
end

function QuestService:_fireDataChanged(player)
    if self._remotes and player.Parent then
        self._remotes.QuestUpdated:FireClient(player, self:GetPlayerQuestData(player))
    end
end

-- Starts remotes, player loading, rotating quest refresh, and playtime tracking.
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

    self._remotes.ClaimAllCompleted.OnServerInvoke = function(player)
        return self:ClaimAllCompleted(player)
    end

    self._remotes.TrackQuest.OnServerInvoke = function(player, questId)
        if type(questId) ~= "string" then
            return false
        end

        return self:TrackQuest(player, questId)
    end

    self._remotes.UntrackQuest.OnServerInvoke = function(player)
        return self:UntrackQuest(player)
    end

    local adminDebugRemote = self._remotes:FindFirstChild("AdminQuestDebug")
    if adminDebugRemote then
        adminDebugRemote.OnServerInvoke = function(player, action, payload)
            return self:RunAdminDebugAction(player, action, payload)
        end
    end

    Players.PlayerAdded:Connect(function(player)
        QuestDataService:LoadPlayer(player)
        self:RefreshRotatingQuests(player)
        self:RefreshDailyLoginStreak(player)
        self:_fireDataChanged(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        QuestDataService:ReleasePlayer(player)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            QuestDataService:LoadPlayer(player)
            self:RefreshRotatingQuests(player)
            self:RefreshDailyLoginStreak(player)
            self:_fireDataChanged(player)
        end)
    end

    task.spawn(function()
        while true do
            task.wait(1)

            for _, player in ipairs(Players:GetPlayers()) do
                for _, quest in ipairs(self._questList or {}) do
                    if QuestUtil.GetQuestType(quest) == "Playtime" then
                        if self:_isQuestActiveForPlayer(player, quest) then
                            self:AddProgress(player, quest.Id, 1)
                        end
                    end
                end
            end
        end
    end)

    if Debug then
        print("[SimpleQuestKit] QuestService initialized")
    end
end

-- Adds progress to a quest from trusted server code only.
function QuestService:AddProgress(player, questId, amount)
    amount = tonumber(amount) or 1
    local state, quest = self:_getQuestState(player, questId)

    if not state or amount <= 0 or state.Claimed or not self:_isQuestActiveForPlayer(player, quest) then
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

    if not state or state.Claimed or not self:_isQuestActiveForPlayer(player, quest) then
        return false
    end

    local wasCompleted = state.Completed == true
    state.Progress = QuestUtil.ClampProgress(amount, quest.RequiredAmount)
    state.UpdatedAt = os.time()

    if QuestUtil.IsCompleted(state.Progress, quest.RequiredAmount) then
        state.Completed = true
    end

    if state.Completed and not wasCompleted and quest.Target ~= "QuestCompleted" then
        self:AddProgressByTarget(player, "QuestCompleted", 1)
    end

    QuestDataService:MarkDirty(player)
    QuestDataService:SavePlayer(player, false)
    self:_fireDataChanged(player)

    return true
end

-- Adds progress to every active quest matching Target or BaseType.
function QuestService:AddProgressByTarget(player, targetId, amount)
    amount = tonumber(amount) or 1
    local changed = false

    if amount <= 0 then
        return false
    end

    self:RefreshRotatingQuests(player)

    for _, quest in ipairs(self._questList or {}) do
        if questMatchesTarget(quest, targetId) and self:_isQuestActiveForPlayer(player, quest) then
            local state = select(1, self:_getQuestStateNoRefresh(player, quest.Id))

            if state and not state.Claimed and (not state.Completed or quest.Repeatable) then
                local oldProgress = state.Progress
                local oldCompleted = state.Completed
                state.Progress = QuestUtil.ClampProgress(state.Progress + amount, quest.RequiredAmount)
                state.UpdatedAt = os.time()

                if QuestUtil.IsCompleted(state.Progress, quest.RequiredAmount) then
                    state.Completed = true
                end

                if state.Progress ~= oldProgress then
                    changed = true
                end

                if state.Completed and not oldCompleted and targetId ~= "QuestCompleted" then
                    self:AddProgressByTarget(player, "QuestCompleted", 1)
                end
            end
        end
    end

    if changed then
        QuestDataService:MarkDirty(player)
        QuestDataService:SavePlayer(player, false)
        self:_fireDataChanged(player)
    end

    return changed
end

-- Sets progress on every active quest matching Target or BaseType.
function QuestService:SetProgressByTarget(player, targetId, amount)
    local changed = false

    self:RefreshRotatingQuests(player)

    for _, quest in ipairs(self._questList or {}) do
        if questMatchesTarget(quest, targetId) and self:_isQuestActiveForPlayer(player, quest) then
            if self:SetProgress(player, quest.Id, amount) then
                changed = true
            end
        end
    end

    return changed
end

-- Marks a quest complete without granting rewards.
function QuestService:CompleteQuest(player, questId)
    local state, quest = self:_getQuestState(player, questId)

    if not state or not self:_isQuestActiveForPlayer(player, quest) then
        return false
    end

    local wasCompleted = state.Completed == true
    state.Progress = quest.RequiredAmount
    state.Completed = true
    state.UpdatedAt = os.time()

    if not wasCompleted and quest.Target ~= "QuestCompleted" then
        self:AddProgressByTarget(player, "QuestCompleted", 1)
    end

    QuestDataService:MarkDirty(player)
    QuestDataService:SavePlayer(player, false)
    self:_fireDataChanged(player)

    return true
end

-- Resets one quest state back to zero progress for admin/debug tooling.
function QuestService:ResetQuest(player, questId)
    local state, quest, data = self:_getQuestStateNoRefresh(player, questId)

    if not state or not quest then
        return false
    end

    data.Quests[questId] = {
        Progress = 0,
        Completed = false,
        Claimed = false,
        LastReset = os.time(),
        UpdatedAt = os.time(),
    }

    QuestDataService:MarkDirty(player)
    QuestDataService:SavePlayer(player, false)
    self:_fireDataChanged(player)

    return true
end

-- Claims configured rewards for a completed quest once.
function QuestService:ClaimReward(player, questId)
    local state, quest = self:_getQuestState(player, questId)

    if not state or not quest or not state.Completed or state.Claimed or not self:_isQuestActiveForPlayer(player, quest) then
        return false
    end

    local grantedRewards = RewardService:GetRewardAmounts(player, quest.Rewards)

    state.Claimed = true
    state.UpdatedAt = os.time()

    RewardService:GrantRewards(player, quest.Rewards)

    if quest.Type == "Daily" then
        self:AddProgressByTarget(player, "DailyClaimed", 1)
    end

    self:AddProgressByTarget(player, "RewardClaimed", 1)
    self:_tryGrantPeriodBonus(player, quest.Type)
    QuestDataService:MarkDirty(player)
    QuestDataService:SavePlayer(player, true)

    if self._remotes and player.Parent then
        self._remotes.QuestClaimed:FireClient(player, questId, grantedRewards)
    end

    self:_fireDataChanged(player)
    return true
end

-- Claims all completed, unclaimed rewards for the player.
function QuestService:ClaimAllCompleted(player)
    local claimedQuestIds = {}
    local rewardSummary = {}
    local data = QuestDataService:GetOrLoadData(player)

    self:RefreshRotatingQuests(player)

    for _, quest in ipairs(self._questList or {}) do
        local state = select(1, self:_getQuestStateNoRefresh(player, quest.Id))

        if state and state.Completed and not state.Claimed and self:_isQuestActiveForPlayer(player, quest) then
            local willClaimDailyBonus = quest.Type == "Daily"
                and not data.DailyBonusClaimed
                and wouldClaimAllQuestIds(data, data.ActiveDailyQuestIds or {}, quest.Id)
            local willClaimWeeklyBonus = quest.Type == "Weekly"
                and not data.WeeklyBonusClaimed
                and wouldClaimAllQuestIds(data, data.ActiveWeeklyQuestIds or {}, quest.Id)

            if self:ClaimReward(player, quest.Id) then
                table.insert(claimedQuestIds, quest.Id)
                addRewardSummary(rewardSummary, quest.Rewards, player)

                if willClaimDailyBonus then
                    addRewardSummary(rewardSummary, DailyQuestConfig.CompletionBonus, player)
                elseif willClaimWeeklyBonus then
                    addRewardSummary(rewardSummary, WeeklyQuestConfig.CompletionBonus, player)
                end
            end
        end
    end

    return {
        Claimed = #claimedQuestIds > 0,
        Count = #claimedQuestIds,
        QuestIds = claimedQuestIds,
        Rewards = rewardSummary,
    }
end

-- Sets the player's tracked quest for the floating tracker widget.
function QuestService:TrackQuest(player, questId)
    local state, quest, data = self:_getQuestState(player, questId)

    if not state or not quest or not self:_isQuestActiveForPlayer(player, quest) then
        return false
    end

    data.TrackedQuestId = questId
    QuestDataService:MarkDirty(player)
    self:_fireDataChanged(player)
    return true
end

-- Clears the player's tracked quest.
function QuestService:UntrackQuest(player)
    local data = QuestDataService:GetOrLoadData(player)
    data.TrackedQuestId = nil
    QuestDataService:MarkDirty(player)
    self:_fireDataChanged(player)
    return true
end

-- Returns active quests grouped by category for server-side integrations.
function QuestService:GetActiveQuests(player)
    self:RefreshRotatingQuests(player)

    local data = QuestDataService:GetOrLoadData(player)
    local grouped = {
        Main = {},
        Daily = {},
        Weekly = {},
        Event = {},
        Achievement = {},
        Completed = {},
    }

    for _, quest in ipairs(self._questList or {}) do
        if self:_isQuestActiveForPlayer(player, quest) then
            local state = data.Quests[quest.Id]
            local category = getQuestCategory(quest)
            local entry = {
                Quest = quest,
                State = state,
            }

            if state and state.Completed then
                table.insert(grouped.Completed, entry)
            else
                grouped[category] = grouped[category] or {}
                table.insert(grouped[category], entry)
            end
        end
    end

    return grouped
end

-- Returns completed or claimed quests for one player.
function QuestService:GetCompletedQuests(player)
    self:RefreshRotatingQuests(player)

    local data = QuestDataService:GetOrLoadData(player)
    local completed = {}

    for _, quest in ipairs(self._questList or {}) do
        local state = data.Quests[quest.Id]

        if state and (state.Completed or state.Claimed) and self:_isQuestActiveForPlayer(player, quest) then
            table.insert(completed, {
                Quest = quest,
                State = state,
            })
        end
    end

    return completed
end

-- Returns daily and weekly reset countdown information.
function QuestService:GetResetInfo(player)
    self:RefreshRotatingQuests(player)

    local now = os.time()
    local dailyResetAt = getNextUtcMidnight(now)
    local weeklyResetAt = getNextUtcWeek(now)
    local data = QuestDataService:GetOrLoadData(player)

    return {
        ServerTime = now,
        DailyKey = data.DailyKey,
        WeeklyKey = data.WeeklyKey,
        DailyResetAt = dailyResetAt,
        WeeklyResetAt = weeklyResetAt,
        DailyResetSeconds = math.max(0, dailyResetAt - now),
        WeeklyResetSeconds = math.max(0, weeklyResetAt - now),
        ActiveDailyQuestIds = QuestUtil.CopyDictionary(data.ActiveDailyQuestIds or {}),
        ActiveWeeklyQuestIds = QuestUtil.CopyDictionary(data.ActiveWeeklyQuestIds or {}),
        EventInfo = getCurrentEventInfo(now),
    }
end

-- Returns daily login streak information for UI or server-side display.
function QuestService:GetDailyStreakInfo(player)
    local data = QuestDataService:GetOrLoadData(player)
    local nextReward = getStreakReward((tonumber(data.DailyStreakCount) or 0) + 1)

    return {
        CurrentStreak = tonumber(data.DailyStreakCount) or 0,
        BestStreak = tonumber(data.BestDailyStreak) or 0,
        LastLoginDayKey = data.LastLoginDayKey,
        LastRewardDayKey = data.LastStreakRewardDayKey,
        LastReward = QuestUtil.CopyDictionary(data.LastStreakReward or {}),
        NextReward = QuestUtil.CopyDictionary(nextReward or {}),
    }
end

-- Returns a safe copy of the player's quest data for UI rendering.
function QuestService:GetPlayerQuestData(player)
    local resetInfo = self:GetResetInfo(player)
    local streakInfo = self:GetDailyStreakInfo(player)

    return {
        Config = QuestConfig,
        DailyConfig = DailyQuestConfig,
        WeeklyConfig = WeeklyQuestConfig,
        AchievementConfig = AchievementConfig,
        EventConfig = EventQuestConfig,
        AllQuests = self._questList,
        DailyResetAt = resetInfo.DailyResetAt,
        WeeklyResetAt = resetInfo.WeeklyResetAt,
        DailyResetSeconds = resetInfo.DailyResetSeconds,
        WeeklyResetSeconds = resetInfo.WeeklyResetSeconds,
        DailyStreakInfo = streakInfo,
        ResetInfo = resetInfo,
        EventInfo = resetInfo.EventInfo,
        PlayerData = publicQuestData(QuestDataService:GetOrLoadData(player)),
        ServerTime = resetInfo.ServerTime,
    }
end

-- Resets daily quests for a player so they can be completed again.
function QuestService:ResetDailyQuests(player)
    local data = QuestDataService:GetOrLoadData(player)
    data.DailyKey = ""
    self:RefreshRotatingQuests(player)
    QuestDataService:MarkDirty(player)
    QuestDataService:SavePlayer(player, true)
    self:_fireDataChanged(player)
    return true
end

-- Resets weekly quests for a player so they can be completed again.
function QuestService:ResetWeeklyQuests(player)
    local data = QuestDataService:GetOrLoadData(player)
    data.WeeklyKey = ""
    self:RefreshRotatingQuests(player)
    QuestDataService:MarkDirty(player)
    QuestDataService:SavePlayer(player, true)
    self:_fireDataChanged(player)
    return true
end

-- Runs admin-only test actions from the optional debug panel.
function QuestService:RunAdminDebugAction(player, action, payload)
    if not isAdminPlayer(player) then
        warn("[SimpleQuestKit] Blocked admin debug action from non-admin player: " .. player.Name)
        return {
            Success = false,
            Message = "Admin debug panel is not enabled for this player.",
        }
    end

    payload = type(payload) == "table" and payload or {}
    local questId = type(payload.QuestId) == "string" and payload.QuestId or ""
    local amount = tonumber(payload.Amount) or 1
    local success = false
    local message = "Unknown admin action."

    if action == "AddProgress" then
        success = questId ~= "" and self:AddProgress(player, questId, amount)
        message = success and "Progress added." or "Could not add progress."
    elseif action == "CompleteQuest" then
        success = questId ~= "" and self:CompleteQuest(player, questId)
        message = success and "Quest completed." or "Could not complete quest."
    elseif action == "ResetQuest" then
        success = questId ~= "" and self:ResetQuest(player, questId)
        message = success and "Quest reset." or "Could not reset quest."
    elseif action == "ResetDaily" then
        success = self:ResetDailyQuests(player)
        message = success and "Daily quests reset." or "Could not reset daily quests."
    elseif action == "ResetWeekly" then
        success = self:ResetWeeklyQuests(player)
        message = success and "Weekly quests reset." or "Could not reset weekly quests."
    elseif action == "ClaimTestReward" then
        RewardService:GrantRewards(player, DemoConfig.AdminTestReward or { Coins = 100 })
        success = true
        message = "Test reward granted."
        self:_fireDataChanged(player)
    end

    return {
        Success = success,
        Message = message,
        Data = self:GetPlayerQuestData(player),
    }
end

return QuestService
