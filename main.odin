package main

import "core:fmt"
import "core:mem"
import "core:math/rand"

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
    //player.pos = rl.Vector2{Width / 2 - player.size / 2, Height / 2 - player.size / 2 + 100.0}
    player.pos = rl.Vector2{250.0, 200.0}
    player.color = rl.Color{125, 255, 207, 255}
    player.speed.x = 400.0

    jump_height:f32 = 200.0
    jump_dist: f32 = 150.0

    player.start_vert_speed = 2 * jump_height * player.speed.x / jump_dist
    player.g = - 2 * jump_height * (player.speed.x * player.speed.x) / (jump_dist * jump_dist)
    player.gravity_jumping = player.g
    player.gravity_landing = 2 * player.g

    rect := get_rect(player.pos, player.size)

    player_mo := move_outline_create(true, rl.Color{player.color.r, player.color.g, player.color.b, 200})

    bullets: [dynamic]Bullet

    blocks: [dynamic]rl.Rectangle
    append(&blocks, rl.Rectangle{0.0, Height - 100.0 + player.size, Width, 100.0})
    //append(&blocks, rl.Rectangle{200.0, 400.0, 100.0, 300.0})
    append(&blocks, rl.Rectangle{700.0, 300.0, 150.0, 50.0})

    enemies: [dynamic]Enemy
    {
        enemy := Enemy{
            pos = rl.Vector2{200.0, Height - 100.0},
            size = 40.0,
            color = rl.RED,
        }
        append(&enemies, enemy)
    }
    {
        enemy := Enemy{
            pos = rl.Vector2{300.0, Height - 100.0},
            size = 40.0,
            color = rl.RED,
        }
        append(&enemies, enemy)
    }

    gui_state := GuiState{}
    draw_rect := true
    rect_color := rl.GREEN

    for !rl.WindowShouldClose(){

        player_update(&player, &player_mo, &bullets, blocks, gui_state)

        for i in 0..<len(bullets){
            bullet_update(&bullets[i])
            for block in blocks{
                if rl.CheckCollisionCircleRec(bullets[i].pos, bullets[i].radius, block){
                    unordered_remove(&bullets, i)
                    break
                }
            }
        }

        for i in 0..<len(enemies){
            for j in 0..<len(bullets){
                if rl.CheckCollisionCircleRec(bullets[j].pos, bullets[j].radius, get_rect(enemies[i].pos, enemies[i].size)){
                    unordered_remove(&enemies, i)
                    unordered_remove(&bullets, j)
                    break
                }
            }
        }

        gui_state.hot_item = 0
        gui_state.active_item = 0

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        for enemy in enemies{
            enemy_render(enemy)
        }

        player_render(player)

        for bullet in bullets{
            bullet_render(bullet)
        }

        for block in blocks{
            rl.DrawRectangleRec(block, rl.WHITE)
        }

        if draw_rect{
            rl.DrawRectangleRec({Width - 200.0, Height - 200.0, 50.0, 50.0}, rect_color)
        }

        if button(&gui_state, rl.Rectangle{100.0, 100.0, 200.0, 50.0}){
            draw_rect = !draw_rect
        }
        if button(&gui_state, rl.Rectangle{100.0, 200.0, 200.0, 50.0}){
            rect_color.r = u8(rand.int31() % 255)
            rect_color.g = u8(rand.int31() % 255)
            rect_color.g = u8(rand.int31() % 255)
        }

        move_outline_render(player_mo)

        rl.EndDrawing()
    }
    delete(player_mo.buf)
    delete(player_mo.breakpoints)
    delete(bullets)
    delete(blocks)
    delete(enemies)

    rl.CloseWindow()

    for key, value in tracking_allocator.allocation_map{
        fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
    }
}