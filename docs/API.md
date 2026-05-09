# API Reference

Use `QuestService` from server scripts only.

```lua
local QuestService = require(game.ServerScriptService.SimpleQuestKitServer.QuestService)
```

The client UI can request quest data and claim rewards through the kit remotes, but clients should never be allowed to award progress directly.

## AddProgress

```lua
QuestService:AddProgress(player, questId, amount)
```

Adds progress to a quest.

Example:

```lua
QuestService:AddProgress(player, "welcome_collect_coins", 1)
```

Use this for coins, chest opens, NPC talks, enemy defeats, crafting, or any other server-verified action.

## SetProgress

```lua
QuestService:SetProgress(player, questId, amount)
```

Sets progress to an exact value.

Example:

```lua
QuestService:SetProgress(player, "playtime_beginner", 120)
```

This is useful when your own system already tracks a total count.

## CompleteQuest

```lua
QuestService:CompleteQuest(player, questId)
```

Marks a quest complete without granting rewards.

Example:

```lua
QuestService:CompleteQuest(player, "visit_forest")
```

The player still needs to claim rewards unless your script also calls `ClaimReward`.

## ClaimReward

```lua
QuestService:ClaimReward(player, questId)
```

Claims rewards for a completed quest once.

Example:

```lua
local claimed = QuestService:ClaimReward(player, "welcome_collect_coins")

if claimed then
    print("Reward claimed")
end
```

Rewards are granted by `RewardService`. The default reward behavior adds numeric values to `leaderstats`.

## GetPlayerQuestData

```lua
local questData = QuestService:GetPlayerQuestData(player)
```

Returns data for UI or debugging.

Example:

```lua
local data = QuestService:GetPlayerQuestData(player)
local quests = data.PlayerData.Quests

print(quests.welcome_collect_coins.Progress)
```

Returned data includes:

- `Config`: quest config table
- `PlayerData`: the player's progress data
- `ServerTime`: current server timestamp

## ResetDailyQuests

```lua
QuestService:ResetDailyQuests(player)
```

Resets all daily quests for one player.

Example:

```lua
QuestService:ResetDailyQuests(player)
```

The included daily service also checks reset timers automatically.

## Reward Format

Rewards are configured in `QuestConfig.lua`:

```lua
Rewards = {
    Coins = 100,
    Gems = 5,
}
```

Default behavior creates or updates:

```text
player.leaderstats.Coins
player.leaderstats.Gems
```

To connect your own economy, edit:

```text
ServerScriptService/SimpleQuestKitServer/RewardService.lua
```

Example custom reward logic:

```lua
function RewardService:GrantRewards(player, rewards)
    for rewardName, amount in pairs(rewards) do
        -- Call your currency, inventory, or badge system here.
        print(player.Name, "earned", amount, rewardName)
    end
end
```

## Remote Names

The kit creates these automatically:

| Remote | Type | Purpose |
| --- | --- | --- |
| `RequestQuestData` | `RemoteFunction` | Client requests quest data |
| `ClaimQuest` | `RemoteFunction` | Client asks server to claim a completed quest |
| `QuestUpdated` | `RemoteEvent` | Server sends updated quest data |
| `QuestClaimed` | `RemoteEvent` | Server tells client a reward was claimed |
| `OpenQuestUI` | `RemoteEvent` | Server asks client to open the quest UI |

Do not add a client remote that directly calls `AddProgress`. Progress should come from trusted server code.
