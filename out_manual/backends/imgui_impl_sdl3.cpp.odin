package imgui

// dear imgui: Platform Backend for SDL3 (*EXPERIMENTAL*)
// This needs to be used along with a Renderer (e.g. DirectX11, OpenGL3, Vulkan..)
// (Info: SDL3 is a cross-platform general purpose library for handling windows, inputs, graphics context creation, etc.)

// (**IMPORTANT: SDL 3.0.0 is NOT YET RELEASED AND CURRENTLY HAS A FAST CHANGING API. THIS CODE BREAKS OFTEN AS SDL3 CHANGES.**)

// Implemented features:
//  [X] Platform: Clipboard support.
//  [X] Platform: Mouse support. Can discriminate Mouse/TouchScreen.
//  [X] Platform: Keyboard support. Since 1.87 we are using the io.AddKeyEvent() function. Pass ImGuiKey values to all key functions e.g. ImGui::IsKeyPressed(ImGuiKey.Space). [Legacy SDL_SCANCODE_* values are obsolete since 1.87 and not supported since 1.91.5]
//  [X] Platform: Gamepad support. Enabled with 'io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad'.
//  [X] Platform: Mouse cursor shape and visibility (ImGuiBackendFlags_HasMouseCursors). Disable with 'io.ConfigFlags |= ImGuiConfigFlags_NoMouseCursorChange'.
//  [x] Platform: Multi-viewport support (multiple windows). Enable with 'io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable' -> the OS animation effect when window gets created/destroyed is problematic. SDL2 backend doesn't have issue.
// Missing features or Issues:
//  [ ] Platform: Multi-viewport: Minimized windows seems to break mouse wheel events (at least under Windows).
//  [x] Platform: IME support. Position somehow broken in SDL3 + app needs to call 'SDL_SetHint(SDL_HINT_IME_SHOW_UI, "1");' before SDL_CreateWindow()!.

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// Learn about Dear ImGui:
// - FAQ                  https://dearimgui.com/faq
// - Getting Started      https://dearimgui.com/getting-started
// - Documentation        https://dearimgui.com/docs (same as your local docs/ folder).
// - Introduction, links and more at the top of imgui.cpp

// CHANGELOG
// (minor and older changes stripped away, please see git history for details)
//  2025-XX-XX: Platform: Added support for multiple windows via the ImGuiPlatformIO interface.
//  2024-09-11: (Docking) Added support for viewport.ParentViewportId field to support parenting at OS level. (#7973)
//  2024-10-24: Emscripten: SDL_EVENT_MOUSE_WHEEL event doesn't require dividing by 100.0f on Emscripten.
//  2024-09-03: Update for SDL3 api changes: SDL_GetGamepads() memory ownership revert. (#7918, #7898, #7807)
//  2024-08-22: moved some OS/backend related function pointers from ImGuiIO to ImGuiPlatformIO:
//               - io.GetClipboardTextFn    -> platform_io.Platform_GetClipboardTextFn
//               - io.SetClipboardTextFn    -> platform_io.Platform_SetClipboardTextFn
//               - io.PlatformSetImeDataFn  -> platform_io.Platform_SetImeDataFn
//  2024-08-19: Storing SDL_WindowID inside ImGuiViewport::PlatformHandle instead of SDL_Window*.
//  2024-08-19: ImGui_ImplSDL3_ProcessEvent() now ignores events intended for other SDL windows. (#7853)
//  2024-07-22: Update for SDL3 api changes: SDL_GetGamepads() memory ownership change. (#7807)
//  2024-07-18: Update for SDL3 api changes: SDL_GetClipboardText() memory ownership change. (#7801)
//  2024-07-15: Update for SDL3 api changes: SDL_GetProperty() change to SDL_GetPointerProperty(). (#7794)
//  2024-07-02: Update for SDL3 api changes: SDLK_x renames and SDLK_KP_x removals (#7761, #7762).
//  2024-07-01: Update for SDL3 api changes: SDL_SetTextInputRect() changed to SDL_SetTextInputArea().
//  2024-06-26: Update for SDL3 api changes: SDL_StartTextInput()/SDL_StopTextInput()/SDL_SetTextInputRect() functions signatures.
//  2024-06-24: Update for SDL3 api changes: SDL_EVENT_KEY_DOWN/SDL_EVENT_KEY_UP contents.
//  2024-06-03; Update for SDL3 api changes: SDL_SYSTEM_CURSOR_ renames.
//  2024-05-15: Update for SDL3 api changes: SDLK_ renames.
//  2024-04-15: Inputs: Re-enable calling SDL_StartTextInput()/SDL_StopTextInput() as SDL3 no longer enables it by default and should play nicer with IME.
//  2024-02-13: Inputs: Fixed gamepad support. Handle gamepad disconnection. Added ImGui_ImplSDL3_SetGamepadMode().
//  2023-11-13: Updated for recent SDL3 API changes.
//  2023-10-05: Inputs: Added support for extra ImGuiKey values: F13 to F24 function keys, app back/forward keys.
//  2023-05-04: Fixed build on Emscripten/iOS/Android. (#6391)
//  2023-04-06: Inputs: Avoid calling SDL_StartTextInput()/SDL_StopTextInput() as they don't only pertain to IME. It's unclear exactly what their relation is to IME. (#6306)
//  2023-04-04: Inputs: Added support for io.AddMouseSourceEvent() to discriminate ImGuiMouseSource_Mouse/ImGuiMouseSource_TouchScreen. (#2702)
//  2023-02-23: Accept SDL_GetPerformanceCounter() not returning a monotonically increasing value. (#6189, #6114, #3644)
//  2023-02-07: Forked "imgui_impl_sdl2" into "imgui_impl_sdl3". Removed version checks for old feature. Refer to imgui_impl_sdl2.cpp for older changelog.

