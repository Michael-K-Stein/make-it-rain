using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Time;

var gGame = null;

class MakeItRainApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        $.gGame = new GameState();
    }

    function onStop(state) {
        if ($.gGame != null) { $.gGame.save(); }
    }

    function getInitialView() {
        if ($.gGame.pendingOffline > 0) {
            return [new OfflineView(), new OfflineDelegate()];
        }
        var v = new MainView();
        return [v, new MainDelegate(v)];
    }
}
