package main

import rl "vendor:raylib"

import "core:strings"
import "core:fmt"
import "core:strconv"

uiid: int

get_uiid :: proc() -> int{
    uiid += 1
    return uiid
}

//GLOBALS
OutlineWidth :: 2.0
TextPadding :: 5.0
//window
WindowBarHeight :: 40.0
WindowColor :: rl.Color{45, 45, 45, 255}

button_color :: rl.Color{121, 122, 122, 255}
button_hot_color :: rl.Color{93, 94, 94, 255}
button_active_color :: rl.Color{30, 30, 30, 255}

scroll_bar_bg_color :: rl.Color{80, 80, 80, 255}

GuiState :: struct{
    hot_item: int,
    active_item: int,

    is_window_clicked: bool,
    resize_window: bool,
}

/*
rel_to_window :: proc(window_rect: rl.Rectangle, pos_percentage: rl.Vector2, scale_percentage: rl.Vector2) -> rl.Rectangle{
    rect := rl.Rectangle{}
    rect.x = window_rect.x + window_rect.width * pos_percentage.x
    rect.y = window_rect.y + window_rect.height * pos_percentage.y
    rect.width = window_rect.width * scale_percentage.x
    rect.height = window_rect.height * scale_percentage.y
    return rect
}
*/

get_outline_rect :: proc(rect: rl.Rectangle) -> rl.Rectangle{
    return rl.Rectangle{rect.x - OutlineWidth, rect.y - OutlineWidth, rect.width + 2 * OutlineWidth, rect.height + 2 * OutlineWidth} 
}

get_non_outline_rect :: proc(rect: rl.Rectangle) -> rl.Rectangle{
    return rl.Rectangle{rect.x + OutlineWidth, rect.y + OutlineWidth, rect.width - 2 * OutlineWidth, rect.height - 2 * OutlineWidth}
}

create_window_body_rect :: proc(rect: rl.Rectangle) -> rl.Rectangle{
    _, _, body := split_window_rect(rect)
    return body 
}

split_window_rect :: proc(rect: rl.Rectangle) -> (rl.Rectangle, rl.Rectangle, rl.Rectangle){
    rect_non_outline := get_non_outline_rect(rect)
    rect1 := rl.Rectangle{rect_non_outline.x, rect_non_outline.y, rect_non_outline.width, WindowBarHeight}
    rect2 := rl.Rectangle{rect_non_outline.x, rect_non_outline.y + WindowBarHeight, rect_non_outline.width, OutlineWidth}
    rect3 := rl.Rectangle{rect_non_outline.x, rect_non_outline.y + WindowBarHeight + OutlineWidth, rect_non_outline.width, rect_non_outline.height - WindowBarHeight - OutlineWidth}
    return rect1, rect2, rect3
}

gui_window :: proc(g_state: ^GuiState, rect: rl.Rectangle, title := "my window"){
    bar_rect, inbetween_outline, body_rect := split_window_rect(rect)
    //outlines
    rl.DrawRectangleRec(rect, rl.WHITE)
    rl.DrawRectangleRec(inbetween_outline, rl.WHITE)

    //bar
    rl.DrawRectangleRec(bar_rect, WindowColor)
    if scale, ok := fit_text_in_line(title, 25, rect.width / 2 - TextPadding); ok{
        rl.DrawText(strings.clone_to_cstring(title, context.temp_allocator), i32(bar_rect.x + TextPadding), i32(bar_rect.y + bar_rect.height / 4), i32(scale), rl.WHITE)
        
    }

    uiid := get_uiid()

    if rl.CheckCollisionPointRec(rl.GetMousePosition(), rect){
        g_state.hot_item = uiid

        if rl.IsMouseButtonDown(.LEFT){
            g_state.active_item = uiid
            g_state.is_window_clicked = true
        }
    }

    //resize invisible rect
    resize_rect_size := f32(12.0)
    resize_rect := rl.Rectangle{rect.x + rect.width - resize_rect_size, rect.y + rect.height - resize_rect_size, 2 * resize_rect_size, 2 * resize_rect_size}
    if rl.CheckCollisionPointRec(rl.GetMousePosition(), resize_rect){
        rl.SetMouseCursor(.RESIZE_NWSE)

        if rl.IsMouseButtonDown(.LEFT){
            g_state.resize_window = true  
            g_state.is_window_clicked = false
        }
    }
    else{
        rl.SetMouseCursor(.ARROW)
    }

    //body
    rl.DrawRectangleRec(body_rect, WindowColor)
}