when !(IMGUI_DISABLE) {

// Clang warnings with -Weverything

// SDL
when defined(__APPLE__) {
}
when _WIN32 {
when !(WIN32_LEAN_AND_MEAN) {
WIN32_LEAN_AND_MEAN :: true
}
}

when !defined(__EMSCRIPTEN__) && !defined(__ANDROID__) && !(defined(__APPLE__) && TARGET_OS_IOS) && !defined(__amigaos4__) {
SDL_HAS_CAPTURE_AND_GLOBAL_MOUSE :: 1
} else {
SDL_HAS_CAPTURE_AND_GLOBAL_MOUSE :: 0
}

// FIXME-LEGACY: remove when SDL 3.1.3 preview is released.
when !(SDLK_APOSTROPHE) {
SDLK_APOSTROPHE :: SDLK_QUOTE
}
when !(SDLK_GRAVE) {
SDLK_GRAVE :: SDLK_BACKQUOTE
}

// SDL Data
ImGui_ImplSDL3_Data :: struct
{
    Window : ^SDL_Window,
    WindowID : SDL_WindowID,
    Renderer : ^SDL_Renderer,
    Time : Uint64,
    ClipboardTextData : string,
    UseVulkan : bool,
    WantUpdateMonitors : bool,

    // IME handling
    ImeWindow : ^SDL_Window,

    // Mouse handling
    MouseWindowID : Uint32,
    MouseButtonsDown : i32,
    SDL_Cursor*             MouseCursors[ImGuiMouseCursor_COUNT];
    MouseLastCursor : ^SDL_Cursor,
    MousePendingLeaveFrame : i32,
    MouseCanUseGlobalState : bool,
    MouseCanReportHoveredViewport : bool,  // This is hard to use/unreliable on SDL so we'll set ImGuiBackendFlags_HasMouseHoveredViewport dynamically based on state.

    // Gamepad handling
    ImVector<SDL_Gamepad*>  Gamepads;
    GamepadMode : ImGui_ImplSDL3_GamepadMode,
    WantUpdateGamepadsList : bool,

    ImGui_ImplSDL3_Data()   { memset((rawptr)this, 0, size_of(*this)); }
};

// Backend data stored in io.BackendPlatformUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
// FIXME: multi-context support is not well tested and probably dysfunctional in this backend.
// FIXME: some shared resources (mouse cursor shape, gamepad) are mishandled when using multi-context.
ImGui_ImplSDL3_GetBackendData :: proc() -> ^ImGui_ImplSDL3_Data
{
    return GetCurrentContext() ? (ImGui_ImplSDL3_Data*)GetIO().BackendPlatformUserData : nullptr;
}

// Forward Declarations
void ImGui_ImplSDL3_UpdateMonitors();
void ImGui_ImplSDL3_InitMultiViewportSupport(SDL_Window* window, rawptr sdl_gl_context);
void ImGui_ImplSDL3_ShutdownMultiViewportSupport();

// Functions
ImGui_ImplSDL3_GetClipboardText :: proc(ImGuiContext*) -> ^u8
{
    bd := ImGui_ImplSDL3_GetBackendData();
    if (bd.ClipboardTextData) {
        SDL_free(bd.ClipboardTextData);
    }

    sdl_clipboard_text := SDL_GetClipboardText();
    bd.ClipboardTextData = sdl_clipboard_text ? SDL_strdup(sdl_clipboard_text) : nullptr;
    return bd.ClipboardTextData;
}

ImGui_ImplSDL3_SetClipboardText :: proc(ImGuiContext*, text : ^u8)
{
    SDL_SetClipboardText(text);
}

ImGui_ImplSDL3_PlatformSetImeData :: proc(ImGuiContext*, viewport : ^ImGuiViewport, data : ^ImGuiPlatformImeData)
{
    bd := ImGui_ImplSDL3_GetBackendData();
    window_id := (SDL_WindowID)(rawptr)viewport.PlatformHandle;
    window := SDL_GetWindowFromID(window_id);
    if ((data.WantVisible == false || bd.ImeWindow != window) && bd.ImeWindow != nullptr)
    {
        SDL_StopTextInput(bd.ImeWindow);
        bd.ImeWindow = nullptr;
    }
    if (data.WantVisible)
    {
        r : SDL_Rect
        r.x = (i32)(data.InputPos.x - viewport.Pos.x);
        r.y = (i32)(data.InputPos.y - viewport.Pos.y + data.InputLineHeight);
        r.w = 1;
        r.h = cast(i32) data.InputLineHeight;
        SDL_SetTextInputArea(window, &r, 0);
        SDL_StartTextInput(window);
        bd.ImeWindow = window;
    }
}

// Not static to allow third-party code to use that if they want to (but undocumented)
ImGuiKey ImGui_ImplSDL3_KeyEventToImGuiKey(SDL_Keycode keycode, SDL_Scancode scancode);
ImGui_ImplSDL3_KeyEventToImGuiKey :: proc(keycode : SDL_Keycode, scancode : SDL_Scancode) -> ImGuiKey
{
    // Keypad doesn't have individual key values in SDL3
    switch (scancode)
    {
        case SDL_SCANCODE_KP_0: return ImGuiKey.Keypad0;
        case SDL_SCANCODE_KP_1: return ImGuiKey.Keypad1;
        case SDL_SCANCODE_KP_2: return ImGuiKey.Keypad2;
        case SDL_SCANCODE_KP_3: return ImGuiKey.Keypad3;
        case SDL_SCANCODE_KP_4: return ImGuiKey.Keypad4;
        case SDL_SCANCODE_KP_5: return ImGuiKey.Keypad5;
        case SDL_SCANCODE_KP_6: return ImGuiKey.Keypad6;
        case SDL_SCANCODE_KP_7: return ImGuiKey.Keypad7;
        case SDL_SCANCODE_KP_8: return ImGuiKey.Keypad8;
        case SDL_SCANCODE_KP_9: return ImGuiKey.Keypad9;
        case SDL_SCANCODE_KP_PERIOD: return ImGuiKey.KeypadDecimal;
        case SDL_SCANCODE_KP_DIVIDE: return ImGuiKey.KeypadDivide;
        case SDL_SCANCODE_KP_MULTIPLY: return ImGuiKey.KeypadMultiply;
        case SDL_SCANCODE_KP_MINUS: return ImGuiKey.KeypadSubtract;
        case SDL_SCANCODE_KP_PLUS: return ImGuiKey.KeypadAdd;
        case SDL_SCANCODE_KP_ENTER: return ImGuiKey.KeypadEnter;
        case SDL_SCANCODE_KP_EQUALS: return ImGuiKey.KeypadEqual;
        case: break;
    }
    switch (keycode)
    {
        case SDLK_TAB: return ImGuiKey.Tab;
        case SDLK_LEFT: return ImGuiKey.LeftArrow;
        case SDLK_RIGHT: return ImGuiKey.RightArrow;
        case SDLK_UP: return ImGuiKey.UpArrow;
        case SDLK_DOWN: return ImGuiKey.DownArrow;
        case SDLK_PAGEUP: return ImGuiKey.PageUp;
        case SDLK_PAGEDOWN: return ImGuiKey.PageDown;
        case SDLK_HOME: return ImGuiKey.Home;
        case SDLK_END: return ImGuiKey.End;
        case SDLK_INSERT: return ImGuiKey.Insert;
        case SDLK_DELETE: return ImGuiKey.Delete;
        case SDLK_BACKSPACE: return ImGuiKey.Backspace;
        case SDLK_SPACE: return ImGuiKey.Space;
        case SDLK_RETURN: return ImGuiKey.Enter;
        case SDLK_ESCAPE: return ImGuiKey.Escape;
        case SDLK_APOSTROPHE: return ImGuiKey.Apostrophe;
        case SDLK_COMMA: return ImGuiKey.Comma;
        case SDLK_MINUS: return ImGuiKey.Minus;
        case SDLK_PERIOD: return ImGuiKey.Period;
        case SDLK_SLASH: return ImGuiKey.Slash;
        case SDLK_SEMICOLON: return ImGuiKey.Semicolon;
        case SDLK_EQUALS: return ImGuiKey.Equal;
        case SDLK_LEFTBRACKET: return ImGuiKey.LeftBracket;
        case SDLK_BACKSLASH: return ImGuiKey.Backslash;
        case SDLK_RIGHTBRACKET: return ImGuiKey.RightBracket;
        case SDLK_GRAVE: return ImGuiKey.GraveAccent;
        case SDLK_CAPSLOCK: return ImGuiKey.CapsLock;
        case SDLK_SCROLLLOCK: return ImGuiKey.ScrollLock;
        case SDLK_NUMLOCKCLEAR: return ImGuiKey.NumLock;
        case SDLK_PRINTSCREEN: return ImGuiKey.PrintScreen;
        case SDLK_PAUSE: return ImGuiKey.Pause;
        case SDLK_LCTRL: return ImGuiKey.LeftCtrl;
        case SDLK_LSHIFT: return ImGuiKey.LeftShift;
        case SDLK_LALT: return ImGuiKey.LeftAlt;
        case SDLK_LGUI: return ImGuiKey.LeftSuper;
        case SDLK_RCTRL: return ImGuiKey.RightCtrl;
        case SDLK_RSHIFT: return ImGuiKey.RightShift;
        case SDLK_RALT: return ImGuiKey.RightAlt;
        case SDLK_RGUI: return ImGuiKey.RightSuper;
        case SDLK_APPLICATION: return ImGuiKey.Menu;
        case SDLK_0: return ImGuiKey._0;
        case SDLK_1: return ImGuiKey._1;
        case SDLK_2: return ImGuiKey._2;
        case SDLK_3: return ImGuiKey._3;
        case SDLK_4: return ImGuiKey._4;
        case SDLK_5: return ImGuiKey._5;
        case SDLK_6: return ImGuiKey._6;
        case SDLK_7: return ImGuiKey._7;
        case SDLK_8: return ImGuiKey._8;
        case SDLK_9: return ImGuiKey._9;
        case SDLK_A: return ImGuiKey.A;
        case SDLK_B: return ImGuiKey.B;
        case SDLK_C: return ImGuiKey.C;
        case SDLK_D: return ImGuiKey.D;
        case SDLK_E: return ImGuiKey.E;
        case SDLK_F: return ImGuiKey.F;
        case SDLK_G: return ImGuiKey.G;
        case SDLK_H: return ImGuiKey.H;
        case SDLK_I: return ImGuiKey.I;
        case SDLK_J: return ImGuiKey.J;
        case SDLK_K: return ImGuiKey.K;
        case SDLK_L: return ImGuiKey.L;
        case SDLK_M: return ImGuiKey.M;
        case SDLK_N: return ImGuiKey.N;
        case SDLK_O: return ImGuiKey.O;
        case SDLK_P: return ImGuiKey.P;
        case SDLK_Q: return ImGuiKey.Q;
        case SDLK_R: return ImGuiKey.R;
        case SDLK_S: return ImGuiKey.S;
        case SDLK_T: return ImGuiKey.T;
        case SDLK_U: return ImGuiKey.U;
        case SDLK_V: return ImGuiKey.V;
        case SDLK_W: return ImGuiKey.W;
        case SDLK_X: return ImGuiKey.X;
        case SDLK_Y: return ImGuiKey.Y;
        case SDLK_Z: return ImGuiKey.Z;
        case SDLK_F1: return ImGuiKey.F1;
        case SDLK_F2: return ImGuiKey.F2;
        case SDLK_F3: return ImGuiKey.F3;
        case SDLK_F4: return ImGuiKey.F4;
        case SDLK_F5: return ImGuiKey.F5;
        case SDLK_F6: return ImGuiKey.F6;
        case SDLK_F7: return ImGuiKey.F7;
        case SDLK_F8: return ImGuiKey.F8;
        case SDLK_F9: return ImGuiKey.F9;
        case SDLK_F10: return ImGuiKey.F10;
        case SDLK_F11: return ImGuiKey.F11;
        case SDLK_F12: return ImGuiKey.F12;
        case SDLK_F13: return ImGuiKey.F13;
        case SDLK_F14: return ImGuiKey.F14;
        case SDLK_F15: return ImGuiKey.F15;
        case SDLK_F16: return ImGuiKey.F16;
        case SDLK_F17: return ImGuiKey.F17;
        case SDLK_F18: return ImGuiKey.F18;
        case SDLK_F19: return ImGuiKey.F19;
        case SDLK_F20: return ImGuiKey.F20;
        case SDLK_F21: return ImGuiKey.F21;
        case SDLK_F22: return ImGuiKey.F22;
        case SDLK_F23: return ImGuiKey.F23;
        case SDLK_F24: return ImGuiKey.F24;
        case SDLK_AC_BACK: return ImGuiKey.AppBack;
        case SDLK_AC_FORWARD: return ImGuiKey.AppForward;
        case: break;
    }
    return ImGuiKey.None;
}

ImGui_ImplSDL3_UpdateKeyModifiers :: proc(sdl_key_mods : SDL_Keymod)
{
    io := GetIO();
    io.AddKeyEvent(ImGuiKey.Mod_Ctrl, (sdl_key_mods & SDL_KMOD_CTRL) != 0);
    io.AddKeyEvent(ImGuiKey.Mod_Shift, (sdl_key_mods & SDL_KMOD_SHIFT) != 0);
    io.AddKeyEvent(ImGuiKey.Mod_Alt, (sdl_key_mods & SDL_KMOD_ALT) != 0);
    io.AddKeyEvent(ImGuiKey.Mod_Super, (sdl_key_mods & SDL_KMOD_GUI) != 0);
}

ImGui_ImplSDL3_GetViewportForWindowID :: proc(window_id : SDL_WindowID) -> ^ImGuiViewport
{
    return FindViewportByPlatformHandle(cast(rawptr)window_id);
}

// You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
// - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application, or clear/overwrite your copy of the mouse data.
// - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application, or clear/overwrite your copy of the keyboard data.
// Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.
ImGui_ImplSDL3_ProcessEvent :: proc(event : ^SDL_Event) -> bool
{
    bd := ImGui_ImplSDL3_GetBackendData();
    assert(bd != nullptr, "Context or backend not initialized! Did you call ImGui_ImplSDL3_Init()?");
    io := GetIO();

    switch (event.type)
    {
        case SDL_EVENT_MOUSE_MOTION:
        {
            if (ImGui_ImplSDL3_GetViewportForWindowID(event.motion.windowID) == nullptr)   do return false
            mouse_pos := ImVec2(cast(f32) event.motion.x, cast(f32) event.motion.y);
            if (.ViewportsEnable in io.ConfigFlags)
            {
                window_x, window_y : i32
                SDL_GetWindowPosition(SDL_GetWindowFromID(event.motion.windowID), &window_x, &window_y);
                mouse_pos.x += window_x;
                mouse_pos.y += window_y;
            }
            io.AddMouseSourceEvent(event.motion.which == SDL_TOUCH_MOUSEID ? ImGuiMouseSource_TouchScreen : ImGuiMouseSource_Mouse);
            io.AddMousePosEvent(mouse_pos.x, mouse_pos.y);
            return true;
        }
        case SDL_EVENT_MOUSE_WHEEL:
        {
            if (ImGui_ImplSDL3_GetViewportForWindowID(event.wheel.windowID) == nullptr)   do return false
            //IMGUI_DEBUG_LOG("wheel %.2f %.2f, precise %.2f %.2f\n", (float)event.wheel.x, (float)event.wheel.y, event.wheel.preciseX, event.wheel.preciseY);
            wheel_x := -event.wheel.x;
            wheel_y := event.wheel.y;
            io.AddMouseSourceEvent(event.wheel.which == SDL_TOUCH_MOUSEID ? ImGuiMouseSource_TouchScreen : ImGuiMouseSource_Mouse);
            io.AddMouseWheelEvent(wheel_x, wheel_y);
            return true;
        }
        case SDL_EVENT_MOUSE_BUTTON_DOWN:
        case SDL_EVENT_MOUSE_BUTTON_UP:
        {
            if (ImGui_ImplSDL3_GetViewportForWindowID(event.button.windowID) == nullptr)   do return false
            mouse_button := -1;
            if (event.button.button == SDL_BUTTON_LEFT) { mouse_button = 0; }
            if (event.button.button == SDL_BUTTON_RIGHT) { mouse_button = 1; }
            if (event.button.button == SDL_BUTTON_MIDDLE) { mouse_button = 2; }
            if (event.button.button == SDL_BUTTON_X1) { mouse_button = 3; }
            if (event.button.button == SDL_BUTTON_X2) { mouse_button = 4; }
            if (mouse_button == -1)   do break
            io.AddMouseSourceEvent(event.button.which == SDL_TOUCH_MOUSEID ? ImGuiMouseSource_TouchScreen : ImGuiMouseSource_Mouse);
            io.AddMouseButtonEvent(mouse_button, (event.type == SDL_EVENT_MOUSE_BUTTON_DOWN));
            bd.MouseButtonsDown = (event.type == SDL_EVENT_MOUSE_BUTTON_DOWN) ? (bd.MouseButtonsDown | (1 << mouse_button)) : (bd.MouseButtonsDown & ~(1 << mouse_button));
            return true;
        }
        case SDL_EVENT_TEXT_INPUT:
        {
            if (ImGui_ImplSDL3_GetViewportForWindowID(event.text.windowID) == nullptr)   do return false
            io.AddInputCharactersUTF8(event.text.text);
            return true;
        }
        case SDL_EVENT_KEY_DOWN:
        case SDL_EVENT_KEY_UP:
        {
            if (ImGui_ImplSDL3_GetViewportForWindowID(event.key.windowID) == nullptr)   do return false
            //IMGUI_DEBUG_LOG("SDL_EVENT_KEY_%d: key=%d, scancode=%d, mod=%X\n", (event.type == SDL_EVENT_KEY_DOWN) ? "DOWN" : "UP", event.key.key, event.key.scancode, event.key.mod);
            ImGui_ImplSDL3_UpdateKeyModifiers((SDL_Keymod)event.key.mod);
            key := ImGui_ImplSDL3_KeyEventToImGuiKey(event.key.key, event.key.scancode);
            io.AddKeyEvent(key, (event.type == SDL_EVENT_KEY_DOWN));
            io.SetKeyEventNativeData(key, event.key.key, event.key.scancode, event.key.scancode); // To support legacy indexing (<1.87 user code). Legacy backend uses SDLK_*** as indices to IsKeyXXX() functions.
            return true;
        }
        case SDL_EVENT_DISPLAY_ORIENTATION:
        case SDL_EVENT_DISPLAY_ADDED:
        case SDL_EVENT_DISPLAY_REMOVED:
        case SDL_EVENT_DISPLAY_MOVED:
        case SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED:
        {
            bd.WantUpdateMonitors = true;
            return true;
        }
        case SDL_EVENT_WINDOW_MOUSE_ENTER:
        {
            if (ImGui_ImplSDL3_GetViewportForWindowID(event.window.windowID) == nullptr)   do return false
            bd.MouseWindowID = event.window.windowID;
            bd.MousePendingLeaveFrame = 0;
            return true;
        }
        // - In some cases, when detaching a window from main viewport SDL may send SDL_WINDOWEVENT_ENTER one frame too late,
        //   causing SDL_WINDOWEVENT_LEAVE on previous frame to interrupt drag operation by clear mouse position. This is why
        //   we delay process the SDL_WINDOWEVENT_LEAVE events by one frame. See issue #5012 for details.
        // FIXME: Unconfirmed whether this is still needed with SDL3.
        case SDL_EVENT_WINDOW_MOUSE_LEAVE:
        {
            if (ImGui_ImplSDL3_GetViewportForWindowID(event.window.windowID) == nullptr)   do return false
            bd.MousePendingLeaveFrame = GetFrameCount() + 1;
            return true;
        }
        case SDL_EVENT_WINDOW_FOCUS_GAINED:
        case SDL_EVENT_WINDOW_FOCUS_LOST:
        {
            if (ImGui_ImplSDL3_GetViewportForWindowID(event.window.windowID) == nullptr)   do return false
            io.AddFocusEvent(event.type == SDL_EVENT_WINDOW_FOCUS_GAINED);
            return true;
        }
        case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
        case SDL_EVENT_WINDOW_MOVED:
        case SDL_EVENT_WINDOW_RESIZED:
        {
            viewport := ImGui_ImplSDL3_GetViewportForWindowID(event.window.windowID);
            if (viewport == nil)   do return false
            if (event.type == SDL_EVENT_WINDOW_CLOSE_REQUESTED) {
                viewport.PlatformRequestClose = true;
            }

            if (event.type == SDL_EVENT_WINDOW_MOVED) {
                viewport.PlatformRequestMove = true;
            }

            if (event.type == SDL_EVENT_WINDOW_RESIZED) {
                viewport.PlatformRequestResize = true;
            }

            return true;
        }
        case SDL_EVENT_GAMEPAD_ADDED:
        case SDL_EVENT_GAMEPAD_REMOVED:
        {
            bd.WantUpdateGamepadsList = true;
            return true;
        }
    }
    return false;
}

ImGui_ImplSDL3_SetupPlatformHandles :: proc(viewport : ^ImGuiViewport, window : ^SDL_Window)
{
    viewport.PlatformHandle = cast(rawptr) (rawptr)SDL_GetWindowID(window);
    viewport.PlatformHandleRaw = nullptr;
when defined(_WIN32) && !defined(__WINRT__) {
    viewport.PlatformHandleRaw = (HWND)SDL_GetPointerProperty(SDL_GetWindowProperties(window), SDL_PROP_WINDOW_WIN32_HWND_POINTER, nullptr);
} else when defined(__APPLE__) && defined(SDL_VIDEO_DRIVER_COCOA) {
    viewport.PlatformHandleRaw = SDL_GetPointerProperty(SDL_GetWindowProperties(window), SDL_PROP_WINDOW_COCOA_WINDOW_POINTER, nullptr);
}
}

ImGui_ImplSDL3_Init :: proc(window : ^SDL_Window, renderer : ^SDL_Renderer, sdl_gl_context : rawptr) -> bool
{
    io := GetIO();
    IMGUI_CHECKVERSION();
    assert(io.BackendPlatformUserData == nullptr, "Already initialized a platform backend!");
    _ = sdl_gl_context; // Unused in this branch

    // Check and store if we are on a SDL backend that supports global mouse position
    // ("wayland" and "rpi" don't support it, but we chose to use a white-list instead of a black-list)
    mouse_can_use_global_state := false;
when SDL_HAS_CAPTURE_AND_GLOBAL_MOUSE {
    sdl_backend := SDL_GetCurrentVideoDriver();
    const u8* global_mouse_whitelist[] = { "windows", "cocoa", "x11", "DIVE", "VMAN" };
    for n := 0; n < len(global_mouse_whitelist); n += 1
        if (strncmp(sdl_backend, global_mouse_whitelist[n], strlen(global_mouse_whitelist[n])) == 0) {
            mouse_can_use_global_state = true;
        }

}

    // Setup backend capabilities flags
    bd := IM_NEW(ImGui_ImplSDL3_Data)();
    io.BackendPlatformUserData = cast(rawptr) bd;
    io.BackendPlatformName = "imgui_impl_sdl3";
    io.BackendFlags |= ImGuiBackendFlags_HasMouseCursors;           // We can honor GetMouseCursor() values (optional)
    io.BackendFlags |= ImGuiBackendFlags_HasSetMousePos;            // We can honor io.WantSetMousePos requests (optional, rarely used)
    if (mouse_can_use_global_state)
        io.BackendFlags |= ImGuiBackendFlags_PlatformHasViewports;  // We can create multi-viewports on the Platform side (optional)

    bd.Window = window;
    bd.WindowID = SDL_GetWindowID(window);
    bd.Renderer = renderer;

    // SDL on Linux/OSX doesn't report events for unfocused windows (see https://github.com/ocornut/imgui/issues/4960)
    // We will use 'MouseCanReportHoveredViewport' to set 'ImGuiBackendFlags_HasMouseHoveredViewport' dynamically each frame.
    bd.MouseCanUseGlobalState = mouse_can_use_global_state;
when !(__APPLE__) {
    bd.MouseCanReportHoveredViewport = bd.MouseCanUseGlobalState;
} else {
    bd.MouseCanReportHoveredViewport = false;
}

    platform_io := &GetPlatformIO();
    platform_io.Platform_SetClipboardTextFn = ImGui_ImplSDL3_SetClipboardText;
    platform_io.Platform_GetClipboardTextFn = ImGui_ImplSDL3_GetClipboardText;
    platform_io.Platform_SetImeDataFn = ImGui_ImplSDL3_PlatformSetImeData;

    // Update monitor a first time during init
    ImGui_ImplSDL3_UpdateMonitors();

    // Gamepad handling
    bd.GamepadMode = ImGui_ImplSDL3_GamepadMode_AutoFirst;
    bd.WantUpdateGamepadsList = true;

    // Load mouse cursors
    bd.MouseCursors[ImGuiMouseCursor_Arrow] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_DEFAULT);
    bd.MouseCursors[ImGuiMouseCursor_TextInput] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_TEXT);
    bd.MouseCursors[ImGuiMouseCursor_ResizeAll] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_MOVE);
    bd.MouseCursors[ImGuiMouseCursor_ResizeNS] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_NS_RESIZE);
    bd.MouseCursors[ImGuiMouseCursor_ResizeEW] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_EW_RESIZE);
    bd.MouseCursors[ImGuiMouseCursor_ResizeNESW] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_NESW_RESIZE);
    bd.MouseCursors[ImGuiMouseCursor_ResizeNWSE] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_NWSE_RESIZE);
    bd.MouseCursors[ImGuiMouseCursor_Hand] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_POINTER);
    bd.MouseCursors[ImGuiMouseCursor_NotAllowed] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_NOT_ALLOWED);

    // Set platform dependent data in viewport
    // Our mouse update function expect PlatformHandle to be filled for the main viewport
    main_viewport := GetMainViewport();
    ImGui_ImplSDL3_SetupPlatformHandles(main_viewport, window);

    // From 2.0.5: Set SDL hint to receive mouse click events on window focus, otherwise SDL doesn't emit the event.
    // Without this, when clicking to gain focus, our widgets wouldn't activate even though they showed as hovered.
    // (This is unfortunately a global SDL setting, so enabling it might have a side-effect on your application.
    // It is unlikely to make a difference, but if your app absolutely needs to ignore the initial on-focus click:
    // you can ignore SDL_EVENT_MOUSE_BUTTON_DOWN events coming right after a SDL_WINDOWEVENT_FOCUS_GAINED)
    SDL_SetHint(SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH, "1");

    // From 2.0.22: Disable auto-capture, this is preventing drag and drop across multiple windows (see #5710)
    SDL_SetHint(SDL_HINT_MOUSE_AUTO_CAPTURE, "0");

    // SDL 3.x : see https://github.com/libsdl-org/SDL/issues/6659
    SDL_SetHint("SDL_BORDERLESS_WINDOWED_STYLE", "0");

    // We need SDL_CaptureMouse(), SDL_GetGlobalMouseState() from SDL 2.0.4+ to support multiple viewports.
    // We left the call to ImGui_ImplSDL3_InitPlatformInterface() outside of #ifdef to avoid unused-function warnings.
    if (.PlatformHasViewports in io.BackendFlags)
        ImGui_ImplSDL3_InitMultiViewportSupport(window, sdl_gl_context);

    return true;
}

