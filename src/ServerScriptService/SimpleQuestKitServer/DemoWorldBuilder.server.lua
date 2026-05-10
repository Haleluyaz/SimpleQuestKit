-- Demo-only low-poly village builder.
-- Remove this file after replacing the showcase with your own map.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local DemoConfig = require(ReplicatedStorage:WaitForChild("SimpleQuestKit"):WaitForChild("Config"):WaitForChild("DemoConfig"))
local Debug = DemoConfig.Debug == true

local DEMO_ROOT_NAME = "SimpleQuestDemo"

if DemoConfig.BuildDemoWorld ~= true then
    local existingDemo = Workspace:FindFirstChild(DEMO_ROOT_NAME)

    if existingDemo then
        existingDemo:Destroy()
    end

    if Debug then
        print("[SimpleQuestKit] Demo world builder skipped. Set DemoConfig.BuildDemoWorld = true to load the sample village.")
    end

    return
end

local COLORS = {
    Grass = Color3.fromRGB(108, 166, 103),
    Path = Color3.fromRGB(189, 168, 126),
    Wood = Color3.fromRGB(126, 82, 48),
    DarkWood = Color3.fromRGB(92, 58, 35),
    Sign = Color3.fromRGB(245, 232, 184),
    Coin = Color3.fromRGB(255, 205, 66),
    Forest = Color3.fromRGB(68, 132, 79),
    Crystal = Color3.fromRGB(134, 95, 226),
    Blue = Color3.fromRGB(80, 134, 198),
    Chest = Color3.fromRGB(150, 91, 48),
    Portal = Color3.fromRGB(79, 194, 210),
    White = Color3.fromRGB(250, 250, 245),
}

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
    local part = nil

    if existing and existing:IsA("BasePart") then
        part = existing
    else
        part = Instance.new("Part")
        part.Name = name
        part.Parent = parent
    end

    part.Size = size
    part.Position = position
    part.Color = color
    part.Anchored = anchored ~= false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth

    return part
end

local function makeSpawn(parent, name, position)
    local existing = parent:FindFirstChild(name)
    local spawn = nil

    if existing and existing:IsA("SpawnLocation") then
        spawn = existing
    else
        if existing then
            existing:Destroy()
        end

        spawn = Instance.new("SpawnLocation")
        spawn.Name = name
        spawn.Parent = parent
    end

    spawn.Size = Vector3.new(8, 0.35, 8)
    spawn.Position = position
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.CanCollide = true
    spawn.Transparency = 0.25
    spawn.Color = Color3.fromRGB(116, 174, 132)
    spawn.Material = Enum.Material.SmoothPlastic

    return spawn
end

local function addPrompt(part, actionText, objectText)
    local prompt = part:FindFirstChildWhichIsA("ProximityPrompt")

    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.Parent = part
    end

    prompt.ActionText = actionText
    prompt.ObjectText = objectText or part.Name
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0.15
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
end

local function addBillboard(part, name, text, size, offset, backgroundColor, textColor)
    local existing = part:FindFirstChild(name)
    if existing then
        existing:Destroy()
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = name
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 80
    billboard.Size = size or UDim2.fromOffset(170, 44)
    billboard.StudsOffset = offset or Vector3.new(0, 4, 0)
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.BackgroundColor3 = backgroundColor or COLORS.Sign
    label.BackgroundTransparency = 0.05
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.Size = UDim2.fromScale(1, 1)
    label.Text = text
    label.TextColor3 = textColor or Color3.fromRGB(42, 35, 28)
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
end

local function addStandingSign(parent, name, position, title, body)
    local post = makePart(parent, name .. "_Post", Vector3.new(0.35, 4, 0.35), position + Vector3.new(0, 2, 0), COLORS.DarkWood, true)
    local board = makePart(parent, name, Vector3.new(7, 3, 0.35), position + Vector3.new(0, 4.1, 0), COLORS.Sign, true)

    addBillboard(board, "SignText", title .. "\n" .. body, UDim2.fromOffset(220, 82), Vector3.new(0, 0.25, 0), Color3.fromRGB(250, 239, 198))
    return board, post
