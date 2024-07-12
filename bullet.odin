package main

import rl "vendor:raylib"

BulletOwner :: enum{
    Player,
    Enemy,
}

Bullet :: struct{
    pos: rl.Vector2,
    radius: f32,
    color: rl.Color,
    dir: rl.Vector2,
    speed: f32,
    owner: BulletOwner,
}

bullet_update :: proc(b: ^Bullet){
    dt := delta_time()
    b.pos += b.dir * b.speed * dt
}

bullet_render :: proc(b: Bullet){
    rl.DrawCircleV(b.pos, b.radius, b.color)
}