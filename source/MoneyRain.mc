using Toybox.Graphics;
using Toybox.Math;

// Lightweight particle burst. Fixed-size pool, no allocation per frame.
class MoneyRain {

    static const MAX = 14;
    static const LIFE = 12;   // frames (~500ms at 25fps)

    hidden var px, py, vx, vy, life, color, size;

    function initialize() {
        px = new [MAX]; py = new [MAX]; vx = new [MAX]; vy = new [MAX];
        life = new [MAX]; color = new [MAX]; size = new [MAX];
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
            size[i] = 4 + (Math.rand() % 4);
            color[i] = crit ? Theme.CRIT : ((Math.rand() % 2) == 0 ? Theme.MONEY : Theme.NOTE);
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
            life[i]--;
        }
    }

    function draw(dc) {
        for (var i = 0; i < MAX; i++) {
            if (life[i] <= 0) { continue; }
            dc.setColor(color[i], Graphics.COLOR_TRANSPARENT);
            var s = size[i];
            // a banknote: small filled rectangle
            dc.fillRectangle(px[i].toNumber(), py[i].toNumber(), s * 2, s);
        }
    }

    function clear() {
        for (var i = 0; i < MAX; i++) { life[i] = 0; }
    }
}
