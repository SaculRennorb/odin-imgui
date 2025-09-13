#+build windows
package im_win32

import "base:runtime"
import win32 "core:sys/windows"
import win32_ex "./win32_ex"
import im "../../"

IMGUI_IMPL_WIN32_DISABLE_GAMEPAD :: false
NOGDI :: false

// dear imgui: Platform Backend for Windows (standard windows API for 32-bits AND 64-bits applications)
// This needs to be used along with a Renderer (e.g. DirectX11, OpenGL3, Vulkan..)

// Implemented features:
//  [X] Platform: Clipboard support (for Win32 this is actually part of core dear imgui)
//  [X] Platform: Mouse support. Can discriminate Mouse/TouchScreen/Pen.
//  [X] Platform: Keyboard support. Since 1.87 we are using the io.AddKeyEvent() function. Pass ImGuiKey values to all key functions e.g. ImGui::IsKeyPressed(ImGuiKey_Space). [Legacy win32.VK_* values are obsolete since 1.87 and not supported since 1.91.5]
//  [X] Platform: Gamepad support. Enabled with 'io.ConfigFlags |= im.ImGuiConfigFlags_NavEnableGamepad'.
//  [X] Platform: Mouse cursor shape and visibility (ImGuiBackendFlags_HasMouseCursors). Disable with 'io.ConfigFlags |= im.ImGuiConfigFlags_NoMouseCursorChange'.
//  [X] Platform: Multi-viewport support (multiple windows). Enable with 'io.ConfigFlags |= im.ImGuiConfigFlags_ViewportsEnable'.

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// Learn about Dear ImGui:
// - FAQ                  https://dearimgui.com/faq
// - Getting Started      https://dearimgui.com/getting-started
// - Documentation        https://dearimgui.com/docs (same as your local docs/ folder).
// - Introduction, links and more at the top of imgui.cpp

// Configuration flags to add in your imconfig file:
//#define IMGUI_IMPL_WIN32_DISABLE_GAMEPAD              // Disable gamepad support. This was meaningful before <1.81 but we now load XInput dynamically so the option is now less relevant.

// CHANGELOG
// (minor and older changes stripped away, please see git history for details)
//  2025-XX-XX: Platform: Added support for multiple windows via the ImGuiPlatformIO interface.
//  2024-11-21: [Docking] Fixed a crash when multiple processes are running with multi-viewports, caused by misusage of GetProp(). (#8162, #8069)
//  2024-10-28: [Docking] Rely on property stored inside win32.HWND to retrieve context/viewport, should facilitate attempt to use this for parallel contexts. (#8069)
//  2024-09-16: [Docking] Inputs: fixed an issue where a viewport destroyed while clicking would hog mouse tracking and temporary lead to incorrect update of HoveredWindow. (#7971)
//  2024-07-08: Inputs: Fixed ImGuiMod_Super being mapped to win32.VK_APPS instead of win32.VK_LWIN||VK_RWIN. (#7768)
//  2023-10-05: Inputs: Added support for extra ImGuiKey values: F13 to F24 function keys, app back/forward keys.
//  2023-09-25: Inputs: Synthesize key-down event on key-up for win32.VK_SNAPSHOT / ImGuiKey_PrintScreen as Windows doesn't emit it (same behavior as GLFW/SDL).
//  2023-09-07: Inputs: Added support for keyboard codepage conversion for when application is compiled in MBCS mode and using a non-Unicode window.
//  2023-04-19: Added InitForOpenGL() to facilitate combining raw Win32/Winapi with OpenGL. (#3218)
//  2023-04-04: Inputs: Added support for io.AddMouseSourceEvent() to discriminate ImGuiMouseSource_Mouse/ImGuiMouseSource_TouchScreen/ImGuiMouseSource_Pen. (#2702)
//  2023-02-15: Inputs: Use win32.WM_NCMOUSEMOVE / win32.WM_NCMOUSELEAVE to track mouse position over non-client area (e.g. OS decorations) when app is not focused. (#6045, #6162)
//  2023-02-02: Inputs: Flipping win32.WM_MOUSEHWHEEL (horizontal mouse-wheel) value to match other backends and offer consistent horizontal scrolling direction. (#4019, #6096, #1463)
//  2022-10-11: Using 'nullptr' instead of 'NULL' as per our switch to C++11.
//  2022-09-28: Inputs: Convert win32.WM_CHAR values with MultiByteToWideChar() when window class was registered as MBCS (not Unicode).
//  2022-09-26: Inputs: Renamed ImGuiKey_ModXXX introduced in 1.87 to ImGuiMod_XXX (old names still supported).
//  2022-01-26: Inputs: replaced short-lived io.AddKeyModsEvent() (added two weeks ago) with io.AddKeyEvent() using ImGuiKey_ModXXX flags. Sorry for the confusion.
//  2021-01-20: Inputs: calling new io.AddKeyAnalogEvent() for gamepad support, instead of writing directly to io.NavInputs[].
//  2022-01-17: Inputs: calling new io.AddMousePosEvent(), io.AddMouseButtonEvent(), io.AddMouseWheelEvent() API (1.87+).
//  2022-01-17: Inputs: always update key mods next and before a key event (not in NewFrame) to fix input queue with very low framerates.
//  2022-01-12: Inputs: Update mouse inputs using win32.WM_MOUSEMOVE/WM_MOUSELEAVE + fallback to provide it when focused but not hovered/captured. More standard and will allow us to pass it to future input queue API.
//  2022-01-12: Inputs: Maintain our own copy of MouseButtonsDown mask instead of using ImGui::IsAnyMouseDown() which will be obsoleted.
//  2022-01-10: Inputs: calling new io.AddKeyEvent(), io.AddKeyModsEvent() + io.SetKeyEventNativeData() API (1.87+). Support for full ImGuiKey range.
//  2021-12-16: Inputs: Fill win32.VK_LCONTROL/VK_RCONTROL/VK_LSHIFT/VK_RSHIFT/VK_LMENU/VK_RMENU for completeness.
//  2021-08-17: Calling io.AddFocusEvent() on win32.WM_SETFOCUS/WM_KILLFOCUS messages.
//  2021-08-02: Inputs: Fixed keyboard modifiers being reported when host window doesn't have focus.
//  2021-07-29: Inputs: MousePos is correctly reported when the host platform window is hovered but not focused (using TrackMouseEvent() to receive win32.WM_MOUSELEAVE events).
//  2021-06-29: Reorganized backend to pull data from a single structure to facilitate usage with multiple-contexts (all g_XXXX access changed to bd->XXXX).
//  2021-06-08: Fixed EnableDpiAwareness() and GetDpiScaleForMonitor() to handle Windows 8.1/10 features without a manifest (per-monitor DPI, and properly calls SetProcessDpiAwareness() on 8.1).
//  2021-03-23: Inputs: Clearing keyboard down array when losing focus (WM_KILLFOCUS).
//  2021-02-18: Added EnableAlphaCompositing(). Non Visual Studio users will need to link with dwmapi.lib (MinGW/gcc: use -ldwmapi).
//  2021-02-17: Fixed EnableDpiAwareness() attempting to get SetProcessDpiAwareness from shcore.dll on Windows 8 whereas it is only supported on Windows 8.1.
//  2021-01-25: Inputs: Dynamically loading XInput DLL.
//  2020-12-04: Misc: Fixed setting of io.DisplaySize to invalid/uninitialized data when after win32.HWND has been closed.
//  2020-03-03: Inputs: Calling AddInputCharacterUTF16() to support surrogate pairs leading to codepoint >= 0x10000 (for more complete CJK inputs)
//  2020-02-17: Added EnableDpiAwareness(), GetDpiScaleForHwnd(), GetDpiScaleForMonitor() helper functions.
//  2020-01-14: Inputs: Added support for #define IMGUI_IMPL_WIN32_DISABLE_GAMEPAD/IMGUI_IMPL_WIN32_DISABLE_LINKING_XINPUT.
//  2019-12-05: Inputs: Added support for ImGuiMouseCursor_NotAllowed mouse cursor.
//  2019-05-11: Inputs: Don't filter value from win32.WM_CHAR before calling AddInputCharacter().
//  2019-01-17: Misc: Using GetForegroundWindow()+IsChild() instead of GetActiveWindow() to be compatible with windows created in a different thread or parent.
//  2019-01-17: Inputs: Added support for mouse buttons 4 and 5 via win32.WM_XBUTTON* messages.
//  2019-01-15: Inputs: Added support for XInput gamepads (if im.ImGuiConfigFlags_NavEnableGamepad is set by user application).
//  2018-11-30: Misc: Setting up io.BackendPlatformName so it can be displayed in the About Window.
//  2018-06-29: Inputs: Added support for the ImGuiMouseCursor_Hand cursor.
//  2018-06-10: Inputs: Fixed handling of mouse wheel messages to support fine position messages (typically sent by track-pads).
//  2018-06-08: Misc: Extracted imgui_impl_win32.cpp/.h away from the old combined DX9/DX10/DX11/DX12 examples.
//  2018-03-20: Misc: Setup io.BackendFlags ImGuiBackendFlags_HasMouseCursors and ImGuiBackendFlags_HasSetMousePos flags + honor im.ImGuiConfigFlags_NoMouseCursorChange flag.
//  2018-02-20: Inputs: Added support for mouse cursors (ImGui::GetMouseCursor() value and win32.WM_SETCURSOR message handling).
//  2018-02-06: Inputs: Added mapping for ImGuiKey_Space.
//  2018-02-06: Inputs: Honoring the io.WantSetMousePos by repositioning the mouse (when using navigation and im.ImGuiConfigFlags_NavMoveMouse is set).
//  2018-02-06: Misc: Removed call to ImGui::Shutdown() which is not available from 1.60 WIP, user needs to call CreateContext/DestroyContext themselves.
//  2018-01-20: Inputs: Added Horizontal Mouse Wheel support.
//  2018-01-08: Inputs: Added mapping for ImGuiKey_Insert.
//  2018-01-05: Inputs: Added win32.WM_LBUTTONDBLCLK double-click handlers for window classes with the CS_DBLCLKS flag.
//  2017-10-23: Inputs: Added win32.WM_SYSKEYDOWN / win32.WM_SYSKEYUP handlers so e.g. the win32.VK_MENU key can be read.
//  2017-10-23: Inputs: Using Win32 ::SetCapture/::GetCapture() to retrieve mouse positions outside the client area when dragging.
//  2016-11-12: Inputs: Only call Win32 ::SetCursor(nullptr) when io.MouseDrawCursor is set.


// dear imgui: Platform Backend for Windows (standard windows API for 32-bits AND 64-bits applications)
// This needs to be used along with a Renderer (e.g. DirectX11, OpenGL3, Vulkan..)

// Implemented features:
//  [X] Platform: Clipboard support (for Win32 this is actually part of core dear imgui)
//  [X] Platform: Mouse support. Can discriminate Mouse/TouchScreen/Pen.
//  [X] Platform: Keyboard support. Since 1.87 we are using the io.AddKeyEvent() function. Pass ImGuiKey values to all key functions e.g. ImGui::IsKeyPressed(ImGuiKey_Space). [Legacy win32.VK_* values are obsolete since 1.87 and not supported since 1.91.5]
//  [X] Platform: Gamepad support. Enabled with 'io.ConfigFlags |= im.ImGuiConfigFlags_NavEnableGamepad'.
//  [X] Platform: Mouse cursor shape and visibility (ImGuiBackendFlags_HasMouseCursors). Disable with 'io.ConfigFlags |= im.ImGuiConfigFlags_NoMouseCursorChange'.
//  [X] Platform: Multi-viewport support (multiple windows). Enable with 'io.ConfigFlags |= im.ImGuiConfigFlags_ViewportsEnable'.

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// Learn about Dear ImGui:
// - FAQ                  https://dearimgui.com/faq
// - Getting Started      https://dearimgui.com/getting-started
// - Documentation        https://dearimgui.com/docs (same as your local docs/ folder).
// - Introduction, links and more at the top of imgui.cpp

