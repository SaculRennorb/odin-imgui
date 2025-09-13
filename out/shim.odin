package test

 pre_decr :: #force_inline proc "contextless" (p : ^$T) -> (new : T) { p^ -= 1; return p }
 pre_incr :: #force_inline proc "contextless" (p : ^$T) -> (new : T) { p^ += 1; return p }
post_decr :: #force_inline proc "contextless" (p : ^$T) -> (old : T) { old = p; p^ -= 1; return }
post_incr :: #force_inline proc "contextless" (p : ^$T) -> (old : T) { old = p; p^ += 1; return }

va_arg :: #force_inline proc(args : ^[]any, $T : typeid) -> (r : T) { r = (cast(T^) args[0])^; args^ = args[1:] }


Add :: proc { ImRect_Add_0, ImRect_Add_1 }

AddText :: proc { ImDrawList_AddText_0, ImDrawList_AddText_1 }

BeginChild :: proc { BeginChild_0, BeginChild_1 }

CheckboxFlags :: proc { CheckboxFlags_0, CheckboxFlags_1, CheckboxFlags_2, CheckboxFlags_3 }

CollapsingHeader :: proc { CollapsingHeader_0, CollapsingHeader_1 }

Combo :: proc { Combo_0, Combo_1, Combo_2 }

Contains :: proc { ImRect_Contains_0, ImRect_Contains_1 }

Expand :: proc { ImRect_Expand_0, ImRect_Expand_1 }

GetColorU32 :: proc { GetColorU32_0, GetColorU32_1, GetColorU32_2 }

GetCursorPos :: proc { GetCursorPos_0 }

GetForegroundDrawList :: proc { GetForegroundDrawList_1, GetForegroundDrawList_0 }

GetID :: proc { GetID_0, GetID_1, GetID_2, GetID_3, ImGuiWindow_GetID_0, ImGuiWindow_GetID_1, ImGuiWindow_GetID_2 }

GetIDWithSeed :: proc { GetIDWithSeed_0, GetIDWithSeed_1 }

GetKeyData :: proc { GetKeyData_0, GetKeyData_1 }

ImAbs :: proc { ImAbs_0, ImAbs_1, ImAbs_2 }

ImClamp :: proc { ImClamp_0, ImClamp_1 }

ImFloor :: proc { ImFloor_0, ImFloor_1 }

ImIsPowerOfTwo :: proc { ImIsPowerOfTwo_0, ImIsPowerOfTwo_1 }

ImLengthSqr :: proc { ImLengthSqr_0, ImLengthSqr_1 }

ImLerp :: proc { ImLerp_0, ImLerp_1, ImLerp_2, ImLerp_3 }

ImLog :: proc { ImLog_0, ImLog_1 }

ImMax :: proc { ImMax_0, ImMax_1 }

ImMin :: proc { ImMin_0, ImMin_1 }

ImPow :: proc { ImPow_0, ImPow_1 }

ImRsqrt :: proc { ImRsqrt_0, ImRsqrt_1 }

ImSign :: proc { ImSign_0, ImSign_1 }

ImTextCountUtf8BytesFromChar :: proc { ImTextCountUtf8BytesFromChar_0, ImTextCountUtf8BytesFromChar_1 }

ImTrunc :: proc { ImTrunc_0, ImTrunc_1 }

IsKeyChordPressed :: proc { IsKeyChordPressed_1, IsKeyChordPressed_0 }

IsKeyDown :: proc { IsKeyDown_1, IsKeyDown_0 }

IsKeyPressed :: proc { IsKeyPressed_1, IsKeyPressed_0 }

IsKeyReleased :: proc { IsKeyReleased_1, IsKeyReleased_0 }

IsMouseClicked :: proc { IsMouseClicked_1, IsMouseClicked_0 }

IsMouseDoubleClicked :: proc { IsMouseDoubleClicked_1, IsMouseDoubleClicked_0 }

IsMouseDown :: proc { IsMouseDown_1, IsMouseDown_0 }

IsMouseReleased :: proc { IsMouseReleased_1, IsMouseReleased_0 }

IsPopupOpen :: proc { IsPopupOpen_1, IsPopupOpen_0 }

IsRectVisible :: proc { IsRectVisible_0, IsRectVisible_1 }

ItemSize :: proc { ItemSize_0, ItemSize_1 }

ListBox :: proc { ListBox_0, ListBox_1 }

