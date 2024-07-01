package main

import rl "vendor:raylib"

import "core:strings"
import "core:fmt"

uiid: int

get_uiid :: proc() -> int{
    uiid += 1
    return uiid
}

button_color :: rl.Color{121, 122, 122, 255}
button_hot_color :: rl.Color{93, 94, 94, 255}
button_active_color :: rl.Color{30, 30, 30, 255}

window_color :: rl.Color{45, 45, 45, 255}

GuiState :: struct{
    hot_item: int,
    active_item: int,
    is_window_clicked: bool,
}

rel_to_window :: proc(window_rect: rl.Rectangle, pos_percentage: rl.Vector2, scale_percentage: rl.Vector2) -> rl.Rectangle{
    rect := rl.Rectangle{}
    rect.x = window_rect.x + window_rect.width * pos_percentage.x
    rect.y = window_rect.y + window_rect.height * pos_percentage.y
    rect.width = window_rect.width * scale_percentage.x
    rect.height = window_rect.height * scale_percentage.y
    return rect
}

window :: proc(g_state: ^GuiState, rect: rl.Rectangle, bar_height: f32, title := "my window"){
    //outline
    outline_width:f32 = 2.0
    rl.DrawRectangleRec({rect.x - outline_width, rect.y - outline_width - bar_height, rect.width + 2.0 * outline_width, (rect.height + bar_height) + 2.0 * outline_width}, rl.WHITE)

    //bar
    bar_rect := rl.Rectangle{rect.x, rect.y - bar_height, rect.width, bar_height}
    rl.DrawRectangleRec(bar_rect, window_color)
    text_padding := f32(5.0)
    if scale, ok := fit_text_in_line(title, 25, rect.width / 2 - text_padding); ok{
        rl.DrawText(strings.clone_to_cstring(title, context.temp_allocator), i32(bar_rect.x + text_padding), i32(bar_rect.y + bar_rect.height / 4), i32(scale), rl.WHITE)
        
    }

    uiid := get_uiid()
    full_rect := rl.Rectangle{rect.x, rect.y - bar_height, rect.width, rect.height + bar_height}

    if rl.CheckCollisionPointRec(rl.GetMousePosition(), full_rect){
        g_state.hot_item = uiid
        if rl.IsMouseButtonDown(.LEFT){
            g_state.active_item = uiid
            g_state.is_window_clicked = true
        }
    }

    //main window
    rl.DrawRectangleRec(rect, window_color)

    //outline between bar and main window
    rl.DrawLineEx({rect.x, rect.y}, {rect.x + rect.width, rect.y}, 2.0, rl.WHITE)
}
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