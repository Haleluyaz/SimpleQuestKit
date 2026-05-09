local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local kit = ReplicatedStorage:WaitForChild("SimpleQuestKit")
local Remotes = kit:WaitForChild("Remotes")

local RequestQuestData = Remotes:WaitForChild("RequestQuestData", 10)
if not RequestQuestData then
    warn("[SimpleQuestKit] RequestQuestData remote was not found after 10 seconds. QuestController stopped.")
    return
end

local ClaimQuest = Remotes:WaitForChild("ClaimQuest", 10)
local QuestUpdated = Remotes:WaitForChild("QuestUpdated", 10)
local QuestClaimed = Remotes:WaitForChild("QuestClaimed", 10)
local OpenQuestUI = Remotes:WaitForChild("OpenQuestUI", 10)

if not ClaimQuest or not QuestUpdated or not QuestClaimed or not OpenQuestUI then
    warn("[SimpleQuestKit] One or more quest remotes were not found after 10 seconds. QuestController stopped.")
    return
end

local function getUI()
    local startedAt = os.clock()

    while not _G.SimpleQuestKitUI and os.clock() - startedAt < 10 do
        task.wait()
    end

    return _G.SimpleQuestKitUI
end

local function render(data)
    local ui = getUI()
    if ui then
        ui:Render(data)
    end
end

local function refresh()
    local success, data = pcall(function()
        return RequestQuestData:InvokeServer()
    end)

    if success then
        render(data)
    else
        warn("[SimpleQuestKit] Could not fetch quest data: " .. tostring(data))
    end
end

local ui = getUI()
if ui then
    ui:SetOnClaim(function(questId)
        local success, result = pcall(function()
            return ClaimQuest:InvokeServer(questId)
        end)

        if not success then
            warn("[SimpleQuestKit] Could not claim quest: " .. tostring(result))
        end
    end)
end

QuestUpdated.OnClientEvent:Connect(render)

QuestClaimed.OnClientEvent:Connect(function(questId, rewards)
    local rewardText = {}

    for rewardName, amount in pairs(rewards or {}) do
        table.insert(rewardText, tostring(amount) .. " " .. tostring(rewardName))
    end

    table.sort(rewardText)

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Quest Complete",
            Text = "Claimed " .. table.concat(rewardText, ", "),
            Duration = 3,
        })
    end)
end)

OpenQuestUI.OnClientEvent:Connect(function()
    local questUi = getUI()
    if questUi then
        questUi:SetOpen(true)
    end
end)

refresh()

print("[SimpleQuestKit] QuestController loaded")
