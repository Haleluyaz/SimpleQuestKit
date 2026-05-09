local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DemoConfig = require(ReplicatedStorage:WaitForChild("SimpleQuestKit"):WaitForChild("Config"):WaitForChild("DemoConfig"))
local QuestConfig = require(ReplicatedStorage:WaitForChild("SimpleQuestKit"):WaitForChild("Config"):WaitForChild("QuestConfig"))
local QuestUtil = require(ReplicatedStorage:WaitForChild("SimpleQuestKit"):WaitForChild("Shared"):WaitForChild("QuestUtil"))
local Debug = DemoConfig.Debug == true

local DATA_VERSION = 1
local MAX_RETRIES = 3

local QuestDataService = {
    _playerData = {},
    _lastSaveByUserId = {},
    _store = nil,
    _useDataStore = DemoConfig.UseDataStore == true,
    _autoSaveStarted = false,
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

    data.DataVersion = tonumber(data.DataVersion or data.Version) or DATA_VERSION
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

local function getDataStoreKey(player)
    return "Player_" .. player.UserId
end

function QuestDataService:_tryDataStore(actionName, callback)
    local lastError = nil

    for attempt = 1, MAX_RETRIES do
        local success, result = pcall(callback)

        if success then
            return true, result
        end

        lastError = result

        if attempt < MAX_RETRIES then
            task.wait(attempt)
        end
    end

    return false, lastError
end

function QuestDataService:_fallbackToMemoryMode(reason)
    if self._useDataStore then
        warn("[SimpleQuestKit] QuestDataService falling back to Memory Mode: " .. tostring(reason))
    end

    self._store = nil
    self._useDataStore = false
end

function QuestDataService:_startAutoSave()
    if self._autoSaveStarted then
        return
    end

    self._autoSaveStarted = true

    task.spawn(function()
        while true do
            task.wait(tonumber(DemoConfig.AutoSaveInterval) or 60)

            if self._useDataStore then
                self:SaveAllPlayers(true)
            end
        end
    end)
end

function QuestDataService:Init()
    self._useDataStore = DemoConfig.UseDataStore == true

    if self._useDataStore then
        local success, result = self:_tryDataStore("GetDataStore", function()
            return DataStoreService:GetDataStore(DemoConfig.DataStoreName or "SimpleQuestKit_PlayerData_v1")
        end)

        if success then
            self._store = result
            self:_startAutoSave()

            game:BindToClose(function()
                self:SaveAllPlayers(true)
            end)

            if Debug then
                print("[SimpleQuestKit] QuestDataService running in DataStore Mode")
            end
            return
        end

        self:_fallbackToMemoryMode("DataStore init failed: " .. tostring(result))
    end

    if Debug then
        print("[SimpleQuestKit] QuestDataService running in Memory Mode")
    end
end

function QuestDataService:LoadPlayer(player)
    if not self._useDataStore then
        local data = normalizeData(nil)
        data._Dirty = false

        self._playerData[player] = data
        return data
    end

    local key = getDataStoreKey(player)
    local loadedData = nil

    local success, result = self:_tryDataStore("GetAsync", function()
        return self._store:GetAsync(key)
    end)

    if success then
        loadedData = result
    else
        self:_fallbackToMemoryMode("load failed for " .. player.Name .. ": " .. tostring(result))
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
        if Debug and force then
            print("[SimpleQuestKit] Memory Mode save skipped for " .. player.Name)
        end
        return true
    end

    if not force then
        return true
    end

    if not data._Dirty then
        return true
    end

    local saveData = QuestUtil.CopyDictionary(data)
    saveData._Dirty = nil

    local key = getDataStoreKey(player)
    local success, result = self:_tryDataStore("SetAsync", function()
        self._store:SetAsync(key, saveData)
    end)

    if success then
        data._Dirty = false
        self._lastSaveByUserId[player.UserId] = os.clock()
        return true
    end

    self:_fallbackToMemoryMode("save failed for " .. player.Name .. ": " .. tostring(result))
    return false
end

function QuestDataService:SaveAllPlayers(force)
    local allSaved = true

    for _, player in ipairs(Players:GetPlayers()) do
        local saved = self:SavePlayer(player, force)
        if not saved then
            allSaved = false
        end
    end

    return allSaved
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
