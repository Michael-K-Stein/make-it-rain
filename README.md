# Make It Rain — Garmin Connect IQ

A minimalist idle game for Garmin touchscreen watches. Swipe down to make money.

## Build

Requires the Connect IQ SDK (tested with 9.2.0) and a developer key.

```sh
openssl genrsa -out bin/dev_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -in bin/dev_key.pem -out bin/developer_key.der -nocrypt

monkeyc -f monkey.jungle -o bin/MakeItRain.prg -y bin/developer_key.der -d venu2
monkeydo bin/MakeItRain.prg venu2      # with the simulator running
```

Device profiles listed in `manifest.xml` that you have not downloaded in the SDK
Manager produce "invalid device id" warnings; they are harmless for other targets.

## Controls

| Gesture | Result |
| --- | --- |
| Swipe down (anywhere in the centre) | Make money |
| Swipe left from the **right** edge | Upgrades |
| Swipe right from the **left** edge | Automation |
| Tap (upgrade/automation screens) | Buy |
| Swipe up/down on Upgrades | Cycle cash-per-swipe / mega-swipe chance |
| Back | Return to the money screen |

Navigation is restricted to the edge zones so rapid money swiping in the centre
can never trigger it.

## Source map

| File | Role |
| --- | --- |
| `source/GameState.mc` | All numbers, economy tuning, save/load, offline earnings |
| `source/MainView.mc` | Money screen, animation loop, milestone celebration |
| `source/MainDelegate.mc` | Drag classification: money swipe vs. edge navigation |
| `source/MoneyRain.mc` | Fixed-pool particle burst |
| `source/UpgradeView.mc` | Cash-per-swipe and mega-swipe upgrades |
| `source/AutomationView.mc` | Passive income upgrade |
| `source/OfflineView.mc` | "Welcome back" claim screen |
| `source/Format.mc` | Compact currency formatting ($12.4K) |
| `source/Theme.mc` | Palette |

## Economy

```
cashPerSwipe  = 1.00 * 1.40^(level-1)          cost = 10 * 1.55^(level-1)
passiveIncome = 0.50 * level * 1.15^(level-1)  cost = 50 * 1.62^level
critChance    = 5% + 2%/level (max 40%)        cost = 250 * 2.4^level
```

Streak multiplier: x1.0 / x1.1 (3) / x1.25 (5) / x1.5 (10), resetting after 2.5s.
Offline earnings are capped at 8 hours.

See `BACKLOG.md` for what is deliberately not built yet.
