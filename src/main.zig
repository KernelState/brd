const std = @import("std");
const fs = std.fs;
const fmt = std.fmt;

const gpa = std.heap.GeneralPurposeAllocator;
const page = std.heap.page_allocator;
const arena = std.heap.ArenaAllocator;

const bufDirName = ".brd-buf";

fn bufDirCheck(path: []const u8) !void {
    var dir = fs.openDirAbsolute(path, .{}) catch |err| switch (err) {
        error.FileNotFound => {try fs.makeDirAbsolute(path); return;},
        else => return err,
    };
    dir.close();
}

fn mvIntoBuf(filename: []const u8) !void {
    var ar_alloc = arena.init(page);
    const alloc = ar_alloc.allocator();
    defer ar_alloc.deinit();

    const homepath = if ((try std.process.getEnvMap(alloc)).get("HOME")) |pth| pth else return error.NonUnixHome;
    
    var bufDirPath = std.ArrayList(u8).init(alloc);
    try std.fmt.format(bufDirPath.writer(), "{s}/{s}", .{homepath, bufDirName});

    try bufDirCheck(bufDirPath.items);
    var bufDir = try fs.openDirAbsolute(bufDirPath.items, .{ .iterate = true });
    defer bufDir.close();

    var iter = bufDir.iterate();
    if (try iter.next()) |_| {
        return error.FloodedBuf;
    }

    try fs.cwd().copyFile(filename, bufDir, filename, .{});
    try fs.cwd().deleteFile(filename);
}


fn cpIntoBuf(filename: []const u8) !void {
    var ar_alloc = arena.init(page);
    const alloc = ar_alloc.allocator();
    defer ar_alloc.deinit();

    const homepath = if ((try std.process.getEnvMap(alloc)).get("HOME")) |pth| pth else return error.NonUnixHome;
    
    var bufDirPath = std.ArrayList(u8).init(alloc);
    try std.fmt.format(bufDirPath.writer(), "{s}/{s}", .{homepath, bufDirName});

    try bufDirCheck(bufDirPath.items);
    var bufDir = try fs.openDirAbsolute(bufDirPath.items, .{ .iterate = true });
    defer bufDir.close();

    var iter = bufDir.iterate();
    if (try iter.next()) |_| {
        return error.FloodedBuf;
    }

    try fs.cwd().copyFile(filename, bufDir, filename, .{});
}


fn pasteFromBuf(dest: []const u8) !void {
    var ar_alloc = arena.init(page);
    const alloc = ar_alloc.allocator();
    defer ar_alloc.deinit();

    const homepath = if ((try std.process.getEnvMap(alloc)).get("HOME")) |pth| pth else return error.NonUnixHome;
    
    var bufDirPath = std.ArrayList(u8).init(alloc);
    try std.fmt.format(bufDirPath.writer(), "{s}/{s}", .{homepath, bufDirName});

    var bufDir = fs.openDirAbsolute(bufDirPath.items, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return error.BufDirDoesNotExist,
        else => return err,
    };
    defer bufDir.close();
    
    var iter = bufDir.iterate();
    const first = if (try iter.next()) |entry| entry.name else return error.NoItemsInBuffer;
    if (try iter.next()) |_| {
        return error.FloodedBuf;
    }

    var output = std.ArrayList(u8).init(alloc);
    try std.fmt.format(output.writer(), "{s}/{s}", .{dest, first});
    
    try bufDir.copyFile(output.items, fs.cwd(), first, .{});
}

pub fn main() !void {
    var gpa_alloc = gpa(.{}){};
    const alloc = gpa_alloc.allocator();
    const argv = try std.process.argsAlloc(alloc);
    if (argv.len < 3) {
        std.debug.print("too few arguments were supplied\n", .{});
        return;
    } else if (argv.len > 3) {
        std.debug.print("too many arguments were supplied\n", .{});
        return;
    }
    const cmd = argv[1];
    const filepath = argv[2];
    if (std.mem.eql(u8, "cp", cmd)) {
        std.fs.cwd().access(filepath, .{}) catch |err| {
            std.debug.print("cannot open file: {!}\n", .{err});
            return;
        };
        cpIntoBuf(filepath) catch |err| {
            std.debug.print("file opened but cannot be copied: {!}\n", .{err});
            return;
        };
    } else if (std.mem.eql(u8, "mv", cmd)) {
        std.fs.cwd().access(filepath, .{}) catch |err| {
            std.debug.print("cannot open file: {!}\n", .{err});
            return;
        };
        cpIntoBuf(filepath) catch |err| {
            std.debug.print("file opened but cannot be copied: {!}\n", .{err});
            return;
        };
    } else if (std.mem.eql(u8, "cmt", cmd)) {
        pasteFromBuf(filepath) catch |err| {
            std.debug.print("cannot commit, you may find your files at ~/{s}: {!}\n", .{bufDirName, err});
            return;
        };
    } else if (std.mem.eql(u8, "ls", cmd)) {
        const homepath = if ((try std.process.getEnvMap(alloc)).get("HOME")) |path| path else {
            std.debug.print("non-unix OS cannot be used to get the HOME env variable", .{});
            return error.NonUnixHome;
        };
        var bufDirPath = std.ArrayList(u8).init(alloc);
        defer bufDirPath.deinit();
        try std.fmt.format(bufDirPath.writer(), "{s}/{s}", .{homepath, bufDirName});

        var bufDir = try fs.openDirAbsolute(bufDirPath.items, .{ .iterate = true }); // Idk why do they put this iter shit in DIRs
        defer bufDir.close();

        var iter = bufDir.iterate();
        while (try iter.next()) |name| {
            std.debug.print("{s}\n", .{name.name});
        }
    } else {
        std.debug.print("unknown subcommand \"{s}\"\n", .{cmd});
    }
}
