const std = @import("std");
const Chunk = @import("Chunk.zig");

const PNG = @This();

pub const file_signature: u64 = 0x89504E470D0A1A0A;

chunks: []Chunk,

// TODO: use stream instead of byte array
pub fn init(allocator: std.mem.Allocator, bytes: []const u8) !PNG {
    var chunks = std.ArrayList(Chunk).empty;
    defer chunks.deinit(allocator);

    var offset: usize = 8; // skip signature
    while (offset < bytes.len) {
        const chunk = Chunk.fromBytes(bytes[offset..]) catch |err| {
            if (err == error.InvalidChunkType) {
                const length = std.mem.readInt(u32, bytes[offset..][0..4], .big);
                if (bytes[offset..].len < 4 + 4 + length + 4) {
                    return error.InsufficientBytes;
                }
                offset += 4 + 4 + length + 4;
                continue;
            }
            return err;
        };

        try chunks.append(allocator, chunk);
        offset += 4 + 4 + chunk.length + 4;
    }

    return .{
        .chunks = try chunks.toOwnedSlice(allocator),
    };
}

pub fn deinit(self: *const PNG, allocator: std.mem.Allocator) void {
    allocator.free(self.chunks);
}
