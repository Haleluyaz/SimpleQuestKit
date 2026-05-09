# Simple Quest Kit for Roblox

A small, Rojo-ready Roblox quest kit for beginner and intermediate developers.

## Features

- Config-based quests
- NPC quests
- Daily quests
- Collect quests
- Playtime quests
- Visit-area quests
- Interact quests
- Custom event quests
- Server-authoritative progress
- DataStore save/load
- Mobile-friendly UI
- Demo place: Starter Village Quest Demo

## Quick Start

```bash
cd SimpleQuestKit
rojo serve
```

Then open Roblox Studio, open the Rojo plugin, and connect to the local server.

Press Play. The kit creates a lightweight demo village with coins, a Guide NPC, a ForestZone, a MagicCrystal, a TreasureChest, a QuestBoard, and a portal endpoint.

## Build

```bash
rojo build -o SimpleQuestKit.rbxlx
```

## Included Quest Types

- `Collect`
- `Playtime`
- `VisitArea`
- `Interact`
- `CustomEvent`
- `Daily`

## Server API

Use these functions from trusted server scripts:

```lua
local QuestService = require(game.ServerScriptService.SimpleQuestKitServer.QuestService)

QuestService:AddProgress(player, questId, amount)
QuestService:SetProgress(player, questId, amount)
QuestService:CompleteQuest(player, questId)
QuestService:ClaimReward(player, questId)
QuestService:GetPlayerQuestData(player)
QuestService:ResetDailyQuests(player)
```

The client can fetch quest data and request reward claims, but it cannot award itself progress or rewards.

## Configuration

Edit quests in:

```text
src/ReplicatedStorage/SimpleQuestKit/Config/QuestConfig.lua
```

Quest data should stay in config. Demo objects use CollectionService tags and object attributes:

- `QuestCoin` with `QuestTarget = "Coin"`
- `QuestZone` with `QuestTarget = "ForestZone"`
- `QuestNPC` with `QuestTarget = "GuideNPC"`
- `QuestInteractable` with `QuestTarget`, `CustomEvent`, and `ActionText` as needed

## Demo Quest IDs

- `welcome_collect_coins`
- `visit_forest`
- `talk_to_guide`
- `crystal_power`
- `playtime_beginner`
- `custom_open_chest`
- `daily_collect_10_coins`

## Testing Checklist

- Start `rojo serve` and connect from Studio.
- Press Play Solo and confirm the quest button appears.
- Collect 5 coins and claim `First Steps`.
- Touch `ForestZone` and claim `Explore the Forest`.
- Talk to `GuideNPC` and claim `Meet the Guide`.
- Charge `MagicCrystal` 3 times and claim `Crystal Power`.
- Stay in game for 2 minutes and claim `Stay A While`.
- Open `TreasureChest` and claim `Treasure Hunter`.
- Collect 10 coins and claim `Daily Collector`.
- Stop and replay to confirm saved progress loads when Studio API services are enabled.

## Known Limitations

- The generated demo world is intentionally simple and meant for product testing, not a full game map.
- DataStore writes are throttled and wrapped in `pcall`, but Studio must have API services enabled to persist between sessions.
- Rewards are added to `leaderstats` as numeric values. Replace `RewardService` if your game uses an inventory or economy service.

## Packaging For Sale

1. Build with `rojo build -o SimpleQuestKit.rbxlx`.
2. Open the build in Roblox Studio and verify Play Solo.
3. Move `ReplicatedStorage.SimpleQuestKit`, `ServerScriptService.SimpleQuestKitServer`, `StarterPlayer.StarterPlayerScripts.SimpleQuestKitClient`, and the optional demo workspace folder into a clean place file or model.
4. Keep `QuestConfig.lua`, `DemoConfig.lua`, `docs/SETUP.md`, and this README with the product.
5. Publish as a Roblox model or wrap the inserted folders in a plugin installer button.
