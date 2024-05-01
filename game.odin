package game

import rl "vendor:raylib" 
import "core:c"
import "core:fmt"

//create a flappy bird with guns
/*
	so the game is flappy bird but can destroy the bricks that
	blocking him. The gun has limited ammo and need to collect ammo to
	able to fire again.
*/

window_height : c.int : 800
window_width : c.int : 600


object :: struct {
	pos: rl.Vector2,
	size: rl.Vector2,
	vel: rl.Vector2,
	rect : rl.Rectangle
}

player : object
player_col := rl.GREEN

obstacle :: struct {
	pos: rl.Vector2,
	size: rl.Vector2,
	// rect: rl.Rectangle,
	half_dist: bool
}

obs_speed :: 200

all_obs : [dynamic][2]obstacle

main :: proc() {

	setup()

	// main loop
	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLUE)

		check_collision()  
		player_movement()
		spawn_obs()
		draw()

		rl.EndDrawing()
	}

	rl.CloseWindow()
}

//setup before the game run
setup :: proc() {
	
	player.size= {64, 64}
	player.pos = {400, 300}
	
	top_obs_pos := rl.Vector2{f32(window_width) - 10, 0}
	top_obs_size := rl.Vector2{64, 300}
	// top_obs_rect := rl.Rectangle{top_obs_pos.x, top_obs_pos.y, top_obs_size.x, top_obs_size.y}
	top_obs: obstacle = {top_obs_pos, top_obs_size, true}
	
	bot_obs_pos := rl.Vector2{f32(window_width) - 10, f32(window_height) - 300}
	bot_obs_size := rl.Vector2{64, 300}
	bot_obs: obstacle = {bot_obs_pos, bot_obs_size, true}

	new_obs : [2]obstacle
	new_obs[0] = top_obs 
	new_obs[1] = bot_obs

	append(&all_obs, new_obs)
	rl.InitWindow(window_width, window_height, "My First Game")	
	rl.SetTargetFPS(60)
}

draw :: proc() {
	rl.DrawRectangleV(player.pos, player.size, player_col)
	for &obs_arr in all_obs {
		for obs in obs_arr {
			rl.DrawRectangleV(obs.pos, obs.size, rl.YELLOW)
		}
	}
}

player_movement :: proc() {
	player.pos += player.vel * rl.GetFrameTime()

	if rl.IsKeyDown(.SPACE) {
		player.vel.y = -600
	}
	//gravity
	player.vel.y += 2000 * rl.GetFrameTime()

}


spawn_obs :: proc() {
	for &obs in all_obs {
		obs[0].pos.x -= obs_speed * rl.GetFrameTime()
		obs[1].pos.x -= obs_speed * rl.GetFrameTime()
		

		if obs[0].half_dist && obs[0].pos.x < f32(window_width)/2 {
			obs[0].half_dist = false

			top_y_size : c.int = rl.GetRandomValue(100, 600)
			bot_y_size : c.int = window_height - top_y_size - 200
			
			top_pos := rl.Vector2{f32(window_width) - 10, 0}
			top_size := rl.Vector2{64, f32(top_y_size)}
			// top_rect := rl.Rectangle{top_pos.x, top_pos.y, top_size.x, top_size.y}
			top_obs: obstacle = {top_pos, top_size, true}

			bot_pos := rl.Vector2{f32(window_width) - 10, f32(window_height) - f32(bot_y_size)}
			bot_size := rl.Vector2{64, f32(bot_y_size)}
			// bot_rect := rl.Rectangle{bot_pos.x, bot_pos.y, bot_size.x, bot_size.y}
			bot_obs: obstacle = {bot_pos, bot_size, true}
				
			new_obs: [2]obstacle
			new_obs[0] = top_obs
			new_obs[1] = bot_obs

			append(&all_obs, new_obs)
			// fmt.println("spawn obs")
			// fmt.println("array length : ", len(all_obs)) 
		}

		if obs[0].pos.x < 0 - obs[0].size.x {
			pop_front(&all_obs)
			// fmt.println("delete obs")
		}
	}
}

//TODO: its more optimize if not creating the rect every frame but just pointing it
check_collision :: proc() {
	player.rect = {player.pos.x, player.pos.y, player.size.x, player.size.y}
	for &obs_arr in all_obs {
		for &obs in obs_arr {
			obs_rect := rl.Rectangle{obs.pos.x, obs.pos.y, obs.size.x, obs.size.y}
			is_colliding : bool = rl.CheckCollisionRecs(player.rect, obs_rect)
			if is_colliding {
				player_col = rl.RED
				// fmt.println("collide")
			} else {
				player_col = rl.GREEN
			}
		}
	}
}