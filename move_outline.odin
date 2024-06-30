package main

import rl "vendor:raylib"

import "core:fmt"

MoveOutline :: struct{
    color: rl.Color,
    buf: [dynamic]rl.Vector2,
    breakpoints: [dynamic]int,
    only_draw_last_segment: bool,
}

move_outline_create :: proc(only_draw_last_segment := false, color := rl.WHITE) -> MoveOutline{
    return MoveOutline{
        color = color,
        buf = make([dynamic]rl.Vector2),
        breakpoints = make([dynamic]int),
        only_draw_last_segment = only_draw_last_segment,
    }
}

move_outline_record :: proc(mo: ^MoveOutline, pos: rl.Vector2){
    append(&mo.buf, pos)
}

move_outline_record_breakpoint :: proc(mo: ^MoveOutline){
    if len(mo.breakpoints) == 0 || mo.breakpoints[len(mo.breakpoints) - 1] != len(mo.buf) - 1{
        append(&mo.breakpoints, len(mo.buf) - 1)
    }
}

move_outline_render_breakpoints :: proc(mo: MoveOutline){
    for point in mo.breakpoints{
        rl.DrawCircleV(mo.buf[point], 5.0, rl.RED)
    }
}

move_outline_render :: proc(mo: MoveOutline){        
    last_point: int
    for point in mo.breakpoints{
        i := last_point
        for i < point - 1{
            if !mo.only_draw_last_segment{
                rl.DrawLineV(mo.buf[i], mo.buf[i + 1], mo.color)
            }

            i += 1
        }
        last_point = point + 1
    }

    for i in last_point..<len(mo.buf) - 1{
        rl.DrawLineV(mo.buf[i], mo.buf[i + 1], mo.color)
    }
}

