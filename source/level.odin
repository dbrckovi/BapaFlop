package game

import rl "vendor:raylib"

SPAWNER_TOP :: 50
SPAWNER_HEIGHT :: 30
FLIPPER_WIDTH :: 80
FLIPPER_HEIGHT :: 40
HATCH_TOP :: 540
HATCH_HEIGHT :: 40
LEVEL_SHADOW_COLOR := rl.Color{40, 23, 51, 255}
LEVEL_NAME_COLOR := rl.Color{214, 155, 128, 255}

Level :: struct {
	name:    cstring, // name of the level
	spawner: [8]Spawner, // array of all possible spawners
	flipper: [4][8]Flipper, // "2D array" of flippers [row][colum]
	hatch:   [8]Hatch, // array of all possible hatches
	balls:   i32, // how many balls the level started with
	score:   i32, // how many balls were successfully scored (brought to finish hatch)
}

Spawner :: struct {
	rectangle: rl.Rectangle, // determines where spawner is
	active:    bool, // determines if spawner is in the level
}

Flipper :: struct {
	rectangle: rl.Rectangle, // determines where flipper is (usedfor collision detection)
	active:    bool, // determines if spawner is in the level
	direction: int, // determines flipper direction (-1 causes the ball to bounce left, 1 to bounce right)
}

Hatch :: struct {
	rectangle: rl.Rectangle, // determines where hatch is
	active:    bool, // determines if hatch is in the level
}

GameBall :: struct {
	center:           [2]f32, // determines where ball center is
	speed:            rl.Vector2, // pixels per second
	last_bounced_row: int, // don't perform collision checks on this row of flippers or all above it 
}

init_level :: proc() -> Level {
	ret := Level {
		name  = "TEST LEVEL",
		balls = 3,
		score = 0,
	}

	// init spawners
	for i: i32 = 0; i < 8; i += 1 {
		ret.spawner[i].rectangle = {f32(i * 100 + 10), SPAWNER_TOP, 80, SPAWNER_HEIGHT}
		ret.spawner[i].active = true
	}

	// init flippers
	for y := 0; y < 4; y += 1 {
		for x := 0; x < 8; x += 1 {
			flip := &ret.flipper[y][x]
			flip.active = true
			flip.rectangle = {f32(x * 100 + 10), f32(y * 100 + 150), FLIPPER_WIDTH, FLIPPER_HEIGHT}
			flip.direction = -1
		}
	}

	// init hatches
	for i: i32 = 0; i < 8; i += 1 {
		ret.hatch[i].rectangle = {f32(i * 100 + 10), HATCH_TOP, 80, HATCH_HEIGHT}
		ret.hatch[i].active = true
	}

	return ret
}

// Draws all game elements
draw_level :: proc(level: Level) {
	draw_level_borders()

	draw_level_stats(currentLevel)

	// Draw spawners
	for spawner in currentLevel.spawner {
		draw_spawner(spawner)
	}

	// Draw flippers
	for y := 0; y < 4; y += 1 {
		for x := 0; x < 8; x += 1 {
			draw_flipper(currentLevel.flipper[y][x])
		}
	}

	// draw hatches
	for hatch in currentLevel.hatch {
		draw_hatch(hatch)
	}

	if ballInPlay {
		draw_game_ball()
	}

}

draw_level_borders :: proc() {
	rl.DrawRectangleRec({0, 0, f32(WINDOW_SIZE.x), 30}, LEVEL_SHADOW_COLOR)
	rl.DrawRectangleRec({0, 30, 5, f32(WINDOW_SIZE.y - 30)}, LEVEL_SHADOW_COLOR)
	rl.DrawRectangleRec(
		{f32(WINDOW_SIZE.x - 6), 30, 6, f32(WINDOW_SIZE.y - 30)},
		LEVEL_SHADOW_COLOR,
	)

}

draw_level_stats :: proc(level: Level) {
	rl.DrawText(level.name, 8, 8, 22, LEVEL_NAME_COLOR)

	// draw balls left to score
	ballsToScore := level.balls - level.score
	for b: i32 = 0; b < level.balls; b += 1 {
		if b + 1 > ballsToScore {
			rl.DrawCircleLines(400 + (b * 30), 17, 9, rl.RED)
		} else {
			rl.DrawCircle(400 + (b * 30), 17, 9, rl.RED)
		}
	}

	// draw score
	for s: i32 = 0; s < level.score; s += 1 {
		rl.DrawCircle(780 - (s * 30), 17, 9, rl.GOLD)
	}
}

draw_spawner :: proc(spawner: Spawner) {
	if spawner.active {
		rl.DrawRectangleLinesEx(spawner.rectangle, 1, rl.DARKGREEN)
	}
}

draw_flipper :: proc(flipper: Flipper) {
	if flipper.active {
		center := get_rectangle_center(flipper.rectangle)
		r: rl.Rectangle = {center.x - 20, center.y - 10, 40, 20}
		if flipper.direction == -1 {
			rl.DrawLine(i32(r.x), i32(r.y + r.height), i32(r.x + r.width), i32(r.y), rl.BROWN)
		} else {
			rl.DrawLine(i32(r.x), i32(r.y), i32(r.x + r.width), i32(r.y + r.height), rl.BROWN)
		}
	}
}

draw_hatch :: proc(hatch: Hatch) {
	if hatch.active {
		rl.DrawRectangleLinesEx(hatch.rectangle, 1, rl.PURPLE)
	}
}

draw_game_ball :: proc() {
	if ballInPlay {
		rl.DrawCircleV(gameBall.center, 10, rl.BLUE)
	}
}

