package imgui

// dear imgui: Platform Backend for SDL2
// This needs to be used along with a Renderer (e.g. DirectX11, OpenGL3, Vulkan..)
// (Info: SDL2 is a cross-platform general purpose library for handling windows, inputs, graphics context creation, etc.)
// (Prefer SDL 2.0.5+ for full feature support.)

// Implemented features:
//  [X] Platform: Clipboard support.
//  [X] Platform: Mouse support. Can discriminate Mouse/TouchScreen.
//  [X] Platform: Keyboard support. Since 1.87 we are using the io.AddKeyEvent() function. Pass ImGuiKey values to all key functions e.g. ImGui::IsKeyPressed(ImGuiKey.Space). [Legacy SDL_SCANCODE_* values are obsolete since 1.87 and not supported since 1.91.5]
//  [X] Platform: Gamepad support. Enabled with 'io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad'.
//  [X] Platform: Mouse cursor shape and visibility (ImGuiBackendFlags_HasMouseCursors). Disable with 'io.ConfigFlags |= ImGuiConfigFlags_NoMouseCursorChange'.
//  [X] Platform: Basic IME support. App needs to call 'SDL_SetHint(SDL_HINT_IME_SHOW_UI, "1");' before SDL_CreateWindow()!.
//  [X] Platform: Multi-viewport support (multiple windows). Enable with 'io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable'.
// Missing features or Issues:
//  [ ] Platform: Multi-viewport: Minimized windows seems to break mouse wheel events (at least under Windows).
//  [ ] Platform: Multi-viewport: ParentViewportID not honored, and so io.ConfigViewportsNoDefaultParent has no effect (minor).

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
//  2024-10-24: Emscripten: from SDL 2.30.9, SDL_EVENT_MOUSE_WHEEL event doesn't require dividing by 100.0f.
//  2024-09-09: use SDL_Vulkan_GetDrawableSize() when available. (#7967, #3190)
//  2024-08-22: moved some OS/backend related function pointers from ImGuiIO to ImGuiPlatformIO:
//               - io.GetClipboardTextFn    -> platform_io.Platform_GetClipboardTextFn
//               - io.SetClipboardTextFn    -> platform_io.Platform_SetClipboardTextFn
//               - io.PlatformOpenInShellFn -> platform_io.Platform_OpenInShellFn
//               - io.PlatformSetImeDataFn  -> platform_io.Platform_SetImeDataFn
//  2024-08-19: Storing SDL's Uint32 WindowID inside ImGuiViewport::PlatformHandle instead of SDL_Window*.
//  2024-08-19: ImGui_ImplSDL2_ProcessEvent() now ignores events intended for other SDL windows. (#7853)
//  2024-07-02: Emscripten: Added io.PlatformOpenInShellFn() handler for Emscripten versions.
//  2024-07-02: Update for io.SetPlatformImeDataFn() -> io.PlatformSetImeDataFn() renaming in main library.
//  2024-02-14: Inputs: Handle gamepad disconnection. Added ImGui_ImplSDL2_SetGamepadMode().
//  2023-10-05: Inputs: Added support for extra ImGuiKey values: F13 to F24 function keys, app back/forward keys.
//  2023-04-06: Inputs: Avoid calling SDL_StartTextInput()/SDL_StopTextInput() as they don't only pertain to IME. It's unclear exactly what their relation is to IME. (#6306)
//  2023-04-04: Inputs: Added support for io.AddMouseSourceEvent() to discriminate ImGuiMouseSource_Mouse/ImGuiMouseSource_TouchScreen. (#2702)
//  2023-02-23: Accept SDL_GetPerformanceCounter() not returning a monotonically increasing value. (#6189, #6114, #3644)
//  2023-02-07: Implement IME handler (io.SetPlatformImeDataFn will call SDL_SetTextInputRect()/SDL_StartTextInput()).
//  2023-02-07: *BREAKING CHANGE* Renamed this backend file from imgui_impl_sdl.cpp/.h to imgui_impl_sdl2.cpp/.h in prevision for the future release of SDL3.
//  2023-02-02: Avoid calling SDL_SetCursor() when cursor has not changed, as the function is surprisingly costly on Mac with latest SDL (may be fixed in next SDL version).
//  2023-02-02: Added support for SDL 2.0.18+ preciseX/preciseY mouse wheel data for smooth scrolling + Scaling X value on Emscripten (bug?). (#4019, #6096)
//  2023-02-02: Removed SDL_MOUSEWHEEL value clamping, as values seem correct in latest Emscripten. (#4019)
//  2023-02-01: Flipping SDL_MOUSEWHEEL 'wheel.x' value to match other backends and offer consistent horizontal scrolling direction. (#4019, #6096, #1463)
//  2022-10-11: Using 'nullptr' instead of 'NULL' as per our switch to C++11.
//  2022-09-26: Inputs: Disable SDL 2.0.22 new "auto capture" (SDL_HINT_MOUSE_AUTO_CAPTURE) which prevents drag and drop across windows for multi-viewport support + don't capture when drag and dropping. (#5710)
//  2022-09-26: Inputs: Renamed ImGuiKey.ModXXX introduced in 1.87 to ImGuiMod_XXX (old names still supported).
//  2022-03-22: Inputs: Fix mouse position issues when dragging outside of boundaries. SDL_CaptureMouse() erroneously still gives out LEAVE events when hovering OS decorations.
//  2022-03-22: Inputs: Added support for extra mouse buttons (SDL_BUTTON_X1/SDL_BUTTON_X2).
//  2022-02-04: Added SDL_Renderer* parameter to ImGui_ImplSDL2_InitForSDLRenderer(), so we can use SDL_GetRendererOutputSize() instead of SDL_GL_GetDrawableSize() when bound to a SDL_Renderer.
//  2022-01-26: Inputs: replaced short-lived io.AddKeyModsEvent() (added two weeks ago) with io.AddKeyEvent() using ImGuiKey.ModXXX flags. Sorry for the confusion.
//  2021-01-20: Inputs: calling new io.AddKeyAnalogEvent() for gamepad support, instead of writing directly to io.NavInputs[].
//  2022-01-17: Inputs: calling new io.AddMousePosEvent(), io.AddMouseButtonEvent(), io.AddMouseWheelEvent() API (1.87+).
//  2022-01-17: Inputs: always update key mods next and before key event (not in NewFrame) to fix input queue with very low framerates.
//  2022-01-12: Update mouse inputs using SDL_MOUSEMOTION/SDL_WINDOWEVENT_LEAVE + fallback to provide it when focused but not hovered/captured. More standard and will allow us to pass it to future input queue API.
//  2022-01-12: Maintain our own copy of MouseButtonsDown mask instead of using ImGui::IsAnyMouseDown() which will be obsoleted.
//  2022-01-10: Inputs: calling new io.AddKeyEvent(), io.AddKeyModsEvent() + io.SetKeyEventNativeData() API (1.87+). Support for full ImGuiKey range.
//  2021-08-17: Calling io.AddFocusEvent() on SDL_WINDOWEVENT_FOCUS_GAINED/SDL_WINDOWEVENT_FOCUS_LOST.
//  2021-07-29: Inputs: MousePos is correctly reported when the host platform window is hovered but not focused (using SDL_GetMouseFocus() + SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH, requires SDL 2.0.5+)
//  2021-06:29: *BREAKING CHANGE* Removed 'SDL_Window* window' parameter to ImGui_ImplSDL2_NewFrame() which was unnecessary.
//  2021-06-29: Reorganized backend to pull data from a single structure to facilitate usage with multiple-contexts (all g_XXXX access changed to bd->XXXX).
//  2021-03-22: Rework global mouse pos availability check listing supported platforms explicitly, effectively fixing mouse access on Raspberry Pi. (#2837, #3950)
//  2020-05-25: Misc: Report a zero display-size when window is minimized, to be consistent with other backends.
//  2020-02-20: Inputs: Fixed mapping for ImGuiKey.KeyPadEnter (using SDL_SCANCODE_KP_ENTER instead of SDL_SCANCODE_RETURN2).
//  2019-12-17: Inputs: On Wayland, use SDL_GetMouseState (because there is no global mouse state).
//  2019-12-05: Inputs: Added support for ImGuiMouseCursor_NotAllowed mouse cursor.
//  2019-07-21: Inputs: Added mapping for ImGuiKey.KeyPadEnter.
//  2019-04-23: Inputs: Added support for SDL_GameController (if ImGuiConfigFlags_NavEnableGamepad is set by user application).
//  2019-03-12: Misc: Preserve DisplayFramebufferScale when main window is minimized.
//  2018-12-21: Inputs: Workaround for Android/iOS which don't seem to handle focus related calls.
//  2018-11-30: Misc: Setting up io.BackendPlatformName so it can be displayed in the About Window.
//  2018-11-14: Changed the signature of ImGui_ImplSDL2_ProcessEvent() to take a 'const SDL_Event*'.
//  2018-08-01: Inputs: Workaround for Emscripten which doesn't seem to handle focus related calls.
//  2018-06-29: Inputs: Added support for the ImGuiMouseCursor_Hand cursor.
//  2018-06-08: Misc: Extracted imgui_impl_sdl.cpp/.h away from the old combined SDL2+OpenGL/Vulkan examples.
//  2018-06-08: Misc: ImGui_ImplSDL2_InitForOpenGL() now takes a SDL_GLContext parameter.
//  2018-05-09: Misc: Fixed clipboard paste memory leak (we didn't call SDL_FreeMemory on the data returned by SDL_GetClipboardText).
//  2018-03-20: Misc: Setup io.BackendFlags ImGuiBackendFlags_HasMouseCursors flag + honor ImGuiConfigFlags_NoMouseCursorChange flag.
//  2018-02-16: Inputs: Added support for mouse cursors, honoring ImGui::GetMouseCursor() value.
//  2018-02-06: Misc: Removed call to ImGui::Shutdown() which is not available from 1.60 WIP, user needs to call CreateContext/DestroyContext themselves.
//  2018-02-06: Inputs: Added mapping for ImGuiKey.Space.
//  2018-02-05: Misc: Using SDL_GetPerformanceCounter() instead of SDL_GetTicks() to be able to handle very high framerate (1000+ FPS).
//  2018-02-05: Inputs: Keyboard mapping is using scancodes everywhere instead of a confusing mixture of keycodes and scancodes.
//  2018-01-20: Inputs: Added Horizontal Mouse Wheel support.
//  2018-01-19: Inputs: When available (SDL 2.0.4+) using SDL_CaptureMouse() to retrieve coordinates outside of client area when dragging. Otherwise (SDL 2.0.3 and before) testing for SDL_WINDOW_INPUT_FOCUS instead of SDL_WINDOW_MOUSE_FOCUS.
//  2018-01-18: Inputs: Added mapping for ImGuiKey.Insert.
//  2017-08-25: Inputs: MousePos set to -FLT_MAX,-FLT_MAX when mouse is unavailable/missing (instead of -1,-1).
//  2016-10-15: Misc: Added a void* user_data parameter to Clipboard function handlers.

