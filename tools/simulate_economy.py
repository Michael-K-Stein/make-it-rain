#!/usr/bin/env python3
"""Play Make It Rain very fast, to check the difficulty curve.

This mirrors the formulas in `source/GameState.mc`. It drives a greedy player
who always buys whichever upgrade adds the most income per dollar - cash/swipe,
passive income, or (once unlocked) mega-swipe chance - and prints when each
milestone and prestige lands, so pacing can be checked without grinding it out
on a watch.

    python3 tools/simulate_economy.py
    python3 tools/simulate_economy.py --hours 8 --taps 0.5
    python3 tools/simulate_economy.py --hours 48 --taps 0   # pure idle

Keep this in step with source/GameState.mc: the constants below are a copy,
and the whole point of the script is that they match (see check_constants.py).
"""
import argparse
import math

# --- mirrored from source/GameState.mc --------------------------------------
SWIPE_BASE = 1.0
SWIPE_GROWTH = 1.4
SWIPE_COST_BASE = 10.0
SWIPE_COST_MULT = 1.55

AUTO_BASE = 0.5
AUTO_GROWTH = 1.15
AUTO_COST_BASE = 50.0
AUTO_COST_MULT = 1.62

CRIT_BASE = 0.05
CRIT_STEP = 0.02
CRIT_MAX = 0.40
CRIT_MULT = 10.0
CRIT_COST_BASE = 250.0
CRIT_COST_MULT = 2.4

STREAK_WINDOW_MS = 2500

MILESTONES = [1000.0, 10000.0, 100000.0, 1000000.0,
              10000000.0, 100000000.0, 1000000000.0]
CRIT_UNLOCK_MILESTONE_IDX = 1

PRESTIGE_REQUIREMENT = 1000000.0
PRESTIGE_BONUS_PER_LEVEL = 1.0


def cash_per_swipe(swipe_level, prestige_level):
    mult = 1.0 + PRESTIGE_BONUS_PER_LEVEL * prestige_level
    return SWIPE_BASE * (SWIPE_GROWTH ** (swipe_level - 1)) * mult


def swipe_cost(swipe_level):
    return SWIPE_COST_BASE * (SWIPE_COST_MULT ** (swipe_level - 1))


def passive_income(auto_level, prestige_level):
    if auto_level <= 0:
        return 0.0
    mult = 1.0 + PRESTIGE_BONUS_PER_LEVEL * prestige_level
    return AUTO_BASE * auto_level * (AUTO_GROWTH ** (auto_level - 1)) * mult


def auto_cost(auto_level):
    return AUTO_COST_BASE * (AUTO_COST_MULT ** auto_level)


def crit_chance(crit_level):
    return min(CRIT_BASE + CRIT_STEP * crit_level, CRIT_MAX)


def crit_cost(crit_level):
    return CRIT_COST_BASE * (CRIT_COST_MULT ** crit_level)


def fmt_money(v):
    for suffix in ("", "K", "M", "B", "T", "q", "Q", "s", "S"):
        if abs(v) < 1000:
            return ("%.2f%s" if abs(v) < 10 else "%.0f%s") % (v, suffix)
        v /= 1000.0
    return "%.1fY" % v


