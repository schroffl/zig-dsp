const std = @import("std");
const Self = @This();

allocator: std.mem.Allocator,
buffer: []f32,
idx: usize = 0,

pub fn init(allocator: std.mem.Allocator, len: usize) !Self {
    var self = Self{
        .allocator = allocator,
        .buffer = try allocator.alloc(f32, len),
    };

    @memset(self.buffer, 0);

    return self;
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.buffer);
}

pub fn process(self: *Self, value: f32) f32 {
    _ = value;
    _ = self;
}

pub fn add(self: *Self, value: f32) void {
    self.buffer[self.idx] = value;
    self.idx = (self.idx + 1) % self.buffer.len;
}

pub fn last(self: Self) f32 {
    return self.buffer[self.idx];
}

pub fn resize(self: *Self, len: usize) !void {
    const old_len = self.buffer.len;

    if (len > old_len) {
        self.buffer = try self.allocator.realloc(self.buffer, len);

        // We can skip the copy if idx = 0
        if (self.idx == 0) {
            self.idx = old_len;
            @memset(self.buffer[self.idx..], 0);
        } else {
            const src = self.buffer[self.idx..old_len];
            const dst = self.buffer[self.buffer.len - src.len ..];
            const len_diff = len - old_len;

            std.mem.copyBackwards(f32, dst, src);
            @memset(src[0..len_diff], 0);
        }
    } else if (len < old_len) {
        if (len <= self.idx) {
            const diff = self.idx - len;
            const src = self.buffer[diff .. diff + len];
            std.mem.copyForwards(f32, self.buffer[0..len], src);
            self.buffer = try self.allocator.realloc(self.buffer, len);
            self.idx = 0;
        } else {
            const diff = len - self.idx;
            const dst = self.buffer[len - diff .. len];
            const src = self.buffer[old_len - diff ..];
            std.mem.copyForwards(f32, dst, src);
            self.buffer = try self.allocator.realloc(self.buffer, len);
        }
    }
}

test {
    const ally = std.testing.allocator;
    var line = try Self.init(ally, 3);
    defer line.deinit();

    line.add(1);
    try std.testing.expectEqual(@as(f32, 0), line.last());
    line.add(2);
    try std.testing.expectEqual(@as(f32, 0), line.last());
    line.add(3);
    try std.testing.expectEqual(@as(f32, 1), line.last());
    line.add(4);
    try std.testing.expectEqual(@as(f32, 2), line.last());
    line.add(5);
    try std.testing.expectEqual(@as(f32, 3), line.last());
    line.add(6);
    try std.testing.expectEqual(@as(f32, 4), line.last());
}

test "grow" {
    const ally = std.testing.allocator;
    var line = try Self.init(ally, 5);
    defer line.deinit();

    line.add(1);
    line.add(2);
    line.add(3);
    line.add(4);
    line.add(5);

    try line.resize(8);
    try std.testing.expectEqual(@as(f32, 0), line.last());

    line.add(6);
    line.add(7);
    line.add(8);
    try std.testing.expectEqual(@as(f32, 1), line.last());

    line.add(9);
    line.add(10);
    try std.testing.expectEqual(@as(f32, 3), line.last());

    try line.resize(9);
    try std.testing.expectEqual(@as(f32, 0), line.last());
    line.add(11);
    try std.testing.expectEqual(@as(f32, 3), line.last());
    line.add(12);
    try std.testing.expectEqual(@as(f32, 4), line.last());
}

test "shrink" {
    const ally = std.testing.allocator;
    var line = try Self.init(ally, 5);
    defer line.deinit();

    line.add(1);
    line.add(2);
    line.add(3);
    line.add(4);

    try line.resize(3);
    try std.testing.expectEqual(@as(f32, 2), line.last());

    var line2 = try Self.init(ally, 8);
    defer line2.deinit();

    line2.add(1);
    line2.add(2);
    line2.add(3);
    line2.add(4);
    line2.add(5);
    line2.add(6);
    line2.add(7);
    line2.add(8);

    line2.add(9);
    line2.add(10);

    try line2.resize(4);
    try std.testing.expectEqual(@as(f32, 7), line2.last());
}
