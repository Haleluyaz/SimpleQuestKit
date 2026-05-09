# Codex Prompt: Build Simple Quest Kit

You are a senior Roblox Luau developer.

I already have a Rojo-ready scaffold for a Roblox product called **Simple Quest Kit**.

Your job:
Implement the full Simple Quest Kit inside this existing project.

## Product Goal

Create a small commercial Roblox quest kit for beginner and intermediate developers.

It must be:
- Clean
- Config-driven
- Server-authoritative
- Mobile-friendly
- Easy to install
- Easy to reskin
- Easy to sell as a Roblox model/plugin

## Required Quest Types

1. Collect
2. Playtime
3. VisitArea
4. Interact
5. CustomEvent
6. Daily

## Required Public API

Implement this on the server:

```lua
QuestService:AddProgress(player, questId, amount)
QuestService:SetProgress(player, questId, amount)
QuestService:CompleteQuest(player, questId)
QuestService:ClaimReward(player, questId)
QuestService:GetPlayerQuestData(player)
QuestService:ResetDailyQuests(player)
```

## Required Core Features

1. Load quests from `QuestConfig.lua`
2. Track player progress per quest
3. Complete quest when progress reaches RequiredAmount
4. Claim rewards once
5. Save/load quest progress using DataStore
6. Support daily reset
7. Support NPC quest interaction
8. Support world object quest triggers
9. Support custom event progress
10. Create RemoteEvents/RemoteFunctions safely
11. Client cannot award itself progress or rewards
12. UI updates when server data changes

## Demo Quests

Use the quest IDs already in `QuestConfig.lua`:

- welcome_collect_coins
- visit_forest
- talk_to_guide
- crystal_power
- playtime_beginner
- custom_open_chest
- daily_collect_10_coins

## Demo World

Create scripts and setup instructions for:

1. Guide NPC
2. Coin pickups
3. ForestZone
4. MagicCrystal
5. TreasureChest
6. QuestBoard
7. Portal endpoint

Use CollectionService tags or object Attributes when useful.

## UI Requirements

Create a simple but polished quest UI:

- Quest button
- Quest panel
- Quest list
- Quest cards
- Progress bar
- Claim button
- Reward preview
- Daily quest section
- Completed state
- Smooth open/close tween
- Mobile-friendly size

## Technical Rules

- Use ModuleScripts
- No hardcoded quest data outside config
- Use pcall for DataStore
- Avoid excessive DataStore writes
- Use RemoteEvents/RemoteFunctions safely
- Add comments to public API functions
- Keep code readable for beginner Roblox developers
- Make it work in Roblox Studio Play Solo

## Implementation Order

1. Implement QuestUtil helpers if needed.
2. Implement QuestDataService with in-memory data first.
3. Implement QuestService logic.
4. Implement RewardService.
5. Add remotes in bootstrap.
6. Implement client QuestController.
7. Implement QuestUIController.
8. Implement QuestObjectService.
9. Implement DailyQuestService.
10. Add DataStore persistence.
11. Add demo setup docs.
12. Update README.

## Deliverables

- Full Luau code
- No empty TODO methods
- Updated README
- Updated setup docs
- Testing checklist
- Known limitations
- Instructions to package/sell as Roblox model/plugin

Keep the project small. Do not build a full game. This is a product demo and reusable quest kit.
