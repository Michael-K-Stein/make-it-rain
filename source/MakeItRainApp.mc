using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Time;

var gGame = null;

class MakeItRainApp extends Application.AppBase {

    static const TICK_MS = 1000;
    static const SAVE_EVERY_TICKS = 20;   // ~20s

    hidden var ticker;
    hidden var tickCount = 0;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        $.gGame = new GameState();
        // Passive income accrues here, independent of whichever view is on
        // screen, so parking on the automation screen doesn't pause it.
        ticker = new Timer.Timer();
        ticker.start(method(:onTick), TICK_MS, true);
    }

    function onStop(state) {
        if (ticker != null) { ticker.stop(); ticker = null; }
        if ($.gGame != null) { $.gGame.save(); }
    }

    function onTick() as Void {
        $.gGame.accrue(TICK_MS / 1000.0);
        WatchUi.requestUpdate();

        tickCount++;
        if (tickCount >= SAVE_EVERY_TICKS) {
            tickCount = 0;
            $.gGame.save();
        }
    }

    function getInitialView() {
        if ($.gGame.pendingOffline > 0) {
            return [new OfflineView(), new OfflineDelegate()];
        }
        var v = new MainView();
        return [v, new MainDelegate(v)];
    }
}