// Should technically be a SDL_GLContext but due to typedef it is sane to keep it void* in public interface.
ImGui_ImplSDL3_InitForOpenGL :: proc(window : ^SDL_Window, sdl_gl_context : rawptr) -> bool
{
    return ImGui_ImplSDL3_Init(window, nullptr, sdl_gl_context);
}

ImGui_ImplSDL3_InitForVulkan :: proc(window : ^SDL_Window) -> bool
{
    if (!ImGui_ImplSDL3_Init(window, nullptr, nullptr))   do return false
    bd := ImGui_ImplSDL3_GetBackendData();
    bd.UseVulkan = true;
    return true;
}

ImGui_ImplSDL3_InitForD3D :: proc(window : ^SDL_Window) -> bool
{
when !defined(_WIN32) {
    assert(false, "Unsupported");
}
    return ImGui_ImplSDL3_Init(window, nullptr, nullptr);
}

ImGui_ImplSDL3_InitForMetal :: proc(window : ^SDL_Window) -> bool
{
    return ImGui_ImplSDL3_Init(window, nullptr, nullptr);
}

ImGui_ImplSDL3_InitForSDLRenderer :: proc(window : ^SDL_Window, renderer : ^SDL_Renderer) -> bool
{
    return ImGui_ImplSDL3_Init(window, renderer, nullptr);
}

