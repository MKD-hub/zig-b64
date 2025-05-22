const std = @import("std");
const Base64 = @import("base64.zig").Base64;
const stdout = std.io.getStdOut().writer();
const helpers = @import("helpers.zig");

pub fn main() !void {
    // one page allocator to rule them all!
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);

    if (args.len < 4) {
        try stdout.print("Usage: {s} <file-path> <options> <output-file-name>\n", .{args[0]});
        return error.InvalidUsage;
    }

    const data: []const u8 = try helpers.getBinaryDataFromFile(allocator, args[1]);
    defer allocator.free(data);

    if (std.mem.eql(u8, args[2], "-e")) {
        var buffer = std.ArrayList([4]u8).init(allocator);
        defer buffer.deinit();
    
        const b64 = Base64.init();
        try helpers.encodeData(data, &b64, &buffer);
        try helpers.writeEncodingToFile(4, allocator, args[3], &buffer);
    }
    else {
        var buffer = std.ArrayList([3]u8).init(allocator);
        defer buffer.deinit();
    
        const b64 = Base64.init();
        try helpers.decodeData(data, &b64, &buffer);
        try helpers.writeEncodingToFile(3, allocator, args[3], &buffer);
    }

}
