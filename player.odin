package main

import rl "vendor:raylib"

import "core:fmt"
import "core:math"

WeaponType :: enum{
    Rifle,
    Shotgun,
}

Player :: struct{
    color: rl.Color,
    size: f32,

    pos: rl.Vector2,
    vel: rl.Vector2,
    start_vert_speed: f32,
    frame_displacement: rl.Vector2,

    g: f32,
    gravity_landing: f32,
    gravity_jumping: f32,

    deg: f32,

    weapon_type: WeaponType,
}

player_rect :: proc(p: Player) -> rl.Rectangle{
    return rl.Rectangle{p.pos.x, p.pos.y, p.size, p.size}
}

player_update :: proc(p: ^Player, mo: ^MoveOutline, bullets: ^[dynamic]Bullet, blocks: [dynamic]rl.Rectangle, gui_state: GuiState){
    dt := delta_time()

    move: rl.Vector2
    if rl.IsKeyDown(.D){
        move.x = p.vel.x * dt
    }
    if rl.IsKeyDown(.A){
        move.x = -p.vel.x * dt
    }
    if rl.IsKeyPressed(.SPACE){
        p.vel.y = p.start_vert_speed
    }
    move.y = -(0.5 * p.g * dt * dt + p.vel.y * dt)

    move = resolve_collisions(blocks, move, p.pos, p.size, &p.vel.y)

    p.pos += move
    p.vel.y += p.g * dt
    p.frame_displacement = move

    //getting the angle between player and mouse
    dx, dy : f32
    if dt != 0.0{
        mouse_pos := rl.GetMousePosition()
        dx = mouse_pos.x - p.pos.x
        dy = mouse_pos.y - p.pos.y
        p.deg = math.atan2(dy, dx) * (180.0 / 3.14) - 90.0
    }

    if rl.IsMouseButtonPressed(.LEFT) && gui_state.hot_item == 0{
        switch p.weapon_type{
            case .Rifle:
                bullet_rifle_add(bullets, get_center(p.pos, p.size), vec_norm(dx, dy), p.color, .Player)
            case .Shotgun:
                bullet_shotgun_add(bullets, get_center(p.pos, p.size), vec_norm(dx, dy), p.color, .Player)
        }
    }
}

player_render :: proc(p: Player){
    rl.DrawRectangleRec(player_rect(p), p.color)
    rl.DrawRectanglePro(rl.Rectangle{p.pos.x + p.size / 2, p.pos.y + p.size / 2, 5.0, 40.0}, {0.0, 0.0}, p.deg, rl.RED)
}