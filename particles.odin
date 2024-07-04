package main

import rl "vendor:raylib"

ParticleSize :: f32(10.0)

Particle :: struct{
    pos: rl.Vector2,
    vel: rl.Vector2,
    speed: f32,
    g: f32,

    color: rl.Color,
    lifetime: f32, //in seconds
}

particle_update :: proc(p: ^Particle){
    dt := rl.GetFrameTime()
    p.lifetime -= dt

    if p.lifetime > 0.0{
        p.pos.x += p.vel.x * p.speed * dt
    }
}

particle_render :: proc(p: Particle){
    if p.lifetime > 0.0{
        rl.DrawCircleV(p.pos, ParticleSize, p.color)
    }
}