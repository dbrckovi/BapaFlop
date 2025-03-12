package game

import rl "vendor:raylib"

HELP_TEXT_COLOR :: rl.Color{214, 155, 128, 255}

HELP_TEXT_GAME ::
	"The goal of the game is to drop each ball into a basket at the bottom.\n" +
	"\n" +
	"To do this, click on a hatch at the top.\n" +
	"\n" +
	"The ball will fall and bounce off the flippers.\n" +
	"Each time the ball bounces, the flipper will 'flip', causing the next\n" +
	"ball that hits it, to bounce in the opposite direction.\n" +
	"\n" +
	"To clear the level, all balls must be dropped into any basket." +
	"\n" +
	"If any ball misses the basket, the level is lost and will restart.\n"

HELP_TEXT_DESIGN ::
	"This is level design mode.\n" +
	"It's currently useful only for development.\n" +
	"\n" +
	"CONTROLS:\n" +
	"\n" +
	" - Right click - shows or hides any level object\n" +
	" - Left click - flips the flipper\n" +
	" - C - save the current level layout to memory\n" +
	" - V - reload previously saved level layout\n"

