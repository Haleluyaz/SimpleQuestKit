-- Simple Quest Kit - buyer-facing settings.
-- Required core file. Buyers may edit this.
-- Most developers only need to edit this file, QuestConfig.lua, and RewardService.lua.

return {
    -- Set true only while developing if you want startup/debug logs.
    Debug = false,

    -- Keep false for Studio Play Solo. Enable only after publishing and turning on API Services.
    UseDataStore = false,
    DataStoreName = "SimpleQuestKit_PlayerData_v1",
    AutoSaveInterval = 60,

    -- Optional Roblox service hooks. Leave false if your game does not use these.
    EnableBadgeRewards = false,
    EnableGamepassRewardMultiplier = false,
    RewardMultiplierGamepassId = 0,
    GamepassRewardMultiplier = 2,

    -- Optional developer test panel. Keep false for normal players and release builds.
    EnableAdminDebugPanel = false,
    AdminUserIds = {
        -- Add your Roblox user ID here to enable the admin test panel.
        -- 123456789,
    },
    AdminTestReward = {
        Coins = 100,
    },

    -- Only these reward names receive the optional gamepass multiplier.
    GamepassMultiplierRewardNames = {
        Coins = true,
        Gems = true,
        Keys = true,
        XP = true,
        Cash = true,
    },

    -- Demo object settings. Safe to ignore if you call QuestService from your own scripts.
    -- Keep false in real games so demo floors/props do not overlap your map.
    BuildDemoWorld = false,
    CoinRespawnSeconds = 8,
    DemoObjectTags = {
        Coin = "QuestCoin",
        NPC = "QuestNPC",
        Zone = "QuestZone",
        Interactable = "QuestInteractable",
    },
    CurrencyNames = {
        Coins = "Coins",
        Gems = "Gems",
        Keys = "Keys",
    }
}
