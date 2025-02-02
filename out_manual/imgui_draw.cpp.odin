package imgui

// dear imgui, v1.91.7 WIP
// (drawing and font code)

/*

Index of this file:

// [SECTION] STB libraries implementation
// [SECTION] Style functions
// [SECTION] ImDrawList
// [SECTION] ImTriangulator, ImDrawList concave polygon fill
// [SECTION] ImDrawListSplitter
// [SECTION] ImDrawData
// [SECTION] Helpers ShadeVertsXXX functions
// [SECTION] ImFontConfig
// [SECTION] ImFontAtlas
// [SECTION] ImFontAtlas: glyph ranges helpers
// [SECTION] ImFontGlyphRangesBuilder
// [SECTION] ImFont
// [SECTION] ImGui Internal Render Helpers
// [SECTION] Decompression code
// [SECTION] Default font data (ProggyClean.ttf)

*/

import stbtt "vendor:stb/truetype"
import stbrp "vendor:stb/rect_pack"
import "core:math"
import "core:math/linalg"
import "core:slice"
import "core:mem"
import "core:bytes"
import "base:runtime"


//-----------------------------------------------------------------------------
// [SECTION] Style functions
//-----------------------------------------------------------------------------

// [forward declared comment]:
// new, recommended style (default)
StyleColorsDark :: proc(dst : ^ImGuiStyle = nil)
{
    style := dst != nil ? dst : GetStyle();
    colors := &style.Colors;

    colors[.Text]                   = ImVec4{1.00, 1.00, 1.00, 1.00};
    colors[.TextDisabled]           = ImVec4{0.50, 0.50, 0.50, 1.00};
    colors[.WindowBg]               = ImVec4{0.06, 0.06, 0.06, 0.94};
    colors[.ChildBg]                = ImVec4{0.00, 0.00, 0.00, 0.00};
    colors[.PopupBg]                = ImVec4{0.08, 0.08, 0.08, 0.94};
    colors[.Border]                 = ImVec4{0.43, 0.43, 0.50, 0.50};
    colors[.BorderShadow]           = ImVec4{0.00, 0.00, 0.00, 0.00};
    colors[.FrameBg]                = ImVec4{0.16, 0.29, 0.48, 0.54};
    colors[.FrameBgHovered]         = ImVec4{0.26, 0.59, 0.98, 0.40};
    colors[.FrameBgActive]          = ImVec4{0.26, 0.59, 0.98, 0.67};
    colors[.TitleBg]                = ImVec4{0.04, 0.04, 0.04, 1.00};
    colors[.TitleBgActive]          = ImVec4{0.16, 0.29, 0.48, 1.00};
    colors[.TitleBgCollapsed]       = ImVec4{0.00, 0.00, 0.00, 0.51};
    colors[.MenuBarBg]              = ImVec4{0.14, 0.14, 0.14, 1.00};
    colors[.ScrollbarBg]            = ImVec4{0.02, 0.02, 0.02, 0.53};
    colors[.ScrollbarGrab]          = ImVec4{0.31, 0.31, 0.31, 1.00};
    colors[.ScrollbarGrabHovered]   = ImVec4{0.41, 0.41, 0.41, 1.00};
    colors[.ScrollbarGrabActive]    = ImVec4{0.51, 0.51, 0.51, 1.00};
    colors[.CheckMark]              = ImVec4{0.26, 0.59, 0.98, 1.00};
    colors[.SliderGrab]             = ImVec4{0.24, 0.52, 0.88, 1.00};
    colors[.SliderGrabActive]       = ImVec4{0.26, 0.59, 0.98, 1.00};
    colors[.Button]                 = ImVec4{0.26, 0.59, 0.98, 0.40};
    colors[.ButtonHovered]          = ImVec4{0.26, 0.59, 0.98, 1.00};
    colors[.ButtonActive]           = ImVec4{0.06, 0.53, 0.98, 1.00};
    colors[.Header]                 = ImVec4{0.26, 0.59, 0.98, 0.31};
    colors[.HeaderHovered]          = ImVec4{0.26, 0.59, 0.98, 0.80};
    colors[.HeaderActive]           = ImVec4{0.26, 0.59, 0.98, 1.00};
    colors[.Separator]              = colors[.Border];
    colors[.SeparatorHovered]       = ImVec4{0.10, 0.40, 0.75, 0.78};
    colors[.SeparatorActive]        = ImVec4{0.10, 0.40, 0.75, 1.00};
    colors[.ResizeGrip]             = ImVec4{0.26, 0.59, 0.98, 0.20};
    colors[.ResizeGripHovered]      = ImVec4{0.26, 0.59, 0.98, 0.67};
    colors[.ResizeGripActive]       = ImVec4{0.26, 0.59, 0.98, 0.95};
    colors[.TabHovered]             = colors[.HeaderHovered];
    colors[.Tab]                    = ImLerp(colors[.Header],       colors[.TitleBgActive], 0.80);
    colors[.TabSelected]            = ImLerp(colors[.HeaderActive], colors[.TitleBgActive], 0.60);
    colors[.TabSelectedOverline]    = colors[.HeaderActive];
    colors[.TabDimmed]              = ImLerp(colors[.Tab],          colors[.TitleBg], 0.80);
    colors[.TabDimmedSelected]      = ImLerp(colors[.TabSelected],  colors[.TitleBg], 0.40);
    colors[.TabDimmedSelectedOverline] = ImVec4{0.50, 0.50, 0.50, 0.00};
    colors[.DockingPreview]         = colors[.HeaderActive] * ImVec4{1.0, 1.0, 1.0, 0.7};
    colors[.DockingEmptyBg]         = ImVec4{0.20, 0.20, 0.20, 1.00};
    colors[.PlotLines]              = ImVec4{0.61, 0.61, 0.61, 1.00};
    colors[.PlotLinesHovered]       = ImVec4{1.00, 0.43, 0.35, 1.00};
    colors[.PlotHistogram]          = ImVec4{0.90, 0.70, 0.00, 1.00};
    colors[.PlotHistogramHovered]   = ImVec4{1.00, 0.60, 0.00, 1.00};
    colors[.TableHeaderBg]          = ImVec4{0.19, 0.19, 0.20, 1.00};
    colors[.TableBorderStrong]      = ImVec4{0.31, 0.31, 0.35, 1.00};   // Prefer using Alpha=1.0 here
    colors[.TableBorderLight]       = ImVec4{0.23, 0.23, 0.25, 1.00};   // Prefer using Alpha=1.0 here
    colors[.TableRowBg]             = ImVec4{0.00, 0.00, 0.00, 0.00};
    colors[.TableRowBgAlt]          = ImVec4{1.00, 1.00, 1.00, 0.06};
    colors[.TextLink]               = colors[.HeaderActive];
    colors[.TextSelectedBg]         = ImVec4{0.26, 0.59, 0.98, 0.35};
    colors[.DragDropTarget]         = ImVec4{1.00, 1.00, 0.00, 0.90};
    colors[.NavCursor]              = ImVec4{0.26, 0.59, 0.98, 1.00};
    colors[.NavWindowingHighlight]  = ImVec4{1.00, 1.00, 1.00, 0.70};
    colors[.NavWindowingDimBg]      = ImVec4{0.80, 0.80, 0.80, 0.20};
    colors[.ModalWindowDimBg]       = ImVec4{0.80, 0.80, 0.80, 0.35};
}

// [forward declared comment]:
// classic imgui style
StyleColorsClassic :: proc(dst : ^ImGuiStyle = nil)
{
    style := dst != nil ? dst : GetStyle();
    colors := &style.Colors;

    colors[.Text]                   = ImVec4{0.90, 0.90, 0.90, 1.00};
    colors[.TextDisabled]           = ImVec4{0.60, 0.60, 0.60, 1.00};
    colors[.WindowBg]               = ImVec4{0.00, 0.00, 0.00, 0.85};
    colors[.ChildBg]                = ImVec4{0.00, 0.00, 0.00, 0.00};
    colors[.PopupBg]                = ImVec4{0.11, 0.11, 0.14, 0.92};
    colors[.Border]                 = ImVec4{0.50, 0.50, 0.50, 0.50};
    colors[.BorderShadow]           = ImVec4{0.00, 0.00, 0.00, 0.00};
    colors[.FrameBg]                = ImVec4{0.43, 0.43, 0.43, 0.39};
    colors[.FrameBgHovered]         = ImVec4{0.47, 0.47, 0.69, 0.40};
    colors[.FrameBgActive]          = ImVec4{0.42, 0.41, 0.64, 0.69};
    colors[.TitleBg]                = ImVec4{0.27, 0.27, 0.54, 0.83};
    colors[.TitleBgActive]          = ImVec4{0.32, 0.32, 0.63, 0.87};
    colors[.TitleBgCollapsed]       = ImVec4{0.40, 0.40, 0.80, 0.20};
    colors[.MenuBarBg]              = ImVec4{0.40, 0.40, 0.55, 0.80};
    colors[.ScrollbarBg]            = ImVec4{0.20, 0.25, 0.30, 0.60};
    colors[.ScrollbarGrab]          = ImVec4{0.40, 0.40, 0.80, 0.30};
    colors[.ScrollbarGrabHovered]   = ImVec4{0.40, 0.40, 0.80, 0.40};
    colors[.ScrollbarGrabActive]    = ImVec4{0.41, 0.39, 0.80, 0.60};
    colors[.CheckMark]              = ImVec4{0.90, 0.90, 0.90, 0.50};
    colors[.SliderGrab]             = ImVec4{1.00, 1.00, 1.00, 0.30};
    colors[.SliderGrabActive]       = ImVec4{0.41, 0.39, 0.80, 0.60};
    colors[.Button]                 = ImVec4{0.35, 0.40, 0.61, 0.62};
    colors[.ButtonHovered]          = ImVec4{0.40, 0.48, 0.71, 0.79};
    colors[.ButtonActive]           = ImVec4{0.46, 0.54, 0.80, 1.00};
    colors[.Header]                 = ImVec4{0.40, 0.40, 0.90, 0.45};
    colors[.HeaderHovered]          = ImVec4{0.45, 0.45, 0.90, 0.80};
    colors[.HeaderActive]           = ImVec4{0.53, 0.53, 0.87, 0.80};
    colors[.Separator]              = ImVec4{0.50, 0.50, 0.50, 0.60};
    colors[.SeparatorHovered]       = ImVec4{0.60, 0.60, 0.70, 1.00};
    colors[.SeparatorActive]        = ImVec4{0.70, 0.70, 0.90, 1.00};
    colors[.ResizeGrip]             = ImVec4{1.00, 1.00, 1.00, 0.10};
    colors[.ResizeGripHovered]      = ImVec4{0.78, 0.82, 1.00, 0.60};
    colors[.ResizeGripActive]       = ImVec4{0.78, 0.82, 1.00, 0.90};
    colors[.TabHovered]             = colors[.HeaderHovered];
    colors[.Tab]                    = ImLerp(colors[.Header],       colors[.TitleBgActive], 0.80);
    colors[.TabSelected]            = ImLerp(colors[.HeaderActive], colors[.TitleBgActive], 0.60);
    colors[.TabSelectedOverline]    = colors[.HeaderActive];
    colors[.TabDimmed]              = ImLerp(colors[.Tab],          colors[.TitleBg], 0.80);
    colors[.TabDimmedSelected]      = ImLerp(colors[.TabSelected],  colors[.TitleBg], 0.40);
    colors[.TabDimmedSelectedOverline] = ImVec4{0.53, 0.53, 0.87, 0.00};
    colors[.DockingPreview]         = colors[.Header] * ImVec4{1.0, 1.0, 1.0, 0.7};
    colors[.DockingEmptyBg]         = ImVec4{0.20, 0.20, 0.20, 1.00};
    colors[.PlotLines]              = ImVec4{1.00, 1.00, 1.00, 1.00};
    colors[.PlotLinesHovered]       = ImVec4{0.90, 0.70, 0.00, 1.00};
    colors[.PlotHistogram]          = ImVec4{0.90, 0.70, 0.00, 1.00};
    colors[.PlotHistogramHovered]   = ImVec4{1.00, 0.60, 0.00, 1.00};
    colors[.TableHeaderBg]          = ImVec4{0.27, 0.27, 0.38, 1.00};
    colors[.TableBorderStrong]      = ImVec4{0.31, 0.31, 0.45, 1.00};   // Prefer using Alpha=1.0 here
    colors[.TableBorderLight]       = ImVec4{0.26, 0.26, 0.28, 1.00};   // Prefer using Alpha=1.0 here
    colors[.TableRowBg]             = ImVec4{0.00, 0.00, 0.00, 0.00};
    colors[.TableRowBgAlt]          = ImVec4{1.00, 1.00, 1.00, 0.07};
    colors[.TextLink]               = colors[.HeaderActive];
    colors[.TextSelectedBg]         = ImVec4{0.00, 0.00, 1.00, 0.35};
    colors[.DragDropTarget]         = ImVec4{1.00, 1.00, 0.00, 0.90};
    colors[.NavCursor]              = colors[.HeaderHovered];
    colors[.NavWindowingHighlight]  = ImVec4{1.00, 1.00, 1.00, 0.70};
    colors[.NavWindowingDimBg]      = ImVec4{0.80, 0.80, 0.80, 0.20};
    colors[.ModalWindowDimBg]       = ImVec4{0.20, 0.20, 0.20, 0.35};
}

// Those light colors are better suited with a thicker font than the default one + FrameBorder
// [forward declared comment]:
// best used with borders and a custom, thicker font
StyleColorsLight :: proc(dst : ^ImGuiStyle = nil)
{
    style := dst != nil ? dst : GetStyle();
    colors := &style.Colors;

    colors[.Text]                   = ImVec4{0.00, 0.00, 0.00, 1.00};
    colors[.TextDisabled]           = ImVec4{0.60, 0.60, 0.60, 1.00};
    colors[.WindowBg]               = ImVec4{0.94, 0.94, 0.94, 1.00};
    colors[.ChildBg]                = ImVec4{0.00, 0.00, 0.00, 0.00};
    colors[.PopupBg]                = ImVec4{1.00, 1.00, 1.00, 0.98};
    colors[.Border]                 = ImVec4{0.00, 0.00, 0.00, 0.30};
    colors[.BorderShadow]           = ImVec4{0.00, 0.00, 0.00, 0.00};
    colors[.FrameBg]                = ImVec4{1.00, 1.00, 1.00, 1.00};
    colors[.FrameBgHovered]         = ImVec4{0.26, 0.59, 0.98, 0.40};
    colors[.FrameBgActive]          = ImVec4{0.26, 0.59, 0.98, 0.67};
    colors[.TitleBg]                = ImVec4{0.96, 0.96, 0.96, 1.00};
    colors[.TitleBgActive]          = ImVec4{0.82, 0.82, 0.82, 1.00};
    colors[.TitleBgCollapsed]       = ImVec4{1.00, 1.00, 1.00, 0.51};
    colors[.MenuBarBg]              = ImVec4{0.86, 0.86, 0.86, 1.00};
    colors[.ScrollbarBg]            = ImVec4{0.98, 0.98, 0.98, 0.53};
    colors[.ScrollbarGrab]          = ImVec4{0.69, 0.69, 0.69, 0.80};
    colors[.ScrollbarGrabHovered]   = ImVec4{0.49, 0.49, 0.49, 0.80};
    colors[.ScrollbarGrabActive]    = ImVec4{0.49, 0.49, 0.49, 1.00};
    colors[.CheckMark]              = ImVec4{0.26, 0.59, 0.98, 1.00};
    colors[.SliderGrab]             = ImVec4{0.26, 0.59, 0.98, 0.78};
    colors[.SliderGrabActive]       = ImVec4{0.46, 0.54, 0.80, 0.60};
    colors[.Button]                 = ImVec4{0.26, 0.59, 0.98, 0.40};
    colors[.ButtonHovered]          = ImVec4{0.26, 0.59, 0.98, 1.00};
    colors[.ButtonActive]           = ImVec4{0.06, 0.53, 0.98, 1.00};
    colors[.Header]                 = ImVec4{0.26, 0.59, 0.98, 0.31};
    colors[.HeaderHovered]          = ImVec4{0.26, 0.59, 0.98, 0.80};
    colors[.HeaderActive]           = ImVec4{0.26, 0.59, 0.98, 1.00};
    colors[.Separator]              = ImVec4{0.39, 0.39, 0.39, 0.62};
    colors[.SeparatorHovered]       = ImVec4{0.14, 0.44, 0.80, 0.78};
    colors[.SeparatorActive]        = ImVec4{0.14, 0.44, 0.80, 1.00};
    colors[.ResizeGrip]             = ImVec4{0.35, 0.35, 0.35, 0.17};
    colors[.ResizeGripHovered]      = ImVec4{0.26, 0.59, 0.98, 0.67};
    colors[.ResizeGripActive]       = ImVec4{0.26, 0.59, 0.98, 0.95};
    colors[.TabHovered]             = colors[.HeaderHovered];
    colors[.Tab]                    = ImLerp(colors[.Header],       colors[.TitleBgActive], 0.90);
    colors[.TabSelected]            = ImLerp(colors[.HeaderActive], colors[.TitleBgActive], 0.60);
    colors[.TabSelectedOverline]    = colors[.HeaderActive];
    colors[.TabDimmed]              = ImLerp(colors[.Tab],          colors[.TitleBg], 0.80);
    colors[.TabDimmedSelected]      = ImLerp(colors[.TabSelected],  colors[.TitleBg], 0.40);
    colors[.TabDimmedSelectedOverline] = ImVec4{0.26, 0.59, 1.00, 0.00};
    colors[.DockingPreview]         = colors[.Header] * ImVec4{1.0, 1.0, 1.0, 0.7};
    colors[.DockingEmptyBg]         = ImVec4{0.20, 0.20, 0.20, 1.00};
    colors[.PlotLines]              = ImVec4{0.39, 0.39, 0.39, 1.00};
    colors[.PlotLinesHovered]       = ImVec4{1.00, 0.43, 0.35, 1.00};
    colors[.PlotHistogram]          = ImVec4{0.90, 0.70, 0.00, 1.00};
    colors[.PlotHistogramHovered]   = ImVec4{1.00, 0.45, 0.00, 1.00};
    colors[.TableHeaderBg]          = ImVec4{0.78, 0.87, 0.98, 1.00};
    colors[.TableBorderStrong]      = ImVec4{0.57, 0.57, 0.64, 1.00};   // Prefer using Alpha=1.0 here
    colors[.TableBorderLight]       = ImVec4{0.68, 0.68, 0.74, 1.00};   // Prefer using Alpha=1.0 here
    colors[.TableRowBg]             = ImVec4{0.00, 0.00, 0.00, 0.00};
    colors[.TableRowBgAlt]          = ImVec4{0.30, 0.30, 0.30, 0.09};
    colors[.TextLink]               = colors[.HeaderActive];
    colors[.TextSelectedBg]         = ImVec4{0.26, 0.59, 0.98, 0.35};
    colors[.DragDropTarget]         = ImVec4{0.26, 0.59, 0.98, 0.95};
    colors[.NavCursor]              = colors[.HeaderHovered];
    colors[.NavWindowingHighlight]  = ImVec4{0.70, 0.70, 0.70, 0.70};
    colors[.NavWindowingDimBg]      = ImVec4{0.20, 0.20, 0.20, 0.20};
    colors[.ModalWindowDimBg]       = ImVec4{0.20, 0.20, 0.20, 0.35};
}

//-----------------------------------------------------------------------------
// [SECTION] ImDrawList
//-----------------------------------------------------------------------------

init_ImDrawListSharedData :: proc(this : ^ImDrawListSharedData)
{
    this^ = {}
    for i := 0; i < len(this.ArcFastVtx); i += 1
    {
        a : f32 = (f32(i) * 2 * IM_PI) / f32(len(this.ArcFastVtx));
        this.ArcFastVtx[i] = ImVec2{math.cos(a), math.sin(a)};
    }
    this.ArcFastRadiusCutoff = IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R(IM_DRAWLIST_ARCFAST_SAMPLE_MAX, this.CircleSegmentMaxError);
}

SetCircleTessellationMaxError :: proc(this : ^ImDrawListSharedData, max_error : f32)
{
    if (this.CircleSegmentMaxError == max_error)  do return;

    assert(max_error > 0.0);
    this.CircleSegmentMaxError = max_error;
    for i := 0; i < len(this.CircleSegmentCounts); i += 1
    {
        radius := f32(i);
        this.CircleSegmentCounts[i] = u8((i > 0) ? IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(radius, this.CircleSegmentMaxError) : IM_DRAWLIST_ARCFAST_SAMPLE_MAX);
    }
    this.ArcFastRadiusCutoff = IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R(IM_DRAWLIST_ARCFAST_SAMPLE_MAX, this.CircleSegmentMaxError);
}

init_ImDrawList :: proc(this : ^ImDrawList, shared_data : ^ImDrawListSharedData)
{
    this^ = {}
    this._Data = shared_data;
}

deinit_ImDrawList :: proc(this : ^ImDrawList)
{
    _ClearFreeMemory(this);
}

// Initialize before use in a new frame. We always have a command ready in the buffer.
// In the majority of cases, you would want to call PushClipRect() and PushTextureID() after this.
_ResetForNewFrame :: proc(this : ^ImDrawList)
{
    // Verify that the ImDrawCmd fields we want to memcmp() are contiguous in memory.
    #assert(offset_of(ImDrawCmd, ClipRect) == 0);
    #assert(offset_of(ImDrawCmd, TextureId) == size_of(ImVec4));
    #assert(offset_of(ImDrawCmd, VtxOffset) == size_of(ImVec4) + size_of(ImTextureID));
    if (this._Splitter._Count > 1)   do Merge(&this._Splitter, this)

    clear(&this.CmdBuffer)
    clear(&this.IdxBuffer)
    clear(&this.VtxBuffer)
    this.Flags = this._Data.InitialFlags;
    this._CmdHeader = {}
    this._VtxCurrentIdx = 0;
    this._VtxWritePtr = nil;
    this._IdxWritePtr = nil;
    clear(&this._ClipRectStack)
    clear(&this._TextureIdStack)
    clear(&this._CallbacksDataBuf)
    clear(&this._Path)
    clear(&this._Splitter)
    append(&this.CmdBuffer, ImDrawCmd{})
    this._FringeScale = 1.0;
}

ImDrawList_ClearFreeMemory :: proc(this : ^ImDrawList)
{
    clear(&this.CmdBuffer);
    clear(&this.IdxBuffer);
    clear(&this.VtxBuffer);
    this.Flags = nil;
    this._VtxCurrentIdx = 0;
    this._VtxWritePtr = nil;
    this._IdxWritePtr = nil;
    clear(&this._ClipRectStack);
    clear(&this._TextureIdStack);
    clear(&this._CallbacksDataBuf);
    clear(&this._Path);
    _ClearFreeMemory(&this._Splitter);
}

// [forward declared comment]:
// Create a clone of the CmdBuffer/IdxBuffer/VtxBuffer.
CloneOutput :: proc(this : ^ImDrawList) -> ^ImDrawList
{
    dst := IM_NEW(ImDrawList);
    init_ImDrawList(dst, this._Data)
    dst.CmdBuffer = this.CmdBuffer;
    dst.IdxBuffer = this.IdxBuffer;
    dst.VtxBuffer = this.VtxBuffer;
    dst.Flags = this.Flags;
    return dst;
}

// [forward declared comment]:
// This is useful if you need to forcefully create a new draw call (to allow for dependent rendering / blending). Otherwise primitives are merged into the same draw-call as much as possible
AddDrawCmd :: proc(this : ^ImDrawList)
{
    draw_cmd : ImDrawCmd
    draw_cmd.ClipRect = this._CmdHeader.ClipRect;    // Same as calling ImDrawCmd_HeaderCopy()
    draw_cmd.TextureId = this._CmdHeader.TextureId;
    draw_cmd.VtxOffset = this._CmdHeader.VtxOffset;
    draw_cmd.IdxOffset = cast(u32) len(this.IdxBuffer);

    assert(draw_cmd.ClipRect.x <= draw_cmd.ClipRect.z && draw_cmd.ClipRect.y <= draw_cmd.ClipRect.w);
    append(&this.CmdBuffer, draw_cmd);
}

// Pop trailing draw command (used before merging or presenting to user)
// Note that this leaves the ImDrawList in a state unfit for further commands, as most code assume that len(CmdBuffer) > 0 && CmdBuffer.back().UserCallback == NULL
_PopUnusedDrawCmd :: proc(this : ^ImDrawList)
{
    for (len(this.CmdBuffer) > 0)
    {
        curr_cmd := &this.CmdBuffer[len(this.CmdBuffer) - 1];
        if (curr_cmd.ElemCount != 0 || curr_cmd.UserCallback != nil)  do return;// break;
        pop(&this.CmdBuffer)
    }
}

AddCallback :: proc(this : ^ImDrawList, callback : ImDrawCallback, userdata : rawptr, userdata_size : int = {})
{
    IM_ASSERT_PARANOID(len(this.CmdBuffer) > 0);
    curr_cmd := &this.CmdBuffer[len(this.CmdBuffer) - 1];
    assert(curr_cmd.UserCallback == nil);
    if (curr_cmd.ElemCount != 0)
    {
        AddDrawCmd(this);
        curr_cmd = &this.CmdBuffer[len(this.CmdBuffer) - 1];
    }

    curr_cmd.UserCallback = callback;
    if (userdata_size == 0)
    {
        // Store user data directly in command (no indirection)
        curr_cmd.UserCallbackData = userdata;
        curr_cmd.UserCallbackDataSize = 0;
        curr_cmd.UserCallbackDataOffset = -1;
    }
    else
    {
        // Copy and store user data in a buffer
        assert(userdata != nil);
        assert(userdata_size < (1 << 31));
        curr_cmd.UserCallbackData = nil; // Will be resolved during Render()
        curr_cmd.UserCallbackDataSize = cast(i32) userdata_size;
        curr_cmd.UserCallbackDataOffset = cast(i32) len(this._CallbacksDataBuf)
        resize(&this._CallbacksDataBuf, len(this._CallbacksDataBuf) + userdata_size);
        memcpy(&this._CallbacksDataBuf[curr_cmd.UserCallbackDataOffset], userdata, userdata_size);
    }

    AddDrawCmd(this); // Force a new command after us (see comment below)
}

// Compare ClipRect, TextureId and VtxOffset with a single memcmp()
ImDrawCmd_HeaderSize :: cast(int)offset_of(ImDrawCmd, VtxOffset) + size_of(u32)
ImDrawCmd_HeaderCompare :: #force_inline proc(CMD_LHS, CMD_RHS : ^$T) -> bool { // Compare ClipRect, TextureId, VtxOffset
    return  memcmp(CMD_LHS, CMD_RHS, ImDrawCmd_HeaderSize) == 0
}
ImDrawCmd_HeaderCopy :: #force_inline proc(CMD_DST, CMD_SRC : ^$T)  { // Copy ClipRect, TextureId, VtxOffset
     memcpy(CMD_DST, CMD_SRC, ImDrawCmd_HeaderSize)
}
ImDrawCmd_AreSequentialIdxOffset :: #force_inline proc(CMD_0, CMD_1 : ^ImDrawCmd) -> bool {
    return  CMD_0.IdxOffset + CMD_0.ElemCount == CMD_1.IdxOffset
}

// Try to merge two last draw commands
_TryMergeDrawCmds :: proc(this : ^ImDrawList)
{
    IM_ASSERT_PARANOID(len(this.CmdBuffer) > 0);
    curr_cmd := back(this.CmdBuffer)
    prev_cmd := mem.ptr_offset(curr_cmd, -1);
    if (ImDrawCmd_HeaderCompare(curr_cmd, prev_cmd) && ImDrawCmd_AreSequentialIdxOffset(prev_cmd, curr_cmd) && curr_cmd.UserCallback == nil && prev_cmd.UserCallback == nil)
    {
        prev_cmd.ElemCount += curr_cmd.ElemCount;
        pop(&this.CmdBuffer)
    }
}

// Our scheme may appears a bit unusual, basically we want the most-common calls AddLine AddRect etc. to not have to perform any check so we always have a command ready in the stack.
// The cost of figuring out if a new command has to be added or if we can merge is paid in those Update** functions only.
_OnChangedClipRect :: proc(this : ^ImDrawList)
{
    // If current command is used with different settings we need to add a new command
    IM_ASSERT_PARANOID(len(this.CmdBuffer) > 0);
    curr_cmd := back(this.CmdBuffer)
    if (curr_cmd.ElemCount != 0 && memcmp(&curr_cmd.ClipRect, &this._CmdHeader.ClipRect, size_of(ImVec4)) != 0)
    {
        AddDrawCmd(this);
        return;
    }
    assert(curr_cmd.UserCallback == nil);

    // Try to merge with previous command if it matches, else use current command
    prev_cmd := mem.ptr_offset(curr_cmd, -1);
    if (curr_cmd.ElemCount == 0 && len(this.CmdBuffer) > 1 && ImDrawCmd_HeaderCompare(&this._CmdHeader, cast(^ImDrawCmdHeader) prev_cmd) && ImDrawCmd_AreSequentialIdxOffset(prev_cmd, curr_cmd) && prev_cmd.UserCallback == nil)
    {
        pop(&this.CmdBuffer)
        return;
    }
    curr_cmd.ClipRect = this._CmdHeader.ClipRect;
}

_OnChangedTextureID :: proc(this : ^ImDrawList)
{
    // If current command is used with different settings we need to add a new command
    IM_ASSERT_PARANOID(len(this.CmdBuffer) > 0);
    curr_cmd := back(this.CmdBuffer)
    if (curr_cmd.ElemCount != 0 && curr_cmd.TextureId != this._CmdHeader.TextureId)
    {
        AddDrawCmd(this);
        return;
    }
    assert(curr_cmd.UserCallback == nil);

    // Try to merge with previous command if it matches, else use current command
    prev_cmd := mem.ptr_offset(curr_cmd, -1);
    if (curr_cmd.ElemCount == 0 && len(this.CmdBuffer) > 1 && ImDrawCmd_HeaderCompare(&this._CmdHeader, cast(^ImDrawCmdHeader) prev_cmd) && ImDrawCmd_AreSequentialIdxOffset(prev_cmd, curr_cmd) && prev_cmd.UserCallback == nil)
    {
        pop(&this.CmdBuffer)
        return;
    }
    curr_cmd.TextureId = this._CmdHeader.TextureId;
}

_OnChangedVtxOffset :: proc(this : ^ImDrawList)
{
    // We don't need to compare curr_cmd.VtxOffset != _CmdHeader.VtxOffset because we know it'll be different at the time we call this.
    this._VtxCurrentIdx = 0;
    IM_ASSERT_PARANOID(len(this.CmdBuffer) > 0)
    curr_cmd := back(this.CmdBuffer)
    //assert(curr_cmd.VtxOffset != _CmdHeader.VtxOffset); // See #3349
    if (curr_cmd.ElemCount != 0)
    {
        AddDrawCmd(this);
        return;
    }
    assert(curr_cmd.UserCallback == nil);
    curr_cmd.VtxOffset = this._CmdHeader.VtxOffset;
}

_CalcCircleAutoSegmentCount :: proc(this : ^ImDrawList, radius : f32) -> i32
{
    // Automatic segment count
    radius_idx := (i32)(radius + 0.999999); // ceil to never reduce accuracy
    if (radius_idx >= 0 && radius_idx < len(this._Data.CircleSegmentCounts)) {
        return i32(this._Data.CircleSegmentCounts[radius_idx]); // Use cached value
    }
    else {
        return cast(i32) IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(radius, this._Data.CircleSegmentMaxError);
    }
}

// Render-level scissoring. This is passed down to your render function but not used for CPU-side coarse clipping. Prefer using higher-level ImGui::PushClipRect() to affect logic (hit-testing and widget culling)
// [forward declared comment]:
// Render-level scissoring. This is passed down to your render function but not used for CPU-side coarse clipping. Prefer using higher-level ImGui::PushClipRect() to affect logic (hit-testing and widget culling)
ImDrawList_PushClipRect :: proc(this : ^ImDrawList, cr_min : ImVec2, cr_max : ImVec2, intersect_with_current_clip_rect : bool = false)
{
    cr := ImVec4{cr_min.x, cr_min.y, cr_max.x, cr_max.y};
    if (intersect_with_current_clip_rect)
    {
        current := this._CmdHeader.ClipRect;
        if (cr.x < current.x) do cr.x = current.x;
        if (cr.y < current.y) do cr.y = current.y;
        if (cr.z > current.z) do cr.z = current.z;
        if (cr.w > current.w) do cr.w = current.w;
    }
    cr.z = ImMax(cr.x, cr.z);
    cr.w = ImMax(cr.y, cr.w);

    append(&this._ClipRectStack, cr);
    this._CmdHeader.ClipRect = cr;
    _OnChangedClipRect(this);
}

PushClipRectFullScreen :: proc(this : ^ImDrawList)
{
    PushClipRect(this._Data.ClipRectFullscreen.xy, this._Data.ClipRectFullscreen.zw);
}

ImDrawList_PopClipRect :: proc(this : ^ImDrawList)
{
    pop(&this._ClipRectStack)
    this._CmdHeader.ClipRect = (len(this._ClipRectStack) == 0) ? this._Data.ClipRectFullscreen : back(this._ClipRectStack)^
    _OnChangedClipRect(this);
}

PushTextureID :: proc(this : ^ImDrawList, texture_id : ImTextureID)
{
    append(&this._TextureIdStack, texture_id)
    this._CmdHeader.TextureId = texture_id;
    _OnChangedTextureID(this);
}

PopTextureID :: proc(this : ^ImDrawList)
{
    pop(&this._TextureIdStack)
    this._CmdHeader.TextureId = (len(this._TextureIdStack) == 0) ? ImTextureID(0) : back(this._TextureIdStack)^;
    _OnChangedTextureID(this);
}

// This is used by ImGui::PushFont()/PopFont(). It works because we never use _TextureIdStack[] elsewhere than in PushTextureID()/PopTextureID().
_SetTextureID :: proc(this : ^ImDrawList, texture_id : ImTextureID)
{
    if (this._CmdHeader.TextureId == texture_id)   do return
    this._CmdHeader.TextureId = texture_id;
    _OnChangedTextureID(this);
}

// Reserve space for a number of vertices and indices.
// You must finish filling your reserved data before calling PrimReserve() again, as it may reallocate or
// submit the intermediate results. PrimUnreserve() can be used to release unused allocations.
PrimReserve :: proc(this : ^ImDrawList, idx_count : i32, vtx_count : i32)
{
    // Large mesh support (when enabled)
    IM_ASSERT_PARANOID(idx_count >= 0 && vtx_count >= 0);
    if (size_of(ImDrawIdx) == 2 && (this._VtxCurrentIdx + u32(vtx_count) >= (1 << 16)) && (.AllowVtxOffset in this.Flags))
    {
        // FIXME: In theory we should be testing that vtx_count <64k here.
        // In practice, RenderText() relies on reserving ahead for a worst case scenario so it is currently useful for us
        // to not make that check until we rework the text functions to handle clipping and large horizontal lines better.
        this._CmdHeader.VtxOffset = cast(u32) len(this.VtxBuffer)
        _OnChangedVtxOffset(this);
    }

    draw_cmd := back(this.CmdBuffer);
    draw_cmd.ElemCount += u32(idx_count);

    vtx_buffer_old_size := len(this.VtxBuffer)
    resize(&this.VtxBuffer, vtx_buffer_old_size + int(vtx_count));
    this._VtxWritePtr = raw_data(this.VtxBuffer)[vtx_buffer_old_size:];

    idx_buffer_old_size := len(this.IdxBuffer)
    resize(&this.IdxBuffer, idx_buffer_old_size + int(idx_count));
    this._IdxWritePtr = raw_data(this.IdxBuffer)[idx_buffer_old_size:];
}

// Release the number of reserved vertices/indices from the end of the last reservation made with PrimReserve().
PrimUnreserve :: proc(this : ^ImDrawList, idx_count : i32, vtx_count : i32)
{
    IM_ASSERT_PARANOID(idx_count >= 0 && vtx_count >= 0);

    draw_cmd := back(this.CmdBuffer);
    draw_cmd.ElemCount -= u32(idx_count);
    shrink_by(&this.VtxBuffer, int(vtx_count));
    shrink_by(&this.IdxBuffer, int(idx_count));
}

// Fully unrolled with inline call to keep our debug builds decently fast.
// [forward declared comment]:
// Axis aligned rectangle (composed of two triangles)
PrimRect :: proc(this : ^ImDrawList, a : ImVec2, c : ImVec2, col : u32)
{
    b := ImVec2{c.x, a.y}
    d := ImVec2{a.x, c.y}
    uv := ImVec2(this._Data.TexUvWhitePixel)
    idx := ImDrawIdx(this._VtxCurrentIdx)
    this._IdxWritePtr[0] = idx; this._IdxWritePtr[1] = ImDrawIdx(idx+1); this._IdxWritePtr[2] = ImDrawIdx(idx+2);
    this._IdxWritePtr[3] = idx; this._IdxWritePtr[4] = ImDrawIdx(idx+2); this._IdxWritePtr[5] = ImDrawIdx(idx+3);
    this._VtxWritePtr[0].pos = a; this._VtxWritePtr[0].uv = uv; this._VtxWritePtr[0].col = col;
    this._VtxWritePtr[1].pos = b; this._VtxWritePtr[1].uv = uv; this._VtxWritePtr[1].col = col;
    this._VtxWritePtr[2].pos = c; this._VtxWritePtr[2].uv = uv; this._VtxWritePtr[2].col = col;
    this._VtxWritePtr[3].pos = d; this._VtxWritePtr[3].uv = uv; this._VtxWritePtr[3].col = col;
    this._VtxWritePtr = this._VtxWritePtr[4:];
    this._VtxCurrentIdx += 4;
    this._IdxWritePtr = this._IdxWritePtr[6:];
}

PrimRectUV :: proc(this : ^ImDrawList, a : ImVec2, c : ImVec2, uv_a : ImVec2, uv_c : ImVec2, col : u32)
{
    b := ImVec2{c.x, a.y}
    d := ImVec2{a.x, c.y}
    uv_b := ImVec2{uv_c.x, uv_a.y}
    uv_d := ImVec2{uv_a.x, uv_c.y}
    idx := ImDrawIdx(this._VtxCurrentIdx);
    this._IdxWritePtr[0] = idx; this._IdxWritePtr[1] = ImDrawIdx(idx+1); this._IdxWritePtr[2] = ImDrawIdx(idx+2);
    this._IdxWritePtr[3] = idx; this._IdxWritePtr[4] = ImDrawIdx(idx+2); this._IdxWritePtr[5] = ImDrawIdx(idx+3);
    this._VtxWritePtr[0].pos = a; this._VtxWritePtr[0].uv = uv_a; this._VtxWritePtr[0].col = col;
    this._VtxWritePtr[1].pos = b; this._VtxWritePtr[1].uv = uv_b; this._VtxWritePtr[1].col = col;
    this._VtxWritePtr[2].pos = c; this._VtxWritePtr[2].uv = uv_c; this._VtxWritePtr[2].col = col;
    this._VtxWritePtr[3].pos = d; this._VtxWritePtr[3].uv = uv_d; this._VtxWritePtr[3].col = col;
    this._VtxWritePtr = this._VtxWritePtr[4:];
    this._VtxCurrentIdx += 4;
    this._IdxWritePtr = this._IdxWritePtr[6:];
}

PrimQuadUV :: proc(this : ^ImDrawList, a : ImVec2, b : ImVec2, c : ImVec2, d : ImVec2, uv_a : ImVec2, uv_b : ImVec2, uv_c : ImVec2, uv_d : ImVec2, col : u32)
{
    idx := ImDrawIdx(this._VtxCurrentIdx);
    this._IdxWritePtr[0] = idx; this._IdxWritePtr[1] = ImDrawIdx(idx+1); this._IdxWritePtr[2] = ImDrawIdx(idx+2);
    this._IdxWritePtr[3] = idx; this._IdxWritePtr[4] = ImDrawIdx(idx+2); this._IdxWritePtr[5] = ImDrawIdx(idx+3);
    this._VtxWritePtr[0].pos = a; this._VtxWritePtr[0].uv = uv_a; this._VtxWritePtr[0].col = col;
    this._VtxWritePtr[1].pos = b; this._VtxWritePtr[1].uv = uv_b; this._VtxWritePtr[1].col = col;
    this._VtxWritePtr[2].pos = c; this._VtxWritePtr[2].uv = uv_c; this._VtxWritePtr[2].col = col;
    this._VtxWritePtr[3].pos = d; this._VtxWritePtr[3].uv = uv_d; this._VtxWritePtr[3].col = col;
    this._VtxWritePtr = this._VtxWritePtr[4:];
    this._VtxCurrentIdx += 4;
    this._IdxWritePtr = this._IdxWritePtr[6:];
}

// On AddPolyline() and AddConvexPolyFilled() we intentionally avoid using ImVec2 and superfluous function calls to optimize debug/non-inlined builds.
// - Those macros expects l-values and need to be used as their own statement.
// - Those macros are intentionally not surrounded by the 'do {} while (0)' idiom because even that translates to runtime with debug compilers.
IM_NORMALIZE2F_OVER_ZERO :: proc(v: ^[2]f32) {
    d2 := linalg.length2(v^);
    if (d2 > 0.0) {
        v^ *= linalg.inverse_sqrt(d2);
    }
}
IM_FIXNORMAL2F_MAX_INVLEN2 :: 100.0 // 500.0f (see #4053, #3366)
IM_FIXNORMAL2F :: proc(v : ^[2]f32) {
    d2 := linalg.length2(v^);
    if (d2 > 0.000001) {
        inv_len2 : = 1.0 / d2;
        if (inv_len2 > IM_FIXNORMAL2F_MAX_INVLEN2) do inv_len2 = IM_FIXNORMAL2F_MAX_INVLEN2;
        v^ *= inv_len2;
    }
}

// TODO: Thickness anti-aliased lines cap are missing their AA fringe.
// We avoid using the ImVec2 math operators here to reduce cost to a minimum for debug/non-inlined builds.
AddPolyline :: proc(this : ^ImDrawList, points : [^]ImVec2, points_count : i32, col : u32, flags : ImDrawFlags, thickness : f32)
{
    thickness := thickness

    if (points_count < 2 || (col & IM_COL32_A_MASK) == 0)   do return

    closed := .Closed in flags;
    opaque_uv := this._Data.TexUvWhitePixel;
    count := closed ? points_count : points_count - 1; // The number of line segments we need to draw
    thick_line := (thickness > this._FringeScale);

    if (.AntiAliasedLines in this.Flags)
    {
        // Anti-aliased stroke
        AA_SIZE := this._FringeScale;
        col_trans := col & ~IM_COL32_A_MASK;

        // Thicknesses <1.0 should behave like thickness 1.0
        thickness = ImMax(thickness, 1.0);
        integer_thickness := cast(i32) thickness;
        fractional_thickness := thickness - f32(integer_thickness);

        // Do we want to draw this line using a texture?
        // - For now, only draw integer-width lines using textures to avoid issues with the way scaling occurs, could be improved.
        // - If AA_SIZE is not 1.0f we cannot use the texture path.
        use_texture := (.AntiAliasedLinesUseTex in this.Flags) && (integer_thickness < IM_DRAWLIST_TEX_LINES_WIDTH_MAX) && (fractional_thickness <= 0.00001) && (AA_SIZE == 1.0);

        // We should never hit this, because NewFrame() doesn't set ImDrawListFlags_AntiAliasedLinesUseTex unless ImFontAtlasFlags_NoBakedLines is off
        IM_ASSERT_PARANOID(!use_texture || !(.NoBakedLines in this._Data.Font.ContainerAtlas.Flags));

        idx_count := use_texture ? (count * 6) : (thick_line ? count * 18 : count * 12);
        vtx_count := use_texture ? (points_count * 2) : (thick_line ? points_count * 4 : points_count * 3);
        PrimReserve(this, idx_count, vtx_count);

        // Temporary buffer
        // The first <points_count> items are normals at each line point, then after that there are either 2 or 4 temp points for each line point
        reserve_discard(&this._Data.TempBuffer, cast(int) points_count * ((use_texture || !thick_line) ? 3 : 5));
        temp_normals := raw_data(this._Data.TempBuffer)
        temp_points := temp_normals[points_count:];

        // Calculate normals (tangents) for each line segment
        for i1 : i32 = 0; i1 < count; i1 += 1
        {
            i2 := (i1 + 1) == points_count ? 0 : i1 + 1;
            d := points[i2] - points[i1];
            IM_NORMALIZE2F_OVER_ZERO(&d);
            temp_normals[i1].x = d.y;
            temp_normals[i1].y = -d.x;
        }
        if (!closed) {
            temp_normals[points_count - 1] = temp_normals[points_count - 2];
        }

        // If we are drawing a one-pixel-wide line without a texture, or a textured line of any width, we only need 2 or 3 vertices per point
        if (use_texture || !thick_line)
        {
            // [PATH 1] Texture-based lines (thick or non-thick)
            // [PATH 2] Non texture-based lines (non-thick)

            // The width of the geometry we need to draw - this is essentially <thickness> pixels for the line itself, plus "one pixel" for AA.
            // - In the texture-based path, we don't use AA_SIZE here because the +1 is tied to the generated texture
            //   (see ImFontAtlasBuildRenderLinesTexData() function), and so alternate values won't work without changes to that code.
            // - In the non texture-based paths, we would allow AA_SIZE to potentially be != 1.0f with a patch (e.g. fringe_scale patch to
            //   allow scaling geometry while preserving one-screen-pixel AA fringe).
            half_draw_size := use_texture ? ((thickness * 0.5) + 1) : AA_SIZE;

            // If line is not closed, the first and last points need to be generated differently as there are no normals to blend
            if (!closed)
            {
                temp_points[0] = points[0] + temp_normals[0] * half_draw_size;
                temp_points[1] = points[0] - temp_normals[0] * half_draw_size;
                temp_points[(points_count-1)*2+0] = points[points_count-1] + temp_normals[points_count-1] * half_draw_size;
                temp_points[(points_count-1)*2+1] = points[points_count-1] - temp_normals[points_count-1] * half_draw_size;
            }

            // Generate the indices to form a number of triangles for each line segment, and the vertices for the line edges
            // This takes points n and n+1 and writes into n+1, with the first point in a closed line being generated from the final one (as n+1 wraps)
            // FIXME-OPT: Merge the different loops, possibly remove the temporary buffer.
            idx1 := this._VtxCurrentIdx; // Vertex index for start of line segment
            for i1 : i32 = 0; i1 < count; i1 += 1 // i1 is the first point of the line segment
            {
                i2 := (i1 + 1) == points_count ? 0 : i1 + 1; // i2 is the second point of the line segment
                idx2 := ((i1 + 1) == points_count) ? this._VtxCurrentIdx : (idx1 + (use_texture ? 2 : 3)); // Vertex index for end of segment

                // Average normals
                dm := (temp_normals[i1] + temp_normals[i2]) * 0.5;
                IM_FIXNORMAL2F(&dm);
                dm *= half_draw_size; // dm_x, dm_y are offset to the outer edge of the AA area

                // Add temporary vertexes for the outer edges
                out_vtx := temp_points[i2 * 2:];
                out_vtx[0] = points[i2] + dm;
                out_vtx[1] = points[i2] - dm;

                if (use_texture)
                {
                    // Add indices for two triangles
                    this._IdxWritePtr[0] = ImDrawIdx(idx2 + 0); this._IdxWritePtr[1] = ImDrawIdx(idx1 + 0); this._IdxWritePtr[2] = ImDrawIdx(idx1 + 1); // Right tri
                    this._IdxWritePtr[3] = ImDrawIdx(idx2 + 1); this._IdxWritePtr[4] = ImDrawIdx(idx1 + 1); this._IdxWritePtr[5] = ImDrawIdx(idx2 + 0); // Left tri
                    this._IdxWritePtr = this._IdxWritePtr[6:];
                }
                else
                {
                    // Add indexes for four triangles
                    this._IdxWritePtr[0] = ImDrawIdx(idx2 + 0); this._IdxWritePtr[1] = ImDrawIdx(idx1 + 0); this._IdxWritePtr[2] = ImDrawIdx(idx1 + 2); // Right tri 1
                    this._IdxWritePtr[3] = ImDrawIdx(idx1 + 2); this._IdxWritePtr[4] = ImDrawIdx(idx2 + 2); this._IdxWritePtr[5] = ImDrawIdx(idx2 + 0); // Right tri 2
                    this._IdxWritePtr[6] = ImDrawIdx(idx2 + 1); this._IdxWritePtr[7] = ImDrawIdx(idx1 + 1); this._IdxWritePtr[8] = ImDrawIdx(idx1 + 0); // Left tri 1
                    this._IdxWritePtr[9] = ImDrawIdx(idx1 + 0); this._IdxWritePtr[10] = ImDrawIdx(idx2 + 0); this._IdxWritePtr[11] = ImDrawIdx(idx2 + 1); // Left tri 2
                    this._IdxWritePtr = this._IdxWritePtr[12:];
                }

                idx1 = idx2;
            }

            // Add vertexes for each point on the line
            if (use_texture)
            {
                // If we're using textures we only need to emit the left/right edge vertices
                tex_uvs := this._Data.TexUvLines[integer_thickness];
                /*if (fractional_thickness != 0.0) // Currently always zero when use_texture==false!
                {
                    tex_uvs_1 := _Data.TexUvLines[integer_thickness + 1];
                    tex_uvs.x = tex_uvs.x + (tex_uvs_1.x - tex_uvs.x) * fractional_thickness; // inlined ImLerp()
                    tex_uvs.y = tex_uvs.y + (tex_uvs_1.y - tex_uvs.y) * fractional_thickness;
                    tex_uvs.z = tex_uvs.z + (tex_uvs_1.z - tex_uvs.z) * fractional_thickness;
                    tex_uvs.w = tex_uvs.w + (tex_uvs_1.w - tex_uvs.w) * fractional_thickness;
                }*/
                tex_uv0 := ImVec2{tex_uvs.x, tex_uvs.y};
                tex_uv1 := ImVec2{tex_uvs.z, tex_uvs.w};
                for i : i32 = 0; i < points_count; i += 1
                {
                    this._VtxWritePtr[0].pos = temp_points[i * 2 + 0]; this._VtxWritePtr[0].uv = tex_uv0; this._VtxWritePtr[0].col = col; // Left-side outer edge
                    this._VtxWritePtr[1].pos = temp_points[i * 2 + 1]; this._VtxWritePtr[1].uv = tex_uv1; this._VtxWritePtr[1].col = col; // Right-side outer edge
                    this._VtxWritePtr = this._VtxWritePtr[2:];
                }
            }
            else
            {
                // If we're not using a texture, we need the center vertex as well
                for i : i32 = 0; i < points_count; i += 1
                {
                    this._VtxWritePtr[0].pos = points[i];              this._VtxWritePtr[0].uv = opaque_uv; this._VtxWritePtr[0].col = col;       // Center of line
                    this._VtxWritePtr[1].pos = temp_points[i * 2 + 0]; this._VtxWritePtr[1].uv = opaque_uv; this._VtxWritePtr[1].col = col_trans; // Left-side outer edge
                    this._VtxWritePtr[2].pos = temp_points[i * 2 + 1]; this._VtxWritePtr[2].uv = opaque_uv; this._VtxWritePtr[2].col = col_trans; // Right-side outer edge
                    this._VtxWritePtr = this._VtxWritePtr[3:];
                }
            }
        }
        else
        {
            // [PATH 2] Non texture-based lines (thick): we need to draw the solid line core and thus require four vertices per point
            half_inner_thickness := (thickness - AA_SIZE) * 0.5;

            // If line is not closed, the first and last points need to be generated differently as there are no normals to blend
            if (!closed)
            {
                points_last := points_count - 1;
                temp_points[0] = points[0] + temp_normals[0] * (half_inner_thickness + AA_SIZE);
                temp_points[1] = points[0] + temp_normals[0] * (half_inner_thickness);
                temp_points[2] = points[0] - temp_normals[0] * (half_inner_thickness);
                temp_points[3] = points[0] - temp_normals[0] * (half_inner_thickness + AA_SIZE);
                temp_points[points_last * 4 + 0] = points[points_last] + temp_normals[points_last] * (half_inner_thickness + AA_SIZE);
                temp_points[points_last * 4 + 1] = points[points_last] + temp_normals[points_last] * (half_inner_thickness);
                temp_points[points_last * 4 + 2] = points[points_last] - temp_normals[points_last] * (half_inner_thickness);
                temp_points[points_last * 4 + 3] = points[points_last] - temp_normals[points_last] * (half_inner_thickness + AA_SIZE);
            }

            // Generate the indices to form a number of triangles for each line segment, and the vertices for the line edges
            // This takes points n and n+1 and writes into n+1, with the first point in a closed line being generated from the final one (as n+1 wraps)
            // FIXME-OPT: Merge the different loops, possibly remove the temporary buffer.
            idx1 := this._VtxCurrentIdx; // Vertex index for start of line segment
            for i1 : i32 = 0; i1 < count; i1 += 1 // i1 is the first point of the line segment
            {
                i2 := (i1 + 1) == points_count ? 0 : (i1 + 1); // i2 is the second point of the line segment
                idx2 := (i1 + 1) == points_count ? this._VtxCurrentIdx : (idx1 + 4); // Vertex index for end of segment

                // Average normals
                dm := (temp_normals[i1] + temp_normals[i2]) * 0.5;
                IM_FIXNORMAL2F(&dm);
                dm_out := dm * (half_inner_thickness + AA_SIZE);
                dm_in := dm * half_inner_thickness;

                // Add temporary vertices
                out_vtx := temp_points[i2 * 4:];
                out_vtx[0] = points[i2] + dm_out;
                out_vtx[1] = points[i2] + dm_in;
                out_vtx[2] = points[i2] - dm_in;
                out_vtx[3] = points[i2] - dm_out;

                // Add indexes
                this._IdxWritePtr[0]  = ImDrawIdx(idx2 + 1); this._IdxWritePtr[1]  = ImDrawIdx(idx1 + 1); this._IdxWritePtr[2]  = ImDrawIdx(idx1 + 2);
                this._IdxWritePtr[3]  = ImDrawIdx(idx1 + 2); this._IdxWritePtr[4]  = ImDrawIdx(idx2 + 2); this._IdxWritePtr[5]  = ImDrawIdx(idx2 + 1);
                this._IdxWritePtr[6]  = ImDrawIdx(idx2 + 1); this._IdxWritePtr[7]  = ImDrawIdx(idx1 + 1); this._IdxWritePtr[8]  = ImDrawIdx(idx1 + 0);
                this._IdxWritePtr[9]  = ImDrawIdx(idx1 + 0); this._IdxWritePtr[10] = ImDrawIdx(idx2 + 0); this._IdxWritePtr[11] = ImDrawIdx(idx2 + 1);
                this._IdxWritePtr[12] = ImDrawIdx(idx2 + 2); this._IdxWritePtr[13] = ImDrawIdx(idx1 + 2); this._IdxWritePtr[14] = ImDrawIdx(idx1 + 3);
                this._IdxWritePtr[15] = ImDrawIdx(idx1 + 3); this._IdxWritePtr[16] = ImDrawIdx(idx2 + 3); this._IdxWritePtr[17] = ImDrawIdx(idx2 + 2);
                this._IdxWritePtr = this._IdxWritePtr[18:];

                idx1 = idx2;
            }

            // Add vertices
            for i : i32 = 0; i < points_count; i += 1
            {
                this._VtxWritePtr[0].pos = temp_points[i * 4 + 0]; this._VtxWritePtr[0].uv = opaque_uv; this._VtxWritePtr[0].col = col_trans;
                this._VtxWritePtr[1].pos = temp_points[i * 4 + 1]; this._VtxWritePtr[1].uv = opaque_uv; this._VtxWritePtr[1].col = col;
                this._VtxWritePtr[2].pos = temp_points[i * 4 + 2]; this._VtxWritePtr[2].uv = opaque_uv; this._VtxWritePtr[2].col = col;
                this._VtxWritePtr[3].pos = temp_points[i * 4 + 3]; this._VtxWritePtr[3].uv = opaque_uv; this._VtxWritePtr[3].col = col_trans;
                this._VtxWritePtr = this._VtxWritePtr[4:];
            }
        }
        this._VtxCurrentIdx += u32(vtx_count);
    }
    else
    {
        // [PATH 4] Non texture-based, Non anti-aliased lines
        idx_count := count * 6;
        vtx_count := count * 4;    // FIXME-OPT: Not sharing edges
        PrimReserve(this, idx_count, vtx_count);

        for i1 : i32 = 0; i1 < count; i1 += 1
        {
            i2 := (i1 + 1) == points_count ? 0 : i1 + 1;
            p1 := points[i1];
            p2 := points[i2];

            d := p2 - p1;
            IM_NORMALIZE2F_OVER_ZERO(&d);
            d *= (thickness * 0.5);

            this._VtxWritePtr[0].pos.x = p1.x + d.y; this._VtxWritePtr[0].pos.y = p1.y - d.x; this._VtxWritePtr[0].uv = opaque_uv; this._VtxWritePtr[0].col = col;
            this._VtxWritePtr[1].pos.x = p2.x + d.y; this._VtxWritePtr[1].pos.y = p2.y - d.x; this._VtxWritePtr[1].uv = opaque_uv; this._VtxWritePtr[1].col = col;
            this._VtxWritePtr[2].pos.x = p2.x - d.y; this._VtxWritePtr[2].pos.y = p2.y + d.x; this._VtxWritePtr[2].uv = opaque_uv; this._VtxWritePtr[2].col = col;
            this._VtxWritePtr[3].pos.x = p1.x - d.y; this._VtxWritePtr[3].pos.y = p1.y + d.x; this._VtxWritePtr[3].uv = opaque_uv; this._VtxWritePtr[3].col = col;
            this._VtxWritePtr = this._VtxWritePtr[4:];

            this._IdxWritePtr[0] = ImDrawIdx(this._VtxCurrentIdx); this._IdxWritePtr[1] = ImDrawIdx(this._VtxCurrentIdx + 1); this._IdxWritePtr[2] = ImDrawIdx(this._VtxCurrentIdx + 2);
            this._IdxWritePtr[3] = ImDrawIdx(this._VtxCurrentIdx); this._IdxWritePtr[4] = ImDrawIdx(this._VtxCurrentIdx + 2); this._IdxWritePtr[5] = ImDrawIdx(this._VtxCurrentIdx + 3);
            this._IdxWritePtr = this._IdxWritePtr[6:];
            this._VtxCurrentIdx += 4;
        }
    }
}

// - We intentionally avoid using ImVec2 and its math operators here to reduce cost to a minimum for debug/non-inlined builds.
// - Filled shapes must always use clockwise winding order. The anti-aliasing fringe depends on it. Counter-clockwise shapes will have "inward" anti-aliasing.
AddConvexPolyFilled :: proc(this : ^ImDrawList, points : [^]ImVec2, points_count : i32, col : u32)
{
    if (points_count < 3 || (col & IM_COL32_A_MASK) == 0)   do return

    uv := this._Data.TexUvWhitePixel;

    if (.AntiAliasedFill in this.Flags)
    {
        // Anti-aliased Fill
        AA_SIZE := this._FringeScale;
        col_trans := col & ~IM_COL32_A_MASK;
        idx_count := (points_count - 2)*3 + points_count * 6;
        vtx_count := (points_count * 2);
        PrimReserve(this, idx_count, vtx_count);

        // Add indexes for fill
        vtx_inner_idx := this._VtxCurrentIdx;
        vtx_outer_idx := this._VtxCurrentIdx + 1;
        for i : u32 = 2; i < u32(points_count); i += 1
        {
            this._IdxWritePtr[0] = ImDrawIdx(vtx_inner_idx);
            this._IdxWritePtr[1] = ImDrawIdx(vtx_inner_idx + ((i - 1) << 1)); 
            this._IdxWritePtr[2] = ImDrawIdx(vtx_inner_idx + (i << 1));
            this._IdxWritePtr = this._IdxWritePtr[3:];
        }

        // Compute normals
        reserve_discard(&this._Data.TempBuffer, int(points_count));
        temp_normals := raw_data(this._Data.TempBuffer);
        for i0, i1 := points_count - 1, i32(0); i1 < points_count; i0, i1 = i1, i1 + 1
        {
            p0 := points[i0];
            p1 := points[i1];
            d := p1 - p0;
            IM_NORMALIZE2F_OVER_ZERO(&d);
            temp_normals[i0].x = d.y;
            temp_normals[i0].y = -d.x;
        }

        for i0, i1 := points_count - 1, i32(0); i1 < points_count; i0, i1 = i1, i1 + 1
        {
            // Average normals
            n0 := temp_normals[i0];
            n1 := temp_normals[i1];
            dm := (n0 + n1) * 0.5;
            IM_FIXNORMAL2F(&dm);
            dm *= AA_SIZE * 0.5;

            // Add vertices
            this._VtxWritePtr[0].pos.x = (points[i1].x - dm.x); this._VtxWritePtr[0].pos.y = (points[i1].y - dm.y); this._VtxWritePtr[0].uv = uv; this._VtxWritePtr[0].col = col;        // Inner
            this._VtxWritePtr[1].pos.x = (points[i1].x + dm.x); this._VtxWritePtr[1].pos.y = (points[i1].y + dm.y); this._VtxWritePtr[1].uv = uv; this._VtxWritePtr[1].col = col_trans;  // Outer
            this._VtxWritePtr = this._VtxWritePtr[2:];

            // Add indexes for fringes
            this._IdxWritePtr[0] = ImDrawIdx(i32(vtx_inner_idx) + (i1 << 1)); this._IdxWritePtr[1] = ImDrawIdx(i32(vtx_inner_idx) + (i0 << 1)); this._IdxWritePtr[2] = ImDrawIdx(i32(vtx_outer_idx) + (i0 << 1));
            this._IdxWritePtr[3] = ImDrawIdx(i32(vtx_outer_idx) + (i0 << 1)); this._IdxWritePtr[4] = ImDrawIdx(i32(vtx_outer_idx) + (i1 << 1)); this._IdxWritePtr[5] = ImDrawIdx(i32(vtx_inner_idx) + (i1 << 1));
            this._IdxWritePtr = this._IdxWritePtr[6:];
        }
        this._VtxCurrentIdx += u32(vtx_count);
    }
    else
    {
        // Non Anti-aliased Fill
        idx_count := (points_count - 2)*3;
        vtx_count := points_count;
        PrimReserve(this, idx_count, vtx_count);
        for i : i32 = 0; i < vtx_count; i += 1
        {
            this._VtxWritePtr[0].pos = points[i]; this._VtxWritePtr[0].uv = uv; this._VtxWritePtr[0].col = col;
            this._VtxWritePtr = this._VtxWritePtr[1:];
        }
        for i : i32 = 2; i < points_count; i += 1
        {
            this._IdxWritePtr[0] = ImDrawIdx(this._VtxCurrentIdx); this._IdxWritePtr[1] = ImDrawIdx(i32(this._VtxCurrentIdx) + i - 1); this._IdxWritePtr[2] = ImDrawIdx(i32(this._VtxCurrentIdx) + i);
            this._IdxWritePtr = this._IdxWritePtr[3:];
        }
        this._VtxCurrentIdx += u32(vtx_count);
    }
}

_PathArcToFastEx :: proc(this : ^ImDrawList, center : ImVec2, radius : f32, a_min_sample : i32, a_max_sample : i32, a_step : i32)
{
    if (radius < 0.5)
    {
        append(&this._Path, center)
        return;
    }

    a_step := a_step

    // Calculate arc auto segment step size
    if (a_step <= 0)  do a_step = IM_DRAWLIST_ARCFAST_SAMPLE_MAX / _CalcCircleAutoSegmentCount(this, radius);

    // Make sure we never do steps larger than one quarter of the circle
    a_step = ImClamp(a_step, 1, IM_DRAWLIST_ARCFAST_TABLE_SIZE / 4);

    sample_range := ImAbs(a_max_sample - a_min_sample);
    a_next_step := a_step;

    samples := sample_range + 1;
    extra_max_sample := false;
    if (a_step > 1)
    {
        samples            = sample_range / a_step + 1;
        overstep := sample_range % a_step;

        if (overstep > 0)
        {
            extra_max_sample = true;
            samples += 1;

            // When we have overstep to avoid awkwardly looking one long line and one tiny one at the end,
            // distribute first step range evenly between them by reducing first step size.
            if (sample_range > 0) do a_step -= (a_step - overstep) / 2;
        }
    }

    resize(&this._Path, len(this._Path) + int(samples));
    out_ptr := raw_data(this._Path)[len(this._Path) - int(samples):];

    sample_index := a_min_sample;
    if (sample_index < 0 || sample_index >= IM_DRAWLIST_ARCFAST_SAMPLE_MAX)
    {
        sample_index = sample_index % IM_DRAWLIST_ARCFAST_SAMPLE_MAX;
        if (sample_index < 0) do sample_index += IM_DRAWLIST_ARCFAST_SAMPLE_MAX;
    }

    if (a_max_sample >= a_min_sample)
    {
        for a := a_min_sample; a <= a_max_sample;  a, sample_index, a_step = a + a_step, sample_index + a_step, a_next_step
        {
            // a_step is clamped to IM_DRAWLIST_ARCFAST_SAMPLE_MAX, so we have guaranteed that it will not wrap over range twice or more
            if (sample_index >= IM_DRAWLIST_ARCFAST_SAMPLE_MAX)  do sample_index -= IM_DRAWLIST_ARCFAST_SAMPLE_MAX;

            s := this._Data.ArcFastVtx[sample_index];
            out_ptr[0] = center + s * radius;
            out_ptr = out_ptr[1:];
        }
    }
    else
    {
        for a := a_min_sample; a >= a_max_sample; a, sample_index, a_step = a - a_step, sample_index - a_step, a_next_step
        {
            // a_step is clamped to IM_DRAWLIST_ARCFAST_SAMPLE_MAX, so we have guaranteed that it will not wrap over range twice or more
            if (sample_index < 0) do sample_index += IM_DRAWLIST_ARCFAST_SAMPLE_MAX;

            s := this._Data.ArcFastVtx[sample_index];
            out_ptr[0] = center + s * radius;
            out_ptr = out_ptr[1:];
        }
    }

    if (extra_max_sample)
    {
        normalized_max_sample := a_max_sample % IM_DRAWLIST_ARCFAST_SAMPLE_MAX;
        if (normalized_max_sample < 0) {
            normalized_max_sample += IM_DRAWLIST_ARCFAST_SAMPLE_MAX;
        }

        s := this._Data.ArcFastVtx[normalized_max_sample];
        out_ptr[0] = center + s * radius;
        out_ptr = out_ptr[1:];
    }

    IM_ASSERT_PARANOID(end(this._Path) == out_ptr);
}

_PathArcToN :: proc(this : ^ImDrawList, center : ImVec2, radius : f32, a_min : f32, a_max : f32, num_segments : i32)
{
    if (radius < 0.5)
    {
        append(&this._Path, center);
        return;
    }

    // Note that we are adding a point at both a_min and a_max.
    // If you are trying to draw a full closed circle you don't want the overlapping points!
    reserve(&this._Path, len(this._Path) + int(num_segments + 1));
    for i : i32 = 0; i <= num_segments; i += 1
    {
        a := a_min + (cast(f32) i / cast(f32) num_segments) * (a_max - a_min);
        append(&this._Path, ImVec2{center.x + math.cos(a) * radius, center.y + math.sin(a) * radius});
    }
}

// 0: East, 3: South, 6: West, 9: North, 12: East
// [forward declared comment]:
// Use precomputed angles for a 12 steps circle
PathArcToFast :: proc(this : ^ImDrawList, center : ImVec2, radius : f32, a_min_of_12 : i32, a_max_of_12 : i32)
{
    if (radius < 0.5)
    {
        append(&this._Path, center);
        return;
    }
    _PathArcToFastEx(this, center, radius, a_min_of_12 * IM_DRAWLIST_ARCFAST_SAMPLE_MAX / 12, a_max_of_12 * IM_DRAWLIST_ARCFAST_SAMPLE_MAX / 12, 0);
}

PathArcTo :: proc(this : ^ImDrawList, center : ImVec2, radius : f32, a_min : f32, a_max : f32, num_segments : i32 = 0)
{
    if (radius < 0.5)
    {
        append(&this._Path, center);
        return;
    }

    if (num_segments > 0)
    {
        _PathArcToN(this, center, radius, a_min, a_max, num_segments);
        return;
    }

    // Automatic segment count
    if (radius <= this._Data.ArcFastRadiusCutoff)
    {
        a_is_reverse := a_max < a_min;

        // We are going to use precomputed values for mid samples.
        // Determine first and last sample in lookup table that belong to the arc.
        a_min_sample_f := IM_DRAWLIST_ARCFAST_SAMPLE_MAX * a_min / (IM_PI * 2.0);
        a_max_sample_f := IM_DRAWLIST_ARCFAST_SAMPLE_MAX * a_max / (IM_PI * 2.0);

        a_min_sample := a_is_reverse ? cast(i32) ImFloor(a_min_sample_f) : cast(i32) ImCeil(a_min_sample_f);
        a_max_sample := a_is_reverse ? cast(i32) ImCeil(a_max_sample_f) : cast(i32) ImFloor(a_max_sample_f);
        a_mid_samples := a_is_reverse ? ImMax(a_min_sample - a_max_sample, 0) : ImMax(a_max_sample - a_min_sample, 0);

        a_min_segment_angle := f32(a_min_sample) * IM_PI * 2.0 / IM_DRAWLIST_ARCFAST_SAMPLE_MAX;
        a_max_segment_angle := f32(a_max_sample) * IM_PI * 2.0 / IM_DRAWLIST_ARCFAST_SAMPLE_MAX;
        a_emit_start := ImAbs(a_min_segment_angle - a_min) >= 1e-5;
        a_emit_end := ImAbs(a_max - a_max_segment_angle) >= 1e-5;

        reserve(&this._Path, len(this._Path) + int(a_mid_samples + 1 + (a_emit_start ? 1 : 0) + (a_emit_end ? 1 : 0)));
        if (a_emit_start) do append(&this._Path, ImVec2{center.x + math.cos(a_min) * radius, center.y + math.sin(a_min) * radius});
        if (a_mid_samples > 0) do _PathArcToFastEx(this, center, radius, a_min_sample, a_max_sample, 0);
        if (a_emit_end) do append(&this._Path, ImVec2{center.x + math.cos(a_max) * radius, center.y + math.sin(a_max) * radius});
    }
    else
    {
        arc_length := ImAbs(a_max - a_min);
        circle_segment_count := _CalcCircleAutoSegmentCount(this, radius);
        arc_segment_count := ImMax(cast(i32) ImCeil(f32(circle_segment_count) * arc_length / (IM_PI * 2.0)), (i32)(2.0 * IM_PI / arc_length));
        _PathArcToN(this, center, radius, a_min, a_max, arc_segment_count);
    }
}

// [forward declared comment]:
// Ellipse
PathEllipticalArcTo :: proc(this : ^ImDrawList, center : ImVec2, radius : ImVec2, rot : f32, a_min : f32, a_max : f32, num_segments : i32 = 0)
{
    num_segments := num_segments

    if (num_segments <= 0) {
        num_segments = _CalcCircleAutoSegmentCount(this, ImMax(radius.x, radius.y)); // A bit pessimistic, maybe there's a better computation to do here.
    }

    reserve(&this._Path, len(this._Path) + int(num_segments + 1));

    cos_rot := math.cos(rot);
    sin_rot := math.sin(rot);
    for i : i32 = 0; i <= num_segments; i += 1
    {
        a := a_min + (cast(f32) i / cast(f32) num_segments) * (a_max - a_min);
        point := ImVec2{math.cos(a) * radius.x, math.sin(a) * radius.y};
        rel := ImVec2{(point.x * cos_rot) - (point.y * sin_rot), (point.x * sin_rot) + (point.y * cos_rot)};
        point.x = rel.x + center.x;
        point.y = rel.y + center.y;
        append(&this._Path, point);
    }
}

ImBezierCubicCalc :: proc(p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, p4 : ImVec2, t : f32) -> ImVec2
{
    u := 1.0 - t;
    w1 := u * u * u;
    w2 := 3 * u * u * t;
    w3 := 3 * u * t * t;
    w4 := t * t * t;
    return ImVec2{w1 * p1.x + w2 * p2.x + w3 * p3.x + w4 * p4.x, w1 * p1.y + w2 * p2.y + w3 * p3.y + w4 * p4.y};
}

ImBezierQuadraticCalc :: proc(p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, t : f32) -> ImVec2
{
    u := 1.0 - t;
    w1 := u * u;
    w2 := 2 * u * t;
    w3 := t * t;
    return ImVec2{w1 * p1.x + w2 * p2.x + w3 * p3.x, w1 * p1.y + w2 * p2.y + w3 * p3.y};
}

// Closely mimics ImBezierCubicClosestPointCasteljau() in imgui.cpp
PathBezierCubicCurveToCasteljau :: proc(path : ^[dynamic]ImVec2, x1 : f32, y1 : f32, x2 : f32, y2 : f32, x3 : f32, y3 : f32, x4 : f32, y4 : f32, tess_tol : f32, level : i32)
{
    dx := x4 - x1;
    dy := y4 - y1;
    d2 := (x2 - x4) * dy - (y2 - y4) * dx;
    d3 := (x3 - x4) * dy - (y3 - y4) * dx;
    d2 = (d2 >= 0) ? d2 : -d2;
    d3 = (d3 >= 0) ? d3 : -d3;
    if ((d2 + d3) * (d2 + d3) < tess_tol * (dx * dx + dy * dy))
    {
        append(path, ImVec2{x4, y4});
    }
    else if (level < 10)
    {
        x12   := (x1   + x2)   * 0.5; y12   := (y1 + y2) * 0.5;
        x23   := (x2   + x3)   * 0.5; y23   := (y2 + y3) * 0.5;
        x34   := (x3   + x4)   * 0.5; y34   := (y3 + y4) * 0.5;
        x123  := (x12  + x23)  * 0.5; y123  := (y12 + y23) * 0.5;
        x234  := (x23  + x34)  * 0.5; y234  := (y23 + y34) * 0.5;
        x1234 := (x123 + x234) * 0.5; y1234 := (y123 + y234) * 0.5;
        PathBezierCubicCurveToCasteljau(path, x1, y1, x12, y12, x123, y123, x1234, y1234, tess_tol, level + 1);
        PathBezierCubicCurveToCasteljau(path, x1234, y1234, x234, y234, x34, y34, x4, y4, tess_tol, level + 1);
    }
}

PathBezierQuadraticCurveToCasteljau :: proc(path : ^[dynamic]ImVec2, x1 : f32, y1 : f32, x2 : f32, y2 : f32, x3 : f32, y3 : f32, tess_tol : f32, level : i32)
{
    dx := x3 - x1; dy := y3 - y1;
    det := (x2 - x3) * dy - (y2 - y3) * dx;
    if (det * det * 4.0 < tess_tol * (dx * dx + dy * dy))
    {
        append(path, ImVec2{x3, y3});
    }
    else if (level < 10)
    {
        x12 := (x1 + x2) * 0.5; y12 := (y1 + y2) * 0.5;
        x23 := (x2 + x3) * 0.5; y23 := (y2 + y3) * 0.5;
        x123 := (x12 + x23) * 0.5; y123: = (y12 + y23) * 0.5;
        PathBezierQuadraticCurveToCasteljau(path, x1, y1, x12, y12, x123, y123, tess_tol, level + 1);
        PathBezierQuadraticCurveToCasteljau(path, x123, y123, x23, y23, x3, y3, tess_tol, level + 1);
    }
}

// [forward declared comment]:
// Cubic Bezier (4 control points)
PathBezierCubicCurveTo :: proc(this : ^ImDrawList, p2 : ImVec2, p3 : ImVec2, p4 : ImVec2, num_segments : i32 = 0)
{
    p1 := back(this._Path)^
    if (num_segments == 0)
    {
        assert(this._Data.CurveTessellationTol > 0.0);
        PathBezierCubicCurveToCasteljau(&this._Path, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y, this._Data.CurveTessellationTol, 0); // Auto-tessellated
    }
    else
    {
        t_step := 1.0 / cast(f32) num_segments;
        for i_step : i32 = 1; i_step <= num_segments; i_step += 1 {
            append(&this._Path, ImBezierCubicCalc(p1, p2, p3, p4, t_step * f32(i_step)));
        }
    }
}

// [forward declared comment]:
// Quadratic Bezier (3 control points)
PathBezierQuadraticCurveTo :: proc(this : ^ImDrawList, p2 : ImVec2, p3 : ImVec2, num_segments : i32 = 0)
{
    p1 := back(this._Path)^
    if (num_segments == 0)
    {
        assert(this._Data.CurveTessellationTol > 0.0);
        PathBezierQuadraticCurveToCasteljau(&this._Path, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, this._Data.CurveTessellationTol, 0);// Auto-tessellated
    }
    else
    {
        t_step := 1.0 / cast(f32) num_segments;
        for i_step : i32 = 1; i_step <= num_segments; i_step += 1 {
            append(&this._Path, ImBezierQuadraticCalc(p1, p2, p3, t_step * f32(i_step)));
        }
    }
}

FixRectCornerFlags :: #force_inline proc(flags : ImDrawFlags) -> ImDrawFlags
{
    /*
    #assert(ImDrawFlags_RoundCornersTopLeft == (1 << 4));
    */
    // If this assert triggers, please update your code replacing hardcoded values with new ImDrawFlags_RoundCorners* values.
    // Note that ImDrawFlags_Closed (== 0x01) is an invalid flag for AddRect(), AddRectFilled(), PathRect() etc. anyway.
    // See details in 1.82 Changelog as well as 2021/03/12 and 2023/09/08 entries in "API BREAKING CHANGES" section.
    assert((transmute(i32) flags & 0x0F) == 0, "Misuse of legacy hardcoded ImDrawCornerFlags values!");

    flags := flags
    if ((flags & ImDrawFlags_RoundCornersMask_) == nil) do flags |= ImDrawFlags_RoundCornersAll;

    return flags;
}

PathRect :: proc(this : ^ImDrawList, a : ImVec2, b : ImVec2, rounding : f32 = 0.0, flags : ImDrawFlags = {})
{
    flags := flags
    rounding := rounding

    if (rounding >= 0.5)
    {
        flags = FixRectCornerFlags(flags);
        rounding = ImMin(rounding, ImAbs(b.x - a.x) * (((flags & ImDrawFlags_RoundCornersTop) == ImDrawFlags_RoundCornersTop) || ((flags & ImDrawFlags_RoundCornersBottom) == ImDrawFlags_RoundCornersBottom) ? 0.5 : 1.0) - 1.0);
        rounding = ImMin(rounding, ImAbs(b.y - a.y) * (((flags & ImDrawFlags_RoundCornersLeft) == ImDrawFlags_RoundCornersLeft) || ((flags & ImDrawFlags_RoundCornersRight) == ImDrawFlags_RoundCornersRight) ? 0.5 : 1.0) - 1.0);
    }
    if (rounding < 0.5 || (flags & ImDrawFlags_RoundCornersMask_) == {ImDrawFlags.RoundCornersNone})
    {
        PathLineTo(this, a);
        PathLineTo(this, ImVec2{b.x, a.y});
        PathLineTo(this, b);
        PathLineTo(this, ImVec2{a.x, b.y});
    }
    else
    {
        rounding_tl := (.RoundCornersTopLeft     in flags) ? rounding : 0.0;
        rounding_tr := (.RoundCornersTopRight    in flags) ? rounding : 0.0;
        rounding_br := (.RoundCornersBottomRight in flags) ? rounding : 0.0;
        rounding_bl := (.RoundCornersBottomLeft  in flags) ? rounding : 0.0;
        PathArcToFast(this, ImVec2{a.x + rounding_tl, a.y + rounding_tl}, rounding_tl, 6, 9);
        PathArcToFast(this, ImVec2{b.x - rounding_tr, a.y + rounding_tr}, rounding_tr, 9, 12);
        PathArcToFast(this, ImVec2{b.x - rounding_br, b.y - rounding_br}, rounding_br, 0, 3);
        PathArcToFast(this, ImVec2{a.x + rounding_bl, b.y - rounding_bl}, rounding_bl, 3, 6);
    }
}

AddLine :: proc(this : ^ImDrawList, p1 : ImVec2, p2 : ImVec2, col : u32, thickness : f32 = 1.0)
{
    if ((col & IM_COL32_A_MASK) == 0)   do return
    PathLineTo(this, p1 + ImVec2{0.5, 0.5});
    PathLineTo(this, p2 + ImVec2{0.5, 0.5});
    PathStroke(this, col, nil, thickness);
}

// p_min = upper-left, p_max = lower-right
// Note we don't render 1 pixels sized rectangles properly.
// [forward declared comment]:
// a: upper-left, b: lower-right (== upper-left + size)
AddRect :: proc(this : ^ImDrawList, p_min : ImVec2, p_max : ImVec2, col : u32, rounding : f32 = 0.0, flags : ImDrawFlags = {}, thickness : f32 = 1)
{
    if ((col & IM_COL32_A_MASK) == 0)   do return
    if (.AntiAliasedLines in this.Flags) {
        PathRect(this, p_min + ImVec2{0.50, 0.50}, p_max - ImVec2{0.50, 0.50}, rounding, flags);
    }
    else {
        PathRect(this, p_min + ImVec2{0.50, 0.50}, p_max - ImVec2{0.49, 0.49}, rounding, flags); // Better looking lower-right corner and rounded non-AA shapes.
    }
    PathStroke(this, col, { .Closed }, thickness);
}

// [forward declared comment]:
// a: upper-left, b: lower-right (== upper-left + size)
AddRectFilled :: proc(this : ^ImDrawList, p_min : ImVec2, p_max : ImVec2, col : u32, rounding : f32 = 0.0, flags : ImDrawFlags = {})
{
    if ((col & IM_COL32_A_MASK) == 0)   do return
    if (rounding < 0.5 || (flags & ImDrawFlags_RoundCornersMask_) == { .RoundCornersNone })
    {
        PrimReserve(this, 6, 4);
        PrimRect(this, p_min, p_max, col);
    }
    else
    {
        PathRect(this, p_min, p_max, rounding, flags);
        PathFillConvex(this, col);
    }
}

// p_min = upper-left, p_max = lower-right
AddRectFilledMultiColor :: proc(this : ^ImDrawList, p_min : ImVec2, p_max : ImVec2, col_upr_left : u32, col_upr_right : u32, col_bot_right : u32, col_bot_left : u32)
{
    if (((col_upr_left | col_upr_right | col_bot_right | col_bot_left) & IM_COL32_A_MASK) == 0)   do return

    uv := this._Data.TexUvWhitePixel;
    PrimReserve(this, 6, 4);
    PrimWriteIdx(this, ImDrawIdx(this._VtxCurrentIdx)); PrimWriteIdx(this, ImDrawIdx(this._VtxCurrentIdx + 1)); PrimWriteIdx(this, ImDrawIdx(this._VtxCurrentIdx + 2));
    PrimWriteIdx(this, ImDrawIdx(this._VtxCurrentIdx)); PrimWriteIdx(this, ImDrawIdx(this._VtxCurrentIdx + 2)); PrimWriteIdx(this, ImDrawIdx(this._VtxCurrentIdx + 3));
    PrimWriteVtx(this, p_min, uv, col_upr_left);
    PrimWriteVtx(this, ImVec2{p_max.x, p_min.y}, uv, col_upr_right);
    PrimWriteVtx(this, p_max, uv, col_bot_right);
    PrimWriteVtx(this, ImVec2{p_min.x, p_max.y}, uv, col_bot_left);
}

AddQuad :: proc(this : ^ImDrawList, p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, p4 : ImVec2, col : u32, thickness : f32 = 1.0)
{
    if ((col & IM_COL32_A_MASK) == 0)   do return

    PathLineTo(this, p1);
    PathLineTo(this, p2);
    PathLineTo(this, p3);
    PathLineTo(this, p4);
    PathStroke(this, col, { .Closed }, thickness);
}

AddQuadFilled :: proc(this : ^ImDrawList, p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, p4 : ImVec2, col : u32)
{
    if ((col & IM_COL32_A_MASK) == 0)   do return

    PathLineTo(this, p1);
    PathLineTo(this, p2);
    PathLineTo(this, p3);
    PathLineTo(this, p4);
    PathFillConvex(this, col);
}

AddTriangle :: proc(this : ^ImDrawList, p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, col : u32, thickness : f32 = 1.0)
{
    if ((col & IM_COL32_A_MASK) == 0)   do return

    PathLineTo(this, p1);
    PathLineTo(this, p2);
    PathLineTo(this, p3);
    PathStroke(this, col, { .Closed }, thickness);
}

AddTriangleFilled :: proc(this : ^ImDrawList, p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, col : u32)
{
    if ((col & IM_COL32_A_MASK) == 0)   do return

    PathLineTo(this, p1);
    PathLineTo(this, p2);
    PathLineTo(this, p3);
    PathFillConvex(this, col);
}

AddCircle :: proc(this : ^ImDrawList, center : ImVec2, radius : f32, col : u32, num_segments : i32 = 0, thickness : f32 = 1.0)
{
    if ((col & IM_COL32_A_MASK) == 0 || radius < 0.5)   do return

    num_segments := num_segments
    if (num_segments <= 0)
    {
        // Use arc with automatic segment count
        _PathArcToFastEx(this, center, radius - 0.5, 0, IM_DRAWLIST_ARCFAST_SAMPLE_MAX, 0);
        raw := cast(^runtime.Raw_Dynamic_Array) (&this._Path)
        raw.len -= 1;
    }
    else
    {
        // Explicit segment count (still clamp to avoid drawing insanely tessellated shapes)
        num_segments = ImClamp(num_segments, 3, IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX);

        // Because we are filling a closed shape we remove 1 from the count of segments/points
        a_max := (IM_PI * 2.0) * (cast(f32) num_segments - 1.0) / cast(f32) num_segments;
        PathArcTo(this, center, radius - 0.5, 0.0, a_max, num_segments - 1);
    }

    PathStroke(this, col, { .Closed }, thickness);
}

AddCircleFilled :: proc(this : ^ImDrawList, center : ImVec2, radius : f32, col : u32, num_segments : i32 = 0)
{
    if ((col & IM_COL32_A_MASK) == 0 || radius < 0.5)   do return

    if (num_segments <= 0)
    {
        // Use arc with automatic segment count
        _PathArcToFastEx(this, center, radius, 0, IM_DRAWLIST_ARCFAST_SAMPLE_MAX, 0);
        raw := cast(^runtime.Raw_Dynamic_Array) (&this._Path)
        raw.len -= 1
    }
    else
    {
        // Explicit segment count (still clamp to avoid drawing insanely tessellated shapes)
        num_segments := ImClamp(num_segments, 3, IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX);

        // Because we are filling a closed shape we remove 1 from the count of segments/points
        a_max := (IM_PI * 2.0) * (cast(f32) num_segments - 1.0) / cast(f32) num_segments;
        PathArcTo(this, center, radius, 0.0, a_max, num_segments - 1);
    }

    PathFillConvex(this, col);
}

// Guaranteed to honor 'num_segments'
AddNgon :: proc(this : ^ImDrawList, center : ImVec2, radius : f32, col : u32, num_segments : i32, thickness : f32 = 1)
{
    if ((col & IM_COL32_A_MASK) == 0 || num_segments <= 2)   do return

    // Because we are filling a closed shape we remove 1 from the count of segments/points
    a_max := (IM_PI * 2.0) * (cast(f32) num_segments - 1.0) / cast(f32) num_segments;
    PathArcTo(this, center, radius - 0.5, 0.0, a_max, num_segments - 1);
    PathStroke(this, col, { .Closed }, thickness);
}

// Guaranteed to honor 'num_segments'
AddNgonFilled :: proc(this : ^ImDrawList, center : ImVec2, radius : f32, col : u32, num_segments : i32)
{
    if ((col & IM_COL32_A_MASK) == 0 || num_segments <= 2)   do return

    // Because we are filling a closed shape we remove 1 from the count of segments/points
    a_max := (IM_PI * 2.0) * (cast(f32) num_segments - 1.0) / cast(f32) num_segments;
    PathArcTo(this, center, radius, 0.0, a_max, num_segments - 1);
    PathFillConvex(this, col);
}

// Ellipse
AddEllipse :: proc(this : ^ImDrawList, center : ImVec2, radius : ImVec2, col : u32, rot : f32 = 0, num_segments : i32 = 0, thickness : f32 = 1)
{
    if ((col & IM_COL32_A_MASK) == 0)   do return
    
    num_segments := num_segments
    if (num_segments <= 0) {
        num_segments = _CalcCircleAutoSegmentCount(this, ImMax(radius.x, radius.y)); // A bit pessimistic, maybe there's a better computation to do here.
    }

    // Because we are filling a closed shape we remove 1 from the count of segments/points
    a_max := IM_PI * 2.0 * (cast(f32) num_segments - 1.0) / cast(f32) num_segments;
    PathEllipticalArcTo(this, center, radius, rot, 0.0, a_max, num_segments - 1);
    PathStroke(this, col, { .Closed }, thickness);
}

AddEllipseFilled :: proc(this : ^ImDrawList, center : ImVec2, radius : ImVec2, col : u32, rot : f32 = 0.0, num_segments : i32 = 0)
{
    if ((col & IM_COL32_A_MASK) == 0)   do return

    num_segments := num_segments
    if (num_segments <= 0) {
        num_segments = _CalcCircleAutoSegmentCount(this, ImMax(radius.x, radius.y)); // A bit pessimistic, maybe there's a better computation to do here.
    }

    // Because we are filling a closed shape we remove 1 from the count of segments/points
    a_max := IM_PI * 2.0 * (cast(f32) num_segments - 1.0) / cast(f32) num_segments;
    PathEllipticalArcTo(this, center, radius, rot, 0.0, a_max, num_segments - 1);
    PathFillConvex(this, col);
}

// Cubic Bezier takes 4 controls points
// [forward declared comment]:
// Cubic Bezier (4 control points)
AddBezierCubic :: proc(this : ^ImDrawList, p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, p4 : ImVec2, col : u32, thickness : f32, num_segments : i32 = 0)
{
    if ((col & IM_COL32_A_MASK) == 0)   do return

    PathLineTo(this, p1);
    PathBezierCubicCurveTo(this, p2, p3, p4, num_segments);
    PathStroke(this, col, nil, thickness);
}

// Quadratic Bezier takes 3 controls points
// [forward declared comment]:
// Quadratic Bezier (3 control points)
AddBezierQuadratic :: proc(this : ^ImDrawList, p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, col : u32, thickness : f32, num_segments : i32 = 0)
{
    if ((col & IM_COL32_A_MASK) == 0)   do return

    PathLineTo(this, p1);
    PathBezierQuadraticCurveTo(this, p2, p3, num_segments);
    PathStroke(this, col, nil, thickness);
}

// [forward declared comment]:
// Add string (each character of the UTF-8 string are added)
AddText_ex :: proc(this : ^ImDrawList, font : ^ImFont, font_size : f32, pos : ImVec2, col : u32, text : string, wrap_width : f32 = 0, cpu_fine_clip_rect : ^ImVec4 = nil)
{
    if ((col & IM_COL32_A_MASK) == 0)   do return
    font := font
    font_size := font_size

    // Accept null ranges
    if (text == "")   do return

    // Pull default font/size from the shared ImDrawListSharedData instance
    if (font == nil)   do font = this._Data.Font
    if (font_size == 0.0) do font_size = this._Data.FontSize;

    assert(font.ContainerAtlas.TexID == this._CmdHeader.TextureId);  // Use high-level ImGui::PushFont() or low-level ImDrawList::PushTextureId() to change font.

    clip_rect := this._CmdHeader.ClipRect;
    if (cpu_fine_clip_rect != nil)
    {
        clip_rect.x = ImMax(clip_rect.x, cpu_fine_clip_rect.x);
        clip_rect.y = ImMax(clip_rect.y, cpu_fine_clip_rect.y);
        clip_rect.z = ImMin(clip_rect.z, cpu_fine_clip_rect.z);
        clip_rect.w = ImMin(clip_rect.w, cpu_fine_clip_rect.w);
    }
    RenderText(font, this, font_size, pos, col, clip_rect, text, wrap_width, cpu_fine_clip_rect != nil);
}

// [forward declared comment]:
// Add string (each character of the UTF-8 string are added)
AddText_basic :: proc(this : ^ImDrawList, pos : ImVec2, col : u32, text : string)
{
    AddText(this, nil, 0.0, pos, col, text);
}

AddText :: proc { AddText_basic, AddText_ex, AddText_fgrb }

AddImage :: proc(this : ^ImDrawList, user_texture_id : ImTextureID, p_min : ImVec2, p_max : ImVec2, uv_min : ImVec2 = {}, uv_max : ImVec2 = ImVec2{1, 1}, col : u32 = IM_COL32_WHITE)
{
    if ((col & IM_COL32_A_MASK) == 0)   do return

    push_texture_id := user_texture_id != this._CmdHeader.TextureId;
    if (push_texture_id) do PushTextureID(this, user_texture_id);

    PrimReserve(this, 6, 4);
    PrimRectUV(this, p_min, p_max, uv_min, uv_max, col);

    if (push_texture_id)   do PopTextureID(this)
}

AddImageQuad :: proc(this : ^ImDrawList, user_texture_id : ImTextureID, p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, p4 : ImVec2, uv1 : ImVec2 = {}, uv2 : ImVec2 = ImVec2{1, 0}, uv3 : ImVec2 = ImVec2{1, 1}, uv4 : ImVec2 = ImVec2{0, 1}, col : u32 = IM_COL32_WHITE)
{
    if ((col & IM_COL32_A_MASK) == 0)   do return

    push_texture_id := user_texture_id != this._CmdHeader.TextureId;
    if (push_texture_id) do PushTextureID(this, user_texture_id);

    PrimReserve(this, 6, 4);
    PrimQuadUV(this, p1, p2, p3, p4, uv1, uv2, uv3, uv4, col);

    if (push_texture_id)   do PopTextureID(this)
}

AddImageRounded :: proc(this : ^ImDrawList, user_texture_id : ImTextureID, p_min : ImVec2, p_max : ImVec2, uv_min : ImVec2, uv_max : ImVec2, col : u32, rounding : f32, flags : ImDrawFlags = {})
{
    if ((col & IM_COL32_A_MASK) == 0)   do return

    flags: = FixRectCornerFlags(flags);
    if (rounding < 0.5 || (flags & ImDrawFlags_RoundCornersMask_) == {.RoundCornersNone})
    {
        AddImage(this, user_texture_id, p_min, p_max, uv_min, uv_max, col);
        return;
    }

    push_texture_id := user_texture_id != this._CmdHeader.TextureId;
    if (push_texture_id) do PushTextureID(this, user_texture_id);

    vert_start_idx := cast(i32) len(this.VtxBuffer)
    PathRect(this, p_min, p_max, rounding, flags);
    PathFillConvex(this, col);
    vert_end_idx := cast(i32) len(this.VtxBuffer)
    ShadeVertsLinearUV(this, vert_start_idx, vert_end_idx, p_min, p_max, uv_min, uv_max, true);

    if (push_texture_id)   do PopTextureID(this)
}

//-----------------------------------------------------------------------------
// [SECTION] ImTriangulator, ImDrawList concave polygon fill
//-----------------------------------------------------------------------------
// Triangulate concave polygons. Based on "Triangulation by Ear Clipping" paper, O(N^2) complexity.
// Reference: https://www.geometrictools.com/Documentation/TriangulationByEarClipping.pdf
// Provided as a convenience for user but not used by main library.
//-----------------------------------------------------------------------------
// - ImTriangulator [Internal]
// - AddConcavePolyFilled()
//-----------------------------------------------------------------------------

ImTriangulatorNodeType :: enum i32
{
    Convex,
    Ear,
    Reflex
};

ImTriangulatorNode :: struct
{
    Type : ImTriangulatorNodeType,
    Index : i32,
    Pos : ImVec2,
    Next : ^ImTriangulatorNode,
    Prev : ^ImTriangulatorNode,
};

Unlink :: proc(this : ^ImTriangulatorNode)        { this.Next.Prev = this.Prev; this.Prev.Next = this.Next; }

ImTriangulatorNodeSpan :: struct
{
    Data : [^]^ImTriangulatorNode,
    Size : i32,
};

ImTriangulatorNodeSpan_append :: proc(this : ^ImTriangulatorNodeSpan, node : ^ImTriangulatorNode) { this.Data[this.Size] = node; this.Size += 1 }
find_erase_unsorted :: proc(this : ^ImTriangulatorNodeSpan, idx : i32)        { for i := this.Size - 1; i >= 0; i -= 1 do if (this.Data[i].Index == idx) { this.Data[i] = this.Data[this.Size - 1]; this.Size -= 1; return; } }

ImTriangulator :: struct
{
    _TrianglesLeft : i32,
    _Nodes : [^]ImTriangulatorNode,
    _Ears : ImTriangulatorNodeSpan,
    _Reflexes : ImTriangulatorNodeSpan,
};

EstimateTriangleCount :: proc(points_count : i32) -> i32      { return (points_count < 3) ? 0 : points_count - 2; }
EstimateScratchBufferSize :: proc(points_count : i32) -> i32  { return size_of(ImTriangulatorNode) * points_count + size_of(^ImTriangulatorNode) * points_count * 2; }


// Distribute storage for nodes, ears and reflexes.
// FIXME-OPT: if everything is convex, we could report it to caller and let it switch to an convex renderer
// (this would require first building reflexes to bail to convex if empty, without even building nodes)
Init :: proc(this : ^ImTriangulator, points : ^ImVec2, points_count : i32, scratch_buffer : rawptr)
{
    assert(scratch_buffer != nil && points_count >= 3);
    this._TrianglesLeft = EstimateTriangleCount(points_count);
    this._Nodes         = cast(^ImTriangulatorNode)scratch_buffer;                          // points_count x Node
    this._Ears.Data     = cast([^]^ImTriangulatorNode)(this._Nodes[points_count:]);                // points_count x Node*
    this._Reflexes.Data = cast([^]^ImTriangulatorNode)(this._Nodes[points_count:])[points_count:]; // points_count x Node*
    BuildNodes(this, points, points_count);
    BuildReflexes(this);
    BuildEars(this);
}

BuildNodes :: proc(this : ^ImTriangulator, points : ^ImVec2, points_count : i32)
{
    for i : i32 = 0; i < points_count; i += 1
    {
        this._Nodes[i].Type = .Convex;
        this._Nodes[i].Index = i;
        this._Nodes[i].Pos = points[i];
        this._Nodes[i].Next = &this._Nodes[i + 1];
        this._Nodes[i].Prev = &this._Nodes[i - 1];
    }
    this._Nodes[0].Prev = this._Nodes[points_count - 1:];
    this._Nodes[points_count - 1].Next = this._Nodes;
}

BuildReflexes :: proc(this : ^ImTriangulator)
{
    n1 := cast(^ImTriangulatorNode) this._Nodes;
    for i := this._TrianglesLeft; i >= 0; i -= 1
    {
        if (ImTriangleIsClockwise(n1.Prev.Pos, n1.Pos, n1.Next.Pos))   do continue
        n1.Type = .Reflex;
        append(&this._Reflexes, n1);
        n1 = n1.Next
    }
}

BuildEars :: proc(this : ^ImTriangulator)
{
    n1 := cast(^ImTriangulatorNode)  this._Nodes;
    for i := this._TrianglesLeft; i >= 0; i, n1 = i - 1, n1.Next
    {
        if (n1.Type != .Convex)   do continue
        if (!IsEar(this, n1.Prev.Index, n1.Index, n1.Next.Index, n1.Prev.Pos, n1.Pos, n1.Next.Pos))   do continue
        n1.Type = .Ear;
        append(&this._Ears, n1);
    }
}

// [forward declared comment]:
// Return relative indexes for next triangle
GetNextTriangle :: proc(this : ^ImTriangulator, out_triangle : ^[3]u32)
{
    if (this._Ears.Size == 0)
    {
        FlipNodeList(this);

        node := cast(^ImTriangulatorNode) this._Nodes;
        for i := this._TrianglesLeft; i >= 0; i -= 1 {
            node.Type = .Convex;
            node = node.Next
        }
        this._Reflexes.Size = 0;
        BuildReflexes(this);
        BuildEars(this);

        // If we still don't have ears, it means geometry is degenerated.
        if (this._Ears.Size == 0)
        {
            // Return first triangle available, mimicking the behavior of convex fill.
            assert(this._TrianglesLeft > 0); // Geometry is degenerated
            this._Ears.Data[0] = this._Nodes;
            this._Ears.Size    = 1;
        }
    }

    this._Ears.Size -= 1
    ear := this._Ears.Data[this._Ears.Size];
    out_triangle[0] = cast(u32) ear.Prev.Index;
    out_triangle[1] = cast(u32) ear.Index;
    out_triangle[2] = cast(u32) ear.Next.Index;

    Unlink(ear);
    if (ear == this._Nodes)   do this._Nodes = ear.Next

    ReclassifyNode(this, ear.Prev);
    ReclassifyNode(this, ear.Next);
    this._TrianglesLeft -= 1;
}

FlipNodeList :: proc(this : ^ImTriangulator)
{
    prev := &this._Nodes[0];
    temp := &this._Nodes[0];
    current := this._Nodes[0].Next;
    prev.Next = prev;
    prev.Prev = prev;
    for (current != this._Nodes)
    {
        temp = current.Next;

        current.Next = prev;
        prev.Prev = current;
        this._Nodes[0].Next = current;
        current.Prev = this._Nodes;

        prev = current;
        current = temp;
    }
    this._Nodes = prev;
}

// A triangle is an ear is no other vertex is inside it. We can test reflexes vertices only (see reference algorithm)
IsEar :: proc(this : ^ImTriangulator, i0 : i32, i1 : i32, i2 : i32, v0 : ImVec2, v1 : ImVec2, v2 : ImVec2) -> bool
{
    for i in 0..<this._Reflexes.Size
    {
        reflex := this._Reflexes.Data[i];
        if (reflex.Index != i0 && reflex.Index != i1 && reflex.Index != i2) {
            if (ImTriangleContainsPoint(v0, v1, v2, reflex.Pos))  {
                return false
            }
        }
    }
    return true;
}

ReclassifyNode :: proc(this : ^ImTriangulator, n1 : ^ImTriangulatorNode)
{
    // Classify node
    type : ImTriangulatorNodeType
    n0 := n1.Prev;
    n2 := n1.Next;
    if (!ImTriangleIsClockwise(n0.Pos, n1.Pos, n2.Pos)) {
        type = .Reflex;
    }
    else if (IsEar(this, n0.Index, n1.Index, n2.Index, n0.Pos, n1.Pos, n2.Pos)) {
        type = .Ear;
    }
    else {
        type = .Convex;
    }

    // Update lists when a type changes
    if (type == n1.Type)   do return
    if (n1.Type == .Reflex) {
        find_erase_unsorted(&this._Reflexes, n1.Index);
    }
    else if (n1.Type == .Ear) {
        find_erase_unsorted(&this._Ears, n1.Index);
    }
    if (type == .Reflex)   do append(&this._Reflexes, n1)
    else if (type == .Ear)   do append(&this._Ears, n1)
    n1.Type = type;
}

// Use ear-clipping algorithm to triangulate a simple polygon (no self-interaction, no holes).
// (Reminder: we don't perform any coarse clipping/culling in ImDrawList layer!
// It is up to caller to ensure not making costly calls that will be outside of visible area.
// As concave fill is noticeably more expensive than other primitives, be mindful of this...
// Caller can build AABB of points, and avoid filling if 'draw_list._CmdHeader.ClipRect.Overlays(points_bb) == false')
AddConcavePolyFilled :: proc(this : ^ImDrawList, points : [^]ImVec2, points_count : i32, col : u32)
{
    if (points_count < 3 || (col & IM_COL32_A_MASK) == 0)   do return

    uv := this._Data.TexUvWhitePixel;
    triangulator : ImTriangulator
    triangle : [3]u32
    if (.AntiAliasedFill in this.Flags)
    {
        // Anti-aliased Fill
        AA_SIZE := this._FringeScale;
        col_trans := col & ~IM_COL32_A_MASK;
        idx_count := (points_count - 2) * 3 + points_count * 6;
        vtx_count := (points_count * 2);
        PrimReserve(this, idx_count, vtx_count);

        // Add indexes for fill
        vtx_inner_idx := this._VtxCurrentIdx;
        vtx_outer_idx := this._VtxCurrentIdx + 1;

        reserve_discard(&this._Data.TempBuffer, (EstimateScratchBufferSize(points_count) + size_of(ImVec2)) / size_of(ImVec2));
        Init(&triangulator, points, points_count, raw_data(this._Data.TempBuffer));
        for (triangulator._TrianglesLeft > 0)
        {
            GetNextTriangle(&triangulator, &triangle);
            this._IdxWritePtr[0] = ImDrawIdx(vtx_inner_idx + (triangle[0] << 1)); this._IdxWritePtr[1] = ImDrawIdx(vtx_inner_idx + (triangle[1] << 1)); this._IdxWritePtr[2] = ImDrawIdx(vtx_inner_idx + (triangle[2] << 1));
            this._IdxWritePtr = this._IdxWritePtr[3:];
        }

        // Compute normals
        reserve_discard(&this._Data.TempBuffer, points_count);
        temp_normals := raw_data(this._Data.TempBuffer);
        for i0, i1 : i32 = points_count - 1, 0; i1 < points_count; i0, i1 = i1, i1 + 1
        {
            p0 := points[i0];
            p1 := points[i1];
            d := p1 - p0;
            IM_NORMALIZE2F_OVER_ZERO(&d);
            temp_normals[i0].x = d.y;
            temp_normals[i0].y = -d.x;
        }

        for i0, i1 : i32 = points_count - 1, 0; i1 < points_count; i0, i1 = i1, i1 + 1
        {
            // Average normals
            n0 := temp_normals[i0];
            n1 := temp_normals[i1];
            dm := (n0 + n1) * 0.5;
            IM_FIXNORMAL2F(&dm);
            dm *= AA_SIZE * 0.5;

            // Add vertices
            this._VtxWritePtr[0].pos.x = (points[i1].x - dm.x); this._VtxWritePtr[0].pos.y = (points[i1].y - dm.y); this._VtxWritePtr[0].uv = uv; this._VtxWritePtr[0].col = col;        // Inner
            this._VtxWritePtr[1].pos.x = (points[i1].x + dm.x); this._VtxWritePtr[1].pos.y = (points[i1].y + dm.y); this._VtxWritePtr[1].uv = uv; this._VtxWritePtr[1].col = col_trans;  // Outer
            this._VtxWritePtr = this._VtxWritePtr[2:];

            // Add indexes for fringes
            this._IdxWritePtr[0] = ImDrawIdx(vtx_inner_idx + (u32(i1) << 1)); this._IdxWritePtr[1] = ImDrawIdx(vtx_inner_idx + (u32(i0) << 1)); this._IdxWritePtr[2] = ImDrawIdx(vtx_outer_idx + (u32(i0) << 1));
            this._IdxWritePtr[3] = ImDrawIdx(vtx_outer_idx + (u32(i0) << 1)); this._IdxWritePtr[4] = ImDrawIdx(vtx_outer_idx + (u32(i1) << 1)); this._IdxWritePtr[5] = ImDrawIdx(vtx_inner_idx + (u32(i1) << 1));
            this._IdxWritePtr = this._IdxWritePtr[6:];
        }
        this._VtxCurrentIdx += u32(vtx_count)
    }
    else
    {
        // Non Anti-aliased Fill
        idx_count := (points_count - 2) * 3;
        vtx_count := points_count;
        PrimReserve(this, idx_count, vtx_count);
        for i : i32 = 0; i < vtx_count; i += 1
        {
            this._VtxWritePtr[0].pos = points[i]; this._VtxWritePtr[0].uv = uv; this._VtxWritePtr[0].col = col;
            this._VtxWritePtr = this._VtxWritePtr[1:];
        }
        reserve_discard(&this._Data.TempBuffer, (EstimateScratchBufferSize(points_count) + size_of(ImVec2)) / size_of(ImVec2));
        Init(&triangulator, points, points_count, raw_data(this._Data.TempBuffer));
        for (triangulator._TrianglesLeft > 0)
        {
            GetNextTriangle(&triangulator, &triangle);
            this._IdxWritePtr[0] = ImDrawIdx(this._VtxCurrentIdx + triangle[0]); this._IdxWritePtr[1] = ImDrawIdx(this._VtxCurrentIdx + triangle[1]); this._IdxWritePtr[2] = ImDrawIdx(this._VtxCurrentIdx + triangle[2]);
            this._IdxWritePtr = this._IdxWritePtr[3:];
        }
        this._VtxCurrentIdx += u32(vtx_count);
    }
}

//-----------------------------------------------------------------------------
// [SECTION] ImDrawListSplitter
//-----------------------------------------------------------------------------
// FIXME: This may be a little confusing, trying to be a little too low-level/optimal instead of just doing vector swap..
//-----------------------------------------------------------------------------

ImDrawListSplitter_ClearFreeMemory :: proc(this : ^ImDrawListSplitter)
{
    for &channel, i in this._Channels
    {
        if (i == int(this._Current)) {
            channel = {};  // Current channel is a copy of CmdBuffer/IdxBuffer, don't destruct again
        }
        clear(&channel._CmdBuffer);
        clear(&channel._IdxBuffer);
    }
    this._Current = 0;
    this._Count = 1;
    clear(&this._Channels)
}

Split :: proc(this : ^ImDrawListSplitter, draw_list : ^ImDrawList, channels_count : i32)
{
    _ = draw_list;
    assert(this._Current == 0 && this._Count <= 1, "Nested channel splitting is not supported. Please use separate instances of ImDrawListSplitter.");
    old_channels_count := cast(i32) len(this._Channels);
    if (old_channels_count < channels_count)
    {
        reserve(&this._Channels, channels_count); // Avoid over reserving since this is likely to stay stable
        resize(&this._Channels, channels_count);
    }
    this._Count = channels_count;

    // Channels[] (24/32 bytes each) hold storage that we'll swap with draw_list._CmdBuffer/_IdxBuffer
    // The content of Channels[0] at this point doesn't matter. We clear it to make state tidy in a debugger but we don't strictly need to.
    // When we switch to the next channel, we'll copy draw_list._CmdBuffer/_IdxBuffer into Channels[0] and then Channels[1] into draw_list.CmdBuffer/_IdxBuffer
    memset(&this._Channels[0], 0, size_of(ImDrawChannel));
    for i : i32 = 1; i < channels_count; i += 1
    {
        if (i >= old_channels_count)
        {
            __inplace_constructors(&this._Channels[i])
        }
        else
        {
            clear(&this._Channels[i]._CmdBuffer);
            clear(&this._Channels[i]._IdxBuffer);
        }
    }
}

Merge :: proc(this : ^ImDrawListSplitter, draw_list : ^ImDrawList)
{
    // Note that we never use or rely on len(_Channels) because it is merely a buffer that we never shrink back to 0 to keep all sub-buffers ready for use.
    if (this._Count <= 1)   do return

    SetCurrentChannel(this, draw_list, 0);
    _PopUnusedDrawCmd(draw_list);

    // Calculate our final buffer sizes. Also fix the incorrect IdxOffset values in each command.
    new_cmd_buffer_count := 0;
    new_idx_buffer_count := 0;
    last_cmd := (this._Count > 0 && len(draw_list.CmdBuffer) > 0) ? back(draw_list.CmdBuffer) : nil;
    idx_offset := last_cmd != nil ? last_cmd.IdxOffset + last_cmd.ElemCount : 0;
    for i : i32 = 1; i < this._Count; i += 1
    {
        ch := &this._Channels[i];
        if (len(ch._CmdBuffer) > 0 && back(ch._CmdBuffer).ElemCount == 0 && back(ch._CmdBuffer).UserCallback == nil) {// Equivalent of PopUnusedDrawCmd()  
            pop(&ch._CmdBuffer)
        }

        if (len(ch._CmdBuffer) > 0 && last_cmd != nil)
        {
            // Do not include ImDrawCmd_AreSequentialIdxOffset() in the compare as we rebuild IdxOffset values ourselves.
            // Manipulating IdxOffset (e.g. by reordering draw commands like done by RenderDimmedBackgroundBehindWindow()) is not supported within a splitter.
            next_cmd := &ch._CmdBuffer[0];
            if (ImDrawCmd_HeaderCompare(last_cmd, next_cmd) && last_cmd.UserCallback == nil && next_cmd.UserCallback == nil)
            {
                // Merge previous channel last draw command with current channel first draw command if matching.
                last_cmd.ElemCount += next_cmd.ElemCount;
                idx_offset += next_cmd.ElemCount;
                erase(&ch._CmdBuffer, raw_data(ch._CmdBuffer)); // FIXME-OPT: Improve for multiple merges.
            }
        }
        if (len(ch._CmdBuffer) > 0) {
            last_cmd = back(ch._CmdBuffer);
        }
        new_cmd_buffer_count += len(ch._CmdBuffer);
        new_idx_buffer_count += len(ch._IdxBuffer);
        for cmd_n := 0; cmd_n < len(ch._CmdBuffer); cmd_n += 1
        {
            ch._CmdBuffer[cmd_n].IdxOffset = idx_offset;
            idx_offset += ch._CmdBuffer[cmd_n].ElemCount;
        }
    }
    resize(&draw_list.CmdBuffer, len(draw_list.CmdBuffer) + new_cmd_buffer_count);
    resize(&draw_list.IdxBuffer, len(draw_list.IdxBuffer) + new_idx_buffer_count);

    // Write commands and indices in order (they are fairly small structures, we don't copy vertices only indices)
    cmd_write := draw_list.CmdBuffer[len(draw_list.CmdBuffer) - new_cmd_buffer_count:];
    idx_write := draw_list.IdxBuffer[len(draw_list.IdxBuffer) - new_idx_buffer_count:];
    for i : i32 = 1; i < this._Count; i += 1
    {
        ch := &this._Channels[i];
        if sz := len(ch._CmdBuffer); sz != 0 { memcpy(raw_data(cmd_write), raw_data(ch._CmdBuffer), sz * size_of(ImDrawCmd)); cmd_write = cmd_write[sz:]; }
        if sz := len(ch._IdxBuffer); sz != 0 { memcpy(raw_data(idx_write), raw_data(ch._IdxBuffer), sz * size_of(ImDrawIdx)); idx_write = idx_write[sz:]; }
    }
    draw_list._IdxWritePtr = raw_data(idx_write);

    // Ensure there's always a non-callback draw command trailing the command-buffer
    if (len(draw_list.CmdBuffer) == 0 || back(draw_list.CmdBuffer).UserCallback != nil)   do AddDrawCmd(draw_list)

    // If current command is used with different settings we need to add a new command
    curr_cmd := &draw_list.CmdBuffer[len(draw_list.CmdBuffer) - 1];
    if (curr_cmd.ElemCount == 0) {
        ImDrawCmd_HeaderCopy(cast(^ImDrawCmdHeader) curr_cmd, &draw_list._CmdHeader); // Copy ClipRect, TextureId, VtxOffset
    }
    else if (!ImDrawCmd_HeaderCompare(cast(^ImDrawCmdHeader) curr_cmd, &draw_list._CmdHeader)) {
        AddDrawCmd(draw_list)
    }

    this._Count = 1;
}

SetCurrentChannel :: proc(this : ^ImDrawListSplitter, draw_list : ^ImDrawList, idx : i32)
{
    assert(idx >= 0 && idx < this._Count);
    if (this._Current == idx)   do return

    // Overwrite ImVector (12/16 bytes), four times. This is merely a silly optimization instead of doing .swap()
    memcpy(&this._Channels[this._Current]._CmdBuffer, &draw_list.CmdBuffer, size_of(draw_list.CmdBuffer));
    memcpy(&this._Channels[this._Current]._IdxBuffer, &draw_list.IdxBuffer, size_of(draw_list.IdxBuffer));
    this._Current = idx;
    memcpy(&draw_list.CmdBuffer, &this._Channels[idx]._CmdBuffer, size_of(draw_list.CmdBuffer));
    memcpy(&draw_list.IdxBuffer, &this._Channels[idx]._IdxBuffer, size_of(draw_list.IdxBuffer));
    draw_list._IdxWritePtr = mem.ptr_offset(raw_data(draw_list.IdxBuffer), len(draw_list.IdxBuffer))

    // If current command is used with different settings we need to add a new command
    curr_cmd := (len(draw_list.CmdBuffer) == 0) ? nil : back(draw_list.CmdBuffer);
    if (curr_cmd == nil) {
        AddDrawCmd(draw_list)
    }
    else if (curr_cmd.ElemCount == 0) {
        ImDrawCmd_HeaderCopy(cast(^ImDrawCmdHeader) curr_cmd, &draw_list._CmdHeader); // Copy ClipRect, TextureId, VtxOffset
    }
    else if (!ImDrawCmd_HeaderCompare(cast(^ImDrawCmdHeader) curr_cmd, &draw_list._CmdHeader)) {
        AddDrawCmd(draw_list)
    }
}

//-----------------------------------------------------------------------------
// [SECTION] ImDrawData
//-----------------------------------------------------------------------------

// [forward declared comment]:
// Clear all input and output.
ImDrawData_Clear :: proc(this : ^ImDrawData)
{
    this.Valid = false;
    this.CmdListsCount = 0;
    this.TotalIdxCount = 0;
    this.TotalVtxCount = 0;
    clear(&this.CmdLists) // The ImDrawList are NOT owned by ImDrawData but e.g. by ImGuiContext, so we don't clear them.
    this.DisplayPos = {}
    this.DisplaySize = {}
    this.FramebufferScale = {}
    this.OwnerViewport = nil;
}

// Important: 'out_list' is generally going to be draw_data.CmdLists, but may be another temporary list
// as long at it is expected that the result will be later merged into draw_data.CmdLists[].
AddDrawListToDrawDataEx :: proc(draw_data : ^ImDrawData, out_list : ^[dynamic]^ImDrawList, draw_list : ^ImDrawList)
{
    if (len(draw_list.CmdBuffer) == 0)   do return
    if (len(draw_list.CmdBuffer) == 1 && draw_list.CmdBuffer[0].ElemCount == 0 && draw_list.CmdBuffer[0].UserCallback == nil)   do return

    // Draw list sanity check. Detect mismatch between PrimReserve() calls and incrementing _VtxCurrentIdx, _VtxWritePtr etc.
    // May trigger for you if you are using PrimXXX functions incorrectly.
    assert(len(draw_list.VtxBuffer) == 0 || draw_list._VtxWritePtr == end(draw_list.VtxBuffer));
    assert(len(draw_list.IdxBuffer) == 0 || draw_list._IdxWritePtr == end(draw_list.IdxBuffer));
    if (!(.AllowVtxOffset in draw_list.Flags)) {
        assert(cast(int) draw_list._VtxCurrentIdx == len(draw_list.VtxBuffer));
    }

    // Check that draw_list doesn't use more vertices than indexable (default ImDrawIdx = unsigned short = 2 bytes = 64K vertices per ImDrawList = per window)
    // If this assert triggers because you are drawing lots of stuff manually:
    // - First, make sure you are coarse clipping yourself and not trying to draw many things outside visible bounds.
    //   Be mindful that the lower-level ImDrawList API doesn't filter vertices. Use the Metrics/Debugger window to inspect draw list contents.
    // - If you want large meshes with more than 64K vertices, you can either:
    //   (A) Handle the ImDrawCmd::VtxOffset value in your renderer backend, and set 'io.BackendFlags |= ImGuiBackendFlags_RendererHasVtxOffset'.
    //       Most example backends already support this from 1.71. Pre-1.71 backends won't.
    //       Some graphics API such as GL ES 1/2 don't have a way to offset the starting vertex so it is not supported for them.
    //   (B) Or handle 32-bit indices in your renderer backend, and uncomment '#define ImDrawIdx unsigned int' line in imconfig.h.
    //       Most example backends already support this. For example, the OpenGL example code detect index size at compile-time:
    //         glDrawElements(GL_TRIANGLES, (GLsizei)pcmd.ElemCount, size_of(ImDrawIdx) == 2 ? GL_UNSIGNED_SHORT : GL_UNSIGNED_INT, idx_buffer_offset);
    //       Your own engine or render API may use different parameters or function calls to specify index sizes.
    //       2 and 4 bytes indices are generally supported by most graphics API.
    // - If for some reason neither of those solutions works for you, a workaround is to call BeginChild()/EndChild() before reaching
    //   the 64K limit to split your draw commands in multiple draw lists.
    if (size_of(ImDrawIdx) == 2) {
        assert(draw_list._VtxCurrentIdx < (1 << 16), "Too many vertices in ImDrawList using 16-bit indices. Read comment above");
    }

    // Resolve callback data pointers
    if (len(draw_list._CallbacksDataBuf) > 0) {
        for &cmd in draw_list.CmdBuffer {
            if (cmd.UserCallback != nil && cmd.UserCallbackDataOffset != -1 && cmd.UserCallbackDataSize > 0) {
                cmd.UserCallbackData = &draw_list._CallbacksDataBuf[cmd.UserCallbackDataOffset];
            }
        }
    }

    // Add to output list + records state in ImDrawData
    append(out_list, draw_list);
    draw_data.CmdListsCount += 1;
    draw_data.TotalVtxCount += cast(i32) len(draw_list.VtxBuffer);
    draw_data.TotalIdxCount += cast(i32) len(draw_list.IdxBuffer);
}

// [forward declared comment]:
// Helper to add an external draw list into an existing ImDrawData.
AddDrawList :: proc(this : ^ImDrawData, draw_list : ^ImDrawList)
{
    assert(len(this.CmdLists) == cast(int) this.CmdListsCount);
    _PopUnusedDrawCmd(draw_list);
    AddDrawListToDrawDataEx(this, &this.CmdLists, draw_list);
}

// For backward compatibility: convert all buffers from indexed to de-indexed, in case you cannot render indexed. Note: this is slow and most likely a waste of resources. Always prefer indexed rendering!
// [forward declared comment]:
// Helper to convert all buffers from indexed to non-indexed, in case you cannot render indexed. Note: this is slow and most likely a waste of resources. Always prefer indexed rendering!
DeIndexAllBuffers :: proc(this : ^ImDrawData)
{
    new_vtx_buffer : [dynamic]ImDrawVert
    this.TotalVtxCount = 0
    this.TotalIdxCount = 0;
    for i : i32 = 0; i < this.CmdListsCount; i += 1
    {
        cmd_list := this.CmdLists[i];
        if (empty(cmd_list.IdxBuffer))   do continue
        resize(&new_vtx_buffer, len(cmd_list.IdxBuffer));
        for j := 0; j < len(cmd_list.IdxBuffer); j += 1 {
            new_vtx_buffer[j] = cmd_list.VtxBuffer[cmd_list.IdxBuffer[j]];
        }
        swap(&cmd_list.VtxBuffer, &new_vtx_buffer);
        clear(&cmd_list.IdxBuffer)
        this.TotalVtxCount += cast(i32) len(cmd_list.VtxBuffer);
    }
}

// Helper to scale the ClipRect field of each ImDrawCmd.
// Use if your final output buffer is at a different scale than draw_data.DisplaySize,
// or if there is a difference between your window resolution and framebuffer resolution.
// [forward declared comment]:
// Helper to scale the ClipRect field of each ImDrawCmd. Use if your final output buffer is at a different scale than Dear ImGui expects, or if there is a difference between your window resolution and framebuffer resolution.
ScaleClipRects :: proc(this : ^ImDrawData, fb_scale : ImVec2)
{
    for draw_list in this.CmdLists {
        for &cmd in draw_list.CmdBuffer {
            cmd.ClipRect = ImVec4{cmd.ClipRect.x * fb_scale.x, cmd.ClipRect.y * fb_scale.y, cmd.ClipRect.z * fb_scale.x, cmd.ClipRect.w * fb_scale.y};
        }
    }
}

//-----------------------------------------------------------------------------
// [SECTION] Helpers ShadeVertsXXX functions
//-----------------------------------------------------------------------------

// Generic linear color gradient, write to RGB fields, leave A untouched.
ShadeVertsLinearColorGradientKeepAlpha :: proc(draw_list : ^ImDrawList, vert_start_idx : i32, vert_end_idx : i32, gradient_p0 : ImVec2, gradient_p1 : ImVec2, col0 : u32, col1 : u32)
{
    gradient_extent := gradient_p1 - gradient_p0;
    gradient_inv_length2 := 1.0 / ImLengthSqr(gradient_extent);
    vertices := draw_list.VtxBuffer[vert_start_idx:vert_end_idx]
    col0_r := (i32)(col0 >> IM_COL32_R_SHIFT) & 0xFF;
    col0_g := (i32)(col0 >> IM_COL32_G_SHIFT) & 0xFF;
    col0_b := (i32)(col0 >> IM_COL32_B_SHIFT) & 0xFF;
    col_delta_r := ((i32)(col1 >> IM_COL32_R_SHIFT) & 0xFF) - col0_r;
    col_delta_g := ((i32)(col1 >> IM_COL32_G_SHIFT) & 0xFF) - col0_g;
    col_delta_b := ((i32)(col1 >> IM_COL32_B_SHIFT) & 0xFF) - col0_b;
    for &vert in vertices
    {
        d := ImDot(vert.pos - gradient_p0, gradient_extent);
        t := ImClamp(d * gradient_inv_length2, 0.0, 1.0);
        r := (u32)(f32(col0_r + col_delta_r) * t);
        g := (u32)(f32(col0_g + col_delta_g) * t);
        b := (u32)(f32(col0_b + col_delta_b) * t);
        vert.col = (r << IM_COL32_R_SHIFT) | (g << IM_COL32_G_SHIFT) | (b << IM_COL32_B_SHIFT) | (vert.col & IM_COL32_A_MASK);
    }
}

// Distribute UV over (a, b) rectangle
ShadeVertsLinearUV :: proc(draw_list : ^ImDrawList, vert_start_idx : i32, vert_end_idx : i32, a : ImVec2, b : ImVec2, uv_a : ImVec2, uv_b : ImVec2, clamp : bool)
{
    size := b - a;
    uv_size := uv_b - uv_a;
    scale := ImVec2{
        size.x != 0.0 ? (uv_size.x / size.x) : 0.0,
        size.y != 0.0 ? (uv_size.y / size.y) : 0.0};

    vertices := draw_list.VtxBuffer[vert_start_idx:vert_end_idx];
    if (clamp)
    {
        min := ImMin(uv_a, uv_b);
        max := ImMax(uv_a, uv_b);
        for &vertex in vertices {
            vertex.uv = ImClamp(uv_a + ImMul(ImVec2{vertex.pos.x, vertex.pos.y} - a, scale), min, max);
        }
    }
    else
    {
        for &vertex in vertices {
            vertex.uv = uv_a + ImMul(ImVec2{vertex.pos.x, vertex.pos.y} - a, scale);
        }
    }
}

ShadeVertsTransformPos :: proc(draw_list : ^ImDrawList, vert_start_idx : i32, vert_end_idx : i32, pivot_in : ImVec2, cos_a : f32, sin_a : f32, pivot_out : ImVec2)
{
    for &vertex in draw_list.VtxBuffer[vert_start_idx:vert_end_idx] {
        vertex.pos = ImRotate(vertex.pos- pivot_in, cos_a, sin_a) + pivot_out;
    }
}

//-----------------------------------------------------------------------------
// [SECTION] ImFontConfig
//-----------------------------------------------------------------------------

init_ImFontConfig :: proc(this : ^ImFontConfig)
{
    this^ = {};
    this.FontDataOwnedByAtlas = true;
    this.OversampleH = 2;
    this.OversampleV = 1;
    this.GlyphMaxAdvanceX = math.F32_MAX;
    this.RasterizerMultiply = 1.0;
    this.RasterizerDensity = 1.0;
    this.EllipsisChar = 0;
}

make_ImFontConfig :: proc() -> (cfg : ImFontConfig) {
    init_ImFontConfig(&cfg)
    return cfg;
}

//-----------------------------------------------------------------------------
// [SECTION] ImFontAtlas
//-----------------------------------------------------------------------------
// - Default texture data encoded in ASCII
// - ImFontAtlas::ClearInputData()
// - ImFontAtlas::ClearTexData()
// - ImFontAtlas::ClearFonts()
// - ImFontAtlas::Clear()
// - ImFontAtlas::GetTexDataAsAlpha8()
// - ImFontAtlas::GetTexDataAsRGBA32()
// - ImFontAtlas::AddFont()
// - ImFontAtlas::AddFontDefault()
// - ImFontAtlas::AddFontFromFileTTF()
// - ImFontAtlas::AddFontFromMemoryTTF()
// - ImFontAtlas::AddFontFromMemoryCompressedTTF()
// - ImFontAtlas::AddFontFromMemoryCompressedBase85TTF()
// - ImFontAtlas::AddCustomRectRegular()
// - ImFontAtlas::AddCustomRectFontGlyph()
// - ImFontAtlas::CalcCustomRectUV()
// - ImFontAtlas::GetMouseCursorTexData()
// - ImFontAtlas::Build()
// - ImFontAtlasBuildMultiplyCalcLookupTable()
// - ImFontAtlasBuildMultiplyRectAlpha8()
// - ImFontAtlasBuildWithStbTruetype()
// - ImFontAtlasGetBuilderForStbTruetype()
// - ImFontAtlasUpdateConfigDataPointers()
// - ImFontAtlasBuildSetupFont()
// - ImFontAtlasBuildPackCustomRects()
// - ImFontAtlasBuildRender8bppRectFromString()
// - ImFontAtlasBuildRender32bppRectFromString()
// - ImFontAtlasBuildRenderDefaultTexData()
// - ImFontAtlasBuildRenderLinesTexData()
// - ImFontAtlasBuildInit()
// - ImFontAtlasBuildFinish()
//-----------------------------------------------------------------------------

// A work of art lies ahead! (. = white layer, X = black layer, others are blank)
// The 2x2 white texels on the top left are the ones we'll use everywhere in Dear ImGui to render filled shapes.
// (This is used when io.MouseDrawCursor = true)
FONT_ATLAS_DEFAULT_TEX_DATA_W :: 122; // Actual texture will be 2 times that + 1 spacing.
FONT_ATLAS_DEFAULT_TEX_DATA_H :: 27;
FONT_ATLAS_DEFAULT_TEX_DATA_PIXELS  : [FONT_ATLAS_DEFAULT_TEX_DATA_W * FONT_ATLAS_DEFAULT_TEX_DATA_H]u8 = (
    "..-         -XXXXXXX-    X    -           X           -XXXXXXX          -          XXXXXXX-     XX          - XX       XX "+
    "..-         -X.....X-   X.X   -          X.X          -X.....X          -          X.....X-    X..X         -X..X     X..X"+
    "---         -XXX.XXX-  X...X  -         X...X         -X....X           -           X....X-    X..X         -X...X   X...X"+
    "X           -  X.X  - X.....X -        X.....X        -X...X            -            X...X-    X..X         - X...X X...X "+
    "XX          -  X.X  -X.......X-       X.......X       -X..X.X           -           X.X..X-    X..X         -  X...X...X  "+
    "X.X         -  X.X  -XXXX.XXXX-       XXXX.XXXX       -X.X X.X          -          X.X X.X-    X..XXX       -   X.....X   "+
    "X..X        -  X.X  -   X.X   -          X.X          -XX   X.X         -         X.X   XX-    X..X..XXX    -    X...X    "+
    "X...X       -  X.X  -   X.X   -    XX    X.X    XX    -      X.X        -        X.X      -    X..X..X..XX  -     X.X     "+
    "X....X      -  X.X  -   X.X   -   X.X    X.X    X.X   -       X.X       -       X.X       -    X..X..X..X.X -    X...X    "+
    "X.....X     -  X.X  -   X.X   -  X..X    X.X    X..X  -        X.X      -      X.X        -XXX X..X..X..X..X-   X.....X   "+
    "X......X    -  X.X  -   X.X   - X...XXXXXX.XXXXXX...X -         X.X   XX-XX   X.X         -X..XX........X..X-  X...X...X  "+
    "X.......X   -  X.X  -   X.X   -X.....................X-          X.X X.X-X.X X.X          -X...X...........X- X...X X...X "+
    "X........X  -  X.X  -   X.X   - X...XXXXXX.XXXXXX...X -           X.X..X-X..X.X           - X..............X-X...X   X...X"+
    "X.........X -XXX.XXX-   X.X   -  X..X    X.X    X..X  -            X...X-X...X            -  X.............X-X..X     X..X"+
    "X..........X-X.....X-   X.X   -   X.X    X.X    X.X   -           X....X-X....X           -  X.............X- XX       XX "+
    "X......XXXXX-XXXXXXX-   X.X   -    XX    X.X    XX    -          X.....X-X.....X          -   X............X--------------"+
    "X...X..X    ---------   X.X   -          X.X          -          XXXXXXX-XXXXXXX          -   X...........X -             "+
    "X..X X..X   -       -XXXX.XXXX-       XXXX.XXXX       -------------------------------------    X..........X -             "+
    "X.X  X..X   -       -X.......X-       X.......X       -    XX           XX    -           -    X..........X -             "+
    "XX    X..X  -       - X.....X -        X.....X        -   X.X           X.X   -           -     X........X  -             "+
    "      X..X  -       -  X...X  -         X...X         -  X..X           X..X  -           -     X........X  -             "+
    "       XX   -       -   X.X   -          X.X          - X...XXXXXXXXXXXXX...X -           -     XXXXXXXXXX  -             "+
    "-------------       -    X    -           X           -X.....................X-           -------------------             "+
    "                    ----------------------------------- X...XXXXXXXXXXXXX...X -                                           "+
    "                                                      -  X..X           X..X  -                                           "+
    "                                                      -   X.X           X.X   -                                           "+
    "                                                      -    XX           XX    -                                           "+
"");

FONT_ATLAS_DEFAULT_TEX_CURSOR_DATA := [ImGuiMouseCursor][3]ImVec2 {
    // Pos ........ Size ......... Offset ......
    .Arrow      = { ImVec2{ 0,3}, ImVec2{12,19}, ImVec2{ 0, 0} }, // ImGuiMouseCursor_Arrow
    .TextInput  = { ImVec2{13,0}, ImVec2{ 7,16}, ImVec2{ 1, 8} }, // ImGuiMouseCursor_TextInput
    .ResizeAll  = { ImVec2{31,0}, ImVec2{23,23}, ImVec2{11,11} }, // ImGuiMouseCursor_ResizeAll
    .ResizeNS   = { ImVec2{21,0}, ImVec2{ 9,23}, ImVec2{ 4,11} }, // ImGuiMouseCursor_ResizeNS
    .ResizeEW   = { ImVec2{55,18},ImVec2{23, 9}, ImVec2{11, 4} }, // ImGuiMouseCursor_ResizeEW
    .ResizeNESW = { ImVec2{73,0}, ImVec2{17,17}, ImVec2{ 8, 8} }, // ImGuiMouseCursor_ResizeNESW
    .ResizeNWSE = { ImVec2{55,0}, ImVec2{17,17}, ImVec2{ 8, 8} }, // ImGuiMouseCursor_ResizeNWSE
    .Hand       = { ImVec2{91,0}, ImVec2{17,22}, ImVec2{ 5, 0} }, // ImGuiMouseCursor_Hand
    .NotAllowed = { ImVec2{109,0},ImVec2{13,15}, ImVec2{ 6, 7} }, // ImGuiMouseCursor_NotAllowed
};

init_ImFontAtlas :: proc(this : ^ImFontAtlas)
{
    this^ = {};
    this.TexGlyphPadding = 1;
    this.PackIdMouseCursors = -1;
    this.PackIdLines = -1;
}

deinit_ImFontAtlas :: proc(this : ^ImFontAtlas)
{
    assert(!this.Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");
    clear(this);
}

// [forward declared comment]:
// Clear input data (all ImFontConfig structures including sizes, TTF data, glyph ranges, etc.) = all the data used to build the texture and fonts.
ClearInputData :: proc(this : ^ImFontAtlas)
{
    assert(!this.Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");
    for &font_cfg in this.ConfigData {
        if (font_cfg.FontData != nil && font_cfg.FontDataOwnedByAtlas)
        {
            IM_FREE(font_cfg.FontData);
            font_cfg.FontData = nil;
        }
    }

    // When clearing this we lose access to the font name and other information used to build the font.
    for font in this.Fonts {
        if (font.ConfigData >= raw_data(this.ConfigData) && font.ConfigData < end(this.ConfigData))
        {
            font.ConfigData = nil;
            font.ConfigDataCount = 0;
        }
    }
    clear(&this.ConfigData)
    clear(&this.CustomRects)
    this.PackIdMouseCursors = -1;
    this.PackIdLines = -1;
    // Important: we leave TexReady untouched
}

// [forward declared comment]:
// Clear output texture data (CPU side). Saves RAM once the texture has been copied to graphics memory.
ClearTexData :: proc(this : ^ImFontAtlas)
{
    assert(!this.Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");
    if (this.TexPixelsAlpha8 != nil)   do IM_FREE(this.TexPixelsAlpha8)
    if (this.TexPixelsRGBA32 != nil)   do IM_FREE(this.TexPixelsRGBA32)
    this.TexPixelsAlpha8 = nil;
    this.TexPixelsRGBA32 = nil;
    this.TexPixelsUseColors = false;
    // Important: we leave TexReady untouched
}

// [forward declared comment]:
// Clear output font data (glyphs storage, UV coordinates).
ClearFonts :: proc(this : ^ImFontAtlas)
{
    assert(!this.Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");
    clear_delete(&this.Fonts);
    this.TexReady = false;
}

// [forward declared comment]:
// Clear all input and output.
ImFontAtlas_Clear :: proc(this : ^ImFontAtlas)
{
    ClearInputData(this);
    ClearTexData(this);
    ClearFonts(this);
}

// [forward declared comment]:
// 1 byte per-pixel
GetTexDataAsAlpha8 :: proc(this : ^ImFontAtlas, out_pixels : ^[^]u8, out_width : ^i32, out_height : ^i32, out_bytes_per_pixel : ^i32 = nil)
{
    // Build atlas on demand
    if (this.TexPixelsAlpha8 == nil)   do Build(this)

    out_pixels^ = this.TexPixelsAlpha8;
    if (out_width != nil) do out_width^ = this.TexWidth;
    if (out_height != nil) do out_height^ = this.TexHeight;
    if (out_bytes_per_pixel != nil) do out_bytes_per_pixel^ = 1;
}

// [forward declared comment]:
// 4 bytes-per-pixel
GetTexDataAsRGBA32 :: proc(this : ^ImFontAtlas, out_pixels : ^^u8, out_width : ^i32, out_height : ^i32, out_bytes_per_pixel : ^i32 = nil)
{
    // Convert to RGBA32 format on demand
    // Although it is likely to be the most commonly used format, our font rendering is 1 channel / 8 bpp
    if (this.TexPixelsRGBA32 == nil)
    {
        pixels : [^]u8;
        GetTexDataAsAlpha8(this, &pixels, nil, nil);
        if (pixels != nil)
        {
            this.TexPixelsRGBA32 = cast([^]u32) IM_ALLOC(cast(int) this.TexWidth * cast(int) this.TexHeight * 4);
            src := pixels;
            dst := this.TexPixelsRGBA32;
            for n := this.TexWidth * this.TexHeight; n > 0; n -= 1 {
                dst[0] = IM_COL32(255, 255, 255, src[0]);
                dst = dst[1:]
                src = src[1:]
            }
        }
    }

    out_pixels^ = cast(^u8) this.TexPixelsRGBA32;
    if (out_width != nil) do out_width^ = this.TexWidth;
    if (out_height != nil) do out_height^ = this.TexHeight;
    if (out_bytes_per_pixel != nil) do out_bytes_per_pixel^ = 4;
}

AddFont :: proc(this : ^ImFontAtlas, font_cfg : ^ImFontConfig) -> ^ImFont
{
    assert(!this.Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");
    assert(font_cfg.FontData != nil && font_cfg.FontDataSize > 0);
    assert(font_cfg.SizePixels > 0.0, "Is ImFontConfig struct correctly initialized?");
    assert(font_cfg.OversampleH > 0 && font_cfg.OversampleV > 0, "Is ImFontConfig struct correctly initialized?");
    assert(font_cfg.RasterizerDensity > 0.0);

    // Create new font
    if (!font_cfg.MergeMode) {
        append(&this.Fonts, IM_NEW(ImFont));
    }
    else {
        assert(len(this.Fonts) > 0, "Cannot use MergeMode for the first font"); // When using MergeMode make sure that a font has already been added before. You can use ImGui::GetIO().Fonts.AddFontDefault() to add the default imgui font.
    }

    append(&this.ConfigData, font_cfg^);
    new_font_cfg := back(this.ConfigData)
    if (new_font_cfg.DstFont == nil) {
        new_font_cfg.DstFont = back(this.Fonts)^
    }
    if (!new_font_cfg.FontDataOwnedByAtlas)
    {
        new_font_cfg.FontData = IM_ALLOC(new_font_cfg.FontDataSize);
        new_font_cfg.FontDataOwnedByAtlas = true;
        memcpy(new_font_cfg.FontData, font_cfg.FontData, cast(int) new_font_cfg.FontDataSize);
    }

    // Round font size
    // - We started rounding in 1.90 WIP (18991) as our layout system currently doesn't support non-rounded font size well yet.
    // - Note that using io.FontGlobalScale or SetWindowFontScale(), with are legacy-ish, partially supported features, can still lead to unrounded sizes.
    // - We may support it better later and remove this rounding.
    new_font_cfg.SizePixels = ImTrunc(new_font_cfg.SizePixels);

    // Pointers to ConfigData and BuilderData are otherwise dangling
    ImFontAtlasUpdateConfigDataPointers(this);

    // Invalidate texture
    this.TexReady = false;
    ClearTexData(this);
    return new_font_cfg.DstFont;
}

// Default font TTF is compressed with stb_compress then base85 encoded (see misc/fonts/binary_to_compressed_c.cpp for encoder)
Decode85Byte :: proc(c : u8) -> u32 { return u32(c >= '\\' ? c-36 : c-35); }
Decode85 :: proc(src : [^]u8, dst : [^]u8)
{
    src := src
    dst := dst

    for (src[0] != 0)
    {
        tmp := Decode85Byte(src[0]) + 85 * (Decode85Byte(src[1]) + 85 * (Decode85Byte(src[2]) + 85 * (Decode85Byte(src[3]) + 85 * Decode85Byte(src[4]))));
        dst[0] = u8((tmp >> 0) & 0xFF); dst[1] = u8((tmp >> 8) & 0xFF); dst[2] = u8((tmp >> 16) & 0xFF); dst[3] = u8((tmp >> 24) & 0xFF);   // We can't assume little-endianness.
        src = src[5:];
        dst = dst[4:];
    }
}

// Load embedded ProggyClean.ttf at size 13, disable oversampling
AddFontDefault :: proc(this : ^ImFontAtlas, font_cfg_template : ^ImFontConfig = nil) -> ^ImFont
{
when !(IMGUI_DISABLE_DEFAULT_FONT) {
    font_cfg : ImFontConfig = font_cfg_template != nil ? font_cfg_template^ : make_ImFontConfig();
    if (font_cfg_template == nil)
    {
        font_cfg.OversampleH = 1;
        font_cfg.OversampleV = 1;
        font_cfg.PixelSnapH = true;
    }
    if (font_cfg.SizePixels <= 0.0) {
        font_cfg.SizePixels = 13.0 * 1.0;
    }
    if (font_cfg.Name[0] == 0) {
        ImFormatString(raw_data(&font_cfg.Name), len(font_cfg.Name), "ProggyClean.ttf, %dpx", cast(i32) font_cfg.SizePixels);
    }
    font_cfg.EllipsisChar = ImWchar(0x0085);
    font_cfg.GlyphOffset.y = 1.0 * math.trunc(font_cfg.SizePixels / 13.0);  // Add +1 offset per 13 units

    ttf_compressed_size : i32 = 0;
    ttf_compressed := GetDefaultCompressedFontDataTTF(&ttf_compressed_size);
    glyph_ranges := font_cfg.GlyphRanges != nil ? font_cfg.GlyphRanges : GetGlyphRangesDefault(this);
    font := AddFontFromMemoryCompressedTTF(this, ttf_compressed, ttf_compressed_size, font_cfg.SizePixels, &font_cfg, glyph_ranges);
    return font;
} else {
    assert(false, "AddFontDefault() disabled in this build.");
    _ = font_cfg_template;
    return nil;
} // #ifndef IMGUI_DISABLE_DEFAULT_FONT
}

AddFontFromFileTTF :: proc(this : ^ImFontAtlas, filename : string, size_pixels : f32, font_cfg_template : ^ImFontConfig = nil, glyph_ranges : ^ImWchar = nil) -> ^ImFont
{
    assert(!this.Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");
    data_size : u64 = 0;
    data := ImFileLoadToMemory(filename, "rb", &data_size, 0);
    if (data == nil)
    {
        IM_ASSERT_USER_ERROR(false, "Could not load font file!");
        return nil;
    }
    font_cfg := font_cfg_template != nil ? font_cfg_template^ : make_ImFontConfig();
    if (font_cfg.Name[0] == 0)
    {
        // Store a short copy of filename into into the font name for convenience
        p_s := raw_data(filename)
        p := cast([^]u8) end(filename)
        for ; p > p_s && p[-1] != '/' && p[-1] != '\\'; p = p[-1:] {}
        ImFormatString(raw_data(&font_cfg.Name), len(font_cfg.Name), "%s, %.0px", p, size_pixels);
    }
    return AddFontFromMemoryTTF(this, data, cast(i32) data_size, size_pixels, &font_cfg, glyph_ranges);
}

// NB: Transfer ownership of 'ttf_data' to ImFontAtlas, unless font_cfg_template.FontDataOwnedByAtlas == false. Owned TTF buffer will be deleted after Build().
AddFontFromMemoryTTF :: proc(this : ^ImFontAtlas, font_data : rawptr, font_data_size : i32, size_pixels : f32, font_cfg_template : ^ImFontConfig, glyph_ranges : ^ImWchar) -> ^ImFont
{
    assert(!this.Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");
    font_cfg := font_cfg_template != nil ? font_cfg_template^ : make_ImFontConfig();
    assert(font_cfg.FontData == nil);
    assert(font_data_size > 100, "Incorrect value for font_data_size!"); // Heuristic to prevent accidentally passing a wrong value to font_data_size.
    font_cfg.FontData = font_data;
    font_cfg.FontDataSize = font_data_size;
    font_cfg.SizePixels = size_pixels > 0.0 ? size_pixels : font_cfg.SizePixels;
    if (glyph_ranges != nil) do font_cfg.GlyphRanges = glyph_ranges;
    return AddFont(this, &font_cfg);
}

// [forward declared comment]:
// 'compressed_font_data' still owned by caller. Compress with binary_to_compressed_c.cpp.
AddFontFromMemoryCompressedTTF :: proc(this : ^ImFontAtlas, compressed_ttf_data : rawptr, compressed_ttf_size : i32, size_pixels : f32, font_cfg_template : ^ImFontConfig = nil, glyph_ranges : ^ImWchar = nil) -> ^ImFont
{
    buf_decompressed_size := stb_decompress_length(cast(^u8) compressed_ttf_data);
    buf_decompressed_data := IM_ALLOC(buf_decompressed_size);
    stb_decompress(buf_decompressed_data, cast([^]u8) compressed_ttf_data, cast(u32) compressed_ttf_size);

    font_cfg := font_cfg_template != nil ? font_cfg_template^ : make_ImFontConfig();
    assert(font_cfg.FontData == nil);
    font_cfg.FontDataOwnedByAtlas = true;
    return AddFontFromMemoryTTF(this, buf_decompressed_data, cast(i32) buf_decompressed_size, size_pixels, &font_cfg, glyph_ranges);
}

// [forward declared comment]:
// 'compressed_font_data_base85' still owned by caller. Compress with binary_to_compressed_c.cpp with -base85 parameter.
AddFontFromMemoryCompressedBase85TTF :: proc(this : ^ImFontAtlas, compressed_ttf_data_base85 : [^]u8, size_pixels : f32, font_cfg : ^ImFontConfig = nil, glyph_ranges : ^ImWchar = nil) -> ^ImFont
{
    compressed_ttf_size := ((cast(i32) strlen(compressed_ttf_data_base85) + 4) / 5) * 4;
    compressed_ttf := IM_ALLOC(compressed_ttf_size);
    Decode85(compressed_ttf_data_base85, compressed_ttf);
    font := AddFontFromMemoryCompressedTTF(this, compressed_ttf, compressed_ttf_size, size_pixels, font_cfg, glyph_ranges);
    IM_FREE(compressed_ttf);
    return font;
}

AddCustomRectRegular :: proc(this : ^ImFontAtlas, width : i32, height : i32) -> i32
{
    assert(width > 0 && width <= 0xFFFF);
    assert(height > 0 && height <= 0xFFFF);
    r : ImFontAtlasCustomRect
    r.Width = cast(u16) width;
    r.Height = cast(u16) height;
    append(&this.CustomRects, r);
    return cast(i32) len(this.CustomRects) - 1; // Return index
}

AddCustomRectFontGlyph :: proc(this : ^ImFontAtlas, font : ^ImFont, id : ImWchar, width : i32, height : i32, advance_x : f32, offset : ImVec2 = {}) -> i32
{
when IMGUI_USE_WCHAR32 {
    assert(id <= IM_UNICODE_CODEPOINT_MAX);
}
    assert(font != nil);
    assert(width > 0 && width <= 0xFFFF);
    assert(height > 0 && height <= 0xFFFF);
    r : ImFontAtlasCustomRect
    r.Width = cast(u16) width;
    r.Height = cast(u16) height;
    r.GlyphID = u32(id);
    r.GlyphColored = false; // Set to 1 manually to mark glyph as colored // FIXME: No official API for that (#8133)
    r.GlyphAdvanceX = advance_x;
    r.GlyphOffset = offset;
    r.Font = font;
    append(&this.CustomRects, r);
    return cast(i32) len(this.CustomRects) - 1; // Return index
}

CalcCustomRectUV :: proc(this : ^ImFontAtlas, rect : ^ImFontAtlasCustomRect, out_uv_min : ^ImVec2, out_uv_max : ^ImVec2)
{
    assert(this.TexWidth > 0 && this.TexHeight > 0);   // Font atlas needs to be built before we can calculate UV coordinates
    assert(IsPacked(rect));                // Make sure the rectangle has been packed
    out_uv_min^ = ImVec2{cast(f32)rect.X * this.TexUvScale.x, cast(f32) rect.Y * this.TexUvScale.y};
    out_uv_max^ = ImVec2{cast(f32)(rect.X + rect.Width) * this.TexUvScale.x, cast(f32)(rect.Y + rect.Height) * this.TexUvScale.y};
}

GetMouseCursorTexData :: proc(this : ^ImFontAtlas, cursor_type : ImGuiMouseCursor, out_offset : ^ImVec2, out_size : ^ImVec2, out_uv_border : ^[2]ImVec2, out_uv_fill : ^[2]ImVec2) -> bool
{
    if (cursor_type <= min(ImGuiMouseCursor) || cursor_type >= ImGuiMouseCursor(len(ImGuiMouseCursor)))   do return false
    if (.NoMouseCursors in this.Flags)   do return false

    assert(this.PackIdMouseCursors != -1);
    r := GetCustomRectByIndex(this, this.PackIdMouseCursors);
    pos := FONT_ATLAS_DEFAULT_TEX_CURSOR_DATA[cursor_type][0] + ImVec2{cast(f32)r.X, cast(f32) r.Y};
    size := FONT_ATLAS_DEFAULT_TEX_CURSOR_DATA[cursor_type][1];
    out_size^ = size;
    out_offset^ = FONT_ATLAS_DEFAULT_TEX_CURSOR_DATA[cursor_type][2];
    out_uv_border[0] = (pos) * this.TexUvScale;
    out_uv_border[1] = (pos + size) * this.TexUvScale;
    pos.x += FONT_ATLAS_DEFAULT_TEX_DATA_W + 1;
    out_uv_fill[0] = (pos) * this.TexUvScale;
    out_uv_fill[1] = (pos + size) * this.TexUvScale;
    return true;
}

// [forward declared comment]:
// Build pixels data. This is called automatically for you by the GetTexData*** functions.
ImFontAtlas_Build :: proc(this : ^ImFontAtlas) -> bool
{
    assert(!this.Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");

    // Default font is none are specified
    if (len(this.ConfigData) == 0)   do AddFontDefault(this)

    // Select builder
    // - Note that we do not reassign to atlas.FontBuilderIO, since it is likely to point to static data which
    //   may mess with some hot-reloading schemes. If you need to assign to this (for dynamic selection) AND are
    //   using a hot-reloading scheme that messes up static data, store your own instance of ImFontBuilderIO somewhere
    //   and point to it instead of pointing directly to return value of the GetBuilderXXX functions.
    builder_io := this.FontBuilderIO;
    if (builder_io == nil)
    {
when IMGUI_ENABLE_FREETYPE {
        builder_io = GetBuilderForFreeType();
} else when IMGUI_ENABLE_STB_TRUETYPE {
        builder_io = ImFontAtlasGetBuilderForStbTruetype();
} else {
        assert(false) // Invalid Build function
}
    }

    // Build
    return builder_io.FontBuilder_Build(this);
}

ImFontAtlasBuildMultiplyCalcLookupTable :: proc(out_table : ^[256]u8, in_brighten_factor : f32)
{
    for i := 0; i < 256; i += 1
    {
        value := (u32)(f32(i) * in_brighten_factor);
        out_table[i] = value > 255 ? 255 : u8(value & 0xFF);
    }
}

ImFontAtlasBuildMultiplyRectAlpha8 :: proc(table : [256]u8, pixels : [^]u8, x : i32, y : i32, w : i32, h : i32, stride : i32)
{
    IM_ASSERT_PARANOID(w <= stride);
    data := pixels[x + y * stride:];
    for j := h; j > 0; j, data = j - 1, data[stride - w:] {
        for i := w; i > 0; i, data = i - 1, data[1:] {
            data[0] = table[data[0]];
        }
    }
}

when IMGUI_ENABLE_STB_TRUETYPE {
// Temporary data for one source font (multiple source fonts can be merged into one destination ImFont)
// (C++03 doesn't allow instancing ImVector<> with function-local types so we declare the type here.)
ImFontBuildSrcData :: struct
{
    FontInfo : stbtt.fontinfo,
    PackRange : stbtt.pack_range,          // Hold the list of codepoints to pack (essentially points to Codepoints.Data)
    Rects : [^]stbrp.Rect,              // Rectangle to pack. We first fill in their size and the packer will give us their position.
    PackedChars : [^]stbtt.packedchar,        // Output glyphs
    SrcRanges : [^]ImWchar,          // Ranges as requested by user (user is allowed to request too much, e.g. 0x0020..0xFFFF)
    DstIndex : i32,           // Index into atlas.Fonts[] and dst_tmp_array[]
    GlyphsHighest : i32,      // Highest requested codepoint
    GlyphsCount : i32,        // Glyph count (excluding missing glyphs and glyphs already set by an earlier source font)
    GlyphsSet : ImBitVector,          // Glyph bit map (random access, 1-bit per codepoint. This will be a maximum of 8KB)
    GlyphsList : [dynamic]rune,         // Glyph codepoints list (flattened version of GlyphsSet)
};

// Temporary data for one destination ImFont* (multiple source fonts can be merged into one destination ImFont)
ImFontBuildDstData :: struct
{
    SrcCount : i32,           // Number of source fonts targeting this destination font.
    GlyphsHighest : i32,
    GlyphsCount : i32,
    GlyphsSet : ImBitVector,          // This is used to resolve collision when multiple sources are merged into a same destination font.
};

UnpackBitVectorToFlatIndexList :: proc(bv : ^ImBitVector, out : ^[dynamic]rune)
{
    assert(size_of(bv.Storage[0]) == size_of(i32));
    it_begin := raw_data(bv.Storage);
    it_end := end(bv.Storage)
    for it := it_begin; it < it_end; it = it[1:] {
        if entries_32 := it[0]; entries_32 != 0 {
            for bit_n : u32 = 0; bit_n < 32; bit_n += 1 {
                if (entries_32 & (cast(u32) 1 << bit_n) != 0) {
                    append(out, (rune)(((mem.ptr_sub(it, it_begin)) << 5) + int(bit_n)));
                }
            }
        }
    }
}

ImFontAtlasBuildWithStbTruetype :: proc(atlas : ^ImFontAtlas) -> bool
{
    assert(len(atlas.ConfigData) > 0);

    ImFontAtlasBuildInit(atlas);

    // Clear atlas
    atlas.TexID = {};
    atlas.TexWidth = 0;
    atlas.TexHeight = 0;
    atlas.TexUvScale = ImVec2{0.0, 0.0};
    atlas.TexUvWhitePixel = ImVec2{0.0, 0.0};
    ClearTexData(atlas);

    // Temporary storage for building
    src_tmp_array : [dynamic]ImFontBuildSrcData
    dst_tmp_array : [dynamic]ImFontBuildDstData
    resize(&src_tmp_array, len(atlas.ConfigData));
    resize(&dst_tmp_array, len(atlas.Fonts));
    memset(raw_data(src_tmp_array), 0, len(src_tmp_array) * size_of(ImFontBuildSrcData));
    memset(raw_data(dst_tmp_array), 0, len(dst_tmp_array) * size_of(ImFontBuildDstData));

    // 1. Initialize font loading structure, check font data validity
    for src_i := 0; src_i < len(atlas.ConfigData); src_i += 1
    {
        src_tmp := &src_tmp_array[src_i];
        cfg := &atlas.ConfigData[src_i];
        assert(cfg.DstFont != nil && (!IsLoaded(cfg.DstFont) || cfg.DstFont.ContainerAtlas == atlas));

        // Find index from cfg.DstFont (we allow the user to set cfg.DstFont. Also it makes casual debugging nicer than when storing indices)
        src_tmp.DstIndex = -1;
        for output_i := 0; output_i < len(atlas.Fonts) && src_tmp.DstIndex == -1; output_i += 1 {
            if (cfg.DstFont == atlas.Fonts[output_i]) {
                src_tmp.DstIndex = cast(i32) output_i;
            }
        }
        if (src_tmp.DstIndex == -1)
        {
            assert(src_tmp.DstIndex != -1); // cfg.DstFont not pointing within atlas.Fonts[] array?
            return false;
        }
        // Initialize helper structure for font loading and verify that the TTF/OTF data is correct
        font_offset := stbtt.GetFontOffsetForIndex(cast([^]u8)cfg.FontData, cfg.FontNo);
        assert(font_offset >= 0, "FontData is incorrect, or FontNo cannot be found.");
        if (!stbtt.InitFont(&src_tmp.FontInfo, cast([^]u8)cfg.FontData, font_offset))
        {
            assert(false, "stbtt_InitFont(): failed to parse FontData. It is correct and complete? Check FontDataSize.");
            return false;
        }

        // Measure highest codepoints
        dst_tmp := &dst_tmp_array[src_tmp.DstIndex];
        src_tmp.SrcRanges = cfg.GlyphRanges != nil ? cfg.GlyphRanges : GetGlyphRangesDefault(atlas);
        for src_range := src_tmp.SrcRanges; src_range[0] != 0 && src_range[1] != 0; src_range = src_range[2:]
        {
            // Check for valid range. This may also help detect *some* dangling pointers, because a common
            // user error is to setup ImFontConfig::GlyphRanges with a pointer to data that isn't persistent,
            // or to forget to zero-terminate the glyph range array.
            assert(src_range[0] <= src_range[1], "Invalid range: is your glyph range array persistent? it is zero-terminated?");
            src_tmp.GlyphsHighest = ImMax(src_tmp.GlyphsHighest, cast(i32) src_range[1]);
        }
        dst_tmp.SrcCount += 1;
        dst_tmp.GlyphsHighest = ImMax(dst_tmp.GlyphsHighest, src_tmp.GlyphsHighest);
    }

    // 2. For every requested codepoint, check for their presence in the font data, and handle redundancy or overlaps between source fonts to avoid unused glyphs.
    total_glyphs_count := 0;
    for src_i := 0; src_i < len(src_tmp_array); src_i += 1
    {
        src_tmp := &src_tmp_array[src_i];
        dst_tmp := &dst_tmp_array[src_tmp.DstIndex];
        Create(&src_tmp.GlyphsSet, src_tmp.GlyphsHighest + 1);
        if (empty(dst_tmp.GlyphsSet.Storage)) {
            Create(&dst_tmp.GlyphsSet, dst_tmp.GlyphsHighest + 1);
        }

        for src_range := src_tmp.SrcRanges; src_range[0] != 0 && src_range[1] != 0; src_range = src_range[2:] {
            for codepoint := src_range[0]; codepoint <= src_range[1]; codepoint += 1 
            {
                if (TestBit(&dst_tmp.GlyphsSet, codepoint)) do continue    // Don't overwrite existing glyphs. We could make this an option for MergeMode (e.g. MergeOverwrite==true) 
                if (stbtt.FindGlyphIndex(&src_tmp.FontInfo, cast(rune) codepoint) == 0) do continue    // It is actually in the font?

                // Add to avail set/counters
                src_tmp.GlyphsCount += 1;
                dst_tmp.GlyphsCount += 1;
                SetBit(&src_tmp.GlyphsSet, codepoint);
                SetBit(&dst_tmp.GlyphsSet, codepoint);
                total_glyphs_count += 1;
            }
        }
    }

    // 3. Unpack our bit map into a flat list (we now have all the Unicode points that we know are requested _and_ available _and_ not overlapping another)
    for src_i := 0; src_i < len(src_tmp_array); src_i += 1
    {
        src_tmp := &src_tmp_array[src_i];
        reserve(&src_tmp.GlyphsList, src_tmp.GlyphsCount);
        UnpackBitVectorToFlatIndexList(&src_tmp.GlyphsSet, &src_tmp.GlyphsList);
        clear(&src_tmp.GlyphsSet)
        assert(len(src_tmp.GlyphsList) == cast(int) src_tmp.GlyphsCount);
    }
    for dst_i := 0; dst_i < len(dst_tmp_array); dst_i += 1 {
        clear(&dst_tmp_array[dst_i].GlyphsSet)
    }
    clear(&dst_tmp_array);

    // Allocate packing character data and flag packed characters buffer as non-packed (x0=y0=x1=y1=0)
    // (We technically don't need to zero-clear buf_rects, but let's do it for the sake of sanity)
    buf_rects : [dynamic]stbrp.Rect
    buf_packedchars : [dynamic]stbtt.packedchar
    resize(&buf_rects, total_glyphs_count);
    resize(&buf_packedchars, total_glyphs_count);
    memset(raw_data(buf_rects), 0, len(buf_rects) * size_of(stbrp.Rect));
    memset(raw_data(buf_packedchars), 0, len(buf_packedchars) * size_of(stbtt.packedchar));

     // the official one is missing h_/v_oversample
    stb_pack_range :: struct {
        font_size:                        f32,
        first_unicode_codepoint_in_range: i32,
        array_of_unicode_codepoints:      [^]rune,
        num_chars:                        i32,
        chardata_for_range:               ^stbtt.packedchar,
        h_oversample, v_oversample: u8,
    }

    // 4. Gather glyphs sizes so we can pack them in our virtual canvas.
    total_surface := 0;
    buf_rects_out_n : i32 = 0;
    buf_packedchars_out_n : i32 = 0;
    pack_padding := atlas.TexGlyphPadding;
    for src_i := 0; src_i < len(src_tmp_array); src_i += 1
    {
        src_tmp := &src_tmp_array[src_i];
        if (src_tmp.GlyphsCount == 0)   do continue

        src_tmp.Rects = &buf_rects[buf_rects_out_n];
        src_tmp.PackedChars = &buf_packedchars[buf_packedchars_out_n];
        buf_rects_out_n += src_tmp.GlyphsCount;
        buf_packedchars_out_n += src_tmp.GlyphsCount;

        // Convert our ranges in the format stb_truetype wants
        cfg := &atlas.ConfigData[src_i];
        src_tmp.PackRange.font_size = cfg.SizePixels * cfg.RasterizerDensity;
        src_tmp.PackRange.first_unicode_codepoint_in_range = 0;
        src_tmp.PackRange.array_of_unicode_codepoints = raw_data(src_tmp.GlyphsList);
        src_tmp.PackRange.num_chars = cast(i32) len(src_tmp.GlyphsList);
        src_tmp.PackRange.chardata_for_range = src_tmp.PackedChars;
        (transmute(^stb_pack_range) &src_tmp.PackRange).h_oversample = cast(u8) cfg.OversampleH;
        (transmute(^stb_pack_range) &src_tmp.PackRange).v_oversample = cast(u8) cfg.OversampleV;

        // Gather the sizes of all rectangles we will need to pack (this loop is based on stbtt_PackFontRangesGatherRects)
        scale := (cfg.SizePixels > 0.0) ? stbtt.ScaleForPixelHeight(&src_tmp.FontInfo, cfg.SizePixels * cfg.RasterizerDensity) : stbtt.ScaleForMappingEmToPixels(&src_tmp.FontInfo, -cfg.SizePixels * cfg.RasterizerDensity);
        for glyph_i := 0; glyph_i < len(src_tmp.GlyphsList); glyph_i += 1
        {
            x0, y0, x1, y1 : i32
            glyph_index_in_font := stbtt.FindGlyphIndex(&src_tmp.FontInfo, src_tmp.GlyphsList[glyph_i]);
            assert(glyph_index_in_font != 0);
            stbtt.GetGlyphBitmapBoxSubpixel(&src_tmp.FontInfo, glyph_index_in_font, scale * f32(cfg.OversampleH), scale * f32(cfg.OversampleV), 0, 0, &x0, &y0, &x1, &y1);
            src_tmp.Rects[glyph_i].w = (stbrp.Coord)(x1 - x0 + pack_padding + cfg.OversampleH - 1);
            src_tmp.Rects[glyph_i].h = (stbrp.Coord)(y1 - y0 + pack_padding + cfg.OversampleV - 1);
            total_surface += int(src_tmp.Rects[glyph_i].w * src_tmp.Rects[glyph_i].h);
        }
    }
    for i := 0; i < len(atlas.CustomRects); i += 1 {
        total_surface += int( (cast(i32) atlas.CustomRects[i].Width + pack_padding) * (cast(i32) atlas.CustomRects[i].Height + pack_padding) );
    }

    // We need a width for the skyline algorithm, any width!
    // The exact width doesn't really matter much, but some API/GPU have texture size limitations and increasing width can decrease height.
    // User can override TexDesiredWidth and TexGlyphPadding if they wish, otherwise we use a simple heuristic to select the width based on expected surface.
    surface_sqrt := cast(i32) math.sqrt(cast(f32) total_surface) + 1;
    atlas.TexHeight = 0;
    if (atlas.TexDesiredWidth > 0) {
        atlas.TexWidth = atlas.TexDesiredWidth;
    }
    else {
        atlas.TexWidth = (cast(f32) surface_sqrt >= (4096 * 0.7)) ? 4096 : (cast(f32) surface_sqrt >= (2048 * 0.7)) ? 2048 : (cast(f32) surface_sqrt >= (1024 * 0.7)) ? 1024 : 512;
    }

    // 5. Start packing
    // Pack our extra data rectangles first, so it will be on the upper-left corner of our texture (UV will have small values).
    TEX_HEIGHT_MAX : i32 = 1024 * 32;
    spc : stbtt.pack_context
    stbtt.PackBegin(&spc, nil, atlas.TexWidth, TEX_HEIGHT_MAX, 0, 0, nil);
    spc.padding = atlas.TexGlyphPadding; // Because we mixup stbtt_PackXXX and stbrp_PackXXX there's a bit of a hack here, not passing the value to stbtt_PackBegin() allows us to still pack a TexWidth-1 wide item. (#8107)
    ImFontAtlasBuildPackCustomRects(atlas, spc.pack_info);

    // 6. Pack each source font. No rendering yet, we are working with rectangles in an infinitely tall texture at this point.
    for src_i := 0; src_i < len(src_tmp_array); src_i += 1
    {
        src_tmp := &src_tmp_array[src_i];
        if (src_tmp.GlyphsCount == 0)   do continue

        stbrp.pack_rects(cast(^stbrp.Context)spc.pack_info, src_tmp.Rects, src_tmp.GlyphsCount);

        // Extend texture height and mark missing glyphs as non-packed so we won't render them.
        // FIXME: We are not handling packing failure here (would happen if we got off TEX_HEIGHT_MAX or if a single if larger than TexWidth?)
        for glyph_i : i32 = 0; glyph_i < src_tmp.GlyphsCount; glyph_i += 1 {
            if (src_tmp.Rects[glyph_i].was_packed) {
                atlas.TexHeight = ImMax(atlas.TexHeight, i32(src_tmp.Rects[glyph_i].y + src_tmp.Rects[glyph_i].h));
            }
        }
    }

    // 7. Allocate texture
    atlas.TexHeight = (.NoPowerOfTwoHeight in atlas.Flags) ? (atlas.TexHeight + 1) : cast(i32) ImUpperPowerOfTwo(cast(int) atlas.TexHeight);
    atlas.TexUvScale = ImVec2{f32(1) / cast(f32) atlas.TexWidth, f32(1) / cast(f32) atlas.TexHeight};
    atlas.TexPixelsAlpha8 = IM_ALLOC(atlas.TexWidth * atlas.TexHeight);
    memset(atlas.TexPixelsAlpha8, 0, atlas.TexWidth * atlas.TexHeight);
    spc.pixels = atlas.TexPixelsAlpha8;
    spc.height = atlas.TexHeight;

    // 8. Render/rasterize font characters into the texture
    for src_i := 0; src_i < len(src_tmp_array); src_i += 1
    {
        cfg := &atlas.ConfigData[src_i];
        src_tmp := &src_tmp_array[src_i];
        if (src_tmp.GlyphsCount == 0)   do continue

        stbtt.PackFontRangesRenderIntoRects(&spc, &src_tmp.FontInfo, &src_tmp.PackRange, 1, src_tmp.Rects);

        // Apply multiply operator
        if (cfg.RasterizerMultiply != 1.0)
        {
            multiply_table : [256]u8
            ImFontAtlasBuildMultiplyCalcLookupTable(&multiply_table, cfg.RasterizerMultiply);
            r := src_tmp.Rects;
            for glyph_i : i32 = 0; glyph_i < src_tmp.GlyphsCount; glyph_i, r = glyph_i + 1, r[1:] {
                if (r[0].was_packed) {
                    ImFontAtlasBuildMultiplyRectAlpha8(multiply_table, atlas.TexPixelsAlpha8, transmute(i32) r[0].x, transmute(i32) r[0].y, transmute(i32) r[0].w, transmute(i32) r[0].h, atlas.TexWidth * 1);
                }
            }
        }
        src_tmp.Rects = nil;
    }

    // End packing
    stbtt.PackEnd(&spc);
    clear(&buf_rects)

    // 9. Setup ImFont and glyphs for runtime
    for src_i := 0; src_i < len(src_tmp_array); src_i += 1
    {
        // When merging fonts with MergeMode=true:
        // - We can have multiple input fonts writing into a same destination font.
        // - dst_font.ConfigData is != from cfg which is our source configuration.
        src_tmp := &src_tmp_array[src_i];
        cfg := &atlas.ConfigData[src_i];
        dst_font := cfg.DstFont;

        font_scale := stbtt.ScaleForPixelHeight(&src_tmp.FontInfo, cfg.SizePixels);
        unscaled_ascent, unscaled_descent, unscaled_line_gap : i32
        stbtt.GetFontVMetrics(&src_tmp.FontInfo, &unscaled_ascent, &unscaled_descent, &unscaled_line_gap);

        ascent := ImCeil(f32(unscaled_ascent) * font_scale);
        descent := ImFloor(f32(unscaled_descent) * font_scale);
        ImFontAtlasBuildSetupFont(atlas, dst_font, cfg, ascent, descent);
        font_off_x := cfg.GlyphOffset.x;
        font_off_y := cfg.GlyphOffset.y + math.round(dst_font.Ascent);

        inv_rasterization_scale := 1.0 / cfg.RasterizerDensity;

        for glyph_i : i32 = 0; glyph_i < src_tmp.GlyphsCount; glyph_i += 1
        {
            // Register glyph
            codepoint := src_tmp.GlyphsList[glyph_i];
            pc := src_tmp.PackedChars[glyph_i];
            q : stbtt.aligned_quad
            unused_x, unused_y : f32
            stbtt.GetPackedQuad(src_tmp.PackedChars, atlas.TexWidth, atlas.TexHeight, glyph_i, &unused_x, &unused_y, &q, false);
            x0 := q.x0 * inv_rasterization_scale + font_off_x;
            y0 := q.y0 * inv_rasterization_scale + font_off_y;
            x1 := q.x1 * inv_rasterization_scale + font_off_x;
            y1 := q.y1 * inv_rasterization_scale + font_off_y;
            AddGlyph(dst_font, cfg, ImWchar(codepoint), x0, y0, x1, y1, q.s0, q.t0, q.s1, q.t1, pc.xadvance * inv_rasterization_scale);
        }
    }

    // Cleanup
    clear_destruct(&src_tmp_array);

    ImFontAtlasBuildFinish(atlas);
    return true;
}

ImFontAtlasGetBuilderForStbTruetype :: proc() -> ^ImFontBuilderIO
{
    @(static) io : ImFontBuilderIO;
    io.FontBuilder_Build = ImFontAtlasBuildWithStbTruetype;
    return &io;
}

} // IMGUI_ENABLE_STB_TRUETYPE

ImFontAtlasUpdateConfigDataPointers :: proc(atlas : ^ImFontAtlas)
{
    for &font_cfg in atlas.ConfigData
    {
        font := font_cfg.DstFont;
        if (!font_cfg.MergeMode)
        {
            font.ConfigData = &font_cfg;
            font.ConfigDataCount = 0;
        }
        font.ConfigDataCount += 1;
    }
}

ImFontAtlasBuildSetupFont :: proc(atlas : ^ImFontAtlas, font : ^ImFont, font_config : ^ImFontConfig, ascent : f32, descent : f32)
{
    if (!font_config.MergeMode)
    {
        ClearOutputData(font);
        font.FontSize = font_config.SizePixels;
        assert(font.ConfigData == font_config);
        font.ContainerAtlas = atlas;
        font.Ascent = ascent;
        font.Descent = descent;
    }
}

ImFontAtlasBuildPackCustomRects :: proc(atlas : ^ImFontAtlas, stbrp_context_opaque : rawptr)
{
    pack_context := cast(^stbrp.Context)stbrp_context_opaque;
    assert(pack_context != nil);

    user_rects := atlas.CustomRects;
    assert(len(user_rects) >= 1); // We expect at least the default custom rects to be registered, else something went wrong.

    pack_padding := atlas.TexGlyphPadding;
    pack_rects : [dynamic]stbrp.Rect
    resize(&pack_rects, len(user_rects));
    memset(raw_data(pack_rects), 0, len(pack_rects) * size_of(stbrp.Rect));
    for i := 0; i < len(user_rects); i += 1
    {
        pack_rects[i].w = stbrp.Coord(i32(user_rects[i].Width) + pack_padding);
        pack_rects[i].h = stbrp.Coord(i32(user_rects[i].Height) + pack_padding);
    }
    stbrp.pack_rects(pack_context, raw_data(pack_rects), cast(i32) len(pack_rects));
    for i := 0; i < len(pack_rects); i += 1 {
        if (pack_rects[i].was_packed)
        {
            user_rects[i].X = cast(u16) pack_rects[i].x;
            user_rects[i].Y = cast(u16) pack_rects[i].y;
            assert(transmute(i32) pack_rects[i].w == i32(user_rects[i].Width) + pack_padding && transmute(i32) pack_rects[i].h == i32(user_rects[i].Height) + pack_padding);
            atlas.TexHeight = ImMax(atlas.TexHeight, i32(pack_rects[i].y + pack_rects[i].h));
        }
    }
}

ImFontAtlasBuildRender8bppRectFromString :: proc(atlas : ^ImFontAtlas, x : i32, y : i32, w : i32, h : i32, in_str : [^]u8, in_marker_char : u8, in_marker_pixel_value : u8)
{
    in_str := in_str

    assert(x >= 0 && x + w <= atlas.TexWidth);
    assert(y >= 0 && y + h <= atlas.TexHeight);
    out_pixel := atlas.TexPixelsAlpha8[x + (y * atlas.TexWidth):];
    for off_y : i32 = 0; off_y < h; off_y, out_pixel, in_str  =  off_y + 1, out_pixel[atlas.TexWidth:], in_str[w:] {
        for off_x : i32 = 0; off_x < w; off_x += 1 {
            out_pixel[off_x] = (in_str[off_x] == in_marker_char) ? in_marker_pixel_value : 0x00;
        }
    }
}

ImFontAtlasBuildRender32bppRectFromString :: proc(atlas : ^ImFontAtlas, x : i32, y : i32, w : i32, h : i32, in_str : [^]u8, in_marker_char : u8, in_marker_pixel_value : u32)
{
    in_str := in_str

    assert(x >= 0 && x + w <= atlas.TexWidth);
    assert(y >= 0 && y + h <= atlas.TexHeight);
    out_pixel := atlas.TexPixelsRGBA32[x + (y * atlas.TexWidth):];
    for off_y : i32 = 0; off_y < h; off_y, out_pixel, in_str  =  off_y + 1, out_pixel[atlas.TexWidth:], in_str[w:] {
        for off_x : i32 = 0; off_x < w; off_x += 1 {
            out_pixel[off_x] = (in_str[off_x] == in_marker_char) ? in_marker_pixel_value : IM_COL32_BLACK_TRANS;
        }
    }
}

ImFontAtlasBuildRenderDefaultTexData :: proc(atlas : ^ImFontAtlas)
{
    r := GetCustomRectByIndex(atlas, atlas.PackIdMouseCursors);
    assert(IsPacked(r));

    w := atlas.TexWidth;
    if (.NoMouseCursors in atlas.Flags)
    {
        // White pixels only
        assert(r.Width == 2 && r.Height == 2);
        offset := cast(i32) r.X + cast(i32) r.Y * w;
        if (atlas.TexPixelsAlpha8 != nil)
        {
            atlas.TexPixelsAlpha8[offset] = 0xFF
            atlas.TexPixelsAlpha8[offset + 1] = 0xFF
            atlas.TexPixelsAlpha8[offset + w] = 0xFF
            atlas.TexPixelsAlpha8[offset + w + 1] = 0xFF;
        }
        else
        {
            atlas.TexPixelsRGBA32[offset] = IM_COL32_WHITE
            atlas.TexPixelsRGBA32[offset + 1] = IM_COL32_WHITE
            atlas.TexPixelsRGBA32[offset + w] = IM_COL32_WHITE
            atlas.TexPixelsRGBA32[offset + w + 1] = IM_COL32_WHITE;
        }
    }
    else
    {
        // White pixels and mouse cursor
        assert(r.Width == FONT_ATLAS_DEFAULT_TEX_DATA_W * 2 + 1 && r.Height == FONT_ATLAS_DEFAULT_TEX_DATA_H);
        x_for_white := i32(r.X);
        x_for_black := i32(r.X + FONT_ATLAS_DEFAULT_TEX_DATA_W + 1);
        if (atlas.TexPixelsAlpha8 != nil)
        {
            ImFontAtlasBuildRender8bppRectFromString(atlas, x_for_white, i32(r.Y), FONT_ATLAS_DEFAULT_TEX_DATA_W, FONT_ATLAS_DEFAULT_TEX_DATA_H, raw_data(&FONT_ATLAS_DEFAULT_TEX_DATA_PIXELS), '.', 0xFF);
            ImFontAtlasBuildRender8bppRectFromString(atlas, x_for_black, i32(r.Y), FONT_ATLAS_DEFAULT_TEX_DATA_W, FONT_ATLAS_DEFAULT_TEX_DATA_H, raw_data(&FONT_ATLAS_DEFAULT_TEX_DATA_PIXELS), 'X', 0xFF);
        }
        else
        {
            ImFontAtlasBuildRender32bppRectFromString(atlas, x_for_white, i32(r.Y), FONT_ATLAS_DEFAULT_TEX_DATA_W, FONT_ATLAS_DEFAULT_TEX_DATA_H, raw_data(&FONT_ATLAS_DEFAULT_TEX_DATA_PIXELS), '.', IM_COL32_WHITE);
            ImFontAtlasBuildRender32bppRectFromString(atlas, x_for_black, i32(r.Y), FONT_ATLAS_DEFAULT_TEX_DATA_W, FONT_ATLAS_DEFAULT_TEX_DATA_H, raw_data(&FONT_ATLAS_DEFAULT_TEX_DATA_PIXELS), 'X', IM_COL32_WHITE);
        }
    }
    atlas.TexUvWhitePixel = ImVec2{(f32(r.X) + 0.5) * atlas.TexUvScale.x, (f32(r.Y) + 0.5) * atlas.TexUvScale.y};
}

ImFontAtlasBuildRenderLinesTexData :: proc(atlas : ^ImFontAtlas)
{
    if (.NoBakedLines in atlas.Flags)   do return

    // This generates a triangular shape in the texture, with the various line widths stacked on top of each other to allow interpolation between them
    r := GetCustomRectByIndex(atlas, atlas.PackIdLines);
    assert(IsPacked(r));
    for n : u16 = 0; n < IM_DRAWLIST_TEX_LINES_WIDTH_MAX + 1; n += 1 // +1 because of the zero-width row
    {
        // Each line consists of at least two empty pixels at the ends, with a line of solid pixels in the middle
        y := n;
        line_width := n;
        pad_left := (r.Width - line_width) / 2;
        pad_right := r.Width - (pad_left + line_width);

        // Write each slice
        assert(pad_left + line_width + pad_right == r.Width && y < r.Height); // Make sure we're inside the texture bounds before we start writing pixels
        if (atlas.TexPixelsAlpha8 != nil)
        {
            write_ptr := atlas.TexPixelsAlpha8[i32(r.X) + (i32(r.Y + y) * atlas.TexWidth):];
            for i : u16 = 0; i < pad_left; i += 1 {
                write_ptr[i] = 0x00;
            }

            for i : u16 = 0; i < line_width; i += 1 {
                write_ptr[pad_left + i] = 0xFF;
            }

            for i : u16 = 0; i < pad_right; i += 1 {
                write_ptr[pad_left + line_width + i] = 0x00;
            }
        }
        else
        {
            write_ptr := atlas.TexPixelsRGBA32[i32(r.X) + (i32(r.Y + y) * atlas.TexWidth):];
            for i : u16 = 0; i < pad_left; i += 1 {
                write_ptr[i] = IM_COL32(255, 255, 255, 0);
            }

            for i : u16 = 0; i < line_width; i += 1 {
                write_ptr[pad_left + i] = IM_COL32_WHITE;
            }

            for i : u16 = 0; i < pad_right; i += 1 {
                write_ptr[pad_left + line_width + i] = IM_COL32(255, 255, 255, 0);
            }
        }

        // Calculate UVs for this line
        uv0 := ImVec2{cast(f32)(r.X + pad_left - 1), cast(f32)(r.Y + y)} * atlas.TexUvScale;
        uv1 := ImVec2{cast(f32)(r.X + pad_left + line_width + 1), cast(f32)(r.Y + y + 1)} * atlas.TexUvScale;
        half_v := (uv0.y + uv1.y) * 0.5; // Calculate a constant V in the middle of the row to avoid sampling artifacts
        atlas.TexUvLines[n] = ImVec4{uv0.x, half_v, uv1.x, half_v};
    }
}

// Note: this is called / shared by both the stb_truetype and the FreeType builder
ImFontAtlasBuildInit :: proc(atlas : ^ImFontAtlas)
{
    // Register texture region for mouse cursors or standard white pixels
    if (atlas.PackIdMouseCursors < 0)
    {
        if (!(.NoMouseCursors in atlas.Flags)) {
            atlas.PackIdMouseCursors = AddCustomRectRegular(atlas, FONT_ATLAS_DEFAULT_TEX_DATA_W * 2 + 1, FONT_ATLAS_DEFAULT_TEX_DATA_H);
        }
        else {
            atlas.PackIdMouseCursors = AddCustomRectRegular(atlas, 2, 2);
        }
    }

    // Register texture region for thick lines
    // The +2 here is to give space for the end caps, whilst height +1 is to accommodate the fact we have a zero-width row
    if (atlas.PackIdLines < 0)
    {
        if (!(.NoBakedLines in atlas.Flags)) {
            atlas.PackIdLines = AddCustomRectRegular(atlas, IM_DRAWLIST_TEX_LINES_WIDTH_MAX + 2, IM_DRAWLIST_TEX_LINES_WIDTH_MAX + 1);
        }
    }
}

// This is called/shared by both the stb_truetype and the FreeType builder.
ImFontAtlasBuildFinish :: proc(atlas : ^ImFontAtlas)
{
    // Render into our custom data blocks
    assert(atlas.TexPixelsAlpha8 != nil || atlas.TexPixelsRGBA32 != nil);
    ImFontAtlasBuildRenderDefaultTexData(atlas);
    ImFontAtlasBuildRenderLinesTexData(atlas);

    // Register custom rectangle glyphs
    for i := 0; i < len(atlas.CustomRects); i += 1
    {
        r: = &atlas.CustomRects[i];
        if (r.Font == nil || r.GlyphID == 0)   do continue

        // Will ignore ImFontConfig settings: GlyphMinAdvanceX, GlyphMinAdvanceY, GlyphExtraSpacing, PixelSnapH
        assert(r.Font.ContainerAtlas == atlas);
        uv0, uv1 : ImVec2
        CalcCustomRectUV(atlas, r, &uv0, &uv1);
        AddGlyph(r.Font, nil, ImWchar(r.GlyphID), r.GlyphOffset.x, r.GlyphOffset.y, r.GlyphOffset.x + f32(r.Width), r.GlyphOffset.y + f32(r.Height), uv0.x, uv0.y, uv1.x, uv1.y, r.GlyphAdvanceX);
        if (r.GlyphColored) {
            back(r.Font.Glyphs).Colored = true;
        }
    }

    // Build all fonts lookup tables
    for font in atlas.Fonts {
        if (font.DirtyLookupTables)   do BuildLookupTable(font)
    }

    atlas.TexReady = true;
}

//-------------------------------------------------------------------------
// [SECTION] ImFontAtlas: glyph ranges helpers
//-------------------------------------------------------------------------
// - GetGlyphRangesDefault()
// - GetGlyphRangesGreek()
// - GetGlyphRangesKorean()
// - GetGlyphRangesChineseFull()
// - GetGlyphRangesChineseSimplifiedCommon()
// - GetGlyphRangesJapanese()
// - GetGlyphRangesCyrillic()
// - GetGlyphRangesThai()
// - GetGlyphRangesVietnamese()
//-----------------------------------------------------------------------------

// Retrieve list of range (2 int per range, values are inclusive)
// [forward declared comment]:
// Basic Latin, Extended Latin
GetGlyphRangesDefault :: proc(this : ^ImFontAtlas) -> [^]ImWchar
{
    @(static) ranges := [?]ImWchar {
        0x0020, 0x00FF, // Basic Latin + Latin Supplement
        0,
    };
    return raw_data(&ranges);
}

// [forward declared comment]:
// Default + Greek and Coptic
GetGlyphRangesGreek :: proc(this : ^ImFontAtlas) -> [^]ImWchar
{
    @(static) ranges := [?]ImWchar {
        0x0020, 0x00FF, // Basic Latin + Latin Supplement
        0x0370, 0x03FF, // Greek and Coptic
        0,
    };
    return raw_data(&ranges);
}

// [forward declared comment]:
// Default + Korean characters
GetGlyphRangesKorean :: proc(this : ^ImFontAtlas) -> [^]ImWchar
{
    @(static) ranges := [?]ImWchar {
        0x0020, 0x00FF, // Basic Latin + Latin Supplement
        0x3131, 0x3163, // Korean alphabets
        0xAC00, 0xD7A3, // Korean characters
        0xFFFD, 0xFFFD, // Invalid
        0,
    };
    return raw_data(&ranges);
}

// [forward declared comment]:
// Default + Half-Width + Japanese Hiragana/Katakana + full set of about 21000 CJK Unified Ideographs
GetGlyphRangesChineseFull :: proc(this : ^ImFontAtlas) -> [^]ImWchar
{
    @(static) ranges := [?]ImWchar {
        0x0020, 0x00FF, // Basic Latin + Latin Supplement
        0x2000, 0x206F, // General Punctuation
        0x3000, 0x30FF, // CJK Symbols and Punctuations, Hiragana, Katakana
        0x31F0, 0x31FF, // Katakana Phonetic Extensions
        0xFF00, 0xFFEF, // Half-width characters
        0xFFFD, 0xFFFD, // Invalid
        0x4e00, 0x9FAF, // CJK Ideograms
        0,
    };
    return raw_data(&ranges);
}

UnpackAccumulativeOffsetsIntoRanges :: proc(base_codepoint : i32, accumulative_offsets : []i16, out_ranges : [^]ImWchar)
{
    base_codepoint := base_codepoint
    out_ranges := out_ranges

    for n := 0; n < len(accumulative_offsets); n, out_ranges = n + 1, out_ranges[2:]
    {
        out_ranges[1] = ImWchar(base_codepoint + i32(accumulative_offsets[n]));
        out_ranges[0] = out_ranges[1]
        base_codepoint += i32(accumulative_offsets[n]);
    }
    out_ranges[0] = 0;
}

// [forward declared comment]:
// Default + Half-Width + Japanese Hiragana/Katakana + set of 2500 CJK Unified Ideographs for common simplified Chinese
GetGlyphRangesChineseSimplifiedCommon :: proc(this : ^ImFontAtlas) -> [^]ImWchar
{
    // Store 2500 regularly used characters for Simplified Chinese.
    // Sourced from https://zh.wiktionary.org/wiki/%E9%99%84%E5%BD%95:%E7%8E%B0%E4%BB%A3%E6%B1%89%E8%AF%AD%E5%B8%B8%E7%94%A8%E5%AD%97%E8%A1%A8
    // This table covers 97.97% of all characters used during the month in July, 1987.
    // You can use ImFontGlyphRangesBuilder to create your own ranges derived from this, by merging existing ranges or adding new characters.
    // (Stored as accumulative offsets from the initial unicode codepoint 0x4E00. This encoding is designed to helps us compact the source code size.)
    @(static) accumulative_offsets_from_0x4E00 := [?]i16 {
        0,1,2,4,1,1,1,1,2,1,3,2,1,2,2,1,1,1,1,1,5,2,1,2,3,3,3,2,2,4,1,1,1,2,1,5,2,3,1,2,1,2,1,1,2,1,1,2,2,1,4,1,1,1,1,5,10,1,2,19,2,1,2,1,2,1,2,1,2,
        1,5,1,6,3,2,1,2,2,1,1,1,4,8,5,1,1,4,1,1,3,1,2,1,5,1,2,1,1,1,10,1,1,5,2,4,6,1,4,2,2,2,12,2,1,1,6,1,1,1,4,1,1,4,6,5,1,4,2,2,4,10,7,1,1,4,2,4,
        2,1,4,3,6,10,12,5,7,2,14,2,9,1,1,6,7,10,4,7,13,1,5,4,8,4,1,1,2,28,5,6,1,1,5,2,5,20,2,2,9,8,11,2,9,17,1,8,6,8,27,4,6,9,20,11,27,6,68,2,2,1,1,
        1,2,1,2,2,7,6,11,3,3,1,1,3,1,2,1,1,1,1,1,3,1,1,8,3,4,1,5,7,2,1,4,4,8,4,2,1,2,1,1,4,5,6,3,6,2,12,3,1,3,9,2,4,3,4,1,5,3,3,1,3,7,1,5,1,1,1,1,2,
        3,4,5,2,3,2,6,1,1,2,1,7,1,7,3,4,5,15,2,2,1,5,3,22,19,2,1,1,1,1,2,5,1,1,1,6,1,1,12,8,2,9,18,22,4,1,1,5,1,16,1,2,7,10,15,1,1,6,2,4,1,2,4,1,6,
        1,1,3,2,4,1,6,4,5,1,2,1,1,2,1,10,3,1,3,2,1,9,3,2,5,7,2,19,4,3,6,1,1,1,1,1,4,3,2,1,1,1,2,5,3,1,1,1,2,2,1,1,2,1,1,2,1,3,1,1,1,3,7,1,4,1,1,2,1,
        1,2,1,2,4,4,3,8,1,1,1,2,1,3,5,1,3,1,3,4,6,2,2,14,4,6,6,11,9,1,15,3,1,28,5,2,5,5,3,1,3,4,5,4,6,14,3,2,3,5,21,2,7,20,10,1,2,19,2,4,28,28,2,3,
        2,1,14,4,1,26,28,42,12,40,3,52,79,5,14,17,3,2,2,11,3,4,6,3,1,8,2,23,4,5,8,10,4,2,7,3,5,1,1,6,3,1,2,2,2,5,28,1,1,7,7,20,5,3,29,3,17,26,1,8,4,
        27,3,6,11,23,5,3,4,6,13,24,16,6,5,10,25,35,7,3,2,3,3,14,3,6,2,6,1,4,2,3,8,2,1,1,3,3,3,4,1,1,13,2,2,4,5,2,1,14,14,1,2,2,1,4,5,2,3,1,14,3,12,
        3,17,2,16,5,1,2,1,8,9,3,19,4,2,2,4,17,25,21,20,28,75,1,10,29,103,4,1,2,1,1,4,2,4,1,2,3,24,2,2,2,1,1,2,1,3,8,1,1,1,2,1,1,3,1,1,1,6,1,5,3,1,1,
        1,3,4,1,1,5,2,1,5,6,13,9,16,1,1,1,1,3,2,3,2,4,5,2,5,2,2,3,7,13,7,2,2,1,1,1,1,2,3,3,2,1,6,4,9,2,1,14,2,14,2,1,18,3,4,14,4,11,41,15,23,15,23,
        176,1,3,4,1,1,1,1,5,3,1,2,3,7,3,1,1,2,1,2,4,4,6,2,4,1,9,7,1,10,5,8,16,29,1,1,2,2,3,1,3,5,2,4,5,4,1,1,2,2,3,3,7,1,6,10,1,17,1,44,4,6,2,1,1,6,
        5,4,2,10,1,6,9,2,8,1,24,1,2,13,7,8,8,2,1,4,1,3,1,3,3,5,2,5,10,9,4,9,12,2,1,6,1,10,1,1,7,7,4,10,8,3,1,13,4,3,1,6,1,3,5,2,1,2,17,16,5,2,16,6,
        1,4,2,1,3,3,6,8,5,11,11,1,3,3,2,4,6,10,9,5,7,4,7,4,7,1,1,4,2,1,3,6,8,7,1,6,11,5,5,3,24,9,4,2,7,13,5,1,8,82,16,61,1,1,1,4,2,2,16,10,3,8,1,1,
        6,4,2,1,3,1,1,1,4,3,8,4,2,2,1,1,1,1,1,6,3,5,1,1,4,6,9,2,1,1,1,2,1,7,2,1,6,1,5,4,4,3,1,8,1,3,3,1,3,2,2,2,2,3,1,6,1,2,1,2,1,3,7,1,8,2,1,2,1,5,
        2,5,3,5,10,1,2,1,1,3,2,5,11,3,9,3,5,1,1,5,9,1,2,1,5,7,9,9,8,1,3,3,3,6,8,2,3,2,1,1,32,6,1,2,15,9,3,7,13,1,3,10,13,2,14,1,13,10,2,1,3,10,4,15,
        2,15,15,10,1,3,9,6,9,32,25,26,47,7,3,2,3,1,6,3,4,3,2,8,5,4,1,9,4,2,2,19,10,6,2,3,8,1,2,2,4,2,1,9,4,4,4,6,4,8,9,2,3,1,1,1,1,3,5,5,1,3,8,4,6,
        2,1,4,12,1,5,3,7,13,2,5,8,1,6,1,2,5,14,6,1,5,2,4,8,15,5,1,23,6,62,2,10,1,1,8,1,2,2,10,4,2,2,9,2,1,1,3,2,3,1,5,3,3,2,1,3,8,1,1,1,11,3,1,1,4,
        3,7,1,14,1,2,3,12,5,2,5,1,6,7,5,7,14,11,1,3,1,8,9,12,2,1,11,8,4,4,2,6,10,9,13,1,1,3,1,5,1,3,2,4,4,1,18,2,3,14,11,4,29,4,2,7,1,3,13,9,2,2,5,
        3,5,20,7,16,8,5,72,34,6,4,22,12,12,28,45,36,9,7,39,9,191,1,1,1,4,11,8,4,9,2,3,22,1,1,1,1,4,17,1,7,7,1,11,31,10,2,4,8,2,3,2,1,4,2,16,4,32,2,
        3,19,13,4,9,1,5,2,14,8,1,1,3,6,19,6,5,1,16,6,2,10,8,5,1,2,3,1,5,5,1,11,6,6,1,3,3,2,6,3,8,1,1,4,10,7,5,7,7,5,8,9,2,1,3,4,1,1,3,1,3,3,2,6,16,
        1,4,6,3,1,10,6,1,3,15,2,9,2,10,25,13,9,16,6,2,2,10,11,4,3,9,1,2,6,6,5,4,30,40,1,10,7,12,14,33,6,3,6,7,3,1,3,1,11,14,4,9,5,12,11,49,18,51,31,
        140,31,2,2,1,5,1,8,1,10,1,4,4,3,24,1,10,1,3,6,6,16,3,4,5,2,1,4,2,57,10,6,22,2,22,3,7,22,6,10,11,36,18,16,33,36,2,5,5,1,1,1,4,10,1,4,13,2,7,
        5,2,9,3,4,1,7,43,3,7,3,9,14,7,9,1,11,1,1,3,7,4,18,13,1,14,1,3,6,10,73,2,2,30,6,1,11,18,19,13,22,3,46,42,37,89,7,3,16,34,2,2,3,9,1,7,1,1,1,2,
        2,4,10,7,3,10,3,9,5,28,9,2,6,13,7,3,1,3,10,2,7,2,11,3,6,21,54,85,2,1,4,2,2,1,39,3,21,2,2,5,1,1,1,4,1,1,3,4,15,1,3,2,4,4,2,3,8,2,20,1,8,7,13,
        4,1,26,6,2,9,34,4,21,52,10,4,4,1,5,12,2,11,1,7,2,30,12,44,2,30,1,1,3,6,16,9,17,39,82,2,2,24,7,1,7,3,16,9,14,44,2,1,2,1,2,3,5,2,4,1,6,7,5,3,
        2,6,1,11,5,11,2,1,18,19,8,1,3,24,29,2,1,3,5,2,2,1,13,6,5,1,46,11,3,5,1,1,5,8,2,10,6,12,6,3,7,11,2,4,16,13,2,5,1,1,2,2,5,2,28,5,2,23,10,8,4,
        4,22,39,95,38,8,14,9,5,1,13,5,4,3,13,12,11,1,9,1,27,37,2,5,4,4,63,211,95,2,2,2,1,3,5,2,1,1,2,2,1,1,1,3,2,4,1,2,1,1,5,2,2,1,1,2,3,1,3,1,1,1,
        3,1,4,2,1,3,6,1,1,3,7,15,5,3,2,5,3,9,11,4,2,22,1,6,3,8,7,1,4,28,4,16,3,3,25,4,4,27,27,1,4,1,2,2,7,1,3,5,2,28,8,2,14,1,8,6,16,25,3,3,3,14,3,
        3,1,1,2,1,4,6,3,8,4,1,1,1,2,3,6,10,6,2,3,18,3,2,5,5,4,3,1,5,2,5,4,23,7,6,12,6,4,17,11,9,5,1,1,10,5,12,1,1,11,26,33,7,3,6,1,17,7,1,5,12,1,11,
        2,4,1,8,14,17,23,1,2,1,7,8,16,11,9,6,5,2,6,4,16,2,8,14,1,11,8,9,1,1,1,9,25,4,11,19,7,2,15,2,12,8,52,7,5,19,2,16,4,36,8,1,16,8,24,26,4,6,2,9,
        5,4,36,3,28,12,25,15,37,27,17,12,59,38,5,32,127,1,2,9,17,14,4,1,2,1,1,8,11,50,4,14,2,19,16,4,17,5,4,5,26,12,45,2,23,45,104,30,12,8,3,10,2,2,
        3,3,1,4,20,7,2,9,6,15,2,20,1,3,16,4,11,15,6,134,2,5,59,1,2,2,2,1,9,17,3,26,137,10,211,59,1,2,4,1,4,1,1,1,2,6,2,3,1,1,2,3,2,3,1,3,4,4,2,3,3,
        1,4,3,1,7,2,2,3,1,2,1,3,3,3,2,2,3,2,1,3,14,6,1,3,2,9,6,15,27,9,34,145,1,1,2,1,1,1,1,2,1,1,1,1,2,2,2,3,1,2,1,1,1,2,3,5,8,3,5,2,4,1,3,2,2,2,12,
        4,1,1,1,10,4,5,1,20,4,16,1,15,9,5,12,2,9,2,5,4,2,26,19,7,1,26,4,30,12,15,42,1,6,8,172,1,1,4,2,1,1,11,2,2,4,2,1,2,1,10,8,1,2,1,4,5,1,2,5,1,8,
        4,1,3,4,2,1,6,2,1,3,4,1,2,1,1,1,1,12,5,7,2,4,3,1,1,1,3,3,6,1,2,2,3,3,3,2,1,2,12,14,11,6,6,4,12,2,8,1,7,10,1,35,7,4,13,15,4,3,23,21,28,52,5,
        26,5,6,1,7,10,2,7,53,3,2,1,1,1,2,163,532,1,10,11,1,3,3,4,8,2,8,6,2,2,23,22,4,2,2,4,2,1,3,1,3,3,5,9,8,2,1,2,8,1,10,2,12,21,20,15,105,2,3,1,1,
        3,2,3,1,1,2,5,1,4,15,11,19,1,1,1,1,5,4,5,1,1,2,5,3,5,12,1,2,5,1,11,1,1,15,9,1,4,5,3,26,8,2,1,3,1,1,15,19,2,12,1,2,5,2,7,2,19,2,20,6,26,7,5,
        2,2,7,34,21,13,70,2,128,1,1,2,1,1,2,1,1,3,2,2,2,15,1,4,1,3,4,42,10,6,1,49,85,8,1,2,1,1,4,4,2,3,6,1,5,7,4,3,211,4,1,2,1,2,5,1,2,4,2,2,6,5,6,
        10,3,4,48,100,6,2,16,296,5,27,387,2,2,3,7,16,8,5,38,15,39,21,9,10,3,7,59,13,27,21,47,5,21,6
    };
    @(static) base_ranges := [?]ImWchar {// not zero-terminated
        0x0020, 0x00FF, // Basic Latin + Latin Supplement
        0x2000, 0x206F, // General Punctuation
        0x3000, 0x30FF, // CJK Symbols and Punctuations, Hiragana, Katakana
        0x31F0, 0x31FF, // Katakana Phonetic Extensions
        0xFF00, 0xFFEF, // Half-width characters
        0xFFFD, 0xFFFD  // Invalid
    };
    @(static) full_ranges : [len(base_ranges) + len(accumulative_offsets_from_0x4E00) * 2 + 1]ImWchar = {};
    if (full_ranges[0] != 0)
    {
        copy(full_ranges[:], base_ranges[:]);
        UnpackAccumulativeOffsetsIntoRanges(0x4E00, accumulative_offsets_from_0x4E00[:], raw_data(full_ranges[len(base_ranges):]));
    }
    return raw_data(&full_ranges);
}

// [forward declared comment]:
// Default + Hiragana, Katakana, Half-Width, Selection of 2999 Ideographs
GetGlyphRangesJapanese :: proc(this : ^ImFontAtlas) -> [^]ImWchar
{
    // 2999 ideograms code points for Japanese
    // - 2136 Joyo (meaning "for regular use" or "for common use") Kanji code points
    // - 863 Jinmeiyo (meaning "for personal name") Kanji code points
    // - Sourced from official information provided by the government agencies of Japan:
    //   - List of Joyo Kanji by the Agency for Cultural Affairs
    //     - https://www.bunka.go.jp/kokugo_nihongo/sisaku/joho/joho/kijun/naikaku/kanji/
    //   - List of Jinmeiyo Kanji by the Ministry of Justice
    //     - http://www.moj.go.jp/MINJI/minji86.html
    //   - Available under the terms of the Creative Commons Attribution 4.0 International (CC BY 4.0).
    //     - https://creativecommons.org/licenses/by/4.0/legalcode
    // - You can generate this code by the script at:
    //   - https://github.com/vaiorabbit/everyday_use_kanji
    // - References:
    //   - List of Joyo Kanji
    //     - (Wikipedia) https://en.wikipedia.org/wiki/List_of_j%C5%8Dy%C5%8D_kanji
    //   - List of Jinmeiyo Kanji
    //     - (Wikipedia) https://en.wikipedia.org/wiki/Jinmeiy%C5%8D_kanji
    // - Missing 1 Joyo Kanji: U+20B9F (Kun'yomi: Shikaru, On'yomi: Shitsu,shichi), see https://github.com/ocornut/imgui/pull/3627 for details.
    // You can use ImFontGlyphRangesBuilder to create your own ranges derived from this, by merging existing ranges or adding new characters.
    // (Stored as accumulative offsets from the initial unicode codepoint 0x4E00. This encoding is designed to helps us compact the source code size.)
    @(static) accumulative_offsets_from_0x4E00 := [?]i16 {
        0,1,2,4,1,1,1,1,2,1,3,3,2,2,1,5,3,5,7,5,6,1,2,1,7,2,6,3,1,8,1,1,4,1,1,18,2,11,2,6,2,1,2,1,5,1,2,1,3,1,2,1,2,3,3,1,1,2,3,1,1,1,12,7,9,1,4,5,1,
        1,2,1,10,1,1,9,2,2,4,5,6,9,3,1,1,1,1,9,3,18,5,2,2,2,2,1,6,3,7,1,1,1,1,2,2,4,2,1,23,2,10,4,3,5,2,4,10,2,4,13,1,6,1,9,3,1,1,6,6,7,6,3,1,2,11,3,
        2,2,3,2,15,2,2,5,4,3,6,4,1,2,5,2,12,16,6,13,9,13,2,1,1,7,16,4,7,1,19,1,5,1,2,2,7,7,8,2,6,5,4,9,18,7,4,5,9,13,11,8,15,2,1,1,1,2,1,2,2,1,2,2,8,
        2,9,3,3,1,1,4,4,1,1,1,4,9,1,4,3,5,5,2,7,5,3,4,8,2,1,13,2,3,3,1,14,1,1,4,5,1,3,6,1,5,2,1,1,3,3,3,3,1,1,2,7,6,6,7,1,4,7,6,1,1,1,1,1,12,3,3,9,5,
        2,6,1,5,6,1,2,3,18,2,4,14,4,1,3,6,1,1,6,3,5,5,3,2,2,2,2,12,3,1,4,2,3,2,3,11,1,7,4,1,2,1,3,17,1,9,1,24,1,1,4,2,2,4,1,2,7,1,1,1,3,1,2,2,4,15,1,
        1,2,1,1,2,1,5,2,5,20,2,5,9,1,10,8,7,6,1,1,1,1,1,1,6,2,1,2,8,1,1,1,1,5,1,1,3,1,1,1,1,3,1,1,12,4,1,3,1,1,1,1,1,10,3,1,7,5,13,1,2,3,4,6,1,1,30,
        2,9,9,1,15,38,11,3,1,8,24,7,1,9,8,10,2,1,9,31,2,13,6,2,9,4,49,5,2,15,2,1,10,2,1,1,1,2,2,6,15,30,35,3,14,18,8,1,16,10,28,12,19,45,38,1,3,2,3,
        13,2,1,7,3,6,5,3,4,3,1,5,7,8,1,5,3,18,5,3,6,1,21,4,24,9,24,40,3,14,3,21,3,2,1,2,4,2,3,1,15,15,6,5,1,1,3,1,5,6,1,9,7,3,3,2,1,4,3,8,21,5,16,4,
        5,2,10,11,11,3,6,3,2,9,3,6,13,1,2,1,1,1,1,11,12,6,6,1,4,2,6,5,2,1,1,3,3,6,13,3,1,1,5,1,2,3,3,14,2,1,2,2,2,5,1,9,5,1,1,6,12,3,12,3,4,13,2,14,
        2,8,1,17,5,1,16,4,2,2,21,8,9,6,23,20,12,25,19,9,38,8,3,21,40,25,33,13,4,3,1,4,1,2,4,1,2,5,26,2,1,1,2,1,3,6,2,1,1,1,1,1,1,2,3,1,1,1,9,2,3,1,1,
        1,3,6,3,2,1,1,6,6,1,8,2,2,2,1,4,1,2,3,2,7,3,2,4,1,2,1,2,2,1,1,1,1,1,3,1,2,5,4,10,9,4,9,1,1,1,1,1,1,5,3,2,1,6,4,9,6,1,10,2,31,17,8,3,7,5,40,1,
        7,7,1,6,5,2,10,7,8,4,15,39,25,6,28,47,18,10,7,1,3,1,1,2,1,1,1,3,3,3,1,1,1,3,4,2,1,4,1,3,6,10,7,8,6,2,2,1,3,3,2,5,8,7,9,12,2,15,1,1,4,1,2,1,1,
        1,3,2,1,3,3,5,6,2,3,2,10,1,4,2,8,1,1,1,11,6,1,21,4,16,3,1,3,1,4,2,3,6,5,1,3,1,1,3,3,4,6,1,1,10,4,2,7,10,4,7,4,2,9,4,3,1,1,1,4,1,8,3,4,1,3,1,
        6,1,4,2,1,4,7,2,1,8,1,4,5,1,1,2,2,4,6,2,7,1,10,1,1,3,4,11,10,8,21,4,6,1,3,5,2,1,2,28,5,5,2,3,13,1,2,3,1,4,2,1,5,20,3,8,11,1,3,3,3,1,8,10,9,2,
        10,9,2,3,1,1,2,4,1,8,3,6,1,7,8,6,11,1,4,29,8,4,3,1,2,7,13,1,4,1,6,2,6,12,12,2,20,3,2,3,6,4,8,9,2,7,34,5,1,18,6,1,1,4,4,5,7,9,1,2,2,4,3,4,1,7,
        2,2,2,6,2,3,25,5,3,6,1,4,6,7,4,2,1,4,2,13,6,4,4,3,1,5,3,4,4,3,2,1,1,4,1,2,1,1,3,1,11,1,6,3,1,7,3,6,2,8,8,6,9,3,4,11,3,2,10,12,2,5,11,1,6,4,5,
        3,1,8,5,4,6,6,3,5,1,1,3,2,1,2,2,6,17,12,1,10,1,6,12,1,6,6,19,9,6,16,1,13,4,4,15,7,17,6,11,9,15,12,6,7,2,1,2,2,15,9,3,21,4,6,49,18,7,3,2,3,1,
        6,8,2,2,6,2,9,1,3,6,4,4,1,2,16,2,5,2,1,6,2,3,5,3,1,2,5,1,2,1,9,3,1,8,6,4,8,11,3,1,1,1,1,3,1,13,8,4,1,3,2,2,1,4,1,11,1,5,2,1,5,2,5,8,6,1,1,7,
        4,3,8,3,2,7,2,1,5,1,5,2,4,7,6,2,8,5,1,11,4,5,3,6,18,1,2,13,3,3,1,21,1,1,4,1,4,1,1,1,8,1,2,2,7,1,2,4,2,2,9,2,1,1,1,4,3,6,3,12,5,1,1,1,5,6,3,2,
        4,8,2,2,4,2,7,1,8,9,5,2,3,2,1,3,2,13,7,14,6,5,1,1,2,1,4,2,23,2,1,1,6,3,1,4,1,15,3,1,7,3,9,14,1,3,1,4,1,1,5,8,1,3,8,3,8,15,11,4,14,4,4,2,5,5,
        1,7,1,6,14,7,7,8,5,15,4,8,6,5,6,2,1,13,1,20,15,11,9,2,5,6,2,11,2,6,2,5,1,5,8,4,13,19,25,4,1,1,11,1,34,2,5,9,14,6,2,2,6,1,1,14,1,3,14,13,1,6,
        12,21,14,14,6,32,17,8,32,9,28,1,2,4,11,8,3,1,14,2,5,15,1,1,1,1,3,6,4,1,3,4,11,3,1,1,11,30,1,5,1,4,1,5,8,1,1,3,2,4,3,17,35,2,6,12,17,3,1,6,2,
        1,1,12,2,7,3,3,2,1,16,2,8,3,6,5,4,7,3,3,8,1,9,8,5,1,2,1,3,2,8,1,2,9,12,1,1,2,3,8,3,24,12,4,3,7,5,8,3,3,3,3,3,3,1,23,10,3,1,2,2,6,3,1,16,1,16,
        22,3,10,4,11,6,9,7,7,3,6,2,2,2,4,10,2,1,1,2,8,7,1,6,4,1,3,3,3,5,10,12,12,2,3,12,8,15,1,1,16,6,6,1,5,9,11,4,11,4,2,6,12,1,17,5,13,1,4,9,5,1,11,
        2,1,8,1,5,7,28,8,3,5,10,2,17,3,38,22,1,2,18,12,10,4,38,18,1,4,44,19,4,1,8,4,1,12,1,4,31,12,1,14,7,75,7,5,10,6,6,13,3,2,11,11,3,2,5,28,15,6,18,
        18,5,6,4,3,16,1,7,18,7,36,3,5,3,1,7,1,9,1,10,7,2,4,2,6,2,9,7,4,3,32,12,3,7,10,2,23,16,3,1,12,3,31,4,11,1,3,8,9,5,1,30,15,6,12,3,2,2,11,19,9,
        14,2,6,2,3,19,13,17,5,3,3,25,3,14,1,1,1,36,1,3,2,19,3,13,36,9,13,31,6,4,16,34,2,5,4,2,3,3,5,1,1,1,4,3,1,17,3,2,3,5,3,1,3,2,3,5,6,3,12,11,1,3,
        1,2,26,7,12,7,2,14,3,3,7,7,11,25,25,28,16,4,36,1,2,1,6,2,1,9,3,27,17,4,3,4,13,4,1,3,2,2,1,10,4,2,4,6,3,8,2,1,18,1,1,24,2,2,4,33,2,3,63,7,1,6,
        40,7,3,4,4,2,4,15,18,1,16,1,1,11,2,41,14,1,3,18,13,3,2,4,16,2,17,7,15,24,7,18,13,44,2,2,3,6,1,1,7,5,1,7,1,4,3,3,5,10,8,2,3,1,8,1,1,27,4,2,1,
        12,1,2,1,10,6,1,6,7,5,2,3,7,11,5,11,3,6,6,2,3,15,4,9,1,1,2,1,2,11,2,8,12,8,5,4,2,3,1,5,2,2,1,14,1,12,11,4,1,11,17,17,4,3,2,5,5,7,3,1,5,9,9,8,
        2,5,6,6,13,13,2,1,2,6,1,2,2,49,4,9,1,2,10,16,7,8,4,3,2,23,4,58,3,29,1,14,19,19,11,11,2,7,5,1,3,4,6,2,18,5,12,12,17,17,3,3,2,4,1,6,2,3,4,3,1,
        1,1,1,5,1,1,9,1,3,1,3,6,1,8,1,1,2,6,4,14,3,1,4,11,4,1,3,32,1,2,4,13,4,1,2,4,2,1,3,1,11,1,4,2,1,4,4,6,3,5,1,6,5,7,6,3,23,3,5,3,5,3,3,13,3,9,10,
        1,12,10,2,3,18,13,7,160,52,4,2,2,3,2,14,5,4,12,4,6,4,1,20,4,11,6,2,12,27,1,4,1,2,2,7,4,5,2,28,3,7,25,8,3,19,3,6,10,2,2,1,10,2,5,4,1,3,4,1,5,
        3,2,6,9,3,6,2,16,3,3,16,4,5,5,3,2,1,2,16,15,8,2,6,21,2,4,1,22,5,8,1,1,21,11,2,1,11,11,19,13,12,4,2,3,2,3,6,1,8,11,1,4,2,9,5,2,1,11,2,9,1,1,2,
        14,31,9,3,4,21,14,4,8,1,7,2,2,2,5,1,4,20,3,3,4,10,1,11,9,8,2,1,4,5,14,12,14,2,17,9,6,31,4,14,1,20,13,26,5,2,7,3,6,13,2,4,2,19,6,2,2,18,9,3,5,
        12,12,14,4,6,2,3,6,9,5,22,4,5,25,6,4,8,5,2,6,27,2,35,2,16,3,7,8,8,6,6,5,9,17,2,20,6,19,2,13,3,1,1,1,4,17,12,2,14,7,1,4,18,12,38,33,2,10,1,1,
        2,13,14,17,11,50,6,33,20,26,74,16,23,45,50,13,38,33,6,6,7,4,4,2,1,3,2,5,8,7,8,9,3,11,21,9,13,1,3,10,6,7,1,2,2,18,5,5,1,9,9,2,68,9,19,13,2,5,
        1,4,4,7,4,13,3,9,10,21,17,3,26,2,1,5,2,4,5,4,1,7,4,7,3,4,2,1,6,1,1,20,4,1,9,2,2,1,3,3,2,3,2,1,1,1,20,2,3,1,6,2,3,6,2,4,8,1,3,2,10,3,5,3,4,4,
        3,4,16,1,6,1,10,2,4,2,1,1,2,10,11,2,2,3,1,24,31,4,10,10,2,5,12,16,164,15,4,16,7,9,15,19,17,1,2,1,1,5,1,1,1,1,1,3,1,4,3,1,3,1,3,1,2,1,1,3,3,7,
        2,8,1,2,2,2,1,3,4,3,7,8,12,92,2,10,3,1,3,14,5,25,16,42,4,7,7,4,2,21,5,27,26,27,21,25,30,31,2,1,5,13,3,22,5,6,6,11,9,12,1,5,9,7,5,5,22,60,3,5,
        13,1,1,8,1,1,3,3,2,1,9,3,3,18,4,1,2,3,7,6,3,1,2,3,9,1,3,1,3,2,1,3,1,1,1,2,1,11,3,1,6,9,1,3,2,3,1,2,1,5,1,1,4,3,4,1,2,2,4,4,1,7,2,1,2,2,3,5,13,
        18,3,4,14,9,9,4,16,3,7,5,8,2,6,48,28,3,1,1,4,2,14,8,2,9,2,1,15,2,4,3,2,10,16,12,8,7,1,1,3,1,1,1,2,7,4,1,6,4,38,39,16,23,7,15,15,3,2,12,7,21,
        37,27,6,5,4,8,2,10,8,8,6,5,1,2,1,3,24,1,16,17,9,23,10,17,6,1,51,55,44,13,294,9,3,6,2,4,2,2,15,1,1,1,13,21,17,68,14,8,9,4,1,4,9,3,11,7,1,1,1,
        5,6,3,2,1,1,1,2,3,8,1,2,2,4,1,5,5,2,1,4,3,7,13,4,1,4,1,3,1,1,1,5,5,10,1,6,1,5,2,1,5,2,4,1,4,5,7,3,18,2,9,11,32,4,3,3,2,4,7,11,16,9,11,8,13,38,
        32,8,4,2,1,1,2,1,2,4,4,1,1,1,4,1,21,3,11,1,16,1,1,6,1,3,2,4,9,8,57,7,44,1,3,3,13,3,10,1,1,7,5,2,7,21,47,63,3,15,4,7,1,16,1,1,2,8,2,3,42,15,4,
        1,29,7,22,10,3,78,16,12,20,18,4,67,11,5,1,3,15,6,21,31,32,27,18,13,71,35,5,142,4,10,1,2,50,19,33,16,35,37,16,19,27,7,1,133,19,1,4,8,7,20,1,4,
        4,1,10,3,1,6,1,2,51,5,40,15,24,43,22928,11,1,13,154,70,3,1,1,7,4,10,1,2,1,1,2,1,2,1,2,2,1,1,2,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,
        3,2,1,1,1,1,2,1,1,
    };
    @(static) base_ranges := [?]ImWchar { // not zero-terminated
        0x0020, 0x00FF, // Basic Latin + Latin Supplement
        0x3000, 0x30FF, // CJK Symbols and Punctuations, Hiragana, Katakana
        0x31F0, 0x31FF, // Katakana Phonetic Extensions
        0xFF00, 0xFFEF, // Half-width characters
        0xFFFD, 0xFFFD  // Invalid
    };
    @(static) full_ranges : [len(base_ranges) + len(accumulative_offsets_from_0x4E00)*2 + 1]ImWchar = {};
    if (full_ranges[0] != 0)
    {
        copy(full_ranges[:], base_ranges[:]);
        UnpackAccumulativeOffsetsIntoRanges(0x4E00, accumulative_offsets_from_0x4E00[:], raw_data(full_ranges[len(base_ranges):]));
    }
    return raw_data(&full_ranges);
}

// [forward declared comment]:
// Default + about 400 Cyrillic characters
GetGlyphRangesCyrillic :: proc(this : ^ImFontAtlas) -> [^]ImWchar
{
    @(static) ranges := [?]ImWchar {
        0x0020, 0x00FF, // Basic Latin + Latin Supplement
        0x0400, 0x052F, // Cyrillic + Cyrillic Supplement
        0x2DE0, 0x2DFF, // Cyrillic Extended-A
        0xA640, 0xA69F, // Cyrillic Extended-B
        0,
    };
    return raw_data(&ranges);
}

// [forward declared comment]:
// Default + Thai characters
GetGlyphRangesThai :: proc(this : ^ImFontAtlas) -> [^]ImWchar
{
    @(static) ranges := [?]ImWchar {
        0x0020, 0x00FF, // Basic Latin
        0x2010, 0x205E, // Punctuations
        0x0E00, 0x0E7F, // Thai
        0,
    };
    return raw_data(&ranges);
}

// [forward declared comment]:
// Default + Vietnamese characters
GetGlyphRangesVietnamese :: proc(this : ^ImFontAtlas) -> [^]ImWchar
{
    @(static) ranges := [?]ImWchar {
        0x0020, 0x00FF, // Basic Latin
        0x0102, 0x0103,
        0x0110, 0x0111,
        0x0128, 0x0129,
        0x0168, 0x0169,
        0x01A0, 0x01A1,
        0x01AF, 0x01B0,
        0x1EA0, 0x1EF9,
        0,
    };
    return raw_data(&ranges);
}

//-----------------------------------------------------------------------------
// [SECTION] ImFontGlyphRangesBuilder
//-----------------------------------------------------------------------------

// [forward declared comment]:
// Add string (each character of the UTF-8 string are added)
AddText_fgrb :: proc(this : ^ImFontGlyphRangesBuilder, text : [^]u8, text_end : ^u8 = nil)
{
    text := text
    
    for (text_end != nil ? (cast(^u8) text < text_end) : text[0] != 0)
    {
        c : u32 = 0;
        c_len := ImTextCharFromUtf8(&c, text, text_end);
        text = text[c_len:];
        if (c_len == 0)   do break
        AddChar(this, ImWchar(c));
    }
}

// [forward declared comment]:
// Add ranges, e.g. builder.AddRanges(ImFontAtlas::GetGlyphRangesDefault()) to force add all of ASCII/Latin+Ext
AddRanges :: proc(this : ^ImFontGlyphRangesBuilder, ranges : [^]ImWchar)
{
    for ranges := ranges; ranges[0] != 0; ranges = ranges[2:] {
        for c := ranges[0]; c <= ranges[1] && c <= IM_UNICODE_CODEPOINT_MAX; c += 1 {//-V560
            AddChar(this, ImWchar(c));
        }
    }
}

// [forward declared comment]:
// Output new ranges
BuildRanges :: proc(this : ^ImFontGlyphRangesBuilder, out_ranges : ^[dynamic]ImWchar)
{
    max_codepoint := IM_UNICODE_CODEPOINT_MAX;
    for n := 0; n <= max_codepoint; n += 1 {
        if (GetBit(this, n))
        {
            append(out_ranges, ImWchar(n));
            for (n < max_codepoint && GetBit(this, n + 1)) do n += 1;
            append(out_ranges, ImWchar(n));
        }
    }
    append(out_ranges, 0);
}

//-----------------------------------------------------------------------------
// [SECTION] ImFont
//-----------------------------------------------------------------------------

init_ImFont :: proc(this : ^ImFont)
{
    this^ = {}
    this.Scale = 1.0;
}

deinit_ImFont :: proc(this : ^ImFont)
{
    ClearOutputData(this);
}

ClearOutputData :: proc(this : ^ImFont)
{
    this.FontSize = 0.0;
    this.FallbackAdvanceX = 0.0;
    clear(&this.Glyphs);
    clear(&this.IndexAdvanceX);
    clear(&this.IndexLookup);
    this.FallbackGlyph = nil;
    this.ContainerAtlas = nil;
    this.DirtyLookupTables = true;
    this.Ascent = 0
    this.Descent = 0.0;
    this.MetricsTotalSurface = 0;
    this.Used4kPagesMap = {}
}

FindFirstExistingGlyph :: proc(font : ^ImFont, candidate_chars : [^]ImWchar, candidate_chars_count : i32) -> ImWchar
{
    for n : i32 = 0; n < candidate_chars_count; n += 1 {
        if (FindGlyphNoFallback(font, candidate_chars[n]) != nil)   do return candidate_chars[n]
    }
    return 0;
}

BuildLookupTable :: proc(this : ^ImFont)
{
    max_codepoint : i32 = 0;
    for i := 0; i != len(this.Glyphs); i += 1 {
        max_codepoint = ImMax(max_codepoint, cast(i32) this.Glyphs[i].Codepoint);
    }

    // Build lookup table
    assert(len(this.Glyphs) > 0, "Font has not loaded glyph!");
    assert(len(this.Glyphs) < 0xFFFF); // -1 is reserved
    clear(&this.IndexAdvanceX);
    clear(&this.IndexLookup);
    this.DirtyLookupTables = false;
    this.Used4kPagesMap = {}
    GrowIndex(this, max_codepoint + 1);
    for i := 0; i < len(this.Glyphs); i += 1
    {
        codepoint := cast(u32) this.Glyphs[i].Codepoint;
        this.IndexAdvanceX[codepoint] = this.Glyphs[i].AdvanceX;
        this.IndexLookup[codepoint] = ImWchar(i);

        // Mark 4K page as used
        page_n := codepoint / 4096;
        this.Used4kPagesMap[page_n >> 3] |= 1 << (page_n & 7);
    }

    // Create a glyph to handle TAB
    // FIXME: Needs proper TAB handling but it needs to be contextualized (or we could arbitrary say that each string starts at "column 0" ?)
    if (FindGlyph(this, ImWchar(' ')) != nil)
    {
        if (back(this.Glyphs).Codepoint != '\t')  {  // So we can call this function multiple times (FIXME: Flaky)
            resize(&this.Glyphs, len(this.Glyphs) + 1);
        }
        tab_glyph := back(this.Glyphs)
        tab_glyph^ = FindGlyph(this, ImWchar(' '))^;
        tab_glyph.Codepoint = '\t';
        tab_glyph.AdvanceX *= IM_TABSIZE;
        this.IndexAdvanceX[cast(i32) tab_glyph.Codepoint] = cast(f32) tab_glyph.AdvanceX;
        this.IndexLookup[cast(i32) tab_glyph.Codepoint] = ImWchar(len(this.Glyphs) - 1);
    }

    // Mark special glyphs as not visible (note that AddGlyph already mark as non-visible glyphs with zero-size polygons)
    SetGlyphVisible(this, ImWchar(' '), false);
    SetGlyphVisible(this, ImWchar('\t'), false);

    // Setup Fallback character
    fallback_chars := [?]ImWchar { IM_UNICODE_CODEPOINT_INVALID, '?', ' ' };
    this.FallbackGlyph = FindGlyphNoFallback(this, this.FallbackChar);
    if (this.FallbackGlyph == nil)
    {
        this.FallbackChar = FindFirstExistingGlyph(this, raw_data(&fallback_chars), len(fallback_chars));
        this.FallbackGlyph = FindGlyphNoFallback(this, this.FallbackChar);
        if (this.FallbackGlyph == nil)
        {
            this.FallbackGlyph = back(this.Glyphs);
            this.FallbackChar = ImWchar(this.FallbackGlyph.Codepoint);
        }
    }
    this.FallbackAdvanceX = this.FallbackGlyph.AdvanceX;
    for i : i32 = 0; i < max_codepoint + 1; i += 1 {
        if (this.IndexAdvanceX[i] < 0.0) {
            this.IndexAdvanceX[i] = this.FallbackAdvanceX;
        }
    }

    // Setup Ellipsis character. It is required for rendering elided text. We prefer using U+2026 (horizontal ellipsis).
    // However some old fonts may contain ellipsis at U+0085. Here we auto-detect most suitable ellipsis character.
    // FIXME: Note that 0x2026 is rarely included in our font ranges. Because of this we are more likely to use three individual dots.
    ellipsis_chars := [?]ImWchar { this.ConfigData[0].EllipsisChar, 0x2026, 0x0085 };
    dots_chars := [?]ImWchar { '.', 0xFF0E };
    if (this.EllipsisChar == 0) {
        this.EllipsisChar = FindFirstExistingGlyph(this, raw_data(&ellipsis_chars), len(ellipsis_chars));
    }
    dot_char := FindFirstExistingGlyph(this, raw_data(&dots_chars), len(dots_chars));
    if (this.EllipsisChar != 0)
    {
        this.EllipsisCharCount = 1;
        this.EllipsisCharStep = FindGlyph(this, this.EllipsisChar).X1;
        this.EllipsisWidth = this.EllipsisCharStep
    }
    else if (dot_char != 0)
    {
        dot_glyph := FindGlyph(this, dot_char);
        this.EllipsisChar = dot_char;
        this.EllipsisCharCount = 3;
        this.EllipsisCharStep = cast(f32)cast(i32)(dot_glyph.X1 - dot_glyph.X0) + 1.0;
        this.EllipsisWidth = ImMax(dot_glyph.AdvanceX, dot_glyph.X0 + this.EllipsisCharStep * 3.0 - 1.0); // FIXME: Slightly odd for normally mono-space fonts but since this is used for trailing contents.
    }
}

// API is designed this way to avoid exposing the 4K page size
// e.g. use with IsGlyphRangeUnused(0, 255)
IsGlyphRangeUnused :: proc(this : ^ImFont, c_begin : u32, c_last : u32) -> bool
{
    page_begin := (c_begin / 4096);
    page_last := (c_last / 4096);
    for page_n := page_begin; page_n <= page_last; page_n += 1 {
        if ((page_n >> 3) < size_of(this.Used4kPagesMap)) {
            if (this.Used4kPagesMap[page_n >> 3] & (1 << (page_n & 7)) != 0)   do return false
        }
    }
    return true;
}

SetGlyphVisible :: proc(this : ^ImFont, c : ImWchar, visible : bool)
{
    if glyph := cast(^ImFontGlyph)cast(rawptr)FindGlyph(this, ImWchar(c)); glyph != nil {
        glyph.Visible = visible
    }
}

GrowIndex :: proc(this : ^ImFont, new_size : i32)
{
    assert(len(this.IndexAdvanceX) == len(this.IndexLookup));
    if (new_size <= cast(i32) len(this.IndexLookup))   do return
    resize_fill(&this.IndexAdvanceX, new_size, -1.0);
    resize_fill(&this.IndexLookup, new_size, ~ImWchar(0));
}

// x0/y0/x1/y1 are offset from the character upper-left layout position, in pixels. Therefore x0/y0 are often fairly close to zero.
// Not to be mistaken with texture coordinates, which are held by u0/v0/u1/v1 in normalized format (0.0..1.0 on each texture axis).
// 'cfg' is not necessarily == 'this.ConfigData' because multiple source fonts+configs can be used to build one target font.
AddGlyph :: proc(this : ^ImFont, cfg : ^ImFontConfig, codepoint : ImWchar, x0 : f32, y0 : f32, x1 : f32, y1 : f32, u0 : f32, v0 : f32, u1 : f32, v1 : f32, advance_x : f32)
{
    advance_x := advance_x
    x0 := x0;
    x1 := x1;

    if (cfg != nil)
    {
        // Clamp & recenter if needed
        advance_x_original := advance_x;
        advance_x = ImClamp(advance_x, cfg.GlyphMinAdvanceX, cfg.GlyphMaxAdvanceX);
        if (advance_x != advance_x_original)
        {
            char_off_x := cfg.PixelSnapH ? ImTrunc((advance_x - advance_x_original) * 0.5) : (advance_x - advance_x_original) * 0.5;
            x0 += char_off_x;
            x1 += char_off_x;
        }

        // Snap to pixel 
        if (cfg.PixelSnapH) {
            advance_x = math.round(advance_x);
        }

        // Bake spacing
        advance_x += cfg.GlyphExtraSpacing.x;
    }

    glyph_idx := len(this.Glyphs);
    resize(&this.Glyphs, len(this.Glyphs) + 1);
    glyph := &this.Glyphs[glyph_idx];
    glyph.Codepoint = cast(u32) codepoint;
    glyph.Visible = (x0 != x1) && (y0 != y1);
    glyph.Colored = false;
    glyph.X0 = x0;
    glyph.Y0 = y0;
    glyph.X1 = x1;
    glyph.Y1 = y1;
    glyph.U0 = u0;
    glyph.V0 = v0;
    glyph.U1 = u1;
    glyph.V1 = v1;
    glyph.AdvanceX = advance_x;

    // Compute rough surface usage metrics (+1 to account for average padding, +0.99 to round)
    // We use (U1-U0)*TexWidth instead of X1-X0 to account for oversampling.
    pad := f32(this.ContainerAtlas.TexGlyphPadding) + 0.99;
    this.DirtyLookupTables = true;
    this.MetricsTotalSurface += (i32)((glyph.U1 - glyph.U0) * f32(this.ContainerAtlas.TexWidth) + pad) * (i32)((glyph.V1 - glyph.V0) * f32(this.ContainerAtlas.TexHeight) + pad);
}

// [forward declared comment]:
// Makes 'dst' character/glyph points to 'src' character/glyph. Currently needs to be called AFTER fonts have been built.
AddRemapChar :: proc(this : ^ImFont, dst : ImWchar, src : ImWchar, overwrite_dst : bool = true)
{
    assert(len(this.IndexLookup) > 0);    // Currently this can only be called AFTER the font has been built, aka after calling ImFontAtlas::GetTexDataAs*() function.
    index_size := cast(u32) len(this.IndexLookup)

    if (u32(dst) < index_size && this.IndexLookup[dst] == ~ImWchar(0) && !overwrite_dst) {// 'dst' already exists
        return;
    }
    if (u32(src) >= index_size && u32(dst) >= index_size) { // both 'dst' and 'src' don't exist -> no-op
        return;
    }

    GrowIndex(this, cast(i32) dst + 1);
    this.IndexLookup[dst] = (u32(src) < index_size) ? this.IndexLookup[src] : ~ImWchar(0);
    this.IndexAdvanceX[dst] = (u32(src) < index_size) ? this.IndexAdvanceX[src] : 1.0;
}

// Find glyph, return fallback if missing
FindGlyph :: proc(this : ^ImFont, c : ImWchar) -> ^ImFontGlyph
{
    if (cast(int) c >= len(this.IndexLookup))   do return this.FallbackGlyph
    i := this.IndexLookup[c];
    if (i == ~ImWchar(0))   do return this.FallbackGlyph
    return &this.Glyphs[i];
}

FindGlyphNoFallback :: proc(this : ^ImFont, c : ImWchar) -> ^ImFontGlyph
{
    if (cast(int) c >= len(this.IndexLookup))   do return nil
    i := this.IndexLookup[c];
    if (i == ~ImWchar(0))   do return nil
    return &this.Glyphs[i];
}

// Trim trailing space and find beginning of next line
CalcWordWrapNextLineStartA :: #force_inline proc(text : [^]u8, text_end : ^u8) -> ^u8
{
    text := text
    
    for (text < text_end && ImCharIsBlankA(text[0])) {
        text = text[1:]
    }
    if (text[0] == '\n')   do text = text[1:]
    return text;
}

ImFontGetCharAdvanceX :: #force_inline proc(_FONT : ^ImFont, _CH : u32) -> f32 { return int(_CH) < len(_FONT.IndexAdvanceX) ? _FONT.IndexAdvanceX[_CH] : _FONT.FallbackAdvanceX }

// Simple word-wrapping for English, not full-featured. Please submit failing cases!
// This will return the next location to wrap from. If no wrapping if necessary, this will fast-forward to e.g. text_end.
// FIXME: Much possible improvements (don't cut things like "word !", "word!!!" but cut within "word,,,,", more sensible support for punctuations, support for Unicode punctuations, etc.)
CalcWordWrapPositionA :: proc(this : ^ImFont, scale : f32, text : [^]u8, text_end : ^u8, wrap_width : f32) -> ^u8
{
    wrap_width := wrap_width
    // For references, possible wrap point marked with ^
    //  "aaa bbb, ccc,ddd. eee   fff. ggg!"
    //      ^    ^    ^   ^   ^__    ^    ^

    // List of hardcoded separators: .,;!?'"

    // Skip extra blanks after a line returns (that includes not counting them in width computation)
    // e.g. "Hello    world" --> "Hello" "World"

    // Cut words that cannot possibly fit within one line.
    // e.g.: "The tropical fish" with ~5 characters worth of width --> "The tr" "opical" "fish"
    line_width : f32 = 0.0;
    word_width : f32 = 0.0;
    blank_width : f32 = 0.0;
    wrap_width /= scale; // We work with unscaled widths to avoid scaling every characters

    word_end := text;
    prev_word_end : ^u8
    inside_word := true;

    s := text;
    assert(text_end != nil);
    for (s < text_end)
    {
        c := cast(u32)s[0];
        next_s : [^]u8
        if (c < 0x80)   do next_s = s[1:]
        else {
            next_s = s[ImTextCharFromUtf8(&c, s, text_end):];
        }

        if (c < 32)
        {
            if (c == '\n')
            {
                line_width = 0
                word_width = 0
                blank_width = 0.0;
                inside_word = true;
                s = next_s;
                continue;
            }
            if (c == '\r')
            {
                s = next_s;
                continue;
            }
        }

        char_width := ImFontGetCharAdvanceX(this, c);
        if (ImCharIsBlankW(c))
        {
            if (inside_word)
            {
                line_width += blank_width;
                blank_width = 0.0;
                word_end = s;
            }
            blank_width += char_width;
            inside_word = false;
        }
        else
        {
            word_width += char_width;
            if (inside_word)
            {
                word_end = next_s;
            }
            else
            {
                prev_word_end = word_end;
                line_width += word_width + blank_width;
                word_width = 0
                blank_width = 0.0;
            }

            // Allow wrapping after punctuation.
            inside_word = (c != '.' && c != ',' && c != ';' && c != '!' && c != '?' && c != '\"');
        }

        // We ignore blank width at the end of the line (they can be skipped)
        if (line_width + word_width > wrap_width)
        {
            // Words that cannot possibly fit within an entire line will be cut anywhere.
            if (word_width < wrap_width) {
                s = prev_word_end != nil ? prev_word_end : word_end;
            }
            break;
        }

        s = next_s;
    }

    // Wrap_width is too small to fit anything. Force displaying 1 character to minimize the height discontinuity.
    // +1 may not be a character start point in UTF-8 but it's ok because caller loops use (text >= word_wrap_eol).
    if (s == text && text < text_end)   do return mem.ptr_offset(s, 1)
    return s;
}

// [forward declared comment]:
// utf8
CalcTextSizeA :: proc(this : ^ImFont, size : f32, max_width : f32, wrap_width : f32, text_ : string, remaining : ^[^]u8 = nil) -> ImVec2
{
    text_begin := raw_data(text_)
    text_end := end(text_)

    line_height := size;
    scale := size / this.FontSize;

    text_size := ImVec2{0, 0};
    line_width : f32 = 0.0;

    word_wrap_enabled := (wrap_width > 0.0);
    word_wrap_eol : ^u8

    s := text_begin;
    for (s < text_end)
    {
        if (word_wrap_enabled)
        {
            // Calculate how far we can render. Requires two passes on the string data but keeps the code simple and not intrusive for what's essentially an uncommon feature.
            if (word_wrap_eol == nil) {
                word_wrap_eol = CalcWordWrapPositionA(this, scale, s, text_end, wrap_width - line_width);
            }

            if (s >= word_wrap_eol)
            {
                if (text_size.x < line_width)   do text_size.x = line_width
                text_size.y += line_height;
                line_width = 0.0;
                word_wrap_eol = nil;
                s = CalcWordWrapNextLineStartA(s, text_end); // Wrapping skips upcoming blanks
                continue;
            }
        }

        // Decode and advance source
        prev_s := s;
        c := u32(s[0]);
        if (c < 0x80)   do s = mem.ptr_offset(s, 1)
        else do s = mem.ptr_offset(s, ImTextCharFromUtf8(&c, s, text_end))

        if (c < 32)
        {
            if (c == '\n')
            {
                text_size.x = ImMax(text_size.x, line_width);
                text_size.y += line_height;
                line_width = 0.0;
                continue;
            }
            if (c == '\r')   do continue
        }

        char_width := ImFontGetCharAdvanceX(this, c) * scale;
        if (line_width + char_width >= max_width)
        {
            s = prev_s;
            break;
        }

        line_width += char_width;
    }

    if (text_size.x < line_width)   do text_size.x = line_width

    if (line_width > 0 || text_size.y == 0.0) do text_size.y += line_height;

    if (remaining != nil)   do remaining^ = s

    return text_size;
}

// Note: as with every ImDrawList drawing function, this expects that the font atlas texture is bound.
RenderChar :: proc(this : ^ImFont, draw_list : ^ImDrawList, size : f32, pos : ImVec2, col : u32, c : ImWchar)
{
    glyph := FindGlyph(this, c);
    if (glyph == nil || !glyph.Visible)   do return
    col := col
    if (glyph.Colored)   do col |= ~IM_COL32_A_MASK
    scale := (size >= 0.0) ? (size / this.FontSize) : 1.0;
    x := math.trunc(pos.x);
    y := math.trunc(pos.y);
    PrimReserve(draw_list, 6, 4);
    PrimRectUV(draw_list, ImVec2{x + glyph.X0 * scale, y + glyph.Y0 * scale}, ImVec2{x + glyph.X1 * scale, y + glyph.Y1 * scale}, ImVec2{glyph.U0, glyph.V0}, ImVec2{glyph.U1, glyph.V1}, col);
}

// Note: as with every ImDrawList drawing function, this expects that the font atlas texture is bound.
RenderText_ex :: proc(this : ^ImFont, draw_list : ^ImDrawList, size : f32, pos : ImVec2, col : u32, clip_rect : ImVec4, text_ : string, wrap_width : f32, cpu_fine_clip : bool)
{
    text_begin := raw_data(text_)
    text_end := end(text_)

    // Align to be pixel perfect
    x := math.trunc(pos.x);
    y := math.trunc(pos.y);
    if (y > clip_rect.w)   do return

    scale := size / this.FontSize;
    line_height := this.FontSize * scale;
    origin_x := x;
    word_wrap_enabled := (wrap_width > 0.0);

    // Fast-forward to first visible line
    s := text_begin;
    if (y + line_height < clip_rect.y) {
        for (y + line_height < clip_rect.y && s < text_end)
        {
            line_end := memchr_end(s, '\n', text_end);
            if (word_wrap_enabled)
            {
                // FIXME-OPT: This is not optimal as do first do a search for \n before calling CalcWordWrapPositionA().
                // If the specs for CalcWordWrapPositionA() were reworked to optionally return on \n we could combine both.
                // However it is still better than nothing performing the fast-forward!
                s = CalcWordWrapPositionA(this, scale, s, line_end == nil ? line_end : text_end, wrap_width);
                s = CalcWordWrapNextLineStartA(s, text_end);
            }
            else
            {
                s = line_end == nil ? ([^]u8)(line_end)[1:] : cast([^]u8) text_end;
            }
            y += line_height;
        }
    }

    // For large text, scan for the last visible line in order to avoid over-reserving in the call to PrimReserve()
    // Note that very large horizontal line will still be affected by the issue (e.g. a one megabyte string buffer without a newline will likely crash atm)
    if (mem.ptr_sub(text_end, cast(^u8) s) > 10000 && !word_wrap_enabled)
    {
        s_end := s;
        y_end := y;
        for (y_end < clip_rect.w && s_end < text_end)
        {
            s_end = memchr_end(s_end, '\n', text_end);
            s_end = s_end != nil ? s_end[1:] : text_end;
            y_end += line_height;
        }
        text_end = s_end;
    }
    if (s == text_end)   do return

    // Reserve vertices for remaining worse case (over-reserving is useful and easily amortized)
    vtx_count_max := cast(i32) mem.ptr_sub(text_end, cast(^u8) s) * 4;
    idx_count_max := cast(i32) mem.ptr_sub(text_end, cast(^u8) s) * 6;
    idx_expected_size := cast(i32) len(draw_list.IdxBuffer) + idx_count_max;
    PrimReserve(draw_list, idx_count_max, vtx_count_max);
    vtx_write := draw_list._VtxWritePtr;
    idx_write := draw_list._IdxWritePtr;
    vtx_index := draw_list._VtxCurrentIdx;

    col_untinted := col | ~IM_COL32_A_MASK;
    word_wrap_eol : ^u8

    for (s < text_end)
    {
        if (word_wrap_enabled)
        {
            // Calculate how far we can render. Requires two passes on the string data but keeps the code simple and not intrusive for what's essentially an uncommon feature.
            if (word_wrap_eol != nil) {
                word_wrap_eol = CalcWordWrapPositionA(this, scale, s, text_end, wrap_width - (x - origin_x));
            }

            if (s >= word_wrap_eol)
            {
                x = origin_x;
                y += line_height;
                if (y > clip_rect.w) {
                    break; // break out of main loop
                }
                word_wrap_eol = nil;
                s = CalcWordWrapNextLineStartA(s, text_end); // Wrapping skips upcoming blanks
                continue;
            }
        }

        // Decode and advance source
        c := cast(u32)s[0];
        if (c < 0x80)   do s = s[1:]
        else do s = s[ImTextCharFromUtf8(&c, s, text_end):];

        if (c < 32)
        {
            if (c == '\n')
            {
                x = origin_x;
                y += line_height;
                if (y > clip_rect.w) do break; // break out of main loop
                continue;
            }
            if (c == '\r')   do continue
        }

        glyph := FindGlyph(this, ImWchar(c));
        if (glyph == nil)   do continue

        char_width := glyph.AdvanceX * scale;
        if (glyph.Visible)
        {
            // We don't do a second finer clipping test on the Y axis as we've already skipped anything before clip_rect.y and exit once we pass clip_rect.w
            x1 := x + glyph.X0 * scale;
            x2 := x + glyph.X1 * scale;
            y1 := y + glyph.Y0 * scale;
            y2 := y + glyph.Y1 * scale;
            if (x1 <= clip_rect.z && x2 >= clip_rect.x)
            {
                // Render a character
                u1 := glyph.U0;
                v1 := glyph.V0;
                u2 := glyph.U1;
                v2 := glyph.V1;

                // CPU side clipping used to fit text in their frame when the frame is too small. Only does clipping for axis aligned quads.
                if (cpu_fine_clip)
                {
                    if (x1 < clip_rect.x)
                    {
                        u1 = u1 + (1.0 - (x2 - clip_rect.x) / (x2 - x1)) * (u2 - u1);
                        x1 = clip_rect.x;
                    }
                    if (y1 < clip_rect.y)
                    {
                        v1 = v1 + (1.0 - (y2 - clip_rect.y) / (y2 - y1)) * (v2 - v1);
                        y1 = clip_rect.y;
                    }
                    if (x2 > clip_rect.z)
                    {
                        u2 = u1 + ((clip_rect.z - x1) / (x2 - x1)) * (u2 - u1);
                        x2 = clip_rect.z;
                    }
                    if (y2 > clip_rect.w)
                    {
                        v2 = v1 + ((clip_rect.w - y1) / (y2 - y1)) * (v2 - v1);
                        y2 = clip_rect.w;
                    }
                    if (y1 >= y2)
                    {
                        x += char_width;
                        continue;
                    }
                }

                // Support for untinted glyphs
                glyph_col := glyph.Colored ? col_untinted : col;

                // We are NOT calling PrimRectUV() here because non-inlined causes too much overhead in a debug builds. Inlined here:
                {
                    vtx_write[0].pos.x = x1; vtx_write[0].pos.y = y1; vtx_write[0].col = glyph_col; vtx_write[0].uv.x = u1; vtx_write[0].uv.y = v1;
                    vtx_write[1].pos.x = x2; vtx_write[1].pos.y = y1; vtx_write[1].col = glyph_col; vtx_write[1].uv.x = u2; vtx_write[1].uv.y = v1;
                    vtx_write[2].pos.x = x2; vtx_write[2].pos.y = y2; vtx_write[2].col = glyph_col; vtx_write[2].uv.x = u2; vtx_write[2].uv.y = v2;
                    vtx_write[3].pos.x = x1; vtx_write[3].pos.y = y2; vtx_write[3].col = glyph_col; vtx_write[3].uv.x = u1; vtx_write[3].uv.y = v2;
                    idx_write[0] = (ImDrawIdx)(vtx_index); idx_write[1] = (ImDrawIdx)(vtx_index + 1); idx_write[2] = (ImDrawIdx)(vtx_index + 2);
                    idx_write[3] = (ImDrawIdx)(vtx_index); idx_write[4] = (ImDrawIdx)(vtx_index + 2); idx_write[5] = (ImDrawIdx)(vtx_index + 3);
                    vtx_write = vtx_write[4:];
                    vtx_index += 4;
                    idx_write = idx_write[6:];
                }
            }
        }
        x += char_width;
    }

    // Give back unused vertices (clipped ones, blanks) ~ this is essentially a PrimUnreserve() action.
    shrink_to(&draw_list.VtxBuffer, mem.ptr_sub(vtx_write, raw_data(draw_list.VtxBuffer))); // Same as calling shrink()
    shrink_to(&draw_list.IdxBuffer, mem.ptr_sub(idx_write, raw_data(draw_list.IdxBuffer)));
    back(draw_list.CmdBuffer).ElemCount -= u32(int(idx_expected_size) - len(draw_list.IdxBuffer));
    draw_list._VtxWritePtr = vtx_write;
    draw_list._IdxWritePtr = idx_write;
    draw_list._VtxCurrentIdx = vtx_index;
}

RenderText :: proc { RenderText_ex, RenderText_basic }

//-----------------------------------------------------------------------------
// [SECTION] ImGui Internal Render Helpers
//-----------------------------------------------------------------------------
// Vaguely redesigned to stop accessing ImGui global state:
// - RenderArrow()
// - RenderBullet()
// - RenderCheckMark()
// - RenderArrowDockMenu()
// - RenderArrowPointingAt()
// - RenderRectFilledRangeH()
// - RenderRectFilledWithHole()
//-----------------------------------------------------------------------------
// Function in need of a redesign (legacy mess)
// - RenderColorRectWithAlphaCheckerboard()
//-----------------------------------------------------------------------------

// Render an arrow aimed to be aligned with text (p_min is a position in the same space text would be positioned). To e.g. denote expanded/collapsed state
RenderArrow :: proc(draw_list : ^ImDrawList, pos : ImVec2, col : u32, dir : ImGuiDir, scale : f32 = 1.0)
{
    h := draw_list._Data.FontSize * 1.00;
    r := h * 0.40 * scale;
    center := pos + ImVec2{h * 0.50, h * 0.50 * scale};

    a, b, c : ImVec2
    switch (dir)
    {
    case ImGuiDir.Up:
    case ImGuiDir.Down:
        if (dir == ImGuiDir.Up) do r = -r;
        a = ImVec2{+0.000, +0.750} * r;
        b = ImVec2{-0.866, -0.750} * r;
        c = ImVec2{+0.866, -0.750} * r;
        break;
    case .Left:
    case .Right:
        if (dir == .Left) do r = -r;
        a = ImVec2{+0.750, +0.000} * r;
        b = ImVec2{-0.750, +0.866} * r;
        c = ImVec2{-0.750, -0.866} * r;
        break;
    case nil:
    case ImGuiDir(len(ImGuiDir)):
        assert(false)
        break;
    }
    AddTriangleFilled(draw_list, center + a, center + b, center + c, col);
}

RenderBullet :: proc(draw_list : ^ImDrawList, pos : ImVec2, col : u32)
{
    // FIXME-OPT: This should be baked in font.
    AddCircleFilled(draw_list, pos, draw_list._Data.FontSize * 0.20, col, 8);
}

RenderCheckMark :: proc(draw_list : ^ImDrawList, pos : ImVec2, col : u32, sz : f32)
{
    thickness := ImMax(sz / 5.0, 1.0);
    sz := sz - thickness * 0.5;
    pos := pos + ImVec2{thickness * 0.25, thickness * 0.25};

    third := sz / 3.0;
    bx := pos.x + third;
    by := pos.y + sz - third * 0.5;
    PathLineTo(draw_list, ImVec2{bx - third, by - third});
    PathLineTo(draw_list, ImVec2{bx, by});
    PathLineTo(draw_list, ImVec2{bx + third * 2.0, by - third * 2.0});
    PathStroke(draw_list, col, nil, thickness);
}

// Render an arrow. 'pos' is position of the arrow tip. half_sz.x is length from base to tip. half_sz.y is length on each side.
RenderArrowPointingAt :: proc(draw_list : ^ImDrawList, pos : ImVec2, half_sz : ImVec2, direction : ImGuiDir, col : u32)
{
    switch (direction)
    {
    case .Left:  AddTriangleFilled(draw_list, ImVec2{pos.x + half_sz.x, pos.y - half_sz.y}, ImVec2{pos.x + half_sz.x, pos.y + half_sz.y}, pos, col); return;
    case .Right: AddTriangleFilled(draw_list, ImVec2{pos.x - half_sz.x, pos.y + half_sz.y}, ImVec2{pos.x - half_sz.x, pos.y - half_sz.y}, pos, col); return;
    case ImGuiDir.Up:    AddTriangleFilled(draw_list, ImVec2{pos.x + half_sz.x, pos.y + half_sz.y}, ImVec2{pos.x - half_sz.x, pos.y + half_sz.y}, pos, col); return;
    case ImGuiDir.Down:  AddTriangleFilled(draw_list, ImVec2{pos.x - half_sz.x, pos.y - half_sz.y}, ImVec2{pos.x + half_sz.x, pos.y - half_sz.y}, pos, col); return;
    case nil: case ImGuiDir(len(ImGuiDir)): break; // Fix warnings
    }
}

// This is less wide than RenderArrow() and we use in dock nodes instead of the regular RenderArrow() to denote a change of functionality,
// and because the saved space means that the left-most tab label can stay at exactly the same position as the label of a loose window.
RenderArrowDockMenu :: proc(draw_list : ^ImDrawList, p_min : ImVec2, sz : f32, col : u32)
{
    AddRectFilled(draw_list, p_min + ImVec2{sz * 0.20, sz * 0.15}, p_min + ImVec2{sz * 0.80, sz * 0.30}, col);
    RenderArrowPointingAt(draw_list, p_min + ImVec2{sz * 0.50, sz * 0.85}, ImVec2{sz * 0.30, sz * 0.40}, ImGuiDir.Down, col);
}

ImAcos01 :: #force_inline proc(x : f32) -> f32
{
    if (x <= 0.0) do return IM_PI * 0.5;
    if (x >= 1.0) do return 0.0;
    return ImAcos(x);
    //return (-0.69813170079773212f * x * x - 0.87266462599716477f) * x + 1.5707963267948966f; // Cheap approximation, may be enough for what we do.
}

// FIXME: Cleanup and move code to ImDrawList.
RenderRectFilledRangeH :: proc(draw_list : ^ImDrawList, rect : ^ImRect, col : u32, x_start_norm : f32, x_end_norm : f32, rounding : f32)
{
    x_start_norm := x_start_norm
    x_end_norm := x_end_norm

    if (x_end_norm == x_start_norm)   do return
    if (x_start_norm > x_end_norm) {
        ImSwap(&x_start_norm, &x_end_norm);
    }

    p0 := ImVec2{ImLerp(rect.Min.x, rect.Max.x, x_start_norm), rect.Min.y};
    p1 := ImVec2{ImLerp(rect.Min.x, rect.Max.x, x_end_norm), rect.Max.y};
    if (rounding == 0.0)
    {
        AddRectFilled(draw_list, p0, p1, col, 0.0);
        return;
    }

    rounding := ImClamp(ImMin((rect.Max.x - rect.Min.x) * 0.5, (rect.Max.y - rect.Min.y) * 0.5) - 1.0, 0.0, rounding);
    inv_rounding := 1.0 / rounding;
    arc0_b := ImAcos01(1.0 - (p0.x - rect.Min.x) * inv_rounding);
    arc0_e := ImAcos01(1.0 - (p1.x - rect.Min.x) * inv_rounding);
    half_pi : f32 = IM_PI * 0.5; // We will == compare to this because we know this is the exact value ImAcos01 can return.
    x0 := ImMax(p0.x, rect.Min.x + rounding);
    if (arc0_b == arc0_e)
    {
        PathLineTo(draw_list, ImVec2{x0, p1.y});
        PathLineTo(draw_list, ImVec2{x0, p0.y});
    }
    else if (arc0_b == 0.0 && arc0_e == half_pi)
    {
        PathArcToFast(draw_list, ImVec2{x0, p1.y - rounding}, rounding, 3, 6); // BL
        PathArcToFast(draw_list, ImVec2{x0, p0.y + rounding}, rounding, 6, 9); // TR
    }
    else
    {
        PathArcTo(draw_list, ImVec2{x0, p1.y - rounding}, rounding, IM_PI - arc0_e, IM_PI - arc0_b); // BL
        PathArcTo(draw_list, ImVec2{x0, p0.y + rounding}, rounding, IM_PI + arc0_b, IM_PI + arc0_e); // TR
    }
    if (p1.x > rect.Min.x + rounding)
    {
        arc1_b := ImAcos01(1.0 - (rect.Max.x - p1.x) * inv_rounding);
        arc1_e := ImAcos01(1.0 - (rect.Max.x - p0.x) * inv_rounding);
        x1 := ImMin(p1.x, rect.Max.x - rounding);
        if (arc1_b == arc1_e)
        {
            PathLineTo(draw_list, ImVec2{x1, p0.y});
            PathLineTo(draw_list, ImVec2{x1, p1.y});
        }
        else if (arc1_b == 0.0 && arc1_e == half_pi)
        {
            PathArcToFast(draw_list, ImVec2{x1, p0.y + rounding}, rounding, 9, 12); // TR
            PathArcToFast(draw_list, ImVec2{x1, p1.y - rounding}, rounding, 0, 3);  // BR
        }
        else
        {
            PathArcTo(draw_list, ImVec2{x1, p0.y + rounding}, rounding, -arc1_e, -arc1_b); // TR
            PathArcTo(draw_list, ImVec2{x1, p1.y - rounding}, rounding, +arc1_b, +arc1_e); // BR
        }
    }
    PathFillConvex(draw_list, col);
}

RenderRectFilledWithHole :: proc(draw_list : ^ImDrawList, outer : ^ImRect, inner : ^ImRect, col : u32, rounding : f32)
{
    fill_L := (inner.Min.x > outer.Min.x);
    fill_R := (inner.Max.x < outer.Max.x);
    fill_U := (inner.Min.y > outer.Min.y);
    fill_D := (inner.Max.y < outer.Max.y);
    if (fill_L) do AddRectFilled(draw_list, ImVec2{outer.Min.x, inner.Min.y}, ImVec2{inner.Min.x, inner.Max.y}, col, rounding, {ImDrawFlag.RoundCornersNone} | (fill_U ? nil : {ImDrawFlag.RoundCornersTopLeft})    | (fill_D ? nil : {ImDrawFlag.RoundCornersBottomLeft}));
    if (fill_R) do AddRectFilled(draw_list, ImVec2{inner.Max.x, inner.Min.y}, ImVec2{outer.Max.x, inner.Max.y}, col, rounding, {ImDrawFlag.RoundCornersNone} | (fill_U ? nil : {ImDrawFlag.RoundCornersTopRight})   | (fill_D ? nil : {ImDrawFlag.RoundCornersBottomRight}));
    if (fill_U) do AddRectFilled(draw_list, ImVec2{inner.Min.x, outer.Min.y}, ImVec2{inner.Max.x, inner.Min.y}, col, rounding, {ImDrawFlag.RoundCornersNone} | (fill_L ? nil : {ImDrawFlag.RoundCornersTopLeft})    | (fill_R ? nil : {ImDrawFlag.RoundCornersTopRight}));
    if (fill_D) do AddRectFilled(draw_list, ImVec2{inner.Min.x, inner.Max.y}, ImVec2{inner.Max.x, outer.Max.y}, col, rounding, {ImDrawFlag.RoundCornersNone} | (fill_L ? nil : {ImDrawFlag.RoundCornersBottomLeft}) | (fill_R ? nil : {ImDrawFlag.RoundCornersBottomRight}));
    if (fill_L && fill_U) do AddRectFilled(draw_list, ImVec2{outer.Min.x, outer.Min.y}, ImVec2{inner.Min.x, inner.Min.y}, col, rounding, {.RoundCornersTopLeft});
    if (fill_R && fill_U) do AddRectFilled(draw_list, ImVec2{inner.Max.x, outer.Min.y}, ImVec2{outer.Max.x, inner.Min.y}, col, rounding, {.RoundCornersTopRight});
    if (fill_L && fill_D) do AddRectFilled(draw_list, ImVec2{outer.Min.x, inner.Max.y}, ImVec2{inner.Min.x, outer.Max.y}, col, rounding, {.RoundCornersBottomLeft});
    if (fill_R && fill_D) do AddRectFilled(draw_list, ImVec2{inner.Max.x, inner.Max.y}, ImVec2{outer.Max.x, outer.Max.y}, col, rounding, {.RoundCornersBottomRight});
}

CalcRoundingFlagsForRectInRect :: proc(r_in : ^ImRect, r_outer : ^ImRect, threshold : f32) -> ImDrawFlags
{
    round_l := r_in.Min.x <= r_outer.Min.x + threshold;
    round_r := r_in.Max.x >= r_outer.Max.x - threshold;
    round_t := r_in.Min.y <= r_outer.Min.y + threshold;
    round_b := r_in.Max.y >= r_outer.Max.y - threshold;
    return ({.RoundCornersNone} |
         ((round_t && round_l) ? { ImDrawFlag.RoundCornersTopLeft } : nil) | ((round_t && round_r) ? { ImDrawFlag.RoundCornersTopRight} : nil) |
         ((round_b && round_l) ? {ImDrawFlag.RoundCornersBottomLeft} : nil) | ((round_b && round_r) ? {ImDrawFlag.RoundCornersBottomRight} : nil));
}

// Helper for ColorPicker4()
// NB: This is rather brittle and will show artifact when rounding this enabled if rounded corners overlap multiple cells. Caller currently responsible for avoiding that.
// Spent a non reasonable amount of time trying to getting this right for ColorButton with rounding+anti-aliasing+ImGuiColorEditFlags_HalfAlphaPreview flag + various grid sizes and offsets, and eventually gave up... probably more reasonable to disable rounding altogether.
// FIXME: uses ImGui::GetColorU32
RenderColorRectWithAlphaCheckerboard :: proc(draw_list : ^ImDrawList, p_min : ImVec2, p_max : ImVec2, col : u32, grid_step : f32, grid_off : ImVec2, rounding : f32 = 0.0, flags : ImDrawFlags = nil)
{
    flags := flags
    if ((flags & ImDrawFlags_RoundCornersMask_) == nil) {
        flags = ImDrawFlags_RoundCornersDefault_;
    }
    if (((col & IM_COL32_A_MASK) >> IM_COL32_A_SHIFT) < 0xFF)
    {
        col_bg1 := GetColorU32(ImAlphaBlendColors(IM_COL32(204, 204, 204, 255), col));
        col_bg2 := GetColorU32(ImAlphaBlendColors(IM_COL32(128, 128, 128, 255), col));
        AddRectFilled(draw_list, p_min, p_max, col_bg1, rounding, flags);

        yi := 0;
        for y : f32 = p_min.y + grid_off.y; y < p_max.y; y, yi = y + grid_step, yi + 1
        {
            y1 := ImClamp(y, p_min.y, p_max.y);
            y2 := ImMin(y + grid_step, p_max.y);
            if (y2 <= y1)   do continue
            for x : f32 = p_min.x + grid_off.x + f32(yi & 1) * grid_step; x < p_max.x; x += grid_step * 2.0
            {
                x1 := ImClamp(x, p_min.x, p_max.x);
                x2 := ImMin(x + grid_step, p_max.x);
                if (x2 <= x1)   do continue
                cell_flags := ImDrawFlags_RoundCornersNone;
                if (y1 <= p_min.y) { if (x1 <= p_min.x) do cell_flags |= ImDrawFlags_RoundCornersTopLeft; if (x2 >= p_max.x) do cell_flags |= ImDrawFlags_RoundCornersTopRight; }
                if (y2 >= p_max.y) { if (x1 <= p_min.x) do cell_flags |= ImDrawFlags_RoundCornersBottomLeft; if (x2 >= p_max.x) do cell_flags |= ImDrawFlags_RoundCornersBottomRight; }

                // Combine flags
                cell_flags = (flags == ImDrawFlags_RoundCornersNone || cell_flags == ImDrawFlags_RoundCornersNone) ? ImDrawFlags_RoundCornersNone : (cell_flags & flags);
                AddRectFilled(draw_list, ImVec2{x1, y1}, ImVec2{x2, y2}, col_bg2, rounding, cell_flags);
            }
        }
    }
    else
    {
        AddRectFilled(draw_list, p_min, p_max, col, rounding, flags);
    }
}

//-----------------------------------------------------------------------------
// [SECTION] Decompression code
//-----------------------------------------------------------------------------
// Compressed with stb_compress() then converted to a C array and encoded as base85.
// Use the program in misc/fonts/binary_to_compressed_c.cpp to create the array from a TTF file.
// The purpose of encoding as base85 instead of "0x00,0x01,..." style is only save on _source code_ size.
// Decompression from stb.h (public domain) by Sean Barrett https://github.com/nothings/stb/blob/master/stb.h
//-----------------------------------------------------------------------------

stb_decompress_length :: proc(input : [^]u8) -> u32
{
    return (u32(input[8]) << 24) + (u32(input[9]) << 16) + (u32(input[10]) << 8) + u32(input[11]);
}

stb__barrier_out_e : [^]u8
stb__barrier_out_b : [^]u8;
stb__barrier_in_b : [^]u8;
stb__dout : [^]u8;
stb__match :: proc(data : [^]u8, length : u32)
{
    data := data
    // INVERSE of memmove... write each byte before copying the next...
    assert(stb__dout[length:] <= stb__barrier_out_e);
    if (stb__dout[length:] > stb__barrier_out_e) { stb__dout = stb__dout[length:]; return; }
    if (data < stb__barrier_out_b) { stb__dout = stb__barrier_out_e[1:]; return; }
    for length := length; length != 0; length -= 1 {
        data = data[1:];
        stb__dout[0] = data[0]
        stb__dout = stb__dout[1:]
    }
}

stb__lit :: proc(data : [^]u8, length : u32)
{
    assert(stb__dout[length:] <= stb__barrier_out_e);
    if (stb__dout[length:] > stb__barrier_out_e) { stb__dout = stb__dout[length:]; return; }
    if (data < stb__barrier_in_b) { stb__dout = stb__barrier_out_e[1:]; return; }
    memcpy(stb__dout, data, cast(int) length);
    stb__dout = stb__dout[length:];
}

stb__in2 :: #force_inline proc(i : [^]u8, x : int) -> u32 { return  ((u32(i[x]) << 8) + u32(i[x+1])) }
stb__in3 :: #force_inline proc(i : [^]u8, x : int) -> u32 { return  ((u32(i[x]) << 16) + stb__in2(i, x+1)) }
stb__in4 :: #force_inline proc(i : [^]u8, x : int) -> u32 { return  ((u32(i[x]) << 24) + stb__in3(i, x+1)) }

stb_decompress_token :: proc(i : [^]u8) -> [^]u8
{
    i := i
    if (i[0] >= 0x20) { // use fewer if's for cases that expand small
        if (i[0] >= 0x80)       { stb__match(stb__dout[-i[1]-1:], u32(i[0]) - 0x80 + 1); i = i[2:]; }
        else if (i[0] >= 0x40)  { stb__match(stb__dout[-(stb__in2(i, 0) - 0x4000 + 1):], u32(i[2])+1); i = i[3:]; }
        else /* i[0] >= 0x20 */ { stb__lit(i[1:], u32(i[0]) - 0x20 + 1); i = i[1 + (i[0] - 0x20 + 1):]; }
    } else { // more ifs for cases that expand large, since overhead is amortized
        if (i[0] >= 0x18)       { stb__match(stb__dout[-(stb__in3(i, 0) - 0x180000 + 1):], u32(i[3])+1); i = i[4:]; }
        else if (i[0] >= 0x10)  { stb__match(stb__dout[-(stb__in3(i, 0) - 0x100000 + 1):], stb__in2(i, 3)+1); i = i[5:]; }
        else if (i[0] >= 0x08)  { stb__lit(i[2:], stb__in2(i, 0) - 0x0800 + 1); i = i[2 + (stb__in2(i, 0) - 0x0800 + 1):]; }
        else if (i[0] == 0x07)  { stb__lit(i[3:], stb__in2(i, 1) + 1); i = i[3 + (stb__in2(i, 1) + 1):]; }
        else if (i[0] == 0x06)  { stb__match(stb__dout[-(stb__in3(i, 1)+1):], u32(i[4])+1); i = i[5:]; }
        else if (i[0] == 0x04)  { stb__match(stb__dout[-(stb__in3(i, 1)+1):], stb__in2(i, 4)+1); i = i[6:]; }
    }
    return i;
}

stb_adler32 :: proc(adler32 : u32, buffer : [^]u8, buflen : u32) -> u32
{
    ADLER_MOD :: 65521;
    s1 : u32 = adler32 & 0xffff; s2 : u32 = adler32 >> 16;
    blocklen : u32 = buflen % 5552;

    i : u32;
    buflen := buflen
    buffer := buffer
    for (buflen != 0) {
        for i = 0; i + 7 < blocklen; i += 8 {
            s1 += u32(buffer[0]); s2 += s1;
            s1 += u32(buffer[1]); s2 += s1;
            s1 += u32(buffer[2]); s2 += s1;
            s1 += u32(buffer[3]); s2 += s1;
            s1 += u32(buffer[4]); s2 += s1;
            s1 += u32(buffer[5]); s2 += s1;
            s1 += u32(buffer[6]); s2 += s1;
            s1 += u32(buffer[7]); s2 += s1;

            buffer = buffer[8:];
        }

        for ; i < blocklen; i += 1 {
            s1 += u32(buffer[0]);
            buffer = buffer[1:];
            s2 += s1;
        }

        s1 %= ADLER_MOD; s2 %= ADLER_MOD;
        buflen -= blocklen;
        blocklen = 5552;
    }
    return (u32)(s2 << 16) + cast(u32) s1;
}

stb_decompress :: proc(output, i : [^]u8, length : u32) -> u32
{
    if (stb__in4(i, 0) != 0x57bC0000) do return 0;
    if (stb__in4(i, 4) != 0)          do return 0; // error! stream is > 4GB
    olen := stb_decompress_length(i);
    stb__barrier_in_b = i;
    stb__barrier_out_e = output[olen:];
    stb__barrier_out_b = output;
    i := i[16:];

    stb__dout = output;
    for {
        old_i := i;
        i = stb_decompress_token(i);
        if (i == old_i) {
            if (i[0] == 0x05 && i[1] == 0xfa) {
                assert(stb__dout == output[olen:]);
                if (stb__dout != output[olen:]) do return 0;
                if (stb_adler32(1, output, olen) != cast(u32) stb__in4(i, 2))   do return 0
                return olen;
            } else {
                assert(false) /* NOTREACHED */
                return 0;
            }
        }
        assert(stb__dout <= output[olen:]);
        if (stb__dout > output[olen:])   do return 0
    }
}

//-----------------------------------------------------------------------------
// [SECTION] Default font data (ProggyClean.ttf)
//-----------------------------------------------------------------------------
// ProggyClean.ttf
// Copyright (c) 2004, 2005 Tristan Grimmer
// MIT license (see License.txt in http://www.proggyfonts.net/index.php?menu=download)
// Download and more information at http://www.proggyfonts.net or http://upperboundsinteractive.com/fonts.php
//-----------------------------------------------------------------------------

when !(IMGUI_DISABLE_DEFAULT_FONT) {

// File: 'ProggyClean.ttf' (41208 bytes)
// Exported using binary_to_compressed_c.exe -u8 "ProggyClean.ttf" proggy_clean_ttf
proggy_clean_ttf_compressed_size :: 9583;
proggy_clean_ttf_compressed_data := [9583]u8 {
    87,188,0,0,0,0,0,0,0,0,160,248,0,4,0,0,55,0,1,0,0,0,12,0,128,0,3,0,64,79,83,47,50,136,235,116,144,0,0,1,72,130,21,44,78,99,109,97,112,2,18,35,117,0,0,3,160,130,19,36,82,99,118,116,
    32,130,23,130,2,33,4,252,130,4,56,2,103,108,121,102,18,175,137,86,0,0,7,4,0,0,146,128,104,101,97,100,215,145,102,211,130,27,32,204,130,3,33,54,104,130,16,39,8,66,1,195,0,0,1,4,130,
    15,59,36,104,109,116,120,138,0,126,128,0,0,1,152,0,0,2,6,108,111,99,97,140,115,176,216,0,0,5,130,30,41,2,4,109,97,120,112,1,174,0,218,130,31,32,40,130,16,44,32,110,97,109,101,37,89,
    187,150,0,0,153,132,130,19,44,158,112,111,115,116,166,172,131,239,0,0,155,36,130,51,44,210,112,114,101,112,105,2,1,18,0,0,4,244,130,47,32,8,132,203,46,1,0,0,60,85,233,213,95,15,60,
    245,0,3,8,0,131,0,34,183,103,119,130,63,43,0,0,189,146,166,215,0,0,254,128,3,128,131,111,130,241,33,2,0,133,0,32,1,130,65,38,192,254,64,0,0,3,128,131,16,130,5,32,1,131,7,138,3,33,2,
    0,130,17,36,1,1,0,144,0,130,121,130,23,38,2,0,8,0,64,0,10,130,9,32,118,130,9,130,6,32,0,130,59,33,1,144,131,200,35,2,188,2,138,130,16,32,143,133,7,37,1,197,0,50,2,0,131,0,33,4,9,131,
    5,145,3,43,65,108,116,115,0,64,0,0,32,172,8,0,131,0,35,5,0,1,128,131,77,131,3,33,3,128,191,1,33,1,128,130,184,35,0,0,128,0,130,3,131,11,32,1,130,7,33,0,128,131,1,32,1,136,9,32,0,132,
    15,135,5,32,1,131,13,135,27,144,35,32,1,149,25,131,21,32,0,130,0,32,128,132,103,130,35,132,39,32,0,136,45,136,97,133,17,130,5,33,0,0,136,19,34,0,128,1,133,13,133,5,32,128,130,15,132,
    131,32,3,130,5,32,3,132,27,144,71,32,0,133,27,130,29,130,31,136,29,131,63,131,3,65,63,5,132,5,132,205,130,9,33,0,0,131,9,137,119,32,3,132,19,138,243,130,55,32,1,132,35,135,19,131,201,
    136,11,132,143,137,13,130,41,32,0,131,3,144,35,33,128,0,135,1,131,223,131,3,141,17,134,13,136,63,134,15,136,53,143,15,130,96,33,0,3,131,4,130,3,34,28,0,1,130,5,34,0,0,76,130,17,131,
    9,36,28,0,4,0,48,130,17,46,8,0,8,0,2,0,0,0,127,0,255,32,172,255,255,130,9,34,0,0,129,132,9,130,102,33,223,213,134,53,132,22,33,1,6,132,6,64,4,215,32,129,165,216,39,177,0,1,141,184,
    1,255,133,134,45,33,198,0,193,1,8,190,244,1,28,1,158,2,20,2,136,2,252,3,20,3,88,3,156,3,222,4,20,4,50,4,80,4,98,4,162,5,22,5,102,5,188,6,18,6,116,6,214,7,56,7,126,7,236,8,78,8,108,
    8,150,8,208,9,16,9,74,9,136,10,22,10,128,11,4,11,86,11,200,12,46,12,130,12,234,13,94,13,164,13,234,14,80,14,150,15,40,15,176,16,18,16,116,16,224,17,82,17,182,18,4,18,110,18,196,19,
    76,19,172,19,246,20,88,20,174,20,234,21,64,21,128,21,166,21,184,22,18,22,126,22,198,23,52,23,142,23,224,24,86,24,186,24,238,25,54,25,150,25,212,26,72,26,156,26,240,27,92,27,200,28,
    4,28,76,28,150,28,234,29,42,29,146,29,210,30,64,30,142,30,224,31,36,31,118,31,166,31,166,32,16,130,1,52,46,32,138,32,178,32,200,33,20,33,116,33,152,33,238,34,98,34,134,35,12,130,1,
    33,128,35,131,1,60,152,35,176,35,216,36,0,36,74,36,104,36,144,36,174,37,6,37,96,37,130,37,248,37,248,38,88,38,170,130,1,8,190,216,39,64,39,154,40,10,40,104,40,168,41,14,41,32,41,184,
    41,248,42,54,42,96,42,96,43,2,43,42,43,94,43,172,43,230,44,32,44,52,44,154,45,40,45,92,45,120,45,170,45,232,46,38,46,166,47,38,47,182,47,244,48,94,48,200,49,62,49,180,50,30,50,158,
    51,30,51,130,51,238,52,92,52,206,53,58,53,134,53,212,54,38,54,114,54,230,55,118,55,216,56,58,56,166,57,18,57,116,57,174,58,46,58,154,59,6,59,124,59,232,60,58,60,150,61,34,61,134,61,
    236,62,86,62,198,63,42,63,154,64,18,64,106,64,208,65,54,65,162,66,8,66,64,66,122,66,184,66,240,67,98,67,204,68,42,68,138,68,238,69,88,69,182,69,226,70,84,70,180,71,20,71,122,71,218,
    72,84,72,198,73,64,0,36,70,21,8,8,77,3,0,7,0,11,0,15,0,19,0,23,0,27,0,31,0,35,0,39,0,43,0,47,0,51,0,55,0,59,0,63,0,67,0,71,0,75,0,79,0,83,0,87,0,91,0,95,0,99,0,103,0,107,0,111,0,115,
    0,119,0,123,0,127,0,131,0,135,0,139,0,143,0,0,17,53,51,21,49,150,3,32,5,130,23,32,33,130,3,211,7,151,115,32,128,133,0,37,252,128,128,2,128,128,190,5,133,74,32,4,133,6,206,5,42,0,7,
    1,128,0,0,2,0,4,0,0,65,139,13,37,0,1,53,51,21,7,146,3,32,3,130,19,32,1,141,133,32,3,141,14,131,13,38,255,0,128,128,0,6,1,130,84,35,2,128,4,128,140,91,132,89,32,51,65,143,6,139,7,33,
    1,0,130,57,32,254,130,3,32,128,132,4,32,4,131,14,138,89,35,0,0,24,0,130,0,33,3,128,144,171,66,55,33,148,115,65,187,19,32,5,130,151,143,155,163,39,32,1,136,182,32,253,134,178,132,7,
    132,200,145,17,32,3,65,48,17,165,17,39,0,0,21,0,128,255,128,3,65,175,17,65,3,27,132,253,131,217,139,201,155,233,155,27,131,67,131,31,130,241,33,255,0,131,181,137,232,132,15,132,4,138,
    247,34,255,0,128,179,238,32,0,130,0,32,20,65,239,48,33,0,19,67,235,10,32,51,65,203,14,65,215,11,32,7,154,27,135,39,32,33,130,35,33,128,128,130,231,32,253,132,231,32,128,132,232,34,
    128,128,254,133,13,136,8,32,253,65,186,5,130,36,130,42,176,234,133,231,34,128,0,0,66,215,44,33,0,1,68,235,6,68,211,19,32,49,68,239,14,139,207,139,47,66,13,7,32,51,130,47,33,1,0,130,
    207,35,128,128,1,0,131,222,131,5,130,212,130,6,131,212,32,0,130,10,133,220,130,233,130,226,32,254,133,255,178,233,39,3,1,128,3,0,2,0,4,68,15,7,68,99,12,130,89,130,104,33,128,4,133,
    93,130,10,38,0,0,11,1,0,255,0,68,63,16,70,39,9,66,215,8,32,7,68,77,6,68,175,14,32,29,68,195,6,132,7,35,2,0,128,255,131,91,132,4,65,178,5,141,111,67,129,23,165,135,140,107,142,135,33,
    21,5,69,71,6,131,7,33,1,0,140,104,132,142,130,4,137,247,140,30,68,255,12,39,11,0,128,0,128,3,0,3,69,171,15,67,251,7,65,15,8,66,249,11,65,229,7,67,211,7,66,13,7,35,1,128,128,254,133,
    93,32,254,131,145,132,4,132,18,32,2,151,128,130,23,34,0,0,9,154,131,65,207,8,68,107,15,68,51,7,32,7,70,59,7,135,121,130,82,32,128,151,111,41,0,0,4,0,128,255,0,1,128,1,137,239,33,0,
    37,70,145,10,65,77,10,65,212,14,37,0,0,0,5,0,128,66,109,5,70,123,10,33,0,19,72,33,18,133,237,70,209,11,33,0,2,130,113,137,119,136,115,33,1,0,133,43,130,5,34,0,0,10,69,135,6,70,219,
    13,66,155,7,65,9,12,66,157,11,66,9,11,32,7,130,141,132,252,66,151,9,137,9,66,15,30,36,0,20,0,128,0,130,218,71,11,42,68,51,8,65,141,7,73,19,15,69,47,23,143,39,66,81,7,32,1,66,55,6,34,
    1,128,128,68,25,5,69,32,6,137,6,136,25,32,254,131,42,32,3,66,88,26,148,26,32,0,130,0,32,14,164,231,70,225,12,66,233,7,67,133,19,71,203,15,130,161,32,255,130,155,32,254,139,127,134,
    12,164,174,33,0,15,164,159,33,59,0,65,125,20,66,25,7,32,5,68,191,6,66,29,7,144,165,65,105,9,35,128,128,255,0,137,2,133,182,164,169,33,128,128,197,171,130,155,68,235,7,32,21,70,77,19,
    66,21,10,68,97,8,66,30,5,66,4,43,34,0,17,0,71,19,41,65,253,20,71,25,23,65,91,15,65,115,7,34,2,128,128,66,9,8,130,169,33,1,0,66,212,13,132,28,72,201,43,35,0,0,0,18,66,27,38,76,231,5,
    68,157,20,135,157,32,7,68,185,13,65,129,28,66,20,5,32,253,66,210,11,65,128,49,133,61,32,0,65,135,6,74,111,37,72,149,12,66,203,19,65,147,19,68,93,7,68,85,8,76,4,5,33,255,0,133,129,34,
    254,0,128,68,69,8,181,197,34,0,0,12,65,135,32,65,123,20,69,183,27,133,156,66,50,5,72,87,10,67,137,32,33,0,19,160,139,78,251,13,68,55,20,67,119,19,65,91,36,69,177,15,32,254,143,16,65,
    98,53,32,128,130,0,32,0,66,43,54,70,141,23,66,23,15,131,39,69,47,11,131,15,70,129,19,74,161,9,36,128,255,0,128,254,130,153,65,148,32,67,41,9,34,0,0,4,79,15,5,73,99,10,71,203,8,32,3,
    72,123,6,72,43,8,32,2,133,56,131,99,130,9,34,0,0,6,72,175,5,73,159,14,144,63,135,197,132,189,133,66,33,255,0,73,6,7,70,137,12,35,0,0,0,10,130,3,73,243,25,67,113,12,65,73,7,69,161,7,
    138,7,37,21,2,0,128,128,254,134,3,73,116,27,33,128,128,130,111,39,12,0,128,1,0,3,128,2,72,219,21,35,43,0,47,0,67,47,20,130,111,33,21,1,68,167,13,81,147,8,133,230,32,128,77,73,6,32,
    128,131,142,134,18,130,6,32,255,75,18,12,131,243,37,128,0,128,3,128,3,74,231,21,135,123,32,29,134,107,135,7,32,21,74,117,7,135,7,134,96,135,246,74,103,23,132,242,33,0,10,67,151,28,
    67,133,20,66,141,11,131,11,32,3,77,71,6,32,128,130,113,32,1,81,4,6,134,218,66,130,24,131,31,34,0,26,0,130,0,77,255,44,83,15,11,148,155,68,13,7,32,49,78,231,18,79,7,11,73,243,11,32,
    33,65,187,10,130,63,65,87,8,73,239,19,35,0,128,1,0,131,226,32,252,65,100,6,32,128,139,8,33,1,0,130,21,32,253,72,155,44,73,255,20,32,128,71,67,8,81,243,39,67,15,20,74,191,23,68,121,
    27,32,1,66,150,6,32,254,79,19,11,131,214,32,128,130,215,37,2,0,128,253,0,128,136,5,65,220,24,147,212,130,210,33,0,24,72,219,42,84,255,13,67,119,16,69,245,19,72,225,19,65,3,15,69,93,
    19,131,55,132,178,71,115,14,81,228,6,142,245,33,253,0,132,43,172,252,65,16,11,75,219,8,65,219,31,66,223,24,75,223,10,33,29,1,80,243,10,66,175,8,131,110,134,203,133,172,130,16,70,30,
    7,164,183,130,163,32,20,65,171,48,65,163,36,65,143,23,65,151,19,65,147,13,65,134,17,133,17,130,216,67,114,5,164,217,65,137,12,72,147,48,79,71,19,74,169,22,80,251,8,65,173,7,66,157,
    15,74,173,15,32,254,65,170,8,71,186,45,72,131,6,77,143,40,187,195,152,179,65,123,38,68,215,57,68,179,15,65,85,7,69,187,14,32,21,66,95,15,67,19,25,32,1,83,223,6,32,2,76,240,7,77,166,
    43,65,8,5,130,206,32,0,67,39,54,143,167,66,255,19,82,193,11,151,47,85,171,5,67,27,17,132,160,69,172,11,69,184,56,66,95,6,33,12,1,130,237,32,2,68,179,27,68,175,16,80,135,15,72,55,7,
    71,87,12,73,3,12,132,12,66,75,32,76,215,5,169,139,147,135,148,139,81,12,12,81,185,36,75,251,7,65,23,27,76,215,9,87,165,12,65,209,15,72,157,7,65,245,31,32,128,71,128,6,32,1,82,125,5,
    34,0,128,254,131,169,32,254,131,187,71,180,9,132,27,32,2,88,129,44,32,0,78,47,40,65,79,23,79,171,14,32,21,71,87,8,72,15,14,65,224,33,130,139,74,27,62,93,23,7,68,31,7,75,27,7,139,15,
    74,3,7,74,23,27,65,165,11,65,177,15,67,123,5,32,1,130,221,32,252,71,96,5,74,12,12,133,244,130,25,34,1,0,128,130,2,139,8,93,26,8,65,9,32,65,57,14,140,14,32,0,73,79,67,68,119,11,135,
    11,32,51,90,75,14,139,247,65,43,7,131,19,139,11,69,159,11,65,247,6,36,1,128,128,253,0,90,71,9,33,1,0,132,14,32,128,89,93,14,69,133,6,130,44,131,30,131,6,65,20,56,33,0,16,72,179,40,
    75,47,12,65,215,19,74,95,19,65,43,11,131,168,67,110,5,75,23,17,69,106,6,75,65,5,71,204,43,32,0,80,75,47,71,203,15,159,181,68,91,11,67,197,7,73,101,13,68,85,6,33,128,128,130,214,130,
    25,32,254,74,236,48,130,194,37,0,18,0,128,255,128,77,215,40,65,139,64,32,51,80,159,10,65,147,39,130,219,84,212,43,130,46,75,19,97,74,33,11,65,201,23,65,173,31,33,1,0,79,133,6,66,150,
    5,67,75,48,85,187,6,70,207,37,32,71,87,221,13,73,163,14,80,167,15,132,15,83,193,19,82,209,8,78,99,9,72,190,11,77,110,49,89,63,5,80,91,35,99,63,32,70,235,23,81,99,10,69,148,10,65,110,
    36,32,0,65,99,47,95,219,11,68,171,51,66,87,7,72,57,7,74,45,17,143,17,65,114,50,33,14,0,65,111,40,159,195,98,135,15,35,7,53,51,21,100,78,9,95,146,16,32,254,82,114,6,32,128,67,208,37,
    130,166,99,79,58,32,17,96,99,14,72,31,19,72,87,31,82,155,7,67,47,14,32,21,131,75,134,231,72,51,17,72,78,8,133,8,80,133,6,33,253,128,88,37,9,66,124,36,72,65,12,134,12,71,55,43,66,139,
    27,85,135,10,91,33,12,65,35,11,66,131,11,71,32,8,90,127,6,130,244,71,76,11,168,207,33,0,12,66,123,32,32,0,65,183,15,68,135,11,66,111,7,67,235,11,66,111,15,32,254,97,66,12,160,154,67,
    227,52,80,33,15,87,249,15,93,45,31,75,111,12,93,45,11,77,99,9,160,184,81,31,12,32,15,98,135,30,104,175,7,77,249,36,69,73,15,78,5,12,32,254,66,151,19,34,128,128,4,87,32,12,149,35,133,
    21,96,151,31,32,19,72,35,5,98,173,15,143,15,32,21,143,99,158,129,33,0,0,65,35,52,65,11,15,147,15,98,75,11,33,1,0,143,151,132,15,32,254,99,200,37,132,43,130,4,39,0,10,0,128,1,128,3,
    0,104,151,14,97,187,20,69,131,15,67,195,11,87,227,7,33,128,128,132,128,33,254,0,68,131,9,65,46,26,42,0,0,0,7,0,0,255,128,3,128,0,88,223,15,33,0,21,89,61,22,66,209,12,65,2,12,37,0,2,
    1,0,3,128,101,83,8,36,0,1,53,51,29,130,3,34,21,1,0,66,53,8,32,0,68,215,6,100,55,25,107,111,9,66,193,11,72,167,8,73,143,31,139,31,33,1,0,131,158,32,254,132,5,33,253,128,65,16,9,133,
    17,89,130,25,141,212,33,0,0,93,39,8,90,131,25,93,39,14,66,217,6,106,179,8,159,181,71,125,15,139,47,138,141,87,11,14,76,23,14,65,231,26,140,209,66,122,8,81,179,5,101,195,26,32,47,74,
    75,13,69,159,11,83,235,11,67,21,16,136,167,131,106,130,165,130,15,32,128,101,90,24,134,142,32,0,65,103,51,108,23,11,101,231,15,75,173,23,74,237,23,66,15,6,66,46,17,66,58,17,65,105,
    49,66,247,55,71,179,12,70,139,15,86,229,7,84,167,15,32,1,95,72,12,89,49,6,33,128,128,65,136,38,66,30,9,32,0,100,239,7,66,247,29,70,105,20,65,141,19,69,81,15,130,144,32,128,83,41,5,
    32,255,131,177,68,185,5,133,126,65,97,37,32,0,130,0,33,21,0,130,55,66,195,28,67,155,13,34,79,0,83,66,213,13,73,241,19,66,59,19,65,125,11,135,201,66,249,16,32,128,66,44,11,66,56,17,
    68,143,8,68,124,38,67,183,12,96,211,9,65,143,29,112,171,5,32,0,68,131,63,34,33,53,51,71,121,11,32,254,98,251,16,32,253,74,231,10,65,175,37,133,206,37,0,0,8,1,0,0,107,123,11,113,115,
    9,33,0,1,130,117,131,3,73,103,7,66,51,18,66,44,5,133,75,70,88,5,32,254,65,39,12,68,80,9,34,12,0,128,107,179,28,68,223,6,155,111,86,147,15,32,2,131,82,141,110,33,254,0,130,15,32,4,103,
    184,15,141,35,87,176,5,83,11,5,71,235,23,114,107,11,65,189,16,70,33,15,86,153,31,135,126,86,145,30,65,183,41,32,0,130,0,32,10,65,183,24,34,35,0,39,67,85,9,65,179,15,143,15,33,1,0,65,
    28,17,157,136,130,123,32,20,130,3,32,0,97,135,24,115,167,19,80,71,12,32,51,110,163,14,78,35,19,131,19,155,23,77,229,8,78,9,17,151,17,67,231,46,94,135,8,73,31,31,93,215,56,82,171,25,
    72,77,8,162,179,169,167,99,131,11,69,85,19,66,215,15,76,129,13,68,115,22,72,79,35,67,113,5,34,0,0,19,70,31,46,65,89,52,73,223,15,85,199,33,95,33,8,132,203,73,29,32,67,48,16,177,215,
    101,13,15,65,141,43,69,141,15,75,89,5,70,0,11,70,235,21,178,215,36,10,0,128,0,0,71,207,24,33,0,19,100,67,6,80,215,11,66,67,7,80,43,12,71,106,7,80,192,5,65,63,5,66,217,26,33,0,13,156,
    119,68,95,5,72,233,12,134,129,85,81,11,76,165,20,65,43,8,73,136,8,75,10,31,38,128,128,0,0,0,13,1,130,4,32,3,106,235,29,114,179,12,66,131,23,32,7,77,133,6,67,89,12,131,139,116,60,9,
    89,15,37,32,0,74,15,7,103,11,22,65,35,5,33,55,0,93,81,28,67,239,23,78,85,5,107,93,14,66,84,17,65,193,26,74,183,10,66,67,34,143,135,79,91,15,32,7,117,111,8,75,56,9,84,212,9,154,134,
    32,0,130,0,32,18,130,3,70,171,41,83,7,16,70,131,19,84,191,15,84,175,19,84,167,30,84,158,12,154,193,68,107,15,33,0,0,65,79,42,65,71,7,73,55,7,118,191,16,83,180,9,32,255,76,166,9,154,
    141,32,0,130,0,69,195,52,65,225,15,151,15,75,215,31,80,56,10,68,240,17,100,32,9,70,147,39,65,93,12,71,71,41,92,85,15,84,135,23,78,35,15,110,27,10,84,125,8,107,115,29,136,160,38,0,0,
    14,0,128,255,0,82,155,24,67,239,8,119,255,11,69,131,11,77,29,6,112,31,8,134,27,105,203,8,32,2,75,51,11,75,195,12,74,13,29,136,161,37,128,0,0,0,11,1,130,163,82,115,8,125,191,17,69,35,
    12,74,137,15,143,15,32,1,65,157,12,136,12,161,142,65,43,40,65,199,6,65,19,24,102,185,11,76,123,11,99,6,12,135,12,32,254,130,8,161,155,101,23,9,39,8,0,0,1,128,3,128,2,78,63,17,72,245,
    12,67,41,11,90,167,9,32,128,97,49,9,32,128,109,51,14,132,97,81,191,8,130,97,125,99,12,121,35,9,127,75,15,71,79,12,81,151,23,87,97,7,70,223,15,80,245,16,105,97,15,32,254,113,17,6,32,
    128,130,8,105,105,8,76,122,18,65,243,21,74,63,7,38,4,1,0,255,0,2,0,119,247,28,133,65,32,255,141,91,35,0,0,0,16,67,63,36,34,59,0,63,77,59,9,119,147,11,143,241,66,173,15,66,31,11,67,
    75,8,81,74,16,32,128,131,255,87,181,42,127,43,5,34,255,128,2,120,235,11,37,19,0,23,0,0,37,109,191,14,118,219,7,127,43,14,65,79,14,35,0,0,0,3,73,91,5,130,5,38,3,0,7,0,11,0,0,70,205,
    11,88,221,12,32,0,73,135,7,87,15,22,73,135,10,79,153,15,97,71,19,65,49,11,32,1,131,104,121,235,11,80,65,11,142,179,144,14,81,123,46,32,1,88,217,5,112,5,8,65,201,15,83,29,15,122,147,
    11,135,179,142,175,143,185,67,247,39,66,199,7,35,5,0,128,3,69,203,15,123,163,12,67,127,7,130,119,71,153,10,141,102,70,175,8,32,128,121,235,30,136,89,100,191,11,116,195,11,111,235,15,
    72,39,7,32,2,97,43,5,132,5,94,67,8,131,8,125,253,10,32,3,65,158,16,146,16,130,170,40,0,21,0,128,0,0,3,128,5,88,219,15,24,64,159,32,135,141,65,167,15,68,163,10,97,73,49,32,255,82,58,
    7,93,80,8,97,81,16,24,67,87,52,34,0,0,5,130,231,33,128,2,80,51,13,65,129,8,113,61,6,132,175,65,219,5,130,136,77,152,17,32,0,95,131,61,70,215,6,33,21,51,90,53,10,78,97,23,105,77,31,
    65,117,7,139,75,24,68,195,9,24,64,22,9,33,0,128,130,11,33,128,128,66,25,5,121,38,5,134,5,134,45,66,40,36,66,59,18,34,128,0,0,66,59,81,135,245,123,103,19,120,159,19,77,175,12,33,255,
    0,87,29,10,94,70,21,66,59,54,39,3,1,128,3,0,2,128,4,24,65,7,15,66,47,7,72,98,12,37,0,0,0,3,1,0,24,65,55,21,131,195,32,1,67,178,6,33,4,0,77,141,8,32,6,131,47,74,67,16,24,69,3,20,24,
    65,251,7,133,234,130,229,94,108,17,35,0,0,6,0,141,175,86,59,5,162,79,85,166,8,70,112,13,32,13,24,64,67,26,24,71,255,7,123,211,12,80,121,11,69,215,15,66,217,11,69,71,10,131,113,132,
    126,119,90,9,66,117,19,132,19,32,0,130,0,24,64,47,59,33,7,0,73,227,5,68,243,15,85,13,12,76,37,22,74,254,15,130,138,33,0,4,65,111,6,137,79,65,107,16,32,1,77,200,6,34,128,128,3,75,154,
    12,37,0,16,0,0,2,0,104,115,36,140,157,68,67,19,68,51,15,106,243,15,134,120,70,37,10,68,27,10,140,152,65,121,24,32,128,94,155,7,67,11,8,24,74,11,25,65,3,12,83,89,18,82,21,37,67,200,
    5,130,144,24,64,172,12,33,4,0,134,162,74,80,14,145,184,32,0,130,0,69,251,20,32,19,81,243,5,82,143,8,33,5,53,89,203,5,133,112,79,109,15,33,0,21,130,71,80,175,41,36,75,0,79,0,83,121,
    117,9,87,89,27,66,103,11,70,13,15,75,191,11,135,67,87,97,20,109,203,5,69,246,8,108,171,5,78,195,38,65,51,13,107,203,11,77,3,17,24,75,239,17,65,229,28,79,129,39,130,175,32,128,123,253,
    7,132,142,24,65,51,15,65,239,41,36,128,128,0,0,13,65,171,5,66,163,28,136,183,118,137,11,80,255,15,67,65,7,74,111,8,32,0,130,157,32,253,24,76,35,10,103,212,5,81,175,9,69,141,7,66,150,
    29,131,158,24,75,199,28,124,185,7,76,205,15,68,124,14,32,3,123,139,16,130,16,33,128,128,108,199,6,33,0,3,65,191,35,107,11,6,73,197,11,24,70,121,15,83,247,15,24,70,173,23,69,205,14,
    32,253,131,140,32,254,136,4,94,198,9,32,3,78,4,13,66,127,13,143,13,32,0,130,0,33,16,0,24,69,59,39,109,147,12,76,253,19,24,69,207,15,69,229,15,130,195,71,90,10,139,10,130,152,73,43,
    40,91,139,10,65,131,37,35,75,0,79,0,84,227,12,143,151,68,25,15,80,9,23,95,169,11,34,128,2,128,112,186,5,130,6,83,161,19,76,50,6,130,37,65,145,44,110,83,5,32,16,67,99,6,71,67,15,76,
    55,17,140,215,67,97,23,76,69,15,77,237,11,104,211,23,77,238,11,65,154,43,33,0,10,83,15,28,83,13,20,67,145,19,67,141,14,97,149,21,68,9,15,86,251,5,66,207,5,66,27,37,82,1,23,127,71,12,
    94,235,10,110,175,24,98,243,15,132,154,132,4,24,66,69,10,32,4,67,156,43,130,198,35,2,1,0,4,75,27,9,69,85,9,95,240,7,32,128,130,35,32,28,66,43,40,24,82,63,23,83,123,12,72,231,15,127,
    59,23,116,23,19,117,71,7,24,77,99,15,67,111,15,71,101,8,36,2,128,128,252,128,127,60,11,32,1,132,16,130,18,141,24,67,107,9,32,3,68,194,15,175,15,38,0,11,0,128,1,128,2,80,63,25,32,0,
    24,65,73,11,69,185,15,83,243,16,32,0,24,81,165,8,130,86,77,35,6,155,163,88,203,5,24,66,195,30,70,19,19,24,80,133,15,32,1,75,211,8,32,254,108,133,8,79,87,20,65,32,9,41,0,0,7,0,128,0,
    0,2,128,2,68,87,15,66,1,16,92,201,16,24,76,24,17,133,17,34,128,0,30,66,127,64,34,115,0,119,73,205,9,66,43,11,109,143,15,24,79,203,11,90,143,15,131,15,155,31,65,185,15,86,87,11,35,128,
    128,253,0,69,7,6,130,213,33,1,0,119,178,15,142,17,66,141,74,83,28,6,36,7,0,0,4,128,82,39,18,76,149,12,67,69,21,32,128,79,118,15,32,0,130,0,32,8,131,206,32,2,79,83,9,100,223,14,102,
    113,23,115,115,7,24,65,231,12,130,162,32,4,68,182,19,130,102,93,143,8,69,107,29,24,77,255,12,143,197,72,51,7,76,195,15,132,139,85,49,15,130,152,131,18,71,81,23,70,14,11,36,0,10,0,128,
    2,69,59,9,89,151,15,66,241,11,76,165,12,71,43,15,75,49,13,65,12,23,132,37,32,0,179,115,130,231,95,181,16,132,77,32,254,67,224,8,65,126,20,79,171,8,32,2,89,81,5,75,143,6,80,41,8,34,
    2,0,128,24,81,72,9,32,0,130,0,35,17,0,0,255,77,99,39,95,65,36,67,109,15,24,69,93,11,77,239,5,95,77,23,35,128,1,0,128,24,86,7,8,132,167,32,2,69,198,41,130,202,33,0,26,120,75,44,24,89,
    51,15,71,243,12,70,239,11,24,84,3,11,66,7,11,71,255,10,32,21,69,155,35,88,151,12,32,128,74,38,10,65,210,8,74,251,5,65,226,5,75,201,13,32,3,65,9,41,146,41,40,0,0,0,9,1,0,1,0,2,91,99,
    19,32,35,106,119,13,70,219,15,83,239,12,137,154,32,2,67,252,19,36,128,0,0,4,1,130,196,32,2,130,8,91,107,8,32,0,135,81,24,73,211,8,132,161,73,164,13,36,0,8,0,128,2,105,123,26,139,67,
    76,99,15,34,1,0,128,135,76,83,156,20,92,104,8,67,251,30,24,86,47,27,123,207,12,24,86,7,15,71,227,8,32,4,65,20,20,131,127,32,0,130,123,32,0,71,223,26,32,19,90,195,22,71,223,15,84,200,
    6,32,128,133,241,24,84,149,9,67,41,25,36,0,0,0,22,0,88,111,49,32,87,66,21,5,77,3,27,123,75,7,71,143,19,135,183,71,183,19,130,171,74,252,5,131,5,89,87,17,32,1,132,18,130,232,68,11,10,
    33,1,128,70,208,16,66,230,18,147,18,130,254,223,255,75,27,23,65,59,15,135,39,155,255,34,128,128,254,104,92,8,33,0,128,65,32,11,65,1,58,33,26,0,130,0,72,71,18,78,55,17,76,11,19,86,101,
    12,75,223,11,89,15,11,24,76,87,15,75,235,15,131,15,72,95,7,85,71,11,72,115,11,73,64,6,34,1,128,128,66,215,9,34,128,254,128,134,14,33,128,255,67,102,5,32,0,130,16,70,38,11,66,26,57,
    88,11,8,24,76,215,34,78,139,7,95,245,7,32,7,24,73,75,23,32,128,131,167,130,170,101,158,9,82,49,22,118,139,6,32,18,67,155,44,116,187,9,108,55,14,80,155,23,66,131,15,93,77,10,131,168,
    32,128,73,211,12,24,75,187,22,32,4,96,71,20,67,108,19,132,19,120,207,8,32,5,76,79,15,66,111,21,66,95,8,32,3,190,211,111,3,8,211,212,32,20,65,167,44,34,75,0,79,97,59,13,32,33,112,63,
    10,65,147,19,69,39,19,143,39,24,66,71,9,130,224,65,185,43,94,176,12,65,183,24,71,38,8,24,72,167,7,65,191,38,136,235,24,96,167,12,65,203,62,115,131,13,65,208,42,175,235,67,127,6,32,
    4,76,171,29,114,187,5,32,71,65,211,5,65,203,68,72,51,8,164,219,32,0,172,214,71,239,58,78,3,27,66,143,15,77,19,15,147,31,35,33,53,51,21,66,183,10,173,245,66,170,30,150,30,34,0,0,23,
    80,123,54,76,1,16,73,125,15,82,245,11,167,253,24,76,85,12,70,184,5,32,254,131,185,37,254,0,128,1,0,128,133,16,117,158,18,92,27,38,65,3,17,130,251,35,17,0,128,254,24,69,83,39,140,243,
    121,73,19,109,167,7,81,41,15,24,95,175,12,102,227,15,121,96,11,24,95,189,7,32,3,145,171,154,17,24,77,47,9,33,0,5,70,71,37,68,135,7,32,29,117,171,11,69,87,15,24,79,97,19,24,79,149,23,
    131,59,32,1,75,235,5,72,115,11,72,143,7,132,188,71,27,46,131,51,32,0,69,95,6,175,215,32,21,131,167,81,15,19,151,191,151,23,131,215,71,43,5,32,254,24,79,164,24,74,109,8,77,166,13,65,
    176,26,88,162,5,98,159,6,171,219,120,247,6,79,29,8,99,169,10,103,59,19,65,209,35,131,35,91,25,19,112,94,15,83,36,8,173,229,33,20,0,88,75,43,71,31,12,65,191,71,33,1,0,130,203,32,254,
    131,4,68,66,7,67,130,6,104,61,13,173,215,38,13,1,0,0,0,2,128,67,111,28,74,129,16,104,35,19,79,161,16,87,14,7,138,143,132,10,67,62,36,114,115,5,162,151,67,33,16,108,181,15,143,151,67,
    5,5,24,100,242,15,170,153,34,0,0,14,65,51,34,32,55,79,75,9,32,51,74,7,10,65,57,38,132,142,32,254,72,0,14,139,163,32,128,80,254,8,67,158,21,65,63,7,32,4,72,227,27,95,155,12,67,119,19,
    124,91,24,149,154,72,177,34,97,223,8,155,151,24,108,227,15,88,147,16,72,117,19,68,35,11,92,253,15,70,199,15,24,87,209,17,32,2,87,233,7,32,1,24,88,195,10,119,24,8,32,3,81,227,24,65,
    125,21,35,128,128,0,25,76,59,48,24,90,187,9,97,235,12,66,61,11,91,105,19,24,79,141,11,24,79,117,15,24,79,129,27,90,53,13,130,13,32,253,131,228,24,79,133,40,69,70,8,66,137,31,65,33,
    19,96,107,8,68,119,29,66,7,5,68,125,16,65,253,19,65,241,27,24,90,179,13,24,79,143,18,33,128,128,130,246,32,254,130,168,68,154,36,77,51,9,97,47,5,167,195,32,21,131,183,78,239,27,155,
    195,78,231,14,201,196,77,11,6,32,5,73,111,37,97,247,12,77,19,31,155,207,78,215,19,162,212,69,17,14,66,91,19,80,143,57,78,203,39,159,215,32,128,93,134,8,24,80,109,24,66,113,15,169,215,
    66,115,6,32,4,69,63,33,32,0,101,113,7,86,227,35,143,211,36,49,53,51,21,1,77,185,14,65,159,28,69,251,34,67,56,8,33,9,0,24,107,175,25,90,111,12,110,251,11,119,189,24,119,187,34,87,15,
    9,32,4,66,231,37,90,39,7,66,239,8,84,219,15,69,105,23,24,85,27,27,87,31,11,33,1,128,76,94,6,32,1,85,241,7,33,128,128,106,48,10,33,128,128,69,136,11,133,13,24,79,116,49,84,236,8,24,
    91,87,9,32,5,165,255,69,115,12,66,27,15,159,15,24,72,247,12,74,178,5,24,80,64,15,33,0,128,143,17,77,89,51,130,214,24,81,43,7,170,215,74,49,8,159,199,143,31,139,215,69,143,5,32,254,
    24,81,50,35,181,217,84,123,70,143,195,159,15,65,187,16,66,123,7,65,175,15,65,193,29,68,207,39,79,27,5,70,131,6,32,4,68,211,33,33,67,0,83,143,14,159,207,143,31,140,223,33,0,128,24,80,
    82,14,24,93,16,23,32,253,65,195,5,68,227,40,133,214,107,31,7,32,5,67,115,27,87,9,8,107,31,43,66,125,6,32,0,103,177,23,131,127,72,203,36,32,0,110,103,8,155,163,73,135,6,32,19,24,112,
    99,10,65,71,11,73,143,19,143,31,126,195,5,24,85,21,9,24,76,47,14,32,254,24,93,77,36,68,207,11,39,25,0,0,255,128,3,128,4,66,51,37,95,247,13,82,255,24,76,39,19,147,221,66,85,27,24,118,
    7,8,24,74,249,12,76,74,8,91,234,8,67,80,17,131,222,33,253,0,121,30,44,73,0,16,69,15,6,32,0,65,23,38,69,231,12,65,179,6,98,131,16,86,31,27,24,108,157,14,80,160,8,24,65,46,17,33,4,0,
    96,2,18,144,191,65,226,8,68,19,5,171,199,80,9,15,180,199,67,89,5,32,255,24,79,173,28,174,201,24,79,179,50,32,1,24,122,5,10,82,61,10,180,209,83,19,8,32,128,24,80,129,27,111,248,43,131,
    71,24,115,103,8,67,127,41,78,213,24,100,247,19,66,115,39,75,107,5,32,254,165,219,78,170,40,24,112,163,49,32,1,97,203,6,65,173,64,32,0,83,54,7,133,217,88,37,12,32,254,131,28,33,128,
    3,67,71,44,84,183,6,32,5,69,223,33,96,7,7,123,137,16,192,211,24,112,14,9,32,255,67,88,29,68,14,10,84,197,38,33,0,22,116,47,50,32,87,106,99,9,116,49,15,89,225,15,97,231,23,70,41,19,
    82,85,8,93,167,6,32,253,132,236,108,190,7,89,251,5,116,49,58,33,128,128,131,234,32,15,24,74,67,38,70,227,24,24,83,45,23,89,219,12,70,187,12,89,216,19,32,2,69,185,24,141,24,70,143,66,
    24,82,119,56,78,24,10,32,253,133,149,132,6,24,106,233,7,69,198,48,178,203,81,243,12,68,211,15,106,255,23,66,91,15,69,193,7,100,39,10,24,83,72,16,176,204,33,19,0,88,207,45,68,21,12,
    68,17,10,65,157,53,68,17,6,32,254,92,67,10,65,161,25,69,182,43,24,118,91,47,69,183,18,181,209,111,253,12,89,159,8,66,112,12,69,184,45,35,0,0,0,9,24,80,227,26,73,185,16,118,195,15,131,
    15,33,1,0,65,59,15,66,39,27,160,111,66,205,12,148,111,143,110,33,128,128,156,112,24,81,199,8,75,199,23,66,117,20,155,121,32,254,68,126,12,72,213,29,134,239,149,123,89,27,16,148,117,
    65,245,8,24,71,159,14,141,134,134,28,73,51,55,109,77,15,105,131,11,68,67,11,76,169,27,107,209,12,102,174,8,32,128,72,100,18,116,163,56,79,203,11,75,183,44,85,119,19,71,119,23,151,227,
    32,1,93,27,8,65,122,5,77,102,8,110,120,20,66,23,8,66,175,17,66,63,12,133,12,79,35,8,74,235,33,67,149,16,69,243,15,78,57,15,69,235,16,67,177,7,151,192,130,23,67,84,29,141,192,174,187,
    77,67,15,69,11,12,159,187,77,59,10,199,189,24,70,235,50,96,83,19,66,53,23,105,65,19,77,47,12,163,199,66,67,37,78,207,50,67,23,23,174,205,67,228,6,71,107,13,67,22,14,66,85,11,83,187,
    38,124,47,49,95,7,19,66,83,23,67,23,19,24,96,78,17,80,101,16,71,98,40,33,0,7,88,131,22,24,89,245,12,84,45,12,102,213,5,123,12,9,32,2,126,21,14,43,255,0,128,128,0,0,20,0,128,255,128,
    3,126,19,39,32,75,106,51,7,113,129,15,24,110,135,19,126,47,15,115,117,11,69,47,11,32,2,109,76,9,102,109,9,32,128,75,2,10,130,21,32,254,69,47,6,32,3,94,217,47,32,0,65,247,10,69,15,46,
    65,235,31,65,243,15,101,139,10,66,174,14,65,247,16,72,102,28,69,17,14,84,243,9,165,191,88,47,48,66,53,12,32,128,71,108,6,203,193,32,17,75,187,42,73,65,16,65,133,52,114,123,9,167,199,
    69,21,37,86,127,44,75,171,11,180,197,78,213,12,148,200,81,97,46,24,95,243,9,32,4,66,75,33,113,103,9,87,243,36,143,225,24,84,27,31,90,145,8,148,216,67,49,5,24,84,34,14,75,155,27,67,
    52,13,140,13,36,0,20,0,128,255,24,135,99,46,88,59,43,155,249,80,165,7,136,144,71,161,23,32,253,132,33,32,254,88,87,44,136,84,35,128,0,0,21,81,103,5,94,47,44,76,51,12,143,197,151,15,
    65,215,31,24,64,77,13,65,220,20,65,214,14,71,4,40,65,213,13,32,0,130,0,35,21,1,2,0,135,0,34,36,0,72,134,10,36,1,0,26,0,130,134,11,36,2,0,14,0,108,134,11,32,3,138,23,32,4,138,11,34,
    5,0,20,134,33,34,0,0,6,132,23,32,1,134,15,32,18,130,25,133,11,37,1,0,13,0,49,0,133,11,36,2,0,7,0,38,134,11,36,3,0,17,0,45,134,11,32,4,138,35,36,5,0,10,0,62,134,23,32,6,132,23,36,3,
    0,1,4,9,130,87,131,167,133,11,133,167,133,11,133,167,133,11,37,3,0,34,0,122,0,133,11,133,167,133,11,133,167,133,11,133,167,34,50,0,48,130,1,34,52,0,47,134,5,8,49,49,0,53,98,121,32,
    84,114,105,115,116,97,110,32,71,114,105,109,109,101,114,82,101,103,117,108,97,114,84,84,88,32,80,114,111,103,103,121,67,108,101,97,110,84,84,50,48,48,52,47,130,2,53,49,53,0,98,0,121,
    0,32,0,84,0,114,0,105,0,115,0,116,0,97,0,110,130,15,32,71,132,15,36,109,0,109,0,101,130,9,32,82,130,5,36,103,0,117,0,108,130,29,32,114,130,43,34,84,0,88,130,35,32,80,130,25,34,111,
    0,103,130,1,34,121,0,67,130,27,32,101,132,59,32,84,130,31,33,0,0,65,155,9,34,20,0,0,65,11,6,130,8,135,2,33,1,1,130,9,8,120,1,1,2,1,3,1,4,1,5,1,6,1,7,1,8,1,9,1,10,1,11,1,12,1,13,1,14,
    1,15,1,16,1,17,1,18,1,19,1,20,1,21,1,22,1,23,1,24,1,25,1,26,1,27,1,28,1,29,1,30,1,31,1,32,0,3,0,4,0,5,0,6,0,7,0,8,0,9,0,10,0,11,0,12,0,13,0,14,0,15,0,16,0,17,0,18,0,19,0,20,0,21,0,
    22,0,23,0,24,0,25,0,26,0,27,0,28,0,29,0,30,0,31,130,187,8,66,33,0,34,0,35,0,36,0,37,0,38,0,39,0,40,0,41,0,42,0,43,0,44,0,45,0,46,0,47,0,48,0,49,0,50,0,51,0,52,0,53,0,54,0,55,0,56,0,
    57,0,58,0,59,0,60,0,61,0,62,0,63,0,64,0,65,0,66,130,243,9,75,68,0,69,0,70,0,71,0,72,0,73,0,74,0,75,0,76,0,77,0,78,0,79,0,80,0,81,0,82,0,83,0,84,0,85,0,86,0,87,0,88,0,89,0,90,0,91,0,
    92,0,93,0,94,0,95,0,96,0,97,1,33,1,34,1,35,1,36,1,37,1,38,1,39,1,40,1,41,1,42,1,43,1,44,1,45,1,46,1,47,1,48,1,49,1,50,1,51,1,52,1,53,1,54,1,55,1,56,1,57,1,58,1,59,1,60,1,61,1,62,1,
    63,1,64,1,65,0,172,0,163,0,132,0,133,0,189,0,150,0,232,0,134,0,142,0,139,0,157,0,169,0,164,0,239,0,138,0,218,0,131,0,147,0,242,0,243,0,141,0,151,0,136,0,195,0,222,0,241,0,158,0,170,
    0,245,0,244,0,246,0,162,0,173,0,201,0,199,0,174,0,98,0,99,0,144,0,100,0,203,0,101,0,200,0,202,0,207,0,204,0,205,0,206,0,233,0,102,0,211,0,208,0,209,0,175,0,103,0,240,0,145,0,214,0,
    212,0,213,0,104,0,235,0,237,0,137,0,106,0,105,0,107,0,109,0,108,0,110,0,160,0,111,0,113,0,112,0,114,0,115,0,117,0,116,0,118,0,119,0,234,0,120,0,122,0,121,0,123,0,125,0,124,0,184,0,
    161,0,127,0,126,0,128,0,129,0,236,0,238,0,186,14,117,110,105,99,111,100,101,35,48,120,48,48,48,49,141,14,32,50,141,14,32,51,141,14,32,52,141,14,32,53,141,14,32,54,141,14,32,55,141,
    14,32,56,141,14,32,57,141,14,32,97,141,14,32,98,141,14,32,99,141,14,32,100,141,14,32,101,141,14,32,102,140,14,33,49,48,141,14,141,239,32,49,141,239,32,49,141,239,32,49,141,239,32,49,
    141,239,32,49,141,239,32,49,141,239,32,49,141,239,32,49,141,239,32,49,141,239,32,49,141,239,32,49,141,239,32,49,141,239,32,49,141,239,45,49,102,6,100,101,108,101,116,101,4,69,117,114,
    111,140,236,32,56,141,236,32,56,141,236,32,56,141,236,32,56,141,236,32,56,141,236,32,56,141,236,32,56,141,236,32,56,141,236,32,56,141,236,32,56,141,236,32,56,141,236,32,56,141,236,
    32,56,141,236,32,56,141,236,32,56,65,220,13,32,57,65,220,13,32,57,141,239,32,57,141,239,32,57,141,239,32,57,141,239,32,57,141,239,32,57,141,239,32,57,141,239,32,57,141,239,32,57,141,
    239,32,57,141,239,32,57,141,239,32,57,141,239,32,57,141,239,32,57,141,239,35,57,102,0,0,5,250,72,249,98,247,
};

GetDefaultCompressedFontDataTTF :: proc(out_size : ^i32) -> [^]u8
{
    out_size^ = proggy_clean_ttf_compressed_size;
    return raw_data(&proggy_clean_ttf_compressed_data);
}
} // #ifndef IMGUI_DISABLE_DEFAULT_FONT
