package imgui

// dear imgui, v1.91.7 WIP
// (headers)

// Help:
// - See links below.
// - Call and read ImGui::ShowDemoWindow() in imgui_demo.cpp. All applications in examples/ are doing that.
// - Read top of imgui.cpp for more details, links and comments.
// - Add '#define IMGUI_DEFINE_MATH_OPERATORS' before including this file (or in imconfig.h) to access courtesy maths operators for ImVec2 and ImVec4.

// Resources:
// - FAQ ........................ https://dearimgui.com/faq (in repository as docs/FAQ.md)
// - Homepage ................... https://github.com/ocornut/imgui
// - Releases & changelog ....... https://github.com/ocornut/imgui/releases
// - Gallery .................... https://github.com/ocornut/imgui/issues?q=label%3Agallery (please post your screenshots/video there!)
// - Wiki ....................... https://github.com/ocornut/imgui/wiki (lots of good stuff there)
//   - Getting Started            https://github.com/ocornut/imgui/wiki/Getting-Started (how to integrate in an existing app by adding ~25 lines of code)
//   - Third-party Extensions     https://github.com/ocornut/imgui/wiki/Useful-Extensions (ImPlot & many more)
//   - Bindings/Backends          https://github.com/ocornut/imgui/wiki/Bindings (language bindings, backends for various tech/engines)
//   - Glossary                   https://github.com/ocornut/imgui/wiki/Glossary
//   - Debug Tools                https://github.com/ocornut/imgui/wiki/Debug-Tools
//   - Software using Dear ImGui  https://github.com/ocornut/imgui/wiki/Software-using-dear-imgui
// - Issues & support ........... https://github.com/ocornut/imgui/issues
// - Test Engine & Automation ... https://github.com/ocornut/imgui_test_engine (test suite, test engine to automate your apps)

// For first-time users having issues compiling/linking/running/loading fonts:
// please post in https://github.com/ocornut/imgui/discussions if you cannot find a solution in resources above.
// Everything else should be asked in 'Issues'! We are building a database of cross-linked knowledge there.

// Library Version
// (Integer encoded as XYYZZ for use in #if preprocessor conditionals, e.g. '#if IMGUI_VERSION_NUM >= 12345')
IMGUI_VERSION :: "1.91.7 WIP"
IMGUI_VERSION_NUM :: 19164
IMGUI_HAS_TABLE :: true
IMGUI_HAS_VIEWPORT :: true          // Viewport WIP branch
IMGUI_HAS_DOCK :: true              // Docking WIP branch

/*

Index of this file:
// [SECTION] Header mess
// [SECTION] Forward declarations and basic types
// [SECTION] Dear ImGui end-user API functions
// [SECTION] Flags & Enumerations
// [SECTION] Tables API flags and structures (ImGuiTableFlags, ImGuiTableColumnFlags, ImGuiTableRowFlags, ImGuiTableBgTarget, ImGuiTableSortSpecs, ImGuiTableColumnSortSpecs)
// [SECTION] Helpers: Debug log, Memory allocations macros, ImVector<>
// [SECTION] ImGuiStyle
// [SECTION] ImGuiIO
// [SECTION] Misc data structures (ImGuiInputTextCallbackData, ImGuiSizeCallbackData, ImGuiWindowClass, ImGuiPayload)
// [SECTION] Helpers (ImGuiOnceUponAFrame, ImGuiTextFilter, ImGuiTextBuffer, ImGuiStorage, ImGuiListClipper, Math Operators, ImColor)
// [SECTION] Multi-Select API flags and structures (ImGuiMultiSelectFlags, ImGuiMultiSelectIO, ImGuiSelectionRequest, ImGuiSelectionBasicStorage, ImGuiSelectionExternalStorage)
// [SECTION] Drawing API (ImDrawCallback, ImDrawCmd, ImDrawIdx, ImDrawVert, ImDrawChannel, ImDrawListSplitter, ImDrawFlags, ImDrawListFlags, ImDrawList, ImDrawData)
// [SECTION] Font API (ImFontConfig, ImFontGlyph, ImFontGlyphRangesBuilder, ImFontAtlasFlags, ImFontAtlas, ImFont)
// [SECTION] Viewports (ImGuiViewportFlags, ImGuiViewport)
// [SECTION] ImGuiPlatformIO + other Platform Dependent Interfaces (ImGuiPlatformMonitor, ImGuiPlatformImeData)
// [SECTION] Obsolete functions and types

*/


// Configuration file with compile-time options
// (edit imconfig.h or '#define IMGUI_USER_CONFIG "myfilename.h" from your build system)

when !(IMGUI_DISABLE) {

//-----------------------------------------------------------------------------
// [SECTION] Header mess
//-----------------------------------------------------------------------------

// Includes

// Define attributes of all API symbols declarations (e.g. for DLL under Windows)
// IMGUI_API is used for core imgui functions, IMGUI_IMPL_API is used for the default backends files (imgui_impl_xxx.h)
// Using dear imgui via a shared library is not recommended: we don't guarantee backward nor forward ABI compatibility + this is a call-heavy library and function call overhead adds up.

// Helper Macros
#define IM_UNUSED(_VAR)             ((void)(_VAR))                              // Used to silence "unused variable warnings". Often useful as asserts may be stripped out from final builds.

// Check that version and structures layouts are matching between compiled imgui code and caller. Read comments above DebugCheckVersionAndDataLayout() for details.
#define IMGUI_CHECKVERSION()        ImGui::DebugCheckVersionAndDataLayout(IMGUI_VERSION, sizeof(ImGuiIO), sizeof(ImGuiStyle), sizeof(ImVec2), sizeof(ImVec4), sizeof(ImDrawVert), sizeof(ImDrawIdx))

// Helper Macros - IM_FMTARGS, IM_FMTLIST: Apply printf-style warnings to our formatting functions.
// (MSVC provides an equivalent mechanism via SAL Annotations but it would require the macros in a different
//  location. e.g. #include <sal.h> + void myprintf(_Printf_format_string_ const char* format, ...))
when !defined(IMGUI_USE_STB_SPRINTF) && defined(__MINGW32__) && !defined(__clang__) {
} else when !defined(IMGUI_USE_STB_SPRINTF) && (defined(__clang__) || defined(__GNUC__)) {
} else {
}

// Disable some of MSVC most aggressive Debug runtime checks in function header/footer (used in some simple/low-level functions)
when defined(_MSC_VER) && !defined(__clang__)  && !defined(__INTEL_COMPILER) && !defined(IMGUI_DEBUG_PARANOID) {
} else {
}

// Warnings
when _MSC_VER {
}

//-----------------------------------------------------------------------------
// [SECTION] Forward declarations and basic types
//-----------------------------------------------------------------------------

// Scalar data types
ImGuiID :: u32// A unique ID used by widgets (typically the result of hashing a stack of string)
i64 :: signed   long long  // 64-bit signed integer

// Forward declarations

// Enumerations
// - We don't use strongly typed enums much because they add constraints (can't extend in private code, can't store typed in bit fields, extra casting on iteration)
// - Tip: Use your programming IDE navigation facilities on the names in the _central column_ below to find the actual flags/enum lists!
//   - In Visual Studio: CTRL+comma ("Edit.GoToAll") can follow symbols inside comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
//   - In Visual Studio w/ Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols inside comments.
//   - In VS Code, CLion, etc.: CTRL+click can follow symbols inside comments.

// Flags (declared as int to allow using as flags without overhead, and to not pollute the top of this file)
// - Tip: Use your programming IDE navigation facilities on the names in the _central column_ below to find the actual flags/enum lists!
//   - In Visual Studio: CTRL+comma ("Edit.GoToAll") can follow symbols inside comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
//   - In Visual Studio w/ Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols inside comments.
//   - In VS Code, CLion, etc.: CTRL+click can follow symbols inside comments.
ImGuiKeyChord :: i32          // -> ImGuiKey | ImGuiMod_XXX    // Flags: for IsKeyChordPressed(), Shortcut() etc. an ImGuiKey optionally OR-ed with one or more ImGuiMod_XXX values.

// ImTexture: user data for renderer backend to identify a texture [Compile-time configurable type]
// - To use something else than an opaque void* pointer: override with e.g. '#define ImTextureID MyTextureType*' in your imconfig.h file.
// - This can be whatever to you want it to be! read the FAQ about ImTextureID for details.
// - You can make this a structure with various constructors if you need. You will have to implement ==/!= operators.
// - (note: before v1.91.4 (2024/10/08) the default type for ImTextureID was void*. Use intermediary intptr_t cast and read FAQ if you have casting warnings)
when !(ImTextureID) {
ImTextureID :: u64          // Default: store a pointer or an integer fitting in a pointer (most renderer backends are ok with that)
}

// ImDrawIdx: vertex index. [Compile-time configurable type]
// - To use 16-bit indices + allow large meshes: backend need to set 'io.BackendFlags |= ImGuiBackendFlags_RendererHasVtxOffset' and handle ImDrawCmd::VtxOffset (recommended).
// - To use 32-bit indices: override with '#define ImDrawIdx unsigned int' in your imconfig.h file.
when !(ImDrawIdx) {
ImDrawIdx :: u16   // Default: 16-bit (for maximum compatibility with renderer backends)
}

// Character types
// (we generally use UTF-8 encoded string in the API. This is storage specifically for a decoded character used for keyboard input and display)
ImWchar32 :: u32     // A single decoded U32 character/code point. We encode them as multi bytes UTF-8 when used in strings.
ImWchar16 :: u16   // A single decoded U16 character/code point. We encode them as multi bytes UTF-8 when used in strings.
when IMGUI_USE_WCHAR32 {            // ImWchar [configurable type: override in imconfig.h with '#define IMGUI_USE_WCHAR32' to support Unicode planes 1-16]
ImWchar :: ImWchar32
} else {
ImWchar :: ImWchar16
}

// Multi-Selection item index or identifier when using BeginMultiSelect()
// - Used by SetNextItemSelectionUserData() + and inside ImGuiMultiSelectIO structure.
// - Most users are likely to use this store an item INDEX but this may be used to store a POINTER/ID as well. Read comments near ImGuiMultiSelectIO for details.
ImGuiSelectionUserData :: i64

// Callback and functions types
ImGuiInputTextCallback :: #type proc(data : ^ImGuiInputTextCallbackData) -> i32    // Callback function for ImGui::InputText()
ImGuiSizeCallback :: #type proc(data : ^ImGuiSizeCallbackData)              // Callback function for ImGui::SetNextWindowSizeConstraints()
ImGuiMemAllocFunc :: #type proc(sz : int, user_data : rawptr) -> rawptr               // Function signature for ImGui::SetAllocatorFunctions()
ImGuiMemFreeFunc :: #type proc(ptr : rawptr, user_data : rawptr)                // Function signature for ImGui::SetAllocatorFunctions()

// ImVec2: 2D vector used to store positions, sizes etc. [Compile-time configurable type]
// - This is a frequently used type in the API. Consider using IM_VEC2_CLASS_EXTRA to create implicit cast from/to our preferred type.
// - Add '#define IMGUI_DEFINE_MATH_OPERATORS' before including this file (or in imconfig.h) to access courtesy maths operators for ImVec2 and ImVec4.
ImVec2 :: struct
{
    x, y : f32,
    constexpr ImVec2{)                      : x(0.0}, y(0.0) { }
    constexpr ImVec2{f32 _x, f32 _y}    : x(_x), y(_y) { }
    f32& operator[] (int idx)          { assert(idx == 0 || idx == 1); return ((f32*)(rawptr)(u8*)this)[idx]; } // We very rarely use this [] operator, so the assert overhead is fine.
    f32  operator[] (int idx) const    { assert(idx == 0 || idx == 1); return ((const f32*)(const rawptr)(const u8*)this)[idx]; }
};

// ImVec4: 4D vector used to store clipping rectangles, colors etc. [Compile-time configurable type]
ImVec4 :: struct
{
    x, y, z, w : f32,
    constexpr ImVec4{)                                        : x(0.0}, y(0.0), z(0.0), w(0.0) { }
    constexpr ImVec4{f32 _x, f32 _y, f32 _z, f32 _w}  : x(_x), y(_y), z(_z), w(_w) { }
};

//-----------------------------------------------------------------------------
// [SECTION] Dear ImGui end-user API functions
// (Note that ImGui:: being a namespace, you can add extra ImGui:: functions in your own separate file. Please don't modify imgui source files!)
//-----------------------------------------------------------------------------

namespace ImGui
{
    // Context creation and access
    // - Each context create its own ImFontAtlas by default. You may instance one yourself and pass it to CreateContext() to share a font atlas between contexts.
    // - DLL users: heaps and globals are not shared across DLL boundaries! You will need to call SetCurrentContext() + SetAllocatorFunctions()
    //   for each static/DLL boundary you are calling from. Read "Context and Memory Allocators" section of imgui.cpp for details.
    ImGuiContext* CreateContext(ImFontAtlas* shared_font_atlas = nil);
    void          DestroyContext(ImGuiContext* ctx = nil);   // NULL = destroy current context
    ImGuiContext* GetCurrentContext();
    void          SetCurrentContext(ImGuiContext* ctx);

    // Main
    ImGuiIO&      GetIO();                                    // access the ImGuiIO structure (mouse/keyboard/gamepad inputs, time, various configuration options/flags)
    ImGuiPlatformIO& GetPlatformIO();                         // access the ImGuiPlatformIO structure (mostly hooks/functions to connect to platform/renderer and OS Clipboard, IME etc.)
    ImGuiStyle&   GetStyle();                                 // access the Style structure (colors, sizes). Always use PushStyleColor(), PushStyleVar() to modify style mid-frame!
    void          NewFrame();                                 // start a new Dear ImGui frame, you can submit any command from this point until Render()/EndFrame().
    void          EndFrame();                                 // ends the Dear ImGui frame. automatically called by Render(). If you don't need to render data (skipping rendering) you may call EndFrame() without Render()... but you'll have wasted CPU already! If you don't need to render, better to not create any windows and not call NewFrame() at all!
    void          Render();                                   // ends the Dear ImGui frame, finalize the draw data. You can then get call GetDrawData().
    ImDrawData*   GetDrawData();                              // valid after Render() and until the next call to NewFrame(). this is what you have to render.

    // Demo, Debug, Information
    void          ShowDemoWindow(bool* p_open = nil);        // create Demo window. demonstrate most ImGui features. call this to learn about the library! try to make it always available in your application!
    void          ShowMetricsWindow(bool* p_open = nil);     // create Metrics/Debugger window. display Dear ImGui internals: windows, draw commands, various internal state, etc.
    void          ShowDebugLogWindow(bool* p_open = nil);    // create Debug Log window. display a simplified log of important dear imgui events.
    void          ShowIDStackToolWindow(bool* p_open = nil); // create Stack Tool window. hover items with mouse to query information about the source of their unique ID.
    void          ShowAboutWindow(bool* p_open = nil);       // create About window. display Dear ImGui version, credits and build/system information.
    void          ShowStyleEditor(ImGuiStyle* ref = nil);    // add style editor block (not a window). you can pass in a reference ImGuiStyle structure to compare to, revert to and save to (else it uses the default style)
    bool          ShowStyleSelector(const u8* label);       // add style selector block (not a window), essentially a combo listing the default styles.
    void          ShowFontSelector(const u8* label);        // add font selector block (not a window), essentially a combo listing the loaded fonts.
    void          ShowUserGuide();                            // add basic help/info block (not a window): how to manipulate ImGui as an end-user (mouse/keyboard controls).
    const u8*   GetVersion();                               // get the compiled version string e.g. "1.80 WIP" (essentially the value for IMGUI_VERSION from the compiled version of imgui.cpp)

    // Styles
    void          StyleColorsDark(ImGuiStyle* dst = nil);    // new, recommended style (default)
    void          StyleColorsLight(ImGuiStyle* dst = nil);   // best used with borders and a custom, thicker font
    void          StyleColorsClassic(ImGuiStyle* dst = nil); // classic imgui style

    // Windows
    // - Begin() = push window to the stack and start appending to it. End() = pop window from the stack.
    // - Passing 'bool* p_open != NULL' shows a window-closing widget in the upper-right corner of the window,
    //   which clicking will set the boolean to false when clicked.
    // - You may append multiple times to the same window during the same frame by calling Begin()/End() pairs multiple times.
    //   Some information such as 'flags' or 'p_open' will only be considered by the first call to Begin().
    // - Begin() return false to indicate the window is collapsed or fully clipped, so you may early out and omit submitting
    //   anything to the window. Always call a matching End() for each Begin() call, regardless of its return value!
    //   [Important: due to legacy reason, Begin/End and BeginChild/EndChild are inconsistent with all other functions
    //    such as BeginMenu/EndMenu, BeginPopup/EndPopup, etc. where the EndXXX call should only be called if the corresponding
    //    BeginXXX function returned true. Begin and BeginChild are the only odd ones out. Will be fixed in a future update.]
    // - Note that the bottom of window stack always contains a window called "Debug".
    bool          Begin(const u8* name, bool* p_open = nil, ImGuiWindowFlags flags = 0);
    void          End();

    // Child Windows
    // - Use child windows to begin into a self-contained independent scrolling/clipping regions within a host window. Child windows can embed their own child.
    // - Before 1.90 (November 2023), the "ImGuiChildFlags child_flags = 0" parameter was "bool border = false".
    //   This API is backward compatible with old code, as we guarantee that ImGuiChildFlags_Borders == true.
    //   Consider updating your old code:
    //      BeginChild("Name", size, false)   -> Begin("Name", size, 0); or Begin("Name", size, ImGuiChildFlags_None);
    //      BeginChild("Name", size, true)    -> Begin("Name", size, ImGuiChildFlags_Borders);
    // - Manual sizing (each axis can use a different setting e.g. ImVec2(0.0f, 400.0f)):
    //     == 0.0f: use remaining parent window size for this axis.
    //      > 0.0f: use specified size for this axis.
    //      < 0.0f: right/bottom-align to specified distance from available content boundaries.
    // - Specifying ImGuiChildFlags_AutoResizeX or ImGuiChildFlags_AutoResizeY makes the sizing automatic based on child contents.
    //   Combining both ImGuiChildFlags_AutoResizeX _and_ ImGuiChildFlags_AutoResizeY defeats purpose of a scrolling region and is NOT recommended.
    // - BeginChild() returns false to indicate the window is collapsed or fully clipped, so you may early out and omit submitting
    //   anything to the window. Always call a matching EndChild() for each BeginChild() call, regardless of its return value.
    //   [Important: due to legacy reason, Begin/End and BeginChild/EndChild are inconsistent with all other functions
    //    such as BeginMenu/EndMenu, BeginPopup/EndPopup, etc. where the EndXXX call should only be called if the corresponding
    //    BeginXXX function returned true. Begin and BeginChild are the only odd ones out. Will be fixed in a future update.]
    bool          BeginChild(const u8* str_id, const ImVec2& size = ImVec2{0, 0}, ImGuiChildFlags child_flags = 0, ImGuiWindowFlags window_flags = 0);
    bool          BeginChild(ImGuiID id, const ImVec2& size = ImVec2{0, 0}, ImGuiChildFlags child_flags = 0, ImGuiWindowFlags window_flags = 0);
    void          EndChild();

    // Windows Utilities
    // - 'current window' = the window we are appending into while inside a Begin()/End() block. 'next window' = next window we will Begin() into.
    bool          IsWindowAppearing();
    bool          IsWindowCollapsed();
    bool          IsWindowFocused(ImGuiFocusedFlags flags=0); // is current window focused? or its root/child, depending on flags. see flags for options.
    bool          IsWindowHovered(ImGuiHoveredFlags flags=0); // is current window hovered and hoverable (e.g. not blocked by a popup/modal)? See ImGuiHoveredFlags_ for options. IMPORTANT: If you are trying to check whether your mouse should be dispatched to Dear ImGui or to your underlying app, you should not use this function! Use the 'io.WantCaptureMouse' boolean for that! Refer to FAQ entry "How can I tell whether to dispatch mouse/keyboard to Dear ImGui or my application?" for details.
    ImDrawList*   GetWindowDrawList();                        // get draw list associated to the current window, to append your own drawing primitives
    f32         GetWindowDpiScale();                        // get DPI scale currently associated to the current window's viewport.
    GetWindowPos := ImVec2();                             // get current window position in screen space (IT IS UNLIKELY YOU EVER NEED TO USE THIS. Consider always using GetCursorScreenPos() and GetContentRegionAvail() instead)
    GetWindowSize := ImVec2();                            // get current window size (IT IS UNLIKELY YOU EVER NEED TO USE THIS. Consider always using GetCursorScreenPos() and GetContentRegionAvail() instead)
    f32         GetWindowWidth();                           // get current window width (IT IS UNLIKELY YOU EVER NEED TO USE THIS). Shortcut for GetWindowSize().x.
    f32         GetWindowHeight();                          // get current window height (IT IS UNLIKELY YOU EVER NEED TO USE THIS). Shortcut for GetWindowSize().y.
    ImGuiViewport*GetWindowViewport();                        // get viewport currently associated to the current window.

    // Window manipulation
    // - Prefer using SetNextXXX functions (before Begin) rather that SetXXX functions (after Begin).
    void          SetNextWindowPos(const ImVec2& pos, ImGuiCond cond = 0, const ImVec2& pivot = ImVec2{0, 0}); // set next window position. call before Begin(). use pivot=(0.5f,0.5f) to center on given point, etc.
    void          SetNextWindowSize(const ImVec2& size, ImGuiCond cond = 0);                  // set next window size. set axis to 0.0f to force an auto-fit on this axis. call before Begin()
    void          SetNextWindowSizeConstraints(const ImVec2& size_min, const ImVec2& size_max, ImGuiSizeCallback custom_callback = nil, rawptr custom_callback_data = nil); // set next window size limits. use 0.0f or FLT_MAX if you don't want limits. Use -1 for both min and max of same axis to preserve current size (which itself is a constraint). Use callback to apply non-trivial programmatic constraints.
    void          SetNextWindowContentSize(const ImVec2& size);                               // set next window content size (~ scrollable client area, which enforce the range of scrollbars). Not including window decorations (title bar, menu bar, etc.) nor WindowPadding. set an axis to 0.0f to leave it automatic. call before Begin()
    void          SetNextWindowCollapsed(bool collapsed, ImGuiCond cond = 0);                 // set next window collapsed state. call before Begin()
    void          SetNextWindowFocus();                                                       // set next window to be focused / top-most. call before Begin()
    void          SetNextWindowScroll(const ImVec2& scroll);                                  // set next window scrolling value (use < 0.0f to not affect a given axis).
    void          SetNextWindowBgAlpha(f32 alpha);                                          // set next window background color alpha. helper to easily override the Alpha component of ImGuiCol_WindowBg/ChildBg/PopupBg. you may also use ImGuiWindowFlags_NoBackground.
    void          SetNextWindowViewport(ImGuiID viewport_id);                                 // set next window viewport
    void          SetWindowPos(const ImVec2& pos, ImGuiCond cond = 0);                        // (not recommended) set current window position - call within Begin()/End(). prefer using SetNextWindowPos(), as this may incur tearing and side-effects.
    void          SetWindowSize(const ImVec2& size, ImGuiCond cond = 0);                      // (not recommended) set current window size - call within Begin()/End(). set to ImVec2(0, 0) to force an auto-fit. prefer using SetNextWindowSize(), as this may incur tearing and minor side-effects.
    void          SetWindowCollapsed(bool collapsed, ImGuiCond cond = 0);                     // (not recommended) set current window collapsed state. prefer using SetNextWindowCollapsed().
    void          SetWindowFocus();                                                           // (not recommended) set current window to be focused / top-most. prefer using SetNextWindowFocus().
    void          SetWindowFontScale(f32 scale);                                            // [OBSOLETE] set font scale. Adjust IO.FontGlobalScale if you want to scale all windows. This is an old API! For correct scaling, prefer to reload font + rebuild ImFontAtlas + call style.ScaleAllSizes().
    void          SetWindowPos(const u8* name, const ImVec2& pos, ImGuiCond cond = 0);      // set named window position.
    void          SetWindowSize(const u8* name, const ImVec2& size, ImGuiCond cond = 0);    // set named window size. set axis to 0.0f to force an auto-fit on this axis.
    void          SetWindowCollapsed(const u8* name, bool collapsed, ImGuiCond cond = 0);   // set named window collapsed state
    void          SetWindowFocus(const u8* name);                                           // set named window to be focused / top-most. use NULL to remove focus.

    // Windows Scrolling
    // - Any change of Scroll will be applied at the beginning of next frame in the first call to Begin().
    // - You may instead use SetNextWindowScroll() prior to calling Begin() to avoid this delay, as an alternative to using SetScrollX()/SetScrollY().
    f32         GetScrollX();                                                   // get scrolling amount [0 .. GetScrollMaxX()]
    f32         GetScrollY();                                                   // get scrolling amount [0 .. GetScrollMaxY()]
    void          SetScrollX(f32 scroll_x);                                     // set scrolling amount [0 .. GetScrollMaxX()]
    void          SetScrollY(f32 scroll_y);                                     // set scrolling amount [0 .. GetScrollMaxY()]
    f32         GetScrollMaxX();                                                // get maximum scrolling amount ~~ ContentSize.x - WindowSize.x - DecorationsSize.x
    f32         GetScrollMaxY();                                                // get maximum scrolling amount ~~ ContentSize.y - WindowSize.y - DecorationsSize.y
    void          SetScrollHereX(f32 center_x_ratio = 0.5);                    // adjust scrolling amount to make current cursor position visible. center_x_ratio=0.0: left, 0.5: center, 1.0: right. When using to make a "default/current item" visible, consider using SetItemDefaultFocus() instead.
    void          SetScrollHereY(f32 center_y_ratio = 0.5);                    // adjust scrolling amount to make current cursor position visible. center_y_ratio=0.0: top, 0.5: center, 1.0: bottom. When using to make a "default/current item" visible, consider using SetItemDefaultFocus() instead.
    void          SetScrollFromPosX(f32 local_x, f32 center_x_ratio = 0.5);  // adjust scrolling amount to make given position visible. Generally GetCursorStartPos() + offset to compute a valid position.
    void          SetScrollFromPosY(f32 local_y, f32 center_y_ratio = 0.5);  // adjust scrolling amount to make given position visible. Generally GetCursorStartPos() + offset to compute a valid position.

    // Parameters stacks (shared)
    void          PushFont(ImFont* font);                                         // use NULL as a shortcut to push default font
    void          PopFont();
    void          PushStyleColor(ImGuiCol idx, u32 col);                        // modify a style color. always use this if you modify the style after NewFrame().
    void          PushStyleColor(ImGuiCol idx, const ImVec4& col);
    void          PopStyleColor(i32 count = 1);
    void          PushStyleVar(ImGuiStyleVar idx, f32 val);                     // modify a style float variable. always use this if you modify the style after NewFrame()!
    void          PushStyleVar(ImGuiStyleVar idx, const ImVec2& val);             // modify a style ImVec2 variable. "
    void          PushStyleVarX(ImGuiStyleVar idx, f32 val_x);                  // modify X component of a style ImVec2 variable. "
    void          PushStyleVarY(ImGuiStyleVar idx, f32 val_y);                  // modify Y component of a style ImVec2 variable. "
    void          PopStyleVar(i32 count = 1);
    void          PushItemFlag(ImGuiItemFlags option, bool enabled);              // modify specified shared item flag, e.g. PushItemFlag(ImGuiItemFlags_NoTabStop, true)
    void          PopItemFlag();

    // Parameters stacks (current window)
    void          PushItemWidth(f32 item_width);                                // push width of items for common large "item+label" widgets. >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -FLT_MIN always align width to the right side).
    void          PopItemWidth();
    void          SetNextItemWidth(f32 item_width);                             // set width of the _next_ common large "item+label" widget. >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -FLT_MIN always align width to the right side)
    f32         CalcItemWidth();                                                // width of item given pushed settings and current cursor position. NOT necessarily the width of last item unlike most 'Item' functions.
    void          PushTextWrapPos(f32 wrap_local_pos_x = 0.0);                 // push word-wrapping position for Text*() commands. < 0.0f: no wrapping; 0.0f: wrap to end of window (or column); > 0.0f: wrap at 'wrap_pos_x' position in window local space
    void          PopTextWrapPos();

    // Style read access
    // - Use the ShowStyleEditor() function to interactively see/edit the colors.
    ImFont*       GetFont();                                                      // get current font
    f32         GetFontSize();                                                  // get current font size (= height in pixels) of current font with current scale applied
    GetFontTexUvWhitePixel := ImVec2();                                       // get UV coordinate for a white pixel, useful to draw custom shapes via the ImDrawList API
    u32         GetColorU32(ImGuiCol idx, f32 alpha_mul = 1.0);              // retrieve given style color with style alpha applied and optional extra alpha multiplier, packed as a 32-bit value suitable for ImDrawList
    u32         GetColorU32(const ImVec4& col);                                 // retrieve given color with style alpha applied, packed as a 32-bit value suitable for ImDrawList
    u32         GetColorU32(u32 col, f32 alpha_mul = 1.0);                 // retrieve given color with style alpha applied, packed as a 32-bit value suitable for ImDrawList
    const ImVec4& GetStyleColorVec4(ImGuiCol idx);                                // retrieve style color as stored in ImGuiStyle structure. use to feed back into PushStyleColor(), otherwise use GetColorU32() to get style color with style alpha baked in.

    // Layout cursor positioning
    // - By "cursor" we mean the current output position.
    // - The typical widget behavior is to output themselves at the current cursor position, then move the cursor one line down.
    // - You can call SameLine() between widgets to undo the last carriage return and output at the right of the preceding widget.
    // - YOU CAN DO 99% OF WHAT YOU NEED WITH ONLY GetCursorScreenPos() and GetContentRegionAvail().
    // - Attention! We currently have inconsistencies between window-local and absolute positions we will aim to fix with future API:
    //    - Absolute coordinate:        GetCursorScreenPos(), SetCursorScreenPos(), all ImDrawList:: functions. -> this is the preferred way forward.
    //    - Window-local coordinates:   SameLine(offset), GetCursorPos(), SetCursorPos(), GetCursorStartPos(), PushTextWrapPos()
    //    - Window-local coordinates:   GetContentRegionMax(), GetWindowContentRegionMin(), GetWindowContentRegionMax() --> all obsoleted. YOU DON'T NEED THEM.
    // - GetCursorScreenPos() = GetCursorPos() + GetWindowPos(). GetWindowPos() is almost only ever useful to convert from window-local to absolute coordinates. Try not to use it.
    GetCursorScreenPos := ImVec2();                                           // cursor position, absolute coordinates. THIS IS YOUR BEST FRIEND (prefer using this rather than GetCursorPos(), also more useful to work with ImDrawList API).
    void          SetCursorScreenPos(const ImVec2& pos);                          // cursor position, absolute coordinates. THIS IS YOUR BEST FRIEND.
    GetContentRegionAvail := ImVec2();                                        // available space from current position. THIS IS YOUR BEST FRIEND.
    GetCursorPos := ImVec2();                                                 // [window-local] cursor position in window-local coordinates. This is not your best friend.
    f32         GetCursorPosX();                                                // [window-local] "
    f32         GetCursorPosY();                                                // [window-local] "
    void          SetCursorPos(const ImVec2& local_pos);                          // [window-local] "
    void          SetCursorPosX(f32 local_x);                                   // [window-local] "
    void          SetCursorPosY(f32 local_y);                                   // [window-local] "
    GetCursorStartPos := ImVec2();                                            // [window-local] initial cursor position, in window-local coordinates. Call GetCursorScreenPos() after Begin() to get the absolute coordinates version.

    // Other layout functions
    void          Separator();                                                    // separator, generally horizontal. inside a menu bar or in horizontal layout mode, this becomes a vertical separator.
    void          SameLine(f32 offset_from_start_x=0.0, f32 spacing=-1.0);  // call between widgets or groups to layout them horizontally. X position given in window coordinates.
    void          NewLine();                                                      // undo a SameLine() or force a new line when in a horizontal-layout context.
    void          Spacing();                                                      // add vertical spacing.
    void          Dummy(const ImVec2& size);                                      // add a dummy item of given size. unlike InvisibleButton(), Dummy() won't take the mouse click or be navigable into.
    void          Indent(f32 indent_w = 0.0);                                  // move content position toward the right, by indent_w, or style.IndentSpacing if indent_w <= 0
    void          Unindent(f32 indent_w = 0.0);                                // move content position back to the left, by indent_w, or style.IndentSpacing if indent_w <= 0
    void          BeginGroup();                                                   // lock horizontal starting position
    void          EndGroup();                                                     // unlock horizontal starting position + capture the whole group bounding box into one "item" (so you can use IsItemHovered() or layout primitives such as SameLine() on whole group, etc.)
    void          AlignTextToFramePadding();                                      // vertically align upcoming text baseline to FramePadding.y so that it will align properly to regularly framed items (call if you have text on a line before a framed item)
    f32         GetTextLineHeight();                                            // ~ FontSize
    f32         GetTextLineHeightWithSpacing();                                 // ~ FontSize + style.ItemSpacing.y (distance in pixels between 2 consecutive lines of text)
    f32         GetFrameHeight();                                               // ~ FontSize + style.FramePadding.y * 2
    f32         GetFrameHeightWithSpacing();                                    // ~ FontSize + style.FramePadding.y * 2 + style.ItemSpacing.y (distance in pixels between 2 consecutive lines of framed widgets)

    // ID stack/scopes
    // Read the FAQ (docs/FAQ.md or http://dearimgui.com/faq) for more details about how ID are handled in dear imgui.
    // - Those questions are answered and impacted by understanding of the ID stack system:
    //   - "Q: Why is my widget not reacting when I click on it?"
    //   - "Q: How can I have widgets with an empty label?"
    //   - "Q: How can I have multiple widgets with the same label?"
    // - Short version: ID are hashes of the entire ID stack. If you are creating widgets in a loop you most likely
    //   want to push a unique identifier (e.g. object pointer, loop index) to uniquely differentiate them.
    // - You can also use the "Label##foobar" syntax within widget label to distinguish them from each others.
    // - In this header file we use the "label"/"name" terminology to denote a string that will be displayed + used as an ID,
    //   whereas "str_id" denote a string that is only used as an ID and not normally displayed.
    void          PushID(const u8* str_id);                                     // push string into the ID stack (will hash string).
    void          PushID(const u8* str_id_begin, const u8* str_id_end);       // push string into the ID stack (will hash string).
    void          PushID(const rawptr ptr_id);                                     // push pointer into the ID stack (will hash pointer).
    void          PushID(i32 int_id);                                             // push integer into the ID stack (will hash integer).
    void          PopID();                                                        // pop from the ID stack.
    GetID := ImGuiID(const u8* str_id);                                      // calculate unique ID (hash of whole ID stack + given parameter). e.g. if you want to query into ImGuiStorage yourself
    GetID := ImGuiID(const u8* str_id_begin, const u8* str_id_end);
    GetID := ImGuiID(const rawptr ptr_id);
    GetID := ImGuiID(i32 int_id);

    // Widgets: Text
    void          TextUnformatted(const u8* text, const u8* text_end = nil); // raw text without formatting. Roughly equivalent to Text("%s", text) but: A) doesn't require null terminated string if 'text_end' is specified, B) it's faster, no memory copy is done, no buffer size limits, recommended for long chunks of text.
    void          Text(const u8* fmt, ...)                                      ; // formatted text
    void          TextV(const u8* fmt, va_list args)                            ;
    void          TextColored(const ImVec4& col, const u8* fmt, ...)            ; // shortcut for PushStyleColor(ImGuiCol_Text, col); Text(fmt, ...); PopStyleColor();
    void          TextColoredV(const ImVec4& col, const u8* fmt, va_list args)  ;
    void          TextDisabled(const u8* fmt, ...)                              ; // shortcut for PushStyleColor(ImGuiCol_Text, style.Colors[ImGuiCol_TextDisabled]); Text(fmt, ...); PopStyleColor();
    void          TextDisabledV(const u8* fmt, va_list args)                    ;
    void          TextWrapped(const u8* fmt, ...)                               ; // shortcut for PushTextWrapPos(0.0f); Text(fmt, ...); PopTextWrapPos();. Note that this won't work on an auto-resizing window if there's no other widgets to extend the window width, yoy may need to set a size using SetNextWindowSize().
    void          TextWrappedV(const u8* fmt, va_list args)                     ;
    void          LabelText(const u8* label, const u8* fmt, ...)              ; // display text+label aligned the same way as value+label widgets
    void          LabelTextV(const u8* label, const u8* fmt, va_list args)    ;
    void          BulletText(const u8* fmt, ...)                                ; // shortcut for Bullet()+Text()
    void          BulletTextV(const u8* fmt, va_list args)                      ;
    void          SeparatorText(const u8* label);                               // currently: formatted text with an horizontal line

    // Widgets: Main
    // - Most widgets return true when the value has been changed or when pressed/selected
    // - You may also use one of the many IsItemXXX functions (e.g. IsItemActive, IsItemHovered, etc.) to query widget state.
    bool          Button(const u8* label, const ImVec2& size = ImVec2{0, 0});   // button
    bool          SmallButton(const u8* label);                                 // button with (FramePadding.y == 0) to easily embed within text
    bool          InvisibleButton(const u8* str_id, const ImVec2& size, ImGuiButtonFlags flags = 0); // flexible button behavior without the visuals, frequently useful to build custom behaviors using the public api (along with IsItemActive, IsItemHovered, etc.)
    bool          ArrowButton(const u8* str_id, ImGuiDir dir);                  // square button with an arrow shape
    bool          Checkbox(const u8* label, bool* v);
    bool          CheckboxFlags(const u8* label, i32* flags, i32 flags_value);
    bool          CheckboxFlags(const u8* label, u32* flags, u32 flags_value);
    bool          RadioButton(const u8* label, bool active);                    // use with e.g. if (RadioButton("one", my_value==1)) { my_value = 1; }
    bool          RadioButton(const u8* label, i32* v, i32 v_button);           // shortcut to handle the above pattern when value is an integer
    void          ProgressBar(f32 fraction, const ImVec2& size_arg = ImVec2{-math.F32_MIN, 0}, const u8* overlay = nil);
    void          Bullet();                                                       // draw a small circle + keep the cursor on the same line. advance cursor x position by GetTreeNodeToLabelSpacing(), same distance that TreeNode() uses
    bool          TextLink(const u8* label);                                    // hyperlink text button, return true when clicked
    void          TextLinkOpenURL(const u8* label, const u8* url = nil);     // hyperlink text button, automatically open file/url when clicked

    // Widgets: Images
    // - Read about ImTextureID here: https://github.com/ocornut/imgui/wiki/Image-Loading-and-Displaying-Examples
    // - 'uv0' and 'uv1' are texture coordinates. Read about them from the same link above.
    // - Note that Image() may add +2.0f to provided size if a border is visible, ImageButton() adds style.FramePadding*2.0f to provided size.
    // - ImageButton() draws a background based on regular Button() color + optionally an inner background if specified.
    void          Image(ImTextureID user_texture_id, const ImVec2& image_size, const ImVec2& uv0 = ImVec2{0, 0}, const ImVec2& uv1 = ImVec2{1, 1}, const ImVec4& tint_col = ImVec4{1, 1, 1, 1}, const ImVec4& border_col = ImVec4{0, 0, 0, 0});
    bool          ImageButton(const u8* str_id, ImTextureID user_texture_id, const ImVec2& image_size, const ImVec2& uv0 = ImVec2{0, 0}, const ImVec2& uv1 = ImVec2{1, 1}, const ImVec4& bg_col = ImVec4{0, 0, 0, 0}, const ImVec4& tint_col = ImVec4{1, 1, 1, 1});

    // Widgets: Combo Box (Dropdown)
    // - The BeginCombo()/EndCombo() api allows you to manage your contents and selection state however you want it, by creating e.g. Selectable() items.
    // - The old Combo() api are helpers over BeginCombo()/EndCombo() which are kept available for convenience purpose. This is analogous to how ListBox are created.
    bool          BeginCombo(const u8* label, const u8* preview_value, ImGuiComboFlags flags = 0);
    void          EndCombo(); // only call EndCombo() if BeginCombo() returns true!
    bool          Combo(const u8* label, i32* current_item, const u8* const items[], i32 items_count, i32 popup_max_height_in_items = -1);
    bool          Combo(const u8* label, i32* current_item, const u8* items_separated_by_zeros, i32 popup_max_height_in_items = -1);      // Separate items with \0 within a string, end item-list with \0\0. e.g. "One\0Two\0Three\0"
    bool          Combo(const u8* label, i32* current_item, const u8* (*getter)(rawptr user_data, i32 idx), rawptr user_data, i32 items_count, i32 popup_max_height_in_items = -1);

    // Widgets: Drag Sliders
    // - CTRL+Click on any drag box to turn them into an input box. Manually input values aren't clamped by default and can go off-bounds. Use ImGuiSliderFlags_AlwaysClamp to always clamp.
    // - For all the Float2/Float3/Float4/Int2/Int3/Int4 versions of every function, note that a 'float v[X]' function argument is the same as 'float* v',
    //   the array syntax is just a way to document the number of elements that are expected to be accessible. You can pass address of your first element out of a contiguous set, e.g. &myvector.x
    // - Adjust format string to decorate the value with a prefix, a suffix, or adapt the editing and display precision e.g. "%.3f" -> 1.234; "%5.2f secs" -> 01.23 secs; "Biscuit: %.0f" -> Biscuit: 1; etc.
    // - Format string may also be set to NULL or use the default format ("%f" or "%d").
    // - Speed are per-pixel of mouse movement (v_speed=0.2f: mouse needs to move by 5 pixels to increase value by 1). For keyboard/gamepad navigation, minimum speed is Max(v_speed, minimum_step_at_given_precision).
    // - Use v_min < v_max to clamp edits to given limits. Note that CTRL+Click manual input can override those limits if ImGuiSliderFlags_AlwaysClamp is not used.
    // - Use v_max = FLT_MAX / INT_MAX etc to avoid clamping to a maximum, same with v_min = -FLT_MAX / INT_MIN to avoid clamping to a minimum.
    // - We use the same sets of flags for DragXXX() and SliderXXX() functions as the features are the same and it makes it easier to swap them.
    // - Legacy: Pre-1.78 there are DragXXX() function signatures that take a final `float power=1.0f' argument instead of the `ImGuiSliderFlags flags=0' argument.
    //   If you get a warning converting a float to ImGuiSliderFlags, read https://github.com/ocornut/imgui/issues/3361
    bool          DragFloat(const u8* label, f32* v, f32 v_speed = 1.0, f32 v_min = 0.0, f32 v_max = 0.0, const u8* format = "%.3", ImGuiSliderFlags flags = 0);     // If v_min >= v_max we have no bound
    bool          DragFloat2(const u8* label, f32 v[2], f32 v_speed = 1.0, f32 v_min = 0.0, f32 v_max = 0.0, const u8* format = "%.3", ImGuiSliderFlags flags = 0);
    bool          DragFloat3(const u8* label, f32 v[3], f32 v_speed = 1.0, f32 v_min = 0.0, f32 v_max = 0.0, const u8* format = "%.3", ImGuiSliderFlags flags = 0);
    bool          DragFloat4(const u8* label, f32 v[4], f32 v_speed = 1.0, f32 v_min = 0.0, f32 v_max = 0.0, const u8* format = "%.3", ImGuiSliderFlags flags = 0);
    bool          DragFloatRange2(const u8* label, f32* v_current_min, f32* v_current_max, f32 v_speed = 1.0, f32 v_min = 0.0, f32 v_max = 0.0, const u8* format = "%.3", const u8* format_max = nil, ImGuiSliderFlags flags = 0);
    bool          DragInt(const u8* label, i32* v, f32 v_speed = 1.0, i32 v_min = 0, i32 v_max = 0, const u8* format = "%d", ImGuiSliderFlags flags = 0);  // If v_min >= v_max we have no bound
    bool          DragInt2(const u8* label, i32 v[2], f32 v_speed = 1.0, i32 v_min = 0, i32 v_max = 0, const u8* format = "%d", ImGuiSliderFlags flags = 0);
    bool          DragInt3(const u8* label, i32 v[3], f32 v_speed = 1.0, i32 v_min = 0, i32 v_max = 0, const u8* format = "%d", ImGuiSliderFlags flags = 0);
    bool          DragInt4(const u8* label, i32 v[4], f32 v_speed = 1.0, i32 v_min = 0, i32 v_max = 0, const u8* format = "%d", ImGuiSliderFlags flags = 0);
    bool          DragIntRange2(const u8* label, i32* v_current_min, i32* v_current_max, f32 v_speed = 1.0, i32 v_min = 0, i32 v_max = 0, const u8* format = "%d", const u8* format_max = nil, ImGuiSliderFlags flags = 0);
    bool          DragScalar(const u8* label, ImGuiDataType data_type, rawptr p_data, f32 v_speed = 1.0, const rawptr p_min = nil, const rawptr p_max = nil, const u8* format = nil, ImGuiSliderFlags flags = 0);
    bool          DragScalarN(const u8* label, ImGuiDataType data_type, rawptr p_data, i32 components, f32 v_speed = 1.0, const rawptr p_min = nil, const rawptr p_max = nil, const u8* format = nil, ImGuiSliderFlags flags = 0);

    // Widgets: Regular Sliders
    // - CTRL+Click on any slider to turn them into an input box. Manually input values aren't clamped by default and can go off-bounds. Use ImGuiSliderFlags_AlwaysClamp to always clamp.
    // - Adjust format string to decorate the value with a prefix, a suffix, or adapt the editing and display precision e.g. "%.3f" -> 1.234; "%5.2f secs" -> 01.23 secs; "Biscuit: %.0f" -> Biscuit: 1; etc.
    // - Format string may also be set to NULL or use the default format ("%f" or "%d").
    // - Legacy: Pre-1.78 there are SliderXXX() function signatures that take a final `float power=1.0f' argument instead of the `ImGuiSliderFlags flags=0' argument.
    //   If you get a warning converting a float to ImGuiSliderFlags, read https://github.com/ocornut/imgui/issues/3361
    bool          SliderFloat(const u8* label, f32* v, f32 v_min, f32 v_max, const u8* format = "%.3", ImGuiSliderFlags flags = 0);     // adjust format to decorate the value with a prefix or a suffix for in-slider labels or unit display.
    bool          SliderFloat2(const u8* label, f32 v[2], f32 v_min, f32 v_max, const u8* format = "%.3", ImGuiSliderFlags flags = 0);
    bool          SliderFloat3(const u8* label, f32 v[3], f32 v_min, f32 v_max, const u8* format = "%.3", ImGuiSliderFlags flags = 0);
    bool          SliderFloat4(const u8* label, f32 v[4], f32 v_min, f32 v_max, const u8* format = "%.3", ImGuiSliderFlags flags = 0);
    bool          SliderAngle(const u8* label, f32* v_rad, f32 v_degrees_min = -360.0, f32 v_degrees_max = +360.0, const u8* format = "%.0 deg", ImGuiSliderFlags flags = 0);
    bool          SliderInt(const u8* label, i32* v, i32 v_min, i32 v_max, const u8* format = "%d", ImGuiSliderFlags flags = 0);
    bool          SliderInt2(const u8* label, i32 v[2], i32 v_min, i32 v_max, const u8* format = "%d", ImGuiSliderFlags flags = 0);
    bool          SliderInt3(const u8* label, i32 v[3], i32 v_min, i32 v_max, const u8* format = "%d", ImGuiSliderFlags flags = 0);
    bool          SliderInt4(const u8* label, i32 v[4], i32 v_min, i32 v_max, const u8* format = "%d", ImGuiSliderFlags flags = 0);
    bool          SliderScalar(const u8* label, ImGuiDataType data_type, rawptr p_data, const rawptr p_min, const rawptr p_max, const u8* format = nil, ImGuiSliderFlags flags = 0);
    bool          SliderScalarN(const u8* label, ImGuiDataType data_type, rawptr p_data, i32 components, const rawptr p_min, const rawptr p_max, const u8* format = nil, ImGuiSliderFlags flags = 0);
    bool          VSliderFloat(const u8* label, const ImVec2& size, f32* v, f32 v_min, f32 v_max, const u8* format = "%.3", ImGuiSliderFlags flags = 0);
    bool          VSliderInt(const u8* label, const ImVec2& size, i32* v, i32 v_min, i32 v_max, const u8* format = "%d", ImGuiSliderFlags flags = 0);
    bool          VSliderScalar(const u8* label, const ImVec2& size, ImGuiDataType data_type, rawptr p_data, const rawptr p_min, const rawptr p_max, const u8* format = nil, ImGuiSliderFlags flags = 0);

    // Widgets: Input with Keyboard
    // - If you want to use InputText() with std::string or any custom dynamic string type, see misc/cpp/imgui_stdlib.h and comments in imgui_demo.cpp.
    // - Most of the ImGuiInputTextFlags flags are only useful for InputText() and not for InputFloatX, InputIntX, InputDouble etc.
    bool          InputText(const u8* label, u8* buf, int buf_size, ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = nil, rawptr user_data = nil);
    bool          InputTextMultiline(const u8* label, u8* buf, int buf_size, const ImVec2& size = ImVec2{0, 0}, ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = nil, rawptr user_data = nil);
    bool          InputTextWithHint(const u8* label, const u8* hint, u8* buf, int buf_size, ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = nil, rawptr user_data = nil);
    bool          InputFloat(const u8* label, f32* v, f32 step = 0.0, f32 step_fast = 0.0, const u8* format = "%.3", ImGuiInputTextFlags flags = 0);
    bool          InputFloat2(const u8* label, f32 v[2], const u8* format = "%.3", ImGuiInputTextFlags flags = 0);
    bool          InputFloat3(const u8* label, f32 v[3], const u8* format = "%.3", ImGuiInputTextFlags flags = 0);
    bool          InputFloat4(const u8* label, f32 v[4], const u8* format = "%.3", ImGuiInputTextFlags flags = 0);
    bool          InputInt(const u8* label, i32* v, i32 step = 1, i32 step_fast = 100, ImGuiInputTextFlags flags = 0);
    bool          InputInt2(const u8* label, i32 v[2], ImGuiInputTextFlags flags = 0);
    bool          InputInt3(const u8* label, i32 v[3], ImGuiInputTextFlags flags = 0);
    bool          InputInt4(const u8* label, i32 v[4], ImGuiInputTextFlags flags = 0);
    bool          InputDouble(const u8* label, f64* v, f64 step = 0.0, f64 step_fast = 0.0, const u8* format = "%.6", ImGuiInputTextFlags flags = 0);
    bool          InputScalar(const u8* label, ImGuiDataType data_type, rawptr p_data, const rawptr p_step = nil, const rawptr p_step_fast = nil, const u8* format = nil, ImGuiInputTextFlags flags = 0);
    bool          InputScalarN(const u8* label, ImGuiDataType data_type, rawptr p_data, i32 components, const rawptr p_step = nil, const rawptr p_step_fast = nil, const u8* format = nil, ImGuiInputTextFlags flags = 0);

    // Widgets: Color Editor/Picker (tip: the ColorEdit* functions have a little color square that can be left-clicked to open a picker, and right-clicked to open an option menu.)
    // - Note that in C++ a 'float v[X]' function argument is the _same_ as 'float* v', the array syntax is just a way to document the number of elements that are expected to be accessible.
    // - You can pass the address of a first float element out of a contiguous structure, e.g. &myvector.x
    bool          ColorEdit3(const u8* label, f32 col[3], ImGuiColorEditFlags flags = 0);
    bool          ColorEdit4(const u8* label, f32 col[4], ImGuiColorEditFlags flags = 0);
    bool          ColorPicker3(const u8* label, f32 col[3], ImGuiColorEditFlags flags = 0);
    bool          ColorPicker4(const u8* label, f32 col[4], ImGuiColorEditFlags flags = 0, const f32* ref_col = nil);
    bool          ColorButton(const u8* desc_id, const ImVec4& col, ImGuiColorEditFlags flags = 0, const ImVec2& size = ImVec2{0, 0}); // display a color square/button, hover for details, return true when pressed.
    void          SetColorEditOptions(ImGuiColorEditFlags flags);                     // initialize current options (generally on application startup) if you want to select a default format, picker type, etc. User will be able to change many settings, unless you pass the _NoOptions flag to your calls.

    // Widgets: Trees
    // - TreeNode functions return true when the node is open, in which case you need to also call TreePop() when you are finished displaying the tree node contents.
    bool          TreeNode(const u8* label);
    bool          TreeNode(const u8* str_id, const u8* fmt, ...) ;   // helper variation to easily decorelate the id from the displayed string. Read the FAQ about why and how to use ID. to align arbitrary text at the same level as a TreeNode() you can use Bullet().
    bool          TreeNode(const rawptr ptr_id, const u8* fmt, ...) ;   // "
    bool          TreeNodeV(const u8* str_id, const u8* fmt, va_list args) ;
    bool          TreeNodeV(const rawptr ptr_id, const u8* fmt, va_list args) ;
    bool          TreeNodeEx(const u8* label, ImGuiTreeNodeFlags flags = 0);
    bool          TreeNodeEx(const u8* str_id, ImGuiTreeNodeFlags flags, const u8* fmt, ...) ;
    bool          TreeNodeEx(const rawptr ptr_id, ImGuiTreeNodeFlags flags, const u8* fmt, ...) ;
    bool          TreeNodeExV(const u8* str_id, ImGuiTreeNodeFlags flags, const u8* fmt, va_list args) ;
    bool          TreeNodeExV(const rawptr ptr_id, ImGuiTreeNodeFlags flags, const u8* fmt, va_list args) ;
    void          TreePush(const u8* str_id);                                       // ~ Indent()+PushID(). Already called by TreeNode() when returning true, but you can call TreePush/TreePop yourself if desired.
    void          TreePush(const rawptr ptr_id);                                       // "
    void          TreePop();                                                          // ~ Unindent()+PopID()
    f32         GetTreeNodeToLabelSpacing();                                        // horizontal distance preceding label when using TreeNode*() or Bullet() == (g.FontSize + style.FramePadding.x*2) for a regular unframed TreeNode
    bool          CollapsingHeader(const u8* label, ImGuiTreeNodeFlags flags = 0);  // if returning 'true' the header is open. doesn't indent nor push on ID stack. user doesn't have to call TreePop().
    bool          CollapsingHeader(const u8* label, bool* p_visible, ImGuiTreeNodeFlags flags = 0); // when 'p_visible != NULL': if '*p_visible==true' display an additional small close button on upper right of the header which will set the bool to false when clicked, if '*p_visible==false' don't display the header.
    void          SetNextItemOpen(bool is_open, ImGuiCond cond = 0);                  // set next TreeNode/CollapsingHeader open state.
    void          SetNextItemStorageID(ImGuiID storage_id);                           // set id to use for open/close storage (default to same as item id).

    // Widgets: Selectables
    // - A selectable highlights when hovered, and can display another color when selected.
    // - Neighbors selectable extend their highlight bounds in order to leave no gap between them. This is so a series of selected Selectable appear contiguous.
    bool          Selectable(const u8* label, bool selected = false, ImGuiSelectableFlags flags = 0, const ImVec2& size = ImVec2{0, 0}); // "bool selected" carry the selection state (read-only). Selectable() is clicked is returns true so you can modify your selection state. size.x==0.0: use remaining width, size.x>0.0: specify width. size.y==0.0: use label height, size.y>0.0: specify height
    bool          Selectable(const u8* label, bool* p_selected, ImGuiSelectableFlags flags = 0, const ImVec2& size = ImVec2{0, 0});      // "bool* p_selected" point to the selection state (read-write), as a convenient helper.

    // Multi-selection system for Selectable(), Checkbox(), TreeNode() functions [BETA]
    // - This enables standard multi-selection/range-selection idioms (CTRL+Mouse/Keyboard, SHIFT+Mouse/Keyboard, etc.) in a way that also allow a clipper to be used.
    // - ImGuiSelectionUserData is often used to store your item index within the current view (but may store something else).
    // - Read comments near ImGuiMultiSelectIO for instructions/details and see 'Demo->Widgets->Selection State & Multi-Select' for demo.
    // - TreeNode() is technically supported but... using this correctly is more complicated. You need some sort of linear/random access to your tree,
    //   which is suited to advanced trees setups already implementing filters and clipper. We will work simplifying the current demo.
    // - 'selection_size' and 'items_count' parameters are optional and used by a few features. If they are costly for you to compute, you may avoid them.
    ImGuiMultiSelectIO*   BeginMultiSelect(ImGuiMultiSelectFlags flags, i32 selection_size = -1, i32 items_count = -1);
    ImGuiMultiSelectIO*   EndMultiSelect();
    void                  SetNextItemSelectionUserData(ImGuiSelectionUserData selection_user_data);
    bool                  IsItemToggledSelection();                                   // Was the last item selection state toggled? Useful if you need the per-item information _before_ reaching EndMultiSelect(). We only returns toggle _event_ in order to handle clipping correctly.

    // Widgets: List Boxes
    // - This is essentially a thin wrapper to using BeginChild/EndChild with the ImGuiChildFlags_FrameStyle flag for stylistic changes + displaying a label.
    // - If you don't need a label you can probably simply use BeginChild() with the ImGuiChildFlags_FrameStyle flag for the same result.
    // - You can submit contents and manage your selection state however you want it, by creating e.g. Selectable() or any other items.
    // - The simplified/old ListBox() api are helpers over BeginListBox()/EndListBox() which are kept available for convenience purpose. This is analoguous to how Combos are created.
    // - Choose frame width:   size.x > 0.0f: custom  /  size.x < 0.0f or -FLT_MIN: right-align   /  size.x = 0.0f (default): use current ItemWidth
    // - Choose frame height:  size.y > 0.0f: custom  /  size.y < 0.0f or -FLT_MIN: bottom-align  /  size.y = 0.0f (default): arbitrary default height which can fit ~7 items
    bool          BeginListBox(const u8* label, const ImVec2& size = ImVec2{0, 0}); // open a framed scrolling region
    void          EndListBox();                                                       // only call EndListBox() if BeginListBox() returned true!
    bool          ListBox(const u8* label, i32* current_item, const u8* const items[], i32 items_count, i32 height_in_items = -1);
    bool          ListBox(const u8* label, i32* current_item, const u8* (*getter)(rawptr user_data, i32 idx), rawptr user_data, i32 items_count, i32 height_in_items = -1);

    // Widgets: Data Plotting
    // - Consider using ImPlot (https://github.com/epezent/implot) which is much better!
    void          PlotLines(const u8* label, const f32* values, i32 values_count, i32 values_offset = 0, const u8* overlay_text = nil, f32 scale_min = math.F32_MAX, f32 scale_max = math.F32_MAX, ImVec2 graph_size = ImVec2{0, 0}, i32 stride = size_of(f32));
    void          PlotLines(const u8* label, f32(*values_getter)(rawptr data, i32 idx), rawptr data, i32 values_count, i32 values_offset = 0, const u8* overlay_text = nil, f32 scale_min = math.F32_MAX, f32 scale_max = math.F32_MAX, ImVec2 graph_size = ImVec2{0, 0});
    void          PlotHistogram(const u8* label, const f32* values, i32 values_count, i32 values_offset = 0, const u8* overlay_text = nil, f32 scale_min = math.F32_MAX, f32 scale_max = math.F32_MAX, ImVec2 graph_size = ImVec2{0, 0}, i32 stride = size_of(f32));
    void          PlotHistogram(const u8* label, f32 (*values_getter)(rawptr data, i32 idx), rawptr data, i32 values_count, i32 values_offset = 0, const u8* overlay_text = nil, f32 scale_min = math.F32_MAX, f32 scale_max = math.F32_MAX, ImVec2 graph_size = ImVec2{0, 0});

    // Widgets: Value() Helpers.
    // - Those are merely shortcut to calling Text() with a format string. Output single value in "name: value" format (tip: freely declare more in your code to handle your types. you can add functions to the ImGui namespace)
    void          Value(const u8* prefix, bool b);
    void          Value(const u8* prefix, i32 v);
    void          Value(const u8* prefix, u32 v);
    void          Value(const u8* prefix, f32 v, const u8* float_format = nil);

    // Widgets: Menus
    // - Use BeginMenuBar() on a window ImGuiWindowFlags_MenuBar to append to its menu bar.
    // - Use BeginMainMenuBar() to create a menu bar at the top of the screen and append to it.
    // - Use BeginMenu() to create a menu. You can call BeginMenu() multiple time with the same identifier to append more items to it.
    // - Not that MenuItem() keyboardshortcuts are displayed as a convenience but _not processed_ by Dear ImGui at the moment.
    bool          BeginMenuBar();                                                     // append to menu-bar of current window (requires ImGuiWindowFlags_MenuBar flag set on parent window).
    void          EndMenuBar();                                                       // only call EndMenuBar() if BeginMenuBar() returns true!
    bool          BeginMainMenuBar();                                                 // create and append to a full screen menu-bar.
    void          EndMainMenuBar();                                                   // only call EndMainMenuBar() if BeginMainMenuBar() returns true!
    bool          BeginMenu(const u8* label, bool enabled = true);                  // create a sub-menu entry. only call EndMenu() if this returns true!
    void          EndMenu();                                                          // only call EndMenu() if BeginMenu() returns true!
    bool          MenuItem(const u8* label, const u8* shortcut = nil, bool selected = false, bool enabled = true);  // return true when activated.
    bool          MenuItem(const u8* label, const u8* shortcut, bool* p_selected, bool enabled = true);              // return true when activated + toggle (*p_selected) if p_selected != NULL

    // Tooltips
    // - Tooltips are windows following the mouse. They do not take focus away.
    // - A tooltip window can contain items of any types.
    // - SetTooltip() is more or less a shortcut for the 'if (BeginTooltip()) { Text(...); EndTooltip(); }' idiom (with a subtlety that it discard any previously submitted tooltip)
    bool          BeginTooltip();                                                     // begin/append a tooltip window.
    void          EndTooltip();                                                       // only call EndTooltip() if BeginTooltip()/BeginItemTooltip() returns true!
    void          SetTooltip(const u8* fmt, ...) ;                     // set a text-only tooltip. Often used after a ImGui::IsItemHovered() check. Override any previous call to SetTooltip().
    void          SetTooltipV(const u8* fmt, va_list args) ;

    // Tooltips: helpers for showing a tooltip when hovering an item
    // - BeginItemTooltip() is a shortcut for the 'if (IsItemHovered(ImGuiHoveredFlags_ForTooltip) && BeginTooltip())' idiom.
    // - SetItemTooltip() is a shortcut for the 'if (IsItemHovered(ImGuiHoveredFlags_ForTooltip)) { SetTooltip(...); }' idiom.
    // - Where 'ImGuiHoveredFlags_ForTooltip' itself is a shortcut to use 'style.HoverFlagsForTooltipMouse' or 'style.HoverFlagsForTooltipNav' depending on active input type. For mouse it defaults to 'ImGuiHoveredFlags_Stationary | ImGuiHoveredFlags_DelayShort'.
    bool          BeginItemTooltip();                                                 // begin/append a tooltip window if preceding item was hovered.
    void          SetItemTooltip(const u8* fmt, ...) ;                 // set a text-only tooltip if preceding item was hovered. override any previous call to SetTooltip().
    void          SetItemTooltipV(const u8* fmt, va_list args) ;

    // Popups, Modals
    //  - They block normal mouse hovering detection (and therefore most mouse interactions) behind them.
    //  - If not modal: they can be closed by clicking anywhere outside them, or by pressing ESCAPE.
    //  - Their visibility state (~bool) is held internally instead of being held by the programmer as we are used to with regular Begin*() calls.
    //  - The 3 properties above are related: we need to retain popup visibility state in the library because popups may be closed as any time.
    //  - You can bypass the hovering restriction by using ImGuiHoveredFlags_AllowWhenBlockedByPopup when calling IsItemHovered() or IsWindowHovered().
    //  - IMPORTANT: Popup identifiers are relative to the current ID stack, so OpenPopup and BeginPopup generally needs to be at the same level of the stack.
    //    This is sometimes leading to confusing mistakes. May rework this in the future.
    //  - BeginPopup(): query popup state, if open start appending into the window. Call EndPopup() afterwards if returned true. ImGuiWindowFlags are forwarded to the window.
    //  - BeginPopupModal(): block every interaction behind the window, cannot be closed by user, add a dimming background, has a title bar.
    bool          BeginPopup(const u8* str_id, ImGuiWindowFlags flags = 0);                         // return true if the popup is open, and you can start outputting to it.
    bool          BeginPopupModal(const u8* name, bool* p_open = nil, ImGuiWindowFlags flags = 0); // return true if the modal is open, and you can start outputting to it.
    void          EndPopup();                                                                         // only call EndPopup() if BeginPopupXXX() returns true!

    // Popups: open/close functions
    //  - OpenPopup(): set popup state to open. ImGuiPopupFlags are available for opening options.
    //  - If not modal: they can be closed by clicking anywhere outside them, or by pressing ESCAPE.
    //  - CloseCurrentPopup(): use inside the BeginPopup()/EndPopup() scope to close manually.
    //  - CloseCurrentPopup() is called by default by Selectable()/MenuItem() when activated (FIXME: need some options).
    //  - Use ImGuiPopupFlags_NoOpenOverExistingPopup to avoid opening a popup if there's already one at the same level. This is equivalent to e.g. testing for !IsAnyPopupOpen() prior to OpenPopup().
    //  - Use IsWindowAppearing() after BeginPopup() to tell if a window just opened.
    //  - IMPORTANT: Notice that for OpenPopupOnItemClick() we exceptionally default flags to 1 (== ImGuiPopupFlags_MouseButtonRight) for backward compatibility with older API taking 'int mouse_button = 1' parameter
    void          OpenPopup(const u8* str_id, ImGuiPopupFlags popup_flags = 0);                     // call to mark popup as open (don't call every frame!).
    void          OpenPopup(ImGuiID id, ImGuiPopupFlags popup_flags = 0);                             // id overload to facilitate calling from nested stacks
    void          OpenPopupOnItemClick(const u8* str_id = nil, ImGuiPopupFlags popup_flags = 1);   // helper to open popup when clicked on last item. Default to ImGuiPopupFlags_MouseButtonRight == 1. (note: actually triggers on the mouse _released_ event to be consistent with popup behaviors)
    void          CloseCurrentPopup();                                                                // manually close the popup we have begin-ed into.

    // Popups: open+begin combined functions helpers
    //  - Helpers to do OpenPopup+BeginPopup where the Open action is triggered by e.g. hovering an item and right-clicking.
    //  - They are convenient to easily create context menus, hence the name.
    //  - IMPORTANT: Notice that BeginPopupContextXXX takes ImGuiPopupFlags just like OpenPopup() and unlike BeginPopup(). For full consistency, we may add ImGuiWindowFlags to the BeginPopupContextXXX functions in the future.
    //  - IMPORTANT: Notice that we exceptionally default their flags to 1 (== ImGuiPopupFlags_MouseButtonRight) for backward compatibility with older API taking 'int mouse_button = 1' parameter, so if you add other flags remember to re-add the ImGuiPopupFlags_MouseButtonRight.
    bool          BeginPopupContextItem(const u8* str_id = nil, ImGuiPopupFlags popup_flags = 1);  // open+begin popup when clicked on last item. Use str_id==NULL to associate the popup to previous item. If you want to use that on a non-interactive item such as Text() you need to pass in an explicit ID here. read comments in .cpp!
    bool          BeginPopupContextWindow(const u8* str_id = nil, ImGuiPopupFlags popup_flags = 1);// open+begin popup when clicked on current window.
    bool          BeginPopupContextVoid(const u8* str_id = nil, ImGuiPopupFlags popup_flags = 1);  // open+begin popup when clicked in void (where there are no windows).

    // Popups: query functions
    //  - IsPopupOpen(): return true if the popup is open at the current BeginPopup() level of the popup stack.
    //  - IsPopupOpen() with ImGuiPopupFlags_AnyPopupId: return true if any popup is open at the current BeginPopup() level of the popup stack.
    //  - IsPopupOpen() with ImGuiPopupFlags_AnyPopupId + ImGuiPopupFlags_AnyPopupLevel: return true if any popup is open.
    bool          IsPopupOpen(const u8* str_id, ImGuiPopupFlags flags = 0);                         // return true if the popup is open.

    // Tables
    // - Full-featured replacement for old Columns API.
    // - See Demo->Tables for demo code. See top of imgui_tables.cpp for general commentary.
    // - See ImGuiTableFlags_ and ImGuiTableColumnFlags_ enums for a description of available flags.
    // The typical call flow is:
    // - 1. Call BeginTable(), early out if returning false.
    // - 2. Optionally call TableSetupColumn() to submit column name/flags/defaults.
    // - 3. Optionally call TableSetupScrollFreeze() to request scroll freezing of columns/rows.
    // - 4. Optionally call TableHeadersRow() to submit a header row. Names are pulled from TableSetupColumn() data.
    // - 5. Populate contents:
    //    - In most situations you can use TableNextRow() + TableSetColumnIndex(N) to start appending into a column.
    //    - If you are using tables as a sort of grid, where every column is holding the same type of contents,
    //      you may prefer using TableNextColumn() instead of TableNextRow() + TableSetColumnIndex().
    //      TableNextColumn() will automatically wrap-around into the next row if needed.
    //    - IMPORTANT: Comparatively to the old Columns() API, we need to call TableNextColumn() for the first column!
    //    - Summary of possible call flow:
    //        - TableNextRow() -> TableSetColumnIndex(0) -> Text("Hello 0") -> TableSetColumnIndex(1) -> Text("Hello 1")  // OK
    //        - TableNextRow() -> TableNextColumn()      -> Text("Hello 0") -> TableNextColumn()      -> Text("Hello 1")  // OK
    //        -                   TableNextColumn()      -> Text("Hello 0") -> TableNextColumn()      -> Text("Hello 1")  // OK: TableNextColumn() automatically gets to next row!
    //        - TableNextRow()                           -> Text("Hello 0")                                               // Not OK! Missing TableSetColumnIndex() or TableNextColumn()! Text will not appear!
    // - 5. Call EndTable()
    bool          BeginTable(const u8* str_id, i32 columns, ImGuiTableFlags flags = 0, const ImVec2& outer_size = ImVec2{0.0, 0.0}, f32 inner_width = 0.0);
    void          EndTable();                                         // only call EndTable() if BeginTable() returns true!
    void          TableNextRow(ImGuiTableRowFlags row_flags = 0, f32 min_row_height = 0.0); // append into the first cell of a new row.
    bool          TableNextColumn();                                  // append into the next column (or first column of next row if currently in last column). Return true when column is visible.
    bool          TableSetColumnIndex(i32 column_n);                  // append into the specified column. Return true when column is visible.

    // Tables: Headers & Columns declaration
    // - Use TableSetupColumn() to specify label, resizing policy, default width/weight, id, various other flags etc.
    // - Use TableHeadersRow() to create a header row and automatically submit a TableHeader() for each column.
    //   Headers are required to perform: reordering, sorting, and opening the context menu.
    //   The context menu can also be made available in columns body using ImGuiTableFlags_ContextMenuInBody.
    // - You may manually submit headers using TableNextRow() + TableHeader() calls, but this is only useful in
    //   some advanced use cases (e.g. adding custom widgets in header row).
    // - Use TableSetupScrollFreeze() to lock columns/rows so they stay visible when scrolled.
    void          TableSetupColumn(const u8* label, ImGuiTableColumnFlags flags = 0, f32 init_width_or_weight = 0.0, ImGuiID user_id = 0);
    void          TableSetupScrollFreeze(i32 cols, i32 rows);         // lock columns/rows so they stay visible when scrolled.
    void          TableHeader(const u8* label);                     // submit one header cell manually (rarely used)
    void          TableHeadersRow();                                  // submit a row with headers cells based on data provided to TableSetupColumn() + submit context menu
    void          TableAngledHeadersRow();                            // submit a row with angled headers for every column with the ImGuiTableColumnFlags_AngledHeader flag. MUST BE FIRST ROW.

    // Tables: Sorting & Miscellaneous functions
    // - Sorting: call TableGetSortSpecs() to retrieve latest sort specs for the table. NULL when not sorting.
    //   When 'sort_specs->SpecsDirty == true' you should sort your data. It will be true when sorting specs have
    //   changed since last call, or the first time. Make sure to set 'SpecsDirty = false' after sorting,
    //   else you may wastefully sort your data every frame!
    // - Functions args 'int column_n' treat the default value of -1 as the same as passing the current column index.
    ImGuiTableSortSpecs*  TableGetSortSpecs();                        // get latest sort specs for the table (NULL if not sorting).  Lifetime: don't hold on this pointer over multiple frames or past any subsequent call to BeginTable().
    i32                   TableGetColumnCount();                      // return number of columns (value passed to BeginTable)
    i32                   TableGetColumnIndex();                      // return current column index.
    i32                   TableGetRowIndex();                         // return current row index.
    const u8*           TableGetColumnName(i32 column_n = -1);      // return "" if column didn't have a name declared by TableSetupColumn(). Pass -1 to use current column.
    TableGetColumnFlags := ImGuiTableColumnFlags(i32 column_n = -1);     // return column flags so you can query their Enabled/Visible/Sorted/Hovered status flags. Pass -1 to use current column.
    void                  TableSetColumnEnabled(i32 column_n, bool v);// change user accessible enabled/disabled state of a column. Set to false to hide the column. User can use the context menu to change this themselves (right-click in headers, or right-click in columns body with ImGuiTableFlags_ContextMenuInBody)
    i32                   TableGetHoveredColumn();                    // return hovered column. return -1 when table is not hovered. return columns_count if the unused space at the right of visible columns is hovered. Can also use (TableGetColumnFlags() & ImGuiTableColumnFlags_IsHovered) instead.
    void                  TableSetBgColor(ImGuiTableBgTarget target, u32 color, i32 column_n = -1);  // change the color of a cell, row, or column. See ImGuiTableBgTarget_ flags for details.

    // Legacy Columns API (prefer using Tables!)
    // - You can also use SameLine(pos_x) to mimic simplified columns.
    void          Columns(i32 count = 1, const u8* id = nil, bool borders = true);
    void          NextColumn();                                                       // next column, defaults to current row or next row if the current row is finished
    i32           GetColumnIndex();                                                   // get current column index
    f32         GetColumnWidth(i32 column_index = -1);                              // get column width (in pixels). pass -1 to use current column
    void          SetColumnWidth(i32 column_index, f32 width);                      // set column width (in pixels). pass -1 to use current column
    f32         GetColumnOffset(i32 column_index = -1);                             // get position of column line (in pixels, from the left side of the contents region). pass -1 to use current column, otherwise 0..GetColumnsCount() inclusive. column 0 is typically 0.0f
    void          SetColumnOffset(i32 column_index, f32 offset_x);                  // set position of column line (in pixels, from the left side of the contents region). pass -1 to use current column
    i32           GetColumnsCount();

    // Tab Bars, Tabs
    // - Note: Tabs are automatically created by the docking system (when in 'docking' branch). Use this to create tab bars/tabs yourself.
    bool          BeginTabBar(const u8* str_id, ImGuiTabBarFlags flags = 0);        // create and append into a TabBar
    void          EndTabBar();                                                        // only call EndTabBar() if BeginTabBar() returns true!
    bool          BeginTabItem(const u8* label, bool* p_open = nil, ImGuiTabItemFlags flags = 0); // create a Tab. Returns true if the Tab is selected.
    void          EndTabItem();                                                       // only call EndTabItem() if BeginTabItem() returns true!
    bool          TabItemButton(const u8* label, ImGuiTabItemFlags flags = 0);      // create a Tab behaving like a button. return true when clicked. cannot be selected in the tab bar.
    void          SetTabItemClosed(const u8* tab_or_docked_window_label);           // notify TabBar or Docking system of a closed tab/window ahead (useful to reduce visual flicker on reorderable tab bars). For tab-bar: call after BeginTabBar() and before Tab submissions. Otherwise call with a window name.

    // Docking
    // [BETA API] Enable with io.ConfigFlags |= ImGuiConfigFlags_DockingEnable.
    // Note: You can use most Docking facilities without calling any API. You DO NOT need to call DockSpace() to use Docking!
    // - Drag from window title bar or their tab to dock/undock. Hold SHIFT to disable docking.
    // - Drag from window menu button (upper-left button) to undock an entire node (all windows).
    // - When io.ConfigDockingWithShift == true, you instead need to hold SHIFT to enable docking.
    // About dockspaces:
    // - Use DockSpaceOverViewport() to create a window covering the screen or a specific viewport + a dockspace inside it.
    //   This is often used with ImGuiDockNodeFlags_PassthruCentralNode to make it transparent.
    // - Use DockSpace() to create an explicit dock node _within_ an existing window. See Docking demo for details.
    // - Important: Dockspaces need to be submitted _before_ any window they can host. Submit it early in your frame!
    // - Important: Dockspaces need to be kept alive if hidden, otherwise windows docked into it will be undocked.
    //   e.g. if you have multiple tabs with a dockspace inside each tab: submit the non-visible dockspaces with ImGuiDockNodeFlags_KeepAliveOnly.
    DockSpace := ImGuiID(ImGuiID dockspace_id, const ImVec2& size = ImVec2{0, 0}, ImGuiDockNodeFlags flags = 0, const ImGuiWindowClass* window_class = nil);
    DockSpaceOverViewport := ImGuiID(ImGuiID dockspace_id = 0, const ImGuiViewport* viewport = nil, ImGuiDockNodeFlags flags = 0, const ImGuiWindowClass* window_class = nil);
    void          SetNextWindowDockID(ImGuiID dock_id, ImGuiCond cond = 0);           // set next window dock id
    void          SetNextWindowClass(const ImGuiWindowClass* window_class);           // set next window class (control docking compatibility + provide hints to platform backend via custom viewport flags and platform parent/child relationship)
    GetWindowDockID := ImGuiID();
    bool          IsWindowDocked();                                                   // is current window docked into another window?

    // Logging/Capture
    // - All text output from the interface can be captured into tty/file/clipboard. By default, tree nodes are automatically opened during logging.
    void          LogToTTY(i32 auto_open_depth = -1);                                 // start logging to tty (stdout)
    void          LogToFile(i32 auto_open_depth = -1, const u8* filename = nil);   // start logging to file
    void          LogToClipboard(i32 auto_open_depth = -1);                           // start logging to OS clipboard
    void          LogFinish();                                                        // stop logging (close file, etc.)
    void          LogButtons();                                                       // helper to display buttons for logging to tty/file/clipboard
    void          LogText(const u8* fmt, ...) ;                        // pass text data straight to log (without being displayed)
    void          LogTextV(const u8* fmt, va_list args) ;

    // Drag and Drop
    // - On source items, call BeginDragDropSource(), if it returns true also call SetDragDropPayload() + EndDragDropSource().
    // - On target candidates, call BeginDragDropTarget(), if it returns true also call AcceptDragDropPayload() + EndDragDropTarget().
    // - If you stop calling BeginDragDropSource() the payload is preserved however it won't have a preview tooltip (we currently display a fallback "..." tooltip, see #1725)
    // - An item can be both drag source and drop target.
    bool          BeginDragDropSource(ImGuiDragDropFlags flags = 0);                                      // call after submitting an item which may be dragged. when this return true, you can call SetDragDropPayload() + EndDragDropSource()
    bool          SetDragDropPayload(const u8* type, const rawptr data, int sz, ImGuiCond cond = 0);  // type is a user defined string of maximum 32 characters. Strings starting with '_' are reserved for dear imgui internal types. Data is copied and held by imgui. Return true when payload has been accepted.
    void          EndDragDropSource();                                                                    // only call EndDragDropSource() if BeginDragDropSource() returns true!
    bool                  BeginDragDropTarget();                                                          // call after submitting an item that may receive a payload. If this returns true, you can call AcceptDragDropPayload() + EndDragDropTarget()
    const ImGuiPayload*   AcceptDragDropPayload(const u8* type, ImGuiDragDropFlags flags = 0);          // accept contents of a given type. If ImGuiDragDropFlags_AcceptBeforeDelivery is set you can peek into the payload before the mouse button is released.
    void                  EndDragDropTarget();                                                            // only call EndDragDropTarget() if BeginDragDropTarget() returns true!
    const ImGuiPayload*   GetDragDropPayload();                                                           // peek directly into the current payload from anywhere. returns NULL when drag and drop is finished or inactive. use ImGuiPayload::IsDataType() to test for the payload type.

    // Disabling [BETA API]
    // - Disable all user interactions and dim items visuals (applying style.DisabledAlpha over current colors)
    // - Those can be nested but it cannot be used to enable an already disabled section (a single BeginDisabled(true) in the stack is enough to keep everything disabled)
    // - Tooltips windows by exception are opted out of disabling.
    // - BeginDisabled(false)/EndDisabled() essentially does nothing but is provided to facilitate use of boolean expressions (as a micro-optimization: if you have tens of thousands of BeginDisabled(false)/EndDisabled() pairs, you might want to reformulate your code to avoid making those calls)
    void          BeginDisabled(bool disabled = true);
    void          EndDisabled();

    // Clipping
    // - Mouse hovering is affected by ImGui::PushClipRect() calls, unlike direct calls to ImDrawList::PushClipRect() which are render only.
    void          PushClipRect(const ImVec2& clip_rect_min, const ImVec2& clip_rect_max, bool intersect_with_current_clip_rect);
    void          PopClipRect();

    // Focus, Activation
    void          SetItemDefaultFocus();                                              // make last item the default focused item of of a newly appearing window.
    void          SetKeyboardFocusHere(i32 offset = 0);                               // focus keyboard on the next widget. Use positive 'offset' to access sub components of a multiple component widget. Use -1 to access previous widget.

    // Keyboard/Gamepad Navigation
    void          SetNavCursorVisible(bool visible);                                  // alter visibility of keyboard/gamepad cursor. by default: show when using an arrow key, hide when clicking with mouse.

    // Overlapping mode
    void          SetNextItemAllowOverlap();                                          // allow next item to be overlapped by a subsequent item. Useful with invisible buttons, selectable, treenode covering an area where subsequent items may need to be added. Note that both Selectable() and TreeNode() have dedicated flags doing this.

    // Item/Widgets Utilities and Query Functions
    // - Most of the functions are referring to the previous Item that has been submitted.
    // - See Demo Window under "Widgets->Querying Status" for an interactive visualization of most of those functions.
    bool          IsItemHovered(ImGuiHoveredFlags flags = 0);                         // is the last item hovered? (and usable, aka not blocked by a popup, etc.). See ImGuiHoveredFlags for more options.
    bool          IsItemActive();                                                     // is the last item active? (e.g. button being held, text field being edited. This will continuously return true while holding mouse button on an item. Items that don't interact will always return false)
    bool          IsItemFocused();                                                    // is the last item focused for keyboard/gamepad navigation?
    bool          IsItemClicked(ImGuiMouseButton mouse_button = 0);                   // is the last item hovered and mouse clicked on? (**)  == IsMouseClicked(mouse_button) && IsItemHovered()Important. (**) this is NOT equivalent to the behavior of e.g. Button(). Read comments in function definition.
    bool          IsItemVisible();                                                    // is the last item visible? (items may be out of sight because of clipping/scrolling)
    bool          IsItemEdited();                                                     // did the last item modify its underlying value this frame? or was pressed? This is generally the same as the "bool" return value of many widgets.
    bool          IsItemActivated();                                                  // was the last item just made active (item was previously inactive).
    bool          IsItemDeactivated();                                                // was the last item just made inactive (item was previously active). Useful for Undo/Redo patterns with widgets that require continuous editing.
    bool          IsItemDeactivatedAfterEdit();                                       // was the last item just made inactive and made a value change when it was active? (e.g. Slider/Drag moved). Useful for Undo/Redo patterns with widgets that require continuous editing. Note that you may get false positives (some widgets such as Combo()/ListBox()/Selectable() will return true even when clicking an already selected item).
    bool          IsItemToggledOpen();                                                // was the last item open state toggled? set by TreeNode().
    bool          IsAnyItemHovered();                                                 // is any item hovered?
    bool          IsAnyItemActive();                                                  // is any item active?
    bool          IsAnyItemFocused();                                                 // is any item focused?
    GetItemID := ImGuiID();                                                        // get ID of last item (~~ often same ImGui::GetID(label) beforehand)
    GetItemRectMin := ImVec2();                                                   // get upper-left bounding rectangle of the last item (screen space)
    GetItemRectMax := ImVec2();                                                   // get lower-right bounding rectangle of the last item (screen space)
    GetItemRectSize := ImVec2();                                                  // get size of last item

    // Viewports
    // - Currently represents the Platform Window created by the application which is hosting our Dear ImGui windows.
    // - In 'docking' branch with multi-viewport enabled, we extend this concept to have multiple active viewports.
    // - In the future we will extend this concept further to also represent Platform Monitor and support a "no main platform window" operation mode.
    ImGuiViewport* GetMainViewport();                                                 // return primary/default viewport. This can never be NULL.

    // Background/Foreground Draw Lists
    ImDrawList*   GetBackgroundDrawList(ImGuiViewport* viewport = nil);              // get background draw list for the given viewport or viewport associated to the current window. this draw list will be the first rendering one. Useful to quickly draw shapes/text behind dear imgui contents.
    ImDrawList*   GetForegroundDrawList(ImGuiViewport* viewport = nil);              // get foreground draw list for the given viewport or viewport associated to the current window. this draw list will be the top-most rendered one. Useful to quickly draw shapes/text over dear imgui contents.

    // Miscellaneous Utilities
    bool          IsRectVisible(const ImVec2& size);                                  // test if rectangle (of given size, starting from cursor position) is visible / not clipped.
    bool          IsRectVisible(const ImVec2& rect_min, const ImVec2& rect_max);      // test if rectangle (in screen space) is visible / not clipped. to perform coarse clipping on user's side.
    f64        GetTime();                                                          // get global imgui time. incremented by io.DeltaTime every frame.
    i32           GetFrameCount();                                                    // get global imgui frame count. incremented by 1 every frame.
    ImDrawListSharedData* GetDrawListSharedData();                                    // you may use this when creating your own ImDrawList instances.
    const u8*   GetStyleColorName(ImGuiCol idx);                                    // get a string corresponding to the enum value (for display, saving, etc.).
    void          SetStateStorage(ImGuiStorage* storage);                             // replace current window storage with our own (if you want to manipulate it yourself, typically clear subsection of it)
    ImGuiStorage* GetStateStorage();

    // Text Utilities
    CalcTextSize := CalcTe(const u8* text, const u8* text_end = nil, bool hide_text_after_double_hash = false, f32 wrap_width = -1.0);

    // Color Utilities
    ColorConvertU32ToFloat4 := ImVec4{u32 in};
    u32         ColorConvertFloat4ToU32(const ImVec4& in);
    void          ColorConvertRGBtoHSV(f32 r, f32 g, f32 b, f32& out_h, f32& out_s, f32& out_v);
    void          ColorConvertHSVtoRGB(f32 h, f32 s, f32 v, f32& out_r, f32& out_g, f32& out_b);

    // Inputs Utilities: Keyboard/Mouse/Gamepad
    // - the ImGuiKey enum contains all possible keyboard, mouse and gamepad inputs (e.g. ImGuiKey_A, ImGuiKey_MouseLeft, ImGuiKey_GamepadDpadUp...).
    // - (legacy: before v1.87, we used ImGuiKey to carry native/user indices as defined by each backends. This was obsoleted in 1.87 (2022-02) and completely removed in 1.91.5 (2024-11). See https://github.com/ocornut/imgui/issues/4921)
    // - (legacy: any use of ImGuiKey will assert when key < 512 to detect passing legacy native/user indices)
    bool          IsKeyDown(ImGuiKey key);                                            // is key being held.
    bool          IsKeyPressed(ImGuiKey key, bool repeat = true);                     // was key pressed (went from !Down to Down)? if repeat=true, uses io.KeyRepeatDelay / KeyRepeatRate
    bool          IsKeyReleased(ImGuiKey key);                                        // was key released (went from Down to !Down)?
    bool          IsKeyChordPressed(ImGuiKeyChord key_chord);                         // was key chord (mods + key) pressed, e.g. you can pass 'ImGuiMod_Ctrl | ImGuiKey_S' as a key-chord. This doesn't do any routing or focus check, please consider using Shortcut() function instead.
    i32           GetKeyPressedAmount(ImGuiKey key, f32 repeat_delay, f32 rate);  // uses provided repeat rate/delay. return a count, most often 0 or 1 but might be >1 if RepeatRate is small enough that DeltaTime > RepeatRate
    const u8*   GetKeyName(ImGuiKey key);                                           // [DEBUG] returns English name of the key. Those names a provided for debugging purpose and are not meant to be saved persistently not compared.
    void          SetNextFrameWantCaptureKeyboard(bool want_capture_keyboard);        // Override io.WantCaptureKeyboard flag next frame (said flag is left for your application to handle, typically when true it instructs your app to ignore inputs). e.g. force capture keyboard when your widget is being hovered. This is equivalent to setting "io.WantCaptureKeyboard = want_capture_keyboard"; after the next NewFrame() call.

    // Inputs Utilities: Shortcut Testing & Routing [BETA]
    // - ImGuiKeyChord = a ImGuiKey + optional ImGuiMod_Alt/ImGuiMod_Ctrl/ImGuiMod_Shift/ImGuiMod_Super.
    //       ImGuiKey_C                          // Accepted by functions taking ImGuiKey or ImGuiKeyChord arguments)
    //       ImGuiMod_Ctrl | ImGuiKey_C          // Accepted by functions taking ImGuiKeyChord arguments)
    //   only ImGuiMod_XXX values are legal to combine with an ImGuiKey. You CANNOT combine two ImGuiKey values.
    // - The general idea is that several callers may register interest in a shortcut, and only one owner gets it.
    //      Parent   -> call Shortcut(Ctrl+S)    // When Parent is focused, Parent gets the shortcut.
    //        Child1 -> call Shortcut(Ctrl+S)    // When Child1 is focused, Child1 gets the shortcut (Child1 overrides Parent shortcuts)
    //        Child2 -> no call                  // When Child2 is focused, Parent gets the shortcut.
    //   The whole system is order independent, so if Child1 makes its calls before Parent, results will be identical.
    //   This is an important property as it facilitate working with foreign code or larger codebase.
    // - To understand the difference:
    //   - IsKeyChordPressed() compares mods and call IsKeyPressed() -> function has no side-effect.
    //   - Shortcut() submits a route, routes are resolved, if it currently can be routed it calls IsKeyChordPressed() -> function has (desirable) side-effects as it can prevents another call from getting the route.
    // - Visualize registered routes in 'Metrics/Debugger->Inputs'.
    bool          Shortcut(ImGuiKeyChord key_chord, ImGuiInputFlags flags = 0);
    void          SetNextItemShortcut(ImGuiKeyChord key_chord, ImGuiInputFlags flags = 0);

    // Inputs Utilities: Key/Input Ownership [BETA]
    // - One common use case would be to allow your items to disable standard inputs behaviors such
    //   as Tab or Alt key handling, Mouse Wheel scrolling, etc.
    //   e.g. Button(...); SetItemKeyOwner(ImGuiKey_MouseWheelY); to make hovering/activating a button disable wheel for scrolling.
    // - Reminder ImGuiKey enum include access to mouse buttons and gamepad, so key ownership can apply to them.
    // - Many related features are still in imgui_internal.h. For instance, most IsKeyXXX()/IsMouseXXX() functions have an owner-id-aware version.
    void          SetItemKeyOwner(ImGuiKey key);                                      // Set key owner to last item ID if it is hovered or active. Equivalent to 'if (IsItemHovered() || IsItemActive()) { SetKeyOwner(key, GetItemID());'.

    // Inputs Utilities: Mouse
    // - To refer to a mouse button, you may use named enums in your code e.g. ImGuiMouseButton_Left, ImGuiMouseButton_Right.
    // - You can also use regular integer: it is forever guaranteed that 0=Left, 1=Right, 2=Middle.
    // - Dragging operations are only reported after mouse has moved a certain distance away from the initial clicking position (see 'lock_threshold' and 'io.MouseDraggingThreshold')
    bool          IsMouseDown(ImGuiMouseButton button);                               // is mouse button held?
    bool          IsMouseClicked(ImGuiMouseButton button, bool repeat = false);       // did mouse button clicked? (went from !Down to Down). Same as GetMouseClickedCount() == 1.
    bool          IsMouseReleased(ImGuiMouseButton button);                           // did mouse button released? (went from Down to !Down)
    bool          IsMouseDoubleClicked(ImGuiMouseButton button);                      // did mouse button double-clicked? Same as GetMouseClickedCount() == 2. (note that a double-click will also report IsMouseClicked() == true)
    i32           GetMouseClickedCount(ImGuiMouseButton button);                      // return the number of successive mouse-clicks at the time where a click happen (otherwise 0).
    bool          IsMouseHoveringRect(const ImVec2& r_min, const ImVec2& r_max, bool clip = true);// is mouse hovering given bounding rect (in screen space). clipped by current clipping settings, but disregarding of other consideration of focus/window ordering/popup-block.
    bool          IsMousePosValid(const ImVec2* mouse_pos = nil);                    // by convention we use (-FLT_MAX,-FLT_MAX) to denote that there is no mouse available
    bool          IsAnyMouseDown();                                                   // [WILL OBSOLETE] is any mouse button held? This was designed for backends, but prefer having backend maintain a mask of held mouse buttons, because upcoming input queue system will make this invalid.
    GetMousePos := ImVec2();                                                      // shortcut to ImGui::GetIO().MousePos provided by user, to be consistent with other calls
    GetMousePosOnOpeningCurrentPopup := ImVec2();                                 // retrieve mouse position at the time of opening popup we have BeginPopup() into (helper to avoid user backing that value themselves)
    bool          IsMouseDragging(ImGuiMouseButton button, f32 lock_threshold = -1.0);         // is mouse dragging? (uses io.MouseDraggingThreshold if lock_threshold < 0.0f)
    GetMouseDragDelta := GetMou(ImGuiMouseButton button = 0, f32 lock_threshold = -1.0);   // return the delta from the initial clicking position while the mouse button is pressed or was just released. This is locked and return 0.0f until the mouse moves past a distance threshold at least once (uses io.MouseDraggingThreshold if lock_threshold < 0.0f)
    void          ResetMouseDragDelta(ImGuiMouseButton button = 0);                   //
    GetMouseCursor := ImGuiMouseCursor();                                                // get desired mouse cursor shape. Important: reset in ImGui::NewFrame(), this is updated during the frame. valid before Render(). If you use software rendering by setting io.MouseDrawCursor ImGui will render those for you
    void          SetMouseCursor(ImGuiMouseCursor cursor_type);                       // set desired mouse cursor shape
    void          SetNextFrameWantCaptureMouse(bool want_capture_mouse);              // Override io.WantCaptureMouse flag next frame (said flag is left for your application to handle, typical when true it instucts your app to ignore inputs). This is equivalent to setting "io.WantCaptureMouse = want_capture_mouse;" after the next NewFrame() call.

    // Clipboard Utilities
    // - Also see the LogToClipboard() function to capture GUI into clipboard, or easily output text data to the clipboard.
    const u8*   GetClipboardText();
    void          SetClipboardText(const u8* text);

    // Settings/.Ini Utilities
    // - The disk functions are automatically called if io.IniFilename != NULL (default is "imgui.ini").
    // - Set io.IniFilename to NULL to load/save manually. Read io.WantSaveIniSettings description about handling .ini saving manually.
    // - Important: default value "imgui.ini" is relative to current working dir! Most apps will want to lock this to an absolute path (e.g. same path as executables).
    void          LoadIniSettingsFromDisk(const u8* ini_filename);                  // call after CreateContext() and before the first call to NewFrame(). NewFrame() automatically calls LoadIniSettingsFromDisk(io.IniFilename).
    void          LoadIniSettingsFromMemory(const u8* ini_data, int ini_size=0); // call after CreateContext() and before the first call to NewFrame() to provide .ini data from your own data source.
    void          SaveIniSettingsToDisk(const u8* ini_filename);                    // this is automatically called (if io.IniFilename is not empty) a few seconds after any modification that should be reflected in the .ini file (and also by DestroyContext).
    const u8*   SaveIniSettingsToMemory(int* out_ini_size = nil);               // return a zero-terminated string with the .ini data which you can save by your own mean. call when io.WantSaveIniSettings is set, then save data by your own mean and clear io.WantSaveIniSettings.

    // Debug Utilities
    // - Your main debugging friend is the ShowMetricsWindow() function, which is also accessible from Demo->Tools->Metrics Debugger
    void          DebugTextEncoding(const u8* text);
    void          DebugFlashStyleColor(ImGuiCol idx);
    void          DebugStartItemPicker();
    bool          DebugCheckVersionAndDataLayout(const u8* version_str, int sz_io, int sz_style, int sz_vec2, int sz_vec4, int sz_drawvert, int sz_drawidx); // This is called by IMGUI_CHECKVERSION() macro.
when !(IMGUI_DISABLE_DEBUG_TOOLS) {
    void          DebugLog(const u8* fmt, ...)           ; // Call via IMGUI_DEBUG_LOG() for maximum stripping in caller code!
    void          DebugLogV(const u8* fmt, va_list args) ;
}

    // Memory Allocators
    // - Those functions are not reliant on the current context.
    // - DLL users: heaps and globals are not shared across DLL boundaries! You will need to call SetCurrentContext() + SetAllocatorFunctions()
    //   for each static/DLL boundary you are calling from. Read "Context and Memory Allocators" section of imgui.cpp for more details.
    void          SetAllocatorFunctions(ImGuiMemAllocFunc alloc_func, ImGuiMemFreeFunc free_func, rawptr user_data = nil);
    void          GetAllocatorFunctions(ImGuiMemAllocFunc* p_alloc_func, ImGuiMemFreeFunc* p_free_func, rawptr* p_user_data);
    rawptr         MemAlloc(int size);
    void          MemFree(rawptr ptr);

    // (Optional) Platform/OS interface for multi-viewport support
    // Read comments around the ImGuiPlatformIO structure for more details.
    // Note: You may use GetWindowViewport() to get the current viewport of the current window.
    void              UpdatePlatformWindows();                                        // call in main loop. will call CreateWindow/ResizeWindow/etc. platform functions for each secondary viewport, and DestroyWindow for each inactive viewport.
    void              RenderPlatformWindowsDefault(rawptr platform_render_arg = nil, rawptr renderer_render_arg = nil); // call in main loop. will call RenderWindow/SwapBuffers platform functions for each secondary viewport which doesn't have the ImGuiViewportFlags_Minimized flag set. May be reimplemented by user for custom rendering needs.
    void              DestroyPlatformWindows();                                       // call DestroyWindow platform functions for all viewports. call from backend Shutdown() if you need to close platform windows before imgui shutdown. otherwise will be called by DestroyContext().
    ImGuiViewport*    FindViewportByID(ImGuiID id);                                   // this is a helper for backends.
    ImGuiViewport*    FindViewportByPlatformHandle(rawptr platform_handle);            // this is a helper for backends. the type platform_handle is decided by the backend (e.g. HWND, MyWindow*, GLFWwindow* etc.)

} // namespace ImGui

//-----------------------------------------------------------------------------
// [SECTION] Flags & Enumerations
//-----------------------------------------------------------------------------

// Flags for ImGui::Begin()
// (Those are per-window flags. There are shared flags in ImGuiIO: io.ConfigWindowsResizeFromEdges and io.ConfigWindowsMoveFromTitleBarOnly)
ImGuiWindowFlags :: bit_set[ImGuiWindowFlag; i32]
ImGuiWindowFlag :: enum
{
    // [removed] -> nil: None                   = 0,
    NoTitleBar             = 0,   // Disable title-bar
    NoResize               = 1,   // Disable user resizing with the lower-right grip
    NoMove                 = 2,   // Disable user moving the window
    NoScrollbar            = 3,   // Disable scrollbars (window can still scroll with mouse or programmatically)
    NoScrollWithMouse      = 4,   // Disable user vertically scrolling with mouse wheel. On child window, mouse wheel will be forwarded to the parent unless NoScrollbar is also set.
    NoCollapse             = 5,   // Disable user collapsing window by double-clicking on it. Also referred to as Window Menu Button (e.g. within a docking node).
    AlwaysAutoResize       = 6,   // Resize every window to its content every frame
    NoBackground           = 7,   // Disable drawing background color (WindowBg, etc.) and outside border. Similar as using SetNextWindowBgAlpha(0.0f).
    NoSavedSettings        = 8,   // Never load/save settings in .ini file
    NoMouseInputs          = 9,   // Disable catching mouse, hovering test with pass through.
    MenuBar                = 10,  // Has a menu-bar
    HorizontalScrollbar    = 11,  // Allow horizontal scrollbar to appear (off by default). You may use SetNextWindowContentSize(ImVec2(width,0.0f)); prior to calling Begin() to specify width. Read code in imgui_demo in the "Horizontal Scrolling" section.
    NoFocusOnAppearing     = 12,  // Disable taking focus when transitioning from hidden to visible state
    NoBringToFrontOnFocus  = 13,  // Disable bringing window to front when taking focus (e.g. clicking on it or programmatically giving it focus)
    AlwaysVerticalScrollbar= 14,  // Always show vertical scrollbar (even if ContentSize.y < Size.y)
    AlwaysHorizontalScrollbar=15,  // Always show horizontal scrollbar (even if ContentSize.x < Size.x)
    NoNavInputs            = 16,  // No keyboard/gamepad navigation within the window
    NoNavFocus             = 17,  // No focusing toward this window with keyboard/gamepad navigation (e.g. skipped by CTRL+TAB)
    UnsavedDocument        = 18,  // Display a dot next to the title. When used in a tab/docking context, tab is selected when clicking the X + closure is not assumed (will wait for user to stop submitting the tab). Otherwise closure is assumed when pressing the X, so if you keep submitting the tab may reappear at end of tab bar.
    NoDocking              = 19,  // Disable docking of this window
    // [moved] NoNav                  = NoNavInputs | NoNavFocus,
    // [moved] NoDecoration           = NoTitleBar | NoResize | NoScrollbar | NoCollapse,
    // [moved] NoInputs               = NoMouseInputs | NoNavInputs | NoNavFocus,

    // [Internal]
    ChildWindow            = 24,  // Don't use! For internal use by BeginChild()
    Tooltip                = 25,  // Don't use! For internal use by BeginTooltip()
    Popup                  = 26,  // Don't use! For internal use by BeginPopup()
    Modal                  = 27,  // Don't use! For internal use by BeginPopupModal()
    ChildMenu              = 28,  // Don't use! For internal use by BeginMenu()
    DockNodeHost           = 29,  // Don't use! For internal use by Begin()/NewFrame()

    // Obsolete names
};
ImGuiWindowFlags_NoNav :: { NoNavInputs , NoNavFocus }
ImGuiWindowFlags_NoDecoration :: { NoTitleBar , NoResize , NoScrollbar , NoCollapse }
ImGuiWindowFlags_NoInputs :: { NoMouseInputs , NoNavInputs , NoNavFocus }

// Flags for ImGui::BeginChild()
// (Legacy: bit 0 must always correspond to ImGuiChildFlags_Borders to be backward compatible with old API using 'bool border = false'.
// About using AutoResizeX/AutoResizeY flags:
// - May be combined with SetNextWindowSizeConstraints() to set a min/max size for each axis (see "Demo->Child->Auto-resize with Constraints").
// - Size measurement for a given axis is only performed when the child window is within visible boundaries, or is just appearing.
//   - This allows BeginChild() to return false when not within boundaries (e.g. when scrolling), which is more optimal. BUT it won't update its auto-size while clipped.
//     While not perfect, it is a better default behavior as the always-on performance gain is more valuable than the occasional "resizing after becoming visible again" glitch.
//   - You may also use ImGuiChildFlags_AlwaysAutoResize to force an update even when child window is not in view.
//     HOWEVER PLEASE UNDERSTAND THAT DOING SO WILL PREVENT BeginChild() FROM EVER RETURNING FALSE, disabling benefits of coarse clipping.
ImGuiChildFlags :: bit_set[ImGuiChildFlag; i32]
ImGuiChildFlag :: enum
{
    // [removed] -> nil: None                    = 0,
    Borders                 = 0,   // Show an outer border and enable WindowPadding. (IMPORTANT: this is always == 1 == true for legacy reason)
    AlwaysUseWindowPadding  = 1,   // Pad with style.WindowPadding even if no border are drawn (no padding by default for non-bordered child windows because it makes more sense)
    ResizeX                 = 2,   // Allow resize from right border (layout direction). Enable .ini saving (unless ImGuiWindowFlags_NoSavedSettings passed to window flags)
    ResizeY                 = 3,   // Allow resize from bottom border (layout direction). "
    AutoResizeX             = 4,   // Enable auto-resizing width. Read "IMPORTANT: Size measurement" details above.
    AutoResizeY             = 5,   // Enable auto-resizing height. Read "IMPORTANT: Size measurement" details above.
    AlwaysAutoResize        = 6,   // Combined with AutoResizeX/AutoResizeY. Always measure size even when child is hidden, always return true, always disable clipping optimization! NOT RECOMMENDED.
    FrameStyle              = 7,   // Style the child window like a framed item: use FrameBg, FrameRounding, FrameBorderSize, FramePadding instead of ChildBg, ChildRounding, ChildBorderSize, WindowPadding.
    NavFlattened            = 8,   // [BETA] Share focus scope, allow keyboard/gamepad navigation to cross over parent border to this child or between sibling child windows.

    // Obsolete names
};

// Flags for ImGui::PushItemFlag()
// (Those are shared by all items)
ImGuiItemFlags :: bit_set[ImGuiItemFlag; i32]
ImGuiItemFlag :: enum
{
    // [removed] -> nil: None                     = 0,        // (Default)
    NoTabStop                = 0,   // false    // Disable keyboard tabbing. This is a "lighter" version of ImGuiItemFlags_NoNav.
    NoNav                    = 1,   // false    // Disable any form of focusing (keyboard/gamepad directional navigation and SetKeyboardFocusHere() calls).
    NoNavDefaultFocus        = 2,   // false    // Disable item being a candidate for default focus (e.g. used by title bar items).
    ButtonRepeat             = 3,   // false    // Any button-like behavior will have repeat mode enabled (based on io.KeyRepeatDelay and io.KeyRepeatRate values). Note that you can also call IsItemActive() after any button to tell if it is being held.
    AutoClosePopups          = 4,   // true     // MenuItem()/Selectable() automatically close their parent popup window.
    AllowDuplicateId         = 5,   // false    // Allow submitting an item with the same identifier as an item already submitted this frame without triggering a warning tooltip if io.ConfigDebugHighlightIdConflicts is set.
};

// Flags for ImGui::InputText()
// (Those are per-item flags. There are shared flags in ImGuiIO: io.ConfigInputTextCursorBlink and io.ConfigInputTextEnterKeepActive)
ImGuiInputTextFlags :: bit_set[ImGuiInputTextFlag; i32]
ImGuiInputTextFlag :: enum
{
    // Basic filters (also see ImGuiInputTextFlags_CallbackCharFilter)
    // [removed] -> nil: None                = 0,
    CharsDecimal        = 0,   // Allow 0123456789.+-*/
    CharsHexadecimal    = 1,   // Allow 0123456789ABCDEFabcdef
    CharsScientific     = 2,   // Allow 0123456789.+-*/eE (Scientific notation input)
    CharsUppercase      = 3,   // Turn a..z into A..Z
    CharsNoBlank        = 4,   // Filter out spaces, tabs

    // Inputs
    AllowTabInput       = 5,   // Pressing TAB input a '\t' character into the text field
    EnterReturnsTrue    = 6,   // Return 'true' when Enter is pressed (as opposed to every time the value was modified). Consider using IsItemDeactivatedAfterEdit() instead!
    EscapeClearsAll     = 7,   // Escape key clears content if not empty, and deactivate otherwise (contrast to default behavior of Escape to revert)
    CtrlEnterForNewLine = 8,   // In multi-line mode, validate with Enter, add new line with Ctrl+Enter (default is opposite: validate with Ctrl+Enter, add line with Enter).

    // Other options
    ReadOnly            = 9,   // Read-only mode
    Password            = 10,  // Password mode, display all characters as '*', disable copy
    AlwaysOverwrite     = 11,  // Overwrite mode
    AutoSelectAll       = 12,  // Select entire text when first taking mouse focus
    ParseEmptyRefVal    = 13,  // InputFloat(), InputInt(), InputScalar() etc. only: parse empty string as zero value.
    DisplayEmptyRefVal  = 14,  // InputFloat(), InputInt(), InputScalar() etc. only: when value is zero, do not display it. Generally used with ImGuiInputTextFlags_ParseEmptyRefVal.
    NoHorizontalScroll  = 15,  // Disable following the cursor horizontally
    NoUndoRedo          = 16,  // Disable undo/redo. Note that input text owns the text data while active, if you want to provide your own undo/redo stack you need e.g. to call ClearActiveID().

    // Elide display / Alignment
    ElideLeft			= 17,	// When text doesn't fit, elide left side to ensure right side stays visible. Useful for path/filenames. Single-line only!

    // Callback features
    CallbackCompletion  = 18,  // Callback on pressing TAB (for completion handling)
    CallbackHistory     = 19,  // Callback on pressing Up/Down arrows (for history handling)
    CallbackAlways      = 20,  // Callback on each iteration. User code may query cursor position, modify text buffer.
    CallbackCharFilter  = 21,  // Callback on character inputs to replace or discard them. Modify 'EventChar' to replace or discard, or return 1 in callback to discard.
    CallbackResize      = 22,  // Callback on buffer capacity changes request (beyond 'buf_size' parameter value), allowing the string to grow. Notify when the string wants to be resized (for string types which hold a cache of their Size). You will be provided a new BufSize in the callback and NEED to honor it. (see misc/cpp/imgui_stdlib.h for an example of using this)
    CallbackEdit        = 23,  // Callback on any edit (note that InputText() already returns true on edit, the callback is useful mainly to manipulate the underlying buffer while focus is active)

    // Obsolete names
    //ImGuiInputTextFlags_AlwaysInsertMode  = ImGuiInputTextFlags_AlwaysOverwrite   // [renamed in 1.82] name was not matching behavior
};

// Flags for ImGui::TreeNodeEx(), ImGui::CollapsingHeader*()
ImGuiTreeNodeFlags :: bit_set[ImGuiTreeNodeFlag; i32]
ImGuiTreeNodeFlag :: enum
{
    // [removed] -> nil: None                 = 0,
    Selected             = 0,   // Draw as selected
    Framed               = 1,   // Draw frame with background (e.g. for CollapsingHeader)
    AllowOverlap         = 2,   // Hit testing to allow subsequent widgets to overlap this one
    NoTreePushOnOpen     = 3,   // Don't do a TreePush() when open (e.g. for CollapsingHeader) = no extra indent nor pushing on ID stack
    NoAutoOpenOnLog      = 4,   // Don't automatically and temporarily open node when Logging is active (by default logging will automatically open tree nodes)
    DefaultOpen          = 5,   // Default node to be open
    OpenOnDoubleClick    = 6,   // Open on double-click instead of simple click (default for multi-select unless any _OpenOnXXX behavior is set explicitly). Both behaviors may be combined.
    OpenOnArrow          = 7,   // Open when clicking on the arrow part (default for multi-select unless any _OpenOnXXX behavior is set explicitly). Both behaviors may be combined.
    Leaf                 = 8,   // No collapsing, no arrow (use as a convenience for leaf nodes).
    Bullet               = 9,   // Display a bullet instead of arrow. IMPORTANT: node can still be marked open/close if you don't set the _Leaf flag!
    FramePadding         = 10,  // Use FramePadding (even for an unframed text node) to vertically align text baseline to regular widget height. Equivalent to calling AlignTextToFramePadding() before the node.
    SpanAvailWidth       = 11,  // Extend hit box to the right-most edge, even if not framed. This is not the default in order to allow adding other items on the same line without using AllowOverlap mode.
    SpanFullWidth        = 12,  // Extend hit box to the left-most and right-most edges (cover the indent area).
    SpanTextWidth        = 13,  // Narrow hit box + narrow hovering highlight, will only cover the label text.
    SpanAllColumns       = 14,  // Frame will span all columns of its container table (text will still fit in current column)
    NavLeftJumpsBackHere = 15,  // (WIP) Nav: left direction may move to this TreeNode() from any of its child (items submitted between TreeNode and TreePop)
    //ImGuiTreeNodeFlags_NoScrollOnOpen     = 1 << 16,  // FIXME: TODO: Disable automatic scroll on TreePop() if node got just open and contents is not visible
    // [moved] CollapsingHeader     = Framed | NoTreePushOnOpen | NoAutoOpenOnLog,

};
ImGuiTreeNodeFlags_CollapsingHeader :: { Framed , NoTreePushOnOpen , NoAutoOpenOnLog }

// Flags for OpenPopup*(), BeginPopupContext*(), IsPopupOpen() functions.
// - To be backward compatible with older API which took an 'int mouse_button = 1' argument instead of 'ImGuiPopupFlags flags',
//   we need to treat small flags values as a mouse button index, so we encode the mouse button in the first few bits of the flags.
//   It is therefore guaranteed to be legal to pass a mouse button index in ImGuiPopupFlags.
// - For the same reason, we exceptionally default the ImGuiPopupFlags argument of BeginPopupContextXXX functions to 1 instead of 0.
//   IMPORTANT: because the default parameter is 1 (==ImGuiPopupFlags_MouseButtonRight), if you rely on the default parameter
//   and want to use another flag, you need to pass in the ImGuiPopupFlags_MouseButtonRight flag explicitly.
// - Multiple buttons currently cannot be combined/or-ed in those functions (we could allow it later).
ImGuiPopupFlags :: bit_set[ImGuiPopupFlag; i32]
ImGuiPopupFlag :: enum
{
    // [removed] -> nil: None                    = 0,
    // [moved] MouseButtonLeft         = 0,        // For BeginPopupContext*(): open on Left Mouse release. Guaranteed to always be == 0 (same as ImGuiMouseButton_Left)
    // [moved] MouseButtonRight        = 1,        // For BeginPopupContext*(): open on Right Mouse release. Guaranteed to always be == 1 (same as ImGuiMouseButton_Right)
    // [moved] MouseButtonMiddle       = 2,        // For BeginPopupContext*(): open on Middle Mouse release. Guaranteed to always be == 2 (same as ImGuiMouseButton_Middle)
    // [moved] MouseButtonMask_        = 0x1F,
    // [moved] MouseButtonDefault_     = 1,
    NoReopen                = 5,   // For OpenPopup*(), BeginPopupContext*(): don't reopen same popup if already open (won't reposition, won't reinitialize navigation)
    //ImGuiPopupFlags_NoReopenAlwaysNavInit = 1 << 6,   // For OpenPopup*(), BeginPopupContext*(): focus and initialize navigation even when not reopening.
    NoOpenOverExistingPopup = 7,   // For OpenPopup*(), BeginPopupContext*(): don't open if there's already a popup at the same level of the popup stack
    NoOpenOverItems         = 8,   // For BeginPopupContextWindow(): don't return true when hovering items, only when hovering empty space
    AnyPopupId              = 10,  // For IsPopupOpen(): ignore the ImGuiID parameter and test for any popup.
    AnyPopupLevel           = 11,  // For IsPopupOpen(): search/test at any level of the popup stack (default test in the current level)
    // [moved] AnyPopup                = AnyPopupId | AnyPopupLevel,
};
ImGuiPopupFlags_MouseButtonLeft :: { 0 }
ImGuiPopupFlags_MouseButtonRight :: { 1 }
ImGuiPopupFlags_MouseButtonMiddle :: { 2 }
ImGuiPopupFlags_MouseButtonMask_ :: { 0x1F }
ImGuiPopupFlags_MouseButtonDefault_ :: { 1 }
ImGuiPopupFlags_AnyPopup :: { AnyPopupId , AnyPopupLevel }

// Flags for ImGui::Selectable()
ImGuiSelectableFlags :: bit_set[ImGuiSelectableFlag; i32]
ImGuiSelectableFlag :: enum
{
    // [removed] -> nil: None               = 0,
    NoAutoClosePopups  = 0,   // Clicking this doesn't close parent popup window (overrides ImGuiItemFlags_AutoClosePopups)
    SpanAllColumns     = 1,   // Frame will span all columns of its container table (text will still fit in current column)
    AllowDoubleClick   = 2,   // Generate press events on double clicks too
    Disabled           = 3,   // Cannot be selected, display grayed out text
    AllowOverlap       = 4,   // (WIP) Hit testing to allow subsequent widgets to overlap this one
    Highlight          = 5,   // Make the item be displayed as if it is hovered

};

// Flags for ImGui::BeginCombo()
ImGuiComboFlags :: bit_set[ImGuiComboFlag; i32]
ImGuiComboFlag :: enum
{
    // [removed] -> nil: None                    = 0,
    PopupAlignLeft          = 0,   // Align the popup toward the left by default
    HeightSmall             = 1,   // Max ~4 items visible. Tip: If you want your combo popup to be a specific size you can use SetNextWindowSizeConstraints() prior to calling BeginCombo()
    HeightRegular           = 2,   // Max ~8 items visible (default)
    HeightLarge             = 3,   // Max ~20 items visible
    HeightLargest           = 4,   // As many fitting items as possible
    NoArrowButton           = 5,   // Display on the preview box without the square arrow button
    NoPreview               = 6,   // Display only a square arrow button
    WidthFitPreview         = 7,   // Width dynamically calculated from preview contents
    // [moved] HeightMask_             = HeightSmall | HeightRegular | HeightLarge | HeightLargest,
};
ImGuiComboFlags_HeightMask_ :: { HeightSmall , HeightRegular , HeightLarge , HeightLargest }

// Flags for ImGui::BeginTabBar()
ImGuiTabBarFlags :: bit_set[ImGuiTabBarFlag; i32]
ImGuiTabBarFlag :: enum
{
    // [removed] -> nil: None                           = 0,
    Reorderable                    = 0,   // Allow manually dragging tabs to re-order them + New tabs are appended at the end of list
    AutoSelectNewTabs              = 1,   // Automatically select new tabs when they appear
    TabListPopupButton             = 2,   // Disable buttons to open the tab list popup
    NoCloseWithMiddleMouseButton   = 3,   // Disable behavior of closing tabs (that are submitted with p_open != NULL) with middle mouse button. You may handle this behavior manually on user's side with if (IsItemHovered() && IsMouseClicked(2)) *p_open = false.
    NoTabListScrollingButtons      = 4,   // Disable scrolling buttons (apply when fitting policy is ImGuiTabBarFlags_FittingPolicyScroll)
    NoTooltip                      = 5,   // Disable tooltips when hovering a tab
    DrawSelectedOverline           = 6,   // Draw selected overline markers over selected tab
    FittingPolicyResizeDown        = 7,   // Resize tabs when they don't fit
    FittingPolicyScroll            = 8,   // Add scroll buttons when tabs don't fit
    // [moved] FittingPolicyMask_             = FittingPolicyResizeDown | FittingPolicyScroll,
    // [moved] FittingPolicyDefault_          = FittingPolicyResizeDown,
};
ImGuiTabBarFlags_FittingPolicyMask_ :: { FittingPolicyResizeDown , FittingPolicyScroll }
ImGuiTabBarFlags_FittingPolicyDefault_ :: { FittingPolicyResizeDown }

// Flags for ImGui::BeginTabItem()
ImGuiTabItemFlags :: bit_set[ImGuiTabItemFlag; i32]
ImGuiTabItemFlag :: enum
{
    // [removed] -> nil: None                          = 0,
    UnsavedDocument               = 0,   // Display a dot next to the title + set ImGuiTabItemFlags_NoAssumedClosure.
    SetSelected                   = 1,   // Trigger flag to programmatically make the tab selected when calling BeginTabItem()
    NoCloseWithMiddleMouseButton  = 2,   // Disable behavior of closing tabs (that are submitted with p_open != NULL) with middle mouse button. You may handle this behavior manually on user's side with if (IsItemHovered() && IsMouseClicked(2)) *p_open = false.
    NoPushId                      = 3,   // Don't call PushID()/PopID() on BeginTabItem()/EndTabItem()
    NoTooltip                     = 4,   // Disable tooltip for the given tab
    NoReorder                     = 5,   // Disable reordering this tab or having another tab cross over this tab
    Leading                       = 6,   // Enforce the tab position to the left of the tab bar (after the tab list popup button)
    Trailing                      = 7,   // Enforce the tab position to the right of the tab bar (before the scrolling buttons)
    NoAssumedClosure              = 8,   // Tab is selected when trying to close + closure is not immediately assumed (will wait for user to stop submitting the tab). Otherwise closure is assumed when pressing the X, so if you keep submitting the tab may reappear at end of tab bar.
};

// Flags for ImGui::IsWindowFocused()
ImGuiFocusedFlags :: bit_set[ImGuiFocusedFlag; i32]
ImGuiFocusedFlag :: enum
{
    // [removed] -> nil: None                          = 0,
    ChildWindows                  = 0,   // Return true if any children of the window is focused
    RootWindow                    = 1,   // Test from root window (top most parent of the current hierarchy)
    AnyWindow                     = 2,   // Return true if any window is focused. Important: If you are trying to tell how to dispatch your low-level inputs, do NOT use this. Use 'io.WantCaptureMouse' instead! Please read the FAQ!
    NoPopupHierarchy              = 3,   // Do not consider popup hierarchy (do not treat popup emitter as parent of popup) (when used with _ChildWindows or _RootWindow)
    DockHierarchy                 = 4,   // Consider docking hierarchy (treat dockspace host as parent of docked window) (when used with _ChildWindows or _RootWindow)
    // [moved] RootAndChildWindows           = RootWindow | ChildWindows,
};
ImGuiFocusedFlags_RootAndChildWindows :: { RootWindow , ChildWindows }

// Flags for ImGui::IsItemHovered(), ImGui::IsWindowHovered()
// Note: if you are trying to check whether your mouse should be dispatched to Dear ImGui or to your app, you should use 'io.WantCaptureMouse' instead! Please read the FAQ!
// Note: windows with the ImGuiWindowFlags_NoInputs flag are ignored by IsWindowHovered() calls.
ImGuiHoveredFlags :: bit_set[ImGuiHoveredFlag; i32]
ImGuiHoveredFlag :: enum
{
    // [removed] -> nil: None                          = 0,        // Return true if directly over the item/window, not obstructed by another window, not obstructed by an active popup or modal blocking inputs under them.
    ChildWindows                  = 0,   // IsWindowHovered() only: Return true if any children of the window is hovered
    RootWindow                    = 1,   // IsWindowHovered() only: Test from root window (top most parent of the current hierarchy)
    AnyWindow                     = 2,   // IsWindowHovered() only: Return true if any window is hovered
    NoPopupHierarchy              = 3,   // IsWindowHovered() only: Do not consider popup hierarchy (do not treat popup emitter as parent of popup) (when used with _ChildWindows or _RootWindow)
    DockHierarchy                 = 4,   // IsWindowHovered() only: Consider docking hierarchy (treat dockspace host as parent of docked window) (when used with _ChildWindows or _RootWindow)
    AllowWhenBlockedByPopup       = 5,   // Return true even if a popup window is normally blocking access to this item/window
    //ImGuiHoveredFlags_AllowWhenBlockedByModal     = 1 << 6,   // Return true even if a modal popup window is normally blocking access to this item/window. FIXME-TODO: Unavailable yet.
    AllowWhenBlockedByActiveItem  = 7,   // Return true even if an active item is blocking access to this item/window. Useful for Drag and Drop patterns.
    AllowWhenOverlappedByItem     = 8,   // IsItemHovered() only: Return true even if the item uses AllowOverlap mode and is overlapped by another hoverable item.
    AllowWhenOverlappedByWindow   = 9,   // IsItemHovered() only: Return true even if the position is obstructed or overlapped by another window.
    AllowWhenDisabled             = 10,  // IsItemHovered() only: Return true even if the item is disabled
    NoNavOverride                 = 11,  // IsItemHovered() only: Disable using keyboard/gamepad navigation state when active, always query mouse
    // [moved] AllowWhenOverlapped           = AllowWhenOverlappedByItem | AllowWhenOverlappedByWindow,
    // [moved] RectOnly                      = AllowWhenBlockedByPopup | AllowWhenBlockedByActiveItem | AllowWhenOverlapped,
    // [moved] RootAndChildWindows           = RootWindow | ChildWindows,

    // Tooltips mode
    // - typically used in IsItemHovered() + SetTooltip() sequence.
    // - this is a shortcut to pull flags from 'style.HoverFlagsForTooltipMouse' or 'style.HoverFlagsForTooltipNav' where you can reconfigure desired behavior.
    //   e.g. 'TooltipHoveredFlagsForMouse' defaults to 'ImGuiHoveredFlags_Stationary | ImGuiHoveredFlags_DelayShort'.
    // - for frequently actioned or hovered items providing a tooltip, you want may to use ImGuiHoveredFlags_ForTooltip (stationary + delay) so the tooltip doesn't show too often.
    // - for items which main purpose is to be hovered, or items with low affordance, or in less consistent apps, prefer no delay or shorter delay.
    ForTooltip                    = 12,  // Shortcut for standard flags when using IsItemHovered() + SetTooltip() sequence.

    // (Advanced) Mouse Hovering delays.
    // - generally you can use ImGuiHoveredFlags_ForTooltip to use application-standardized flags.
    // - use those if you need specific overrides.
    Stationary                    = 13,  // Require mouse to be stationary for style.HoverStationaryDelay (~0.15 sec) _at least one time_. After this, can move on same item/window. Using the stationary test tends to reduces the need for a long delay.
    DelayNone                     = 14,  // IsItemHovered() only: Return true immediately (default). As this is the default you generally ignore this.
    DelayShort                    = 15,  // IsItemHovered() only: Return true after style.HoverDelayShort elapsed (~0.15 sec) (shared between items) + requires mouse to be stationary for style.HoverStationaryDelay (once per item).
    DelayNormal                   = 16,  // IsItemHovered() only: Return true after style.HoverDelayNormal elapsed (~0.40 sec) (shared between items) + requires mouse to be stationary for style.HoverStationaryDelay (once per item).
    NoSharedDelay                 = 17,  // IsItemHovered() only: Disable shared delay system where moving from one item to the next keeps the previous timer for a short time (standard for tooltips with long delays)
};
ImGuiHoveredFlags_AllowWhenOverlapped :: { AllowWhenOverlappedByItem , AllowWhenOverlappedByWindow }
ImGuiHoveredFlags_RectOnly :: { AllowWhenBlockedByPopup , AllowWhenBlockedByActiveItem , AllowWhenOverlapped }
ImGuiHoveredFlags_RootAndChildWindows :: { RootWindow , ChildWindows }

// Flags for ImGui::DockSpace(), shared/inherited by child nodes.
// (Some flags can be applied to individual nodes directly)
// FIXME-DOCK: Also see ImGuiDockNodeFlagsPrivate_ which may involve using the WIP and internal DockBuilder api.
ImGuiDockNodeFlags :: bit_set[ImGuiDockNodeFlag; i32]
ImGuiDockNodeFlag :: enum
{
    // [removed] -> nil: None                         = 0,
    KeepAliveOnly                = 0,   //       // Don't display the dockspace node but keep it alive. Windows docked into this dockspace node won't be undocked.
    //ImGuiDockNodeFlags_NoCentralNode              = 1 << 1,   //       // Disable Central Node (the node which can stay empty)
    NoDockingOverCentralNode     = 2,   //       // Disable docking over the Central Node, which will be always kept empty.
    PassthruCentralNode          = 3,   //       // Enable passthru dockspace: 1) DockSpace() will render a ImGuiCol_WindowBg background covering everything excepted the Central Node when empty. Meaning the host window should probably use SetNextWindowBgAlpha(0.0f) prior to Begin() when using this. 2) When Central Node is empty: let inputs pass-through + won't display a DockingEmptyBg background. See demo for details.
    NoDockingSplit               = 4,   //       // Disable other windows/nodes from splitting this node.
    NoResize                     = 5,   // Saved // Disable resizing node using the splitter/separators. Useful with programmatically setup dockspaces.
    AutoHideTabBar               = 6,   //       // Tab bar will automatically hide when there is a single window in the dock node.
    NoUndocking                  = 7,   //       // Disable undocking this node.

};

// Flags for ImGui::BeginDragDropSource(), ImGui::AcceptDragDropPayload()
ImGuiDragDropFlags :: bit_set[ImGuiDragDropFlag; i32]
ImGuiDragDropFlag :: enum
{
    // [removed] -> nil: None                         = 0,
    // BeginDragDropSource() flags
    SourceNoPreviewTooltip       = 0,   // Disable preview tooltip. By default, a successful call to BeginDragDropSource opens a tooltip so you can display a preview or description of the source contents. This flag disables this behavior.
    SourceNoDisableHover         = 1,   // By default, when dragging we clear data so that IsItemHovered() will return false, to avoid subsequent user code submitting tooltips. This flag disables this behavior so you can still call IsItemHovered() on the source item.
    SourceNoHoldToOpenOthers     = 2,   // Disable the behavior that allows to open tree nodes and collapsing header by holding over them while dragging a source item.
    SourceAllowNullID            = 3,   // Allow items such as Text(), Image() that have no unique identifier to be used as drag source, by manufacturing a temporary identifier based on their window-relative position. This is extremely unusual within the dear imgui ecosystem and so we made it explicit.
    SourceExtern                 = 4,   // External source (from outside of dear imgui), won't attempt to read current item/window info. Will always return true. Only one Extern source can be active simultaneously.
    PayloadAutoExpire            = 5,   // Automatically expire the payload if the source cease to be submitted (otherwise payloads are persisting while being dragged)
    PayloadNoCrossContext        = 6,   // Hint to specify that the payload may not be copied outside current dear imgui context.
    PayloadNoCrossProcess        = 7,   // Hint to specify that the payload may not be copied outside current process.
    // AcceptDragDropPayload() flags
    AcceptBeforeDelivery         = 10,  // AcceptDragDropPayload() will returns true even before the mouse button is released. You can then call IsDelivery() to test if the payload needs to be delivered.
    AcceptNoDrawDefaultRect      = 11,  // Do not draw the default highlight rectangle when hovering over target.
    AcceptNoPreviewTooltip       = 12,  // Request hiding the BeginDragDropSource tooltip from the BeginDragDropTarget site.
    // [moved] AcceptPeekOnly               = AcceptBeforeDelivery | AcceptNoDrawDefaultRect, // For peeking ahead and inspecting the payload before delivery.

};
ImGuiDragDropFlags_AcceptPeekOnly :: { AcceptBeforeDelivery , AcceptNoDrawDefaultRect }

// Standard Drag and Drop payload types. You can define you own payload types using short strings. Types starting with '_' are defined by Dear ImGui.
IMGUI_PAYLOAD_TYPE_COLOR_3F :: "_COL3F"    // float[3]: Standard type for colors, without alpha. User code may use this type.
IMGUI_PAYLOAD_TYPE_COLOR_4F :: "_COL4F"    // float[4]: Standard type for colors. User code may use this type.

// A primary data type
ImGuiDataType_ :: enum i32
{
    S8,       // signed char / char (with sensible compilers)
    U8,       // unsigned char
    S16,      // short
    U16,      // unsigned short
    S32,      // int
    U32,      // unsigned int
    S64,      // long long / __int64
    U64,      // unsigned long long / unsigned __int64
    Float,    // float
    Double,   // double
    Bool,     // bool (provided for user convenience, not supported by scalar widgets)
    String,   // char* (provided for user convenience, not supported by scalar widgets)
    _COUNT,
};

// A cardinal direction
ImGuiDir :: enum i32
{
    ImGuiDir_None    = -1,
    ImGuiDir_Left    = 0,
    ImGuiDir_Right   = 1,
    ImGuiDir_Up      = 2,
    ImGuiDir_Down    = 3,
    ImGuiDir_COUNT
};

// A sorting direction
ImGuiSortDirection :: enum u8
{
    ImGuiSortDirection_None         = 0,
    ImGuiSortDirection_Ascending    = 1,    // Ascending = 0->9, A->Z etc.
    ImGuiSortDirection_Descending   = 2     // Descending = 9->0, Z->A etc.
};

// A key identifier (ImGuiKey_XXX or ImGuiMod_XXX value): can represent Keyboard, Mouse and Gamepad values.
// All our named keys are >= 512. Keys value 0 to 511 are left unused and were legacy native/opaque key values (< 1.87).
// Support for legacy keys was completely removed in 1.91.5.
// Read details about the 1.87+ transition : https://github.com/ocornut/imgui/issues/4921
// Note that "Keys" related to physical keys and are not the same concept as input "Characters", the later are submitted via io.AddInputCharacter().
// The keyboard key enum values are named after the keys on a standard US keyboard, and on other keyboard types the keys reported may not match the keycaps.
ImGuiKey :: enum i32
{
    // Keyboard
    ImGuiKey_None = 0,
    ImGuiKey_NamedKey_BEGIN = 512,  // First valid key value (other than 0)

    ImGuiKey_Tab = 512,             // == ImGuiKey_NamedKey_BEGIN
    ImGuiKey_LeftArrow,
    ImGuiKey_RightArrow,
    ImGuiKey_UpArrow,
    ImGuiKey_DownArrow,
    ImGuiKey_PageUp,
    ImGuiKey_PageDown,
    ImGuiKey_Home,
    ImGuiKey_End,
    ImGuiKey_Insert,
    ImGuiKey_Delete,
    ImGuiKey_Backspace,
    ImGuiKey_Space,
    ImGuiKey_Enter,
    ImGuiKey_Escape,
    ImGuiKey_LeftCtrl, ImGuiKey_LeftShift, ImGuiKey_LeftAlt, ImGuiKey_LeftSuper,
    ImGuiKey_RightCtrl, ImGuiKey_RightShift, ImGuiKey_RightAlt, ImGuiKey_RightSuper,
    ImGuiKey_Menu,
    ImGuiKey_0, ImGuiKey_1, ImGuiKey_2, ImGuiKey_3, ImGuiKey_4, ImGuiKey_5, ImGuiKey_6, ImGuiKey_7, ImGuiKey_8, ImGuiKey_9,
    ImGuiKey_A, ImGuiKey_B, ImGuiKey_C, ImGuiKey_D, ImGuiKey_E, ImGuiKey_F, ImGuiKey_G, ImGuiKey_H, ImGuiKey_I, ImGuiKey_J,
    ImGuiKey_K, ImGuiKey_L, ImGuiKey_M, ImGuiKey_N, ImGuiKey_O, ImGuiKey_P, ImGuiKey_Q, ImGuiKey_R, ImGuiKey_S, ImGuiKey_T,
    ImGuiKey_U, ImGuiKey_V, ImGuiKey_W, ImGuiKey_X, ImGuiKey_Y, ImGuiKey_Z,
    ImGuiKey_F1, ImGuiKey_F2, ImGuiKey_F3, ImGuiKey_F4, ImGuiKey_F5, ImGuiKey_F6,
    ImGuiKey_F7, ImGuiKey_F8, ImGuiKey_F9, ImGuiKey_F10, ImGuiKey_F11, ImGuiKey_F12,
    ImGuiKey_F13, ImGuiKey_F14, ImGuiKey_F15, ImGuiKey_F16, ImGuiKey_F17, ImGuiKey_F18,
    ImGuiKey_F19, ImGuiKey_F20, ImGuiKey_F21, ImGuiKey_F22, ImGuiKey_F23, ImGuiKey_F24,
    ImGuiKey_Apostrophe,        // '
    ImGuiKey_Comma,             // ,
    ImGuiKey_Minus,             // -
    ImGuiKey_Period,            // .
    ImGuiKey_Slash,             // /
    ImGuiKey_Semicolon,         // ;
    ImGuiKey_Equal,             // =
    ImGuiKey_LeftBracket,       // [
    ImGuiKey_Backslash,         // \ (this text inhibit multiline comment caused by backslash)
    ImGuiKey_RightBracket,      // ]
    ImGuiKey_GraveAccent,       // `
    ImGuiKey_CapsLock,
    ImGuiKey_ScrollLock,
    ImGuiKey_NumLock,
    ImGuiKey_PrintScreen,
    ImGuiKey_Pause,
    ImGuiKey_Keypad0, ImGuiKey_Keypad1, ImGuiKey_Keypad2, ImGuiKey_Keypad3, ImGuiKey_Keypad4,
    ImGuiKey_Keypad5, ImGuiKey_Keypad6, ImGuiKey_Keypad7, ImGuiKey_Keypad8, ImGuiKey_Keypad9,
    ImGuiKey_KeypadDecimal,
    ImGuiKey_KeypadDivide,
    ImGuiKey_KeypadMultiply,
    ImGuiKey_KeypadSubtract,
    ImGuiKey_KeypadAdd,
    ImGuiKey_KeypadEnter,
    ImGuiKey_KeypadEqual,
    ImGuiKey_AppBack,               // Available on some keyboard/mouses. Often referred as "Browser Back"
    ImGuiKey_AppForward,

    // Gamepad (some of those are analog values, 0.0f to 1.0f)                          // NAVIGATION ACTION
    // (download controller mapping PNG/PSD at http://dearimgui.com/controls_sheets)
    ImGuiKey_GamepadStart,          // Menu (Xbox)      + (Switch)   Start/Options (PS)
    ImGuiKey_GamepadBack,           // View (Xbox)      - (Switch)   Share (PS)
    ImGuiKey_GamepadFaceLeft,       // X (Xbox)         Y (Switch)   Square (PS)        // Tap: Toggle Menu. Hold: Windowing mode (Focus/Move/Resize windows)
    ImGuiKey_GamepadFaceRight,      // B (Xbox)         A (Switch)   Circle (PS)        // Cancel / Close / Exit
    ImGuiKey_GamepadFaceUp,         // Y (Xbox)         X (Switch)   Triangle (PS)      // Text Input / On-screen Keyboard
    ImGuiKey_GamepadFaceDown,       // A (Xbox)         B (Switch)   Cross (PS)         // Activate / Open / Toggle / Tweak
    ImGuiKey_GamepadDpadLeft,       // D-pad Left                                       // Move / Tweak / Resize Window (in Windowing mode)
    ImGuiKey_GamepadDpadRight,      // D-pad Right                                      // Move / Tweak / Resize Window (in Windowing mode)
    ImGuiKey_GamepadDpadUp,         // D-pad Up                                         // Move / Tweak / Resize Window (in Windowing mode)
    ImGuiKey_GamepadDpadDown,       // D-pad Down                                       // Move / Tweak / Resize Window (in Windowing mode)
    ImGuiKey_GamepadL1,             // L Bumper (Xbox)  L (Switch)   L1 (PS)            // Tweak Slower / Focus Previous (in Windowing mode)
    ImGuiKey_GamepadR1,             // R Bumper (Xbox)  R (Switch)   R1 (PS)            // Tweak Faster / Focus Next (in Windowing mode)
    ImGuiKey_GamepadL2,             // L Trig. (Xbox)   ZL (Switch)  L2 (PS) [Analog]
    ImGuiKey_GamepadR2,             // R Trig. (Xbox)   ZR (Switch)  R2 (PS) [Analog]
    ImGuiKey_GamepadL3,             // L Stick (Xbox)   L3 (Switch)  L3 (PS)
    ImGuiKey_GamepadR3,             // R Stick (Xbox)   R3 (Switch)  R3 (PS)
    ImGuiKey_GamepadLStickLeft,     // [Analog]                                         // Move Window (in Windowing mode)
    ImGuiKey_GamepadLStickRight,    // [Analog]                                         // Move Window (in Windowing mode)
    ImGuiKey_GamepadLStickUp,       // [Analog]                                         // Move Window (in Windowing mode)
    ImGuiKey_GamepadLStickDown,     // [Analog]                                         // Move Window (in Windowing mode)
    ImGuiKey_GamepadRStickLeft,     // [Analog]
    ImGuiKey_GamepadRStickRight,    // [Analog]
    ImGuiKey_GamepadRStickUp,       // [Analog]
    ImGuiKey_GamepadRStickDown,     // [Analog]

    // Aliases: Mouse Buttons (auto-submitted from AddMouseButtonEvent() calls)
    // - This is mirroring the data also written to io.MouseDown[], io.MouseWheel, in a format allowing them to be accessed via standard key API.
    ImGuiKey_MouseLeft, ImGuiKey_MouseRight, ImGuiKey_MouseMiddle, ImGuiKey_MouseX1, ImGuiKey_MouseX2, ImGuiKey_MouseWheelX, ImGuiKey_MouseWheelY,

    // [Internal] Reserved for mod storage
    ImGuiKey_ReservedForModCtrl, ImGuiKey_ReservedForModShift, ImGuiKey_ReservedForModAlt, ImGuiKey_ReservedForModSuper,
    ImGuiKey_NamedKey_END,

    // Keyboard Modifiers (explicitly submitted by backend via AddKeyEvent() calls)
    // - This is mirroring the data also written to io.KeyCtrl, io.KeyShift, io.KeyAlt, io.KeySuper, in a format allowing
    //   them to be accessed via standard key API, allowing calls such as IsKeyPressed(), IsKeyReleased(), querying duration etc.
    // - Code polling every key (e.g. an interface to detect a key press for input mapping) might want to ignore those
    //   and prefer using the real keys (e.g. ImGuiKey_LeftCtrl, ImGuiKey_RightCtrl instead of ImGuiMod_Ctrl).
    // - In theory the value of keyboard modifiers should be roughly equivalent to a logical or of the equivalent left/right keys.
    //   In practice: it's complicated; mods are often provided from different sources. Keyboard layout, IME, sticky keys and
    //   backends tend to interfere and break that equivalence. The safer decision is to relay that ambiguity down to the end-user...
    // - On macOS, we swap Cmd(Super) and Ctrl keys at the time of the io.AddKeyEvent() call.
    ImGuiMod_None                   = 0,
    ImGuiMod_Ctrl                   = 1 << 12, // Ctrl (non-macOS), Cmd (macOS)
    ImGuiMod_Shift                  = 1 << 13, // Shift
    ImGuiMod_Alt                    = 1 << 14, // Option/Menu
    ImGuiMod_Super                  = 1 << 15, // Windows/Super (non-macOS), Ctrl (macOS)
    ImGuiMod_Mask_                  = 0xF000,  // 4-bits

    // [Internal] If you need to iterate all keys (for e.g. an input mapper) you may use ImGuiKey_NamedKey_BEGIN..ImGuiKey_NamedKey_END.
    ImGuiKey_NamedKey_COUNT         = ImGuiKey_NamedKey_END - ImGuiKey_NamedKey_BEGIN,
    //ImGuiKey_KeysData_SIZE        = ImGuiKey_NamedKey_COUNT,  // Size of KeysData[]: only hold named keys
    //ImGuiKey_KeysData_OFFSET      = ImGuiKey_NamedKey_BEGIN,  // Accesses to io.KeysData[] must use (key - ImGuiKey_NamedKey_BEGIN) index.

};

// Flags for Shortcut(), SetNextItemShortcut(),
// (and for upcoming extended versions of IsKeyPressed(), IsMouseClicked(), Shortcut(), SetKeyOwner(), SetItemKeyOwner() that are still in imgui_internal.h)
// Don't mistake with ImGuiInputTextFlags! (which is for ImGui::InputText() function)
ImGuiInputFlags :: bit_set[ImGuiInputFlag; i32]
ImGuiInputFlag :: enum
{
    // [removed] -> nil: None                    = 0,
    Repeat                  = 0,   // Enable repeat. Return true on successive repeats. Default for legacy IsKeyPressed(). NOT Default for legacy IsMouseClicked(). MUST BE == 1.

    // Flags for Shortcut(), SetNextItemShortcut()
    // - Routing policies: RouteGlobal+OverActive >> RouteActive or RouteFocused (if owner is active item) >> RouteGlobal+OverFocused >> RouteFocused (if in focused window stack) >> RouteGlobal.
    // - Default policy is RouteFocused. Can select only 1 policy among all available.
    RouteActive             = 10,  // Route to active item only.
    RouteFocused            = 11,  // Route to windows in the focus stack (DEFAULT). Deep-most focused window takes inputs. Active item takes inputs over deep-most focused window.
    RouteGlobal             = 12,  // Global route (unless a focused window or active item registered the route).
    RouteAlways             = 13,  // Do not register route, poll keys directly.
    // - Routing options
    RouteOverFocused        = 14,  // Option: global route: higher priority than focused route (unless active item in focused route).
    RouteOverActive         = 15,  // Option: global route: higher priority than active item. Unlikely you need to use that: will interfere with every active items, e.g. CTRL+A registered by InputText will be overridden by this. May not be fully honored as user/internal code is likely to always assume they can access keys when active.
    RouteUnlessBgFocused    = 16,  // Option: global route: will not be applied if underlying background/void is focused (== no Dear ImGui windows are focused). Useful for overlay applications.
    RouteFromRootWindow     = 17,  // Option: route evaluated from the point of view of root window rather than current window.

    // Flags for SetNextItemShortcut()
    Tooltip                 = 18,  // Automatically display a tooltip when hovering item [BETA] Unsure of right api (opt-in/opt-out)
};

// Configuration flags stored in io.ConfigFlags. Set by user/application.
ImGuiConfigFlags :: bit_set[ImGuiConfigFlag; i32]
ImGuiConfigFlag :: enum
{
    // [removed] -> nil: None                   = 0,
    NavEnableKeyboard      = 0,   // Master keyboard navigation enable flag. Enable full Tabbing + directional arrows + space/enter to activate.
    NavEnableGamepad       = 1,   // Master gamepad navigation enable flag. Backend also needs to set ImGuiBackendFlags_HasGamepad.
    NoMouse                = 4,   // Instruct dear imgui to disable mouse inputs and interactions.
    NoMouseCursorChange    = 5,   // Instruct backend to not alter mouse cursor shape and visibility. Use if the backend cursor changes are interfering with yours and you don't want to use SetMouseCursor() to change mouse cursor. You may want to honor requests from imgui by reading GetMouseCursor() yourself instead.
    NoKeyboard             = 6,   // Instruct dear imgui to disable keyboard inputs and interactions. This is done by ignoring keyboard events and clearing existing states.

    // [BETA] Docking
    DockingEnable          = 7,   // Docking enable flags.

    // [BETA] Viewports
    // When using viewports it is recommended that your default value for ImGuiCol_WindowBg is opaque (Alpha=1.0) so transition to a viewport won't be noticeable.
    ViewportsEnable        = 10,  // Viewport enable flags (require both ImGuiBackendFlags_PlatformHasViewports + ImGuiBackendFlags_RendererHasViewports set by the respective backends)
    DpiEnableScaleViewports= 14,  // [BETA: Don't use] FIXME-DPI: Reposition and resize imgui windows when the DpiScale of a viewport changed (mostly useful for the main viewport hosting other window). Note that resizing the main window itself is up to your application.
    DpiEnableScaleFonts    = 15,  // [BETA: Don't use] FIXME-DPI: Request bitmap-scaled fonts to match DpiScale. This is a very low-quality workaround. The correct way to handle DPI is _currently_ to replace the atlas and/or fonts in the Platform_OnChangedViewport callback, but this is all early work in progress.

    // User storage (to allow your backend/engine to communicate to code that may be shared between multiple projects. Those flags are NOT used by core Dear ImGui)
    IsSRGB                 = 20,  // Application is SRGB-aware.
    IsTouchScreen          = 21,  // Application is using a touch screen instead of a mouse.

};

// Backend capabilities flags stored in io.BackendFlags. Set by imgui_impl_xxx or custom backend.
ImGuiBackendFlags :: bit_set[ImGuiBackendFlag; i32]
ImGuiBackendFlag :: enum
{
    // [removed] -> nil: None                  = 0,
    HasGamepad            = 0,   // Backend Platform supports gamepad and currently has one connected.
    HasMouseCursors       = 1,   // Backend Platform supports honoring GetMouseCursor() value to change the OS cursor shape.
    HasSetMousePos        = 2,   // Backend Platform supports io.WantSetMousePos requests to reposition the OS mouse position (only used if io.ConfigNavMoveSetMousePos is set).
    RendererHasVtxOffset  = 3,   // Backend Renderer supports ImDrawCmd::VtxOffset. This enables output of large meshes (64K+ vertices) while still using 16-bit indices.

    // [BETA] Viewports
    PlatformHasViewports  = 10,  // Backend Platform supports multiple viewports.
    HasMouseHoveredViewport=11,  // Backend Platform supports calling io.AddMouseViewportEvent() with the viewport under the mouse. IF POSSIBLE, ignore viewports with the ImGuiViewportFlags_NoInputs flag (Win32 backend, GLFW 3.30+ backend can do this, SDL backend cannot). If this cannot be done, Dear ImGui needs to use a flawed heuristic to find the viewport under.
    RendererHasViewports  = 12,  // Backend Renderer supports multiple viewports.
};

// Enumeration for PushStyleColor() / PopStyleColor()
ImGuiCol_ :: enum i32
{
    Text,
    TextDisabled,
    WindowBg,              // Background of normal windows
    ChildBg,               // Background of child windows
    PopupBg,               // Background of popups, menus, tooltips windows
    Border,
    BorderShadow,
    FrameBg,               // Background of checkbox, radio button, plot, slider, text input
    FrameBgHovered,
    FrameBgActive,
    TitleBg,               // Title bar
    TitleBgActive,         // Title bar when focused
    TitleBgCollapsed,      // Title bar when collapsed
    MenuBarBg,
    ScrollbarBg,
    ScrollbarGrab,
    ScrollbarGrabHovered,
    ScrollbarGrabActive,
    CheckMark,             // Checkbox tick and RadioButton circle
    SliderGrab,
    SliderGrabActive,
    Button,
    ButtonHovered,
    ButtonActive,
    Header,                // Header* colors are used for CollapsingHeader, TreeNode, Selectable, MenuItem
    HeaderHovered,
    HeaderActive,
    Separator,
    SeparatorHovered,
    SeparatorActive,
    ResizeGrip,            // Resize grip in lower-right and lower-left corners of windows.
    ResizeGripHovered,
    ResizeGripActive,
    TabHovered,            // Tab background, when hovered
    Tab,                   // Tab background, when tab-bar is focused & tab is unselected
    TabSelected,           // Tab background, when tab-bar is focused & tab is selected
    TabSelectedOverline,   // Tab horizontal overline, when tab-bar is focused & tab is selected
    TabDimmed,             // Tab background, when tab-bar is unfocused & tab is unselected
    TabDimmedSelected,     // Tab background, when tab-bar is unfocused & tab is selected
    TabDimmedSelectedOverline,//..horizontal overline, when tab-bar is unfocused & tab is selected
    DockingPreview,        // Preview overlay color when about to docking something
    DockingEmptyBg,        // Background color for empty node (e.g. CentralNode with no window docked into it)
    PlotLines,
    PlotLinesHovered,
    PlotHistogram,
    PlotHistogramHovered,
    TableHeaderBg,         // Table header background
    TableBorderStrong,     // Table outer and header borders (prefer using Alpha=1.0 here)
    TableBorderLight,      // Table inner borders (prefer using Alpha=1.0 here)
    TableRowBg,            // Table row background (even rows)
    TableRowBgAlt,         // Table row background (odd rows)
    TextLink,              // Hyperlink color
    TextSelectedBg,
    DragDropTarget,        // Rectangle highlighting a drop target
    NavCursor,             // Color of keyboard/gamepad navigation cursor/rectangle, when visible
    NavWindowingHighlight, // Highlight window when using CTRL+TAB
    NavWindowingDimBg,     // Darken/colorize entire screen behind the CTRL+TAB window list, when active
    ModalWindowDimBg,      // Darken/colorize entire screen behind a modal window, when one is active
    _COUNT,

};

// Enumeration for PushStyleVar() / PopStyleVar() to temporarily modify the ImGuiStyle structure.
// - The enum only refers to fields of ImGuiStyle which makes sense to be pushed/popped inside UI code.
//   During initialization or between frames, feel free to just poke into ImGuiStyle directly.
// - Tip: Use your programming IDE navigation facilities on the names in the _second column_ below to find the actual members and their description.
//   - In Visual Studio: CTRL+comma ("Edit.GoToAll") can follow symbols inside comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
//   - In Visual Studio w/ Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols inside comments.
//   - In VS Code, CLion, etc.: CTRL+click can follow symbols inside comments.
// - When changing this enum, you need to update the associated internal table GStyleVarInfo[] accordingly. This is where we link enum values to members offset/type.
ImGuiStyleVar_ :: enum i32
{
    // Enum name -------------------------- // Member in ImGuiStyle structure (see ImGuiStyle for descriptions)
    Alpha,                    // float     Alpha
    DisabledAlpha,            // float     DisabledAlpha
    WindowPadding,            // ImVec2    WindowPadding
    WindowRounding,           // float     WindowRounding
    WindowBorderSize,         // float     WindowBorderSize
    WindowMinSize,            // ImVec2    WindowMinSize
    WindowTitleAlign,         // ImVec2    WindowTitleAlign
    ChildRounding,            // float     ChildRounding
    ChildBorderSize,          // float     ChildBorderSize
    PopupRounding,            // float     PopupRounding
    PopupBorderSize,          // float     PopupBorderSize
    FramePadding,             // ImVec2    FramePadding
    FrameRounding,            // float     FrameRounding
    FrameBorderSize,          // float     FrameBorderSize
    ItemSpacing,              // ImVec2    ItemSpacing
    ItemInnerSpacing,         // ImVec2    ItemInnerSpacing
    IndentSpacing,            // float     IndentSpacing
    CellPadding,              // ImVec2    CellPadding
    ScrollbarSize,            // float     ScrollbarSize
    ScrollbarRounding,        // float     ScrollbarRounding
    GrabMinSize,              // float     GrabMinSize
    GrabRounding,             // float     GrabRounding
    TabRounding,              // float     TabRounding
    TabBorderSize,            // float     TabBorderSize
    TabBarBorderSize,         // float     TabBarBorderSize
    TabBarOverlineSize,       // float     TabBarOverlineSize
    TableAngledHeadersAngle,  // float     TableAngledHeadersAngle
    TableAngledHeadersTextAlign,// ImVec2  TableAngledHeadersTextAlign
    ButtonTextAlign,          // ImVec2    ButtonTextAlign
    SelectableTextAlign,      // ImVec2    SelectableTextAlign
    SeparatorTextBorderSize,  // float     SeparatorTextBorderSize
    SeparatorTextAlign,       // ImVec2    SeparatorTextAlign
    SeparatorTextPadding,     // ImVec2    SeparatorTextPadding
    DockingSeparatorSize,     // float     DockingSeparatorSize
    _COUNT,
};

// Flags for InvisibleButton() [extended in imgui_internal.h]
ImGuiButtonFlags :: bit_set[ImGuiButtonFlag; i32]
ImGuiButtonFlag :: enum
{
    // [removed] -> nil: None                   = 0,
    MouseButtonLeft        = 0,   // React on left mouse button (default)
    MouseButtonRight       = 1,   // React on right mouse button
    MouseButtonMiddle      = 2,   // React on center mouse button
    // [moved] MouseButtonMask_       = MouseButtonLeft | MouseButtonRight | MouseButtonMiddle, // [Internal]
    EnableNav              = 3,   // InvisibleButton(): do not disable navigation/tabbing. Otherwise disabled by default.
};
ImGuiButtonFlags_MouseButtonMask_ :: { MouseButtonLeft , MouseButtonRight , MouseButtonMiddle }

// Flags for ColorEdit3() / ColorEdit4() / ColorPicker3() / ColorPicker4() / ColorButton()
ImGuiColorEditFlags :: bit_set[ImGuiColorEditFlag; i32]
ImGuiColorEditFlag :: enum
{
    // [removed] -> nil: None            = 0,
    NoAlpha         = 1,   //              // ColorEdit, ColorPicker, ColorButton: ignore Alpha component (will only read 3 components from the input pointer).
    NoPicker        = 2,   //              // ColorEdit: disable picker when clicking on color square.
    NoOptions       = 3,   //              // ColorEdit: disable toggling options menu when right-clicking on inputs/small preview.
    NoSmallPreview  = 4,   //              // ColorEdit, ColorPicker: disable color square preview next to the inputs. (e.g. to show only the inputs)
    NoInputs        = 5,   //              // ColorEdit, ColorPicker: disable inputs sliders/text widgets (e.g. to show only the small preview color square).
    NoTooltip       = 6,   //              // ColorEdit, ColorPicker, ColorButton: disable tooltip when hovering the preview.
    NoLabel         = 7,   //              // ColorEdit, ColorPicker: disable display of inline text label (the label is still forwarded to the tooltip and picker).
    NoSidePreview   = 8,   //              // ColorPicker: disable bigger color preview on right side of the picker, use small color square preview instead.
    NoDragDrop      = 9,   //              // ColorEdit: disable drag and drop target. ColorButton: disable drag and drop source.
    NoBorder        = 10,  //              // ColorButton: disable border (which is enforced by default)

    // User Options (right-click on widget to change some of them).
    AlphaBar        = 16,  //              // ColorEdit, ColorPicker: show vertical alpha bar/gradient in picker.
    AlphaPreview    = 17,  //              // ColorEdit, ColorPicker, ColorButton: display preview as a transparent color over a checkerboard, instead of opaque.
    AlphaPreviewHalf= 18,  //              // ColorEdit, ColorPicker, ColorButton: display half opaque / half checkerboard, instead of opaque.
    HDR             = 19,  //              // (WIP) ColorEdit: Currently only disable 0.0f..1.0f limits in RGBA edition (note: you probably want to use ImGuiColorEditFlags_Float flag as well).
    DisplayRGB      = 20,  // [Display]    // ColorEdit: override _display_ type among RGB/HSV/Hex. ColorPicker: select any combination using one or more of RGB/HSV/Hex.
    DisplayHSV      = 21,  // [Display]    // "
    DisplayHex      = 22,  // [Display]    // "
    Uint8           = 23,  // [DataType]   // ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0..255.
    Float           = 24,  // [DataType]   // ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0.0f..1.0f floats instead of 0..255 integers. No round-trip of value via integers.
    PickerHueBar    = 25,  // [Picker]     // ColorPicker: bar for Hue, rectangle for Sat/Value.
    PickerHueWheel  = 26,  // [Picker]     // ColorPicker: wheel for Hue, triangle for Sat/Value.
    InputRGB        = 27,  // [Input]      // ColorEdit, ColorPicker: input and output data in RGB format.
    InputHSV        = 28,  // [Input]      // ColorEdit, ColorPicker: input and output data in HSV format.

    // Defaults Options. You can set application defaults using SetColorEditOptions(). The intent is that you probably don't want to
    // override them in most of your calls. Let the user choose via the option menu and/or call SetColorEditOptions() once during startup.
    // [moved] DefaultOptions_ = Uint8 | DisplayRGB | InputRGB | PickerHueBar,

    // [Internal] Masks
    // [moved] DisplayMask_    = DisplayRGB | DisplayHSV | DisplayHex,
    // [moved] DataTypeMask_   = Uint8 | Float,
    // [moved] PickerMask_     = PickerHueWheel | PickerHueBar,
    // [moved] InputMask_      = InputRGB | InputHSV,

    // Obsolete names
    //ImGuiColorEditFlags_RGB = ImGuiColorEditFlags_DisplayRGB, ImGuiColorEditFlags_HSV = ImGuiColorEditFlags_DisplayHSV, ImGuiColorEditFlags_HEX = ImGuiColorEditFlags_DisplayHex  // [renamed in 1.69]
};
ImGuiColorEditFlags_DefaultOptions_ :: { Uint8 , DisplayRGB , InputRGB , PickerHueBar }
ImGuiColorEditFlags_DisplayMask_ :: { DisplayRGB , DisplayHSV , DisplayHex }
ImGuiColorEditFlags_DataTypeMask_ :: { Uint8 , Float }
ImGuiColorEditFlags_PickerMask_ :: { PickerHueWheel , PickerHueBar }
ImGuiColorEditFlags_InputMask_ :: { InputRGB , InputHSV }

// Flags for DragFloat(), DragInt(), SliderFloat(), SliderInt() etc.
// We use the same sets of flags for DragXXX() and SliderXXX() functions as the features are the same and it makes it easier to swap them.
// (Those are per-item flags. There is shared behavior flag too: ImGuiIO: io.ConfigDragClickToInputText)
ImGuiSliderFlags :: bit_set[ImGuiSliderFlag; i32]
ImGuiSliderFlag :: enum
{
    // [removed] -> nil: None               = 0,
    Logarithmic        = 5,       // Make the widget logarithmic (linear otherwise). Consider using ImGuiSliderFlags_NoRoundToFormat with this if using a format-string with small amount of digits.
    NoRoundToFormat    = 6,       // Disable rounding underlying value to match precision of the display format string (e.g. %.3f values are rounded to those 3 digits).
    NoInput            = 7,       // Disable CTRL+Click or Enter key allowing to input text directly into the widget.
    WrapAround         = 8,       // Enable wrapping around from max to min and from min to max. Only supported by DragXXX() functions for now.
    ClampOnInput       = 9,       // Clamp value to min/max bounds when input manually with CTRL+Click. By default CTRL+Click allows going out of bounds.
    ClampZeroRange     = 10,      // Clamp even if min==max==0.0f. Otherwise due to legacy reason DragXXX functions don't clamp with those values. When your clamping limits are dynamic you almost always want to use it.
    NoSpeedTweaks      = 11,      // Disable keyboard modifiers altering tweak speed. Useful if you want to alter tweak speed yourself based on your own logic.
    // [moved] AlwaysClamp        = ClampOnInput | ClampZeroRange,
    // [moved] InvalidMask_       = 0x7000000F,   // [Internal] We treat using those bits as being potentially a 'float power' argument from the previous API that has got miscast to this enum, and will trigger an assert if needed.
};
ImGuiSliderFlags_AlwaysClamp :: { ClampOnInput , ClampZeroRange }
ImGuiSliderFlags_InvalidMask_ :: { 0x7000000F }

// Identify a mouse button.
// Those values are guaranteed to be stable and we frequently use 0/1 directly. Named enums provided for convenience.
ImGuiMouseButton_ :: enum i32
{
    Left = 0,
    Right = 1,
    Middle = 2,
    COUNT = 5
};

// Enumeration for GetMouseCursor()
// User code may request backend to display given cursor by calling SetMouseCursor(), which is why we have some cursors that are marked unused here
ImGuiMouseCursor_ :: enum i32
{
    // [removed] -> nil: None = -1,
    Arrow = 0,
    TextInput,         // When hovering over InputText, etc.
    ResizeAll,         // (Unused by Dear ImGui functions)
    ResizeNS,          // When hovering over a horizontal border
    ResizeEW,          // When hovering over a vertical border or a column
    ResizeNESW,        // When hovering over the bottom-left corner of a window
    ResizeNWSE,        // When hovering over the bottom-right corner of a window
    Hand,              // (Unused by Dear ImGui functions. Use for e.g. hyperlinks)
    NotAllowed,        // When hovering something with disallowed interaction. Usually a crossed circle.
    _COUNT,
};

// Enumeration for AddMouseSourceEvent() actual source of Mouse Input data.
// Historically we use "Mouse" terminology everywhere to indicate pointer data, e.g. MousePos, IsMousePressed(), io.AddMousePosEvent()
// But that "Mouse" data can come from different source which occasionally may be useful for application to know about.
// You can submit a change of pointer type using io.AddMouseSourceEvent().
ImGuiMouseSource :: enum i32
{
    ImGuiMouseSource_Mouse = 0,         // Input is coming from an actual mouse.
    ImGuiMouseSource_TouchScreen,       // Input is coming from a touch screen (no hovering prior to initial press, less precise initial press aiming, dual-axis wheeling possible).
    ImGuiMouseSource_Pen,               // Input is coming from a pressure/magnetic pen (often used in conjunction with high-sampling rates).
    ImGuiMouseSource_COUNT
};

// Enumeration for ImGui::SetNextWindow***(), SetWindow***(), SetNextItem***() functions
// Represent a condition.
// Important: Treat as a regular enum! Do NOT combine multiple values using binary operators! All the functions above treat 0 as a shortcut to ImGuiCond_Always.
ImGuiCond_ :: enum i32
{
    // [removed] -> nil: None          = 0,        // No condition (always set the variable), same as _Always
    Always        = 1 << 0,   // No condition (always set the variable), same as _None
    Once          = 1 << 1,   // Set the variable once per runtime session (only the first call will succeed)
    FirstUseEver  = 1 << 2,   // Set the variable if the object/window has no persistently saved data (no entry in .ini file)
    Appearing     = 1 << 3,   // Set the variable if the object/window is appearing after being hidden/inactive (or the first time)
};

//-----------------------------------------------------------------------------
// [SECTION] Tables API flags and structures (ImGuiTableFlags, ImGuiTableColumnFlags, ImGuiTableRowFlags, ImGuiTableBgTarget, ImGuiTableSortSpecs, ImGuiTableColumnSortSpecs)
//-----------------------------------------------------------------------------

// Flags for ImGui::BeginTable()
// - Important! Sizing policies have complex and subtle side effects, much more so than you would expect.
//   Read comments/demos carefully + experiment with live demos to get acquainted with them.
// - The DEFAULT sizing policies are:
//    - Default to ImGuiTableFlags_SizingFixedFit    if ScrollX is on, or if host window has ImGuiWindowFlags_AlwaysAutoResize.
//    - Default to ImGuiTableFlags_SizingStretchSame if ScrollX is off.
// - When ScrollX is off:
//    - Table defaults to ImGuiTableFlags_SizingStretchSame -> all Columns defaults to ImGuiTableColumnFlags_WidthStretch with same weight.
//    - Columns sizing policy allowed: Stretch (default), Fixed/Auto.
//    - Fixed Columns (if any) will generally obtain their requested width (unless the table cannot fit them all).
//    - Stretch Columns will share the remaining width according to their respective weight.
//    - Mixed Fixed/Stretch columns is possible but has various side-effects on resizing behaviors.
//      The typical use of mixing sizing policies is: any number of LEADING Fixed columns, followed by one or two TRAILING Stretch columns.
//      (this is because the visible order of columns have subtle but necessary effects on how they react to manual resizing).
// - When ScrollX is on:
//    - Table defaults to ImGuiTableFlags_SizingFixedFit -> all Columns defaults to ImGuiTableColumnFlags_WidthFixed
//    - Columns sizing policy allowed: Fixed/Auto mostly.
//    - Fixed Columns can be enlarged as needed. Table will show a horizontal scrollbar if needed.
//    - When using auto-resizing (non-resizable) fixed columns, querying the content width to use item right-alignment e.g. SetNextItemWidth(-FLT_MIN) doesn't make sense, would create a feedback loop.
//    - Using Stretch columns OFTEN DOES NOT MAKE SENSE if ScrollX is on, UNLESS you have specified a value for 'inner_width' in BeginTable().
//      If you specify a value for 'inner_width' then effectively the scrolling space is known and Stretch or mixed Fixed/Stretch columns become meaningful again.
// - Read on documentation at the top of imgui_tables.cpp for details.
ImGuiTableFlags :: bit_set[ImGuiTableFlag; i32]
ImGuiTableFlag :: enum
{
    // Features
    // [removed] -> nil: None                       = 0,
    Resizable                  = 0,   // Enable resizing columns.
    Reorderable                = 1,   // Enable reordering columns in header row (need calling TableSetupColumn() + TableHeadersRow() to display headers)
    Hideable                   = 2,   // Enable hiding/disabling columns in context menu.
    Sortable                   = 3,   // Enable sorting. Call TableGetSortSpecs() to obtain sort specs. Also see ImGuiTableFlags_SortMulti and ImGuiTableFlags_SortTristate.
    NoSavedSettings            = 4,   // Disable persisting columns order, width and sort settings in the .ini file.
    ContextMenuInBody          = 5,   // Right-click on columns body/contents will display table context menu. By default it is available in TableHeadersRow().
    // Decorations
    RowBg                      = 6,   // Set each RowBg color with ImGuiCol_TableRowBg or ImGuiCol_TableRowBgAlt (equivalent of calling TableSetBgColor with ImGuiTableBgFlags_RowBg0 on each row manually)
    BordersInnerH              = 7,   // Draw horizontal borders between rows.
    BordersOuterH              = 8,   // Draw horizontal borders at the top and bottom.
    BordersInnerV              = 9,   // Draw vertical borders between columns.
    BordersOuterV              = 10,  // Draw vertical borders on the left and right sides.
    // [moved] BordersH                   = BordersInnerH | BordersOuterH, // Draw horizontal borders.
    // [moved] BordersV                   = BordersInnerV | BordersOuterV, // Draw vertical borders.
    // [moved] BordersInner               = BordersInnerV | BordersInnerH, // Draw inner borders.
    // [moved] BordersOuter               = BordersOuterV | BordersOuterH, // Draw outer borders.
    // [moved] Borders                    = BordersInner | BordersOuter,   // Draw all borders.
    NoBordersInBody            = 11,  // [ALPHA] Disable vertical borders in columns Body (borders will always appear in Headers). -> May move to style
    NoBordersInBodyUntilResize = 12,  // [ALPHA] Disable vertical borders in columns Body until hovered for resize (borders will always appear in Headers). -> May move to style
    // Sizing Policy (read above for defaults)
    SizingFixedFit             = 13,  // Columns default to _WidthFixed or _WidthAuto (if resizable or not resizable), matching contents width.
    SizingFixedSame            = 13,  // Columns default to _WidthFixed or _WidthAuto (if resizable or not resizable), matching the maximum contents width of all columns. Implicitly enable ImGuiTableFlags_NoKeepColumnsVisible.
    SizingStretchProp          = 13,  // Columns default to _WidthStretch with default weights proportional to each columns contents widths.
    SizingStretchSame          = 13,  // Columns default to _WidthStretch with default weights all equal, unless overridden by TableSetupColumn().
    // Sizing Extra Options
    NoHostExtendX              = 16,  // Make outer width auto-fit to columns, overriding outer_size.x value. Only available when ScrollX/ScrollY are disabled and Stretch columns are not used.
    NoHostExtendY              = 17,  // Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit). Only available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.
    NoKeepColumnsVisible       = 18,  // Disable keeping column always minimally visible when ScrollX is off and table gets too small. Not recommended if columns are resizable.
    PreciseWidths              = 19,  // Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.
    // Clipping
    NoClip                     = 20,  // Disable clipping rectangle for every individual columns (reduce draw command count, items will be able to overflow into other columns). Generally incompatible with TableSetupScrollFreeze().
    // Padding
    PadOuterX                  = 21,  // Default if BordersOuterV is on. Enable outermost padding. Generally desirable if you have headers.
    NoPadOuterX                = 22,  // Default if BordersOuterV is off. Disable outermost padding.
    NoPadInnerX                = 23,  // Disable inner padding between columns (double inner padding if BordersOuterV is on, single inner padding if BordersOuterV is off).
    // Scrolling
    ScrollX                    = 24,  // Enable horizontal scrolling. Require 'outer_size' parameter of BeginTable() to specify the container size. Changes default sizing policy. Because this creates a child window, ScrollY is currently generally recommended when using ScrollX.
    ScrollY                    = 25,  // Enable vertical scrolling. Require 'outer_size' parameter of BeginTable() to specify the container size.
    // Sorting
    SortMulti                  = 26,  // Hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).
    SortTristate               = 27,  // Allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).
    // Miscellaneous
    HighlightHoveredColumn     = 28,  // Highlight column headers when hovered (may evolve into a fuller highlight)

    // [Internal] Combinations and masks
    // [moved] SizingMask_                = SizingFixedFit | SizingFixedSame | SizingStretchProp | SizingStretchSame,
};
ImGuiTableFlags_BordersH :: { BordersInnerH , BordersOuterH }
ImGuiTableFlags_BordersV :: { BordersInnerV , BordersOuterV }
ImGuiTableFlags_BordersInner :: { BordersInnerV , BordersInnerH }
ImGuiTableFlags_BordersOuter :: { BordersOuterV , BordersOuterH }
ImGuiTableFlags_Borders :: { BordersInner , BordersOuter }
ImGuiTableFlags_SizingMask_ :: { SizingFixedFit , SizingFixedSame , SizingStretchProp , SizingStretchSame }

// Flags for ImGui::TableSetupColumn()
ImGuiTableColumnFlags :: bit_set[ImGuiTableColumnFlag; i32]
ImGuiTableColumnFlag :: enum
{
    // Input configuration flags
    // [removed] -> nil: None                  = 0,
    Disabled              = 0,   // Overriding/master disable flag: hide column, won't show in context menu (unlike calling TableSetColumnEnabled() which manipulates the user accessible state)
    DefaultHide           = 1,   // Default as a hidden/disabled column.
    DefaultSort           = 2,   // Default as a sorting column.
    WidthStretch          = 3,   // Column will stretch. Preferable with horizontal scrolling disabled (default if table sizing policy is _SizingStretchSame or _SizingStretchProp).
    WidthFixed            = 4,   // Column will not stretch. Preferable with horizontal scrolling enabled (default if table sizing policy is _SizingFixedFit and table is resizable).
    NoResize              = 5,   // Disable manual resizing.
    NoReorder             = 6,   // Disable manual reordering this column, this will also prevent other columns from crossing over this column.
    NoHide                = 7,   // Disable ability to hide/disable this column.
    NoClip                = 8,   // Disable clipping for this column (all NoClip columns will render in a same draw command).
    NoSort                = 9,   // Disable ability to sort on this field (even if ImGuiTableFlags_Sortable is set on the table).
    NoSortAscending       = 10,  // Disable ability to sort in the ascending direction.
    NoSortDescending      = 11,  // Disable ability to sort in the descending direction.
    NoHeaderLabel         = 12,  // TableHeadersRow() will submit an empty label for this column. Convenient for some small columns. Name will still appear in context menu or in angled headers. You may append into this cell by calling TableSetColumnIndex() right after the TableHeadersRow() call.
    NoHeaderWidth         = 13,  // Disable header text width contribution to automatic column width.
    PreferSortAscending   = 14,  // Make the initial sort direction Ascending when first sorting on this column (default).
    PreferSortDescending  = 15,  // Make the initial sort direction Descending when first sorting on this column.
    IndentEnable          = 16,  // Use current Indent value when entering cell (default for column 0).
    IndentDisable         = 17,  // Ignore current Indent value when entering cell (default for columns > 0). Indentation changes _within_ the cell will still be honored.
    AngledHeader          = 18,  // TableHeadersRow() will submit an angled header row for this column. Note this will add an extra row.

    // Output status flags, read-only via TableGetColumnFlags()
    IsEnabled             = 24,  // Status: is enabled == not hidden by user/api (referred to as "Hide" in _DefaultHide and _NoHide) flags.
    IsVisible             = 25,  // Status: is visible == is enabled AND not clipped by scrolling.
    IsSorted              = 26,  // Status: is currently part of the sort specs
    IsHovered             = 27,  // Status: is hovered by mouse

    // [Internal] Combinations and masks
    // [moved] WidthMask_            = WidthStretch | WidthFixed,
    // [moved] IndentMask_           = IndentEnable | IndentDisable,
    // [moved] StatusMask_           = IsEnabled | IsVisible | IsSorted | IsHovered,
    NoDirectResize_       = 30,  // [Internal] Disable user resizing this column directly (it may however we resized indirectly from its left edge)
};
ImGuiTableColumnFlags_WidthMask_ :: { WidthStretch , WidthFixed }
ImGuiTableColumnFlags_IndentMask_ :: { IndentEnable , IndentDisable }
ImGuiTableColumnFlags_StatusMask_ :: { IsEnabled , IsVisible , IsSorted , IsHovered }

// Flags for ImGui::TableNextRow()
ImGuiTableRowFlags :: bit_set[ImGuiTableRowFlag; i32]
ImGuiTableRowFlag :: enum
{
    // [removed] -> nil: None                     = 0,
    Headers                  = 0,   // Identify header row (set default background color + width of its contents accounted differently for auto column width)
};

// Enum for ImGui::TableSetBgColor()
// Background colors are rendering in 3 layers:
//  - Layer 0: draw with RowBg0 color if set, otherwise draw with ColumnBg0 if set.
//  - Layer 1: draw with RowBg1 color if set, otherwise draw with ColumnBg1 if set.
//  - Layer 2: draw with CellBg color if set.
// The purpose of the two row/columns layers is to let you decide if a background color change should override or blend with the existing color.
// When using ImGuiTableFlags_RowBg on the table, each row has the RowBg0 color automatically set for odd/even rows.
// If you set the color of RowBg0 target, your color will override the existing RowBg0 color.
// If you set the color of RowBg1 or ColumnBg1 target, your color will blend over the RowBg0 color.
ImGuiTableBgTarget_ :: enum i32
{
    // [removed] -> nil: None                     = 0,
    RowBg0                   = 1,        // Set row background color 0 (generally used for background, automatically set when ImGuiTableFlags_RowBg is used)
    RowBg1                   = 2,        // Set row background color 1 (generally used for selection marking)
    CellBg                   = 3,        // Set cell background color (top-most color)
};

// Sorting specifications for a table (often handling sort specs for a single column, occasionally more)
// Obtained by calling TableGetSortSpecs().
// When 'SpecsDirty == true' you can sort your data. It will be true with sorting specs have changed since last call, or the first time.
// Make sure to set 'SpecsDirty = false' after sorting, else you may wastefully sort your data every frame!
ImGuiTableSortSpecs :: struct
{
    Specs : ^ImGuiTableColumnSortSpecs,     // Pointer to sort spec array.
    SpecsCount : i32,     // Sort spec count. Most often 1. May be > 1 when ImGuiTableFlags_SortMulti is enabled. May be == 0 when ImGuiTableFlags_SortTristate is enabled.
    SpecsDirty : bool,     // Set to true when specs have changed since last time! Use this to sort again, then clear the flag.

    ImGuiTableSortSpecs()       { memset(this, 0, size_of(*this)); }
};

// Sorting specification for one column of a table (sizeof == 12 bytes)
ImGuiTableColumnSortSpecs :: struct
{
    ColumnUserID : ImGuiID,       // User id of the column (if specified by a TableSetupColumn() call)
    ColumnIndex : u16,        // Index of the column
    SortOrder : u16,          // Index within parent ImGuiTableSortSpecs (always stored in order starting from 0, tables sorted on a single criteria will always have a 0 here)
    SortDirection : ImGuiSortDirection,      // ImGuiSortDirection_Ascending or ImGuiSortDirection_Descending

    ImGuiTableColumnSortSpecs() { memset(this, 0, size_of(*this)); }
};

//-----------------------------------------------------------------------------
// [SECTION] Helpers: Debug log, memory allocations macros, ImVector<>
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Debug Logging into ShowDebugLogWindow(), tty and more.
//-----------------------------------------------------------------------------

when !(IMGUI_DISABLE_DEBUG_TOOLS) {
#define IMGUI_DEBUG_LOG(...)        ImGui::DebugLog(__VA_ARGS__)
} else {
#define IMGUI_DEBUG_LOG(...)        ((void)0)
}

//-----------------------------------------------------------------------------
// IM_MALLOC(), IM_FREE(), IM_NEW(), IM_PLACEMENT_NEW(), IM_DELETE()
// We call C++ constructor on own allocated memory via the placement "new(ptr) Type()" syntax.
// Defining a custom placement new() with a custom parameter allows us to bypass including <new> which on some platforms complains when user has disabled exceptions.
//-----------------------------------------------------------------------------

struct ImNewWrapper {};
inline rawptr operator new(int, ImNewWrapper, rawptr ptr) { return ptr; }
inline void  operator delete(rawptr, ImNewWrapper, rawptr)   {} // This is only required so we can use the symmetrical new()
#define IM_ALLOC(_SIZE)                     ImGui::MemAlloc(_SIZE)
#define IM_FREE(_PTR)                       ImGui::MemFree(_PTR)
#define IM_PLACEMENT_NEW(_PTR)              new(ImNewWrapper(), _PTR)
#define IM_NEW(_TYPE)                       new(ImNewWrapper(), ImGui::MemAlloc(sizeof(_TYPE))) _TYPE
template<typename T> void IM_DELETE(T* p)   { if (p) { p->~T(); MemFree(p); } }

//-----------------------------------------------------------------------------
// ImVector<>
// Lightweight std::vector<>-like class to avoid dragging dependencies (also, some implementations of STL with debug enabled are absurdly slow, we bypass it so our code runs fast in debug).
//-----------------------------------------------------------------------------
// - You generally do NOT need to care or use this ever. But we need to make it available in imgui.h because some of our public structures are relying on it.
// - We use std-like naming convention here, which is a little unusual for this codebase.
// - Important: clear() frees memory, resize(0) keep the allocated buffer. We use resize(0) a lot to intentionally recycle allocated buffers across frames and amortize our costs.
// - Important: our implementation does NOT call C++ constructors/destructors, we treat everything as raw data! This is intentional but be extra mindful of that,
//   Do NOT use this class as a std::vector replacement in your own code! Many of the structures used by dear imgui can be safely initialized by a zero-memset.
//-----------------------------------------------------------------------------

template<typename T>
ImVector :: struct
{
    Size : i32,
    Capacity : i32,
    Data : ^T,

    // Provide standard typedefs but we don't use them ourselves.
    value_type :: T
    iterator :: ^value_type
    const_iterator :: ^const value_type

    // Constructors, destructor
    inline ImVector()                                       { Size = Capacity = 0; Data = nil; }
    inline ImVector(const ImVector<T>& src)                 { Size = Capacity = 0; Data = nil; operator=(src); }
    inline ImVector<T>& operator=(const ImVector<T>& src)   { clear(); resize(src.Size); if (src.Data) memcpy(Data, src.Data, cast(ast) ast) ast)ze_of(T)); return *this; }
    inline ~ImVector()                                      { if (Data) IM_FREE(Data); } // Important: does not destruct anything

    inline void         clear()                             { if (Data) { Size = Capacity = 0; IM_FREE(Data); Data = nil; } }  // Important: does not destruct anything
    inline void         clear_delete()                      { for (i32 n = 0; n < Size; n++) IM_DELETE(Data[n]); clear(); }     // Important: never called automatically! always explicit.
    inline void         clear_destruct()                    { for (i32 n = 0; n < Size; n++) Data[n].~T(); clear(); }           // Important: never called automatically! always explicit.

    inline bool         empty() const                       { return Size == 0; }
    inline i32          size() const                        { return Size; }
    inline i32          size_in_bytes() const               { return Size * cast(ast) ast) oft) of}
    inline i32          max_size() const                    { return 0x7FFFFFFF / cast(ast) ast) oft) of}
    inline i32          capacity() const                    { return Capacity; }
    inline T&           operator[](i32 i)                   { assert(i >= 0 && i < Size); return Data[i]; }
    inline const T&     operator[](i32 i) const             { assert(i >= 0 && i < Size); return Data[i]; }

    inline T*           begin()                             { return Data; }
    inline const T*     begin() const                       { return Data; }
    inline T*           end()                               { return Data + Size; }
    inline const T*     end() const                         { return Data + Size; }
    inline T&           front()                             { assert(Size > 0); return Data[0]; }
    inline const T&     front() const                       { assert(Size > 0); return Data[0]; }
    inline T&           back()                              { assert(Size > 0); return Data[Size - 1]; }
    inline const T&     back() const                        { assert(Size > 0); return Data[Size - 1]; }
    inline void         swap(ImVector<T>& rhs)              { i32 rhs_size = rhs.Size; rhs.Size = Size; Size = rhs_size; i32 rhs_cap = rhs.Capacity; rhs.Capacity = Capacity; Capacity = rhs_cap; T* rhs_data = rhs.Data; rhs.Data = Data; Data = rhs_data; }

    inline i32          _grow_capacity(i32 sz) const        { i32 new_capacity = Capacity ? (Capacity + Capacity / 2) : 8; return new_capacity > sz ? new_capacity : sz; }
    inline void         resize(i32 new_size)                { if (new_size > Capacity) reserve(_grow_capacity(new_size)); Size = new_size; }
    inline void         resize(i32 new_size, const T& v)    { if (new_size > Capacity) reserve(_grow_capacity(new_size)); if (new_size > Size) for (i32 n = Size; n < new_size; n++) memcpy(&Data[n], &v, size_of(v)); Size = new_size; }
    inline void         shrink(i32 new_size)                { assert(new_size <= Size); Size = new_size; } // Resize a vector to a smaller size, guaranteed not to cause a reallocation
    inline void         reserve(i32 new_capacity)           { if (new_capacity <= Capacity) return; T* new_data = (T*)IM_ALLOC(cast(ast) ast) apacityacityze_of(T)); if (Data) { memcpy(new_data, Data, cast(ta,) cast(ta,) cast(T)); IM_FREE(Data); } Data = new_data; Capacity = new_capacity; }
    inline void         reserve_discard(i32 new_capacity)   { if (new_capacity <= Capacity) return; if (Data) IM_FREE(Data); Data = (T*)IM_ALLOC(cast(ast) ast) apacityacityze_of(T)); Capacity = new_capacity; }

    // NB: It is illegal to call push_back/push_front/insert with a reference pointing inside the ImVector data itself! e.g. v.push_back(v[10]) is forbidden.
    inline void         push_back(const T& v)               { if (Size == Capacity) reserve(_grow_capacity(Size + 1)); memcpy(&Data[Size], &v, size_of(v)); Size += 1; }
    inline void         pop_back()                          { assert(Size > 0); Size -= 1; }
    inline void         push_front(const T& v)              { if (Size == 0) push_back(v); else insert(Data, v); }
    inline T*           erase(const T* it)                  { assert(it >= Data && it < Data + Size); const ptrdiff_t off = it - Data; memmove(Data + off, Data + off + 1, (cast(ast) ast) ast)nt)off - 1) * size_of(T)); Size -= 1; return Data + off; }
    inline T*           erase(const T* it, const T* it_last){ assert(it >= Data && it < Data + Size && it_last >= it && it_last <= Data + Size); const ptrdiff_t count = it_last - it; const ptrdiff_t off = it - Data; memmove(Data + off, Data + off + count, (cast(ast) ast) ast)nt)off - cast(f -) cast(f -) cast(f(T)); Size -= cast( Si) e -= cast( Si) e -=  off; }
    inline T*           erase_unsorted(const T* it)         { assert(it >= Data && it < Data + Size);  const ptrdiff_t off = it - Data; if (it < Data + Size - 1) memcpy(Data + off, Data + Size - 1, size_of(T)); Size -= 1; return Data + off; }
    inline T*           insert(const T* it, const T& v)     { assert(it >= Data && it <= Data + Size); const ptrdiff_t off = it - Data; if (Size == Capacity) reserve(_grow_capacity(Size + 1)); if (off < cast(ast) ast) ast)move(Data + off + 1, Data + off, (cast(f, ) cast(f, ) castf) * size_of(T)); memcpy(&Data[off], &v, size_of(v)); Size += 1; return Data + off; }
    inline bool         contains(const T& v) const          { const T* data = Data;  const T* data_end = Data + Size; for (data < data_end) if (*data++ == v) return true; return false; }
    inline T*           find(const T& v)                    { T* data = Data;  const T* data_end = Data + Size; for (data < data_end) if (*data == v) break; else ++data; return data; }
    inline const T*     find(const T& v) const              { const T* data = Data;  const T* data_end = Data + Size; for (data < data_end) if (*data == v) break; else ++data; return data; }
    inline i32          find_index(const T& v) const        { const T* data_end = Data + Size; const T* it = find(v); if (it == data_end) return -1; const ptrdiff_t off = it - Data; return cast(ast) ast) a
    inline bool         find_erase(const T& v)              { const T* it = find(v); if (it < Data + Size) { erase(it); return true; } return false; }
    inline bool         find_erase_unsorted(const T& v)     { const T* it = find(v); if (it < Data + Size) { erase_unsorted(it); return true; } return false; }
    inline i32          index_from_ptr(const T* it) const   { assert(it >= Data && it < Data + Size); const ptrdiff_t off = it - Data; return cast(ast) ast) a
};

//-----------------------------------------------------------------------------
// [SECTION] ImGuiStyle
//-----------------------------------------------------------------------------
// You may modify the ImGui::GetStyle() main instance during initialization and before NewFrame().
// During the frame, use ImGui::PushStyleVar(ImGuiStyleVar_XXXX)/PopStyleVar() to alter the main style values,
// and ImGui::PushStyleColor(ImGuiCol_XXX)/PopStyleColor() for colors.
//-----------------------------------------------------------------------------

ImGuiStyle :: struct
{
    Alpha : f32,                      // Global alpha applies to everything in Dear ImGui.
    DisabledAlpha : f32,              // Additional alpha multiplier applied by BeginDisabled(). Multiply over current value of Alpha.
    WindowPadding : ImVec2,              // Padding within a window.
    WindowRounding : f32,             // Radius of window corners rounding. Set to 0.0f to have rectangular windows. Large values tend to lead to variety of artifacts and are not recommended.
    WindowBorderSize : f32,           // Thickness of border around windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
    WindowMinSize : ImVec2,              // Minimum window size. This is a global setting. If you want to constrain individual windows, use SetNextWindowSizeConstraints().
    WindowTitleAlign : ImVec2,           // Alignment for title bar text. Defaults to (0.0f,0.5f) for left-aligned,vertically centered.
    WindowMenuButtonPosition : ImGuiDir,   // Side of the collapsing/docking button in the title bar (None/Left/Right). Defaults to ImGuiDir_Left.
    ChildRounding : f32,              // Radius of child window corners rounding. Set to 0.0f to have rectangular windows.
    ChildBorderSize : f32,            // Thickness of border around child windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
    PopupRounding : f32,              // Radius of popup window corners rounding. (Note that tooltip windows use WindowRounding)
    PopupBorderSize : f32,            // Thickness of border around popup/tooltip windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
    FramePadding : ImVec2,               // Padding within a framed rectangle (used by most widgets).
    FrameRounding : f32,              // Radius of frame corners rounding. Set to 0.0f to have rectangular frame (used by most widgets).
    FrameBorderSize : f32,            // Thickness of border around frames. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
    ItemSpacing : ImVec2,                // Horizontal and vertical spacing between widgets/lines.
    ItemInnerSpacing : ImVec2,           // Horizontal and vertical spacing between within elements of a composed widget (e.g. a slider and its label).
    CellPadding : ImVec2,                // Padding within a table cell. Cellpadding.x is locked for entire table. CellPadding.y may be altered between different rows.
    TouchExtraPadding : ImVec2,          // Expand reactive bounding box for touch-based system where touch position is not accurate enough. Unfortunately we don't sort widgets so priority on overlap will always be given to the first widget. So don't grow this too much!
    IndentSpacing : f32,              // Horizontal indentation when e.g. entering a tree node. Generally == (FontSize + FramePadding.x*2).
    ColumnsMinSpacing : f32,          // Minimum horizontal spacing between two columns. Preferably > (FramePadding.x + 1).
    ScrollbarSize : f32,              // Width of the vertical scrollbar, Height of the horizontal scrollbar.
    ScrollbarRounding : f32,          // Radius of grab corners for scrollbar.
    GrabMinSize : f32,                // Minimum width/height of a grab box for slider/scrollbar.
    GrabRounding : f32,               // Radius of grabs corners rounding. Set to 0.0f to have rectangular slider grabs.
    LogSliderDeadzone : f32,          // The size in pixels of the dead-zone around zero on logarithmic sliders that cross zero.
    TabRounding : f32,                // Radius of upper corners of a tab. Set to 0.0f to have rectangular tabs.
    TabBorderSize : f32,              // Thickness of border around tabs.
    TabMinWidthForCloseButton : f32,  // Minimum width for close button to appear on an unselected tab when hovered. Set to 0.0f to always show when hovering, set to FLT_MAX to never show close button unless selected.
    TabBarBorderSize : f32,           // Thickness of tab-bar separator, which takes on the tab active color to denote focus.
    TabBarOverlineSize : f32,         // Thickness of tab-bar overline, which highlights the selected tab-bar.
    TableAngledHeadersAngle : f32,    // Angle of angled headers (supported values range from -50.0f degrees to +50.0f degrees).
    TableAngledHeadersTextAlign : ImVec2,// Alignment of angled headers within the cell
    ColorButtonPosition : ImGuiDir,        // Side of the color button in the ColorEdit4 widget (left/right). Defaults to ImGuiDir_Right.
    ButtonTextAlign : ImVec2,            // Alignment of button text when button is larger than text. Defaults to (0.5f, 0.5f) (centered).
    SelectableTextAlign : ImVec2,        // Alignment of selectable text. Defaults to (0.0f, 0.0f) (top-left aligned). It's generally important to keep this left-aligned if you want to lay multiple items on a same line.
    SeparatorTextBorderSize : f32,    // Thickness of border in SeparatorText()
    SeparatorTextAlign : ImVec2,         // Alignment of text within the separator. Defaults to (0.0f, 0.5f) (left aligned, center).
    SeparatorTextPadding : ImVec2,       // Horizontal offset of text from each edge of the separator + spacing on other axis. Generally small values. .y is recommended to be == FramePadding.y.
    DisplayWindowPadding : ImVec2,       // Apply to regular windows: amount which we enforce to keep visible when moving near edges of your screen.
    DisplaySafeAreaPadding : ImVec2,     // Apply to every windows, menus, popups, tooltips: amount where we avoid displaying contents. Adjust if you cannot see the edges of your screen (e.g. on a TV where scaling has not been configured).
    DockingSeparatorSize : f32,       // Thickness of resizing border between docked windows
    MouseCursorScale : f32,           // Scale software rendered mouse cursor (when io.MouseDrawCursor is enabled). We apply per-monitor DPI scaling over this scale. May be removed later.
    AntiAliasedLines : bool,           // Enable anti-aliased lines/borders. Disable if you are really tight on CPU/GPU. Latched at the beginning of the frame (copied to ImDrawList).
    AntiAliasedLinesUseTex : bool,     // Enable anti-aliased lines/borders using textures where possible. Require backend to render with bilinear filtering (NOT point/nearest filtering). Latched at the beginning of the frame (copied to ImDrawList).
    AntiAliasedFill : bool,            // Enable anti-aliased edges around filled shapes (rounded rectangles, circles, etc.). Disable if you are really tight on CPU/GPU. Latched at the beginning of the frame (copied to ImDrawList).
    CurveTessellationTol : f32,       // Tessellation tolerance when using PathBezierCurveTo() without a specific number of segments. Decrease for highly tessellated curves (higher quality, more polygons), increase to reduce quality.
    CircleTessellationMaxError : f32, // Maximum error (in pixels) allowed when using AddCircle()/AddCircleFilled() or drawing rounded corner rectangles with no explicit segment count specified. Decrease for higher quality but more geometry.
    Colors : [ImGuiCol_COUNT]ImVec4,

    // Behaviors
    // (It is possible to modify those fields mid-frame if specific behavior need it, unlike e.g. configuration fields in ImGuiIO)
    HoverStationaryDelay : f32,     // Delay for IsItemHovered(ImGuiHoveredFlags_Stationary). Time required to consider mouse stationary.
    HoverDelayShort : f32,          // Delay for IsItemHovered(ImGuiHoveredFlags_DelayShort). Usually used along with HoverStationaryDelay.
    HoverDelayNormal : f32,         // Delay for IsItemHovered(ImGuiHoveredFlags_DelayNormal). "
    HoverFlagsForTooltipMouse : ImGuiHoveredFlags,// Default flags when using IsItemHovered(ImGuiHoveredFlags_ForTooltip) or BeginItemTooltip()/SetItemTooltip() while using mouse.
    HoverFlagsForTooltipNav : ImGuiHoveredFlags,  // Default flags when using IsItemHovered(ImGuiHoveredFlags_ForTooltip) or BeginItemTooltip()/SetItemTooltip() while using keyboard/gamepad.

    ImGuiStyle();
    void ScaleAllSizes(f32 scale_factor);
};

//-----------------------------------------------------------------------------
// [SECTION] ImGuiIO
//-----------------------------------------------------------------------------
// Communicate most settings and inputs/outputs to Dear ImGui using this structure.
// Access via ImGui::GetIO(). Read 'Programmer guide' section in .cpp file for general usage.
// It is generally expected that:
// - initialization: backends and user code writes to ImGuiIO.
// - main loop: backends writes to ImGuiIO, user code and imgui code reads from ImGuiIO.
//-----------------------------------------------------------------------------
// Also see ImGui::GetPlatformIO() and ImGuiPlatformIO struct for OS/platform related functions: clipboard, IME etc.
//-----------------------------------------------------------------------------

// [Internal] Storage used by IsKeyDown(), IsKeyPressed() etc functions.
// If prior to 1.87 you used io.KeysDownDuration[] (which was marked as internal), you should use GetKeyData(key)->DownDuration and *NOT* io.KeysData[key]->DownDuration.
ImGuiKeyData :: struct
{
    Down : bool,               // True for if key is down
    DownDuration : f32,       // Duration the key has been down (<0.0f: not pressed, 0.0f: just pressed, >0.0f: time held)
    DownDurationPrev : f32,   // Last frame duration the key has been down
    AnalogValue : f32,        // 0.0f..1.0f for gamepad values
};

ImGuiIO :: struct
{
    //------------------------------------------------------------------
    // Configuration                            // Default value
    //------------------------------------------------------------------

    ConfigFlags : ImGuiConfigFlags,             // = 0              // See ImGuiConfigFlags_ enum. Set by user/application. Keyboard/Gamepad navigation options, etc.
    BackendFlags : ImGuiBackendFlags,            // = 0              // See ImGuiBackendFlags_ enum. Set by backend (imgui_impl_xxx files or custom backend) to communicate features supported by the backend.
    DisplaySize : ImVec2,                    // <unset>          // Main display size, in pixels (generally == GetMainViewport()->Size). May change every frame.
    DeltaTime : f32,                      // = 1.0f/60.0f     // Time elapsed since last frame, in seconds. May change every frame.
    IniSavingRate : f32,                  // = 5.0f           // Minimum time between saving positions/sizes to .ini file, in seconds.
    IniFilename : ^u8,                    // = "imgui.ini"    // Path to .ini file (important: default "imgui.ini" is relative to current working dir!). Set NULL to disable automatic .ini loading/saving or if you want to manually call LoadIniSettingsXXX() / SaveIniSettingsXXX() functions.
    LogFilename : ^u8,                    // = "imgui_log.txt"// Path to .log file (default parameter to ImGui::LogToFile when no file is specified).
    UserData : rawptr,                       // = NULL           // Store your own data.

    // Font system
    ImFontAtlas*Fonts;                          // <auto>           // Font atlas: load, rasterize and pack one or more fonts into a single texture.
    FontGlobalScale : f32,                // = 1.0f           // Global scale all fonts
    FontAllowUserScaling : bool,           // = false          // [OBSOLETE] Allow user scaling text of individual window with CTRL+Wheel.
    FontDefault : ^ImFont,                    // = NULL           // Font to use on NewFrame(). Use NULL to uses Fonts->Fonts[0].
    DisplayFramebufferScale : ImVec2,        // = (1, 1)         // For retina display or other situations where window coordinates are different from framebuffer coordinates. This generally ends up in ImDrawData::FramebufferScale.

    // Keyboard/Gamepad Navigation options
    ConfigNavSwapGamepadButtons : bool,    // = false          // Swap Activate<>Cancel (A<>B) buttons, matching typical "Nintendo/Japanese style" gamepad layout.
    ConfigNavMoveSetMousePos : bool,       // = false          // Directional/tabbing navigation teleports the mouse cursor. May be useful on TV/console systems where moving a virtual mouse is difficult. Will update io.MousePos and set io.WantSetMousePos=true.
    ConfigNavCaptureKeyboard : bool,       // = true           // Sets io.WantCaptureKeyboard when io.NavActive is set.
    ConfigNavEscapeClearFocusItem : bool,  // = true           // Pressing Escape can clear focused item + navigation id/highlight. Set to false if you want to always keep highlight on.
    ConfigNavEscapeClearFocusWindow : bool,// = false          // Pressing Escape can clear focused window as well (super set of io.ConfigNavEscapeClearFocusItem).
    ConfigNavCursorVisibleAuto : bool,     // = true           // Using directional navigation key makes the cursor visible. Mouse click hides the cursor.
    ConfigNavCursorVisibleAlways : bool,   // = false          // Navigation cursor is always visible.

    // Docking options (when ImGuiConfigFlags_DockingEnable is set)
    ConfigDockingNoSplit : bool,           // = false          // Simplified docking mode: disable window splitting, so docking is limited to merging multiple windows together into tab-bars.
    ConfigDockingWithShift : bool,         // = false          // Enable docking with holding Shift key (reduce visual noise, allows dropping in wider space)
    ConfigDockingAlwaysTabBar : bool,      // = false          // [BETA] [FIXME: This currently creates regression with auto-sizing and general overhead] Make every single floating window display within a docking node.
    ConfigDockingTransparentPayload : bool,// = false          // [BETA] Make window or viewport transparent when docking and only display docking boxes on the target viewport. Useful if rendering of multiple viewport cannot be synced. Best used with ConfigViewportsNoAutoMerge.

    // Viewport options (when ImGuiConfigFlags_ViewportsEnable is set)
    ConfigViewportsNoAutoMerge : bool,     // = false;         // Set to make all floating imgui windows always create their own viewport. Otherwise, they are merged into the main host viewports when overlapping it. May also set ImGuiViewportFlags_NoAutoMerge on individual viewport.
    ConfigViewportsNoTaskBarIcon : bool,   // = false          // Disable default OS task bar icon flag for secondary viewports. When a viewport doesn't want a task bar icon, ImGuiViewportFlags_NoTaskBarIcon will be set on it.
    ConfigViewportsNoDecoration : bool,    // = true           // Disable default OS window decoration flag for secondary viewports. When a viewport doesn't want window decorations, ImGuiViewportFlags_NoDecoration will be set on it. Enabling decoration can create subsequent issues at OS levels (e.g. minimum window size).
    ConfigViewportsNoDefaultParent : bool, // = false          // Disable default OS parenting to main viewport for secondary viewports. By default, viewports are marked with ParentViewportId = <main_viewport>, expecting the platform backend to setup a parent/child relationship between the OS windows (some backend may ignore this). Set to true if you want the default to be 0, then all viewports will be top-level OS windows.

    // Miscellaneous options
    // (you can visualize and interact with all options in 'Demo->Configuration')
    MouseDrawCursor : bool,                // = false          // Request ImGui to draw a mouse cursor for you (if you are on a platform without a mouse cursor). Cannot be easily renamed to 'io.ConfigXXX' because this is frequently used by backend implementations.
    ConfigMacOSXBehaviors : bool,          // = defined(__APPLE__) // Swap Cmd<>Ctrl keys + OS X style text editing cursor movement using Alt instead of Ctrl, Shortcuts using Cmd/Super instead of Ctrl, Line/Text Start and End using Cmd+Arrows instead of Home/End, Double click selects by word instead of selecting whole text, Multi-selection in lists uses Cmd/Super instead of Ctrl.
    ConfigInputTrickleEventQueue : bool,   // = true           // Enable input queue trickling: some types of events submitted during the same frame (e.g. button down + up) will be spread over multiple frames, improving interactions with low framerates.
    ConfigInputTextCursorBlink : bool,     // = true           // Enable blinking cursor (optional as some users consider it to be distracting).
    ConfigInputTextEnterKeepActive : bool, // = false          // [BETA] Pressing Enter will keep item active and select contents (single-line only).
    ConfigDragClickToInputText : bool,     // = false          // [BETA] Enable turning DragXXX widgets into text input with a simple mouse click-release (without moving). Not desirable on devices without a keyboard.
    ConfigWindowsResizeFromEdges : bool,   // = true           // Enable resizing of windows from their edges and from the lower-left corner. This requires ImGuiBackendFlags_HasMouseCursors for better mouse cursor feedback. (This used to be a per-window ImGuiWindowFlags_ResizeFromAnySide flag)
    ConfigWindowsMoveFromTitleBarOnly : bool,  // = false      // Enable allowing to move windows only when clicking on their title bar. Does not apply to windows without a title bar.
    ConfigWindowsCopyContentsWithCtrlC : bool, // = false      // [EXPERIMENTAL] CTRL+C copy the contents of focused window into the clipboard. Experimental because: (1) has known issues with nested Begin/End pairs (2) text output quality varies (3) text output is in submission order rather than spatial order.
    ConfigScrollbarScrollByPage : bool,    // = true           // Enable scrolling page by page when clicking outside the scrollbar grab. When disabled, always scroll to clicked location. When enabled, Shift+Click scrolls to clicked location.
    ConfigMemoryCompactTimer : f32,       // = 60.0f          // Timer (in seconds) to free transient windows/tables memory buffers when unused. Set to -1.0f to disable.

    // Inputs Behaviors
    // (other variables, ones which are expected to be tweaked within UI code, are exposed in ImGuiStyle)
    MouseDoubleClickTime : f32,           // = 0.30f          // Time for a double-click, in seconds.
    MouseDoubleClickMaxDist : f32,        // = 6.0f           // Distance threshold to stay in to validate a double-click, in pixels.
    MouseDragThreshold : f32,             // = 6.0f           // Distance threshold before considering we are dragging.
    KeyRepeatDelay : f32,                 // = 0.275f         // When holding a key/button, time before it starts repeating, in seconds (for buttons in Repeat mode, etc.).
    KeyRepeatRate : f32,                  // = 0.050f         // When holding a key/button, rate at which it repeats, in seconds.

    //------------------------------------------------------------------
    // Debug options
    //------------------------------------------------------------------

    // Options to configure Error Handling and how we handle recoverable errors [EXPERIMENTAL]
    // - Error recovery is provided as a way to facilitate:
    //    - Recovery after a programming error (native code or scripting language - the later tends to facilitate iterating on code while running).
    //    - Recovery after running an exception handler or any error processing which may skip code after an error has been detected.
    // - Error recovery is not perfect nor guaranteed! It is a feature to ease development.
    //   You not are not supposed to rely on it in the course of a normal application run.
    // - Functions that support error recovery are using IM_ASSERT_USER_ERROR() instead of IM_ASSERT().
    // - By design, we do NOT allow error recovery to be 100% silent. One of the three options needs to be checked!
    // - Always ensure that on programmers seats you have at minimum Asserts or Tooltips enabled when making direct imgui API calls!
    //   Otherwise it would severely hinder your ability to catch and correct mistakes!
    // Read https://github.com/ocornut/imgui/wiki/Error-Handling for details.
    // - Programmer seats: keep asserts (default), or disable asserts and keep error tooltips (new and nice!)
    // - Non-programmer seats: maybe disable asserts, but make sure errors are resurfaced (tooltips, visible log entries, use callback etc.)
    // - Recovery after error/exception: record stack sizes with ErrorRecoveryStoreState(), disable assert, set log callback (to e.g. trigger high-level breakpoint), recover with ErrorRecoveryTryToRecoverState(), restore settings.
    ConfigErrorRecovery : bool,                // = true       // Enable error recovery support. Some errors won't be detected and lead to direct crashes if recovery is disabled.
    ConfigErrorRecoveryEnableAssert : bool,    // = true       // Enable asserts on recoverable error. By default call IM_ASSERT() when returning from a failing IM_ASSERT_USER_ERROR()
    ConfigErrorRecoveryEnableDebugLog : bool,  // = true       // Enable debug log output on recoverable errors.
    ConfigErrorRecoveryEnableTooltip : bool,   // = true       // Enable tooltip on recoverable errors. The tooltip include a way to enable asserts if they were disabled.

    // Option to enable various debug tools showing buttons that will call the IM_DEBUG_BREAK() macro.
    // - The Item Picker tool will be available regardless of this being enabled, in order to maximize its discoverability.
    // - Requires a debugger being attached, otherwise IM_DEBUG_BREAK() options will appear to crash your application.
    //   e.g. io.ConfigDebugIsDebuggerPresent = ::IsDebuggerPresent() on Win32, or refer to ImOsIsDebuggerPresent() imgui_test_engine/imgui_te_utils.cpp for a Unix compatible version).
    ConfigDebugIsDebuggerPresent : bool,   // = false          // Enable various tools calling IM_DEBUG_BREAK().

    // Tools to detect code submitting items with conflicting/duplicate IDs
    // - Code should use PushID()/PopID() in loops, or append "##xx" to same-label identifiers.
    // - Empty label e.g. Button("") == same ID as parent widget/node. Use Button("##xx") instead!
    // - See FAQ https://github.com/ocornut/imgui/blob/master/docs/FAQ.md#q-about-the-id-stack-system
    ConfigDebugHighlightIdConflicts : bool,// = true           // Highlight and show an error message when multiple items have conflicting identifiers.

    // Tools to test correct Begin/End and BeginChild/EndChild behaviors.
    // - Presently Begin()/End() and BeginChild()/EndChild() needs to ALWAYS be called in tandem, regardless of return value of BeginXXX()
    // - This is inconsistent with other BeginXXX functions and create confusion for many users.
    // - We expect to update the API eventually. In the meanwhile we provide tools to facilitate checking user-code behavior.
    ConfigDebugBeginReturnValueOnce : bool,// = false          // First-time calls to Begin()/BeginChild() will return false. NEEDS TO BE SET AT APPLICATION BOOT TIME if you don't want to miss windows.
    ConfigDebugBeginReturnValueLoop : bool,// = false          // Some calls to Begin()/BeginChild() will return false. Will cycle through window depths then repeat. Suggested use: add "io.ConfigDebugBeginReturnValue = io.KeyShift" in your main loop then occasionally press SHIFT. Windows should be flickering while running.

    // Option to deactivate io.AddFocusEvent(false) handling.
    // - May facilitate interactions with a debugger when focus loss leads to clearing inputs data.
    // - Backends may have other side-effects on focus loss, so this will reduce side-effects but not necessary remove all of them.
    ConfigDebugIgnoreFocusLoss : bool,     // = false          // Ignore io.AddFocusEvent(false), consequently not calling io.ClearInputKeys()/io.ClearInputMouse() in input processing.

    // Option to audit .ini data
    ConfigDebugIniSettings : bool,         // = false          // Save .ini data with extra comments (particularly helpful for Docking, but makes saving slower)

    //------------------------------------------------------------------
    // Platform Identifiers
    // (the imgui_impl_xxxx backend files are setting those up for you)
    //------------------------------------------------------------------

    // Nowadays those would be stored in ImGuiPlatformIO but we are leaving them here for legacy reasons.
    // Optional: Platform/Renderer backend name (informational only! will be displayed in About Window) + User data for backend/wrappers to store their own stuff.
    BackendPlatformName : ^u8,            // = NULL
    BackendRendererName : ^u8,            // = NULL
    BackendPlatformUserData : rawptr,        // = NULL           // User data for platform backend
    BackendRendererUserData : rawptr,        // = NULL           // User data for renderer backend
    BackendLanguageUserData : rawptr,        // = NULL           // User data for non C++ programming language backend

    //------------------------------------------------------------------
    // Input - Call before calling NewFrame()
    //------------------------------------------------------------------

    // Input Functions
    void  AddKeyEvent(ImGuiKey key, bool down);                   // Queue a new key down/up event. Key should be "translated" (as in, generally ImGuiKey_A matches the key end-user would use to emit an 'A' character)
    void  AddKeyAnalogEvent(ImGuiKey key, bool down, f32 v);    // Queue a new key down/up event for analog values (e.g. ImGuiKey_Gamepad_ values). Dead-zones should be handled by the backend.
    void  AddMousePosEvent(f32 x, f32 y);                     // Queue a mouse position update. Use -FLT_MAX,-FLT_MAX to signify no mouse (e.g. app not focused and not hovered)
    void  AddMouseButtonEvent(i32 button, bool down);             // Queue a mouse button change
    void  AddMouseWheelEvent(f32 wheel_x, f32 wheel_y);       // Queue a mouse wheel update. wheel_y<0: scroll down, wheel_y>0: scroll up, wheel_x<0: scroll right, wheel_x>0: scroll left.
    void  AddMouseSourceEvent(ImGuiMouseSource source);           // Queue a mouse source change (Mouse/TouchScreen/Pen)
    void  AddMouseViewportEvent(ImGuiID id);                      // Queue a mouse hovered viewport. Requires backend to set ImGuiBackendFlags_HasMouseHoveredViewport to call this (for multi-viewport support).
    void  AddFocusEvent(bool focused);                            // Queue a gain/loss of focus for the application (generally based on OS/platform focus of your window)
    void  AddInputCharacter(u32 c);                      // Queue a new character input
    void  AddInputCharacterUTF16(ImWchar16 c);                    // Queue a new character input from a UTF-16 character, it can be a surrogate
    void  AddInputCharactersUTF8(const u8* str);                // Queue a new characters input from a UTF-8 string

    void  SetKeyEventNativeData(ImGuiKey key, i32 native_keycode, i32 native_scancode, i32 native_legacy_index = -1); // [Optional] Specify index for legacy <1.87 IsKeyXXX() functions with native indices + specify native keycode, scancode.
    void  SetAppAcceptingEvents(bool accepting_events);           // Set master flag for accepting key/mouse/text events (default to true). Useful if you have native dialog boxes that are interrupting your application loop/refresh, and you want to disable events being queued while your app is frozen.
    void  ClearEventsQueue();                                     // Clear all incoming events.
    void  ClearInputKeys();                                       // Clear current keyboard/gamepad state + current frame text input buffer. Equivalent to releasing all keys/buttons.
    void  ClearInputMouse();                                      // Clear current mouse state.

    //------------------------------------------------------------------
    // Output - Updated by NewFrame() or EndFrame()/Render()
    // (when reading from the io.WantCaptureMouse, io.WantCaptureKeyboard flags to dispatch your inputs, it is
    //  generally easier and more correct to use their state BEFORE calling NewFrame(). See FAQ for details!)
    //------------------------------------------------------------------

    WantCaptureMouse : bool,                   // Set when Dear ImGui will use mouse inputs, in this case do not dispatch them to your main game/application (either way, always pass on mouse inputs to imgui). (e.g. unclicked mouse is hovering over an imgui window, widget is active, mouse was clicked over an imgui window, etc.).
    WantCaptureKeyboard : bool,                // Set when Dear ImGui will use keyboard inputs, in this case do not dispatch them to your main game/application (either way, always pass keyboard inputs to imgui). (e.g. InputText active, or an imgui window is focused and navigation is enabled, etc.).
    WantTextInput : bool,                      // Mobile/console: when set, you may display an on-screen keyboard. This is set by Dear ImGui when it wants textual keyboard input to happen (e.g. when a InputText widget is active).
    WantSetMousePos : bool,                    // MousePos has been altered, backend should reposition mouse on next frame. Rarely used! Set only when io.ConfigNavMoveSetMousePos is enabled.
    WantSaveIniSettings : bool,                // When manual .ini load/save is active (io.IniFilename == NULL), this will be set to notify your application that you can call SaveIniSettingsToMemory() and save yourself. Important: clear io.WantSaveIniSettings yourself after saving!
    NavActive : bool,                          // Keyboard/Gamepad navigation is currently allowed (will handle ImGuiKey_NavXXX events) = a window is focused and it doesn't use the ImGuiWindowFlags_NoNavInputs flag.
    NavVisible : bool,                         // Keyboard/Gamepad navigation highlight is visible and allowed (will handle ImGuiKey_NavXXX events).
    Framerate : f32,                          // Estimate of application framerate (rolling average over 60 frames, based on io.DeltaTime), in frame per second. Solely for convenience. Slow applications may not want to use a moving average or may want to reset underlying buffers occasionally.
    MetricsRenderVertices : i32,              // Vertices output during last call to Render()
    MetricsRenderIndices : i32,               // Indices output during last call to Render() = number of triangles * 3
    MetricsRenderWindows : i32,               // Number of visible windows
    MetricsActiveWindows : i32,               // Number of active windows
    MouseDelta : ImVec2,                         // Mouse delta. Note that this is zero if either current or previous position are invalid (-FLT_MAX,-FLT_MAX), so a disappearing/reappearing mouse won't have a huge delta.

    //------------------------------------------------------------------
    // [Internal] Dear ImGui will maintain those fields. Forward compatibility not guaranteed!
    //------------------------------------------------------------------

    Ctx : ^ImGuiContext,                              // Parent UI context (needs to be set explicitly by parent).

    // Main Input State
    // (this block used to be written by backend, since 1.87 it is best to NOT write to those directly, call the AddXXX functions above instead)
    // (reading from those variables is fair game, as they are extremely unlikely to be moving anywhere)
    MousePos : ImVec2,                           // Mouse position, in pixels. Set to ImVec2(-FLT_MAX, -FLT_MAX) if mouse is unavailable (on another screen, etc.)
    MouseDown : [5]bool,                       // Mouse buttons: 0=left, 1=right, 2=middle + extras (ImGuiMouseButton_COUNT == 5). Dear ImGui mostly uses left and right buttons. Other buttons allow us to track if the mouse is being used by your application + available to user as a convenience via IsMouse** API.
    MouseWheel : f32,                         // Mouse wheel Vertical: 1 unit scrolls about 5 lines text. >0 scrolls Up, <0 scrolls Down. Hold SHIFT to turn vertical scroll into horizontal scroll.
    MouseWheelH : f32,                        // Mouse wheel Horizontal. >0 scrolls Left, <0 scrolls Right. Most users don't have a mouse with a horizontal wheel, may not be filled by all backends.
    MouseSource : ImGuiMouseSource,                   // Mouse actual input peripheral (Mouse/TouchScreen/Pen).
    MouseHoveredViewport : ImGuiID,               // (Optional) Modify using io.AddMouseViewportEvent(). With multi-viewports: viewport the OS mouse is hovering. If possible _IGNORING_ viewports with the ImGuiViewportFlags_NoInputs flag is much better (few backends can handle that). Set io.BackendFlags |= ImGuiBackendFlags_HasMouseHoveredViewport if you can provide this info. If you don't imgui will infer the value using the rectangles and last focused time of the viewports it knows about (ignoring other OS windows).
    KeyCtrl : bool,                            // Keyboard modifier down: Control
    KeyShift : bool,                           // Keyboard modifier down: Shift
    KeyAlt : bool,                             // Keyboard modifier down: Alt
    KeySuper : bool,                           // Keyboard modifier down: Cmd/Super/Windows

    // Other state maintained from data above + IO function calls
    KeyMods : ImGuiKeyChord,                          // Key mods flags (any of ImGuiMod_Ctrl/ImGuiMod_Shift/ImGuiMod_Alt/ImGuiMod_Super flags, same as io.KeyCtrl/KeyShift/KeyAlt/KeySuper but merged into flags. Read-only, updated by NewFrame()
    KeysData : [ImGuiKey_NamedKey_COUNT]ImGuiKeyData,// Key state for all known keys. Use IsKeyXXX() functions to access this.
    WantCaptureMouseUnlessPopupClose : bool,   // Alternative to WantCaptureMouse: (WantCaptureMouse == true && WantCaptureMouseUnlessPopupClose == false) when a click over void is expected to close a popup.
    MousePosPrev : ImVec2,                       // Previous mouse position (note that MouseDelta is not necessary == MousePos-MousePosPrev, in case either position is invalid)
    MouseClickedPos : [5]ImVec2,                 // Position at time of clicking
    MouseClickedTime : [5]f64,                // Time of last click (used to figure out double-click)
    MouseClicked : [5]bool,                    // Mouse button went from !Down to Down (same as MouseClickedCount[x] != 0)
    MouseDoubleClicked : [5]bool,              // Has mouse button been double-clicked? (same as MouseClickedCount[x] == 2)
    MouseClickedCount : [5]u16,               // == 0 (not clicked), == 1 (same as MouseClicked[]), == 2 (double-clicked), == 3 (triple-clicked) etc. when going from !Down to Down
    MouseClickedLastCount : [5]u16,           // Count successive number of clicks. Stays valid after mouse release. Reset after another click is done.
    MouseReleased : [5]bool,                   // Mouse button went from Down to !Down
    MouseDownOwned : [5]bool,                  // Track if button was clicked inside a dear imgui window or over void blocked by a popup. We don't request mouse capture from the application if click started outside ImGui bounds.
    MouseDownOwnedUnlessPopupClose : [5]bool,  // Track if button was clicked inside a dear imgui window.
    MouseWheelRequestAxisSwap : bool,          // On a non-Mac system, holding SHIFT requests WheelY to perform the equivalent of a WheelX event. On a Mac system this is already enforced by the system.
    MouseCtrlLeftAsRightClick : bool,          // (OSX) Set to true when the current click was a ctrl-click that spawned a simulated right click
    MouseDownDuration : [5]f32,               // Duration the mouse button has been down (0.0f == just clicked)
    MouseDownDurationPrev : [5]f32,           // Previous time the mouse button has been down
    MouseDragMaxDistanceAbs : [5]ImVec2,         // Maximum distance, absolute, on each axis, of how much mouse has traveled from the clicking point
    MouseDragMaxDistanceSqr : [5]f32,         // Squared maximum distance of how much mouse has traveled from the clicking point (used for moving thresholds)
    PenPressure : f32,                        // Touch/Pen pressure (0.0f to 1.0f, should be >0.0f only when MouseDown[0] == true). Helper storage currently unused by Dear ImGui.
    AppFocusLost : bool,                       // Only modify via AddFocusEvent()
    AppAcceptingEvents : bool,                 // Only modify via SetAppAcceptingEvents()
    InputQueueSurrogate : ImWchar16,                // For AddInputCharacterUTF16()
    InputQueueCharacters : [dynamic]ImWchar,         // Queue of _characters_ input (obtained by platform backend). Fill using AddInputCharacter() helper.

    // Legacy: before 1.87, we required backend to fill io.KeyMap[] (imgui->native map) during initialization and io.KeysDown[] (native indices) every frame.
    // This is still temporarily supported as a legacy feature. However the new preferred scheme is for backend to call io.AddKeyEvent().
    //   Old (<1.87):  ImGui::IsKeyPressed(ImGui::GetIO().KeyMap[ImGuiKey_Space]) --> New (1.87+) ImGui::IsKeyPressed(ImGuiKey_Space)
    //   Old (<1.87):  ImGui::IsKeyPressed(MYPLATFORM_KEY_SPACE)                  --> New (1.87+) ImGui::IsKeyPressed(ImGuiKey_Space)
    // Read https://github.com/ocornut/imgui/issues/4921 for details.
    //int       KeyMap[ImGuiKey_COUNT];             // [LEGACY] Input: map of indices into the KeysDown[512] entries array which represent your "native" keyboard state. The first 512 are now unused and should be kept zero. Legacy backend will write into KeyMap[] using ImGuiKey_ indices which are always >512.
    //bool      KeysDown[ImGuiKey_COUNT];           // [LEGACY] Input: Keyboard keys that are pressed (ideally left in the "native" order your engine has access to keyboard keys, so you can use your own defines/enums for keys). This used to be [512] sized. It is now ImGuiKey_COUNT to allow legacy io.KeysDown[GetKeyIndex(...)] to work without an overflow.
    //float     NavInputs[ImGuiNavInput_COUNT];     // [LEGACY] Since 1.88, NavInputs[] was removed. Backends from 1.60 to 1.86 won't build. Feed gamepad inputs via io.AddKeyEvent() and ImGuiKey_GamepadXXX enums.
    //void*     ImeWindowHandle;                    // [Obsoleted in 1.87] Set ImGuiViewport::PlatformHandleRaw instead. Set this to your HWND to get automatic IME cursor positioning.

    // Legacy: before 1.91.1, clipboard functions were stored in ImGuiIO instead of ImGuiPlatformIO.
    // As this is will affect all users of custom engines/backends, we are providing proper legacy redirection (will obsolete).

      ImGuiIO();
};

//-----------------------------------------------------------------------------
// [SECTION] Misc data structures (ImGuiInputTextCallbackData, ImGuiSizeCallbackData, ImGuiPayload)
//-----------------------------------------------------------------------------

// Shared state of InputText(), passed as an argument to your callback when a ImGuiInputTextFlags_Callback* flag is used.
// The callback function should return 0 by default.
// Callbacks (follow a flag name and see comments in ImGuiInputTextFlags_ declarations for more details)
// - ImGuiInputTextFlags_CallbackEdit:        Callback on buffer edit (note that InputText() already returns true on edit, the callback is useful mainly to manipulate the underlying buffer while focus is active)
// - ImGuiInputTextFlags_CallbackAlways:      Callback on each iteration
// - ImGuiInputTextFlags_CallbackCompletion:  Callback on pressing TAB
// - ImGuiInputTextFlags_CallbackHistory:     Callback on pressing Up/Down arrows
// - ImGuiInputTextFlags_CallbackCharFilter:  Callback on character inputs to replace or discard them. Modify 'EventChar' to replace or discard, or return 1 in callback to discard.
// - ImGuiInputTextFlags_CallbackResize:      Callback on buffer capacity changes request (beyond 'buf_size' parameter value), allowing the string to grow.
ImGuiInputTextCallbackData :: struct
{
    Ctx : ^ImGuiContext,            // Parent UI context
    EventFlag : ImGuiInputTextFlags,      // One ImGuiInputTextFlags_Callback*    // Read-only
    Flags : ImGuiInputTextFlags,          // What user passed to InputText()      // Read-only
    UserData : rawptr,       // What user passed to InputText()      // Read-only

    // Arguments for the different callback events
    // - During Resize callback, Buf will be same as your input buffer.
    // - However, during Completion/History/Always callback, Buf always points to our own internal data (it is not the same as your buffer)! Changes to it will be reflected into your own buffer shortly after the callback.
    // - To modify the text buffer in a callback, prefer using the InsertChars() / DeleteChars() function. InsertChars() will take care of calling the resize callback if necessary.
    // - If you know your edits are not going to resize the underlying buffer allocation, you may modify the contents of 'Buf[]' directly. You need to update 'BufTextLen' accordingly (0 <= BufTextLen < BufSize) and set 'BufDirty'' to true so InputText can update its internal state.
    EventChar : ImWchar,      // Character input                      // Read-write   // [CharFilter] Replace character with another one, or set to zero to drop. return 1 is equivalent to setting EventChar=0;
    EventKey : ImGuiKey,       // Key pressed (Up/Down/TAB)            // Read-only    // [Completion,History]
    Buf : ^u8,            // Text buffer                          // Read-write   // [Resize] Can replace pointer / [Completion,History,Always] Only write to pointed data, don't replace the actual pointer!
    BufTextLen : i32,     // Text length (in bytes)               // Read-write   // [Resize,Completion,History,Always] Exclude zero-terminator storage. In C land: == strlen(some_text), in C++ land: string.length()
    BufSize : i32,        // Buffer size (in bytes) = capacity+1  // Read-only    // [Resize,Completion,History,Always] Include zero-terminator storage. In C land == ARRAYSIZE(my_char_array), in C++ land: string.capacity()+1
    BufDirty : bool,       // Set if you modify Buf/BufTextLen!    // Write        // [Completion,History,Always]
    CursorPos : i32,      //                                      // Read-write   // [Completion,History,Always]
    SelectionStart : i32, //                                      // Read-write   // [Completion,History,Always] == to SelectionEnd when no selection)
    SelectionEnd : i32,   //                                      // Read-write   // [Completion,History,Always]

    // Helper functions for text manipulation.
    // Use those function to benefit from the CallbackResize behaviors. Calling those function reset the selection.
    ImGuiInputTextCallbackData();
    void      DeleteChars(i32 pos, i32 bytes_count);
    void      InsertChars(i32 pos, const u8* text, const u8* text_end = nil);
    void                SelectAll()             { SelectionStart = 0; SelectionEnd = BufTextLen; }
    void                ClearSelection()        { SelectionStart = SelectionEnd = BufTextLen; }
    bool                HasSelection() const    { return SelectionStart != SelectionEnd; }
};

// Resizing callback data to apply custom constraint. As enabled by SetNextWindowSizeConstraints(). Callback is called during the next Begin().
// NB: For basic min/max size constraint on each axis you don't need to use the callback! The SetNextWindowSizeConstraints() parameters are enough.
ImGuiSizeCallbackData :: struct
{
    UserData : rawptr,       // Read-only.   What user passed to SetNextWindowSizeConstraints(). Generally store an integer or float in here (need reinterpret_cast<>).
    Pos : ImVec2,            // Read-only.   Window position, for reference.
    CurrentSize : ImVec2,    // Read-only.   Current window size.
    DesiredSize : ImVec2,    // Read-write.  Desired size, based on user's mouse position. Write to this field to restrain resizing.
};

// [ALPHA] Rarely used / very advanced uses only. Use with SetNextWindowClass() and DockSpace() functions.
// Important: the content of this class is still highly WIP and likely to change and be refactored
// before we stabilize Docking features. Please be mindful if using this.
// Provide hints:
// - To the platform backend via altered viewport flags (enable/disable OS decoration, OS task bar icons, etc.)
// - To the platform backend for OS level parent/child relationships of viewport.
// - To the docking system for various options and filtering.
ImGuiWindowClass :: struct
{
    ClassId : ImGuiID,                    // User data. 0 = Default class (unclassed). Windows of different classes cannot be docked with each others.
    ParentViewportId : ImGuiID,           // Hint for the platform backend. -1: use default. 0: request platform backend to not parent the platform. != 0: request platform backend to create a parent<>child relationship between the platform windows. Not conforming backends are free to e.g. parent every viewport to the main viewport or not.
    FocusRouteParentWindowId : ImGuiID,   // ID of parent window for shortcut focus route evaluation, e.g. Shortcut() call from Parent Window will succeed when this window is focused.
    ViewportFlagsOverrideSet : ImGuiViewportFlags,   // Viewport flags to set when a window of this class owns a viewport. This allows you to enforce OS decoration or task bar icon, override the defaults on a per-window basis.
    ViewportFlagsOverrideClear : ImGuiViewportFlags, // Viewport flags to clear when a window of this class owns a viewport. This allows you to enforce OS decoration or task bar icon, override the defaults on a per-window basis.
    TabItemFlagsOverrideSet : ImGuiTabItemFlags,    // [EXPERIMENTAL] TabItem flags to set when a window of this class gets submitted into a dock node tab bar. May use with ImGuiTabItemFlags_Leading or ImGuiTabItemFlags_Trailing.
    DockNodeFlagsOverrideSet : ImGuiDockNodeFlags,   // [EXPERIMENTAL] Dock node flags to set when a window of this class is hosted by a dock node (it doesn't have to be selected!)
    DockingAlwaysTabBar : bool,        // Set to true to enforce single floating windows of this class always having their own docking node (equivalent of setting the global io.ConfigDockingAlwaysTabBar)
    DockingAllowUnclassed : bool,      // Set to true to allow windows of this class to be docked/merged with an unclassed window. // FIXME-DOCK: Move to DockNodeFlags override?

    ImGuiWindowClass() { memset(this, 0, size_of(*this)); ParentViewportId = (ImGuiID)-1; DockingAllowUnclassed = true; }
};

// Data payload for Drag and Drop operations: AcceptDragDropPayload(), GetDragDropPayload()
ImGuiPayload :: struct
{
    // Members
    Data : rawptr,               // Data (copied and owned by dear imgui)
    DataSize : i32,           // Data size

    // [Internal]
    SourceId : ImGuiID,           // Source item id
    SourceParentId : ImGuiID,     // Source parent id (if available)
    DataFrameCount : i32,     // Data timestamp
    DataType : [32 + 1]u8,   // Data type tag (short user-supplied string, 32 characters max)
    Preview : bool,            // Set when AcceptDragDropPayload() was called and mouse has been hovering the target item (nb: handle overlapping drag targets)
    Delivery : bool,           // Set when AcceptDragDropPayload() was called and mouse button is released over the target item.

    ImGuiPayload()  { Clear(); }
    void Clear()    { SourceId = SourceParentId = 0; Data = nil; DataSize = 0; memset(DataType, 0, size_of(DataType)); DataFrameCount = -1; Preview = Delivery = false; }
    bool IsDataType(const u8* type) const { return DataFrameCount != -1 && strcmp(type, DataType) == 0; }
    bool IsPreview() const                  { return Preview; }
    bool IsDelivery() const                 { return Delivery; }
};

//-----------------------------------------------------------------------------
// [SECTION] Helpers (ImGuiOnceUponAFrame, ImGuiTextFilter, ImGuiTextBuffer, ImGuiStorage, ImGuiListClipper, Math Operators, ImColor)
//-----------------------------------------------------------------------------

// Helper: Unicode defines
IM_UNICODE_CODEPOINT_INVALID :: 0xFFFD     // Invalid Unicode code point (standard value).
when IMGUI_USE_WCHAR32 {
IM_UNICODE_CODEPOINT_MAX :: 0x10FFFF   // Maximum Unicode code point supported by this build.
} else {
IM_UNICODE_CODEPOINT_MAX :: 0xFFFF     // Maximum Unicode code point supported by this build.
}

// Helper: Execute a block of code at maximum once a frame. Convenient if you want to quickly create a UI within deep-nested code that runs multiple times every frame.
// Usage: static ImGuiOnceUponAFrame oaf; if (oaf) ImGui::Text("This will be called only once per frame");
ImGuiOnceUponAFrame :: struct
{
    ImGuiOnceUponAFrame() { RefFrame = -1; }
    mutable i32 RefFrame;
    operator bool() const { i32 current_frame = GetFrameCount(); if (RefFrame == current_frame) return false; RefFrame = current_frame; return true; }
};

// Helper: Parse and apply text filters. In format "aaaaa[,bbbb][,ccccc]"
ImGuiTextFilter :: struct
{
              ImGuiTextFilter(const u8* default_filter = "");
    bool      Draw(const u8* label = "Filter (inc,-exc)", f32 width = 0.0);  // Helper calling InputText+Build
    bool      PassFilter(const u8* text, const u8* text_end = nil) const;
    void      Build();
    void                Clear()          { InputBuf[0] = 0; Build(); }
    bool                IsActive() const { return !Filters.empty(); }

    // [Internal]
    ImGuiTextRange :: struct
    {
        b : ^u8,
        e : ^u8,

        ImGuiTextRange()                                { b = e = nil; }
        ImGuiTextRange(const u8* _b, const u8* _e)  { b = _b; e = _e; }
        bool            empty() const                   { return b == e; }
        void  split(u8 separator, ImVector<ImGuiTextRange>* out) const;
    };
    InputBuf : [256]u8
    ImVector<ImGuiTextRange>Filters;
    CountGrep : i32
};

// Helper: Growable text buffer for logging/accumulating text
// (this could be called 'ImGuiTextBuilder' / 'ImGuiStringBuilder')
ImGuiTextBuffer :: struct
{
    Buf : [dynamic]u8,
    static u8 EmptyString[1];

    ImGuiTextBuffer()   { }
    inline u8         operator[](i32 i) const { assert(Buf.Data != nil); return Buf.Data[i]; }
    const u8*         begin() const           { return Buf.Data ? &Buf.front() : EmptyString; }
    const u8*         end() const             { return Buf.Data ? &Buf.back() : EmptyString; }   // Buf is zero-terminated, so end() will point on the zero-terminator
    i32                 size() const            { return Buf.Size ? Buf.Size - 1 : 0; }
    bool                empty() const           { return Buf.Size <= 1; }
    void                clear()                 { Buf.clear(); }
    void                reserve(i32 capacity)   { Buf.reserve(capacity); }
    const u8*         c_str() const           { return Buf.Data ? Buf.Data : EmptyString; }
    void      append(const u8* str, const u8* str_end = nil);
    void      appendf(const u8* fmt, ...) ;
    void      appendfv(const u8* fmt, va_list args) ;
};

// [Internal] Key+Value for ImGuiStorage
ImGuiStoragePair :: struct
{
    key : ImGuiID,
    union       { i32 val_i; f32 val_f; rawptr val_p; };
    ImGuiStoragePair(ImGuiID _key, i32 _val)    { key = _key; val_i = _val; }
    ImGuiStoragePair(ImGuiID _key, f32 _val)  { key = _key; val_f = _val; }
    ImGuiStoragePair(ImGuiID _key, rawptr _val)  { key = _key; val_p = _val; }
};

// Helper: Key->Value storage
// Typically you don't have to worry about this since a storage is held within each Window.
// We use it to e.g. store collapse state for a tree (Int 0/1)
// This is optimized for efficient lookup (dichotomy into a contiguous buffer) and rare insertion (typically tied to user interactions aka max once a frame)
// You can use it as custom user storage for temporary values. Declare your own storage if, for example:
// - You want to manipulate the open/close state of a particular sub-tree in your interface (tree node uses Int 0/1 to store their state).
// - You want to store custom debug data easily without adding or editing structures in your code (probably not efficient, but convenient)
// Types are NOT stored, so it is up to you to make sure your Key don't collide with different types.
ImGuiStorage :: struct
{
    // [Internal]
    Data : [dynamic]ImGuiStoragePair,

    // - Get***() functions find pair, never add/allocate. Pairs are sorted so a query is O(log N)
    // - Set***() functions find pair, insertion on demand if missing.
    // - Sorted insertion is costly, paid once. A typical frame shouldn't need to insert any new pair.
    void                Clear() { Data.clear(); }
    i32       GetInt(ImGuiID key, i32 default_val = 0) const;
    void      SetInt(ImGuiID key, i32 val);
    bool      GetBool(ImGuiID key, bool default_val = false) const;
    void      SetBool(ImGuiID key, bool val);
    f32     GetFloat(ImGuiID key, f32 default_val = 0.0) const;
    void      SetFloat(ImGuiID key, f32 val);
    rawptr     GetVoidPtr(ImGuiID key) const; // default_val is NULL
    void      SetVoidPtr(ImGuiID key, rawptr val);

    // - Get***Ref() functions finds pair, insert on demand if missing, return pointer. Useful if you intend to do Get+Set.
    // - References are only valid until a new value is added to the storage. Calling a Set***() function or a Get***Ref() function invalidates the pointer.
    // - A typical use case where this is convenient for quick hacking (e.g. add storage during a live Edit&Continue session if you can't modify existing struct)
    //      float* pvar = ImGui::GetFloatRef(key); ImGui::SliderFloat("var", pvar, 0, 100.0f); some_var += *pvar;
    i32*      GetIntRef(ImGuiID key, i32 default_val = 0);
    bool*     GetBoolRef(ImGuiID key, bool default_val = false);
    f32*    GetFloatRef(ImGuiID key, f32 default_val = 0.0);
    rawptr*    GetVoidPtrRef(ImGuiID key, rawptr default_val = nil);

    // Advanced: for quicker full rebuild of a storage (instead of an incremental one), you may add all your contents and then sort once.
    void      BuildSortByKey();
    // Obsolete: use on your own storage if you know only integer are being stored (open/close all tree nodes)
    void      SetAllInt(i32 val);

};

// Helper: Manually clip large list of items.
// If you have lots evenly spaced items and you have random access to the list, you can perform coarse
// clipping based on visibility to only submit items that are in view.
// The clipper calculates the range of visible items and advance the cursor to compensate for the non-visible items we have skipped.
// (Dear ImGui already clip items based on their bounds but: it needs to first layout the item to do so, and generally
//  fetching/submitting your own data incurs additional cost. Coarse clipping using ImGuiListClipper allows you to easily
//  scale using lists with tens of thousands of items without a problem)
// Usage:
//   ImGuiListClipper clipper;
//   clipper.Begin(1000);         // We have 1000 elements, evenly spaced.
//   while (clipper.Step())
//       for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
//           ImGui::Text("line number %d", i);
// Generally what happens is:
// - Clipper lets you process the first element (DisplayStart = 0, DisplayEnd = 1) regardless of it being visible or not.
// - User code submit that one element.
// - Clipper can measure the height of the first element
// - Clipper calculate the actual range of elements to display based on the current clipping rectangle, position the cursor before the first visible element.
// - User code submit visible elements.
// - The clipper also handles various subtleties related to keyboard/gamepad navigation, wrapping etc.
ImGuiListClipper :: struct
{
    Ctx : ^ImGuiContext,                // Parent UI context
    DisplayStart : i32,       // First item to display, updated by each call to Step()
    DisplayEnd : i32,         // End of items to display (exclusive)
    ItemsCount : i32,         // [Internal] Number of items
    ItemsHeight : f32,        // [Internal] Height of item after a first step and item submission can calculate it
    StartPosY : f32,          // [Internal] Cursor position at the time of Begin() or after table frozen rows are all processed
    StartSeekOffsetY : f64,   // [Internal] Account for frozen rows in a table and initial loss of precision in very large windows.
    TempData : rawptr,           // [Internal] Internal data

    // items_count: Use INT_MAX if you don't know how many items you have (in which case the cursor won't be advanced in the final step, and you can call SeekCursorForItem() manually if you need)
    // items_height: Use -1.0f to be calculated automatically on first step. Otherwise pass in the distance between your items, typically GetTextLineHeightWithSpacing() or GetFrameHeightWithSpacing().
    ImGuiListClipper();
    ~ImGuiListClipper();
    void  Begin(i32 items_count, f32 items_height = -1.0);
    void  End();             // Automatically called on the last call of Step() that returns false.
    bool  Step();            // Call until it returns false. The DisplayStart/DisplayEnd fields will be set and you can process/draw those items.

    // Call IncludeItemByIndex() or IncludeItemsByIndex() *BEFORE* first call to Step() if you need a range of items to not be clipped, regardless of their visibility.
    // (Due to alignment / padding of certain items it is possible that an extra item may be included on either end of the display range).
    inline void     IncludeItemByIndex(i32 item_index)                  { IncludeItemsByIndex(item_index, item_index + 1); }
    void  IncludeItemsByIndex(i32 item_begin, i32 item_end);  // item_end is exclusive e.g. use (42, 42+1) to make item 42 never clipped.

    // Seek cursor toward given item. This is automatically called while stepping.
    // - The only reason to call this is: you can use ImGuiListClipper::Begin(INT_MAX) if you don't know item count ahead of time.
    // - In this case, after all steps are done, you'll want to call SeekCursorForItem(item_count).
    void  SeekCursorForItem(i32 item_index);

};

// Helpers: ImVec2/ImVec4 operators
// - It is important that we are keeping those disabled by default so they don't leak in user space.
// - This is in order to allow user enabling implicit cast operators between ImVec2/ImVec4 and their own types (using IM_VEC2_CLASS_EXTRA in imconfig.h)
// - Add '#define IMGUI_DEFINE_MATH_OPERATORS' before including this file (or in imconfig.h) to access courtesy maths operators for ImVec2 and ImVec4.
// - We intentionally provide ImVec2*float but not float*ImVec2: this is rare enough and we want to reduce the surface for possible user mistake.

// Helpers macros to generate 32-bit encoded colors
// - User can declare their own format by #defining the 5 _SHIFT/_MASK macros in their imconfig file.
// - Any setting other than the default will need custom backend support. The only standard backend that supports anything else than the default is DirectX9.
when !(IM_COL32_R_SHIFT) {
when IMGUI_USE_BGRA_PACKED_COLOR {
IM_COL32_R_SHIFT :: 16
IM_COL32_G_SHIFT :: 8
IM_COL32_B_SHIFT :: 0
IM_COL32_A_SHIFT :: 24
IM_COL32_A_MASK :: 0xFF000000
} else {
IM_COL32_R_SHIFT :: 0
IM_COL32_G_SHIFT :: 8
IM_COL32_B_SHIFT :: 16
IM_COL32_A_SHIFT :: 24
IM_COL32_A_MASK :: 0xFF000000
}
}
#define IM_COL32(R,G,B,A)    (((ImU32)(A)<<IM_COL32_A_SHIFT) | ((ImU32)(B)<<IM_COL32_B_SHIFT) | ((ImU32)(G)<<IM_COL32_G_SHIFT) | ((ImU32)(R)<<IM_COL32_R_SHIFT))
#define IM_COL32_WHITE       IM_COL32(255,255,255,255)  // Opaque white = 0xFFFFFFFF
#define IM_COL32_BLACK       IM_COL32(0,0,0,255)        // Opaque black
#define IM_COL32_BLACK_TRANS IM_COL32(0,0,0,0)          // Transparent black = 0x00000000

// Helper: ImColor() implicitly converts colors to either ImU32 (packed 4x1 byte) or ImVec4 (4x1 float)
// Prefer using IM_COL32() macros if you want a guaranteed compile-time ImU32 for usage with ImDrawList API.
// **Avoid storing ImColor! Store either u32 of ImVec4. This is not a full-featured color class. MAY OBSOLETE.
// **None of the ImGui API are using ImColor directly but you can use it as a convenience to pass colors in either ImU32 or ImVec4 formats. Explicitly cast to ImU32 or ImVec4 if needed.
ImColor :: struct
{
    Value : ImVec4,

    constexpr ImColor()                                             { }
    constexpr ImColor(f32 r, f32 g, f32 b, f32 a = 1.0)    : Value(r, g, b, a) { }
    constexpr ImColor(const ImVec4& col)                            : Value(col) {}
    constexpr ImColor(i32 r, i32 g, i32 b, i32 a = 255)             : Value(cast(ast) ast) a.0 / 255.0), cast(0),) cast(0),) c255.0), cast(c25) .0), cast(c25) .), cast(cas) (c25) .), cast(cas) 
    constexpr ImColor(u32 rgba)                                   : Value((f32)((rgba >> IM_COL32_R_SHIFT) & 0xFF) * (1.0 / 255.0), (f32)((rgba >> IM_COL32_G_SHIFT) & 0xFF) * (1.0 / 255.0), (f32)((rgba >> IM_COL32_B_SHIFT) & 0xFF) * (1.0 / 255.0), (f32)((rgba >> IM_COL32_A_SHIFT) & 0xFF) * (1.0 / 255.0)) {}
    inline operator u32() const                                   { return ColorConvertFloat4ToU32(Value); }
    inline operator ImVec4() const                                  { return Value; }

    // FIXME-OBSOLETE: May need to obsolete/cleanup those helpers.
    inline void    SetHSV(f32 h, f32 s, f32 v, f32 a = 1.0){ ColorConvertHSVtoRGB(h, s, v, Value.x, Value.y, Value.z); Value.w = a; }
    static ImColor HSV(f32 h, f32 s, f32 v, f32 a = 1.0)   { f32 r, g, b; ColorConvertHSVtoRGB(h, s, v, r, g, b); return ImColor(r, g, b, a); }
};

//-----------------------------------------------------------------------------
// [SECTION] Multi-Select API flags and structures (ImGuiMultiSelectFlags, ImGuiSelectionRequestType, ImGuiSelectionRequest, ImGuiMultiSelectIO, ImGuiSelectionBasicStorage)
//-----------------------------------------------------------------------------

// Multi-selection system
// Documentation at: https://github.com/ocornut/imgui/wiki/Multi-Select
// - Refer to 'Demo->Widgets->Selection State & Multi-Select' for demos using this.
// - This system implements standard multi-selection idioms (CTRL+Mouse/Keyboard, SHIFT+Mouse/Keyboard, etc)
//   with support for clipper (skipping non-visible items), box-select and many other details.
// - Selectable(), Checkbox() are supported but custom widgets may use it as well.
// - TreeNode() is technically supported but... using this correctly is more complicated: you need some sort of linear/random access to your tree,
//   which is suited to advanced trees setups also implementing filters and clipper. We will work toward simplifying and demoing it.
// - In the spirit of Dear ImGui design, your code owns actual selection data.
//   This is designed to allow all kinds of selection storage you may use in your application e.g. set/map/hash.
// About ImGuiSelectionBasicStorage:
// - This is an optional helper to store a selection state and apply selection requests.
// - It is used by our demos and provided as a convenience to quickly implement multi-selection.
// Usage:
// - Identify submitted items with SetNextItemSelectionUserData(), most likely using an index into your current data-set.
// - Store and maintain actual selection data using persistent object identifiers.
// - Usage flow:
//     BEGIN - (1) Call BeginMultiSelect() and retrieve the ImGuiMultiSelectIO* result.
//           - (2) Honor request list (SetAll/SetRange requests) by updating your selection data. Same code as Step 6.
//           - (3) [If using clipper] You need to make sure RangeSrcItem is always submitted. Calculate its index and pass to clipper.IncludeItemByIndex(). If storing indices in ImGuiSelectionUserData, a simple clipper.IncludeItemByIndex(ms_io->RangeSrcItem) call will work.
//     LOOP  - (4) Submit your items with SetNextItemSelectionUserData() + Selectable()/TreeNode() calls.
//     END   - (5) Call EndMultiSelect() and retrieve the ImGuiMultiSelectIO* result.
//           - (6) Honor request list (SetAll/SetRange requests) by updating your selection data. Same code as Step 2.
//     If you submit all items (no clipper), Step 2 and 3 are optional and will be handled by each item themselves. It is fine to always honor those steps.
// About ImGuiSelectionUserData:
// - This can store an application-defined identifier (e.g. index or pointer) submitted via SetNextItemSelectionUserData().
// - In return we store them into RangeSrcItem/RangeFirstItem/RangeLastItem and other fields in ImGuiMultiSelectIO.
// - Most applications will store an object INDEX, hence the chosen name and type. Storing an index is natural, because
//   SetRange requests will give you two end-points and you will need to iterate/interpolate between them to update your selection.
// - However it is perfectly possible to store a POINTER or another IDENTIFIER inside ImGuiSelectionUserData.
//   Our system never assume that you identify items by indices, it never attempts to interpolate between two values.
// - If you enable ImGuiMultiSelectFlags_NoRangeSelect then it is guaranteed that you will never have to interpolate
//   between two ImGuiSelectionUserData, which may be a convenient way to use part of the feature with less code work.
// - As most users will want to store an index, for convenience and to reduce confusion we use ImS64 instead of void*,
//   being syntactically easier to downcast. Feel free to reinterpret_cast and store a pointer inside.

// Flags for BeginMultiSelect()
ImGuiMultiSelectFlags :: bit_set[ImGuiMultiSelectFlag; i32]
ImGuiMultiSelectFlag :: enum
{
    // [removed] -> nil: None                  = 0,
    SingleSelect          = 0,   // Disable selecting more than one item. This is available to allow single-selection code to share same code/logic if desired. It essentially disables the main purpose of BeginMultiSelect() tho!
    NoSelectAll           = 1,   // Disable CTRL+A shortcut to select all.
    NoRangeSelect         = 2,   // Disable Shift+selection mouse/keyboard support (useful for unordered 2D selection). With BoxSelect is also ensure contiguous SetRange requests are not combined into one. This allows not handling interpolation in SetRange requests.
    NoAutoSelect          = 3,   // Disable selecting items when navigating (useful for e.g. supporting range-select in a list of checkboxes).
    NoAutoClear           = 4,   // Disable clearing selection when navigating or selecting another one (generally used with ImGuiMultiSelectFlags_NoAutoSelect. useful for e.g. supporting range-select in a list of checkboxes).
    NoAutoClearOnReselect = 5,   // Disable clearing selection when clicking/selecting an already selected item.
    BoxSelect1d           = 6,   // Enable box-selection with same width and same x pos items (e.g. full row Selectable()). Box-selection works better with little bit of spacing between items hit-box in order to be able to aim at empty space.
    BoxSelect2d           = 7,   // Enable box-selection with varying width or varying x pos items support (e.g. different width labels, or 2D layout/grid). This is slower: alters clipping logic so that e.g. horizontal movements will update selection of normally clipped items.
    BoxSelectNoScroll     = 8,   // Disable scrolling when box-selecting near edges of scope.
    ClearOnEscape         = 9,   // Clear selection when pressing Escape while scope is focused.
    ClearOnClickVoid      = 10,  // Clear selection when clicking on empty location within scope.
    ScopeWindow           = 11,  // Scope for _BoxSelect and _ClearOnClickVoid is whole window (Default). Use if BeginMultiSelect() covers a whole window or used a single time in same window.
    ScopeRect             = 12,  // Scope for _BoxSelect and _ClearOnClickVoid is rectangle encompassing BeginMultiSelect()/EndMultiSelect(). Use if BeginMultiSelect() is called multiple times in same window.
    SelectOnClick         = 13,  // Apply selection on mouse down when clicking on unselected item. (Default)
    SelectOnClickRelease  = 14,  // Apply selection on mouse release when clicking an unselected item. Allow dragging an unselected item without altering selection.
    //ImGuiMultiSelectFlags_RangeSelect2d       = 1 << 15,  // Shift+Selection uses 2d geometry instead of linear sequence, so possible to use Shift+up/down to select vertically in grid. Analogous to what BoxSelect does.
    NavWrapX              = 16,  // [Temporary] Enable navigation wrapping on X axis. Provided as a convenience because we don't have a design for the general Nav API for this yet. When the more general feature be public we may obsolete this flag in favor of new one.
};

// Main IO structure returned by BeginMultiSelect()/EndMultiSelect().
// This mainly contains a list of selection requests.
// - Use 'Demo->Tools->Debug Log->Selection' to see requests as they happen.
// - Some fields are only useful if your list is dynamic and allows deletion (getting post-deletion focus/state right is shown in the demo)
// - Below: who reads/writes each fields? 'r'=read, 'w'=write, 'ms'=multi-select code, 'app'=application/user code.
ImGuiMultiSelectIO :: struct
{
    //------------------------------------------// BeginMultiSelect / EndMultiSelect
    Requests : [dynamic]ImGuiSelectionRequest,   //  ms:w, app:r     /  ms:w  app:r   // Requests to apply to your selection data.
    RangeSrcItem : ImGuiSelectionUserData,   //  ms:w  app:r     /                // (If using clipper) Begin: Source item (often the first selected item) must never be clipped: use clipper.IncludeItemByIndex() to ensure it is submitted.
    NavIdItem : ImGuiSelectionUserData,      //  ms:w, app:r     /                // (If using deletion) Last known SetNextItemSelectionUserData() value for NavId (if part of submitted items).
    NavIdSelected : bool,  //  ms:w, app:r     /        app:r   // (If using deletion) Last known selection state for NavId (if part of submitted items).
    RangeSrcReset : bool,  //        app:w     /  ms:r          // (If using deletion) Set before EndMultiSelect() to reset ResetSrcItem (e.g. if deleted selection).
    ItemsCount : i32,     //  ms:w, app:r     /        app:r   // 'int items_count' parameter to BeginMultiSelect() is copied here for convenience, allowing simpler calls to your ApplyRequests handler. Not used internally.
};

// Selection request type
ImGuiSelectionRequestType :: enum i32
{
    // [removed] -> nil: None = 0,
    SetAll,           // Request app to clear selection (if Selected==false) or select all items (if Selected==true). We cannot set RangeFirstItem/RangeLastItem as its contents is entirely up to user (not necessarily an index)
    SetRange,         // Request app to select/unselect [RangeFirstItem..RangeLastItem] items (inclusive) based on value of Selected. Only EndMultiSelect() request this, app code can read after BeginMultiSelect() and it will always be false.
};

// Selection request item
ImGuiSelectionRequest :: struct
{
    //------------------------------------------// BeginMultiSelect / EndMultiSelect
    Type : ImGuiSelectionRequestType,           //  ms:w, app:r     /  ms:w, app:r   // Request type. You'll most often receive 1 Clear + 1 SetRange with a single-item range.
    Selected : bool,       //  ms:w, app:r     /  ms:w, app:r   // Parameter for SetAll/SetRange requests (true = select, false = unselect)
    RangeDirection : i8, //                  /  ms:w  app:r   // Parameter for SetRange request: +1 when RangeFirstItem comes before RangeLastItem, -1 otherwise. Useful if you want to preserve selection order on a backward Shift+Click.
    RangeFirstItem : ImGuiSelectionUserData, //                  /  ms:w, app:r   // Parameter for SetRange request (this is generally == RangeSrcItem when shift selecting from top to bottom).
    RangeLastItem : ImGuiSelectionUserData,  //                  /  ms:w, app:r   // Parameter for SetRange request (this is generally == RangeSrcItem when shift selecting from bottom to top). Inclusive!
};

// Optional helper to store multi-selection state + apply multi-selection requests.
// - Used by our demos and provided as a convenience to easily implement basic multi-selection.
// - Iterate selection with 'void* it = NULL; ImGuiID id; while (selection.GetNextSelectedItem(&it, &id)) { ... }'
//   Or you can check 'if (Contains(id)) { ... }' for each possible object if their number is not too high to iterate.
// - USING THIS IS NOT MANDATORY. This is only a helper and not a required API.
// To store a multi-selection, in your application you could:
// - Use this helper as a convenience. We use our simple key->value ImGuiStorage as a std::set<ImGuiID> replacement.
// - Use your own external storage: e.g. std::set<MyObjectId>, std::vector<MyObjectId>, interval trees, intrusively stored selection etc.
// In ImGuiSelectionBasicStorage we:
// - always use indices in the multi-selection API (passed to SetNextItemSelectionUserData(), retrieved in ImGuiMultiSelectIO)
// - use the AdapterIndexToStorageId() indirection layer to abstract how persistent selection data is derived from an index.
// - use decently optimized logic to allow queries and insertion of very large selection sets.
// - do not preserve selection order.
// Many combinations are possible depending on how you prefer to store your items and how you prefer to store your selection.
// Large applications are likely to eventually want to get rid of this indirection layer and do their own thing.
// See https://github.com/ocornut/imgui/wiki/Multi-Select for details and pseudo-code using this helper.
ImGuiSelectionBasicStorage :: struct
{
    // Members
    Size : i32,           //          // Number of selected items, maintained by this helper.
    PreserveOrder : bool,  // = false  // GetNextSelectedItem() will return ordered selection (currently implemented by two additional sorts of selection. Could be improved)
    UserData : rawptr,       // = NULL   // User data for use by adapter function        // e.g. selection.UserData = (void*)my_items;
    ImGuiID         (*AdapterIndexToStorageId)(ImGuiSelectionBasicStorage* self, i32 idx);      // e.g. selection.AdapterIndexToStorageId = [](ImGuiSelectionBasicStorage* self, int idx) { return ((MyItems**)self->UserData)[idx]->ID; };
    _SelectionOrder : i32,// [Internal] Increasing counter to store selection order
    _Storage : ImGuiStorage,       // [Internal] Selection set. Think of this as similar to e.g. std::set<ImGuiID>. Prefer not accessing directly: iterate with GetNextSelectedItem().

    // Methods
    ImGuiSelectionBasicStorage();
    void  ApplyRequests(ImGuiMultiSelectIO* ms_io);   // Apply selection requests coming from BeginMultiSelect() and EndMultiSelect() functions. It uses 'items_count' passed to BeginMultiSelect()
    bool  Contains(ImGuiID id) const;                 // Query if an item id is in selection.
    void  Clear();                                    // Clear selection
    void  Swap(ImGuiSelectionBasicStorage& r);        // Swap two selections
    void  SetItemSelected(ImGuiID id, bool selected); // Add/remove an item from selection (generally done by ApplyRequests() function)
    bool  GetNextSelectedItem(rawptr* opaque_it, ImGuiID* out_id); // Iterate selection with 'void* it = NULL; ImGuiID id; while (selection.GetNextSelectedItem(&it, &id)) { ... }'
    inline ImGuiID  GetStorageIdFromIndex(i32 idx)              { return AdapterIndexToStorageId(this, idx); }  // Convert index to item id based on provided adapter.
};

// Optional helper to apply multi-selection requests to existing randomly accessible storage.
// Convenient if you want to quickly wire multi-select API on e.g. an array of bool or items storing their own selection state.
ImGuiSelectionExternalStorage :: struct
{
    // Members
    UserData : rawptr,       // User data for use by adapter function                                // e.g. selection.UserData = (void*)my_items;
    void            (*AdapterSetItemSelected)(ImGuiSelectionExternalStorage* self, i32 idx, bool selected); // e.g. AdapterSetItemSelected = [](ImGuiSelectionExternalStorage* self, int idx, bool selected) { ((MyItems**)self->UserData)[idx]->Selected = selected; }

    // Methods
    ImGuiSelectionExternalStorage();
    void  ApplyRequests(ImGuiMultiSelectIO* ms_io);   // Apply selection requests by using AdapterSetItemSelected() calls
};

//-----------------------------------------------------------------------------
// [SECTION] Drawing API (ImDrawCmd, ImDrawIdx, ImDrawVert, ImDrawChannel, ImDrawListSplitter, ImDrawListFlags, ImDrawList, ImDrawData)
// Hold a series of drawing commands. The user provides a renderer for ImDrawData which essentially contains an array of ImDrawList.
//-----------------------------------------------------------------------------

// The maximum line width to bake anti-aliased textures for. Build atlas with ImFontAtlasFlags_NoBakedLines to disable baking.
when !(IM_DRAWLIST_TEX_LINES_WIDTH_MAX) {
#define IM_DRAWLIST_TEX_LINES_WIDTH_MAX     (63)
}

// ImDrawCallback: Draw callbacks for advanced uses [configurable type: override in imconfig.h]
// NB: You most likely do NOT need to use draw callbacks just to create your own widget or customized UI rendering,
// you can poke into the draw list for that! Draw callback may be useful for example to:
//  A) Change your GPU render state,
//  B) render a complex 3D scene inside a UI element without an intermediate texture/render target, etc.
// The expected behavior from your rendering function is 'if (cmd.UserCallback != NULL) { cmd.UserCallback(parent_list, cmd); } else { RenderTriangles() }'
// If you want to override the signature of ImDrawCallback, you can simply use e.g. '#define ImDrawCallback MyDrawCallback' (in imconfig.h) + update rendering backend accordingly.
when !(ImDrawCallback) {
ImDrawCallback :: #type proc(parent_list : ^ImDrawList, cmd : ^ImDrawCmd)
}

// Special Draw callback value to request renderer backend to reset the graphics/render state.
// The renderer backend needs to handle this special value, otherwise it will crash trying to call a function at this address.
// This is useful, for example, if you submitted callbacks which you know have altered the render state and you want it to be restored.
// Render state is not reset by default because they are many perfectly useful way of altering render state (e.g. changing shader/blending settings before an Image call).
#define ImDrawCallback_ResetRenderState     (ImDrawCallback)(-8)

// Typically, 1 command = 1 GPU draw call (unless command is a callback)
// - VtxOffset: When 'io.BackendFlags & ImGuiBackendFlags_RendererHasVtxOffset' is enabled,
//   this fields allow us to render meshes larger than 64K vertices while keeping 16-bit indices.
//   Backends made for <1.71. will typically ignore the VtxOffset fields.
// - The ClipRect/TextureId/VtxOffset fields must be contiguous as we memcmp() them together (this is asserted for).
ImDrawCmd :: struct
{
    ClipRect : ImVec4,           // 4*4  // Clipping rectangle (x1, y1, x2, y2). Subtract ImDrawData->DisplayPos to get clipping rectangle in "viewport" coordinates
    TextureId : ImTextureID,          // 4-8  // User-provided texture ID. Set by user in ImfontAtlas::SetTexID() for fonts or passed to Image*() functions. Ignore if never using images or multiple fonts atlas.
    VtxOffset : u32,          // 4    // Start offset in vertex buffer. ImGuiBackendFlags_RendererHasVtxOffset: always 0, otherwise may be >0 to support meshes larger than 64K vertices with 16-bit indices.
    IdxOffset : u32,          // 4    // Start offset in index buffer.
    ElemCount : u32,          // 4    // Number of indices (multiple of 3) to be rendered as triangles. Vertices are stored in the callee ImDrawList's vtx_buffer[] array, indices in idx_buffer[].
    UserCallback : ImDrawCallback,       // 4-8  // If != NULL, call the function instead of rendering the vertices. clip_rect and texture_id will be set normally.
    UserCallbackData : rawptr,   // 4-8  // Callback user data (when UserCallback != NULL). If called AddCallback() with size == 0, this is a copy of the AddCallback() argument. If called AddCallback() with size > 0, this is pointing to a buffer where data is stored.
    UserCallbackDataSize : i32,  // 4 // Size of callback user data when using storage, otherwise 0.
    UserCallbackDataOffset : i32,// 4 // [Internal] Offset of callback user data when using storage, otherwise -1.

    ImDrawCmd()     { memset(this, 0, size_of(*this)); } // Also ensure our padding fields are zeroed

    // Since 1.83: returns ImTextureID associated with this draw call. Warning: DO NOT assume this is always same as 'TextureId' (we will change this function for an upcoming feature)
    inline ImTextureID GetTexID() const { return TextureId; }
};

// Vertex layout
ImDrawVert :: struct
{
    pos : ImVec2,
    uv : ImVec2,
    col : u32,
};

// [Internal] For use by ImDrawList
ImDrawCmdHeader :: struct
{
    ClipRect : ImVec4,
    TextureId : ImTextureID,
    VtxOffset : u32,
};

// [Internal] For use by ImDrawListSplitter
ImDrawChannel :: struct
{
    _CmdBuffer : [dynamic]ImDrawCmd,
    _IdxBuffer : [dynamic]ImDrawIdx,
};


// Split/Merge functions are used to split the draw list into different layers which can be drawn into out of order.
// This is used by the Columns/Tables API, so items of each column can be batched together in a same draw call.
ImDrawListSplitter :: struct
{
    _Current : i32,    // Current channel number (0)
    _Count : i32,      // Number of active channels (1+)
    _Channels : [dynamic]ImDrawChannel,   // Draw channels (not resized down so _Count might be < Channels.Size)

    inline ImDrawListSplitter()  { memset(this, 0, size_of(*this)); }
    inline ~ImDrawListSplitter() { ClearFreeMemory(); }
    inline void                 Clear() { _Current = 0; _Count = 1; } // Do not clear Channels[] so our allocations are reused next frame
    void              ClearFreeMemory();
    void              Split(ImDrawList* draw_list, i32 count);
    void              Merge(ImDrawList* draw_list);
    void              SetCurrentChannel(ImDrawList* draw_list, i32 channel_idx);
};

// Flags for ImDrawList functions
// (Legacy: bit 0 must always correspond to ImDrawFlags_Closed to be backward compatible with old API using a bool. Bits 1..3 must be unused)
ImDrawFlags :: bit_set[ImDrawFlag; i32]
ImDrawFlag :: enum
{
    // [removed] -> nil: None                        = 0,
    Closed                      = 0, // PathStroke(), AddPolyline(): specify that shape should be closed (Important: this is always == 1 for legacy reason)
    RoundCornersTopLeft         = 4, // AddRect(), AddRectFilled(), PathRect(): enable rounding top-left corner only (when rounding > 0.0f, we default to all corners). Was 0x01.
    RoundCornersTopRight        = 5, // AddRect(), AddRectFilled(), PathRect(): enable rounding top-right corner only (when rounding > 0.0f, we default to all corners). Was 0x02.
    RoundCornersBottomLeft      = 6, // AddRect(), AddRectFilled(), PathRect(): enable rounding bottom-left corner only (when rounding > 0.0f, we default to all corners). Was 0x04.
    RoundCornersBottomRight     = 7, // AddRect(), AddRectFilled(), PathRect(): enable rounding bottom-right corner only (when rounding > 0.0f, we default to all corners). Wax 0x08.
    RoundCornersNone            = 8, // AddRect(), AddRectFilled(), PathRect(): disable rounding on all corners (when rounding > 0.0f). This is NOT zero, NOT an implicit flag!
    // [moved] RoundCornersTop             = RoundCornersTopLeft | RoundCornersTopRight,
    // [moved] RoundCornersBottom          = RoundCornersBottomLeft | RoundCornersBottomRight,
    // [moved] RoundCornersLeft            = RoundCornersBottomLeft | RoundCornersTopLeft,
    // [moved] RoundCornersRight           = RoundCornersBottomRight | RoundCornersTopRight,
    // [moved] RoundCornersAll             = RoundCornersTopLeft | RoundCornersTopRight | RoundCornersBottomLeft | RoundCornersBottomRight,
    // [moved] RoundCornersDefault_        = RoundCornersAll, // Default to ALL corners if none of the _RoundCornersXX flags are specified.
    // [moved] RoundCornersMask_           = RoundCornersAll | RoundCornersNone,
};
ImDrawFlags_RoundCornersTop :: { RoundCornersTopLeft , RoundCornersTopRight }
ImDrawFlags_RoundCornersBottom :: { RoundCornersBottomLeft , RoundCornersBottomRight }
ImDrawFlags_RoundCornersLeft :: { RoundCornersBottomLeft , RoundCornersTopLeft }
ImDrawFlags_RoundCornersRight :: { RoundCornersBottomRight , RoundCornersTopRight }
ImDrawFlags_RoundCornersAll :: { RoundCornersTopLeft , RoundCornersTopRight , RoundCornersBottomLeft , RoundCornersBottomRight }
ImDrawFlags_RoundCornersDefault_ :: { RoundCornersAll }
ImDrawFlags_RoundCornersMask_ :: { RoundCornersAll , RoundCornersNone }

// Flags for ImDrawList instance. Those are set automatically by ImGui:: functions from ImGuiIO settings, and generally not manipulated directly.
// It is however possible to temporarily alter flags between calls to ImDrawList:: functions.
ImDrawListFlags :: bit_set[ImDrawListFlag; i32]
ImDrawListFlag :: enum
{
    // [removed] -> nil: None                    = 0,
    AntiAliasedLines        = 0,  // Enable anti-aliased lines/borders (*2 the number of triangles for 1.0f wide line or lines thin enough to be drawn using textures, otherwise *3 the number of triangles)
    AntiAliasedLinesUseTex  = 1,  // Enable anti-aliased lines/borders using textures when possible. Require backend to render with bilinear filtering (NOT point/nearest filtering).
    AntiAliasedFill         = 2,  // Enable anti-aliased edge around filled shapes (rounded rectangles, circles).
    AllowVtxOffset          = 3,  // Can emit 'VtxOffset > 0' to allow large meshes. Set when 'ImGuiBackendFlags_RendererHasVtxOffset' is enabled.
};

// Draw command list
// This is the low-level list of polygons that ImGui:: functions are filling. At the end of the frame,
// all command lists are passed to your ImGuiIO::RenderDrawListFn function for rendering.
// Each dear imgui window contains its own ImDrawList. You can use ImGui::GetWindowDrawList() to
// access the current window draw list and draw custom primitives.
// You can interleave normal ImGui:: calls and adding primitives to the current draw list.
// In single viewport mode, top-left is == GetMainViewport()->Pos (generally 0,0), bottom-right is == GetMainViewport()->Pos+Size (generally io.DisplaySize).
// You are totally free to apply whatever transformation matrix you want to the data (depending on the use of the transformation you may want to apply it to ClipRect as well!)
// Important: Primitives are always added to the list and not culled (culling is done at higher-level by ImGui:: functions), if you use this API a lot consider coarse culling your drawn objects.
ImDrawList :: struct
{
    // This is what you have to render
    CmdBuffer : [dynamic]ImDrawCmd,          // Draw commands. Typically 1 command = 1 GPU draw call, unless the command is a callback.
    IdxBuffer : [dynamic]ImDrawIdx,          // Index buffer. Each command consume ImDrawCmd::ElemCount of those
    VtxBuffer : [dynamic]ImDrawVert,          // Vertex buffer.
    Flags : ImDrawListFlags,              // Flags, you may poke into these to adjust anti-aliasing settings per-primitive.

    // [Internal, used while building lists]
    _VtxCurrentIdx : u32,     // [Internal] generally == VtxBuffer.Size unless we are past 64K vertices, in which case this gets reset to 0.
    _Data : ^ImDrawListSharedData,              // Pointer to shared draw data (you can use ImGui::GetDrawListSharedData() to get the one from current ImGui context)
    _VtxWritePtr : ^ImDrawVert,       // [Internal] point within VtxBuffer.Data after each add command (to avoid using the ImVector<> operators too much)
    _IdxWritePtr : ^ImDrawIdx,       // [Internal] point within IdxBuffer.Data after each add command (to avoid using the ImVector<> operators too much)
    _Path : [dynamic]ImVec2,              // [Internal] current path building
    _CmdHeader : ImDrawCmdHeader,         // [Internal] template of active commands. Fields should match those of CmdBuffer.back().
    _Splitter : ImDrawListSplitter,          // [Internal] for channels api (note: prefer using your own persistent instance of ImDrawListSplitter!)
    _ClipRectStack : [dynamic]ImVec4,     // [Internal]
    _TextureIdStack : [dynamic]ImTextureID,    // [Internal]
    _CallbacksDataBuf : [dynamic]u8,  // [Internal]
    _FringeScale : f32,       // [Internal] anti-alias fringe is scaled by this value, this helps to keep things sharp while zooming at vertex buffer content
    _OwnerName : ^u8,         // Pointer to owner window's name for debugging

    // If you want to create ImDrawList instances, pass them ImGui::GetDrawListSharedData().
    // (advanced: you may create and use your own ImDrawListSharedData so you can use ImDrawList without ImGui, but that's more involved)
    ImDrawList(ImDrawListSharedData* shared_data);
    ~ImDrawList();

    void  PushClipRect(const ImVec2& clip_rect_min, const ImVec2& clip_rect_max, bool intersect_with_current_clip_rect = false);  // Render-level scissoring. This is passed down to your render function but not used for CPU-side coarse clipping. Prefer using higher-level ImGui::PushClipRect() to affect logic (hit-testing and widget culling)
    void  PushClipRectFullScreen();
    void  PopClipRect();
    void  PushTextureID(ImTextureID texture_id);
    void  PopTextureID();
    inline ImVec2   GetClipRectMin() const { const ImVec4& cr = _ClipRectStack.back(); return ImVec2{cr.x, cr.y}; }
    inline ImVec2   GetClipRectMax() const { const ImVec4& cr = _ClipRectStack.back(); return ImVec2{cr.z, cr.w}; }

    // Primitives
    // - Filled shapes must always use clockwise winding order. The anti-aliasing fringe depends on it. Counter-clockwise shapes will have "inward" anti-aliasing.
    // - For rectangular primitives, "p_min" and "p_max" represent the upper-left and lower-right corners.
    // - For circle primitives, use "num_segments == 0" to automatically calculate tessellation (preferred).
    //   In older versions (until Dear ImGui 1.77) the AddCircle functions defaulted to num_segments == 12.
    //   In future versions we will use textures to provide cheaper and higher-quality circles.
    //   Use AddNgon() and AddNgonFilled() functions if you need to guarantee a specific number of sides.
    void  AddLine(const ImVec2& p1, const ImVec2& p2, u32 col, f32 thickness = 1.0);
    void  AddRect(const ImVec2& p_min, const ImVec2& p_max, u32 col, f32 rounding = 0.0, ImDrawFlags flags = 0, f32 thickness = 1.0);   // a: upper-left, b: lower-right (== upper-left + size)
    void  AddRectFilled(const ImVec2& p_min, const ImVec2& p_max, u32 col, f32 rounding = 0.0, ImDrawFlags flags = 0);                     // a: upper-left, b: lower-right (== upper-left + size)
    void  AddRectFilledMultiColor(const ImVec2& p_min, const ImVec2& p_max, u32 col_upr_left, u32 col_upr_right, u32 col_bot_right, u32 col_bot_left);
    void  AddQuad(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, u32 col, f32 thickness = 1.0);
    void  AddQuadFilled(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, u32 col);
    void  AddTriangle(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, u32 col, f32 thickness = 1.0);
    void  AddTriangleFilled(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, u32 col);
    void  AddCircle(const ImVec2& center, f32 radius, u32 col, i32 num_segments = 0, f32 thickness = 1.0);
    void  AddCircleFilled(const ImVec2& center, f32 radius, u32 col, i32 num_segments = 0);
    void  AddNgon(const ImVec2& center, f32 radius, u32 col, i32 num_segments, f32 thickness = 1.0);
    void  AddNgonFilled(const ImVec2& center, f32 radius, u32 col, i32 num_segments);
    void  AddEllipse(const ImVec2& center, const ImVec2& radius, u32 col, f32 rot = 0.0, i32 num_segments = 0, f32 thickness = 1.0);
    void  AddEllipseFilled(const ImVec2& center, const ImVec2& radius, u32 col, f32 rot = 0.0, i32 num_segments = 0);
    void  AddText(const ImVec2& pos, u32 col, const u8* text_begin, const u8* text_end = nil);
    void  AddText(ImFont* font, f32 font_size, const ImVec2& pos, u32 col, const u8* text_begin, const u8* text_end = nil, f32 wrap_width = 0.0, const ImVec4* cpu_fine_clip_rect = nil);
    void  AddBezierCubic(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, u32 col, f32 thickness, i32 num_segments = 0); // Cubic Bezier (4 control points)
    void  AddBezierQuadratic(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, u32 col, f32 thickness, i32 num_segments = 0);               // Quadratic Bezier (3 control points)

    // General polygon
    // - Only simple polygons are supported by filling functions (no self-intersections, no holes).
    // - Concave polygon fill is more expensive than convex one: it has O(N^2) complexity. Provided as a convenience fo user but not used by main library.
    void  AddPolyline(const ImVec2* points, i32 num_points, u32 col, ImDrawFlags flags, f32 thickness);
    void  AddConvexPolyFilled(const ImVec2* points, i32 num_points, u32 col);
    void  AddConcavePolyFilled(const ImVec2* points, i32 num_points, u32 col);

    // Image primitives
    // - Read FAQ to understand what ImTextureID is.
    // - "p_min" and "p_max" represent the upper-left and lower-right corners of the rectangle.
    // - "uv_min" and "uv_max" represent the normalized texture coordinates to use for those corners. Using (0,0)->(1,1) texture coordinates will generally display the entire texture.
    void  AddImage(ImTextureID user_texture_id, const ImVec2& p_min, const ImVec2& p_max, const ImVec2& uv_min = ImVec2{0, 0}, const ImVec2& uv_max = ImVec2{1, 1}, u32 col = IM_COL32_WHITE);
    void  AddImageQuad(ImTextureID user_texture_id, const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, const ImVec2& uv1 = ImVec2{0, 0}, const ImVec2& uv2 = ImVec2{1, 0}, const ImVec2& uv3 = ImVec2{1, 1}, const ImVec2& uv4 = ImVec2{0, 1}, u32 col = IM_COL32_WHITE);
    void  AddImageRounded(ImTextureID user_texture_id, const ImVec2& p_min, const ImVec2& p_max, const ImVec2& uv_min, const ImVec2& uv_max, u32 col, f32 rounding, ImDrawFlags flags = 0);

    // Stateful path API, add points then finish with PathFillConvex() or PathStroke()
    // - Important: filled shapes must always use clockwise winding order! The anti-aliasing fringe depends on it. Counter-clockwise shapes will have "inward" anti-aliasing.
    //   so e.g. 'PathArcTo(center, radius, PI * -0.5f, PI)' is ok, whereas 'PathArcTo(center, radius, PI, PI * -0.5f)' won't have correct anti-aliasing when followed by PathFillConvex().
    inline    void  PathClear()                                                 { _Path.Size = 0; }
    inline    void  PathLineTo(const ImVec2& pos)                               { _Path.push_back(pos); }
    inline    void  PathLineToMergeDuplicate(const ImVec2& pos)                 { if (_Path.Size == 0 || memcmp(&_Path.Data[_Path.Size - 1], &pos, 8) != 0) _Path.push_back(pos); }
    inline    void  PathFillConvex(u32 col)                                   { AddConvexPolyFilled(_Path.Data, _Path.Size, col); _Path.Size = 0; }
    inline    void  PathFillConcave(u32 col)                                  { AddConcavePolyFilled(_Path.Data, _Path.Size, col); _Path.Size = 0; }
    inline    void  PathStroke(u32 col, ImDrawFlags flags = 0, f32 thickness = 1.0) { AddPolyline(_Path.Data, _Path.Size, col, flags, thickness); _Path.Size = 0; }
    void  PathArcTo(const ImVec2& center, f32 radius, f32 a_min, f32 a_max, i32 num_segments = 0);
    void  PathArcToFast(const ImVec2& center, f32 radius, i32 a_min_of_12, i32 a_max_of_12);                // Use precomputed angles for a 12 steps circle
    void  PathEllipticalArcTo(const ImVec2& center, const ImVec2& radius, f32 rot, f32 a_min, f32 a_max, i32 num_segments = 0); // Ellipse
    void  PathBezierCubicCurveTo(const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, i32 num_segments = 0); // Cubic Bezier (4 control points)
    void  PathBezierQuadraticCurveTo(const ImVec2& p2, const ImVec2& p3, i32 num_segments = 0);               // Quadratic Bezier (3 control points)
    void  PathRect(const ImVec2& rect_min, const ImVec2& rect_max, f32 rounding = 0.0, ImDrawFlags flags = 0);

    // Advanced: Draw Callbacks
    // - May be used to alter render state (change sampler, blending, current shader). May be used to emit custom rendering commands (difficult to do correctly, but possible).
    // - Use special ImDrawCallback_ResetRenderState callback to instruct backend to reset its render state to the default.
    // - Your rendering loop must check for 'UserCallback' in ImDrawCmd and call the function instead of rendering triangles. All standard backends are honoring this.
    // - For some backends, the callback may access selected render-states exposed by the backend in a ImGui_ImplXXXX_RenderState structure pointed to by platform_io.Renderer_RenderState.
    // - IMPORTANT: please be mindful of the different level of indirection between using size==0 (copying argument) and using size>0 (copying pointed data into a buffer).
    //   - If userdata_size == 0: we copy/store the 'userdata' argument as-is. It will be available unmodified in ImDrawCmd::UserCallbackData during render.
    //   - If userdata_size > 0,  we copy/store 'userdata_size' bytes pointed to by 'userdata'. We store them in a buffer stored inside the drawlist. ImDrawCmd::UserCallbackData will point inside that buffer so you have to retrieve data from there. Your callback may need to use ImDrawCmd::UserCallbackDataSize if you expect dynamically-sized data.
    //   - Support for userdata_size > 0 was added in v1.91.4, October 2024. So earlier code always only allowed to copy/store a simple void*.
    void  AddCallback(ImDrawCallback callback, rawptr userdata, int userdata_size = 0);

    // Advanced: Miscellaneous
    void  AddDrawCmd();                                               // This is useful if you need to forcefully create a new draw call (to allow for dependent rendering / blending). Otherwise primitives are merged into the same draw-call as much as possible
    ImDrawList* CloneOutput() const;                                  // Create a clone of the CmdBuffer/IdxBuffer/VtxBuffer.

    // Advanced: Channels
    // - Use to split render into layers. By switching channels to can render out-of-order (e.g. submit FG primitives before BG primitives)
    // - Use to minimize draw calls (e.g. if going back-and-forth between multiple clipping rectangles, prefer to append into separate channels then merge at the end)
    // - This API shouldn't have been in ImDrawList in the first place!
    //   Prefer using your own persistent instance of ImDrawListSplitter as you can stack them.
    //   Using the ImDrawList::ChannelsXXXX you cannot stack a split over another.
    inline void     ChannelsSplit(i32 count)    { _Splitter.Split(this, count); }
    inline void     ChannelsMerge()             { _Splitter.Merge(this); }
    inline void     ChannelsSetCurrent(i32 n)   { _Splitter.SetCurrentChannel(this, n); }

    // Advanced: Primitives allocations
    // - We render triangles (three vertices)
    // - All primitives needs to be reserved via PrimReserve() beforehand.
    void  PrimReserve(i32 idx_count, i32 vtx_count);
    void  PrimUnreserve(i32 idx_count, i32 vtx_count);
    void  PrimRect(const ImVec2& a, const ImVec2& b, u32 col);      // Axis aligned rectangle (composed of two triangles)
    void  PrimRectUV(const ImVec2& a, const ImVec2& b, const ImVec2& uv_a, const ImVec2& uv_b, u32 col);
    void  PrimQuadUV(const ImVec2& a, const ImVec2& b, const ImVec2& c, const ImVec2& d, const ImVec2& uv_a, const ImVec2& uv_b, const ImVec2& uv_c, const ImVec2& uv_d, u32 col);
    inline    void  PrimWriteVtx(const ImVec2& pos, const ImVec2& uv, u32 col)    { _VtxWritePtr.pos = pos; _VtxWritePtr.uv = uv; _VtxWritePtr.col = col; _VtxWritePtr += 1; _VtxCurrentIdx += 1; }
    inline    void  PrimWriteIdx(ImDrawIdx idx)                                     { *_IdxWritePtr = idx; _IdxWritePtr += 1; }
    inline    void  PrimVtx(const ImVec2& pos, const ImVec2& uv, u32 col)         { PrimWriteIdx((ImDrawIdx)_VtxCurrentIdx); PrimWriteVtx(pos, uv, col); } // Write vertex with unique index

    // Obsolete names
    //inline  void  AddEllipse(const ImVec2& center, float radius_x, float radius_y, ImU32 col, float rot = 0.0f, int num_segments = 0, float thickness = 1.0f) { AddEllipse(center, ImVec2(radius_x, radius_y), col, rot, num_segments, thickness); } // OBSOLETED in 1.90.5 (Mar 2024)
    //inline  void  AddEllipseFilled(const ImVec2& center, float radius_x, float radius_y, ImU32 col, float rot = 0.0f, int num_segments = 0) { AddEllipseFilled(center, ImVec2(radius_x, radius_y), col, rot, num_segments); }                        // OBSOLETED in 1.90.5 (Mar 2024)
    //inline  void  PathEllipticalArcTo(const ImVec2& center, float radius_x, float radius_y, float rot, float a_min, float a_max, int num_segments = 0) { PathEllipticalArcTo(center, ImVec2(radius_x, radius_y), rot, a_min, a_max, num_segments); } // OBSOLETED in 1.90.5 (Mar 2024)
    //inline  void  AddBezierCurve(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, ImU32 col, float thickness, int num_segments = 0) { AddBezierCubic(p1, p2, p3, p4, col, thickness, num_segments); }                         // OBSOLETED in 1.80 (Jan 2021)
    //inline  void  PathBezierCurveTo(const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, int num_segments = 0) { PathBezierCubicCurveTo(p2, p3, p4, num_segments); }                                                                                // OBSOLETED in 1.80 (Jan 2021)

    // [Internal helpers]
    void  _ResetForNewFrame();
    void  _ClearFreeMemory();
    void  _PopUnusedDrawCmd();
    void  _TryMergeDrawCmds();
    void  _OnChangedClipRect();
    void  _OnChangedTextureID();
    void  _OnChangedVtxOffset();
    void  _SetTextureID(ImTextureID texture_id);
    i32   _CalcCircleAutoSegmentCount(f32 radius) const;
    void  _PathArcToFastEx(const ImVec2& center, f32 radius, i32 a_min_sample, i32 a_max_sample, i32 a_step);
    void  _PathArcToN(const ImVec2& center, f32 radius, f32 a_min, f32 a_max, i32 num_segments);
};

// All draw data to render a Dear ImGui frame
// (NB: the style and the naming convention here is a little inconsistent, we currently preserve them for backward compatibility purpose,
// as this is one of the oldest structure exposed by the library! Basically, ImDrawList == CmdList)
ImDrawData :: struct
{
    Valid : bool,              // Only valid after Render() is called and before the next NewFrame() is called.
    CmdListsCount : i32,      // Number of ImDrawList* to render
    TotalIdxCount : i32,      // For convenience, sum of all ImDrawList's IdxBuffer.Size
    TotalVtxCount : i32,      // For convenience, sum of all ImDrawList's VtxBuffer.Size
    CmdLists : [dynamic]^ImDrawList,         // Array of ImDrawList* to render. The ImDrawLists are owned by ImGuiContext and only pointed to from here.
    DisplayPos : ImVec2,         // Top-left position of the viewport to render (== top-left of the orthogonal projection matrix to use) (== GetMainViewport()->Pos for the main viewport, == (0.0) in most single-viewport applications)
    DisplaySize : ImVec2,        // Size of the viewport to render (== GetMainViewport()->Size for the main viewport, == io.DisplaySize in most single-viewport applications)
    FramebufferScale : ImVec2,   // Amount of pixels for each unit of DisplaySize. Based on io.DisplayFramebufferScale. Generally (1,1) on normal display, (2,2) on OSX with Retina display.
    OwnerViewport : ^ImGuiViewport,      // Viewport carrying the ImDrawData instance, might be of use to the renderer (generally not).

    // Functions
    ImDrawData()    { Clear(); }
    void  Clear();
    void  AddDrawList(ImDrawList* draw_list);     // Helper to add an external draw list into an existing ImDrawData.
    void  DeIndexAllBuffers();                    // Helper to convert all buffers from indexed to non-indexed, in case you cannot render indexed. Note: this is slow and most likely a waste of resources. Always prefer indexed rendering!
    void  ScaleClipRects(const ImVec2& fb_scale); // Helper to scale the ClipRect field of each ImDrawCmd. Use if your final output buffer is at a different scale than Dear ImGui expects, or if there is a difference between your window resolution and framebuffer resolution.
};

//-----------------------------------------------------------------------------
// [SECTION] Font API (ImFontConfig, ImFontGlyph, ImFontAtlasFlags, ImFontAtlas, ImFontGlyphRangesBuilder, ImFont)
//-----------------------------------------------------------------------------

ImFontConfig :: struct
{
    FontData : rawptr,               //          // TTF/OTF data
    FontDataSize : i32,           //          // TTF/OTF data size
    FontDataOwnedByAtlas : bool,   // true     // TTF/OTF data ownership taken by the container ImFontAtlas (will delete memory itself).
    FontNo : i32,                 // 0        // Index of font within TTF/OTF file
    SizePixels : f32,             //          // Size in pixels for rasterizer (more or less maps to the resulting font height).
    OversampleH : i32,            // 2        // Rasterize at higher quality for sub-pixel positioning. Note the difference between 2 and 3 is minimal. You can reduce this to 1 for large glyphs save memory. Read https://github.com/nothings/stb/blob/master/tests/oversample/README.md for details.
    OversampleV : i32,            // 1        // Rasterize at higher quality for sub-pixel positioning. This is not really useful as we don't use sub-pixel positions on the Y axis.
    PixelSnapH : bool,             // false    // Align every glyph AdvanceX to pixel boundaries. Useful e.g. if you are merging a non-pixel aligned font with the default font. If enabled, you can set OversampleH/V to 1.
    GlyphExtraSpacing : ImVec2,      // 0, 0     // Extra spacing (in pixels) between glyphs when rendered: essentially add to glyph->AdvanceX. Only X axis is supported for now.
    GlyphOffset : ImVec2,            // 0, 0     // Offset all glyphs from this font input.
    GlyphRanges : ^ImWchar,            // NULL     // THE ARRAY DATA NEEDS TO PERSIST AS LONG AS THE FONT IS ALIVE. Pointer to a user-provided list of Unicode range (2 value per range, values are inclusive, zero-terminated list).
    GlyphMinAdvanceX : f32,       // 0        // Minimum AdvanceX for glyphs, set Min to align font icons, set both Min/Max to enforce mono-space font
    GlyphMaxAdvanceX : f32,       // FLT_MAX  // Maximum AdvanceX for glyphs
    MergeMode : bool,              // false    // Merge into previous ImFont, so you can combine multiple inputs font into one ImFont (e.g. ASCII font + icons + Japanese glyphs). You may want to use GlyphOffset.y when merge font of different heights.
    FontBuilderFlags : u32,       // 0        // Settings for custom font builder. THIS IS BUILDER IMPLEMENTATION DEPENDENT. Leave as zero if unsure.
    RasterizerMultiply : f32,     // 1.0f     // Linearly brighten (>1.0f) or darken (<1.0f) font output. Brightening small fonts may be a good workaround to make them more readable. This is a silly thing we may remove in the future.
    RasterizerDensity : f32,      // 1.0f     // DPI scale for rasterization, not altering other font metrics: make it easy to swap between e.g. a 100% and a 400% fonts for a zooming display. IMPORTANT: If you increase this it is expected that you increase font scale accordingly, otherwise quality may look lowered.
    EllipsisChar : ImWchar,           // 0        // Explicitly specify unicode codepoint of ellipsis character. When fonts are being merged first specified ellipsis will be used.

    // [Internal]
    Name : [40]u8,               // Name (strictly to ease debugging)
    DstFont : ^ImFont,

    ImFontConfig();
};

// Hold rendering data for one glyph.
// (Note: some language parsers may fail to convert the 31+1 bitfield members, in this case maybe drop store a single u32 or we can rework this)
ImFontGlyph :: struct
{
    u32    Colored : 1;        // Flag to indicate glyph is colored and should generally ignore tinting (make it usable with no shift on little-endian as this is used in loops)
    u32    Visible : 1;        // Flag to indicate glyph has no visible pixels (e.g. space). Allow early out when rendering.
    u32    Codepoint : 30;     // 0x0000..0x10FFFF
    AdvanceX : f32,           // Distance to next character (= data from font + ImFontConfig::GlyphExtraSpacing.x baked in)
    X0, Y0, X1, Y1 : f32,     // Glyph corners
    U0, V0, U1, V1 : f32,     // Texture coordinates
};

// Helper to build glyph ranges from text/string data. Feed your application strings/characters to it then call BuildRanges().
// This is essentially a tightly packed of vector of 64k booleans = 8KB storage.
ImFontGlyphRangesBuilder :: struct
{
    UsedChars : [dynamic]u32,            // Store 1-bit per Unicode code point (0=unused, 1=used)

    ImFontGlyphRangesBuilder()              { Clear(); }
    inline void     Clear()                 { i32 size_in_bytes = (IM_UNICODE_CODEPOINT_MAX + 1) / 8; UsedChars.resize(size_in_bytes / cast(ast) ast) oft) of); memset(UsedChars.Data, 0, cast( 0,) cast( 0,) test( 0
    inline bool     GetBit(int n) const  { i32 off = (i32)(n >> 5); u32 mask = 1u << (n & 31); return (UsedChars[off] & mask) != 0; }  // Get bit n in the array
    inline void     SetBit(int n)        { i32 off = (i32)(n >> 5); u32 mask = 1u << (n & 31); UsedChars[off] |= mask; }               // Set bit n in the array
    inline void     AddChar(ImWchar c)      { SetBit(c); }                      // Add character
    void  AddText(const u8* text, const u8* text_end = nil);     // Add string (each character of the UTF-8 string are added)
    void  AddRanges(const ImWchar* ranges);                           // Add ranges, e.g. builder.AddRanges(ImFontAtlas::GetGlyphRangesDefault()) to force add all of ASCII/Latin+Ext
    void  BuildRanges(ImVector<ImWchar>* out_ranges);                 // Output new ranges
};

// See ImFontAtlas::AddCustomRectXXX functions.
ImFontAtlasCustomRect :: struct
{
    X, Y : u16,           // Output   // Packed position in Atlas

    // [Internal]
    Width, Height : u16,  // Input    // Desired rectangle dimension
    u32    GlyphID : 31;   // Input    // For custom font glyphs only (ID < 0x110000)
    u32    GlyphColored : 1; // Input  // For custom font glyphs only: glyph is colored, removed tinting.
    GlyphAdvanceX : f32,  // Input    // For custom font glyphs only: glyph xadvance
    GlyphOffset : ImVec2,    // Input    // For custom font glyphs only: glyph display offset
    Font : ^ImFont,           // Input    // For custom font glyphs only: target font
    ImFontAtlasCustomRect()         { X = Y = 0xFFFF; Width = Height = 0; GlyphID = 0; GlyphColored = 0; GlyphAdvanceX = 0.0; GlyphOffset = ImVec2{0, 0}; Font = nil; }
    bool IsPacked() const           { return X != 0xFFFF; }
};

// Flags for ImFontAtlas build
ImFontAtlasFlags :: bit_set[ImFontAtlasFlag; i32]
ImFontAtlasFlag :: enum
{
    // [removed] -> nil: None               = 0,
    NoPowerOfTwoHeight = 0,   // Don't round the height to next power of two
    NoMouseCursors     = 1,   // Don't build software mouse cursors into the atlas (save a little texture memory)
    NoBakedLines       = 2,   // Don't build thick line textures into the atlas (save a little texture memory, allow support for point/nearest filtering). The AntiAliasedLinesUseTex features uses them, otherwise they will be rendered using polygons (more expensive for CPU/GPU).
};

// Load and rasterize multiple TTF/OTF fonts into a same texture. The font atlas will build a single texture holding:
//  - One or more fonts.
//  - Custom graphics data needed to render the shapes needed by Dear ImGui.
//  - Mouse cursor shapes for software cursor rendering (unless setting 'Flags |= ImFontAtlasFlags_NoMouseCursors' in the font atlas).
// It is the user-code responsibility to setup/build the atlas, then upload the pixel data into a texture accessible by your graphics api.
//  - Optionally, call any of the AddFont*** functions. If you don't call any, the default font embedded in the code will be loaded for you.
//  - Call GetTexDataAsAlpha8() or GetTexDataAsRGBA32() to build and retrieve pixels data.
//  - Upload the pixels data into a texture within your graphics system (see imgui_impl_xxxx.cpp examples)
//  - Call SetTexID(my_tex_id); and pass the pointer/identifier to your texture in a format natural to your graphics API.
//    This value will be passed back to you during rendering to identify the texture. Read FAQ entry about ImTextureID for more details.
// Common pitfalls:
// - If you pass a 'glyph_ranges' array to AddFont*** functions, you need to make sure that your array persist up until the
//   atlas is build (when calling GetTexData*** or Build()). We only copy the pointer, not the data.
// - Important: By default, AddFontFromMemoryTTF() takes ownership of the data. Even though we are not writing to it, we will free the pointer on destruction.
//   You can set font_cfg->FontDataOwnedByAtlas=false to keep ownership of your data and it won't be freed,
// - Even though many functions are suffixed with "TTF", OTF data is supported just as well.
// - This is an old API and it is currently awkward for those and various other reasons! We will address them in the future!
ImFontAtlas :: struct
{
    ImFontAtlas();
    ~ImFontAtlas();
    ImFont*           AddFont(const ImFontConfig* font_cfg);
    ImFont*           AddFontDefault(const ImFontConfig* font_cfg = nil);
    ImFont*           AddFontFromFileTTF(const u8* filename, f32 size_pixels, const ImFontConfig* font_cfg = nil, const ImWchar* glyph_ranges = nil);
    ImFont*           AddFontFromMemoryTTF(rawptr font_data, i32 font_data_size, f32 size_pixels, const ImFontConfig* font_cfg = nil, const ImWchar* glyph_ranges = nil); // Note: Transfer ownership of 'ttf_data' to ImFontAtlas! Will be deleted after destruction of the atlas. Set font_cfg->FontDataOwnedByAtlas=false to keep ownership of your data and it won't be freed.
    ImFont*           AddFontFromMemoryCompressedTTF(const rawptr compressed_font_data, i32 compressed_font_data_size, f32 size_pixels, const ImFontConfig* font_cfg = nil, const ImWchar* glyph_ranges = nil); // 'compressed_font_data' still owned by caller. Compress with binary_to_compressed_c.cpp.
    ImFont*           AddFontFromMemoryCompressedBase85TTF(const u8* compressed_font_data_base85, f32 size_pixels, const ImFontConfig* font_cfg = nil, const ImWchar* glyph_ranges = nil);              // 'compressed_font_data_base85' still owned by caller. Compress with binary_to_compressed_c.cpp with -base85 parameter.
    void              ClearInputData();           // Clear input data (all ImFontConfig structures including sizes, TTF data, glyph ranges, etc.) = all the data used to build the texture and fonts.
    void              ClearTexData();             // Clear output texture data (CPU side). Saves RAM once the texture has been copied to graphics memory.
    void              ClearFonts();               // Clear output font data (glyphs storage, UV coordinates).
    void              Clear();                    // Clear all input and output.

    // Build atlas, retrieve pixel data.
    // User is in charge of copying the pixels into graphics memory (e.g. create a texture with your engine). Then store your texture handle with SetTexID().
    // The pitch is always = Width * BytesPerPixels (1 or 4)
    // Building in RGBA32 format is provided for convenience and compatibility, but note that unless you manually manipulate or copy color data into
    // the texture (e.g. when using the AddCustomRect*** api), then the RGB pixels emitted will always be white (~75% of memory/bandwidth waste.
    bool              Build();                    // Build pixels data. This is called automatically for you by the GetTexData*** functions.
    void              GetTexDataAsAlpha8(u8** out_pixels, i32* out_width, i32* out_height, i32* out_bytes_per_pixel = nil);  // 1 byte per-pixel
    void              GetTexDataAsRGBA32(u8** out_pixels, i32* out_width, i32* out_height, i32* out_bytes_per_pixel = nil);  // 4 bytes-per-pixel
    bool                        IsBuilt() const             { return Fonts.Size > 0 && TexReady; } // Bit ambiguous: used to detect when user didn't build texture but effectively we should check TexID != 0 except that would be backend dependent...
    void                        SetTexID(ImTextureID id)    { TexID = id; }

    //-------------------------------------------
    // Glyph Ranges
    //-------------------------------------------

    // Helpers to retrieve list of common Unicode ranges (2 value per range, values are inclusive, zero-terminated list)
    // NB: Make sure that your string are UTF-8 and NOT in your local code page.
    // Read https://github.com/ocornut/imgui/blob/master/docs/FONTS.md/#about-utf-8-encoding for details.
    // NB: Consider using ImFontGlyphRangesBuilder to build glyph ranges from textual data.
    const ImWchar*    GetGlyphRangesDefault();                // Basic Latin, Extended Latin
    const ImWchar*    GetGlyphRangesGreek();                  // Default + Greek and Coptic
    const ImWchar*    GetGlyphRangesKorean();                 // Default + Korean characters
    const ImWchar*    GetGlyphRangesJapanese();               // Default + Hiragana, Katakana, Half-Width, Selection of 2999 Ideographs
    const ImWchar*    GetGlyphRangesChineseFull();            // Default + Half-Width + Japanese Hiragana/Katakana + full set of about 21000 CJK Unified Ideographs
    const ImWchar*    GetGlyphRangesChineseSimplifiedCommon();// Default + Half-Width + Japanese Hiragana/Katakana + set of 2500 CJK Unified Ideographs for common simplified Chinese
    const ImWchar*    GetGlyphRangesCyrillic();               // Default + about 400 Cyrillic characters
    const ImWchar*    GetGlyphRangesThai();                   // Default + Thai characters
    const ImWchar*    GetGlyphRangesVietnamese();             // Default + Vietnamese characters

    //-------------------------------------------
    // [BETA] Custom Rectangles/Glyphs API
    //-------------------------------------------

    // You can request arbitrary rectangles to be packed into the atlas, for your own purposes.
    // - After calling Build(), you can query the rectangle position and render your pixels.
    // - If you render colored output, set 'atlas->TexPixelsUseColors = true' as this may help some backends decide of preferred texture format.
    // - You can also request your rectangles to be mapped as font glyph (given a font + Unicode point),
    //   so you can render e.g. custom colorful icons and use them as regular glyphs.
    // - Read docs/FONTS.md for more details about using colorful icons.
    // - Note: this API may be redesigned later in order to support multi-monitor varying DPI settings.
    i32               AddCustomRectRegular(i32 width, i32 height);
    i32               AddCustomRectFontGlyph(ImFont* font, ImWchar id, i32 width, i32 height, f32 advance_x, const ImVec2& offset = ImVec2{0, 0});
    ImFontAtlasCustomRect*      GetCustomRectByIndex(i32 index) { assert(index >= 0); return &CustomRects[index]; }

    // [Internal]
    void              CalcCustomRectUV(const ImFontAtlasCustomRect* rect, ImVec2* out_uv_min, ImVec2* out_uv_max) const;
    bool              GetMouseCursorTexData(ImGuiMouseCursor cursor, ImVec2* out_offset, ImVec2* out_size, ImVec2 out_uv_border[2], ImVec2 out_uv_fill[2]);

    //-------------------------------------------
    // Members
    //-------------------------------------------

    Flags : ImFontAtlasFlags,              // Build flags (see ImFontAtlasFlags_)
    TexID : ImTextureID,              // User data to refer to the texture once it has been uploaded to user's graphic systems. It is passed back to you during rendering via the ImDrawCmd structure.
    TexDesiredWidth : i32,    // Texture width desired by user before Build(). Must be a power-of-two. If have many glyphs your graphics API have texture size restrictions you may want to increase texture width to decrease height.
    TexGlyphPadding : i32,    // FIXME: Should be called "TexPackPadding". Padding between glyphs within texture in pixels. Defaults to 1. If your rendering method doesn't rely on bilinear filtering you may set this to 0 (will also need to set AntiAliasedLinesUseTex = false).
    Locked : bool,             // Marked as Locked by ImGui::NewFrame() so attempt to modify the atlas will assert.
    UserData : rawptr,           // Store your own atlas related user-data (if e.g. you have multiple font atlas).

    // [Internal]
    // NB: Access texture data via GetTexData*() calls! Which will setup a default font for you.
    TexReady : bool,           // Set when texture was built matching current font input
    TexPixelsUseColors : bool, // Tell whether our texture data is known to use colors (rather than just alpha channel), in order to help backend select a format.
    TexPixelsAlpha8 : ^u8,    // 1 component per pixel, each component is unsigned 8-bit. Total size = TexWidth * TexHeight
    TexPixelsRGBA32 : ^u32,    // 4 component per pixel, each component is unsigned 8-bit. Total size = TexWidth * TexHeight * 4
    TexWidth : i32,           // Texture width calculated during Build().
    TexHeight : i32,          // Texture height calculated during Build().
    TexUvScale : ImVec2,         // = (1.0f/TexWidth, 1.0f/TexHeight)
    TexUvWhitePixel : ImVec2,    // Texture coordinates to a white pixel
    Fonts : [dynamic]^ImFont,              // Hold all the fonts returned by AddFont*. Fonts[0] is the default font upon calling ImGui::NewFrame(), use ImGui::PushFont()/PopFont() to change the current font.
    CustomRects : [dynamic]ImFontAtlasCustomRect,    // Rectangles for packing custom texture data into the atlas.
    ConfigData : [dynamic]ImFontConfig,         // Configuration data
    TexUvLines : [IM_DRAWLIST_TEX_LINES_WIDTH_MAX + 1]ImVec4,  // UVs for baked anti-aliased lines

    // [Internal] Font builder
    FontBuilderIO : ^ImFontBuilderIO,      // Opaque interface to a font builder (default to stb_truetype, can be changed to use FreeType by defining IMGUI_ENABLE_FREETYPE).
    FontBuilderFlags : u32,   // Shared flags (for all fonts) for custom font builder. THIS IS BUILD IMPLEMENTATION DEPENDENT. Per-font override is also available in ImFontConfig.

    // [Internal] Packing data
    PackIdMouseCursors : i32, // Custom texture rectangle ID for white pixel and mouse cursors
    PackIdLines : i32,        // Custom texture rectangle ID for baked anti-aliased lines

    // [Obsolete]
    //typedef ImFontAtlasCustomRect    CustomRect;         // OBSOLETED in 1.72+
    //typedef ImFontGlyphRangesBuilder GlyphRangesBuilder; // OBSOLETED in 1.67+
};

// Font runtime data and rendering
// ImFontAtlas automatically loads a default embedded font for you when you call GetTexDataAsAlpha8() or GetTexDataAsRGBA32().
ImFont :: struct
{
    // [Internal] Members: Hot ~20/24 bytes (for CalcTextSize)
    IndexAdvanceX : [dynamic]f32,      // 12-16 // out //            // Sparse. Glyphs->AdvanceX in a directly indexable way (cache-friendly for CalcTextSize functions which only this info, and are often bottleneck in large UI).
    FallbackAdvanceX : f32,   // 4     // out // = FallbackGlyph->AdvanceX
    FontSize : f32,           // 4     // in  //            // Height of characters/line, set during loading (don't change after loading)

    // [Internal] Members: Hot ~28/40 bytes (for RenderText loop)
    IndexLookup : [dynamic]ImWchar,        // 12-16 // out //            // Sparse. Index glyphs by Unicode code-point.
    Glyphs : [dynamic]ImFontGlyph,             // 12-16 // out //            // All glyphs.
    FallbackGlyph : ^ImFontGlyph,      // 4-8   // out // = FindGlyph(FontFallbackChar)

    // [Internal] Members: Cold ~32/40 bytes
    // Conceptually ConfigData[] is the list of font sources merged to create this font.
    ContainerAtlas : ^ImFontAtlas,     // 4-8   // out //            // What we has been loaded into
    ConfigData : ^ImFontConfig,         // 4-8   // in  //            // Pointer within ContainerAtlas->ConfigData to ConfigDataCount instances
    ConfigDataCount : i16,    // 2     // in  // ~ 1        // Number of ImFontConfig involved in creating this font. Bigger than 1 when merging multiple font sources into one ImFont.
    EllipsisCharCount : i16,  // 1     // out // 1 or 3
    EllipsisChar : ImWchar,       // 2-4   // out // = '...'/'.'// Character used for ellipsis rendering.
    FallbackChar : ImWchar,       // 2-4   // out // = FFFD/'?' // Character used if a glyph isn't found.
    EllipsisWidth : f32,      // 4     // out               // Width
    EllipsisCharStep : f32,   // 4     // out               // Step between characters when EllipsisCount > 0
    DirtyLookupTables : bool,  // 1     // out //
    Scale : f32,              // 4     // in  // = 1.f      // Base font scale, multiplied by the per-window font scale which you can adjust with SetWindowFontScale()
    Ascent, Descent : f32,    // 4+4   // out //            // Ascent: distance from top to bottom of e.g. 'A' [0..FontSize] (unscaled)
    MetricsTotalSurface : i32,// 4     // out //            // Total surface in pixels to get an idea of the font rasterization/texture cost (not exact, we approximate the cost of padding between glyphs)
    Used4kPagesMap : [(IM_UNICODE_CODEPOINT_MAX+1)/4096/8]u8, // 2 bytes if ImWchar=ImWchar16, 34 bytes if ImWchar==ImWchar32. Store 1-bit for each block of 4K codepoints that has one active glyph. This is mainly used to facilitate iterations across all used codepoints.

    // Methods
    ImFont();
    ~ImFont();
    const ImFontGlyph*FindGlyph(ImWchar c);
    const ImFontGlyph*FindGlyphNoFallback(ImWchar c);
    f32                       GetCharAdvance(ImWchar c)           { return (cast(ast) ast) adexAdvanceX.Size) ? IndexAdvanceX[cast(ceX) cast(ceX) cckAdvanceX; }
    bool                        IsLoaded() const                    { return ContainerAtlas != nil; }
    const u8*                 GetDebugName() const                { return ConfigData ? ConfigData.Name : "<unknown>"; }

    // 'max_width' stops rendering after a certain width (could be turned into a 2d size). FLT_MAX to disable.
    // 'wrap_width' enable automatic word-wrapping across multiple lines to fit into given width. 0.0f to disable.
    ImVec2            CalcTextSizeA(f32 size, f32 max_width, f32 wrap_width, const u8* text_begin, const u8* text_end = nil, const u8** remaining = nil); // utf8
    const u8*       CalcWordWrapPositionA(f32 scale, const u8* text, const u8* text_end, f32 wrap_width);
    void              RenderChar(ImDrawList* draw_list, f32 size, const ImVec2& pos, u32 col, ImWchar c);
    void              RenderText(ImDrawList* draw_list, f32 size, const ImVec2& pos, u32 col, const ImVec4& clip_rect, const u8* text_begin, const u8* text_end, f32 wrap_width = 0.0, bool cpu_fine_clip = false);

    // [Internal] Don't use!
    void              BuildLookupTable();
    void              ClearOutputData();
    void              GrowIndex(i32 new_size);
    void              AddGlyph(const ImFontConfig* src_cfg, ImWchar c, f32 x0, f32 y0, f32 x1, f32 y1, f32 u0, f32 v0, f32 u1, f32 v1, f32 advance_x);
    void              AddRemapChar(ImWchar dst, ImWchar src, bool overwrite_dst = true); // Makes 'dst' character/glyph points to 'src' character/glyph. Currently needs to be called AFTER fonts have been built.
    void              SetGlyphVisible(ImWchar c, bool visible);
    bool              IsGlyphRangeUnused(u32 c_begin, u32 c_last);
};

//-----------------------------------------------------------------------------
// [SECTION] Viewports
//-----------------------------------------------------------------------------

// Flags stored in ImGuiViewport::Flags, giving indications to the platform backends.
ImGuiViewportFlags :: bit_set[ImGuiViewportFlag; i32]
ImGuiViewportFlag :: enum
{
    // [removed] -> nil: None                     = 0,
    IsPlatformWindow         = 0,   // Represent a Platform Window
    IsPlatformMonitor        = 1,   // Represent a Platform Monitor (unused yet)
    OwnedByApp               = 2,   // Platform Window: Is created/managed by the user application? (rather than our backend)
    NoDecoration             = 3,   // Platform Window: Disable platform decorations: title bar, borders, etc. (generally set all windows, but if ImGuiConfigFlags_ViewportsDecoration is set we only set this on popups/tooltips)
    NoTaskBarIcon            = 4,   // Platform Window: Disable platform task bar icon (generally set on popups/tooltips, or all windows if ImGuiConfigFlags_ViewportsNoTaskBarIcon is set)
    NoFocusOnAppearing       = 5,   // Platform Window: Don't take focus when created.
    NoFocusOnClick           = 6,   // Platform Window: Don't take focus when clicked on.
    NoInputs                 = 7,   // Platform Window: Make mouse pass through so we can drag this window while peaking behind it.
    NoRendererClear          = 8,   // Platform Window: Renderer doesn't need to clear the framebuffer ahead (because we will fill it entirely).
    NoAutoMerge              = 9,   // Platform Window: Avoid merging this window into another host window. This can only be set via ImGuiWindowClass viewport flags override (because we need to now ahead if we are going to create a viewport in the first place!).
    TopMost                  = 10,  // Platform Window: Display on top (for tooltips only).
    CanHostOtherWindows      = 11,  // Viewport can host multiple imgui windows (secondary viewports are associated to a single window). // FIXME: In practice there's still probably code making the assumption that this is always and only on the MainViewport. Will fix once we add support for "no main viewport".

    // Output status flags (from Platform)
    IsMinimized              = 12,  // Platform Window: Window is minimized, can skip render. When minimized we tend to avoid using the viewport pos/size for clipping window or testing if they are contained in the viewport.
    IsFocused                = 13,  // Platform Window: Window is focused (last call to Platform_GetWindowFocus() returned true)
};

// - Currently represents the Platform Window created by the application which is hosting our Dear ImGui windows.
// - With multi-viewport enabled, we extend this concept to have multiple active viewports.
// - In the future we will extend this concept further to also represent Platform Monitor and support a "no main platform window" operation mode.
// - About Main Area vs Work Area:
//   - Main Area = entire viewport.
//   - Work Area = entire viewport minus sections used by main menu bars (for platform windows), or by task bar (for platform monitor).
//   - Windows are generally trying to stay within the Work Area of their host viewport.
ImGuiViewport :: struct
{
    ID : ImGuiID,                     // Unique identifier for the viewport
    Flags : ImGuiViewportFlags,                  // See ImGuiViewportFlags_
    Pos : ImVec2,                    // Main Area: Position of the viewport (Dear ImGui coordinates are the same as OS desktop/native coordinates)
    Size : ImVec2,                   // Main Area: Size of the viewport.
    WorkPos : ImVec2,                // Work Area: Position of the viewport minus task bars, menus bars, status bars (>= Pos)
    WorkSize : ImVec2,               // Work Area: Size of the viewport minus task bars, menu bars, status bars (<= Size)
    DpiScale : f32,               // 1.0f = 96 DPI = No extra scale.
    ParentViewportId : ImGuiID,       // (Advanced) 0: no parent. Instruct the platform backend to setup a parent/child relationship between platform windows.
    DrawData : ^ImDrawData,               // The ImDrawData corresponding to this viewport. Valid after Render() and until the next call to NewFrame().

    // Platform/Backend Dependent Data
    // Our design separate the Renderer and Platform backends to facilitate combining default backends with each others.
    // When our create your own backend for a custom engine, it is possible that both Renderer and Platform will be handled
    // by the same system and you may not need to use all the UserData/Handle fields.
    // The library never uses those fields, they are merely storage to facilitate backend implementation.
    RendererUserData : rawptr,       // void* to hold custom data structure for the renderer (e.g. swap chain, framebuffers etc.). generally set by your Renderer_CreateWindow function.
    PlatformUserData : rawptr,       // void* to hold custom data structure for the OS / platform (e.g. windowing info, render context). generally set by your Platform_CreateWindow function.
    PlatformHandle : rawptr,         // void* to hold higher-level, platform window handle (e.g. HWND, GLFWWindow*, SDL_Window*), for FindViewportByPlatformHandle().
    PlatformHandleRaw : rawptr,      // void* to hold lower-level, platform-native window handle (under Win32 this is expected to be a HWND, unused for other platforms), when using an abstraction layer like GLFW or SDL (where PlatformHandle would be a SDL_Window*)
    PlatformWindowCreated : bool,  // Platform window has been created (Platform_CreateWindow() has been called). This is false during the first frame where a viewport is being created.
    PlatformRequestMove : bool,    // Platform window requested move (e.g. window was moved by the OS / host window manager, authoritative position will be OS window position)
    PlatformRequestResize : bool,  // Platform window requested resize (e.g. window was resized by the OS / host window manager, authoritative size will be OS window size)
    PlatformRequestClose : bool,   // Platform window requested closure (e.g. window was moved by the OS / host window manager, e.g. pressing ALT-F4)

    ImGuiViewport()     { memset(this, 0, size_of(*this)); }
    ~ImGuiViewport()    { assert(PlatformUserData == nil && RendererUserData == nil); }

    // Helpers
    ImVec2              GetCenter() const       { return ImVec2{Pos.x + Size.x * 0.5, Pos.y + Size.y * 0.5}; }
    ImVec2              GetWorkCenter() const   { return ImVec2{WorkPos.x + WorkSize.x * 0.5, WorkPos.y + WorkSize.y * 0.5}; }
};

//-----------------------------------------------------------------------------
// [SECTION] ImGuiPlatformIO + other Platform Dependent Interfaces (ImGuiPlatformMonitor, ImGuiPlatformImeData)
//-----------------------------------------------------------------------------

// [BETA] (Optional) Multi-Viewport Support!
// If you are new to Dear ImGui and trying to integrate it into your engine, you can probably ignore this for now.
//
// This feature allows you to seamlessly drag Dear ImGui windows outside of your application viewport.
// This is achieved by creating new Platform/OS windows on the fly, and rendering into them.
// Dear ImGui manages the viewport structures, and the backend create and maintain one Platform/OS window for each of those viewports.
//
// See Recap:   https://github.com/ocornut/imgui/wiki/Multi-Viewports
// See Glossary https://github.com/ocornut/imgui/wiki/Glossary for details about some of the terminology.
//
// About the coordinates system:
// - When multi-viewports are enabled, all Dear ImGui coordinates become absolute coordinates (same as OS coordinates!)
// - So e.g. ImGui::SetNextWindowPos(ImVec2(0,0)) will position a window relative to your primary monitor!
// - If you want to position windows relative to your main application viewport, use ImGui::GetMainViewport()->Pos as a base position.
//
// Steps to use multi-viewports in your application, when using a default backend from the examples/ folder:
// - Application:  Enable feature with 'io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable'.
// - Backend:      The backend initialization will setup all necessary ImGuiPlatformIO's functions and update monitors info every frame.
// - Application:  In your main loop, call ImGui::UpdatePlatformWindows(), ImGui::RenderPlatformWindowsDefault() after EndFrame() or Render().
// - Application:  Fix absolute coordinates used in ImGui::SetWindowPos() or ImGui::SetNextWindowPos() calls.
//
// Steps to use multi-viewports in your application, when using a custom backend:
// - Important:    THIS IS NOT EASY TO DO and comes with many subtleties not described here!
//                 It's also an experimental feature, so some of the requirements may evolve.
//                 Consider using default backends if you can. Either way, carefully follow and refer to examples/ backends for details.
// - Application:  Enable feature with 'io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable'.
// - Backend:      Hook ImGuiPlatformIO's Platform_* and Renderer_* callbacks (see below).
//                 Set 'io.BackendFlags |= ImGuiBackendFlags_PlatformHasViewports' and 'io.BackendFlags |= ImGuiBackendFlags_PlatformHasViewports'.
//                 Update ImGuiPlatformIO's Monitors list every frame.
//                 Update MousePos every frame, in absolute coordinates.
// - Application:  In your main loop, call ImGui::UpdatePlatformWindows(), ImGui::RenderPlatformWindowsDefault() after EndFrame() or Render().
//                 You may skip calling RenderPlatformWindowsDefault() if its API is not convenient for your needs. Read comments below.
// - Application:  Fix absolute coordinates used in ImGui::SetWindowPos() or ImGui::SetNextWindowPos() calls.
//
// About ImGui::RenderPlatformWindowsDefault():
// - This function is a mostly a _helper_ for the common-most cases, and to facilitate using default backends.
// - You can check its simple source code to understand what it does.
//   It basically iterates secondary viewports and call 4 functions that are setup in ImGuiPlatformIO, if available:
//     Platform_RenderWindow(), Renderer_RenderWindow(), Platform_SwapBuffers(), Renderer_SwapBuffers()
//   Those functions pointers exists only for the benefit of RenderPlatformWindowsDefault().
// - If you have very specific rendering needs (e.g. flipping multiple swap-chain simultaneously, unusual sync/threading issues, etc.),
//   you may be tempted to ignore RenderPlatformWindowsDefault() and write customized code to perform your renderingg.
//   You may decide to setup the platform_io's *RenderWindow and *SwapBuffers pointers and call your functions through those pointers,
//   or you may decide to never setup those pointers and call your code directly. They are a convenience, not an obligatory interface.
//-----------------------------------------------------------------------------

// Access via ImGui::GetPlatformIO()
ImGuiPlatformIO :: struct
{
    ImGuiPlatformIO();

    //------------------------------------------------------------------
    // Interface with OS and Platform backend (basic)
    //------------------------------------------------------------------

    // Optional: Access OS clipboard
    // (default to use native Win32 clipboard on Windows, otherwise uses a private clipboard. Override to access OS clipboard on other architectures)
    const u8* (*Platform_GetClipboardTextFn)(ImGuiContext* ctx);
    void        (*Platform_SetClipboardTextFn)(ImGuiContext* ctx, const u8* text);
    Platform_ClipboardUserData : rawptr,

    // Optional: Open link/folder/file in OS Shell
    // (default to use ShellExecuteA() on Windows, system() on Linux/Mac)
    bool        (*Platform_OpenInShellFn)(ImGuiContext* ctx, const u8* path);
    Platform_OpenInShellUserData : rawptr,

    // Optional: Notify OS Input Method Editor of the screen position of your cursor for text input position (e.g. when using Japanese/Chinese IME on Windows)
    // (default to use native imm32 api on Windows)
    void        (*Platform_SetImeDataFn)(ImGuiContext* ctx, ImGuiViewport* viewport, ImGuiPlatformImeData* data);
    Platform_ImeUserData : rawptr,
    //void      (*SetPlatformImeDataFn)(ImGuiViewport* viewport, ImGuiPlatformImeData* data); // [Renamed to platform_io.PlatformSetImeDataFn in 1.91.1]

    // Optional: Platform locale
    // [Experimental] Configure decimal point e.g. '.' or ',' useful for some languages (e.g. German), generally pulled from *localeconv()->decimal_point
    Platform_LocaleDecimalPoint : ImWchar,     // '.'

    //------------------------------------------------------------------
    // Interface with Renderer Backend
    //------------------------------------------------------------------

    // Written by some backends during ImGui_ImplXXXX_RenderDrawData() call to point backend_specific ImGui_ImplXXXX_RenderState* structure.
    Renderer_RenderState : rawptr,

    //------------------------------------------------------------------
    // Input - Interface with OS/backends (Multi-Viewport support!)
    //------------------------------------------------------------------

    // For reference, the second column shows which function are generally calling the Platform Functions:
    //   N = ImGui::NewFrame()                        ~ beginning of the dear imgui frame: read info from platform/OS windows (latest size/position)
    //   F = ImGui::Begin(), ImGui::EndFrame()        ~ during the dear imgui frame
    //   U = ImGui::UpdatePlatformWindows()           ~ after the dear imgui frame: create and update all platform/OS windows
    //   R = ImGui::RenderPlatformWindowsDefault()    ~ render
    //   D = ImGui::DestroyPlatformWindows()          ~ shutdown
    // The general idea is that NewFrame() we will read the current Platform/OS state, and UpdatePlatformWindows() will write to it.

    // The handlers are designed so we can mix and match two imgui_impl_xxxx files, one Platform backend and one Renderer backend.
    // Custom engine backends will often provide both Platform and Renderer interfaces together and so may not need to use all functions.
    // Platform functions are typically called _before_ their Renderer counterpart, apart from Destroy which are called the other way.

    // Platform Backend functions (e.g. Win32, GLFW, SDL) ------------------- Called by -----
    void    (*Platform_CreateWindow)(ImGuiViewport* vp);                    // . . U . .  // Create a new platform window for the given viewport
    void    (*Platform_DestroyWindow)(ImGuiViewport* vp);                   // N . U . D  //
    void    (*Platform_ShowWindow)(ImGuiViewport* vp);                      // . . U . .  // Newly created windows are initially hidden so SetWindowPos/Size/Title can be called on them before showing the window
    void    (*Platform_SetWindowPos)(ImGuiViewport* vp, ImVec2 pos);        // . . U . .  // Set platform window position (given the upper-left corner of client area)
    ImVec2  (*Platform_GetWindowPos)(ImGuiViewport* vp);                    // N . . . .  //
    void    (*Platform_SetWindowSize)(ImGuiViewport* vp, ImVec2 size);      // . . U . .  // Set platform window client area size (ignoring OS decorations such as OS title bar etc.)
    ImVec2  (*Platform_GetWindowSize)(ImGuiViewport* vp);                   // N . . . .  // Get platform window client area size
    void    (*Platform_SetWindowFocus)(ImGuiViewport* vp);                  // N . . . .  // Move window to front and set input focus
    bool    (*Platform_GetWindowFocus)(ImGuiViewport* vp);                  // . . U . .  //
    bool    (*Platform_GetWindowMinimized)(ImGuiViewport* vp);              // N . . . .  // Get platform window minimized state. When minimized, we generally won't attempt to get/set size and contents will be culled more easily
    void    (*Platform_SetWindowTitle)(ImGuiViewport* vp, const u8* str); // . . U . .  // Set platform window title (given an UTF-8 string)
    void    (*Platform_SetWindowAlpha)(ImGuiViewport* vp, f32 alpha);     // . . U . .  // (Optional) Setup global transparency (not per-pixel transparency)
    void    (*Platform_UpdateWindow)(ImGuiViewport* vp);                    // . . U . .  // (Optional) Called by UpdatePlatformWindows(). Optional hook to allow the platform backend from doing general book-keeping every frame.
    void    (*Platform_RenderWindow)(ImGuiViewport* vp, rawptr render_arg);  // . . . R .  // (Optional) Main rendering (platform side! This is often unused, or just setting a "current" context for OpenGL bindings). 'render_arg' is the value passed to RenderPlatformWindowsDefault().
    void    (*Platform_SwapBuffers)(ImGuiViewport* vp, rawptr render_arg);   // . . . R .  // (Optional) Call Present/SwapBuffers (platform side! This is often unused!). 'render_arg' is the value passed to RenderPlatformWindowsDefault().
    f32   (*Platform_GetWindowDpiScale)(ImGuiViewport* vp);               // N . . . .  // (Optional) [BETA] FIXME-DPI: DPI handling: Return DPI scale for this viewport. 1.0f = 96 DPI.
    void    (*Platform_OnChangedViewport)(ImGuiViewport* vp);               // . F . . .  // (Optional) [BETA] FIXME-DPI: DPI handling: Called during Begin() every time the viewport we are outputting into changes, so backend has a chance to swap fonts to adjust style.
    ImVec4  (*Platform_GetWindowWorkAreaInsets)(ImGuiViewport* vp);         // N . . . .  // (Optional) [BETA] Get initial work area inset for the viewport (won't be covered by main menu bar, dockspace over viewport etc.). Default to (0,0),(0,0). 'safeAreaInsets' in iOS land, 'DisplayCutout' in Android land.
    i32     (*Platform_CreateVkSurface)(ImGuiViewport* vp, u64 vk_inst, const rawptr vk_allocators, u64* out_vk_surface); // (Optional) For a Vulkan Renderer to call into Platform code (since the surface creation needs to tie them both).

    // Renderer Backend functions (e.g. DirectX, OpenGL, Vulkan) ------------ Called by -----
    void    (*Renderer_CreateWindow)(ImGuiViewport* vp);                    // . . U . .  // Create swap chain, frame buffers etc. (called after Platform_CreateWindow)
    void    (*Renderer_DestroyWindow)(ImGuiViewport* vp);                   // N . U . D  // Destroy swap chain, frame buffers etc. (called before Platform_DestroyWindow)
    void    (*Renderer_SetWindowSize)(ImGuiViewport* vp, ImVec2 size);      // . . U . .  // Resize swap chain, frame buffers etc. (called after Platform_SetWindowSize)
    void    (*Renderer_RenderWindow)(ImGuiViewport* vp, rawptr render_arg);  // . . . R .  // (Optional) Clear framebuffer, setup render target, then render the viewport->DrawData. 'render_arg' is the value passed to RenderPlatformWindowsDefault().
    void    (*Renderer_SwapBuffers)(ImGuiViewport* vp, rawptr render_arg);   // . . . R .  // (Optional) Call Present/SwapBuffers. 'render_arg' is the value passed to RenderPlatformWindowsDefault().

    // (Optional) Monitor list
    // - Updated by: app/backend. Update every frame to dynamically support changing monitor or DPI configuration.
    // - Used by: dear imgui to query DPI info, clamp popups/tooltips within same monitor and not have them straddle monitors.
    Monitors : [dynamic]ImGuiPlatformMonitor,

    //------------------------------------------------------------------
    // Output - List of viewports to render into platform windows
    //------------------------------------------------------------------

    // Viewports list (the list is updated by calling ImGui::EndFrame or ImGui::Render)
    // (in the future we will attempt to organize this feature to remove the need for a "main viewport")
    Viewports : [dynamic]^ImGuiViewport,                              // Main viewports, followed by all secondary viewports.
};

// (Optional) This is required when enabling multi-viewport. Represent the bounds of each connected monitor/display and their DPI.
// We use this information for multiple DPI support + clamping the position of popups and tooltips so they don't straddle multiple monitors.
ImGuiPlatformMonitor :: struct
{
    MainPos, MainSize : ImVec2,      // Coordinates of the area displayed on this monitor (Min = upper left, Max = bottom right)
    WorkPos, WorkSize : ImVec2,      // Coordinates without task bars / side bars / menu bars. Used to avoid positioning popups/tooltips inside this region. If you don't have this info, please copy the value for MainPos/MainSize.
    DpiScale : f32,               // 1.0f = 96 DPI
    PlatformHandle : rawptr,         // Backend dependant data (e.g. HMONITOR, GLFWmonitor*, SDL Display Index, NSScreen*)
    ImGuiPlatformMonitor()          { MainPos = MainSize = WorkPos = WorkSize = ImVec2{0, 0}; DpiScale = 1.0; PlatformHandle = nil; }
};

// (Optional) Support for IME (Input Method Editor) via the platform_io.Platform_SetImeDataFn() function.
ImGuiPlatformImeData :: struct
{
    WantVisible : bool,        // A widget wants the IME to be visible
    InputPos : ImVec2,           // Position of the input cursor
    InputLineHeight : f32,    // Line height

    ImGuiPlatformImeData() { memset(this, 0, size_of(*this)); }
};

//-----------------------------------------------------------------------------
// [SECTION] Obsolete functions and types
// (Will be removed! Read 'API BREAKING CHANGES' section in imgui.cpp for details)
// Please keep your copy of dear imgui up to date! Occasionally set '#define IMGUI_DISABLE_OBSOLETE_FUNCTIONS' in imconfig.h to stay ahead.
//-----------------------------------------------------------------------------


// RENAMED IMGUI_DISABLE_METRICS_WINDOW > IMGUI_DISABLE_DEBUG_TOOLS in 1.88 (from June 2022)

//-----------------------------------------------------------------------------


when _MSC_VER {
}

// Include imgui_user.h at the end of imgui.h
// May be convenient for some users to only explicitly include vanilla imgui.h and have extra stuff included.

} // #ifndef IMGUI_DISABLE
