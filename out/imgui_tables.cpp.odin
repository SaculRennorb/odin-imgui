package imgui

// dear imgui, v1.91.7 WIP
// (tables and columns code)

/*

Index of this file:

// [SECTION] Commentary
// [SECTION] Header mess
// [SECTION] Tables: Main code
// [SECTION] Tables: Simple accessors
// [SECTION] Tables: Row changes
// [SECTION] Tables: Columns changes
// [SECTION] Tables: Columns width management
// [SECTION] Tables: Drawing
// [SECTION] Tables: Sorting
// [SECTION] Tables: Headers
// [SECTION] Tables: Context Menu
// [SECTION] Tables: Settings (.ini data)
// [SECTION] Tables: Garbage Collection
// [SECTION] Tables: Debugging
// [SECTION] Columns, BeginColumns, EndColumns, etc.

*/

// Navigating this file:
// - In Visual Studio: CTRL+comma ("Edit.GoToAll") can follow symbols inside comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
// - In Visual Studio w/ Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols inside comments.
// - In VS Code, CLion, etc.: CTRL+click can follow symbols inside comments.

//-----------------------------------------------------------------------------
// [SECTION] Commentary
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Typical tables call flow: (root level is generally public API):
//-----------------------------------------------------------------------------
// - BeginTable()                               user begin into a table
//    | BeginChild()                            - (if ScrollX/ScrollY is set)
//    | TableBeginInitMemory()                  - first time table is used
//    | TableResetSettings()                    - on settings reset
//    | TableLoadSettings()                     - on settings load
//    | TableBeginApplyRequests()               - apply queued resizing/reordering/hiding requests
//    | - TableSetColumnWidth()                 - apply resizing width (for mouse resize, often requested by previous frame)
//    |    - TableUpdateColumnsWeightFromWidth()- recompute columns weights (of stretch columns) from their respective width
// - TableSetupColumn()                         user submit columns details (optional)
// - TableSetupScrollFreeze()                   user submit scroll freeze information (optional)
//-----------------------------------------------------------------------------
// - TableUpdateLayout() [Internal]             followup to BeginTable(): setup everything: widths, columns positions, clipping rectangles. Automatically called by the FIRST call to TableNextRow() or TableHeadersRow().
//    | TableSetupDrawChannels()                - setup ImDrawList channels
//    | TableUpdateBorders()                    - detect hovering columns for resize, ahead of contents submission
//    | TableBeginContextMenuPopup()
//    | - TableDrawDefaultContextMenu()         - draw right-click context menu contents
//-----------------------------------------------------------------------------
// - TableHeadersRow() or TableHeader()         user submit a headers row (optional)
//    | TableSortSpecsClickColumn()             - when left-clicked: alter sort order and sort direction
//    | TableOpenContextMenu()                  - when right-clicked: trigger opening of the default context menu
// - TableGetSortSpecs()                        user queries updated sort specs (optional, generally after submitting headers)
// - TableNextRow()                             user begin into a new row (also automatically called by TableHeadersRow())
//    | TableEndRow()                           - finish existing row
//    | TableBeginRow()                         - add a new row
// - TableSetColumnIndex() / TableNextColumn()  user begin into a cell
//    | TableEndCell()                          - close existing column/cell
//    | TableBeginCell()                        - enter into current column/cell
// - [...]                                      user emit contents
//-----------------------------------------------------------------------------
// - EndTable()                                 user ends the table
//    | TableDrawBorders()                      - draw outer borders, inner vertical borders
//    | TableMergeDrawChannels()                - merge draw channels if clipping isn't required
//    | EndChild()                              - (if ScrollX/ScrollY is set)
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// TABLE SIZING
//-----------------------------------------------------------------------------
// (Read carefully because this is subtle but it does make sense!)
//-----------------------------------------------------------------------------
// About 'outer_size':
// Its meaning needs to differ slightly depending on if we are using ScrollX/ScrollY flags.
// Default value is ImVec2(0.0f, 0.0f).
//   X
//   - outer_size.x <= 0.0f  ->  Right-align from window/work-rect right-most edge. With -FLT_MIN or 0.0f will align exactly on right-most edge.
//   - outer_size.x  > 0.0f  ->  Set Fixed width.
//   Y with ScrollX/ScrollY disabled: we output table directly in current window
//   - outer_size.y  < 0.0f  ->  Bottom-align (but will auto extend, unless _NoHostExtendY is set). Not meaningful if parent window can vertically scroll.
//   - outer_size.y  = 0.0f  ->  No minimum height (but will auto extend, unless _NoHostExtendY is set)
//   - outer_size.y  > 0.0f  ->  Set Minimum height (but will auto extend, unless _NoHostExtendY is set)
//   Y with ScrollX/ScrollY enabled: using a child window for scrolling
//   - outer_size.y  < 0.0f  ->  Bottom-align. Not meaningful if parent window can vertically scroll.
//   - outer_size.y  = 0.0f  ->  Bottom-align, consistent with BeginChild(). Not recommended unless table is last item in parent window.
//   - outer_size.y  > 0.0f  ->  Set Exact height. Recommended when using Scrolling on any axis.
//-----------------------------------------------------------------------------
// Outer size is also affected by the NoHostExtendX/NoHostExtendY flags.
// Important to note how the two flags have slightly different behaviors!
//   - ImGuiTableFlags_NoHostExtendX -> Make outer width auto-fit to columns (overriding outer_size.x value). Only available when ScrollX/ScrollY are disabled and Stretch columns are not used.
//   - ImGuiTableFlags_NoHostExtendY -> Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit). Only available when ScrollX/ScrollY is disabled. Data below the limit will be clipped and not visible.
// In theory ImGuiTableFlags_NoHostExtendY could be the default and any non-scrolling tables with outer_size.y != 0.0f would use exact height.
// This would be consistent but perhaps less useful and more confusing (as vertically clipped items are not useful and not easily noticeable).
//-----------------------------------------------------------------------------
// About 'inner_width':
//   With ScrollX disabled:
//   - inner_width          ->  *ignored*
//   With ScrollX enabled:
//   - inner_width  < 0.0f  ->  *illegal* fit in known width (right align from outer_size.x) <-- weird
//   - inner_width  = 0.0f  ->  fit in outer_width: Fixed size columns will take space they need (if avail, otherwise shrink down), Stretch columns becomes Fixed columns.
//   - inner_width  > 0.0f  ->  override scrolling width, generally to be larger than outer_size.x. Fixed column take space they need (if avail, otherwise shrink down), Stretch columns share remaining space!
//-----------------------------------------------------------------------------
// Details:
// - If you want to use Stretch columns with ScrollX, you generally need to specify 'inner_width' otherwise the concept
//   of "available space" doesn't make sense.
// - Even if not really useful, we allow 'inner_width < outer_size.x' for consistency and to facilitate understanding
//   of what the value does.
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// COLUMNS SIZING POLICIES
// (Reference: ImGuiTableFlags_SizingXXX flags and ImGuiTableColumnFlags_WidthXXX flags)
//-----------------------------------------------------------------------------
// About overriding column sizing policy and width/weight with TableSetupColumn():
// We use a default parameter of -1 for 'init_width'/'init_weight'.
//   - with ImGuiTableColumnFlags_WidthFixed,    init_width  <= 0 (default)  --> width is automatic
//   - with ImGuiTableColumnFlags_WidthFixed,    init_width  >  0 (explicit) --> width is custom
//   - with ImGuiTableColumnFlags_WidthStretch,  init_weight <= 0 (default)  --> weight is 1.0f
//   - with ImGuiTableColumnFlags_WidthStretch,  init_weight >  0 (explicit) --> weight is custom
// Widths are specified _without_ CellPadding. If you specify a width of 100.0f, the column will be cover (100.0f + Padding * 2.0f)
// and you can fit a 100.0f wide item in it without clipping and with padding honored.
//-----------------------------------------------------------------------------
// About default sizing policy (if you don't specify a ImGuiTableColumnFlags_WidthXXXX flag)
//   - with Table policy ImGuiTableFlags_SizingFixedFit      --> default Column policy is ImGuiTableColumnFlags_WidthFixed, default Width is equal to contents width
//   - with Table policy ImGuiTableFlags_SizingFixedSame     --> default Column policy is ImGuiTableColumnFlags_WidthFixed, default Width is max of all contents width
//   - with Table policy ImGuiTableFlags_SizingStretchSame   --> default Column policy is ImGuiTableColumnFlags_WidthStretch, default Weight is 1.0f
//   - with Table policy ImGuiTableFlags_SizingStretchWeight --> default Column policy is ImGuiTableColumnFlags_WidthStretch, default Weight is proportional to contents
// Default Width and default Weight can be overridden when calling TableSetupColumn().
//-----------------------------------------------------------------------------
// About mixing Fixed/Auto and Stretch columns together:
//   - the typical use of mixing sizing policies is: any number of LEADING Fixed columns, followed by one or two TRAILING Stretch columns.
//   - using mixed policies with ScrollX does not make much sense, as using Stretch columns with ScrollX does not make much sense in the first place!
//     that is, unless 'inner_width' is passed to BeginTable() to explicitly provide a total width to layout columns in.
//   - when using ImGuiTableFlags_SizingFixedSame with mixed columns, only the Fixed/Auto columns will match their widths to the width of the maximum contents.
//   - when using ImGuiTableFlags_SizingStretchSame with mixed columns, only the Stretch columns will match their weights/widths.
//-----------------------------------------------------------------------------
// About using column width:
// If a column is manually resizable or has a width specified with TableSetupColumn():
//   - you may use GetContentRegionAvail().x to query the width available in a given column.
//   - right-side alignment features such as SetNextItemWidth(-x) or PushItemWidth(-x) will rely on this width.
// If the column is not resizable and has no width specified with TableSetupColumn():
//   - its width will be automatic and be set to the max of items submitted.
//   - therefore you generally cannot have ALL items of the columns use e.g. SetNextItemWidth(-FLT_MIN).
//   - but if the column has one or more items of known/fixed size, this will become the reference width used by SetNextItemWidth(-FLT_MIN).
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
// TABLES CLIPPING/CULLING
//-----------------------------------------------------------------------------
// About clipping/culling of Rows in Tables:
// - For large numbers of rows, it is recommended you use ImGuiListClipper to submit only visible rows.
//   ImGuiListClipper is reliant on the fact that rows are of equal height.
//   See 'Demo->Tables->Vertical Scrolling' or 'Demo->Tables->Advanced' for a demo of using the clipper.
// - Note that auto-resizing columns don't play well with using the clipper.
//   By default a table with _ScrollX but without _Resizable will have column auto-resize.
//   So, if you want to use the clipper, make sure to either enable _Resizable, either setup columns width explicitly with _WidthFixed.
//-----------------------------------------------------------------------------
// About clipping/culling of Columns in Tables:
// - Both TableSetColumnIndex() and TableNextColumn() return true when the column is visible or performing
//   width measurements. Otherwise, you may skip submitting the contents of a cell/column, BUT ONLY if you know
//   it is not going to contribute to row height.
//   In many situations, you may skip submitting contents for every column but one (e.g. the first one).
// - Case A: column is not hidden by user, and at least partially in sight (most common case).
// - Case B: column is clipped / out of sight (because of scrolling or parent ClipRect): TableNextColumn() return false as a hint but we still allow layout output.
// - Case C: column is hidden explicitly by the user (e.g. via the context menu, or _DefaultHide column flag, etc.).
//
//                        [A]         [B]          [C]
//  TableNextColumn():    true        false        false       -> [userland] when TableNextColumn() / TableSetColumnIndex() returns false, user can skip submitting items but only if the column doesn't contribute to row height.
//          SkipItems:    false       false        true        -> [internal] when SkipItems is true, most widgets will early out if submitted, resulting is no layout output.
//           ClipRect:    normal      zero-width   zero-width  -> [internal] when ClipRect is zero, ItemAdd() will return false and most widgets will early out mid-way.
//  ImDrawList output:    normal      dummy        dummy       -> [internal] when using the dummy channel, ImDrawList submissions (if any) will be wasted (because cliprect is zero-width anyway).
//
// - We need to distinguish those cases because non-hidden columns that are clipped outside of scrolling bounds should still contribute their height to the row.
//   However, in the majority of cases, the contribution to row height is the same for all columns, or the tallest cells are known by the programmer.
//-----------------------------------------------------------------------------
// About clipping/culling of whole Tables:
// - Scrolling tables with a known outer size can be clipped earlier as BeginTable() will return false.
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// [SECTION] Header mess
//-----------------------------------------------------------------------------

when defined(_MSC_VER) && !defined(_CRT_SECURE_NO_WARNINGS) {
_CRT_SECURE_NO_WARNINGS :: true
}

IMGUI_DEFINE_MATH_OPERATORS :: true

when !(IMGUI_DISABLE) {

// System includes

// Visual Studio warnings
when _MSC_VER {
when defined(_MSC_VER) && _MSC_VER >= 1922 { // MSVC 2019 16.2 or later
}
}

// Clang/GCC warnings with -Weverything

//-----------------------------------------------------------------------------
// [SECTION] Tables: Main code
//-----------------------------------------------------------------------------
// - TableFixFlags() [Internal]
// - TableFindByID() [Internal]
// - BeginTable()
// - BeginTableEx() [Internal]
// - TableBeginInitMemory() [Internal]
// - TableBeginApplyRequests() [Internal]
// - TableSetupColumnFlags() [Internal]
// - TableUpdateLayout() [Internal]
// - TableUpdateBorders() [Internal]
// - EndTable()
// - TableSetupColumn()
// - TableSetupScrollFreeze()
//-----------------------------------------------------------------------------

// Configuration
TABLE_DRAW_CHANNEL_BG0 := 0;
TABLE_DRAW_CHANNEL_BG2_FROZEN := 1;
TABLE_DRAW_CHANNEL_NOCLIP := 2;                     // When using ImGuiTableFlags_NoClip (this becomes the last visible channel)
TABLE_BORDER_SIZE := 1.0;    // FIXME-TABLE: Currently hard-coded because of clipping assumptions with outer borders rendering.
TABLE_RESIZE_SEPARATOR_HALF_THICKNESS := 4.0;    // Extend outside inner borders.
TABLE_RESIZE_SEPARATOR_FEEDBACK_TIMER := 0.06;   // Delay/timer before making the hover feedback (color+cursor) visible because tables/columns tends to be more cramped.

// Helper
inline ImGuiTableFlags TableFixFlags(ImGuiTableFlags flags, ImGuiWindow* outer_window)
{
    // Adjust flags: set default sizing policy
    if ((flags & ImGuiTableFlags_SizingMask_) == 0)
        flags |= ((flags & ImGuiTableFlags_ScrollX) || (outer_window.Flags & ImGuiWindowFlags_AlwaysAutoResize)) ? ImGuiTableFlags_SizingFixedFit : ImGuiTableFlags_SizingStretchSame;

    // Adjust flags: enable NoKeepColumnsVisible when using ImGuiTableFlags_SizingFixedSame
    if ((flags & ImGuiTableFlags_SizingMask_) == ImGuiTableFlags_SizingFixedSame)
        flags |= ImGuiTableFlags_NoKeepColumnsVisible;

    // Adjust flags: enforce borders when resizable
    if (flags & ImGuiTableFlags_Resizable)
        flags |= ImGuiTableFlags_BordersInnerV;

    // Adjust flags: disable NoHostExtendX/NoHostExtendY if we have any scrolling going on
    if (flags & (ImGuiTableFlags_ScrollX | ImGuiTableFlags_ScrollY))
        flags &= ~(ImGuiTableFlags_NoHostExtendX | ImGuiTableFlags_NoHostExtendY);

    // Adjust flags: NoBordersInBodyUntilResize takes priority over NoBordersInBody
    if (flags & ImGuiTableFlags_NoBordersInBodyUntilResize)
        flags &= ~ImGuiTableFlags_NoBordersInBody;

    // Adjust flags: disable saved settings if there's nothing to save
    if ((flags & (ImGuiTableFlags_Resizable | ImGuiTableFlags_Hideable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Sortable)) == 0)
        flags |= ImGuiTableFlags_NoSavedSettings;

    // Inherit _NoSavedSettings from top-level window (child windows always have _NoSavedSettings set)
    if (outer_window.RootWindow->Flags & ImGuiWindowFlags_NoSavedSettings)
        flags |= ImGuiTableFlags_NoSavedSettings;

    return flags;
}

TableFindByID :: proc(id : ImGuiID) -> ^ImGuiTable
{
    g := GImGui;
    return g.Tables.GetByKey(id);
}

// Read about "TABLE SIZING" at the top of this file.
BeginTable :: proc(str_id : ^u8, columns_count : i32, flags : ImGuiTableFlags = {}, outer_size : ImVec2 = 0.0, inner_width : f32 = 0.0) -> bool
{
    id := GetID(str_id);
    return BeginTableEx(str_id, id, columns_count, flags, outer_size, inner_width);
}

BeginTableEx :: proc(name : ^u8, id : ImGuiID, columns_count : i32, flags : ImGuiTableFlags, outer_size : ImVec2, inner_width : f32) -> bool
{
    g := GImGui;
    outer_window := GetCurrentWindow();
    if (outer_window.SkipItems) // Consistent with other tables + beneficial side effect that assert on miscalling EndTable() will be more visible.
        return false;

    // Sanity checks
    assert(columns_count > 0 && columns_count < IMGUI_TABLE_MAX_COLUMNS);
    if (flags & ImGuiTableFlags_ScrollX)
        assert(inner_width >= 0.0);

    // If an outer size is specified ahead we will be able to early out when not visible. Exact clipping criteria may evolve.
    // FIXME: coarse clipping because access to table data causes two issues:
    // - instance numbers varying/unstable. may not be a direct problem for users, but could make outside access broken or confusing, e.g. TestEngine.
    // - can't implement support for ImGuiChildFlags_ResizeY as we need to somehow pull the height data from somewhere. this also needs stable instance numbers.
    // The side-effects of accessing table data on coarse clip would be:
    // - always reserving the pooled ImGuiTable data ahead for a fully clipped table (minor IMHO). Also the 'outer_window_is_measuring_size' criteria may already be defeating this in some situations.
    // - always performing the GetOrAddByKey() O(log N) query in g.Tables.Map[].
    use_child_window := (flags & (ImGuiTableFlags_ScrollX | ImGuiTableFlags_ScrollY)) != 0;
    avail_size := GetContentRegionAvail();
    actual_outer_size := ImTrunc(CalcItemSize(outer_size, ImMax(avail_size.x, 1.0), use_child_window ? ImMax(avail_size.y, 1.0) : 0.0));
    outer_rect := ImRect(outer_window.DC.CursorPos, outer_window.DC.CursorPos + actual_outer_size);
    outer_window_is_measuring_size := (outer_window.AutoFitFramesX > 0) || (outer_window.AutoFitFramesY > 0); // Doesn't apply to AlwaysAutoResize windows!
    if (use_child_window && IsClippedEx(outer_rect, 0) && !outer_window_is_measuring_size)
    {
        ItemSize(outer_rect);
        ItemAdd(outer_rect, id);
        return false;
    }

    // [DEBUG] Debug break requested by user
    if (g.DebugBreakInTable == id)
        runtime.debug_trap;

    // Acquire storage for the table
    table := g.Tables.GetOrAddByKey(id);

    // Acquire temporary buffers
    table_idx := g.Tables.GetIndex(table);
    if (++g.TablesTempDataStacked > g.TablesTempData.Size)
        g.TablesTempData.resize(g.TablesTempDataStacked, ImGuiTableTempData());
    temp_data := table.TempData = &g.TablesTempData[g.TablesTempDataStacked - 1];
    temp_data.TableIndex = table_idx;
    table.DrawSplitter = &table.TempData->DrawSplitter;
    table.DrawSplitter->Clear();

    // Fix flags
    table.IsDefaultSizingPolicy = (flags & ImGuiTableFlags_SizingMask_) == 0;
    flags = TableFixFlags(flags, outer_window);

    // Initialize
    previous_frame_active := table.LastFrameActive;
    instance_no := (previous_frame_active != g.FrameCount) ? 0 : table.InstanceCurrent + 1;
    previous_flags := table.Flags;
    table.ID = id;
    table.Flags = flags;
    table.LastFrameActive = g.FrameCount;
    table.OuterWindow = table.InnerWindow = outer_window;
    table.ColumnsCount = columns_count;
    table.IsLayoutLocked = false;
    table.InnerWidth = inner_width;
    temp_data.UserOuterSize = outer_size;

    // Instance data (for instance 0, TableID == TableInstanceID)
    instance_id : ImGuiID
    table.InstanceCurrent = cast(ast) ast) nce_noc
    if (instance_no > 0)
    {
        assert(table.ColumnsCount == columns_count, "BeginTable(): Cannot change columns count mid-frame for preserving same ID");
        if (table.InstanceDataExtra.Size < instance_no)
            table.InstanceDataExtra.push_back(ImGuiTableInstanceData());
        instance_id = GetIDWithSeed(instance_no, GetIDWithSeed("##Instances", nil, id)); // Push "##Instances" followed by (int)instance_no in ID stack.
    }
    else
    {
        instance_id = id;
    }
    table_instance := TableGetInstanceData(table, table.InstanceCurrent);
    table_instance.TableInstanceID = instance_id;

    // When not using a child window, WorkRect.Max will grow as we append contents.
    if (use_child_window)
    {
        // Ensure no vertical scrollbar appears if we only want horizontal one, to make flag consistent
        // (we have no other way to disable vertical scrollbar of a window while keeping the horizontal one showing)
        override_content_size := overri(ri(h.F32_MAX, math.F32_MAX);
        if ((flags & ImGuiTableFlags_ScrollX) && !(flags & ImGuiTableFlags_ScrollY))
            override_content_size.y = math.F32_MIN;

        // Ensure specified width (when not specified, Stretched columns will act as if the width == OuterWidth and
        // never lead to any scrolling). We don't handle inner_width < 0.0f, we could potentially use it to right-align
        // based on the right side of the child window work rect, which would require knowing ahead if we are going to
        // have decoration taking horizontal spaces (typically a vertical scrollbar).
        if ((flags & ImGuiTableFlags_ScrollX) && inner_width > 0.0)
            override_content_size.x = inner_width;

        if (override_content_size.x != math.F32_MAX || override_content_size.y != math.F32_MAX)
            SetNextWindowContentSize(ImVec2{override_content_size.x != math.F32_MAX ? override_content_size.x : 0.0, override_content_size.y != math.F32_MAX ? override_content_size.y : 0.0});

        // Reset scroll if we are reactivating it
        if ((previous_flags & (ImGuiTableFlags_ScrollX | ImGuiTableFlags_ScrollY)) == 0)
            if ((g.NextWindowData.Flags & ImGuiNextWindowDataFlags_HasScroll) == 0)
                SetNextWindowScroll(ImVec2{0.0, 0.0});

        // Create scrolling region (without border and zero window padding)
        child_window_flags := (flags & ImGuiTableFlags_ScrollX) ? ImGuiWindowFlags_HorizontalScrollbar : ImGuiWindowFlags_None;
        BeginChildEx(name, instance_id, outer_rect.GetSize(), ImGuiChildFlags_None, child_window_flags);
        table.InnerWindow = g.CurrentWindow;
        table.WorkRect = table.InnerWindow->WorkRect;
        table.OuterRect = table.InnerWindow->Rect();
        table.InnerRect = table.InnerWindow->InnerRect;
        assert(table.InnerWindow->WindowPadding.x == 0.0 && table.InnerWindow->WindowPadding.y == 0.0 && table.InnerWindow->WindowBorderSize == 0.0);

        // Allow submitting when host is measuring
        if (table.InnerWindow->SkipItems && outer_window_is_measuring_size)
            table.InnerWindow->SkipItems = false;

        // When using multiple instances, ensure they have the same amount of horizontal decorations (aka vertical scrollbar) so stretched columns can be aligned)
        if (instance_no == 0)
        {
            table.HasScrollbarYPrev = table.HasScrollbarYCurr;
            table.HasScrollbarYCurr = false;
        }
        table.HasScrollbarYCurr |= table.InnerWindow->ScrollbarY;
    }
    else
    {
        // For non-scrolling tables, WorkRect == OuterRect == InnerRect.
        // But at this point we do NOT have a correct value for .Max.y (unless a height has been explicitly passed in). It will only be updated in EndTable().
        table.WorkRect = table.OuterRect = table.InnerRect = outer_rect;
        table.HasScrollbarYPrev = table.HasScrollbarYCurr = false;
    }

    // Push a standardized ID for both child-using and not-child-using tables
    PushOverrideID(id);
    if (instance_no > 0)
        PushOverrideID(instance_id); // FIXME: Somehow this is not resolved by stack-tool, even tho GetIDWithSeed() submitted the symbol.

    // Backup a copy of host window members we will modify
    inner_window := table.InnerWindow;
    table.HostIndentX = inner_window.DC.Indent.x;
    table.HostClipRect = inner_window.ClipRect;
    table.HostSkipItems = inner_window.SkipItems;
    temp_data.HostBackupWorkRect = inner_window.WorkRect;
    temp_data.HostBackupParentWorkRect = inner_window.ParentWorkRect;
    temp_data.HostBackupColumnsOffset = outer_window.DC.ColumnsOffset;
    temp_data.HostBackupPrevLineSize = inner_window.DC.PrevLineSize;
    temp_data.HostBackupCurrLineSize = inner_window.DC.CurrLineSize;
    temp_data.HostBackupCursorMaxPos = inner_window.DC.CursorMaxPos;
    temp_data.HostBackupItemWidth = outer_window.DC.ItemWidth;
    temp_data.HostBackupItemWidthStackSize = outer_window.DC.ItemWidthStack.Size;
    inner_window.DC.PrevLineSize = inner_window.DC.CurrLineSize = ImVec2{0.0, 0.0};

    // Make borders not overlap our contents by offsetting HostClipRect (#6765, #7428, #3752)
    // (we normally shouldn't alter HostClipRect as we rely on TableMergeDrawChannels() expanding non-clipped column toward the
    // limits of that rectangle, in order for ImDrawListSplitter::Merge() to merge the draw commands. However since the overlap
    // problem only affect scrolling tables in this case we can get away with doing it without extra cost).
    if (inner_window != outer_window)
    {
        // FIXME: Because inner_window's Scrollbar doesn't know about border size, since it's not encoded in window->WindowBorderSize,
        // it already overlaps it and doesn't need an extra offset. Ideally we should be able to pass custom border size with
        // different x/y values to BeginChild().
        if (flags & ImGuiTableFlags_BordersOuterV)
        {
            table.HostClipRect.Min.x = ImMin(table.HostClipRect.Min.x + TABLE_BORDER_SIZE, table.HostClipRect.Max.x);
            if (inner_window.DecoOuterSizeX2 == 0.0)
                table.HostClipRect.Max.x = ImMax(table.HostClipRect.Max.x - TABLE_BORDER_SIZE, table.HostClipRect.Min.x);
        }
        if (flags & ImGuiTableFlags_BordersOuterH)
        {
            table.HostClipRect.Min.y = ImMin(table.HostClipRect.Min.y + TABLE_BORDER_SIZE, table.HostClipRect.Max.y);
            if (inner_window.DecoOuterSizeY2 == 0.0)
                table.HostClipRect.Max.y = ImMax(table.HostClipRect.Max.y - TABLE_BORDER_SIZE, table.HostClipRect.Min.y);
        }
    }

    // Padding and Spacing
    // - None               ........Content..... Pad .....Content........
    // - PadOuter           | Pad ..Content..... Pad .....Content.. Pad |
    // - PadInner           ........Content.. Pad | Pad ..Content........
    // - PadOuter+PadInner  | Pad ..Content.. Pad | Pad ..Content.. Pad |
    pad_outer_x := (flags & ImGuiTableFlags_NoPadOuterX) ? false : (flags & ImGuiTableFlags_PadOuterX) ? true : (flags & ImGuiTableFlags_BordersOuterV) != 0;
    pad_inner_x := (flags & ImGuiTableFlags_NoPadInnerX) ? false : true;
    inner_spacing_for_border := (flags & ImGuiTableFlags_BordersInnerV) ? TABLE_BORDER_SIZE : 0.0;
    inner_spacing_explicit := (pad_inner_x && (flags & ImGuiTableFlags_BordersInnerV) == 0) ? g.Style.CellPadding.x : 0.0;
    inner_padding_explicit := (pad_inner_x && (flags & ImGuiTableFlags_BordersInnerV) != 0) ? g.Style.CellPadding.x : 0.0;
    table.CellSpacingX1 = inner_spacing_explicit + inner_spacing_for_border;
    table.CellSpacingX2 = inner_spacing_explicit;
    table.CellPaddingX = inner_padding_explicit;

    outer_padding_for_border := (flags & ImGuiTableFlags_BordersOuterV) ? TABLE_BORDER_SIZE : 0.0;
    outer_padding_explicit := pad_outer_x ? g.Style.CellPadding.x : 0.0;
    table.OuterPaddingX = (outer_padding_for_border + outer_padding_explicit) - table.CellPaddingX;

    table.CurrentColumn = -1;
    table.CurrentRow = -1;
    table.RowBgColorCounter = 0;
    table.LastRowFlags = ImGuiTableRowFlags_None;
    table.InnerClipRect = (inner_window == outer_window) ? table.WorkRect : inner_window.ClipRect;
    table.InnerClipRect.ClipWith(table.WorkRect);     // We need this to honor inner_width
    table.InnerClipRect.ClipWithFull(table.HostClipRect);
    table.InnerClipRect.Max.y = (flags & ImGuiTableFlags_NoHostExtendY) ? ImMin(table.InnerClipRect.Max.y, inner_window.WorkRect.Max.y) : table.HostClipRect.Max.y;

    table.RowPosY1 = table.RowPosY2 = table.WorkRect.Min.y; // This is needed somehow
    table.RowTextBaseline = 0.0; // This will be cleared again by TableBeginRow()
    table.RowCellPaddingY = 0.0;
    table.FreezeRowsRequest = table.FreezeRowsCount = 0; // This will be setup by TableSetupScrollFreeze(), if any
    table.FreezeColumnsRequest = table.FreezeColumnsCount = 0;
    table.IsUnfrozenRows = true;
    table.DeclColumnsCount = table.AngledHeadersCount = 0;
    if (previous_frame_active + 1 < g.FrameCount)
        table.IsActiveIdInTable = false;
    table.AngledHeadersHeight = 0.0;
    temp_data.AngledHeadersExtraWidth = 0.0;

    // Using opaque colors facilitate overlapping lines of the grid, otherwise we'd need to improve TableDrawBorders()
    table.BorderColorStrong = GetColorU32(ImGuiCol_TableBorderStrong);
    table.BorderColorLight = GetColorU32(ImGuiCol_TableBorderLight);

    // Make table current
    g.CurrentTable = table;
    outer_window.DC.NavIsScrollPushableX = false; // Shortcut for NavUpdateCurrentWindowIsScrollPushableX();
    outer_window.DC.CurrentTableIdx = table_idx;
    if (inner_window != outer_window) // So EndChild() within the inner window can restore the table properly.
        inner_window.DC.CurrentTableIdx = table_idx;

    if ((previous_flags & ImGuiTableFlags_Reorderable) && (flags & ImGuiTableFlags_Reorderable) == 0)
        table.IsResetDisplayOrderRequest = true;

    // Mark as used to avoid GC
    if (table_idx >= g.TablesLastTimeActive.Size)
        g.TablesLastTimeActive.resize(table_idx + 1, -1.0);
    g.TablesLastTimeActive[table_idx] = cast(ast) ast) a;
    temp_data.LastTimeActive = cast(ast) ast) a;
    table.MemoryCompacted = false;

    // Setup memory buffer (clear data if columns count changed)
    old_columns_to_preserve := nil;
    old_columns_raw_data := nil;
    old_columns_count := table.Columns.size();
    if (old_columns_count != 0 && old_columns_count != columns_count)
    {
        // Attempt to preserve width on column count change (#4046)
        old_columns_to_preserve = table.Columns.Data;
        old_columns_raw_data = table.RawData;
        table.RawData = nil;
    }
    if (table.RawData == nil)
    {
        TableBeginInitMemory(table, columns_count);
        table.IsInitializing = table.IsSettingsRequestLoad = true;
    }
    if (table.IsResetAllRequest)
        TableResetSettings(table);
    if (table.IsInitializing)
    {
        // Initialize
        table.SettingsOffset = -1;
        table.IsSortSpecsDirty = true;
        table.InstanceInteracted = -1;
        table.ContextPopupColumn = -1;
        table.ReorderColumn = table.ResizedColumn = table.LastResizedColumn = -1;
        table.AutoFitSingleColumn = -1;
        table.HoveredColumnBody = table.HoveredColumnBorder = -1;
        for i32 n = 0; n < columns_count; n++
        {
            column := &table.Columns[n];
            if (old_columns_to_preserve && n < old_columns_count)
            {
                // FIXME: We don't attempt to preserve column order in this path.
                column^ = old_columns_to_preserve[n];
            }
            else
            {
                width_auto := column.WidthAuto;
                column^ = ImGuiTableColumn();
                column.WidthAuto = width_auto;
                column.IsPreserveWidthAuto = true; // Preserve WidthAuto when reinitializing a live table: not technically necessary but remove a visible flicker
                column.IsEnabled = column.IsUserEnabled = column.IsUserEnabledNextFrame = true;
            }
            column.DisplayOrder = table.DisplayOrderToIndex[n] = (ImGuiTableColumnIdx)n;
        }
    }
    if (old_columns_raw_data)
        IM_FREE(old_columns_raw_data);

    // Load settings
    if (table.IsSettingsRequestLoad)
        TableLoadSettings(table);

    // Handle DPI/font resize
    // This is designed to facilitate DPI changes with the assumption that e.g. style.CellPadding has been scaled as well.
    // It will also react to changing fonts with mixed results. It doesn't need to be perfect but merely provide a decent transition.
    // FIXME-DPI: Provide consistent standards for reference size. Perhaps using g.CurrentDpiScale would be more self explanatory.
    // This is will lead us to non-rounded WidthRequest in columns, which should work but is a poorly tested path.
    new_ref_scale_unit := g.FontSize; // g.Font->GetCharAdvance('A') ?
    if (table.RefScale != 0.0 && table.RefScale != new_ref_scale_unit)
    {
        scale_factor := new_ref_scale_unit / table.RefScale;
        //IMGUI_DEBUG_PRINT("[table] %08X RefScaleUnit %.3f -> %.3f, scaling width by %.3f\n", table->ID, table->RefScaleUnit, new_ref_scale_unit, scale_factor);
        for i32 n = 0; n < columns_count; n++
            table.Columns[n].WidthRequest = table.Columns[n].WidthRequest * scale_factor;
    }
    table.RefScale = new_ref_scale_unit;

    // Disable output until user calls TableNextRow() or TableNextColumn() leading to the TableUpdateLayout() call..
    // This is not strictly necessary but will reduce cases were "out of table" output will be misleading to the user.
    // Because we cannot safely assert in EndTable() when no rows have been created, this seems like our best option.
    inner_window.SkipItems = true;

    // Clear names
    // At this point the ->NameOffset field of each column will be invalid until TableUpdateLayout() or the first call to TableSetupColumn()
    if (table.ColumnsNames.Buf.Size > 0)
        table.ColumnsNames.Buf.resize(0);

    // Apply queued resizing/reordering/hiding requests
    TableBeginApplyRequests(table);

    return true;
}

