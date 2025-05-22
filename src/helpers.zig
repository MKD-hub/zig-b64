const std = @import("std");


pub fn isFileBinary(fileExtension: []const u8) bool {
    return std.mem.eql(u8, fileExtension, ".txt");
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

    // don't do this in future. maybe_data is allocated to the stack of this
    // function and once it exits the data is removed, I was returning a
    // pointer to a dead piece of data
    // Keeping this for future reference

    //return maybe_data orelse "";

    return heap_buffer;
}

pub fn concatenateSmallString(buff: *[255]u8, str1: []const u8, str2: []const u8) ![]const u8 {
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


pub fn flattenArray(allocator: std.mem.Allocator, buffer: *std.ArrayList([4]u8)) !std.ArrayList(u8) {
    var flat = std.ArrayList(u8).init(allocator);
    //defer flat.deinit();
    //commented out the above since the program terminates after this and the allocated memory by the page allocator will be "recycled" by the OS.
    //if defer were still used, that'd make it so that the program de-initializes the memory before the function returns and we get a segmentation fault.

    for (buffer.items) |chunk| {
        try flat.appendSlice(&chunk);
    }

    return flat;
}


