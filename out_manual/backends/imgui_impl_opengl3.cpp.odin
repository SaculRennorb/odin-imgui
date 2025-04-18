package imgui

// dear imgui: Renderer Backend for modern OpenGL with shaders / programmatic pipeline
// - Desktop GL: 2.x 3.x 4.x
// - Embedded GL: ES 2.0 (WebGL 1.0), ES 3.0 (WebGL 2.0)
// This needs to be used along with a Platform Backend (e.g. GLFW, SDL, Win32, custom..)

// Implemented features:
//  [X] Renderer: User texture binding. Use 'GLuint' OpenGL texture identifier as void*/ImTextureID. Read the FAQ about ImTextureID!
//  [x] Renderer: Large meshes support (64k+ vertices) even with 16-bit indices (ImGuiBackendFlags_RendererHasVtxOffset) [Desktop OpenGL only!]
//  [X] Renderer: Multi-viewport support (multiple windows). Enable with 'io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable'.

// About WebGL/ES:
// - You need to '#define IMGUI_IMPL_OPENGL_ES2' or '#define IMGUI_IMPL_OPENGL_ES3' to use WebGL or OpenGL ES.
// - This is done automatically on iOS, Android and Emscripten targets.
// - For other targets, the define needs to be visible from the imgui_impl_opengl3.cpp compilation unit. If unsure, define globally or in imconfig.h.

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
//  2024-10-07: OpenGL: Changed default texture sampler to Clamp instead of Repeat/Wrap.
//  2024-06-28: OpenGL: ImGui_ImplOpenGL3_NewFrame() recreates font texture if it has been destroyed by ImGui_ImplOpenGL3_DestroyFontsTexture(). (#7748)
//  2024-05-07: OpenGL: Update loader for Linux to support EGL/GLVND. (#7562)
//  2024-04-16: OpenGL: Detect ES3 contexts on desktop based on version string, to e.g. avoid calling glPolygonMode() on them. (#7447)
//  2024-01-09: OpenGL: Update GL3W based imgui_impl_opengl3_loader.h to load "libGL.so" and variants, fixing regression on distros missing a symlink.
//  2023-11-08: OpenGL: Update GL3W based imgui_impl_opengl3_loader.h to load "libGL.so" instead of "libGL.so.1", accommodating for NetBSD systems having only "libGL.so.3" available. (#6983)
//  2023-10-05: OpenGL: Rename symbols in our internal loader so that LTO compilation with another copy of gl3w is possible. (#6875, #6668, #4445)
//  2023-06-20: OpenGL: Fixed erroneous use glGetIntegerv(GL_CONTEXT_PROFILE_MASK) on contexts lower than 3.2. (#6539, #6333)
//  2023-05-09: OpenGL: Support for glBindSampler() backup/restore on ES3. (#6375)
//  2023-04-18: OpenGL: Restore front and back polygon mode separately when supported by context. (#6333)
//  2023-03-23: OpenGL: Properly restoring "no shader program bound" if it was the case prior to running the rendering function. (#6267, #6220, #6224)
//  2023-03-15: OpenGL: Fixed GL loader crash when GL_VERSION returns NULL. (#6154, #4445, #3530)
//  2023-03-06: OpenGL: Fixed restoration of a potentially deleted OpenGL program, by calling glIsProgram(). (#6220, #6224)
//  2022-11-09: OpenGL: Reverted use of glBufferSubData(), too many corruptions issues + old issues seemingly can't be reproed with Intel drivers nowadays (revert 2021-12-15 and 2022-05-23 changes).
//  2022-10-11: Using 'nullptr' instead of 'NULL' as per our switch to C++11.
//  2022-09-27: OpenGL: Added ability to '#define IMGUI_IMPL_OPENGL_DEBUG'.
//  2022-05-23: OpenGL: Reworking 2021-12-15 "Using buffer orphaning" so it only happens on Intel GPU, seems to cause problems otherwise. (#4468, #4825, #4832, #5127).
//  2022-05-13: OpenGL: Fixed state corruption on OpenGL ES 2.0 due to not preserving GL_ELEMENT_ARRAY_BUFFER_BINDING and vertex attribute states.
//  2021-12-15: OpenGL: Using buffer orphaning + glBufferSubData(), seems to fix leaks with multi-viewports with some Intel HD drivers.
//  2021-08-23: OpenGL: Fixed ES 3.0 shader ("#version 300 es") use normal precision floats to avoid wobbly rendering at HD resolutions.
//  2021-08-19: OpenGL: Embed and use our own minimal GL loader (imgui_impl_opengl3_loader.h), removing requirement and support for third-party loader.
//  2021-06-29: Reorganized backend to pull data from a single structure to facilitate usage with multiple-contexts (all g_XXXX access changed to bd->XXXX).
//  2021-06-25: OpenGL: Use OES_vertex_array extension on Emscripten + backup/restore current state.
//  2021-06-21: OpenGL: Destroy individual vertex/fragment shader objects right after they are linked into the main shader.
//  2021-05-24: OpenGL: Access GL_CLIP_ORIGIN when "GL_ARB_clip_control" extension is detected, inside of just OpenGL 4.5 version.
//  2021-05-19: OpenGL: Replaced direct access to ImDrawCmd::TextureId with a call to ImDrawCmd::GetTexID(). (will become a requirement)
//  2021-04-06: OpenGL: Don't try to read GL_CLIP_ORIGIN unless we're OpenGL 4.5 or greater.
//  2021-02-18: OpenGL: Change blending equation to preserve alpha in output buffer.
//  2021-01-03: OpenGL: Backup, setup and restore GL_STENCIL_TEST state.
//  2020-10-23: OpenGL: Backup, setup and restore GL_PRIMITIVE_RESTART state.
//  2020-10-15: OpenGL: Use glGetString(GL_VERSION) instead of glGetIntegerv(GL_MAJOR_VERSION, args : ..any) when the later returns zero (e.g. Desktop GL 2.x)
//  2020-09-17: OpenGL: Fix to avoid compiling/calling glBindSampler() on ES or pre 3.3 context which have the defines set by a loader.
//  2020-07-10: OpenGL: Added support for glad2 OpenGL loader.
//  2020-05-08: OpenGL: Made default GLSL version 150 (instead of 130) on OSX.
//  2020-04-21: OpenGL: Fixed handling of glClipControl(GL_UPPER_LEFT) by inverting projection matrix.
//  2020-04-12: OpenGL: Fixed context version check mistakenly testing for 4.0+ instead of 3.2+ to enable ImGuiBackendFlags_RendererHasVtxOffset.
//  2020-03-24: OpenGL: Added support for glbinding 2.x OpenGL loader.
//  2020-01-07: OpenGL: Added support for glbinding 3.x OpenGL loader.
//  2019-10-25: OpenGL: Using a combination of GL define and runtime GL version to decide whether to use glDrawElementsBaseVertex(). Fix building with pre-3.2 GL loaders.
//  2019-09-22: OpenGL: Detect default GL loader using __has_include compiler facility.
//  2019-09-16: OpenGL: Tweak initialization code to allow application calling ImGui_ImplOpenGL3_CreateFontsTexture() before the first NewFrame() call.
//  2019-05-29: OpenGL: Desktop GL only: Added support for large mesh (64K+ vertices), enable ImGuiBackendFlags_RendererHasVtxOffset flag.
//  2019-04-30: OpenGL: Added support for special ImDrawCallback_ResetRenderState callback to reset render state.
//  2019-03-29: OpenGL: Not calling glBindBuffer more than necessary in the render loop.
//  2019-03-15: OpenGL: Added a GL call + comments in ImGui_ImplOpenGL3_Init() to detect uninitialized GL function loaders early.
//  2019-03-03: OpenGL: Fix support for ES 2.0 (WebGL 1.0).
//  2019-02-20: OpenGL: Fix for OSX not supporting OpenGL 4.5, we don't try to read GL_CLIP_ORIGIN even if defined by the headers/loader.
//  2019-02-11: OpenGL: Projecting clipping rectangles correctly using draw_data.FramebufferScale to allow multi-viewports for retina display.
//  2019-02-01: OpenGL: Using GLSL 410 shaders for any version over 410 (e.g. 430, 450).
//  2018-11-30: Misc: Setting up io.BackendRendererName so it can be displayed in the About Window.
//  2018-11-13: OpenGL: Support for GL 4.5's glClipControl(GL_UPPER_LEFT) / GL_CLIP_ORIGIN.
//  2018-08-29: OpenGL: Added support for more OpenGL loaders: glew and glad, with comments indicative that any loader can be used.
//  2018-08-09: OpenGL: Default to OpenGL ES 3 on iOS and Android. GLSL version default to "#version 300 ES".
//  2018-07-30: OpenGL: Support for GLSL 300 ES and 410 core. Fixes for Emscripten compilation.
//  2018-07-10: OpenGL: Support for more GLSL versions (based on the GLSL version string). Added error output when shaders fail to compile/link.
//  2018-06-08: Misc: Extracted imgui_impl_opengl3.cpp/.h away from the old combined GLFW/SDL+OpenGL3 examples.
//  2018-06-08: OpenGL: Use draw_data.DisplayPos and draw_data.DisplaySize to setup projection matrix and clipping rectangle.
//  2018-05-25: OpenGL: Removed unnecessary backup/restore of GL_ELEMENT_ARRAY_BUFFER_BINDING since this is part of the VAO state.
//  2018-05-14: OpenGL: Making the call to glBindSampler() optional so 3.2 context won't fail if the function is a nullptr pointer.
//  2018-03-06: OpenGL: Added const char* glsl_version parameter to ImGui_ImplOpenGL3_Init() so user can override the GLSL version e.g. "#version 150".
//  2018-02-23: OpenGL: Create the VAO in the render function so the setup can more easily be used with multiple shared GL context.
//  2018-02-16: Misc: Obsoleted the io.RenderDrawListsFn callback and exposed ImGui_ImplSdlGL3_RenderDrawData() in the .h file so you can call it yourself.
//  2018-01-07: OpenGL: Changed GLSL shader version from 330 to 150.
//  2017-09-01: OpenGL: Save and restore current bound sampler. Save and restore current polygon mode.
//  2017-05-01: OpenGL: Fixed save and restore of current blend func state.
//  2017-05-01: OpenGL: Fixed save and restore of current GL_ACTIVE_TEXTURE.
//  2016-09-05: OpenGL: Fixed save and restore of current scissor rectangle.
//  2016-07-29: OpenGL: Explicitly setting GL_UNPACK_ROW_LENGTH to reduce issues because SDL changes it. (#752)

