package main

import rl "vendor:raylib"

Enemy :: struct{
    pos: rl.Vector2,
    size: f32,
    color: rl.Color,
}

enemy_render :: proc(e: Enemy){
    rl.DrawRectangleV(e.pos, {e.size, e.size}, e.color)
}