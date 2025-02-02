package imgui

// dear imgui: Renderer Backend for OpenGL2 (legacy OpenGL, fixed pipeline)
// This needs to be used along with a Platform Backend (e.g. GLFW, SDL, Win32, custom..)

// Implemented features:
//  [X] Renderer: User texture binding. Use 'GLuint' OpenGL texture identifier as void*/ImTextureID. Read the FAQ about ImTextureID!
//  [X] Renderer: Multi-viewport support (multiple windows). Enable with 'io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable'.
// Missing features or Issues:
//  [ ] Renderer: Large meshes support (64k+ vertices) even with 16-bit indices (ImGuiBackendFlags_RendererHasVtxOffset).

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// Learn about Dear ImGui:
// - FAQ                  https://dearimgui.com/faq
// - Getting Started      https://dearimgui.com/getting-started
// - Documentation        https://dearimgui.com/docs (same as your local docs/ folder).
// - Introduction, links and more at the top of imgui.cpp

// **DO NOT USE THIS CODE IF YOUR CODE/ENGINE IS USING MODERN OPENGL (SHADERS, VBO, VAO, etc.)**
// **Prefer using the code in imgui_impl_opengl3.cpp**
// This code is mostly provided as a reference to learn how ImGui integration works, because it is shorter to read.
// If your code is using GL3+ context or any semi modern OpenGL calls, using this is likely to make everything more
// complicated, will require your code to reset every single OpenGL attributes to their initial state, and might
// confuse your GPU driver.
// The GL2 code is unable to reset attributes or even call e.g. "glUseProgram(0)" because they don't exist in that API.

// CHANGELOG
// (minor and older changes stripped away, please see git history for details)
//  2025-XX-XX: Platform: Added support for multiple windows via the ImGuiPlatformIO interface.
//  2024-10-07: OpenGL: Changed default texture sampler to Clamp instead of Repeat/Wrap.
//  2024-06-28: OpenGL: ImGui_ImplOpenGL2_NewFrame() recreates font texture if it has been destroyed by ImGui_ImplOpenGL2_DestroyFontsTexture(). (#7748)
//  2022-10-11: Using 'nullptr' instead of 'NULL' as per our switch to C++11.
//  2021-12-08: OpenGL: Fixed mishandling of the ImDrawCmd::IdxOffset field! This is an old bug but it never had an effect until some internal rendering changes in 1.86.
//  2021-06-29: Reorganized backend to pull data from a single structure to facilitate usage with multiple-contexts (all g_XXXX access changed to bd->XXXX).
//  2021-05-19: OpenGL: Replaced direct access to ImDrawCmd::TextureId with a call to ImDrawCmd::GetTexID(). (will become a requirement)
//  2021-01-03: OpenGL: Backup, setup and restore GL_SHADE_MODEL state, disable GL_STENCIL_TEST and disable GL_NORMAL_ARRAY client state to increase compatibility with legacy OpenGL applications.
//  2020-01-23: OpenGL: Backup, setup and restore GL_TEXTURE_ENV to increase compatibility with legacy OpenGL applications.
//  2019-04-30: OpenGL: Added support for special ImDrawCallback_ResetRenderState callback to reset render state.
//  2019-02-11: OpenGL: Projecting clipping rectangles correctly using draw_data.FramebufferScale to allow multi-viewports for retina display.
//  2018-11-30: Misc: Setting up io.BackendRendererName so it can be displayed in the About Window.
//  2018-08-03: OpenGL: Disabling/restoring GL_LIGHTING and GL_COLOR_MATERIAL to increase compatibility with legacy OpenGL applications.
//  2018-06-08: Misc: Extracted imgui_impl_opengl2.cpp/.h away from the old combined GLFW/SDL+OpenGL2 examples.
//  2018-06-08: OpenGL: Use draw_data.DisplayPos and draw_data.DisplaySize to setup projection matrix and clipping rectangle.
//  2018-02-16: Misc: Obsoleted the io.RenderDrawListsFn callback and exposed ImGui_ImplOpenGL2_RenderDrawData() in the .h file so you can call it yourself.
//  2017-09-01: OpenGL: Save and restore current polygon mode.
//  2016-09-10: OpenGL: Uploading font texture as RGBA32 to increase compatibility with users shaders (not ideal).
//  2016-09-05: OpenGL: Fixed save and restore of current scissor rectangle.

