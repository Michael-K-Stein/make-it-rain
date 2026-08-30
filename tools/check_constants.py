#!/usr/bin/env python3
"""Check that the Python tools still agree with source/GameState.mc.

`simulate_economy.py` only tells the truth about the difficulty curve while
its copy of the tuning matches the game's. Nothing in the build enforces
that, so a balance change lands in one file and quietly invalidates the
other. This parses the constants out of both and compares them.

    python3 tools/check_constants.py
"""
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# GameState.mc name -> simulate_economy.py name. Scalars only; MILESTONES is
# compared separately as an array.
SCALARS = {
    "SWIPE_BASE": "SWIPE_BASE",
    "SWIPE_GROWTH": "SWIPE_GROWTH",
    "SWIPE_COST_BASE": "SWIPE_COST_BASE",
    "SWIPE_COST_MULT": "SWIPE_COST_MULT",
    "AUTO_BASE": "AUTO_BASE",
    "AUTO_GROWTH": "AUTO_GROWTH",
    "AUTO_COST_BASE": "AUTO_COST_BASE",
    "AUTO_COST_MULT": "AUTO_COST_MULT",
    "CRIT_BASE": "CRIT_BASE",
    "CRIT_STEP": "CRIT_STEP",
    "CRIT_MAX": "CRIT_MAX",
    "CRIT_MULT": "CRIT_MULT",
    "CRIT_COST_BASE": "CRIT_COST_BASE",
    "CRIT_COST_MULT": "CRIT_COST_MULT",
    "CRIT_UNLOCK_MILESTONE_IDX": "CRIT_UNLOCK_MILESTONE_IDX",
    "PRESTIGE_REQUIREMENT": "PRESTIGE_REQUIREMENT",
    "PRESTIGE_BONUS_PER_LEVEL": "PRESTIGE_BONUS_PER_LEVEL",
}

ARRAYS = {
    "MILESTONES": "MILESTONES",
}


def number(text):
    """Read a Monkey C or Python numeric literal, and simple `a * b` products
    (used for e.g. `8 * 3600`). The `d`/`f` suffix marks a Monkey C
    Double/Float and carries no meaning here."""
    text = text.strip()
    parts = [p.strip().rstrip("dDfF") for p in text.split("*")]
    result = 1.0
    for p in parts:
        result *= float(p)
    return result


def monkey_constants(path):
    src = io.open(path, encoding="utf-8").read()
    scalars, arrays = {}, {}
    for name, value in re.findall(
            r"static\s+const\s+(\w+)\s*=\s*([^;\[][^;]*);", src):
        try:
            scalars[name] = number(value)
        except ValueError:
            pass   # a string constant (e.g. SAVE_KEY) - not tuning, skip it
    for name, body in re.findall(
            r"static\s+const\s+(\w+)\s*=\s*\[(.*?)\]\s*;", src, re.S):
        if name in ARRAYS:
            arrays[name] = [number(v) for v in body.split(",") if v.strip()]
    return scalars, arrays


def python_constants(path):
    src = io.open(path, encoding="utf-8").read()
    scalars, arrays = {}, {}
    for name, value in re.findall(r"^(\w+)\s*=\s*(-?[\d.]+)\s*$", src, re.M):
        scalars[name] = number(value)
    for name, body in re.findall(r"^(\w+)\s*=\s*\[(.*?)\]", src, re.M | re.S):
        if name in ARRAYS.values():
            arrays[name] = [number(v) for v in body.split(",") if v.strip()]
    return scalars, arrays


def main():
    mc = os.path.join(ROOT, "source", "GameState.mc")
    py = os.path.join(ROOT, "tools", "simulate_economy.py")
    mc_scalars, mc_arrays = monkey_constants(mc)
    py_scalars, py_arrays = python_constants(py)

    problems = []
    for mc_name, py_name in sorted(SCALARS.items()):
        if mc_name not in mc_scalars:
            problems.append("GameState.mc no longer defines %s" % mc_name)
            continue
        if py_name not in py_scalars:
            problems.append("simulate_economy.py is missing %s" % py_name)
            continue
        if mc_scalars[mc_name] != py_scalars[py_name]:
            problems.append("%s: GameState.mc has %g, simulate_economy.py has %g"
                            % (mc_name, mc_scalars[mc_name], py_scalars[py_name]))

    for mc_name, py_name in sorted(ARRAYS.items()):
        got, want = mc_arrays.get(mc_name), py_arrays.get(py_name)
        if got is None or want is None:
            problems.append("%s is missing from one of the two files" % mc_name)
        elif got != want:
            problems.append("%s differs:\n     GameState.mc %s\n     tools        %s"
                            % (mc_name, got, want))

    if problems:
        for problem in problems:
            print("   FAIL %s" % problem)
        print("\n   The simulation is only meaningful while these agree.")
        return 1

    print("   OK   %d constants and %d table(s) match source/GameState.mc"
          % (len(SCALARS), len(ARRAYS)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
