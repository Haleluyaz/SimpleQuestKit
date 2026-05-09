# Installation Guide

This guide explains how to install Simple Quest Kit with Rojo or manually in Roblox Studio.

## Folder Structure

The project is organized to match Roblox services:

```text
src/
  ReplicatedStorage/
    SimpleQuestKit/
      Config/
        QuestConfig.lua
        DemoConfig.lua
      Shared/
        QuestUtil.lua
        QuestTypes.lua
        Signal.lua
  ServerScriptService/
    SimpleQuestKitServer/
      QuestBootstrap.server.lua
      QuestService.lua
      QuestDataService.lua
      RewardService.lua
      DailyQuestService.lua
      QuestObjectService.lua
      DemoWorldBuilder.server.lua
  StarterPlayer/
    StarterPlayerScripts/
      SimpleQuestKitClient/
        QuestController.client.lua
        QuestUIController.client.lua
        OnboardingController.client.lua
  Workspace/
    SimpleQuestDemo/
  StarterGui/
    SimpleQuestKitUI/
```

## Install With Rojo

1. Install Rojo.
2. Open a terminal in the project folder.
3. Run:

```bash
rojo serve
```

4. Open Roblox Studio.
5. Open or create a place.
6. Open the Rojo plugin.
7. Connect to the local Rojo server.
8. Press Play.

The demo village should appear automatically. You should also see a `Quests` button on the right side of the screen.

## Build A Place File With Rojo

Use this when you want a complete demo place file for testing or selling.

Run:

```bash
rojo build -o SimpleQuestKit.rbxlx
```

Open `SimpleQuestKit.rbxlx` in Roblox Studio and press Play.

## Package A Model File

Use this when you want a `.rbxm` that buyers can insert into an existing game.

The simplest Studio workflow is:

1. Build or open the project in Studio.
2. Create a temporary `SimpleQuestKitPackage` folder in `ServerStorage`.
3. Copy the kit folders into that package.
4. Right-click `SimpleQuestKitPackage`.
5. Choose `Save to File`.
6. Save as `SimpleQuestKit.rbxm`.

Full packaging steps are in [PACKAGING.md](PACKAGING.md).

## Manual Studio Install

Use this method if you bought the kit as folders or copied it from a model.

1. In Roblox Studio, open Explorer.
2. Create a folder named `SimpleQuestKit` in `ReplicatedStorage`.
3. Copy the contents of `src/ReplicatedStorage/SimpleQuestKit` into it.
4. Create a folder named `SimpleQuestKitServer` in `ServerScriptService`.
5. Copy the contents of `src/ServerScriptService/SimpleQuestKitServer` into it.
6. Create a folder named `SimpleQuestKitClient` in `StarterPlayer > StarterPlayerScripts`.
7. Copy the client scripts into it.
8. Optional: copy `src/Workspace/SimpleQuestDemo` into `Workspace`.
9. Optional: copy `src/StarterGui/SimpleQuestKitUI` into `StarterGui`.
10. Press Play.

Do not rename `SimpleQuestKit` or `SimpleQuestKitServer`. The scripts use those names to find each other.

## Enable DataStore

Memory Mode is the default:

```lua
UseDataStore = false,
```

This is best for Play Solo and early testing because it avoids DataStore publish errors.

For production saving, edit:

```text
ReplicatedStorage/SimpleQuestKit/Config/DemoConfig.lua
```

Set:

```lua
UseDataStore = true,
DataStoreName = "SimpleQuestKit_PlayerData_v1",
AutoSaveInterval = 60,
```

Then in Roblox Studio:

1. Publish the place to Roblox.
2. Open Game Settings.
3. Go to Security.
4. Enable Studio Access to API Services.
5. Save settings.
6. Restart Play Solo.

The kit saves on reward claim, player leave, server shutdown, and autosave.

## Package As A Roblox Model

1. Install the kit into a clean place.
2. Test Play Solo.
3. Select these folders:
   - `ReplicatedStorage.SimpleQuestKit`
   - `ServerScriptService.SimpleQuestKitServer`
   - `StarterPlayer.StarterPlayerScripts.SimpleQuestKitClient`
   - optional `Workspace.SimpleQuestDemo`
   - optional `StarterGui.SimpleQuestKitUI`
4. Right-click and save or publish as a model.
5. Include the documentation files for buyers.

## Package As A Plugin

A plugin can insert the same folders into the correct services.

The plugin should:

1. Check if each folder already exists.
2. Ask before replacing an existing installation.
3. Insert `SimpleQuestKit` into `ReplicatedStorage`.
4. Insert `SimpleQuestKitServer` into `ServerScriptService`.
5. Insert `SimpleQuestKitClient` into `StarterPlayerScripts`.
6. Optionally insert the demo village into `Workspace`.

Keep the plugin simple. The quest system itself should remain in the installed folders.
