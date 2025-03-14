package game

import "core:strconv"
import "core:strings"
import rl "vendor:raylib"

SPAWNER_TOP :: 50
SPAWNER_HEIGHT :: 30
FLIPPER_WIDTH :: 80
FLIPPER_HEIGHT :: 40
HATCH_TOP :: 540
HATCH_HEIGHT :: 40
LEVEL_SHADOW_COLOR := rl.Color{40, 23, 51, 255}
LEVEL_NAME_COLOR := rl.Color{214, 155, 128, 255}

LevelDefinition :: struct {
	name: cstring,
	code: cstring,
}

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
	radius:           f32, // ball radius
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

	if len(fullScreenMessage) > 0 {
		rl.DrawText(fullScreenMessage, 50, 250, 90, fullScreenMessageColor)
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
	if design_mode {
		level_code := level_to_string(level)
		// rl.DrawText("DESIGN MODE", 8, 8, 22, rl.RED)
		rl.DrawText(level_code, 8, 8, 22, rl.SKYBLUE)
	} else {
		rl.DrawText(level.name, 8, 8, 22, LEVEL_NAME_COLOR)
	}

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
	if design_mode {
		rl.DrawRectangleLinesEx(spawner.rectangle, 1, LEVEL_SHADOW_COLOR)
	}
	if spawner.active {
		rl.DrawRectangleLinesEx(spawner.rectangle, 1, rl.DARKGREEN)
	}
}

draw_flipper :: proc(flipper: Flipper) {
	if design_mode {
		rl.DrawRectangleLinesEx(flipper.rectangle, 1, LEVEL_SHADOW_COLOR)
	}
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
	if design_mode {
		rl.DrawRectangleLinesEx(hatch.rectangle, 1, LEVEL_SHADOW_COLOR)
	}
	if hatch.active {
		rl.DrawRectangleLinesEx(hatch.rectangle, 1, rl.PURPLE)
	}
}

draw_game_ball :: proc() {
	if ballInPlay {
		rl.DrawCircleV(gameBall.center, gameBall.radius, rl.BLUE)
	}
}

// Generates level string from level
level_to_string :: proc(level: Level) -> cstring {
	// Level is stored as a string of hexadecimal characters:
	// Each byte holds state of 8 booleans
	// Bits of first byte specify which spawners are visible
	// Bits of second byte specfy which flippers in the first row are visible
	// Bits of a third byte specfy which filppers in the first row have direction towards right
	// etc...
	// Structure is like this:
	// SS,FFDD,FFDD,FFDD,FFDD,HH
	// 
	// SS -> which spawners are visible
	// FF -> which flippers are visible in corresponding row
	// DD -> which flippers in corresponding row point right
	// HH -> which hatches are visible

	ret: string

	// spawners
	spawner_bits: i32 = 0
	#reverse for spawner in level.spawner {
		spawner_bits = spawner_bits << 1
		if spawner.active {
			spawner_bits |= 1
		}
	}
	ret = int_to_string(i64(spawner_bits))

	// flippers
	for y := 0; y < 4; y += 1 {
		flipper_visiblity_bits: i32 = 0
		flipper_direction_bits: i32 = 0

		for x := 7; x >= 0; x -= 1 {
			flipper := level.flipper[y][x]
			flipper_visiblity_bits = flipper_visiblity_bits << 1
			flipper_direction_bits = flipper_direction_bits << 1
			if flipper.active {
				flipper_visiblity_bits |= 1
			}
			if flipper.direction > 0 {
				flipper_direction_bits |= 1
			}
		}
		ret = strings.join({ret, ",", int_to_string(i64(flipper_visiblity_bits))}, "")
		ret = strings.join({ret, int_to_string(i64(flipper_direction_bits))}, "")
	}

	// hatches
	hatch_bits: i32 = 0
	#reverse for hatch in level.hatch {
		hatch_bits = hatch_bits << 1
		if hatch.active {
			hatch_bits |= 1
		}
	}
	ret = strings.join({ret, ",", int_to_string(i64(hatch_bits))}, "")

	return strings.clone_to_cstring(ret)
}

// Decodes the level string and populates the level accordingly
string_to_level :: proc(levelString: cstring, level: ^Level) {
	level.score = 0

	// see level_to_string for string format 
	str: string = string(levelString)
	str, _ = strings.replace_all(str, ",", "")

	// spawners
	spawner_string, _ := strings.substring(str, 0, 2)
	spawner_bits, _ := strconv.parse_int(spawner_string, 16)
	for &spawner in level.spawner {
		spawner.active = (spawner_bits & 1) == 1
		spawner_bits = spawner_bits >> 1
	}

	// flippers
	for y := 0; y < 4; y += 1 {
		flipBlockStart := 2 + y * 4
		flipper_string, _ := strings.substring(str, flipBlockStart, flipBlockStart + 2)
		flipper_bits, _ := strconv.parse_int(flipper_string, 16)

		flipper_dir_string, _ := strings.substring(str, flipBlockStart + 2, flipBlockStart + 4)
		flipper_dir_bits, _ := strconv.parse_int(flipper_dir_string, 16)
		for x := 0; x < 8; x += 1 {
			flipper := &level.flipper[y][x]
			flipper.active = (flipper_bits & 1) == 1
			flipper_bits = flipper_bits >> 1

			flipper.direction = (flipper_dir_bits & 1) == 1 ? 1 : -1
			flipper_dir_bits = flipper_dir_bits >> 1
		}
	}

	// hatches
	hatch_string, _ := strings.substring(str, 18, 20)
	hatch_bits, _ := strconv.parse_int(hatch_string, 16)
	for &hatch in level.hatch {
		hatch.active = (hatch_bits & 1) == 1
		hatch_bits = hatch_bits >> 1
	}

	// balls
	balls_string, _ := strings.substring(str, 20, 21)
	balls_bits, _ := strconv.parse_int(balls_string, 10)
	level.balls = i32(balls_bits)
}

int_to_string :: proc(value: i64) -> string {
	buf: [4]byte
	result := strings.to_upper(strconv.append_int(buf[:], value, 16))
	if value <= 15 {
		result = strings.join({"0", result}, "")
	}
	return result
}