//----------------------------------------
// OpenGL    GLSL      GLSL
// version   version   string
//----------------------------------------
//  2.0       110       "#version 110"
//  2.1       120       "#version 120"
//  3.0       130       "#version 130"
//  3.1       140       "#version 140"
//  3.2       150       "#version 150"
//  3.3       330       "#version 330 core"
//  4.0       400       "#version 400 core"
//  4.1       410       "#version 410 core"
//  4.2       420       "#version 410 core"
//  4.3       430       "#version 430 core"
//  ES 2.0    100       "#version 100"      = WebGL 1.0
//  ES 3.0    300       "#version 300 es"   = WebGL 2.0
//----------------------------------------

when defined(_MSC_VER) && !defined(_CRT_SECURE_NO_WARNINGS) {
_CRT_SECURE_NO_WARNINGS :: true
}

when !(IMGUI_DISABLE) {
when defined(__APPLE__) {
}

// Clang/GCC warnings with -Weverything

// GL includes
when defined(IMGUI_IMPL_OPENGL_ES2) {
when (defined(__APPLE__) && (TARGET_OS_IOS || TARGET_OS_TV)) {
} else {
}
when defined(__EMSCRIPTEN__) {
when !(GL_GLEXT_PROTOTYPES) {
GL_GLEXT_PROTOTYPES :: true
}
}
} else when defined(IMGUI_IMPL_OPENGL_ES3) {
when (defined(__APPLE__) && (TARGET_OS_IOS || TARGET_OS_TV)) {
} else {
}
} else when !defined(IMGUI_IMPL_OPENGL_LOADER_CUSTOM) {
// Modern desktop OpenGL doesn't have a standard portable header file to load OpenGL function pointers.
// Helper libraries are often used for this purpose! Here we are using our own minimal custom loader based on gl3w.
// In the rest of your app/engine, you can use another loader of your choice (gl3w, glew, glad, glbinding, glext, glLoadGen, etc.).
// If you happen to be developing a new feature for this backend (imgui_impl_opengl3.cpp):
// - You may need to regenerate imgui_impl_opengl3_loader.h to add new symbols. See https://github.com/dearimgui/gl3w_stripped
//   Typically you would run: python3 ./gl3w_gen.py --output ../imgui/backends/imgui_impl_opengl3_loader.h --ref ../imgui/backends/imgui_impl_opengl3.cpp ./extra_symbols.txt
// - You can temporarily use an unstripped version. See https://github.com/dearimgui/gl3w_stripped/releases
// Changes to this backend using new APIs should be accompanied by a regenerated stripped loader version.
IMGL3W_IMPL :: true
}

// Vertex arrays are not supported on ES2/WebGL1 unless Emscripten which uses an extension
when !(IMGUI_IMPL_OPENGL_ES2) {
IMGUI_IMPL_OPENGL_USE_VERTEX_ARRAY :: true
} else when defined(__EMSCRIPTEN__) {
IMGUI_IMPL_OPENGL_USE_VERTEX_ARRAY :: true
glBindVertexArray :: glBindVertexArrayOES
glGenVertexArrays :: glGenVertexArraysOES
glDeleteVertexArrays :: glDeleteVertexArraysOES
GL_VERTEX_ARRAY_BINDING :: GL_VERTEX_ARRAY_BINDING_OES
}

// Desktop GL 2.0+ has extension and glPolygonMode() which GL ES and WebGL don't have..
// A desktop ES context can technically compile fine with our loader, so we also perform a runtime checks
when !defined(IMGUI_IMPL_OPENGL_ES2) && !defined(IMGUI_IMPL_OPENGL_ES3) {
IMGUI_IMPL_OPENGL_HAS_EXTENSIONS :: true        // has glGetIntegerv(GL_NUM_EXTENSIONS)
IMGUI_IMPL_OPENGL_MAY_HAVE_POLYGON_MODE :: true // may have glPolygonMode()
}

// Desktop GL 2.1+ and GL ES 3.0+ have glBindBuffer() with GL_PIXEL_UNPACK_BUFFER target.
when !defined(IMGUI_IMPL_OPENGL_ES2) {
IMGUI_IMPL_OPENGL_MAY_HAVE_BIND_BUFFER_PIXEL_UNPACK :: true
}

// Desktop GL 3.1+ has GL_PRIMITIVE_RESTART state
when !defined(IMGUI_IMPL_OPENGL_ES2) && !defined(IMGUI_IMPL_OPENGL_ES3) && defined(GL_VERSION_3_1) {
IMGUI_IMPL_OPENGL_MAY_HAVE_PRIMITIVE_RESTART :: true
}

// Desktop GL 3.2+ has glDrawElementsBaseVertex() which GL ES and WebGL don't have.
when !defined(IMGUI_IMPL_OPENGL_ES2) && !defined(IMGUI_IMPL_OPENGL_ES3) && defined(GL_VERSION_3_2) {
IMGUI_IMPL_OPENGL_MAY_HAVE_VTX_OFFSET :: true
}

// Desktop GL 3.3+ and GL ES 3.0+ have glBindSampler()
when !defined(IMGUI_IMPL_OPENGL_ES2) && (defined(IMGUI_IMPL_OPENGL_ES3) || defined(GL_VERSION_3_3)) {
IMGUI_IMPL_OPENGL_MAY_HAVE_BIND_SAMPLER :: true
}

// [Debugging]
IMGUI_IMPL_OPENGL_DEBUG :: false
when IMGUI_IMPL_OPENGL_DEBUG {
#define GL_CALL(_CALL)      do { _CALL; GLenum gl_err = glGetError(); if (gl_err != 0) fprintf(stderr, "GL error 0x%x returned from '%s'.\n", gl_err, #_CALL); } while (0)  // Call with error check
} else {
#define GL_CALL(_CALL)      _CALL   // Call without error check
}

// OpenGL Data
ImGui_ImplOpenGL3_Data :: struct
{
    GlVersion : GLuint,               // Extracted at runtime using GL_MAJOR_VERSION, GL_MINOR_VERSION queries (e.g. 320 for GL 3.2)
    u8            GlslVersionString[32];   // Specified by user or detected based on compile time GL settings.
    GlProfileIsES2 : bool,
    GlProfileIsES3 : bool,
    GlProfileIsCompat : bool,
    GlProfileMask : GLint,
    FontTexture : GLuint,
    ShaderHandle : GLuint,
    AttribLocationTex : GLint,       // Uniforms location
    AttribLocationProjMtx : GLint,
    AttribLocationVtxPos : GLuint,    // Vertex attributes location
    AttribLocationVtxUV : GLuint,
    AttribLocationVtxColor : GLuint,
    VboHandle, ElementsHandle : u32,
    VertexBufferSize : GLsizeiptr,
    IndexBufferSize : GLsizeiptr,
    HasPolygonMode : bool,
    HasClipOrigin : bool,
    UseBufferSubData : bool,

    ImGui_ImplOpenGL3_Data() { memset((rawptr)this, 0, size_of(*this)); }
};

// Backend data stored in io.BackendRendererUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
ImGui_ImplOpenGL3_GetBackendData :: proc() -> ^ImGui_ImplOpenGL3_Data
{
    return GetCurrentContext() ? (ImGui_ImplOpenGL3_Data*)GetIO().BackendRendererUserData : nullptr;
}

// Forward Declarations
void ImGui_ImplOpenGL3_InitMultiViewportSupport();
void ImGui_ImplOpenGL3_ShutdownMultiViewportSupport();

// OpenGL vertex attribute state (for ES 1.0 and ES 2.0 only)
when !(IMGUI_IMPL_OPENGL_USE_VERTEX_ARRAY) {
ImGui_ImplOpenGL3_VtxAttribState :: struct
{
    Enabled, Size, Type, Normalized, Stride : GLint,
    Ptr : GLrawptr,

    GetState :: proc(index : GLint)
    {
        glGetVertexAttribiv(index, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &Enabled);
        glGetVertexAttribiv(index, GL_VERTEX_ATTRIB_ARRAY_SIZE, &Size);
        glGetVertexAttribiv(index, GL_VERTEX_ATTRIB_ARRAY_TYPE, &Type);
        glGetVertexAttribiv(index, GL_VERTEX_ATTRIB_ARRAY_NORMALIZED, &Normalized);
        glGetVertexAttribiv(index, GL_VERTEX_ATTRIB_ARRAY_STRIDE, &Stride);
        glGetVertexAttribPointerv(index, GL_VERTEX_ATTRIB_ARRAY_POINTER, &Ptr);
    }
    SetState :: proc(index : GLint)
    {
        glVertexAttribPointer(index, Size, Type, (GLboolean)Normalized, Stride, Ptr);
        if (Enabled) glEnableVertexAttribArray(index); else glDisableVertexAttribArray(index);
    }
};
}

// Functions
ImGui_ImplOpenGL3_Init :: proc(glsl_version : ^u8) -> bool
{
    io := GetIO();
    IMGUI_CHECKVERSION();
    assert(io.BackendRendererUserData == nullptr, "Already initialized a renderer backend!");

    // Initialize our loader
when !defined(IMGUI_IMPL_OPENGL_ES2) && !defined(IMGUI_IMPL_OPENGL_ES3) && !defined(IMGUI_IMPL_OPENGL_LOADER_CUSTOM) {
    if (imgl3wInit() != 0)
    {
        fprintf(stderr, "Failed to initialize OpenGL loader!\n");
        return false;
    }
}

    // Setup backend capabilities flags
    bd := IM_NEW(ImGui_ImplOpenGL3_Data)();
    io.BackendRendererUserData = cast(rawptr) bd;
    io.BackendRendererName = "imgui_impl_opengl3";

    // Query for GL version (e.g. 320 for GL 3.2)
    gl_version_str := cast(^u8) glGetString(GL_VERSION);
when defined(IMGUI_IMPL_OPENGL_ES2) {
    // GLES 2
    bd.GlVersion = 200;
    bd.GlProfileIsES2 = true;
} else {
    // Desktop or GLES 3
    major := 0;
    minor := 0;
    glGetIntegerv(GL_MAJOR_VERSION, &major);
    glGetIntegerv(GL_MINOR_VERSION, &minor);
    if (major == 0 && minor == 0) {
        sscanf(gl_version_str, "%d.%d", &major, &minor); // Query GL_VERSION in desktop GL 2.x, the string will start with "<major>.<minor>"
    }

    bd.GlVersion = (GLuint)(major * 100 + minor * 10);
when defined(GL_CONTEXT_PROFILE_MASK) {
    if (bd.GlVersion >= 320) {
        glGetIntegerv(GL_CONTEXT_PROFILE_MASK, &bd.GlProfileMask);
    }

    bd.GlProfileIsCompat = (bd.GlProfileMask & GL_CONTEXT_COMPATIBILITY_PROFILE_BIT) != 0;
}

when defined(IMGUI_IMPL_OPENGL_ES3) {
    bd.GlProfileIsES3 = true;
} else {
    if (strncmp(gl_version_str, "OpenGL ES 3", 11) == 0)   do bd.GlProfileIsES3 = true
}

    bd.UseBufferSubData = false;
    /*
    // Query vendor to enable glBufferSubData kludge
when _WIN32 {
    if (vendor := cast(^u8) glGetString(GL_VENDOR))
        if (strncmp(vendor, "Intel", 5) == 0) {
            bd.UseBufferSubData = true;
        }

}
    */
}

when IMGUI_IMPL_OPENGL_DEBUG {
    printf("GlVersion = %d, \"%s\"\nGlProfileIsCompat = %d\nGlProfileMask = 0x%X\nGlProfileIsES2/IsEs3 = %d/%d\nGL_VENDOR = '%s'\nGL_RENDERER = '%s'\n", bd.GlVersion, gl_version_str, bd.GlProfileIsCompat, bd.GlProfileMask, bd.GlProfileIsES2, bd.GlProfileIsES3, cast(^u8) glGetString(GL_VENDOR), cast(^u8) glGetString(GL_RENDERER)); // [DEBUG]
}

when IMGUI_IMPL_OPENGL_MAY_HAVE_VTX_OFFSET {
    if (bd.GlVersion >= 320)
        io.BackendFlags |= ImGuiBackendFlags_RendererHasVtxOffset;  // We can honor the ImDrawCmd::VtxOffset field, allowing for large meshes.
}
    io.BackendFlags |= ImGuiBackendFlags_RendererHasViewports;  // We can create multi-viewports on the Renderer side (optional)

    // Store GLSL version string so we can refer to it later in case we recreate shaders.
    // Note: GLSL version is NOT the same as GL version. Leave this to nullptr if unsure.
    if (glsl_version == nullptr)
    {
when defined(IMGUI_IMPL_OPENGL_ES2) {
        glsl_version = "#version 100";
} else when defined(IMGUI_IMPL_OPENGL_ES3) {
        glsl_version = "#version 300 es";
} else when defined(__APPLE__) {
        glsl_version = "#version 150";
} else {
        glsl_version = "#version 130";
}
    }
    assert(cast(i32) strlen(glsl_version) + 2 < len(bd.GlslVersionString));
    strcpy(bd.GlslVersionString, glsl_version);
    strcat(bd.GlslVersionString, "\n");

    // Make an arbitrary GL call (we don't actually need the result)
    // IF YOU GET A CRASH HERE: it probably means the OpenGL function loader didn't do its job. Let us know!
    current_texture : GLint
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &current_texture);

    // Detect extensions we support
when IMGUI_IMPL_OPENGL_MAY_HAVE_POLYGON_MODE {
    bd.HasPolygonMode = (!bd.GlProfileIsES2 && !bd.GlProfileIsES3);
}
    bd.HasClipOrigin = (bd.GlVersion >= 450);
when IMGUI_IMPL_OPENGL_HAS_EXTENSIONS {
    num_extensions := 0;
    glGetIntegerv(GL_NUM_EXTENSIONS, &num_extensions);
    for GLint i = 0; i < num_extensions; i += 1
    {
        extension := cast(^u8) glGetStringi(GL_EXTENSIONS, i);
        if (extension != nullptr && strcmp(extension, "GL_ARB_clip_control") == 0)   do bd.HasClipOrigin = true
    }
}

    ImGui_ImplOpenGL3_InitMultiViewportSupport();

    return true;
}

