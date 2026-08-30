using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Timer;

// Progression + prestige. Reached by pulling down from the top of the
// money screen (spec §8 assigns this slot to "Stats / Progression").
class StatsView extends WatchUi.View {

    hidden var confirming = false;
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
        if (flash != 0) { flash = (flash > 0) ? flash - 1 : flash + 1; }
        WatchUi.requestUpdate();
    }

    function armPrestige() {
        if (!$.gGame.canPrestige()) { return; }
        confirming = true;
        WatchUi.requestUpdate();
    }

    function cancelPrestige() {
        confirming = false;
        WatchUi.requestUpdate();
    }

    function confirmPrestige() {
        confirming = false;
        flash = $.gGame.doPrestige() ? 3 : -3;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var g = $.gGame;

        dc.setColor(Theme.BG, Theme.BG);
        dc.clear();

        if (confirming) {
            drawConfirm(dc, w, h);
            return;
        }

        dc.setColor(Theme.ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.09, Graphics.FONT_TINY, "STATS",
                    Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Theme.CASH, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.24, Graphics.FONT_NUMBER_MILD, Format.cash(g.lifetimeCash),
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Theme.MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.35, Graphics.FONT_XTINY, "lifetime earned",
                    Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Theme.POSITIVE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.45, Graphics.FONT_XTINY,
                    g.totalSwipes.toString() + " swipes",
                    Graphics.TEXT_JUSTIFY_CENTER);

        if (g.prestigeLevel > 0) {
            dc.setColor(Theme.CRIT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 0.52, Graphics.FONT_XTINY,
                        "prestige " + g.prestigeLevel.toString()
                        + "   x" + g.prestigeMultiplier().format("%.1f"),
                        Graphics.TEXT_JUSTIFY_CENTER);
        }

        var ready = g.canPrestige();
        var color = ready ? Theme.CRIT : Theme.MUTED;
        if (flash > 0) { color = Theme.CASH; }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        var bx = w * 0.14;
        var by = h * 0.68;
        var bw = w * 0.72;
        var bh = h * 0.16;
        dc.drawRoundedRectangle(bx, by, bw, bh, 12);
        var label = ready
            ? "PRESTIGE  x" + (g.prestigeMultiplier() + GameState.PRESTIGE_BONUS_PER_LEVEL).format("%.1f")
            : "PRESTIGE AT " + Format.cash(GameState.PRESTIGE_REQUIREMENT);
        dc.drawText(w / 2, by + bh / 2, Graphics.FONT_XTINY, label,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setPenWidth(1);

        dc.setColor(Theme.MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.9, Graphics.FONT_XTINY, "swipe down to exit",
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function drawConfirm(dc, w, h) {
        dc.setColor(Theme.CRIT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.22, Graphics.FONT_SMALL, "PRESTIGE?",
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Theme.POSITIVE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.38, Graphics.FONT_XTINY, "Resets cash & upgrades",
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Theme.CASH, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.52, Graphics.FONT_MEDIUM,
                    "x" + ($.gGame.prestigeMultiplier() + GameState.PRESTIGE_BONUS_PER_LEVEL).format("%.1f"),
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Theme.MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.63, Graphics.FONT_XTINY, "permanent earnings",
                    Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Theme.CRIT, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawRoundedRectangle(w * 0.18, h * 0.75, w * 0.64, h * 0.14, 12);
        dc.drawText(w / 2, h * 0.75 + h * 0.07, Graphics.FONT_SMALL, "TAP TO CONFIRM",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setPenWidth(1);
    }
}

class StatsDelegate extends WatchUi.BehaviorDelegate {

    hidden var view;

    function initialize(v) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onTap(evt) {
        if (view.confirming) {
            view.confirmPrestige();
        } else {
            view.armPrestige();
        }
        return true;
    }

    function onSelect() {
        if (view.confirming) {
            view.confirmPrestige();
        } else {
            view.armPrestige();
        }
        return true;
    }

    function onSwipe(evt) {
        if (view.confirming) {
            view.cancelPrestige();
            return true;
        }
        if (evt.getDirection() == WatchUi.SWIPE_DOWN || evt.getDirection() == WatchUi.SWIPE_UP) {
            WatchUi.popView(WatchUi.SLIDE_UP);
        }
        return true;
    }

    function onBack() {
        if (view.confirming) {
            view.cancelPrestige();
        } else {
            WatchUi.popView(WatchUi.SLIDE_UP);
        }
        return true;
    }
}