// For reference, the average total _allocation count_ for a table is:
// + 0 (for ImGuiTable instance, we are pooling allocations in g.Tables[])
// + 1 (for table->RawData allocated below)
// + 1 (for table->ColumnsNames, if names are used)
// Shared allocations for the maximum number of simultaneously nested tables (generally a very small number)
// + 1 (for table->Splitter._Channels)
// + 2 * active_channels_count (for ImDrawCmd and ImDrawIdx buffers inside channels)
// Where active_channels_count is variable but often == columns_count or == columns_count + 1, see TableSetupDrawChannels() for details.
// Unused channels don't perform their +2 allocations.
TableBeginInitMemory :: proc(table : ^ImGuiTable, columns_count : i32)
{
    // Allocate single buffer for our arrays
    columns_bit_array_size := cast(ast) ast) ArrayGetStorageSizeInBytesBytesmns_count);
    span_allocator : ImSpanAllocator<6>
    span_allocator.Reserve(0, columns_count * size_of(ImGuiTableColumn));
    span_allocator.Reserve(1, columns_count * size_of(ImGuiTableColumnIdx));
    span_allocator.Reserve(2, columns_count * size_of(ImGuiTableCellData), 4);
    for i32 n = 3; n < 6; n++
        span_allocator.Reserve(n, columns_bit_array_size);
    table.RawData = IM_ALLOC(span_allocator.GetArenaSizeInBytes());
    memset(table.RawData, 0, span_allocator.GetArenaSizeInBytes());
    span_allocator.SetArenaBasePtr(table.RawData);
    span_allocator.GetSpan(0, &table.Columns);
    span_allocator.GetSpan(1, &table.DisplayOrderToIndex);
    span_allocator.GetSpan(2, &table.RowCellData);
    table.EnabledMaskByDisplayOrder = (u32*)span_allocator.GetSpanPtrBegin(3);
    table.EnabledMaskByIndex = (u32*)span_allocator.GetSpanPtrBegin(4);
    table.VisibleMaskByIndex = (u32*)span_allocator.GetSpanPtrBegin(5);
}

// Apply queued resizing/reordering/hiding requests
TableBeginApplyRequests :: proc(table : ^ImGuiTable)
{
    // Handle resizing request
    // (We process this in the TableBegin() of the first instance of each table)
    // FIXME-TABLE: Contains columns if our work area doesn't allow for scrolling?
    if (table.InstanceCurrent == 0)
    {
        if (table.ResizedColumn != -1 && table.ResizedColumnNextWidth != math.F32_MAX)
            TableSetColumnWidth(table.ResizedColumn, table.ResizedColumnNextWidth);
        table.LastResizedColumn = table.ResizedColumn;
        table.ResizedColumnNextWidth = math.F32_MAX;
        table.ResizedColumn = -1;

        // Process auto-fit for single column, which is a special case for stretch columns and fixed columns with FixedSame policy.
        // FIXME-TABLE: Would be nice to redistribute available stretch space accordingly to other weights, instead of giving it all to siblings.
        if (table.AutoFitSingleColumn != -1)
        {
            TableSetColumnWidth(table.AutoFitSingleColumn, table.Columns[table.AutoFitSingleColumn].WidthAuto);
            table.AutoFitSingleColumn = -1;
        }
    }

    // Handle reordering request
    // Note: we don't clear ReorderColumn after handling the request.
    if (table.InstanceCurrent == 0)
    {
        if (table.HeldHeaderColumn == -1 && table.ReorderColumn != -1)
            table.ReorderColumn = -1;
        table.HeldHeaderColumn = -1;
        if (table.ReorderColumn != -1 && table.ReorderColumnDir != 0)
        {
            // We need to handle reordering across hidden columns.
            // In the configuration below, moving C to the right of E will lead to:
            //    ... C [D] E  --->  ... [D] E  C   (Column name/index)
            //    ... 2  3  4        ...  2  3  4   (Display order)
            reorder_dir := table.ReorderColumnDir;
            assert(reorder_dir == -1 || reorder_dir == +1);
            assert(table.Flags & ImGuiTableFlags_Reorderable);
            src_column := &table.Columns[table.ReorderColumn];
            dst_column := &table.Columns[(reorder_dir == -1) ? src_column.PrevEnabledColumn : src_column.NextEnabledColumn];
            IM_UNUSED(dst_column);
            src_order := src_column.DisplayOrder;
            dst_order := dst_column.DisplayOrder;
            src_column.DisplayOrder = (ImGuiTableColumnIdx)dst_order;
            for i32 order_n = src_order + reorder_dir; order_n != dst_order + reorder_dir; order_n += reorder_dir
                table.Columns[table.DisplayOrderToIndex[order_n]].DisplayOrder -= (ImGuiTableColumnIdx)reorder_dir;
            assert(dst_column.DisplayOrder == dst_order - reorder_dir);

            // Display order is stored in both columns->IndexDisplayOrder and table->DisplayOrder[]. Rebuild later from the former.
            for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
                table.DisplayOrderToIndex[table.Columns[column_n].DisplayOrder] = (ImGuiTableColumnIdx)column_n;
            table.ReorderColumnDir = 0;
            table.IsSettingsDirty = true;
        }
    }

    // Handle display order reset request
    if (table.IsResetDisplayOrderRequest)
    {
        for i32 n = 0; n < table.ColumnsCount; n++
            table.DisplayOrderToIndex[n] = table.Columns[n].DisplayOrder = (ImGuiTableColumnIdx)n;
        table.IsResetDisplayOrderRequest = false;
        table.IsSettingsDirty = true;
    }
}