when !(IMGUI_DISABLE) {

// Clang/GCC warnings with -Weverything

// Include OpenGL header (without an OpenGL loader) requires a bit of fiddling
when defined(_WIN32) && !defined(APIENTRY) {
APIENTRY :: __stdcall                  // It is customary to use APIENTRY for OpenGL function pointer declarations on all platforms.  Additionally, the Windows OpenGL header needs APIENTRY.
}
when defined(_WIN32) && !defined(WINGDIAPI) {
#define WINGDIAPI __declspec(dllimport)     // Some Windows OpenGL headers need this
}
when defined(__APPLE__) {
GL_SILENCE_DEPRECATION :: true
} else {
}

ImGui_ImplOpenGL2_Data :: struct
{
    FontTexture : GLuint,

    ImGui_ImplOpenGL2_Data() { memset((rawptr)this, 0, size_of(*this)); }
};

// Backend data stored in io.BackendRendererUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
ImGui_ImplOpenGL2_GetBackendData :: proc() -> ^ImGui_ImplOpenGL2_Data
{
    return GetCurrentContext() ? (ImGui_ImplOpenGL2_Data*)GetIO().BackendRendererUserData : nullptr;
}

// Forward Declarations
void ImGui_ImplOpenGL2_InitMultiViewportSupport();
void ImGui_ImplOpenGL2_ShutdownMultiViewportSupport();

// Functions
ImGui_ImplOpenGL2_Init :: proc() -> bool
{
    io := GetIO();
    IMGUI_CHECKVERSION();
    assert(io.BackendRendererUserData == nullptr, "Already initialized a renderer backend!");

    // Setup backend capabilities flags
    bd := IM_NEW(ImGui_ImplOpenGL2_Data)();
    io.BackendRendererUserData = cast(rawptr) bd;
    io.BackendRendererName = "imgui_impl_opengl2";
    io.BackendFlags |= ImGuiBackendFlags_RendererHasViewports;    // We can create multi-viewports on the Renderer side (optional)

    ImGui_ImplOpenGL2_InitMultiViewportSupport();

    return true;
}

ImGui_ImplOpenGL2_Shutdown :: proc()
{
    bd := ImGui_ImplOpenGL2_GetBackendData();
    assert(bd != nullptr, "No renderer backend to shutdown, or already shutdown?");
    io := GetIO();

    ImGui_ImplOpenGL2_ShutdownMultiViewportSupport();
    ImGui_ImplOpenGL2_DestroyDeviceObjects();
    io.BackendRendererName = nullptr;
    io.BackendRendererUserData = nullptr;
    io.BackendFlags &= ~ImGuiBackendFlags_RendererHasViewports;
    IM_DELETE(bd);
}

ImGui_ImplOpenGL2_NewFrame :: proc()
{
    bd := ImGui_ImplOpenGL2_GetBackendData();
    assert(bd != nullptr, "Context or backend not initialized! Did you call ImGui_ImplOpenGL2_Init()?");

    if (!bd.FontTexture)
        ImGui_ImplOpenGL2_CreateDeviceObjects();
    if (!bd.FontTexture)
        ImGui_ImplOpenGL2_CreateFontsTexture();
}

ImGui_ImplOpenGL2_SetupRenderState :: proc(draw_data : ^ImDrawData, fb_width : i32, fb_height : i32)
{
    // Setup render state: alpha-blending enabled, no face culling, no depth testing, scissor enabled, vertex/texcoord/color pointers, polygon fill.
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    //glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA); // In order to composite our output buffer we need to preserve alpha
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_STENCIL_TEST);
    glDisable(GL_LIGHTING);
    glDisable(GL_COLOR_MATERIAL);
    glEnable(GL_SCISSOR_TEST);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);
    glEnable(GL_TEXTURE_2D);
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    glShadeModel(GL_SMOOTH);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

    // If you are using this code with non-legacy OpenGL header/contexts (which you should not, prefer using imgui_impl_opengl3.cpp!!),
    // you may need to backup/reset/restore other state, e.g. for current shader using the commented lines below.
    // (DO NOT MODIFY THIS FILE! Add the code in your calling function)
    //   GLint last_program;
    //   glGetIntegerv(GL_CURRENT_PROGRAM, &last_program);
    //   glUseProgram(0);
    //   ImGui_ImplOpenGL2_RenderDrawData(...);
    //   glUseProgram(last_program)
    // There are potentially many more states you could need to clear/setup that we can't access from default headers.
    // e.g. glBindBuffer(GL_ARRAY_BUFFER, 0), glDisable(GL_TEXTURE_CUBE_MAP).

    // Setup viewport, orthographic projection matrix
    // Our visible imgui space lies from draw_data.DisplayPos (top left) to draw_data.DisplayPos+data_data.DisplaySize (bottom right). DisplayPos is (0,0) for single viewport apps.
    glViewport(0, 0, (GLsizei)fb_width, (GLsizei)fb_height);
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrtho(draw_data.DisplayPos.x, draw_data.DisplayPos.x + draw_data.DisplaySize.x, draw_data.DisplayPos.y + draw_data.DisplaySize.y, draw_data.DisplayPos.y, -1.0, +1.0);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
}

