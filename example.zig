const std = @import("std");

const chan = @import("chan");

const Request = struct {
    id: u32,
    data: []const u8,
};

const Worker = struct {
    name: []const u8,
    c: chan.Chan(Request),
    t: std.Thread,

    pub fn init(name: []const u8) !Worker {
        const c = try chan.Chan(Request).init(0);
        const t = try std.Thread.spawn(.{}, run, .{ name, c });
        return .{ .name = name, .c = c, .t = t };
    }

    pub fn deinit(self: Worker) void {
        self.c.deinit();
    }

    pub fn send(self: Worker, req: *Request) !void {
        try self.c.send(req);
    }

    pub fn join(self: Worker) !void {
        _ = try self.c.recv();
    }

    pub fn stop(self: Worker) !void {
        try self.c.send(null);
        self.t.join();
    }

    fn run(name: []const u8, c: chan.Chan(Request)) void {
        listen(name, c) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
        };
    }

    fn listen(name: []const u8, c: chan.Chan(Request)) !void {
        while (try c.recv()) |req| {
            std.log.info("[{s}] RECEIVED REQUEST ({d}) \"{s}\"", .{ name, req.id, req.data });

            std.time.sleep(3 * 1_000_000_000);

            try c.send(null);
        }

        std.log.info("[{s}] exiting", .{name});
    }
};

pub fn main() !void {
    const a = try Worker.init("a");
    defer a.deinit();
    const b = try Worker.init("b");
    defer b.deinit();

    {
        var req = Request{ .id = 0, .data = "hello" };
        try a.send(&req);
    }

    {
        var req = Request{ .id = 0, .data = "world" };
        try b.send(&req);
    }

    try a.join();
    std.log.info("[{s}] RECEIVED RESPONSE", .{a.name});
    try b.join();
    std.log.info("[{s}] RECEIVED RESPONSE", .{b.name});

    try a.stop();
    try b.stop();
}
