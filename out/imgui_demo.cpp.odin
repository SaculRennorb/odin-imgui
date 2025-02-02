package imgui

// dear imgui, v1.91.7 WIP
// (demo code)

// Help:
// - Read FAQ at http://dearimgui.com/faq
// - Call and read ImGui::ShowDemoWindow() in imgui_demo.cpp. All applications in examples/ are doing that.
// - Need help integrating Dear ImGui in your codebase?
//   - Read Getting Started https://github.com/ocornut/imgui/wiki/Getting-Started
//   - Read 'Programmer guide' in imgui.cpp for notes on how to setup Dear ImGui in your codebase.
// Read top of imgui.cpp and imgui.h for many details, documentation, comments, links.
// Get the latest version at https://github.com/ocornut/imgui

// How to easily locate code?
// - Use Tools->Item Picker to debug break in code by clicking any widgets: https://github.com/ocornut/imgui/wiki/Debug-Tools
// - Browse an online version the demo with code linked to hovered widgets: https://pthom.github.io/imgui_manual_online/manual/imgui_manual.html
// - Find a visible string and search for it in the code!

//---------------------------------------------------
// PLEASE DO NOT REMOVE THIS FILE FROM YOUR PROJECT!
//---------------------------------------------------
// Message to the person tempted to delete this file when integrating Dear ImGui into their codebase:
// Think again! It is the most useful reference code that you and other coders will want to refer to and call.
// Have the ImGui::ShowDemoWindow() function wired in an always-available debug menu of your game/app!
// Also include Metrics! ItemPicker! DebugLog! and other debug features.
// Removing this file from your project is hindering access to documentation for everyone in your team,
// likely leading you to poorer usage of the library.
// Everything in this file will be stripped out by the linker if you don't call ImGui::ShowDemoWindow().
// If you want to link core Dear ImGui in your shipped builds but want a thorough guarantee that the demo will not be
// linked, you can setup your imconfig.h with #define IMGUI_DISABLE_DEMO_WINDOWS and those functions will be empty.
// In another situation, whenever you have Dear ImGui available you probably want this to be available for reference.
// Thank you,
// -Your beloved friend, imgui_demo.cpp (which you won't delete)

//--------------------------------------------
// ABOUT THE MEANING OF THE 'static' KEYWORD:
//--------------------------------------------
// In this demo code, we frequently use 'static' variables inside functions.
// A static variable persists across calls. It is essentially a global variable but declared inside the scope of the function.
// Think of "static int n = 0;" as "global int n = 0;" !
// We do this IN THE DEMO because we want:
// - to gather code and data in the same place.
// - to make the demo source code faster to read, faster to change, smaller in size.
// - it is also a convenient way of storing simple UI related information as long as your function
//   doesn't need to be reentrant or used in multiple threads.
// This might be a pattern you will want to use in your code, but most of the data you would be working
// with in a complex codebase is likely going to be stored outside your functions.

//-----------------------------------------
// ABOUT THE CODING STYLE OF OUR DEMO CODE
//-----------------------------------------
// The Demo code in this file is designed to be easy to copy-and-paste into your application!
// Because of this:
// - We never omit the ImGui:: prefix when calling functions, even though most code here is in the same namespace.
// - We try to declare static variables in the local scope, as close as possible to the code using them.
// - We never use any of the helpers/facilities used internally by Dear ImGui, unless available in the public API.
// - We never use maths operators on ImVec2/ImVec4. For our other sources files we use them, and they are provided
//   by imgui.h using the IMGUI_DEFINE_MATH_OPERATORS define. For your own sources file they are optional
//   and require you either enable those, either provide your own via IM_VEC2_CLASS_EXTRA in imconfig.h.
//   Because we can't assume anything about your support of maths operators, we cannot use them in imgui_demo.cpp.

// Navigating this file:
// - In Visual Studio: CTRL+comma ("Edit.GoToAll") can follow symbols inside comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
// - In Visual Studio w/ Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols inside comments.
// - In VS Code, CLion, etc.: CTRL+click can follow symbols inside comments.
// - You can search/grep for all sections listed in the index to find the section.

/*

Index of this file:

// [SECTION] Forward Declarations
// [SECTION] Helpers
// [SECTION] Helpers: ExampleTreeNode, ExampleMemberInfo (for use by Property Editor & Multi-Select demos)
// [SECTION] Demo Window / ShowDemoWindow()
// [SECTION] ShowDemoWindowMenuBar()
// [SECTION] ShowDemoWindowWidgets()
// [SECTION] ShowDemoWindowMultiSelect()
// [SECTION] ShowDemoWindowLayout()
// [SECTION] ShowDemoWindowPopups()
// [SECTION] ShowDemoWindowTables()
// [SECTION] ShowDemoWindowInputs()
// [SECTION] About Window / ShowAboutWindow()
// [SECTION] Style Editor / ShowStyleEditor()
// [SECTION] User Guide / ShowUserGuide()
// [SECTION] Example App: Main Menu Bar / ShowExampleAppMainMenuBar()
// [SECTION] Example App: Debug Console / ShowExampleAppConsole()
// [SECTION] Example App: Debug Log / ShowExampleAppLog()
// [SECTION] Example App: Simple Layout / ShowExampleAppLayout()
// [SECTION] Example App: Property Editor / ShowExampleAppPropertyEditor()
// [SECTION] Example App: Long Text / ShowExampleAppLongText()
// [SECTION] Example App: Auto Resize / ShowExampleAppAutoResize()
// [SECTION] Example App: Constrained Resize / ShowExampleAppConstrainedResize()
// [SECTION] Example App: Simple overlay / ShowExampleAppSimpleOverlay()
// [SECTION] Example App: Fullscreen window / ShowExampleAppFullscreen()
// [SECTION] Example App: Manipulating window titles / ShowExampleAppWindowTitles()
// [SECTION] Example App: Custom Rendering using ImDrawList API / ShowExampleAppCustomRendering()
// [SECTION] Example App: Docking, DockSpace / ShowExampleAppDockSpace()
// [SECTION] Example App: Documents Handling / ShowExampleAppDocuments()
// [SECTION] Example App: Assets Browser / ShowExampleAppAssetsBrowser()

*/

when defined(_MSC_VER) && !defined(_CRT_SECURE_NO_WARNINGS) {
_CRT_SECURE_NO_WARNINGS :: true
}

when !(IMGUI_DISABLE) {

// System includes
when !defined(_MSC_VER) || _MSC_VER >= 1800 {
}
when __EMSCRIPTEN__ {
}

// Visual Studio warnings
when _MSC_VER {
}

// Clang/GCC warnings with -Weverything

// Play it nice with Windows users (Update: May 2018, Notepad now supports Unix-style carriage returns!)
when _WIN32 {
IM_NEWLINE :: "\r\n"
} else {
IM_NEWLINE :: "\n"
}

// Helpers
when defined(_MSC_VER) && !defined(snprintf) {
snprintf :: _snprintf
}
when defined(_MSC_VER) && !defined(vsnprintf) {
vsnprintf :: _vsnprintf
}

// Format specifiers for 64-bit values (hasn't been decently standardized before VS2013)
when !defined(PRId64) && defined(_MSC_VER) {
PRId64 :: "I64d"
PRIu64 :: "I64u"
} else when !defined(PRId64) {
PRId64 :: "lld"
PRIu64 :: "llu"
}

// Helpers macros
// We normally try to not use many helpers in imgui_demo.cpp in order to make code easier to copy and paste,
// but making an exception here as those are largely simplifying code...
// In other imgui sources we can use nicer internal functions from imgui_internal.h (ImMin/ImMax) but not in the demo.
#define IM_MIN(A, B)            (((A) < (B)) ? (A) : (B))
#define IM_MAX(A, B)            (((A) >= (B)) ? (A) : (B))
#define IM_CLAMP(V, MN, MX)     ((V) < (MN) ? (MN) : (V) > (MX) ? (MX) : (V))

// Enforce cdecl calling convention for functions called by the standard library,
// in case compilation settings changed the default to e.g. __vectorcall
when !(IMGUI_CDECL) {
when _MSC_VER {
} else {
}
}

//-----------------------------------------------------------------------------
// [SECTION] Forward Declarations
//-----------------------------------------------------------------------------

when !defined(IMGUI_DISABLE_DEMO_WINDOWS) {

// Forward Declarations
void ShowExampleAppMainMenuBar();
void ShowExampleAppAssetsBrowser(bool* p_open);
void ShowExampleAppConsole(bool* p_open);
void ShowExampleAppCustomRendering(bool* p_open);
void ShowExampleAppDockSpace(bool* p_open);
void ShowExampleAppDocuments(bool* p_open);
void ShowExampleAppLog(bool* p_open);
void ShowExampleAppLayout(bool* p_open);
void ShowExampleAppPropertyEditor(bool* p_open, ImGuiDemoWindowData* demo_data);
void ShowExampleAppSimpleOverlay(bool* p_open);
void ShowExampleAppAutoResize(bool* p_open);
void ShowExampleAppConstrainedResize(bool* p_open);
void ShowExampleAppFullscreen(bool* p_open);
void ShowExampleAppLongText(bool* p_open);
void ShowExampleAppWindowTitles(bool* p_open);
void ShowExampleMenuFile();

// We split the contents of the big ShowDemoWindow() function into smaller functions
// (because the link time of very large functions tends to grow non-linearly)
void ShowDemoWindowMenuBar(ImGuiDemoWindowData* demo_data);
void ShowDemoWindowWidgets(ImGuiDemoWindowData* demo_data);
void ShowDemoWindowMultiSelect(ImGuiDemoWindowData* demo_data);
void ShowDemoWindowLayout();
void ShowDemoWindowPopups();
void ShowDemoWindowTables();
void ShowDemoWindowColumns();
void ShowDemoWindowInputs();

//-----------------------------------------------------------------------------
// [SECTION] Helpers
//-----------------------------------------------------------------------------

// Helper to display a little (?) mark which shows a tooltip when hovered.
// In your own code you may want to display an actual icon if you are using a merged icon fonts (see docs/FONTS.md)
HelpMarker :: proc(desc : ^u8)
{
    TextDisabled("(?)");
    if (BeginItemTooltip())
    {
        PushTextWrapPos(GetFontSize() * 35.0);
        TextUnformatted(desc);
        PopTextWrapPos();
        EndTooltip();
    }
}

ShowDockingDisabledMessage :: proc()
{
    ImGuiIO& io = GetIO();
    Text("ERROR: Docking is not enabled! See Demo > Configuration.");
    Text("Set io.ConfigFlags |= ImGuiConfigFlags_DockingEnable in your code, or ");
    SameLine(0.0, 0.0);
    if (SmallButton("click here"))
        io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;
}

// Helper to wire demo markers located in code to an interactive browser
ImGuiDemoMarkerCallback :: #type proc(file : ^u8, line : i32, section : ^u8, user_data : rawptr)
extern ImGuiDemoMarkerCallback      GImGuiDemoMarkerCallback;
extern rawptr                        GImGuiDemoMarkerCallbackUserData;
GImGuiDemoMarkerCallback := nil;
GImGuiDemoMarkerCallbackUserData := nil;
#define IMGUI_DEMO_MARKER(section)  do { if (GImGuiDemoMarkerCallback != NULL) GImGuiDemoMarkerCallback(__FILE__, __LINE__, section, GImGuiDemoMarkerCallbackUserData); } while (0)

//-----------------------------------------------------------------------------
// [SECTION] Helpers: ExampleTreeNode, ExampleMemberInfo (for use by Property Editor etc.)
//-----------------------------------------------------------------------------

// Simple representation for a tree
// (this is designed to be simple to understand for our demos, not to be fancy or efficient etc.)
ExampleTreeNode :: struct
{
    // Tree structure
    u8                        Name[28] = "";
    UID := 0;
    Parent := nil;
    Childs : [dynamic]^ExampleTreeNode,
    IndexInParent := 0;  // Maintaining this allows us to implement linear traversal more easily

    // Leaf Data
    HasData := false;    // All leaves have data
    DataMyBool := true;
    DataMyInt := 128;
    DataMyVec2 := ImVec2{0.0, 3.141592};
};

// Simple representation of struct metadata/serialization data.
// (this is a minimal version of what a typical advanced application may provide)
ExampleMemberInfo :: struct
{
    Name : ^u8,       // Member name
    DataType : ImGuiDataType,   // Member type
    DataCount : i32,  // Member count (1 when scalar)
    Offset : i32,     // Offset inside parent structure
};

// Metadata description of ExampleTreeNode struct.
const ExampleMemberInfo ExampleTreeNodeMemberInfos[]
{
    { "MyName",     ImGuiDataType_String,  1, offsetof(ExampleTreeNode, Name) },
    { "MyBool",     ImGuiDataType_Bool,    1, offsetof(ExampleTreeNode, DataMyBool) },
    { "MyInt",      ImGuiDataType_S32,     1, offsetof(ExampleTreeNode, DataMyInt) },
    { "MyVec2",     ImGuiDataType_Float,   2, offsetof(ExampleTreeNode, DataMyVec2) },
};

ExampleTree_CreateNode :: proc(name : ^u8, uid : i32, parent : ^ExampleTreeNode) -> ^ExampleTreeNode
{
    node := IM_NEW(ExampleTreeNode);
    snprintf(node.Name, len(node.Name), "%s", name);
    node.UID = uid;
    node.Parent = parent;
    node.IndexInParent = parent ? cast(ast) ast) tst) tds.Size : 0;
    if (parent)
        parent.Childs.push_back(node);
    return node;
}

ExampleTree_DestroyNode :: proc(node : ^ExampleTreeNode)
{
    for ExampleTreeNode* child_node : node.Childs
        ExampleTree_DestroyNode(child_node);
    IM_DELETE(node);
}

// Create example tree data
// (this allocates _many_ more times than most other code in either Dear ImGui or others demo)
ExampleTree_CreateDemoTree :: proc() -> ^ExampleTreeNode
{
    static const u8* root_names[] = { "Apple", "Banana", "Cherry", "Kiwi", "Mango", "Orange", "Pear", "Pineapple", "Strawberry", "Watermelon" };
    NAME_MAX_LEN := size_of(ExampleTreeNode::Name);
    name_buf : [NAME_MAX_LEN]u8
    uid := 0;
    node_L0 := ExampleTree_CreateNode("<ROOT>", ++uid, nil);
    root_items_multiplier := 2;
    for i32 idx_L0 = 0; idx_L0 < len(root_names) * root_items_multiplier; idx_L0++
    {
        snprintf(name_buf, len(name_buf), "%s %d", root_names[idx_L0 / root_items_multiplier], idx_L0 % root_items_multiplier);
        node_L1 := ExampleTree_CreateNode(name_buf, ++uid, node_L0);
        number_of_childs := cast(ast) ast) nst) n_L1.Name);
        for i32 idx_L1 = 0; idx_L1 < number_of_childs; idx_L1++
        {
            snprintf(name_buf, len(name_buf), "Child %d", idx_L1);
            node_L2 := ExampleTree_CreateNode(name_buf, ++uid, node_L1);
            node_L2.HasData = true;
            if (idx_L1 == 0)
            {
                snprintf(name_buf, len(name_buf), "Sub-child %d", 0);
                node_L3 := ExampleTree_CreateNode(name_buf, ++uid, node_L2);
                node_L3.HasData = true;
            }
        }
    }
    return node_L0;
}

//-----------------------------------------------------------------------------
// [SECTION] Demo Window / ShowDemoWindow()
//-----------------------------------------------------------------------------

// Data to be shared across different functions of the demo.
ImGuiDemoWindowData :: struct
{
    // Examples Apps (accessible from the "Examples" menu)
    ShowMainMenuBar := false;
    ShowAppAssetsBrowser := false;
    ShowAppConsole := false;
    ShowAppCustomRendering := false;
    ShowAppDocuments := false;
    ShowAppDockSpace := false;
    ShowAppLog := false;
    ShowAppLayout := false;
    ShowAppPropertyEditor := false;
    ShowAppSimpleOverlay := false;
    ShowAppAutoResize := false;
    ShowAppConstrainedResize := false;
    ShowAppFullscreen := false;
    ShowAppLongText := false;
    ShowAppWindowTitles := false;

    // Dear ImGui Tools (accessible from the "Tools" menu)
    ShowMetrics := false;
    ShowDebugLog := false;
    ShowIDStackTool := false;
    ShowStyleEditor := false;
    ShowAbout := false;

    // Other data
    DemoTree := nil;

    ~ImGuiDemoWindowData() { if (DemoTree) ExampleTree_DestroyNode(DemoTree); }
};

// Demonstrate most Dear ImGui features (this is big function!)
// You may execute this function to experiment with the UI and understand what it does.
// You may then search for keywords in the code when you are interested by a specific feature.
// [forward declared comment]:
// create Demo window. demonstrate most ImGui features. call this to learn about the library! try to make it always available in your application!
ShowDemoWindow :: proc(p_open : ^bool = nil)
{
    // Exceptionally add an extra assert here for people confused about initial Dear ImGui setup
    // Most functions would normally just assert/crash if the context is missing.
    assert(GetCurrentContext() != nil, "Missing Dear ImGui context. Refer to examples app!");

    // Verify ABI compatibility between caller code and compiled version of Dear ImGui. This helps detects some build issues.
    IMGUI_CHECKVERSION();

    // Stored data
    static ImGuiDemoWindowData demo_data;

    // Examples Apps (accessible from the "Examples" menu)
    if (demo_data.ShowMainMenuBar)          { ShowExampleAppMainMenuBar(); }
    if (demo_data.ShowAppDockSpace)         { ShowExampleAppDockSpace(&demo_data.ShowAppDockSpace); } // Important: Process the Docking app first, as explicit DockSpace() nodes needs to be submitted early (read comments near the DockSpace function)
    if (demo_data.ShowAppDocuments)         { ShowExampleAppDocuments(&demo_data.ShowAppDocuments); } // ...process the Document app next, as it may also use a DockSpace()
    if (demo_data.ShowAppAssetsBrowser)     { ShowExampleAppAssetsBrowser(&demo_data.ShowAppAssetsBrowser); }
    if (demo_data.ShowAppConsole)           { ShowExampleAppConsole(&demo_data.ShowAppConsole); }
    if (demo_data.ShowAppCustomRendering)   { ShowExampleAppCustomRendering(&demo_data.ShowAppCustomRendering); }
    if (demo_data.ShowAppLog)               { ShowExampleAppLog(&demo_data.ShowAppLog); }
    if (demo_data.ShowAppLayout)            { ShowExampleAppLayout(&demo_data.ShowAppLayout); }
    if (demo_data.ShowAppPropertyEditor)    { ShowExampleAppPropertyEditor(&demo_data.ShowAppPropertyEditor, &demo_data); }
    if (demo_data.ShowAppSimpleOverlay)     { ShowExampleAppSimpleOverlay(&demo_data.ShowAppSimpleOverlay); }
    if (demo_data.ShowAppAutoResize)        { ShowExampleAppAutoResize(&demo_data.ShowAppAutoResize); }
    if (demo_data.ShowAppConstrainedResize) { ShowExampleAppConstrainedResize(&demo_data.ShowAppConstrainedResize); }
    if (demo_data.ShowAppFullscreen)        { ShowExampleAppFullscreen(&demo_data.ShowAppFullscreen); }
    if (demo_data.ShowAppLongText)          { ShowExampleAppLongText(&demo_data.ShowAppLongText); }
    if (demo_data.ShowAppWindowTitles)      { ShowExampleAppWindowTitles(&demo_data.ShowAppWindowTitles); }

    // Dear ImGui Tools (accessible from the "Tools" menu)
    if (demo_data.ShowMetrics)              { ShowMetricsWindow(&demo_data.ShowMetrics); }
    if (demo_data.ShowDebugLog)             { ShowDebugLogWindow(&demo_data.ShowDebugLog); }
    if (demo_data.ShowIDStackTool)          { ShowIDStackToolWindow(&demo_data.ShowIDStackTool); }
    if (demo_data.ShowAbout)                { ShowAboutWindow(&demo_data.ShowAbout); }
    if (demo_data.ShowStyleEditor)
    {
        Begin("Dear ImGui Style Editor", &demo_data.ShowStyleEditor);
        ShowStyleEditor();
        End();
    }

    // Demonstrate the various window flags. Typically you would just use the default!
    static bool no_titlebar = false;
    static bool no_scrollbar = false;
    static bool no_menu = false;
    static bool no_move = false;
    static bool no_resize = false;
    static bool no_collapse = false;
    static bool no_close = false;
    static bool no_nav = false;
    static bool no_background = false;
    static bool no_bring_to_front = false;
    static bool no_docking = false;
    static bool unsaved_document = false;

    window_flags := 0;
    if (no_titlebar)        window_flags |= ImGuiWindowFlags_NoTitleBar;
    if (no_scrollbar)       window_flags |= ImGuiWindowFlags_NoScrollbar;
    if (!no_menu)           window_flags |= ImGuiWindowFlags_MenuBar;
    if (no_move)            window_flags |= ImGuiWindowFlags_NoMove;
    if (no_resize)          window_flags |= ImGuiWindowFlags_NoResize;
    if (no_collapse)        window_flags |= ImGuiWindowFlags_NoCollapse;
    if (no_nav)             window_flags |= ImGuiWindowFlags_NoNav;
    if (no_background)      window_flags |= ImGuiWindowFlags_NoBackground;
    if (no_bring_to_front)  window_flags |= ImGuiWindowFlags_NoBringToFrontOnFocus;
    if (no_docking)         window_flags |= ImGuiWindowFlags_NoDocking;
    if (unsaved_document)   window_flags |= ImGuiWindowFlags_UnsavedDocument;
    if (no_close)           p_open = nil; // Don't pass our bool* to Begin

    // We specify a default position/size in case there's no data in the .ini file.
    // We only do it to make the demo applications a little more welcoming, but typically this isn't required.
    main_viewport := GetMainViewport();
    SetNextWindowPos(ImVec2{main_viewport.WorkPos.x + 650, main_viewport.WorkPos.y + 20}, ImGuiCond_FirstUseEver);
    SetNextWindowSize(ImVec2{550, 680}, ImGuiCond_FirstUseEver);

    // Main body of the Demo window starts here.
    if (!Begin("Dear ImGui Demo", p_open, window_flags))
    {
        // Early out if the window is collapsed, as an optimization.
        End();
        return;
    }

    // Most "big" widgets share a common width settings by default. See 'Demo->Layout->Widgets Width' for details.
    PushItemWidth(GetFontSize() * -12);           // e.g. Leave a fixed amount of width for labels (by passing a negative value), the rest goes to widgets.
    //ImGui::PushItemWidth(-ImGui::GetWindowWidth() * 0.35f);   // e.g. Use 2/3 of the space for widgets and 1/3 for labels (right align)

    // Menu Bar
    ShowDemoWindowMenuBar(&demo_data);

    Text("dear imgui says hello! (%s) (%d)", IMGUI_VERSION, IMGUI_VERSION_NUM);
    Spacing();

    IMGUI_DEMO_MARKER("Help");
    if (CollapsingHeader("Help"))
    {
        SeparatorText("ABOUT THIS DEMO:");
        BulletText("Sections below are demonstrating many aspects of the library.");
        BulletText("The \"Examples\" menu above leads to more demo contents.");
        BulletText("The \"Tools\" menu above gives access to: About Box, Style Editor,\n"
                          "and Metrics/Debugger (general purpose Dear ImGui debugging tool).");

        SeparatorText("PROGRAMMER GUIDE:");
        BulletText("See the ShowDemoWindow() code in imgui_demo.cpp. <- you are here!");
        BulletText("See comments in imgui.cpp.");
        BulletText("See example applications in the examples/ folder.");
        BulletText("Read the FAQ at ");
        SameLine(0, 0);
        TextLinkOpenURL("https://www.dearimgui.com/faq/");
        BulletText("Set 'io.ConfigFlags |= NavEnableKeyboard' for keyboard controls.");
        BulletText("Set 'io.ConfigFlags |= NavEnableGamepad' for gamepad controls.");

        SeparatorText("USER GUIDE:");
        ShowUserGuide();
    }

    IMGUI_DEMO_MARKER("Configuration");
    if (CollapsingHeader("Configuration"))
    {
        ImGuiIO& io = GetIO();

        if (TreeNode("Configuration##2"))
        {
            SeparatorText("General");
            CheckboxFlags("io.ConfigFlags: NavEnableKeyboard",    &io.ConfigFlags, ImGuiConfigFlags_NavEnableKeyboard);
            SameLine(); HelpMarker("Enable keyboard controls.");
            CheckboxFlags("io.ConfigFlags: NavEnableGamepad",     &io.ConfigFlags, ImGuiConfigFlags_NavEnableGamepad);
            SameLine(); HelpMarker("Enable gamepad controls. Require backend to set io.BackendFlags |= ImGuiBackendFlags_HasGamepad.\n\nRead instructions in imgui.cpp for details.");
            CheckboxFlags("io.ConfigFlags: NoMouse",              &io.ConfigFlags, ImGuiConfigFlags_NoMouse);
            SameLine(); HelpMarker("Instruct dear imgui to disable mouse inputs and interactions.");

            // The "NoMouse" option can get us stuck with a disabled mouse! Let's provide an alternative way to fix it:
            if (io.ConfigFlags & ImGuiConfigFlags_NoMouse)
            {
                if (fmodf(cast(ast) ast) met) me.40) < 0.20)
                {
                    SameLine();
                    Text("<<PRESS SPACE TO DISABLE>>");
                }
                // Prevent both being checked
                if (IsKeyPressed(ImGuiKey_Space) || (io.ConfigFlags & ImGuiConfigFlags_NoKeyboard))
                    io.ConfigFlags &= ~ImGuiConfigFlags_NoMouse;
            }

            CheckboxFlags("io.ConfigFlags: NoMouseCursorChange",  &io.ConfigFlags, ImGuiConfigFlags_NoMouseCursorChange);
            SameLine(); HelpMarker("Instruct backend to not alter mouse cursor shape and visibility.");
            CheckboxFlags("io.ConfigFlags: NoKeyboard", &io.ConfigFlags, ImGuiConfigFlags_NoKeyboard);
            SameLine(); HelpMarker("Instruct dear imgui to disable keyboard inputs and interactions.");

            Checkbox("io.ConfigInputTrickleEventQueue", &io.ConfigInputTrickleEventQueue);
            SameLine(); HelpMarker("Enable input queue trickling: some types of events submitted during the same frame (e.g. button down + up) will be spread over multiple frames, improving interactions with low framerates.");
            Checkbox("io.MouseDrawCursor", &io.MouseDrawCursor);
            SameLine(); HelpMarker("Instruct Dear ImGui to render a mouse cursor itself. Note that a mouse cursor rendered via your application GPU rendering path will feel more laggy than hardware cursor, but will be more in sync with your other visuals.\n\nSome desktop applications may use both kinds of cursors (e.g. enable software cursor only when resizing/dragging something).");

            SeparatorText("Keyboard/Gamepad Navigation");
            Checkbox("io.ConfigNavSwapGamepadButtons", &io.ConfigNavSwapGamepadButtons);
            Checkbox("io.ConfigNavMoveSetMousePos", &io.ConfigNavMoveSetMousePos);
            SameLine(); HelpMarker("Directional/tabbing navigation teleports the mouse cursor. May be useful on TV/console systems where moving a virtual mouse is difficult");
            Checkbox("io.ConfigNavCaptureKeyboard", &io.ConfigNavCaptureKeyboard);
            Checkbox("io.ConfigNavEscapeClearFocusItem", &io.ConfigNavEscapeClearFocusItem);
            SameLine(); HelpMarker("Pressing Escape clears focused item.");
            Checkbox("io.ConfigNavEscapeClearFocusWindow", &io.ConfigNavEscapeClearFocusWindow);
            SameLine(); HelpMarker("Pressing Escape clears focused window.");
            Checkbox("io.ConfigNavCursorVisibleAuto", &io.ConfigNavCursorVisibleAuto);
            SameLine(); HelpMarker("Using directional navigation key makes the cursor visible. Mouse click hides the cursor.");
            Checkbox("io.ConfigNavCursorVisibleAlways", &io.ConfigNavCursorVisibleAlways);
            SameLine(); HelpMarker("Navigation cursor is always visible.");

            SeparatorText("Docking");
            CheckboxFlags("io.ConfigFlags: DockingEnable", &io.ConfigFlags, ImGuiConfigFlags_DockingEnable);
            SameLine();
            if (io.ConfigDockingWithShift)
                HelpMarker("Drag from window title bar or their tab to dock/undock. Hold SHIFT to enable docking.\n\nDrag from window menu button (upper-left button) to undock an entire node (all windows).");
            else
                HelpMarker("Drag from window title bar or their tab to dock/undock. Hold SHIFT to disable docking.\n\nDrag from window menu button (upper-left button) to undock an entire node (all windows).");
            if (io.ConfigFlags & ImGuiConfigFlags_DockingEnable)
            {
                Indent();
                Checkbox("io.ConfigDockingNoSplit", &io.ConfigDockingNoSplit);
                SameLine(); HelpMarker("Simplified docking mode: disable window splitting, so docking is limited to merging multiple windows together into tab-bars.");
                Checkbox("io.ConfigDockingWithShift", &io.ConfigDockingWithShift);
                SameLine(); HelpMarker("Enable docking when holding Shift only (allow to drop in wider space, reduce visual noise)");
                Checkbox("io.ConfigDockingAlwaysTabBar", &io.ConfigDockingAlwaysTabBar);
                SameLine(); HelpMarker("Create a docking node and tab-bar on single floating windows.");
                Checkbox("io.ConfigDockingTransparentPayload", &io.ConfigDockingTransparentPayload);
                SameLine(); HelpMarker("Make window or viewport transparent when docking and only display docking boxes on the target viewport. Useful if rendering of multiple viewport cannot be synced. Best used with ConfigViewportsNoAutoMerge.");
                Unindent();
            }

            SeparatorText("Multi-viewports");
            CheckboxFlags("io.ConfigFlags: ViewportsEnable", &io.ConfigFlags, ImGuiConfigFlags_ViewportsEnable);
            SameLine(); HelpMarker("[beta] Enable beta multi-viewports support. See ImGuiPlatformIO for details.");
            if (io.ConfigFlags & ImGuiConfigFlags_ViewportsEnable)
            {
                Indent();
                Checkbox("io.ConfigViewportsNoAutoMerge", &io.ConfigViewportsNoAutoMerge);
                SameLine(); HelpMarker("Set to make all floating imgui windows always create their own viewport. Otherwise, they are merged into the main host viewports when overlapping it.");
                Checkbox("io.ConfigViewportsNoTaskBarIcon", &io.ConfigViewportsNoTaskBarIcon);
                SameLine(); HelpMarker("Toggling this at runtime is normally unsupported (most platform backends won't refresh the task bar icon state right away).");
                Checkbox("io.ConfigViewportsNoDecoration", &io.ConfigViewportsNoDecoration);
                SameLine(); HelpMarker("Toggling this at runtime is normally unsupported (most platform backends won't refresh the decoration right away).");
                Checkbox("io.ConfigViewportsNoDefaultParent", &io.ConfigViewportsNoDefaultParent);
                SameLine(); HelpMarker("Toggling this at runtime is normally unsupported (most platform backends won't refresh the parenting right away).");
                Unindent();
            }

            SeparatorText("Windows");
            Checkbox("io.ConfigWindowsResizeFromEdges", &io.ConfigWindowsResizeFromEdges);
            SameLine(); HelpMarker("Enable resizing of windows from their edges and from the lower-left corner.\nThis requires ImGuiBackendFlags_HasMouseCursors for better mouse cursor feedback.");
            Checkbox("io.ConfigWindowsMoveFromTitleBarOnly", &io.ConfigWindowsMoveFromTitleBarOnly);
            Checkbox("io.ConfigWindowsCopyContentsWithCtrlC", &io.ConfigWindowsCopyContentsWithCtrlC); // [EXPERIMENTAL]
            SameLine(); HelpMarker("*EXPERIMENTAL* CTRL+C copy the contents of focused window into the clipboard.\n\nExperimental because:\n- (1) has known issues with nested Begin/End pairs.\n- (2) text output quality varies.\n- (3) text output is in submission order rather than spatial order.");
            Checkbox("io.ConfigScrollbarScrollByPage", &io.ConfigScrollbarScrollByPage);
            SameLine(); HelpMarker("Enable scrolling page by page when clicking outside the scrollbar grab.\nWhen disabled, always scroll to clicked location.\nWhen enabled, Shift+Click scrolls to clicked location.");

            SeparatorText("Widgets");
            Checkbox("io.ConfigInputTextCursorBlink", &io.ConfigInputTextCursorBlink);
            SameLine(); HelpMarker("Enable blinking cursor (optional as some users consider it to be distracting).");
            Checkbox("io.ConfigInputTextEnterKeepActive", &io.ConfigInputTextEnterKeepActive);
            SameLine(); HelpMarker("Pressing Enter will keep item active and select contents (single-line only).");
            Checkbox("io.ConfigDragClickToInputText", &io.ConfigDragClickToInputText);
            SameLine(); HelpMarker("Enable turning DragXXX widgets into text input with a simple mouse click-release (without moving).");
            Checkbox("io.ConfigMacOSXBehaviors", &io.ConfigMacOSXBehaviors);
            SameLine(); HelpMarker("Swap Cmd<>Ctrl keys, enable various MacOS style behaviors.");
            Text("Also see Style.Rendering for rendering options.");

            // Also read: https://github.com/ocornut/imgui/wiki/Error-Handling
            SeparatorText("Error Handling");

            Checkbox("io.ConfigErrorRecovery", &io.ConfigErrorRecovery);
            SameLine(); HelpMarker(
                "Options to configure how we handle recoverable errors.\n"
                "- Error recovery is not perfect nor guaranteed! It is a feature to ease development.\n"
                "- You not are not supposed to rely on it in the course of a normal application run.\n"
                "- Possible usage: facilitate recovery from errors triggered from a scripting language or after specific exceptions handlers.\n"
                "- Always ensure that on programmers seat you have at minimum Asserts or Tooltips enabled when making direct imgui API call!"
                "Otherwise it would severely hinder your ability to catch and correct mistakes!");
            Checkbox("io.ConfigErrorRecoveryEnableAssert", &io.ConfigErrorRecoveryEnableAssert);
            Checkbox("io.ConfigErrorRecoveryEnableDebugLog", &io.ConfigErrorRecoveryEnableDebugLog);
            Checkbox("io.ConfigErrorRecoveryEnableTooltip", &io.ConfigErrorRecoveryEnableTooltip);
            if (!io.ConfigErrorRecoveryEnableAssert && !io.ConfigErrorRecoveryEnableDebugLog && !io.ConfigErrorRecoveryEnableTooltip)
                io.ConfigErrorRecoveryEnableAssert = io.ConfigErrorRecoveryEnableDebugLog = io.ConfigErrorRecoveryEnableTooltip = true;

            // Also read: https://github.com/ocornut/imgui/wiki/Debug-Tools
            SeparatorText("Debug");
            Checkbox("io.ConfigDebugIsDebuggerPresent", &io.ConfigDebugIsDebuggerPresent);
            SameLine(); HelpMarker("Enable various tools calling runtime.debug_trap.\n\nRequires a debugger being attached, otherwise runtime.debug_trap options will appear to crash your application.");
            Checkbox("io.ConfigDebugHighlightIdConflicts", &io.ConfigDebugHighlightIdConflicts);
            SameLine(); HelpMarker("Highlight and show an error message when multiple items have conflicting identifiers.");
            BeginDisabled();
            Checkbox("io.ConfigDebugBeginReturnValueOnce", &io.ConfigDebugBeginReturnValueOnce);
            EndDisabled();
            SameLine(); HelpMarker("First calls to Begin()/BeginChild() will return false.\n\nTHIS OPTION IS DISABLED because it needs to be set at application boot-time to make sense. Showing the disabled option is a way to make this feature easier to discover.");
            Checkbox("io.ConfigDebugBeginReturnValueLoop", &io.ConfigDebugBeginReturnValueLoop);
            SameLine(); HelpMarker("Some calls to Begin()/BeginChild() will return false.\n\nWill cycle through window depths then repeat. Windows should be flickering for running.");
            Checkbox("io.ConfigDebugIgnoreFocusLoss", &io.ConfigDebugIgnoreFocusLoss);
            SameLine(); HelpMarker("Option to deactivate io.AddFocusEvent(false) handling. May facilitate interactions with a debugger when focus loss leads to clearing inputs data.");
            Checkbox("io.ConfigDebugIniSettings", &io.ConfigDebugIniSettings);
            SameLine(); HelpMarker("Option to save .ini data with extra comments (particularly helpful for Docking, but makes saving slower).");

            TreePop();
            Spacing();
        }

        IMGUI_DEMO_MARKER("Configuration/Backend Flags");
        if (TreeNode("Backend Flags"))
        {
            HelpMarker(
                "Those flags are set by the backends (imgui_impl_xxx files) to specify their capabilities.\n"
                "Here we expose them as read-only fields to avoid breaking interactions with your backend.");

            // Make a local copy to avoid modifying actual backend flags.
            // FIXME: Maybe we need a BeginReadonly() equivalent to keep label bright?
            BeginDisabled();
            CheckboxFlags("io.BackendFlags: HasGamepad",             &io.BackendFlags, ImGuiBackendFlags_HasGamepad);
            CheckboxFlags("io.BackendFlags: HasMouseCursors",        &io.BackendFlags, ImGuiBackendFlags_HasMouseCursors);
            CheckboxFlags("io.BackendFlags: HasSetMousePos",         &io.BackendFlags, ImGuiBackendFlags_HasSetMousePos);
            CheckboxFlags("io.BackendFlags: PlatformHasViewports",   &io.BackendFlags, ImGuiBackendFlags_PlatformHasViewports);
            CheckboxFlags("io.BackendFlags: HasMouseHoveredViewport",&io.BackendFlags, ImGuiBackendFlags_HasMouseHoveredViewport);
            CheckboxFlags("io.BackendFlags: RendererHasVtxOffset",   &io.BackendFlags, ImGuiBackendFlags_RendererHasVtxOffset);
            CheckboxFlags("io.BackendFlags: RendererHasViewports",   &io.BackendFlags, ImGuiBackendFlags_RendererHasViewports);
            EndDisabled();

            TreePop();
            Spacing();
        }

        IMGUI_DEMO_MARKER("Configuration/Style");
        if (TreeNode("Style"))
        {
            Checkbox("Style Editor", &demo_data.ShowStyleEditor);
            SameLine();
            HelpMarker("The same contents can be accessed in 'Tools.Style Editor' or by calling the ShowStyleEditor() function.");
            TreePop();
            Spacing();
        }

        IMGUI_DEMO_MARKER("Configuration/Capture, Logging");
        if (TreeNode("Capture/Logging"))
        {
            HelpMarker(
                "The logging API redirects all text output so you can easily capture the content of "
                "a window or a block. Tree nodes can be automatically expanded.\n"
                "Try opening any of the contents below in this window and then click one of the \"Log To\" button.");
            LogButtons();

            HelpMarker("You can also call LogText() to output directly to the log without a visual output.");
            if (Button("Copy \"Hello, world!\" to clipboard"))
            {
                LogToClipboard();
                LogText("Hello, world!");
                LogFinish();
            }
            TreePop();
        }
    }

    IMGUI_DEMO_MARKER("Window options");
    if (CollapsingHeader("Window options"))
    {
        if (BeginTable("split", 3))
        {
            TableNextColumn(); Checkbox("No titlebar", &no_titlebar);
            TableNextColumn(); Checkbox("No scrollbar", &no_scrollbar);
            TableNextColumn(); Checkbox("No menu", &no_menu);
            TableNextColumn(); Checkbox("No move", &no_move);
            TableNextColumn(); Checkbox("No resize", &no_resize);
            TableNextColumn(); Checkbox("No collapse", &no_collapse);
            TableNextColumn(); Checkbox("No close", &no_close);
            TableNextColumn(); Checkbox("No nav", &no_nav);
            TableNextColumn(); Checkbox("No background", &no_background);
            TableNextColumn(); Checkbox("No bring to front", &no_bring_to_front);
            TableNextColumn(); Checkbox("No docking", &no_docking);
            TableNextColumn(); Checkbox("Unsaved document", &unsaved_document);
            EndTable();
        }
    }

    // All demo contents
    ShowDemoWindowWidgets(&demo_data);
    ShowDemoWindowLayout();
    ShowDemoWindowPopups();
    ShowDemoWindowTables();
    ShowDemoWindowInputs();

    // End of ShowDemoWindow()
    PopItemWidth();
    End();
}

//-----------------------------------------------------------------------------
// [SECTION] ShowDemoWindowMenuBar()
//-----------------------------------------------------------------------------

ShowDemoWindowMenuBar :: proc(demo_data : ^ImGuiDemoWindowData)
{
    IMGUI_DEMO_MARKER("Menu");
    if (BeginMenuBar())
    {
        if (BeginMenu("Menu"))
        {
            IMGUI_DEMO_MARKER("Menu/File");
            ShowExampleMenuFile();
            EndMenu();
        }
        if (BeginMenu("Examples"))
        {
            IMGUI_DEMO_MARKER("Menu/Examples");
            MenuItem("Main menu bar", nil, &demo_data.ShowMainMenuBar);

            SeparatorText("Mini apps");
            MenuItem("Assets Browser", nil, &demo_data.ShowAppAssetsBrowser);
            MenuItem("Console", nil, &demo_data.ShowAppConsole);
            MenuItem("Custom rendering", nil, &demo_data.ShowAppCustomRendering);
            MenuItem("Documents", nil, &demo_data.ShowAppDocuments);
            MenuItem("Dockspace", nil, &demo_data.ShowAppDockSpace);
            MenuItem("Log", nil, &demo_data.ShowAppLog);
            MenuItem("Property editor", nil, &demo_data.ShowAppPropertyEditor);
            MenuItem("Simple layout", nil, &demo_data.ShowAppLayout);
            MenuItem("Simple overlay", nil, &demo_data.ShowAppSimpleOverlay);

            SeparatorText("Concepts");
            MenuItem("Auto-resizing window", nil, &demo_data.ShowAppAutoResize);
            MenuItem("Constrained-resizing window", nil, &demo_data.ShowAppConstrainedResize);
            MenuItem("Fullscreen window", nil, &demo_data.ShowAppFullscreen);
            MenuItem("Long text display", nil, &demo_data.ShowAppLongText);
            MenuItem("Manipulating window titles", nil, &demo_data.ShowAppWindowTitles);

            EndMenu();
        }
        //if (ImGui::MenuItem("MenuItem")) {} // You can also use MenuItem() inside a menu bar!
        if (BeginMenu("Tools"))
        {
            IMGUI_DEMO_MARKER("Menu/Tools");
            ImGuiIO& io = GetIO();
when !(IMGUI_DISABLE_DEBUG_TOOLS) {
            has_debug_tools := true;
} else {
            has_debug_tools := false;
}
            MenuItem("Metrics/Debugger", nil, &demo_data.ShowMetrics, has_debug_tools);
            MenuItem("Debug Log", nil, &demo_data.ShowDebugLog, has_debug_tools);
            MenuItem("ID Stack Tool", nil, &demo_data.ShowIDStackTool, has_debug_tools);
            is_debugger_present := io.ConfigDebugIsDebuggerPresent;
            if (MenuItem("Item Picker", nil, false, has_debug_tools && is_debugger_present))
                DebugStartItemPicker();
            if (!is_debugger_present)
                SetItemTooltip("Requires io.ConfigDebugIsDebuggerPresent=true to be set.\n\nWe otherwise disable the menu option to avoid casual users crashing the application.\n\nYou can however always access the Item Picker in Metrics.Tools.");
            MenuItem("Style Editor", nil, &demo_data.ShowStyleEditor);
            MenuItem("About Dear ImGui", nil, &demo_data.ShowAbout);

            SeparatorText("Debug Options");
            MenuItem("Highlight ID Conflicts", nil, &io.ConfigDebugHighlightIdConflicts, has_debug_tools);
            EndMenu();
        }
        EndMenuBar();
    }
}

//-----------------------------------------------------------------------------
// [SECTION] ShowDemoWindowWidgets()
//-----------------------------------------------------------------------------

ShowDemoWindowWidgets :: proc(demo_data : ^ImGuiDemoWindowData)
{
    IMGUI_DEMO_MARKER("Widgets");
    //ImGui::SetNextItemOpen(true, ImGuiCond_Once);
    if (!CollapsingHeader("Widgets"))
        return;

    static bool disable_all = false; // The Checkbox for that is inside the "Disabled" section at the bottom
    if (disable_all)
        BeginDisabled();

    IMGUI_DEMO_MARKER("Widgets/Basic");
    if (TreeNode("Basic"))
    {
        SeparatorText("General");

        IMGUI_DEMO_MARKER("Widgets/Basic/Button");
        static i32 clicked = 0;
        if (Button("Button"))
            clicked += 1;
        if (clicked & 1)
        {
            SameLine();
            Text("Thanks for clicking me!");
        }

        IMGUI_DEMO_MARKER("Widgets/Basic/Checkbox");
        static bool check = true;
        Checkbox("checkbox", &check);

        IMGUI_DEMO_MARKER("Widgets/Basic/RadioButton");
        static i32 e = 0;
        RadioButton("radio a", &e, 0); SameLine();
        RadioButton("radio b", &e, 1); SameLine();
        RadioButton("radio c", &e, 2);

        // Color buttons, demonstrate using PushID() to add unique identifier in the ID stack, and changing style.
        IMGUI_DEMO_MARKER("Widgets/Basic/Buttons (Colored)");
        for i32 i = 0; i < 7; i++
        {
            if (i > 0)
                SameLine();
            PushID(i);
            PushStyleColor(ImGuiCol_Button, (ImVec4)ImColor::HSV(i / 7.0, 0.6, 0.6));
            PushStyleColor(ImGuiCol_ButtonHovered, (ImVec4)ImColor::HSV(i / 7.0, 0.7, 0.7));
            PushStyleColor(ImGuiCol_ButtonActive, (ImVec4)ImColor::HSV(i / 7.0, 0.8, 0.8));
            Button("Click");
            PopStyleColor(3);
            PopID();
        }

        // Use AlignTextToFramePadding() to align text baseline to the baseline of framed widgets elements
        // (otherwise a Text+SameLine+Button sequence will have the text a little too high by default!)
        // See 'Demo->Layout->Text Baseline Alignment' for details.
        AlignTextToFramePadding();
        Text("Hold to repeat:");
        SameLine();

        // Arrow buttons with Repeater
        IMGUI_DEMO_MARKER("Widgets/Basic/Buttons (Repeating)");
        static i32 counter = 0;
        spacing := GetStyle().ItemInnerSpacing.x;
        PushItemFlag(ImGuiItemFlags_ButtonRepeat, true);
        if (ArrowButton("##left", ImGuiDir_Left)) { counter -= 1; }
        SameLine(0.0, spacing);
        if (ArrowButton("##right", ImGuiDir_Right)) { counter += 1; }
        PopItemFlag();
        SameLine();
        Text("%d", counter);

        Button("Tooltip");
        SetItemTooltip("I am a tooltip");

        LabelText("label", "Value");

        SeparatorText("Inputs");

        {
            // To wire InputText() with std::string or any other custom string type,
            // see the "Text Input > Resize Callback" section of this demo, and the misc/cpp/imgui_stdlib.h file.
            IMGUI_DEMO_MARKER("Widgets/Basic/InputText");
            static u8 str0[128] = "Hello, world!";
            InputText("input text", str0, len(str0));
            SameLine(); HelpMarker(
                "USER:\n"
                "Hold SHIFT or use mouse to select text.\n"
                "CTRL+Left/Right to word jump.\n"
                "CTRL+A or Double-Click to select all.\n"
                "CTRL+X,CTRL+C,CTRL+V clipboard.\n"
                "CTRL+Z,CTRL+Y undo/redo.\n"
                "ESCAPE to revert.\n\n"
                "PROGRAMMER:\n"
                "You can use the ImGuiInputTextFlags_CallbackResize facility if you need to wire InputText() "
                "to a dynamic string type. See misc/cpp/imgui_stdlib.h for an example (this is not demonstrated "
                "in imgui_demo.cpp).");

            static u8 str1[128] = "";
            InputTextWithHint("input text (w/ hint)", "enter text here", str1, len(str1));

            IMGUI_DEMO_MARKER("Widgets/Basic/InputInt, InputFloat");
            static i32 i0 = 123;
            InputInt("input i32", &i0);

            static f32 f0 = 0.001;
            InputFloat("input f32", &f0, 0.01, 1.0, "%.3");

            static f64 d0 = 999999.00000001;
            InputDouble("input f64", &d0, 0.01, 1.0, "%.8");

            static f32 f1 = 1.e10f;
            InputFloat("input scientific", &f1, 0.0, 0.0, "%e");
            SameLine(); HelpMarker(
                "You can input value using the scientific notation,\n"
                "  e.g. \"1e+8\" becomes \"100000000\".");

            static f32 vec4a[4] = { 0.10, 0.20, 0.30, 0.44 };
            InputFloat3("input float3", vec4a);
        }

        SeparatorText("Drags");

        {
            IMGUI_DEMO_MARKER("Widgets/Basic/DragInt, DragFloat");
            static i32 i1 = 50, i2 = 42, i3 = 128;
            DragInt("drag i32", &i1, 1);
            SameLine(); HelpMarker(
                "Click and drag to edit value.\n"
                "Hold SHIFT/ALT for faster/slower edit.\n"
                "Double-click or CTRL+click to input value.");
            DragInt("drag i32 0..100", &i2, 1, 0, 100, "%d%%", ImGuiSliderFlags_AlwaysClamp);
            DragInt("drag i32 wrap 100..200", &i3, 1, 100, 200, "%d", ImGuiSliderFlags_WrapAround);

            static f32 f1 = 1.00, f2 = 0.0067;
            DragFloat("drag f32", &f1, 0.005);
            DragFloat("drag small f32", &f2, 0.0001, 0.0, 0.0, "%.06 ns");
            //ImGui::DragFloat("drag wrap -1..1", &f3, 0.005f, -1.0f, 1.0f, NULL, ImGuiSliderFlags_WrapAround);
        }

        SeparatorText("Sliders");

        {
            IMGUI_DEMO_MARKER("Widgets/Basic/SliderInt, SliderFloat");
            static i32 i1 = 0;
            SliderInt("slider i32", &i1, -1, 3);
            SameLine(); HelpMarker("CTRL+click to input value.");

            static f32 f1 = 0.123, f2 = 0.0;
            SliderFloat("slider f32", &f1, 0.0, 1.0, "ratio = %.3");
            SliderFloat("slider f32 (log)", &f2, -10.0, 10.0, "%.4", ImGuiSliderFlags_Logarithmic);

            IMGUI_DEMO_MARKER("Widgets/Basic/SliderAngle");
            static f32 angle = 0.0;
            SliderAngle("slider angle", &angle);

            // Using the format string to display a name instead of an integer.
            // Here we completely omit '%d' from the format string, so it'll only display a name.
            // This technique can also be used with DragInt().
            IMGUI_DEMO_MARKER("Widgets/Basic/Slider (enum)");
            enum Element { Element_Fire, Element_Earth, Element_Air, Element_Water, Element_COUNT };
            static i32 elem = Element_Fire;
            const u8* elems_names[Element_COUNT] = { "Fire", "Earth", "Air", "Water" };
            elem_name := (elem >= 0 && elem < Element_COUNT) ? elems_names[elem] : "Unknown";
            SliderInt("slider enum", &elem, 0, Element_COUNT - 1, elem_name); // Use ImGuiSliderFlags_NoInput flag to disable CTRL+Click here.
            SameLine(); HelpMarker("Using the format string parameter to display a name instead of the underlying integer.");
        }

        SeparatorText("Selectors/Pickers");

        {
            IMGUI_DEMO_MARKER("Widgets/Basic/ColorEdit3, ColorEdit4");
            static f32 col1[3] = { 1.0, 0.0, 0.2 };
            static f32 col2[4] = { 0.4, 0.7, 0.0, 0.5 };
            ColorEdit3("color 1", col1);
            SameLine(); HelpMarker(
                "Click on the color square to open a color picker.\n"
                "Click and hold to use drag and drop.\n"
                "Right-click on the color square to show options.\n"
                "CTRL+click on individual component to input value.\n");

            ColorEdit4("color 2", col2);
        }

        {
            // Using the _simplified_ one-liner Combo() api here
            // See "Combo" section for examples of how to use the more flexible BeginCombo()/EndCombo() api.
            IMGUI_DEMO_MARKER("Widgets/Basic/Combo");
            const u8* items[] = { "AAAA", "BBBB", "CCCC", "DDDD", "EEEE", "FFFF", "GGGG", "HHHH", "IIIIIII", "JJJJ", "KKKKKKK" };
            static i32 item_current = 0;
            Combo("combo", &item_current, items, len(items));
            SameLine(); HelpMarker(
                "Using the simplified one-liner Combo API here.\n"
                "Refer to the \"Combo\" section below for an explanation of how to use the more flexible and general BeginCombo/EndCombo API.");
        }

        {
            // Using the _simplified_ one-liner ListBox() api here
            // See "List boxes" section for examples of how to use the more flexible BeginListBox()/EndListBox() api.
            IMGUI_DEMO_MARKER("Widgets/Basic/ListBox");
            const u8* items[] = { "Apple", "Banana", "Cherry", "Kiwi", "Mango", "Orange", "Pineapple", "Strawberry", "Watermelon" };
            static i32 item_current = 1;
            ListBox("listbox", &item_current, items, len(items), 4);
            SameLine(); HelpMarker(
                "Using the simplified one-liner ListBox API here.\n"
                "Refer to the \"List boxes\" section below for an explanation of how to use the more flexible and general BeginListBox/EndListBox API.");
        }

        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Tooltips");
    if (TreeNode("Tooltips"))
    {
        // Tooltips are windows following the mouse. They do not take focus away.
        SeparatorText("General");

        // Typical use cases:
        // - Short-form (text only):      SetItemTooltip("Hello");
        // - Short-form (any contents):   if (BeginItemTooltip()) { Text("Hello"); EndTooltip(); }

        // - Full-form (text only):       if (IsItemHovered(...)) { SetTooltip("Hello"); }
        // - Full-form (any contents):    if (IsItemHovered(...) && BeginTooltip()) { Text("Hello"); EndTooltip(); }

        HelpMarker(
            "Tooltip are typically created by using a IsItemHovered() + SetTooltip() sequence.\n\n"
            "We provide a helper SetItemTooltip() function to perform the two with standards flags.");

        sz := ImVec2{-math.F32_MIN, 0.0};

        Button("Basic", sz);
        SetItemTooltip("I am a tooltip");

        Button("Fancy", sz);
        if (BeginItemTooltip())
        {
            Text("I am a fancy tooltip");
            static f32 arr[] = { 0.6, 0.1, 1.0, 0.5, 0.92, 0.1, 0.2 };
            PlotLines("Curve", arr, len(arr));
            Text("Sin(time) = %f", sinf(cast(f32) GetTime()));
            EndTooltip();
        }

        SeparatorText("Always On");

        // Showcase NOT relying on a IsItemHovered() to emit a tooltip.
        // Here the tooltip is always emitted when 'always_on == true'.
        static i32 always_on = 0;
        RadioButton("Off", &always_on, 0);
        SameLine();
        RadioButton("Always On (Simple)", &always_on, 1);
        SameLine();
        RadioButton("Always On (Advanced)", &always_on, 2);
        if (always_on == 1)
            SetTooltip("I am following you around.");
        else if (always_on == 2 && BeginTooltip())
        {
            ProgressBar(sinf(cast(ast) ast) met) me 0.5 + 0.5, ImVec2{GetFontSize(} * 25, 0.0));
            EndTooltip();
        }

        SeparatorText("Custom");

        HelpMarker(
            "Passing ImGuiHoveredFlags_ForTooltip to IsItemHovered() is the preferred way to standardize"
            "tooltip activation details across your application. You may however decide to use custom"
            "flags for a specific tooltip instance.");

        // The following examples are passed for documentation purpose but may not be useful to most users.
        // Passing ImGuiHoveredFlags_ForTooltip to IsItemHovered() will pull ImGuiHoveredFlags flags values from
        // 'style.HoverFlagsForTooltipMouse' or 'style.HoverFlagsForTooltipNav' depending on whether mouse or keyboard/gamepad is being used.
        // With default settings, ImGuiHoveredFlags_ForTooltip is equivalent to ImGuiHoveredFlags_DelayShort + ImGuiHoveredFlags_Stationary.
        Button("Manual", sz);
        if (IsItemHovered(ImGuiHoveredFlags_ForTooltip))
            SetTooltip("I am a manually emitted tooltip.");

        Button("DelayNone", sz);
        if (IsItemHovered(ImGuiHoveredFlags_DelayNone))
            SetTooltip("I am a tooltip with no delay.");

        Button("DelayShort", sz);
        if (IsItemHovered(ImGuiHoveredFlags_DelayShort | ImGuiHoveredFlags_NoSharedDelay))
            SetTooltip("I am a tooltip with a i16 delay (%0.2 sec).", GetStyle().HoverDelayShort);

        Button("DelayLong", sz);
        if (IsItemHovered(ImGuiHoveredFlags_DelayNormal | ImGuiHoveredFlags_NoSharedDelay))
            SetTooltip("I am a tooltip with a long delay (%0.2 sec).", GetStyle().HoverDelayNormal);

        Button("Stationary", sz);
        if (IsItemHovered(ImGuiHoveredFlags_Stationary))
            SetTooltip("I am a tooltip requiring mouse to be stationary before activating.");

        // Using ImGuiHoveredFlags_ForTooltip will pull flags from 'style.HoverFlagsForTooltipMouse' or 'style.HoverFlagsForTooltipNav',
        // which default value include the ImGuiHoveredFlags_AllowWhenDisabled flag.
        BeginDisabled();
        Button("Disabled item", sz);
        if (IsItemHovered(ImGuiHoveredFlags_ForTooltip))
            SetTooltip("I am a a tooltip for a disabled item.");
        EndDisabled();

        TreePop();
    }

    // Testing ImGuiOnceUponAFrame helper.
    //static ImGuiOnceUponAFrame once;
    //for (int i = 0; i < 5; i++)
    //    if (once)
    //        ImGui::Text("This will be displayed only once.");

    IMGUI_DEMO_MARKER("Widgets/Tree Nodes");
    if (TreeNode("Tree Nodes"))
    {
        IMGUI_DEMO_MARKER("Widgets/Tree Nodes/Basic trees");
        if (TreeNode("Basic trees"))
        {
            for i32 i = 0; i < 5; i++
            {
                // Use SetNextItemOpen() so set the default state of a node to be open. We could
                // also use TreeNodeEx() with the ImGuiTreeNodeFlags_DefaultOpen flag to achieve the same thing!
                if (i == 0)
                    SetNextItemOpen(true, ImGuiCond_Once);

                // Here we use PushID() to generate a unique base ID, and then the "" used as TreeNode id won't conflict.
                // An alternative to using 'PushID() + TreeNode("", ...)' to generate a unique ID is to use 'TreeNode((void*)(intptr_t)i, ...)',
                // aka generate a dummy pointer-sized value to be hashed. The demo below uses that technique. Both are fine.
                PushID(i);
                if (TreeNode("", "Child %d", i))
                {
                    Text("blah blah");
                    SameLine();
                    if (SmallButton("button")) {}
                    TreePop();
                }
                PopID();
            }
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Tree Nodes/Advanced, with Selectable nodes");
        if (TreeNode("Advanced, with Selectable nodes"))
        {
            HelpMarker(
                "This is a more typical looking tree with selectable nodes.\n"
                "Click to select, CTRL+Click to toggle, click on arrows or f64-click to open.");
            static ImGuiTreeNodeFlags base_flags = ImGuiTreeNodeFlags_OpenOnArrow | ImGuiTreeNodeFlags_OpenOnDoubleClick | ImGuiTreeNodeFlags_SpanAvailWidth;
            static bool align_label_with_current_x_position = false;
            static bool test_drag_and_drop = false;
            CheckboxFlags("ImGuiTreeNodeFlags_OpenOnArrow",       &base_flags, ImGuiTreeNodeFlags_OpenOnArrow);
            CheckboxFlags("ImGuiTreeNodeFlags_OpenOnDoubleClick", &base_flags, ImGuiTreeNodeFlags_OpenOnDoubleClick);
            CheckboxFlags("ImGuiTreeNodeFlags_SpanAvailWidth",    &base_flags, ImGuiTreeNodeFlags_SpanAvailWidth); SameLine(); HelpMarker("Extend hit area to all available width instead of allowing more items to be laid out after the node.");
            CheckboxFlags("ImGuiTreeNodeFlags_SpanFullWidth",     &base_flags, ImGuiTreeNodeFlags_SpanFullWidth);
            CheckboxFlags("ImGuiTreeNodeFlags_SpanTextWidth",     &base_flags, ImGuiTreeNodeFlags_SpanTextWidth); SameLine(); HelpMarker("Reduce hit area to the text label and a bit of margin.");
            CheckboxFlags("ImGuiTreeNodeFlags_SpanAllColumns",    &base_flags, ImGuiTreeNodeFlags_SpanAllColumns); SameLine(); HelpMarker("For use in Tables only.");
            CheckboxFlags("ImGuiTreeNodeFlags_AllowOverlap",      &base_flags, ImGuiTreeNodeFlags_AllowOverlap);
            CheckboxFlags("ImGuiTreeNodeFlags_Framed",            &base_flags, ImGuiTreeNodeFlags_Framed); SameLine(); HelpMarker("Draw frame with background (e.g. for CollapsingHeader)");
            CheckboxFlags("ImGuiTreeNodeFlags_NavLeftJumpsBackHere", &base_flags, ImGuiTreeNodeFlags_NavLeftJumpsBackHere);
            Checkbox("Align label with current X position", &align_label_with_current_x_position);
            Checkbox("Test tree node as drag source", &test_drag_and_drop);
            Text("Hello!");
            if (align_label_with_current_x_position)
                Unindent(GetTreeNodeToLabelSpacing());

            // 'selection_mask' is dumb representation of what may be user-side selection state.
            //  You may retain selection state inside or outside your objects in whatever format you see fit.
            // 'node_clicked' is temporary storage of what node we have clicked to process selection at the end
            /// of the loop. May be a pointer to your own node type, etc.
            static i32 selection_mask = (1 << 2);
            node_clicked := -1;
            for i32 i = 0; i < 6; i++
            {
                // Disable the default "open on single-click behavior" + set Selected flag according to our selection.
                // To alter selection we use IsItemClicked() && !IsItemToggledOpen(), so clicking on an arrow doesn't alter selection.
                node_flags := base_flags;
                is_selected := (selection_mask & (1 << i)) != 0;
                if (is_selected)
                    node_flags |= ImGuiTreeNodeFlags_Selected;
                if (i < 3)
                {
                    // Items 0..2 are Tree Node
                    node_open := TreeNodeEx((rawptr)(intptr_t)i, node_flags, "Selectable Node %d", i);
                    if (IsItemClicked() && !IsItemToggledOpen())
                        node_clicked = i;
                    if (test_drag_and_drop && BeginDragDropSource())
                    {
                        SetDragDropPayload("_TREENODE", nil, 0);
                        Text("This is a drag and drop source");
                        EndDragDropSource();
                    }
                    if (i == 2 && (base_flags & ImGuiTreeNodeFlags_SpanTextWidth))
                    {
                        // Item 2 has an additional inline button to help demonstrate SpanTextWidth.
                        SameLine();
                        if (SmallButton("button")) {}
                    }
                    if (node_open)
                    {
                        BulletText("Blah blah\nBlah Blah");
                        SameLine();
                        SmallButton("Button");
                        TreePop();
                    }
                }
                else
                {
                    // Items 3..5 are Tree Leaves
                    // The only reason we use TreeNode at all is to allow selection of the leaf. Otherwise we can
                    // use BulletText() or advance the cursor by GetTreeNodeToLabelSpacing() and call Text().
                    node_flags |= ImGuiTreeNodeFlags_Leaf | ImGuiTreeNodeFlags_NoTreePushOnOpen; // ImGuiTreeNodeFlags_Bullet
                    TreeNodeEx((rawptr)(intptr_t)i, node_flags, "Selectable Leaf %d", i);
                    if (IsItemClicked() && !IsItemToggledOpen())
                        node_clicked = i;
                    if (test_drag_and_drop && BeginDragDropSource())
                    {
                        SetDragDropPayload("_TREENODE", nil, 0);
                        Text("This is a drag and drop source");
                        EndDragDropSource();
                    }
                }
            }
            if (node_clicked != -1)
            {
                // Update selection state
                // (process outside of tree loop to avoid visual inconsistencies during the clicking frame)
                if (GetIO().KeyCtrl)
                    selection_mask ^= (1 << node_clicked);          // CTRL+click to toggle
                else //if (!(selection_mask & (1 << node_clicked))) // Depending on selection behavior you want, may want to preserve selection when clicking on item that is part of the selection
                    selection_mask = (1 << node_clicked);           // Click to single-select
            }
            if (align_label_with_current_x_position)
                Indent(GetTreeNodeToLabelSpacing());
            TreePop();
        }
        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Collapsing Headers");
    if (TreeNode("Collapsing Headers"))
    {
        static bool closable_group = true;
        Checkbox("Show 2nd header", &closable_group);
        if (CollapsingHeader("Header", ImGuiTreeNodeFlags_None))
        {
            Text("IsItemHovered: %d", IsItemHovered());
            for i32 i = 0; i < 5; i++
                Text("Some content %d", i);
        }
        if (CollapsingHeader("Header with a close button", &closable_group))
        {
            Text("IsItemHovered: %d", IsItemHovered());
            for i32 i = 0; i < 5; i++
                Text("More content %d", i);
        }
        /*
        if (CollapsingHeader("Header with a bullet", ImGuiTreeNodeFlags_Bullet))
            Text("IsItemHovered: %d", IsItemHovered());
        */
        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Bullets");
    if (TreeNode("Bullets"))
    {
        BulletText("Bullet point 1");
        BulletText("Bullet point 2\nOn multiple lines");
        if (TreeNode("Tree node"))
        {
            BulletText("Another bullet point");
            TreePop();
        }
        Bullet(); Text("Bullet point 3 (two calls)");
        Bullet(); SmallButton("Button");
        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Text");
    if (TreeNode("Text"))
    {
        IMGUI_DEMO_MARKER("Widgets/Text/Colored Text");
        if (TreeNode("Colorful Text"))
        {
            // Using shortcut. You can use PushStyleColor()/PopStyleColor() for more flexibility.
            TextColored(ImVec4{1.0, 0.0, 1.0, 1.0}, "Pink");
            TextColored(ImVec4{1.0, 1.0, 0.0, 1.0}, "Yellow");
            TextDisabled("Disabled");
            SameLine(); HelpMarker("The TextDisabled color is stored in ImGuiStyle.");
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text/Word Wrapping");
        if (TreeNode("Word Wrapping"))
        {
            // Using shortcut. You can use PushTextWrapPos()/PopTextWrapPos() for more flexibility.
            TextWrapped(
                "This text should automatically wrap on the edge of the window. The current implementation "
                "for text wrapping follows simple rules suitable for English and possibly other languages.");
            Spacing();

            static f32 wrap_width = 200.0;
            SliderFloat("Wrap width", &wrap_width, -20, 600, "%.0");

            draw_list := GetWindowDrawList();
            for i32 n = 0; n < 2; n++
            {
                Text("Test paragraph %d:", n);
                pos := GetCursorScreenPos();
                marker_min := ImVec2{pos.x + wrap_width, pos.y};
                marker_max := ImVec2{pos.x + wrap_width + 10, pos.y + GetTextLineHeight(});
                PushTextWrapPos(GetCursorPos().x + wrap_width);
                if (n == 0)
                    Text("The lazy dog is a good dog. This paragraph should fit within %.0 pixels. Testing a 1 character word. The quick brown fox jumps over the lazy dog.", wrap_width);
                else
                    Text("aaaaaaaa bbbbbbbb, c cccccccc,dddddddd. d eeeeeeee   ffffffff. gggggggg!hhhhhhhh");

                // Draw actual text bounding box, following by marker of our expected limit (should not overlap!)
                draw_list.AddRect(GetItemRectMin(), GetItemRectMax(), IM_COL32(255, 255, 0, 255));
                draw_list.AddRectFilled(marker_min, marker_max, IM_COL32(255, 0, 255, 255));
                PopTextWrapPos();
            }

            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text/UTF-8 Text");
        if (TreeNode("UTF-8 Text"))
        {
            // UTF-8 test with Japanese characters
            // (Needs a suitable font? Try "Google Noto" or "Arial Unicode". See docs/FONTS.md for details.)
            // - From C++11 you can use the u8"my text" syntax to encode literal strings as UTF-8
            // - For earlier compiler, you may be able to encode your sources as UTF-8 (e.g. in Visual Studio, you
            //   can save your source files as 'UTF-8 without signature').
            // - FOR THIS DEMO FILE ONLY, BECAUSE WE WANT TO SUPPORT OLD COMPILERS, WE ARE *NOT* INCLUDING RAW UTF-8
            //   CHARACTERS IN THIS SOURCE FILE. Instead we are encoding a few strings with hexadecimal constants.
            //   Don't do this in your application! Please use u8"text in any language" in your application!
            // Note that characters values are preserved even by InputText() if the font cannot be displayed,
            // so you can safely copy & paste garbled characters into another application.
            TextWrapped(
                "CJK text will only appear if the font was loaded with the appropriate CJK character ranges. "
                "Call io.Fonts.AddFontFromFileTTF() manually to load extra character ranges. "
                "Read docs/FONTS.md for details.");
            Text("Hiragana: \xe3\x81\x8b\xe3\x81\x8d\xe3\x81\x8f\xe3\x81\x91\xe3\x81\x93 (kakikukeko)");
            Text("Kanjis: \xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e (nihongo)");
            static u8 buf[32] = "\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e";
            //static char buf[32] = u8"NIHONGO"; // <- this is how you would write it with C++11, using real kanjis
            InputText("UTF-8 input", buf, len(buf));
            TreePop();
        }
        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Images");
    if (TreeNode("Images"))
    {
        ImGuiIO& io = GetIO();
        TextWrapped(
            "Below we are displaying the font texture (which is the only texture we have access to in this demo). "
            "Use the 'ImTextureID' type as storage to pass pointers or identifier to your own texture data. "
            "Hover the texture for a zoomed view!");

        // Below we are displaying the font texture because it is the only texture we have access to inside the demo!
        // Remember that ImTextureID is just storage for whatever you want it to be. It is essentially a value that
        // will be passed to the rendering backend via the ImDrawCmd structure.
        // If you use one of the default imgui_impl_XXXX.cpp rendering backend, they all have comments at the top
        // of their respective source file to specify what they expect to be stored in ImTextureID, for example:
        // - The imgui_impl_dx11.cpp renderer expect a 'ID3D11ShaderResourceView*' pointer
        // - The imgui_impl_opengl3.cpp renderer expect a GLuint OpenGL texture identifier, etc.
        // More:
        // - If you decided that ImTextureID = MyEngineTexture*, then you can pass your MyEngineTexture* pointers
        //   to ImGui::Image(), and gather width/height through your own functions, etc.
        // - You can use ShowMetricsWindow() to inspect the draw data that are being passed to your renderer,
        //   it will help you debug issues if you are confused about it.
        // - Consider using the lower-level ImDrawList::AddImage() API, via ImGui::GetWindowDrawList()->AddImage().
        // - Read https://github.com/ocornut/imgui/blob/master/docs/FAQ.md
        // - Read https://github.com/ocornut/imgui/wiki/Image-Loading-and-Displaying-Examples
        my_tex_id := io.Fonts.TexID;
        my_tex_w := cast(ast) ast) ass.TexWidth;
        my_tex_h := cast(ast) ast) ass.TexHeight;
        {
            static bool use_text_color_for_tint = false;
            Checkbox("Use Text Color for Tint", &use_text_color_for_tint);
            Text("%.0x%.0", my_tex_w, my_tex_h);
            pos := GetCursorScreenPos();
            uv_min := ImVec2{0.0, 0.0};                 // Top-left
            uv_max := ImVec2{1.0, 1.0};                 // Lower-right
            tint_col := use_text_color_for_tint ? GetStyleColorVec4(ImGuiCol_Text) : ImVec4{1.0, 1.0, 1.0, 1.0}; // No tint
            border_col := GetStyleColorVec4(ImGuiCol_Border);
            Image(my_tex_id, ImVec2{my_tex_w, my_tex_h}, uv_min, uv_max, tint_col, border_col);
            if (BeginItemTooltip())
            {
                region_sz := 32.0;
                region_x := io.MousePos.x - pos.x - region_sz * 0.5;
                region_y := io.MousePos.y - pos.y - region_sz * 0.5;
                zoom := 4.0;
                if (region_x < 0.0) { region_x = 0.0; }
                else if (region_x > my_tex_w - region_sz) { region_x = my_tex_w - region_sz; }
                if (region_y < 0.0) { region_y = 0.0; }
                else if (region_y > my_tex_h - region_sz) { region_y = my_tex_h - region_sz; }
                Text("Min: (%.2, %.2)", region_x, region_y);
                Text("Max: (%.2, %.2)", region_x + region_sz, region_y + region_sz);
                uv0 := ImVec2{(region_x} / my_tex_w, (region_y) / my_tex_h);
                uv1 := ImVec2{(region_x + region_sz} / my_tex_w, (region_y + region_sz) / my_tex_h);
                Image(my_tex_id, ImVec2{region_sz * zoom, region_sz * zoom}, uv0, uv1, tint_col, border_col);
                EndTooltip();
            }
        }

        IMGUI_DEMO_MARKER("Widgets/Images/Textured buttons");
        TextWrapped("And now some textured buttons..");
        static i32 pressed_count = 0;
        for i32 i = 0; i < 8; i++
        {
            // UV coordinates are often (0.0f, 0.0f) and (1.0f, 1.0f) to display an entire textures.
            // Here are trying to display only a 32x32 pixels area of the texture, hence the UV computation.
            // Read about UV coordinates here: https://github.com/ocornut/imgui/wiki/Image-Loading-and-Displaying-Examples
            PushID(i);
            if (i > 0)
                PushStyleVar(ImGuiStyleVar_FramePadding, ImVec2{i - 1.0, i - 1.0});
            size := ImVec2{32.0, 32.0};                         // Size of the image we want to make visible
            uv0 := ImVec2{0.0, 0.0};                            // UV coordinates for lower-left
            uv1 := ImVec2{32.0 / my_tex_w, 32.0 / my_tex_h};    // UV coordinates for (32,32) in our texture
            bg_col := ImVec4{0.0, 0.0, 0.0, 1.0};             // Black background
            tint_col := ImVec4{1.0, 1.0, 1.0, 1.0};           // No tint
            if (ImageButton("", my_tex_id, size, uv0, uv1, bg_col, tint_col))
                pressed_count += 1;
            if (i > 0)
                PopStyleVar();
            PopID();
            SameLine();
        }
        NewLine();
        Text("Pressed %d times.", pressed_count);
        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Combo");
    if (TreeNode("Combo"))
    {
        // Combo Boxes are also called "Dropdown" in other systems
        // Expose flags as checkbox for the demo
        static ImGuiComboFlags flags = 0;
        CheckboxFlags("ImGuiComboFlags_PopupAlignLeft", &flags, ImGuiComboFlags_PopupAlignLeft);
        SameLine(); HelpMarker("Only makes a difference if the popup is larger than the combo");
        if (CheckboxFlags("ImGuiComboFlags_NoArrowButton", &flags, ImGuiComboFlags_NoArrowButton))
            flags &= ~ImGuiComboFlags_NoPreview;     // Clear incompatible flags
        if (CheckboxFlags("ImGuiComboFlags_NoPreview", &flags, ImGuiComboFlags_NoPreview))
            flags &= ~(ImGuiComboFlags_NoArrowButton | ImGuiComboFlags_WidthFitPreview); // Clear incompatible flags
        if (CheckboxFlags("ImGuiComboFlags_WidthFitPreview", &flags, ImGuiComboFlags_WidthFitPreview))
            flags &= ~ImGuiComboFlags_NoPreview;

        // Override default popup height
        if (CheckboxFlags("ImGuiComboFlags_HeightSmall", &flags, ImGuiComboFlags_HeightSmall))
            flags &= ~(ImGuiComboFlags_HeightMask_ & ~ImGuiComboFlags_HeightSmall);
        if (CheckboxFlags("ImGuiComboFlags_HeightRegular", &flags, ImGuiComboFlags_HeightRegular))
            flags &= ~(ImGuiComboFlags_HeightMask_ & ~ImGuiComboFlags_HeightRegular);
        if (CheckboxFlags("ImGuiComboFlags_HeightLargest", &flags, ImGuiComboFlags_HeightLargest))
            flags &= ~(ImGuiComboFlags_HeightMask_ & ~ImGuiComboFlags_HeightLargest);

        // Using the generic BeginCombo() API, you have full control over how to display the combo contents.
        // (your selection data could be an index, a pointer to the object, an id for the object, a flag intrusively
        // stored in the object itself, etc.)
        const u8* items[] = { "AAAA", "BBBB", "CCCC", "DDDD", "EEEE", "FFFF", "GGGG", "HHHH", "IIII", "JJJJ", "KKKK", "LLLLLLL", "MMMM", "OOOOOOO" };
        static i32 item_selected_idx = 0; // Here we store our selection data as an index.

        // Pass in the preview value visible before opening the combo (it could technically be different contents or not pulled from items[])
        combo_preview_value := items[item_selected_idx];

        if (BeginCombo("combo 1", combo_preview_value, flags))
        {
            for i32 n = 0; n < len(items); n++
            {
                is_selected := (item_selected_idx == n);
                if (Selectable(items[n], is_selected))
                    item_selected_idx = n;

                // Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
                if (is_selected)
                    SetItemDefaultFocus();
            }
            EndCombo();
        }

        Spacing();
        SeparatorText("One-liner variants");
        HelpMarker("Flags above don't apply to this section.");

        // Simplified one-liner Combo() API, using values packed in a single constant string
        // This is a convenience for when the selection set is small and known at compile-time.
        static i32 item_current_2 = 0;
        Combo("combo 2 (one-liner)", &item_current_2, "aaaa0x00bbbb0x00cccc0x00dddd0x00eeee0x000x00");

        // Simplified one-liner Combo() using an array of const char*
        // This is not very useful (may obsolete): prefer using BeginCombo()/EndCombo() for full control.
        static i32 item_current_3 = -1; // If the selection isn't within 0..count, Combo won't display a preview
        Combo("combo 3 (array)", &item_current_3, items, len(items));

        // Simplified one-liner Combo() using an accessor function
        static i32 item_current_4 = 0;
        Combo("combo 4 (function)", &item_current_4, [](rawptr data, i32 n) { return ((const u8**)data)[n]; }, items, len(items));

        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/List Boxes");
    if (TreeNode("List boxes"))
    {
        // BeginListBox() is essentially a thin wrapper to using BeginChild()/EndChild()
        // using the ImGuiChildFlags_FrameStyle flag for stylistic changes + displaying a label.
        // You may be tempted to simply use BeginChild() directly. However note that BeginChild() requires EndChild()
        // to always be called (inconsistent with BeginListBox()/EndListBox()).

        // Using the generic BeginListBox() API, you have full control over how to display the combo contents.
        // (your selection data could be an index, a pointer to the object, an id for the object, a flag intrusively
        // stored in the object itself, etc.)
        const u8* items[] = { "AAAA", "BBBB", "CCCC", "DDDD", "EEEE", "FFFF", "GGGG", "HHHH", "IIII", "JJJJ", "KKKK", "LLLLLLL", "MMMM", "OOOOOOO" };
        static i32 item_selected_idx = 0; // Here we store our selected data as an index.

        static bool item_highlight = false;
        item_highlighted_idx := -1; // Here we store our highlighted data as an index.
        Checkbox("Highlight hovered item in second listbox", &item_highlight);

        if (BeginListBox("listbox 1"))
        {
            for i32 n = 0; n < len(items); n++
            {
                is_selected := (item_selected_idx == n);
                if (Selectable(items[n], is_selected))
                    item_selected_idx = n;

                if (item_highlight && IsItemHovered())
                    item_highlighted_idx = n;

                // Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
                if (is_selected)
                    SetItemDefaultFocus();
            }
            EndListBox();
        }
        SameLine(); HelpMarker("Here we are sharing selection state between both boxes.");

        // Custom size: use all width, 5 items tall
        Text("Full-width:");
        if (BeginListBox("##listbox 2", ImVec2{-math.F32_MIN, 5 * GetTextLineHeightWithSpacing(})))
        {
            for i32 n = 0; n < len(items); n++
            {
                is_selected := (item_selected_idx == n);
                flags := (item_highlighted_idx == n) ? ImGuiSelectableFlags_Highlight : 0;
                if (Selectable(items[n], is_selected, flags))
                    item_selected_idx = n;

                // Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
                if (is_selected)
                    SetItemDefaultFocus();
            }
            EndListBox();
        }

        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Selectables");
    //ImGui::SetNextItemOpen(true, ImGuiCond_Once);
    if (TreeNode("Selectables"))
    {
        // Selectable() has 2 overloads:
        // - The one taking "bool selected" as a read-only selection information.
        //   When Selectable() has been clicked it returns true and you can alter selection state accordingly.
        // - The one taking "bool* p_selected" as a read-write selection information (convenient in some cases)
        // The earlier is more flexible, as in real application your selection may be stored in many different ways
        // and not necessarily inside a bool value (e.g. in flags within objects, as an external list, etc).
        IMGUI_DEMO_MARKER("Widgets/Selectables/Basic");
        if (TreeNode("Basic"))
        {
            static bool selection[5] = { false, true, false, false };
            Selectable("1. I am selectable", &selection[0]);
            Selectable("2. I am selectable", &selection[1]);
            Selectable("3. I am selectable", &selection[2]);
            if (Selectable("4. I am f64 clickable", selection[3], ImGuiSelectableFlags_AllowDoubleClick))
                if (IsMouseDoubleClicked(0))
                    selection[3] = !selection[3];
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Selectables/Rendering more items on the same line");
        if (TreeNode("Rendering more items on the same line"))
        {
            // (1) Using SetNextItemAllowOverlap()
            // (2) Using the Selectable() override that takes "bool* p_selected" parameter, the bool value is toggled automatically.
            static bool selected[3] = { false, false, false };
            SetNextItemAllowOverlap(); Selectable("main.c",    &selected[0]); SameLine(); SmallButton("Link 1");
            SetNextItemAllowOverlap(); Selectable("Hello.cpp", &selected[1]); SameLine(); SmallButton("Link 2");
            SetNextItemAllowOverlap(); Selectable("Hello.h",   &selected[2]); SameLine(); SmallButton("Link 3");
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Selectables/In Tables");
        if (TreeNode("In Tables"))
        {
            static bool selected[10] = {};

            if (BeginTable("split1", 3, ImGuiTableFlags_Resizable | ImGuiTableFlags_NoSavedSettings | ImGuiTableFlags_Borders))
            {
                for i32 i = 0; i < 10; i++
                {
                    label : [32]u8
                    sprintf(label, "Item %d", i);
                    TableNextColumn();
                    Selectable(label, &selected[i]); // FIXME-TABLE: Selection overlap
                }
                EndTable();
            }
            Spacing();
            if (BeginTable("split2", 3, ImGuiTableFlags_Resizable | ImGuiTableFlags_NoSavedSettings | ImGuiTableFlags_Borders))
            {
                for i32 i = 0; i < 10; i++
                {
                    label : [32]u8
                    sprintf(label, "Item %d", i);
                    TableNextRow();
                    TableNextColumn();
                    Selectable(label, &selected[i], ImGuiSelectableFlags_SpanAllColumns);
                    TableNextColumn();
                    Text("Some other contents");
                    TableNextColumn();
                    Text("123456");
                }
                EndTable();
            }
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Selectables/Grid");
        if (TreeNode("Grid"))
        {
            static u8 selected[4][4] = { { 1, 0, 0, 0 }, { 0, 1, 0, 0 }, { 0, 0, 1, 0 }, { 0, 0, 0, 1 } };

            // Add in a bit of silly fun...
            time := cast(ast) ast) met) 
            winning_state := memchr(selected, 0, size_of(selected)) == nil; // If all cells are selected...
            if (winning_state)
                PushStyleVar(ImGuiStyleVar_SelectableTextAlign, ImVec2{0.5 + 0.5 * cosf(time * 2.0}, 0.5 + 0.5 * sinf(time * 3.0)));

            for i32 y = 0; y < 4; y++
                for i32 x = 0; x < 4; x++
                {
                    if (x > 0)
                        SameLine();
                    PushID(y * 4 + x);
                    if (Selectable("Sailor", selected[y][x] != 0, 0, ImVec2{50, 50}))
                    {
                        // Toggle clicked cell + toggle neighbors
                        selected[y][x] ^= 1;
                        if (x > 0) { selected[y][x - 1] ^= 1; }
                        if (x < 3) { selected[y][x + 1] ^= 1; }
                        if (y > 0) { selected[y - 1][x] ^= 1; }
                        if (y < 3) { selected[y + 1][x] ^= 1; }
                    }
                    PopID();
                }

            if (winning_state)
                PopStyleVar();
            TreePop();
        }
        IMGUI_DEMO_MARKER("Widgets/Selectables/Alignment");
        if (TreeNode("Alignment"))
        {
            HelpMarker(
                "By default, Selectables uses style.SelectableTextAlign but it can be overridden on a per-item "
                "basis using PushStyleVar(). You'll probably want to always keep your default situation to "
                "left-align otherwise it becomes difficult to layout multiple items on a same line");
            static bool selected[3 * 3] = { true, false, true, false, true, false, true, false, true };
            for i32 y = 0; y < 3; y++
            {
                for i32 x = 0; x < 3; x++
                {
                    alignment := ImVec2{(f32}x / 2.0, cast(ast) ast) a0);
                    name : [32]u8
                    sprintf(name, "(%.1,%.1)", alignment.x, alignment.y);
                    if (x > 0) SameLine();
                    PushStyleVar(ImGuiStyleVar_SelectableTextAlign, alignment);
                    Selectable(name, &selected[3 * y + x], ImGuiSelectableFlags_None, ImVec2{80, 80});
                    PopStyleVar();
                }
            }
            TreePop();
        }
        TreePop();
    }

    ShowDemoWindowMultiSelect(demo_data);

    // To wire InputText() with std::string or any other custom string type,
    // see the "Text Input > Resize Callback" section of this demo, and the misc/cpp/imgui_stdlib.h file.
    IMGUI_DEMO_MARKER("Widgets/Text Input");
    if (TreeNode("Text Input"))
    {
        IMGUI_DEMO_MARKER("Widgets/Text Input/Multi-line Text Input");
        if (TreeNode("Multi-line Text Input"))
        {
            // Note: we are using a fixed-sized buffer for simplicity here. See ImGuiInputTextFlags_CallbackResize
            // and the code in misc/cpp/imgui_stdlib.h for how to setup InputText() for dynamically resizing strings.
            static u8 text[1024 * 16] =
                "/*\n"
                " The Pentium F00F bug, shorthand for F0 0F C7 C8,\n"
                " the hexadecimal encoding of one offending instruction,\n"
                " more formally, the invalid operand with locked CMPXCHG8B\n"
                " instruction bug, is a design flaw in the majority of\n"
                " Intel Pentium, Pentium MMX, and Pentium OverDrive\n"
                " processors (all in the P5 microarchitecture).\n"
                "*/\n\n"
                "label:\n"
                "\tlock cmpxchg8b eax\n";

            static ImGuiInputTextFlags flags = ImGuiInputTextFlags_AllowTabInput;
            HelpMarker("You can use the ImGuiInputTextFlags_CallbackResize facility if you need to wire InputTextMultiline() to a dynamic string type. See misc/cpp/imgui_stdlib.h for an example. (This is not demonstrated in imgui_demo.cpp because we don't want to include <string> in here)");
            CheckboxFlags("ImGuiInputTextFlags_ReadOnly", &flags, ImGuiInputTextFlags_ReadOnly);
            CheckboxFlags("ImGuiInputTextFlags_AllowTabInput", &flags, ImGuiInputTextFlags_AllowTabInput);
            SameLine(); HelpMarker("When _AllowTabInput is set, passing through the widget with Tabbing doesn't automatically activate it, in order to also cycling through subsequent widgets.");
            CheckboxFlags("ImGuiInputTextFlags_CtrlEnterForNewLine", &flags, ImGuiInputTextFlags_CtrlEnterForNewLine);
            InputTextMultiline("##source", text, len(text), ImVec2{-math.F32_MIN, GetTextLineHeight(} * 16), flags);
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text Input/Filtered Text Input");
        if (TreeNode("Filtered Text Input"))
        {
            TextFilters :: struct
            {
                // Modify character input by altering 'data->Eventchar' (ImGuiInputTextFlags_CallbackCharFilter callback)
                static i32 FilterCasingSwap(ImGuiInputTextCallbackData* data)
                {
                    if (data.EventChar >= 'a' && data.EventChar <= 'z')       { data.EventChar -= 'a' - 'A'; } // Lowercase becomes uppercase
                    else if (data.EventChar >= 'A' && data.EventChar <= 'Z')  { data.EventChar += 'a' - 'A'; } // Uppercase becomes lowercase
                    return 0;
                }

                // Return 0 (pass) if the character is 'i' or 'm' or 'g' or 'u' or 'i', otherwise return 1 (filter out)
                static i32 FilterImGuiLetters(ImGuiInputTextCallbackData* data)
                {
                    if (data.EventChar < 256 && strchr("imgui", cast(as) (as) (as)tChar))
                        return 0;
                    return 1;
                }
            };

            static u8 buf1[32] = ""; InputText("default",     buf1, 32);
            static u8 buf2[32] = ""; InputText("decimal",     buf2, 32, ImGuiInputTextFlags_CharsDecimal);
            static u8 buf3[32] = ""; InputText("hexadecimal", buf3, 32, ImGuiInputTextFlags_CharsHexadecimal | ImGuiInputTextFlags_CharsUppercase);
            static u8 buf4[32] = ""; InputText("uppercase",   buf4, 32, ImGuiInputTextFlags_CharsUppercase);
            static u8 buf5[32] = ""; InputText("no blank",    buf5, 32, ImGuiInputTextFlags_CharsNoBlank);
            static u8 buf6[32] = ""; InputText("casing swap", buf6, 32, ImGuiInputTextFlags_CallbackCharFilter, TextFilters::FilterCasingSwap); // Use CharFilter callback to replace characters.
            static u8 buf7[32] = ""; InputText("\"imgui\"",   buf7, 32, ImGuiInputTextFlags_CallbackCharFilter, TextFilters::FilterImGuiLetters); // Use CharFilter callback to disable some characters.
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text Input/Password input");
        if (TreeNode("Password Input"))
        {
            static u8 password[64] = "password123";
            InputText("password", password, len(password), ImGuiInputTextFlags_Password);
            SameLine(); HelpMarker("Display all characters as '*'.\nDisable clipboard cut and copy.\nDisable logging.\n");
            InputTextWithHint("password (w/ hint)", "<password>", password, len(password), ImGuiInputTextFlags_Password);
            InputText("password (clear)", password, len(password));
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text Input/Completion, History, Edit Callbacks");
        if (TreeNode("Completion, History, Edit Callbacks"))
        {
            Funcs :: struct
            {
                static i32 MyCallback(ImGuiInputTextCallbackData* data)
                {
                    if (data.EventFlag == ImGuiInputTextFlags_CallbackCompletion)
                    {
                        data.InsertChars(data.CursorPos, "..");
                    }
                    else if (data.EventFlag == ImGuiInputTextFlags_CallbackHistory)
                    {
                        if (data.EventKey == ImGuiKey_UpArrow)
                        {
                            data.DeleteChars(0, data.BufTextLen);
                            data.InsertChars(0, "Pressed Up!");
                            data.SelectAll();
                        }
                        else if (data.EventKey == ImGuiKey_DownArrow)
                        {
                            data.DeleteChars(0, data.BufTextLen);
                            data.InsertChars(0, "Pressed Down!");
                            data.SelectAll();
                        }
                    }
                    else if (data.EventFlag == ImGuiInputTextFlags_CallbackEdit)
                    {
                        // Toggle casing of first character
                        c := data.Buf[0];
                        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) data.Buf[0] ^= 32;
                        data.BufDirty = true;

                        // Increment a counter
                        p_int := (i32*)data.UserData;
                        p_int^ = *p_int + 1;
                    }
                    return 0;
                }
            };
            static u8 buf1[64];
            InputText("Completion", buf1, 64, ImGuiInputTextFlags_CallbackCompletion, Funcs::MyCallback);
            SameLine(); HelpMarker(
                "Here we append \"..\" each time Tab is pressed. "
                "See 'Examples>Console' for a more meaningful demonstration of using this callback.");

            static u8 buf2[64];
            InputText("History", buf2, 64, ImGuiInputTextFlags_CallbackHistory, Funcs::MyCallback);
            SameLine(); HelpMarker(
                "Here we replace and select text each time Up/Down are pressed. "
                "See 'Examples>Console' for a more meaningful demonstration of using this callback.");

            static u8 buf3[64];
            static i32 edit_count = 0;
            InputText("Edit", buf3, 64, ImGuiInputTextFlags_CallbackEdit, Funcs::MyCallback, (rawptr)&edit_count);
            SameLine(); HelpMarker(
                "Here we toggle the casing of the first character on every edit + count edits.");
            SameLine(); Text("(%d)", edit_count);

            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text Input/Resize Callback");
        if (TreeNode("Resize Callback"))
        {
            // To wire InputText() with std::string or any other custom string type,
            // you can use the ImGuiInputTextFlags_CallbackResize flag + create a custom ImGui::InputText() wrapper
            // using your preferred type. See misc/cpp/imgui_stdlib.h for an implementation of this using std::string.
            HelpMarker(
                "Using ImGuiInputTextFlags_CallbackResize to wire your custom string type to InputText().\n\n"
                "See misc/cpp/imgui_stdlib.h for an implementation of this for std::string.");
            Funcs :: struct
            {
                static i32 MyResizeCallback(ImGuiInputTextCallbackData* data)
                {
                    if (data.EventFlag == ImGuiInputTextFlags_CallbackResize)
                    {
                        ImVector<u8>* my_str = (ImVector<u8>*)data.UserData;
                        assert(my_str.begin() == data.Buf);
                        my_str.resize(data.BufSize); // NB: On resizing calls, generally data->BufSize == data->BufTextLen + 1
                        data.Buf = my_str.begin();
                    }
                    return 0;
                }

                // Note: Because ImGui:: is a namespace you would typically add your own function into the namespace.
                // For example, you code may declare a function 'ImGui::InputText(const char* label, MyString* my_str)'
                static bool MyInputTextMultiline(const u8* label, ImVector<u8>* my_str, const ImVec2& size = ImVec2{0, 0}, ImGuiInputTextFlags flags = 0)
                {
                    assert((flags & ImGuiInputTextFlags_CallbackResize) == 0);
                    return InputTextMultiline(label, my_str.begin(), cast(ast) ast) rst) r(), size, flags | ImGuiInputTextFlags_CallbackResize, Funcs::MyResizeCallback, (rawptr)my_str);
                }
            };

            // For this demo we are using ImVector as a string container.
            // Note that because we need to store a terminating zero character, our size/capacity are 1 more
            // than usually reported by a typical string class.
            static ImVector<u8> my_str;
            if (my_str.empty())
                my_str.push_back(0);
            Funcs::MyInputTextMultiline("##MyStr", &my_str, ImVec2{-math.F32_MIN, GetTextLineHeight(} * 16));
            Text("Data: %p\nSize: %d\nCapacity: %d", (rawptr)my_str.begin(), my_str.size(), my_str.capacity());
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text Input/Eliding, Alignment");
        if (TreeNode("Eliding, Alignment"))
        {
            static u8 buf1[128] = "/path/to/some/folder/with/long/filename.cpp";
            static ImGuiInputTextFlags flags = ImGuiInputTextFlags_ElideLeft;
            CheckboxFlags("ImGuiInputTextFlags_ElideLeft", &flags, ImGuiInputTextFlags_ElideLeft);
            InputText("Path", buf1, len(buf1), flags);
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text Input/Miscellaneous");
        if (TreeNode("Miscellaneous"))
        {
            static u8 buf1[16];
            static ImGuiInputTextFlags flags = ImGuiInputTextFlags_EscapeClearsAll;
            CheckboxFlags("ImGuiInputTextFlags_EscapeClearsAll", &flags, ImGuiInputTextFlags_EscapeClearsAll);
            CheckboxFlags("ImGuiInputTextFlags_ReadOnly", &flags, ImGuiInputTextFlags_ReadOnly);
            CheckboxFlags("ImGuiInputTextFlags_NoUndoRedo", &flags, ImGuiInputTextFlags_NoUndoRedo);
            InputText("Hello", buf1, len(buf1), flags);
            TreePop();
        }

        TreePop();
    }

    // Tabs
    IMGUI_DEMO_MARKER("Widgets/Tabs");
    if (TreeNode("Tabs"))
    {
        IMGUI_DEMO_MARKER("Widgets/Tabs/Basic");
        if (TreeNode("Basic"))
        {
            tab_bar_flags := ImGuiTabBarFlags_None;
            if (BeginTabBar("MyTabBar", tab_bar_flags))
            {
                if (BeginTabItem("Avocado"))
                {
                    Text("This is the Avocado tab!\nblah blah blah blah blah");
                    EndTabItem();
                }
                if (BeginTabItem("Broccoli"))
                {
                    Text("This is the Broccoli tab!\nblah blah blah blah blah");
                    EndTabItem();
                }
                if (BeginTabItem("Cucumber"))
                {
                    Text("This is the Cucumber tab!\nblah blah blah blah blah");
                    EndTabItem();
                }
                EndTabBar();
            }
            Separator();
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Tabs/Advanced & Close Button");
        if (TreeNode("Advanced & Close Button"))
        {
            // Expose a couple of the available flags. In most cases you may just call BeginTabBar() with no flags (0).
            static ImGuiTabBarFlags tab_bar_flags = ImGuiTabBarFlags_Reorderable;
            CheckboxFlags("ImGuiTabBarFlags_Reorderable", &tab_bar_flags, ImGuiTabBarFlags_Reorderable);
            CheckboxFlags("ImGuiTabBarFlags_AutoSelectNewTabs", &tab_bar_flags, ImGuiTabBarFlags_AutoSelectNewTabs);
            CheckboxFlags("ImGuiTabBarFlags_TabListPopupButton", &tab_bar_flags, ImGuiTabBarFlags_TabListPopupButton);
            CheckboxFlags("ImGuiTabBarFlags_NoCloseWithMiddleMouseButton", &tab_bar_flags, ImGuiTabBarFlags_NoCloseWithMiddleMouseButton);
            CheckboxFlags("ImGuiTabBarFlags_DrawSelectedOverline", &tab_bar_flags, ImGuiTabBarFlags_DrawSelectedOverline);
            if ((tab_bar_flags & ImGuiTabBarFlags_FittingPolicyMask_) == 0)
                tab_bar_flags |= ImGuiTabBarFlags_FittingPolicyDefault_;
            if (CheckboxFlags("ImGuiTabBarFlags_FittingPolicyResizeDown", &tab_bar_flags, ImGuiTabBarFlags_FittingPolicyResizeDown))
                tab_bar_flags &= ~(ImGuiTabBarFlags_FittingPolicyMask_ ^ ImGuiTabBarFlags_FittingPolicyResizeDown);
            if (CheckboxFlags("ImGuiTabBarFlags_FittingPolicyScroll", &tab_bar_flags, ImGuiTabBarFlags_FittingPolicyScroll))
                tab_bar_flags &= ~(ImGuiTabBarFlags_FittingPolicyMask_ ^ ImGuiTabBarFlags_FittingPolicyScroll);

            // Tab Bar
            AlignTextToFramePadding();
            Text("Opened:");
            const u8* names[4] = { "Artichoke", "Beetroot", "Celery", "Daikon" };
            static bool opened[4] = { true, true, true, true }; // Persistent user state
            for i32 n = 0; n < len(opened); n++
            {
                SameLine();
                Checkbox(names[n], &opened[n]);
            }

            // Passing a bool* to BeginTabItem() is similar to passing one to Begin():
            // the underlying bool will be set to false when the tab is closed.
            if (BeginTabBar("MyTabBar", tab_bar_flags))
            {
                for i32 n = 0; n < len(opened); n++
                    if (opened[n] && BeginTabItem(names[n], &opened[n], ImGuiTabItemFlags_None))
                    {
                        Text("This is the %s tab!", names[n]);
                        if (n & 1)
                            Text("I am an odd tab.");
                        EndTabItem();
                    }
                EndTabBar();
            }
            Separator();
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Tabs/TabItemButton & Leading-Trailing flags");
        if (TreeNode("TabItemButton & Leading/Trailing flags"))
        {
            static ImVector<i32> active_tabs;
            static i32 next_tab_id = 0;
            if (next_tab_id == 0) // Initialize with some default tabs
                for i32 i = 0; i < 3; i++
                    active_tabs.push_back(next_tab_id++);

            // TabItemButton() and Leading/Trailing flags are distinct features which we will demo together.
            // (It is possible to submit regular tabs with Leading/Trailing flags, or TabItemButton tabs without Leading/Trailing flags...
            // but they tend to make more sense together)
            static bool show_leading_button = true;
            static bool show_trailing_button = true;
            Checkbox("Show Leading TabItemButton()", &show_leading_button);
            Checkbox("Show Trailing TabItemButton()", &show_trailing_button);

            // Expose some other flags which are useful to showcase how they interact with Leading/Trailing tabs
            static ImGuiTabBarFlags tab_bar_flags = ImGuiTabBarFlags_AutoSelectNewTabs | ImGuiTabBarFlags_Reorderable | ImGuiTabBarFlags_FittingPolicyResizeDown;
            CheckboxFlags("ImGuiTabBarFlags_TabListPopupButton", &tab_bar_flags, ImGuiTabBarFlags_TabListPopupButton);
            if (CheckboxFlags("ImGuiTabBarFlags_FittingPolicyResizeDown", &tab_bar_flags, ImGuiTabBarFlags_FittingPolicyResizeDown))
                tab_bar_flags &= ~(ImGuiTabBarFlags_FittingPolicyMask_ ^ ImGuiTabBarFlags_FittingPolicyResizeDown);
            if (CheckboxFlags("ImGuiTabBarFlags_FittingPolicyScroll", &tab_bar_flags, ImGuiTabBarFlags_FittingPolicyScroll))
                tab_bar_flags &= ~(ImGuiTabBarFlags_FittingPolicyMask_ ^ ImGuiTabBarFlags_FittingPolicyScroll);

            if (BeginTabBar("MyTabBar", tab_bar_flags))
            {
                // Demo a Leading TabItemButton(): click the "?" button to open a menu
                if (show_leading_button)
                    if (TabItemButton("?", ImGuiTabItemFlags_Leading | ImGuiTabItemFlags_NoTooltip))
                        OpenPopup("MyHelpMenu");
                if (BeginPopup("MyHelpMenu"))
                {
                    Selectable("Hello!");
                    EndPopup();
                }

                // Demo Trailing Tabs: click the "+" button to add a new tab.
                // (In your app you may want to use a font icon instead of the "+")
                // We submit it before the regular tabs, but thanks to the ImGuiTabItemFlags_Trailing flag it will always appear at the end.
                if (show_trailing_button)
                    if (TabItemButton("+", ImGuiTabItemFlags_Trailing | ImGuiTabItemFlags_NoTooltip))
                        active_tabs.push_back(next_tab_id++); // Add new tab

                // Submit our regular tabs
                for i32 n = 0; n < active_tabs.Size; 
                {
                    open := true;
                    name : [16]u8
                    snprintf(name, len(name), "%04d", active_tabs[n]);
                    if (BeginTabItem(name, &open, ImGuiTabItemFlags_None))
                    {
                        Text("This is the %s tab!", name);
                        EndTabItem();
                    }

                    if (!open)
                        active_tabs.erase(active_tabs.Data + n);
                    else
                        n += 1;
                }

                EndTabBar();
            }
            Separator();
            TreePop();
        }
        TreePop();
    }

    // Plot/Graph widgets are not very good.
    // Consider using a third-party library such as ImPlot: https://github.com/epezent/implot
    // (see others https://github.com/ocornut/imgui/wiki/Useful-Extensions)
    IMGUI_DEMO_MARKER("Widgets/Plotting");
    if (TreeNode("Plotting"))
    {
        static bool animate = true;
        Checkbox("Animate", &animate);

        // Plot as lines and plot as histogram
        static f32 arr[] = { 0.6, 0.1, 1.0, 0.5, 0.92, 0.1, 0.2 };
        PlotLines("Frame Times", arr, len(arr));
        PlotHistogram("Histogram", arr, len(arr), 0, nil, 0.0, 1.0, ImVec2{0, 80.0});
        //ImGui::SameLine(); HelpMarker("Consider using ImPlot instead!");

        // Fill an array of contiguous float values to plot
        // Tip: If your float aren't contiguous but part of a structure, you can pass a pointer to your first float
        // and the sizeof() of your structure in the "stride" parameter.
        static f32 values[90] = {};
        static i32 values_offset = 0;
        static f64 refresh_time = 0.0;
        if (!animate || refresh_time == 0.0)
            refresh_time = GetTime();
        for refresh_time < GetTime() // Create data at fixed 60 Hz rate for the demo
        {
            static f32 phase = 0.0;
            values[values_offset] = cosf(phase);
            values_offset = (values_offset + 1) % len(values);
            phase += 0.10 * values_offset;
            refresh_time += 1.0 / 60.0;
        }

        // Plots can display overlay texts
        // (in this example, we will display an average value)
        {
            average := 0.0;
            for i32 n = 0; n < len(values); n++
                average += values[n];
            average /= cast(ast) ast) astes);
            overlay : [32]u8
            sprintf(overlay, "avg %f", average);
            PlotLines("Lines", values, len(values), values_offset, overlay, -1.0, 1.0, ImVec2{0, 80.0});
        }

        // Use functions to generate output
        // FIXME: This is actually VERY awkward because current plot API only pass in indices.
        // We probably want an API passing floats and user provide sample rate/count.
        Funcs :: struct
        {
            static f32 Sin(rawptr, i32 i) { return sinf(i * 0.1); }
            static f32 Saw(rawptr, i32 i) { return (i & 1) ? 1.0 : -1.0; }
        };
        static i32 func_type = 0, display_count = 70;
        SeparatorText("Functions");
        SetNextItemWidth(GetFontSize() * 8);
        Combo("func", &func_type, "Sin0x00Saw0x00");
        SameLine();
        SliderInt("Sample count", &display_count, 1, 400);
        f32 (*func)(rawptr, i32) = (func_type == 0) ? Funcs::Sin : Funcs::Saw;
        PlotLines("Lines##2", func, nil, display_count, 0, nil, -1.0, 1.0, ImVec2{0, 80});
        PlotHistogram("Histogram##2", func, nil, display_count, 0, nil, -1.0, 1.0, ImVec2{0, 80});
        Separator();

        Text("Need better plotting and graphing? Consider using ImPlot:");
        TextLinkOpenURL("https://github.com/epezent/implot");
        Separator();

        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Progress Bars");
    if (TreeNode("Progress Bars"))
    {
        // Animate a simple progress bar
        static f32 progress = 0.0, progress_dir = 1.0;
        progress += progress_dir * 0.4 * GetIO().DeltaTime;
        if (progress >= +1.1) { progress = +1.1; progress_dir *= -1.0; }
        if (progress <= -0.1) { progress = -0.1; progress_dir *= -1.0; }

        // Typically we would use ImVec2(-1.0f,0.0f) or ImVec2(-FLT_MIN,0.0f) to use all available width,
        // or ImVec2(width,0.0f) for a specified width. ImVec2(0.0f,0.0f) uses ItemWidth.
        ProgressBar(progress, ImVec2{0.0, 0.0});
        SameLine(0.0, GetStyle().ItemInnerSpacing.x);
        Text("Progress Bar");

        progress_saturated := IM_CLAMP(progress, 0.0, 1.0);
        buf : [32]u8
        sprintf(buf, "%d/%d", (i32)(progress_saturated * 1753), 1753);
        ProgressBar(progress, ImVec2{0.f, 0.f}, buf);

        // Pass an animated negative value, e.g. -1.0f * (float)ImGui::GetTime() is the recommended value.
        // Adjust the factor if you want to adjust the animation speed.
        ProgressBar(-1.0 * cast(ast) ast) met) memVec2{0.0, 0.0}, "Searching..");
        SameLine(0.0, GetStyle().ItemInnerSpacing.x);
        Text("Indeterminate");

        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Color");
    if (TreeNode("Color/Picker Widgets"))
    {
        static ImVec4 color = ImVec4{114.0 / 255.0, 144.0 / 255.0, 154.0 / 255.0, 200.0 / 255.0};

        static bool alpha_preview = true;
        static bool alpha_half_preview = false;
        static bool drag_and_drop = true;
        static bool options_menu = true;
        static bool hdr = false;
        SeparatorText("Options");
        Checkbox("With Alpha Preview", &alpha_preview);
        Checkbox("With Half Alpha Preview", &alpha_half_preview);
        Checkbox("With Drag and Drop", &drag_and_drop);
        Checkbox("With Options Menu", &options_menu); SameLine(); HelpMarker("Right-click on the individual color widget to show options.");
        Checkbox("With HDR", &hdr); SameLine(); HelpMarker("Currently all this does is to lift the 0..1 limits on dragging widgets.");
        misc_flags := (hdr ? ImGuiColorEditFlags_HDR : 0) | (drag_and_drop ? 0 : ImGuiColorEditFlags_NoDragDrop) | (alpha_half_preview ? ImGuiColorEditFlags_AlphaPreviewHalf : (alpha_preview ? ImGuiColorEditFlags_AlphaPreview : 0)) | (options_menu ? 0 : ImGuiColorEditFlags_NoOptions);

        IMGUI_DEMO_MARKER("Widgets/Color/ColorEdit");
        SeparatorText("Inline color editor");
        Text("Color widget:");
        SameLine(); HelpMarker(
            "Click on the color square to open a color picker.\n"
            "CTRL+click on individual component to input value.\n");
        ColorEdit3("MyColor##1", (f32*)&color, misc_flags);

        IMGUI_DEMO_MARKER("Widgets/Color/ColorEdit (HSV, with Alpha)");
        Text("Color widget HSV with Alpha:");
        ColorEdit4("MyColor##2", (f32*)&color, ImGuiColorEditFlags_DisplayHSV | misc_flags);

        IMGUI_DEMO_MARKER("Widgets/Color/ColorEdit (f32 display)");
        Text("Color widget with Float Display:");
        ColorEdit4("MyColor##2f", (f32*)&color, ImGuiColorEditFlags_Float | misc_flags);

        IMGUI_DEMO_MARKER("Widgets/Color/ColorButton (with Picker)");
        Text("Color button with Picker:");
        SameLine(); HelpMarker(
            "With the ImGuiColorEditFlags_NoInputs flag you can hide all the slider/text inputs.\n"
            "With the ImGuiColorEditFlags_NoLabel flag you can pass a non-empty label which will only "
            "be used for the tooltip and picker popup.");
        ColorEdit4("MyColor##3", (f32*)&color, ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_NoLabel | misc_flags);

        IMGUI_DEMO_MARKER("Widgets/Color/ColorButton (with custom Picker popup)");
        Text("Color button with Custom Picker Popup:");

        // Generate a default palette. The palette will persist and can be edited.
        static bool saved_palette_init = true;
        static ImVec4 saved_palette[32] = {};
        if (saved_palette_init)
        {
            for i32 n = 0; n < len(saved_palette); n++
            {
                ColorConvertHSVtoRGB(n / 31.0, 0.8, 0.8,
                    saved_palette[n].x, saved_palette[n].y, saved_palette[n].z);
                saved_palette[n].w = 1.0; // Alpha
            }
            saved_palette_init = false;
        }

        static ImVec4 backup_color;
        open_popup := ColorButton("MyColor##3b", color, misc_flags);
        SameLine(0, GetStyle().ItemInnerSpacing.x);
        open_popup |= Button("Palette");
        if (open_popup)
        {
            OpenPopup("mypicker");
            backup_color = color;
        }
        if (BeginPopup("mypicker"))
        {
            Text("MY CUSTOM COLOR PICKER WITH AN AMAZING PALETTE!");
            Separator();
            ColorPicker4("##picker", (f32*)&color, misc_flags | ImGuiColorEditFlags_NoSidePreview | ImGuiColorEditFlags_NoSmallPreview);
            SameLine();

            BeginGroup(); // Lock X position
            Text("Current");
            ColorButton("##current", color, ImGuiColorEditFlags_NoPicker | ImGuiColorEditFlags_AlphaPreviewHalf, ImVec2{60, 40});
            Text("Previous");
            if (ColorButton("##previous", backup_color, ImGuiColorEditFlags_NoPicker | ImGuiColorEditFlags_AlphaPreviewHalf, ImVec2{60, 40}))
                color = backup_color;
            Separator();
            Text("Palette");
            for i32 n = 0; n < len(saved_palette); n++
            {
                PushID(n);
                if ((n % 8) != 0)
                    SameLine(0.0, GetStyle().ItemSpacing.y);

                palette_button_flags := ImGuiColorEditFlags_NoAlpha | ImGuiColorEditFlags_NoPicker | ImGuiColorEditFlags_NoTooltip;
                if (ColorButton("##palette", saved_palette[n], palette_button_flags, ImVec2{20, 20}))
                    color = ImVec4{saved_palette[n].x, saved_palette[n].y, saved_palette[n].z, color.w}; // Preserve alpha!

                // Allow user to drop colors into each palette entry. Note that ColorButton() is already a
                // drag source by default, unless specifying the ImGuiColorEditFlags_NoDragDrop flag.
                if (BeginDragDropTarget())
                {
                    if (const ImGuiPayload* payload = AcceptDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_3F))
                        memcpy((f32*)&saved_palette[n], payload.Data, size_of(f32) * 3);
                    if (const ImGuiPayload* payload = AcceptDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_4F))
                        memcpy((f32*)&saved_palette[n], payload.Data, size_of(f32) * 4);
                    EndDragDropTarget();
                }

                PopID();
            }
            EndGroup();
            EndPopup();
        }

        IMGUI_DEMO_MARKER("Widgets/Color/ColorButton (simple)");
        Text("Color button only:");
        static bool no_border = false;
        Checkbox("ImGuiColorEditFlags_NoBorder", &no_border);
        ColorButton("MyColor##3c", *(ImVec4*)&color, misc_flags | (no_border ? ImGuiColorEditFlags_NoBorder : 0), ImVec2{80, 80});

        IMGUI_DEMO_MARKER("Widgets/Color/ColorPicker");
        SeparatorText("Color picker");
        static bool alpha = true;
        static bool alpha_bar = true;
        static bool side_preview = true;
        static bool ref_color = false;
        static ImVec4 ref_color_v(1.0, 0.0, 1.0, 0.5);
        static i32 display_mode = 0;
        static i32 picker_mode = 0;
        Checkbox("With Alpha", &alpha);
        Checkbox("With Alpha Bar", &alpha_bar);
        Checkbox("With Side Preview", &side_preview);
        if (side_preview)
        {
            SameLine();
            Checkbox("With Ref Color", &ref_color);
            if (ref_color)
            {
                SameLine();
                ColorEdit4("##RefColor", &ref_color_v.x, ImGuiColorEditFlags_NoInputs | misc_flags);
            }
        }
        Combo("Display Mode", &display_mode, "Auto/Current0x00None0x00RGB Only0x00HSV Only0x00Hex Only0x00");
        SameLine(); HelpMarker(
            "ColorEdit defaults to displaying RGB inputs if you don't specify a display mode, "
            "but the user can change it with a right-click on those inputs.\n\nColorPicker defaults to displaying RGB+HSV+Hex "
            "if you don't specify a display mode.\n\nYou can change the defaults using SetColorEditOptions().");
        SameLine(); HelpMarker("When not specified explicitly (Auto/Current mode), user can right-click the picker to change mode.");
        flags := misc_flags;
        if (!alpha)            flags |= ImGuiColorEditFlags_NoAlpha;        // This is by default if you call ColorPicker3() instead of ColorPicker4()
        if (alpha_bar)         flags |= ImGuiColorEditFlags_AlphaBar;
        if (!side_preview)     flags |= ImGuiColorEditFlags_NoSidePreview;
        if (picker_mode == 1)  flags |= ImGuiColorEditFlags_PickerHueBar;
        if (picker_mode == 2)  flags |= ImGuiColorEditFlags_PickerHueWheel;
        if (display_mode == 1) flags |= ImGuiColorEditFlags_NoInputs;       // Disable all RGB/HSV/Hex displays
        if (display_mode == 2) flags |= ImGuiColorEditFlags_DisplayRGB;     // Override display mode
        if (display_mode == 3) flags |= ImGuiColorEditFlags_DisplayHSV;
        if (display_mode == 4) flags |= ImGuiColorEditFlags_DisplayHex;
        ColorPicker4("MyColor##4", (f32*)&color, flags, ref_color ? &ref_color_v.x : nil);

        Text("Set defaults in code:");
        SameLine(); HelpMarker(
            "SetColorEditOptions() is designed to allow you to set boot-time default.\n"
            "We don't have Push/Pop functions because you can force options on a per-widget basis if needed,"
            "and the user can change non-forced ones with the options menu.\nWe don't have a getter to avoid"
            "encouraging you to persistently save values that aren't forward-compatible.");
        if (Button("Default: Uint8 + HSV + Hue Bar"))
            SetColorEditOptions(ImGuiColorEditFlags_Uint8 | ImGuiColorEditFlags_DisplayHSV | ImGuiColorEditFlags_PickerHueBar);
        if (Button("Default: Float + HDR + Hue Wheel"))
            SetColorEditOptions(ImGuiColorEditFlags_Float | ImGuiColorEditFlags_HDR | ImGuiColorEditFlags_PickerHueWheel);

        // Always display a small version of both types of pickers
        // (that's in order to make it more visible in the demo to people who are skimming quickly through it)
        Text("Both types:");
        w := (GetContentRegionAvail().x - GetStyle().ItemSpacing.y) * 0.40;
        SetNextItemWidth(w);
        ColorPicker3("##MyColor##5", (f32*)&color, ImGuiColorEditFlags_PickerHueBar | ImGuiColorEditFlags_NoSidePreview | ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_NoAlpha);
        SameLine();
        SetNextItemWidth(w);
        ColorPicker3("##MyColor##6", (f32*)&color, ImGuiColorEditFlags_PickerHueWheel | ImGuiColorEditFlags_NoSidePreview | ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_NoAlpha);

        // HSV encoded support (to avoid RGB<>HSV round trips and singularities when S==0 or V==0)
        static ImVec4 color_hsv(0.23, 1.0, 1.0, 1.0); // Stored as HSV!
        Spacing();
        Text("HSV encoded colors");
        SameLine(); HelpMarker(
            "By default, colors are given to ColorEdit and ColorPicker in RGB, but ImGuiColorEditFlags_InputHSV"
            "allows you to store colors as HSV and pass them to ColorEdit and ColorPicker as HSV. This comes with the"
            "added benefit that you can manipulate hue values with the picker even when saturation or value are zero.");
        Text("Color widget with InputHSV:");
        ColorEdit4("HSV shown as RGB##1", (f32*)&color_hsv, ImGuiColorEditFlags_DisplayRGB | ImGuiColorEditFlags_InputHSV | ImGuiColorEditFlags_Float);
        ColorEdit4("HSV shown as HSV##1", (f32*)&color_hsv, ImGuiColorEditFlags_DisplayHSV | ImGuiColorEditFlags_InputHSV | ImGuiColorEditFlags_Float);
        DragFloat4("Raw HSV values", (f32*)&color_hsv, 0.01, 0.0, 1.0);

        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Drag and Slider Flags");
    if (TreeNode("Drag/Slider Flags"))
    {
        // Demonstrate using advanced flags for DragXXX and SliderXXX functions. Note that the flags are the same!
        static ImGuiSliderFlags flags = ImGuiSliderFlags_None;
        CheckboxFlags("ImGuiSliderFlags_AlwaysClamp", &flags, ImGuiSliderFlags_AlwaysClamp);
        CheckboxFlags("ImGuiSliderFlags_ClampOnInput", &flags, ImGuiSliderFlags_ClampOnInput);
        SameLine(); HelpMarker("Clamp value to min/max bounds when input manually with CTRL+Click. By default CTRL+Click allows going out of bounds.");
        CheckboxFlags("ImGuiSliderFlags_ClampZeroRange", &flags, ImGuiSliderFlags_ClampZeroRange);
        SameLine(); HelpMarker("Clamp even if min==max==0.0. Otherwise DragXXX functions don't clamp.");
        CheckboxFlags("ImGuiSliderFlags_Logarithmic", &flags, ImGuiSliderFlags_Logarithmic);
        SameLine(); HelpMarker("Enable logarithmic editing (more precision for small values).");
        CheckboxFlags("ImGuiSliderFlags_NoRoundToFormat", &flags, ImGuiSliderFlags_NoRoundToFormat);
        SameLine(); HelpMarker("Disable rounding underlying value to match precision of the format string (e.g. %.3 values are rounded to those 3 digits).");
        CheckboxFlags("ImGuiSliderFlags_NoInput", &flags, ImGuiSliderFlags_NoInput);
        SameLine(); HelpMarker("Disable CTRL+Click or Enter key allowing to input text directly into the widget.");
        CheckboxFlags("ImGuiSliderFlags_NoSpeedTweaks", &flags, ImGuiSliderFlags_NoSpeedTweaks);
        SameLine(); HelpMarker("Disable keyboard modifiers altering tweak speed. Useful if you want to alter tweak speed yourself based on your own logic.");
        CheckboxFlags("ImGuiSliderFlags_WrapAround", &flags, ImGuiSliderFlags_WrapAround);
        SameLine(); HelpMarker("Enable wrapping around from max to min and from min to max (only supported by DragXXX() functions)");

        // Drags
        static f32 drag_f = 0.5;
        static i32 drag_i = 50;
        Text("Underlying f32 value: %f", drag_f);
        DragFloat("DragFloat (0 -> 1)", &drag_f, 0.005, 0.0, 1.0, "%.3", flags);
        DragFloat("DragFloat (0 -> +inf)", &drag_f, 0.005, 0.0, math.F32_MAX, "%.3", flags);
        DragFloat("DragFloat (-inf -> 1)", &drag_f, 0.005, -math.F32_MAX, 1.0, "%.3", flags);
        DragFloat("DragFloat (-inf -> +inf)", &drag_f, 0.005, -math.F32_MAX, +math.F32_MAX, "%.3", flags);
        //ImGui::DragFloat("DragFloat (0 -> 0)", &drag_f, 0.005f, 0.0f, 0.0f, "%.3f", flags);           // To test ClampZeroRange
        //ImGui::DragFloat("DragFloat (100 -> 100)", &drag_f, 0.005f, 100.0f, 100.0f, "%.3f", flags);
        DragInt("DragInt (0 -> 100)", &drag_i, 0.5, 0, 100, "%d", flags);

        // Sliders
        static f32 slider_f = 0.5;
        static i32 slider_i = 50;
        flags_for_sliders := flags & ~ImGuiSliderFlags_WrapAround;
        Text("Underlying f32 value: %f", slider_f);
        SliderFloat("SliderFloat (0 -> 1)", &slider_f, 0.0, 1.0, "%.3", flags_for_sliders);
        SliderInt("SliderInt (0 -> 100)", &slider_i, 0, 100, "%d", flags_for_sliders);

        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Range Widgets");
    if (TreeNode("Range Widgets"))
    {
        static f32 begin = 10, end = 90;
        static i32 begin_i = 100, end_i = 1000;
        DragFloatRange2("range f32", &begin, &end, 0.25, 0.0, 100.0, "Min: %.1 %%", "Max: %.1 %%", ImGuiSliderFlags_AlwaysClamp);
        DragIntRange2("range i32", &begin_i, &end_i, 5, 0, 1000, "Min: %d units", "Max: %d units");
        DragIntRange2("range i32 (no bounds)", &begin_i, &end_i, 5, 0, 0, "Min: %d units", "Max: %d units");
        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Data Types");
    if (TreeNode("Data Types"))
    {
        // DragScalar/InputScalar/SliderScalar functions allow various data types
        // - signed/unsigned
        // - 8/16/32/64-bits
        // - integer/float/double
        // To avoid polluting the public API with all possible combinations, we use the ImGuiDataType enum
        // to pass the type, and passing all arguments by pointer.
        // This is the reason the test code below creates local variables to hold "zero" "one" etc. for each type.
        // In practice, if you frequently use a given type that is not covered by the normal API entry points,
        // you can wrap it yourself inside a 1 line function which can take typed argument as value instead of void*,
        // and then pass their address to the generic function. For example:
        //   bool MySliderU64(const char *label, u64* value, u64 min = 0, u64 max = 0, const char* format = "%lld")
        //   {
        //      return SliderScalar(label, ImGuiDataType_U64, value, &min, &max, format);
        //   }

        // Setup limits (as helper variables so we can take their address, as explained above)
        // Note: SliderScalar() functions have a maximum usable range of half the natural type maximum, hence the /2.
when !(LLONG_MIN) {
        LLONG_MIN := -9223372036854775807LL - 1;
        LLONG_MAX := 9223372036854775807LL;
        ULLONG_MAX := (2ULL * 9223372036854775807LL + 1);
}
        s8_zero := 0,   s8_one  = 1,   s8_fifty  = 50, s8_min  = -128,        s8_max = 127;
        u8_zero := 0,   u8_one  = 1,   u8_fifty  = 50, u8_min  = 0,           u8_max = 255;
        s16_zero := 0,   s16_one = 1,   s16_fifty = 50, s16_min = -32768,      s16_max = 32767;
        u16_zero := 0,   u16_one = 1,   u16_fifty = 50, u16_min = 0,           u16_max = 65535;
        s32_zero := 0,   s32_one = 1,   s32_fifty = 50, s32_min = INT_MIN/2,   s32_max = INT_MAX/2,    s32_hi_a = INT_MAX/2 - 100,    s32_hi_b = INT_MAX/2;
        u32_zero := 0,   u32_one = 1,   u32_fifty = 50, u32_min = 0,           u32_max = UINT_MAX/2,   u32_hi_a = UINT_MAX/2 - 100,   u32_hi_b = UINT_MAX/2;
        s64_zero := 0,   s64_one = 1,   s64_fifty = 50, s64_min = LLONG_MIN/2, s64_max = LLONG_MAX/2,  s64_hi_a = LLONG_MAX/2 - 100,  s64_hi_b = LLONG_MAX/2;
        u64_zero := 0,   u64_one = 1,   u64_fifty = 50, u64_min = 0,           u64_max = ULLONG_MAX/2, u64_hi_a = ULLONG_MAX/2 - 100, u64_hi_b = ULLONG_MAX/2;
        f32_zero := 0.f, f32_one = 1.f, f32_lo_a = -10000000000.0, f32_hi_a = +10000000000.0;
        f64_zero := 0.,  f64_one = 1.,  f64_lo_a = -1000000000000000.0, f64_hi_a = +1000000000000000.0;

        // State
        static u8   s8_v  = 127;
        static u8   u8_v  = 255;
        static i16  s16_v = 32767;
        static u16  u16_v = 65535;
        static i32  s32_v = -1;
        static u32  u32_v = (u32)-1;
        static i64  s64_v = -1;
        static u64  u64_v = (u64)-1;
        static f32  f32_v = 0.123;
        static f64 f64_v = 90000.01234567890123456789;

        drag_speed := 0.2;
        static bool drag_clamp = false;
        IMGUI_DEMO_MARKER("Widgets/Data Types/Drags");
        SeparatorText("Drags");
        Checkbox("Clamp integers to 0..50", &drag_clamp);
        SameLine(); HelpMarker(
            "As with every widget in dear imgui, we never modify values unless there is a user interaction.\n"
            "You can override the clamping limits by using CTRL+Click to input a value.");
        DragScalar("drag s8",        ImGuiDataType_S8,     &s8_v,  drag_speed, drag_clamp ? &s8_zero  : nil, drag_clamp ? &s8_fifty  : nil);
        DragScalar("drag u8",        ImGuiDataType_U8,     &u8_v,  drag_speed, drag_clamp ? &u8_zero  : nil, drag_clamp ? &u8_fifty  : nil, "%u ms");
        DragScalar("drag s16",       ImGuiDataType_S16,    &s16_v, drag_speed, drag_clamp ? &s16_zero : nil, drag_clamp ? &s16_fifty : nil);
        DragScalar("drag u16",       ImGuiDataType_U16,    &u16_v, drag_speed, drag_clamp ? &u16_zero : nil, drag_clamp ? &u16_fifty : nil, "%u ms");
        DragScalar("drag s32",       ImGuiDataType_S32,    &s32_v, drag_speed, drag_clamp ? &s32_zero : nil, drag_clamp ? &s32_fifty : nil);
        DragScalar("drag s32 hex",   ImGuiDataType_S32,    &s32_v, drag_speed, drag_clamp ? &s32_zero : nil, drag_clamp ? &s32_fifty : nil, "0x%08X");
        DragScalar("drag u32",       ImGuiDataType_U32,    &u32_v, drag_speed, drag_clamp ? &u32_zero : nil, drag_clamp ? &u32_fifty : nil, "%u ms");
        DragScalar("drag s64",       ImGuiDataType_S64,    &s64_v, drag_speed, drag_clamp ? &s64_zero : nil, drag_clamp ? &s64_fifty : nil);
        DragScalar("drag u64",       ImGuiDataType_U64,    &u64_v, drag_speed, drag_clamp ? &u64_zero : nil, drag_clamp ? &u64_fifty : nil);
        DragScalar("drag f32",     ImGuiDataType_Float,  &f32_v, 0.005,  &f32_zero, &f32_one, "%f");
        DragScalar("drag f32 log", ImGuiDataType_Float,  &f32_v, 0.005,  &f32_zero, &f32_one, "%f", ImGuiSliderFlags_Logarithmic);
        DragScalar("drag f64",    ImGuiDataType_Double, &f64_v, 0.0005, &f64_zero, nil,     "%.10 grams");
        DragScalar("drag f64 log",ImGuiDataType_Double, &f64_v, 0.0005, &f64_zero, &f64_one, "0 < %.10 < 1", ImGuiSliderFlags_Logarithmic);

        IMGUI_DEMO_MARKER("Widgets/Data Types/Sliders");
        SeparatorText("Sliders");
        SliderScalar("slider s8 full",       ImGuiDataType_S8,     &s8_v,  &s8_min,   &s8_max,   "%d");
        SliderScalar("slider u8 full",       ImGuiDataType_U8,     &u8_v,  &u8_min,   &u8_max,   "%u");
        SliderScalar("slider s16 full",      ImGuiDataType_S16,    &s16_v, &s16_min,  &s16_max,  "%d");
        SliderScalar("slider u16 full",      ImGuiDataType_U16,    &u16_v, &u16_min,  &u16_max,  "%u");
        SliderScalar("slider s32 low",       ImGuiDataType_S32,    &s32_v, &s32_zero, &s32_fifty,"%d");
        SliderScalar("slider s32 high",      ImGuiDataType_S32,    &s32_v, &s32_hi_a, &s32_hi_b, "%d");
        SliderScalar("slider s32 full",      ImGuiDataType_S32,    &s32_v, &s32_min,  &s32_max,  "%d");
        SliderScalar("slider s32 hex",       ImGuiDataType_S32,    &s32_v, &s32_zero, &s32_fifty, "0x%04X");
        SliderScalar("slider u32 low",       ImGuiDataType_U32,    &u32_v, &u32_zero, &u32_fifty,"%u");
        SliderScalar("slider u32 high",      ImGuiDataType_U32,    &u32_v, &u32_hi_a, &u32_hi_b, "%u");
        SliderScalar("slider u32 full",      ImGuiDataType_U32,    &u32_v, &u32_min,  &u32_max,  "%u");
        SliderScalar("slider s64 low",       ImGuiDataType_S64,    &s64_v, &s64_zero, &s64_fifty,"%" PRId64);
        SliderScalar("slider s64 high",      ImGuiDataType_S64,    &s64_v, &s64_hi_a, &s64_hi_b, "%" PRId64);
        SliderScalar("slider s64 full",      ImGuiDataType_S64,    &s64_v, &s64_min,  &s64_max,  "%" PRId64);
        SliderScalar("slider u64 low",       ImGuiDataType_U64,    &u64_v, &u64_zero, &u64_fifty,"%" PRIu64 " ms");
        SliderScalar("slider u64 high",      ImGuiDataType_U64,    &u64_v, &u64_hi_a, &u64_hi_b, "%" PRIu64 " ms");
        SliderScalar("slider u64 full",      ImGuiDataType_U64,    &u64_v, &u64_min,  &u64_max,  "%" PRIu64 " ms");
        SliderScalar("slider f32 low",     ImGuiDataType_Float,  &f32_v, &f32_zero, &f32_one);
        SliderScalar("slider f32 low log", ImGuiDataType_Float,  &f32_v, &f32_zero, &f32_one,  "%.10", ImGuiSliderFlags_Logarithmic);
        SliderScalar("slider f32 high",    ImGuiDataType_Float,  &f32_v, &f32_lo_a, &f32_hi_a, "%e");
        SliderScalar("slider f64 low",    ImGuiDataType_Double, &f64_v, &f64_zero, &f64_one,  "%.10 grams");
        SliderScalar("slider f64 low log",ImGuiDataType_Double, &f64_v, &f64_zero, &f64_one,  "%.10", ImGuiSliderFlags_Logarithmic);
        SliderScalar("slider f64 high",   ImGuiDataType_Double, &f64_v, &f64_lo_a, &f64_hi_a, "%e grams");

        SeparatorText("Sliders (reverse)");
        SliderScalar("slider s8 reverse",    ImGuiDataType_S8,   &s8_v,  &s8_max,    &s8_min,   "%d");
        SliderScalar("slider u8 reverse",    ImGuiDataType_U8,   &u8_v,  &u8_max,    &u8_min,   "%u");
        SliderScalar("slider s32 reverse",   ImGuiDataType_S32,  &s32_v, &s32_fifty, &s32_zero, "%d");
        SliderScalar("slider u32 reverse",   ImGuiDataType_U32,  &u32_v, &u32_fifty, &u32_zero, "%u");
        SliderScalar("slider s64 reverse",   ImGuiDataType_S64,  &s64_v, &s64_fifty, &s64_zero, "%" PRId64);
        SliderScalar("slider u64 reverse",   ImGuiDataType_U64,  &u64_v, &u64_fifty, &u64_zero, "%" PRIu64 " ms");

        IMGUI_DEMO_MARKER("Widgets/Data Types/Inputs");
        static bool inputs_step = true;
        static ImGuiInputTextFlags flags = ImGuiInputTextFlags_None;
        SeparatorText("Inputs");
        Checkbox("Show step buttons", &inputs_step);
        CheckboxFlags("ImGuiInputTextFlags_ReadOnly", &flags, ImGuiInputTextFlags_ReadOnly);
        CheckboxFlags("ImGuiInputTextFlags_ParseEmptyRefVal", &flags, ImGuiInputTextFlags_ParseEmptyRefVal);
        CheckboxFlags("ImGuiInputTextFlags_DisplayEmptyRefVal", &flags, ImGuiInputTextFlags_DisplayEmptyRefVal);
        InputScalar("input s8",      ImGuiDataType_S8,     &s8_v,  inputs_step ? &s8_one  : nil, nil, "%d", flags);
        InputScalar("input u8",      ImGuiDataType_U8,     &u8_v,  inputs_step ? &u8_one  : nil, nil, "%u", flags);
        InputScalar("input s16",     ImGuiDataType_S16,    &s16_v, inputs_step ? &s16_one : nil, nil, "%d", flags);
        InputScalar("input u16",     ImGuiDataType_U16,    &u16_v, inputs_step ? &u16_one : nil, nil, "%u", flags);
        InputScalar("input s32",     ImGuiDataType_S32,    &s32_v, inputs_step ? &s32_one : nil, nil, "%d", flags);
        InputScalar("input s32 hex", ImGuiDataType_S32,    &s32_v, inputs_step ? &s32_one : nil, nil, "%04X", flags);
        InputScalar("input u32",     ImGuiDataType_U32,    &u32_v, inputs_step ? &u32_one : nil, nil, "%u", flags);
        InputScalar("input u32 hex", ImGuiDataType_U32,    &u32_v, inputs_step ? &u32_one : nil, nil, "%08X", flags);
        InputScalar("input s64",     ImGuiDataType_S64,    &s64_v, inputs_step ? &s64_one : nil, nil, nil, flags);
        InputScalar("input u64",     ImGuiDataType_U64,    &u64_v, inputs_step ? &u64_one : nil, nil, nil, flags);
        InputScalar("input f32",   ImGuiDataType_Float,  &f32_v, inputs_step ? &f32_one : nil, nil, nil, flags);
        InputScalar("input f64",  ImGuiDataType_Double, &f64_v, inputs_step ? &f64_one : nil, nil, nil, flags);

        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Multi-component Widgets");
    if (TreeNode("Multi-component Widgets"))
    {
        static f32 vec4f[4] = { 0.10, 0.20, 0.30, 0.44 };
        static i32 vec4i[4] = { 1, 5, 100, 255 };

        SeparatorText("2-wide");
        InputFloat2("input float2", vec4f);
        DragFloat2("drag float2", vec4f, 0.01, 0.0, 1.0);
        SliderFloat2("slider float2", vec4f, 0.0, 1.0);
        InputInt2("input int2", vec4i);
        DragInt2("drag int2", vec4i, 1, 0, 255);
        SliderInt2("slider int2", vec4i, 0, 255);

        SeparatorText("3-wide");
        InputFloat3("input float3", vec4f);
        DragFloat3("drag float3", vec4f, 0.01, 0.0, 1.0);
        SliderFloat3("slider float3", vec4f, 0.0, 1.0);
        InputInt3("input int3", vec4i);
        DragInt3("drag int3", vec4i, 1, 0, 255);
        SliderInt3("slider int3", vec4i, 0, 255);

        SeparatorText("4-wide");
        InputFloat4("input float4", vec4f);
        DragFloat4("drag float4", vec4f, 0.01, 0.0, 1.0);
        SliderFloat4("slider float4", vec4f, 0.0, 1.0);
        InputInt4("input int4", vec4i);
        DragInt4("drag int4", vec4i, 1, 0, 255);
        SliderInt4("slider int4", vec4i, 0, 255);

        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Vertical Sliders");
    if (TreeNode("Vertical Sliders"))
    {
        spacing := 4;
        PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2{spacing, spacing});

        static i32 int_value = 0;
        VSliderInt("##i32", ImVec2{18, 160}, &int_value, 0, 5);
        SameLine();

        static f32 values[7] = { 0.0, 0.60, 0.35, 0.9, 0.70, 0.20, 0.0 };
        PushID("set1");
        for i32 i = 0; i < 7; i++
        {
            if (i > 0) SameLine();
            PushID(i);
            PushStyleColor(ImGuiCol_FrameBg, (ImVec4)ImColor::HSV(i / 7.0, 0.5, 0.5));
            PushStyleColor(ImGuiCol_FrameBgHovered, (ImVec4)ImColor::HSV(i / 7.0, 0.6, 0.5));
            PushStyleColor(ImGuiCol_FrameBgActive, (ImVec4)ImColor::HSV(i / 7.0, 0.7, 0.5));
            PushStyleColor(ImGuiCol_SliderGrab, (ImVec4)ImColor::HSV(i / 7.0, 0.9, 0.9));
            VSliderFloat("##v", ImVec2{18, 160}, &values[i], 0.0, 1.0, "");
            if (IsItemActive() || IsItemHovered())
                SetTooltip("%.3", values[i]);
            PopStyleColor(4);
            PopID();
        }
        PopID();

        SameLine();
        PushID("set2");
        static f32 values2[4] = { 0.20, 0.80, 0.40, 0.25 };
        rows := 3;
        small_slider_size := slider(18, (f32)(i32)((160.0 - (rows - 1) * spacing) / rows));
        for i32 nx = 0; nx < 4; nx++
        {
            if (nx > 0) SameLine();
            BeginGroup();
            for i32 ny = 0; ny < rows; ny++
            {
                PushID(nx * rows + ny);
                VSliderFloat("##v", small_slider_size, &values2[nx], 0.0, 1.0, "");
                if (IsItemActive() || IsItemHovered())
                    SetTooltip("%.3", values2[nx]);
                PopID();
            }
            EndGroup();
        }
        PopID();

        SameLine();
        PushID("set3");
        for i32 i = 0; i < 4; i++
        {
            if (i > 0) SameLine();
            PushID(i);
            PushStyleVar(ImGuiStyleVar_GrabMinSize, 40);
            VSliderFloat("##v", ImVec2{40, 160}, &values[i], 0.0, 1.0, "%.2\nsec");
            PopStyleVar();
            PopID();
        }
        PopID();
        PopStyleVar();
        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Drag and drop");
    if (TreeNode("Drag and Drop"))
    {
        IMGUI_DEMO_MARKER("Widgets/Drag and drop/Standard widgets");
        if (TreeNode("Drag and drop in standard widgets"))
        {
            // ColorEdit widgets automatically act as drag source and drag target.
            // They are using standardized payload strings IMGUI_PAYLOAD_TYPE_COLOR_3F and IMGUI_PAYLOAD_TYPE_COLOR_4F
            // to allow your own widgets to use colors in their drag and drop interaction.
            // Also see 'Demo->Widgets->Color/Picker Widgets->Palette' demo.
            HelpMarker("You can drag from the color squares.");
            static f32 col1[3] = { 1.0, 0.0, 0.2 };
            static f32 col2[4] = { 0.4, 0.7, 0.0, 0.5 };
            ColorEdit3("color 1", col1);
            ColorEdit4("color 2", col2);
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Drag and drop/Copy-swap items");
        if (TreeNode("Drag and drop to copy/swap items"))
        {
            Mode :: enum i32
            {
                Copy,
                Move,
                Swap
            };
            static i32 mode = 0;
            if (RadioButton("Copy", mode == Mode_Copy)) { mode = Mode_Copy; } SameLine();
            if (RadioButton("Move", mode == Mode_Move)) { mode = Mode_Move; } SameLine();
            if (RadioButton("Swap", mode == Mode_Swap)) { mode = Mode_Swap; }
            static const u8* names[9] =
            {
                "Bobby", "Beatrice", "Betty",
                "Brianna", "Barry", "Bernard",
                "Bibi", "Blaine", "Bryn"
            };
            for i32 n = 0; n < len(names); n++
            {
                PushID(n);
                if ((n % 3) != 0)
                    SameLine();
                Button(names[n], ImVec2{60, 60});

                // Our buttons are both drag sources and drag targets here!
                if (BeginDragDropSource(ImGuiDragDropFlags_None))
                {
                    // Set payload to carry the index of our item (could be anything)
                    SetDragDropPayload("DND_DEMO_CELL", &n, size_of(i32));

                    // Display preview (could be anything, e.g. when dragging an image we could decide to display
                    // the filename and a small preview of the image, etc.)
                    if (mode == Mode_Copy) { Text("Copy %s", names[n]); }
                    if (mode == Mode_Move) { Text("Move %s", names[n]); }
                    if (mode == Mode_Swap) { Text("Swap %s", names[n]); }
                    EndDragDropSource();
                }
                if (BeginDragDropTarget())
                {
                    if (const ImGuiPayload* payload = AcceptDragDropPayload("DND_DEMO_CELL"))
                    {
                        assert(payload.DataSize == size_of(i32));
                        payload_n := *(const i32*)payload.Data;
                        if (mode == Mode_Copy)
                        {
                            names[n] = names[payload_n];
                        }
                        if (mode == Mode_Move)
                        {
                            names[n] = names[payload_n];
                            names[payload_n] = "";
                        }
                        if (mode == Mode_Swap)
                        {
                            tmp := names[n];
                            names[n] = names[payload_n];
                            names[payload_n] = tmp;
                        }
                    }
                    EndDragDropTarget();
                }
                PopID();
            }
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Drag and Drop/Drag to reorder items (simple)");
        if (TreeNode("Drag to reorder items (simple)"))
        {
            // FIXME: there is temporary (usually single-frame) ID Conflict during reordering as a same item may be submitting twice.
            // This code was always slightly faulty but in a way which was not easily noticeable.
            // Until we fix this, enable ImGuiItemFlags_AllowDuplicateId to disable detecting the issue.
            PushItemFlag(ImGuiItemFlags_AllowDuplicateId, true);

            // Simple reordering
            HelpMarker(
                "We don't use the drag and drop api at all here! "
                "Instead we query when the item is held but not hovered, and order items accordingly.");
            static const u8* item_names[] = { "Item One", "Item Two", "Item Three", "Item Four", "Item Five" };
            for i32 n = 0; n < len(item_names); n++
            {
                item := item_names[n];
                Selectable(item);

                if (IsItemActive() && !IsItemHovered())
                {
                    n_next := n + (GetMouseDragDelta(0).y < 0.f ? -1 : 1);
                    if (n_next >= 0 && n_next < len(item_names))
                    {
                        item_names[n] = item_names[n_next];
                        item_names[n_next] = item;
                        ResetMouseDragDelta();
                    }
                }
            }

            PopItemFlag();
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Drag and Drop/Tooltip at target location");
        if (TreeNode("Tooltip at target location"))
        {
            for i32 n = 0; n < 2; n++
            {
                // Drop targets
                Button(n ? "drop here##1" : "drop here##0");
                if (BeginDragDropTarget())
                {
                    drop_target_flags := ImGuiDragDropFlags_AcceptBeforeDelivery | ImGuiDragDropFlags_AcceptNoPreviewTooltip;
                    if (const ImGuiPayload* payload = AcceptDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_4F, drop_target_flags))
                    {
                        IM_UNUSED(payload);
                        SetMouseCursor(ImGuiMouseCursor_NotAllowed);
                        SetTooltip("Cannot drop here!");
                    }
                    EndDragDropTarget();
                }

                // Drop source
                static ImVec4 col4 = { 1.0, 0.0, 0.2, 1.0 };
                if (n == 0)
                    ColorButton("drag me", col4);

            }
            TreePop();
        }

        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Querying Item Status (Edited,Active,Hovered etc.)");
    if (TreeNode("Querying Item Status (Edited/Active/Hovered etc.)"))
    {
        // Select an item type
        const u8* item_names[] =
        {
            "Text", "Button", "Button (w/ repeat)", "Checkbox", "SliderFloat", "InputText", "InputTextMultiline", "InputFloat",
            "InputFloat3", "ColorEdit4", "Selectable", "MenuItem", "TreeNode", "TreeNode (w/ f64-click)", "Combo", "ListBox"
        };
        static i32 item_type = 4;
        static bool item_disabled = false;
        Combo("Item Type", &item_type, item_names, len(item_names), len(item_names));
        SameLine();
        HelpMarker("Testing how various types of items are interacting with the IsItemXXX functions. Note that the bool return value of most ImGui function is generally equivalent to calling IsItemHovered().");
        Checkbox("Item Disabled",  &item_disabled);

        // Submit selected items so we can query their status in the code following it.
        ret := false;
        static bool b = false;
        static f32 col4f[4] = { 1.0, 0.5, 0.0, 1.0 };
        static u8 str[16] = {};
        if (item_disabled)
            BeginDisabled(true);
        if (item_type == 0) { Text("ITEM: Text"); }                                              // Testing text items with no identifier/interaction
        if (item_type == 1) { ret = Button("ITEM: Button"); }                                    // Testing button
        if (item_type == 2) { PushItemFlag(ImGuiItemFlags_ButtonRepeat, true); ret = Button("ITEM: Button"); PopItemFlag(); } // Testing button (with repeater)
        if (item_type == 3) { ret = Checkbox("ITEM: Checkbox", &b); }                            // Testing checkbox
        if (item_type == 4) { ret = SliderFloat("ITEM: SliderFloat", &col4f[0], 0.0, 1.0); }   // Testing basic item
        if (item_type == 5) { ret = InputText("ITEM: InputText", &str[0], len(str)); }  // Testing input text (which handles tabbing)
        if (item_type == 6) { ret = InputTextMultiline("ITEM: InputTextMultiline", &str[0], len(str)); } // Testing input text (which uses a child window)
        if (item_type == 7) { ret = InputFloat("ITEM: InputFloat", col4f, 1.0); }               // Testing +/- buttons on scalar input
        if (item_type == 8) { ret = InputFloat3("ITEM: InputFloat3", col4f); }                   // Testing multi-component items (IsItemXXX flags are reported merged)
        if (item_type == 9) { ret = ColorEdit4("ITEM: ColorEdit4", col4f); }                     // Testing multi-component items (IsItemXXX flags are reported merged)
        if (item_type == 10){ ret = Selectable("ITEM: Selectable"); }                            // Testing selectable item
        if (item_type == 11){ ret = MenuItem("ITEM: MenuItem"); }                                // Testing menu item (they use ImGuiButtonFlags_PressedOnRelease button policy)
        if (item_type == 12){ ret = TreeNode("ITEM: TreeNode"); if (ret) TreePop(); }     // Testing tree node
        if (item_type == 13){ ret = TreeNodeEx("ITEM: TreeNode w/ ImGuiTreeNodeFlags_OpenOnDoubleClick", ImGuiTreeNodeFlags_OpenOnDoubleClick | ImGuiTreeNodeFlags_NoTreePushOnOpen); } // Testing tree node with ImGuiButtonFlags_PressedOnDoubleClick button policy.
        if (item_type == 14){ const u8* items[] = { "Apple", "Banana", "Cherry", "Kiwi" }; static i32 current = 1; ret = Combo("ITEM: Combo", &current, items, len(items)); }
        if (item_type == 15){ const u8* items[] = { "Apple", "Banana", "Cherry", "Kiwi" }; static i32 current = 1; ret = ListBox("ITEM: ListBox", &current, items, len(items), len(items)); }

        hovered_delay_none := IsItemHovered();
        hovered_delay_stationary := IsItemHovered(ImGuiHoveredFlags_Stationary);
        hovered_delay_short := IsItemHovered(ImGuiHoveredFlags_DelayShort);
        hovered_delay_normal := IsItemHovered(ImGuiHoveredFlags_DelayNormal);
        hovered_delay_tooltip := IsItemHovered(ImGuiHoveredFlags_ForTooltip); // = Normal + Stationary

        // Display the values of IsItemHovered() and other common item state functions.
        // Note that the ImGuiHoveredFlags_XXX flags can be combined.
        // Because BulletText is an item itself and that would affect the output of IsItemXXX functions,
        // we query every state in a single call to avoid storing them and to simplify the code.
        BulletText(
            "Return value = %d\n"
            "IsItemFocused() = %d\n"
            "IsItemHovered() = %d\n"
            "IsItemHovered(_AllowWhenBlockedByPopup) = %d\n"
            "IsItemHovered(_AllowWhenBlockedByActiveItem) = %d\n"
            "IsItemHovered(_AllowWhenOverlappedByItem) = %d\n"
            "IsItemHovered(_AllowWhenOverlappedByWindow) = %d\n"
            "IsItemHovered(_AllowWhenDisabled) = %d\n"
            "IsItemHovered(_RectOnly) = %d\n"
            "IsItemActive() = %d\n"
            "IsItemEdited() = %d\n"
            "IsItemActivated() = %d\n"
            "IsItemDeactivated() = %d\n"
            "IsItemDeactivatedAfterEdit() = %d\n"
            "IsItemVisible() = %d\n"
            "IsItemClicked() = %d\n"
            "IsItemToggledOpen() = %d\n"
            "GetItemRectMin() = (%.1, %.1)\n"
            "GetItemRectMax() = (%.1, %.1)\n"
            "GetItemRectSize() = (%.1, %.1)",
            ret,
            IsItemFocused(),
            IsItemHovered(),
            IsItemHovered(ImGuiHoveredFlags_AllowWhenBlockedByPopup),
            IsItemHovered(ImGuiHoveredFlags_AllowWhenBlockedByActiveItem),
            IsItemHovered(ImGuiHoveredFlags_AllowWhenOverlappedByItem),
            IsItemHovered(ImGuiHoveredFlags_AllowWhenOverlappedByWindow),
            IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled),
            IsItemHovered(ImGuiHoveredFlags_RectOnly),
            IsItemActive(),
            IsItemEdited(),
            IsItemActivated(),
            IsItemDeactivated(),
            IsItemDeactivatedAfterEdit(),
            IsItemVisible(),
            IsItemClicked(),
            IsItemToggledOpen(),
            GetItemRectMin().x, GetItemRectMin().y,
            GetItemRectMax().x, GetItemRectMax().y,
            GetItemRectSize().x, GetItemRectSize().y
        );
        BulletText(
            "with Hovering Delay or Stationary test:\n"
            "IsItemHovered() = = %d\n"
            "IsItemHovered(_Stationary) = %d\n"
            "IsItemHovered(_DelayShort) = %d\n"
            "IsItemHovered(_DelayNormal) = %d\n"
            "IsItemHovered(_Tooltip) = %d",
            hovered_delay_none, hovered_delay_stationary, hovered_delay_short, hovered_delay_normal, hovered_delay_tooltip);

        if (item_disabled)
            EndDisabled();

        u8 buf[1] = "";
        InputText("unused", buf, len(buf), ImGuiInputTextFlags_ReadOnly);
        SameLine();
        HelpMarker("This widget is only here to be able to tab-out of the widgets above and see e.g. Deactivated() status.");

        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Querying Window Status (Focused,Hovered etc.)");
    if (TreeNode("Querying Window Status (Focused/Hovered etc.)"))
    {
        static bool embed_all_inside_a_child_window = false;
        Checkbox("Embed everything inside a child window for testing _RootWindow flag.", &embed_all_inside_a_child_window);
        if (embed_all_inside_a_child_window)
            BeginChild("outer_child", ImVec2{0, GetFontSize(} * 20.0), ImGuiChildFlags_Borders);

        // Testing IsWindowFocused() function with its various flags.
        BulletText(
            "IsWindowFocused() = %d\n"
            "IsWindowFocused(_ChildWindows) = %d\n"
            "IsWindowFocused(_ChildWindows|_NoPopupHierarchy) = %d\n"
            "IsWindowFocused(_ChildWindows|_DockHierarchy) = %d\n"
            "IsWindowFocused(_ChildWindows|_RootWindow) = %d\n"
            "IsWindowFocused(_ChildWindows|_RootWindow|_NoPopupHierarchy) = %d\n"
            "IsWindowFocused(_ChildWindows|_RootWindow|_DockHierarchy) = %d\n"
            "IsWindowFocused(_RootWindow) = %d\n"
            "IsWindowFocused(_RootWindow|_NoPopupHierarchy) = %d\n"
            "IsWindowFocused(_RootWindow|_DockHierarchy) = %d\n"
            "IsWindowFocused(_AnyWindow) = %d\n",
            IsWindowFocused(),
            IsWindowFocused(ImGuiFocusedFlags_ChildWindows),
            IsWindowFocused(ImGuiFocusedFlags_ChildWindows | ImGuiFocusedFlags_NoPopupHierarchy),
            IsWindowFocused(ImGuiFocusedFlags_ChildWindows | ImGuiFocusedFlags_DockHierarchy),
            IsWindowFocused(ImGuiFocusedFlags_ChildWindows | ImGuiFocusedFlags_RootWindow),
            IsWindowFocused(ImGuiFocusedFlags_ChildWindows | ImGuiFocusedFlags_RootWindow | ImGuiFocusedFlags_NoPopupHierarchy),
            IsWindowFocused(ImGuiFocusedFlags_ChildWindows | ImGuiFocusedFlags_RootWindow | ImGuiFocusedFlags_DockHierarchy),
            IsWindowFocused(ImGuiFocusedFlags_RootWindow),
            IsWindowFocused(ImGuiFocusedFlags_RootWindow | ImGuiFocusedFlags_NoPopupHierarchy),
            IsWindowFocused(ImGuiFocusedFlags_RootWindow | ImGuiFocusedFlags_DockHierarchy),
            IsWindowFocused(ImGuiFocusedFlags_AnyWindow));

        // Testing IsWindowHovered() function with its various flags.
        BulletText(
            "IsWindowHovered() = %d\n"
            "IsWindowHovered(_AllowWhenBlockedByPopup) = %d\n"
            "IsWindowHovered(_AllowWhenBlockedByActiveItem) = %d\n"
            "IsWindowHovered(_ChildWindows) = %d\n"
            "IsWindowHovered(_ChildWindows|_NoPopupHierarchy) = %d\n"
            "IsWindowHovered(_ChildWindows|_DockHierarchy) = %d\n"
            "IsWindowHovered(_ChildWindows|_RootWindow) = %d\n"
            "IsWindowHovered(_ChildWindows|_RootWindow|_NoPopupHierarchy) = %d\n"
            "IsWindowHovered(_ChildWindows|_RootWindow|_DockHierarchy) = %d\n"
            "IsWindowHovered(_RootWindow) = %d\n"
            "IsWindowHovered(_RootWindow|_NoPopupHierarchy) = %d\n"
            "IsWindowHovered(_RootWindow|_DockHierarchy) = %d\n"
            "IsWindowHovered(_ChildWindows|_AllowWhenBlockedByPopup) = %d\n"
            "IsWindowHovered(_AnyWindow) = %d\n"
            "IsWindowHovered(_Stationary) = %d\n",
            IsWindowHovered(),
            IsWindowHovered(ImGuiHoveredFlags_AllowWhenBlockedByPopup),
            IsWindowHovered(ImGuiHoveredFlags_AllowWhenBlockedByActiveItem),
            IsWindowHovered(ImGuiHoveredFlags_ChildWindows),
            IsWindowHovered(ImGuiHoveredFlags_ChildWindows | ImGuiHoveredFlags_NoPopupHierarchy),
            IsWindowHovered(ImGuiHoveredFlags_ChildWindows | ImGuiHoveredFlags_DockHierarchy),
            IsWindowHovered(ImGuiHoveredFlags_ChildWindows | ImGuiHoveredFlags_RootWindow),
            IsWindowHovered(ImGuiHoveredFlags_ChildWindows | ImGuiHoveredFlags_RootWindow | ImGuiHoveredFlags_NoPopupHierarchy),
            IsWindowHovered(ImGuiHoveredFlags_ChildWindows | ImGuiHoveredFlags_RootWindow | ImGuiHoveredFlags_DockHierarchy),
            IsWindowHovered(ImGuiHoveredFlags_RootWindow),
            IsWindowHovered(ImGuiHoveredFlags_RootWindow | ImGuiHoveredFlags_NoPopupHierarchy),
            IsWindowHovered(ImGuiHoveredFlags_RootWindow | ImGuiHoveredFlags_DockHierarchy),
            IsWindowHovered(ImGuiHoveredFlags_ChildWindows | ImGuiHoveredFlags_AllowWhenBlockedByPopup),
            IsWindowHovered(ImGuiHoveredFlags_AnyWindow),
            IsWindowHovered(ImGuiHoveredFlags_Stationary));

        BeginChild("child", ImVec2{0, 50}, ImGuiChildFlags_Borders);
        Text("This is another child window for testing the _ChildWindows flag.");
        EndChild();
        if (embed_all_inside_a_child_window)
            EndChild();

        // Calling IsItemHovered() after begin returns the hovered status of the title bar.
        // This is useful in particular if you want to create a context menu associated to the title bar of a window.
        // This will also work when docked into a Tab (the Tab replace the Title Bar and guarantee the same properties).
        static bool test_window = false;
        Checkbox("Hovered/Active tests after Begin() for title bar testing", &test_window);
        if (test_window)
        {
            // FIXME-DOCK: This window cannot be docked within the ImGui Demo window, this will cause a feedback loop and get them stuck.
            // Could we fix this through an ImGuiWindowClass feature? Or an API call to tag our parent as "don't skip items"?
            Begin("Title bar Hovered/Active tests", &test_window);
            if (BeginPopupContextItem()) // <-- This is using IsItemHovered()
            {
                if (MenuItem("Close")) { test_window = false; }
                EndPopup();
            }
            Text(
                "IsItemHovered() after begin = %d (== is title bar hovered)\n"
                "IsItemActive() after begin = %d (== is window being clicked/moved)\n",
                IsItemHovered(), IsItemActive());
            End();
        }

        TreePop();
    }

    // Demonstrate BeginDisabled/EndDisabled using a checkbox located at the bottom of the section (which is a bit odd:
    // logically we'd have this checkbox at the top of the section, but we don't want this feature to steal that space)
    if (disable_all)
        EndDisabled();

    IMGUI_DEMO_MARKER("Widgets/Disable Block");
    if (TreeNode("Disable block"))
    {
        Checkbox("Disable entire section above", &disable_all);
        SameLine(); HelpMarker("Demonstrate using BeginDisabled()/EndDisabled() across this section.");
        TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Text Filter");
    if (TreeNode("Text Filter"))
    {
        // Helper class to easy setup a text filter.
        // You may want to implement a more feature-full filtering scheme in your own application.
        HelpMarker("Not a widget per-se, but ImGuiTextFilter is a helper to perform simple filtering on text strings.");
        static ImGuiTextFilter filter;
        Text("Filter usage:\n"
            "  \"\"         display all lines\n"
            "  \"xxx\"      display lines containing \"xxx\"\n"
            "  \"xxx,yyy\"  display lines containing \"xxx\" or \"yyy\"\n"
            "  \"-xxx\"     hide lines containing \"xxx\"");
        filter.Draw();
        const u8* lines[] = { "aaa1.c", "bbb1.c", "ccc1.c", "aaa2.cpp", "bbb2.cpp", "ccc2.cpp", "abc.h", "hello, world" };
        for i32 i = 0; i < len(lines); i++
            if (filter.PassFilter(lines[i]))
                BulletText("%s", lines[i]);
        TreePop();
    }
}

const u8* ExampleNames[] =
{
    "Artichoke", "Arugula", "Asparagus", "Avocado", "Bamboo Shoots", "Bean Sprouts", "Beans", "Beet", "Belgian Endive", "Bell Pepper",
    "Bitter Gourd", "Bok Choy", "Broccoli", "Brussels Sprouts", "Burdock Root", "Cabbage", "Calabash", "Capers", "Carrot", "Cassava",
    "Cauliflower", "Celery", "Celery Root", "Celcuce", "Chayote", "Chinese Broccoli", "Corn", "Cucumber"
};

// Extra functions to add deletion support to ImGuiSelectionBasicStorage
struct ExampleSelectionWithDeletion : ImGuiSelectionBasicStorage
{
    // Find which item should be Focused after deletion.
    // Call _before_ item submission. Retunr an index in the before-deletion item list, your item loop should call SetKeyboardFocusHere() on it.
    // The subsequent ApplyDeletionPostLoop() code will use it to apply Selection.
    // - We cannot provide this logic in core Dear ImGui because we don't have access to selection data.
    // - We don't actually manipulate the ImVector<> here, only in ApplyDeletionPostLoop(), but using similar API for consistency and flexibility.
    // - Important: Deletion only works if the underlying ImGuiID for your items are stable: aka not depend on their index, but on e.g. item id/ptr.
    // FIXME-MULTISELECT: Doesn't take account of the possibility focus target will be moved during deletion. Need refocus or scroll offset.
    ApplyDeletionPreLoop :: proc(ms_io : ^ImGuiMultiSelectIO, items_count : i32) -> i32
    {
        if (Size == 0)
            return -1;

        // If focused item is not selected...
        focused_idx := cast(ast) ast) ast) dItem;  // Index of currently focused item
        if (ms_io.NavIdSelected == false)  // This is merely a shortcut, == Contains(adapter->IndexToStorage(items, focused_idx))
        {
            ms_io.RangeSrcReset = true;    // Request to recover RangeSrc from NavId next frame. Would be ok to reset even when NavIdSelected==true, but it would take an extra frame to recover RangeSrc when deleting a selected item.
            return focused_idx;             // Request to focus same item after deletion.
        }

        // If focused item is selected: land on first unselected item after focused item.
        for i32 idx = focused_idx + 1; idx < items_count; idx++
            if (!Contains(GetStorageIdFromIndex(idx)))
                return idx;

        // If focused item is selected: otherwise return last unselected item before focused item.
        for i32 idx = IM_MIN(focused_idx, items_count) - 1; idx >= 0; idx--
            if (!Contains(GetStorageIdFromIndex(idx)))
                return idx;

        return -1;
    }

    // Rewrite item list (delete items) + update selection.
    // - Call after EndMultiSelect()
    // - We cannot provide this logic in core Dear ImGui because we don't have access to your items, nor to selection data.
    template<typename ITEM_TYPE>
    ApplyDeletionPostLoop :: proc(ms_io : ^ImGuiMultiSelectIO, items : ImVector<ITEM_TYPE>, item_curr_idx_to_select : i32)
    {
        // Rewrite item list (delete items) + convert old selection index (before deletion) to new selection index (after selection).
        // If NavId was not part of selection, we will stay on same item.
        new_items : [dynamic]ITEM_TYPE
        new_items.reserve(items.Size - Size);
        item_next_idx_to_select := -1;
        for i32 idx = 0; idx < items.Size; idx++
        {
            if (!Contains(GetStorageIdFromIndex(idx)))
                new_items.push_back(items[idx]);
            if (item_curr_idx_to_select == idx)
                item_next_idx_to_select = new_items.Size - 1;
        }
        items.swap(new_items);

        // Update selection
        Clear();
        if (item_next_idx_to_select != -1 && ms_io.NavIdSelected)
            SetItemSelected(GetStorageIdFromIndex(item_next_idx_to_select), true);
    }
};

// Example: Implement dual list box storage and interface
ExampleDualListBox :: struct
{
    Items : [2][dynamic]ImGuiID,               // ID is index into ExampleName[]
    Selections : [2]ImGuiSelectionBasicStorage,          // Store ExampleItemId into selection
    OptKeepSorted := true;

    MoveAll :: proc(src : i32, dst : i32)
    {
        assert((src == 0 && dst == 1) || (src == 1 && dst == 0));
        for ImGuiID item_id : Items[src]
            Items[dst].push_back(item_id);
        Items[src].clear();
        SortItems(dst);
        Selections[src].Swap(Selections[dst]);
        Selections[src].Clear();
    }
    MoveSelected :: proc(src : i32, dst : i32)
    {
        for i32 src_n = 0; src_n < Items[src].Size; src_n++
        {
            item_id := Items[src][src_n];
            if (!Selections[src].Contains(item_id))
                continue;
            Items[src].erase(&Items[src][src_n]); // FIXME-OPT: Could be implemented more optimally (rebuild src items and swap)
            Items[dst].push_back(item_id);
            src_n -= 1;
        }
        if (OptKeepSorted)
            SortItems(dst);
        Selections[src].Swap(Selections[dst]);
        Selections[src].Clear();
    }
    ApplySelectionRequests :: proc(ms_io : ^ImGuiMultiSelectIO, side : i32)
    {
        // In this example we store item id in selection (instead of item index)
        Selections[side].UserData = Items[side].Data;
        Selections[side].AdapterIndexToStorageId = [](ImGuiSelectionBasicStorage* self, i32 idx) { ImGuiID* items = (ImGuiID*)self.UserData; return items[idx]; };
        Selections[side].ApplyRequests(ms_io);
    }
    static i32 IMGUI_CDECL CompareItemsByValue(const rawptr lhs, const rawptr rhs)
    {
        a := (const i32*)lhs;
        b := (const i32*)rhs;
        return (*a - *b) > 0 ? +1 : -1;
    }
    SortItems :: proc(n : i32)
    {
        qsort(Items[n].Data, cast(ast) ast) ast) ize, size_of(Items[n][0]), CompareItemsByValue);
    }
    Show :: proc()
    {
        //ImGui::Checkbox("Sorted", &OptKeepSorted);
        if (BeginTable("split", 3, ImGuiTableFlags_None))
        {
            TableSetupColumn("", ImGuiTableColumnFlags_WidthStretch);    // Left side
            TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed);      // Buttons
            TableSetupColumn("", ImGuiTableColumnFlags_WidthStretch);    // Right side
            TableNextRow();

            request_move_selected := -1;
            request_move_all := -1;
            child_height_0 := 0.0;
            for i32 side = 0; side < 2; side++
            {
                // FIXME-MULTISELECT: Dual List Box: Add context menus
                // FIXME-NAV: Using ImGuiWindowFlags_NavFlattened exhibit many issues.
                ImVector<ImGuiID>& items = Items[side];
                ImGuiSelectionBasicStorage& selection = Selections[side];

                TableSetColumnIndex((side == 0) ? 0 : 2);
                Text("%s (%d)", (side == 0) ? "Available" : "Basket", items.Size);

                // Submit scrolling range to avoid glitches on moving/deletion
                items_height := GetTextLineHeightWithSpacing();
                SetNextWindowContentSize(ImVec2{0.0, items.Size * items_height});

                child_visible : bool,
                if (side == 0)
                {
                    // Left child is resizable
                    SetNextWindowSizeConstraints(ImVec2{0.0, GetFrameHeightWithSpacing(} * 4), ImVec2{math.F32_MAX, math.F32_MAX});
                    child_visible = BeginChild("0", ImVec2{-math.F32_MIN, GetFontSize(} * 20), ImGuiChildFlags_FrameStyle | ImGuiChildFlags_ResizeY);
                    child_height_0 = GetWindowSize().y;
                }
                else
                {
                    // Right child use same height as left one
                    child_visible = BeginChild("1", ImVec2{-math.F32_MIN, child_height_0}, ImGuiChildFlags_FrameStyle);
                }
                if (child_visible)
                {
                    flags := ImGuiMultiSelectFlags_None;
                    ms_io := BeginMultiSelect(flags, selection.Size, items.Size);
                    ApplySelectionRequests(ms_io, side);

                    for i32 item_n = 0; item_n < items.Size; item_n++
                    {
                        item_id := items[item_n];
                        item_is_selected := selection.Contains(item_id);
                        SetNextItemSelectionUserData(item_n);
                        Selectable(ExampleNames[item_id], item_is_selected, ImGuiSelectableFlags_AllowDoubleClick);
                        if (IsItemFocused())
                        {
                            // FIXME-MULTISELECT: Dual List Box: Transfer focus
                            if (IsKeyPressed(ImGuiKey_Enter) || IsKeyPressed(ImGuiKey_KeypadEnter))
                                request_move_selected = side;
                            if (IsMouseDoubleClicked(0)) // FIXME-MULTISELECT: Double-click on multi-selection?
                                request_move_selected = side;
                        }
                    }

                    ms_io = EndMultiSelect();
                    ApplySelectionRequests(ms_io, side);
                }
                EndChild();
            }

            // Buttons columns
            TableSetColumnIndex(1);
            NewLine();
            //ImVec2 button_sz = { ImGui::CalcTextSize(">>").x + ImGui::GetStyle().FramePadding.x * 2.0f, ImGui::GetFrameHeight() + padding.y * 2.0f };
            button_sz := { GetFrameHeight(), GetFrameHeight() };

            // (Using BeginDisabled()/EndDisabled() works but feels distracting given how it is currently visualized)
            if (Button(">>", button_sz))
                request_move_all = 0;
            if (Button(">", button_sz))
                request_move_selected = 0;
            if (Button("<", button_sz))
                request_move_selected = 1;
            if (Button("<<", button_sz))
                request_move_all = 1;

            // Process requests
            if (request_move_all != -1)
                MoveAll(request_move_all, request_move_all ^ 1);
            if (request_move_selected != -1)
                MoveSelected(request_move_selected, request_move_selected ^ 1);

            // FIXME-MULTISELECT: Support action from outside
            /*
            if (OptKeepSorted == false)
            {
                NewLine();
                if (ArrowButton("MoveUp", ImGuiDir_Up)) {}
                if (ArrowButton("MoveDown", ImGuiDir_Down)) {}
            }
            */

            EndTable();
        }
    }
};

//-----------------------------------------------------------------------------
// [SECTION] ShowDemoWindowMultiSelect()
//-----------------------------------------------------------------------------
// Multi-selection demos
// Also read: https://github.com/ocornut/imgui/wiki/Multi-Select
//-----------------------------------------------------------------------------

ShowDemoWindowMultiSelect :: proc(demo_data : ^ImGuiDemoWindowData)
{
    IMGUI_DEMO_MARKER("Widgets/Selection State & Multi-Select");
    if (TreeNode("Selection State & Multi-Select"))
    {
        HelpMarker("Selections can be built using Selectable(), TreeNode() or other widgets. Selection state is owned by application code/data.");

        // Without any fancy API: manage single-selection yourself.
        IMGUI_DEMO_MARKER("Widgets/Selection State/Single-Select");
        if (TreeNode("Single-Select"))
        {
            static i32 selected = -1;
            for i32 n = 0; n < 5; n++
            {
                buf : [32]u8
                sprintf(buf, "Object %d", n);
                if (Selectable(buf, selected == n))
                    selected = n;
            }
            TreePop();
        }

        // Demonstrate implementation a most-basic form of multi-selection manually
        // This doesn't support the SHIFT modifier which requires BeginMultiSelect()!
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (manual/simplified, without BeginMultiSelect)");
        if (TreeNode("Multi-Select (manual/simplified, without BeginMultiSelect)"))
        {
            HelpMarker("Hold CTRL and click to select multiple items.");
            static bool selection[5] = { false, false, false, false, false };
            for i32 n = 0; n < 5; n++
            {
                buf : [32]u8
                sprintf(buf, "Object %d", n);
                if (Selectable(buf, selection[n]))
                {
                    if (!GetIO().KeyCtrl) // Clear selection when CTRL is not held
                        memset(selection, 0, size_of(selection));
                    selection[n] ^= 1; // Toggle current item
                }
            }
            TreePop();
        }

        // Demonstrate handling proper multi-selection using the BeginMultiSelect/EndMultiSelect API.
        // SHIFT+Click w/ CTRL and other standard features are supported.
        // We use the ImGuiSelectionBasicStorage helper which you may freely reimplement.
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select");
        if (TreeNode("Multi-Select"))
        {
            Text("Supported features:");
            BulletText("Keyboard navigation (arrows, page up/down, home/end, space).");
            BulletText("Ctrl modifier to preserve and toggle selection.");
            BulletText("Shift modifier for range selection.");
            BulletText("CTRL+A to select all.");
            BulletText("Escape to clear selection.");
            BulletText("Click and drag to box-select.");
            Text("Tip: Use 'Demo.Tools->Debug Log.Selection' to see selection requests as they happen.");

            // Use default selection.Adapter: Pass index to SetNextItemSelectionUserData(), store index in Selection
            ITEMS_COUNT := 50;
            static ImGuiSelectionBasicStorage selection;
            Text("Selection: %d/%d", selection.Size, ITEMS_COUNT);

            // The BeginChild() has no purpose for selection logic, other that offering a scrolling region.
            if (BeginChild("##Basket", ImVec2{-math.F32_MIN, GetFontSize(} * 20), ImGuiChildFlags_FrameStyle | ImGuiChildFlags_ResizeY))
            {
                flags := ImGuiMultiSelectFlags_ClearOnEscape | ImGuiMultiSelectFlags_BoxSelect1d;
                ms_io := BeginMultiSelect(flags, selection.Size, ITEMS_COUNT);
                selection.ApplyRequests(ms_io);

                for i32 n = 0; n < ITEMS_COUNT; n++
                {
                    label : [64]u8
                    sprintf(label, "Object %05d: %s", n, ExampleNames[n % len(ExampleNames)]);
                    item_is_selected := selection.Contains((ImGuiID)n);
                    SetNextItemSelectionUserData(n);
                    Selectable(label, item_is_selected);
                }

                ms_io = EndMultiSelect();
                selection.ApplyRequests(ms_io);
            }
            EndChild();
            TreePop();
        }

        // Demonstrate using the clipper with BeginMultiSelect()/EndMultiSelect()
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (with clipper)");
        if (TreeNode("Multi-Select (with clipper)"))
        {
            // Use default selection.Adapter: Pass index to SetNextItemSelectionUserData(), store index in Selection
            static ImGuiSelectionBasicStorage selection;

            Text("Added features:");
            BulletText("Using ImGuiListClipper.");

            ITEMS_COUNT := 10000;
            Text("Selection: %d/%d", selection.Size, ITEMS_COUNT);
            if (BeginChild("##Basket", ImVec2{-math.F32_MIN, GetFontSize(} * 20), ImGuiChildFlags_FrameStyle | ImGuiChildFlags_ResizeY))
            {
                flags := ImGuiMultiSelectFlags_ClearOnEscape | ImGuiMultiSelectFlags_BoxSelect1d;
                ms_io := BeginMultiSelect(flags, selection.Size, ITEMS_COUNT);
                selection.ApplyRequests(ms_io);

                clipper : ImGuiListClipper
                clipper.Begin(ITEMS_COUNT);
                if (ms_io.RangeSrcItem != -1)
                    clipper.IncludeItemByIndex(cast(ast) ast) ast) eSrcItem); // Ensure RangeSrc item is not clipped.
                for clipper.Step()
                {
                    for i32 n = clipper.DisplayStart; n < clipper.DisplayEnd; n++
                    {
                        label : [64]u8
                        sprintf(label, "Object %05d: %s", n, ExampleNames[n % len(ExampleNames)]);
                        item_is_selected := selection.Contains((ImGuiID)n);
                        SetNextItemSelectionUserData(n);
                        Selectable(label, item_is_selected);
                    }
                }

                ms_io = EndMultiSelect();
                selection.ApplyRequests(ms_io);
            }
            EndChild();
            TreePop();
        }

        // Demonstrate dynamic item list + deletion support using the BeginMultiSelect/EndMultiSelect API.
        // In order to support Deletion without any glitches you need to:
        // - (1) If items are submitted in their own scrolling area, submit contents size SetNextWindowContentSize() ahead of time to prevent one-frame readjustment of scrolling.
        // - (2) Items needs to have persistent ID Stack identifier = ID needs to not depends on their index. PushID(index) = KO. PushID(item_id) = OK. This is in order to focus items reliably after a selection.
        // - (3) BeginXXXX process
        // - (4) Focus process
        // - (5) EndXXXX process
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (with deletion)");
        if (TreeNode("Multi-Select (with deletion)"))
        {
            // Storing items data separately from selection data.
            // (you may decide to store selection data inside your item (aka intrusive storage) if you don't need multiple views over same items)
            // Use a custom selection.Adapter: store item identifier in Selection (instead of index)
            static ImVector<ImGuiID> items;
            static ExampleSelectionWithDeletion selection;
            selection.UserData = (rawptr)&items;
            selection.AdapterIndexToStorageId = [](ImGuiSelectionBasicStorage* self, i32 idx) { ImVector<ImGuiID>* p_items = (ImVector<ImGuiID>*)self.UserData; return (*p_items)[idx]; }; // Index -> ID

            Text("Added features:");
            BulletText("Dynamic list with Delete key support.");
            Text("Selection size: %d/%d", selection.Size, items.Size);

            // Initialize default list with 50 items + button to add/remove items.
            static ImGuiID items_next_id = 0;
            if (items_next_id == 0)
                for ImGuiID n = 0; n < 50; n++
                    items.push_back(items_next_id++);
            if (SmallButton("Add 20 items"))     { for (i32 n = 0; n < 20; n++) { items.push_back(items_next_id++); } }
            SameLine();
            if (SmallButton("Remove 20 items"))  { for (i32 n = IM_MIN(20, items.Size); n > 0; n--) { selection.SetItemSelected(items.back(), false); items.pop_back(); } }

            // (1) Extra to support deletion: Submit scrolling range to avoid glitches on deletion
            items_height := GetTextLineHeightWithSpacing();
            SetNextWindowContentSize(ImVec2{0.0, items.Size * items_height});

            if (BeginChild("##Basket", ImVec2{-math.F32_MIN, GetFontSize(} * 20), ImGuiChildFlags_FrameStyle | ImGuiChildFlags_ResizeY))
            {
                flags := ImGuiMultiSelectFlags_ClearOnEscape | ImGuiMultiSelectFlags_BoxSelect1d;
                ms_io := BeginMultiSelect(flags, selection.Size, items.Size);
                selection.ApplyRequests(ms_io);

                want_delete := Shortcut(ImGuiKey_Delete, ImGuiInputFlags_Repeat) && (selection.Size > 0);
                item_curr_idx_to_focus := want_delete ? selection.ApplyDeletionPreLoop(ms_io, items.Size) : -1;

                for i32 n = 0; n < items.Size; n++
                {
                    item_id := items[n];
                    label : [64]u8
                    sprintf(label, "Object %05u: %s", item_id, ExampleNames[item_id % len(ExampleNames)]);

                    item_is_selected := selection.Contains(item_id);
                    SetNextItemSelectionUserData(n);
                    Selectable(label, item_is_selected);
                    if (item_curr_idx_to_focus == n)
                        SetKeyboardFocusHere(-1);
                }

                // Apply multi-select requests
                ms_io = EndMultiSelect();
                selection.ApplyRequests(ms_io);
                if (want_delete)
                    selection.ApplyDeletionPostLoop(ms_io, items, item_curr_idx_to_focus);
            }
            EndChild();
            TreePop();
        }

        // Implement a Dual List Box (#6648)
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (dual list box)");
        if (TreeNode("Multi-Select (dual list box)"))
        {
            // Init default state
            static ExampleDualListBox dlb;
            if (dlb.Items[0].Size == 0 && dlb.Items[1].Size == 0)
                for i32 item_id = 0; item_id < len(ExampleNames); item_id++
                    dlb.Items[0].push_back((ImGuiID)item_id);

            // Show
            dlb.Show();

            TreePop();
        }

        // Demonstrate using the clipper with BeginMultiSelect()/EndMultiSelect()
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (in a table)");
        if (TreeNode("Multi-Select (in a table)"))
        {
            static ImGuiSelectionBasicStorage selection;

            ITEMS_COUNT := 10000;
            Text("Selection: %d/%d", selection.Size, ITEMS_COUNT);
            if (BeginTable("##Basket", 2, ImGuiTableFlags_ScrollY | ImGuiTableFlags_RowBg | ImGuiTableFlags_BordersOuter))
            {
                TableSetupColumn("Object");
                TableSetupColumn("Action");
                TableSetupScrollFreeze(0, 1);
                TableHeadersRow();

                flags := ImGuiMultiSelectFlags_ClearOnEscape | ImGuiMultiSelectFlags_BoxSelect1d;
                ms_io := BeginMultiSelect(flags, selection.Size, ITEMS_COUNT);
                selection.ApplyRequests(ms_io);

                clipper : ImGuiListClipper
                clipper.Begin(ITEMS_COUNT);
                if (ms_io.RangeSrcItem != -1)
                    clipper.IncludeItemByIndex(cast(ast) ast) ast) eSrcItem); // Ensure RangeSrc item is not clipped.
                for clipper.Step()
                {
                    for i32 n = clipper.DisplayStart; n < clipper.DisplayEnd; n++
                    {
                        TableNextRow();
                        TableNextColumn();
                        label : [64]u8
                        sprintf(label, "Object %05d: %s", n, ExampleNames[n % len(ExampleNames)]);
                        item_is_selected := selection.Contains((ImGuiID)n);
                        SetNextItemSelectionUserData(n);
                        Selectable(label, item_is_selected, ImGuiSelectableFlags_SpanAllColumns | ImGuiSelectableFlags_AllowOverlap);
                        TableNextColumn();
                        SmallButton("hello");
                    }
                }

                ms_io = EndMultiSelect();
                selection.ApplyRequests(ms_io);
                EndTable();
            }
            TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (checkboxes)");
        if (TreeNode("Multi-Select (checkboxes)"))
        {
            Text("In a list of checkboxes (not selectable):");
            BulletText("Using _NoAutoSelect + _NoAutoClear flags.");
            BulletText("Shift+Click to check multiple boxes.");
            BulletText("Shift+Keyboard to copy current value to other boxes.");

            // If you have an array of checkboxes, you may want to use NoAutoSelect + NoAutoClear and the ImGuiSelectionExternalStorage helper.
            static bool items[20] = {};
            static ImGuiMultiSelectFlags flags = ImGuiMultiSelectFlags_NoAutoSelect | ImGuiMultiSelectFlags_NoAutoClear | ImGuiMultiSelectFlags_ClearOnEscape;
            CheckboxFlags("ImGuiMultiSelectFlags_NoAutoSelect", &flags, ImGuiMultiSelectFlags_NoAutoSelect);
            CheckboxFlags("ImGuiMultiSelectFlags_NoAutoClear", &flags, ImGuiMultiSelectFlags_NoAutoClear);
            CheckboxFlags("ImGuiMultiSelectFlags_BoxSelect2d", &flags, ImGuiMultiSelectFlags_BoxSelect2d); // Cannot use ImGuiMultiSelectFlags_BoxSelect1d as checkboxes are varying width.

            if (BeginChild("##Basket", ImVec2{-math.F32_MIN, GetFontSize(} * 20), ImGuiChildFlags_Borders | ImGuiChildFlags_ResizeY))
            {
                ms_io := BeginMultiSelect(flags, -1, len(items));
                storage_wrapper : ImGuiSelectionExternalStorage
                storage_wrapper.UserData = (rawptr)items;
                storage_wrapper.AdapterSetItemSelected = [](ImGuiSelectionExternalStorage* self, i32 n, bool selected) { bool* array = (bool*)self.UserData; array[n] = selected; };
                storage_wrapper.ApplyRequests(ms_io);
                for i32 n = 0; n < 20; n++
                {
                    label : [32]u8
                    sprintf(label, "Item %d", n);
                    SetNextItemSelectionUserData(n);
                    Checkbox(label, &items[n]);
                }
                ms_io = EndMultiSelect();
                storage_wrapper.ApplyRequests(ms_io);
            }
            EndChild();

            TreePop();
        }

        // Demonstrate individual selection scopes in same window
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (multiple scopes)");
        if (TreeNode("Multi-Select (multiple scopes)"))
        {
            // Use default select: Pass index to SetNextItemSelectionUserData(), store index in Selection
            SCOPES_COUNT := 3;
            ITEMS_COUNT := 8; // Per scope
            static ImGuiSelectionBasicStorage selections_data[SCOPES_COUNT];

            // Use ImGuiMultiSelectFlags_ScopeRect to not affect other selections in same window.
            static ImGuiMultiSelectFlags flags = ImGuiMultiSelectFlags_ScopeRect | ImGuiMultiSelectFlags_ClearOnEscape;// | ImGuiMultiSelectFlags_ClearOnClickVoid;
            if (CheckboxFlags("ImGuiMultiSelectFlags_ScopeWindow", &flags, ImGuiMultiSelectFlags_ScopeWindow) && (flags & ImGuiMultiSelectFlags_ScopeWindow))
                flags &= ~ImGuiMultiSelectFlags_ScopeRect;
            if (CheckboxFlags("ImGuiMultiSelectFlags_ScopeRect", &flags, ImGuiMultiSelectFlags_ScopeRect) && (flags & ImGuiMultiSelectFlags_ScopeRect))
                flags &= ~ImGuiMultiSelectFlags_ScopeWindow;
            CheckboxFlags("ImGuiMultiSelectFlags_ClearOnClickVoid", &flags, ImGuiMultiSelectFlags_ClearOnClickVoid);
            CheckboxFlags("ImGuiMultiSelectFlags_BoxSelect1d", &flags, ImGuiMultiSelectFlags_BoxSelect1d);

            for i32 selection_scope_n = 0; selection_scope_n < SCOPES_COUNT; selection_scope_n++
            {
                PushID(selection_scope_n);
                selection := &selections_data[selection_scope_n];
                ms_io := BeginMultiSelect(flags, selection.Size, ITEMS_COUNT);
                selection.ApplyRequests(ms_io);

                SeparatorText("Selection scope");
                Text("Selection size: %d/%d", selection.Size, ITEMS_COUNT);

                for i32 n = 0; n < ITEMS_COUNT; n++
                {
                    label : [64]u8
                    sprintf(label, "Object %05d: %s", n, ExampleNames[n % len(ExampleNames)]);
                    item_is_selected := selection.Contains((ImGuiID)n);
                    SetNextItemSelectionUserData(n);
                    Selectable(label, item_is_selected);
                }

                // Apply multi-select requests
                ms_io = EndMultiSelect();
                selection.ApplyRequests(ms_io);
                PopID();
            }
            TreePop();
        }

        // See ShowExampleAppAssetsBrowser()
        if (TreeNode("Multi-Select (tiled assets browser)"))
        {
            Checkbox("Assets Browser", &demo_data.ShowAppAssetsBrowser);
            Text("(also access from 'Examples.Assets Browser' in menu)");
            TreePop();
        }

        // Demonstrate supporting multiple-selection in a tree.
        // - We don't use linear indices for selection user data, but our ExampleTreeNode* pointer directly!
        //   This showcase how SetNextItemSelectionUserData() never assume indices!
        // - The difficulty here is to "interpolate" from RangeSrcItem to RangeDstItem in the SetAll/SetRange request.
        //   We want this interpolation to match what the user sees: in visible order, skipping closed nodes.
        //   This is implemented by our TreeGetNextNodeInVisibleOrder() user-space helper.
        // - Important: In a real codebase aiming to implement full-featured selectable tree with custom filtering, you
        //   are more likely to build an array mapping sequential indices to visible tree nodes, since your
        //   filtering/search + clipping process will benefit from it. Having this will make this interpolation much easier.
        // - Consider this a prototype: we are working toward simplifying some of it.
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (trees)");
        if (TreeNode("Multi-Select (trees)"))
        {
            HelpMarker(
                "This is rather advanced and experimental. If you are getting started with multi-select,"
                "please don't start by looking at how to use it for a tree!\n\n"
                "Future versions will try to simplify and formalize some of this.");

            ExampleTreeFuncs :: struct
            {
                static void DrawNode(ExampleTreeNode* node, ImGuiSelectionBasicStorage* selection)
                {
                    tree_node_flags := ImGuiTreeNodeFlags_SpanAvailWidth | ImGuiTreeNodeFlags_OpenOnArrow | ImGuiTreeNodeFlags_OpenOnDoubleClick;
                    tree_node_flags |= ImGuiTreeNodeFlags_NavLeftJumpsBackHere; // Enable pressing left to jump to parent
                    if (node.Childs.Size == 0)
                        tree_node_flags |= ImGuiTreeNodeFlags_Bullet | ImGuiTreeNodeFlags_Leaf;
                    if (selection.Contains((ImGuiID)node.UID))
                        tree_node_flags |= ImGuiTreeNodeFlags_Selected;

                    // Using SetNextItemStorageID() to specify storage id, so we can easily peek into
                    // the storage holding open/close stage, using our TreeNodeGetOpen/TreeNodeSetOpen() functions.
                    SetNextItemSelectionUserData((ImGuiSelectionUserData)(intptr_t)node);
                    SetNextItemStorageID((ImGuiID)node.UID);
                    if (TreeNodeEx(node.Name, tree_node_flags))
                    {
                        for ExampleTreeNode* child : node.Childs
                            DrawNode(child, selection);
                        TreePop();
                    }
                    else if (IsItemToggledOpen())
                    {
                        TreeCloseAndUnselectChildNodes(node, selection);
                    }
                }

                static bool TreeNodeGetOpen(ExampleTreeNode* node)
                {
                    return GetStateStorage()->GetBool((ImGuiID)node.UID);
                }

                static void TreeNodeSetOpen(ExampleTreeNode* node, bool open)
                {
                    GetStateStorage()->SetBool((ImGuiID)node.UID, open);
                }

                // When closing a node: 1) close and unselect all child nodes, 2) select parent if any child was selected.
                // FIXME: This is currently handled by user logic but I'm hoping to eventually provide tree node
                // features to do this automatically, e.g. a ImGuiTreeNodeFlags_AutoCloseChildNodes etc.
                static i32 TreeCloseAndUnselectChildNodes(ExampleTreeNode* node, ImGuiSelectionBasicStorage* selection, i32 depth = 0)
                {
                    // Recursive close (the test for depth == 0 is because we call this on a node that was just closed!)
                    unselected_count := selection.Contains((ImGuiID)node.UID) ? 1 : 0;
                    if (depth == 0 || TreeNodeGetOpen(node))
                    {
                        for ExampleTreeNode* child : node.Childs
                            unselected_count += TreeCloseAndUnselectChildNodes(child, selection, depth + 1);
                        TreeNodeSetOpen(node, false);
                    }

                    // Select root node if any of its child was selected, otherwise unselect
                    selection.SetItemSelected((ImGuiID)node.UID, (depth == 0 && unselected_count > 0));
                    return unselected_count;
                }

                // Apply multi-selection requests
                static void ApplySelectionRequests(ImGuiMultiSelectIO* ms_io, ExampleTreeNode* tree, ImGuiSelectionBasicStorage* selection)
                {
                    for ImGuiSelectionRequest& req : ms_io.Requests
                    {
                        if (req.Type == ImGuiSelectionRequestType_SetAll)
                        {
                            if (req.Selected)
                                TreeSetAllInOpenNodes(tree, selection, req.Selected);
                            else
                                selection.Clear();
                        }
                        else if (req.Type == ImGuiSelectionRequestType_SetRange)
                        {
                            first_node := (ExampleTreeNode*)(intptr_t)req.RangeFirstItem;
                            last_node := (ExampleTreeNode*)(intptr_t)req.RangeLastItem;
                            for ExampleTreeNode* node = first_node; node != nil; node = TreeGetNextNodeInVisibleOrder(node, last_node)
                                selection.SetItemSelected((ImGuiID)node.UID, req.Selected);
                        }
                    }
                }

                static void TreeSetAllInOpenNodes(ExampleTreeNode* node, ImGuiSelectionBasicStorage* selection, bool selected)
                {
                    if (node.Parent != nil) // Root node isn't visible nor selectable in our scheme
                        selection.SetItemSelected((ImGuiID)node.UID, selected);
                    if (node.Parent == nil || TreeNodeGetOpen(node))
                        for ExampleTreeNode* child : node.Childs
                            TreeSetAllInOpenNodes(child, selection, selected);
                }

                // Interpolate in *user-visible order* AND only *over opened nodes*.
                // If you have a sequential mapping tables (e.g. generated after a filter/search pass) this would be simpler.
                // Here the tricks are that:
                // - we store/maintain ExampleTreeNode::IndexInParent which allows implementing a linear iterator easily, without searches, without recursion.
                //   this could be replaced by a search in parent, aka 'int index_in_parent = curr_node->Parent->Childs.find_index(curr_node)'
                //   which would only be called when crossing from child to a parent, aka not too much.
                // - we call SetNextItemStorageID() before our TreeNode() calls with an ID which doesn't relate to UI stack,
                //   making it easier to call TreeNodeGetOpen()/TreeNodeSetOpen() from any location.
                static ExampleTreeNode* TreeGetNextNodeInVisibleOrder(ExampleTreeNode* curr_node, ExampleTreeNode* last_node)
                {
                    // Reached last node
                    if (curr_node == last_node)
                        return nil;

                    // Recurse into childs. Query storage to tell if the node is open.
                    if (curr_node.Childs.Size > 0 && TreeNodeGetOpen(curr_node))
                        return curr_node.Childs[0];

                    // Next sibling, then into our own parent
                    for curr_node.Parent != nil
                    {
                        if (curr_node.IndexInParent + 1 < curr_node.Parent->Childs.Size)
                            return curr_node.Parent->Childs[curr_node.IndexInParent + 1];
                        curr_node = curr_node.Parent;
                    }
                    return nil;
                }

            }; // ExampleTreeFuncs

            static ImGuiSelectionBasicStorage selection;
            if (demo_data.DemoTree == nil)
                demo_data.DemoTree = ExampleTree_CreateDemoTree(); // Create tree once
            Text("Selection size: %d", selection.Size);

            if (BeginChild("##Tree", ImVec2{-math.F32_MIN, GetFontSize(} * 20), ImGuiChildFlags_FrameStyle | ImGuiChildFlags_ResizeY))
            {
                tree := demo_data.DemoTree;
                ms_flags := ImGuiMultiSelectFlags_ClearOnEscape | ImGuiMultiSelectFlags_BoxSelect2d;
                ms_io := BeginMultiSelect(ms_flags, selection.Size, -1);
                ExampleTreeFuncs::ApplySelectionRequests(ms_io, tree, &selection);
                for ExampleTreeNode* node : tree.Childs
                    ExampleTreeFuncs::DrawNode(node, &selection);
                ms_io = EndMultiSelect();
                ExampleTreeFuncs::ApplySelectionRequests(ms_io, tree, &selection);
            }
            EndChild();

            TreePop();
        }

        // Advanced demonstration of BeginMultiSelect()
        // - Showcase clipping.
        // - Showcase deletion.
        // - Showcase basic drag and drop.
        // - Showcase TreeNode variant (note that tree node don't expand in the demo: supporting expanding tree nodes + clipping a separate thing).
        // - Showcase using inside a table.
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (advanced)");
        //ImGui::SetNextItemOpen(true, ImGuiCond_Once);
        if (TreeNode("Multi-Select (advanced)"))
        {
            // Options
            enum WidgetType { WidgetType_Selectable, WidgetType_TreeNode };
            static bool use_clipper = true;
            static bool use_deletion = true;
            static bool use_drag_drop = true;
            static bool show_in_table = false;
            static bool show_color_button = true;
            static ImGuiMultiSelectFlags flags = ImGuiMultiSelectFlags_ClearOnEscape | ImGuiMultiSelectFlags_BoxSelect1d;
            static WidgetType widget_type = WidgetType_Selectable;

            if (TreeNode("Options"))
            {
                if (RadioButton("Selectables", widget_type == WidgetType_Selectable)) { widget_type = WidgetType_Selectable; }
                SameLine();
                if (RadioButton("Tree nodes", widget_type == WidgetType_TreeNode)) { widget_type = WidgetType_TreeNode; }
                SameLine();
                HelpMarker("TreeNode() is technically supported but... using this correctly is more complicated (you need some sort of linear/random access to your tree, which is suited to advanced trees setups already implementing filters and clipper. We will work toward simplifying and demoing this.\n\nFor now the tree demo is actually a little bit meaningless because it is an empty tree with only root nodes.");
                Checkbox("Enable clipper", &use_clipper);
                Checkbox("Enable deletion", &use_deletion);
                Checkbox("Enable drag & drop", &use_drag_drop);
                Checkbox("Show in a table", &show_in_table);
                Checkbox("Show color button", &show_color_button);
                CheckboxFlags("ImGuiMultiSelectFlags_SingleSelect", &flags, ImGuiMultiSelectFlags_SingleSelect);
                CheckboxFlags("ImGuiMultiSelectFlags_NoSelectAll", &flags, ImGuiMultiSelectFlags_NoSelectAll);
                CheckboxFlags("ImGuiMultiSelectFlags_NoRangeSelect", &flags, ImGuiMultiSelectFlags_NoRangeSelect);
                CheckboxFlags("ImGuiMultiSelectFlags_NoAutoSelect", &flags, ImGuiMultiSelectFlags_NoAutoSelect);
                CheckboxFlags("ImGuiMultiSelectFlags_NoAutoClear", &flags, ImGuiMultiSelectFlags_NoAutoClear);
                CheckboxFlags("ImGuiMultiSelectFlags_NoAutoClearOnReselect", &flags, ImGuiMultiSelectFlags_NoAutoClearOnReselect);
                CheckboxFlags("ImGuiMultiSelectFlags_BoxSelect1d", &flags, ImGuiMultiSelectFlags_BoxSelect1d);
                CheckboxFlags("ImGuiMultiSelectFlags_BoxSelect2d", &flags, ImGuiMultiSelectFlags_BoxSelect2d);
                CheckboxFlags("ImGuiMultiSelectFlags_BoxSelectNoScroll", &flags, ImGuiMultiSelectFlags_BoxSelectNoScroll);
                CheckboxFlags("ImGuiMultiSelectFlags_ClearOnEscape", &flags, ImGuiMultiSelectFlags_ClearOnEscape);
                CheckboxFlags("ImGuiMultiSelectFlags_ClearOnClickVoid", &flags, ImGuiMultiSelectFlags_ClearOnClickVoid);
                if (CheckboxFlags("ImGuiMultiSelectFlags_ScopeWindow", &flags, ImGuiMultiSelectFlags_ScopeWindow) && (flags & ImGuiMultiSelectFlags_ScopeWindow))
                    flags &= ~ImGuiMultiSelectFlags_ScopeRect;
                if (CheckboxFlags("ImGuiMultiSelectFlags_ScopeRect", &flags, ImGuiMultiSelectFlags_ScopeRect) && (flags & ImGuiMultiSelectFlags_ScopeRect))
                    flags &= ~ImGuiMultiSelectFlags_ScopeWindow;
                if (CheckboxFlags("ImGuiMultiSelectFlags_SelectOnClick", &flags, ImGuiMultiSelectFlags_SelectOnClick) && (flags & ImGuiMultiSelectFlags_SelectOnClick))
                    flags &= ~ImGuiMultiSelectFlags_SelectOnClickRelease;
                if (CheckboxFlags("ImGuiMultiSelectFlags_SelectOnClickRelease", &flags, ImGuiMultiSelectFlags_SelectOnClickRelease) && (flags & ImGuiMultiSelectFlags_SelectOnClickRelease))
                    flags &= ~ImGuiMultiSelectFlags_SelectOnClick;
                SameLine(); HelpMarker("Allow dragging an unselected item without altering selection.");
                TreePop();
            }

            // Initialize default list with 1000 items.
            // Use default selection.Adapter: Pass index to SetNextItemSelectionUserData(), store index in Selection
            static ImVector<i32> items;
            static i32 items_next_id = 0;
            if (items_next_id == 0) { for (i32 n = 0; n < 1000; n++) { items.push_back(items_next_id++); } }
            static ExampleSelectionWithDeletion selection;
            static bool request_deletion_from_menu = false; // Queue deletion triggered from context menu

            Text("Selection size: %d/%d", selection.Size, items.Size);

            items_height := (widget_type == WidgetType_TreeNode) ? GetTextLineHeight() : GetTextLineHeightWithSpacing();
            SetNextWindowContentSize(ImVec2{0.0, items.Size * items_height});
            if (BeginChild("##Basket", ImVec2{-math.F32_MIN, GetFontSize(} * 20), ImGuiChildFlags_FrameStyle | ImGuiChildFlags_ResizeY))
            {
                color_button_sz := ImVec2{GetFontSize(}, GetFontSize());
                if (widget_type == WidgetType_TreeNode)
                    PushStyleVarY(ImGuiStyleVar_ItemSpacing, 0.0);

                ms_io := BeginMultiSelect(flags, selection.Size, items.Size);
                selection.ApplyRequests(ms_io);

                want_delete := (Shortcut(ImGuiKey_Delete, ImGuiInputFlags_Repeat) && (selection.Size > 0)) || request_deletion_from_menu;
                item_curr_idx_to_focus := want_delete ? selection.ApplyDeletionPreLoop(ms_io, items.Size) : -1;
                request_deletion_from_menu = false;

                if (show_in_table)
                {
                    if (widget_type == WidgetType_TreeNode)
                        PushStyleVar(ImGuiStyleVar_CellPadding, ImVec2{0.0, 0.0});
                    BeginTable("##Split", 2, ImGuiTableFlags_Resizable | ImGuiTableFlags_NoSavedSettings | ImGuiTableFlags_NoPadOuterX);
                    TableSetupColumn("", ImGuiTableColumnFlags_WidthStretch, 0.70);
                    TableSetupColumn("", ImGuiTableColumnFlags_WidthStretch, 0.30);
                    //ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacingY, 0.0f);
                }

                clipper : ImGuiListClipper
                if (use_clipper)
                {
                    clipper.Begin(items.Size);
                    if (item_curr_idx_to_focus != -1)
                        clipper.IncludeItemByIndex(item_curr_idx_to_focus); // Ensure focused item is not clipped.
                    if (ms_io.RangeSrcItem != -1)
                        clipper.IncludeItemByIndex(cast(ast) ast) ast) eSrcItem); // Ensure RangeSrc item is not clipped.
                }

                for !use_clipper || clipper.Step()
                {
                    item_begin := use_clipper ? clipper.DisplayStart : 0;
                    item_end := use_clipper ? clipper.DisplayEnd : items.Size;
                    for i32 n = item_begin; n < item_end; n++
                    {
                        if (show_in_table)
                            TableNextColumn();

                        item_id := items[n];
                        item_category := ExampleNames[item_id % len(ExampleNames)];
                        label : [64]u8
                        sprintf(label, "Object %05d: %s", item_id, item_category);

                        // IMPORTANT: for deletion refocus to work we need object ID to be stable,
                        // aka not depend on their index in the list. Here we use our persistent item_id
                        // instead of index to build a unique ID that will persist.
                        // (If we used PushID(index) instead, focus wouldn't be restored correctly after deletion).
                        PushID(item_id);

                        // Emit a color button, to test that Shift+LeftArrow landing on an item that is not part
                        // of the selection scope doesn't erroneously alter our selection.
                        if (show_color_button)
                        {
                            dummy_col := (u32)(cast(ast) ast) aC250B74B) | IM_COL32_A_MASK;
                            ColorButton("##", ImColor(dummy_col), ImGuiColorEditFlags_NoTooltip, color_button_sz);
                            SameLine();
                        }

                        // Submit item
                        item_is_selected := selection.Contains((ImGuiID)n);
                        item_is_open := false;
                        SetNextItemSelectionUserData(n);
                        if (widget_type == WidgetType_Selectable)
                        {
                            Selectable(label, item_is_selected, ImGuiSelectableFlags_None);
                        }
                        else if (widget_type == WidgetType_TreeNode)
                        {
                            tree_node_flags := ImGuiTreeNodeFlags_SpanAvailWidth | ImGuiTreeNodeFlags_OpenOnArrow | ImGuiTreeNodeFlags_OpenOnDoubleClick;
                            if (item_is_selected)
                                tree_node_flags |= ImGuiTreeNodeFlags_Selected;
                            item_is_open = TreeNodeEx(label, tree_node_flags);
                        }

                        // Focus (for after deletion)
                        if (item_curr_idx_to_focus == n)
                            SetKeyboardFocusHere(-1);

                        // Drag and Drop
                        if (use_drag_drop && BeginDragDropSource())
                        {
                            // Create payload with full selection OR single unselected item.
                            // (the later is only possible when using ImGuiMultiSelectFlags_SelectOnClickRelease)
                            if (GetDragDropPayload() == nil)
                            {
                                payload_items : [dynamic]i32
                                it := nil;
                                id := 0;
                                if (!item_is_selected)
                                    payload_items.push_back(item_id);
                                else
                                    for selection.GetNextSelectedItem(&it, &id)
                                        payload_items.push_back(cast(ast) ast)
                                SetDragDropPayload("MULTISELECT_DEMO_ITEMS", payload_items.Data, cast(int) payload_items.size_in_bytes());
                            }

                            // Display payload content in tooltip
                            payload := GetDragDropPayload();
                            payload_items := (i32*)payload.Data;
                            payload_count := cast(ast) ast) adt) adSize / cast(e /) cast(e /) cas
                            if (payload_count == 1)
                                Text("Object %05d: %s", payload_items[0], ExampleNames[payload_items[0] % len(ExampleNames)]);
                            else
                                Text("Dragging %d objects", payload_count);

                            EndDragDropSource();
                        }

                        if (widget_type == WidgetType_TreeNode && item_is_open)
                            TreePop();

                        // Right-click: context menu
                        if (BeginPopupContextItem())
                        {
                            BeginDisabled(!use_deletion || selection.Size == 0);
                            sprintf(label, "Delete %d item(s)###DeleteSelected", selection.Size);
                            if (Selectable(label))
                                request_deletion_from_menu = true;
                            EndDisabled();
                            Selectable("Close");
                            EndPopup();
                        }

                        // Demo content within a table
                        if (show_in_table)
                        {
                            TableNextColumn();
                            SetNextItemWidth(-math.F32_MIN);
                            PushStyleVar(ImGuiStyleVar_FramePadding, ImVec2{0, 0});
                            InputText("###NoLabel", (u8*)(rawptr)item_category, strlen(item_category), ImGuiInputTextFlags_ReadOnly);
                            PopStyleVar();
                        }

                        PopID();
                    }
                    if (!use_clipper)
                        break;
                }

                if (show_in_table)
                {
                    EndTable();
                    if (widget_type == WidgetType_TreeNode)
                        PopStyleVar();
                }

                // Apply multi-select requests
                ms_io = EndMultiSelect();
                selection.ApplyRequests(ms_io);
                if (want_delete)
                    selection.ApplyDeletionPostLoop(ms_io, items, item_curr_idx_to_focus);

                if (widget_type == WidgetType_TreeNode)
                    PopStyleVar();
            }
            EndChild();
            TreePop();
        }
        TreePop();
    }
}

//-----------------------------------------------------------------------------
// [SECTION] ShowDemoWindowLayout()
//-----------------------------------------------------------------------------

ShowDemoWindowLayout :: proc()
{
    IMGUI_DEMO_MARKER("Layout");
    if (!CollapsingHeader("Layout & Scrolling"))
        return;

    IMGUI_DEMO_MARKER("Layout/Child windows");
    if (TreeNode("Child windows"))
    {
        SeparatorText("Child windows");

        HelpMarker("Use child windows to begin into a self-contained independent scrolling/clipping regions within a host window.");
        static bool disable_mouse_wheel = false;
        static bool disable_menu = false;
        Checkbox("Disable Mouse Wheel", &disable_mouse_wheel);
        Checkbox("Disable Menu", &disable_menu);

        // Child 1: no border, enable horizontal scrollbar
        {
            window_flags := ImGuiWindowFlags_HorizontalScrollbar;
            if (disable_mouse_wheel)
                window_flags |= ImGuiWindowFlags_NoScrollWithMouse;
            BeginChild("ChildL", ImVec2{GetContentRegionAvail(}.x * 0.5, 260), ImGuiChildFlags_None, window_flags);
            for i32 i = 0; i < 100; i++
                Text("%04d: scrollable region", i);
            EndChild();
        }

        SameLine();

        // Child 2: rounded border
        {
            window_flags := ImGuiWindowFlags_None;
            if (disable_mouse_wheel)
                window_flags |= ImGuiWindowFlags_NoScrollWithMouse;
            if (!disable_menu)
                window_flags |= ImGuiWindowFlags_MenuBar;
            PushStyleVar(ImGuiStyleVar_ChildRounding, 5.0);
            BeginChild("ChildR", ImVec2{0, 260}, ImGuiChildFlags_Borders, window_flags);
            if (!disable_menu && BeginMenuBar())
            {
                if (BeginMenu("Menu"))
                {
                    ShowExampleMenuFile();
                    EndMenu();
                }
                EndMenuBar();
            }
            if (BeginTable("split", 2, ImGuiTableFlags_Resizable | ImGuiTableFlags_NoSavedSettings))
            {
                for i32 i = 0; i < 100; i++
                {
                    buf : [32]u8
                    sprintf(buf, "%03d", i);
                    TableNextColumn();
                    Button(buf, ImVec2{-math.F32_MIN, 0.0});
                }
                EndTable();
            }
            EndChild();
            PopStyleVar();
        }

        // Child 3: manual-resize
        SeparatorText("Manual-resize");
        {
            HelpMarker("Drag bottom border to resize. Double-click bottom border to auto-fit to vertical contents.");
            //if (ImGui::Button("Set Height to 200"))
            //    ImGui::SetNextWindowSize(ImVec2(-FLT_MIN, 200.0f));

            PushStyleColor(ImGuiCol_ChildBg, GetStyleColorVec4(ImGuiCol_FrameBg));
            if (BeginChild("ResizableChild", ImVec2{-math.F32_MIN, GetTextLineHeightWithSpacing(} * 8), ImGuiChildFlags_Borders | ImGuiChildFlags_ResizeY))
                for i32 n = 0; n < 10; n++
                    Text("Line %04d", n);
            PopStyleColor();
            EndChild();
        }

        // Child 4: auto-resizing height with a limit
        SeparatorText("Auto-resize with constraints");
        {
            static i32 draw_lines = 3;
            static i32 max_height_in_lines = 10;
            SetNextItemWidth(GetFontSize() * 8);
            DragInt("Lines Count", &draw_lines, 0.2);
            SetNextItemWidth(GetFontSize() * 8);
            DragInt("Max Height (in Lines)", &max_height_in_lines, 0.2);

            SetNextWindowSizeConstraints(ImVec2{0.0, GetTextLineHeightWithSpacing(} * 1), ImVec2{math.F32_MAX, GetTextLineHeightWithSpacing(} * max_height_in_lines));
            if (BeginChild("ConstrainedChild", ImVec2{-math.F32_MIN, 0.0}, ImGuiChildFlags_Borders | ImGuiChildFlags_AutoResizeY))
                for i32 n = 0; n < draw_lines; n++
                    Text("Line %04d", n);
            EndChild();
        }

        SeparatorText("Misc/Advanced");

        // Demonstrate a few extra things
        // - Changing ImGuiCol_ChildBg (which is transparent black in default styles)
        // - Using SetCursorPos() to position child window (the child window is an item from the POV of parent window)
        //   You can also call SetNextWindowPos() to position the child window. The parent window will effectively
        //   layout from this position.
        // - Using ImGui::GetItemRectMin/Max() to query the "item" state (because the child window is an item from
        //   the POV of the parent window). See 'Demo->Querying Status (Edited/Active/Hovered etc.)' for details.
        {
            static i32 offset_x = 0;
            static bool override_bg_color = true;
            static ImGuiChildFlags child_flags = ImGuiChildFlags_Borders | ImGuiChildFlags_ResizeX | ImGuiChildFlags_ResizeY;
            SetNextItemWidth(GetFontSize() * 8);
            DragInt("Offset X", &offset_x, 1.0, -1000, 1000);
            Checkbox("Override ChildBg color", &override_bg_color);
            CheckboxFlags("ImGuiChildFlags_Borders", &child_flags, ImGuiChildFlags_Borders);
            CheckboxFlags("ImGuiChildFlags_AlwaysUseWindowPadding", &child_flags, ImGuiChildFlags_AlwaysUseWindowPadding);
            CheckboxFlags("ImGuiChildFlags_ResizeX", &child_flags, ImGuiChildFlags_ResizeX);
            CheckboxFlags("ImGuiChildFlags_ResizeY", &child_flags, ImGuiChildFlags_ResizeY);
            CheckboxFlags("ImGuiChildFlags_FrameStyle", &child_flags, ImGuiChildFlags_FrameStyle);
            SameLine(); HelpMarker("Style the child window like a framed item: use FrameBg, FrameRounding, FrameBorderSize, FramePadding instead of ChildBg, ChildRounding, ChildBorderSize, WindowPadding.");
            if (child_flags & ImGuiChildFlags_FrameStyle)
                override_bg_color = false;

            SetCursorPosX(GetCursorPosX() + cast(f32) offset_x);
            if (override_bg_color)
                PushStyleColor(ImGuiCol_ChildBg, IM_COL32(255, 0, 0, 100));
            BeginChild("Red", ImVec2{200, 100}, child_flags, ImGuiWindowFlags_None);
            if (override_bg_color)
                PopStyleColor();

            for i32 n = 0; n < 50; n++
                Text("Some test %d", n);
            EndChild();
            child_is_hovered := IsItemHovered();
            child_rect_min := GetItemRectMin();
            child_rect_max := GetItemRectMax();
            Text("Hovered: %d", child_is_hovered);
            Text("Rect of child window is: (%.0,%.0) (%.0,%.0)", child_rect_min.x, child_rect_min.y, child_rect_max.x, child_rect_max.y);
        }

        TreePop();
    }

    IMGUI_DEMO_MARKER("Layout/Widgets Width");
    if (TreeNode("Widgets Width"))
    {
        static f32 f = 0.0;
        static bool show_indented_items = true;
        Checkbox("Show indented items", &show_indented_items);

        // Use SetNextItemWidth() to set the width of a single upcoming item.
        // Use PushItemWidth()/PopItemWidth() to set the width of a group of items.
        // In real code use you'll probably want to choose width values that are proportional to your font size
        // e.g. Using '20.0f * GetFontSize()' as width instead of '200.0f', etc.

        Text("SetNextItemWidth/PushItemWidth(100)");
        SameLine(); HelpMarker("Fixed width.");
        PushItemWidth(100);
        DragFloat("f32##1b", &f);
        if (show_indented_items)
        {
            Indent();
            DragFloat("f32 (indented)##1b", &f);
            Unindent();
        }
        PopItemWidth();

        Text("SetNextItemWidth/PushItemWidth(-100)");
        SameLine(); HelpMarker("Align to right edge minus 100");
        PushItemWidth(-100);
        DragFloat("f32##2a", &f);
        if (show_indented_items)
        {
            Indent();
            DragFloat("f32 (indented)##2b", &f);
            Unindent();
        }
        PopItemWidth();

        Text("SetNextItemWidth/PushItemWidth(GetContentRegionAvail().x * 0.5)");
        SameLine(); HelpMarker("Half of available width.\n(~ right-cursor_pos)\n(works within a column set)");
        PushItemWidth(GetContentRegionAvail().x * 0.5);
        DragFloat("f32##3a", &f);
        if (show_indented_items)
        {
            Indent();
            DragFloat("f32 (indented)##3b", &f);
            Unindent();
        }
        PopItemWidth();

        Text("SetNextItemWidth/PushItemWidth(-GetContentRegionAvail().x * 0.5)");
        SameLine(); HelpMarker("Align to right edge minus half");
        PushItemWidth(-GetContentRegionAvail().x * 0.5);
        DragFloat("f32##4a", &f);
        if (show_indented_items)
        {
            Indent();
            DragFloat("f32 (indented)##4b", &f);
            Unindent();
        }
        PopItemWidth();

        // Demonstrate using PushItemWidth to surround three items.
        // Calling SetNextItemWidth() before each of them would have the same effect.
        Text("SetNextItemWidth/PushItemWidth(-math.F32_MIN)");
        SameLine(); HelpMarker("Align to right edge");
        PushItemWidth(-math.F32_MIN);
        DragFloat("##float5a", &f);
        if (show_indented_items)
        {
            Indent();
            DragFloat("f32 (indented)##5b", &f);
            Unindent();
        }
        PopItemWidth();

        TreePop();
    }

    IMGUI_DEMO_MARKER("Layout/Basic Horizontal Layout");
    if (TreeNode("Basic Horizontal Layout"))
    {
        TextWrapped("(Use SameLine() to keep adding items to the right of the preceding item)");

        // Text
        IMGUI_DEMO_MARKER("Layout/Basic Horizontal Layout/SameLine");
        Text("Two items: Hello"); SameLine();
        TextColored(ImVec4{1, 1, 0, 1}, "Sailor");

        // Adjust spacing
        Text("More spacing: Hello"); SameLine(0, 20);
        TextColored(ImVec4{1, 1, 0, 1}, "Sailor");

        // Button
        AlignTextToFramePadding();
        Text("Normal buttons"); SameLine();
        Button("Banana"); SameLine();
        Button("Apple"); SameLine();
        Button("Corniflower");

        // Button
        Text("Small buttons"); SameLine();
        SmallButton("Like this one"); SameLine();
        Text("can fit within a text block.");

        // Aligned to arbitrary position. Easy/cheap column.
        IMGUI_DEMO_MARKER("Layout/Basic Horizontal Layout/SameLine (with offset)");
        Text("Aligned");
        SameLine(150); Text("x=150");
        SameLine(300); Text("x=300");
        Text("Aligned");
        SameLine(150); SmallButton("x=150");
        SameLine(300); SmallButton("x=300");

        // Checkbox
        IMGUI_DEMO_MARKER("Layout/Basic Horizontal Layout/SameLine (more)");
        static bool c1 = false, c2 = false, c3 = false, c4 = false;
        Checkbox("My", &c1); SameLine();
        Checkbox("Tailor", &c2); SameLine();
        Checkbox("Is", &c3); SameLine();
        Checkbox("Rich", &c4);

        // Various
        static f32 f0 = 1.0, f1 = 2.0, f2 = 3.0;
        PushItemWidth(80);
        const u8* items[] = { "AAAA", "BBBB", "CCCC", "DDDD" };
        static i32 item = -1;
        Combo("Combo", &item, items, len(items)); SameLine();
        SliderFloat("X", &f0, 0.0, 5.0); SameLine();
        SliderFloat("Y", &f1, 0.0, 5.0); SameLine();
        SliderFloat("Z", &f2, 0.0, 5.0);
        PopItemWidth();

        PushItemWidth(80);
        Text("Lists:");
        static i32 selection[4] = { 0, 1, 2, 3 };
        for i32 i = 0; i < 4; i++
        {
            if (i > 0) SameLine();
            PushID(i);
            ListBox("", &selection[i], items, len(items));
            PopID();
            //ImGui::SetItemTooltip("ListBox %d hovered", i);
        }
        PopItemWidth();

        // Dummy
        IMGUI_DEMO_MARKER("Layout/Basic Horizontal Layout/Dummy");
        button_sz := ImVec2{40, 40};
        Button("A", button_sz); SameLine();
        Dummy(button_sz); SameLine();
        Button("B", button_sz);

        // Manually wrapping
        // (we should eventually provide this as an automatic layout feature, but for now you can do it manually)
        IMGUI_DEMO_MARKER("Layout/Basic Horizontal Layout/Manual wrapping");
        Text("Manual wrapping:");
        ImGuiStyle& style = GetStyle();
        buttons_count := 20;
        window_visible_x2 := GetCursorScreenPos().x + GetContentRegionAvail().x;
        for i32 n = 0; n < buttons_count; n++
        {
            PushID(n);
            Button("Box", button_sz);
            last_button_x2 := GetItemRectMax().x;
            next_button_x2 := last_button_x2 + style.ItemSpacing.x + button_sz.x; // Expected position if next button was on same line
            if (n + 1 < buttons_count && next_button_x2 < window_visible_x2)
                SameLine();
            PopID();
        }

        TreePop();
    }

    IMGUI_DEMO_MARKER("Layout/Groups");
    if (TreeNode("Groups"))
    {
        HelpMarker(
            "BeginGroup() basically locks the horizontal position for new line. "
            "EndGroup() bundles the whole group so that you can use \"item\" functions such as "
            "IsItemHovered()/IsItemActive() or SameLine() etc. on the whole group.");
        BeginGroup();
        {
            BeginGroup();
            Button("AAA");
            SameLine();
            Button("BBB");
            SameLine();
            BeginGroup();
            Button("CCC");
            Button("DDD");
            EndGroup();
            SameLine();
            Button("EEE");
            EndGroup();
            SetItemTooltip("First group hovered");
        }
        // Capture the group size and create widgets using the same size
        size := GetItemRectSize();
        const f32 values[5] = { 0.5, 0.20, 0.80, 0.60, 0.25 };
        PlotHistogram("##values", values, len(values), 0, nil, 0.0, 1.0, size);

        Button("ACTION", ImVec2{(size.x - GetStyle(}.ItemSpacing.x) * 0.5, size.y));
        SameLine();
        Button("REACTION", ImVec2{(size.x - GetStyle(}.ItemSpacing.x) * 0.5, size.y));
        EndGroup();
        SameLine();

        Button("LEVERAGE\nBUZZWORD", size);
        SameLine();

        if (BeginListBox("List", size))
        {
            Selectable("Selected", true);
            Selectable("Not Selected", false);
            EndListBox();
        }

        TreePop();
    }

    IMGUI_DEMO_MARKER("Layout/Text Baseline Alignment");
    if (TreeNode("Text Baseline Alignment"))
    {
        {
            BulletText("Text baseline:");
            SameLine(); HelpMarker(
                "This is testing the vertical alignment that gets applied on text to keep it aligned with widgets. "
                "Lines only composed of text or \"small\" widgets use less vertical space than lines with framed widgets.");
            Indent();

            Text("KO Blahblah"); SameLine();
            Button("Some framed item"); SameLine();
            HelpMarker("Baseline of button will look misaligned with text..");

            // If your line starts with text, call AlignTextToFramePadding() to align text to upcoming widgets.
            // (because we don't know what's coming after the Text() statement, we need to move the text baseline
            // down by FramePadding.y ahead of time)
            AlignTextToFramePadding();
            Text("OK Blahblah"); SameLine();
            Button("Some framed item##2"); SameLine();
            HelpMarker("We call AlignTextToFramePadding() to vertically align the text baseline by +FramePadding.y");

            // SmallButton() uses the same vertical padding as Text
            Button("TEST##1"); SameLine();
            Text("TEST"); SameLine();
            SmallButton("TEST##2");

            // If your line starts with text, call AlignTextToFramePadding() to align text to upcoming widgets.
            AlignTextToFramePadding();
            Text("Text aligned to framed item"); SameLine();
            Button("Item##1"); SameLine();
            Text("Item"); SameLine();
            SmallButton("Item##2"); SameLine();
            Button("Item##3");

            Unindent();
        }

        Spacing();

        {
            BulletText("Multi-line text:");
            Indent();
            Text("One\nTwo\nThree"); SameLine();
            Text("Hello\nWorld"); SameLine();
            Text("Banana");

            Text("Banana"); SameLine();
            Text("Hello\nWorld"); SameLine();
            Text("One\nTwo\nThree");

            Button("HOP##1"); SameLine();
            Text("Banana"); SameLine();
            Text("Hello\nWorld"); SameLine();
            Text("Banana");

            Button("HOP##2"); SameLine();
            Text("Hello\nWorld"); SameLine();
            Text("Banana");
            Unindent();
        }

        Spacing();

        {
            BulletText("Misc items:");
            Indent();

            // SmallButton() sets FramePadding to zero. Text baseline is aligned to match baseline of previous Button.
            Button("80x80", ImVec2{80, 80});
            SameLine();
            Button("50x50", ImVec2{50, 50});
            SameLine();
            Button("Button()");
            SameLine();
            SmallButton("SmallButton()");

            // Tree
            spacing := GetStyle().ItemInnerSpacing.x;
            Button("Button##1");
            SameLine(0.0, spacing);
            if (TreeNode("Node##1"))
            {
                // Placeholder tree data
                for i32 i = 0; i < 6; i++
                    BulletText("Item %d..", i);
                TreePop();
            }

            // Vertically align text node a bit lower so it'll be vertically centered with upcoming widget.
            // Otherwise you can use SmallButton() (smaller fit).
            AlignTextToFramePadding();

            // Common mistake to avoid: if we want to SameLine after TreeNode we need to do it before we add
            // other contents below the node.
            node_open := TreeNode("Node##2");
            SameLine(0.0, spacing); Button("Button##2");
            if (node_open)
            {
                // Placeholder tree data
                for i32 i = 0; i < 6; i++
                    BulletText("Item %d..", i);
                TreePop();
            }

            // Bullet
            Button("Button##3");
            SameLine(0.0, spacing);
            BulletText("Bullet text");

            AlignTextToFramePadding();
            BulletText("Node");
            SameLine(0.0, spacing); Button("Button##4");
            Unindent();
        }

        TreePop();
    }

    IMGUI_DEMO_MARKER("Layout/Scrolling");
    if (TreeNode("Scrolling"))
    {
        // Vertical scroll functions
        IMGUI_DEMO_MARKER("Layout/Scrolling/Vertical");
        HelpMarker("Use SetScrollHereY() or SetScrollFromPosY() to scroll to a given vertical position.");

        static i32 track_item = 50;
        static bool enable_track = true;
        static bool enable_extra_decorations = false;
        static f32 scroll_to_off_px = 0.0;
        static f32 scroll_to_pos_px = 200.0;

        Checkbox("Decoration", &enable_extra_decorations);

        Checkbox("Track", &enable_track);
        PushItemWidth(100);
        SameLine(140); enable_track |= DragInt("##item", &track_item, 0.25, 0, 99, "Item = %d");

        scroll_to_off := Button("Scroll Offset");
        SameLine(140); scroll_to_off |= DragFloat("##off", &scroll_to_off_px, 1.00, 0, math.F32_MAX, "+%.0 px");

        scroll_to_pos := Button("Scroll To Pos");
        SameLine(140); scroll_to_pos |= DragFloat("##pos", &scroll_to_pos_px, 1.00, -10, math.F32_MAX, "X/Y = %.0 px");
        PopItemWidth();

        if (scroll_to_off || scroll_to_pos)
            enable_track = false;

        ImGuiStyle& style = GetStyle();
        child_w := (GetContentRegionAvail().x - 4 * style.ItemSpacing.x) / 5;
        if (child_w < 1.0)
            child_w = 1.0;
        PushID("##VerticalScrolling");
        for i32 i = 0; i < 5; i++
        {
            if (i > 0) SameLine();
            BeginGroup();
            const u8* names[] = { "Top", "25%", "Center", "75%", "Bottom" };
            TextUnformatted(names[i]);

            child_flags := enable_extra_decorations ? ImGuiWindowFlags_MenuBar : 0;
            child_id := GetID((rawptr)(intptr_t)i);
            child_is_visible := BeginChild(child_id, ImVec2{child_w, 200.0}, ImGuiChildFlags_Borders, child_flags);
            if (BeginMenuBar())
            {
                TextUnformatted("abc");
                EndMenuBar();
            }
            if (scroll_to_off)
                SetScrollY(scroll_to_off_px);
            if (scroll_to_pos)
                SetScrollFromPosY(GetCursorStartPos().y + scroll_to_pos_px, i * 0.25);
            if (child_is_visible) // Avoid calling SetScrollHereY when running with culled items
            {
                for i32 item = 0; item < 100; item++
                {
                    if (enable_track && item == track_item)
                    {
                        TextColored(ImVec4{1, 1, 0, 1}, "Item %d", item);
                        SetScrollHereY(i * 0.25); // 0.0f:top, 0.5f:center, 1.0f:bottom
                    }
                    else
                    {
                        Text("Item %d", item);
                    }
                }
            }
            scroll_y := GetScrollY();
            scroll_max_y := GetScrollMaxY();
            EndChild();
            Text("%.0/%.0", scroll_y, scroll_max_y);
            EndGroup();
        }
        PopID();

        // Horizontal scroll functions
        IMGUI_DEMO_MARKER("Layout/Scrolling/Horizontal");
        Spacing();
        HelpMarker(
            "Use SetScrollHereX() or SetScrollFromPosX() to scroll to a given horizontal position.\n\n"
            "Because the clipping rectangle of most window hides half worth of WindowPadding on the "
            "left/right, using SetScrollFromPosX(+1) will usually result in clipped text whereas the "
            "equivalent SetScrollFromPosY(+1) wouldn't.");
        PushID("##HorizontalScrolling");
        for i32 i = 0; i < 5; i++
        {
            child_height := GetTextLineHeight() + style.ScrollbarSize + style.WindowPadding.y * 2.0;
            child_flags := ImGuiWindowFlags_HorizontalScrollbar | (enable_extra_decorations ? ImGuiWindowFlags_AlwaysVerticalScrollbar : 0);
            child_id := GetID((rawptr)(intptr_t)i);
            child_is_visible := BeginChild(child_id, ImVec2{-100, child_height}, ImGuiChildFlags_Borders, child_flags);
            if (scroll_to_off)
                SetScrollX(scroll_to_off_px);
            if (scroll_to_pos)
                SetScrollFromPosX(GetCursorStartPos().x + scroll_to_pos_px, i * 0.25);
            if (child_is_visible) // Avoid calling SetScrollHereY when running with culled items
            {
                for i32 item = 0; item < 100; item++
                {
                    if (item > 0)
                        SameLine();
                    if (enable_track && item == track_item)
                    {
                        TextColored(ImVec4{1, 1, 0, 1}, "Item %d", item);
                        SetScrollHereX(i * 0.25); // 0.0f:left, 0.5f:center, 1.0f:right
                    }
                    else
                    {
                        Text("Item %d", item);
                    }
                }
            }
            scroll_x := GetScrollX();
            scroll_max_x := GetScrollMaxX();
            EndChild();
            SameLine();
            const u8* names[] = { "Left", "25%", "Center", "75%", "Right" };
            Text("%s\n%.0/%.0", names[i], scroll_x, scroll_max_x);
            Spacing();
        }
        PopID();

        // Miscellaneous Horizontal Scrolling Demo
        IMGUI_DEMO_MARKER("Layout/Scrolling/Horizontal (more)");
        HelpMarker(
            "Horizontal scrolling for a window is enabled via the ImGuiWindowFlags_HorizontalScrollbar flag.\n\n"
            "You may want to also explicitly specify content width by using SetNextWindowContentWidth() before Begin().");
        static i32 lines = 7;
        SliderInt("Lines", &lines, 1, 15);
        PushStyleVar(ImGuiStyleVar_FrameRounding, 3.0);
        PushStyleVar(ImGuiStyleVar_FramePadding, ImVec2{2.0, 1.0});
        scrolling_child_size := ImVec2{0, GetFrameHeightWithSpacing(} * 7 + 30);
        BeginChild("scrolling", scrolling_child_size, ImGuiChildFlags_Borders, ImGuiWindowFlags_HorizontalScrollbar);
        for i32 line = 0; line < lines; line++
        {
            // Display random stuff. For the sake of this trivial demo we are using basic Button() + SameLine()
            // If you want to create your own time line for a real application you may be better off manipulating
            // the cursor position yourself, aka using SetCursorPos/SetCursorScreenPos to position the widgets
            // yourself. You may also want to use the lower-level ImDrawList API.
            num_buttons := 10 + ((line & 1) ? line * 9 : line * 3);
            for i32 n = 0; n < num_buttons; n++
            {
                if (n > 0) SameLine();
                PushID(n + line * 1000);
                num_buf : [16]u8
                sprintf(num_buf, "%d", n);
                label := (!(n % 15)) ? "FizzBuzz" : (!(n % 3)) ? "Fizz" : (!(n % 5)) ? "Buzz" : num_buf;
                hue := n * 0.05;
                PushStyleColor(ImGuiCol_Button, (ImVec4)ImColor::HSV(hue, 0.6, 0.6));
                PushStyleColor(ImGuiCol_ButtonHovered, (ImVec4)ImColor::HSV(hue, 0.7, 0.7));
                PushStyleColor(ImGuiCol_ButtonActive, (ImVec4)ImColor::HSV(hue, 0.8, 0.8));
                Button(label, ImVec2{40.0 + sinf((f32}(line + n)) * 20.0, 0.0));
                PopStyleColor(3);
                PopID();
            }
        }
        scroll_x := GetScrollX();
        scroll_max_x := GetScrollMaxX();
        EndChild();
        PopStyleVar(2);
        scroll_x_delta := 0.0;
        SmallButton("<<");
        if (IsItemActive())
            scroll_x_delta = -GetIO().DeltaTime * 1000.0;
        SameLine();
        Text("Scroll from code"); SameLine();
        SmallButton(">>");
        if (IsItemActive())
            scroll_x_delta = +GetIO().DeltaTime * 1000.0;
        SameLine();
        Text("%.0/%.0", scroll_x, scroll_max_x);
        if (scroll_x_delta != 0.0)
        {
            // Demonstrate a trick: you can use Begin to set yourself in the context of another window
            // (here we are already out of your child window)
            BeginChild("scrolling");
            SetScrollX(GetScrollX() + scroll_x_delta);
            EndChild();
        }
        Spacing();

        static bool show_horizontal_contents_size_demo_window = false;
        Checkbox("Show Horizontal contents size demo window", &show_horizontal_contents_size_demo_window);

        if (show_horizontal_contents_size_demo_window)
        {
            static bool show_h_scrollbar = true;
            static bool show_button = true;
            static bool show_tree_nodes = true;
            static bool show_text_wrapped = false;
            static bool show_columns = true;
            static bool show_tab_bar = true;
            static bool show_child = false;
            static bool explicit_content_size = false;
            static f32 contents_size_x = 300.0;
            if (explicit_content_size)
                SetNextWindowContentSize(ImVec2{contents_size_x, 0.0});
            Begin("Horizontal contents size demo window", &show_horizontal_contents_size_demo_window, show_h_scrollbar ? ImGuiWindowFlags_HorizontalScrollbar : 0);
            IMGUI_DEMO_MARKER("Layout/Scrolling/Horizontal contents size demo window");
            PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2{2, 0});
            PushStyleVar(ImGuiStyleVar_FramePadding, ImVec2{2, 0});
            HelpMarker(
                "Test how different widgets react and impact the work rectangle growing when horizontal scrolling is enabled.\n\n"
                "Use 'Metrics.Tools->Show windows rectangles' to visualize rectangles.");
            Checkbox("H-scrollbar", &show_h_scrollbar);
            Checkbox("Button", &show_button);            // Will grow contents size (unless explicitly overwritten)
            Checkbox("Tree nodes", &show_tree_nodes);    // Will grow contents size and display highlight over full width
            Checkbox("Text wrapped", &show_text_wrapped);// Will grow and use contents size
            Checkbox("Columns", &show_columns);          // Will use contents size
            Checkbox("Tab bar", &show_tab_bar);          // Will use contents size
            Checkbox("Child", &show_child);              // Will grow and use contents size
            Checkbox("Explicit content size", &explicit_content_size);
            Text("Scroll %.1/%.1 %.1/%.1", GetScrollX(), GetScrollMaxX(), GetScrollY(), GetScrollMaxY());
            if (explicit_content_size)
            {
                SameLine();
                SetNextItemWidth(100);
                DragFloat("##csx", &contents_size_x);
                p := GetCursorScreenPos();
                GetWindowDrawList()->AddRectFilled(p, ImVec2{p.x + 10, p.y + 10}, IM_COL32_WHITE);
                GetWindowDrawList()->AddRectFilled(ImVec2{p.x + contents_size_x - 10, p.y}, ImVec2{p.x + contents_size_x, p.y + 10}, IM_COL32_WHITE);
                Dummy(ImVec2{0, 10});
            }
            PopStyleVar(2);
            Separator();
            if (show_button)
            {
                Button("this is a 300-wide button", ImVec2{300, 0});
            }
            if (show_tree_nodes)
            {
                open := true;
                if (TreeNode("this is a tree node"))
                {
                    if (TreeNode("another one of those tree node..."))
                    {
                        Text("Some tree contents");
                        TreePop();
                    }
                    TreePop();
                }
                CollapsingHeader("CollapsingHeader", &open);
            }
            if (show_text_wrapped)
            {
                TextWrapped("This text should automatically wrap on the edge of the work rectangle.");
            }
            if (show_columns)
            {
                Text("Tables:");
                if (BeginTable("table", 4, ImGuiTableFlags_Borders))
                {
                    for i32 n = 0; n < 4; n++
                    {
                        TableNextColumn();
                        Text("Width %.2", GetContentRegionAvail().x);
                    }
                    EndTable();
                }
                Text("Columns:");
                Columns(4);
                for i32 n = 0; n < 4; n++
                {
                    Text("Width %.2", GetColumnWidth());
                    NextColumn();
                }
                Columns(1);
            }
            if (show_tab_bar && BeginTabBar("Hello"))
            {
                if (BeginTabItem("OneOneOne")) { EndTabItem(); }
                if (BeginTabItem("TwoTwoTwo")) { EndTabItem(); }
                if (BeginTabItem("ThreeThreeThree")) { EndTabItem(); }
                if (BeginTabItem("FourFourFour")) { EndTabItem(); }
                EndTabBar();
            }
            if (show_child)
            {
                BeginChild("child", ImVec2{0, 0}, ImGuiChildFlags_Borders);
                EndChild();
            }
            End();
        }

        TreePop();
    }

    IMGUI_DEMO_MARKER("Layout/Text Clipping");
    if (TreeNode("Text Clipping"))
    {
        static ImVec2 size(100.0, 100.0);
        static ImVec2 offset(30.0, 30.0);
        DragFloat2("size", (f32*)&size, 0.5, 1.0, 200.0, "%.0");
        TextWrapped("(Click and drag to scroll)");

        HelpMarker(
            "(Left) Using PushClipRect():\n"
            "Will alter ImGui hit-testing logic + ImDrawList rendering.\n"
            "(use this if you want your clipping rectangle to affect interactions)\n\n"
            "(Center) Using ImDrawList::PushClipRect():\n"
            "Will alter ImDrawList rendering only.\n"
            "(use this as a shortcut if you are only using ImDrawList calls)\n\n"
            "(Right) Using ImDrawList::AddText() with a fine ClipRect:\n"
            "Will alter only this specific ImDrawList::AddText() rendering.\n"
            "This is often used internally to avoid altering the clipping rectangle and minimize draw calls.");

        for i32 n = 0; n < 3; n++
        {
            if (n > 0)
                SameLine();

            PushID(n);
            InvisibleButton("##canvas", size);
            if (IsItemActive() && IsMouseDragging(ImGuiMouseButton_Left))
            {
                offset.x += GetIO().MouseDelta.x;
                offset.y += GetIO().MouseDelta.y;
            }
            PopID();
            if (!IsItemVisible()) // Skip rendering as ImDrawList elements are not clipped.
                continue;

            p0 := GetItemRectMin();
            p1 := GetItemRectMax();
            text_str := "Line 1 hello\nLine 2 clip me!";
            text_pos := ImVec2{p0.x + offset.x, p0.y + offset.y};
            draw_list := GetWindowDrawList();
            switch (n)
            {
            case 0:
                PushClipRect(p0, p1, true);
                draw_list.AddRectFilled(p0, p1, IM_COL32(90, 90, 120, 255));
                draw_list.AddText(text_pos, IM_COL32_WHITE, text_str);
                PopClipRect();
                break;
            case 1:
                draw_list.PushClipRect(p0, p1, true);
                draw_list.AddRectFilled(p0, p1, IM_COL32(90, 90, 120, 255));
                draw_list.AddText(text_pos, IM_COL32_WHITE, text_str);
                draw_list.PopClipRect();
                break;
            case 2:
                clip_rect := ImVec4{p0.x, p0.y, p1.x, p1.y}; // AddText() takes a ImVec4* here so let's convert.
                draw_list.AddRectFilled(p0, p1, IM_COL32(90, 90, 120, 255));
                draw_list.AddText(GetFont(), GetFontSize(), text_pos, IM_COL32_WHITE, text_str, nil, 0.0, &clip_rect);
                break;
            }
        }

        TreePop();
    }

    IMGUI_DEMO_MARKER("Layout/Overlap Mode");
    if (TreeNode("Overlap Mode"))
    {
        static bool enable_allow_overlap = true;

        HelpMarker(
            "Hit-testing is by default performed in item submission order, which generally is perceived as 'back-to-front'.\n\n"
            "By using SetNextItemAllowOverlap() you can notify that an item may be overlapped by another. "
            "Doing so alters the hovering logic: items using AllowOverlap mode requires an extra frame to accept hovered state.");
        Checkbox("Enable AllowOverlap", &enable_allow_overlap);

        button1_pos := GetCursorScreenPos();
        button2_pos := ImVec2{button1_pos.x + 50.0, button1_pos.y + 50.0};
        if (enable_allow_overlap)
            SetNextItemAllowOverlap();
        Button("Button 1", ImVec2{80, 80});
        SetCursorScreenPos(button2_pos);
        Button("Button 2", ImVec2{80, 80});

        // This is typically used with width-spanning items.
        // (note that Selectable() has a dedicated flag ImGuiSelectableFlags_AllowOverlap, which is a shortcut
        // for using SetNextItemAllowOverlap(). For demo purpose we use SetNextItemAllowOverlap() here.)
        if (enable_allow_overlap)
            SetNextItemAllowOverlap();
        Selectable("Some Selectable", false);
        SameLine();
        SmallButton("++");

        TreePop();
    }
}

//-----------------------------------------------------------------------------
// [SECTION] ShowDemoWindowPopups()
//-----------------------------------------------------------------------------

ShowDemoWindowPopups :: proc()
{
    IMGUI_DEMO_MARKER("Popups");
    if (!CollapsingHeader("Popups & Modal windows"))
        return;

    // The properties of popups windows are:
    // - They block normal mouse hovering detection outside them. (*)
    // - Unless modal, they can be closed by clicking anywhere outside them, or by pressing ESCAPE.
    // - Their visibility state (~bool) is held internally by Dear ImGui instead of being held by the programmer as
    //   we are used to with regular Begin() calls. User can manipulate the visibility state by calling OpenPopup().
    // (*) One can use IsItemHovered(ImGuiHoveredFlags_AllowWhenBlockedByPopup) to bypass it and detect hovering even
    //     when normally blocked by a popup.
    // Those three properties are connected. The library needs to hold their visibility state BECAUSE it can close
    // popups at any time.

    // Typical use for regular windows:
    //   bool my_tool_is_active = false; if (ImGui::Button("Open")) my_tool_is_active = true; [...] if (my_tool_is_active) Begin("My Tool", &my_tool_is_active) { [...] } End();
    // Typical use for popups:
    //   if (ImGui::Button("Open")) ImGui::OpenPopup("MyPopup"); if (ImGui::BeginPopup("MyPopup") { [...] EndPopup(); }

    // With popups we have to go through a library call (here OpenPopup) to manipulate the visibility state.
    // This may be a bit confusing at first but it should quickly make sense. Follow on the examples below.

    IMGUI_DEMO_MARKER("Popups/Popups");
    if (TreeNode("Popups"))
    {
        TextWrapped(
            "When a popup is active, it inhibits interacting with windows that are behind the popup. "
            "Clicking outside the popup closes it.");

        static i32 selected_fish = -1;
        const u8* names[] = { "Bream", "Haddock", "Mackerel", "Pollock", "Tilefish" };
        static bool toggles[] = { true, false, false, false, false };

        // Simple selection popup (if you want to show the current selection inside the Button itself,
        // you may want to build a string using the "###" operator to preserve a constant ID with a variable label)
        if (Button("Select.."))
            OpenPopup("my_select_popup");
        SameLine();
        TextUnformatted(selected_fish == -1 ? "<None>" : names[selected_fish]);
        if (BeginPopup("my_select_popup"))
        {
            SeparatorText("Aquarium");
            for i32 i = 0; i < len(names); i++
                if (Selectable(names[i]))
                    selected_fish = i;
            EndPopup();
        }

        // Showing a menu with toggles
        if (Button("Toggle.."))
            OpenPopup("my_toggle_popup");
        if (BeginPopup("my_toggle_popup"))
        {
            for i32 i = 0; i < len(names); i++
                MenuItem(names[i], "", &toggles[i]);
            if (BeginMenu("Sub-menu"))
            {
                MenuItem("Click me");
                EndMenu();
            }

            Separator();
            Text("Tooltip here");
            SetItemTooltip("I am a tooltip over a popup");

            if (Button("Stacked Popup"))
                OpenPopup("another popup");
            if (BeginPopup("another popup"))
            {
                for i32 i = 0; i < len(names); i++
                    MenuItem(names[i], "", &toggles[i]);
                if (BeginMenu("Sub-menu"))
                {
                    MenuItem("Click me");
                    if (Button("Stacked Popup"))
                        OpenPopup("another popup");
                    if (BeginPopup("another popup"))
                    {
                        Text("I am the last one here.");
                        EndPopup();
                    }
                    EndMenu();
                }
                EndPopup();
            }
            EndPopup();
        }

        // Call the more complete ShowExampleMenuFile which we use in various places of this demo
        if (Button("With a menu.."))
            OpenPopup("my_file_popup");
        if (BeginPopup("my_file_popup", ImGuiWindowFlags_MenuBar))
        {
            if (BeginMenuBar())
            {
                if (BeginMenu("File"))
                {
                    ShowExampleMenuFile();
                    EndMenu();
                }
                if (BeginMenu("Edit"))
                {
                    MenuItem("Dummy");
                    EndMenu();
                }
                EndMenuBar();
            }
            Text("Hello from popup!");
            Button("This is a dummy button..");
            EndPopup();
        }

        TreePop();
    }

    IMGUI_DEMO_MARKER("Popups/Context menus");
    if (TreeNode("Context menus"))
    {
        HelpMarker("\"Context\" functions are simple helpers to associate a Popup to a given Item or Window identifier.");

        // BeginPopupContextItem() is a helper to provide common/simple popup behavior of essentially doing:
        //     if (id == 0)
        //         id = GetItemID(); // Use last item id
        //     if (IsItemHovered() && IsMouseReleased(ImGuiMouseButton_Right))
        //         OpenPopup(id);
        //     return BeginPopup(id);
        // For advanced uses you may want to replicate and customize this code.
        // See more details in BeginPopupContextItem().

        // Example 1
        // When used after an item that has an ID (e.g. Button), we can skip providing an ID to BeginPopupContextItem(),
        // and BeginPopupContextItem() will use the last item ID as the popup ID.
        {
            const u8* names[5] = { "Label1", "Label2", "Label3", "Label4", "Label5" };
            static i32 selected = -1;
            for i32 n = 0; n < 5; n++
            {
                if (Selectable(names[n], selected == n))
                    selected = n;
                if (BeginPopupContextItem()) // <-- use last item id as popup id
                {
                    selected = n;
                    Text("This a popup for \"%s\"!", names[n]);
                    if (Button("Close"))
                        CloseCurrentPopup();
                    EndPopup();
                }
                SetItemTooltip("Right-click to open popup");
            }
        }

        // Example 2
        // Popup on a Text() element which doesn't have an identifier: we need to provide an identifier to BeginPopupContextItem().
        // Using an explicit identifier is also convenient if you want to activate the popups from different locations.
        {
            HelpMarker("Text() elements don't have stable identifiers so we need to provide one.");
            static f32 value = 0.5;
            Text("Value = %.3 <-- (1) right-click this text", value);
            if (BeginPopupContextItem("my popup"))
            {
                if (Selectable("Set to zero")) value = 0.0;
                if (Selectable("Set to PI")) value = 3.1415;
                SetNextItemWidth(-math.F32_MIN);
                DragFloat("##Value", &value, 0.1, 0.0, 0.0);
                EndPopup();
            }

            // We can also use OpenPopupOnItemClick() to toggle the visibility of a given popup.
            // Here we make it that right-clicking this other text element opens the same popup as above.
            // The popup itself will be submitted by the code above.
            Text("(2) Or right-click this text");
            OpenPopupOnItemClick("my popup", ImGuiPopupFlags_MouseButtonRight);

            // Back to square one: manually open the same popup.
            if (Button("(3) Or click this button"))
                OpenPopup("my popup");
        }

        // Example 3
        // When using BeginPopupContextItem() with an implicit identifier (NULL == use last item ID),
        // we need to make sure your item identifier is stable.
        // In this example we showcase altering the item label while preserving its identifier, using the ### operator (see FAQ).
        {
            HelpMarker("Showcase using a popup ID linked to item ID, with the item having a changing label + stable ID using the ### operator.");
            static u8 name[32] = "Label1";
            buf : [64]u8
            sprintf(buf, "Button: %s###Button", name); // ### operator override ID ignoring the preceding label
            Button(buf);
            if (BeginPopupContextItem())
            {
                Text("Edit name:");
                InputText("##edit", name, len(name));
                if (Button("Close"))
                    CloseCurrentPopup();
                EndPopup();
            }
            SameLine(); Text("(<-- right-click here)");
        }

        TreePop();
    }

    IMGUI_DEMO_MARKER("Popups/Modals");
    if (TreeNode("Modals"))
    {
        TextWrapped("Modal windows are like popups but the user cannot close them by clicking outside.");

        if (Button("Delete.."))
            OpenPopup("Delete?");

        // Always center this window when appearing
        center := GetMainViewport()->GetCenter();
        SetNextWindowPos(center, ImGuiCond_Appearing, ImVec2{0.5, 0.5});

        if (BeginPopupModal("Delete?", nil, ImGuiWindowFlags_AlwaysAutoResize))
        {
            Text("All those beautiful files will be deleted.\nThis operation cannot be undone!");
            Separator();

            //static int unused_i = 0;
            //ImGui::Combo("Combo", &unused_i, "Delete\0Delete harder\0");

            static bool dont_ask_me_next_time = false;
            PushStyleVar(ImGuiStyleVar_FramePadding, ImVec2{0, 0});
            Checkbox("Don't ask me next time", &dont_ask_me_next_time);
            PopStyleVar();

            if (Button("OK", ImVec2{120, 0})) { CloseCurrentPopup(); }
            SetItemDefaultFocus();
            SameLine();
            if (Button("Cancel", ImVec2{120, 0})) { CloseCurrentPopup(); }
            EndPopup();
        }

        if (Button("Stacked modals.."))
            OpenPopup("Stacked 1");
        if (BeginPopupModal("Stacked 1", nil, ImGuiWindowFlags_MenuBar))
        {
            if (BeginMenuBar())
            {
                if (BeginMenu("File"))
                {
                    if (MenuItem("Some menu item")) {}
                    EndMenu();
                }
                EndMenuBar();
            }
            Text("Hello from Stacked The First\nUsing style.Colors[ImGuiCol_ModalWindowDimBg] behind it.");

            // Testing behavior of widgets stacking their own regular popups over the modal.
            static i32 item = 1;
            static f32 color[4] = { 0.4, 0.7, 0.0, 0.5 };
            Combo("Combo", &item, "aaaa0x00bbbb0x00cccc0x00dddd0x00eeee0x000x00");
            ColorEdit4("Color", color);

            if (Button("Add another modal.."))
                OpenPopup("Stacked 2");

            // Also demonstrate passing a bool* to BeginPopupModal(), this will create a regular close button which
            // will close the popup. Note that the visibility state of popups is owned by imgui, so the input value
            // of the bool actually doesn't matter here.
            unused_open := true;
            if (BeginPopupModal("Stacked 2", &unused_open))
            {
                Text("Hello from Stacked The Second!");
                ColorEdit4("Color", color); // Allow opening another nested popup
                if (Button("Close"))
                    CloseCurrentPopup();
                EndPopup();
            }

            if (Button("Close"))
                CloseCurrentPopup();
            EndPopup();
        }

        TreePop();
    }

    IMGUI_DEMO_MARKER("Popups/Menus inside a regular window");
    if (TreeNode("Menus inside a regular window"))
    {
        TextWrapped("Below we are testing adding menu items to a regular window. It's rather unusual but should work!");
        Separator();

        MenuItem("Menu item", "CTRL+M");
        if (BeginMenu("Menu inside a regular window"))
        {
            ShowExampleMenuFile();
            EndMenu();
        }
        Separator();
        TreePop();
    }
}

// Dummy data structure that we use for the Table demo.
// (pre-C++11 doesn't allow us to instantiate ImVector<MyItem> template if this structure is defined inside the demo function)
namespace
{
// We are passing our own identifier to TableSetupColumn() to facilitate identifying columns in the sorting code.
// This identifier will be passed down into ImGuiTableSortSpec::ColumnUserID.
// But it is possible to omit the user id parameter of TableSetupColumn() and just use the column index instead! (ImGuiTableSortSpec::ColumnIndex)
// If you don't use sorting, you will generally never care about giving column an ID!
MyItemColumnID :: enum i32
{
    ID,
    Name,
    Action,
    Quantity,
    Description
};

MyItem :: struct
{
    ID : i32,
    Name : ^u8,
    Quantity : i32,

    // We have a problem which is affecting _only this demo_ and should not affect your code:
    // As we don't rely on std:: or other third-party library to compile dear imgui, we only have reliable access to qsort(),
    // however qsort doesn't allow passing user data to comparing function.
    // As a workaround, we are storing the sort specs in a static/global for the comparing function to access.
    // In your own use case you would probably pass the sort specs to your sorting/comparing functions directly and not use a global.
    // We could technically call ImGui::TableGetSortSpecs() in CompareWithSortSpecs(), but considering that this function is called
    // very often by the sorting algorithm it would be a little wasteful.
    static const ImGuiTableSortSpecs* s_current_sort_specs;

    static void SortWithSortSpecs(ImGuiTableSortSpecs* sort_specs, MyItem* items, i32 items_count)
    {
        s_current_sort_specs = sort_specs; // Store in variable accessible by the sort function.
        if (items_count > 1)
            qsort(items, cast(ast) ast) _countcounte_of(items[0]), MyItem::CompareWithSortSpecs);
        s_current_sort_specs = nil;
    }

    // Compare function to be used by qsort()
    static i32 IMGUI_CDECL CompareWithSortSpecs(const rawptr lhs, const rawptr rhs)
    {
        a := (const MyItem*)lhs;
        b := (const MyItem*)rhs;
        for i32 n = 0; n < s_current_sort_specs.SpecsCount; n++
        {
            // Here we identify columns using the ColumnUserID value that we ourselves passed to TableSetupColumn()
            // We could also choose to identify columns based on their index (sort_spec->ColumnIndex), which is simpler!
            sort_spec := &s_current_sort_specs.Specs[n];
            delta := 0;
            switch (sort_spec.ColumnUserID)
            {
            case MyItemColumnID_ID:             delta = (a.ID - b.ID);                break;
            case MyItemColumnID_Name:           delta = (strcmp(a.Name, b.Name));     break;
            case MyItemColumnID_Quantity:       delta = (a.Quantity - b.Quantity);    break;
            case MyItemColumnID_Description:    delta = (strcmp(a.Name, b.Name));     break;
            case: assert(false) break;
            }
            if (delta > 0)
                return (sort_spec.SortDirection == ImGuiSortDirection_Ascending) ? +1 : -1;
            if (delta < 0)
                return (sort_spec.SortDirection == ImGuiSortDirection_Ascending) ? -1 : +1;
        }

        // qsort() is instable so always return a way to differenciate items.
        // Your own compare function may want to avoid fallback on implicit sort specs.
        // e.g. a Name compare if it wasn't already part of the sort specs.
        return (a.ID - b.ID);
    }
};
const ImGuiTableSortSpecs* MyItem::s_current_sort_specs = nil;
}

// Make the UI compact because there are so many fields
PushStyleCompact :: proc()
{
    ImGuiStyle& style = GetStyle();
    PushStyleVarY(ImGuiStyleVar_FramePadding, (f32)(i32)(style.FramePadding.y * 0.60));
    PushStyleVarY(ImGuiStyleVar_ItemSpacing, (f32)(i32)(style.ItemSpacing.y * 0.60));
}

PopStyleCompact :: proc()
{
    PopStyleVar(2);
}

// Show a combo box with a choice of sizing policies
EditTableSizingFlags :: proc(p_flags : ^ImGuiTableFlags)
{
    struct EnumDesc { ImGuiTableFlags Value; const u8* Name; const u8* Tooltip; };
    static const EnumDesc policies[] =
    {
        { ImGuiTableFlags_None,               "Default",                            "Use default sizing policy:\n- ImGuiTableFlags_SizingFixedFit if ScrollX is on or if host window has ImGuiWindowFlags_AlwaysAutoResize.\n- ImGuiTableFlags_SizingStretchSame otherwise." },
        { ImGuiTableFlags_SizingFixedFit,     "ImGuiTableFlags_SizingFixedFit",     "Columns default to _WidthFixed (if resizable) or _WidthAuto (if not resizable), matching contents width." },
        { ImGuiTableFlags_SizingFixedSame,    "ImGuiTableFlags_SizingFixedSame",    "Columns are all the same width, matching the maximum contents width.\nImplicitly disable ImGuiTableFlags_Resizable and enable ImGuiTableFlags_NoKeepColumnsVisible." },
        { ImGuiTableFlags_SizingStretchProp,  "ImGuiTableFlags_SizingStretchProp",  "Columns default to _WidthStretch with weights proportional to their widths." },
        { ImGuiTableFlags_SizingStretchSame,  "ImGuiTableFlags_SizingStretchSame",  "Columns default to _WidthStretch with same weights." }
    };
    idx : i32
    for idx = 0; idx < len(policies); idx++
        if (policies[idx].Value == (*p_flags & ImGuiTableFlags_SizingMask_))
            break;
    preview_text := (idx < len(policies)) ? policies[idx].Name + (idx > 0 ? strlen("ImGuiTableFlags") : 0) : "";
    if (BeginCombo("Sizing Policy", preview_text))
    {
        for i32 n = 0; n < len(policies); n++
            if (Selectable(policies[n].Name, idx == n))
                p_flags^ = (*p_flags & ~ImGuiTableFlags_SizingMask_) | policies[n].Value;
        EndCombo();
    }
    SameLine();
    TextDisabled("(?)");
    if (BeginItemTooltip())
    {
        PushTextWrapPos(GetFontSize() * 50.0);
        for i32 m = 0; m < len(policies); m++
        {
            Separator();
            Text("%s:", policies[m].Name);
            Separator();
            SetCursorPosX(GetCursorPosX() + GetStyle().IndentSpacing * 0.5);
            TextUnformatted(policies[m].Tooltip);
        }
        PopTextWrapPos();
        EndTooltip();
    }
}

EditTableColumnsFlags :: proc(p_flags : ^ImGuiTableColumnFlags)
{
    CheckboxFlags("_Disabled", p_flags, ImGuiTableColumnFlags_Disabled); SameLine(); HelpMarker("Master disable flag (also hide from context menu)");
    CheckboxFlags("_DefaultHide", p_flags, ImGuiTableColumnFlags_DefaultHide);
    CheckboxFlags("_DefaultSort", p_flags, ImGuiTableColumnFlags_DefaultSort);
    if (CheckboxFlags("_WidthStretch", p_flags, ImGuiTableColumnFlags_WidthStretch))
        *p_flags &= ~(ImGuiTableColumnFlags_WidthMask_ ^ ImGuiTableColumnFlags_WidthStretch);
    if (CheckboxFlags("_WidthFixed", p_flags, ImGuiTableColumnFlags_WidthFixed))
        *p_flags &= ~(ImGuiTableColumnFlags_WidthMask_ ^ ImGuiTableColumnFlags_WidthFixed);
    CheckboxFlags("_NoResize", p_flags, ImGuiTableColumnFlags_NoResize);
    CheckboxFlags("_NoReorder", p_flags, ImGuiTableColumnFlags_NoReorder);
    CheckboxFlags("_NoHide", p_flags, ImGuiTableColumnFlags_NoHide);
    CheckboxFlags("_NoClip", p_flags, ImGuiTableColumnFlags_NoClip);
    CheckboxFlags("_NoSort", p_flags, ImGuiTableColumnFlags_NoSort);
    CheckboxFlags("_NoSortAscending", p_flags, ImGuiTableColumnFlags_NoSortAscending);
    CheckboxFlags("_NoSortDescending", p_flags, ImGuiTableColumnFlags_NoSortDescending);
    CheckboxFlags("_NoHeaderLabel", p_flags, ImGuiTableColumnFlags_NoHeaderLabel);
    CheckboxFlags("_NoHeaderWidth", p_flags, ImGuiTableColumnFlags_NoHeaderWidth);
    CheckboxFlags("_PreferSortAscending", p_flags, ImGuiTableColumnFlags_PreferSortAscending);
    CheckboxFlags("_PreferSortDescending", p_flags, ImGuiTableColumnFlags_PreferSortDescending);
    CheckboxFlags("_IndentEnable", p_flags, ImGuiTableColumnFlags_IndentEnable); SameLine(); HelpMarker("Default for column 0");
    CheckboxFlags("_IndentDisable", p_flags, ImGuiTableColumnFlags_IndentDisable); SameLine(); HelpMarker("Default for column >0");
    CheckboxFlags("_AngledHeader", p_flags, ImGuiTableColumnFlags_AngledHeader);
}

ShowTableColumnsStatusFlags :: proc(flags : ImGuiTableColumnFlags)
{
    CheckboxFlags("_IsEnabled", &flags, ImGuiTableColumnFlags_IsEnabled);
    CheckboxFlags("_IsVisible", &flags, ImGuiTableColumnFlags_IsVisible);
    CheckboxFlags("_IsSorted", &flags, ImGuiTableColumnFlags_IsSorted);
    CheckboxFlags("_IsHovered", &flags, ImGuiTableColumnFlags_IsHovered);
}

//-----------------------------------------------------------------------------
// [SECTION] ShowDemoWindowTables()
//-----------------------------------------------------------------------------

ShowDemoWindowTables :: proc()
{
    //ImGui::SetNextItemOpen(true, ImGuiCond_Once);
    IMGUI_DEMO_MARKER("Tables");
    if (!CollapsingHeader("Tables & Columns"))
        return;

    // Using those as a base value to create width/height that are factor of the size of our font
    TEXT_BASE_WIDTH := CalcTextSize("A").x;
    TEXT_BASE_HEIGHT := GetTextLineHeightWithSpacing();

    PushID("Tables");

    open_action := -1;
    if (Button("Expand all"))
        open_action = 1;
    SameLine();
    if (Button("Collapse all"))
        open_action = 0;
    SameLine();

    // Options
    static bool disable_indent = false;
    Checkbox("Disable tree indentation", &disable_indent);
    SameLine();
    HelpMarker("Disable the indenting of tree nodes so demo tables can use the full window width.");
    Separator();
    if (disable_indent)
        PushStyleVar(ImGuiStyleVar_IndentSpacing, 0.0);

    // About Styling of tables
    // Most settings are configured on a per-table basis via the flags passed to BeginTable() and TableSetupColumns APIs.
    // There are however a few settings that a shared and part of the ImGuiStyle structure:
    //   style.CellPadding                          // Padding within each cell
    //   style.Colors[ImGuiCol_TableHeaderBg]       // Table header background
    //   style.Colors[ImGuiCol_TableBorderStrong]   // Table outer and header borders
    //   style.Colors[ImGuiCol_TableBorderLight]    // Table inner borders
    //   style.Colors[ImGuiCol_TableRowBg]          // Table row background when ImGuiTableFlags_RowBg is enabled (even rows)
    //   style.Colors[ImGuiCol_TableRowBgAlt]       // Table row background when ImGuiTableFlags_RowBg is enabled (odds rows)

    // Demos
    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Basic");
    if (TreeNode("Basic"))
    {
        // Here we will showcase three different ways to output a table.
        // They are very simple variations of a same thing!

        // [Method 1] Using TableNextRow() to create a new row, and TableSetColumnIndex() to select the column.
        // In many situations, this is the most flexible and easy to use pattern.
        HelpMarker("Using TableNextRow() + calling TableSetColumnIndex() _before_ each cell, in a loop.");
        if (BeginTable("table1", 3))
        {
            for i32 row = 0; row < 4; row++
            {
                TableNextRow();
                for i32 column = 0; column < 3; column++
                {
                    TableSetColumnIndex(column);
                    Text("Row %d Column %d", row, column);
                }
            }
            EndTable();
        }

        // [Method 2] Using TableNextColumn() called multiple times, instead of using a for loop + TableSetColumnIndex().
        // This is generally more convenient when you have code manually submitting the contents of each column.
        HelpMarker("Using TableNextRow() + calling TableNextColumn() _before_ each cell, manually.");
        if (BeginTable("table2", 3))
        {
            for i32 row = 0; row < 4; row++
            {
                TableNextRow();
                TableNextColumn();
                Text("Row %d", row);
                TableNextColumn();
                Text("Some contents");
                TableNextColumn();
                Text("123.456");
            }
            EndTable();
        }

        // [Method 3] We call TableNextColumn() _before_ each cell. We never call TableNextRow(),
        // as TableNextColumn() will automatically wrap around and create new rows as needed.
        // This is generally more convenient when your cells all contains the same type of data.
        HelpMarker(
            "Only using TableNextColumn(), which tends to be convenient for tables where every cell contains "
            "the same type of contents.\n This is also more similar to the old NextColumn() function of the "
            "Columns API, and provided to facilitate the Columns.Tables API transition.");
        if (BeginTable("table3", 3))
        {
            for i32 item = 0; item < 14; item++
            {
                TableNextColumn();
                Text("Item %d", item);
            }
            EndTable();
        }

        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Borders, background");
    if (TreeNode("Borders, background"))
    {
        // Expose a few Borders related flags interactively
        enum ContentsType { CT_Text, CT_FillButton };
        static ImGuiTableFlags flags = ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg;
        static bool display_headers = false;
        static i32 contents_type = CT_Text;

        PushStyleCompact();
        CheckboxFlags("ImGuiTableFlags_RowBg", &flags, ImGuiTableFlags_RowBg);
        CheckboxFlags("ImGuiTableFlags_Borders", &flags, ImGuiTableFlags_Borders);
        SameLine(); HelpMarker("ImGuiTableFlags_Borders\n = ImGuiTableFlags_BordersInnerV\n | ImGuiTableFlags_BordersOuterV\n | ImGuiTableFlags_BordersInnerH\n | ImGuiTableFlags_BordersOuterH");
        Indent();

        CheckboxFlags("ImGuiTableFlags_BordersH", &flags, ImGuiTableFlags_BordersH);
        Indent();
        CheckboxFlags("ImGuiTableFlags_BordersOuterH", &flags, ImGuiTableFlags_BordersOuterH);
        CheckboxFlags("ImGuiTableFlags_BordersInnerH", &flags, ImGuiTableFlags_BordersInnerH);
        Unindent();

        CheckboxFlags("ImGuiTableFlags_BordersV", &flags, ImGuiTableFlags_BordersV);
        Indent();
        CheckboxFlags("ImGuiTableFlags_BordersOuterV", &flags, ImGuiTableFlags_BordersOuterV);
        CheckboxFlags("ImGuiTableFlags_BordersInnerV", &flags, ImGuiTableFlags_BordersInnerV);
        Unindent();

        CheckboxFlags("ImGuiTableFlags_BordersOuter", &flags, ImGuiTableFlags_BordersOuter);
        CheckboxFlags("ImGuiTableFlags_BordersInner", &flags, ImGuiTableFlags_BordersInner);
        Unindent();

        AlignTextToFramePadding(); Text("Cell contents:");
        SameLine(); RadioButton("Text", &contents_type, CT_Text);
        SameLine(); RadioButton("FillButton", &contents_type, CT_FillButton);
        Checkbox("Display headers", &display_headers);
        CheckboxFlags("ImGuiTableFlags_NoBordersInBody", &flags, ImGuiTableFlags_NoBordersInBody); SameLine(); HelpMarker("Disable vertical borders in columns Body (borders will always appear in Headers");
        PopStyleCompact();

        if (BeginTable("table1", 3, flags))
        {
            // Display headers so we can inspect their interaction with borders
            // (Headers are not the main purpose of this section of the demo, so we are not elaborating on them now. See other sections for details)
            if (display_headers)
            {
                TableSetupColumn("One");
                TableSetupColumn("Two");
                TableSetupColumn("Three");
                TableHeadersRow();
            }

            for i32 row = 0; row < 5; row++
            {
                TableNextRow();
                for i32 column = 0; column < 3; column++
                {
                    TableSetColumnIndex(column);
                    buf : [32]u8
                    sprintf(buf, "Hello %d,%d", column, row);
                    if (contents_type == CT_Text)
                        TextUnformatted(buf);
                    else if (contents_type == CT_FillButton)
                        Button(buf, ImVec2{-math.F32_MIN, 0.0});
                }
            }
            EndTable();
        }
        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Resizable, stretch");
    if (TreeNode("Resizable, stretch"))
    {
        // By default, if we don't enable ScrollX the sizing policy for each column is "Stretch"
        // All columns maintain a sizing weight, and they will occupy all available width.
        static ImGuiTableFlags flags = ImGuiTableFlags_SizingStretchSame | ImGuiTableFlags_Resizable | ImGuiTableFlags_BordersOuter | ImGuiTableFlags_BordersV | ImGuiTableFlags_ContextMenuInBody;
        PushStyleCompact();
        CheckboxFlags("ImGuiTableFlags_Resizable", &flags, ImGuiTableFlags_Resizable);
        CheckboxFlags("ImGuiTableFlags_BordersV", &flags, ImGuiTableFlags_BordersV);
        SameLine(); HelpMarker(
            "Using the _Resizable flag automatically enables the _BordersInnerV flag as well, "
            "this is why the resize borders are still showing when unchecking this.");
        PopStyleCompact();

        if (BeginTable("table1", 3, flags))
        {
            for i32 row = 0; row < 5; row++
            {
                TableNextRow();
                for i32 column = 0; column < 3; column++
                {
                    TableSetColumnIndex(column);
                    Text("Hello %d,%d", column, row);
                }
            }
            EndTable();
        }
        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Resizable, fixed");
    if (TreeNode("Resizable, fixed"))
    {
        // Here we use ImGuiTableFlags_SizingFixedFit (even though _ScrollX is not set)
        // So columns will adopt the "Fixed" policy and will maintain a fixed width regardless of the whole available width (unless table is small)
        // If there is not enough available width to fit all columns, they will however be resized down.
        // FIXME-TABLE: Providing a stretch-on-init would make sense especially for tables which don't have saved settings
        HelpMarker(
            "Using _Resizable + _SizingFixedFit flags.\n"
            "Fixed-width columns generally makes more sense if you want to use horizontal scrolling.\n\n"
            "Double-click a column border to auto-fit the column to its contents.");
        PushStyleCompact();
        static ImGuiTableFlags flags = ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_Resizable | ImGuiTableFlags_BordersOuter | ImGuiTableFlags_BordersV | ImGuiTableFlags_ContextMenuInBody;
        CheckboxFlags("ImGuiTableFlags_NoHostExtendX", &flags, ImGuiTableFlags_NoHostExtendX);
        PopStyleCompact();

        if (BeginTable("table1", 3, flags))
        {
            for i32 row = 0; row < 5; row++
            {
                TableNextRow();
                for i32 column = 0; column < 3; column++
                {
                    TableSetColumnIndex(column);
                    Text("Hello %d,%d", column, row);
                }
            }
            EndTable();
        }
        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Resizable, mixed");
    if (TreeNode("Resizable, mixed"))
    {
        HelpMarker(
            "Using TableSetupColumn() to alter resizing policy on a per-column basis.\n\n"
            "When combining Fixed and Stretch columns, generally you only want one, maybe two trailing columns to use _WidthStretch.");
        static ImGuiTableFlags flags = ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_RowBg | ImGuiTableFlags_Borders | ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Hideable;

        if (BeginTable("table1", 3, flags))
        {
            TableSetupColumn("AAA", ImGuiTableColumnFlags_WidthFixed);
            TableSetupColumn("BBB", ImGuiTableColumnFlags_WidthFixed);
            TableSetupColumn("CCC", ImGuiTableColumnFlags_WidthStretch);
            TableHeadersRow();
            for i32 row = 0; row < 5; row++
            {
                TableNextRow();
                for i32 column = 0; column < 3; column++
                {
                    TableSetColumnIndex(column);
                    Text("%s %d,%d", (column == 2) ? "Stretch" : "Fixed", column, row);
                }
            }
            EndTable();
        }
        if (BeginTable("table2", 6, flags))
        {
            TableSetupColumn("AAA", ImGuiTableColumnFlags_WidthFixed);
            TableSetupColumn("BBB", ImGuiTableColumnFlags_WidthFixed);
            TableSetupColumn("CCC", ImGuiTableColumnFlags_WidthFixed | ImGuiTableColumnFlags_DefaultHide);
            TableSetupColumn("DDD", ImGuiTableColumnFlags_WidthStretch);
            TableSetupColumn("EEE", ImGuiTableColumnFlags_WidthStretch);
            TableSetupColumn("FFF", ImGuiTableColumnFlags_WidthStretch | ImGuiTableColumnFlags_DefaultHide);
            TableHeadersRow();
            for i32 row = 0; row < 5; row++
            {
                TableNextRow();
                for i32 column = 0; column < 6; column++
                {
                    TableSetColumnIndex(column);
                    Text("%s %d,%d", (column >= 3) ? "Stretch" : "Fixed", column, row);
                }
            }
            EndTable();
        }
        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Reorderable, hideable, with headers");
    if (TreeNode("Reorderable, hideable, with headers"))
    {
        HelpMarker(
            "Click and drag column headers to reorder columns.\n\n"
            "Right-click on a header to open a context menu.");
        static ImGuiTableFlags flags = ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Hideable | ImGuiTableFlags_BordersOuter | ImGuiTableFlags_BordersV;
        PushStyleCompact();
        CheckboxFlags("ImGuiTableFlags_Resizable", &flags, ImGuiTableFlags_Resizable);
        CheckboxFlags("ImGuiTableFlags_Reorderable", &flags, ImGuiTableFlags_Reorderable);
        CheckboxFlags("ImGuiTableFlags_Hideable", &flags, ImGuiTableFlags_Hideable);
        CheckboxFlags("ImGuiTableFlags_NoBordersInBody", &flags, ImGuiTableFlags_NoBordersInBody);
        CheckboxFlags("ImGuiTableFlags_NoBordersInBodyUntilResize", &flags, ImGuiTableFlags_NoBordersInBodyUntilResize); SameLine(); HelpMarker("Disable vertical borders in columns Body until hovered for resize (borders will always appear in Headers)");
        CheckboxFlags("ImGuiTableFlags_HighlightHoveredColumn", &flags, ImGuiTableFlags_HighlightHoveredColumn);
        PopStyleCompact();

        if (BeginTable("table1", 3, flags))
        {
            // Submit columns name with TableSetupColumn() and call TableHeadersRow() to create a row with a header in each column.
            // (Later we will show how TableSetupColumn() has other uses, optional flags, sizing weight etc.)
            TableSetupColumn("One");
            TableSetupColumn("Two");
            TableSetupColumn("Three");
            TableHeadersRow();
            for i32 row = 0; row < 6; row++
            {
                TableNextRow();
                for i32 column = 0; column < 3; column++
                {
                    TableSetColumnIndex(column);
                    Text("Hello %d,%d", column, row);
                }
            }
            EndTable();
        }

        // Use outer_size.x == 0.0f instead of default to make the table as tight as possible
        // (only valid when no scrolling and no stretch column)
        if (BeginTable("table2", 3, flags | ImGuiTableFlags_SizingFixedFit, ImVec2{0.0, 0.0}))
        {
            TableSetupColumn("One");
            TableSetupColumn("Two");
            TableSetupColumn("Three");
            TableHeadersRow();
            for i32 row = 0; row < 6; row++
            {
                TableNextRow();
                for i32 column = 0; column < 3; column++
                {
                    TableSetColumnIndex(column);
                    Text("Fixed %d,%d", column, row);
                }
            }
            EndTable();
        }
        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Padding");
    if (TreeNode("Padding"))
    {
        // First example: showcase use of padding flags and effect of BorderOuterV/BorderInnerV on X padding.
        // We don't expose BorderOuterH/BorderInnerH here because they have no effect on X padding.
        HelpMarker(
            "We often want outer padding activated when any using features which makes the edges of a column visible:\n"
            "e.g.:\n"
            "- BorderOuterV\n"
            "- any form of row selection\n"
            "Because of this, activating BorderOuterV sets the default to PadOuterX. "
            "Using PadOuterX or NoPadOuterX you can override the default.\n\n"
            "Actual padding values are using style.CellPadding.\n\n"
            "In this demo we don't show horizontal borders to emphasize how they don't affect default horizontal padding.");

        static ImGuiTableFlags flags1 = ImGuiTableFlags_BordersV;
        PushStyleCompact();
        CheckboxFlags("ImGuiTableFlags_PadOuterX", &flags1, ImGuiTableFlags_PadOuterX);
        SameLine(); HelpMarker("Enable outer-most padding (default if ImGuiTableFlags_BordersOuterV is set)");
        CheckboxFlags("ImGuiTableFlags_NoPadOuterX", &flags1, ImGuiTableFlags_NoPadOuterX);
        SameLine(); HelpMarker("Disable outer-most padding (default if ImGuiTableFlags_BordersOuterV is not set)");
        CheckboxFlags("ImGuiTableFlags_NoPadInnerX", &flags1, ImGuiTableFlags_NoPadInnerX);
        SameLine(); HelpMarker("Disable inner padding between columns (f64 inner padding if BordersOuterV is on, single inner padding if BordersOuterV is off)");
        CheckboxFlags("ImGuiTableFlags_BordersOuterV", &flags1, ImGuiTableFlags_BordersOuterV);
        CheckboxFlags("ImGuiTableFlags_BordersInnerV", &flags1, ImGuiTableFlags_BordersInnerV);
        static bool show_headers = false;
        Checkbox("show_headers", &show_headers);
        PopStyleCompact();

        if (BeginTable("table_padding", 3, flags1))
        {
            if (show_headers)
            {
                TableSetupColumn("One");
                TableSetupColumn("Two");
                TableSetupColumn("Three");
                TableHeadersRow();
            }

            for i32 row = 0; row < 5; row++
            {
                TableNextRow();
                for i32 column = 0; column < 3; column++
                {
                    TableSetColumnIndex(column);
                    if (row == 0)
                    {
                        Text("Avail %.2", GetContentRegionAvail().x);
                    }
                    else
                    {
                        buf : [32]u8
                        sprintf(buf, "Hello %d,%d", column, row);
                        Button(buf, ImVec2{-math.F32_MIN, 0.0});
                    }
                    //if (ImGui::TableGetColumnFlags() & ImGuiTableColumnFlags_IsHovered)
                    //    ImGui::TableSetBgColor(ImGuiTableBgTarget_CellBg, IM_COL32(0, 100, 0, 255));
                }
            }
            EndTable();
        }

        // Second example: set style.CellPadding to (0.0) or a custom value.
        // FIXME-TABLE: Vertical border effectively not displayed the same way as horizontal one...
        HelpMarker("Setting style.CellPadding to (0,0) or a custom value.");
        static ImGuiTableFlags flags2 = ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg;
        static ImVec2 cell_padding(0.0, 0.0);
        static bool show_widget_frame_bg = true;

        PushStyleCompact();
        CheckboxFlags("ImGuiTableFlags_Borders", &flags2, ImGuiTableFlags_Borders);
        CheckboxFlags("ImGuiTableFlags_BordersH", &flags2, ImGuiTableFlags_BordersH);
        CheckboxFlags("ImGuiTableFlags_BordersV", &flags2, ImGuiTableFlags_BordersV);
        CheckboxFlags("ImGuiTableFlags_BordersInner", &flags2, ImGuiTableFlags_BordersInner);
        CheckboxFlags("ImGuiTableFlags_BordersOuter", &flags2, ImGuiTableFlags_BordersOuter);
        CheckboxFlags("ImGuiTableFlags_RowBg", &flags2, ImGuiTableFlags_RowBg);
        CheckboxFlags("ImGuiTableFlags_Resizable", &flags2, ImGuiTableFlags_Resizable);
        Checkbox("show_widget_frame_bg", &show_widget_frame_bg);
        SliderFloat2("CellPadding", &cell_padding.x, 0.0, 10.0, "%.0");
        PopStyleCompact();

        PushStyleVar(ImGuiStyleVar_CellPadding, cell_padding);
        if (BeginTable("table_padding_2", 3, flags2))
        {
            static u8 text_bufs[3 * 5][16]; // Mini text storage for 3x5 cells
            static bool init = true;
            if (!show_widget_frame_bg)
                PushStyleColor(ImGuiCol_FrameBg, 0);
            for i32 cell = 0; cell < 3 * 5; cell++
            {
                TableNextColumn();
                if (init)
                    strcpy(text_bufs[cell], "edit me");
                SetNextItemWidth(-math.F32_MIN);
                PushID(cell);
                InputText("##cell", text_bufs[cell], len(text_bufs[cell]));
                PopID();
            }
            if (!show_widget_frame_bg)
                PopStyleColor();
            init = false;
            EndTable();
        }
        PopStyleVar();

        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Explicit widths");
    if (TreeNode("Sizing policies"))
    {
        static ImGuiTableFlags flags1 = ImGuiTableFlags_BordersV | ImGuiTableFlags_BordersOuterH | ImGuiTableFlags_RowBg | ImGuiTableFlags_ContextMenuInBody;
        PushStyleCompact();
        CheckboxFlags("ImGuiTableFlags_Resizable", &flags1, ImGuiTableFlags_Resizable);
        CheckboxFlags("ImGuiTableFlags_NoHostExtendX", &flags1, ImGuiTableFlags_NoHostExtendX);
        PopStyleCompact();

        static ImGuiTableFlags sizing_policy_flags[4] = { ImGuiTableFlags_SizingFixedFit, ImGuiTableFlags_SizingFixedSame, ImGuiTableFlags_SizingStretchProp, ImGuiTableFlags_SizingStretchSame };
        for i32 table_n = 0; table_n < 4; table_n++
        {
            PushID(table_n);
            SetNextItemWidth(TEXT_BASE_WIDTH * 30);
            EditTableSizingFlags(&sizing_policy_flags[table_n]);

            // To make it easier to understand the different sizing policy,
            // For each policy: we display one table where the columns have equal contents width,
            // and one where the columns have different contents width.
            if (BeginTable("table1", 3, sizing_policy_flags[table_n] | flags1))
            {
                for i32 row = 0; row < 3; row++
                {
                    TableNextRow();
                    TableNextColumn(); Text("Oh dear");
                    TableNextColumn(); Text("Oh dear");
                    TableNextColumn(); Text("Oh dear");
                }
                EndTable();
            }
            if (BeginTable("table2", 3, sizing_policy_flags[table_n] | flags1))
            {
                for i32 row = 0; row < 3; row++
                {
                    TableNextRow();
                    TableNextColumn(); Text("AAAA");
                    TableNextColumn(); Text("BBBBBBBB");
                    TableNextColumn(); Text("CCCCCCCCCCCC");
                }
                EndTable();
            }
            PopID();
        }

        Spacing();
        TextUnformatted("Advanced");
        SameLine();
        HelpMarker(
            "This section allows you to interact and see the effect of various sizing policies "
            "depending on whether Scroll is enabled and the contents of your columns.");

        enum ContentsType { CT_ShowWidth, CT_ShortText, CT_LongText, CT_Button, CT_FillButton, CT_InputText };
        static ImGuiTableFlags flags = ImGuiTableFlags_ScrollY | ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg | ImGuiTableFlags_Resizable;
        static i32 contents_type = CT_ShowWidth;
        static i32 column_count = 3;

        PushStyleCompact();
        PushID("Advanced");
        PushItemWidth(TEXT_BASE_WIDTH * 30);
        EditTableSizingFlags(&flags);
        Combo("Contents", &contents_type, "Show width0x00Short Text0x00Long Text0x00Button0x00Fill Button0x00InputText0x00");
        if (contents_type == CT_FillButton)
        {
            SameLine();
            HelpMarker(
                "Be mindful that using right-alignment (e.g. size.x = -math.F32_MIN) creates a feedback loop "
                "where contents width can feed into auto-column width can feed into contents width.");
        }
        DragInt("Columns", &column_count, 0.1, 1, 64, "%d", ImGuiSliderFlags_AlwaysClamp);
        CheckboxFlags("ImGuiTableFlags_Resizable", &flags, ImGuiTableFlags_Resizable);
        CheckboxFlags("ImGuiTableFlags_PreciseWidths", &flags, ImGuiTableFlags_PreciseWidths);
        SameLine(); HelpMarker("Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.");
        CheckboxFlags("ImGuiTableFlags_ScrollX", &flags, ImGuiTableFlags_ScrollX);
        CheckboxFlags("ImGuiTableFlags_ScrollY", &flags, ImGuiTableFlags_ScrollY);
        CheckboxFlags("ImGuiTableFlags_NoClip", &flags, ImGuiTableFlags_NoClip);
        PopItemWidth();
        PopID();
        PopStyleCompact();

        if (BeginTable("table2", column_count, flags, ImVec2{0.0, TEXT_BASE_HEIGHT * 7}))
        {
            for i32 cell = 0; cell < 10 * column_count; cell++
            {
                TableNextColumn();
                column := TableGetColumnIndex();
                row := TableGetRowIndex();

                PushID(cell);
                label : [32]u8
                static u8 text_buf[32] = "";
                sprintf(label, "Hello %d,%d", column, row);
                switch (contents_type)
                {
                case CT_ShortText:  TextUnformatted(label); break;
                case CT_LongText:   Text("Some %s text %d,%d\nOver two lines..", column == 0 ? "long" : "longeeer", column, row); break;
                case CT_ShowWidth:  Text("W: %.1", GetContentRegionAvail().x); break;
                case CT_Button:     Button(label); break;
                case CT_FillButton: Button(label, ImVec2{-math.F32_MIN, 0.0}); break;
                case CT_InputText:  SetNextItemWidth(-math.F32_MIN); InputText("##", text_buf, len(text_buf)); break;
                }
                PopID();
            }
            EndTable();
        }
        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Vertical scrolling, with clipping");
    if (TreeNode("Vertical scrolling, with clipping"))
    {
        HelpMarker(
            "Here we activate ScrollY, which will create a child window container to allow hosting scrollable contents.\n\n"
            "We also demonstrate using ImGuiListClipper to virtualize the submission of many items.");
        static ImGuiTableFlags flags = ImGuiTableFlags_ScrollY | ImGuiTableFlags_RowBg | ImGuiTableFlags_BordersOuter | ImGuiTableFlags_BordersV | ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Hideable;

        PushStyleCompact();
        CheckboxFlags("ImGuiTableFlags_ScrollY", &flags, ImGuiTableFlags_ScrollY);
        PopStyleCompact();

        // When using ScrollX or ScrollY we need to specify a size for our table container!
        // Otherwise by default the table will fit all available space, like a BeginChild() call.
        outer_size := ImVec2{0.0, TEXT_BASE_HEIGHT * 8};
        if (BeginTable("table_scrolly", 3, flags, outer_size))
        {
            TableSetupScrollFreeze(0, 1); // Make top row always visible
            TableSetupColumn("One", ImGuiTableColumnFlags_None);
            TableSetupColumn("Two", ImGuiTableColumnFlags_None);
            TableSetupColumn("Three", ImGuiTableColumnFlags_None);
            TableHeadersRow();

            // Demonstrate using clipper for large vertical lists
            clipper : ImGuiListClipper
            clipper.Begin(1000);
            for clipper.Step()
            {
                for i32 row = clipper.DisplayStart; row < clipper.DisplayEnd; row++
                {
                    TableNextRow();
                    for i32 column = 0; column < 3; column++
                    {
                        TableSetColumnIndex(column);
                        Text("Hello %d,%d", column, row);
                    }
                }
            }
            EndTable();
        }
        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Horizontal scrolling");
    if (TreeNode("Horizontal scrolling"))
    {
        HelpMarker(
            "When ScrollX is enabled, the default sizing policy becomes ImGuiTableFlags_SizingFixedFit, "
            "as automatically stretching columns doesn't make much sense with horizontal scrolling.\n\n"
            "Also note that as of the current version, you will almost always want to enable ScrollY along with ScrollX, "
            "because the container window won't automatically extend vertically to fix contents "
            "(this may be improved in future versions).");
        static ImGuiTableFlags flags = ImGuiTableFlags_ScrollX | ImGuiTableFlags_ScrollY | ImGuiTableFlags_RowBg | ImGuiTableFlags_BordersOuter | ImGuiTableFlags_BordersV | ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Hideable;
        static i32 freeze_cols = 1;
        static i32 freeze_rows = 1;

        PushStyleCompact();
        CheckboxFlags("ImGuiTableFlags_Resizable", &flags, ImGuiTableFlags_Resizable);
        CheckboxFlags("ImGuiTableFlags_ScrollX", &flags, ImGuiTableFlags_ScrollX);
        CheckboxFlags("ImGuiTableFlags_ScrollY", &flags, ImGuiTableFlags_ScrollY);
        SetNextItemWidth(GetFrameHeight());
        DragInt("freeze_cols", &freeze_cols, 0.2, 0, 9, nil, ImGuiSliderFlags_NoInput);
        SetNextItemWidth(GetFrameHeight());
        DragInt("freeze_rows", &freeze_rows, 0.2, 0, 9, nil, ImGuiSliderFlags_NoInput);
        PopStyleCompact();

        // When using ScrollX or ScrollY we need to specify a size for our table container!
        // Otherwise by default the table will fit all available space, like a BeginChild() call.
        outer_size := ImVec2{0.0, TEXT_BASE_HEIGHT * 8};
        if (BeginTable("table_scrollx", 7, flags, outer_size))
        {
            TableSetupScrollFreeze(freeze_cols, freeze_rows);
            TableSetupColumn("Line #", ImGuiTableColumnFlags_NoHide); // Make the first column not hideable to match our use of TableSetupScrollFreeze()
            TableSetupColumn("One");
            TableSetupColumn("Two");
            TableSetupColumn("Three");
            TableSetupColumn("Four");
            TableSetupColumn("Five");
            TableSetupColumn("Six");
            TableHeadersRow();
            for i32 row = 0; row < 20; row++
            {
                TableNextRow();
                for i32 column = 0; column < 7; column++
                {
                    // Both TableNextColumn() and TableSetColumnIndex() return true when a column is visible or performing width measurement.
                    // Because here we know that:
                    // - A) all our columns are contributing the same to row height
                    // - B) column 0 is always visible,
                    // We only always submit this one column and can skip others.
                    // More advanced per-column clipping behaviors may benefit from polling the status flags via TableGetColumnFlags().
                    if (!TableSetColumnIndex(column) && column > 0)
                        continue;
                    if (column == 0)
                        Text("Line %d", row);
                    else
                        Text("Hello world %d,%d", column, row);
                }
            }
            EndTable();
        }

        Spacing();
        TextUnformatted("Stretch + ScrollX");
        SameLine();
        HelpMarker(
            "Showcase using Stretch columns + ScrollX together: "
            "this is rather unusual and only makes sense when specifying an 'inner_width' for the table!\n"
            "Without an explicit value, inner_width is == outer_size.x and therefore using Stretch columns "
            "along with ScrollX doesn't make sense.");
        static ImGuiTableFlags flags2 = ImGuiTableFlags_SizingStretchSame | ImGuiTableFlags_ScrollX | ImGuiTableFlags_ScrollY | ImGuiTableFlags_BordersOuter | ImGuiTableFlags_RowBg | ImGuiTableFlags_ContextMenuInBody;
        static f32 inner_width = 1000.0;
        PushStyleCompact();
        PushID("flags3");
        PushItemWidth(TEXT_BASE_WIDTH * 30);
        CheckboxFlags("ImGuiTableFlags_ScrollX", &flags2, ImGuiTableFlags_ScrollX);
        DragFloat("inner_width", &inner_width, 1.0, 0.0, math.F32_MAX, "%.1");
        PopItemWidth();
        PopID();
        PopStyleCompact();
        if (BeginTable("table2", 7, flags2, outer_size, inner_width))
        {
            for i32 cell = 0; cell < 20 * 7; cell++
            {
                TableNextColumn();
                Text("Hello world %d,%d", TableGetColumnIndex(), TableGetRowIndex());
            }
            EndTable();
        }
        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Columns flags");
    if (TreeNode("Columns flags"))
    {
        // Create a first table just to show all the options/flags we want to make visible in our example!
        column_count := 3;
        const u8* column_names[column_count] = { "One", "Two", "Three" };
        static ImGuiTableColumnFlags column_flags[column_count] = { ImGuiTableColumnFlags_DefaultSort, ImGuiTableColumnFlags_None, ImGuiTableColumnFlags_DefaultHide };
        static ImGuiTableColumnFlags column_flags_out[column_count] = { 0, 0, 0 }; // Output from TableGetColumnFlags()

        if (BeginTable("table_columns_flags_checkboxes", column_count, ImGuiTableFlags_None))
        {
            PushStyleCompact();
            for i32 column = 0; column < column_count; column++
            {
                TableNextColumn();
                PushID(column);
                AlignTextToFramePadding(); // FIXME-TABLE: Workaround for wrong text baseline propagation across columns
                Text("'%s'", column_names[column]);
                Spacing();
                Text("Input flags:");
                EditTableColumnsFlags(&column_flags[column]);
                Spacing();
                Text("Output flags:");
                BeginDisabled();
                ShowTableColumnsStatusFlags(column_flags_out[column]);
                EndDisabled();
                PopID();
            }
            PopStyleCompact();
            EndTable();
        }

        // Create the real table we care about for the example!
        // We use a scrolling table to be able to showcase the difference between the _IsEnabled and _IsVisible flags above,
        // otherwise in a non-scrolling table columns are always visible (unless using ImGuiTableFlags_NoKeepColumnsVisible
        // + resizing the parent window down).
        const ImGuiTableFlags flags
            = ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_ScrollX | ImGuiTableFlags_ScrollY
            | ImGuiTableFlags_RowBg | ImGuiTableFlags_BordersOuter | ImGuiTableFlags_BordersV
            | ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Hideable | ImGuiTableFlags_Sortable;
        outer_size := ImVec2{0.0, TEXT_BASE_HEIGHT * 9};
        if (BeginTable("table_columns_flags", column_count, flags, outer_size))
        {
            has_angled_header := false;
            for i32 column = 0; column < column_count; column++
            {
                has_angled_header |= (column_flags[column] & ImGuiTableColumnFlags_AngledHeader) != 0;
                TableSetupColumn(column_names[column], column_flags[column]);
            }
            if (has_angled_header)
                TableAngledHeadersRow();
            TableHeadersRow();
            for i32 column = 0; column < column_count; column++
                column_flags_out[column] = TableGetColumnFlags(column);
            indent_step := (f32)(cast(ast) ast) BASE_WIDTHWIDTH;
            for i32 row = 0; row < 8; row++
            {
                // Add some indentation to demonstrate usage of per-column IndentEnable/IndentDisable flags.
                Indent(indent_step);
                TableNextRow();
                for i32 column = 0; column < column_count; column++
                {
                    TableSetColumnIndex(column);
                    Text("%s %s", (column == 0) ? "Indented" : "Hello", TableGetColumnName(column));
                }
            }
            Unindent(indent_step * 8.0);

            EndTable();
        }
        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Columns widths");
    if (TreeNode("Columns widths"))
    {
        HelpMarker("Using TableSetupColumn() to setup default width.");

        static ImGuiTableFlags flags1 = ImGuiTableFlags_Borders | ImGuiTableFlags_NoBordersInBodyUntilResize;
        PushStyleCompact();
        CheckboxFlags("ImGuiTableFlags_Resizable", &flags1, ImGuiTableFlags_Resizable);
        CheckboxFlags("ImGuiTableFlags_NoBordersInBodyUntilResize", &flags1, ImGuiTableFlags_NoBordersInBodyUntilResize);
        PopStyleCompact();
        if (BeginTable("table1", 3, flags1))
        {
            // We could also set ImGuiTableFlags_SizingFixedFit on the table and all columns will default to ImGuiTableColumnFlags_WidthFixed.
            TableSetupColumn("one", ImGuiTableColumnFlags_WidthFixed, 100.0); // Default to 100.0f
            TableSetupColumn("two", ImGuiTableColumnFlags_WidthFixed, 200.0); // Default to 200.0f
            TableSetupColumn("three", ImGuiTableColumnFlags_WidthFixed);       // Default to auto
            TableHeadersRow();
            for i32 row = 0; row < 4; row++
            {
                TableNextRow();
                for i32 column = 0; column < 3; column++
                {
                    TableSetColumnIndex(column);
                    if (row == 0)
                        Text("(w: %5.1)", GetContentRegionAvail().x);
                    else
                        Text("Hello %d,%d", column, row);
                }
            }
            EndTable();
        }

        HelpMarker(
            "Using TableSetupColumn() to setup explicit width.\n\nUnless _NoKeepColumnsVisible is set, "
            "fixed columns with set width may still be shrunk down if there's not enough space in the host.");

        static ImGuiTableFlags flags2 = ImGuiTableFlags_None;
        PushStyleCompact();
        CheckboxFlags("ImGuiTableFlags_NoKeepColumnsVisible", &flags2, ImGuiTableFlags_NoKeepColumnsVisible);
        CheckboxFlags("ImGuiTableFlags_BordersInnerV", &flags2, ImGuiTableFlags_BordersInnerV);
        CheckboxFlags("ImGuiTableFlags_BordersOuterV", &flags2, ImGuiTableFlags_BordersOuterV);
        PopStyleCompact();
        if (BeginTable("table2", 4, flags2))
        {
            // We could also set ImGuiTableFlags_SizingFixedFit on the table and then all columns
            // will default to ImGuiTableColumnFlags_WidthFixed.
            TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed, 100.0);
            TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 15.0);
            TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 30.0);
            TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 15.0);
            for i32 row = 0; row < 5; row++
            {
                TableNextRow();
                for i32 column = 0; column < 4; column++
                {
                    TableSetColumnIndex(column);
                    if (row == 0)
                        Text("(w: %5.1)", GetContentRegionAvail().x);
                    else
                        Text("Hello %d,%d", column, row);
                }
            }
            EndTable();
        }
        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Nested tables");
    if (TreeNode("Nested tables"))
    {
        HelpMarker("This demonstrates embedding a table into another table cell.");

        if (BeginTable("table_nested1", 2, ImGuiTableFlags_Borders | ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Hideable))
        {
            TableSetupColumn("A0");
            TableSetupColumn("A1");
            TableHeadersRow();

            TableNextColumn();
            Text("A0 Row 0");
            {
                rows_height := TEXT_BASE_HEIGHT * 2;
                if (BeginTable("table_nested2", 2, ImGuiTableFlags_Borders | ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Hideable))
                {
                    TableSetupColumn("B0");
                    TableSetupColumn("B1");
                    TableHeadersRow();

                    TableNextRow(ImGuiTableRowFlags_None, rows_height);
                    TableNextColumn();
                    Text("B0 Row 0");
                    TableNextColumn();
                    Text("B1 Row 0");
                    TableNextRow(ImGuiTableRowFlags_None, rows_height);
                    TableNextColumn();
                    Text("B0 Row 1");
                    TableNextColumn();
                    Text("B1 Row 1");

                    EndTable();
                }
            }
            TableNextColumn(); Text("A1 Row 0");
            TableNextColumn(); Text("A0 Row 1");
            TableNextColumn(); Text("A1 Row 1");
            EndTable();
        }
        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Row height");
    if (TreeNode("Row height"))
    {
        HelpMarker(
            "You can pass a 'min_row_height' to TableNextRow().\n\nRows are padded with 'style.CellPadding.y' on top and bottom, "
            "so effectively the minimum row height will always be >= 'style.CellPadding.y * 2.0'.\n\n"
            "We cannot honor a _maximum_ row height as that would require a unique clipping rectangle per row.");
        if (BeginTable("table_row_height", 1, ImGuiTableFlags_Borders))
        {
            for i32 row = 0; row < 8; row++
            {
                min_row_height := (f32)(i32)(TEXT_BASE_HEIGHT * 0.30 * row);
                TableNextRow(ImGuiTableRowFlags_None, min_row_height);
                TableNextColumn();
                Text("min_row_height = %.2", min_row_height);
            }
            EndTable();
        }

        HelpMarker(
            "Showcase using SameLine(0,0) to share Current Line Height between cells.\n\n"
            "Please note that Tables Row Height is not the same thing as Current Line Height, "
            "as a table cell may contains multiple lines.");
        if (BeginTable("table_share_lineheight", 2, ImGuiTableFlags_Borders))
        {
            TableNextRow();
            TableNextColumn();
            ColorButton("##1", ImVec4{0.13, 0.26, 0.40, 1.0}, ImGuiColorEditFlags_None, ImVec2{40, 40});
            TableNextColumn();
            Text("Line 1");
            Text("Line 2");

            TableNextRow();
            TableNextColumn();
            ColorButton("##2", ImVec4{0.13, 0.26, 0.40, 1.0}, ImGuiColorEditFlags_None, ImVec2{40, 40});
            TableNextColumn();
            SameLine(0.0, 0.0); // Reuse line height from previous column
            Text("Line 1, with SameLine(0,0)");
            Text("Line 2");

            EndTable();
        }

        HelpMarker("Showcase altering CellPadding.y between rows. Note that CellPadding.x is locked for the entire table.");
        if (BeginTable("table_changing_cellpadding_y", 1, ImGuiTableFlags_Borders))
        {
            ImGuiStyle& style = GetStyle();
            for i32 row = 0; row < 8; row++
            {
                if ((row % 3) == 2)
                    PushStyleVarY(ImGuiStyleVar_CellPadding, 20.0);
                TableNextRow(ImGuiTableRowFlags_None);
                TableNextColumn();
                Text("CellPadding.y = %.2", style.CellPadding.y);
                if ((row % 3) == 2)
                    PopStyleVar();
            }
            EndTable();
        }

        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Outer size");
    if (TreeNode("Outer size"))
    {
        // Showcasing use of ImGuiTableFlags_NoHostExtendX and ImGuiTableFlags_NoHostExtendY
        // Important to that note how the two flags have slightly different behaviors!
        Text("Using NoHostExtendX and NoHostExtendY:");
        PushStyleCompact();
        static ImGuiTableFlags flags = ImGuiTableFlags_Borders | ImGuiTableFlags_Resizable | ImGuiTableFlags_ContextMenuInBody | ImGuiTableFlags_RowBg | ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_NoHostExtendX;
        CheckboxFlags("ImGuiTableFlags_NoHostExtendX", &flags, ImGuiTableFlags_NoHostExtendX);
        SameLine(); HelpMarker("Make outer width auto-fit to columns, overriding outer_size.x value.\n\nOnly available when ScrollX/ScrollY are disabled and Stretch columns are not used.");
        CheckboxFlags("ImGuiTableFlags_NoHostExtendY", &flags, ImGuiTableFlags_NoHostExtendY);
        SameLine(); HelpMarker("Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit).\n\nOnly available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.");
        PopStyleCompact();

        outer_size := ImVec2{0.0, TEXT_BASE_HEIGHT * 5.5};
        if (BeginTable("table1", 3, flags, outer_size))
        {
            for i32 row = 0; row < 10; row++
            {
                TableNextRow();
                for i32 column = 0; column < 3; column++
                {
                    TableNextColumn();
                    Text("Cell %d,%d", column, row);
                }
            }
            EndTable();
        }
        SameLine();
        Text("Hello!");

        Spacing();

        Text("Using explicit size:");
        if (BeginTable("table2", 3, ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg, ImVec2{TEXT_BASE_WIDTH * 30, 0.0}))
        {
            for i32 row = 0; row < 5; row++
            {
                TableNextRow();
                for i32 column = 0; column < 3; column++
                {
                    TableNextColumn();
                    Text("Cell %d,%d", column, row);
                }
            }
            EndTable();
        }
        SameLine();
        if (BeginTable("table3", 3, ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg, ImVec2{TEXT_BASE_WIDTH * 30, 0.0}))
        {
            for i32 row = 0; row < 3; row++
            {
                TableNextRow(0, TEXT_BASE_HEIGHT * 1.5);
                for i32 column = 0; column < 3; column++
                {
                    TableNextColumn();
                    Text("Cell %d,%d", column, row);
                }
            }
            EndTable();
        }

        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Background color");
    if (TreeNode("Background color"))
    {
        static ImGuiTableFlags flags = ImGuiTableFlags_RowBg;
        static i32 row_bg_type = 1;
        static i32 row_bg_target = 1;
        static i32 cell_bg_type = 1;

        PushStyleCompact();
        CheckboxFlags("ImGuiTableFlags_Borders", &flags, ImGuiTableFlags_Borders);
        CheckboxFlags("ImGuiTableFlags_RowBg", &flags, ImGuiTableFlags_RowBg);
        SameLine(); HelpMarker("ImGuiTableFlags_RowBg automatically sets RowBg0 to alternative colors pulled from the Style.");
        Combo("row bg type", (i32*)&row_bg_type, "None0x00Red0x00Gradient0x00");
        Combo("row bg target", (i32*)&row_bg_target, "RowBg00x00RowBg10x00"); SameLine(); HelpMarker("Target RowBg0 to override the alternating odd/even colors,\nTarget RowBg1 to blend with them.");
        Combo("cell bg type", (i32*)&cell_bg_type, "None0x00Blue0x00"); SameLine(); HelpMarker("We are colorizing cells to B1.C2 here.");
        assert(row_bg_type >= 0 && row_bg_type <= 2);
        assert(row_bg_target >= 0 && row_bg_target <= 1);
        assert(cell_bg_type >= 0 && cell_bg_type <= 1);
        PopStyleCompact();

        if (BeginTable("table1", 5, flags))
        {
            for i32 row = 0; row < 6; row++
            {
                TableNextRow();

                // Demonstrate setting a row background color with 'ImGui::TableSetBgColor(ImGuiTableBgTarget_RowBgX, ...)'
                // We use a transparent color so we can see the one behind in case our target is RowBg1 and RowBg0 was already targeted by the ImGuiTableFlags_RowBg flag.
                if (row_bg_type != 0)
                {
                    row_bg_color := GetColorU32(row_bg_type == 1 ? ImVec4{0.7, 0.3, 0.3, 0.65} : ImVec4{0.2 + row * 0.1, 0.2, 0.2, 0.65}); // Flat or Gradient?
                    TableSetBgColor(ImGuiTableBgTarget_RowBg0 + row_bg_target, row_bg_color);
                }

                // Fill cells
                for i32 column = 0; column < 5; column++
                {
                    TableSetColumnIndex(column);
                    Text("%c%c", 'A' + row, '0' + column);

                    // Change background of Cells B1->C2
                    // Demonstrate setting a cell background color with 'ImGui::TableSetBgColor(ImGuiTableBgTarget_CellBg, ...)'
                    // (the CellBg color will be blended over the RowBg and ColumnBg colors)
                    // We can also pass a column number as a third parameter to TableSetBgColor() and do this outside the column loop.
                    if (row >= 1 && row <= 2 && column >= 1 && column <= 2 && cell_bg_type == 1)
                    {
                        cell_bg_color := GetColorU32(ImVec4{0.3, 0.3, 0.7, 0.65});
                        TableSetBgColor(ImGuiTableBgTarget_CellBg, cell_bg_color);
                    }
                }
            }
            EndTable();
        }
        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Tree view");
    if (TreeNode("Tree view"))
    {
        static ImGuiTableFlags flags = ImGuiTableFlags_BordersV | ImGuiTableFlags_BordersOuterH | ImGuiTableFlags_Resizable | ImGuiTableFlags_RowBg | ImGuiTableFlags_NoBordersInBody;

        static ImGuiTreeNodeFlags tree_node_flags = ImGuiTreeNodeFlags_SpanAllColumns;
        CheckboxFlags("ImGuiTreeNodeFlags_SpanFullWidth",  &tree_node_flags, ImGuiTreeNodeFlags_SpanFullWidth);
        CheckboxFlags("ImGuiTreeNodeFlags_SpanTextWidth",  &tree_node_flags, ImGuiTreeNodeFlags_SpanTextWidth);
        CheckboxFlags("ImGuiTreeNodeFlags_SpanAllColumns", &tree_node_flags, ImGuiTreeNodeFlags_SpanAllColumns);

        HelpMarker("See \"Columns flags\" section to configure how indentation is applied to individual columns.");
        if (BeginTable("3ways", 3, flags))
        {
            // The first column will use the default _WidthStretch when ScrollX is Off and _WidthFixed when ScrollX is On
            TableSetupColumn("Name", ImGuiTableColumnFlags_NoHide);
            TableSetupColumn("Size", ImGuiTableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 12.0);
            TableSetupColumn("Type", ImGuiTableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 18.0);
            TableHeadersRow();

            // Simple storage to output a dummy file-system.
            MyTreeNode :: struct
            {
                Name : ^u8,
                Type : ^u8,
                Size : i32,
                ChildIdx : i32,
                ChildCount : i32,
                static void DisplayNode(const MyTreeNode* node, const MyTreeNode* all_nodes)
                {
                    TableNextRow();
                    TableNextColumn();
                    is_folder := (node.ChildCount > 0);
                    if (is_folder)
                    {
                        open := TreeNodeEx(node.Name, tree_node_flags);
                        TableNextColumn();
                        TextDisabled("--");
                        TableNextColumn();
                        TextUnformatted(node.Type);
                        if (open)
                        {
                            for i32 child_n = 0; child_n < node.ChildCount; child_n++
                                DisplayNode(&all_nodes[node.ChildIdx + child_n], all_nodes);
                            TreePop();
                        }
                    }
                    else
                    {
                        TreeNodeEx(node.Name, tree_node_flags | ImGuiTreeNodeFlags_Leaf | ImGuiTreeNodeFlags_Bullet | ImGuiTreeNodeFlags_NoTreePushOnOpen);
                        TableNextColumn();
                        Text("%d", node.Size);
                        TableNextColumn();
                        TextUnformatted(node.Type);
                    }
                }
            };
            static const MyTreeNode nodes[] =
            {
                { "Root",                         "Folder",       -1,       1, 3    }, // 0
                { "Music",                        "Folder",       -1,       4, 2    }, // 1
                { "Textures",                     "Folder",       -1,       6, 3    }, // 2
                { "desktop.ini",                  "System file",  1024,    -1,-1    }, // 3
                { "File1_a.wav",                  "Audio file",   123000,  -1,-1    }, // 4
                { "File1_b.wav",                  "Audio file",   456000,  -1,-1    }, // 5
                { "Image001.png",                 "Image file",   203128,  -1,-1    }, // 6
                { "Copy of Image001.png",         "Image file",   203256,  -1,-1    }, // 7
                { "Copy of Image001 (Final2).png","Image file",   203512,  -1,-1    }, // 8
            };

            MyTreeNode::DisplayNode(&nodes[0], nodes);

            EndTable();
        }
        TreePop();
    }

    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Item width");
    if (TreeNode("Item width"))
    {
        HelpMarker(
            "Showcase using PushItemWidth() and how it is preserved on a per-column basis.\n\n"
            "Note that on auto-resizing non-resizable fixed columns, querying the content width for "
            "e.g. right-alignment doesn't make sense.");
        if (BeginTable("table_item_width", 3, ImGuiTableFlags_Borders))
        {
            TableSetupColumn("small");
            TableSetupColumn("half");
            TableSetupColumn("right-align");
            TableHeadersRow();

            for i32 row = 0; row < 3; row++
            {
                TableNextRow();
                if (row == 0)
                {
                    // Setup ItemWidth once (instead of setting up every time, which is also possible but less efficient)
                    TableSetColumnIndex(0);
                    PushItemWidth(TEXT_BASE_WIDTH * 3.0); // Small
                    TableSetColumnIndex(1);
                    PushItemWidth(-GetContentRegionAvail().x * 0.5);
                    TableSetColumnIndex(2);
                    PushItemWidth(-math.F32_MIN); // Right-aligned
                }

                // Draw our contents
                static f32 dummy_f = 0.0;
                PushID(row);
                TableSetColumnIndex(0);
                SliderFloat("float0", &dummy_f, 0.0, 1.0);
                TableSetColumnIndex(1);
                SliderFloat("float1", &dummy_f, 0.0, 1.0);
                TableSetColumnIndex(2);
                SliderFloat("##float2", &dummy_f, 0.0, 1.0); // No visible label since right-aligned
                PopID();
            }
            EndTable();
        }
        TreePop();
    }

    // Demonstrate using TableHeader() calls instead of TableHeadersRow()
    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Custom headers");
    if (TreeNode("Custom headers"))
    {
        COLUMNS_COUNT := 3;
        if (BeginTable("table_custom_headers", COLUMNS_COUNT, ImGuiTableFlags_Borders | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Hideable))
        {
            TableSetupColumn("Apricot");
            TableSetupColumn("Banana");
            TableSetupColumn("Cherry");

            // Dummy entire-column selection storage
            // FIXME: It would be nice to actually demonstrate full-featured selection using those checkbox.
            static bool column_selected[3] = {};

            // Instead of calling TableHeadersRow() we'll submit custom headers ourselves.
            // (A different approach is also possible:
            //    - Specify ImGuiTableColumnFlags_NoHeaderLabel in some TableSetupColumn() call.
            //    - Call TableHeadersRow() normally. This will submit TableHeader() with no name.
            //    - Then call TableSetColumnIndex() to position yourself in the column and submit your stuff e.g. Checkbox().)
            TableNextRow(ImGuiTableRowFlags_Headers);
            for i32 column = 0; column < COLUMNS_COUNT; column++
            {
                TableSetColumnIndex(column);
                column_name := TableGetColumnName(column); // Retrieve name passed to TableSetupColumn()
                PushID(column);
                PushStyleVar(ImGuiStyleVar_FramePadding, ImVec2{0, 0});
                Checkbox("##checkall", &column_selected[column]);
                PopStyleVar();
                SameLine(0.0, GetStyle().ItemInnerSpacing.x);
                TableHeader(column_name);
                PopID();
            }

            // Submit table contents
            for i32 row = 0; row < 5; row++
            {
                TableNextRow();
                for i32 column = 0; column < 3; column++
                {
                    buf : [32]u8
                    sprintf(buf, "Cell %d,%d", column, row);
                    TableSetColumnIndex(column);
                    Selectable(buf, column_selected[column]);
                }
            }
            EndTable();
        }
        TreePop();
    }

    // Demonstrate using ImGuiTableColumnFlags_AngledHeader flag to create angled headers
    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Angled headers");
    if (TreeNode("Angled headers"))
    {
        const u8* column_names[] = { "Track", "cabasa", "ride", "smash", "tom-hi", "tom-mid", "tom-low", "hihat-o", "hihat-c", "snare-s", "snare-c", "clap", "rim", "kick" };
        columns_count := len(column_names);
        rows_count := 12;

        static ImGuiTableFlags table_flags = ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_ScrollX | ImGuiTableFlags_ScrollY | ImGuiTableFlags_BordersOuter | ImGuiTableFlags_BordersInnerH | ImGuiTableFlags_Hideable | ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_HighlightHoveredColumn;
        static ImGuiTableColumnFlags column_flags = ImGuiTableColumnFlags_AngledHeader | ImGuiTableColumnFlags_WidthFixed;
        static bool bools[columns_count * rows_count] = {}; // Dummy storage selection storage
        static i32 frozen_cols = 1;
        static i32 frozen_rows = 2;
        CheckboxFlags("_ScrollX", &table_flags, ImGuiTableFlags_ScrollX);
        CheckboxFlags("_ScrollY", &table_flags, ImGuiTableFlags_ScrollY);
        CheckboxFlags("_Resizable", &table_flags, ImGuiTableFlags_Resizable);
        CheckboxFlags("_Sortable", &table_flags, ImGuiTableFlags_Sortable);
        CheckboxFlags("_NoBordersInBody", &table_flags, ImGuiTableFlags_NoBordersInBody);
        CheckboxFlags("_HighlightHoveredColumn", &table_flags, ImGuiTableFlags_HighlightHoveredColumn);
        SetNextItemWidth(GetFontSize() * 8);
        SliderInt("Frozen columns", &frozen_cols, 0, 2);
        SetNextItemWidth(GetFontSize() * 8);
        SliderInt("Frozen rows", &frozen_rows, 0, 2);
        CheckboxFlags("Disable header contributing to column width", &column_flags, ImGuiTableColumnFlags_NoHeaderWidth);

        if (TreeNode("Style settings"))
        {
            SameLine();
            HelpMarker("Giving access to some ImGuiStyle value in this demo for convenience.");
            SetNextItemWidth(GetFontSize() * 8);
            SliderAngle("style.TableAngledHeadersAngle", &GetStyle().TableAngledHeadersAngle, -50.0, +50.0);
            SetNextItemWidth(GetFontSize() * 8);
            SliderFloat2("style.TableAngledHeadersTextAlign", (f32*)&GetStyle().TableAngledHeadersTextAlign, 0.0, 1.0, "%.2");
            TreePop();
        }

        if (BeginTable("table_angled_headers", columns_count, table_flags, ImVec2{0.0, TEXT_BASE_HEIGHT * 12}))
        {
            TableSetupColumn(column_names[0], ImGuiTableColumnFlags_NoHide | ImGuiTableColumnFlags_NoReorder);
            for i32 n = 1; n < columns_count; n++
                TableSetupColumn(column_names[n], column_flags);
            TableSetupScrollFreeze(frozen_cols, frozen_rows);

            TableAngledHeadersRow(); // Draw angled headers for all columns with the ImGuiTableColumnFlags_AngledHeader flag.
            TableHeadersRow();       // Draw remaining headers and allow access to context-menu and other functions.
            for i32 row = 0; row < rows_count; row++
            {
                PushID(row);
                TableNextRow();
                TableSetColumnIndex(0);
                AlignTextToFramePadding();
                Text("Track %d", row);
                for i32 column = 1; column < columns_count; column++
                    if (TableSetColumnIndex(column))
                    {
                        PushID(column);
                        Checkbox("", &bools[row * columns_count + column]);
                        PopID();
                    }
                PopID();
            }
            EndTable();
        }
        TreePop();
    }

    // Demonstrate creating custom context menus inside columns,
    // while playing it nice with context menus provided by TableHeadersRow()/TableHeader()
    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Context menus");
    if (TreeNode("Context menus"))
    {
        HelpMarker(
            "By default, right-clicking over a TableHeadersRow()/TableHeader() line will open the default context-menu.\n"
            "Using ImGuiTableFlags_ContextMenuInBody we also allow right-clicking over columns body.");
        static ImGuiTableFlags flags1 = ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Hideable | ImGuiTableFlags_Borders | ImGuiTableFlags_ContextMenuInBody;

        PushStyleCompact();
        CheckboxFlags("ImGuiTableFlags_ContextMenuInBody", &flags1, ImGuiTableFlags_ContextMenuInBody);
        PopStyleCompact();

        // Context Menus: first example
        // [1.1] Right-click on the TableHeadersRow() line to open the default table context menu.
        // [1.2] Right-click in columns also open the default table context menu (if ImGuiTableFlags_ContextMenuInBody is set)
        COLUMNS_COUNT := 3;
        if (BeginTable("table_context_menu", COLUMNS_COUNT, flags1))
        {
            TableSetupColumn("One");
            TableSetupColumn("Two");
            TableSetupColumn("Three");

            // [1.1]] Right-click on the TableHeadersRow() line to open the default table context menu.
            TableHeadersRow();

            // Submit dummy contents
            for i32 row = 0; row < 4; row++
            {
                TableNextRow();
                for i32 column = 0; column < COLUMNS_COUNT; column++
                {
                    TableSetColumnIndex(column);
                    Text("Cell %d,%d", column, row);
                }
            }
            EndTable();
        }

        // Context Menus: second example
        // [2.1] Right-click on the TableHeadersRow() line to open the default table context menu.
        // [2.2] Right-click on the ".." to open a custom popup
        // [2.3] Right-click in columns to open another custom popup
        HelpMarker(
            "Demonstrate mixing table context menu (over header), item context button (over button) "
            "and custom per-colunm context menu (over column body).");
        flags2 := ImGuiTableFlags_Resizable | ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Hideable | ImGuiTableFlags_Borders;
        if (BeginTable("table_context_menu_2", COLUMNS_COUNT, flags2))
        {
            TableSetupColumn("One");
            TableSetupColumn("Two");
            TableSetupColumn("Three");

            // [2.1] Right-click on the TableHeadersRow() line to open the default table context menu.
            TableHeadersRow();
            for i32 row = 0; row < 4; row++
            {
                TableNextRow();
                for i32 column = 0; column < COLUMNS_COUNT; column++
                {
                    // Submit dummy contents
                    TableSetColumnIndex(column);
                    Text("Cell %d,%d", column, row);
                    SameLine();

                    // [2.2] Right-click on the ".." to open a custom popup
                    PushID(row * COLUMNS_COUNT + column);
                    SmallButton("..");
                    if (BeginPopupContextItem())
                    {
                        Text("This is the popup for Button(\"..\") in Cell %d,%d", column, row);
                        if (Button("Close"))
                            CloseCurrentPopup();
                        EndPopup();
                    }
                    PopID();
                }
            }

            // [2.3] Right-click anywhere in columns to open another custom popup
            // (instead of testing for !IsAnyItemHovered() we could also call OpenPopup() with ImGuiPopupFlags_NoOpenOverExistingPopup
            // to manage popup priority as the popups triggers, here "are we hovering a column" are overlapping)
            hovered_column := -1;
            for i32 column = 0; column < COLUMNS_COUNT + 1; column++
            {
                PushID(column);
                if (TableGetColumnFlags(column) & ImGuiTableColumnFlags_IsHovered)
                    hovered_column = column;
                if (hovered_column == column && !IsAnyItemHovered() && IsMouseReleased(1))
                    OpenPopup("MyPopup");
                if (BeginPopup("MyPopup"))
                {
                    if (column == COLUMNS_COUNT)
                        Text("This is a custom popup for unused space after the last column.");
                    else
                        Text("This is a custom popup for Column %d", column);
                    if (Button("Close"))
                        CloseCurrentPopup();
                    EndPopup();
                }
                PopID();
            }

            EndTable();
            Text("Hovered column: %d", hovered_column);
        }
        TreePop();
    }

    // Demonstrate creating multiple tables with the same ID
    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Synced instances");
    if (TreeNode("Synced instances"))
    {
        HelpMarker("Multiple tables with the same identifier will share their settings, width, visibility, order etc.");

        static ImGuiTableFlags flags = ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Hideable | ImGuiTableFlags_Borders | ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_NoSavedSettings;
        CheckboxFlags("ImGuiTableFlags_Resizable", &flags, ImGuiTableFlags_Resizable);
        CheckboxFlags("ImGuiTableFlags_ScrollY", &flags, ImGuiTableFlags_ScrollY);
        CheckboxFlags("ImGuiTableFlags_SizingFixedFit", &flags, ImGuiTableFlags_SizingFixedFit);
        CheckboxFlags("ImGuiTableFlags_HighlightHoveredColumn", &flags, ImGuiTableFlags_HighlightHoveredColumn);
        for i32 n = 0; n < 3; n++
        {
            buf : [32]u8
            sprintf(buf, "Synced Table %d", n);
            open := CollapsingHeader(buf, ImGuiTreeNodeFlags_DefaultOpen);
            if (open && BeginTable("Table", 3, flags, ImVec2{0.0, GetTextLineHeightWithSpacing(} * 5)))
            {
                TableSetupColumn("One");
                TableSetupColumn("Two");
                TableSetupColumn("Three");
                TableHeadersRow();
                cell_count := (n == 1) ? 27 : 9; // Make second table have a scrollbar to verify that additional decoration is not affecting column positions.
                for i32 cell = 0; cell < cell_count; cell++
                {
                    TableNextColumn();
                    Text("this cell %d", cell);
                }
                EndTable();
            }
        }
        TreePop();
    }

    // Demonstrate using Sorting facilities
    // This is a simplified version of the "Advanced" example, where we mostly focus on the code necessary to handle sorting.
    // Note that the "Advanced" example also showcase manually triggering a sort (e.g. if item quantities have been modified)
    static const u8* template_items_names[] =
    {
        "Banana", "Apple", "Cherry", "Watermelon", "Grapefruit", "Strawberry", "Mango",
        "Kiwi", "Orange", "Pineapple", "Blueberry", "Plum", "Coconut", "Pear", "Apricot"
    };
    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Sorting");
    if (TreeNode("Sorting"))
    {
        // Create item list
        static ImVector<MyItem> items;
        if (items.Size == 0)
        {
            items.resize(50, MyItem());
            for i32 n = 0; n < items.Size; n++
            {
                template_n := n % len(template_items_names);
                MyItem& item = items[n];
                item.ID = n;
                item.Name = template_items_names[template_n];
                item.Quantity = (n * n - n) % 20; // Assign default quantities
            }
        }

        // Options
        static ImGuiTableFlags flags =
            ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Hideable | ImGuiTableFlags_Sortable | ImGuiTableFlags_SortMulti
            | ImGuiTableFlags_RowBg | ImGuiTableFlags_BordersOuter | ImGuiTableFlags_BordersV | ImGuiTableFlags_NoBordersInBody
            | ImGuiTableFlags_ScrollY;
        PushStyleCompact();
        CheckboxFlags("ImGuiTableFlags_SortMulti", &flags, ImGuiTableFlags_SortMulti);
        SameLine(); HelpMarker("When sorting is enabled: hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).");
        CheckboxFlags("ImGuiTableFlags_SortTristate", &flags, ImGuiTableFlags_SortTristate);
        SameLine(); HelpMarker("When sorting is enabled: allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).");
        PopStyleCompact();

        if (BeginTable("table_sorting", 4, flags, ImVec2{0.0, TEXT_BASE_HEIGHT * 15}, 0.0))
        {
            // Declare columns
            // We use the "user_id" parameter of TableSetupColumn() to specify a user id that will be stored in the sort specifications.
            // This is so our sort function can identify a column given our own identifier. We could also identify them based on their index!
            // Demonstrate using a mixture of flags among available sort-related flags:
            // - ImGuiTableColumnFlags_DefaultSort
            // - ImGuiTableColumnFlags_NoSort / ImGuiTableColumnFlags_NoSortAscending / ImGuiTableColumnFlags_NoSortDescending
            // - ImGuiTableColumnFlags_PreferSortAscending / ImGuiTableColumnFlags_PreferSortDescending
            TableSetupColumn("ID",       ImGuiTableColumnFlags_DefaultSort          | ImGuiTableColumnFlags_WidthFixed,   0.0, MyItemColumnID_ID);
            TableSetupColumn("Name",                                                  ImGuiTableColumnFlags_WidthFixed,   0.0, MyItemColumnID_Name);
            TableSetupColumn("Action",   ImGuiTableColumnFlags_NoSort               | ImGuiTableColumnFlags_WidthFixed,   0.0, MyItemColumnID_Action);
            TableSetupColumn("Quantity", ImGuiTableColumnFlags_PreferSortDescending | ImGuiTableColumnFlags_WidthStretch, 0.0, MyItemColumnID_Quantity);
            TableSetupScrollFreeze(0, 1); // Make row always visible
            TableHeadersRow();

            // Sort our data if sort specs have been changed!
            if (ImGuiTableSortSpecs* sort_specs = TableGetSortSpecs())
                if (sort_specs.SpecsDirty)
                {
                    MyItem::SortWithSortSpecs(sort_specs, items.Data, items.Size);
                    sort_specs.SpecsDirty = false;
                }

            // Demonstrate using clipper for large vertical lists
            clipper : ImGuiListClipper
            clipper.Begin(items.Size);
            for clipper.Step()
                for i32 row_n = clipper.DisplayStart; row_n < clipper.DisplayEnd; row_n++
                {
                    // Display a data item
                    item := &items[row_n];
                    PushID(item.ID);
                    TableNextRow();
                    TableNextColumn();
                    Text("%04d", item.ID);
                    TableNextColumn();
                    TextUnformatted(item.Name);
                    TableNextColumn();
                    SmallButton("None");
                    TableNextColumn();
                    Text("%d", item.Quantity);
                    PopID();
                }
            EndTable();
        }
        TreePop();
    }

    // In this example we'll expose most table flags and settings.
    // For specific flags and settings refer to the corresponding section for more detailed explanation.
    // This section is mostly useful to experiment with combining certain flags or settings with each others.
    //ImGui::SetNextItemOpen(true, ImGuiCond_Once); // [DEBUG]
    if (open_action != -1)
        SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Advanced");
    if (TreeNode("Advanced"))
    {
        static ImGuiTableFlags flags =
            ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Hideable
            | ImGuiTableFlags_Sortable | ImGuiTableFlags_SortMulti
            | ImGuiTableFlags_RowBg | ImGuiTableFlags_Borders | ImGuiTableFlags_NoBordersInBody
            | ImGuiTableFlags_ScrollX | ImGuiTableFlags_ScrollY
            | ImGuiTableFlags_SizingFixedFit;
        static ImGuiTableColumnFlags columns_base_flags = ImGuiTableColumnFlags_None;

        enum ContentsType { CT_Text, CT_Button, CT_SmallButton, CT_FillButton, CT_Selectable, CT_SelectableSpanRow };
        static i32 contents_type = CT_SelectableSpanRow;
        const u8* contents_type_names[] = { "Text", "Button", "SmallButton", "FillButton", "Selectable", "Selectable (span row)" };
        static i32 freeze_cols = 1;
        static i32 freeze_rows = 1;
        static i32 items_count = len(template_items_names) * 2;
        static ImVec2 outer_size_value = ImVec2{0.0, TEXT_BASE_HEIGHT * 12};
        static f32 row_min_height = 0.0; // Auto
        static f32 inner_width_with_scroll = 0.0; // Auto-extend
        static bool outer_size_enabled = true;
        static bool show_headers = true;
        static bool show_wrapped_text = false;
        //static ImGuiTextFilter filter;
        //ImGui::SetNextItemOpen(true, ImGuiCond_Once); // FIXME-TABLE: Enabling this results in initial clipped first pass on table which tend to affect column sizing
        if (TreeNode("Options"))
        {
            // Make the UI compact because there are so many fields
            PushStyleCompact();
            PushItemWidth(TEXT_BASE_WIDTH * 28.0);

            if (TreeNodeEx("Features:", ImGuiTreeNodeFlags_DefaultOpen))
            {
                CheckboxFlags("ImGuiTableFlags_Resizable", &flags, ImGuiTableFlags_Resizable);
                CheckboxFlags("ImGuiTableFlags_Reorderable", &flags, ImGuiTableFlags_Reorderable);
                CheckboxFlags("ImGuiTableFlags_Hideable", &flags, ImGuiTableFlags_Hideable);
                CheckboxFlags("ImGuiTableFlags_Sortable", &flags, ImGuiTableFlags_Sortable);
                CheckboxFlags("ImGuiTableFlags_NoSavedSettings", &flags, ImGuiTableFlags_NoSavedSettings);
                CheckboxFlags("ImGuiTableFlags_ContextMenuInBody", &flags, ImGuiTableFlags_ContextMenuInBody);
                TreePop();
            }

            if (TreeNodeEx("Decorations:", ImGuiTreeNodeFlags_DefaultOpen))
            {
                CheckboxFlags("ImGuiTableFlags_RowBg", &flags, ImGuiTableFlags_RowBg);
                CheckboxFlags("ImGuiTableFlags_BordersV", &flags, ImGuiTableFlags_BordersV);
                CheckboxFlags("ImGuiTableFlags_BordersOuterV", &flags, ImGuiTableFlags_BordersOuterV);
                CheckboxFlags("ImGuiTableFlags_BordersInnerV", &flags, ImGuiTableFlags_BordersInnerV);
                CheckboxFlags("ImGuiTableFlags_BordersH", &flags, ImGuiTableFlags_BordersH);
                CheckboxFlags("ImGuiTableFlags_BordersOuterH", &flags, ImGuiTableFlags_BordersOuterH);
                CheckboxFlags("ImGuiTableFlags_BordersInnerH", &flags, ImGuiTableFlags_BordersInnerH);
                CheckboxFlags("ImGuiTableFlags_NoBordersInBody", &flags, ImGuiTableFlags_NoBordersInBody); SameLine(); HelpMarker("Disable vertical borders in columns Body (borders will always appear in Headers");
                CheckboxFlags("ImGuiTableFlags_NoBordersInBodyUntilResize", &flags, ImGuiTableFlags_NoBordersInBodyUntilResize); SameLine(); HelpMarker("Disable vertical borders in columns Body until hovered for resize (borders will always appear in Headers)");
                TreePop();
            }

            if (TreeNodeEx("Sizing:", ImGuiTreeNodeFlags_DefaultOpen))
            {
                EditTableSizingFlags(&flags);
                SameLine(); HelpMarker("In the Advanced demo we override the policy of each column so those table-wide settings have less effect that typical.");
                CheckboxFlags("ImGuiTableFlags_NoHostExtendX", &flags, ImGuiTableFlags_NoHostExtendX);
                SameLine(); HelpMarker("Make outer width auto-fit to columns, overriding outer_size.x value.\n\nOnly available when ScrollX/ScrollY are disabled and Stretch columns are not used.");
                CheckboxFlags("ImGuiTableFlags_NoHostExtendY", &flags, ImGuiTableFlags_NoHostExtendY);
                SameLine(); HelpMarker("Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit).\n\nOnly available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.");
                CheckboxFlags("ImGuiTableFlags_NoKeepColumnsVisible", &flags, ImGuiTableFlags_NoKeepColumnsVisible);
                SameLine(); HelpMarker("Only available if ScrollX is disabled.");
                CheckboxFlags("ImGuiTableFlags_PreciseWidths", &flags, ImGuiTableFlags_PreciseWidths);
                SameLine(); HelpMarker("Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.");
                CheckboxFlags("ImGuiTableFlags_NoClip", &flags, ImGuiTableFlags_NoClip);
                SameLine(); HelpMarker("Disable clipping rectangle for every individual columns (reduce draw command count, items will be able to overflow into other columns). Generally incompatible with ScrollFreeze options.");
                TreePop();
            }

            if (TreeNodeEx("Padding:", ImGuiTreeNodeFlags_DefaultOpen))
            {
                CheckboxFlags("ImGuiTableFlags_PadOuterX", &flags, ImGuiTableFlags_PadOuterX);
                CheckboxFlags("ImGuiTableFlags_NoPadOuterX", &flags, ImGuiTableFlags_NoPadOuterX);
                CheckboxFlags("ImGuiTableFlags_NoPadInnerX", &flags, ImGuiTableFlags_NoPadInnerX);
                TreePop();
            }

            if (TreeNodeEx("Scrolling:", ImGuiTreeNodeFlags_DefaultOpen))
            {
                CheckboxFlags("ImGuiTableFlags_ScrollX", &flags, ImGuiTableFlags_ScrollX);
                SameLine();
                SetNextItemWidth(GetFrameHeight());
                DragInt("freeze_cols", &freeze_cols, 0.2, 0, 9, nil, ImGuiSliderFlags_NoInput);
                CheckboxFlags("ImGuiTableFlags_ScrollY", &flags, ImGuiTableFlags_ScrollY);
                SameLine();
                SetNextItemWidth(GetFrameHeight());
                DragInt("freeze_rows", &freeze_rows, 0.2, 0, 9, nil, ImGuiSliderFlags_NoInput);
                TreePop();
            }

            if (TreeNodeEx("Sorting:", ImGuiTreeNodeFlags_DefaultOpen))
            {
                CheckboxFlags("ImGuiTableFlags_SortMulti", &flags, ImGuiTableFlags_SortMulti);
                SameLine(); HelpMarker("When sorting is enabled: hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).");
                CheckboxFlags("ImGuiTableFlags_SortTristate", &flags, ImGuiTableFlags_SortTristate);
                SameLine(); HelpMarker("When sorting is enabled: allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).");
                TreePop();
            }

            if (TreeNodeEx("Headers:", ImGuiTreeNodeFlags_DefaultOpen))
            {
                Checkbox("show_headers", &show_headers);
                CheckboxFlags("ImGuiTableFlags_HighlightHoveredColumn", &flags, ImGuiTableFlags_HighlightHoveredColumn);
                CheckboxFlags("ImGuiTableColumnFlags_AngledHeader", &columns_base_flags, ImGuiTableColumnFlags_AngledHeader);
                SameLine(); HelpMarker("Enable AngledHeader on all columns. Best enabled on selected narrow columns (see \"Angled headers\" section of the demo).");
                TreePop();
            }

            if (TreeNodeEx("Other:", ImGuiTreeNodeFlags_DefaultOpen))
            {
                Checkbox("show_wrapped_text", &show_wrapped_text);

                DragFloat2("##OuterSize", &outer_size_value.x);
                SameLine(0.0, GetStyle().ItemInnerSpacing.x);
                Checkbox("outer_size", &outer_size_enabled);
                SameLine();
                HelpMarker("If scrolling is disabled (ScrollX and ScrollY not set):\n"
                    "- The table is output directly in the parent window.\n"
                    "- OuterSize.x < 0.0 will right-align the table.\n"
                    "- OuterSize.x = 0.0 will narrow fit the table unless there are any Stretch columns.\n"
                    "- OuterSize.y then becomes the minimum size for the table, which will extend vertically if there are more rows (unless NoHostExtendY is set).");

                // From a user point of view we will tend to use 'inner_width' differently depending on whether our table is embedding scrolling.
                // To facilitate toying with this demo we will actually pass 0.0f to the BeginTable() when ScrollX is disabled.
                DragFloat("inner_width (when ScrollX active)", &inner_width_with_scroll, 1.0, 0.0, math.F32_MAX);

                DragFloat("row_min_height", &row_min_height, 1.0, 0.0, math.F32_MAX);
                SameLine(); HelpMarker("Specify height of the Selectable item.");

                DragInt("items_count", &items_count, 0.1, 0, 9999);
                Combo("items_type (first column)", &contents_type, contents_type_names, len(contents_type_names));
                //filter.Draw("filter");
                TreePop();
            }

            PopItemWidth();
            PopStyleCompact();
            Spacing();
            TreePop();
        }

        // Update item list if we changed the number of items
        static ImVector<MyItem> items;
        static ImVector<i32> selection;
        static bool items_need_sort = false;
        if (items.Size != items_count)
        {
            items.resize(items_count, MyItem());
            for i32 n = 0; n < items_count; n++
            {
                template_n := n % len(template_items_names);
                MyItem& item = items[n];
                item.ID = n;
                item.Name = template_items_names[template_n];
                item.Quantity = (template_n == 3) ? 10 : (template_n == 4) ? 20 : 0; // Assign default quantities
            }
        }

        parent_draw_list := GetWindowDrawList();
        parent_draw_list_draw_cmd_count := parent_draw_list.CmdBuffer.Size;
        table_scroll_cur, table_scroll_max : ImVec2 // For debug display
        table_draw_list := nil;  // "

        // Submit table
        inner_width_to_use := (flags & ImGuiTableFlags_ScrollX) ? inner_width_with_scroll : 0.0;
        if (BeginTable("table_advanced", 6, flags, outer_size_enabled ? outer_size_value : ImVec2{0, 0}, inner_width_to_use))
        {
            // Declare columns
            // We use the "user_id" parameter of TableSetupColumn() to specify a user id that will be stored in the sort specifications.
            // This is so our sort function can identify a column given our own identifier. We could also identify them based on their index!
            TableSetupColumn("ID",           columns_base_flags | ImGuiTableColumnFlags_DefaultSort | ImGuiTableColumnFlags_WidthFixed | ImGuiTableColumnFlags_NoHide, 0.0, MyItemColumnID_ID);
            TableSetupColumn("Name",         columns_base_flags | ImGuiTableColumnFlags_WidthFixed, 0.0, MyItemColumnID_Name);
            TableSetupColumn("Action",       columns_base_flags | ImGuiTableColumnFlags_NoSort | ImGuiTableColumnFlags_WidthFixed, 0.0, MyItemColumnID_Action);
            TableSetupColumn("Quantity",     columns_base_flags | ImGuiTableColumnFlags_PreferSortDescending, 0.0, MyItemColumnID_Quantity);
            TableSetupColumn("Description",  columns_base_flags | ((flags & ImGuiTableFlags_NoHostExtendX) ? 0 : ImGuiTableColumnFlags_WidthStretch), 0.0, MyItemColumnID_Description);
            TableSetupColumn("Hidden",       columns_base_flags |  ImGuiTableColumnFlags_DefaultHide | ImGuiTableColumnFlags_NoSort);
            TableSetupScrollFreeze(freeze_cols, freeze_rows);

            // Sort our data if sort specs have been changed!
            sort_specs := TableGetSortSpecs();
            if (sort_specs && sort_specs.SpecsDirty)
                items_need_sort = true;
            if (sort_specs && items_need_sort && items.Size > 1)
            {
                MyItem::SortWithSortSpecs(sort_specs, items.Data, items.Size);
                sort_specs.SpecsDirty = false;
            }
            items_need_sort = false;

            // Take note of whether we are currently sorting based on the Quantity field,
            // we will use this to trigger sorting when we know the data of this column has been modified.
            sorts_specs_using_quantity := (TableGetColumnFlags(3) & ImGuiTableColumnFlags_IsSorted) != 0;

            // Show headers
            if (show_headers && (columns_base_flags & ImGuiTableColumnFlags_AngledHeader) != 0)
                TableAngledHeadersRow();
            if (show_headers)
                TableHeadersRow();

            // Show data
            // FIXME-TABLE FIXME-NAV: How we can get decent up/down even though we have the buttons here?
when 1 {
            // Demonstrate using clipper for large vertical lists
            clipper : ImGuiListClipper
            clipper.Begin(items.Size);
            for clipper.Step()
            {
                for i32 row_n = clipper.DisplayStart; row_n < clipper.DisplayEnd; row_n++
} else {
            // Without clipper
            {
                for i32 row_n = 0; row_n < items.Size; row_n++
}
                {
                    item := &items[row_n];
                    //if (!filter.PassFilter(item->Name))
                    //    continue;

                    item_is_selected := selection.contains(item.ID);
                    PushID(item.ID);
                    TableNextRow(ImGuiTableRowFlags_None, row_min_height);

                    // For the demo purpose we can select among different type of items submitted in the first column
                    TableSetColumnIndex(0);
                    label : [32]u8
                    sprintf(label, "%04d", item.ID);
                    if (contents_type == CT_Text)
                        TextUnformatted(label);
                    else if (contents_type == CT_Button)
                        Button(label);
                    else if (contents_type == CT_SmallButton)
                        SmallButton(label);
                    else if (contents_type == CT_FillButton)
                        Button(label, ImVec2{-math.F32_MIN, 0.0});
                    else if (contents_type == CT_Selectable || contents_type == CT_SelectableSpanRow)
                    {
                        selectable_flags := (contents_type == CT_SelectableSpanRow) ? ImGuiSelectableFlags_SpanAllColumns | ImGuiSelectableFlags_AllowOverlap : ImGuiSelectableFlags_None;
                        if (Selectable(label, item_is_selected, selectable_flags, ImVec2{0, row_min_height}))
                        {
                            if (GetIO().KeyCtrl)
                            {
                                if (item_is_selected)
                                    selection.find_erase_unsorted(item.ID);
                                else
                                    selection.push_back(item.ID);
                            }
                            else
                            {
                                selection.clear();
                                selection.push_back(item.ID);
                            }
                        }
                    }

                    if (TableSetColumnIndex(1))
                        TextUnformatted(item.Name);

                    // Here we demonstrate marking our data set as needing to be sorted again if we modified a quantity,
                    // and we are currently sorting on the column showing the Quantity.
                    // To avoid triggering a sort while holding the button, we only trigger it when the button has been released.
                    // You will probably need some extra logic if you want to automatically sort when a specific entry changes.
                    if (TableSetColumnIndex(2))
                    {
                        if (SmallButton("Chop")) { item.Quantity += 1; }
                        if (sorts_specs_using_quantity && IsItemDeactivated()) { items_need_sort = true; }
                        SameLine();
                        if (SmallButton("Eat")) { item.Quantity -= 1; }
                        if (sorts_specs_using_quantity && IsItemDeactivated()) { items_need_sort = true; }
                    }

                    if (TableSetColumnIndex(3))
                        Text("%d", item.Quantity);

                    TableSetColumnIndex(4);
                    if (show_wrapped_text)
                        TextWrapped("Lorem ipsum dolor sit amet");
                    else
                        Text("Lorem ipsum dolor sit amet");

                    if (TableSetColumnIndex(5))
                        Text("1234");

                    PopID();
                }
            }

            // Store some info to display debug details below
            table_scroll_cur = ImVec2{GetScrollX(}, GetScrollY());
            table_scroll_max = ImVec2{GetScrollMaxX(}, GetScrollMaxY());
            table_draw_list = GetWindowDrawList();
            EndTable();
        }
        static bool show_debug_details = false;
        Checkbox("Debug details", &show_debug_details);
        if (show_debug_details && table_draw_list)
        {
            SameLine(0.0, 0.0);
            table_draw_list_draw_cmd_count := table_draw_list.CmdBuffer.Size;
            if (table_draw_list == parent_draw_list)
                Text(": DrawCmd: +%d (in same window)",
                    table_draw_list_draw_cmd_count - parent_draw_list_draw_cmd_count);
            else
                Text(": DrawCmd: +%d (in child window), Scroll: (%.f/%.f) (%.f/%.f)",
                    table_draw_list_draw_cmd_count - 1, table_scroll_cur.x, table_scroll_max.x, table_scroll_cur.y, table_scroll_max.y);
        }
        TreePop();
    }

    PopID();

    ShowDemoWindowColumns();

    if (disable_indent)
        PopStyleVar();
}

// Demonstrate old/legacy Columns API!
// [2020: Columns are under-featured and not maintained. Prefer using the more flexible and powerful BeginTable() API!]
ShowDemoWindowColumns :: proc()
{
    IMGUI_DEMO_MARKER("Columns (legacy API)");
    open := TreeNode("Legacy Columns API");
    SameLine();
    HelpMarker("Columns() is an old API! Prefer using the more flexible and powerful BeginTable() API!");
    if (!open)
        return;

    // Basic columns
    IMGUI_DEMO_MARKER("Columns (legacy API)/Basic");
    if (TreeNode("Basic"))
    {
        Text("Without border:");
        Columns(3, "mycolumns3", false);  // 3-ways, no border
        Separator();
        for i32 n = 0; n < 14; n++
        {
            label : [32]u8
            sprintf(label, "Item %d", n);
            if (Selectable(label)) {}
            //if (ImGui::Button(label, ImVec2(-FLT_MIN,0.0f))) {}
            NextColumn();
        }
        Columns(1);
        Separator();

        Text("With border:");
        Columns(4, "mycolumns"); // 4-ways, with border
        Separator();
        Text("ID"); NextColumn();
        Text("Name"); NextColumn();
        Text("Path"); NextColumn();
        Text("Hovered"); NextColumn();
        Separator();
        const u8* names[3] = { "One", "Two", "Three" };
        const u8* paths[3] = { "/path/one", "/path/two", "/path/three" };
        static i32 selected = -1;
        for i32 i = 0; i < 3; i++
        {
            label : [32]u8
            sprintf(label, "%04d", i);
            if (Selectable(label, selected == i, ImGuiSelectableFlags_SpanAllColumns))
                selected = i;
            hovered := IsItemHovered();
            NextColumn();
            Text(names[i]); NextColumn();
            Text(paths[i]); NextColumn();
            Text("%d", hovered); NextColumn();
        }
        Columns(1);
        Separator();
        TreePop();
    }

    IMGUI_DEMO_MARKER("Columns (legacy API)/Borders");
    if (TreeNode("Borders"))
    {
        // NB: Future columns API should allow automatic horizontal borders.
        static bool h_borders = true;
        static bool v_borders = true;
        static i32 columns_count = 4;
        lines_count := 3;
        SetNextItemWidth(GetFontSize() * 8);
        DragInt("##columns_count", &columns_count, 0.1, 2, 10, "%d columns");
        if (columns_count < 2)
            columns_count = 2;
        SameLine();
        Checkbox("horizontal", &h_borders);
        SameLine();
        Checkbox("vertical", &v_borders);
        Columns(columns_count, nil, v_borders);
        for i32 i = 0; i < columns_count * lines_count; i++
        {
            if (h_borders && GetColumnIndex() == 0)
                Separator();
            PushID(i);
            Text("%c%c%c", 'a' + i, 'a' + i, 'a' + i);
            Text("Width %.2", GetColumnWidth());
            Text("Avail %.2", GetContentRegionAvail().x);
            Text("Offset %.2", GetColumnOffset());
            Text("Long text that is likely to clip");
            Button("Button", ImVec2{-math.F32_MIN, 0.0});
            PopID();
            NextColumn();
        }
        Columns(1);
        if (h_borders)
            Separator();
        TreePop();
    }

    // Create multiple items in a same cell before switching to next column
    IMGUI_DEMO_MARKER("Columns (legacy API)/Mixed items");
    if (TreeNode("Mixed items"))
    {
        Columns(3, "mixed");
        Separator();

        Text("Hello");
        Button("Banana");
        NextColumn();

        Text("ImGui");
        Button("Apple");
        static f32 foo = 1.0;
        InputFloat("red", &foo, 0.05, 0, "%.3");
        Text("An extra line here.");
        NextColumn();

        Text("Sailor");
        Button("Corniflower");
        static f32 bar = 1.0;
        InputFloat("blue", &bar, 0.05, 0, "%.3");
        NextColumn();

        if (CollapsingHeader("Category A")) { Text("Blah blah blah"); } NextColumn();
        if (CollapsingHeader("Category B")) { Text("Blah blah blah"); } NextColumn();
        if (CollapsingHeader("Category C")) { Text("Blah blah blah"); } NextColumn();
        Columns(1);
        Separator();
        TreePop();
    }

    // Word wrapping
    IMGUI_DEMO_MARKER("Columns (legacy API)/Word-wrapping");
    if (TreeNode("Word-wrapping"))
    {
        Columns(2, "word-wrapping");
        Separator();
        TextWrapped("The quick brown fox jumps over the lazy dog.");
        TextWrapped("Hello Left");
        NextColumn();
        TextWrapped("The quick brown fox jumps over the lazy dog.");
        TextWrapped("Hello Right");
        Columns(1);
        Separator();
        TreePop();
    }

    IMGUI_DEMO_MARKER("Columns (legacy API)/Horizontal Scrolling");
    if (TreeNode("Horizontal Scrolling"))
    {
        SetNextWindowContentSize(ImVec2{1500.0, 0.0});
        child_size := ImVec2{0, GetFontSize(} * 20.0);
        BeginChild("##ScrollingRegion", child_size, ImGuiChildFlags_None, ImGuiWindowFlags_HorizontalScrollbar);
        Columns(10);

        // Also demonstrate using clipper for large vertical lists
        ITEMS_COUNT := 2000;
        clipper : ImGuiListClipper
        clipper.Begin(ITEMS_COUNT);
        for clipper.Step()
        {
            for i32 i = clipper.DisplayStart; i < clipper.DisplayEnd; i++
                for i32 j = 0; j < 10; j++
                {
                    Text("Line %d Column %d...", i, j);
                    NextColumn();
                }
        }
        Columns(1);
        EndChild();
        TreePop();
    }

    IMGUI_DEMO_MARKER("Columns (legacy API)/Tree");
    if (TreeNode("Tree"))
    {
        Columns(2, "tree", true);
        for i32 x = 0; x < 3; x++
        {
            open1 := TreeNode((rawptr)(intptr_t)x, "Node%d", x);
            NextColumn();
            Text("Node contents");
            NextColumn();
            if (open1)
            {
                for i32 y = 0; y < 3; y++
                {
                    open2 := TreeNode((rawptr)(intptr_t)y, "Node%d.%d", x, y);
                    NextColumn();
                    Text("Node contents");
                    if (open2)
                    {
                        Text("Even more contents");
                        if (TreeNode("Tree in column"))
                        {
                            Text("The quick brown fox jumps over the lazy dog");
                            TreePop();
                        }
                    }
                    NextColumn();
                    if (open2)
                        TreePop();
                }
                TreePop();
            }
        }
        Columns(1);
        TreePop();
    }

    TreePop();
}

//-----------------------------------------------------------------------------
// [SECTION] ShowDemoWindowInputs()
//-----------------------------------------------------------------------------

ShowDemoWindowInputs :: proc()
{
    IMGUI_DEMO_MARKER("Inputs & Focus");
    if (CollapsingHeader("Inputs & Focus"))
    {
        ImGuiIO& io = GetIO();

        // Display inputs submitted to ImGuiIO
        IMGUI_DEMO_MARKER("Inputs & Focus/Inputs");
        SetNextItemOpen(true, ImGuiCond_Once);
        inputs_opened := TreeNode("Inputs");
        SameLine();
        HelpMarker(
            "This is a simplified view. See more detailed input state:\n"
            "- in 'Tools.Metrics/Debugger.Inputs'.\n"
            "- in 'Tools.Debug Log.IO'.");
        if (inputs_opened)
        {
            if (IsMousePosValid())
                Text("Mouse pos: (%g, %g)", io.MousePos.x, io.MousePos.y);
            else
                Text("Mouse pos: <INVALID>");
            Text("Mouse delta: (%g, %g)", io.MouseDelta.x, io.MouseDelta.y);
            Text("Mouse down:");
            for (i32 i = 0; i < len(io.MouseDown); i++) if (IsMouseDown(i)) { SameLine(); Text("b%d (%.02 secs)", i, io.MouseDownDuration[i]); }
            Text("Mouse wheel: %.1", io.MouseWheel);

            // We iterate both legacy native range and named ImGuiKey ranges. This is a little unusual/odd but this allows
            // displaying the data for old/new backends.
            // User code should never have to go through such hoops!
            // You can generally iterate between ImGuiKey_NamedKey_BEGIN and ImGuiKey_NamedKey_END.
            struct funcs { static bool IsLegacyNativeDupe(ImGuiKey) { return false; } };
            start_key := ImGuiKey_NamedKey_BEGIN;
            Text("Keys down:");         for (ImGuiKey key = start_key; key < ImGuiKey_NamedKey_END; key = (ImGuiKey)(key + 1)) { if (funcs::IsLegacyNativeDupe(key) || !IsKeyDown(key)) continue; SameLine(); Text((key < ImGuiKey_NamedKey_BEGIN) ? "\"%s\"" : "\"%s\" %d", GetKeyName(key), key); }
            Text("Keys mods: %s%s%s%s", io.KeyCtrl ? "CTRL " : "", io.KeyShift ? "SHIFT " : "", io.KeyAlt ? "ALT " : "", io.KeySuper ? "SUPER " : "");
            Text("Chars queue:");       for (i32 i = 0; i < io.InputQueueCharacters.Size; i++) { ImWchar c = io.InputQueueCharacters[i]; SameLine();  Text("\'%c\' (0x%04X)", (c > ' ' && c <= 255) ? cast(u8) c : '?', c); } // FIXME: We should convert 'c' to UTF-8 here but the functions are not public.

            TreePop();
        }

        // Display ImGuiIO output flags
        IMGUI_DEMO_MARKER("Inputs & Focus/Outputs");
        SetNextItemOpen(true, ImGuiCond_Once);
        outputs_opened := TreeNode("Outputs");
        SameLine();
        HelpMarker(
            "The value of io.WantCaptureMouse and io.WantCaptureKeyboard are normally set by Dear ImGui "
            "to instruct your application of how to route inputs. Typically, when a value is true, it means "
            "Dear ImGui wants the corresponding inputs and we expect the underlying application to ignore them.\n\n"
            "The most typical case is: when hovering a window, Dear ImGui set io.WantCaptureMouse to true, "
            "and underlying application should ignore mouse inputs (in practice there are many and more subtle "
            "rules leading to how those flags are set).");
        if (outputs_opened)
        {
            Text("io.WantCaptureMouse: %d", io.WantCaptureMouse);
            Text("io.WantCaptureMouseUnlessPopupClose: %d", io.WantCaptureMouseUnlessPopupClose);
            Text("io.WantCaptureKeyboard: %d", io.WantCaptureKeyboard);
            Text("io.WantTextInput: %d", io.WantTextInput);
            Text("io.WantSetMousePos: %d", io.WantSetMousePos);
            Text("io.NavActive: %d, io.NavVisible: %d", io.NavActive, io.NavVisible);

            IMGUI_DEMO_MARKER("Inputs & Focus/Outputs/WantCapture override");
            if (TreeNode("WantCapture override"))
            {
                HelpMarker(
                    "Hovering the colored canvas will override io.WantCaptureXXX fields.\n"
                    "Notice how normally (when set to none), the value of io.WantCaptureKeyboard would be false when hovering "
                    "and true when clicking.");
                static i32 capture_override_mouse = -1;
                static i32 capture_override_keyboard = -1;
                const u8* capture_override_desc[] = { "None", "Set to false", "Set to true" };
                SetNextItemWidth(GetFontSize() * 15);
                SliderInt("SetNextFrameWantCaptureMouse() on hover", &capture_override_mouse, -1, +1, capture_override_desc[capture_override_mouse + 1], ImGuiSliderFlags_AlwaysClamp);
                SetNextItemWidth(GetFontSize() * 15);
                SliderInt("SetNextFrameWantCaptureKeyboard() on hover", &capture_override_keyboard, -1, +1, capture_override_desc[capture_override_keyboard + 1], ImGuiSliderFlags_AlwaysClamp);

                ColorButton("##panel", ImVec4{0.7, 0.1, 0.7, 1.0}, ImGuiColorEditFlags_NoTooltip | ImGuiColorEditFlags_NoDragDrop, ImVec2{128.0, 96.0}); // Dummy item
                if (IsItemHovered() && capture_override_mouse != -1)
                    SetNextFrameWantCaptureMouse(capture_override_mouse == 1);
                if (IsItemHovered() && capture_override_keyboard != -1)
                    SetNextFrameWantCaptureKeyboard(capture_override_keyboard == 1);

                TreePop();
            }
            TreePop();
        }

        // Demonstrate using Shortcut() and Routing Policies.
        // The general flow is:
        // - Code interested in a chord (e.g. "Ctrl+A") declares their intent.
        // - Multiple locations may be interested in same chord! Routing helps find a winner.
        // - Every frame, we resolve all claims and assign one owner if the modifiers are matching.
        // - The lower-level function is 'bool SetShortcutRouting()', returns true when caller got the route.
        // - Most of the times, SetShortcutRouting() is not called directly. User mostly calls Shortcut() with routing flags.
        // - If you call Shortcut() WITHOUT any routing option, it uses ImGuiInputFlags_RouteFocused.
        // TL;DR: Most uses will simply be:
        // - Shortcut(ImGuiMod_Ctrl | ImGuiKey_A); // Use ImGuiInputFlags_RouteFocused policy.
        IMGUI_DEMO_MARKER("Inputs & Focus/Shortcuts");
        if (TreeNode("Shortcuts"))
        {
            static ImGuiInputFlags route_options = ImGuiInputFlags_Repeat;
            static ImGuiInputFlags route_type = ImGuiInputFlags_RouteFocused;
            CheckboxFlags("ImGuiInputFlags_Repeat", &route_options, ImGuiInputFlags_Repeat);
            RadioButton("ImGuiInputFlags_RouteActive", &route_type, ImGuiInputFlags_RouteActive);
            RadioButton("ImGuiInputFlags_RouteFocused (default)", &route_type, ImGuiInputFlags_RouteFocused);
            RadioButton("ImGuiInputFlags_RouteGlobal", &route_type, ImGuiInputFlags_RouteGlobal);
            Indent();
            BeginDisabled(route_type != ImGuiInputFlags_RouteGlobal);
            CheckboxFlags("ImGuiInputFlags_RouteOverFocused", &route_options, ImGuiInputFlags_RouteOverFocused);
            CheckboxFlags("ImGuiInputFlags_RouteOverActive", &route_options, ImGuiInputFlags_RouteOverActive);
            CheckboxFlags("ImGuiInputFlags_RouteUnlessBgFocused", &route_options, ImGuiInputFlags_RouteUnlessBgFocused);
            EndDisabled();
            Unindent();
            RadioButton("ImGuiInputFlags_RouteAlways", &route_type, ImGuiInputFlags_RouteAlways);
            flags := route_type | route_options; // Merged flags
            if (route_type != ImGuiInputFlags_RouteGlobal)
                flags &= ~(ImGuiInputFlags_RouteOverFocused | ImGuiInputFlags_RouteOverActive | ImGuiInputFlags_RouteUnlessBgFocused);

            SeparatorText("Using SetNextItemShortcut()");
            Text("Ctrl+S");
            SetNextItemShortcut(ImGuiMod_Ctrl | ImGuiKey_S, flags | ImGuiInputFlags_Tooltip);
            Button("Save");
            Text("Alt+F");
            SetNextItemShortcut(ImGuiMod_Alt | ImGuiKey_F, flags | ImGuiInputFlags_Tooltip);
            static f32 f = 0.5;
            SliderFloat("Factor", &f, 0.0, 1.0);

            SeparatorText("Using Shortcut()");
            line_height := GetTextLineHeightWithSpacing();
            key_chord := ImGuiMod_Ctrl | ImGuiKey_A;

            Text("Ctrl+A");
            Text("IsWindowFocused: %d, Shortcut: %s", IsWindowFocused(), Shortcut(key_chord, flags) ? "PRESSED" : "...");

            PushStyleColor(ImGuiCol_ChildBg, ImVec4{1.0, 0.0, 1.0, 0.1});

            BeginChild("WindowA", ImVec2{-math.F32_MIN, line_height * 14}, true);
            Text("Press CTRL+A and see who receives it!");
            Separator();

            // 1: Window polling for CTRL+A
            Text("(in WindowA)");
            Text("IsWindowFocused: %d, Shortcut: %s", IsWindowFocused(), Shortcut(key_chord, flags) ? "PRESSED" : "...");

            // 2: InputText also polling for CTRL+A: it always uses _RouteFocused internally (gets priority when active)
            // (Commmented because the owner-aware version of Shortcut() is still in imgui_internal.h)
            //char str[16] = "Press CTRL+A";
            //ImGui::Spacing();
            //ImGui::InputText("InputTextB", str, IM_ARRAYSIZE(str), ImGuiInputTextFlags_ReadOnly);
            //ImGuiID item_id = ImGui::GetItemID();
            //ImGui::SameLine(); HelpMarker("Internal widgets always use _RouteFocused");
            //ImGui::Text("IsWindowFocused: %d, Shortcut: %s", ImGui::IsWindowFocused(), ImGui::Shortcut(key_chord, flags, item_id) ? "PRESSED" : "...");

            // 3: Dummy child is not claiming the route: focusing them shouldn't steal route away from WindowA
            BeginChild("ChildD", ImVec2{-math.F32_MIN, line_height * 4}, true);
            Text("(in ChildD: not using same Shortcut)");
            Text("IsWindowFocused: %d", IsWindowFocused());
            EndChild();

            // 4: Child window polling for CTRL+A. It is deeper than WindowA and gets priority when focused.
            BeginChild("ChildE", ImVec2{-math.F32_MIN, line_height * 4}, true);
            Text("(in ChildE: using same Shortcut)");
            Text("IsWindowFocused: %d, Shortcut: %s", IsWindowFocused(), Shortcut(key_chord, flags) ? "PRESSED" : "...");
            EndChild();

            // 5: In a popup
            if (Button("Open Popup"))
                OpenPopup("PopupF");
            if (BeginPopup("PopupF"))
            {
                Text("(in PopupF)");
                Text("IsWindowFocused: %d, Shortcut: %s", IsWindowFocused(), Shortcut(key_chord, flags) ? "PRESSED" : "...");
                // (Commmented because the owner-aware version of Shortcut() is still in imgui_internal.h)
                //ImGui::InputText("InputTextG", str, IM_ARRAYSIZE(str), ImGuiInputTextFlags_ReadOnly);
                //ImGui::Text("IsWindowFocused: %d, Shortcut: %s", ImGui::IsWindowFocused(), ImGui::Shortcut(key_chord, flags, ImGui::GetItemID()) ? "PRESSED" : "...");
                EndPopup();
            }
            EndChild();
            PopStyleColor();

            TreePop();
        }

        // Display mouse cursors
        IMGUI_DEMO_MARKER("Inputs & Focus/Mouse Cursors");
        if (TreeNode("Mouse Cursors"))
        {
            const u8* mouse_cursors_names[] = { "Arrow", "TextInput", "ResizeAll", "ResizeNS", "ResizeEW", "ResizeNESW", "ResizeNWSE", "Hand", "NotAllowed" };
            assert(len(mouse_cursors_names) == ImGuiMouseCursor_COUNT);

            current := GetMouseCursor();
            cursor_name := (current >= ImGuiMouseCursor_Arrow) && (current < ImGuiMouseCursor_COUNT) ? mouse_cursors_names[current] : "N/A";
            Text("Current mouse cursor = %d: %s", current, cursor_name);
            BeginDisabled(true);
            CheckboxFlags("io.BackendFlags: HasMouseCursors", &io.BackendFlags, ImGuiBackendFlags_HasMouseCursors);
            EndDisabled();

            Text("Hover to see mouse cursors:");
            SameLine(); HelpMarker(
                "Your application can render a different mouse cursor based on what GetMouseCursor() returns. "
                "If software cursor rendering (io.MouseDrawCursor) is set ImGui will draw the right cursor for you, "
                "otherwise your backend needs to handle it.");
            for i32 i = 0; i < ImGuiMouseCursor_COUNT; i++
            {
                label : [32]u8
                sprintf(label, "Mouse cursor %d: %s", i, mouse_cursors_names[i]);
                Bullet(); Selectable(label, false);
                if (IsItemHovered())
                    SetMouseCursor(i);
            }
            TreePop();
        }

        IMGUI_DEMO_MARKER("Inputs & Focus/Tabbing");
        if (TreeNode("Tabbing"))
        {
            Text("Use TAB/SHIFT+TAB to cycle through keyboard editable fields.");
            static u8 buf[32] = "hello";
            InputText("1", buf, len(buf));
            InputText("2", buf, len(buf));
            InputText("3", buf, len(buf));
            PushItemFlag(ImGuiItemFlags_NoTabStop, true);
            InputText("4 (tab skip)", buf, len(buf));
            SameLine(); HelpMarker("Item won't be cycled through when using TAB or Shift+Tab.");
            PopItemFlag();
            InputText("5", buf, len(buf));
            TreePop();
        }

        IMGUI_DEMO_MARKER("Inputs & Focus/Focus from code");
        if (TreeNode("Focus from code"))
        {
            focus_1 := Button("Focus on 1"); SameLine();
            focus_2 := Button("Focus on 2"); SameLine();
            focus_3 := Button("Focus on 3");
            has_focus := 0;
            static u8 buf[128] = "click on a button to set focus";

            if (focus_1) SetKeyboardFocusHere();
            InputText("1", buf, len(buf));
            if (IsItemActive()) has_focus = 1;

            if (focus_2) SetKeyboardFocusHere();
            InputText("2", buf, len(buf));
            if (IsItemActive()) has_focus = 2;

            PushItemFlag(ImGuiItemFlags_NoTabStop, true);
            if (focus_3) SetKeyboardFocusHere();
            InputText("3 (tab skip)", buf, len(buf));
            if (IsItemActive()) has_focus = 3;
            SameLine(); HelpMarker("Item won't be cycled through when using TAB or Shift+Tab.");
            PopItemFlag();

            if (has_focus)
                Text("Item with focus: %d", has_focus);
            else
                Text("Item with focus: <none>");

            // Use >= 0 parameter to SetKeyboardFocusHere() to focus an upcoming item
            static f32 f3[3] = { 0.0, 0.0, 0.0 };
            focus_ahead := -1;
            if (Button("Focus on X")) { focus_ahead = 0; } SameLine();
            if (Button("Focus on Y")) { focus_ahead = 1; } SameLine();
            if (Button("Focus on Z")) { focus_ahead = 2; }
            if (focus_ahead != -1) SetKeyboardFocusHere(focus_ahead);
            SliderFloat3("Float3", &f3[0], 0.0, 1.0);

            TextWrapped("NB: Cursor & selection are preserved when refocusing last used item in code.");
            TreePop();
        }

        IMGUI_DEMO_MARKER("Inputs & Focus/Dragging");
        if (TreeNode("Dragging"))
        {
            TextWrapped("You can use GetMouseDragDelta(0) to query for the dragged amount on any widget.");
            for i32 button = 0; button < 3; button++
            {
                Text("IsMouseDragging(%d):", button);
                Text("  w/ default threshold: %d,", IsMouseDragging(button));
                Text("  w/ zero threshold: %d,", IsMouseDragging(button, 0.0));
                Text("  w/ large threshold: %d,", IsMouseDragging(button, 20.0));
            }

            Button("Drag Me");
            if (IsItemActive())
                GetForegroundDrawList()->AddLine(io.MouseClickedPos[0], io.MousePos, GetColorU32(ImGuiCol_Button), 4.0); // Draw a line between the button and the mouse cursor

            // Drag operations gets "unlocked" when the mouse has moved past a certain threshold
            // (the default threshold is stored in io.MouseDragThreshold). You can request a lower or higher
            // threshold using the second parameter of IsMouseDragging() and GetMouseDragDelta().
            value_raw := GetMouseDragDelta(0, 0.0);
            value_with_lock_threshold := GetMouseDragDelta(0);
            mouse_delta := io.MouseDelta;
            Text("GetMouseDragDelta(0):");
            Text("  w/ default threshold: (%.1, %.1)", value_with_lock_threshold.x, value_with_lock_threshold.y);
            Text("  w/ zero threshold: (%.1, %.1)", value_raw.x, value_raw.y);
            Text("io.MouseDelta: (%.1, %.1)", mouse_delta.x, mouse_delta.y);
            TreePop();
        }
    }
}

//-----------------------------------------------------------------------------
// [SECTION] About Window / ShowAboutWindow()
// Access from Dear ImGui Demo -> Tools -> About
//-----------------------------------------------------------------------------

// [forward declared comment]:
// create About window. display Dear ImGui version, credits and build/system information.
ShowAboutWindow :: proc(p_open : ^bool = nil)
{
    if (!Begin("About Dear ImGui", p_open, ImGuiWindowFlags_AlwaysAutoResize))
    {
        End();
        return;
    }
    IMGUI_DEMO_MARKER("Tools/About Dear ImGui");
    Text("Dear ImGui %s (%d)", IMGUI_VERSION, IMGUI_VERSION_NUM);

    TextLinkOpenURL("Homepage", "https://github.com/ocornut/imgui");
    SameLine();
    TextLinkOpenURL("FAQ", "https://github.com/ocornut/imgui/blob/master/docs/FAQ.md");
    SameLine();
    TextLinkOpenURL("Wiki", "https://github.com/ocornut/imgui/wiki");
    SameLine();
    TextLinkOpenURL("Releases", "https://github.com/ocornut/imgui/releases");
    SameLine();
    TextLinkOpenURL("Funding", "https://github.com/ocornut/imgui/wiki/Funding");

    Separator();
    Text("(c) 2014-2025 Omar Cornut");
    Text("Developed by Omar Cornut and all Dear ImGui contributors.");
    Text("Dear ImGui is licensed under the MIT License, see LICENSE for more information.");
    Text("If your company uses this, please consider funding the project.");

    static bool show_config_info = false;
    Checkbox("Config/Build Information", &show_config_info);
    if (show_config_info)
    {
        ImGuiIO& io = GetIO();
        ImGuiStyle& style = GetStyle();

        copy_to_clipboard := Button("Copy to clipboard");
        child_size := ImVec2{0, GetTextLineHeightWithSpacing(} * 18);
        BeginChild(GetID("cfg_infos"), child_size, ImGuiChildFlags_FrameStyle);
        if (copy_to_clipboard)
        {
            LogToClipboard();
            LogText("```\n"); // Back quotes will make text appears without formatting when pasting on GitHub
        }

        Text("Dear ImGui %s (%d)", IMGUI_VERSION, IMGUI_VERSION_NUM);
        Separator();
        Text("size_of(int): %d, size_of(ImDrawIdx): %d, size_of(ImDrawVert): %d", cast(i32) size_of(int), cast(i32) size_of(ImDrawIdx), cast(i32) size_of(ImDrawVert));
        Text("define: __cplusplus=%d", cast(i32) __cplusplus);
        Text("define: IMGUI_DISABLE_OBSOLETE_FUNCTIONS");
when IMGUI_DISABLE_WIN32_DEFAULT_CLIPBOARD_FUNCTIONS {
        Text("define: IMGUI_DISABLE_WIN32_DEFAULT_CLIPBOARD_FUNCTIONS");
}
when IMGUI_DISABLE_WIN32_DEFAULT_IME_FUNCTIONS {
        Text("define: IMGUI_DISABLE_WIN32_DEFAULT_IME_FUNCTIONS");
}
when IMGUI_DISABLE_WIN32_FUNCTIONS {
        Text("define: IMGUI_DISABLE_WIN32_FUNCTIONS");
}
when IMGUI_DISABLE_DEFAULT_FORMAT_FUNCTIONS {
        Text("define: IMGUI_DISABLE_DEFAULT_FORMAT_FUNCTIONS");
}
when IMGUI_DISABLE_DEFAULT_MATH_FUNCTIONS {
        Text("define: IMGUI_DISABLE_DEFAULT_MATH_FUNCTIONS");
}
when IMGUI_DISABLE_DEFAULT_FILE_FUNCTIONS {
        Text("define: IMGUI_DISABLE_DEFAULT_FILE_FUNCTIONS");
}
when IMGUI_DISABLE_FILE_FUNCTIONS {
        Text("define: IMGUI_DISABLE_FILE_FUNCTIONS");
}
when IMGUI_DISABLE_DEFAULT_ALLOCATORS {
        Text("define: IMGUI_DISABLE_DEFAULT_ALLOCATORS");
}
when IMGUI_USE_BGRA_PACKED_COLOR {
        Text("define: IMGUI_USE_BGRA_PACKED_COLOR");
}
when _WIN32 {
        Text("define: _WIN32");
}
when _WIN64 {
        Text("define: _WIN64");
}
when __linux__ {
        Text("define: __linux__");
}
when __APPLE__ {
        Text("define: ODIN_OS == .Darwin");
}
when _MSC_VER {
        Text("define: _MSC_VER=%d", _MSC_VER);
}
when _MSVC_LANG {
        Text("define: _MSVC_LANG=%d", cast(i32) _MSVC_LANG);
}
when __MINGW32__ {
        Text("define: __MINGW32__");
}
when __MINGW64__ {
        Text("define: __MINGW64__");
}
when __GNUC__ {
        Text("define: __GNUC__=%d", cast(i32) __GNUC__);
}
when __clang_version__ {
        Text("define: __clang_version__=%s", __clang_version__);
}
when __EMSCRIPTEN__ {
        Text("define: __EMSCRIPTEN__");
        Text("Emscripten: %d.%d.%d", __EMSCRIPTEN_major__, __EMSCRIPTEN_minor__, __EMSCRIPTEN_tiny__);
}
when IMGUI_HAS_VIEWPORT {
        Text("define: IMGUI_HAS_VIEWPORT");
}
when IMGUI_HAS_DOCK {
        Text("define: IMGUI_HAS_DOCK");
}
        Separator();
        Text("io.BackendPlatformName: %s", io.BackendPlatformName ? io.BackendPlatformName : "nil");
        Text("io.BackendRendererName: %s", io.BackendRendererName ? io.BackendRendererName : "nil");
        Text("io.ConfigFlags: 0x%08X", io.ConfigFlags);
        if (io.ConfigFlags & ImGuiConfigFlags_NavEnableKeyboard)        Text(" NavEnableKeyboard");
        if (io.ConfigFlags & ImGuiConfigFlags_NavEnableGamepad)         Text(" NavEnableGamepad");
        if (io.ConfigFlags & ImGuiConfigFlags_NoMouse)                  Text(" NoMouse");
        if (io.ConfigFlags & ImGuiConfigFlags_NoMouseCursorChange)      Text(" NoMouseCursorChange");
        if (io.ConfigFlags & ImGuiConfigFlags_NoKeyboard)               Text(" NoKeyboard");
        if (io.ConfigFlags & ImGuiConfigFlags_DockingEnable)            Text(" DockingEnable");
        if (io.ConfigFlags & ImGuiConfigFlags_ViewportsEnable)          Text(" ViewportsEnable");
        if (io.ConfigFlags & ImGuiConfigFlags_DpiEnableScaleViewports)  Text(" DpiEnableScaleViewports");
        if (io.ConfigFlags & ImGuiConfigFlags_DpiEnableScaleFonts)      Text(" DpiEnableScaleFonts");
        if (io.MouseDrawCursor)                                         Text("io.MouseDrawCursor");
        if (io.ConfigViewportsNoAutoMerge)                              Text("io.ConfigViewportsNoAutoMerge");
        if (io.ConfigViewportsNoTaskBarIcon)                            Text("io.ConfigViewportsNoTaskBarIcon");
        if (io.ConfigViewportsNoDecoration)                             Text("io.ConfigViewportsNoDecoration");
        if (io.ConfigViewportsNoDefaultParent)                          Text("io.ConfigViewportsNoDefaultParent");
        if (io.ConfigDockingNoSplit)                                    Text("io.ConfigDockingNoSplit");
        if (io.ConfigDockingWithShift)                                  Text("io.ConfigDockingWithShift");
        if (io.ConfigDockingAlwaysTabBar)                               Text("io.ConfigDockingAlwaysTabBar");
        if (io.ConfigDockingTransparentPayload)                         Text("io.ConfigDockingTransparentPayload");
        if (io.ConfigMacOSXBehaviors)                                   Text("io.ConfigMacOSXBehaviors");
        if (io.ConfigNavMoveSetMousePos)                                Text("io.ConfigNavMoveSetMousePos");
        if (io.ConfigNavCaptureKeyboard)                                Text("io.ConfigNavCaptureKeyboard");
        if (io.ConfigInputTextCursorBlink)                              Text("io.ConfigInputTextCursorBlink");
        if (io.ConfigWindowsResizeFromEdges)                            Text("io.ConfigWindowsResizeFromEdges");
        if (io.ConfigWindowsMoveFromTitleBarOnly)                       Text("io.ConfigWindowsMoveFromTitleBarOnly");
        if (io.ConfigMemoryCompactTimer >= 0.0)                        Text("io.ConfigMemoryCompactTimer = %.1", io.ConfigMemoryCompactTimer);
        Text("io.BackendFlags: 0x%08X", io.BackendFlags);
        if (io.BackendFlags & ImGuiBackendFlags_HasGamepad)             Text(" HasGamepad");
        if (io.BackendFlags & ImGuiBackendFlags_HasMouseCursors)        Text(" HasMouseCursors");
        if (io.BackendFlags & ImGuiBackendFlags_HasSetMousePos)         Text(" HasSetMousePos");
        if (io.BackendFlags & ImGuiBackendFlags_PlatformHasViewports)   Text(" PlatformHasViewports");
        if (io.BackendFlags & ImGuiBackendFlags_HasMouseHoveredViewport)Text(" HasMouseHoveredViewport");
        if (io.BackendFlags & ImGuiBackendFlags_RendererHasVtxOffset)   Text(" RendererHasVtxOffset");
        if (io.BackendFlags & ImGuiBackendFlags_RendererHasViewports)   Text(" RendererHasViewports");
        Separator();
        Text("io.Fonts: %d fonts, Flags: 0x%08X, TexSize: %d,%d", io.Fonts.Fonts.Size, io.Fonts.Flags, io.Fonts.TexWidth, io.Fonts.TexHeight);
        Text("io.DisplaySize: %.2,%.2", io.DisplaySize.x, io.DisplaySize.y);
        Text("io.DisplayFramebufferScale: %.2,%.2", io.DisplayFramebufferScale.x, io.DisplayFramebufferScale.y);
        Separator();
        Text("style.WindowPadding: %.2,%.2", style.WindowPadding.x, style.WindowPadding.y);
        Text("style.WindowBorderSize: %.2", style.WindowBorderSize);
        Text("style.FramePadding: %.2,%.2", style.FramePadding.x, style.FramePadding.y);
        Text("style.FrameRounding: %.2", style.FrameRounding);
        Text("style.FrameBorderSize: %.2", style.FrameBorderSize);
        Text("style.ItemSpacing: %.2,%.2", style.ItemSpacing.x, style.ItemSpacing.y);
        Text("style.ItemInnerSpacing: %.2,%.2", style.ItemInnerSpacing.x, style.ItemInnerSpacing.y);

        if (copy_to_clipboard)
        {
            LogText("\n```\n");
            LogFinish();
        }
        EndChild();
    }
    End();
}

//-----------------------------------------------------------------------------
// [SECTION] Style Editor / ShowStyleEditor()
//-----------------------------------------------------------------------------
// - ShowFontSelector()
// - ShowStyleSelector()
// - ShowStyleEditor()
//-----------------------------------------------------------------------------

// Forward declare ShowFontAtlas() which isn't worth putting in public API yet
namespace ImGui { void ShowFontAtlas(ImFontAtlas* atlas); }

// Demo helper function to select among loaded fonts.
// Here we use the regular BeginCombo()/EndCombo() api which is the more flexible one.
// [forward declared comment]:
// add font selector block (not a window), essentially a combo listing the loaded fonts.
ShowFontSelector :: proc(label : ^u8)
{
    ImGuiIO& io = GetIO();
    font_current := GetFont();
    if (BeginCombo(label, font_current.GetDebugName()))
    {
        for ImFont* font : io.Fonts.Fonts
        {
            PushID((rawptr)font);
            if (Selectable(font.GetDebugName(), font == font_current))
                io.FontDefault = font;
            if (font == font_current)
                SetItemDefaultFocus();
            PopID();
        }
        EndCombo();
    }
    SameLine();
    HelpMarker(
        "- Load additional fonts with io.Fonts.AddFontFromFileTTF().\n"
        "- The font atlas is built when calling io.Fonts.GetTexDataAsXXXX() or io.Fonts.Build().\n"
        "- Read FAQ and docs/FONTS.md for more details.\n"
        "- If you need to add/remove fonts at runtime (e.g. for DPI change), do it before calling NewFrame().");
}

// Demo helper function to select among default colors. See ShowStyleEditor() for more advanced options.
// Here we use the simplified Combo() api that packs items into a single literal string.
// Useful for quick combo boxes where the choices are known locally.
// [forward declared comment]:
// add style selector block (not a window), essentially a combo listing the default styles.
ShowStyleSelector :: proc(label : ^u8) -> bool
{
    static i32 style_idx = -1;
    if (Combo(label, &style_idx, "Dark0x00Light0x00Classic0x00"))
    {
        switch (style_idx)
        {
        case 0: StyleColorsDark(); break;
        case 1: StyleColorsLight(); break;
        case 2: StyleColorsClassic(); break;
        }
        return true;
    }
    return false;
}

// [forward declared comment]:
// add style editor block (not a window). you can pass in a reference ImGuiStyle structure to compare to, revert to and save to (else it uses the default style)
ShowStyleEditor :: proc(ref : ^ImGuiStyle = nil)
{
    IMGUI_DEMO_MARKER("Tools/Style Editor");
    // You can pass in a reference ImGuiStyle structure to compare to, revert to and save to
    // (without a reference style pointer, we will use one compared locally as a reference)
    ImGuiStyle& style = GetStyle();
    static ImGuiStyle ref_saved_style;

    // Default to using internal storage as reference
    static bool init = true;
    if (init && ref == nil)
        ref_saved_style = style;
    init = false;
    if (ref == nil)
        ref = &ref_saved_style;

    PushItemWidth(GetWindowWidth() * 0.50);

    if (ShowStyleSelector("Colors##Selector"))
        ref_saved_style = style;
    ShowFontSelector("Fonts##Selector");

    // Simplified Settings (expose floating-pointer border sizes as boolean representing 0.0f or 1.0f)
    if (SliderFloat("FrameRounding", &style.FrameRounding, 0.0, 12.0, "%.0"))
        style.GrabRounding = style.FrameRounding; // Make GrabRounding always the same value as FrameRounding
    { bool border = (style.WindowBorderSize > 0.0); if (Checkbox("WindowBorder", &border)) { style.WindowBorderSize = border ? 1.0 : 0.0; } }
    SameLine();
    { bool border = (style.FrameBorderSize > 0.0);  if (Checkbox("FrameBorder",  &border)) { style.FrameBorderSize  = border ? 1.0 : 0.0; } }
    SameLine();
    { bool border = (style.PopupBorderSize > 0.0);  if (Checkbox("PopupBorder",  &border)) { style.PopupBorderSize  = border ? 1.0 : 0.0; } }

    // Save/Revert button
    if (Button("Save Ref"))
        ref^ = ref_saved_style = style;
    SameLine();
    if (Button("Revert Ref"))
        style = *ref;
    SameLine();
    HelpMarker(
        "Save/Revert in local non-persistent storage. Default Colors definition are not affected. "
        "Use \"Export\" below to save them somewhere.");

    Separator();

    if (BeginTabBar("##tabs", ImGuiTabBarFlags_None))
    {
        if (BeginTabItem("Sizes"))
        {
            SeparatorText("Main");
            SliderFloat2("WindowPadding", (f32*)&style.WindowPadding, 0.0, 20.0, "%.0");
            SliderFloat2("FramePadding", (f32*)&style.FramePadding, 0.0, 20.0, "%.0");
            SliderFloat2("ItemSpacing", (f32*)&style.ItemSpacing, 0.0, 20.0, "%.0");
            SliderFloat2("ItemInnerSpacing", (f32*)&style.ItemInnerSpacing, 0.0, 20.0, "%.0");
            SliderFloat2("TouchExtraPadding", (f32*)&style.TouchExtraPadding, 0.0, 10.0, "%.0");
            SliderFloat("IndentSpacing", &style.IndentSpacing, 0.0, 30.0, "%.0");
            SliderFloat("ScrollbarSize", &style.ScrollbarSize, 1.0, 20.0, "%.0");
            SliderFloat("GrabMinSize", &style.GrabMinSize, 1.0, 20.0, "%.0");

            SeparatorText("Borders");
            SliderFloat("WindowBorderSize", &style.WindowBorderSize, 0.0, 1.0, "%.0");
            SliderFloat("ChildBorderSize", &style.ChildBorderSize, 0.0, 1.0, "%.0");
            SliderFloat("PopupBorderSize", &style.PopupBorderSize, 0.0, 1.0, "%.0");
            SliderFloat("FrameBorderSize", &style.FrameBorderSize, 0.0, 1.0, "%.0");
            SliderFloat("TabBorderSize", &style.TabBorderSize, 0.0, 1.0, "%.0");
            SliderFloat("TabBarBorderSize", &style.TabBarBorderSize, 0.0, 2.0, "%.0");
            SliderFloat("TabBarOverlineSize", &style.TabBarOverlineSize, 0.0, 2.0, "%.0");
            SameLine(); HelpMarker("Overline is only drawn over the selected tab when ImGuiTabBarFlags_DrawSelectedOverline is set.");

            SeparatorText("Rounding");
            SliderFloat("WindowRounding", &style.WindowRounding, 0.0, 12.0, "%.0");
            SliderFloat("ChildRounding", &style.ChildRounding, 0.0, 12.0, "%.0");
            SliderFloat("FrameRounding", &style.FrameRounding, 0.0, 12.0, "%.0");
            SliderFloat("PopupRounding", &style.PopupRounding, 0.0, 12.0, "%.0");
            SliderFloat("ScrollbarRounding", &style.ScrollbarRounding, 0.0, 12.0, "%.0");
            SliderFloat("GrabRounding", &style.GrabRounding, 0.0, 12.0, "%.0");
            SliderFloat("TabRounding", &style.TabRounding, 0.0, 12.0, "%.0");

            SeparatorText("Tables");
            SliderFloat2("CellPadding", (f32*)&style.CellPadding, 0.0, 20.0, "%.0");
            SliderAngle("TableAngledHeadersAngle", &style.TableAngledHeadersAngle, -50.0, +50.0);
            SliderFloat2("TableAngledHeadersTextAlign", (f32*)&style.TableAngledHeadersTextAlign, 0.0, 1.0, "%.2");

            SeparatorText("Widgets");
            SliderFloat2("WindowTitleAlign", (f32*)&style.WindowTitleAlign, 0.0, 1.0, "%.2");
            window_menu_button_position := style.WindowMenuButtonPosition + 1;
            if (Combo("WindowMenuButtonPosition", (i32*)&window_menu_button_position, "None0x00Left0x00Right0x00"))
                style.WindowMenuButtonPosition = (ImGuiDir)(window_menu_button_position - 1);
            Combo("ColorButtonPosition", (i32*)&style.ColorButtonPosition, "Left0x00Right0x00");
            SliderFloat2("ButtonTextAlign", (f32*)&style.ButtonTextAlign, 0.0, 1.0, "%.2");
            SameLine(); HelpMarker("Alignment applies when a button is larger than its text content.");
            SliderFloat2("SelectableTextAlign", (f32*)&style.SelectableTextAlign, 0.0, 1.0, "%.2");
            SameLine(); HelpMarker("Alignment applies when a selectable is larger than its text content.");
            SliderFloat("SeparatorTextBorderSize", &style.SeparatorTextBorderSize, 0.0, 10.0, "%.0");
            SliderFloat2("SeparatorTextAlign", (f32*)&style.SeparatorTextAlign, 0.0, 1.0, "%.2");
            SliderFloat2("SeparatorTextPadding", (f32*)&style.SeparatorTextPadding, 0.0, 40.0, "%.0");
            SliderFloat("LogSliderDeadzone", &style.LogSliderDeadzone, 0.0, 12.0, "%.0");

            SeparatorText("Docking");
            SliderFloat("DockingSplitterSize", &style.DockingSeparatorSize, 0.0, 12.0, "%.0");

            SeparatorText("Tooltips");
            for i32 n = 0; n < 2; n++
                if (TreeNodeEx(n == 0 ? "HoverFlagsForTooltipMouse" : "HoverFlagsForTooltipNav"))
                {
                    p := (n == 0) ? &style.HoverFlagsForTooltipMouse : &style.HoverFlagsForTooltipNav;
                    CheckboxFlags("ImGuiHoveredFlags_DelayNone", p, ImGuiHoveredFlags_DelayNone);
                    CheckboxFlags("ImGuiHoveredFlags_DelayShort", p, ImGuiHoveredFlags_DelayShort);
                    CheckboxFlags("ImGuiHoveredFlags_DelayNormal", p, ImGuiHoveredFlags_DelayNormal);
                    CheckboxFlags("ImGuiHoveredFlags_Stationary", p, ImGuiHoveredFlags_Stationary);
                    CheckboxFlags("ImGuiHoveredFlags_NoSharedDelay", p, ImGuiHoveredFlags_NoSharedDelay);
                    TreePop();
                }

            SeparatorText("Misc");
            SliderFloat2("DisplayWindowPadding", (f32*)&style.DisplayWindowPadding, 0.0, 30.0, "%.0"); SameLine(); HelpMarker("Apply to regular windows: amount which we enforce to keep visible when moving near edges of your screen.");
            SliderFloat2("DisplaySafeAreaPadding", (f32*)&style.DisplaySafeAreaPadding, 0.0, 30.0, "%.0"); SameLine(); HelpMarker("Apply to every windows, menus, popups, tooltips: amount where we avoid displaying contents. Adjust if you cannot see the edges of your screen (e.g. on a TV where scaling has not been configured).");

            EndTabItem();
        }

        if (BeginTabItem("Colors"))
        {
            static i32 output_dest = 0;
            static bool output_only_modified = true;
            if (Button("Export"))
            {
                if (output_dest == 0)
                    LogToClipboard();
                else
                    LogToTTY();
                LogText("ImVec4* colors = GetStyle().Colors;" IM_NEWLINE);
                for i32 i = 0; i < ImGuiCol_COUNT; i++
                {
                    const ImVec4& col = style.Colors[i];
                    name := GetStyleColorName(i);
                    if (!output_only_modified || memcmp(&col, &ref.Colors[i], size_of(ImVec4)) != 0)
                        LogText("colors[ImGuiCol_%s]%*s= ImVec4{%.2f, %.2f, %.2f, %.2f};" IM_NEWLINE,
                            name, 23 - cast(ast) ast) nst) n), "", col.x, col.y, col.z, col.w);
                }
                LogFinish();
            }
            SameLine(); SetNextItemWidth(120); Combo("##output_type", &output_dest, "To Clipboard0x00To TTY0x00");
            SameLine(); Checkbox("Only Modified Colors", &output_only_modified);

            static ImGuiTextFilter filter;
            filter.Draw("Filter colors", GetFontSize() * 16);

            static ImGuiColorEditFlags alpha_flags = 0;
            if (RadioButton("Opaque", alpha_flags == ImGuiColorEditFlags_None))             { alpha_flags = ImGuiColorEditFlags_None; } SameLine();
            if (RadioButton("Alpha",  alpha_flags == ImGuiColorEditFlags_AlphaPreview))     { alpha_flags = ImGuiColorEditFlags_AlphaPreview; } SameLine();
            if (RadioButton("Both",   alpha_flags == ImGuiColorEditFlags_AlphaPreviewHalf)) { alpha_flags = ImGuiColorEditFlags_AlphaPreviewHalf; } SameLine();
            HelpMarker(
                "In the color list:\n"
                "Left-click on color square to open color picker,\n"
                "Right-click to open edit options menu.");

            SetNextWindowSizeConstraints(ImVec2{0.0, GetTextLineHeightWithSpacing(} * 10), ImVec2{math.F32_MAX, math.F32_MAX});
            BeginChild("##colors", ImVec2{0, 0}, ImGuiChildFlags_Borders | ImGuiChildFlags_NavFlattened, ImGuiWindowFlags_AlwaysVerticalScrollbar | ImGuiWindowFlags_AlwaysHorizontalScrollbar);
            PushItemWidth(GetFontSize() * -12);
            for i32 i = 0; i < ImGuiCol_COUNT; i++
            {
                name := GetStyleColorName(i);
                if (!filter.PassFilter(name))
                    continue;
                PushID(i);
when !(IMGUI_DISABLE_DEBUG_TOOLS) {
                if (Button("?"))
                    DebugFlashStyleColor((ImGuiCol)i);
                SetItemTooltip("Flash given color to identify places where it is used.");
                SameLine();
}
                ColorEdit4("##color", (f32*)&style.Colors[i], ImGuiColorEditFlags_AlphaBar | alpha_flags);
                if (memcmp(&style.Colors[i], &ref.Colors[i], size_of(ImVec4)) != 0)
                {
                    // Tips: in a real user application, you may want to merge and use an icon font into the main font,
                    // so instead of "Save"/"Revert" you'd use icons!
                    // Read the FAQ and docs/FONTS.md about using icon fonts. It's really easy and super convenient!
                    SameLine(0.0, style.ItemInnerSpacing.x); if (Button("Save")) { ref.Colors[i] = style.Colors[i]; }
                    SameLine(0.0, style.ItemInnerSpacing.x); if (Button("Revert")) { style.Colors[i] = ref.Colors[i]; }
                }
                SameLine(0.0, style.ItemInnerSpacing.x);
                TextUnformatted(name);
                PopID();
            }
            PopItemWidth();
            EndChild();

            EndTabItem();
        }

        if (BeginTabItem("Fonts"))
        {
            ImGuiIO& io = GetIO();
            atlas := io.Fonts;
            HelpMarker("Read FAQ and docs/FONTS.md for details on font loading.");
            ShowFontAtlas(atlas);

            // Post-baking font scaling. Note that this is NOT the nice way of scaling fonts, read below.
            // (we enforce hard clamping manually as by default DragFloat/SliderFloat allows CTRL+Click text to get out of bounds).
            MIN_SCALE := 0.3;
            MAX_SCALE := 2.0;
            HelpMarker(
                "Those are old settings provided for convenience.\n"
                "However, the _correct_ way of scaling your UI is currently to reload your font at the designed size, "
                "rebuild the font atlas, and call style.ScaleAllSizes() on a reference ImGuiStyle structure.\n"
                "Using those settings here will give you poor quality results.");
            static f32 window_scale = 1.0;
            PushItemWidth(GetFontSize() * 8);
            if (DragFloat("window scale", &window_scale, 0.005, MIN_SCALE, MAX_SCALE, "%.2", ImGuiSliderFlags_AlwaysClamp)) // Scale only this window
                SetWindowFontScale(window_scale);
            DragFloat("global scale", &io.FontGlobalScale, 0.005, MIN_SCALE, MAX_SCALE, "%.2", ImGuiSliderFlags_AlwaysClamp); // Scale everything
            PopItemWidth();

            EndTabItem();
        }

        if (BeginTabItem("Rendering"))
        {
            Checkbox("Anti-aliased lines", &style.AntiAliasedLines);
            SameLine();
            HelpMarker("When disabling anti-aliasing lines, you'll probably want to disable borders in your style as well.");

            Checkbox("Anti-aliased lines use texture", &style.AntiAliasedLinesUseTex);
            SameLine();
            HelpMarker("Faster lines using texture data. Require backend to render with bilinear filtering (not point/nearest filtering).");

            Checkbox("Anti-aliased fill", &style.AntiAliasedFill);
            PushItemWidth(GetFontSize() * 8);
            DragFloat("Curve Tessellation Tolerance", &style.CurveTessellationTol, 0.02, 0.10, 10.0, "%.2");
            if (style.CurveTessellationTol < 0.10) style.CurveTessellationTol = 0.10;

            // When editing the "Circle Segment Max Error" value, draw a preview of its effect on auto-tessellated circles.
            DragFloat("Circle Tessellation Max Error", &style.CircleTessellationMaxError , 0.005, 0.10, 5.0, "%.2", ImGuiSliderFlags_AlwaysClamp);
            show_samples := IsItemActive();
            if (show_samples)
                SetNextWindowPos(GetCursorScreenPos());
            if (show_samples && BeginTooltip())
            {
                TextUnformatted("(R = radius, N = approx number of segments)");
                Spacing();
                draw_list := GetWindowDrawList();
                min_widget_width := CalcTextSize("R: MMM\nN: MMM").x;
                for i32 n = 0; n < 8; n++
                {
                    RAD_MIN := 5.0;
                    RAD_MAX := 70.0;
                    rad := RAD_MIN + (RAD_MAX - RAD_MIN) * cast(ast) ast) a.0 - 1.0);

                    BeginGroup();

                    // N is not always exact here due to how PathArcTo() function work internally
                    Text("R: %.f\nN: %d", rad, draw_list._CalcCircleAutoSegmentCount(rad));

                    canvas_width := IM_MAX(min_widget_width, rad * 2.0);
                    offset_x := floorf(canvas_width * 0.5);
                    offset_y := floorf(RAD_MAX);

                    p1 := GetCursorScreenPos();
                    draw_list.AddCircle(ImVec2{p1.x + offset_x, p1.y + offset_y}, rad, GetColorU32(ImGuiCol_Text));
                    Dummy(ImVec2{canvas_width, RAD_MAX * 2});

                    /*
                    p2 := GetCursorScreenPos();
                    draw_list.AddCircleFilled(ImVec2{p2.x + offset_x, p2.y + offset_y}, rad, GetColorU32(ImGuiCol_Text));
                    Dummy(ImVec2{canvas_width, RAD_MAX * 2});
                    */

                    EndGroup();
                    SameLine();
                }
                EndTooltip();
            }
            SameLine();
            HelpMarker("When drawing circle primitives with \"num_segments == 0\" tesselation will be calculated automatically.");

            DragFloat("Global Alpha", &style.Alpha, 0.005, 0.20, 1.0, "%.2"); // Not exposing zero here so user doesn't "lose" the UI (zero alpha clips all widgets). But application code could have a toggle to switch between zero and non-zero.
            DragFloat("Disabled Alpha", &style.DisabledAlpha, 0.005, 0.0, 1.0, "%.2"); SameLine(); HelpMarker("Additional alpha multiplier for disabled items (multiply over current value of Alpha).");
            PopItemWidth();

            EndTabItem();
        }

        EndTabBar();
    }

    PopItemWidth();
}

//-----------------------------------------------------------------------------
// [SECTION] User Guide / ShowUserGuide()
//-----------------------------------------------------------------------------

// [forward declared comment]:
// add basic help/info block (not a window): how to manipulate ImGui as an end-user (mouse/keyboard controls).
ShowUserGuide :: proc()
{
    ImGuiIO& io = GetIO();
    BulletText("Double-click on title bar to collapse window.");
    BulletText(
        "Click and drag on lower corner to resize window\n"
        "(f64-click to auto fit window to its contents).");
    BulletText("CTRL+Click on a slider or drag box to input value as text.");
    BulletText("TAB/SHIFT+TAB to cycle through keyboard editable fields.");
    BulletText("CTRL+Tab to select a window.");
    if (io.FontAllowUserScaling)
        BulletText("CTRL+Mouse Wheel to zoom window contents.");
    BulletText("While inputing text:\n");
    Indent();
    BulletText("CTRL+Left/Right to word jump.");
    BulletText("CTRL+A or f64-click to select all.");
    BulletText("CTRL+X/C/V to use clipboard cut/copy/paste.");
    BulletText("CTRL+Z,CTRL+Y to undo/redo.");
    BulletText("ESCAPE to revert.");
    Unindent();
    BulletText("With keyboard navigation enabled:");
    Indent();
    BulletText("Arrow keys to navigate.");
    BulletText("Space to activate a widget.");
    BulletText("Return to input text into a widget.");
    BulletText("Escape to deactivate a widget, close popup, exit child window.");
    BulletText("Alt to jump to the menu layer of a window.");
    Unindent();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Main Menu Bar / ShowExampleAppMainMenuBar()
//-----------------------------------------------------------------------------
// - ShowExampleAppMainMenuBar()
// - ShowExampleMenuFile()
//-----------------------------------------------------------------------------

// Demonstrate creating a "main" fullscreen menu bar and populating it.
// Note the difference between BeginMainMenuBar() and BeginMenuBar():
// - BeginMenuBar() = menu-bar inside current window (which needs the ImGuiWindowFlags_MenuBar flag!)
// - BeginMainMenuBar() = helper to create menu-bar-sized window at the top of the main viewport + call BeginMenuBar() into it.
ShowExampleAppMainMenuBar :: proc()
{
    if (BeginMainMenuBar())
    {
        if (BeginMenu("File"))
        {
            ShowExampleMenuFile();
            EndMenu();
        }
        if (BeginMenu("Edit"))
        {
            if (MenuItem("Undo", "CTRL+Z")) {}
            if (MenuItem("Redo", "CTRL+Y", false, false)) {}  // Disabled item
            Separator();
            if (MenuItem("Cut", "CTRL+X")) {}
            if (MenuItem("Copy", "CTRL+C")) {}
            if (MenuItem("Paste", "CTRL+V")) {}
            EndMenu();
        }
        EndMainMenuBar();
    }
}

// Note that shortcuts are currently provided for display only
// (future version will add explicit flags to BeginMenu() to request processing shortcuts)
ShowExampleMenuFile :: proc()
{
    IMGUI_DEMO_MARKER("Examples/Menu");
    MenuItem("(demo menu)", nil, false, false);
    if (MenuItem("New")) {}
    if (MenuItem("Open", "Ctrl+O")) {}
    if (BeginMenu("Open Recent"))
    {
        MenuItem("fish_hat.c");
        MenuItem("fish_hat.inl");
        MenuItem("fish_hat.h");
        if (BeginMenu("More.."))
        {
            MenuItem("Hello");
            MenuItem("Sailor");
            if (BeginMenu("Recurse.."))
            {
                ShowExampleMenuFile();
                EndMenu();
            }
            EndMenu();
        }
        EndMenu();
    }
    if (MenuItem("Save", "Ctrl+S")) {}
    if (MenuItem("Save As..")) {}

    Separator();
    IMGUI_DEMO_MARKER("Examples/Menu/Options");
    if (BeginMenu("Options"))
    {
        static bool enabled = true;
        MenuItem("Enabled", "", &enabled);
        BeginChild("child", ImVec2{0, 60}, ImGuiChildFlags_Borders);
        for i32 i = 0; i < 10; i++
            Text("Scrolling Text %d", i);
        EndChild();
        static f32 f = 0.5;
        static i32 n = 0;
        SliderFloat("Value", &f, 0.0, 1.0);
        InputFloat("Input", &f, 0.1);
        Combo("Combo", &n, "Yes0x00No0x00Maybe0x000x00");
        EndMenu();
    }

    IMGUI_DEMO_MARKER("Examples/Menu/Colors");
    if (BeginMenu("Colors"))
    {
        sz := GetTextLineHeight();
        for i32 i = 0; i < ImGuiCol_COUNT; i++
        {
            name := GetStyleColorName((ImGuiCol)i);
            p := GetCursorScreenPos();
            GetWindowDrawList()->AddRectFilled(p, ImVec2{p.x + sz, p.y + sz}, GetColorU32((ImGuiCol)i));
            Dummy(ImVec2{sz, sz});
            SameLine();
            MenuItem(name);
        }
        EndMenu();
    }

    // Here we demonstrate appending again to the "Options" menu (which we already created above)
    // Of course in this demo it is a little bit silly that this function calls BeginMenu("Options") twice.
    // In a real code-base using it would make senses to use this feature from very different code locations.
    if (BeginMenu("Options")) // <-- Append!
    {
        IMGUI_DEMO_MARKER("Examples/Menu/Append to an existing menu");
        static bool b = true;
        Checkbox("SomeOption", &b);
        EndMenu();
    }

    if (BeginMenu("Disabled", false)) // Disabled
    {
        assert(false)
    }
    if (MenuItem("Checked", nil, true)) {}
    Separator();
    if (MenuItem("Quit", "Alt+F4")) {}
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Debug Console / ShowExampleAppConsole()
//-----------------------------------------------------------------------------

// Demonstrate creating a simple console window, with scrolling, filtering, completion and history.
// For the console example, we are using a more C++ like approach of declaring a class to hold both data and functions.
ExampleAppConsole :: struct
{
    InputBuf : [256]u8,
    Items : [dynamic]^u8,
    ImVector<const u8*> Commands;
    History : [dynamic]^u8,
    HistoryPos : i32,    // -1: new line, 0..History.Size-1 browsing history.
    Filter : ImGuiTextFilter,
    AutoScroll : bool,
    ScrollToBottom : bool,

    ExampleAppConsole()
    {
        IMGUI_DEMO_MARKER("Examples/Console");
        ClearLog();
        memset(InputBuf, 0, size_of(InputBuf));
        HistoryPos = -1;

        // "CLASSIFY" is here to provide the test case where "C"+[tab] completes to "CL" and display multiple matches.
        Commands.push_back("HELP");
        Commands.push_back("HISTORY");
        Commands.push_back("CLEAR");
        Commands.push_back("CLASSIFY");
        AutoScroll = true;
        ScrollToBottom = false;
        AddLog("Welcome to Dear ImGui!");
    }
    ~ExampleAppConsole()
    {
        ClearLog();
        for i32 i = 0; i < History.Size; i++
            MemFree(History[i]);
    }

    // Portable helpers
    static i32   Stricmp(const u8* s1, const u8* s2)         { i32 d; for ((d = toupper(*s2) - toupper(*s1)) == 0 && *s1) { s1 += 1; s2 += 1; } return d; }
    static i32   Strnicmp(const u8* s1, const u8* s2, i32 n) { i32 d = 0; for (n > 0 && (d = toupper(*s2) - toupper(*s1)) == 0 && *s1) { s1 += 1; s2 += 1; n -= 1; } return d; }
    static u8* Strdup(const u8* s)                           { assert(s); int len = strlen(s) + 1; rawptr buf = MemAlloc(len); assert(buf); return (u8*)memcpy(buf, (const rawptr)s, len); }
    static void  Strtrim(u8* s)                                { u8* str_end = s + strlen(s); for (str_end > s && str_end[-1] == ' ') str_end -= 1; *str_end = 0; }

    ClearLog :: proc()
    {
        for i32 i = 0; i < Items.Size; i++
            MemFree(Items[i]);
        Items.clear();
    }

    void    AddLog(const u8* fmt, ...) 
    {
        // FIXME-OPT
        buf : [1024]u8,
        args : va_list,
        va_start(args, fmt);
        vsnprintf(buf, len(buf), fmt, args);
        buf[len(buf)-1] = 0;
        va_end(args);
        Items.push_back(Strdup(buf));
    }

    // [forward declared comment]:
// Helper calling InputText+Build
Draw :: proc(title : ^u8 = "Filter (inc,-exc)", p_open : ^bool = 0.0)
    {
        SetNextWindowSize(ImVec2{520, 600}, ImGuiCond_FirstUseEver);
        if (!Begin(title, p_open))
        {
            End();
            return;
        }

        // As a specific feature guaranteed by the library, after calling Begin() the last Item represent the title bar.
        // So e.g. IsItemHovered() will return true when hovering the title bar.
        // Here we create a context menu only available from the title bar.
        if (BeginPopupContextItem())
        {
            if (MenuItem("Close Console"))
                p_open^ = false;
            EndPopup();
        }

        TextWrapped(
            "This example implements a console with basic coloring, completion (TAB key) and history (Up/Down keys). A more elaborate "
            "implementation may want to store entries along with extra data such as timestamp, emitter, etc.");
        TextWrapped("Enter 'HELP' for help.");

        // TODO: display items starting from the bottom

        if (SmallButton("Add Debug Text"))  { AddLog("%d some text", Items.Size); AddLog("some more text"); AddLog("display very important message here!"); }
        SameLine();
        if (SmallButton("Add Debug Error")) { AddLog("[error] something went wrong"); }
        SameLine();
        if (SmallButton("Clear"))           { ClearLog(); }
        SameLine();
        copy_to_clipboard := SmallButton("Copy");
        //static float t = 0.0f; if (ImGui::GetTime() - t > 0.02f) { t = ImGui::GetTime(); AddLog("Spam %f", t); }

        Separator();

        // Options menu
        if (BeginPopup("Options"))
        {
            Checkbox("Auto-scroll", &AutoScroll);
            EndPopup();
        }

        // Options, Filter
        SetNextItemShortcut(ImGuiMod_Ctrl | ImGuiKey_O, ImGuiInputFlags_Tooltip);
        if (Button("Options"))
            OpenPopup("Options");
        SameLine();
        Filter.Draw("Filter (\"incl,-excl\") (\"error\")", 180);
        Separator();

        // Reserve enough left-over height for 1 separator + 1 input text
        footer_height_to_reserve := GetStyle().ItemSpacing.y + GetFrameHeightWithSpacing();
        if (BeginChild("ScrollingRegion", ImVec2{0, -footer_height_to_reserve}, ImGuiChildFlags_NavFlattened, ImGuiWindowFlags_HorizontalScrollbar))
        {
            if (BeginPopupContextWindow())
            {
                if (Selectable("Clear")) ClearLog();
                EndPopup();
            }

            // Display every line as a separate entry so we can change their color or add custom widgets.
            // If you only want raw text you can use ImGui::TextUnformatted(log.begin(), log.end());
            // NB- if you have thousands of entries this approach may be too inefficient and may require user-side clipping
            // to only process visible items. The clipper will automatically measure the height of your first item and then
            // "seek" to display only items in the visible area.
            // To use the clipper we can replace your standard loop:
            //      for (int i = 0; i < Items.Size; i++)
            //   With:
            //      ImGuiListClipper clipper;
            //      clipper.Begin(Items.Size);
            //      while (clipper.Step())
            //         for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
            // - That your items are evenly spaced (same height)
            // - That you have cheap random access to your elements (you can access them given their index,
            //   without processing all the ones before)
            // You cannot this code as-is if a filter is active because it breaks the 'cheap random-access' property.
            // We would need random-access on the post-filtered list.
            // A typical application wanting coarse clipping and filtering may want to pre-compute an array of indices
            // or offsets of items that passed the filtering test, recomputing this array when user changes the filter,
            // and appending newly elements as they are inserted. This is left as a task to the user until we can manage
            // to improve this example code!
            // If your items are of variable height:
            // - Split them into same height items would be simpler and facilitate random-seeking into your list.
            // - Consider using manual call to IsRectVisible() and skipping extraneous decoration from your items.
            PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2{4, 1}); // Tighten spacing
            if (copy_to_clipboard)
                LogToClipboard();
            for const u8* item : Items
            {
                if (!Filter.PassFilter(item))
                    continue;

                // Normally you would store more information in your item than just a string.
                // (e.g. make Items[] an array of structure, store color/type etc.)
                color : ImVec4,
                has_color := false;
                if (strstr(item, "[error]")) { color = ImVec4{1.0, 0.4, 0.4, 1.0}; has_color = true; }
                else if (strncmp(item, "# ", 2) == 0) { color = ImVec4{1.0, 0.8, 0.6, 1.0}; has_color = true; }
                if (has_color)
                    PushStyleColor(ImGuiCol_Text, color);
                TextUnformatted(item);
                if (has_color)
                    PopStyleColor();
            }
            if (copy_to_clipboard)
                LogFinish();

            // Keep up at the bottom of the scroll region if we were already at the bottom at the beginning of the frame.
            // Using a scrollbar or mouse-wheel will take away from the bottom edge.
            if (ScrollToBottom || (AutoScroll && GetScrollY() >= GetScrollMaxY()))
                SetScrollHereY(1.0);
            ScrollToBottom = false;

            PopStyleVar();
        }
        EndChild();
        Separator();

        // Command-line
        reclaim_focus := false;
        input_text_flags := ImGuiInputTextFlags_EnterReturnsTrue | ImGuiInputTextFlags_EscapeClearsAll | ImGuiInputTextFlags_CallbackCompletion | ImGuiInputTextFlags_CallbackHistory;
        if (InputText("Input", InputBuf, len(InputBuf), input_text_flags, &TextEditCallbackStub, (rawptr)this))
        {
            s := InputBuf;
            Strtrim(s);
            if (s[0])
                ExecCommand(s);
            strcpy(s, "");
            reclaim_focus = true;
        }

        // Auto-focus on window apparition
        SetItemDefaultFocus();
        if (reclaim_focus)
            SetKeyboardFocusHere(-1); // Auto focus previous widget

        End();
    }

    ExecCommand :: proc(command_line : ^u8)
    {
        AddLog("# %s\n", command_line);

        // Insert into history. First find match and delete it so it can be pushed to the back.
        // This isn't trying to be smart or optimal.
        HistoryPos = -1;
        for i32 i = History.Size - 1; i >= 0; i--
            if (Stricmp(History[i], command_line) == 0)
            {
                MemFree(History[i]);
                History.erase(History.begin() + i);
                break;
            }
        History.push_back(Strdup(command_line));

        // Process command
        if (Stricmp(command_line, "CLEAR") == 0)
        {
            ClearLog();
        }
        else if (Stricmp(command_line, "HELP") == 0)
        {
            AddLog("Commands:");
            for i32 i = 0; i < Commands.Size; i++
                AddLog("- %s", Commands[i]);
        }
        else if (Stricmp(command_line, "HISTORY") == 0)
        {
            first := History.Size - 10;
            for i32 i = first > 0 ? first : 0; i < History.Size; i++
                AddLog("%3d: %s\n", i, History[i]);
        }
        else
        {
            AddLog("Unknown command: '%s'\n", command_line);
        }

        // On command input, we scroll to bottom even if AutoScroll==false
        ScrollToBottom = true;
    }

    // In C++11 you'd be better off using lambdas for this sort of forwarding callbacks
    static i32 TextEditCallbackStub(ImGuiInputTextCallbackData* data)
    {
        console := (ExampleAppConsole*)data.UserData;
        return console.TextEditCallback(data);
    }

    TextEditCallback :: proc(data : ^ImGuiInputTextCallbackData) -> i32
    {
        //AddLog("cursor: %d, selection: %d-%d", data->CursorPos, data->SelectionStart, data->SelectionEnd);
        switch (data.EventFlag)
        {
        case ImGuiInputTextFlags_CallbackCompletion:
            {
                // Example of TEXT COMPLETION

                // Locate beginning of current word
                word_end := data.Buf + data.CursorPos;
                word_start := word_end;
                for word_start > data.Buf
                {
                    c := word_start[-1];
                    if (c == ' ' || c == '\t' || c == ',' || c == ';')
                        break;
                    word_start -= 1;
                }

                // Build a list of candidates
                ImVector<const u8*> candidates;
                for i32 i = 0; i < Commands.Size; i++
                    if (Strnicmp(Commands[i], word_start, (i32)(word_end - word_start)) == 0)
                        candidates.push_back(Commands[i]);

                if (candidates.Size == 0)
                {
                    // No match
                    AddLog("No match for \"%.*s\"!\n", (i32)(word_end - word_start), word_start);
                }
                else if (candidates.Size == 1)
                {
                    // Single match. Delete the beginning of the word and replace it entirely so we've got nice casing.
                    data.DeleteChars((i32)(word_start - data.Buf), (i32)(word_end - word_start));
                    data.InsertChars(data.CursorPos, candidates[0]);
                    data.InsertChars(data.CursorPos, " ");
                }
                else
                {
                    // Multiple matches. Complete as much as we can..
                    // So inputing "C"+Tab will complete to "CL" then display "CLEAR" and "CLASSIFY" as matches.
                    match_len := (i32)(word_end - word_start);
                    for ;;
                    {
                        c := 0;
                        all_candidates_matches := true;
                        for i32 i = 0; i < candidates.Size && all_candidates_matches; i++
                            if (i == 0)
                                c = toupper(candidates[i][match_len]);
                            else if (c == 0 || c != toupper(candidates[i][match_len]))
                                all_candidates_matches = false;
                        if (!all_candidates_matches)
                            break;
                        match_len += 1;
                    }

                    if (match_len > 0)
                    {
                        data.DeleteChars((i32)(word_start - data.Buf), (i32)(word_end - word_start));
                        data.InsertChars(data.CursorPos, candidates[0], candidates[0] + match_len);
                    }

                    // List matches
                    AddLog("Possible matches:\n");
                    for i32 i = 0; i < candidates.Size; i++
                        AddLog("- %s\n", candidates[i]);
                }

                break;
            }
        case ImGuiInputTextFlags_CallbackHistory:
            {
                // Example of HISTORY
                prev_history_pos := HistoryPos;
                if (data.EventKey == ImGuiKey_UpArrow)
                {
                    if (HistoryPos == -1)
                        HistoryPos = History.Size - 1;
                    else if (HistoryPos > 0)
                        HistoryPos -= 1;
                }
                else if (data.EventKey == ImGuiKey_DownArrow)
                {
                    if (HistoryPos != -1)
                        if (++HistoryPos >= History.Size)
                            HistoryPos = -1;
                }

                // A better implementation would preserve the data on the current input line along with cursor position.
                if (prev_history_pos != HistoryPos)
                {
                    history_str := (HistoryPos >= 0) ? History[HistoryPos] : "";
                    data.DeleteChars(0, data.BufTextLen);
                    data.InsertChars(0, history_str);
                }
            }
        }
        return 0;
    }
};

ShowExampleAppConsole :: proc(p_open : ^bool)
{
    static ExampleAppConsole console;
    console.Draw("Example: Console", p_open);
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Debug Log / ShowExampleAppLog()
//-----------------------------------------------------------------------------

// Usage:
//  static ExampleAppLog my_log;
//  my_log.AddLog("Hello %d world\n", 123);
//  my_log.Draw("title");
ExampleAppLog :: struct
{
    Buf : ImGuiTextBuffer,
    Filter : ImGuiTextFilter,
    LineOffsets : [dynamic]i32, // Index to lines offset. We maintain this with AddLog() calls.
    AutoScroll : bool,  // Keep scrolling if already at the bottom.

    ExampleAppLog()
    {
        AutoScroll = true;
        Clear();
    }

    // [forward declared comment]:
// Clear all input and output.
Clear :: proc()
    {
        Buf.clear();
        LineOffsets.clear();
        LineOffsets.push_back(0);
    }

    void    AddLog(const u8* fmt, ...) 
    {
        old_size := Buf.size();
        args : va_list,
        va_start(args, fmt);
        Buf.appendfv(fmt, args);
        va_end(args);
        for i32 new_size = Buf.size(); old_size < new_size; old_size++
            if (Buf[old_size] == '\n')
                LineOffsets.push_back(old_size + 1);
    }

    // [forward declared comment]:
// Helper calling InputText+Build
Draw :: proc(title : ^u8 = "Filter (inc,-exc)", p_open : ^bool = 0.0 = nil)
    {
        if (!Begin(title, p_open))
        {
            End();
            return;
        }

        // Options menu
        if (BeginPopup("Options"))
        {
            Checkbox("Auto-scroll", &AutoScroll);
            EndPopup();
        }

        // Main window
        if (Button("Options"))
            OpenPopup("Options");
        SameLine();
        clear := Button("Clear");
        SameLine();
        copy := Button("Copy");
        SameLine();
        Filter.Draw("Filter", -100.0);

        Separator();

        if (BeginChild("scrolling", ImVec2{0, 0}, ImGuiChildFlags_None, ImGuiWindowFlags_HorizontalScrollbar))
        {
            if (clear)
                Clear();
            if (copy)
                LogToClipboard();

            PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2{0, 0});
            buf := Buf.begin();
            buf_end := Buf.end();
            if (Filter.IsActive())
            {
                // In this example we don't use the clipper when Filter is enabled.
                // This is because we don't have random access to the result of our filter.
                // A real application processing logs with ten of thousands of entries may want to store the result of
                // search/filter.. especially if the filtering function is not trivial (e.g. reg-exp).
                for i32 line_no = 0; line_no < LineOffsets.Size; line_no++
                {
                    line_start := buf + LineOffsets[line_no];
                    line_end := (line_no + 1 < LineOffsets.Size) ? (buf + LineOffsets[line_no + 1] - 1) : buf_end;
                    if (Filter.PassFilter(line_start, line_end))
                        TextUnformatted(line_start, line_end);
                }
            }
            else
            {
                // The simplest and easy way to display the entire buffer:
                //   ImGui::TextUnformatted(buf_begin, buf_end);
                // And it'll just work. TextUnformatted() has specialization for large blob of text and will fast-forward
                // to skip non-visible lines. Here we instead demonstrate using the clipper to only process lines that are
                // within the visible area.
                // If you have tens of thousands of items and their processing cost is non-negligible, coarse clipping them
                // on your side is recommended. Using ImGuiListClipper requires
                // - A) random access into your data
                // - B) items all being the  same height,
                // both of which we can handle since we have an array pointing to the beginning of each line of text.
                // When using the filter (in the block of code above) we don't have random access into the data to display
                // anymore, which is why we don't use the clipper. Storing or skimming through the search result would make
                // it possible (and would be recommended if you want to search through tens of thousands of entries).
                clipper : ImGuiListClipper,
                clipper.Begin(LineOffsets.Size);
                for clipper.Step()
                {
                    for i32 line_no = clipper.DisplayStart; line_no < clipper.DisplayEnd; line_no++
                    {
                        line_start := buf + LineOffsets[line_no];
                        line_end := (line_no + 1 < LineOffsets.Size) ? (buf + LineOffsets[line_no + 1] - 1) : buf_end;
                        TextUnformatted(line_start, line_end);
                    }
                }
                clipper.End();
            }
            PopStyleVar();

            // Keep up at the bottom of the scroll region if we were already at the bottom at the beginning of the frame.
            // Using a scrollbar or mouse-wheel will take away from the bottom edge.
            if (AutoScroll && GetScrollY() >= GetScrollMaxY())
                SetScrollHereY(1.0);
        }
        EndChild();
        End();
    }
};

// Demonstrate creating a simple log window with basic filtering.
ShowExampleAppLog :: proc(p_open : ^bool)
{
    static ExampleAppLog log;

    // For the demo: add a debug button _BEFORE_ the normal log window contents
    // We take advantage of a rarely used feature: multiple calls to Begin()/End() are appending to the _same_ window.
    // Most of the contents of the window will be added by the log.Draw() call.
    SetNextWindowSize(ImVec2{500, 400}, ImGuiCond_FirstUseEver);
    Begin("Example: Log", p_open);
    IMGUI_DEMO_MARKER("Examples/Log");
    if (SmallButton("[Debug] Add 5 entries"))
    {
        static i32 counter = 0;
        const u8* categories[3] = { "info", "warn", "error" };
        const u8* words[] = { "Bumfuzzled", "Cattywampus", "Snickersnee", "Abibliophobia", "Absquatulate", "Nincompoop", "Pauciloquent" };
        for i32 n = 0; n < 5; n++
        {
            category := categories[counter % len(categories)];
            word := words[counter % len(words)];
            log.AddLog("[%05d] [%s] Hello, current time is %.1, here's a word: '%s'\n",
                GetFrameCount(), category, GetTime(), word);
            counter += 1;
        }
    }
    End();

    // Actually call in the regular Log helper (which will Begin() into the same window as we just did)
    log.Draw("Example: Log", p_open);
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Simple Layout / ShowExampleAppLayout()
//-----------------------------------------------------------------------------

// Demonstrate create a window with multiple child windows.
ShowExampleAppLayout :: proc(p_open : ^bool)
{
    SetNextWindowSize(ImVec2{500, 440}, ImGuiCond_FirstUseEver);
    if (Begin("Example: Simple layout", p_open, ImGuiWindowFlags_MenuBar))
    {
        IMGUI_DEMO_MARKER("Examples/Simple layout");
        if (BeginMenuBar())
        {
            if (BeginMenu("File"))
            {
                if (MenuItem("Close", "Ctrl+W")) { *p_open = false; }
                EndMenu();
            }
            EndMenuBar();
        }

        // Left
        static i32 selected = 0;
        {
            BeginChild("left pane", ImVec2{150, 0}, ImGuiChildFlags_Borders | ImGuiChildFlags_ResizeX);
            for i32 i = 0; i < 100; i++
            {
                // FIXME: Good candidate to use ImGuiSelectableFlags_SelectOnNav
                label : [128]u8
                sprintf(label, "MyObject %d", i);
                if (Selectable(label, selected == i))
                    selected = i;
            }
            EndChild();
        }
        SameLine();

        // Right
        {
            BeginGroup();
            BeginChild("item view", ImVec2{0, -GetFrameHeightWithSpacing(})); // Leave room for 1 line below us
            Text("MyObject: %d", selected);
            Separator();
            if (BeginTabBar("##Tabs", ImGuiTabBarFlags_None))
            {
                if (BeginTabItem("Description"))
                {
                    TextWrapped("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ");
                    EndTabItem();
                }
                if (BeginTabItem("Details"))
                {
                    Text("ID: 0123456789");
                    EndTabItem();
                }
                EndTabBar();
            }
            EndChild();
            if (Button("Revert")) {}
            SameLine();
            if (Button("Save")) {}
            EndGroup();
        }
    }
    End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Property Editor / ShowExampleAppPropertyEditor()
//-----------------------------------------------------------------------------
// Some of the interactions are a bit lack-luster:
// - We would want pressing validating or leaving the filter to somehow restore focus.
// - We may want more advanced filtering (child nodes) and clipper support: both will need extra work.
// - We would want to customize some keyboard interactions to easily keyboard navigate between the tree and the properties.
//-----------------------------------------------------------------------------

ExampleAppPropertyEditor :: struct
{
    Filter : ImGuiTextFilter,
    VisibleNode := nil;

    // [forward declared comment]:
// Helper calling InputText+Build
Draw :: proc(root_node : ^ExampleTreeNode = "Filter (inc,-exc)")
    {
        // Left side: draw tree
        // - Currently using a table to benefit from RowBg feature
        if (BeginChild("##tree", ImVec2{300, 0}, ImGuiChildFlags_ResizeX | ImGuiChildFlags_Borders | ImGuiChildFlags_NavFlattened))
        {
            SetNextItemWidth(-math.F32_MIN);
            SetNextItemShortcut(ImGuiMod_Ctrl | ImGuiKey_F, ImGuiInputFlags_Tooltip);
            PushItemFlag(ImGuiItemFlags_NoNavDefaultFocus, true);
            if (InputTextWithHint("##Filter", "incl,-excl", Filter.InputBuf, len(Filter.InputBuf), ImGuiInputTextFlags_EscapeClearsAll))
                Filter.Build();
            PopItemFlag();

            if (BeginTable("##bg", 1, ImGuiTableFlags_RowBg))
            {
                for ExampleTreeNode* node : root_node.Childs
                    if (Filter.PassFilter(node.Name)) // Filter root node
                        DrawTreeNode(node);
                EndTable();
            }
        }
        EndChild();

        // Right side: draw properties
        SameLine();

        BeginGroup(); // Lock X position
        if (ExampleTreeNode* node = VisibleNode)
        {
            Text("%s", node.Name);
            TextDisabled("UID: 0x%08X", node.UID);
            Separator();
            if (BeginTable("##properties", 2, ImGuiTableFlags_Resizable | ImGuiTableFlags_ScrollY))
            {
                // Push object ID after we entered the table, so table is shared for all objects
                PushID(cast(ast) ast) ast);
                TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed);
                TableSetupColumn("", ImGuiTableColumnFlags_WidthStretch, 2.0); // Default twice larger
                if (node.HasData)
                {
                    // In a typical application, the structure description would be derived from a data-driven system.
                    // - We try to mimic this with our ExampleMemberInfo structure and the ExampleTreeNodeMemberInfos[] array.
                    // - Limits and some details are hard-coded to simplify the demo.
                    for const ExampleMemberInfo& field_desc : ExampleTreeNodeMemberInfos
                    {
                        TableNextRow();
                        PushID(field_desc.Name);
                        TableNextColumn();
                        AlignTextToFramePadding();
                        TextUnformatted(field_desc.Name);
                        TableNextColumn();
                        field_ptr := (rawptr)(((u8*)node) + field_desc.Offset);
                        switch (field_desc.DataType)
                        {
                        case ImGuiDataType_Bool:
                        {
                            assert(field_desc.DataCount == 1);
                            Checkbox("##Editor", (bool*)field_ptr);
                            break;
                        }
                        case ImGuiDataType_S32:
                        {
                            v_min := INT_MIN, v_max = INT_MAX;
                            SetNextItemWidth(-math.F32_MIN);
                            DragScalarN("##Editor", field_desc.DataType, field_ptr, field_desc.DataCount, 1.0, &v_min, &v_max);
                            break;
                        }
                        case ImGuiDataType_Float:
                        {
                            v_min := 0.0, v_max = 1.0;
                            SetNextItemWidth(-math.F32_MIN);
                            SliderScalarN("##Editor", field_desc.DataType, field_ptr, field_desc.DataCount, &v_min, &v_max);
                            break;
                        }
                        case ImGuiDataType_String:
                        {
                            InputText("##Editor", reinterpret_cast<u8*>(field_ptr), 28);
                            break;
                        }
                        }
                        PopID();
                    }
                }
                PopID();
                EndTable();
            }
        }
        EndGroup();
    }

    DrawTreeNode :: proc(node : ^ExampleTreeNode)
    {
        TableNextRow();
        TableNextColumn();
        PushID(node.UID);
        tree_flags := ImGuiTreeNodeFlags_None;
        tree_flags |= ImGuiTreeNodeFlags_OpenOnArrow | ImGuiTreeNodeFlags_OpenOnDoubleClick;    // Standard opening mode as we are likely to want to add selection afterwards
        tree_flags |= ImGuiTreeNodeFlags_NavLeftJumpsBackHere;                                  // Left arrow support
        if (node == VisibleNode)
            tree_flags |= ImGuiTreeNodeFlags_Selected;
        if (node.Childs.Size == 0)
            tree_flags |= ImGuiTreeNodeFlags_Leaf | ImGuiTreeNodeFlags_Bullet;
        if (node.DataMyBool == false)
            PushStyleColor(ImGuiCol_Text, GetStyle().Colors[ImGuiCol_TextDisabled]);
        node_open := TreeNodeEx("", tree_flags, "%s", node.Name);
        if (node.DataMyBool == false)
            PopStyleColor();
        if (IsItemFocused())
            VisibleNode = node;
        if (node_open)
        {
            for ExampleTreeNode* child : node.Childs
                DrawTreeNode(child);
            TreePop();
        }
        PopID();
    }
};

// Demonstrate creating a simple property editor.
ShowExampleAppPropertyEditor :: proc(p_open : ^bool, demo_data : ^ImGuiDemoWindowData)
{
    SetNextWindowSize(ImVec2{430, 450}, ImGuiCond_FirstUseEver);
    if (!Begin("Example: Property editor", p_open))
    {
        End();
        return;
    }

    IMGUI_DEMO_MARKER("Examples/Property Editor");
    static ExampleAppPropertyEditor property_editor;
    if (demo_data.DemoTree == nil)
        demo_data.DemoTree = ExampleTree_CreateDemoTree();
    property_editor.Draw(demo_data.DemoTree);

    End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Long Text / ShowExampleAppLongText()
//-----------------------------------------------------------------------------

// Demonstrate/test rendering huge amount of text, and the incidence of clipping.
ShowExampleAppLongText :: proc(p_open : ^bool)
{
    SetNextWindowSize(ImVec2{520, 600}, ImGuiCond_FirstUseEver);
    if (!Begin("Example: Long text display", p_open))
    {
        End();
        return;
    }
    IMGUI_DEMO_MARKER("Examples/Long text display");

    static i32 test_type = 0;
    static ImGuiTextBuffer log;
    static i32 lines = 0;
    Text("Printing unusually long amount of text.");
    Combo("Test type", &test_type,
        "Single call to TextUnformatted()0x00"
        "Multiple calls to Text(), clipped0x00"
        "Multiple calls to Text(), not clipped (slow)0x00");
    Text("Buffer contents: %d lines, %d bytes", lines, log.size());
    if (Button("Clear")) { log.clear(); lines = 0; }
    SameLine();
    if (Button("Add 1000 lines"))
    {
        for i32 i = 0; i < 1000; i++
            log.appendf("%i The quick brown fox jumps over the lazy dog\n", lines + i);
        lines += 1000;
    }
    BeginChild("Log");
    switch (test_type)
    {
    case 0:
        // Single call to TextUnformatted() with a big buffer
        TextUnformatted(log.begin(), log.end());
        break;
    case 1:
        {
            // Multiple calls to Text(), manually coarsely clipped - demonstrate how to use the ImGuiListClipper helper.
            PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2{0, 0});
            clipper : ImGuiListClipper
            clipper.Begin(lines);
            for clipper.Step()
                for i32 i = clipper.DisplayStart; i < clipper.DisplayEnd; i++
                    Text("%i The quick brown fox jumps over the lazy dog", i);
            PopStyleVar();
            break;
        }
    case 2:
        // Multiple calls to Text(), not clipped (slow)
        PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2{0, 0});
        for i32 i = 0; i < lines; i++
            Text("%i The quick brown fox jumps over the lazy dog", i);
        PopStyleVar();
        break;
    }
    EndChild();
    End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Auto Resize / ShowExampleAppAutoResize()
//-----------------------------------------------------------------------------

// Demonstrate creating a window which gets auto-resized according to its content.
ShowExampleAppAutoResize :: proc(p_open : ^bool)
{
    if (!Begin("Example: Auto-resizing window", p_open, ImGuiWindowFlags_AlwaysAutoResize))
    {
        End();
        return;
    }
    IMGUI_DEMO_MARKER("Examples/Auto-resizing window");

    static i32 lines = 10;
    TextUnformatted(
        "Window will resize every-frame to the size of its content.\n"
        "Note that you probably don't want to query the window size to\n"
        "output your content because that would create a feedback loop.");
    SliderInt("Number of lines", &lines, 1, 20);
    for i32 i = 0; i < lines; i++
        Text("%*sThis is line %d", i * 4, "", i); // Pad with space to extend size horizontally
    End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Constrained Resize / ShowExampleAppConstrainedResize()
//-----------------------------------------------------------------------------

// Demonstrate creating a window with custom resize constraints.
// Note that size constraints currently don't work on a docked window (when in 'docking' branch)
ShowExampleAppConstrainedResize :: proc(p_open : ^bool)
{
    CustomConstraints :: struct
    {
        // Helper functions to demonstrate programmatic constraints
        // FIXME: This doesn't take account of decoration size (e.g. title bar), library should make this easier.
        // FIXME: None of the three demos works consistently when resizing from borders.
        static void AspectRatio(ImGuiSizeCallbackData* data)
        {
            aspect_ratio := *(f32*)data.UserData;
            data.DesiredSize.y = (f32)(i32)(data.DesiredSize.x / aspect_ratio);
        }
        static void Square(ImGuiSizeCallbackData* data)
        {
            data.DesiredSize.x = data.DesiredSize.y = IM_MAX(data.DesiredSize.x, data.DesiredSize.y);
        }
        static void Step(ImGuiSizeCallbackData* data)
        {
            step := *(f32*)data.UserData;
            data.DesiredSize = ImVec2{(i32}(data.DesiredSize.x / step + 0.5) * step, (i32)(data.DesiredSize.y / step + 0.5) * step);
        }
    };

    const u8* test_desc[] =
    {
        "Between 100x100 and 500x500",
        "At least 100x100",
        "Resize vertical + lock current width",
        "Resize horizontal + lock current height",
        "Width Between 400 and 500",
        "Height at least 400",
        "Custom: Aspect Ratio 16:9",
        "Custom: Always Square",
        "Custom: Fixed Steps (100)",
    };

    // Options
    static bool auto_resize = false;
    static bool window_padding = true;
    static i32 type = 6; // Aspect Ratio
    static i32 display_lines = 10;

    // Submit constraint
    aspect_ratio := 16.0 / 9.0;
    fixed_step := 100.0;
    if (type == 0) SetNextWindowSizeConstraints(ImVec2{100, 100}, ImVec2{500, 500});         // Between 100x100 and 500x500
    if (type == 1) SetNextWindowSizeConstraints(ImVec2{100, 100}, ImVec2{math.F32_MAX, math.F32_MAX}); // Width > 100, Height > 100
    if (type == 2) SetNextWindowSizeConstraints(ImVec2{-1, 0},    ImVec2{-1, math.F32_MAX});      // Resize vertical + lock current width
    if (type == 3) SetNextWindowSizeConstraints(ImVec2{0, -1},    ImVec2{math.F32_MAX, -1});      // Resize horizontal + lock current height
    if (type == 4) SetNextWindowSizeConstraints(ImVec2{400, -1},  ImVec2{500, -1});          // Width Between and 400 and 500
    if (type == 5) SetNextWindowSizeConstraints(ImVec2{-1, 400},  ImVec2{-1, math.F32_MAX});      // Height at least 400
    if (type == 6) SetNextWindowSizeConstraints(ImVec2{0, 0},     ImVec2{math.F32_MAX, math.F32_MAX}, CustomConstraints::AspectRatio, (rawptr)&aspect_ratio);   // Aspect ratio
    if (type == 7) SetNextWindowSizeConstraints(ImVec2{0, 0},     ImVec2{math.F32_MAX, math.F32_MAX}, CustomConstraints::Square);                              // Always Square
    if (type == 8) SetNextWindowSizeConstraints(ImVec2{0, 0},     ImVec2{math.F32_MAX, math.F32_MAX}, CustomConstraints::Step, (rawptr)&fixed_step);            // Fixed Step

    // Submit window
    if (!window_padding)
        PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2{0.0, 0.0});
    window_flags := auto_resize ? ImGuiWindowFlags_AlwaysAutoResize : 0;
    window_open := Begin("Example: Constrained Resize", p_open, window_flags);
    if (!window_padding)
        PopStyleVar();
    if (window_open)
    {
        IMGUI_DEMO_MARKER("Examples/Constrained Resizing window");
        if (GetIO().KeyShift)
        {
            // Display a dummy viewport (in your real app you would likely use ImageButton() to display a texture.
            avail_size := GetContentRegionAvail();
            pos := GetCursorScreenPos();
            ColorButton("viewport", ImVec4{0.5, 0.2, 0.5, 1.0}, ImGuiColorEditFlags_NoTooltip | ImGuiColorEditFlags_NoDragDrop, avail_size);
            SetCursorScreenPos(ImVec2{pos.x + 10, pos.y + 10});
            Text("%.2 x %.2", avail_size.x, avail_size.y);
        }
        else
        {
            Text("(Hold SHIFT to display a dummy viewport)");
            if (IsWindowDocked())
                Text("Warning: Sizing Constraints won't work if the window is docked!");
            if (Button("Set 200x200")) { SetWindowSize(ImVec2{200, 200}); } SameLine();
            if (Button("Set 500x500")) { SetWindowSize(ImVec2{500, 500}); } SameLine();
            if (Button("Set 800x200")) { SetWindowSize(ImVec2{800, 200}); }
            SetNextItemWidth(GetFontSize() * 20);
            Combo("Constraint", &type, test_desc, len(test_desc));
            SetNextItemWidth(GetFontSize() * 20);
            DragInt("Lines", &display_lines, 0.2, 1, 100);
            Checkbox("Auto-resize", &auto_resize);
            Checkbox("Window padding", &window_padding);
            for i32 i = 0; i < display_lines; i++
                Text("%*sHello, sailor! Making this line long enough for the example.", i * 4, "");
        }
    }
    End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Simple overlay / ShowExampleAppSimpleOverlay()
//-----------------------------------------------------------------------------

// Demonstrate creating a simple static window with no decoration
// + a context-menu to choose which corner of the screen to use.
ShowExampleAppSimpleOverlay :: proc(p_open : ^bool)
{
    static i32 location = 0;
    ImGuiIO& io = GetIO();
    window_flags := ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoDocking | ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoFocusOnAppearing | ImGuiWindowFlags_NoNav;
    if (location >= 0)
    {
        PAD := 10.0;
        viewport := GetMainViewport();
        work_pos := viewport.WorkPos; // Use work area to avoid menu-bar/task-bar, if any!
        work_size := viewport.WorkSize;
        window_pos, window_pos_pivot : ImVec2
        window_pos.x = (location & 1) ? (work_pos.x + work_size.x - PAD) : (work_pos.x + PAD);
        window_pos.y = (location & 2) ? (work_pos.y + work_size.y - PAD) : (work_pos.y + PAD);
        window_pos_pivot.x = (location & 1) ? 1.0 : 0.0;
        window_pos_pivot.y = (location & 2) ? 1.0 : 0.0;
        SetNextWindowPos(window_pos, ImGuiCond_Always, window_pos_pivot);
        SetNextWindowViewport(viewport.ID);
        window_flags |= ImGuiWindowFlags_NoMove;
    }
    else if (location == -2)
    {
        // Center window
        SetNextWindowPos(GetMainViewport()->GetCenter(), ImGuiCond_Always, ImVec2{0.5, 0.5});
        window_flags |= ImGuiWindowFlags_NoMove;
    }
    SetNextWindowBgAlpha(0.35); // Transparent background
    if (Begin("Example: Simple overlay", p_open, window_flags))
    {
        IMGUI_DEMO_MARKER("Examples/Simple Overlay");
        Text("Simple overlay\n" "(right-click to change position)");
        Separator();
        if (IsMousePosValid())
            Text("Mouse Position: (%.1,%.1)", io.MousePos.x, io.MousePos.y);
        else
            Text("Mouse Position: <invalid>");
        if (BeginPopupContextWindow())
        {
            if (MenuItem("Custom",       nil, location == -1)) location = -1;
            if (MenuItem("Center",       nil, location == -2)) location = -2;
            if (MenuItem("Top-left",     nil, location == 0)) location = 0;
            if (MenuItem("Top-right",    nil, location == 1)) location = 1;
            if (MenuItem("Bottom-left",  nil, location == 2)) location = 2;
            if (MenuItem("Bottom-right", nil, location == 3)) location = 3;
            if (p_open && MenuItem("Close")) *p_open = false;
            EndPopup();
        }
    }
    End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Fullscreen window / ShowExampleAppFullscreen()
//-----------------------------------------------------------------------------

// Demonstrate creating a window covering the entire screen/viewport
ShowExampleAppFullscreen :: proc(p_open : ^bool)
{
    static bool use_work_area = true;
    static ImGuiWindowFlags flags = ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoSavedSettings;

    // We demonstrate using the full viewport area or the work area (without menu-bars, task-bars etc.)
    // Based on your use case you may want one or the other.
    viewport := GetMainViewport();
    SetNextWindowPos(use_work_area ? viewport.WorkPos : viewport.Pos);
    SetNextWindowSize(use_work_area ? viewport.WorkSize : viewport.Size);

    if (Begin("Example: Fullscreen window", p_open, flags))
    {
        Checkbox("Use work area instead of main area", &use_work_area);
        SameLine();
        HelpMarker("Main Area = entire viewport,\nWork Area = entire viewport minus sections used by the main menu bars, task bars etc.\n\nEnable the main-menu bar in Examples menu to see the difference.");

        CheckboxFlags("ImGuiWindowFlags_NoBackground", &flags, ImGuiWindowFlags_NoBackground);
        CheckboxFlags("ImGuiWindowFlags_NoDecoration", &flags, ImGuiWindowFlags_NoDecoration);
        Indent();
        CheckboxFlags("ImGuiWindowFlags_NoTitleBar", &flags, ImGuiWindowFlags_NoTitleBar);
        CheckboxFlags("ImGuiWindowFlags_NoCollapse", &flags, ImGuiWindowFlags_NoCollapse);
        CheckboxFlags("ImGuiWindowFlags_NoScrollbar", &flags, ImGuiWindowFlags_NoScrollbar);
        Unindent();

        if (p_open && Button("Close this window"))
            p_open^ = false;
    }
    End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Manipulating Window Titles / ShowExampleAppWindowTitles()
//-----------------------------------------------------------------------------

// Demonstrate the use of "##" and "###" in identifiers to manipulate ID generation.
// This applies to all regular items as well.
// Read FAQ section "How can I have multiple widgets with the same label?" for details.
ShowExampleAppWindowTitles :: proc(bool*)
{
    viewport := GetMainViewport();
    base_pos := viewport.Pos;

    // By default, Windows are uniquely identified by their title.
    // You can use the "##" and "###" markers to manipulate the display/ID.

    // Using "##" to display same title but have unique identifier.
    SetNextWindowPos(ImVec2{base_pos.x + 100, base_pos.y + 100}, ImGuiCond_FirstUseEver);
    Begin("Same title as another window##1");
    IMGUI_DEMO_MARKER("Examples/Manipulating window titles");
    Text("This is window 1.\nMy title is the same as window 2, but my identifier is unique.");
    End();

    SetNextWindowPos(ImVec2{base_pos.x + 100, base_pos.y + 200}, ImGuiCond_FirstUseEver);
    Begin("Same title as another window##2");
    Text("This is window 2.\nMy title is the same as window 1, but my identifier is unique.");
    End();

    // Using "###" to display a changing title but keep a static identifier "AnimatedTitle"
    buf : [128]u8
    sprintf(buf, "Animated title %c %d###AnimatedTitle", "|/-\\"[(i32)(GetTime() / 0.25) & 3], GetFrameCount());
    SetNextWindowPos(ImVec2{base_pos.x + 100, base_pos.y + 300}, ImGuiCond_FirstUseEver);
    Begin(buf);
    Text("This window has a changing title.");
    End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Custom Rendering using ImDrawList API / ShowExampleAppCustomRendering()
//-----------------------------------------------------------------------------

// Add a |_| looking shape
PathConcaveShape :: proc(draw_list : ^ImDrawList, x : f32, y : f32, sz : f32)
{
    const ImVec2 pos_norms[] = { { 0.0, 0.0 }, { 0.3, 0.0 }, { 0.3, 0.7 }, { 0.7, 0.7 }, { 0.7, 0.0 }, { 1.0, 0.0 }, { 1.0, 1.0 }, { 0.0, 1.0 } };
    for const ImVec2& p : pos_norms
        draw_list.PathLineTo(ImVec2{x + 0.5 + (i32}(sz * p.x), y + 0.5 + (i32)(sz * p.y)));
}

// Demonstrate using the low-level ImDrawList to draw custom shapes.
ShowExampleAppCustomRendering :: proc(p_open : ^bool)
{
    if (!Begin("Example: Custom rendering", p_open))
    {
        End();
        return;
    }
    IMGUI_DEMO_MARKER("Examples/Custom Rendering");

    // Tip: If you do a lot of custom rendering, you probably want to use your own geometrical types and benefit of
    // overloaded operators, etc. Define IM_VEC2_CLASS_EXTRA in imconfig.h to create implicit conversions between your
    // types and ImVec2/ImVec4. Dear ImGui defines overloaded operators but they are internal to imgui.cpp and not
    // exposed outside (to avoid messing with your types) In this example we are not using the maths operators!

    if (BeginTabBar("##TabBar"))
    {
        if (BeginTabItem("Primitives"))
        {
            PushItemWidth(-GetFontSize() * 15);
            draw_list := GetWindowDrawList();

            // Draw gradients
            // (note that those are currently exacerbating our sRGB/Linear issues)
            // Calling ImGui::GetColorU32() multiplies the given colors by the current Style Alpha, but you may pass the IM_COL32() directly as well..
            Text("Gradients");
            gradient_size := ImVec2{CalcItemWidth(}, GetFrameHeight());
            {
                p0 := GetCursorScreenPos();
                p1 := ImVec2{p0.x + gradient_size.x, p0.y + gradient_size.y};
                col_a := GetColorU32(IM_COL32(0, 0, 0, 255));
                col_b := GetColorU32(IM_COL32(255, 255, 255, 255));
                draw_list.AddRectFilledMultiColor(p0, p1, col_a, col_b, col_b, col_a);
                InvisibleButton("##gradient1", gradient_size);
            }
            {
                p0 := GetCursorScreenPos();
                p1 := ImVec2{p0.x + gradient_size.x, p0.y + gradient_size.y};
                col_a := GetColorU32(IM_COL32(0, 255, 0, 255));
                col_b := GetColorU32(IM_COL32(255, 0, 0, 255));
                draw_list.AddRectFilledMultiColor(p0, p1, col_a, col_b, col_b, col_a);
                InvisibleButton("##gradient2", gradient_size);
            }

            // Draw a bunch of primitives
            Text("All primitives");
            static f32 sz = 36.0;
            static f32 thickness = 3.0;
            static i32 ngon_sides = 6;
            static bool circle_segments_override = false;
            static i32 circle_segments_override_v = 12;
            static bool curve_segments_override = false;
            static i32 curve_segments_override_v = 8;
            static ImVec4 colf = ImVec4{1.0, 1.0, 0.4, 1.0};
            DragFloat("Size", &sz, 0.2, 2.0, 100.0, "%.0");
            DragFloat("Thickness", &thickness, 0.05, 1.0, 8.0, "%.02");
            SliderInt("N-gon sides", &ngon_sides, 3, 12);
            Checkbox("##circlesegmentoverride", &circle_segments_override);
            SameLine(0.0, GetStyle().ItemInnerSpacing.x);
            circle_segments_override |= SliderInt("Circle segments override", &circle_segments_override_v, 3, 40);
            Checkbox("##curvessegmentoverride", &curve_segments_override);
            SameLine(0.0, GetStyle().ItemInnerSpacing.x);
            curve_segments_override |= SliderInt("Curves segments override", &curve_segments_override_v, 3, 40);
            ColorEdit4("Color", &colf.x);

            p := GetCursorScreenPos();
            col := ImColor(colf);
            spacing := 10.0;
            corners_tl_br := ImDrawFlags_RoundCornersTopLeft | ImDrawFlags_RoundCornersBottomRight;
            rounding := sz / 5.0;
            circle_segments := circle_segments_override ? circle_segments_override_v : 0;
            curve_segments := curve_segments_override ? curve_segments_override_v : 0;
            const ImVec2 cp3[3] = { ImVec2{0.0, sz * 0.6}, ImVec2{sz * 0.5, -sz * 0.4}, ImVec2{sz, sz} }; // Control points for curves
            const ImVec2 cp4[4] = { ImVec2{0.0, 0.0}, ImVec2{sz * 1.3, sz * 0.3}, ImVec2{sz - sz * 1.3, sz - sz * 0.3}, ImVec2{sz, sz} };

            x := p.x + 4.0;
            y := p.y + 4.0;
            for i32 n = 0; n < 2; n++
            {
                // First line uses a thickness of 1.0f, second line uses the configurable thickness
                th := (n == 0) ? 1.0 : thickness;
                draw_list.AddNgon(ImVec2{x + sz*0.5, y + sz*0.5}, sz*0.5, col, ngon_sides, th);                 x += sz + spacing;  // N-gon
                draw_list.AddCircle(ImVec2{x + sz*0.5, y + sz*0.5}, sz*0.5, col, circle_segments, th);          x += sz + spacing;  // Circle
                draw_list.AddEllipse(ImVec2{x + sz*0.5, y + sz*0.5}, ImVec2{sz*0.5, sz*0.3}, col, -0.3, circle_segments, th); x += sz + spacing;	// Ellipse
                draw_list.AddRect(ImVec2{x, y}, ImVec2{x + sz, y + sz}, col, 0.0, ImDrawFlags_None, th);          x += sz + spacing;  // Square
                draw_list.AddRect(ImVec2{x, y}, ImVec2{x + sz, y + sz}, col, rounding, ImDrawFlags_None, th);      x += sz + spacing;  // Square with all rounded corners
                draw_list.AddRect(ImVec2{x, y}, ImVec2{x + sz, y + sz}, col, rounding, corners_tl_br, th);         x += sz + spacing;  // Square with two rounded corners
                draw_list.AddTriangle(ImVec2{x+sz*0.5,y}, ImVec2{x+sz, y+sz-0.5}, ImVec2{x, y+sz-0.5}, col, th);x += sz + spacing;  // Triangle
                //draw_list->AddTriangle(ImVec2(x+sz*0.2f,y), ImVec2(x, y+sz-0.5f), ImVec2(x+sz*0.4f, y+sz-0.5f), col, th);x+= sz*0.4f + spacing; // Thin triangle
                PathConcaveShape(draw_list, x, y, sz); draw_list.PathStroke(col, ImDrawFlags_Closed, th);          x += sz + spacing;  // Concave Shape
                //draw_list->AddPolyline(concave_shape, IM_ARRAYSIZE(concave_shape), col, ImDrawFlags_Closed, th);
                draw_list.AddLine(ImVec2{x, y}, ImVec2{x + sz, y}, col, th);                                       x += sz + spacing;  // Horizontal line (note: drawing a filled rectangle will be faster!)
                draw_list.AddLine(ImVec2{x, y}, ImVec2{x, y + sz}, col, th);                                       x += spacing;       // Vertical line (note: drawing a filled rectangle will be faster!)
                draw_list.AddLine(ImVec2{x, y}, ImVec2{x + sz, y + sz}, col, th);                                  x += sz + spacing;  // Diagonal line

                // Path
                draw_list.PathArcTo(ImVec2{x + sz*0.5, y + sz*0.5}, sz*0.5, 3.141592, 3.141592 * -0.5);
                draw_list.PathStroke(col, ImDrawFlags_None, th);
                x += sz + spacing;

                // Quadratic Bezier Curve (3 control points)
                draw_list.AddBezierQuadratic(ImVec2{x + cp3[0].x, y + cp3[0].y}, ImVec2{x + cp3[1].x, y + cp3[1].y}, ImVec2{x + cp3[2].x, y + cp3[2].y}, col, th, curve_segments);
                x += sz + spacing;

                // Cubic Bezier Curve (4 control points)
                draw_list.AddBezierCubic(ImVec2{x + cp4[0].x, y + cp4[0].y}, ImVec2{x + cp4[1].x, y + cp4[1].y}, ImVec2{x + cp4[2].x, y + cp4[2].y}, ImVec2{x + cp4[3].x, y + cp4[3].y}, col, th, curve_segments);

                x = p.x + 4;
                y += sz + spacing;
            }

            // Filled shapes
            draw_list.AddNgonFilled(ImVec2{x + sz * 0.5, y + sz * 0.5}, sz * 0.5, col, ngon_sides);             x += sz + spacing;  // N-gon
            draw_list.AddCircleFilled(ImVec2{x + sz * 0.5, y + sz * 0.5}, sz * 0.5, col, circle_segments);      x += sz + spacing;  // Circle
            draw_list.AddEllipseFilled(ImVec2{x + sz * 0.5, y + sz * 0.5}, ImVec2{sz * 0.5, sz * 0.3}, col, -0.3, circle_segments); x += sz + spacing;// Ellipse
            draw_list.AddRectFilled(ImVec2{x, y}, ImVec2{x + sz, y + sz}, col);                                    x += sz + spacing;  // Square
            draw_list.AddRectFilled(ImVec2{x, y}, ImVec2{x + sz, y + sz}, col, 10.0);                             x += sz + spacing;  // Square with all rounded corners
            draw_list.AddRectFilled(ImVec2{x, y}, ImVec2{x + sz, y + sz}, col, 10.0, corners_tl_br);              x += sz + spacing;  // Square with two rounded corners
            draw_list.AddTriangleFilled(ImVec2{x+sz*0.5,y}, ImVec2{x+sz, y+sz-0.5}, ImVec2{x, y+sz-0.5}, col);  x += sz + spacing;  // Triangle
            //draw_list->AddTriangleFilled(ImVec2(x+sz*0.2f,y), ImVec2(x, y+sz-0.5f), ImVec2(x+sz*0.4f, y+sz-0.5f), col); x += sz*0.4f + spacing; // Thin triangle
            PathConcaveShape(draw_list, x, y, sz); draw_list.PathFillConcave(col);                                 x += sz + spacing;  // Concave shape
            draw_list.AddRectFilled(ImVec2{x, y}, ImVec2{x + sz, y + thickness}, col);                             x += sz + spacing;  // Horizontal line (faster than AddLine, but only handle integer thickness)
            draw_list.AddRectFilled(ImVec2{x, y}, ImVec2{x + thickness, y + sz}, col);                             x += spacing * 2.0;// Vertical line (faster than AddLine, but only handle integer thickness)
            draw_list.AddRectFilled(ImVec2{x, y}, ImVec2{x + 1, y + 1}, col);                                      x += sz;            // Pixel (faster than AddLine)

            // Path
            draw_list.PathArcTo(ImVec2{x + sz * 0.5, y + sz * 0.5}, sz * 0.5, 3.141592 * -0.5, 3.141592);
            draw_list.PathFillConvex(col);
            x += sz + spacing;

            // Quadratic Bezier Curve (3 control points)
            draw_list.PathLineTo(ImVec2{x + cp3[0].x, y + cp3[0].y});
            draw_list.PathBezierQuadraticCurveTo(ImVec2{x + cp3[1].x, y + cp3[1].y}, ImVec2{x + cp3[2].x, y + cp3[2].y}, curve_segments);
            draw_list.PathFillConvex(col);
            x += sz + spacing;

            draw_list.AddRectFilledMultiColor(ImVec2{x, y}, ImVec2{x + sz, y + sz}, IM_COL32(0, 0, 0, 255), IM_COL32(255, 0, 0, 255), IM_COL32(255, 255, 0, 255), IM_COL32(0, 255, 0, 255));
            x += sz + spacing;

            Dummy(ImVec2{(sz + spacing} * 13.2, (sz + spacing) * 3.0));
            PopItemWidth();
            EndTabItem();
        }

        if (BeginTabItem("Canvas"))
        {
            static ImVector<ImVec2> points;
            static ImVec2 scrolling(0.0, 0.0);
            static bool opt_enable_grid = true;
            static bool opt_enable_context_menu = true;
            static bool adding_line = false;

            Checkbox("Enable grid", &opt_enable_grid);
            Checkbox("Enable context menu", &opt_enable_context_menu);
            Text("Mouse Left: drag to add lines,\nMouse Right: drag to scroll, click for context menu.");

            // Typically you would use a BeginChild()/EndChild() pair to benefit from a clipping region + own scrolling.
            // Here we demonstrate that this can be replaced by simple offsetting + custom drawing + PushClipRect/PopClipRect() calls.
            // To use a child window instead we could use, e.g:
            //      ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0, 0));      // Disable padding
            //      ImGui::PushStyleColor(ImGuiCol_ChildBg, IM_COL32(50, 50, 50, 255));  // Set a background color
            //      ImGui::BeginChild("canvas", ImVec2(0.0f, 0.0f), ImGuiChildFlags_Borders, ImGuiWindowFlags_NoMove);
            //      ImGui::PopStyleColor();
            //      ImGui::PopStyleVar();
            //      [...]
            //      ImGui::EndChild();

            // Using InvisibleButton() as a convenience 1) it will advance the layout cursor and 2) allows us to use IsItemHovered()/IsItemActive()
            canvas_p0 := GetCursorScreenPos();      // ImDrawList API uses screen coordinates!
            canvas_sz := GetContentRegionAvail();   // Resize canvas to what's available
            if (canvas_sz.x < 50.0) canvas_sz.x = 50.0;
            if (canvas_sz.y < 50.0) canvas_sz.y = 50.0;
            canvas_p1 := ImVec2{canvas_p0.x + canvas_sz.x, canvas_p0.y + canvas_sz.y};

            // Draw border and background color
            ImGuiIO& io = GetIO();
            draw_list := GetWindowDrawList();
            draw_list.AddRectFilled(canvas_p0, canvas_p1, IM_COL32(50, 50, 50, 255));
            draw_list.AddRect(canvas_p0, canvas_p1, IM_COL32(255, 255, 255, 255));

            // This will catch our interactions
            InvisibleButton("canvas", canvas_sz, ImGuiButtonFlags_MouseButtonLeft | ImGuiButtonFlags_MouseButtonRight);
            is_hovered := IsItemHovered(); // Hovered
            is_active := IsItemActive();   // Held
            origin := ImVec2{canvas_p0.x + scrolling.x, canvas_p0.y + scrolling.y}; // Lock scrolled origin
            mouse_pos_in_canvas := ImVec2{io.MousePos.x - origin.x, io.MousePos.y - origin.y};

            // Add first and second point
            if (is_hovered && !adding_line && IsMouseClicked(ImGuiMouseButton_Left))
            {
                points.push_back(mouse_pos_in_canvas);
                points.push_back(mouse_pos_in_canvas);
                adding_line = true;
            }
            if (adding_line)
            {
                points.back() = mouse_pos_in_canvas;
                if (!IsMouseDown(ImGuiMouseButton_Left))
                    adding_line = false;
            }

            // Pan (we use a zero mouse threshold when there's no context menu)
            // You may decide to make that threshold dynamic based on whether the mouse is hovering something etc.
            mouse_threshold_for_pan := opt_enable_context_menu ? -1.0 : 0.0;
            if (is_active && IsMouseDragging(ImGuiMouseButton_Right, mouse_threshold_for_pan))
            {
                scrolling.x += io.MouseDelta.x;
                scrolling.y += io.MouseDelta.y;
            }

            // Context menu (under default mouse threshold)
            drag_delta := GetMouseDragDelta(ImGuiMouseButton_Right);
            if (opt_enable_context_menu && drag_delta.x == 0.0 && drag_delta.y == 0.0)
                OpenPopupOnItemClick("context", ImGuiPopupFlags_MouseButtonRight);
            if (BeginPopup("context"))
            {
                if (adding_line)
                    points.resize(points.size() - 2);
                adding_line = false;
                if (MenuItem("Remove one", nil, false, points.Size > 0)) { points.resize(points.size() - 2); }
                if (MenuItem("Remove all", nil, false, points.Size > 0)) { points.clear(); }
                EndPopup();
            }

            // Draw grid + all lines in the canvas
            draw_list.PushClipRect(canvas_p0, canvas_p1, true);
            if (opt_enable_grid)
            {
                GRID_STEP := 64.0;
                for f32 x = fmodf(scrolling.x, GRID_STEP); x < canvas_sz.x; x += GRID_STEP
                    draw_list.AddLine(ImVec2{canvas_p0.x + x, canvas_p0.y}, ImVec2{canvas_p0.x + x, canvas_p1.y}, IM_COL32(200, 200, 200, 40));
                for f32 y = fmodf(scrolling.y, GRID_STEP); y < canvas_sz.y; y += GRID_STEP
                    draw_list.AddLine(ImVec2{canvas_p0.x, canvas_p0.y + y}, ImVec2{canvas_p1.x, canvas_p0.y + y}, IM_COL32(200, 200, 200, 40));
            }
            for i32 n = 0; n < points.Size; n += 2
                draw_list.AddLine(ImVec2{origin.x + points[n].x, origin.y + points[n].y}, ImVec2{origin.x + points[n + 1].x, origin.y + points[n + 1].y}, IM_COL32(255, 255, 0, 255), 2.0);
            draw_list.PopClipRect();

            EndTabItem();
        }

        if (BeginTabItem("BG/FG draw lists"))
        {
            static bool draw_bg = true;
            static bool draw_fg = true;
            Checkbox("Draw in Background draw list", &draw_bg);
            SameLine(); HelpMarker("The Background draw list will be rendered below every Dear ImGui windows.");
            Checkbox("Draw in Foreground draw list", &draw_fg);
            SameLine(); HelpMarker("The Foreground draw list will be rendered over every Dear ImGui windows.");
            window_pos := GetWindowPos();
            window_size := GetWindowSize();
            window_center := ImVec2{window_pos.x + window_size.x * 0.5, window_pos.y + window_size.y * 0.5};
            if (draw_bg)
                GetBackgroundDrawList()->AddCircle(window_center, window_size.x * 0.6, IM_COL32(255, 0, 0, 200), 0, 10 + 4);
            if (draw_fg)
                GetForegroundDrawList()->AddCircle(window_center, window_size.y * 0.6, IM_COL32(0, 255, 0, 200), 0, 10);
            EndTabItem();
        }

        // Demonstrate out-of-order rendering via channels splitting
        // We use functions in ImDrawList as each draw list contains a convenience splitter,
        // but you can also instantiate your own ImDrawListSplitter if you need to nest them.
        if (BeginTabItem("Draw Channels"))
        {
            draw_list := GetWindowDrawList();
            {
                Text("Blue shape is drawn first: appears in back");
                Text("Red shape is drawn after: appears in front");
                p0 := GetCursorScreenPos();
                draw_list.AddRectFilled(ImVec2{p0.x, p0.y}, ImVec2{p0.x + 50, p0.y + 50}, IM_COL32(0, 0, 255, 255)); // Blue
                draw_list.AddRectFilled(ImVec2{p0.x + 25, p0.y + 25}, ImVec2{p0.x + 75, p0.y + 75}, IM_COL32(255, 0, 0, 255)); // Red
                Dummy(ImVec2{75, 75});
            }
            Separator();
            {
                Text("Blue shape is drawn first, into channel 1: appears in front");
                Text("Red shape is drawn after, into channel 0: appears in back");
                p1 := GetCursorScreenPos();

                // Create 2 channels and draw a Blue shape THEN a Red shape.
                // You can create any number of channels. Tables API use 1 channel per column in order to better batch draw calls.
                draw_list.ChannelsSplit(2);
                draw_list.ChannelsSetCurrent(1);
                draw_list.AddRectFilled(ImVec2{p1.x, p1.y}, ImVec2{p1.x + 50, p1.y + 50}, IM_COL32(0, 0, 255, 255)); // Blue
                draw_list.ChannelsSetCurrent(0);
                draw_list.AddRectFilled(ImVec2{p1.x + 25, p1.y + 25}, ImVec2{p1.x + 75, p1.y + 75}, IM_COL32(255, 0, 0, 255)); // Red

                // Flatten/reorder channels. Red shape is in channel 0 and it appears below the Blue shape in channel 1.
                // This works by copying draw indices only (vertices are not copied).
                draw_list.ChannelsMerge();
                Dummy(ImVec2{75, 75});
                Text("After reordering, contents of channel 0 appears below channel 1.");
            }
            EndTabItem();
        }

        EndTabBar();
    }

    End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Docking, DockSpace / ShowExampleAppDockSpace()
//-----------------------------------------------------------------------------

// Demonstrate using DockSpace() to create an explicit docking node within an existing window.
// Note: You can use most Docking facilities without calling any API. You DO NOT need to call DockSpace() to use Docking!
// - Drag from window title bar or their tab to dock/undock. Hold SHIFT to disable docking.
// - Drag from window menu button (upper-left button) to undock an entire node (all windows).
// - When io.ConfigDockingWithShift == true, you instead need to hold SHIFT to enable docking.
// About dockspaces:
// - Use DockSpace() to create an explicit dock node _within_ an existing window.
// - Use DockSpaceOverViewport() to create an explicit dock node covering the screen or a specific viewport.
//   This is often used with ImGuiDockNodeFlags_PassthruCentralNode.
// - Important: Dockspaces need to be submitted _before_ any window they can host. Submit it early in your frame! (*)
// - Important: Dockspaces need to be kept alive if hidden, otherwise windows docked into it will be undocked.
//   e.g. if you have multiple tabs with a dockspace inside each tab: submit the non-visible dockspaces with ImGuiDockNodeFlags_KeepAliveOnly.
// (*) because of this constraint, the implicit \"Debug\" window can not be docked into an explicit DockSpace() node,
// because that window is submitted as part of the part of the NewFrame() call. An easy workaround is that you can create
// your own implicit "Debug##2" window after calling DockSpace() and leave it in the window stack for anyone to use.
ShowExampleAppDockSpace :: proc(p_open : ^bool)
{
    // READ THIS !!!
    // TL;DR; this demo is more complicated than what most users you would normally use.
    // If we remove all options we are showcasing, this demo would become:
    //     void ShowExampleAppDockSpace()
    //     {
    //         ImGui::DockSpaceOverViewport(0, ImGui::GetMainViewport());
    //     }
    // In most cases you should be able to just call DockSpaceOverViewport() and ignore all the code below!
    // In this specific demo, we are not using DockSpaceOverViewport() because:
    // - (1) we allow the host window to be floating/moveable instead of filling the viewport (when opt_fullscreen == false)
    // - (2) we allow the host window to have padding (when opt_padding == true)
    // - (3) we expose many flags and need a way to have them visible.
    // - (4) we have a local menu bar in the host window (vs. you could use BeginMainMenuBar() + DockSpaceOverViewport()
    //      in your code, but we don't here because we allow the window to be floating)

    static bool opt_fullscreen = true;
    static bool opt_padding = false;
    static ImGuiDockNodeFlags dockspace_flags = ImGuiDockNodeFlags_None;

    // We are using the ImGuiWindowFlags_NoDocking flag to make the parent window not dockable into,
    // because it would be confusing to have two docking targets within each others.
    window_flags := ImGuiWindowFlags_MenuBar | ImGuiWindowFlags_NoDocking;
    if (opt_fullscreen)
    {
        viewport := GetMainViewport();
        SetNextWindowPos(viewport.WorkPos);
        SetNextWindowSize(viewport.WorkSize);
        SetNextWindowViewport(viewport.ID);
        PushStyleVar(ImGuiStyleVar_WindowRounding, 0.0);
        PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0);
        window_flags |= ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove;
        window_flags |= ImGuiWindowFlags_NoBringToFrontOnFocus | ImGuiWindowFlags_NoNavFocus;
    }
    else
    {
        dockspace_flags &= ~ImGuiDockNodeFlags_PassthruCentralNode;
    }

    // When using ImGuiDockNodeFlags_PassthruCentralNode, DockSpace() will render our background
    // and handle the pass-thru hole, so we ask Begin() to not render a background.
    if (dockspace_flags & ImGuiDockNodeFlags_PassthruCentralNode)
        window_flags |= ImGuiWindowFlags_NoBackground;

    // Important: note that we proceed even if Begin() returns false (aka window is collapsed).
    // This is because we want to keep our DockSpace() active. If a DockSpace() is inactive,
    // all active windows docked into it will lose their parent and become undocked.
    // We cannot preserve the docking relationship between an active window and an inactive docking, otherwise
    // any change of dockspace/settings would lead to windows being stuck in limbo and never being visible.
    if (!opt_padding)
        PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2{0.0, 0.0});
    Begin("DockSpace Demo", p_open, window_flags);
    if (!opt_padding)
        PopStyleVar();

    if (opt_fullscreen)
        PopStyleVar(2);

    // Submit the DockSpace
    ImGuiIO& io = GetIO();
    if (io.ConfigFlags & ImGuiConfigFlags_DockingEnable)
    {
        dockspace_id := GetID("MyDockSpace");
        DockSpace(dockspace_id, ImVec2{0.0, 0.0}, dockspace_flags);
    }
    else
    {
        ShowDockingDisabledMessage();
    }

    if (BeginMenuBar())
    {
        if (BeginMenu("Options"))
        {
            // Disabling fullscreen would allow the window to be moved to the front of other windows,
            // which we can't undo at the moment without finer window depth/z control.
            MenuItem("Fullscreen", nil, &opt_fullscreen);
            MenuItem("Padding", nil, &opt_padding);
            Separator();

            if (MenuItem("Flag: NoDockingOverCentralNode", "", (dockspace_flags & ImGuiDockNodeFlags_NoDockingOverCentralNode) != 0)) { dockspace_flags ^= ImGuiDockNodeFlags_NoDockingOverCentralNode; }
            if (MenuItem("Flag: NoDockingSplit",         "", (dockspace_flags & ImGuiDockNodeFlags_NoDockingSplit) != 0))             { dockspace_flags ^= ImGuiDockNodeFlags_NoDockingSplit; }
            if (MenuItem("Flag: NoUndocking",            "", (dockspace_flags & ImGuiDockNodeFlags_NoUndocking) != 0))                { dockspace_flags ^= ImGuiDockNodeFlags_NoUndocking; }
            if (MenuItem("Flag: NoResize",               "", (dockspace_flags & ImGuiDockNodeFlags_NoResize) != 0))                   { dockspace_flags ^= ImGuiDockNodeFlags_NoResize; }
            if (MenuItem("Flag: AutoHideTabBar",         "", (dockspace_flags & ImGuiDockNodeFlags_AutoHideTabBar) != 0))             { dockspace_flags ^= ImGuiDockNodeFlags_AutoHideTabBar; }
            if (MenuItem("Flag: PassthruCentralNode",    "", (dockspace_flags & ImGuiDockNodeFlags_PassthruCentralNode) != 0, opt_fullscreen)) { dockspace_flags ^= ImGuiDockNodeFlags_PassthruCentralNode; }
            Separator();

            if (MenuItem("Close", nil, false, p_open != nil))
                p_open^ = false;
            EndMenu();
        }
        HelpMarker(
            "When docking is enabled, you can ALWAYS dock MOST window into another! Try it now!" "\n"
            "- Drag from window title bar or their tab to dock/undock." "\n"
            "- Drag from window menu button (upper-left button) to undock an entire node (all windows)." "\n"
            "- Hold SHIFT to disable docking (if io.ConfigDockingWithShift == false, default)" "\n"
            "- Hold SHIFT to enable docking (if io.ConfigDockingWithShift == true)" "\n"
            "This demo app has nothing to do with enabling docking!" "\n\n"
            "This demo app only demonstrate the use of DockSpace() which allows you to manually create a docking node _within_ another window." "\n\n"
            "Read comments in ShowExampleAppDockSpace() for more details.");

        EndMenuBar();
    }

    End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Documents Handling / ShowExampleAppDocuments()
//-----------------------------------------------------------------------------

// Simplified structure to mimic a Document model
MyDocument :: struct
{
    Name : [32]u8,   // Document title
    UID : i32,        // Unique ID (necessary as we can change title)
    Open : bool,       // Set when open (we keep an array of all available documents to simplify demo code!)
    OpenPrev : bool,   // Copy of Open from last update.
    Dirty : bool,      // Set when the document has been modified
    Color : ImVec4,      // An arbitrary variable associated to the document

    MyDocument(i32 uid, const u8* name, bool open = true, const ImVec4& color = ImVec4{1.0, 1.0, 1.0, 1.0})
    {
        UID = uid;
        snprintf(Name, size_of(Name), "%s", name);
        Open = OpenPrev = open;
        Dirty = false;
        Color = color;
    }
    void DoOpen()       { Open = true; }
    void DoForceClose() { Open = false; Dirty = false; }
    void DoSave()       { Dirty = false; }
};

ExampleAppDocuments :: struct
{
    Documents : [dynamic]MyDocument,
    CloseQueue : [dynamic]^MyDocument,
    RenamingDoc := nil;
    RenamingStarted := false;

    ExampleAppDocuments()
    {
        Documents.push_back(MyDocument(0, "Lettuce",             true,  ImVec4{0.4, 0.8, 0.4, 1.0}));
        Documents.push_back(MyDocument(1, "Eggplant",            true,  ImVec4{0.8, 0.5, 1.0, 1.0}));
        Documents.push_back(MyDocument(2, "Carrot",              true,  ImVec4{1.0, 0.8, 0.5, 1.0}));
        Documents.push_back(MyDocument(3, "Tomato",              false, ImVec4{1.0, 0.3, 0.4, 1.0}));
        Documents.push_back(MyDocument(4, "A Rather Long Title", false, ImVec4{0.4, 0.8, 0.8, 1.0}));
        Documents.push_back(MyDocument(5, "Some Document",       false, ImVec4{0.8, 0.8, 1.0, 1.0}));
    }

    // As we allow to change document name, we append a never-changing document ID so tabs are stable
    GetTabName :: proc(doc : ^MyDocument, out_buf : ^u8, out_buf_size : int)
    {
        snprintf(out_buf, out_buf_size, "%s###doc%d", doc.Name, doc.UID);
    }

    // Display placeholder contents for the Document
    DisplayDocContents :: proc(doc : ^MyDocument)
    {
        PushID(doc);
        Text("Document \"%s\"", doc.Name);
        PushStyleColor(ImGuiCol_Text, doc.Color);
        TextWrapped("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.");
        PopStyleColor();

        SetNextItemShortcut(ImGuiMod_Ctrl | ImGuiKey_R, ImGuiInputFlags_Tooltip);
        if (Button("Rename.."))
        {
            RenamingDoc = doc;
            RenamingStarted = true;
        }
        SameLine();

        SetNextItemShortcut(ImGuiMod_Ctrl | ImGuiKey_M, ImGuiInputFlags_Tooltip);
        if (Button("Modify"))
            doc.Dirty = true;

        SameLine();
        SetNextItemShortcut(ImGuiMod_Ctrl | ImGuiKey_S, ImGuiInputFlags_Tooltip);
        if (Button("Save"))
            doc.DoSave();

        SameLine();
        SetNextItemShortcut(ImGuiMod_Ctrl | ImGuiKey_W, ImGuiInputFlags_Tooltip);
        if (Button("Close"))
            CloseQueue.push_back(doc);
        ColorEdit3("color", &doc.Color.x);  // Useful to test drag and drop and hold-dragged-to-open-tab behavior.
        PopID();
    }

    // Display context menu for the Document
    DisplayDocContextMenu :: proc(doc : ^MyDocument)
    {
        if (!BeginPopupContextItem())
            return;

        buf : [256]u8,
        sprintf(buf, "Save %s", doc.Name);
        if (MenuItem(buf, "Ctrl+S", false, doc.Open))
            doc.DoSave();
        if (MenuItem("Rename...", "Ctrl+R", false, doc.Open))
            RenamingDoc = doc;
        if (MenuItem("Close", "Ctrl+W", false, doc.Open))
            CloseQueue.push_back(doc);
        EndPopup();
    }

    // [Optional] Notify the system of Tabs/Windows closure that happened outside the regular tab interface.
    // If a tab has been closed programmatically (aka closed from another source such as the Checkbox() in the demo,
    // as opposed to clicking on the regular tab closing button) and stops being submitted, it will take a frame for
    // the tab bar to notice its absence. During this frame there will be a gap in the tab bar, and if the tab that has
    // disappeared was the selected one, the tab bar will report no selected tab during the frame. This will effectively
    // give the impression of a flicker for one frame.
    // We call SetTabItemClosed() to manually notify the Tab Bar or Docking system of removed tabs to avoid this glitch.
    // Note that this completely optional, and only affect tab bars with the ImGuiTabBarFlags_Reorderable flag.
    NotifyOfDocumentsClosedElsewhere :: proc()
    {
        for MyDocument& doc : Documents
        {
            if (!doc.Open && doc.OpenPrev)
                SetTabItemClosed(doc.Name);
            doc.OpenPrev = doc.Open;
        }
    }
};

ShowExampleAppDocuments :: proc(p_open : ^bool)
{
    static ExampleAppDocuments app;

    // Options
    Target :: enum i32
    {
        None,
        Tab,                 // Create documents as local tab into a local tab bar
        DockSpaceAndWindow   // Create documents as regular windows, and create an embedded dockspace
    };
    static Target opt_target = Target_Tab;
    static bool opt_reorderable = true;
    static ImGuiTabBarFlags opt_fitting_flags = ImGuiTabBarFlags_FittingPolicyDefault_;

    // When (opt_target == Target_DockSpaceAndWindow) there is the possibily that one of our child Document window (e.g. "Eggplant")
    // that we emit gets docked into the same spot as the parent window ("Example: Documents").
    // This would create a problematic feedback loop because selecting the "Eggplant" tab would make the "Example: Documents" tab
    // not visible, which in turn would stop submitting the "Eggplant" window.
    // We avoid this problem by submitting our documents window even if our parent window is not currently visible.
    // Another solution may be to make the "Example: Documents" window use the ImGuiWindowFlags_NoDocking.

    window_contents_visible := Begin("Example: Documents", p_open, ImGuiWindowFlags_MenuBar);
    if (!window_contents_visible && opt_target != Target_DockSpaceAndWindow)
    {
        End();
        return;
    }

    // Menu
    if (BeginMenuBar())
    {
        if (BeginMenu("File"))
        {
            open_count := 0;
            for MyDocument& doc : app.Documents
                open_count += doc.Open ? 1 : 0;

            if (BeginMenu("Open", open_count < app.Documents.Size))
            {
                for MyDocument& doc : app.Documents
                    if (!doc.Open && MenuItem(doc.Name))
                        doc.DoOpen();
                EndMenu();
            }
            if (MenuItem("Close All Documents", nil, false, open_count > 0))
                for MyDocument& doc : app.Documents
                    app.CloseQueue.push_back(&doc);
            if (MenuItem("Exit") && p_open)
                p_open^ = false;
            EndMenu();
        }
        EndMenuBar();
    }

    // [Debug] List documents with one checkbox for each
    for i32 doc_n = 0; doc_n < app.Documents.Size; doc_n++
    {
        MyDocument& doc = app.Documents[doc_n];
        if (doc_n > 0)
            SameLine();
        PushID(&doc);
        if (Checkbox(doc.Name, &doc.Open))
            if (!doc.Open)
                doc.DoForceClose();
        PopID();
    }
    PushItemWidth(GetFontSize() * 12);
    Combo("Output", (i32*)&opt_target, "None0x00TabBar+Tabs0x00DockSpace+Window0x00");
    PopItemWidth();
    redock_all := false;
    if (opt_target == Target_Tab)                { SameLine(); Checkbox("Reorderable Tabs", &opt_reorderable); }
    if (opt_target == Target_DockSpaceAndWindow) { SameLine(); redock_all = Button("Redock all"); }

    Separator();

    // About the ImGuiWindowFlags_UnsavedDocument / ImGuiTabItemFlags_UnsavedDocument flags.
    // They have multiple effects:
    // - Display a dot next to the title.
    // - Tab is selected when clicking the X close button.
    // - Closure is not assumed (will wait for user to stop submitting the tab).
    //   Otherwise closure is assumed when pressing the X, so if you keep submitting the tab may reappear at end of tab bar.
    //   We need to assume closure by default otherwise waiting for "lack of submission" on the next frame would leave an empty
    //   hole for one-frame, both in the tab-bar and in tab-contents when closing a tab/window.
    //   The rarely used SetTabItemClosed() function is a way to notify of programmatic closure to avoid the one-frame hole.

    // Tabs
    if (opt_target == Target_Tab)
    {
        tab_bar_flags := (opt_fitting_flags) | (opt_reorderable ? ImGuiTabBarFlags_Reorderable : 0);
        tab_bar_flags |= ImGuiTabBarFlags_DrawSelectedOverline;
        if (BeginTabBar("##tabs", tab_bar_flags))
        {
            if (opt_reorderable)
                app.NotifyOfDocumentsClosedElsewhere();

            // [DEBUG] Stress tests
            //if ((ImGui::GetFrameCount() % 30) == 0) docs[1].Open ^= 1;            // [DEBUG] Automatically show/hide a tab. Test various interactions e.g. dragging with this on.
            //if (ImGui::GetIO().KeyCtrl) ImGui::SetTabItemSelected(docs[1].Name);  // [DEBUG] Test SetTabItemSelected(), probably not very useful as-is anyway..

            // Submit Tabs
            for MyDocument& doc : app.Documents
            {
                if (!doc.Open)
                    continue;

                // As we allow to change document name, we append a never-changing document id so tabs are stable
                doc_name_buf : [64]u8
                app.GetTabName(&doc, doc_name_buf, size_of(doc_name_buf));
                tab_flags := (doc.Dirty ? ImGuiTabItemFlags_UnsavedDocument : 0);
                visible := BeginTabItem(doc_name_buf, &doc.Open, tab_flags);

                // Cancel attempt to close when unsaved add to save queue so we can display a popup.
                if (!doc.Open && doc.Dirty)
                {
                    doc.Open = true;
                    app.CloseQueue.push_back(&doc);
                }

                app.DisplayDocContextMenu(&doc);
                if (visible)
                {
                    app.DisplayDocContents(&doc);
                    EndTabItem();
                }
            }

            EndTabBar();
        }
    }
    else if (opt_target == Target_DockSpaceAndWindow)
    {
        if (GetIO().ConfigFlags & ImGuiConfigFlags_DockingEnable)
        {
            app.NotifyOfDocumentsClosedElsewhere();

            // Create a DockSpace node where any window can be docked
            dockspace_id := GetID("MyDockSpace");
            DockSpace(dockspace_id);

            // Create Windows
            for i32 doc_n = 0; doc_n < app.Documents.Size; doc_n++
            {
                doc := &app.Documents[doc_n];
                if (!doc.Open)
                    continue;

                SetNextWindowDockID(dockspace_id, redock_all ? ImGuiCond_Always : ImGuiCond_FirstUseEver);
                window_flags := (doc.Dirty ? ImGuiWindowFlags_UnsavedDocument : 0);
                visible := Begin(doc.Name, &doc.Open, window_flags);

                // Cancel attempt to close when unsaved add to save queue so we can display a popup.
                if (!doc.Open && doc.Dirty)
                {
                    doc.Open = true;
                    app.CloseQueue.push_back(doc);
                }

                app.DisplayDocContextMenu(doc);
                if (visible)
                    app.DisplayDocContents(doc);

                End();
            }
        }
        else
        {
            ShowDockingDisabledMessage();
        }
    }

    // Early out other contents
    if (!window_contents_visible)
    {
        End();
        return;
    }

    // Display renaming UI
    if (app.RenamingDoc != nil)
    {
        if (app.RenamingStarted)
            OpenPopup("Rename");
        if (BeginPopup("Rename"))
        {
            SetNextItemWidth(GetFontSize() * 30);
            if (InputText("###Name", app.RenamingDoc.Name, len(app.RenamingDoc.Name), ImGuiInputTextFlags_EnterReturnsTrue))
            {
                CloseCurrentPopup();
                app.RenamingDoc = nil;
            }
            if (app.RenamingStarted)
                SetKeyboardFocusHere(-1);
            EndPopup();
        }
        else
        {
            app.RenamingDoc = nil;
        }
        app.RenamingStarted = false;
    }

    // Display closing confirmation UI
    if (!app.CloseQueue.empty())
    {
        close_queue_unsaved_documents := 0;
        for i32 n = 0; n < app.CloseQueue.Size; n++
            if (app.CloseQueue[n]->Dirty)
                close_queue_unsaved_documents += 1;

        if (close_queue_unsaved_documents == 0)
        {
            // Close documents when all are unsaved
            for i32 n = 0; n < app.CloseQueue.Size; n++
                app.CloseQueue[n]->DoForceClose();
            app.CloseQueue.clear();
        }
        else
        {
            if (!IsPopupOpen("Save?"))
                OpenPopup("Save?");
            if (BeginPopupModal("Save?", nil, ImGuiWindowFlags_AlwaysAutoResize))
            {
                Text("Save change to the following items?");
                item_height := GetTextLineHeightWithSpacing();
                if (BeginChild(GetID("frame"), ImVec2{-math.F32_MIN, 6.25 * item_height}, ImGuiChildFlags_FrameStyle))
                    for MyDocument* doc : app.CloseQueue
                        if (doc.Dirty)
                            Text("%s", doc.Name);
                EndChild();

                button_size := button(on(FontSize() * 7.0, 0.0);
                if (Button("Yes", button_size))
                {
                    for MyDocument* doc : app.CloseQueue
                    {
                        if (doc.Dirty)
                            doc.DoSave();
                        doc.DoForceClose();
                    }
                    app.CloseQueue.clear();
                    CloseCurrentPopup();
                }
                SameLine();
                if (Button("No", button_size))
                {
                    for MyDocument* doc : app.CloseQueue
                        doc.DoForceClose();
                    app.CloseQueue.clear();
                    CloseCurrentPopup();
                }
                SameLine();
                if (Button("Cancel", button_size))
                {
                    app.CloseQueue.clear();
                    CloseCurrentPopup();
                }
                EndPopup();
            }
        }
    }

    End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Assets Browser / ShowExampleAppAssetsBrowser()
//-----------------------------------------------------------------------------

//#include "imgui_internal.h" // NavMoveRequestTryWrapping()

ExampleAsset :: struct
{
    ID : ImGuiID,
    Type : i32,

    ExampleAsset(ImGuiID id, i32 type) { ID = id; Type = type; }

    static const ImGuiTableSortSpecs* s_current_sort_specs;

    static void SortWithSortSpecs(ImGuiTableSortSpecs* sort_specs, ExampleAsset* items, i32 items_count)
    {
        s_current_sort_specs = sort_specs; // Store in variable accessible by the sort function.
        if (items_count > 1)
            qsort(items, cast(ast) ast) _countcounte_of(items[0]), ExampleAsset::CompareWithSortSpecs);
        s_current_sort_specs = nil;
    }

    // Compare function to be used by qsort()
    static i32 IMGUI_CDECL CompareWithSortSpecs(const rawptr lhs, const rawptr rhs)
    {
        a := (const ExampleAsset*)lhs;
        b := (const ExampleAsset*)rhs;
        for i32 n = 0; n < s_current_sort_specs.SpecsCount; n++
        {
            sort_spec := &s_current_sort_specs.Specs[n];
            delta := 0;
            if (sort_spec.ColumnIndex == 0)
                delta = (cast(ast) ast) a cast() a) cast()
            else if (sort_spec.ColumnIndex == 1)
                delta = (a.Type - b.Type);
            if (delta > 0)
                return (sort_spec.SortDirection == ImGuiSortDirection_Ascending) ? +1 : -1;
            if (delta < 0)
                return (sort_spec.SortDirection == ImGuiSortDirection_Ascending) ? -1 : +1;
        }
        return (cast(ast) ast) a cast() a) cast()
    }
};
const ImGuiTableSortSpecs* ExampleAsset::s_current_sort_specs = nil;

ExampleAssetsBrowser :: struct
{
    // Options
    ShowTypeOverlay := true;
    AllowSorting := true;
    AllowDragUnselected := false;
    AllowBoxSelect := true;
    IconSize := 32.0;
    IconSpacing := 10;
    IconHitSpacing := 4;         // Increase hit-spacing if you want to make it possible to clear or box-select from gaps. Some spacing is required to able to amend with Shift+box-select. Value is small in Explorer.
    StretchSpacing := true;

    // State
    Items : [dynamic]ExampleAsset,               // Our items
    Selection : ExampleSelectionWithDeletion,     // Our selection (ImGuiSelectionBasicStorage + helper funcs to handle deletion)
    NextItemId := 0;             // Unique identifier when creating new items
    RequestDelete := false;      // Deferred deletion request
    RequestSort := false;        // Deferred sort request
    ZoomWheelAccum := 0.0;      // Mouse wheel accumulator to handle smooth wheels better

    // Calculated sizes for layout, output of UpdateLayoutSizes(). Could be locals but our code is simpler this way.
    LayoutItemSize : ImVec2,
    LayoutItemStep : ImVec2,             // == LayoutItemSize + LayoutItemSpacing
    LayoutItemSpacing := 0.0;
    LayoutSelectableSpacing := 0.0;
    LayoutOuterPadding := 0.0;
    LayoutColumnCount := 0;
    LayoutLineCount := 0;

    // Functions
    ExampleAssetsBrowser()
    {
        AddItems(10000);
    }
    AddItems :: proc(count : i32)
    {
        if (Items.Size == 0)
            NextItemId = 0;
        Items.reserve(Items.Size + count);
        for i32 n = 0; n < count; n++, NextItemId++
            Items.push_back(ExampleAsset(NextItemId, (NextItemId % 20) < 15 ? 0 : (NextItemId % 20) < 18 ? 1 : 2));
        RequestSort = true;
    }
    ClearItems :: proc()
    {
        Items.clear();
        Selection.Clear();
    }

    // Logic would be written in the main code BeginChild() and outputing to local variables.
    // We extracted it into a function so we can call it easily from multiple places.
    UpdateLayoutSizes :: proc(avail_width : f32)
    {
        // Layout: when not stretching: allow extending into right-most spacing.
        LayoutItemSpacing = cast(ast) ast) pacinga
        if (StretchSpacing == false)
            avail_width += floorf(LayoutItemSpacing * 0.5);

        // Layout: calculate number of icon per line and number of lines
        LayoutItemSize = ImVec2{floorf(IconSize}, floorf(IconSize));
        LayoutColumnCount = IM_MAX((i32)(avail_width / (LayoutItemSize.x + LayoutItemSpacing)), 1);
        LayoutLineCount = (Items.Size + LayoutColumnCount - 1) / LayoutColumnCount;

        // Layout: when stretching: allocate remaining space to more spacing. Round before division, so item_spacing may be non-integer.
        if (StretchSpacing && LayoutColumnCount > 1)
            LayoutItemSpacing = floorf(avail_width - LayoutItemSize.x * LayoutColumnCount) / LayoutColumnCount;

        LayoutItemStep = ImVec2{LayoutItemSize.x + LayoutItemSpacing, LayoutItemSize.y + LayoutItemSpacing};
        LayoutSelectableSpacing = IM_MAX(floorf(LayoutItemSpacing) - IconHitSpacing, 0.0);
        LayoutOuterPadding = floorf(LayoutItemSpacing * 0.5);
    }

    // [forward declared comment]:
// Helper calling InputText+Build
Draw :: proc(title : ^u8 = "Filter (inc,-exc)", p_open : ^bool = 0.0)
    {
        SetNextWindowSize(ImVec2{IconSize * 25, IconSize * 15}, ImGuiCond_FirstUseEver);
        if (!Begin(title, p_open, ImGuiWindowFlags_MenuBar))
        {
            End();
            return;
        }

        // Menu bar
        if (BeginMenuBar())
        {
            if (BeginMenu("File"))
            {
                if (MenuItem("Add 10000 items"))
                    AddItems(10000);
                if (MenuItem("Clear items"))
                    ClearItems();
                Separator();
                if (MenuItem("Close", nil, false, p_open != nil))
                    p_open^ = false;
                EndMenu();
            }
            if (BeginMenu("Edit"))
            {
                if (MenuItem("Delete", "Del", false, Selection.Size > 0))
                    RequestDelete = true;
                EndMenu();
            }
            if (BeginMenu("Options"))
            {
                PushItemWidth(GetFontSize() * 10);

                SeparatorText("Contents");
                Checkbox("Show Type Overlay", &ShowTypeOverlay);
                Checkbox("Allow Sorting", &AllowSorting);

                SeparatorText("Selection Behavior");
                Checkbox("Allow dragging unselected item", &AllowDragUnselected);
                Checkbox("Allow box-selection", &AllowBoxSelect);

                SeparatorText("Layout");
                SliderFloat("Icon Size", &IconSize, 16.0, 128.0, "%.0");
                SameLine(); HelpMarker("Use CTRL+Wheel to zoom");
                SliderInt("Icon Spacing", &IconSpacing, 0, 32);
                SliderInt("Icon Hit Spacing", &IconHitSpacing, 0, 32);
                Checkbox("Stretch Spacing", &StretchSpacing);
                PopItemWidth();
                EndMenu();
            }
            EndMenuBar();
        }

        // Show a table with ONLY one header row to showcase the idea/possibility of using this to provide a sorting UI
        if (AllowSorting)
        {
            PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2{0, 0});
            table_flags_for_sort_specs := ImGuiTableFlags_Sortable | ImGuiTableFlags_SortMulti | ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_Borders;
            if (BeginTable("for_sort_specs_only", 2, table_flags_for_sort_specs, ImVec2{0.0, GetFrameHeight(})))
            {
                TableSetupColumn("Index");
                TableSetupColumn("Type");
                TableHeadersRow();
                if (ImGuiTableSortSpecs* sort_specs = TableGetSortSpecs())
                    if (sort_specs.SpecsDirty || RequestSort)
                    {
                        ExampleAsset::SortWithSortSpecs(sort_specs, Items.Data, Items.Size);
                        sort_specs.SpecsDirty = RequestSort = false;
                    }
                EndTable();
            }
            PopStyleVar();
        }

        ImGuiIO& io = GetIO();
        SetNextWindowContentSize(ImVec2{0.0, LayoutOuterPadding + LayoutLineCount * (LayoutItemSize.y + LayoutItemSpacing}));
        if (BeginChild("Assets", ImVec2{0.0, -GetTextLineHeightWithSpacing(}), ImGuiChildFlags_Borders, ImGuiWindowFlags_NoMove))
        {
            draw_list := GetWindowDrawList();

            avail_width := GetContentRegionAvail().x;
            UpdateLayoutSizes(avail_width);

            // Calculate and store start position.
            start_pos := GetCursorScreenPos();
            start_pos = ImVec2{start_pos.x + LayoutOuterPadding, start_pos.y + LayoutOuterPadding};
            SetCursorScreenPos(start_pos);

            // Multi-select
            ms_flags := ImGuiMultiSelectFlags_ClearOnEscape | ImGuiMultiSelectFlags_ClearOnClickVoid;

            // - Enable box-select (in 2D mode, so that changing box-select rectangle X1/X2 boundaries will affect clipped items)
            if (AllowBoxSelect)
                ms_flags |= ImGuiMultiSelectFlags_BoxSelect2d;

            // - This feature allows dragging an unselected item without selecting it (rarely used)
            if (AllowDragUnselected)
                ms_flags |= ImGuiMultiSelectFlags_SelectOnClickRelease;

            // - Enable keyboard wrapping on X axis
            // (FIXME-MULTISELECT: We haven't designed/exposed a general nav wrapping api yet, so this flag is provided as a courtesy to avoid doing:
            //    ImGui::NavMoveRequestTryWrapping(ImGui::GetCurrentWindow(), ImGuiNavMoveFlags_WrapX);
            // When we finish implementing a more general API for this, we will obsolete this flag in favor of the new system)
            ms_flags |= ImGuiMultiSelectFlags_NavWrapX;

            ms_io := BeginMultiSelect(ms_flags, Selection.Size, Items.Size);

            // Use custom selection adapter: store ID in selection (recommended)
            Selection.UserData = this;
            Selection.AdapterIndexToStorageId = [](ImGuiSelectionBasicStorage* self_, i32 idx) { ExampleAssetsBrowser* self = (ExampleAssetsBrowser*)self_.UserData; return self.Items[idx].ID; };
            Selection.ApplyRequests(ms_io);

            want_delete := (Shortcut(ImGuiKey_Delete, ImGuiInputFlags_Repeat) && (Selection.Size > 0)) || RequestDelete;
            item_curr_idx_to_focus := want_delete ? Selection.ApplyDeletionPreLoop(ms_io, Items.Size) : -1;
            RequestDelete = false;

            // Push LayoutSelectableSpacing (which is LayoutItemSpacing minus hit-spacing, if we decide to have hit gaps between items)
            // Altering style ItemSpacing may seem unnecessary as we position every items using SetCursorScreenPos()...
            // But it is necessary for two reasons:
            // - Selectables uses it by default to visually fill the space between two items.
            // - The vertical spacing would be measured by Clipper to calculate line height if we didn't provide it explicitly (here we do).
            PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2{LayoutSelectableSpacing, LayoutSelectableSpacing});

            // Rendering parameters
            const u32 icon_type_overlay_colors[3] = { 0, IM_COL32(200, 70, 70, 255), IM_COL32(70, 170, 70, 255) };
            icon_bg_color := GetColorU32(IM_COL32(35, 35, 35, 220));
            icon_type_overlay_size := ImVec2{4.0, 4.0};
            display_label := (LayoutItemSize.x >= CalcTextSize("999").x);

            column_count := LayoutColumnCount;
            clipper : ImGuiListClipper,
            clipper.Begin(LayoutLineCount, LayoutItemStep.y);
            if (item_curr_idx_to_focus != -1)
                clipper.IncludeItemByIndex(item_curr_idx_to_focus / column_count); // Ensure focused item line is not clipped.
            if (ms_io.RangeSrcItem != -1)
                clipper.IncludeItemByIndex(cast(ast) ast) ast) eSrcItem / column_count); // Ensure RangeSrc item line is not clipped.
            for clipper.Step()
            {
                for i32 line_idx = clipper.DisplayStart; line_idx < clipper.DisplayEnd; line_idx++
                {
                    item_min_idx_for_current_line := line_idx * column_count;
                    item_max_idx_for_current_line := IM_MIN((line_idx + 1) * column_count, Items.Size);
                    for i32 item_idx = item_min_idx_for_current_line; item_idx < item_max_idx_for_current_line; ++item_idx
                    {
                        item_data := &Items[item_idx];
                        PushID(cast(ast) ast) data data

                        // Position item
                        pos := ImVec2{start_pos.x + (item_idx % column_count} * LayoutItemStep.x, start_pos.y + line_idx * LayoutItemStep.y);
                        SetCursorScreenPos(pos);

                        SetNextItemSelectionUserData(item_idx);
                        item_is_selected := Selection.Contains((ImGuiID)item_data.ID);
                        item_is_visible := IsRectVisible(LayoutItemSize);
                        Selectable("", item_is_selected, ImGuiSelectableFlags_None, LayoutItemSize);

                        // Update our selection state immediately (without waiting for EndMultiSelect() requests)
                        // because we use this to alter the color of our text/icon.
                        if (IsItemToggledSelection())
                            item_is_selected = !item_is_selected;

                        // Focus (for after deletion)
                        if (item_curr_idx_to_focus == item_idx)
                            SetKeyboardFocusHere(-1);

                        // Drag and drop
                        if (BeginDragDropSource())
                        {
                            // Create payload with full selection OR single unselected item.
                            // (the later is only possible when using ImGuiMultiSelectFlags_SelectOnClickRelease)
                            if (GetDragDropPayload() == nil)
                            {
                                payload_items : [dynamic]ImGuiID,
                                it := nil;
                                id := 0;
                                if (!item_is_selected)
                                    payload_items.push_back(item_data.ID);
                                else
                                    for Selection.GetNextSelectedItem(&it, &id)
                                        payload_items.push_back(id);
                                SetDragDropPayload("ASSETS_BROWSER_ITEMS", payload_items.Data, cast(int) payload_items.size_in_bytes());
                            }

                            // Display payload content in tooltip, by extracting it from the payload data
                            // (we could read from selection, but it is more correct and reusable to read from payload)
                            payload := GetDragDropPayload();
                            payload_count := cast(ast) ast) adt) adSize / cast(e /) cast(e /) cast(e 
                            Text("%d assets", payload_count);

                            EndDragDropSource();
                        }

                        // Render icon (a real app would likely display an image/thumbnail here)
                        // Because we use ImGuiMultiSelectFlags_BoxSelect2d, clipping vertical may occasionally be larger, so we coarse-clip our rendering as well.
                        if (item_is_visible)
                        {
                            ImVec2 box_min(pos.x - 1, pos.y - 1);
                            ImVec2 box_max(box_min.x + LayoutItemSize.x + 2, box_min.y + LayoutItemSize.y + 2); // Dubious
                            draw_list.AddRectFilled(box_min, box_max, icon_bg_color); // Background color
                            if (ShowTypeOverlay && item_data.Type != 0)
                            {
                                type_col := icon_type_overlay_colors[item_data.Type % len(icon_type_overlay_colors)];
                                draw_list.AddRectFilled(ImVec2{box_max.x - 2 - icon_type_overlay_size.x, box_min.y + 2}, ImVec2{box_max.x - 2, box_min.y + 2 + icon_type_overlay_size.y}, type_col);
                            }
                            if (display_label)
                            {
                                label_col := GetColorU32(item_is_selected ? ImGuiCol_Text : ImGuiCol_TextDisabled);
                                label : [32]u8,
                                sprintf(label, "%d", item_data.ID);
                                draw_list.AddText(ImVec2{box_min.x, box_max.y - GetFontSize(}), label_col, label);
                            }
                        }

                        PopID();
                    }
                }
            }
            clipper.End();
            PopStyleVar(); // ImGuiStyleVar_ItemSpacing

            // Context menu
            if (BeginPopupContextWindow())
            {
                Text("Selection: %d items", Selection.Size);
                Separator();
                if (MenuItem("Delete", "Del", false, Selection.Size > 0))
                    RequestDelete = true;
                EndPopup();
            }

            ms_io = EndMultiSelect();
            Selection.ApplyRequests(ms_io);
            if (want_delete)
                Selection.ApplyDeletionPostLoop(ms_io, Items, item_curr_idx_to_focus);

            // Zooming with CTRL+Wheel
            if (IsWindowAppearing())
                ZoomWheelAccum = 0.0;
            if (IsWindowHovered() && io.MouseWheel != 0.0 && IsKeyDown(ImGuiMod_Ctrl) && IsAnyItemActive() == false)
            {
                ZoomWheelAccum += io.MouseWheel;
                if (fabsf(ZoomWheelAccum) >= 1.0)
                {
                    // Calculate hovered item index from mouse location
                    // FIXME: Locking aiming on 'hovered_item_idx' (with a cool-down timer) would ensure zoom keeps on it.
                    hovered_item_nx := (io.MousePos.x - start_pos.x + LayoutItemSpacing * 0.5) / LayoutItemStep.x;
                    hovered_item_ny := (io.MousePos.y - start_pos.y + LayoutItemSpacing * 0.5) / LayoutItemStep.y;
                    hovered_item_idx := (cast(ast) ast) ed_item_nyem_nyyoutColumnCount) + cast() +) cast() +) em_nx)
                    //ImGui::SetTooltip("%f,%f -> item %d", hovered_item_nx, hovered_item_ny, hovered_item_idx); // Move those 4 lines in block above for easy debugging

                    // Zoom
                    IconSize *= powf(1.1, (f32)cast(ast) ast) heelAccumAc
                    IconSize = IM_CLAMP(IconSize, 16.0, 128.0);
                    ZoomWheelAccum -= cast(ast) ast) heelAccumA
                    UpdateLayoutSizes(avail_width);

                    // Manipulate scroll to that we will land at the same Y location of currently hovered item.
                    // - Calculate next frame position of item under mouse
                    // - Set new scroll position to be used in next ImGui::BeginChild() call.
                    hovered_item_rel_pos_y := ((f32)(hovered_item_idx / LayoutColumnCount) + fmodf(hovered_item_ny, 1.0)) * LayoutItemStep.y;
                    hovered_item_rel_pos_y += GetStyle().WindowPadding.y;
                    mouse_local_y := io.MousePos.y - GetWindowPos().y;
                    SetScrollY(hovered_item_rel_pos_y - mouse_local_y);
                }
            }
        }
        EndChild();

        Text("Selected: %d/%d items", Selection.Size, Items.Size);
        End();
    }
};

ShowExampleAppAssetsBrowser :: proc(p_open : ^bool)
{
    IMGUI_DEMO_MARKER("Examples/Assets Browser");
    static ExampleAssetsBrowser assets_browser;
    assets_browser.Draw("Example: Assets Browser", p_open);
}

// End of Demo code
} else {

void ShowAboutWindow(bool*) {}
void ShowDemoWindow(bool*) {}
void ShowUserGuide() {}
void ShowStyleEditor(ImGuiStyle*) {}
bool ShowStyleSelector(const u8* label) { return false; }
void ShowFontSelector(const u8* label) {}

}

} // #ifndef IMGUI_DISABLE