ImGui_ImplSDL3_InitForSDLGPU :: proc(window : ^SDL_Window) -> bool
{
    return ImGui_ImplSDL3_Init(window, nullptr, nullptr);
}

ImGui_ImplSDL3_InitForOther :: proc(window : ^SDL_Window) -> bool
{
    return ImGui_ImplSDL3_Init(window, nullptr, nullptr);
}

void ImGui_ImplSDL3_CloseGamepads();

ImGui_ImplSDL3_Shutdown :: proc()
{
    bd := ImGui_ImplSDL3_GetBackendData();
    assert(bd != nullptr, "No platform backend to shutdown, or already shutdown?");
    io := GetIO();

    ImGui_ImplSDL3_ShutdownMultiViewportSupport();

    if (bd.ClipboardTextData) {
        SDL_free(bd.ClipboardTextData);
    }

    for ImGuiMouseCursor cursor_n = 0; cursor_n < ImGuiMouseCursor_COUNT; cursor_n += 1
        SDL_DestroyCursor(bd.MouseCursors[cursor_n]);
    ImGui_ImplSDL3_CloseGamepads();

    io.BackendPlatformName = nullptr;
    io.BackendPlatformUserData = nullptr;
    io.BackendFlags &= ~(ImGuiBackendFlags_HasMouseCursors | ImGuiBackendFlags_HasSetMousePos | ImGuiBackendFlags_HasGamepad | ImGuiBackendFlags_PlatformHasViewports | ImGuiBackendFlags_HasMouseHoveredViewport);
    IM_DELETE(bd);
}

