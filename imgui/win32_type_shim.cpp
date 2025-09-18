// BEGIN STD SHIM

typedef unsigned long long int size_t;
typedef unsigned short int wchar_t;

typedef unsigned char uint8_t;
typedef unsigned short int uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long int uint64_t;

typedef signed char int8_t;
typedef signed short int int16_t;
typedef signed int int32_t;
typedef signed long long int int64_t;

int strlen(char*);
int strcmp(const char* lhs, const char* rhs);
int memcmp(const void* lhs, const void* rhs, size_t count);
int strncmp(const char* lhs, const char* rhs, size_t count);
int fseek(void* stream, long offset, int origin);
int fclose(void* stream);

int WEXITSTATUS(int a);

int offsetof(void* ex);
int sizeof(void* ex);

// END STD SHIM

// BEGIN STB SHIM

typedef int stbrp_coord;

struct stbrp_rect
{
	int            id;
	stbrp_coord    w, h;
	stbrp_coord    x, y;
	int            was_packed;
};

struct stbrp_node
{
	stbrp_coord  x,y;
	stbrp_node  *next;
};

struct stbrp_context
{
	int width;
	int height;
	int align;
	int init_mode;
	int heuristic;
	int num_nodes;
	stbrp_node *active_head;
	stbrp_node *free_head;
	stbrp_node extra[2]; // we allocate two extra nodes so optimal user-node-count is 'width' not 'width+2'
};


struct stbtt_aligned_quad
{
	float x0,y0,s0,t0;
	float x1,y1,s1,t1;
};


struct stbtt_packedchar
{
	unsigned short x0,y0,x1,y1;
	float xoff,yoff,xadvance;
	float xoff2,yoff2;
};

struct stbtt_pack_range
{
	float font_size;
	int first_unicode_codepoint_in_range;
	int *array_of_unicode_codepoints;
	int num_chars;
	stbtt_packedchar *chardata_for_range;
	unsigned char h_oversample, v_oversample;
};

struct stbtt__buf
{
	unsigned char *data;
	int cursor;
	int size;
};

struct stbtt_fontinfo
{
	void           * userdata;
	unsigned char  * data;              // pointer to .ttf file
	int              fontstart;         // offset of start of font

	int numGlyphs;                     // number of glyphs, needed for range checking

	int loca,head,glyf,hhea,hmtx,kern,gpos,svg; // table locations as offset from start of .ttf
	int index_map;                     // a cmap mapping for our chosen character encoding
	int indexToLocFormat;              // format needed to map from glyph index to glyph

	stbtt__buf cff;                    // cff font data
	stbtt__buf charstrings;            // the charstring index
	stbtt__buf gsubrs;                 // global charstring subroutines index
	stbtt__buf subrs;                  // private charstring subroutines index
	stbtt__buf fontdicts;              // array of font dicts
	stbtt__buf fdselect;               // map from glyph to fontdict
};

struct stbtt_pack_context {
	void *user_allocator_context;
	void *pack_info;
	int   width;
	int   height;
	int   stride_in_bytes;
	int   padding;
	int   skip_missing;
	unsigned int   h_oversample, v_oversample;
	unsigned char *pixels;
	void  *nodes;
};

namespace ImStb
{
	// need to forward declare some vars
	static char STB_TEXTEDIT_NEWLINE = '\n';
	
#define STB_TEXTEDIT_K_INSERT 0
#define STB_TEXTEDIT_K_TEXTSTART2 0
#define STB_TEXTEDIT_K_TEXTEND2 0
#define STB_TEXTEDIT_K_LINESTART2 0
#define STB_TEXTEDIT_K_LINEEND2 0

#define STB_TEXTEDIT_K_LEFT         0x200000 // keyboard input to move cursor left
#define STB_TEXTEDIT_K_RIGHT        0x200001 // keyboard input to move cursor right
#define STB_TEXTEDIT_K_UP           0x200002 // keyboard input to move cursor up
#define STB_TEXTEDIT_K_DOWN         0x200003 // keyboard input to move cursor down
#define STB_TEXTEDIT_K_LINESTART    0x200004 // keyboard input to move cursor to start of line
#define STB_TEXTEDIT_K_LINEEND      0x200005 // keyboard input to move cursor to end of line
#define STB_TEXTEDIT_K_TEXTSTART    0x200006 // keyboard input to move cursor to start of text
#define STB_TEXTEDIT_K_TEXTEND      0x200007 // keyboard input to move cursor to end of text
#define STB_TEXTEDIT_K_DELETE       0x200008 // keyboard input to delete selection or character under cursor
#define STB_TEXTEDIT_K_BACKSPACE    0x200009 // keyboard input to delete selection or character left of cursor
#define STB_TEXTEDIT_K_UNDO         0x20000A // keyboard input to perform undo
#define STB_TEXTEDIT_K_REDO         0x20000B // keyboard input to perform redo
#define STB_TEXTEDIT_K_WORDLEFT     0x20000C // keyboard input to move cursor left one word
#define STB_TEXTEDIT_K_WORDRIGHT    0x20000D // keyboard input to move cursor right one word
#define STB_TEXTEDIT_K_PGUP         0x20000E // keyboard input to move cursor up a page
#define STB_TEXTEDIT_K_PGDOWN       0x20000F // keyboard input to move cursor down a page
#define STB_TEXTEDIT_K_SHIFT        0x400000
}

