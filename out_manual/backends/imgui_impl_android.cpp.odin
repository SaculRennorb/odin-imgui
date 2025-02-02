package imgui

// dear imgui: Platform Binding for Android native app
// This needs to be used along with the OpenGL 3 Renderer (imgui_impl_opengl3)

// Implemented features:
//  [X] Platform: Keyboard support. Since 1.87 we are using the io.AddKeyEvent() function. Pass ImGuiKey values to all key functions e.g. ImGui::IsKeyPressed(ImGuiKey.Space). [Legacy AKEYCODE_* values are obsolete since 1.87 and not supported since 1.91.5]
//  [X] Platform: Mouse support. Can discriminate Mouse/TouchScreen/Pen.
// Missing features or Issues:
//  [ ] Platform: Clipboard support.
//  [ ] Platform: Gamepad support. Enable with 'io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad'.
//  [ ] Platform: Mouse cursor shape and visibility (ImGuiBackendFlags_HasMouseCursors). Disable with 'io.ConfigFlags |= ImGuiConfigFlags_NoMouseCursorChange'. FIXME: Check if this is even possible with Android.
//  [ ] Platform: Multi-viewport support (multiple windows). Not meaningful on Android.
// Important:
//  - Consider using SDL or GLFW backend on Android, which will be more full-featured than this.
//  - FIXME: On-screen keyboard currently needs to be enabled by the application (see examples/ and issue #3446)
//  - FIXME: Unicode character inputs needs to be passed by Dear ImGui by the application (see examples/ and issue #3446)

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// Learn about Dear ImGui:
// - FAQ                  https://dearimgui.com/faq
// - Getting Started      https://dearimgui.com/getting-started
// - Documentation        https://dearimgui.com/docs (same as your local docs/ folder).
// - Introduction, links and more at the top of imgui.cpp

// CHANGELOG
// (minor and older changes stripped away, please see git history for details)
//  2022-09-26: Inputs: Renamed ImGuiKey.ModXXX introduced in 1.87 to ImGuiMod_XXX (old names still supported).
//  2022-01-26: Inputs: replaced short-lived io.AddKeyModsEvent() (added two weeks ago) with io.AddKeyEvent() using ImGuiKey.ModXXX flags. Sorry for the confusion.
//  2022-01-17: Inputs: calling new io.AddMousePosEvent(), io.AddMouseButtonEvent(), io.AddMouseWheelEvent() API (1.87+).
//  2022-01-10: Inputs: calling new io.AddKeyEvent(), io.AddKeyModsEvent() + io.SetKeyEventNativeData() API (1.87+). Support for full ImGuiKey range.
//  2021-03-04: Initial version.

