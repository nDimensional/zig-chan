const std = @import("std");

const chan = @import("chan");

const Request = struct {
    id: u32,
    data: []const u8,
};

const Response = struct {
    id: u32,
};

const Worker = struct {
    name: []const u8,
    req_chan: chan.Chan(Request),
    res_chan: chan.Chan(Response),
    t: std.Thread,

    pub fn init(name: []const u8) !Worker {
        const req_chan = try chan.Chan(Request).init(0);
        const res_chan = try chan.Chan(Response).init(0);
        const t = try std.Thread.spawn(.{}, run, .{ name, req_chan, res_chan });
        return .{ .name = name, .req_chan = req_chan, .res_chan = res_chan, .t = t };
    }

    pub fn deinit(self: Worker) void {
        self.req_chan.deinit();
        self.res_chan.deinit();
    }

    pub fn send(self: Worker, req: ?*Request) !void {
        try self.req_chan.send(req);
    }

    pub fn recv(self: Worker) !?*Response {
        return try self.res_chan.recv();
    }

    fn run(name: []const u8, req_chan: chan.Chan(Request), res_chan: chan.Chan(Response)) void {
        listen(name, req_chan, res_chan) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
        };
    }

    fn listen(name: []const u8, req_chan: chan.Chan(Request), res_chan: chan.Chan(Response)) !void {
        var res = Response{ .id = 0 };

        while (try req_chan.recv()) |req| {
            std.log.info("[{s}] RECEIVED REQUEST ({d}) \"{s}\"", .{ name, req.id, req.data });

            std.time.sleep(3 * 1_000_000_000);

            res.id = req.id;
            try res_chan.send(&res);
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

    {
        if (try a.recv()) |res| {
            std.log.info("[{s}] RECEIVED RESPONSE ({d})", .{ a.name, res.id });
            try std.testing.expectEqual(Response{ .id = 0 }, res.*);
        }
    }

    {
        if (try b.recv()) |res| {
            std.log.info("[{s}] RECEIVED RESPONSE ({d})", .{ b.name, res.id });
            try std.testing.expectEqual(Response{ .id = 0 }, res.*);
        }
    }

    try a.send(null);
    try b.send(null);
}
