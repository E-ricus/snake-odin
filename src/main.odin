package main

import rl "vendor:raylib"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450

SNAKE_LENGTH :: 256
SQUARE_SIZE :: 31

Snake :: struct {
	position: rl.Vector2,
	size:     rl.Vector2,
	speed:    rl.Vector2,
	color:    rl.Color,
}

Food :: struct {
	position: rl.Vector2,
	size:     rl.Vector2,
	active:   bool,
	color:    rl.Color,
}

game_over := false
pause := false
allow_move := false

frames_counter := 0
counter_tail := 0

offset := rl.Vector2{0, 0}

snake: [SNAKE_LENGTH]Snake
fruit: Food
// TODO: Instead of this, following each position in the snake array would save memory(?)
snake_position: [SNAKE_LENGTH]rl.Vector2


main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Snake XD")
	defer rl.CloseWindow()

	init_game()

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() { 	// Game loop
		update_game()
		draw_game()
	}

}

init_game :: proc() {
	frames_counter = 0
	game_over = false
	pause = false
	allow_move := false

	counter_tail = 1

	offset.x = SCREEN_WIDTH % SQUARE_SIZE
	offset.y = SCREEN_HEIGHT % SQUARE_SIZE

	for i := 0; i < SNAKE_LENGTH; i += 1 {
		snake[i].position = rl.Vector2{offset.x / 2, offset.y / 2}
		snake[i].size = {SQUARE_SIZE, SQUARE_SIZE}
		snake[i].speed = {SQUARE_SIZE, 0}

		snake[i].color = i == 0 ? rl.DARKBLUE : rl.BLUE

		snake_position[i] = {0.0, 0.0}
	}

	fruit = Food {
		color = rl.SKYBLUE,
		size = {SQUARE_SIZE, SQUARE_SIZE},
	}
}

update_game :: proc() {
	if game_over {
		if rl.IsKeyPressed(.ENTER) {
			init_game()
			game_over = false
		}
		return
	}

	if rl.IsKeyPressed(.P) do pause = !pause
	if pause do return

	player_control()

	// Snake movement
	for i := 0; i < counter_tail; i += 1 do snake_position[i] = snake[i].position


	if (frames_counter % 5) == 0 {
		for i := 0; i < counter_tail; i += 1 {
			if (i != 0) {
				snake[i].position = snake_position[i - 1]
				continue
			}
			snake[0].position.x += snake[0].speed.x
			snake[0].position.y += snake[0].speed.y
			allow_move = true
		}
	}

	// Wall behaviour
	if snake[0].position.x > (SCREEN_WIDTH - offset.x) ||
	   snake[0].position.y > (SCREEN_HEIGHT - offset.y) ||
	   snake[0].position.x < 0 ||
	   snake[0].position.y < 0 {
		game_over = true
	}

	// Collision with yourself
	for i := 1; i < counter_tail; i += 1 {
		if snake[0].position.x == snake[i].position.x &&
		   snake[0].position.y == snake[i].position.y {
			game_over = true
		}
	}

	// Fruit position calculation
	if !fruit.active {
		fruit.active = true
		fruit.position =  {
			fruit_position(SCREEN_WIDTH, offset.x),
			fruit_position(SCREEN_HEIGHT, offset.y),
		}

		for i := 0; i < counter_tail; i += 1 {
			for fruit.position.x == snake[i].position.x &&
			    fruit.position.y == snake[i].position.y {
				fruit.position =  {
					fruit_position(SCREEN_WIDTH, offset.x),
					fruit_position(SCREEN_HEIGHT, offset.y),
				}
				i = 0
			}
		}
	}

	// Collision
	if collision() {
		snake[counter_tail].position = snake_position[counter_tail - 1]
		counter_tail += 1
		fruit.active = false
	}

	frames_counter += 1
}

fruit_position :: proc(width_height: i32, offset: f32) -> f32 {
	random_pos := rl.GetRandomValue(0, (width_height / SQUARE_SIZE) - 1)
	return f32(random_pos) * f32(SQUARE_SIZE) + offset / 2
}

collision :: proc() -> bool {
	return(
		(snake[0].position.x < (fruit.position.x + fruit.size.x) &&
			(snake[0].position.x + snake[0].size.x) > fruit.position.x) &&
		(snake[0].position.y < (fruit.position.y + fruit.size.y) &&
				(snake[0].position.y + snake[0].size.y) > fruit.position.y) \
	)
}

player_control :: proc() {
	switch {
	case rl.IsKeyPressed(.RIGHT) && snake[0].speed.x == 0 && allow_move:
		snake[0].speed = {SQUARE_SIZE, 0}
		allow_move = false
	case rl.IsKeyPressed(.LEFT) && snake[0].speed.x == 0 && allow_move:
		snake[0].speed = {-SQUARE_SIZE, 0}
		allow_move = false
	case rl.IsKeyPressed(.UP) && snake[0].speed.y == 0 && allow_move:
		snake[0].speed = {0, -SQUARE_SIZE}
		allow_move = false
	case rl.IsKeyPressed(.DOWN) && snake[0].speed.y == 0 && allow_move:
		snake[0].speed = {0, SQUARE_SIZE}
		allow_move = false
	}
}

draw_game :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.RAYWHITE)
	if game_over {
		rl.DrawText(
			"PRESS [ENTER] TO PLAY AGAIN",
			rl.GetScreenWidth() / 2 - rl.MeasureText("PRESS [ENTER] TO PLAY AGAIN", 20) / 2,
			rl.GetScreenHeight() / 2 - 50,
			20,
			rl.GRAY,
		)
		return
	}


	for i := 0; i < SCREEN_WIDTH / SQUARE_SIZE + 1; i += 1 {
		start_pos := rl.Vector2{f32(SQUARE_SIZE * i) + offset.x / 2, offset.y / 2}
		end_pos := rl.Vector2{f32(SQUARE_SIZE * i) + offset.x / 2, SCREEN_HEIGHT - offset.y / 2}
		rl.DrawLineV(start_pos, end_pos, rl.LIGHTGRAY)
	}

	for i := 0; i < SCREEN_HEIGHT / SQUARE_SIZE + 1; i += 1 {
		start_pos := rl.Vector2{offset.x / 2, f32(SQUARE_SIZE * i) + offset.y / 2}
		end_pos := rl.Vector2{SCREEN_WIDTH - offset.x / 2, f32(SQUARE_SIZE * i) + offset.y / 2}
		rl.DrawLineV(start_pos, end_pos, rl.LIGHTGRAY)
	}

	// Draw snake
	for i := 0; i < counter_tail; i += 1 {
		rl.DrawRectangleV(snake[i].position, snake[i].size, snake[i].color)
	}
	// Draw fruit to pick
	rl.DrawRectangleV(fruit.position, fruit.size, fruit.color)
	if pause {
		rl.DrawText(
			"GAME PAUSED",
			SCREEN_WIDTH / 2 - rl.MeasureText("GAME PAUSED", 40) / 2,
			SCREEN_HEIGHT / 2 - 40,
			40,
			rl.GRAY,
		)
	}
}