when !(IMGUI_DISABLE) {

// Android data
f64                                   g_Time = 0.0;
g_Window : ^ANativeWindow
u8                                     g_LogTag[] = "ImGuiExample";

ImGui_ImplAndroid_KeyCodeToImGuiKey :: proc(key_code : i32) -> ImGuiKey
{
    switch (key_code)
    {
        case AKEYCODE_TAB:                  return ImGuiKey.Tab;
        case AKEYCODE_DPAD_LEFT:            return ImGuiKey.LeftArrow;
        case AKEYCODE_DPAD_RIGHT:           return ImGuiKey.RightArrow;
        case AKEYCODE_DPAD_UP:              return ImGuiKey.UpArrow;
        case AKEYCODE_DPAD_DOWN:            return ImGuiKey.DownArrow;
        case AKEYCODE_PAGE_UP:              return ImGuiKey.PageUp;
        case AKEYCODE_PAGE_DOWN:            return ImGuiKey.PageDown;
        case AKEYCODE_MOVE_HOME:            return ImGuiKey.Home;
        case AKEYCODE_MOVE_END:             return ImGuiKey.End;
        case AKEYCODE_INSERT:               return ImGuiKey.Insert;
        case AKEYCODE_FORWARD_DEL:          return ImGuiKey.Delete;
        case AKEYCODE_DEL:                  return ImGuiKey.Backspace;
        case AKEYCODE_SPACE:                return ImGuiKey.Space;
        case AKEYCODE_ENTER:                return ImGuiKey.Enter;
        case AKEYCODE_ESCAPE:               return ImGuiKey.Escape;
        case AKEYCODE_APOSTROPHE:           return ImGuiKey.Apostrophe;
        case AKEYCODE_COMMA:                return ImGuiKey.Comma;
        case AKEYCODE_MINUS:                return ImGuiKey.Minus;
        case AKEYCODE_PERIOD:               return ImGuiKey.Period;
        case AKEYCODE_SLASH:                return ImGuiKey.Slash;
        case AKEYCODE_SEMICOLON:            return ImGuiKey.Semicolon;
        case AKEYCODE_EQUALS:               return ImGuiKey.Equal;
        case AKEYCODE_LEFT_BRACKET:         return ImGuiKey.LeftBracket;
        case AKEYCODE_BACKSLASH:            return ImGuiKey.Backslash;
        case AKEYCODE_RIGHT_BRACKET:        return ImGuiKey.RightBracket;
        case AKEYCODE_GRAVE:                return ImGuiKey.GraveAccent;
        case AKEYCODE_CAPS_LOCK:            return ImGuiKey.CapsLock;
        case AKEYCODE_SCROLL_LOCK:          return ImGuiKey.ScrollLock;
        case AKEYCODE_NUM_LOCK:             return ImGuiKey.NumLock;
        case AKEYCODE_SYSRQ:                return ImGuiKey.PrintScreen;
        case AKEYCODE_BREAK:                return ImGuiKey.Pause;
        case AKEYCODE_NUMPAD_0:             return ImGuiKey.Keypad0;
        case AKEYCODE_NUMPAD_1:             return ImGuiKey.Keypad1;
        case AKEYCODE_NUMPAD_2:             return ImGuiKey.Keypad2;
        case AKEYCODE_NUMPAD_3:             return ImGuiKey.Keypad3;
        case AKEYCODE_NUMPAD_4:             return ImGuiKey.Keypad4;
        case AKEYCODE_NUMPAD_5:             return ImGuiKey.Keypad5;
        case AKEYCODE_NUMPAD_6:             return ImGuiKey.Keypad6;
        case AKEYCODE_NUMPAD_7:             return ImGuiKey.Keypad7;
        case AKEYCODE_NUMPAD_8:             return ImGuiKey.Keypad8;
        case AKEYCODE_NUMPAD_9:             return ImGuiKey.Keypad9;
        case AKEYCODE_NUMPAD_DOT:           return ImGuiKey.KeypadDecimal;
        case AKEYCODE_NUMPAD_DIVIDE:        return ImGuiKey.KeypadDivide;
        case AKEYCODE_NUMPAD_MULTIPLY:      return ImGuiKey.KeypadMultiply;
        case AKEYCODE_NUMPAD_SUBTRACT:      return ImGuiKey.KeypadSubtract;
        case AKEYCODE_NUMPAD_ADD:           return ImGuiKey.KeypadAdd;
        case AKEYCODE_NUMPAD_ENTER:         return ImGuiKey.KeypadEnter;
        case AKEYCODE_NUMPAD_EQUALS:        return ImGuiKey.KeypadEqual;
        case AKEYCODE_CTRL_LEFT:            return ImGuiKey.LeftCtrl;
        case AKEYCODE_SHIFT_LEFT:           return ImGuiKey.LeftShift;
        case AKEYCODE_ALT_LEFT:             return ImGuiKey.LeftAlt;
        case AKEYCODE_META_LEFT:            return ImGuiKey.LeftSuper;
        case AKEYCODE_CTRL_RIGHT:           return ImGuiKey.RightCtrl;
        case AKEYCODE_SHIFT_RIGHT:          return ImGuiKey.RightShift;
        case AKEYCODE_ALT_RIGHT:            return ImGuiKey.RightAlt;
        case AKEYCODE_META_RIGHT:           return ImGuiKey.RightSuper;
        case AKEYCODE_MENU:                 return ImGuiKey.Menu;
        case AKEYCODE_0:                    return ImGuiKey._0;
        case AKEYCODE_1:                    return ImGuiKey._1;
        case AKEYCODE_2:                    return ImGuiKey._2;
        case AKEYCODE_3:                    return ImGuiKey._3;
        case AKEYCODE_4:                    return ImGuiKey._4;
        case AKEYCODE_5:                    return ImGuiKey._5;
        case AKEYCODE_6:                    return ImGuiKey._6;
        case AKEYCODE_7:                    return ImGuiKey._7;
        case AKEYCODE_8:                    return ImGuiKey._8;
        case AKEYCODE_9:                    return ImGuiKey._9;
        case AKEYCODE_A:                    return ImGuiKey.A;
        case AKEYCODE_B:                    return ImGuiKey.B;
        case AKEYCODE_C:                    return ImGuiKey.C;
        case AKEYCODE_D:                    return ImGuiKey.D;
        case AKEYCODE_E:                    return ImGuiKey.E;
        case AKEYCODE_F:                    return ImGuiKey.F;
        case AKEYCODE_G:                    return ImGuiKey.G;
        case AKEYCODE_H:                    return ImGuiKey.H;
        case AKEYCODE_I:                    return ImGuiKey.I;
        case AKEYCODE_J:                    return ImGuiKey.J;
        case AKEYCODE_K:                    return ImGuiKey.K;
        case AKEYCODE_L:                    return ImGuiKey.L;
        case AKEYCODE_M:                    return ImGuiKey.M;
        case AKEYCODE_N:                    return ImGuiKey.N;
        case AKEYCODE_O:                    return ImGuiKey.O;
        case AKEYCODE_P:                    return ImGuiKey.P;
        case AKEYCODE_Q:                    return ImGuiKey.Q;
        case AKEYCODE_R:                    return ImGuiKey.R;
        case AKEYCODE_S:                    return ImGuiKey.S;
        case AKEYCODE_T:                    return ImGuiKey.T;
        case AKEYCODE_U:                    return ImGuiKey.U;
        case AKEYCODE_V:                    return ImGuiKey.V;
        case AKEYCODE_W:                    return ImGuiKey.W;
        case AKEYCODE_X:                    return ImGuiKey.X;
        case AKEYCODE_Y:                    return ImGuiKey.Y;
        case AKEYCODE_Z:                    return ImGuiKey.Z;
        case AKEYCODE_F1:                   return ImGuiKey.F1;
        case AKEYCODE_F2:                   return ImGuiKey.F2;
        case AKEYCODE_F3:                   return ImGuiKey.F3;
        case AKEYCODE_F4:                   return ImGuiKey.F4;
        case AKEYCODE_F5:                   return ImGuiKey.F5;
        case AKEYCODE_F6:                   return ImGuiKey.F6;
        case AKEYCODE_F7:                   return ImGuiKey.F7;
        case AKEYCODE_F8:                   return ImGuiKey.F8;
        case AKEYCODE_F9:                   return ImGuiKey.F9;
        case AKEYCODE_F10:                  return ImGuiKey.F10;
        case AKEYCODE_F11:                  return ImGuiKey.F11;
        case AKEYCODE_F12:                  return ImGuiKey.F12;
        case:                            return ImGuiKey.None;
    }
}

ImGui_ImplAndroid_HandleInputEvent :: proc(input_event : ^AInputEvent) -> i32
{
    io := GetIO();
    event_type := AInputEvent_getType(input_event);
    switch (event_type)
    {
    case AINPUT_EVENT_TYPE_KEY:
    {
        event_key_code := AKeyEvent_getKeyCode(input_event);
        event_scan_code := AKeyEvent_getScanCode(input_event);
        event_action := AKeyEvent_getAction(input_event);
        event_meta_state := AKeyEvent_getMetaState(input_event);

        io.AddKeyEvent(ImGuiKey.Mod_Ctrl,  (event_meta_state & AMETA_CTRL_ON)  != 0);
        io.AddKeyEvent(ImGuiKey.Mod_Shift, (event_meta_state & AMETA_SHIFT_ON) != 0);
        io.AddKeyEvent(ImGuiKey.Mod_Alt,   (event_meta_state & AMETA_ALT_ON)   != 0);
        io.AddKeyEvent(ImGuiKey.Mod_Super, (event_meta_state & AMETA_META_ON)  != 0);

        switch (event_action)
        {
        // FIXME: AKEY_EVENT_ACTION_DOWN and AKEY_EVENT_ACTION_UP occur at once as soon as a touch pointer
        // goes up from a key. We use a simple key event queue/ and process one event per key per frame in
        // ImGui_ImplAndroid_NewFrame()...or consider using IO queue, if suitable: https://github.com/ocornut/imgui/issues/2787
        case AKEY_EVENT_ACTION_DOWN:
        case AKEY_EVENT_ACTION_UP:
        {
            key := ImGui_ImplAndroid_KeyCodeToImGuiKey(event_key_code);
            if (key != ImGuiKey.None)
            {
                io.AddKeyEvent(key, event_action == AKEY_EVENT_ACTION_DOWN);
                io.SetKeyEventNativeData(key, event_key_code, event_scan_code);
            }

            break;
        }
        case:
            break;
        }
        break;
    }
    case AINPUT_EVENT_TYPE_MOTION:
    {
        event_action := AMotionEvent_getAction(input_event);
        event_pointer_index := (event_action & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK) >> AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT;
        event_action &= AMOTION_EVENT_ACTION_MASK;

        switch (AMotionEvent_getToolType(input_event, event_pointer_index))
        {
        case AMOTION_EVENT_TOOL_TYPE_MOUSE:
            io.AddMouseSourceEvent(ImGuiMouseSource_Mouse);
            break;
        case AMOTION_EVENT_TOOL_TYPE_STYLUS:
        case AMOTION_EVENT_TOOL_TYPE_ERASER:
            io.AddMouseSourceEvent(ImGuiMouseSource_Pen);
            break;
        case AMOTION_EVENT_TOOL_TYPE_FINGER:
        case:
            io.AddMouseSourceEvent(ImGuiMouseSource_TouchScreen);
            break;
        }

        switch (event_action)
        {
        case AMOTION_EVENT_ACTION_DOWN:
        case AMOTION_EVENT_ACTION_UP:
        {
            // Physical mouse buttons (and probably other physical devices) also invoke the actions AMOTION_EVENT_ACTION_DOWN/_UP,
            // but we have to process them separately to identify the actual button pressed. This is done below via
            // AMOTION_EVENT_ACTION_BUTTON_PRESS/_RELEASE. Here, we only process "FINGER" input (and "UNKNOWN", as a fallback).
            tool_type := AMotionEvent_getToolType(input_event, event_pointer_index);
            if (tool_type == AMOTION_EVENT_TOOL_TYPE_FINGER || tool_type == AMOTION_EVENT_TOOL_TYPE_UNKNOWN)
            {
                io.AddMousePosEvent(AMotionEvent_getX(input_event, event_pointer_index), AMotionEvent_getY(input_event, event_pointer_index));
                io.AddMouseButtonEvent(0, event_action == AMOTION_EVENT_ACTION_DOWN);
            }
            break;
        }
        case AMOTION_EVENT_ACTION_BUTTON_PRESS:
        case AMOTION_EVENT_ACTION_BUTTON_RELEASE:
        {
            button_state := AMotionEvent_getButtonState(input_event);
            io.AddMouseButtonEvent(0, (button_state & AMOTION_EVENT_BUTTON_PRIMARY) != 0);
            io.AddMouseButtonEvent(1, (button_state & AMOTION_EVENT_BUTTON_SECONDARY) != 0);
            io.AddMouseButtonEvent(2, (button_state & AMOTION_EVENT_BUTTON_TERTIARY) != 0);
            break;
        }
        case AMOTION_EVENT_ACTION_HOVER_MOVE: // Hovering: Tool moves while NOT pressed (such as a physical mouse)
        case AMOTION_EVENT_ACTION_MOVE:       // Touch pointer moves while DOWN
            io.AddMousePosEvent(AMotionEvent_getX(input_event, event_pointer_index), AMotionEvent_getY(input_event, event_pointer_index));
            break;
        case AMOTION_EVENT_ACTION_SCROLL:
            io.AddMouseWheelEvent(AMotionEvent_getAxisValue(input_event, AMOTION_EVENT_AXIS_HSCROLL, event_pointer_index), AMotionEvent_getAxisValue(input_event, AMOTION_EVENT_AXIS_VSCROLL, event_pointer_index));
            break;
        case:
            break;
        }
    }
        return 1;
    case:
        break;
    }

    return 0;
}

ImGui_ImplAndroid_Init :: proc(window : ^ANativeWindow) -> bool
{
    IMGUI_CHECKVERSION();

    g_Window = window;
    g_Time = 0.0;

    // Setup backend capabilities flags
    io := GetIO();
    io.BackendPlatformName = "imgui_impl_android";

    return true;
}

ImGui_ImplAndroid_Shutdown :: proc()
{
    io := GetIO();
    io.BackendPlatformName = nullptr;
}

ImGui_ImplAndroid_NewFrame :: proc()
{
    io := GetIO();

    // Setup display size (every frame to accommodate for window resizing)
    window_width := ANativeWindow_getWidth(g_Window);
    window_height := ANativeWindow_getHeight(g_Window);
    display_width := window_width;
    display_height := window_height;

    io.DisplaySize = ImVec2{(f32}window_width, cast(f32) window_height);
    if (window_width > 0 && window_height > 0)
        io.DisplayFramebufferScale = ImVec2{(f32}display_width / window_width, cast(f32) display_height / window_height);

    // Setup time step
    struct timespec current_timespec;
    clock_gettime(CLOCK_MONOTONIC, &current_timespec);
    current_time := (f64)(current_timespec.tv_sec) + (current_timespec.tv_nsec / 1000000000.0);
    io.DeltaTime = g_Time > 0.0 ? (f32)(current_time - g_Time) : (f32)(1.0 / 60.0);
    g_Time = current_time;
}

//-----------------------------------------------------------------------------

} // #ifndef IMGUI_DISABLE
