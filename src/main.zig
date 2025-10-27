const std = @import("std");
const pngtool = @import("pngtool");

const Chunk = pngtool.Chunk;
const PNG = pngtool.PNG;

pub fn main() !void {
    try fromReader();
    std.debug.print("\n/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\\n\n", .{});
    try fromBytes();
}

fn fromReader() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("assets/test_911.png", .{});
    defer file.close();

    var buf: [1024]u8 = undefined;
    var reader = file.reader(&buf);

    var png = try PNG.initFromReader(allocator, &reader.interface);
    defer png.deinit(allocator);

    const chunks = png.chunks;
    std.debug.print("Number of chunks: {d}\n", .{chunks.items.len});

    for (chunks.items) |chunk| {
        const data = try chunk.getStructuredData() orelse {
            std.debug.print("{s}: length={d}\n", .{ chunk.data_type.getName(), chunk.data_length });
            continue;
        };

        switch (data) {
            .IHDR => |ihdr| {
                std.debug.print("IHDR: width={d}, height={d}, bit_depth={d}\n", .{ ihdr.width, ihdr.height, ihdr.bit_depth });
            },
            .PLTE => |plte| {
                std.debug.print("PLTE: palette_entries={d}\n", .{plte.palette_entries.len});
            },
        }
    }
}

fn fromBytes() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("assets/test_911.png", .{});
    defer file.close();

    var buf: [1024]u8 = undefined;
    var reader = file.reader(&buf);

    const bytes = try reader.interface.allocRemaining(allocator, .unlimited);
    defer allocator.free(bytes);

    var png = try PNG.initFromBytes(allocator, bytes);
    defer png.deinit(allocator);

    const chunks = png.chunks;
    std.debug.print("Number of chunks: {d}\n", .{chunks.items.len});

    for (chunks.items) |chunk| {
        const data = try chunk.getStructuredData() orelse {
            std.debug.print("{s}: length={d}\n", .{ chunk.data_type.getName(), chunk.data_length });
            continue;
        };

        switch (data) {
            .IHDR => |ihdr| {
                std.debug.print("IHDR: width={d}, height={d}, bit_depth={d}\n", .{ ihdr.width, ihdr.height, ihdr.bit_depth });
            },
            .PLTE => |plte| {
                std.debug.print("PLTE: palette_entries={d}\n", .{plte.palette_entries.len});
            },
        }
    }
}
