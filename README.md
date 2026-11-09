# This mod likely will not be maintained

I no longer really play the game, so ongoing updates and fixes are unlikely.

# Quick Dungeon Restart

<!-- drh:show -->
Shift+R quickly restarts the current dungeon with its entry settings and keeps the gold cache synchronized.
<!-- /drh:show -->

- Shift+R exits and re-enters using the saved dungeon-entry settings.
- Preserves the friends-only setting and waits for server exit confirmation.
- Prevents duplicate restart requests and ignores chat input and held-key repeats.
- Keeps the account gold cache synchronized with server currency updates.

Replays entry to the dungeon, not its current floor or procedural seed. Friend/map-instance joins replay their original arguments and may rejoin that instance. Other party members are not forced to restart.

## Multiplayer restart order

**Guests must wait for their host friend to press Shift+R first.** After the host has restarted, guests can press Shift+R to rejoin.

## Requirements

Dungeon Rampage Haxe V17 and DRH Mod API 1.2 or a compatible later 1.x release. The launcher resolves the API dependency. This mod uses game internals and may need updates for later game releases.

## Installation

Install the release ZIP through the DRH Launcher Mods page. Do not use GitHub's automatic source-code ZIP as the release artifact.

To test a source checkout, run this from its repository folder with your launcher path:

```powershell
& "C:\Path\To\DRH-Launcher.com" --run-mod (Get-Location).Path
```

## Publishing

The included official workflow drafts a release when you push a `v<version>` tag matching `mod.json`. Test the generated ZIP before publishing the draft. Follow [Making a mod](https://github.com/Tutez64/Dungeon-Rampage-Haxe/blob/master/docs/making-a-mod.md) to submit the published release to the mod index.

## License

MIT. See [LICENSE](LICENSE).
