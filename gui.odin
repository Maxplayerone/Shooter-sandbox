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
ItemPadding :: 10.0

//window
WindowBarHeight :: 40.0
WindowColor :: rl.Color{45, 45, 45, 255}

//button
ButtonColor :: rl.Color{121, 122, 122, 255}
ButtonHotColor :: rl.Color{93, 94, 94, 255}
ButtonActiveColor :: rl.Color{30, 30, 30, 255}

scroll_bar_bg_color :: rl.Color{80, 80, 80, 255}

GuiState :: struct{
    hot_item: int,
    active_item: int,
    active_item_non_reset: int,

    is_window_clicked: bool,
    resize_window: bool,
}

get_non_outline_rect :: proc(rect: rl.Rectangle, outline: f32 = OutlineWidth) -> rl.Rectangle{
    return rl.Rectangle{rect.x + outline, rect.y + outline, rect.width - 2 * outline, rect.height - 2 * outline}
}

split_window_rect :: proc(rect: rl.Rectangle) -> (rl.Rectangle, rl.Rectangle, rl.Rectangle){
    rect_non_outline := get_non_outline_rect(rect)
    rect1 := rl.Rectangle{rect_non_outline.x, rect_non_outline.y, rect_non_outline.width, WindowBarHeight}
    rect2 := rl.Rectangle{rect_non_outline.x, rect_non_outline.y + WindowBarHeight, rect_non_outline.width, OutlineWidth}
    rect3 := rl.Rectangle{rect_non_outline.x, rect_non_outline.y + WindowBarHeight + OutlineWidth, rect_non_outline.width, rect_non_outline.height - WindowBarHeight - OutlineWidth}
    return rect1, rect2, rect3
}

generate_rects_for_window :: proc(window_rect: rl.Rectangle, items_count: f32) -> [dynamic]rl.Rectangle{
    items: [dynamic]rl.Rectangle
    _, _, body_rect := split_window_rect(window_rect)

    height := (body_rect.height - items_count * ItemPadding) / items_count

    body_rect.y += ItemPadding
    for i in 0..<items_count{
        item_rect: rl.Rectangle
        item_rect.x = body_rect.x + ItemPadding
        item_rect.y = body_rect.y + (ItemPadding + height) * f32(i)
        item_rect.width = body_rect.width - 2 * ItemPadding 
        item_rect.height = height 
        append(&items, item_rect)
    }
    return items
}

regenerate_rects_for_window :: proc(window_rect: rl.Rectangle, rects: ^[dynamic]rl.Rectangle){
    _, _, body_rect := split_window_rect(window_rect)

    count := len(rects)
    height := (body_rect.height - f32(count) * ItemPadding) / f32(count)
    body_rect.y += ItemPadding
    for i in 0..<count{
        item_rect: rl.Rectangle
        item_rect.x = body_rect.x + ItemPadding
        item_rect.y = body_rect.y + (ItemPadding + height) * f32(i)
        item_rect.width = body_rect.width - 2 * ItemPadding 
        item_rect.height = height 
        rects[i] = item_rect
    }
}

