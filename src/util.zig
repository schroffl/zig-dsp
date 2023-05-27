const std = @import("std");

/// Throw a compile error if the given type is not a float
pub fn ensureFloat(comptime T: type) void {
    switch (@typeInfo(T)) {
        .Float => {},
        else => {
            @compileError("Expected a float, but you passed a " ++ @typeName(T));
        },
    }
}

/// Normalize the given buffer in place
pub fn normalize(comptime T: type, a: []T) void {
    var i: usize = 0;
    var sum: T = 0;

    while (i < a.len) : (i += 1) {
        sum += a[i];
    }

    i = 0;

    while (i < a.len) : (i += 1) {
        a[i] = a[i] / sum;
    }
}

pub fn sincDiscrete(comptime T: type, N: usize, frequency: T, i: usize) T {
    if (i == (N - 1) / 2) {
        return 1;
    }

    const x = @intToFloat(T, i) / @intToFloat(T, N - 1) * 2 - 1;

    return sinc(T, frequency * x);
}

pub fn sinc(comptime T: type, x: T) T {
    const pi_x = std.math.pi * x;
    return std.math.sin(pi_x) / pi_x;
}

test "normalize" {
    var buffer = [_]f32{ 0.125, 0.25, 0.125 };
    normalize(f32, buffer[0..]);
    try std.testing.expectEqualSlices(f32, &[_]f32{ 0.25, 0.5, 0.25 }, buffer[0..]);

    var buffer2 = [_]f32{1} ** 10;
    normalize(f32, buffer2[0..]);
    try std.testing.expectEqualSlices(f32, &[_]f32{0.1} ** 10, buffer2[0..]);

    var buffer3 = [_]f32{ -0.25, 0.5, -0.75 };
    normalize(f32, buffer3[0..]);
    try std.testing.expectEqualSlices(f32, &[_]f32{ 0.5, -1, 1.5 }, buffer3[0..]);
}

test "sincDiscrete" {
    const N = 91;
    const tolerance = 0.000000001;

    try std.testing.expectApproxEqAbs(@as(f64, 0), sincDiscrete(f64, N, 1, 0), tolerance);
    try std.testing.expectApproxEqAbs(@as(f64, 1), sincDiscrete(f64, N, 1, 45), tolerance);
    try std.testing.expectApproxEqAbs(@as(f64, 0), sincDiscrete(f64, N, 1, 90), tolerance);

    try std.testing.expectApproxEqAbs(@as(f64, 0), sincDiscrete(f64, N, 2, 0), tolerance);
    try std.testing.expectApproxEqAbs(@as(f64, 1), sincDiscrete(f64, N, 2, 45), tolerance);
    try std.testing.expectApproxEqAbs(@as(f64, 0), sincDiscrete(f64, N, 2, 90), tolerance);

    var sum1: f64 = 0;
    for (0..N) |i| sum1 += sincDiscrete(f64, N, 1, i);
    try std.testing.expectApproxEqAbs(@as(f64, 53.050), sum1, 0.001);

    var sum2: f64 = 0;
    for (0..N) |i| sum2 += sincDiscrete(f64, N, 2, i);
    try std.testing.expectApproxEqAbs(@as(f64, 20.317), sum2, 0.001);

    var sum3: f64 = 0;
    for (0..N) |i| sum3 += sincDiscrete(f64, N, 3.5, i);
    try std.testing.expectApproxEqAbs(@as(f64, 12.831), sum3, 0.001);
}
