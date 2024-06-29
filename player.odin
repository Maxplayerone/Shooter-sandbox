package main

import rl "vendor:raylib"

import "core:fmt"

Player :: struct{
    color: rl.Color,
    size: f32,

    pos: rl.Vector2,
    speed: rl.Vector2,
    start_vert_speed: f32,

    g: f32,
    gravity_landing: f32,
    gravity_jumping: f32,

    on_floor: bool,
}

player_rect :: proc(p: Player) -> rl.Rectangle{
    return rl.Rectangle{p.pos.x, p.pos.y, p.size, p.size}
}

player_update :: proc(p: ^Player){
    dt := rl.GetFrameTime()

    if rl.IsKeyDown(.D){
        p.pos.x += p.speed.x * dt
    }
    if rl.IsKeyDown(.A){
        p.pos.x -= p.speed.x * dt
    }

    if rl.IsKeyPressed(.SPACE){
        p.on_floor = false
        p.speed.y = p.start_vert_speed
        p.g = p.gravity_jumping
    }

    if !p.on_floor{
        p.pos.y -= 0.5 * p.g * dt * dt + p.speed.y * dt
        p.speed.y += p.g * dt

        if p.speed.y > 0{
            p.g = p.gravity_jumping
        }
        else{
            p.g = p.gravity_landing
        }
    }

    if p.pos.y > Height - 100.0{
        p.pos.y = Height - 100.0
        p.on_floor = true
    }
}

player_render :: proc(p: Player){
    rl.DrawRectangleRec(player_rect(p), p.color)
}