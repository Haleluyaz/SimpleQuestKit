local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestConfig = require(ReplicatedStorage:WaitForChild("SimpleQuestKit"):WaitForChild("Config"):WaitForChild("QuestConfig"))

local DailyQuestService = {
    _questDataService = nil,
}

function DailyQuestService:Init()
    self._questDataService = require(script.Parent:WaitForChild("QuestDataService"))

    task.spawn(function()
        while true do
            task.wait(60)
            self:ResetExpiredDailiesForAllPlayers()
        end
    end)

    print("[SimpleQuestKit] DailyQuestService initialized")
end

function DailyQuestService:ResetExpiredDailies(player)
    local QuestService = require(script.Parent:WaitForChild("QuestService"))
    local data = self._questDataService:GetData(player)

    if not data then
        return false
    end

    local now = os.time()
    local didReset = false

    for _, quest in ipairs(QuestConfig.Quests or {}) do
        if quest.Type == "Daily" then
            local state = data.Quests[quest.Id]
            local resetSeconds = quest.ResetSeconds or 86400

            if state and now - (state.LastReset or 0) >= resetSeconds then
                QuestService:ResetDailyQuests(player)
                didReset = true
                break
            end
        end
    end

    return didReset
end

function DailyQuestService:ResetExpiredDailiesForAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        self:ResetExpiredDailies(player)
    end
end

return DailyQuestService