// Using XInput for gamepad (will load DLL dynamically)
when ! IMGUI_IMPL_WIN32_DISABLE_GAMEPAD { /* @gen ifndef */
PFN_XInputGetCapabilities :: proc(_ : win32.DWORD, _ : win32.XINPUT_FLAG, _ : ^win32.XINPUT_CAPABILITIES) -> win32.DWORD
PFN_XInputGetState :: proc(_ : win32.DWORD, _ : ^win32.XINPUT_STATE) -> win32.DWORD
} // preproc endif

when ! IMGUI_IMPL_WIN32_DISABLE_GAMEPAD { /* @gen ifndef */
Data :: struct {
	hWnd : win32.HWND,
	MouseHwnd : win32.HWND,
	MouseTrackedArea : i32, // 0: not tracked, 1: client area, 2: non-client area
	MouseButtonsDown : i32,
	Time : win32.INT64,
	TicksPerSecond : win32.INT64,
	LastMouseCursor : im.ImGuiMouseCursor,
	KeyboardCodePage : win32.UINT32,
	WantUpdateMonitors : bool,

	HasGamepad : bool,
	WantUpdateHasGamepad : bool,
	XInputDLL : win32.HMODULE,
	XInputGetCapabilities : PFN_XInputGetCapabilities,
	XInputGetState : PFN_XInputGetState,
}
} else {
Data :: struct {
	hWnd : win32.HWND,
	MouseHwnd : win32.HWND,
	MouseTrackedArea : i32, // 0: not tracked, 1: client area, 2: non-client area
	MouseButtonsDown : i32,
	Time : INT64,
	TicksPerSecond : INT64,
	LastMouseCursor : ImGuiMouseCursor,
	KeyboardCodePage : win32.UINT32,
	WantUpdateMonitors : bool,
}
} // preproc endif

Data_init :: proc(this : ^Data) { this^ = {} }

GetBackendData :: proc { GetBackendData_0, GetBackendData_1 }
// Backend data stored in io.BackendPlatformUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
// FIXME: multi-context support is not well tested and probably dysfunctional in this backend.
// FIXME: some shared resources (mouse cursor shape, gamepad) are mishandled when using multi-context.
GetBackendData_0 :: proc() -> ^Data
{
	return im.GetCurrentContext() != nil ? cast(^Data) im.GetIO().BackendPlatformUserData : nil
}
GetBackendData_1 :: proc(io : ^im.ImGuiIO) -> ^Data
{
	return cast(^Data) io.BackendPlatformUserData
}

// Functions
UpdateKeyboardCodePage :: proc(io : ^im.ImGuiIO)
{
	// Retrieve keyboard code page, required for handling of non-Unicode Windows.
	bd : ^Data = GetBackendData(io)
	keyboard_layout := win32_ex.GetKeyboardLayout(0)
	keyboard_lcid : win32.LCID = win32.MAKELCID(win32.HIWORD(uintptr(keyboard_layout)), win32_ex.SORT_DEFAULT)
	if win32_ex.GetLocaleInfoA(keyboard_lcid, (win32_ex.LOCALE_RETURN_NUMBER | win32_ex.LOCALE_IDEFAULTANSICODEPAGE), cast(win32.LPSTR) &bd.KeyboardCodePage, size_of(bd.KeyboardCodePage)) == 0 {
		// Fallback to default ANSI code page when fails.
		bd.KeyboardCodePage = win32.CP_ACP
	}
}

InitEx :: proc(hwnd : rawptr, platform_has_own_dc : bool) -> bool
{
	io := im.GetIO()
	im.CHECKVERSION()
	im.IM_ASSERT(io.BackendPlatformUserData == nil, "Already initialized a platform backend!")

	perf_frequency : win32.INT64; perf_counter : win32.INT64
	if win32.QueryPerformanceFrequency(cast(^win32.LARGE_INTEGER) &perf_frequency) == {} { return false }
	if win32.QueryPerformanceCounter(cast(^win32.LARGE_INTEGER) &perf_counter) == {} { return false }

	// Setup backend capabilities flags
	bd := im.IM_NEW_MEM(Data); Data_init(bd)
	io.BackendPlatformUserData = cast(rawptr) bd
	io.BackendPlatformName = "imgui_impl_win32"
	io.BackendFlags |= .ImGuiBackendFlags_HasMouseCursors; // We can honor GetMouseCursor() values (optional)
	io.BackendFlags |= .ImGuiBackendFlags_HasSetMousePos; // We can honor io.WantSetMousePos requests (optional, rarely used)
	io.BackendFlags |= .ImGuiBackendFlags_PlatformHasViewports; // We can create multi-viewports on the Platform side (optional)
	io.BackendFlags |= .ImGuiBackendFlags_HasMouseHoveredViewport; // We can call io.AddMouseViewportEvent() with correct data (optional)

	bd.hWnd = cast(win32.HWND) hwnd
	bd.TicksPerSecond = perf_frequency
	bd.Time = perf_counter
	bd.LastMouseCursor = .ImGuiMouseCursor_COUNT
	UpdateKeyboardCodePage(io)

	// Update monitor a first time during init
	UpdateMonitors()

	// Our mouse update function expect PlatformHandle to be filled for the main viewport
	main_viewport := im.GetMainViewport()
	main_viewport.PlatformHandleRaw = cast(rawptr) bd.hWnd; main_viewport.PlatformHandle = main_viewport.PlatformHandleRaw

	// Be aware that GetPropA()/SetPropA() may be accessed from other processes.
	// So as we store a pointer in IMGUI_CONTEXT we need to make sure we only call GetPropA() on windows owned by our process.
	win32.SetPropW(bd.hWnd, "IMGUI_CONTEXT", cast(win32.HANDLE) im.GetCurrentContext())
	InitMultiViewportSupport(platform_has_own_dc)

	// Dynamically load XInput library
	when ! IMGUI_IMPL_WIN32_DISABLE_GAMEPAD { /* @gen ifndef */
	bd.WantUpdateHasGamepad = true
	xinput_dll_names :=  [?]cstring16 {
		"xinput1_4.dll", // Windows 8+
		"xinput1_3.dll", // DirectX SDK
		"xinput9_1_0.dll", // Windows Vista, Windows 7
		"xinput1_2.dll", // DirectX SDK
		"xinput1_1.dll", // DirectX SDK
	}
	for n : i32 = 0; n < cast(i32)len(xinput_dll_names); n += 1 { if dll := win32.LoadLibraryW(xinput_dll_names[n]); dll != nil {
	bd.XInputDLL = dll
	bd.XInputGetCapabilities = cast(PFN_XInputGetCapabilities) win32.GetProcAddress(dll, "XInputGetCapabilities")
	bd.XInputGetState = cast(PFN_XInputGetState) win32.GetProcAddress(dll, "XInputGetState")
	break
} }

	} // preproc endif// IMGUI_IMPL_WIN32_DISABLE_GAMEPAD

	return true
}

// Follow "Getting Started" link and check examples/ folder to learn about using backends!
Init :: proc(hwnd : rawptr) -> bool
{
	return InitEx(hwnd, false)
}

InitForOpenGL :: proc(hwnd : rawptr) -> bool
{
	// OpenGL needs CS_OWNDC
	return InitEx(hwnd, true)
}

Shutdown :: proc()
{
	bd : ^Data = GetBackendData()
	im.IM_ASSERT(bd != nil, "No platform backend to shutdown, or already shutdown?")
	io := im.GetIO()

	win32.SetPropW(bd.hWnd, "IMGUI_CONTEXT", nil)
	ShutdownMultiViewportSupport()

	// Unload XInput library
	when ! IMGUI_IMPL_WIN32_DISABLE_GAMEPAD { /* @gen ifndef */
	if bd.XInputDLL != {} { win32.FreeLibrary(bd.XInputDLL) }
	} // preproc endif// IMGUI_IMPL_WIN32_DISABLE_GAMEPAD

	io.BackendPlatformName = ""
	io.BackendPlatformUserData = nil
	io.BackendFlags &= cast(im.ImGuiBackendFlags)~i32(im.ImGuiBackendFlags_.ImGuiBackendFlags_HasMouseCursors | im.ImGuiBackendFlags_.ImGuiBackendFlags_HasSetMousePos | im.ImGuiBackendFlags_.ImGuiBackendFlags_HasGamepad | im.ImGuiBackendFlags_.ImGuiBackendFlags_PlatformHasViewports | im.ImGuiBackendFlags_.ImGuiBackendFlags_HasMouseHoveredViewport)
	im.IM_FREE(bd)
}

UpdateMouseCursor :: proc(io : ^im.ImGuiIO, imgui_cursor : im.ImGuiMouseCursor) -> bool
{
	if (io.ConfigFlags & im.ImGuiConfigFlags_.ImGuiConfigFlags_NoMouseCursorChange) != {} { return false }

	if imgui_cursor == im.ImGuiMouseCursor_.ImGuiMouseCursor_None || io.MouseDrawCursor {
		// Hide OS mouse cursor if imgui is drawing it or if it wants no cursor
		win32.SetCursor(nil)
	}
	else {
		// Show OS mouse cursor
		win32_cursor := win32.IDC_ARROW
		#partial switch imgui_cursor {
			case .ImGuiMouseCursor_Arrow:      win32_cursor = win32.IDC_ARROW; break
			case .ImGuiMouseCursor_TextInput:  win32_cursor = win32.IDC_IBEAM; break
			case .ImGuiMouseCursor_ResizeAll:  win32_cursor = win32.IDC_SIZEALL; break
			case .ImGuiMouseCursor_ResizeEW:   win32_cursor = win32.IDC_SIZEWE; break
			case .ImGuiMouseCursor_ResizeNS:   win32_cursor = win32.IDC_SIZENS; break
			case .ImGuiMouseCursor_ResizeNESW: win32_cursor = win32.IDC_SIZENESW; break
			case .ImGuiMouseCursor_ResizeNWSE: win32_cursor = win32.IDC_SIZENWSE; break
			case .ImGuiMouseCursor_Hand:       win32_cursor = win32.IDC_HAND; break
			case .ImGuiMouseCursor_NotAllowed: win32_cursor = win32.IDC_NO; break
		}
		win32.SetCursor(win32.LoadCursorA(nil, win32_cursor))
	}
	return true
}

IsVkDown :: proc(vk : i32) -> bool
{
	return (win32.GetKeyState(vk) & transmute(i16) u16(0x8000)) != {}
}

AddKeyEvent :: proc(io : ^im.ImGuiIO, key : im.ImGuiKey, down : bool, native_keycode : i32, native_scancode : i32 = -1)
{
	im.AddKeyEvent(io, key, down)
	im.SetKeyEventNativeData(io, key, native_keycode, native_scancode); // To support legacy indexing (<1.87 user code)
	 _ = native_scancode
}

