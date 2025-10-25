const std = @import("std");

const Chunk = @This();

const IHDR = Chunk.DataStructures.IHDR;
const PLTE = Chunk.DataStructures.PLTE;
const IDAT = Chunk.DataStructures.IDAT;
const IEND = Chunk.DataStructures.IEND;

length: u32,
type: Type,
data: []const u8,
crc: u32,

pub const Type = enum(u32) {
    IHDR = 0x49484452,
    PLTE = 0x504C5445,
    IDAT = 0x49444154,
    IEND = 0x49454E44,
};

pub const StructuredData = union(Type) {
    IHDR: IHDR,
    PLTE: PLTE,
    IDAT: IDAT,
    IEND: IEND,
};

pub fn fromBytes(bytes: []const u8) !Chunk {
    if (bytes.len < 12) {
        return error.InvalidChunkLength;
    }

    const length = std.mem.readInt(u32, bytes[0..4], .big);

    if (bytes.len < 4 + 4 + length + 4) {
        return error.InsufficientBytes;
    }

    const chunk_type_raw = std.mem.readInt(u32, bytes[4..8], .big);
    const chunk_type = std.enums.fromInt(Type, chunk_type_raw) orelse return error.InvalidChunkType;

    const data = bytes[8 .. 8 + length];
    const crc = std.mem.readInt(u32, bytes[8 + length .. 12 + length][0..4], .big);

    const chunk_hash = std.hash.Crc32.hash(bytes[4 .. 8 + length]);
    if (chunk_hash != crc) {
        return error.InvalidCRC;
    }

    return Chunk{
        .length = length,
        .type = chunk_type,
        .data = data,
        .crc = crc,
    };
}

pub fn getStructuredData(self: *const Chunk) StructuredData {
    return switch (self.type) {
        .IHDR => .{ .IHDR = IHDR.fromBytes(self.data) },
        .PLTE => .{ .PLTE = PLTE.fromBytes(self.data) },
        .IDAT => .{ .IDAT = IDAT.fromBytes(self.data) },
        .IEND => .{ .IEND = IEND.fromBytes(self.data) },
    };
}

pub fn getStructuredDataFromType(self: *const Chunk, comptime T: Type) ChunkTypeStruct(T) {
    return ChunkTypeStruct(T).fromBytes(self.data);
}

fn ChunkTypeStruct(comptime T: Type) type {
    return switch (T) {
        .IHDR => IHDR,
        .PLTE => PLTE,
        .IDAT => IDAT,
        .IEND => IEND,
    };
}

const DataStructures = struct {
    pub const IHDR = struct {
        width: u32,
        height: u32,
        bit_depth: u8,
        color_type: u8,
        compression: u8,
        filter: u8,
        interlace: u8,

        const Self = @This();

        pub fn fromBytes(bytes: []const u8) Self {
            return .{
                .width = std.mem.readInt(u32, bytes[0..4], .big),
                .height = std.mem.readInt(u32, bytes[4..8], .big),
                .bit_depth = bytes[8],
                .color_type = bytes[9],
                .compression = bytes[10],
                .filter = bytes[11],
                .interlace = bytes[12],
            };
        }
    };

    // Placeholder
    const PLTE = struct {
        palette: []const u8,

        const Self = @This();

        pub fn fromBytes(bytes: []const u8) Self {
            return .{ .palette = bytes };
        }
    };

    // Placeholder
    const IDAT = struct {
        data: []const u8,

        const Self = @This();

        pub fn fromBytes(bytes: []const u8) Self {
            return .{ .data = bytes };
        }
    };

    // Placeholder
    const IEND = struct {
        const Self = @This();

        pub fn fromBytes(bytes: []const u8) Self {
            _ = bytes;
            return .{};
        }
    };
};
