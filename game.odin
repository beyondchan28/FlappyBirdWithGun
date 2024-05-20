package game

import rl "vendor:raylib" 
import "core:c"
import "core:fmt"
import "core:math"

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

//TODO: Implement gun, bullet, and firing with limited ammo

window_height : c.int : 800
window_width : c.int : 600
obstacle_gap : c.int : 200
sub_block_size : int : 20


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
	half_dist: bool
}

obs_speed :: 200

all_obs : [dynamic][2]obstacle
all_sub_block : [dynamic][2][dynamic]sub_block
all_bullet : [dynamic]object

main :: proc() {

	setup()

	// main loop
	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLUE)

		// check_collision()  
		player_movement()
		firing()
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
	top_obs: obstacle = {top_obs_pos, top_obs_size, true}

	bot_obs_pos := rl.Vector2{f32(window_width), f32(window_height) - f32(obstacle_gap) - 100 }
	bot_obs_size := rl.Vector2{64, 300}
	bot_obs: obstacle = {bot_obs_pos, bot_obs_size, true}

	new_obs : [2]obstacle
	new_obs[0] = top_obs 
	new_obs[1] = bot_obs
	append(&all_obs, new_obs)


	//BUG: The first sub block color doesnt randomized
	sub_block_pair : [2][dynamic]sub_block
	sub_block_pair[0] = create_sub_block(top_obs)
	sub_block_pair[1] = create_sub_block(bot_obs)
	append(&all_sub_block, sub_block_pair)
	

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
		for &sub_block_pair in sub_block_arr {
			for &sub_block in sub_block_pair {
				rl.DrawRectangleV(sub_block.pos, sub_block.size, sub_block.col)
			}
		}
	}

	for &bullet in all_bullet {
		rl.DrawRectangleV(bullet.pos, bullet.size, rl.BLACK)
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
		}
	}
	for &sub_block_arr in all_sub_block {
		for &sub_block_pair in sub_block_arr {
			for &sub_block in sub_block_pair {
				sub_block.pos.x -= obs_speed * rl.GetFrameTime()
			}
		}
	}

	for &bullet in all_bullet {
		angle : f32 = math.atan2_f32(bullet.vel.x, bullet.vel.y)
		bullet.pos.x += 1000 * math.sin(angle) * rl.GetFrameTime()
		bullet.pos.y += 1000 * math.cos(angle) * rl.GetFrameTime()
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
			top_obs: obstacle = {top_pos, top_size, true}

			bot_pos := rl.Vector2{f32(window_width) - 10, f32(window_height) - f32(bot_y_size)}
			bot_size := rl.Vector2{64, f32(bot_y_size)}
			bot_obs: obstacle = {bot_pos, bot_size, true}
				
			new_obs: [2]obstacle = {top_obs, bot_obs}
			append(&all_obs, new_obs)
			sub_block_pair : [2][dynamic]sub_block
			sub_block_pair[0] = create_sub_block(top_obs)
			sub_block_pair[1] = create_sub_block(bot_obs)
			append(&all_sub_block, sub_block_pair)


			// fmt.println("spawn obs")
			// fmt.println("array length : ", len(all_obs)) 
		}

		if obs[0].pos.x < 0 - obs[0].size.x {
			pop_front(&all_obs)
			ordered_remove(&all_sub_block, 0)

			fmt.println("delete obs")
			fmt.println("all obs : ", len(all_obs))
			fmt.println("all sub block : ", len(all_sub_block))
		}
		
	}
}


create_sub_block :: proc(obs: obstacle) -> [dynamic]sub_block {
	result := int(obs.size.y) / sub_block_size 
	sub_block_arr := make([dynamic]sub_block)
	// fmt.println("y size : ", obs.size.y)
	// fmt.println("result : ", result)
	for i := 0; i < result; i += 1 {	
		block_pos : rl.Vector2
		block_pos = rl.Vector2{obs.pos.x, obs.pos.y + (obs.size.y / f32(result)) * (f32(i))}
		// fmt.println(block_pos.y)
		block_size := rl.Vector2{obs.size.x, obs.size.y / f32(result)}
		block_rect := rl.Rectangle{block_pos.x, block_pos.y, block_size.x, block_size.y}
		block_color := rl.Color{u8(rl.GetRandomValue(125, 255)), u8(rl.GetRandomValue(125, 255)), u8(rl.GetRandomValue(125, 255)), 255}
		sub_block : sub_block = {block_pos, block_size, block_rect, block_color}
		append(&sub_block_arr, sub_block)
	}

	return sub_block_arr

}

spawn_bullet :: proc(p_pos: rl.Vector2, target: rl.Vector2) {
	dist : rl.Vector2 = target - p_pos
	bullet := object {
		pos = p_pos,
		size = {32, 32},
		vel = dist,
		rect = {p_pos.x, p_pos.y, 32, 32}
	}

	append(&all_bullet, bullet)
}


firing :: proc() {
	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		spawn_bullet(player.pos, rl.GetMousePosition())
	}		
}

check_collision :: proc() {
	if player.pos.y > f32(window_height) {
		fmt.println("Out of frame")
	}


	// for &obs_arr in all_obs {
	// 	for &obs in obs_arr {
	// 		is_colliding : bool = rl.CheckCollisionRecs(player.rect, obs.rect)
	// 		if is_colliding {
	// 			fmt.println("collide")
	// 		} 
	// 	}
	// }
	for &bullet in all_bullet {
		if bullet.pos 
	}
}