// This code is incredibly messy because some of the functions we need for full viewport support are not available in SDL < 2.0.4.
ImGui_ImplSDL3_UpdateMouseData :: proc()
{
    bd := ImGui_ImplSDL3_GetBackendData();
    io := GetIO();

    // We forward mouse input when hovered or captured (via SDL_EVENT_MOUSE_MOTION) or when focused (below)
when SDL_HAS_CAPTURE_AND_GLOBAL_MOUSE {
    // SDL_CaptureMouse() let the OS know e.g. that our imgui drag outside the SDL window boundaries shouldn't e.g. trigger other operations outside
    SDL_CaptureMouse(bd.MouseButtonsDown != 0);
    focused_window := SDL_GetKeyboardFocus();
    is_app_focused := (focused_window && (bd.Window == focused_window || ImGui_ImplSDL3_GetViewportForWindowID(SDL_GetWindowID(focused_window)) != nil));
} else {
    focused_window := bd.Window;
    is_app_focused := (SDL_GetWindowFlags(bd.Window) & SDL_WINDOW_INPUT_FOCUS) != 0; // SDL 2.0.3 and non-windowed systems: single-viewport only
}
    if (is_app_focused)
    {
        // (Optional) Set OS mouse position from Dear ImGui if requested (rarely used, only when io.ConfigNavMoveSetMousePos is enabled by user)
        if (io.WantSetMousePos)
        {
when SDL_HAS_CAPTURE_AND_GLOBAL_MOUSE {
            if (.ViewportsEnable in io.ConfigFlags) {
                SDL_WarpMouseGlobal(io.MousePos.x, io.MousePos.y);
            }

            else
}
                SDL_WarpMouseInWindow(bd.Window, io.MousePos.x, io.MousePos.y);
        }

        // (Optional) Fallback to provide mouse position when focused (SDL_EVENT_MOUSE_MOTION already provides this when hovered or captured)
        if (bd.MouseCanUseGlobalState && bd.MouseButtonsDown == 0)
        {
            // Single-viewport mode: mouse position in client window coordinates (io.MousePos is (0,0) when the mouse is on the upper-left corner of the app window)
            // Multi-viewport mode: mouse position in OS absolute coordinates (io.MousePos is (0,0) when the mouse is on the upper-left of the primary monitor)
            mouse_x, mouse_y : f32
            window_x, window_y : i32
            SDL_GetGlobalMouseState(&mouse_x, &mouse_y);
            if (!(.ViewportsEnable in io.ConfigFlags))
            {
                SDL_GetWindowPosition(focused_window, &window_x, &window_y);
                mouse_x -= window_x;
                mouse_y -= window_y;
            }
            io.AddMousePosEvent(cast(f32) mouse_x, cast(f32) mouse_y);
        }
    }

    // (Optional) When using multiple viewports: call io.AddMouseViewportEvent() with the viewport the OS mouse cursor is hovering.
    // If ImGuiBackendFlags_HasMouseHoveredViewport is not set by the backend, Dear imGui will ignore this field and infer the information using its flawed heuristic.
    // - [!] SDL backend does NOT correctly ignore viewports with the _NoInputs flag.
    //       Some backend are not able to handle that correctly. If a backend report an hovered viewport that has the _NoInputs flag (e.g. when dragging a window
    //       for docking, the viewport has the _NoInputs flag in order to allow us to find the viewport under), then Dear ImGui is forced to ignore the value reported
    //       by the backend, and use its flawed heuristic to guess the viewport behind.
    // - [X] SDL backend correctly reports this regardless of another viewport behind focused and dragged from (we need this to find a useful drag and drop target).
    if (.HasMouseHoveredViewport in io.BackendFlags)
    {
        mouse_viewport_id := 0;
        if (ImGuiViewport* mouse_viewport = ImGui_ImplSDL3_GetViewportForWindowID(bd.MouseWindowID)) {
            mouse_viewport_id = mouse_viewport.ID;
        }

        io.AddMouseViewportEvent(mouse_viewport_id);
    }
}

ImGui_ImplSDL3_UpdateMouseCursor :: proc()
{
    io := GetIO();
    if (.NoMouseCursorChange in io.ConfigFlags)   do return
    bd := ImGui_ImplSDL3_GetBackendData();

    imgui_cursor := GetMouseCursor();
    if (io.MouseDrawCursor || imgui_cursor == ImGuiMouseCursor_None)
    {
        // Hide OS mouse cursor if imgui is drawing it or if it wants no cursor
        SDL_HideCursor();
    }
    else
    {
        // Show OS mouse cursor
        expected_cursor := bd.MouseCursors[imgui_cursor] ? bd.MouseCursors[imgui_cursor] : bd.MouseCursors[ImGuiMouseCursor_Arrow];
        if (bd.MouseLastCursor != expected_cursor)
        {
            SDL_SetCursor(expected_cursor); // SDL function doesn't have an early out (see #6113)
            bd.MouseLastCursor = expected_cursor;
        }
        SDL_ShowCursor();
    }
}

ImGui_ImplSDL3_CloseGamepads :: proc()
{
    bd := ImGui_ImplSDL3_GetBackendData();
    if (bd.GamepadMode != ImGui_ImplSDL3_GamepadMode_Manual) {
        for gamepad in bd.Gamepads
    }

            SDL_CloseGamepad(gamepad);
    bd.Gamepads.resize(0);
}

