const std = @import("std");
const pngtool = @import("pngtool");

const Chunk = pngtool.Chunk;
const PNG = pngtool.PNG;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file: []const u8 = @embedFile("assets/test_911.png")[0..];

    const png = try PNG.init(allocator, file);
    defer png.deinit(allocator);
    const chunks = png.chunks;

    for (chunks) |chunk| {
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
