package main

import rl "vendor:raylib"

import "core:fmt"

BulletOwner :: enum{
    Player,
    Enemy,
}

Rifle :: struct{}
RifleDefault :: Rifle{}

Shotgun :: struct{
    lifetime: f32,
    lifetime_end: f32,
}
ShotgunDefault :: Shotgun{
    lifetime_end = 2.0,
    lifetime = 2.0
}

BulletType :: union{
    Rifle,
    Shotgun,
}

Bullet :: struct{
    pos: rl.Vector2,
    radius: f32,
    color: rl.Color,
    dir: rl.Vector2,
    speed: f32,
    owner: BulletOwner,

    bullet_type: BulletType,
    damage: int,
}


@(private="file")
BulletRifleSize :: 8.0
@(private="file")
BulletRifleSpeed :: 1200.0
bullet_rifle_add :: proc(bullets: ^[dynamic]Bullet, pos, dir: rl.Vector2, color: rl.Color, owner: BulletOwner){
    append(bullets, Bullet{
        pos = pos,
        dir = dir,
        color = color,
        radius = BulletRifleSize,
        speed = BulletRifleSpeed,
        owner = owner,
        bullet_type = RifleDefault,
        damage = 50,
    })
}

@(private="file")
ShotgunBulletCount :: 5
@(private="file")
ShotgunSpeed :: 2400.0 
bullet_shotgun_add :: proc(bullets: ^[dynamic]Bullet, pos, dir: rl.Vector2, color: rl.Color, owner: BulletOwner){
    for i in 0..<ShotgunBulletCount{
        b := Bullet{
            pos = pos,
            dir = rl.Vector2Rotate(dir, to_rad(-10.0 + f32(i) * 5.0)),
            color = color,
            radius = BulletRifleSize,
            speed = BulletRifleSpeed,
            owner = owner,
            bullet_type = ShotgunDefault,
            damage = 100,
        }
        append(bullets, b)
    }
}

bullet_update :: proc(b: ^Bullet){
    dt := delta_time()

    switch &s in b.bullet_type{
        case Rifle:
        case Shotgun:
            s.lifetime -= dt
            b.damage = int(f32(b.damage) * s.lifetime / s.lifetime_end)
    }
    b.pos += b.dir * b.speed * dt
}

bullet_render :: proc(b: Bullet){
    rl.DrawCircleV(b.pos, b.radius, b.color)
}