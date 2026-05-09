local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DemoConfig = require(ReplicatedStorage:WaitForChild("SimpleQuestKit"):WaitForChild("Config"):WaitForChild("DemoConfig"))
local Debug = DemoConfig.Debug == true

local RewardService = {}

function RewardService:Init()
    if Debug then
        print("[SimpleQuestKit] RewardService initialized")
    end
end

function RewardService:GrantRewards(player, rewards)
    if type(rewards) ~= "table" then
        return
    end

    local leaderstats = player:FindFirstChild("leaderstats")

    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    for rewardName, amount in pairs(rewards) do
        local rewardAmount = tonumber(amount) or 0
        local value = leaderstats:FindFirstChild(rewardName)

        if not value then
            value = Instance.new("IntValue")
            value.Name = rewardName
            value.Value = 0
            value.Parent = leaderstats
        end

        if value:IsA("IntValue") or value:IsA("NumberValue") then
            value.Value += rewardAmount
        end
    end
end

return RewardService
