const std = @import("std");
const util = @import("./util.zig");

pub fn hamming(comptime T: type, N: usize, n: usize) T {
    comptime util.ensureFloat(T);
    const a0 = 0.54;
    const a1 = 0.46;

    return a0 - a1 * std.math.cos(2 * std.math.pi * @intToFloat(T, n) / @intToFloat(T, N - 1));
}

pub fn hann(comptime T: type, N: usize, n: usize) T {
    comptime util.ensureFloat(T);
    return 0.5 * (1 - std.math.cos(2 * std.math.pi * @intToFloat(T, n) / @intToFloat(T, N - 1)));
}

test "hamming" {
    const N = 91;
    var sum: f64 = 0;

    for (0..N) |i| {
        sum += hamming(f64, N, i);
    }

    // I calculated the reference sum in octave via `sum(hamming(91))`
    try std.testing.expectApproxEqAbs(@as(f64, 48.68), sum, 0.000000001);
}

test "hann" {
    const N = 91;
    var sum: f64 = 0;

    for (0..N) |i| {
        sum += hann(f64, N, i);
    }

    // I calculated the reference sum in octave via `sum(hamming(91))`
    try std.testing.expectApproxEqAbs(@as(f64, 45), sum, 0.000000001);
}
