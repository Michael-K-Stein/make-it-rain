using Toybox.Lang;
using Toybox.Math;

// Compact currency formatting: $950, $12.4K, $3.7M, $2.1B ...
module Format {

    const SUFFIX = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc"];

    // Returns e.g. "12.4K" (no dollar sign)
    function num(value) {
        var v = value.toDouble();
        if (v < 0) { v = 0.0; }
        if (v < 1000.0) {
            return (v.toNumber()).toString();
        }
        var tier = 0;
        while (v >= 1000.0 && tier < SUFFIX.size() - 1) {
            v = v / 1000.0;
            tier++;
        }
        var s;
        if (v < 10.0) {
            s = v.format("%.2f");
        } else if (v < 100.0) {
            s = v.format("%.1f");
        } else {
            s = v.format("%.0f");
        }
        if (s.find(".") != null) {
            while (s.substring(s.length() - 1, s.length()).equals("0")) {
                s = s.substring(0, s.length() - 1);
            }
            if (s.substring(s.length() - 1, s.length()).equals(".")) {
                s = s.substring(0, s.length() - 1);
            }
        }
        return s + SUFFIX[tier];
    }

    function cash(value) {
        return "$" + num(value);
    }

    function gain(value) {
        return "+$" + num(value);
    }

    function duration(seconds) {
        if (seconds < 60) { return seconds.toNumber().toString() + "s"; }
        if (seconds < 3600) { return (seconds / 60).toNumber().toString() + "m"; }
        return (seconds / 3600).toNumber().toString() + "h";
    }
}