end

local function makeHouse(parent, name, position, wallColor, roofColor)
    local base = makePart(parent, name .. "_Base", Vector3.new(10, 6, 8), position + Vector3.new(0, 3, 0), wallColor, true)
    local roof = makePart(parent, name .. "_Roof", Vector3.new(12, 2, 10), position + Vector3.new(0, 7.3, 0), roofColor, true)
    roof.Rotation = Vector3.new(0, 0, 0)

    local door = makePart(parent, name .. "_Door", Vector3.new(2.2, 3.2, 0.25), position + Vector3.new(0, 1.8, -4.15), COLORS.DarkWood, true)
    local windowLeft = makePart(parent, name .. "_WindowLeft", Vector3.new(1.5, 1.5, 0.25), position + Vector3.new(-3, 3.8, -4.2), Color3.fromRGB(129, 190, 210), true)
    local windowRight = makePart(parent, name .. "_WindowRight", Vector3.new(1.5, 1.5, 0.25), position + Vector3.new(3, 3.8, -4.2), Color3.fromRGB(129, 190, 210), true)

    base.Material = Enum.Material.WoodPlanks
    roof.Material = Enum.Material.WoodPlanks
    door.Material = Enum.Material.Wood
    windowLeft.Material = Enum.Material.Glass
    windowRight.Material = Enum.Material.Glass
end

local function makeTree(parent, name, position)
    local trunk = makePart(parent, name .. "_Trunk", Vector3.new(1.4, 5, 1.4), position + Vector3.new(0, 2.5, 0), COLORS.DarkWood, true)
    local leaves = makePart(parent, name .. "_Leaves", Vector3.new(5, 5, 5), position + Vector3.new(0, 6, 0), Color3.fromRGB(54, 126, 75), true)
    leaves.Shape = Enum.PartType.Ball
    trunk.Material = Enum.Material.Wood
end

local function animateFloatAndSpin(part, height, seconds)
    if not part:IsA("BasePart") then
        return
    end

    local basePosition = part.Position

    task.spawn(function()
        while part.Parent do
            local upTween = TweenService:Create(part, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Position = basePosition + Vector3.new(0, height, 0),
                Orientation = part.Orientation + Vector3.new(0, 180, 0),
            })

            upTween:Play()
            upTween.Completed:Wait()

            if not part.Parent then
                break
            end

            local downTween = TweenService:Create(part, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Position = basePosition,
                Orientation = part.Orientation + Vector3.new(0, 180, 0),
            })

            downTween:Play()
            downTween.Completed:Wait()
        end
    end)
end

local root = getFolder(Workspace, DEMO_ROOT_NAME)
root:SetAttribute("GeneratedBySimpleQuestKitDemo", true)
local collectibles = getFolder(root, "Collectibles")
local npcs = getFolder(root, "NPCs")
local zones = getFolder(root, "Zones")
local interactables = getFolder(root, "Interactables")
local environment = getFolder(root, "Environment")
local signs = getFolder(root, "Signs")

local ground = makePart(environment, "VillageGreen", Vector3.new(100, 1, 80), Vector3.new(5, -1.05, 0), COLORS.Grass, true)
ground.Material = Enum.Material.Grass
ground.CanCollide = false

local spawn = makeSpawn(environment, "DemoSpawn", Vector3.new(-12, 0.25, -4))
addBillboard(spawn, "SpawnHint", "Simple Quest Kit Demo\nTalk to the Guide NPC to begin", UDim2.fromOffset(300, 62), Vector3.new(0, 4.2, 0), Color3.fromRGB(235, 243, 255))

