const std = @import("std");
const rl = @import("raylib"); // Assuming a Raylib Zig binding

const SCREEN_WIDTH = 1000;
const SCREEN_HEIGHT = 800;

const RealVector = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) RealVector {
        return .{ .x = x, .y = y };
    }

    pub fn default() RealVector {
        return .{ .x = 0, .y = 0 };
    }

    pub fn add(self: RealVector, other: RealVector) RealVector {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn sub(self: RealVector, other: RealVector) RealVector {
        return .{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn scale(self: RealVector, scalar: f32) RealVector {
        return .{ .x = self.x * scalar, .y = self.y * scalar };
    }

    pub fn getMagnitude(self: RealVector) f32 {
        return @sqrt(self.x * self.x + self.y * self.y);
    }

    pub fn normalize(self: RealVector) RealVector {
        const mag = self.getMagnitude();
        return .{ .x = self.x / mag, .y = self.y / mag };
    }

    pub fn getAngle(self: RealVector) f32 {
        if (self.x == 0) {
            return if (self.y > 0) std.math.pi / 2 else -std.math.pi / 2;
        }
        var angle = std.math.atan2(f32, self.y, self.x);
        if (self.y < 0 and self.x < 0) angle += std.math.pi;
        if (self.x < 0) angle += std.math.pi;
        return angle;
    }
};

const Boid = struct {
    position: RealVector,
    velocity: RealVector,
    acceleration: RealVector,
    danger_zone: f32,
    sight_zone: f32,
    size: f32,

    pub fn init(x: f32, y: f32, vx: f32, vy: f32, danger_zone: f32, sight_zone: f32, size: f32) Boid {
        return .{
            .position = RealVector.init(x, y),
            .velocity = RealVector.init(vx, vy),
            .acceleration = RealVector.default(),
            .danger_zone = danger_zone,
            .sight_zone = sight_zone,
            .size = size,
        };
    }

    pub fn moveBoid(self: *Boid) void {
        const w = @as(f32, @floatFromInt(rl.getScreenWidth()));
        const h = @as(f32, @floatFromInt(rl.getScreenHeight()));
        self.position = self.position.add(self.velocity);
        self.position.x = if (self.position.x > w) w else if (self.position.x < 0) 0 else self.position.x;
        self.position.y = if (self.position.y > h) h else if (self.position.y < 0) 0 else self.position.y;
    }

    pub fn showBoid(self: Boid) void {
        const mag = self.velocity.getMagnitude();
        var rv: RealVector = undefined;

        if (mag == 0) {
            rv = RealVector.init(0, -self.size);
        } else {
            rv = self.velocity.scale(self.size / mag);
        }

        const move_to_middle = RealVector.init(-rv.x / 2, -rv.y / 2);

        var tri: [3]rl.Vector2 = undefined;
        tri[0] = .{ .x = self.position.x + rv.x + move_to_middle.x, .y = self.position.y + rv.y + move_to_middle.y };
        rv = RealVector.init(rv.y, -rv.x);
        tri[1] = .{ .x = self.position.x + rv.x + move_to_middle.x, .y = self.position.y + rv.y + move_to_middle.y };
        rv = RealVector.init(-rv.x, -rv.y);
        tri[2] = .{ .x = self.position.x + rv.x + move_to_middle.x, .y = self.position.y + rv.y + move_to_middle.y };

        rl.drawCircleLines(@intFromFloat(self.position.x), @intFromFloat(self.position.y), self.danger_zone, rl.Color.red);
        rl.drawCircleLines(@intFromFloat(self.position.x), @intFromFloat(self.position.y), self.sight_zone, rl.Color.green);
        rl.drawTriangle(tri[0], tri[1], tri[2], rl.Color.black);
    }
};

fn alterBoidPath(boids: []Boid, boid_idx: usize, avoidance_factor: f64, matching_factor: f64, centering_factor: f64) void {
    var neighbours: i32 = 0;
    var vel_average = RealVector.default();
    var pos_average = RealVector.default();
    var close_d = RealVector.default();

    for (boids, 0..) |other, i| {
        if (i == boid_idx) continue;

        const difference = boids[boid_idx].position.sub(other.position);
        const distance = difference.getMagnitude();

        if (distance < boids[boid_idx].danger_zone) {
            if (distance == 0) {
                boids[boid_idx].moveBoid();
                close_d = close_d.add(difference);
            }
        } else if (distance < boids[boid_idx].sight_zone) {
            vel_average = vel_average.add(other.velocity);
            pos_average = pos_average.add(other.position);
            neighbours += 1;
        }
    }

    if (neighbours > 0) {
        vel_average = vel_average.scale(1.0 / @as(f32, @floatFromInt(neighbours)));
        pos_average = pos_average.scale(1.0 / @as(f32, @floatFromInt(neighbours)));

        const change_vel = vel_average.sub(boids[boid_idx].velocity.scale(@floatCast(matching_factor)));
        boids[boid_idx].velocity = boids[boid_idx].velocity.add(change_vel);

        const change_pos = pos_average.sub(boids[boid_idx].position.scale(@floatCast(centering_factor)));
        boids[boid_idx].velocity = boids[boid_idx].velocity.add(change_pos);
    }

    boids[boid_idx].velocity = boids[boid_idx].velocity.add(close_d.scale(@floatCast(avoidance_factor)));
}

fn boundBoid(boid: *Boid, turn_factor: f64, turn_padding: f32, sw: i32, sh: i32) void {
    if (boid.position.x < turn_padding) boid.velocity.x += @floatCast(turn_factor) else if (boid.position.x > @as(f32, @floatFromInt(sw)) - turn_padding) boid.velocity.x -= @floatCast(turn_factor);
    if (boid.position.y < turn_padding) boid.velocity.y += @floatCast(turn_factor) else if (boid.position.y > @as(f32, @floatFromInt(sh)) - turn_padding) boid.velocity.y -= @floatCast(turn_factor);
}

fn limitSpeed(boid: *Boid, min_speed: f32, max_speed: f32) void {
    const speed = boid.velocity.getMagnitude();
    if (speed != 0) {
        if (speed < min_speed) boid.velocity = boid.velocity.scale(min_speed / speed) else if (speed > max_speed) boid.velocity = boid.velocity.scale(max_speed / speed);
    }
}

const Xoshiro256 = struct {
    pub fn fill(_: *Xoshiro256, buf: []u8) void {
        @memset(buf, 0);
    }

    pub fn random(self: *Xoshiro256) std.Random {
        return std.Random.init(self, fill);
    }
};

pub fn main() !void {
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Boids");
    defer rl.closeWindow();
    rl.setTargetFPS(120);

    const turn_factor = 0.2;
    const turn_padding = 100;
    const min_speed = 1.5;
    const max_speed = 3;

    const danger_zone = 15;
    const sight_zone = 30;
    const size = 10;

    const avoidance_factor = 0.05;
    const matching_factor = 0.05;
    const centering_factor = 0.0005;

    var _xo = Xoshiro256{};
    var random = _xo.random();

    const n_boids = 100;
    var boids: [n_boids]Boid = undefined;

    for (&boids, 0..) |*boid, i| {
        if (i == 0) {} // do nottinh
        const vx = @as(f32, @floatFromInt(random.intRangeAtMost(i32, -5, 5)));
        const vy = @as(f32, @floatFromInt(random.intRangeAtMost(i32, -5, 5)));
        boid.* = Boid.init(@as(f32, @floatFromInt(random.intRangeAtMost(i32, 0, SCREEN_WIDTH))), @as(f32, @floatFromInt(random.intRangeAtMost(i32, 0, SCREEN_HEIGHT))), vx, vy, danger_zone, sight_zone, size);
    }

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.ray_white);

        for (&boids, 0..) |*boid, i| {
            alterBoidPath(&boids, i, avoidance_factor, matching_factor, centering_factor);
            limitSpeed(boid, min_speed, max_speed);
            boundBoid(boid, turn_factor, turn_padding, SCREEN_WIDTH, SCREEN_HEIGHT);
        }

        for (&boids) |*boid| {
            boid.moveBoid();
            boid.showBoid();
        }

        rl.drawFPS(10, 10);
    }
}
