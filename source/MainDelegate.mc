using Toybox.WatchUi;
using Toybox.System;

class MainDelegate extends WatchUi.BehaviorDelegate {

    hidden var view;
    hidden var sx = 0;
    hidden var sy = 0;
    hidden var startMs = 0;
    hidden var dragging = false;
    hidden var lastDragMs = 0;   // suppresses the duplicate onSwipe that follows a drag

    function initialize(v) {
        BehaviorDelegate.initialize();
        view = v;
    }

    hidden function minSwipe(w) { return (w * 0.145).toNumber(); }   // ~60px on a 416px screen
    hidden function edge(w)     { return (w * 0.22).toNumber(); }

    function onDrag(evt) {
        var c = evt.getCoordinates();
        var type = evt.getType();

        if (type == WatchUi.DRAG_TYPE_START) {
            sx = c[0];
            sy = c[1];
            startMs = System.getTimer();
            dragging = true;
            return true;
        }
        if (type != WatchUi.DRAG_TYPE_STOP || !dragging) {
            return true;
        }
        dragging = false;
        lastDragMs = System.getTimer();

        var dim = System.getDeviceSettings();
        var w = dim.screenWidth;
        var h = dim.screenHeight;
        var dx = c[0] - sx;
        var dy = c[1] - sy;
        var minD = minSwipe(w);
        var e = edge(w);

        // --- navigation: only from the side edges, so fast money swiping
        //     in the centre can never trigger it ---
        if (sx >= w - e && dx <= -minD && dx.abs() > dy.abs()) {
            var uv = new UpgradeView();
            WatchUi.pushView(uv, new UpgradeDelegate(uv), WatchUi.SLIDE_LEFT);
            return true;
        }
        if (sx <= e && dx >= minD && dx.abs() > dy.abs()) {
            var av = new AutomationView();
            WatchUi.pushView(av, new AutomationDelegate(av), WatchUi.SLIDE_RIGHT);
            return true;
        }

        // --- money: any downward swipe elsewhere ---
        if (dy >= minD && dy > dx.abs()) {
            earn(dy, h, System.getTimer() - startMs, c[0], c[1]);
        }
        return true;
    }

    hidden function earn(dy, h, elapsedMs, x, y) {
        var minD = minSwipe(h);
        // Longer swipes pay a little more, capped so a normal flick stays fine.
        var factor = 1.0 + (dy - minD).toDouble() / (h * 2.0);
        if (elapsedMs > 0 && elapsedMs < 200) { factor += 0.05; }   // fast flick bonus
        if (factor > 1.25) { factor = 1.25; }
        if (factor < 1.0)  { factor = 1.0; }

        var result = $.gGame.doSwipe(System.getTimer(), factor);
        view.onSwipeEarned(result, x, y);
    }

    // Fallback for devices that report gestures without drag coordinates.
    function onSwipe(evt) {
        if (System.getTimer() - lastDragMs < 400) { return true; }
        var d = evt.getDirection();
        var h = System.getDeviceSettings().screenHeight;
        if (d == WatchUi.SWIPE_DOWN) {
            earn(minSwipe(h), h, 0, System.getDeviceSettings().screenWidth / 2, h / 2);
        }
        return true;
    }

    function onKey(evt) {
        if (evt.getKey() == WatchUi.KEY_ENTER) {
            var uv = new UpgradeView();
            WatchUi.pushView(uv, new UpgradeDelegate(uv), WatchUi.SLIDE_LEFT);
            return true;
        }
        return false;
    }
}
