package game

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

WINDOW_SIZE: [2]i32 = {800, 600}

run: bool

back_color := rl.Color{49, 34, 73, 255}
clipBoardLevelString: cstring = "FF,FF00,FF00,FF00,FF00,FF"
currentLevel: Level
ballInPlay: bool
gameBall: GameBall // relevant only if ballInPlay is true TODO: convert to Maybe(GameBall)
gravity: f32 = 200
friction: f32 = 200

design_mode := false
help_visible := false
status_message: cstring = ""

init :: proc() {
	run = true
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.SetTargetFPS(500)
	rl.InitWindow(WINDOW_SIZE.x, WINDOW_SIZE.y, "BapaFlop")
	currentLevel = init_level()
	// string_to_level("BD,7E08,7E1C,7E08,7E08,66", &currentLevel)
}

update :: proc() {
	frame_time := rl.GetFrameTime()
	rl.BeginDrawing()
	rl.ClearBackground(back_color)

	// update ball position (if it exists)
	if ballInPlay {
		gameBall.speed.y += gravity * frame_time
		if (gameBall.speed.x > 0) {gameBall.speed.x -= friction * frame_time}
		if (gameBall.speed.x < 0) {gameBall.speed.x += friction * frame_time}
		// gameBall.speed.x *= 0.983
		gameBall.center += gameBall.speed * frame_time
		gameBall.radius = 13

		if gameBall.center.y > f32(WINDOW_SIZE.y) {
			ballInPlay = false
			//TODO: replace this with game over logic
		}

		flipper_collision_check()
		wall_collision_check()
	} else {
		if rl.IsKeyPressed(rl.KeyboardKey.D) {
			design_mode = !design_mode
		}

		if rl.IsKeyPressed(rl.KeyboardKey.H) {
			help_visible = !help_visible
		}

		if rl.IsKeyPressed(rl.KeyboardKey.C) {
			clipBoardLevelString = level_to_string(currentLevel)
			status_message = strings.clone_to_cstring(
				strings.join({"Level saved: ", string(clipBoardLevelString)}, ""),
			)
		}

		if rl.IsKeyPressed(rl.KeyboardKey.V) {
			string_to_level(clipBoardLevelString, &currentLevel)
			status_message = strings.clone_to_cstring(
				strings.join({"Level restored: ", string(clipBoardLevelString)}, ""),
			)
		}

		if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
			spawn_ball_if_clicked()
			if design_mode {
				flip_flipper_if_clicked()
			}
		}
		if rl.IsMouseButtonReleased(rl.MouseButton.RIGHT) {
			if design_mode {
				toggle_flipper_active_if_clicked()
				toggle_spawner_active_if_clicked()
				toggle_hatch_active_if_clicked()
			}
		}
	}


	draw_level(currentLevel)

	if help_visible {
		draw_help()
	}

	if len(status_message) == 0 && !ballInPlay {
		rl.DrawText("H: help", 8, WINDOW_SIZE.y - 16, 16, HELP_TEXT_COLOR)
		rl.DrawText("D: toggle design mode", 200, WINDOW_SIZE.y - 16, 16, HELP_TEXT_COLOR)
	} else {
		rl.DrawText(status_message, 8, WINDOW_SIZE.y - 16, 16, HELP_TEXT_COLOR)
	}

	rl.EndDrawing()

	// Anything allocated using temp allocator is invalid after this.
	free_all(context.temp_allocator)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
parent_window_size_changed :: proc(w, h: int) {
	// 	rl.SetWindowSize(c.int(w), c.int(h))
}

// Closes the window (causing the game to exit on desktop)
shutdown :: proc() {
	rl.CloseWindow()
}

// Exits the game when windows is closed
should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			run = false
		}
	}

	return run
}

// If spawner is clicked, spawns a ball on it's location
spawn_ball_if_clicked :: proc() {
	mouse_pos := rl.GetMousePosition()
	for spawner in currentLevel.spawner {
		if rectangle_intersects(mouse_pos, spawner.rectangle) && spawner.active {
			gameBall = {
				center           = get_rectangle_center(spawner.rectangle),
				speed            = rl.Vector2{0, 0},
				last_bounced_row = -1,
			}
			ballInPlay = true
			break
		}
	}
}

