local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local kit = ReplicatedStorage:WaitForChild("SimpleQuestKit")
local DemoConfig = require(kit:WaitForChild("Config"):WaitForChild("DemoConfig"))
local QuestConfig = require(kit:WaitForChild("Config"):WaitForChild("QuestConfig"))
local QuestUtil = require(kit:WaitForChild("Shared"):WaitForChild("QuestUtil"))

local QuestService = require(script.Parent:WaitForChild("QuestService"))

local QuestObjectService = {
    _connections = {},
    _touchDebounce = {},
    _promptDebounce = {},
    _questMap = QuestUtil.BuildQuestMap(QuestConfig),
}

local function getPlayerFromPart(part)
    local character = part and part.Parent
    if not character then
        return nil
    end

    return Players:GetPlayerFromCharacter(character)
end

local function getOrCreatePrompt(instance, actionText)
    local prompt = instance:FindFirstChildWhichIsA("ProximityPrompt", true)

    if prompt then
        return prompt
    end

    prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = actionText
    prompt.ObjectText = instance:GetAttribute("DisplayName") or instance.Name
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0.15
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = instance:IsA("BasePart") and instance or instance:FindFirstChildWhichIsA("BasePart") or instance

    return prompt
end

function QuestObjectService:_connect(instance, connection)
    table.insert(self._connections, connection)

    instance.Destroying:Connect(function()
        connection:Disconnect()
    end)
end

function QuestObjectService:_progressMatchingQuests(player, questType, target, amount)
    for _, quest in ipairs(QuestConfig.Quests or {}) do
        local effectiveType = QuestUtil.GetQuestType(quest)

        if effectiveType == questType and quest.Target == target then
            QuestService:AddProgress(player, quest.Id, amount or 1)
        end
    end
end

function QuestObjectService:_setupCoin(coin)
    if not coin:IsA("BasePart") then
        return
    end

    coin.CanTouch = true

    self:_connect(coin, coin.Touched:Connect(function(hit)
        local player = getPlayerFromPart(hit)
        if not player or not coin.Transparency or coin.Transparency >= 1 then
            return
        end

        local key = player.UserId .. ":" .. tostring(coin)
        if self._touchDebounce[key] then
            return
        end

        self._touchDebounce[key] = true
        self:_progressMatchingQuests(player, "Collect", coin:GetAttribute("QuestTarget") or "Coin", 1)

        coin.Transparency = 1
        coin.CanTouch = false

        task.delay(tonumber(coin:GetAttribute("RespawnSeconds")) or DemoConfig.CoinRespawnSeconds or 8, function()
            if coin.Parent then
                coin.Transparency = 0
                coin.CanTouch = true
                self._touchDebounce[key] = nil
            end
        end)
    end))
end

function QuestObjectService:_setupZone(zone)
    if not zone:IsA("BasePart") then
        return
    end

    zone.CanTouch = true

    self:_connect(zone, zone.Touched:Connect(function(hit)
        local player = getPlayerFromPart(hit)
        if not player then
            return
        end

        local target = zone:GetAttribute("QuestTarget") or zone.Name
        local key = player.UserId .. ":" .. target

        if self._touchDebounce[key] then
            return
        end

        self._touchDebounce[key] = true
        self:_progressMatchingQuests(player, "VisitArea", target, 1)

        task.delay(2, function()
            self._touchDebounce[key] = nil
        end)
    end))
end

function QuestObjectService:_setupPromptObject(instance)
    local target = instance:GetAttribute("QuestTarget") or instance.Name
    local prompt = getOrCreatePrompt(instance, instance:GetAttribute("ActionText") or "Interact")

    self:_connect(instance, prompt.Triggered:Connect(function(player)
        local key = player.UserId .. ":" .. tostring(instance)
        if self._promptDebounce[key] then
            return
        end

        self._promptDebounce[key] = true

        if target == "QuestBoard" then
            local remotes = kit:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("OpenQuestUI") then
                remotes.OpenQuestUI:FireClient(player)
            end
        elseif instance:GetAttribute("CustomEvent") then
            self:_progressMatchingQuests(player, "CustomEvent", instance:GetAttribute("CustomEvent"), 1)
        else
            self:_progressMatchingQuests(player, "Interact", target, 1)
        end

        task.delay(0.75, function()
            self._promptDebounce[key] = nil
        end)
    end))
end

function QuestObjectService:_setupExisting(tagName, setupFunction)
    for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
        setupFunction(self, instance)
    end

    CollectionService:GetInstanceAddedSignal(tagName):Connect(function(instance)
        setupFunction(self, instance)
    end)
end

function QuestObjectService:Init()
    local tags = DemoConfig.DemoObjectTags or {}

    self:_setupExisting(tags.Coin or "QuestCoin", self._setupCoin)
    self:_setupExisting(tags.Zone or "QuestZone", self._setupZone)
    self:_setupExisting(tags.NPC or "QuestNPC", self._setupPromptObject)
    self:_setupExisting(tags.Interactable or "QuestInteractable", self._setupPromptObject)

    print("[SimpleQuestKit] QuestObjectService initialized")
end

return QuestObjectService
