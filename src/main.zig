const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");
const math = std.math;
//////////////////////////////////////////////////////////////
/// CONSTANTS
//////////////////////////////////////////////////////////////
const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 600;

const CASH_FONT_SIZE: i16 = 24;
const STATS_FONT_SIZE: i16 = 18;
//////////////////////////////////////////////////////////////
/// VARIABLES
//////////////////////////////////////////////////////////////

var wave: i32 = 1;
var levelTurret: i32 = 1;
var levelDamage: i32 = 1;
var levelRotationalSpeed: i32 = 1;
var levelProjectileSpeed: i32 = 1;
var levelCooldown: i32 = 1;

var bgColor = rl.Color.black;
var fgColor = rl.Color.white;
var dt: f32 = 1;
var timeSinceLastShot: f32 = 0;

//////////////////////////////////////////////////////////////
/// STRUCTS & CONTAINERS
//////////////////////////////////////////////////////////////
const State = struct {
    time: f32 = 0,
    cash: u32 = 0,
};
var state: State = undefined;

const Player = struct { pos: rl.Vector2, turretSize: f32, gunSize: rl.Vector2, rot: f32, speed: f32, damage: f32, projectileSpeed: f32 = 4, cooldown: f32 = 2 };
var player: Player = undefined;

const Enemy = struct { pos: rl.Vector2, vel: rl.Vector2, size: f32, health: f32 };
var enemies: std.ArrayList(Enemy) = undefined;

const Projectile = struct { pos: rl.Vector2 = .{ .x = 0, .y = 0 }, vel: rl.Vector2 = .{ .x = 0, .y = 0 }, size: f32 = 5 };
var projectiles: std.ArrayList(Projectile) = undefined;

//////////////////////////////////////////////////////////////
/// FUNCTIONS
//////////////////////////////////////////////////////////////

fn switchColor() !void {
    if (std.meta.eql(bgColor, rl.Color.white)) {
        bgColor = rl.Color.black;
        fgColor = rl.Color.white;
    } else {
        bgColor = rl.Color.white;
        fgColor = rl.Color.black;
    }
}

fn drawPlayer() !void {
    //turret
    rl.drawCircleV(player.pos, player.turretSize, fgColor);

    // gun
    var rec: rl.Rectangle = .{ .x = player.pos.x, .y = player.pos.y, .width = player.gunSize.x, .height = player.gunSize.y };
    rl.drawRectanglePro(rec, .{ .x = player.gunSize.x / 2, .y = 0 }, player.rot, fgColor);
}

fn update() !void {
    // TIME
    dt = rl.getFrameTime();
    state.time += dt;
    timeSinceLastShot += dt;

    //USEFUL VARIABLES
    const dirRadians = (player.rot + 90) * (math.pi / 180.0);
    const gunDir = rl.Vector2.init(math.cos(dirRadians), math.sin(dirRadians));

    // INPUTS
    if (rl.isKeyPressed(.key_j)) {
        try switchColor();
    }

    if (rl.isKeyDown(.key_a)) {
        player.rot -= player.speed * math.tau * dt;
    }

    if (rl.isKeyDown(.key_d)) {
        player.rot += player.speed * math.tau * dt;
    }

    if (rl.isKeyDown(.key_space)) {
        if (timeSinceLastShot > player.cooldown) {
            try projectiles.append(.{ .pos = rlm.vector2Add(player.pos, rlm.vector2Scale(gunDir, player.gunSize.y + 4)), .vel = rlm.vector2Scale(gunDir, player.projectileSpeed) });
            timeSinceLastShot = 0.0;
        }
    }

    //PROJECTILES
    var i: usize = 0;
    while (i < projectiles.items.len) {
        var p = &projectiles.items[i];
        p.pos = rlm.vector2Add(p.pos, rlm.vector2Scale(p.vel, dt * 10));
        //projectile left the screen
        if ((p.pos.x < 0) or (p.pos.y < 0) or (p.pos.x > SCREEN_WIDTH) or (p.pos.y > SCREEN_HEIGHT)) {
            _ = projectiles.swapRemove(i);
        }
        i += 1;
    }
}

fn render() !void {
    try drawPlayer();

    for (projectiles.items) |p| {
        rl.drawCircleV(p.pos, p.size, fgColor);
    }

    // STATS
    const cashString: [:0]const u8 = rl.textFormat("$%02i", .{state.cash});
    const cashStringWidth = rl.measureText(cashString, CASH_FONT_SIZE);
    rl.drawText(cashString, SCREEN_WIDTH - cashStringWidth - 5, 5, CASH_FONT_SIZE, fgColor);

    rl.drawText("STATS:", 5, STATS_FONT_SIZE * 0 + 5, STATS_FONT_SIZE, fgColor);
    rl.drawText("Wave:    1", 5, STATS_FONT_SIZE * 1 + 5, STATS_FONT_SIZE, fgColor);
    rl.drawText("Turret: 1", 5, STATS_FONT_SIZE * 2 + 5, STATS_FONT_SIZE, fgColor);
    rl.drawText("Damage: 1", 5, STATS_FONT_SIZE * 3 + 5, STATS_FONT_SIZE, fgColor);
}

//////////////////////////////////////////////////////////////
/// MAIN
//////////////////////////////////////////////////////////////
pub fn main() anyerror!void {
    // INITIALIZATIONS
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    state = .{};
    player = .{ .pos = .{ .x = SCREEN_WIDTH / 2, .y = SCREEN_HEIGHT / 2 }, .turretSize = 10, .gunSize = .{ .x = 10, .y = 20 }, .rot = 90.0, .speed = 10, .damage = 1 };
    projectiles = std.ArrayList(Projectile).init(allocator);
    defer projectiles.deinit();

    // WINDOW & GAME LOOP
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "turret defense!");
    defer rl.closeWindow();

    while (!rl.windowShouldClose()) {
        try update();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(bgColor);

        try render();
    }
}
