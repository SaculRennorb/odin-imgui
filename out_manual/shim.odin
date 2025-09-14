package test

import str "core:strings"
import "core:strconv"
import "core:os"
import "core:mem"
import "base:runtime"
import "base:intrinsics"

pre_decr :: proc { pre_decr_m, pre_decr_r }
pre_decr_m :: #force_inline proc "contextless" (p : ^[^]$T) -> (new : ^T) {
	p^ = p^[-1:]; return p^
}
pre_decr_r :: #force_inline proc "contextless" (p : ^$T) -> (new : T) where !intrinsics.type_is_multi_pointer(T) {
	when intrinsics.type_is_pointer(T) { p^ = mem.ptr_offset(p^, -1) } else { p^ -= 1 }; return p^
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
	old = p^; p^ = p^[-1:]; return
}
post_decr_r :: #force_inline proc "contextless" (p : ^$T) -> (old : T) where !intrinsics.type_is_multi_pointer(T) {
	old = p^; when intrinsics.type_is_pointer(T) { p^ = mem.ptr_offset(p^, -1) } else { p^ -= 1 }; return
}

post_incr :: proc { post_incr_m, post_incr_r }
post_incr_m :: #force_inline proc "contextless" (p : ^[^]$T) -> (old : ^T) {
	old = p^; p^ = p^[1:]; return
}
post_incr_r :: #force_inline proc "contextless" (p : ^$T) -> (old : T) where !intrinsics.type_is_multi_pointer(T) {
	old = p^; when intrinsics.type_is_pointer(T) { p^ = mem.ptr_offset(p^, 1) } else { p^ += 1 }; return
}

va_arg :: proc { va_arg_f, va_arg_n }
va_arg_f :: #force_inline proc(args : ^[]any, $T : typeid) -> (r : T) { r = (cast(^T) args[0].data)^; args^ = args[1:] }
va_arg_n :: #force_inline proc(args : []any, $T : typeid, i : int) -> T { return (cast(^T) args[0].data)^ }

ptr_to_first :: proc { ptr_to_first_slice, ptr_to_first_se }

