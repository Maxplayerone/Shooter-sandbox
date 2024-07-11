package main

import rl "vendor:raylib"

Enemy :: struct{
    pos: rl.Vector2,
    vel: rl.Vector2,
    g: f32,

    size: f32,
    color: rl.Color,
}

enemy_update :: proc(e: ^Enemy, blocks: [dynamic]rl.Rectangle){
    dt := rl.GetFrameTime()

    if is_colliding, floor_y := floor_collission(blocks, {e.pos.x, e.pos.y + e.size + 1.0}, e.size); is_colliding{
        e.pos.y = floor_y - e.size
        e.vel.y = 0 //we are treating every surface like it's elevated
    }
    else{
        e.pos.y -= 0.5 * e.g * dt * dt + e.vel.y * dt
        e.vel.y += e.g * dt
    }
}

enemy_render :: proc(e: Enemy){
    rl.DrawRectangleV(e.pos, {e.size, e.size}, e.color)
}