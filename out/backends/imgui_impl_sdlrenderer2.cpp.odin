package imgui

// dear imgui: Renderer Backend for SDL_Renderer for SDL2
// (Requires: SDL 2.0.17+)

// Note how SDL_Renderer is an _optional_ component of SDL2.
// For a multi-platform app consider using e.g. SDL+DirectX on Windows and SDL+OpenGL on Linux/OSX.
// If your application will want to render any non trivial amount of graphics other than UI,
// please be aware that SDL_Renderer currently offers a limited graphic API to the end-user and
// it might be difficult to step out of those boundaries.

// Implemented features:
//  [X] Renderer: User texture binding. Use 'SDL_Texture*' as ImTextureID. Read the FAQ about ImTextureID!
//  [X] Renderer: Large meshes support (64k+ vertices) even with 16-bit indices (ImGuiBackendFlags_RendererHasVtxOffset).
//  [X] Renderer: Expose selected render state for draw callbacks to use. Access in '(ImGui_ImplXXXX_RenderState*)GetPlatformIO().Renderer_RenderState'.
// Missing features:
//  [ ] Renderer: Multi-viewport support (multiple windows).

// You can copy and use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// Learn about Dear ImGui:
// - FAQ                  https://dearimgui.com/faq
// - Getting Started      https://dearimgui.com/getting-started
// - Documentation        https://dearimgui.com/docs (same as your local docs/ folder).
// - Introduction, links and more at the top of imgui.cpp

// CHANGELOG
//  2024-10-09: Expose selected render state in ImGui_ImplSDLRenderer2_RenderState, which you can access in 'void* platform_io.Renderer_RenderState' during draw callbacks.
//  2024-05-14: *BREAKING CHANGE* ImGui_ImplSDLRenderer3_RenderDrawData() requires SDL_Renderer* passed as parameter.
//  2023-05-30: Renamed imgui_impl_sdlrenderer.h/.cpp to imgui_impl_sdlrenderer2.h/.cpp to accommodate for upcoming SDL3.
//  2022-10-11: Using 'nullptr' instead of 'NULL' as per our switch to C++11.
//  2021-12-21: Update SDL_RenderGeometryRaw() format to work with SDL 2.0.19.
//  2021-12-03: Added support for large mesh (64K+ vertices), enable ImGuiBackendFlags_RendererHasVtxOffset flag.
//  2021-10-06: Backup and restore modified ClipRect/Viewport.
//  2021-09-21: Initial version.

