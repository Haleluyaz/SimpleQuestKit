# Packaging Guide

Use this guide when preparing Simple Quest Kit for buyers.

## Release Files To Include

Include:

- `README.md`
- `CHANGELOG.md`
- `LICENSE.txt`
- `docs/`
- `default.project.json`
- `aftman.toml`
- `src/`

Do not include local build artifacts unless you are intentionally shipping them:

- `SimpleQuestKit.rbxlx`
- `SimpleQuestKit.rbxm`

## Build A `.rbxlx` Place File

Use `.rbxlx` when you want to sell or share a complete demo place.

Run:

```bash
rojo build -o SimpleQuestKit.rbxlx
```

Then:

1. Open `SimpleQuestKit.rbxlx` in Roblox Studio.
2. Press Play and run through `docs/TESTING_CHECKLIST.md`.
3. Save or publish the place as your demo file.

## Create A `.rbxm` Model In Studio

Use `.rbxm` when you want buyers to insert the kit into their own game.

Roblox models are easiest to package from Studio:

1. Open the built `.rbxlx` place or connect with Rojo.
2. In Explorer, create a temporary folder named `SimpleQuestKitPackage` in `ServerStorage`.
3. Copy these folders into `SimpleQuestKitPackage`:
   - `ReplicatedStorage.SimpleQuestKit`
   - `ServerScriptService.SimpleQuestKitServer`
   - `StarterPlayer.StarterPlayerScripts.SimpleQuestKitClient`
   - optional `Workspace.SimpleQuestDemo`
   - optional `StarterGui.SimpleQuestKitUI`
4. Right-click `SimpleQuestKitPackage`.
5. Choose `Save to File`.
6. Save as `SimpleQuestKit.rbxm`.

Add a note for buyers that they must move each folder into the matching Roblox service after inserting the model.

## Create A Marketplace Model

1. Install the kit into a clean place.
2. Test Play Solo.
3. Select the package folder or the individual kit folders.
4. Right-click and choose `Save to Roblox`.
5. Add a clear title, description, version number, and link to the docs.

## Plugin Packaging

For a plugin, keep the plugin installer simple. It should only insert the kit folders into the correct services.

Recommended plugin behavior:

1. Add a toolbar button named `Install Simple Quest Kit`.
2. Check for an existing install.
3. Ask before replacing folders.
4. Insert `SimpleQuestKit` into `ReplicatedStorage`.
5. Insert `SimpleQuestKitServer` into `ServerScriptService`.
6. Insert `SimpleQuestKitClient` into `StarterPlayerScripts`.
7. Optionally insert the Starter Village demo into `Workspace`.

Do not add new gameplay systems to the plugin. The product should remain a focused quest kit.

## Final Buyer Test

Before publishing a release:

1. Set `Debug = false`.
2. Set `UseDataStore = false` for the demo package unless you specifically want persistence enabled.
3. Run `rojo build -o SimpleQuestKit.rbxlx`.
4. Open the build in Studio.
5. Complete `docs/TESTING_CHECKLIST.md`.
6. Confirm Output has no infinite yield warnings and no DataStore errors.