/*
button :: proc(g_state: ^GuiState, rect: rl.Rectangle, title := "") -> bool{
    clicked: bool 

    outline_width:f32 = 2.0
    rl.DrawRectangleRec({rect.x - outline_width, rect.y - outline_width, rect.width + 2.0 * outline_width, rect.height + 2.0 * outline_width}, rl.WHITE)

    uiid := get_uiid()

    if rl.CheckCollisionPointRec(rl.GetMousePosition(), rect){
        g_state.hot_item = uiid 

        if rl.IsMouseButtonDown(.LEFT){
            g_state.is_window_clicked = false 
        }

        if rl.IsMouseButtonPressed(.LEFT){
            g_state.active_item = uiid 
            clicked = true
            g_state.last_active_item = uiid
        }
    }

    if g_state.hot_item == uiid{
        if g_state.active_item == uiid{
            rl.DrawRectangleRec(rect, button_active_color)
        }
        else{
            rl.DrawRectangleRec(rect, button_hot_color)
        }
    }
    else{
        rl.DrawRectangleRec(rect, button_color)
    }

    if title != ""{
        text_padding: f32 = 8.0
        if scale, ok := fit_text_in_line(title, 30, rect.width - 2.0 * text_padding); ok{
            rl.DrawText(strings.clone_to_cstring(title, context.temp_allocator), i32(rect.x + text_padding), i32(rect.y + rect.height / 4), i32(scale), rl.WHITE)
        }
    }

    return clicked
}


scroll_bar :: proc(g_state: ^GuiState, rect: rl.Rectangle, value: ^f32, min:f32 = 0.0, max: f32, fill_color := rl.WHITE){
    outline_width:f32 = 2.0
    rl.DrawRectangleRec({rect.x - outline_width, rect.y - outline_width, rect.width + 2.0 * outline_width, rect.height + 2.0 * outline_width}, rl.WHITE)

    rl.DrawRectangleRec(rect, scroll_bar_bg_color)

    fill_padding := f32(2.0)
    fill_rect := rl.Rectangle{rect.x + fill_padding, rect.y + fill_padding, rect.width - 2 * fill_padding, rect.height - 2 *fill_padding}

    uiid := get_uiid()

    if rl.CheckCollisionPointRec(rl.GetMousePosition(), rect){
        g_state.hot_item = uiid 

        if rl.IsMouseButtonDown(.LEFT){
            g_state.is_window_clicked = false 
            g_state.active_item = uiid
            g_state.last_active_item = uiid
        }

    }

    max_width := fill_rect.width
    fill_rect.width *= (value^)/max

    if g_state.active_item == uiid{
        fill_rect.width = rl.GetMousePosition().x - fill_rect.x
    }
    value^ = max * fill_rect.width / max_width

    if value^ < min{
        value^ = min
    }

    rl.DrawRectangleRec(fill_rect, fill_color)

}

display_active :: proc(g_state: ^GuiState, command:  ^[dynamic]rl.KeyboardKey, rect: rl.Rectangle, value: ^f32){
    outline_width := f32(2.0)
    outline_rect := get_outline_rect(rect, outline_width)
    rl.DrawRectangleRec(outline_rect, rl.WHITE)
    rl.DrawRectangleRec(rect, scroll_bar_bg_color)

    uiid := get_uiid()

    if rl.CheckCollisionPointRec(rl.GetMousePosition(), rect){
        g_state.hot_item = uiid 

        if rl.IsMouseButtonDown(.LEFT){
            g_state.is_window_clicked = false 
            g_state.last_active_item = uiid
        }

        if rl.IsMouseButtonPressed(.LEFT){
            g_state.active_item = uiid
        }
    }

    //getting the scroll bar value to string
    buf: [8]byte
    text_padding := f32(5.0)
    str := strconv.ftoa(buf[:], f64(value^), 'f', 2, 32)

    //pulling user input and possibly changing the string
    if key := rl.GetKeyPressed(); g_state.last_active_item == uiid && key != .KEY_NULL{
        if key == .BACKSPACE{
            if len(command) > 0{
                pop(command)
            }
        }
        else if key == .ENTER{
            g_state.last_active_item = 0
        }
        else{
            append(command, key)
        }
    }

    if len(command) != 0 && g_state.last_active_item == uiid{
        str = to_string_only_numbers(command^)
        value^ = f32(strconv.atof(str))
    }

    if scale, ok := fit_text_in_line(str, 30.0, rect.width - 2 * text_padding, min_scale = 5); ok{
        rl.DrawText(strings.clone_to_cstring(str, context.temp_allocator), i32(rect.x + text_padding), i32(rect.y + rect.height / 4), i32(scale), rl.WHITE)
    }

}

display :: proc(rect: rl.Rectangle, value: ^f32){
    outline_width := f32(2.0)
    outline_rect := get_outline_rect(rect, outline_width)
    rl.DrawRectangleRec(outline_rect, rl.WHITE)
    rl.DrawRectangleRec(rect, scroll_bar_bg_color)

    buf: [8]byte
    text_padding := f32(5.0)
    str := strconv.ftoa(buf[:], f64(value^), 'f', 2, 32)

    if scale, ok := fit_text_in_line(str, 30.0, rect.width - 2 * text_padding, min_scale = 5); ok{
        rl.DrawText(strings.clone_to_cstring(str, context.temp_allocator), i32(rect.x + text_padding), i32(rect.y + rect.height / 4), i32(scale), rl.WHITE)
    }
}

text :: proc(rect: rl.Rectangle, title: string){
    outline_width := f32(2.0)
    outline_rect := get_outline_rect(rect, outline_width)
    rl.DrawRectangleRec(outline_rect, rl.WHITE)
    rl.DrawRectangleRec(rect, scroll_bar_bg_color)

    text_padding := f32(5.0)
    if scale, ok := fit_text_in_line(title, 30.0, rect.width - 2 * text_padding, min_scale = 5); ok{
        rl.DrawText(strings.clone_to_cstring(title, context.temp_allocator), i32(rect.x + text_padding), i32(rect.y + rect.height / 4), i32(scale), rl.WHITE)
    }
}
    */