when !(IMGUI_DISABLE) {

// Clang warnings with -Weverything

// SDL
// (the multi-viewports feature requires SDL features supported from SDL 2.0.4+. SDL 2.0.5+ is highly recommended)
when __APPLE__ {
}
when __EMSCRIPTEN__ {
}

when SDL_VERSION_ATLEAST(2,0,4) && !defined(__EMSCRIPTEN__) && !defined(__ANDROID__) && !(defined(__APPLE__) && TARGET_OS_IOS) && !defined(__amigaos4__) {
SDL_HAS_CAPTURE_AND_GLOBAL_MOUSE :: 1
} else {
SDL_HAS_CAPTURE_AND_GLOBAL_MOUSE :: 0
}
#define SDL_HAS_WINDOW_ALPHA                SDL_VERSION_ATLEAST(2,0,5)
#define SDL_HAS_ALWAYS_ON_TOP               SDL_VERSION_ATLEAST(2,0,5)
#define SDL_HAS_USABLE_DISPLAY_BOUNDS       SDL_VERSION_ATLEAST(2,0,5)
#define SDL_HAS_PER_MONITOR_DPI             SDL_VERSION_ATLEAST(2,0,4)
#define SDL_HAS_VULKAN                      SDL_VERSION_ATLEAST(2,0,6)
#define SDL_HAS_DISPLAY_EVENT               SDL_VERSION_ATLEAST(2,0,9)
#define SDL_HAS_SHOW_WINDOW_ACTIVATION_HINT SDL_VERSION_ATLEAST(2,0,18)
when SDL_HAS_VULKAN {
} else {
const Uint32 SDL_WINDOW_VULKAN = 0x10000000;
}

// SDL Data
ImGui_ImplSDL2_Data :: struct
{
    Window : ^SDL_Window,
    WindowID : Uint32,
    Renderer : ^SDL_Renderer,
    Time : Uint64,
    ClipboardTextData : string,
    UseVulkan : bool,
    WantUpdateMonitors : bool,

    // Mouse handling
    MouseWindowID : Uint32,
    MouseButtonsDown : i32,
    SDL_Cursor*             MouseCursors[ImGuiMouseCursor_COUNT];
    MouseLastCursor : ^SDL_Cursor,
    MouseLastLeaveFrame : i32,
    MouseCanUseGlobalState : bool,
    MouseCanReportHoveredViewport : bool,  // This is hard to use/unreliable on SDL so we'll set ImGuiBackendFlags_HasMouseHoveredViewport dynamically based on state.

    // Gamepad handling
    ImVector<SDL_GameController*> Gamepads;
    GamepadMode : ImGui_ImplSDL2_GamepadMode,
    WantUpdateGamepadsList : bool,

    ImGui_ImplSDL2_Data()   { memset((rawptr)this, 0, size_of(*this)); }
};

// Backend data stored in io.BackendPlatformUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
// FIXME: multi-context support is not well tested and probably dysfunctional in this backend.
// FIXME: some shared resources (mouse cursor shape, gamepad) are mishandled when using multi-context.
ImGui_ImplSDL2_GetBackendData :: proc() -> ^ImGui_ImplSDL2_Data
{
    return GetCurrentContext() ? (ImGui_ImplSDL2_Data*)GetIO().BackendPlatformUserData : nullptr;
}

// Forward Declarations
void ImGui_ImplSDL2_UpdateMonitors();
void ImGui_ImplSDL2_InitMultiViewportSupport(SDL_Window* window, rawptr sdl_gl_context);
void ImGui_ImplSDL2_ShutdownMultiViewportSupport();

// Functions
ImGui_ImplSDL2_GetClipboardText :: proc(ImGuiContext*) -> ^u8
{
    bd := ImGui_ImplSDL2_GetBackendData();
    if (bd.ClipboardTextData) {
        SDL_free(bd.ClipboardTextData);
    }

    bd.ClipboardTextData = SDL_GetClipboardText();
    return bd.ClipboardTextData;
}

ImGui_ImplSDL2_SetClipboardText :: proc(ImGuiContext*, text : ^u8)
{
    SDL_SetClipboardText(text);
}

// Note: native IME will only display if user calls SDL_SetHint(SDL_HINT_IME_SHOW_UI, "1") _before_ SDL_CreateWindow().
ImGui_ImplSDL2_PlatformSetImeData :: proc(ImGuiContext*, viewport : ^ImGuiViewport, data : ^ImGuiPlatformImeData)
{
    if (data.WantVisible)
    {
        r : SDL_Rect
        r.x = (i32)(data.InputPos.x - viewport.Pos.x);
        r.y = (i32)(data.InputPos.y - viewport.Pos.y + data.InputLineHeight);
        r.w = 1;
        r.h = cast(i32) data.InputLineHeight;
        SDL_SetTextInputRect(&r);
    }
}

// Not static to allow third-party code to use that if they want to (but undocumented)
ImGuiKey ImGui_ImplSDL2_KeyEventToImGuiKey(SDL_Keycode keycode, SDL_Scancode scancode);
ImGui_ImplSDL2_KeyEventToImGuiKey :: proc(keycode : SDL_Keycode, scancode : SDL_Scancode) -> ImGuiKey
{
    _ = scancode;
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
        case SDLK_QUOTE: return ImGuiKey.Apostrophe;
        case SDLK_COMMA: return ImGuiKey.Comma;
        case SDLK_MINUS: return ImGuiKey.Minus;
        case SDLK_PERIOD: return ImGuiKey.Period;
        case SDLK_SLASH: return ImGuiKey.Slash;
        case SDLK_SEMICOLON: return ImGuiKey.Semicolon;
        case SDLK_EQUALS: return ImGuiKey.Equal;
        case SDLK_LEFTBRACKET: return ImGuiKey.LeftBracket;
        case SDLK_BACKSLASH: return ImGuiKey.Backslash;
        case SDLK_RIGHTBRACKET: return ImGuiKey.RightBracket;
        case SDLK_BACKQUOTE: return ImGuiKey.GraveAccent;
        case SDLK_CAPSLOCK: return ImGuiKey.CapsLock;
        case SDLK_SCROLLLOCK: return ImGuiKey.ScrollLock;
        case SDLK_NUMLOCKCLEAR: return ImGuiKey.NumLock;
        case SDLK_PRINTSCREEN: return ImGuiKey.PrintScreen;
        case SDLK_PAUSE: return ImGuiKey.Pause;
        case SDLK_KP_0: return ImGuiKey.Keypad0;
        case SDLK_KP_1: return ImGuiKey.Keypad1;
        case SDLK_KP_2: return ImGuiKey.Keypad2;
        case SDLK_KP_3: return ImGuiKey.Keypad3;
        case SDLK_KP_4: return ImGuiKey.Keypad4;
        case SDLK_KP_5: return ImGuiKey.Keypad5;
        case SDLK_KP_6: return ImGuiKey.Keypad6;
        case SDLK_KP_7: return ImGuiKey.Keypad7;
        case SDLK_KP_8: return ImGuiKey.Keypad8;
        case SDLK_KP_9: return ImGuiKey.Keypad9;
        case SDLK_KP_PERIOD: return ImGuiKey.KeypadDecimal;
        case SDLK_KP_DIVIDE: return ImGuiKey.KeypadDivide;
        case SDLK_KP_MULTIPLY: return ImGuiKey.KeypadMultiply;
        case SDLK_KP_MINUS: return ImGuiKey.KeypadSubtract;
        case SDLK_KP_PLUS: return ImGuiKey.KeypadAdd;
        case SDLK_KP_ENTER: return ImGuiKey.KeypadEnter;
        case SDLK_KP_EQUALS: return ImGuiKey.KeypadEqual;
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
        case SDLK_a: return ImGuiKey.A;
        case SDLK_b: return ImGuiKey.B;
        case SDLK_c: return ImGuiKey.C;
        case SDLK_d: return ImGuiKey.D;
        case SDLK_e: return ImGuiKey.E;
        case SDLK_f: return ImGuiKey.F;
        case SDLK_g: return ImGuiKey.G;
        case SDLK_h: return ImGuiKey.H;
        case SDLK_i: return ImGuiKey.I;
        case SDLK_j: return ImGuiKey.J;
        case SDLK_k: return ImGuiKey.K;
        case SDLK_l: return ImGuiKey.L;
        case SDLK_m: return ImGuiKey.M;
        case SDLK_n: return ImGuiKey.N;
        case SDLK_o: return ImGuiKey.O;
        case SDLK_p: return ImGuiKey.P;
        case SDLK_q: return ImGuiKey.Q;
        case SDLK_r: return ImGuiKey.R;
        case SDLK_s: return ImGuiKey.S;
        case SDLK_t: return ImGuiKey.T;
        case SDLK_u: return ImGuiKey.U;
        case SDLK_v: return ImGuiKey.V;
        case SDLK_w: return ImGuiKey.W;
        case SDLK_x: return ImGuiKey.X;
        case SDLK_y: return ImGuiKey.Y;
        case SDLK_z: return ImGuiKey.Z;
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

ImGui_ImplSDL2_UpdateKeyModifiers :: proc(sdl_key_mods : SDL_Keymod)
{
    io := GetIO();
    io.AddKeyEvent(ImGuiKey.Mod_Ctrl, (sdl_key_mods & KMOD_CTRL) != 0);
    io.AddKeyEvent(ImGuiKey.Mod_Shift, (sdl_key_mods & KMOD_SHIFT) != 0);
    io.AddKeyEvent(ImGuiKey.Mod_Alt, (sdl_key_mods & KMOD_ALT) != 0);
    io.AddKeyEvent(ImGuiKey.Mod_Super, (sdl_key_mods & KMOD_GUI) != 0);
}

ImGui_ImplSDL2_GetViewportForWindowID :: proc(window_id : Uint32) -> ^ImGuiViewport
{
    return FindViewportByPlatformHandle(cast(rawptr)window_id);
}

// You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
// - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application, or clear/overwrite your copy of the mouse data.
// - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application, or clear/overwrite your copy of the keyboard data.
// Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.
ImGui_ImplSDL2_ProcessEvent :: proc(event : ^SDL_Event) -> bool
{
    bd := ImGui_ImplSDL2_GetBackendData();
    assert(bd != nullptr, "Context or backend not initialized! Did you call ImGui_ImplSDL2_Init()?");
    io := GetIO();

    switch (event.type)
    {
        case SDL_MOUSEMOTION:
        {
            if (ImGui_ImplSDL2_GetViewportForWindowID(event.motion.windowID) == nullptr)   do return false
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
        case SDL_MOUSEWHEEL:
        {
            if (ImGui_ImplSDL2_GetViewportForWindowID(event.wheel.windowID) == nullptr)   do return false
            //IMGUI_DEBUG_LOG("wheel %.2f %.2f, precise %.2f %.2f\n", (float)event.wheel.x, (float)event.wheel.y, event.wheel.preciseX, event.wheel.preciseY);
when SDL_VERSION_ATLEAST(2,0,18) { // If this fails to compile on Emscripten: update to latest Emscripten!
            wheel_x := -event.wheel.preciseX;
            wheel_y := event.wheel.preciseY;
} else {
            wheel_x := -cast(f32) event.wheel.x;
            wheel_y := cast(f32) event.wheel.y;
}
when defined(__EMSCRIPTEN__) && !SDL_VERSION_ATLEAST(2,31,0) {
            wheel_x /= 100.0;
}
            io.AddMouseSourceEvent(event.wheel.which == SDL_TOUCH_MOUSEID ? ImGuiMouseSource_TouchScreen : ImGuiMouseSource_Mouse);
            io.AddMouseWheelEvent(wheel_x, wheel_y);
            return true;
        }
        case SDL_MOUSEBUTTONDOWN:
        case SDL_MOUSEBUTTONUP:
        {
            if (ImGui_ImplSDL2_GetViewportForWindowID(event.button.windowID) == nullptr)   do return false
            mouse_button := -1;
            if (event.button.button == SDL_BUTTON_LEFT) { mouse_button = 0; }
            if (event.button.button == SDL_BUTTON_RIGHT) { mouse_button = 1; }
            if (event.button.button == SDL_BUTTON_MIDDLE) { mouse_button = 2; }
            if (event.button.button == SDL_BUTTON_X1) { mouse_button = 3; }
            if (event.button.button == SDL_BUTTON_X2) { mouse_button = 4; }
            if (mouse_button == -1)   do break
            io.AddMouseSourceEvent(event.button.which == SDL_TOUCH_MOUSEID ? ImGuiMouseSource_TouchScreen : ImGuiMouseSource_Mouse);
            io.AddMouseButtonEvent(mouse_button, (event.type == SDL_MOUSEBUTTONDOWN));
            bd.MouseButtonsDown = (event.type == SDL_MOUSEBUTTONDOWN) ? (bd.MouseButtonsDown | (1 << mouse_button)) : (bd.MouseButtonsDown & ~(1 << mouse_button));
            return true;
        }
        case SDL_TEXTINPUT:
        {
            if (ImGui_ImplSDL2_GetViewportForWindowID(event.text.windowID) == nullptr)   do return false
            io.AddInputCharactersUTF8(event.text.text);
            return true;
        }
        case SDL_KEYDOWN:
        case SDL_KEYUP:
        {
            if (ImGui_ImplSDL2_GetViewportForWindowID(event.key.windowID) == nullptr)   do return false
            ImGui_ImplSDL2_UpdateKeyModifiers((SDL_Keymod)event.key.keysym.mod);
            key := ImGui_ImplSDL2_KeyEventToImGuiKey(event.key.keysym.sym, event.key.keysym.scancode);
            io.AddKeyEvent(key, (event.type == SDL_KEYDOWN));
            io.SetKeyEventNativeData(key, event.key.keysym.sym, event.key.keysym.scancode, event.key.keysym.scancode); // To support legacy indexing (<1.87 user code). Legacy backend uses SDLK_*** as indices to IsKeyXXX() functions.
            return true;
        }
when SDL_HAS_DISPLAY_EVENT {
        case SDL_DISPLAYEVENT:
        {
            // 2.0.26 has SDL_DISPLAYEVENT_CONNECTED/SDL_DISPLAYEVENT_DISCONNECTED/SDL_DISPLAYEVENT_ORIENTATION,
            // so change of DPI/Scaling are not reflected in this event. (SDL3 has it)
            bd.WantUpdateMonitors = true;
            return true;
        }
}
        case SDL_WINDOWEVENT:
        {
            viewport := ImGui_ImplSDL2_GetViewportForWindowID(event.window.windowID);
            if (viewport == nil)   do return false

            // - When capturing mouse, SDL will send a bunch of conflicting LEAVE/ENTER event on every mouse move, but the final ENTER tends to be right.
            // - However we won't get a correct LEAVE event for a captured window.
            // - In some cases, when detaching a window from main viewport SDL may send SDL_WINDOWEVENT_ENTER one frame too late,
            //   causing SDL_WINDOWEVENT_LEAVE on previous frame to interrupt drag operation by clear mouse position. This is why
            //   we delay process the SDL_WINDOWEVENT_LEAVE events by one frame. See issue #5012 for details.
            window_event := event.window.event;
            if (window_event == SDL_WINDOWEVENT_ENTER)
            {
                bd.MouseWindowID = event.window.windowID;
                bd.MouseLastLeaveFrame = 0;
            }
            if (window_event == SDL_WINDOWEVENT_LEAVE) {
                bd.MouseLastLeaveFrame = GetFrameCount() + 1;
            }

            if (window_event == SDL_WINDOWEVENT_FOCUS_GAINED)   do io.AddFocusEvent(true)
            else if (window_event == SDL_WINDOWEVENT_FOCUS_LOST)   do io.AddFocusEvent(false)
            else if (window_event == SDL_WINDOWEVENT_CLOSE) {
                viewport.PlatformRequestClose = true;
            }

            else if (window_event == SDL_WINDOWEVENT_MOVED) {
                viewport.PlatformRequestMove = true;
            }

            else if (window_event == SDL_WINDOWEVENT_RESIZED) {
                viewport.PlatformRequestResize = true;
            }

            return true;
        }
        case SDL_CONTROLLERDEVICEADDED:
        case SDL_CONTROLLERDEVICEREMOVED:
        {
            bd.WantUpdateGamepadsList = true;
            return true;
        }
    }
    return false;
}

when __EMSCRIPTEN__ {
EM_JS(void, ImGui_ImplSDL2_EmscriptenOpenURL, (u8 const* url), { url = url ? UTF8ToString(url) : null; if (url) window.open(url, '_blank'); });
}

ImGui_ImplSDL2_Init :: proc(window : ^SDL_Window, renderer : ^SDL_Renderer, sdl_gl_context : rawptr) -> bool
{
    io := GetIO();
    IMGUI_CHECKVERSION();
    assert(io.BackendPlatformUserData == nullptr, "Already initialized a platform backend!");

    // Check and store if we are on a SDL backend that supports global mouse position
    // ("wayland" and "rpi" don't support it, but we chose to use a white-list instead of a black-list)
    mouse_can_use_global_state := false;
when SDL_HAS_CAPTURE_AND_GLOBAL_MOUSE {
    sdl_backend := SDL_GetCurrentVideoDriver();
    const u8* global_mouse_whitelist[] = { "windows", "cocoa", "x11", "DIVE", "VMAN" };
    for int n = 0; n < len(global_mouse_whitelist); n += 1
        if (strncmp(sdl_backend, global_mouse_whitelist[n], strlen(global_mouse_whitelist[n])) == 0) {
            mouse_can_use_global_state = true;
        }

}

    // Setup backend capabilities flags
    bd := IM_NEW(ImGui_ImplSDL2_Data)();
    io.BackendPlatformUserData = cast(rawptr) bd;
    io.BackendPlatformName = "imgui_impl_sdl2";
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
    platform_io.Platform_SetClipboardTextFn = ImGui_ImplSDL2_SetClipboardText;
    platform_io.Platform_GetClipboardTextFn = ImGui_ImplSDL2_GetClipboardText;
    platform_io.Platform_ClipboardUserData = nullptr;
    platform_io.Platform_SetImeDataFn = ImGui_ImplSDL2_PlatformSetImeData;
when __EMSCRIPTEN__ {
    platform_io.Platform_OpenInShellFn = [](ImGuiContext*, const u8* url) { ImGui_ImplSDL2_EmscriptenOpenURL(url); return true; };
}

    // Update monitor a first time during init
    ImGui_ImplSDL2_UpdateMonitors();

    // Gamepad handling
    bd.GamepadMode = ImGui_ImplSDL2_GamepadMode_AutoFirst;
    bd.WantUpdateGamepadsList = true;

    // Load mouse cursors
    bd.MouseCursors[ImGuiMouseCursor_Arrow] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_ARROW);
    bd.MouseCursors[ImGuiMouseCursor_TextInput] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_IBEAM);
    bd.MouseCursors[ImGuiMouseCursor_ResizeAll] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_SIZEALL);
    bd.MouseCursors[ImGuiMouseCursor_ResizeNS] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_SIZENS);
    bd.MouseCursors[ImGuiMouseCursor_ResizeEW] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_SIZEWE);
    bd.MouseCursors[ImGuiMouseCursor_ResizeNESW] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_SIZENESW);
    bd.MouseCursors[ImGuiMouseCursor_ResizeNWSE] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_SIZENWSE);
    bd.MouseCursors[ImGuiMouseCursor_Hand] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_HAND);
    bd.MouseCursors[ImGuiMouseCursor_NotAllowed] = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_NO);

    // Set platform dependent data in viewport
    // Our mouse update function expect PlatformHandle to be filled for the main viewport
    main_viewport := GetMainViewport();
    main_viewport.PlatformHandle = cast(rawptr) (rawptr)bd.WindowID;
    main_viewport.PlatformHandleRaw = nullptr;
    info : SDL_SysWMinfo
    SDL_VERSION(&info.version);
    if (SDL_GetWindowWMInfo(window, &info))
    {
when defined(SDL_VIDEO_DRIVER_WINDOWS) {
        main_viewport.PlatformHandleRaw = cast(rawptr) info.info.win.window;
} else when defined(__APPLE__) && defined(SDL_VIDEO_DRIVER_COCOA) {
        main_viewport.PlatformHandleRaw = cast(rawptr) info.info.cocoa.window;
}
    }

    // From 2.0.5: Set SDL hint to receive mouse click events on window focus, otherwise SDL doesn't emit the event.
    // Without this, when clicking to gain focus, our widgets wouldn't activate even though they showed as hovered.
    // (This is unfortunately a global SDL setting, so enabling it might have a side-effect on your application.
    // It is unlikely to make a difference, but if your app absolutely needs to ignore the initial on-focus click:
    // you can ignore SDL_MOUSEBUTTONDOWN events coming right after a SDL_WINDOWEVENT_FOCUS_GAINED)
when SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH {
    SDL_SetHint(SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH, "1");
}

    // From 2.0.18: Enable native IME.
    // IMPORTANT: This is used at the time of SDL_CreateWindow() so this will only affects secondary windows, if any.
    // For the main window to be affected, your application needs to call this manually before calling SDL_CreateWindow().
when SDL_HINT_IME_SHOW_UI {
    SDL_SetHint(SDL_HINT_IME_SHOW_UI, "1");
}

    // From 2.0.22: Disable auto-capture, this is preventing drag and drop across multiple windows (see #5710)
when SDL_HINT_MOUSE_AUTO_CAPTURE {
    SDL_SetHint(SDL_HINT_MOUSE_AUTO_CAPTURE, "0");
}

    // We need SDL_CaptureMouse(), SDL_GetGlobalMouseState() from SDL 2.0.4+ to support multiple viewports.
    // We left the call to ImGui_ImplSDL2_InitMultiViewportSupport() outside of #ifdef to avoid unused-function warnings.
    if (.PlatformHasViewports in io.BackendFlags)
        ImGui_ImplSDL2_InitMultiViewportSupport(window, sdl_gl_context);

    return true;
}

ImGui_ImplSDL2_InitForOpenGL :: proc(window : ^SDL_Window, sdl_gl_context : rawptr) -> bool
{
    return ImGui_ImplSDL2_Init(window, nullptr, sdl_gl_context);
}