// OpenGL2 Render function.
// Note that this implementation is little overcomplicated because we are saving/setting up/restoring every OpenGL state explicitly.
// This is in order to be able to run within an OpenGL engine that doesn't do so.
ImGui_ImplOpenGL2_RenderDrawData :: proc(draw_data : ^ImDrawData)
{
    // Avoid rendering when minimized, scale coordinates for retina displays (screen coordinates != framebuffer coordinates)
    fb_width := (i32)(draw_data.DisplaySize.x * draw_data.FramebufferScale.x);
    fb_height := (i32)(draw_data.DisplaySize.y * draw_data.FramebufferScale.y);
    if (fb_width == 0 || fb_height == 0)   do return

    // Backup GL state
    last_texture : GLint
    GLint last_polygon_mode[2]; glGetIntegerv(GL_POLYGON_MODE, last_polygon_mode);
    GLint last_viewport[4]; glGetIntegerv(GL_VIEWPORT, last_viewport);
    GLint last_scissor_box[4]; glGetIntegerv(GL_SCISSOR_BOX, last_scissor_box);
    last_shade_model : GLint
    last_tex_env_mode : GLint
    glPushAttrib(GL_ENABLE_BIT | GL_COLOR_BUFFER_BIT | GL_TRANSFORM_BIT);

    // Setup desired GL state
    ImGui_ImplOpenGL2_SetupRenderState(draw_data, fb_width, fb_height);

    // Will project scissor/clipping rectangles into framebuffer space
    clip_off := draw_data.DisplayPos;         // (0,0) unless using multi-viewports
    clip_scale := draw_data.FramebufferScale; // (1,1) unless using retina display which are often (2,2)

    // Render command lists
    for int n = 0; n < draw_data.CmdListsCount; n += 1
    {
        const ImDrawList* draw_list = draw_data.CmdLists[n];
        const ImDrawVert* vtx_buffer = draw_list.VtxBuffer.Data;
        const ImDrawIdx* idx_buffer = draw_list.IdxBuffer.Data;
        glVertexPointer(2, GL_FLOAT, size_of(ImDrawVert), (const GLrawptr)(cast(^u8) vtx_buffer + offset_of(ImDrawVert, pos)));
        glTexCoordPointer(2, GL_FLOAT, size_of(ImDrawVert), (const GLrawptr)(cast(^u8) vtx_buffer + offset_of(ImDrawVert, uv)));
        glColorPointer(4, GL_UNSIGNED_BYTE, size_of(ImDrawVert), (const GLrawptr)(cast(^u8) vtx_buffer + offset_of(ImDrawVert, col)));

        for int cmd_i = 0; cmd_i < len(draw_list.CmdBuffer); cmd_i += 1
        {
            const ImDrawCmd* pcmd = &draw_list.CmdBuffer[cmd_i];
            if (pcmd.UserCallback)
            {
                // User callback, registered via ImDrawList::AddCallback()
                // (ImDrawCallback_ResetRenderState is a special callback value used by the user to request the renderer to reset render state.)
                if (pcmd.UserCallback == ImDrawCallback_ResetRenderState)
                    ImGui_ImplOpenGL2_SetupRenderState(draw_data, fb_width, fb_height);
                else
                    pcmd.UserCallback(draw_list, pcmd);
            }
            else
            {
                // Project scissor/clipping rectangles into framebuffer space
                clip_min := ImVec2((pcmd.ClipRect.x - clip_off.x) * clip_scale.x, (pcmd.ClipRect.y - clip_off.y) * clip_scale.y);
                clip_max := ImVec2((pcmd.ClipRect.z - clip_off.x) * clip_scale.x, (pcmd.ClipRect.w - clip_off.y) * clip_scale.y);
                if (clip_max.x <= clip_min.x || clip_max.y <= clip_min.y)   do continue

                // Apply scissor/clipping rectangle (Y is inverted in OpenGL)
                glScissor(cast(i32) clip_min.x, (i32)(cast(f32) fb_height - clip_max.y), (i32)(clip_max.x - clip_min.x), (i32)(clip_max.y - clip_min.y));

                // Bind texture, Draw
                glBindTexture(GL_TEXTURE_2D, (GLuint)(rawptr)pcmd.GetTexID());
                glDrawElements(GL_TRIANGLES, (GLsizei)pcmd.ElemCount, size_of(ImDrawIdx) == 2 ? GL_UNSIGNED_SHORT : GL_UNSIGNED_INT, idx_buffer + pcmd.IdxOffset);
            }
        }
    }

    // Restore modified GL state
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
    glBindTexture(GL_TEXTURE_2D, (GLuint)last_texture);
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glPopAttrib();
    glPolygonMode(GL_FRONT, (GLenum)last_polygon_mode[0]); glPolygonMode(GL_BACK, (GLenum)last_polygon_mode[1]);
    glViewport(last_viewport[0], last_viewport[1], (GLsizei)last_viewport[2], (GLsizei)last_viewport[3]);
    glScissor(last_scissor_box[0], last_scissor_box[1], (GLsizei)last_scissor_box[2], (GLsizei)last_scissor_box[3]);
    glShadeModel(last_shade_model);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, last_tex_env_mode);
}

