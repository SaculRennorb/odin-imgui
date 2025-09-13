#+build windows
package win

import win32 "core:sys/windows"

foreign import lib "system:Gdi32.lib"

LOGPIXELSX :: 88    /* Logical pixels/inch in X                 */
LOGPIXELSY :: 90    /* Logical pixels/inch in Y                 */

@(default_calling_convention="c")
foreign lib {
	CreateRectRgn :: proc(x1 : i32, y1 : i32, x2 : i32, y2 : i32) -> win32.HRGN ---
}
