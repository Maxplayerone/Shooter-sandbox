package main

import "core:fmt"
import "core:mem"

import rl "vendor:raylib"

Width :: 960
Height :: 720

main :: proc(){
    tracking_allocator: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)

    rl.InitWindow(Width, Height, "game")
    rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.SetTargetFPS(60)

    player := Player{}
    player.size = 40.0
    player.pos = rl.Vector2{Width / 2 - player.size / 2, Height / 2 - player.size / 2 + 100.0}
    player.color = rl.Color{125, 255, 207, 255}
    player.speed.x = 400.0

    /*
    max_dist := rl.Vector2{100.0, 40.0}
    player.start_vert_speed = 2 * max_dist.y * player.speed.x / max_dist.x
    player.speed.y = player.start_vert_speed
    player.g = 2 * max_dist.y * player.speed.x * player.speed.x / (max_dist.x * max_dist.x)
    */

    jump_height:f32 = 200.0
    jump_time: f32 = 1.0
    starting_y := player.pos.y
    on_floor := true

    g := - 2 * jump_height / (jump_time * jump_time)
    v := 2 * jump_height / jump_time

    rect := get_rect(player.pos, player.size)

    for !rl.WindowShouldClose(){

        //player_update(&player)
        dt := rl.GetFrameTime()
        if rl.IsKeyPressed(.SPACE){
            on_floor = false
            v = 2 * jump_height / jump_time
        }

        if !on_floor{
            player.pos.y -= 0.5 * g * dt * dt + v * dt
            v += g * dt
        }

        if player.pos.y > starting_y{
            player.pos.y = starting_y
            on_floor = true
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        player_render(player)
        rl.DrawRectangleRec({rect.x - 150.0, rect.y + rect.height - jump_height, 50.0, jump_height}, rl.WHITE)

        rl.EndDrawing()
    }

    rl.CloseWindow()

    for key, value in tracking_allocator.allocation_map{
        fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
    }
}