ImGui_ImplSDL2_InitForVulkan :: proc(window : ^SDL_Window) -> bool
{
when !SDL_HAS_VULKAN {
    assert(false, "Unsupported");
}
    if (!ImGui_ImplSDL2_Init(window, nullptr, nullptr))   do return false
    bd := ImGui_ImplSDL2_GetBackendData();
    bd.UseVulkan = true;
    return true;
}

ImGui_ImplSDL2_InitForD3D :: proc(window : ^SDL_Window) -> bool
{
when !defined(_WIN32) {
    assert(false, "Unsupported");
}
    return ImGui_ImplSDL2_Init(window, nullptr, nullptr);
}

ImGui_ImplSDL2_InitForMetal :: proc(window : ^SDL_Window) -> bool
{
    return ImGui_ImplSDL2_Init(window, nullptr, nullptr);
}

ImGui_ImplSDL2_InitForSDLRenderer :: proc(window : ^SDL_Window, renderer : ^SDL_Renderer) -> bool
{
    return ImGui_ImplSDL2_Init(window, renderer, nullptr);
}

ImGui_ImplSDL2_InitForOther :: proc(window : ^SDL_Window) -> bool
{
    return ImGui_ImplSDL2_Init(window, nullptr, nullptr);
}

void ImGui_ImplSDL2_CloseGamepads();

