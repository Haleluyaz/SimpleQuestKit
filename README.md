# Simple Quest Kit for Roblox

Simple Quest Kit is a small, server-authoritative quest system for Roblox games. It is built for beginner and intermediate developers who want a clean quest board, demo objects, rewards, daily quests, and optional DataStore saving without building a full game framework.

The kit is Rojo-ready, works in Studio Play Solo, and includes a lightweight Starter Village showcase.

## What You Get

- Config-driven quests in one `QuestConfig.lua` file
- Quest types: `Collect`, `Playtime`, `VisitArea`, `Interact`, `CustomEvent`, and `Daily`
- Server API for adding progress, completing quests, claiming rewards, and reading player data
- Mobile-friendly quest UI
- Guide NPC, coins, ForestZone, MagicCrystal, TreasureChest, QuestBoard, and labeled demo signs
- Memory Mode by default for easy Studio testing
- Optional production DataStore persistence
- Beginner-friendly documentation and example snippets
- Release files: changelog, license placeholder, packaging guide, and testing checklist

## Quick Start With Rojo

```bash
cd SimpleQuestKit
rojo serve
```

Open Roblox Studio, open the Rojo plugin, connect to the local server, then press Play.

You should see the Starter Village demo and a `Quests` button. Talk to the Guide NPC, collect coins, open the quest board, and claim rewards.

## Manual Studio Install

If you are not using Rojo, copy these folders into the matching Roblox Studio services:

| Folder | Studio Location |
| --- | --- |
| `src/ReplicatedStorage/SimpleQuestKit` | `ReplicatedStorage.SimpleQuestKit` |
| `src/ServerScriptService/SimpleQuestKitServer` | `ServerScriptService.SimpleQuestKitServer` |
| `src/StarterPlayer/StarterPlayerScripts/SimpleQuestKitClient` | `StarterPlayer.StarterPlayerScripts.SimpleQuestKitClient` |
| `src/Workspace/SimpleQuestDemo` | `Workspace.SimpleQuestDemo` |
| `src/StarterGui/SimpleQuestKitUI` | `StarterGui.SimpleQuestKitUI` |

For full installation steps, read [docs/INSTALLATION.md](docs/INSTALLATION.md).

## Important Files

```text
ReplicatedStorage/SimpleQuestKit/Config/QuestConfig.lua
ReplicatedStorage/SimpleQuestKit/Config/DemoConfig.lua
ServerScriptService/SimpleQuestKitServer/QuestService.lua
ServerScriptService/SimpleQuestKitServer/QuestDataService.lua
StarterPlayer/StarterPlayerScripts/SimpleQuestKitClient/QuestUIController.client.lua
```

## Server API

Use the API from trusted server scripts only:

```lua
local QuestService = require(game.ServerScriptService.SimpleQuestKitServer.QuestService)

QuestService:AddProgress(player, "welcome_collect_coins", 1)
QuestService:SetProgress(player, "welcome_collect_coins", 5)
QuestService:CompleteQuest(player, "welcome_collect_coins")
QuestService:ClaimReward(player, "welcome_collect_coins")
QuestService:GetPlayerQuestData(player)
QuestService:ResetDailyQuests(player)
```

Full API reference: [docs/API.md](docs/API.md).

## Adding Quests

Most new quests only need two things:

1. Add a quest entry in `QuestConfig.lua`.
2. Add progress from a trusted server script or a tagged demo object.

Start here: [docs/ADD_NEW_QUEST.md](docs/ADD_NEW_QUEST.md).

## DataStore

DataStore is off by default so Play Solo does not show publishing/API errors.

To enable production saving, edit `DemoConfig.lua`:

```lua
UseDataStore = true,
DataStoreName = "SimpleQuestKit_PlayerData_v1",
AutoSaveInterval = 60,
```

Then publish the place and enable Studio API Services. More details are in [docs/INSTALLATION.md](docs/INSTALLATION.md) and [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## Packaging As A Model Or Plugin

For a model, put the kit folders into a clean place, test Play Solo, then publish the model from Studio.

For a plugin, create a toolbar button that inserts these folders into the correct services:

- `ReplicatedStorage.SimpleQuestKit`
- `ServerScriptService.SimpleQuestKitServer`
- `StarterPlayer.StarterPlayerScripts.SimpleQuestKitClient`
- optional `Workspace.SimpleQuestDemo`
- optional `StarterGui.SimpleQuestKitUI`

See [docs/INSTALLATION.md](docs/INSTALLATION.md) for packaging notes.

Detailed `.rbxm`, `.rbxlx`, and plugin packaging steps are in [docs/PACKAGING.md](docs/PACKAGING.md).

## Troubleshooting

Common fixes are documented in [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md), including:

- quest UI not opening
- DataStore publish/API errors
- quests not progressing
- collect coins not working
- rewards not appearing
- remote mismatch or infinite yield warnings

## Testing Checklist

Before shipping, walk through [docs/TESTING_CHECKLIST.md](docs/TESTING_CHECKLIST.md). It covers quest progress, claiming, anti-exploit behavior, DataStore persistence, mobile UI, and clean Output checks.

## Build

```bash
rojo build -o SimpleQuestKit.rbxlx
```

The `.rbxlx` build is ignored by git by default.

## Release Files

- [CHANGELOG.md](CHANGELOG.md)
- [LICENSE.txt](LICENSE.txt)
- [docs/PACKAGING.md](docs/PACKAGING.md)
- [docs/TESTING_CHECKLIST.md](docs/TESTING_CHECKLIST.md)
