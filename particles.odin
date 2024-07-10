package main

import rl "vendor:raylib"

import "core:fmt"
import "core:math/rand"

Particle :: struct{
    pos: rl.Vector2,
    starting_pos: rl.Vector2,
    vel: rl.Vector2,
    starting_vel: rl.Vector2,

    //gravity specific
    is_gravity: bool,
    g: f32,

    color: rl.Color,
    lifetime: f32, //in seconds
    starting_lifetime: f32,

    size: f32,
    starting_size: f32,
}

GravityParticleConfig :: struct{
    base_dist: rl.Vector2,
    dist_offset: rl.Vector2,
    dist_offset_jump: f32,
    vel_offset: f32,
    vel_offset_jump: f32,
}

ParticleConfig :: struct{
    pos: rl.Vector2,
    vel: rl.Vector2,
    color: rl.Color,
    lifetime: f32,
    size: f32,
}

spawn_particle_gravity :: proc(gravity_config: GravityParticleConfig, config: ParticleConfig) -> Particle{
    p := Particle{}
    p.pos = config.pos
    p.starting_pos = config.pos
    p.vel.x = config.vel.x
    p.color = config.color
    p.lifetime = config.lifetime
    p.starting_lifetime = config.lifetime
    p.size = config.size
    p.starting_size = config.size

    if gravity_config.dist_offset_jump > gravity_config.dist_offset.x || gravity_config.dist_offset_jump > gravity_config.dist_offset.x || gravity_config.vel_offset_jump > gravity_config.vel_offset{
        assert(false, "jump offset has to be smaller than the offset")
    }

    dist := rl.Vector2{}
    sign: f32 = rand.int31() % 2 == 0 ? 1.0 : -1.0
    dist.x = f32(rand.int31() % i32(gravity_config.dist_offset.x / gravity_config.dist_offset_jump)) * gravity_config.dist_offset_jump * sign + gravity_config.base_dist.x
    dist.y = f32(rand.int31() % i32(gravity_config.dist_offset.y / gravity_config.dist_offset_jump)) * gravity_config.dist_offset_jump * sign + gravity_config.base_dist.y

    p.vel.x =  sign * (f32(rand.int31() % i32(gravity_config.vel_offset / gravity_config.vel_offset_jump)) * gravity_config.vel_offset_jump + config.vel.x)
    p.vel.y = get_ver_speed(dist, p.vel.x)
    p.g = get_gravity(dist, p.vel.x)
    p.is_gravity = true
    p.starting_vel = p.vel

    return p
}

ParticleInstancer :: struct{
    buf: [dynamic]Particle,
    time_btw_spawns: f32,
    start_time_btw_spawns: f32,
}

particle_inst_update :: proc(pi: ^ParticleInstancer, blocks: [dynamic]rl.Rectangle){
    for &p in pi.buf{
        particle_update(&p, blocks)
    }
}

particle_inst_render :: proc(pi: ParticleInstancer){
    for p in pi.buf{
        particle_render(p)
    }
}

particle_update :: proc(p: ^Particle, blocks: [dynamic]rl.Rectangle){
    dt := rl.GetFrameTime()
    p.lifetime -= dt

    if p.lifetime > 0.0{
        //position
        if p.is_gravity{
            new_y_pos :=  p.pos.y - (0.5 * p.g * dt * dt + p.vel.y * dt)
            if is_colliding, floor_y := floor_collission(blocks, new_y_pos, p.size); !is_colliding{

                p.pos.x += p.vel.x * dt

                p.pos.y = new_y_pos
                p.vel.y += p.g * dt
            }
            else{
                p.pos.y = floor_y
            }
        }
        else{
            p.pos += p.vel * dt
        }

        //other properties
        age_ratio := p.lifetime / p.starting_lifetime
        p.size = age_ratio * p.starting_size
        p.color.a = u8(255.0 * age_ratio)
    }
}

particle_render :: proc(p: Particle){
    if p.lifetime > 0.0{
        rl.DrawCircleV(p.pos, p.size, p.color)
    }
}