#+build windows
package winternal

import win32 "core:sys/windows"

foreign import lib "system:Imm32.lib"

HIMC :: distinct win32.DWORD
HIMCC :: distinct win32.DWORD

COMPOSITIONFORM :: struct {
	dwStyle      : win32.DWORD,
	ptCurrentPos : win32.POINT,
	rcArea       : win32.RECT,
}

LPCOMPOSITIONFORM :: ^COMPOSITIONFORM

CANDIDATEFORM :: struct {
	dwIndex      : win32.DWORD,
	dwStyle      : win32.DWORD,
	ptCurrentPos : win32.POINT,
	rcArea       : win32.RECT,
}

LPCANDIDATEFORM :: ^CANDIDATEFORM

CFS_DEFAULT                     :: 0x0000
CFS_RECT                        :: 0x0001
CFS_POINT                       :: 0x0002
CFS_FORCE_POSITION              :: 0x0020
CFS_CANDIDATEPOS                :: 0x0040
CFS_EXCLUDE                     :: 0x0080

@(default_calling_convention="c")
foreign lib {
	ImmGetContext :: proc(param1 : win32.HWND) -> HIMC ---
	ImmSetCompositionWindow :: proc(_ : HIMC, lpCompForm : LPCOMPOSITIONFORM) -> win32.BOOL --- 
	ImmSetCandidateWindow :: proc(_ : HIMC, lpCandidate : LPCANDIDATEFORM) -> win32.BOOL --- 
	ImmReleaseContext :: proc(_ : win32.HWND, _ : HIMC) -> win32.BOOL --- 
}