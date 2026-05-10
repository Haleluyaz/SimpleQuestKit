-- Connects tagged world objects to quest progress.
-- Required core file if you want tagged NPCs, pickups, zones, and interactables.
-- This keeps demo/world interaction logic separate from the core QuestService API.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local kit = ReplicatedStorage:WaitForChild("SimpleQuestKit")
local DemoConfig = require(kit:WaitForChild("Config"):WaitForChild("DemoConfig"))
local Debug = DemoConfig.Debug == true

local QuestService = require(script.Parent:WaitForChild("QuestService"))

local QuestObjectService = {
    _connections = {},
    _touchDebounce = {},
    _promptDebounce = {},
    _initializedInstances = {},
}

local function getTemporaryEffectsFolder()
    local folder = Workspace:FindFirstChild("TemporaryEffects")

    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "TemporaryEffects"
        folder.Parent = Workspace
    end

    return folder
end

local function getPlayerFromPart(part)
    local character = part and part:FindFirstAncestorOfClass("Model")

    while character and not character:FindFirstChildOfClass("Humanoid") do
        local parent = character.Parent
        if parent and parent:IsA("Model") then
            character = parent
        else
            character = parent and parent:FindFirstAncestorOfClass("Model") or nil
        end
    end

    if not character or not character:FindFirstChildOfClass("Humanoid") then
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
    if not player or type(target) ~= "string" or target == "" then
        return false
    end

    QuestService:AddProgressByTarget(player, target, amount or 1)
end

function QuestObjectService:_playChestOpen(instance)
    if instance:GetAttribute("OpenedVisual") then
        return
    end

    instance:SetAttribute("OpenedVisual", true)

    local parent = instance.Parent
    local lid = parent and parent:FindFirstChild(instance.Name .. "_Lid")

    if lid and lid:IsA("BasePart") then
        TweenService:Create(lid, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = lid.Position + Vector3.new(0, 1.1, 0.45),
            Orientation = lid.Orientation + Vector3.new(-25, 0, 0),
        }):Play()
    end

    local effectPart = Instance.new("Part")
    effectPart.Name = "ChestRewardGlow"
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.CanQuery = false
    effectPart.CanTouch = false
    effectPart.Transparency = 1
    effectPart.Size = Vector3.new(1, 1, 1)
    effectPart.CFrame = instance.CFrame
    effectPart.Parent = getTemporaryEffectsFolder()

    local sparkle = Instance.new("PointLight")
    sparkle.Name = "ChestRewardGlow"
    sparkle.Color = Color3.fromRGB(255, 219, 92)
    sparkle.Brightness = 2
    sparkle.Range = 12
    sparkle.Parent = effectPart
    Debris:AddItem(effectPart, 4)
end

function QuestObjectService:_setupCoin(coin)
    if not coin:IsA("BasePart") then
        return
    end

    if self._initializedInstances[coin] then
        return
    end
    self._initializedInstances[coin] = true

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

    if self._initializedInstances[zone] then
        return
    end
    self._initializedInstances[zone] = true

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
    if self._initializedInstances[instance] then
        return
    end
    self._initializedInstances[instance] = true

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
            QuestService:AddProgressByTarget(player, "InteractObject", 1)
            if instance.Name == "TreasureChest" then
                self:_playChestOpen(instance)
            end
        else
            self:_progressMatchingQuests(player, "Interact", target, 1)
            QuestService:AddProgressByTarget(player, "InteractObject", 1)
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

    if Debug then
        print("[SimpleQuestKit] QuestObjectService initialized")
    end
end

return QuestObjectService