ProcessKeyEventsWorkarounds :: proc(io : ^im.ImGuiIO)
{
	// Left & right Shift keys: when both are pressed together, Windows tend to not generate the win32.WM_KEYUP event for the first released one.
	if im.IsKeyDown(.ImGuiKey_LeftShift) && !IsVkDown(win32.VK_LSHIFT) { AddKeyEvent(io, .ImGuiKey_LeftShift, false, win32.VK_LSHIFT) }
	if im.IsKeyDown(.ImGuiKey_RightShift) && !IsVkDown(win32.VK_RSHIFT) { AddKeyEvent(io, .ImGuiKey_RightShift, false, win32.VK_RSHIFT) }

	// Sometimes win32.WM_KEYUP for Win key is not passed down to the app (e.g. for Win+V on some setups, according to GLFW).
	if im.IsKeyDown(.ImGuiKey_LeftSuper) && !IsVkDown(win32.VK_LWIN) { AddKeyEvent(io, .ImGuiKey_LeftSuper, false, win32.VK_LWIN) }
	if im.IsKeyDown(.ImGuiKey_RightSuper) && !IsVkDown(win32.VK_RWIN) { AddKeyEvent(io, .ImGuiKey_RightSuper, false, win32.VK_RWIN) }
}

UpdateKeyModifiers :: proc(io : ^im.ImGuiIO)
{
	im.AddKeyEvent(io, .ImGuiMod_Ctrl, IsVkDown(win32.VK_CONTROL))
	im.AddKeyEvent(io, .ImGuiMod_Shift, IsVkDown(win32.VK_SHIFT))
	im.AddKeyEvent(io, .ImGuiMod_Alt, IsVkDown(win32.VK_MENU))
	im.AddKeyEvent(io, .ImGuiMod_Super, IsVkDown(win32.VK_LWIN) || IsVkDown(win32.VK_RWIN))
}

FindViewportByPlatformHandle :: proc(platform_io : ^im.ImGuiPlatformIO, hwnd : win32.HWND) -> ^im.ImGuiViewport
{
	// We cannot use ImGui::FindViewportByPlatformHandle() because it doesn't take a context.
	// When called from WndProcHandler_PlatformWindow() we don't assume that context is bound.
	//return ImGui::FindViewportByPlatformHandle((void*)hwnd);
	for viewport in platform_io.Viewports.Data[:platform_io.Viewports.Size] { if viewport.PlatformHandle == hwnd { return viewport } }

	return nil
}

// This code supports multi-viewports (multiple OS Windows mapped into different Dear ImGui viewports)
// Because of that, it is a little more complicated than your typical single-viewport binding code!
UpdateMouseData :: proc(io : ^im.ImGuiIO, platform_io : ^im.ImGuiPlatformIO)
{
	bd := GetBackendData(io)
	im.IM_ASSERT(bd.hWnd != {})

	mouse_screen_pos : win32.POINT
	has_mouse_screen_pos : bool = win32.GetCursorPos(&mouse_screen_pos) != {}

	focused_window := win32.GetForegroundWindow()
	is_app_focused : bool = (focused_window != {} && (focused_window == bd.hWnd || win32.IsChild(focused_window, bd.hWnd) != {} || FindViewportByPlatformHandle(platform_io, focused_window) != nil))
	if is_app_focused {
		// (Optional) Set OS mouse position from Dear ImGui if requested (rarely used, only when io.ConfigNavMoveSetMousePos is enabled by user)
		// When multi-viewports are enabled, all Dear ImGui positions are same as OS positions.
		if io.WantSetMousePos {
			pos : win32.POINT = {cast(i32) io.MousePos.x, cast(i32) io.MousePos.y}
			if (io.ConfigFlags & im.ImGuiConfigFlags_.ImGuiConfigFlags_ViewportsEnable) == {} { win32.ClientToScreen(focused_window, &pos) }
			win32.SetCursorPos(pos.x, pos.y)
		}

		// (Optional) Fallback to provide mouse position when focused (WM_MOUSEMOVE already provides this when hovered or captured)
		// This also fills a short gap when clicking non-client area: win32.WM_NCMOUSELEAVE -> modal OS move -> gap -> win32.WM_NCMOUSEMOVE
		if !io.WantSetMousePos && bd.MouseTrackedArea == 0 && has_mouse_screen_pos {
			// Single viewport mode: mouse position in client window coordinates (io.MousePos is (0,0) when the mouse is on the upper-left corner of the app window)
			// (This is the position you can get with ::GetCursorPos() + ::ScreenToClient() or win32.WM_MOUSEMOVE.)
			// Multi-viewport mode: mouse position in OS absolute coordinates (io.MousePos is (0,0) when the mouse is on the upper-left of the primary monitor)
			// (This is the position you can get with ::GetCursorPos() or win32.WM_MOUSEMOVE + ::ClientToScreen(). In theory adding viewport->Pos to a client position would also be the same.)
			mouse_pos : win32.POINT = mouse_screen_pos
			if (io.ConfigFlags & im.ImGuiConfigFlags_.ImGuiConfigFlags_ViewportsEnable) == {} { win32.ScreenToClient(bd.hWnd, &mouse_pos) }
			im.AddMousePosEvent(io, cast(f32) mouse_pos.x, cast(f32) mouse_pos.y)
		}
	}

	// (Optional) When using multiple viewports: call io.AddMouseViewportEvent() with the viewport the OS mouse cursor is hovering.
	// If ImGuiBackendFlags_HasMouseHoveredViewport is not set by the backend, Dear imGui will ignore this field and infer the information using its flawed heuristic.
	// - [X] Win32 backend correctly ignore viewports with the _NoInputs flag (here using ::WindowFromPoint with win32.WM_NCHITTEST + HTTRANSPARENT in WndProc does that)
	//       Some backend are not able to handle that correctly. If a backend report an hovered viewport that has the _NoInputs flag (e.g. when dragging a window
	//       for docking, the viewport has the _NoInputs flag in order to allow us to find the viewport under), then Dear ImGui is forced to ignore the value reported
	//       by the backend, and use its flawed heuristic to guess the viewport behind.
	// - [X] Win32 backend correctly reports this regardless of another viewport behind focused and dragged from (we need this to find a useful drag and drop target).
	mouse_viewport_id : im.ImGuiID = 0
	if has_mouse_screen_pos {
		if hovered_hwnd := win32_ex.WindowFromPoint(mouse_screen_pos); hovered_hwnd != {} {
			if viewport := FindViewportByPlatformHandle(platform_io, hovered_hwnd); viewport != nil {
				mouse_viewport_id = viewport.ID
			}
		}
	}
	im.AddMouseViewportEvent(io, mouse_viewport_id)
}

// Gamepad navigation mapping
UpdateGamepads :: proc(io : ^im.ImGuiIO)
{
	when ! IMGUI_IMPL_WIN32_DISABLE_GAMEPAD { /* @gen ifndef */
	bd := GetBackendData(io)
	//if ((io.ConfigFlags & im.ImGuiConfigFlags_NavEnableGamepad) == 0) // FIXME: Technically feeding gamepad shouldn't depend on this now that they are regular inputs.
	//    return;

	// Calling XInputGetState() every frame on disconnected gamepads is unfortunately too slow.
	// Instead we refresh gamepad availability by calling XInputGetCapabilities() _only_ after receiving win32.WM_DEVICECHANGE.
	if bd.WantUpdateHasGamepad {
		caps : win32.XINPUT_CAPABILITIES = {}
		bd.HasGamepad = bd.XInputGetCapabilities != {} ? (bd.XInputGetCapabilities(0, { .GAMEPAD }, &caps) == win32.ERROR_SUCCESS) : false
		bd.WantUpdateHasGamepad = false
	}

	io.BackendFlags &= cast(im.ImGuiBackendFlags) ~cast(i32)im.ImGuiBackendFlags_.ImGuiBackendFlags_HasGamepad
	xinput_state : win32.XINPUT_STATE
	gamepad : ^win32.XINPUT_GAMEPAD = &xinput_state.Gamepad
	if !bd.HasGamepad || bd.XInputGetState == nil || bd.XInputGetState(0, &xinput_state) != win32.ERROR_SUCCESS { return }
	io.BackendFlags |= im.ImGuiBackendFlags_.ImGuiBackendFlags_HasGamepad

	IM_SATURATE :: #force_inline proc "contextless" (V : f32) -> f32
	{
		return (V < 0.0 ? 0.0 : (V > 1.0 ? 1.0 : V))
	}

	MAP_BUTTON :: #force_inline proc(io : ^im.ImGuiIO, gamepad : ^win32.XINPUT_GAMEPAD, KEY_NO : im.ImGuiKey, BUTTON_ENUM : win32.XINPUT_GAMEPAD_BUTTON)
	{
		im.AddKeyEvent(io, KEY_NO, (gamepad.wButtons & BUTTON_ENUM) != {});
	}

	MAP_ANALOG :: #force_inline proc(io : ^im.ImGuiIO, KEY_NO : im.ImGuiKey, VALUE, V0, V1 : $T3)
	{
		vn := cast(f32)(VALUE - V0) / (f32)(V1 - V0);
		im.AddKeyAnalogEvent(io, KEY_NO, vn > 0.10, IM_SATURATE(vn));
	}

	MAP_BUTTON(io, gamepad, .ImGuiKey_GamepadStart, { .START })
	MAP_BUTTON(io, gamepad, .ImGuiKey_GamepadBack, { .BACK })
	MAP_BUTTON(io, gamepad, .ImGuiKey_GamepadFaceLeft, { .X })
	MAP_BUTTON(io, gamepad, .ImGuiKey_GamepadFaceRight, { .B })
	MAP_BUTTON(io, gamepad, .ImGuiKey_GamepadFaceUp, { .Y })
	MAP_BUTTON(io, gamepad, .ImGuiKey_GamepadFaceDown, { .A })
	MAP_BUTTON(io, gamepad, .ImGuiKey_GamepadDpadLeft, { .DPAD_LEFT })
	MAP_BUTTON(io, gamepad, .ImGuiKey_GamepadDpadRight, { .DPAD_RIGHT })
	MAP_BUTTON(io, gamepad, .ImGuiKey_GamepadDpadUp, { .DPAD_UP })
	MAP_BUTTON(io, gamepad, .ImGuiKey_GamepadDpadDown, { .DPAD_DOWN })
	MAP_BUTTON(io, gamepad, .ImGuiKey_GamepadL1, { .LEFT_SHOULDER })
	MAP_BUTTON(io, gamepad, .ImGuiKey_GamepadR1, { .RIGHT_SHOULDER })
	MAP_ANALOG(io,          .ImGuiKey_GamepadL2, gamepad.bLeftTrigger, win32.BYTE(win32.XINPUT_GAMEPAD_TRIGGER_THRESHOLD), 255)
	MAP_ANALOG(io,          .ImGuiKey_GamepadR2, gamepad.bRightTrigger, win32.BYTE(win32.XINPUT_GAMEPAD_TRIGGER_THRESHOLD), 255)
	MAP_BUTTON(io, gamepad, .ImGuiKey_GamepadL3, { .LEFT_THUMB })
	MAP_BUTTON(io, gamepad, .ImGuiKey_GamepadR3, { .RIGHT_THUMB })
	MAP_ANALOG(io,          .ImGuiKey_GamepadLStickLeft, gamepad.sThumbLX, -win32.XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, -32768)
	MAP_ANALOG(io,          .ImGuiKey_GamepadLStickRight, gamepad.sThumbLX, +win32.XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, +32767)
	MAP_ANALOG(io,          .ImGuiKey_GamepadLStickUp, gamepad.sThumbLY, +win32.XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, +32767)
	MAP_ANALOG(io,          .ImGuiKey_GamepadLStickDown, gamepad.sThumbLY, -win32.XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, -32768)
	MAP_ANALOG(io,          .ImGuiKey_GamepadRStickLeft, gamepad.sThumbRX, -win32.XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, -32768)
	MAP_ANALOG(io,          .ImGuiKey_GamepadRStickRight, gamepad.sThumbRX, +win32.XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, +32767)
	MAP_ANALOG(io,          .ImGuiKey_GamepadRStickUp, gamepad.sThumbRY, +win32.XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, +32767)
	MAP_ANALOG(io,          .ImGuiKey_GamepadRStickDown, gamepad.sThumbRY, -win32.XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, -32768)
	} else { // #ifndef IMGUI_IMPL_WIN32_DISABLE_GAMEPAD
	_ = io
	} // preproc endif
}

