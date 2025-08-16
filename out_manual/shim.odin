package test

import "core:mem"
import "base:intrinsics"

pre_decr :: proc { pre_decr_m, pre_decr_r }
pre_decr_m :: #force_inline proc "contextless" (p : ^[^]$T) -> (new : ^T) {
	p^ = p^[-1:]; return p^
}
pre_decr_r :: #force_inline proc "contextless" (p : ^$T) -> (new : T) where !intrinsics.type_is_multi_pointer(T) {
	when intrinsics.type_is_pointer(T) { p^ = mem.ptr_sub(p^, 1) } else { p^ -= 1 }; return p^
}

pre_incr :: proc { pre_incr_m, pre_incr_r }
pre_incr_m :: #force_inline proc "contextless" (p : ^[^]$T) -> (new : ^T) {
	p^ = p^[1:]; return p^
}
pre_incr_r :: #force_inline proc "contextless" (p : ^$T) -> (new : T) where !intrinsics.type_is_multi_pointer(T) {
	when intrinsics.type_is_pointer(T) { p^ = mem.ptr_offset(p^, 1) } else { p^ += 1 }; return p^
}

post_decr :: proc { post_decr_m, post_decr_r }
post_decr_m :: #force_inline proc "contextless" (p : ^[^]$T) -> (old : ^T) {
	old = p^; p^ = p^[-1:]; return p^
}
post_decr_r :: #force_inline proc "contextless" (p : ^$T) -> (old : T) where !intrinsics.type_is_multi_pointer(T) {
	old = p^; when intrinsics.type_is_pointer(T) { p^ = mem.ptr_sub(p^, 1) } else { p^ -= 1 }; return
}

post_incr :: proc { post_incr_m, post_incr_r }
post_incr_m :: #force_inline proc "contextless" (p : ^[^]$T) -> (old : ^T) {
	old = p^; p^ = p^[1:]; return p^
}
post_incr_r :: #force_inline proc "contextless" (p : ^$T) -> (old : T) where !intrinsics.type_is_multi_pointer(T) {
	old = p^; when intrinsics.type_is_pointer(T) { p^ = mem.ptr_offset(p^, 1) } else { p^ += 1 }; return
}

va_arg :: #force_inline proc(args : ^[]any, $T : typeid) -> (r : T) { r = (cast(T^) args[0])^; args^ = args[1:] }

ptr_to_first :: proc { ptr_to_first_slice, ptr_to_first_se }

ptr_to_first_slice :: proc(slice : []$T, needle : T) -> (el : ^T, found : bool)
{
	for &e in slice {
		if e == needle { return e, true }
	}
	return nil, false
}

ptr_to_first_se :: proc(start, end : ^$T, needle : T) -> (el : ^T, found : bool)
{
	for e := start; e < end; e = mem.ptr_offset(e, 1) {
		if e^ == needle { return e, true }
	}
	return nil, false
}

erase :: proc { ImVector_erase_0, ImVector_erase_1 }

Remove :: proc { ImPool_Remove_0, ImPool_Remove_1 }

find :: proc { ImVector_find_0, ImVector_find_1 }

set :: proc { ImSpan_set_0, ImSpan_set_1 }

AddText :: proc { ImDrawList_AddText_0, ImDrawList_AddText_1 }

Contains :: proc { ImRect_Contains_0, ImRect_Contains_1 }

front :: proc { ImVector_front }

resize :: proc { ImVector_resize_0, ImVector_resize_1 }

back :: proc { ImVector_back }

init :: proc { ImVector_init_0, ImVector_init_1, ImGuiTextFilter_ImGuiTextRange_init_0, ImGuiTextFilter_ImGuiTextRange_init_1, ImGuiStoragePair_init_0, ImGuiStoragePair_init_1, ImGuiStoragePair_init_2, ImColor_init_1, ImColor_init_2, ImColor_init_3, ImColor_init_4, ImRect_init_1, ImRect_init_2, ImRect_init_3, ImSpan_init_0, ImSpan_init_1, ImSpan_init_2, ImGuiStyleMod_init_0, ImGuiStyleMod_init_1, ImGuiStyleMod_init_2, ImGuiPtrOrIndex_init_0, ImGuiPtrOrIndex_init_1 }

Add :: proc { ImRect_Add_0, ImRect_Add_1 }

GetID :: proc { ImGuiWindow_GetID_0, ImGuiWindow_GetID_1, ImGuiWindow_GetID_2 }

deinit :: proc { ImVector_deinit, ImDrawListSplitter_deinit, ImGuiViewport_deinit, ImPool_deinit, ImGuiViewportP_deinit, ImGuiTable_deinit, ImDrawList_deinit }

Expand :: proc { ImRect_Expand_0, ImRect_Expand_1 }

TableGetColumnName :: proc { TableGetColumnName_n, TableGetColumnName_tn }

TableGcCompactTransientBuffers :: proc { TableGcCompactTransientBuffers_tab, TableGcCompactTransientBuffers_tmp }

CheckboxFlags :: proc { CheckboxFlags_i, CheckboxFlags_u, CheckboxFlags_i64, CheckboxFlags_u64 }

RadioButton :: proc { RadioButton_0, RadioButton_1 }

Combo :: proc { Combo_0, Combo_1, Combo_2 }

TreeNode :: proc { TreeNode_s, TreeNode_p, TreeNode_b }

TreeNodeEx :: proc { TreeNodeEx_s, TreeNodeEx_p, TreeNodeEx_b }

TreePush :: proc { TreePush_s, TreePush_p }

CollapsingHeader :: proc{ CollapsingHeader_b, CollapsingHeader_v }

Selectable :: proc { Selectable_0, Selectable_1 }

ListBox :: proc { ListBox_0, ListBox_1 }


PlotLines :: proc { PlotLines_0, PlotLines_1 }
PlotHistogram :: proc { PlotHistogram_0, PlotHistogram_1 }

Value :: proc { Value_0, Value_1, Value_2, Value_3 }

MenuItem :: proc { MenuItem_0, MenuItem_1 }

TabBarQueueFocus :: proc { TabBarQueueFocus_0, TabBarQueueFocus_1 }

TabItemCalcSize :: proc { TabItemCalcSize_0, TabItemCalcSize_1 }

GetColorU32 :: proc { GetColorU32_0, GetColorU32_1, GetColorU32_2 }

ImDrawList_AddText :: proc { ImDrawList_AddText_0, ImDrawList_AddText_1 }