ImGui_ImplSDL2_Shutdown :: proc()
{
    bd := ImGui_ImplSDL2_GetBackendData();
    assert(bd != nullptr, "No platform backend to shutdown, or already shutdown?");
    io := GetIO();

    ImGui_ImplSDL2_ShutdownMultiViewportSupport();

    if (bd.ClipboardTextData) {
        SDL_free(bd.ClipboardTextData);
    }

    for ImGuiMouseCursor cursor_n = 0; cursor_n < ImGuiMouseCursor_COUNT; cursor_n += 1
        SDL_FreeCursor(bd.MouseCursors[cursor_n]);
    ImGui_ImplSDL2_CloseGamepads();

    io.BackendPlatformName = nullptr;
    io.BackendPlatformUserData = nullptr;
    io.BackendFlags &= ~(ImGuiBackendFlags_HasMouseCursors | ImGuiBackendFlags_HasSetMousePos | ImGuiBackendFlags_HasGamepad | ImGuiBackendFlags_PlatformHasViewports | ImGuiBackendFlags_HasMouseHoveredViewport);
    IM_DELETE(bd);
}

// This code is incredibly messy because some of the functions we need for full viewport support are not available in SDL < 2.0.4.
ImGui_ImplSDL2_UpdateMouseData :: proc()
{
    bd := ImGui_ImplSDL2_GetBackendData();
    io := GetIO();

    // We forward mouse input when hovered or captured (via SDL_MOUSEMOTION) or when focused (below)
when SDL_HAS_CAPTURE_AND_GLOBAL_MOUSE {
    // SDL_CaptureMouse() let the OS know e.g. that our imgui drag outside the SDL window boundaries shouldn't e.g. trigger other operations outside
    SDL_CaptureMouse((bd.MouseButtonsDown != 0) ? SDL_TRUE : SDL_FALSE);
    focused_window := SDL_GetKeyboardFocus();
    is_app_focused := (focused_window && (bd.Window == focused_window || ImGui_ImplSDL2_GetViewportForWindowID(SDL_GetWindowID(focused_window)) != nil));
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
                SDL_WarpMouseGlobal(cast(i32) io.MousePos.x, cast(i32) io.MousePos.y);
            }

            else
}
                SDL_WarpMouseInWindow(bd.Window, cast(i32) io.MousePos.x, cast(i32) io.MousePos.y);
        }

        // (Optional) Fallback to provide mouse position when focused (SDL_MOUSEMOTION already provides this when hovered or captured)
        if (bd.MouseCanUseGlobalState && bd.MouseButtonsDown == 0)
        {
            // Single-viewport mode: mouse position in client window coordinates (io.MousePos is (0,0) when the mouse is on the upper-left corner of the app window)
            // Multi-viewport mode: mouse position in OS absolute coordinates (io.MousePos is (0,0) when the mouse is on the upper-left of the primary monitor)
            mouse_x, mouse_y, window_x, window_y : i32
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
        if (ImGuiViewport* mouse_viewport = ImGui_ImplSDL2_GetViewportForWindowID(bd.MouseWindowID)) {
            mouse_viewport_id = mouse_viewport.ID;
        }

        io.AddMouseViewportEvent(mouse_viewport_id);
    }
}

ImGui_ImplSDL2_UpdateMouseCursor :: proc()
{
    io := GetIO();
    if (.NoMouseCursorChange in io.ConfigFlags)   do return
    bd := ImGui_ImplSDL2_GetBackendData();

    imgui_cursor := GetMouseCursor();
    if (io.MouseDrawCursor || imgui_cursor == ImGuiMouseCursor_None)
    {
        // Hide OS mouse cursor if imgui is drawing it or if it wants no cursor
        SDL_ShowCursor(SDL_FALSE);
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
        SDL_ShowCursor(SDL_TRUE);
    }
}

ImGui_ImplSDL2_CloseGamepads :: proc()
{
    bd := ImGui_ImplSDL2_GetBackendData();
    if (bd.GamepadMode != ImGui_ImplSDL2_GamepadMode_Manual) {
        for gamepad in bd.Gamepads
    }

            SDL_GameControllerClose(gamepad);
    bd.Gamepads.resize(0);
}

