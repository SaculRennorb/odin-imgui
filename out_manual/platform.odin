package imgui

//TODO(Rennorb): All of this is untested

//-----------------------------------------------------------------------------
// [SECTION] PLATFORM DEPENDENT HELPERS
//-----------------------------------------------------------------------------
// - Default clipboard handlers
// - Default shell function handlers
// - Default IME handlers
//-----------------------------------------------------------------------------

when !IMGUI_DISABLE_DEFAULT_SHELL_FUNCTIONS {

	when ODIN_OS != .Windows {

		Platform_OpenInShellFn_DefaultImpl :: proc(_ : ^ImGuiContext, path : ^u8) -> bool
		{
			when ODIN_OS == .Darwin {
				args := [?]string { "open", "--", path, nil };
			} else {
				args := [?]string { "xdg-open", path, nil };
			}
			pid := fork();
			if (pid < 0)   do return false
			if (!pid)
			{
				execvp(args[0], cast(^^u)(args));
				exit(-1);
			}
			else
			{
				status : i32
				waitpid(pid, &status, 0);
				return WEXITSTATUS(status) == 0;
			}
		}

	}

}
else { // IMGUI_DISABLE_DEFAULT_SHELL_FUNCTIONS

	Platform_OpenInShellFn_DefaultImpl :: proc(_ : ^ImGuiContext, path : ^u8) -> bool { return false }

}

//-----------------------------------------------------------------------------

when !(ODIN_OS == .Windows && !IMGUI_DISABLE_WIN32_DEFAULT_CLIPBOARD_FUNCTIONS) \
    && !(ODIN_OS == .Darwin && IMGUI_ENABLE_OSX_DEFAULT_CLIPBOARD_FUNCTIONS) {

	// Local Dear ImGui-only clipboard implementation, if user hasn't defined better clipboard handlers.
	Platform_GetClipboardTextFn_DefaultImpl :: proc(ctx : ^ImGuiContext) -> ^u8
	{
		g := ctx;
		return g.ClipboardHandlerData.empty() ? nil : g.ClipboardHandlerData.begin();
	}

	Platform_SetClipboardTextFn_DefaultImpl :: proc(ctx : ^ImGuiContext, text : ^u8)
	{
		g := ctx;
		g.ClipboardHandlerData.clear();
		text_end := text + strlen(text);
		g.ClipboardHandlerData.resize((i32)(text_end - text) + 1);
		memcpy(&g.ClipboardHandlerData[0], text, (int)(text_end - text));
		g.ClipboardHandlerData[(i32)(text_end - text)] = 0;
	}

}

//-----------------------------------------------------------------------------

// Win32 API IME support (for Asian languages, etc.)
when ODIN_OS != .Windows || IMGUI_DISABLE_WIN32_FUNCTIONS || IMGUI_DISABLE_WIN32_DEFAULT_IME_FUNCTIONS {

	Platform_SetImeDataFn_DefaultImpl :: proc(_ : ^ImGuiContext, _ : ^ImGuiViewport, _ : ^ImGuiPlatformImeData) {}

}