ptr_to_first_slice :: proc(slice : []$T, needle : T) -> (el : ^T, found : bool)
{
	for &e in slice {
		if e == needle { return &e, true }
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

strlen :: #force_inline proc(str : [^]u8) -> i32
{
	return cast(i32) runtime.cstring_len(cast(cstring) str)
}

strncpy :: proc(dst, src : [^]u8, #any_int len : u32)
{
	for dst, src, len := dst, src, len; \
			len > 0 && src[0] != 0; \
			dst, src, len = dst[1:], src[1:], len - 1 {
		dst[0] = src[0]
	}
}

fread :: proc(buffer : rawptr, size : uint, count : uint, stream : os.Handle) -> uint
{
	read, err := os.read(stream, (cast([^]byte)buffer)[:size * count])
	return cast(uint)read
}

fwrite :: proc(buffer : rawptr, size : uint, count : uint, stream : os.Handle) -> uint
{
	read, err := os.write(stream, (cast([^]byte)buffer)[:size * count])
	return cast(uint)read
}

memchr :: proc(mem : [^]u8, chr : u8, #any_int len : int) -> ^u8
{
	for i in 0..<len {
		if mem[i] == chr { return &mem[i] }
	}
	return nil
}

memset :: mem.set

next_line :: proc(str : string, offset : ^int) -> string {
	rem := str[offset^:]
	end := memchr(raw_data(rem), '\n', len(rem))
	if(end != nil) {
		offset^ += mem.ptr_sub(cast(^u8)raw_data(rem), end) + 1
		return string_from_se(raw_data(rem), end)
	}
	else {
		offset^ = len(str)
		return string_from_se(raw_data(rem), &raw_data(str)[len(str)])
	}
}


string_from_cstr :: proc { string_from_cstr_d, string_from_cstr_l }

string_from_cstr_d :: #force_inline proc(str : cstring) -> string
{
	return string_from_cstr_l(str, strlen(cast([^]u8)str))
}

string_from_cstr_l :: #force_inline proc(str : cstring, #any_int len : int) -> string
{
	return transmute(string) runtime.Raw_String{ cast([^]u8) str, len }
}

string_from_se :: #force_inline proc(start : [^]u8, end : ^u8) -> string
{
	return transmute(string) runtime.Raw_String{ start, mem.ptr_sub(end, cast(^u8) start) }
}

string_from_slice :: #force_inline proc(buff : []u8, scan_for_terminator := true) -> string
{
	return transmute(string) runtime.Raw_String{ raw_data(buff), scan_for_terminator ? cast(int)strlen(raw_data(buff)) : len(buff) }
}

slice_from_se :: #force_inline proc(start : [^]$T, end : ^T) -> []T
{
	return start[:mem.ptr_sub(end, cast(^T)start)]
}

appendfv :: ImGuiTextBuffer_appendfv
appendf :: ImGuiTextBuffer_appendf

append :: proc { ImGuiTextIndex_append, ImGuiTextBuffer_append, ImGuiTextBuffer_append2 }

c_str :: ImGuiTextBuffer_c_str

memcpy :: mem.copy_non_overlapping

memmove :: mem.copy

memcmp :: #force_inline proc(a, b : rawptr, #any_int l : int) -> i32 { return cast(i32) mem.compare_ptrs(a, b, l) }

strcmp :: runtime.cstring_cmp


strncmp :: proc { strncmp_s, strncmp_c }

strncmp_s :: proc(x, y : string, #any_int len_ : int) -> i32
{
	if len(x) < len_ { return -1 if len(y) > 0 else 0 }
	if len(y) < len_ { return +1 }

	return cast(i32) str.compare(x[:len_], y[:len_])
}

strncmp_c :: proc(x, y : cstring, #any_int len : int) -> i32
{
	if x == y {
		return 0
	}
	if (x == nil) ~ (y == nil) {
		return -1 if x == nil else +1
	}

	xn := runtime.cstring_len(x)
	yn := runtime.cstring_len(y)
	ret := runtime.memory_compare(cast([^]u8) x, cast([^]u8) y, min(xn, yn, len))
	if ret == 0 && xn != yn {
		return -1 if xn < yn else +1
	}
	return cast(i32) ret
}

clear :: proc { runtime.clear_map, runtime.clear_dynamic_array, ImVector_clear, ImGuiTextBuffer_clear, ImChunkStream_clear, ImGuiTextIndex_clear }

erase :: proc { ImVector_erase_0, ImVector_erase_1 }

empty :: proc { ImVector_empty, ImChunkStream_empty, ImGuiTextBuffer_empty, ImGuiTextFilter_ImGuiTextRange_empty }

size :: proc { ImSpan_size, ImVector_size, ImGuiTextBuffer_size, ImChunkStream_size, ImGuiTextIndex_size }

pop_back :: proc { ImVector_pop_back }

push_back :: proc { ImVector_push_back, ImTriangulatorNodeSpan_push_back }
push_front :: proc { ImVector_push_front }

reserve_discard :: ImVector_reserve_discard

find_erase :: ImVector_find_erase

Remove :: proc { ImPool_Remove_0, ImPool_Remove_1 }

find :: ImVector_find

set :: proc { ImSpan_set_0, ImSpan_set_1 }

AddText :: proc { ImDrawList_AddText_0, ImDrawList_AddText_1 }

Contains :: proc { ImRect_Contains_0, ImRect_Contains_1, ImPool_Contains, ImGuiSelectionBasicStorage_Contains }

front :: proc { ImVector_front }

resize :: proc { ImVector_resize_0, ImVector_resize_1 }

reserve :: proc { ImVector_reserve, ImGuiTextBuffer_reserve }

begin :: proc{ ImChunkStream_begin, ImGuiTextBuffer_begin, ImVector_begin }
end :: proc{ ImChunkStream_end, ImGuiTextBuffer_end, ImVector_end }
chunk_size :: ImChunkStream_chunk_size

back :: proc { ImVector_back }

contains :: ImVector_contains

init :: proc { ImVector_init_0, ImVector_init_1, ImGuiTextFilter_ImGuiTextRange_init_1, ImGuiStoragePair_init_0, ImGuiStoragePair_init_1, ImGuiStoragePair_init_2, ImColor_init_1, ImColor_init_2, ImColor_init_3, ImColor_init_4, ImRect_init_1, ImRect_init_2, ImRect_init_3, ImSpan_init_0, ImSpan_init_1, ImSpan_init_2, ImGuiStyleMod_init_0, ImGuiStyleMod_init_1, ImGuiStyleMod_init_2, ImGuiPtrOrIndex_init_0, ImGuiPtrOrIndex_init_1, ImDrawList_init, ImGuiKeyRoutingData_init, ImGuiWindow_init, ImGuiWindowClass_init, ImGuiWindowSettings_init, ImGuiDockNode_init, ImFontConfig_init, ImFontAtlasCustomRect_init, ImGuiMultiSelectTempData_init, ImGuiPlotArrayGetterData_init, ImGuiTabItem_init, ImGuiTableTempData_init, ImGuiTableInstanceData_init, ImGuiTableColumn_init, ImGuiTableSettings_init, ImGuiTableColumnSettings_init, ImGuiOldColumns_init, ImFontAtlas_init, ImGuiDockContextPruneNodeData_init, ImGuiTable_init, ImGuiMultiSelectState_init, ImGuiTabBar_init, ImGuiViewportP_init, init_shim_ImStbTexteditState, ImFont_init, ImGuiContext_init }

init_shim_ImStbTexteditState :: #force_inline proc "contextless" (p : ^ImStbTexteditState) { p^ = {} }

Add :: proc { ImRect_Add_0, ImRect_Add_1, ImPool_Add }

GetID :: proc { ImGuiWindow_GetID_0, ImGuiWindow_GetID_1, ImGuiWindow_GetID_2, ImGuiWindow_GetID_3, GetID_0, GetID_1, GetID_2, GetID_3 }

deinit :: proc { \
	ImVector_deinit, ImDrawListSplitter_deinit, ImGuiViewport_deinit, ImPool_deinit, ImGuiViewportP_deinit, ImGuiTable_deinit, ImDrawList_deinit, ImGuiDockNode_deinit, ImFontAtlas_deinit, ImGuiWindow_deinit, ImFont_deinit \
	, deinit_stub_u8, deinit_stub_ImGuiMultiSelectTempData, deinit_stub_ImStb_STB_TexteditState, deinit_stub_ImGuiTabBar, deinit_stub_ImGuiMultiSelectState, deinit_stub_ImGuiListClipperData, deinit_stub_ImGuiTableTempData, deinit_stub_ImGuiContext, deinit_stub_ImGuiOldColumns, deinit_stub_ImFontBuildSrcData \
}
// might be a issue of missin implicit destructors
deinit_stub_u8 :: #force_inline proc "contextless" (_ : ^u8) { }
deinit_stub_ImGuiMultiSelectTempData :: #force_inline proc "contextless" (_ : ^ImGuiMultiSelectTempData) { }
deinit_stub_ImStb_STB_TexteditState :: #force_inline proc "contextless" (_ : ^ImStb_STB_TexteditState) { }
deinit_stub_ImGuiTabBar :: #force_inline proc "contextless" (_ : ^ImGuiTabBar) { }
deinit_stub_ImGuiMultiSelectState :: #force_inline proc "contextless" (_ : ^ImGuiMultiSelectState) { }
deinit_stub_ImGuiListClipperData :: #force_inline proc "contextless" (_ : ^ImGuiListClipperData) { }
deinit_stub_ImGuiTableTempData :: #force_inline proc "contextless" (_ : ^ImGuiTableTempData) { }
deinit_stub_ImGuiContext :: #force_inline proc "contextless" (_ : ^ImGuiContext) { }
deinit_stub_ImGuiOldColumns :: #force_inline proc "contextless" (_ : ^ImGuiOldColumns) { }
deinit_stub_ImFontBuildSrcData :: #force_inline proc "contextless" (_ : ^ImFontBuildSrcData) { }

Expand :: proc { ImRect_Expand_0, ImRect_Expand_1 }

TableGetColumnName :: proc { TableGetColumnName_n, TableGetColumnName_tn }

TableGcCompactTransientBuffers :: proc { TableGcCompactTransientBuffers_tab, TableGcCompactTransientBuffers_tmp }

CheckboxFlags :: proc { CheckboxFlags_i, CheckboxFlags_u, CheckboxFlags_i64, CheckboxFlags_u64, CheckboxFlagsT }

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

ItemSize :: proc{ ItemSize_0, ItemSize_1 }

_ClearFreeMemory :: ImDrawList__ClearFreeMemory

ClearFreeMemory :: proc { ImDrawListSplitter_ClearFreeMemory, ImGuiInputTextState_ClearFreeMemory, ImGuiInputTextDeactivatedState_ClearFreeMemory }

GetColumnSettings :: ImGuiTableSettings_GetColumnSettings

Overlaps :: ImRect_Overlaps

AddRectFilled :: ImDrawList_AddRectFilled

AddRectFilledMultiColor :: ImDrawList_AddRectFilledMultiColor

GetForegroundDrawList :: proc { GetForegroundDrawList_w, GetForegroundDrawList_vp }

GetCenter :: proc { ImRect_GetCenter, ImGuiViewport_GetCenter }
GetWidth :: ImRect_GetWidth
GetHeight :: ImRect_GetHeight

_CalcCircleAutoSegmentCount :: ImDrawList__CalcCircleAutoSegmentCount

AddCircleFilled :: ImDrawList_AddCircleFilled

AddCircle :: ImDrawList_AddCircle

Begin :: proc { Begin_, ImGuiListClipper_Begin }

IncludeItemByIndex :: ImGuiListClipper_IncludeItemByIndex

IncludeItemsByIndex :: ImGuiListClipper_IncludeItemsByIndex

Step :: ImGuiListClipper_Step

PushID :: proc { PushID_0, PushID_1, PushID_2, PushID_3 }

GetIndex :: ImPool_GetIndex

AddRect :: ImDrawList_AddRect
AddLine :: ImDrawList_AddLine
AddPolyline :: ImDrawList_AddPolyline

PathLineTo :: ImDrawList_PathLineTo

PathLineToMergeDuplicate :: ImDrawList_PathLineToMergeDuplicate

ClearFlags :: proc { ImGuiNextItemData_ClearFlags, ImGuiNextWindowData_ClearFlags }

PathStroke :: ImDrawList_PathStroke

PathArcTo :: ImDrawList_PathArcTo
PathArcToFast :: ImDrawList_PathArcToFast
_PathArcToFastEx :: ImDrawList__PathArcToFastEx

Clear :: proc { ImPool_Clear, ImDrawData_Clear, ImBitVector_Clear, ImGuiPayload_Clear, ImGuiStorage_Clear, ImGuiTextFilter_Clear, ImGuiNavItemData_Clear, ImDrawListSplitter_Clear, ImGuiKeyRoutingTable_Clear, ImFontGlyphRangesBuilder_Clear, ImGuiTypingSelectState_Clear, ImGuiMultiSelectTempData_Clear, ImFontAtlas_Clear, ImGuiSelectionBasicStorage_Clear }

GetSize :: ImRect_GetSize

ClipWith :: ImRect_ClipWith

ClipWithFull :: ImRect_ClipWithFull

LogTextV :: proc { LogTextV_0, LogTextV_1 }

CalcTextSizeA :: ImFont_CalcTextSizeA

PushStyleColor :: proc { PushStyleColor_0, PushStyleColor_1 }

ImIsPowerOfTwo :: proc { ImIsPowerOfTwo_0, ImIsPowerOfTwo_1 }

PushTextureID :: ImDrawList_PushTextureID

PushClipRect :: proc { ImDrawList_PushClipRect, PushClipRect_ }

IsMouseClicked :: proc { IsMouseClicked_0, IsMouseClicked_1 }

IsMouseDoubleClicked :: proc { IsMouseDoubleClicked_0, IsMouseDoubleClicked_1 }

IsMouseReleased :: proc { IsMouseReleased_0, IsMouseReleased_1 }

IsMouseDown :: proc { IsMouseDown_0, IsMouseDown_1 }

Shortcut :: proc { Shortcut_0, Shortcut_1 }

PopClipRect :: proc { PopClipRect_, ImDrawList_PopClipRect }

ContainsWithPad :: ImRect_ContainsWithPad

GetMainRect :: ImGuiViewportP_GetMainRect

GetVoidPtr :: ImGuiStorage_GetVoidPtr
GetVoidPtrRef :: ImGuiStorage_GetVoidPtrRef
SetVoidPtr :: ImGuiStorage_SetVoidPtr
GetVarPtr :: ImGuiDataVarInfo_GetVarPtr

IsPopupOpen :: proc{ IsPopupOpen_0, IsPopupOpen_1 }

SetScrollFromPosX :: proc { SetScrollFromPosX_0, SetScrollFromPosX_1 }
SetScrollFromPosY :: proc { SetScrollFromPosY_0, SetScrollFromPosY_1 }

Reset :: ImGuiListClipperData_Reset

Split :: ImDrawListSplitter_Split

Merge :: ImDrawListSplitter_Merge

SetCurrentChannel :: ImDrawListSplitter_SetCurrentChannel

index_from_ptr :: proc{ ImSpan_index_from_ptr, ImVector_index_from_ptr }

GetByKey :: ImPool_GetByKey

GetOrAddByKey :: ImPool_GetOrAddByKey

SeekCursorForItem :: ImGuiListClipper_SeekCursorForItem

ImTextCountUtf8BytesFromChar :: proc { ImTextCountUtf8BytesFromChar_0, ImTextCountUtf8BytesFromChar_1 }

RenderChar :: ImFont_RenderChar

GetByIndex :: ImPool_GetByIndex

CalcFontSize :: ImGuiWindow_CalcFontSize
GetIDFromPos :: ImGuiWindow_GetIDFromPos
SetWindowPos :: proc { SetWindowPos_0, SetWindowPos_1, SetWindowPos_2 }

MarkIniSettingsDirty :: proc { MarkIniSettingsDirty_0, MarkIniSettingsDirty_1 }

SetWindowSize :: proc { SetWindowSize_0, SetWindowSize_1, SetWindowSize_2 }

SetWindowCollapsed :: proc { SetWindowCollapsed_0, SetWindowCollapsed_1, SetWindowCollapsed_2 }

ChannelsSplit :: ImDrawList_ChannelsSplit
ChannelsSetCurrent :: ImDrawList_ChannelsSetCurrent

GetInt :: ImGuiStorage_GetInt

CursorClamp :: ImGuiInputTextState_CursorClamp

GetKeyData :: proc { GetKeyData_0, GetKeyData_k }

TitleBarRect :: ImGuiWindow_TitleBarRect

Rect :: proc{ ImGuiWindow_Rect, ImGuiDockNode_Rect }

GetWorkRect :: ImGuiViewportP_GetWorkRect
GetBuildWorkRect :: ImGuiViewportP_GetBuildWorkRect
UpdateWorkRect :: ImGuiViewportP_UpdateWorkRect

Update :: ImGuiMenuColumns_Update

IsLoaded :: ImFont_IsLoaded

_SetTextureID :: ImDrawList__SetTextureID

TestBit :: proc{ ImBitArray_TestBit, ImBitVector_TestBit }

IsKeyChordPressed :: proc { IsKeyChordPressed_0, IsKeyChordPressed_1 }

Translate :: ImRect_Translate

GetIDFromRectangle :: ImGuiWindow_GetIDFromRectangle

next_chunk :: ImChunkStream_next_chunk
ptr_from_offset :: ImChunkStream_ptr_from_offset

insert :: ImVector_insert

split :: ImGuiTextFilter_ImGuiTextRange_split

offset_from_ptr :: ImChunkStream_offset_from_ptr

IsKeyPressed :: proc { IsKeyPressed_0, IsKeyPressed_1 }

IsFloatingNode :: ImGuiDockNode_IsFloatingNode
IsCentralNode :: ImGuiDockNode_IsCentralNode
IsDockSpace :: ImGuiDockNode_IsDockSpace
IsRootNode :: ImGuiDockNode_IsRootNode
IsHiddenTabBar :: ImGuiDockNode_IsHiddenTabBar
IsNoTabBar :: ImGuiDockNode_IsNoTabBar
IsSplitNode :: ImGuiDockNode_IsSplitNode
IsEmpty :: ImGuiDockNode_IsEmpty
UpdateMergedFlags :: ImGuiDockNode_UpdateMergedFlags
IsLeafNode :: ImGuiDockNode_IsLeafNode

IsDataType :: ImGuiPayload_IsDataType

MenuBarRect :: ImGuiWindow_MenuBarRect

GetBL :: ImRect_GetBL
GetTL :: ImRect_GetTL
GetBR :: ImRect_GetBR
GetTR :: ImRect_GetTR
IsInverted :: ImRect_IsInverted
GetArea :: ImRect_GetArea

PushClipRectFullScreen :: ImDrawList_PushClipRectFullScreen

IsPreview :: ImGuiPayload_IsPreview
IsDelivery :: ImGuiPayload_IsDelivery

PushStyleVar :: proc { PushStyleVar_f, PushStyleVar_v2 }

CursorAnimReset :: ImGuiInputTextState_CursorAnimReset

stb_textedit_initialize_state :: ImStb_stb_textedit_initialize_state
stb_textedit_drag :: ImStb_stb_textedit_drag
stb_textedit_click :: ImStb_stb_textedit_click
stb_textedit_cut :: ImStb_stb_textedit_cut
stb_textedit_paste :: ImStb_stb_textedit_paste
stb_textedit_replace :: ImStb_stb_textedit_replace

FindGlyph :: ImFont_FindGlyph
SelectAll :: proc { ImGuiInputTextState_SelectAll, ImGuiInputTextCallbackData_SelectAll }
HasSelection :: proc { ImGuiInputTextState_HasSelection, ImGuiInputTextCallbackData_HasSelection }
ClearSelection :: proc { ImGuiInputTextState_ClearSelection, ImGuiInputTextCallbackData_ClearSelection }

OnKeyPressed :: ImGuiInputTextState_OnKeyPressed
OnCharPressed :: ImGuiInputTextState_OnCharPressed

SetScrollY :: proc { SetScrollY_0, SetScrollY_1 }
SetScrollX :: proc { SetScrollX_0, SetScrollX_1 }

GetCharAdvance :: ImFont_GetCharAdvance

GetMouseCursorTexData :: ImFontAtlas_GetMouseCursorTexData

AddImage :: ImDrawList_AddImage
AddImageQuad :: ImDrawList_AddImageQuad
AddImageRounded :: ImDrawList_AddImageRounded
PopTextureID :: ImDrawList_PopTextureID
PrimVtx :: ImDrawList_PrimVtx
PrimWriteVtx :: ImDrawList_PrimWriteVtx
AddTriangle :: ImDrawList_AddTriangle
AddTriangleFilled :: ImDrawList_AddTriangleFilled
PathFillConvex :: ImDrawList_PathFillConvex

SetBit :: proc { ImBitArray_SetBit, ImBitVector_SetBit, ImFontGlyphRangesBuilder_SetBit }

ClearTexData :: ImFontAtlas_ClearTexData
GetGlyphRangesDefault :: ImFontAtlas_GetGlyphRangesDefault

size_in_bytes :: proc { ImSpan_size_in_bytes, ImVector_size_in_bytes }

Create :: ImBitVector_Create

Init :: ImTriangulator_Init
GetNextTriangle :: ImTriangulator_GetNextTriangle

_PopUnusedDrawCmd :: ImDrawList__PopUnusedDrawCmd
AddDrawCmd :: ImDrawList_AddDrawCmd

clear_delete :: ImVector_clear_delete

PrimReserve :: ImDrawList_PrimReserve
PrimUnReserve :: ImDrawList_PrimUnreserve

PrimRectUV :: ImDrawList_PrimRectUV

GetIntRef :: ImGuiStorage_GetIntRef

shrink :: ImVector_shrink

Unlink :: ImTriangulatorNode_Unlink

find_erase_unsorted :: proc{ ImVector_find_erase_unsorted, ImTriangulatorNodeSpan_find_erase_unsorted }

AddGlyph :: ImFont_AddGlyph

clear_destruct :: ImVector_clear_destruct

SetInt :: ImGuiStorage_SetInt

GetIDWithSeed :: proc { GetIDWithSeed_0, GetIDWithSeed_1 }

IsRectVisible :: proc{ IsRectVisible_0, IsRectVisible_1 }

BeginChild :: proc { BeginChild_0, BeginChild_1 }

IsKeyDown :: proc { IsKeyDown_0, IsKeyDown_1 }

ClearInputKeys :: ImGuiIO_ClearInputKeys

TranslateY :: ImRect_TranslateY
TranslateX :: ImRect_TranslateX

alloc_chunk :: ImChunkStream_alloc_chunk

GetName :: ImGuiWindowSettings_GetName

ClearRequestFlags :: ImGuiViewportP_ClearRequestFlags

Reserve :: proc{ ImPool_Reserve, ImSpanAllocator_Reserve }

SetLocalFlags :: ImGuiDockNode_SetLocalFlags

DeclColumns :: ImGuiMenuColumns_DeclColumns

ToVec4 :: ImRect_ToVec4

SetCircleTessellationMaxError :: ImDrawListSharedData_SetCircleTessellationMaxError

ChannelsMerge :: ImDrawList_ChannelsMerge

swap :: proc { ImVector_swap, ImChunkStream_swap }

IsKeyReleased :: proc { IsKeyReleased_0, IsKeyReleased_1 }

ClearInputMouse :: ImGuiIO_ClearInputMouse

SetItemKeyOwner :: proc { SetItemKeyOwner_0, SetItemKeyOwner_1 }

IsBuilt :: ImFontAtlas_IsBuilt

OpenPopup :: proc { OpenPopup_0, OpenPopup_1 }

IsPacked :: ImFontAtlasCustomRect_IsPacked

ClearOutputData :: ImFont_ClearOutputData

GetCustomRectByIndex :: ImFontAtlas_GetCustomRectByIndex

AddCustomRectRegular :: ImFontAtlas_AddCustomRectRegular

CalcCustomRectUV :: ImFontAtlas_CalcCustomRectUV

BuildLookupTable :: ImFont_BuildLookupTable

FindGlyphNoFallback :: ImFont_FindGlyphNoFallback

IsGlyphRangeUnused :: ImFont_IsGlyphRangeUnused

get_line_begin :: ImGuiTextIndex_get_line_begin
get_line_end :: ImGuiTextIndex_get_line_end

_TryMergeDrawCmds :: ImDrawList__TryMergeDrawCmds

BuildSortByKey :: ImGuiStorage_BuildSortByKey

GetMapSize :: ImPool_GetMapSize
TryGetMapData :: ImPool_TryGetMapData
GetAliveCount :: ImPool_GetAliveCount

GetArenaSizeInBytes :: ImSpanAllocator_GetArenaSizeInBytes
SetArenaBasePtr :: ImSpanAllocator_SetArenaBasePtr
GetSpan :: ImSpanAllocator_GetSpan
GetSpanPtrBegin :: ImSpanAllocator_GetSpanPtrBegin
GetSpanPtrEnd :: ImSpanAllocator_GetSpanPtrEnd

AddQuadFilled :: ImDrawList_AddQuadFilled

SetTexID :: ImFontAtlas_SetTexID
GetTexDataAsRGBA32 :: ImFontAtlas_GetTexDataAsRGBA32

GetTexID :: ImDrawCmd_GetTexID

AddKeyEvent :: ImGuiIO_AddKeyEvent
AddKeyAnalogEvent :: ImGuiIO_AddKeyAnalogEvent
SetKeyEventNativeData :: ImGuiIO_SetKeyEventNativeData
AddMousePosEvent :: ImGuiIO_AddMousePosEvent
AddMouseViewportEvent :: ImGuiIO_AddMouseViewportEvent
AddMouseSourceEvent :: ImGuiIO_AddMouseSourceEvent
AddMouseButtonEvent :: ImGuiIO_AddMouseButtonEvent
AddMouseWheelEvent :: ImGuiIO_AddMouseWheelEvent
AddInputCharacter :: ImGuiIO_AddInputCharacter
AddFocusEvent :: ImGuiIO_AddFocusEvent
AddInputCharacterUTF16 :: ImGuiIO_AddInputCharacterUTF16


parse_int_pair_prefixed :: proc(line : string, offset : ^int, prefix : string, x : ^i64, $radix_x : int, y : ^i64, $radix_y : int) -> (ok : bool)
{
	if strncmp(line, prefix, len(prefix)) != 0 { return }; offset^ += len(prefix)
	return parse_int_pair(line, offset, x, radix_x, y, radix_y)
}

parse_int_pair :: proc(line : string, offset : ^int, x : ^i64, $radix_x : int, y : ^i64, $radix_y : int) -> (ok : bool)
{
	if !parse_int(line, offset, x, radix_x) { return }
	if line[offset^] != ',' { return }; offset ^ += 1
	if !parse_int(line, offset, y, radix_y) { return }
	return true
}

parse_int_prefixed :: proc(line : string, offset : ^int, prefix : string, x : ^i64, $radix_x : int) -> (ok : bool)
{
	if strncmp(line, prefix, len(prefix)) != 0 { return }; offset^ += len(prefix)
	return parse_int(line, offset, x, radix_x)
}

parse_int :: proc(line : string, offset : ^int, x : ^i64, $radix_x : int) -> (ok : bool)
{
	l : int
	when radix_x == 16 { if strncmp(line[offset^:], "0x", 2) != 0 { return }; offset^ += 2 }
	x^, ok = strconv.parse_i64_of_base(line[offset^:], radix_x, &l); if !ok { return } offset^ += l
	return true
}

parse_char_prefixed :: proc(line : string, offset : ^int, prefix : string, x : ^u8) -> (ok : bool)
{
	if strncmp(line, prefix, len(prefix)) != 0 { return }; offset^ += len(prefix)
	return parse_char(line, offset, x)
}

parse_char :: proc(line : string, offset : ^int, x : ^u8) -> (ok : bool)
{
	x^ = line[offset^]
	offset^ += 1
	return true
}

parse_float_prefixed :: proc(line : string, offset : ^int, prefix : string, x : ^f32, $radix_x : int) -> (ok : bool)
{
	if strncmp(line, prefix, len(prefix)) != 0 { return }; offset^ += len(prefix)
	return parse_float(line, offset, x, radix_x)
}

parse_float :: proc(line : string, offset : ^int, x : ^f32, $radix_x : int) -> (ok : bool)
{
	l : int
	when radix_x == 16 { if strncmp(line[offset^:], "0x", 2) != 0 { return }; offset^ += 2 }
	x^, ok = strconv.parse_f32(line[offset^:], &l); if !ok { return } offset^ += l
	return true
}

parse_skip_blank :: proc(str : string, offset : ^int)
{
	for str[offset^] == ' ' || str[offset^] == '\t' {
		offset^ += 1
	}
}

HEX_LUT_INVERSE : [255]u8 = {
	'0' = 0x0,
	'1' = 0x1,
	'2' = 0x2,
	'3' = 0x3,
	'4' = 0x4,
	'5' = 0x5,
	'6' = 0x6,
	'7' = 0x7,
	'8' = 0x8,
	'9' = 0x9,
	'a' = 0xA, 'A' = 0xA,
	'b' = 0xB, 'B' = 0xB,
	'c' = 0xC, 'C' = 0xC,
	'd' = 0xD, 'D' = 0xD,
	'e' = 0xE, 'E' = 0xE,
	'f' = 0xF, 'F' = 0xF,
}


sscanf :: proc(buffer : []u8, format : string, out_ptrs : ..any) -> (written_ptrs : int)
{
	if format == "" { return }

	c, e := raw_data(format), raw_data(format)[len(format)-1:]
	ic, ie := raw_data(buffer), raw_data(buffer)[len(buffer):]
	arg_loop: for c < e && ic < ie {
		switch c[0] {
			case '%': // format specs
				parse_precission := false
				width, precission, longness : i32 = max(i32), 0, 0
				for c < e && ic < ie {
					c = c[1:]
					switch c[0] {
						case '%':
							if ic[0] != '%' { return } // non format specifiers should match
							c, ic = c[2:], ic[1:]
							continue arg_loop

						case '0': fallthrough //TODO(Rennorb) @corectness: this is actually a prefix
						case '1'..='9':
							width_loop: for ic < ie {
								precission = precission * 10 + i32(c[0] - '0')
								c = c[1:]
								switch c[0] {
									case '0'..='9': /*continue parsing*/
									case: break width_loop
								}
							}
							if !parse_precission { width = precission; precission = 0 }
							else { parse_precission = false }

						case '.':
							c = c[1:]
							parse_precission = true
						
						case '*':
							c = c[1:]
							precission = -1
							parse_precission = false

						case 'c':
							out_ptrs[written_ptrs].(^u8)^ = ic[0]
							written_ptrs += 1
							c, ic = c[1:], ic[1:]
							continue arg_loop

						case 's':
							str := transmute(string)runtime.Raw_String{ data = ic, len = width == 0 ? mem.ptr_sub(ie, ic) : int(width) }
							out_ptrs[written_ptrs].(^string)^ = str
							written_ptrs += 1
							c, ic = c[1:], ic[len(str):]

							continue arg_loop

						// not implementing set matchces, how do i look like...
						// case '['
						
						case 'd', 'i' /*somewhat wrong, i should determine the base from the first number parsed*/:
							c = c[1:]

							neg : bool
							if ic[0] == '-' {
								neg = true
								ic = ic[1:]
							}

							number : i64 
							numbers_loop1: for ic < ie && width > 0 {
								switch ic[0] {
									case '0'..='9':
										number = number * 10 + i64(ic[0] - '0')
									case: break numbers_loop1
								}
								ic = ic[1:]
							}

							switch longness {
								case -2: out_ptrs[written_ptrs].(^i8)^  = cast(i8) (neg ? -number : number)
								case -1: out_ptrs[written_ptrs].(^i16)^ = cast(i16)(neg ? -number : number)
								case 0: out_ptrs[written_ptrs].(^i32)^  = cast(i32)(neg ? -number : number)
								case 2: out_ptrs[written_ptrs].(^i64)^  = cast(i64)(neg ? -number : number)
								case: return
							}
							written_ptrs += 1

							continue arg_loop

						case 'u':
							c = c[1:]

							number : u64
							numbers_loop2: for ic < ie && width > 0 {
								switch ic[0] {
									case '0'..='9':
										number = number * 10 + u64(ic[0] - '0')
									case: break numbers_loop2
								}
								ic = ic[1:]
							}

							switch longness {
								case -2: out_ptrs[written_ptrs].(^u8)^  = cast(u8)number
								case -1: out_ptrs[written_ptrs].(^u16)^ = cast(u16)number
								case 0: out_ptrs[written_ptrs].(^u32)^  = cast(u32)number
								case 2: out_ptrs[written_ptrs].(^u64)^  = cast(u64)number
								case: return
							}
							written_ptrs += 1

							width, precission, longness = max(i32), 0, 0 // reset

						case 'o':
							c = c[1:]

							neg : bool
							if ic[0] == '-' {
								neg = true
								ic = ic[1:]
							}

							number : i64 
							numbers_loop3: for ic < ie && width > 0 {
								switch ic[0] {
									case '0'..='8':
										number = number * 8 + i64(ic[0] - '0')
									case: break numbers_loop3
								}
								ic = ic[1:]
							}

							switch longness {
								case -2: out_ptrs[written_ptrs].(^i8)^  = cast(i8) (neg ? -number : number)
								case -1: out_ptrs[written_ptrs].(^i16)^ = cast(i16)(neg ? -number : number)
								case 0: out_ptrs[written_ptrs].(^i32)^  = cast(i32)(neg ? -number : number)
								case 2: out_ptrs[written_ptrs].(^i64)^  = cast(i64)(neg ? -number : number)
								case: return
							}
							written_ptrs += 1

							continue arg_loop

						case 'p': fallthrough
						case 'x', 'X':
							c = c[1:]

							neg : bool
							if ic[0] == '-' {
								neg = true
								ic = ic[1:]
							}

							number : i64 
							numbers_loop4: for ic < ie && width > 0 {
								switch ic[0] {
									case '0'..='9':
										number = number * 16 + i64(ic[0] - '0')
									case 'a'..='f':
										number = number * 16 + i64(ic[0] - 'a')
									case 'A'..='F':
										number = number * 16 + i64(ic[0] - 'A')
									case: break numbers_loop4
								}
								ic = ic[1:]
							}

							switch longness {
								case -2: out_ptrs[written_ptrs].(^i8)^  = cast(i8) (neg ? -number : number)
								case -1: out_ptrs[written_ptrs].(^i16)^ = cast(i16)(neg ? -number : number)
								case 0: out_ptrs[written_ptrs].(^i32)^  = cast(i32)(neg ? -number : number)
								case 2: out_ptrs[written_ptrs].(^i64)^  = cast(i64)(neg ? -number : number)
								case: return
							}
							written_ptrs += 1

							continue arg_loop

						case 'n': // number of chars read
							c = c[1:]
							switch longness {
								case -2: out_ptrs[written_ptrs].(^i8)^ = cast(i8)mem.ptr_sub(ie, ic)
								case -1: out_ptrs[written_ptrs].(^i16)^ = cast(i16)mem.ptr_sub(ie, ic)
								case 0: out_ptrs[written_ptrs].(^i32)^ = cast(i32)mem.ptr_sub(ie, ic)
								case 2: out_ptrs[written_ptrs].(^i64)^ = cast(i64)mem.ptr_sub(ie, ic)
								case: return
							}
							written_ptrs += 1 //TODO(Rennorb) @correctness: should in theory not increment this, but whatever

						case 'a', 'A', 'e', 'E', 'f', 'F', 'g', 'G':
							c = c[1:]
							// TODO(Rennorb) @correctness: width is ignored for now
							f, l, ok := strconv.parse_f64_prefix(string_from_se(ic, ie)); if !ok { return }
							switch longness {
								case 0: out_ptrs[written_ptrs].(^f32)^ = f32(f)
								case 1: out_ptrs[written_ptrs].(^f64)^ = f
								case: return
							}
							written_ptrs += 1

							continue arg_loop

						case 'l':
							c = c[1:]
							longness += 1

						case 'h':
							c = c[1:]
							longness -= 1
					}
				}

			case ' ', '\t', '\n', 'r', '\f', '\v':
				c = c[1:]
				// "any single whitespace character in the format string consumes all available consecutive whitespace characters from the input"
				whitespace_loop: for ic < ie {
					switch ic[0] {
						case ' ', '\t', '\n', 'r', '\f', '\v': ic = ic[1:]
						case: break whitespace_loop
					}
				}

			case:
				if c[0] != ic[0] { return } // non format specifiers should match
				c, ic = c[1:], ic[1:]
		}
	}
	return
}
