# Starter Village Quest Demo

## Player Flow

1. Spawn in a small village.
2. Talk to Guide NPC.
3. Collect 5 coins.
4. Open quest menu.
5. Claim reward.
6. Visit forest zone.
7. Interact with glowing crystal.
8. Open treasure chest.
9. Complete daily quest.
10. See demo complete popup.

## Demo Objects

- GuideNPC: ProximityPrompt + exclamation mark.
- Coins: 10 collectibles, respawn after delay.
- ForestZone: invisible trigger part.
- MagicCrystal: ProximityPrompt, counts 3 interactions.
- TreasureChest: ProximityPrompt, counts once per player.
- QuestBoard: opens quest UI.
- Portal: endpoint visual.

## Buyer-Focused Labels

Add signs:

- Config Based
- Server Authoritative
- Mobile Ready
- Daily Quests
- NPC Quests
- Custom Events

## Tags And Attributes

The demo is powered by `QuestObjectService` on the server.

| Object | Tag | Required Attributes |
| --- | --- | --- |
| GuideNPC | `QuestNPC` | `QuestTarget = "GuideNPC"` |
| Coins | `QuestCoin` | `QuestTarget = "Coin"` |
| ForestZone | `QuestZone` | `QuestTarget = "ForestZone"` |
| MagicCrystal | `QuestInteractable` | `QuestTarget = "MagicCrystal"` |
| TreasureChest | `QuestInteractable` | `CustomEvent = "OpenChest"` |
| QuestBoard | `QuestInteractable` | `QuestTarget = "QuestBoard"` |

## Demo Script Behavior

- Coins call server-side collect progress and briefly hide before respawning.
- Zones call server-side visit progress when touched by a character.
- NPCs and interactables use ProximityPrompts.
- The quest board asks the client to open the quest UI.
- The chest advances the configured custom event quest.

## Packaging Tip

For a marketplace demo, keep the generated scene tiny and readable. Buyers should immediately see the tags, attributes, and config values that connect the world to the quest system.
