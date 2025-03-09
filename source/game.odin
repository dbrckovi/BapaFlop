package game

import rl "vendor:raylib"

WINDOW_SIZE: [2]i32 = {800, 600}

run: bool

back_color := rl.Color{49, 34, 73, 255}
status_message: cstring = "no message yet"
status_message_color := rl.Color{214, 155, 128, 255}
status_message_backcolor := rl.Color{40, 23, 51, 255}

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

	for spawner in currentLevel.spawner {
		draw_spawner(spawner)
	}

	// status message
	rl.DrawRectangleRec(
		{2, f32(WINDOW_SIZE.y - 20), f32(WINDOW_SIZE.x - 4), 18},
		status_message_backcolor,
	)
	rl.DrawText(status_message, 8, WINDOW_SIZE.y - 18, 15, status_message_color)

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

