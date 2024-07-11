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
    append(&blocks, rl.Rectangle{700.0, 300.0, 150.0, 50.0})

    EnemySize :: 40
    EnemiesMinLen :: 3
    EnemyVel := rl.Vector2{player.speed.x, 0.0}
    EnemyG := get_gravity({jump_dist, jump_height}, player.speed.x)
    enemies: [dynamic]Enemy
    {
        enemy := Enemy{
            pos = rl.Vector2{200.0, Height - 100.0},
            size = EnemySize,
            color = rl.RED,
            vel = EnemyVel,
            g = EnemyG,
        }
        append(&enemies, enemy)
    }
    {
        enemy := Enemy{
            pos = rl.Vector2{300.0, Height - 100.0},
            size = EnemySize,
            color = rl.RED,
            vel = EnemyVel,
            g = EnemyG,
        }
        append(&enemies, enemy)
    }

    gui_state := GuiState{}
    window_rect := rl.Rectangle{11, 10, 427, 621}
    gui_rects := generate_rects_for_window(window_rect, 5)
    command: [dynamic]rl.KeyboardKey

    particles: [dynamic]Particle


    enemy_death_config := ParticleConfig{}
    enemy_death_config.pos = rl.Vector2{700.0, 590.0}
    enemy_death_config.vel = rl.Vector2{300.0, 0.0}
    enemy_death_config.color = rl.RED 
    enemy_death_config.lifetime = 2.0
    enemy_death_config.size = 10.0
    enemy_death_config.is_gravity = true
    enemy_death_config.base_dist = {42.0, 50.0}
    enemy_death_config.dist_offset = {45.0, 45.0}
    enemy_death_config.dist_offset_jump = 13.0
    enemy_death_config.vel_offset = 50.0
    enemy_death_config.vel_offset_jump = 5.0


    enemy_spawn_config := ParticleConfig{}
    enemy_spawn_config.pos = {700.0, 590.0}
    enemy_spawn_config.vel = {50.0, 0.0}
    enemy_spawn_config.modify_vel = true
    enemy_spawn_config.color = rl.Color{255, 0, 0, 125}
    enemy_spawn_config.lifetime = 1.6
    enemy_spawn_config.size = 16.0

    emitter_buf: [dynamic]Emitter

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
            enemy_update(&enemies[i], blocks, player.pos)

            //deleting enemies if colliding with bullets
            for j in 0..<len(bullets){
                if rl.CheckCollisionCircleRec(bullets[j].pos, bullets[j].radius, get_rect(enemies[i].pos, enemies[i].size)){
                    enemy_death_config.pos = enemies[i].pos
                    append(&emitter_buf, emitter_create(enemy_death_config, enemy_death_config.lifetime, .DoNothing))

                    //enemy spawn particle emitter
                    enemy_spawn_config.pos = find_random_unoccupied_pos(blocks, enemies, player)
                    append(&emitter_buf, emitter_create(enemy_spawn_config, enemy_spawn_config.lifetime * 0.6, .SpawnEnemy))

                    unordered_remove(&enemies, i)
                    unordered_remove(&bullets, j)
                    break
                }
            }
        }

        //particles update
        for &emitter, i in emitter_buf{
            emitter_effect := emitter_update(&emitter, blocks)
            switch emitter_effect{
                case .DoNothingNoRemove: 
                case .DoNothing:
                    unordered_remove(&emitter_buf, i)
                case .SpawnEnemy:
                    e := Enemy{
                        pos = emitter.config.pos,
                        size = EnemySize,
                        g = EnemyG,
                        vel = EnemyVel,
                        color = rl.RED,
                    }
                    append(&enemies, e)
                    unordered_remove(&emitter_buf, i)
            }
        }

        //debug------------------------------------------------------
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
        for emitter in emitter_buf{
            emitter_render(emitter)
        }
        //particle_inst_render(enemy_spawn_effect)

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
    delete(gui_rects)
    delete(emitter_buf)

    rl.CloseWindow()

    for key, value in tracking_allocator.allocation_map{
        fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
    }
}