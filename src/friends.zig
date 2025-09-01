const std = @import("std");

pub fn write_friend_list(allocator: std.mem.Allocator, writer: anytype, text: []const u8) !void {
    const list = try read_list(allocator, text);
    for (list) |line| {
        try writer.print("\t\t\t<li><a href=\"https://{s}\">{s}</a></li>\n", .{ line, line });
    }
}

pub fn write_friends_of_friends_list(allocator: std.mem.Allocator, writer: anytype, text: []const u8) !void {
    const list = try get_friends_of_friends_list(allocator, text);
    defer allocator.free(list);
    for (list) |line| {
        try writer.print("\t\t\t<li><a href=\"https://{s}\">{s}</a></li>\n", .{ line, line });
    }
}

fn get_friends_of_friends_list(allocator: std.mem.Allocator, text: []const u8) ![][]const u8 {
    const list = try read_list(allocator, text);

    var set: std.StringArrayHashMap(bool) = .init(allocator);
    defer set.deinit();
    for (list) |line| {
        const fof = get_friends_of_friend(allocator, line) catch {
            std.log.err("trying to get friends of friend. {s} probably isn't running friends.txt. Let them know!", .{line});
            continue;
        };
        const fofList = try read_list(allocator, fof);
        for (fofList) |fofLine| {
            _ = try set.fetchPut(fofLine, true);
        }
    }

    return try allocator.dupe([]const u8, set.keys());
}

fn get_friends_of_friend(allocator: std.mem.Allocator, domain: []const u8) ![]const u8 {
    var client: std.http.Client = .{
        .allocator = allocator,
    };
    defer client.deinit();

    var responseBody: std.ArrayList(u8) = .init(allocator);
    defer responseBody.deinit();

    const url = try std.mem.concat(
        allocator,
        u8,
        &[3][]const u8{ "https://", domain, "/friends.txt" },
    );

    std.debug.print("hitting {s}\n", .{url});

    const result = try client.fetch(.{
        .method = .GET,
        .location = .{ .url = url },
        .response_storage = .{ .dynamic = &responseBody },
    });

    if (result.status == .ok) {
        return responseBody.toOwnedSlice();
    } else return error.BadStatus;
}

fn read_list(allocator: std.mem.Allocator, text: []const u8) ![][]const u8 {
    var fbs = std.io.fixedBufferStream(text);
    const reader = fbs.reader();
    var list: std.ArrayList([]const u8) = .init(allocator);
    defer list.deinit();

    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024 * 10)) |line| {
        try list.append(line);
    }

    return list.toOwnedSlice();
}