ImGui_ImplOpenGL2_CreateFontsTexture :: proc() -> bool
{
    // Build texture atlas
    io := GetIO();
    bd := ImGui_ImplOpenGL2_GetBackendData();
    pixels : ^u8
    width, height : i32
    io.Fonts.GetTexDataAsRGBA32(&pixels, &width, &height);   // Load as RGBA 32-bit (75% of the memory is wasted, but default font is so small) because it is more likely to be compatible with user's existing shaders. If your ImTextureId represent a higher-level concept than just a GL texture id, consider calling GetTexDataAsAlpha8() instead to save on GPU memory.

    // Upload texture to graphics system
    // (Bilinear sampling is required by default. Set 'io.Fonts.Flags |= ImFontAtlasFlags_NoBakedLines' or 'style.AntiAliasedLinesUseTex = false' to allow point/nearest sampling)
    last_texture : GLint
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &last_texture);
    glGenTextures(1, &bd.FontTexture);
    glBindTexture(GL_TEXTURE_2D, bd.FontTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);

    // Store our identifier
    io.Fonts.SetTexID((ImTextureID)(rawptr)bd.FontTexture);

    // Restore state
    glBindTexture(GL_TEXTURE_2D, last_texture);

    return true;
}

ImGui_ImplOpenGL2_DestroyFontsTexture :: proc()
{
    io := GetIO();
    bd := ImGui_ImplOpenGL2_GetBackendData();
    if (bd.FontTexture)
    {
        glDeleteTextures(1, &bd.FontTexture);
        io.Fonts.SetTexID(0);
        bd.FontTexture = 0;
    }
}

ImGui_ImplOpenGL2_CreateDeviceObjects :: proc() -> bool
{
    return ImGui_ImplOpenGL2_CreateFontsTexture();
}

ImGui_ImplOpenGL2_DestroyDeviceObjects :: proc()
{
    ImGui_ImplOpenGL2_DestroyFontsTexture();
}


//--------------------------------------------------------------------------------------------------------
// MULTI-VIEWPORT / PLATFORM INTERFACE SUPPORT
// This is an _advanced_ and _optional_ feature, allowing the backend to create and handle multiple viewports simultaneously.
// If you are new to dear imgui or creating a new binding for dear imgui, it is recommended that you completely ignore this section first..
//--------------------------------------------------------------------------------------------------------

ImGui_ImplOpenGL2_RenderWindow :: proc(viewport : ^ImGuiViewport, rawptr)
{
    if (!(.NoRendererClear in viewport.Flags))
    {
        clear_color := ImVec4{0.0, 0.0, 0.0, 1.0};
        glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    ImGui_ImplOpenGL2_RenderDrawData(viewport.DrawData);
}

ImGui_ImplOpenGL2_InitMultiViewportSupport :: proc()
{
    platform_io := &GetPlatformIO();
    platform_io.Renderer_RenderWindow = ImGui_ImplOpenGL2_RenderWindow;
}

ImGui_ImplOpenGL2_ShutdownMultiViewportSupport :: proc()
{
    DestroyPlatformWindows();
}

//-----------------------------------------------------------------------------


} // #ifndef IMGUI_DISABLE