// Adjust flags: default width mode + stretch columns are not allowed when auto extending
TableSetupColumnFlags :: proc(table : ^ImGuiTable, column : ^ImGuiTableColumn, flags_in : ImGuiTableColumnFlags)
{
    flags := flags_in;

    // Sizing Policy
    if ((flags & ImGuiTableColumnFlags_WidthMask_) == 0)
    {
        table_sizing_policy := (table.Flags & ImGuiTableFlags_SizingMask_);
        if (table_sizing_policy == ImGuiTableFlags_SizingFixedFit || table_sizing_policy == ImGuiTableFlags_SizingFixedSame)
            flags |= ImGuiTableColumnFlags_WidthFixed;
        else
            flags |= ImGuiTableColumnFlags_WidthStretch;
    }
    else
    {
        assert(math.is_power_of_two(flags & ImGuiTableColumnFlags_WidthMask_)); // Check that only 1 of each set is used.
    }

    // Resize
    if ((table.Flags & ImGuiTableFlags_Resizable) == 0)
        flags |= ImGuiTableColumnFlags_NoResize;

    // Sorting
    if ((flags & ImGuiTableColumnFlags_NoSortAscending) && (flags & ImGuiTableColumnFlags_NoSortDescending))
        flags |= ImGuiTableColumnFlags_NoSort;

    // Indentation
    if ((flags & ImGuiTableColumnFlags_IndentMask_) == 0)
        flags |= (table.Columns.index_from_ptr(column) == 0) ? ImGuiTableColumnFlags_IndentEnable : ImGuiTableColumnFlags_IndentDisable;

    // Alignment
    //if ((flags & ImGuiTableColumnFlags_AlignMask_) == 0)
    //    flags |= ImGuiTableColumnFlags_AlignCenter;
    //IM_ASSERT(ImIsPowerOfTwo(flags & ImGuiTableColumnFlags_AlignMask_)); // Check that only 1 of each set is used.

    // Preserve status flags
    column.Flags = flags | (column.Flags & ImGuiTableColumnFlags_StatusMask_);

    // Build an ordered list of available sort directions
    column.SortDirectionsAvailCount = column.SortDirectionsAvailMask = column.SortDirectionsAvailList = 0;
    if (table.Flags & ImGuiTableFlags_Sortable)
    {
        count := 0, mask = 0, list = 0;
        if ((flags & ImGuiTableColumnFlags_PreferSortAscending)  != 0 && (flags & ImGuiTableColumnFlags_NoSortAscending)  == 0) { mask |= 1 << ImGuiSortDirection_Ascending;  list |= ImGuiSortDirection_Ascending  << (count << 1); count += 1; }
        if ((flags & ImGuiTableColumnFlags_PreferSortDescending) != 0 && (flags & ImGuiTableColumnFlags_NoSortDescending) == 0) { mask |= 1 << ImGuiSortDirection_Descending; list |= ImGuiSortDirection_Descending << (count << 1); count += 1; }
        if ((flags & ImGuiTableColumnFlags_PreferSortAscending)  == 0 && (flags & ImGuiTableColumnFlags_NoSortAscending)  == 0) { mask |= 1 << ImGuiSortDirection_Ascending;  list |= ImGuiSortDirection_Ascending  << (count << 1); count += 1; }
        if ((flags & ImGuiTableColumnFlags_PreferSortDescending) == 0 && (flags & ImGuiTableColumnFlags_NoSortDescending) == 0) { mask |= 1 << ImGuiSortDirection_Descending; list |= ImGuiSortDirection_Descending << (count << 1); count += 1; }
        if ((table.Flags & ImGuiTableFlags_SortTristate) || count == 0) { mask |= 1 << ImGuiSortDirection_None; count += 1; }
        column.SortDirectionsAvailList = cast(as) (as) 
        column.SortDirectionsAvailMask = cast(as) (as) 
        column.SortDirectionsAvailCount = cast(as) (as) (
        TableFixColumnSortDirection(table, column);
    }
}

// Layout columns for the frame. This is in essence the followup to BeginTable() and this is our largest function.
// Runs on the first call to TableNextRow(), to give a chance for TableSetupColumn() and other TableSetupXXXXX() functions to be called first.
// FIXME-TABLE: Our width (and therefore our WorkRect) will be minimal in the first frame for _WidthAuto columns.
// Increase feedback side-effect with widgets relying on WorkRect.Max.x... Maybe provide a default distribution for _WidthAuto columns?
TableUpdateLayout :: proc(table : ^ImGuiTable)
{
    g := GImGui;
    assert(table.IsLayoutLocked == false);

    table_sizing_policy := (table.Flags & ImGuiTableFlags_SizingMask_);
    table.IsDefaultDisplayOrder = true;
    table.ColumnsEnabledCount = 0;
    ImBitArrayClearAllBits(table.EnabledMaskByIndex, table.ColumnsCount);
    ImBitArrayClearAllBits(table.EnabledMaskByDisplayOrder, table.ColumnsCount);
    table.LeftMostEnabledColumn = -1;
    table.MinColumnWidth = ImMax(1.0, g.Style.FramePadding.x * 1.0); // g.Style.ColumnsMinSpacing; // FIXME-TABLE

    // [Part 1] Apply/lock Enabled and Order states. Calculate auto/ideal width for columns. Count fixed/stretch columns.
    // Process columns in their visible orders as we are building the Prev/Next indices.
    count_fixed := 0;                // Number of columns that have fixed sizing policies
    count_stretch := 0;              // Number of columns that have stretch sizing policies
    prev_visible_column_idx := -1;
    has_auto_fit_request := false;
    has_resizable := false;
    stretch_sum_width_auto := 0.0;
    fixed_max_width_auto := 0.0;
    for i32 order_n = 0; order_n < table.ColumnsCount; order_n++
    {
        column_n := table.DisplayOrderToIndex[order_n];
        if (column_n != order_n)
            table.IsDefaultDisplayOrder = false;
        column := &table.Columns[column_n];

        // Clear column setup if not submitted by user. Currently we make it mandatory to call TableSetupColumn() every frame.
        // It would easily work without but we're not ready to guarantee it since e.g. names need resubmission anyway.
        // We take a slight shortcut but in theory we could be calling TableSetupColumn() here with dummy values, it should yield the same effect.
        if (table.DeclColumnsCount <= column_n)
        {
            TableSetupColumnFlags(table, column, ImGuiTableColumnFlags_None);
            column.NameOffset = -1;
            column.UserID = 0;
            column.InitStretchWeightOrWidth = -1.0;
        }

        // Update Enabled state, mark settings and sort specs dirty
        if (!(table.Flags & ImGuiTableFlags_Hideable) || (column.Flags & ImGuiTableColumnFlags_NoHide))
            column.IsUserEnabledNextFrame = true;
        if (column.IsUserEnabled != column.IsUserEnabledNextFrame)
        {
            column.IsUserEnabled = column.IsUserEnabledNextFrame;
            table.IsSettingsDirty = true;
        }
        column.IsEnabled = column.IsUserEnabled && (column.Flags & ImGuiTableColumnFlags_Disabled) == 0;

        if (column.SortOrder != -1 && !column.IsEnabled)
            table.IsSortSpecsDirty = true;
        if (column.SortOrder > 0 && !(table.Flags & ImGuiTableFlags_SortMulti))
            table.IsSortSpecsDirty = true;

        // Auto-fit unsized columns
        start_auto_fit := (column.Flags & ImGuiTableColumnFlags_WidthFixed) ? (column.WidthRequest < 0.0) : (column.StretchWeight < 0.0);
        if (start_auto_fit)
            column.AutoFitQueue = column.CannotSkipItemsQueue = (1 << 3) - 1; // Fit for three frames

        if (!column.IsEnabled)
        {
            column.IndexWithinEnabledSet = -1;
            continue;
        }

        // Mark as enabled and link to previous/next enabled column
        column.PrevEnabledColumn = (ImGuiTableColumnIdx)prev_visible_column_idx;
        column.NextEnabledColumn = -1;
        if (prev_visible_column_idx != -1)
            table.Columns[prev_visible_column_idx].NextEnabledColumn = (ImGuiTableColumnIdx)column_n;
        else
            table.LeftMostEnabledColumn = (ImGuiTableColumnIdx)column_n;
        column.IndexWithinEnabledSet = table.ColumnsEnabledCount += 1;
        ImBitArraySetBit(table.EnabledMaskByIndex, column_n);
        ImBitArraySetBit(table.EnabledMaskByDisplayOrder, column.DisplayOrder);
        prev_visible_column_idx = column_n;
        assert(column.IndexWithinEnabledSet <= column.DisplayOrder);

        // Calculate ideal/auto column width (that's the width required for all contents to be visible without clipping)
        // Combine width from regular rows + width from headers unless requested not to.
        if (!column.IsPreserveWidthAuto && table.InstanceCurrent == 0)
            column.WidthAuto = TableGetColumnWidthAuto(table, column);

        // Non-resizable columns keep their requested width (apply user value regardless of IsPreserveWidthAuto)
        column_is_resizable := (column.Flags & ImGuiTableColumnFlags_NoResize) == 0;
        if (column_is_resizable)
            has_resizable = true;
        if ((column.Flags & ImGuiTableColumnFlags_WidthFixed) && column.InitStretchWeightOrWidth > 0.0 && !column_is_resizable)
            column.WidthAuto = column.InitStretchWeightOrWidth;

        if (column.AutoFitQueue != 0x00)
            has_auto_fit_request = true;
        if (column.Flags & ImGuiTableColumnFlags_WidthStretch)
        {
            stretch_sum_width_auto += column.WidthAuto;
            count_stretch += 1;
        }
        else
        {
            fixed_max_width_auto = ImMax(fixed_max_width_auto, column.WidthAuto);
            count_fixed += 1;
        }
    }
    if ((table.Flags & ImGuiTableFlags_Sortable) && table.SortSpecsCount == 0 && !(table.Flags & ImGuiTableFlags_SortTristate))
        table.IsSortSpecsDirty = true;
    table.RightMostEnabledColumn = (ImGuiTableColumnIdx)prev_visible_column_idx;
    assert(table.LeftMostEnabledColumn >= 0 && table.RightMostEnabledColumn >= 0);

    // [Part 2] Disable child window clipping while fitting columns. This is not strictly necessary but makes it possible to avoid
    // the column fitting having to wait until the first visible frame of the child container (may or not be a good thing). Also see #6510.
    // FIXME-TABLE: for always auto-resizing columns may not want to do that all the time.
    if (has_auto_fit_request && table.OuterWindow != table.InnerWindow)
        table.InnerWindow->SkipItems = false;
    if (has_auto_fit_request)
        table.IsSettingsDirty = true;

    // [Part 3] Fix column flags and record a few extra information.
    sum_width_requests := 0.0;    // Sum of all width for fixed and auto-resize columns, excluding width contributed by Stretch columns but including spacing/padding.
    stretch_sum_weights := 0.0;   // Sum of all weights for stretch columns.
    table.LeftMostStretchedColumn = table.RightMostStretchedColumn = -1;
    for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
    {
        if (!IM_BITARRAY_TESTBIT(table.EnabledMaskByIndex, column_n))
            continue;
        column := &table.Columns[column_n];

        column_is_resizable := (column.Flags & ImGuiTableColumnFlags_NoResize) == 0;
        if (column.Flags & ImGuiTableColumnFlags_WidthFixed)
        {
            // Apply same widths policy
            width_auto := column.WidthAuto;
            if (table_sizing_policy == ImGuiTableFlags_SizingFixedSame && (column.AutoFitQueue != 0x00 || !column_is_resizable))
                width_auto = fixed_max_width_auto;

            // Apply automatic width
            // Latch initial size for fixed columns and update it constantly for auto-resizing column (unless clipped!)
            if (column.AutoFitQueue != 0x00)
                column.WidthRequest = width_auto;
            else if ((column.Flags & ImGuiTableColumnFlags_WidthFixed) && !column_is_resizable && column.IsRequestOutput)
                column.WidthRequest = width_auto;

            // FIXME-TABLE: Increase minimum size during init frame to avoid biasing auto-fitting widgets
            // (e.g. TextWrapped) too much. Otherwise what tends to happen is that TextWrapped would output a very
            // large height (= first frame scrollbar display very off + clipper would skip lots of items).
            // This is merely making the side-effect less extreme, but doesn't properly fixes it.
            // FIXME: Move this to ->WidthGiven to avoid temporary lossyless?
            // FIXME: This break IsPreserveWidthAuto from not flickering if the stored WidthAuto was smaller.
            if (column.AutoFitQueue > 0x01 && table.IsInitializing && !column.IsPreserveWidthAuto)
                column.WidthRequest = ImMax(column.WidthRequest, table.MinColumnWidth * 4.0); // FIXME-TABLE: Another constant/scale?
            sum_width_requests += column.WidthRequest;
        }
        else
        {
            // Initialize stretch weight
            if (column.AutoFitQueue != 0x00 || column.StretchWeight < 0.0 || !column_is_resizable)
            {
                if (column.InitStretchWeightOrWidth > 0.0)
                    column.StretchWeight = column.InitStretchWeightOrWidth;
                else if (table_sizing_policy == ImGuiTableFlags_SizingStretchProp)
                    column.StretchWeight = (column.WidthAuto / stretch_sum_width_auto) * count_stretch;
                else
                    column.StretchWeight = 1.0;
            }

            stretch_sum_weights += column.StretchWeight;
            if (table.LeftMostStretchedColumn == -1 || table.Columns[table.LeftMostStretchedColumn].DisplayOrder > column.DisplayOrder)
                table.LeftMostStretchedColumn = (ImGuiTableColumnIdx)column_n;
            if (table.RightMostStretchedColumn == -1 || table.Columns[table.RightMostStretchedColumn].DisplayOrder < column.DisplayOrder)
                table.RightMostStretchedColumn = (ImGuiTableColumnIdx)column_n;
        }
        column.IsPreserveWidthAuto = false;
        sum_width_requests += table.CellPaddingX * 2.0;
    }
    table.ColumnsEnabledFixedCount = (ImGuiTableColumnIdx)count_fixed;
    table.ColumnsStretchSumWeights = stretch_sum_weights;

    // [Part 4] Apply final widths based on requested widths
    work_rect := table.WorkRect;
    width_spacings := (table.OuterPaddingX * 2.0) + (table.CellSpacingX1 + table.CellSpacingX2) * (table.ColumnsEnabledCount - 1);
    width_removed := (table.HasScrollbarYPrev && !table.InnerWindow->ScrollbarY) ? g.Style.ScrollbarSize : 0.0; // To synchronize decoration width of synched tables with mismatching scrollbar state (#5920)
    width_avail := ImMax(1.0, (((table.Flags & ImGuiTableFlags_ScrollX) && table.InnerWidth == 0.0) ? table.InnerClipRect.GetWidth() : work_rect.GetWidth()) - width_removed);
    width_avail_for_stretched_columns := width_avail - width_spacings - sum_width_requests;
    width_remaining_for_stretched_columns := width_avail_for_stretched_columns;
    table.ColumnsGivenWidth = width_spacings + (table.CellPaddingX * 2.0) * table.ColumnsEnabledCount;
    for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
    {
        if (!IM_BITARRAY_TESTBIT(table.EnabledMaskByIndex, column_n))
            continue;
        column := &table.Columns[column_n];

        // Allocate width for stretched/weighted columns (StretchWeight gets converted into WidthRequest)
        if (column.Flags & ImGuiTableColumnFlags_WidthStretch)
        {
            weight_ratio := column.StretchWeight / stretch_sum_weights;
            column.WidthRequest = math.trunc(ImMax(width_avail_for_stretched_columns * weight_ratio, table.MinColumnWidth) + 0.01);
            width_remaining_for_stretched_columns -= column.WidthRequest;
        }

        // [Resize Rule 1] The right-most Visible column is not resizable if there is at least one Stretch column
        // See additional comments in TableSetColumnWidth().
        if (column.NextEnabledColumn == -1 && table.LeftMostStretchedColumn != -1)
            column.Flags |= ImGuiTableColumnFlags_NoDirectResize_;

        // Assign final width, record width in case we will need to shrink
        column.WidthGiven = ImTrunc(ImMax(column.WidthRequest, table.MinColumnWidth));
        table.ColumnsGivenWidth += column.WidthGiven;
    }

    // [Part 5] Redistribute stretch remainder width due to rounding (remainder width is < 1.0f * number of Stretch column).
    // Using right-to-left distribution (more likely to match resizing cursor).
    if (width_remaining_for_stretched_columns >= 1.0 && !(table.Flags & ImGuiTableFlags_PreciseWidths))
        for i32 order_n = table.ColumnsCount - 1; stretch_sum_weights > 0.0 && width_remaining_for_stretched_columns >= 1.0 && order_n >= 0; order_n--
        {
            if (!IM_BITARRAY_TESTBIT(table.EnabledMaskByDisplayOrder, order_n))
                continue;
            column := &table.Columns[table.DisplayOrderToIndex[order_n]];
            if (!(column.Flags & ImGuiTableColumnFlags_WidthStretch))
                continue;
            column.WidthRequest += 1.0;
            column.WidthGiven += 1.0;
            width_remaining_for_stretched_columns -= 1.0;
        }

    // Determine if table is hovered which will be used to flag columns as hovered.
    // - In principle we'd like to use the equivalent of IsItemHovered(ImGuiHoveredFlags_AllowWhenBlockedByActiveItem),
    //   but because our item is partially submitted at this point we use ItemHoverable() and a workaround (temporarily
    //   clear ActiveId, which is equivalent to the change provided by _AllowWhenBLockedByActiveItem).
    // - This allows columns to be marked as hovered when e.g. clicking a button inside the column, or using drag and drop.
    table_instance := TableGetInstanceData(table, table.InstanceCurrent);
    table_instance.HoveredRowLast = table_instance.HoveredRowNext;
    table_instance.HoveredRowNext = -1;
    table.HoveredColumnBody = table.HoveredColumnBorder = -1;
    mouse_hit_rect := ImRect(table.OuterRect.Min.x, table.OuterRect.Min.y, table.OuterRect.Max.x, ImMax(table.OuterRect.Max.y, table.OuterRect.Min.y + table_instance.LastOuterHeight));
    backup_active_id := g.ActiveId;
    g.ActiveId = 0;
    is_hovering_table := ItemHoverable(mouse_hit_rect, 0, ImGuiItemFlags_None);
    g.ActiveId = backup_active_id;

    // Determine skewed MousePos.x to support angled headers.
    mouse_skewed_x := g.IO.MousePos.x;
    if (table.AngledHeadersHeight > 0.0)
        if (g.IO.MousePos.y >= table.OuterRect.Min.y && g.IO.MousePos.y <= table.OuterRect.Min.y + table.AngledHeadersHeight)
            mouse_skewed_x += ImTrunc((table.OuterRect.Min.y + table.AngledHeadersHeight - g.IO.MousePos.y) * table.AngledHeadersSlope);

    // [Part 6] Setup final position, offset, skip/clip states and clipping rectangles, detect hovered column
    // Process columns in their visible orders as we are comparing the visible order and adjusting host_clip_rect while looping.
    visible_n := 0;
    has_at_least_one_column_requesting_output := false;
    offset_x_frozen := (table.FreezeColumnsCount > 0);
    offset_x := ((table.FreezeColumnsCount > 0) ? table.OuterRect.Min.x : work_rect.Min.x) + table.OuterPaddingX - table.CellSpacingX1;
    host_clip_rect := table.InnerClipRect;
    //host_clip_rect.Max.x += table->CellPaddingX + table->CellSpacingX2;
    ImBitArrayClearAllBits(table.VisibleMaskByIndex, table.ColumnsCount);
    for i32 order_n = 0; order_n < table.ColumnsCount; order_n++
    {
        column_n := table.DisplayOrderToIndex[order_n];
        column := &table.Columns[column_n];

        column.NavLayerCurrent = (i8)(table.FreezeRowsCount > 0 ? ImGuiNavLayer_Menu : ImGuiNavLayer_Main); // Use Count NOT request so Header line changes layer when frozen

        if (offset_x_frozen && table.FreezeColumnsCount == visible_n)
        {
            offset_x += work_rect.Min.x - table.OuterRect.Min.x;
            offset_x_frozen = false;
        }

        // Clear status flags
        column.Flags &= ~ImGuiTableColumnFlags_StatusMask_;

        if (!IM_BITARRAY_TESTBIT(table.EnabledMaskByDisplayOrder, order_n))
        {
            // Hidden column: clear a few fields and we are done with it for the remainder of the function.
            // We set a zero-width clip rect but set Min.y/Max.y properly to not interfere with the clipper.
            column.MinX = column.MaxX = column.WorkMinX = column.ClipRect.Min.x = column.ClipRect.Max.x = offset_x;
            column.WidthGiven = 0.0;
            column.ClipRect.Min.y = work_rect.Min.y;
            column.ClipRect.Max.y = math.F32_MAX;
            column.ClipRect.ClipWithFull(host_clip_rect);
            column.IsVisibleX = column.IsVisibleY = column.IsRequestOutput = false;
            column.IsSkipItems = true;
            column.ItemWidth = 1.0;
            continue;
        }

        // Lock start position
        column.MinX = offset_x;

        // Lock width based on start position and minimum/maximum width for this position
        column.WidthMax = TableCalcMaxColumnWidth(table, column_n);
        column.WidthGiven = ImMin(column.WidthGiven, column.WidthMax);
        column.WidthGiven = ImMax(column.WidthGiven, ImMin(column.WidthRequest, table.MinColumnWidth));
        column.MaxX = offset_x + column.WidthGiven + table.CellSpacingX1 + table.CellSpacingX2 + table.CellPaddingX * 2.0;

        // Lock other positions
        // - ClipRect.Min.x: Because merging draw commands doesn't compare min boundaries, we make ClipRect.Min.x match left bounds to be consistent regardless of merging.
        // - ClipRect.Max.x: using WorkMaxX instead of MaxX (aka including padding) makes things more consistent when resizing down, tho slightly detrimental to visibility in very-small column.
        // - ClipRect.Max.x: using MaxX makes it easier for header to receive hover highlight with no discontinuity and display sorting arrow.
        // - FIXME-TABLE: We want equal width columns to have equal (ClipRect.Max.x - WorkMinX) width, which means ClipRect.max.x cannot stray off host_clip_rect.Max.x else right-most column may appear shorter.
        previous_instance_work_min_x := column.WorkMinX;
        column.WorkMinX = column.MinX + table.CellPaddingX + table.CellSpacingX1;
        column.WorkMaxX = column.MaxX - table.CellPaddingX - table.CellSpacingX2; // Expected max
        column.ItemWidth = ImTrunc(column.WidthGiven * 0.65);
        column.ClipRect.Min.x = column.MinX;
        column.ClipRect.Min.y = work_rect.Min.y;
        column.ClipRect.Max.x = column.MaxX; //column->WorkMaxX;
        column.ClipRect.Max.y = math.F32_MAX;
        column.ClipRect.ClipWithFull(host_clip_rect);

        // Mark column as Clipped (not in sight)
        // Note that scrolling tables (where inner_window != outer_window) handle Y clipped earlier in BeginTable() so IsVisibleY really only applies to non-scrolling tables.
        // FIXME-TABLE: Because InnerClipRect.Max.y is conservatively ==outer_window->ClipRect.Max.y, we never can mark columns _Above_ the scroll line as not IsVisibleY.
        // Taking advantage of LastOuterHeight would yield good results there...
        // FIXME-TABLE: Y clipping is disabled because it effectively means not submitting will reduce contents width which is fed to outer_window->DC.CursorMaxPos.x,
        // and this may be used (e.g. typically by outer_window using AlwaysAutoResize or outer_window's horizontal scrollbar, but could be something else).
        // Possible solution to preserve last known content width for clipped column. Test 'table_reported_size' fails when enabling Y clipping and window is resized small.
        column.IsVisibleX = (column.ClipRect.Max.x > column.ClipRect.Min.x);
        column.IsVisibleY = true; // (column->ClipRect.Max.y > column->ClipRect.Min.y);
        is_visible := column.IsVisibleX; //&& column->IsVisibleY;
        if (is_visible)
            ImBitArraySetBit(table.VisibleMaskByIndex, column_n);

        // Mark column as requesting output from user. Note that fixed + non-resizable sets are auto-fitting at all times and therefore always request output.
        column.IsRequestOutput = is_visible || column.AutoFitQueue != 0 || column.CannotSkipItemsQueue != 0;

        // Mark column as SkipItems (ignoring all items/layout)
        // (table->HostSkipItems is a copy of inner_window->SkipItems before we cleared it above in Part 2)
        column.IsSkipItems = !column.IsEnabled || table.HostSkipItems;
        if (column.IsSkipItems)
            assert(!is_visible);
        if (column.IsRequestOutput && !column.IsSkipItems)
            has_at_least_one_column_requesting_output = true;

        // Update status flags
        column.Flags |= ImGuiTableColumnFlags_IsEnabled;
        if (is_visible)
            column.Flags |= ImGuiTableColumnFlags_IsVisible;
        if (column.SortOrder != -1)
            column.Flags |= ImGuiTableColumnFlags_IsSorted;

        // Detect hovered column
        if (is_hovering_table && mouse_skewed_x >= column.ClipRect.Min.x && mouse_skewed_x < column.ClipRect.Max.x)
        {
            column.Flags |= ImGuiTableColumnFlags_IsHovered;
            table.HoveredColumnBody = (ImGuiTableColumnIdx)column_n;
        }

        // Alignment
        // FIXME-TABLE: This align based on the whole column width, not per-cell, and therefore isn't useful in
        // many cases (to be able to honor this we might be able to store a log of cells width, per row, for
        // visible rows, but nav/programmatic scroll would have visible artifacts.)
        //if (column->Flags & ImGuiTableColumnFlags_AlignRight)
        //    column->WorkMinX = ImMax(column->WorkMinX, column->MaxX - column->ContentWidthRowsUnfrozen);
        //else if (column->Flags & ImGuiTableColumnFlags_AlignCenter)
        //    column->WorkMinX = ImLerp(column->WorkMinX, ImMax(column->StartX, column->MaxX - column->ContentWidthRowsUnfrozen), 0.5f);

        // Reset content width variables
        if (table.InstanceCurrent == 0)
        {
            column.ContentMaxXFrozen = column.WorkMinX;
            column.ContentMaxXUnfrozen = column.WorkMinX;
            column.ContentMaxXHeadersUsed = column.WorkMinX;
            column.ContentMaxXHeadersIdeal = column.WorkMinX;
        }
        else
        {
            // As we store an absolute value to make per-cell updates faster, we need to offset values used for width computation.
            offset_from_previous_instance := column.WorkMinX - previous_instance_work_min_x;
            column.ContentMaxXFrozen += offset_from_previous_instance;
            column.ContentMaxXUnfrozen += offset_from_previous_instance;
            column.ContentMaxXHeadersUsed += offset_from_previous_instance;
            column.ContentMaxXHeadersIdeal += offset_from_previous_instance;
        }

        // Don't decrement auto-fit counters until container window got a chance to submit its items
        if (table.HostSkipItems == false && table.InstanceCurrent == 0)
        {
            column.AutoFitQueue >>= 1;
            column.CannotSkipItemsQueue >>= 1;
        }

        if (visible_n < table.FreezeColumnsCount)
            host_clip_rect.Min.x = ImClamp(column.MaxX + TABLE_BORDER_SIZE, host_clip_rect.Min.x, host_clip_rect.Max.x);

        offset_x += column.WidthGiven + table.CellSpacingX1 + table.CellSpacingX2 + table.CellPaddingX * 2.0;
        visible_n += 1;
    }

    // In case the table is visible (e.g. decorations) but all columns clipped, we keep a column visible.
    // Else if give no chance to a clipper-savy user to submit rows and therefore total contents height used by scrollbar.
    if (has_at_least_one_column_requesting_output == false)
    {
        table.Columns[table.LeftMostEnabledColumn].IsRequestOutput = true;
        table.Columns[table.LeftMostEnabledColumn].IsSkipItems = false;
    }

    // [Part 7] Detect/store when we are hovering the unused space after the right-most column (so e.g. context menus can react on it)
    // Clear Resizable flag if none of our column are actually resizable (either via an explicit _NoResize flag, either
    // because of using _WidthAuto/_WidthStretch). This will hide the resizing option from the context menu.
    unused_x1 := ImMax(table.WorkRect.Min.x, table.Columns[table.RightMostEnabledColumn].ClipRect.Max.x);
    if (is_hovering_table && table.HoveredColumnBody == -1)
        if (mouse_skewed_x >= unused_x1)
            table.HoveredColumnBody = (ImGuiTableColumnIdx)table.ColumnsCount;
    if (has_resizable == false && (table.Flags & ImGuiTableFlags_Resizable))
        table.Flags &= ~ImGuiTableFlags_Resizable;

    table.IsActiveIdAliveBeforeTable = (g.ActiveIdIsAlive != 0);

    // [Part 8] Lock actual OuterRect/WorkRect right-most position.
    // This is done late to handle the case of fixed-columns tables not claiming more widths that they need.
    // Because of this we are careful with uses of WorkRect and InnerClipRect before this point.
    if (table.RightMostStretchedColumn != -1)
        table.Flags &= ~ImGuiTableFlags_NoHostExtendX;
    if (table.Flags & ImGuiTableFlags_NoHostExtendX)
    {
        table.OuterRect.Max.x = table.WorkRect.Max.x = unused_x1;
        table.InnerClipRect.Max.x = ImMin(table.InnerClipRect.Max.x, unused_x1);
    }
    table.InnerWindow->ParentWorkRect = table.WorkRect;
    table.BorderX1 = table.InnerClipRect.Min.x;
    table.BorderX2 = table.InnerClipRect.Max.x;

    // Setup window's WorkRect.Max.y for GetContentRegionAvail(). Other values will be updated in each TableBeginCell() call.
    window_content_max_y : f32
    if (table.Flags & ImGuiTableFlags_NoHostExtendY)
        window_content_max_y = table.OuterRect.Max.y;
    else
        window_content_max_y = ImMax(table.InnerWindow->ContentRegionRect.Max.y, (table.Flags & ImGuiTableFlags_ScrollY) ? 0.0 : table.OuterRect.Max.y);
    table.InnerWindow->WorkRect.Max.y = ImClamp(window_content_max_y - g.Style.CellPadding.y, table.InnerWindow->WorkRect.Min.y, table.InnerWindow->WorkRect.Max.y);

    // [Part 9] Allocate draw channels and setup background cliprect
    TableSetupDrawChannels(table);

    // [Part 10] Hit testing on borders
    if (table.Flags & ImGuiTableFlags_Resizable)
        TableUpdateBorders(table);
    table_instance.LastTopHeadersRowHeight = 0.0;
    table.IsLayoutLocked = true;
    table.IsUsingHeaders = false;

    // Highlight header
    table.HighlightColumnHeader = -1;
    if (table.IsContextPopupOpen && table.ContextPopupColumn != -1 && table.InstanceInteracted == table.InstanceCurrent)
        table.HighlightColumnHeader = table.ContextPopupColumn;
    else if ((table.Flags & ImGuiTableFlags_HighlightHoveredColumn) && table.HoveredColumnBody != -1 && table.HoveredColumnBody != table.ColumnsCount && table.HoveredColumnBorder == -1)
        if (g.ActiveId == 0 || (table.IsActiveIdInTable || g.DragDropActive))
            table.HighlightColumnHeader = table.HoveredColumnBody;

    // [Part 11] Default context menu
    // - To append to this menu: you can call TableBeginContextMenuPopup()/.../EndPopup().
    // - To modify or replace this: set table->IsContextPopupNoDefaultContents = true, then call TableBeginContextMenuPopup()/.../EndPopup().
    // - You may call TableDrawDefaultContextMenu() with selected flags to display specific sections of the default menu,
    //   e.g. TableDrawDefaultContextMenu(table, table->Flags & ~ImGuiTableFlags_Hideable) will display everything EXCEPT columns visibility options.
    if (table.DisableDefaultContextMenu == false && TableBeginContextMenuPopup(table))
    {
        TableDrawDefaultContextMenu(table, table.Flags);
        EndPopup();
    }

    // [Part 12] Sanitize and build sort specs before we have a chance to use them for display.
    // This path will only be exercised when sort specs are modified before header rows (e.g. init or visibility change)
    if (table.IsSortSpecsDirty && (table.Flags & ImGuiTableFlags_Sortable))
        TableSortSpecsBuild(table);

    // [Part 13] Setup inner window decoration size (for scrolling / nav tracking to properly take account of frozen rows/columns)
    if (table.FreezeColumnsRequest > 0)
        table.InnerWindow->DecoInnerSizeX1 = table.Columns[table.DisplayOrderToIndex[table.FreezeColumnsRequest - 1]].MaxX - table.OuterRect.Min.x;
    if (table.FreezeRowsRequest > 0)
        table.InnerWindow->DecoInnerSizeY1 = table_instance.LastFrozenHeight;
    table_instance.LastFrozenHeight = 0.0;

    // Initial state
    inner_window := table.InnerWindow;
    if (table.Flags & ImGuiTableFlags_NoClip)
        table.DrawSplitter->SetCurrentChannel(inner_window.DrawList, TABLE_DRAW_CHANNEL_NOCLIP);
    else
        inner_window.DrawList->PushClipRect(inner_window.InnerClipRect.Min, inner_window.InnerClipRect.Max, false); // FIXME: use table->InnerClipRect?
}

// Process hit-testing on resizing borders. Actual size change will be applied in EndTable()
// - Set table->HoveredColumnBorder with a short delay/timer to reduce visual feedback noise.
TableUpdateBorders :: proc(table : ^ImGuiTable)
{
    g := GImGui;
    assert(table.Flags & ImGuiTableFlags_Resizable);

    // At this point OuterRect height may be zero or under actual final height, so we rely on temporal coherency and
    // use the final height from last frame. Because this is only affecting _interaction_ with columns, it is not
    // really problematic (whereas the actual visual will be displayed in EndTable() and using the current frame height).
    // Actual columns highlight/render will be performed in EndTable() and not be affected.
    table_instance := TableGetInstanceData(table, table.InstanceCurrent);
    hit_half_width := ImTrunc(TABLE_RESIZE_SEPARATOR_HALF_THICKNESS * g.CurrentDpiScale);
    hit_y1 := (table.FreezeRowsCount >= 1 ? table.OuterRect.Min.y : table.WorkRect.Min.y) + table.AngledHeadersHeight;
    hit_y2_body := ImMax(table.OuterRect.Max.y, hit_y1 + table_instance.LastOuterHeight - table.AngledHeadersHeight);
    hit_y2_head := hit_y1 + table_instance.LastTopHeadersRowHeight;

    for i32 order_n = 0; order_n < table.ColumnsCount; order_n++
    {
        if (!IM_BITARRAY_TESTBIT(table.EnabledMaskByDisplayOrder, order_n))
            continue;

        column_n := table.DisplayOrderToIndex[order_n];
        column := &table.Columns[column_n];
        if (column.Flags & (ImGuiTableColumnFlags_NoResize | ImGuiTableColumnFlags_NoDirectResize_))
            continue;

        // ImGuiTableFlags_NoBordersInBodyUntilResize will be honored in TableDrawBorders()
        border_y2_hit := (table.Flags & ImGuiTableFlags_NoBordersInBody) ? hit_y2_head : hit_y2_body;
        if ((table.Flags & ImGuiTableFlags_NoBordersInBody) && table.IsUsingHeaders == false)
            continue;

        if (!column.IsVisibleX && table.LastResizedColumn != column_n)
            continue;

        column_id := TableGetColumnResizeID(table, column_n, table.InstanceCurrent);
        hit_rect := ImRect(column.MaxX - hit_half_width, hit_y1, column.MaxX + hit_half_width, border_y2_hit);
        ItemAdd(hit_rect, column_id, nil, ImGuiItemFlags_NoNav);
        //GetForegroundDrawList()->AddRect(hit_rect.Min, hit_rect.Max, IM_COL32(255, 0, 0, 100));

        hovered := false, held = false;
        pressed := ButtonBehavior(hit_rect, column_id, &hovered, &held, ImGuiButtonFlags_FlattenChildren | ImGuiButtonFlags_PressedOnClick | ImGuiButtonFlags_PressedOnDoubleClick | ImGuiButtonFlags_NoNavFocus);
        if (pressed && IsMouseDoubleClicked(0))
        {
            TableSetColumnWidthAutoSingle(table, column_n);
            ClearActiveID();
            held = false;
        }
        if (held)
        {
            if (table.LastResizedColumn == -1)
                table.ResizeLockMinContentsX2 = table.RightMostEnabledColumn != -1 ? table.Columns[table.RightMostEnabledColumn].MaxX : -math.F32_MAX;
            table.ResizedColumn = (ImGuiTableColumnIdx)column_n;
            table.InstanceInteracted = table.InstanceCurrent;
        }
        if ((hovered && g.HoveredIdTimer > TABLE_RESIZE_SEPARATOR_FEEDBACK_TIMER) || held)
        {
            table.HoveredColumnBorder = (ImGuiTableColumnIdx)column_n;
            SetMouseCursor(ImGuiMouseCursor_ResizeEW);
        }
    }
}

// [forward declared comment]:
// only call EndTable() if BeginTable() returns true!
EndTable :: proc()
{
    g := GImGui;
    table := g.CurrentTable;
    assert(table != nil, "Only call EndTable() if BeginTable() returns true!");

    // This assert would be very useful to catch a common error... unfortunately it would probably trigger in some
    // cases, and for consistency user may sometimes output empty tables (and still benefit from e.g. outer border)
    //IM_ASSERT(table->IsLayoutLocked && "Table unused: never called TableNextRow(), is that the intent?");

    // If the user never got to call TableNextRow() or TableNextColumn(), we call layout ourselves to ensure all our
    // code paths are consistent (instead of just hoping that TableBegin/TableEnd will work), get borders drawn, etc.
    if (!table.IsLayoutLocked)
        TableUpdateLayout(table);

    flags := table.Flags;
    inner_window := table.InnerWindow;
    outer_window := table.OuterWindow;
    temp_data := table.TempData;
    assert(inner_window == g.CurrentWindow);
    assert(outer_window == inner_window || outer_window == inner_window.ParentWindow);

    if (table.IsInsideRow)
        TableEndRow(table);

    // Context menu in columns body
    if (flags & ImGuiTableFlags_ContextMenuInBody)
        if (table.HoveredColumnBody != -1 && !IsAnyItemHovered() && IsMouseReleased(ImGuiMouseButton_Right))
            TableOpenContextMenu(cast(ast) ast) ast) redColumnBody);

    // Finalize table height
    table_instance := TableGetInstanceData(table, table.InstanceCurrent);
    inner_window.DC.PrevLineSize = temp_data.HostBackupPrevLineSize;
    inner_window.DC.CurrLineSize = temp_data.HostBackupCurrLineSize;
    inner_window.DC.CursorMaxPos = temp_data.HostBackupCursorMaxPos;
    inner_content_max_y := table.RowPosY2;
    assert(table.RowPosY2 == inner_window.DC.CursorPos.y);
    if (inner_window != outer_window)
        inner_window.DC.CursorMaxPos.y = inner_content_max_y;
    else if (!(flags & ImGuiTableFlags_NoHostExtendY))
        table.OuterRect.Max.y = table.InnerRect.Max.y = ImMax(table.OuterRect.Max.y, inner_content_max_y); // Patch OuterRect/InnerRect height
    table.WorkRect.Max.y = ImMax(table.WorkRect.Max.y, table.OuterRect.Max.y);
    table_instance.LastOuterHeight = table.OuterRect.GetHeight();

    // Setup inner scrolling range
    // FIXME: This ideally should be done earlier, in BeginTable() SetNextWindowContentSize call, just like writing to inner_window->DC.CursorMaxPos.y,
    // but since the later is likely to be impossible to do we'd rather update both axises together.
    if (table.Flags & ImGuiTableFlags_ScrollX)
    {
        outer_padding_for_border := (table.Flags & ImGuiTableFlags_BordersOuterV) ? TABLE_BORDER_SIZE : 0.0;
        max_pos_x := table.InnerWindow->DC.CursorMaxPos.x;
        if (table.RightMostEnabledColumn != -1)
            max_pos_x = ImMax(max_pos_x, table.Columns[table.RightMostEnabledColumn].WorkMaxX + table.CellPaddingX + table.OuterPaddingX - outer_padding_for_border);
        if (table.ResizedColumn != -1)
            max_pos_x = ImMax(max_pos_x, table.ResizeLockMinContentsX2);
        table.InnerWindow->DC.CursorMaxPos.x = max_pos_x + table.TempData->AngledHeadersExtraWidth;
    }

    // Pop clipping rect
    if (!(flags & ImGuiTableFlags_NoClip))
        inner_window.DrawList->PopClipRect();
    inner_window.ClipRect = inner_window.DrawList->_ClipRectStack.back();

    // Draw borders
    if ((flags & ImGuiTableFlags_Borders) != 0)
        TableDrawBorders(table);

when 0 {
    // Strip out dummy channel draw calls
    // We have no way to prevent user submitting direct ImDrawList calls into a hidden column (but ImGui:: calls will be clipped out)
    // Pros: remove draw calls which will have no effect. since they'll have zero-size cliprect they may be early out anyway.
    // Cons: making it harder for users watching metrics/debugger to spot the wasted vertices.
    if (table.DummyDrawChannel != (ImGuiTableColumnIdx)-1)
    {
        dummy_channel := &table.DrawSplitter._Channels[table.DummyDrawChannel];
        dummy_channel._CmdBuffer.resize(0);
        dummy_channel._IdxBuffer.resize(0);
    }
}

    // Flatten channels and merge draw calls
    splitter := table.DrawSplitter;
    splitter.SetCurrentChannel(inner_window.DrawList, 0);
    if ((table.Flags & ImGuiTableFlags_NoClip) == 0)
        TableMergeDrawChannels(table);
    splitter.Merge(inner_window.DrawList);

    // Update ColumnsAutoFitWidth to get us ahead for host using our size to auto-resize without waiting for next BeginTable()
    auto_fit_width_for_fixed := 0.0;
    auto_fit_width_for_stretched := 0.0;
    auto_fit_width_for_stretched_min := 0.0;
    for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
        if (IM_BITARRAY_TESTBIT(table.EnabledMaskByIndex, column_n))
        {
            column := &table.Columns[column_n];
            column_width_request := ((column.Flags & ImGuiTableColumnFlags_WidthFixed) && !(column.Flags & ImGuiTableColumnFlags_NoResize)) ? column.WidthRequest : TableGetColumnWidthAuto(table, column);
            if (column.Flags & ImGuiTableColumnFlags_WidthFixed)
                auto_fit_width_for_fixed += column_width_request;
            else
                auto_fit_width_for_stretched += column_width_request;
            if ((column.Flags & ImGuiTableColumnFlags_WidthStretch) && (column.Flags & ImGuiTableColumnFlags_NoResize) != 0)
                auto_fit_width_for_stretched_min = ImMax(auto_fit_width_for_stretched_min, column_width_request / (column.StretchWeight / table.ColumnsStretchSumWeights));
        }
    width_spacings := (table.OuterPaddingX * 2.0) + (table.CellSpacingX1 + table.CellSpacingX2) * (table.ColumnsEnabledCount - 1);
    table.ColumnsAutoFitWidth = width_spacings + (table.CellPaddingX * 2.0) * table.ColumnsEnabledCount + auto_fit_width_for_fixed + ImMax(auto_fit_width_for_stretched, auto_fit_width_for_stretched_min);

    // Update scroll
    if ((table.Flags & ImGuiTableFlags_ScrollX) == 0 && inner_window != outer_window)
    {
        inner_window.Scroll.x = 0.0;
    }
    else if (table.LastResizedColumn != -1 && table.ResizedColumn == -1 && inner_window.ScrollbarX && table.InstanceInteracted == table.InstanceCurrent)
    {
        // When releasing a column being resized, scroll to keep the resulting column in sight
        neighbor_width_to_keep_visible := table.MinColumnWidth + table.CellPaddingX * 2.0;
        column := &table.Columns[table.LastResizedColumn];
        if (column.MaxX < table.InnerClipRect.Min.x)
            SetScrollFromPosX(inner_window, column.MaxX - inner_window.Pos.x - neighbor_width_to_keep_visible, 1.0);
        else if (column.MaxX > table.InnerClipRect.Max.x)
            SetScrollFromPosX(inner_window, column.MaxX - inner_window.Pos.x + neighbor_width_to_keep_visible, 1.0);
    }

    // Apply resizing/dragging at the end of the frame
    if (table.ResizedColumn != -1 && table.InstanceCurrent == table.InstanceInteracted)
    {
        column := &table.Columns[table.ResizedColumn];
        new_x2 := (g.IO.MousePos.x - g.ActiveIdClickOffset.x + ImTrunc(TABLE_RESIZE_SEPARATOR_HALF_THICKNESS * g.CurrentDpiScale));
        new_width := ImTrunc(new_x2 - column.MinX - table.CellSpacingX1 - table.CellPaddingX * 2.0);
        table.ResizedColumnNextWidth = new_width;
    }

    table.IsActiveIdInTable = (g.ActiveIdIsAlive != 0 && table.IsActiveIdAliveBeforeTable == false);

    // Pop from id stack
    IM_ASSERT_USER_ERROR(inner_window.IDStack.back() == table_instance.TableInstanceID, "Mismatching PushID/PopID!");
    IM_ASSERT_USER_ERROR(outer_window.DC.ItemWidthStack.Size >= temp_data.HostBackupItemWidthStackSize, "Too many PopItemWidth!");
    if (table.InstanceCurrent > 0)
        PopID();
    PopID();

    // Restore window data that we modified
    backup_outer_max_pos := outer_window.DC.CursorMaxPos;
    inner_window.WorkRect = temp_data.HostBackupWorkRect;
    inner_window.ParentWorkRect = temp_data.HostBackupParentWorkRect;
    inner_window.SkipItems = table.HostSkipItems;
    outer_window.DC.CursorPos = table.OuterRect.Min;
    outer_window.DC.ItemWidth = temp_data.HostBackupItemWidth;
    outer_window.DC.ItemWidthStack.Size = temp_data.HostBackupItemWidthStackSize;
    outer_window.DC.ColumnsOffset = temp_data.HostBackupColumnsOffset;

    // Layout in outer window
    // (FIXME: To allow auto-fit and allow desirable effect of SameLine() we dissociate 'used' vs 'ideal' size by overriding
    // CursorPosPrevLine and CursorMaxPos manually. That should be a more general layout feature, see same problem e.g. #3414)
    if (inner_window != outer_window)
    {
        backup_nav_layers_active_mask := inner_window.DC.NavLayersActiveMask;
        inner_window.DC.NavLayersActiveMask |= 1 << ImGuiNavLayer_Main; // So empty table don't appear to navigate differently.
        g.CurrentTable = nil; // To avoid error recovery recursing
        EndChild();
        g.CurrentTable = table;
        inner_window.DC.NavLayersActiveMask = backup_nav_layers_active_mask;
    }
    else
    {
        ItemSize(table.OuterRect.GetSize());
        ItemAdd(table.OuterRect, 0);
    }

    // Override declared contents width/height to enable auto-resize while not needlessly adding a scrollbar
    if (table.Flags & ImGuiTableFlags_NoHostExtendX)
    {
        // FIXME-TABLE: Could we remove this section?
        // ColumnsAutoFitWidth may be one frame ahead here since for Fixed+NoResize is calculated from latest contents
        assert((table.Flags & ImGuiTableFlags_ScrollX) == 0);
        outer_window.DC.CursorMaxPos.x = ImMax(backup_outer_max_pos.x, table.OuterRect.Min.x + table.ColumnsAutoFitWidth);
    }
    else if (temp_data.UserOuterSize.x <= 0.0)
    {
        // Some references for this: #7651 + tests "table_reported_size", "table_reported_size_outer" equivalent Y block
        // - Checking for ImGuiTableFlags_ScrollX/ScrollY flag makes us a frame ahead when disabling those flags.
        // - FIXME-TABLE: Would make sense to pre-compute expected scrollbar visibility/sizes to generally save a frame of feedback.
        inner_content_max_x := table.OuterRect.Min.x + table.ColumnsAutoFitWidth; // Slightly misleading name but used for code symmetry with inner_content_max_y
        decoration_size := table.TempData->AngledHeadersExtraWidth + ((table.Flags & ImGuiTableFlags_ScrollY) ? inner_window.ScrollbarSizes.x : 0.0);
        outer_window.DC.IdealMaxPos.x = ImMax(outer_window.DC.IdealMaxPos.x, inner_content_max_x + decoration_size - temp_data.UserOuterSize.x);
        outer_window.DC.CursorMaxPos.x = ImMax(backup_outer_max_pos.x, ImMin(table.OuterRect.Max.x, inner_content_max_x + decoration_size));
    }
    else
    {
        outer_window.DC.CursorMaxPos.x = ImMax(backup_outer_max_pos.x, table.OuterRect.Max.x);
    }
    if (temp_data.UserOuterSize.y <= 0.0)
    {
        decoration_size := (table.Flags & ImGuiTableFlags_ScrollX) ? inner_window.ScrollbarSizes.y : 0.0;
        outer_window.DC.IdealMaxPos.y = ImMax(outer_window.DC.IdealMaxPos.y, inner_content_max_y + decoration_size - temp_data.UserOuterSize.y);
        outer_window.DC.CursorMaxPos.y = ImMax(backup_outer_max_pos.y, ImMin(table.OuterRect.Max.y, inner_content_max_y + decoration_size));
    }
    else
    {
        // OuterRect.Max.y may already have been pushed downward from the initial value (unless ImGuiTableFlags_NoHostExtendY is set)
        outer_window.DC.CursorMaxPos.y = ImMax(backup_outer_max_pos.y, table.OuterRect.Max.y);
    }

    // Save settings
    if (table.IsSettingsDirty)
        TableSaveSettings(table);
    table.IsInitializing = false;

    // Clear or restore current table, if any
    assert(g.CurrentWindow == outer_window && g.CurrentTable == table);
    assert(g.TablesTempDataStacked > 0);
    temp_data = (--g.TablesTempDataStacked > 0) ? &g.TablesTempData[g.TablesTempDataStacked - 1] : nil;
    g.CurrentTable = temp_data ? g.Tables.GetByIndex(temp_data.TableIndex) : nil;
    if (g.CurrentTable)
    {
        g.CurrentTable.TempData = temp_data;
        g.CurrentTable.DrawSplitter = &temp_data.DrawSplitter;
    }
    outer_window.DC.CurrentTableIdx = g.CurrentTable ? g.Tables.GetIndex(g.CurrentTable) : -1;
    NavUpdateCurrentWindowIsScrollPushableX();
}

