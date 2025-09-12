#+build windows
package shell

import win32 "core:sys/windows"

foreign import shell32 "system:Shell32.lib"

@(default_calling_convention="system")
foreign shell32 {
	ShellExecuteA :: proc(
		hwnd         : win32.HWND,
		lpOperation  : win32.LPCSTR,
		lpFile       : win32.LPCSTR,
		lpParameters : win32.LPCSTR,
		lpDirectory  : win32.LPCSTR,
		nShowCmd     : win32.INT,
	) -> win32.HINSTANCE ---
}