flip_flipper_if_clicked :: proc() {
	mouse_pos := rl.GetMousePosition()

	for y := 0; y < 4; y += 1 {
		for x := 0; x < 8; x += 1 {
			flip := &currentLevel.flipper[y][x]

			if flip.active && rectangle_intersects(mouse_pos, flip.rectangle) {
				flip.direction *= -1
				break
			}
		}
	}
}

toggle_flipper_active_if_clicked :: proc() {
	mouse_pos := rl.GetMousePosition()

	for y := 0; y < 4; y += 1 {
		for x := 0; x < 8; x += 1 {
			flip := &currentLevel.flipper[y][x]

			if rectangle_intersects(mouse_pos, flip.rectangle) {
				flip.active = !flip.active
				break
			}
		}
	}
}

toggle_spawner_active_if_clicked :: proc() {
	mouse_pos := rl.GetMousePosition()

	for &spawner in currentLevel.spawner {
		if rectangle_intersects(mouse_pos, spawner.rectangle) {
			spawner.active = !spawner.active
			break
		}
	}
}

toggle_hatch_active_if_clicked :: proc() {
	mouse_pos := rl.GetMousePosition()

	for &hatch in currentLevel.hatch {
		if rectangle_intersects(mouse_pos, hatch.rectangle) {
			hatch.active = !hatch.active
			break
		}
	}
}

// checks if ball (if in play) is colliding with any wall and handles the bounce
wall_collision_check :: proc() {
	if gameBall.speed.x < 0 && gameBall.center.x < gameBall.radius {
		gameBall.speed.x *= -0.8
	}
	if gameBall.speed.x > 0 && gameBall.center.x > (f32(WINDOW_SIZE.x) - gameBall.radius) {
		gameBall.speed.x *= -0.8
	}
}

// Checks if ball (if in play) is colliding with any flipper and handles the bounce
flipper_collision_check :: proc() {
	for y := gameBall.last_bounced_row + 1; y < 4; y += 1 {
		for x := 0; x < 8; x += 1 {
			flip := &currentLevel.flipper[y][x]
			if flip.active {
				if rectangle_intersects(gameBall.center, flip.rectangle) {
					//ball collided with flipper
					flipper_center := get_rectangle_center(flip.rectangle)
					gameBall.center.x = flipper_center.x
					gameBall.speed.x = f32(flip.direction * 200)
					gameBall.speed.y = 0
					gameBall.last_bounced_row = y
					flip.direction *= -1
					return
				}
			}
		}
	}
}

// Checks if Vector2 is inside Rectangle
rectangle_intersects :: proc(point: rl.Vector2, rect: rl.Rectangle) -> bool {
	return(
		rect.x < point.x &&
		rect.y < point.y &&
		(rect.x + rect.width) > point.x &&
		(rect.y + rect.height) > point.y \
	)
}

// Gets center point of a rectangle
get_rectangle_center :: proc(rect: rl.Rectangle) -> rl.Vector2 {
	return {rect.x + rect.width / 2, rect.y + rect.height / 2}
}

// Prints a DEBUG message to stdout
debug_print :: proc(message: any) {
	fmt.println("----------------DEBUG----------------")
	fmt.println(message)
	fmt.println("-------------------------------------")
}

draw_help :: proc() {
	background_rectangle := rl.Rectangle{20, 50, f32(WINDOW_SIZE.x - 40), f32(WINDOW_SIZE.y - 100)}

	rl.DrawRectangleRounded(background_rectangle, 0.1, 1, LEVEL_SHADOW_COLOR)
	rl.DrawRectangleRoundedLines(background_rectangle, 0.1, 1, rl.GRAY)

	text: cstring = design_mode ? HELP_TEXT_DESIGN : HELP_TEXT_GAME
	rl.DrawText(text, 35, 75, 20, HELP_TEXT_COLOR)
}