// See "COLUMNS SIZING POLICIES" comments at the top of this file
// If (init_width_or_weight <= 0.0f) it is ignored
TableSetupColumn :: proc(label : ^u8, flags : ImGuiTableColumnFlags = {}, init_width_or_weight : f32 = 0.0, user_id : ImGuiID = 0.0)
{
    g := GImGui;
    table := g.CurrentTable;
    assert(table != nil, "Need to call TableSetupColumn() after BeginTable()!");
    assert(table.IsLayoutLocked == false, "Need to call call TableSetupColumn() before first row!");
    assert((flags & ImGuiTableColumnFlags_StatusMask_) == 0, "Illegal to pass StatusMask values to TableSetupColumn()");
    if (table.DeclColumnsCount >= table.ColumnsCount)
    {
        IM_ASSERT_USER_ERROR(table.DeclColumnsCount < table.ColumnsCount, "Called TableSetupColumn() too many times!");
        return;
    }

    column := &table.Columns[table.DeclColumnsCount];
    table.DeclColumnsCount += 1;

    // Assert when passing a width or weight if policy is entirely left to default, to avoid storing width into weight and vice-versa.
    // Give a grace to users of ImGuiTableFlags_ScrollX.
    if (table.IsDefaultSizingPolicy && (flags & ImGuiTableColumnFlags_WidthMask_) == 0 && (flags & ImGuiTableFlags_ScrollX) == 0)
        assert(init_width_or_weight <= 0.0, "Can only specify width/weight if sizing policy is set explicitly in either Table or Column.");

    // When passing a width automatically enforce WidthFixed policy
    // (whereas TableSetupColumnFlags would default to WidthAuto if table is not Resizable)
    if ((flags & ImGuiTableColumnFlags_WidthMask_) == 0 && init_width_or_weight > 0.0)
        if ((table.Flags & ImGuiTableFlags_SizingMask_) == ImGuiTableFlags_SizingFixedFit || (table.Flags & ImGuiTableFlags_SizingMask_) == ImGuiTableFlags_SizingFixedSame)
            flags |= ImGuiTableColumnFlags_WidthFixed;
    if (flags & ImGuiTableColumnFlags_AngledHeader)
    {
        flags |= ImGuiTableColumnFlags_NoHeaderLabel;
        table.AngledHeadersCount += 1;
    }

    TableSetupColumnFlags(table, column, flags);
    column.UserID = user_id;
    flags = column.Flags;

    // Initialize defaults
    column.InitStretchWeightOrWidth = init_width_or_weight;
    if (table.IsInitializing)
    {
        // Init width or weight
        if (column.WidthRequest < 0.0 && column.StretchWeight < 0.0)
        {
            if ((flags & ImGuiTableColumnFlags_WidthFixed) && init_width_or_weight > 0.0)
                column.WidthRequest = init_width_or_weight;
            if (flags & ImGuiTableColumnFlags_WidthStretch)
                column.StretchWeight = (init_width_or_weight > 0.0) ? init_width_or_weight : -1.0;

            // Disable auto-fit if an explicit width/weight has been specified
            if (init_width_or_weight > 0.0)
                column.AutoFitQueue = 0x00;
        }

        // Init default visibility/sort state
        if ((flags & ImGuiTableColumnFlags_DefaultHide) && (table.SettingsLoadedFlags & ImGuiTableFlags_Hideable) == 0)
            column.IsUserEnabled = column.IsUserEnabledNextFrame = false;
        if (flags & ImGuiTableColumnFlags_DefaultSort && (table.SettingsLoadedFlags & ImGuiTableFlags_Sortable) == 0)
        {
            column.SortOrder = 0; // Multiple columns using _DefaultSort will be reassigned unique SortOrder values when building the sort specs.
            column.SortDirection = (column.Flags & ImGuiTableColumnFlags_PreferSortDescending) ? cast(as) (as) SortDirection_Descendingnding8)(ImGuiSortDirection_Ascending);
        }
    }

    // Store name (append with zero-terminator in contiguous buffer)
    // FIXME: If we recorded the number of \n in names we could compute header row height
    column.NameOffset = -1;
    if (label != nil && label[0] != 0)
    {
        column.NameOffset = cast(ast) ast) ast) mnsNames.size();
        table.ColumnsNames.append(label, label + strlen(label) + 1);
    }
}

// [Public]
// [forward declared comment]:
// lock columns/rows so they stay visible when scrolled.
TableSetupScrollFreeze :: proc(columns : i32, rows : i32)
{
    g := GImGui;
    table := g.CurrentTable;
    assert(table != nil, "Need to call TableSetupColumn() after BeginTable()!");
    assert(table.IsLayoutLocked == false, "Need to call TableSetupColumn() before first row!");
    assert(columns >= 0 && columns < IMGUI_TABLE_MAX_COLUMNS);
    assert(rows >= 0 && rows < 128); // Arbitrary limit

    table.FreezeColumnsRequest = (table.Flags & ImGuiTableFlags_ScrollX) ? (ImGuiTableColumnIdx)ImMin(columns, table.ColumnsCount) : 0;
    table.FreezeColumnsCount = (table.InnerWindow->Scroll.x != 0.0) ? table.FreezeColumnsRequest : 0;
    table.FreezeRowsRequest = (table.Flags & ImGuiTableFlags_ScrollY) ? (ImGuiTableColumnIdx)rows : 0;
    table.FreezeRowsCount = (table.InnerWindow->Scroll.y != 0.0) ? table.FreezeRowsRequest : 0;
    table.IsUnfrozenRows = (table.FreezeRowsCount == 0); // Make sure this is set before TableUpdateLayout() so ImGuiListClipper can benefit from it.b

    // Ensure frozen columns are ordered in their section. We still allow multiple frozen columns to be reordered.
    // FIXME-TABLE: This work for preserving 2143 into 21|43. How about 4321 turning into 21|43? (preserve relative order in each section)
    for i32 column_n = 0; column_n < table.FreezeColumnsRequest; column_n++
    {
        order_n := table.DisplayOrderToIndex[column_n];
        if (order_n != column_n && order_n >= table.FreezeColumnsRequest)
        {
            ImSwap(table.Columns[table.DisplayOrderToIndex[order_n]].DisplayOrder, table.Columns[table.DisplayOrderToIndex[column_n]].DisplayOrder);
            ImSwap(table.DisplayOrderToIndex[order_n], table.DisplayOrderToIndex[column_n]);
        }
    }
}

//-----------------------------------------------------------------------------
// [SECTION] Tables: Simple accessors
//-----------------------------------------------------------------------------
// - TableGetColumnCount()
// - TableGetColumnName()
// - TableGetColumnName() [Internal]
// - TableSetColumnEnabled()
// - TableGetColumnFlags()
// - TableGetCellBgRect() [Internal]
// - TableGetColumnResizeID() [Internal]
// - TableGetHoveredColumn() [Internal]
// - TableGetHoveredRow() [Internal]
// - TableSetBgColor()
//-----------------------------------------------------------------------------

// [forward declared comment]:
// return number of columns (value passed to BeginTable)
TableGetColumnCount :: proc() -> i32
{
    g := GImGui;
    table := g.CurrentTable;
    return table ? table.ColumnsCount : 0;
}

TableGetColumnName :: proc(column_n : i32) -> ^u8
{
    g := GImGui;
    table := g.CurrentTable;
    if (!table)
        return nil;
    if (column_n < 0)
        column_n = table.CurrentColumn;
    return TableGetColumnName(table, column_n);
}

TableGetColumnName :: proc(table : ^ImGuiTable, column_n : i32) -> ^u8
{
    if (table.IsLayoutLocked == false && column_n >= table.DeclColumnsCount)
        return ""; // NameOffset is invalid at this point
    column := &table.Columns[column_n];
    if (column.NameOffset == -1)
        return "";
    return &table.ColumnsNames.Buf[column.NameOffset];
}

// Change user accessible enabled/disabled state of a column (often perceived as "showing/hiding" from users point of view)
// Note that end-user can use the context menu to change this themselves (right-click in headers, or right-click in columns body with ImGuiTableFlags_ContextMenuInBody)
// - Require table to have the ImGuiTableFlags_Hideable flag because we are manipulating user accessible state.
// - Request will be applied during next layout, which happens on the first call to TableNextRow() after BeginTable().
// - For the getter you can test (TableGetColumnFlags() & ImGuiTableColumnFlags_IsEnabled) != 0.
// - Alternative: the ImGuiTableColumnFlags_Disabled is an overriding/master disable flag which will also hide the column from context menu.
// [forward declared comment]:
// change user accessible enabled/disabled state of a column. Set to false to hide the column. User can use the context menu to change this themselves (right-click in headers, or right-click in columns body with ImGuiTableFlags_ContextMenuInBody)
TableSetColumnEnabled :: proc(column_n : i32, enabled : bool)
{
    g := GImGui;
    table := g.CurrentTable;
    assert(table != nil);
    if (!table)
        return;
    assert(table.Flags & ImGuiTableFlags_Hideable); // See comments above
    if (column_n < 0)
        column_n = table.CurrentColumn;
    assert(column_n >= 0 && column_n < table.ColumnsCount);
    column := &table.Columns[column_n];
    column.IsUserEnabledNextFrame = enabled;
}

// We allow querying for an extra column in order to poll the IsHovered state of the right-most section
TableGetColumnFlags := ImGuiTableColumnFlags(i32 column_n)
{
    g := GImGui;
    table := g.CurrentTable;
    if (!table)
        return ImGuiTableColumnFlags_None;
    if (column_n < 0)
        column_n = table.CurrentColumn;
    if (column_n == table.ColumnsCount)
        return (table.HoveredColumnBody == column_n) ? ImGuiTableColumnFlags_IsHovered : ImGuiTableColumnFlags_None;
    return table.Columns[column_n].Flags;
}

// Return the cell rectangle based on currently known height.
// - Important: we generally don't know our row height until the end of the row, so Max.y will be incorrect in many situations.
//   The only case where this is correct is if we provided a min_row_height to TableNextRow() and don't go below it, or in TableEndRow() when we locked that height.
// - Important: if ImGuiTableFlags_PadOuterX is set but ImGuiTableFlags_PadInnerX is not set, the outer-most left and right
//   columns report a small offset so their CellBgRect can extend up to the outer border.
//   FIXME: But the rendering code in TableEndRow() nullifies that with clamping required for scrolling.
TableGetCellBgRect := ImRect(const ImGuiTable* table, i32 column_n)
{
    column := &table.Columns[column_n];
    x1 := column.MinX;
    x2 := column.MaxX;
    //if (column->PrevEnabledColumn == -1)
    //    x1 -= table->OuterPaddingX;
    //if (column->NextEnabledColumn == -1)
    //    x2 += table->OuterPaddingX;
    x1 = ImMax(x1, table.WorkRect.Min.x);
    x2 = ImMin(x2, table.WorkRect.Max.x);
    return ImRect(x1, table.RowPosY1, x2, table.RowPosY2);
}

// Return the resizing ID for the right-side of the given column.
TableGetColumnResizeID := ImGuiID(ImGuiTable* table, i32 column_n, i32 instance_no)
{
    assert(column_n >= 0 && column_n < table.ColumnsCount);
    instance_id := TableGetInstanceID(table, instance_no);
    return instance_id + 1 + column_n; // FIXME: #6140: still not ideal
}

// Return -1 when table is not hovered. return columns_count if hovering the unused space at the right of the right-most visible column.
// [forward declared comment]:
// return hovered column. return -1 when table is not hovered. return columns_count if the unused space at the right of visible columns is hovered. Can also use (TableGetColumnFlags() & ImGuiTableColumnFlags_IsHovered) instead.
TableGetHoveredColumn :: proc() -> i32
{
    g := GImGui;
    table := g.CurrentTable;
    if (!table)
        return -1;
    return cast(ast) ast) ast) redColumnBody;
}

// Return -1 when table is not hovered. Return maxrow+1 if in table but below last submitted row.
// *IMPORTANT* Unlike TableGetHoveredColumn(), this has a one frame latency in updating the value.
// This difference with is the reason why this is not public yet.
// [forward declared comment]:
// Retrieve *PREVIOUS FRAME* hovered row. This difference with TableGetHoveredColumn() is the reason why this is not public yet.
TableGetHoveredRow :: proc() -> i32
{
    g := GImGui;
    table := g.CurrentTable;
    if (!table)
        return -1;
    table_instance := TableGetInstanceData(table, table.InstanceCurrent);
    return cast(ast) ast) _instancetanceredRowLast;
}

// [forward declared comment]:
// change the color of a cell, row, or column. See ImGuiTableBgTarget_ flags for details.
TableSetBgColor :: proc(target : ImGuiTableBgTarget, color : u32, column_n : i32 = -1)
{
    g := GImGui;
    table := g.CurrentTable;
    assert(target != ImGuiTableBgTarget_None);

    if (color == IM_COL32_DISABLE)
        color = 0;

    // We cannot draw neither the cell or row background immediately as we don't know the row height at this point in time.
    switch (target)
    {
    case ImGuiTableBgTarget_CellBg:
    {
        if (table.RowPosY1 > table.InnerClipRect.Max.y) // Discard
            return;
        if (column_n == -1)
            column_n = table.CurrentColumn;
        if (!IM_BITARRAY_TESTBIT(table.VisibleMaskByIndex, column_n))
            return;
        if (table.RowCellDataCurrent < 0 || table.RowCellData[table.RowCellDataCurrent].Column != column_n)
            table.RowCellDataCurrent += 1;
        cell_data := &table.RowCellData[table.RowCellDataCurrent];
        cell_data.BgColor = color;
        cell_data.Column = (ImGuiTableColumnIdx)column_n;
        break;
    }
    case ImGuiTableBgTarget_RowBg0:
    case ImGuiTableBgTarget_RowBg1:
    {
        if (table.RowPosY1 > table.InnerClipRect.Max.y) // Discard
            return;
        assert(column_n == -1);
        bg_idx := (target == ImGuiTableBgTarget_RowBg1) ? 1 : 0;
        table.RowBgColor[bg_idx] = color;
        break;
    }
    case:
        assert(false)
    }
}

//-------------------------------------------------------------------------
// [SECTION] Tables: Row changes
//-------------------------------------------------------------------------
// - TableGetRowIndex()
// - TableNextRow()
// - TableBeginRow() [Internal]
// - TableEndRow() [Internal]
//-------------------------------------------------------------------------

// [Public] Note: for row coloring we use ->RowBgColorCounter which is the same value without counting header rows
// [forward declared comment]:
// return current row index.
TableGetRowIndex :: proc() -> i32
{
    g := GImGui;
    table := g.CurrentTable;
    if (!table)
        return 0;
    return table.CurrentRow;
}

// [Public] Starts into the first cell of a new row
// [forward declared comment]:
// append into the first cell of a new row.
TableNextRow :: proc(row_flags : ImGuiTableRowFlags = {}, row_min_height : f32 = 0.0)
{
    g := GImGui;
    table := g.CurrentTable;

    if (!table.IsLayoutLocked)
        TableUpdateLayout(table);
    if (table.IsInsideRow)
        TableEndRow(table);

    table.LastRowFlags = table.RowFlags;
    table.RowFlags = row_flags;
    table.RowCellPaddingY = g.Style.CellPadding.y;
    table.RowMinHeight = row_min_height;
    TableBeginRow(table);

    // We honor min_row_height requested by user, but cannot guarantee per-row maximum height,
    // because that would essentially require a unique clipping rectangle per-cell.
    table.RowPosY2 += table.RowCellPaddingY * 2.0;
    table.RowPosY2 = ImMax(table.RowPosY2, table.RowPosY1 + row_min_height);

    // Disable output until user calls TableNextColumn()
    table.InnerWindow->SkipItems = true;
}

// [Internal] Only called by TableNextRow()
TableBeginRow :: proc(table : ^ImGuiTable)
{
    window := table.InnerWindow;
    assert(!table.IsInsideRow);

    // New row
    table.CurrentRow += 1;
    table.CurrentColumn = -1;
    table.RowBgColor[0] = table.RowBgColor[1] = IM_COL32_DISABLE;
    table.RowCellDataCurrent = -1;
    table.IsInsideRow = true;

    // Begin frozen rows
    next_y1 := table.RowPosY2;
    if (table.CurrentRow == 0 && table.FreezeRowsCount > 0)
        next_y1 = window.DC.CursorPos.y = table.OuterRect.Min.y;

    table.RowPosY1 = table.RowPosY2 = next_y1;
    table.RowTextBaseline = 0.0;
    table.RowIndentOffsetX = window.DC.Indent.x - table.HostIndentX; // Lock indent

    window.DC.PrevLineTextBaseOffset = 0.0;
    window.DC.CursorPosPrevLine = ImVec2{window.DC.CursorPos.x, window.DC.CursorPos.y + table.RowCellPaddingY}; // This allows users to call SameLine() to share LineSize between columns.
    window.DC.PrevLineSize = window.DC.CurrLineSize = ImVec2{0.0, 0.0}; // This allows users to call SameLine() to share LineSize between columns, and to call it from first column too.
    window.DC.IsSameLine = window.DC.IsSetPos = false;
    window.DC.CursorMaxPos.y = next_y1;

    // Making the header BG color non-transparent will allow us to overlay it multiple times when handling smooth dragging.
    if (table.RowFlags & ImGuiTableRowFlags_Headers)
    {
        TableSetBgColor(ImGuiTableBgTarget_RowBg0, GetColorU32(ImGuiCol_TableHeaderBg));
        if (table.CurrentRow == 0)
            table.IsUsingHeaders = true;
    }
}

// [Internal] Called by TableNextRow()
TableEndRow :: proc(table : ^ImGuiTable)
{
    g := GImGui;
    window := g.CurrentWindow;
    assert(window == table.InnerWindow);
    assert(table.IsInsideRow);

    if (table.CurrentColumn != -1)
        TableEndCell(table);

    // Logging
    if (g.LogEnabled)
        LogRenderedText(nil, "|");

    // Position cursor at the bottom of our row so it can be used for e.g. clipping calculation. However it is
    // likely that the next call to TableBeginCell() will reposition the cursor to take account of vertical padding.
    window.DC.CursorPos.y = table.RowPosY2;

    // Row background fill
    bg_y1 := table.RowPosY1;
    bg_y2 := table.RowPosY2;
    unfreeze_rows_actual := (table.CurrentRow + 1 == table.FreezeRowsCount);
    unfreeze_rows_request := (table.CurrentRow + 1 == table.FreezeRowsRequest);
    table_instance := TableGetInstanceData(table, table.InstanceCurrent);
    if ((table.RowFlags & ImGuiTableRowFlags_Headers) && (table.CurrentRow == 0 || (table.LastRowFlags & ImGuiTableRowFlags_Headers)))
        table_instance.LastTopHeadersRowHeight += bg_y2 - bg_y1;

    is_visible := (bg_y2 >= table.InnerClipRect.Min.y && bg_y1 <= table.InnerClipRect.Max.y);
    if (is_visible)
    {
        // Update data for TableGetHoveredRow()
        if (table.HoveredColumnBody != -1 && g.IO.MousePos.y >= bg_y1 && g.IO.MousePos.y < bg_y2 && table_instance.HoveredRowNext < 0)
            table_instance.HoveredRowNext = table.CurrentRow;

        // Decide of background color for the row
        bg_col0 := 0;
        bg_col1 := 0;
        if (table.RowBgColor[0] != IM_COL32_DISABLE)
            bg_col0 = table.RowBgColor[0];
        else if (table.Flags & ImGuiTableFlags_RowBg)
            bg_col0 = GetColorU32((table.RowBgColorCounter & 1) ? ImGuiCol_TableRowBgAlt : ImGuiCol_TableRowBg);
        if (table.RowBgColor[1] != IM_COL32_DISABLE)
            bg_col1 = table.RowBgColor[1];

        // Decide of top border color
        top_border_col := 0;
        border_size := TABLE_BORDER_SIZE;
        if (table.CurrentRow > 0 && (table.Flags & ImGuiTableFlags_BordersInnerH))
            top_border_col = (table.LastRowFlags & ImGuiTableRowFlags_Headers) ? table.BorderColorStrong : table.BorderColorLight;

        draw_cell_bg_color := table.RowCellDataCurrent >= 0;
        draw_strong_bottom_border := unfreeze_rows_actual;
        if ((bg_col0 | bg_col1 | top_border_col) != 0 || draw_strong_bottom_border || draw_cell_bg_color)
        {
            // In theory we could call SetWindowClipRectBeforeSetChannel() but since we know TableEndRow() is
            // always followed by a change of clipping rectangle we perform the smallest overwrite possible here.
            if ((table.Flags & ImGuiTableFlags_NoClip) == 0)
                window.DrawList->_CmdHeader.ClipRect = table.Bg0ClipRectForDrawCmd.ToVec4();
            table.DrawSplitter->SetCurrentChannel(window.DrawList, TABLE_DRAW_CHANNEL_BG0);
        }

        // Draw row background
        // We soft/cpu clip this so all backgrounds and borders can share the same clipping rectangle
        if (bg_col0 || bg_col1)
        {
            row_rect := ImRect(table.WorkRect.Min.x, bg_y1, table.WorkRect.Max.x, bg_y2);
            row_rect.ClipWith(table.BgClipRect);
            if (bg_col0 != 0 && row_rect.Min.y < row_rect.Max.y)
                window.DrawList->AddRectFilled(row_rect.Min, row_rect.Max, bg_col0);
            if (bg_col1 != 0 && row_rect.Min.y < row_rect.Max.y)
                window.DrawList->AddRectFilled(row_rect.Min, row_rect.Max, bg_col1);
        }

        // Draw cell background color
        if (draw_cell_bg_color)
        {
            cell_data_end := &table.RowCellData[table.RowCellDataCurrent];
            for ImGuiTableCellData* cell_data = &table.RowCellData[0]; cell_data <= cell_data_end; cell_data++
            {
                // As we render the BG here we need to clip things (for layout we would not)
                // FIXME: This cancels the OuterPadding addition done by TableGetCellBgRect(), need to keep it while rendering correctly while scrolling.
                column := &table.Columns[cell_data.Column];
                cell_bg_rect := TableGetCellBgRect(table, cell_data.Column);
                cell_bg_rect.ClipWith(table.BgClipRect);
                cell_bg_rect.Min.x = ImMax(cell_bg_rect.Min.x, column.ClipRect.Min.x);     // So that first column after frozen one gets clipped when scrolling
                cell_bg_rect.Max.x = ImMin(cell_bg_rect.Max.x, column.MaxX);
                if (cell_bg_rect.Min.y < cell_bg_rect.Max.y)
                    window.DrawList->AddRectFilled(cell_bg_rect.Min, cell_bg_rect.Max, cell_data.BgColor);
            }
        }

        // Draw top border
        if (top_border_col && bg_y1 >= table.BgClipRect.Min.y && bg_y1 < table.BgClipRect.Max.y)
            window.DrawList->AddLine(ImVec2{table.BorderX1, bg_y1}, ImVec2{table.BorderX2, bg_y1}, top_border_col, border_size);

        // Draw bottom border at the row unfreezing mark (always strong)
        if (draw_strong_bottom_border && bg_y2 >= table.BgClipRect.Min.y && bg_y2 < table.BgClipRect.Max.y)
            window.DrawList->AddLine(ImVec2{table.BorderX1, bg_y2}, ImVec2{table.BorderX2, bg_y2}, table.BorderColorStrong, border_size);
    }

    // End frozen rows (when we are past the last frozen row line, teleport cursor and alter clipping rectangle)
    // We need to do that in TableEndRow() instead of TableBeginRow() so the list clipper can mark end of row and
    // get the new cursor position.
    if (unfreeze_rows_request)
    {
        for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
            table.Columns[column_n].NavLayerCurrent = ImGuiNavLayer_Main;
        y0 := ImMax(table.RowPosY2 + 1, table.InnerClipRect.Min.y);
        table_instance.LastFrozenHeight = y0 - table.OuterRect.Min.y;

        if (unfreeze_rows_actual)
        {
            assert(table.IsUnfrozenRows == false);
            table.IsUnfrozenRows = true;

            // BgClipRect starts as table->InnerClipRect, reduce it now and make BgClipRectForDrawCmd == BgClipRect
            table.BgClipRect.Min.y = table.Bg2ClipRectForDrawCmd.Min.y = ImMin(y0, table.InnerClipRect.Max.y);
            table.BgClipRect.Max.y = table.Bg2ClipRectForDrawCmd.Max.y = table.InnerClipRect.Max.y;
            table.Bg2DrawChannelCurrent = table.Bg2DrawChannelUnfrozen;
            assert(table.Bg2ClipRectForDrawCmd.Min.y <= table.Bg2ClipRectForDrawCmd.Max.y);

            row_height := table.RowPosY2 - table.RowPosY1;
            table.RowPosY2 = window.DC.CursorPos.y = table.WorkRect.Min.y + table.RowPosY2 - table.OuterRect.Min.y;
            table.RowPosY1 = table.RowPosY2 - row_height;
            for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
            {
                column := &table.Columns[column_n];
                column.DrawChannelCurrent = column.DrawChannelUnfrozen;
                column.ClipRect.Min.y = table.Bg2ClipRectForDrawCmd.Min.y;
            }

            // Update cliprect ahead of TableBeginCell() so clipper can access to new ClipRect->Min.y
            SetWindowClipRectBeforeSetChannel(window, table.Columns[0].ClipRect);
            table.DrawSplitter->SetCurrentChannel(window.DrawList, table.Columns[0].DrawChannelCurrent);
        }
    }

    if (!(table.RowFlags & ImGuiTableRowFlags_Headers))
        table.RowBgColorCounter += 1;
    table.IsInsideRow = false;
}

//-------------------------------------------------------------------------
// [SECTION] Tables: Columns changes
//-------------------------------------------------------------------------
// - TableGetColumnIndex()
// - TableSetColumnIndex()
// - TableNextColumn()
// - TableBeginCell() [Internal]
// - TableEndCell() [Internal]
//-------------------------------------------------------------------------

// [forward declared comment]:
// return current column index.
TableGetColumnIndex :: proc() -> i32
{
    g := GImGui;
    table := g.CurrentTable;
    if (!table)
        return 0;
    return table.CurrentColumn;
}

// [Public] Append into a specific column
// [forward declared comment]:
// append into the specified column. Return true when column is visible.
TableSetColumnIndex :: proc(column_n : i32) -> bool
{
    g := GImGui;
    table := g.CurrentTable;
    if (!table)
        return false;

    if (table.CurrentColumn != column_n)
    {
        if (table.CurrentColumn != -1)
            TableEndCell(table);
        assert(column_n >= 0 && table.ColumnsCount);
        TableBeginCell(table, column_n);
    }

    // Return whether the column is visible. User may choose to skip submitting items based on this return value,
    // however they shouldn't skip submitting for columns that may have the tallest contribution to row height.
    return table.Columns[column_n].IsRequestOutput;
}

// [Public] Append into the next column, wrap and create a new row when already on last column
// [forward declared comment]:
// append into the next column (or first column of next row if currently in last column). Return true when column is visible.
TableNextColumn :: proc() -> bool
{
    g := GImGui;
    table := g.CurrentTable;
    if (!table)
        return false;

    if (table.IsInsideRow && table.CurrentColumn + 1 < table.ColumnsCount)
    {
        if (table.CurrentColumn != -1)
            TableEndCell(table);
        TableBeginCell(table, table.CurrentColumn + 1);
    }
    else
    {
        TableNextRow();
        TableBeginCell(table, 0);
    }

    // Return whether the column is visible. User may choose to skip submitting items based on this return value,
    // however they shouldn't skip submitting for columns that may have the tallest contribution to row height.
    return table.Columns[table.CurrentColumn].IsRequestOutput;
}


// [Internal] Called by TableSetColumnIndex()/TableNextColumn()
// This is called very frequently, so we need to be mindful of unnecessary overhead.
// FIXME-TABLE FIXME-OPT: Could probably shortcut some things for non-active or clipped columns.
TableBeginCell :: proc(table : ^ImGuiTable, column_n : i32)
{
    g := GImGui;
    column := &table.Columns[column_n];
    window := table.InnerWindow;
    table.CurrentColumn = column_n;

    // Start position is roughly ~~ CellRect.Min + CellPadding + Indent
    start_x := column.WorkMinX;
    if (column.Flags & ImGuiTableColumnFlags_IndentEnable)
        start_x += table.RowIndentOffsetX; // ~~ += window.DC.Indent.x - table->HostIndentX, except we locked it for the row.

    window.DC.CursorPos.x = start_x;
    window.DC.CursorPos.y = table.RowPosY1 + table.RowCellPaddingY;
    window.DC.CursorMaxPos.x = window.DC.CursorPos.x;
    window.DC.ColumnsOffset.x = start_x - window.Pos.x - window.DC.Indent.x; // FIXME-WORKRECT
    window.DC.CursorPosPrevLine.x = window.DC.CursorPos.x; // PrevLine.y is preserved. This allows users to call SameLine() to share LineSize between columns.
    window.DC.CurrLineTextBaseOffset = table.RowTextBaseline;
    window.DC.NavLayerCurrent = (ImGuiNavLayer)column.NavLayerCurrent;

    // Note how WorkRect.Max.y is only set once during layout
    window.WorkRect.Min.y = window.DC.CursorPos.y;
    window.WorkRect.Min.x = column.WorkMinX;
    window.WorkRect.Max.x = column.WorkMaxX;
    window.DC.ItemWidth = column.ItemWidth;

    window.SkipItems = column.IsSkipItems;
    if (column.IsSkipItems)
    {
        g.LastItemData.ID = 0;
        g.LastItemData.StatusFlags = 0;
    }

    if (table.Flags & ImGuiTableFlags_NoClip)
    {
        // FIXME: if we end up drawing all borders/bg in EndTable, could remove this and just assert that channel hasn't changed.
        table.DrawSplitter->SetCurrentChannel(window.DrawList, TABLE_DRAW_CHANNEL_NOCLIP);
        //IM_ASSERT(table->DrawSplitter._Current == TABLE_DRAW_CHANNEL_NOCLIP);
    }
    else
    {
        // FIXME-TABLE: Could avoid this if draw channel is dummy channel?
        SetWindowClipRectBeforeSetChannel(window, column.ClipRect);
        table.DrawSplitter->SetCurrentChannel(window.DrawList, column.DrawChannelCurrent);
    }

    // Logging
    if (g.LogEnabled && !column.IsSkipItems)
    {
        LogRenderedText(&window.DC.CursorPos, "|");
        g.LogLinePosY = math.F32_MAX;
    }
}

