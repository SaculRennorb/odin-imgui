#+build windows
package win

import win32 "core:sys/windows"

foreign import lib "system:Dwmapi.lib"

DWM_BB :: bit_set[DWM_BB_bits; win32.DWORD]

DWM_BB_bits :: enum {
    ENABLE                = 1,  // fEnable has been specified
    BLURREGION            = 2,  // hRgnBlur has been specified
    TRANSITIONONMAXIMIZED = 3,  // fTransitionOnMaximized has been specified
}

DWM_BLURBEHIND :: struct {
    dwFlags : DWM_BB,
    fEnable : win32.BOOL,
    hRgnBlur : win32.HRGN,
    fTransitionOnMaximized : win32.BOOL,
}

PDWM_BLURBEHIND :: ^DWM_BLURBEHIND

@(default_calling_convention="c")
foreign lib {
    DwmEnableBlurBehindWindow :: proc(hWnd : win32.HWND, pBlurBehind : ^DWM_BLURBEHIND) -> win32.HRESULT ---
    DwmGetColorizationColor :: proc(pcrColorization : ^win32.DWORD, pfOpaqueBlend : ^win32.BOOL) -> win32.HRESULT ---
}
