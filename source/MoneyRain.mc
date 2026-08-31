using Toybox.Graphics;
using Toybox.Math;

// Lightweight particle burst. Fixed-size pool, no allocation per frame.
class MoneyRain {

    static const MAX = 14;
    static const LIFE = 16;   // frames (~640ms at 25fps)
    static const TWO_PI = Math.PI * 2.0;

    hidden var px, py, vx, vy, life, color, size, angle, spin;

    function initialize() {
        px = new [MAX]; py = new [MAX]; vx = new [MAX]; vy = new [MAX];
        life = new [MAX]; color = new [MAX]; size = new [MAX];
        angle = new [MAX]; spin = new [MAX];
        for (var i = 0; i < MAX; i++) { life[i] = 0; }
    }

    function burst(cx, cy, count, crit) {
        var spawned = 0;
        for (var i = 0; i < MAX && spawned < count; i++) {
            if (life[i] > 0) { continue; }
            px[i] = cx + (Math.rand() % 121) - 60;
            py[i] = cy + (Math.rand() % 61) - 30;
            vx[i] = ((Math.rand() % 9) - 4) * 0.6;
            vy[i] = -2.0 - (Math.rand() % 30) / 10.0;
            life[i] = LIFE;
            size[i] = 9 + (Math.rand() % 5);   // half-width; height follows a bill's aspect ratio
            color[i] = crit ? Theme.CRIT : ((Math.rand() % 2) == 0 ? Theme.MONEY : Theme.NOTE);
            angle[i] = (Math.rand() % 1000) / 1000.0 * TWO_PI;
            spin[i] = (((Math.rand() % 21) - 10) / 10.0) * 0.35;   // tumble, not spin in place
            spawned++;
        }
    }

    function isActive() {
        for (var i = 0; i < MAX; i++) {
            if (life[i] > 0) { return true; }
        }
        return false;
    }

    function update() {
        for (var i = 0; i < MAX; i++) {
            if (life[i] <= 0) { continue; }
            px[i] += vx[i];
            py[i] += vy[i];
            vy[i] += 0.45;          // gravity: pops up, then rains down
            angle[i] += spin[i];
            life[i]--;
        }
    }

    // A banknote as a tumbling rectangle: coloured body, pale paper inset,
    // dark seal - readable as "money" at a glance instead of a plain dot.
    hidden function drawNote(dc, cx, cy, a, hw, hh, body) {
        var ca = Math.cos(a);
        var sa = Math.sin(a);
        var corners = [[-hw, -hh], [hw, -hh], [hw, hh], [-hw, hh]];

        var outer = new [4];
        for (var i = 0; i < 4; i++) {
            var dx = corners[i][0];
            var dy = corners[i][1];
            outer[i] = [(cx + dx * ca - dy * sa).toNumber(), (cy + dx * sa + dy * ca).toNumber()];
        }
        dc.setColor(body, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(outer);

        var iw = hw * 0.6;
        var ih = hh * 0.5;
        var inset = new [4];
        for (var j = 0; j < 4; j++) {
            var idx = corners[j][0] * (iw / hw);
            var idy = corners[j][1] * (ih / hh);
            inset[j] = [(cx + idx * ca - idy * sa).toNumber(), (cy + idx * sa + idy * ca).toNumber()];
        }
        dc.setColor(Theme.NOTE_PAPER, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(inset);

        dc.setColor(Theme.NOTE_INK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx.toNumber(), cy.toNumber(), (hh * 0.3).toNumber());
    }

    function draw(dc) {
        for (var i = 0; i < MAX; i++) {
            if (life[i] <= 0) { continue; }
            var hw = size[i].toFloat();
            drawNote(dc, px[i], py[i], angle[i], hw, hw * 0.42, color[i]);
        }
    }

    function clear() {
        for (var i = 0; i < MAX; i++) { life[i] = 0; }
    }
}