ImGui_ImplSDL2_SetGamepadMode :: proc(mode : ImGui_ImplSDL2_GamepadMode, manual_gamepads_array : ^^_SDL_GameController, manual_gamepads_count : i32)
{
    bd := ImGui_ImplSDL2_GetBackendData();
    ImGui_ImplSDL2_CloseGamepads();
    if (mode == ImGui_ImplSDL2_GamepadMode_Manual)
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

ImGui_ImplSDL2_UpdateGamepadButton :: proc(bd : ^ImGui_ImplSDL2_Data, io : ^ImGuiIO, key : ImGuiKey, button_no : SDL_GameControllerButton)
{
    merged_value := false;
    for gamepad in bd.Gamepads
        merged_value |= SDL_GameControllerGetButton(gamepad, button_no) != 0;
    io.AddKeyEvent(key, merged_value);
}

inline f32 Saturate(f32 v) { return v < 0.0 ? 0.0 : v  > 1.0 ? 1.0 : v; }
ImGui_ImplSDL2_UpdateGamepadAnalog :: proc(bd : ^ImGui_ImplSDL2_Data, io : ^ImGuiIO, key : ImGuiKey, axis_no : SDL_GameControllerAxis, v0 : f32, v1 : f32)
{
    merged_value := 0.0;
    for gamepad in bd.Gamepads
    {
        vn := Saturate((f32)(SDL_GameControllerGetAxis(gamepad, axis_no) - v0) / (f32)(v1 - v0));
        if (merged_value < vn)   do merged_value = vn
    }
    io.AddKeyAnalogEvent(key, merged_value > 0.1, merged_value);
}

ImGui_ImplSDL2_UpdateGamepads :: proc()
{
    bd := ImGui_ImplSDL2_GetBackendData();
    io := GetIO();

    // Update list of controller(s) to use
    if (bd.WantUpdateGamepadsList && bd.GamepadMode != ImGui_ImplSDL2_GamepadMode_Manual)
    {
        ImGui_ImplSDL2_CloseGamepads();
        joystick_count := SDL_NumJoysticks();
        for n := 0; n < joystick_count; n += 1
            if (SDL_IsGameController(n))
                if (SDL_GameController* gamepad = SDL_GameControllerOpen(n))
                {
                    bd.Gamepads.append(gamepad);
                    if (bd.GamepadMode == ImGui_ImplSDL2_GamepadMode_AutoFirst)   do break
                }
        bd.WantUpdateGamepadsList = false;
    }

    // FIXME: Technically feeding gamepad shouldn't depend on this now that they are regular inputs.
    if ((.NavEnableGamepad not_in io.ConfigFlags))   do return
    io.BackendFlags &= ~ImGuiBackendFlags_HasGamepad;
    if (len(bd.Gamepads) == 0)   do return
    io.BackendFlags |= ImGuiBackendFlags_HasGamepad;

    // Update gamepad inputs
    thumb_dead_zone := 8000; // SDL_gamecontroller.h suggests using this value.
    ImGui_ImplSDL2_UpdateGamepadButton(bd, io, ImGuiKey.GamepadStart,       SDL_CONTROLLER_BUTTON_START);
    ImGui_ImplSDL2_UpdateGamepadButton(bd, io, ImGuiKey.GamepadBack,        SDL_CONTROLLER_BUTTON_BACK);
    ImGui_ImplSDL2_UpdateGamepadButton(bd, io, ImGuiKey.GamepadFaceLeft,    SDL_CONTROLLER_BUTTON_X);              // Xbox X, PS Square
    ImGui_ImplSDL2_UpdateGamepadButton(bd, io, ImGuiKey.GamepadFaceRight,   SDL_CONTROLLER_BUTTON_B);              // Xbox B, PS Circle
    ImGui_ImplSDL2_UpdateGamepadButton(bd, io, ImGuiKey.GamepadFaceUp,      SDL_CONTROLLER_BUTTON_Y);              // Xbox Y, PS Triangle
    ImGui_ImplSDL2_UpdateGamepadButton(bd, io, ImGuiKey.GamepadFaceDown,    SDL_CONTROLLER_BUTTON_A);              // Xbox A, PS Cross
    ImGui_ImplSDL2_UpdateGamepadButton(bd, io, ImGuiKey.GamepadDpadLeft,    SDL_CONTROLLER_BUTTON_DPAD_LEFT);
    ImGui_ImplSDL2_UpdateGamepadButton(bd, io, ImGuiKey.GamepadDpadRight,   SDL_CONTROLLER_BUTTON_DPAD_RIGHT);
    ImGui_ImplSDL2_UpdateGamepadButton(bd, io, ImGuiKey.GamepadDpadUp,      SDL_CONTROLLER_BUTTON_DPAD_UP);
    ImGui_ImplSDL2_UpdateGamepadButton(bd, io, ImGuiKey.GamepadDpadDown,    SDL_CONTROLLER_BUTTON_DPAD_DOWN);
    ImGui_ImplSDL2_UpdateGamepadButton(bd, io, ImGuiKey.GamepadL1,          SDL_CONTROLLER_BUTTON_LEFTSHOULDER);
    ImGui_ImplSDL2_UpdateGamepadButton(bd, io, ImGuiKey.GamepadR1,          SDL_CONTROLLER_BUTTON_RIGHTSHOULDER);
    ImGui_ImplSDL2_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadL2,          SDL_CONTROLLER_AXIS_TRIGGERLEFT,  0.0, 32767);
    ImGui_ImplSDL2_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadR2,          SDL_CONTROLLER_AXIS_TRIGGERRIGHT, 0.0, 32767);
    ImGui_ImplSDL2_UpdateGamepadButton(bd, io, ImGuiKey.GamepadL3,          SDL_CONTROLLER_BUTTON_LEFTSTICK);
    ImGui_ImplSDL2_UpdateGamepadButton(bd, io, ImGuiKey.GamepadR3,          SDL_CONTROLLER_BUTTON_RIGHTSTICK);
    ImGui_ImplSDL2_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadLStickLeft,  SDL_CONTROLLER_AXIS_LEFTX,  -thumb_dead_zone, -32768);
    ImGui_ImplSDL2_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadLStickRight, SDL_CONTROLLER_AXIS_LEFTX,  +thumb_dead_zone, +32767);
    ImGui_ImplSDL2_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadLStickUp,    SDL_CONTROLLER_AXIS_LEFTY,  -thumb_dead_zone, -32768);
    ImGui_ImplSDL2_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadLStickDown,  SDL_CONTROLLER_AXIS_LEFTY,  +thumb_dead_zone, +32767);
    ImGui_ImplSDL2_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadRStickLeft,  SDL_CONTROLLER_AXIS_RIGHTX, -thumb_dead_zone, -32768);
    ImGui_ImplSDL2_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadRStickRight, SDL_CONTROLLER_AXIS_RIGHTX, +thumb_dead_zone, +32767);
    ImGui_ImplSDL2_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadRStickUp,    SDL_CONTROLLER_AXIS_RIGHTY, -thumb_dead_zone, -32768);
    ImGui_ImplSDL2_UpdateGamepadAnalog(bd, io, ImGuiKey.GamepadRStickDown,  SDL_CONTROLLER_AXIS_RIGHTY, +thumb_dead_zone, +32767);
}

// FIXME: Note that doesn't update with DPI/Scaling change only as SDL2 doesn't have an event for it (SDL3 has).
ImGui_ImplSDL2_UpdateMonitors :: proc()
{
    bd := ImGui_ImplSDL2_GetBackendData();
    platform_io := &GetPlatformIO();
    platform_io.Monitors.resize(0);
    bd.WantUpdateMonitors = false;
    display_count := SDL_GetNumVideoDisplays();
    for n := 0; n < display_count; n += 1
    {
        // Warning: the validity of monitor DPI information on Windows depends on the application DPI awareness settings, which generally needs to be set in the manifest or at runtime.
        monitor : ImGuiPlatformMonitor
        r : SDL_Rect
        SDL_GetDisplayBounds(n, &r);
        monitor.MainPos = monitor.WorkPos = ImVec2{(f32}r.x, cast(f32) r.y);
        monitor.MainSize = monitor.WorkSize = ImVec2{(f32}r.w, cast(f32) r.h);
when SDL_HAS_USABLE_DISPLAY_BOUNDS {
        SDL_GetDisplayUsableBounds(n, &r);
        monitor.WorkPos = ImVec2{(f32}r.x, cast(f32) r.y);
        monitor.WorkSize = ImVec2{(f32}r.w, cast(f32) r.h);
}
when SDL_HAS_PER_MONITOR_DPI {
        // FIXME-VIEWPORT: On MacOS SDL reports actual monitor DPI scale, ignoring OS configuration. We may want to set
        //  DpiScale to cocoa_window.backingScaleFactor here.
        dpi := 0.0;
        if (!SDL_GetDisplayDPI(n, &dpi, nullptr, nullptr))
        {
            if (dpi <= 0.0) {
                continue; // Some accessibility applications are declaring virtual monitors with a DPI of 0, see #7902.
            }

            monitor.DpiScale = dpi / 96.0;
        }
}
        monitor.PlatformHandle = cast(rawptr) (rawptr)n;
        platform_io.Monitors.append(monitor);
    }
}

