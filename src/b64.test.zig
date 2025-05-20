const std = @import("std");
const expect = std.testing.expect;
const Base64 = @import("base64.zig").Base64;

test "testing simple encode" {
    const b64 = Base64.init(); 
    const encoded = b64.encode("Hel");
    try expect(std.mem.eql(u8, &encoded, "SGVs"));
}

test "testing simple two letter encode" {
    const b64 = Base64.init(); 
    const encoded = b64.encode("Ma");
    try expect(std.mem.eql(u8, &encoded, "TWE="));
}

test "testing one letter encode" {
    const b64 = Base64.init(); 
    const encoded = b64.encode("M");
    try expect(std.mem.eql(u8, &encoded, "TQ=="));
}

test "testing simple decode" {
    const b64 = Base64.init(); 
    const decoded = b64.decode("SGVs");
    try expect(std.mem.eql(u8, &decoded, "Hel"));
}

test "testing simple two letter decode" {
    const b64 = Base64.init(); 
    const decoded = b64.decode("TWE=");
    try expect(std.mem.eql(u8, &decoded, "Ma"));
}

test "testing one letter decode" {
    const b64 = Base64.init(); 
    const decoded = b64.decode("TQ==");
    try expect(std.mem.eql(u8, &decoded, "M"));
}
