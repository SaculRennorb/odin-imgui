package imgui

//-----------------------------------------------------------------------------
// [SECTION] PLATFORM DEPENDENT HELPERS
//-----------------------------------------------------------------------------
// - Default clipboard handlers
// - Default shell function handlers
// - Default IME handlers
//-----------------------------------------------------------------------------

import win32 "core:sys/windows"
import win32 "core:sys/windows"
import "core:mem"

L :: win32.L

when !IMGUI_DISABLE_DEFAULT_SHELL_FUNCTIONS {

	Platform_OpenInShellFn_DefaultImpl :: proc(_ : ^ImGuiContext, path : string) -> bool
	{
		wlen := win32.MultiByteToWideChar(win32.CP_UTF8, 0, raw_data(path), cast(i32) len(path), nil, 0)
		
		wmem, _ := mem.alloc_bytes_non_zeroed(cast(int) wlen * 2, 2, context.temp_allocator)
		win32.MultiByteToWideChar(win32.CP_UTF8, 0, raw_data(path), cast(i32) len(path), cast([^]win32.WCHAR) raw_data(wmem), wlen)

		return cast(uintptr)win32.ShellExecuteW(nil, L("open"), cast([^]win32.WCHAR) raw_data(wmem), nil, nil, win32.SW_SHOWDEFAULT) > 32;
	}

}

//-----------------------------------------------------------------------------

when !IMGUI_DISABLE_WIN32_DEFAULT_CLIPBOARD_FUNCTIONS {

	// Win32 clipboard implementation
	// We use g.ClipboardHandlerData for temporary storage to ensure it is freed on Shutdown()
	Platform_GetClipboardTextFn_DefaultImpl :: proc(ctx : ^ImGuiContext) -> [^]u8
	{
			g := ctx;
			clear(&g.ClipboardHandlerData)
			if (!win32.OpenClipboard(nil))   do return nil
			wbuf_handle := transmute(win32.HGLOBAL) win32.GetClipboardData(win32.CF_UNICODETEXT);
			if (wbuf_handle == nil)
			{
					win32.CloseClipboard();
					return nil;
			}
			if wbuf_global := cast(^win32.WCHAR)win32.GlobalLock(wbuf_handle); wbuf_global != nil
			{
					buf_len := win32.WideCharToMultiByte(win32.CP_UTF8, 0, wbuf_global, -1, nil, 0, nil, nil);
					resize(&g.ClipboardHandlerData, buf_len);
					win32.WideCharToMultiByte(win32.CP_UTF8, 0, wbuf_global, -1, raw_data(g.ClipboardHandlerData), buf_len, nil, nil);
			}
			win32.GlobalUnlock(wbuf_handle);
			win32.CloseClipboard();
			return raw_data(g.ClipboardHandlerData);
	}

	Platform_SetClipboardTextFn_DefaultImpl :: proc(_ : ^ImGuiContext, text : ^u8)
	{
			if (!win32.OpenClipboard(nil))   do return
			wbuf_length := win32.MultiByteToWideChar(win32.CP_UTF8, 0, text, -1, nil, 0);
			wbuf_handle := transmute(win32.HGLOBAL) win32.GlobalAlloc(win32.GMEM_MOVEABLE, cast(win32.SIZE_T)wbuf_length * size_of(win32.WCHAR));
			if (wbuf_handle == nil)
			{
					win32.CloseClipboard();
					return;
			}
			wbuf_global := cast(^win32.WCHAR)win32.GlobalLock(wbuf_handle);
			win32.MultiByteToWideChar(win32.CP_UTF8, 0, text, -1, wbuf_global, wbuf_length);
			win32.GlobalUnlock(wbuf_handle);
			win32.EmptyClipboard();
			if (win32.SetClipboardData(win32.CF_UNICODETEXT, transmute(win32.HANDLE) wbuf_handle) == nil)   do win32.GlobalFree(wbuf_handle)
			win32.CloseClipboard();
	}

}

//-----------------------------------------------------------------------------

// Win32 API IME support (for Asian languages, etc.)
when !IMGUI_DISABLE_WIN32_FUNCTIONS && !IMGUI_DISABLE_WIN32_DEFAULT_IME_FUNCTIONS {

	HIMC :: distinct win32.HANDLE

	CFS_FORCE_POSITION : win32.DWORD : 32
	CFS_CANDIDATEPOS : win32.DWORD : 64

	COMPOSITIONFORM :: struct {
		dwStyle : win32.DWORD,
		ptCurrentPos : win32.POINT,
		rcArea : win32.RECT,
	}

	CANDIDATEFORM :: struct {
		dwIndex : win32.DWORD,
		dwStyle : win32.DWORD,
		ptCurrentPos : win32.POINT,
		rcArea : win32.RECT,
	}

	foreign import imm "system:imm32.lib"

	@(default_calling_convention="system")
	foreign imm {
		ImmGetContext :: proc(param1 : win32.HWND) -> HIMC ---
		ImmSetCompositionWindow :: proc(param1 : HIMC, comp_form : ^COMPOSITIONFORM) -> win32.BOOL ---
		ImmSetCandidateWindow :: proc(param1 : HIMC, candidate : ^CANDIDATEFORM) -> win32.BOOL ---
		ImmReleaseContext :: proc(param1 : win32.HWND, param2 : HIMC) -> win32.BOOL ---
	}

	Platform_SetImeDataFn_DefaultImpl :: proc(_ : ^ImGuiContext, viewport : ^ImGuiViewport, data : ^ImGuiPlatformImeData)
	{
			// Notify OS Input Method Editor of text input position
			hwnd := cast(win32.HWND)viewport.PlatformHandleRaw;
			if (hwnd == nil)   do return

			//::ImmAssociateContextEx(hwnd, NULL, data.WantVisible ? IACE_DEFAULT : 0);
			if himc : HIMC = ImmGetContext(hwnd); himc != {}
			{
					composition_form : COMPOSITIONFORM
					composition_form.ptCurrentPos.x = (win32.LONG)(data.InputPos.x - viewport.Pos.x);
					composition_form.ptCurrentPos.y = (win32.LONG)(data.InputPos.y - viewport.Pos.y);
					composition_form.dwStyle = CFS_FORCE_POSITION;
					ImmSetCompositionWindow(himc, &composition_form);
					candidate_form : CANDIDATEFORM
					candidate_form.dwStyle = CFS_CANDIDATEPOS;
					candidate_form.ptCurrentPos.x = (win32.LONG)(data.InputPos.x - viewport.Pos.x);
					candidate_form.ptCurrentPos.y = (win32.LONG)(data.InputPos.y - viewport.Pos.y);
					ImmSetCandidateWindow(himc, &candidate_form);
					ImmReleaseContext(hwnd, himc);
			}
	}

}