ImGui_ImplOpenGL3_Shutdown :: proc()
{
    bd := ImGui_ImplOpenGL3_GetBackendData();
    assert(bd != nullptr, "No renderer backend to shutdown, or already shutdown?");
    io := GetIO();

    ImGui_ImplOpenGL3_ShutdownMultiViewportSupport();
    ImGui_ImplOpenGL3_DestroyDeviceObjects();
    io.BackendRendererName = nullptr;
    io.BackendRendererUserData = nullptr;
    io.BackendFlags &= ~(ImGuiBackendFlags_RendererHasVtxOffset | ImGuiBackendFlags_RendererHasViewports);
    IM_DELETE(bd);
}

ImGui_ImplOpenGL3_NewFrame :: proc()
{
    bd := ImGui_ImplOpenGL3_GetBackendData();
    assert(bd != nullptr, "Context or backend not initialized! Did you call ImGui_ImplOpenGL3_Init()?");

    if (!bd.ShaderHandle)
        ImGui_ImplOpenGL3_CreateDeviceObjects();
    if (!bd.FontTexture)
        ImGui_ImplOpenGL3_CreateFontsTexture();
}

ImGui_ImplOpenGL3_SetupRenderState :: proc(draw_data : ^ImDrawData, fb_width : i32, fb_height : i32, vertex_array_object : GLuint)
{
    bd := ImGui_ImplOpenGL3_GetBackendData();

    // Setup render state: alpha-blending enabled, no face culling, no depth testing, scissor enabled, polygon fill
    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_STENCIL_TEST);
    glEnable(GL_SCISSOR_TEST);
