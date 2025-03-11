package game

import "core:fmt"
import rl "vendor:raylib"

WINDOW_SIZE: [2]i32 = {800, 600}

run: bool

back_color := rl.Color{49, 34, 73, 255}
status_message: cstring = "no message yet"
status_message_color := rl.Color{214, 155, 128, 255}

currentLevel: Level
ballInPlay: bool
gameBall: GameBall // relevant only if ballInPlay is true TODO: convert to Maybe(GameBall)
gravity: f32 = 200

init :: proc() {
	run = true
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(WINDOW_SIZE.x, WINDOW_SIZE.y, "BapaFlop")
	currentLevel = init_level() //Initial level
}

update :: proc() {
	frame_time := rl.GetFrameTime()
	rl.BeginDrawing()
	rl.ClearBackground(back_color)
	// status_message = fmt.ctprintf(
	// 	"%i, %i",
	// 	i32(rl.GetMousePosition().x),
	// 	i32(rl.GetMousePosition().y),
	// )

	// update ball position (if it exists)
	if ballInPlay {
		gameBall.speed.y += gravity * frame_time
		gameBall.center += gameBall.speed * frame_time

		if gameBall.center.y > f32(WINDOW_SIZE.y) {
			ballInPlay = false
			//TODO: replace this with game over logic
		}

		flipper_collision_check()
	}


	if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
		if !ballInPlay {
			spawn_ball_if_clicked()
		}
	}

	draw_level(currentLevel)

	rl.DrawText(status_message, 8, WINDOW_SIZE.y - 25, 22, status_message_color)

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
		if rectangle_intersects(mouse_pos, spawner.rectangle) {
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

// Checks if ball (if in play) is colliding with any flipper and handles the bounce
flipper_collision_check :: proc() {
	for y := gameBall.last_bounced_row + 1; y < 4; y += 1 {
		for x := 0; x < 8; x += 1 {
			flip := &currentLevel.flipper[y][x]
			if flip.active {
				if rectangle_intersects(gameBall.center, flip.rectangle) {
					//game collided with flipper
					flipper_center := get_rectangle_center(flip.rectangle)
					gameBall.center.x = flipper_center.x
					gameBall.speed.x = f32(flip.direction * 100)
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

