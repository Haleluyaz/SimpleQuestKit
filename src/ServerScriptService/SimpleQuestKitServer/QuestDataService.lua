local USE_DATA_STORE = false

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestConfig = require(ReplicatedStorage:WaitForChild("SimpleQuestKit"):WaitForChild("Config"):WaitForChild("QuestConfig"))
local QuestUtil = require(ReplicatedStorage:WaitForChild("SimpleQuestKit"):WaitForChild("Shared"):WaitForChild("QuestUtil"))

local DATASTORE_NAME = "SimpleQuestKit_v1"
local SAVE_COOLDOWN = 30

local QuestDataService = {
    _playerData = {},
    _lastSaveByUserId = {},
    _store = nil,
    _useDataStore = USE_DATA_STORE,
}

local function getDefaultQuestState(quest)
    return {
        Progress = 0,
        Completed = false,
        Claimed = false,
        LastReset = os.time(),
        UpdatedAt = os.time(),
    }
end

local function normalizeData(data)
    if type(data) ~= "table" then
        data = {}
    end

    data.Version = data.Version or 1
    data.Quests = type(data.Quests) == "table" and data.Quests or {}
    data.Currencies = type(data.Currencies) == "table" and data.Currencies or {}
    data.LastDailyReset = data.LastDailyReset or os.time()

    for _, quest in ipairs(QuestConfig.Quests or {}) do
        local questState = data.Quests[quest.Id]

        if type(questState) ~= "table" then
            data.Quests[quest.Id] = getDefaultQuestState(quest)
        else
            questState.Progress = tonumber(questState.Progress) or 0
            questState.Completed = questState.Completed == true
            questState.Claimed = questState.Claimed == true
            questState.LastReset = tonumber(questState.LastReset) or os.time()
            questState.UpdatedAt = tonumber(questState.UpdatedAt) or os.time()
        end
    end

    return data
end

function QuestDataService:Init()
    self._useDataStore = USE_DATA_STORE

    if self._useDataStore then
        local success, result = pcall(function()
            return DataStoreService:GetDataStore(DATASTORE_NAME)
        end)

        if success then
            self._store = result
            print("[SimpleQuestKit] QuestDataService running in DataStore Mode")
            return
        end

        self._store = nil
        self._useDataStore = false
        warn("[SimpleQuestKit] QuestDataService DataStore init failed. Falling back to Memory Mode: " .. tostring(result))
    end

    print("[SimpleQuestKit] QuestDataService running in Memory Mode")
end

function QuestDataService:LoadPlayer(player)
    if not self._useDataStore then
        local data = normalizeData(nil)
        data._Dirty = false

        self._playerData[player] = data
        return data
    end

    local key = "Player_" .. player.UserId
    local loadedData = nil

    local success, result = pcall(function()
        return self._store:GetAsync(key)
    end)

    if success then
        loadedData = result
    else
        warn("[SimpleQuestKit] DataStore load failed for " .. player.Name .. ": " .. tostring(result))
    end

    local data = normalizeData(loadedData)
    data._Dirty = false

    self._playerData[player] = data
    return data
end

function QuestDataService:SavePlayer(player, force)
    local data = self._playerData[player]
    if not data then
        return false
    end

    if not self._useDataStore then
        data._Dirty = false
        if force then
            print("[SimpleQuestKit] Memory Mode save skipped for " .. player.Name)
        end
        return true
    end

    local now = os.clock()
    local lastSave = self._lastSaveByUserId[player.UserId] or 0

    if not force and (not data._Dirty or now - lastSave < SAVE_COOLDOWN) then
        return true
    end

    local saveData = QuestUtil.CopyDictionary(data)
    saveData._Dirty = nil

    local key = "Player_" .. player.UserId
    local success, result = pcall(function()
        self._store:SetAsync(key, saveData)
    end)

    if success then
        data._Dirty = false
        self._lastSaveByUserId[player.UserId] = now
        return true
    end

    warn("[SimpleQuestKit] DataStore save failed for " .. player.Name .. ": " .. tostring(result))
    return false
end

function QuestDataService:GetData(player)
    return self._playerData[player]
end

function QuestDataService:GetOrLoadData(player)
    return self:GetData(player) or self:LoadPlayer(player)
end

function QuestDataService:MarkDirty(player)
    local data = self._playerData[player]
    if data then
        data._Dirty = true
    end
end

function QuestDataService:ReleasePlayer(player)
    self:SavePlayer(player, true)
    self._playerData[player] = nil
    self._lastSaveByUserId[player.UserId] = nil
end

function QuestDataService:IsStudio()
    return RunService:IsStudio()
end

return QuestDataService
