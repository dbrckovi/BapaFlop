package game

import "core:fmt"
import rl "vendor:raylib"

WINDOW_SIZE: [2]i32 = {800, 600}

run: bool

back_color := rl.Color{49, 34, 73, 255}
status_message: cstring = "no message yet"
status_message_color := rl.Color{214, 155, 128, 255}

currentLevel: Level

init :: proc() {
	run = true
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(WINDOW_SIZE.x, WINDOW_SIZE.y, "BapaFlop")
	currentLevel = init_level() //Initial level
}

update :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(back_color)
	status_message = fmt.ctprintf(
		"%i, %i",
		i32(rl.GetMousePosition().x),
		i32(rl.GetMousePosition().y),
	)

	draw_level(currentLevel)

	// status message
	// rl.DrawRectangleRec(
	// 	{2, f32(WINDOW_SIZE.y - 30), f32(WINDOW_SIZE.x - 4), 28},
	// 	status_message_backcolor,
	// )
	// rl.DrawText(status_message, 8, WINDOW_SIZE.y - 25, 22, status_message_color)

	rl.EndDrawing()

	// Anything allocated using temp allocator is invalid after this.
	free_all(context.temp_allocator)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
parent_window_size_changed :: proc(w, h: int) {
	// 	rl.SetWindowSize(c.int(w), c.int(h))
}

shutdown :: proc() {
	rl.CloseWindow()
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			run = false
		}
	}

	return run
}