UpdateMonitors_EnumFunc :: proc "system" (monitor : win32.HMONITOR, _ : win32.HDC, _ : win32.LPRECT, userdata : win32.LPARAM) -> win32.BOOL
{
	context = (^runtime.Context)(uintptr(userdata))^

	info : win32.MONITORINFO = {}
	info.cbSize = size_of(win32.MONITORINFO)
	if win32.GetMonitorInfoW(monitor, &info) == {} { return win32.TRUE }
	imgui_monitor : im.ImGuiPlatformMonitor
	imgui_monitor.MainPos = {cast(f32) info.rcMonitor.left, cast(f32) info.rcMonitor.top}
	imgui_monitor.MainSize = {cast(f32) (info.rcMonitor.right - info.rcMonitor.left), cast(f32) (info.rcMonitor.bottom - info.rcMonitor.top)}
	imgui_monitor.WorkPos = {cast(f32) info.rcWork.left, cast(f32) info.rcWork.top}
	imgui_monitor.WorkSize = {cast(f32) (info.rcWork.right - info.rcWork.left), cast(f32) (info.rcWork.bottom - info.rcWork.top)}
	imgui_monitor.DpiScale = GetDpiScaleForMonitor(monitor)
	imgui_monitor.PlatformHandle = cast(rawptr) monitor
	if imgui_monitor.DpiScale <= 0.0 {
		// Some accessibility applications are declaring virtual monitors with a DPI of 0, see #7902.
		return win32.TRUE
	}
	io := im.GetPlatformIO()
	MONITORINFOF_PRIMARY :: 0x00000001
	if (info.dwFlags & MONITORINFOF_PRIMARY) != {} { im.push_front(&io.Monitors, imgui_monitor) }
	else { im.push_back(&io.Monitors, imgui_monitor) }
	return win32.TRUE
}

UpdateMonitors :: proc()
{
	bd : ^Data = GetBackendData()
	im.resize(&im.GetPlatformIO().Monitors, 0)
	c := context
	win32.EnumDisplayMonitors(nil, nil, UpdateMonitors_EnumFunc, cast(win32.LPARAM) uintptr(&c))
	bd.WantUpdateMonitors = false
}

NewFrame :: proc()
{
	bd : ^Data = GetBackendData()
	im.IM_ASSERT(bd != nil, "Context or backend not initialized? Did you call Init()?")
	io := im.GetIO()
	platform_io := im.GetPlatformIO()

	// Setup display size (every frame to accommodate for window resizing)
	rect : win32.RECT = {0, 0, 0, 0}
	win32.GetClientRect(bd.hWnd, &rect)
	io.DisplaySize = {cast(f32) (rect.right - rect.left), cast(f32) (rect.bottom - rect.top)}
	if bd.WantUpdateMonitors { UpdateMonitors() }

	// Setup time step
	current_time : win32.INT64 = 0
	win32.QueryPerformanceCounter(cast(^win32.LARGE_INTEGER) &current_time)
	io.DeltaTime = cast(f32) (current_time - bd.Time) / f32(bd.TicksPerSecond)
	bd.Time = current_time

	// Update OS mouse position
	UpdateMouseData(io, platform_io)

	// Process workarounds for known Windows key handling issues
	ProcessKeyEventsWorkarounds(io)

	// Update OS mouse cursor with the cursor requested by imgui
	mouse_cursor := io.MouseDrawCursor ? im.ImGuiMouseCursor_.ImGuiMouseCursor_None : im.GetMouseCursor()
	if bd.LastMouseCursor != mouse_cursor {
		bd.LastMouseCursor = mouse_cursor
		UpdateMouseCursor(io, mouse_cursor)
	}

	// Update game controllers (if enabled and available)
	UpdateGamepads(io)
}

// Map VK_xxx to ImGuiKey_xxx.
// Not static to allow third-party code to use that if they want to (but undocumented)
KeyEventToImGuiKey :: proc(wParam : win32.WPARAM, lParam : win32.LPARAM) -> im.ImGuiKey
{
	// There is no distinct VK_xxx for keypad enter, instead it is VK_RETURN + KF_EXTENDED.
	if (wParam == win32.VK_RETURN) && (win32.HIWORD(lParam) & win32.KF_EXTENDED) != {} { return .ImGuiKey_KeypadEnter }

	switch wParam {
		case win32.VK_TAB:       return .ImGuiKey_Tab
		case win32.VK_LEFT:      return .ImGuiKey_LeftArrow
		case win32.VK_RIGHT:     return .ImGuiKey_RightArrow
		case win32.VK_UP:        return .ImGuiKey_UpArrow
		case win32.VK_DOWN:      return .ImGuiKey_DownArrow
		case win32.VK_PRIOR:     return .ImGuiKey_PageUp
		case win32.VK_NEXT:      return .ImGuiKey_PageDown
		case win32.VK_HOME:      return .ImGuiKey_Home
		case win32.VK_END:       return .ImGuiKey_End
		case win32.VK_INSERT:    return .ImGuiKey_Insert
		case win32.VK_DELETE:    return .ImGuiKey_Delete
		case win32.VK_BACK:      return .ImGuiKey_Backspace
		case win32.VK_SPACE:     return .ImGuiKey_Space
		case win32.VK_RETURN:    return .ImGuiKey_Enter
		case win32.VK_ESCAPE:    return .ImGuiKey_Escape
		case win32.VK_OEM_7:     return .ImGuiKey_Apostrophe
		case win32.VK_OEM_COMMA: return .ImGuiKey_Comma
		case win32.VK_OEM_MINUS: return .ImGuiKey_Minus
		case win32.VK_OEM_PERIOD:return .ImGuiKey_Period
		case win32.VK_OEM_2:     return .ImGuiKey_Slash
		case win32.VK_OEM_1:     return .ImGuiKey_Semicolon
		case win32.VK_OEM_PLUS:  return .ImGuiKey_Equal
		case win32.VK_OEM_4:     return .ImGuiKey_LeftBracket
		case win32.VK_OEM_5:     return .ImGuiKey_Backslash
		case win32.VK_OEM_6:     return .ImGuiKey_RightBracket
		case win32.VK_OEM_3:     return .ImGuiKey_GraveAccent
		case win32.VK_CAPITAL:   return .ImGuiKey_CapsLock
		case win32.VK_SCROLL:    return .ImGuiKey_ScrollLock
		case win32.VK_NUMLOCK:   return .ImGuiKey_NumLock
		case win32.VK_SNAPSHOT:  return .ImGuiKey_PrintScreen
		case win32.VK_PAUSE:     return .ImGuiKey_Pause
		case win32.VK_NUMPAD0:   return .ImGuiKey_Keypad0
		case win32.VK_NUMPAD1:   return .ImGuiKey_Keypad1
		case win32.VK_NUMPAD2:   return .ImGuiKey_Keypad2
		case win32.VK_NUMPAD3:   return .ImGuiKey_Keypad3
		case win32.VK_NUMPAD4:   return .ImGuiKey_Keypad4
		case win32.VK_NUMPAD5:   return .ImGuiKey_Keypad5
		case win32.VK_NUMPAD6:   return .ImGuiKey_Keypad6
		case win32.VK_NUMPAD7:   return .ImGuiKey_Keypad7
		case win32.VK_NUMPAD8:   return .ImGuiKey_Keypad8
		case win32.VK_NUMPAD9:   return .ImGuiKey_Keypad9
		case win32.VK_DECIMAL:   return .ImGuiKey_KeypadDecimal
		case win32.VK_DIVIDE:    return .ImGuiKey_KeypadDivide
		case win32.VK_MULTIPLY:  return .ImGuiKey_KeypadMultiply
		case win32.VK_SUBTRACT:  return .ImGuiKey_KeypadSubtract
		case win32.VK_ADD:       return .ImGuiKey_KeypadAdd
		case win32.VK_LSHIFT:    return .ImGuiKey_LeftShift
		case win32.VK_LCONTROL:  return .ImGuiKey_LeftCtrl
		case win32.VK_LMENU:     return .ImGuiKey_LeftAlt
		case win32.VK_LWIN:      return .ImGuiKey_LeftSuper
		case win32.VK_RSHIFT:    return .ImGuiKey_RightShift
		case win32.VK_RCONTROL:  return .ImGuiKey_RightCtrl
		case win32.VK_RMENU:     return .ImGuiKey_RightAlt
		case win32.VK_RWIN:      return .ImGuiKey_RightSuper
		case win32.VK_APPS:      return .ImGuiKey_Menu
		case '0':                return .ImGuiKey_0
		case '1':                return .ImGuiKey_1
		case '2':                return .ImGuiKey_2
		case '3':                return .ImGuiKey_3
		case '4':                return .ImGuiKey_4
		case '5':                return .ImGuiKey_5
		case '6':                return .ImGuiKey_6
		case '7':                return .ImGuiKey_7
		case '8':                return .ImGuiKey_8
		case '9':                return .ImGuiKey_9
		case 'A':                return .ImGuiKey_A
		case 'B':                return .ImGuiKey_B
		case 'C':                return .ImGuiKey_C
		case 'D':                return .ImGuiKey_D
		case 'E':                return .ImGuiKey_E
		case 'F':                return .ImGuiKey_F
		case 'G':                return .ImGuiKey_G
		case 'H':                return .ImGuiKey_H
		case 'I':                return .ImGuiKey_I
		case 'J':                return .ImGuiKey_J
		case 'K':                return .ImGuiKey_K
		case 'L':                return .ImGuiKey_L
		case 'M':                return .ImGuiKey_M
		case 'N':                return .ImGuiKey_N
		case 'O':                return .ImGuiKey_O
		case 'P':                return .ImGuiKey_P
		case 'Q':                return .ImGuiKey_Q
		case 'R':                return .ImGuiKey_R
		case 'S':                return .ImGuiKey_S
		case 'T':                return .ImGuiKey_T
		case 'U':                return .ImGuiKey_U
		case 'V':                return .ImGuiKey_V
		case 'W':                return .ImGuiKey_W
		case 'X':                return .ImGuiKey_X
		case 'Y':                return .ImGuiKey_Y
		case 'Z':                return .ImGuiKey_Z
		case win32.VK_F1:        return .ImGuiKey_F1
		case win32.VK_F2:        return .ImGuiKey_F2
		case win32.VK_F3:        return .ImGuiKey_F3
		case win32.VK_F4:        return .ImGuiKey_F4
		case win32.VK_F5:        return .ImGuiKey_F5
		case win32.VK_F6:        return .ImGuiKey_F6
		case win32.VK_F7:        return .ImGuiKey_F7
		case win32.VK_F8:        return .ImGuiKey_F8
		case win32.VK_F9:        return .ImGuiKey_F9
		case win32.VK_F10:       return .ImGuiKey_F10
		case win32.VK_F11:       return .ImGuiKey_F11
		case win32.VK_F12:       return .ImGuiKey_F12
		case win32.VK_F13:       return .ImGuiKey_F13
		case win32.VK_F14:       return .ImGuiKey_F14
		case win32.VK_F15:       return .ImGuiKey_F15
		case win32.VK_F16:       return .ImGuiKey_F16
		case win32.VK_F17:       return .ImGuiKey_F17
		case win32.VK_F18:       return .ImGuiKey_F18
		case win32.VK_F19:       return .ImGuiKey_F19
		case win32.VK_F20:       return .ImGuiKey_F20
		case win32.VK_F21:       return .ImGuiKey_F21
		case win32.VK_F22:       return .ImGuiKey_F22
		case win32.VK_F23:       return .ImGuiKey_F23
		case win32.VK_F24:       return .ImGuiKey_F24
		case win32.VK_BROWSER_BACK:   return .ImGuiKey_AppBack
		case win32.VK_BROWSER_FORWARD:return .ImGuiKey_AppForward
		case: return .ImGuiKey_None
	}
}

