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
    player.pos = rl.Vector2{750.0, 260.0}
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
    window_rect := rl.Rectangle{11, 10, 427, 621}
    gui_rects := generate_rects_for_window(window_rect, 5)
    command: [dynamic]rl.KeyboardKey

    particles: [dynamic]Particle

    config := ParticleConfig{}
    config.pos = rl.Vector2{700.0, 590.0}
    config.vel = rl.Vector2{300.0, 0.0}
    config.color = rl.RED 
    config.lifetime = 2.0
    config.size = 10.0

    g_config := GravityParticleConfig{}
    g_config.base_dist = {42.0, 50.0}
    g_config.dist_offset = {45.0, 45.0}
    g_config.dist_offset_jump = 13.0
    g_config.vel_offset = 50.0
    g_config.vel_offset_jump = 5.0

    enemy_death_effect := ParticleInstancer{}

    config2 := ParticleConfig{}
    config2.pos = {700.0, 590.0}
    config2.vel = {50.0, 0.0}
    config2.color = rl.Color{255, 0, 0, 125}
    config2.lifetime = 1.6
    config2.size = 16.0
    config2.modify_vel = true
    p := spawn_particle(config2)

    enemy_spawn_effect := ParticleInstancer{}

    for !rl.WindowShouldClose(){

        //player update
        player_update(&player, &player_mo, &bullets, blocks, gui_state)

        //bullets update
        for i in 0..<len(bullets){
            bullet_update(&bullets[i])
            for block in blocks{
                if rl.CheckCollisionCircleRec(bullets[i].pos, bullets[i].radius, block){
                    unordered_remove(&bullets, i)
                    break
                }
            }
        }

        //enemies update
        for i in 0..<len(enemies){
            for j in 0..<len(bullets){
                if rl.CheckCollisionCircleRec(bullets[j].pos, bullets[j].radius, get_rect(enemies[i].pos, enemies[i].size)){

                    config.pos = enemies[i].pos
                    for i in 0..<10{
                        append(&enemy_death_effect.buf, spawn_particle_gravity(g_config, config))
                    }
                    //spawn particles
                    unordered_remove(&enemies, i)
                    unordered_remove(&bullets, j)
                    break
                }
            }
        }

        //particles update
        particle_inst_update(&enemy_death_effect, blocks)
        particle_inst_update(&enemy_spawn_effect, blocks)

        //debug------------------------------------------------------
        if rl.IsKeyPressed(.U){
            for i in 0..<10{ 
                rand_angle := f32(rand.int31() % 45)
                sign: f32 = rand.int31()  % 2 == 0 ? 1.0 : -1.0
                rand_angle *= sign
                config2.vel = rl.Vector2Rotate(config2.vel, to_rad(rand_angle) + f32(i) * 30.0)
                append(&enemy_spawn_effect.buf, spawn_particle(config2))
            }
        }
        if rl.IsKeyPressed(.I){
            reset_gravity_particles(&enemy_death_effect.buf)
        }
        if rl.IsKeyPressed(.O){
            player_mo.only_draw_last_segment = !player_mo.only_draw_last_segment
        }
        if rl.IsKeyPressed(.P){
            clear(&player_mo.breakpoints)
            clear(&player_mo.buf)
        }
        //-----------------------------------------------------------

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        //enemies
        for enemy in enemies{
            enemy_render(enemy)
        }

        //player
        player_render(player)

        //bullet
        for bullet in bullets{
            bullet_render(bullet)
        }

        //obstacles
        for block in blocks{
            rl.DrawRectangleRec(block, rl.WHITE)
        }

        //particle
        particle_inst_render(enemy_death_effect)
        particle_inst_render(enemy_spawn_effect)

        //move outlines
        move_outline_render(player_mo)

        //gui
        rl.DrawFPS(0, 0)

        rl.EndDrawing()

        free_all(context.temp_allocator)
    }
    delete(player_mo.buf)
    delete(player_mo.breakpoints)
    delete(bullets)
    delete(blocks)
    delete(enemies)
    //delete(command)
    delete(particles)
    delete(enemy_death_effect.buf)
    delete(enemy_spawn_effect.buf)
    delete(gui_rects)

    rl.CloseWindow()

    for key, value in tracking_allocator.allocation_map{
        fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
    }
}