// [Internal] Called by TableNextRow()/TableSetColumnIndex()/TableNextColumn()
TableEndCell :: proc(table : ^ImGuiTable)
{
    column := &table.Columns[table.CurrentColumn];
    window := table.InnerWindow;

    if (window.DC.IsSetPos)
        ErrorCheckUsingSetCursorPosToExtendParentBoundaries();

    // Report maximum position so we can infer content size per column.
    p_max_pos_x : ^f32
    if (table.RowFlags & ImGuiTableRowFlags_Headers)
        p_max_pos_x = &column.ContentMaxXHeadersUsed;  // Useful in case user submit contents in header row that is not a TableHeader() call
    else
        p_max_pos_x = table.IsUnfrozenRows ? &column.ContentMaxXUnfrozen : &column.ContentMaxXFrozen;
    p_max_pos_x^ = ImMax(*p_max_pos_x, window.DC.CursorMaxPos.x);
    if (column.IsEnabled)
        table.RowPosY2 = ImMax(table.RowPosY2, window.DC.CursorMaxPos.y + table.RowCellPaddingY);
    column.ItemWidth = window.DC.ItemWidth;

    // Propagate text baseline for the entire row
    // FIXME-TABLE: Here we propagate text baseline from the last line of the cell.. instead of the first one.
    table.RowTextBaseline = ImMax(table.RowTextBaseline, window.DC.PrevLineTextBaseOffset);
}

//-------------------------------------------------------------------------
// [SECTION] Tables: Columns width management
//-------------------------------------------------------------------------
// - TableGetMaxColumnWidth() [Internal]
// - TableGetColumnWidthAuto() [Internal]
// - TableSetColumnWidth()
// - TableSetColumnWidthAutoSingle() [Internal]
// - TableSetColumnWidthAutoAll() [Internal]
// - TableUpdateColumnsWeightFromWidth() [Internal]
//-------------------------------------------------------------------------
// Note that actual columns widths are computed in TableUpdateLayout().
//-------------------------------------------------------------------------

// Maximum column content width given current layout. Use column->MinX so this value differs on a per-column basis.
TableCalcMaxColumnWidth :: proc(table : ^ImGuiTable, column_n : i32) -> f32
{
    column := &table.Columns[column_n];
    max_width := math.F32_MAX;
    min_column_distance := table.MinColumnWidth + table.CellPaddingX * 2.0 + table.CellSpacingX1 + table.CellSpacingX2;
    if (table.Flags & ImGuiTableFlags_ScrollX)
    {
        // Frozen columns can't reach beyond visible width else scrolling will naturally break.
        // (we use DisplayOrder as within a set of multiple frozen column reordering is possible)
        if (column.DisplayOrder < table.FreezeColumnsRequest)
        {
            max_width = (table.InnerClipRect.Max.x - (table.FreezeColumnsRequest - column.DisplayOrder) * min_column_distance) - column.MinX;
            max_width = max_width - table.OuterPaddingX - table.CellPaddingX - table.CellSpacingX2;
        }
    }
    else if ((table.Flags & ImGuiTableFlags_NoKeepColumnsVisible) == 0)
    {
        // If horizontal scrolling if disabled, we apply a final lossless shrinking of columns in order to make
        // sure they are all visible. Because of this we also know that all of the columns will always fit in
        // table->WorkRect and therefore in table->InnerRect (because ScrollX is off)
        // FIXME-TABLE: This is solved incorrectly but also quite a difficult problem to fix as we also want ClipRect width to match.
        // See "table_width_distrib" and "table_width_keep_visible" tests
        max_width = table.WorkRect.Max.x - (table.ColumnsEnabledCount - column.IndexWithinEnabledSet - 1) * min_column_distance - column.MinX;
        //max_width -= table->CellSpacingX1;
        max_width -= table.CellSpacingX2;
        max_width -= table.CellPaddingX * 2.0;
        max_width -= table.OuterPaddingX;
    }
    return max_width;
}

// Note this is meant to be stored in column->WidthAuto, please generally use the WidthAuto field
TableGetColumnWidthAuto :: proc(table : ^ImGuiTable, column : ^ImGuiTableColumn) -> f32
{
    content_width_body := ImMax(column.ContentMaxXFrozen, column.ContentMaxXUnfrozen) - column.WorkMinX;
    content_width_headers := column.ContentMaxXHeadersIdeal - column.WorkMinX;
    width_auto := content_width_body;
    if (!(column.Flags & ImGuiTableColumnFlags_NoHeaderWidth))
        width_auto = ImMax(width_auto, content_width_headers);

    // Non-resizable fixed columns preserve their requested width
    if ((column.Flags & ImGuiTableColumnFlags_WidthFixed) && column.InitStretchWeightOrWidth > 0.0)
        if (!(table.Flags & ImGuiTableFlags_Resizable) || (column.Flags & ImGuiTableColumnFlags_NoResize))
            width_auto = column.InitStretchWeightOrWidth;

    return ImMax(width_auto, table.MinColumnWidth);
}

// 'width' = inner column width, without padding
TableSetColumnWidth :: proc(column_n : i32, width : f32)
{
    g := GImGui;
    table := g.CurrentTable;
    assert(table != nil && table.IsLayoutLocked == false);
    assert(column_n >= 0 && column_n < table.ColumnsCount);
    column_0 := &table.Columns[column_n];
    column_0_width := width;

    // Apply constraints early
    // Compare both requested and actual given width to avoid overwriting requested width when column is stuck (minimum size, bounded)
    assert(table.MinColumnWidth > 0.0);
    min_width := table.MinColumnWidth;
    max_width := ImMax(min_width, column_0.WidthMax); // Don't use TableCalcMaxColumnWidth() here as it would rely on MinX from last instance (#7933)
    column_0_width = ImClamp(column_0_width, min_width, max_width);
    if (column_0.WidthGiven == column_0_width || column_0.WidthRequest == column_0_width)
        return;

    //IMGUI_DEBUG_PRINT("TableSetColumnWidth(%d, %.1f->%.1f)\n", column_0_idx, column_0->WidthGiven, column_0_width);
    column_1 := (column_0.NextEnabledColumn != -1) ? &table.Columns[column_0.NextEnabledColumn] : nil;

    // In this surprisingly not simple because of how we support mixing Fixed and multiple Stretch columns.
    // - All fixed: easy.
    // - All stretch: easy.
    // - One or more fixed + one stretch: easy.
    // - One or more fixed + more than one stretch: tricky.
    // Qt when manual resize is enabled only supports a single _trailing_ stretch column, we support more cases here.

    // When forwarding resize from Wn| to Fn+1| we need to be considerate of the _NoResize flag on Fn+1.
    // FIXME-TABLE: Find a way to rewrite all of this so interactions feel more consistent for the user.
    // Scenarios:
    // - F1 F2 F3  resize from F1| or F2|   --> ok: alter ->WidthRequested of Fixed column. Subsequent columns will be offset.
    // - F1 F2 F3  resize from F3|          --> ok: alter ->WidthRequested of Fixed column. If active, ScrollX extent can be altered.
    // - F1 F2 W3  resize from F1| or F2|   --> ok: alter ->WidthRequested of Fixed column. If active, ScrollX extent can be altered, but it doesn't make much sense as the Stretch column will always be minimal size.
    // - F1 F2 W3  resize from W3|          --> ok: no-op (disabled by Resize Rule 1)
    // - W1 W2 W3  resize from W1| or W2|   --> ok
    // - W1 W2 W3  resize from W3|          --> ok: no-op (disabled by Resize Rule 1)
    // - W1 F2 F3  resize from F3|          --> ok: no-op (disabled by Resize Rule 1)
    // - W1 F2     resize from F2|          --> ok: no-op (disabled by Resize Rule 1)
    // - W1 W2 F3  resize from W1| or W2|   --> ok
    // - W1 F2 W3  resize from W1| or F2|   --> ok
    // - F1 W2 F3  resize from W2|          --> ok
    // - F1 W3 F2  resize from W3|          --> ok
    // - W1 F2 F3  resize from W1|          --> ok: equivalent to resizing |F2. F3 will not move.
    // - W1 F2 F3  resize from F2|          --> ok
    // All resizes from a Wx columns are locking other columns.

    // Possible improvements:
    // - W1 W2 W3  resize W1|               --> to not be stuck, both W2 and W3 would stretch down. Seems possible to fix. Would be most beneficial to simplify resize of all-weighted columns.
    // - W3 F1 F2  resize W3|               --> to not be stuck past F1|, both F1 and F2 would need to stretch down, which would be lossy or ambiguous. Seems hard to fix.

    // [Resize Rule 1] Can't resize from right of right-most visible column if there is any Stretch column. Implemented in TableUpdateLayout().

    // If we have all Fixed columns OR resizing a Fixed column that doesn't come after a Stretch one, we can do an offsetting resize.
    // This is the preferred resize path
    if (column_0.Flags & ImGuiTableColumnFlags_WidthFixed)
        if (!column_1 || table.LeftMostStretchedColumn == -1 || table.Columns[table.LeftMostStretchedColumn].DisplayOrder >= column_0.DisplayOrder)
        {
            column_0.WidthRequest = column_0_width;
            table.IsSettingsDirty = true;
            return;
        }

    // We can also use previous column if there's no next one (this is used when doing an auto-fit on the right-most stretch column)
    if (column_1 == nil)
        column_1 = (column_0.PrevEnabledColumn != -1) ? &table.Columns[column_0.PrevEnabledColumn] : nil;
    if (column_1 == nil)
        return;

    // Resizing from right-side of a Stretch column before a Fixed column forward sizing to left-side of fixed column.
    // (old_a + old_b == new_a + new_b) --> (new_a == old_a + old_b - new_b)
    column_1_width := ImMax(column_1.WidthRequest - (column_0_width - column_0.WidthRequest), min_width);
    column_0_width = column_0.WidthRequest + column_1.WidthRequest - column_1_width;
    assert(column_0_width > 0.0 && column_1_width > 0.0);
    column_0.WidthRequest = column_0_width;
    column_1.WidthRequest = column_1_width;
    if ((column_0.Flags | column_1.Flags) & ImGuiTableColumnFlags_WidthStretch)
        TableUpdateColumnsWeightFromWidth(table);
    table.IsSettingsDirty = true;
}

// Disable clipping then auto-fit, will take 2 frames
// (we don't take a shortcut for unclipped columns to reduce inconsistencies when e.g. resizing multiple columns)
TableSetColumnWidthAutoSingle :: proc(table : ^ImGuiTable, column_n : i32)
{
    // Single auto width uses auto-fit
    column := &table.Columns[column_n];
    if (!column.IsEnabled)
        return;
    column.CannotSkipItemsQueue = (1 << 0);
    table.AutoFitSingleColumn = (ImGuiTableColumnIdx)column_n;
}

TableSetColumnWidthAutoAll :: proc(table : ^ImGuiTable)
{
    for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
    {
        column := &table.Columns[column_n];
        if (!column.IsEnabled && !(column.Flags & ImGuiTableColumnFlags_WidthStretch)) // Cannot reset weight of hidden stretch column
            continue;
        column.CannotSkipItemsQueue = (1 << 0);
        column.AutoFitQueue = (1 << 1);
    }
}

TableUpdateColumnsWeightFromWidth :: proc(table : ^ImGuiTable)
{
    assert(table.LeftMostStretchedColumn != -1 && table.RightMostStretchedColumn != -1);

    // Measure existing quantities
    visible_weight := 0.0;
    visible_width := 0.0;
    for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
    {
        column := &table.Columns[column_n];
        if (!column.IsEnabled || !(column.Flags & ImGuiTableColumnFlags_WidthStretch))
            continue;
        assert(column.StretchWeight > 0.0);
        visible_weight += column.StretchWeight;
        visible_width += column.WidthRequest;
    }
    assert(visible_weight > 0.0 && visible_width > 0.0);

    // Apply new weights
    for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
    {
        column := &table.Columns[column_n];
        if (!column.IsEnabled || !(column.Flags & ImGuiTableColumnFlags_WidthStretch))
            continue;
        column.StretchWeight = (column.WidthRequest / visible_width) * visible_weight;
        assert(column.StretchWeight > 0.0);
    }
}

//-------------------------------------------------------------------------
// [SECTION] Tables: Drawing
//-------------------------------------------------------------------------
// - TablePushBackgroundChannel() [Internal]
// - TablePopBackgroundChannel() [Internal]
// - TableSetupDrawChannels() [Internal]
// - TableMergeDrawChannels() [Internal]
// - TableGetColumnBorderCol() [Internal]
// - TableDrawBorders() [Internal]
//-------------------------------------------------------------------------

// Bg2 is used by Selectable (and possibly other widgets) to render to the background.
// Unlike our Bg0/1 channel which we uses for RowBg/CellBg/Borders and where we guarantee all shapes to be CPU-clipped, the Bg2 channel being widgets-facing will rely on regular ClipRect.
TablePushBackgroundChannel :: proc()
{
    g := GImGui;
    window := g.CurrentWindow;
    table := g.CurrentTable;

    // Optimization: avoid SetCurrentChannel() + PushClipRect()
    table.HostBackupInnerClipRect = window.ClipRect;
    SetWindowClipRectBeforeSetChannel(window, table.Bg2ClipRectForDrawCmd);
    table.DrawSplitter->SetCurrentChannel(window.DrawList, table.Bg2DrawChannelCurrent);
}

TablePopBackgroundChannel :: proc()
{
    g := GImGui;
    window := g.CurrentWindow;
    table := g.CurrentTable;
    column := &table.Columns[table.CurrentColumn];

    // Optimization: avoid PopClipRect() + SetCurrentChannel()
    SetWindowClipRectBeforeSetChannel(window, table.HostBackupInnerClipRect);
    table.DrawSplitter->SetCurrentChannel(window.DrawList, column.DrawChannelCurrent);
}

// Allocate draw channels. Called by TableUpdateLayout()
// - We allocate them following storage order instead of display order so reordering columns won't needlessly
//   increase overall dormant memory cost.
// - We isolate headers draw commands in their own channels instead of just altering clip rects.
//   This is in order to facilitate merging of draw commands.
// - After crossing FreezeRowsCount, all columns see their current draw channel changed to a second set of channels.
// - We only use the dummy draw channel so we can push a null clipping rectangle into it without affecting other
//   channels, while simplifying per-row/per-cell overhead. It will be empty and discarded when merged.
// - We allocate 1 or 2 background draw channels. This is because we know TablePushBackgroundChannel() is only used for
//   horizontal spanning. If we allowed vertical spanning we'd need one background draw channel per merge group (1-4).
// Draw channel allocation (before merging):
// - NoClip                       --> 2+D+1 channels: bg0/1 + bg2 + foreground (same clip rect == always 1 draw call)
// - Clip                         --> 2+D+N channels
// - FreezeRows                   --> 2+D+N*2 (unless scrolling value is zero)
// - FreezeRows || FreezeColunns  --> 3+D+N*2 (unless scrolling value is zero)
// Where D is 1 if any column is clipped or hidden (dummy channel) otherwise 0.
TableSetupDrawChannels :: proc(table : ^ImGuiTable)
{
    freeze_row_multiplier := (table.FreezeRowsCount > 0) ? 2 : 1;
    channels_for_row := (table.Flags & ImGuiTableFlags_NoClip) ? 1 : table.ColumnsEnabledCount;
    channels_for_bg := 1 + 1 * freeze_row_multiplier;
    channels_for_dummy := (table.ColumnsEnabledCount < table.ColumnsCount || (memcmp(table.VisibleMaskByIndex, table.EnabledMaskByIndex, ImBitArrayGetStorageSizeInBytes(table.ColumnsCount)) != 0)) ? +1 : 0;
    channels_total := channels_for_bg + (channels_for_row * freeze_row_multiplier) + channels_for_dummy;
    table.DrawSplitter->Split(table.InnerWindow->DrawList, channels_total);
    table.DummyDrawChannel = (ImGuiTableDrawChannelIdx)((channels_for_dummy > 0) ? channels_total - 1 : -1);
    table.Bg2DrawChannelCurrent = TABLE_DRAW_CHANNEL_BG2_FROZEN;
    table.Bg2DrawChannelUnfrozen = (ImGuiTableDrawChannelIdx)((table.FreezeRowsCount > 0) ? 2 + channels_for_row : TABLE_DRAW_CHANNEL_BG2_FROZEN);

    draw_channel_current := 2;
    for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
    {
        column := &table.Columns[column_n];
        if (column.IsVisibleX && column.IsVisibleY)
        {
            column.DrawChannelFrozen = (ImGuiTableDrawChannelIdx)(draw_channel_current);
            column.DrawChannelUnfrozen = (ImGuiTableDrawChannelIdx)(draw_channel_current + (table.FreezeRowsCount > 0 ? channels_for_row + 1 : 0));
            if (!(table.Flags & ImGuiTableFlags_NoClip))
                draw_channel_current += 1;
        }
        else
        {
            column.DrawChannelFrozen = column.DrawChannelUnfrozen = table.DummyDrawChannel;
        }
        column.DrawChannelCurrent = column.DrawChannelFrozen;
    }

    // Initial draw cmd starts with a BgClipRect that matches the one of its host, to facilitate merge draw commands by default.
    // All our cell highlight are manually clipped with BgClipRect. When unfreezing it will be made smaller to fit scrolling rect.
    // (This technically isn't part of setting up draw channels, but is reasonably related to be done here)
    table.BgClipRect = table.InnerClipRect;
    table.Bg0ClipRectForDrawCmd = table.OuterWindow->ClipRect;
    table.Bg2ClipRectForDrawCmd = table.HostClipRect;
    assert(table.BgClipRect.Min.y <= table.BgClipRect.Max.y);
}

// This function reorder draw channels based on matching clip rectangle, to facilitate merging them. Called by EndTable().
// For simplicity we call it TableMergeDrawChannels() but in fact it only reorder channels + overwrite ClipRect,
// actual merging is done by table->DrawSplitter.Merge() which is called right after TableMergeDrawChannels().
//
// Columns where the contents didn't stray off their local clip rectangle can be merged. To achieve
// this we merge their clip rect and make them contiguous in the channel list, so they can be merged
// by the call to DrawSplitter.Merge() following to the call to this function.
// We reorder draw commands by arranging them into a maximum of 4 distinct groups:
//
//   1 group:               2 groups:              2 groups:              4 groups:
//   [ 0. ] no freeze       [ 0. ] row freeze      [ 01 ] col freeze      [ 01 ] row+col freeze
//   [ .. ]  or no scroll   [ 2. ]  and v-scroll   [ .. ]  and h-scroll   [ 23 ]  and v+h-scroll
//
// Each column itself can use 1 channel (row freeze disabled) or 2 channels (row freeze enabled).
// When the contents of a column didn't stray off its limit, we move its channels into the corresponding group
// based on its position (within frozen rows/columns groups or not).
// At the end of the operation our 1-4 groups will each have a ImDrawCmd using the same ClipRect.
// This function assume that each column are pointing to a distinct draw channel,
// otherwise merge_group->ChannelsCount will not match set bit count of merge_group->ChannelsMask.
//
// Column channels will not be merged into one of the 1-4 groups in the following cases:
// - The contents stray off its clipping rectangle (we only compare the MaxX value, not the MinX value).
//   Direct ImDrawList calls won't be taken into account by default, if you use them make sure the ImGui:: bounds
//   matches, by e.g. calling SetCursorScreenPos().
// - The channel uses more than one draw command itself. We drop all our attempt at merging stuff here..
//   we could do better but it's going to be rare and probably not worth the hassle.
// Columns for which the draw channel(s) haven't been merged with other will use their own ImDrawCmd.
//
// This function is particularly tricky to understand.. take a breath.
TableMergeDrawChannels :: proc(table : ^ImGuiTable)
{
    g := GImGui;
    splitter := table.DrawSplitter;
    has_freeze_v := (table.FreezeRowsCount > 0);
    has_freeze_h := (table.FreezeColumnsCount > 0);
    assert(splitter._Current == 0);

    // Track which groups we are going to attempt to merge, and which channels goes into each group.
    MergeGroup :: struct
    {
        ClipRect : ImRect,
        ChannelsCount := 0;
        ChannelsMask := nil;
    };
    merge_group_mask := 0x00;
    merge_groups : [4]MergeGroup

    // Use a reusable temp buffer for the merge masks as they are dynamically sized.
    max_draw_channels := (4 + table.ColumnsCount * 2);
    size_for_masks_bitarrays_one := cast(ast) ast) ArrayGetStorageSizeInBytesBytesdraw_channels);
    g.TempBuffer.reserve(size_for_masks_bitarrays_one * 5);
    memset(g.TempBuffer.Data, 0, size_for_masks_bitarrays_one * 5);
    for i32 n = 0; n < len(merge_groups); n++
        merge_groups[n].ChannelsMask = (ImBitArrayPtr)(rawptr)(g.TempBuffer.Data + (size_for_masks_bitarrays_one * n));
    remaining_mask := (ImBitArrayPtr)(rawptr)(g.TempBuffer.Data + (size_for_masks_bitarrays_one * 4));

    // 1. Scan channels and take note of those which can be merged
    for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
    {
        if (!IM_BITARRAY_TESTBIT(table.VisibleMaskByIndex, column_n))
            continue;
        column := &table.Columns[column_n];

        merge_group_sub_count := has_freeze_v ? 2 : 1;
        for i32 merge_group_sub_n = 0; merge_group_sub_n < merge_group_sub_count; merge_group_sub_n++
        {
            channel_no := (merge_group_sub_n == 0) ? column.DrawChannelFrozen : column.DrawChannelUnfrozen;

            // Don't attempt to merge if there are multiple draw calls within the column
            src_channel := &splitter._Channels[channel_no];
            if (src_channel._CmdBuffer.Size > 0 && src_channel._CmdBuffer.back().ElemCount == 0 && src_channel._CmdBuffer.back().UserCallback == nil) // Equivalent of PopUnusedDrawCmd()
                src_channel._CmdBuffer.pop_back();
            if (src_channel._CmdBuffer.Size != 1)
                continue;

            // Find out the width of this merge group and check if it will fit in our column
            // (note that we assume that rendering didn't stray on the left direction. we should need a CursorMinPos to detect it)
            if (!(column.Flags & ImGuiTableColumnFlags_NoClip))
            {
                content_max_x : f32
                if (!has_freeze_v)
                    content_max_x = ImMax(column.ContentMaxXUnfrozen, column.ContentMaxXHeadersUsed); // No row freeze
                else if (merge_group_sub_n == 0)
                    content_max_x = ImMax(column.ContentMaxXFrozen, column.ContentMaxXHeadersUsed);   // Row freeze: use width before freeze
                else
                    content_max_x = column.ContentMaxXUnfrozen;                                        // Row freeze: use width after freeze
                if (content_max_x > column.ClipRect.Max.x)
                    continue;
            }

            merge_group_n := (has_freeze_h && column_n < table.FreezeColumnsCount ? 0 : 1) + (has_freeze_v && merge_group_sub_n == 0 ? 0 : 2);
            assert(channel_no < max_draw_channels);
            merge_group := &merge_groups[merge_group_n];
            if (merge_group.ChannelsCount == 0)
                merge_group.ClipRect = ImRect(+math.F32_MAX, +math.F32_MAX, -math.F32_MAX, -math.F32_MAX);
            ImBitArraySetBit(merge_group.ChannelsMask, channel_no);
            merge_group.ChannelsCount += 1;
            merge_group.ClipRect.Add(src_channel._CmdBuffer[0].ClipRect);
            merge_group_mask |= (1 << merge_group_n);
        }

        // Invalidate current draw channel
        // (we don't clear DrawChannelFrozen/DrawChannelUnfrozen solely to facilitate debugging/later inspection of data)
        column.DrawChannelCurrent = (ImGuiTableDrawChannelIdx)-1;
    }

    // [DEBUG] Display merge groups
when 0 {
    if (g.IO.KeyShift)
        for i32 merge_group_n = 0; merge_group_n < len(merge_groups); merge_group_n++
        {
            merge_group := &merge_groups[merge_group_n];
            if (merge_group.ChannelsCount == 0)
                continue;
            buf : [32]u8
            ImFormatString(buf, 32, "MG%d:%d", merge_group_n, merge_group.ChannelsCount);
            text_pos := merge_group.ClipRect.Min + ImVec2{4, 4};
            text_size := CalcTextSize(buf, nil);
            GetForegroundDrawList()->AddRectFilled(text_pos, text_pos + text_size, IM_COL32(0, 0, 0, 255));
            GetForegroundDrawList()->AddText(text_pos, IM_COL32(255, 255, 0, 255), buf, nil);
            GetForegroundDrawList()->AddRect(merge_group.ClipRect.Min, merge_group.ClipRect.Max, IM_COL32(255, 255, 0, 255));
        }
}

    // 2. Rewrite channel list in our preferred order
    if (merge_group_mask != 0)
    {
        // We skip channel 0 (Bg0/Bg1) and 1 (Bg2 frozen) from the shuffling since they won't move - see channels allocation in TableSetupDrawChannels().
        LEADING_DRAW_CHANNELS := 2;
        g.DrawChannelsTempMergeBuffer.resize(splitter._Count - LEADING_DRAW_CHANNELS); // Use shared temporary storage so the allocation gets amortized
        dst_tmp := g.DrawChannelsTempMergeBuffer.Data;
        ImBitArraySetBitRange(remaining_mask, LEADING_DRAW_CHANNELS, splitter._Count);
        ImBitArrayClearBit(remaining_mask, table.Bg2DrawChannelUnfrozen);
        assert(has_freeze_v == false || table.Bg2DrawChannelUnfrozen != TABLE_DRAW_CHANNEL_BG2_FROZEN);
        remaining_count := splitter._Count - (has_freeze_v ? LEADING_DRAW_CHANNELS + 1 : LEADING_DRAW_CHANNELS);
        //ImRect host_rect = (table->InnerWindow == table->OuterWindow) ? table->InnerClipRect : table->HostClipRect;
        host_rect := table.HostClipRect;
        for i32 merge_group_n = 0; merge_group_n < len(merge_groups); merge_group_n++
        {
            if (i32 merge_channels_count = merge_groups[merge_group_n].ChannelsCount)
            {
                merge_group := &merge_groups[merge_group_n];
                merge_clip_rect := merge_group.ClipRect;

                // Extend outer-most clip limits to match those of host, so draw calls can be merged even if
                // outer-most columns have some outer padding offsetting them from their parent ClipRect.
                // The principal cases this is dealing with are:
                // - On a same-window table (not scrolling = single group), all fitting columns ClipRect -> will extend and match host ClipRect -> will merge
                // - Columns can use padding and have left-most ClipRect.Min.x and right-most ClipRect.Max.x != from host ClipRect -> will extend and match host ClipRect -> will merge
                // FIXME-TABLE FIXME-WORKRECT: We are wasting a merge opportunity on tables without scrolling if column doesn't fit
                // within host clip rect, solely because of the half-padding difference between window->WorkRect and window->InnerClipRect.
                if ((merge_group_n & 1) == 0 || !has_freeze_h)
                    merge_clip_rect.Min.x = ImMin(merge_clip_rect.Min.x, host_rect.Min.x);
                if ((merge_group_n & 2) == 0 || !has_freeze_v)
                    merge_clip_rect.Min.y = ImMin(merge_clip_rect.Min.y, host_rect.Min.y);
                if ((merge_group_n & 1) != 0)
                    merge_clip_rect.Max.x = ImMax(merge_clip_rect.Max.x, host_rect.Max.x);
                if ((merge_group_n & 2) != 0 && (table.Flags & ImGuiTableFlags_NoHostExtendY) == 0)
                    merge_clip_rect.Max.y = ImMax(merge_clip_rect.Max.y, host_rect.Max.y);
                //GetForegroundDrawList()->AddRect(merge_group->ClipRect.Min, merge_group->ClipRect.Max, IM_COL32(255, 0, 0, 200), 0.0f, 0, 1.0f); // [DEBUG]
                //GetForegroundDrawList()->AddLine(merge_group->ClipRect.Min, merge_clip_rect.Min, IM_COL32(255, 100, 0, 200));
                //GetForegroundDrawList()->AddLine(merge_group->ClipRect.Max, merge_clip_rect.Max, IM_COL32(255, 100, 0, 200));
                remaining_count -= merge_group.ChannelsCount;
                for i32 n = 0; n < (size_for_masks_bitarrays_one >> 2); n++
                    remaining_mask[n] &= ~merge_group.ChannelsMask[n];
                for i32 n = 0; n < splitter._Count && merge_channels_count != 0; n++
                {
                    // Copy + overwrite new clip rect
                    if (!IM_BITARRAY_TESTBIT(merge_group.ChannelsMask, n))
                        continue;
                    IM_BITARRAY_CLEARBIT(merge_group.ChannelsMask, n);
                    merge_channels_count -= 1;

                    channel := &splitter._Channels[n];
                    assert(channel._CmdBuffer.Size == 1 && merge_clip_rect.Contains(ImRect(channel._CmdBuffer[0].ClipRect)));
                    channel._CmdBuffer[0].ClipRect = merge_clip_rect.ToVec4();
                    memcpy(dst_tmp++, channel, size_of(ImDrawChannel));
                }
            }

            // Make sure Bg2DrawChannelUnfrozen appears in the middle of our groups (whereas Bg0/Bg1 and Bg2 frozen are fixed to 0 and 1)
            if (merge_group_n == 1 && has_freeze_v)
                memcpy(dst_tmp++, &splitter._Channels[table.Bg2DrawChannelUnfrozen], size_of(ImDrawChannel));
        }

        // Append unmergeable channels that we didn't reorder at the end of the list
        for i32 n = 0; n < splitter._Count && remaining_count != 0; n++
        {
            if (!IM_BITARRAY_TESTBIT(remaining_mask, n))
                continue;
            channel := &splitter._Channels[n];
            memcpy(dst_tmp++, channel, size_of(ImDrawChannel));
            remaining_count -= 1;
        }
        assert(dst_tmp == g.DrawChannelsTempMergeBuffer.Data + g.DrawChannelsTempMergeBuffer.Size);
        memcpy(splitter._Channels.Data + LEADING_DRAW_CHANNELS, g.DrawChannelsTempMergeBuffer.Data, (splitter._Count - LEADING_DRAW_CHANNELS) * size_of(ImDrawChannel));
    }
}

TableGetColumnBorderCol :: proc(table : ^ImGuiTable, order_n : i32, column_n : i32) -> u32
{
    is_hovered := (table.HoveredColumnBorder == column_n);
    is_resized := (table.ResizedColumn == column_n) && (table.InstanceInteracted == table.InstanceCurrent);
    is_frozen_separator := (table.FreezeColumnsCount == order_n + 1);
    if (is_resized || is_hovered)
        return GetColorU32(is_resized ? ImGuiCol_SeparatorActive : ImGuiCol_SeparatorHovered);
    if (is_frozen_separator || (table.Flags & (ImGuiTableFlags_NoBordersInBody | ImGuiTableFlags_NoBordersInBodyUntilResize)))
        return table.BorderColorStrong;
    return table.BorderColorLight;
}

