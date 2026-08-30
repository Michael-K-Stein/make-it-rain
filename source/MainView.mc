using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Timer;
using Toybox.System;
using Toybox.Attention;
using Toybox.Math;

class MainView extends WatchUi.View {

    static const FRAME_MS = 50;   // 20fps: below this the platform clamps the timer anyway
    // Swipe hint fades out once the player has clearly got it, and comes
    // back if they step away for a while.
    static const HINT_TEACH_SWIPES = 4;
    static const HINT_RETURN_IDLE_FRAMES = 20 * 30;   // ~30s of inactivity at 20fps

    hidden var rain;
    hidden var timer;
    hidden var idleFrames = 0;

    // floating "+$x" feedback
    hidden var gainText = null;
    hidden var gainLife = 0;
    hidden var gainCrit = false;

    // milestone celebration
    hidden var msText = null;
    hidden var msLife = 0;

    function initialize() {
        View.initialize();
        rain = new MoneyRain();
    }

    function onShow() {
        timer = new Timer.Timer();
        timer.start(method(:onFrame), FRAME_MS, true);
    }

    function onHide() {
        if (timer != null) { timer.stop(); timer = null; }
        $.gGame.save();
    }

    function onFrame() as Void {
        var now = System.getTimer();

        var busy = false;
        if (rain.isActive()) { rain.update(); busy = true; }
        if (gainLife > 0) { gainLife--; busy = true; }
        if (msLife > 0) { msLife--; busy = true; }
        if ($.gGame.tickStreak(now)) { busy = true; }

        var m = $.gGame.takeMilestone();
        if (m != null) { showMilestone(m); busy = true; }

        if (busy) {
            idleFrames = 0;
            WatchUi.requestUpdate();
        } else {
            // Idle: refresh roughly once a second so the passive-income
            // ticker (driven by MakeItRainApp) is still reflected on screen,
            // and so the swipe hint can reappear after a long pause.
            idleFrames++;
            if (idleFrames % 25 == 0) { WatchUi.requestUpdate(); }
        }
    }

    function showMilestone(value) {
        msText = Format.cash(value);
        msLife = 45;
        vibe(100, 80);
        tone(Attention has :TONE_KEY ? Attention.TONE_KEY : null);
    }

    // Called by the delegate after a qualifying swipe.
    function onSwipeEarned(result, x, y) {
        gainText = Format.gain(result[:amount]);
        gainCrit = result[:crit];
        gainLife = 14;
        idleFrames = 0;
        rain.burst(x, y, gainCrit ? 12 : 6, gainCrit);
        vibe(gainCrit ? 75 : 25, gainCrit ? 120 : 40);
        tone(gainCrit
            ? (Attention has :TONE_LOUD_BEEP ? Attention.TONE_LOUD_BEEP : null)
            : (Attention has :TONE_CLICK ? Attention.TONE_CLICK : null));
        WatchUi.requestUpdate();
    }

    hidden function vibe(strength, duration) {
        if (Attention has :vibrate && Attention has :VibeProfile) {
            try {
                Attention.vibrate([new Attention.VibeProfile(strength, duration)]);
            } catch (e) {
                // Vibration unsupported or disabled; feedback is visual anyway.
            }
        }
    }

    hidden function tone(t) {
        if (t == null) { return; }
        if (Attention has :playTone) {
            try {
                Attention.playTone(t);
            } catch (e) {
                // Tone unsupported, muted by the system, or DND is on.
            }
        }
    }

