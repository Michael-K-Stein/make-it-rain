using Toybox.Test;
using Toybox.Lang;

(:test)
function testFormatSmall(logger as Test.Logger) {
    return Format.cash(0) .equals("$0")
        && Format.cash(1) .equals("$1")
        && Format.cash(950).equals("$950")
        && Format.cash(999).equals("$999");
}

(:test)
function testFormatThousands(logger as Test.Logger) {
    // trailing-zero stripping: 12400 -> "12.4K", not "12.40K"
    return Format.cash(12400).equals("$12.4K")
        && Format.cash(1000).equals("$1K")
        && Format.cash(1500).equals("$1.5K")
        && Format.cash(999999).equals("$1000K");
}

(:test)
function testFormatMillionsAndUp(logger as Test.Logger) {
    return Format.cash(3700000).equals("$3.7M")
        && Format.cash(2100000000).equals("$2.1B")
        && Format.cash(100000000).equals("$100M");
}

(:test)
function testFormatGain(logger as Test.Logger) {
    return Format.gain(125).equals("+$125");
}

(:test)
function testFormatRoundTierBoundary(logger as Test.Logger) {
    // A value that rounds up to the next thousand at 3 sig figs should
    // still read as e.g. "$10K", not "$9.996K" mangled or a stray dot.
    return Format.cash(9996).equals("$10K");
}
