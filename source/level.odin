package game

import rl "vendor:raylib"

SPAWNER_TOP :: 40
SPAWNER_HEIGHT :: 30

Spawner :: struct {
	rectangle: rl.Rectangle,
	active:    bool,
}

Level :: struct {
	name:    string,
	spawner: [8]Spawner,
}

init_level :: proc() -> Level {
	ret := Level {
		name = "Test level",
	}

	for i: i32 = 0; i < 8; i += 1 {
		ret.spawner[i].rectangle = {f32(i * 100 + 10), SPAWNER_TOP, 80, SPAWNER_HEIGHT}
		ret.spawner[i].active = true
	}

	return ret
}

draw_spawner :: proc(spawner: Spawner) {
	if spawner.active {
		using spawner
		rl.DrawRectangleRec(spawner.rectangle, rl.GREEN)
	}
}

