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
        switch (chunk.getStructuredData()) {
            .IHDR => |ihdr| {
                std.debug.print("IHDR: width={d}, height={d}, bit_depth={d}\n", .{ ihdr.width, ihdr.height, ihdr.bit_depth });
            },
            .PLTE => |plte| {
                std.debug.print("PLTE: length={d}\n", .{plte.palette.len});
            },
            .IDAT => |idat| {
                std.debug.print("IDAT: length={d}\n", .{idat.data.len});
            },
            .IEND => {
                std.debug.print("IEND: empty\n", .{});
            },
        }
    }
}