// Helper to obtain the source of mouse messages.
// See https://learn.microsoft.com/en-us/windows/win32/tablet/system-events-and-mouse-messages
// Prefer to call this at the top of the message handler to avoid the possibility of other Win32 calls interfering with this.
GetMouseSourceFromMessageExtraInfo :: proc() -> im.ImGuiMouseSource
{
	extra_info := win32_ex.GetMessageExtraInfo()
	if (extra_info & 0xFFFFFF80) == 0xFF515700 { return .ImGuiMouseSource_Pen }
	if (extra_info & 0xFFFFFF80) == 0xFF515780 { return .ImGuiMouseSource_TouchScreen }
	return .ImGuiMouseSource_Mouse
}

// Win32 message handler (process Win32 mouse/keyboard inputs, etc.)
// Call from your application's message handler. Keep calling your message handler unless this function returns TRUE.
// When implementing your own backend, you can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if Dear ImGui wants to use your inputs.
// - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application, or clear/overwrite your copy of the mouse data.
// - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application, or clear/overwrite your copy of the keyboard data.
// Generally you may always pass all inputs to Dear ImGui, and hide them from your application based on those two flags.
// PS: We treat DBLCLK messages as regular mouse down messages, so this code will work on windows classes that have the CS_DBLCLKS flag set. Our own example app code doesn't set this flag.

// Copy either line into your .cpp file to forward declare the function:
// Use ImGui::GetCurrentContext()
WndProcHandler :: proc(hwnd : win32.HWND, msg : win32.UINT, wparam : win32.WPARAM, lparam : win32.LPARAM) -> win32.LRESULT
{
	// Most backends don't have silent checks like this one, but we need it because WndProc are called early in CreateWindow().
	// We silently allow both context or just only backend data to be nullptr.
	if im.GetCurrentContext() == nil { return 0 }
	return WndProcHandlerEx(hwnd, msg, wparam, lparam, im.GetIO())
}

// Doesn't use ImGui::GetCurrentContext()
// This version is in theory thread-safe in the sense that no path should access ImGui::GetCurrentContext().
WndProcHandlerEx :: proc(hwnd : win32.HWND, msg : win32.UINT, wParam : win32.WPARAM, lParam : win32.LPARAM, io : ^im.ImGuiIO) -> win32.LRESULT
{
	bd : ^Data = GetBackendData(io)
	if bd == nil { return 0 }
	switch msg {
		case win32.WM_MOUSEMOVE:
			fallthrough
		case win32.WM_NCMOUSEMOVE:
			{
			// We need to call TrackMouseEvent in order to receive win32.WM_MOUSELEAVE events
			mouse_source := GetMouseSourceFromMessageExtraInfo()
			area : i32 = (msg == win32.WM_MOUSEMOVE) ? 1 : 2
			bd.MouseHwnd = hwnd
			if bd.MouseTrackedArea != area {
				tme_cancel : win32.TRACKMOUSEEVENT = {size_of(win32.TRACKMOUSEEVENT), win32.TME_CANCEL, hwnd, 0}
				tme_track : win32.TRACKMOUSEEVENT = {size_of(win32.TRACKMOUSEEVENT), cast(win32.DWORD) ((area == 2) ? (win32.TME_LEAVE | win32.TME_NONCLIENT) : win32.TME_LEAVE), hwnd, 0}
				if bd.MouseTrackedArea != 0 { win32.TrackMouseEvent(&tme_cancel) }
				win32.TrackMouseEvent(&tme_track)
				bd.MouseTrackedArea = area
			}
			mouse_pos : win32.POINT = {cast(win32.LONG) win32.GET_X_LPARAM(lParam), cast(win32.LONG) win32.GET_Y_LPARAM(lParam)}
			want_absolute_pos : bool = (io.ConfigFlags & im.ImGuiConfigFlags_.ImGuiConfigFlags_ViewportsEnable) != {}
			if msg == win32.WM_MOUSEMOVE && want_absolute_pos {
				// win32.WM_MOUSEMOVE are client-relative coordinates.
				win32.ClientToScreen(hwnd, &mouse_pos)
			}
			if msg == win32.WM_NCMOUSEMOVE && !want_absolute_pos {
				// win32.WM_NCMOUSEMOVE are absolute coordinates.
				win32.ScreenToClient(hwnd, &mouse_pos)
			}
			im.AddMouseSourceEvent(io, mouse_source)
			im.AddMousePosEvent(io, cast(f32) mouse_pos.x, cast(f32) mouse_pos.y)
			return 0
			}
			fallthrough
		case win32.WM_MOUSELEAVE:
			fallthrough
		case win32.WM_NCMOUSELEAVE:
			{
			area : i32 = (msg == win32.WM_MOUSELEAVE) ? 1 : 2
			if bd.MouseTrackedArea == area {
				if bd.MouseHwnd == hwnd { bd.MouseHwnd = nil }
				bd.MouseTrackedArea = 0
				im.AddMousePosEvent(io, -max(f32), -max(f32))
			}
			return 0
			}
			fallthrough
		case win32.WM_DESTROY:
			if bd.MouseHwnd == hwnd && bd.MouseTrackedArea != 0 {
				tme_cancel : win32.TRACKMOUSEEVENT = {size_of(win32.TRACKMOUSEEVENT), win32.TME_CANCEL, hwnd, 0}
				win32.TrackMouseEvent(&tme_cancel)
				bd.MouseHwnd = nil
				bd.MouseTrackedArea = 0
				im.AddMousePosEvent(io, -max(f32), -max(f32))
			}
			return 0
		case win32.WM_LBUTTONDOWN: fallthrough
		case win32.WM_LBUTTONDBLCLK: fallthrough
		case win32.WM_RBUTTONDOWN: fallthrough
		case win32.WM_RBUTTONDBLCLK: fallthrough
		case win32.WM_MBUTTONDOWN: fallthrough
		case win32.WM_MBUTTONDBLCLK: fallthrough
		case win32.WM_XBUTTONDOWN: fallthrough
		case win32.WM_XBUTTONDBLCLK:
			{
			mouse_source := GetMouseSourceFromMessageExtraInfo()
			button : i32 = 0
			if msg == win32.WM_LBUTTONDOWN || msg == win32.WM_LBUTTONDBLCLK { button = 0 }
			if msg == win32.WM_RBUTTONDOWN || msg == win32.WM_RBUTTONDBLCLK { button = 1 }
			if msg == win32.WM_MBUTTONDOWN || msg == win32.WM_MBUTTONDBLCLK { button = 2 }
			if msg == win32.WM_XBUTTONDOWN || msg == win32.WM_XBUTTONDBLCLK { button = (win32.GET_XBUTTON_WPARAM(wParam) == win32.XBUTTON1) ? 3 : 4 }
			if bd.MouseButtonsDown == 0 && win32.GetCapture() == nil {
				// Allow us to read mouse coordinates when dragging mouse outside of our window bounds.
				win32.SetCapture(hwnd)
			}
			bd.MouseButtonsDown |= 1 << u32(button)
			im.AddMouseSourceEvent(io, mouse_source)
			im.AddMouseButtonEvent(io, im.ImGuiMouseButton(button), true)
			return 0
			}
			fallthrough
		case win32.WM_LBUTTONUP:
			fallthrough
		case win32.WM_RBUTTONUP:
			fallthrough
		case win32.WM_MBUTTONUP:
			fallthrough
		case win32.WM_XBUTTONUP:
			{
			mouse_source := GetMouseSourceFromMessageExtraInfo()
			button : i32 = 0
			if msg == win32.WM_LBUTTONUP { button = 0 }
			if msg == win32.WM_RBUTTONUP { button = 1 }
			if msg == win32.WM_MBUTTONUP { button = 2 }
			if msg == win32.WM_XBUTTONUP { button = (win32.GET_XBUTTON_WPARAM(wParam) == win32.XBUTTON1) ? 3 : 4 }
			bd.MouseButtonsDown &= ~(1 << u32(button))
			if bd.MouseButtonsDown == 0 && win32.GetCapture() == hwnd { win32.ReleaseCapture() }
			im.AddMouseSourceEvent(io, mouse_source)
			im.AddMouseButtonEvent(io, im.ImGuiMouseButton(button), false)
			return 0
			}
			fallthrough
		case win32.WM_MOUSEWHEEL:
			im.AddMouseWheelEvent(io, 0.0, cast(f32) win32.GET_WHEEL_DELTA_WPARAM(wParam) / cast(f32) win32.WHEEL_DELTA)
			return 0
		case win32.WM_MOUSEHWHEEL:
			im.AddMouseWheelEvent(io, -cast(f32) win32.GET_WHEEL_DELTA_WPARAM(wParam) / cast(f32) win32.WHEEL_DELTA, 0.0)
			return 0
		case win32.WM_KEYDOWN:
			fallthrough
		case win32.WM_KEYUP:
			fallthrough
		case win32.WM_SYSKEYDOWN:
			fallthrough
		case win32.WM_SYSKEYUP:
			{
			is_key_down : bool = (msg == win32.WM_KEYDOWN || msg == win32.WM_SYSKEYDOWN)
			if wParam < 256 {
				// Submit modifiers
				UpdateKeyModifiers(io)

				// Obtain virtual key code and convert to ImGuiKey
				key := KeyEventToImGuiKey(wParam, lParam)
				vk : i32 = cast(i32) wParam
				scancode : i32 = cast(i32) win32.LOBYTE(win32.HIWORD(lParam))

				// Special behavior for win32.VK_SNAPSHOT / ImGuiKey_PrintScreen as Windows doesn't emit the key down event.
				if key == .ImGuiKey_PrintScreen && !is_key_down { AddKeyEvent(io, key, true, vk, scancode) }

				// Submit key event
				if key != .ImGuiKey_None { AddKeyEvent(io, key, is_key_down, vk, scancode) }

				// Submit individual left/right modifier events
				if vk == win32.VK_SHIFT {
					// Important: Shift keys tend to get stuck when pressed together, missing key-up events are corrected in ProcessKeyEventsWorkarounds()
					if IsVkDown(win32.VK_LSHIFT) == is_key_down { AddKeyEvent(io, .ImGuiKey_LeftShift, is_key_down, win32.VK_LSHIFT, scancode) }
					if IsVkDown(win32.VK_RSHIFT) == is_key_down { AddKeyEvent(io, .ImGuiKey_RightShift, is_key_down, win32.VK_RSHIFT, scancode) }
				}
				else if vk == win32.VK_CONTROL {
					if IsVkDown(win32.VK_LCONTROL) == is_key_down { AddKeyEvent(io, .ImGuiKey_LeftCtrl, is_key_down, win32.VK_LCONTROL, scancode) }
					if IsVkDown(win32.VK_RCONTROL) == is_key_down { AddKeyEvent(io, .ImGuiKey_RightCtrl, is_key_down, win32.VK_RCONTROL, scancode) }
				}
				else if vk == win32.VK_MENU {
					if IsVkDown(win32.VK_LMENU) == is_key_down { AddKeyEvent(io, .ImGuiKey_LeftAlt, is_key_down, win32.VK_LMENU, scancode) }
					if IsVkDown(win32.VK_RMENU) == is_key_down { AddKeyEvent(io, .ImGuiKey_RightAlt, is_key_down, win32.VK_RMENU, scancode) }
				}
			}
			return 0
			}
		case win32.WM_SETFOCUS:
			fallthrough
		case win32.WM_KILLFOCUS:
			im.AddFocusEvent(io, msg == win32.WM_SETFOCUS)
			return 0
		case win32.WM_INPUTLANGCHANGE:
			UpdateKeyboardCodePage(io)
			return 0
		case win32.WM_CHAR:
			if win32_ex.IsWindowUnicode(hwnd) != {} {
				// You can also use ToAscii()+GetKeyboardState() to retrieve characters.
				if wParam > 0 && wParam < 0x10000 { im.AddInputCharacterUTF16(io, cast(u16) wParam) }
			}
			else {
				wch : win32.wchar_t = 0
				wParam := wParam
				win32.MultiByteToWideChar(bd.KeyboardCodePage, win32_ex.MB_PRECOMPOSED, cast(^u8) &wParam, 1, &wch, 1)
				im.AddInputCharacter(io, u32(wch))
			}
			return 0
		case win32.WM_SETCURSOR:
			// This is required to restore cursor when transitioning from e.g resize borders to client area.
			if win32.LOWORD(lParam) == win32.HTCLIENT && UpdateMouseCursor(io, bd.LastMouseCursor) { return 1 }
			return 0
		case win32.WM_DEVICECHANGE:
			when ! IMGUI_IMPL_WIN32_DISABLE_GAMEPAD { /* @gen ifndef */
			if cast(win32.UINT) wParam == win32_ex.DBT_DEVNODES_CHANGED { bd.WantUpdateHasGamepad = true }
			} // preproc endif
			return 0
		case win32.WM_DISPLAYCHANGE:
			bd.WantUpdateMonitors = true
			return 0
	}
	return 0
}


