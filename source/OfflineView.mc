using Toybox.Graphics;
using Toybox.WatchUi;

// "Welcome back" screen. One tap claims everything.
class OfflineView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Theme.BG, Theme.BG);
        dc.clear();

        dc.setColor(Theme.POSITIVE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.20, Graphics.FONT_TINY, "WELCOME BACK",
                    Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Theme.CASH, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.36, Graphics.FONT_NUMBER_MEDIUM,
                    Format.cash($.gGame.pendingOffline),
                    Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Theme.MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.60, Graphics.FONT_XTINY, "while you were away",
                    Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Theme.ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.74, Graphics.FONT_SMALL, "TAP TO CLAIM",
                    Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class OfflineDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    hidden function claim() {
        $.gGame.claimOffline();
        var v = new MainView();
        WatchUi.switchToView(v, new MainDelegate(v), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onTap(evt) { return claim(); }
    function onSelect() { return claim(); }
    function onBack()   { return claim(); }
}