ImGui_ImplSDL3_SetGamepadMode :: proc(mode : ImGui_ImplSDL3_GamepadMode, manual_gamepads_array : ^^SDL_Gamepad, manual_gamepads_count : i32)
{
    bd := ImGui_ImplSDL3_GetBackendData();
    ImGui_ImplSDL3_CloseGamepads();
    if (mode == ImGui_ImplSDL3_GamepadMode_Manual)
    {
        assert(manual_gamepads_array != nullptr && manual_gamepads_count > 0);
        for n := 0; n < manual_gamepads_count; n += 1
            bd.Gamepads.append(manual_gamepads_array[n]);
    }
    else
    {
        assert(manual_gamepads_array == nullptr && manual_gamepads_count <= 0);
        bd.WantUpdateGamepadsList = true;
    }
    bd.GamepadMode = mode;
}

ImGui_ImplSDL3_UpdateGamepadButton :: proc(bd : ^ImGui_ImplSDL3_Data, io : ^ImGuiIO, key : ImGuiKey, button_no : SDL_GamepadButton)
{
    merged_value := false;
    for gamepad in bd.Gamepads
        merged_value |= SDL_GetGamepadButton(gamepad, button_no) != 0;
    io.AddKeyEvent(key, merged_value);
}

inline f32 Saturate(f32 v) { return v < 0.0 ? 0.0 : v  > 1.0 ? 1.0 : v; }
ImGui_ImplSDL3_UpdateGamepadAnalog :: proc(bd : ^ImGui_ImplSDL3_Data, io : ^ImGuiIO, key : ImGuiKey, axis_no : SDL_GamepadAxis, v0 : f32, v1 : f32)
{
    merged_value := 0.0;
    for gamepad in bd.Gamepads
    {
        vn := Saturate((f32)(SDL_GetGamepadAxis(gamepad, axis_no) - v0) / (f32)(v1 - v0));
        if (merged_value < vn)   do merged_value = vn
    }
    io.AddKeyAnalogEvent(key, merged_value > 0.1, merged_value);
}

ImGui_ImplSDL3_UpdateGamepads :: proc()
{
    io := GetIO();
    bd := ImGui_ImplSDL3_GetBackendData();

    // Update list of gamepads to use
    if (bd.WantUpdateGamepadsList && bd.GamepadMode != ImGui_ImplSDL3_GamepadMode_Manual)
    {
        ImGui_ImplSDL3_CloseGamepads();
        sdl_gamepads_count := 0;
        sdl_gamepads := SDL_GetGamepads(&sdl_gamepads_count);
        for n := 0; n < sdl_gamepads_count; n += 1
            if (SDL_Gamepad* gamepad = SDL_OpenGamepad(sdl_gamepads[n]))
            {
                bd.Gamepads.append(gamepad);
                if (bd.GamepadMode == ImGui_ImplSDL3_GamepadMode_AutoFirst)   do break
            }
        bd.WantUpdateGamepadsList = false;
        SDL_free(sdl_gamepads);
    }

    // FIXME: Technically feeding gamepad shouldn't depend on this now that they are regular inputs.
    if ((.NavEnableGamepad not_in io.ConfigFlags))   do return
    io.BackendFlags &= ~ImGuiBackendFlags_HasGamepad;
    if (len(bd.Gamepads) == 0)   do return
    io.BackendFlags |= ImGuiBackendFlags_HasGamepad;

    // Update gamepad inputs
    thumb_dead_zone := 8000;           // SDL_gamepad.h suggests using this value.
    ImGui_ImplSDL3_UpdateGamepadButton(bd, io, ImGuiKey.GamepadStart,       SDL_GAMEPAD_BUTTON_START);
    ImGui_ImplSDL3_UpdateGamepadButton(bd, io, ImGuiKey.GamepadBack,        SDL_GAMEPAD_BUTTON_BACK);
    ImGui_ImplSDL3_UpdateGamepadButton(bd, io, ImGuiKey.GamepadFaceLeft,    SDL_GAMEPAD_BUTTON_WEST);           // Xbox X, PS Square
    ImGui_ImplSDL3_UpdateGamepadButton(bd, io, ImGuiKey.GamepadFaceRight,   SDL_GAMEPAD_BUTTON_EAST);           // Xbox B, PS Circle
    ImGui_ImplSDL3_UpdateGamepadButton(bd, io, ImGuiKey.GamepadFaceUp,      SDL_GAMEPAD_BUTTON_NORTH);          // Xbox Y, PS Triangle
    ImGui_ImplSDL3_UpdateGamepadButton(bd, io, ImGuiKey.GamepadFaceDown,    SDL_GAMEPAD_BUTTON_SOUTH);          // Xbox A, PS Cross
    ImGui_ImplSDL3_UpdateGamepadButton(bd, io, ImGuiKey.GamepadDpadLeft,    SDL_GAMEPAD_BUTTON_DPAD_LEFT);
    ImGui_ImplSDL3_UpdateGamepadButton(bd, io, ImGuiKey.GamepadDpadRight,   SDL_GAMEPAD_BUTTON_DPAD_RIGHT);
    ImGui_ImplSDL3_UpdateGamepadButton(bd, io, ImGuiKey.GamepadDpadUp,      SDL_GAMEPAD_BUTTON_DPAD_UP);
    ImGui_ImplSDL3_UpdateGamepadButton(bd, io, ImGuiKey.GamepadDpadDown,    SDL_GAMEPAD_BUTTON_DPAD_DOWN);
    ImGui_ImplSDL3_UpdateGamepadButton(bd, io, ImGuiKey.GamepadL1,          SDL_GAMEPAD_BUTTON_LEFT_SHOULDER);
    ImGui_ImplSDL3_UpdateGamepadButton(bd, io, ImGuiKey.GamepadR1,          SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER);
    ImGui_ImplSDL3_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadL2,          SDL_GAMEPAD_AXIS_LEFT_TRIGGER,  0.0, 32767);
    ImGui_ImplSDL3_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadR2,          SDL_GAMEPAD_AXIS_RIGHT_TRIGGER, 0.0, 32767);
    ImGui_ImplSDL3_UpdateGamepadButton(bd, io, ImGuiKey.GamepadL3,          SDL_GAMEPAD_BUTTON_LEFT_STICK);
    ImGui_ImplSDL3_UpdateGamepadButton(bd, io, ImGuiKey.GamepadR3,          SDL_GAMEPAD_BUTTON_RIGHT_STICK);
    ImGui_ImplSDL3_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadLStickLeft,  SDL_GAMEPAD_AXIS_LEFTX,  -thumb_dead_zone, -32768);
    ImGui_ImplSDL3_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadLStickRight, SDL_GAMEPAD_AXIS_LEFTX,  +thumb_dead_zone, +32767);
    ImGui_ImplSDL3_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadLStickUp,    SDL_GAMEPAD_AXIS_LEFTY,  -thumb_dead_zone, -32768);
    ImGui_ImplSDL3_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadLStickDown,  SDL_GAMEPAD_AXIS_LEFTY,  +thumb_dead_zone, +32767);
    ImGui_ImplSDL3_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadRStickLeft,  SDL_GAMEPAD_AXIS_RIGHTX, -thumb_dead_zone, -32768);
    ImGui_ImplSDL3_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadRStickRight, SDL_GAMEPAD_AXIS_RIGHTX, +thumb_dead_zone, +32767);
    ImGui_ImplSDL3_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadRStickUp,    SDL_GAMEPAD_AXIS_RIGHTY, -thumb_dead_zone, -32768);
    ImGui_ImplSDL3_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadRStickDown,  SDL_GAMEPAD_AXIS_RIGHTY, +thumb_dead_zone, +32767);
}

