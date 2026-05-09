# Troubleshooting

This page lists common issues and beginner-friendly fixes.

## Infinite Yield On RequestQuestData

Message:

```text
Infinite yield possible on ReplicatedStorage.SimpleQuestKit.Remotes
```

Fixes:

- Make sure `QuestBootstrap.server.lua` is inside `ServerScriptService.SimpleQuestKitServer`.
- Do not rename `SimpleQuestKit` or `SimpleQuestKitServer`.
- Press Play, not just Run, when testing client UI.
- Check Output for an earlier server error.

The server creates these remotes automatically:

```text
RequestQuestData
ClaimQuest
QuestUpdated
QuestClaimed
OpenQuestUI
```

## DataStore Error: Publish This Place

Message:

```text
You must publish this place to the web to access DataStore
```

Fixes:

- Leave `UseDataStore = false` while testing in an unpublished place.
- To test saving, publish the place first.
- Open Game Settings > Security.
- Enable Studio Access to API Services.
- Restart Play Solo.

Config location:

```text
ReplicatedStorage/SimpleQuestKit/Config/DemoConfig.lua
```

## Data Does Not Save

Check:

```lua
UseDataStore = true
```

Then confirm:

- The place is published.
- Studio API Services are enabled.
- You are testing in Play Solo or a live server.
- Output does not show a DataStore warning.

The kit falls back to Memory Mode if DataStore fails, so the quest system can keep working during the session.

## Quest UI Does Not Open

Fixes:

- Make sure `QuestUIController.client.lua` is inside `StarterPlayerScripts.SimpleQuestKitClient`.
- Make sure `QuestController.client.lua` is also inside that folder.
- Press Play so LocalScripts run.
- Check that `ReplicatedStorage.SimpleQuestKit` exists.

The QuestBoard opens the UI through the `OpenQuestUI` remote.

## Quest Does Not Progress

Check the quest config:

```lua
Id = "collect_apples",
Type = "Collect",
Target = "Apple",
RequiredAmount = 8,
```

Then check the object or script that adds progress. The `Target` must match.

For tagged objects:

- collect pickups use `QuestTarget`
- visit zones use `QuestTarget`
- NPCs use `QuestTarget`
- interactables use `QuestTarget` or `CustomEvent`

For custom scripts:

```lua
QuestService:AddProgress(player, "collect_apples", 1)
```

Make sure this runs on the server.

## Coin Pickups Do Not Work

Check:

- The pickup is a `BasePart`.
- It has the `QuestCoin` tag.
- It has `QuestTarget = "Coin"` or your custom target.
- `CanTouch` is not disabled by another script.
- The player's character is touching the part.

The default tag names are in `DemoConfig.lua`.

## NPC Prompt Does Not Count

Check:

- The NPC part has a `ProximityPrompt`.
- The part has tag `QuestNPC`.
- The part has `QuestTarget` matching the quest `Target`.

Example:

```text
QuestTarget = GuideNPC
```

Quest:

```lua
Type = "Interact",
Target = "GuideNPC",
```

## Visit Area Does Not Count

Check:

- The zone is a `BasePart`.
- The zone has tag `QuestZone`.
- The zone has `QuestTarget` matching the quest `Target`.
- The zone has `CanTouch = true`.

Example:

```lua
Type = "VisitArea",
Target = "ForestZone",
```

## Rewards Do Not Appear

The default reward system adds values under:

```text
player.leaderstats
```

If your game uses a custom economy, edit:

```text
ServerScriptService/SimpleQuestKitServer/RewardService.lua
```

Example:

```lua
function RewardService:GrantRewards(player, rewards)
    for rewardName, amount in pairs(rewards) do
        -- Send reward to your own inventory or currency system.
    end
end
```

## Too Many Output Messages

Turn debug off:

```lua
Debug = false
```

Location:

```text
ReplicatedStorage/SimpleQuestKit/Config/DemoConfig.lua
```

Important warnings still show even when debug is off.

## I Renamed A Folder And It Broke

The kit expects these names:

```text
ReplicatedStorage.SimpleQuestKit
ServerScriptService.SimpleQuestKitServer
StarterPlayer.StarterPlayerScripts.SimpleQuestKitClient
```

If you rename them, update all scripts that call `WaitForChild` for those names.

## Reset My Test Progress

In Memory Mode, stop and restart Play Solo.

With DataStore enabled, change `DataStoreName` during testing:

```lua
DataStoreName = "SimpleQuestKit_PlayerData_Test2"
```

For a live game, build an admin-only reset command that calls:

```lua
QuestService:ResetDailyQuests(player)
```

or clears your saved DataStore record with your own admin tooling.
