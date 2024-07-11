package main

import rl "vendor:raylib"

import "core:fmt"
import "core:math/rand"

Particle :: struct{
    pos: rl.Vector2,
    starting_pos: rl.Vector2,

    vel: rl.Vector2,
    starting_vel: rl.Vector2,
    modify_vel: bool,

    //gravity specific
    is_gravity: bool,
    g: f32,

    color: rl.Color,
    lifetime: f32, //in seconds
    starting_lifetime: f32,

    size: f32,
    starting_size: f32,
}

particle_reset :: proc(particle: ^Particle){
    particle.pos = particle.starting_pos
    particle.lifetime = particle.starting_lifetime
    particle.size = particle.starting_size
    particle.vel = particle.starting_vel
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
        if !p.is_gravity && p.modify_vel{
            p.vel = age_ratio * p.starting_vel
        }

        p.size = age_ratio * p.starting_size
        //p.color.a = u8(255.0 * age_ratio)
    }
}

particle_render :: proc(p: Particle){
    if p.lifetime > 0.0{
        rl.DrawCircleV(p.pos, p.size, p.color)
    }
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
    modify_vel: bool,
}

spawn_particle :: proc(config: ParticleConfig) -> Particle{
    p := Particle{}
    p.pos = config.pos
    p.starting_pos = config.pos

    p.vel = config.vel
    p.starting_vel = config.vel
    p.modify_vel = config.modify_vel

    p.is_gravity = false
    p.color = config.color
    p.lifetime = config.lifetime
    p.starting_lifetime = config.lifetime
    p.size = config.size
    p.starting_size = config.size
    return p
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

reset_particles :: proc(particles: ^[dynamic]Particle){
     for i in 0..<len(particles){
        particles[i].pos = particles[i].starting_pos
        particles[i].lifetime = particles[i].starting_lifetime
        particles[i].size = particles[i].starting_size
        particles[i].vel = particles[i].starting_vel
    }
}

InstanceSize :: 10

//for now only works for non-gravity particles
Emitter :: struct{
    buf: [InstanceSize]Particle,
    config: ParticleConfig,
    is_gravity: bool,
    gconfig: GravityParticleConfig,
    emittion_time: f32,
}

emitter_create :: proc(config: ParticleConfig, gconfig: GravityParticleConfig, emission_time: f32) -> Emitter{
    emitter: Emitter
    emitter.config = config
    if gconfig.base_dist.x != 0{
        emitter.gconfig = gconfig
    }
    emitter.emittion_time = emission_time

    for i in 0..<InstanceSize{
        rand_angle := f32(rand.int31() % 45)
        sign: f32 = rand.int31()  % 2 == 0 ? 1.0 : -1.0
        rand_angle *= sign
        emitter.config.vel = rl.Vector2Rotate(emitter.config.vel, to_rad(rand_angle) + f32(i) * 30.0)
        emitter.buf[i] = spawn_particle(emitter.config)
    }
    return emitter
}

//returns true if the emitter finished emitting
emitter_update :: proc(emitter: ^Emitter, blocks: [dynamic]rl.Rectangle) -> bool{
    for i in 0..<InstanceSize{
        particle_update(&emitter.buf[i], blocks)

        if emitter.buf[i].lifetime < 0.0{
            particle_reset(&emitter.buf[i])
        }
    }

    emitter.emittion_time -= rl.GetFrameTime()
    return emitter.emittion_time < 0.0
}

emitter_render :: proc(emitter: Emitter){
    for particle in emitter.buf{
        particle_render(particle)
    }
}

ParticleInstancer :: struct{
    buf: [dynamic]Particle,

    config: ParticleConfig,
    is_gravity: bool,
    gconfig: GravityParticleConfig,
}

instancer_add_instance :: proc(instancer: ^ParticleInstancer, pos: rl.Vector2){
    instancer.config.pos = pos
    if instancer.is_gravity{
        for i in 0..<InstanceSize{
            append(&instancer.buf, spawn_particle_gravity(instancer.gconfig, instancer.config))
        }
    }
    else{
        for i in 0..<InstanceSize{ 
            rand_angle := f32(rand.int31() % 45)
            sign: f32 = rand.int31()  % 2 == 0 ? 1.0 : -1.0
            rand_angle *= sign
            instancer.config.vel = rl.Vector2Rotate(instancer.config.vel, to_rad(rand_angle) + f32(i) * 30.0)
            append(&instancer.buf, spawn_particle(instancer.config))
        }
    }
}

particle_inst_update :: proc(pi: ^ParticleInstancer, blocks: [dynamic]rl.Rectangle){
    for &p, i in pi.buf{
        particle_update(&p, blocks)

        if p.lifetime <= 0{
            unordered_remove(&pi.buf, i)
        }
    }
}

particle_inst_render :: proc(pi: ParticleInstancer){
    for p in pi.buf{
        particle_render(p)
    }
}
