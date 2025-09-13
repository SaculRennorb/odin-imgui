#+build windows
package win

import win32 "core:sys/windows"

foreign import lib "system:Kernel32.lib"

MB_PRECOMPOSED :: 0x00000001

LOCALE_RETURN_NUMBER        :: 0x20000000   // return number instead of string
LOCALE_IDEFAULTANSICODEPAGE :: 0x00001004 

@(default_calling_convention="c")
foreign lib {
	VerSetConditionMask :: proc(ConditionMask : win32.ULONGLONG, TypeMask : win32.DWORD, Condition : win32.BYTE) -> win32.ULONGLONG ---
	GetLocaleInfoA :: proc(Locale : win32.LCID, LCType : win32.LCTYPE, lpLCData : win32.LPSTR, cchData : i32) -> i32 ---
}
