# Backlog

Everything the spec describes that the MVP deliberately leaves out, plus gaps
found while building. One entry per issue, ready to be filed as GitHub issues.

## Deferred by the spec (§14, §20)

### 1. Prestige system
Spec §14. Reset cash and upgrades at a major milestone for a permanent earnings
multiplier. `prestigeLevel` is named in the §16 save list but is not yet a field
on `GameState`; adding it is a save-format change (see #12).

### 2. Stats / progression screen
Spec §8 maps a right-edge swipe to Stats. The gesture is currently unbound.
`GameState` already tracks `lifetimeCash` and `totalSwipes` for it.

### 3. Milestone-gated upgrade unlocks
Spec §13 shows "NEW UPGRADE UNLOCKED" on a milestone. Milestones currently only
trigger a celebration; no upgrade is gated behind them, so both upgrade cards
are available from the first second.

## Gaps in what was built

### 4. No sound feedback
Spec §21 asks for "visual/audio/haptic" feedback. Haptics and visuals are done;
`Attention.playTone` is not wired up, and there is no user setting to mute it.

### 5. Swipe hint never adapts to the player
`MainView.drawSwipeHint` always draws the same three chevrons. It should fade out
once the player has clearly understood the mechanic (e.g. after N swipes) to free
the screen, and reappear after a long absence.

### 6. Upgrade screen shows only one upgrade at a time with no affordability cue
You have to cycle to the second card to discover it, and nothing on the money
screen signals "you can afford an upgrade right now" — a core idle-game pull.
Suggest a small accent dot on the right edge hint when anything is affordable.

### 7. Buy-max / hold-to-buy
Late game, levelling from 30 to 40 costs 10 separate taps. Add repeat-buy on a
long press, or a "buy x10" affordance.

### 8. Number precision ceiling
`GameState` stores cash as a `Double`. Beyond ~1e15 the integer part loses
precision and `Format.num` has suffixes only up to `Oc` (1e27). Fine for the MVP
horizon; needs a mantissa/exponent representation for a real prestige loop.

### 9. Passive income accrues only while the app is open or via the offline claim
`MainView.onFrame` drives accrual at 25 fps while the money screen is showing.
The upgrade and automation screens do not accrue (their timers only repaint), so
sitting on the automation screen silently pauses passive income. Accrual should
move to a single app-level ticker.

### 10. Offline earnings trust the system clock
`GameState.computeOffline` clamps negative elapsed time to 0, but a player who
moves the watch clock forward is credited up to the full 8-hour cap. Consider
`System.getTimer`-based sanity checks or accepting it as harmless.

### 11. Autosave interval is frame-counted, not time-based
`MainView` saves every 500 frames (~20s at 40ms). If the timer is throttled the
interval drifts. Should key off `System.getTimer()`.

### 12. Save migration path is untested
`GameState.load` versions the payload and ignores newer/unknown versions, which
silently discards a future save on a downgrade. There is no migration function
and no test for a v1 -> v2 upgrade.

### 13. No automated tests
Nothing covers `Format.num` (the trailing-zero stripping in particular), the
upgrade cost curves, or offline-earnings clamping. Connect IQ supports unit tests
via `(:test)` annotations and `monkeyc --unit-test`.

### 14. Only venu2 is build-verified
`manifest.xml` lists 11 products; only `venu2` (416x416, round) has been compiled
and loaded. Square (venusq2) and smaller round (venu2s, 360x360) layouts use the
same fractional positions and have not been checked — text may collide at 0.56h /
0.645h on short screens.

### 15. Launcher icon is a placeholder
`resources/drawables/launcher_icon.png` is a generated green circle at 70x70.
Devices with other launcher icon sizes get a scaled copy.

### 16. Gesture handling has an untested fallback path
`MainDelegate.onSwipe` exists for devices that report gestures without drag
coordinates, and awards a fixed minimum-distance swipe. It is suppressed for
400ms after a drag; that de-duplication window is a guess and has not been
validated on hardware.

### 17. No interactive verification on hardware or in the simulator
The app compiles and loads in the venu2 simulator, but no gesture, purchase, or
offline-claim flow has been exercised end to end.