local mainPath = makePart(environment, "MainPath", Vector3.new(78, 0.12, 7), Vector3.new(8, 0.16, -4), COLORS.Path, true)
local crossPath = makePart(environment, "CrossPath", Vector3.new(7, 0.12, 48), Vector3.new(0, 0.17, 2), COLORS.Path, true)
local plaza = makePart(environment, "VillagePlaza", Vector3.new(22, 0.12, 18), Vector3.new(0, 0.18, -4), Color3.fromRGB(203, 183, 140), true)
mainPath.CanCollide = false
crossPath.CanCollide = false
plaza.CanCollide = false

makeHouse(environment, "BlueHut", Vector3.new(-30, 0, -18), Color3.fromRGB(164, 189, 202), Color3.fromRGB(69, 105, 145))
makeHouse(environment, "GreenHut", Vector3.new(26, 0, -20), Color3.fromRGB(170, 196, 157), Color3.fromRGB(77, 121, 82))

for index, position in ipairs({
    Vector3.new(-42, 0, 20),
    Vector3.new(-34, 0, 28),
    Vector3.new(36, 0, 19),
    Vector3.new(42, 0, 29),
    Vector3.new(48, 0, -18),
}) do
    makeTree(environment, "VillageTree" .. index, position)
end

addStandingSign(signs, "OnboardingSign", Vector3.new(-9, 0, -12), "START HERE", "Talk to the Guide to start\nThen collect coins and claim")
addStandingSign(signs, "NpcQuestSign", Vector3.new(-4, 0, -25), "NPC Quest", "Talk to the Guide")
addStandingSign(signs, "CollectQuestSign", Vector3.new(-24, 0, 8), "Collect Quest", "Pick up 10 coins")
addStandingSign(signs, "VisitAreaQuestSign", Vector3.new(31, 0, 15), "Visit Area Quest", "Enter the ForestZone")
addStandingSign(signs, "InteractQuestSign", Vector3.new(-28, 0, -1), "Interact Quest", "Charge the crystal")
addStandingSign(signs, "CustomEventQuestSign", Vector3.new(-29, 0, -16), "Custom Event Quest", "Open the chest")
addStandingSign(signs, "DailyQuestSign", Vector3.new(15, 0, 12), "Daily Quest", "Repeatable daily goal")
addStandingSign(signs, "WeeklyQuestSign", Vector3.new(18, 0, 22), "Weekly Quest", "Longer weekly goals")
addStandingSign(signs, "AchievementQuestSign", Vector3.new(18, 0, 31), "Achievement Quest", "Long-term one-time goals")
addStandingSign(signs, "EventQuestSign", Vector3.new(31, 0, 31), "Event Quest", "Limited-time rewards")

for index, signInfo in ipairs({
    { "Config Based", "Edit QuestConfig, not core scripts" },
    { "Daily Quests", "3 selected per player per UTC day" },
    { "Weekly Quests", "3-5 selected per player per week" },
    { "Event Quests", "Seasonal limited-time goals" },
    { "Achievement Quests", "Permanent long-term progress" },
    { "Server Authoritative", "Progress and rewards stay on server" },
    { "Mobile Ready", "Tabs, cards, tracker, and toasts" },
    { "Easy Rewards", "Customize RewardService handlers" },
    { "Use AddProgressByTarget", "One call can update many quests" },
}) do
    local row = math.floor((index - 1) / 4)
    local column = (index - 1) % 4
    addStandingSign(
        signs,
        "BuyerInfo_" .. index,
        Vector3.new(-40 + column * 13, 0, 33 + row * 8),
        signInfo[1],
        signInfo[2]
    )
end

