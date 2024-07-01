package main

import rl "vendor:raylib"

uiid: int

get_uiid :: proc() -> int{
    uiid += 1
    return uiid
}

button_color :: rl.Color{121, 122, 122, 255}
button_hot_color :: rl.Color{93, 94, 94, 255}
button_active_color :: rl.Color{30, 30, 30, 255}

GuiState :: struct{
    hot_item: int,
    active_item: int,
}

button :: proc(g_state: ^GuiState, rect: rl.Rectangle) -> bool{
    clicked: bool 

    outline_width:f32 = 2.0
    rl.DrawRectangleRec({rect.x - outline_width, rect.y - outline_width, rect.width + 2.0 * outline_width, rect.height + 2.0 * outline_width}, rl.WHITE)

    uiid := get_uiid()

    if rl.CheckCollisionPointRec(rl.GetMousePosition(), rect){
        g_state.hot_item = uiid 

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

    return clicked
}