const std = @import("std");

pub const Base64 = struct {
    table: [64]u8,
    reverse_table: [128]u8,

    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numbers_symbols = "0123456789+/";
        const full = upper ++ lower ++ numbers_symbols;

        var table: [64]u8 = undefined;
        var reverse_table: [128]u8 = [_]u8{ 0xff } ** 128; // 0xff for undefined entries

        // Fill base64 table
        for (full, 0..) |ch, index| {
            table[index] = ch;
            reverse_table[ch] = @intCast(index);
        }

        return Base64{
            .table = table,
            .reverse_table = reverse_table,
        };  
    }

    pub fn _char_at(self: Base64, index: usize) u8 {
        return self.table[index];
    }

    pub fn _index_at(self: Base64, character: u8) u8 {
        const char_slice = &[1]u8{character};
        if (std.mem.eql(u8, char_slice, "=")) {
            return 64;
        }
        return self.reverse_table[character];
    }

    pub fn decode(self: Base64, encodedString: []const u8) [3]u8 {
        // Iterates over and combines each 4 bits of the encoded string
        var groups: [4]u8 = [4]u8{0,0,0,0};

        for (encodedString, 0..) |byte, index| {
            if (std.mem.eql(u8, &[1]u8{byte}, "=")) {
                groups[index] = 0;
                continue;
            }
            groups[index] = self._index_at(byte);
        }

        return .{
            (groups[0] << 2) | (groups[1] >> 4),
            (groups[1] << 4) | (groups[2] >> 2),
            (groups[2] << 6) | (groups[3])
        };
    }

    pub fn encode(self: Base64, word: []const u8) [4]u8 {
        // What this function does:
        // Recieves 24 bytes (3 ASCII characters)
        // convert to binary
        // convert to base64
        // return the list 
    
        var groups: [4]u8 = [4]u8{0, 0, 0, 0};
        var encodedString: [4]u8 = [4]u8{0, 0, 0, 0};
    
        // Each group should store the correct 6 bits
        // Each ASCII character is a single byte
    
        var leftover: u8 = 0; 
        var counter: u8 = 0;
        const byteShifter = [3]u3{2, 4, 6};
        const leftOverShifts = [3]u3{0, 4, 2};
        const lastBits = [3]u8{0x03, 0xf, 0x3f};
    
        // same functionality in a loop
    
        for (word, 0..) |byte, index| {
            groups[index] = (byte >> byteShifter[index]) | (leftover << leftOverShifts[index]); 
            leftover = byte & lastBits[index];
            counter = counter + 1;
        }
    
        if (counter < 3) {
            groups[counter] = leftover << leftOverShifts[counter];
            for (groups, 0..) |b64Index, index| {
                if (b64Index == 0) {
                    encodedString[index] = 61; // ASCII value for: =
                    continue;
                }
                encodedString[index] = self._char_at(b64Index);
            }
            return encodedString;
        }
        
        groups[counter] = leftover;
    
        for (groups, 0..) |b64Index, index| {
            if (b64Index == 0) {
                encodedString[index] = 61; // ASCII value for: =
                continue;
            }
            encodedString[index] = self._char_at(b64Index);
        }
        return encodedString;
    }

};

