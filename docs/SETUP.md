# Setup Guide

## 1. Open in VSCode

```bash
cd SimpleQuestKit
code .
```

## 2. Start Rojo

```bash
rojo serve
```

## 3. Connect Studio

Open Roblox Studio > Plugins > Rojo > Connect.

## 4. Test

Press Play. You should see a `Quests` button on the right side of the screen. The kit also creates a small demo scene if the objects do not already exist.

`Debug = false` by default, so normal startup logs are hidden. If you want development logs, set `Debug = true` in `DemoConfig.lua`.

## 5. Demo Objects

The server demo builder creates:

- `GuideNPC`: tagged `QuestNPC`, `QuestTarget = "GuideNPC"`.
- `Coin1` through `Coin10`: tagged `QuestCoin`, `QuestTarget = "Coin"`.
- `ForestZone`: tagged `QuestZone`, `QuestTarget = "ForestZone"`.
- `MagicCrystal`: tagged `QuestInteractable`, `QuestTarget = "MagicCrystal"`.
- `TreasureChest`: tagged `QuestInteractable`, `CustomEvent = "OpenChest"`.
- `QuestBoard`: tagged `QuestInteractable`, opens the quest UI.
- `PortalEndpoint`: visual endpoint for the demo path.

You can delete `DemoWorldBuilder.server.lua` after replacing these with your own map objects. Keep the same tags and attributes.

## 6. Adding Progress From Your Game

From a trusted server script:

```lua
local QuestService = require(game.ServerScriptService.SimpleQuestKitServer.QuestService)

QuestService:AddProgress(player, "custom_open_chest", 1)
```

Do not expose your own progress RemoteEvent to clients unless the server fully validates the action.

## 7. DataStore Notes

Memory Mode is enabled by default for clean Studio testing:

```lua
UseDataStore = false
```

To enable production persistence, edit `DemoConfig.lua`:

```lua
UseDataStore = true,
DataStoreName = "SimpleQuestKit_PlayerData_v1",
AutoSaveInterval = 60,
```

Studio persistence requires:

1. Game Settings > Security.
2. Enable Studio Access to API Services.
3. Publish the place before testing DataStores.

If DataStore initialization, loading, or saving fails, the kit warns clearly and falls back to Memory Mode when possible. Saves use protected calls and retry up to 3 times. Saved records include `DataVersion = 1`.

## 8. Reskinning

- Quest text, requirements, rewards, and categories live in `QuestConfig.lua`.
- Demo tag names and coin respawn timing live in `DemoConfig.lua`.
- UI colors and layout live in `QuestUIController.client.lua`.
