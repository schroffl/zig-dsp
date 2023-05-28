const std = @import("std");

// The Phasor mainly exists to fix one problem I've encountered: The
// std.math.sin function from the std library get's pretty inaccurate and thus
// noisy for high input values. I think it's caused by decreasing floating
// point accuracy.
pub fn Phasor(comptime T: type) type {
    return struct {
        const Self = @This();

        phase: T = 0,
        step: T = 0,
        sample_rate: T,

        pub fn init(sample_rate: T, frequency: T) Self {
            var self = Self{
                .sample_rate = sample_rate,
            };

            self.setFrequency(frequency);

            return self;
        }

        pub fn reset(self: *Self) void {
            self.phase = 0;
        }

        pub fn setFrequency(self: *Self, frequency: T) void {
            self.step = frequency * std.math.pi * 2 / self.sample_rate;
        }

        pub fn increment(self: *Self) void {
            const two_pi = @as(T, std.math.pi) * 2;

            self.phase += self.step;

            if (self.phase >= two_pi) {
                self.phase -= two_pi;
            }
        }

        pub fn sin(self: Self) T {
            return std.math.sin(self.phase);
        }

        pub fn cos(self: Self) T {
            return std.math.cos(self.phase);
        }
    };
}

test {
    var phasor = Phasor(f64).init(1000, 1);

    // At x = 0
    try std.testing.expectEqual(@as(f64, 0), phasor.sin());
    try std.testing.expectEqual(@as(f64, 1), phasor.cos());

    // At x = pi
    for (0..500) |_| phasor.increment();
    try std.testing.expectApproxEqAbs(@as(f64, 0), phasor.sin(), 0.00000001);
    try std.testing.expectApproxEqAbs(@as(f64, -1), phasor.cos(), 0.00000001);

    // At x = 2 * pi
    for (0..500) |_| phasor.increment();
    try std.testing.expectApproxEqAbs(@as(f64, 0), phasor.sin(), 0.00000001);
    try std.testing.expectApproxEqAbs(@as(f64, 1), phasor.cos(), 0.00000001);

    // At x = 2002 * pi
    for (0..1000 * 1000) |_| phasor.increment();
    try std.testing.expectApproxEqAbs(@as(f64, 0), phasor.sin(), 0.00000001);
    try std.testing.expectApproxEqAbs(@as(f64, 1), phasor.cos(), 0.00000001);
}