def fmt_time(seconds):
    seconds = int(seconds)
    if seconds < 60:
        return "%ds" % seconds
    if seconds < 3600:
        return "%dm %02ds" % (seconds // 60, seconds % 60)
    if seconds < 86400:
        return "%dh %02dm" % (seconds // 3600, (seconds % 3600) // 60)
    return "%dd %02dh" % (seconds // 86400, (seconds % 86400) // 3600)


def simulate(hours, taps_per_second, step=1.0):
    swipe_level = 1
    auto_level = 0
    crit_level = 0
    prestige_level = 0
    cash = 0.0
    lifetime = 0.0
    milestone_idx = 0
    events = []

    for tick in range(int(hours * 3600 / step)):
        now = tick * step

        income = passive_income(auto_level, prestige_level) * step
        if taps_per_second > 0.0:
            # crit expectation folded into the average rate, same simplification
            # as the tap-in-idle assumption used elsewhere in this simulator.
            chance = crit_chance(crit_level) if milestone_idx >= CRIT_UNLOCK_MILESTONE_IDX else 0.0
            per_swipe = cash_per_swipe(swipe_level, prestige_level)
            per_swipe *= (1.0 - chance) + chance * CRIT_MULT
            income += per_swipe * taps_per_second * step
        cash += income
        lifetime += income

        while lifetime >= MILESTONES[milestone_idx] if milestone_idx < len(MILESTONES) else False:
            events.append((now, "milestone: %s lifetime" % fmt_money(MILESTONES[milestone_idx])))
            milestone_idx += 1

        # Greedy purchasing: whatever adds the most $/s (or, for swipe level,
        # the most $/swipe) per dollar spent, evaluated at the current tap rate.
        progressed = True
        while progressed:
            progressed = False
            best_kind, best_ratio = None, 0.0

            cost = swipe_cost(swipe_level)
            if cost <= cash and taps_per_second > 0.0:
                gain = (cash_per_swipe(swipe_level + 1, prestige_level)
                        - cash_per_swipe(swipe_level, prestige_level)) * taps_per_second
                ratio = gain / cost
                if ratio > best_ratio:
                    best_kind, best_ratio = "swipe", ratio

            cost = auto_cost(auto_level)
            if cost <= cash:
                gain = (passive_income(auto_level + 1, prestige_level)
                        - passive_income(auto_level, prestige_level))
                ratio = gain / cost
                if ratio > best_ratio:
                    best_kind, best_ratio = "auto", ratio

            if milestone_idx >= CRIT_UNLOCK_MILESTONE_IDX and crit_chance(crit_level) < CRIT_MAX:
                cost = crit_cost(crit_level)
                if cost <= cash and taps_per_second > 0.0:
                    per_swipe = cash_per_swipe(swipe_level, prestige_level)
                    before = crit_chance(crit_level)
                    after = crit_chance(crit_level + 1)
                    gain = per_swipe * (after - before) * (CRIT_MULT - 1.0) * taps_per_second
                    ratio = gain / cost
                    if ratio > best_ratio:
                        best_kind, best_ratio = "crit", ratio

            if best_kind == "swipe":
                cash -= swipe_cost(swipe_level)
                swipe_level += 1
                progressed = True
            elif best_kind == "auto":
                cash -= auto_cost(auto_level)
                auto_level += 1
                progressed = True
            elif best_kind == "crit":
                cash -= crit_cost(crit_level)
                crit_level += 1
                progressed = True

        if lifetime >= PRESTIGE_REQUIREMENT and prestige_level == 0 and cash < swipe_cost(swipe_level):
            # A greedy player prestiges as soon as the run has gone cold -
            # nothing left worth buying with what's on hand.
            events.append((now, "prestige available (x%.1f -> x%.1f)"
                          % (1.0 + PRESTIGE_BONUS_PER_LEVEL * prestige_level,
                             1.0 + PRESTIGE_BONUS_PER_LEVEL * (prestige_level + 1))))
            prestige_level += 1
            cash = 0.0
            swipe_level = 1
            auto_level = 0
            crit_level = 0

    return swipe_level, auto_level, crit_level, prestige_level, cash, lifetime, events


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--hours", type=float, default=2.0,
                    help="hours of play to simulate (default 2)")
    ap.add_argument("--taps", type=float, default=1.0, metavar="PER_SEC",
                    help="average swipes per second; 0 models pure idling")
    ap.add_argument("--step", type=float, default=1.0,
                    help="simulation step in seconds (default 1)")
    args = ap.parse_args()

    swipe_level, auto_level, crit_level, prestige_level, cash, lifetime, events = simulate(
        args.hours, args.taps, args.step)

    mode = "idle only" if args.taps <= 0.0 else "%.3g taps/s" % args.taps
    print("Make It Rain - %g hours, %s\n" % (args.hours, mode))
    for when, what in events:
        print("  %8s  %s" % (fmt_time(when), what))
    if not events:
        print("  nothing happened - a fresh run earns nothing without taps.")
        print("  Try --taps 1 to model someone actually swiping.")

    print("\n  final cash      %s" % fmt_money(cash))
    print("  lifetime earned %s" % fmt_money(lifetime))
    print("  swipe level     %d (%s/swipe)"
          % (swipe_level, fmt_money(cash_per_swipe(swipe_level, prestige_level))))
    print("  auto level      %d (%s/s)"
          % (auto_level, fmt_money(passive_income(auto_level, prestige_level))))
    print("  crit level      %d (%.0f%% chance)" % (crit_level, crit_chance(crit_level) * 100))
    print("  prestige level  %d (x%.1f)"
          % (prestige_level, 1.0 + PRESTIGE_BONUS_PER_LEVEL * prestige_level))


if __name__ == "__main__":
    main()