when !(IMGUI_DISABLE) {

// Clang warnings with -Weverything

// SDL
when !SDL_VERSION_ATLEAST(2,0,17) {
#error This backend requires SDL 2.0.17+ because of SDL_RenderGeometry() function
}

// SDL_Renderer data
ImGui_ImplSDLRenderer2_Data :: struct
{
    Renderer : ^SDL_Renderer,       // Main viewport's renderer
    FontTexture : ^SDL_Texture,
    ImGui_ImplSDLRenderer2_Data()   { memset((rawptr)this, 0, size_of(*this)); }
};

// Backend data stored in io.BackendRendererUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
ImGui_ImplSDLRenderer2_GetBackendData :: proc() -> ^ImGui_ImplSDLRenderer2_Data
{
    return GetCurrentContext() ? (ImGui_ImplSDLRenderer2_Data*)GetIO().BackendRendererUserData : nullptr;
}

// Functions
ImGui_ImplSDLRenderer2_Init :: proc(renderer : ^SDL_Renderer) -> bool
{
    ImGuiIO& io = GetIO();
    IMGUI_CHECKVERSION();
    assert(io.BackendRendererUserData == nullptr, "Already initialized a renderer backend!");
    assert(renderer != nullptr, "SDL_Renderer not initialized!");

    // Setup backend capabilities flags
    bd := IM_NEW(ImGui_ImplSDLRenderer2_Data)();
    io.BackendRendererUserData = (rawptr)bd;
    io.BackendRendererName = "imgui_impl_sdlrenderer2";
    io.BackendFlags |= ImGuiBackendFlags_RendererHasVtxOffset;  // We can honor the ImDrawCmd::VtxOffset field, allowing for large meshes.

    bd.Renderer = renderer;

    return true;
}

ImGui_ImplSDLRenderer2_Shutdown :: proc()
{
    bd := ImGui_ImplSDLRenderer2_GetBackendData();
    assert(bd != nullptr, "No renderer backend to shutdown, or already shutdown?");
    ImGuiIO& io = GetIO();

    ImGui_ImplSDLRenderer2_DestroyDeviceObjects();

    io.BackendRendererName = nullptr;
    io.BackendRendererUserData = nullptr;
    io.BackendFlags &= ~ImGuiBackendFlags_RendererHasVtxOffset;
    IM_DELETE(bd);
}

ImGui_ImplSDLRenderer2_SetupRenderState :: proc(renderer : ^SDL_Renderer)
{
	// Clear out any viewports and cliprect set by the user
    // FIXME: Technically speaking there are lots of other things we could backup/setup/restore during our render process.
	SDL_RenderSetViewport(renderer, nullptr);
	SDL_RenderSetClipRect(renderer, nullptr);
}

ImGui_ImplSDLRenderer2_NewFrame :: proc()
{
    bd := ImGui_ImplSDLRenderer2_GetBackendData();
    assert(bd != nullptr, "Context or backend not initialized! Did you call ImGui_ImplSDLRenderer2_Init()?");

    if (!bd.FontTexture)
        ImGui_ImplSDLRenderer2_CreateDeviceObjects();
}

ImGui_ImplSDLRenderer2_RenderDrawData :: proc(draw_data : ^ImDrawData, renderer : ^SDL_Renderer)
{
	// If there's a scale factor set by the user, use that instead
    // If the user has specified a scale factor to SDL_Renderer already via SDL_RenderSetScale(), SDL will scale whatever we pass
    // to SDL_RenderGeometryRaw() by that scale factor. In that case we don't want to be also scaling it ourselves here.
    rsx := 1.0;
	f32 rsy = 1.0;
	SDL_RenderGetScale(renderer, &rsx, &rsy);
    render_scale : ImVec2
	render_scale.x = (rsx == 1.0) ? draw_data.FramebufferScale.x : 1.0;
	render_scale.y = (rsy == 1.0) ? draw_data.FramebufferScale.y : 1.0;

	// Avoid rendering when minimized, scale coordinates for retina displays (screen coordinates != framebuffer coordinates)
	i32 fb_width = (i32)(draw_data.DisplaySize.x * render_scale.x);
	i32 fb_height = (i32)(draw_data.DisplaySize.y * render_scale.y);
	if (fb_width == 0 || fb_height == 0)
		return;

    // Backup SDL_Renderer state that will be modified to restore it afterwards
    BackupSDLRendererState :: struct
    {
        Viewport : SDL_Rect,
        ClipEnabled : bool,
        ClipRect : SDL_Rect,
    };
    old := {};
    old.ClipEnabled = SDL_RenderIsClipEnabled(renderer) == SDL_TRUE;
    SDL_RenderGetViewport(renderer, &old.Viewport);
    SDL_RenderGetClipRect(renderer, &old.ClipRect);

    // Setup desired state
    ImGui_ImplSDLRenderer2_SetupRenderState(renderer);

    // Setup render state structure (for callbacks and custom texture bindings)
    ImGuiPlatformIO& platform_io = GetPlatformIO();
    render_state : ImGui_ImplSDLRenderer2_RenderState
    render_state.Renderer = renderer;
    platform_io.Renderer_RenderState = &render_state;

	// Will project scissor/clipping rectangles into framebuffer space
	ImVec2 clip_off = draw_data.DisplayPos;         // (0,0) unless using multi-viewports
	ImVec2 clip_scale = render_scale;

    // Render command lists
    for i32 n = 0; n < draw_data.CmdListsCount; n++
    {
        draw_list := draw_data.CmdLists[n];
        vtx_buffer := draw_list.VtxBuffer.Data;
        idx_buffer := draw_list.IdxBuffer.Data;

        for i32 cmd_i = 0; cmd_i < draw_list.CmdBuffer.Size; cmd_i++
        {
            pcmd := &draw_list.CmdBuffer[cmd_i];
            if (pcmd.UserCallback)
            {
                // User callback, registered via ImDrawList::AddCallback()
                // (ImDrawCallback_ResetRenderState is a special callback value used by the user to request the renderer to reset render state.)
                if (pcmd.UserCallback == ImDrawCallback_ResetRenderState)
                    ImGui_ImplSDLRenderer2_SetupRenderState(renderer);
                else
                    pcmd.UserCallback(draw_list, pcmd);
            }
            else
            {
                // Project scissor/clipping rectangles into framebuffer space
                clip_min := ImVec2{(pcmd.ClipRect.x - clip_off.x} * clip_scale.x, (pcmd.ClipRect.y - clip_off.y) * clip_scale.y);
                clip_max := ImVec2{(pcmd.ClipRect.z - clip_off.x} * clip_scale.x, (pcmd.ClipRect.w - clip_off.y) * clip_scale.y);
                if (clip_min.x < 0.0) { clip_min.x = 0.0; }
                if (clip_min.y < 0.0) { clip_min.y = 0.0; }
                if (clip_max.x > cast(ast) ast) dth) dthlip_max.x = cast(x =) cast(x =) c
                if (clip_max.y > cast(ast) ast) ight ightlip_max.y = cast(y =) cast(y =) ca
                if (clip_max.x <= clip_min.x || clip_max.y <= clip_min.y)
                    continue;

                r := { (i32)(clip_min.x), (i32)(clip_min.y), (i32)(clip_max.x - clip_min.x), (i32)(clip_max.y - clip_min.y) };
                SDL_RenderSetClipRect(renderer, &r);

                xy := (const f32*)(const rawptr)((const u8*)(vtx_buffer + pcmd.VtxOffset) + offsetof(ImDrawVert, pos));
                uv := (const f32*)(const rawptr)((const u8*)(vtx_buffer + pcmd.VtxOffset) + offsetof(ImDrawVert, uv));
when SDL_VERSION_ATLEAST(2,0,19) {
                color := (const SDL_Color*)(const rawptr)((const u8*)(vtx_buffer + pcmd.VtxOffset) + offsetof(ImDrawVert, col)); // SDL 2.0.19+
} else {
                color := (const i32*)(const rawptr)((const u8*)(vtx_buffer + pcmd.VtxOffset) + offsetof(ImDrawVert, col)); // SDL 2.0.17 and 2.0.18
}

                // Bind texture, Draw
				SDL_Texture* tex = (SDL_Texture*)pcmd.GetTexID();
                SDL_RenderGeometryRaw(renderer, tex,
                    xy, cast(ast) ast) oft) ofawVert),
                    color, cast(ast) ast) oft) ofawVert),
                    uv, cast(ast) ast) oft) ofawVert),
                    draw_list.VtxBuffer.Size - pcmd.VtxOffset,
                    idx_buffer + pcmd.IdxOffset, pcmd.ElemCount, size_of(ImDrawIdx));
            }
        }
    }
    platform_io.Renderer_RenderState = nullptr;

    // Restore modified SDL_Renderer state
    SDL_RenderSetViewport(renderer, &old.Viewport);
    SDL_RenderSetClipRect(renderer, old.ClipEnabled ? &old.ClipRect : nullptr);
}