when IMGUI_IMPL_OPENGL_MAY_HAVE_PRIMITIVE_RESTART {
    if (bd.GlVersion >= 310) {
        glDisable(GL_PRIMITIVE_RESTART);
    }

}
when IMGUI_IMPL_OPENGL_MAY_HAVE_POLYGON_MODE {
    if (bd.HasPolygonMode) {
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    }

}

    // Support for GL 4.5 rarely used glClipControl(GL_UPPER_LEFT)
when defined(GL_CLIP_ORIGIN) {
    clip_origin_lower_left := true;
    if (bd.HasClipOrigin)
    {
        current_clip_origin := 0; glGetIntegerv(GL_CLIP_ORIGIN, (GLint*)&current_clip_origin);
        if (current_clip_origin == GL_UPPER_LEFT) {
            clip_origin_lower_left = false;
        }

    }
}

    // Setup viewport, orthographic projection matrix
    // Our visible imgui space lies from draw_data.DisplayPos (top left) to draw_data.DisplayPos+data_data.DisplaySize (bottom right). DisplayPos is (0,0) for single viewport apps.
    GL_CALL(glViewport(0, 0, (GLsizei)fb_width, (GLsizei)fb_height));
    L := draw_data.DisplayPos.x;
    R := draw_data.DisplayPos.x + draw_data.DisplaySize.x;
    T := draw_data.DisplayPos.y;
    B := draw_data.DisplayPos.y + draw_data.DisplaySize.y;