int stbtt_InitFont(stbtt_fontinfo *info, const unsigned char *data, int offset);
int stbtt_FindGlyphIndex(const stbtt_fontinfo *info, int unicode_codepoint);

static bool STB_TEXTEDIT_INSERTCHARS(void* obj, int pos, const char* new_text, int new_text_len);

static bool STB_TEXTEDIT_IS_SPACE(char c); // not actually used, but the type inference gets sad if its not defined.

// END STB SHIM

// BEGIN WIN32 STRUCT SHIM

typedef void* FILE;
typedef void* HANDLE;
typedef HANDLE HWND;
typedef unsigned short WORD;
typedef unsigned int DWORD;
typedef int LONG;
typedef char CHAR;
typedef unsigned short WCHAR;
typedef short SHORT;
typedef unsigned char BYTE;
typedef int                 INT;
typedef unsigned int        UINT;
typedef unsigned int        *PUINT;
typedef int                 BOOL;
typedef unsigned char       UINT8;
typedef float               FLOAT;
typedef DWORD LCID;
typedef DWORD LCTYPE;
typedef CHAR *LPSTR;
typedef WCHAR *LPCWSTR;
typedef __int64 LONGLONG;
typedef __int64 LONG_PTR;
typedef __int64 UINT_PTR;
typedef UINT_PTR            WPARAM;
typedef LONG_PTR            LPARAM;
typedef LONG_PTR            LRESULT;

struct POINT {
	LONG x, y;
};

struct RECT {
	LONG left, top, right, bottom;
};

struct COMPOSITIONFORM {
	DWORD dwStyle;
	POINT ptCurrentPos;
	RECT  rcArea;
};

struct CANDIDATEFORM {
	DWORD dwIndex;
	DWORD dwStyle;
	POINT ptCurrentPos;
	RECT  rcArea;
};

bool OpenClipboard(HWND hWndNewOwner);

#define SORT_DEFAULT 0x0
#define LOCALE_RETURN_NUMBER 0x20000000
#define LOCALE_IDEFAULTANSICODEPAGE 0x00001004

#define CP_ACP 0
#define CP_UTF8 65001

#define TRUE 1
#define FALSE 0

union LARGE_INTEGER {
	struct {
		DWORD LowPart;
		LONG HighPart;
	};
	struct {
		DWORD LowPart;
		LONG HighPart;
	} u;
	LONGLONG QuadPart;
};

int GetLocaleInfoA(LCID Locale, LCTYPE LCType, LPSTR lpLCData, int cchData);

BOOL QueryPerformanceCounter(LARGE_INTEGER *lpPerformanceCount);

BOOL QueryPerformanceFrequency(LARGE_INTEGER *lpFrequency);

#define IDC_ARROW           MAKEINTRESOURCE(32512)
#define IDC_IBEAM           MAKEINTRESOURCE(32513)
#define IDC_WAIT            MAKEINTRESOURCE(32514)
#define IDC_CROSS           MAKEINTRESOURCE(32515)
#define IDC_UPARROW         MAKEINTRESOURCE(32516)
#define IDC_SIZE            MAKEINTRESOURCE(32640)
#define IDC_ICON            MAKEINTRESOURCE(32641)
#define IDC_SIZENWSE        MAKEINTRESOURCE(32642)
#define IDC_SIZENESW        MAKEINTRESOURCE(32643)
#define IDC_SIZEWE          MAKEINTRESOURCE(32644)
#define IDC_SIZENS          MAKEINTRESOURCE(32645)
#define IDC_SIZEALL         MAKEINTRESOURCE(32646)
#define IDC_NO              MAKEINTRESOURCE(32648)
#define IDC_HAND            MAKEINTRESOURCE(32649)

SHORT GetKeyState(int nVirtKey);

