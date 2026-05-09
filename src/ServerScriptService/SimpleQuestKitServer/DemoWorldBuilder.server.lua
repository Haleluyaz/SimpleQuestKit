local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local DEMO_ROOT_NAME = "SimpleQuestDemo"

local function getFolder(parent, name)
    local folder = parent:FindFirstChild(name)

    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end

    return folder
end

local function makePart(parent, name, size, position, color, anchored)
    local existing = parent:FindFirstChild(name)

    if existing and existing:IsA("BasePart") then
        return existing
    end

    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Color = color
    part.Anchored = anchored ~= false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent

    return part
end

local function addPrompt(part, actionText)
    local prompt = part:FindFirstChildWhichIsA("ProximityPrompt")

    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.Parent = part
    end

    prompt.ActionText = actionText
    prompt.ObjectText = part.Name
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0.15
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
end

local root = getFolder(Workspace, DEMO_ROOT_NAME)
local collectibles = getFolder(root, "Collectibles")
local npcs = getFolder(root, "NPCs")
local zones = getFolder(root, "Zones")
local interactables = getFolder(root, "Interactables")
local environment = getFolder(root, "Environment")

for index = 1, 10 do
    local angle = (math.pi * 2 / 10) * index
    local coin = makePart(
        collectibles,
        "Coin" .. index,
        Vector3.new(1, 0.25, 1),
        Vector3.new(math.cos(angle) * 14, 2, math.sin(angle) * 14),
        Color3.fromRGB(255, 205, 66),
        true
    )

    coin.Shape = Enum.PartType.Cylinder
    coin:SetAttribute("QuestTarget", "Coin")
    coin:SetAttribute("RespawnSeconds", 8)
    CollectionService:AddTag(coin, "QuestCoin")
end

local guide = makePart(npcs, "GuideNPC", Vector3.new(3, 6, 3), Vector3.new(0, 3, -18), Color3.fromRGB(88, 141, 199), true)
guide:SetAttribute("QuestTarget", "GuideNPC")
guide:SetAttribute("DisplayName", "Village Guide")
guide:SetAttribute("ActionText", "Talk")
addPrompt(guide, "Talk")
CollectionService:AddTag(guide, "QuestNPC")

local forestZone = makePart(zones, "ForestZone", Vector3.new(22, 1, 18), Vector3.new(34, 1, 0), Color3.fromRGB(76, 151, 96), true)
forestZone.Transparency = 0.45
forestZone:SetAttribute("QuestTarget", "ForestZone")
CollectionService:AddTag(forestZone, "QuestZone")

local crystal = makePart(interactables, "MagicCrystal", Vector3.new(3, 6, 3), Vector3.new(-18, 3, 8), Color3.fromRGB(117, 82, 204), true)
crystal.Material = Enum.Material.Neon
crystal:SetAttribute("QuestTarget", "MagicCrystal")
crystal:SetAttribute("ActionText", "Charge")
addPrompt(crystal, "Charge")
CollectionService:AddTag(crystal, "QuestInteractable")

local chest = makePart(interactables, "TreasureChest", Vector3.new(5, 3, 3), Vector3.new(-18, 1.5, -8), Color3.fromRGB(157, 98, 54), true)
chest:SetAttribute("CustomEvent", "OpenChest")
chest:SetAttribute("ActionText", "Open")
addPrompt(chest, "Open")
CollectionService:AddTag(chest, "QuestInteractable")

local board = makePart(interactables, "QuestBoard", Vector3.new(6, 5, 1), Vector3.new(8, 2.5, -18), Color3.fromRGB(118, 82, 50), true)
board:SetAttribute("QuestTarget", "QuestBoard")
board:SetAttribute("ActionText", "View Quests")
addPrompt(board, "View Quests")
CollectionService:AddTag(board, "QuestInteractable")

local portal = makePart(environment, "PortalEndpoint", Vector3.new(5, 8, 1), Vector3.new(44, 4, 0), Color3.fromRGB(79, 194, 210), true)
portal.Material = Enum.Material.Neon

print("[SimpleQuestKit] Demo world builder loaded")
