package main

import rl "vendor:raylib"

get_rect :: proc(pos: rl.Vector2, size: f32,) -> rl.Rectangle{
    return rl.Rectangle{pos.x, pos.y, size, size}
}