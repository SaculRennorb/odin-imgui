#+build windows
package win

import win32 "core:sys/windows"

RTL_OSVERSIONINFOEXW :: win32.OSVERSIONINFOEXW

VER_MINORVERSION     :: 0x0000001
VER_MAJORVERSION     :: 0x0000002
VER_BUILDNUMBER      :: 0x0000004
VER_PLATFORMID       :: 0x0000008
VER_SERVICEPACKMINOR :: 0x0000010
VER_SERVICEPACKMAJOR :: 0x0000020
VER_SUITENAME        :: 0x0000040
VER_PRODUCT_TYPE     :: 0x0000080

VER_EQUAL         :: 1
VER_GREATER       :: 2
VER_GREATER_EQUAL :: 3
VER_LESS          :: 4
VER_LESS_EQUAL    :: 5
VER_AND           :: 6
VER_OR            :: 7

SORT_DEFAULT :: 0x0

VER_SET_CONDITION :: proc "contextless" (m : ^win32.ULONGLONG, t : win32.DWORD, c : win32.BYTE) {
	m^ = VerSetConditionMask(m^, t, c)
}
