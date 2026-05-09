local QuestUtil = {}

function QuestUtil.ClampProgress(value, requiredAmount)
    value = tonumber(value) or 0
    requiredAmount = tonumber(requiredAmount) or 1
    return math.clamp(value, 0, requiredAmount)
end

function QuestUtil.GetQuestType(quest)
    if not quest then
        return nil
    end

    return quest.BaseType or quest.Type
end

function QuestUtil.IsCompleted(progress, requiredAmount)
    return (tonumber(progress) or 0) >= (tonumber(requiredAmount) or 1)
end

function QuestUtil.FindQuestById(questConfig, questId)
    for _, quest in ipairs(questConfig.Quests or {}) do
        if quest.Id == questId then
            return quest
        end
    end
    return nil
end

function QuestUtil.BuildQuestMap(questConfig)
    local questMap = {}

    for _, quest in ipairs(questConfig.Quests or {}) do
        questMap[quest.Id] = quest
    end

    return questMap
end

function QuestUtil.CopyDictionary(source)
    local result = {}

    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            result[key] = QuestUtil.CopyDictionary(value)
        else
            result[key] = value
        end
    end

    return result
end

function QuestUtil.FormatRewards(rewards)
    local parts = {}

    for rewardName, amount in pairs(rewards or {}) do
        table.insert(parts, tostring(amount) .. " " .. tostring(rewardName))
    end

    table.sort(parts)
    return table.concat(parts, ", ")
end

return QuestUtil