when defined(GL_CLIP_ORIGIN) {
    if (!clip_origin_lower_left) { f32 tmp = T; T = B; B = tmp; } // Swap top and bottom if origin is upper left
}
    const f32 ortho_projection[4][4] =
    {
        { 2.0/(R-L),   0.0,         0.0,   0.0 },
        { 0.0,         2.0/(T-B),   0.0,   0.0 },
        { 0.0,         0.0,        -1.0,   0.0 },
        { (R+L)/(L-R),  (T+B)/(B-T),  0.0,   1.0 },
    };
    glUseProgram(bd.ShaderHandle);
    glUniform1i(bd.AttribLocationTex, 0);
    glUniformMatrix4fv(bd.AttribLocationProjMtx, 1, GL_FALSE, &ortho_projection[0][0]);

when IMGUI_IMPL_OPENGL_MAY_HAVE_BIND_SAMPLER {
    if (bd.GlVersion >= 330 || bd.GlProfileIsES3) {
        glBindSampler(0, 0); // We use combined texture/sampler state. Applications using GL 3.3 and GL ES 3.0 may set that otherwise.
    }

}

    (void)vertex_array_object;
when IMGUI_IMPL_OPENGL_USE_VERTEX_ARRAY {
    glBindVertexArray(vertex_array_object);
}

    // Bind vertex/index buffers and setup attributes for ImDrawVert
    GL_CALL(glBindBuffer(GL_ARRAY_BUFFER, bd.VboHandle));
    GL_CALL(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, bd.ElementsHandle));
    GL_CALL(glEnableVertexAttribArray(bd.AttribLocationVtxPos));
    GL_CALL(glEnableVertexAttribArray(bd.AttribLocationVtxUV));
    GL_CALL(glEnableVertexAttribArray(bd.AttribLocationVtxColor));
    GL_CALL(glVertexAttribPointer(bd.AttribLocationVtxPos,   2, GL_FLOAT,         GL_FALSE, size_of(ImDrawVert), (GLrawptr)offset_of(ImDrawVert, pos)));
    GL_CALL(glVertexAttribPointer(bd.AttribLocationVtxUV,    2, GL_FLOAT,         GL_FALSE, size_of(ImDrawVert), (GLrawptr)offset_of(ImDrawVert, uv)));
    GL_CALL(glVertexAttribPointer(bd.AttribLocationVtxColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, size_of(ImDrawVert), (GLrawptr)offset_of(ImDrawVert, col)));
}

// OpenGL3 Render function.
// Note that this implementation is little overcomplicated because we are saving/setting up/restoring every OpenGL state explicitly.
// This is in order to be able to run within an OpenGL engine that doesn't do so.
ImGui_ImplOpenGL3_RenderDrawData :: proc(draw_data : ^ImDrawData)
{
    // Avoid rendering when minimized, scale coordinates for retina displays (screen coordinates != framebuffer coordinates)
    fb_width := (i32)(draw_data.DisplaySize.x * draw_data.FramebufferScale.x);
    fb_height := (i32)(draw_data.DisplaySize.y * draw_data.FramebufferScale.y);
    if (fb_width <= 0 || fb_height <= 0)   do return

    bd := ImGui_ImplOpenGL3_GetBackendData();

    // Backup GL state
    last_active_texture : GLenum
    glActiveTexture(GL_TEXTURE0);
    last_program : GLuint
    last_texture : GLuint
when IMGUI_IMPL_OPENGL_MAY_HAVE_BIND_SAMPLER {
    last_sampler : GLuint
}
    last_array_buffer : GLuint
when !(IMGUI_IMPL_OPENGL_USE_VERTEX_ARRAY) {
    // This is part of VAO on OpenGL 3.0+ and OpenGL ES 3.0+.
    last_element_array_buffer : GLint
    last_vtx_attrib_state_pos : ImGui_ImplOpenGL3_VtxAttribState
    last_vtx_attrib_state_uv : ImGui_ImplOpenGL3_VtxAttribState
    last_vtx_attrib_state_color : ImGui_ImplOpenGL3_VtxAttribState
}
when IMGUI_IMPL_OPENGL_USE_VERTEX_ARRAY {
    last_vertex_array_object : GLuint
}
when IMGUI_IMPL_OPENGL_MAY_HAVE_POLYGON_MODE {
    GLint last_polygon_mode[2]; if (bd.HasPolygonMode) { glGetIntegerv(GL_POLYGON_MODE, last_polygon_mode); }
}
    GLint last_viewport[4]; glGetIntegerv(GL_VIEWPORT, last_viewport);
    GLint last_scissor_box[4]; glGetIntegerv(GL_SCISSOR_BOX, last_scissor_box);
    last_blend_src_rgb : GLenum
    last_blend_dst_rgb : GLenum
    last_blend_src_alpha : GLenum
    last_blend_dst_alpha : GLenum
    last_blend_equation_rgb : GLenum
    last_blend_equation_alpha : GLenum
    last_enable_blend := glIsEnabled(GL_BLEND);
    last_enable_cull_face := glIsEnabled(GL_CULL_FACE);
    last_enable_depth_test := glIsEnabled(GL_DEPTH_TEST);
    last_enable_stencil_test := glIsEnabled(GL_STENCIL_TEST);
    last_enable_scissor_test := glIsEnabled(GL_SCISSOR_TEST);
when IMGUI_IMPL_OPENGL_MAY_HAVE_PRIMITIVE_RESTART {
    last_enable_primitive_restart := (bd.GlVersion >= 310) ? glIsEnabled(GL_PRIMITIVE_RESTART) : GL_FALSE;
}

    // Setup desired GL state
    // Recreate the VAO every time (this is to easily allow multiple GL contexts to be rendered to. VAO are not shared among GL contexts)
    // The renderer would actually work without any VAO bound, but then our VertexAttrib calls would overwrite the default one currently bound.
    vertex_array_object := 0;
when IMGUI_IMPL_OPENGL_USE_VERTEX_ARRAY {
    GL_CALL(glGenVertexArrays(1, &vertex_array_object));
}
    ImGui_ImplOpenGL3_SetupRenderState(draw_data, fb_width, fb_height, vertex_array_object);

    // Will project scissor/clipping rectangles into framebuffer space
    clip_off := draw_data.DisplayPos;         // (0,0) unless using multi-viewports
    clip_scale := draw_data.FramebufferScale; // (1,1) unless using retina display which are often (2,2)

    // Render command lists
    for int n = 0; n < draw_data.CmdListsCount; n += 1
    {
        const ImDrawList* draw_list = draw_data.CmdLists[n];

        // Upload vertex/index buffers
        // - OpenGL drivers are in a very sorry state nowadays....
        //   During 2021 we attempted to switch from glBufferData() to orphaning+glBufferSubData() following reports
        //   of leaks on Intel GPU when using multi-viewports on Windows.
        // - After this we kept hearing of various display corruptions issues. We started disabling on non-Intel GPU, but issues still got reported on Intel.
        // - We are now back to using exclusively glBufferData(). So bd.UseBufferSubData IS ALWAYS FALSE in this code.
        //   We are keeping the old code path for a while in case people finding new issues may want to test the bd.UseBufferSubData path.
        // - See https://github.com/ocornut/imgui/issues/4468 and please report any corruption issues.
        vtx_buffer_size := (GLsizeiptr)len(draw_list.VtxBuffer) * size_of(ImDrawVert);
        idx_buffer_size := (GLsizeiptr)len(draw_list.IdxBuffer) * size_of(ImDrawIdx);
        if (bd.UseBufferSubData)
        {
            if (bd.VertexBufferSize < vtx_buffer_size)
            {
                bd.VertexBufferSize = vtx_buffer_size;
                GL_CALL(glBufferData(GL_ARRAY_BUFFER, bd.VertexBufferSize, nullptr, GL_STREAM_DRAW));
            }
            if (bd.IndexBufferSize < idx_buffer_size)
            {
                bd.IndexBufferSize = idx_buffer_size;
                GL_CALL(glBufferData(GL_ELEMENT_ARRAY_BUFFER, bd.IndexBufferSize, nullptr, GL_STREAM_DRAW));
            }
            GL_CALL(glBufferSubData(GL_ARRAY_BUFFER, 0, vtx_buffer_size, (const GLrawptr)draw_list.VtxBuffer.Data));
            GL_CALL(glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, idx_buffer_size, (const GLrawptr)draw_list.IdxBuffer.Data));
        }
        else
        {
            GL_CALL(glBufferData(GL_ARRAY_BUFFER, vtx_buffer_size, (const GLrawptr)draw_list.VtxBuffer.Data, GL_STREAM_DRAW));
            GL_CALL(glBufferData(GL_ELEMENT_ARRAY_BUFFER, idx_buffer_size, (const GLrawptr)draw_list.IdxBuffer.Data, GL_STREAM_DRAW));
        }

        for int cmd_i = 0; cmd_i < len(draw_list.CmdBuffer); cmd_i += 1
        {
            const ImDrawCmd* pcmd = &draw_list.CmdBuffer[cmd_i];
            if (pcmd.UserCallback != nullptr)
            {
                // User callback, registered via ImDrawList::AddCallback()
                // (ImDrawCallback_ResetRenderState is a special callback value used by the user to request the renderer to reset render state.)
                if (pcmd.UserCallback == ImDrawCallback_ResetRenderState)
                    ImGui_ImplOpenGL3_SetupRenderState(draw_data, fb_width, fb_height, vertex_array_object);
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
                GL_CALL(glScissor(cast(i32) clip_min.x, (i32)(cast(f32) fb_height - clip_max.y), (i32)(clip_max.x - clip_min.x), (i32)(clip_max.y - clip_min.y)));

                // Bind texture, Draw
                GL_CALL(glBindTexture(GL_TEXTURE_2D, (GLuint)(rawptr)pcmd.GetTexID()));
when IMGUI_IMPL_OPENGL_MAY_HAVE_VTX_OFFSET {
                if (bd.GlVersion >= 320) {
                    GL_CALL(glDrawElementsBaseVertex(GL_TRIANGLES, (GLsizei)pcmd.ElemCount, size_of(ImDrawIdx) == 2 ? GL_UNSIGNED_SHORT : GL_UNSIGNED_INT, cast(rawptr) (rawptr)(pcmd.IdxOffset * size_of(ImDrawIdx)), (GLint)pcmd.VtxOffset));
                }

                else
}
                GL_CALL(glDrawElements(GL_TRIANGLES, (GLsizei)pcmd.ElemCount, size_of(ImDrawIdx) == 2 ? GL_UNSIGNED_SHORT : GL_UNSIGNED_INT, cast(rawptr) (rawptr)(pcmd.IdxOffset * size_of(ImDrawIdx))));
            }
        }
    }

    // Destroy the temporary VAO
