const std = @import("std");
const Base64 = @import("base64.zig").Base64;
const encode = @import("base64.zig").encode;
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    var b64 = Base64.init();
    const encoded = b64.encode("Hel");
    const decoded = b64.decode(encoded[0..]);

    std.debug.print("{s}\n", .{encoded[0..]});
    std.debug.print("{s}\n", .{decoded[0..]});

}
