package main

import rl "vendor:raylib"

import "core:fmt"
import "core:math"

Player :: struct{
    color: rl.Color,
    size: f32,

    pos: rl.Vector2,
    speed: rl.Vector2,
    start_vert_speed: f32,

    g: f32,
    gravity_landing: f32,
    gravity_jumping: f32,

    deg: f32,

    jump_time_before_check: int,
}

player_rect :: proc(p: Player) -> rl.Rectangle{
    return rl.Rectangle{p.pos.x, p.pos.y, p.size, p.size}
}

player_update :: proc(p: ^Player, mo: ^MoveOutline, bullets: ^[dynamic]Bullet, blocks: [dynamic]rl.Rectangle){
    dt := rl.GetFrameTime()

    //horizontal movement
    if rl.IsKeyDown(.D){
        new_pos := p.pos.x + p.speed.x * dt

        if !wall_collission(blocks, {new_pos + p.size, p.pos.y}){
            p.pos.x = new_pos
        }
    }
    if rl.IsKeyDown(.A){
        new_pos := p.pos.x - p.speed.x * dt

        if !wall_collission(blocks, {new_pos, p.pos.y}){
            p.pos.x = new_pos
        }
    }

    new_y_pos := p.pos.y - 0.5 * p.g * dt * dt + p.speed.y * dt
    if is_colliding, new_y := ceiling_collission(blocks, {p.pos.x, new_y_pos, p.size, 0.0}); is_colliding{
        p.g = p.gravity_landing
        p.speed.y = 0.0
        p.pos.y = new_y 
    }

    //testing for collission with the floor
    if is_colliding, floor_y := floor_collission(blocks, {p.pos.x, p.pos.y + p.size + 1.0}, p.size); is_colliding && p.jump_time_before_check <= 0{
        p.pos.y = floor_y - p.size
        p.speed.y = 0 //we are treating every surface like it's elevated

        move_outline_record_breakpoint(mo)
    }
    else{
        p.pos.y -= 0.5 * p.g * dt * dt + p.speed.y * dt
        p.speed.y += p.g * dt

        if p.speed.y > 0{
            p.g = p.gravity_jumping
        }
        else{
            p.g = p.gravity_landing
        }

        move_outline_record(mo, get_center(p.pos, p.size))
    }

    if rl.IsKeyPressed(.SPACE){
        p.speed.y = p.start_vert_speed
        p.g = p.gravity_jumping

        p.pos.y -= 0.5 * p.g * dt * dt + p.speed.y * dt
        p.speed.y += p.g * dt

        p.jump_time_before_check = 5
    }

    p.jump_time_before_check -= 1

    //getting the angle between player and mouse
    mouse_pos := rl.GetMousePosition()
    dx := mouse_pos.x - p.pos.x
    dy := mouse_pos.y - p.pos.y
    p.deg = math.atan2(dy, dx) * (180.0 / 3.14) - 90.0

    if rl.IsMouseButtonPressed(.LEFT){
        bullet := Bullet{}
        bullet.pos = get_center(p.pos, p.size)
        bullet.radius = 8.0
        bullet.color = rl.WHITE
        bullet.dir = vec_norm(dx, dy)
        bullet.speed = 1200.0
        append(bullets, bullet)
    }
}

player_render :: proc(p: Player){
    rl.DrawRectangleRec(player_rect(p), p.color)
    rl.DrawRectanglePro(rl.Rectangle{p.pos.x + p.size / 2, p.pos.y + p.size / 2, 5.0, 40.0}, {0.0, 0.0}, p.deg, rl.RED)
}