when IMGUI_IMPL_OPENGL_USE_VERTEX_ARRAY {
    GL_CALL(glDeleteVertexArrays(1, &vertex_array_object));
}

    // Restore modified GL state
    // This "glIsProgram()" check is required because if the program is "pending deletion" at the time of binding backup, it will have been deleted by now and will cause an OpenGL error. See #6220.
    if (last_program == 0 || glIsProgram(last_program)) glUseProgram(last_program);
    glBindTexture(GL_TEXTURE_2D, last_texture);
when IMGUI_IMPL_OPENGL_MAY_HAVE_BIND_SAMPLER {
    if (bd.GlVersion >= 330 || bd.GlProfileIsES3) {
        glBindSampler(0, last_sampler);
    }

}
    glActiveTexture(last_active_texture);
when IMGUI_IMPL_OPENGL_USE_VERTEX_ARRAY {
    glBindVertexArray(last_vertex_array_object);
}
    glBindBuffer(GL_ARRAY_BUFFER, last_array_buffer);
when !(IMGUI_IMPL_OPENGL_USE_VERTEX_ARRAY) {
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, last_element_array_buffer);
    last_vtx_attrib_state_pos.SetState(bd.AttribLocationVtxPos);
    last_vtx_attrib_state_uv.SetState(bd.AttribLocationVtxUV);
    last_vtx_attrib_state_color.SetState(bd.AttribLocationVtxColor);
}
    glBlendEquationSeparate(last_blend_equation_rgb, last_blend_equation_alpha);
    glBlendFuncSeparate(last_blend_src_rgb, last_blend_dst_rgb, last_blend_src_alpha, last_blend_dst_alpha);
    if (last_enable_blend) glEnable(GL_BLEND); else glDisable(GL_BLEND);
    if (last_enable_cull_face) glEnable(GL_CULL_FACE); else glDisable(GL_CULL_FACE);
    if (last_enable_depth_test) glEnable(GL_DEPTH_TEST); else glDisable(GL_DEPTH_TEST);
    if (last_enable_stencil_test) glEnable(GL_STENCIL_TEST); else glDisable(GL_STENCIL_TEST);
    if (last_enable_scissor_test) glEnable(GL_SCISSOR_TEST); else glDisable(GL_SCISSOR_TEST);
when IMGUI_IMPL_OPENGL_MAY_HAVE_PRIMITIVE_RESTART {
    if (bd.GlVersion >= 310) { if (last_enable_primitive_restart) glEnable(GL_PRIMITIVE_RESTART); else glDisable(GL_PRIMITIVE_RESTART); }
}

when IMGUI_IMPL_OPENGL_MAY_HAVE_POLYGON_MODE {
    // Desktop OpenGL 3.0 and OpenGL 3.1 had separate polygon draw modes for front-facing and back-facing faces of polygons
    if (bd.HasPolygonMode) { if (bd.GlVersion <= 310 || bd.GlProfileIsCompat) { glPolygonMode(GL_FRONT, (GLenum)last_polygon_mode[0]); glPolygonMode(GL_BACK, (GLenum)last_polygon_mode[1]); } else { glPolygonMode(GL_FRONT_AND_BACK, (GLenum)last_polygon_mode[0]); } }
} // IMGUI_IMPL_OPENGL_MAY_HAVE_POLYGON_MODE

    glViewport(last_viewport[0], last_viewport[1], (GLsizei)last_viewport[2], (GLsizei)last_viewport[3]);
    glScissor(last_scissor_box[0], last_scissor_box[1], (GLsizei)last_scissor_box[2], (GLsizei)last_scissor_box[3]);
    (void)bd; // Not all compilation paths use this
}

