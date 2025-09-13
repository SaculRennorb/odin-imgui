package test


//
// shim
//
int :: int
bool :: bool
//
// win32
//
// BEGIN STD SHIM

size_t :: u64
wchar_t :: u16

uint8_t :: u8
uint16_t :: u16
uint32_t :: u32
uint64_t :: u64

int8_t :: i8
int16_t :: i16
int32_t :: i32
int64_t :: i64

// END STD SHIM

// BEGIN STB SHIM

stbrp_coord :: i32

stbrp_rect :: struct {
	id : i32,
	w : stbrp_coord, h : stbrp_coord,
	x : stbrp_coord, y : stbrp_coord,
	was_packed : i32,
}

stbrp_node :: struct {
	x : stbrp_coord, y : stbrp_coord,
	next : ^stbrp_node,
}

stbrp_context :: struct {
	width : i32,
	height : i32,
	align : i32,
	init_mode : i32,
	heuristic : i32,
	num_nodes : i32,
	active_head : ^stbrp_node,
	free_head : ^stbrp_node,
	extra : [2]stbrp_node, // we allocate two extra nodes so optimal user-node-count is 'width' not 'width+2'
}


stbtt_aligned_quad :: struct {
	x0 : f32, y0 : f32, s0 : f32, t0 : f32,
	x1 : f32, y1 : f32, s1 : f32, t1 : f32,
}


stbtt_packedchar :: struct {
	x0 : u16, y0 : u16, x1 : u16, y1 : u16,
	xoff : f32, yoff : f32, xadvance : f32,
	xoff2 : f32, yoff2 : f32,
}

stbtt_pack_range :: struct {
	font_size : f32,
	first_unicode_codepoint_in_range : i32,
	array_of_unicode_codepoints : ^i32,
	num_chars : i32,
	chardata_for_range : ^stbtt_packedchar,
	h_oversample : u8, v_oversample : u8,
}

stbtt__buf :: struct {
	data : ^u8,
	cursor : i32,
	size : i32,
}

stbtt_fontinfo :: struct {
	userdata : rawptr,
	data : ^u8, // pointer to .ttf file
	fontstart : i32, // offset of start of font

	numGlyphs : i32, // number of glyphs, needed for range checking

	loca : i32, head : i32, glyf : i32, hhea : i32, hmtx : i32, kern : i32, gpos : i32, svg : i32, // table locations as offset from start of .ttf
	index_map : i32, // a cmap mapping for our chosen character encoding
	indexToLocFormat : i32, // format needed to map from glyph index to glyph

	cff : stbtt__buf, // cff font data
	charstrings : stbtt__buf, // the charstring index
	gsubrs : stbtt__buf, // global charstring subroutines index
	subrs : stbtt__buf, // private charstring subroutines index
	fontdicts : stbtt__buf, // array of font dicts
	fdselect : stbtt__buf, // map from glyph to fontdict
}

stbtt_pack_context :: struct {
	user_allocator_context : rawptr,
	pack_info : rawptr,
	width : i32,
	height : i32,
	stride_in_bytes : i32,
	padding : i32,
	skip_missing : i32,
	h_oversample : u32, v_oversample : u32,
	pixels : ^u8,
	nodes : rawptr,
}

// need to forward declare some vars
STB_TEXTEDIT_NEWLINE : u8 = '\n'

STB_TEXTEDIT_K_INSERT :: 0
STB_TEXTEDIT_K_TEXTSTART2 :: 0
STB_TEXTEDIT_K_TEXTEND2 :: 0
STB_TEXTEDIT_K_LINESTART2 :: 0
STB_TEXTEDIT_K_LINEEND2 :: 0

STB_TEXTEDIT_K_LEFT :: 0x200000// keyboard input to move cursor left
STB_TEXTEDIT_K_RIGHT :: 0x200001// keyboard input to move cursor right
STB_TEXTEDIT_K_UP :: 0x200002// keyboard input to move cursor up
STB_TEXTEDIT_K_DOWN :: 0x200003// keyboard input to move cursor down
STB_TEXTEDIT_K_LINESTART :: 0x200004// keyboard input to move cursor to start of line
STB_TEXTEDIT_K_LINEEND :: 0x200005// keyboard input to move cursor to end of line
STB_TEXTEDIT_K_TEXTSTART :: 0x200006// keyboard input to move cursor to start of text
STB_TEXTEDIT_K_TEXTEND :: 0x200007// keyboard input to move cursor to end of text
STB_TEXTEDIT_K_DELETE :: 0x200008// keyboard input to delete selection or character under cursor
STB_TEXTEDIT_K_BACKSPACE :: 0x200009// keyboard input to delete selection or character left of cursor
STB_TEXTEDIT_K_UNDO :: 0x20000A// keyboard input to perform undo
STB_TEXTEDIT_K_REDO :: 0x20000B// keyboard input to perform redo
STB_TEXTEDIT_K_WORDLEFT :: 0x20000C// keyboard input to move cursor left one word
STB_TEXTEDIT_K_WORDRIGHT :: 0x20000D// keyboard input to move cursor right one word
STB_TEXTEDIT_K_PGUP :: 0x20000E// keyboard input to move cursor up a page
STB_TEXTEDIT_K_PGDOWN :: 0x20000F// keyboard input to move cursor down a page
STB_TEXTEDIT_K_SHIFT :: 0x400000
// END STB SHIM

// BEGIN WIN32 STRUCT SHIM

FILE :: rawptr
HANDLE :: rawptr
HWND :: HANDLE
WORD :: u16
DWORD :: u32
LONG :: i32
CHAR :: u8
WCHAR :: u16
SHORT :: i16
BYTE :: u8
INT :: i32
UINT :: u32
PUINT :: ^u32
BOOL :: i32
UINT8 :: u8
FLOAT :: f32
LCID :: DWORD
LCTYPE :: DWORD
LPSTR :: ^CHAR
LPCWSTR :: ^WCHAR
LONGLONG :: __int64
LONG_PTR :: __int64
UINT_PTR :: __int64
WPARAM :: UINT_PTR
LPARAM :: LONG_PTR
LRESULT :: LONG_PTR

POINT :: struct {
	x : LONG, y : LONG,
}

RECT :: struct {
	left : LONG, top : LONG, right : LONG, bottom : LONG,
}

COMPOSITIONFORM :: struct {
	dwStyle : DWORD,
	ptCurrentPos : POINT,
	rcArea : RECT,
}

CANDIDATEFORM :: struct {
	dwIndex : DWORD,
	dwStyle : DWORD,
	ptCurrentPos : POINT,
	rcArea : RECT,
}

SORT_DEFAULT :: 0x0
LOCALE_RETURN_NUMBER :: 0x20000000
LOCALE_IDEFAULTANSICODEPAGE :: 0x00001004

CP_ACP :: 0
CP_UTF8 :: 65001

TRUE :: 1
FALSE :: 0

LARGE_INTEGER :: struct #raw_union {
	using _0 : struct {
		LowPart : DWORD,
		HighPart : LONG,
	},
	u : struct {
LowPart : DWORD,
HighPart : LONG,
},
	QuadPart : LONGLONG,
}

IDC_ARROW :: MAKEINTRESOURCE(32512)
IDC_IBEAM :: MAKEINTRESOURCE(32513)
IDC_WAIT :: MAKEINTRESOURCE(32514)
IDC_CROSS :: MAKEINTRESOURCE(32515)
IDC_UPARROW :: MAKEINTRESOURCE(32516)
IDC_SIZE :: MAKEINTRESOURCE(32640)
IDC_ICON :: MAKEINTRESOURCE(32641)
IDC_SIZENWSE :: MAKEINTRESOURCE(32642)
IDC_SIZENESW :: MAKEINTRESOURCE(32643)
IDC_SIZEWE :: MAKEINTRESOURCE(32644)
IDC_SIZENS :: MAKEINTRESOURCE(32645)
IDC_SIZEALL :: MAKEINTRESOURCE(32646)
IDC_NO :: MAKEINTRESOURCE(32648)
IDC_HAND :: MAKEINTRESOURCE(32649)

VK_LSHIFT :: 0xA0
VK_RSHIFT :: 0xA1
VK_LCONTROL :: 0xA2
VK_RCONTROL :: 0xA3
VK_LMENU :: 0xA4
VK_RMENU :: 0xA5

VK_LWIN :: 0x5B
VK_RWIN :: 0x5C
VK_APPS :: 0x5D

VK_SHIFT :: 0x10
VK_CONTROL :: 0x11
VK_MENU :: 0x12
VK_PAUSE :: 0x13
VK_CAPITAL :: 0x14

VK_BACK :: 0x08
VK_TAB :: 0x09

VK_CLEAR :: 0x0C
VK_RETURN :: 0x0D

VK_SPACE :: 0x20
VK_PRIOR :: 0x21
VK_NEXT :: 0x22
VK_END :: 0x23
VK_HOME :: 0x24
VK_LEFT :: 0x25
VK_UP :: 0x26
VK_RIGHT :: 0x27
VK_DOWN :: 0x28
VK_SELECT :: 0x29
VK_PRINT :: 0x2A
VK_EXECUTE :: 0x2B
VK_SNAPSHOT :: 0x2C
VK_INSERT :: 0x2D
VK_DELETE :: 0x2E
VK_HELP :: 0x2F

VK_SHIFT :: 0x10
VK_CONTROL :: 0x11
VK_MENU :: 0x12
VK_PAUSE :: 0x13
VK_CAPITAL :: 0x14

VK_KANA :: 0x15
VK_HANGEUL :: 0x15
VK_HANGUL :: 0x15
VK_IME_ON :: 0x16
VK_JUNJA :: 0x17
VK_FINAL :: 0x18
VK_HANJA :: 0x19
VK_KANJI :: 0x19
VK_IME_OFF :: 0x1A

VK_ESCAPE :: 0x1B

VK_CONVERT :: 0x1C
VK_NONCONVERT :: 0x1D
VK_ACCEPT :: 0x1E
VK_MODECHANGE :: 0x1F

VK_OEM_1 :: 0xBA// ';:' for US
VK_OEM_PLUS :: 0xBB// '+' any country
VK_OEM_COMMA :: 0xBC// ',' any country
VK_OEM_MINUS :: 0xBD// '-' any country
VK_OEM_PERIOD :: 0xBE// '.' any country
VK_OEM_2 :: 0xBF// '/?' for US
VK_OEM_3 :: 0xC0// '`~' for US
VK_OEM_4 :: 0xDB//  '[{' for US
VK_OEM_5 :: 0xDC//  '\|' for US
VK_OEM_6 :: 0xDD//  ']}' for US
VK_OEM_7 :: 0xDE//  ''"' for US
VK_OEM_8 :: 0xDF

VK_NUMLOCK :: 0x90
VK_SCROLL :: 0x91

VK_NUMPAD0 :: 0x60
VK_NUMPAD1 :: 0x61
VK_NUMPAD2 :: 0x62
VK_NUMPAD3 :: 0x63
VK_NUMPAD4 :: 0x64
VK_NUMPAD5 :: 0x65
VK_NUMPAD6 :: 0x66
VK_NUMPAD7 :: 0x67
VK_NUMPAD8 :: 0x68
VK_NUMPAD9 :: 0x69
VK_MULTIPLY :: 0x6A
VK_ADD :: 0x6B
VK_SEPARATOR :: 0x6C
VK_SUBTRACT :: 0x6D
VK_DECIMAL :: 0x6E
VK_DIVIDE :: 0x6F
VK_F1 :: 0x70
VK_F2 :: 0x71
VK_F3 :: 0x72
VK_F4 :: 0x73
VK_F5 :: 0x74
VK_F6 :: 0x75
VK_F7 :: 0x76
VK_F8 :: 0x77
VK_F9 :: 0x78
VK_F10 :: 0x79
VK_F11 :: 0x7A
VK_F12 :: 0x7B
VK_F13 :: 0x7C
VK_F14 :: 0x7D
VK_F15 :: 0x7E
VK_F16 :: 0x7F
VK_F17 :: 0x80
VK_F18 :: 0x81
VK_F19 :: 0x82
VK_F20 :: 0x83
VK_F21 :: 0x84
VK_F22 :: 0x85
VK_F23 :: 0x86
VK_F24 :: 0x87

VK_BROWSER_BACK :: 0xA6
VK_BROWSER_FORWARD :: 0xA7
VK_BROWSER_REFRESH :: 0xA8
VK_BROWSER_STOP :: 0xA9
VK_BROWSER_SEARCH :: 0xAA
VK_BROWSER_FAVORITES :: 0xAB
VK_BROWSER_HOME :: 0xAC


XINPUT_FLAG_GAMEPAD :: 0x00000001
ERROR_SUCCESS :: 0

XINPUT_GAMEPAD :: struct {
	wButtons : WORD,
	bLeftTrigger : BYTE,
	bRightTrigger : BYTE,
	sThumbLX : SHORT,
	sThumbLY : SHORT,
	sThumbRX : SHORT,
	sThumbRY : SHORT,
}

XINPUT_STATE :: struct {
	dwPacketNumber : DWORD,
	Gamepad : XINPUT_GAMEPAD,
}

XINPUT_GAMEPAD_DPAD_UP :: 0x0001
XINPUT_GAMEPAD_DPAD_DOWN :: 0x0002
XINPUT_GAMEPAD_DPAD_LEFT :: 0x0004
XINPUT_GAMEPAD_DPAD_RIGHT :: 0x0008
XINPUT_GAMEPAD_START :: 0x0010
XINPUT_GAMEPAD_BACK :: 0x0020
XINPUT_GAMEPAD_LEFT_THUMB :: 0x0040
XINPUT_GAMEPAD_RIGHT_THUMB :: 0x0080
XINPUT_GAMEPAD_LEFT_SHOULDER :: 0x0100
XINPUT_GAMEPAD_RIGHT_SHOULDER :: 0x0200
XINPUT_GAMEPAD_A :: 0x1000
XINPUT_GAMEPAD_B :: 0x2000
XINPUT_GAMEPAD_X :: 0x4000
XINPUT_GAMEPAD_Y :: 0x8000

XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE :: 7849
XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE :: 8689
XINPUT_GAMEPAD_TRIGGER_THRESHOLD :: 30

MONITORINFO :: struct {
	cbSize : DWORD,
	rcMonitor : RECT,
	rcWork : RECT,
	dwFlags : DWORD,
}

HMONITOR :: rawptr

MONITORINFOF_PRIMARY :: 0x00000001

LOWORD :: #force_inline proc "contextless" (l : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	((WORD)(((DWORD_PTR)(l))&0xffff))
}

HIWORD :: #force_inline proc "contextless" (l : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	((WORD)((((DWORD_PTR)(l))>>16)&0xffff))
}


KF_EXTENDED :: 0x0100
KF_DLGMODE :: 0x0800
KF_MENUMODE :: 0x1000
KF_ALTDOWN :: 0x2000
KF_REPEAT :: 0x4000
KF_UP :: 0x8000


WM_MOUSEFIRST :: 0x0200
WM_MOUSEMOVE :: 0x0200
WM_LBUTTONDOWN :: 0x0201
WM_LBUTTONUP :: 0x0202
WM_LBUTTONDBLCLK :: 0x0203
WM_RBUTTONDOWN :: 0x0204
WM_RBUTTONUP :: 0x0205
WM_RBUTTONDBLCLK :: 0x0206
WM_MBUTTONDOWN :: 0x0207
WM_MBUTTONUP :: 0x0208
WM_MBUTTONDBLCLK :: 0x0209
WM_MOUSEWHEEL :: 0x020A
WM_NCMOUSEMOVE :: 0x00A0
WM_MOUSELEAVE :: 0x02A3
WM_NCMOUSELEAVE :: 0x02A2
WM_DESTROY :: 0x0002
WM_XBUTTONDOWN :: 0x020B
WM_XBUTTONUP :: 0x020C
WM_XBUTTONDBLCLK :: 0x020D
WM_KEYDOWN :: 0x0100
WM_KEYUP :: 0x0101
WM_SYSKEYDOWN :: 0x0104
WM_SYSKEYUP :: 0x0105
WM_SETFOCUS :: 0x0007
WM_KILLFOCUS :: 0x0008
WM_INPUTLANGCHANGEREQUEST :: 0x0050
WM_INPUTLANGCHANGE :: 0x0051
WM_CHAR :: 0x0102
WM_SETCURSOR :: 0x0020
WM_DEVICECHANGE :: 0x0219
WM_DISPLAYCHANGE :: 0x007E
WM_MOUSEACTIVATE :: 0x0021
WM_MOVE :: 0x0003
WM_CLOSE :: 0x0010
WM_SIZE :: 0x0005
WM_NCHITTEST :: 0x0084

HTTRANSPARENT :: (-1)

XBUTTON1 :: 0x0001
XBUTTON2 :: 0x0002

WHEEL_DELTA :: 120
GET_WHEEL_DELTA_WPARAM :: #force_inline proc "contextless" (wParam : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	((short)HIWORD(wParam))
}


TME_CANCEL :: 0x80000000
TME_LEAVE :: 0x00000002
TME_NONCLIENT :: 0x00000010

GET_X_LPARAM :: #force_inline proc "contextless" (lp : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	((int)(short)LOWORD(lp))
}

GET_Y_LPARAM :: #force_inline proc "contextless" (lp : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	((int)(short)HIWORD(lp))
}


MB_PRECOMPOSED :: 0x00000001

HTCLIENT :: 1

RTL_OSVERSIONINFOEXW :: struct {
	dwOSVersionInfoSize : DWORD,
	dwMajorVersion : DWORD,
	dwMinorVersion : DWORD,
	dwBuildNumber : DWORD,
	dwPlatformId : DWORD,
	szCSDVersion : [128]WCHAR,
	wServicePackMajor : WORD,
	wServicePackMinor : WORD,
	wSuiteMask : WORD,
	wProductType : BYTE,
	wReserved : BYTE,
}

VER_MINORVERSION :: 0x0000001
VER_MAJORVERSION :: 0x0000002
VER_GREATER_EQUAL :: 3

VER_SET_CONDITION :: #force_inline proc "contextless" (_m_ : $T0, _t_ : $T1, _c_ : $T2) //TODO @gen: Validate the parameters were not passed by reference.
{
	((_m_)=VerSetConditionMask((_m_),(_t_),(_c_)))
}


LOGPIXELSX :: 88
LOGPIXELSY :: 90

MONITOR_DEFAULTTONULL :: 0x00000000
MONITOR_DEFAULTTOPRIMARY :: 0x00000001
MONITOR_DEFAULTTONEAREST :: 0x00000002

FAILED :: #force_inline proc "contextless" (hr : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	(((HRESULT)(hr))<0)
}

SUCCEEDED :: #force_inline proc "contextless" (hr : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	(((HRESULT)(hr))>=0)
}


DWM_BB_ENABLE :: 0x00000001
DWM_BB_BLURREGION :: 0x00000002
DWM_BB_TRANSITIONONMAXIMIZED :: 0x00000004

HRGN :: struct { }

DWM_BLURBEHIND :: struct {
	dwFlags : DWORD,
	fEnable : BOOL,
	hRgnBlur : HRGN,
	fTransitionOnMaximized : BOOL,
}

WS_POPUP :: 0x80000000
WS_OVERLAPPED :: 0x00000000
WS_EX_TOPMOST :: 0x00000008
WS_EX_TOOLWINDOW :: 0x00000080
WS_EX_APPWINDOW :: 0x00040000
WS_EX_LAYERED :: 0x00080000

WS_OVERLAPPEDWINDOW :: 0xfffff// w/e

GWLP_HWNDPARENT :: (-8)

SW_SHOWNA :: 8
SW_SHOW :: 5

HWND_TOPMOST :: ((HWND)-1)
HWND_NOTOPMOST :: ((HWND)-2)

GWL_STYLE :: (-16)
GWL_EXSTYLE :: (-20)

SWP_NOSIZE :: 0x0001
SWP_NOMOVE :: 0x0002
SWP_NOZORDER :: 0x0004
SWP_NOACTIVATE :: 0x0010
SWP_FRAMECHANGED :: 0x0020

LWA_ALPHA :: 0x00000002

MA_NOACTIVATE :: 3

WNDPROC :: proc(_ : HWND, _ : UINT, _ : WPARAM, _ : LPARAM) -> LRESULT

HINSTANCE :: HANDLE
HICON :: HANDLE
HCURSOR :: HANDLE
HBRUSH :: HANDLE

WNDCLASSEXW :: struct {
	cbSize : UINT,
	/* Win 3.x */
	style : UINT,
	lpfnWndProc : WNDPROC,
	cbClsExtra : i32,
	cbWndExtra : i32,
	hInstance : HINSTANCE,
	hIcon : HICON,
	hCursor : HCURSOR,
	hbrBackground : HBRUSH,
	lpszMenuName : LPCWSTR,
	lpszClassName : LPCWSTR,
	/* Win 4.0 */
	hIconSm : HICON,
}

CS_VREDRAW :: 0x0001
CS_HREDRAW :: 0x0002
CS_OWNDC :: 0x0020

COLOR_BACKGROUND :: 1

// END WIN32 STRUCT SHIM
//
// impl
//
// dear imgui: Platform Backend for Windows (standard windows API for 32-bits AND 64-bits applications)
// This needs to be used along with a Renderer (e.g. DirectX11, OpenGL3, Vulkan..)

// Implemented features:
//  [X] Platform: Clipboard support (for Win32 this is actually part of core dear imgui)
//  [X] Platform: Mouse support. Can discriminate Mouse/TouchScreen/Pen.
//  [X] Platform: Keyboard support. Since 1.87 we are using the io.AddKeyEvent() function. Pass ImGuiKey values to all key functions e.g. ImGui::IsKeyPressed(ImGuiKey_Space). [Legacy VK_* values are obsolete since 1.87 and not supported since 1.91.5]
//  [X] Platform: Gamepad support. Enabled with 'io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad'.
//  [X] Platform: Mouse cursor shape and visibility (ImGuiBackendFlags_HasMouseCursors). Disable with 'io.ConfigFlags |= ImGuiConfigFlags_NoMouseCursorChange'.
//  [X] Platform: Multi-viewport support (multiple windows). Enable with 'io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable'.

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
//  2024-10-28: [Docking] Rely on property stored inside HWND to retrieve context/viewport, should facilitate attempt to use this for parallel contexts. (#8069)
//  2024-09-16: [Docking] Inputs: fixed an issue where a viewport destroyed while clicking would hog mouse tracking and temporary lead to incorrect update of HoveredWindow. (#7971)
//  2024-07-08: Inputs: Fixed ImGuiMod_Super being mapped to VK_APPS instead of VK_LWIN||VK_RWIN. (#7768)
//  2023-10-05: Inputs: Added support for extra ImGuiKey values: F13 to F24 function keys, app back/forward keys.
//  2023-09-25: Inputs: Synthesize key-down event on key-up for VK_SNAPSHOT / ImGuiKey_PrintScreen as Windows doesn't emit it (same behavior as GLFW/SDL).
//  2023-09-07: Inputs: Added support for keyboard codepage conversion for when application is compiled in MBCS mode and using a non-Unicode window.
//  2023-04-19: Added ImGui_ImplWin32_InitForOpenGL() to facilitate combining raw Win32/Winapi with OpenGL. (#3218)
//  2023-04-04: Inputs: Added support for io.AddMouseSourceEvent() to discriminate ImGuiMouseSource_Mouse/ImGuiMouseSource_TouchScreen/ImGuiMouseSource_Pen. (#2702)
//  2023-02-15: Inputs: Use WM_NCMOUSEMOVE / WM_NCMOUSELEAVE to track mouse position over non-client area (e.g. OS decorations) when app is not focused. (#6045, #6162)
//  2023-02-02: Inputs: Flipping WM_MOUSEHWHEEL (horizontal mouse-wheel) value to match other backends and offer consistent horizontal scrolling direction. (#4019, #6096, #1463)
//  2022-10-11: Using 'nullptr' instead of 'NULL' as per our switch to C++11.
//  2022-09-28: Inputs: Convert WM_CHAR values with MultiByteToWideChar() when window class was registered as MBCS (not Unicode).
//  2022-09-26: Inputs: Renamed ImGuiKey_ModXXX introduced in 1.87 to ImGuiMod_XXX (old names still supported).
//  2022-01-26: Inputs: replaced short-lived io.AddKeyModsEvent() (added two weeks ago) with io.AddKeyEvent() using ImGuiKey_ModXXX flags. Sorry for the confusion.
//  2021-01-20: Inputs: calling new io.AddKeyAnalogEvent() for gamepad support, instead of writing directly to io.NavInputs[].
//  2022-01-17: Inputs: calling new io.AddMousePosEvent(), io.AddMouseButtonEvent(), io.AddMouseWheelEvent() API (1.87+).
//  2022-01-17: Inputs: always update key mods next and before a key event (not in NewFrame) to fix input queue with very low framerates.
//  2022-01-12: Inputs: Update mouse inputs using WM_MOUSEMOVE/WM_MOUSELEAVE + fallback to provide it when focused but not hovered/captured. More standard and will allow us to pass it to future input queue API.
//  2022-01-12: Inputs: Maintain our own copy of MouseButtonsDown mask instead of using ImGui::IsAnyMouseDown() which will be obsoleted.
//  2022-01-10: Inputs: calling new io.AddKeyEvent(), io.AddKeyModsEvent() + io.SetKeyEventNativeData() API (1.87+). Support for full ImGuiKey range.
//  2021-12-16: Inputs: Fill VK_LCONTROL/VK_RCONTROL/VK_LSHIFT/VK_RSHIFT/VK_LMENU/VK_RMENU for completeness.
//  2021-08-17: Calling io.AddFocusEvent() on WM_SETFOCUS/WM_KILLFOCUS messages.
//  2021-08-02: Inputs: Fixed keyboard modifiers being reported when host window doesn't have focus.
//  2021-07-29: Inputs: MousePos is correctly reported when the host platform window is hovered but not focused (using TrackMouseEvent() to receive WM_MOUSELEAVE events).
//  2021-06-29: Reorganized backend to pull data from a single structure to facilitate usage with multiple-contexts (all g_XXXX access changed to bd->XXXX).
//  2021-06-08: Fixed ImGui_ImplWin32_EnableDpiAwareness() and ImGui_ImplWin32_GetDpiScaleForMonitor() to handle Windows 8.1/10 features without a manifest (per-monitor DPI, and properly calls SetProcessDpiAwareness() on 8.1).
//  2021-03-23: Inputs: Clearing keyboard down array when losing focus (WM_KILLFOCUS).
//  2021-02-18: Added ImGui_ImplWin32_EnableAlphaCompositing(). Non Visual Studio users will need to link with dwmapi.lib (MinGW/gcc: use -ldwmapi).
//  2021-02-17: Fixed ImGui_ImplWin32_EnableDpiAwareness() attempting to get SetProcessDpiAwareness from shcore.dll on Windows 8 whereas it is only supported on Windows 8.1.
//  2021-01-25: Inputs: Dynamically loading XInput DLL.
//  2020-12-04: Misc: Fixed setting of io.DisplaySize to invalid/uninitialized data when after hwnd has been closed.
//  2020-03-03: Inputs: Calling AddInputCharacterUTF16() to support surrogate pairs leading to codepoint >= 0x10000 (for more complete CJK inputs)
//  2020-02-17: Added ImGui_ImplWin32_EnableDpiAwareness(), ImGui_ImplWin32_GetDpiScaleForHwnd(), ImGui_ImplWin32_GetDpiScaleForMonitor() helper functions.
//  2020-01-14: Inputs: Added support for #define IMGUI_IMPL_WIN32_DISABLE_GAMEPAD/IMGUI_IMPL_WIN32_DISABLE_LINKING_XINPUT.
//  2019-12-05: Inputs: Added support for ImGuiMouseCursor_NotAllowed mouse cursor.
//  2019-05-11: Inputs: Don't filter value from WM_CHAR before calling AddInputCharacter().
//  2019-01-17: Misc: Using GetForegroundWindow()+IsChild() instead of GetActiveWindow() to be compatible with windows created in a different thread or parent.
//  2019-01-17: Inputs: Added support for mouse buttons 4 and 5 via WM_XBUTTON* messages.
//  2019-01-15: Inputs: Added support for XInput gamepads (if ImGuiConfigFlags_NavEnableGamepad is set by user application).
//  2018-11-30: Misc: Setting up io.BackendPlatformName so it can be displayed in the About Window.
//  2018-06-29: Inputs: Added support for the ImGuiMouseCursor_Hand cursor.
//  2018-06-10: Inputs: Fixed handling of mouse wheel messages to support fine position messages (typically sent by track-pads).
//  2018-06-08: Misc: Extracted imgui_impl_win32.cpp/.h away from the old combined DX9/DX10/DX11/DX12 examples.
//  2018-03-20: Misc: Setup io.BackendFlags ImGuiBackendFlags_HasMouseCursors and ImGuiBackendFlags_HasSetMousePos flags + honor ImGuiConfigFlags_NoMouseCursorChange flag.
//  2018-02-20: Inputs: Added support for mouse cursors (ImGui::GetMouseCursor() value and WM_SETCURSOR message handling).
//  2018-02-06: Inputs: Added mapping for ImGuiKey_Space.
//  2018-02-06: Inputs: Honoring the io.WantSetMousePos by repositioning the mouse (when using navigation and ImGuiConfigFlags_NavMoveMouse is set).
//  2018-02-06: Misc: Removed call to ImGui::Shutdown() which is not available from 1.60 WIP, user needs to call CreateContext/DestroyContext themselves.
//  2018-01-20: Inputs: Added Horizontal Mouse Wheel support.
//  2018-01-08: Inputs: Added mapping for ImGuiKey_Insert.
//  2018-01-05: Inputs: Added WM_LBUTTONDBLCLK double-click handlers for window classes with the CS_DBLCLKS flag.
//  2017-10-23: Inputs: Added WM_SYSKEYDOWN / WM_SYSKEYUP handlers so e.g. the VK_MENU key can be read.
//  2017-10-23: Inputs: Using Win32 ::SetCapture/::GetCapture() to retrieve mouse positions outside the client area when dragging.
//  2016-11-12: Inputs: Only call Win32 ::SetCursor(nullptr) when io.MouseDrawCursor is set.

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
IMGUI_HAS_VIEWPORT :: true// Viewport WIP branch
IMGUI_HAS_DOCK :: true// Docking WIP branch

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



when ! IMGUI_DISABLE { /* @gen ifndef */

//-----------------------------------------------------------------------------
// [SECTION] Header mess
//-----------------------------------------------------------------------------

// Includes

// Define attributes of all API symbols declarations (e.g. for DLL under Windows)
// IMGUI_API is used for core imgui functions, IMGUI_IMPL_API is used for the default backends files (imgui_impl_xxx.h)
// Using dear imgui via a shared library is not recommended: we don't guarantee backward nor forward ABI compatibility + this is a call-heavy library and function call overhead adds up.
when ! IMGUI_API { /* @gen ifndef */
IMGUI_API :: true
} // preproc endif
when ! IMGUI_IMPL_API { /* @gen ifndef */
IMGUI_IMPL_API :: IMGUI_API
} // preproc endif

// Helper Macros
when ! IM_ASSERT { /* @gen ifndef */
IM_ASSERT :: #force_inline proc "contextless" (_EXPR : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	assert(_EXPR)// You can override the default assert handler by editing imconfig.h
}

} // preproc endif
IM_ARRAYSIZE :: #force_inline proc "contextless" (_ARR : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	((int)(sizeof(_ARR)/sizeof(*(_ARR))))// Size of a static C-style array. Don't use on pointers!
}

IM_UNUSED :: #force_inline proc "contextless" (_VAR : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	((void)(_VAR))// Used to silence "unused variable warnings". Often useful as asserts may be stripped out from final builds.
}


// Check that version and structures layouts are matching between compiled imgui code and caller. Read comments above DebugCheckVersionAndDataLayout() for details.
IMGUI_CHECKVERSION :: #force_inline proc "contextless" () //TODO @gen: Validate the parameters were not passed by reference.
{
	ImGui::DebugCheckVersionAndDataLayout(IMGUI_VERSION,sizeof(ImGuiIO),sizeof(ImGuiStyle),sizeof(ImVec2),sizeof(ImVec4),sizeof(ImDrawVert),sizeof(ImDrawIdx))
}


// Helper Macros - IM_FMTARGS, IM_FMTLIST: Apply printf-style warnings to our formatting functions.
// (MSVC provides an equivalent mechanism via SAL Annotations but it would require the macros in a different
//  location. e.g. #include <sal.h> + void myprintf(_Printf_format_string_ const char* format, ...))
when ! defined ( IMGUI_USE_STB_SPRINTF ) && defined ( __MINGW32__ ) && ! defined ( __clang__ ) {
IM_FMTARGS :: #force_inline proc "contextless" (FMT : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	__attribute__((format(gnu_printf,FMT,FMT+1)))
}

IM_FMTLIST :: #force_inline proc "contextless" (FMT : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	__attribute__((format(gnu_printf,FMT,0)))
}

} else when ! defined ( IMGUI_USE_STB_SPRINTF ) && ( defined ( __clang__ ) || defined ( __GNUC__ ) ) {
IM_FMTARGS :: #force_inline proc "contextless" (FMT : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	__attribute__((format(printf,FMT,FMT+1)))
}

IM_FMTLIST :: #force_inline proc "contextless" (FMT : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	__attribute__((format(printf,FMT,0)))
}

} else { // preproc else
IM_FMTARGS :: #force_inline proc "contextless" (FMT : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
}

IM_FMTLIST :: #force_inline proc "contextless" (FMT : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
}

} // preproc endif

// Disable some of MSVC most aggressive Debug runtime checks in function header/footer (used in some simple/low-level functions)
when defined ( _MSC_VER ) && ! defined ( __clang__ ) && ! defined ( __INTEL_COMPILER ) && ! defined ( IMGUI_DEBUG_PARANOID ) {
IM_MSVC_RUNTIME_CHECKS_OFF :: __pragma(runtime_checks("",off))__pragma(check_stack(off))__pragma(strict_gs_check(push,off))
IM_MSVC_RUNTIME_CHECKS_RESTORE :: __pragma(runtime_checks("",restore))__pragma(check_stack())__pragma(strict_gs_check(pop))
} else { // preproc else
IM_MSVC_RUNTIME_CHECKS_OFF :: true
IM_MSVC_RUNTIME_CHECKS_RESTORE :: true
} // preproc endif

// Warnings
when _MSC_VER { /* @gen ifdef */
} // preproc endif
when defined ( __clang__ ) {
when __has_warning ( "-Wunknown-warning-option" ) {
} // preproc endif
} else when defined ( __GNUC__ ) {
} // preproc endif

//-----------------------------------------------------------------------------
// [SECTION] Forward declarations and basic types
//-----------------------------------------------------------------------------

// Scalar data types
ImGuiID :: u32// A unique ID used by widgets (typically the result of hashing a stack of string)
ImS8 :: i8// 8-bit signed integer
ImU8 :: u8// 8-bit unsigned integer
ImS16 :: i16// 16-bit signed integer
ImU16 :: u16// 16-bit unsigned integer
ImS32 :: i32// 32-bit signed integer == int
ImU32 :: u32// 32-bit unsigned integer (often used to store packed colors)
ImS64 :: i64// 64-bit signed integer
ImU64 :: u64// 64-bit unsigned integer

ImGuiCol :: i32// -> enum ImGuiCol_             // Enum: A color identifier for styling
ImGuiCond :: i32// -> enum ImGuiCond_            // Enum: A condition for many Set*() functions
ImGuiDataType :: i32// -> enum ImGuiDataType_        // Enum: A primary data type
ImGuiMouseButton :: i32// -> enum ImGuiMouseButton_     // Enum: A mouse button identifier (0=left, 1=right, 2=middle)
ImGuiMouseCursor :: i32// -> enum ImGuiMouseCursor_     // Enum: A mouse cursor shape
ImGuiStyleVar :: i32// -> enum ImGuiStyleVar_        // Enum: A variable identifier for styling
ImGuiTableBgTarget :: i32// -> enum ImGuiTableBgTarget_   // Enum: A color target for TableSetBgColor()

// Flags (declared as int to allow using as flags without overhead, and to not pollute the top of this file)
// - Tip: Use your programming IDE navigation facilities on the names in the _central column_ below to find the actual flags/enum lists!
//   - In Visual Studio: CTRL+comma ("Edit.GoToAll") can follow symbols inside comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
//   - In Visual Studio w/ Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols inside comments.
//   - In VS Code, CLion, etc.: CTRL+click can follow symbols inside comments.
ImDrawFlags :: i32// -> enum ImDrawFlags_          // Flags: for ImDrawList functions
ImDrawListFlags :: i32// -> enum ImDrawListFlags_      // Flags: for ImDrawList instance
ImFontAtlasFlags :: i32// -> enum ImFontAtlasFlags_     // Flags: for ImFontAtlas build
ImGuiBackendFlags :: i32// -> enum ImGuiBackendFlags_    // Flags: for io.BackendFlags
ImGuiButtonFlags :: i32// -> enum ImGuiButtonFlags_     // Flags: for InvisibleButton()
ImGuiChildFlags :: i32// -> enum ImGuiChildFlags_      // Flags: for BeginChild()
ImGuiColorEditFlags :: i32// -> enum ImGuiColorEditFlags_  // Flags: for ColorEdit4(), ColorPicker4() etc.
ImGuiConfigFlags :: i32// -> enum ImGuiConfigFlags_     // Flags: for io.ConfigFlags
ImGuiComboFlags :: i32// -> enum ImGuiComboFlags_      // Flags: for BeginCombo()
ImGuiDockNodeFlags :: i32// -> enum ImGuiDockNodeFlags_   // Flags: for DockSpace()
ImGuiDragDropFlags :: i32// -> enum ImGuiDragDropFlags_   // Flags: for BeginDragDropSource(), AcceptDragDropPayload()
ImGuiFocusedFlags :: i32// -> enum ImGuiFocusedFlags_    // Flags: for IsWindowFocused()
ImGuiHoveredFlags :: i32// -> enum ImGuiHoveredFlags_    // Flags: for IsItemHovered(), IsWindowHovered() etc.
ImGuiInputFlags :: i32// -> enum ImGuiInputFlags_      // Flags: for Shortcut(), SetNextItemShortcut()
ImGuiInputTextFlags :: i32// -> enum ImGuiInputTextFlags_  // Flags: for InputText(), InputTextMultiline()
ImGuiItemFlags :: i32// -> enum ImGuiItemFlags_       // Flags: for PushItemFlag(), shared by all items
ImGuiKeyChord :: i32// -> ImGuiKey | ImGuiMod_XXX    // Flags: for IsKeyChordPressed(), Shortcut() etc. an ImGuiKey optionally OR-ed with one or more ImGuiMod_XXX values.
ImGuiPopupFlags :: i32// -> enum ImGuiPopupFlags_      // Flags: for OpenPopup*(), BeginPopupContext*(), IsPopupOpen()
ImGuiMultiSelectFlags :: i32// -> enum ImGuiMultiSelectFlags_// Flags: for BeginMultiSelect()
ImGuiSelectableFlags :: i32// -> enum ImGuiSelectableFlags_ // Flags: for Selectable()
ImGuiSliderFlags :: i32// -> enum ImGuiSliderFlags_     // Flags: for DragFloat(), DragInt(), SliderFloat(), SliderInt() etc.
ImGuiTabBarFlags :: i32// -> enum ImGuiTabBarFlags_     // Flags: for BeginTabBar()
ImGuiTabItemFlags :: i32// -> enum ImGuiTabItemFlags_    // Flags: for BeginTabItem()
ImGuiTableFlags :: i32// -> enum ImGuiTableFlags_      // Flags: For BeginTable()
ImGuiTableColumnFlags :: i32// -> enum ImGuiTableColumnFlags_// Flags: For TableSetupColumn()
ImGuiTableRowFlags :: i32// -> enum ImGuiTableRowFlags_   // Flags: For TableNextRow()
ImGuiTreeNodeFlags :: i32// -> enum ImGuiTreeNodeFlags_   // Flags: for TreeNode(), TreeNodeEx(), CollapsingHeader()
ImGuiViewportFlags :: i32// -> enum ImGuiViewportFlags_   // Flags: for ImGuiViewport
ImGuiWindowFlags :: i32// -> enum ImGuiWindowFlags_     // Flags: for Begin(), BeginChild()

// ImTexture: user data for renderer backend to identify a texture [Compile-time configurable type]
// - To use something else than an opaque void* pointer: override with e.g. '#define ImTextureID MyTextureType*' in your imconfig.h file.
// - This can be whatever to you want it to be! read the FAQ about ImTextureID for details.
// - You can make this a structure with various constructors if you need. You will have to implement ==/!= operators.
// - (note: before v1.91.4 (2024/10/08) the default type for ImTextureID was void*. Use intermediary intptr_t cast and read FAQ if you have casting warnings)
when ! ImTextureID { /* @gen ifndef */
ImTextureID :: ImU64// Default: store a pointer or an integer fitting in a pointer (most renderer backends are ok with that)
} // preproc endif

// ImDrawIdx: vertex index. [Compile-time configurable type]
// - To use 16-bit indices + allow large meshes: backend need to set 'io.BackendFlags |= ImGuiBackendFlags_RendererHasVtxOffset' and handle ImDrawCmd::VtxOffset (recommended).
// - To use 32-bit indices: override with '#define ImDrawIdx unsigned int' in your imconfig.h file.
when ! ImDrawIdx { /* @gen ifndef */
ImDrawIdx :: u16// Default: 16-bit (for maximum compatibility with renderer backends)
} // preproc endif

// Character types
// (we generally use UTF-8 encoded string in the API. This is storage specifically for a decoded character used for keyboard input and display)
ImWchar32 :: u32// A single decoded U32 character/code point. We encode them as multi bytes UTF-8 when used in strings.
ImWchar16 :: u16// A single decoded U16 character/code point. We encode them as multi bytes UTF-8 when used in strings.
when IMGUI_USE_WCHAR32 /* @gen ifdef */ { // ImWchar [configurable type: override in imconfig.h with '#define IMGUI_USE_WCHAR32' to support Unicode planes 1-16]
ImWchar :: ImWchar32
} else { // preproc else
ImWchar :: ImWchar16
} // preproc endif

// Multi-Selection item index or identifier when using BeginMultiSelect()
// - Used by SetNextItemSelectionUserData() + and inside ImGuiMultiSelectIO structure.
// - Most users are likely to use this store an item INDEX but this may be used to store a POINTER/ID as well. Read comments near ImGuiMultiSelectIO for details.
ImGuiSelectionUserData :: ImS64

// Callback and functions types
ImGuiInputTextCallback :: proc(data : ^ImGuiInputTextCallbackData) -> i32// Callback function for ImGui::InputText()
ImGuiSizeCallback :: proc(data : ^ImGuiSizeCallbackData)// Callback function for ImGui::SetNextWindowSizeConstraints()
ImGuiMemAllocFunc :: proc(sz : uint, user_data : rawptr) -> rawptr// Function signature for ImGui::SetAllocatorFunctions()
ImGuiMemFreeFunc :: proc(ptr : rawptr, user_data : rawptr)// Function signature for ImGui::SetAllocatorFunctions()

// ImVec2: 2D vector used to store positions, sizes etc. [Compile-time configurable type]
// - This is a frequently used type in the API. Consider using IM_VEC2_CLASS_EXTRA to create implicit cast from/to our preferred type.
// - Add '#define IMGUI_DEFINE_MATH_OPERATORS' before including this file (or in imconfig.h) to access courtesy maths operators for ImVec2 and ImVec4.

ImVec2 :: struct {
	x : f32, y : f32,
}

ImVec2_init_0 :: proc(this : ^ImVec2)
{
	this.x = 0.0
	this.y = 0.0
}

ImVec2_init_1 :: proc(this : ^ImVec2, _x : f32, _y : f32)
{
	this.x = _x
	this.y = _y
}

// ImVec4: 4D vector used to store clipping rectangles, colors etc. [Compile-time configurable type]
ImVec4 :: struct {
	x : f32, y : f32, z : f32, w : f32,
}

ImVec4_init_0 :: proc(this : ^ImVec4)
{
	this.x = 0.0
	this.y = 0.0
	this.z = 0.0
	this.w = 0.0
}

ImVec4_init_1 :: proc(this : ^ImVec4, _x : f32, _y : f32, _z : f32, _w : f32)
{
	this.x = _x
	this.y = _y
	this.z = _z
	this.w = _w
}


//-----------------------------------------------------------------------------
// [SECTION] Dear ImGui end-user API functions
// (Note that ImGui:: being a namespace, you can add extra ImGui:: functions in your own separate file. Please don't modify imgui source files!)
//-----------------------------------------------------------------------------

when ! IMGUI_DISABLE_DEBUG_TOOLS { /* @gen ifndef */
} // preproc endif

// namespace ImGui

//-----------------------------------------------------------------------------
// [SECTION] Flags & Enumerations
//-----------------------------------------------------------------------------

// Flags for ImGui::Begin()
// (Those are per-window flags. There are shared flags in ImGuiIO: io.ConfigWindowsResizeFromEdges and io.ConfigWindowsMoveFromTitleBarOnly)
ImGuiWindowFlags_ :: enum i32 {
	ImGuiWindowFlags_None = 0,
	ImGuiWindowFlags_NoTitleBar = 1 << 0, // Disable title-bar
	ImGuiWindowFlags_NoResize = 1 << 1, // Disable user resizing with the lower-right grip
	ImGuiWindowFlags_NoMove = 1 << 2, // Disable user moving the window
	ImGuiWindowFlags_NoScrollbar = 1 << 3, // Disable scrollbars (window can still scroll with mouse or programmatically)
	ImGuiWindowFlags_NoScrollWithMouse = 1 << 4, // Disable user vertically scrolling with mouse wheel. On child window, mouse wheel will be forwarded to the parent unless NoScrollbar is also set.
	ImGuiWindowFlags_NoCollapse = 1 << 5, // Disable user collapsing window by double-clicking on it. Also referred to as Window Menu Button (e.g. within a docking node).
	ImGuiWindowFlags_AlwaysAutoResize = 1 << 6, // Resize every window to its content every frame
	ImGuiWindowFlags_NoBackground = 1 << 7, // Disable drawing background color (WindowBg, etc.) and outside border. Similar as using SetNextWindowBgAlpha(0.0f).
	ImGuiWindowFlags_NoSavedSettings = 1 << 8, // Never load/save settings in .ini file
	ImGuiWindowFlags_NoMouseInputs = 1 << 9, // Disable catching mouse, hovering test with pass through.
	ImGuiWindowFlags_MenuBar = 1 << 10, // Has a menu-bar
	ImGuiWindowFlags_HorizontalScrollbar = 1 << 11, // Allow horizontal scrollbar to appear (off by default). You may use SetNextWindowContentSize(ImVec2(width,0.0f)); prior to calling Begin() to specify width. Read code in imgui_demo in the "Horizontal Scrolling" section.
	ImGuiWindowFlags_NoFocusOnAppearing = 1 << 12, // Disable taking focus when transitioning from hidden to visible state
	ImGuiWindowFlags_NoBringToFrontOnFocus = 1 << 13, // Disable bringing window to front when taking focus (e.g. clicking on it or programmatically giving it focus)
	ImGuiWindowFlags_AlwaysVerticalScrollbar = 1 << 14, // Always show vertical scrollbar (even if ContentSize.y < Size.y)
	ImGuiWindowFlags_AlwaysHorizontalScrollbar = 1 << 15, // Always show horizontal scrollbar (even if ContentSize.x < Size.x)
	ImGuiWindowFlags_NoNavInputs = 1 << 16, // No keyboard/gamepad navigation within the window
	ImGuiWindowFlags_NoNavFocus = 1 << 17, // No focusing toward this window with keyboard/gamepad navigation (e.g. skipped by CTRL+TAB)
	ImGuiWindowFlags_UnsavedDocument = 1 << 18, // Display a dot next to the title. When used in a tab/docking context, tab is selected when clicking the X + closure is not assumed (will wait for user to stop submitting the tab). Otherwise closure is assumed when pressing the X, so if you keep submitting the tab may reappear at end of tab bar.
	ImGuiWindowFlags_NoDocking = 1 << 19, // Disable docking of this window
	ImGuiWindowFlags_NoNav = ImGuiWindowFlags_NoNavInputs | ImGuiWindowFlags_NoNavFocus,
	ImGuiWindowFlags_NoDecoration = ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoCollapse,
	ImGuiWindowFlags_NoInputs = ImGuiWindowFlags_NoMouseInputs | ImGuiWindowFlags_NoNavInputs | ImGuiWindowFlags_NoNavFocus,

	// [Internal]
	ImGuiWindowFlags_ChildWindow = 1 << 24, // Don't use! For internal use by BeginChild()
	ImGuiWindowFlags_Tooltip = 1 << 25, // Don't use! For internal use by BeginTooltip()
	ImGuiWindowFlags_Popup = 1 << 26, // Don't use! For internal use by BeginPopup()
	ImGuiWindowFlags_Modal = 1 << 27, // Don't use! For internal use by BeginPopupModal()
	ImGuiWindowFlags_ChildMenu = 1 << 28, // Don't use! For internal use by BeginMenu()
	ImGuiWindowFlags_DockNodeHost = 1 << 29, // Don't use! For internal use by Begin()/NewFrame()

	// Obsolete names

}

// Flags for ImGui::BeginChild()
// (Legacy: bit 0 must always correspond to ImGuiChildFlags_Borders to be backward compatible with old API using 'bool border = false'.
// About using AutoResizeX/AutoResizeY flags:
// - May be combined with SetNextWindowSizeConstraints() to set a min/max size for each axis (see "Demo->Child->Auto-resize with Constraints").
// - Size measurement for a given axis is only performed when the child window is within visible boundaries, or is just appearing.
//   - This allows BeginChild() to return false when not within boundaries (e.g. when scrolling), which is more optimal. BUT it won't update its auto-size while clipped.
//     While not perfect, it is a better default behavior as the always-on performance gain is more valuable than the occasional "resizing after becoming visible again" glitch.
//   - You may also use ImGuiChildFlags_AlwaysAutoResize to force an update even when child window is not in view.
//     HOWEVER PLEASE UNDERSTAND THAT DOING SO WILL PREVENT BeginChild() FROM EVER RETURNING FALSE, disabling benefits of coarse clipping.
ImGuiChildFlags_ :: enum i32 {
	ImGuiChildFlags_None = 0,
	ImGuiChildFlags_Borders = 1 << 0, // Show an outer border and enable WindowPadding. (IMPORTANT: this is always == 1 == true for legacy reason)
	ImGuiChildFlags_AlwaysUseWindowPadding = 1 << 1, // Pad with style.WindowPadding even if no border are drawn (no padding by default for non-bordered child windows because it makes more sense)
	ImGuiChildFlags_ResizeX = 1 << 2, // Allow resize from right border (layout direction). Enable .ini saving (unless ImGuiWindowFlags_NoSavedSettings passed to window flags)
	ImGuiChildFlags_ResizeY = 1 << 3, // Allow resize from bottom border (layout direction). "
	ImGuiChildFlags_AutoResizeX = 1 << 4, // Enable auto-resizing width. Read "IMPORTANT: Size measurement" details above.
	ImGuiChildFlags_AutoResizeY = 1 << 5, // Enable auto-resizing height. Read "IMPORTANT: Size measurement" details above.
	ImGuiChildFlags_AlwaysAutoResize = 1 << 6, // Combined with AutoResizeX/AutoResizeY. Always measure size even when child is hidden, always return true, always disable clipping optimization! NOT RECOMMENDED.
	ImGuiChildFlags_FrameStyle = 1 << 7, // Style the child window like a framed item: use FrameBg, FrameRounding, FrameBorderSize, FramePadding instead of ChildBg, ChildRounding, ChildBorderSize, WindowPadding.
	ImGuiChildFlags_NavFlattened = 1 << 8, // [BETA] Share focus scope, allow keyboard/gamepad navigation to cross over parent border to this child or between sibling child windows.

	// Obsolete names

}

// Flags for ImGui::PushItemFlag()
// (Those are shared by all items)
ImGuiItemFlags_ :: enum i32 {
	ImGuiItemFlags_None = 0, // (Default)
	ImGuiItemFlags_NoTabStop = 1 << 0, // false    // Disable keyboard tabbing. This is a "lighter" version of ImGuiItemFlags_NoNav.
	ImGuiItemFlags_NoNav = 1 << 1, // false    // Disable any form of focusing (keyboard/gamepad directional navigation and SetKeyboardFocusHere() calls).
	ImGuiItemFlags_NoNavDefaultFocus = 1 << 2, // false    // Disable item being a candidate for default focus (e.g. used by title bar items).
	ImGuiItemFlags_ButtonRepeat = 1 << 3, // false    // Any button-like behavior will have repeat mode enabled (based on io.KeyRepeatDelay and io.KeyRepeatRate values). Note that you can also call IsItemActive() after any button to tell if it is being held.
	ImGuiItemFlags_AutoClosePopups = 1 << 4, // true     // MenuItem()/Selectable() automatically close their parent popup window.
	ImGuiItemFlags_AllowDuplicateId = 1 << 5, // false    // Allow submitting an item with the same identifier as an item already submitted this frame without triggering a warning tooltip if io.ConfigDebugHighlightIdConflicts is set.
}

// Flags for ImGui::InputText()
// (Those are per-item flags. There are shared flags in ImGuiIO: io.ConfigInputTextCursorBlink and io.ConfigInputTextEnterKeepActive)
ImGuiInputTextFlags_ :: enum i32 {
	// Basic filters (also see ImGuiInputTextFlags_CallbackCharFilter)
	ImGuiInputTextFlags_None = 0,
	ImGuiInputTextFlags_CharsDecimal = 1 << 0, // Allow 0123456789.+-*/
	ImGuiInputTextFlags_CharsHexadecimal = 1 << 1, // Allow 0123456789ABCDEFabcdef
	ImGuiInputTextFlags_CharsScientific = 1 << 2, // Allow 0123456789.+-*/eE (Scientific notation input)
	ImGuiInputTextFlags_CharsUppercase = 1 << 3, // Turn a..z into A..Z
	ImGuiInputTextFlags_CharsNoBlank = 1 << 4, // Filter out spaces, tabs

	// Inputs
	ImGuiInputTextFlags_AllowTabInput = 1 << 5, // Pressing TAB input a '\t' character into the text field
	ImGuiInputTextFlags_EnterReturnsTrue = 1 << 6, // Return 'true' when Enter is pressed (as opposed to every time the value was modified). Consider using IsItemDeactivatedAfterEdit() instead!
	ImGuiInputTextFlags_EscapeClearsAll = 1 << 7, // Escape key clears content if not empty, and deactivate otherwise (contrast to default behavior of Escape to revert)
	ImGuiInputTextFlags_CtrlEnterForNewLine = 1 << 8, // In multi-line mode, validate with Enter, add new line with Ctrl+Enter (default is opposite: validate with Ctrl+Enter, add line with Enter).

	// Other options
	ImGuiInputTextFlags_ReadOnly = 1 << 9, // Read-only mode
	ImGuiInputTextFlags_Password = 1 << 10, // Password mode, display all characters as '*', disable copy
	ImGuiInputTextFlags_AlwaysOverwrite = 1 << 11, // Overwrite mode
	ImGuiInputTextFlags_AutoSelectAll = 1 << 12, // Select entire text when first taking mouse focus
	ImGuiInputTextFlags_ParseEmptyRefVal = 1 << 13, // InputFloat(), InputInt(), InputScalar() etc. only: parse empty string as zero value.
	ImGuiInputTextFlags_DisplayEmptyRefVal = 1 << 14, // InputFloat(), InputInt(), InputScalar() etc. only: when value is zero, do not display it. Generally used with ImGuiInputTextFlags_ParseEmptyRefVal.
	ImGuiInputTextFlags_NoHorizontalScroll = 1 << 15, // Disable following the cursor horizontally
	ImGuiInputTextFlags_NoUndoRedo = 1 << 16, // Disable undo/redo. Note that input text owns the text data while active, if you want to provide your own undo/redo stack you need e.g. to call ClearActiveID().

	// Elide display / Alignment
	ImGuiInputTextFlags_ElideLeft = 1 << 17, // When text doesn't fit, elide left side to ensure right side stays visible. Useful for path/filenames. Single-line only!

	// Callback features
	ImGuiInputTextFlags_CallbackCompletion = 1 << 18, // Callback on pressing TAB (for completion handling)
	ImGuiInputTextFlags_CallbackHistory = 1 << 19, // Callback on pressing Up/Down arrows (for history handling)
	ImGuiInputTextFlags_CallbackAlways = 1 << 20, // Callback on each iteration. User code may query cursor position, modify text buffer.
	ImGuiInputTextFlags_CallbackCharFilter = 1 << 21, // Callback on character inputs to replace or discard them. Modify 'EventChar' to replace or discard, or return 1 in callback to discard.
	ImGuiInputTextFlags_CallbackResize = 1 << 22, // Callback on buffer capacity changes request (beyond 'buf_size' parameter value), allowing the string to grow. Notify when the string wants to be resized (for string types which hold a cache of their Size). You will be provided a new BufSize in the callback and NEED to honor it. (see misc/cpp/imgui_stdlib.h for an example of using this)
	ImGuiInputTextFlags_CallbackEdit = 1 << 23, // Callback on any edit (note that InputText() already returns true on edit, the callback is useful mainly to manipulate the underlying buffer while focus is active)

	// Obsolete names
	//ImGuiInputTextFlags_AlwaysInsertMode  = ImGuiInputTextFlags_AlwaysOverwrite   // [renamed in 1.82] name was not matching behavior
}

// Flags for ImGui::TreeNodeEx(), ImGui::CollapsingHeader*()
ImGuiTreeNodeFlags_ :: enum i32 {
	ImGuiTreeNodeFlags_None = 0,
	ImGuiTreeNodeFlags_Selected = 1 << 0, // Draw as selected
	ImGuiTreeNodeFlags_Framed = 1 << 1, // Draw frame with background (e.g. for CollapsingHeader)
	ImGuiTreeNodeFlags_AllowOverlap = 1 << 2, // Hit testing to allow subsequent widgets to overlap this one
	ImGuiTreeNodeFlags_NoTreePushOnOpen = 1 << 3, // Don't do a TreePush() when open (e.g. for CollapsingHeader) = no extra indent nor pushing on ID stack
	ImGuiTreeNodeFlags_NoAutoOpenOnLog = 1 << 4, // Don't automatically and temporarily open node when Logging is active (by default logging will automatically open tree nodes)
	ImGuiTreeNodeFlags_DefaultOpen = 1 << 5, // Default node to be open
	ImGuiTreeNodeFlags_OpenOnDoubleClick = 1 << 6, // Open on double-click instead of simple click (default for multi-select unless any _OpenOnXXX behavior is set explicitly). Both behaviors may be combined.
	ImGuiTreeNodeFlags_OpenOnArrow = 1 << 7, // Open when clicking on the arrow part (default for multi-select unless any _OpenOnXXX behavior is set explicitly). Both behaviors may be combined.
	ImGuiTreeNodeFlags_Leaf = 1 << 8, // No collapsing, no arrow (use as a convenience for leaf nodes).
	ImGuiTreeNodeFlags_Bullet = 1 << 9, // Display a bullet instead of arrow. IMPORTANT: node can still be marked open/close if you don't set the _Leaf flag!
	ImGuiTreeNodeFlags_FramePadding = 1 << 10, // Use FramePadding (even for an unframed text node) to vertically align text baseline to regular widget height. Equivalent to calling AlignTextToFramePadding() before the node.
	ImGuiTreeNodeFlags_SpanAvailWidth = 1 << 11, // Extend hit box to the right-most edge, even if not framed. This is not the default in order to allow adding other items on the same line without using AllowOverlap mode.
	ImGuiTreeNodeFlags_SpanFullWidth = 1 << 12, // Extend hit box to the left-most and right-most edges (cover the indent area).
	ImGuiTreeNodeFlags_SpanTextWidth = 1 << 13, // Narrow hit box + narrow hovering highlight, will only cover the label text.
	ImGuiTreeNodeFlags_SpanAllColumns = 1 << 14, // Frame will span all columns of its container table (text will still fit in current column)
	ImGuiTreeNodeFlags_NavLeftJumpsBackHere = 1 << 15, // (WIP) Nav: left direction may move to this TreeNode() from any of its child (items submitted between TreeNode and TreePop)
	//ImGuiTreeNodeFlags_NoScrollOnOpen     = 1 << 16,  // FIXME: TODO: Disable automatic scroll on TreePop() if node got just open and contents is not visible
	ImGuiTreeNodeFlags_CollapsingHeader = ImGuiTreeNodeFlags_Framed | ImGuiTreeNodeFlags_NoTreePushOnOpen | ImGuiTreeNodeFlags_NoAutoOpenOnLog,


}

// Flags for OpenPopup*(), BeginPopupContext*(), IsPopupOpen() functions.
// - To be backward compatible with older API which took an 'int mouse_button = 1' argument instead of 'ImGuiPopupFlags flags',
//   we need to treat small flags values as a mouse button index, so we encode the mouse button in the first few bits of the flags.
//   It is therefore guaranteed to be legal to pass a mouse button index in ImGuiPopupFlags.
// - For the same reason, we exceptionally default the ImGuiPopupFlags argument of BeginPopupContextXXX functions to 1 instead of 0.
//   IMPORTANT: because the default parameter is 1 (==ImGuiPopupFlags_MouseButtonRight), if you rely on the default parameter
//   and want to use another flag, you need to pass in the ImGuiPopupFlags_MouseButtonRight flag explicitly.
// - Multiple buttons currently cannot be combined/or-ed in those functions (we could allow it later).
ImGuiPopupFlags_ :: enum i32 {
	ImGuiPopupFlags_None = 0,
	ImGuiPopupFlags_MouseButtonLeft = 0, // For BeginPopupContext*(): open on Left Mouse release. Guaranteed to always be == 0 (same as ImGuiMouseButton_Left)
	ImGuiPopupFlags_MouseButtonRight = 1, // For BeginPopupContext*(): open on Right Mouse release. Guaranteed to always be == 1 (same as ImGuiMouseButton_Right)
	ImGuiPopupFlags_MouseButtonMiddle = 2, // For BeginPopupContext*(): open on Middle Mouse release. Guaranteed to always be == 2 (same as ImGuiMouseButton_Middle)
	ImGuiPopupFlags_MouseButtonMask_ = 0x1F,
	ImGuiPopupFlags_MouseButtonDefault_ = 1,
	ImGuiPopupFlags_NoReopen = 1 << 5, // For OpenPopup*(), BeginPopupContext*(): don't reopen same popup if already open (won't reposition, won't reinitialize navigation)
	//ImGuiPopupFlags_NoReopenAlwaysNavInit = 1 << 6,   // For OpenPopup*(), BeginPopupContext*(): focus and initialize navigation even when not reopening.
	ImGuiPopupFlags_NoOpenOverExistingPopup = 1 << 7, // For OpenPopup*(), BeginPopupContext*(): don't open if there's already a popup at the same level of the popup stack
	ImGuiPopupFlags_NoOpenOverItems = 1 << 8, // For BeginPopupContextWindow(): don't return true when hovering items, only when hovering empty space
	ImGuiPopupFlags_AnyPopupId = 1 << 10, // For IsPopupOpen(): ignore the ImGuiID parameter and test for any popup.
	ImGuiPopupFlags_AnyPopupLevel = 1 << 11, // For IsPopupOpen(): search/test at any level of the popup stack (default test in the current level)
	ImGuiPopupFlags_AnyPopup = ImGuiPopupFlags_AnyPopupId | ImGuiPopupFlags_AnyPopupLevel,
}

// Flags for ImGui::Selectable()
ImGuiSelectableFlags_ :: enum i32 {
	ImGuiSelectableFlags_None = 0,
	ImGuiSelectableFlags_NoAutoClosePopups = 1 << 0, // Clicking this doesn't close parent popup window (overrides ImGuiItemFlags_AutoClosePopups)
	ImGuiSelectableFlags_SpanAllColumns = 1 << 1, // Frame will span all columns of its container table (text will still fit in current column)
	ImGuiSelectableFlags_AllowDoubleClick = 1 << 2, // Generate press events on double clicks too
	ImGuiSelectableFlags_Disabled = 1 << 3, // Cannot be selected, display grayed out text
	ImGuiSelectableFlags_AllowOverlap = 1 << 4, // (WIP) Hit testing to allow subsequent widgets to overlap this one
	ImGuiSelectableFlags_Highlight = 1 << 5, // Make the item be displayed as if it is hovered


}

// Flags for ImGui::BeginCombo()
ImGuiComboFlags_ :: enum i32 {
	ImGuiComboFlags_None = 0,
	ImGuiComboFlags_PopupAlignLeft = 1 << 0, // Align the popup toward the left by default
	ImGuiComboFlags_HeightSmall = 1 << 1, // Max ~4 items visible. Tip: If you want your combo popup to be a specific size you can use SetNextWindowSizeConstraints() prior to calling BeginCombo()
	ImGuiComboFlags_HeightRegular = 1 << 2, // Max ~8 items visible (default)
	ImGuiComboFlags_HeightLarge = 1 << 3, // Max ~20 items visible
	ImGuiComboFlags_HeightLargest = 1 << 4, // As many fitting items as possible
	ImGuiComboFlags_NoArrowButton = 1 << 5, // Display on the preview box without the square arrow button
	ImGuiComboFlags_NoPreview = 1 << 6, // Display only a square arrow button
	ImGuiComboFlags_WidthFitPreview = 1 << 7, // Width dynamically calculated from preview contents
	ImGuiComboFlags_HeightMask_ = ImGuiComboFlags_HeightSmall | ImGuiComboFlags_HeightRegular | ImGuiComboFlags_HeightLarge | ImGuiComboFlags_HeightLargest,
}

// Flags for ImGui::BeginTabBar()
ImGuiTabBarFlags_ :: enum i32 {
	ImGuiTabBarFlags_None = 0,
	ImGuiTabBarFlags_Reorderable = 1 << 0, // Allow manually dragging tabs to re-order them + New tabs are appended at the end of list
	ImGuiTabBarFlags_AutoSelectNewTabs = 1 << 1, // Automatically select new tabs when they appear
	ImGuiTabBarFlags_TabListPopupButton = 1 << 2, // Disable buttons to open the tab list popup
	ImGuiTabBarFlags_NoCloseWithMiddleMouseButton = 1 << 3, // Disable behavior of closing tabs (that are submitted with p_open != NULL) with middle mouse button. You may handle this behavior manually on user's side with if (IsItemHovered() && IsMouseClicked(2)) *p_open = false.
	ImGuiTabBarFlags_NoTabListScrollingButtons = 1 << 4, // Disable scrolling buttons (apply when fitting policy is ImGuiTabBarFlags_FittingPolicyScroll)
	ImGuiTabBarFlags_NoTooltip = 1 << 5, // Disable tooltips when hovering a tab
	ImGuiTabBarFlags_DrawSelectedOverline = 1 << 6, // Draw selected overline markers over selected tab
	ImGuiTabBarFlags_FittingPolicyResizeDown = 1 << 7, // Resize tabs when they don't fit
	ImGuiTabBarFlags_FittingPolicyScroll = 1 << 8, // Add scroll buttons when tabs don't fit
	ImGuiTabBarFlags_FittingPolicyMask_ = ImGuiTabBarFlags_FittingPolicyResizeDown | ImGuiTabBarFlags_FittingPolicyScroll,
	ImGuiTabBarFlags_FittingPolicyDefault_ = ImGuiTabBarFlags_FittingPolicyResizeDown,
}

// Flags for ImGui::BeginTabItem()
ImGuiTabItemFlags_ :: enum i32 {
	ImGuiTabItemFlags_None = 0,
	ImGuiTabItemFlags_UnsavedDocument = 1 << 0, // Display a dot next to the title + set ImGuiTabItemFlags_NoAssumedClosure.
	ImGuiTabItemFlags_SetSelected = 1 << 1, // Trigger flag to programmatically make the tab selected when calling BeginTabItem()
	ImGuiTabItemFlags_NoCloseWithMiddleMouseButton = 1 << 2, // Disable behavior of closing tabs (that are submitted with p_open != NULL) with middle mouse button. You may handle this behavior manually on user's side with if (IsItemHovered() && IsMouseClicked(2)) *p_open = false.
	ImGuiTabItemFlags_NoPushId = 1 << 3, // Don't call PushID()/PopID() on BeginTabItem()/EndTabItem()
	ImGuiTabItemFlags_NoTooltip = 1 << 4, // Disable tooltip for the given tab
	ImGuiTabItemFlags_NoReorder = 1 << 5, // Disable reordering this tab or having another tab cross over this tab
	ImGuiTabItemFlags_Leading = 1 << 6, // Enforce the tab position to the left of the tab bar (after the tab list popup button)
	ImGuiTabItemFlags_Trailing = 1 << 7, // Enforce the tab position to the right of the tab bar (before the scrolling buttons)
	ImGuiTabItemFlags_NoAssumedClosure = 1 << 8, // Tab is selected when trying to close + closure is not immediately assumed (will wait for user to stop submitting the tab). Otherwise closure is assumed when pressing the X, so if you keep submitting the tab may reappear at end of tab bar.
}

// Flags for ImGui::IsWindowFocused()
ImGuiFocusedFlags_ :: enum i32 {
	ImGuiFocusedFlags_None = 0,
	ImGuiFocusedFlags_ChildWindows = 1 << 0, // Return true if any children of the window is focused
	ImGuiFocusedFlags_RootWindow = 1 << 1, // Test from root window (top most parent of the current hierarchy)
	ImGuiFocusedFlags_AnyWindow = 1 << 2, // Return true if any window is focused. Important: If you are trying to tell how to dispatch your low-level inputs, do NOT use this. Use 'io.WantCaptureMouse' instead! Please read the FAQ!
	ImGuiFocusedFlags_NoPopupHierarchy = 1 << 3, // Do not consider popup hierarchy (do not treat popup emitter as parent of popup) (when used with _ChildWindows or _RootWindow)
	ImGuiFocusedFlags_DockHierarchy = 1 << 4, // Consider docking hierarchy (treat dockspace host as parent of docked window) (when used with _ChildWindows or _RootWindow)
	ImGuiFocusedFlags_RootAndChildWindows = ImGuiFocusedFlags_RootWindow | ImGuiFocusedFlags_ChildWindows,
}

// Flags for ImGui::IsItemHovered(), ImGui::IsWindowHovered()
// Note: if you are trying to check whether your mouse should be dispatched to Dear ImGui or to your app, you should use 'io.WantCaptureMouse' instead! Please read the FAQ!
// Note: windows with the ImGuiWindowFlags_NoInputs flag are ignored by IsWindowHovered() calls.
ImGuiHoveredFlags_ :: enum i32 {
	ImGuiHoveredFlags_None = 0, // Return true if directly over the item/window, not obstructed by another window, not obstructed by an active popup or modal blocking inputs under them.
	ImGuiHoveredFlags_ChildWindows = 1 << 0, // IsWindowHovered() only: Return true if any children of the window is hovered
	ImGuiHoveredFlags_RootWindow = 1 << 1, // IsWindowHovered() only: Test from root window (top most parent of the current hierarchy)
	ImGuiHoveredFlags_AnyWindow = 1 << 2, // IsWindowHovered() only: Return true if any window is hovered
	ImGuiHoveredFlags_NoPopupHierarchy = 1 << 3, // IsWindowHovered() only: Do not consider popup hierarchy (do not treat popup emitter as parent of popup) (when used with _ChildWindows or _RootWindow)
	ImGuiHoveredFlags_DockHierarchy = 1 << 4, // IsWindowHovered() only: Consider docking hierarchy (treat dockspace host as parent of docked window) (when used with _ChildWindows or _RootWindow)
	ImGuiHoveredFlags_AllowWhenBlockedByPopup = 1 << 5, // Return true even if a popup window is normally blocking access to this item/window
	//ImGuiHoveredFlags_AllowWhenBlockedByModal     = 1 << 6,   // Return true even if a modal popup window is normally blocking access to this item/window. FIXME-TODO: Unavailable yet.
	ImGuiHoveredFlags_AllowWhenBlockedByActiveItem = 1 << 7, // Return true even if an active item is blocking access to this item/window. Useful for Drag and Drop patterns.
	ImGuiHoveredFlags_AllowWhenOverlappedByItem = 1 << 8, // IsItemHovered() only: Return true even if the item uses AllowOverlap mode and is overlapped by another hoverable item.
	ImGuiHoveredFlags_AllowWhenOverlappedByWindow = 1 << 9, // IsItemHovered() only: Return true even if the position is obstructed or overlapped by another window.
	ImGuiHoveredFlags_AllowWhenDisabled = 1 << 10, // IsItemHovered() only: Return true even if the item is disabled
	ImGuiHoveredFlags_NoNavOverride = 1 << 11, // IsItemHovered() only: Disable using keyboard/gamepad navigation state when active, always query mouse
	ImGuiHoveredFlags_AllowWhenOverlapped = ImGuiHoveredFlags_AllowWhenOverlappedByItem | ImGuiHoveredFlags_AllowWhenOverlappedByWindow,
	ImGuiHoveredFlags_RectOnly = ImGuiHoveredFlags_AllowWhenBlockedByPopup | ImGuiHoveredFlags_AllowWhenBlockedByActiveItem | ImGuiHoveredFlags_AllowWhenOverlapped,
	ImGuiHoveredFlags_RootAndChildWindows = ImGuiHoveredFlags_RootWindow | ImGuiHoveredFlags_ChildWindows,

	// Tooltips mode
	// - typically used in IsItemHovered() + SetTooltip() sequence.
	// - this is a shortcut to pull flags from 'style.HoverFlagsForTooltipMouse' or 'style.HoverFlagsForTooltipNav' where you can reconfigure desired behavior.
	//   e.g. 'TooltipHoveredFlagsForMouse' defaults to 'ImGuiHoveredFlags_Stationary | ImGuiHoveredFlags_DelayShort'.
	// - for frequently actioned or hovered items providing a tooltip, you want may to use ImGuiHoveredFlags_ForTooltip (stationary + delay) so the tooltip doesn't show too often.
	// - for items which main purpose is to be hovered, or items with low affordance, or in less consistent apps, prefer no delay or shorter delay.
	ImGuiHoveredFlags_ForTooltip = 1 << 12, // Shortcut for standard flags when using IsItemHovered() + SetTooltip() sequence.

	// (Advanced) Mouse Hovering delays.
	// - generally you can use ImGuiHoveredFlags_ForTooltip to use application-standardized flags.
	// - use those if you need specific overrides.
	ImGuiHoveredFlags_Stationary = 1 << 13, // Require mouse to be stationary for style.HoverStationaryDelay (~0.15 sec) _at least one time_. After this, can move on same item/window. Using the stationary test tends to reduces the need for a long delay.
	ImGuiHoveredFlags_DelayNone = 1 << 14, // IsItemHovered() only: Return true immediately (default). As this is the default you generally ignore this.
	ImGuiHoveredFlags_DelayShort = 1 << 15, // IsItemHovered() only: Return true after style.HoverDelayShort elapsed (~0.15 sec) (shared between items) + requires mouse to be stationary for style.HoverStationaryDelay (once per item).
	ImGuiHoveredFlags_DelayNormal = 1 << 16, // IsItemHovered() only: Return true after style.HoverDelayNormal elapsed (~0.40 sec) (shared between items) + requires mouse to be stationary for style.HoverStationaryDelay (once per item).
	ImGuiHoveredFlags_NoSharedDelay = 1 << 17, // IsItemHovered() only: Disable shared delay system where moving from one item to the next keeps the previous timer for a short time (standard for tooltips with long delays)
}

// Flags for ImGui::DockSpace(), shared/inherited by child nodes.
// (Some flags can be applied to individual nodes directly)
// FIXME-DOCK: Also see ImGuiDockNodeFlagsPrivate_ which may involve using the WIP and internal DockBuilder api.
ImGuiDockNodeFlags_ :: enum i32 {
	ImGuiDockNodeFlags_None = 0,
	ImGuiDockNodeFlags_KeepAliveOnly = 1 << 0, //       // Don't display the dockspace node but keep it alive. Windows docked into this dockspace node won't be undocked.
	//ImGuiDockNodeFlags_NoCentralNode              = 1 << 1,   //       // Disable Central Node (the node which can stay empty)
	ImGuiDockNodeFlags_NoDockingOverCentralNode = 1 << 2, //       // Disable docking over the Central Node, which will be always kept empty.
	ImGuiDockNodeFlags_PassthruCentralNode = 1 << 3, //       // Enable passthru dockspace: 1) DockSpace() will render a ImGuiCol_WindowBg background covering everything excepted the Central Node when empty. Meaning the host window should probably use SetNextWindowBgAlpha(0.0f) prior to Begin() when using this. 2) When Central Node is empty: let inputs pass-through + won't display a DockingEmptyBg background. See demo for details.
	ImGuiDockNodeFlags_NoDockingSplit = 1 << 4, //       // Disable other windows/nodes from splitting this node.
	ImGuiDockNodeFlags_NoResize = 1 << 5, // Saved // Disable resizing node using the splitter/separators. Useful with programmatically setup dockspaces.
	ImGuiDockNodeFlags_AutoHideTabBar = 1 << 6, //       // Tab bar will automatically hide when there is a single window in the dock node.
	ImGuiDockNodeFlags_NoUndocking = 1 << 7, //       // Disable undocking this node.


}

// Flags for ImGui::BeginDragDropSource(), ImGui::AcceptDragDropPayload()
ImGuiDragDropFlags_ :: enum i32 {
	ImGuiDragDropFlags_None = 0,
	// BeginDragDropSource() flags
	ImGuiDragDropFlags_SourceNoPreviewTooltip = 1 << 0, // Disable preview tooltip. By default, a successful call to BeginDragDropSource opens a tooltip so you can display a preview or description of the source contents. This flag disables this behavior.
	ImGuiDragDropFlags_SourceNoDisableHover = 1 << 1, // By default, when dragging we clear data so that IsItemHovered() will return false, to avoid subsequent user code submitting tooltips. This flag disables this behavior so you can still call IsItemHovered() on the source item.
	ImGuiDragDropFlags_SourceNoHoldToOpenOthers = 1 << 2, // Disable the behavior that allows to open tree nodes and collapsing header by holding over them while dragging a source item.
	ImGuiDragDropFlags_SourceAllowNullID = 1 << 3, // Allow items such as Text(), Image() that have no unique identifier to be used as drag source, by manufacturing a temporary identifier based on their window-relative position. This is extremely unusual within the dear imgui ecosystem and so we made it explicit.
	ImGuiDragDropFlags_SourceExtern = 1 << 4, // External source (from outside of dear imgui), won't attempt to read current item/window info. Will always return true. Only one Extern source can be active simultaneously.
	ImGuiDragDropFlags_PayloadAutoExpire = 1 << 5, // Automatically expire the payload if the source cease to be submitted (otherwise payloads are persisting while being dragged)
	ImGuiDragDropFlags_PayloadNoCrossContext = 1 << 6, // Hint to specify that the payload may not be copied outside current dear imgui context.
	ImGuiDragDropFlags_PayloadNoCrossProcess = 1 << 7, // Hint to specify that the payload may not be copied outside current process.
	// AcceptDragDropPayload() flags
	ImGuiDragDropFlags_AcceptBeforeDelivery = 1 << 10, // AcceptDragDropPayload() will returns true even before the mouse button is released. You can then call IsDelivery() to test if the payload needs to be delivered.
	ImGuiDragDropFlags_AcceptNoDrawDefaultRect = 1 << 11, // Do not draw the default highlight rectangle when hovering over target.
	ImGuiDragDropFlags_AcceptNoPreviewTooltip = 1 << 12, // Request hiding the BeginDragDropSource tooltip from the BeginDragDropTarget site.
	ImGuiDragDropFlags_AcceptPeekOnly = ImGuiDragDropFlags_AcceptBeforeDelivery | ImGuiDragDropFlags_AcceptNoDrawDefaultRect, // For peeking ahead and inspecting the payload before delivery.


}

// Standard Drag and Drop payload types. You can define you own payload types using short strings. Types starting with '_' are defined by Dear ImGui.
IMGUI_PAYLOAD_TYPE_COLOR_3F :: "_COL3F"// float[3]: Standard type for colors, without alpha. User code may use this type.
IMGUI_PAYLOAD_TYPE_COLOR_4F :: "_COL4F"// float[4]: Standard type for colors. User code may use this type.

// A primary data type
ImGuiDataType_ :: enum i32 {
	ImGuiDataType_S8, // signed char / char (with sensible compilers)
	ImGuiDataType_U8, // unsigned char
	ImGuiDataType_S16, // short
	ImGuiDataType_U16, // unsigned short
	ImGuiDataType_S32, // int
	ImGuiDataType_U32, // unsigned int
	ImGuiDataType_S64, // long long / __int64
	ImGuiDataType_U64, // unsigned long long / unsigned __int64
	ImGuiDataType_Float, // float
	ImGuiDataType_Double, // double
	ImGuiDataType_Bool, // bool (provided for user convenience, not supported by scalar widgets)
	ImGuiDataType_String, // char* (provided for user convenience, not supported by scalar widgets)
	ImGuiDataType_COUNT,
}

// Enumerations
// - We don't use strongly typed enums much because they add constraints (can't extend in private code, can't store typed in bit fields, extra casting on iteration)
// - Tip: Use your programming IDE navigation facilities on the names in the _central column_ below to find the actual flags/enum lists!
//   - In Visual Studio: CTRL+comma ("Edit.GoToAll") can follow symbols inside comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
//   - In Visual Studio w/ Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols inside comments.
//   - In VS Code, CLion, etc.: CTRL+click can follow symbols inside comments.
// -> enum ImGuiDir              // Enum: A cardinal direction (Left, Right, Up, Down)
// A cardinal direction
ImGuiDir :: enum i32 {
	ImGuiDir_None = -1,
	ImGuiDir_Left = 0,
	ImGuiDir_Right = 1,
	ImGuiDir_Up = 2,
	ImGuiDir_Down = 3,
	ImGuiDir_COUNT,
}

// -> enum ImGuiSortDirection    // Enum: A sorting direction (ascending or descending)
// A sorting direction
ImGuiSortDirection :: enum ImU8 {
	ImGuiSortDirection_None = 0,
	ImGuiSortDirection_Ascending = 1, // Ascending = 0->9, A->Z etc.
	ImGuiSortDirection_Descending = 2,
}

// -> enum ImGuiKey              // Enum: A key identifier (ImGuiKey_XXX or ImGuiMod_XXX value)
// A key identifier (ImGuiKey_XXX or ImGuiMod_XXX value): can represent Keyboard, Mouse and Gamepad values.
// All our named keys are >= 512. Keys value 0 to 511 are left unused and were legacy native/opaque key values (< 1.87).
// Support for legacy keys was completely removed in 1.91.5.
// Read details about the 1.87+ transition : https://github.com/ocornut/imgui/issues/4921
// Note that "Keys" related to physical keys and are not the same concept as input "Characters", the later are submitted via io.AddInputCharacter().
// The keyboard key enum values are named after the keys on a standard US keyboard, and on other keyboard types the keys reported may not match the keycaps.
ImGuiKey :: enum i32 {
	// Keyboard
	ImGuiKey_None = 0,
	ImGuiKey_NamedKey_BEGIN = 512, // First valid key value (other than 0)

	ImGuiKey_Tab = 512, // == ImGuiKey_NamedKey_BEGIN
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
	ImGuiKey_Apostrophe, // '
	ImGuiKey_Comma, // ,
	ImGuiKey_Minus, // -
	ImGuiKey_Period, // .
	ImGuiKey_Slash, // /
	ImGuiKey_Semicolon, // ;
	ImGuiKey_Equal, // =
	ImGuiKey_LeftBracket, // [
	ImGuiKey_Backslash, // \ (this text inhibit multiline comment caused by backslash)
	ImGuiKey_RightBracket, // ]
	ImGuiKey_GraveAccent, // `
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
	ImGuiKey_AppBack, // Available on some keyboard/mouses. Often referred as "Browser Back"
	ImGuiKey_AppForward,

	// Gamepad (some of those are analog values, 0.0f to 1.0f)                          // NAVIGATION ACTION
	// (download controller mapping PNG/PSD at http://dearimgui.com/controls_sheets)
	ImGuiKey_GamepadStart, // Menu (Xbox)      + (Switch)   Start/Options (PS)
	ImGuiKey_GamepadBack, // View (Xbox)      - (Switch)   Share (PS)
	ImGuiKey_GamepadFaceLeft, // X (Xbox)         Y (Switch)   Square (PS)        // Tap: Toggle Menu. Hold: Windowing mode (Focus/Move/Resize windows)
	ImGuiKey_GamepadFaceRight, // B (Xbox)         A (Switch)   Circle (PS)        // Cancel / Close / Exit
	ImGuiKey_GamepadFaceUp, // Y (Xbox)         X (Switch)   Triangle (PS)      // Text Input / On-screen Keyboard
	ImGuiKey_GamepadFaceDown, // A (Xbox)         B (Switch)   Cross (PS)         // Activate / Open / Toggle / Tweak
	ImGuiKey_GamepadDpadLeft, // D-pad Left                                       // Move / Tweak / Resize Window (in Windowing mode)
	ImGuiKey_GamepadDpadRight, // D-pad Right                                      // Move / Tweak / Resize Window (in Windowing mode)
	ImGuiKey_GamepadDpadUp, // D-pad Up                                         // Move / Tweak / Resize Window (in Windowing mode)
	ImGuiKey_GamepadDpadDown, // D-pad Down                                       // Move / Tweak / Resize Window (in Windowing mode)
	ImGuiKey_GamepadL1, // L Bumper (Xbox)  L (Switch)   L1 (PS)            // Tweak Slower / Focus Previous (in Windowing mode)
	ImGuiKey_GamepadR1, // R Bumper (Xbox)  R (Switch)   R1 (PS)            // Tweak Faster / Focus Next (in Windowing mode)
	ImGuiKey_GamepadL2, // L Trig. (Xbox)   ZL (Switch)  L2 (PS) [Analog]
	ImGuiKey_GamepadR2, // R Trig. (Xbox)   ZR (Switch)  R2 (PS) [Analog]
	ImGuiKey_GamepadL3, // L Stick (Xbox)   L3 (Switch)  L3 (PS)
	ImGuiKey_GamepadR3, // R Stick (Xbox)   R3 (Switch)  R3 (PS)
	ImGuiKey_GamepadLStickLeft, // [Analog]                                         // Move Window (in Windowing mode)
	ImGuiKey_GamepadLStickRight, // [Analog]                                         // Move Window (in Windowing mode)
	ImGuiKey_GamepadLStickUp, // [Analog]                                         // Move Window (in Windowing mode)
	ImGuiKey_GamepadLStickDown, // [Analog]                                         // Move Window (in Windowing mode)
	ImGuiKey_GamepadRStickLeft, // [Analog]
	ImGuiKey_GamepadRStickRight, // [Analog]
	ImGuiKey_GamepadRStickUp, // [Analog]
	ImGuiKey_GamepadRStickDown, // [Analog]

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
	ImGuiMod_None = 0,
	ImGuiMod_Ctrl = 1 << 12, // Ctrl (non-macOS), Cmd (macOS)
	ImGuiMod_Shift = 1 << 13, // Shift
	ImGuiMod_Alt = 1 << 14, // Option/Menu
	ImGuiMod_Super = 1 << 15, // Windows/Super (non-macOS), Ctrl (macOS)
	ImGuiMod_Mask_ = 0xF000, // 4-bits

	// [Internal] If you need to iterate all keys (for e.g. an input mapper) you may use ImGuiKey_NamedKey_BEGIN..ImGuiKey_NamedKey_END.
	ImGuiKey_NamedKey_COUNT = ImGuiKey_NamedKey_END - ImGuiKey_NamedKey_BEGIN,
	//ImGuiKey_KeysData_SIZE        = ImGuiKey_NamedKey_COUNT,  // Size of KeysData[]: only hold named keys
	//ImGuiKey_KeysData_OFFSET      = ImGuiKey_NamedKey_BEGIN,  // Accesses to io.KeysData[] must use (key - ImGuiKey_NamedKey_BEGIN) index.


}

// Flags for Shortcut(), SetNextItemShortcut(),
// (and for upcoming extended versions of IsKeyPressed(), IsMouseClicked(), Shortcut(), SetKeyOwner(), SetItemKeyOwner() that are still in imgui_internal.h)
// Don't mistake with ImGuiInputTextFlags! (which is for ImGui::InputText() function)
ImGuiInputFlags_ :: enum i32 {
	ImGuiInputFlags_None = 0,
	ImGuiInputFlags_Repeat = 1 << 0, // Enable repeat. Return true on successive repeats. Default for legacy IsKeyPressed(). NOT Default for legacy IsMouseClicked(). MUST BE == 1.

	// Flags for Shortcut(), SetNextItemShortcut()
	// - Routing policies: RouteGlobal+OverActive >> RouteActive or RouteFocused (if owner is active item) >> RouteGlobal+OverFocused >> RouteFocused (if in focused window stack) >> RouteGlobal.
	// - Default policy is RouteFocused. Can select only 1 policy among all available.
	ImGuiInputFlags_RouteActive = 1 << 10, // Route to active item only.
	ImGuiInputFlags_RouteFocused = 1 << 11, // Route to windows in the focus stack (DEFAULT). Deep-most focused window takes inputs. Active item takes inputs over deep-most focused window.
	ImGuiInputFlags_RouteGlobal = 1 << 12, // Global route (unless a focused window or active item registered the route).
	ImGuiInputFlags_RouteAlways = 1 << 13, // Do not register route, poll keys directly.
	// - Routing options
	ImGuiInputFlags_RouteOverFocused = 1 << 14, // Option: global route: higher priority than focused route (unless active item in focused route).
	ImGuiInputFlags_RouteOverActive = 1 << 15, // Option: global route: higher priority than active item. Unlikely you need to use that: will interfere with every active items, e.g. CTRL+A registered by InputText will be overridden by this. May not be fully honored as user/internal code is likely to always assume they can access keys when active.
	ImGuiInputFlags_RouteUnlessBgFocused = 1 << 16, // Option: global route: will not be applied if underlying background/void is focused (== no Dear ImGui windows are focused). Useful for overlay applications.
	ImGuiInputFlags_RouteFromRootWindow = 1 << 17, // Option: route evaluated from the point of view of root window rather than current window.

	// Flags for SetNextItemShortcut()
	ImGuiInputFlags_Tooltip = 1 << 18, // Automatically display a tooltip when hovering item [BETA] Unsure of right api (opt-in/opt-out)
}

// Configuration flags stored in io.ConfigFlags. Set by user/application.
ImGuiConfigFlags_ :: enum i32 {
	ImGuiConfigFlags_None = 0,
	ImGuiConfigFlags_NavEnableKeyboard = 1 << 0, // Master keyboard navigation enable flag. Enable full Tabbing + directional arrows + space/enter to activate.
	ImGuiConfigFlags_NavEnableGamepad = 1 << 1, // Master gamepad navigation enable flag. Backend also needs to set ImGuiBackendFlags_HasGamepad.
	ImGuiConfigFlags_NoMouse = 1 << 4, // Instruct dear imgui to disable mouse inputs and interactions.
	ImGuiConfigFlags_NoMouseCursorChange = 1 << 5, // Instruct backend to not alter mouse cursor shape and visibility. Use if the backend cursor changes are interfering with yours and you don't want to use SetMouseCursor() to change mouse cursor. You may want to honor requests from imgui by reading GetMouseCursor() yourself instead.
	ImGuiConfigFlags_NoKeyboard = 1 << 6, // Instruct dear imgui to disable keyboard inputs and interactions. This is done by ignoring keyboard events and clearing existing states.

	// [BETA] Docking
	ImGuiConfigFlags_DockingEnable = 1 << 7, // Docking enable flags.

	// [BETA] Viewports
	// When using viewports it is recommended that your default value for ImGuiCol_WindowBg is opaque (Alpha=1.0) so transition to a viewport won't be noticeable.
	ImGuiConfigFlags_ViewportsEnable = 1 << 10, // Viewport enable flags (require both ImGuiBackendFlags_PlatformHasViewports + ImGuiBackendFlags_RendererHasViewports set by the respective backends)
	ImGuiConfigFlags_DpiEnableScaleViewports = 1 << 14, // [BETA: Don't use] FIXME-DPI: Reposition and resize imgui windows when the DpiScale of a viewport changed (mostly useful for the main viewport hosting other window). Note that resizing the main window itself is up to your application.
	ImGuiConfigFlags_DpiEnableScaleFonts = 1 << 15, // [BETA: Don't use] FIXME-DPI: Request bitmap-scaled fonts to match DpiScale. This is a very low-quality workaround. The correct way to handle DPI is _currently_ to replace the atlas and/or fonts in the Platform_OnChangedViewport callback, but this is all early work in progress.

	// User storage (to allow your backend/engine to communicate to code that may be shared between multiple projects. Those flags are NOT used by core Dear ImGui)
	ImGuiConfigFlags_IsSRGB = 1 << 20, // Application is SRGB-aware.
	ImGuiConfigFlags_IsTouchScreen = 1 << 21, // Application is using a touch screen instead of a mouse.


}

// Backend capabilities flags stored in io.BackendFlags. Set by imgui_impl_xxx or custom backend.
ImGuiBackendFlags_ :: enum i32 {
	ImGuiBackendFlags_None = 0,
	ImGuiBackendFlags_HasGamepad = 1 << 0, // Backend Platform supports gamepad and currently has one connected.
	ImGuiBackendFlags_HasMouseCursors = 1 << 1, // Backend Platform supports honoring GetMouseCursor() value to change the OS cursor shape.
	ImGuiBackendFlags_HasSetMousePos = 1 << 2, // Backend Platform supports io.WantSetMousePos requests to reposition the OS mouse position (only used if io.ConfigNavMoveSetMousePos is set).
	ImGuiBackendFlags_RendererHasVtxOffset = 1 << 3, // Backend Renderer supports ImDrawCmd::VtxOffset. This enables output of large meshes (64K+ vertices) while still using 16-bit indices.

	// [BETA] Viewports
	ImGuiBackendFlags_PlatformHasViewports = 1 << 10, // Backend Platform supports multiple viewports.
	ImGuiBackendFlags_HasMouseHoveredViewport = 1 << 11, // Backend Platform supports calling io.AddMouseViewportEvent() with the viewport under the mouse. IF POSSIBLE, ignore viewports with the ImGuiViewportFlags_NoInputs flag (Win32 backend, GLFW 3.30+ backend can do this, SDL backend cannot). If this cannot be done, Dear ImGui needs to use a flawed heuristic to find the viewport under.
	ImGuiBackendFlags_RendererHasViewports = 1 << 12, // Backend Renderer supports multiple viewports.
}

// Enumeration for PushStyleColor() / PopStyleColor()
ImGuiCol_ :: enum i32 {
	ImGuiCol_Text,
	ImGuiCol_TextDisabled,
	ImGuiCol_WindowBg, // Background of normal windows
	ImGuiCol_ChildBg, // Background of child windows
	ImGuiCol_PopupBg, // Background of popups, menus, tooltips windows
	ImGuiCol_Border,
	ImGuiCol_BorderShadow,
	ImGuiCol_FrameBg, // Background of checkbox, radio button, plot, slider, text input
	ImGuiCol_FrameBgHovered,
	ImGuiCol_FrameBgActive,
	ImGuiCol_TitleBg, // Title bar
	ImGuiCol_TitleBgActive, // Title bar when focused
	ImGuiCol_TitleBgCollapsed, // Title bar when collapsed
	ImGuiCol_MenuBarBg,
	ImGuiCol_ScrollbarBg,
	ImGuiCol_ScrollbarGrab,
	ImGuiCol_ScrollbarGrabHovered,
	ImGuiCol_ScrollbarGrabActive,
	ImGuiCol_CheckMark, // Checkbox tick and RadioButton circle
	ImGuiCol_SliderGrab,
	ImGuiCol_SliderGrabActive,
	ImGuiCol_Button,
	ImGuiCol_ButtonHovered,
	ImGuiCol_ButtonActive,
	ImGuiCol_Header, // Header* colors are used for CollapsingHeader, TreeNode, Selectable, MenuItem
	ImGuiCol_HeaderHovered,
	ImGuiCol_HeaderActive,
	ImGuiCol_Separator,
	ImGuiCol_SeparatorHovered,
	ImGuiCol_SeparatorActive,
	ImGuiCol_ResizeGrip, // Resize grip in lower-right and lower-left corners of windows.
	ImGuiCol_ResizeGripHovered,
	ImGuiCol_ResizeGripActive,
	ImGuiCol_TabHovered, // Tab background, when hovered
	ImGuiCol_Tab, // Tab background, when tab-bar is focused & tab is unselected
	ImGuiCol_TabSelected, // Tab background, when tab-bar is focused & tab is selected
	ImGuiCol_TabSelectedOverline, // Tab horizontal overline, when tab-bar is focused & tab is selected
	ImGuiCol_TabDimmed, // Tab background, when tab-bar is unfocused & tab is unselected
	ImGuiCol_TabDimmedSelected, // Tab background, when tab-bar is unfocused & tab is selected
	ImGuiCol_TabDimmedSelectedOverline, //..horizontal overline, when tab-bar is unfocused & tab is selected
	ImGuiCol_DockingPreview, // Preview overlay color when about to docking something
	ImGuiCol_DockingEmptyBg, // Background color for empty node (e.g. CentralNode with no window docked into it)
	ImGuiCol_PlotLines,
	ImGuiCol_PlotLinesHovered,
	ImGuiCol_PlotHistogram,
	ImGuiCol_PlotHistogramHovered,
	ImGuiCol_TableHeaderBg, // Table header background
	ImGuiCol_TableBorderStrong, // Table outer and header borders (prefer using Alpha=1.0 here)
	ImGuiCol_TableBorderLight, // Table inner borders (prefer using Alpha=1.0 here)
	ImGuiCol_TableRowBg, // Table row background (even rows)
	ImGuiCol_TableRowBgAlt, // Table row background (odd rows)
	ImGuiCol_TextLink, // Hyperlink color
	ImGuiCol_TextSelectedBg,
	ImGuiCol_DragDropTarget, // Rectangle highlighting a drop target
	ImGuiCol_NavCursor, // Color of keyboard/gamepad navigation cursor/rectangle, when visible
	ImGuiCol_NavWindowingHighlight, // Highlight window when using CTRL+TAB
	ImGuiCol_NavWindowingDimBg, // Darken/colorize entire screen behind the CTRL+TAB window list, when active
	ImGuiCol_ModalWindowDimBg, // Darken/colorize entire screen behind a modal window, when one is active
	ImGuiCol_COUNT,


}

// Enumeration for PushStyleVar() / PopStyleVar() to temporarily modify the ImGuiStyle structure.
// - The enum only refers to fields of ImGuiStyle which makes sense to be pushed/popped inside UI code.
//   During initialization or between frames, feel free to just poke into ImGuiStyle directly.
// - Tip: Use your programming IDE navigation facilities on the names in the _second column_ below to find the actual members and their description.
//   - In Visual Studio: CTRL+comma ("Edit.GoToAll") can follow symbols inside comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
//   - In Visual Studio w/ Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols inside comments.
//   - In VS Code, CLion, etc.: CTRL+click can follow symbols inside comments.
// - When changing this enum, you need to update the associated internal table GStyleVarInfo[] accordingly. This is where we link enum values to members offset/type.
ImGuiStyleVar_ :: enum i32 {
	// Enum name -------------------------- // Member in ImGuiStyle structure (see ImGuiStyle for descriptions)
	ImGuiStyleVar_Alpha, // float     Alpha
	ImGuiStyleVar_DisabledAlpha, // float     DisabledAlpha
	ImGuiStyleVar_WindowPadding, // ImVec2    WindowPadding
	ImGuiStyleVar_WindowRounding, // float     WindowRounding
	ImGuiStyleVar_WindowBorderSize, // float     WindowBorderSize
	ImGuiStyleVar_WindowMinSize, // ImVec2    WindowMinSize
	ImGuiStyleVar_WindowTitleAlign, // ImVec2    WindowTitleAlign
	ImGuiStyleVar_ChildRounding, // float     ChildRounding
	ImGuiStyleVar_ChildBorderSize, // float     ChildBorderSize
	ImGuiStyleVar_PopupRounding, // float     PopupRounding
	ImGuiStyleVar_PopupBorderSize, // float     PopupBorderSize
	ImGuiStyleVar_FramePadding, // ImVec2    FramePadding
	ImGuiStyleVar_FrameRounding, // float     FrameRounding
	ImGuiStyleVar_FrameBorderSize, // float     FrameBorderSize
	ImGuiStyleVar_ItemSpacing, // ImVec2    ItemSpacing
	ImGuiStyleVar_ItemInnerSpacing, // ImVec2    ItemInnerSpacing
	ImGuiStyleVar_IndentSpacing, // float     IndentSpacing
	ImGuiStyleVar_CellPadding, // ImVec2    CellPadding
	ImGuiStyleVar_ScrollbarSize, // float     ScrollbarSize
	ImGuiStyleVar_ScrollbarRounding, // float     ScrollbarRounding
	ImGuiStyleVar_GrabMinSize, // float     GrabMinSize
	ImGuiStyleVar_GrabRounding, // float     GrabRounding
	ImGuiStyleVar_TabRounding, // float     TabRounding
	ImGuiStyleVar_TabBorderSize, // float     TabBorderSize
	ImGuiStyleVar_TabBarBorderSize, // float     TabBarBorderSize
	ImGuiStyleVar_TabBarOverlineSize, // float     TabBarOverlineSize
	ImGuiStyleVar_TableAngledHeadersAngle, // float     TableAngledHeadersAngle
	ImGuiStyleVar_TableAngledHeadersTextAlign, // ImVec2  TableAngledHeadersTextAlign
	ImGuiStyleVar_ButtonTextAlign, // ImVec2    ButtonTextAlign
	ImGuiStyleVar_SelectableTextAlign, // ImVec2    SelectableTextAlign
	ImGuiStyleVar_SeparatorTextBorderSize, // float     SeparatorTextBorderSize
	ImGuiStyleVar_SeparatorTextAlign, // ImVec2    SeparatorTextAlign
	ImGuiStyleVar_SeparatorTextPadding, // ImVec2    SeparatorTextPadding
	ImGuiStyleVar_DockingSeparatorSize, // float     DockingSeparatorSize
	ImGuiStyleVar_COUNT,
}

// Flags for InvisibleButton() [extended in imgui_internal.h]
ImGuiButtonFlags_ :: enum i32 {
	ImGuiButtonFlags_None = 0,
	ImGuiButtonFlags_MouseButtonLeft = 1 << 0, // React on left mouse button (default)
	ImGuiButtonFlags_MouseButtonRight = 1 << 1, // React on right mouse button
	ImGuiButtonFlags_MouseButtonMiddle = 1 << 2, // React on center mouse button
	ImGuiButtonFlags_MouseButtonMask_ = ImGuiButtonFlags_MouseButtonLeft | ImGuiButtonFlags_MouseButtonRight | ImGuiButtonFlags_MouseButtonMiddle, // [Internal]
	ImGuiButtonFlags_EnableNav = 1 << 3, // InvisibleButton(): do not disable navigation/tabbing. Otherwise disabled by default.
}

// Flags for ColorEdit3() / ColorEdit4() / ColorPicker3() / ColorPicker4() / ColorButton()
ImGuiColorEditFlags_ :: enum i32 {
	ImGuiColorEditFlags_None = 0,
	ImGuiColorEditFlags_NoAlpha = 1 << 1, //              // ColorEdit, ColorPicker, ColorButton: ignore Alpha component (will only read 3 components from the input pointer).
	ImGuiColorEditFlags_NoPicker = 1 << 2, //              // ColorEdit: disable picker when clicking on color square.
	ImGuiColorEditFlags_NoOptions = 1 << 3, //              // ColorEdit: disable toggling options menu when right-clicking on inputs/small preview.
	ImGuiColorEditFlags_NoSmallPreview = 1 << 4, //              // ColorEdit, ColorPicker: disable color square preview next to the inputs. (e.g. to show only the inputs)
	ImGuiColorEditFlags_NoInputs = 1 << 5, //              // ColorEdit, ColorPicker: disable inputs sliders/text widgets (e.g. to show only the small preview color square).
	ImGuiColorEditFlags_NoTooltip = 1 << 6, //              // ColorEdit, ColorPicker, ColorButton: disable tooltip when hovering the preview.
	ImGuiColorEditFlags_NoLabel = 1 << 7, //              // ColorEdit, ColorPicker: disable display of inline text label (the label is still forwarded to the tooltip and picker).
	ImGuiColorEditFlags_NoSidePreview = 1 << 8, //              // ColorPicker: disable bigger color preview on right side of the picker, use small color square preview instead.
	ImGuiColorEditFlags_NoDragDrop = 1 << 9, //              // ColorEdit: disable drag and drop target. ColorButton: disable drag and drop source.
	ImGuiColorEditFlags_NoBorder = 1 << 10, //              // ColorButton: disable border (which is enforced by default)

	// User Options (right-click on widget to change some of them).
	ImGuiColorEditFlags_AlphaBar = 1 << 16, //              // ColorEdit, ColorPicker: show vertical alpha bar/gradient in picker.
	ImGuiColorEditFlags_AlphaPreview = 1 << 17, //              // ColorEdit, ColorPicker, ColorButton: display preview as a transparent color over a checkerboard, instead of opaque.
	ImGuiColorEditFlags_AlphaPreviewHalf = 1 << 18, //              // ColorEdit, ColorPicker, ColorButton: display half opaque / half checkerboard, instead of opaque.
	ImGuiColorEditFlags_HDR = 1 << 19, //              // (WIP) ColorEdit: Currently only disable 0.0f..1.0f limits in RGBA edition (note: you probably want to use ImGuiColorEditFlags_Float flag as well).
	ImGuiColorEditFlags_DisplayRGB = 1 << 20, // [Display]    // ColorEdit: override _display_ type among RGB/HSV/Hex. ColorPicker: select any combination using one or more of RGB/HSV/Hex.
	ImGuiColorEditFlags_DisplayHSV = 1 << 21, // [Display]    // "
	ImGuiColorEditFlags_DisplayHex = 1 << 22, // [Display]    // "
	ImGuiColorEditFlags_Uint8 = 1 << 23, // [DataType]   // ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0..255.
	ImGuiColorEditFlags_Float = 1 << 24, // [DataType]   // ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0.0f..1.0f floats instead of 0..255 integers. No round-trip of value via integers.
	ImGuiColorEditFlags_PickerHueBar = 1 << 25, // [Picker]     // ColorPicker: bar for Hue, rectangle for Sat/Value.
	ImGuiColorEditFlags_PickerHueWheel = 1 << 26, // [Picker]     // ColorPicker: wheel for Hue, triangle for Sat/Value.
	ImGuiColorEditFlags_InputRGB = 1 << 27, // [Input]      // ColorEdit, ColorPicker: input and output data in RGB format.
	ImGuiColorEditFlags_InputHSV = 1 << 28, // [Input]      // ColorEdit, ColorPicker: input and output data in HSV format.

	// Defaults Options. You can set application defaults using SetColorEditOptions(). The intent is that you probably don't want to
	// override them in most of your calls. Let the user choose via the option menu and/or call SetColorEditOptions() once during startup.
	ImGuiColorEditFlags_DefaultOptions_ = ImGuiColorEditFlags_Uint8 | ImGuiColorEditFlags_DisplayRGB | ImGuiColorEditFlags_InputRGB | ImGuiColorEditFlags_PickerHueBar,

	// [Internal] Masks
	ImGuiColorEditFlags_DisplayMask_ = ImGuiColorEditFlags_DisplayRGB | ImGuiColorEditFlags_DisplayHSV | ImGuiColorEditFlags_DisplayHex,
	ImGuiColorEditFlags_DataTypeMask_ = ImGuiColorEditFlags_Uint8 | ImGuiColorEditFlags_Float,
	ImGuiColorEditFlags_PickerMask_ = ImGuiColorEditFlags_PickerHueWheel | ImGuiColorEditFlags_PickerHueBar,
	ImGuiColorEditFlags_InputMask_ = ImGuiColorEditFlags_InputRGB | ImGuiColorEditFlags_InputHSV,

	// Obsolete names
	//ImGuiColorEditFlags_RGB = ImGuiColorEditFlags_DisplayRGB, ImGuiColorEditFlags_HSV = ImGuiColorEditFlags_DisplayHSV, ImGuiColorEditFlags_HEX = ImGuiColorEditFlags_DisplayHex  // [renamed in 1.69]
}

// Flags for DragFloat(), DragInt(), SliderFloat(), SliderInt() etc.
// We use the same sets of flags for DragXXX() and SliderXXX() functions as the features are the same and it makes it easier to swap them.
// (Those are per-item flags. There is shared behavior flag too: ImGuiIO: io.ConfigDragClickToInputText)
ImGuiSliderFlags_ :: enum i32 {
	ImGuiSliderFlags_None = 0,
	ImGuiSliderFlags_Logarithmic = 1 << 5, // Make the widget logarithmic (linear otherwise). Consider using ImGuiSliderFlags_NoRoundToFormat with this if using a format-string with small amount of digits.
	ImGuiSliderFlags_NoRoundToFormat = 1 << 6, // Disable rounding underlying value to match precision of the display format string (e.g. %.3f values are rounded to those 3 digits).
	ImGuiSliderFlags_NoInput = 1 << 7, // Disable CTRL+Click or Enter key allowing to input text directly into the widget.
	ImGuiSliderFlags_WrapAround = 1 << 8, // Enable wrapping around from max to min and from min to max. Only supported by DragXXX() functions for now.
	ImGuiSliderFlags_ClampOnInput = 1 << 9, // Clamp value to min/max bounds when input manually with CTRL+Click. By default CTRL+Click allows going out of bounds.
	ImGuiSliderFlags_ClampZeroRange = 1 << 10, // Clamp even if min==max==0.0f. Otherwise due to legacy reason DragXXX functions don't clamp with those values. When your clamping limits are dynamic you almost always want to use it.
	ImGuiSliderFlags_NoSpeedTweaks = 1 << 11, // Disable keyboard modifiers altering tweak speed. Useful if you want to alter tweak speed yourself based on your own logic.
	ImGuiSliderFlags_AlwaysClamp = ImGuiSliderFlags_ClampOnInput | ImGuiSliderFlags_ClampZeroRange,
	ImGuiSliderFlags_InvalidMask_ = 0x7000000F, // [Internal] We treat using those bits as being potentially a 'float power' argument from the previous API that has got miscast to this enum, and will trigger an assert if needed.
}

// Identify a mouse button.
// Those values are guaranteed to be stable and we frequently use 0/1 directly. Named enums provided for convenience.
ImGuiMouseButton_ :: enum i32 {
	ImGuiMouseButton_Left = 0,
	ImGuiMouseButton_Right = 1,
	ImGuiMouseButton_Middle = 2,
	ImGuiMouseButton_COUNT = 5,
}

// Enumeration for GetMouseCursor()
// User code may request backend to display given cursor by calling SetMouseCursor(), which is why we have some cursors that are marked unused here
ImGuiMouseCursor_ :: enum i32 {
	ImGuiMouseCursor_None = -1,
	ImGuiMouseCursor_Arrow = 0,
	ImGuiMouseCursor_TextInput, // When hovering over InputText, etc.
	ImGuiMouseCursor_ResizeAll, // (Unused by Dear ImGui functions)
	ImGuiMouseCursor_ResizeNS, // When hovering over a horizontal border
	ImGuiMouseCursor_ResizeEW, // When hovering over a vertical border or a column
	ImGuiMouseCursor_ResizeNESW, // When hovering over the bottom-left corner of a window
	ImGuiMouseCursor_ResizeNWSE, // When hovering over the bottom-right corner of a window
	ImGuiMouseCursor_Hand, // (Unused by Dear ImGui functions. Use for e.g. hyperlinks)
	ImGuiMouseCursor_NotAllowed, // When hovering something with disallowed interaction. Usually a crossed circle.
	ImGuiMouseCursor_COUNT,
}

// -> enum ImGuiMouseSource      // Enum; A mouse input source identifier (Mouse, TouchScreen, Pen)
// Enumeration for AddMouseSourceEvent() actual source of Mouse Input data.
// Historically we use "Mouse" terminology everywhere to indicate pointer data, e.g. MousePos, IsMousePressed(), io.AddMousePosEvent()
// But that "Mouse" data can come from different source which occasionally may be useful for application to know about.
// You can submit a change of pointer type using io.AddMouseSourceEvent().
ImGuiMouseSource :: enum i32 {
	ImGuiMouseSource_Mouse = 0, // Input is coming from an actual mouse.
	ImGuiMouseSource_TouchScreen, // Input is coming from a touch screen (no hovering prior to initial press, less precise initial press aiming, dual-axis wheeling possible).
	ImGuiMouseSource_Pen, // Input is coming from a pressure/magnetic pen (often used in conjunction with high-sampling rates).
	ImGuiMouseSource_COUNT,
}

// Enumeration for ImGui::SetNextWindow***(), SetWindow***(), SetNextItem***() functions
// Represent a condition.
// Important: Treat as a regular enum! Do NOT combine multiple values using binary operators! All the functions above treat 0 as a shortcut to ImGuiCond_Always.
ImGuiCond_ :: enum i32 {
	ImGuiCond_None = 0, // No condition (always set the variable), same as _Always
	ImGuiCond_Always = 1 << 0, // No condition (always set the variable), same as _None
	ImGuiCond_Once = 1 << 1, // Set the variable once per runtime session (only the first call will succeed)
	ImGuiCond_FirstUseEver = 1 << 2, // Set the variable if the object/window has no persistently saved data (no entry in .ini file)
	ImGuiCond_Appearing = 1 << 3, // Set the variable if the object/window is appearing after being hidden/inactive (or the first time)
}

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
ImGuiTableFlags_ :: enum i32 {
	// Features
	ImGuiTableFlags_None = 0,
	ImGuiTableFlags_Resizable = 1 << 0, // Enable resizing columns.
	ImGuiTableFlags_Reorderable = 1 << 1, // Enable reordering columns in header row (need calling TableSetupColumn() + TableHeadersRow() to display headers)
	ImGuiTableFlags_Hideable = 1 << 2, // Enable hiding/disabling columns in context menu.
	ImGuiTableFlags_Sortable = 1 << 3, // Enable sorting. Call TableGetSortSpecs() to obtain sort specs. Also see ImGuiTableFlags_SortMulti and ImGuiTableFlags_SortTristate.
	ImGuiTableFlags_NoSavedSettings = 1 << 4, // Disable persisting columns order, width and sort settings in the .ini file.
	ImGuiTableFlags_ContextMenuInBody = 1 << 5, // Right-click on columns body/contents will display table context menu. By default it is available in TableHeadersRow().
	// Decorations
	ImGuiTableFlags_RowBg = 1 << 6, // Set each RowBg color with ImGuiCol_TableRowBg or ImGuiCol_TableRowBgAlt (equivalent of calling TableSetBgColor with ImGuiTableBgFlags_RowBg0 on each row manually)
	ImGuiTableFlags_BordersInnerH = 1 << 7, // Draw horizontal borders between rows.
	ImGuiTableFlags_BordersOuterH = 1 << 8, // Draw horizontal borders at the top and bottom.
	ImGuiTableFlags_BordersInnerV = 1 << 9, // Draw vertical borders between columns.
	ImGuiTableFlags_BordersOuterV = 1 << 10, // Draw vertical borders on the left and right sides.
	ImGuiTableFlags_BordersH = ImGuiTableFlags_BordersInnerH | ImGuiTableFlags_BordersOuterH, // Draw horizontal borders.
	ImGuiTableFlags_BordersV = ImGuiTableFlags_BordersInnerV | ImGuiTableFlags_BordersOuterV, // Draw vertical borders.
	ImGuiTableFlags_BordersInner = ImGuiTableFlags_BordersInnerV | ImGuiTableFlags_BordersInnerH, // Draw inner borders.
	ImGuiTableFlags_BordersOuter = ImGuiTableFlags_BordersOuterV | ImGuiTableFlags_BordersOuterH, // Draw outer borders.
	ImGuiTableFlags_Borders = ImGuiTableFlags_BordersInner | ImGuiTableFlags_BordersOuter, // Draw all borders.
	ImGuiTableFlags_NoBordersInBody = 1 << 11, // [ALPHA] Disable vertical borders in columns Body (borders will always appear in Headers). -> May move to style
	ImGuiTableFlags_NoBordersInBodyUntilResize = 1 << 12, // [ALPHA] Disable vertical borders in columns Body until hovered for resize (borders will always appear in Headers). -> May move to style
	// Sizing Policy (read above for defaults)
	ImGuiTableFlags_SizingFixedFit = 1 << 13, // Columns default to _WidthFixed or _WidthAuto (if resizable or not resizable), matching contents width.
	ImGuiTableFlags_SizingFixedSame = 2 << 13, // Columns default to _WidthFixed or _WidthAuto (if resizable or not resizable), matching the maximum contents width of all columns. Implicitly enable ImGuiTableFlags_NoKeepColumnsVisible.
	ImGuiTableFlags_SizingStretchProp = 3 << 13, // Columns default to _WidthStretch with default weights proportional to each columns contents widths.
	ImGuiTableFlags_SizingStretchSame = 4 << 13, // Columns default to _WidthStretch with default weights all equal, unless overridden by TableSetupColumn().
	// Sizing Extra Options
	ImGuiTableFlags_NoHostExtendX = 1 << 16, // Make outer width auto-fit to columns, overriding outer_size.x value. Only available when ScrollX/ScrollY are disabled and Stretch columns are not used.
	ImGuiTableFlags_NoHostExtendY = 1 << 17, // Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit). Only available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.
	ImGuiTableFlags_NoKeepColumnsVisible = 1 << 18, // Disable keeping column always minimally visible when ScrollX is off and table gets too small. Not recommended if columns are resizable.
	ImGuiTableFlags_PreciseWidths = 1 << 19, // Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.
	// Clipping
	ImGuiTableFlags_NoClip = 1 << 20, // Disable clipping rectangle for every individual columns (reduce draw command count, items will be able to overflow into other columns). Generally incompatible with TableSetupScrollFreeze().
	// Padding
	ImGuiTableFlags_PadOuterX = 1 << 21, // Default if BordersOuterV is on. Enable outermost padding. Generally desirable if you have headers.
	ImGuiTableFlags_NoPadOuterX = 1 << 22, // Default if BordersOuterV is off. Disable outermost padding.
	ImGuiTableFlags_NoPadInnerX = 1 << 23, // Disable inner padding between columns (double inner padding if BordersOuterV is on, single inner padding if BordersOuterV is off).
	// Scrolling
	ImGuiTableFlags_ScrollX = 1 << 24, // Enable horizontal scrolling. Require 'outer_size' parameter of BeginTable() to specify the container size. Changes default sizing policy. Because this creates a child window, ScrollY is currently generally recommended when using ScrollX.
	ImGuiTableFlags_ScrollY = 1 << 25, // Enable vertical scrolling. Require 'outer_size' parameter of BeginTable() to specify the container size.
	// Sorting
	ImGuiTableFlags_SortMulti = 1 << 26, // Hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).
	ImGuiTableFlags_SortTristate = 1 << 27, // Allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).
	// Miscellaneous
	ImGuiTableFlags_HighlightHoveredColumn = 1 << 28, // Highlight column headers when hovered (may evolve into a fuller highlight)

	// [Internal] Combinations and masks
	ImGuiTableFlags_SizingMask_ = ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_SizingFixedSame | ImGuiTableFlags_SizingStretchProp | ImGuiTableFlags_SizingStretchSame,
}

// Flags for ImGui::TableSetupColumn()
ImGuiTableColumnFlags_ :: enum i32 {
	// Input configuration flags
	ImGuiTableColumnFlags_None = 0,
	ImGuiTableColumnFlags_Disabled = 1 << 0, // Overriding/master disable flag: hide column, won't show in context menu (unlike calling TableSetColumnEnabled() which manipulates the user accessible state)
	ImGuiTableColumnFlags_DefaultHide = 1 << 1, // Default as a hidden/disabled column.
	ImGuiTableColumnFlags_DefaultSort = 1 << 2, // Default as a sorting column.
	ImGuiTableColumnFlags_WidthStretch = 1 << 3, // Column will stretch. Preferable with horizontal scrolling disabled (default if table sizing policy is _SizingStretchSame or _SizingStretchProp).
	ImGuiTableColumnFlags_WidthFixed = 1 << 4, // Column will not stretch. Preferable with horizontal scrolling enabled (default if table sizing policy is _SizingFixedFit and table is resizable).
	ImGuiTableColumnFlags_NoResize = 1 << 5, // Disable manual resizing.
	ImGuiTableColumnFlags_NoReorder = 1 << 6, // Disable manual reordering this column, this will also prevent other columns from crossing over this column.
	ImGuiTableColumnFlags_NoHide = 1 << 7, // Disable ability to hide/disable this column.
	ImGuiTableColumnFlags_NoClip = 1 << 8, // Disable clipping for this column (all NoClip columns will render in a same draw command).
	ImGuiTableColumnFlags_NoSort = 1 << 9, // Disable ability to sort on this field (even if ImGuiTableFlags_Sortable is set on the table).
	ImGuiTableColumnFlags_NoSortAscending = 1 << 10, // Disable ability to sort in the ascending direction.
	ImGuiTableColumnFlags_NoSortDescending = 1 << 11, // Disable ability to sort in the descending direction.
	ImGuiTableColumnFlags_NoHeaderLabel = 1 << 12, // TableHeadersRow() will submit an empty label for this column. Convenient for some small columns. Name will still appear in context menu or in angled headers. You may append into this cell by calling TableSetColumnIndex() right after the TableHeadersRow() call.
	ImGuiTableColumnFlags_NoHeaderWidth = 1 << 13, // Disable header text width contribution to automatic column width.
	ImGuiTableColumnFlags_PreferSortAscending = 1 << 14, // Make the initial sort direction Ascending when first sorting on this column (default).
	ImGuiTableColumnFlags_PreferSortDescending = 1 << 15, // Make the initial sort direction Descending when first sorting on this column.
	ImGuiTableColumnFlags_IndentEnable = 1 << 16, // Use current Indent value when entering cell (default for column 0).
	ImGuiTableColumnFlags_IndentDisable = 1 << 17, // Ignore current Indent value when entering cell (default for columns > 0). Indentation changes _within_ the cell will still be honored.
	ImGuiTableColumnFlags_AngledHeader = 1 << 18, // TableHeadersRow() will submit an angled header row for this column. Note this will add an extra row.

	// Output status flags, read-only via TableGetColumnFlags()
	ImGuiTableColumnFlags_IsEnabled = 1 << 24, // Status: is enabled == not hidden by user/api (referred to as "Hide" in _DefaultHide and _NoHide) flags.
	ImGuiTableColumnFlags_IsVisible = 1 << 25, // Status: is visible == is enabled AND not clipped by scrolling.
	ImGuiTableColumnFlags_IsSorted = 1 << 26, // Status: is currently part of the sort specs
	ImGuiTableColumnFlags_IsHovered = 1 << 27, // Status: is hovered by mouse

	// [Internal] Combinations and masks
	ImGuiTableColumnFlags_WidthMask_ = ImGuiTableColumnFlags_WidthStretch | ImGuiTableColumnFlags_WidthFixed,
	ImGuiTableColumnFlags_IndentMask_ = ImGuiTableColumnFlags_IndentEnable | ImGuiTableColumnFlags_IndentDisable,
	ImGuiTableColumnFlags_StatusMask_ = ImGuiTableColumnFlags_IsEnabled | ImGuiTableColumnFlags_IsVisible | ImGuiTableColumnFlags_IsSorted | ImGuiTableColumnFlags_IsHovered,
	ImGuiTableColumnFlags_NoDirectResize_ = 1 << 30, // [Internal] Disable user resizing this column directly (it may however we resized indirectly from its left edge)
}

// Flags for ImGui::TableNextRow()
ImGuiTableRowFlags_ :: enum i32 {
	ImGuiTableRowFlags_None = 0,
	ImGuiTableRowFlags_Headers = 1 << 0, // Identify header row (set default background color + width of its contents accounted differently for auto column width)
}

// Enum for ImGui::TableSetBgColor()
// Background colors are rendering in 3 layers:
//  - Layer 0: draw with RowBg0 color if set, otherwise draw with ColumnBg0 if set.
//  - Layer 1: draw with RowBg1 color if set, otherwise draw with ColumnBg1 if set.
//  - Layer 2: draw with CellBg color if set.
// The purpose of the two row/columns layers is to let you decide if a background color change should override or blend with the existing color.
// When using ImGuiTableFlags_RowBg on the table, each row has the RowBg0 color automatically set for odd/even rows.
// If you set the color of RowBg0 target, your color will override the existing RowBg0 color.
// If you set the color of RowBg1 or ColumnBg1 target, your color will blend over the RowBg0 color.
ImGuiTableBgTarget_ :: enum i32 {
	ImGuiTableBgTarget_None = 0,
	ImGuiTableBgTarget_RowBg0 = 1, // Set row background color 0 (generally used for background, automatically set when ImGuiTableFlags_RowBg is used)
	ImGuiTableBgTarget_RowBg1 = 2, // Set row background color 1 (generally used for selection marking)
	ImGuiTableBgTarget_CellBg = 3, // Set cell background color (top-most color)
}

// Sorting specifications for a table (often handling sort specs for a single column, occasionally more)
// Sorting specifications for a table (often handling sort specs for a single column, occasionally more)
// Obtained by calling TableGetSortSpecs().
// When 'SpecsDirty == true' you can sort your data. It will be true with sorting specs have changed since last call, or the first time.
// Make sure to set 'SpecsDirty = false' after sorting, else you may wastefully sort your data every frame!
ImGuiTableSortSpecs :: struct {
	Specs : ^ImGuiTableColumnSortSpecs, // Pointer to sort spec array.
	SpecsCount : i32, // Sort spec count. Most often 1. May be > 1 when ImGuiTableFlags_SortMulti is enabled. May be == 0 when ImGuiTableFlags_SortTristate is enabled.
	SpecsDirty : bool, // Set to true when specs have changed since last time! Use this to sort again, then clear the flag.
}

ImGuiTableSortSpecs_init :: proc(this : ^ImGuiTableSortSpecs) { memset(this, 0, size_of(this^)) }

// Sorting specification for one column of a table
// Sorting specification for one column of a table (sizeof == 12 bytes)
ImGuiTableColumnSortSpecs :: struct {
	ColumnUserID : ImGuiID, // User id of the column (if specified by a TableSetupColumn() call)
	ColumnIndex : ImS16, // Index of the column
	SortOrder : ImS16, // Index within parent ImGuiTableSortSpecs (always stored in order starting from 0, tables sorted on a single criteria will always have a 0 here)
	SortDirection : ImGuiSortDirection, // ImGuiSortDirection_Ascending or ImGuiSortDirection_Descending
}

ImGuiTableColumnSortSpecs_init :: proc(this : ^ImGuiTableColumnSortSpecs) { memset(this, 0, size_of(this^)) }

//-----------------------------------------------------------------------------
// [SECTION] Helpers: Debug log, memory allocations macros, ImVector<>
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Debug Logging into ShowDebugLogWindow(), tty and more.
//-----------------------------------------------------------------------------

when ! IMGUI_DISABLE_DEBUG_TOOLS { /* @gen ifndef */
IMGUI_DEBUG_LOG :: #force_inline proc "contextless" (args : ..any) //TODO @gen: Validate the parameters were not passed by reference.
{
	ImGui::DebugLog(__VA_ARGS__)
}

} else { // preproc else
IMGUI_DEBUG_LOG :: #force_inline proc "contextless" (args : ..any) //TODO @gen: Validate the parameters were not passed by reference.
{
	((void)0)
}

} // preproc endif

//-----------------------------------------------------------------------------
// IM_MALLOC(), IM_FREE(), IM_NEW(), IM_PLACEMENT_NEW(), IM_DELETE()
// We call C++ constructor on own allocated memory via the placement "new(ptr) Type()" syntax.
// Defining a custom placement new() with a custom parameter allows us to bypass including <new> which on some platforms complains when user has disabled exceptions.
//-----------------------------------------------------------------------------

ImNewWrapper :: struct { }
IM_ALLOC :: #force_inline proc "contextless" (_SIZE : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	ImGui::MemAlloc(_SIZE)
}

IM_FREE :: #force_inline proc "contextless" (_PTR : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	ImGui::MemFree(_PTR)
}

IM_PLACEMENT_NEW :: #force_inline proc "contextless" (_PTR : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	new(ImNewWrapper(),_PTR)
}

IM_NEW :: #force_inline proc "contextless" (_TYPE : $T0) //TODO @gen: Validate the parameters were not passed by reference.
{
	new(ImNewWrapper(),ImGui::MemAlloc(sizeof(_TYPE)))_TYPE
}

IM_DELETE :: proc($T : typeid, p : ^T) { if p != nil {deinit(p); MemFree(p)
} }

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


ImVector :: struct($T : typeid) {
	Size : i32,
	Capacity : i32,
	Data : ^T,

	// Provide standard typedefs but we don't use them ourselves.




}

ImVector_deinit :: proc(this : ^ImVector)
{if this.Data != nil { IM_FREE(this.Data) }}

// Constructors, destructor
ImVector_init_0 :: #force_inline proc(this : ^ImVector($T))
{
	this.Capacity = 0; this.Size = this.Capacity; this.Data = nil
}

ImVector_init_1 :: #force_inline proc(this : ^ImVector($T), src : ^ImVector(T))
{
	this.Capacity = 0; this.Size = this.Capacity; this.Data = nil; operator_Assign(src)
}

// Important: does not destruct anything
ImVector_clear :: #force_inline proc(this : ^ImVector($T)) { if this.Data != nil {this.Capacity = 0; this.Size = this.Capacity; IM_FREE(this.Data); this.Data = nil
} }

// Important: never called automatically! always explicit.
ImVector_clear_delete :: #force_inline proc(this : ^ImVector($T))
{
	for n : i32 = 0; n < this.Size; post_incr(&n) { IM_DELETE(this.Data[n]) }; ImVector_clear(this)
}

// Important: never called automatically! always explicit.
ImVector_clear_destruct :: #force_inline proc(this : ^ImVector($T))
{
	for n : i32 = 0; n < this.Size; post_incr(&n) { deinit(&this.Data[n]) }; ImVector_clear(this)
}

ImVector_empty :: #force_inline proc(this : ^ImVector($T)) -> bool { return this.Size == 0 }

ImVector_size :: #force_inline proc(this : ^ImVector($T)) -> i32 { return this.Size }

ImVector_size_in_bytes :: #force_inline proc(this : ^ImVector($T)) -> i32 { return this.Size * cast(i32) size_of(T) }

ImVector_max_size :: #force_inline proc(this : ^ImVector($T)) -> i32 { return 0x7FFFFFFF / cast(i32) size_of(T) }

ImVector_capacity :: #force_inline proc(this : ^ImVector($T)) -> i32 { return this.Capacity }

ImVector_begin :: #force_inline proc(this : ^ImVector($T)) -> ^T { return this.Data }

ImVector_begin :: #force_inline proc(this : ^ImVector($T)) -> ^T { return this.Data }

ImVector_end :: #force_inline proc(this : ^ImVector($T)) -> ^T { return this.Data + this.Size }

ImVector_end :: #force_inline proc(this : ^ImVector($T)) -> ^T { return this.Data + this.Size }

ImVector_front :: #force_inline proc(this : ^ImVector($T)) -> ^T
{
	IM_ASSERT(this.Size > 0); return this.Data[0]
}

ImVector_front :: #force_inline proc(this : ^ImVector($T)) -> ^T
{
	IM_ASSERT(this.Size > 0); return this.Data[0]
}

ImVector_back :: #force_inline proc(this : ^ImVector($T)) -> ^T
{
	IM_ASSERT(this.Size > 0); return this.Data[this.Size - 1]
}

ImVector_back :: #force_inline proc(this : ^ImVector($T)) -> ^T
{
	IM_ASSERT(this.Size > 0); return this.Data[this.Size - 1]
}

ImVector_swap :: #force_inline proc(this : ^ImVector($T), rhs : ^ImVector(T))
{
	rhs_size : i32 = rhs.Size; rhs.Size = this.Size; this.Size = rhs_size; rhs_cap : i32 = rhs.Capacity; rhs.Capacity = this.Capacity; this.Capacity = rhs_cap; rhs_data : ^T = rhs.Data; rhs.Data = this.Data; this.Data = rhs_data
}

ImVector__grow_capacity :: #force_inline proc(this : ^ImVector($T), sz : i32) -> i32
{
	new_capacity : i32 = this.Capacity != 0 ? (this.Capacity + this.Capacity / 2) : 8; return new_capacity > sz ? new_capacity : sz
}

ImVector_resize_0 :: #force_inline proc(this : ^ImVector($T), new_size : i32)
{
	if new_size > this.Capacity { reserve(ImVector__grow_capacity(this, new_size)) }; this.Size = new_size
}

ImVector_resize_1 :: #force_inline proc(this : ^ImVector($T), new_size : i32, v : ^T)
{
	if new_size > this.Capacity { reserve(ImVector__grow_capacity(this, new_size)) }; if new_size > this.Size { for n : i32 = this.Size; n < new_size; post_incr(&n) { memcpy(&this.Data[n], &v, size_of(v)) } }; this.Size = new_size
}

// Resize a vector to a smaller size, guaranteed not to cause a reallocation
ImVector_shrink :: #force_inline proc(this : ^ImVector($T), new_size : i32)
{
	IM_ASSERT(new_size <= this.Size); this.Size = new_size
}

ImVector_reserve :: #force_inline proc(this : ^ImVector($T), new_capacity : i32)
{
	if new_capacity <= this.Capacity { return }; new_data : ^T = cast(^T) IM_ALLOC(cast(uint) new_capacity * size_of(T)); if this.Data != nil {memcpy(new_data, this.Data, cast(uint) this.Size * size_of(T)); IM_FREE(this.Data)
	}; this.Data = new_data; this.Capacity = new_capacity
}

ImVector_reserve_discard :: #force_inline proc(this : ^ImVector($T), new_capacity : i32)
{
	if new_capacity <= this.Capacity { return }; if this.Data != nil { IM_FREE(this.Data) }; this.Data = cast(^T) IM_ALLOC(cast(uint) new_capacity * size_of(T)); this.Capacity = new_capacity
}

// NB: It is illegal to call push_back/push_front/insert with a reference pointing inside the ImVector data itself! e.g. v.push_back(v[10]) is forbidden.
ImVector_push_back :: #force_inline proc(this : ^ImVector($T), v : ^T)
{
	if this.Size == this.Capacity { ImVector_reserve(this, ImVector__grow_capacity(this, this.Size + 1)) }; memcpy(&this.Data[this.Size], &v, size_of(v)); post_incr(&this.Size)
}

ImVector_pop_back :: #force_inline proc(this : ^ImVector($T))
{
	IM_ASSERT(this.Size > 0); post_decr(&this.Size)
}

ImVector_push_front :: #force_inline proc(this : ^ImVector($T), v : ^T) { if this.Size == 0 { ImVector_push_back(this, v) }
else { insert(this.Data, v) } }

ImVector_erase_0 :: #force_inline proc(this : ^ImVector($T), it : ^T) -> ^T
{
	IM_ASSERT(it >= this.Data && it < this.Data + this.Size); off : int = it - this.Data; memmove(this.Data + off, this.Data + off + 1, (cast(uint) this.Size - cast(uint) off - 1) * size_of(T)); post_decr(&this.Size); return this.Data + off
}

ImVector_erase_1 :: #force_inline proc(this : ^ImVector($T), it : ^T, it_last : ^T) -> ^T
{
	IM_ASSERT(it >= this.Data && it < this.Data + this.Size && it_last >= it && it_last <= this.Data + this.Size); count : int = it_last - it; off : int = it - this.Data; memmove(this.Data + off, this.Data + off + count, (cast(uint) this.Size - cast(uint) off - cast(uint) count) * size_of(T)); this.Size -= cast(i32) count; return this.Data + off
}

ImVector_erase_unsorted :: #force_inline proc(this : ^ImVector($T), it : ^T) -> ^T
{
	IM_ASSERT(it >= this.Data && it < this.Data + this.Size); off : int = it - this.Data; if it < this.Data + this.Size - 1 { memcpy(this.Data + off, this.Data + this.Size - 1, size_of(T)) }; post_decr(&this.Size); return this.Data + off
}

ImVector_insert :: #force_inline proc(this : ^ImVector($T), it : ^T, v : ^T) -> ^T
{
	IM_ASSERT(it >= this.Data && it <= this.Data + this.Size); off : int = it - this.Data; if this.Size == this.Capacity { ImVector_reserve(this, ImVector__grow_capacity(this, this.Size + 1)) }; if off < cast(i32) this.Size { memmove(this.Data + off + 1, this.Data + off, (cast(uint) this.Size - cast(uint) off) * size_of(T)) }; memcpy(&this.Data[off], &v, size_of(v)); post_incr(&this.Size); return this.Data + off
}

ImVector_contains :: #force_inline proc(this : ^ImVector($T), v : ^T) -> bool
{
	data : ^T = this.Data; data_end : ^T = this.Data + this.Size; for data < data_end { if post_incr(&data)^ == v { return true } }; return false
}

ImVector_find :: #force_inline proc(this : ^ImVector($T), v : ^T) -> ^T
{
	data : ^T = this.Data; data_end : ^T = this.Data + this.Size; for data < data_end { if data^ == v { break }
else { pre_incr(&data) } }; return data
}

ImVector_find :: #force_inline proc(this : ^ImVector($T), v : ^T) -> ^T
{
	data : ^T = this.Data; data_end : ^T = this.Data + this.Size; for data < data_end { if data^ == v { break }
else { pre_incr(&data) } }; return data
}

ImVector_find_index :: #force_inline proc(this : ^ImVector($T), v : ^T) -> i32
{
	data_end : ^T = this.Data + this.Size; it : ^T = ImVector_find(this, v); if it == data_end { return -1 }; off : int = it - this.Data; return cast(i32) off
}

ImVector_find_erase :: #force_inline proc(this : ^ImVector($T), v : ^T) -> bool
{
	it : ^T = ImVector_find(this, v); if it < this.Data + this.Size {ImVector_erase(this, it); return true
	}; return false
}

ImVector_find_erase_unsorted :: #force_inline proc(this : ^ImVector($T), v : ^T) -> bool
{
	it : ^T = ImVector_find(this, v); if it < this.Data + this.Size {ImVector_erase_unsorted(this, it); return true
	}; return false
}

ImVector_index_from_ptr :: #force_inline proc(this : ^ImVector($T), it : ^T) -> i32
{
	IM_ASSERT(it >= this.Data && it < this.Data + this.Size); off : int = it - this.Data; return cast(i32) off
}


// Runtime data for styling/colors
//-----------------------------------------------------------------------------
// [SECTION] ImGuiStyle
//-----------------------------------------------------------------------------
// You may modify the ImGui::GetStyle() main instance during initialization and before NewFrame().
// During the frame, use ImGui::PushStyleVar(ImGuiStyleVar_XXXX)/PopStyleVar() to alter the main style values,
// and ImGui::PushStyleColor(ImGuiCol_XXX)/PopStyleColor() for colors.
//-----------------------------------------------------------------------------

ImGuiStyle :: struct {
	Alpha : f32, // Global alpha applies to everything in Dear ImGui.
	DisabledAlpha : f32, // Additional alpha multiplier applied by BeginDisabled(). Multiply over current value of Alpha.
	WindowPadding : ImVec2, // Padding within a window.
	WindowRounding : f32, // Radius of window corners rounding. Set to 0.0f to have rectangular windows. Large values tend to lead to variety of artifacts and are not recommended.
	WindowBorderSize : f32, // Thickness of border around windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
	WindowMinSize : ImVec2, // Minimum window size. This is a global setting. If you want to constrain individual windows, use SetNextWindowSizeConstraints().
	WindowTitleAlign : ImVec2, // Alignment for title bar text. Defaults to (0.0f,0.5f) for left-aligned,vertically centered.
	WindowMenuButtonPosition : ImGuiDir, // Side of the collapsing/docking button in the title bar (None/Left/Right). Defaults to ImGuiDir_Left.
	ChildRounding : f32, // Radius of child window corners rounding. Set to 0.0f to have rectangular windows.
	ChildBorderSize : f32, // Thickness of border around child windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
	PopupRounding : f32, // Radius of popup window corners rounding. (Note that tooltip windows use WindowRounding)
	PopupBorderSize : f32, // Thickness of border around popup/tooltip windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
	FramePadding : ImVec2, // Padding within a framed rectangle (used by most widgets).
	FrameRounding : f32, // Radius of frame corners rounding. Set to 0.0f to have rectangular frame (used by most widgets).
	FrameBorderSize : f32, // Thickness of border around frames. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
	ItemSpacing : ImVec2, // Horizontal and vertical spacing between widgets/lines.
	ItemInnerSpacing : ImVec2, // Horizontal and vertical spacing between within elements of a composed widget (e.g. a slider and its label).
	CellPadding : ImVec2, // Padding within a table cell. Cellpadding.x is locked for entire table. CellPadding.y may be altered between different rows.
	TouchExtraPadding : ImVec2, // Expand reactive bounding box for touch-based system where touch position is not accurate enough. Unfortunately we don't sort widgets so priority on overlap will always be given to the first widget. So don't grow this too much!
	IndentSpacing : f32, // Horizontal indentation when e.g. entering a tree node. Generally == (FontSize + FramePadding.x*2).
	ColumnsMinSpacing : f32, // Minimum horizontal spacing between two columns. Preferably > (FramePadding.x + 1).
	ScrollbarSize : f32, // Width of the vertical scrollbar, Height of the horizontal scrollbar.
	ScrollbarRounding : f32, // Radius of grab corners for scrollbar.
	GrabMinSize : f32, // Minimum width/height of a grab box for slider/scrollbar.
	GrabRounding : f32, // Radius of grabs corners rounding. Set to 0.0f to have rectangular slider grabs.
	LogSliderDeadzone : f32, // The size in pixels of the dead-zone around zero on logarithmic sliders that cross zero.
	TabRounding : f32, // Radius of upper corners of a tab. Set to 0.0f to have rectangular tabs.
	TabBorderSize : f32, // Thickness of border around tabs.
	TabMinWidthForCloseButton : f32, // Minimum width for close button to appear on an unselected tab when hovered. Set to 0.0f to always show when hovering, set to FLT_MAX to never show close button unless selected.
	TabBarBorderSize : f32, // Thickness of tab-bar separator, which takes on the tab active color to denote focus.
	TabBarOverlineSize : f32, // Thickness of tab-bar overline, which highlights the selected tab-bar.
	TableAngledHeadersAngle : f32, // Angle of angled headers (supported values range from -50.0f degrees to +50.0f degrees).
	TableAngledHeadersTextAlign : ImVec2, // Alignment of angled headers within the cell
	ColorButtonPosition : ImGuiDir, // Side of the color button in the ColorEdit4 widget (left/right). Defaults to ImGuiDir_Right.
	ButtonTextAlign : ImVec2, // Alignment of button text when button is larger than text. Defaults to (0.5f, 0.5f) (centered).
	SelectableTextAlign : ImVec2, // Alignment of selectable text. Defaults to (0.0f, 0.0f) (top-left aligned). It's generally important to keep this left-aligned if you want to lay multiple items on a same line.
	SeparatorTextBorderSize : f32, // Thickness of border in SeparatorText()
	SeparatorTextAlign : ImVec2, // Alignment of text within the separator. Defaults to (0.0f, 0.5f) (left aligned, center).
	SeparatorTextPadding : ImVec2, // Horizontal offset of text from each edge of the separator + spacing on other axis. Generally small values. .y is recommended to be == FramePadding.y.
	DisplayWindowPadding : ImVec2, // Apply to regular windows: amount which we enforce to keep visible when moving near edges of your screen.
	DisplaySafeAreaPadding : ImVec2, // Apply to every windows, menus, popups, tooltips: amount where we avoid displaying contents. Adjust if you cannot see the edges of your screen (e.g. on a TV where scaling has not been configured).
	DockingSeparatorSize : f32, // Thickness of resizing border between docked windows
	MouseCursorScale : f32, // Scale software rendered mouse cursor (when io.MouseDrawCursor is enabled). We apply per-monitor DPI scaling over this scale. May be removed later.
	AntiAliasedLines : bool, // Enable anti-aliased lines/borders. Disable if you are really tight on CPU/GPU. Latched at the beginning of the frame (copied to ImDrawList).
	AntiAliasedLinesUseTex : bool, // Enable anti-aliased lines/borders using textures where possible. Require backend to render with bilinear filtering (NOT point/nearest filtering). Latched at the beginning of the frame (copied to ImDrawList).
	AntiAliasedFill : bool, // Enable anti-aliased edges around filled shapes (rounded rectangles, circles, etc.). Disable if you are really tight on CPU/GPU. Latched at the beginning of the frame (copied to ImDrawList).
	CurveTessellationTol : f32, // Tessellation tolerance when using PathBezierCurveTo() without a specific number of segments. Decrease for highly tessellated curves (higher quality, more polygons), increase to reduce quality.
	CircleTessellationMaxError : f32, // Maximum error (in pixels) allowed when using AddCircle()/AddCircleFilled() or drawing rounded corner rectangles with no explicit segment count specified. Decrease for higher quality but more geometry.
	Colors : [ImGuiCol_.ImGuiCol_COUNT]ImVec4,

	// Behaviors
	// (It is possible to modify those fields mid-frame if specific behavior need it, unlike e.g. configuration fields in ImGuiIO)
	HoverStationaryDelay : f32, // Delay for IsItemHovered(ImGuiHoveredFlags_Stationary). Time required to consider mouse stationary.
	HoverDelayShort : f32, // Delay for IsItemHovered(ImGuiHoveredFlags_DelayShort). Usually used along with HoverStationaryDelay.
	HoverDelayNormal : f32, // Delay for IsItemHovered(ImGuiHoveredFlags_DelayNormal). "
	HoverFlagsForTooltipMouse : ImGuiHoveredFlags, // Default flags when using IsItemHovered(ImGuiHoveredFlags_ForTooltip) or BeginItemTooltip()/SetItemTooltip() while using mouse.
	HoverFlagsForTooltipNav : ImGuiHoveredFlags, // Default flags when using IsItemHovered(ImGuiHoveredFlags_ForTooltip) or BeginItemTooltip()/SetItemTooltip() while using keyboard/gamepad.
}

// Storage for ImGuiIO and IsKeyDown(), IsKeyPressed() etc functions.
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
ImGuiKeyData :: struct {
	Down : bool, // True for if key is down
	DownDuration : f32, // Duration the key has been down (<0.0f: not pressed, 0.0f: just pressed, >0.0f: time held)
	DownDurationPrev : f32, // Last frame duration the key has been down
	AnalogValue : f32, // 0.0f..1.0f for gamepad values
}

// Main configuration and I/O between your application and ImGui (also see: ImGuiPlatformIO)
ImGuiIO :: struct {
	//------------------------------------------------------------------
	// Configuration                            // Default value
	//------------------------------------------------------------------

	ConfigFlags : ImGuiConfigFlags, // = 0              // See ImGuiConfigFlags_ enum. Set by user/application. Keyboard/Gamepad navigation options, etc.
	BackendFlags : ImGuiBackendFlags, // = 0              // See ImGuiBackendFlags_ enum. Set by backend (imgui_impl_xxx files or custom backend) to communicate features supported by the backend.
	DisplaySize : ImVec2, // <unset>          // Main display size, in pixels (generally == GetMainViewport()->Size). May change every frame.
	DeltaTime : f32, // = 1.0f/60.0f     // Time elapsed since last frame, in seconds. May change every frame.
	IniSavingRate : f32, // = 5.0f           // Minimum time between saving positions/sizes to .ini file, in seconds.
	IniFilename : ^u8, // = "imgui.ini"    // Path to .ini file (important: default "imgui.ini" is relative to current working dir!). Set NULL to disable automatic .ini loading/saving or if you want to manually call LoadIniSettingsXXX() / SaveIniSettingsXXX() functions.
	LogFilename : ^u8, // = "imgui_log.txt"// Path to .log file (default parameter to ImGui::LogToFile when no file is specified).
	UserData : rawptr, // = NULL           // Store your own data.

	// Font system
	Fonts : ^ImFontAtlas, // <auto>           // Font atlas: load, rasterize and pack one or more fonts into a single texture.
	FontGlobalScale : f32, // = 1.0f           // Global scale all fonts
	FontAllowUserScaling : bool, // = false          // [OBSOLETE] Allow user scaling text of individual window with CTRL+Wheel.
	FontDefault : ^ImFont, // = NULL           // Font to use on NewFrame(). Use NULL to uses Fonts->Fonts[0].
	DisplayFramebufferScale : ImVec2, // = (1, 1)         // For retina display or other situations where window coordinates are different from framebuffer coordinates. This generally ends up in ImDrawData::FramebufferScale.

	// Keyboard/Gamepad Navigation options
	ConfigNavSwapGamepadButtons : bool, // = false          // Swap Activate<>Cancel (A<>B) buttons, matching typical "Nintendo/Japanese style" gamepad layout.
	ConfigNavMoveSetMousePos : bool, // = false          // Directional/tabbing navigation teleports the mouse cursor. May be useful on TV/console systems where moving a virtual mouse is difficult. Will update io.MousePos and set io.WantSetMousePos=true.
	ConfigNavCaptureKeyboard : bool, // = true           // Sets io.WantCaptureKeyboard when io.NavActive is set.
	ConfigNavEscapeClearFocusItem : bool, // = true           // Pressing Escape can clear focused item + navigation id/highlight. Set to false if you want to always keep highlight on.
	ConfigNavEscapeClearFocusWindow : bool, // = false          // Pressing Escape can clear focused window as well (super set of io.ConfigNavEscapeClearFocusItem).
	ConfigNavCursorVisibleAuto : bool, // = true           // Using directional navigation key makes the cursor visible. Mouse click hides the cursor.
	ConfigNavCursorVisibleAlways : bool, // = false          // Navigation cursor is always visible.

	// Docking options (when ImGuiConfigFlags_DockingEnable is set)
	ConfigDockingNoSplit : bool, // = false          // Simplified docking mode: disable window splitting, so docking is limited to merging multiple windows together into tab-bars.
	ConfigDockingWithShift : bool, // = false          // Enable docking with holding Shift key (reduce visual noise, allows dropping in wider space)
	ConfigDockingAlwaysTabBar : bool, // = false          // [BETA] [FIXME: This currently creates regression with auto-sizing and general overhead] Make every single floating window display within a docking node.
	ConfigDockingTransparentPayload : bool, // = false          // [BETA] Make window or viewport transparent when docking and only display docking boxes on the target viewport. Useful if rendering of multiple viewport cannot be synced. Best used with ConfigViewportsNoAutoMerge.

	// Viewport options (when ImGuiConfigFlags_ViewportsEnable is set)
	ConfigViewportsNoAutoMerge : bool, // = false;         // Set to make all floating imgui windows always create their own viewport. Otherwise, they are merged into the main host viewports when overlapping it. May also set ImGuiViewportFlags_NoAutoMerge on individual viewport.
	ConfigViewportsNoTaskBarIcon : bool, // = false          // Disable default OS task bar icon flag for secondary viewports. When a viewport doesn't want a task bar icon, ImGuiViewportFlags_NoTaskBarIcon will be set on it.
	ConfigViewportsNoDecoration : bool, // = true           // Disable default OS window decoration flag for secondary viewports. When a viewport doesn't want window decorations, ImGuiViewportFlags_NoDecoration will be set on it. Enabling decoration can create subsequent issues at OS levels (e.g. minimum window size).
	ConfigViewportsNoDefaultParent : bool, // = false          // Disable default OS parenting to main viewport for secondary viewports. By default, viewports are marked with ParentViewportId = <main_viewport>, expecting the platform backend to setup a parent/child relationship between the OS windows (some backend may ignore this). Set to true if you want the default to be 0, then all viewports will be top-level OS windows.

	// Miscellaneous options
	// (you can visualize and interact with all options in 'Demo->Configuration')
	MouseDrawCursor : bool, // = false          // Request ImGui to draw a mouse cursor for you (if you are on a platform without a mouse cursor). Cannot be easily renamed to 'io.ConfigXXX' because this is frequently used by backend implementations.
	ConfigMacOSXBehaviors : bool, // = defined(__APPLE__) // Swap Cmd<>Ctrl keys + OS X style text editing cursor movement using Alt instead of Ctrl, Shortcuts using Cmd/Super instead of Ctrl, Line/Text Start and End using Cmd+Arrows instead of Home/End, Double click selects by word instead of selecting whole text, Multi-selection in lists uses Cmd/Super instead of Ctrl.
	ConfigInputTrickleEventQueue : bool, // = true           // Enable input queue trickling: some types of events submitted during the same frame (e.g. button down + up) will be spread over multiple frames, improving interactions with low framerates.
	ConfigInputTextCursorBlink : bool, // = true           // Enable blinking cursor (optional as some users consider it to be distracting).
	ConfigInputTextEnterKeepActive : bool, // = false          // [BETA] Pressing Enter will keep item active and select contents (single-line only).
	ConfigDragClickToInputText : bool, // = false          // [BETA] Enable turning DragXXX widgets into text input with a simple mouse click-release (without moving). Not desirable on devices without a keyboard.
	ConfigWindowsResizeFromEdges : bool, // = true           // Enable resizing of windows from their edges and from the lower-left corner. This requires ImGuiBackendFlags_HasMouseCursors for better mouse cursor feedback. (This used to be a per-window ImGuiWindowFlags_ResizeFromAnySide flag)
	ConfigWindowsMoveFromTitleBarOnly : bool, // = false      // Enable allowing to move windows only when clicking on their title bar. Does not apply to windows without a title bar.
	ConfigWindowsCopyContentsWithCtrlC : bool, // = false      // [EXPERIMENTAL] CTRL+C copy the contents of focused window into the clipboard. Experimental because: (1) has known issues with nested Begin/End pairs (2) text output quality varies (3) text output is in submission order rather than spatial order.
	ConfigScrollbarScrollByPage : bool, // = true           // Enable scrolling page by page when clicking outside the scrollbar grab. When disabled, always scroll to clicked location. When enabled, Shift+Click scrolls to clicked location.
	ConfigMemoryCompactTimer : f32, // = 60.0f          // Timer (in seconds) to free transient windows/tables memory buffers when unused. Set to -1.0f to disable.

	// Inputs Behaviors
	// (other variables, ones which are expected to be tweaked within UI code, are exposed in ImGuiStyle)
	MouseDoubleClickTime : f32, // = 0.30f          // Time for a double-click, in seconds.
	MouseDoubleClickMaxDist : f32, // = 6.0f           // Distance threshold to stay in to validate a double-click, in pixels.
	MouseDragThreshold : f32, // = 6.0f           // Distance threshold before considering we are dragging.
	KeyRepeatDelay : f32, // = 0.275f         // When holding a key/button, time before it starts repeating, in seconds (for buttons in Repeat mode, etc.).
	KeyRepeatRate : f32, // = 0.050f         // When holding a key/button, rate at which it repeats, in seconds.

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
	ConfigErrorRecovery : bool, // = true       // Enable error recovery support. Some errors won't be detected and lead to direct crashes if recovery is disabled.
	ConfigErrorRecoveryEnableAssert : bool, // = true       // Enable asserts on recoverable error. By default call IM_ASSERT() when returning from a failing IM_ASSERT_USER_ERROR()
	ConfigErrorRecoveryEnableDebugLog : bool, // = true       // Enable debug log output on recoverable errors.
	ConfigErrorRecoveryEnableTooltip : bool, // = true       // Enable tooltip on recoverable errors. The tooltip include a way to enable asserts if they were disabled.

	// Option to enable various debug tools showing buttons that will call the IM_DEBUG_BREAK() macro.
	// - The Item Picker tool will be available regardless of this being enabled, in order to maximize its discoverability.
	// - Requires a debugger being attached, otherwise IM_DEBUG_BREAK() options will appear to crash your application.
	//   e.g. io.ConfigDebugIsDebuggerPresent = ::IsDebuggerPresent() on Win32, or refer to ImOsIsDebuggerPresent() imgui_test_engine/imgui_te_utils.cpp for a Unix compatible version).
	ConfigDebugIsDebuggerPresent : bool, // = false          // Enable various tools calling IM_DEBUG_BREAK().

	// Tools to detect code submitting items with conflicting/duplicate IDs
	// - Code should use PushID()/PopID() in loops, or append "##xx" to same-label identifiers.
	// - Empty label e.g. Button("") == same ID as parent widget/node. Use Button("##xx") instead!
	// - See FAQ https://github.com/ocornut/imgui/blob/master/docs/FAQ.md#q-about-the-id-stack-system
	ConfigDebugHighlightIdConflicts : bool, // = true           // Highlight and show an error message when multiple items have conflicting identifiers.

	// Tools to test correct Begin/End and BeginChild/EndChild behaviors.
	// - Presently Begin()/End() and BeginChild()/EndChild() needs to ALWAYS be called in tandem, regardless of return value of BeginXXX()
	// - This is inconsistent with other BeginXXX functions and create confusion for many users.
	// - We expect to update the API eventually. In the meanwhile we provide tools to facilitate checking user-code behavior.
	ConfigDebugBeginReturnValueOnce : bool, // = false          // First-time calls to Begin()/BeginChild() will return false. NEEDS TO BE SET AT APPLICATION BOOT TIME if you don't want to miss windows.
	ConfigDebugBeginReturnValueLoop : bool, // = false          // Some calls to Begin()/BeginChild() will return false. Will cycle through window depths then repeat. Suggested use: add "io.ConfigDebugBeginReturnValue = io.KeyShift" in your main loop then occasionally press SHIFT. Windows should be flickering while running.

	// Option to deactivate io.AddFocusEvent(false) handling.
	// - May facilitate interactions with a debugger when focus loss leads to clearing inputs data.
	// - Backends may have other side-effects on focus loss, so this will reduce side-effects but not necessary remove all of them.
	ConfigDebugIgnoreFocusLoss : bool, // = false          // Ignore io.AddFocusEvent(false), consequently not calling io.ClearInputKeys()/io.ClearInputMouse() in input processing.

	// Option to audit .ini data
	ConfigDebugIniSettings : bool, // = false          // Save .ini data with extra comments (particularly helpful for Docking, but makes saving slower)

	//------------------------------------------------------------------
	// Platform Identifiers
	// (the imgui_impl_xxxx backend files are setting those up for you)
	//------------------------------------------------------------------

	// Nowadays those would be stored in ImGuiPlatformIO but we are leaving them here for legacy reasons.
	// Optional: Platform/Renderer backend name (informational only! will be displayed in About Window) + User data for backend/wrappers to store their own stuff.
	BackendPlatformName : ^u8, // = NULL
	BackendRendererName : ^u8, // = NULL
	BackendPlatformUserData : rawptr, // = NULL           // User data for platform backend
	BackendRendererUserData : rawptr, // = NULL           // User data for renderer backend
	BackendLanguageUserData : rawptr, // = NULL           // User data for non C++ programming language backend

	//------------------------------------------------------------------
	// Output - Updated by NewFrame() or EndFrame()/Render()
	// (when reading from the io.WantCaptureMouse, io.WantCaptureKeyboard flags to dispatch your inputs, it is
	//  generally easier and more correct to use their state BEFORE calling NewFrame(). See FAQ for details!)
	//------------------------------------------------------------------

	WantCaptureMouse : bool, // Set when Dear ImGui will use mouse inputs, in this case do not dispatch them to your main game/application (either way, always pass on mouse inputs to imgui). (e.g. unclicked mouse is hovering over an imgui window, widget is active, mouse was clicked over an imgui window, etc.).
	WantCaptureKeyboard : bool, // Set when Dear ImGui will use keyboard inputs, in this case do not dispatch them to your main game/application (either way, always pass keyboard inputs to imgui). (e.g. InputText active, or an imgui window is focused and navigation is enabled, etc.).
	WantTextInput : bool, // Mobile/console: when set, you may display an on-screen keyboard. This is set by Dear ImGui when it wants textual keyboard input to happen (e.g. when a InputText widget is active).
	WantSetMousePos : bool, // MousePos has been altered, backend should reposition mouse on next frame. Rarely used! Set only when io.ConfigNavMoveSetMousePos is enabled.
	WantSaveIniSettings : bool, // When manual .ini load/save is active (io.IniFilename == NULL), this will be set to notify your application that you can call SaveIniSettingsToMemory() and save yourself. Important: clear io.WantSaveIniSettings yourself after saving!
	NavActive : bool, // Keyboard/Gamepad navigation is currently allowed (will handle ImGuiKey_NavXXX events) = a window is focused and it doesn't use the ImGuiWindowFlags_NoNavInputs flag.
	NavVisible : bool, // Keyboard/Gamepad navigation highlight is visible and allowed (will handle ImGuiKey_NavXXX events).
	Framerate : f32, // Estimate of application framerate (rolling average over 60 frames, based on io.DeltaTime), in frame per second. Solely for convenience. Slow applications may not want to use a moving average or may want to reset underlying buffers occasionally.
	MetricsRenderVertices : i32, // Vertices output during last call to Render()
	MetricsRenderIndices : i32, // Indices output during last call to Render() = number of triangles * 3
	MetricsRenderWindows : i32, // Number of visible windows
	MetricsActiveWindows : i32, // Number of active windows
	MouseDelta : ImVec2, // Mouse delta. Note that this is zero if either current or previous position are invalid (-FLT_MAX,-FLT_MAX), so a disappearing/reappearing mouse won't have a huge delta.

	//------------------------------------------------------------------
	// [Internal] Dear ImGui will maintain those fields. Forward compatibility not guaranteed!
	//------------------------------------------------------------------

	Ctx : ^ImGuiContext, // Parent UI context (needs to be set explicitly by parent).

	// Main Input State
	// (this block used to be written by backend, since 1.87 it is best to NOT write to those directly, call the AddXXX functions above instead)
	// (reading from those variables is fair game, as they are extremely unlikely to be moving anywhere)
	MousePos : ImVec2, // Mouse position, in pixels. Set to ImVec2(-FLT_MAX, -FLT_MAX) if mouse is unavailable (on another screen, etc.)
	MouseDown : [5]bool, // Mouse buttons: 0=left, 1=right, 2=middle + extras (ImGuiMouseButton_COUNT == 5). Dear ImGui mostly uses left and right buttons. Other buttons allow us to track if the mouse is being used by your application + available to user as a convenience via IsMouse** API.
	MouseWheel : f32, // Mouse wheel Vertical: 1 unit scrolls about 5 lines text. >0 scrolls Up, <0 scrolls Down. Hold SHIFT to turn vertical scroll into horizontal scroll.
	MouseWheelH : f32, // Mouse wheel Horizontal. >0 scrolls Left, <0 scrolls Right. Most users don't have a mouse with a horizontal wheel, may not be filled by all backends.
	MouseSource : ImGuiMouseSource, // Mouse actual input peripheral (Mouse/TouchScreen/Pen).
	MouseHoveredViewport : ImGuiID, // (Optional) Modify using io.AddMouseViewportEvent(). With multi-viewports: viewport the OS mouse is hovering. If possible _IGNORING_ viewports with the ImGuiViewportFlags_NoInputs flag is much better (few backends can handle that). Set io.BackendFlags |= ImGuiBackendFlags_HasMouseHoveredViewport if you can provide this info. If you don't imgui will infer the value using the rectangles and last focused time of the viewports it knows about (ignoring other OS windows).
	KeyCtrl : bool, // Keyboard modifier down: Control
	KeyShift : bool, // Keyboard modifier down: Shift
	KeyAlt : bool, // Keyboard modifier down: Alt
	KeySuper : bool, // Keyboard modifier down: Cmd/Super/Windows

	// Other state maintained from data above + IO function calls
	KeyMods : ImGuiKeyChord, // Key mods flags (any of ImGuiMod_Ctrl/ImGuiMod_Shift/ImGuiMod_Alt/ImGuiMod_Super flags, same as io.KeyCtrl/KeyShift/KeyAlt/KeySuper but merged into flags. Read-only, updated by NewFrame()
	KeysData : [ImGuiKey.ImGuiKey_NamedKey_COUNT]ImGuiKeyData, // Key state for all known keys. Use IsKeyXXX() functions to access this.
	WantCaptureMouseUnlessPopupClose : bool, // Alternative to WantCaptureMouse: (WantCaptureMouse == true && WantCaptureMouseUnlessPopupClose == false) when a click over void is expected to close a popup.
	MousePosPrev : ImVec2, // Previous mouse position (note that MouseDelta is not necessary == MousePos-MousePosPrev, in case either position is invalid)
	MouseClickedPos : [5]ImVec2, // Position at time of clicking
	MouseClickedTime : [5]f64, // Time of last click (used to figure out double-click)
	MouseClicked : [5]bool, // Mouse button went from !Down to Down (same as MouseClickedCount[x] != 0)
	MouseDoubleClicked : [5]bool, // Has mouse button been double-clicked? (same as MouseClickedCount[x] == 2)
	MouseClickedCount : [5]ImU16, // == 0 (not clicked), == 1 (same as MouseClicked[]), == 2 (double-clicked), == 3 (triple-clicked) etc. when going from !Down to Down
	MouseClickedLastCount : [5]ImU16, // Count successive number of clicks. Stays valid after mouse release. Reset after another click is done.
	MouseReleased : [5]bool, // Mouse button went from Down to !Down
	MouseDownOwned : [5]bool, // Track if button was clicked inside a dear imgui window or over void blocked by a popup. We don't request mouse capture from the application if click started outside ImGui bounds.
	MouseDownOwnedUnlessPopupClose : [5]bool, // Track if button was clicked inside a dear imgui window.
	MouseWheelRequestAxisSwap : bool, // On a non-Mac system, holding SHIFT requests WheelY to perform the equivalent of a WheelX event. On a Mac system this is already enforced by the system.
	MouseCtrlLeftAsRightClick : bool, // (OSX) Set to true when the current click was a ctrl-click that spawned a simulated right click
	MouseDownDuration : [5]f32, // Duration the mouse button has been down (0.0f == just clicked)
	MouseDownDurationPrev : [5]f32, // Previous time the mouse button has been down
	MouseDragMaxDistanceAbs : [5]ImVec2, // Maximum distance, absolute, on each axis, of how much mouse has traveled from the clicking point
	MouseDragMaxDistanceSqr : [5]f32, // Squared maximum distance of how much mouse has traveled from the clicking point (used for moving thresholds)
	PenPressure : f32, // Touch/Pen pressure (0.0f to 1.0f, should be >0.0f only when MouseDown[0] == true). Helper storage currently unused by Dear ImGui.
	AppFocusLost : bool, // Only modify via AddFocusEvent()
	AppAcceptingEvents : bool, // Only modify via SetAppAcceptingEvents()
	InputQueueSurrogate : ImWchar16, // For AddInputCharacterUTF16()
	InputQueueCharacters : ImVector(ImWchar), // Queue of _characters_ input (obtained by platform backend). Fill using AddInputCharacter() helper.
}

// Shared state of InputText() when using custom ImGuiInputTextCallback (rare/advanced use)
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
ImGuiInputTextCallbackData :: struct {
	Ctx : ^ImGuiContext, // Parent UI context
	EventFlag : ImGuiInputTextFlags, // One ImGuiInputTextFlags_Callback*    // Read-only
	Flags : ImGuiInputTextFlags, // What user passed to InputText()      // Read-only
	UserData : rawptr, // What user passed to InputText()      // Read-only

	// Arguments for the different callback events
	// - During Resize callback, Buf will be same as your input buffer.
	// - However, during Completion/History/Always callback, Buf always points to our own internal data (it is not the same as your buffer)! Changes to it will be reflected into your own buffer shortly after the callback.
	// - To modify the text buffer in a callback, prefer using the InsertChars() / DeleteChars() function. InsertChars() will take care of calling the resize callback if necessary.
	// - If you know your edits are not going to resize the underlying buffer allocation, you may modify the contents of 'Buf[]' directly. You need to update 'BufTextLen' accordingly (0 <= BufTextLen < BufSize) and set 'BufDirty'' to true so InputText can update its internal state.
	EventChar : ImWchar, // Character input                      // Read-write   // [CharFilter] Replace character with another one, or set to zero to drop. return 1 is equivalent to setting EventChar=0;
	EventKey : ImGuiKey, // Key pressed (Up/Down/TAB)            // Read-only    // [Completion,History]
	Buf : ^u8, // Text buffer                          // Read-write   // [Resize] Can replace pointer / [Completion,History,Always] Only write to pointed data, don't replace the actual pointer!
	BufTextLen : i32, // Text length (in bytes)               // Read-write   // [Resize,Completion,History,Always] Exclude zero-terminator storage. In C land: == strlen(some_text), in C++ land: string.length()
	BufSize : i32, // Buffer size (in bytes) = capacity+1  // Read-only    // [Resize,Completion,History,Always] Include zero-terminator storage. In C land == ARRAYSIZE(my_char_array), in C++ land: string.capacity()+1
	BufDirty : bool, // Set if you modify Buf/BufTextLen!    // Write        // [Completion,History,Always]
	CursorPos : i32, //                                      // Read-write   // [Completion,History,Always]
	SelectionStart : i32, //                                      // Read-write   // [Completion,History,Always] == to SelectionEnd when no selection)
	SelectionEnd : i32, //                                      // Read-write   // [Completion,History,Always]
}

ImGuiInputTextCallbackData_SelectAll :: proc(this : ^ImGuiInputTextCallbackData)
{
	this.SelectionStart = 0; this.SelectionEnd = this.BufTextLen
}

ImGuiInputTextCallbackData_ClearSelection :: proc(this : ^ImGuiInputTextCallbackData) { this.SelectionEnd = this.BufTextLen; this.SelectionStart = this.SelectionEnd }

ImGuiInputTextCallbackData_HasSelection :: proc(this : ^ImGuiInputTextCallbackData) -> bool { return this.SelectionStart != this.SelectionEnd }

// Callback data when using SetNextWindowSizeConstraints() (rare/advanced use)
// Resizing callback data to apply custom constraint. As enabled by SetNextWindowSizeConstraints(). Callback is called during the next Begin().
// NB: For basic min/max size constraint on each axis you don't need to use the callback! The SetNextWindowSizeConstraints() parameters are enough.
ImGuiSizeCallbackData :: struct {
	UserData : rawptr, // Read-only.   What user passed to SetNextWindowSizeConstraints(). Generally store an integer or float in here (need reinterpret_cast<>).
	Pos : ImVec2, // Read-only.   Window position, for reference.
	CurrentSize : ImVec2, // Read-only.   Current window size.
	DesiredSize : ImVec2, // Read-write.  Desired size, based on user's mouse position. Write to this field to restrain resizing.
}

// Window class (rare/advanced uses: provide hints to the platform backend via altered viewport flags and parent/child info)
// [ALPHA] Rarely used / very advanced uses only. Use with SetNextWindowClass() and DockSpace() functions.
// Important: the content of this class is still highly WIP and likely to change and be refactored
// before we stabilize Docking features. Please be mindful if using this.
// Provide hints:
// - To the platform backend via altered viewport flags (enable/disable OS decoration, OS task bar icons, etc.)
// - To the platform backend for OS level parent/child relationships of viewport.
// - To the docking system for various options and filtering.
ImGuiWindowClass :: struct {
	ClassId : ImGuiID, // User data. 0 = Default class (unclassed). Windows of different classes cannot be docked with each others.
	ParentViewportId : ImGuiID, // Hint for the platform backend. -1: use default. 0: request platform backend to not parent the platform. != 0: request platform backend to create a parent<>child relationship between the platform windows. Not conforming backends are free to e.g. parent every viewport to the main viewport or not.
	FocusRouteParentWindowId : ImGuiID, // ID of parent window for shortcut focus route evaluation, e.g. Shortcut() call from Parent Window will succeed when this window is focused.
	ViewportFlagsOverrideSet : ImGuiViewportFlags, // Viewport flags to set when a window of this class owns a viewport. This allows you to enforce OS decoration or task bar icon, override the defaults on a per-window basis.
	ViewportFlagsOverrideClear : ImGuiViewportFlags, // Viewport flags to clear when a window of this class owns a viewport. This allows you to enforce OS decoration or task bar icon, override the defaults on a per-window basis.
	TabItemFlagsOverrideSet : ImGuiTabItemFlags, // [EXPERIMENTAL] TabItem flags to set when a window of this class gets submitted into a dock node tab bar. May use with ImGuiTabItemFlags_Leading or ImGuiTabItemFlags_Trailing.
	DockNodeFlagsOverrideSet : ImGuiDockNodeFlags, // [EXPERIMENTAL] Dock node flags to set when a window of this class is hosted by a dock node (it doesn't have to be selected!)
	DockingAlwaysTabBar : bool, // Set to true to enforce single floating windows of this class always having their own docking node (equivalent of setting the global io.ConfigDockingAlwaysTabBar)
	DockingAllowUnclassed : bool, // Set to true to allow windows of this class to be docked/merged with an unclassed window. // FIXME-DOCK: Move to DockNodeFlags override?
}

ImGuiWindowClass_init :: proc(this : ^ImGuiWindowClass)
{
	memset(this, 0, size_of(this^)); this.ParentViewportId = cast(ImGuiID) -1; this.DockingAllowUnclassed = true
}

// User data payload for drag and drop operations
// Data payload for Drag and Drop operations: AcceptDragDropPayload(), GetDragDropPayload()
ImGuiPayload :: struct {
	// Members
	Data : rawptr, // Data (copied and owned by dear imgui)
	DataSize : i32, // Data size

	// [Internal]
	SourceId : ImGuiID, // Source item id
	SourceParentId : ImGuiID, // Source parent id (if available)
	DataFrameCount : i32, // Data timestamp
	DataType : [32 + 1]u8, // Data type tag (short user-supplied string, 32 characters max)
	Preview : bool, // Set when AcceptDragDropPayload() was called and mouse has been hovering the target item (nb: handle overlapping drag targets)
	Delivery : bool, // Set when AcceptDragDropPayload() was called and mouse button is released over the target item.
}

ImGuiPayload_init :: proc(this : ^ImGuiPayload) { Clear() }

ImGuiPayload_Clear :: proc(this : ^ImGuiPayload)
{
	this.SourceParentId = 0; this.SourceId = this.SourceParentId; this.Data = nil; this.DataSize = 0; memset(this.DataType, 0, size_of(DataType)); this.DataFrameCount = -1; this.Delivery = false; this.Preview = this.Delivery
}

ImGuiPayload_IsDataType :: proc(this : ^ImGuiPayload, type : ^u8) -> bool { return this.DataFrameCount != -1 && strcmp(type, this.DataType) == 0 }

ImGuiPayload_IsPreview :: proc(this : ^ImGuiPayload) -> bool { return this.Preview }

ImGuiPayload_IsDelivery :: proc(this : ^ImGuiPayload) -> bool { return this.Delivery }

//-----------------------------------------------------------------------------
// [SECTION] Helpers (ImGuiOnceUponAFrame, ImGuiTextFilter, ImGuiTextBuffer, ImGuiStorage, ImGuiListClipper, Math Operators, ImColor)
//-----------------------------------------------------------------------------

// Helper: Unicode defines
IM_UNICODE_CODEPOINT_INVALID :: 0xFFFD// Invalid Unicode code point (standard value).
when IMGUI_USE_WCHAR32 { /* @gen ifdef */
IM_UNICODE_CODEPOINT_MAX :: 0x10FFFF// Maximum Unicode code point supported by this build.
} else { // preproc else
IM_UNICODE_CODEPOINT_MAX :: 0xFFFF// Maximum Unicode code point supported by this build.
} // preproc endif

// Helper for running a block of code not more than once a frame
// Helper: Execute a block of code at maximum once a frame. Convenient if you want to quickly create a UI within deep-nested code that runs multiple times every frame.
// Usage: static ImGuiOnceUponAFrame oaf; if (oaf) ImGui::Text("This will be called only once per frame");
ImGuiOnceUponAFrame :: struct {
	RefFrame : i32,
}

ImGuiOnceUponAFrame_init :: proc(this : ^ImGuiOnceUponAFrame) { this.RefFrame = -1 }

// Helper to parse and apply text filters (e.g. "aaaaa[,bbbbb][,ccccc]")
// Helper: Parse and apply text filters. In format "aaaaa[,bbbb][,ccccc]"
ImGuiTextFilter :: struct {
	InputBuf : [256]u8,
	Filters : ImVector(ImGuiTextFilter_ImGuiTextRange),
	CountGrep : i32,
}

ImGuiTextFilter_Clear :: proc(this : ^ImGuiTextFilter)
{
	this.InputBuf[0] = 0; ImGuiTextFilter_Build(this)
}

ImGuiTextFilter_IsActive :: proc(this : ^ImGuiTextFilter) -> bool { return !empty(&this.Filters) }

// [Internal]
// [Internal]
ImGuiTextFilter_ImGuiTextRange :: struct {
	b : ^u8,
	e : ^u8,
}

ImGuiTextFilter_ImGuiTextRange_init_0 :: proc(this : ^ImGuiTextFilter_ImGuiTextRange) { this.e = nil; this.b = this.e }

ImGuiTextFilter_ImGuiTextRange_init_1 :: proc(this : ^ImGuiTextFilter_ImGuiTextRange, _b : ^u8, _e : ^u8)
{
	this.b = _b; this.e = _e
}

ImGuiTextFilter_ImGuiTextRange_empty :: proc(this : ^ImGuiTextFilter_ImGuiTextRange) -> bool { return this.b == this.e }

// Helper to hold and append into a text buffer (~string builder)
// Helper: Growable text buffer for logging/accumulating text
// (this could be called 'ImGuiTextBuilder' / 'ImGuiStringBuilder')
ImGuiTextBuffer :: struct {
	Buf : ImVector(u8),
}

ImGuiTextBuffer_EmptyString : [1]u8

ImGuiTextBuffer_init :: proc(this : ^ImGuiTextBuffer) { }

ImGuiTextBuffer_begin :: proc(this : ^ImGuiTextBuffer) -> ^u8 { return this.Buf.Data != nil ? &front(&this.Buf) : EmptyString }

// Buf is zero-terminated, so end() will point on the zero-terminator
ImGuiTextBuffer_end :: proc(this : ^ImGuiTextBuffer) -> ^u8 { return this.Buf.Data != nil ? &back(&this.Buf) : EmptyString }

ImGuiTextBuffer_size :: proc(this : ^ImGuiTextBuffer) -> i32 { return this.Buf.Size != 0 ? this.Buf.Size - 1 : 0 }

ImGuiTextBuffer_empty :: proc(this : ^ImGuiTextBuffer) -> bool { return this.Buf.Size <= 1 }

ImGuiTextBuffer_clear :: proc(this : ^ImGuiTextBuffer) { clear(&this.Buf) }

ImGuiTextBuffer_reserve :: proc(this : ^ImGuiTextBuffer, capacity : i32) { reserve(&this.Buf, capacity) }

ImGuiTextBuffer_c_str :: proc(this : ^ImGuiTextBuffer) -> ^u8 { return this.Buf.Data != nil ? this.Buf.Data : EmptyString }

// Helper for key->value storage (pair)
// [Internal] Key+Value for ImGuiStorage
ImGuiStoragePair :: struct {
	key : ImGuiID,
	using _0 : struct #raw_union { val_i : i32, val_f : f32, val_p : rawptr, },
}

ImGuiStoragePair_init_0 :: proc(this : ^ImGuiStoragePair, _key : ImGuiID, _val : i32)
{
	this.key = _key; this.val_i = _val
}

ImGuiStoragePair_init_1 :: proc(this : ^ImGuiStoragePair, _key : ImGuiID, _val : f32)
{
	this.key = _key; this.val_f = _val
}

ImGuiStoragePair_init_2 :: proc(this : ^ImGuiStoragePair, _key : ImGuiID, _val : rawptr)
{
	this.key = _key; this.val_p = _val
}

// Helper for key->value storage (container sorted by key)
// Helper: Key->Value storage
// Typically you don't have to worry about this since a storage is held within each Window.
// We use it to e.g. store collapse state for a tree (Int 0/1)
// This is optimized for efficient lookup (dichotomy into a contiguous buffer) and rare insertion (typically tied to user interactions aka max once a frame)
// You can use it as custom user storage for temporary values. Declare your own storage if, for example:
// - You want to manipulate the open/close state of a particular sub-tree in your interface (tree node uses Int 0/1 to store their state).
// - You want to store custom debug data easily without adding or editing structures in your code (probably not efficient, but convenient)
// Types are NOT stored, so it is up to you to make sure your Key don't collide with different types.
ImGuiStorage :: struct {
	// [Internal]
	Data : ImVector(ImGuiStoragePair),
}

// - Get***() functions find pair, never add/allocate. Pairs are sorted so a query is O(log N)
// - Set***() functions find pair, insertion on demand if missing.
// - Sorted insertion is costly, paid once. A typical frame shouldn't need to insert any new pair.
ImGuiStorage_Clear :: proc(this : ^ImGuiStorage) { clear(&this.Data) }

// Helper to manually clip large list of items
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
ImGuiListClipper :: struct {
	Ctx : ^ImGuiContext, // Parent UI context
	DisplayStart : i32, // First item to display, updated by each call to Step()
	DisplayEnd : i32, // End of items to display (exclusive)
	ItemsCount : i32, // [Internal] Number of items
	ItemsHeight : f32, // [Internal] Height of item after a first step and item submission can calculate it
	StartPosY : f32, // [Internal] Cursor position at the time of Begin() or after table frozen rows are all processed
	StartSeekOffsetY : f64, // [Internal] Account for frozen rows in a table and initial loss of precision in very large windows.
	TempData : rawptr, // [Internal] Internal data
}

// Call IncludeItemByIndex() or IncludeItemsByIndex() *BEFORE* first call to Step() if you need a range of items to not be clipped, regardless of their visibility.
// (Due to alignment / padding of certain items it is possible that an extra item may be included on either end of the display range).
ImGuiListClipper_IncludeItemByIndex :: #force_inline proc(this : ^ImGuiListClipper, item_index : i32) { IncludeItemsByIndex(item_index, item_index + 1) }

// Helpers: ImVec2/ImVec4 operators
// - It is important that we are keeping those disabled by default so they don't leak in user space.
// - This is in order to allow user enabling implicit cast operators between ImVec2/ImVec4 and their own types (using IM_VEC2_CLASS_EXTRA in imconfig.h)
// - Add '#define IMGUI_DEFINE_MATH_OPERATORS' before including this file (or in imconfig.h) to access courtesy maths operators for ImVec2 and ImVec4.
// - We intentionally provide ImVec2*float but not float*ImVec2: this is rare enough and we want to reduce the surface for possible user mistake.
when IMGUI_DEFINE_MATH_OPERATORS { /* @gen ifdef */
IMGUI_DEFINE_MATH_OPERATORS_IMPLEMENTED :: true

} // preproc endif

// Helpers macros to generate 32-bit encoded colors
// - User can declare their own format by #defining the 5 _SHIFT/_MASK macros in their imconfig file.
// - Any setting other than the default will need custom backend support. The only standard backend that supports anything else than the default is DirectX9.
when ! IM_COL32_R_SHIFT { /* @gen ifndef */
when IMGUI_USE_BGRA_PACKED_COLOR { /* @gen ifdef */
IM_COL32_R_SHIFT :: 16
IM_COL32_G_SHIFT :: 8
IM_COL32_B_SHIFT :: 0
IM_COL32_A_SHIFT :: 24
IM_COL32_A_MASK :: 0xFF000000
} else { // preproc else
IM_COL32_R_SHIFT :: 0
IM_COL32_G_SHIFT :: 8
IM_COL32_B_SHIFT :: 16
IM_COL32_A_SHIFT :: 24
IM_COL32_A_MASK :: 0xFF000000
} // preproc endif
} // preproc endif
IM_COL32 :: #force_inline proc "contextless" (R : $T0, G : $T1, B : $T2, A : $T3) //TODO @gen: Validate the parameters were not passed by reference.
{
	(((ImU32)(A)<<IM_COL32_A_SHIFT)|((ImU32)(B)<<IM_COL32_B_SHIFT)|((ImU32)(G)<<IM_COL32_G_SHIFT)|((ImU32)(R)<<IM_COL32_R_SHIFT))
}

IM_COL32_WHITE :: IM_COL32(255,255,255,255)// Opaque white = 0xFFFFFFFF
IM_COL32_BLACK :: IM_COL32(0,0,0,255)// Opaque black
IM_COL32_BLACK_TRANS :: IM_COL32(0,0,0,0)// Transparent black = 0x00000000

// Helper functions to create a color that can be converted to either u32 or float4 (*OBSOLETE* please avoid using)
// Helper: ImColor() implicitly converts colors to either ImU32 (packed 4x1 byte) or ImVec4 (4x1 float)
// Prefer using IM_COL32() macros if you want a guaranteed compile-time ImU32 for usage with ImDrawList API.
// **Avoid storing ImColor! Store either u32 of ImVec4. This is not a full-featured color class. MAY OBSOLETE.
// **None of the ImGui API are using ImColor directly but you can use it as a convenience to pass colors in either ImU32 or ImVec4 formats. Explicitly cast to ImU32 or ImVec4 if needed.
ImColor :: struct {
	Value : ImVec4,

	// FIXME-OBSOLETE: May need to obsolete/cleanup those helpers.
}

ImColor_init_0 :: proc(this : ^ImColor) { }

ImColor_init_1 :: proc(this : ^ImColor, r : f32, g : f32, b : f32, a : f32 = 1.0)
{
	init(&this.Value, r, g, b, a)
}

ImColor_init_2 :: proc(this : ^ImColor, col : ^ImVec4)
{
	init(&this.Value, col)
}

ImColor_init_3 :: proc(this : ^ImColor, r : i32, g : i32, b : i32, a : i32 = 255)
{
	init(&this.Value, cast(f32) r * (1.0 / 255.0), cast(f32) g * (1.0 / 255.0), cast(f32) b * (1.0 / 255.0), cast(f32) a * (1.0 / 255.0))
}

ImColor_init_4 :: proc(this : ^ImColor, rgba : ImU32)
{
	init(&this.Value, cast(f32) ((rgba >> IM_COL32_R_SHIFT) & 0xFF) * (1.0 / 255.0), cast(f32) ((rgba >> IM_COL32_G_SHIFT) & 0xFF) * (1.0 / 255.0), cast(f32) ((rgba >> IM_COL32_B_SHIFT) & 0xFF) * (1.0 / 255.0), cast(f32) ((rgba >> IM_COL32_A_SHIFT) & 0xFF) * (1.0 / 255.0))
}

ImColor_SetHSV :: #force_inline proc(this : ^ImColor, h : f32, s : f32, v : f32, a : f32 = 1.0)
{
	ColorConvertHSVtoRGB(h, s, v, this.Value.x, this.Value.y, this.Value.z); this.Value.w = a
}

ImColor_HSV :: proc(this : ^ImColor, h : f32, s : f32, v : f32, a : f32 = 1.0) -> ImColor
{
	r : f32; g : f32; b : f32; ColorConvertHSVtoRGB(h, s, v, r, g, b); return ImColor_ImColor(this, r, g, b, a)
}

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
ImGuiMultiSelectFlags_ :: enum i32 {
	ImGuiMultiSelectFlags_None = 0,
	ImGuiMultiSelectFlags_SingleSelect = 1 << 0, // Disable selecting more than one item. This is available to allow single-selection code to share same code/logic if desired. It essentially disables the main purpose of BeginMultiSelect() tho!
	ImGuiMultiSelectFlags_NoSelectAll = 1 << 1, // Disable CTRL+A shortcut to select all.
	ImGuiMultiSelectFlags_NoRangeSelect = 1 << 2, // Disable Shift+selection mouse/keyboard support (useful for unordered 2D selection). With BoxSelect is also ensure contiguous SetRange requests are not combined into one. This allows not handling interpolation in SetRange requests.
	ImGuiMultiSelectFlags_NoAutoSelect = 1 << 3, // Disable selecting items when navigating (useful for e.g. supporting range-select in a list of checkboxes).
	ImGuiMultiSelectFlags_NoAutoClear = 1 << 4, // Disable clearing selection when navigating or selecting another one (generally used with ImGuiMultiSelectFlags_NoAutoSelect. useful for e.g. supporting range-select in a list of checkboxes).
	ImGuiMultiSelectFlags_NoAutoClearOnReselect = 1 << 5, // Disable clearing selection when clicking/selecting an already selected item.
	ImGuiMultiSelectFlags_BoxSelect1d = 1 << 6, // Enable box-selection with same width and same x pos items (e.g. full row Selectable()). Box-selection works better with little bit of spacing between items hit-box in order to be able to aim at empty space.
	ImGuiMultiSelectFlags_BoxSelect2d = 1 << 7, // Enable box-selection with varying width or varying x pos items support (e.g. different width labels, or 2D layout/grid). This is slower: alters clipping logic so that e.g. horizontal movements will update selection of normally clipped items.
	ImGuiMultiSelectFlags_BoxSelectNoScroll = 1 << 8, // Disable scrolling when box-selecting near edges of scope.
	ImGuiMultiSelectFlags_ClearOnEscape = 1 << 9, // Clear selection when pressing Escape while scope is focused.
	ImGuiMultiSelectFlags_ClearOnClickVoid = 1 << 10, // Clear selection when clicking on empty location within scope.
	ImGuiMultiSelectFlags_ScopeWindow = 1 << 11, // Scope for _BoxSelect and _ClearOnClickVoid is whole window (Default). Use if BeginMultiSelect() covers a whole window or used a single time in same window.
	ImGuiMultiSelectFlags_ScopeRect = 1 << 12, // Scope for _BoxSelect and _ClearOnClickVoid is rectangle encompassing BeginMultiSelect()/EndMultiSelect(). Use if BeginMultiSelect() is called multiple times in same window.
	ImGuiMultiSelectFlags_SelectOnClick = 1 << 13, // Apply selection on mouse down when clicking on unselected item. (Default)
	ImGuiMultiSelectFlags_SelectOnClickRelease = 1 << 14, // Apply selection on mouse release when clicking an unselected item. Allow dragging an unselected item without altering selection.
	//ImGuiMultiSelectFlags_RangeSelect2d       = 1 << 15,  // Shift+Selection uses 2d geometry instead of linear sequence, so possible to use Shift+up/down to select vertically in grid. Analogous to what BoxSelect does.
	ImGuiMultiSelectFlags_NavWrapX = 1 << 16, // [Temporary] Enable navigation wrapping on X axis. Provided as a convenience because we don't have a design for the general Nav API for this yet. When the more general feature be public we may obsolete this flag in favor of new one.
}

// Structure to interact with a BeginMultiSelect()/EndMultiSelect() block
// Main IO structure returned by BeginMultiSelect()/EndMultiSelect().
// This mainly contains a list of selection requests.
// - Use 'Demo->Tools->Debug Log->Selection' to see requests as they happen.
// - Some fields are only useful if your list is dynamic and allows deletion (getting post-deletion focus/state right is shown in the demo)
// - Below: who reads/writes each fields? 'r'=read, 'w'=write, 'ms'=multi-select code, 'app'=application/user code.
ImGuiMultiSelectIO :: struct {
	//------------------------------------------// BeginMultiSelect / EndMultiSelect
	Requests : ImVector(ImGuiSelectionRequest), //  ms:w, app:r     /  ms:w  app:r   // Requests to apply to your selection data.
	RangeSrcItem : ImGuiSelectionUserData, //  ms:w  app:r     /                // (If using clipper) Begin: Source item (often the first selected item) must never be clipped: use clipper.IncludeItemByIndex() to ensure it is submitted.
	NavIdItem : ImGuiSelectionUserData, //  ms:w, app:r     /                // (If using deletion) Last known SetNextItemSelectionUserData() value for NavId (if part of submitted items).
	NavIdSelected : bool, //  ms:w, app:r     /        app:r   // (If using deletion) Last known selection state for NavId (if part of submitted items).
	RangeSrcReset : bool, //        app:w     /  ms:r          // (If using deletion) Set before EndMultiSelect() to reset ResetSrcItem (e.g. if deleted selection).
	ItemsCount : i32, //  ms:w, app:r     /        app:r   // 'int items_count' parameter to BeginMultiSelect() is copied here for convenience, allowing simpler calls to your ApplyRequests handler. Not used internally.
}

// Selection request type
ImGuiSelectionRequestType :: enum i32 {
	ImGuiSelectionRequestType_None = 0,
	ImGuiSelectionRequestType_SetAll, // Request app to clear selection (if Selected==false) or select all items (if Selected==true). We cannot set RangeFirstItem/RangeLastItem as its contents is entirely up to user (not necessarily an index)
	ImGuiSelectionRequestType_SetRange, // Request app to select/unselect [RangeFirstItem..RangeLastItem] items (inclusive) based on value of Selected. Only EndMultiSelect() request this, app code can read after BeginMultiSelect() and it will always be false.
}

// A selection request (stored in ImGuiMultiSelectIO)
// Selection request item
ImGuiSelectionRequest :: struct {
	//------------------------------------------// BeginMultiSelect / EndMultiSelect
	Type : ImGuiSelectionRequestType, //  ms:w, app:r     /  ms:w, app:r   // Request type. You'll most often receive 1 Clear + 1 SetRange with a single-item range.
	Selected : bool, //  ms:w, app:r     /  ms:w, app:r   // Parameter for SetAll/SetRange requests (true = select, false = unselect)
	RangeDirection : ImS8, //                  /  ms:w  app:r   // Parameter for SetRange request: +1 when RangeFirstItem comes before RangeLastItem, -1 otherwise. Useful if you want to preserve selection order on a backward Shift+Click.
	RangeFirstItem : ImGuiSelectionUserData, //                  /  ms:w, app:r   // Parameter for SetRange request (this is generally == RangeSrcItem when shift selecting from top to bottom).
	RangeLastItem : ImGuiSelectionUserData, //                  /  ms:w, app:r   // Parameter for SetRange request (this is generally == RangeSrcItem when shift selecting from bottom to top). Inclusive!
}

// Optional helper to store multi-selection state + apply multi-selection requests.
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
ImGuiSelectionBasicStorage :: struct {
	// Members
	Size : i32, //          // Number of selected items, maintained by this helper.
	PreserveOrder : bool, // = false  // GetNextSelectedItem() will return ordered selection (currently implemented by two additional sorts of selection. Could be improved)
	UserData : rawptr, // = NULL   // User data for use by adapter function        // e.g. selection.UserData = (void*)my_items;
	AdapterIndexToStorageId : proc(self : ^ImGuiSelectionBasicStorage, idx : i32) -> ImGuiID, // e.g. selection.AdapterIndexToStorageId = [](ImGuiSelectionBasicStorage* self, int idx) { return ((MyItems**)self->UserData)[idx]->ID; };
	_SelectionOrder : i32, // [Internal] Increasing counter to store selection order
	_Storage : ImGuiStorage, // [Internal] Selection set. Think of this as similar to e.g. std::set<ImGuiID>. Prefer not accessing directly: iterate with GetNextSelectedItem().
}

// Convert index to item id based on provided adapter.
ImGuiSelectionBasicStorage_GetStorageIdFromIndex :: #force_inline proc(this : ^ImGuiSelectionBasicStorage, idx : i32) -> ImGuiID { return AdapterIndexToStorageId(this, idx) }

//Optional helper to apply multi-selection requests to existing randomly accessible storage.
// Optional helper to apply multi-selection requests to existing randomly accessible storage.
// Convenient if you want to quickly wire multi-select API on e.g. an array of bool or items storing their own selection state.
ImGuiSelectionExternalStorage :: struct {
	// Members
	UserData : rawptr, // User data for use by adapter function                                // e.g. selection.UserData = (void*)my_items;
	AdapterSetItemSelected : proc(self : ^ImGuiSelectionExternalStorage, idx : i32, selected : bool), // e.g. AdapterSetItemSelected = [](ImGuiSelectionExternalStorage* self, int idx, bool selected) { ((MyItems**)self->UserData)[idx]->Selected = selected; }
}

//-----------------------------------------------------------------------------
// [SECTION] Drawing API (ImDrawCmd, ImDrawIdx, ImDrawVert, ImDrawChannel, ImDrawListSplitter, ImDrawListFlags, ImDrawList, ImDrawData)
// Hold a series of drawing commands. The user provides a renderer for ImDrawData which essentially contains an array of ImDrawList.
//-----------------------------------------------------------------------------

// The maximum line width to bake anti-aliased textures for. Build atlas with ImFontAtlasFlags_NoBakedLines to disable baking.
when ! IM_DRAWLIST_TEX_LINES_WIDTH_MAX { /* @gen ifndef */
IM_DRAWLIST_TEX_LINES_WIDTH_MAX :: (63)
} // preproc endif

// ImDrawCallback: Draw callbacks for advanced uses [configurable type: override in imconfig.h]
// NB: You most likely do NOT need to use draw callbacks just to create your own widget or customized UI rendering,
// you can poke into the draw list for that! Draw callback may be useful for example to:
//  A) Change your GPU render state,
//  B) render a complex 3D scene inside a UI element without an intermediate texture/render target, etc.
// The expected behavior from your rendering function is 'if (cmd.UserCallback != NULL) { cmd.UserCallback(parent_list, cmd); } else { RenderTriangles() }'
// If you want to override the signature of ImDrawCallback, you can simply use e.g. '#define ImDrawCallback MyDrawCallback' (in imconfig.h) + update rendering backend accordingly.
when ! ImDrawCallback { /* @gen ifndef */
ImDrawCallback :: proc(parent_list : ^ImDrawList, cmd : ^ImDrawCmd)
} // preproc endif

// Special Draw callback value to request renderer backend to reset the graphics/render state.
// The renderer backend needs to handle this special value, otherwise it will crash trying to call a function at this address.
// This is useful, for example, if you submitted callbacks which you know have altered the render state and you want it to be restored.
// Render state is not reset by default because they are many perfectly useful way of altering render state (e.g. changing shader/blending settings before an Image call).
ImDrawCallback_ResetRenderState :: (ImDrawCallback)(-8)

// A single draw command within a parent ImDrawList (generally maps to 1 GPU draw call, unless it is a callback)
// Typically, 1 command = 1 GPU draw call (unless command is a callback)
// - VtxOffset: When 'io.BackendFlags & ImGuiBackendFlags_RendererHasVtxOffset' is enabled,
//   this fields allow us to render meshes larger than 64K vertices while keeping 16-bit indices.
//   Backends made for <1.71. will typically ignore the VtxOffset fields.
// - The ClipRect/TextureId/VtxOffset fields must be contiguous as we memcmp() them together (this is asserted for).
ImDrawCmd :: struct {
	ClipRect : ImVec4, // 4*4  // Clipping rectangle (x1, y1, x2, y2). Subtract ImDrawData->DisplayPos to get clipping rectangle in "viewport" coordinates
	TextureId : ImTextureID, // 4-8  // User-provided texture ID. Set by user in ImfontAtlas::SetTexID() for fonts or passed to Image*() functions. Ignore if never using images or multiple fonts atlas.
	VtxOffset : u32, // 4    // Start offset in vertex buffer. ImGuiBackendFlags_RendererHasVtxOffset: always 0, otherwise may be >0 to support meshes larger than 64K vertices with 16-bit indices.
	IdxOffset : u32, // 4    // Start offset in index buffer.
	ElemCount : u32, // 4    // Number of indices (multiple of 3) to be rendered as triangles. Vertices are stored in the callee ImDrawList's vtx_buffer[] array, indices in idx_buffer[].
	UserCallback : ImDrawCallback, // 4-8  // If != NULL, call the function instead of rendering the vertices. clip_rect and texture_id will be set normally.
	UserCallbackData : rawptr, // 4-8  // Callback user data (when UserCallback != NULL). If called AddCallback() with size == 0, this is a copy of the AddCallback() argument. If called AddCallback() with size > 0, this is pointing to a buffer where data is stored.
	UserCallbackDataSize : i32, // 4 // Size of callback user data when using storage, otherwise 0.
	UserCallbackDataOffset : i32, // 4 // [Internal] Offset of callback user data when using storage, otherwise -1.
}

// Also ensure our padding fields are zeroed
ImDrawCmd_init :: proc(this : ^ImDrawCmd) { memset(this, 0, size_of(this^)) }

// Since 1.83: returns ImTextureID associated with this draw call. Warning: DO NOT assume this is always same as 'TextureId' (we will change this function for an upcoming feature)
ImDrawCmd_GetTexID :: #force_inline proc(this : ^ImDrawCmd) -> ImTextureID { return this.TextureId }

// Vertex layout
when ! IMGUI_OVERRIDE_DRAWVERT_STRUCT_LAYOUT { /* @gen ifndef */
// A single vertex (pos + uv + col = 20 bytes by default. Override layout with IMGUI_OVERRIDE_DRAWVERT_STRUCT_LAYOUT)
ImDrawVert :: struct {
	pos : ImVec2,
	uv : ImVec2,
	col : ImU32,
}
} else { // preproc else
// You can override the vertex format layout by defining IMGUI_OVERRIDE_DRAWVERT_STRUCT_LAYOUT in imconfig.h
// The code expect ImVec2 pos (8 bytes), ImVec2 uv (8 bytes), ImU32 col (4 bytes), but you can re-order them or add other fields as needed to simplify integration in your engine.
// The type has to be described within the macro (you can either declare the struct or use a typedef). This is because ImVec2/ImU32 are likely not declared at the time you'd want to set your type up.
// NOTE: IMGUI DOESN'T CLEAR THE STRUCTURE AND DOESN'T CALL A CONSTRUCTOR SO ANY CUSTOM FIELD WILL BE UNINITIALIZED. IF YOU ADD EXTRA FIELDS (SUCH AS A 'Z' COORDINATES) YOU WILL NEED TO CLEAR THEM DURING RENDER OR TO IGNORE THEM.
//IMGUI_OVERRIDE_DRAWVERT_STRUCT_LAYOUT;
} // preproc endif

// [Internal] For use by ImDrawList
ImDrawCmdHeader :: struct {
	ClipRect : ImVec4,
	TextureId : ImTextureID,
	VtxOffset : u32,
}

// Forward declarations
// Temporary storage to output draw commands out of order, used by ImDrawListSplitter and ImDrawList::ChannelsSplit()
// [Internal] For use by ImDrawListSplitter
ImDrawChannel :: struct {
	_CmdBuffer : ImVector(ImDrawCmd),
	_IdxBuffer : ImVector(ImDrawIdx),
}


// Helper to split a draw list into different layers which can be drawn into out of order, then flattened back.
// Split/Merge functions are used to split the draw list into different layers which can be drawn into out of order.
// This is used by the Columns/Tables API, so items of each column can be batched together in a same draw call.
ImDrawListSplitter :: struct {
	_Current : i32, // Current channel number (0)
	_Count : i32, // Number of active channels (1+)
	_Channels : ImVector(ImDrawChannel), // Draw channels (not resized down so _Count might be < Channels.Size)
}

ImDrawListSplitter_deinit :: proc(this : ^ImDrawListSplitter)
{ClearFreeMemory()}

ImDrawListSplitter_init :: #force_inline proc(this : ^ImDrawListSplitter) { memset(this, 0, size_of(this^)) }

// Do not clear Channels[] so our allocations are reused next frame
ImDrawListSplitter_Clear :: #force_inline proc(this : ^ImDrawListSplitter)
{
	this._Current = 0; this._Count = 1
}

// Flags for ImDrawList functions
// (Legacy: bit 0 must always correspond to ImDrawFlags_Closed to be backward compatible with old API using a bool. Bits 1..3 must be unused)
ImDrawFlags_ :: enum i32 {
	ImDrawFlags_None = 0,
	ImDrawFlags_Closed = 1 << 0, // PathStroke(), AddPolyline(): specify that shape should be closed (Important: this is always == 1 for legacy reason)
	ImDrawFlags_RoundCornersTopLeft = 1 << 4, // AddRect(), AddRectFilled(), PathRect(): enable rounding top-left corner only (when rounding > 0.0f, we default to all corners). Was 0x01.
	ImDrawFlags_RoundCornersTopRight = 1 << 5, // AddRect(), AddRectFilled(), PathRect(): enable rounding top-right corner only (when rounding > 0.0f, we default to all corners). Was 0x02.
	ImDrawFlags_RoundCornersBottomLeft = 1 << 6, // AddRect(), AddRectFilled(), PathRect(): enable rounding bottom-left corner only (when rounding > 0.0f, we default to all corners). Was 0x04.
	ImDrawFlags_RoundCornersBottomRight = 1 << 7, // AddRect(), AddRectFilled(), PathRect(): enable rounding bottom-right corner only (when rounding > 0.0f, we default to all corners). Wax 0x08.
	ImDrawFlags_RoundCornersNone = 1 << 8, // AddRect(), AddRectFilled(), PathRect(): disable rounding on all corners (when rounding > 0.0f). This is NOT zero, NOT an implicit flag!
	ImDrawFlags_RoundCornersTop = ImDrawFlags_RoundCornersTopLeft | ImDrawFlags_RoundCornersTopRight,
	ImDrawFlags_RoundCornersBottom = ImDrawFlags_RoundCornersBottomLeft | ImDrawFlags_RoundCornersBottomRight,
	ImDrawFlags_RoundCornersLeft = ImDrawFlags_RoundCornersBottomLeft | ImDrawFlags_RoundCornersTopLeft,
	ImDrawFlags_RoundCornersRight = ImDrawFlags_RoundCornersBottomRight | ImDrawFlags_RoundCornersTopRight,
	ImDrawFlags_RoundCornersAll = ImDrawFlags_RoundCornersTopLeft | ImDrawFlags_RoundCornersTopRight | ImDrawFlags_RoundCornersBottomLeft | ImDrawFlags_RoundCornersBottomRight,
	ImDrawFlags_RoundCornersDefault_ = ImDrawFlags_RoundCornersAll, // Default to ALL corners if none of the _RoundCornersXX flags are specified.
	ImDrawFlags_RoundCornersMask_ = ImDrawFlags_RoundCornersAll | ImDrawFlags_RoundCornersNone,
}

// Flags for ImDrawList instance. Those are set automatically by ImGui:: functions from ImGuiIO settings, and generally not manipulated directly.
// It is however possible to temporarily alter flags between calls to ImDrawList:: functions.
ImDrawListFlags_ :: enum i32 {
	ImDrawListFlags_None = 0,
	ImDrawListFlags_AntiAliasedLines = 1 << 0, // Enable anti-aliased lines/borders (*2 the number of triangles for 1.0f wide line or lines thin enough to be drawn using textures, otherwise *3 the number of triangles)
	ImDrawListFlags_AntiAliasedLinesUseTex = 1 << 1, // Enable anti-aliased lines/borders using textures when possible. Require backend to render with bilinear filtering (NOT point/nearest filtering).
	ImDrawListFlags_AntiAliasedFill = 1 << 2, // Enable anti-aliased edge around filled shapes (rounded rectangles, circles).
	ImDrawListFlags_AllowVtxOffset = 1 << 3, // Can emit 'VtxOffset > 0' to allow large meshes. Set when 'ImGuiBackendFlags_RendererHasVtxOffset' is enabled.
}

// A single draw command list (generally one per window, conceptually you may see this as a dynamic "mesh" builder)
// Draw command list
// This is the low-level list of polygons that ImGui:: functions are filling. At the end of the frame,
// all command lists are passed to your ImGuiIO::RenderDrawListFn function for rendering.
// Each dear imgui window contains its own ImDrawList. You can use ImGui::GetWindowDrawList() to
// access the current window draw list and draw custom primitives.
// You can interleave normal ImGui:: calls and adding primitives to the current draw list.
// In single viewport mode, top-left is == GetMainViewport()->Pos (generally 0,0), bottom-right is == GetMainViewport()->Pos+Size (generally io.DisplaySize).
// You are totally free to apply whatever transformation matrix you want to the data (depending on the use of the transformation you may want to apply it to ClipRect as well!)
// Important: Primitives are always added to the list and not culled (culling is done at higher-level by ImGui:: functions), if you use this API a lot consider coarse culling your drawn objects.
ImDrawList :: struct {
	// This is what you have to render
	CmdBuffer : ImVector(ImDrawCmd), // Draw commands. Typically 1 command = 1 GPU draw call, unless the command is a callback.
	IdxBuffer : ImVector(ImDrawIdx), // Index buffer. Each command consume ImDrawCmd::ElemCount of those
	VtxBuffer : ImVector(ImDrawVert), // Vertex buffer.
	Flags : ImDrawListFlags, // Flags, you may poke into these to adjust anti-aliasing settings per-primitive.

	// [Internal, used while building lists]
	_VtxCurrentIdx : u32, // [Internal] generally == VtxBuffer.Size unless we are past 64K vertices, in which case this gets reset to 0.
	_Data : ^ImDrawListSharedData, // Pointer to shared draw data (you can use ImGui::GetDrawListSharedData() to get the one from current ImGui context)
	_VtxWritePtr : ^ImDrawVert, // [Internal] point within VtxBuffer.Data after each add command (to avoid using the ImVector<> operators too much)
	_IdxWritePtr : ^ImDrawIdx, // [Internal] point within IdxBuffer.Data after each add command (to avoid using the ImVector<> operators too much)
	_Path : ImVector(ImVec2), // [Internal] current path building
	_CmdHeader : ImDrawCmdHeader, // [Internal] template of active commands. Fields should match those of CmdBuffer.back().
	_Splitter : ImDrawListSplitter, // [Internal] for channels api (note: prefer using your own persistent instance of ImDrawListSplitter!)
	_ClipRectStack : ImVector(ImVec4), // [Internal]
	_TextureIdStack : ImVector(ImTextureID), // [Internal]
	_CallbacksDataBuf : ImVector(ImU8), // [Internal]
	_FringeScale : f32, // [Internal] anti-alias fringe is scaled by this value, this helps to keep things sharp while zooming at vertex buffer content
	_OwnerName : ^u8, // Pointer to owner window's name for debugging
}

ImDrawList_GetClipRectMin :: #force_inline proc(this : ^ImDrawList) -> ImVec2
{
	cr : ^ImVec4 = back(&this._ClipRectStack); return ImVec2(cr.x, cr.y)
}

ImDrawList_GetClipRectMax :: #force_inline proc(this : ^ImDrawList) -> ImVec2
{
	cr : ^ImVec4 = back(&this._ClipRectStack); return ImVec2(cr.z, cr.w)
}

// Stateful path API, add points then finish with PathFillConvex() or PathStroke()
// - Important: filled shapes must always use clockwise winding order! The anti-aliasing fringe depends on it. Counter-clockwise shapes will have "inward" anti-aliasing.
//   so e.g. 'PathArcTo(center, radius, PI * -0.5f, PI)' is ok, whereas 'PathArcTo(center, radius, PI, PI * -0.5f)' won't have correct anti-aliasing when followed by PathFillConvex().
ImDrawList_PathClear :: #force_inline proc(this : ^ImDrawList) { this._Path.Size = 0 }

ImDrawList_PathLineTo :: #force_inline proc(this : ^ImDrawList, pos : ^ImVec2) { push_back(&this._Path, pos) }

ImDrawList_PathLineToMergeDuplicate :: #force_inline proc(this : ^ImDrawList, pos : ^ImVec2) { if this._Path.Size == 0 || memcmp(&this._Path.Data[this._Path.Size - 1], &pos, 8) != 0 { push_back(&this._Path, pos) } }

ImDrawList_PathFillConvex :: #force_inline proc(this : ^ImDrawList, col : ImU32)
{
	ImDrawList_AddConvexPolyFilled(this, this._Path.Data, this._Path.Size, col); this._Path.Size = 0
}

ImDrawList_PathFillConcave :: #force_inline proc(this : ^ImDrawList, col : ImU32)
{
	ImDrawList_AddConcavePolyFilled(this, this._Path.Data, this._Path.Size, col); this._Path.Size = 0
}

ImDrawList_PathStroke :: #force_inline proc(this : ^ImDrawList, col : ImU32, flags : ImDrawFlags = 0, thickness : f32 = 1.0)
{
	ImDrawList_AddPolyline(this, this._Path.Data, this._Path.Size, col, flags, thickness); this._Path.Size = 0
}

// Advanced: Channels
// - Use to split render into layers. By switching channels to can render out-of-order (e.g. submit FG primitives before BG primitives)
// - Use to minimize draw calls (e.g. if going back-and-forth between multiple clipping rectangles, prefer to append into separate channels then merge at the end)
// - This API shouldn't have been in ImDrawList in the first place!
//   Prefer using your own persistent instance of ImDrawListSplitter as you can stack them.
//   Using the ImDrawList::ChannelsXXXX you cannot stack a split over another.
ImDrawList_ChannelsSplit :: #force_inline proc(this : ^ImDrawList, count : i32) { Split(&this._Splitter, this, count) }

ImDrawList_ChannelsMerge :: #force_inline proc(this : ^ImDrawList) { Merge(&this._Splitter, this) }

ImDrawList_ChannelsSetCurrent :: #force_inline proc(this : ^ImDrawList, n : i32) { SetCurrentChannel(&this._Splitter, this, n) }

ImDrawList_PrimWriteVtx :: #force_inline proc(this : ^ImDrawList, pos : ^ImVec2, uv : ^ImVec2, col : ImU32)
{
	this._VtxWritePtr.pos = pos; this._VtxWritePtr.uv = uv; this._VtxWritePtr.col = col; post_incr(&this._VtxWritePtr); post_incr(&this._VtxCurrentIdx)
}

ImDrawList_PrimWriteIdx :: #force_inline proc(this : ^ImDrawList, idx : ImDrawIdx)
{
	this._IdxWritePtr^ = idx; post_incr(&this._IdxWritePtr)
}

// Write vertex with unique index
ImDrawList_PrimVtx :: #force_inline proc(this : ^ImDrawList, pos : ^ImVec2, uv : ^ImVec2, col : ImU32)
{
	ImDrawList_PrimWriteIdx(this, cast(ImDrawIdx) this._VtxCurrentIdx); ImDrawList_PrimWriteVtx(this, pos, uv, col)
}

// All draw command lists required to render the frame + pos/size coordinates to use for the projection matrix.
// All draw data to render a Dear ImGui frame
// (NB: the style and the naming convention here is a little inconsistent, we currently preserve them for backward compatibility purpose,
// as this is one of the oldest structure exposed by the library! Basically, ImDrawList == CmdList)
ImDrawData :: struct {
	Valid : bool, // Only valid after Render() is called and before the next NewFrame() is called.
	CmdListsCount : i32, // Number of ImDrawList* to render
	TotalIdxCount : i32, // For convenience, sum of all ImDrawList's IdxBuffer.Size
	TotalVtxCount : i32, // For convenience, sum of all ImDrawList's VtxBuffer.Size
	CmdLists : ImVector(^ImDrawList), // Array of ImDrawList* to render. The ImDrawLists are owned by ImGuiContext and only pointed to from here.
	DisplayPos : ImVec2, // Top-left position of the viewport to render (== top-left of the orthogonal projection matrix to use) (== GetMainViewport()->Pos for the main viewport, == (0.0) in most single-viewport applications)
	DisplaySize : ImVec2, // Size of the viewport to render (== GetMainViewport()->Size for the main viewport, == io.DisplaySize in most single-viewport applications)
	FramebufferScale : ImVec2, // Amount of pixels for each unit of DisplaySize. Based on io.DisplayFramebufferScale. Generally (1,1) on normal display, (2,2) on OSX with Retina display.
	OwnerViewport : ^ImGuiViewport, // Viewport carrying the ImDrawData instance, might be of use to the renderer (generally not).
}

// Functions
ImDrawData_init :: proc(this : ^ImDrawData) { Clear() }

// Configuration data when adding a font or merging fonts
//-----------------------------------------------------------------------------
// [SECTION] Font API (ImFontConfig, ImFontGlyph, ImFontAtlasFlags, ImFontAtlas, ImFontGlyphRangesBuilder, ImFont)
//-----------------------------------------------------------------------------

ImFontConfig :: struct {
	FontData : rawptr, //          // TTF/OTF data
	FontDataSize : i32, //          // TTF/OTF data size
	FontDataOwnedByAtlas : bool, // true     // TTF/OTF data ownership taken by the container ImFontAtlas (will delete memory itself).
	FontNo : i32, // 0        // Index of font within TTF/OTF file
	SizePixels : f32, //          // Size in pixels for rasterizer (more or less maps to the resulting font height).
	OversampleH : i32, // 2        // Rasterize at higher quality for sub-pixel positioning. Note the difference between 2 and 3 is minimal. You can reduce this to 1 for large glyphs save memory. Read https://github.com/nothings/stb/blob/master/tests/oversample/README.md for details.
	OversampleV : i32, // 1        // Rasterize at higher quality for sub-pixel positioning. This is not really useful as we don't use sub-pixel positions on the Y axis.
	PixelSnapH : bool, // false    // Align every glyph AdvanceX to pixel boundaries. Useful e.g. if you are merging a non-pixel aligned font with the default font. If enabled, you can set OversampleH/V to 1.
	GlyphExtraSpacing : ImVec2, // 0, 0     // Extra spacing (in pixels) between glyphs when rendered: essentially add to glyph->AdvanceX. Only X axis is supported for now.
	GlyphOffset : ImVec2, // 0, 0     // Offset all glyphs from this font input.
	GlyphRanges : ^ImWchar, // NULL     // THE ARRAY DATA NEEDS TO PERSIST AS LONG AS THE FONT IS ALIVE. Pointer to a user-provided list of Unicode range (2 value per range, values are inclusive, zero-terminated list).
	GlyphMinAdvanceX : f32, // 0        // Minimum AdvanceX for glyphs, set Min to align font icons, set both Min/Max to enforce mono-space font
	GlyphMaxAdvanceX : f32, // FLT_MAX  // Maximum AdvanceX for glyphs
	MergeMode : bool, // false    // Merge into previous ImFont, so you can combine multiple inputs font into one ImFont (e.g. ASCII font + icons + Japanese glyphs). You may want to use GlyphOffset.y when merge font of different heights.
	FontBuilderFlags : u32, // 0        // Settings for custom font builder. THIS IS BUILDER IMPLEMENTATION DEPENDENT. Leave as zero if unsure.
	RasterizerMultiply : f32, // 1.0f     // Linearly brighten (>1.0f) or darken (<1.0f) font output. Brightening small fonts may be a good workaround to make them more readable. This is a silly thing we may remove in the future.
	RasterizerDensity : f32, // 1.0f     // DPI scale for rasterization, not altering other font metrics: make it easy to swap between e.g. a 100% and a 400% fonts for a zooming display. IMPORTANT: If you increase this it is expected that you increase font scale accordingly, otherwise quality may look lowered.
	EllipsisChar : ImWchar, // 0        // Explicitly specify unicode codepoint of ellipsis character. When fonts are being merged first specified ellipsis will be used.

	// [Internal]
	Name : [40]u8, // Name (strictly to ease debugging)
	DstFont : ^ImFont,
}

// A single font glyph (code point + coordinates within in ImFontAtlas + offset)
// Hold rendering data for one glyph.
// (Note: some language parsers may fail to convert the 31+1 bitfield members, in this case maybe drop store a single u32 or we can rework this)
ImFontGlyph :: struct {
	using _0 : bit_field u32 {
		Colored : u32 | 1, // Flag to indicate glyph is colored and should generally ignore tinting (make it usable with no shift on little-endian as this is used in loops)
		Visible : u32 | 1, // Flag to indicate glyph has no visible pixels (e.g. space). Allow early out when rendering.
		Codepoint : u32 | 30, // 0x0000..0x10FFFF
	},
	AdvanceX : f32, // Distance to next character (= data from font + ImFontConfig::GlyphExtraSpacing.x baked in)
	X0 : f32, Y0 : f32, X1 : f32, Y1 : f32, // Glyph corners
	U0 : f32, V0 : f32, U1 : f32, V1 : f32, // Texture coordinates
}

// Helper to build glyph ranges from text/string data
// Helper to build glyph ranges from text/string data. Feed your application strings/characters to it then call BuildRanges().
// This is essentially a tightly packed of vector of 64k booleans = 8KB storage.
ImFontGlyphRangesBuilder :: struct {
	UsedChars : ImVector(ImU32), // Store 1-bit per Unicode code point (0=unused, 1=used)
}

ImFontGlyphRangesBuilder_init :: proc(this : ^ImFontGlyphRangesBuilder) { Clear() }

ImFontGlyphRangesBuilder_Clear :: #force_inline proc(this : ^ImFontGlyphRangesBuilder)
{
	size_in_bytes : i32 = (IM_UNICODE_CODEPOINT_MAX + 1) / 8; resize(&this.UsedChars, size_in_bytes / cast(i32) size_of(ImU32)); memset(this.UsedChars.Data, 0, cast(uint) size_in_bytes)
}

// Get bit n in the array
ImFontGlyphRangesBuilder_GetBit :: #force_inline proc(this : ^ImFontGlyphRangesBuilder, n : uint) -> bool
{
	off : i32 = cast(i32) (n >> 5); mask : ImU32 = 1 << (n & 31); return (this.UsedChars[off] & mask) != nil
}

// Set bit n in the array
ImFontGlyphRangesBuilder_SetBit :: #force_inline proc(this : ^ImFontGlyphRangesBuilder, n : uint)
{
	off : i32 = cast(i32) (n >> 5); mask : ImU32 = 1 << (n & 31); this.UsedChars[off] |= mask
}

// Add character
ImFontGlyphRangesBuilder_AddChar :: #force_inline proc(this : ^ImFontGlyphRangesBuilder, c : ImWchar) { ImFontGlyphRangesBuilder_SetBit(this, c) }

// See ImFontAtlas::AddCustomRectXXX functions.
ImFontAtlasCustomRect :: struct {
	X : u16, Y : u16, // Output   // Packed position in Atlas

	// [Internal]
	Width : u16, Height : u16, // Input    // Desired rectangle dimension
	using _0 : bit_field u32 {
		GlyphID : u32 | 31, // Input    // For custom font glyphs only (ID < 0x110000)
		GlyphColored : u32 | 1, // Input  // For custom font glyphs only: glyph is colored, removed tinting.
	},
	GlyphAdvanceX : f32, // Input    // For custom font glyphs only: glyph xadvance
	GlyphOffset : ImVec2, // Input    // For custom font glyphs only: glyph display offset
	Font : ^ImFont, // Input    // For custom font glyphs only: target font
}

ImFontAtlasCustomRect_init :: proc(this : ^ImFontAtlasCustomRect)
{
	this.Y = 0xFFFF; this.X = this.Y; this.Height = 0; this.Width = this.Height; this.GlyphID = 0; this.GlyphColored = 0; this.GlyphAdvanceX = 0.0; this.GlyphOffset = ImVec2(0, 0); this.Font = nil
}

ImFontAtlasCustomRect_IsPacked :: proc(this : ^ImFontAtlasCustomRect) -> bool { return this.X != 0xFFFF }

// Flags for ImFontAtlas build
ImFontAtlasFlags_ :: enum i32 {
	ImFontAtlasFlags_None = 0,
	ImFontAtlasFlags_NoPowerOfTwoHeight = 1 << 0, // Don't round the height to next power of two
	ImFontAtlasFlags_NoMouseCursors = 1 << 1, // Don't build software mouse cursors into the atlas (save a little texture memory)
	ImFontAtlasFlags_NoBakedLines = 1 << 2, // Don't build thick line textures into the atlas (save a little texture memory, allow support for point/nearest filtering). The AntiAliasedLinesUseTex features uses them, otherwise they will be rendered using polygons (more expensive for CPU/GPU).
}

// Runtime data for multiple fonts, bake multiple fonts into a single texture, TTF/OTF font loader
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
ImFontAtlas :: struct {
	//-------------------------------------------
	// Members
	//-------------------------------------------

	Flags : ImFontAtlasFlags, // Build flags (see ImFontAtlasFlags_)
	TexID : ImTextureID, // User data to refer to the texture once it has been uploaded to user's graphic systems. It is passed back to you during rendering via the ImDrawCmd structure.
	TexDesiredWidth : i32, // Texture width desired by user before Build(). Must be a power-of-two. If have many glyphs your graphics API have texture size restrictions you may want to increase texture width to decrease height.
	TexGlyphPadding : i32, // FIXME: Should be called "TexPackPadding". Padding between glyphs within texture in pixels. Defaults to 1. If your rendering method doesn't rely on bilinear filtering you may set this to 0 (will also need to set AntiAliasedLinesUseTex = false).
	Locked : bool, // Marked as Locked by ImGui::NewFrame() so attempt to modify the atlas will assert.
	UserData : rawptr, // Store your own atlas related user-data (if e.g. you have multiple font atlas).

	// [Internal]
	// NB: Access texture data via GetTexData*() calls! Which will setup a default font for you.
	TexReady : bool, // Set when texture was built matching current font input
	TexPixelsUseColors : bool, // Tell whether our texture data is known to use colors (rather than just alpha channel), in order to help backend select a format.
	TexPixelsAlpha8 : ^u8, // 1 component per pixel, each component is unsigned 8-bit. Total size = TexWidth * TexHeight
	TexPixelsRGBA32 : ^u32, // 4 component per pixel, each component is unsigned 8-bit. Total size = TexWidth * TexHeight * 4
	TexWidth : i32, // Texture width calculated during Build().
	TexHeight : i32, // Texture height calculated during Build().
	TexUvScale : ImVec2, // = (1.0f/TexWidth, 1.0f/TexHeight)
	TexUvWhitePixel : ImVec2, // Texture coordinates to a white pixel
	Fonts : ImVector(^ImFont), // Hold all the fonts returned by AddFont*. Fonts[0] is the default font upon calling ImGui::NewFrame(), use ImGui::PushFont()/PopFont() to change the current font.
	CustomRects : ImVector(ImFontAtlasCustomRect), // Rectangles for packing custom texture data into the atlas.
	ConfigData : ImVector(ImFontConfig), // Configuration data
	TexUvLines : [IM_DRAWLIST_TEX_LINES_WIDTH_MAX + 1]ImVec4, // UVs for baked anti-aliased lines

	// [Internal] Font builder
	FontBuilderIO : ^ImFontBuilderIO, // Opaque interface to a font builder (default to stb_truetype, can be changed to use FreeType by defining IMGUI_ENABLE_FREETYPE).
	FontBuilderFlags : u32, // Shared flags (for all fonts) for custom font builder. THIS IS BUILD IMPLEMENTATION DEPENDENT. Per-font override is also available in ImFontConfig.

	// [Internal] Packing data
	PackIdMouseCursors : i32, // Custom texture rectangle ID for white pixel and mouse cursors
	PackIdLines : i32, // Custom texture rectangle ID for baked anti-aliased lines

	// [Obsolete]
	//typedef ImFontAtlasCustomRect    CustomRect;         // OBSOLETED in 1.72+
	//typedef ImFontGlyphRangesBuilder GlyphRangesBuilder; // OBSOLETED in 1.67+
}

// Bit ambiguous: used to detect when user didn't build texture but effectively we should check TexID != 0 except that would be backend dependent...
ImFontAtlas_IsBuilt :: proc(this : ^ImFontAtlas) -> bool { return this.Fonts.Size > 0 && this.TexReady }

ImFontAtlas_SetTexID :: proc(this : ^ImFontAtlas, id : ImTextureID) { this.TexID = id }

ImFontAtlas_GetCustomRectByIndex :: proc(this : ^ImFontAtlas, index : i32) -> ^ImFontAtlasCustomRect
{
	IM_ASSERT(index >= 0); return &this.CustomRects[index]
}

// Runtime data for a single font within a parent ImFontAtlas
// Font runtime data and rendering
// ImFontAtlas automatically loads a default embedded font for you when you call GetTexDataAsAlpha8() or GetTexDataAsRGBA32().
ImFont :: struct {
	// [Internal] Members: Hot ~20/24 bytes (for CalcTextSize)
	IndexAdvanceX : ImVector(f32), // 12-16 // out //            // Sparse. Glyphs->AdvanceX in a directly indexable way (cache-friendly for CalcTextSize functions which only this info, and are often bottleneck in large UI).
	FallbackAdvanceX : f32, // 4     // out // = FallbackGlyph->AdvanceX
	FontSize : f32, // 4     // in  //            // Height of characters/line, set during loading (don't change after loading)

	// [Internal] Members: Hot ~28/40 bytes (for RenderText loop)
	IndexLookup : ImVector(ImWchar), // 12-16 // out //            // Sparse. Index glyphs by Unicode code-point.
	Glyphs : ImVector(ImFontGlyph), // 12-16 // out //            // All glyphs.
	FallbackGlyph : ^ImFontGlyph, // 4-8   // out // = FindGlyph(FontFallbackChar)

	// [Internal] Members: Cold ~32/40 bytes
	// Conceptually ConfigData[] is the list of font sources merged to create this font.
	ContainerAtlas : ^ImFontAtlas, // 4-8   // out //            // What we has been loaded into
	ConfigData : ^ImFontConfig, // 4-8   // in  //            // Pointer within ContainerAtlas->ConfigData to ConfigDataCount instances
	ConfigDataCount : i16, // 2     // in  // ~ 1        // Number of ImFontConfig involved in creating this font. Bigger than 1 when merging multiple font sources into one ImFont.
	EllipsisCharCount : i16, // 1     // out // 1 or 3
	EllipsisChar : ImWchar, // 2-4   // out // = '...'/'.'// Character used for ellipsis rendering.
	FallbackChar : ImWchar, // 2-4   // out // = FFFD/'?' // Character used if a glyph isn't found.
	EllipsisWidth : f32, // 4     // out               // Width
	EllipsisCharStep : f32, // 4     // out               // Step between characters when EllipsisCount > 0
	DirtyLookupTables : bool, // 1     // out //
	Scale : f32, // 4     // in  // = 1.f      // Base font scale, multiplied by the per-window font scale which you can adjust with SetWindowFontScale()
	Ascent : f32, Descent : f32, // 4+4   // out //            // Ascent: distance from top to bottom of e.g. 'A' [0..FontSize] (unscaled)
	MetricsTotalSurface : i32, // 4     // out //            // Total surface in pixels to get an idea of the font rasterization/texture cost (not exact, we approximate the cost of padding between glyphs)
	Used4kPagesMap : [(IM_UNICODE_CODEPOINT_MAX + 1) / 4096 / 8]ImU8, // 2 bytes if ImWchar=ImWchar16, 34 bytes if ImWchar==ImWchar32. Store 1-bit for each block of 4K codepoints that has one active glyph. This is mainly used to facilitate iterations across all used codepoints.
}

ImFont_GetCharAdvance :: proc(this : ^ImFont, c : ImWchar) -> f32 { return (cast(i32) c < this.IndexAdvanceX.Size) ? this.IndexAdvanceX[cast(i32) c] : this.FallbackAdvanceX }

ImFont_IsLoaded :: proc(this : ^ImFont) -> bool { return this.ContainerAtlas != nil }

ImFont_GetDebugName :: proc(this : ^ImFont) -> ^u8 { return this.ConfigData != nil ? this.ConfigData.Name : "<unknown>" }

//-----------------------------------------------------------------------------
// [SECTION] Viewports
//-----------------------------------------------------------------------------

// Flags stored in ImGuiViewport::Flags, giving indications to the platform backends.
ImGuiViewportFlags_ :: enum i32 {
	ImGuiViewportFlags_None = 0,
	ImGuiViewportFlags_IsPlatformWindow = 1 << 0, // Represent a Platform Window
	ImGuiViewportFlags_IsPlatformMonitor = 1 << 1, // Represent a Platform Monitor (unused yet)
	ImGuiViewportFlags_OwnedByApp = 1 << 2, // Platform Window: Is created/managed by the user application? (rather than our backend)
	ImGuiViewportFlags_NoDecoration = 1 << 3, // Platform Window: Disable platform decorations: title bar, borders, etc. (generally set all windows, but if ImGuiConfigFlags_ViewportsDecoration is set we only set this on popups/tooltips)
	ImGuiViewportFlags_NoTaskBarIcon = 1 << 4, // Platform Window: Disable platform task bar icon (generally set on popups/tooltips, or all windows if ImGuiConfigFlags_ViewportsNoTaskBarIcon is set)
	ImGuiViewportFlags_NoFocusOnAppearing = 1 << 5, // Platform Window: Don't take focus when created.
	ImGuiViewportFlags_NoFocusOnClick = 1 << 6, // Platform Window: Don't take focus when clicked on.
	ImGuiViewportFlags_NoInputs = 1 << 7, // Platform Window: Make mouse pass through so we can drag this window while peaking behind it.
	ImGuiViewportFlags_NoRendererClear = 1 << 8, // Platform Window: Renderer doesn't need to clear the framebuffer ahead (because we will fill it entirely).
	ImGuiViewportFlags_NoAutoMerge = 1 << 9, // Platform Window: Avoid merging this window into another host window. This can only be set via ImGuiWindowClass viewport flags override (because we need to now ahead if we are going to create a viewport in the first place!).
	ImGuiViewportFlags_TopMost = 1 << 10, // Platform Window: Display on top (for tooltips only).
	ImGuiViewportFlags_CanHostOtherWindows = 1 << 11, // Viewport can host multiple imgui windows (secondary viewports are associated to a single window). // FIXME: In practice there's still probably code making the assumption that this is always and only on the MainViewport. Will fix once we add support for "no main viewport".

	// Output status flags (from Platform)
	ImGuiViewportFlags_IsMinimized = 1 << 12, // Platform Window: Window is minimized, can skip render. When minimized we tend to avoid using the viewport pos/size for clipping window or testing if they are contained in the viewport.
	ImGuiViewportFlags_IsFocused = 1 << 13, // Platform Window: Window is focused (last call to Platform_GetWindowFocus() returned true)
}

// A Platform Window (always 1 unless multi-viewport are enabled. One per platform window to output to). In the future may represent Platform Monitor
// - Currently represents the Platform Window created by the application which is hosting our Dear ImGui windows.
// - With multi-viewport enabled, we extend this concept to have multiple active viewports.
// - In the future we will extend this concept further to also represent Platform Monitor and support a "no main platform window" operation mode.
// - About Main Area vs Work Area:
//   - Main Area = entire viewport.
//   - Work Area = entire viewport minus sections used by main menu bars (for platform windows), or by task bar (for platform monitor).
//   - Windows are generally trying to stay within the Work Area of their host viewport.
ImGuiViewport :: struct {
	ID : ImGuiID, // Unique identifier for the viewport
	Flags : ImGuiViewportFlags, // See ImGuiViewportFlags_
	Pos : ImVec2, // Main Area: Position of the viewport (Dear ImGui coordinates are the same as OS desktop/native coordinates)
	Size : ImVec2, // Main Area: Size of the viewport.
	WorkPos : ImVec2, // Work Area: Position of the viewport minus task bars, menus bars, status bars (>= Pos)
	WorkSize : ImVec2, // Work Area: Size of the viewport minus task bars, menu bars, status bars (<= Size)
	DpiScale : f32, // 1.0f = 96 DPI = No extra scale.
	ParentViewportId : ImGuiID, // (Advanced) 0: no parent. Instruct the platform backend to setup a parent/child relationship between platform windows.
	DrawData : ^ImDrawData, // The ImDrawData corresponding to this viewport. Valid after Render() and until the next call to NewFrame().

	// Platform/Backend Dependent Data
	// Our design separate the Renderer and Platform backends to facilitate combining default backends with each others.
	// When our create your own backend for a custom engine, it is possible that both Renderer and Platform will be handled
	// by the same system and you may not need to use all the UserData/Handle fields.
	// The library never uses those fields, they are merely storage to facilitate backend implementation.
	RendererUserData : rawptr, // void* to hold custom data structure for the renderer (e.g. swap chain, framebuffers etc.). generally set by your Renderer_CreateWindow function.
	PlatformUserData : rawptr, // void* to hold custom data structure for the OS / platform (e.g. windowing info, render context). generally set by your Platform_CreateWindow function.
	PlatformHandle : rawptr, // void* to hold higher-level, platform window handle (e.g. HWND, GLFWWindow*, SDL_Window*), for FindViewportByPlatformHandle().
	PlatformHandleRaw : rawptr, // void* to hold lower-level, platform-native window handle (under Win32 this is expected to be a HWND, unused for other platforms), when using an abstraction layer like GLFW or SDL (where PlatformHandle would be a SDL_Window*)
	PlatformWindowCreated : bool, // Platform window has been created (Platform_CreateWindow() has been called). This is false during the first frame where a viewport is being created.
	PlatformRequestMove : bool, // Platform window requested move (e.g. window was moved by the OS / host window manager, authoritative position will be OS window position)
	PlatformRequestResize : bool, // Platform window requested resize (e.g. window was resized by the OS / host window manager, authoritative size will be OS window size)
	PlatformRequestClose : bool, // Platform window requested closure (e.g. window was moved by the OS / host window manager, e.g. pressing ALT-F4)
}

ImGuiViewport_deinit :: proc(this : ^ImGuiViewport)
{IM_ASSERT(this.PlatformUserData == nil && this.RendererUserData == nil)}

ImGuiViewport_init :: proc(this : ^ImGuiViewport) { memset(this, 0, size_of(this^)) }

// Helpers
ImGuiViewport_GetCenter :: proc(this : ^ImGuiViewport) -> ImVec2 { return ImVec2(this.Pos.x + this.Size.x * 0.5, this.Pos.y + this.Size.y * 0.5) }

ImGuiViewport_GetWorkCenter :: proc(this : ^ImGuiViewport) -> ImVec2 { return ImVec2(this.WorkPos.x + this.WorkSize.x * 0.5, this.WorkPos.y + this.WorkSize.y * 0.5) }

// Interface between platform/renderer backends and ImGui (e.g. Clipboard, IME, Multi-Viewport support). Extends ImGuiIO.
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
ImGuiPlatformIO :: struct {
	//------------------------------------------------------------------
	// Interface with OS and Platform backend (basic)
	//------------------------------------------------------------------

	// Optional: Access OS clipboard
	// (default to use native Win32 clipboard on Windows, otherwise uses a private clipboard. Override to access OS clipboard on other architectures)
	Platform_GetClipboardTextFn : proc(ctx : ^ImGuiContext) -> ^u8,
	Platform_SetClipboardTextFn : proc(ctx : ^ImGuiContext, text : ^u8),
	Platform_ClipboardUserData : rawptr,

	// Optional: Open link/folder/file in OS Shell
	// (default to use ShellExecuteA() on Windows, system() on Linux/Mac)
	Platform_OpenInShellFn : proc(ctx : ^ImGuiContext, path : ^u8) -> bool,
	Platform_OpenInShellUserData : rawptr,

	// Optional: Notify OS Input Method Editor of the screen position of your cursor for text input position (e.g. when using Japanese/Chinese IME on Windows)
	// (default to use native imm32 api on Windows)
	Platform_SetImeDataFn : proc(ctx : ^ImGuiContext, viewport : ^ImGuiViewport, data : ^ImGuiPlatformImeData),
	Platform_ImeUserData : rawptr,
	//void      (*SetPlatformImeDataFn)(ImGuiViewport* viewport, ImGuiPlatformImeData* data); // [Renamed to platform_io.PlatformSetImeDataFn in 1.91.1]

	// Optional: Platform locale
	// [Experimental] Configure decimal point e.g. '.' or ',' useful for some languages (e.g. German), generally pulled from *localeconv()->decimal_point
	Platform_LocaleDecimalPoint : ImWchar, // '.'

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
	Platform_CreateWindow : proc(vp : ^ImGuiViewport), // . . U . .  // Create a new platform window for the given viewport
	Platform_DestroyWindow : proc(vp : ^ImGuiViewport), // N . U . D  //
	Platform_ShowWindow : proc(vp : ^ImGuiViewport), // . . U . .  // Newly created windows are initially hidden so SetWindowPos/Size/Title can be called on them before showing the window
	Platform_SetWindowPos : proc(vp : ^ImGuiViewport, pos : ImVec2), // . . U . .  // Set platform window position (given the upper-left corner of client area)
	Platform_GetWindowPos : proc(vp : ^ImGuiViewport) -> ImVec2, // N . . . .  //
	Platform_SetWindowSize : proc(vp : ^ImGuiViewport, size : ImVec2), // . . U . .  // Set platform window client area size (ignoring OS decorations such as OS title bar etc.)
	Platform_GetWindowSize : proc(vp : ^ImGuiViewport) -> ImVec2, // N . . . .  // Get platform window client area size
	Platform_SetWindowFocus : proc(vp : ^ImGuiViewport), // N . . . .  // Move window to front and set input focus
	Platform_GetWindowFocus : proc(vp : ^ImGuiViewport) -> bool, // . . U . .  //
	Platform_GetWindowMinimized : proc(vp : ^ImGuiViewport) -> bool, // N . . . .  // Get platform window minimized state. When minimized, we generally won't attempt to get/set size and contents will be culled more easily
	Platform_SetWindowTitle : proc(vp : ^ImGuiViewport, str : ^u8), // . . U . .  // Set platform window title (given an UTF-8 string)
	Platform_SetWindowAlpha : proc(vp : ^ImGuiViewport, alpha : f32), // . . U . .  // (Optional) Setup global transparency (not per-pixel transparency)
	Platform_UpdateWindow : proc(vp : ^ImGuiViewport), // . . U . .  // (Optional) Called by UpdatePlatformWindows(). Optional hook to allow the platform backend from doing general book-keeping every frame.
	Platform_RenderWindow : proc(vp : ^ImGuiViewport, render_arg : rawptr), // . . . R .  // (Optional) Main rendering (platform side! This is often unused, or just setting a "current" context for OpenGL bindings). 'render_arg' is the value passed to RenderPlatformWindowsDefault().
	Platform_SwapBuffers : proc(vp : ^ImGuiViewport, render_arg : rawptr), // . . . R .  // (Optional) Call Present/SwapBuffers (platform side! This is often unused!). 'render_arg' is the value passed to RenderPlatformWindowsDefault().
	Platform_GetWindowDpiScale : proc(vp : ^ImGuiViewport) -> f32, // N . . . .  // (Optional) [BETA] FIXME-DPI: DPI handling: Return DPI scale for this viewport. 1.0f = 96 DPI.
	Platform_OnChangedViewport : proc(vp : ^ImGuiViewport), // . F . . .  // (Optional) [BETA] FIXME-DPI: DPI handling: Called during Begin() every time the viewport we are outputting into changes, so backend has a chance to swap fonts to adjust style.
	Platform_GetWindowWorkAreaInsets : proc(vp : ^ImGuiViewport) -> ImVec4, // N . . . .  // (Optional) [BETA] Get initial work area inset for the viewport (won't be covered by main menu bar, dockspace over viewport etc.). Default to (0,0),(0,0). 'safeAreaInsets' in iOS land, 'DisplayCutout' in Android land.
	Platform_CreateVkSurface : proc(vp : ^ImGuiViewport, vk_inst : ImU64, vk_allocators : rawptr, out_vk_surface : ^ImU64) -> i32, // (Optional) For a Vulkan Renderer to call into Platform code (since the surface creation needs to tie them both).

	// Renderer Backend functions (e.g. DirectX, OpenGL, Vulkan) ------------ Called by -----
	Renderer_CreateWindow : proc(vp : ^ImGuiViewport), // . . U . .  // Create swap chain, frame buffers etc. (called after Platform_CreateWindow)
	Renderer_DestroyWindow : proc(vp : ^ImGuiViewport), // N . U . D  // Destroy swap chain, frame buffers etc. (called before Platform_DestroyWindow)
	Renderer_SetWindowSize : proc(vp : ^ImGuiViewport, size : ImVec2), // . . U . .  // Resize swap chain, frame buffers etc. (called after Platform_SetWindowSize)
	Renderer_RenderWindow : proc(vp : ^ImGuiViewport, render_arg : rawptr), // . . . R .  // (Optional) Clear framebuffer, setup render target, then render the viewport->DrawData. 'render_arg' is the value passed to RenderPlatformWindowsDefault().
	Renderer_SwapBuffers : proc(vp : ^ImGuiViewport, render_arg : rawptr), // . . . R .  // (Optional) Call Present/SwapBuffers. 'render_arg' is the value passed to RenderPlatformWindowsDefault().

	// (Optional) Monitor list
	// - Updated by: app/backend. Update every frame to dynamically support changing monitor or DPI configuration.
	// - Used by: dear imgui to query DPI info, clamp popups/tooltips within same monitor and not have them straddle monitors.
	Monitors : ImVector(ImGuiPlatformMonitor),

	//------------------------------------------------------------------
	// Output - List of viewports to render into platform windows
	//------------------------------------------------------------------

	// Viewports list (the list is updated by calling ImGui::EndFrame or ImGui::Render)
	// (in the future we will attempt to organize this feature to remove the need for a "main viewport")
	Viewports : ImVector(^ImGuiViewport), // Main viewports, followed by all secondary viewports.
}

// Multi-viewport support: user-provided bounds for each connected monitor/display. Used when positioning popups and tooltips to avoid them straddling monitors
// (Optional) This is required when enabling multi-viewport. Represent the bounds of each connected monitor/display and their DPI.
// We use this information for multiple DPI support + clamping the position of popups and tooltips so they don't straddle multiple monitors.
ImGuiPlatformMonitor :: struct {
	MainPos : ImVec2, MainSize : ImVec2, // Coordinates of the area displayed on this monitor (Min = upper left, Max = bottom right)
	WorkPos : ImVec2, WorkSize : ImVec2, // Coordinates without task bars / side bars / menu bars. Used to avoid positioning popups/tooltips inside this region. If you don't have this info, please copy the value for MainPos/MainSize.
	DpiScale : f32, // 1.0f = 96 DPI
	PlatformHandle : rawptr, // Backend dependant data (e.g. HMONITOR, GLFWmonitor*, SDL Display Index, NSScreen*)
}

ImGuiPlatformMonitor_init :: proc(this : ^ImGuiPlatformMonitor)
{
	this.WorkSize = ImVec2(0, 0); this.WorkPos = this.WorkSize; this.MainSize = this.WorkPos; this.MainPos = this.MainSize; this.DpiScale = 1.0; this.PlatformHandle = nil
}

// Platform IME data for io.PlatformSetImeDataFn() function.
// (Optional) Support for IME (Input Method Editor) via the platform_io.Platform_SetImeDataFn() function.
ImGuiPlatformImeData :: struct {
	WantVisible : bool, // A widget wants the IME to be visible
	InputPos : ImVec2, // Position of the input cursor
	InputLineHeight : f32, // Line height
}

ImGuiPlatformImeData_init :: proc(this : ^ImGuiPlatformImeData) { memset(this, 0, size_of(this^)) }

//-----------------------------------------------------------------------------
// [SECTION] Obsolete functions and types
// (Will be removed! Read 'API BREAKING CHANGES' section in imgui.cpp for details)
// Please keep your copy of dear imgui up to date! Occasionally set '#define IMGUI_DISABLE_OBSOLETE_FUNCTIONS' in imconfig.h to stay ahead.
//-----------------------------------------------------------------------------

// #ifndef IMGUI_DISABLE_OBSOLETE_FUNCTIONS

// RENAMED IMGUI_DISABLE_METRICS_WINDOW > IMGUI_DISABLE_DEBUG_TOOLS in 1.88 (from June 2022)
when IMGUI_DISABLE_METRICS_WINDOW { /* @gen ifdef */
// warning IMGUI_DISABLE_METRICS_WINDOW was renamed to IMGUI_DISABLE_DEBUG_TOOLS , please use new name .
} // preproc endif

//-----------------------------------------------------------------------------

when defined ( __clang__ ) {
} else when defined ( __GNUC__ ) {
} // preproc endif

when _MSC_VER { /* @gen ifdef */
} // preproc endif

// Include imgui_user.h at the end of imgui.h
// May be convenient for some users to only explicitly include vanilla imgui.h and have extra stuff included.
when IMGUI_INCLUDE_IMGUI_USER_H { /* @gen ifdef */
when IMGUI_USER_H_FILENAME { /* @gen ifdef */
//#include IMGUI_USER_H_FILENAME
} else { // preproc else
//#include "imgui_user.h"
} // preproc endif
} // preproc endif

} // preproc endif// #ifndef IMGUI_DISABLE
when ! IMGUI_DISABLE { /* @gen ifndef */
// dear imgui: Platform Backend for Windows (standard windows API for 32-bits AND 64-bits applications)
// This needs to be used along with a Renderer (e.g. DirectX11, OpenGL3, Vulkan..)

// Implemented features:
//  [X] Platform: Clipboard support (for Win32 this is actually part of core dear imgui)
//  [X] Platform: Mouse support. Can discriminate Mouse/TouchScreen/Pen.
//  [X] Platform: Keyboard support. Since 1.87 we are using the io.AddKeyEvent() function. Pass ImGuiKey values to all key functions e.g. ImGui::IsKeyPressed(ImGuiKey_Space). [Legacy VK_* values are obsolete since 1.87 and not supported since 1.91.5]
//  [X] Platform: Gamepad support. Enabled with 'io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad'.
//  [X] Platform: Mouse cursor shape and visibility (ImGuiBackendFlags_HasMouseCursors). Disable with 'io.ConfigFlags |= ImGuiConfigFlags_NoMouseCursorChange'.
//  [X] Platform: Multi-viewport support (multiple windows). Enable with 'io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable'.

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// Learn about Dear ImGui:
// - FAQ                  https://dearimgui.com/faq
// - Getting Started      https://dearimgui.com/getting-started
// - Documentation        https://dearimgui.com/docs (same as your local docs/ folder).
// - Introduction, links and more at the top of imgui.cpp

when ! IMGUI_DISABLE { /* @gen ifndef */

} // preproc endif// #ifndef IMGUI_DISABLE
when ! WIN32_LEAN_AND_MEAN { /* @gen ifndef */
WIN32_LEAN_AND_MEAN :: true
} // preproc endif

// Using XInput for gamepad (will load DLL dynamically)
when ! IMGUI_IMPL_WIN32_DISABLE_GAMEPAD { /* @gen ifndef */
PFN_XInputGetCapabilities :: proc(_ : DWORD, _ : DWORD, _ : ^XINPUT_CAPABILITIES) -> DWORD
PFN_XInputGetState :: proc(_ : DWORD, _ : ^XINPUT_STATE) -> DWORD
} // preproc endif

// Clang/GCC warnings with -Weverything
when defined ( __clang__ ) {
} // preproc endif
when defined ( __GNUC__ ) {
} // preproc endif

ImGui_ImplWin32_Data :: struct {
	hWnd : HWND,
	MouseHwnd : HWND,
	MouseTrackedArea : i32, // 0: not tracked, 1: client area, 2: non-client area
	MouseButtonsDown : i32,
	Time : INT64,
	TicksPerSecond : INT64,
	LastMouseCursor : ImGuiMouseCursor,
	KeyboardCodePage : UINT32,
	WantUpdateMonitors : bool,

when ! IMGUI_IMPL_WIN32_DISABLE_GAMEPAD { /* @gen ifndef */
	HasGamepad : bool,
	WantUpdateHasGamepad : bool,
	XInputDLL : HMODULE,
	XInputGetCapabilities : PFN_XInputGetCapabilities,
	XInputGetState : PFN_XInputGetState,
} // preproc endif
}

ImGui_ImplWin32_Data_init :: proc(this : ^ImGui_ImplWin32_Data) { memset(cast(rawptr) this, 0, size_of(this^)) }

// Backend data stored in io.BackendPlatformUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
// FIXME: multi-context support is not well tested and probably dysfunctional in this backend.
// FIXME: some shared resources (mouse cursor shape, gamepad) are mishandled when using multi-context.
ImGui_ImplWin32_GetBackendData_0 :: proc() -> ^ImGui_ImplWin32_Data
{
	return GetCurrentContext() != nil ? cast(^ImGui_ImplWin32_Data) GetIO().BackendPlatformUserData : nil
}
ImGui_ImplWin32_GetBackendData_1 :: proc(io : ^ImGuiIO) -> ^ImGui_ImplWin32_Data
{
	return cast(^ImGui_ImplWin32_Data) io.BackendPlatformUserData
}

// Functions
ImGui_ImplWin32_UpdateKeyboardCodePage :: proc(io : ^ImGuiIO)
{
	// Retrieve keyboard code page, required for handling of non-Unicode Windows.
	bd : ^ImGui_ImplWin32_Data = ImGui_ImplWin32_GetBackendData(io)
	keyboard_layout : HKL = GetKeyboardLayout(0)
	keyboard_lcid : LCID = MAKELCID(HIWORD(keyboard_layout), SORT_DEFAULT)
	if GetLocaleInfoA(keyboard_lcid, (LOCALE_RETURN_NUMBER | LOCALE_IDEFAULTANSICODEPAGE), cast(LPSTR) &bd.KeyboardCodePage, size_of(bd.KeyboardCodePage)) == 0 {
		// Fallback to default ANSI code page when fails.
		bd.KeyboardCodePage = CP_ACP
	}
}

ImGui_ImplWin32_InitEx :: proc(hwnd : rawptr, platform_has_own_dc : bool) -> bool
{
	io : ^ImGuiIO = GetIO()
	IMGUI_CHECKVERSION()
	IM_ASSERT(io.BackendPlatformUserData == nil && "Already initialized a platform backend!")

	perf_frequency : INT64; perf_counter : INT64
	if QueryPerformanceFrequency(cast(^LARGE_INTEGER) &perf_frequency) == {} { return false }
	if QueryPerformanceCounter(cast(^LARGE_INTEGER) &perf_counter) == {} { return false }

	// Setup backend capabilities flags
	bd : ^ImGui_ImplWin32_Data = IM_NEW(ImGui_ImplWin32_Data)()
	io.BackendPlatformUserData = cast(rawptr) bd
	io.BackendPlatformName = "imgui_impl_win32"
	io.BackendFlags |= ImGuiBackendFlags_.ImGuiBackendFlags_HasMouseCursors; // We can honor GetMouseCursor() values (optional)
	io.BackendFlags |= ImGuiBackendFlags_.ImGuiBackendFlags_HasSetMousePos; // We can honor io.WantSetMousePos requests (optional, rarely used)
	io.BackendFlags |= ImGuiBackendFlags_.ImGuiBackendFlags_PlatformHasViewports; // We can create multi-viewports on the Platform side (optional)
	io.BackendFlags |= ImGuiBackendFlags_.ImGuiBackendFlags_HasMouseHoveredViewport; // We can call io.AddMouseViewportEvent() with correct data (optional)

	bd.hWnd = cast(HWND) hwnd
	bd.TicksPerSecond = perf_frequency
	bd.Time = perf_counter
	bd.LastMouseCursor = ImGuiMouseCursor_.ImGuiMouseCursor_COUNT
	ImGui_ImplWin32_UpdateKeyboardCodePage(io)

	// Update monitor a first time during init
	ImGui_ImplWin32_UpdateMonitors()

	// Our mouse update function expect PlatformHandle to be filled for the main viewport
	main_viewport : ^ImGuiViewport = GetMainViewport()
	main_viewport.PlatformHandleRaw = cast(rawptr) bd.hWnd; main_viewport.PlatformHandle = main_viewport.PlatformHandleRaw

	// Be aware that GetPropA()/SetPropA() may be accessed from other processes.
	// So as we store a pointer in IMGUI_CONTEXT we need to make sure we only call GetPropA() on windows owned by our process.
	SetPropA(bd.hWnd, "IMGUI_CONTEXT", GetCurrentContext())
	ImGui_ImplWin32_InitMultiViewportSupport(platform_has_own_dc)

	// Dynamically load XInput library
	when ! IMGUI_IMPL_WIN32_DISABLE_GAMEPAD { /* @gen ifndef */
	bd.WantUpdateHasGamepad = true
	xinput_dll_names : [^]^u8 = {
		"xinput1_4.dll", // Windows 8+
		"xinput1_3.dll", // DirectX SDK
		"xinput9_1_0.dll", // Windows Vista, Windows 7
		"xinput1_2.dll", // DirectX SDK
		"xinput1_1.dll", // DirectX SDK
	}
	for n : i32 = 0; n < IM_ARRAYSIZE(xinput_dll_names); post_incr(&n) { if dll : HMODULE = LoadLibraryA(xinput_dll_names[n]); dll {
	bd.XInputDLL = dll
	bd.XInputGetCapabilities = cast(PFN_XInputGetCapabilities) GetProcAddress(dll, "XInputGetCapabilities")
	bd.XInputGetState = cast(PFN_XInputGetState) GetProcAddress(dll, "XInputGetState")
	break
} }

	} // preproc endif// IMGUI_IMPL_WIN32_DISABLE_GAMEPAD

	return true
}

// Follow "Getting Started" link and check examples/ folder to learn about using backends!
ImGui_ImplWin32_Init :: proc(hwnd : rawptr) -> bool
{
	return ImGui_ImplWin32_InitEx(hwnd, false)
}

ImGui_ImplWin32_InitForOpenGL :: proc(hwnd : rawptr) -> bool
{
	// OpenGL needs CS_OWNDC
	return ImGui_ImplWin32_InitEx(hwnd, true)
}

ImGui_ImplWin32_Shutdown :: proc()
{
	bd : ^ImGui_ImplWin32_Data = ImGui_ImplWin32_GetBackendData()
	IM_ASSERT(bd != nil && "No platform backend to shutdown, or already shutdown?")
	io : ^ImGuiIO = GetIO()

	SetPropA(bd.hWnd, "IMGUI_CONTEXT", nil)
	ImGui_ImplWin32_ShutdownMultiViewportSupport()

	// Unload XInput library
	when ! IMGUI_IMPL_WIN32_DISABLE_GAMEPAD { /* @gen ifndef */
	if bd.XInputDLL != {} { FreeLibrary(bd.XInputDLL) }
	} // preproc endif// IMGUI_IMPL_WIN32_DISABLE_GAMEPAD

	io.BackendPlatformName = nil
	io.BackendPlatformUserData = nil
	io.BackendFlags &= ~(ImGuiBackendFlags_.ImGuiBackendFlags_HasMouseCursors | ImGuiBackendFlags_.ImGuiBackendFlags_HasSetMousePos | ImGuiBackendFlags_.ImGuiBackendFlags_HasGamepad | ImGuiBackendFlags_.ImGuiBackendFlags_PlatformHasViewports | ImGuiBackendFlags_.ImGuiBackendFlags_HasMouseHoveredViewport)
	IM_DELETE(bd)
}

ImGui_ImplWin32_UpdateMouseCursor :: proc(io : ^ImGuiIO, imgui_cursor : ImGuiMouseCursor) -> bool
{
	if (io.ConfigFlags & ImGuiConfigFlags_.ImGuiConfigFlags_NoMouseCursorChange) != {} { return false }

	if imgui_cursor == ImGuiMouseCursor_.ImGuiMouseCursor_None || io.MouseDrawCursor {
		// Hide OS mouse cursor if imgui is drawing it or if it wants no cursor
		SetCursor(nil)
	}
	else {
		// Show OS mouse cursor
		win32_cursor : LPTSTR = IDC_ARROW
		switch imgui_cursor {
			case ImGuiMouseCursor_.ImGuiMouseCursor_Arrow:win32_cursor = IDC_ARROW; break

			case ImGuiMouseCursor_.ImGuiMouseCursor_TextInput:win32_cursor = IDC_IBEAM; break

			case ImGuiMouseCursor_.ImGuiMouseCursor_ResizeAll:win32_cursor = IDC_SIZEALL; break

			case ImGuiMouseCursor_.ImGuiMouseCursor_ResizeEW:win32_cursor = IDC_SIZEWE; break

			case ImGuiMouseCursor_.ImGuiMouseCursor_ResizeNS:win32_cursor = IDC_SIZENS; break

			case ImGuiMouseCursor_.ImGuiMouseCursor_ResizeNESW:win32_cursor = IDC_SIZENESW; break

			case ImGuiMouseCursor_.ImGuiMouseCursor_ResizeNWSE:win32_cursor = IDC_SIZENWSE; break

			case ImGuiMouseCursor_.ImGuiMouseCursor_Hand:win32_cursor = IDC_HAND; break

			case ImGuiMouseCursor_.ImGuiMouseCursor_NotAllowed:win32_cursor = IDC_NO; break
		}
		SetCursor(LoadCursor(nil, win32_cursor))
	}
	return true
}

IsVkDown :: proc(vk : i32) -> bool
{
	return (GetKeyState(vk) & 0x8000) != {}
}

ImGui_ImplWin32_AddKeyEvent :: proc(io : ^ImGuiIO, key : ImGuiKey, down : bool, native_keycode : i32, native_scancode : i32 = -1)
{
	AddKeyEvent(&io, key, down)
	SetKeyEventNativeData(&io, key, native_keycode, native_scancode); // To support legacy indexing (<1.87 user code)
	IM_UNUSED(native_scancode)
}

ImGui_ImplWin32_ProcessKeyEventsWorkarounds :: proc(io : ^ImGuiIO)
{
	// Left & right Shift keys: when both are pressed together, Windows tend to not generate the WM_KEYUP event for the first released one.
	if IsKeyDown(ImGuiKey.ImGuiKey_LeftShift) && !IsVkDown(VK_LSHIFT) { ImGui_ImplWin32_AddKeyEvent(io, ImGuiKey.ImGuiKey_LeftShift, false, VK_LSHIFT) }
	if IsKeyDown(ImGuiKey.ImGuiKey_RightShift) && !IsVkDown(VK_RSHIFT) { ImGui_ImplWin32_AddKeyEvent(io, ImGuiKey.ImGuiKey_RightShift, false, VK_RSHIFT) }

	// Sometimes WM_KEYUP for Win key is not passed down to the app (e.g. for Win+V on some setups, according to GLFW).
	if IsKeyDown(ImGuiKey.ImGuiKey_LeftSuper) && !IsVkDown(VK_LWIN) { ImGui_ImplWin32_AddKeyEvent(io, ImGuiKey.ImGuiKey_LeftSuper, false, VK_LWIN) }
	if IsKeyDown(ImGuiKey.ImGuiKey_RightSuper) && !IsVkDown(VK_RWIN) { ImGui_ImplWin32_AddKeyEvent(io, ImGuiKey.ImGuiKey_RightSuper, false, VK_RWIN) }
}

ImGui_ImplWin32_UpdateKeyModifiers :: proc(io : ^ImGuiIO)
{
	AddKeyEvent(&io, ImGuiKey.ImGuiMod_Ctrl, IsVkDown(VK_CONTROL))
	AddKeyEvent(&io, ImGuiKey.ImGuiMod_Shift, IsVkDown(VK_SHIFT))
	AddKeyEvent(&io, ImGuiKey.ImGuiMod_Alt, IsVkDown(VK_MENU))
	AddKeyEvent(&io, ImGuiKey.ImGuiMod_Super, IsVkDown(VK_LWIN) || IsVkDown(VK_RWIN))
}

ImGui_ImplWin32_FindViewportByPlatformHandle :: proc(platform_io : ^ImGuiPlatformIO, hwnd : HWND) -> ^ImGuiViewport
{
	// We cannot use ImGui::FindViewportByPlatformHandle() because it doesn't take a context.
	// When called from ImGui_ImplWin32_WndProcHandler_PlatformWindow() we don't assume that context is bound.
	//return ImGui::FindViewportByPlatformHandle((void*)hwnd);
	for viewport in platform_io.Viewports { if viewport.PlatformHandle == hwnd { return viewport } }

	return nil
}

// This code supports multi-viewports (multiple OS Windows mapped into different Dear ImGui viewports)
// Because of that, it is a little more complicated than your typical single-viewport binding code!
ImGui_ImplWin32_UpdateMouseData :: proc(io : ^ImGuiIO, platform_io : ^ImGuiPlatformIO)
{
	bd : ^ImGui_ImplWin32_Data = ImGui_ImplWin32_GetBackendData(io)
	IM_ASSERT(bd.hWnd != {})

	mouse_screen_pos : POINT
	has_mouse_screen_pos : bool = GetCursorPos(&mouse_screen_pos) != {}

	focused_window : HWND = GetForegroundWindow()
	is_app_focused : bool = (focused_window != {} && (focused_window == bd.hWnd || IsChild(focused_window, bd.hWnd) != {} || ImGui_ImplWin32_FindViewportByPlatformHandle(platform_io, focused_window) != nil))
	if is_app_focused {
		// (Optional) Set OS mouse position from Dear ImGui if requested (rarely used, only when io.ConfigNavMoveSetMousePos is enabled by user)
		// When multi-viewports are enabled, all Dear ImGui positions are same as OS positions.
		if io.WantSetMousePos {
			pos : POINT = {cast(i32) io.MousePos.x, cast(i32) io.MousePos.y}
			if (io.ConfigFlags & ImGuiConfigFlags_.ImGuiConfigFlags_ViewportsEnable) == {} { ClientToScreen(focused_window, &pos) }
			SetCursorPos(pos.x, pos.y)
		}

		// (Optional) Fallback to provide mouse position when focused (WM_MOUSEMOVE already provides this when hovered or captured)
		// This also fills a short gap when clicking non-client area: WM_NCMOUSELEAVE -> modal OS move -> gap -> WM_NCMOUSEMOVE
		if !io.WantSetMousePos && bd.MouseTrackedArea == 0 && has_mouse_screen_pos {
			// Single viewport mode: mouse position in client window coordinates (io.MousePos is (0,0) when the mouse is on the upper-left corner of the app window)
			// (This is the position you can get with ::GetCursorPos() + ::ScreenToClient() or WM_MOUSEMOVE.)
			// Multi-viewport mode: mouse position in OS absolute coordinates (io.MousePos is (0,0) when the mouse is on the upper-left of the primary monitor)
			// (This is the position you can get with ::GetCursorPos() or WM_MOUSEMOVE + ::ClientToScreen(). In theory adding viewport->Pos to a client position would also be the same.)
			mouse_pos : POINT = mouse_screen_pos
			if (io.ConfigFlags & ImGuiConfigFlags_.ImGuiConfigFlags_ViewportsEnable) == {} { ScreenToClient(bd.hWnd, &mouse_pos) }
			AddMousePosEvent(&io, cast(f32) mouse_pos.x, cast(f32) mouse_pos.y)
		}
	}

	// (Optional) When using multiple viewports: call io.AddMouseViewportEvent() with the viewport the OS mouse cursor is hovering.
	// If ImGuiBackendFlags_HasMouseHoveredViewport is not set by the backend, Dear imGui will ignore this field and infer the information using its flawed heuristic.
	// - [X] Win32 backend correctly ignore viewports with the _NoInputs flag (here using ::WindowFromPoint with WM_NCHITTEST + HTTRANSPARENT in WndProc does that)
	//       Some backend are not able to handle that correctly. If a backend report an hovered viewport that has the _NoInputs flag (e.g. when dragging a window
	//       for docking, the viewport has the _NoInputs flag in order to allow us to find the viewport under), then Dear ImGui is forced to ignore the value reported
	//       by the backend, and use its flawed heuristic to guess the viewport behind.
	// - [X] Win32 backend correctly reports this regardless of another viewport behind focused and dragged from (we need this to find a useful drag and drop target).
	mouse_viewport_id : ImGuiID = 0
	if has_mouse_screen_pos { if hovered_hwnd : HWND = WindowFromPoint(mouse_screen_pos); hovered_hwnd { if viewport : ^ImGuiViewport = ImGui_ImplWin32_FindViewportByPlatformHandle(platform_io, hovered_hwnd); viewport { mouse_viewport_id = viewport.ID } } }
	AddMouseViewportEvent(&io, mouse_viewport_id)
}

// Gamepad navigation mapping
ImGui_ImplWin32_UpdateGamepads :: proc(io : ^ImGuiIO)
{
	when ! IMGUI_IMPL_WIN32_DISABLE_GAMEPAD { /* @gen ifndef */
	bd : ^ImGui_ImplWin32_Data = ImGui_ImplWin32_GetBackendData(io)
	//if ((io.ConfigFlags & ImGuiConfigFlags_NavEnableGamepad) == 0) // FIXME: Technically feeding gamepad shouldn't depend on this now that they are regular inputs.
	//    return;

	// Calling XInputGetState() every frame on disconnected gamepads is unfortunately too slow.
	// Instead we refresh gamepad availability by calling XInputGetCapabilities() _only_ after receiving WM_DEVICECHANGE.
	if bd.WantUpdateHasGamepad {
		caps : XINPUT_CAPABILITIES = {}
		bd.HasGamepad = bd.XInputGetCapabilities != {} ? (XInputGetCapabilities(bd, 0, XINPUT_FLAG_GAMEPAD, &caps) == ERROR_SUCCESS) : false
		bd.WantUpdateHasGamepad = false
	}

	io.BackendFlags &= ~ImGuiBackendFlags_.ImGuiBackendFlags_HasGamepad
	xinput_state : XINPUT_STATE
	gamepad : ^XINPUT_GAMEPAD = xinput_state.Gamepad
	if !bd.HasGamepad || bd.XInputGetState == nil || XInputGetState(bd, 0, &xinput_state) != ERROR_SUCCESS { return }
	io.BackendFlags |= ImGuiBackendFlags_.ImGuiBackendFlags_HasGamepad

	IM_SATURATE :: #force_inline proc "contextless" (V : $T0) //TODO @gen: Validate the parameters were not passed by reference.
	{
		(V<0.0?0.0:V>1.0?1.0:V)
	}

	MAP_BUTTON :: #force_inline proc "contextless" (KEY_NO : $T0, BUTTON_ENUM : $T1) //TODO @gen: Validate the parameters were not passed by reference.
	{
		{io.AddKeyEvent(KEY_NO,(gamepad.wButtons&BUTTON_ENUM)!=0);
		}
	}

	MAP_ANALOG :: #force_inline proc "contextless" (KEY_NO : $T0, VALUE : $T1, V0 : $T2, V1 : $T3) //TODO @gen: Validate the parameters were not passed by reference.
	{
		{floatvn=(float)(VALUE-V0)/(float)(V1-V0);
		io.AddKeyAnalogEvent(KEY_NO,vn>0.10,IM_SATURATE(vn));
		}
	}

	MAP_BUTTON(ImGuiKey.ImGuiKey_GamepadStart, XINPUT_GAMEPAD_START)
	MAP_BUTTON(ImGuiKey.ImGuiKey_GamepadBack, XINPUT_GAMEPAD_BACK)
	MAP_BUTTON(ImGuiKey.ImGuiKey_GamepadFaceLeft, XINPUT_GAMEPAD_X)
	MAP_BUTTON(ImGuiKey.ImGuiKey_GamepadFaceRight, XINPUT_GAMEPAD_B)
	MAP_BUTTON(ImGuiKey.ImGuiKey_GamepadFaceUp, XINPUT_GAMEPAD_Y)
	MAP_BUTTON(ImGuiKey.ImGuiKey_GamepadFaceDown, XINPUT_GAMEPAD_A)
	MAP_BUTTON(ImGuiKey.ImGuiKey_GamepadDpadLeft, XINPUT_GAMEPAD_DPAD_LEFT)
	MAP_BUTTON(ImGuiKey.ImGuiKey_GamepadDpadRight, XINPUT_GAMEPAD_DPAD_RIGHT)
	MAP_BUTTON(ImGuiKey.ImGuiKey_GamepadDpadUp, XINPUT_GAMEPAD_DPAD_UP)
	MAP_BUTTON(ImGuiKey.ImGuiKey_GamepadDpadDown, XINPUT_GAMEPAD_DPAD_DOWN)
	MAP_BUTTON(ImGuiKey.ImGuiKey_GamepadL1, XINPUT_GAMEPAD_LEFT_SHOULDER)
	MAP_BUTTON(ImGuiKey.ImGuiKey_GamepadR1, XINPUT_GAMEPAD_RIGHT_SHOULDER)
	MAP_ANALOG(ImGuiKey.ImGuiKey_GamepadL2, gamepad.bLeftTrigger, XINPUT_GAMEPAD_TRIGGER_THRESHOLD, 255)
	MAP_ANALOG(ImGuiKey.ImGuiKey_GamepadR2, gamepad.bRightTrigger, XINPUT_GAMEPAD_TRIGGER_THRESHOLD, 255)
	MAP_BUTTON(ImGuiKey.ImGuiKey_GamepadL3, XINPUT_GAMEPAD_LEFT_THUMB)
	MAP_BUTTON(ImGuiKey.ImGuiKey_GamepadR3, XINPUT_GAMEPAD_RIGHT_THUMB)
	MAP_ANALOG(ImGuiKey.ImGuiKey_GamepadLStickLeft, gamepad.sThumbLX, -XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, -32768)
	MAP_ANALOG(ImGuiKey.ImGuiKey_GamepadLStickRight, gamepad.sThumbLX, +XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, +32767)
	MAP_ANALOG(ImGuiKey.ImGuiKey_GamepadLStickUp, gamepad.sThumbLY, +XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, +32767)
	MAP_ANALOG(ImGuiKey.ImGuiKey_GamepadLStickDown, gamepad.sThumbLY, -XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, -32768)
	MAP_ANALOG(ImGuiKey.ImGuiKey_GamepadRStickLeft, gamepad.sThumbRX, -XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, -32768)
	MAP_ANALOG(ImGuiKey.ImGuiKey_GamepadRStickRight, gamepad.sThumbRX, +XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, +32767)
	MAP_ANALOG(ImGuiKey.ImGuiKey_GamepadRStickUp, gamepad.sThumbRY, +XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, +32767)
	MAP_ANALOG(ImGuiKey.ImGuiKey_GamepadRStickDown, gamepad.sThumbRY, -XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, -32768)
	//TODO @gen: there was a '#undef %!(MISSING ARGUMENT)' here, that cannot be emulated in odin. Make sure everything works as expected.
	//TODO @gen: there was a '#undef %!(MISSING ARGUMENT)' here, that cannot be emulated in odin. Make sure everything works as expected.
	} else when  { // #ifndef IMGUI_IMPL_WIN32_DISABLE_GAMEPAD
	IM_UNUSED(io)
	} // preproc endif
}

ImGui_ImplWin32_UpdateMonitors_EnumFunc :: proc(monitor : HMONITOR, _ : HDC, _ : LPRECT, _ : LPARAM) -> BOOL
{
	info : MONITORINFO = {}
	info.cbSize = size_of(MONITORINFO)
	if GetMonitorInfo(monitor, &info) == {} { return TRUE }
	imgui_monitor : ImGuiPlatformMonitor
	imgui_monitor.MainPos = ImVec2(cast(f32) info.rcMonitor.left, cast(f32) info.rcMonitor.top)
	imgui_monitor.MainSize = ImVec2(cast(f32) (info.rcMonitor.right - info.rcMonitor.left), cast(f32) (info.rcMonitor.bottom - info.rcMonitor.top))
	imgui_monitor.WorkPos = ImVec2(cast(f32) info.rcWork.left, cast(f32) info.rcWork.top)
	imgui_monitor.WorkSize = ImVec2(cast(f32) (info.rcWork.right - info.rcWork.left), cast(f32) (info.rcWork.bottom - info.rcWork.top))
	imgui_monitor.DpiScale = ImGui_ImplWin32_GetDpiScaleForMonitor(monitor)
	imgui_monitor.PlatformHandle = cast(rawptr) monitor
	if imgui_monitor.DpiScale <= 0.0 {
		// Some accessibility applications are declaring virtual monitors with a DPI of 0, see #7902.
		return TRUE
	}
	io : ^ImGuiPlatformIO = GetPlatformIO()
	if (info.dwFlags & MONITORINFOF_PRIMARY) != {} { push_front(&io.Monitors, imgui_monitor) }
	else { push_back(&io.Monitors, imgui_monitor) }
	return TRUE
}

ImGui_ImplWin32_UpdateMonitors :: proc()
{
	bd : ^ImGui_ImplWin32_Data = ImGui_ImplWin32_GetBackendData()
	resize(&GetPlatformIO().Monitors, 0)
	EnumDisplayMonitors(nil, nil, ImGui_ImplWin32_UpdateMonitors_EnumFunc, 0)
	bd.WantUpdateMonitors = false
}

ImGui_ImplWin32_NewFrame :: proc()
{
	bd : ^ImGui_ImplWin32_Data = ImGui_ImplWin32_GetBackendData()
	IM_ASSERT(bd != nil && "Context or backend not initialized? Did you call ImGui_ImplWin32_Init()?")
	io : ^ImGuiIO = GetIO()
	platform_io : ^ImGuiPlatformIO = GetPlatformIO()

	// Setup display size (every frame to accommodate for window resizing)
	rect : RECT = {0, 0, 0, 0}
	GetClientRect(bd.hWnd, &rect)
	io.DisplaySize = ImVec2(cast(f32) (rect.right - rect.left), cast(f32) (rect.bottom - rect.top))
	if bd.WantUpdateMonitors { ImGui_ImplWin32_UpdateMonitors() }

	// Setup time step
	current_time : INT64 = 0
	QueryPerformanceCounter(cast(^LARGE_INTEGER) &current_time)
	io.DeltaTime = cast(f32) (current_time - bd.Time) / bd.TicksPerSecond
	bd.Time = current_time

	// Update OS mouse position
	ImGui_ImplWin32_UpdateMouseData(io, platform_io)

	// Process workarounds for known Windows key handling issues
	ImGui_ImplWin32_ProcessKeyEventsWorkarounds(io)

	// Update OS mouse cursor with the cursor requested by imgui
	mouse_cursor : ImGuiMouseCursor = io.MouseDrawCursor ? ImGuiMouseCursor_.ImGuiMouseCursor_None : GetMouseCursor()
	if bd.LastMouseCursor != mouse_cursor {
		bd.LastMouseCursor = mouse_cursor
		ImGui_ImplWin32_UpdateMouseCursor(io, mouse_cursor)
	}

	// Update game controllers (if enabled and available)
	ImGui_ImplWin32_UpdateGamepads(io)
}

// Map VK_xxx to ImGuiKey_xxx.
// Not static to allow third-party code to use that if they want to (but undocumented)
ImGui_ImplWin32_KeyEventToImGuiKey :: proc(wParam : WPARAM, lParam : LPARAM) -> ImGuiKey
{
	// There is no distinct VK_xxx for keypad enter, instead it is VK_RETURN + KF_EXTENDED.
	if (wParam == VK_RETURN) && (HIWORD(lParam) & KF_EXTENDED) { return ImGuiKey.ImGuiKey_KeypadEnter }

	switch wParam {
		case VK_TAB:return ImGuiKey.ImGuiKey_Tab
			fallthrough
		case VK_LEFT:return ImGuiKey.ImGuiKey_LeftArrow
			fallthrough
		case VK_RIGHT:return ImGuiKey.ImGuiKey_RightArrow
			fallthrough
		case VK_UP:return ImGuiKey.ImGuiKey_UpArrow
			fallthrough
		case VK_DOWN:return ImGuiKey.ImGuiKey_DownArrow
			fallthrough
		case VK_PRIOR:return ImGuiKey.ImGuiKey_PageUp
			fallthrough
		case VK_NEXT:return ImGuiKey.ImGuiKey_PageDown
			fallthrough
		case VK_HOME:return ImGuiKey.ImGuiKey_Home
			fallthrough
		case VK_END:return ImGuiKey.ImGuiKey_End
			fallthrough
		case VK_INSERT:return ImGuiKey.ImGuiKey_Insert
			fallthrough
		case VK_DELETE:return ImGuiKey.ImGuiKey_Delete
			fallthrough
		case VK_BACK:return ImGuiKey.ImGuiKey_Backspace
			fallthrough
		case VK_SPACE:return ImGuiKey.ImGuiKey_Space
			fallthrough
		case VK_RETURN:return ImGuiKey.ImGuiKey_Enter
			fallthrough
		case VK_ESCAPE:return ImGuiKey.ImGuiKey_Escape
			fallthrough
		case VK_OEM_7:return ImGuiKey.ImGuiKey_Apostrophe
			fallthrough
		case VK_OEM_COMMA:return ImGuiKey.ImGuiKey_Comma
			fallthrough
		case VK_OEM_MINUS:return ImGuiKey.ImGuiKey_Minus
			fallthrough
		case VK_OEM_PERIOD:return ImGuiKey.ImGuiKey_Period
			fallthrough
		case VK_OEM_2:return ImGuiKey.ImGuiKey_Slash
			fallthrough
		case VK_OEM_1:return ImGuiKey.ImGuiKey_Semicolon
			fallthrough
		case VK_OEM_PLUS:return ImGuiKey.ImGuiKey_Equal
			fallthrough
		case VK_OEM_4:return ImGuiKey.ImGuiKey_LeftBracket
			fallthrough
		case VK_OEM_5:return ImGuiKey.ImGuiKey_Backslash
			fallthrough
		case VK_OEM_6:return ImGuiKey.ImGuiKey_RightBracket
			fallthrough
		case VK_OEM_3:return ImGuiKey.ImGuiKey_GraveAccent
			fallthrough
		case VK_CAPITAL:return ImGuiKey.ImGuiKey_CapsLock
			fallthrough
		case VK_SCROLL:return ImGuiKey.ImGuiKey_ScrollLock
			fallthrough
		case VK_NUMLOCK:return ImGuiKey.ImGuiKey_NumLock
			fallthrough
		case VK_SNAPSHOT:return ImGuiKey.ImGuiKey_PrintScreen
			fallthrough
		case VK_PAUSE:return ImGuiKey.ImGuiKey_Pause
			fallthrough
		case VK_NUMPAD0:return ImGuiKey.ImGuiKey_Keypad0
			fallthrough
		case VK_NUMPAD1:return ImGuiKey.ImGuiKey_Keypad1
			fallthrough
		case VK_NUMPAD2:return ImGuiKey.ImGuiKey_Keypad2
			fallthrough
		case VK_NUMPAD3:return ImGuiKey.ImGuiKey_Keypad3
			fallthrough
		case VK_NUMPAD4:return ImGuiKey.ImGuiKey_Keypad4
			fallthrough
		case VK_NUMPAD5:return ImGuiKey.ImGuiKey_Keypad5
			fallthrough
		case VK_NUMPAD6:return ImGuiKey.ImGuiKey_Keypad6
			fallthrough
		case VK_NUMPAD7:return ImGuiKey.ImGuiKey_Keypad7
			fallthrough
		case VK_NUMPAD8:return ImGuiKey.ImGuiKey_Keypad8
			fallthrough
		case VK_NUMPAD9:return ImGuiKey.ImGuiKey_Keypad9
			fallthrough
		case VK_DECIMAL:return ImGuiKey.ImGuiKey_KeypadDecimal
			fallthrough
		case VK_DIVIDE:return ImGuiKey.ImGuiKey_KeypadDivide
			fallthrough
		case VK_MULTIPLY:return ImGuiKey.ImGuiKey_KeypadMultiply
			fallthrough
		case VK_SUBTRACT:return ImGuiKey.ImGuiKey_KeypadSubtract
			fallthrough
		case VK_ADD:return ImGuiKey.ImGuiKey_KeypadAdd
			fallthrough
		case VK_LSHIFT:return ImGuiKey.ImGuiKey_LeftShift
			fallthrough
		case VK_LCONTROL:return ImGuiKey.ImGuiKey_LeftCtrl
			fallthrough
		case VK_LMENU:return ImGuiKey.ImGuiKey_LeftAlt
			fallthrough
		case VK_LWIN:return ImGuiKey.ImGuiKey_LeftSuper
			fallthrough
		case VK_RSHIFT:return ImGuiKey.ImGuiKey_RightShift
			fallthrough
		case VK_RCONTROL:return ImGuiKey.ImGuiKey_RightCtrl
			fallthrough
		case VK_RMENU:return ImGuiKey.ImGuiKey_RightAlt
			fallthrough
		case VK_RWIN:return ImGuiKey.ImGuiKey_RightSuper
			fallthrough
		case VK_APPS:return ImGuiKey.ImGuiKey_Menu
			fallthrough
		case '0':return ImGuiKey.ImGuiKey_0
			fallthrough
		case '1':return ImGuiKey.ImGuiKey_1
			fallthrough
		case '2':return ImGuiKey.ImGuiKey_2
			fallthrough
		case '3':return ImGuiKey.ImGuiKey_3
			fallthrough
		case '4':return ImGuiKey.ImGuiKey_4
			fallthrough
		case '5':return ImGuiKey.ImGuiKey_5
			fallthrough
		case '6':return ImGuiKey.ImGuiKey_6
			fallthrough
		case '7':return ImGuiKey.ImGuiKey_7
			fallthrough
		case '8':return ImGuiKey.ImGuiKey_8
			fallthrough
		case '9':return ImGuiKey.ImGuiKey_9
			fallthrough
		case 'A':return ImGuiKey.ImGuiKey_A
			fallthrough
		case 'B':return ImGuiKey.ImGuiKey_B
			fallthrough
		case 'C':return ImGuiKey.ImGuiKey_C
			fallthrough
		case 'D':return ImGuiKey.ImGuiKey_D
			fallthrough
		case 'E':return ImGuiKey.ImGuiKey_E
			fallthrough
		case 'F':return ImGuiKey.ImGuiKey_F
			fallthrough
		case 'G':return ImGuiKey.ImGuiKey_G
			fallthrough
		case 'H':return ImGuiKey.ImGuiKey_H
			fallthrough
		case 'I':return ImGuiKey.ImGuiKey_I
			fallthrough
		case 'J':return ImGuiKey.ImGuiKey_J
			fallthrough
		case 'K':return ImGuiKey.ImGuiKey_K
			fallthrough
		case 'L':return ImGuiKey.ImGuiKey_L
			fallthrough
		case 'M':return ImGuiKey.ImGuiKey_M
			fallthrough
		case 'N':return ImGuiKey.ImGuiKey_N
			fallthrough
		case 'O':return ImGuiKey.ImGuiKey_O
			fallthrough
		case 'P':return ImGuiKey.ImGuiKey_P
			fallthrough
		case 'Q':return ImGuiKey.ImGuiKey_Q
			fallthrough
		case 'R':return ImGuiKey.ImGuiKey_R
			fallthrough
		case 'S':return ImGuiKey.ImGuiKey_S
			fallthrough
		case 'T':return ImGuiKey.ImGuiKey_T
			fallthrough
		case 'U':return ImGuiKey.ImGuiKey_U
			fallthrough
		case 'V':return ImGuiKey.ImGuiKey_V
			fallthrough
		case 'W':return ImGuiKey.ImGuiKey_W
			fallthrough
		case 'X':return ImGuiKey.ImGuiKey_X
			fallthrough
		case 'Y':return ImGuiKey.ImGuiKey_Y
			fallthrough
		case 'Z':return ImGuiKey.ImGuiKey_Z
			fallthrough
		case VK_F1:return ImGuiKey.ImGuiKey_F1
			fallthrough
		case VK_F2:return ImGuiKey.ImGuiKey_F2
			fallthrough
		case VK_F3:return ImGuiKey.ImGuiKey_F3
			fallthrough
		case VK_F4:return ImGuiKey.ImGuiKey_F4
			fallthrough
		case VK_F5:return ImGuiKey.ImGuiKey_F5
			fallthrough
		case VK_F6:return ImGuiKey.ImGuiKey_F6
			fallthrough
		case VK_F7:return ImGuiKey.ImGuiKey_F7
			fallthrough
		case VK_F8:return ImGuiKey.ImGuiKey_F8
			fallthrough
		case VK_F9:return ImGuiKey.ImGuiKey_F9
			fallthrough
		case VK_F10:return ImGuiKey.ImGuiKey_F10
			fallthrough
		case VK_F11:return ImGuiKey.ImGuiKey_F11
			fallthrough
		case VK_F12:return ImGuiKey.ImGuiKey_F12
			fallthrough
		case VK_F13:return ImGuiKey.ImGuiKey_F13
			fallthrough
		case VK_F14:return ImGuiKey.ImGuiKey_F14
			fallthrough
		case VK_F15:return ImGuiKey.ImGuiKey_F15
			fallthrough
		case VK_F16:return ImGuiKey.ImGuiKey_F16
			fallthrough
		case VK_F17:return ImGuiKey.ImGuiKey_F17
			fallthrough
		case VK_F18:return ImGuiKey.ImGuiKey_F18
			fallthrough
		case VK_F19:return ImGuiKey.ImGuiKey_F19
			fallthrough
		case VK_F20:return ImGuiKey.ImGuiKey_F20
			fallthrough
		case VK_F21:return ImGuiKey.ImGuiKey_F21
			fallthrough
		case VK_F22:return ImGuiKey.ImGuiKey_F22
			fallthrough
		case VK_F23:return ImGuiKey.ImGuiKey_F23
			fallthrough
		case VK_F24:return ImGuiKey.ImGuiKey_F24
			fallthrough
		case VK_BROWSER_BACK:return ImGuiKey.ImGuiKey_AppBack
			fallthrough
		case VK_BROWSER_FORWARD:return ImGuiKey.ImGuiKey_AppForward
			fallthrough
		case:return ImGuiKey.ImGuiKey_None
	}
}

// Allow compilation with old Windows SDK. MinGW doesn't have default _WIN32_WINNT/WINVER versions.
when ! WM_MOUSEHWHEEL { /* @gen ifndef */
WM_MOUSEHWHEEL :: 0x020E
} // preproc endif
when ! DBT_DEVNODES_CHANGED { /* @gen ifndef */
DBT_DEVNODES_CHANGED :: 0x0007
} // preproc endif

// Helper to obtain the source of mouse messages.
// See https://learn.microsoft.com/en-us/windows/win32/tablet/system-events-and-mouse-messages
// Prefer to call this at the top of the message handler to avoid the possibility of other Win32 calls interfering with this.
ImGui_ImplWin32_GetMouseSourceFromMessageExtraInfo :: proc() -> ImGuiMouseSource
{
	extra_info : LPARAM = GetMessageExtraInfo()
	if (extra_info & 0xFFFFFF80) == 0xFF515700 { return ImGuiMouseSource.ImGuiMouseSource_Pen }
	if (extra_info & 0xFFFFFF80) == 0xFF515780 { return ImGuiMouseSource.ImGuiMouseSource_TouchScreen }
	return ImGuiMouseSource.ImGuiMouseSource_Mouse
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
ImGui_ImplWin32_WndProcHandler :: proc(hwnd : HWND, msg : UINT, wParam : WPARAM, lParam : LPARAM) -> LRESULT
{
	// Most backends don't have silent checks like this one, but we need it because WndProc are called early in CreateWindow().
	// We silently allow both context or just only backend data to be nullptr.
	if GetCurrentContext() == nil { return 0 }
	return ImGui_ImplWin32_WndProcHandlerEx(hwnd, msg, wParam, lParam, GetIO())
}

// Doesn't use ImGui::GetCurrentContext()
// This version is in theory thread-safe in the sense that no path should access ImGui::GetCurrentContext().
ImGui_ImplWin32_WndProcHandlerEx :: proc(hwnd : HWND, msg : UINT, wParam : WPARAM, lParam : LPARAM, io : ^ImGuiIO) -> LRESULT
{
	bd : ^ImGui_ImplWin32_Data = ImGui_ImplWin32_GetBackendData(io)
	if bd == nil { return 0 }
	switch msg {
		case WM_MOUSEMOVE:
			fallthrough
		case WM_NCMOUSEMOVE:
			{
			// We need to call TrackMouseEvent in order to receive WM_MOUSELEAVE events
			mouse_source : ImGuiMouseSource = ImGui_ImplWin32_GetMouseSourceFromMessageExtraInfo()
			area : i32 = (msg == WM_MOUSEMOVE) ? 1 : 2
			bd.MouseHwnd = hwnd
			if bd.MouseTrackedArea != area {
				tme_cancel : TRACKMOUSEEVENT = {size_of(tme_cancel), TME_CANCEL, hwnd, 0}
				tme_track : TRACKMOUSEEVENT = {size_of(tme_track), cast(DWORD) ((area == 2) ? (TME_LEAVE | TME_NONCLIENT) : TME_LEAVE), hwnd, 0}
				if bd.MouseTrackedArea != 0 { TrackMouseEvent(&tme_cancel) }
				TrackMouseEvent(&tme_track)
				bd.MouseTrackedArea = area
			}
			mouse_pos : POINT = {cast(LONG) GET_X_LPARAM(lParam), cast(LONG) GET_Y_LPARAM(lParam)}
			want_absolute_pos : bool = (io.ConfigFlags & ImGuiConfigFlags_.ImGuiConfigFlags_ViewportsEnable) != {}
			if msg == WM_MOUSEMOVE && want_absolute_pos {
				// WM_MOUSEMOVE are client-relative coordinates.ClientToScreen(hwnd, &mouse_pos)
			}
			if msg == WM_NCMOUSEMOVE && !want_absolute_pos {
				// WM_NCMOUSEMOVE are absolute coordinates.ScreenToClient(hwnd, &mouse_pos)
			}
			AddMouseSourceEvent(&io, mouse_source)
			AddMousePosEvent(&io, cast(f32) mouse_pos.x, cast(f32) mouse_pos.y)
			return 0
			}
			fallthrough
		case WM_MOUSELEAVE:
			fallthrough
		case WM_NCMOUSELEAVE:
			{
			area : i32 = (msg == WM_MOUSELEAVE) ? 1 : 2
			if bd.MouseTrackedArea == area {
				if bd.MouseHwnd == hwnd { bd.MouseHwnd = nil }
				bd.MouseTrackedArea = 0
				AddMousePosEvent(&io, -FLT_MAX, -FLT_MAX)
			}
			return 0
			}
			fallthrough
		case WM_DESTROY:
			if bd.MouseHwnd == hwnd && bd.MouseTrackedArea != 0 {
				tme_cancel : TRACKMOUSEEVENT = {size_of(tme_cancel), TME_CANCEL, hwnd, 0}
				TrackMouseEvent(&tme_cancel)
				bd.MouseHwnd = nil
				bd.MouseTrackedArea = 0
				AddMousePosEvent(&io, -FLT_MAX, -FLT_MAX)
			}
			return 0
			fallthrough
		case WM_LBUTTONDOWN:; fallthrough
		case WM_LBUTTONDBLCLK:
			fallthrough
		case WM_RBUTTONDOWN:; fallthrough
		case WM_RBUTTONDBLCLK:
			fallthrough
		case WM_MBUTTONDOWN:; fallthrough
		case WM_MBUTTONDBLCLK:
			fallthrough
		case WM_XBUTTONDOWN:; fallthrough
		case WM_XBUTTONDBLCLK:
			{
			mouse_source : ImGuiMouseSource = ImGui_ImplWin32_GetMouseSourceFromMessageExtraInfo()
			button : i32 = 0
			if msg == WM_LBUTTONDOWN || msg == WM_LBUTTONDBLCLK { button = 0 }
			if msg == WM_RBUTTONDOWN || msg == WM_RBUTTONDBLCLK { button = 1 }
			if msg == WM_MBUTTONDOWN || msg == WM_MBUTTONDBLCLK { button = 2 }
			if msg == WM_XBUTTONDOWN || msg == WM_XBUTTONDBLCLK { button = (GET_XBUTTON_WPARAM(wParam) == XBUTTON1) ? 3 : 4 }
			if bd.MouseButtonsDown == 0 && GetCapture() == nil {
				// Allow us to read mouse coordinates when dragging mouse outside of our window bounds.
				SetCapture(hwnd)
			}
			bd.MouseButtonsDown |= 1 << button
			AddMouseSourceEvent(&io, mouse_source)
			AddMouseButtonEvent(&io, button, true)
			return 0
			}
			fallthrough
		case WM_LBUTTONUP:
			fallthrough
		case WM_RBUTTONUP:
			fallthrough
		case WM_MBUTTONUP:
			fallthrough
		case WM_XBUTTONUP:
			{
			mouse_source : ImGuiMouseSource = ImGui_ImplWin32_GetMouseSourceFromMessageExtraInfo()
			button : i32 = 0
			if msg == WM_LBUTTONUP { button = 0 }
			if msg == WM_RBUTTONUP { button = 1 }
			if msg == WM_MBUTTONUP { button = 2 }
			if msg == WM_XBUTTONUP { button = (GET_XBUTTON_WPARAM(wParam) == XBUTTON1) ? 3 : 4 }
			bd.MouseButtonsDown &= ~(1 << button)
			if bd.MouseButtonsDown == 0 && GetCapture() == hwnd { ReleaseCapture() }
			AddMouseSourceEvent(&io, mouse_source)
			AddMouseButtonEvent(&io, button, false)
			return 0
			}
			fallthrough
		case WM_MOUSEWHEEL:
			AddMouseWheelEvent(&io, 0.0, cast(f32) GET_WHEEL_DELTA_WPARAM(wParam) / cast(f32) WHEEL_DELTA)
			return 0
			fallthrough
		case WM_MOUSEHWHEEL:
			AddMouseWheelEvent(&io, -cast(f32) GET_WHEEL_DELTA_WPARAM(wParam) / cast(f32) WHEEL_DELTA, 0.0)
			return 0
			fallthrough
		case WM_KEYDOWN:
			fallthrough
		case WM_KEYUP:
			fallthrough
		case WM_SYSKEYDOWN:
			fallthrough
		case WM_SYSKEYUP:
			{
			is_key_down : bool = (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN)
			if wParam < 256 {
				// Submit modifiers
				ImGui_ImplWin32_UpdateKeyModifiers(io)

				// Obtain virtual key code and convert to ImGuiKey
				key : ImGuiKey = ImGui_ImplWin32_KeyEventToImGuiKey(wParam, lParam)
				vk : i32 = cast(i32) wParam
				scancode : i32 = cast(i32) LOBYTE(HIWORD(lParam))

				// Special behavior for VK_SNAPSHOT / ImGuiKey_PrintScreen as Windows doesn't emit the key down event.
				if key == ImGuiKey.ImGuiKey_PrintScreen && !is_key_down { ImGui_ImplWin32_AddKeyEvent(io, key, true, vk, scancode) }

				// Submit key event
				if key != ImGuiKey.ImGuiKey_None { ImGui_ImplWin32_AddKeyEvent(io, key, is_key_down, vk, scancode) }

				// Submit individual left/right modifier events
				if vk == VK_SHIFT {
					// Important: Shift keys tend to get stuck when pressed together, missing key-up events are corrected in ImGui_ImplWin32_ProcessKeyEventsWorkarounds()
					if IsVkDown(VK_LSHIFT) == is_key_down { ImGui_ImplWin32_AddKeyEvent(io, ImGuiKey.ImGuiKey_LeftShift, is_key_down, VK_LSHIFT, scancode) }
					if IsVkDown(VK_RSHIFT) == is_key_down { ImGui_ImplWin32_AddKeyEvent(io, ImGuiKey.ImGuiKey_RightShift, is_key_down, VK_RSHIFT, scancode) }
				}
				else if vk == VK_CONTROL {
					if IsVkDown(VK_LCONTROL) == is_key_down { ImGui_ImplWin32_AddKeyEvent(io, ImGuiKey.ImGuiKey_LeftCtrl, is_key_down, VK_LCONTROL, scancode) }
					if IsVkDown(VK_RCONTROL) == is_key_down { ImGui_ImplWin32_AddKeyEvent(io, ImGuiKey.ImGuiKey_RightCtrl, is_key_down, VK_RCONTROL, scancode) }
				}
				else if vk == VK_MENU {
					if IsVkDown(VK_LMENU) == is_key_down { ImGui_ImplWin32_AddKeyEvent(io, ImGuiKey.ImGuiKey_LeftAlt, is_key_down, VK_LMENU, scancode) }
					if IsVkDown(VK_RMENU) == is_key_down { ImGui_ImplWin32_AddKeyEvent(io, ImGuiKey.ImGuiKey_RightAlt, is_key_down, VK_RMENU, scancode) }
				}
			}
			return 0
			}
			fallthrough
		case WM_SETFOCUS:
			fallthrough
		case WM_KILLFOCUS:
			AddFocusEvent(&io, msg == WM_SETFOCUS)
			return 0
			fallthrough
		case WM_INPUTLANGCHANGE:
			ImGui_ImplWin32_UpdateKeyboardCodePage(io)
			return 0
			fallthrough
		case WM_CHAR:
			if IsWindowUnicode(hwnd) != {} {
				// You can also use ToAscii()+GetKeyboardState() to retrieve characters.
				if wParam > 0 && wParam < 0x10000 { AddInputCharacterUTF16(&io, cast(u16) wParam) }
			}
			else {
				wch : wchar_t = 0
				MultiByteToWideChar(bd.KeyboardCodePage, MB_PRECOMPOSED, cast(^u8) &wParam, 1, &wch, 1)
				AddInputCharacter(&io, wch)
			}
			return 0
			fallthrough
		case WM_SETCURSOR:
			// This is required to restore cursor when transitioning from e.g resize borders to client area.
			if LOWORD(lParam) == HTCLIENT && ImGui_ImplWin32_UpdateMouseCursor(io, bd.LastMouseCursor) { return 1 }
			return 0
			fallthrough
		case WM_DEVICECHANGE:
			when ! IMGUI_IMPL_WIN32_DISABLE_GAMEPAD { /* @gen ifndef */
			if cast(UINT) wParam == DBT_DEVNODES_CHANGED { bd.WantUpdateHasGamepad = true }
			} // preproc endif
			return 0
			fallthrough
		case WM_DISPLAYCHANGE:
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
// ImGui_ImplWin32_EnableDpiAwareness() is just a helper called by main.cpp, we don't call it automatically.
// If you are trying to implement your own backend for your own engine, you may ignore that noise.
//---------------------------------------------------------------------------------------------------------

// Perform our own check with RtlVerifyVersionInfo() instead of using functions from <VersionHelpers.h> as they
// require a manifest to be functional for checks above 8.1. See https://github.com/ocornut/imgui/issues/4200
_IsWindowsVersionOrGreater :: proc(major : WORD, minor : WORD, _ : WORD) -> BOOL
{
	PFN_RtlVerifyVersionInfo :: proc(_ : ^OSVERSIONINFOEXW, _ : ULONG, _ : ULONGLONG) -> LONG
	RtlVerifyVersionInfoFn : PFN_RtlVerifyVersionInfo = nil
	if RtlVerifyVersionInfoFn == nil { if ntdllModule : HMODULE = GetModuleHandleA("ntdll.dll"); ntdllModule { RtlVerifyVersionInfoFn = cast(PFN_RtlVerifyVersionInfo) GetProcAddress(ntdllModule, "RtlVerifyVersionInfo") } }
	if RtlVerifyVersionInfoFn == nil { return FALSE }

	versionInfo : RTL_OSVERSIONINFOEXW = {}
	conditionMask : ULONGLONG = 0
	versionInfo.dwOSVersionInfoSize = size_of(RTL_OSVERSIONINFOEXW)
	versionInfo.dwMajorVersion = major
	versionInfo.dwMinorVersion = minor
	VER_SET_CONDITION(conditionMask, VER_MAJORVERSION, VER_GREATER_EQUAL)
	VER_SET_CONDITION(conditionMask, VER_MINORVERSION, VER_GREATER_EQUAL)
	return (RtlVerifyVersionInfoFn(&versionInfo, VER_MAJORVERSION | VER_MINORVERSION, conditionMask) == {}) ? TRUE : FALSE
}

_IsWindowsVistaOrGreater :: #force_inline proc "contextless" () //TODO @gen: Validate the parameters were not passed by reference.
{
	_IsWindowsVersionOrGreater(HIBYTE(0x0600),LOBYTE(0x0600),0)// _WIN32_WINNT_VISTA
}

_IsWindows8OrGreater :: #force_inline proc "contextless" () //TODO @gen: Validate the parameters were not passed by reference.
{
	_IsWindowsVersionOrGreater(HIBYTE(0x0602),LOBYTE(0x0602),0)// _WIN32_WINNT_WIN8
}

_IsWindows8Point1OrGreater :: #force_inline proc "contextless" () //TODO @gen: Validate the parameters were not passed by reference.
{
	_IsWindowsVersionOrGreater(HIBYTE(0x0603),LOBYTE(0x0603),0)// _WIN32_WINNT_WINBLUE
}

_IsWindows10OrGreater :: #force_inline proc "contextless" () //TODO @gen: Validate the parameters were not passed by reference.
{
	_IsWindowsVersionOrGreater(HIBYTE(0x0A00),LOBYTE(0x0A00),0)// _WIN32_WINNT_WINTHRESHOLD / _WIN32_WINNT_WIN10
}


when ! DPI_ENUMS_DECLARED { /* @gen ifndef */
PROCESS_DPI_AWARENESSE0 :: enum i32 { PROCESS_DPI_UNAWARE = 0, PROCESS_SYSTEM_DPI_AWARE = 1, PROCESS_PER_MONITOR_DPI_AWARE = 2, }
MONITOR_DPI_TYPEE1 :: enum i32 { MDT_EFFECTIVE_DPI = 0, MDT_ANGULAR_DPI = 1, MDT_RAW_DPI = 2, MDT_DEFAULT = MDT_EFFECTIVE_DPI, }
} // preproc endif
when ! _DPI_AWARENESS_CONTEXTS_ { /* @gen ifndef */
DECLARE_HANDLE(DPI_AWARENESS_CONTEXT)
DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE :: (DPI_AWARENESS_CONTEXT)-3
} // preproc endif
when ! DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 { /* @gen ifndef */
DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 :: (DPI_AWARENESS_CONTEXT)-4
} // preproc endif
PFN_SetProcessDpiAwareness :: proc(_ : PROCESS_DPI_AWARENESS) -> HRESULT// Shcore.lib + dll, Windows 8.1+
PFN_GetDpiForMonitor :: proc(_ : HMONITOR, _ : MONITOR_DPI_TYPE, _ : ^UINT, _ : ^UINT) -> HRESULT// Shcore.lib + dll, Windows 8.1+
PFN_SetThreadDpiAwarenessContext :: proc(_ : DPI_AWARENESS_CONTEXT) -> DPI_AWARENESS_CONTEXT// User32.lib + dll, Windows 10 v1607+ (Creators Update)

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
ImGui_ImplWin32_EnableDpiAwareness :: proc()
{
	// Make sure monitors will be updated with latest correct scaling
	if bd : ^ImGui_ImplWin32_Data = ImGui_ImplWin32_GetBackendData(); bd { bd.WantUpdateMonitors = true }

	if _IsWindows10OrGreater() {
		user32_dll : HINSTANCE = LoadLibraryA("user32.dll"); // Reference counted per-process
		if SetThreadDpiAwarenessContextFn : PFN_SetThreadDpiAwarenessContext = cast(PFN_SetThreadDpiAwarenessContext) GetProcAddress(user32_dll, "SetThreadDpiAwarenessContext"); SetThreadDpiAwarenessContextFn {
			SetThreadDpiAwarenessContextFn(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)
			return
		}
	}
	if _IsWindows8Point1OrGreater() {
		shcore_dll : HINSTANCE = LoadLibraryA("shcore.dll"); // Reference counted per-process
		if SetProcessDpiAwarenessFn : PFN_SetProcessDpiAwareness = cast(PFN_SetProcessDpiAwareness) GetProcAddress(shcore_dll, "SetProcessDpiAwareness"); SetProcessDpiAwarenessFn {
			SetProcessDpiAwarenessFn(E0.PROCESS_PER_MONITOR_DPI_AWARE)
			return
		}
	}
	when _WIN32_WINNT >= 0x0600 {
	SetProcessDPIAware()
	} // preproc endif
}

when defined ( _MSC_VER ) && ! defined ( NOGDI ) {
} // preproc endif

// HMONITOR monitor
ImGui_ImplWin32_GetDpiScaleForMonitor :: proc(monitor : rawptr) -> f32
{
	xdpi : UINT = 96; ydpi : UINT = 96
	if _IsWindows8Point1OrGreater() {
		shcore_dll : HINSTANCE = LoadLibraryA("shcore.dll"); // Reference counted per-process
		GetDpiForMonitorFn : PFN_GetDpiForMonitor = nil
		if GetDpiForMonitorFn == nil && shcore_dll != nil { GetDpiForMonitorFn = cast(PFN_GetDpiForMonitor) GetProcAddress(shcore_dll, "GetDpiForMonitor") }
		if GetDpiForMonitorFn != nil {
			GetDpiForMonitorFn(cast(HMONITOR) monitor, E1.MDT_EFFECTIVE_DPI, &xdpi, &ydpi)
			IM_ASSERT(xdpi == ydpi); // Please contact me if you hit this assert!
			return xdpi / 96.0
		}
	}
	when ! NOGDI { /* @gen ifndef */
	dc : HDC = GetDC(nil)
	xdpi = GetDeviceCaps(dc, LOGPIXELSX)
	ydpi = GetDeviceCaps(dc, LOGPIXELSY)
	IM_ASSERT(xdpi == ydpi); // Please contact me if you hit this assert!
	ReleaseDC(nil, dc)
	} // preproc endif
	return xdpi / 96.0
}

// HWND hwnd
ImGui_ImplWin32_GetDpiScaleForHwnd :: proc(hwnd : rawptr) -> f32
{
	monitor : HMONITOR = MonitorFromWindow(cast(HWND) hwnd, MONITOR_DEFAULTTONEAREST)
	return ImGui_ImplWin32_GetDpiScaleForMonitor(monitor)
}

//---------------------------------------------------------------------------------------------------------
// Transparency related helpers (optional)
//--------------------------------------------------------------------------------------------------------

when defined ( _MSC_VER ) {
} // preproc endif

// Transparency related helpers (optional) [experimental]
// - Use to enable alpha compositing transparency with the desktop.
// - Use together with e.g. clearing your framebuffer with zero-alpha.
// HWND hwnd
// [experimental]
// Borrowed from GLFW's function updateFramebufferTransparency() in src/win32_window.c
// (the Dwm* functions are Vista era functions but we are borrowing logic from GLFW)
ImGui_ImplWin32_EnableAlphaCompositing :: proc(hwnd : rawptr)
{
	if !_IsWindowsVistaOrGreater() { return }

	composition : BOOL
	if FAILED(DwmIsCompositionEnabled(&composition)) || composition == {} { return }

	opaque : BOOL
	color : DWORD
	if _IsWindows8OrGreater() || (SUCCEEDED(DwmGetColorizationColor(&color, &opaque)) && opaque == {}) {
		region : HRGN = CreateRectRgn(0, 0, -1, -1)
		bb : DWM_BLURBEHIND = {}
		bb.dwFlags = DWM_BB_ENABLE | DWM_BB_BLURREGION
		bb.hRgnBlur = region
		bb.fEnable = TRUE
		DwmEnableBlurBehindWindow(cast(HWND) hwnd, &bb)
		DeleteObject(region)
	}
	else {
		bb : DWM_BLURBEHIND = {}
		bb.dwFlags = DWM_BB_ENABLE
		DwmEnableBlurBehindWindow(cast(HWND) hwnd, &bb)
	}
}

//---------------------------------------------------------------------------------------------------------
// MULTI-VIEWPORT / PLATFORM INTERFACE SUPPORT
// This is an _advanced_ and _optional_ feature, allowing the backend to create and handle multiple viewports simultaneously.
// If you are new to dear imgui or creating a new binding for dear imgui, it is recommended that you completely ignore this section first..
//--------------------------------------------------------------------------------------------------------

// Helper structure we store in the void* RendererUserData field of each ImGuiViewport to easily retrieve our backend data.
ImGui_ImplWin32_ViewportData :: struct {
	Hwnd : HWND,
	HwndParent : HWND,
	HwndOwned : bool,
	DwStyle : DWORD,
	DwExStyle : DWORD,
}

ImGui_ImplWin32_ViewportData_deinit :: proc(this : ^ImGui_ImplWin32_ViewportData)
{IM_ASSERT(this.Hwnd == nil)}

ImGui_ImplWin32_ViewportData_init :: proc(this : ^ImGui_ImplWin32_ViewportData)
{
	this.HwndParent = nil; this.Hwnd = this.HwndParent; this.HwndOwned = false; this.DwExStyle = 0; this.DwStyle = this.DwExStyle
}

ImGui_ImplWin32_GetWin32StyleFromViewportFlags :: proc(flags : ImGuiViewportFlags, out_style : ^DWORD, out_ex_style : ^DWORD)
{
	if (flags & ImGuiViewportFlags_.ImGuiViewportFlags_NoDecoration) != {} { out_style^ = WS_POPUP }
	else { out_style^ = WS_OVERLAPPEDWINDOW }

	if (flags & ImGuiViewportFlags_.ImGuiViewportFlags_NoTaskBarIcon) != {} { out_ex_style^ = WS_EX_TOOLWINDOW }
	else { out_ex_style^ = WS_EX_APPWINDOW }

	if (flags & ImGuiViewportFlags_.ImGuiViewportFlags_TopMost) != {} { out_ex_style^ |= WS_EX_TOPMOST }
}

ImGui_ImplWin32_GetHwndFromViewportID :: proc(viewport_id : ImGuiID) -> HWND
{
	if viewport_id != 0 { if viewport : ^ImGuiViewport = FindViewportByID(viewport_id); viewport { return cast(HWND) viewport.PlatformHandle } }
	return nil
}

ImGui_ImplWin32_CreateWindow :: proc(viewport : ^ImGuiViewport)
{
	vd : ^ImGui_ImplWin32_ViewportData = IM_NEW(ImGui_ImplWin32_ViewportData)()
	viewport.PlatformUserData = vd

	// Select style and parent window
	ImGui_ImplWin32_GetWin32StyleFromViewportFlags(viewport.Flags, &vd.DwStyle, &vd.DwExStyle)
	vd.HwndParent = ImGui_ImplWin32_GetHwndFromViewportID(viewport.ParentViewportId)

	// Create window
	rect : RECT = {cast(LONG) viewport.Pos.x, cast(LONG) viewport.Pos.y, cast(LONG) (viewport.Pos.x + viewport.Size.x), cast(LONG) (viewport.Pos.y + viewport.Size.y)}
	AdjustWindowRectEx(&rect, vd.DwStyle, FALSE, vd.DwExStyle)
	vd.Hwnd = CreateWindowExW(vd.DwExStyle, "ImGui Platform", "Untitled", vd.DwStyle, rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top, vd.HwndParent, nil, GetModuleHandle(nil), nil); // Owner window, Menu, Instance, Param
	vd.HwndOwned = true
	viewport.PlatformRequestResize = false
	viewport.PlatformHandleRaw = vd.Hwnd; viewport.PlatformHandle = viewport.PlatformHandleRaw

	// Secondary viewports store their imgui context
	SetPropA(vd.Hwnd, "IMGUI_CONTEXT", GetCurrentContext())
}

ImGui_ImplWin32_DestroyWindow :: proc(viewport : ^ImGuiViewport)
{
	bd : ^ImGui_ImplWin32_Data = ImGui_ImplWin32_GetBackendData()
	if vd : ^ImGui_ImplWin32_ViewportData = cast(^ImGui_ImplWin32_ViewportData) viewport.PlatformUserData; vd {
		if GetCapture() == vd.Hwnd {
			// Transfer capture so if we started dragging from a window that later disappears, we'll still receive the MOUSEUP event.
			ReleaseCapture()
			SetCapture(bd.hWnd)
		}
		if vd.Hwnd != {} && vd.HwndOwned { DestroyWindow(vd.Hwnd) }
		vd.Hwnd = nil
		IM_DELETE(vd)
	}
	viewport.PlatformHandle = nil; viewport.PlatformUserData = viewport.PlatformHandle
}

ImGui_ImplWin32_ShowWindow :: proc(viewport : ^ImGuiViewport)
{
	vd : ^ImGui_ImplWin32_ViewportData = cast(^ImGui_ImplWin32_ViewportData) viewport.PlatformUserData
	IM_ASSERT(vd.Hwnd != {})

	// ShowParent() also brings parent to front, which is not always desirable,
	// so we temporarily disable parenting. (#7354)
	if vd.HwndParent != nil { SetWindowLongPtr(vd.Hwnd, GWLP_HWNDPARENT, cast(LONG_PTR) nil) }

	if (viewport.Flags & ImGuiViewportFlags_.ImGuiViewportFlags_NoFocusOnAppearing) != {} { ShowWindow(vd.Hwnd, SW_SHOWNA) }
	else { ShowWindow(vd.Hwnd, SW_SHOW) }

	// Restore
	if vd.HwndParent != nil { SetWindowLongPtr(vd.Hwnd, GWLP_HWNDPARENT, cast(LONG_PTR) vd.HwndParent) }
}

ImGui_ImplWin32_UpdateWindow :: proc(viewport : ^ImGuiViewport)
{
	vd : ^ImGui_ImplWin32_ViewportData = cast(^ImGui_ImplWin32_ViewportData) viewport.PlatformUserData
	IM_ASSERT(vd.Hwnd != {})

	// Update Win32 parent if it changed _after_ creation
	// Unlike style settings derived from configuration flags, this is more likely to change for advanced apps that are manipulating ParentViewportID manually.
	new_parent : HWND = ImGui_ImplWin32_GetHwndFromViewportID(viewport.ParentViewportId)
	if new_parent != vd.HwndParent {
		// Win32 windows can either have a "Parent" (for WS_CHILD window) or an "Owner" (which among other thing keeps window above its owner).
		// Our Dear Imgui-side concept of parenting only mostly care about what Win32 call "Owner".
		// The parent parameter of CreateWindowEx() sets up Parent OR Owner depending on WS_CHILD flag. In our case an Owner as we never use WS_CHILD.
		// Calling ::SetParent() here would be incorrect: it will create a full child relation, alter coordinate system and clipping.
		// Calling ::SetWindowLongPtr() with GWLP_HWNDPARENT seems correct although poorly documented.
		// https://devblogs.microsoft.com/oldnewthing/20100315-00/?p=14613
		vd.HwndParent = new_parent
		SetWindowLongPtr(vd.Hwnd, GWLP_HWNDPARENT, cast(LONG_PTR) vd.HwndParent)
	}

	// (Optional) Update Win32 style if it changed _after_ creation.
	// Generally they won't change unless configuration flags are changed, but advanced uses (such as manually rewriting viewport flags) make this useful.
	new_style : DWORD
	new_ex_style : DWORD
	ImGui_ImplWin32_GetWin32StyleFromViewportFlags(viewport.Flags, &new_style, &new_ex_style)

	// Only reapply the flags that have been changed from our point of view (as other flags are being modified by Windows)
	if vd.DwStyle != new_style || vd.DwExStyle != new_ex_style {
		// (Optional) Update TopMost state if it changed _after_ creation
		top_most_changed : bool = (vd.DwExStyle & WS_EX_TOPMOST) != (new_ex_style & WS_EX_TOPMOST)
		insert_after : HWND = top_most_changed ? ((viewport.Flags & ImGuiViewportFlags_.ImGuiViewportFlags_TopMost) != {} ? HWND_TOPMOST : HWND_NOTOPMOST) : 0
		swp_flag : UINT = top_most_changed ? 0 : SWP_NOZORDER

		// Apply flags and position (since it is affected by flags)
		vd.DwStyle = new_style
		vd.DwExStyle = new_ex_style
		SetWindowLong(vd.Hwnd, GWL_STYLE, vd.DwStyle)
		SetWindowLong(vd.Hwnd, GWL_EXSTYLE, vd.DwExStyle)
		rect : RECT = {cast(LONG) viewport.Pos.x, cast(LONG) viewport.Pos.y, cast(LONG) (viewport.Pos.x + viewport.Size.x), cast(LONG) (viewport.Pos.y + viewport.Size.y)}
		AdjustWindowRectEx(&rect, vd.DwStyle, FALSE, vd.DwExStyle); // Client to Screen
		SetWindowPos(vd.Hwnd, insert_after, rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top, swp_flag | SWP_NOACTIVATE | SWP_FRAMECHANGED)
		ShowWindow(vd.Hwnd, SW_SHOWNA); // This is necessary when we alter the style
		viewport.PlatformRequestResize = true; viewport.PlatformRequestMove = viewport.PlatformRequestResize
	}
}

ImGui_ImplWin32_GetWindowPos :: proc(viewport : ^ImGuiViewport) -> ImVec2
{
	vd : ^ImGui_ImplWin32_ViewportData = cast(^ImGui_ImplWin32_ViewportData) viewport.PlatformUserData
	IM_ASSERT(vd.Hwnd != {})
	pos : POINT = {0, 0}
	ClientToScreen(vd.Hwnd, &pos)
	return ImVec2(cast(f32) pos.x, cast(f32) pos.y)
}

ImGui_ImplWin32_UpdateWin32StyleFromWindow :: proc(viewport : ^ImGuiViewport)
{
	vd : ^ImGui_ImplWin32_ViewportData = cast(^ImGui_ImplWin32_ViewportData) viewport.PlatformUserData
	vd.DwStyle = GetWindowLongW(vd.Hwnd, GWL_STYLE)
	vd.DwExStyle = GetWindowLongW(vd.Hwnd, GWL_EXSTYLE)
}

ImGui_ImplWin32_SetWindowPos :: proc(viewport : ^ImGuiViewport, pos : ImVec2)
{
	vd : ^ImGui_ImplWin32_ViewportData = cast(^ImGui_ImplWin32_ViewportData) viewport.PlatformUserData
	IM_ASSERT(vd.Hwnd != {})
	rect : RECT = {cast(LONG) pos.x, cast(LONG) pos.y, cast(LONG) pos.x, cast(LONG) pos.y}
	if (viewport.Flags & ImGuiViewportFlags_.ImGuiViewportFlags_OwnedByApp) != {} {
		// Not our window, poll style before using
		ImGui_ImplWin32_UpdateWin32StyleFromWindow(viewport)
	}
	AdjustWindowRectEx(&rect, vd.DwStyle, FALSE, vd.DwExStyle)
	SetWindowPos(vd.Hwnd, nil, rect.left, rect.top, 0, 0, SWP_NOZORDER | SWP_NOSIZE | SWP_NOACTIVATE)
}

ImGui_ImplWin32_GetWindowSize :: proc(viewport : ^ImGuiViewport) -> ImVec2
{
	vd : ^ImGui_ImplWin32_ViewportData = cast(^ImGui_ImplWin32_ViewportData) viewport.PlatformUserData
	IM_ASSERT(vd.Hwnd != {})
	rect : RECT
	GetClientRect(vd.Hwnd, &rect)
	return ImVec2(float(rect.right - rect.left), float(rect.bottom - rect.top))
}

ImGui_ImplWin32_SetWindowSize :: proc(viewport : ^ImGuiViewport, size : ImVec2)
{
	vd : ^ImGui_ImplWin32_ViewportData = cast(^ImGui_ImplWin32_ViewportData) viewport.PlatformUserData
	IM_ASSERT(vd.Hwnd != {})
	rect : RECT = {0, 0, cast(LONG) size.x, cast(LONG) size.y}
	if (viewport.Flags & ImGuiViewportFlags_.ImGuiViewportFlags_OwnedByApp) != {} {
		// Not our window, poll style before using
		ImGui_ImplWin32_UpdateWin32StyleFromWindow(viewport)
	}
	AdjustWindowRectEx(&rect, vd.DwStyle, FALSE, vd.DwExStyle); // Client to Screen
	SetWindowPos(vd.Hwnd, nil, 0, 0, rect.right - rect.left, rect.bottom - rect.top, SWP_NOZORDER | SWP_NOMOVE | SWP_NOACTIVATE)
}

ImGui_ImplWin32_SetWindowFocus :: proc(viewport : ^ImGuiViewport)
{
	vd : ^ImGui_ImplWin32_ViewportData = cast(^ImGui_ImplWin32_ViewportData) viewport.PlatformUserData
	IM_ASSERT(vd.Hwnd != {})
	BringWindowToTop(vd.Hwnd)
	SetForegroundWindow(vd.Hwnd)
	SetFocus(vd.Hwnd)
}

ImGui_ImplWin32_GetWindowFocus :: proc(viewport : ^ImGuiViewport) -> bool
{
	vd : ^ImGui_ImplWin32_ViewportData = cast(^ImGui_ImplWin32_ViewportData) viewport.PlatformUserData
	IM_ASSERT(vd.Hwnd != {})
	return GetForegroundWindow() == vd.Hwnd
}

ImGui_ImplWin32_GetWindowMinimized :: proc(viewport : ^ImGuiViewport) -> bool
{
	vd : ^ImGui_ImplWin32_ViewportData = cast(^ImGui_ImplWin32_ViewportData) viewport.PlatformUserData
	IM_ASSERT(vd.Hwnd != {})
	return IsIconic(vd.Hwnd) != {}
}

ImGui_ImplWin32_SetWindowTitle :: proc(viewport : ^ImGuiViewport, title : ^u8)
{
	// ::SetWindowTextA() doesn't properly handle UTF-8 so we explicitely convert our string.
	vd : ^ImGui_ImplWin32_ViewportData = cast(^ImGui_ImplWin32_ViewportData) viewport.PlatformUserData
	IM_ASSERT(vd.Hwnd != {})
	n : i32 = MultiByteToWideChar(CP_UTF8, 0, title, -1, nil, 0)
	title_w : ImVector(wchar_t)
	resize(&title_w, n)
	MultiByteToWideChar(CP_UTF8, 0, title, -1, title_w.Data, n)
	SetWindowTextW(vd.Hwnd, title_w.Data)
}

ImGui_ImplWin32_SetWindowAlpha :: proc(viewport : ^ImGuiViewport, alpha : f32)
{
	vd : ^ImGui_ImplWin32_ViewportData = cast(^ImGui_ImplWin32_ViewportData) viewport.PlatformUserData
	IM_ASSERT(vd.Hwnd != {})
	IM_ASSERT(alpha >= 0.0 && alpha <= 1.0)
	if alpha < 1.0 {
		ex_style : DWORD = GetWindowLongW(vd.Hwnd, GWL_EXSTYLE) | WS_EX_LAYERED
		SetWindowLongW(vd.Hwnd, GWL_EXSTYLE, ex_style)
		SetLayeredWindowAttributes(vd.Hwnd, 0, cast(BYTE) (255 * alpha), LWA_ALPHA)
	}
	else {
		ex_style : DWORD = GetWindowLongW(vd.Hwnd, GWL_EXSTYLE) & ~WS_EX_LAYERED
		SetWindowLongW(vd.Hwnd, GWL_EXSTYLE, ex_style)
	}
}

ImGui_ImplWin32_GetWindowDpiScale :: proc(viewport : ^ImGuiViewport) -> f32
{
	vd : ^ImGui_ImplWin32_ViewportData = cast(^ImGui_ImplWin32_ViewportData) viewport.PlatformUserData
	IM_ASSERT(vd.Hwnd != {})
	return ImGui_ImplWin32_GetDpiScaleForHwnd(vd.Hwnd)
}

// FIXME-DPI: Testing DPI related ideas
ImGui_ImplWin32_OnChangedViewport :: proc(viewport : ^ImGuiViewport)
{
	_ = viewport

}

ImGui_ImplWin32_WndProcHandler_PlatformWindow :: proc(hWnd : HWND, msg : UINT, wParam : WPARAM, lParam : LPARAM) -> LRESULT
{
	// Allow secondary viewport WndProc to be called regardless of current context
	ctx : ^ImGuiContext = cast(^ImGuiContext) GetPropA(hWnd, "IMGUI_CONTEXT")
	if ctx == nil {
		// unlike ImGui_ImplWin32_WndProcHandler() we are called directly by Windows, we can't just return 0.
		return DefWindowProc(hWnd, msg, wParam, lParam)
	}

	io : ^ImGuiIO = GetIOEx(ctx)
	platform_io : ^ImGuiPlatformIO = GetPlatformIOEx(ctx)
	result : LRESULT = 0
	if ImGui_ImplWin32_WndProcHandlerEx(hWnd, msg, wParam, lParam, io) != {} { result = true }
	else if viewport : ^ImGuiViewport = ImGui_ImplWin32_FindViewportByPlatformHandle(platform_io, hWnd); viewport {
		switch msg {
			case WM_CLOSE:
				viewport.PlatformRequestClose = true
				break

			case WM_MOVE:
				viewport.PlatformRequestMove = true
				break

			case WM_SIZE:
				viewport.PlatformRequestResize = true
				break

			case WM_MOUSEACTIVATE:
				if (viewport.Flags & ImGuiViewportFlags_.ImGuiViewportFlags_NoFocusOnClick) != {} { result = MA_NOACTIVATE }
				break

			case WM_NCHITTEST:
				// Let mouse pass-through the window. This will allow the backend to call io.AddMouseViewportEvent() correctly. (which is optional).
				// The ImGuiViewportFlags_NoInputs flag is set while dragging a viewport, as want to detect the window behind the one we are dragging.
				// If you cannot easily access those viewport flags from your windowing/event code: you may manually synchronize its state e.g. in
				// your main loop after calling UpdatePlatformWindows(). Iterate all viewports/platform windows and pass the flag to your windowing system.
				if (viewport.Flags & ImGuiViewportFlags_.ImGuiViewportFlags_NoInputs) != {} { result = HTTRANSPARENT }
				break
		}
	}
	if result == {} { result = DefWindowProc(hWnd, msg, wParam, lParam) }
	return result
}

// Forward Declarations
ImGui_ImplWin32_InitMultiViewportSupport :: proc(platform_has_own_dc : bool)
{
	wcex : WNDCLASSEXW
	wcex.cbSize = size_of(WNDCLASSEXW)
	wcex.style = CS_HREDRAW | CS_VREDRAW | (platform_has_own_dc ? CS_OWNDC : 0)
	wcex.lpfnWndProc = ImGui_ImplWin32_WndProcHandler_PlatformWindow
	wcex.cbClsExtra = 0
	wcex.cbWndExtra = 0
	wcex.hInstance = GetModuleHandle(nil)
	wcex.hIcon = nil
	wcex.hCursor = nil
	wcex.hbrBackground = cast(HBRUSH) (COLOR_BACKGROUND + 1)
	wcex.lpszMenuName = nil
	wcex.lpszClassName = "ImGui Platform"
	wcex.hIconSm = nil
	RegisterClassExW(&wcex)

	ImGui_ImplWin32_UpdateMonitors()

	// Register platform interface (will be coupled with a renderer interface)
	platform_io : ^ImGuiPlatformIO = GetPlatformIO()
	platform_io.Platform_CreateWindow = ImGui_ImplWin32_CreateWindow
	platform_io.Platform_DestroyWindow = ImGui_ImplWin32_DestroyWindow
	platform_io.Platform_ShowWindow = ImGui_ImplWin32_ShowWindow
	platform_io.Platform_SetWindowPos = ImGui_ImplWin32_SetWindowPos
	platform_io.Platform_GetWindowPos = ImGui_ImplWin32_GetWindowPos
	platform_io.Platform_SetWindowSize = ImGui_ImplWin32_SetWindowSize
	platform_io.Platform_GetWindowSize = ImGui_ImplWin32_GetWindowSize
	platform_io.Platform_SetWindowFocus = ImGui_ImplWin32_SetWindowFocus
	platform_io.Platform_GetWindowFocus = ImGui_ImplWin32_GetWindowFocus
	platform_io.Platform_GetWindowMinimized = ImGui_ImplWin32_GetWindowMinimized
	platform_io.Platform_SetWindowTitle = ImGui_ImplWin32_SetWindowTitle
	platform_io.Platform_SetWindowAlpha = ImGui_ImplWin32_SetWindowAlpha
	platform_io.Platform_UpdateWindow = ImGui_ImplWin32_UpdateWindow
	platform_io.Platform_GetWindowDpiScale = ImGui_ImplWin32_GetWindowDpiScale; // FIXME-DPI
	platform_io.Platform_OnChangedViewport = ImGui_ImplWin32_OnChangedViewport; // FIXME-DPI

	// Register main window handle (which is owned by the main application, not by us)
	// This is mostly for simplicity and consistency, so that our code (e.g. mouse handling etc.) can use same logic for main and secondary viewports.
	main_viewport : ^ImGuiViewport = GetMainViewport()
	bd : ^ImGui_ImplWin32_Data = ImGui_ImplWin32_GetBackendData()
	vd : ^ImGui_ImplWin32_ViewportData = IM_NEW(ImGui_ImplWin32_ViewportData)()
	vd.Hwnd = bd.hWnd
	vd.HwndOwned = false
	main_viewport.PlatformUserData = vd
}

ImGui_ImplWin32_ShutdownMultiViewportSupport :: proc()
{
	UnregisterClass(_T("ImGui Platform"), GetModuleHandle(nil))
	DestroyPlatformWindows()
}

//---------------------------------------------------------------------------------------------------------

when defined ( __GNUC__ ) {
} // preproc endif
when defined ( __clang__ ) {
} // preproc endif

} // preproc endif// #ifndef IMGUI_DISABLE
