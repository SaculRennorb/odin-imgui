package test

 pre_decr :: #force_inline proc "contextless" (p : ^$T) -> (new : T) { p^ -= 1; return p }
 pre_incr :: #force_inline proc "contextless" (p : ^$T) -> (new : T) { p^ += 1; return p }
post_decr :: #force_inline proc "contextless" (p : ^$T) -> (old : T) { old = p; p^ -= 1; return }
post_incr :: #force_inline proc "contextless" (p : ^$T) -> (old : T) { old = p; p^ += 1; return }

va_arg :: #force_inline proc(args : ^[]any, $T : typeid) -> (r : T) { r = (cast(T^) args[0])^; args^ = args[1:] }


erase :: proc { ImVector_erase_0, ImVector_erase_1 }

Remove :: proc { ImPool_Remove_0, ImPool_Remove_1 }

find :: proc { ImVector_find_0, ImVector_find_1 }

set :: proc { ImSpan_set_0, ImSpan_set_1 }

AddText :: proc { ImDrawList_AddText_0, ImDrawList_AddText_1 }

Contains :: proc { ImRect_Contains_0, ImRect_Contains_1 }

front :: proc { ImVector_front_0, ImVector_front_1 }

resize :: proc { ImVector_resize_0, ImVector_resize_1 }

back :: proc { ImVector_back_0, ImVector_back_1 }

init :: proc { ImVec2_init_0, ImVec2_init_1, ImVec4_init_0, ImVec4_init_1, ImVector_init_0, ImVector_init_1, ImGuiTextFilter_ImGuiTextRange_init_0, ImGuiTextFilter_ImGuiTextRange_init_1, ImGuiStoragePair_init_0, ImGuiStoragePair_init_1, ImGuiStoragePair_init_2, ImColor_init_0, ImColor_init_1, ImColor_init_2, ImColor_init_3, ImColor_init_4, ImVec1_init_0, ImVec1_init_1, ImVec2ih_init_0, ImVec2ih_init_1, ImVec2ih_init_2, ImRect_init_0, ImRect_init_1, ImRect_init_2, ImRect_init_3, ImSpan_init_0, ImSpan_init_1, ImSpan_init_2, ImGuiStyleMod_init_0, ImGuiStyleMod_init_1, ImGuiStyleMod_init_2, ImGuiPtrOrIndex_init_0, ImGuiPtrOrIndex_init_1 }

Add :: proc { ImRect_Add_0, ImRect_Add_1 }

GetID :: proc { ImGuiWindow_GetID_0, ImGuiWindow_GetID_1, ImGuiWindow_GetID_2 }

deinit :: proc { ImVector_deinit, ImDrawListSplitter_deinit, ImGuiViewport_deinit, ImPool_deinit, ImGuiViewportP_deinit, ImGuiTable_deinit }

Expand :: proc { ImRect_Expand_0, ImRect_Expand_1 }
