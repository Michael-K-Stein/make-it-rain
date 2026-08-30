# Backlog

Status of every item raised after the MVP (github.com/Michael-K-Stein/make-it-rain,
issues #1–#17). Implemented items note what shipped and what's still unverified.

## Implemented

### 1. Prestige system — done
`GameState.doPrestige()` resets cash/swipe/auto/crit levels once
`lifetimeCash >= PRESTIGE_REQUIREMENT` ($1M), grants a permanent +100%/level
earnings multiplier (`prestigeMultiplier()`, applied in `cashPerSwipe()` and
`passiveIncome()`), and keeps lifetime stats. Reached from the new Stats screen.
Save format bumped to v2 (`"prestige"` field); see #12.

### 2. Stats / progression screen — done
`StatsView`/`StatsDelegate`. Reached by swiping down from the top strip of the
money screen. Shows lifetime cash, total swipes, prestige level/multiplier, and
the prestige action with a confirm step.

### 3. Milestone-gated upgrade unlocks — done
Mega Swipe (crit) is locked until the first milestone ($1,000) is crossed
(`GameState.critUnlocked()`). The upgrade card shows a "LOCKED — unlocks at $1K"
state instead of a buyable card until then.

### 4. Sound feedback — done
`MainView.tone()` calls `Attention.playTone` on a normal swipe, a mega swipe,
and a milestone, wrapped in the same has/try pattern as the existing vibration
code so it's silently a no-op where unsupported. No mute setting was added —
still relies on the watch's own DND/vibration settings.

### 5. Swipe hint fades out — done
`MainView` hides the chevron hint once `totalSwipes >= HINT_TEACH_SWIPES` (4),
and brings it back after ~30s of no interaction (`HINT_RETURN_IDLE_FRAMES`).

### 6. Affordability cue — done
`drawEdgeHints` colors the "U"/"A" edge-hint letters `Theme.ACCENT` instead of
`Theme.MUTED` whenever anything on that screen is affordable.

### 7. Buy-max / hold-to-buy — done, one caveat
Holding the buy button (`onHold`) buys every level the current cash affords in
one shot (`GameState.buyMaxSwipeUpgrade/buyMaxAutoUpgrade/buyMaxCritUpgrade`,
capped at `MAX_BUY_STEPS` to bound the loop). **Not verified**: whether a
release-after-hold also fires `onTap` on this SDK/device, which would trigger an
extra single-level buy immediately after the max-buy. Needs an interactive check
(see #17).

### 9. Passive income now accrues app-wide — done
Moved off `MainView`'s per-frame timer onto a `Timer.Timer` owned by
`MakeItRainApp` (`onTick`, 1s interval), so it keeps running regardless of which
view is on screen, including Upgrades/Automation/Stats.

### 11. Autosave is time-based — done
Folded into the same `MakeItRainApp.onTick`: saves every `SAVE_EVERY_TICKS` (20)
real-second ticks instead of counting animation frames.

### 12. Save migration — done
`SAVE_VERSION` bumped to 2 for the new `prestige` field. `load()`'s per-field
`pick()` fallback means a v1 save (no `"prestige"` key) loads cleanly with
`prestigeLevel = 0`; a save from a *future* version is still rejected outright
rather than partially trusted. Covered by `testPrestigeResetsRunButKeepsLifetimeStats`
et al. in `tests/GameStateTest.mc`, though there's no literal "load an old-format
blob" test — it relies on the field being genuinely optional.

### 13. Automated tests — done
`tests/FormatTest.mc` and `tests/GameStateTest.mc`, 15 cases covering compact
number formatting (including the trailing-zero stripping and a tier-boundary
rounding case), cost-curve growth, prestige gating/reset, crit unlock/cap,
streak tiers, and buy-max spend accounting. Build with:
```sh
monkeyc -f tests.jungle -o bin/tests.prg -y bin/developer_key.der -d venu2 -t
monkeydo bin/tests.prg venu2 /t     # simulator must be running
```
All 15 currently pass.

## Partially addressed

### 14. Device coverage — improved, not complete
Compiles clean (no errors, no warnings) and launches without a runtime error on
both `venu2` (416×416 round) and `vivoactive5` (260×260 round) — the smallest
screen available in the local SDK install — so the fractional layout survives a
meaningfully smaller display. `venu2s`, `venu3`, `venu3s`, `venusq2`,
`venusq2m`, `fr265`, and `fr965` device profiles aren't downloaded in this SDK
install and remain unchecked; `venusq2` in particular is square, not round, and
has not been visually verified at all. No screenshot tooling was available in
this environment to confirm layout by eye on any device — "no runtime error"
is not the same as "nothing overlaps."

### 17. Interactive verification — improved, not complete
The app now launches cleanly in the simulator on two device profiles with no
runtime error. Gesture, purchase, prestige-confirm, and offline-claim flows
have still not been exercised — there was no way to script simulated touch
input from this environment. Needs a manual pass on the simulator or hardware.

## Still open, unchanged

### 8. Number precision ceiling
`GameState` still stores cash as a `Double`. Beyond ~1e15 the integer part loses
precision, and `Format.num`'s suffixes only go up to `Oc` (1e27). The new
prestige multiplier makes numbers grow faster, which brings this ceiling
closer but doesn't require hitting it yet at typical play lengths. A real fix
needs a mantissa/exponent representation.

### 10. Offline earnings trust the system clock
Unchanged: `GameState.computeOffline` clamps negative elapsed time to 0, but a
forward-clock-set is still credited up to the 8h cap. Left as accepted risk —
low value to exploit, and there's no tamper-resistant clock source available to
a watch app.

### 15. Launcher icon is a placeholder
Still a generated flat green circle. Needs real art, not more code.

### 16. Gesture fallback path is untested
`MainDelegate.onSwipe`'s device-without-drag-coordinates fallback and its 400ms
de-duplication window against `onDrag` are unchanged and still unvalidated on
real hardware.
