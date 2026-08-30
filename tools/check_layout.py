#!/usr/bin/env python3
"""Check Make It Rain's geometry against a round display.

Every screen positions its elements as fractions of width/height, so the same
layout serves every round watch in the manifest, from a 416x416 Venu 2 down to
a 260x260 Venu Sq 2. On a round screen the corners don't exist, so this
reproduces that fractional arithmetic (mirroring MainView.onUpdate,
UpgradeView.onUpdate, AutomationView.onUpdate and StatsView.onUpdate) and
asserts every button and text row stays inside the circle.

Text rows are checked against the *chord* width of the display at their own
height: a row near the top or bottom of a round screen has far less usable
width than one across the middle.

    python3 tools/check_layout.py
"""
import math
import sys

# Screen sizes actually exercised: the largest and smallest round watches
# named in manifest.xml.
SIZES = [416, 360, 260]

# (name, x_fraction, y_fraction, w_fraction, h_fraction) - mirrors the
# `bx`/`by`/`bw`/`bh` buy-button rectangle shared by UpgradeView.mc,
# AutomationView.mc and StatsView.mc.
BUY_BUTTONS = [
    ("UpgradeView buy button", 0.18, 0.68, 0.64, 0.16),
    ("AutomationView buy button", 0.18, 0.68, 0.64, 0.16),
    ("StatsView prestige button", 0.18, 0.68, 0.64, 0.16),
    ("StatsView confirm button", 0.22, 0.72, 0.56, 0.12),
]

# (name, y_fraction, needed_px_at_416) - a centred text row, and roughly how
# wide its longest realistic string needs to be at the reference size. Scaled
# down proportionally for smaller screens below.
TEXT_ROWS = [
    ("MainView cash readout", 0.36, 340),
    ("MainView cash/swipe rate", 0.56, 220),
    ("MainView passive-income rate", 0.645, 220),
    ("StatsView lifetime cash", 0.24, 300),
]


def chord_half_width(radius, dy):
    d = abs(dy)
    if d >= radius:
        return 0
    return math.sqrt(float(radius * radius - d * d))


def check_rect(size, name, xf, yf, wf, hf, problems, margin=2):
    x, y = xf * size, yf * size
    rw, rh = wf * size, hf * size
    radius = size / 2.0 - margin
    for cx, cy in ((x, y), (x + rw, y), (x, y + rh), (x + rw, y + rh)):
        dist = math.hypot(cx - size / 2.0, cy - size / 2.0)
        if dist > radius:
            problems.append("%dpx: %s corner (%.0f,%.0f) is %.1fpx outside the display"
                            % (size, name, cx, cy, dist - radius))


def check_text_row(size, name, yf, needed_at_416, problems):
    needed = needed_at_416 * (size / 416.0)
    y = yf * size
    half = chord_half_width(size / 2.0 - 2, y - size / 2.0)
    if half * 2 < needed:
        problems.append("%dpx: %s at %.0f%% has %.0fpx of width, needs %.0f"
                        % (size, name, yf * 100, half * 2, needed))


def main():
    problems = []
    for size in SIZES:
        for name, xf, yf, wf, hf in BUY_BUTTONS:
            check_rect(size, name, xf, yf, wf, hf, problems)
        for name, yf, needed in TEXT_ROWS:
            check_text_row(size, name, yf, needed, problems)

    if problems:
        for problem in problems:
            print("   FAIL %s" % problem)
        return 1

    print("   OK   layout fits %d round sizes (%s)"
          % (len(SIZES), ", ".join("%dpx" % s for s in SIZES)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
