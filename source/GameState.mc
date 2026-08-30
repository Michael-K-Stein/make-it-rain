using Toybox.Application;
using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Time;

// All game numbers live here. Views never mutate state directly.
class GameState {

    static const SAVE_VERSION = 1;
    static const SAVE_KEY = "save";

    // --- tuning ---------------------------------------------------------
    static const SWIPE_BASE      = 1.0;   // $ per swipe at level 1
    static const SWIPE_GROWTH    = 1.4;   // value multiplier per level
    static const SWIPE_COST_BASE = 10.0;
    static const SWIPE_COST_MULT = 1.55;

    static const AUTO_BASE       = 0.5;   // $/sec contributed per level
    static const AUTO_GROWTH     = 1.15;
    static const AUTO_COST_BASE  = 50.0;
    static const AUTO_COST_MULT  = 1.62;

    static const CRIT_BASE       = 0.05;  // 5%
    static const CRIT_STEP       = 0.02;
    static const CRIT_MAX        = 0.40;
    static const CRIT_MULT       = 10.0;
    static const CRIT_COST_BASE  = 250.0;
    static const CRIT_COST_MULT  = 2.4;

    static const STREAK_WINDOW_MS = 2500;
    static const OFFLINE_CAP_SEC  = 8 * 3600;

    static const MILESTONES = [1000.0, 10000.0, 100000.0, 1000000.0,
                               10000000.0, 100000000.0, 1000000000.0];

    // --- persisted ------------------------------------------------------
    var cash          = 0.0;
    var lifetimeCash  = 0.0;
    var swipeLevel    = 1;
    var autoLevel     = 0;
    var critLevel     = 0;
    var milestoneIdx  = 0;   // next milestone not yet celebrated
    var totalSwipes   = 0;
    var lastSaveTime  = 0;

    // --- transient ------------------------------------------------------
    var streak        = 0;
    var lastSwipeMs   = 0;
    var pendingOffline = 0.0;
    var pendingMilestone = null;

    function initialize() {
        load();
    }

    // --- derived --------------------------------------------------------
    function cashPerSwipe() {
        return SWIPE_BASE * Math.pow(SWIPE_GROWTH, swipeLevel - 1);
    }

    function swipeUpgradeCost() {
        return SWIPE_COST_BASE * Math.pow(SWIPE_COST_MULT, swipeLevel - 1);
    }

    function nextCashPerSwipe() {
        return SWIPE_BASE * Math.pow(SWIPE_GROWTH, swipeLevel);
    }

    function passiveIncome() {
        if (autoLevel <= 0) { return 0.0; }
        return AUTO_BASE * autoLevel * Math.pow(AUTO_GROWTH, autoLevel - 1);
    }

    function nextPassiveIncome() {
        var l = autoLevel + 1;
        return AUTO_BASE * l * Math.pow(AUTO_GROWTH, l - 1);
    }

    function autoUpgradeCost() {
        return AUTO_COST_BASE * Math.pow(AUTO_COST_MULT, autoLevel);
    }

    function critChance() {
        var c = CRIT_BASE + CRIT_STEP * critLevel;
        return c > CRIT_MAX ? CRIT_MAX : c;
    }

    function nextCritChance() {
        var c = CRIT_BASE + CRIT_STEP * (critLevel + 1);
        return c > CRIT_MAX ? CRIT_MAX : c;
    }

    function critUpgradeCost() {
        return CRIT_COST_BASE * Math.pow(CRIT_COST_MULT, critLevel);
    }

    function streakMultiplier() {
        if (streak >= 10) { return 1.5; }
        if (streak >= 5)  { return 1.25; }
        if (streak >= 3)  { return 1.1; }
        return 1.0;
    }

    // --- actions --------------------------------------------------------

