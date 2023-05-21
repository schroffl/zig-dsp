//! A basic processor to remove the DC component from a signal.
//! The implementation is based on https://ccrma.stanford.edu/~jos/fp/DC_Blocker.html

const std = @import("std");
const Self = @This();

R: f32 = 0.995,
last_y: f32 = 0,
last_x: f32 = 0,

/// Initialize the DC Blocker with the given R
pub fn init(R: f32) Self {
    return .{ .R = R };
}

/// Process the given sample
pub fn process(self: *Self, x: f32) f32 {
    const y = x - self.last_x + self.R * self.last_y;
    self.last_x = x;
    self.last_y = y;
    return y;
}

test {
    var blocker = Self.init(0.995);
    var out: f32 = undefined;

    // Assuming a sample rate of 44.1kHz this is a one second signal
    const signal = [_]f32{0.5} ** 44100;

    for (signal) |v| {
        out = blocker.process(v);
    }

    try std.testing.expectApproxEqAbs(@as(f32, 0), out, 0.000000001);
}
