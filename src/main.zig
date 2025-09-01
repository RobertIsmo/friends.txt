const std = @import("std");
const config = @import("config");

const semver = std.SemanticVersion.parse(config.version) catch unreachable;

const f = @import("friends.zig");

const friends01 = @embedFile("embed/friends01");
const friends02 = @embedFile("embed/friends02");
const friends03 = @embedFile("embed/friends03");

pub fn main() void {
    std.debug.print("Version {s}\n", .{config.version});
    const cwd = std.fs.cwd();
    const friends = cwd.makeOpenPath(
        "www/friends",
        .{},
    ) catch {
        std.log.err("Unable to create or open the friends directory.", .{});
        return;
    };
    const www = cwd.openDir(
        "www",
        .{},
    ) catch {
        std.log.err("Unable to open the www directory.", .{});
        return;
    };

    const friendsHtml = friends.createFile(
        "index.html",
        .{},
    ) catch {
        std.log.err("Unable to create or open the friends index.html file.", .{});
        return;
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    const allocator = arena.allocator();
    defer arena.deinit();

    const friendsTxt = www.readFileAlloc(
        allocator,
        "friends.txt",
        1024 * 10,
    ) catch {
        std.log.err("Unable to open the friends.txt file.", .{});
        return;
    };

    _ = friendsHtml.write(friends01) catch {
        std.log.err("Unable to write to the friends index.html file.", .{});
        return;
    };

    const writer = friendsHtml.writer();
    var friendSet: std.StringArrayHashMap(bool) = .init(allocator);
    defer friendSet.deinit();

    f.write_friend_list(allocator, &friendSet, writer, friendsTxt) catch {
        std.log.err("Unable to write the friends.txt file.", .{});
        return;
    };

    _ = friendsHtml.write(friends02) catch {
        std.log.err("Unable to write to the friends index.html file.", .{});
        return;
    };

    f.write_friends_of_friends_list(allocator, &friendSet, writer, friendsTxt) catch {
        std.log.err("Unable to write the friends.txt file for friends of friends.", .{});
        return;
    };

    _ = friendsHtml.write(friends03) catch {
        std.log.err("Unable to write to the friends index.html file.", .{});
        return;
    };
}
