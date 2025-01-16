const std = @import("std");
const util = @import("util");

pub const PAGE_SIZE: u32 = std.mem.page_size;
pub const BASE_SIZE: u32 = 8;

pub fn mAlloc(pages: usize) error{Fail}![]u8 {
    const buffer = std.posix.mmap(
        null,
        pages * PAGE_SIZE,
        0x01 | 0x02,
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    ) catch return error.Fail;

    return @alignCast(buffer);
}

pub fn mFree(memory: []const u8) void {
    const ptr: []align(PAGE_SIZE) const u8 = @alignCast(memory);
    std.posix.munmap(ptr);
}

pub fn fowardCopy(T: type, src: []const T, dst: []T) void {
    @setRuntimeSafety(false);

    const len = src.len;

    for (0..len) |i| {
        dst[i] = src[i];
    }
}

pub fn backwardCopy(T: type, src: []const T, dst: []T) void {
    @setRuntimeSafety(false);

    const len = src.len;

    for (0..len) |i| {
        dst[len - i - 1] = src[len - i - 1];
    }
}

pub fn equal(T: type, one: []const T, two: []const T) bool {
    if (one.len != two.len) return false;

    for (0..one.len) |i| {
        if (one[i] != two[i]) return false;
    }

    return true;
}

pub fn asBytes(T: type, ptr: *const T) []const u8 {
    const buffer: [*]const u8 = @ptrCast(ptr);
    const size = @sizeOf(T);

    return buffer[0..size];
}

pub fn alignWith(value: usize, with: usize) u32 {
    const rest = value % with;

    if (rest == 0) {
        return @intCast(value);
    }

    return @intCast(value + with - rest);
}

pub const Arena = struct {
    ptr: *anyopaque,
    usage: u32,
    capacity: u32,

    parent: ?*Arena,

    pub fn new(pages: u32) error{OutOfMemory}!Arena {
        const buffer = mAlloc(pages) catch return error.OutOfMemory;

        return .{
            .ptr = buffer.ptr,
            .capacity = @intCast(buffer.len),
            .usage = 0,
            .parent = null,
        };
    }

    pub fn child(self: *Arena, size: u32) error{OutOfMemory}!*Arena {
        var arena = Arena{
            .ptr = try self.alloc(u8, size),
            .capacity = size,
            .parent = self,
            .usage = 0,
        };

        errdefer arena.deinit();
        return try arena.create(Arena, arena);
    }

    pub fn alloc(self: *Arena, T: type, count: u32) error{OutOfMemory}![*]T {
        if (count == 0) {
            return @ptrCast(@alignCast(self.ptr));
        }

        const lenght = alignWith(@sizeOf(T) * count, BASE_SIZE);

        if (lenght + self.usage > self.capacity) return error.OutOfMemory;

        const ptr_offset: usize = @intFromPtr(self.ptr) + self.usage;
        const ptr: [*]T = @ptrFromInt(ptr_offset);

        self.usage += @intCast(lenght);

        return ptr;
    }

    pub fn create(self: *Arena, T: type) error{OutOfMemory}!*T {
        return @ptrCast(try self.alloc(T, 1));
    }

    pub fn deinit(self: *Arena) void {
        if (self.parent) |_| {} else {
            const buffer: [*]u8 = @ptrCast(self.ptr);
            mFree(buffer[0..self.capacity]);
        }

        self.capacity = 0;
    }
};

test "Arena init" {
}
