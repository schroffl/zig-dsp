const std = @import("std");

pub fn main() !void {
    const start = rdtscp();
    const a = @splat(4, @as(f32, 1));
    const b = @splat(4, @as(f32, 2));
    const sum = @reduce(.Add, a + b);
    const end = rdtscp();

    const diff = end - start;

    var out = std.io.getStdOut().writer();
    try out.print("{} {d:.}", .{ diff, sum });
}

fn rdtscp() u64 {
    var hi: u64 = 0;
    var low: u64 = 0;

    //Changing the following to rdtsc fixes the bug
    asm volatile (
        \\rdtsc
        : [low] "={eax}" (low),
          [hi] "={edx}" (hi),
    );
    return (@as(u64, hi) << 32) | @as(u64, low);
}

test {
    _ = @import("./convolver.zig");
    _ = @import("./ring.zig");
}
