#+build windows
package winternal

import win32 "core:sys/windows"

NT_TIB :: struct {
	ExceptionList        : win32.PVOID,
	StackBase            : win32.PVOID,
	StackLimit           : win32.PVOID,
	SubSystemTib         : win32.PVOID,
	using _ : struct #raw_union {
			FiberData        : win32.PVOID,
			Version          : win32.DWORD,
	},
	ArbitraryUserPointer : win32.PVOID,
	Self                 : ^NT_TIB,
}

TEB :: struct {
	using _ : struct #raw_union {
		Tib                   :       NT_TIB,
		_                     :   [12]win32.PVOID,
	},
	ProcessEnvironmentBlock :      ^win32.PEB,
	_                       :  [399]win32.PVOID,
	_                       : [1952]win32.BYTE,
	TlsSlots                :   [64]win32.PVOID,
	_                       :    [8]win32.BYTE,
	_                       :   [26]win32.PVOID,
	_                       :       win32.PVOID,
	_                       :    [4]win32.PVOID,
	TlsExpansionSlots       :       win32.PVOID,
}

