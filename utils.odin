package main

import rl "vendor:raylib"

import "core:math"
import "core:strings"

get_rect :: proc(pos: rl.Vector2, size: f32) -> rl.Rectangle{
    return rl.Rectangle{pos.x, pos.y, size, size}
}

get_center :: proc(pos: rl.Vector2, size: f32) -> rl.Vector2{
    return rl.Vector2{pos.x + size / 2, pos.y + size / 2}
}

vec_norm :: proc(x: f32, y: f32) -> rl.Vector2{
    len := math.sqrt(x * x + y * y)
    return rl.Vector2{x / len, y / len}
}

to_rad :: proc(angle_deg: f32) -> f32{
    return angle_deg * math.PI/180.0
}

vec_rect_collission :: proc(vec: rl.Vector2, rect: rl.Rectangle) -> bool{
    return vec.x > rect.x && vec.x < rect.x + rect.width && vec.y > rect.y && vec.y < rect.y + rect.height
}

wall_collission :: proc(walls: [dynamic]rl.Rectangle, vec: rl.Vector2) -> bool{
    is_colliding: bool
    for wall in walls{
        if vec_rect_collission(vec, wall){
            is_colliding = true
            break
        }
    }
    return is_colliding
}

floor_collission :: proc(floors: [dynamic]rl.Rectangle, vec: rl.Vector2, size: f32, floor_depth:f32 = 30.0) -> (bool, f32){
    is_colliding: bool
    floor_y_pos: f32
    for floor in floors{
        if rl.CheckCollisionRecs({vec.x, vec.y + size + 1.0, size, 0.0}, floor){
            is_colliding = true
            floor_y_pos = floor.y
            break
        }
    }
    return is_colliding, floor_y_pos
}

ceiling_collission :: proc(ceilings: [dynamic]rl.Rectangle, rect: rl.Rectangle) -> (bool, f32){
    is_colliding: bool
    floor_y_with_size: f32
    for ceiling in ceilings{
        if rl.CheckCollisionRecs(ceiling, rect){
            is_colliding = true
            floor_y_with_size = ceiling.y + ceiling.height
            break
        }
    }
    return is_colliding, floor_y_with_size
}

@(private="file")
fit_text_in_line :: proc(text: string, scale: int, width: f32, min_scale := 15) -> int{
    text_cstring := strings.clone_to_cstring(text, context.temp_allocator)
    if f32(rl.MeasureText(text_cstring, i32(min_scale))) > width{
        return 1000
    }
    scale := scale
    for scale > min_scale{
        if f32(rl.MeasureText(text_cstring, i32(scale))) < width{
            break
        }
        scale -= 1
    }
    return scale
}

@(private="file")
fit_text_in_column :: proc(scale: int, height: f32, min_scale: f32 = 15) -> int{
    if f32(scale) < height{
        return scale
    }
    else if height >= min_scale{
        return int(height)
    }
    else{
        return 1000 
    }
}

fit_text_in_rect :: proc(text: string, dims: rl.Vector2, wanted_scale: int, min_scale: f32 = 15) -> int{
    scale_x := fit_text_in_line(text, wanted_scale, dims.x, int(min_scale))
    scale_y := fit_text_in_column(wanted_scale, dims.y, min_scale)

    if scale_x < scale_y && scale_y != 1000{
        return scale_x
    }
    else if scale_y < scale_x && scale_x != 1000{
        return scale_y
    }
    else if scale_x == scale_y && scale_x != 1000{
        return scale_x
    }
    else{
        return 0
    }
}

adjust_and_draw_text :: proc(text: string, rect: rl.Rectangle, padding: f32, wanted_scale: int, min_scale: f32 = 15){
    scale := fit_text_in_rect(text, {rect.width - 2 * padding, rect.height - 2 * padding}, wanted_scale)

    if scale != 0{
        rl.DrawText(strings.clone_to_cstring(text, context.temp_allocator), i32(rect.x + padding), i32(rect.y + padding), i32(scale), rl.WHITE)
    }
}

to_string_only_numbers :: proc(command: [dynamic]rl.KeyboardKey) -> string{
    b := strings.builder_make(context.temp_allocator)
    for c in command{
        if int(c) > 47 && int(c) < 58 || int(c) == 46{
            strings.write_rune(&b, rune(int(c)))
        }
    }
    return strings.to_string(b)
}

get_gravity :: proc(dist: rl.Vector2, hor_speed: f32) -> f32{
    hor_speed := math.abs(hor_speed)
    return -2.0 * dist.y * (hor_speed * hor_speed) / (dist.x * dist.x)
}

get_ver_speed :: proc(dist: rl.Vector2, hor_speed: f32) -> f32{
    hor_speed := math.abs(hor_speed)
    return 2.0 * dist.y * hor_speed / dist.x
}

split_rect_by_two :: proc(rect: rl.Rectangle, left_width:f32 = 0.5, padding: f32 = 0.0) -> (rl.Rectangle, rl.Rectangle){
    if left_width > 1.0 && left_width < 0.0{
        assert(false, "Error: left_width should be in a (0.0, 1.0) range")
    }

    left_rect := rect
    left_rect.width = rect.width * left_width

    right_rect := rect
    right_rect.width = rect.width * (1.0 - left_width) - padding
    right_rect.x += rect.width * left_width + padding

    return left_rect, right_rect
}