package imgui

// dear imgui: Platform Backend for GLUT/FreeGLUT
// This needs to be used along with a Renderer (e.g. OpenGL2)

// !!! GLUT/FreeGLUT IS OBSOLETE PREHISTORIC SOFTWARE. Using GLUT is not recommended unless you really miss the 90's. !!!
// !!! If someone or something is teaching you GLUT today, you are being abused. Please show some resistance. !!!
// !!! Nowadays, prefer using GLFW or SDL instead!

// Implemented features:
//  [X] Platform: Partial keyboard support. Since 1.87 we are using the io.AddKeyEvent() function. Pass ImGuiKey values to all key functions e.g. ImGui::IsKeyPressed(ImGuiKey_Space). [Legacy GLUT values are obsolete since 1.87 and not supported since 1.91.5]
// Missing features or Issues:
//  [ ] Platform: GLUT is unable to distinguish e.g. Backspace from CTRL+H or TAB from CTRL+I
//  [ ] Platform: Missing horizontal mouse wheel support.
//  [ ] Platform: Missing mouse cursor shape/visibility support.
//  [ ] Platform: Missing clipboard support (not supported by Glut).
//  [ ] Platform: Missing gamepad support.
//  [ ] Platform: Missing multi-viewport support (multiple windows).

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// Learn about Dear ImGui:
// - FAQ                  https://dearimgui.com/faq
// - Getting Started      https://dearimgui.com/getting-started
// - Documentation        https://dearimgui.com/docs (same as your local docs/ folder).
// - Introduction, links and more at the top of imgui.cpp

// CHANGELOG
// (minor and older changes stripped away, please see git history for details)
//  2023-04-17: BREAKING: Removed call to ImGui::NewFrame() from ImGui_ImplGLUT_NewFrame(). Needs to be called from the main application loop, like with every other backends.
//  2022-09-26: Inputs: Renamed ImGuiKey_ModXXX introduced in 1.87 to ImGuiMod_XXX (old names still supported).
//  2022-01-26: Inputs: replaced short-lived io.AddKeyModsEvent() (added two weeks ago) with io.AddKeyEvent() using ImGuiKey_ModXXX flags. Sorry for the confusion.
//  2022-01-17: Inputs: calling new io.AddMousePosEvent(), io.AddMouseButtonEvent(), io.AddMouseWheelEvent() API (1.87+).
//  2022-01-10: Inputs: calling new io.AddKeyEvent(), io.AddKeyModsEvent() + io.SetKeyEventNativeData() API (1.87+). Support for full ImGuiKey range.
//  2019-04-03: Misc: Renamed imgui_impl_freeglut.cpp/.h to imgui_impl_glut.cpp/.h.
//  2019-03-25: Misc: Made io.DeltaTime always above zero.
//  2018-11-30: Misc: Setting up io.BackendPlatformName so it can be displayed in the About Window.
//  2018-03-22: Added GLUT Platform binding.

