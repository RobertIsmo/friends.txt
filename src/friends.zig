const std = @import("std");

pub fn write_friend_list(allocator: std.mem.Allocator, set: *std.StringArrayHashMap(bool), writer: anytype, text: []const u8) !void {
    const list = try read_list(allocator, text);
    for (list) |line| {
        _ = try set.fetchPut(line, false);
        try writer.print("\t\t\t<li><a href=\"https://{s}\">{s}</a></li>\n", .{ line, line });
    }
}

pub fn write_friends_of_friends_list(allocator: std.mem.Allocator, set: *std.StringArrayHashMap(bool), writer: anytype, text: []const u8) !void {
    const list = try get_friends_of_friends_list(allocator, set, text);
    defer allocator.free(list);
    for (list) |line| {
        try writer.print("\t\t\t<li><a href=\"https://{s}\">{s}</a></li>\n", .{ line, line });
    }
}

fn get_friends_of_friends_list(allocator: std.mem.Allocator, set: *std.StringArrayHashMap(bool), text: []const u8) ![][]const u8 {
    const list = try read_list(allocator, text);

    var friendsOfFriends: std.ArrayList([]const u8) = .init(allocator);
    defer friendsOfFriends.deinit();

    for (list) |line| {
        const fof = get_friends_of_friend(allocator, line) catch {
            std.log.err("trying to get friends of friend. {s} probably isn't running friends.txt. Let them know!", .{line});
            continue;
        };
        const fofList = try read_list(allocator, fof);
        for (fofList) |fofLine| {
            if (!set.contains(fofLine)) {
                _ = try set.fetchPut(fofLine, true);
                try friendsOfFriends.append(fofLine);
            }
        }
    }

    return friendsOfFriends.toOwnedSlice();
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
