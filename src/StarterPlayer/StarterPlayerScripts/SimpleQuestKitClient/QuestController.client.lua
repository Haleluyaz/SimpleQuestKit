-- Client quest data bridge.
-- Required core file. Buyers usually should not edit this.
-- Requests quest data, listens for server updates, and forwards claim clicks to the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local kit = ReplicatedStorage:WaitForChild("SimpleQuestKit", 10)
if not kit then
    warn("[SimpleQuestKit] ReplicatedStorage.SimpleQuestKit was not found after 10 seconds. QuestController stopped.")
    return
end

local configFolder = kit:WaitForChild("Config", 10)
if not configFolder then
    warn("[SimpleQuestKit] ReplicatedStorage.SimpleQuestKit.Config was not found after 10 seconds. QuestController stopped.")
    return
end

local demoConfigModule = configFolder:WaitForChild("DemoConfig", 10)
if not demoConfigModule then
    warn("[SimpleQuestKit] DemoConfig was not found after 10 seconds. QuestController stopped.")
    return
end

local DemoConfig = require(demoConfigModule)
local Debug = DemoConfig.Debug == true
local Remotes = kit:WaitForChild("Remotes", 10)
if not Remotes then
    warn("[SimpleQuestKit] ReplicatedStorage.SimpleQuestKit.Remotes was not found after 10 seconds. QuestController stopped.")
    return
end

local RequestQuestData = Remotes:WaitForChild("RequestQuestData", 10)
if not RequestQuestData then
    warn("[SimpleQuestKit] RequestQuestData remote was not found after 10 seconds. QuestController stopped.")
    return
end

local ClaimQuest = Remotes:WaitForChild("ClaimQuest", 10)
local QuestUpdated = Remotes:WaitForChild("QuestUpdated", 10)
local QuestClaimed = Remotes:WaitForChild("QuestClaimed", 10)
local OpenQuestUI = Remotes:WaitForChild("OpenQuestUI", 10)
local ClaimAllCompleted = Remotes:WaitForChild("ClaimAllCompleted", 10)
local TrackQuest = Remotes:WaitForChild("TrackQuest", 10)
local UntrackQuest = Remotes:WaitForChild("UntrackQuest", 10)

if not ClaimQuest or not QuestUpdated or not QuestClaimed or not OpenQuestUI or not ClaimAllCompleted or not TrackQuest or not UntrackQuest then
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
        local ui = getUI()
        if ui and ui.ShowError then
            ui:ShowError("Remote request failed. Check Output for the server error.")
        end

        warn("[SimpleQuestKit] Could not fetch quest data: " .. tostring(data))
    end
end

local ui = getUI()
if ui then
    ui:SetOnClaim(function(questId)
        local success, result = pcall(function()
            return ClaimQuest:InvokeServer(questId)
        end)

        if ui.ClearPendingClaim then
            ui:ClearPendingClaim(questId)
        end

        if not success then
            warn("[SimpleQuestKit] Could not claim quest: " .. tostring(result))
            if ui.ShowToast then
                ui:ShowToast("Claim Failed", "Could not claim this quest.")
            end
        elseif not result and ui.ShowToast then
            ui:ShowToast("Cannot Claim Yet", "Complete the quest before claiming.")
        end

        refresh()
    end)

    ui:SetOnClaimAll(function()
        if ui.SetClaimAllPending then
            ui:SetClaimAllPending(true)
        end

        local success, result = pcall(function()
            return ClaimAllCompleted:InvokeServer()
        end)

        if ui.SetClaimAllPending then
            ui:SetClaimAllPending(false)
        end

        if not success then
            warn("[SimpleQuestKit] Could not claim all quests: " .. tostring(result))
            if ui.ShowToast then
                ui:ShowToast("Claim All Failed", "Could not claim completed quests.")
            end
        elseif result and result.Claimed and ui.ShowToast then
            ui:ShowToast("Rewards Claimed", "Claimed all completed rewards.")
        elseif ui.ShowToast then
            ui:ShowToast("Nothing To Claim", "No completed rewards are ready.")
        end

        refresh()
    end)

    ui:SetOnTrack(function(questId)
        local success, result = pcall(function()
            return TrackQuest:InvokeServer(questId)
        end)

        if not success then
            warn("[SimpleQuestKit] Could not track quest: " .. tostring(result))
        elseif result and ui.ShowToast then
            ui:ShowToast("Quest Tracked", "Tracking quest progress.")
        end
    end)

    ui:SetOnUntrack(function()
        local success, result = pcall(function()
            return UntrackQuest:InvokeServer()
        end)

        if not success then
            warn("[SimpleQuestKit] Could not untrack quest: " .. tostring(result))
        elseif result and ui.ShowToast then
            ui:ShowToast("Quest Untracked", "Floating tracker cleared.")
        end
    end)
end

QuestUpdated.OnClientEvent:Connect(render)

QuestClaimed.OnClientEvent:Connect(function(questId, rewards)
    local rewardText = {}
    local questUi = getUI()

    for rewardName, amount in pairs(rewards or {}) do
        table.insert(rewardText, tostring(amount) .. " " .. tostring(rewardName))
    end

    table.sort(rewardText)

    local message = #rewardText > 0 and table.concat(rewardText, ", ") or "Reward claimed."

    if questUi and questUi.ShowToast then
        questUi:ShowToast("Reward Claimed", message)
    end

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Quest Complete",
            Text = message,
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

if Debug then
    print("[SimpleQuestKit] QuestController loaded")
end
