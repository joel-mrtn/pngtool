const std = @import("std");

const Chunk = @This();

const IHDR = Chunk.DataStructures.IHDR;
const PLTE = Chunk.DataStructures.PLTE;
const EmptyChunk = Chunk.DataStructures.EmptyChunk;
const UnstructuredChunk = Chunk.DataStructures.UnstructuredChunk;

data_length: u32,
data_type: DataType,
data: []const u8,
crc: u32,

pub fn fromBytes(bytes: []const u8) !Chunk {
    if (bytes.len < 12) {
        return error.InvalidChunkLength;
    }

    const length = std.mem.readInt(u32, bytes[0..4], .big);

    if (bytes.len < 4 + 4 + length + 4) {
        return error.InsufficientBytes;
    }

    const chunk_type_raw = std.mem.readInt(u32, bytes[4..8], .big);
    const chunk_type = std.enums.fromInt(DataType, chunk_type_raw) orelse return error.InvalidChunkType;

    const data = bytes[8 .. 8 + length];
    const crc = std.mem.readInt(u32, bytes[8 + length .. 12 + length][0..4], .big);

    const chunk_hash = std.hash.Crc32.hash(bytes[4 .. 8 + length]);
    if (chunk_hash != crc) {
        return error.InvalidCRC;
    }

    return Chunk{
        .data_length = length,
        .data_type = chunk_type,
        .data = data,
        .crc = crc,
    };
}

pub fn getStructuredData(self: *const Chunk) !?StructuredData {
    return switch (self.data_type) {
        .IHDR => .{ .IHDR = try IHDR.fromBytes(self.data) },
        .PLTE => .{ .PLTE = try PLTE.fromBytes(self.data) },
        else => null,
    };
}

pub fn getStructuredDataFromType(self: *const Chunk, comptime T: DataType) ?ChunkTypeStruct(T) {
    const TypeStruct = ChunkTypeStruct(T) orelse return null;
    return TypeStruct.fromBytes(self.data);
}

pub const DataType = enum(u32) {
    IHDR = 0x49484452,
    PLTE = 0x504C5445,
    IDAT = 0x49444154,
    IEND = 0x49454E44,

    pub fn getName(self: *const DataType) []const u8 {
        return switch (self.*) {
            .IHDR => "IHDR",
            .PLTE => "PLTE",
            .IDAT => "IDAT",
            .IEND => "IEND",
        };
    }
};

const StructuredData = union(enum) {
    IHDR: IHDR,
    PLTE: PLTE,
};

fn ChunkTypeStruct(comptime T: DataType) ?type {
    return switch (T) {
        .IHDR => IHDR,
        .PLTE => PLTE,
        else => null,
    };
}

pub const DataStructures = struct {
    pub const IHDR = struct {
        width: u32,
        height: u32,
        bit_depth: u8,
        color_type: u8,
        compression: u8,
        filter: u8,
        interlace: u8,

        const Self = @This();

        pub fn fromBytes(bytes: []const u8) !Self {
            try Self.validateBytes(bytes);

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

        pub fn validateBytes(bytes: []const u8) !void {
            if (bytes.len != 13) {
                return error.InvalidDataLength;
            }
        }
    };

    pub const PLTE = struct {
        palette_entries: []const Palette,

        const Self = @This();

        pub fn fromBytes(bytes: []const u8) !Self {
            try Self.validateBytes(bytes);

            const num_entries = bytes.len / 3;
            var buf: [256]Palette = undefined;

            for (0..num_entries) |i| {
                const offset = i * 3;
                buf[i] = Palette{
                    .r = bytes[offset + 0],
                    .g = bytes[offset + 1],
                    .b = bytes[offset + 2],
                };
            }

            return Self{
                .palette_entries = buf[0..num_entries],
            };
        }

        pub fn validateBytes(bytes: []const u8) !void {
            if (bytes.len % 3 != 0) {
                return error.InvalidDataLength;
            }

            const num_entries = bytes.len / 3;
            if (num_entries > 256) {
                return error.InvalidDataLength;
            }
        }

        const Palette = struct {
            r: u8,
            g: u8,
            b: u8,
        };
    };
};