//--------------------------------------------------------------------------------------------------------
// DPI-related helpers (optional)
//--------------------------------------------------------------------------------------------------------
// - Use to enable DPI awareness without having to create an application manifest.
// - Your own app may already do this via a manifest or explicit calls. This is mostly useful for our examples/ apps.
// - In theory we could call simple functions from Windows SDK such as SetProcessDPIAware(), SetProcessDpiAwareness(), etc.
//   but most of the functions provided by Microsoft require Windows 8.1/10+ SDK at compile time and Windows 8/10+ at runtime,
//   neither we want to require the user to have. So we dynamically select and load those functions to avoid dependencies.
//---------------------------------------------------------------------------------------------------------
// This is the scheme successfully used by GLFW (from which we borrowed some of the code) and other apps aiming to be highly portable.
// EnableDpiAwareness() is just a helper called by main.cpp, we don't call it automatically.
// If you are trying to implement your own backend for your own engine, you may ignore that noise.
//---------------------------------------------------------------------------------------------------------

// Perform our own check with RtlVerifyVersionInfo() instead of using functions from <VersionHelpers.h> as they
// require a manifest to be functional for checks above 8.1. See https://github.com/ocornut/imgui/issues/4200
_IsWindowsVersionOrGreater :: proc "contextless"(major : win32.WORD, minor : win32.WORD, _ : win32.WORD) -> bool
{
	PFN_RtlVerifyVersionInfo :: proc "system" (_ : ^win32.OSVERSIONINFOEXW, _ : win32.ULONG, _ : win32.ULONGLONG) -> win32.LONG
	RtlVerifyVersionInfoFn : PFN_RtlVerifyVersionInfo = nil
	if RtlVerifyVersionInfoFn == nil { if ntdllModule : = win32.GetModuleHandleA("ntdll.dll"); ntdllModule != nil { RtlVerifyVersionInfoFn = cast(PFN_RtlVerifyVersionInfo) win32.GetProcAddress(ntdllModule, "RtlVerifyVersionInfo") } }
	if RtlVerifyVersionInfoFn == nil { return false }

	versionInfo : win32_ex.RTL_OSVERSIONINFOEXW = {}
	conditionMask : win32.ULONGLONG = 0
	versionInfo.dwOSVersionInfoSize = size_of(win32_ex.RTL_OSVERSIONINFOEXW)
	versionInfo.dwMajorVersion = win32.DWORD(major)
	versionInfo.dwMinorVersion = win32.DWORD(minor)
	win32_ex.VER_SET_CONDITION(&conditionMask, win32_ex.VER_MAJORVERSION, win32_ex.VER_GREATER_EQUAL)
	win32_ex.VER_SET_CONDITION(&conditionMask, win32_ex.VER_MINORVERSION, win32_ex.VER_GREATER_EQUAL)
	return (RtlVerifyVersionInfoFn(&versionInfo, win32_ex.VER_MAJORVERSION | win32_ex.VER_MINORVERSION, conditionMask) == {})
}

_IsWindowsVistaOrGreater :: #force_inline proc "contextless" () -> bool
{
	return _IsWindowsVersionOrGreater(win32.WORD(win32.HIBYTE(0x0600)), win32.WORD(win32.LOBYTE(0x0600)), 0)// _WIN32_WINNT_VISTA
}

_IsWindows8OrGreater :: #force_inline proc "contextless" () -> bool
{
	return _IsWindowsVersionOrGreater(win32.WORD(win32.HIBYTE(0x0602)), win32.WORD(win32.LOBYTE(0x0602)), 0)// _WIN32_WINNT_WIN8
}

_IsWindows8Point1OrGreater :: #force_inline proc "contextless" () -> bool
{
	return _IsWindowsVersionOrGreater(win32.WORD(win32.HIBYTE(0x0603)), win32.WORD(win32.LOBYTE(0x0603)), 0)// _WIN32_WINNT_WINBLUE
}

_IsWindows10OrGreater :: #force_inline proc "contextless" () -> bool
{
	return _IsWindowsVersionOrGreater(win32.WORD(win32.HIBYTE(0x0A00)), win32.WORD(win32.LOBYTE(0x0A00)), 0)// _WIN32_WINNT_WINTHRESHOLD / _WIN32_WINNT_WIN10
}


PROCESS_DPI_AWARENESS :: enum i32 { PROCESS_DPI_UNAWARE = 0, PROCESS_SYSTEM_DPI_AWARE = 1, PROCESS_PER_MONITOR_DPI_AWARE = 2, }
MONITOR_DPI_TYPE :: enum i32 { MDT_EFFECTIVE_DPI = 0, MDT_ANGULAR_DPI = 1, MDT_RAW_DPI = 2, MDT_DEFAULT = MDT_EFFECTIVE_DPI, }
DPI_AWARENESS_CONTEXT :: distinct win32.HANDLE
DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE :: DPI_AWARENESS_CONTEXT(transmute(uintptr)(int(-3)))
DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 :: DPI_AWARENESS_CONTEXT(transmute(uintptr)(int(-4)))
PFN_SetProcessDpiAwareness :: proc "system" (_ : PROCESS_DPI_AWARENESS) -> win32.HRESULT// Shcore.lib + dll, Windows 8.1+
PFN_GetDpiForMonitor :: proc "system" (_ : win32.HMONITOR, _ : MONITOR_DPI_TYPE, _ : ^win32.UINT, _ : ^win32.UINT) -> win32.HRESULT// Shcore.lib + dll, Windows 8.1+
PFN_SetThreadDpiAwarenessContext :: proc "system" (_ : DPI_AWARENESS_CONTEXT) -> DPI_AWARENESS_CONTEXT// User32.lib + dll, Windows 10 v1607+ (Creators Update)

// Win32 message handler your application need to call.
// - Intentionally commented out in a '#if 0' block to avoid dragging dependencies on <windows.h> from this helper.
// - You should COPY the line below into your .cpp code to forward declare the function and then you can call it.
// - Call from your application's message handler. Keep calling your message handler unless this function returns TRUE.



// DPI-related helpers (optional)
// - Use to enable DPI awareness without having to create an application manifest.
// - Your own app may already do this via a manifest or explicit calls. This is mostly useful for our examples/ apps.
// - In theory we could call simple functions from Windows SDK such as SetProcessDPIAware(), SetProcessDpiAwareness(), etc.
//   but most of the functions provided by Microsoft require Windows 8.1/10+ SDK at compile time and Windows 8/10+ at runtime,
//   neither we want to require the user to have. So we dynamically select and load those functions to avoid dependencies.
// Helper function to enable DPI awareness without setting up a manifest
EnableDpiAwareness :: proc()
{
	// Make sure monitors will be updated with latest correct scaling
	if bd : ^Data = GetBackendData(); bd != nil { bd.WantUpdateMonitors = true }

	if _IsWindows10OrGreater() {
		user32_dll := win32.LoadLibraryW("user32.dll"); // Reference counted per-process
		if SetThreadDpiAwarenessContextFn := cast(PFN_SetThreadDpiAwarenessContext) win32.GetProcAddress(user32_dll, "SetThreadDpiAwarenessContext"); SetThreadDpiAwarenessContextFn != nil {
			SetThreadDpiAwarenessContextFn(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)
			return
		}
	}
	if _IsWindows8Point1OrGreater() {
		shcore_dll := win32.LoadLibraryW("shcore.dll"); // Reference counted per-process
		if SetProcessDpiAwarenessFn := cast(PFN_SetProcessDpiAwareness) win32.GetProcAddress(shcore_dll, "SetProcessDpiAwareness"); SetProcessDpiAwarenessFn != nil {
			SetProcessDpiAwarenessFn(.PROCESS_PER_MONITOR_DPI_AWARE)
			return
		}
	}
	//when win32._WIN32_WINNT >= 0x0600 {
	win32.SetProcessDPIAware()
	//} // preproc endif
}

// win32.HMONITOR monitor
GetDpiScaleForMonitor :: proc(monitor : rawptr) -> f32
{
	xdpi : win32.UINT = 96; ydpi : win32.UINT = 96
	if _IsWindows8Point1OrGreater() {
		shcore_dll := win32.LoadLibraryW("shcore.dll"); // Reference counted per-process
		GetDpiForMonitorFn : PFN_GetDpiForMonitor = nil
		if GetDpiForMonitorFn == nil && shcore_dll != nil { GetDpiForMonitorFn = cast(PFN_GetDpiForMonitor) win32.GetProcAddress(shcore_dll, "GetDpiForMonitor") }
		if GetDpiForMonitorFn != nil {
			GetDpiForMonitorFn(cast(win32.HMONITOR) monitor, .MDT_EFFECTIVE_DPI, &xdpi, &ydpi)
			im.IM_ASSERT(xdpi == ydpi); // Please contact me if you hit this assert!
			return f32(xdpi) / 96.0
		}
	}
	when ! NOGDI { /* @gen ifndef */
	dc : win32.HDC = win32.GetDC(nil)
	xdpi = cast(u32) win32.GetDeviceCaps(dc, win32_ex.LOGPIXELSX)
	ydpi = cast(u32) win32.GetDeviceCaps(dc, win32_ex.LOGPIXELSY)
	im.IM_ASSERT(xdpi == ydpi); // Please contact me if you hit this assert!
	win32.ReleaseDC(nil, dc)
	} // preproc endif
	return f32(xdpi) / 96.0
}

