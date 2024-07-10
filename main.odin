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
    draw_rect := true
    rect_color := rl.GREEN

    window_rect := rl.Rectangle{50.0, 50.0, 300.0, 400.0}

    show_gui := true 

    command: [dynamic]rl.KeyboardKey


    particles: [dynamic]Particle
    StartingPos := rl.Vector2{480.0, 590.0}
    time_btw_spawns := f32(0.3)
    start_time_btw_spawns := time_btw_spawns

    config := ParticleConfig{}
    config.pos = rl.Vector2{480.0, 590.0}
    config.vel = rl.Vector2{400.0, 0.0}
    config.color = rl.RED 
    config.lifetime = 2.0
    config.size = 10.0
    config.shape = .Circle

    g_config := GravityParticleConfig{}
    g_config.base_dist = {100.0, 50.0}
    g_config.dist_offset = {50.0, 10.0}
    g_config.dist_offset_jump = 10.0
    g_config.vel_offset = 50.0
    g_config.vel_offset_jump = 5.0

    enemy_death_effect := ParticleInstancer{}

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

        particle_inst_update(&enemy_death_effect, blocks)

        gui_state.hot_item = 0
        gui_state.active_item = 0
        uiid = 0

        //debug------------------------------------------------------
        if rl.IsKeyPressed(.I){
            show_gui = !show_gui
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

        particle_inst_render(enemy_death_effect)

        if show_gui{
            window(&gui_state, window_rect, 40.0, "particle system")

            if button(&gui_state, rel_to_window(window_rect, {0.1, 0.07}, {0.3, 0.08}), "reset"){
                /*
                for i in 0..<len(particles){
                    particles[i].pos = StartingPos
                    if particles[i].is_gravity{
                        particles[i].vel.y = get_ver_speed(particles[i].dist, particles[i].vel.x)
                    }
                    particles[i].lifetime = 2.0
                }
                    */
            }

            if button(&gui_state, rel_to_window(window_rect, {0.1, 0.2}, {0.4, 0.1}), "spawn particle"){
                append(&enemy_death_effect.buf, spawn_particle_gravity(g_config, config))
            }

            if button(&gui_state, rel_to_window(window_rect, {0.1, 0.35}, {0.4, 0.1}), "spawn 10"){
                for i in 0..<10{
                    append(&enemy_death_effect.buf, spawn_particle_gravity(g_config, config))
                }
            }

            //text(rel_to_window(window_rect, {0.1, 0.18}, {0.3, 0.08}), "min velocity")
            //scroll_bar(&gui_state, rel_to_window(window_rect, {0.1, 0.25}, {0.3, 0.08}), &angle, max = 90.0)
            //display_active(&gui_state, &command, rel_to_window(window_rect, {0.5, 0.25}, {0.2, 0.05}), &angle)

            if gui_state.resize_window{
                window_rect.width += rl.GetMouseDelta().x
                window_rect.height += rl.GetMouseDelta().y
                gui_state.resize_window = false
                gui_state.is_window_clicked = false
            }

            if gui_state.is_window_clicked{
                window_rect.x += rl.GetMouseDelta().x
                window_rect.y += rl.GetMouseDelta().y
                gui_state.is_window_clicked = false
            }
        }

        move_outline_render(player_mo)

        rl.EndDrawing()

        free_all(context.temp_allocator)
    }
    delete(player_mo.buf)
    delete(player_mo.breakpoints)
    delete(bullets)
    delete(blocks)
    delete(enemies)
    delete(command)
    delete(particles)
    delete(enemy_death_effect.buf)

    rl.CloseWindow()

    for key, value in tracking_allocator.allocation_map{
        fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
    }
}