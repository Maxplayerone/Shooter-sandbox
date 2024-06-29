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

    jump_height:f32 = 200.0
    jump_dist: f32 = 150.0

    player.start_vert_speed = 2 * jump_height * player.speed.x / jump_dist
    player.g = - 2 * jump_height * (player.speed.x * player.speed.x) / (jump_dist * jump_dist)
    player.gravity_jumping = player.g
    player.gravity_landing = 2 * player.g

    rect := get_rect(player.pos, player.size)

    for !rl.WindowShouldClose(){

        player_update(&player)

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        player_render(player)
        rl.DrawRectangleRec({0.0, Height - 100.0 + player.size, Width, 100.0}, rl.WHITE)
        //rl.DrawRectangleRec({200.0, Height - 100.0 + player.size, 200 + jump_dist, 100.0}, rl.RED)
        //rl.DrawRectangleRec({200.0, Height - 100.0 + player.size - jump_height, 250.0, jump_height}, rl.RED)

        rl.EndDrawing()
    }

    rl.CloseWindow()

    for key, value in tracking_allocator.allocation_map{
        fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
    }
}