local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DemoConfig = require(ReplicatedStorage:WaitForChild("SimpleQuestKit"):WaitForChild("Config"):WaitForChild("DemoConfig"))
local Debug = DemoConfig.Debug == true

local root = ServerScriptService:WaitForChild("SimpleQuestKitServer")

local QuestService = require(root:WaitForChild("QuestService"))
local QuestDataService = require(root:WaitForChild("QuestDataService"))
local RewardService = require(root:WaitForChild("RewardService"))
local QuestObjectService = require(root:WaitForChild("QuestObjectService"))
local DailyQuestService = require(root:WaitForChild("DailyQuestService"))

QuestDataService:Init()
RewardService:Init()
DailyQuestService:Init()
QuestService:Init()
QuestObjectService:Init()

if Debug then
    print("[SimpleQuestKit] Server bootstrap loaded")
end
