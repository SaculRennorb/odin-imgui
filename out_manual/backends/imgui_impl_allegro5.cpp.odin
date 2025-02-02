package imgui

// dear imgui: Renderer + Platform Backend for Allegro 5
// (Info: Allegro 5 is a cross-platform general purpose library for handling windows, inputs, graphics, etc.)

// Implemented features:
//  [X] Renderer: User texture binding. Use 'ALLEGRO_BITMAP*' as ImTextureID. Read the FAQ about ImTextureID!
//  [X] Platform: Keyboard support. Since 1.87 we are using the io.AddKeyEvent() function. Pass ImGuiKey values to all key functions e.g. ImGui::IsKeyPressed(ImGuiKey.Space). [Legacy ALLEGRO_KEY_* values are obsolete since 1.87 and not supported since 1.91.5]
//  [X] Platform: Clipboard support (from Allegro 5.1.12).
//  [X] Platform: Mouse cursor shape and visibility (ImGuiBackendFlags_HasMouseCursors). Disable with 'io.ConfigFlags |= ImGuiConfigFlags_NoMouseCursorChange'.
// Missing features or Issues:
//  [ ] Renderer: The renderer is suboptimal as we need to unindex our buffers and convert vertices manually.
//  [ ] Platform: Missing gamepad support.
//  [ ] Renderer: Multi-viewport support (multiple windows).

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// Learn about Dear ImGui:
// - FAQ                  https://dearimgui.com/faq
// - Getting Started      https://dearimgui.com/getting-started
// - Documentation        https://dearimgui.com/docs (same as your local docs/ folder).
// - Introduction, links and more at the top of imgui.cpp

// CHANGELOG
// (minor and older changes stripped away, please see git history for details)
//  2025-01-06: Avoid calling al_set_mouse_cursor() repeatedly since it appears to leak on on X11 (#8256).
//  2024-08-22: moved some OS/backend related function pointers from ImGuiIO to ImGuiPlatformIO:
//               - io.GetClipboardTextFn    -> platform_io.Platform_GetClipboardTextFn
//               - io.SetClipboardTextFn    -> platform_io.Platform_SetClipboardTextFn
//  2022-11-30: Renderer: Restoring using al_draw_indexed_prim() when Allegro version is >= 5.2.5.
//  2022-10-11: Using 'nullptr' instead of 'NULL' as per our switch to C++11.
//  2022-09-26: Inputs: Renamed ImGuiKey.ModXXX introduced in 1.87 to ImGuiMod_XXX (old names still supported).
//  2022-01-26: Inputs: replaced short-lived io.AddKeyModsEvent() (added two weeks ago) with io.AddKeyEvent() using ImGuiKey.ModXXX flags. Sorry for the confusion.
//  2022-01-17: Inputs: calling new io.AddMousePosEvent(), io.AddMouseButtonEvent(), io.AddMouseWheelEvent() API (1.87+).
//  2022-01-17: Inputs: always calling io.AddKeyModsEvent() next and before key event (not in NewFrame) to fix input queue with very low framerates.
//  2022-01-10: Inputs: calling new io.AddKeyEvent(), io.AddKeyModsEvent() + io.SetKeyEventNativeData() API (1.87+). Support for full ImGuiKey range.
//  2021-12-08: Renderer: Fixed mishandling of the ImDrawCmd::IdxOffset field! This is an old bug but it never had an effect until some internal rendering changes in 1.86.
//  2021-08-17: Calling io.AddFocusEvent() on ALLEGRO_EVENT_DISPLAY_SWITCH_OUT/ALLEGRO_EVENT_DISPLAY_SWITCH_IN events.
//  2021-06-29: Reorganized backend to pull data from a single structure to facilitate usage with multiple-contexts (all g_XXXX access changed to bd->XXXX).
//  2021-05-19: Renderer: Replaced direct access to ImDrawCmd::TextureId with a call to ImDrawCmd::GetTexID(). (will become a requirement)
//  2021-02-18: Change blending equation to preserve alpha in output buffer.
//  2020-08-10: Inputs: Fixed horizontal mouse wheel direction.
//  2019-12-05: Inputs: Added support for ImGuiMouseCursor_NotAllowed mouse cursor.
//  2019-07-21: Inputs: Added mapping for ImGuiKey.KeyPadEnter.
//  2019-05-11: Inputs: Don't filter character value from ALLEGRO_EVENT_KEY_CHAR before calling AddInputCharacter().
//  2019-04-30: Renderer: Added support for special ImDrawCallback_ResetRenderState callback to reset render state.
//  2018-11-30: Platform: Added touchscreen support.
//  2018-11-30: Misc: Setting up io.BackendPlatformName/io.BackendRendererName so they can be displayed in the About Window.
//  2018-06-13: Platform: Added clipboard support (from Allegro 5.1.12).
//  2018-06-13: Renderer: Use draw_data->DisplayPos and draw_data->DisplaySize to setup projection matrix and clipping rectangle.
//  2018-06-13: Renderer: Stopped using al_draw_indexed_prim() as it is buggy in Allegro's DX9 backend.
//  2018-06-13: Renderer: Backup/restore transform and clipping rectangle.
//  2018-06-11: Misc: Setup io.BackendFlags ImGuiBackendFlags_HasMouseCursors flag + honor ImGuiConfigFlags_NoMouseCursorChange flag.
//  2018-04-18: Misc: Renamed file from imgui_impl_a5.cpp to imgui_impl_allegro5.cpp.
//  2018-04-18: Misc: Added support for 32-bit vertex indices to avoid conversion at runtime. Added imconfig_allegro5.h to enforce 32-bit indices when included from imgui.h.
//  2018-02-16: Misc: Obsoleted the io.RenderDrawListsFn callback and exposed ImGui_ImplAllegro5_RenderDrawData() in the .h file so you can call it yourself.
//  2018-02-06: Misc: Removed call to ImGui::Shutdown() which is not available from 1.60 WIP, user needs to call CreateContext/DestroyContext themselves.
//  2018-02-06: Inputs: Added mapping for ImGuiKey.Space.