for index = 1, 10 do
    local row = math.floor((index - 1) / 5)
    local column = (index - 1) % 5
    local coin = makePart(
        collectibles,
        "Coin" .. index,
        Vector3.new(1, 0.25, 1),
        Vector3.new(-20 + column * 4, 1.4, 5 + row * 5),
        COLORS.Coin,
        true
    )

    coin.Shape = Enum.PartType.Cylinder
    coin.Orientation = Vector3.new(0, 0, 90)
    coin.Material = Enum.Material.Metal
    coin:SetAttribute("QuestTarget", "Coin")
    coin:SetAttribute("RespawnSeconds", 8)
    CollectionService:AddTag(coin, "QuestCoin")
    animateFloatAndSpin(coin, 0.35, 0.9)
end

local guideBody = makePart(npcs, "GuideNPC", Vector3.new(3, 5, 2), Vector3.new(0, 2.5, -18), COLORS.Blue, true)
guideBody:SetAttribute("QuestTarget", "GuideNPC")
guideBody:SetAttribute("DisplayName", "Village Guide")
guideBody:SetAttribute("ActionText", "Talk")
guideBody.Material = Enum.Material.SmoothPlastic
addPrompt(guideBody, "Talk", "Village Guide")
addBillboard(guideBody, "GuideName", "Village Guide", UDim2.fromOffset(140, 34), Vector3.new(0, 4.2, 0), Color3.fromRGB(235, 243, 255))
addBillboard(guideBody, "GuideQuestHint", "Talk to me\nthen collect coins", UDim2.fromOffset(150, 52), Vector3.new(0, 6.1, 0), Color3.fromRGB(255, 246, 190))
CollectionService:AddTag(guideBody, "QuestNPC")

local guideHead = makePart(npcs, "GuideNPC_Head", Vector3.new(2.2, 2.2, 2.2), Vector3.new(0, 6.1, -18), Color3.fromRGB(236, 202, 153), true)
guideHead.Shape = Enum.PartType.Ball
local exclamation = makePart(npcs, "GuideNPC_Exclamation", Vector3.new(0.75, 2.4, 0.35), Vector3.new(0, 9.2, -18), Color3.fromRGB(255, 220, 75), true)
exclamation.Material = Enum.Material.Neon
local dot = makePart(npcs, "GuideNPC_ExclamationDot", Vector3.new(0.8, 0.8, 0.8), Vector3.new(0, 7.6, -18), Color3.fromRGB(255, 220, 75), true)
dot.Shape = Enum.PartType.Ball
dot.Material = Enum.Material.Neon

local forestZone = makePart(zones, "ForestZone", Vector3.new(24, 8, 18), Vector3.new(35, 4, 4), COLORS.Forest, true)
forestZone.Transparency = 1
forestZone.Material = Enum.Material.SmoothPlastic
forestZone.CanCollide = false
forestZone.CanTouch = true
forestZone:SetAttribute("QuestTarget", "ForestZone")
CollectionService:AddTag(forestZone, "QuestZone")
addStandingSign(signs, "ForestZoneSign", Vector3.new(35, 0, -8), "ForestZone", "Visit this area")

local forestMarkerNorth = makePart(zones, "ForestZone_MarkerNorth", Vector3.new(24, 0.35, 0.35), Vector3.new(35, 1.1, -5), COLORS.Forest, true)
local forestMarkerSouth = makePart(zones, "ForestZone_MarkerSouth", Vector3.new(24, 0.35, 0.35), Vector3.new(35, 1.1, 13), COLORS.Forest, true)
local forestMarkerWest = makePart(zones, "ForestZone_MarkerWest", Vector3.new(0.35, 0.35, 18), Vector3.new(23, 1.1, 4), COLORS.Forest, true)
local forestMarkerEast = makePart(zones, "ForestZone_MarkerEast", Vector3.new(0.35, 0.35, 18), Vector3.new(47, 1.1, 4), COLORS.Forest, true)

for _, marker in ipairs({ forestMarkerNorth, forestMarkerSouth, forestMarkerWest, forestMarkerEast }) do
    marker.Material = Enum.Material.Wood
    marker.CanCollide = false
    marker.CanTouch = false
end

