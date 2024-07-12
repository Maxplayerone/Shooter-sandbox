package main

import rl "vendor:raylib"

import "core:math/rand"
import "core:fmt"

@(private="file")
EnemySize :: 40
@(private="file")
EnemyVel := rl.Vector2{400.0, 0.0}
@(private="file")
EnemyG := get_gravity({150.0, 200.0}, EnemyVel.x)
@(private="file")
EnemyColorDamaged :: rl.Color{255, 161, 161, 255} 
@(private="file")
EnemyColor :: rl.RED
@(private="file")
EnemyDamagedFrameTime :: 5 
@(private="file")
StartTimeBtwStates :: 1.0

EnemyIdle :: struct{}
EnemyIdleDefault :: EnemyIdle{}

EnemyShooting :: struct{
    reload_time: f32,
    cur_time: f32,
    shots_fired: int,
    max_shots_fired: int,
}
EnemyShootingDefault :: EnemyShooting{
    reload_time = 1.0,
    cur_time = 1.0,
    max_shots_fired = 3,
}

EnemyMoving :: struct{
    max_move_dist: f32,
    move_dist: f32,
    min_dist_to_player: f32,
}
EnemyMovingDefault :: EnemyMoving{
    max_move_dist = 200.0,
    min_dist_to_player = 150.0,
}

EnemyJumping :: struct{
    jump_frames_before_floor_check: int
}
EnemyJumpingDefault :: EnemyJumping{
    jump_frames_before_floor_check = 5,
}

EnemyState :: union{
    EnemyIdle,
    EnemyShooting,
    EnemyMoving,
    EnemyJumping,
}

EnemyStates := [?]EnemyState{
    EnemyIdleDefault,
    EnemyShootingDefault,
    EnemyMovingDefault,
    EnemyJumpingDefault,
}

Enemy :: struct{
    pos: rl.Vector2,
    vel: rl.Vector2,
    g: f32,
    dir: rl.Vector2,

    size: f32,
    color: rl.Color,

    cur_state: EnemyState,
    time_btw_states: f32,

    health: int,
    cur_damaged_frame_time: int,
}

enemy_spawn :: proc(pos: rl.Vector2) -> Enemy{
    return Enemy{
        pos = pos,
        vel = EnemyVel,
        g = EnemyG,
        color = EnemyColor,
        size = EnemySize,
        time_btw_states = StartTimeBtwStates,
        cur_state = EnemyIdle{},
        health = 100,
    }
}

enemy_damaged :: proc(enemy: ^Enemy){
    enemy.cur_damaged_frame_time = EnemyDamagedFrameTime
}

enemy_update :: proc(e: ^Enemy, blocks: [dynamic]rl.Rectangle, player_pos: rl.Vector2, bullets: ^[dynamic]Bullet){
    dt := delta_time() 

    if e.cur_damaged_frame_time > 0{
        e.color = EnemyColorDamaged
        e.cur_damaged_frame_time -= 1
    }
    else{
        e.color = EnemyColor
    }

    //(NOTE) the state in cur_state isn't saved
    //for EnemyJumping state
    is_jumping := false
    switch &s in e.cur_state{
        case EnemyIdle:
            e.time_btw_states -= dt
            if e.time_btw_states < 0.0{
                idx := rand.int31() % (len(EnemyStates) -1) + 1
                e.cur_state = EnemyStates[idx]
                e.time_btw_states = StartTimeBtwStates
            }
        case EnemyJumping:
            if s.jump_frames_before_floor_check == 5{
                e.vel.y = get_ver_speed({150.0, 200.0}, EnemyVel.x)
                is_jumping = true
            }

            if s.jump_frames_before_floor_check > 0{
                e.pos.y -= 0.5 * e.g * dt * dt + e.vel.y * dt
                e.vel.y += e.g * dt
            }
            else{
                //idx := rand.int31() % len(EnemyStates)
                //e.cur_state = EnemyStates[idx]
                e.cur_state = EnemyStates[0]
            }

            s.jump_frames_before_floor_check -= 1
        case EnemyMoving:
            dist_to_player := player_pos.x - e.pos.x
            sign := dist_to_player > 0.0 ? 1.0 : -1.0
            e.pos.x += e.vel.x * dt * f32(sign)

            if abs(player_pos.x - e.pos.x) < s.min_dist_to_player{
                //idx := rand.int31() % len(EnemyStates)
                //e.cur_state = EnemyStates[idx]
                e.cur_state = EnemyStates[0]
            }

            s.move_dist += e.vel.x * dt * f32(sign)

            if abs(s.move_dist) > s.max_move_dist{
                //idx := rand.int31() % len(EnemyStates)
                //e.cur_state = EnemyStates[idx]
                e.cur_state = EnemyStates[0]
            }
        case EnemyShooting:
            s.cur_time += dt
            if s.cur_time >= s.reload_time{
                bullet := Bullet{
                    pos = get_center(e.pos, e.size),
                    radius = 8.0,
                    color = rl.WHITE,
                    dir = vec_norm(e.dir.x, e.dir.y),
                    speed = 1200.0,
                    owner = .Enemy,
                }
                append(bullets, bullet)

                s.cur_time = 0.0
                s.shots_fired += 1
            }

            //idx := rand.int31() % (len(EnemyStates) -1) + 1
            //e.cur_state = EnemyStates[idx]
            if s.shots_fired >= s.max_shots_fired{
                e.cur_state = EnemyStates[0]
            }
    }

    if is_colliding, floor_y := floor_collission(blocks, {e.pos.x, e.pos.y + e.size + 1.0}, e.size); is_colliding && !is_jumping{
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
    rl.DrawLineEx(get_center(e.pos, e.size), get_center(e.pos, e.size) + e.dir, 5.0, rl.ORANGE)
}