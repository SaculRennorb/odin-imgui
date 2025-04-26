package test

defined :: #force_inline proc "contextless" ($I) -> bool { I }

 pre_decr :: #force_inline proc "contextless" (p : ^$T) -> (new : T) { p^ -= 1; return p }
 pre_incr :: #force_inline proc "contextless" (p : ^$T) -> (new : T) { p^ += 1; return p }
post_decr :: #force_inline proc "contextless" (p : ^$T) -> (old : T) { old = p; p^ -= 1; return }
post_incr :: #force_inline proc "contextless" (p : ^$T) -> (old : T) { old = p; p^ += 1; return }

init :: proc {ImVec2_init, ImVec4_init, ImGuiTableSortSpecs_init, ImGuiTableColumnSortSpecs_init, ImVector_init, ImGuiWindowClass_init, ImGuiPayload_init, ImGuiOnceUponAFrame_init, ImGuiTextFilter_ImGuiTextRange_init, ImGuiTextBuffer_init, ImGuiStoragePair_init, ImColor_init, ImDrawCmd_init, ImDrawListSplitter_init, ImDrawData_init, ImFontGlyphRangesBuilder_init, ImFontAtlasCustomRect_init, ImGuiViewport_init, ImGuiPlatformMonitor_init, ImGuiPlatformImeData_init}

deinit :: proc {ImVector_deinit, ImDrawListSplitter_deinit, ImGuiViewport_deinit}
