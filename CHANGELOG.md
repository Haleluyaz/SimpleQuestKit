# Changelog

## v1.0.0

Initial commercial release candidate for Simple Quest Kit.

### Added

- Config-driven quest definitions in `QuestConfig.lua`.
- Quest types: `Collect`, `Playtime`, `VisitArea`, `Interact`, `CustomEvent`, and `Daily`.
- Server-authoritative `QuestService` API.
- Mobile-friendly quest UI with quest cards, progress bars, reward previews, completed state, and claim buttons.
- Reward claiming through `RewardService` with default `leaderstats` support.
- Memory Mode as the default persistence mode for clean Studio Play Solo testing.
- Optional DataStore persistence with retries, autosave, leave save, shutdown save, and fallback to Memory Mode.
- Central `DemoConfig.Debug` toggle for normal development logs.
- Polished low-poly Starter Village demo with Guide NPC, coins, ForestZone, MagicCrystal, TreasureChest, QuestBoard, onboarding signs, and quest type signs.
- Buyer documentation for installation, API usage, adding quests, troubleshooting, and testing.

### Notes

- No pet, inventory, battle pass, shop, combat, or random reward systems are included. This product is intentionally focused on quests.
- DataStore is disabled by default. Enable it only after publishing the place and turning on Studio API Services.
