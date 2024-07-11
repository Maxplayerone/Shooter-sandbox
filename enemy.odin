package main

import rl "vendor:raylib"

Enemy :: struct{
    pos: rl.Vector2,
    vel: rl.Vector2,
    g: f32,

    size: f32,
    color: rl.Color,

    dir: rl.Vector2,
}


enemy_update :: proc(e: ^Enemy, blocks: [dynamic]rl.Rectangle, player_pos: rl.Vector2){
    dt := rl.GetFrameTime()

    if is_colliding, floor_y := floor_collission(blocks, {e.pos.x, e.pos.y + e.size + 1.0}, e.size); is_colliding{
        e.pos.y = floor_y - e.size
        e.vel.y = 0 //we are treating every surface like it's elevated
    }
    else{
        e.pos.y -= 0.5 * e.g * dt * dt + e.vel.y * dt
        e.vel.y += e.g * dt
    }

    e.dir = rl.Vector2Normalize(player_pos - e.pos) * 50.0
}

enemy_render :: proc(e: Enemy){
    rl.DrawRectangleV(e.pos, {e.size, e.size}, e.color)
    enemy_mid := rl.Vector2{e.pos.x + e.size / 2, e.pos.y + e.size / 2}
    rl.DrawLineEx(enemy_mid, enemy_mid + e.dir, 5.0, rl.ORANGE)
}