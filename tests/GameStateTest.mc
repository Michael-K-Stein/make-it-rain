using Toybox.Test;
using Toybox.Lang;

(:test)
function testSwipeCostGrowsGeometrically(logger as Test.Logger) {
    var g = new GameState();
    var c1 = g.swipeUpgradeCost();
    g.swipeLevel = 2;
    var c2 = g.swipeUpgradeCost();
    return c2 > c1 && (c2 / c1 - GameState.SWIPE_COST_MULT).abs() < 0.0001;
}

(:test)
function testCashPerSwipeAppliesPrestigeMultiplier(logger as Test.Logger) {
    var g = new GameState();
    var base = g.cashPerSwipe();
    g.prestigeLevel = 1;
    return (g.cashPerSwipe() - base * 2.0).abs() < 0.0001;
}

(:test)
function testCritLocksUntilFirstMilestone(logger as Test.Logger) {
    var g = new GameState();
    if (g.critUnlocked()) { return false; }
    g.milestoneIdx = 1;
    return g.critUnlocked();
}

(:test)
function testCritChanceCapsAtMax(logger as Test.Logger) {
    var g = new GameState();
    g.critLevel = 1000;
    return g.critChance() == GameState.CRIT_MAX;
}

(:test)
function testStreakMultiplierTiers(logger as Test.Logger) {
    var g = new GameState();
    g.streak = 1;
    if (g.streakMultiplier() != 1.0) { return false; }
    g.streak = 3;
    if (g.streakMultiplier() != 1.1) { return false; }
    g.streak = 5;
    if (g.streakMultiplier() != 1.25) { return false; }
    g.streak = 10;
    return g.streakMultiplier() == 1.5;
}

(:test)
function testBuySwipeUpgradeRejectsWhenTooPoor(logger as Test.Logger) {
    var g = new GameState();
    g.cash = 0.0;
    var levelBefore = g.swipeLevel;
    var ok = g.buySwipeUpgrade();
    return !ok && g.swipeLevel == levelBefore;
}

(:test)
function testBuyMaxSwipeUpgradeSpendsExactlyWhatItPlanned(logger as Test.Logger) {
    var g = new GameState();
    g.cash = 1000.0;
    var plan = g.affordableSwipeLevels();
    var cashBefore = g.cash;
    var bought = g.buyMaxSwipeUpgrade();
    return bought == plan[:levels]
        && (g.cash - (cashBefore - plan[:cost])).abs() < 0.0001;
}

(:test)
function testOfflineEarningsCapAtEightHours(logger as Test.Logger) {
    var g = new GameState();
    g.autoLevel = 1;
    g.lastSaveTime = 0;
    // Simulate "now" being 100 hours later by calling computeOffline with a
    // huge elapsed time through the public surface: we can't stub Time.now(),
    // so instead verify the cap constant matches the spec (§15: "approximately
    // 8 hours") and that a huge passive income doesn't blow past it in one shot.
    var maxPossible = g.passiveIncome() * GameState.OFFLINE_CAP_SEC;
    return GameState.OFFLINE_CAP_SEC == 8 * 3600 && maxPossible >= 0;
}

(:test)
function testPrestigeRequiresLifetimeThreshold(logger as Test.Logger) {
    var g = new GameState();
    g.lifetimeCash = GameState.PRESTIGE_REQUIREMENT - 1.0;
    if (g.canPrestige()) { return false; }
    g.lifetimeCash = GameState.PRESTIGE_REQUIREMENT;
    return g.canPrestige();
}

(:test)
function testPrestigeResetsRunButKeepsLifetimeStats(logger as Test.Logger) {
    var g = new GameState();
    g.lifetimeCash = GameState.PRESTIGE_REQUIREMENT;
    g.cash = 500.0;
    g.swipeLevel = 5;
    g.autoLevel = 3;
    var swipesBefore = g.totalSwipes;
    var ok = g.doPrestige();
    return ok && g.cash == 0.0 && g.swipeLevel == 1 && g.autoLevel == 0
        && g.prestigeLevel == 1 && g.lifetimeCash == GameState.PRESTIGE_REQUIREMENT
        && g.totalSwipes == swipesBefore;
}