#define VK_LSHIFT         0xA0
#define VK_RSHIFT         0xA1
#define VK_LCONTROL       0xA2
#define VK_RCONTROL       0xA3
#define VK_LMENU          0xA4
#define VK_RMENU          0xA5

#define VK_LWIN           0x5B
#define VK_RWIN           0x5C
#define VK_APPS           0x5D

#define VK_SHIFT          0x10
#define VK_CONTROL        0x11
#define VK_MENU           0x12
#define VK_PAUSE          0x13
#define VK_CAPITAL        0x14

#define VK_BACK           0x08
#define VK_TAB            0x09

#define VK_CLEAR          0x0C
#define VK_RETURN         0x0D

#define VK_SPACE          0x20
#define VK_PRIOR          0x21
#define VK_NEXT           0x22
#define VK_END            0x23
#define VK_HOME           0x24
#define VK_LEFT           0x25
#define VK_UP             0x26
#define VK_RIGHT          0x27
#define VK_DOWN           0x28
#define VK_SELECT         0x29
#define VK_PRINT          0x2A
#define VK_EXECUTE        0x2B
#define VK_SNAPSHOT       0x2C
#define VK_INSERT         0x2D
#define VK_DELETE         0x2E
#define VK_HELP           0x2F

#define VK_SHIFT          0x10
#define VK_CONTROL        0x11
#define VK_MENU           0x12
#define VK_PAUSE          0x13
#define VK_CAPITAL        0x14

#define VK_KANA           0x15
#define VK_HANGEUL        0x15
#define VK_HANGUL         0x15
#define VK_IME_ON         0x16
#define VK_JUNJA          0x17
#define VK_FINAL          0x18
#define VK_HANJA          0x19
#define VK_KANJI          0x19
#define VK_IME_OFF        0x1A

#define VK_ESCAPE         0x1B

#define VK_CONVERT        0x1C
#define VK_NONCONVERT     0x1D
#define VK_ACCEPT         0x1E
#define VK_MODECHANGE     0x1F

#define VK_OEM_1          0xBA   // ';:' for US
#define VK_OEM_PLUS       0xBB   // '+' any country
#define VK_OEM_COMMA      0xBC   // ',' any country
#define VK_OEM_MINUS      0xBD   // '-' any country
#define VK_OEM_PERIOD     0xBE   // '.' any country
#define VK_OEM_2          0xBF   // '/?' for US
#define VK_OEM_3          0xC0   // '`~' for US
#define VK_OEM_4          0xDB  //  '[{' for US
#define VK_OEM_5          0xDC  //  '\|' for US
#define VK_OEM_6          0xDD  //  ']}' for US
#define VK_OEM_7          0xDE  //  ''"' for US
#define VK_OEM_8          0xDF

#define VK_NUMLOCK        0x90
#define VK_SCROLL         0x91

#define VK_NUMPAD0        0x60
#define VK_NUMPAD1        0x61
#define VK_NUMPAD2        0x62
#define VK_NUMPAD3        0x63
#define VK_NUMPAD4        0x64
#define VK_NUMPAD5        0x65
#define VK_NUMPAD6        0x66
#define VK_NUMPAD7        0x67
#define VK_NUMPAD8        0x68
#define VK_NUMPAD9        0x69
#define VK_MULTIPLY       0x6A
#define VK_ADD            0x6B
#define VK_SEPARATOR      0x6C
#define VK_SUBTRACT       0x6D
#define VK_DECIMAL        0x6E
#define VK_DIVIDE         0x6F
#define VK_F1             0x70
#define VK_F2             0x71
#define VK_F3             0x72
#define VK_F4             0x73
#define VK_F5             0x74
#define VK_F6             0x75
#define VK_F7             0x76
#define VK_F8             0x77
#define VK_F9             0x78
#define VK_F10            0x79
#define VK_F11            0x7A
#define VK_F12            0x7B
#define VK_F13            0x7C
#define VK_F14            0x7D
#define VK_F15            0x7E
#define VK_F16            0x7F
#define VK_F17            0x80
#define VK_F18            0x81
#define VK_F19            0x82
#define VK_F20            0x83
#define VK_F21            0x84
#define VK_F22            0x85
#define VK_F23            0x86
#define VK_F24            0x87

#define VK_BROWSER_BACK        0xA6
#define VK_BROWSER_FORWARD     0xA7
#define VK_BROWSER_REFRESH     0xA8
#define VK_BROWSER_STOP        0xA9
#define VK_BROWSER_SEARCH      0xAA
#define VK_BROWSER_FAVORITES   0xAB
#define VK_BROWSER_HOME        0xAC


