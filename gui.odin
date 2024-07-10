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
        if scale, ok := fit_text_in_line(title, 30, button_rect.width - 2.0 * TextPadding); ok{
            rl.DrawText(strings.clone_to_cstring(title, context.temp_allocator), i32(button_rect.x + TextPadding), i32(button_rect.y + button_rect.height / 4), i32(scale), rl.WHITE)
        }
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
        scalex, ok1 := fit_text_in_line(title, 30, title_bar_rect.width - 2 * TextPadding)
        scaley, ok2 := fit_text_in_column(30, (title_bar_rect.height - 2 * TextPadding))
        if scalex < scaley && ok1{
            rl.DrawText(strings.clone_to_cstring(title, context.temp_allocator), i32(title_bar_rect.x + TextPadding), i32(title_bar_rect.y + title_bar_rect.height / 4), i32(scalex), rl.WHITE)
        }
        else if scaley < scalex && ok2{
            rl.DrawText(strings.clone_to_cstring(title, context.temp_allocator), i32(title_bar_rect.x + TextPadding), i32(title_bar_rect.y + title_bar_rect.height / 4), i32(scaley), rl.WHITE)
        }
        /*
        if scale, ok := fit_text_in_line(title, 30, title_bar_rect.width - 2.0 * TextPadding); ok{
            rl.DrawText(strings.clone_to_cstring(title, context.temp_allocator), i32(title_bar_rect.x + TextPadding), i32(title_bar_rect.y + title_bar_rect.height / 4), i32(scale), rl.WHITE)
        }
            */
    }

    //fill rect stuff
    fill_rect := get_non_outline_rect(scroll_bar_rect, OutlineWidth * 2)

    uiid := get_uiid()

    if rl.CheckCollisionPointRec(rl.GetMousePosition(), fill_rect){
        g_state.hot_item = uiid 

        if rl.IsMouseButtonDown(.LEFT){
            g_state.is_window_clicked = false 
            g_state.active_item = uiid
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

}

/*
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