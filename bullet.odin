package main

import rl "vendor:raylib"

Bullet :: struct{
    pos: rl.Vector2,
    radius: f32,
    color: rl.Color,
    dir: rl.Vector2,
    speed: f32,
}

bullet_update :: proc(b: ^Bullet){
    b.pos += b.dir * b.speed * rl.GetFrameTime()
}

bullet_render :: proc(b: Bullet){
    rl.DrawCircleV(b.pos, b.radius, b.color)
}