// FIXME-TABLE: This is a mess, need to redesign how we render borders (as some are also done in TableEndRow)
TableDrawBorders :: proc(table : ^ImGuiTable)
{
    inner_window := table.InnerWindow;
    if (!table.OuterWindow->ClipRect.Overlaps(table.OuterRect))
        return;

    inner_drawlist := inner_window.DrawList;
    table.DrawSplitter->SetCurrentChannel(inner_drawlist, TABLE_DRAW_CHANNEL_BG0);
    inner_drawlist.PushClipRect(table.Bg0ClipRectForDrawCmd.Min, table.Bg0ClipRectForDrawCmd.Max, false);

    // Draw inner border and resizing feedback
    table_instance := TableGetInstanceData(table, table.InstanceCurrent);
    border_size := TABLE_BORDER_SIZE;
    draw_y1 := ImMax(table.InnerRect.Min.y, (table.FreezeRowsCount >= 1 ? table.InnerRect.Min.y : table.WorkRect.Min.y) + table.AngledHeadersHeight) + ((table.Flags & ImGuiTableFlags_BordersOuterH) ? 1.0 : 0.0);
    draw_y2_body := table.InnerRect.Max.y;
    draw_y2_head := table.IsUsingHeaders ? ImMin(table.InnerRect.Max.y, (table.FreezeRowsCount >= 1 ? table.InnerRect.Min.y : table.WorkRect.Min.y) + table_instance.LastTopHeadersRowHeight) : draw_y1;
    if (table.Flags & ImGuiTableFlags_BordersInnerV)
    {
        for i32 order_n = 0; order_n < table.ColumnsCount; order_n++
        {
            if (!IM_BITARRAY_TESTBIT(table.EnabledMaskByDisplayOrder, order_n))
                continue;

            column_n := table.DisplayOrderToIndex[order_n];
            column := &table.Columns[column_n];
            is_hovered := (table.HoveredColumnBorder == column_n);
            is_resized := (table.ResizedColumn == column_n) && (table.InstanceInteracted == table.InstanceCurrent);
            is_resizable := (column.Flags & (ImGuiTableColumnFlags_NoResize | ImGuiTableColumnFlags_NoDirectResize_)) == 0;
            is_frozen_separator := (table.FreezeColumnsCount == order_n + 1);
            if (column.MaxX > table.InnerClipRect.Max.x && !is_resized)
                continue;

            // Decide whether right-most column is visible
            if (column.NextEnabledColumn == -1 && !is_resizable)
                if ((table.Flags & ImGuiTableFlags_SizingMask_) != ImGuiTableFlags_SizingFixedSame || (table.Flags & ImGuiTableFlags_NoHostExtendX))
                    continue;
            if (column.MaxX <= column.ClipRect.Min.x) // FIXME-TABLE FIXME-STYLE: Assume BorderSize==1, this is problematic if we want to increase the border size..
                continue;

            // Draw in outer window so right-most column won't be clipped
            // Always draw full height border when being resized/hovered, or on the delimitation of frozen column scrolling.
            draw_y2 := (is_hovered || is_resized || is_frozen_separator || (table.Flags & (ImGuiTableFlags_NoBordersInBody | ImGuiTableFlags_NoBordersInBodyUntilResize)) == 0) ? draw_y2_body : draw_y2_head;
            if (draw_y2 > draw_y1)
                inner_drawlist.AddLine(ImVec2{column.MaxX, draw_y1}, ImVec2{column.MaxX, draw_y2}, TableGetColumnBorderCol(table, order_n, column_n), border_size);
        }
    }

    // Draw outer border
    // FIXME: could use AddRect or explicit VLine/HLine helper?
    if (table.Flags & ImGuiTableFlags_BordersOuter)
    {
        // Display outer border offset by 1 which is a simple way to display it without adding an extra draw call
        // (Without the offset, in outer_window it would be rendered behind cells, because child windows are above their
        // parent. In inner_window, it won't reach out over scrollbars. Another weird solution would be to display part
        // of it in inner window, and the part that's over scrollbars in the outer window..)
        // Either solution currently won't allow us to use a larger border size: the border would clipped.
        outer_border := table.OuterRect;
        outer_col := table.BorderColorStrong;
        if ((table.Flags & ImGuiTableFlags_BordersOuter) == ImGuiTableFlags_BordersOuter)
        {
            inner_drawlist.AddRect(outer_border.Min, outer_border.Max, outer_col, 0.0, 0, border_size);
        }
        else if (table.Flags & ImGuiTableFlags_BordersOuterV)
        {
            inner_drawlist.AddLine(outer_border.Min, ImVec2{outer_border.Min.x, outer_border.Max.y}, outer_col, border_size);
            inner_drawlist.AddLine(ImVec2{outer_border.Max.x, outer_border.Min.y}, outer_border.Max, outer_col, border_size);
        }
        else if (table.Flags & ImGuiTableFlags_BordersOuterH)
        {
            inner_drawlist.AddLine(outer_border.Min, ImVec2{outer_border.Max.x, outer_border.Min.y}, outer_col, border_size);
            inner_drawlist.AddLine(ImVec2{outer_border.Min.x, outer_border.Max.y}, outer_border.Max, outer_col, border_size);
        }
    }
    if ((table.Flags & ImGuiTableFlags_BordersInnerH) && table.RowPosY2 < table.OuterRect.Max.y)
    {
        // Draw bottom-most row border between it is above outer border.
        border_y := table.RowPosY2;
        if (border_y >= table.BgClipRect.Min.y && border_y < table.BgClipRect.Max.y)
            inner_drawlist.AddLine(ImVec2{table.BorderX1, border_y}, ImVec2{table.BorderX2, border_y}, table.BorderColorLight, border_size);
    }

    inner_drawlist.PopClipRect();
}

//-------------------------------------------------------------------------
// [SECTION] Tables: Sorting
//-------------------------------------------------------------------------
// - TableGetSortSpecs()
// - TableFixColumnSortDirection() [Internal]
// - TableGetColumnNextSortDirection() [Internal]
// - TableSetColumnSortDirection() [Internal]
// - TableSortSpecsSanitize() [Internal]
// - TableSortSpecsBuild() [Internal]
//-------------------------------------------------------------------------

// Return NULL if no sort specs (most often when ImGuiTableFlags_Sortable is not set)
// When 'sort_specs->SpecsDirty == true' you should sort your data. It will be true when sorting specs have
// changed since last call, or the first time. Make sure to set 'SpecsDirty = false' after sorting,
// else you may wastefully sort your data every frame!
// Lifetime: don't hold on this pointer over multiple frames or past any subsequent call to BeginTable()!
// [forward declared comment]:
// get latest sort specs for the table (NULL if not sorting).  Lifetime: don't hold on this pointer over multiple frames or past any subsequent call to BeginTable().
TableGetSortSpecs :: proc() -> ^ImGuiTableSortSpecs
{
    g := GImGui;
    table := g.CurrentTable;
    assert(table != nil);

    if (!(table.Flags & ImGuiTableFlags_Sortable))
        return nil;

    // Require layout (in case TableHeadersRow() hasn't been called) as it may alter IsSortSpecsDirty in some paths.
    if (!table.IsLayoutLocked)
        TableUpdateLayout(table);

    TableSortSpecsBuild(table);
    return &table.SortSpecs;
}

inline ImGuiSortDirection TableGetColumnAvailSortDirection(ImGuiTableColumn* column, i32 n)
{
    assert(n < column.SortDirectionsAvailCount);
    return (ImGuiSortDirection)((column.SortDirectionsAvailList >> (n << 1)) & 0x03);
}

// Fix sort direction if currently set on a value which is unavailable (e.g. activating NoSortAscending/NoSortDescending)
TableFixColumnSortDirection :: proc(table : ^ImGuiTable, column : ^ImGuiTableColumn)
{
    if (column.SortOrder == -1 || (column.SortDirectionsAvailMask & (1 << column.SortDirection)) != 0)
        return;
    column.SortDirection = cast(as) (as) GetColumnAvailSortDirectionctionmn, 0);
    table.IsSortSpecsDirty = true;
}

// Calculate next sort direction that would be set after clicking the column
// - If the PreferSortDescending flag is set, we will default to a Descending direction on the first click.
// - Note that the PreferSortAscending flag is never checked, it is essentially the default and therefore a no-op.
#assert(ImGuiSortDirection_None == 0 && ImGuiSortDirection_Ascending == 1 && ImGuiSortDirection_Descending == 2);
TableGetColumnNextSortDirection := ImGuiSortDirection(ImGuiTableColumn* column)
{
    assert(column.SortDirectionsAvailCount > 0);
    if (column.SortOrder == -1)
        return TableGetColumnAvailSortDirection(column, 0);
    for i32 n = 0; n < 3; n++
        if (column.SortDirection == TableGetColumnAvailSortDirection(column, n))
            return TableGetColumnAvailSortDirection(column, (n + 1) % column.SortDirectionsAvailCount);
    assert(false)
    return ImGuiSortDirection_None;
}

// Note that the NoSortAscending/NoSortDescending flags are processed in TableSortSpecsSanitize(), and they may change/revert
// the value of SortDirection. We could technically also do it here but it would be unnecessary and duplicate code.
TableSetColumnSortDirection :: proc(column_n : i32, sort_direction : ImGuiSortDirection, append_to_sort_specs : bool)
{
    g := GImGui;
    table := g.CurrentTable;

    if (!(table.Flags & ImGuiTableFlags_SortMulti))
        append_to_sort_specs = false;
    if (!(table.Flags & ImGuiTableFlags_SortTristate))
        assert(sort_direction != ImGuiSortDirection_None);

    sort_order_max := 0;
    if (append_to_sort_specs)
        for i32 other_column_n = 0; other_column_n < table.ColumnsCount; other_column_n++
            sort_order_max = ImMax(sort_order_max, table.Columns[other_column_n].SortOrder);

    column := &table.Columns[column_n];
    column.SortDirection = cast(as) (as) directionc
    if (column.SortDirection == ImGuiSortDirection_None)
        column.SortOrder = -1;
    else if (column.SortOrder == -1 || !append_to_sort_specs)
        column.SortOrder = append_to_sort_specs ? sort_order_max + 1 : 0;

    for i32 other_column_n = 0; other_column_n < table.ColumnsCount; other_column_n++
    {
        other_column := &table.Columns[other_column_n];
        if (other_column != column && !append_to_sort_specs)
            other_column.SortOrder = -1;
        TableFixColumnSortDirection(table, other_column);
    }
    table.IsSettingsDirty = true;
    table.IsSortSpecsDirty = true;
}

TableSortSpecsSanitize :: proc(table : ^ImGuiTable)
{
    assert(table.Flags & ImGuiTableFlags_Sortable);

    // Clear SortOrder from hidden column and verify that there's no gap or duplicate.
    sort_order_count := 0;
    sort_order_mask := 0x00;
    for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
    {
        column := &table.Columns[column_n];
        if (column.SortOrder != -1 && !column.IsEnabled)
            column.SortOrder = -1;
        if (column.SortOrder == -1)
            continue;
        sort_order_count += 1;
        sort_order_mask |= (cast(ast) ast) aolumn.SortOrder);
        assert(sort_order_count < cast(ast) ast) oft) of_order_mask) * 8);
    }

    need_fix_linearize := (cast(ast) ast) aort_order_count) != (sort_order_mask + 1);
    need_fix_single_sort_order := (sort_order_count > 1) && !(table.Flags & ImGuiTableFlags_SortMulti);
    if (need_fix_linearize || need_fix_single_sort_order)
    {
        fixed_mask := 0x00;
        for i32 sort_n = 0; sort_n < sort_order_count; sort_n++
        {
            // Fix: Rewrite sort order fields if needed so they have no gap or duplicate.
            // (e.g. SortOrder 0 disappeared, SortOrder 1..2 exists --> rewrite then as SortOrder 0..1)
            column_with_smallest_sort_order := -1;
            for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
                if ((fixed_mask & (cast(ast) ast) au64)column_n)) == 0 && table.Columns[column_n].SortOrder != -1)
                    if (column_with_smallest_sort_order == -1 || table.Columns[column_n].SortOrder < table.Columns[column_with_smallest_sort_order].SortOrder)
                        column_with_smallest_sort_order = column_n;
            assert(column_with_smallest_sort_order != -1);
            fixed_mask |= (cast(ast) ast) aolumn_with_smallest_sort_order);
            table.Columns[column_with_smallest_sort_order].SortOrder = (ImGuiTableColumnIdx)sort_n;

            // Fix: Make sure only one column has a SortOrder if ImGuiTableFlags_MultiSortable is not set.
            if (need_fix_single_sort_order)
            {
                sort_order_count = 1;
                for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
                    if (column_n != column_with_smallest_sort_order)
                        table.Columns[column_n].SortOrder = -1;
                break;
            }
        }
    }

    // Fallback default sort order (if no column with the ImGuiTableColumnFlags_DefaultSort flag)
    if (sort_order_count == 0 && !(table.Flags & ImGuiTableFlags_SortTristate))
        for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
        {
            column := &table.Columns[column_n];
            if (column.IsEnabled && !(column.Flags & ImGuiTableColumnFlags_NoSort))
            {
                sort_order_count = 1;
                column.SortOrder = 0;
                column.SortDirection = cast(as) (as) GetColumnAvailSortDirectionctionmn, 0);
                break;
            }
        }

    table.SortSpecsCount = (ImGuiTableColumnIdx)sort_order_count;
}

TableSortSpecsBuild :: proc(table : ^ImGuiTable)
{
    dirty := table.IsSortSpecsDirty;
    if (dirty)
    {
        TableSortSpecsSanitize(table);
        table.SortSpecsMulti.resize(table.SortSpecsCount <= 1 ? 0 : table.SortSpecsCount);
        table.SortSpecs.SpecsDirty = true; // Mark as dirty for user
        table.IsSortSpecsDirty = false; // Mark as not dirty for us
    }

    // Write output
    // May be able to move all SortSpecs data from table (48 bytes) to ImGuiTableTempData if we decide to write it back on every BeginTable()
    sort_specs := (table.SortSpecsCount == 0) ? nil : (table.SortSpecsCount == 1) ? &table.SortSpecsSingle : table.SortSpecsMulti.Data;
    if (dirty && sort_specs != nil)
        for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
        {
            column := &table.Columns[column_n];
            if (column.SortOrder == -1)
                continue;
            assert(column.SortOrder < table.SortSpecsCount);
            sort_spec := &sort_specs[column.SortOrder];
            sort_spec.ColumnUserID = column.UserID;
            sort_spec.ColumnIndex = (ImGuiTableColumnIdx)column_n;
            sort_spec.SortOrder = (ImGuiTableColumnIdx)column.SortOrder;
            sort_spec.SortDirection = (ImGuiSortDirection)column.SortDirection;
        }

    table.SortSpecs.Specs = sort_specs;
    table.SortSpecs.SpecsCount = table.SortSpecsCount;
}

//-------------------------------------------------------------------------
// [SECTION] Tables: Headers
//-------------------------------------------------------------------------
// - TableGetHeaderRowHeight() [Internal]
// - TableGetHeaderAngledMaxLabelWidth() [Internal]
// - TableHeadersRow()
// - TableHeader()
// - TableAngledHeadersRow()
// - TableAngledHeadersRowEx() [Internal]
//-------------------------------------------------------------------------

TableGetHeaderRowHeight :: proc() -> f32
{
    // Caring for a minor edge case:
    // Calculate row height, for the unlikely case that some labels may be taller than others.
    // If we didn't do that, uneven header height would highlight but smaller one before the tallest wouldn't catch input for all height.
    // In your custom header row you may omit this all together and just call TableNextRow() without a height...
    g := GImGui;
    table := g.CurrentTable;
    row_height := g.FontSize;
    for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
        if (IM_BITARRAY_TESTBIT(table.EnabledMaskByIndex, column_n))
            if ((table.Columns[column_n].Flags & ImGuiTableColumnFlags_NoHeaderLabel) == 0)
                row_height = ImMax(row_height, CalcTextSize(TableGetColumnName(table, column_n)).y);
    return row_height + g.Style.CellPadding.y * 2.0;
}

TableGetHeaderAngledMaxLabelWidth :: proc() -> f32
{
    g := GImGui;
    table := g.CurrentTable;
    width := 0.0;
    for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
        if (IM_BITARRAY_TESTBIT(table.EnabledMaskByIndex, column_n))
            if (table.Columns[column_n].Flags & ImGuiTableColumnFlags_AngledHeader)
                width = ImMax(width, CalcTextSize(TableGetColumnName(table, column_n), nil, true).x);
    return width + g.Style.CellPadding.y * 2.0; // Swap padding
}

// [Public] This is a helper to output TableHeader() calls based on the column names declared in TableSetupColumn().
// The intent is that advanced users willing to create customized headers would not need to use this helper
// and can create their own! For example: TableHeader() may be preceded by Checkbox() or other custom widgets.
// See 'Demo->Tables->Custom headers' for a demonstration of implementing a custom version of this.
// This code is intentionally written to not make much use of internal functions, to give you better direction
// if you need to write your own.
// FIXME-TABLE: TableOpenContextMenu() and TableGetHeaderRowHeight() are not public.
// [forward declared comment]:
// submit a row with headers cells based on data provided to TableSetupColumn() + submit context menu
TableHeadersRow :: proc()
{
    g := GImGui;
    table := g.CurrentTable;
    assert(table != nil, "Need to call TableHeadersRow() after BeginTable()!");

    // Call layout if not already done. This is automatically done by TableNextRow: we do it here _only_ to make
    // it easier to debug-step in TableUpdateLayout(). Your own version of this function doesn't need this.
    if (!table.IsLayoutLocked)
        TableUpdateLayout(table);

    // Open row
    row_height := TableGetHeaderRowHeight();
    TableNextRow(ImGuiTableRowFlags_Headers, row_height);
    row_y1 := GetCursorScreenPos().y;
    if (table.HostSkipItems) // Merely an optimization, you may skip in your own code.
        return;

    columns_count := TableGetColumnCount();
    for i32 column_n = 0; column_n < columns_count; column_n++
    {
        if (!TableSetColumnIndex(column_n))
            continue;

        // Push an id to allow empty/unnamed headers. This is also idiomatic as it ensure there is a consistent ID path to access columns (for e.g. automation)
        name := (TableGetColumnFlags(column_n) & ImGuiTableColumnFlags_NoHeaderLabel) ? "" : TableGetColumnName(column_n);
        PushID(column_n);
        TableHeader(name);
        PopID();
    }

    // Allow opening popup from the right-most section after the last column.
    mouse_pos := GetMousePos();
    if (IsMouseReleased(1) && TableGetHoveredColumn() == columns_count)
        if (mouse_pos.y >= row_y1 && mouse_pos.y < row_y1 + row_height)
            TableOpenContextMenu(columns_count); // Will open a non-column-specific popup.
}