when !(IMGUI_DISABLE) {
GL_SILENCE_DEPRECATION :: true
when __APPLE__ {
} else {
}

when _MSC_VER {
}

g_Time := 0;          // Current time, in milliseconds

// Glut has 1 function for characters and one for "special keys". We map the characters in the 0..255 range and the keys above.
ImGui_ImplGLUT_KeyToImGuiKey := mplGLUT_(i32 key)
{
    switch (key)
    {
        case '\t':                      return ImGuiKey_Tab;
        case 256 + GLUT_KEY_LEFT:       return ImGuiKey_LeftArrow;
        case 256 + GLUT_KEY_RIGHT:      return ImGuiKey_RightArrow;
        case 256 + GLUT_KEY_UP:         return ImGuiKey_UpArrow;
        case 256 + GLUT_KEY_DOWN:       return ImGuiKey_DownArrow;
        case 256 + GLUT_KEY_PAGE_UP:    return ImGuiKey_PageUp;
        case 256 + GLUT_KEY_PAGE_DOWN:  return ImGuiKey_PageDown;
        case 256 + GLUT_KEY_HOME:       return ImGuiKey_Home;
        case 256 + GLUT_KEY_END:        return ImGuiKey_End;
        case 256 + GLUT_KEY_INSERT:     return ImGuiKey_Insert;
        case 127:                       return ImGuiKey_Delete;
        case 8:                         return ImGuiKey_Backspace;
        case ' ':                       return ImGuiKey_Space;
        case 13:                        return ImGuiKey_Enter;
        case 27:                        return ImGuiKey_Escape;
        case 39:                        return ImGuiKey_Apostrophe;
        case 44:                        return ImGuiKey_Comma;
        case 45:                        return ImGuiKey_Minus;
        case 46:                        return ImGuiKey_Period;
        case 47:                        return ImGuiKey_Slash;
        case 59:                        return ImGuiKey_Semicolon;
        case 61:                        return ImGuiKey_Equal;
        case 91:                        return ImGuiKey_LeftBracket;
        case 92:                        return ImGuiKey_Backslash;
        case 93:                        return ImGuiKey_RightBracket;
        case 96:                        return ImGuiKey_GraveAccent;
        //case 0:                         return ImGuiKey_CapsLock;
        //case 0:                         return ImGuiKey_ScrollLock;
        case 256 + 0x006D:              return ImGuiKey_NumLock;
        //case 0:                         return ImGuiKey_PrintScreen;
        //case 0:                         return ImGuiKey_Pause;
        //case '0':                       return ImGuiKey_Keypad0;
        //case '1':                       return ImGuiKey_Keypad1;
        //case '2':                       return ImGuiKey_Keypad2;
        //case '3':                       return ImGuiKey_Keypad3;
        //case '4':                       return ImGuiKey_Keypad4;
        //case '5':                       return ImGuiKey_Keypad5;
        //case '6':                       return ImGuiKey_Keypad6;
        //case '7':                       return ImGuiKey_Keypad7;
        //case '8':                       return ImGuiKey_Keypad8;
        //case '9':                       return ImGuiKey_Keypad9;
        //case 46:                        return ImGuiKey_KeypadDecimal;
        //case 47:                        return ImGuiKey_KeypadDivide;
        case 42:                        return ImGuiKey_KeypadMultiply;
        //case 45:                        return ImGuiKey_KeypadSubtract;
        case 43:                        return ImGuiKey_KeypadAdd;
        //case 13:                        return ImGuiKey_KeypadEnter;
        //case 0:                         return ImGuiKey_KeypadEqual;
        case 256 + 0x0072:              return ImGuiKey_LeftCtrl;
        case 256 + 0x0070:              return ImGuiKey_LeftShift;
        case 256 + 0x0074:              return ImGuiKey_LeftAlt;
        //case 0:                         return ImGuiKey_LeftSuper;
        case 256 + 0x0073:              return ImGuiKey_RightCtrl;
        case 256 + 0x0071:              return ImGuiKey_RightShift;
        case 256 + 0x0075:              return ImGuiKey_RightAlt;
        //case 0:                         return ImGuiKey_RightSuper;
        //case 0:                         return ImGuiKey_Menu;
        case '0':                       return ImGuiKey_0;
        case '1':                       return ImGuiKey_1;
        case '2':                       return ImGuiKey_2;
        case '3':                       return ImGuiKey_3;
        case '4':                       return ImGuiKey_4;
        case '5':                       return ImGuiKey_5;
        case '6':                       return ImGuiKey_6;
        case '7':                       return ImGuiKey_7;
        case '8':                       return ImGuiKey_8;
        case '9':                       return ImGuiKey_9;
        case 'A': case 'a':             return ImGuiKey_A;
        case 'B': case 'b':             return ImGuiKey_B;
        case 'C': case 'c':             return ImGuiKey_C;
        case 'D': case 'd':             return ImGuiKey_D;
        case 'E': case 'e':             return ImGuiKey_E;
        case 'F': case 'f':             return ImGuiKey_F;
        case 'G': case 'g':             return ImGuiKey_G;
        case 'H': case 'h':             return ImGuiKey_H;
        case 'I': case 'i':             return ImGuiKey_I;
        case 'J': case 'j':             return ImGuiKey_J;
        case 'K': case 'k':             return ImGuiKey_K;
        case 'L': case 'l':             return ImGuiKey_L;
        case 'M': case 'm':             return ImGuiKey_M;
        case 'N': case 'n':             return ImGuiKey_N;
        case 'O': case 'o':             return ImGuiKey_O;
        case 'P': case 'p':             return ImGuiKey_P;
        case 'Q': case 'q':             return ImGuiKey_Q;
        case 'R': case 'r':             return ImGuiKey_R;
        case 'S': case 's':             return ImGuiKey_S;
        case 'T': case 't':             return ImGuiKey_T;
        case 'U': case 'u':             return ImGuiKey_U;
        case 'V': case 'v':             return ImGuiKey_V;
        case 'W': case 'w':             return ImGuiKey_W;
        case 'X': case 'x':             return ImGuiKey_X;
        case 'Y': case 'y':             return ImGuiKey_Y;
        case 'Z': case 'z':             return ImGuiKey_Z;
        case 256 + GLUT_KEY_F1:         return ImGuiKey_F1;
        case 256 + GLUT_KEY_F2:         return ImGuiKey_F2;
        case 256 + GLUT_KEY_F3:         return ImGuiKey_F3;
        case 256 + GLUT_KEY_F4:         return ImGuiKey_F4;
        case 256 + GLUT_KEY_F5:         return ImGuiKey_F5;
        case 256 + GLUT_KEY_F6:         return ImGuiKey_F6;
        case 256 + GLUT_KEY_F7:         return ImGuiKey_F7;
        case 256 + GLUT_KEY_F8:         return ImGuiKey_F8;
        case 256 + GLUT_KEY_F9:         return ImGuiKey_F9;
        case 256 + GLUT_KEY_F10:        return ImGuiKey_F10;
        case 256 + GLUT_KEY_F11:        return ImGuiKey_F11;
        case 256 + GLUT_KEY_F12:        return ImGuiKey_F12;
        case:                        return ImGuiKey_None;
    }
}

ImGui_ImplGLUT_Init :: proc() -> bool
{
    ImGuiIO& io = GetIO();
    IMGUI_CHECKVERSION();

when FREEGLUT {
    io.BackendPlatformName = "imgui_impl_glut (freeglut)";
} else {
    io.BackendPlatformName = "imgui_impl_glut";
}
    g_Time = 0;

    return true;
}

ImGui_ImplGLUT_InstallFuncs :: proc()
{
    glutReshapeFunc(ImGui_ImplGLUT_ReshapeFunc);
    glutMotionFunc(ImGui_ImplGLUT_MotionFunc);
    glutPassiveMotionFunc(ImGui_ImplGLUT_MotionFunc);
    glutMouseFunc(ImGui_ImplGLUT_MouseFunc);
when __FREEGLUT_EXT_H__ {
    glutMouseWheelFunc(ImGui_ImplGLUT_MouseWheelFunc);
}
    glutKeyboardFunc(ImGui_ImplGLUT_KeyboardFunc);
    glutKeyboardUpFunc(ImGui_ImplGLUT_KeyboardUpFunc);
    glutSpecialFunc(ImGui_ImplGLUT_SpecialFunc);
    glutSpecialUpFunc(ImGui_ImplGLUT_SpecialUpFunc);
}

ImGui_ImplGLUT_Shutdown :: proc()
{
    ImGuiIO& io = GetIO();
    io.BackendPlatformName = nullptr;
}

ImGui_ImplGLUT_NewFrame :: proc()
{
    // Setup time step
    ImGuiIO& io = GetIO();
    current_time := glutGet(GLUT_ELAPSED_TIME);
    delta_time_ms := (current_time - g_Time);
    if (delta_time_ms <= 0)
        delta_time_ms = 1;
    io.DeltaTime = delta_time_ms / 1000.0;
    g_Time = current_time;
}

ImGui_ImplGLUT_UpdateKeyModifiers :: proc()
{
    ImGuiIO& io = GetIO();
    glut_key_mods := glutGetModifiers();
    io.AddKeyEvent(ImGuiMod_Ctrl, (glut_key_mods & GLUT_ACTIVE_CTRL) != 0);
    io.AddKeyEvent(ImGuiMod_Shift, (glut_key_mods & GLUT_ACTIVE_SHIFT) != 0);
    io.AddKeyEvent(ImGuiMod_Alt, (glut_key_mods & GLUT_ACTIVE_ALT) != 0);
}

ImGui_ImplGLUT_AddKeyEvent :: proc(key : ImGuiKey, down : bool, native_keycode : i32)
{
    ImGuiIO& io = GetIO();
    io.AddKeyEvent(key, down);
    io.SetKeyEventNativeData(key, native_keycode, -1); // To support legacy indexing (<1.87 user code)
}

ImGui_ImplGLUT_KeyboardFunc :: proc(c : u8, x : i32, y : i32)
{
    // Send character to imgui
    //printf("char_down_func %d '%c'\n", c, c);
    ImGuiIO& io = GetIO();
    if (c >= 32)
        io.AddInputCharacter(cast(u32) c);

    key := ImGui_ImplGLUT_KeyToImGuiKey(c);
    ImGui_ImplGLUT_AddKeyEvent(key, true, c);
    ImGui_ImplGLUT_UpdateKeyModifiers();
    (void)x; (void)y; // Unused
}

ImGui_ImplGLUT_KeyboardUpFunc :: proc(c : u8, x : i32, y : i32)
{
    //printf("char_up_func %d '%c'\n", c, c);
    key := ImGui_ImplGLUT_KeyToImGuiKey(c);
    ImGui_ImplGLUT_AddKeyEvent(key, false, c);
    ImGui_ImplGLUT_UpdateKeyModifiers();
    (void)x; (void)y; // Unused
}

ImGui_ImplGLUT_SpecialFunc :: proc(key : i32, x : i32, y : i32)
{
    //printf("key_down_func %d\n", key);
    imgui_key := ImGui_ImplGLUT_KeyToImGuiKey(key + 256);
    ImGui_ImplGLUT_AddKeyEvent(imgui_key, true, key + 256);
    ImGui_ImplGLUT_UpdateKeyModifiers();
    (void)x; (void)y; // Unused
}

ImGui_ImplGLUT_SpecialUpFunc :: proc(key : i32, x : i32, y : i32)
{
    //printf("key_up_func %d\n", key);
    imgui_key := ImGui_ImplGLUT_KeyToImGuiKey(key + 256);
    ImGui_ImplGLUT_AddKeyEvent(imgui_key, false, key + 256);
    ImGui_ImplGLUT_UpdateKeyModifiers();
    (void)x; (void)y; // Unused
}

ImGui_ImplGLUT_MouseFunc :: proc(glut_button : i32, state : i32, x : i32, y : i32)
{
    ImGuiIO& io = GetIO();
    io.AddMousePosEvent(cast(ast) ast) a2)y);
    button := -1;
    if (glut_button == GLUT_LEFT_BUTTON) button = 0;
    if (glut_button == GLUT_RIGHT_BUTTON) button = 1;
    if (glut_button == GLUT_MIDDLE_BUTTON) button = 2;
    if (button != -1 && (state == GLUT_DOWN || state == GLUT_UP))
        io.AddMouseButtonEvent(button, state == GLUT_DOWN);
}

when __FREEGLUT_EXT_H__ {
ImGui_ImplGLUT_MouseWheelFunc :: proc(button : i32, dir : i32, x : i32, y : i32)
{
    ImGuiIO& io = GetIO();
    io.AddMousePosEvent(cast(ast) ast) a2)y);
    if (dir != 0)
        io.AddMouseWheelEvent(0.0, dir > 0 ? 1.0 : -1.0);
    (void)button; // Unused
}
}

ImGui_ImplGLUT_ReshapeFunc :: proc(w : i32, h : i32)
{
    ImGuiIO& io = GetIO();
    io.DisplaySize = ImVec2{(f32}w, cast(ast) ast
}

ImGui_ImplGLUT_MotionFunc :: proc(x : i32, y : i32)
{
    ImGuiIO& io = GetIO();
    io.AddMousePosEvent(cast(ast) ast) a2)y);
}

//-----------------------------------------------------------------------------

} // #ifndef IMGUI_DISABLE