LogTextV :: proc { LogTextV_0 }

MarkIniSettingsDirty :: proc { MarkIniSettingsDirty_0, MarkIniSettingsDirty_1 }

MenuItem :: proc { MenuItem_0, MenuItem_1 }

OpenPopup :: proc { OpenPopup_0, OpenPopup_1 }

PlotHistogram :: proc { PlotHistogram_0, PlotHistogram_1 }

PlotLines :: proc { PlotLines_0, PlotLines_1 }

PushID :: proc { PushID_0, PushID_1, PushID_2, PushID_3 }

PushStyleColor :: proc { PushStyleColor_0, PushStyleColor_1 }

PushStyleVar :: proc { PushStyleVar_0, PushStyleVar_1 }

RadioButton :: proc { RadioButton_0, RadioButton_1 }

Remove :: proc { ImPool_Remove_0, ImPool_Remove_1 }

Selectable :: proc { Selectable_0, Selectable_1 }

SetItemKeyOwner :: proc { SetItemKeyOwner_1, SetItemKeyOwner_0 }

SetScrollFromPosX :: proc { SetScrollFromPosX_1, SetScrollFromPosX_0 }

SetScrollFromPosY :: proc { SetScrollFromPosY_1, SetScrollFromPosY_0 }

SetScrollX :: proc { SetScrollX_1, SetScrollX_0 }

SetScrollY :: proc { SetScrollY_1, SetScrollY_0 }

SetWindowCollapsed :: proc { SetWindowCollapsed_0, SetWindowCollapsed_1, SetWindowCollapsed_2 }

SetWindowFocus :: proc { SetWindowFocus_0, SetWindowFocus_1 }

SetWindowPos :: proc { SetWindowPos_0, SetWindowPos_1, SetWindowPos_2 }

SetWindowSize :: proc { SetWindowSize_0, SetWindowSize_1, SetWindowSize_2 }

Shortcut :: proc { Shortcut_1, Shortcut_0 }

TabBarQueueFocus :: proc { TabBarQueueFocus_0, TabBarQueueFocus_1 }

TabItemCalcSize :: proc { TabItemCalcSize_0, TabItemCalcSize_1 }

TableGcCompactTransientBuffers :: proc { TableGcCompactTransientBuffers_0, TableGcCompactTransientBuffers_1 }

TableGetColumnName :: proc { TableGetColumnName_1, TableGetColumnName_0 }

TreeNode :: proc { TreeNode_0, TreeNode_1, TreeNode_2 }

TreeNodeEx :: proc { TreeNodeEx_0, TreeNodeEx_1, TreeNodeEx_2 }

TreeNodeExV :: proc { TreeNodeExV_0, TreeNodeExV_1 }

TreeNodeV :: proc { TreeNodeV_0, TreeNodeV_1 }

TreePush :: proc { TreePush_0, TreePush_1 }

Value :: proc { Value_0, Value_1, Value_2, Value_3 }

deinit :: proc { ImVector_deinit, ImDrawListSplitter_deinit, ImGuiViewport_deinit, ImPool_deinit, ImGuiViewportP_deinit, ImGuiTable_deinit }

erase :: proc { ImVector_erase_0, ImVector_erase_1 }

init :: proc { ImVec2_init_0, ImVec2_init_1, ImVec4_init_0, ImVec4_init_1, ImVector_init_0, ImVector_init_1, ImGuiTextFilter_ImGuiTextRange_init_0, ImGuiTextFilter_ImGuiTextRange_init_1, ImGuiStoragePair_init_0, ImGuiStoragePair_init_1, ImGuiStoragePair_init_2, ImColor_init_0, ImColor_init_1, ImColor_init_2, ImColor_init_3, ImColor_init_4, ImVec1_init_0, ImVec1_init_1, ImVec2ih_init_0, ImVec2ih_init_1, ImVec2ih_init_2, ImRect_init_0, ImRect_init_1, ImRect_init_2, ImRect_init_3, ImSpan_init_0, ImSpan_init_1, ImSpan_init_2, ImGuiStyleMod_init_0, ImGuiStyleMod_init_1, ImGuiStyleMod_init_2, ImGuiPtrOrIndex_init_0, ImGuiPtrOrIndex_init_1 }

resize :: proc { ImVector_resize_0, ImVector_resize_1 }

set :: proc { ImSpan_set_0, ImSpan_set_1 }