// win32.HWND win32.HWND
GetDpiScaleForHwnd :: proc(hwnd : rawptr) -> f32
{
	monitor := win32.MonitorFromWindow(cast(win32.HWND) hwnd, .MONITOR_DEFAULTTONEAREST)
	return GetDpiScaleForMonitor(monitor)
}

//---------------------------------------------------------------------------------------------------------
// Transparency related helpers (optional)
//--------------------------------------------------------------------------------------------------------

// Transparency related helpers (optional) [experimental]
// - Use to enable alpha compositing transparency with the desktop.
// - Use together with e.g. clearing your framebuffer with zero-alpha.
// win32.HWND win32.HWND
// [experimental]
// Borrowed from GLFW's function updateFramebufferTransparency() in src/win32_window.c
// (the Dwm* functions are Vista era functions but we are borrowing logic from GLFW)
EnableAlphaCompositing :: proc(hwnd : rawptr)
{
	if !_IsWindowsVistaOrGreater() { return }

	composition : win32.BOOL
	if win32.FAILED(win32.DwmIsCompositionEnabled(&composition)) || composition == {} { return }

	opaque : win32.BOOL
	color : win32.DWORD
	if _IsWindows8OrGreater() || (win32.SUCCEEDED(win32_ex.DwmGetColorizationColor(&color, &opaque)) && opaque == {}) {
		region := win32_ex.CreateRectRgn(0, 0, -1, -1)
		bb : win32_ex.DWM_BLURBEHIND = {}
		bb.dwFlags = { .ENABLE, .BLURREGION }
		bb.hRgnBlur = region
		bb.fEnable =  win32.TRUE
		win32_ex.DwmEnableBlurBehindWindow(cast(win32.HWND) hwnd, &bb)
		win32.DeleteObject(cast(win32.HGDIOBJ) region)
	}
	else {
		bb : win32_ex.DWM_BLURBEHIND = {}
		bb.dwFlags = { .ENABLE }
		win32_ex.DwmEnableBlurBehindWindow(cast(win32.HWND) hwnd, &bb)
	}
}

//---------------------------------------------------------------------------------------------------------
// MULTI-VIEWPORT / PLATFORM INTERFACE SUPPORT
// This is an _advanced_ and _optional_ feature, allowing the backend to create and handle multiple viewports simultaneously.
// If you are new to dear imgui or creating a new binding for dear imgui, it is recommended that you completely ignore this section first..
//--------------------------------------------------------------------------------------------------------

// Helper structure we store in the void* RendererUserData field of each im.ImGuiViewport to easily retrieve our backend data.
ViewportData :: struct {
	Hwnd : win32.HWND,
	HwndParent : win32.HWND,
	HwndOwned : bool,
	DwStyle : win32.DWORD,
	DwExStyle : win32.DWORD,
}

ViewportData_deinit :: proc(this : ^ViewportData) { im.IM_ASSERT(this.Hwnd == nil) }

ViewportData_init :: proc(this : ^ViewportData)
{
	this.HwndParent = nil; this.Hwnd = this.HwndParent; this.HwndOwned = false; this.DwExStyle = 0; this.DwStyle = this.DwExStyle
}

GetWin32StyleFromViewportFlags :: proc(flags : im.ImGuiViewportFlags, out_style : ^win32.DWORD, out_ex_style : ^win32.DWORD)
{
	if (flags & im.ImGuiViewportFlags_.ImGuiViewportFlags_NoDecoration) != {} { out_style^ = win32.WS_POPUP }
	else { out_style^ = win32.WS_OVERLAPPEDWINDOW }

	if (flags & im.ImGuiViewportFlags_.ImGuiViewportFlags_NoTaskBarIcon) != {} { out_ex_style^ = win32.WS_EX_TOOLWINDOW }
	else { out_ex_style^ = win32.WS_EX_APPWINDOW }

	if (flags & im.ImGuiViewportFlags_.ImGuiViewportFlags_TopMost) != {} { out_ex_style^ |= win32.WS_EX_TOPMOST }
}

GetHwndFromViewportID :: proc(viewport_id : im.ImGuiID) -> win32.HWND
{
	if viewport_id != 0 { if viewport := im.FindViewportByID(viewport_id); viewport != nil { return cast(win32.HWND) viewport.PlatformHandle } }
	return nil
}

CreateWindow :: proc(viewport : ^im.ImGuiViewport)
{
	vd := im.IM_NEW_MEM(ViewportData); ViewportData_init(vd)
	viewport.PlatformUserData = vd

	// Select style and parent window
	GetWin32StyleFromViewportFlags(viewport.Flags, &vd.DwStyle, &vd.DwExStyle)
	vd.HwndParent = GetHwndFromViewportID(viewport.ParentViewportId)

	// Create window
	rect : win32.RECT = {cast(win32.LONG) viewport.Pos.x, cast(win32.LONG) viewport.Pos.y, cast(win32.LONG) (viewport.Pos.x + viewport.Size.x), cast(win32.LONG) (viewport.Pos.y + viewport.Size.y)}
	win32.AdjustWindowRectEx(&rect, vd.DwStyle, win32.FALSE, vd.DwExStyle)
	vd.Hwnd = win32.CreateWindowExW(vd.DwExStyle, "ImGui Platform", "Untitled", vd.DwStyle, rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top, vd.HwndParent, nil, cast(win32.HANDLE) win32.GetModuleHandleW(nil), nil); // Owner window, Menu, Instance, Param
	vd.HwndOwned = true
	viewport.PlatformRequestResize = false
	viewport.PlatformHandleRaw = vd.Hwnd; viewport.PlatformHandle = viewport.PlatformHandleRaw

	// Secondary viewports store their imgui context
	win32.SetPropW(vd.Hwnd, "IMGUI_CONTEXT", cast(win32.HANDLE) im.GetCurrentContext())
}

DestroyWindow :: proc(viewport : ^im.ImGuiViewport)
{
	bd : ^Data = GetBackendData()
	if vd : ^ViewportData = cast(^ViewportData) viewport.PlatformUserData; vd != nil {
		if win32.GetCapture() == vd.Hwnd {
			// Transfer capture so if we started dragging from a window that later disappears, we'll still receive the MOUSEUP event.
			win32.ReleaseCapture()
			win32.SetCapture(bd.hWnd)
		}
		if vd.Hwnd != {} && vd.HwndOwned { win32.DestroyWindow(vd.Hwnd) }
		vd.Hwnd = nil
		ViewportData_deinit(vd); im.IM_FREE(vd)
	}
	viewport.PlatformHandle = nil; viewport.PlatformUserData = viewport.PlatformHandle
}

ShowWindow :: proc(viewport : ^im.ImGuiViewport)
{
	vd : ^ViewportData = cast(^ViewportData) viewport.PlatformUserData
	im.IM_ASSERT(vd.Hwnd != {})

	// ShowParent() also brings parent to front, which is not always desirable,
	// so we temporarily disable parenting. (#7354)
	if vd.HwndParent != nil { win32.SetWindowLongPtrW(vd.Hwnd, win32.GWLP_HWNDPARENT, cast(win32.LONG_PTR) 0) }

	if (viewport.Flags & im.ImGuiViewportFlags_.ImGuiViewportFlags_NoFocusOnAppearing) != {} { win32.ShowWindow(vd.Hwnd, win32.SW_SHOWNA) }
	else { win32.ShowWindow(vd.Hwnd, win32.SW_SHOW) }

	// Restore
	if vd.HwndParent != nil { win32.SetWindowLongPtrW(vd.Hwnd, win32.GWLP_HWNDPARENT, cast(win32.LONG_PTR) uintptr(vd.HwndParent)) }
}

UpdateWindow :: proc(viewport : ^im.ImGuiViewport)
{
	vd : ^ViewportData = cast(^ViewportData) viewport.PlatformUserData
	im.IM_ASSERT(vd.Hwnd != {})

	// Update Win32 parent if it changed _after_ creation
	// Unlike style settings derived from configuration flags, this is more likely to change for advanced apps that are manipulating ParentViewportID manually.
	new_parent : win32.HWND = GetHwndFromViewportID(viewport.ParentViewportId)
	if new_parent != vd.HwndParent {
		// Win32 windows can either have a "Parent" (for win32.WS_CHILD window) or an "Owner" (which among other thing keeps window above its owner).
		// Our Dear Imgui-side concept of parenting only mostly care about what Win32 call "Owner".
		// The parent parameter of CreateWindowEx() sets up Parent OR Owner depending on win32.WS_CHILD flag. In our case an Owner as we never use win32.WS_CHILD.
		// Calling ::SetParent() here would be incorrect: it will create a full child relation, alter coordinate system and clipping.
		// Calling ::SetWindowLongPtr() with GWLP_HWNDPARENT seems correct although poorly documented.
		// https://devblogs.microsoft.com/oldnewthing/20100315-00/?p=14613
		vd.HwndParent = new_parent
		win32.SetWindowLongPtrW(vd.Hwnd, win32.GWLP_HWNDPARENT, cast(win32.LONG_PTR) uintptr(vd.HwndParent))
	}

	// (Optional) Update Win32 style if it changed _after_ creation.
	// Generally they won't change unless configuration flags are changed, but advanced uses (such as manually rewriting viewport flags) make this useful.
	new_style : win32.DWORD
	new_ex_style : win32.DWORD
	GetWin32StyleFromViewportFlags(viewport.Flags, &new_style, &new_ex_style)

	// Only reapply the flags that have been changed from our win32.POINT of view (as other flags are being modified by Windows)
	if vd.DwStyle != new_style || vd.DwExStyle != new_ex_style {
		// (Optional) Update TopMost state if it changed _after_ creation
		top_most_changed : bool = (vd.DwExStyle & win32.WS_EX_TOPMOST) != (new_ex_style & win32.WS_EX_TOPMOST)
		insert_after : win32.HWND = top_most_changed ? ((viewport.Flags & im.ImGuiViewportFlags_.ImGuiViewportFlags_TopMost) != {} ? win32.HWND_TOPMOST : win32.HWND_NOTOPMOST) : {}
		swp_flag : win32.UINT = top_most_changed ? 0 : win32.SWP_NOZORDER

		// Apply flags and position (since it is affected by flags)
		vd.DwStyle = new_style
		vd.DwExStyle = new_ex_style
		win32.SetWindowLongW(vd.Hwnd, win32.GWL_STYLE, cast(win32.LONG) vd.DwStyle)
		win32.SetWindowLongW(vd.Hwnd, win32.GWL_EXSTYLE, cast(win32.LONG) vd.DwExStyle)
		rect : win32.RECT = {cast(win32.LONG) viewport.Pos.x, cast(win32.LONG) viewport.Pos.y, cast(win32.LONG) (viewport.Pos.x + viewport.Size.x), cast(win32.LONG) (viewport.Pos.y + viewport.Size.y)}
		win32.AdjustWindowRectEx(&rect, vd.DwStyle, win32.FALSE, vd.DwExStyle); // Client to Screen
		win32.SetWindowPos(vd.Hwnd, insert_after, rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top, swp_flag | win32.SWP_NOACTIVATE | win32.SWP_FRAMECHANGED)
		win32.ShowWindow(vd.Hwnd, win32.SW_SHOWNA); // This is necessary when we alter the style
		viewport.PlatformRequestResize = true; viewport.PlatformRequestMove = viewport.PlatformRequestResize
	}
}

GetWindowPos :: proc (viewport : ^im.ImGuiViewport) -> im.ImVec2
{
	vd : ^ViewportData = cast(^ViewportData) viewport.PlatformUserData
	im.IM_ASSERT(vd.Hwnd != {})
	pos : win32.POINT = {0, 0}
	win32.ClientToScreen(vd.Hwnd, &pos)
	return im.ImVec2{cast(f32) pos.x, cast(f32) pos.y}
}

