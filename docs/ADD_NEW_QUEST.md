# Add A New Quest

Most quests are added in two steps:

1. Add a quest table in `QuestConfig.lua`.
2. Add progress from a server script or a tagged world object.

Open:

```text
ReplicatedStorage/SimpleQuestKit/Config/QuestConfig.lua
```

Add your quest inside the `Quests = { ... }` list.

## Quest Fields

```lua
{
    Id = "my_quest_id",
    Title = "Quest Title",
    Description = "What the player should do.",
    Type = "Collect",
    Target = "Coin",
    RequiredAmount = 5,
    Rewards = { Coins = 100 },
    Category = "Main",
    Repeatable = false,
}
```

Important fields:

- `Id`: unique string used by scripts
- `Title`: shown in the UI
- `Description`: shown in the UI
- `Type`: `Collect`, `Playtime`, `VisitArea`, `Interact`, `CustomEvent`, or `Daily`
- `Target`: the object or event name the quest listens for
- `RequiredAmount`: progress needed to complete
- `Rewards`: table of reward names and amounts
- `Category`: shown in the UI
- `Repeatable`: usually `false`, daily quests use `true`

## Add Progress From Another Script

Use a server script:

```lua
local QuestService = require(game.ServerScriptService.SimpleQuestKitServer.QuestService)

local function onPlayerDidThing(player)
    QuestService:AddProgress(player, "my_quest_id", 1)
end
```

Only call this from server-verified actions. Do not let a LocalScript award progress.

## NPC Quest

Example quest:

```lua
{
    Id = "talk_to_blacksmith",
    Title = "Meet the Blacksmith",
    Description = "Talk to the blacksmith in town.",
    Type = "Interact",
    Target = "BlacksmithNPC",
    RequiredAmount = 1,
    Rewards = { Coins = 25 },
    Category = "NPC",
    Repeatable = false,
}
```

Create an NPC part or model with a `ProximityPrompt`.

Set attributes on the prompted part:

```text
QuestTarget = BlacksmithNPC
ActionText = Talk
```

Add the CollectionService tag:

```text
QuestNPC
```

When the prompt is triggered, `QuestObjectService` adds progress for matching `Interact` quests.

## Collect Quest

Example quest:

```lua
{
    Id = "collect_apples",
    Title = "Apple Basket",
    Description = "Collect 8 apples.",
    Type = "Collect",
    Target = "Apple",
    RequiredAmount = 8,
    Rewards = { Coins = 80 },
    Category = "Collect",
    Repeatable = false,
}
```

Create pickup parts and set:

```text
QuestTarget = Apple
RespawnSeconds = 8
```

Add the tag:

```text
QuestCoin
```

The tag name is configurable in `DemoConfig.DemoObjectTags.Coin`. The default pickup behavior hides the part briefly, then respawns it.

## Visit Area Quest

Example quest:

```lua
{
    Id = "visit_mine",
    Title = "Find the Mine",
    Description = "Walk into the mine entrance.",
    Type = "VisitArea",
    Target = "MineZone",
    RequiredAmount = 1,
    Rewards = { Coins = 50 },
    Category = "Explore",
    Repeatable = false,
}
```

Create an invisible or visible zone part.

Set:

```text
QuestTarget = MineZone
```

Add the tag:

```text
QuestZone
```

When the player's character touches it, the quest progresses.

## Interact Quest

Example quest:

```lua
{
    Id = "charge_totem",
    Title = "Ancient Totem",
    Description = "Interact with the totem 3 times.",
    Type = "Interact",
    Target = "AncientTotem",
    RequiredAmount = 3,
    Rewards = { Gems = 5 },
    Category = "Interact",
    Repeatable = false,
}
```

Create a part with a `ProximityPrompt`.

Set:

```text
QuestTarget = AncientTotem
ActionText = Charge
```

Add the tag:

```text
QuestInteractable
```

## Custom Event Quest

Use `CustomEvent` when progress comes from your own script or a special world action.

Example quest:

```lua
{
    Id = "open_boss_chest",
    Title = "Boss Loot",
    Description = "Open the boss chest.",
    Type = "CustomEvent",
    Target = "OpenBossChest",
    RequiredAmount = 1,
    Rewards = { Keys = 1 },
    Category = "Special",
    Repeatable = false,
}
```

From your own server script:

```lua
local QuestService = require(game.ServerScriptService.SimpleQuestKitServer.QuestService)

chestPrompt.Triggered:Connect(function(player)
    QuestService:AddProgress(player, "open_boss_chest", 1)
end)
```

Or use a tagged `QuestInteractable` and set:

```text
CustomEvent = OpenBossChest
ActionText = Open
```

## Daily Quest

Daily quests use `Type = "Daily"` plus `BaseType`.

Example:

```lua
{
    Id = "daily_collect_apples",
    Title = "Daily Apples",
    Description = "Collect 10 apples today.",
    Type = "Daily",
    BaseType = "Collect",
    Target = "Apple",
    RequiredAmount = 10,
    Rewards = { Coins = 200 },
    Category = "Daily",
    Repeatable = true,
    ResetSeconds = 86400,
}
```

`BaseType` tells the quest what kind of progress to listen for. In this example, apple pickups count toward the daily quest too.

## Playtime Quest

Example:

```lua
{
    Id = "play_10_minutes",
    Title = "Stay A While",
    Description = "Play for 10 minutes.",
    Type = "Playtime",
    Target = "Time",
    RequiredAmount = 600,
    Rewards = { Coins = 150 },
    Category = "Main",
    Repeatable = false,
}
```

`RequiredAmount` is seconds. The server adds playtime progress automatically.

## Claim Rewards

Players can claim completed quests from the included UI.

You can also claim from a server script:

```lua
local claimed = QuestService:ClaimReward(player, "my_quest_id")
```

The default `RewardService` adds rewards to `leaderstats`.
