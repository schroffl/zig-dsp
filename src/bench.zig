const std = @import("std");
const benchmark = @import("bench").benchmark;
const Convolver = @import("./convolver.zig");

pub fn main() !void {
    try benchmark(Benchmarks);
}

fn rdtsc() u64 {
    var hi: u64 = 0;
    var low: u64 = 0;

    asm volatile (
        \\rdtsc
        : [low] "={eax}" (low),
          [hi] "={edx}" (hi),
    );

    return (@as(u64, hi) << 32) | @as(u64, low);
}

const Benchmarks = struct {
    const Arg = struct {
        coeffs: []const f32,
        signal: []const f32,
    };

    pub const args = [_]Arg{
        Arg{
            .coeffs = &(randomSignal(10)),
            .signal = &(randomSignal(10)),
        },
        Arg{
            .coeffs = &(randomSignal(69)),
            .signal = &(randomSignal(69)),
        },
        Arg{
            .coeffs = &(randomSignal(128)),
            .signal = &(randomSignal(128)),
        },
        Arg{
            .coeffs = &(randomSignal(1024)),
            .signal = &(randomSignal(1024)),
        },
        Arg{
            .coeffs = &(randomSignal(4096)),
            .signal = &(randomSignal(4096)),
        },
    };

    pub const arg_names = [_][]const u8{
        "10",
        "69",
        "128",
        "1024",
        "4096",
    };

    pub fn convolve(arg: Arg) f32 {
        var i: usize = 0;
        var result: f32 = 0;

        while (i < 100) : (i += 1) {
            result = Convolver.convolve(arg.coeffs, arg.signal);
        }

        return result;
    }

    pub fn convolveSIMD(arg: Arg) f32 {
        var i: usize = 0;
        var result: f32 = 0;

        while (i < 100) : (i += 1) {
            result = Convolver.convolveSIMD(arg.coeffs, arg.signal);
        }

        return result;
    }
};

fn randomSignal(comptime len: usize) [len]f32 {
    @setEvalBranchQuota(1024 * 1024 * 1024);

    var prng = std.rand.DefaultPrng.init(0);
    var rand = prng.random();

    var arr: [len]f32 = undefined;
    var i: usize = 0;

    while (i < len) : (i += 1) {
        arr[i] = rand.float(f32) * 2 - 1;
    }

    return arr;
}