// Called by Init/NewFrame/Shutdown
ImGui_ImplSDLRenderer2_CreateFontsTexture :: proc() -> bool
{
    ImGuiIO& io = GetIO();
    bd := ImGui_ImplSDLRenderer2_GetBackendData();

    // Build texture atlas
    pixels : ^u8
    width, height : i32
    io.Fonts.GetTexDataAsRGBA32(&pixels, &width, &height);   // Load as RGBA 32-bit (75% of the memory is wasted, but default font is so small) because it is more likely to be compatible with user's existing shaders. If your ImTextureId represent a higher-level concept than just a GL texture id, consider calling GetTexDataAsAlpha8() instead to save on GPU memory.

    // Upload texture to graphics system
    // (Bilinear sampling is required by default. Set 'io.Fonts->Flags |= ImFontAtlasFlags_NoBakedLines' or 'style.AntiAliasedLinesUseTex = false' to allow point/nearest sampling)
    bd.FontTexture = SDL_CreateTexture(bd.Renderer, SDL_PIXELFORMAT_ABGR8888, SDL_TEXTUREACCESS_STATIC, width, height);
    if (bd.FontTexture == nullptr)
    {
        SDL_Log("error creating texture");
        return false;
    }
    SDL_UpdateTexture(bd.FontTexture, nullptr, pixels, 4 * width);
    SDL_SetTextureBlendMode(bd.FontTexture, SDL_BLENDMODE_BLEND);
    SDL_SetTextureScaleMode(bd.FontTexture, SDL_ScaleModeLinear);

    // Store our identifier
    io.Fonts.SetTexID((ImTextureID)(intptr_t)bd.FontTexture);

    return true;
}

ImGui_ImplSDLRenderer2_DestroyFontsTexture :: proc()
{
    ImGuiIO& io = GetIO();
    bd := ImGui_ImplSDLRenderer2_GetBackendData();
    if (bd.FontTexture)
    {
        io.Fonts.SetTexID(0);
        SDL_DestroyTexture(bd.FontTexture);
        bd.FontTexture = nullptr;
    }
}

ImGui_ImplSDLRenderer2_CreateDeviceObjects :: proc() -> bool
{
    return ImGui_ImplSDLRenderer2_CreateFontsTexture();
}

ImGui_ImplSDLRenderer2_DestroyDeviceObjects :: proc()
{
    ImGui_ImplSDLRenderer2_DestroyFontsTexture();
}

//-----------------------------------------------------------------------------


} // #ifndef IMGUI_DISABLE