UpdateWin32StyleFromWindow :: proc(viewport : ^im.ImGuiViewport)
{
	vd : ^ViewportData = cast(^ViewportData) viewport.PlatformUserData
	vd.DwStyle = cast(u32)win32.GetWindowLongW(vd.Hwnd, win32.GWL_STYLE)
	vd.DwExStyle = cast(u32)win32.GetWindowLongW(vd.Hwnd, win32.GWL_EXSTYLE)
}

SetWindowPos :: proc(viewport : ^im.ImGuiViewport, pos : im.ImVec2)
{
	vd : ^ViewportData = cast(^ViewportData) viewport.PlatformUserData
	im.IM_ASSERT(vd.Hwnd != {})
	rect : win32.RECT = {cast(win32.LONG) pos.x, cast(win32.LONG) pos.y, cast(win32.LONG) pos.x, cast(win32.LONG) pos.y}
	if (viewport.Flags & im.ImGuiViewportFlags_.ImGuiViewportFlags_OwnedByApp) != {} {
		// Not our window, poll style before using
		UpdateWin32StyleFromWindow(viewport)
	}
	win32.AdjustWindowRectEx(&rect, vd.DwStyle, win32.FALSE, vd.DwExStyle)
	win32.SetWindowPos(vd.Hwnd, nil, rect.left, rect.top, 0, 0, win32.SWP_NOZORDER | win32.SWP_NOSIZE | win32.SWP_NOACTIVATE)
}

GetWindowSize :: proc(viewport : ^im.ImGuiViewport) -> im.ImVec2
{
	vd : ^ViewportData = cast(^ViewportData) viewport.PlatformUserData
	im.IM_ASSERT(vd.Hwnd != {})
	rect : win32.RECT
	win32.GetClientRect(vd.Hwnd, &rect)
	return im.ImVec2{f32(rect.right - rect.left), f32(rect.bottom - rect.top)}
}

SetWindowSize :: proc(viewport : ^im.ImGuiViewport, size : im.ImVec2)
{
	vd : ^ViewportData = cast(^ViewportData) viewport.PlatformUserData
	im.IM_ASSERT(vd.Hwnd != {})
	rect : win32.RECT = {0, 0, cast(win32.LONG) size.x, cast(win32.LONG) size.y}
	if (viewport.Flags & im.ImGuiViewportFlags_.ImGuiViewportFlags_OwnedByApp) != {} {
		// Not our window, poll style before using
		UpdateWin32StyleFromWindow(viewport)
	}
	win32.AdjustWindowRectEx(&rect, vd.DwStyle, win32.FALSE, vd.DwExStyle); // Client to Screen
	win32.SetWindowPos(vd.Hwnd, nil, 0, 0, rect.right - rect.left, rect.bottom - rect.top, win32.SWP_NOZORDER | win32.SWP_NOMOVE | win32.SWP_NOACTIVATE)
}

SetWindowFocus :: proc(viewport : ^im.ImGuiViewport)
{
	vd : ^ViewportData = cast(^ViewportData) viewport.PlatformUserData
	im.IM_ASSERT(vd.Hwnd != {})
	win32.BringWindowToTop(vd.Hwnd)
	win32.SetForegroundWindow(vd.Hwnd)
	win32.SetFocus(vd.Hwnd)
}

GetWindowFocus :: proc(viewport : ^im.ImGuiViewport) -> bool
{
	vd : ^ViewportData = cast(^ViewportData) viewport.PlatformUserData
	im.IM_ASSERT(vd.Hwnd != {})
	return win32.GetForegroundWindow() == vd.Hwnd
}

GetWindowMinimized :: proc(viewport : ^im.ImGuiViewport) -> bool
{
	vd : ^ViewportData = cast(^ViewportData) viewport.PlatformUserData
	im.IM_ASSERT(vd.Hwnd != {})
	return win32.IsIconic(vd.Hwnd) != {}
}

SetWindowTitle :: proc(viewport : ^im.ImGuiViewport, title : string)
{
	// ::SetWindowTextA() doesn't properly handle UTF-8 so we explicitely convert our string.
	vd : ^ViewportData = cast(^ViewportData) viewport.PlatformUserData
	im.IM_ASSERT(vd.Hwnd != {})
	n : i32 = win32.MultiByteToWideChar(win32.CP_UTF8, 0, raw_data(title), cast(i32)len(title), nil, 0)
	title_w : im.ImVector(win32.wchar_t)
	im.resize(&title_w, n)
	win32.MultiByteToWideChar(win32.CP_UTF8, 0, raw_data(title), cast(i32)len(title), title_w.Data, n)
	win32.SetWindowTextW(vd.Hwnd, cast(cstring16)title_w.Data)
}

SetWindowAlpha :: proc(viewport : ^im.ImGuiViewport, alpha : f32)
{
	vd : ^ViewportData = cast(^ViewportData) viewport.PlatformUserData
	im.IM_ASSERT(vd.Hwnd != {})
	im.IM_ASSERT(alpha >= 0.0 && alpha <= 1.0)
	if alpha < 1.0 {
		ex_style := win32.GetWindowLongW(vd.Hwnd, win32.GWL_EXSTYLE) | cast(win32.LONG)win32.WS_EX_LAYERED
		win32.SetWindowLongW(vd.Hwnd, win32.GWL_EXSTYLE, ex_style)
		win32.SetLayeredWindowAttributes(vd.Hwnd, 0, cast(win32.BYTE) (255 * alpha), win32_ex.LWA_ALPHA)
	}
	else {
		ex_style := win32.GetWindowLongW(vd.Hwnd, win32.GWL_EXSTYLE) & ~cast(win32.LONG)win32.WS_EX_LAYERED
		win32.SetWindowLongW(vd.Hwnd, win32.GWL_EXSTYLE, ex_style)
	}
}

GetWindowDpiScale :: proc(viewport : ^im.ImGuiViewport) -> f32
{
	vd : ^ViewportData = cast(^ViewportData) viewport.PlatformUserData
	im.IM_ASSERT(vd.Hwnd != {})
	return GetDpiScaleForHwnd(vd.Hwnd)
}

// FIXME-DPI: Testing DPI related ideas
OnChangedViewport :: proc(viewport : ^im.ImGuiViewport)
{
	_ = viewport

}

WndProcHandler_PlatformWindow :: proc "system" (hWnd : win32.HWND, msg : win32.UINT, wparam : win32.WPARAM, lparam : win32.LPARAM) -> win32.LRESULT
{
	// Allow secondary viewport WndProc to be called regardless of current context
	ctx := cast(^im.ImGuiContext) win32.GetPropW(hWnd, "IMGUI_CONTEXT")
	if ctx == nil {
		// unlike WndProcHandler() we are called directly by Windows, we can't just return 0.
		return win32.DefWindowProcW(hWnd, msg, wparam, lparam)
	}

	context = (cast(^runtime.Context)(cast(uintptr) win32.GetClassLongPtrW(hWnd, 0)))^ // TODO(Rennorb) @completeness

	io := im.GetIOEx(ctx)
	platform_io := im.GetPlatformIOEx(ctx)
	result : win32.LRESULT = 0
	if WndProcHandlerEx(hWnd, msg, wparam, lparam, io) != {} { result = 1 }
	else if viewport : ^im.ImGuiViewport = FindViewportByPlatformHandle(platform_io, hWnd); viewport != nil {
		switch msg {
			case win32.WM_CLOSE:
				viewport.PlatformRequestClose = true
				break

			case win32.WM_MOVE:
				viewport.PlatformRequestMove = true
				break

			case win32.WM_SIZE:
				viewport.PlatformRequestResize = true
				break

			case win32.WM_MOUSEACTIVATE:
				if (viewport.Flags & im.ImGuiViewportFlags_.ImGuiViewportFlags_NoFocusOnClick) != {} { result = win32_ex.MA_NOACTIVATE }
				break

			case win32.WM_NCHITTEST:
				// Let mouse pass-through the window. This will allow the backend to call io.AddMouseViewportEvent() correctly. (which is optional).
				// The im.ImGuiViewportFlags_NoInputs flag is set while dragging a viewport, as want to detect the window behind the one we are dragging.
				// If you cannot easily access those viewport flags from your windowing/event code: you may manually synchronize its state e.g. in
				// your main loop after calling UpdatePlatformWindows(). Iterate all viewports/platform windows and pass the flag to your windowing system.
				if (viewport.Flags & im.ImGuiViewportFlags_.ImGuiViewportFlags_NoInputs) != {} { result = win32.HTTRANSPARENT }
				break
		}
	}
	if result == {} { result = win32.DefWindowProcA(hWnd, msg, wparam, lparam) }
	return result
}

InitMultiViewportSupport :: proc(platform_has_own_dc : bool)
{
	wcex : win32.WNDCLASSEXW
	wcex.cbSize = size_of(win32.WNDCLASSEXW)
	wcex.style = win32.CS_HREDRAW | win32.CS_VREDRAW | (platform_has_own_dc ? win32.CS_OWNDC : 0)
	wcex.lpfnWndProc = WndProcHandler_PlatformWindow
	wcex.cbClsExtra = size_of(runtime.Context)
	wcex.cbWndExtra = 0
	wcex.hInstance = cast(win32.HANDLE) win32.GetModuleHandleA(nil)
	wcex.hIcon = nil
	wcex.hCursor = nil
	wcex.hbrBackground = cast(win32.HBRUSH) uintptr(win32.COLOR_BACKGROUND + 1)
	wcex.lpszMenuName = nil
	wcex.lpszClassName = "ImGui Platform"
	wcex.hIconSm = nil
	win32.RegisterClassExW(&wcex)

	UpdateMonitors()

	// Register platform interface (will be coupled with a renderer interface)
	platform_io := im.GetPlatformIO()
	platform_io.Platform_CreateWindow = CreateWindow
	platform_io.Platform_DestroyWindow = DestroyWindow
	platform_io.Platform_ShowWindow = ShowWindow
	platform_io.Platform_SetWindowPos = SetWindowPos
	platform_io.Platform_GetWindowPos = GetWindowPos
	platform_io.Platform_SetWindowSize = SetWindowSize
	platform_io.Platform_GetWindowSize = GetWindowSize
	platform_io.Platform_SetWindowFocus = SetWindowFocus
	platform_io.Platform_GetWindowFocus = GetWindowFocus
	platform_io.Platform_GetWindowMinimized = GetWindowMinimized
	platform_io.Platform_SetWindowTitle = SetWindowTitle
	platform_io.Platform_SetWindowAlpha = SetWindowAlpha
	platform_io.Platform_UpdateWindow = UpdateWindow
	platform_io.Platform_GetWindowDpiScale = GetWindowDpiScale; // FIXME-DPI
	platform_io.Platform_OnChangedViewport = OnChangedViewport; // FIXME-DPI

	// Register main window handle (which is owned by the main application, not by us)
	// This is mostly for simplicity and consistency, so that our code (e.g. mouse handling etc.) can use same logic for main and secondary viewports.
	main_viewport := im.GetMainViewport()
	bd : ^Data = GetBackendData()
	vd := im.IM_NEW_MEM(ViewportData); ViewportData_init(vd)
	vd.Hwnd = bd.hWnd
	vd.HwndOwned = false
	main_viewport.PlatformUserData = vd
}

ShutdownMultiViewportSupport :: proc()
{
	win32.UnregisterClassW("ImGui Platform", cast(win32.HANDLE) win32.GetModuleHandleW(nil))
	im.DestroyPlatformWindows()
}