ImGui_ImplSDL2_NewFrame :: proc()
{
    bd := ImGui_ImplSDL2_GetBackendData();
    assert(bd != nullptr, "Context or backend not initialized! Did you call ImGui_ImplSDL2_Init()?");
    io := GetIO();

    // Setup display size (every frame to accommodate for window resizing)
    w, h : i32
    display_w, display_h : i32
    SDL_GetWindowSize(bd.Window, &w, &h);
    if (SDL_GetWindowFlags(bd.Window) & SDL_WINDOW_MINIMIZED)   do w = h = 0
    if (bd.Renderer != nullptr) {
        SDL_GetRendererOutputSize(bd.Renderer, &display_w, &display_h);
    }

when SDL_HAS_VULKAN {
    else if (SDL_GetWindowFlags(bd.Window) & SDL_WINDOW_VULKAN) {
        SDL_Vulkan_GetDrawableSize(bd.Window, &display_w, &display_h);
    }

}
    else
        SDL_GL_GetDrawableSize(bd.Window, &display_w, &display_h);
    io.DisplaySize = ImVec2{(f32}w, cast(f32) h);
    if (w > 0 && h > 0)
        io.DisplayFramebufferScale = ImVec2{(f32}display_w / w, cast(f32) display_h / h);

    // Update monitors
    if (bd.WantUpdateMonitors)
        ImGui_ImplSDL2_UpdateMonitors();

    // Setup time step (we don't use SDL_GetTicks() because it is using millisecond resolution)
    // (Accept SDL_GetPerformanceCounter() not returning a monotonically increasing value. Happens in VMs and Emscripten, see #6189, #6114, #3644)
    static Uint64 frequency = SDL_GetPerformanceFrequency();
    current_time := SDL_GetPerformanceCounter();
    if (current_time <= bd.Time) {
        current_time = bd.Time + 1;
    }

    io.DeltaTime = bd.Time > 0 ? (f32)((f64)(current_time - bd.Time) / frequency) : (f32)(1.0 / 60.0);
    bd.Time = current_time;

    if (bd.MouseLastLeaveFrame && bd.MouseLastLeaveFrame >= GetFrameCount() && bd.MouseButtonsDown == 0)
    {
        bd.MouseWindowID = 0;
        bd.MouseLastLeaveFrame = 0;
        io.AddMousePosEvent(-math.F32_MAX, -math.F32_MAX);
    }

    // Our io.AddMouseViewportEvent() calls will only be valid when not capturing.
    // Technically speaking testing for 'bd.MouseButtonsDown == 0' would be more rigorous, but testing for payload reduces noise and potential side-effects.
    if (bd.MouseCanReportHoveredViewport && GetDragDropPayload() == nullptr)
        io.BackendFlags |= ImGuiBackendFlags_HasMouseHoveredViewport;
    else
        io.BackendFlags &= ~ImGuiBackendFlags_HasMouseHoveredViewport;

    ImGui_ImplSDL2_UpdateMouseData();
    ImGui_ImplSDL2_UpdateMouseCursor();

    // Update game controllers (if enabled and available)
    ImGui_ImplSDL2_UpdateGamepads();
}

//--------------------------------------------------------------------------------------------------------
// MULTI-VIEWPORT / PLATFORM INTERFACE SUPPORT
// This is an _advanced_ and _optional_ feature, allowing the backend to create and handle multiple viewports simultaneously.
// If you are new to dear imgui or creating a new binding for dear imgui, it is recommended that you completely ignore this section first..
//--------------------------------------------------------------------------------------------------------

// Helper structure we store in the void* RendererUserData field of each ImGuiViewport to easily retrieve our backend data.
ImGui_ImplSDL2_ViewportData :: struct
{
    Window : ^SDL_Window,
    WindowID : Uint32,
    WindowOwned : bool,
    GLContext : SDL_GLContext,

    ImGui_ImplSDL2_ViewportData() { Window = nullptr; WindowID = 0; WindowOwned = false; GLContext = nullptr; }
    ~ImGui_ImplSDL2_ViewportData() { assert(Window == nullptr && GLContext == nullptr); }
};

ImGui_ImplSDL2_CreateWindow :: proc(viewport : ^ImGuiViewport)
{
    bd := ImGui_ImplSDL2_GetBackendData();
    vd := IM_NEW(ImGui_ImplSDL2_ViewportData)();
    viewport.PlatformUserData = vd;

    main_viewport := GetMainViewport();
    main_viewport_data := (ImGui_ImplSDL2_ViewportData*)main_viewport.PlatformUserData;

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
    sdl_flags |= SDL_GetWindowFlags(bd.Window) & SDL_WINDOW_ALLOW_HIGHDPI;
    sdl_flags |= SDL_WINDOW_HIDDEN;
    sdl_flags |= (.NoDecoration in viewport.Flags) ? SDL_WINDOW_BORDERLESS : 0;
    sdl_flags |= (.NoDecoration in viewport.Flags) ? 0 : SDL_WINDOW_RESIZABLE;
when !defined(_WIN32) {
    // See SDL hack in ImGui_ImplSDL2_ShowWindow().
    sdl_flags |= (.NoTaskBarIcon in viewport.Flags) ? SDL_WINDOW_SKIP_TASKBAR : 0;
}
when SDL_HAS_ALWAYS_ON_TOP {
    sdl_flags |= (.TopMost in viewport.Flags) ? SDL_WINDOW_ALWAYS_ON_TOP : 0;
}
    vd.Window = SDL_CreateWindow("No Title Yet", cast(i32) viewport.Pos.x, cast(i32) viewport.Pos.y, cast(i32) viewport.Size.x, cast(i32) viewport.Size.y, sdl_flags);
    vd.WindowOwned = true;
    if (use_opengl)
    {
        vd.GLContext = SDL_GL_CreateContext(vd.Window);
        SDL_GL_SetSwapInterval(0);
    }
    if (use_opengl && backup_context) {
        SDL_GL_MakeCurrent(vd.Window, backup_context);
    }

    viewport.PlatformHandle = cast(rawptr) (rawptr)SDL_GetWindowID(vd.Window);
    viewport.PlatformHandleRaw = nullptr;
    info : SDL_SysWMinfo
    SDL_VERSION(&info.version);
    if (SDL_GetWindowWMInfo(vd.Window, &info))
    {
when defined(SDL_VIDEO_DRIVER_WINDOWS) {
        viewport.PlatformHandleRaw = info.info.win.window;
} else when defined(__APPLE__) && defined(SDL_VIDEO_DRIVER_COCOA) {
        viewport.PlatformHandleRaw = cast(rawptr) info.info.cocoa.window;
}
    }
}