local crystalBase = makePart(interactables, "MagicCrystal_Base", Vector3.new(5, 1, 5), Vector3.new(-23, 0.5, -3), COLORS.DarkWood, true)
local crystal = makePart(interactables, "MagicCrystal", Vector3.new(3, 6, 3), Vector3.new(-23, 4, -3), COLORS.Crystal, true)
crystal.Material = Enum.Material.Neon
crystal:SetAttribute("QuestTarget", "MagicCrystal")
crystal:SetAttribute("ActionText", "Charge")
addPrompt(crystal, "Charge", "Magic Crystal")
CollectionService:AddTag(crystal, "QuestInteractable")

local crystalLight = crystal:FindFirstChild("CrystalGlow") or Instance.new("PointLight")
crystalLight.Name = "CrystalGlow"
crystalLight.Color = COLORS.Crystal
crystalLight.Brightness = 2
crystalLight.Range = 18
crystalLight.Parent = crystal
crystalBase.Material = Enum.Material.Wood
animateFloatAndSpin(crystal, 0.25, 1.35)

local chest = makePart(interactables, "TreasureChest", Vector3.new(5, 2.5, 3), Vector3.new(-25, 1.25, -16), COLORS.Chest, true)
chest:SetAttribute("CustomEvent", "OpenChest")
chest:SetAttribute("ActionText", "Open")
chest.Material = Enum.Material.Wood
addPrompt(chest, "Open", "Treasure Chest")
CollectionService:AddTag(chest, "QuestInteractable")
makePart(interactables, "TreasureChest_Lid", Vector3.new(5.4, 0.7, 3.3), Vector3.new(-25, 2.9, -16), Color3.fromRGB(113, 65, 35), true)
makePart(interactables, "TreasureChest_Lock", Vector3.new(0.8, 0.8, 0.25), Vector3.new(-25, 1.6, -17.55), COLORS.Coin, true)

local chestLight = chest:FindFirstChild("ChestSparkle") or Instance.new("PointLight")
chestLight.Name = "ChestSparkle"
chestLight.Color = COLORS.Coin
chestLight.Brightness = 0.8
chestLight.Range = 10
chestLight.Parent = chest

local board = makePart(interactables, "QuestBoard", Vector3.new(7, 5, 0.6), Vector3.new(9, 2.8, -16), COLORS.Wood, true)
board:SetAttribute("QuestTarget", "QuestBoard")
board:SetAttribute("ActionText", "View Quests")
board.Material = Enum.Material.WoodPlanks
addPrompt(board, "View Quests", "Quest Board")
addBillboard(board, "QuestBoardText", "QUEST BOARD\nOpen UI", UDim2.fromOffset(190, 70), Vector3.new(0, 0.2, -0.2), Color3.fromRGB(244, 230, 174))
CollectionService:AddTag(board, "QuestInteractable")

local portal = makePart(interactables, "DemoEndPortal", Vector3.new(5, 8, 1), Vector3.new(48, 4, -4), COLORS.Portal, true)
portal.Material = Enum.Material.Neon
portal:SetAttribute("QuestTarget", "DemoEndPortal")
portal:SetAttribute("ActionText", "Finish Demo")
addPrompt(portal, "Finish Demo", "Demo Portal")
CollectionService:AddTag(portal, "QuestInteractable")

local portalLight = portal:FindFirstChild("PortalGlow") or Instance.new("PointLight")
portalLight.Name = "PortalGlow"
portalLight.Color = portal.Color
portalLight.Brightness = 1.5
portalLight.Range = 14
portalLight.Parent = portal
addBillboard(portal, "PortalText", "Demo End\nReview the UI tabs", UDim2.fromOffset(170, 54), Vector3.new(0, 5, 0), Color3.fromRGB(226, 250, 252))
animateFloatAndSpin(portal, 0.15, 1.6)

if Debug then
    print("[SimpleQuestKit] Polished demo village loaded")
end