// Emit a column header (text + optional sort order)
// We cpu-clip text here so that all columns headers can be merged into a same draw call.
// Note that because of how we cpu-clip and display sorting indicators, you _cannot_ use SameLine() after a TableHeader()
// [forward declared comment]:
// submit one header cell manually (rarely used)
TableHeader :: proc(label : ^u8)
{
    g := GImGui;
    window := g.CurrentWindow;
    if (window.SkipItems)
        return;

    table := g.CurrentTable;
    assert(table != nil, "Need to call TableHeader() after BeginTable()!");
    assert(table.CurrentColumn != -1);
    column_n := table.CurrentColumn;
    column := &table.Columns[column_n];

    // Label
    if (label == nil)
        label = "";
    label_end := FindRenderedTextEnd(label);
    label_size := CalcTextSize(label, label_end, true);
    label_pos := window.DC.CursorPos;

    // If we already got a row height, there's use that.
    // FIXME-TABLE: Padding problem if the correct outer-padding CellBgRect strays off our ClipRect?
    cell_r := TableGetCellBgRect(table, column_n);
    label_height := ImMax(label_size.y, table.RowMinHeight - table.RowCellPaddingY * 2.0);

    // Calculate ideal size for sort order arrow
    w_arrow := 0.0;
    w_sort_text := 0.0;
    sort_arrow := false;
    u8 sort_order_suf[4] = "";
    ARROW_SCALE := 0.65;
    if ((table.Flags & ImGuiTableFlags_Sortable) && !(column.Flags & ImGuiTableColumnFlags_NoSort))
    {
        w_arrow = ImTrunc(g.FontSize * ARROW_SCALE + g.Style.FramePadding.x);
        if (column.SortOrder != -1)
            sort_arrow = true;
        if (column.SortOrder > 0)
        {
            ImFormatString(sort_order_suf, len(sort_order_suf), "%d", column.SortOrder + 1);
            w_sort_text = g.Style.ItemInnerSpacing.x + CalcTextSize(sort_order_suf).x;
        }
    }

    // We feed our unclipped width to the column without writing on CursorMaxPos, so that column is still considered for merging.
    max_pos_x := label_pos.x + label_size.x + w_sort_text + w_arrow;
    column.ContentMaxXHeadersUsed = ImMax(column.ContentMaxXHeadersUsed, sort_arrow ? cell_r.Max.x : ImMin(max_pos_x, cell_r.Max.x));
    column.ContentMaxXHeadersIdeal = ImMax(column.ContentMaxXHeadersIdeal, max_pos_x);

    // Keep header highlighted when context menu is open.
    id := window.GetID(label);
    bb := bb := (= (l_r.Min.x, cell_r.Min.y, cell_r.Max.x, ImMax(cell_r.Max.y, cell_r.Min.y + label_height + g.Style.CellPadding.y * 2.0));
    ItemSize(ImVec2{0.0, label_height}); // Don't declare unclipped width, it'll be fed ContentMaxPosHeadersIdeal
    if (!ItemAdd(bb, id))
        return;

    //GetForegroundDrawList()->AddRect(cell_r.Min, cell_r.Max, IM_COL32(255, 0, 0, 255)); // [DEBUG]
    //GetForegroundDrawList()->AddRect(bb.Min, bb.Max, IM_COL32(255, 0, 0, 255)); // [DEBUG]

    // Using AllowOverlap mode because we cover the whole cell, and we want user to be able to submit subsequent items.
    highlight := (table.HighlightColumnHeader == column_n);
    hovered, held : bool
    pressed := ButtonBehavior(bb, id, &hovered, &held, ImGuiButtonFlags_AllowOverlap);
    if (held || hovered || highlight)
    {
        col := GetColorU32(held ? ImGuiCol_HeaderActive : hovered ? ImGuiCol_HeaderHovered : ImGuiCol_Header);
        //RenderFrame(bb.Min, bb.Max, col, false, 0.0f);
        TableSetBgColor(ImGuiTableBgTarget_CellBg, col, table.CurrentColumn);
    }
    else
    {
        // Submit single cell bg color in the case we didn't submit a full header row
        if ((table.RowFlags & ImGuiTableRowFlags_Headers) == 0)
            TableSetBgColor(ImGuiTableBgTarget_CellBg, GetColorU32(ImGuiCol_TableHeaderBg), table.CurrentColumn);
    }
    RenderNavCursor(bb, id, ImGuiNavRenderCursorFlags_Compact | ImGuiNavRenderCursorFlags_NoRounding);
    if (held)
        table.HeldHeaderColumn = (ImGuiTableColumnIdx)column_n;
    window.DC.CursorPos.y -= g.Style.ItemSpacing.y * 0.5;

    // Drag and drop to re-order columns.
    // FIXME-TABLE: Scroll request while reordering a column and it lands out of the scrolling zone.
    if (held && (table.Flags & ImGuiTableFlags_Reorderable) && IsMouseDragging(0) && !g.DragDropActive)
    {
        // While moving a column it will jump on the other side of the mouse, so we also test for MouseDelta.x
        table.ReorderColumn = (ImGuiTableColumnIdx)column_n;
        table.InstanceInteracted = table.InstanceCurrent;

        // We don't reorder: through the frozen<>unfrozen line, or through a column that is marked with ImGuiTableColumnFlags_NoReorder.
        if (g.IO.MouseDelta.x < 0.0 && g.IO.MousePos.x < cell_r.Min.x)
            if (ImGuiTableColumn* prev_column = (column.PrevEnabledColumn != -1) ? &table.Columns[column.PrevEnabledColumn] : nil)
                if (!((column.Flags | prev_column.Flags) & ImGuiTableColumnFlags_NoReorder))
                    if ((column.IndexWithinEnabledSet < table.FreezeColumnsRequest) == (prev_column.IndexWithinEnabledSet < table.FreezeColumnsRequest))
                        table.ReorderColumnDir = -1;
        if (g.IO.MouseDelta.x > 0.0 && g.IO.MousePos.x > cell_r.Max.x)
            if (ImGuiTableColumn* next_column = (column.NextEnabledColumn != -1) ? &table.Columns[column.NextEnabledColumn] : nil)
                if (!((column.Flags | next_column.Flags) & ImGuiTableColumnFlags_NoReorder))
                    if ((column.IndexWithinEnabledSet < table.FreezeColumnsRequest) == (next_column.IndexWithinEnabledSet < table.FreezeColumnsRequest))
                        table.ReorderColumnDir = +1;
    }

    // Sort order arrow
    ellipsis_max := ImMax(cell_r.Max.x - w_arrow - w_sort_text, label_pos.x);
    if ((table.Flags & ImGuiTableFlags_Sortable) && !(column.Flags & ImGuiTableColumnFlags_NoSort))
    {
        if (column.SortOrder != -1)
        {
            x := ImMax(cell_r.Min.x, cell_r.Max.x - w_arrow - w_sort_text);
            y := label_pos.y;
            if (column.SortOrder > 0)
            {
                PushStyleColor(ImGuiCol_Text, GetColorU32(ImGuiCol_Text, 0.70));
                RenderText(ImVec2{x + g.Style.ItemInnerSpacing.x, y}, sort_order_suf);
                PopStyleColor();
                x += w_sort_text;
            }
            RenderArrow(window.DrawList, ImVec2{x, y}, GetColorU32(ImGuiCol_Text), column.SortDirection == ImGuiSortDirection_Ascending ? ImGuiDir_Up : ImGuiDir_Down, ARROW_SCALE);
        }

        // Handle clicking on column header to adjust Sort Order
        if (pressed && table.ReorderColumn != column_n)
        {
            sort_direction := TableGetColumnNextSortDirection(column);
            TableSetColumnSortDirection(column_n, sort_direction, g.IO.KeyShift);
        }
    }

    // Render clipped label. Clipping here ensure that in the majority of situations, all our header cells will
    // be merged into a single draw call.
    //window->DrawList->AddCircleFilled(ImVec2(ellipsis_max, label_pos.y), 40, IM_COL32_WHITE);
    RenderTextEllipsis(window.DrawList, label_pos, ImVec2{ellipsis_max, label_pos.y + label_height + g.Style.FramePadding.y}, ellipsis_max, ellipsis_max, label, label_end, &label_size);

    text_clipped := label_size.x > (ellipsis_max - label_pos.x);
    if (text_clipped && hovered && g.ActiveId == 0)
        SetItemTooltip("%.*s", (i32)(label_end - label), label);

    // We don't use BeginPopupContextItem() because we want the popup to stay up even after the column is hidden
    if (IsMouseReleased(1) && IsItemHovered())
        TableOpenContextMenu(column_n);
}

// Unlike TableHeadersRow() it is not expected that you can reimplement or customize this with custom widgets.
// FIXME: No hit-testing/button on the angled header.
// [forward declared comment]:
// submit a row with angled headers for every column with the ImGuiTableColumnFlags_AngledHeader flag. MUST BE FIRST ROW.
TableAngledHeadersRow :: proc()
{
    g := GImGui;
    table := g.CurrentTable;
    temp_data := table.TempData;
    temp_data.AngledHeadersRequests.resize(0);
    temp_data.AngledHeadersRequests.reserve(table.ColumnsEnabledCount);

    // Which column needs highlight?
    row_id := GetID("##AngledHeaders");
    table_instance := TableGetInstanceData(table, table.InstanceCurrent);
    highlight_column_n := table.HighlightColumnHeader;
    if (highlight_column_n == -1 && table.HoveredColumnBody != -1)
        if (table_instance.HoveredRowLast == 0 && table.HoveredColumnBorder == -1 && (g.ActiveId == 0 || g.ActiveId == row_id || (table.IsActiveIdInTable || g.DragDropActive)))
            highlight_column_n = table.HoveredColumnBody;

    // Build up request
    col_header_bg := GetColorU32(ImGuiCol_TableHeaderBg);
    col_text := GetColorU32(ImGuiCol_Text);
    for i32 order_n = 0; order_n < table.ColumnsCount; order_n++
        if (IM_BITARRAY_TESTBIT(table.EnabledMaskByDisplayOrder, order_n))
        {
            column_n := table.DisplayOrderToIndex[order_n];
            column := &table.Columns[column_n];
            if ((column.Flags & ImGuiTableColumnFlags_AngledHeader) == 0) // Note: can't rely on ImGuiTableColumnFlags_IsVisible test here.
                continue;
            request := { (ImGuiTableColumnIdx)column_n, col_text, col_header_bg, (column_n == highlight_column_n) ? GetColorU32(ImGuiCol_Header) : 0 };
            temp_data.AngledHeadersRequests.push_back(request);
        }

    // Render row
    TableAngledHeadersRowEx(row_id, g.Style.TableAngledHeadersAngle, 0.0, temp_data.AngledHeadersRequests.Data, temp_data.AngledHeadersRequests.Size);
}

// Important: data must be fed left to right
TableAngledHeadersRowEx :: proc(row_id : ImGuiID, angle : f32, max_label_width : f32, data : ^ImGuiTableHeaderData, data_count : i32)
{
    g := GImGui;
    table := g.CurrentTable;
    window := g.CurrentWindow;
    draw_list := window.DrawList;
    assert(table != nil, "Need to call TableHeadersRow() after BeginTable()!");
    assert(table.CurrentRow == -1, "Must be first row");

    if (max_label_width == 0.0)
        max_label_width = TableGetHeaderAngledMaxLabelWidth();

    // Angle argument expressed in (-IM_PI/2 .. +IM_PI/2) as it is easier to think about for user.
    flip_label := (angle < 0.0);
    angle -= IM_PI * 0.5;
    cos_a := ImCos(angle);
    sin_a := ImSin(angle);
    label_cos_a := flip_label ? ImCos(angle + IM_PI) : cos_a;
    label_sin_a := flip_label ? ImSin(angle + IM_PI) : sin_a;
    unit_right := ImVec2{cos_a, sin_a};

    // Calculate our base metrics and set angled headers data _before_ the first call to TableNextRow()
    // FIXME-STYLE: Would it be better for user to submit 'max_label_width' or 'row_height' ? One can be derived from the other.
    header_height := g.FontSize + g.Style.CellPadding.x * 2.0;
    row_height := ImTrunc(ImFabs(ImRotate(ImVec2{max_label_width, flip_label ? +header_height : -header_height}, cos_a, sin_a).y));
    table.AngledHeadersHeight = row_height;
    table.AngledHeadersSlope = (sin_a != 0.0) ? (cos_a / sin_a) : 0.0;
    header_angled_vector := unit_right * (row_height / -sin_a); // vector from bottom-left to top-left, and from bottom-right to top-right

    // Declare row, override and draw our own background
    TableNextRow(ImGuiTableRowFlags_Headers, row_height);
    TableNextColumn();
    row_r := ImRect(table.WorkRect.Min.x, table.BgClipRect.Min.y, table.WorkRect.Max.x, table.RowPosY2);
    table.DrawSplitter->SetCurrentChannel(draw_list, TABLE_DRAW_CHANNEL_BG0);
    clip_rect_min_x := table.BgClipRect.Min.x;
    if (table.FreezeColumnsCount > 0)
        clip_rect_min_x = ImMax(clip_rect_min_x, table.Columns[table.FreezeColumnsCount - 1].MaxX);
    TableSetBgColor(ImGuiTableBgTarget_RowBg0, 0); // Cancel
    PushClipRect(table.BgClipRect.Min, table.BgClipRect.Max, false); // Span all columns
    draw_list.AddRectFilled(ImVec2{table.BgClipRect.Min.x, row_r.Min.y}, ImVec2{table.BgClipRect.Max.x, row_r.Max.y}, GetColorU32(ImGuiCol_TableHeaderBg, 0.25)); // FIXME-STYLE: Change row background with an arbitrary color.
    PushClipRect(ImVec2{clip_rect_min_x, table.BgClipRect.Min.y}, table.BgClipRect.Max, true); // Span all columns

    ButtonBehavior(row_r, row_id, nil, nil);
    KeepAliveID(row_id);

    ascent_scaled := g.Font.Ascent * g.FontScale; // FIXME: Standardize those scaling factors better
    line_off_for_ascent_x := (ImMax((g.FontSize - ascent_scaled) * 0.5, 0.0) / -sin_a) * (flip_label ? -1.0 : 1.0);
    padding := g.Style.CellPadding; // We will always use swapped component
    align := g.Style.TableAngledHeadersTextAlign;

    // Draw background and labels in first pass, then all borders.
    max_x := -math.F32_MAX;
    for i32 pass = 0; pass < 2; pass++
        for i32 order_n = 0; order_n < data_count; order_n++
        {
            request := &data[order_n];
            column_n := request.Index;
            column := &table.Columns[column_n];

            bg_shape : [4]ImVec2
            bg_shape[0] = ImVec2{column.MaxX, row_r.Max.y};
            bg_shape[1] = ImVec2{column.MinX, row_r.Max.y};
            bg_shape[2] = bg_shape[1] + header_angled_vector;
            bg_shape[3] = bg_shape[0] + header_angled_vector;
            if (pass == 0)
            {
                // Draw shape
                draw_list.AddQuadFilled(bg_shape[0], bg_shape[1], bg_shape[2], bg_shape[3], request.BgColor0);
                draw_list.AddQuadFilled(bg_shape[0], bg_shape[1], bg_shape[2], bg_shape[3], request.BgColor1); // Optional highlight
                max_x = ImMax(max_x, bg_shape[3].x);

                // Draw label
                // - First draw at an offset where RenderTextXXX() function won't meddle with applying current ClipRect, then transform to final offset.
                // - Handle multiple lines manually, as we want each lines to follow on the horizontal border, rather than see a whole block rotated.
                label_name := TableGetColumnName(table, column_n);
                label_name_end := FindRenderedTextEnd(label_name);
                line_off_step_x := (g.FontSize / -sin_a);
                label_lines := ImTextCountLines(label_name, label_name_end);

                // Left<>Right alignment
                line_off_curr_x := flip_label ? (label_lines - 1) * line_off_step_x : 0.0;
                line_off_for_align_x := ImMax((((column.MaxX - column.MinX) - padding.x * 2.0) - (label_lines * line_off_step_x)), 0.0) * align.x;
                line_off_curr_x += line_off_for_align_x - line_off_for_ascent_x;

                // Register header width
                column.ContentMaxXHeadersUsed = column.ContentMaxXHeadersIdeal = column.WorkMinX + ImCeil(label_lines * line_off_step_x - line_off_for_align_x);

                for label_name < label_name_end
                {
                    label_name_eol := strchr(label_name, '\n');
                    if (label_name_eol == nil)
                        label_name_eol = label_name_end;

                    // FIXME: Individual line clipping for right-most column is broken for negative angles.
                    label_size := CalcTextSize(label_name, label_name_eol);
                    clip_width := max_label_width - padding.y; // Using padding.y*2.0f would be symmetrical but hide more text.
                    clip_height := ImMin(label_size.y, column.ClipRect.Max.x - column.WorkMinX - line_off_curr_x);
                    clip_r := ImRect(window.ClipRect.Min, window.ClipRect.Min + ImVec2{clip_width, clip_height});
                    vtx_idx_begin := draw_list._VtxCurrentIdx;
                    PushStyleColor(ImGuiCol_Text, request.TextColor);
                    RenderTextEllipsis(draw_list, clip_r.Min, clip_r.Max, clip_r.Max.x, clip_r.Max.x, label_name, label_name_eol, &label_size);
                    PopStyleColor();
                    vtx_idx_end := draw_list._VtxCurrentIdx;

                    // Up<>Down alignment
                    available_space := ImMax(clip_width - label_size.x + ImAbs(padding.x * cos_a) * 2.0 - ImAbs(padding.y * sin_a) * 2.0, 0.0);
                    vertical_offset := available_space * align.y * (flip_label ? -1.0 : 1.0);

                    // Rotate and offset label
                    pivot_in := ImVec2{window.ClipRect.Min.x - vertical_offset, window.ClipRect.Min.y + label_size.y};
                    pivot_out := ImVec2{column.WorkMinX, row_r.Max.y};
                    line_off_curr_x += flip_label ? -line_off_step_x : line_off_step_x;
                    pivot_out += unit_right * padding.y;
                    if (flip_label)
                        pivot_out += unit_right * (clip_width - ImMax(0.0, clip_width - label_size.x));
                    pivot_out.x += flip_label ? line_off_curr_x + line_off_step_x : line_off_curr_x;
                    ShadeVertsTransformPos(draw_list, vtx_idx_begin, vtx_idx_end, pivot_in, label_cos_a, label_sin_a, pivot_out); // Rotate and offset
                    //if (g.IO.KeyShift) { ImDrawList* fg_dl = GetForegroundDrawList(); vtx_idx_begin = fg_dl->_VtxCurrentIdx; fg_dl->AddRect(clip_r.Min, clip_r.Max, IM_COL32(0, 255, 0, 255), 0.0f, 0, 1.0f); ShadeVertsTransformPos(fg_dl, vtx_idx_begin, fg_dl->_VtxCurrentIdx, pivot_in, label_cos_a, label_sin_a, pivot_out); }

                    label_name = label_name_eol + 1;
                }
            }
            if (pass == 1)
            {
                // Draw border
                draw_list.AddLine(bg_shape[0], bg_shape[3], TableGetColumnBorderCol(table, order_n, column_n));
            }
        }
    PopClipRect();
    PopClipRect();
    table.TempData->AngledHeadersExtraWidth = ImMax(0.0, max_x - table.Columns[table.RightMostEnabledColumn].MaxX);
}

//-------------------------------------------------------------------------
// [SECTION] Tables: Context Menu
//-------------------------------------------------------------------------
// - TableOpenContextMenu() [Internal]
// - TableBeginContextMenuPopup() [Internal]
// - TableDrawDefaultContextMenu() [Internal]
//-------------------------------------------------------------------------

// Use -1 to open menu not specific to a given column.
TableOpenContextMenu :: proc(column_n : i32 = -1)
{
    g := GImGui;
    table := g.CurrentTable;
    if (column_n == -1 && table.CurrentColumn != -1)   // When called within a column automatically use this one (for consistency)
        column_n = table.CurrentColumn;
    if (column_n == table.ColumnsCount)                // To facilitate using with TableGetHoveredColumn()
        column_n = -1;
    assert(column_n >= -1 && column_n < table.ColumnsCount);
    if (table.Flags & (ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_Hideable))
    {
        table.IsContextPopupOpen = true;
        table.ContextPopupColumn = (ImGuiTableColumnIdx)column_n;
        table.InstanceInteracted = table.InstanceCurrent;
        context_menu_id := ImHashStr("##ContextMenu", 0, table.ID);
        OpenPopupEx(context_menu_id, ImGuiPopupFlags_None);
    }
}

TableBeginContextMenuPopup :: proc(table : ^ImGuiTable) -> bool
{
    if (!table.IsContextPopupOpen || table.InstanceCurrent != table.InstanceInteracted)
        return false;
    context_menu_id := ImHashStr("##ContextMenu", 0, table.ID);
    if (BeginPopupEx(context_menu_id, ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoSavedSettings))
        return true;
    table.IsContextPopupOpen = false;
    return false;
}

// Output context menu into current window (generally a popup)
// FIXME-TABLE: Ideally this should be writable by the user. Full programmatic access to that data?
// Sections to display are pulled from 'flags_for_section_to_display', which is typically == table->Flags.
// - ImGuiTableFlags_Resizable   -> display Sizing menu items
// - ImGuiTableFlags_Reorderable -> display "Reset Order"
////- ImGuiTableFlags_Sortable   -> display sorting options (disabled)
// - ImGuiTableFlags_Hideable    -> display columns visibility menu items
// It means if you have a custom context menus you can call this section and omit some sections, and add your own.
TableDrawDefaultContextMenu :: proc(table : ^ImGuiTable, flags_for_section_to_display : ImGuiTableFlags)
{
    g := GImGui;
    window := g.CurrentWindow;
    if (window.SkipItems)
        return;

    want_separator := false;
    column_n := (table.ContextPopupColumn >= 0 && table.ContextPopupColumn < table.ColumnsCount) ? table.ContextPopupColumn : -1;
    column := (column_n != -1) ? &table.Columns[column_n] : nil;

    // Sizing
    if (flags_for_section_to_display & ImGuiTableFlags_Resizable)
    {
        if (column != nil)
        {
            can_resize := !(column.Flags & ImGuiTableColumnFlags_NoResize) && column.IsEnabled;
            if (MenuItem(LocalizeGetMsg(ImGuiLocKey_TableSizeOne), nil, false, can_resize)) // "###SizeOne"
                TableSetColumnWidthAutoSingle(table, column_n);
        }

        size_all_desc : ^u8
        if (table.ColumnsEnabledFixedCount == table.ColumnsEnabledCount && (table.Flags & ImGuiTableFlags_SizingMask_) != ImGuiTableFlags_SizingFixedSame)
            size_all_desc = LocalizeGetMsg(ImGuiLocKey_TableSizeAllFit);        // "###SizeAll" All fixed
        else
            size_all_desc = LocalizeGetMsg(ImGuiLocKey_TableSizeAllDefault);    // "###SizeAll" All stretch or mixed
        if (MenuItem(size_all_desc, nil))
            TableSetColumnWidthAutoAll(table);
        want_separator = true;
    }

    // Ordering
    if (flags_for_section_to_display & ImGuiTableFlags_Reorderable)
    {
        if (MenuItem(LocalizeGetMsg(ImGuiLocKey_TableResetOrder), nil, false, !table.IsDefaultDisplayOrder))
            table.IsResetDisplayOrderRequest = true;
        want_separator = true;
    }

    // Reset all (should work but seems unnecessary/noisy to expose?)
    //if (MenuItem("Reset all"))
    //    table->IsResetAllRequest = true;

    // Sorting
    // (modify TableOpenContextMenu() to add _Sortable flag if enabling this)
when 0 {
    if ((flags_for_section_to_display & ImGuiTableFlags_Sortable) && column != nil && (column.Flags & ImGuiTableColumnFlags_NoSort) == 0)
    {
        if (want_separator)
            Separator();
        want_separator = true;

        append_to_sort_specs := g.IO.KeyShift;
        if (MenuItem("Sort in Ascending Order", nil, column.SortOrder != -1 && column.SortDirection == ImGuiSortDirection_Ascending, (column.Flags & ImGuiTableColumnFlags_NoSortAscending) == 0))
            TableSetColumnSortDirection(table, column_n, ImGuiSortDirection_Ascending, append_to_sort_specs);
        if (MenuItem("Sort in Descending Order", nil, column.SortOrder != -1 && column.SortDirection == ImGuiSortDirection_Descending, (column.Flags & ImGuiTableColumnFlags_NoSortDescending) == 0))
            TableSetColumnSortDirection(table, column_n, ImGuiSortDirection_Descending, append_to_sort_specs);
    }
}

    // Hiding / Visibility
    if (flags_for_section_to_display & ImGuiTableFlags_Hideable)
    {
        if (want_separator)
            Separator();
        want_separator = true;

        PushItemFlag(ImGuiItemFlags_AutoClosePopups, false);
        for i32 other_column_n = 0; other_column_n < table.ColumnsCount; other_column_n++
        {
            other_column := &table.Columns[other_column_n];
            if (other_column.Flags & ImGuiTableColumnFlags_Disabled)
                continue;

            name := TableGetColumnName(table, other_column_n);
            if (name == nil || name[0] == 0)
                name = "<Unknown>";

            // Make sure we can't hide the last active column
            menu_item_active := (other_column.Flags & ImGuiTableColumnFlags_NoHide) ? false : true;
            if (other_column.IsUserEnabled && table.ColumnsEnabledCount <= 1)
                menu_item_active = false;
            if (MenuItem(name, nil, other_column.IsUserEnabled, menu_item_active))
                other_column.IsUserEnabledNextFrame = !other_column.IsUserEnabled;
        }
        PopItemFlag();
    }
}

//-------------------------------------------------------------------------
// [SECTION] Tables: Settings (.ini data)
//-------------------------------------------------------------------------
// FIXME: The binding/finding/creating flow are too confusing.
//-------------------------------------------------------------------------
// - TableSettingsInit() [Internal]
// - TableSettingsCalcChunkSize() [Internal]
// - TableSettingsCreate() [Internal]
// - TableSettingsFindByID() [Internal]
// - TableGetBoundSettings() [Internal]
// - TableResetSettings()
// - TableSaveSettings() [Internal]
// - TableLoadSettings() [Internal]
// - TableSettingsHandler_ClearAll() [Internal]
// - TableSettingsHandler_ApplyAll() [Internal]
// - TableSettingsHandler_ReadOpen() [Internal]
// - TableSettingsHandler_ReadLine() [Internal]
// - TableSettingsHandler_WriteAll() [Internal]
// - TableSettingsInstallHandler() [Internal]
//-------------------------------------------------------------------------
// [Init] 1: TableSettingsHandler_ReadXXXX()   Load and parse .ini file into TableSettings.
// [Main] 2: TableLoadSettings()               When table is created, bind Table to TableSettings, serialize TableSettings data into Table.
// [Main] 3: TableSaveSettings()               When table properties are modified, serialize Table data into bound or new TableSettings, mark .ini as dirty.
// [Main] 4: TableSettingsHandler_WriteAll()   When .ini file is dirty (which can come from other source), save TableSettings into .ini file.
//-------------------------------------------------------------------------

// Clear and initialize empty settings instance
TableSettingsInit :: proc(settings : ^ImGuiTableSettings, id : ImGuiID, columns_count : i32, columns_count_max : i32)
{
    IM_PLACEMENT_NEW(settings) ImGuiTableSettings();
    settings_column := settings.GetColumnSettings();
    for i32 n = 0; n < columns_count_max; n++, settings_column++
        IM_PLACEMENT_NEW(settings_column) ImGuiTableColumnSettings();
    settings.ID = id;
    settings.ColumnsCount = (ImGuiTableColumnIdx)columns_count;
    settings.ColumnsCountMax = (ImGuiTableColumnIdx)columns_count_max;
    settings.WantApply = true;
}

TableSettingsCalcChunkSize :: proc(columns_count : i32) -> int
{
    return size_of(ImGuiTableSettings) + cast(ast) ast) ns_countcountze_of(ImGuiTableColumnSettings);
}

TableSettingsCreate :: proc(id : ImGuiID, columns_count : i32) -> ^ImGuiTableSettings
{
    g := GImGui;
    settings := g.SettingsTables.alloc_chunk(TableSettingsCalcChunkSize(columns_count));
    TableSettingsInit(settings, id, columns_count, columns_count);
    return settings;
}

// Find existing settings
TableSettingsFindByID :: proc(id : ImGuiID) -> ^ImGuiTableSettings
{
    // FIXME-OPT: Might want to store a lookup map for this?
    g := GImGui;
    for ImGuiTableSettings* settings = g.SettingsTables.begin(); settings != nil; settings = g.SettingsTables.next_chunk(settings)
        if (settings.ID == id)
            return settings;
    return nil;
}

// Get settings for a given table, NULL if none
TableGetBoundSettings :: proc(table : ^ImGuiTable) -> ^ImGuiTableSettings
{
    if (table.SettingsOffset != -1)
    {
        g := GImGui;
        settings := g.SettingsTables.ptr_from_offset(table.SettingsOffset);
        assert(settings.ID == table.ID);
        if (settings.ColumnsCountMax >= table.ColumnsCount)
            return settings; // OK
        settings.ID = 0; // Invalidate storage, we won't fit because of a count change
    }
    return nil;
}

// Restore initial state of table (with or without saved settings)
TableResetSettings :: proc(table : ^ImGuiTable)
{
    table.IsInitializing = table.IsSettingsDirty = true;
    table.IsResetAllRequest = false;
    table.IsSettingsRequestLoad = false;                   // Don't reload from ini
    table.SettingsLoadedFlags = ImGuiTableFlags_None;      // Mark as nothing loaded so our initialized data becomes authoritative
}

TableSaveSettings :: proc(table : ^ImGuiTable)
{
    table.IsSettingsDirty = false;
    if (table.Flags & ImGuiTableFlags_NoSavedSettings)
        return;

    // Bind or create settings data
    g := GImGui;
    settings := TableGetBoundSettings(table);
    if (settings == nil)
    {
        settings = TableSettingsCreate(table.ID, table.ColumnsCount);
        table.SettingsOffset = g.SettingsTables.offset_from_ptr(settings);
    }
    settings.ColumnsCount = (ImGuiTableColumnIdx)table.ColumnsCount;

    // Serialize ImGuiTable/ImGuiTableColumn into ImGuiTableSettings/ImGuiTableColumnSettings
    assert(settings.ID == table.ID);
    assert(settings.ColumnsCount == table.ColumnsCount && settings.ColumnsCountMax >= settings.ColumnsCount);
    column := table.Columns.Data;
    column_settings := settings.GetColumnSettings();

    save_ref_scale := false;
    settings.SaveFlags = ImGuiTableFlags_None;
    for i32 n = 0; n < table.ColumnsCount; n++, column++, column_settings++
    {
        width_or_weight := (column.Flags & ImGuiTableColumnFlags_WidthStretch) ? column.StretchWeight : column.WidthRequest;
        column_settings.WidthOrWeight = width_or_weight;
        column_settings.Index = (ImGuiTableColumnIdx)n;
        column_settings.DisplayOrder = column.DisplayOrder;
        column_settings.SortOrder = column.SortOrder;
        column_settings.SortDirection = column.SortDirection;
        column_settings.IsEnabled = column.IsUserEnabled;
        column_settings.IsStretch = (column.Flags & ImGuiTableColumnFlags_WidthStretch) ? 1 : 0;
        if ((column.Flags & ImGuiTableColumnFlags_WidthStretch) == 0)
            save_ref_scale = true;

        // We skip saving some data in the .ini file when they are unnecessary to restore our state.
        // Note that fixed width where initial width was derived from auto-fit will always be saved as InitStretchWeightOrWidth will be 0.0f.
        // FIXME-TABLE: We don't have logic to easily compare SortOrder to DefaultSortOrder yet so it's always saved when present.
        if (width_or_weight != column.InitStretchWeightOrWidth)
            settings.SaveFlags |= ImGuiTableFlags_Resizable;
        if (column.DisplayOrder != n)
            settings.SaveFlags |= ImGuiTableFlags_Reorderable;
        if (column.SortOrder != -1)
            settings.SaveFlags |= ImGuiTableFlags_Sortable;
        if (column.IsUserEnabled != ((column.Flags & ImGuiTableColumnFlags_DefaultHide) == 0))
            settings.SaveFlags |= ImGuiTableFlags_Hideable;
    }
    settings.SaveFlags &= table.Flags;
    settings.RefScale = save_ref_scale ? table.RefScale : 0.0;

    MarkIniSettingsDirty();
}

TableLoadSettings :: proc(table : ^ImGuiTable)
{
    g := GImGui;
    table.IsSettingsRequestLoad = false;
    if (table.Flags & ImGuiTableFlags_NoSavedSettings)
        return;

    // Bind settings
    settings : ^ImGuiTableSettings
    if (table.SettingsOffset == -1)
    {
        settings = TableSettingsFindByID(table.ID);
        if (settings == nil)
            return;
        if (settings.ColumnsCount != table.ColumnsCount) // Allow settings if columns count changed. We could otherwise decide to return...
            table.IsSettingsDirty = true;
        table.SettingsOffset = g.SettingsTables.offset_from_ptr(settings);
    }
    else
    {
        settings = TableGetBoundSettings(table);
    }

    table.SettingsLoadedFlags = settings.SaveFlags;
    table.RefScale = settings.RefScale;

    // Serialize ImGuiTableSettings/ImGuiTableColumnSettings into ImGuiTable/ImGuiTableColumn
    column_settings := settings.GetColumnSettings();
    display_order_mask := 0;
    for i32 data_n = 0; data_n < settings.ColumnsCount; data_n++, column_settings++
    {
        column_n := column_settings.Index;
        if (column_n < 0 || column_n >= table.ColumnsCount)
            continue;

        column := &table.Columns[column_n];
        if (settings.SaveFlags & ImGuiTableFlags_Resizable)
        {
            if (column_settings.IsStretch)
                column.StretchWeight = column_settings.WidthOrWeight;
            else
                column.WidthRequest = column_settings.WidthOrWeight;
            column.AutoFitQueue = 0x00;
        }
        if (settings.SaveFlags & ImGuiTableFlags_Reorderable)
            column.DisplayOrder = column_settings.DisplayOrder;
        else
            column.DisplayOrder = (ImGuiTableColumnIdx)column_n;
        display_order_mask |= cast(ast) ast) aolumn.DisplayOrder;
        column.IsUserEnabled = column.IsUserEnabledNextFrame = column_settings.IsEnabled;
        column.SortOrder = column_settings.SortOrder;
        column.SortDirection = column_settings.SortDirection;
    }

    // Validate and fix invalid display order data
    expected_display_order_mask := (settings.ColumnsCount == 64) ? ~0 : (cast(ast) ast) aettings.ColumnsCount) - 1;
    if (display_order_mask != expected_display_order_mask)
        for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
            table.Columns[column_n].DisplayOrder = (ImGuiTableColumnIdx)column_n;

    // Rebuild index
    for i32 column_n = 0; column_n < table.ColumnsCount; column_n++
        table.DisplayOrderToIndex[table.Columns[column_n].DisplayOrder] = (ImGuiTableColumnIdx)column_n;
}

TableSettingsHandler_ClearAll :: proc(ctx : ^ImGuiContext, ImGuiSettingsHandler*)
{
    g := ctx;
    for i32 i = 0; i != g.Tables.GetMapSize(); i++
        if (ImGuiTable* table = g.Tables.TryGetMapData(i))
            table.SettingsOffset = -1;
    g.SettingsTables.clear();
}

// Apply to existing windows (if any)
TableSettingsHandler_ApplyAll :: proc(ctx : ^ImGuiContext, ImGuiSettingsHandler*)
{
    g := ctx;
    for i32 i = 0; i != g.Tables.GetMapSize(); i++
        if (ImGuiTable* table = g.Tables.TryGetMapData(i))
        {
            table.IsSettingsRequestLoad = true;
            table.SettingsOffset = -1;
        }
}

TableSettingsHandler_ReadOpen :: proc(ImGuiContext*, ImGuiSettingsHandler*, name : ^u8) -> rawptr
{
    id := 0;
    columns_count := 0;
    if (sscanf(name, "0x%08X,%d", &id, &columns_count) < 2)
        return nil;

    if (ImGuiTableSettings* settings = TableSettingsFindByID(id))
    {
        if (settings.ColumnsCountMax >= columns_count)
        {
            TableSettingsInit(settings, id, columns_count, settings.ColumnsCountMax); // Recycle
            return settings;
        }
        settings.ID = 0; // Invalidate storage, we won't fit because of a count change
    }
    return TableSettingsCreate(id, columns_count);
}

TableSettingsHandler_ReadLine :: proc(ImGuiContext*, ImGuiSettingsHandler*, entry : rawptr, line : ^u8)
{
    // "Column 0  UserID=0x42AD2D21 Width=100 Visible=1 Order=0 Sort=0v"
    settings := (ImGuiTableSettings*)entry;
    f := 0.0;
    column_n := 0, r = 0, n = 0;

    if (sscanf(line, "RefScale=%f", &f) == 1) { settings.RefScale = f; return; }

    if (sscanf(line, "Column %d%n", &column_n, &r) == 1)
    {
        if (column_n < 0 || column_n >= settings.ColumnsCount)
            return;
        line = ImStrSkipBlank(line + r);
        c := 0;
        column := settings.GetColumnSettings() + column_n;
        column.Index = (ImGuiTableColumnIdx)column_n;
        if (sscanf(line, "UserID=0x%08X%n", (u32*)&n, &r)==1) { line = ImStrSkipBlank(line + r); column.UserID = (ImGuiID)n; }
        if (sscanf(line, "Width=%d%n", &n, &r) == 1)            { line = ImStrSkipBlank(line + r); column.WidthOrWeight = cast(ast) ast) aumn.IsStretch = 0; settings.SaveFlags |= ImGuiTableFlags_Resizable; }
        if (sscanf(line, "Weight=%f%n", &f, &r) == 1)           { line = ImStrSkipBlank(line + r); column.WidthOrWeight = f; column.IsStretch = 1; settings.SaveFlags |= ImGuiTableFlags_Resizable; }
        if (sscanf(line, "Visible=%d%n", &n, &r) == 1)          { line = ImStrSkipBlank(line + r); column.IsEnabled = cast(as) (as) (tings.SaveFlags |= ImGuiTableFlags_Hideable; }
        if (sscanf(line, "Order=%d%n", &n, &r) == 1)            { line = ImStrSkipBlank(line + r); column.DisplayOrder = (ImGuiTableColumnIdx)n; settings.SaveFlags |= ImGuiTableFlags_Reorderable; }
        if (sscanf(line, "Sort=%d%c%n", &n, &c, &r) == 2)       { line = ImStrSkipBlank(line + r); column.SortOrder = (ImGuiTableColumnIdx)n; column.SortDirection = (c == '^') ? ImGuiSortDirection_Descending : ImGuiSortDirection_Ascending; settings.SaveFlags |= ImGuiTableFlags_Sortable; }
    }
}

TableSettingsHandler_WriteAll :: proc(ctx : ^ImGuiContext, handler : ^ImGuiSettingsHandler, buf : ^ImGuiTextBuffer)
{
    g := ctx;
    for ImGuiTableSettings* settings = g.SettingsTables.begin(); settings != nil; settings = g.SettingsTables.next_chunk(settings)
    {
        if (settings.ID == 0) // Skip ditched settings
            continue;

        // TableSaveSettings() may clear some of those flags when we establish that the data can be stripped
        // (e.g. Order was unchanged)
        save_size := (settings.SaveFlags & ImGuiTableFlags_Resizable) != 0;
        save_visible := (settings.SaveFlags & ImGuiTableFlags_Hideable) != 0;
        save_order := (settings.SaveFlags & ImGuiTableFlags_Reorderable) != 0;
        save_sort := (settings.SaveFlags & ImGuiTableFlags_Sortable) != 0;
        if (!save_size && !save_visible && !save_order && !save_sort)
            continue;

        buf.reserve(buf.size() + 30 + settings.ColumnsCount * 50); // ballpark reserve
        buf.appendf("[%s][0x%08X,%d]\n", handler.TypeName, settings.ID, settings.ColumnsCount);
        if (settings.RefScale != 0.0)
            buf.appendf("RefScale=%g\n", settings.RefScale);
        column := settings.GetColumnSettings();
        for i32 column_n = 0; column_n < settings.ColumnsCount; column_n++, column++
        {
            // "Column 0  UserID=0x42AD2D21 Width=100 Visible=1 Order=0 Sort=0v"
            save_column := column.UserID != 0 || save_size || save_visible || save_order || (save_sort && column.SortOrder != -1);
            if (!save_column)
                continue;
            buf.appendf("Column %-2d", column_n);
            if (column.UserID != 0)                    { buf.appendf(" UserID=%08X", column.UserID); }
            if (save_size && column.IsStretch)         { buf.appendf(" Weight=%.4", column.WidthOrWeight); }
            if (save_size && !column.IsStretch)        { buf.appendf(" Width=%d", cast(ast) ast) nst) nhOrWeight); }
            if (save_visible)                           { buf.appendf(" Visible=%d", column.IsEnabled); }
            if (save_order)                             { buf.appendf(" Order=%d", column.DisplayOrder); }
            if (save_sort && column.SortOrder != -1)   { buf.appendf(" Sort=%d%c", column.SortOrder, (column.SortDirection == ImGuiSortDirection_Ascending) ? 'v' : '^'); }
            buf.append("\n");
        }
        buf.append("\n");
    }
}

TableSettingsAddSettingsHandler :: proc()
{
    ini_handler : ImGuiSettingsHandler
    ini_handler.TypeName = "Table";
    ini_handler.TypeHash = ImHashStr("Table");
    ini_handler.ClearAllFn = TableSettingsHandler_ClearAll;
    ini_handler.ReadOpenFn = TableSettingsHandler_ReadOpen;
    ini_handler.ReadLineFn = TableSettingsHandler_ReadLine;
    ini_handler.ApplyAllFn = TableSettingsHandler_ApplyAll;
    ini_handler.WriteAllFn = TableSettingsHandler_WriteAll;
    AddSettingsHandler(&ini_handler);
}

//-------------------------------------------------------------------------
// [SECTION] Tables: Garbage Collection
//-------------------------------------------------------------------------
// - TableRemove() [Internal]
// - TableGcCompactTransientBuffers() [Internal]
// - TableGcCompactSettings() [Internal]
//-------------------------------------------------------------------------