    // distanceFactor: 1.0 for a minimum swipe, up to ~1.25 for a long one.
    // Returns { :amount, :crit, :streak, :milestone }
    function doSwipe(nowMs, distanceFactor) {
        if (nowMs - lastSwipeMs <= STREAK_WINDOW_MS) {
            streak++;
        } else {
            streak = 1;
        }
        lastSwipeMs = nowMs;
        totalSwipes++;

        var amount = cashPerSwipe() * streakMultiplier() * distanceFactor;
        var crit = (Math.rand() % 1000) < (critChance() * 1000).toNumber();
        if (crit) { amount = amount * CRIT_MULT; }

        addCash(amount);
        return { :amount => amount, :crit => crit, :streak => streak };
    }

    function tickStreak(nowMs) {
        if (streak > 0 && nowMs - lastSwipeMs > STREAK_WINDOW_MS) {
            streak = 0;
            return true;
        }
        return false;
    }

    function addCash(amount) {
        cash += amount;
        lifetimeCash += amount;
        checkMilestone();
    }

    function checkMilestone() {
        while (milestoneIdx < MILESTONES.size() && lifetimeCash >= MILESTONES[milestoneIdx]) {
            pendingMilestone = MILESTONES[milestoneIdx];
            milestoneIdx++;
        }
    }

    function takeMilestone() {
        var m = pendingMilestone;
        pendingMilestone = null;
        return m;
    }

    function buySwipeUpgrade() {
        var c = swipeUpgradeCost();
        if (cash < c) { return false; }
        cash -= c;
        swipeLevel++;
        save();
        return true;
    }

    function buyAutoUpgrade() {
        var c = autoUpgradeCost();
        if (cash < c) { return false; }
        cash -= c;
        autoLevel++;
        save();
        return true;
    }

    function buyCritUpgrade() {
        var c = critUpgradeCost();
        if (cash < c || critChance() >= CRIT_MAX) { return false; }
        cash -= c;
        critLevel++;
        save();
        return true;
    }

    // Passive accrual for `seconds` of live play.
    function accrue(seconds) {
        var inc = passiveIncome() * seconds;
        if (inc > 0) { addCash(inc); }
        return inc;
    }

    function claimOffline() {
        var amt = pendingOffline;
        pendingOffline = 0.0;
        if (amt > 0) { addCash(amt); save(); }
        return amt;
    }

    // --- persistence ----------------------------------------------------
    function save() {
        lastSaveTime = Time.now().value();
        Storage.setValue(SAVE_KEY, {
            "v"     => SAVE_VERSION,
            "cash"  => cash,
            "life"  => lifetimeCash,
            "swipe" => swipeLevel,
            "auto"  => autoLevel,
            "crit"  => critLevel,
            "ms"    => milestoneIdx,
            "n"     => totalSwipes,
            "t"     => lastSaveTime
        });
    }

    function load() {
        var d = Storage.getValue(SAVE_KEY);
        if (d == null || !(d instanceof Lang.Dictionary)) {
            lastSaveTime = Time.now().value();
            return;
        }
        // Unknown/newer save versions are ignored rather than mis-read.
        var v = d.get("v");
        if (v == null || v > SAVE_VERSION) {
            lastSaveTime = Time.now().value();
            return;
        }
        cash         = pick(d, "cash", 0.0).toDouble();
        lifetimeCash = pick(d, "life", cash).toDouble();
        swipeLevel   = pick(d, "swipe", 1).toNumber();
        autoLevel    = pick(d, "auto", 0).toNumber();
        critLevel    = pick(d, "crit", 0).toNumber();
        milestoneIdx = pick(d, "ms", 0).toNumber();
        totalSwipes  = pick(d, "n", 0).toNumber();
        lastSaveTime = pick(d, "t", Time.now().value()).toNumber();

        computeOffline();
    }

    hidden function pick(d, key, fallback) {
        var x = d.get(key);
        return x == null ? fallback : x;
    }

    function computeOffline() {
        var now = Time.now().value();
        var elapsed = now - lastSaveTime;
        if (elapsed < 0) { elapsed = 0; }              // clock moved backwards
        if (elapsed > OFFLINE_CAP_SEC) { elapsed = OFFLINE_CAP_SEC; }
        pendingOffline = passiveIncome() * elapsed;
        if (pendingOffline < 1.0) { pendingOffline = 0.0; }
    }
}
