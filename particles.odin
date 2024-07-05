package main

import rl "vendor:raylib"

import "core:fmt"

ParticleSize :: f32(10.0)

Particle :: struct{
    pos: rl.Vector2,
    vel: rl.Vector2,
    g: f32,
    dist: rl.Vector2,

    color: rl.Color,
    lifetime: f32, //in seconds
}

particle_update :: proc(p: ^Particle, blocks: [dynamic]rl.Rectangle){
    dt := rl.GetFrameTime()
    p.lifetime -= dt

    if p.lifetime > 0.0{

        new_y_pos :=  p.pos.y - (0.5 * p.g * dt * dt + p.vel.y * dt)
        if is_colliding, floor_y := floor_collission(blocks, new_y_pos, ParticleSize); !is_colliding{

            p.pos.x += p.vel.x * dt

            p.pos.y = new_y_pos
            p.vel.y += p.g * dt
        }
        else{
            p.pos.y = floor_y
        }
    }
}

particle_render :: proc(p: Particle){
    if p.lifetime > 0.0{
        rl.DrawCircleV(p.pos, ParticleSize, p.color)
    }
}