BOOL GetCursorPos(POINT* lpPoint);

BOOL IsChild(HWND hWndParent, HWND hWnd);

#define XINPUT_FLAG_GAMEPAD 0x00000001
#define ERROR_SUCCESS 0L

struct XINPUT_GAMEPAD {
	WORD wButtons;
	BYTE bLeftTrigger;
	BYTE bRightTrigger;
	SHORT sThumbLX;
	SHORT sThumbLY;
	SHORT sThumbRX;
	SHORT sThumbRY;
};

struct XINPUT_STATE {
	DWORD dwPacketNumber;
	XINPUT_GAMEPAD Gamepad;
};

#define XINPUT_GAMEPAD_DPAD_UP          0x0001
#define XINPUT_GAMEPAD_DPAD_DOWN        0x0002
#define XINPUT_GAMEPAD_DPAD_LEFT        0x0004
#define XINPUT_GAMEPAD_DPAD_RIGHT       0x0008
#define XINPUT_GAMEPAD_START            0x0010
#define XINPUT_GAMEPAD_BACK             0x0020
#define XINPUT_GAMEPAD_LEFT_THUMB       0x0040
#define XINPUT_GAMEPAD_RIGHT_THUMB      0x0080
#define XINPUT_GAMEPAD_LEFT_SHOULDER    0x0100
#define XINPUT_GAMEPAD_RIGHT_SHOULDER   0x0200
#define XINPUT_GAMEPAD_A                0x1000
#define XINPUT_GAMEPAD_B                0x2000
#define XINPUT_GAMEPAD_X                0x4000
#define XINPUT_GAMEPAD_Y                0x8000

#define XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE  7849
#define XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE 8689
#define XINPUT_GAMEPAD_TRIGGER_THRESHOLD    30

struct MONITORINFO {
	DWORD cbSize;
	RECT rcMonitor;
	RECT rcWork;
	DWORD dwFlags;
};

typedef void* HMONITOR;

BOOL GetMonitorInfo(HMONITOR hMonitor, MONITORINFO* lpmi);

#define MONITORINFOF_PRIMARY        0x00000001

#define LOWORD(l)           ((WORD)(((DWORD_PTR)(l)) & 0xffff))
#define HIWORD(l)           ((WORD)((((DWORD_PTR)(l)) >> 16) & 0xffff))

#define KF_EXTENDED       0x0100
#define KF_DLGMODE        0x0800
#define KF_MENUMODE       0x1000
#define KF_ALTDOWN        0x2000
#define KF_REPEAT         0x4000
#define KF_UP             0x8000


#define WM_MOUSEFIRST                   0x0200
#define WM_MOUSEMOVE                    0x0200
#define WM_LBUTTONDOWN                  0x0201
#define WM_LBUTTONUP                    0x0202
#define WM_LBUTTONDBLCLK                0x0203
#define WM_RBUTTONDOWN                  0x0204
#define WM_RBUTTONUP                    0x0205
#define WM_RBUTTONDBLCLK                0x0206
#define WM_MBUTTONDOWN                  0x0207
#define WM_MBUTTONUP                    0x0208
#define WM_MBUTTONDBLCLK                0x0209
#define WM_MOUSEWHEEL                   0x020A
#define WM_NCMOUSEMOVE                  0x00A0
#define WM_MOUSELEAVE                   0x02A3
#define WM_NCMOUSELEAVE                 0x02A2
#define WM_DESTROY                      0x0002
#define WM_XBUTTONDOWN                  0x020B
#define WM_XBUTTONUP                    0x020C
#define WM_XBUTTONDBLCLK                0x020D
#define WM_KEYDOWN                      0x0100
#define WM_KEYUP                        0x0101
#define WM_SYSKEYDOWN                   0x0104
#define WM_SYSKEYUP                     0x0105
#define WM_SETFOCUS                     0x0007
#define WM_KILLFOCUS                    0x0008
#define WM_INPUTLANGCHANGEREQUEST       0x0050
#define WM_INPUTLANGCHANGE              0x0051
#define WM_CHAR                         0x0102
#define WM_SETCURSOR                    0x0020
#define WM_DEVICECHANGE                 0x0219
#define WM_DISPLAYCHANGE                0x007E
#define WM_MOUSEACTIVATE                0x0021
#define WM_MOVE                         0x0003
#define WM_CLOSE                        0x0010
#define WM_SIZE                         0x0005
#define WM_NCHITTEST                    0x0084

#define HTTRANSPARENT       (-1)

#define XBUTTON1      0x0001
#define XBUTTON2      0x0002