ImGui_ImplOpenGL3_CreateFontsTexture :: proc() -> bool
{
    io := GetIO();
    bd := ImGui_ImplOpenGL3_GetBackendData();

    // Build texture atlas
    pixels : ^u8
    width, height : i32
    io.Fonts.GetTexDataAsRGBA32(&pixels, &width, &height);   // Load as RGBA 32-bit (75% of the memory is wasted, but default font is so small) because it is more likely to be compatible with user's existing shaders. If your ImTextureId represent a higher-level concept than just a GL texture id, consider calling GetTexDataAsAlpha8() instead to save on GPU memory.

    // Upload texture to graphics system
    // (Bilinear sampling is required by default. Set 'io.Fonts.Flags |= ImFontAtlasFlags_NoBakedLines' or 'style.AntiAliasedLinesUseTex = false' to allow point/nearest sampling)
    last_texture : GLint
    GL_CALL(glGetIntegerv(GL_TEXTURE_BINDING_2D, &last_texture));
    GL_CALL(glGenTextures(1, &bd.FontTexture));
    GL_CALL(glBindTexture(GL_TEXTURE_2D, bd.FontTexture));
    GL_CALL(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR));
    GL_CALL(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR));
    GL_CALL(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE));
    GL_CALL(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE));
when GL_UNPACK_ROW_LENGTH { // Not on WebGL/ES
    GL_CALL(glPixelStorei(GL_UNPACK_ROW_LENGTH, 0));
}
    GL_CALL(glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels));

    // Store identifier
    io.Fonts.SetTexID((ImTextureID)(rawptr)bd.FontTexture);

    // Restore state
    GL_CALL(glBindTexture(GL_TEXTURE_2D, last_texture));

    return true;
}

ImGui_ImplOpenGL3_DestroyFontsTexture :: proc()
{
    io := GetIO();
    bd := ImGui_ImplOpenGL3_GetBackendData();
    if (bd.FontTexture)
    {
        glDeleteTextures(1, &bd.FontTexture);
        io.Fonts.SetTexID(0);
        bd.FontTexture = 0;
    }
}

// If you get an error please report on github. You may try different GL context version or GLSL version. See GL<>GLSL version table at the top of this file.
CheckShader :: proc(handle : GLuint, desc : ^u8) -> bool
{
    bd := ImGui_ImplOpenGL3_GetBackendData();
    status := 0, log_length = 0;
    glGetShaderiv(handle, GL_COMPILE_STATUS, &status);
    glGetShaderiv(handle, GL_INFO_LOG_LENGTH, &log_length);
    if ((GLboolean)status == GL_FALSE) {
        fprintf(stderr, "ERROR: ImGui_ImplOpenGL3_CreateDeviceObjects: failed to compile %s! With GLSL: %s\n", desc, bd.GlslVersionString);
    }

    if (log_length > 1)
    {
        ImVector<u8> buf;
        buf.resize((i32)(log_length + 1));
        glGetShaderInfoLog(handle, log_length, nullptr, (GLchar*)buf.begin());
        fprintf(stderr, "%s\n", buf.begin());
    }
    return (GLboolean)status == GL_TRUE;
}

// If you get an error please report on GitHub. You may try different GL context version or GLSL version.
CheckProgram :: proc(handle : GLuint, desc : ^u8) -> bool
{
    bd := ImGui_ImplOpenGL3_GetBackendData();
    status := 0, log_length = 0;
    glGetProgramiv(handle, GL_LINK_STATUS, &status);
    glGetProgramiv(handle, GL_INFO_LOG_LENGTH, &log_length);
    if ((GLboolean)status == GL_FALSE) {
        fprintf(stderr, "ERROR: ImGui_ImplOpenGL3_CreateDeviceObjects: failed to link %s! With GLSL %s\n", desc, bd.GlslVersionString);
    }

    if (log_length > 1)
    {
        ImVector<u8> buf;
        buf.resize((i32)(log_length + 1));
        glGetProgramInfoLog(handle, log_length, nullptr, (GLchar*)buf.begin());
        fprintf(stderr, "%s\n", buf.begin());
    }
    return (GLboolean)status == GL_TRUE;
}

