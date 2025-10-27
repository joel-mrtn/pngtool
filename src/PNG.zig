const std = @import("std");
const Chunk = @import("Chunk.zig");

const PNG = @This();

pub const file_signature: u64 = 0x89504E470D0A1A0A;

chunks: std.ArrayList(Chunk),

// TODO: rename PNG to DataStream or FileData, this only contains the raw chunks, handles Chunk Addition and Validation

// TODO: create another Struct called PNGData or something, in which the PNG data and it's properties are stored in
//  another form. One property of that new object would be dada, which contains the raw pixel data from the file and
//  has some helper functions to e.g. resize, cut, etc.

pub fn initFromReader(allocator: std.mem.Allocator, reader: *std.Io.Reader) !PNG {
    if (try reader.takeInt(u64, .big) != file_signature) {
        return error.InvalidFileSignature;
    }

    var chunks = std.ArrayList(Chunk).empty;
    errdefer chunks.deinit(allocator);

    while (Chunk.initFromReader(allocator, reader)) |chunk| {
        try chunks.append(allocator, chunk);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return .{
        .chunks = chunks,
    };
}

pub fn initFromBytes(allocator: std.mem.Allocator, bytes: []const u8) !PNG {
    if (std.mem.readInt(u64, bytes[0..8], .big) != file_signature) {
        return error.InvalidFileSignature;
    }

    var chunks = std.ArrayList(Chunk).empty;
    errdefer chunks.deinit(allocator);

    var offset: usize = 8;
    while (offset < bytes.len) {
        const chunk = try Chunk.initFromBytes(allocator, bytes[offset..]);
        try chunks.append(allocator, chunk);
        offset += 8 + chunk.data_length + 4;
    }

    return .{
        .chunks = chunks,
    };
}

pub fn deinit(self: *PNG, allocator: std.mem.Allocator) void {
    for (self.chunks.items) |*chunk| {
        chunk.deinit(allocator);
    }
    self.chunks.deinit(allocator);
}
