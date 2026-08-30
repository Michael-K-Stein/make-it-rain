using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Timer;

// The idle half of the game: one machine, one upgrade button.
class AutomationView extends WatchUi.View {

    hidden var flash = 0;
    hidden var timer;

    function initialize() {
        View.initialize();
    }

    function onShow() {
        timer = new Timer.Timer();
        timer.start(method(:onFrame), 250, true);
    }

    function onHide() {
        if (timer != null) { timer.stop(); timer = null; }
    }

    function onFrame() as Void {
        if (flash != 0) {
            flash = (flash > 0) ? flash - 1 : flash + 1;
        }
        WatchUi.requestUpdate();   // keeps the live cash counter moving
    }

    function buy() {
        flash = $.gGame.buyAutoUpgrade() ? 3 : -3;
        WatchUi.requestUpdate();
    }

    // Long-press: buy every level the current cash affords in one go.
    function buyMax() {
        flash = ($.gGame.buyMaxAutoUpgrade() > 0) ? 3 : -3;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var g = $.gGame;

        dc.setColor(Theme.BG, Theme.BG);
        dc.clear();

        dc.setColor(Theme.ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.11, Graphics.FONT_TINY, "CASH MACHINE",
                    Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Theme.CASH, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.30, Graphics.FONT_NUMBER_MEDIUM,
                    Format.cash(g.passiveIncome()),
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Theme.CASH_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.46, Graphics.FONT_XTINY,
                    "per sec   Lv. " + g.autoLevel.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Theme.POSITIVE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.56, Graphics.FONT_XTINY,
                    "next  " + Format.cash(g.nextPassiveIncome()) + " / sec",
                    Graphics.TEXT_JUSTIFY_CENTER);

        var cost = g.autoUpgradeCost();
        var color = (g.cash >= cost) ? Theme.ACCENT : Theme.MUTED;
        if (flash > 0) { color = Theme.CASH; }
        if (flash < 0) { color = Theme.LOCKED; }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        var bx = w * 0.18;
        var by = h * 0.68;
        var bw = w * 0.64;
        var bh = h * 0.16;
        dc.drawRoundedRectangle(bx, by, bw, bh, 12);
        dc.drawText(w / 2, by + bh / 2, Graphics.FONT_SMALL, "BUY " + Format.cash(cost),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setPenWidth(1);

        dc.setColor(Theme.MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.87, Graphics.FONT_XTINY, "hold to buy max",
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, h * 0.95, Graphics.FONT_XTINY, Format.cash(g.cash),
                    Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class AutomationDelegate extends WatchUi.BehaviorDelegate {

    hidden var view;

    function initialize(v) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onTap(evt)  { view.buy(); return true; }
    function onSelect()  { view.buy(); return true; }
    function onHold(evt) { view.buyMax(); return true; }

    function onSwipe(evt) {
        if (evt.getDirection() == WatchUi.SWIPE_LEFT) {
            WatchUi.popView(WatchUi.SLIDE_LEFT);
        }
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_LEFT);
        return true;
    }
}
