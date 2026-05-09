# Testing Checklist

Use this checklist before shipping Simple Quest Kit in a game, model, or plugin.

## Basic Startup

- [ ] Player joins without error

  Press Play Solo. The player should spawn in the demo village and Output should not show red script errors.

- [ ] Quest UI opens

  Click the `Quests` button or interact with the `QuestBoard`. The quest panel should slide open.

- [ ] Quest data loads

  The quest list should show the configured demo quests from `QuestConfig.lua`.

- [ ] No infinite yield warnings

  Output should not show missing remote warnings such as `WaitForChild("RequestQuestData")`.

- [ ] No DataStore error

  With `UseDataStore = false`, Studio Play Solo should not show DataStore publish or API Services errors.

## Quest Progress

- [ ] Collect quest progresses

  Pick up coins. `First Steps` should increase until it reaches `5 / 5`.

- [ ] NPC quest progresses

  Talk to the Guide NPC. `Meet the Guide` should complete.

- [ ] VisitArea quest progresses

  Walk into `ForestZone`. `Explore the Forest` should complete.

- [ ] Interact quest progresses

  Interact with `MagicCrystal` three times. `Crystal Power` should reach `3 / 3`.

- [ ] CustomEvent quest progresses

  Open `TreasureChest`. `Treasure Hunter` should complete.

- [ ] Daily quest progresses

  Collect 10 coins. `Daily Collector` should reach `10 / 10`.

- [ ] Progress does not exceed required amount

  Continue triggering a completed quest. Progress should stay capped at the configured `RequiredAmount`.

## Rewards

- [ ] Claim reward works

  Complete a quest and click `Claim`. The configured reward should appear in `leaderstats`.

- [ ] Cannot claim twice

  Claim the same quest again. The UI should show `Claimed`, and `leaderstats` should not increase a second time.

- [ ] Cannot exploit reward from client

  Confirm there is no client remote that calls `QuestService:AddProgress`. The client should only request quest data and ask to claim already completed quests.

## Persistence

- [ ] Data saves after rejoin

  Set `UseDataStore = true`, publish the place, enable Studio API Services, complete or claim a quest, stop Play Solo, then rejoin. Progress should load again.

  For normal unpublished Studio testing, keep `UseDataStore = false` and skip this item.

## UI

- [ ] Mobile UI usable

  In Studio, use a mobile emulator size. The `Quests` button, quest panel, scrolling list, progress bars, and claim buttons should be readable and tappable.

## Final Pass

- [ ] Demo complete popup appears

  Complete the key demo quests: talk to Guide, collect coins, visit ForestZone, charge MagicCrystal, and open TreasureChest. A `Demo Complete` notification should appear once.

- [ ] Output is clean with Debug off

  Set `Debug = false` in `DemoConfig.lua`. Normal startup logs should be hidden, while real warnings/errors should still appear.
