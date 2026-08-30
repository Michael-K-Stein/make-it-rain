# Make It Rain — Garmin Connect IQ

A minimalist idle game for Garmin touchscreen watches. Swipe down to make money.

## Build

Needs `java` and `python3`. Point at an existing SDK, or let the tooling fetch one:

```sh
tools/verify.sh                    # fast checks, no SDK needed
tools/build.sh --fetch-sdk         # -> dist/MakeItRain-<device>.prg (sideload)
tools/package.sh --fetch-sdk       # -> dist/MakeItRain.iq (every product, store-ready)
```

Or point at an SDK you already have (from the graphical SDK Manager or otherwise):

```sh
CIQ_SDK=~/connectiq-sdk tools/build.sh venu2
```

Device configurations are generated straight from the SDK's own device table
(`tools/make_device_json.py`), not from the SDK Manager's per-device
downloads — so `tools/build.sh` and `tools/package.sh` can target any device
the SDK knows about, including ones you've never opened the Manager for.
`tools/build.sh`'s default set is `venu2 venu2s vivoactive5`; `tools/package.sh`
packages every product in `manifest.xml` into one `.iq`.

A developer key is required to sign anything. `tools/build.sh` generates a
throwaway one at `dist/developer_key.der` if none exists — fine for
sideloading, but the store binds an app to whichever key first uploaded it, so
`tools/package.sh` refuses to invent one; point `CIQ_KEY` at your real key.

### Tests

```sh
monkeyc -f tests.jungle -o dist/tests.prg -y dist/developer_key.der -d venu2 -t
monkeydo dist/tests.prg venu2 /t       # with the simulator running
```

### CI

`.github/workflows/build.yml` runs `tools/verify.sh`, `tools/build.sh --fetch-sdk`,
and the unit tests on every push. `.github/workflows/release.yml` additionally
packages and publishes a GitHub release when a `v*` tag is pushed — set the
`CIQ_DEVELOPER_KEY` repo secret to your key, base64-encoded
(`base64 -w0 dist/developer_key.der`), first.

## Controls

| Gesture | Result |
| --- | --- |
| Swipe down (anywhere in the centre) | Make money |
| Swipe left from the **right** edge | Upgrades |
| Swipe right from the **left** edge | Automation |
| Swipe down from the **top** strip | Stats / Prestige |
| Tap (Upgrades/Automation/Stats) | Buy / confirm |
| Hold (Upgrades/Automation) | Buy every affordable level at once |
| Swipe up/down on Upgrades | Cycle cash-per-swipe / mega-swipe chance |
| Back | Return to the previous screen |

Navigation is restricted to the edge zones so rapid money swiping in the centre
can never trigger it.

## Source map

| File | Role |
| --- | --- |
| `source/GameState.mc` | All numbers, economy tuning, save/load, offline earnings, prestige |
| `source/MainView.mc` | Money screen, animation loop, milestone celebration |
| `source/MainDelegate.mc` | Drag classification: money swipe vs. edge navigation |
| `source/MoneyRain.mc` | Fixed-pool particle burst |
| `source/UpgradeView.mc` | Cash-per-swipe and mega-swipe upgrades |
| `source/AutomationView.mc` | Passive income upgrade |
| `source/StatsView.mc` | Lifetime stats and prestige |
| `source/OfflineView.mc` | "Welcome back" claim screen |
| `source/MakeItRainApp.mc` | App lifecycle, the app-wide passive-income/autosave ticker |
| `source/Format.mc` | Compact currency formatting ($12.4K) |
| `source/Theme.mc` | Palette |
| `tests/` | Unit tests (`monkeyc -t`), not part of the shipped app |
| `tools/` | Build/verify/package scripts and their Python helpers (see below) |

### Tools

| File | Role |
| --- | --- |
| `tools/build.sh` | Fetches the SDK if asked, builds `.prg` per device for sideloading |
| `tools/package.sh` | Builds the store-ready `.iq` covering every manifest product |
| `tools/verify.sh` | The no-SDK-needed fast gate: constants, layout, economy smoke test |
| `tools/make_device_json.py` | Device configs straight from the SDK jar — no SDK Manager needed |
| `tools/make_icon.py` | Generates `resources/drawables/launcher_icon.png` (not committed) |
| `tools/check_constants.py` | Fails if `GameState.mc` and `simulate_economy.py` drift apart |
| `tools/check_layout.py` | Fails if a button/text row would clip a round display's bezel |
| `tools/simulate_economy.py` | Plays the game fast — greedy buyer — to sanity-check pacing |

## Economy

```
cashPerSwipe  = 1.00 * 1.40^(level-1) * prestigeMult      cost = 10 * 1.55^(level-1)
passiveIncome = 0.50 * level * 1.15^(level-1) * prestigeMult  cost = 50 * 1.62^level
critChance    = 5% + 2%/level (max 40%), unlocks at $1K   cost = 250 * 2.4^level
prestigeMult  = 1 + prestigeLevel   (available at $1M lifetime cash, resets the run)
```

Streak multiplier: x1.0 / x1.1 (3) / x1.25 (5) / x1.5 (10), resetting after 2.5s.
Offline earnings are capped at 8 hours. Passive income and autosave run on an
app-wide ticker, independent of which screen is showing.

See `BACKLOG.md` for what's still open.