    hidden function cashFont(dc, text, maxWidth) {
        var fonts = [Graphics.FONT_NUMBER_THAI_HOT, Graphics.FONT_NUMBER_HOT,
                     Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD];
        for (var i = 0; i < fonts.size(); i++) {
            if (dc.getTextWidthInPixels(text, fonts[i]) <= maxWidth) { return fonts[i]; }
        }
        return Graphics.FONT_NUMBER_MILD;
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var g = $.gGame;

        dc.setColor(Theme.BG, Theme.BG);
        dc.clear();

        if (msLife > 0) { drawMilestone(dc, w, h); return; }

        // Money behind the number so notes read as falling past it.
        rain.draw(dc);

        // --- the focal point: current cash ---
        var cashStr = Format.cash(g.cash);
        var f = cashFont(dc, cashStr, w * 0.82);
        dc.setColor(Theme.CASH, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.36, f, cashStr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- swipe gain feedback ---
        if (gainLife > 0 && gainText != null) {
            var rise = (14 - gainLife) * 2;
            dc.setColor(gainCrit ? Theme.CRIT : Theme.POSITIVE, Graphics.COLOR_TRANSPARENT);
            if (gainCrit) {
                dc.drawText(w / 2, h * 0.13 - rise, Graphics.FONT_XTINY, "MEGA SWIPE",
                            Graphics.TEXT_JUSTIFY_CENTER);
            }
            dc.drawText(w / 2, h * 0.19 - rise,
                        gainCrit ? Graphics.FONT_MEDIUM : Graphics.FONT_SMALL,
                        gainText, Graphics.TEXT_JUSTIFY_CENTER);
        } else if (g.streak >= 3) {
            dc.setColor(Theme.CRIT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 0.17, Graphics.FONT_XTINY,
                        "x" + g.streak.toString() + "  " + g.streakMultiplier().format("%.2f"),
                        Graphics.TEXT_JUSTIFY_CENTER);
        }

        // --- rate line ---
        dc.setColor(Theme.CASH_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.56, Graphics.FONT_XTINY,
                    Format.cash(g.cashPerSwipe()) + " / swipe",
                    Graphics.TEXT_JUSTIFY_CENTER);
        if (g.passiveIncome() > 0) {
            dc.drawText(w / 2, h * 0.645, Graphics.FONT_XTINY,
                        Format.cash(g.passiveIncome()) + " / sec",
                        Graphics.TEXT_JUSTIFY_CENTER);
        }

        if (g.totalSwipes < HINT_TEACH_SWIPES || idleFrames >= HINT_RETURN_IDLE_FRAMES) {
            drawSwipeHint(dc, w, h);
        }
        drawEdgeHints(dc, w, h);
    }

    hidden function drawSwipeHint(dc, w, h) {
        // Three chevrons pointing down: the whole instruction, no text needed.
        var cx = w / 2;
        var top = h * 0.75;
        dc.setPenWidth(4);
        for (var i = 0; i < 3; i++) {
            var y = top + i * 16;
            var shade = (i == 0) ? Theme.CASH : ((i == 1) ? Theme.CASH_DIM : Theme.MUTED);
            dc.setColor(shade, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(cx - 22, y, cx, y + 12);
            dc.drawLine(cx, y + 12, cx + 22, y);
        }
        dc.setPenWidth(1);
    }

    hidden function drawEdgeHints(dc, w, h) {
        var g = $.gGame;
        // A brighter dot means something on that screen can be bought right now.
        var upgradeReady = g.cash >= g.swipeUpgradeCost()
            || (g.critUnlocked() && g.cash >= g.critUpgradeCost());
        var autoReady = g.cash >= g.autoUpgradeCost();

        dc.setColor(upgradeReady ? Theme.ACCENT : Theme.MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - 6, h / 2, Graphics.FONT_XTINY, "U",
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(autoReady ? Theme.ACCENT : Theme.MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, h / 2, Graphics.FONT_XTINY, "A",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.95, Graphics.FONT_XTINY, "S",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function drawMilestone(dc, w, h) {
        dc.setColor(Theme.CRIT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.28, Graphics.FONT_SMALL, "MILESTONE",
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Theme.CASH, Graphics.COLOR_TRANSPARENT);
        var f = cashFont(dc, msText, w * 0.82);
        dc.drawText(w / 2, h * 0.50, f, msText,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.POSITIVE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.70, Graphics.FONT_XTINY, "KEEP SWIPING",
                    Graphics.TEXT_JUSTIFY_CENTER);
    }
}
