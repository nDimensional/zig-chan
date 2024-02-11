const std = @import("std");
const c = @import("c.zig");

pub fn Chan(comptime T: type) type {
    return struct {
        const Self = @This();
        ptr: *c.chan_t,

        pub fn init(capacity: usize) !Self {
            if (c.chan_init(capacity)) |ptr| {
                return .{ .ptr = ptr };
            } else {
                return error.ERROR;
            }

            // switch (c.errno) {
            //     c.EINVAL => return error.INVAL,
            //     c.ENOMEM => return error.NOMEM,
            //     else => @panic("failed to initialize chan"),
            // }
        }

        pub fn deinit(self: Self) void {
            c.chan_dispose(self.ptr);
        }

        pub fn close(self: Self) !void {
            switch (c.chan_close(self.ptr)) {
                0 => return,
                else => return error.ERROR,
            }

            // switch (err) {
            //     c.EPIPE => return error.PIPE,
            //     else => @panic("failed to close chan"),
            // }
        }

        pub fn isClosed(self: Self) bool {
            return c.chan_is_closed(self.ptr) != 0;
        }

        pub fn getSize(self: Self) usize {
            const size = c.chan_size(self.ptr);
            if (size < 0) {
                @panic("expected size to be non-negative");
            }

            return @intCast(size);
        }

        /// Sends a value into the channel. If the channel is unbuffered, this will
        /// block until a receiver receives the value. If the channel is buffered and at
        /// capacity, this will block until a receiver receives a value.
        pub fn send(self: Self, msg: ?*T) !void {
            switch (c.chan_send(self.ptr, msg)) {
                0 => return,
                else => return error.ERROR,
            }

            // switch (err) {
            //     c.EPIPE => return error.PIPE,
            //     else => @panic("failed to send"),
            // }
        }

        /// Receives a value from the channel. This will block until there is data to receive.
        pub fn recv(self: Self) !?*T {
            var data: ?*T = null;
            switch (c.chan_recv(self.ptr, @ptrCast(&data))) {
                0 => return data,
                else => return error.ERROR,
            }

            // switch (err) {
            //     c.EPIPE => return error.PIPE,
            //     else => @panic("failed to receive"),
            // }
        }
    };
}