ImGui_ImplSDL3_UpdateMonitors :: proc()
{
    bd := ImGui_ImplSDL3_GetBackendData();
    platform_io := &GetPlatformIO();
    platform_io.Monitors.resize(0);
    bd.WantUpdateMonitors = false;

    display_count : i32
    displays := SDL_GetDisplays(&display_count);
    for n := 0; n < display_count; n += 1
    {
        // Warning: the validity of monitor DPI information on Windows depends on the application DPI awareness settings, which generally needs to be set in the manifest or at runtime.
        display_id := displays[n];
        monitor : ImGuiPlatformMonitor
        r : SDL_Rect
        SDL_GetDisplayBounds(display_id, &r);
        monitor.MainPos = monitor.WorkPos = ImVec2{(f32}r.x, cast(f32) r.y);
        monitor.MainSize = monitor.WorkSize = ImVec2{(f32}r.w, cast(f32) r.h);
        SDL_GetDisplayUsableBounds(display_id, &r);
        monitor.WorkPos = ImVec2{(f32}r.x, cast(f32) r.y);
        monitor.WorkSize = ImVec2{(f32}r.w, cast(f32) r.h);
        // FIXME-VIEWPORT: On MacOS SDL reports actual monitor DPI scale, ignoring OS configuration. We may want to set
        //  DpiScale to cocoa_window.backingScaleFactor here.
        monitor.DpiScale = SDL_GetDisplayContentScale(display_id);
        monitor.PlatformHandle = cast(rawptr) (rawptr)n;
        if (monitor.DpiScale <= 0.0) {
            continue; // Some accessibility applications are declaring virtual monitors with a DPI of 0, see #7902.
        }

        platform_io.Monitors.append(monitor);
    }
    SDL_free(displays);
}

ImGui_ImplSDL3_NewFrame :: proc()
{
    bd := ImGui_ImplSDL3_GetBackendData();
    assert(bd != nullptr, "Context or backend not initialized! Did you call ImGui_ImplSDL3_Init()?");
    io := GetIO();

    // Setup display size (every frame to accommodate for window resizing)
    w, h : i32
    display_w, display_h : i32
    SDL_GetWindowSize(bd.Window, &w, &h);
    if (SDL_GetWindowFlags(bd.Window) & SDL_WINDOW_MINIMIZED)   do w = h = 0
    SDL_GetWindowSizeInPixels(bd.Window, &display_w, &display_h);
    io.DisplaySize = ImVec2{(f32}w, cast(f32) h);
    if (w > 0 && h > 0)
        io.DisplayFramebufferScale = ImVec2{(f32}display_w / w, cast(f32) display_h / h);

    // Update monitors
    if (bd.WantUpdateMonitors)
        ImGui_ImplSDL3_UpdateMonitors();

    // Setup time step (we don't use SDL_GetTicks() because it is using millisecond resolution)
    // (Accept SDL_GetPerformanceCounter() not returning a monotonically increasing value. Happens in VMs and Emscripten, see #6189, #6114, #3644)
    static Uint64 frequency = SDL_GetPerformanceFrequency();
    current_time := SDL_GetPerformanceCounter();
    if (current_time <= bd.Time) {
        current_time = bd.Time + 1;
    }

    io.DeltaTime = bd.Time > 0 ? (f32)((f64)(current_time - bd.Time) / frequency) : (f32)(1.0 / 60.0);
    bd.Time = current_time;

    if (bd.MousePendingLeaveFrame && bd.MousePendingLeaveFrame >= GetFrameCount() && bd.MouseButtonsDown == 0)
    {
        bd.MouseWindowID = 0;
        bd.MousePendingLeaveFrame = 0;
        io.AddMousePosEvent(-math.F32_MAX, -math.F32_MAX);
    }

    // Our io.AddMouseViewportEvent() calls will only be valid when not capturing.
    // Technically speaking testing for 'bd.MouseButtonsDown == 0' would be more rigorous, but testing for payload reduces noise and potential side-effects.
    if (bd.MouseCanReportHoveredViewport && GetDragDropPayload() == nullptr)
        io.BackendFlags |= ImGuiBackendFlags_HasMouseHoveredViewport;
    else
        io.BackendFlags &= ~ImGuiBackendFlags_HasMouseHoveredViewport;

    ImGui_ImplSDL3_UpdateMouseData();
    ImGui_ImplSDL3_UpdateMouseCursor();

    // Update game controllers (if enabled and available)
    ImGui_ImplSDL3_UpdateGamepads();
}

//--------------------------------------------------------------------------------------------------------
// MULTI-VIEWPORT / PLATFORM INTERFACE SUPPORT
// This is an _advanced_ and _optional_ feature, allowing the backend to create and handle multiple viewports simultaneously.
// If you are new to dear imgui or creating a new binding for dear imgui, it is recommended that you completely ignore this section first..
//--------------------------------------------------------------------------------------------------------

// Helper structure we store in the void* RendererUserData field of each ImGuiViewport to easily retrieve our backend data.
ImGui_ImplSDL3_ViewportData :: struct
{
    Window : ^SDL_Window,
    ParentWindow : ^SDL_Window,
    WindowID : Uint32,
    WindowOwned : bool,
    GLContext : SDL_GLContext,

    ImGui_ImplSDL3_ViewportData() { Window = ParentWindow = nullptr; WindowID = 0; WindowOwned = false; GLContext = nullptr; }
    ~ImGui_ImplSDL3_ViewportData() { assert(Window == nullptr && GLContext == nullptr); }
};

ImGui_ImplSDL3_GetSDLWindowFromViewportID :: proc(viewport_id : ImGuiID) -> ^SDL_Window
{
    if (viewport_id != 0)
        if (ImGuiViewport* viewport = FindViewportByID(viewport_id))
        {
            window_id := (SDL_WindowID)(rawptr)viewport.PlatformHandle;
            return SDL_GetWindowFromID(window_id);
        }
    return nullptr;
}

ImGui_ImplSDL3_CreateWindow :: proc(viewport : ^ImGuiViewport)
{
    bd := ImGui_ImplSDL3_GetBackendData();
    vd := IM_NEW(ImGui_ImplSDL3_ViewportData)();
    viewport.PlatformUserData = vd;

    vd.ParentWindow = ImGui_ImplSDL3_GetSDLWindowFromViewportID(viewport.ParentViewportId);

    main_viewport := GetMainViewport();
    main_viewport_data := (ImGui_ImplSDL3_ViewportData*)main_viewport.PlatformUserData;

    // Share GL resources with main context
    use_opengl := (main_viewport_data.GLContext != nullptr);
    backup_context := nullptr;
    if (use_opengl)
    {
        backup_context = SDL_GL_GetCurrentContext();
        SDL_GL_SetAttribute(SDL_GL_SHARE_WITH_CURRENT_CONTEXT, 1);
        SDL_GL_MakeCurrent(main_viewport_data.Window, main_viewport_data.GLContext);
    }

    sdl_flags := 0;
    sdl_flags |= use_opengl ? SDL_WINDOW_OPENGL : (bd.UseVulkan ? SDL_WINDOW_VULKAN : 0);
    sdl_flags |= SDL_GetWindowFlags(bd.Window) & SDL_WINDOW_HIGH_PIXEL_DENSITY;
    sdl_flags |= (.NoDecoration in viewport.Flags) ? SDL_WINDOW_BORDERLESS : 0;
    sdl_flags |= (.NoDecoration in viewport.Flags) ? 0 : SDL_WINDOW_RESIZABLE;
    sdl_flags |= (.NoTaskBarIcon in viewport.Flags) ? SDL_WINDOW_UTILITY : 0;
    sdl_flags |= (.TopMost in viewport.Flags) ? SDL_WINDOW_ALWAYS_ON_TOP : 0;
    vd.Window = SDL_CreateWindow("No Title Yet", cast(i32) viewport.Size.x, cast(i32) viewport.Size.y, sdl_flags);
    SDL_SetWindowParent(vd.Window, vd.ParentWindow);
    SDL_SetWindowPosition(vd.Window, cast(i32) viewport.Pos.x, cast(i32) viewport.Pos.y);
    vd.WindowOwned = true;
    if (use_opengl)
    {
        vd.GLContext = SDL_GL_CreateContext(vd.Window);
        SDL_GL_SetSwapInterval(0);
    }
    if (use_opengl && backup_context) {
        SDL_GL_MakeCurrent(vd.Window, backup_context);
    }

    ImGui_ImplSDL3_SetupPlatformHandles(viewport, vd.Window);
}

