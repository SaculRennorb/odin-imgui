#+build windows
package winternal

import win32 "core:sys/windows"

foreign import lib "system:DbgHelp.lib"

ADDRESS64 :: struct {
  Offset  : win32.DWORD64     ,
  Segment : win32.WORD        ,
  Mode    : win32.ADDRESS_MODE,
}

KDHELP64 :: struct {
  Thread                          :    win32.DWORD64,
  ThCallbackStack                 :    win32.DWORD,
  ThCallbackBStore                :    win32.DWORD,
  NextCallback                    :    win32.DWORD,
  FramePointer                    :    win32.DWORD,
  KiCallUserMode                  :    win32.DWORD64,
  KeUserCallbackDispatcher        :    win32.DWORD64,
  SystemRangeStart                :    win32.DWORD64,
  KiUserExceptionDispatcher       :    win32.DWORD64,
  StackBase                       :    win32.DWORD64,
  StackLimit                      :    win32.DWORD64,
  BuildVersion                    :    win32.DWORD,
  RetpolineStubFunctionTableSize  :    win32.DWORD,
  RetpolineStubFunctionTable      :    win32.DWORD64,
  RetpolineStubOffset             :    win32.DWORD,
  RetpolineStubSize               :    win32.DWORD,
  Reserved0                       : [2]win32.DWORD64,
}

STACKFRAME64 :: struct {
  AddrPC         :    ADDRESS64,
  AddrReturn     :    ADDRESS64,
  AddrFrame      :    ADDRESS64,
  AddrStack      :    ADDRESS64,
  AddrBStore     :    ADDRESS64,
  FuncTableEntry :    win32.PVOID,
  Params         : [4]win32.DWORD64,
  Far            :    win32.BOOL,
  Virtual        :    win32.BOOL,
  Reserved       : [3]win32.DWORD64,
  KdHelp         :    KDHELP64,
}

PREAD_PROCESS_MEMORY_ROUTINE64 :: proc "c" (
  hProcess            : win32.HANDLE,
  lpBaseAddress       : win32.DWORD64,
  lpBuffer            : win32.PVOID,
  nSize               : win32.DWORD,
  lpNumberOfBytesRead : win32.PDWORD,
) -> win32.BOOL

PFUNCTION_TABLE_ACCESS_ROUTINE64 :: proc "c" (
  hProcess : win32.HANDLE,
  AddrBase : win32.DWORD64,
) -> win32.PVOID

PGET_MODULE_BASE_ROUTINE64 :: proc "c" (
  hProcess : win32.HANDLE,
  Address  : win32.DWORD64,
) -> win32.DWORD64

PTRANSLATE_ADDRESS_ROUTINE64 :: proc "c" (
  hProcess : win32.HANDLE,
  hThread  : win32.HANDLE,
  lpaddr   : ^ADDRESS64,
) -> win32.DWORD64

IMAGEHLP_SYMBOL64 :: struct {
  SizeOfStruct  :    win32.DWORD,
  Address       :    win32.DWORD64,
  Size          :    win32.DWORD,
  Flags         :    win32.DWORD,
  MaxNameLength :    win32.DWORD,
  Name          : [1]win32.CHAR,
}


IMAGE_FILE_MACHINE_I386 :: 0x014c
IMAGE_FILE_MACHINE_AMD64 :: 0x8664
IMAGE_FILE_MACHINE_ARM :: 0x01c0
IMAGE_FILE_MACHINE_THUMB :: 0x01c2
IMAGE_FILE_MACHINE_ARM64 :: 0xAA64

// https://learn.microsoft.com/en-us/windows/win32/api/dbghelp/nf-dbghelp-undecoratesymbolname
UNDNAME_COMPLETE :: 0x0000
 

@(default_calling_convention="c")
foreign lib {
	StackWalk64 :: proc(
		MachineType                : win32.DWORD,
		hProcess                   : win32.HANDLE,
		hThread                    : win32.HANDLE,
		StackFrame                 : ^STACKFRAME64,
		ContextRecord              : win32.PVOID,
		ReadMemoryRoutine          : PREAD_PROCESS_MEMORY_ROUTINE64,
		FunctionTableAccessRoutine : PFUNCTION_TABLE_ACCESS_ROUTINE64,
		GetModuleBaseRoutine       : PGET_MODULE_BASE_ROUTINE64,
		TranslateAddress           : PTRANSLATE_ADDRESS_ROUTINE64,
	) -> win32.BOOL ---

	SymGetModuleBase64 :: proc (
		hProcess : win32.HANDLE,
		qwAddr : win32.DWORD64,
	) -> win32.DWORD64 ---

	SymFunctionTableAccess64 :: proc(
		hProcess : win32.HANDLE,
		AddrBase : win32.DWORD64,
	) -> win32.PVOID ---

	SymGetSymFromAddr64 :: proc(
		hProcess        :  win32.HANDLE,
		qwAddr          :  win32.DWORD64,
		pdwDisplacement :  win32.PDWORD64,
		Symbol          : ^IMAGEHLP_SYMBOL64,
	) -> win32.BOOL ---

	UnDecorateSymbolName :: proc(
		name            : win32.PCSTR,
		outputString    : win32.LPSTR,
		maxStringLength : win32.DWORD,
		flags           : win32.DWORD,
	) -> win32.DWORD --- 
}