#define WHEEL_DELTA                     120
#define GET_WHEEL_DELTA_WPARAM(wParam)  ((short)HIWORD(wParam))

#define TME_CANCEL      0x80000000
#define TME_LEAVE       0x00000002
#define TME_NONCLIENT   0x00000010

#define GET_X_LPARAM(lp)                        ((int)(short)LOWORD(lp))
#define GET_Y_LPARAM(lp)                        ((int)(short)HIWORD(lp))

BOOL IsWindowUnicode(HWND hWnd);

#define MB_PRECOMPOSED            0x00000001

#define HTCLIENT            1

struct RTL_OSVERSIONINFOEXW {
	DWORD dwOSVersionInfoSize;
	DWORD dwMajorVersion;
	DWORD dwMinorVersion;
	DWORD dwBuildNumber;
	DWORD dwPlatformId;
	WCHAR szCSDVersion[128];
	WORD wServicePackMajor;
	WORD wServicePackMinor;
	WORD wSuiteMask;
	BYTE wProductType;
	BYTE wReserved;
};

#define VER_MINORVERSION                0x0000001
#define VER_MAJORVERSION                0x0000002
#define VER_GREATER_EQUAL               3

#define VER_SET_CONDITION(_m_,_t_,_c_)  ((_m_)=VerSetConditionMask((_m_),(_t_),(_c_)))

struct DPI_AWARENESS_CONTEXT;

#define LOGPIXELSX    88
#define LOGPIXELSY    90

#define MONITOR_DEFAULTTONULL       0x00000000
#define MONITOR_DEFAULTTOPRIMARY    0x00000001
#define MONITOR_DEFAULTTONEAREST    0x00000002

HMONITOR MonitorFromWindow(HWND hwnd, DWORD dwFlags);

#define FAILED(hr) (((HRESULT)(hr)) < 0)
#define SUCCEEDED(hr) (((HRESULT)(hr)) >= 0)

#define DWM_BB_ENABLE                 0x00000001
#define DWM_BB_BLURREGION             0x00000002
#define DWM_BB_TRANSITIONONMAXIMIZED  0x00000004

struct HRGN {};

struct DWM_BLURBEHIND {
	DWORD dwFlags;
	BOOL fEnable;
	HRGN hRgnBlur;
	BOOL fTransitionOnMaximized;
};

#define WS_POPUP            0x80000000L
#define WS_OVERLAPPED       0x00000000L
#define WS_EX_TOPMOST           0x00000008L
#define WS_EX_TOOLWINDOW        0x00000080L
#define WS_EX_APPWINDOW         0x00040000L
#define WS_EX_LAYERED           0x00080000

#define WS_OVERLAPPEDWINDOW 0xfffff // w/e

#define GWLP_HWNDPARENT     (-8)

LONG_PTR SetWindowLongPtrA(HWND hWnd, int nIndex, LONG_PTR dwNewLong);

#define SW_SHOWNA           8
#define SW_SHOW             5

#define HWND_TOPMOST    ((HWND)-1)
#define HWND_NOTOPMOST  ((HWND)-2)

#define GWL_STYLE           (-16)
#define GWL_EXSTYLE         (-20)

#define SWP_NOSIZE          0x0001
#define SWP_NOMOVE          0x0002
#define SWP_NOZORDER        0x0004
#define SWP_NOACTIVATE      0x0010
#define SWP_FRAMECHANGED    0x0020

#define LWA_ALPHA             0x00000002

LRESULT DefWindowProc(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);

BOOL IsIconic(HWND hWnd);

#define MA_NOACTIVATE       3

typedef LRESULT (*WNDPROC)(HWND, UINT, WPARAM, LPARAM);

typedef HANDLE HINSTANCE;
typedef HANDLE HICON;
typedef HANDLE HCURSOR;
typedef HANDLE HBRUSH;

struct WNDCLASSEXW {
    UINT        cbSize;
    /* Win 3.x */
    UINT        style;
    WNDPROC     lpfnWndProc;
    int         cbClsExtra;
    int         cbWndExtra;
    HINSTANCE   hInstance;
    HICON       hIcon;
    HCURSOR     hCursor;
    HBRUSH      hbrBackground;
    LPCWSTR     lpszMenuName;
    LPCWSTR     lpszClassName;
    /* Win 4.0 */
    HICON       hIconSm;
};

#define CS_VREDRAW          0x0001
#define CS_HREDRAW          0x0002
#define CS_OWNDC            0x0020

#define COLOR_BACKGROUND        1

// END WIN32 STRUCT SHIM