gui_window :: proc(g_state: ^GuiState, rect: rl.Rectangle, title := "my window"){
    bar_rect, inbetween_outline, body_rect := split_window_rect(rect)
    //outlines
    rl.DrawRectangleRec(rect, rl.WHITE)
    rl.DrawRectangleRec(inbetween_outline, rl.WHITE)

    //bar
    rl.DrawRectangleRec(bar_rect, WindowColor)
    adjust_and_draw_text(title, rect, TextPadding, 25)

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

gui_button :: proc(g_state: ^GuiState, rect: rl.Rectangle, title := "") -> bool{
    clicked: bool

    rl.DrawRectangleRec(rect, rl.WHITE)

    uiid := get_uiid()

    if rl.CheckCollisionPointRec(rl.GetMousePosition(), rect){
        g_state.hot_item = uiid 

        if rl.IsMouseButtonDown(.LEFT){
            g_state.is_window_clicked = false 
        }

        if rl.IsMouseButtonPressed(.LEFT){
            g_state.active_item = uiid 
            g_state.active_item_non_reset = uiid
            clicked = true
        }
    }

    //button rendering
    button_rect := get_non_outline_rect(rect)
    if g_state.hot_item == uiid{
        if g_state.active_item == uiid{
            rl.DrawRectangleRec(button_rect, ButtonActiveColor)
        }
        else{
            rl.DrawRectangleRec(button_rect, ButtonActiveColor)
        }
    }
    else{
        rl.DrawRectangleRec(button_rect, ButtonColor)
    }

    //text
    if title != ""{
        adjust_and_draw_text(title, button_rect, TextPadding, 30)
    }

    return clicked
}

gui_scroll_bar :: proc(g_state: ^GuiState, rect: rl.Rectangle, title := "", value: ^f32, max: f32, min: f32 = 0.0, fill_color := rl.WHITE){
    rl.DrawRectangleRec(rect, rl.WHITE)
    rect_non_outline := get_non_outline_rect(rect)

    scroll_bar_rect, display_rect := split_rect_by_two(rect_non_outline, left_width = 0.7, padding = 2 * OutlineWidth)

    //title
    TitleBarSize :: 30.0
    y := scroll_bar_rect.y

    scroll_bar_rect.y += TitleBarSize
    scroll_bar_rect.height -= TitleBarSize
    display_rect.y += TitleBarSize
    display_rect.height -= TitleBarSize

    title_bar_rect := rl.Rectangle{scroll_bar_rect.x, y, rect_non_outline.width, TitleBarSize - OutlineWidth}

    //blank rendering
    rl.DrawRectangleRec(scroll_bar_rect, scroll_bar_bg_color)
    rl.DrawRectangleRec(display_rect, scroll_bar_bg_color)
    rl.DrawRectangleRec(title_bar_rect, scroll_bar_bg_color)

    if title != ""{
        adjust_and_draw_text(title, title_bar_rect, TextPadding, 30)
    }

    //fill rect stuff
    fill_rect := get_non_outline_rect(scroll_bar_rect, OutlineWidth * 2)

    uiid := get_uiid()

    if rl.CheckCollisionPointRec(rl.GetMousePosition(), fill_rect){
        g_state.hot_item = uiid 

        if rl.IsMouseButtonDown(.LEFT){
            g_state.is_window_clicked = false 
            g_state.active_item = uiid
            g_state.active_item_non_reset = uiid
        }

    }

    max_width := fill_rect.width
    fill_rect.width *= rl.Normalize(value^, min, max)

    if g_state.active_item == uiid{
        fill_rect.width = rl.GetMousePosition().x - fill_rect.x
        value^ = (max - min) * fill_rect.width / max_width + min
    }

    rl.DrawRectangleRec(fill_rect, fill_color)

    //display stuff rect
    buf: [8]byte
    str := strconv.ftoa(buf[:], f64(value^), 'f', 2, 32)
    if str[0] == '+'{
        str = str[1:]
    }
    adjust_and_draw_text(str, display_rect, TextPadding, 30)
}

//scroll bar but you can change the display
gui_scroll_bar_active :: proc(g_state: ^GuiState, rect: rl.Rectangle, title := "", command: ^[dynamic]rl.KeyboardKey, value: ^f32, max: f32, min: f32 = 0.0, fill_color := rl.WHITE){
    rl.DrawRectangleRec(rect, rl.WHITE)
    rect_non_outline := get_non_outline_rect(rect)

    scroll_bar_rect, display_rect := split_rect_by_two(rect_non_outline, left_width = 0.7, padding = 2 * OutlineWidth)

    //title
    TitleBarSize :: 30.0
    y := scroll_bar_rect.y

    scroll_bar_rect.y += TitleBarSize
    scroll_bar_rect.height -= TitleBarSize
    display_rect.y += TitleBarSize
    display_rect.height -= TitleBarSize

    title_bar_rect := rl.Rectangle{scroll_bar_rect.x, y, rect_non_outline.width, TitleBarSize - OutlineWidth}

    //blank rendering
    rl.DrawRectangleRec(scroll_bar_rect, scroll_bar_bg_color)
    rl.DrawRectangleRec(display_rect, scroll_bar_bg_color)
    rl.DrawRectangleRec(title_bar_rect, scroll_bar_bg_color)

    if title != ""{
        adjust_and_draw_text(title, title_bar_rect, TextPadding, 30)
    }

    //fill rect stuff
    fill_rect := get_non_outline_rect(scroll_bar_rect, OutlineWidth * 2)

    uiid := get_uiid()

    if rl.CheckCollisionPointRec(rl.GetMousePosition(), fill_rect){
        g_state.hot_item = uiid 

        if rl.IsMouseButtonDown(.LEFT){
            g_state.is_window_clicked = false 
            g_state.active_item = uiid
            g_state.active_item_non_reset = uiid
        }

    }

    max_width := fill_rect.width
    fill_rect.width *= rl.Normalize(value^, min, max)

    if g_state.active_item == uiid{
        clear(command)
        
        fill_rect.width = rl.GetMousePosition().x - fill_rect.x
        value^ = (max - min) * fill_rect.width / max_width + min
    }

    rl.DrawRectangleRec(fill_rect, fill_color)

    //display stuff rect
    uiid_display := get_uiid()

    if rl.CheckCollisionPointRec(rl.GetMousePosition(), display_rect){
        g_state.hot_item = uiid 

        if g_state.active_item_non_reset == uiid{
            if key := rl.GetKeyPressed(); key != .KEY_NULL{
                if key == .BACKSPACE{
                    if len(command) > 0{
                        pop(command)
                    }
                }
                else if key == .ENTER{
                    g_state.active_item_non_reset = 0
                }
                else{
                    append(command, key)
                }
            }
        }

        if rl.IsMouseButtonDown(.LEFT){
            g_state.is_window_clicked = false 
            g_state.active_item = uiid
            g_state.active_item_non_reset = uiid
        }

    }


    buf: [8]byte
    str := strconv.ftoa(buf[:], f64(value^), 'f', 2, 32)

    if len(command) != 0 && g_state.active_item_non_reset == uiid{
        str = to_string_only_numbers(command^)
        value^ = f32(strconv.atof(str))
    }

    if str[0] == '+'{
        str = str[1:]
    }
    
    adjust_and_draw_text(str, display_rect, TextPadding, 30)
}