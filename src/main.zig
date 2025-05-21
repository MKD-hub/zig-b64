const std = @import("std");
const Base64 = @import("base64.zig").Base64;
const stdout = std.io.getStdOut().writer();

fn concatenateSmallString(buff: *[255]u8, str1: []const u8, str2: []const u8) ![]const u8 {
    // 255 size array since I don't expect filenames to be too large. But also,
    // preferring to put on stack rather than on heap for this simple
    // operation. Might refactor later.

    //var combined_buffer: [255]u8 = undefined; // Bad, can't slice from this and return slice since this gets deallocated and the slice will be left dangling

    const combined_len = (str1.len + str2.len) - 4; // -4 because I want to remove the .txt and append the .b64
    if (combined_len > buff.len) return error.StringTooLong;

    const concatenated_string =  buff[0..combined_len];
    std.mem.copyForwards(u8, concatenated_string[0..str1.len], str1);
    std.mem.copyForwards(u8, concatenated_string[str1.len-4..], str2);

    std.debug.print("{s}\n", .{concatenated_string});

    return concatenated_string;
}

fn flattenArray(allocator: std.mem.Allocator, buffer: *std.ArrayList([4]u8)) !std.ArrayList(u8) {
    var flat = std.ArrayList(u8).init(allocator);
    //defer flat.deinit();
    //commented out the above since the program terminates after this and the allocated memory by the page allocator will be "recycled" by the OS.
    //if defer were still used, that'd make it so that the program de-initializes the memory before the function returns and we get a segmentation fault.

    for (buffer.items) |chunk| {
        try flat.appendSlice(&chunk);
    }

    return flat;
}

fn encode_large_text(data: []const u8, b64: *const Base64, buf:  *std.ArrayList([4]u8)) !void {
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

fn getDataFromFile(allocator: std.mem.Allocator, filename: []const u8) ![]const u8 {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    var buffered = std.io.bufferedReader(file.reader());
    var bufreader = buffered.reader();

    var buffer: [1000]u8 = undefined; // This is a stack buffer, very bad for exporting, copy result into heap buffer
    @memset(buffer[0..], 0);

    const maybe_data = try bufreader.readUntilDelimiterOrEof(buffer[0..], '\x00');
    
    const heap_buffer = try allocator.alloc(u8, maybe_data.?.len);
    std.mem.copyForwards(u8, heap_buffer, maybe_data orelse "");

    // don't do this in future. maybe_data is allocated to the stack of this
    // function and once it exits the data is removed, I was returning a
    // pointer to a dead piece of data
    // Keeping this for future reference

    //return maybe_data orelse "";

    return heap_buffer;
}

fn writeEncodingToFile(allocator: std.mem.Allocator, filename: []const u8, buffer: *std.ArrayList([4]u8)) !void {
    var copyBuffer: [255]u8 = undefined;
    const output_filename = try concatenateSmallString(&copyBuffer, filename, ".b64"); 
    var file = try std.fs.cwd().createFile(output_filename, .{});
    defer file.close();

    const flat = try flattenArray(allocator , buffer);
    std.debug.print("{any}\n", .{flat.items});

    try file.writeAll(flat.items);
}

pub fn main() !void {

    // one page allocator to rule them all!
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <file-path>\n", .{args[0]});
        return error.InvalidUsage;
    }

    // Heap allocator for data
    const data: []const u8 = try getDataFromFile(allocator, args[1]);
    defer allocator.free(data);

    var buffer = std.ArrayList([4]u8).init(allocator);
    defer buffer.deinit();

    const b64 = Base64.init();
    try encode_large_text(data, &b64, &buffer);

    try writeEncodingToFile(allocator, args[1], &buffer);

    std.debug.print("{s}\n", .{buffer.items});
}