ImGui_ImplSDL2_DestroyWindow :: proc(viewport : ^ImGuiViewport)
{
    if (ImGui_ImplSDL2_ViewportData* vd = (ImGui_ImplSDL2_ViewportData*)viewport.PlatformUserData)
    {
        if (vd.GLContext && vd.WindowOwned) {
            SDL_GL_DeleteContext(vd.GLContext);
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

ImGui_ImplSDL2_ShowWindow :: proc(viewport : ^ImGuiViewport)
{
    vd := (ImGui_ImplSDL2_ViewportData*)viewport.PlatformUserData;
when defined(_WIN32) && !(defined(WINAPI_FAMILY) && (WINAPI_FAMILY == WINAPI_FAMILY_APP || WINAPI_FAMILY == WINAPI_FAMILY_GAMES)) {
    hwnd := (HWND)viewport.PlatformHandleRaw;

    // SDL hack: Hide icon from task bar
    // Note: SDL 2.0.6+ has a SDL_WINDOW_SKIP_TASKBAR flag which is supported under Windows but the way it create the window breaks our seamless transition.
    if (.NoTaskBarIcon in viewport.Flags)
    {
        ex_style := ::GetWindowLong(hwnd, GWL_EXSTYLE);
        ex_style &= ~WS_EX_APPWINDOW;
        ex_style |= WS_EX_TOOLWINDOW;
        ::SetWindowLong(hwnd, GWL_EXSTYLE, ex_style);
    }
}

when SDL_HAS_SHOW_WINDOW_ACTIVATION_HINT {
    SDL_SetHint(SDL_HINT_WINDOW_NO_ACTIVATION_WHEN_SHOWN, (.NoFocusOnAppearing in viewport.Flags) ? "1" : "0");
} else when defined(_WIN32) {
    // SDL hack: SDL always activate/focus windows :/
    if (.NoFocusOnAppearing in viewport.Flags)
    {
        ::ShowWindow(hwnd, SW_SHOWNA);
        return;
    }
}
    SDL_ShowWindow(vd.Window);
}

ImGui_ImplSDL2_GetWindowPos :: proc(viewport : ^ImGuiViewport) -> ImVec2
{
    vd := (ImGui_ImplSDL2_ViewportData*)viewport.PlatformUserData;
    x := 0, y = 0;
    SDL_GetWindowPosition(vd.Window, &x, &y);
    return ImVec2{(f32}x, cast(f32) y);
}

ImGui_ImplSDL2_SetWindowPos :: proc(viewport : ^ImGuiViewport, pos : ImVec2)
{
    vd := (ImGui_ImplSDL2_ViewportData*)viewport.PlatformUserData;
    SDL_SetWindowPosition(vd.Window, cast(i32) pos.x, cast(i32) pos.y);
}

ImGui_ImplSDL2_GetWindowSize :: proc(viewport : ^ImGuiViewport) -> ImVec2
{
    vd := (ImGui_ImplSDL2_ViewportData*)viewport.PlatformUserData;
    w := 0, h = 0;
    SDL_GetWindowSize(vd.Window, &w, &h);
    return ImVec2{(f32}w, cast(f32) h);
}

ImGui_ImplSDL2_SetWindowSize :: proc(viewport : ^ImGuiViewport, size : ImVec2)
{
    vd := (ImGui_ImplSDL2_ViewportData*)viewport.PlatformUserData;
    SDL_SetWindowSize(vd.Window, cast(i32) size.x, cast(i32) size.y);
}

ImGui_ImplSDL2_SetWindowTitle :: proc(viewport : ^ImGuiViewport, title : ^u8)
{
    vd := (ImGui_ImplSDL2_ViewportData*)viewport.PlatformUserData;
    SDL_SetWindowTitle(vd.Window, title);
}

when SDL_HAS_WINDOW_ALPHA {
ImGui_ImplSDL2_SetWindowAlpha :: proc(viewport : ^ImGuiViewport, alpha : f32)
{
    vd := (ImGui_ImplSDL2_ViewportData*)viewport.PlatformUserData;
    SDL_SetWindowOpacity(vd.Window, alpha);
}
}

ImGui_ImplSDL2_SetWindowFocus :: proc(viewport : ^ImGuiViewport)
{
    vd := (ImGui_ImplSDL2_ViewportData*)viewport.PlatformUserData;
    SDL_RaiseWindow(vd.Window);
}

ImGui_ImplSDL2_GetWindowFocus :: proc(viewport : ^ImGuiViewport) -> bool
{
    vd := (ImGui_ImplSDL2_ViewportData*)viewport.PlatformUserData;
    return (SDL_GetWindowFlags(vd.Window) & SDL_WINDOW_INPUT_FOCUS) != 0;
}

ImGui_ImplSDL2_GetWindowMinimized :: proc(viewport : ^ImGuiViewport) -> bool
{
    vd := (ImGui_ImplSDL2_ViewportData*)viewport.PlatformUserData;
    return (SDL_GetWindowFlags(vd.Window) & SDL_WINDOW_MINIMIZED) != 0;
}

ImGui_ImplSDL2_RenderWindow :: proc(viewport : ^ImGuiViewport, rawptr)
{
    vd := (ImGui_ImplSDL2_ViewportData*)viewport.PlatformUserData;
    if (vd.GLContext) {
        SDL_GL_MakeCurrent(vd.Window, vd.GLContext);
    }

}

ImGui_ImplSDL2_SwapBuffers :: proc(viewport : ^ImGuiViewport, rawptr)
{
    vd := (ImGui_ImplSDL2_ViewportData*)viewport.PlatformUserData;
    if (vd.GLContext)
    {
        SDL_GL_MakeCurrent(vd.Window, vd.GLContext);
        SDL_GL_SwapWindow(vd.Window);
    }
}

// Vulkan support (the Vulkan renderer needs to call a platform-side support function to create the surface)
// SDL is graceful enough to _not_ need <vulkan/vulkan.h> so we can safely include this.
when SDL_HAS_VULKAN {
ImGui_ImplSDL2_CreateVkSurface :: proc(viewport : ^ImGuiViewport, vk_instance : u64, vk_allocator : rawptr, out_vk_surface : ^u64) -> i32
{
    vd := (ImGui_ImplSDL2_ViewportData*)viewport.PlatformUserData;
    (void)vk_allocator;
    ret := SDL_Vulkan_CreateSurface(vd.Window, (VkInstance)vk_instance, (VkSurfaceKHR*)out_vk_surface);
    return ret ? 0 : 1; // ret ? VK_SUCCESS : VK_NOT_READY
}
} // SDL_HAS_VULKAN

ImGui_ImplSDL2_InitMultiViewportSupport :: proc(window : ^SDL_Window, sdl_gl_context : rawptr)
{
    // Register platform interface (will be coupled with a renderer interface)
    platform_io := &GetPlatformIO();
    platform_io.Platform_CreateWindow = ImGui_ImplSDL2_CreateWindow;
    platform_io.Platform_DestroyWindow = ImGui_ImplSDL2_DestroyWindow;
    platform_io.Platform_ShowWindow = ImGui_ImplSDL2_ShowWindow;
    platform_io.Platform_SetWindowPos = ImGui_ImplSDL2_SetWindowPos;
    platform_io.Platform_GetWindowPos = ImGui_ImplSDL2_GetWindowPos;
    platform_io.Platform_SetWindowSize = ImGui_ImplSDL2_SetWindowSize;
    platform_io.Platform_GetWindowSize = ImGui_ImplSDL2_GetWindowSize;
    platform_io.Platform_SetWindowFocus = ImGui_ImplSDL2_SetWindowFocus;
    platform_io.Platform_GetWindowFocus = ImGui_ImplSDL2_GetWindowFocus;
    platform_io.Platform_GetWindowMinimized = ImGui_ImplSDL2_GetWindowMinimized;
    platform_io.Platform_SetWindowTitle = ImGui_ImplSDL2_SetWindowTitle;
    platform_io.Platform_RenderWindow = ImGui_ImplSDL2_RenderWindow;
    platform_io.Platform_SwapBuffers = ImGui_ImplSDL2_SwapBuffers;
when SDL_HAS_WINDOW_ALPHA {
    platform_io.Platform_SetWindowAlpha = ImGui_ImplSDL2_SetWindowAlpha;
}
when SDL_HAS_VULKAN {
    platform_io.Platform_CreateVkSurface = ImGui_ImplSDL2_CreateVkSurface;
}

    // Register main window handle (which is owned by the main application, not by us)
    // This is mostly for simplicity and consistency, so that our code (e.g. mouse handling etc.) can use same logic for main and secondary viewports.
    main_viewport := GetMainViewport();
    vd := IM_NEW(ImGui_ImplSDL2_ViewportData)();
    vd.Window = window;
    vd.WindowID = SDL_GetWindowID(window);
    vd.WindowOwned = false;
    vd.GLContext = sdl_gl_context;
    main_viewport.PlatformUserData = vd;
    main_viewport.PlatformHandle = cast(rawptr) (rawptr)vd.WindowID;
}

ImGui_ImplSDL2_ShutdownMultiViewportSupport :: proc()
{
    DestroyPlatformWindows();
}

//-----------------------------------------------------------------------------


} // #ifndef IMGUI_DISABLE
