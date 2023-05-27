const std = @import("std");
const Self = @This();

buffer: []f32,
idx: usize = 0,
len: usize = 0,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator, capacity: usize) !Self {
    var self = Self{
        .allocator = allocator,
        .buffer = try allocator.alloc(f32, capacity),
    };

    return self;
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.buffer);
}

pub fn write(self: *Self, value: f32) void {
    self.buffer[self.idx] = value;
    self.idx = (self.idx + 1) % self.buffer.len;

    if (self.len < self.buffer.len) {
        self.len += 1;
    }
}

pub fn copyToSlice(self: Self, slice: []f32) []f32 {
    std.debug.assert(slice.len >= self.len);

    if (self.len < self.buffer.len) {
        std.mem.copy(f32, slice, self.buffer[0..self.len]);
        return slice[0..self.len];
    } else {
        std.mem.copy(f32, slice, self.buffer[self.idx..]);
        std.mem.copy(f32, slice[self.len - self.idx ..], self.buffer[0..self.idx]);
        return slice;
    }
}

pub fn multiSlice(self: Self) MultiSlice {
    if (self.len < self.buffer.len) {
        return MultiSlice{
            .first = self.buffer[0..self.len],
            .second = &[_]f32{},
        };
    } else {
        return MultiSlice{
            .first = self.buffer[self.idx..],
            .second = self.buffer[0..self.idx],
        };
    }
}

pub const MultiSlice = struct {
    first: []f32,
    second: []f32,
};

test {
    const t = std.testing;
    var ally = t.allocator;
    var ring = try Self.init(ally, 3);
    defer ring.deinit();

    ring.write(1);

    try t.expectEqual(@as(usize, 1), ring.len);
    try t.expectEqual(@as(usize, 1), ring.idx);

    var slice = try ally.alloc(f32, ring.buffer.len);
    defer ally.free(slice);

    var copied = ring.copyToSlice(slice);

    try t.expectEqualSlices(f32, &.{1}, copied);

    ring.write(2);
    ring.write(3);
    copied = ring.copyToSlice(slice);
    try t.expectEqualSlices(f32, &.{ 1, 2, 3 }, copied);

    ring.write(4);
    copied = ring.copyToSlice(slice);
    try t.expectEqualSlices(f32, &.{ 2, 3, 4 }, copied);
}