ImGui_ImplOpenGL3_CreateDeviceObjects :: proc() -> bool
{
    bd := ImGui_ImplOpenGL3_GetBackendData();

    // Backup GL state
    last_texture, last_array_buffer : GLint
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &last_texture);
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &last_array_buffer);
when IMGUI_IMPL_OPENGL_MAY_HAVE_BIND_BUFFER_PIXEL_UNPACK {
    last_pixel_unpack_buffer := 0;
    if (bd.GlVersion >= 210) { glGetIntegerv(GL_PIXEL_UNPACK_BUFFER_BINDING, &last_pixel_unpack_buffer); glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0); }
}
when IMGUI_IMPL_OPENGL_USE_VERTEX_ARRAY {
    last_vertex_array : GLint
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING, &last_vertex_array);
}

    // Parse GLSL version string
    glsl_version := 130;
    sscanf(bd.GlslVersionString, "#version %d", &glsl_version);

    const GLchar* vertex_shader_glsl_120 =
        "uniform mat4 ProjMtx;\n"
        "attribute vec2 Position;\n"
        "attribute vec2 UV;\n"
        "attribute vec4 Color;\n"
        "varying vec2 Frag_UV;\n"
        "varying vec4 Frag_Color;\n"
        "void main()\n"
        "{\n"
        "    Frag_UV = UV;\n"
        "    Frag_Color = Color;\n"
        "    gl_Position = ProjMtx * vec4(Position.xy,0,1);\n"
        "}\n";

    const GLchar* vertex_shader_glsl_130 =
        "uniform mat4 ProjMtx;\n"
        "in vec2 Position;\n"
        "in vec2 UV;\n"
        "in vec4 Color;\n"
        "out vec2 Frag_UV;\n"
        "out vec4 Frag_Color;\n"
        "void main()\n"
        "{\n"
        "    Frag_UV = UV;\n"
        "    Frag_Color = Color;\n"
        "    gl_Position = ProjMtx * vec4(Position.xy,0,1);\n"
        "}\n";

    const GLchar* vertex_shader_glsl_300_es =
        "precision highp float;\n"
        "layout (location = 0) in vec2 Position;\n"
        "layout (location = 1) in vec2 UV;\n"
        "layout (location = 2) in vec4 Color;\n"
        "uniform mat4 ProjMtx;\n"
        "out vec2 Frag_UV;\n"
        "out vec4 Frag_Color;\n"
        "void main()\n"
        "{\n"
        "    Frag_UV = UV;\n"
        "    Frag_Color = Color;\n"
        "    gl_Position = ProjMtx * vec4(Position.xy,0,1);\n"
        "}\n";

    const GLchar* vertex_shader_glsl_410_core =
        "layout (location = 0) in vec2 Position;\n"
        "layout (location = 1) in vec2 UV;\n"
        "layout (location = 2) in vec4 Color;\n"
        "uniform mat4 ProjMtx;\n"
        "out vec2 Frag_UV;\n"
        "out vec4 Frag_Color;\n"
        "void main()\n"
        "{\n"
        "    Frag_UV = UV;\n"
        "    Frag_Color = Color;\n"
        "    gl_Position = ProjMtx * vec4(Position.xy,0,1);\n"
        "}\n";

    const GLchar* fragment_shader_glsl_120 =
        "#ifdef GL_ES\n"
        "    precision mediump float;\n"
        "#endif\n"
        "uniform sampler2D Texture;\n"
        "varying vec2 Frag_UV;\n"
        "varying vec4 Frag_Color;\n"
        "void main()\n"
        "{\n"
        "    gl_FragColor = Frag_Color * texture2D(Texture, Frag_UV.st);\n"
        "}\n";

    const GLchar* fragment_shader_glsl_130 =
        "uniform sampler2D Texture;\n"
        "in vec2 Frag_UV;\n"
        "in vec4 Frag_Color;\n"
        "out vec4 Out_Color;\n"
        "void main()\n"
        "{\n"
        "    Out_Color = Frag_Color * texture(Texture, Frag_UV.st);\n"
        "}\n";

    const GLchar* fragment_shader_glsl_300_es =
        "precision mediump float;\n"
        "uniform sampler2D Texture;\n"
        "in vec2 Frag_UV;\n"
        "in vec4 Frag_Color;\n"
        "layout (location = 0) out vec4 Out_Color;\n"
        "void main()\n"
        "{\n"
        "    Out_Color = Frag_Color * texture(Texture, Frag_UV.st);\n"
        "}\n";

    const GLchar* fragment_shader_glsl_410_core =
        "in vec2 Frag_UV;\n"
        "in vec4 Frag_Color;\n"
        "uniform sampler2D Texture;\n"
        "layout (location = 0) out vec4 Out_Color;\n"
        "void main()\n"
        "{\n"
        "    Out_Color = Frag_Color * texture(Texture, Frag_UV.st);\n"
        "}\n";

    // Select shaders matching our GLSL versions
    const GLchar* vertex_shader = nullptr;
    const GLchar* fragment_shader = nullptr;
    if (glsl_version < 130)
    {
        vertex_shader = vertex_shader_glsl_120;
        fragment_shader = fragment_shader_glsl_120;
    }
    else if (glsl_version >= 410)
    {
        vertex_shader = vertex_shader_glsl_410_core;
        fragment_shader = fragment_shader_glsl_410_core;
    }
    else if (glsl_version == 300)
    {
        vertex_shader = vertex_shader_glsl_300_es;
        fragment_shader = fragment_shader_glsl_300_es;
    }
    else
    {
        vertex_shader = vertex_shader_glsl_130;
        fragment_shader = fragment_shader_glsl_130;
    }

    // Create shaders
    const GLchar* vertex_shader_with_version[2] = { bd.GlslVersionString, vertex_shader };
    vert_handle : GLuint
    GL_CALL(vert_handle = glCreateShader(GL_VERTEX_SHADER));
    glShaderSource(vert_handle, 2, vertex_shader_with_version, nullptr);
    glCompileShader(vert_handle);
    CheckShader(vert_handle, "vertex shader");

    const GLchar* fragment_shader_with_version[2] = { bd.GlslVersionString, fragment_shader };
    frag_handle : GLuint
    GL_CALL(frag_handle = glCreateShader(GL_FRAGMENT_SHADER));
    glShaderSource(frag_handle, 2, fragment_shader_with_version, nullptr);
    glCompileShader(frag_handle);
    CheckShader(frag_handle, "fragment shader");

    // Link
    bd.ShaderHandle = glCreateProgram();
    glAttachShader(bd.ShaderHandle, vert_handle);
    glAttachShader(bd.ShaderHandle, frag_handle);
    glLinkProgram(bd.ShaderHandle);
    CheckProgram(bd.ShaderHandle, "shader program");

    glDetachShader(bd.ShaderHandle, vert_handle);
    glDetachShader(bd.ShaderHandle, frag_handle);
    glDeleteShader(vert_handle);
    glDeleteShader(frag_handle);

    bd.AttribLocationTex = glGetUniformLocation(bd.ShaderHandle, "Texture");
    bd.AttribLocationProjMtx = glGetUniformLocation(bd.ShaderHandle, "ProjMtx");
    bd.AttribLocationVtxPos = (GLuint)glGetAttribLocation(bd.ShaderHandle, "Position");
    bd.AttribLocationVtxUV = (GLuint)glGetAttribLocation(bd.ShaderHandle, "UV");
    bd.AttribLocationVtxColor = (GLuint)glGetAttribLocation(bd.ShaderHandle, "Color");

    // Create buffers
    glGenBuffers(1, &bd.VboHandle);
    glGenBuffers(1, &bd.ElementsHandle);

    ImGui_ImplOpenGL3_CreateFontsTexture();

    // Restore modified GL state
    glBindTexture(GL_TEXTURE_2D, last_texture);
    glBindBuffer(GL_ARRAY_BUFFER, last_array_buffer);
when IMGUI_IMPL_OPENGL_MAY_HAVE_BIND_BUFFER_PIXEL_UNPACK {
    if (bd.GlVersion >= 210) { glBindBuffer(GL_PIXEL_UNPACK_BUFFER, last_pixel_unpack_buffer); }
}
when IMGUI_IMPL_OPENGL_USE_VERTEX_ARRAY {
    glBindVertexArray(last_vertex_array);
}

    return true;
}

ImGui_ImplOpenGL3_DestroyDeviceObjects :: proc()
{
    bd := ImGui_ImplOpenGL3_GetBackendData();
    if (bd.VboHandle)      { glDeleteBuffers(1, &bd.VboHandle); bd.VboHandle = 0; }
    if (bd.ElementsHandle) { glDeleteBuffers(1, &bd.ElementsHandle); bd.ElementsHandle = 0; }
    if (bd.ShaderHandle)   { glDeleteProgram(bd.ShaderHandle); bd.ShaderHandle = 0; }
    ImGui_ImplOpenGL3_DestroyFontsTexture();
}

//--------------------------------------------------------------------------------------------------------
// MULTI-VIEWPORT / PLATFORM INTERFACE SUPPORT
// This is an _advanced_ and _optional_ feature, allowing the backend to create and handle multiple viewports simultaneously.
// If you are new to dear imgui or creating a new binding for dear imgui, it is recommended that you completely ignore this section first..
//--------------------------------------------------------------------------------------------------------

ImGui_ImplOpenGL3_RenderWindow :: proc(viewport : ^ImGuiViewport, rawptr)
{
    if (!(.NoRendererClear in viewport.Flags))
    {
        clear_color := ImVec4{0.0, 0.0, 0.0, 1.0};
        glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    ImGui_ImplOpenGL3_RenderDrawData(viewport.DrawData);
}

ImGui_ImplOpenGL3_InitMultiViewportSupport :: proc()
{
    platform_io := &GetPlatformIO();
    platform_io.Renderer_RenderWindow = ImGui_ImplOpenGL3_RenderWindow;
}

ImGui_ImplOpenGL3_ShutdownMultiViewportSupport :: proc()
{
    DestroyPlatformWindows();
}

//-----------------------------------------------------------------------------


} // #ifndef IMGUI_DISABLE
