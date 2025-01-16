const mem = @import("mem.zig");

pub fn Vector(T: type) type {
    return struct {
        items: [*]T,
        len: u32,
        capacity: u32,

        const Self = @This();

        pub fn new(size: u32, arena: *mem.Arena) error{OutOfMemory}!Self {
            return Self{
                .items = try arena.alloc(T, size),
                .capacity = size,
                .len = 0,
            };
        }

        pub fn push(self: *Self, item: T) error{OutOfBounds}!void {
            if (self.len >= self.capacity) return error.OutOfBounds;

            defer self.len += 1;
            self.items[self.len] = item;
        }

        pub fn remove(self: *Self, index: usize) error{OutOfBounds}!void {
            try self.shift_left(index, 1);
        }

        pub fn extend(self: *Self, items: []const T) error{OutOfBounds}!void {
            if (self.len + items.len > self.capacity) return error.OutOfBounds;

            for (0..items.len) |i| {
                self.items[self.len + i] = items[i];
            }

            self.len += @intCast(items.len);
        }

        pub fn shiftLeft(self: *Self, index: usize, count: usize) error{OutOfBounds}!void {
            if (index + 1 < count) return error.OutOfBounds;
            if (index >= self.len) return error.OutOfBounds;

            defer self.len -= @intCast(count);
            mem.fowardCopy(T, self.items[index + count .. self.len], self.items[index .. self.len - count]);
        }

        pub fn shiftRight(self: *Self, index: usize, count: usize) error{OutOfBounds}!void {
            if (self.len + count > self.capacity) return error.OutOfBounds;
            if (index >= self.len) return error.OutOfBounds;

            defer self.len += @intCast(count);
            mem.backwardCopy(T, self.items[index..self.len], self.items[index + count .. self.len + count]);
        }

        pub fn getMut(self: *const Self, index: u32) error{OutOfBounds}!*T {
            if (index >= self.len) return error.OutOfBounds;

            return &self.items[index];
        }

        pub fn get(self: *const Self, index: u32) error{OutOfBounds}!T {
            if (index >= self.len) return error.OutOfBounds;
            return self.items[index];
        }

        pub fn getBack(self: *const Self, index: usize) error{OutOfBounds}!T {
            if (index >= self.len) return error.OutOfBounds;
            return self.items[self.len - index - 1];
        }

        pub fn getMutBack(self: *const Self, index: usize) error{OutOfBounds}!*T {
            if (index >= self.len) return error.OutOfBounds;
            return &self.items[self.len - index - 1];
        }

        pub fn lastMut(self: *const Self) error{OutOfBounds}!*T {
            if (self.len == 0) return error.OutOfBounds;

            return &self.items[self.len - 1];
        }

        pub fn pop(self: *Self) error{OutOfBounds}!T {
            if (self.len == 0) return error.OutOfBounds;

            defer self.len -= 1;
            return self.items[self.len - 1];
        }

        pub fn freeSpace(self: *const Self) []T {
            return self.items[self.len..self.capacity];
        }

        pub fn setLen(self: *Self, len: u32) error{OutOfBounds}!void {
            if (len > self.capacity) return error.OutOfBounds;
            self.len = len;
        }

        pub fn offset(self: *const Self, o: u32) error{OutOfBounds}![]const T {
            if (o > self.len) return error.OutOfBounds;

            return self.items[o..self.len];
        }

        pub fn clear(self: *Self) void {
            self.len = 0;
        }

        pub fn deinit(self: *Self, arena: *mem.Arena) void {
            defer {
                self.clear();
                self.capacity = 0;
            }

            arena.destroy(T, self.capacity);
        }
    };
}

test "Vector init" {
    var arena = try mem.Arena.new("Test", 1);
    _ = try Vector(u32).new(10, &arena);
}