ImGui_ImplSDL3_DestroyWindow :: proc(viewport : ^ImGuiViewport)
{
    if (ImGui_ImplSDL3_ViewportData* vd = (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData)
    {
        if (vd.GLContext && vd.WindowOwned) {
            SDL_GL_DestroyContext(vd.GLContext);
        }

        if (vd.Window && vd.WindowOwned) {
            SDL_DestroyWindow(vd.Window);
        }

        vd.GLContext = nullptr;
        vd.Window = nullptr;
        IM_DELETE(vd);
    }
    viewport.PlatformUserData = viewport.PlatformHandle = nullptr;
}

ImGui_ImplSDL3_ShowWindow :: proc(viewport : ^ImGuiViewport)
{
    vd := (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData;
when defined(_WIN32) && !(defined(WINAPI_FAMILY) && (WINAPI_FAMILY == WINAPI_FAMILY_APP || WINAPI_FAMILY == WINAPI_FAMILY_GAMES)) {
    hwnd := (HWND)viewport.PlatformHandleRaw;

    // SDL hack: Show icon in task bar (#7989)
    // Note: SDL_WINDOW_UTILITY can be used to control task bar visibility, but on Windows, it does not affect child windows.
    if (!(.NoTaskBarIcon in viewport.Flags))
    {
        ex_style := ::GetWindowLong(hwnd, GWL_EXSTYLE);
        ex_style |= WS_EX_APPWINDOW;
        ex_style &= ~WS_EX_TOOLWINDOW;
        ::ShowWindow(hwnd, SW_HIDE);
        ::SetWindowLong(hwnd, GWL_EXSTYLE, ex_style);
    }
}

    SDL_SetHint(SDL_HINT_WINDOW_ACTIVATE_WHEN_SHOWN, (.NoFocusOnAppearing in viewport.Flags) ? "0" : "1");
    SDL_ShowWindow(vd.Window);
}

ImGui_ImplSDL3_UpdateWindow :: proc(viewport : ^ImGuiViewport)
{
    vd := (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData;

    // Update SDL3 parent if it changed _after_ creation.
    // This is for advanced apps that are manipulating ParentViewportID manually.
    new_parent := ImGui_ImplSDL3_GetSDLWindowFromViewportID(viewport.ParentViewportId);
    if (new_parent != vd.ParentWindow)
    {
        vd.ParentWindow = new_parent;
        SDL_SetWindowParent(vd.Window, vd.ParentWindow);
    }
}

ImGui_ImplSDL3_GetWindowPos :: proc(viewport : ^ImGuiViewport) -> ImVec2
{
    vd := (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData;
    x := 0, y = 0;
    SDL_GetWindowPosition(vd.Window, &x, &y);
    return ImVec2{(f32}x, cast(f32) y);
}

ImGui_ImplSDL3_SetWindowPos :: proc(viewport : ^ImGuiViewport, pos : ImVec2)
{
    vd := (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData;
    SDL_SetWindowPosition(vd.Window, cast(i32) pos.x, cast(i32) pos.y);
}

ImGui_ImplSDL3_GetWindowSize :: proc(viewport : ^ImGuiViewport) -> ImVec2
{
    vd := (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData;
    w := 0, h = 0;
    SDL_GetWindowSize(vd.Window, &w, &h);
    return ImVec2{(f32}w, cast(f32) h);
}

ImGui_ImplSDL3_SetWindowSize :: proc(viewport : ^ImGuiViewport, size : ImVec2)
{
    vd := (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData;
    SDL_SetWindowSize(vd.Window, cast(i32) size.x, cast(i32) size.y);
}

ImGui_ImplSDL3_SetWindowTitle :: proc(viewport : ^ImGuiViewport, title : ^u8)
{
    vd := (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData;
    SDL_SetWindowTitle(vd.Window, title);
}

ImGui_ImplSDL3_SetWindowAlpha :: proc(viewport : ^ImGuiViewport, alpha : f32)
{
    vd := (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData;
    SDL_SetWindowOpacity(vd.Window, alpha);
}

ImGui_ImplSDL3_SetWindowFocus :: proc(viewport : ^ImGuiViewport)
{
    vd := (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData;
    SDL_RaiseWindow(vd.Window);
}

ImGui_ImplSDL3_GetWindowFocus :: proc(viewport : ^ImGuiViewport) -> bool
{
    vd := (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData;
    return (SDL_GetWindowFlags(vd.Window) & SDL_WINDOW_INPUT_FOCUS) != 0;
}

ImGui_ImplSDL3_GetWindowMinimized :: proc(viewport : ^ImGuiViewport) -> bool
{
    vd := (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData;
    return (SDL_GetWindowFlags(vd.Window) & SDL_WINDOW_MINIMIZED) != 0;
}

ImGui_ImplSDL3_RenderWindow :: proc(viewport : ^ImGuiViewport, rawptr)
{
    vd := (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData;
    if (vd.GLContext) {
        SDL_GL_MakeCurrent(vd.Window, vd.GLContext);
    }

}

ImGui_ImplSDL3_SwapBuffers :: proc(viewport : ^ImGuiViewport, rawptr)
{
    vd := (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData;
    if (vd.GLContext)
    {
        SDL_GL_MakeCurrent(vd.Window, vd.GLContext);
        SDL_GL_SwapWindow(vd.Window);
    }
}

// Vulkan support (the Vulkan renderer needs to call a platform-side support function to create the surface)
// SDL is graceful enough to _not_ need <vulkan/vulkan.h> so we can safely include this.
ImGui_ImplSDL3_CreateVkSurface :: proc(viewport : ^ImGuiViewport, vk_instance : u64, vk_allocator : rawptr, out_vk_surface : ^u64) -> i32
{
    vd := (ImGui_ImplSDL3_ViewportData*)viewport.PlatformUserData;
    (void)vk_allocator;
    ret := SDL_Vulkan_CreateSurface(vd.Window, (VkInstance)vk_instance, (VkAllocationCallbacks*)vk_allocator, (VkSurfaceKHR*)out_vk_surface);
    return ret ? 0 : 1; // ret ? VK_SUCCESS : VK_NOT_READY
}

ImGui_ImplSDL3_InitMultiViewportSupport :: proc(window : ^SDL_Window, sdl_gl_context : rawptr)
{
    // Register platform interface (will be coupled with a renderer interface)
    platform_io := &GetPlatformIO();
    platform_io.Platform_CreateWindow = ImGui_ImplSDL3_CreateWindow;
    platform_io.Platform_DestroyWindow = ImGui_ImplSDL3_DestroyWindow;
    platform_io.Platform_ShowWindow = ImGui_ImplSDL3_ShowWindow;
    platform_io.Platform_UpdateWindow = ImGui_ImplSDL3_UpdateWindow;
    platform_io.Platform_SetWindowPos = ImGui_ImplSDL3_SetWindowPos;
    platform_io.Platform_GetWindowPos = ImGui_ImplSDL3_GetWindowPos;
    platform_io.Platform_SetWindowSize = ImGui_ImplSDL3_SetWindowSize;
    platform_io.Platform_GetWindowSize = ImGui_ImplSDL3_GetWindowSize;
    platform_io.Platform_SetWindowFocus = ImGui_ImplSDL3_SetWindowFocus;
    platform_io.Platform_GetWindowFocus = ImGui_ImplSDL3_GetWindowFocus;
    platform_io.Platform_GetWindowMinimized = ImGui_ImplSDL3_GetWindowMinimized;
    platform_io.Platform_SetWindowTitle = ImGui_ImplSDL3_SetWindowTitle;
    platform_io.Platform_RenderWindow = ImGui_ImplSDL3_RenderWindow;
    platform_io.Platform_SwapBuffers = ImGui_ImplSDL3_SwapBuffers;
    platform_io.Platform_SetWindowAlpha = ImGui_ImplSDL3_SetWindowAlpha;
    platform_io.Platform_CreateVkSurface = ImGui_ImplSDL3_CreateVkSurface;

    // Register main window handle (which is owned by the main application, not by us)
    // This is mostly for simplicity and consistency, so that our code (e.g. mouse handling etc.) can use same logic for main and secondary viewports.
    main_viewport := GetMainViewport();
    vd := IM_NEW(ImGui_ImplSDL3_ViewportData)();
    vd.Window = window;
    vd.WindowID = SDL_GetWindowID(window);
    vd.WindowOwned = false;
    vd.GLContext = (SDL_GLContext)sdl_gl_context;
    main_viewport.PlatformUserData = vd;
    main_viewport.PlatformHandle = cast(rawptr) (rawptr)vd.WindowID;
}

ImGui_ImplSDL3_ShutdownMultiViewportSupport :: proc()
{
    DestroyPlatformWindows();
}

//-----------------------------------------------------------------------------


} // #ifndef IMGUI_DISABLE
