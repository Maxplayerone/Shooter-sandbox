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

    hit_floor: bool,
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

}

player_render :: proc(p: Player){
    rl.DrawRectangleRec(player_rect(p), p.color)
}