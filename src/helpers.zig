const std = @import("std");
const Base64 = @import("base64.zig").Base64;

pub fn writeEncodingToFile(comptime N: usize, allocator: std.mem.Allocator, outputFilename: []const u8, buffer: *std.ArrayList([N]u8)) !void {
    var file = try std.fs.cwd().createFile(outputFilename, .{});
    defer file.close();

    const flat = try flattenArray(N, allocator , buffer);

    try file.writeAll(flat.items);
}

pub fn encodeData(data: []const u8, b64: *const Base64, buf:  *std.ArrayList([4]u8)) !void {
    var counter: usize = 0;

    while (counter + 3 <= data.len) : (counter += 3) {
        const chunk = data[counter..counter + 3];
        const encoded = b64.encode(chunk);
        try buf.append(encoded);
    }

    if (counter < data.len) {
        const encoded = b64.encode(data[counter..]);
        try buf.append(encoded);
    }
}

pub fn decodeData(data: []const u8, b64: *const Base64, buf:  *std.ArrayList([3]u8)) !void {
    var counter: usize = 0;

    while (counter + 4 <= data.len) : (counter += 4) {
        const chunk = data[counter..counter + 4];
        const decoded = b64.decode(chunk);
        try buf.append(decoded);
    }

    if (counter < data.len) {
        const encoded = b64.decode(data[counter..]);
        try buf.append(encoded);
    }
}


pub fn getBinaryDataFromFile(allocator: std.mem.Allocator, filename: []const u8) ![]const u8 {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const stat = try file.stat();

    var buffer = try allocator.alloc(u8, stat.size);
    @memset(buffer, 0); // allocator.alloc returns a slice. No need to write buffer[0..]

    const bytes_read = try file.read(buffer);
    
    const heap_buffer = try allocator.alloc(u8, bytes_read);
    std.mem.copyForwards(u8, heap_buffer, buffer[0..bytes_read]);

    return heap_buffer;
}

fn flattenArray(comptime N: usize, allocator: std.mem.Allocator, buffer: *std.ArrayList([N]u8)) !std.ArrayList(u8) {
    var flat = std.ArrayList(u8).init(allocator);
    //defer flat.deinit();
    //commented out the above since the program terminates after this and the allocated memory by the page allocator will be "recycled" by the OS.
    //if defer were still used, that'd make it so that the program de-initializes the memory before the function returns and we get a segmentation fault.

    for (buffer.items) |chunk| {
        try flat.appendSlice(&chunk);
    }

    return flat;
}

// The function below is deprecated and replaced by getBinaryDataFromFile(...) because this function was only copying the first 1000 bytes of a file
fn getDataFromFile(allocator: std.mem.Allocator, filename: []const u8) ![]const u8 {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    var buffered = std.io.bufferedReader(file.reader());
    var bufreader = buffered.reader();

    var buffer: [1000]u8 = undefined; // This is a stack buffer, very bad for exporting, copy result into heap buffer
    @memset(buffer[0..], 0);

    const maybe_data = try bufreader.readUntilDelimiterOrEof(buffer[0..], '\x00'); // readUntilDelimiterOrEof() is for text files, binary files might have the delimiter anywhere in the file
    
    const heap_buffer = try allocator.alloc(u8, maybe_data.?.len);
    std.mem.copyForwards(u8, heap_buffer, maybe_data orelse "");

    // don't do this in future. maybe_data is allocated to the stack of this
    // function and once it exits the data is removed, I was returning a
    // pointer to a dead piece of data
    // Keeping this for future reference

    //return maybe_data orelse "";

    return heap_buffer;
}