when !(IMGUI_DISABLE) {

// Allegro
when _WIN32 {
}
#define ALLEGRO_HAS_CLIPBOARD           ((ALLEGRO_VERSION_INT & ~ALLEGRO_UNSTABLE_BIT) >= ((5 << 24) | (1 << 16) | (12 << 8))) // Clipboard only supported from Allegro 5.1.12
#define ALLEGRO_HAS_DRAW_INDEXED_PRIM   ((ALLEGRO_VERSION_INT & ~ALLEGRO_UNSTABLE_BIT) >= ((5 << 24) | (2 << 16) | ( 5 << 8))) // DX9 implementation of al_draw_indexed_prim() got fixed in Allegro 5.2.5

// Visual Studio warnings
when _MSC_VER {
}

ImDrawVertAllegro :: struct
{
    pos : ImVec2,
    uv : ImVec2,
    col : ALLEGRO_COLOR,
};

// FIXME-OPT: Unfortunately Allegro doesn't support 32-bit packed colors so we have to convert them to 4 float as well..
// FIXME-OPT: Consider inlining al_map_rgba()?
// see https://github.com/liballeg/allegro5/blob/master/src/pixels.c#L554
// and https://github.com/liballeg/allegro5/blob/master/include/allegro5/internal/aintern_pixels.h
#define DRAW_VERT_IMGUI_TO_ALLEGRO(DST, SRC)  { (DST)->pos = (SRC)->pos; (DST)->uv = (SRC)->uv; unsigned char* c = (unsigned char*)&(SRC)->col; (DST)->col = al_map_rgba(c[0], c[1], c[2], c[3]); }

// Allegro Data
ImGui_ImplAllegro5_Data :: struct
{
    Display : ^ALLEGRO_DISPLAY,
    Texture : ^ALLEGRO_BITMAP,
    Time : f64,
    MouseCursorInvisible : ^ALLEGRO_MOUSE_CURSOR,
    VertexDecl : ^ALLEGRO_VERTEX_DECL,
    ClipboardTextData : ^u8,
    LastCursor : ImGuiMouseCursor,

    BufVertices : [dynamic]ImDrawVertAllegro,
    BufIndices : [dynamic]i32,

    ImGui_ImplAllegro5_Data()   { memset((rawptr)this, 0, size_of(*this)); }
};

// Backend data stored in io.BackendPlatformUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
// FIXME: multi-context support is not well tested and probably dysfunctional in this backend.
ImGui_ImplAllegro5_Data* ImGui_ImplAllegro5_GetBackendData()     { return GetCurrentContext() ? (ImGui_ImplAllegro5_Data*)GetIO().BackendPlatformUserData : nullptr; }

ImGui_ImplAllegro5_SetupRenderState :: proc(draw_data : ^ImDrawData)
{
    // Setup blending
    al_set_separate_blender(ALLEGRO_ADD, ALLEGRO_ALPHA, ALLEGRO_INVERSE_ALPHA, ALLEGRO_ADD, ALLEGRO_ONE, ALLEGRO_INVERSE_ALPHA);

    // Setup orthographic projection matrix
    // Our visible imgui space lies from draw_data->DisplayPos (top left) to draw_data->DisplayPos+data_data->DisplaySize (bottom right).
    {
        L := draw_data.DisplayPos.x;
        R := draw_data.DisplayPos.x + draw_data.DisplaySize.x;
        T := draw_data.DisplayPos.y;
        B := draw_data.DisplayPos.y + draw_data.DisplaySize.y;
        transform : ALLEGRO_TRANSFORM
        al_identity_transform(&transform);
        al_use_transform(&transform);
        al_orthographic_transform(&transform, L, T, 1.0, R, B, -1.0);
        al_use_projection_transform(&transform);
    }
}

// Render function.
ImGui_ImplAllegro5_RenderDrawData :: proc(draw_data : ^ImDrawData)
{
    // Avoid rendering when minimized
    if (draw_data.DisplaySize.x <= 0.0 || draw_data.DisplaySize.y <= 0.0)   do return

    // Backup Allegro state that will be modified
    bd := ImGui_ImplAllegro5_GetBackendData();
    last_transform := *al_get_current_transform();
    last_projection_transform := *al_get_current_projection_transform();
    last_clip_x, last_clip_y, last_clip_w, last_clip_h : i32
    al_get_clipping_rectangle(&last_clip_x, &last_clip_y, &last_clip_w, &last_clip_h);
    last_blender_op, last_blender_src, last_blender_dst : i32
    al_get_blender(&last_blender_op, &last_blender_src, &last_blender_dst);

    // Setup desired render state
    ImGui_ImplAllegro5_SetupRenderState(draw_data);

    // Render command lists
    for int n = 0; n < draw_data.CmdListsCount; n += 1
    {
        const ImDrawList* draw_list = draw_data.CmdLists[n];

        ImVector<ImDrawVertAllegro>& vertices = bd.BufVertices;
when ALLEGRO_HAS_DRAW_INDEXED_PRIM {
        vertices.resize(draw_list.VtxBuffer.Size);
        for int i = 0; i < len(draw_list.VtxBuffer); i += 1
        {
            const ImDrawVert* src_v = &draw_list.VtxBuffer[i];
            dst_v := &vertices[i];
            DRAW_VERT_IMGUI_TO_ALLEGRO(dst_v, src_v);
        }
        const i32* indices = nullptr;
        if (size_of(ImDrawIdx) == 2)
        {
            // FIXME-OPT: Allegro doesn't support 16-bit indices.
            // You can '#define ImDrawIdx int' in imconfig.h to request Dear ImGui to output 32-bit indices.
            // Otherwise, we convert them from 16-bit to 32-bit at runtime here, which works perfectly but is a little wasteful.
            bd.BufIndices.resize(draw_list.IdxBuffer.Size);
            for int i = 0; i < len(draw_list.IdxBuffer); ++i
                bd.BufIndices[i] = cast(i32) draw_list.IdxBuffer.Data[i];
            indices = bd.BufIndices.Data;
        }
        else if (size_of(ImDrawIdx) == 4)
        {
            indices = (const i32*)draw_list.IdxBuffer.Data;
        }
} else {
        // Allegro's implementation of al_draw_indexed_prim() for DX9 was broken until 5.2.5. Unindex buffers ourselves while converting vertex format.
        vertices.resize(draw_list.IdxBuffer.Size);
        for int i = 0; i < len(draw_list.IdxBuffer); i += 1
        {
            const ImDrawVert* src_v = &draw_list.VtxBuffer[draw_list.IdxBuffer[i]];
            dst_v := &vertices[i];
            DRAW_VERT_IMGUI_TO_ALLEGRO(dst_v, src_v);
        }
}

        // Render command lists
        clip_off := draw_data.DisplayPos;
        for int cmd_i = 0; cmd_i < len(draw_list.CmdBuffer); cmd_i += 1
        {
            const ImDrawCmd* pcmd = &draw_list.CmdBuffer[cmd_i];
            if (pcmd.UserCallback)
            {
                // User callback, registered via ImDrawList::AddCallback()
                // (ImDrawCallback_ResetRenderState is a special callback value used by the user to request the renderer to reset render state.)
                if (pcmd.UserCallback == ImDrawCallback_ResetRenderState)
                    ImGui_ImplAllegro5_SetupRenderState(draw_data);
                else
                    pcmd.UserCallback(draw_list, pcmd);
            }
            else
            {
                // Project scissor/clipping rectangles into framebuffer space
                clip_min := ImVec2{pcmd.ClipRect.x - clip_off.x, pcmd.ClipRect.y - clip_off.y};
                clip_max := ImVec2{pcmd.ClipRect.z - clip_off.x, pcmd.ClipRect.w - clip_off.y};
                if (clip_max.x <= clip_min.x || clip_max.y <= clip_min.y)   do continue

                // Apply scissor/clipping rectangle, Draw
                texture := (ALLEGRO_BITMAP*)pcmd.GetTexID();
                al_set_clipping_rectangle(clip_min.x, clip_min.y, clip_max.x - clip_min.x, clip_max.y - clip_min.y);
when ALLEGRO_HAS_DRAW_INDEXED_PRIM {
                al_draw_indexed_prim(&vertices[0], bd.VertexDecl, texture, &indices[pcmd.IdxOffset], pcmd.ElemCount, ALLEGRO_PRIM_TRIANGLE_LIST);
} else {
                al_draw_prim(&vertices[0], bd.VertexDecl, texture, pcmd.IdxOffset, pcmd.IdxOffset + pcmd.ElemCount, ALLEGRO_PRIM_TRIANGLE_LIST);
}
            }
        }
    }

    // Restore modified Allegro state
    al_set_blender(last_blender_op, last_blender_src, last_blender_dst);
    al_set_clipping_rectangle(last_clip_x, last_clip_y, last_clip_w, last_clip_h);
    al_use_transform(&last_transform);
    al_use_projection_transform(&last_projection_transform);
}

ImGui_ImplAllegro5_CreateDeviceObjects :: proc() -> bool
{
    // Build texture atlas
    bd := ImGui_ImplAllegro5_GetBackendData();
    io := GetIO();
    pixels : ^u8
    width, height : i32
    io.Fonts.GetTexDataAsRGBA32(&pixels, &width, &height);

    // Create texture
    // (Bilinear sampling is required by default. Set 'io.Fonts->Flags |= ImFontAtlasFlags_NoBakedLines' or 'style.AntiAliasedLinesUseTex = false' to allow point/nearest sampling)
    flags := al_get_new_bitmap_flags();
    fmt := al_get_new_bitmap_format();
    al_set_new_bitmap_flags(ALLEGRO_MEMORY_BITMAP | ALLEGRO_MIN_LINEAR | ALLEGRO_MAG_LINEAR);
    al_set_new_bitmap_format(ALLEGRO_PIXEL_FORMAT_ABGR_8888_LE);
    img := al_create_bitmap(width, height);
    al_set_new_bitmap_flags(flags);
    al_set_new_bitmap_format(fmt);
    if (!img)   do return false

    locked_img := al_lock_bitmap(img, al_get_bitmap_format(img), ALLEGRO_LOCK_WRITEONLY);
    if (!locked_img)
    {
        al_destroy_bitmap(img);
        return false;
    }
    memcpy(locked_img.data, pixels, size_of(i32) * width * height);
    al_unlock_bitmap(img);

    // Convert software texture to hardware texture.
    cloned_img := al_clone_bitmap(img);
    al_destroy_bitmap(img);
    if (!cloned_img)   do return false

    // Store our identifier
    io.Fonts.SetTexID((ImTextureID)(rawptr)cloned_img);
    bd.Texture = cloned_img;

    // Create an invisible mouse cursor
    // Because al_hide_mouse_cursor() seems to mess up with the actual inputs..
    mouse_cursor := al_create_bitmap(8, 8);
    bd.MouseCursorInvisible = al_create_mouse_cursor(mouse_cursor, 0, 0);
    al_destroy_bitmap(mouse_cursor);

    return true;
}

ImGui_ImplAllegro5_InvalidateDeviceObjects :: proc()
{
    io := GetIO();
    bd := ImGui_ImplAllegro5_GetBackendData();
    if (bd.Texture)
    {
        io.Fonts.SetTexID(0);
        al_destroy_bitmap(bd.Texture);
        bd.Texture = nullptr;
    }
    if (bd.MouseCursorInvisible)
    {
        al_destroy_mouse_cursor(bd.MouseCursorInvisible);
        bd.MouseCursorInvisible = nullptr;
    }
}

when ALLEGRO_HAS_CLIPBOARD {
ImGui_ImplAllegro5_GetClipboardText :: proc(ImGuiContext*) -> ^u8
{
    bd := ImGui_ImplAllegro5_GetBackendData();
    if (bd.ClipboardTextData) {
        al_free(bd.ClipboardTextData);
    }

    bd.ClipboardTextData = al_get_clipboard_text(bd.Display);
    return bd.ClipboardTextData;
}

ImGui_ImplAllegro5_SetClipboardText :: proc(ImGuiContext*, text : ^u8)
{
    bd := ImGui_ImplAllegro5_GetBackendData();
    al_set_clipboard_text(bd.Display, text);
}
}

// Not static to allow third-party code to use that if they want to (but undocumented)
ImGuiKey ImGui_ImplAllegro5_KeyCodeToImGuiKey(i32 key_code);
ImGui_ImplAllegro5_KeyCodeToImGuiKey :: proc(key_code : i32) -> ImGuiKey
{
    switch (key_code)
    {
        case ALLEGRO_KEY_TAB: return ImGuiKey.Tab;
        case ALLEGRO_KEY_LEFT: return ImGuiKey.LeftArrow;
        case ALLEGRO_KEY_RIGHT: return ImGuiKey.RightArrow;
        case ALLEGRO_KEY_UP: return ImGuiKey.UpArrow;
        case ALLEGRO_KEY_DOWN: return ImGuiKey.DownArrow;
        case ALLEGRO_KEY_PGUP: return ImGuiKey.PageUp;
        case ALLEGRO_KEY_PGDN: return ImGuiKey.PageDown;
        case ALLEGRO_KEY_HOME: return ImGuiKey.Home;
        case ALLEGRO_KEY_END: return ImGuiKey.End;
        case ALLEGRO_KEY_INSERT: return ImGuiKey.Insert;
        case ALLEGRO_KEY_DELETE: return ImGuiKey.Delete;
        case ALLEGRO_KEY_BACKSPACE: return ImGuiKey.Backspace;
        case ALLEGRO_KEY_SPACE: return ImGuiKey.Space;
        case ALLEGRO_KEY_ENTER: return ImGuiKey.Enter;
        case ALLEGRO_KEY_ESCAPE: return ImGuiKey.Escape;
        case ALLEGRO_KEY_QUOTE: return ImGuiKey.Apostrophe;
        case ALLEGRO_KEY_COMMA: return ImGuiKey.Comma;
        case ALLEGRO_KEY_MINUS: return ImGuiKey.Minus;
        case ALLEGRO_KEY_FULLSTOP: return ImGuiKey.Period;
        case ALLEGRO_KEY_SLASH: return ImGuiKey.Slash;
        case ALLEGRO_KEY_SEMICOLON: return ImGuiKey.Semicolon;
        case ALLEGRO_KEY_EQUALS: return ImGuiKey.Equal;
        case ALLEGRO_KEY_OPENBRACE: return ImGuiKey.LeftBracket;
        case ALLEGRO_KEY_BACKSLASH: return ImGuiKey.Backslash;
        case ALLEGRO_KEY_CLOSEBRACE: return ImGuiKey.RightBracket;
        case ALLEGRO_KEY_TILDE: return ImGuiKey.GraveAccent;
        case ALLEGRO_KEY_CAPSLOCK: return ImGuiKey.CapsLock;
        case ALLEGRO_KEY_SCROLLLOCK: return ImGuiKey.ScrollLock;
        case ALLEGRO_KEY_NUMLOCK: return ImGuiKey.NumLock;
        case ALLEGRO_KEY_PRINTSCREEN: return ImGuiKey.PrintScreen;
        case ALLEGRO_KEY_PAUSE: return ImGuiKey.Pause;
        case ALLEGRO_KEY_PAD_0: return ImGuiKey.Keypad0;
        case ALLEGRO_KEY_PAD_1: return ImGuiKey.Keypad1;
        case ALLEGRO_KEY_PAD_2: return ImGuiKey.Keypad2;
        case ALLEGRO_KEY_PAD_3: return ImGuiKey.Keypad3;
        case ALLEGRO_KEY_PAD_4: return ImGuiKey.Keypad4;
        case ALLEGRO_KEY_PAD_5: return ImGuiKey.Keypad5;
        case ALLEGRO_KEY_PAD_6: return ImGuiKey.Keypad6;
        case ALLEGRO_KEY_PAD_7: return ImGuiKey.Keypad7;
        case ALLEGRO_KEY_PAD_8: return ImGuiKey.Keypad8;
        case ALLEGRO_KEY_PAD_9: return ImGuiKey.Keypad9;
        case ALLEGRO_KEY_PAD_DELETE: return ImGuiKey.KeypadDecimal;
        case ALLEGRO_KEY_PAD_SLASH: return ImGuiKey.KeypadDivide;
        case ALLEGRO_KEY_PAD_ASTERISK: return ImGuiKey.KeypadMultiply;
        case ALLEGRO_KEY_PAD_MINUS: return ImGuiKey.KeypadSubtract;
        case ALLEGRO_KEY_PAD_PLUS: return ImGuiKey.KeypadAdd;
        case ALLEGRO_KEY_PAD_ENTER: return ImGuiKey.KeypadEnter;
        case ALLEGRO_KEY_PAD_EQUALS: return ImGuiKey.KeypadEqual;
        case ALLEGRO_KEY_LCTRL: return ImGuiKey.LeftCtrl;
        case ALLEGRO_KEY_LSHIFT: return ImGuiKey.LeftShift;
        case ALLEGRO_KEY_ALT: return ImGuiKey.LeftAlt;
        case ALLEGRO_KEY_LWIN: return ImGuiKey.LeftSuper;
        case ALLEGRO_KEY_RCTRL: return ImGuiKey.RightCtrl;
        case ALLEGRO_KEY_RSHIFT: return ImGuiKey.RightShift;
        case ALLEGRO_KEY_ALTGR: return ImGuiKey.RightAlt;
        case ALLEGRO_KEY_RWIN: return ImGuiKey.RightSuper;
        case ALLEGRO_KEY_MENU: return ImGuiKey.Menu;
        case ALLEGRO_KEY_0: return ImGuiKey._0;
        case ALLEGRO_KEY_1: return ImGuiKey._1;
        case ALLEGRO_KEY_2: return ImGuiKey._2;
        case ALLEGRO_KEY_3: return ImGuiKey._3;
        case ALLEGRO_KEY_4: return ImGuiKey._4;
        case ALLEGRO_KEY_5: return ImGuiKey._5;
        case ALLEGRO_KEY_6: return ImGuiKey._6;
        case ALLEGRO_KEY_7: return ImGuiKey._7;
        case ALLEGRO_KEY_8: return ImGuiKey._8;
        case ALLEGRO_KEY_9: return ImGuiKey._9;
        case ALLEGRO_KEY_A: return ImGuiKey.A;
        case ALLEGRO_KEY_B: return ImGuiKey.B;
        case ALLEGRO_KEY_C: return ImGuiKey.C;
        case ALLEGRO_KEY_D: return ImGuiKey.D;
        case ALLEGRO_KEY_E: return ImGuiKey.E;
        case ALLEGRO_KEY_F: return ImGuiKey.F;
        case ALLEGRO_KEY_G: return ImGuiKey.G;
        case ALLEGRO_KEY_H: return ImGuiKey.H;
        case ALLEGRO_KEY_I: return ImGuiKey.I;
        case ALLEGRO_KEY_J: return ImGuiKey.J;
        case ALLEGRO_KEY_K: return ImGuiKey.K;
        case ALLEGRO_KEY_L: return ImGuiKey.L;
        case ALLEGRO_KEY_M: return ImGuiKey.M;
        case ALLEGRO_KEY_N: return ImGuiKey.N;
        case ALLEGRO_KEY_O: return ImGuiKey.O;
        case ALLEGRO_KEY_P: return ImGuiKey.P;
        case ALLEGRO_KEY_Q: return ImGuiKey.Q;
        case ALLEGRO_KEY_R: return ImGuiKey.R;
        case ALLEGRO_KEY_S: return ImGuiKey.S;
        case ALLEGRO_KEY_T: return ImGuiKey.T;
        case ALLEGRO_KEY_U: return ImGuiKey.U;
        case ALLEGRO_KEY_V: return ImGuiKey.V;
        case ALLEGRO_KEY_W: return ImGuiKey.W;
        case ALLEGRO_KEY_X: return ImGuiKey.X;
        case ALLEGRO_KEY_Y: return ImGuiKey.Y;
        case ALLEGRO_KEY_Z: return ImGuiKey.Z;
        case ALLEGRO_KEY_F1: return ImGuiKey.F1;
        case ALLEGRO_KEY_F2: return ImGuiKey.F2;
        case ALLEGRO_KEY_F3: return ImGuiKey.F3;
        case ALLEGRO_KEY_F4: return ImGuiKey.F4;
        case ALLEGRO_KEY_F5: return ImGuiKey.F5;
        case ALLEGRO_KEY_F6: return ImGuiKey.F6;
        case ALLEGRO_KEY_F7: return ImGuiKey.F7;
        case ALLEGRO_KEY_F8: return ImGuiKey.F8;
        case ALLEGRO_KEY_F9: return ImGuiKey.F9;
        case ALLEGRO_KEY_F10: return ImGuiKey.F10;
        case ALLEGRO_KEY_F11: return ImGuiKey.F11;
        case ALLEGRO_KEY_F12: return ImGuiKey.F12;
        case: return ImGuiKey.None;
    }
}

ImGui_ImplAllegro5_Init :: proc(display : ^ALLEGRO_DISPLAY) -> bool
{
    io := GetIO();
    IMGUI_CHECKVERSION();
    assert(io.BackendPlatformUserData == nullptr, "Already initialized a platform backend!");

    // Setup backend capabilities flags
    bd := IM_NEW(ImGui_ImplAllegro5_Data)();
    io.BackendPlatformUserData = cast(rawptr) bd;
    io.BackendPlatformName = io.BackendRendererName = "imgui_impl_allegro5";
    io.BackendFlags |= ImGuiBackendFlags_HasMouseCursors;       // We can honor GetMouseCursor() values (optional)

    bd.Display = display;
    bd.LastCursor = ALLEGRO_SYSTEM_MOUSE_CURSOR_NONE;

    // Create custom vertex declaration.
    // Unfortunately Allegro doesn't support 32-bit packed colors so we have to convert them to 4 floats.
    // We still use a custom declaration to use 'ALLEGRO_PRIM_TEX_COORD' instead of 'ALLEGRO_PRIM_TEX_COORD_PIXEL' else we can't do a reliable conversion.
    ALLEGRO_VERTEX_ELEMENT elems[] =
    {
        { ALLEGRO_PRIM_POSITION, ALLEGRO_PRIM_FLOAT_2, offset_of(ImDrawVertAllegro, pos) },
        { ALLEGRO_PRIM_TEX_COORD, ALLEGRO_PRIM_FLOAT_2, offset_of(ImDrawVertAllegro, uv) },
        { ALLEGRO_PRIM_COLOR_ATTR, 0, offset_of(ImDrawVertAllegro, col) },
        { 0, 0, 0 }
    };
    bd.VertexDecl = al_create_vertex_decl(elems, size_of(ImDrawVertAllegro));

when ALLEGRO_HAS_CLIPBOARD {
    platform_io := &GetPlatformIO();
    platform_io.Platform_SetClipboardTextFn = ImGui_ImplAllegro5_SetClipboardText;
    platform_io.Platform_GetClipboardTextFn = ImGui_ImplAllegro5_GetClipboardText;
}

    return true;
}

ImGui_ImplAllegro5_Shutdown :: proc()
{
    bd := ImGui_ImplAllegro5_GetBackendData();
    assert(bd != nullptr, "No platform backend to shutdown, or already shutdown?");
    io := GetIO();

    ImGui_ImplAllegro5_InvalidateDeviceObjects();
    if (bd.VertexDecl) {
        al_destroy_vertex_decl(bd.VertexDecl);
    }

    if (bd.ClipboardTextData) {
        al_free(bd.ClipboardTextData);
    }

    io.BackendPlatformName = io.BackendRendererName = nullptr;
    io.BackendPlatformUserData = nullptr;
    io.BackendFlags &= ~ImGuiBackendFlags_HasMouseCursors;
    IM_DELETE(bd);
}

// ev->keyboard.modifiers seems always zero so using that...
ImGui_ImplAllegro5_UpdateKeyModifiers :: proc()
{
    io := GetIO();
    keys : ALLEGRO_KEYBOARD_STATE
    al_get_keyboard_state(&keys);
    io.AddKeyEvent(ImGuiKey.Mod_Ctrl, al_key_down(&keys, ALLEGRO_KEY_LCTRL) || al_key_down(&keys, ALLEGRO_KEY_RCTRL));
    io.AddKeyEvent(ImGuiKey.Mod_Shift, al_key_down(&keys, ALLEGRO_KEY_LSHIFT) || al_key_down(&keys, ALLEGRO_KEY_RSHIFT));
    io.AddKeyEvent(ImGuiKey.Mod_Alt, al_key_down(&keys, ALLEGRO_KEY_ALT) || al_key_down(&keys, ALLEGRO_KEY_ALTGR));
    io.AddKeyEvent(ImGuiKey.Mod_Super, al_key_down(&keys, ALLEGRO_KEY_LWIN) || al_key_down(&keys, ALLEGRO_KEY_RWIN));
}

// You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
// - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application, or clear/overwrite your copy of the mouse data.
// - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application, or clear/overwrite your copy of the keyboard data.
// Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.
ImGui_ImplAllegro5_ProcessEvent :: proc(ev : ^ALLEGRO_EVENT) -> bool
{
    bd := ImGui_ImplAllegro5_GetBackendData();
    assert(bd != nullptr, "Context or backend not initialized! Did you call ImGui_ImplAllegro5_Init()?");
    io := GetIO();

    switch (ev.type)
    {
    case ALLEGRO_EVENT_MOUSE_AXES:
        if (ev.mouse.display == bd.Display)
        {
            io.AddMousePosEvent(ev.mouse.x, ev.mouse.y);
            io.AddMouseWheelEvent(-ev.mouse.dw, ev.mouse.dz);
        }
        return true;
    case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
    case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
        if (ev.mouse.display == bd.Display && ev.mouse.button > 0 && ev.mouse.button <= 5)
            io.AddMouseButtonEvent(ev.mouse.button - 1, ev.type == ALLEGRO_EVENT_MOUSE_BUTTON_DOWN);
        return true;
    case ALLEGRO_EVENT_TOUCH_MOVE:
        if (ev.touch.display == bd.Display)
            io.AddMousePosEvent(ev.touch.x, ev.touch.y);
        return true;
    case ALLEGRO_EVENT_TOUCH_BEGIN:
    case ALLEGRO_EVENT_TOUCH_END:
    case ALLEGRO_EVENT_TOUCH_CANCEL:
        if (ev.touch.display == bd.Display && ev.touch.primary)
            io.AddMouseButtonEvent(0, ev.type == ALLEGRO_EVENT_TOUCH_BEGIN);
        return true;
    case ALLEGRO_EVENT_MOUSE_LEAVE_DISPLAY:
        if (ev.mouse.display == bd.Display)
            io.AddMousePosEvent(-math.F32_MAX, -math.F32_MAX);
        return true;
    case ALLEGRO_EVENT_KEY_CHAR:
        if (ev.keyboard.display == bd.Display)
            if (ev.keyboard.unichar != 0)
                io.AddInputCharacter(cast(u32) ev.keyboard.unichar);
        return true;
    case ALLEGRO_EVENT_KEY_DOWN:
    case ALLEGRO_EVENT_KEY_UP:
        if (ev.keyboard.display == bd.Display)
        {
            ImGui_ImplAllegro5_UpdateKeyModifiers();
            key := ImGui_ImplAllegro5_KeyCodeToImGuiKey(ev.keyboard.keycode);
            io.AddKeyEvent(key, (ev.type == ALLEGRO_EVENT_KEY_DOWN));
            io.SetKeyEventNativeData(key, ev.keyboard.keycode, -1); // To support legacy indexing (<1.87 user code)
        }
        return true;
    case ALLEGRO_EVENT_DISPLAY_SWITCH_OUT:
        if (ev.display.source == bd.Display)   do io.AddFocusEvent(false)
        return true;
    case ALLEGRO_EVENT_DISPLAY_SWITCH_IN:
        if (ev.display.source == bd.Display)
        {
            io.AddFocusEvent(true);
when defined(ALLEGRO_UNSTABLE) {
            al_clear_keyboard_state(bd.Display);
}
        }
        return true;
    }
    return false;
}

ImGui_ImplAllegro5_UpdateMouseCursor :: proc()
{
    io := GetIO();
    if (.NoMouseCursorChange in io.ConfigFlags)   do return

    bd := ImGui_ImplAllegro5_GetBackendData();
    imgui_cursor := GetMouseCursor();

    // Hide OS mouse cursor if imgui is drawing it
    if (io.MouseDrawCursor)
        imgui_cursor = ImGuiMouseCursor_None;

    if (bd.LastCursor == imgui_cursor)   do return
    bd.LastCursor = imgui_cursor;
    if (imgui_cursor == ImGuiMouseCursor_None)
    {
        al_set_mouse_cursor(bd.Display, bd.MouseCursorInvisible);
    }
    else
    {
        cursor_id := ALLEGRO_SYSTEM_MOUSE_CURSOR_DEFAULT;
        switch (imgui_cursor)
        {
        case ImGuiMouseCursor_TextInput:    cursor_id = ALLEGRO_SYSTEM_MOUSE_CURSOR_EDIT; break;
        case ImGuiMouseCursor_ResizeAll:    cursor_id = ALLEGRO_SYSTEM_MOUSE_CURSOR_MOVE; break;
        case ImGuiMouseCursor_ResizeNS:     cursor_id = ALLEGRO_SYSTEM_MOUSE_CURSOR_RESIZE_N; break;
        case ImGuiMouseCursor_ResizeEW:     cursor_id = ALLEGRO_SYSTEM_MOUSE_CURSOR_RESIZE_E; break;
        case ImGuiMouseCursor_ResizeNESW:   cursor_id = ALLEGRO_SYSTEM_MOUSE_CURSOR_RESIZE_NE; break;
        case ImGuiMouseCursor_ResizeNWSE:   cursor_id = ALLEGRO_SYSTEM_MOUSE_CURSOR_RESIZE_NW; break;
        case ImGuiMouseCursor_NotAllowed:   cursor_id = ALLEGRO_SYSTEM_MOUSE_CURSOR_UNAVAILABLE; break;
        }
        al_set_system_mouse_cursor(bd.Display, cursor_id);
    }
}

ImGui_ImplAllegro5_NewFrame :: proc()
{
    bd := ImGui_ImplAllegro5_GetBackendData();
    assert(bd != nullptr, "Context or backend not initialized! Did you call ImGui_ImplAllegro5_Init()?");

    if (!bd.Texture)
        ImGui_ImplAllegro5_CreateDeviceObjects();

    io := GetIO();

    // Setup display size (every frame to accommodate for window resizing)
    w, h : i32
    w = al_get_display_width(bd.Display);
    h = al_get_display_height(bd.Display);
    io.DisplaySize = ImVec2{(f32}w, cast(f32) h);

    // Setup time step
    current_time := al_get_time();
    io.DeltaTime = bd.Time > 0.0 ? (f32)(current_time - bd.Time) : (f32)(1.0 / 60.0);
    bd.Time = current_time;

    // Setup mouse cursor shape
    ImGui_ImplAllegro5_UpdateMouseCursor();
}

//-----------------------------------------------------------------------------

} // #ifndef IMGUI_DISABLE
