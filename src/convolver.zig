const std = @import("std");
const Ring = @import("./ring.zig");
const Self = @This();

allocator: std.mem.Allocator,
coeffs: []f32,
ring: Ring,
work_mem: []f32,

pub fn init(allocator: std.mem.Allocator, coeffs: []const f32) !Self {
    var cloned = try allocator.dupe(f32, coeffs);
    std.mem.reverse(f32, cloned);

    var ring = try Ring.init(allocator, cloned.len);
    var i: usize = 0;

    while (i < coeffs.len) : (i += 1) ring.write(0);

    return Self{
        .allocator = allocator,
        .coeffs = cloned,
        .ring = ring,
        .work_mem = try allocator.alloc(f32, ring.len),
    };
}

pub fn deinit(self: *Self) void {
    self.ring.deinit();
    self.allocator.free(self.work_mem);
    self.allocator.free(self.coeffs);
}

pub fn process(self: *Self, y: f32) f32 {
    self.ring.write(y);

    var samples = self.ring.copyToSlice(self.work_mem);

    return convolveSIMD(self.coeffs, samples);
}

pub fn convolve(coeffs: []const f32, samples: []const f32) f32 {
    std.debug.assert(coeffs.len == samples.len);

    var result: f32 = 0;

    for (samples, 0..) |v, i| {
        result += v * coeffs[i];
    }

    return result;
}

pub fn convolveSIMD(coeffs: []const f32, signal: []const f32) f32 {
    std.debug.assert(coeffs.len == signal.len);

    const chunk_size = 16;
    const full_chunks = @divFloor(signal.len, chunk_size);
    const V = std.meta.Vector(chunk_size, f32);

    var chunk_i: usize = 0;
    var result: f32 = 0;

    while (chunk_i < full_chunks) : (chunk_i += 1) {
        const i = chunk_i * chunk_size;

        var coeffs_vec: V = coeffs[i..][0..chunk_size].*;
        var signal_vec: V = signal[i..][0..chunk_size].*;

        result += @reduce(.Add, coeffs_vec * signal_vec);
    }

    const chunk_width = full_chunks * chunk_size;
    const left = signal.len - chunk_width;

    if (left > 0) {
        var left_i: usize = chunk_width;

        while (left_i < signal.len) : (left_i += 1) {
            result += signal[left_i] * coeffs[left_i];
        }
    }

    return result;
}

test {
    const t = std.testing;
    var ally = t.allocator;
    var cv = try Self.init(ally, &[_]f32{ 0.5, 1, 1 });
    defer cv.deinit();

    _ = cv.process(1);
    _ = cv.process(2);
    var result = cv.process(3);
    try t.expectEqual(@as(f32, 4.5), result);

    result = cv.process(4);
    try t.expectEqual(@as(f32, 7), result);
}

test "large signal" {
    const t = std.testing;
    var ally = t.allocator;
    var cv = try Self.init(ally, &[_]f32{
        54, 37, 26, 62, 58, 4,   12, 39, 46, 96, 95, 74, 81, 38, 17, 59, 32, 99,
        9,  15, 65, 41, 78, 31,  27, 71, 19, 61, 35, 94, 23, 86, 68, 5,  10, 42,
        28, 77, 13, 45, 43, 89,  53, 90, 44, 83, 69, 30, 60, 36, 20, 76, 34, 63,
        1,  92, 50, 11, 79, 100, 51, 16, 55, 72, 66, 93, 21, 97, 40, 87, 67, 70,
        88, 85, 24, 56, 29, 14,  47, 22, 6,  33, 48, 49, 8,  3,  91, 64, 18, 7,
        75, 25, 73, 2,  84, 80,  52, 57, 82, 98,
    });
    defer cv.deinit();

    const signal = &[_]f32{
        3,  79, 42,  96, 50, 66, 11, 84, 16, 63, 38, 74, 30, 81, 14, 25, 55, 12,
        45, 49, 100, 98, 72, 64, 62, 21, 97, 26, 52, 75, 76, 86, 60, 19, 77, 69,
        78, 59, 68,  39, 61, 41, 9,  34, 57, 20, 27, 65, 54, 44, 29, 87, 73, 6,
        91, 35, 22,  80, 31, 4,  71, 88, 46, 47, 95, 17, 43, 36, 82, 40, 89, 10,
        13, 28, 24,  33, 1,  23, 5,  48, 8,  67, 92, 51, 7,  85, 56, 58, 32, 70,
        94, 99, 15,  53, 2,  37, 83, 90, 18, 93,
    };

    var result: f32 = 0;

    for (signal) |y| result = cv.process(y);

    try t.expectEqual(@as(f32, 277409), result);
}
