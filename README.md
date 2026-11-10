# This mod likely will not be maintained

I no longer really play the game, so ongoing updates and fixes are unlikely.

# Quick Dungeon Restart

<!-- drh:show -->
Shift+R and a native Repeat button replay dungeons. Next and Repeat preserve Friends Only and summary reward handling.
- Shift+R exits and re-enters using the saved dungeon-entry settings.
- Adds a Repeat button beneath Next using the game's own artwork, font and hover styling.
- Shift+R also works on the dungeon summary, after the reveal and crate handling finish.
- Keep, open or abandon remaining crates and close summary dialogs before repeating; it does not auto-claim loot.
- Summary repeats use native exit cleanup and refresh the account before re-entry.
- Next and Repeat preserve the previous entry's Friends Only setting, both on and off.
- Waits for server exit confirmation.
- Prevents duplicate restart requests and ignores chat input and held-key repeats.
- Keeps the account gold cache synchronized with server currency updates.
<!-- /drh:show -->

Replays entry to the dungeon, not its current floor or procedural seed. Friend/map-instance joins replay their original arguments and may rejoin that instance. Other party members are not forced to restart.

Restarting during gameplay still leaves early and does not award unfinished dungeon completion rewards. For completion XP and crates, finish the dungeon, handle the summary rewards, then use Repeat or Shift+R.

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
