using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Timer;

// One upgrade fills the screen. Swipe up/down cycles between the two,
// tap buys, swipe right (or back) exits.
class UpgradeView extends WatchUi.View {

    static const CARD_SWIPE = 0;
    static const CARD_CRIT  = 1;

    var card = CARD_SWIPE;
    hidden var flash = 0;       // >0 bought, <0 rejected
    hidden var timer;

    function initialize() {
        View.initialize();
    }

    function onShow() {
        timer = new Timer.Timer();
        timer.start(method(:onFrame), 100, true);
    }

    function onHide() {
        if (timer != null) { timer.stop(); timer = null; }
    }

    function onFrame() as Void {
        if (flash != 0) {
            flash = (flash > 0) ? flash - 1 : flash + 1;
            WatchUi.requestUpdate();
        }
    }

    function nextCard() {
        card = (card == CARD_SWIPE) ? CARD_CRIT : CARD_SWIPE;
        WatchUi.requestUpdate();
    }

    function buy() {
        var ok = (card == CARD_SWIPE) ? $.gGame.buySwipeUpgrade()
                                      : $.gGame.buyCritUpgrade();
        flash = ok ? 5 : -5;
        WatchUi.requestUpdate();
        return ok;
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var g = $.gGame;

        dc.setColor(Theme.BG, Theme.BG);
        dc.clear();

        var title, fromTo, cost, affordable;
        if (card == CARD_SWIPE) {
            title  = "CASH / SWIPE";
            fromTo = Format.cash(g.cashPerSwipe()) + "  >  " + Format.cash(g.nextCashPerSwipe());
            cost   = g.swipeUpgradeCost();
            affordable = g.cash >= cost;
        } else {
            title  = "MEGA SWIPE";
            fromTo = (g.critChance() * 100).format("%.0f") + "%  >  "
                     + (g.nextCritChance() * 100).format("%.0f") + "%";
            cost   = g.critUpgradeCost();
            affordable = g.cash >= cost && g.critChance() < GameState.CRIT_MAX;
        }

        dc.setColor(Theme.ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.13, Graphics.FONT_TINY, title,
                    Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Theme.POSITIVE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.30, Graphics.FONT_SMALL, fromTo,
                    Graphics.TEXT_JUSTIFY_CENTER);

        // Your wallet, big, so the buy decision needs no thought.
        dc.setColor(Theme.CASH, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.48, Graphics.FONT_NUMBER_MEDIUM, Format.cash(g.cash),
                    Graphics.TEXT_JUSTIFY_CENTER);

        var btnColor = affordable ? Theme.ACCENT : Theme.MUTED;
        if (flash > 0) { btnColor = Theme.CASH; }
        if (flash < 0) { btnColor = Theme.LOCKED; }
        dc.setColor(btnColor, Graphics.COLOR_TRANSPARENT);
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
        dc.drawText(w / 2, h * 0.87, Graphics.FONT_XTINY, "swipe up for more",
                    Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class UpgradeDelegate extends WatchUi.BehaviorDelegate {

    hidden var view;

    function initialize(v) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onTap(evt) {
        view.buy();
        return true;
    }

    function onSelect() {
        view.buy();
        return true;
    }

    function onSwipe(evt) {
        var d = evt.getDirection();
        if (d == WatchUi.SWIPE_RIGHT) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        if (d == WatchUi.SWIPE_UP || d == WatchUi.SWIPE_DOWN) {
            view.nextCard();
            return true;
        }
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
