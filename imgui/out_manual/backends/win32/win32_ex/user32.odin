#+build windows
package win

import win32 "core:sys/windows"

foreign import lib "system:User32.lib"

LWA_COLORKEY :: 0x00000001
LWA_ALPHA    :: 0x00000002

MA_ACTIVATE         :: 1
MA_ACTIVATEANDEAT   :: 2
MA_NOACTIVATE       :: 3
MA_NOACTIVATEANDEAT :: 4

HKL :: distinct win32.HANDLE

@(default_calling_convention="c")
foreign lib {
	GetMessageExtraInfo :: proc() -> win32.LPARAM ---
	IsWindowUnicode :: proc(hWnd : win32.HWND) -> win32.BOOL ---
	GetKeyboardLayout :: proc(idThread : win32.DWORD) -> HKL ---
	WindowFromPoint :: proc(Point : win32.POINT) -> win32.HWND ---
}