// Remove Table (currently only used by TestEngine)
TableRemove :: proc(table : ^ImGuiTable)
{
    //IMGUI_DEBUG_PRINT("TableRemove() id=0x%08X\n", table->ID);
    g := GImGui;
    table_idx := g.Tables.GetIndex(table);
    //memset(table->RawData.Data, 0, table->RawData.size_in_bytes());
    //memset(table, 0, sizeof(ImGuiTable));
    g.Tables.Remove(table.ID, table);
    g.TablesLastTimeActive[table_idx] = -1.0;
}

// Free up/compact internal Table buffers for when it gets unused
TableGcCompactTransientBuffers :: proc(table : ^ImGuiTable)
{
    //IMGUI_DEBUG_PRINT("TableGcCompactTransientBuffers() id=0x%08X\n", table->ID);
    g := GImGui;
    assert(table.MemoryCompacted == false);
    table.SortSpecs.Specs = nil;
    table.SortSpecsMulti.clear();
    table.IsSortSpecsDirty = true; // FIXME: In theory shouldn't have to leak into user performing a sort on resume.
    table.ColumnsNames.clear();
    table.MemoryCompacted = true;
    for i32 n = 0; n < table.ColumnsCount; n++
        table.Columns[n].NameOffset = -1;
    g.TablesLastTimeActive[g.Tables.GetIndex(table)] = -1.0;
}

TableGcCompactTransientBuffers :: proc(temp_data : ^ImGuiTableTempData)
{
    temp_data.DrawSplitter.ClearFreeMemory();
    temp_data.LastTimeActive = -1.0;
}

// Compact and remove unused settings data (currently only used by TestEngine)
TableGcCompactSettings :: proc()
{
    g := GImGui;
    required_memory := 0;
    for ImGuiTableSettings* settings = g.SettingsTables.begin(); settings != nil; settings = g.SettingsTables.next_chunk(settings)
        if (settings.ID != 0)
            required_memory += cast(ast) ast) SettingsCalcChunkSizekSizeings.ColumnsCount);
    if (required_memory == g.SettingsTables.Buf.Size)
        return;
    new_chunk_stream : ImChunkStream<ImGuiTableSettings>
    new_chunk_stream.Buf.reserve(required_memory);
    for ImGuiTableSettings* settings = g.SettingsTables.begin(); settings != nil; settings = g.SettingsTables.next_chunk(settings)
        if (settings.ID != 0)
            memcpy(new_chunk_stream.alloc_chunk(TableSettingsCalcChunkSize(settings.ColumnsCount)), settings, TableSettingsCalcChunkSize(settings.ColumnsCount));
    g.SettingsTables.swap(new_chunk_stream);
}


//-------------------------------------------------------------------------
// [SECTION] Tables: Debugging
//-------------------------------------------------------------------------
// - DebugNodeTable() [Internal]
//-------------------------------------------------------------------------

when !(IMGUI_DISABLE_DEBUG_TOOLS) {

DebugNodeTableGetSizingPolicyDesc :: proc(sizing_policy : ImGuiTableFlags) -> ^u8
{
    sizing_policy &= ImGuiTableFlags_SizingMask_;
    if (sizing_policy == ImGuiTableFlags_SizingFixedFit)    { return "FixedFit"; }
    if (sizing_policy == ImGuiTableFlags_SizingFixedSame)   { return "FixedSame"; }
    if (sizing_policy == ImGuiTableFlags_SizingStretchProp) { return "StretchProp"; }
    if (sizing_policy == ImGuiTableFlags_SizingStretchSame) { return "StretchSame"; }
    return "N/A";
}

DebugNodeTable :: proc(table : ^ImGuiTable)
{
    g := GImGui;
    is_active := (table.LastFrameActive >= g.FrameCount - 2); // Note that fully clipped early out scrolling tables will appear as inactive here.
    if (!is_active) { PushStyleColor(ImGuiCol_Text, GetStyleColorVec4(ImGuiCol_TextDisabled)); }
    open := TreeNode(table, "Table 0x%08X (%d columns, in '%s')%s", table.ID, table.ColumnsCount, table.OuterWindow->Name, is_active ? "" : " *Inactive*");
    if (!is_active) { PopStyleColor(); }
    if (IsItemHovered())
        GetForegroundDrawList()->AddRect(table.OuterRect.Min, table.OuterRect.Max, IM_COL32(255, 255, 0, 255));
    if (IsItemVisible() && table.HoveredColumnBody != -1)
        GetForegroundDrawList()->AddRect(GetItemRectMin(), GetItemRectMax(), IM_COL32(255, 255, 0, 255));
    if (!open)
        return;
    if (table.InstanceCurrent > 0)
        Text("** %d instances of same table! Some data below will refer to last instance.", table.InstanceCurrent + 1);
    if (g.IO.ConfigDebugIsDebuggerPresent)
    {
        if (DebugBreakButton("**DebugBreak**", "in BeginTable()"))
            g.DebugBreakInTable = table.ID;
        SameLine();
    }

    clear_settings := SmallButton("Clear settings");
    BulletText("OuterRect: Pos: (%.1,%.1) Size: (%.1,%.1) Sizing: '%s'", table.OuterRect.Min.x, table.OuterRect.Min.y, table.OuterRect.GetWidth(), table.OuterRect.GetHeight(), DebugNodeTableGetSizingPolicyDesc(table.Flags));
    BulletText("ColumnsGivenWidth: %.1, ColumnsAutoFitWidth: %.1, InnerWidth: %.1%s", table.ColumnsGivenWidth, table.ColumnsAutoFitWidth, table.InnerWidth, table.InnerWidth == 0.0 ? " (auto)" : "");
    BulletText("CellPaddingX: %.1, CellSpacingX: %.1/%.1, OuterPaddingX: %.1", table.CellPaddingX, table.CellSpacingX1, table.CellSpacingX2, table.OuterPaddingX);
    BulletText("HoveredColumnBody: %d, HoveredColumnBorder: %d", table.HoveredColumnBody, table.HoveredColumnBorder);
    BulletText("ResizedColumn: %d, ReorderColumn: %d, HeldHeaderColumn: %d", table.ResizedColumn, table.ReorderColumn, table.HeldHeaderColumn);
    for i32 n = 0; n < table.InstanceCurrent + 1; n++
    {
        table_instance := TableGetInstanceData(table, n);
        BulletText("Instance %d: HoveredRow: %d, LastOuterHeight: %.2", n, table_instance.HoveredRowLast, table_instance.LastOuterHeight);
    }
    //BulletText("BgDrawChannels: %d/%d", 0, table->BgDrawChannelUnfrozen);
    sum_weights := 0.0;
    for i32 n = 0; n < table.ColumnsCount; n++
        if (table.Columns[n].Flags & ImGuiTableColumnFlags_WidthStretch)
            sum_weights += table.Columns[n].StretchWeight;
    for i32 n = 0; n < table.ColumnsCount; n++
    {
        column := &table.Columns[n];
        name := TableGetColumnName(table, n);
        buf : [512]u8
        ImFormatString(buf, len(buf),
            "Column %d order %d '%s': offset %+.2 to %+.2%s\n"
            "Enabled: %d, VisibleX/Y: %d/%d, RequestOutput: %d, SkipItems: %d, DrawChannels: %d,%d\n"
            "WidthGiven: %.1, Request/Auto: %.1/%.1, StretchWeight: %.3 (%.1%%)\n"
            "MinX: %.1, MaxX: %.1 (%+.1), ClipRect: %.1 to %.1 (+%.1)\n"
            "ContentWidth: %.1,%.1, HeadersUsed/Ideal %.1/%.1\n"
            "Sort: %d%s, UserID: 0x%08X, Flags: 0x%04X: %s%s%s..",
            n, column.DisplayOrder, name, column.MinX - table.WorkRect.Min.x, column.MaxX - table.WorkRect.Min.x, (n < table.FreezeColumnsRequest) ? " (Frozen)" : "",
            column.IsEnabled, column.IsVisibleX, column.IsVisibleY, column.IsRequestOutput, column.IsSkipItems, column.DrawChannelFrozen, column.DrawChannelUnfrozen,
            column.WidthGiven, column.WidthRequest, column.WidthAuto, column.StretchWeight, column.StretchWeight > 0.0 ? (column.StretchWeight / sum_weights) * 100.0 : 0.0,
            column.MinX, column.MaxX, column.MaxX - column.MinX, column.ClipRect.Min.x, column.ClipRect.Max.x, column.ClipRect.Max.x - column.ClipRect.Min.x,
            column.ContentMaxXFrozen - column.WorkMinX, column.ContentMaxXUnfrozen - column.WorkMinX, column.ContentMaxXHeadersUsed - column.WorkMinX, column.ContentMaxXHeadersIdeal - column.WorkMinX,
            column.SortOrder, (column.SortDirection == ImGuiSortDirection_Ascending) ? " (Asc)" : (column.SortDirection == ImGuiSortDirection_Descending) ? " (Des)" : "", column.UserID, column.Flags,
            (column.Flags & ImGuiTableColumnFlags_WidthStretch) ? "WidthStretch " : "",
            (column.Flags & ImGuiTableColumnFlags_WidthFixed) ? "WidthFixed " : "",
            (column.Flags & ImGuiTableColumnFlags_NoResize) ? "NoResize " : "");
        Bullet();
        Selectable(buf);
        if (IsItemHovered())
        {
            r := ImRect(column.MinX, table.OuterRect.Min.y, column.MaxX, table.OuterRect.Max.y);
            GetForegroundDrawList()->AddRect(r.Min, r.Max, IM_COL32(255, 255, 0, 255));
        }
    }
    if (ImGuiTableSettings* settings = TableGetBoundSettings(table))
        DebugNodeTableSettings(settings);
    if (clear_settings)
        table.IsResetAllRequest = true;
    TreePop();
}

DebugNodeTableSettings :: proc(settings : ^ImGuiTableSettings)
{
    if (!TreeNode((rawptr)(intptr_t)settings.ID, "Settings 0x%08X (%d columns)", settings.ID, settings.ColumnsCount))
        return;
    BulletText("SaveFlags: 0x%08X", settings.SaveFlags);
    BulletText("ColumnsCount: %d (max %d)", settings.ColumnsCount, settings.ColumnsCountMax);
    for i32 n = 0; n < settings.ColumnsCount; n++
    {
        column_settings := &settings.GetColumnSettings()[n];
        sort_dir := (column_settings.SortOrder != -1) ? (ImGuiSortDirection)column_settings.SortDirection : ImGuiSortDirection_None;
        BulletText("Column %d Order %d SortOrder %d %s Vis %d %s %7.3 UserID 0x%08X",
            n, column_settings.DisplayOrder, column_settings.SortOrder,
            (sort_dir == ImGuiSortDirection_Ascending) ? "Asc" : (sort_dir == ImGuiSortDirection_Descending) ? "Des" : "---",
            column_settings.IsEnabled, column_settings.IsStretch ? "Weight" : "Width ", column_settings.WidthOrWeight, column_settings.UserID);
    }
    TreePop();
}

} else { // #ifndef IMGUI_DISABLE_DEBUG_TOOLS

void DebugNodeTable(ImGuiTable*) {}
void DebugNodeTableSettings(ImGuiTableSettings*) {}

}


//-------------------------------------------------------------------------
// [SECTION] Columns, BeginColumns, EndColumns, etc.
// (This is a legacy API, prefer using BeginTable/EndTable!)
//-------------------------------------------------------------------------
// FIXME: sizing is lossy when columns width is very small (default width may turn negative etc.)
//-------------------------------------------------------------------------
// - SetWindowClipRectBeforeSetChannel() [Internal]
// - GetColumnIndex()
// - GetColumnsCount()
// - GetColumnOffset()
// - GetColumnWidth()
// - SetColumnOffset()
// - SetColumnWidth()
// - PushColumnClipRect() [Internal]
// - PushColumnsBackground() [Internal]
// - PopColumnsBackground() [Internal]
// - FindOrCreateColumns() [Internal]
// - GetColumnsID() [Internal]
// - BeginColumns()
// - NextColumn()
// - EndColumns()
// - Columns()
//-------------------------------------------------------------------------

// [Internal] Small optimization to avoid calls to PopClipRect/SetCurrentChannel/PushClipRect in sequences,
// they would meddle many times with the underlying ImDrawCmd.
// Instead, we do a preemptive overwrite of clipping rectangle _without_ altering the command-buffer and let
// the subsequent single call to SetCurrentChannel() does it things once.
SetWindowClipRectBeforeSetChannel :: proc(window : ^ImGuiWindow, clip_rect : ^ImRect)
{
    clip_rect_vec4 := clip_rect.ToVec4();
    window.ClipRect = clip_rect;
    window.DrawList->_CmdHeader.ClipRect = clip_rect_vec4;
    window.DrawList->_ClipRectStack.Data[window.DrawList->_ClipRectStack.Size - 1] = clip_rect_vec4;
}

// [forward declared comment]:
// get current column index
GetColumnIndex :: proc() -> i32
{
    window := GetCurrentWindowRead();
    return window.DC.CurrentColumns ? window.DC.CurrentColumns.Current : 0;
}

GetColumnsCount :: proc() -> i32
{
    window := GetCurrentWindowRead();
    return window.DC.CurrentColumns ? window.DC.CurrentColumns.Count : 1;
}

GetColumnOffsetFromNorm :: proc(columns : ^ImGuiOldColumns, offset_norm : f32) -> f32
{
    return offset_norm * (columns.OffMaxX - columns.OffMinX);
}

GetColumnNormFromOffset :: proc(columns : ^ImGuiOldColumns, offset : f32) -> f32
{
    return offset / (columns.OffMaxX - columns.OffMinX);
}

COLUMNS_HIT_RECT_HALF_THICKNESS := 4.0;

GetDraggedColumnOffset :: proc(columns : ^ImGuiOldColumns, column_index : i32) -> f32
{
    // Active (dragged) column always follow mouse. The reason we need this is that dragging a column to the right edge of an auto-resizing
    // window creates a feedback loop because we store normalized positions. So while dragging we enforce absolute positioning.
    g := GImGui;
    window := g.CurrentWindow;
    assert(column_index > 0); // We are not supposed to drag column 0.
    assert(g.ActiveId == columns.ID + ImGuiID(column_index));

    x := g.IO.MousePos.x - g.ActiveIdClickOffset.x + ImTrunc(COLUMNS_HIT_RECT_HALF_THICKNESS * g.CurrentDpiScale) - window.Pos.x;
    x = ImMax(x, GetColumnOffset(column_index - 1) + g.Style.ColumnsMinSpacing);
    if ((columns.Flags & ImGuiOldColumnFlags_NoPreserveWidths))
        x = ImMin(x, GetColumnOffset(column_index + 1) - g.Style.ColumnsMinSpacing);

    return x;
}

// [forward declared comment]:
// get position of column line (in pixels, from the left side of the contents region). pass -1 to use current column, otherwise 0..GetColumnsCount() inclusive. column 0 is typically 0.0f
GetColumnOffset :: proc(column_index : i32 = -1) -> f32
{
    window := GetCurrentWindowRead();
    columns := window.DC.CurrentColumns;
    if (columns == nil)
        return 0.0;

    if (column_index < 0)
        column_index = columns.Current;
    assert(column_index < columns.Columns.Size);

    t := columns.Columns[column_index].OffsetNorm;
    x_offset := ImLerp(columns.OffMinX, columns.OffMaxX, t);
    return x_offset;
}

GetColumnWidthEx :: proc(columns : ^ImGuiOldColumns, column_index : i32, before_resize : bool = false) -> f32
{
    if (column_index < 0)
        column_index = columns.Current;

    offset_norm : f32
    if (before_resize)
        offset_norm = columns.Columns[column_index + 1].OffsetNormBeforeResize - columns.Columns[column_index].OffsetNormBeforeResize;
    else
        offset_norm = columns.Columns[column_index + 1].OffsetNorm - columns.Columns[column_index].OffsetNorm;
    return GetColumnOffsetFromNorm(columns, offset_norm);
}

// [forward declared comment]:
// get column width (in pixels). pass -1 to use current column
GetColumnWidth :: proc(column_index : i32 = -1) -> f32
{
    g := GImGui;
    window := g.CurrentWindow;
    columns := window.DC.CurrentColumns;
    if (columns == nil)
        return GetContentRegionAvail().x;

    if (column_index < 0)
        column_index = columns.Current;
    return GetColumnOffsetFromNorm(columns, columns.Columns[column_index + 1].OffsetNorm - columns.Columns[column_index].OffsetNorm);
}

// [forward declared comment]:
// set position of column line (in pixels, from the left side of the contents region). pass -1 to use current column
SetColumnOffset :: proc(column_index : i32, offset : f32)
{
    g := GImGui;
    window := g.CurrentWindow;
    columns := window.DC.CurrentColumns;
    assert(columns != nil);

    if (column_index < 0)
        column_index = columns.Current;
    assert(column_index < columns.Columns.Size);

    preserve_width := !(columns.Flags & ImGuiOldColumnFlags_NoPreserveWidths) && (column_index < columns.Count - 1);
    width := preserve_width ? GetColumnWidthEx(columns, column_index, columns.IsBeingResized) : 0.0;

    if (!(columns.Flags & ImGuiOldColumnFlags_NoForceWithinWindow))
        offset = ImMin(offset, columns.OffMaxX - g.Style.ColumnsMinSpacing * (columns.Count - column_index));
    columns.Columns[column_index].OffsetNorm = GetColumnNormFromOffset(columns, offset - columns.OffMinX);

    if (preserve_width)
        SetColumnOffset(column_index + 1, offset + ImMax(g.Style.ColumnsMinSpacing, width));
}

// [forward declared comment]:
// set column width (in pixels). pass -1 to use current column
SetColumnWidth :: proc(column_index : i32, width : f32)
{
    window := GetCurrentWindowRead();
    columns := window.DC.CurrentColumns;
    assert(columns != nil);

    if (column_index < 0)
        column_index = columns.Current;
    SetColumnOffset(column_index + 1, GetColumnOffset(column_index) + width);
}

PushColumnClipRect :: proc(column_index : i32)
{
    window := GetCurrentWindowRead();
    columns := window.DC.CurrentColumns;
    if (column_index < 0)
        column_index = columns.Current;

    column := &columns.Columns[column_index];
    PushClipRect(column.ClipRect.Min, column.ClipRect.Max, false);
}

// Get into the columns background draw command (which is generally the same draw command as before we called BeginColumns)
PushColumnsBackground :: proc()
{
    window := GetCurrentWindowRead();
    columns := window.DC.CurrentColumns;
    if (columns.Count == 1)
        return;

    // Optimization: avoid SetCurrentChannel() + PushClipRect()
    columns.HostBackupClipRect = window.ClipRect;
    SetWindowClipRectBeforeSetChannel(window, columns.HostInitialClipRect);
    columns.Splitter.SetCurrentChannel(window.DrawList, 0);
}

PopColumnsBackground :: proc()
{
    window := GetCurrentWindowRead();
    columns := window.DC.CurrentColumns;
    if (columns.Count == 1)
        return;

    // Optimization: avoid PopClipRect() + SetCurrentChannel()
    SetWindowClipRectBeforeSetChannel(window, columns.HostBackupClipRect);
    columns.Splitter.SetCurrentChannel(window.DrawList, columns.Current + 1);
}

FindOrCreateColumns :: proc(window : ^ImGuiWindow, id : ImGuiID) -> ^ImGuiOldColumns
{
    // We have few columns per window so for now we don't need bother much with turning this into a faster lookup.
    for i32 n = 0; n < window.ColumnsStorage.Size; n++
        if (window.ColumnsStorage[n].ID == id)
            return &window.ColumnsStorage[n];

    window.ColumnsStorage.push_back(ImGuiOldColumns());
    columns := &window.ColumnsStorage.back();
    columns.ID = id;
    return columns;
}

GetColumnsID := ImGuiID(const u8* str_id, i32 columns_count)
{
    window := GetCurrentWindow();

    // Differentiate column ID with an arbitrary prefix for cases where users name their columns set the same as another widget.
    // In addition, when an identifier isn't explicitly provided we include the number of columns in the hash to make it uniquer.
    PushID(0x11223347 + (str_id ? 0 : columns_count));
    id := window.GetID(str_id ? str_id : "columns");
    PopID();

    return id;
}

// [forward declared comment]:
// setup number of columns. use an identifier to distinguish multiple column sets. close with EndColumns().
BeginColumns :: proc(str_id : ^u8, columns_count : i32, flags : ImGuiOldColumnFlags = {})
{
    g := GImGui;
    window := GetCurrentWindow();

    assert(columns_count >= 1);
    assert(window.DC.CurrentColumns == nil);   // Nested columns are currently not supported

    // Acquire storage for the columns set
    id := GetColumnsID(str_id, columns_count);
    columns := FindOrCreateColumns(window, id);
    assert(columns.ID == id);
    columns.Current = 0;
    columns.Count = columns_count;
    columns.Flags = flags;
    window.DC.CurrentColumns = columns;
    window.DC.NavIsScrollPushableX = false; // Shortcut for NavUpdateCurrentWindowIsScrollPushableX();

    columns.HostCursorPosY = window.DC.CursorPos.y;
    columns.HostCursorMaxPosX = window.DC.CursorMaxPos.x;
    columns.HostInitialClipRect = window.ClipRect;
    columns.HostBackupParentWorkRect = window.ParentWorkRect;
    window.ParentWorkRect = window.WorkRect;

    // Set state for first column
    // We aim so that the right-most column will have the same clipping width as other after being clipped by parent ClipRect
    column_padding := g.Style.ItemSpacing.x;
    half_clip_extend_x := ImTrunc(ImMax(window.WindowPadding.x * 0.5, window.WindowBorderSize));
    max_1 := window.WorkRect.Max.x + column_padding - ImMax(column_padding - window.WindowPadding.x, 0.0);
    max_2 := window.WorkRect.Max.x + half_clip_extend_x;
    columns.OffMinX = window.DC.Indent.x - column_padding + ImMax(column_padding - window.WindowPadding.x, 0.0);
    columns.OffMaxX = ImMax(ImMin(max_1, max_2) - window.Pos.x, columns.OffMinX + 1.0);
    columns.LineMinY = columns.LineMaxY = window.DC.CursorPos.y;

    // Clear data if columns count changed
    if (columns.Columns.Size != 0 && columns.Columns.Size != columns_count + 1)
        columns.Columns.resize(0);

    // Initialize default widths
    columns.IsFirstFrame = (columns.Columns.Size == 0);
    if (columns.Columns.Size == 0)
    {
        columns.Columns.reserve(columns_count + 1);
        for i32 n = 0; n < columns_count + 1; n++
        {
            column : ImGuiOldColumnData
            column.OffsetNorm = n / cast(ast) ast) ns_countc
            columns.Columns.push_back(column);
        }
    }

    for i32 n = 0; n < columns_count; n++
    {
        // Compute clipping rectangle
        column := &columns.Columns[n];
        clip_x1 := math.round(window.Pos.x + GetColumnOffset(n));
        clip_x2 := math.round(window.Pos.x + GetColumnOffset(n + 1) - 1.0);
        column.ClipRect = ImRect(clip_x1, -math.F32_MAX, clip_x2, +math.F32_MAX);
        column.ClipRect.ClipWithFull(window.ClipRect);
    }

    if (columns.Count > 1)
    {
        columns.Splitter.Split(window.DrawList, 1 + columns.Count);
        columns.Splitter.SetCurrentChannel(window.DrawList, 1);
        PushColumnClipRect(0);
    }

    // We don't generally store Indent.x inside ColumnsOffset because it may be manipulated by the user.
    offset_0 := GetColumnOffset(columns.Current);
    offset_1 := GetColumnOffset(columns.Current + 1);
    width := offset_1 - offset_0;
    PushItemWidth(width * 0.65);
    window.DC.ColumnsOffset.x = ImMax(column_padding - window.WindowPadding.x, 0.0);
    window.DC.CursorPos.x = math.trunc(window.Pos.x + window.DC.Indent.x + window.DC.ColumnsOffset.x);
    window.WorkRect.Max.x = window.Pos.x + offset_1 - column_padding;
    window.WorkRect.Max.y = window.ContentRegionRect.Max.y;
}

// [forward declared comment]:
// next column, defaults to current row or next row if the current row is finished
NextColumn :: proc()
{
    window := GetCurrentWindow();
    if (window.SkipItems || window.DC.CurrentColumns == nil)
        return;

    g := GImGui;
    columns := window.DC.CurrentColumns;

    if (columns.Count == 1)
    {
        window.DC.CursorPos.x = math.trunc(window.Pos.x + window.DC.Indent.x + window.DC.ColumnsOffset.x);
        assert(columns.Current == 0);
        return;
    }

    // Next column
    if (++columns.Current == columns.Count)
        columns.Current = 0;

    PopItemWidth();

    // Optimization: avoid PopClipRect() + SetCurrentChannel() + PushClipRect()
    // (which would needlessly attempt to update commands in the wrong channel, then pop or overwrite them),
    column := &columns.Columns[columns.Current];
    SetWindowClipRectBeforeSetChannel(window, column.ClipRect);
    columns.Splitter.SetCurrentChannel(window.DrawList, columns.Current + 1);

    column_padding := g.Style.ItemSpacing.x;
    columns.LineMaxY = ImMax(columns.LineMaxY, window.DC.CursorPos.y);
    if (columns.Current > 0)
    {
        // Columns 1+ ignore IndentX (by canceling it out)
        // FIXME-COLUMNS: Unnecessary, could be locked?
        window.DC.ColumnsOffset.x = GetColumnOffset(columns.Current) - window.DC.Indent.x + column_padding;
    }
    else
    {
        // New row/line: column 0 honor IndentX.
        window.DC.ColumnsOffset.x = ImMax(column_padding - window.WindowPadding.x, 0.0);
        window.DC.IsSameLine = false;
        columns.LineMinY = columns.LineMaxY;
    }
    window.DC.CursorPos.x = math.trunc(window.Pos.x + window.DC.Indent.x + window.DC.ColumnsOffset.x);
    window.DC.CursorPos.y = columns.LineMinY;
    window.DC.CurrLineSize = ImVec2{0.0, 0.0};
    window.DC.CurrLineTextBaseOffset = 0.0;

    // FIXME-COLUMNS: Share code with BeginColumns() - move code on columns setup.
    offset_0 := GetColumnOffset(columns.Current);
    offset_1 := GetColumnOffset(columns.Current + 1);
    width := offset_1 - offset_0;
    PushItemWidth(width * 0.65);
    window.WorkRect.Max.x = window.Pos.x + offset_1 - column_padding;
}

// [forward declared comment]:
// close columns
EndColumns :: proc()
{
    g := GImGui;
    window := GetCurrentWindow();
    columns := window.DC.CurrentColumns;
    assert(columns != nil);

    PopItemWidth();
    if (columns.Count > 1)
    {
        PopClipRect();
        columns.Splitter.Merge(window.DrawList);
    }

    flags := columns.Flags;
    columns.LineMaxY = ImMax(columns.LineMaxY, window.DC.CursorPos.y);
    window.DC.CursorPos.y = columns.LineMaxY;
    if (!(flags & ImGuiOldColumnFlags_GrowParentContentsSize))
        window.DC.CursorMaxPos.x = columns.HostCursorMaxPosX;  // Restore cursor max pos, as columns don't grow parent

    // Draw columns borders and handle resize
    // The IsBeingResized flag ensure we preserve pre-resize columns width so back-and-forth are not lossy
    is_being_resized := false;
    if (!(flags & ImGuiOldColumnFlags_NoBorder) && !window.SkipItems)
    {
        // We clip Y boundaries CPU side because very long triangles are mishandled by some GPU drivers.
        y1 := ImMax(columns.HostCursorPosY, window.ClipRect.Min.y);
        y2 := ImMin(window.DC.CursorPos.y, window.ClipRect.Max.y);
        dragging_column := -1;
        for i32 n = 1; n < columns.Count; n++
        {
            column := &columns.Columns[n];
            x := window.Pos.x + GetColumnOffset(n);
            column_id := columns.ID + ImGuiID(n);
            column_hit_hw := ImTrunc(COLUMNS_HIT_RECT_HALF_THICKNESS * g.CurrentDpiScale);
            column_hit_rect := ImRect(ImVec2{x - column_hit_hw, y1}, ImVec2{x + column_hit_hw, y2});
            if (!ItemAdd(column_hit_rect, column_id, nil, ImGuiItemFlags_NoNav))
                continue;

            hovered := false, held = false;
            if (!(flags & ImGuiOldColumnFlags_NoResize))
            {
                ButtonBehavior(column_hit_rect, column_id, &hovered, &held);
                if (hovered || held)
                    SetMouseCursor(ImGuiMouseCursor_ResizeEW);
                if (held && !(column.Flags & ImGuiOldColumnFlags_NoResize))
                    dragging_column = n;
            }

            // Draw column
            col := GetColorU32(held ? ImGuiCol_SeparatorActive : hovered ? ImGuiCol_SeparatorHovered : ImGuiCol_Separator);
            xi := math.trunc(x);
            window.DrawList->AddLine(ImVec2{xi, y1 + 1.0}, ImVec2{xi, y2}, col);
        }

        // Apply dragging after drawing the column lines, so our rendered lines are in sync with how items were displayed during the frame.
        if (dragging_column != -1)
        {
            if (!columns.IsBeingResized)
                for i32 n = 0; n < columns.Count + 1; n++
                    columns.Columns[n].OffsetNormBeforeResize = columns.Columns[n].OffsetNorm;
            columns.IsBeingResized = is_being_resized = true;
            x := GetDraggedColumnOffset(columns, dragging_column);
            SetColumnOffset(dragging_column, x);
        }
    }
    columns.IsBeingResized = is_being_resized;

    window.WorkRect = window.ParentWorkRect;
    window.ParentWorkRect = columns.HostBackupParentWorkRect;
    window.DC.CurrentColumns = nil;
    window.DC.ColumnsOffset.x = 0.0;
    window.DC.CursorPos.x = math.trunc(window.Pos.x + window.DC.Indent.x + window.DC.ColumnsOffset.x);
    NavUpdateCurrentWindowIsScrollPushableX();
}

Columns :: proc(columns_count : i32 = 1, id : ^u8 = nil, borders : bool = true)
{
    window := GetCurrentWindow();
    assert(columns_count >= 1);

    flags := (borders ? 0 : ImGuiOldColumnFlags_NoBorder);
    //flags |= ImGuiOldColumnFlags_NoPreserveWidths; // NB: Legacy behavior
    columns := window.DC.CurrentColumns;
    if (columns != nil && columns.Count == columns_count && columns.Flags == flags)
        return;

    if (columns != nil)
        EndColumns();

    if (columns_count != 1)
        BeginColumns(id, columns_count, flags);
}

//-------------------------------------------------------------------------

} // #ifndef IMGUI_DISABLE
