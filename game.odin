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

//sub block design
/*
	obstacle's height modulo by 100, the result as the the amount of sub block.
	the size would be equal.
*/

window_height : c.int : 800
window_width : c.int : 600
obstacle_gap : c.int : 200

sub_block_color :[5]rl.Color = {rl.WHITE, rl.RED, rl.PINK, rl.PURPLE, rl.BROWN}

object :: struct {
	pos: rl.Vector2,
	size: rl.Vector2,
	vel: rl.Vector2,
	rect : rl.Rectangle
}

sub_block :: struct {
	pos: rl.Vector2,
	size: rl.Vector2,
	rect: rl.Rectangle,
	col: rl.Color
}

player : object
player_col := rl.GREEN

obstacle :: struct {
	pos: rl.Vector2,
	size: rl.Vector2,
	rect: rl.Rectangle,
	half_dist: bool
}

obs_speed :: 200

all_obs : [dynamic][2]obstacle
all_sub_block : [dynamic][dynamic]sub_block

main :: proc() {

	setup()

	// main loop
	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLUE)

		check_collision()  
		player_movement()
		object_movement()
		spawn_obs()
		draw()

		rl.EndDrawing()
	}

	rl.CloseWindow()
}

//setup before the game run
setup :: proc() {
	
	player.size= {64, 64}
	player.pos = {400 - 64, 300 - 64}

	top_obs_pos := rl.Vector2{f32(window_width), 0}
	top_obs_size := rl.Vector2{64, 300}
	top_obs_rect := rl.Rectangle{top_obs_pos.x, top_obs_pos.y, top_obs_size.x, top_obs_size.y}
	top_obs: obstacle = {top_obs_pos, top_obs_size, top_obs_rect, true}

	bot_obs_pos := rl.Vector2{f32(window_width), f32(window_height) - f32(obstacle_gap) - 100 }
	bot_obs_size := rl.Vector2{64, 300}
	bot_obs_rect := rl.Rectangle{bot_obs_pos.x, bot_obs_pos.y, bot_obs_size.x, bot_obs_size.y}
	bot_obs: obstacle = {bot_obs_pos, bot_obs_size, bot_obs_rect, true}

	new_obs : [2]obstacle
	new_obs[0] = top_obs 
	new_obs[1] = bot_obs

	// create_sub_block(top_obs)
	create_sub_block(bot_obs)

	append(&all_obs, new_obs)
	rl.InitWindow(window_width, window_height, "My First Game")	
	rl.SetTargetFPS(60)
}

draw :: proc() {
	for &obs_arr in all_obs {
		for obs in obs_arr {
			rl.DrawRectangleV(obs.pos, obs.size, rl.YELLOW)
		}
	}

	for &sub_block_arr in all_sub_block {
		for &sub_block in sub_block_arr {
			rl.DrawRectangleV(sub_block.pos, sub_block.size, sub_block.col)
		}
	}

	rl.DrawRectangleV(player.pos, player.size, player_col)
}

player_movement :: proc() {
	player.pos += player.vel * rl.GetFrameTime()

	if rl.IsKeyDown(.SPACE) {
		player.vel.y = -400
	}
	//gravity
	player.vel.y += 2000 * rl.GetFrameTime()
	player.rect = {player.pos.x, player.pos.y, player.size.x, player.size.y}
}


object_movement :: proc() {
	for &obs_arr in all_obs {
		for &obs in obs_arr {
			obs.pos.x -= obs_speed * rl.GetFrameTime()
			obs.rect = {obs.pos.x, obs.pos.y, obs.size.x, obs.size.y}
		}
	}
	for &sub_block_arr in all_sub_block {
		for &sub_block in sub_block_arr {
			sub_block.pos.x -= obs_speed * rl.GetFrameTime()
		}
	}
}

spawn_obs :: proc() {
	for &obs in all_obs {
		if obs[0].half_dist && obs[0].pos.x < f32(window_width)/2 {
			obs[0].half_dist = false

			top_y_size : c.int = rl.GetRandomValue(100, 600)
			bot_y_size : c.int = window_height - top_y_size - obstacle_gap
			
			top_pos := rl.Vector2{f32(window_width) - 10, 0}
			top_size := rl.Vector2{64, f32(top_y_size)}
			top_rect := rl.Rectangle{top_pos.x, top_pos.y, top_size.x, top_size.y}
			top_obs: obstacle = {top_pos, top_size, top_rect, true}

			bot_pos := rl.Vector2{f32(window_width) - 10, f32(window_height) - f32(bot_y_size)}
			bot_size := rl.Vector2{64, f32(bot_y_size)}
			bot_rect := rl.Rectangle{bot_pos.x, bot_pos.y, bot_size.x, bot_size.y}
			bot_obs: obstacle = {bot_pos, bot_size, bot_rect, true}
				
			new_obs: [2]obstacle = {top_obs, bot_obs}
			// create_sub_block(top_obs)
			// create_sub_block(bot_obs)

			append(&all_obs, new_obs)
			// fmt.println("spawn obs")
			// fmt.println("array length : ", len(all_obs)) 
		}

		if obs[0].pos.x < 0 - obs[0].size.x {
			pop_front(&all_obs)
			// delete_dynamic_array(all_sub_block[0])
			// pop_front(&all_sub_block)
			// fmt.println("delete obs")
		}
		
	}
}


create_sub_block :: proc(obs: obstacle) {
	result := int(obs.size.y) / 100
	fmt.println(result)
	sub_block_arr : [dynamic]sub_block
		for i := 0; i < result; i += 1 {
			block_pos : rl.Vector2
			if obs.pos.y == 0 {
				block_pos = rl.Vector2{obs.pos.x, obs.pos.y + (obs.size.y / f32(result)) * (f32(i))}
			} else {
				block_pos = rl.Vector2{obs.pos.x, obs.pos.y - (obs.size.y / f32(result)) * (f32(i))}
			}

			fmt.println(block_pos.y)
			block_size := rl.Vector2{obs.size.x, obs.size.y / f32(result)}
			block_rect := rl.Rectangle{block_pos.x, block_pos.y, block_size.x, block_size.y}
			block_color := sub_block_color[i]
			sub_block : sub_block = {block_pos, block_size, block_rect, block_color}
			append(&sub_block_arr, sub_block)
		}
	append(&all_sub_block, sub_block_arr)
	// fmt.println(len(all_sub_block))
}

check_collision :: proc() {
	if player.pos.y > f32(window_height) {
		fmt.println("Out of frame")
	}

	for &obs_arr in all_obs {
		for &obs in obs_arr {
			is_colliding : bool = rl.CheckCollisionRecs(player.rect, obs.rect)
			if is_colliding {
				fmt.println("collide")
			} 
		}
	}
}