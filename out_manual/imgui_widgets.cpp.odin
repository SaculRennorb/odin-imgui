package imgui

// dear imgui, v1.91.7 WIP
// (widgets code)

/*

Index of this file:

// [SECTION] Forward Declarations
// [SECTION] Widgets: Text, etc.
// [SECTION] Widgets: Main (Button, Image, Checkbox, RadioButton, ProgressBar, Bullet, etc.)
// [SECTION] Widgets: Low-level Layout helpers (Spacing, Dummy, NewLine, Separator, etc.)
// [SECTION] Widgets: ComboBox
// [SECTION] Data Type and Data Formatting Helpers
// [SECTION] Widgets: DragScalar, DragFloat, DragInt, etc.
// [SECTION] Widgets: SliderScalar, SliderFloat, SliderInt, etc.
// [SECTION] Widgets: InputScalar, InputFloat, InputInt, etc.
// [SECTION] Widgets: InputText, InputTextMultiline
// [SECTION] Widgets: ColorEdit, ColorPicker, ColorButton, etc.
// [SECTION] Widgets: TreeNode, CollapsingHeader, etc.
// [SECTION] Widgets: Selectable
// [SECTION] Widgets: Typing-Select support
// [SECTION] Widgets: Box-Select support
// [SECTION] Widgets: Multi-Select support
// [SECTION] Widgets: Multi-Select helpers
// [SECTION] Widgets: ListBox
// [SECTION] Widgets: PlotLines, PlotHistogram
// [SECTION] Widgets: Value helpers
// [SECTION] Widgets: MenuItem, BeginMenu, EndMenu, etc.
// [SECTION] Widgets: BeginTabBar, EndTabBar, etc.
// [SECTION] Widgets: BeginTabItem, EndTabItem, etc.
// [SECTION] Widgets: Columns, BeginColumns, EndColumns, etc.

*/

import "core:math"

//-------------------------------------------------------------------------
// Data
//-------------------------------------------------------------------------

// Widgets
DRAGDROP_HOLD_TO_OPEN_TIMER : f32 = 0.70;    // Time for drag-hold to activate items accepting the ImGuiButtonFlags_PressedOnDragDropHold button behavior.
DRAG_MOUSE_THRESHOLD_FACTOR : f32 = 0.50;    // Multiplier for the default value of io.MouseDragThreshold to make DragFloat/DragInt react faster to mouse drags.

// Those MIN/MAX values are not define because we need to point to them
IM_S8_MIN : i8  = min(i8);
IM_S8_MAX : i8  = max(i8);
IM_U8_MIN : u8  = min(u8);
IM_U8_MAX : u8  = max(u8);
IM_S16_MIN : i16 = min(i16);
IM_S16_MAX : i16 = max(i16);
IM_U16_MIN : u16 = min(u16);
IM_U16_MAX : u16 = max(u16);
IM_S32_MIN : i32 = min(i32);    // (-2147483647 - 1), (0x80000000);
IM_S32_MAX : i32 = max(i32);    // (2147483647), (0x7FFFFFFF)
IM_U32_MIN : u32 = min(u32);
IM_U32_MAX : u32 = max(u32);   // (0xFFFFFFFF)
IM_S64_MIN : i64 = min(i64);
IM_S64_MAX : i64 = max(i64);

IM_U64_MIN : u64 = min(u64);
IM_U64_MAX : u64 = max(u64); // (0xFFFFFFFFFFFFFFFFull);

//-------------------------------------------------------------------------
// [SECTION] Forward Declarations
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
// [SECTION] Widgets: Text, etc.
//-------------------------------------------------------------------------
// - TextEx() [Internal]
// - TextUnformatted()
// - Text()
// - TextV()
// - TextColored()
// - TextColoredV()
// - TextDisabled()
// - TextDisabledV()
// - TextWrapped()
// - TextWrappedV()
// - LabelText()
// - LabelTextV()
// - BulletText()
// - BulletTextV()
//-------------------------------------------------------------------------

TextEx :: proc(text : string, flags : ImGuiTextFlags)
{
    window := GetCurrentWindow();
    if (window.SkipItems) do return;
    g := GImGui;

    text_pos := ImVec2{window.DC.CursorPos.x, window.DC.CursorPos.y + window.DC.CurrLineTextBaseOffset};
    wrap_pos_x := window.DC.TextWrapPos;
    wrap_enabled := (wrap_pos_x >= 0.0);
    if (len(text) <= 2000 || wrap_enabled)
    {
        // Common case
        wrap_width := wrap_enabled ? CalcWrapWidthForPos(window.DC.CursorPos, wrap_pos_x) : 0.0;
        text_size := CalcTextSize(text, false, wrap_width);

        bb := ImRect{ _v = {text_pos, text_pos + text_size} };
        ItemSize(text_size, 0.0);
        if (!ItemAdd(bb, 0)) do return;

        // Render (we don't hide text after ## in this end-user function)
        RenderTextWrapped(bb.Min, text, wrap_width);
    }
    else
    {
        text_end := end(text)
        // Long text!
        // Perform manual coarse clipping to optimize for long multi-line text
        // - From this point we will only compute the width of lines that are visible. Optimization only available when word-wrapping is disabled.
        // - We also don't vertically center the text within the line full height, which is unlikely to matter because we are likely the biggest and only item on the line.
        // - We use memchr(), pay attention that well optimized versions of those str/mem functions are much faster than a casually written loop.
        line : [^]u8 = raw_data(text);
        line_height := GetTextLineHeight();
        text_size := ImVec2{0, 0};

        // Lines to skip (can't skip when logging text)
        pos := text_pos;
        if (!g.LogEnabled)
        {
            lines_skippable := (int)((window.ClipRect.Min.y - text_pos.y) / line_height);
            if (lines_skippable > 0)
            {
                lines_skipped := 0;
                for (line < text_end && lines_skipped < lines_skippable)
                {
                    line_end : [^]u8 = memchr_end(line, '\n', text_end);
                    if (line_end == nil)  do  line_end = text_end;
                    if ((.NoWidthForLargeClippedText not_in flags)) {
                        text_size.x = ImMax(text_size.x, CalcTextSize(string_from_start_end(line, line_end)).x);
                    }
                    line = line_end[1:];
                    lines_skipped += 1;
                }
                pos.y += lines_skipped * line_height;
            }
        }

        // Lines to render
        if (line < text_end)
        {
            line_rect := ImRect{_v = {pos, pos + ImVec2{math.F32_MAX, line_height}}};
            for (line < text_end)
            {
                if (IsClippedEx(line_rect, 0)) do break;

                line_end : [^]u8 = memchr_end(line, '\n', text_end);
                if (line_end == nil) do line_end = text_end;
                l := string_from_start_end(line, line_end)
                text_size.x = ImMax(text_size.x, CalcTextSize(l).x);
                RenderText(pos, l, false);
                line = line_end[1:];
                line_rect.Min.y += line_height;
                line_rect.Max.y += line_height;
                pos.y += line_height;
            }

            // Count remaining lines
            lines_skipped := 0;
            for (line < text_end)
            {
                line_end : ^u8 = memchr_end(line, '\n', text_end);
                if (line_end == nil) do line_end = text_end;
                if ((.NoWidthForLargeClippedText not_in flags)) {
                    text_size.x = ImMax(text_size.x, CalcTextSize(string_from_start_end(line, line_end)).x);
                }
                line = line_end[1:]
                lines_skipped += 1;
            }
            pos.y += lines_skipped * line_height;
        }
        text_size.y = (pos - text_pos).y;

        bb := ImRect{text_pos, text_pos + text_size};
        ItemSize(text_size, 0.0);
        ItemAdd(bb, 0);
    }
}

// [forward declared comment]:
// raw text without formatting. Roughly equivalent to Text("%s", text) but: A) doesn't require null terminated string if 'text_end' is specified, B) it's faster, no memory copy is done, no buffer size limits, recommended for long chunks of text.
TextUnformatted :: proc(text : string)
{
    TextEx(text, {.NoWidthForLargeClippedText});
}

// [forward declared comment]:
// formatted text
Text :: proc(fmt : string, args : ..any)
{
    window := GetCurrentWindow();
    if (window.SkipItems) do return;

    text := ImFormatStringToTempBuffer(fmt, args);
    TextEx(text, {.NoWidthForLargeClippedText});
}

// [forward declared comment]:
// shortcut for PushStyleColor(ImGuiCol.Text, col); Text(fmt, args : ..any); PopStyleColor();
TextColored :: proc(col : ImVec4, fmt : string, args : ..any)
{
    PushStyleColor(ImGuiCol.Text, col);
    Text(fmt, args);
    PopStyleColor();
}

// [forward declared comment]:
// shortcut for PushStyleColor(ImGuiCol.Text, style.Colors[ImGuiCol.TextDisabled]); Text(fmt, args : ..any); PopStyleColor();
TextDisabled :: proc(fmt : string, args : ..any)
{
    g := GImGui;
    PushStyleColor(ImGuiCol.Text, g.Style.Colors[ImGuiCol.TextDisabled]);
    Text(fmt, args);
    PopStyleColor();
}

// [forward declared comment]:
// shortcut for PushTextWrapPos(0.0f); Text(fmt, args : ..any); PopTextWrapPos();. Note that this won't work on an auto-resizing window if there's no other widgets to extend the window width, yoy may need to set a size using SetNextWindowSize().
TextWrapped :: proc(fmt : string, args : ..any)
{
    g := GImGui;
    need_backup := (g.CurrentWindow.DC.TextWrapPos < 0.0);  // Keep existing wrap position if one is already set
    if (need_backup) do PushTextWrapPos(0.0);
    TextV(fmt, args);
    if (need_backup) do PopTextWrapPos();
}

// [forward declared comment]:
// display text+label aligned the same way as value+label widgets
// Add a label+text combo aligned to other label+value widgets
LabelText :: proc(label : string, fmt : string, args : ..any)
{
    window := GetCurrentWindow();
    if (window.SkipItems) do return;

    g := GImGui;
    style := &g.Style;
    w := CalcItemWidth();

    value_text := ImFormatStringToTempBuffer(fmt, args);
    value_size := CalcTextSize(value_text, false);
    label_size := CalcTextSize(label, true);

    pos := window.DC.CursorPos;
    value_bb := ImRect(pos, pos + ImVec2{w, value_size.y + style.FramePadding.y * 2});
    total_bb := ImRect(pos, pos + ImVec2{w + (label_size.x > 0.0 ? style.ItemInnerSpacing.x + label_size.x : 0.0), ImMax(value_size.y, label_size.y) + style.FramePadding.y * 2});
    ItemSize(total_bb, style.FramePadding.y);
    if (!ItemAdd(total_bb, 0))  do return;

    // Render
    RenderTextClipped(value_bb.Min + style.FramePadding, value_bb.Max, value_text, &value_size, ImVec2{0.0, 0.0});
    if (label_size.x > 0.0)  do RenderText(ImVec2{value_bb.Max.x + style.ItemInnerSpacing.x, value_bb.Min.y + style.FramePadding.y}, label);
}

// Text with a little bullet aligned to the typical tree node.
// [forward declared comment]:
// shortcut for Bullet()+Text()
BulletText :: proc(fmt : string, args : ..any)
{
    window := GetCurrentWindow();
    if (window.SkipItems)  do return;

    g := GImGui;
    style := &g.Style;

    text := ImFormatStringToTempBuffer(fmt, args);
    label_size := CalcTextSize(text, false);
    total_size := ImVec2{g.FontSize + (label_size.x > 0.0 ? (label_size.x + style.FramePadding.x * 2) : 0.0), label_size.y};  // Empty text doesn't add padding
    pos := window.DC.CursorPos;
    pos.y += window.DC.CurrLineTextBaseOffset;
    ItemSize(total_size, 0.0);
    bb := ImRect{ _v = {pos, pos + total_size} };
    if (!ItemAdd(bb, 0))  do return;

    // Render
    text_col := GetColorU32(ImGuiCol.Text);
    RenderBullet(window.DrawList, bb.Min + ImVec2{style.FramePadding.x + g.FontSize * 0.5, g.FontSize * 0.5}, text_col);
    RenderText(bb.Min + ImVec2{g.FontSize + style.FramePadding.x * 2, 0.0}, text, false);
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: Main
//-------------------------------------------------------------------------
// - ButtonBehavior() [Internal]
// - Button()
// - SmallButton()
// - InvisibleButton()
// - ArrowButton()
// - CloseButton() [Internal]
// - CollapseButton() [Internal]
// - GetWindowScrollbarID() [Internal]
// - GetWindowScrollbarRect() [Internal]
// - Scrollbar() [Internal]
// - ScrollbarEx() [Internal]
// - Image()
// - ImageButton()
// - Checkbox()
// - CheckboxFlagsT() [Internal]
// - CheckboxFlags()
// - RadioButton()
// - ProgressBar()
// - Bullet()
// - Hyperlink()
//-------------------------------------------------------------------------

// The ButtonBehavior() function is key to many interactions and used by many/most widgets.
// Because we handle so many cases (keyboard/gamepad navigation, drag and drop) and many specific behavior (via ImGuiButtonFlags_),
// this code is a little complex.
// By far the most common path is interacting with the Mouse using the default ImGuiButtonFlags_PressedOnClickRelease button behavior.
// See the series of events below and the corresponding state reported by dear imgui:
//------------------------------------------------------------------------------------------------------------------------------------------------
// with PressedOnClickRelease:             return-value  IsItemHovered()  IsItemActive()  IsItemActivated()  IsItemDeactivated()  IsItemClicked()
//   Frame N+0 (mouse is outside bb)        -             -                -               -                  -                    -
//   Frame N+1 (mouse moves inside bb)      -             true             -               -                  -                    -
//   Frame N+2 (mouse button is down)       -             true             true            true               -                    true
//   Frame N+3 (mouse button is down)       -             true             true            -                  -                    -
//   Frame N+4 (mouse moves outside bb)     -             -                true            -                  -                    -
//   Frame N+5 (mouse moves inside bb)      -             true             true            -                  -                    -
//   Frame N+6 (mouse button is released)   true          true             -               -                  true                 -
//   Frame N+7 (mouse button is released)   -             true             -               -                  -                    -
//   Frame N+8 (mouse moves outside bb)     -             -                -               -                  -                    -
//------------------------------------------------------------------------------------------------------------------------------------------------
// with PressedOnClick:                    return-value  IsItemHovered()  IsItemActive()  IsItemActivated()  IsItemDeactivated()  IsItemClicked()
//   Frame N+2 (mouse button is down)       true          true             true            true               -                    true
//   Frame N+3 (mouse button is down)       -             true             true            -                  -                    -
//   Frame N+6 (mouse button is released)   -             true             -               -                  true                 -
//   Frame N+7 (mouse button is released)   -             true             -               -                  -                    -
//------------------------------------------------------------------------------------------------------------------------------------------------
// with PressedOnRelease:                  return-value  IsItemHovered()  IsItemActive()  IsItemActivated()  IsItemDeactivated()  IsItemClicked()
//   Frame N+2 (mouse button is down)       -             true             -               -                  -                    true
//   Frame N+3 (mouse button is down)       -             true             -               -                  -                    -
//   Frame N+6 (mouse button is released)   true          true             -               -                  -                    -
//   Frame N+7 (mouse button is released)   -             true             -               -                  -                    -
//------------------------------------------------------------------------------------------------------------------------------------------------
// with PressedOnDoubleClick:              return-value  IsItemHovered()  IsItemActive()  IsItemActivated()  IsItemDeactivated()  IsItemClicked()
//   Frame N+0 (mouse button is down)       -             true             -               -                  -                    true
//   Frame N+1 (mouse button is down)       -             true             -               -                  -                    -
//   Frame N+2 (mouse button is released)   -             true             -               -                  -                    -
//   Frame N+3 (mouse button is released)   -             true             -               -                  -                    -
//   Frame N+4 (mouse button is down)       true          true             true            true               -                    true
//   Frame N+5 (mouse button is down)       -             true             true            -                  -                    -
//   Frame N+6 (mouse button is released)   -             true             -               -                  true                 -
//   Frame N+7 (mouse button is released)   -             true             -               -                  -                    -
//------------------------------------------------------------------------------------------------------------------------------------------------
// Note that some combinations are supported,
// - PressedOnDragDropHold can generally be associated with any flag.
// - PressedOnDoubleClick can be associated by PressedOnClickRelease/PressedOnRelease, in which case the second release event won't be reported.
//------------------------------------------------------------------------------------------------------------------------------------------------
// The behavior of the return-value changes when ImGuiItemFlags_ButtonRepeat is set:
//                                         Repeat+                  Repeat+           Repeat+             Repeat+
//                                         PressedOnClickRelease    PressedOnClick    PressedOnRelease    PressedOnDoubleClick
//-------------------------------------------------------------------------------------------------------------------------------------------------
//   Frame N+0 (mouse button is down)       -                        true              -                   true
//   ...                                    -                        -                 -                   -
//   Frame N + RepeatDelay                  true                     true              -                   true
//   ...                                    -                        -                 -                   -
//   Frame N + RepeatDelay + RepeatRate*N   true                     true              -                   true
//-------------------------------------------------------------------------------------------------------------------------------------------------

// - FIXME: For refactor we could output flags, incl mouse hovered vs nav keyboard vs nav triggered etc.
//   And better standardize how widgets use 'GetColor32((held && hovered) ? ... : hovered ? ...)' vs 'GetColor32(held ? ... : hovered ? ...);'
//   For mouse feedback we typically prefer the 'held && hovered' test, but for nav feedback not always. Outputting hovered=true on Activation may be misleading.
// - Since v1.91.2 (Sept 2024) we included io.ConfigDebugHighlightIdConflicts feature.
//   One idiom which was previously valid which will now emit a warning is when using multiple overlayed ButtonBehavior()
//   with same ID and different MouseButton (see #8030). You can fix it by:
//       (1) switching to use a single ButtonBehavior() with multiple _MouseButton flags.
//    or (2) surrounding those calls with PushItemFlag(ImGuiItemFlags_AllowDuplicateId, true); ... PopItemFlag()
ButtonBehavior :: proc(bb : ImRect, id : ImGuiID, out_hovered : ^bool, out_held : ^bool, flags : ImGuiButtonFlags = {}) -> bool
{
    g := GImGui;
    window := GetCurrentWindow();
    
    flags := flags
    // Default behavior inherited from item flags
    // Note that _both_ ButtonFlags and ItemFlags are valid sources, so copy one into the item_flags and only check that.
    item_flags := (g.LastItemData.ID == id ? g.LastItemData.ItemFlags : g.CurrentItemFlags);
    if (flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.AllowOverlap != nil) {
        item_flags |= transmute(ImGuiItemFlags) ImGuiItemFlagsPrivate.AllowOverlap;
    }

    // Default only reacts to left mouse button
    if ((flags & ImGuiButtonFlags_MouseButtonMask_) == nil) {
        flags |= {.MouseButtonLeft};
    }

    // Default behavior requires click + release inside bounding box
    if ((flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.PressedOnMask_) == nil) {
        flags |= transmute(ImGuiButtonFlags) ((.ButtonRepeat in item_flags) ?  ImGuiButtonFlagsPrivate.PressedOnClick : ImGuiButtonFlagsPrivate.PressedOnDefault_);
    }

    backup_hovered_window := g.HoveredWindow;
    flatten_hovered_children := (flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.FlattenChildren != nil) && g.HoveredWindow != nil && g.HoveredWindow.RootWindowDockTree == window.RootWindowDockTree;
    if (flatten_hovered_children) do g.HoveredWindow = window;

when IMGUI_ENABLE_TEST_ENGINE {
    // Alternate registration spot, for when caller didn't use ItemAdd()
    if (g.LastItemData.ID != id) do IMGUI_TEST_ENGINE_ITEM_ADD(id, bb, nil);
}

    pressed := false;
    hovered := ItemHoverable(bb, id, item_flags);

    // Special mode for Drag and Drop where holding button pressed for a long time while dragging another item triggers the button
    if (g.DragDropActive && (flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.PressedOnDragDropHold != nil) && !(.SourceNoHoldToOpenOthers in g.DragDropSourceFlags)) {
        if (IsItemHovered({.AllowWhenBlockedByActiveItem}))
        {
            hovered = true;
            SetHoveredID(id);
            if (g.HoveredIdTimer - g.IO.DeltaTime <= DRAGDROP_HOLD_TO_OPEN_TIMER && g.HoveredIdTimer >= DRAGDROP_HOLD_TO_OPEN_TIMER)
            {
                pressed = true;
                g.DragDropHoldJustPressedId = id;
                FocusWindow(window);
            }
        }
    }

    if (flatten_hovered_children) do g.HoveredWindow = backup_hovered_window;

    // Mouse handling
    test_owner_id := (flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.NoTestKeyOwner) ? ImGuiKeyOwner_Any : id;
    if (hovered)
    {
        assert(id != 0); // Lazily check inside rare path.

        INVALID_BTN :: ImGuiMouseButton(-1)

        // Poll mouse buttons
        // - 'mouse_button_clicked' is generally carried into ActiveIdMouseButton when setting ActiveId.
        // - Technically we only need some values in one code path, but since this is gated by hovered test this is fine.
        mouse_button_clicked := INVALID_BTN;
        mouse_button_released := INVALID_BTN;
        for button := ImGuiMouseButton(0); button < ImGuiMouseButton(3); button += ImGuiMouseButton(1) {
            if (flags & transmute(ImGuiButtonFlags) (transmute(u32) ImGuiButtonFlags{.MouseButtonLeft} << u32(button)) != nil) // Handle ImGuiButtonFlags_MouseButtonRight and ImGuiButtonFlags_MouseButtonMiddle here.
            {
                if (IsMouseClicked(button, nil, test_owner_id) && mouse_button_clicked == INVALID_BTN) { mouse_button_clicked = button; }
                if (IsMouseReleased(button, test_owner_id) && mouse_button_released == INVALID_BTN) { mouse_button_released = button; }
            }
        }

        // Process initial action
        mods_ok := !(flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.NoKeyModsAllowed != nil) || (!g.IO.KeyCtrl && !g.IO.KeyShift && !g.IO.KeyAlt);
        if (mods_ok)
        {
            if (mouse_button_clicked != INVALID_BTN && g.ActiveId != id)
            {
                if (!(flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.NoSetKeyOwner != nil)) {
                    SetKeyOwner(MouseButtonToKey(mouse_button_clicked), id);
                }
                if (flags & transmute(ImGuiButtonFlags) (ImGuiButtonFlagsPrivate.PressedOnClickRelease | ImGuiButtonFlagsPrivate.PressedOnClickReleaseAnywhere) != nil)
                {
                    SetActiveID(id, window);
                    g.ActiveIdMouseButton = cast(i32) mouse_button_clicked;
                    if (!(flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.NoNavFocus != nil))
                    {
                        SetFocusID(id, window);
                        FocusWindow(window);
                    }
                    else
                    {
                        FocusWindow(window, .RestoreFocusedChild); // Still need to focus and bring to front, but try to avoid losing NavId when navigating a child
                    }
                }
                if ((flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.PressedOnClick != nil) || ((flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.PressedOnDoubleClick != nil) && g.IO.MouseClickedCount[mouse_button_clicked] == 2))
                {
                    pressed = true;
                    if (flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.NoHoldingActiveId != nil) do ClearActiveID();
                    else do SetActiveID(id, window); // Hold on ID

                    g.ActiveIdMouseButton = cast(i32) mouse_button_clicked;
                    if (!(flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.NoNavFocus != nil))
                    {
                        SetFocusID(id, window);
                        FocusWindow(window);
                    }
                    else
                    {
                        FocusWindow(window, .RestoreFocusedChild); // Still need to focus and bring to front, but try to avoid losing NavId when navigating a child
                    }
                }
            }
            if (flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.PressedOnRelease != nil)
            {
                if (mouse_button_released != ImGuiMouseButton(-1))
                {
                    has_repeated_at_least_once := (.ButtonRepeat in item_flags) && g.IO.MouseDownDurationPrev[mouse_button_released] >= g.IO.KeyRepeatDelay; // Repeat mode trumps on release behavior
                    if (!has_repeated_at_least_once) do pressed = true;
                    if (!(flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.NoNavFocus != nil)) do SetFocusID(id, window); // FIXME: Lack of FocusWindow() call here is inconsistent with other paths. Research why.
                    ClearActiveID();
                }
            }

            // 'Repeat' mode acts when held regardless of _PressedOn flags (see table above).
            // Relies on repeat logic of IsMouseClicked() but we may as well do it ourselves if we end up exposing finer RepeatDelay/RepeatRate settings.
            if (g.ActiveId == id && (.ButtonRepeat in item_flags)) {
                if (g.IO.MouseDownDuration[g.ActiveIdMouseButton] > 0.0 && IsMouseClicked(g.ActiveIdMouseButton, .Repeat, test_owner_id)) {
                    pressed = true;
                }
            }
        }

        if (pressed && g.IO.ConfigNavCursorVisibleAuto) do g.NavCursorVisible = false;
    }

    // Keyboard/Gamepad navigation handling
    // We report navigated and navigation-activated items as hovered but we don't set g.HoveredId to not interfere with mouse.
    if (g.NavId == id && g.NavCursorVisible && g.NavHighlightItemUnderNav) {
        if (!(flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.NoHoveredOnFocus != nil)) do  hovered = true;
    }
    if (g.NavActivateDownId == id)
    {
        nav_activated_by_code := (g.NavActivateId == id);
        nav_activated_by_inputs := (g.NavActivatePressedId == id);
        if (!nav_activated_by_inputs && (.ButtonRepeat in item_flags))
        {
            // Avoid pressing multiple keys from triggering excessive amount of repeat events
            key1 := GetKeyData(.Space);
            key2 := GetKeyData(.Enter);
            key3 := GetKeyData(ImGuiKey_NavGamepadActivate(g));
            t1 := ImMax(ImMax(key1.DownDuration, key2.DownDuration), key3.DownDuration);
            nav_activated_by_inputs = CalcTypematicRepeatAmount(t1 - g.IO.DeltaTime, t1, g.IO.KeyRepeatDelay, g.IO.KeyRepeatRate) > 0;
        }
        if (nav_activated_by_code || nav_activated_by_inputs)
        {
            // Set active id so it can be queried by user via IsItemActive(), equivalent of holding the mouse button.
            pressed = true;
            SetActiveID(id, window);
            g.ActiveIdSource = g.NavInputSource;
            if (!(flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.NoNavFocus != nil) && !(.FromShortcut in g.NavActivateFlags)) {
                SetFocusID(id, window);
            }
            if (.FromShortcut in g.NavActivateFlags) {
                g.ActiveIdFromShortcut = true;
            }
        }
    }

    // Process while held
    held := false;
    if (g.ActiveId == id)
    {
        if (g.ActiveIdSource == .Mouse)
        {
            if (g.ActiveIdIsJustActivated) do g.ActiveIdClickOffset = g.IO.MousePos - bb.Min;

            mouse_button := ImGuiMouseButton(g.ActiveIdMouseButton);
            if (mouse_button == ImGuiMouseButton(-1))
            {
                // Fallback for the rare situation were g.ActiveId was set programmatically or from another widget (e.g. #6304).
                ClearActiveID();
            }
            else if (IsMouseDown(mouse_button, test_owner_id))
            {
                held = true;
            }
            else
            {
                release_in := hovered && (flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.PressedOnClickRelease != nil)
                release_anywhere := (flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.PressedOnClickReleaseAnywhere != nil)
                if ((release_in || release_anywhere) && !g.DragDropActive)
                {
                    // Report as pressed when releasing the mouse (this is the most common path)
                    is_double_click_release := (flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.PressedOnDoubleClick != nil) && g.IO.MouseReleased[mouse_button] && g.IO.MouseClickedLastCount[mouse_button] == 2;
                    is_repeating_already := (.ButtonRepeat in item_flags) && g.IO.MouseDownDurationPrev[mouse_button] >= g.IO.KeyRepeatDelay; // Repeat mode trumps <on release>
                    is_button_avail_or_owned := TestKeyOwner(MouseButtonToKey(mouse_button), test_owner_id);
                    if (!is_double_click_release && !is_repeating_already && is_button_avail_or_owned)  do  pressed = true;
                }
                ClearActiveID();
            }
            if (!(flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.NoNavFocus != nil) && g.IO.ConfigNavCursorVisibleAuto) do g.NavCursorVisible = false;
        }
        else if (g.ActiveIdSource == .Keyboard || g.ActiveIdSource == .Gamepad)
        {
            // When activated using Nav, we hold on the ActiveID until activation button is released
            if (g.NavActivateDownId == id) do held = true; // hovered == true not true as we are already likely hovered on direct activation.
            else do ClearActiveID();
        }
        if (pressed) do g.ActiveIdHasBeenPressedBefore = true;
    }

    // Activation highlight (this may be a remote activation)
    if (g.NavHighlightActivatedId == id)  do hovered = true;

    if (out_hovered != nil) do out_hovered^ = hovered;
    if (out_held != nil) do out_held^ = held;

    return pressed;
}

ButtonEx :: proc(label : string, size_arg : ImVec2, flags : ImGuiButtonFlags) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems) do return false;

    g := GImGui;
    style := &g.Style;
    id := GetID(window, label);
    label_size := CalcTextSize(label, true);

    pos := window.DC.CursorPos;
    if ((flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.AlignTextBaseLine != nil) && style.FramePadding.y < window.DC.CurrLineTextBaseOffset) { // Try to vertically align buttons that are smaller/have no padding so that text baseline matches (bit hacky, since it shouldn't be a flag)
        pos.y += window.DC.CurrLineTextBaseOffset - style.FramePadding.y;
    }
    size := CalcItemSize(size_arg, label_size.x + style.FramePadding.x * 2.0, label_size.y + style.FramePadding.y * 2.0);

    bb := ImRect{ _v = {pos, pos + size}};
    ItemSize(size, style.FramePadding.y);
    if (!ItemAdd(bb, id)) do return false;

    hovered, held : bool
    pressed := ButtonBehavior(bb, id, &hovered, &held, flags);

    // Render
    col := GetColorU32((held && hovered) ? ImGuiCol.ButtonActive : hovered ? ImGuiCol.ButtonHovered : ImGuiCol.Button);
    RenderNavCursor(bb, id);
    RenderFrame(bb.Min, bb.Max, col, true, style.FrameRounding);

    if (g.LogEnabled) do LogSetNextTextDecoration("[", "]");
    RenderTextClipped(bb.Min + style.FramePadding, bb.Max - style.FramePadding, label, &label_size, style.ButtonTextAlign, &bb);

    // Automatically close popups
    //if (pressed && !(.DontClosePopups in flags) && (window.Flags & ImGuiWindowFlags_Popup))   do //    CloseCurrentPopup()

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags);
    return pressed;
}

// [forward declared comment]:
// button
Button :: proc(label : string, size_arg : ImVec2 = {}) -> bool
{
    return ButtonEx(label, size_arg, ImGuiButtonFlags_None);
}

// Small buttons fits within text without additional vertical spacing.
// [forward declared comment]:
// button with (FramePadding.y == 0) to easily embed within text
SmallButton :: proc(label : string) -> bool
{
    g := GImGui;
    backup_padding_y := g.Style.FramePadding.y;
    g.Style.FramePadding.y = 0.0;
    pressed := ButtonEx(label, ImVec2{0, 0}, transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.AlignTextBaseLine);
    g.Style.FramePadding.y = backup_padding_y;
    return pressed;
}

// Tip: use ImGui::PushID()/PopID() to push indices or pointers in the ID stack.
// Then you can keep 'str_id' empty or the same for all your buttons (instead of creating a string based on a non-string id)
// [forward declared comment]:
// flexible button behavior without the visuals, frequently useful to build custom behaviors using the public api (along with IsItemActive, IsItemHovered, etc.)
InvisibleButton :: proc(str_id : ^u8, size_arg : ImVec2, flags : ImGuiButtonFlags = {}) -> bool
{
    g := GImGui;
    window := GetCurrentWindow();
    if (window.SkipItems) do return false;

    // Cannot use zero-size for InvisibleButton(). Unlike Button() there is not way to fallback using the label size.
    assert(size_arg.x != 0.0 && size_arg.y != 0.0);

    id := GetID(window, str_id);
    size := CalcItemSize(size_arg, 0.0, 0.0);
    bb := ImRect{ _v = {window.DC.CursorPos, window.DC.CursorPos + size}};
    ItemSize(size);
    if (!ItemAdd(bb, id, nil, (.EnableNav in flags) ? ImGuiItemFlags_None : ImGuiItemFlags_NoNav)) do return false;

    hovered, held : bool
    pressed := ButtonBehavior(bb, id, &hovered, &held, flags);
    RenderNavCursor(bb, id);

    IMGUI_TEST_ENGINE_ITEM_INFO(id, str_id, g.LastItemData.StatusFlags);
    return pressed;
}

ArrowButtonEx :: proc(str_id : ^u8, dir : ImGuiDir, size : ImVec2, flags : ImGuiButtonFlags) -> bool
{
    g := GImGui;
    window := GetCurrentWindow();
    if (window.SkipItems) do return false;

    id := GetID(window, str_id);
    bb := ImRect{ _v = {window.DC.CursorPos, window.DC.CursorPos + size}};
    default_size := GetFrameHeight();
    ItemSize(size, (size.y >= default_size) ? g.Style.FramePadding.y : -1.0);
    if (!ItemAdd(bb, id)) do return false;

    hovered, held : bool
    pressed := ButtonBehavior(bb, id, &hovered, &held, flags);

    // Render
    bg_col := GetColorU32((held && hovered) ? ImGuiCol.ButtonActive : hovered ? ImGuiCol.ButtonHovered : ImGuiCol.Button);
    text_col := GetColorU32(ImGuiCol.Text);
    RenderNavCursor(bb, id);
    RenderFrame(bb.Min, bb.Max, bg_col, true, g.Style.FrameRounding);
    RenderArrow(window.DrawList, bb.Min + ImVec2{ImMax(0.0, (size.x - g.FontSize) * 0.5), ImMax(0.0, (size.y - g.FontSize) * 0.5)}, text_col, dir);

    IMGUI_TEST_ENGINE_ITEM_INFO(id, str_id, g.LastItemData.StatusFlags);
    return pressed;
}

// [forward declared comment]:
// square button with an arrow shape
ArrowButton :: proc(str_id : ^u8, dir : ImGuiDir) -> bool
{
    sz := GetFrameHeight();
    return ArrowButtonEx(str_id, dir, ImVec2{sz, sz}, ImGuiButtonFlags_None);
}

// Button to close a window
CloseButton :: proc(id : ImGuiID, pos : ImVec2) -> bool
{
    g := GImGui;
    window := g.CurrentWindow;

    // Tweak 1: Shrink hit-testing area if button covers an abnormally large proportion of the visible region. That's in order to facilitate moving the window away. (#3825)
    // This may better be applied as a general hit-rect reduction mechanism for all widgets to ensure the area to move window is always accessible?
    bb := ImRect(pos, pos + ImVec2{g.FontSize, g.FontSize});
    bb_interact := bb;
    area_to_visible_ratio := window.OuterRectClipped.GetArea() / bb.GetArea();
    if (area_to_visible_ratio < 1.5) do bb_interact.Expand(ImTrunc(bb_interact.GetSize() * -0.25));

    // Tweak 2: We intentionally allow interaction when clipped so that a mechanical Alt,Right,Activate sequence can always close a window.
    // (this isn't the common behavior of buttons, but it doesn't affect the user because navigation tends to keep items visible in scrolling layer).
    is_clipped := !ItemAdd(bb_interact, id);

    hovered, held : bool
    pressed := ButtonBehavior(bb_interact, id, &hovered, &held);
    if (is_clipped) do return pressed;

    // Render
    bg_col := GetColorU32(held ? ImGuiCol.ButtonActive : ImGuiCol.ButtonHovered);
    if (hovered) do AddRectFilled(window.DrawList, bb.Min, bb.Max, bg_col);
    RenderNavCursor(bb, id, ImGuiNavRenderCursorFlags_Compact);
    cross_col := GetColorU32(ImGuiCol.Text);
    cross_center := bb.GetCenter() - ImVec2{0.5, 0.5};
    cross_extent := g.FontSize * 0.5 * 0.7071 - 1.0;
    AddLine(window.DrawList, cross_center + ImVec2{+cross_extent, +cross_extent}, cross_center + ImVec2{-cross_extent, -cross_extent}, cross_col, 1.0);
    AddLine(window.DrawList, cross_center + ImVec2{+cross_extent, -cross_extent}, cross_center + ImVec2{-cross_extent, +cross_extent}, cross_col, 1.0);

    return pressed;
}

// The Collapse button also functions as a Dock Menu button.
CollapseButton :: proc(id : ImGuiID, pos : ImVec2, dock_node : ^ImGuiDockNode) -> bool
{
    g := GImGui;
    window := g.CurrentWindow;

    bb := ImRect(pos, pos + ImVec2{g.FontSize, g.FontSize});
    is_clipped := !ItemAdd(bb, id);
    hovered, held : bool
    pressed := ButtonBehavior(bb, id, &hovered, &held, ImGuiButtonFlags_None);
    if (is_clipped) do return pressed;

    // Render
    //bool is_dock_menu = (window.DockNodeAsHost && !window.Collapsed);
    bg_col := GetColorU32((held && hovered) ? ImGuiCol.ButtonActive : hovered ? ImGuiCol.ButtonHovered : ImGuiCol.Button);
    text_col := GetColorU32(ImGuiCol.Text);
    if (hovered || held) do AddRectFilled(window.DrawList, bb.Min, bb.Max, bg_col);
    RenderNavCursor(bb, id, ImGuiNavRenderCursorFlags_Compact);

    if (dock_node) do RenderArrowDockMenu(window.DrawList, bb.Min, g.FontSize, text_col);
    else do RenderArrow(window.DrawList, bb.Min, text_col, window.Collapsed ? .Right : ImGuiDir.Down, 1.0);

    // Switch to moving the window after mouse is moved beyond the initial drag threshold
    if (IsItemActive() && IsMouseDragging(0)) do StartMouseMovingWindowOrNode(window, dock_node, true); // Undock from window/collapse menu button

    return pressed;
}

GetWindowScrollbarID :: proc(window : ^ImGuiWindow, axis : ImGuiAxis) -> ImGuiID
{
    return GetID(window, axis == ImGuiAxis.X ? "#SCROLLX" : "#SCROLLY");
}

// Return scrollbar rectangle, must only be called for corresponding axis if window.ScrollbarX/Y is set.
GetWindowScrollbarRect :: proc(window : ^ImGuiWindow, axis : ImGuiAxis) -> ImRect
{
    outer_rect := Rect(window);
    inner_rect := window.InnerRect;
    border_size := window.WindowBorderSize;
    scrollbar_size := window.ScrollbarSizes[axis ~ 1]; // (ScrollbarSizes.x = width of Y scrollbar; ScrollbarSizes.y = height of X scrollbar)
    assert(scrollbar_size > 0.0);
    if (axis == ImGuiAxis.X) do return ImRect(inner_rect.Min.x, ImMax(outer_rect.Min.y, outer_rect.Max.y - border_size - scrollbar_size), inner_rect.Max.x - border_size, outer_rect.Max.y - border_size);
    else do return ImRect(ImMax(outer_rect.Min.x, outer_rect.Max.x - border_size - scrollbar_size), inner_rect.Min.y, outer_rect.Max.x - border_size, inner_rect.Max.y - border_size);
}

Scrollbar :: proc(axis : ImGuiAxis)
{
    g := GImGui;
    window := g.CurrentWindow;
    id := GetWindowScrollbarID(window, axis);

    // Calculate scrollbar bounding box
    bb := GetWindowScrollbarRect(window, axis);
    rounding_corners := ImDrawFlags_RoundCornersNone;
    if (axis == ImGuiAxis.X)
    {
        rounding_corners |= ImDrawFlags_RoundCornersBottomLeft;
        if (!window.ScrollbarY) {
            rounding_corners |= ImDrawFlags_RoundCornersBottomRight;
        }
    }
    else
    {
        if ((.NoTitleBar in window.Flags) && !(.MenuBar in window.Flags)) {
            rounding_corners |= ImDrawFlags_RoundCornersTopRight;
        }
        if (!window.ScrollbarX) {
            rounding_corners |= ImDrawFlags_RoundCornersBottomRight;
        }
    }
    size_visible := window.InnerRect.Max[axis] - window.InnerRect.Min[axis];
    size_contents := window.ContentSize[axis] + window.WindowPadding[axis] * 2.0;
    scroll := cast(i64) window.Scroll[axis];
    ScrollbarEx(bb, id, axis, &scroll, cast(i64) size_visible, cast(i64) size_contents, rounding_corners);
    window.Scroll[axis] = cast(f32) scroll;
}

// Vertical/Horizontal scrollbar
// The entire piece of code below is rather confusing because:
// - We handle absolute seeking (when first clicking outside the grab) and relative manipulation (afterward or when clicking inside the grab)
// - We store values as normalized ratio and in a form that allows the window content to change while we are holding on a scrollbar
// - We handle both horizontal and vertical scrollbars, which makes the terminology not ideal.
// Still, the code should probably be made simpler..
ScrollbarEx :: proc(bb_frame : ^ImRect, id : ImGuiID, axis : ImGuiAxis, p_scroll_v : ^i64, size_visible_v : i64, size_contents_v : i64, draw_rounding_flags : ImDrawFlags = {}) -> bool
{
    g := GImGui;
    window := g.CurrentWindow;
    if (window.SkipItems) do return false;

    bb_frame_width := bb_frame.GetWidth();
    bb_frame_height := bb_frame.GetHeight();
    if (bb_frame_width <= 0.0 || bb_frame_height <= 0.0) do return false;

    // When we are too small, start hiding and disabling the grab (this reduce visual noise on very small window and facilitate using the window resize grab)
    alpha := 1.0;
    if ((axis == ImGuiAxis.Y) && bb_frame_height < g.FontSize + g.Style.FramePadding.y * 2.0) {
        alpha = ImSaturate((bb_frame_height - g.FontSize) / (g.Style.FramePadding.y * 2.0));
    }
    if (alpha <= 0.0) {
        return false;
    }

    style := &g.Style;
    allow_interaction := (alpha >= 1.0);

    bb := bb_frame;
    bb.Expand(ImVec2{-ImClamp(math.trunc((bb_frame_width - 2.0) * 0.5), 0.0, 3.0), -ImClamp(math.trunc((bb_frame_height - 2.0) * 0.5), 0.0, 3.0)});

    // V denote the main, longer axis of the scrollbar (= height for a vertical scrollbar)
    scrollbar_size_v := (axis == ImGuiAxis.X) ? bb.GetWidth() : bb.GetHeight();

    // Calculate the height of our grabbable box. It generally represent the amount visible (vs the total scrollable amount)
    // But we maintain a minimum size in pixel to allow for the user to still aim inside.
    assert(ImMax(size_contents_v, size_visible_v) > 0.0); // Adding this assert to check if the ImMax(XXX,1.0f) is still needed. PLEASE CONTACT ME if this triggers.
    win_size_v := ImMax(ImMax(size_contents_v, size_visible_v), cast(i64) 1);
    grab_h_pixels := ImClamp(scrollbar_size_v * (cast(f32) size_visible_v / cast(f32) win_size_v), style.GrabMinSize, scrollbar_size_v);
    grab_h_norm := grab_h_pixels / scrollbar_size_v;

    // Handle input right away. None of the code of Begin() is relying on scrolling position before calling Scrollbar().
    held := false;
    hovered := false;
    ItemAdd(bb_frame, id, nil, ImGuiItemFlags_NoNav);
    ButtonBehavior(bb, id, &hovered, &held, ImGuiButtonFlags_NoNavFocus);

    scroll_max := ImMax(cast(i64) 1, size_contents_v - size_visible_v);
    scroll_ratio := ImSaturate((f32)*p_scroll_v / cast(f32) scroll_max);
    grab_v_norm := scroll_ratio * (scrollbar_size_v - grab_h_pixels) / scrollbar_size_v; // Grab position in normalized space
    if (held && allow_interaction && grab_h_norm < 1.0)
    {
        scrollbar_pos_v := bb.Min[axis];
        mouse_pos_v := g.IO.MousePos[axis];

        // Click position in scrollbar normalized space (0.0f->1.0f)
        clicked_v_norm := ImSaturate((mouse_pos_v - scrollbar_pos_v) / scrollbar_size_v);

        held_dir := (clicked_v_norm < grab_v_norm) ? -1 : (clicked_v_norm > grab_v_norm + grab_h_norm) ? +1 : 0;
        if (g.ActiveIdIsJustActivated)
        {
            // On initial click when held_dir == 0 (clicked over grab): calculate the distance between mouse and the center of the grab
            scroll_to_clicked_location := (g.IO.ConfigScrollbarScrollByPage == false || g.IO.KeyShift || held_dir == 0);
            g.ScrollbarSeekMode = scroll_to_clicked_location ? 0 : cast(i16) held_dir;
            g.ScrollbarClickDeltaToGrabCenter = (held_dir == 0 && !g.IO.KeyShift) ? clicked_v_norm - grab_v_norm - grab_h_norm * 0.5 : 0.0;
        }

        // Apply scroll (p_scroll_v will generally point on one member of window.Scroll)
        // It is ok to modify Scroll here because we are being called in Begin() after the calculation of ContentSize and before setting up our starting position
        if (g.ScrollbarSeekMode == 0)
        {
            // Absolute seeking
            scroll_v_norm := ImSaturate((clicked_v_norm - g.ScrollbarClickDeltaToGrabCenter - grab_h_norm * 0.5) / (1.0 - grab_h_norm));
            p_scroll_v^ = (i64)(scroll_v_norm * scroll_max);
        }
        else
        {
            // Page by page
            if (IsMouseClicked(ImGuiMouseButton_Left, ImGuiInputFlags_Repeat) && held_dir == g.ScrollbarSeekMode)
            {
                page_dir := (g.ScrollbarSeekMode > 0.0) ? +1.0 : -1.0;
                p_scroll_v^ = ImClamp(p_scroll_v^ + (i64)(page_dir * size_visible_v), cast(i64) 0, scroll_max);
            }
        }

        // Update values for rendering
        scroll_ratio = ImSaturate(cast(f32) p_scroll_v^ / cast(f32) scroll_max);
        grab_v_norm = scroll_ratio * (scrollbar_size_v - grab_h_pixels) / scrollbar_size_v;

        // Update distance to grab now that we have seek'ed and saturated
        //if (seek_absolute)
        //    g.ScrollbarClickDeltaToGrabCenter = clicked_v_norm - grab_v_norm - grab_h_norm * 0.5f;
    }

    // Render
    bg_col := GetColorU32(ImGuiCol.ScrollbarBg);
    grab_col := GetColorU32(held ? ImGuiCol.ScrollbarGrabActive : hovered ? ImGuiCol.ScrollbarGrabHovered : ImGuiCol.ScrollbarGrab, alpha);
    AddRectFilled(window.DrawList, bb_frame.Min, bb_frame.Max, bg_col, window.WindowRounding, draw_rounding_flags);
    grab_rect : ImRect
    if (axis == ImGuiAxis.X)  do grab_rect = ImRect(ImLerp(bb.Min.x, bb.Max.x, grab_v_norm), bb.Min.y, ImLerp(bb.Min.x, bb.Max.x, grab_v_norm) + grab_h_pixels, bb.Max.y);
    else                      do grab_rect = ImRect(bb.Min.x, ImLerp(bb.Min.y, bb.Max.y, grab_v_norm), bb.Max.x, ImLerp(bb.Min.y, bb.Max.y, grab_v_norm) + grab_h_pixels);
    AddRectFilled(window.DrawList, grab_rect.Min, grab_rect.Max, grab_col, style.ScrollbarRounding);

    return held;
}

// - Read about ImTextureID here: https://github.com/ocornut/imgui/wiki/Image-Loading-and-Displaying-Examples
// - 'uv0' and 'uv1' are texture coordinates. Read about them from the same link above.
Image :: proc(user_texture_id : ImTextureID, image_size : ImVec2, uv0 : ImVec2 = {}, uv1 : ImVec2 = ImVec2{1, 1}, tint_col : ImVec4 = ImVec4{1, 1, 1, 1}, border_col : ImVec4 = ImVec4{0, 0, 0, 0})
{
    window := GetCurrentWindow();
    if (window.SkipItems) do return;

    border_size := (border_col.w > 0.0) ? 1.0 : 0.0;
    padding := ImVec2{border_size, border_size};
    bb := ImRect{ _v = {window.DC.CursorPos, window.DC.CursorPos + image_size + padding * 2.0}};
    ItemSize(bb);
    if (!ItemAdd(bb, 0)) do return;

    // Render
    if (border_size > 0.0) {
        window.DrawList.AddRect(bb.Min, bb.Max, GetColorU32(border_col), 0.0, ImDrawFlags_None, border_size);
    }
    window.DrawList.AddImage(user_texture_id, bb.Min + padding, bb.Max - padding, uv0, uv1, GetColorU32(tint_col));
}

ImageButtonEx :: proc(id : ImGuiID, user_texture_id : ImTextureID, image_size : ImVec2, uv0 : ImVec2, uv1 : ImVec2, bg_col : ImVec4, tint_col : ImVec4, flags : ImGuiButtonFlags) -> bool
{
    g := GImGui;
    window := GetCurrentWindow();
    if (window.SkipItems) do return false;

    padding := g.Style.FramePadding;
    bb := ImRect{ _v = {window.DC.CursorPos, window.DC.CursorPos + image_size + padding * 2.0}};
    ItemSize(bb);
    if (!ItemAdd(bb, id))   do return false

    hovered, held : bool
    pressed := ButtonBehavior(bb, id, &hovered, &held, flags);

    // Render
    col := GetColorU32((held && hovered) ? ImGuiCol.ButtonActive : hovered ? ImGuiCol.ButtonHovered : ImGuiCol.Button);
    RenderNavCursor(bb, id);
    RenderFrame(bb.Min, bb.Max, col, true, ImClamp(cast(f32) ImMin(padding.x, padding.y), 0.0, g.Style.FrameRounding));
    if (bg_col.w > 0.0) {
        AddRectFilled(window.DrawList, bb.Min + padding, bb.Max - padding, GetColorU32(bg_col));
    }
    window.DrawList.AddImage(user_texture_id, bb.Min + padding, bb.Max - padding, uv0, uv1, GetColorU32(tint_col));

    return pressed;
}

// - ImageButton() adds style.FramePadding*2.0f to provided size. This is in order to facilitate fitting an image in a button.
// - ImageButton() draws a background based on regular Button() color + optionally an inner background if specified. (#8165) // FIXME: Maybe that's not the best design?
ImageButton :: proc(str_id : ^u8, user_texture_id : ImTextureID, image_size : ImVec2, uv0 : ImVec2 = {}, uv1 : ImVec2 = ImVec2{1, 1}, bg_col : ImVec4 = ImVec4{0, 0, 0, 0}, tint_col : ImVec4 = ImVec4{1, 1, 1, 1}) -> bool
{
    g := GImGui;
    window := g.CurrentWindow;
    if (window.SkipItems)   do return false

    return ImageButtonEx(GetID(window, str_id), user_texture_id, image_size, uv0, uv1, bg_col, tint_col);
}


Checkbox :: proc(label : string, v : ^bool) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    style := &g.Style;
    id := GetID(window, label);
    label_size := CalcTextSize(label, nil, true);

    square_sz := GetFrameHeight();
    pos := window.DC.CursorPos;
    total_bb := ImRect(pos, pos + ImVec2{square_sz + (label_size.x > 0.0 ? style.ItemInnerSpacing.x + label_size.x : 0.0), label_size.y + style.FramePadding.y * 2.0});
    ItemSize(total_bb, style.FramePadding.y);
    is_visible := ItemAdd(total_bb, id);
    is_multi_select := (.IsMultiSelect in g.LastItemData.ItemFlags) != 0;
    if (!is_visible) {
        if (!is_multi_select || !g.BoxSelectState.UnclipMode || !g.BoxSelectState.UnclipRect.Overlaps(total_bb)) // Extra layer of "no logic clip" for box-select support
        {
            IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags | ImGuiItemStatusFlags_Checkable | (v^ ? ImGuiItemStatusFlags_Checked : 0));
            return false;
        }
    }

    // Range-Selection/Multi-selection support (header)
    checked := v^;
    if (is_multi_select) do MultiSelectItemHeader(id, &checked, nil);

    hovered, held : bool
    pressed := ButtonBehavior(total_bb, id, &hovered, &held);

    // Range-Selection/Multi-selection support (footer)
    if (is_multi_select) do MultiSelectItemFooter(id, &checked, &pressed);
    else if (pressed) do checked = !checked;

    if (v^ != checked)
    {
        v^ = checked;
        pressed = true; // return value
        MarkItemEdited(id);
    }

    check_bb := ImRect(pos, pos + ImVec2{square_sz, square_sz});
    mixed_value := (.MixedValue in g.LastItemData.ItemFlags) != 0;
    if (is_visible)
    {
        RenderNavCursor(total_bb, id);
        RenderFrame(check_bb.Min, check_bb.Max, GetColorU32((held && hovered) ? ImGuiCol.FrameBgActive : hovered ? ImGuiCol.FrameBgHovered : ImGuiCol.FrameBg), true, style.FrameRounding);
        check_col := GetColorU32(ImGuiCol.CheckMark);
        if (mixed_value)
        {
            // Undocumented tristate/mixed/indeterminate checkbox (#2644)
            // This may seem awkwardly designed because the aim is to make ImGuiItemFlags_MixedValue supported by all widgets (not just checkbox)
            pad := ImVec2(ImMax(1.0, math.trunc(square_sz / 3.6)), ImMax(1.0, math.trunc(square_sz / 3.6)));
            AddRectFilled(window.DrawList, check_bb.Min + pad, check_bb.Max - pad, check_col, style.FrameRounding);
        }
        else if (v^)
        {
            pad := ImMax(1.0, math.trunc(square_sz / 6.0));
            RenderCheckMark(window.DrawList, check_bb.Min + ImVec2{pad, pad}, check_col, square_sz - pad * 2.0);
        }
    }
    label_pos := ImVec2{check_bb.Max.x + style.ItemInnerSpacing.x, check_bb.Min.y + style.FramePadding.y};
    if (g.LogEnabled) do LogRenderedText(&label_pos, mixed_value ? "[~]" : v^ ? "[x]" : "[ ]");
    if (is_visible && label_size.x > 0.0) do RenderText(label_pos, label);

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags | ImGuiItemStatusFlags_Checkable | (v^ ? ImGuiItemStatusFlags_Checked : 0));
    return pressed;
}


CheckboxFlagsT :: proc(label : string, flags : ^$T, flags_value : T) -> bool
{
    all_on := (flags^ & flags_value) == flags_value;
    any_on := (flags^ & flags_value) != 0;
    pressed : bool
    if (!all_on && any_on)
    {
        g := GImGui;
        g.NextItemData.ItemFlags |= ImGuiItemFlags_MixedValue;
        pressed = Checkbox(label, &all_on);
    }
    else
    {
        pressed = Checkbox(label, &all_on);

    }
    if (pressed)
    {
        if (all_on) do flags^ |= flags_value;
        else do flags^ &= ~flags_value;
    }
    return pressed;
}

CheckboxFlags_i :: proc(label : string, flags : ^i32, flags_value : i32) -> bool
{
    return CheckboxFlagsT(label, flags, flags_value);
}

CheckboxFlags_u :: proc(label : string, flags : ^u32, flags_value : u32) -> bool
{
    return CheckboxFlagsT(label, flags, flags_value);
}

CheckboxFlags_i64 :: proc(label : string, flags : ^i64, flags_value : i64) -> bool
{
    return CheckboxFlagsT(label, flags, flags_value);
}

CheckboxFlags_u64 :: proc(label : string, flags : ^u64, flags_value : u64) -> bool
{
    return CheckboxFlagsT(label, flags, flags_value);
}

CheckboxFlags :: proc { CheckboxFlags_i, CheckboxFlags_u, CheckboxFlags_i64, CheckboxFlags_u64 }

// [forward declared comment]:
// shortcut to handle the above pattern when value is an integer
RadioButton_ex :: proc(label : string, active : bool) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    style := &g.Style;
    id := GetID(window, label);
    label_size := CalcTextSize(label, nil, true);

    square_sz := GetFrameHeight();
    pos := window.DC.CursorPos;
    check_bb := ImRect(pos, pos + ImVec2{square_sz, square_sz});
    total_bb := ImRect(pos, pos + ImVec2{square_sz + (label_size.x > 0.0 ? style.ItemInnerSpacing.x + label_size.x : 0.0), label_size.y + style.FramePadding.y * 2.0});
    ItemSize(total_bb, style.FramePadding.y);
    if (!ItemAdd(total_bb, id))   do return false

    center := check_bb.GetCenter();
    center.x = math.round(center.x);
    center.y = math.round(center.y);
    radius := (square_sz - 1.0) * 0.5;

    hovered, held : bool
    pressed := ButtonBehavior(total_bb, id, &hovered, &held);
    if (pressed) do MarkItemEdited(id);

    RenderNavCursor(total_bb, id);
    num_segment := window.DrawList._CalcCircleAutoSegmentCount(radius);
    window.DrawList.AddCircleFilled(center, radius, GetColorU32((held && hovered) ? ImGuiCol.FrameBgActive : hovered ? ImGuiCol.FrameBgHovered : ImGuiCol.FrameBg), num_segment);
    if (active)
    {
        pad := ImMax(1.0, math.trunc(square_sz / 6.0));
        window.DrawList.AddCircleFilled(center, radius - pad, GetColorU32(ImGuiCol.CheckMark));
    }

    if (style.FrameBorderSize > 0.0)
    {
        window.DrawList.AddCircle(center + ImVec2{1, 1}, radius, GetColorU32(ImGuiCol.BorderShadow), num_segment, style.FrameBorderSize);
        window.DrawList.AddCircle(center, radius, GetColorU32(ImGuiCol.Border), num_segment, style.FrameBorderSize);
    }

    label_pos := ImVec2{check_bb.Max.x + style.ItemInnerSpacing.x, check_bb.Min.y + style.FramePadding.y};
    if (g.LogEnabled) do LogRenderedText(&label_pos, active ? "(x)" : "( )");
    if (label_size.x > 0.0) do RenderText(label_pos, label);

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags);
    return pressed;
}

// FIXME: This would work nicely if it was a public template, e.g. 'template<T> RadioButton(const char* label, T* v, T v_button)', but I'm not sure how we would expose it..
// [forward declared comment]:
// shortcut to handle the above pattern when value is an integer
RadioButton_basic :: proc(label : string, v : ^i32, v_button : i32) -> bool
{
    pressed := RadioButton(label, v^ == v_button);
    if (pressed)   do v^ = v_button
    return pressed;
}

RadioButton :: proc { RadioButton_basic, RadioButton_ex }

// size_arg (for each axis) < 0.0f: align to end, 0.0f: auto, > 0.0f: specified size
ProgressBar :: proc(fraction : f32, size_arg : ImVec2 = ImVec2{-math.F32_MIN, 0}, overlay : ^u8 = nil)
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return

    g := GImGui;
    style := &g.Style;

    pos := window.DC.CursorPos;
    size := CalcItemSize(size_arg, CalcItemWidth(), g.FontSize + style.FramePadding.y * 2.0);
    bb := ImRect{ _v = {pos, pos + size}};
    ItemSize(size, style.FramePadding.y);
    if (!ItemAdd(bb, 0))   do return

    // Fraction < 0.0f will display an indeterminate progress bar animation
    // The value must be animated along with time, so e.g. passing '-1.0f * ImGui::GetTime()' as fraction works.
    is_indeterminate := (fraction < 0.0);
    if (!is_indeterminate)  do fraction = ImSaturate(fraction);

    // Out of courtesy we accept a NaN fraction without crashing
    fill_n0 := 0.0;
    fill_n1 := (fraction == fraction) ? fraction : 0.0;

    if (is_indeterminate)
    {
        fill_width_n := 0.2;
        fill_n0 = ImFmod(-fraction, 1.0) * (1.0 + fill_width_n) - fill_width_n;
        fill_n1 = ImSaturate(fill_n0 + fill_width_n);
        fill_n0 = ImSaturate(fill_n0);
    }

    // Render
    RenderFrame(bb.Min, bb.Max, GetColorU32(ImGuiCol.FrameBg), true, style.FrameRounding);
    bb.Expand(ImVec2{-style.FrameBorderSize, -style.FrameBorderSize});
    RenderRectFilledRangeH(window.DrawList, bb, GetColorU32(ImGuiCol.PlotHistogram), fill_n0, fill_n1, style.FrameRounding);

    // Default displaying the fraction as percentage string, but user can override it
    // Don't display text for indeterminate bars by default
    overlay_buf : [32]u8
    if (!is_indeterminate || overlay != nil)
    {
        if (!overlay)
        {
            ImFormatString(overlay_buf, len(overlay_buf), "%.0%%", fraction * 100 + 0.01);
            overlay = overlay_buf;
        }

        overlay_size := CalcTextSize(overlay, nil);
        if (overlay_size.x > 0.0)
        {
            text_x := is_indeterminate ? (bb.Min.x + bb.Max.x - overlay_size.x) * 0.5 : ImLerp(bb.Min.x, bb.Max.x, fill_n1) + style.ItemSpacing.x;
            RenderTextClipped(ImVec2{ImClamp(text_x, bb.Min.x, bb.Max.x - overlay_size.x - style.ItemInnerSpacing.x), bb.Min.y}, bb.Max, overlay, nil, &overlay_size, ImVec2{0.0, 0.5}, &bb);
        }
    }
}

// [forward declared comment]:
// draw a small circle + keep the cursor on the same line. advance cursor x position by GetTreeNodeToLabelSpacing(), same distance that TreeNode() uses
Bullet :: proc()
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return

    g := GImGui;
    style := &g.Style;
    line_height := ImMax(ImMin(window.DC.CurrLineSize.y, g.FontSize + style.FramePadding.y * 2), g.FontSize);
    bb := ImRect{_v = { window.DC.CursorPos, window.DC.CursorPos + ImVec2{g.FontSize, line_height}}};
    ItemSize(bb);
    if (!ItemAdd(bb, 0))
    {
        SameLine(0, style.FramePadding.x * 2);
        return;
    }

    // Render and stay on same line
    text_col := GetColorU32(ImGuiCol.Text);
    RenderBullet(window.DrawList, bb.Min + ImVec2{style.FramePadding.x + g.FontSize * 0.5, line_height * 0.5}, text_col);
    SameLine(0, style.FramePadding.x * 2.0);
}

// This is provided as a convenience for being an often requested feature.
// FIXME-STYLE: we delayed adding as there is a larger plan to revamp the styling system.
// Because of this we currently don't provide many styling options for this widget
// (e.g. hovered/active colors are automatically inferred from a single color).
// [forward declared comment]:
// hyperlink text button, return true when clicked
TextLink :: proc(label : string) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    id := GetID(window, label);
    label_end := FindRenderedText(label);

    pos := window.DC.CursorPos;
    size := CalcTextSize(label, label_end, true);
    bb := ImRect{ _v = {pos, pos + size}};
    ItemSize(size, 0.0);
    if (!ItemAdd(bb, id))   do return false

    hovered, held : bool
    pressed := ButtonBehavior(bb, id, &hovered, &held);
    RenderNavCursor(bb, id);

    if (hovered) do SetMouseCursor(ImGuiMouseCursor_Hand);

    text_colf := g.Style.Colors[ImGuiCol.TextLink];
    line_colf := text_colf;
    {
        // FIXME-STYLE: Read comments above. This widget is NOT written in the same style as some earlier widgets,
        // as we are currently experimenting/planning a different styling system.
        h, s, v : f32
        ColorConvertRGBtoHSV(text_colf.x, text_colf.y, text_colf.z, h, s, v);
        if (held || hovered)
        {
            v = ImSaturate(v + (held ? 0.4 : 0.3));
            h = ImFmod(h + 0.02, 1.0);
        }
        ColorConvertHSVtoRGB(h, s, v, text_colf.x, text_colf.y, text_colf.z);
        v = ImSaturate(v - 0.20);
        ColorConvertHSVtoRGB(h, s, v, line_colf.x, line_colf.y, line_colf.z);
    }

    line_y := bb.Max.y + ImFloor(g.Font.Descent * g.FontScale * 0.20);
    AddLine(window.DrawList, ImVec2{bb.Min.x, line_y}, ImVec2{bb.Max.x, line_y}, GetColorU32(line_colf)); // FIXME-TEXT: Underline mode.

    PushStyleColor(ImGuiCol.Text, GetColorU32(text_colf));
    RenderText(bb.Min, label, label_end);
    PopStyleColor();

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags);
    return pressed;
}

// [forward declared comment]:
// hyperlink text button, automatically open file/url when clicked
TextLinkOpenURL :: proc(label : string, url : ^u8 = nil)
{
    g := GImGui;
    if (url == nil)   do url = label
    if (TextLink(label)) {
        if (g.PlatformIO.Platform_OpenInShellFn != nil) {
            g.PlatformIO.Platform_OpenInShellFn(g, url);
        }
    }
    SetItemTooltip(LocalizeGetMsg(ImGuiLocKey_OpenLink_s), url); // It is more reassuring for user to _always_ display URL when we same as label
    if (BeginPopupContextItem())
    {
        if (MenuItem(LocalizeGetMsg(ImGuiLocKey_CopyLink)))   do SetClipboardText(url)
        EndPopup();
    }
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: Low-level Layout helpers
//-------------------------------------------------------------------------
// - Spacing()
// - Dummy()
// - NewLine()
// - AlignTextToFramePadding()
// - SeparatorEx() [Internal]
// - Separator()
// - SplitterBehavior() [Internal]
// - ShrinkWidths() [Internal]
//-------------------------------------------------------------------------

// [forward declared comment]:
// add vertical spacing.
Spacing :: proc()
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return
    ItemSize(ImVec2{0, 0});
}

// [forward declared comment]:
// add a dummy item of given size. unlike InvisibleButton(), Dummy() won't take the mouse click or be navigable into.
Dummy :: proc(size : ImVec2)
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return

    bb := ImRect{ _v = {window.DC.CursorPos, window.DC.CursorPos + size}};
    ItemSize(size);
    ItemAdd(bb, 0);
}

// [forward declared comment]:
// undo a SameLine() or force a new line when in a horizontal-layout context.
NewLine :: proc()
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return

    g := GImGui;
    backup_layout_type := window.DC.LayoutType;
    window.DC.LayoutType = .Vertical;
    window.DC.IsSameLine = false;
    // In the event that we are on a line with items that is smaller that FontSize high, we will preserve its height.
    if (window.DC.CurrLineSize.y > 0.0)  do ItemSize(ImVec2{0, 0});
    else  do ItemSize(ImVec2{0.0, g.FontSize});
    window.DC.LayoutType = backup_layout_type;
}

// [forward declared comment]:
// vertically align upcoming text baseline to FramePadding.y so that it will align properly to regularly framed items (call if you have text on a line before a framed item)
AlignTextToFramePadding :: proc()
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return

    g := GImGui;
    window.DC.CurrLineSize.y = ImMax(window.DC.CurrLineSize.y, g.FontSize + g.Style.FramePadding.y * 2);
    window.DC.CurrLineTextBaseOffset = ImMax(window.DC.CurrLineTextBaseOffset, g.Style.FramePadding.y);
}

// Horizontal/vertical separating line
// FIXME: Surprisingly, this seemingly trivial widget is a victim of many different legacy/tricky layout issues.
// Note how thickness == 1.0f is handled specifically as not moving CursorPos by 'thickness', but other values are.
SeparatorEx :: proc(flags : ImGuiSeparatorFlags, thickness : f32 = 1.0)
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return

    g := GImGui;
    assert(math.is_power_of_two(flags & ImGuiSeparatorFlags{.Horizontal, .Vertical} != nil));   // Check that only 1 option is selected
    assert(thickness > 0.0);

    if (.Vertical in flags)
    {
        // Vertical separator, for menu bars (use current line height).
        y1 := window.DC.CursorPos.y;
        y2 := window.DC.CursorPos.y + window.DC.CurrLineSize.y;
        bb := ImRect{ _v = { ImVec2{window.DC.CursorPos.x, y1}, ImVec2{window.DC.CursorPos.x + thickness, y2} }};
        ItemSize(ImVec2{thickness, 0.0});
        if (!ItemAdd(bb, 0))   do return

        // Draw
        AddRectFilled(window.DrawList, bb.Min, bb.Max, GetColorU32(ImGuiCol.Separator));
        if (g.LogEnabled)   do LogText(" |")
    }
    else if (.Horizontal in flags)
    {
        // Horizontal Separator
        x1 := window.DC.CursorPos.x;
        x2 := window.WorkRect.Max.x;

        // Preserve legacy behavior inside Columns()
        // Before Tables API happened, we relied on Separator() to span all columns of a Columns() set.
        // We currently don't need to provide the same feature for tables because tables naturally have border features.
        columns := (.SpanAllColumns in flags) ? window.DC.CurrentColumns : nil;
        if (columns != nil)
        {
            x1 = window.Pos.x + window.DC.Indent.x; // Used to be Pos.x before 2023/10/03
            x2 = window.Pos.x + window.Size.x;
            PushColumnsBackground();
        }

        // We don't provide our width to the layout so that it doesn't get feed back into AutoFit
        // FIXME: This prevents ->CursorMaxPos based bounding box evaluation from working (e.g. TableEndCell)
        thickness_for_layout := (thickness == 1.0) ? 0.0 : thickness; // FIXME: See 1.70/1.71 Separator() change: makes legacy 1-px separator not affect layout yet. Should change.
        bb := ImRect{_v = {ImVec2{x1, window.DC.CursorPos.y}, ImVec2{x2, window.DC.CursorPos.y + thickness}}};
        ItemSize(ImVec2{0.0, thickness_for_layout});

        if (ItemAdd(bb, 0))
        {
            // Draw
            AddRectFilled(window.DrawList, bb.Min, bb.Max, GetColorU32(ImGuiCol.Separator));
            if (g.LogEnabled) do LogRenderedText(&bb.Min, "--------------------------------\n");

        }
        if (columns != nil)
        {
            PopColumnsBackground();
            columns.LineMinY = window.DC.CursorPos.y;
        }
    }
}

// [forward declared comment]:
// separator, generally horizontal. inside a menu bar or in horizontal layout mode, this becomes a vertical separator.
Separator :: proc()
{
    g := GImGui;
    window := g.CurrentWindow;
    if (window.SkipItems)   do return

    // Those flags should eventually be configurable by the user
    // FIXME: We cannot g.Style.SeparatorTextBorderSize for thickness as it relates to SeparatorText() which is a decorated separator, not defaulting to 1.0f.
    flags := (window.DC.LayoutType == .Horizontal) ? ImGuiSeparatorFlags{.Vertical} : ImGuiSeparatorFlags{.Horizontal};

    // Only applies to legacy Columns() api as they relied on Separator() a lot.
    if (window.DC.CurrentColumns != nil) {
        flags |= {.SpanAllColumns};
    }

    SeparatorEx(flags, 1.0);
}

SeparatorTextEx :: proc(id : ImGuiID, label : string, label_end : ^u8, extra_w : f32)
{
    g := GImGui;
    window := g.CurrentWindow;
    style := &g.Style;

    label_size := CalcTextSize(label, label_end, false);
    pos := window.DC.CursorPos;
    padding := style.SeparatorTextPadding;

    separator_thickness := style.SeparatorTextBorderSize;
    min_size := ImVec2(label_size.x + extra_w + padding.x * 2.0, ImMax(label_size.y + padding.y * 2.0, separator_thickness));
    bb := ImRect(pos, ImVec2{window.WorkRect.Max.x, pos.y + min_size.y});
    text_baseline_y := ImTrunc((bb.GetHeight() - label_size.y) * style.SeparatorTextAlign.y + 0.99999); //ImMax(padding.y, ImTrunc((style.SeparatorTextSize - label_size.y) * 0.5f));
    ItemSize(min_size, text_baseline_y);
    if (!ItemAdd(bb, id))   do return

    sep1_x1 := pos.x;
    sep2_x2 := bb.Max.x;
    seps_y := ImTrunc((bb.Min.y + bb.Max.y) * 0.5 + 0.99999);

    label_avail_w := ImMax(0.0, sep2_x2 - sep1_x1 - padding.x * 2.0);
    label_pos := ImVec2(pos.x + padding.x + ImMax(0.0, (label_avail_w - label_size.x - extra_w) * style.SeparatorTextAlign.x), pos.y + text_baseline_y); // FIXME-ALIGN

    // This allows using SameLine() to position something in the 'extra_w'
    window.DC.CursorPosPrevLine.x = label_pos.x + label_size.x;

    separator_col := GetColorU32(ImGuiCol.Separator);
    if (label_size.x > 0.0)
    {
        sep1_x2 := label_pos.x - style.ItemSpacing.x;
        sep2_x1 := label_pos.x + label_size.x + extra_w + style.ItemSpacing.x;
        if (sep1_x2 > sep1_x1 && separator_thickness > 0.0) {
            AddLine(window.DrawList, ImVec2{sep1_x1, seps_y}, ImVec2{sep1_x2, seps_y}, separator_col, separator_thickness);
        }
        if (sep2_x2 > sep2_x1 && separator_thickness > 0.0) {
            AddLine(window.DrawList, ImVec2{sep2_x1, seps_y}, ImVec2{sep2_x2, seps_y}, separator_col, separator_thickness);
        }
        if (g.LogEnabled) {
            LogSetNextTextDecoration("---", nil);
        }
        RenderTextEllipsis(window.DrawList, label_pos, ImVec2{bb.Max.x, bb.Max.y + style.ItemSpacing.y}, bb.Max.x, bb.Max.x, label, label_end, &label_size);
    }
    else
    {
        if (g.LogEnabled)   do LogText("---")
        if (separator_thickness > 0.0) {
            AddLine(window.DrawList, ImVec2{sep1_x1, seps_y}, ImVec2{sep2_x2, seps_y}, separator_col, separator_thickness);
        }
    }
}

// [forward declared comment]:
// currently: formatted text with an horizontal line
SeparatorText :: proc(label : string)
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return

    // The SeparatorText() vs SeparatorTextEx() distinction is designed to be considerate that we may want:
    // - allow separator-text to be draggable items (would require a stable ID + a noticeable highlight)
    // - this high-level entry point to allow formatting? (which in turns may require ID separate from formatted string)
    // - because of this we probably can't turn 'const char* label' into 'const char* fmt, ...'
    // Otherwise, we can decide that users wanting to drag this would layout a dedicated drag-item,
    // and then we can turn this into a format function.
    SeparatorTextEx(0, label, FindRenderedText(label), 0.0);
}

// Using 'hover_visibility_delay' allows us to hide the highlight and mouse cursor for a short time, which can be convenient to reduce visual noise.
SplitterBehavior :: proc(bb : ^ImRect, id : ImGuiID, axis : ImGuiAxis, size1 : ^f32, size2 : ^f32, min_size1 : f32, min_size2 : f32, hover_extend : f32 = 0.0, hover_visibility_delay : f32 = 0.0, bg_col : u32 = 0.0) -> bool
{
    g := GImGui;
    window := g.CurrentWindow;

    if (!ItemAdd(bb, id, nil, ImGuiItemFlags_NoNav))   do return false

    // FIXME: AFAIK the only leftover reason for passing ImGuiButtonFlags_AllowOverlap here is
    // to allow caller of SplitterBehavior() to call SetItemAllowOverlap() after the item.
    // Nowadays we would instead want to use SetNextItemAllowOverlap() before the item.
    button_flags := ImGuiButtonFlags_FlattenChildren;

    hovered, held : bool
    bb_interact := bb;
    bb_interact.Expand(axis == ImGuiAxis.Y ? ImVec2{0.0, hover_extend} : ImVec2{hover_extend, 0.0});
    ButtonBehavior(bb_interact, id, &hovered, &held, button_flags);
    if (hovered) {
        g.LastItemData.StatusFlags |= ImGuiItemStatusFlags_HoveredRect; // for IsItemHovered(), because bb_interact is larger than bb
    }

    if (held || (hovered && g.HoveredIdPreviousFrame == id && g.HoveredIdTimer >= hover_visibility_delay)) {
        SetMouseCursor(axis == ImGuiAxis.Y ? ImGuiMouseCursor_ResizeNS : ImGuiMouseCursor_ResizeEW);
    }

    bb_render := bb;
    if (held)
    {
        mouse_delta := (g.IO.MousePos - g.ActiveIdClickOffset - bb_interact.Min)[axis];

        // Minimum pane size
        size_1_maximum_delta := ImMax(0.0, size1^ - min_size1);
        size_2_maximum_delta := ImMax(0.0, size2^ - min_size2);
        if (mouse_delta < -size_1_maximum_delta) do mouse_delta = -size_1_maximum_delta;
        if (mouse_delta > size_2_maximum_delta) do mouse_delta = size_2_maximum_delta;

        // Apply resize
        if (mouse_delta != 0.0)
        {
            size1^ = ImMax(size1^ + mouse_delta, min_size1);
            size2^ = ImMax(size2^ - mouse_delta, min_size2);
            bb_render.Translate((axis == ImGuiAxis.X) ? ImVec2{mouse_delta, 0.0} : ImVec2{0.0, mouse_delta});
            MarkItemEdited(id);
        }
    }

    // Render at new position
    if (bg_col & IM_COL32_A_MASK) {
        AddRectFilled(window.DrawList, bb_render.Min, bb_render.Max, bg_col, 0.0);
    }
    col := GetColorU32(held ? ImGuiCol.SeparatorActive : (hovered && g.HoveredIdTimer >= hover_visibility_delay) ? ImGuiCol.SeparatorHovered : ImGuiCol.Separator);
    AddRectFilled(window.DrawList, bb_render.Min, bb_render.Max, col, 0.0);

    return held;
}

ShrinkWidthItemComparer :: proc(lhs : rawptr, rhs : rawptr) -> i32
{
    a: = cast(^ImGuiShrinkWidthItem)lhs;
    b: = cast(^ImGuiShrinkWidthItem)rhs;
    if d := (i32)(b.Width - a.Width); d != 0   do return d
    return (b.Index - a.Index);
}

// Shrink excess width from a set of item, by removing width from the larger items first.
// Set items Width to -1.0f to disable shrinking this item.
ShrinkWidths :: proc(items : ^ImGuiShrinkWidthItem, count : i32, width_excess : f32)
{
    if (count == 1)
    {
        if (items[0].Width >= 0.0) {
            items[0].Width = ImMax(items[0].Width - width_excess, 1.0);
        }
        return;
    }
    ImQsort(items, cast(int) count, size_of(ImGuiShrinkWidthItem), ShrinkWidthItemComparer);
    count_same_width := 1;
    for (width_excess > 0.0 && count_same_width < count)
    {
        for (count_same_width < count && items[0].Width <= items[count_same_width].Width) {
            count_same_width += 1;
        }
        max_width_to_remove_per_item := (count_same_width < count && items[count_same_width].Width >= 0.0) ? (items[0].Width - items[count_same_width].Width) : (items[0].Width - 1.0);
        if (max_width_to_remove_per_item <= 0.0)   do break
        width_to_remove_per_item := ImMin(width_excess / count_same_width, max_width_to_remove_per_item);
        for item_n := 0; item_n < count_same_width; item_n += 1 {
            items[item_n].Width -= width_to_remove_per_item;
        }
        width_excess -= width_to_remove_per_item * count_same_width;
    }

    // Round width and redistribute remainder
    // Ensure that e.g. the right-most tab of a shrunk tab-bar always reaches exactly at the same distance from the right-most edge of the tab bar separator.
    width_excess = 0.0;
    for n := 0; n < count; n += 1
    {
        width_rounded := ImTrunc(items[n].Width);
        width_excess += items[n].Width - width_rounded;
        items[n].Width = width_rounded;
    }
    for (width_excess > 0.0) {
        for n := 0; n < count && width_excess > 0.0; n += 1
        {
            width_to_add := ImMin(items[n].InitialWidth - items[n].Width, 1.0);
            items[n].Width += width_to_add;
            width_excess -= width_to_add;
        }
    }
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: ComboBox
//-------------------------------------------------------------------------
// - CalcMaxPopupHeightFromItemCount() [Internal]
// - BeginCombo()
// - BeginComboPopup() [Internal]
// - EndCombo()
// - BeginComboPreview() [Internal]
// - EndComboPreview() [Internal]
// - Combo()
//-------------------------------------------------------------------------

CalcMaxPopupHeightFromItemCount :: proc(items_count : i32) -> f32
{
    g := GImGui;
    if (items_count <= 0)   do return math.F32_MAX
    return (g.FontSize + g.Style.ItemSpacing.y) * items_count - g.Style.ItemSpacing.y + (g.Style.WindowPadding.y * 2);
}

BeginCombo :: proc(label : string, preview_value : ^u8, flags : ImGuiComboFlags = {}) -> bool
{
    g := GImGui;
    window := GetCurrentWindow();

    backup_next_window_data_flags := g.NextWindowData.Flags;
    g.NextWindowData.ClearFlags(); // We behave like Begin() and need to consume those values
    if (window.SkipItems)   do return false

    style := &g.Style;
    id := GetID(window, label);
    assert((flags & (ImGuiComboFlags_NoArrowButton | ImGuiComboFlags_NoPreview)) != (ImGuiComboFlags_NoArrowButton | ImGuiComboFlags_NoPreview)); // Can't use both flags together
    if (.WidthFitPreview in flags) {
        assert((flags & (ImGuiComboFlags_NoPreview | ImGuiComboFlags(ImGuiComboFlags_CustomPreview))) == 0);
    }

    arrow_size := (.NoArrowButton in flags) ? 0.0 : GetFrameHeight();
    label_size := CalcTextSize(label, nil, true);
    preview_width := ((.WidthFitPreview in flags) && (preview_value != nil)) ? CalcTextSize(preview_value, nil, true).x : 0.0;
    w := (.NoPreview in flags) ? arrow_size : ((.WidthFitPreview in flags) ? (arrow_size + preview_width + style.FramePadding.x * 2.0) : CalcItemWidth());
    bb := ImRect(window.DC.CursorPos, window.DC.CursorPos + ImVec2{w, label_size.y + style.FramePadding.y * 2.0});
    total_bb := ImRect(bb.Min, bb.Max + ImVec2{label_size.x > 0.0 ? style.ItemInnerSpacing.x + label_size.x : 0.0, 0.0});
    ItemSize(total_bb, style.FramePadding.y);
    if (!ItemAdd(total_bb, id, &bb))   do return false

    // Open on click
    hovered, held : bool
    pressed := ButtonBehavior(bb, id, &hovered, &held);
    popup_id := ImHashStr("##ComboPopup", 0, id);
    popup_open := IsPopupOpen(popup_id, ImGuiPopupFlags_None);
    if (pressed && !popup_open)
    {
        OpenPopupEx(popup_id, ImGuiPopupFlags_None);
        popup_open = true;
    }

    // Render shape
    frame_col := GetColorU32(hovered ? ImGuiCol.FrameBgHovered : ImGuiCol.FrameBg);
    value_x2 := ImMax(bb.Min.x, bb.Max.x - arrow_size);
    RenderNavCursor(bb, id);
    if (!(.NoPreview in flags)) {
        AddRectFilled(window.DrawList, bb.Min, ImVec2{value_x2, bb.Max.y}, frame_col, style.FrameRounding, (.NoArrowButton in flags) ? ImDrawFlags_RoundCornersAll : ImDrawFlags_RoundCornersLeft);
    }
    if (!(.NoArrowButton in flags))
    {
        bg_col := GetColorU32((popup_open || hovered) ? ImGuiCol.ButtonHovered : ImGuiCol.Button);
        text_col := GetColorU32(ImGuiCol.Text);
        AddRectFilled(window.DrawList, ImVec2{value_x2, bb.Min.y}, bb.Max, bg_col, style.FrameRounding, (w <= arrow_size) ? ImDrawFlags_RoundCornersAll : ImDrawFlags_RoundCornersRight);
        if (value_x2 + arrow_size - style.FramePadding.x <= bb.Max.x) {
            RenderArrow(window.DrawList, ImVec2{value_x2 + style.FramePadding.y, bb.Min.y + style.FramePadding.y}, text_col, ImGuiDir.Down, 1.0);
        }
    }
    RenderFrameBorder(bb.Min, bb.Max, style.FrameRounding);

    // Custom preview
    if (.CustomPreview in flags)
    {
        g.ComboPreviewData.PreviewRect = ImRect{ _r = {bb.Min.x, bb.Min.y, value_x2, bb.Max.y}};
        assert(preview_value == nil || preview_value[0] == 0);
        preview_value = nil;
    }

    // Render preview and label
    if (preview_value != nil && !(.NoPreview in flags))
    {
        if (g.LogEnabled) {
            LogSetNextTextDecoration("{", "}");
        }
        RenderTextClipped(bb.Min + style.FramePadding, ImVec2{value_x2, bb.Max.y}, preview_value, nil, nil);
    }
    if (label_size.x > 0) {
        RenderText(ImVec2{bb.Max.x + style.ItemInnerSpacing.x, bb.Min.y + style.FramePadding.y}, label);
    }

    if (!popup_open)   do return false

    g.NextWindowData.Flags = backup_next_window_data_flags;
    return BeginComboPopup(popup_id, bb, flags);
}

BeginComboPopup :: proc(popup_id : ImGuiID, bb : ^ImRect, flags : ImGuiComboFlags) -> bool
{
    g := GImGui;
    if (!IsPopupOpen(popup_id, ImGuiPopupFlags_None))
    {
        g.NextWindowData.ClearFlags();
        return false;
    }

    // Set popup size
    w := bb.GetWidth();
    if (.HasSizeConstraint in g.NextWindowData.Flags)
    {
        g.NextWindowData.SizeConstraintRect.Min.x = ImMax(g.NextWindowData.SizeConstraintRect.Min.x, w);
    }
    else
    {
        if ((flags & ImGuiComboFlags_HeightMask_) == 0) {
            flags |= ImGuiComboFlags_HeightRegular;
        }
        assert(math.is_power_of_two(flags & ImGuiComboFlags_HeightMask_)); // Only one
        popup_max_height_in_items := -1;
        if (.HeightRegular in flags)     do popup_max_height_in_items = 8;
        else if (.HeightSmall in flags)  do popup_max_height_in_items = 4;
        else if (.HeightLarge in flags)  do popup_max_height_in_items = 20;
        constraint_min := ImVec2{0.0, 0.0};
        constraint_max := ImVec2{math.F32_MAX, math.F32_MAX}
        if ((.HasSize not_in g.NextWindowData.Flags) || g.NextWindowData.SizeVal.x <= 0.0) { // Don't apply constraints if user specified a size
            constraint_min.x = w;
        }
        if ((.HasSize not_in g.NextWindowData.Flags) || g.NextWindowData.SizeVal.y <= 0.0) {
            constraint_max.y = CalcMaxPopupHeightFromItemCount(popup_max_height_in_items);
        }
        SetNextWindowSizeConstraints(constraint_min, constraint_max);
    }

    // This is essentially a specialized version of BeginPopupEx()
    name : [16]u8
    ImFormatString(name, len(name), "##Combo_%02d", g.BeginComboDepth); // Recycle windows based on depth

    // Set position given a custom constraint (peak into expected window size so we can position it)
    // FIXME: This might be easier to express with an hypothetical SetNextWindowPosConstraints() function?
    // FIXME: This might be moved to Begin() or at least around the same spot where Tooltips and other Popups are calling FindBestWindowPosForPopupEx()?
    if popup_window := FindWindowByName(name); popup_window != nil {
        if (popup_window.WasActive)
        {
            // Always override 'AutoPosLastDirection' to not leave a chance for a past value to affect us.
            size_expected := CalcWindowNextAutoFitSize(popup_window);
            popup_window.AutoPosLastDirection = (.PopupAlignLeft in flags) ? .Left : ImGuiDir.Down; // Left = "Below, Toward Left", Down = "Below, Toward Right (default)"
            r_outer := GetPopupAllowedExtentRect(popup_window);
            pos := FindBestWindowPosForPopupEx(bb.GetBL(), size_expected, &popup_window.AutoPosLastDirection, r_outer, bb, ImGuiPopupPositionPolicy_ComboBox);
            SetNextWindowPos(pos);
        }
    }

    // We don't use BeginPopupEx() solely because we have a custom name string, which we could make an argument to BeginPopupEx()
    window_flags := ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_Popup | ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoMove;
    PushStyleVarX(ImGuiStyleVar_WindowPadding, g.Style.FramePadding.x); // Horizontally align ourselves with the framed text
    ret := Begin(name, nil, window_flags);
    PopStyleVar();
    if (!ret)
    {
        EndPopup();
        assert(false)   // This should never happen as we tested for IsPopupOpen() above
        return false;
    }
    g.BeginComboDepth += 1;
    return true;
}

// [forward declared comment]:
// only call EndCombo() if BeginCombo() returns true!
EndCombo :: proc()
{
    g := GImGui;
    EndPopup();
    g.BeginComboDepth -= 1;
}

// Call directly after the BeginCombo/EndCombo block. The preview is designed to only host non-interactive elements
// (Experimental, see GitHub issues: #1658, #4168)
BeginComboPreview :: proc() -> bool
{
    g := GImGui;
    window := g.CurrentWindow;
    preview_data := &g.ComboPreviewData;

    if (window.SkipItems || !(.Visible in g.LastItemData.StatusFlags))   do return false
    assert(g.LastItemData.Rect.Min.x == preview_data.PreviewRect.Min.x && g.LastItemData.Rect.Min.y == preview_data.PreviewRect.Min.y); // Didn't call after BeginCombo/EndCombo block or forgot to pass ImGuiComboFlags_CustomPreview flag?
    if (!window.ClipRect.Overlaps(preview_data.PreviewRect)) do return false // Narrower test (optional)   

    // FIXME: This could be contained in a PushWorkRect() api
    preview_data.BackupCursorPos = window.DC.CursorPos;
    preview_data.BackupCursorMaxPos = window.DC.CursorMaxPos;
    preview_data.BackupCursorPosPrevLine = window.DC.CursorPosPrevLine;
    preview_data.BackupPrevLineTextBaseOffset = window.DC.PrevLineTextBaseOffset;
    preview_data.BackupLayout = window.DC.LayoutType;
    window.DC.CursorPos = preview_data.PreviewRect.Min + g.Style.FramePadding;
    window.DC.CursorMaxPos = window.DC.CursorPos;
    window.DC.LayoutType = .Horizontal;
    window.DC.IsSameLine = false;
    PushClipRect(preview_data.PreviewRect.Min, preview_data.PreviewRect.Max, true);

    return true;
}

EndComboPreview :: proc()
{
    g := GImGui;
    window := g.CurrentWindow;
    preview_data := &g.ComboPreviewData;

    // FIXME: Using CursorMaxPos approximation instead of correct AABB which we will store in ImDrawCmd in the future
    draw_list := window.DrawList;
    if (window.DC.CursorMaxPos.x < preview_data.PreviewRect.Max.x && window.DC.CursorMaxPos.y < preview_data.PreviewRect.Max.y) {
        if (len(draw_list.CmdBuffer) > 1) // Unlikely case that the PushClipRect() didn't create a command
        {
            r := draw_list.CmdBuffer[len(draw_list.CmdBuffer) - 2].ClipRect;
            draw_list.CmdBuffer[len(draw_list.CmdBuffer) - 1].ClipRect = r
            draw_list._CmdHeader.ClipRect = r
            draw_list._TryMergeDrawCmds();
        }
    }
    PopClipRect();
    window.DC.CursorPos = preview_data.BackupCursorPos;
    window.DC.CursorMaxPos = ImMax(window.DC.CursorMaxPos, preview_data.BackupCursorMaxPos);
    window.DC.CursorPosPrevLine = preview_data.BackupCursorPosPrevLine;
    window.DC.PrevLineTextBaseOffset = preview_data.BackupPrevLineTextBaseOffset;
    window.DC.LayoutType = preview_data.BackupLayout;
    window.DC.IsSameLine = false;
    preview_data.PreviewRect = ImRect();
}

// Getter for the old Combo() API: const char*[]
Items_ArrayGetter :: proc(data : rawptr, idx : i32) -> ^u8
{
    items := cast(^^u8) data;
    return items[idx];
}

// Getter for the old Combo() API: "item1\0item2\0item3\0"
Items_SingleStringGetter :: proc(data : rawptr, idx : i32) -> ^u8
{
    items_separated_by_zeros := cast(^u8) data;
    items_count := 0;
    p := items_separated_by_zeros;
    for (p^)
    {
        if (idx == items_count)   do break
        p += strlen(p) + 1;
        items_count += 1;
    }
    return p^ ? p : nil;
}

// Old API, prefer using BeginCombo() nowadays if you can.
Combo_ex :: proc(label : string, current_item : ^i32, getter : proc(user_data : rawptr, idx : i32) -> ^u8, user_data : rawptr, items_count : i32, popup_max_height_in_items : i32) -> bool
{
    g := GImGui;

    // Call the getter to obtain the preview string which is a parameter to BeginCombo()
    preview_value : ^u8= nil;
    if (current_item^ >= 0 && current_item^ < items_count) {
        preview_value = getter(user_data, current_item^);
    }

    // The old Combo() API exposed "popup_max_height_in_items". The new more general BeginCombo() API doesn't have/need it, but we emulate it here.
    if (popup_max_height_in_items != -1 && !(.HasSizeConstraint in g.NextWindowData.Flags)) {
        SetNextWindowSizeConstraints(ImVec2{0, 0}, ImVec2{math.F32_MAX, CalcMaxPopupHeightFromItemCount(popup_max_height_in_items)});
    }

    if (!BeginCombo(label, preview_value, ImGuiComboFlags_None))   do return false

    // Display items
    value_changed := false;
    clipper : ImGuiListClipper
    clipper.Begin(items_count);
    clipper.IncludeItemByIndex(current_item^);
    for (clipper.Step()) {
        for i := clipper.DisplayStart; i < clipper.DisplayEnd; i += 1
        {
            item_text := getter(user_data, i);
            if (item_text == nil) do item_text = "*Unknown item*";

            PushID(i);
            item_selected := (i == current_item^);
            if (Selectable(item_text, item_selected) && current_item^ != i)
            {
                value_changed = true;
                current_item^ = i;
            }
            if (item_selected)   do SetItemDefaultFocus()
            PopID();
        }
    }

    EndCombo();
    if (value_changed) {
        MarkItemEdited(g.LastItemData.ID);
    }

    return value_changed;
}

// Combo box helper allowing to pass an array of strings.
Combo_str :: proc(label : string, current_item : ^i32, items : []string, height_in_items : i32) -> bool
{
    value_changed := Combo(label, current_item, Items_ArrayGetter, cast(rawptr) items, len(items), height_in_items);
    return value_changed;
}

// Combo box helper allowing to pass all items in a single string literal holding multiple zero-terminated items "item1\0item2\0"
Combo_nil :: proc(label : string, current_item : ^i32, items_separated_by_zeros : [^]u8, height_in_items : i32) -> bool
{
    items_count := 0;
    p := items_separated_by_zeros;       // FIXME-OPT: Avoid computing this, or at least only when combo is open
    for (p^)
    {
        p += strlen(p) + 1;
        items_count += 1;
    }
    value_changed := Combo(label, current_item, Items_SingleStringGetter, cast(rawptr) items_separated_by_zeros, items_count, height_in_items);
    return value_changed;
}

Combo :: proc { Combo_ex, Combo_str, Combo_nil }


//-------------------------------------------------------------------------
// [SECTION] Data Type and Data Formatting Helpers [Internal]
//-------------------------------------------------------------------------
// - DataTypeGetInfo()
// - DataTypeFormatString()
// - DataTypeApplyOp()
// - DataTypeApplyFromText()
// - DataTypeCompare()
// - DataTypeClamp()
// - GetMinimumStepAtDecimalPrecision
// - RoundScalarWithFormat<>()
//-------------------------------------------------------------------------

//TODO remove
GDataTypeInfo := [ImGuiDataType]ImGuiDataTypeInfo {
    .S8     = { size_of(i8),   "S8",   "%d",   "%d"    },  // ImGuiDataType.S8
    .U8     = { size_of(u8),   "U8",   "%u",   "%u"    },
    .S16    = { size_of(i16),  "S16",  "%d",   "%d"    },  // ImGuiDataType.S16
    .U16    = { size_of(u16),  "U16",  "%u",   "%u"    },
    .S32    = { size_of(i32),  "S32",  "%d",   "%d"    },  // ImGuiDataType.S32
    .U32    = { size_of(u32),  "U32",  "%u",   "%u"    },
    .S64    = { size_of(i64),  "S64",  "%I64d","%I64d" },  // ImGuiDataType.S64
    .U64    = { size_of(u64),  "U64",  "%I64u","%I64u" },
    .Float  = { size_of(f32),  "f32", "%.3","%f"    },  // ImGuiDataType.Float (float are promoted to double in va_arg)
    .Double = { size_of(f64),  "f64","%f",  "%lf"   },  // ImGuiDataType.Double
    .Bool   = { size_of(bool), "bool", "%d",   "%d"    },  // ImGuiDataType.Bool
    .String = { 0,             "u8*","%s",   "%s"    },  // ImGuiDataType.String
};

DataTypeGetInfo :: proc(data_type : ImGuiDataType) -> ^ImGuiDataTypeInfo
{
    assert(data_type >= 0 && data_type < ImGuiDataType.COUNT);
    return &GDataTypeInfo[data_type];
}

DataTypeFormatString :: proc(buf : ^u8, buf_size : i32, data_type : ImGuiDataType, p_data : rawptr, format : ^u8) -> i32
{
    // Signedness doesn't matter when pushing integer arguments
    if (data_type == ImGuiDataType.S32 || data_type == ImGuiDataType.U32) {
        return ImFormatString(buf, buf_size, format, (cast(^u32)p_data)^);
    }
    if (data_type == ImGuiDataType.S64 || data_type == ImGuiDataType.U64) {
        return ImFormatString(buf, buf_size, format, (cast(^u64)p_data)^);
    }
    if (data_type == ImGuiDataType.Float) {
        return ImFormatString(buf, buf_size, format, (cast(^f32)p_data)^);
    }
    if (data_type == ImGuiDataType.Double) {
        return ImFormatString(buf, buf_size, format, (cast(^f64)p_data)^);
    }
    if (data_type == ImGuiDataType.S8) {
        return ImFormatString(buf, buf_size, format, (cast(^i8)p_data)^);
    }
    if (data_type == ImGuiDataType.U8) {
        return ImFormatString(buf, buf_size, format, (cast(^u8)p_data)^);
    }
    if (data_type == ImGuiDataType.S16) {
        return ImFormatString(buf, buf_size, format, (cast(^u16)p_data)^);
    }
    if (data_type == ImGuiDataType.U16) {
        return ImFormatString(buf, buf_size, format, (cast(^u16)p_data)^);
    }
    assert(false)
    return 0;
}

DataTypeApplyOp :: proc(data_type : ImGuiDataType, op : i32, output : rawptr, arg1 : rawptr, arg2 : rawptr)
{
    assert(op == '+' || op == '-');
    switch (data_type)
    {
        case ImGuiDataType.S8:
            if (op == '+') { (cast(^i8) output)^  = ImAddClampOverflow((cast(^i8)arg1)^,  (cast(^i8)arg2)^,  IM_S8_MIN,  IM_S8_MAX); }
            if (op == '-') { (cast(^i8) output)^  = ImSubClampOverflow((cast(^i8)arg1)^,  (cast(^i8)arg2)^,  IM_S8_MIN,  IM_S8_MAX); }
            return;
        case ImGuiDataType.U8:
            if (op == '+') { (cast(^u8) output)^  = ImAddClampOverflow((cast(^u8)arg1)^,  (cast(^u8)arg2)^,  IM_U8_MIN,  IM_U8_MAX); }
            if (op == '-') { (cast(^u8) output)^  = ImSubClampOverflow((cast(^u8)arg1)^,  (cast(^u8)arg2)^,  IM_U8_MIN,  IM_U8_MAX); }
            return;
        case ImGuiDataType.S16:
            if (op == '+') { (cast(^u16 )output)^ = ImAddClampOverflow((cast(^u16)arg1)^, (cast(^u16)arg2)^, IM_S16_MIN, IM_S16_MAX); }
            if (op == '-') { (cast(^u16 )output)^ = ImSubClampOverflow((cast(^u16)arg1)^, (cast(^u16)arg2)^, IM_S16_MIN, IM_S16_MAX); }
            return;
        case ImGuiDataType.U16:
            if (op == '+') { (cast(^u16 )output)^ = ImAddClampOverflow((cast(^u16)arg1)^, (cast(^u16)arg2)^, IM_U16_MIN, IM_U16_MAX); }
            if (op == '-') { (cast(^u16 )output)^ = ImSubClampOverflow((cast(^u16)arg1)^, (cast(^u16)arg2)^, IM_U16_MIN, IM_U16_MAX); }
            return;
        case ImGuiDataType.S32:
            if (op == '+') { (cast(^i32 )output)^ = ImAddClampOverflow((cast(^i32)arg1)^, (cast(^i32)arg2)^, IM_S32_MIN, IM_S32_MAX); }
            if (op == '-') { (cast(^i32 )output)^ = ImSubClampOverflow((cast(^i32)arg1)^, (cast(^i32)arg2)^, IM_S32_MIN, IM_S32_MAX); }
            return;
        case ImGuiDataType.U32:
            if (op == '+') { (cast(^u32 )output)^ = ImAddClampOverflow((cast(^u32)arg1)^, (cast(^u32)arg2)^, IM_U32_MIN, IM_U32_MAX); }
            if (op == '-') { (cast(^u32 )output)^ = ImSubClampOverflow((cast(^u32)arg1)^, (cast(^u32)arg2)^, IM_U32_MIN, IM_U32_MAX); }
            return;
        case ImGuiDataType.S64:
            if (op == '+') { (cast(^i64 )output)^ = ImAddClampOverflow((cast(^i64)arg1)^, (cast(^i64)arg2)^, IM_S64_MIN, IM_S64_MAX); }
            if (op == '-') { (cast(^i64 )output)^ = ImSubClampOverflow((cast(^i64)arg1)^, (cast(^i64)arg2)^, IM_S64_MIN, IM_S64_MAX); }
            return;
        case ImGuiDataType.U64:
            if (op == '+') { (cast(^u64 )output)^ = ImAddClampOverflow((cast(^u64)arg1)^, (cast(^u64)arg2)^, IM_U64_MIN, IM_U64_MAX); }
            if (op == '-') { (cast(^u64 )output)^ = ImSubClampOverflow((cast(^u64)arg1)^, (cast(^u64)arg2)^, IM_U64_MIN, IM_U64_MAX); }
            return;
        case ImGuiDataType.Float:
            if (op == '+') { (cast(^f32 )output)^ = (cast(^f32)arg1)^ + (cast(^f32)arg2)^; }
            if (op == '-') { (cast(^f32 )output)^ = (cast(^f32)arg1)^ - (cast(^f32)arg2)^; }
            return;
        case ImGuiDataType.Double:
            if (op == '+') { (cast(^f64 )output)^ = (cast(^f64)arg1)^ + (cast(^f64)arg2)^; }
            if (op == '-') { (cast(^f64 )output)^ = (cast(^f64)arg1)^ - (cast(^f64)arg2)^; }
            return;
        case ImGuiDataType.COUNT: break;
    }
    assert(false)
}

// User can input math operators (e.g. +100) to edit a numerical values.
// NB: This is _not_ a full expression evaluator. We should probably add one and replace this dumb mess..
DataTypeApplyFromText :: proc(buf : ^u8, data_type : ImGuiDataType, p_data : rawptr, format : ^u8, p_data_when_empty : rawptr = nil) -> bool
{
    // Copy the value in an opaque buffer so we can compare at the end of the function if it changed at all.
    type_info := DataTypeGetInfo(data_type);
    data_backup : ImGuiDataTypeStorage
    memcpy(&data_backup, p_data, type_info.Size);

    for (ImCharIsBlankA(buf^))  do buf += 1;
    if (!buf[0])
    {
        if (p_data_when_empty != nil)
        {
            memcpy(p_data, p_data_when_empty, type_info.Size);
            return memcmp(&data_backup, p_data, type_info.Size) != 0;
        }
        return false;
    }

    // Sanitize format
    // - For float/double we have to ignore format with precision (e.g. "%.2f") because sscanf doesn't take them in, so force them into %f and %lf
    // - In theory could treat empty format as using default, but this would only cover rare/bizarre case of using InputScalar() + integer + format string without %.
    format_sanitized : [32]u8
    if (data_type == ImGuiDataType.Float || data_type == ImGuiDataType.Double) {
        format = type_info.ScanFmt;
    }
    else {
        format = ImParseFormatSanitizeForScanning(format, format_sanitized, len(format_sanitized));
    }

    // Small types need a 32-bit buffer to receive the result from scanf()
    v32 := 0;
    if (sscanf(buf, format, len(type_info) >= 4 ? p_data : &v32) < 1)   do return false
    if (len(type_info) < 4)
    {
        if (data_type == ImGuiDataType.S8) {
             (cast(^i8) p_data)^ = cast(i8) ImClamp(v32, cast(i32) IM_S8_MIN, cast(i32) IM_S8_MAX);
        }
        else if (data_type == ImGuiDataType.U8) {
            (cast(^u8) p_data)^ = cast(u8) ImClamp(v32, cast(i32) IM_U8_MIN, cast(i32) IM_U8_MAX);
        }
        else if (data_type == ImGuiDataType.S16) {
            (cast(^u16) p_data)^ = cast(u16) ImClamp(v32, cast(i32) IM_S16_MIN, cast(i32) IM_S16_MAX);
        }
        else if (data_type == ImGuiDataType.U16) {
            (cast(^u16) p_data)^ = cast(u16) ImClamp(v32, cast(i32) IM_U16_MIN, cast(i32) IM_U16_MAX);
        }
        else {
            assert(false)
        }
    }

    return memcmp(&data_backup, p_data, type_info.Size) != 0;
}

DataTypeCompareT :: proc(lhs, rhs : ^$T) -> i32
{
    if (lhs^ < rhs^) do return -1;
    if (lhs^ > rhs^) do return +1;
    return 0;
}

DataTypeCompare :: proc(data_type : ImGuiDataType, arg_1 : rawptr, arg_2 : rawptr) -> i32
{
    switch (data_type)
    {
        case ImGuiDataType.S8:     return DataTypeCompareT(cast(^i8 ) arg_1, cast(^i8 ) arg_2);
        case ImGuiDataType.U8:     return DataTypeCompareT(cast(^u8 ) arg_1, cast(^u8 ) arg_2);
        case ImGuiDataType.S16:    return DataTypeCompareT(cast(^u16) arg_1, cast(^u16) arg_2);
        case ImGuiDataType.U16:    return DataTypeCompareT(cast(^u16) arg_1, cast(^u16) arg_2);
        case ImGuiDataType.S32:    return DataTypeCompareT(cast(^i32) arg_1, cast(^i32) arg_2);
        case ImGuiDataType.U32:    return DataTypeCompareT(cast(^u32) arg_1, cast(^u32) arg_2);
        case ImGuiDataType.S64:    return DataTypeCompareT(cast(^i64) arg_1, cast(^i64) arg_2);
        case ImGuiDataType.U64:    return DataTypeCompareT(cast(^u64) arg_1, cast(^u64) arg_2);
        case ImGuiDataType.Float:  return DataTypeCompareT(cast(^f32) arg_1, cast(^f32) arg_2);
        case ImGuiDataType.Double: return DataTypeCompareT(cast(^f64) arg_1, cast(^f64) arg_2);
        case ImGuiDataType.COUNT:  break;
    }
    assert(false)
    return 0;
}

DataTypeClampT :: proc(v, v_min, v_max : ^$T) -> bool
{
    // Clamp, both sides are optional, return true if modified
    if (v_min && v^ < v_min^) { v^ = v_min^; return true; }
    if (v_max && v^ > v_max^) { v^ = v_max^; return true; }
    return false;
}

DataTypeClamp :: proc(data_type : ImGuiDataType, p_data : rawptr, p_min : rawptr, p_max : rawptr) -> bool
{
    switch (data_type)
    {
        case ImGuiDataType.S8:     return DataTypeClampT(cast(^i8 ) p_data, cast(^i8 ) p_min, cast(^i8 ) p_max);
        case ImGuiDataType.U8:     return DataTypeClampT(cast(^u8 ) p_data, cast(^u8 ) p_min, cast(^u8 ) p_max);
        case ImGuiDataType.S16:    return DataTypeClampT(cast(^u16) p_data, cast(^u16) p_min, cast(^u16) p_max);
        case ImGuiDataType.U16:    return DataTypeClampT(cast(^u16) p_data, cast(^u16) p_min, cast(^u16) p_max);
        case ImGuiDataType.S32:    return DataTypeClampT(cast(^i32) p_data, cast(^i32) p_min, cast(^i32) p_max);
        case ImGuiDataType.U32:    return DataTypeClampT(cast(^u32) p_data, cast(^u32) p_min, cast(^u32) p_max);
        case ImGuiDataType.S64:    return DataTypeClampT(cast(^i64) p_data, cast(^i64) p_min, cast(^i64) p_max);
        case ImGuiDataType.U64:    return DataTypeClampT(cast(^u64) p_data, cast(^u64) p_min, cast(^u64) p_max);
        case ImGuiDataType.Float:  return DataTypeClampT(cast(^f32) p_data, cast(^f32) p_min, cast(^f32) p_max);
        case ImGuiDataType.Double: return DataTypeClampT(cast(^f64) p_data, cast(^f64) p_min, cast(^f64) p_max);
        case ImGuiDataType.COUNT:  break;
    }
    assert(false)
    return false;
}

DataTypeIsZero :: proc(data_type : ImGuiDataType, p_data : rawptr) -> bool
{
    g := GImGui;
    return DataTypeCompare(data_type, p_data, &g.DataTypeZeroValue) == 0;
}

GetMinimumStepAtDecimalPrecision :: proc(decimal_precision : i32) -> f32
{
    @(static)
    min_steps : f32[10] = { 1.0, 0.1, 0.01, 0.001, 0.0001, 0.00001, 0.000001, 0.0000001, 0.00000001, 0.000000001 };
    if (decimal_precision < 0)   do return math.F32_MIN
    return (decimal_precision < len(min_steps)) ? min_steps[decimal_precision] : ImPow(10.0, (f32)-decimal_precision);
}

RoundScalarWithFormatT :: proc(format : ^u8, data_type : ImGuiDataType, v : $TYPE) -> TYPE
{
    _ = data_type;
    assert(data_type == ImGuiDataType.Float || data_type == ImGuiDataType.Double);
    fmt_start := ImParseFormatFindStart(format);
    if (fmt_start[0] != '%' || fmt_start[1] == '%') do return v; // Don't apply if the value is not visible in the format string
        

    // Sanitize format
    fmt_sanitized : [32]u8
    ImParseFormatSanitizeForPrinting(fmt_start, fmt_sanitized, len(fmt_sanitized));
    fmt_start = fmt_sanitized;

    // Format value with our rounding, and read back
    v_str : [64]u8
    ImFormatString(v_str, len(v_str), fmt_start, v);
    p : ^u8 = v_str;
    for (p^ == ' ') do p += 1;
    v = transmute(TYPE) ImAtof(p);

    return v;
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: DragScalar, DragFloat, DragInt, etc.
//-------------------------------------------------------------------------
// - DragBehaviorT<>() [Internal]
// - DragBehavior() [Internal]
// - DragScalar()
// - DragScalarN()
// - DragFloat()
// - DragFloat2()
// - DragFloat3()
// - DragFloat4()
// - DragFloatRange2()
// - DragInt()
// - DragInt2()
// - DragInt3()
// - DragInt4()
// - DragIntRange2()
//-------------------------------------------------------------------------

// This is called by DragBehavior() when the widget is active (held by mouse or being manipulated with Nav controls)
DragBehaviorT :: proc($TYPE, $SIGNEDTYPE, $FLOATTYPE : typeid, data_type : ImGuiDataType, v : ^TYPE, v_speed : f32, v_min : TYPE, v_max : TYPE, format : ^u8, flags : ImGuiSliderFlags) -> bool
{
    g := GImGui;
    axis := (.Vertical in flags) ? ImGuiAxis.Y : ImGuiAxis.X;
    is_bounded := (v_min < v_max) || ((v_min == v_max) && (v_min != 0.0 || (.ClampZeroRange in flags)));
    is_wrapped := is_bounded && (.WrapAround in flags);
    is_logarithmic := (.Logarithmic in flags)
    is_floating_point := (data_type == ImGuiDataType.Float) || (data_type == ImGuiDataType.Double);

    // Default tweak speed
    if (v_speed == 0.0 && is_bounded && (v_max - v_min < math.F32_MAX)) {
        v_speed = (f32)((v_max - v_min) * g.DragSpeedDefaultRatio);
    }

    // Inputs accumulates into g.DragCurrentAccum, which is flushed into the current value as soon as it makes a difference with our precision settings
    adjust_delta := 0.0;
    if (g.ActiveIdSource == .Mouse && IsMousePosValid() && IsMouseDragPastThreshold(0, g.IO.MouseDragThreshold * DRAG_MOUSE_THRESHOLD_FACTOR))
    {
        adjust_delta = g.IO.MouseDelta[axis];
        if (g.IO.KeyAlt && !(.NoSpeedTweaks in flags)) {
            adjust_delta *= 1.0 / 100.0;
        }
        if (g.IO.KeyShift && !(.NoSpeedTweaks in flags))   do adjust_delta *= 10.0
    }
    else if (g.ActiveIdSource == .Keyboard || g.ActiveIdSource == .Gamepad)
    {
        decimal_precision := is_floating_point ? ImParseFormatPrecision(format, 3) : 0;
        tweak_slow := IsKeyDown((g.NavInputSource == .Gamepad) ? ImGuiKey.NavGamepadTweakSlow : ImGuiKey.NavKeyboardTweakSlow);
        tweak_fast := IsKeyDown((g.NavInputSource == .Gamepad) ? ImGuiKey.NavGamepadTweakFast : ImGuiKey.NavKeyboardTweakFast);
        tweak_factor := (.NoSpeedTweaks in flags) ? 1.0 : tweak_slow ? 1.0 / 10.0 : tweak_fast ? 10.0 : 1.0;
        adjust_delta = GetNavTweakPressedAmount(axis) * tweak_factor;
        v_speed = ImMax(v_speed, GetMinimumStepAtDecimalPrecision(decimal_precision));
    }
    adjust_delta *= v_speed;

    // For vertical drag we currently assume that Up=higher value (like we do with vertical sliders). This may become a parameter.
    if (axis == ImGuiAxis.Y) {
        adjust_delta = -adjust_delta;
    }

    // For logarithmic use our range is effectively 0..1 so scale the delta into that range
    if (is_logarithmic && (v_max - v_min < math.F32_MAX) && ((v_max - v_min) > 0.000001)) {// Epsilon to avoid /0
        adjust_delta /= (f32)(v_max - v_min);
    }

    // Clear current value on activation
    // Avoid altering values and clamping when we are _already_ past the limits and heading in the same direction, so e.g. if range is 0..255, current value is 300 and we are pushing to the right side, keep the 300.
    is_just_activated := g.ActiveIdIsJustActivated;
    is_already_past_limits_and_pushing_outward := is_bounded && !is_wrapped && ((v^ >= v_max && adjust_delta > 0.0) || (v^ <= v_min && adjust_delta < 0.0));
    if (is_just_activated || is_already_past_limits_and_pushing_outward)
    {
        g.DragCurrentAccum = 0.0;
        g.DragCurrentAccumDirty = false;
    }
    else if (adjust_delta != 0.0)
    {
        g.DragCurrentAccum += adjust_delta;
        g.DragCurrentAccumDirty = true;
    }

    if (!g.DragCurrentAccumDirty)   do return false

    v_cur := v^;
    v_old_ref_for_accum_remainder := cast(FLOATTYPE) 0.0;

    logarithmic_zero_epsilon := 0.0; // Only valid when is_logarithmic is true
    zero_deadzone_halfsize := 0.0; // Drag widgets have no deadzone (as it doesn't make sense)
    if (is_logarithmic)
    {
        // When using logarithmic sliders, we need to clamp to avoid hitting zero, but our choice of clamp value greatly affects slider precision. We attempt to use the specified precision to estimate a good lower bound.
        decimal_precision := is_floating_point ? ImParseFormatPrecision(format, 3) : 1;
        logarithmic_zero_epsilon = ImPow(0.1, cast(f32) decimal_precision);

        // Convert to parametric space, apply delta, convert back
        v_old_parametric := ScaleRatioFromValueT(TYPE, SIGNEDTYPE, FLOATTYPE, data_type, v_cur, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);
        v_new_parametric := v_old_parametric + g.DragCurrentAccum;
        v_cur = ScaleValueFromRatioT(TYPE, SIGNEDTYPE, FLOATTYPE, data_type, v_new_parametric, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);
        v_old_ref_for_accum_remainder = v_old_parametric;
    }
    else
    {
        v_cur += cast(SIGNEDTYPE) g.DragCurrentAccum;
    }

    // Round to user desired precision based on format string
    if (is_floating_point && !(.NoRoundToFormat in flags)) {
        v_cur = RoundScalarWithFormatT(TYPE, format, data_type, v_cur);
    }

    // Preserve remainder after rounding has been applied. This also allow slow tweaking of values.
    g.DragCurrentAccumDirty = false;
    if (is_logarithmic)
    {
        // Convert to parametric space, apply delta, convert back
        v_new_parametric := ScaleRatioFromValueT(TYPE, SIGNEDTYPE, FLOATTYPE, data_type, v_cur, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);
        g.DragCurrentAccum -= cast(f32) (v_new_parametric - v_old_ref_for_accum_remainder);
    }
    else
    {
        g.DragCurrentAccum -= cast(f32) (cast(SIGNEDTYPE) v_cur - cast(SIGNEDTYPE) v^);
    }

    // Lose zero sign for float/double
    if (v_cur == transmute(TYPE)-0)   do v_cur = cast(TYPE)0

    if (v^ != v_cur && is_bounded)
    {
        if (is_wrapped)
        {
            // Wrap values
            if (v_cur < v_min) do v_cur += v_max - v_min + (is_floating_point ? 0 : 1);
            if (v_cur > v_max) do v_cur -= v_max - v_min + (is_floating_point ? 0 : 1);
        }
        else
        {
            // Clamp values + handle overflow/wrap-around for integer types.
            if (v_cur < v_min || (v_cur > v^ && adjust_delta < 0.0 && !is_floating_point))   do v_cur = v_min
            if (v_cur > v_max || (v_cur < v^ && adjust_delta > 0.0 && !is_floating_point))   do v_cur = v_max
        }
    }

    // Apply result
    if (v^ == v_cur)   do return false
    v^ = v_cur;
    return true;
}

DragBehavior :: proc(id : ImGuiID, data_type : ImGuiDataType, p_v : rawptr, v_speed : f32, p_min : rawptr, p_max : rawptr, format : ^u8, flags : ImGuiSliderFlags) -> bool
{
    // Read imgui.cpp "API BREAKING CHANGES" section for 1.78 if you hit this assert.
    assert((flags == 1 || (flags & ImGuiSliderFlags_InvalidMask_) == 0), "Invalid ImGuiSliderFlags flags! Has the legacy 'f32 power' argument been mistakenly cast to flags? Call function with ImGuiSliderFlags_Logarithmic flags instead.");

    g := GImGui;
    if (g.ActiveId == id)
    {
        // Those are the things we can do easily outside the DragBehaviorT<> template, saves code generation.
        if (g.ActiveIdSource == .Mouse && !g.IO.MouseDown[0])   do ClearActiveID()
        else if ((g.ActiveIdSource == .Keyboard || g.ActiveIdSource == .Gamepad) && g.NavActivatePressedId == id && !g.ActiveIdIsJustActivated)   do ClearActiveID()
    }
    if (g.ActiveId != id)   do return false
    if ((.ReadOnly in g.LastItemData.ItemFlags) || (.ReadOnly in flags))   do return false

    switch (data_type)
    {
        case ImGuiDataType.S8:     { v32 := cast(i32) (cast(^i8)p_v)^;  r := DragBehaviorT(i32, i32, f32, .S32, &v32, v_speed, p_min ? (cast(^i8) p_min)^ : IM_S8_MIN,  p_max ? (cast(^i8)p_max)^  : IM_S8_MAX,  format, flags); if (r) do (cast(^i8)p_v)^ = cast(i8) v32; return r; }
        case ImGuiDataType.U8:     { v32 := cast(u32) (cast(^u8)p_v)^;  r := DragBehaviorT(u32, i32, f32, .U32, &v32, v_speed, p_min ? (cast(^u8) p_min)^ : IM_U8_MIN,  p_max ? (cast(^u8)p_max)^  : IM_U8_MAX,  format, flags); if (r) do (cast(^u8)p_v)^ = cast(u8) v32; return r; }
        case ImGuiDataType.S16:    { v32 := cast(i32) (cast(^u16)p_v)^; r := DragBehaviorT(i32, i32, f32, .S32, &v32, v_speed, p_min ? (cast(^u16)p_min)^ : IM_S16_MIN, p_max ? (cast(^u16)p_max)^ : IM_S16_MAX, format, flags); if (r) do (cast(^u16)p_v)^ = cast(u16) v32; return r; }
        case ImGuiDataType.U16:    { v32 := cast(u32) (cast(^u16)p_v)^; r := DragBehaviorT(u32, i32, f32, .U32, &v32, v_speed, p_min ? (cast(^u16)p_min)^ : IM_U16_MIN, p_max ? (cast(^u16)p_max)^ : IM_U16_MAX, format, flags); if (r) do (cast(^u16)p_v)^ = cast(u16) v32; return r; }
        case ImGuiDataType.S32:    return DragBehaviorT(i32, i32, f32, data_type, cast(^i32)p_v, v_speed, p_min ? (cast(^i32)p_min)^ :    IM_S32_MIN, p_max ? (cast(^i32)p_max)^ : IM_S32_MAX  , format, flags);
        case ImGuiDataType.U32:    return DragBehaviorT(u32, i32, f32, data_type, cast(^u32)p_v, v_speed, p_min ? (cast(^u32)p_min)^ :    IM_U32_MIN, p_max ? (cast(^u32)p_max)^ : IM_U32_MAX  , format, flags);
        case ImGuiDataType.S64:    return DragBehaviorT(i64, i64, f64, data_type, cast(^i64)p_v, v_speed, p_min ? (cast(^i64)p_min)^ :    IM_S64_MIN, p_max ? (cast(^i64)p_max)^ : IM_S64_MAX  , format, flags);
        case ImGuiDataType.U64:    return DragBehaviorT(u64, i64, f64, data_type, cast(^u64)p_v, v_speed, p_min ? (cast(^u64)p_min)^ :    IM_U64_MIN, p_max ? (cast(^u64)p_max)^ : IM_U64_MAX  , format, flags);
        case ImGuiDataType.Float:  return DragBehaviorT(f32, f32, f32, data_type, cast(^f32)p_v, v_speed, p_min ? (cast(^f32)p_min)^ : -math.F32_MAX, p_max ? (cast(^f32)p_max)^ : math.F32_MAX, format, flags);
        case ImGuiDataType.Double: return DragBehaviorT(f64, f64, f64, data_type, cast(^f64)p_v, v_speed, p_min ? (cast(^f64)p_min)^ : -math.F32_MAX, p_max ? (cast(^f64)p_max)^ : math.F64_MAX, format, flags);
        case ImGuiDataType.COUNT:  break;
    }
    assert(false)
    return false;
}

// Note: p_data, p_min and p_max are _pointers_ to a memory address holding the data. For a Drag widget, p_min and p_max are optional.
// Read code of e.g. DragFloat(), DragInt() etc. or examples in 'Demo.Widgets.Data Types' to understand how to use this function directly.
DragScalar :: proc(label : string, data_type : ImGuiDataType, p_data : rawptr, v_speed : f32, p_min : rawptr, p_max : rawptr, format : ^u8, flags : ImGuiSliderFlags) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    style := &g.Style;
    id := GetID(window, label);
    w := CalcItemWidth();

    label_size := CalcTextSize(label, nil, true);
    frame_bb := ImRect(window.DC.CursorPos, window.DC.CursorPos + ImVec2{w, label_size.y + style.FramePadding.y * 2.0});
    total_bb := ImRect(frame_bb.Min, frame_bb.Max + ImVec2{label_size.x > 0.0 ? style.ItemInnerSpacing.x + label_size.x : 0.0, 0.0});

    temp_input_allowed := (.NoInput not_in flags);
    ItemSize(total_bb, style.FramePadding.y);
    if (!ItemAdd(total_bb, id, &frame_bb, temp_input_allowed ? ImGuiItemFlags_Inputable : 0))   do return false

    // Default format string when passing NULL
    if (format == nil) do format = DataTypeGetInfo(data_type)->PrintFmt;

    hovered := ItemHoverable(frame_bb, id, g.LastItemData.ItemFlags);
    temp_input_is_active := temp_input_allowed && TempInputIsActive(id);
    if (!temp_input_is_active)
    {
        // Tabbing or CTRL-clicking on Drag turns it into an InputText
        clicked := hovered && IsMouseClicked(0, ImGuiInputFlags_None, id);
        double_clicked := (hovered && g.IO.MouseClickedCount[0] == 2 && TestKeyOwner(ImGuiKey.MouseLeft, id));
        make_active := (clicked || double_clicked || g.NavActivateId == id);
        if (make_active && (clicked || double_clicked)) {
            SetKeyOwner(ImGuiKey.MouseLeft, id);
        }
        if (make_active && temp_input_allowed) {
            if ((clicked && g.IO.KeyCtrl) || double_clicked || (g.NavActivateId == id && (.PreferInput in g.NavActivateFlags))) {
                temp_input_is_active = true;
            }
        }

        // (Optional) simple click (without moving) turns Drag into an InputText
        if (g.IO.ConfigDragClickToInputText && temp_input_allowed && !temp_input_is_active) {
            if (g.ActiveId == id && hovered && g.IO.MouseReleased[0] && !IsMouseDragPastThreshold(0, g.IO.MouseDragThreshold * DRAG_MOUSE_THRESHOLD_FACTOR))
            {
                g.NavActivateId = id;
                g.NavActivateFlags = ImGuiActivateFlags_PreferInput;
                temp_input_is_active = true;
            }
        }

        // Store initial value (not used by main lib but available as a convenience but some mods e.g. to revert)
        if (make_active) {
            memcpy(&g.ActiveIdValueOnActivation, p_data, DataTypeGetInfo(data_type)->Size);
        }

        if (make_active && !temp_input_is_active)
        {
            SetActiveID(id, window);
            SetFocusID(id, window);
            FocusWindow(window);
            g.ActiveIdUsingNavDirMask = (1 << .Left) | (1 << .Right);
        }
    }

    if (temp_input_is_active)
    {
        // Only clamp CTRL+Click input when ImGuiSliderFlags_ClampOnInput is set (generally via ImGuiSliderFlags_AlwaysClamp)
        clamp_enabled := false;
        if ((.ClampOnInput in flags) && (p_min != nil || p_max != nil))
        {
            clamp_range_dir := (p_min != nil && p_max != nil) ? DataTypeCompare(data_type, p_min, p_max) : 0; // -1 when *p_min < *p_max, == 0 when *p_min == *p_max
            if (p_min == nil || p_max == nil || clamp_range_dir < 0)   do clamp_enabled = true
            else if (clamp_range_dir == 0) {
                clamp_enabled = DataTypeIsZero(data_type, p_min) ? ((.ClampZeroRange in flags) != 0) : true;
            }
        }
        return TempInputScalar(frame_bb, id, label, data_type, p_data, format, clamp_enabled ? p_min : nil, clamp_enabled ? p_max : nil);
    }

    // Draw frame
    frame_col := GetColorU32(g.ActiveId == id ? ImGuiCol.FrameBgActive : hovered ? ImGuiCol.FrameBgHovered : ImGuiCol.FrameBg);
    RenderNavCursor(frame_bb, id);
    RenderFrame(frame_bb.Min, frame_bb.Max, frame_col, true, style.FrameRounding);

    // Drag behavior
    value_changed := DragBehavior(id, data_type, p_data, v_speed, p_min, p_max, format, flags);
    if (value_changed)   do MarkItemEdited(id)

    // Display value using user-provided display format so user can add prefix/suffix/decorations to the value.
    value_buf : [64]u8
    value_buf_end := value_buf + DataTypeFormatString(value_buf, len(value_buf), data_type, p_data, format);
    if (g.LogEnabled) {
        LogSetNextTextDecoration("{", "}");
    }
    RenderTextClipped(frame_bb.Min, frame_bb.Max, value_buf, value_buf_end, nil, ImVec2{0.5, 0.5});

    if (label_size.x > 0.0) {
        RenderText(ImVec2{frame_bb.Max.x + style.ItemInnerSpacing.x, frame_bb.Min.y + style.FramePadding.y}, label);
    }

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags | (temp_input_allowed ? ImGuiItemStatusFlags_Inputable : 0));
    return value_changed;
}

DragScalarN :: proc(label : string, data_type : ImGuiDataType, p_data : rawptr, components : i32, v_speed : f32, p_min : rawptr, p_max : rawptr, format : ^u8, flags : ImGuiSliderFlags) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    value_changed := false;
    BeginGroup();
    PushID(label);
    PushMultiItemsWidths(components, CalcItemWidth());
    type_size := GDataTypeInfo[data_type].Size;
    for i := 0; i < components; i += 1
    {
        PushID(i);
        if (i > 0) {
            SameLine(0, g.Style.ItemInnerSpacing.x);
        }
        value_changed |= DragScalar("", data_type, p_data, v_speed, p_min, p_max, format, flags);
        PopID();
        PopItemWidth();
        p_data = p_data + type_size;
    }
    PopID();

    label_end := FindRenderedText(label);
    if (label != label_end)
    {
        SameLine(0, g.Style.ItemInnerSpacing.x);
        TextEx(label, label_end);
    }

    EndGroup();
    return value_changed;
}

// [forward declared comment]:
// If v_min >= v_max we have no bound
DragFloat :: proc(label : string, v : ^f32, v_speed : f32 = 1, v_min : f32 = 0, v_max : f32 = 0, format : string = "%.3f", flags : ImGuiSliderFlags = {}) -> bool
{
    return DragScalar(label, ImGuiDataType.Float, v, v_speed, &v_min, &v_max, format, flags);
}

DragFloat2 :: proc(label : string, v : [2]f32, v_speed : f32 = 1, v_min : f32 = 0, v_max : f32 = 0, format : string = "%.3f", flags : ImGuiSliderFlags = {}) -> bool
{
    return DragScalarN(label, ImGuiDataType.Float, v, 2, v_speed, &v_min, &v_max, format, flags);
}

DragFloat3 :: proc(label : string, v : [3]f32, v_speed : f32 = 1, v_min : f32 = 0, v_max : f32 = 0, format : string = "%.3f", flags : ImGuiSliderFlags = {}) -> bool
{
    return DragScalarN(label, ImGuiDataType.Float, v, 3, v_speed, &v_min, &v_max, format, flags);
}

DragFloat4 :: proc(label : string, v : [4]f32, v_speed : f32 = 1, v_min : f32 = 0, v_max : f32 = 0, format : string = "%.3f", flags : ImGuiSliderFlags = {}) -> bool
{
    return DragScalarN(label, ImGuiDataType.Float, v, 4, v_speed, &v_min, &v_max, format, flags);
}

// NB: You likely want to specify the ImGuiSliderFlags_AlwaysClamp when using this.
DragFloatRange2 :: proc(label : string, v_current_min : ^f32, v_current_max : ^f32, v_speed : f32 = 1, v_min : f32 = 0, v_max : f32 = 0, format : string = "%.3f", format_max : string = "", flags : ImGuiSliderFlags = {}) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    PushID(label);
    BeginGroup();
    PushMultiItemsWidths(2, CalcItemWidth());

    min_min := (v_min >= v_max) ? -math.F32_MAX : v_min;
    min_max := (v_min >= v_max) ? v_current_max^ : ImMin(v_max, v_current_max^);
    min_flags := flags | ((min_min == min_max) ? ImGuiSliderFlags_ReadOnly : 0);
    value_changed := DragScalar("##min", ImGuiDataType.Float, v_current_min, v_speed, &min_min, &min_max, format, min_flags);
    PopItemWidth();
    SameLine(0, g.Style.ItemInnerSpacing.x);

    max_min := (v_min >= v_max) ? v_current_min^ : ImMax(v_min, v_current_min^);
    max_max := (v_min >= v_max) ? math.F32_MAX : v_max;
    max_flags := flags | ((max_min == max_max) ? ImGuiSliderFlags_ReadOnly : 0);
    value_changed |= DragScalar("##max", ImGuiDataType.Float, v_current_max, v_speed, &max_min, &max_max, format_max ? format_max : format, max_flags);
    PopItemWidth();
    SameLine(0, g.Style.ItemInnerSpacing.x);

    TextEx(label, FindRenderedText(label));
    EndGroup();
    PopID();

    return value_changed;
}

// NB: v_speed is float to allow adjusting the drag speed with more precision
// [forward declared comment]:
// If v_min >= v_max we have no bound
DragInt :: proc(label : string, v : ^i32, v_speed : f32, v_min : i32, v_max : i32, format : string = "%d", flags : ImGuiSliderFlags = {}) -> bool // TODO default args
{
    return DragScalar(label, ImGuiDataType.S32, v, v_speed, &v_min, &v_max, format, flags);
}

DragInt2 :: proc(label : string, v : [2]i32, v_speed : f32, v_min : i32, v_max : i32, format : string = "%d", flags : ImGuiSliderFlags = {}) -> bool // TODO default args
{
    return DragScalarN(label, ImGuiDataType.S32, v, 2, v_speed, &v_min, &v_max, format, flags);
}

DragInt3 :: proc(label : string, v : [3]i32, v_speed : f32, v_min : i32, v_max : i32, format : string = "%d", flags : ImGuiSliderFlags = {}) -> bool // TODO default args
{
    return DragScalarN(label, ImGuiDataType.S32, v, 3, v_speed, &v_min, &v_max, format, flags);
}

DragInt4 :: proc(label : string, v : [4]i32, v_speed : f32, v_min : i32, v_max : i32, format : string = "%d", flags : ImGuiSliderFlags = {}) -> bool // TODO default args
{
    return DragScalarN(label, ImGuiDataType.S32, v, 4, v_speed, &v_min, &v_max, format, flags);
}

// NB: You likely want to specify the ImGuiSliderFlags_AlwaysClamp when using this.
DragIntRange2 :: proc(label : string, v_current_min : ^i32, v_current_max : ^i32, v_speed : f32, v_min : i32, v_max : i32, format : string = "%d", format_max : string, flags : ImGuiSliderFlags = {}) -> bool // TODO default args
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    PushID(label);
    BeginGroup();
    PushMultiItemsWidths(2, CalcItemWidth());

    min_min := (v_min >= v_max) ? INT_MIN : v_min;
    min_max := (v_min >= v_max) ? v_current_max^ : ImMin(v_max, v_current_max^);
    min_flags := flags | ((min_min == min_max) ? ImGuiSliderFlags_ReadOnly : 0);
    value_changed := DragInt("##min", v_current_min, v_speed, min_min, min_max, format, min_flags);
    PopItemWidth();
    SameLine(0, g.Style.ItemInnerSpacing.x);

    max_min := (v_min >= v_max) ? v_current_min^ : ImMax(v_min, v_current_min^);
    max_max := (v_min >= v_max) ? INT_MAX : v_max;
    max_flags := flags | ((max_min == max_max) ? ImGuiSliderFlags_ReadOnly : 0);
    value_changed |= DragInt("##max", v_current_max, v_speed, max_min, max_max, format_max ? format_max : format, max_flags);
    PopItemWidth();
    SameLine(0, g.Style.ItemInnerSpacing.x);

    TextEx(label, FindRenderedText(label));
    EndGroup();
    PopID();

    return value_changed;
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: SliderScalar, SliderFloat, SliderInt, etc.
//-------------------------------------------------------------------------
// - ScaleRatioFromValueT<> [Internal]
// - ScaleValueFromRatioT<> [Internal]
// - SliderBehaviorT<>() [Internal]
// - SliderBehavior() [Internal]
// - SliderScalar()
// - SliderScalarN()
// - SliderFloat()
// - SliderFloat2()
// - SliderFloat3()
// - SliderFloat4()
// - SliderAngle()
// - SliderInt()
// - SliderInt2()
// - SliderInt3()
// - SliderInt4()
// - VSliderScalar()
// - VSliderFloat()
// - VSliderInt()
//-------------------------------------------------------------------------

// Convert a value v in the output space of a slider into a parametric position on the slider itself (the logical opposite of ScaleValueFromRatioT)
ScaleRatioFromValueT :: proc($TYPE, $SIGNEDTYPE, $FLOATTYPE : typeid, data_type : ImGuiDataType, v, v_min, v_max : TYPE, is_logarithmic : bool, logarithmic_zero_epsilon : f32, zero_deadzone_halfsize : f32) -> f32
{
    if (v_min == v_max)   do return 0.0
    _ = data_type;

    v_clamped := (v_min < v_max) ? ImClamp(v, v_min, v_max) : ImClamp(v, v_max, v_min);
    if (is_logarithmic)
    {
        flipped := v_max < v_min;

        if (flipped) {// Handle the case where the range is backwards
            ImSwap(v_min, v_max);
        }

        // Fudge min/max to avoid getting close to log(0)
        v_min_fudged := (ImAbs(cast(FLOATTYPE)v_min) < logarithmic_zero_epsilon) ? ((v_min < 0.0) ? -logarithmic_zero_epsilon : logarithmic_zero_epsilon) : cast(FLOATTYPE)v_min;
        v_max_fudged := (ImAbs(cast(FLOATTYPE)v_max) < logarithmic_zero_epsilon) ? ((v_max < 0.0) ? -logarithmic_zero_epsilon : logarithmic_zero_epsilon) : cast(FLOATTYPE)v_max;

        // Awkward special cases - we need ranges of the form (-100 .. 0) to convert to (-100 .. -epsilon), not (-100 .. epsilon)
        if ((v_min == 0.0) && (v_max < 0.0)) {
            v_min_fudged = -logarithmic_zero_epsilon;
        }
        else if ((v_max == 0.0) && (v_min < 0.0)) {
            v_max_fudged = -logarithmic_zero_epsilon;
        }

        result : f32
        if (v_clamped <= v_min_fudged) {
            result = 0.0; // Workaround for values that are in-range but below our fudge
        }
        else if (v_clamped >= v_max_fudged) {
            result = 1.0; // Workaround for values that are in-range but above our fudge
        }
        else if ((v_min * v_max) < 0.0) // Range crosses zero, so split into two portions
        {
            zero_point_center := (-cast(f32) v_min) / (cast(f32) v_max - cast(f32) v_min); // The zero point in parametric space.  There's an argument we should take the logarithmic nature into account when calculating this, but for now this should do (and the most common case of a symmetrical range works fine)
            zero_point_snap_L := zero_point_center - zero_deadzone_halfsize;
            zero_point_snap_R := zero_point_center + zero_deadzone_halfsize;
            if (v == 0.0) {
                result = zero_point_center; // Special case for exactly zero
            }
            else if (v < 0.0) {
                result = (1.0 - (f32)(ImLog(-cast(FLOATTYPE)v_clamped / logarithmic_zero_epsilon) / ImLog(-v_min_fudged / logarithmic_zero_epsilon))) * zero_point_snap_L;
            }
            else {
                result = zero_point_snap_R + ((f32)(ImLog(cast(FLOATTYPE)v_clamped / logarithmic_zero_epsilon) / ImLog(v_max_fudged / logarithmic_zero_epsilon)) * (1.0 - zero_point_snap_R));
            }
        }
        else if ((v_min < 0.0) || (v_max < 0.0)) {// Entirely negative slider
            result = 1.0 - (f32)(ImLog(-cast(FLOATTYPE)v_clamped / -v_max_fudged) / ImLog(-v_min_fudged / -v_max_fudged));
        }
        else {
            result = (f32)(ImLog(cast(FLOATTYPE)v_clamped / v_min_fudged) / ImLog(v_max_fudged / v_min_fudged));
        }

        return flipped ? (1.0 - result) : result;
    }
    else
    {
        // Linear slider
        return (f32)(cast(FLOATTYPE)cast(SIGNEDTYPE)(v_clamped - v_min) / cast(FLOATTYPE)cast(SIGNEDTYPE)(v_max - v_min));
    }
}

// Convert a parametric position on a slider into a value v in the output space (the logical opposite of ScaleRatioFromValueT)
ScaleValueFromRatioT :: proc($TYPE, $SIGNEDTYPE, $FLOATTYPE : typeid, data_type : ImGuiDataType, t : f32, v_min, v_max : TYPE, is_logarithmic : bool, logarithmic_zero_epsilon : f32, zero_deadzone_halfsize : f32) -> TYPE
{
    // We special-case the extents because otherwise our logarithmic fudging can lead to "mathematically correct"
    // but non-intuitive behaviors like a fully-left slider not actually reaching the minimum value. Also generally simpler.
    if (t <= 0.0 || v_min == v_max)   do return v_min
    if (t >= 1.0)   do return v_max

    result : TYPE = 0;
    if (is_logarithmic)
    {
        // Fudge min/max to avoid getting silly results close to zero
        v_min_fudged := (ImAbs(cast(FLOATTYPE)v_min) < logarithmic_zero_epsilon) ? ((v_min < 0.0) ? -logarithmic_zero_epsilon : logarithmic_zero_epsilon) : cast(FLOATTYPE) v_min;
        v_max_fudged := (ImAbs(cast(FLOATTYPE)v_max) < logarithmic_zero_epsilon) ? ((v_max < 0.0) ? -logarithmic_zero_epsilon : logarithmic_zero_epsilon) : cast(FLOATTYPE) v_max;

        flipped := v_max < v_min; // Check if range is "backwards"
        if (flipped) {
            ImSwap(v_min_fudged, v_max_fudged);
        }

        // Awkward special case - we need ranges of the form (-100 .. 0) to convert to (-100 .. -epsilon), not (-100 .. epsilon)
        if ((v_max == 0.0) && (v_min < 0.0)) {
            v_max_fudged = -logarithmic_zero_epsilon;
        }

        t_with_flip := flipped ? (1.0 - t) : t; // t, but flipped if necessary to account for us flipping the range

        if ((v_min * v_max) < 0.0) // Range crosses zero, so we have to do this in two parts
        {
            zero_point_center := (-cast(f32) ImMin(v_min, v_max)) / ImAbs(cast(f32) v_max - cast(f32) v_min); // The zero point in parametric space
            zero_point_snap_L := zero_point_center - zero_deadzone_halfsize;
            zero_point_snap_R := zero_point_center + zero_deadzone_halfsize;
            if (t_with_flip >= zero_point_snap_L && t_with_flip <= zero_point_snap_R) {
                result = 0.0; // Special case to make getting exactly zero possible (the epsilon prevents it otherwise)
            }
            else if (t_with_flip < zero_point_center) {
                result = cast(TYPE) -(logarithmic_zero_epsilon * ImPow(-v_min_fudged / logarithmic_zero_epsilon, cast(FLOATTYPE) (1.0 - (t_with_flip / zero_point_snap_L))));
            }
            else {
                result = cast(TYPE) (logarithmic_zero_epsilon * ImPow(v_max_fudged / logarithmic_zero_epsilon, cast(FLOATTYPE) ((t_with_flip - zero_point_snap_R) / (1.0 - zero_point_snap_R))));
            }
        }
        else if ((v_min < 0.0) || (v_max < 0.0)) {// Entirely negative slider
            result = (TYPE)-(-v_max_fudged * ImPow(-v_min_fudged / -v_max_fudged, cast(FLOATTYPE) (1.0 - t_with_flip)));
        }
        else {
            result = (TYPE)(v_min_fudged * ImPow(v_max_fudged / v_min_fudged, cast(FLOATTYPE) t_with_flip));
        }
    }
    else
    {
        // Linear slider
        is_floating_point := (data_type == ImGuiDataType.Float) || (data_type == ImGuiDataType.Double);
        if (is_floating_point)
        {
            result = ImLerp(v_min, v_max, t);
        }
        else if (t < 1.0)
        {
            // - For integer values we want the clicking position to match the grab box so we round above
            //   This code is carefully tuned to work with large values (e.g. high ranges of U64) while preserving this property..
            // - Not doing a *1.0 multiply at the end of a range as it tends to be lossy. While absolute aiming at a large s64/u64
            //   range is going to be imprecise anyway, with this check we at least make the edge values matches expected limits.
            v_new_off_f := cast(SIGNEDTYPE)(v_max - v_min) * t;
            result = cast(TYPE)(cast(SIGNEDTYPE)v_min + cast(SIGNEDTYPE)(v_new_off_f + cast(FLOATTYPE)(v_min > v_max ? -0.5 : 0.5)));
        }
    }

    return result;
}

// FIXME: Try to move more of the code into shared SliderBehavior()
SliderBehaviorT :: proc($TYPE, $SIGNEDTYPE, $FLOATTYPE : typeid, bb : ^ImRect, id : ImGuiID, data_type : ImGuiDataType, v : ^TYPE, v_min, v_max : TYPE, format : ^u8, flags : ImGuiSliderFlags, out_grab_bb : ^ImRect) -> bool
{
    g := GImGui;
    style := &g.Style;

    axis := (.Vertical in flags) ? ImGuiAxis.Y : ImGuiAxis.X;
    is_logarithmic := (.Logarithmic in flags)
    is_floating_point := (data_type == ImGuiDataType.Float) || (data_type == ImGuiDataType.Double);
    v_range_f := (f32)(v_min < v_max ? v_max - v_min : v_min - v_max); // We don't need high precision for what we do with it.

    // Calculate bounds
    grab_padding := 2.0; // FIXME: Should be part of style.
    slider_sz := (bb.Max[axis] - bb.Min[axis]) - grab_padding * 2.0;
    grab_sz := style.GrabMinSize;
    if (!is_floating_point && v_range_f >= 0.0) {                        // v_range_f < 0 may happen on integer overflows
        grab_sz = ImMax(slider_sz / (v_range_f + 1), style.GrabMinSize); // For integer sliders: if possible have the grab size represent 1 unit
    }
    grab_sz = ImMin(grab_sz, slider_sz);
    slider_usable_sz := slider_sz - grab_sz;
    slider_usable_pos_min := bb.Min[axis] + grab_padding + grab_sz * 0.5;
    slider_usable_pos_max := bb.Max[axis] - grab_padding - grab_sz * 0.5;

    logarithmic_zero_epsilon := 0.0; // Only valid when is_logarithmic is true
    zero_deadzone_halfsize := 0.0; // Only valid when is_logarithmic is true
    if (is_logarithmic)
    {
        // When using logarithmic sliders, we need to clamp to avoid hitting zero, but our choice of clamp value greatly affects slider precision. We attempt to use the specified precision to estimate a good lower bound.
        decimal_precision := is_floating_point ? ImParseFormatPrecision(format, 3) : 1;
        logarithmic_zero_epsilon = ImPow(0.1, cast(f32) decimal_precision);
        zero_deadzone_halfsize = (style.LogSliderDeadzone * 0.5) / ImMax(slider_usable_sz, 1.0);
    }

    // Process interacting with the slider
    value_changed := false;
    if (g.ActiveId == id)
    {
        set_new_value := false;
        clicked_t := 0.0;
        if (g.ActiveIdSource == .Mouse)
        {
            if (!g.IO.MouseDown[0])
            {
                ClearActiveID();
            }
            else
            {
                mouse_abs_pos := g.IO.MousePos[axis];
                if (g.ActiveIdIsJustActivated)
                {
                    grab_t := ScaleRatioFromValueT(TYPE, SIGNEDTYPE, FLOATTYPE, data_type, v^, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);
                    if (axis == ImGuiAxis.Y)   do grab_t = 1.0 - grab_t
                    grab_pos := ImLerp(slider_usable_pos_min, slider_usable_pos_max, grab_t);
                    clicked_around_grab := (mouse_abs_pos >= grab_pos - grab_sz * 0.5 - 1.0) && (mouse_abs_pos <= grab_pos + grab_sz * 0.5 + 1.0); // No harm being extra generous here.
                    g.SliderGrabClickOffset = (clicked_around_grab && is_floating_point) ? mouse_abs_pos - grab_pos : 0.0;
                }
                if (slider_usable_sz > 0.0) {
                    clicked_t = ImSaturate((mouse_abs_pos - g.SliderGrabClickOffset - slider_usable_pos_min) / slider_usable_sz);
                }
                if (axis == ImGuiAxis.Y) {
                    clicked_t = 1.0 - clicked_t;
                }
                set_new_value = true;
            }
        }
        else if (g.ActiveIdSource == .Keyboard || g.ActiveIdSource == .Gamepad)
        {
            if (g.ActiveIdIsJustActivated)
            {
                g.SliderCurrentAccum = 0.0; // Reset any stored nav delta upon activation
                g.SliderCurrentAccumDirty = false;
            }

            input_delta := (axis == ImGuiAxis.X) ? GetNavTweakPressedAmount(axis) : -GetNavTweakPressedAmount(axis);
            if (input_delta != 0.0)
            {
                tweak_slow := IsKeyDown((g.NavInputSource == .Gamepad) ? ImGuiKey.NavGamepadTweakSlow : ImGuiKey.NavKeyboardTweakSlow);
                tweak_fast := IsKeyDown((g.NavInputSource == .Gamepad) ? ImGuiKey.NavGamepadTweakFast : ImGuiKey.NavKeyboardTweakFast);
                decimal_precision := is_floating_point ? ImParseFormatPrecision(format, 3) : 0;
                if (decimal_precision > 0)
                {
                    input_delta /= 100.0; // Keyboard/Gamepad tweak speeds in % of slider bounds
                    if (tweak_slow)   do input_delta /= 10.0
                }
                else
                {
                    if ((v_range_f >= -100.0 && v_range_f <= 100.0 && v_range_f != 0.0) || tweak_slow) {
                        input_delta = ((input_delta < 0.0) ? -1.0 : +1.0) / v_range_f; // Keyboard/Gamepad tweak speeds in integer steps
                    }
                    else {
                        input_delta /= 100.0;
                    }
                }
                if (tweak_fast)   do input_delta *= 10.0

                g.SliderCurrentAccum += input_delta;
                g.SliderCurrentAccumDirty = true;
            }

            delta := g.SliderCurrentAccum;
            if (g.NavActivatePressedId == id && !g.ActiveIdIsJustActivated)
            {
                ClearActiveID();
            }
            else if (g.SliderCurrentAccumDirty)
            {
                clicked_t = ScaleRatioFromValueT(TYPE, SIGNEDTYPE, FLOATTYPE, data_type, v^, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);

                if ((clicked_t >= 1.0 && delta > 0.0) || (clicked_t <= 0.0 && delta < 0.0)) // This is to avoid applying the saturation when already past the limits
                {
                    set_new_value = false;
                    g.SliderCurrentAccum = 0.0; // If pushing up against the limits, don't continue to accumulate
                }
                else
                {
                    set_new_value = true;
                    old_clicked_t := clicked_t;
                    clicked_t = ImSaturate(clicked_t + delta);

                    // Calculate what our "new" clicked_t will be, and thus how far we actually moved the slider, and subtract this from the accumulator
                    v_new := ScaleValueFromRatioT(TYPE, SIGNEDTYPE, FLOATTYPE, data_type, clicked_t, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);
                    if (is_floating_point && !(.NoRoundToFormat in flags)) {
                        v_new = RoundScalarWithFormatT(TYPE, format, data_type, v_new);
                    }
                    new_clicked_t := ScaleRatioFromValueT(TYPE, SIGNEDTYPE, FLOATTYPE, data_type, v_new, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);

                    if (delta > 0) {
                        g.SliderCurrentAccum -= ImMin(new_clicked_t - old_clicked_t, delta);
                    }
                    else {
                        g.SliderCurrentAccum -= ImMax(new_clicked_t - old_clicked_t, delta);
                    }
                }

                g.SliderCurrentAccumDirty = false;
            }
        }

        if (set_new_value) {
            if ((.ReadOnly in g.LastItemData.ItemFlags) || (.ReadOnly in flags))   do set_new_value = false
        }

        if (set_new_value)
        {
            v_new := ScaleValueFromRatioT(TYPE, SIGNEDTYPE, FLOATTYPE, data_type, clicked_t, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);

            // Round to user desired precision based on format string
            if (is_floating_point && !(.NoRoundToFormat in flags)) {
                v_new = RoundScalarWithFormatT(TYPE, format, data_type, v_new);
            }

            // Apply result
            if (v^ != v_new)
            {
                v^ = v_new;
                value_changed = true;
            }
        }
    }

    if (slider_sz < 1.0)
    {
        out_grab_bb^ = ImRect{ _v = {bb.Min, bb.Min}};
    }
    else
    {
        // Output grab position so it can be displayed by the caller
        grab_t := ScaleRatioFromValueT(TYPE, SIGNEDTYPE, FLOATTYPE, data_type, v^, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);
        if (axis == ImGuiAxis.Y)   do grab_t = 1.0 - grab_t
        grab_pos := ImLerp(slider_usable_pos_min, slider_usable_pos_max, grab_t);
        if (axis == ImGuiAxis.X) {
            out_grab_bb^ = ImRect{ _r = {grab_pos - grab_sz * 0.5, bb.Min.y + grab_padding, grab_pos + grab_sz * 0.5, bb.Max.y - grab_padding}};
        }
        else {
            out_grab_bb^ = ImRect{ _r = {bb.Min.x + grab_padding, grab_pos - grab_sz * 0.5, bb.Max.x - grab_padding, grab_pos + grab_sz * 0.5}};
        }
    }

    return value_changed;
}

// For 32-bit and larger types, slider bounds are limited to half the natural type range.
// So e.g. an integer Slider between INT_MAX-10 and INT_MAX will fail, but an integer Slider between INT_MAX/2-10 and INT_MAX/2 will be ok.
// It would be possible to lift that limitation with some work but it doesn't seem to be worth it for sliders.
SliderBehavior :: proc(bb : ^ImRect, id : ImGuiID, data_type : ImGuiDataType, p_v : rawptr, p_min : rawptr, p_max : rawptr, format : ^u8, flags : ImGuiSliderFlags, out_grab_bb : ^ImRect) -> bool
{
    // Read imgui.cpp "API BREAKING CHANGES" section for 1.78 if you hit this assert.
    assert((flags == 1 || (flags & ImGuiSliderFlags_InvalidMask_) == 0), "Invalid ImGuiSliderFlags flags! Has the legacy 'f32 power' argument been mistakenly cast to flags? Call function with ImGuiSliderFlags_Logarithmic flags instead.");
    assert((.WrapAround not_in flags)); // Not supported by SliderXXX(), only by DragXXX()

    switch (data_type)
    {
    case ImGuiDataType.S8:  { v32 := cast(i32) (cast(^i8)p_v)^;  r := SliderBehaviorT(i32, i32, f32, bb, id, ImGuiDataType.S32, &v32, (cast(^i8)p_min)^,  (cast(^i8)p_max)^,  format, flags, out_grab_bb); if (r) do (cast(^i8)p_v)^  = cast(i8) v32;  return r; }
    case ImGuiDataType.U8:  { v32 := cast(u32) (cast(^u8)p_v)^;  r := SliderBehaviorT(u32, i32, f32, bb, id, ImGuiDataType.U32, &v32, (cast(^u8)p_min)^,  (cast(^u8)p_max)^,  format, flags, out_grab_bb); if (r) do (cast(^u8)p_v)^  = cast(u8) v32;  return r; }
    case ImGuiDataType.S16: { v32 := cast(i32) (cast(^u16)p_v)^; r := SliderBehaviorT(i32, i32, f32, bb, id, ImGuiDataType.S32, &v32, (cast(^u16)p_min)^, (cast(^u16)p_max)^, format, flags, out_grab_bb); if (r) do (cast(^u16)p_v)^ = cast(u16) v32; return r; }
    case ImGuiDataType.U16: { v32 := cast(u32) (cast(^u16)p_v)^; r := SliderBehaviorT(u32, i32, f32, bb, id, ImGuiDataType.U32, &v32, (cast(^u16)p_min)^, (cast(^u16)p_max)^, format, flags, out_grab_bb); if (r) do (cast(^u16)p_v)^ = cast(u16) v32; return r; }
    case ImGuiDataType.S32:
        assert((cast(^i32)p_min)^ >= IM_S32_MIN / 2 && (cast(^i32)p_max)^ <= IM_S32_MAX / 2);
        return SliderBehaviorT(i32, i32, f32, bb, id, data_type, cast(^i32)p_v,  (cast(^i32)p_min)^,  (cast(^i32)p_max)^,  format, flags, out_grab_bb);
    case ImGuiDataType.U32:
        assert((cast(^u32)p_max)^ <= IM_U32_MAX / 2);
        return SliderBehaviorT(u32, i32, f32, bb, id, data_type, cast(^u32)p_v,  (cast(^u32)p_min)^,  (cast(^u32)p_max)^,  format, flags, out_grab_bb);
    case ImGuiDataType.S64:
        assert((cast(^i64)p_min)^ >= IM_S64_MIN / 2 && (cast(^i64)p_max)^ <= IM_S64_MAX / 2);
        return SliderBehaviorT(i64, i64, f64, bb, id, data_type, cast(^i64)p_v,  (cast(^i64)p_min)^,  (cast(^i64)p_max)^,  format, flags, out_grab_bb);
    case ImGuiDataType.U64:
        assert((cast(^u64)p_max)^ <= IM_U64_MAX / 2);
        return SliderBehaviorT(u64, i64, f64, bb, id, data_type, cast(^u64)p_v,  (cast(^u64)p_min)^,  (cast(^u64)p_max)^,  format, flags, out_grab_bb);
    case ImGuiDataType.Float:
        assert((cast(^f32)p_min)^ >= -math.F32_MAX / 2.0 && (cast(^f32)p_max)^ <= math.F32_MAX / 2.0);
        return SliderBehaviorT(f32, f32, f32, bb, id, data_type, cast(^f32)p_v,  (cast(^f32)p_min)^,  (cast(^f32)p_max)^,  format, flags, out_grab_bb);
    case ImGuiDataType.Double:
        assert((cast(^f64)p_min)^ >= -math.F64_MAX / 2.0 && (cast(^f64)p_max)^ <= math.F64_MAX / 2.0);
        return SliderBehaviorT(f64, f64, f64, bb, id, data_type, cast(^f64)p_v, (cast(^f64)p_min)^, (cast(^f64)p_max)^, format, flags, out_grab_bb);
    case ImGuiDataType.COUNT: break;
    }
    assert(false)
    return false;
}

// Note: p_data, p_min and p_max are _pointers_ to a memory address holding the data. For a slider, they are all required.
// Read code of e.g. SliderFloat(), SliderInt() etc. or examples in 'Demo.Widgets.Data Types' to understand how to use this function directly.
SliderScalar :: proc(label : string, data_type : ImGuiDataType, p_data : rawptr, p_min : rawptr, p_max : rawptr, format : ^u8, flags : ImGuiSliderFlags) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    style := &g.Style;
    id := GetID(window, label);
    w := CalcItemWidth();

    label_size := CalcTextSize(label, nil, true);
    frame_bb := ImRect(window.DC.CursorPos, window.DC.CursorPos + ImVec2{w, label_size.y + style.FramePadding.y * 2.0});
    total_bb := ImRect(frame_bb.Min, frame_bb.Max + ImVec2{label_size.x > 0.0 ? style.ItemInnerSpacing.x + label_size.x : 0.0, 0.0});

    temp_input_allowed := (.NoInput not_in flags);
    ItemSize(total_bb, style.FramePadding.y);
    if (!ItemAdd(total_bb, id, &frame_bb, temp_input_allowed ? ImGuiItemFlags_Inputable : 0))   do return false

    // Default format string when passing NULL
    if (format == nil) {
        format = DataTypeGetInfo(data_type)->PrintFmt;
    }

    hovered := ItemHoverable(frame_bb, id, g.LastItemData.ItemFlags);
    temp_input_is_active := temp_input_allowed && TempInputIsActive(id);
    if (!temp_input_is_active)
    {
        // Tabbing or CTRL-clicking on Slider turns it into an input box
        clicked := hovered && IsMouseClicked(0, ImGuiInputFlags_None, id);
        make_active := (clicked || g.NavActivateId == id);
        if (make_active && clicked) {
            SetKeyOwner(ImGuiKey.MouseLeft, id);
        }
        if (make_active && temp_input_allowed) {
            if ((clicked && g.IO.KeyCtrl) || (g.NavActivateId == id && (.PreferInput in g.NavActivateFlags))) {
                temp_input_is_active = true;
            }
        }

        // Store initial value (not used by main lib but available as a convenience but some mods e.g. to revert)
        if (make_active) {
            memcpy(&g.ActiveIdValueOnActivation, p_data, DataTypeGetInfo(data_type)->Size);
        }

        if (make_active && !temp_input_is_active)
        {
            SetActiveID(id, window);
            SetFocusID(id, window);
            FocusWindow(window);
            g.ActiveIdUsingNavDirMask |= (1 << .Left) | (1 << .Right);
        }
    }

    if (temp_input_is_active)
    {
        // Only clamp CTRL+Click input when ImGuiSliderFlags_ClampOnInput is set (generally via ImGuiSliderFlags_AlwaysClamp)
        clamp_enabled := (.ClampOnInput in flags)
        return TempInputScalar(frame_bb, id, label, data_type, p_data, format, clamp_enabled ? p_min : nil, clamp_enabled ? p_max : nil);
    }

    // Draw frame
    frame_col := GetColorU32(g.ActiveId == id ? ImGuiCol.FrameBgActive : hovered ? ImGuiCol.FrameBgHovered : ImGuiCol.FrameBg);
    RenderNavCursor(frame_bb, id);
    RenderFrame(frame_bb.Min, frame_bb.Max, frame_col, true, g.Style.FrameRounding);

    // Slider behavior
    grab_bb : ImRect
    value_changed := SliderBehavior(frame_bb, id, data_type, p_data, p_min, p_max, format, flags, &grab_bb);
    if (value_changed)   do MarkItemEdited(id)

    // Render grab
    if (grab_bb.Max.x > grab_bb.Min.x) {
        AddRectFilled(window.DrawList, grab_bb.Min, grab_bb.Max, GetColorU32(g.ActiveId == id ? ImGuiCol.SliderGrabActive : ImGuiCol.SliderGrab), style.GrabRounding);
    }

    // Display value using user-provided display format so user can add prefix/suffix/decorations to the value.
    value_buf : [64]u8
    value_buf_end := value_buf + DataTypeFormatString(value_buf, len(value_buf), data_type, p_data, format);
    if (g.LogEnabled) do LogSetNextTextDecoration("{", "}");
    RenderTextClipped(frame_bb.Min, frame_bb.Max, value_buf, value_buf_end, nil, ImVec2{0.5, 0.5});

    if (label_size.x > 0.0) {
        RenderText(ImVec2{frame_bb.Max.x + style.ItemInnerSpacing.x, frame_bb.Min.y + style.FramePadding.y}, label);
    }

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags | (temp_input_allowed ? ImGuiItemStatusFlags_Inputable : 0));
    return value_changed;
}

// Add multiple sliders on 1 line for compact edition of multiple components
SliderScalarN :: proc(label : string, data_type : ImGuiDataType, v : rawptr, components : i32, v_min : rawptr, v_max : rawptr, format : ^u8, flags : ImGuiSliderFlags) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    value_changed := false;
    BeginGroup();
    PushID(label);
    PushMultiItemsWidths(components, CalcItemWidth());
    type_size := GDataTypeInfo[data_type].Size;
    for i := 0; i < components; i += 1
    {
        PushID(i);
        if (i > 0) do SameLine(0, g.Style.ItemInnerSpacing.x);
        value_changed |= SliderScalar("", data_type, v, v_min, v_max, format, flags);
        PopID();
        PopItemWidth();
        v = v + type_size;
    }
    PopID();

    label_end := FindRenderedText(label);
    if (label != label_end)
    {
        SameLine(0, g.Style.ItemInnerSpacing.x);
        TextEx(label, label_end);
    }

    EndGroup();
    return value_changed;
}

// [forward declared comment]:
// adjust format to decorate the value with a prefix or a suffix for in-slider labels or unit display.
SliderFloat :: proc(label : string, v : ^f32, v_min : f32, v_max : f32, format : string = "%.3f", flags : ImGuiSliderFlags = {}) -> bool
{
    return SliderScalar(label, ImGuiDataType.Float, v, &v_min, &v_max, format, flags);
}

SliderFloat2 :: proc(label : string, v : [2]f32, v_min : f32, v_max : f32, format : string = "%.3f", flags : ImGuiSliderFlags = {}) -> bool
{
    return SliderScalarN(label, ImGuiDataType.Float, v, 2, &v_min, &v_max, format, flags);
}

SliderFloat3 :: proc(label : string, v : [3]f32, v_min : f32, v_max : f32, format : string = "%.3f", flags : ImGuiSliderFlags = {}) -> bool
{
    return SliderScalarN(label, ImGuiDataType.Float, v, 3, &v_min, &v_max, format, flags);
}

SliderFloat4 :: proc(label : string, v : [4]f32, v_min : f32, v_max : f32, format : string = "%.3f", flags : ImGuiSliderFlags = {}) -> bool
{
    return SliderScalarN(label, ImGuiDataType.Float, v, 4, &v_min, &v_max, format, flags);
}

SliderAngle :: proc(label : string, v_rad : ^f32, v_degrees_min : f32 = 360.0, v_degrees_max : f32, format : string = "%.0f deg", flags : ImGuiSliderFlags = {}) -> bool
{
    if (format == nil)   do format = "%.0 deg"
    v_deg := (v_rad^) * 360.0 / (2 * IM_PI);
    value_changed := SliderFloat(label, &v_deg, v_degrees_min, v_degrees_max, format, flags);
    if (value_changed) do v_rad^ = v_deg * (2 * IM_PI) / 360.0;
    return value_changed;
}

SliderInt :: proc(label : string, v : ^i32, v_min : i32, v_max : i32, format : string = "%d", flags : ImGuiSliderFlags = {}) -> bool
{
    return SliderScalar(label, ImGuiDataType.S32, v, &v_min, &v_max, format, flags);
}

SliderInt2 :: proc(label : string, v : [2]i32, v_min : i32, v_max : i32, format : string = "%d", flags : ImGuiSliderFlags = {}) -> bool
{
    return SliderScalarN(label, ImGuiDataType.S32, v, 2, &v_min, &v_max, format, flags);
}

SliderInt3 :: proc(label : string, v : [3]i32, v_min : i32, v_max : i32, format : string = "%d", flags : ImGuiSliderFlags = {}) -> bool
{
    return SliderScalarN(label, ImGuiDataType.S32, v, 3, &v_min, &v_max, format, flags);
}

SliderInt4 :: proc(label : string, v : [4]i32, v_min : i32, v_max : i32, format : string = "%d", flags : ImGuiSliderFlags = {}) -> bool
{
    return SliderScalarN(label, ImGuiDataType.S32, v, 4, &v_min, &v_max, format, flags);
}

VSliderScalar :: proc(label : string, size : ImVec2, data_type : ImGuiDataType, p_data : rawptr, p_min : rawptr, p_max : rawptr, format : string, flags : ImGuiSliderFlags) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    style := &g.Style;
    id := GetID(window, label);

    label_size := CalcTextSize(label, nil, true);
    frame_bb := ImRect{ _v = {window.DC.CursorPos, window.DC.CursorPos + size}};
    bb := ImRect(frame_bb.Min, frame_bb.Max + ImVec2{label_size.x > 0.0 ? style.ItemInnerSpacing.x + label_size.x : 0.0, 0.0});

    ItemSize(bb, style.FramePadding.y);
    if (!ItemAdd(frame_bb, id))   do return false

    // Default format string when passing NULL
    if (format == nil) do format = DataTypeGetInfo(data_type).PrintFmt;

    hovered := ItemHoverable(frame_bb, id, g.LastItemData.ItemFlags);
    clicked := hovered && IsMouseClicked(0, ImGuiInputFlags_None, id);
    if (clicked || g.NavActivateId == id)
    {
        if (clicked) do SetKeyOwner(ImGuiKey.MouseLeft, id);
        SetActiveID(id, window);
        SetFocusID(id, window);
        FocusWindow(window);
        g.ActiveIdUsingNavDirMask |= (1 << ImGuiDir.Up) | (1 << ImGuiDir.Down);
    }

    // Draw frame
    frame_col := GetColorU32(g.ActiveId == id ? ImGuiCol.FrameBgActive : hovered ? ImGuiCol.FrameBgHovered : ImGuiCol.FrameBg);
    RenderNavCursor(frame_bb, id);
    RenderFrame(frame_bb.Min, frame_bb.Max, frame_col, true, g.Style.FrameRounding);

    // Slider behavior
    grab_bb : ImRect
    value_changed := SliderBehavior(frame_bb, id, data_type, p_data, p_min, p_max, format, flags | ImGuiSliderFlags_Vertical, &grab_bb);
    if (value_changed)   do MarkItemEdited(id)

    // Render grab
    if (grab_bb.Max.y > grab_bb.Min.y) {
        AddRectFilled(window.DrawList, grab_bb.Min, grab_bb.Max, GetColorU32(g.ActiveId == id ? ImGuiCol.SliderGrabActive : ImGuiCol.SliderGrab), style.GrabRounding);
    }

    // Display value using user-provided display format so user can add prefix/suffix/decorations to the value.
    // For the vertical slider we allow centered text to overlap the frame padding
    value_buf : [64]u8
    value_buf_end := value_buf + DataTypeFormatString(value_buf, len(value_buf), data_type, p_data, format);
    RenderTextClipped(ImVec2{frame_bb.Min.x, frame_bb.Min.y + style.FramePadding.y}, frame_bb.Max, value_buf, value_buf_end, nil, ImVec2{0.5, 0.0});
    if (label_size.x > 0.0) {
        RenderText(ImVec2{frame_bb.Max.x + style.ItemInnerSpacing.x, frame_bb.Min.y + style.FramePadding.y}, label);
    }

    return value_changed;
}

VSliderFloat :: proc(label : string, size : ImVec2, v : ^f32, v_min : f32, v_max : f32, format : string = "%.3f", flags : ImGuiSliderFlags = {}) -> bool
{
    return VSliderScalar(label, size, ImGuiDataType.Float, v, &v_min, &v_max, format, flags);
}

VSliderInt :: proc(label : string, size : ImVec2, v : ^i32, v_min : i32, v_max : i32, format : string = "%d", flags : ImGuiSliderFlags = {}) -> bool
{
    return VSliderScalar(label, size, ImGuiDataType.S32, v, &v_min, &v_max, format, flags);
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: InputScalar, InputFloat, InputInt, etc.
//-------------------------------------------------------------------------
// - ImParseFormatFindStart() [Internal]
// - ImParseFormatFindEnd() [Internal]
// - ImParseFormatTrimDecorations() [Internal]
// - ImParseFormatSanitizeForPrinting() [Internal]
// - ImParseFormatSanitizeForScanning() [Internal]
// - ImParseFormatPrecision() [Internal]
// - TempInputTextScalar() [Internal]
// - InputScalar()
// - InputScalarN()
// - InputFloat()
// - InputFloat2()
// - InputFloat3()
// - InputFloat4()
// - InputInt()
// - InputInt2()
// - InputInt3()
// - InputInt4()
// - InputDouble()
//-------------------------------------------------------------------------

// We don't use strchr() because our strings are usually very short and often start with '%'
ImParseFormatFindStart :: proc(fmt : ^u8) -> ^u8
{
    fmt := fmt
    for c := fmt^; c != 0; fmt += 1
    {
        if (c == '%' && fmt[1] != '%')   do return fmt
        else if (c == '%')   do fmt += 1
    }
    return fmt;
}

ImParseFormatFindEnd :: proc(fmt : ^u8) -> ^u8
{
    // Printf/scanf types modifiers: I/L/h/j/l/t/w/z. Other uppercase letters qualify as types aka end of the format.
    if (fmt[0] != '%')   do return fmt
    ignored_uppercase_mask := (1 << ('I'-'A')) | (1 << ('L'-'A'));
    ignored_lowercase_mask := (1 << ('h'-'a')) | (1 << ('j'-'a')) | (1 << ('l'-'a')) | (1 << ('t'-'a')) | (1 << ('w'-'a')) | (1 << ('z'-'a'));
    for c : u8 = fmt^; c != 0; fmt += 1
    {
        if (c >= 'A' && c <= 'Z' && ((1 << (c - 'A')) & ignored_uppercase_mask) == 0)   do return fmt + 1
        if (c >= 'a' && c <= 'z' && ((1 << (c - 'a')) & ignored_lowercase_mask) == 0)   do return fmt + 1
        c = fmt^
    }
    return fmt;
}

// Extract the format out of a format string with leading or trailing decorations
//  fmt = "blah blah"  -> return ""
//  fmt = "%.3f"       -> return fmt
//  fmt = "hello %.3f" -> return fmt + 6
//  fmt = "%.3f hello" -> return buf written with "%.3f"
ImParseFormatTrimDecorations :: proc(fmt : ^u8, buf : ^u8, buf_size : int) -> ^u8
{
    fmt_start := ImParseFormatFindStart(fmt);
    if (fmt_start[0] != '%')   do return ""
    fmt_end := ImParseFormatFindEnd(fmt_start);
    if (fmt_end[0] == 0) {// If we only have leading decoration, we don't need to copy the data.
        return fmt_start;
    }
    ImStrncpy(buf, fmt_start, ImMin((int)(fmt_end - fmt_start) + 1, buf_size));
    return buf;
}

// Sanitize format
// - Zero terminate so extra characters after format (e.g. "%f123") don't confuse atof/atoi
// - stb_sprintf.h supports several new modifiers which format numbers in a way that also makes them incompatible atof/atoi.
ImParseFormatSanitizeForPrinting :: proc(fmt_in : ^u8, fmt_out : ^u8, fmt_out_size : int)
{
    fmt_end := ImParseFormatFindEnd(fmt_in);
    _ = fmt_out_size;
    assert((int)(fmt_end - fmt_in + 1) < fmt_out_size); // Format is too long, let us know if this happens to you!
    for (fmt_in < fmt_end)
    {
        fmt_in^ += 1
        c := fmt_in^
        if (c != '\'' && c != '$' && c != '_') {// Custom flags provided by stb_sprintf.h. POSIX 2008 also supports '.
            fmt_out^ = c;
            fmt_out += 1
        }
    }
    fmt_out^ = 0; // Zero-terminate
}

// - For scanning we need to remove all width and precision fields and flags "%+3.7f" -> "%f". BUT don't strip types like "%I64d" which includes digits. ! "%07I64d" -> "%I64d"
ImParseFormatSanitizeForScanning :: proc(fmt_in : ^u8, fmt_out : ^u8, fmt_out_size : int) -> ^u8
{
    fmt_end := ImParseFormatFindEnd(fmt_in);
    fmt_out_begin := fmt_out;
    _ = fmt_out_size;
    assert((int)(fmt_end - fmt_in + 1) < fmt_out_size); // Format is too long, let us know if this happens to you!
    has_type := false;
    for (fmt_in < fmt_end)
    {
        fmt_in^ += 1;
        c := fmt_in^
        if (!has_type && ((c >= '0' && c <= '9') || c == '.' || c == '+' || c == '#'))   do continue
        has_type |= ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')); // Stop skipping digits
        if (c != '\'' && c != '$' && c != '_') { // Custom flags provided by stb_sprintf.h. POSIX 2008 also supports '.
            fmt_out^ = c;
            fmt_out += 1
        }
    }
    fmt_out^ = 0; // Zero-terminate
    return fmt_out_begin;
}

ImAtoi :: proc(src : ^u8, output : ^$TYPE) -> ^u8
{
    negative := 0;
    if (src^ == '-') { negative = 1; src += 1; }
    if (src^ == '+') { src += 1; }
    v := 0;
    for (src^ >= '0' && src^ <= '9') {
        v = (v * 10) + (src^ - '0');
        src += 1
    }
    output^ = negative ? -v : v;
    return src;
}

// Parse display precision back from the display format string
// FIXME: This is still used by some navigation code path to infer a minimum tweak step, but we should aim to rework widgets so it isn't needed.
ImParseFormatPrecision :: proc(fmt : ^u8, default_precision : i32) -> i32
{
    fmt = ImParseFormatFindStart(fmt);
    if (fmt[0] != '%')   do return default_precision
    fmt += 1;
    for (fmt^ >= '0' && fmt^ <= '9') do fmt += 1;
    precision := INT_MAX;
    if (fmt^ == '.')
    {
        fmt = ImAtoi(fmt + 1, &precision);
        if (precision < 0 || precision > 99) {
            precision = default_precision;
        }
    }
    if (fmt^ == 'e' || fmt^ == 'E') {// Maximum precision with scientific notation
        precision = -1;
    }
    if ((fmt^ == 'g' || fmt^ == 'G') && precision == INT_MAX)   do precision = -1
    return (precision == INT_MAX) ? default_precision : precision;
}

// Create text input in place of another active widget (e.g. used when doing a CTRL+Click on drag/slider widgets)
// FIXME: Facilitate using this in variety of other situations.
// FIXME: Among other things, setting ImGuiItemFlags_AllowDuplicateId in LastItemData is currently correct but
// the expected relationship between TempInputXXX functions and LastItemData is a little fishy.
TempInputText :: proc(bb : ^ImRect, id : ImGuiID, label : string, buf : ^u8, buf_size : i32, flags : ImGuiInputTextFlags) -> bool
{
    // On the first frame, g.TempInputTextId == 0, then on subsequent frames it becomes == id.
    // We clear ActiveID on the first frame to allow the InputText() taking it back.
    g := GImGui;
    init := (g.TempInputId != id);
    if (init)   do ClearActiveID()

    g.CurrentWindow.DC.CursorPos = bb.Min;
    g.LastItemData.ItemFlags |= ImGuiItemFlags_AllowDuplicateId;
    value_changed := InputTextEx(label, nil, buf, buf_size, bb.GetSize(), flags | ImGuiInputTextFlags_MergedItem);
    if (init)
    {
        // First frame we started displaying the InputText widget, we expect it to take the active id.
        assert(g.ActiveId == id);
        g.TempInputId = g.ActiveId;
    }
    return value_changed;
}

// Note that Drag/Slider functions are only forwarding the min/max values clamping values if the ImGuiSliderFlags_AlwaysClamp flag is set!
// This is intended: this way we allow CTRL+Click manual input to set a value out of bounds, for maximum flexibility.
// However this may not be ideal for all uses, as some user code may break on out of bound values.
TempInputScalar :: proc(bb : ^ImRect, id : ImGuiID, label : string, data_type : ImGuiDataType, p_data : rawptr, format : ^u8, p_clamp_min : rawptr, p_clamp_max : rawptr) -> bool
{
    // FIXME: May need to clarify display behavior if format doesn't contain %.
    // "%d" -> "%d" / "There are %d items" -> "%d" / "items" -> "%d" (fallback). Also see #6405
    g := GImGui;
    type_info := DataTypeGetInfo(data_type);
    fmt_buf : [32]u8
    data_buf : [32]u8
    format = ImParseFormatTrimDecorations(format, fmt_buf, len(fmt_buf));
    if (format[0] == 0)  do format = type_info.PrintFmt;
    DataTypeFormatString(data_buf, len(data_buf), data_type, p_data, format);
    ImStrTrimBlanks(data_buf);

    flags := ImGuiInputTextFlags_AutoSelectAll | cast(ImGuiInputTextFlags)ImGuiInputTextFlags_LocalizeDecimalPoint;
    g.LastItemData.ItemFlags |= ImGuiItemFlags_NoMarkEdited; // Because TempInputText() uses ImGuiInputTextFlags_MergedItem it doesn't submit a new item, so we poke LastItemData.
    value_changed := false;
    if (TempInputText(bb, id, label, data_buf, len(data_buf), flags))
    {
        // Backup old value
        data_type_size := len(type_info);
        data_backup : ImGuiDataTypeStorage
        memcpy(&data_backup, p_data, data_type_size);

        // Apply new value (or operations) then clamp
        DataTypeApplyFromText(data_buf, data_type, p_data, format, nil);
        if (p_clamp_min || p_clamp_max)
        {
            if (p_clamp_min && p_clamp_max && DataTypeCompare(data_type, p_clamp_min, p_clamp_max) > 0) {
                ImSwap(p_clamp_min, p_clamp_max);
            }
            DataTypeClamp(data_type, p_data, p_clamp_min, p_clamp_max);
        }

        // Only mark as edited if new value is different
        g.LastItemData.ItemFlags &= ~ImGuiItemFlags_NoMarkEdited;
        value_changed = memcmp(&data_backup, p_data, data_type_size) != 0;
        if (value_changed)   do MarkItemEdited(id)
    }
    return value_changed;
}

SetNextItemRefVal :: proc(data_type : ImGuiDataType, p_data : rawptr)
{
    g := GImGui;
    g.NextItemData.HasFlags |= ImGuiNextItemDataFlags_HasRefVal;
    memcpy(&g.NextItemData.RefVal, p_data, DataTypeGetInfo(data_type)->Size);
}

// Note: p_data, p_step, p_step_fast are _pointers_ to a memory address holding the data. For an Input widget, p_step and p_step_fast are optional.
// Read code of e.g. InputFloat(), InputInt() etc. or examples in 'Demo.Widgets.Data Types' to understand how to use this function directly.
InputScalar :: proc(label : string, data_type : ImGuiDataType, p_data : rawptr, p_step : rawptr, p_step_fast : rawptr, format : ^u8, flags : ImGuiInputTextFlags) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    style := &g.Style;
    assert((.EnterReturnsTrue not_in flags)); // Not supported by InputScalar(). Please open an issue if you this would be useful to you. Otherwise use IsItemDeactivatedAfterEdit()!

    if (format == nil) {
        format = DataTypeGetInfo(data_type)->PrintFmt;
    }

    p_data_default := (.HasRefVal in g.NextItemData.HasFlags) ? &g.NextItemData.RefVal : &g.DataTypeZeroValue;

    buf : [64]u8
    if ((.DisplayEmptyRefVal in flags) && DataTypeCompare(data_type, p_data, p_data_default) == 0)   do buf[0] = 0
    else  do DataTypeFormatString(buf, len(buf), data_type, p_data, format);

    // Disable the MarkItemEdited() call in InputText but keep ImGuiItemStatusFlags_Edited.
    // We call MarkItemEdited() ourselves by comparing the actual data rather than the string.
    g.NextItemData.ItemFlags |= ImGuiItemFlags_NoMarkEdited;
    flags |= ImGuiInputTextFlags_AutoSelectAll | ImGuiInputTextFlags_LocalizeDecimalPoint;

    value_changed := false;
    if (p_step == nil)
    {
        if (InputText(label, buf, len(buf), flags)) {
            value_changed = DataTypeApplyFromText(buf, data_type, p_data, format, (.ParseEmptyRefVal in flags) ? p_data_default : nil);
        }
    }
    else
    {
        button_size := GetFrameHeight();

        BeginGroup(); // The only purpose of the group here is to allow the caller to query item data e.g. IsItemActive()
        PushID(label);
        SetNextItemWidth(ImMax(1.0, CalcItemWidth() - (button_size + style.ItemInnerSpacing.x) * 2));
        if (InputText("", buf, len(buf), flags)) {// PushId(label) + "" gives us the expected ID from outside point of view
            value_changed = DataTypeApplyFromText(buf, data_type, p_data, format, (.ParseEmptyRefVal in flags) ? p_data_default : nil);
        }
        IMGUI_TEST_ENGINE_ITEM_INFO(g.LastItemData.ID, label, g.LastItemData.StatusFlags | ImGuiItemStatusFlags_Inputable);

        // Step buttons
        backup_frame_padding := style.FramePadding;
        style.FramePadding.x = style.FramePadding.y;
        if (.ReadOnly in flags)   do BeginDisabled()
        PushItemFlag(ImGuiItemFlags_ButtonRepeat, true);
        SameLine(0, style.ItemInnerSpacing.x);
        if (ButtonEx("-", ImVec2{button_size, button_size}))
        {
            DataTypeApplyOp(data_type, '-', p_data, p_data, g.IO.KeyCtrl && p_step_fast ? p_step_fast : p_step);
            value_changed = true;
        }
        SameLine(0, style.ItemInnerSpacing.x);
        if (ButtonEx("+", ImVec2{button_size, button_size}))
        {
            DataTypeApplyOp(data_type, '+', p_data, p_data, g.IO.KeyCtrl && p_step_fast ? p_step_fast : p_step);
            value_changed = true;
        }
        PopItemFlag();
        if (.ReadOnly in flags)   do EndDisabled()

        label_end := FindRenderedText(label);
        if (label != label_end)
        {
            SameLine(0, style.ItemInnerSpacing.x);
            TextEx(label, label_end);
        }
        style.FramePadding = backup_frame_padding;

        PopID();
        EndGroup();
    }

    g.LastItemData.ItemFlags &= ~ImGuiItemFlags_NoMarkEdited;
    if (value_changed) do MarkItemEdited(g.LastItemData.ID);

    return value_changed;
}

InputScalarN :: proc(label : string, data_type : ImGuiDataType, p_data : rawptr, components : i32, p_step : rawptr, p_step_fast : rawptr, format : ^u8, flags : ImGuiInputTextFlags) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    value_changed := false;
    BeginGroup();
    PushID(label);
    PushMultiItemsWidths(components, CalcItemWidth());
    type_size := GDataTypeInfo[data_type].Size;
    for i := 0; i < components; i += 1
    {
        PushID(i);
        if (i > 0) do SameLine(0, g.Style.ItemInnerSpacing.x);
        value_changed |= InputScalar("", data_type, p_data, p_step, p_step_fast, format, flags);
        PopID();
        PopItemWidth();
        p_data = p_data + type_size;
    }
    PopID();

    label_end := FindRenderedText(label);
    if (label != label_end)
    {
        SameLine(0.0, g.Style.ItemInnerSpacing.x);
        TextEx(label, label_end);
    }

    EndGroup();
    return value_changed;
}

InputFloat :: proc(label : string, v : ^f32, step : f32 = 0, step_fast : f32 = 0, format : string = "%.3f", flags : ImGuiInputTextFlags = nil) -> bool // TODO default args
{
    return InputScalar(label, ImGuiDataType.Float, cast(rawptr) v, cast(rawptr) (step > 0.0 ? &step : nil), cast(rawptr) (step_fast > 0.0 ? &step_fast : nil), format, flags);
}

InputFloat2 :: proc(label : string, v : [2]f32, format : string = "%.3f", flags : ImGuiInputTextFlags = {}) -> bool
{
    return InputScalarN(label, ImGuiDataType.Float, v, 2, nil, nil, format, flags);
}

InputFloat3 :: proc(label : string, v : [3]f32, format : string = "%.3f", flags : ImGuiInputTextFlags = {}) -> bool
{
    return InputScalarN(label, ImGuiDataType.Float, v, 3, nil, nil, format, flags);
}

InputFloat4 :: proc(label : string, v : [4]f32, format : string = "%.3f", flags : ImGuiInputTextFlags = {}) -> bool
{
    return InputScalarN(label, ImGuiDataType.Float, v, 4, nil, nil, format, flags);
}

InputInt :: proc(label : string, v : ^i32, step : i32 = 1, step_fast : i32 = 100, flags : ImGuiInputTextFlags = {}) -> bool
{
    // Hexadecimal input provided as a convenience but the flag name is awkward. Typically you'd use InputText() to parse your own data, if you want to handle prefixes.
    format := (.CharsHexadecimal in flags) ? "%08X" : "%d";
    return InputScalar(label, ImGuiDataType.S32, cast(rawptr) v, cast(rawptr) (step > 0 ? &step : nil), cast(rawptr) (step_fast > 0 ? &step_fast : nil), format, flags);
}

InputInt2 :: proc(label : string, v : [2]i32, flags : ImGuiInputTextFlags = {}) -> bool
{
    return InputScalarN(label, ImGuiDataType.S32, v, 2, nil, nil, "%d", flags);
}

InputInt3 :: proc(label : string, v : [3]i32, flags : ImGuiInputTextFlags = {}) -> bool
{
    return InputScalarN(label, ImGuiDataType.S32, v, 3, nil, nil, "%d", flags);
}

InputInt4 :: proc(label : string, v : [4]i32, flags : ImGuiInputTextFlags = {}) -> bool
{
    return InputScalarN(label, ImGuiDataType.S32, v, 4, nil, nil, "%d", flags);
}

InputDouble :: proc(label : string, v : ^f64, step : f64 = 0.0, step_fast : f64 = 0.0, format : string = "%.6f", flags : ImGuiInputTextFlags = {}) -> bool
{
    return InputScalar(label, ImGuiDataType.Double, cast(rawptr) v, cast(rawptr) (step > 0.0 ? &step : nil), cast(rawptr) (step_fast > 0.0 ? &step_fast : nil), format, flags);
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: InputText, InputTextMultiline, InputTextWithHint
//-------------------------------------------------------------------------
// - imstb_textedit.h include
// - InputText()
// - InputTextWithHint()
// - InputTextMultiline()
// - InputTextGetCharInfo() [Internal]
// - InputTextReindexLines() [Internal]
// - InputTextReindexLinesRange() [Internal]
// - InputTextEx() [Internal]
// - DebugNodeInputTextState() [Internal]
//-------------------------------------------------------------------------


InputText :: proc(label : string, buf : []u8, flags : ImGuiInputTextFlags = {}, callback : ImGuiInputTextCallback = nil, user_data : rawptr = nil) -> bool
{
    assert(!(flags & transmute(ImGuiInputTextFlags) ImGuiInputTextFlagsPrivate.Multiline != nil), "call InputTextMultiline()");
    return InputTextEx(label, nil, buf, ImVec2{0, 0}, flags, callback, user_data);
}

InputTextMultiline :: proc(label : string, buf : []u8, size : ImVec2 = {}, flags : ImGuiInputTextFlags = {}, callback : ImGuiInputTextCallback = nil, user_data : rawptr = nil) -> bool
{
    return InputTextEx(label, nil, buf, cast(i32) buf_size, size, flags | ImGuiInputTextFlags_Multiline, callback, user_data);
}

InputTextWithHint :: proc(label : string, hint : [^]u8, buf : []u8, flags : ImGuiInputTextFlags = {}, callback : ImGuiInputTextCallback = nil, user_data : rawptr = nil) -> bool
{
    assert(!(flags & transmute(ImGuiInputTextFlags) ImGuiInputTextFlagsPrivate.Multiline != nil), "call InputTextMultiline() or  InputTextEx() manually if you need multi-line + hint.");
    return InputTextEx(label, hint, buf, ImVec2{0, 0}, flags, callback, user_data);
}

// This is only used in the path where the multiline widget is inactivate.
InputTextCalcTextLenAndLineCount :: proc(text_begin : [^]u8, out_text_end : ^^u8) -> i32
{
    line_count : i32 = 0;
    s := text_begin;
    for (true)
    {
        s_eol := memchr(s, '\n');
        line_count += 1;
        if (s_eol == nil)
        {
            s = s[strlen(s):];
            break;
        }
        s = s_eol + 1;
    }
    out_text_end^ = s;
    return line_count;
}

// FIXME: Ideally we'd share code with ImFont::CalcTextSizeA()
InputTextCalcTextSize :: proc(ctx : ^ImGuiContext, text_begin : ^u8, text_end : ^u8, remaining : ^^u8 = nil, out_offset : ^ImVec2 = nil, stop_on_new_line : bool = false) -> ImVec2
{
    g := ctx;
    font := g.Font;
    line_height := g.FontSize;
    scale := line_height / font.FontSize;

    text_size := ImVec2{0, 0};
    line_width := 0.0;

    s := text_begin;
    for (s < text_end)
    {
        c := (u32)*s;
        if (c < 0x80)   do s += 1
        else do s += ImTextCharFromUtf8(&c, s, text_end);

        if (c == '\n')
        {
            text_size.x = ImMax(text_size.x, line_width);
            text_size.y += line_height;
            line_width = 0.0;
            if (stop_on_new_line)   do break
            continue;
        }
        if (c == '\r')   do continue

        char_width := (cast(i32) c < len(font.IndexAdvanceX) ? font.IndexAdvanceX.Data[c] : font.FallbackAdvanceX) * scale;
        line_width += char_width;
    }

    if (text_size.x < line_width)   do text_size.x = line_width

    if (out_offset) {
        out_offset^ = ImVec2{line_width, text_size.y + line_height};  // offset allow for the possibility of sitting after a trailing \n
    }

    if (line_width > 0 || text_size.y == 0.0) {                       // whereas size.y will ignore the trailing \n
        text_size.y += line_height;
    }

    if (remaining)   do remaining^ = s

    return text_size;
}

// Wrapper for stb_textedit.h to edit text (our wrapper is for: statically sized buffer, single-line, wchar characters. InputText converts between UTF-8 and wchar)
// With our UTF-8 use of stb_textedit:
// - STB_TEXTEDIT_GETCHAR is nothing more than a a "GETBYTE". It's only used to compare to ascii or to copy blocks of text so we are fine.
// - One exception is the STB_TEXTEDIT_IS_SPACE feature which would expect a full char in order to handle full-width space such as 0x3000 (see ImCharIsBlankW).
// - ...but we don't use that feature.
STB_TEXTEDIT_STRINGLEN :: proc(obj : ^ImGuiInputTextState)  -> i32 { return obj.TextLen; }
STB_TEXTEDIT_GETCHAR :: proc(obj : ^ImGuiInputTextState, idx : i32)  -> u8 { assert(idx <= obj.TextLen); return obj.TextSrc[idx]; }
STB_TEXTEDIT_GETWIDTH :: proc(obj : ^ImGuiInputTextState, line_start_idx, char_idx : i32)  -> f32 { c : u32; ImTextCharFromUtf8(&c, obj.TextSrc + line_start_idx + char_idx, obj.TextSrc + obj.TextLen); if (cast(ImWchar)c == '\n') do return IMSTB_TEXTEDIT_GETWIDTH_NEWLINE; g := &obj.Ctx; return g.Font.GetCharAdvance(cast(ImWchar)c) * g.FontScale; }
STB_TEXTEDIT_NEWLINE :: '\n';
STB_TEXTEDIT_LAYOUTROW :: proc(r : ^StbTexteditRow, obj : ^ImGuiInputTextState, line_start_idx : i32)
{
    text := obj.TextSrc;
    text_remaining : ^u8;
    size := InputTextCalcTextSize(obj.Ctx, text + line_start_idx, text + obj.TextLen, &text_remaining, nil, true);
    r.x0 = 0.0;
    r.x1 = size.x;
    r.baseline_y_delta = size.y;
    r.ymin = 0.0;
    r.ymax = size.y;
    r.num_chars = (i32)(text_remaining - (text + line_start_idx));
}

IMSTB_TEXTEDIT_GETNEXTCHARINDEX :: IMSTB_TEXTEDIT_GETNEXTCHARINDEX_IMPL
IMSTB_TEXTEDIT_GETPREVCHARINDEX :: IMSTB_TEXTEDIT_GETPREVCHARINDEX_IMPL

IMSTB_TEXTEDIT_GETNEXTCHARINDEX_IMPL :: proc(obj : ^ImGuiInputTextState, idx : i32) -> i32
{
    if (idx >= obj.TextLen)   do return obj.TextLen + 1
    c : u32
    return idx + ImTextCharFromUtf8(&c, obj.TextSrc + idx, obj.TextSrc + obj.TextLen);
}

IMSTB_TEXTEDIT_GETPREVCHARINDEX_IMPL :: proc(obj : ^ImGuiInputTextState, idx : i32) -> i32
{
    if (idx <= 0)   do return -1
    p := ImTextFindPreviousUtf8Codepoint(obj.TextSrc, obj.TextSrc + idx);
    return (i32)(p - obj.TextSrc);
}

ImCharIsSeparatorW :: proc(c : u32) -> bool
{
    separator_list : = [?]u32 {
        ',', 0x3001, '.', 0x3002, ';', 0xFF1B, '(', 0xFF08, ')', 0xFF09, '{', 0xFF5B, '}', 0xFF5D,
        '[', 0x300C, ']', 0x300D, '|', 0xFF5C, '!', 0xFF01, '\\', 0xFFE5, '/', 0x30FB, 0xFF0F,
        '\n', '\r',
    }
    for separator in separator_list {
        if (c == separator)   do return true
    }
    return false;
}

is_word_boundary_from_right :: proc(obj : ^ImGuiInputTextState, idx : i32) -> i32
{
    // When ImGuiInputTextFlags_Password is set, we don't want actions such as CTRL+Arrow to leak the fact that underlying data are blanks or separators.
    if ((.Password in obj.Flags) || idx <= 0)   do return 0

    curr_p := obj.TextSrc + idx;
    prev_p := ImTextFindPreviousUtf8Codepoint(obj.TextSrc, curr_p);
    curr_c : u32
    prev_c : u32

    prev_white := ImCharIsBlankW(prev_c);
    prev_separ := ImCharIsSeparatorW(prev_c);
    curr_white := ImCharIsBlankW(curr_c);
    curr_separ := ImCharIsSeparatorW(curr_c);
    return ((prev_white || prev_separ) && !(curr_separ || curr_white)) || (curr_separ && !prev_separ);
}
is_word_boundary_from_left :: proc(obj : ^ImGuiInputTextState, idx : i32) -> i32
{
    if ((.Password in obj.Flags) || idx <= 0)   do return 0

    curr_p := obj.TextSrc + idx;
    prev_p := ImTextFindPreviousUtf8Codepoint(obj.TextSrc, curr_p);
    prev_c : u32
    curr_c : u32

    prev_white := ImCharIsBlankW(prev_c);
    prev_separ := ImCharIsSeparatorW(prev_c);
    curr_white := ImCharIsBlankW(curr_c);
    curr_separ := ImCharIsSeparatorW(curr_c);
    return ((prev_white) && !(curr_separ || curr_white)) || (curr_separ && !prev_separ);
}
STB_TEXTEDIT_MOVEWORDLEFT_IMPL :: proc(obj : ^ImGuiInputTextState, idx : i32) -> i32
{
    idx = IMSTB_TEXTEDIT_GETPREVCHARINDEX(obj, idx);
    for (idx >= 0 && !is_word_boundary_from_right(obj, idx)) {
        idx = IMSTB_TEXTEDIT_GETPREVCHARINDEX(obj, idx);
    }
    return idx < 0 ? 0 : idx;
}
STB_TEXTEDIT_MOVEWORDRIGHT_MAC :: proc(obj : ^ImGuiInputTextState, idx : i32) -> i32
{
    len := obj.TextLen;
    idx = IMSTB_TEXTEDIT_GETNEXTCHARINDEX(obj, idx);
    for (idx < len && !is_word_boundary_from_left(obj, idx)) {
        idx = IMSTB_TEXTEDIT_GETNEXTCHARINDEX(obj, idx);
    }
    return idx > len ? len : idx;
}
STB_TEXTEDIT_MOVEWORDRIGHT_WIN :: proc(obj : ^ImGuiInputTextState, idx : i32) -> i32
{
    idx = IMSTB_TEXTEDIT_GETNEXTCHARINDEX(obj, idx);
    len := obj.TextLen;
    for (idx < len && !is_word_boundary_from_right(obj, idx)) {
        idx = IMSTB_TEXTEDIT_GETNEXTCHARINDEX(obj, idx);
    }
    return idx > len ? len : idx;
}
STB_TEXTEDIT_MOVEWORDRIGHT_IMPL :: proc(obj : ^ImGuiInputTextState, idx : i32) -> i32  { g := obj.Ctx; if (g.IO.ConfigMacOSXBehaviors) do return STB_TEXTEDIT_MOVEWORDRIGHT_MAC(obj, idx); else do return STB_TEXTEDIT_MOVEWORDRIGHT_WIN(obj, idx); }
STB_TEXTEDIT_MOVEWORDLEFT :: STB_TEXTEDIT_MOVEWORDLEFT_IMPL  // They need to be #define for stb_textedit.h
STB_TEXTEDIT_MOVEWORDRIGHT :: STB_TEXTEDIT_MOVEWORDRIGHT_IMPL

STB_TEXTEDIT_DELETECHARS :: proc(obj : ^ImGuiInputTextState, pos : i32, n : i32)
{
    // Offset remaining text (+ copy zero terminator)
    assert(obj.TextSrc == raw_data(obj.TextA));
    dst := obj.TextA.Data + pos;
    src := obj.TextA.Data + pos + n;
    memmove(dst, src, obj.TextLen - n - pos + 1);
    obj.Edited = true;
    obj.TextLen -= n;
}

STB_TEXTEDIT_INSERTCHARS :: proc(obj : ^ImGuiInputTextState, pos : i32, new_text : ^u8, new_text_len : i32) -> bool
{
    is_resizable := (.CallbackResize in obj.Flags) != 0;
    text_len := obj.TextLen;
    assert(pos <= text_len);

    if (!is_resizable && (new_text_len + obj.TextLen + 1 > obj.BufCapacity))   do return false

    // Grow internal buffer if needed
    assert(obj.TextSrc == obj.TextA.Data);
    if (new_text_len + text_len + 1 > obj.TextA.Size)
    {
        if (!is_resizable)   do return false
        obj.TextA.resize(text_len + ImClamp(new_text_len, 32, ImMax(256, new_text_len)) + 1);
        obj.TextSrc = obj.TextA.Data;
    }

    text := obj.TextA.Data;
    if (pos != text_len) do memmove(text + pos + new_text_len, text + pos, (int)(text_len - pos));
    memcpy(text + pos, new_text, cast(int) new_text_len);

    obj.Edited = true;
    obj.TextLen += new_text_len;
    obj.TextA[obj.TextLen] = nil;

    return true;
}

// We don't use an enum so we can build even with conflicting symbols (if another user of stb_textedit.h leak their STB_TEXTEDIT_K_* symbols)
STB_TEXTEDIT_K_LEFT :: 0x200000 // keyboard input to move cursor left
STB_TEXTEDIT_K_RIGHT :: 0x200001 // keyboard input to move cursor right
STB_TEXTEDIT_K_UP :: 0x200002 // keyboard input to move cursor up
STB_TEXTEDIT_K_DOWN :: 0x200003 // keyboard input to move cursor down
STB_TEXTEDIT_K_LINESTART :: 0x200004 // keyboard input to move cursor to start of line
STB_TEXTEDIT_K_LINEEND :: 0x200005 // keyboard input to move cursor to end of line
STB_TEXTEDIT_K_TEXTSTART :: 0x200006 // keyboard input to move cursor to start of text
STB_TEXTEDIT_K_TEXTEND :: 0x200007 // keyboard input to move cursor to end of text
STB_TEXTEDIT_K_DELETE :: 0x200008 // keyboard input to delete selection or character under cursor
STB_TEXTEDIT_K_BACKSPACE :: 0x200009 // keyboard input to delete selection or character left of cursor
STB_TEXTEDIT_K_UNDO :: 0x20000A // keyboard input to perform undo
STB_TEXTEDIT_K_REDO :: 0x20000B // keyboard input to perform redo
STB_TEXTEDIT_K_WORDLEFT :: 0x20000C // keyboard input to move cursor left one word
STB_TEXTEDIT_K_WORDRIGHT :: 0x20000D // keyboard input to move cursor right one word
STB_TEXTEDIT_K_PGUP :: 0x20000E // keyboard input to move cursor up a page
STB_TEXTEDIT_K_PGDOWN :: 0x20000F // keyboard input to move cursor down a page
STB_TEXTEDIT_K_SHIFT :: 0x400000

// stb_textedit internally allows for a single undo record to do addition and deletion, but somehow, calling
// the stb_textedit_paste() function creates two separate records, so we perform it manually. (FIXME: Report to nothings/stb?)
stb_textedit_replace :: proc(str : ^ImGuiInputTextState, state : ^STB_TexteditState, text : ^IMSTB_TEXTEDIT_CHARTYPE, text_len : i32)
{
    stb_text_makeundo_replace(str, state, 0, str.TextLen, text_len);
    STB_TEXTEDIT_DELETECHARS(str, 0, str.TextLen);
    state.cursor = 0
    state.select_start = 0
    state.select_end = 0;
    if (text_len <= 0)   do return
    if STB_TEXTEDIT_INSERTCHARS(str, 0, text, text_len)
    {
        state.cursor = text_len
        state.select_start = text_len
        state.select_end = text_len;
        state.has_preferred_x = 0;
        return;
    }
    assert(false) // Failed to insert character, normally shouldn't happen because of how we currently use stb_textedit_replace()
}

// We added an extra indirection where 'Stb' is heap-allocated, in order facilitate the work of bindings generators.
init_ImGuiInputTextState :: proc(this : ^ImGuiInputTextState)
{
    this^ = {};
    this.Stb = IM_NEW(ImStbTexteditState);
    memset(this.Stb, 0, size_of(this.Stb^));
}

deinit_ImGuiInputTextState :: proc(this : ^ImGuiInputTextState)
{
    IM_DELETE(this.Stb);
}

// [forward declared comment]:
// Cannot be inline because we call in code in stb_textedit.h implementation
OnKeyPressed :: proc(this : ^ImGuiInputTextState, key : i32)
{
    stb_textedit_key(this, Stb, key);
    CursorFollow = true;
    CursorAnimReset();
}

OnCharPressed :: proc(this : ^ImGuiInputTextState, c : u32)
{
    // Convert the key to a UTF8 byte sequence.
    // The changes we had to make to stb_textedit_key made it very much UTF-8 specific which is not too great.
    utf8 : [5]u8
    ImTextCharToUtf8(utf8, c);
    stb_textedit_text(this, Stb, utf8, cast(i32) strlen(utf8));
    CursorFollow = true;
    CursorAnimReset();
}

// Those functions are not inlined in imgui_internal.h, allowing us to hide ImStbTexteditState from that header.
CursorAnimReset               :: proc(this : ^ImGuiInputTextState) { this.CursorAnim = -0.30; } // After a user-input the cursor stays on for a while without blinking
CursorClamp                   :: proc(this : ^ImGuiInputTextState) { this.Stb.cursor = ImMin(this.Stb.cursor, this.TextLen); this.Stb.select_start = ImMin(this.Stb.select_start, this.TextLen); this.Stb.select_end = ImMin(this.Stb.select_end, this.TextLen); }
HasSelection_state            :: proc(this : ^ImGuiInputTextState) -> bool { return this.Stb.select_start != this.Stb.select_end; }
HasSelection :: proc { HasSelection_state, HasSelection_callback }
ClearSelection_state          :: proc(this : ^ImGuiInputTextState) { this.Stb.select_start = this.Stb.cursor; this.Stb.select_end = this.Stb.cursor; }
ClearSelection :: proc { ClearSelection_state, ClearSelection_callback }
GetCursorPos                  :: proc(this : ^ImGuiInputTextState) -> i32 { return this.Stb.cursor; }
GetSelectionStart             :: proc(this : ^ImGuiInputTextState) -> i32 { return this.Stb.select_start; }
GetSelectionEnd               :: proc(this : ^ImGuiInputTextState) -> i32 { return this.Stb.select_end; }
SelectAll_state               :: proc(this : ^ImGuiInputTextState) { this.Stb.select_start = 0; this.Stb.cursor = this.TextLen; this.Stb.select_end = this.TextLen; this.Stb.has_preferred_x = 0; }
SelectAll :: proc { SelectAll_state, SelectAll_callback }
ReloadUserBufAndSelectAll     :: proc(this : ^ImGuiInputTextState) { this.WantReloadUserBuf = true; this.ReloadSelectionStart = 0; this.ReloadSelectionEnd = INT_MAX; }
ReloadUserBufAndKeepSelection :: proc(this : ^ImGuiInputTextState) { this.WantReloadUserBuf = true; this.ReloadSelectionStart = this.Stb.select_start; this.ReloadSelectionEnd = this.Stb.select_end; }
ReloadUserBufAndMoveToEnd     :: proc(this : ^ImGuiInputTextState) { this.WantReloadUserBuf = true; this.ReloadSelectionStart = INT_MAX; this.ReloadSelectionEnd = INT_MAX; }

init_ImGuiInputTextCallbackData :: proc(this : ^ImGuiInputTextCallbackData)
{
    this^ = {};
}

// Public API to manipulate UTF-8 text from within a callback.
// FIXME: The existence of this rarely exercised code path is a bit of a nuisance.
// Historically they existed because STB_TEXTEDIT_INSERTCHARS() etc. worked on our ImWchar
// buffer, but nowadays they both work on UTF-8 data. Should aim to merge both.
DeleteChars :: proc(this : ^ImGuiInputTextCallbackData, pos : i32, bytes_count : i32)
{
    assert(pos + bytes_count <= BufTextLen);
    dst := Buf + pos;
    src := Buf + pos + bytes_count;
    memmove(dst, src, BufTextLen - bytes_count - pos + 1);

    if (CursorPos >= pos + bytes_count)   do CursorPos -= bytes_count
    else if (CursorPos >= pos)   do CursorPos = pos
    SelectionEnd = CursorPos
    SelectionStart = CursorPos;
    BufDirty = true;
    BufTextLen -= bytes_count;
}

InsertChars :: proc(this : ^ImGuiInputTextCallbackData, pos : i32, new_text : ^u8, new_text_end : ^u8 = nil)
{
    // Accept null ranges
    if (new_text == new_text_end)   do return

    // Grow internal buffer if needed
    is_resizable := (.CallbackResize in flags)
    new_text_len := new_text_end ? (i32)(new_text_end - new_text) : cast(i32) strlen(new_text);
    if (new_text_len + this.BufTextLen >= this.BufSize)
    {
        if (!is_resizable)   do return

        g := Ctx;
        edit_state := &g.InputTextState;
        assert(edit_state.ID != 0 && g.ActiveId == edit_state.ID);
        assert(Buf == edit_state.TextA.Data);
        new_buf_size := this.BufTextLen + ImClamp(new_text_len * 4, 32, ImMax(256, new_text_len)) + 1;
        edit_state.TextA.resize(new_buf_size + 1);
        edit_state.TextSrc = edit_state.TextA.Data;
        this.Buf = edit_state.TextA.Data;
        edit_state.BufCapacity = new_buf_size;
        this.BufSize = new_buf_size;
    }

    if (this.BufTextLen != pos) {
        memmove(this.Buf + pos + new_text_len, this.Buf + pos, (int)(this.BufTextLen - pos));
    }
    memcpy(this.Buf + pos, new_text, cast(int) new_text_len * size_of(u8));
    this.Buf[this.BufTextLen + new_text_len] = nil;

    if (this.CursorPos >= pos)   do this.CursorPos += new_text_len
    this.SelectionEnd = this.CursorPos;
    this.SelectionStart = this.CursorPos;
    this.BufDirty = true;
    this.BufTextLen += new_text_len;
}

// Return false to discard a character.
InputTextFilterCharacter :: proc(ctx : ^ImGuiContext, p_char : ^u32, flags : ImGuiInputTextFlags, callback : ImGuiInputTextCallback, user_data : rawptr, input_source_is_clipboard : bool) -> bool
{
    c := p_char^;

    // Filter non-printable (NB: isprint is unreliable! see #2467)
    apply_named_filters := true;
    if (c < 0x20)
    {
        pass := false;
        pass |= (c == '\n') && (.Multiline in flags) // Note that an Enter KEY will emit \r and be ignored (we poll for KEY in InputText() code)
        pass |= (c == '\t') && (.AllowTabInput in flags)
        if (!pass)   do return false
        apply_named_filters = false; // Override named filters below so newline and tabs can still be inserted.
    }

    if (input_source_is_clipboard == false)
    {
        // We ignore Ascii representation of delete (emitted from Backspace on OSX, see #2578, #2817)
        if (c == 127)   do return false

        // Filter private Unicode range. GLFW on OSX seems to send private characters for special keys like arrow keys (FIXME)
        if (c >= 0xE000 && c <= 0xF8FF)   do return false
    }

    // Filter Unicode ranges we are not handling in this build
    if (c > IM_UNICODE_CODEPOINT_MAX)   do return false

    // Generic named filters
    if (apply_named_filters && (flags & (ImGuiInputTextFlags_CharsDecimal | ImGuiInputTextFlags_CharsHexadecimal | ImGuiInputTextFlags_CharsUppercase | ImGuiInputTextFlags_CharsNoBlank | ImGuiInputTextFlags_CharsScientific | ImGuiInputTextFlags_LocalizeDecimalPoint)))
    {
        // The libc allows overriding locale, with e.g. 'setlocale(LC_NUMERIC, "de_DE.UTF-8");' which affect the output/input of printf/scanf to use e.g. ',' instead of '.'.
        // The standard mandate that programs starts in the "C" locale where the decimal point is '.'.
        // We don't really intend to provide widespread support for it, but out of empathy for people stuck with using odd API, we support the bare minimum aka overriding the decimal point.
        // Change the default decimal_point with:
        //   ImGui::GetPlatformIO()->Platform_LocaleDecimalPoint = *localeconv()->decimal_point;
        // Users of non-default decimal point (in particular ',') may be affected by word-selection logic (is_word_boundary_from_right/is_word_boundary_from_left) functions.
        g := ctx;
        c_decimal_point := cast(u32) g.PlatformIO.Platform_LocaleDecimalPoint;
        if (flags & (ImGuiInputTextFlags_CharsDecimal | ImGuiInputTextFlags_CharsScientific | ImGuiInputTextFlags_LocalizeDecimalPoint)) {
            if (c == '.' || c == ',')   do c = c_decimal_point
        }

        // Full-width -> half-width conversion for numeric fields (https://en.wikipedia.org/wiki/Halfwidth_and_Fullwidth_Forms_(Unicode_block)
        // While this is mostly convenient, this has the side-effect for uninformed users accidentally inputting full-width characters that they may
        // scratch their head as to why it works in numerical fields vs in generic text fields it would require support in the font.
        if (flags & (ImGuiInputTextFlags_CharsDecimal | ImGuiInputTextFlags_CharsScientific | ImGuiInputTextFlags_CharsHexadecimal)) {
            if (c >= 0xFF01 && c <= 0xFF5E)   do c = c - 0xFF01 + 0x21
        }

        // Allow 0-9 . - + * /
        if (.CharsDecimal in flags) {
            if (!(c >= '0' && c <= '9') && (c != c_decimal_point) && (c != '-') && (c != '+') && (c != '*') && (c != '/'))   do return false
        }

        // Allow 0-9 . - + * / e E
        if (.CharsScientific in flags) {
            if (!(c >= '0' && c <= '9') && (c != c_decimal_point) && (c != '-') && (c != '+') && (c != '*') && (c != '/') && (c != 'e') && (c != 'E'))   do return false
        }

        // Allow 0-9 a-F A-F
        if (.CharsHexadecimal in flags) {
            if (!(c >= '0' && c <= '9') && !(c >= 'a' && c <= 'f') && !(c >= 'A' && c <= 'F'))   do return false
        }

        // Turn a-z into A-Z
        if (.CharsUppercase in flags) {
            if (c >= 'a' && c <= 'z')   do c += (u32)('A' - 'a')
        }

        if (.CharsNoBlank in flags) {
            if (ImCharIsBlankW(c))   do return false
        }

        p_char^ = c;
    }

    // Custom callback filter
    if (.CallbackCharFilter in flags)
    {
        g := GImGui;
        callback_data : ImGuiInputTextCallbackData
        callback_data.Ctx = &g;
        callback_data.EventFlag = ImGuiInputTextFlags_CallbackCharFilter;
        callback_data.EventChar = ImWchar(c);
        callback_data.Flags = flags;
        callback_data.UserData = user_data;
        if (callback(&callback_data) != 0)   do return false
        p_char^ = callback_data.EventChar;
        if (!callback_data.EventChar)   do return false
    }

    return true;
}

// Find the shortest single replacement we can make to get from old_buf to new_buf
// Note that this doesn't directly alter state.TextA, state.TextLen. They are expected to be made valid separately.
// FIXME: Ideally we should transition toward (1) making InsertChars()/DeleteChars() update undo-stack (2) discourage (and keep reconcile) or obsolete (and remove reconcile) accessing buffer directly.
InputTextReconcileUndoState :: proc(state : ^ImGuiInputTextState, old_buf : ^u8, old_length : i32, new_buf : ^u8, new_length : i32)
{
    shorter_length := ImMin(old_length, new_length);
    first_diff : i32
    for first_diff = 0; first_diff < shorter_length; first_diff += 1 {
        if (old_buf[first_diff] != new_buf[first_diff])   do break
    }
    if (first_diff == old_length && first_diff == new_length)   do return

    old_last_diff := old_length - 1;
    new_last_diff := new_length - 1;
    for ; old_last_diff >= first_diff && new_last_diff >= first_diff; old_last_diff, new_last_diff = old_last_diff - 1, new_last_diff - 1 {
        if (old_buf[old_last_diff] != new_buf[new_last_diff])   do break
    }

    insert_len := new_last_diff - first_diff + 1;
    delete_len := old_last_diff - first_diff + 1;
    if (insert_len > 0 || delete_len > 0) {
        if p := stb_text_createundo(&state.Stb.undostate, first_diff, delete_len, insert_len); p != 0 {
            for i := 0; i < delete_len; i += 1 {
                p[i] = old_buf[first_diff + i];
            }
        }
    }
}

// As InputText() retain textual data and we currently provide a path for user to not retain it (via local variables)
// we need some form of hook to reapply data back to user buffer on deactivation frame. (#4714)
// It would be more desirable that we discourage users from taking advantage of the "user not retaining data" trick,
// but that more likely be attractive when we do have _NoLiveEdit flag available.
InputTextDeactivateHook :: proc(id : ImGuiID)
{
    g := GImGui;
    state := &g.InputTextState;
    if (id == 0 || state.ID != id)   do return
    g.InputTextDeactivatedState.ID = state.ID;
    if (.ReadOnly in state.Flags)
    {
        clear(&g.InputTextDeactivatedState.TextA); // In theory this data won't be used, but clear to be neat.
    }
    else
    {
        assert(raw_data(state.TextA) != nil);
        assert(state.TextA[state.TextLen] == 0);
        resize(&g.InputTextDeactivatedState.TextA, state.TextLen + 1);
        memcpy(raw_data(g.InputTextDeactivatedState.TextA), raw_data(state.TextA), int(state.TextLen + 1));
    }
}

// Edit a string of text
// - buf_size account for the zero-terminator, so a buf_size of 6 can hold "Hello" but not "Hello!".
//   This is so we can easily call InputText() on static arrays using ARRAYSIZE() and to match
//   Note that in std::string world, capacity() would omit 1 byte used by the zero-terminator.
// - When active, hold on a privately held copy of the text (and apply back to 'buf'). So changing 'buf' while the InputText is active has no effect.
// - If you want to use ImGui::InputText() with std::string, see misc/cpp/imgui_stdlib.h
// (FIXME: Rather confusing and messy function, among the worse part of our codebase, expecting to rewrite a V2 at some point.. Partly because we are
//  doing UTF8 > U16 > UTF8 conversions on the go to easily interface with stb_textedit. Ideally should stay in UTF-8 all the time. See https://github.com/nothings/stb/issues/188)
InputTextEx :: proc(label : string, hint : ^u8, buf_ : []u8, size_arg : ImVec2, flags : ImGuiInputTextFlags, callback : ImGuiInputTextCallback, callback_user_data : rawptr) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    buf := raw_data(buf_)
    buf_size := cast(i32) len(buf_)

    assert(buf != nil);
    assert(!((.CallbackHistory in flags) && (flags & transmute(ImGuiInputTextFlags) ImGuiInputTextFlagsPrivate.Multiline != nil)));        // Can't use both together (they both use up/down keys)
    assert(!((.CallbackCompletion in flags) && (.AllowTabInput in flags))); // Can't use both together (they both use tab key)
    assert(!((.ElideLeft in flags) && (flags & transmute(ImGuiInputTextFlags) ImGuiInputTextFlagsPrivate.Multiline != nil)));               // Multiline will not work with left-trimming

    g := GImGui;
    io := &g.IO;
    style := &g.Style;

    RENDER_SELECTION_WHEN_INACTIVE := false;
    is_multiline := (flags & transmute(ImGuiInputTextFlags) ImGuiInputTextFlagsPrivate.Multiline != nil)

    if (is_multiline) do BeginGroup() // Open group before calling GetID() because groups tracks id created within their scope (including the scrollbar) 
    id := GetID(window, label);
    label_size := CalcTextSize(label, true);
    frame_size := CalcItemSize(size_arg, CalcItemWidth(), (is_multiline ? g.FontSize * 8.0 : label_size.y) + style.FramePadding.y * 2.0); // Arbitrary default of 8 lines high for multi-line
    total_size := ImVec2{frame_size.x + (label_size.x > 0.0 ? style.ItemInnerSpacing.x + label_size.x : 0.0), frame_size.y};

    frame_bb := ImRect{ _v = { window.DC.CursorPos, window.DC.CursorPos + frame_size} };
    total_bb := ImRect{ _v = { frame_bb.Min, frame_bb.Min + total_size} };

    draw_window := window;
    inner_size := frame_size;
    item_data_backup : ImGuiLastItemData
    if (is_multiline)
    {
        backup_pos := window.DC.CursorPos;
        ItemSize(total_bb, style.FramePadding.y);
        if (!ItemAdd(total_bb, id, &frame_bb, .Inputable))
        {
            EndGroup();
            return false;
        }
        item_data_backup = g.LastItemData;
        window.DC.CursorPos = backup_pos;

        // Prevent NavActivation from Tabbing when our widget accepts Tab inputs: this allows cycling through widgets without stopping.
        if (g.NavActivateId == id && (.FromTabbing in g.NavActivateFlags) && (.AllowTabInput in flags))   do g.NavActivateId = 0

        // Prevent NavActivate reactivating in BeginChild() when we are already active.
        backup_activate_id := g.NavActivateId;
        if (g.ActiveId == id) {// Prevent reactivation
            g.NavActivateId = 0;
        }

        // We reproduce the contents of BeginChildFrame() in order to provide 'label' so our window internal data are easier to read/debug.
        PushStyleColor(ImGuiCol.ChildBg, style.Colors[ImGuiCol.FrameBg]);
        PushStyleVar(.ChildRounding, style.FrameRounding);
        PushStyleVar(.ChildBorderSize, style.FrameBorderSize);
        PushStyleVar(.WindowPadding, ImVec2{0, 0}); // Ensure no clip rect so mouse hover can reach FramePadding edges
        child_visible := BeginChildEx(label, id, GetSize(frame_bb), {.Borders}, {.NoMove});
        g.NavActivateId = backup_activate_id;
        PopStyleVar(3);
        PopStyleColor();
        if (!child_visible)
        {
            EndChild();
            EndGroup();
            return false;
        }
        draw_window = g.CurrentWindow; // Child window
        draw_window.DC.NavLayersActiveMaskNext |= (1 << u32(draw_window.DC.NavLayerCurrent)); // This is to ensure that EndChild() will display a navigation highlight so we can "enter" into it.
        draw_window.DC.CursorPos += style.FramePadding;
        inner_size.x -= draw_window.ScrollbarSizes.x;
    }
    else
    {
        // Support for internal ImGuiInputTextFlags_MergedItem flag, which could be redesigned as an ItemFlags if needed (with test performed in ItemAdd)
        ItemSize(total_bb, style.FramePadding.y);
        if (!(flags & transmute(ImGuiInputTextFlags) ImGuiInputTextFlagsPrivate.MergedItem != nil)) {
            if (!ItemAdd(total_bb, id, &frame_bb, {.Inputable}))   do return false
        }
    }

    // Ensure mouse cursor is set even after switching to keyboard/gamepad mode. May generalize further? (#6417)
    hovered := ItemHoverable(frame_bb, id, g.LastItemData.ItemFlags | transmute(ImGuiItemFlags) ImGuiItemFlagsPrivate.NoNavDisableMouseHover);
    if (hovered) do SetMouseCursor(.TextInput);
    if (hovered && g.NavHighlightItemUnderNav)   do hovered = false

    // We are only allowed to access the state if we are already the active widget.
    state := GetInputTextState(id);

    flags := flags
    if (g.LastItemData.ItemFlags & transmute(ImGuiItemFlags) ImGuiItemFlagsPrivate.ReadOnly != nil) {
        flags |= {.ReadOnly};
    }
    is_readonly := (.ReadOnly in flags)
    is_password := (.Password in flags)
    is_undoable := (.NoUndoRedo not_in flags)
    is_resizable := (.CallbackResize in flags)
    if (is_resizable) do assert(callback != nil); // Must provide a callback if you set the ImGuiInputTextFlags_CallbackResize flag!

    input_requested_by_nav := (g.ActiveId != id) && ((g.NavActivateId == id) && ((.PreferInput in g.NavActivateFlags) || (g.NavInputSource == .Keyboard)));

    user_clicked := hovered && io.MouseClicked[0];
    user_scroll_finish := is_multiline && state != nil && g.ActiveId == 0 && g.ActiveIdPreviousFrame == GetWindowScrollbarID(draw_window, .Y);
    user_scroll_active := is_multiline && state != nil && g.ActiveId == GetWindowScrollbarID(draw_window, .Y);
    clear_active_id := false;
    select_all := false;

    scroll_y := is_multiline ? draw_window.Scroll.y : math.F32_MAX;

    init_reload_from_user_buf := (state != nil && state.WantReloadUserBuf);
    init_changed_specs := (state != nil && state.Stb.single_line != !is_multiline); // state != NULL means its our state.
    init_make_active := (user_clicked || user_scroll_finish || input_requested_by_nav);
    init_state := (init_make_active || user_scroll_active);
    if (init_reload_from_user_buf)
    {
        new_len := cast(i32) strlen(buf);
        assert(new_len + 1 <= buf_size, "Is your input buffer properly zero-terminated?");
        state.WantReloadUserBuf = false;
        InputTextReconcileUndoState(state, raw_data(state.TextA), state.TextLen, buf, new_len);
        resize(&state.TextA, int(buf_size + 1)); // we use +1 to make sure that .Data is always pointing to at least an empty string.
        state.TextLen = new_len;
        memcpy(raw_data(state.TextA), buf, int(state.TextLen + 1));
        state.Stb.select_start = state.ReloadSelectionStart;
        state.Stb.select_end = state.ReloadSelectionEnd;
        state.Stb.cursor = state.Stb.select_end;
        CursorClamp(state);
    }
    else if ((init_state && g.ActiveId != id) || init_changed_specs)
    {
        // Access state even if we don't own it yet.
        state = &g.InputTextState;
        CursorAnimReset(state);

        // Backup state of deactivating item so they'll have a chance to do a write to output buffer on the same frame they report IsItemDeactivatedAfterEdit (#4714)
        InputTextDeactivateHook(state.ID);

        // Take a copy of the initial buffer value.
        // From the moment we focused we are normally ignoring the content of 'buf' (unless we are in read-only mode)
        buf_len := cast(i32) strlen(buf);
        assert(buf_len + 1 <= buf_size, "Is your input buffer properly zero-terminated?");
        resize(&state.TextToRevertTo, buf_len + 1);    // UTF-8. we use +1 to make sure that .Data is always pointing to at least an empty string.
        memcpy(raw_data(state.TextToRevertTo), buf, int(buf_len + 1));

        // Preserve cursor position and undo/redo stack if we come back to same widget
        // FIXME: Since we reworked this on 2022/06, may want to differentiate recycle_cursor vs recycle_undostate?
        recycle_state := (state.ID == id && !init_changed_specs);
        if (recycle_state && (state.TextLen != buf_len || (raw_data(state.TextA) == nil || strncmp(raw_data(state.TextA), buf, buf_len) != 0)))   do recycle_state = false

        // Start edition
        state.ID = id;
        state.TextLen = buf_len;
        if (!is_readonly)
        {
            resize(&state.TextA, buf_size + 1); // we use +1 to make sure that .Data is always pointing to at least an empty string.
            memcpy(raw_data(state.TextA), buf, int(state.TextLen + 1));
        }

        // Find initial scroll position for right alignment
        state.Scroll = ImVec2{0.0, 0.0};
        if (.ElideLeft in flags) {
            state.Scroll.x += ImMax(0.0, CalcTextSize(cast(string) cstring(buf)).x - frame_size.x + style.FramePadding.x * 2.0);
        }

        // Recycle existing cursor/selection/undo stack but clamp position
        // Note a single mouse click will override the cursor/position immediately by calling stb_textedit_click handler.
        if (recycle_state)   do CursorClamp(state)
        else do stb_textedit_initialize_state(state.Stb, !is_multiline);

        if (!is_multiline)
        {
            if (.AutoSelectAll in flags)   do select_all = true
            if (input_requested_by_nav && (!recycle_state || !(.TryToPreserveState in g.NavActivateFlags)))   do select_all = true
            if (user_clicked && io.KeyCtrl)   do select_all = true
        }

        if (.AlwaysOverwrite in flags) {
            state.Stb.insert_mode = 1; // stb field name is indeed incorrect (see #2863)
        }
    }

    is_osx := io.ConfigMacOSXBehaviors;
    if (g.ActiveId != id && init_make_active)
    {
        assert(state && state.ID == id);
        SetActiveID(id, window);
        SetFocusID(id, window);
        FocusWindow(window);
    }
    if (g.ActiveId == id)
    {
        // Declare some inputs, the other are registered and polled via Shortcut() routing system.
        // FIXME: The reason we don't use Shortcut() is we would need a routing flag to specify multiple mods, or to all mods combinaison into individual shortcuts.
        always_owned_keys := [?]ImGuiKey { .LeftArrow, .RightArrow, .Enter, .KeypadEnter, .Delete, .Backspace, .Home, .End };
        for key in always_owned_keys   do SetKeyOwner(key, id);
        if (user_clicked) do SetKeyOwner(.MouseLeft, id);
        g.ActiveIdUsingNavDirMask |= (1 << u32(ImGuiDir.Left)) | (1 << u32(ImGuiDir.Right));
        if (is_multiline || (.CallbackHistory in flags))
        {
            g.ActiveIdUsingNavDirMask |= (1 << u32(ImGuiDir.Up)) | (1 << u32(ImGuiDir.Down));
            SetKeyOwner(.UpArrow, id);
            SetKeyOwner(.DownArrow, id);
        }
        if (is_multiline)
        {
            SetKeyOwner(.PageUp, id);
            SetKeyOwner(.PageDown, id);
        }
        // FIXME: May be a problem to always steal Alt on OSX, would ideally still allow an uninterrupted Alt down-up to toggle menu
        if (is_osx) do SetKeyOwner(.Alt, id);

        // Expose scroll in a manner that is agnostic to us using a child window
        if (is_multiline && state != nil) do state.Scroll.y = draw_window.Scroll.y;

        // Read-only mode always ever read from source buffer. Refresh TextLen when active.
        if (is_readonly && state != nil) do state.TextLen = cast(i32) strlen(buf);
        //if (is_readonly && state != NULL)
        //    state.TextA.clear(); // Uncomment to facilitate debugging, but we otherwise prefer to keep/amortize th allocation.
    }
    if (state != nil) do state.TextSrc = is_readonly ? raw_data(buf) : raw_data(state.TextA);

    // We have an edge case if ActiveId was set through another widget (e.g. widget being swapped), clear id immediately (don't wait until the end of the function)
    if (g.ActiveId == id && state == nil)   do ClearActiveID()

    // Release focus when we click outside
    if (g.ActiveId == id && io.MouseClicked[0] && !init_state && !init_make_active) {//-V560
        clear_active_id = true;
    }

    // Lock the decision of whether we are going to take the path displaying the cursor or selection
    render_cursor := (g.ActiveId == id) || (state != nil && user_scroll_active);
    render_selection := state != nil && (HasSelection(state) || select_all) && (RENDER_SELECTION_WHEN_INACTIVE || render_cursor);
    value_changed := false;
    validated := false;

    // Select the buffer to render.
    buf_display_from_state := (render_cursor || render_selection || g.ActiveId == id) && !is_readonly && state;
    is_displaying_hint := (hint != nil && (buf_display_from_state ? raw_data(state.TextA) : buf)[0] == 0);

    // Password pushes a temporary font with only a fallback glyph
    if (is_password && !is_displaying_hint)
    {
        glyph := FindGlyph(g.Font, '*');
        password_font := &g.InputTextPasswordFont;
        password_font.FontSize = g.Font.FontSize;
        password_font.Scale = g.Font.Scale;
        password_font.Ascent = g.Font.Ascent;
        password_font.Descent = g.Font.Descent;
        password_font.ContainerAtlas = g.Font.ContainerAtlas;
        password_font.FallbackGlyph = glyph;
        password_font.FallbackAdvanceX = glyph.AdvanceX;
        assert(len(password_font.Glyphs) == 0 && len(password_font.IndexAdvanceX) == 0 && len(password_font.IndexLookup) == 0);
        PushFont(password_font);
    }

    // Process mouse inputs and character inputs
    if (g.ActiveId == id)
    {
        assert(state != nil);
        state.Edited = false;
        state.BufCapacity = buf_size;
        state.Flags = flags;

        // Although we are active we don't prevent mouse from hovering other elements unless we are interacting right now with the widget.
        // Down the line we should have a cleaner library-wide concept of Selected vs Active.
        g.ActiveIdAllowOverlap = !io.MouseDown[0];

        // Edit in progress
        mouse_x := (io.MousePos.x - frame_bb.Min.x - style.FramePadding.x) + state.Scroll.x;
        mouse_y := (is_multiline ? (io.MousePos.y - draw_window.DC.CursorPos.y) : (g.FontSize * 0.5));

        if (select_all)
        {
            SelectAll(state);
            state.SelectedAllMouseLock = true;
        }
        else if (hovered && io.MouseClickedCount[0] >= 2 && !io.KeyShift)
        {
            stb_textedit_click(state, state.Stb, mouse_x, mouse_y);
            multiclick_count := (io.MouseClickedCount[0] - 2);
            if ((multiclick_count % 2) == 0)
            {
                // Double-click: Select word
                // We always use the "Mac" word advance for double-click select vs CTRL+Right which use the platform dependent variant:
                // FIXME: There are likely many ways to improve this behavior, but there's no "right" behavior (depends on use-case, software, OS)
                is_bol := (state.Stb.cursor == 0) || STB_TEXTEDIT_GETCHAR(state, state.Stb.cursor - 1) == '\n';
                if (STB_TEXT_HAS_SELECTION(state.Stb) || !is_bol) {
                    OnKeyPressed(state, STB_TEXTEDIT_K_WORDLEFT);
                }
                //OnKeyPressed(state, STB_TEXTEDIT_K_WORDRIGHT | STB_TEXTEDIT_K_SHIFT);
                if (!STB_TEXT_HAS_SELECTION(state.Stb)) {
                    stb_textedit_prep_selection_at_cursor(state.Stb);
                }
                state.Stb.cursor = STB_TEXTEDIT_MOVEWORDRIGHT_MAC(state, state.Stb.cursor);
                state.Stb.select_end = state.Stb.cursor;
                stb_textedit_clamp(state, state.Stb);
            }
            else
            {
                // Triple-click: Select line
                is_eol := STB_TEXTEDIT_GETCHAR(state, state.Stb.cursor) == '\n';
                OnKeyPressed(state, STB_TEXTEDIT_K_LINESTART);
                OnKeyPressed(state, STB_TEXTEDIT_K_LINEEND | STB_TEXTEDIT_K_SHIFT);
                OnKeyPressed(state, STB_TEXTEDIT_K_RIGHT | STB_TEXTEDIT_K_SHIFT);
                if (!is_eol && is_multiline)
                {
                    ImSwap(&state.Stb.select_start, &state.Stb.select_end);
                    state.Stb.cursor = state.Stb.select_end;
                }
                state.CursorFollow = false;
            }
            CursorAnimReset(state);
        }
        else if (io.MouseClicked[0] && !state.SelectedAllMouseLock)
        {
            if (hovered)
            {
                if (io.KeyShift) do stb_textedit_drag(state, state.Stb, mouse_x, mouse_y);
                else do stb_textedit_click(state, state.Stb, mouse_x, mouse_y);
                CursorAnimReset(state);
            }
        }
        else if (io.MouseDown[0] && !state.SelectedAllMouseLock && (io.MouseDelta.x != 0.0 || io.MouseDelta.y != 0.0))
        {
            stb_textedit_drag(state, state.Stb, mouse_x, mouse_y);
            CursorAnimReset(state);
            state.CursorFollow = true;
        }
        if (state.SelectedAllMouseLock && !io.MouseDown[0]) {
            state.SelectedAllMouseLock = false;
        }

        // We expect backends to emit a Tab key but some also emit a Tab character which we ignore (#2467, #1336)
        // (For Tab and Enter: Win32/SFML/Allegro are sending both keys and chars, GLFW and SDL are only sending keys. For Space they all send all threes)
        if ((.AllowTabInput in flags) && !is_readonly)
        {
            if (Shortcut(.Tab, .Repeat, id))
            {
                c := ImWchar32('\t'); // Insert TAB
                if (InputTextFilterCharacter(g, &c, flags, callback, callback_user_data))   do OnCharPressed(state, c)
            }
            // FIXME: Implement Shift+Tab
            /*
            if (Shortcut(ImGuiKey.Tab | ImGuiKey.Mod_Shift, ImGuiInputFlags_Repeat, id))
            {
            }
            */
        }

        // Process regular text input (before we check for Return because using some IME will effectively send a Return?)
        // We ignore CTRL inputs, but need to allow ALT+CTRL as some keyboards (e.g. German) use AltGR (which _is_ Alt+Ctrl) to input certain characters.
        ignore_char_inputs := (io.KeyCtrl && !io.KeyAlt) || (is_osx && io.KeyCtrl);
        if (len(io.InputQueueCharacters) > 0)
        {
            if (!ignore_char_inputs && !is_readonly && !input_requested_by_nav) {
                for n := 0; n < len(io.InputQueueCharacters); n += 1
                {
                    // Insert character if they pass filtering
                    c := cast(ImWchar32) io.InputQueueCharacters[n];
                    if (c == '\t') do continue// Skip Tab, see above.
                    if (InputTextFilterCharacter(g, &c, flags, callback, callback_user_data))   do OnCharPressed(state, c)
                }
            }

            // Consume characters
            clear(&io.InputQueueCharacters)
        }
    }

    // Process other shortcuts/key-presses
    revert_edit := false;
    if (g.ActiveId == id && !g.ActiveIdIsJustActivated && !clear_active_id)
    {
        assert(state != nil);

        row_count_per_page := ImMax(cast(i32)((inner_size.y - style.FramePadding.y) / g.FontSize), 1);
        state.Stb.row_count_per_page = row_count_per_page;

        k_mask := (io.KeyShift ? STB_TEXTEDIT_K_SHIFT : 0);
        is_wordmove_key_down := is_osx ? io.KeyAlt : io.KeyCtrl;                     // OS X style: Text editing cursor movement using Alt instead of Ctrl
        is_startend_key_down := is_osx && io.KeyCtrl && !io.KeySuper && !io.KeyAlt;  // OS X style: Line/Text Start and End using Cmd+Arrows instead of Home/End

        // Using Shortcut() with ImGuiInputFlags_RouteFocused (default policy) to allow routing operations for other code (e.g. calling window trying to use CTRL+A and CTRL+B: formet would be handled by InputText)
        // Otherwise we could simply assume that we own the keys as we are active.
        f_repeat := ImGuiInputFlags{.Repeat};
        is_cut := (Shortcut(ImGuiKey.Mod_Ctrl | ImGuiKey.X, f_repeat, id) || Shortcut(ImGuiKey.Mod_Shift | ImGuiKey.Delete, f_repeat, id)) && !is_readonly && !is_password && (!is_multiline || HasSelection(state));
        is_copy := (Shortcut(ImGuiKey.Mod_Ctrl | ImGuiKey.C, 0,        id) || Shortcut(ImGuiKey.Mod_Ctrl  | ImGuiKey.Insert, 0,        id)) && !is_password && (!is_multiline || HasSelection(state));
        is_paste := (Shortcut(ImGuiKey.Mod_Ctrl | ImGuiKey.V, f_repeat, id) || Shortcut(ImGuiKey.Mod_Shift | ImGuiKey.Insert, f_repeat, id)) && !is_readonly;
        is_undo := (Shortcut(ImGuiKey.Mod_Ctrl | ImGuiKey.Z, f_repeat, id)) && !is_readonly && is_undoable;
        is_redo :=  (Shortcut(ImGuiKey.Mod_Ctrl | ImGuiKey.Y, f_repeat, id) || (is_osx && Shortcut(ImGuiKey.Mod_Ctrl | ImGuiKey.Mod_Shift | ImGuiKey.Z, f_repeat, id))) && !is_readonly && is_undoable;
        is_select_all := Shortcut(ImGuiKey.Mod_Ctrl | ImGuiKey.A, 0, id);

        // We allow validate/cancel with Nav source (gamepad) to makes it easier to undo an accidental NavInput press with no keyboard wired, but otherwise it isn't very useful.
        nav_gamepad_active := (.NavEnableGamepad in io.ConfigFlags) && (.HasGamepad in io.BackendFlags);
        is_enter_pressed := IsKeyPressed(ImGuiKey.Enter, true) || IsKeyPressed(ImGuiKey.KeypadEnter, true);
        is_gamepad_validate := nav_gamepad_active && (IsKeyPressed(ImGuiKey_NavGamepadActivate(g), false) || IsKeyPressed(ImGuiKey_NavGamepadInput, false));
        is_cancel := Shortcut(ImGuiKey.Escape, f_repeat, id) || (nav_gamepad_active && Shortcut(ImGuiKey.NavGamepadCancel, f_repeat, id));

        // FIXME: Should use more Shortcut() and reduce IsKeyPressed()+SetKeyOwner(), but requires modifiers combination to be taken account of.
        // FIXME-OSX: Missing support for Alt(option)+Right/Left = go to end of line, or next line if already in end of line.
        if (IsKeyPressed(ImGuiKey.LeftArrow))                        { OnKeyPressed(state, (is_startend_key_down ? STB_TEXTEDIT_K_LINESTART : is_wordmove_key_down ? STB_TEXTEDIT_K_WORDLEFT : STB_TEXTEDIT_K_LEFT) | k_mask); }
        else if (IsKeyPressed(ImGuiKey.RightArrow))                  { OnKeyPressed(state, (is_startend_key_down ? STB_TEXTEDIT_K_LINEEND : is_wordmove_key_down ? STB_TEXTEDIT_K_WORDRIGHT : STB_TEXTEDIT_K_RIGHT) | k_mask); }
        else if (IsKeyPressed(ImGuiKey.UpArrow) && is_multiline)     { if (io.KeyCtrl) do SetScrollY(draw_window, ImMax(draw_window.Scroll.y - g.FontSize, 0.0)); else do OnKeyPressed(state, (is_startend_key_down ? STB_TEXTEDIT_K_TEXTSTART : STB_TEXTEDIT_K_UP) | k_mask); }
        else if (IsKeyPressed(ImGuiKey.DownArrow) && is_multiline)   { if (io.KeyCtrl) do SetScrollY(draw_window, ImMin(draw_window.Scroll.y + g.FontSize, GetScrollMaxY())); else do OnKeyPressed(state, (is_startend_key_down ? STB_TEXTEDIT_K_TEXTEND : STB_TEXTEDIT_K_DOWN) | k_mask); }
        else if (IsKeyPressed(ImGuiKey.PageUp) && is_multiline)      { OnKeyPressed(state, STB_TEXTEDIT_K_PGUP | k_mask); scroll_y -= row_count_per_page * g.FontSize; }
        else if (IsKeyPressed(ImGuiKey.PageDown) && is_multiline)    { OnKeyPressed(state, STB_TEXTEDIT_K_PGDOWN | k_mask); scroll_y += row_count_per_page * g.FontSize; }
        else if (IsKeyPressed(ImGuiKey.Home))                        { OnKeyPressed(state, io.KeyCtrl ? STB_TEXTEDIT_K_TEXTSTART | k_mask : STB_TEXTEDIT_K_LINESTART | k_mask); }
        else if (IsKeyPressed(ImGuiKey.End))                         { OnKeyPressed(state, io.KeyCtrl ? STB_TEXTEDIT_K_TEXTEND | k_mask : STB_TEXTEDIT_K_LINEEND | k_mask); }
        else if (IsKeyPressed(ImGuiKey.Delete) && !is_readonly && !is_cut)
        {
            if (!HasSelection(state))
            {
                // OSX doesn't seem to have Super+Delete to delete until end-of-line, so we don't emulate that (as opposed to Super+Backspace)
                if (is_wordmove_key_down) do OnKeyPressed(state, STB_TEXTEDIT_K_WORDRIGHT | STB_TEXTEDIT_K_SHIFT);
            }
            OnKeyPressed(state, STB_TEXTEDIT_K_DELETE | k_mask);
        }
        else if (IsKeyPressed(ImGuiKey.Backspace) && !is_readonly)
        {
            if (!HasSelection(state))
            {
                if (is_wordmove_key_down) {
                    OnKeyPressed(state, STB_TEXTEDIT_K_WORDLEFT | STB_TEXTEDIT_K_SHIFT);
                }
                else if (is_osx && io.KeyCtrl && !io.KeyAlt && !io.KeySuper) {
                    OnKeyPressed(state, STB_TEXTEDIT_K_LINESTART | STB_TEXTEDIT_K_SHIFT);
                }
            }
            OnKeyPressed(state, STB_TEXTEDIT_K_BACKSPACE | k_mask);
        }
        else if (is_enter_pressed || is_gamepad_validate)
        {
            // Determine if we turn Enter into a \n character
            ctrl_enter_for_new_line := (.CtrlEnterForNewLine in flags)
            if (!is_multiline || is_gamepad_validate || (ctrl_enter_for_new_line && !io.KeyCtrl) || (!ctrl_enter_for_new_line && io.KeyCtrl))
            {
                validated = true;
                if (io.ConfigInputTextEnterKeepActive && !is_multiline) do state.SelectAll(); // No need to scroll
                else do clear_active_id = true;
            }
            else if (!is_readonly)
            {
                c := '\n'; // Insert new line
                if (InputTextFilterCharacter(g, &c, flags, callback, callback_user_data))   do OnCharPressed(state, c)
            }
        }
        else if (is_cancel)
        {
            if (.EscapeClearsAll in flags)
            {
                if (buf[0] != 0)
                {
                    revert_edit = true;
                }
                else
                {
                    render_cursor = false
                    render_selection = false;
                    clear_active_id = true;
                }
            }
            else
            {
                clear_active_id = true
                revert_edit = true;
                render_cursor = false
                render_selection = false;
            }
        }
        else if (is_undo || is_redo)
        {
            OnKeyPressed(state, is_undo ? STB_TEXTEDIT_K_UNDO : STB_TEXTEDIT_K_REDO);
            state.ClearSelection();
        }
        else if (is_select_all)
        {
            state.SelectAll();
            state.CursorFollow = true;
        }
        else if (is_cut || is_copy)
        {
            // Cut, Copy
            if (g.PlatformIO.Platform_SetClipboardTextFn != nil)
            {
                // SetClipboardText() only takes null terminated strings + state.TextSrc may point to read-only user buffer, so we need to make a copy.
                ib := HasSelection(state) ? ImMin(state.Stb.select_start, state.Stb.select_end) : 0;
                ie := HasSelection(state) ? ImMax(state.Stb.select_start, state.Stb.select_end) : state.TextLen;
                g.TempBuffer.reserve(ie - ib + 1);
                memcpy(g.TempBuffer.Data, state.TextSrc + ib, ie - ib);
                g.TempBuffer.Data[ie - ib] = 0;
                SetClipboardText(g.TempBuffer.Data);
            }
            if (is_cut)
            {
                if (!HasSelection(state))   do state.SelectAll()
                state.CursorFollow = true;
                stb_textedit_cut(state, state.Stb);
            }
        }
        else if (is_paste)
        {
            if clipboard := GetClipboardText(); clipboard != nil
            {
                // Filter pasted buffer
                clipboard_len := cast(i32) strlen(clipboard);
                clipboard_filtered : [dynamic]u8
                clipboard_filtered.reserve(clipboard_len + 1);
                for s := clipboard; s[0] != 0; 
                {
                    c : u32
                    in_len := ImTextCharFromUtf8(&c, s, nil);
                    s = s[in_len:];
                    if (!InputTextFilterCharacter(g, &c, flags, callback, callback_user_data, true))   do continue
                    c_utf8 : [5]u8
                    ImTextCharToUtf8(c_utf8, c);
                    out_len := cast(i32) strlen(c_utf8);
                    clipboard_filtered.resize(len(clipboard_filtered) + out_len);
                    memcpy(clipboard_filtered.Data + len(clipboard_filtered) - out_len, c_utf8, out_len);
                }
                if (len(clipboard_filtered) > 0) // If everything was filtered, ignore the pasting operation
                {
                    clipboard_filtered.append(0);
                    stb_textedit_paste(state, state.Stb, clipboard_filtered.Data, len(clipboard_filtered) - 1);
                    state.CursorFollow = true;
                }
            }
        }

        // Update render selection flag after events have been handled, so selection highlight can be displayed during the same frame.
        render_selection |= HasSelection(state) && (RENDER_SELECTION_WHEN_INACTIVE || render_cursor);
    }

    // Process callbacks and apply result back to user's buffer.
    apply_new_text := nil;
    apply_new_text_length := 0;
    if (g.ActiveId == id)
    {
        assert(state != nil);
        if (revert_edit && !is_readonly)
        {
            if (.EscapeClearsAll in flags)
            {
                // Clear input
                assert(buf[0] != 0);
                apply_new_text = "";
                apply_new_text_length = 0;
                value_changed = true;
                empty_string : IMSTB_TEXTEDIT_CHARTYPE
                stb_textedit_replace(state, state.Stb, &empty_string, 0);
            }
            else if (strcmp(buf, state.TextToRevertTo.Data) != 0)
            {
                apply_new_text = state.TextToRevertTo.Data;
                apply_new_text_length = len(state.TextToRevertTo) - 1;

                // Restore initial value. Only return true if restoring to the initial value changes the current buffer contents.
                // Push records into the undo stack so we can CTRL+Z the revert operation itself
                value_changed = true;
                stb_textedit_replace(state, state.Stb, state.TextToRevertTo.Data, len(state.TextToRevertTo) - 1);
            }
        }

        // When using 'ImGuiInputTextFlags_EnterReturnsTrue' as a special case we reapply the live buffer back to the input buffer
        // before clearing ActiveId, even though strictly speaking it wasn't modified on this frame.
        // If we didn't do that, code like InputInt() with ImGuiInputTextFlags_EnterReturnsTrue would fail.
        // This also allows the user to use InputText() with ImGuiInputTextFlags_EnterReturnsTrue without maintaining any user-side storage
        // (please note that if you use this property along ImGuiInputTextFlags_CallbackResize you can end up with your temporary string object
        // unnecessarily allocating once a frame, either store your string data, either if you don't then don't use ImGuiInputTextFlags_CallbackResize).
        apply_edit_back_to_user_buffer := !revert_edit || (validated && (.EnterReturnsTrue in flags) != 0);
        if (apply_edit_back_to_user_buffer)
        {
            // Apply new value immediately - copy modified buffer back
            // Note that as soon as the input box is active, the in-widget value gets priority over any underlying modification of the input buffer
            // FIXME: We actually always render 'buf' when calling DrawList.AddText, making the comment above incorrect.
            // FIXME-OPT: CPU waste to do this every time the widget is active, should mark dirty state from the stb_textedit callbacks.

            // User callback
            if ((flags & (ImGuiInputTextFlags_CallbackCompletion | ImGuiInputTextFlags_CallbackHistory | ImGuiInputTextFlags_CallbackEdit | ImGuiInputTextFlags_CallbackAlways)) != 0)
            {
                assert(callback != nil);

                // The reason we specify the usage semantic (Completion/History) is that Completion needs to disable keyboard TABBING at the moment.
                event_flag := 0;
                event_key := ImGuiKey.None;
                if ((.CallbackCompletion in flags) != 0 && Shortcut(ImGuiKey.Tab, 0, id))
                {
                    event_flag = ImGuiInputTextFlags_CallbackCompletion;
                    event_key = ImGuiKey.Tab;
                }
                else if ((.CallbackHistory in flags) != 0 && IsKeyPressed(ImGuiKey.UpArrow))
                {
                    event_flag = ImGuiInputTextFlags_CallbackHistory;
                    event_key = ImGuiKey.UpArrow;
                }
                else if ((.CallbackHistory in flags) != 0 && IsKeyPressed(ImGuiKey.DownArrow))
                {
                    event_flag = ImGuiInputTextFlags_CallbackHistory;
                    event_key = ImGuiKey.DownArrow;
                }
                else if ((.CallbackEdit in flags) && state.Edited)
                {
                    event_flag = ImGuiInputTextFlags_CallbackEdit;
                }
                else if (.CallbackAlways in flags)
                {
                    event_flag = ImGuiInputTextFlags_CallbackAlways;
                }

                if (event_flag)
                {
                    callback_data : ImGuiInputTextCallbackData
                    callback_data.Ctx = &g;
                    callback_data.EventFlag = event_flag;
                    callback_data.Flags = flags;
                    callback_data.UserData = callback_user_data;

                    // FIXME-OPT: Undo stack reconcile needs a backup of the data until we rework API, see #7925
                    callback_buf := is_readonly ? buf : state.TextA.Data;
                    assert(callback_buf == state.TextSrc);
                    state.CallbackTextBackup.resize(state.TextLen + 1);
                    memcpy(state.CallbackTextBackup.Data, callback_buf, state.TextLen + 1);

                    callback_data.EventKey = event_key;
                    callback_data.Buf = callback_buf;
                    callback_data.BufTextLen = state.TextLen;
                    callback_data.BufSize = state.BufCapacity;
                    callback_data.BufDirty = false;

                    callback_data.CursorPos = state.Stb.cursor
                    utf8_cursor_pos := callback_data.CursorPos
                    callback_data.SelectionStart = state.Stb.select_start;
                    utf8_selection_start := callback_data.SelectionStart
                    callback_data.SelectionEnd = state.Stb.select_end;
                    utf8_selection_end := callback_data.SelectionEnd

                    // Call user code
                    callback(&callback_data);

                    // Read back what user may have modified
                    callback_buf = is_readonly ? buf : state.TextA.Data; // Pointer may have been invalidated by a resize callback
                    assert(callback_data.Buf == callback_buf);         // Invalid to modify those fields
                    assert(callback_data.BufSize == state.BufCapacity);
                    assert(callback_data.Flags == flags);
                    buf_dirty := callback_data.BufDirty;
                    if (callback_data.CursorPos != utf8_cursor_pos || buf_dirty)            { state.Stb.cursor = callback_data.CursorPos; state.CursorFollow = true; }
                    if (callback_data.SelectionStart != utf8_selection_start || buf_dirty)  { state.Stb.select_start = (callback_data.SelectionStart == callback_data.CursorPos) ? state.Stb.cursor : callback_data.SelectionStart; }
                    if (callback_data.SelectionEnd != utf8_selection_end || buf_dirty)      { state.Stb.select_end = (callback_data.SelectionEnd == callback_data.SelectionStart) ? state.Stb.select_start : callback_data.SelectionEnd; }
                    if (buf_dirty)
                    {
                        // Callback may update buffer and thus set buf_dirty even in read-only mode.
                        assert(callback_data.BufTextLen == cast(i32) strlen(callback_data.Buf)); // You need to maintain BufTextLen if you change the text!
                        InputTextReconcileUndoState(state, state.CallbackTextBackup.Data, len(state.CallbackTextBackup) - 1, callback_data.Buf, callback_data.BufTextLen);
                        state.TextLen = callback_data.BufTextLen;  // Assume correct length and valid UTF-8 from user, saves us an extra strlen()
                        CursorAnimReset(state);
                    }
                }
            }

            // Will copy result string if modified
            if (!is_readonly && strcmp(state.TextSrc, buf) != 0)
            {
                apply_new_text = state.TextSrc;
                apply_new_text_length = state.TextLen;
                value_changed = true;
            }
        }
    }

    // Handle reapplying final data on deactivation (see InputTextDeactivateHook() for details)
    if (g.InputTextDeactivatedState.ID == id)
    {
        if (g.ActiveId != id && IsItemDeactivatedAfterEdit() && !is_readonly && strcmp(g.InputTextDeactivatedState.TextA.Data, buf) != 0)
        {
            apply_new_text = g.InputTextDeactivatedState.TextA.Data;
            apply_new_text_length = len(g.InputTextDeactivatedState.TextA) - 1;
            value_changed = true;
            //IMGUI_DEBUG_LOG("InputText(): apply Deactivated data for 0x%08X: \"%.*s\".\n", id, apply_new_text_length, apply_new_text);
        }
        g.InputTextDeactivatedState.ID = 0;
    }

    // Copy result to user buffer. This can currently only happen when (g.ActiveId == id)
    if (apply_new_text != nil)
    {
        //// We cannot test for 'backup_current_text_length != apply_new_text_length' here because we have no guarantee that the size
        //// of our owned buffer matches the size of the string object held by the user, and by design we allow InputText() to be used
        //// without any storage on user's side.
        assert(apply_new_text_length >= 0);
        if (is_resizable)
        {
            callback_data : ImGuiInputTextCallbackData
            callback_data.Ctx = &g;
            callback_data.EventFlag = ImGuiInputTextFlags_CallbackResize;
            callback_data.Flags = flags;
            callback_data.Buf = buf;
            callback_data.BufTextLen = apply_new_text_length;
            callback_data.BufSize = ImMax(buf_size, apply_new_text_length + 1);
            callback_data.UserData = callback_user_data;
            callback(&callback_data);
            buf = callback_data.Buf;
            buf_size = callback_data.BufSize;
            apply_new_text_length = ImMin(callback_data.BufTextLen, buf_size - 1);
            assert(apply_new_text_length <= buf_size);
        }
        //IMGUI_DEBUG_PRINT("InputText(\"%s\"): apply_new_text length %d\n", label, apply_new_text_length);

        // If the underlying buffer resize was denied or not carried to the next frame, apply_new_text_length+1 may be >= buf_size.
        ImStrncpy(buf, apply_new_text, ImMin(apply_new_text_length + 1, buf_size));
    }

    // Release active ID at the end of the function (so e.g. pressing Return still does a final application of the value)
    // Otherwise request text input ahead for next frame.
    if (g.ActiveId == id && clear_active_id)   do ClearActiveID()
    else if (g.ActiveId == id) do g.WantTextInputNextFrame = 1;

    // Render frame
    if (!is_multiline)
    {
        RenderNavCursor(frame_bb, id);
        RenderFrame(frame_bb.Min, frame_bb.Max, GetColorU32(ImGuiCol.FrameBg), true, style.FrameRounding);
    }

    clip_rect := ImVec4(frame_bb.Min.x, frame_bb.Min.y, frame_bb.Min.x + inner_size.x, frame_bb.Min.y + inner_size.y); // Not using frame_bb.Max because we have adjusted size
    draw_pos := is_multiline ? draw_window.DC.CursorPos : frame_bb.Min + style.FramePadding;
    text_size := ImVec2{0.0, 0.0};

    // Set upper limit of single-line InputTextEx() at 2 million characters strings. The current pathological worst case is a long line
    // without any carriage return, which would makes ImFont::RenderText() reserve too many vertices and probably crash. Avoid it altogether.
    // Note that we only use this limit on single-line InputText(), so a pathologically large line on a InputTextMultiline() would still crash.
    buf_display_max_length := 2 * 1024 * 1024;
    buf_display := buf_display_from_state ? state.TextA.Data : buf; //-V595
    buf_display_end := nil; // We have specialized paths below for setting the length
    if (is_displaying_hint)
    {
        buf_display = hint;
        buf_display_end = hint + strlen(hint);
    }

    // Render text. We currently only render selection when the widget is active or while scrolling.
    // FIXME: We could remove the '&& render_cursor' to keep rendering selection when inactive.
    if (render_cursor || render_selection)
    {
        assert(state != nil);
        if (!is_displaying_hint) do buf_display_end = buf_display + state.TextLen;

        // Render text (with cursor and selection)
        // This is going to be messy. We need to:
        // - Display the text (this alone can be more easily clipped)
        // - Handle scrolling, highlight selection, display cursor (those all requires some form of 1d.2d cursor position calculation)
        // - Measure text height (for scrollbar)
        // We are attempting to do most of that in **one main pass** to minimize the computation cost (non-negligible for large amount of text) + 2nd pass for selection rendering (we could merge them by an extra refactoring effort)
        // FIXME: This should occur on buf_display but we'd need to maintain cursor/select_start/select_end for UTF-8.
        text_begin := buf_display;
        text_end := text_begin + state.TextLen;
        cursor_offset, select_start_offset : ImVec2

        {
            // Find lines numbers straddling cursor and selection min position
            cursor_line_no := render_cursor ? -1 : -1000;
            selmin_line_no := render_selection ? -1 : -1000;
            cursor_ptr := render_cursor ? text_begin + state.Stb.cursor : nil;
            selmin_ptr := render_selection ? text_begin + ImMin(state.Stb.select_start, state.Stb.select_end) : nil;

            // Count lines and find line number for cursor and selection ends
            line_count := 1;
            if (is_multiline)
            {
                for s := memchr(text_begin, '\n', (int)(text_end - text_begin)); s != nil; s += 1
                {
                    if (cursor_line_no == -1 && s >= cursor_ptr) { cursor_line_no = line_count; }
                    if (selmin_line_no == -1 && s >= selmin_ptr) { selmin_line_no = line_count; }
                    line_count += 1;
                    s = memchr(s, '\n', (int)(text_end - s))
                }
            }
            if (cursor_line_no == -1) do cursor_line_no = line_count;
            if (selmin_line_no == -1) do selmin_line_no = line_count;

            // Calculate 2d position by finding the beginning of the line and measuring distance
            cursor_offset.x = InputTextCalcTextSize(g, ImStrbol(cursor_ptr, text_begin), cursor_ptr).x;
            cursor_offset.y = cursor_line_no * g.FontSize;
            if (selmin_line_no >= 0)
            {
                select_start_offset.x = InputTextCalcTextSize(g, ImStrbol(selmin_ptr, text_begin), selmin_ptr).x;
                select_start_offset.y = selmin_line_no * g.FontSize;
            }

            // Store text height (note that we haven't calculated text width at all, see GitHub issues #383, #1224)
            if (is_multiline) do text_size = ImVec2{inner_size.x, line_count * g.FontSize};
        }

        // Scroll
        if (render_cursor && state.CursorFollow)
        {
            // Horizontal scroll in chunks of quarter width
            if (!(.NoHorizontalScroll in flags))
            {
                scroll_increment_x := inner_size.x * 0.25;
                visible_width := inner_size.x - style.FramePadding.x;
                if (cursor_offset.x < state.Scroll.x) {
                    state.Scroll.x = math.trunc(ImMax(0.0, cursor_offset.x - scroll_increment_x));
                }
                else if (cursor_offset.x - visible_width >= state.Scroll.x) {
                    state.Scroll.x = math.trunc(cursor_offset.x - visible_width + scroll_increment_x);
                }
            }
            else
            {
                state.Scroll.y = 0.0;
            }

            // Vertical scroll
            if (is_multiline)
            {
                // Test if cursor is vertically visible
                if (cursor_offset.y - g.FontSize < scroll_y) {
                    scroll_y = ImMax(0.0, cursor_offset.y - g.FontSize);
                }
                else if (cursor_offset.y - (inner_size.y - style.FramePadding.y * 2.0) >= scroll_y) {
                    scroll_y = cursor_offset.y - inner_size.y + style.FramePadding.y * 2.0;
                }
                scroll_max_y := ImMax((text_size.y + style.FramePadding.y * 2.0) - inner_size.y, 0.0);
                scroll_y = ImClamp(scroll_y, 0.0, scroll_max_y);
                draw_pos.y += (draw_window.Scroll.y - scroll_y);   // Manipulate cursor pos immediately avoid a frame of lag
                draw_window.Scroll.y = scroll_y;
            }

            state.CursorFollow = false;
        }

        // Draw selection
        draw_scroll := ImVec2{state.Scroll.x, 0.0};
        if (render_selection)
        {
            text_selected_begin := text_begin + ImMin(state.Stb.select_start, state.Stb.select_end);
            text_selected_end := text_begin + ImMax(state.Stb.select_start, state.Stb.select_end);

            bg_color := GetColorU32(ImGuiCol.TextSelectedBg, render_cursor ? 1.0 : 0.6); // FIXME: current code flow mandate that render_cursor is always true here, we are leaving the transparent one for tests.
            bg_offy_up := is_multiline ? 0.0 : -1.0;    // FIXME: those offsets should be part of the style? they don't play so well with multi-line selection.
            bg_offy_dn := is_multiline ? 0.0 : 2.0;
            rect_pos := draw_pos + select_start_offset - draw_scroll;
            for p := text_selected_begin; p < text_selected_end; 
            {
                if (rect_pos.y > clip_rect.w + g.FontSize)   do break
                if (rect_pos.y < clip_rect.y)
                {
                    p = memchr(cast(rawptr)p, '\n', text_selected_end - p);
                    p = p ? p + 1 : text_selected_end;
                }
                else
                {
                    rect_size := InputTextCalcTextSize(g, p, text_selected_end, &p, nil, true);
                    if (rect_size.x <= 0.0) do rect_size.x = math.trunc(g.Font.GetCharAdvance(ImWchar(' ')) * 0.50); // So we can see selected empty lines
                    rect := ImRect{ _r = {rect_pos + ImVec2{0.0, bg_offy_up - g.FontSize}, rect_pos + ImVec2{rect_size.x, bg_offy_dn}}};
                    rect.ClipWith(clip_rect);
                    if (rect.Overlaps(clip_rect)) do draw_window.DrawList.AddRectFilled(rect.Min, rect.Max, bg_color);
                    rect_pos.x = draw_pos.x - draw_scroll.x;
                }
                rect_pos.y += g.FontSize;
            }
        }

        // We test for 'buf_display_max_length' as a way to avoid some pathological cases (e.g. single-line 1 MB string) which would make ImDrawList crash.
        // FIXME-OPT: Multiline could submit a smaller amount of contents to AddText() since we already iterated through it.
        if (is_multiline || (buf_display_end - buf_display) < buf_display_max_length)
        {
            col := GetColorU32(is_displaying_hint ? ImGuiCol.TextDisabled : ImGuiCol.Text);
            draw_window.DrawList.AddText(g.Font, g.FontSize, draw_pos - draw_scroll, col, buf_display, buf_display_end, 0.0, is_multiline ? nil : &clip_rect);
        }

        // Draw blinking cursor
        if (render_cursor)
        {
            state.CursorAnim += io.DeltaTime;
            cursor_is_visible := (!g.IO.ConfigInputTextCursorBlink) || (state.CursorAnim <= 0.0) || ImFmod(state.CursorAnim, 1.20) <= 0.80;
            cursor_screen_pos := ImTrunc(draw_pos + cursor_offset - draw_scroll);
            cursor_screen_rect := ImRect{ _r = {cursor_screen_pos.x, cursor_screen_pos.y - g.FontSize + 0.5, cursor_screen_pos.x + 1.0, cursor_screen_pos.y - 1.5}};
            if (cursor_is_visible && cursor_screen_rect.Overlaps(clip_rect)) {
                draw_AddLine(window.DrawList, cursor_screen_rect.Min, cursor_screen_rect.GetBL(), GetColorU32(ImGuiCol.Text));
            }

            // Notify OS of text input position for advanced IME (-1 x offset so that Windows IME can cover our cursor. Bit of an extra nicety.)
            if (!is_readonly)
            {
                g.PlatformImeData.WantVisible = true;
                g.PlatformImeData.InputPos = ImVec2{cursor_screen_pos.x - 1.0, cursor_screen_pos.y - g.FontSize};
                g.PlatformImeData.InputLineHeight = g.FontSize;
                g.PlatformImeViewport = window.Viewport.ID;
            }
        }
    }
    else
    {
        // Render text only (no selection, no cursor)
        if (is_multiline) {
            text_size = ImVec2{inner_size.x, InputTextCalcTextLenAndLineCount(buf_display, &buf_display_end) * g.FontSize}; // We don't need width
        }
        else if (!is_displaying_hint && g.ActiveId == id) {
            buf_display_end = buf_display + state.TextLen;
        }
        else if (!is_displaying_hint) {
            buf_display_end = buf_display + strlen(buf_display);
        }

        if (is_multiline || (buf_display_end - buf_display) < buf_display_max_length)
        {
            // Find render position for right alignment
            if (.ElideLeft in flags) {
                draw_pos.x = ImMin(draw_pos.x, frame_bb.Max.x - CalcTextSize(buf_display, nil).x - style.FramePadding.x);
            }

            draw_scroll := /*state ? ImVec2{state.Scroll.x, 0.0} :*/ ImVec2{0.0, 0.0}; // Preserve scroll when inactive?
            col := GetColorU32(is_displaying_hint ? ImGuiCol.TextDisabled : ImGuiCol.Text);
            draw_window.DrawList.AddText(g.Font, g.FontSize, draw_pos - draw_scroll, col, buf_display, buf_display_end, 0.0, is_multiline ? nil : &clip_rect);
        }
    }

    if (is_password && !is_displaying_hint)   do PopFont()

    if (is_multiline)
    {
        // For focus requests to work on our multiline we need to ensure our child ItemAdd() call specifies the ImGuiItemFlags_Inputable (see #4761, #7870)...
        Dummy(ImVec2{text_size.x, text_size.y + style.FramePadding.y});
        g.NextItemData.ItemFlags |= ImGuiItemFlags_Inputable | ImGuiItemFlags_NoTabStop;
        EndChild();
        item_data_backup.StatusFlags |= (.HoveredWindow in g.LastItemData.StatusFlags);

        // ...and then we need to undo the group overriding last item data, which gets a bit messy as EndGroup() tries to forward scrollbar being active...
        // FIXME: This quite messy/tricky, should attempt to get rid of the child window.
        EndGroup();
        if (g.LastItemData.ID == 0 || g.LastItemData.ID != GetWindowScrollbarID(draw_window, ImGuiAxis.Y))
        {
            g.LastItemData.ID = id;
            g.LastItemData.ItemFlags = item_data_backup.ItemFlags;
            g.LastItemData.StatusFlags = item_data_backup.StatusFlags;
        }
    }
    if (state)   do state.TextSrc = nil

    // Log as text
    if (g.LogEnabled && (!is_password || is_displaying_hint))
    {
        LogSetNextTextDecoration("{", "}");
        LogRenderedText(&draw_pos, buf_display, buf_display_end);
    }

    if (label_size.x > 0) {
        RenderText(ImVec2{frame_bb.Max.x + style.ItemInnerSpacing.x, frame_bb.Min.y + style.FramePadding.y}, label);
    }

    if (value_changed)   do MarkItemEdited(id)

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags | ImGuiItemStatusFlags_Inputable);
    if ((.EnterReturnsTrue in flags) != 0)   do return validated
    else do return value_changed;
}

DebugNodeInputTextState :: proc(state : ^ImGuiInputTextState)
{
when !(IMGUI_DISABLE_DEBUG_TOOLS) {
    g := GImGui;
    STB_TexteditState* stb_state = state.Stb;
    StbUndoState* undo_state = &stb_state.undostate;
    Text("ID: 0x%08X, ActiveID: 0x%08X", state.ID, g.ActiveId);
    DebugLocateItemOnHover(state.ID);
    Text("CurLenA: %d, Cursor: %d, Selection: %d..%d", state.TextLen, stb_state.cursor, stb_state.select_start, stb_state.select_end);
    Text("BufCapacityA: %d", state.BufCapacity);
    Text("(Internal Buffer: TextA Size: %d, Capacity: %d)", state.TextA.Size, state.TextA.Capacity);
    Text("has_preferred_x: %d (%.2)", stb_state.has_preferred_x, stb_state.preferred_x);
    Text("undo_point: %d, redo_point: %d, undo_char_point: %d, redo_char_point: %d", undo_state.undo_point, undo_state.redo_point, undo_state.undo_char_point, undo_state.redo_char_point);
    if (BeginChild("undopoints", ImVec2{0.0, GetTextLineHeight() * 10}, ImGuiChildFlags_Borders | ImGuiChildFlags_ResizeY)) // Visualize undo state
    {
        PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2{0, 0});
        for n := 0; n < IMSTB_TEXTEDIT_UNDOSTATECOUNT; n += 1
        {
            undo_rec := &undo_state.undo_rec[n];
            undo_rec_type := (n < undo_state.undo_point) ? 'u' : (n >= undo_state.redo_point) ? 'r' : ' ';
            if (undo_rec_type == ' ')   do BeginDisabled()
            buf_preview_len := (undo_rec_type != ' ' && undo_rec.char_storage != -1) ? undo_rec.insert_length : 0;
            buf_preview_str := undo_state.undo_char + undo_rec.char_storage;
            Text("%c [%02d] where %03d, insert %03d, delete %03d, char_storage %03d \"%.*s\"",
                undo_rec_type, n, undo_rec.where_, undo_rec.insert_length, undo_rec.delete_length, undo_rec.char_storage, buf_preview_len, buf_preview_str);
            if (undo_rec_type == ' ')   do EndDisabled()
        }
        PopStyleVar();
    }
    EndChild();
} else {
    _ = state;
}
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: ColorEdit, ColorPicker, ColorButton, etc.
//-------------------------------------------------------------------------
// - ColorEdit3()
// - ColorEdit4()
// - ColorPicker3()
// - RenderColorRectWithAlphaCheckerboard() [Internal]
// - ColorPicker4()
// - ColorButton()
// - SetColorEditOptions()
// - ColorTooltip() [Internal]
// - ColorEditOptionsPopup() [Internal]
// - ColorPickerOptionsPopup() [Internal]
//-------------------------------------------------------------------------

ColorEdit3 :: proc(label : string, col : [3]f32, flags : ImGuiColorEditFlags = {}) -> bool
{
    return ColorEdit4(label, col, flags | ImGuiColorEditFlags_NoAlpha);
}

ColorEditRestoreH :: proc(col : ^f32, H : ^f32)
{
    g := GImGui;
    assert(g.ColorEditCurrentID != 0);
    if (g.ColorEditSavedID != g.ColorEditCurrentID || g.ColorEditSavedColor != ColorConvertFloat4ToU32(ImVec4{col[0], col[1], col[2], 0}))   do return
    H^ = g.ColorEditSavedHue;
}

// ColorEdit supports RGB and HSV inputs. In case of RGB input resulting color may have undefined hue and/or saturation.
// Since widget displays both RGB and HSV values we must preserve hue and saturation to prevent these values resetting.
ColorEditRestoreHS :: proc(col : ^f32, H : ^f32, S : ^f32, V : ^f32)
{
    g := GImGui;
    assert(g.ColorEditCurrentID != 0);
    if (g.ColorEditSavedID != g.ColorEditCurrentID || g.ColorEditSavedColor != ColorConvertFloat4ToU32(ImVec4{col[0], col[1], col[2], 0}))   do return

    // When S == 0, H is undefined.
    // When H == 1 it wraps around to 0.
    if (S^ == 0.0 || (H^ == 0.0 && g.ColorEditSavedHue == 1))   do H^ = g.ColorEditSavedHue

    // When V == 0, S is undefined.
    if (V^ == 0.0)   do S^ = g.ColorEditSavedSat
}

// Edit colors components (each component in 0.0f..1.0f range).
// See enum ImGuiColorEditFlags_ for available options. e.g. Only access 3 floats if ImGuiColorEditFlags_NoAlpha flag is set.
// With typical options: Left-click on color square to open color picker. Right-click to open option menu. CTRL-Click over input fields to edit them and TAB to go to next item.
ColorEdit4 :: proc(label : string, col : [4]f32, flags : ImGuiColorEditFlags) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    style := &g.Style;
    square_sz := GetFrameHeight();
    label_display_end := FindRenderedText(label);
    w_full := CalcItemWidth();
    g.NextItemData.ClearFlags();

    BeginGroup();
    PushID(label);
    set_current_color_edit_id := (g.ColorEditCurrentID == 0);
    if (set_current_color_edit_id) do g.ColorEditCurrentID = window.IDStack.back();

    // If we're not showing any slider there's no point in doing any HSV conversions
    flags_untouched := flags;
    if (.NoInputs in flags) {
        flags = (flags & (~ImGuiColorEditFlags_DisplayMask_)) | ImGuiColorEditFlags_DisplayRGB | ImGuiColorEditFlags_NoOptions;
    }

    // Context menu: display and modify options (before defaults are applied)
    if (!(.NoOptions in flags)) {
        ColorEditOptionsPopup(col, flags);
    }

    // Read stored options
    if (!(flags & ImGuiColorEditFlags_DisplayMask_)) {
        flags |= (g.ColorEditOptions & ImGuiColorEditFlags_DisplayMask_);
    }
    if (!(flags & ImGuiColorEditFlags_DataTypeMask_)) {
        flags |= (g.ColorEditOptions & ImGuiColorEditFlags_DataTypeMask_);
    }
    if (!(flags & ImGuiColorEditFlags_PickerMask_)) {
        flags |= (g.ColorEditOptions & ImGuiColorEditFlags_PickerMask_);
    }
    if (!(flags & ImGuiColorEditFlags_InputMask_)) {
        flags |= (g.ColorEditOptions & ImGuiColorEditFlags_InputMask_);
    }
    flags |= (g.ColorEditOptions & ~(ImGuiColorEditFlags_DisplayMask_ | ImGuiColorEditFlags_DataTypeMask_ | ImGuiColorEditFlags_PickerMask_ | ImGuiColorEditFlags_InputMask_));
    assert(math.is_power_of_two(flags & ImGuiColorEditFlags_DisplayMask_)); // Check that only 1 is selected
    assert(math.is_power_of_two(flags & ImGuiColorEditFlags_InputMask_));   // Check that only 1 is selected

    alpha := (.NoAlpha not_in flags);
    hdr := (.HDR in flags)
    components := alpha ? 4 : 3;
    w_button := (.NoSmallPreview in flags) ? 0.0 : (square_sz + style.ItemInnerSpacing.x);
    w_inputs := ImMax(w_full - w_button, 1.0);
    w_full = w_inputs + w_button;

    // Convert to the formats we need
    f := [4]f32 { col[0], col[1], col[2], alpha ? col[3] : 1.0 };
    if ((.InputHSV in flags) && (.DisplayRGB in flags)) {
        ColorConvertHSVtoRGB(f[0], f[1], f[2], f[0], f[1], f[2]);
    }
    else if ((.InputRGB in flags) && (.DisplayHSV in flags))
    {
        // Hue is lost when converting from grayscale rgb (saturation=0). Restore it.
        ColorConvertRGBtoHSV(f[0], f[1], f[2], f[0], f[1], f[2]);
        ColorEditRestoreHS(col, &f[0], &f[1], &f[2]);
    }
    i := [4]i32 { IM_F32_TO_INT8_UNBOUND(f[0]), IM_F32_TO_INT8_UNBOUND(f[1]), IM_F32_TO_INT8_UNBOUND(f[2]), IM_F32_TO_INT8_UNBOUND(f[3]) };

    value_changed := false;
    value_changed_as_float := false;

    pos := window.DC.CursorPos;
    inputs_offset_x := (style.ColorButtonPosition == .Left) ? w_button : 0.0;
    window.DC.CursorPos.x = pos.x + inputs_offset_x;

    if ((flags & (ImGuiColorEditFlags_DisplayRGB | ImGuiColorEditFlags_DisplayHSV)) != 0 && (.NoInputs not_in flags))
    {
        // RGB/HSV 0..255 Sliders
        w_items := w_inputs - style.ItemInnerSpacing.x * (components - 1);

        hide_prefix := (math.trunc(w_items / components) <= CalcTextSize((.Float in flags) ? "M:0.000" : "M:000").x);
        @(static) ids := [4]string { "##X", "##Y", "##Z", "##W" };
        @(static) fmt_table_int := [3][4]string {
            {   "%3d",   "%3d",   "%3d",   "%3d" }, // Short display
            { "R:%3d", "G:%3d", "B:%3d", "A:%3d" }, // Long display for RGBA
            { "H:%3d", "S:%3d", "V:%3d", "A:%3d" }  // Long display for HSVA
        };
        @(static) fmt_table_float := [3][4]string {
            {   "%0.3",   "%0.3",   "%0.3",   "%0.3" }, // Short display
            { "R:%0.3", "G:%0.3", "B:%0.3", "A:%0.3" }, // Long display for RGBA
            { "H:%0.3", "S:%0.3", "V:%0.3", "A:%0.3" }  // Long display for HSVA
        };
        fmt_idx := hide_prefix ? 0 : (.DisplayHSV in flags) ? 2 : 1;

        prev_split := 0.0;
        for n := 0; n < components; n += 1
        {
            if (n > 0) do SameLine(0, style.ItemInnerSpacing.x);
            next_split := math.trunc(w_items * (n + 1) / components);
            SetNextItemWidth(ImMax(next_split - prev_split, 1.0));
            prev_split = next_split;

            // FIXME: When ImGuiColorEditFlags_HDR flag is passed HS values snap in weird ways when SV values go below 0.
            if (.Float in flags)
            {
                value_changed |= DragFloat(ids[n], &f[n], 1.0 / 255.0, 0.0, hdr ? 0.0 : 1.0, fmt_table_float[fmt_idx][n]);
                value_changed_as_float |= value_changed;
            }
            else
            {
                value_changed |= DragInt(ids[n], &i[n], 1.0, 0, hdr ? 0 : 255, fmt_table_int[fmt_idx][n]);
            }
            if (!(.NoOptions in flags)) {
                OpenPopupOnItemClick("context", ImGuiPopupFlags_MouseButtonRight);
            }
        }
    }
    else if ((.DisplayHex in flags) != 0 && (.NoInputs not_in flags))
    {
        // RGB Hexadecimal Input
        buf : [64]u8
        if (alpha) do ImFormatString(buf, len(buf), "#%02X%02X%02X%02X", ImClamp(i[0], 0, 255), ImClamp(i[1], 0, 255), ImClamp(i[2], 0, 255), ImClamp(i[3], 0, 255));
        else do ImFormatString(buf, len(buf), "#%02X%02X%02X", ImClamp(i[0], 0, 255), ImClamp(i[1], 0, 255), ImClamp(i[2], 0, 255));
        SetNextItemWidth(w_inputs);
        if (InputText("##Text", buf, len(buf), ImGuiInputTextFlags_CharsUppercase))
        {
            value_changed = true;
            p :[^]u8 = buf;
            for (p[0] == '#' || ImCharIsBlankA(p[0])) do p = p[1:];
            i[0] = 0
            i[1] = 0
            i[2] = 0;
            i[3] = 0xFF; // alpha default to 255 is not parsed by scanf (e.g. inputting #FFFFFF omitting alpha)
            r : i32
            if (alpha) do r = sscanf(p, "%02X%02X%02X%02X", cast(^u32)&i[0], cast(^u32)&i[1], cast(^u32)&i[2], cast(^u32)&i[3]); // Treat at unsigned (%X is unsigned)
            else do r = sscanf(p, "%02X%02X%02X", cast(^u32)&i[0], cast(^u32)&i[1], cast(^u32)&i[2]);
            _ = r; // Fixes C6031: Return value ignored: 'sscanf'.
        }
        if (!(.NoOptions in flags)) {
            OpenPopupOnItemClick("context", ImGuiPopupFlags_MouseButtonRight);
        }
    }

    picker_active_window := nil;
    if (!(.NoSmallPreview in flags))
    {
        button_offset_x := ((.NoInputs in flags) || (style.ColorButtonPosition == .Left)) ? 0.0 : w_inputs + style.ItemInnerSpacing.x;
        window.DC.CursorPos = ImVec2{pos.x + button_offset_x, pos.y};

        col_v4 := ImVec4(col[0], col[1], col[2], alpha ? col[3] : 1.0);
        if (ColorButton("##ColorButton", col_v4, flags))
        {
            if (!(.NoPicker in flags))
            {
                // Store current color and open a picker
                g.ColorPickerRef = col_v4;
                OpenPopup("picker");
                SetNextWindowPos(g.LastItemData.Rect.GetBL() + ImVec2{0.0, style.ItemSpacing.y});
            }
        }
        if (!(.NoOptions in flags)) {
            OpenPopupOnItemClick("context", ImGuiPopupFlags_MouseButtonRight);
        }

        if (BeginPopup("picker"))
        {
            if (g.CurrentWindow.BeginCount == 1)
            {
                picker_active_window = g.CurrentWindow;
                if (label != label_display_end)
                {
                    TextEx(label, label_display_end);
                    Spacing();
                }
                picker_flags_to_forward := ImGuiColorEditFlags_DataTypeMask_ | ImGuiColorEditFlags_PickerMask_ | ImGuiColorEditFlags_InputMask_ | ImGuiColorEditFlags_HDR | ImGuiColorEditFlags_NoAlpha | ImGuiColorEditFlags_AlphaBar;
                picker_flags := (flags_untouched & picker_flags_to_forward) | ImGuiColorEditFlags_DisplayMask_ | ImGuiColorEditFlags_NoLabel | ImGuiColorEditFlags_AlphaPreviewHalf;
                SetNextItemWidth(square_sz * 12.0); // Use 256 + bar sizes?
                value_changed |= ColorPicker4("##picker", col, picker_flags, &g.ColorPickerRef.x);
            }
            EndPopup();
        }
    }

    if (label != label_display_end && !(.NoLabel in flags))
    {
        // Position not necessarily next to last submitted button (e.g. if style.ColorButtonPosition == .Left),
        // but we need to use SameLine() to setup baseline correctly. Might want to refactor SameLine() to simplify this.
        SameLine(0.0, style.ItemInnerSpacing.x);
        window.DC.CursorPos.x = pos.x + ((.NoInputs in flags) ? w_button : w_full + style.ItemInnerSpacing.x);
        TextEx(label, label_display_end);
    }

    // Convert back
    if (value_changed && picker_active_window == nil)
    {
        if (!value_changed_as_float) {
            for n := 0; n < 4; n += 1 {
                f[n] = i[n] / 255.0;
            }
        }
        if ((.DisplayHSV in flags) && (.InputRGB in flags))
        {
            g.ColorEditSavedHue = f[0];
            g.ColorEditSavedSat = f[1];
            ColorConvertHSVtoRGB(f[0], f[1], f[2], f[0], f[1], f[2]);
            g.ColorEditSavedID = g.ColorEditCurrentID;
            g.ColorEditSavedColor = ColorConvertFloat4ToU32(ImVec4{f[0], f[1], f[2], 0});
        }
        if ((.DisplayRGB in flags) && (.InputHSV in flags)) {
            ColorConvertRGBtoHSV(f[0], f[1], f[2], f[0], f[1], f[2]);
        }

        col[0] = f[0];
        col[1] = f[1];
        col[2] = f[2];
        if (alpha)   do col[3] = f[3]
    }

    if (set_current_color_edit_id)   do g.ColorEditCurrentID = 0
    PopID();
    EndGroup();

    // Drag and Drop Target
    // NB: The flag test is merely an optional micro-optimization, BeginDragDropTarget() does the same test.
    if ((.HoveredRect in g.LastItemData.StatusFlags) && !(.ReadOnly in g.LastItemData.ItemFlags) && !(.NoDragDrop in flags) && BeginDragDropTarget())
    {
        accepted_drag_drop := false;
        if payload := AcceptDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_3F); payload != nil
        {
            memcpy(cast(^f32)col, payload.Data, size_of(f32) * 3); // Preserve alpha if any //-V512 //-V1086
            value_changed = true
            accepted_drag_drop = true;
        }
        if payload := AcceptDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_4F); payload != nil
        {
            memcpy(cast(^f32)col, payload.Data, size_of(f32) * components);
            value_changed = true
            accepted_drag_drop = true;
        }

        // Drag-drop payloads are always RGB
        if (accepted_drag_drop && (.InputHSV in flags)) {
            ColorConvertRGBtoHSV(col[0], col[1], col[2], col[0], col[1], col[2]);
        }
        EndDragDropTarget();
    }

    // When picker is being actively used, use its active id so IsItemActive() will function on ColorEdit4().
    if (picker_active_window && g.ActiveId != 0 && g.ActiveIdWindow == picker_active_window) {
        g.LastItemData.ID = g.ActiveId;
    }

    if (value_changed && g.LastItemData.ID != 0) { // In case of ID collision, the second EndGroup() won't catch g.ActiveId
        MarkItemEdited(g.LastItemData.ID);
    }

    return value_changed;
}

ColorPicker3 :: proc(label : string, col : [3]f32, flags : ImGuiColorEditFlags = {}) -> bool
{
    col4 := [4]f32 { col[0], col[1], col[2], 1.0 };
    if (!ColorPicker4(label, col4, flags | ImGuiColorEditFlags_NoAlpha))   do return false
    col[0] = col4[0]; col[1] = col4[1]; col[2] = col4[2];
    return true;
}

// Helper for ColorPicker4()
RenderArrowsForVerticalBar :: proc(draw_list : ^ImDrawList, pos : ImVec2, half_sz : ImVec2, bar_w : f32, alpha : f32)
{
    alpha8 := IM_F32_TO_INT8_SAT(alpha);
    RenderArrowPointingAt(draw_list, ImVec2{pos.x + half_sz.x + 1,         pos.y}, ImVec2{half_sz.x + 2, half_sz.y + 1}, .Right, IM_COL32(0,0,0,alpha8));
    RenderArrowPointingAt(draw_list, ImVec2{pos.x + half_sz.x,             pos.y}, half_sz,                              .Right, IM_COL32(255,255,255,alpha8));
    RenderArrowPointingAt(draw_list, ImVec2{pos.x + bar_w - half_sz.x - 1, pos.y}, ImVec2{half_sz.x + 2, half_sz.y + 1}, .Left,  IM_COL32(0,0,0,alpha8));
    RenderArrowPointingAt(draw_list, ImVec2{pos.x + bar_w - half_sz.x,     pos.y}, half_sz,                              .Left,  IM_COL32(255,255,255,alpha8));
}

// Note: ColorPicker4() only accesses 3 floats if ImGuiColorEditFlags_NoAlpha flag is set.
// (In C++ the 'float col[4]' notation for a function argument is equivalent to 'float* col', we only specify a size to facilitate understanding of the code.)
// FIXME: we adjust the big color square height based on item width, which may cause a flickering feedback loop (if automatic height makes a vertical scrollbar appears, affecting automatic width..)
// FIXME: this is trying to be aware of style.Alpha but not fully correct. Also, the color wheel will have overlapping glitches with (style.Alpha < 1.0)
ColorPicker4 :: proc(label : string, col : [4]f32, flags : ImGuiColorEditFlags = {}, ref_col : ^f32 = nil) -> bool
{
    g := GImGui;
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    draw_list := window.DrawList;
    style := &g.Style;
    io := &g.IO;

    width := CalcItemWidth();
    is_readonly := ((g.NextItemData.ItemFlags | g.CurrentItemFlags) & ImGuiItemFlags_ReadOnly) != 0;
    g.NextItemData.ClearFlags();

    PushID(label);
    set_current_color_edit_id := (g.ColorEditCurrentID == 0);
    if (set_current_color_edit_id) {
        g.ColorEditCurrentID = window.IDStack.back();
    }
    BeginGroup();

    if (!(.NoSidePreview in flags)) {
        flags |= ImGuiColorEditFlags_NoSmallPreview;
    }

    // Context menu: display and store options.
    if (!(.NoOptions in flags)) {
        ColorPickerOptionsPopup(col, flags);
    }

    // Read stored options
    if (!(flags & ImGuiColorEditFlags_PickerMask_)) {
        flags |= ((g.ColorEditOptions & ImGuiColorEditFlags_PickerMask_) ? g.ColorEditOptions : ImGuiColorEditFlags_DefaultOptions_) & ImGuiColorEditFlags_PickerMask_;
    }
    if (!(flags & ImGuiColorEditFlags_InputMask_)) {
        flags |= ((g.ColorEditOptions & ImGuiColorEditFlags_InputMask_) ? g.ColorEditOptions : ImGuiColorEditFlags_DefaultOptions_) & ImGuiColorEditFlags_InputMask_;
    }
    assert(math.is_power_of_two(flags & ImGuiColorEditFlags_PickerMask_)); // Check that only 1 is selected
    assert(math.is_power_of_two(flags & ImGuiColorEditFlags_InputMask_));  // Check that only 1 is selected
    if (!(.NoOptions in flags)) {
        flags |= (g.ColorEditOptions & ImGuiColorEditFlags_AlphaBar);
    }

    // Setup
    components := (.NoAlpha in flags) ? 3 : 4;
    alpha_bar := (.AlphaBar in flags) && !(.NoAlpha in flags);
    picker_pos := window.DC.CursorPos;
    square_sz := GetFrameHeight();
    bars_width := square_sz; // Arbitrary smallish width of Hue/Alpha picking bars
    sv_picker_size := ImMax(bars_width * 1, width - (alpha_bar ? 2 : 1) * (bars_width + style.ItemInnerSpacing.x)); // Saturation/Value picking box
    bar0_pos_x := picker_pos.x + sv_picker_size + style.ItemInnerSpacing.x;
    bar1_pos_x := bar0_pos_x + bars_width + style.ItemInnerSpacing.x;
    bars_triangles_half_sz := math.trunc(bars_width * 0.20);

    backup_initial_col : [4]f32
    memcpy(backup_initial_col, col, components * size_of(f32));

    wheel_thickness := sv_picker_size * 0.08;
    wheel_r_outer := sv_picker_size * 0.50;
    wheel_r_inner := wheel_r_outer - wheel_thickness;
    wheel_center := ImVec2(picker_pos.x + (sv_picker_size + bars_width)*0.5, picker_pos.y + sv_picker_size * 0.5);

    // Note: the triangle is displayed rotated with triangle_pa pointing to Hue, but most coordinates stays unrotated for logic.
    triangle_r := wheel_r_inner - (i32)(sv_picker_size * 0.027);
    triangle_pa := ImVec2{triangle_r, 0.0}; // Hue point.
    triangle_pb := ImVec2{triangle_r * -0.5, triangle_r * -0.866025}; // Black point.
    triangle_pc := ImVec2{triangle_r * -0.5, triangle_r * +0.866025}; // White point.

    H := col[0]
    S := col[1]
    V := col[2]
    R := col[0]
    G := col[1]
    B := col[2]
    if (.InputRGB in flags)
    {
        // Hue is lost when converting from grayscale rgb (saturation=0). Restore it.
        ColorConvertRGBtoHSV(R, G, B, H, S, V);
        ColorEditRestoreHS(col, &H, &S, &V);
    }
    else if (.InputHSV in flags)
    {
        ColorConvertHSVtoRGB(H, S, V, R, G, B);
    }

    value_changed := false;
    value_changed_h := false
    value_changed_sv := false;

    PushItemFlag(ImGuiItemFlags_NoNav, true);
    if (.PickerHueWheel in flags)
    {
        // Hue wheel + SV triangle logic
        InvisibleButton("hsv", ImVec2{sv_picker_size + style.ItemInnerSpacing.x + bars_width, sv_picker_size});
        if (IsItemActive() && !is_readonly)
        {
            initial_off := g.IO.MouseClickedPos[0] - wheel_center;
            current_off := g.IO.MousePos - wheel_center;
            initial_dist2 := ImLengthSqr(initial_off);
            if (initial_dist2 >= (wheel_r_inner - 1) * (wheel_r_inner - 1) && initial_dist2 <= (wheel_r_outer + 1) * (wheel_r_outer + 1))
            {
                // Interactive with Hue wheel
                H = ImAtan2(current_off.y, current_off.x) / IM_PI * 0.5;
                if (H < 0.0)   do H += 1.0
                value_changed_h = true;
                value_changed = true
            }
            cos_hue_angle := math.cos(-H * 2.0 * IM_PI);
            sin_hue_angle := math.sin(-H * 2.0 * IM_PI);
            if (ImTriangleContainsPoint(triangle_pa, triangle_pb, triangle_pc, ImRotate(initial_off, cos_hue_angle, sin_hue_angle)))
            {
                // Interacting with SV triangle
                current_off_unrotated := ImRotate(current_off, cos_hue_angle, sin_hue_angle);
                if (!ImTriangleContainsPoint(triangle_pa, triangle_pb, triangle_pc, current_off_unrotated)) {
                    current_off_unrotated = ImTriangleClosestPoint(triangle_pa, triangle_pb, triangle_pc, current_off_unrotated);
                }
                uu, vv, ww : f32
                ImTriangleBarycentricCoords(triangle_pa, triangle_pb, triangle_pc, current_off_unrotated, uu, vv, ww);
                V = ImClamp(1.0 - vv, 0.0001, 1.0);
                S = ImClamp(uu / V, 0.0001, 1.0);
                value_changed = true
                value_changed_sv = true;
            }
        }
        if (!(.NoOptions in flags)) {
            OpenPopupOnItemClick("context", ImGuiPopupFlags_MouseButtonRight);
        }
    }
    else if (.PickerHueBar in flags)
    {
        // SV rectangle logic
        InvisibleButton("sv", ImVec2{sv_picker_size, sv_picker_size});
        if (IsItemActive() && !is_readonly)
        {
            S = ImSaturate((io.MousePos.x - picker_pos.x) / (sv_picker_size - 1));
            V = 1.0 - ImSaturate((io.MousePos.y - picker_pos.y) / (sv_picker_size - 1));
            ColorEditRestoreH(col, &H); // Greatly reduces hue jitter and reset to 0 when hue == 255 and color is rapidly modified using SV square.
            value_changed = true
            value_changed_sv = true;
        }
        if (!(.NoOptions in flags)) {
            OpenPopupOnItemClick("context", ImGuiPopupFlags_MouseButtonRight);
        }

        // Hue bar logic
        SetCursorScreenPos(ImVec2{bar0_pos_x, picker_pos.y});
        InvisibleButton("hue", ImVec2{bars_width, sv_picker_size});
        if (IsItemActive() && !is_readonly)
        {
            H = ImSaturate((io.MousePos.y - picker_pos.y) / (sv_picker_size - 1));
            value_changed = true
            value_changed_h = true;
        }
    }

    // Alpha bar logic
    if (alpha_bar)
    {
        SetCursorScreenPos(ImVec2{bar1_pos_x, picker_pos.y});
        InvisibleButton("alpha", ImVec2{bars_width, sv_picker_size});
        if (IsItemActive())
        {
            col[3] = 1.0 - ImSaturate((io.MousePos.y - picker_pos.y) / (sv_picker_size - 1));
            value_changed = true;
        }
    }
    PopItemFlag(); // ImGuiItemFlags_NoNav

    if (!(.NoSidePreview in flags))
    {
        SameLine(0, style.ItemInnerSpacing.x);
        BeginGroup();
    }

    if (!(.NoLabel in flags))
    {
        label_display_end := FindRenderedText(label);
        if (label != label_display_end)
        {
            if ((.NoSidePreview in flags)) {
                SameLine(0, style.ItemInnerSpacing.x);
            }
            TextEx(label, label_display_end);
        }
    }

    if (!(.NoSidePreview in flags))
    {
        PushItemFlag(ImGuiItemFlags_NoNavDefaultFocus, true);
        col_v4 := ImVec4(col[0], col[1], col[2], (.NoAlpha in flags) ? 1.0 : col[3]);
        if ((.NoLabel in flags))   do Text("Current")

        sub_flags_to_forward := ImGuiColorEditFlags_InputMask_ | ImGuiColorEditFlags_HDR | ImGuiColorEditFlags_AlphaPreview | ImGuiColorEditFlags_AlphaPreviewHalf | ImGuiColorEditFlags_NoTooltip;
        ColorButton("##current", col_v4, (.forward in flags), ImVec2{square_sz * 3, square_sz * 2});
        if (ref_col != nil)
        {
            Text("Original");
            ref_col_v4 := ImVec4(ref_col[0], ref_col[1], ref_col[2], (.NoAlpha in flags) ? 1.0 : ref_col[3]);
            if (ColorButton("##original", ref_col_v4, (.forward in flags), ImVec2{square_sz * 3, square_sz * 2}))
            {
                memcpy(col, ref_col, components * size_of(f32));
                value_changed = true;
            }
        }
        PopItemFlag();
        EndGroup();
    }

    // Convert back color to RGB
    if (value_changed_h || value_changed_sv)
    {
        if (.InputRGB in flags)
        {
            ColorConvertHSVtoRGB(H, S, V, col[0], col[1], col[2]);
            g.ColorEditSavedHue = H;
            g.ColorEditSavedSat = S;
            g.ColorEditSavedID = g.ColorEditCurrentID;
            g.ColorEditSavedColor = ColorConvertFloat4ToU32(ImVec4{col[0], col[1], col[2], 0});
        }
        else if (.InputHSV in flags)
        {
            col[0] = H;
            col[1] = S;
            col[2] = V;
        }
    }

    // R,G,B and H,S,V slider color editor
    value_changed_fix_hue_wrap := false;
    if ((.NoInputs not_in flags))
    {
        PushItemWidth((alpha_bar ? bar1_pos_x : bar0_pos_x) + bars_width - picker_pos.x);
        sub_flags_to_forward := ImGuiColorEditFlags_DataTypeMask_ | ImGuiColorEditFlags_InputMask_ | ImGuiColorEditFlags_HDR | ImGuiColorEditFlags_NoAlpha | ImGuiColorEditFlags_NoOptions | ImGuiColorEditFlags_NoTooltip | ImGuiColorEditFlags_NoSmallPreview | ImGuiColorEditFlags_AlphaPreview | ImGuiColorEditFlags_AlphaPreviewHalf;
        sub_flags := (.forward in flags) | ImGuiColorEditFlags_NoPicker;
        if (flags & ImGuiColorEditFlags_DisplayRGB || (flags & ImGuiColorEditFlags_DisplayMask_) == 0) {
            if (ColorEdit4("##rgb", col, sub_flags | ImGuiColorEditFlags_DisplayRGB))
            {
                // FIXME: Hackily differentiating using the DragInt (ActiveId != 0 && !ActiveIdAllowOverlap) vs. using the InputText or DropTarget.
                // For the later we don't want to run the hue-wrap canceling code. If you are well versed in HSV picker please provide your input! (See #2050)
                value_changed_fix_hue_wrap = (g.ActiveId != 0 && !g.ActiveIdAllowOverlap);
                value_changed = true;
            }
        }
        if (flags & ImGuiColorEditFlags_DisplayHSV || (flags & ImGuiColorEditFlags_DisplayMask_) == 0) {
            value_changed |= ColorEdit4("##hsv", col, sub_flags | ImGuiColorEditFlags_DisplayHSV);
        }
        if (flags & ImGuiColorEditFlags_DisplayHex || (flags & ImGuiColorEditFlags_DisplayMask_) == 0) {
            value_changed |= ColorEdit4("##hex", col, sub_flags | ImGuiColorEditFlags_DisplayHex);
        }
        PopItemWidth();
    }

    // Try to cancel hue wrap (after ColorEdit4 call), if any
    if (value_changed_fix_hue_wrap && (.InputRGB in flags))
    {
        new_H, new_S, new_V : f32
        ColorConvertRGBtoHSV(col[0], col[1], col[2], new_H, new_S, new_V);
        if (new_H <= 0 && H > 0)
        {
            if (new_V <= 0 && V != new_V) {
                ColorConvertHSVtoRGB(H, S, new_V <= 0 ? V * 0.5 : new_V, col[0], col[1], col[2]);
            }
            else if (new_S <= 0) {
                ColorConvertHSVtoRGB(H, new_S <= 0 ? S * 0.5 : new_S, new_V, col[0], col[1], col[2]);
            }
        }
    }

    if (value_changed)
    {
        if (.InputRGB in flags)
        {
            R = col[0];
            G = col[1];
            B = col[2];
            ColorConvertRGBtoHSV(R, G, B, H, S, V);
            ColorEditRestoreHS(col, &H, &S, &V);   // Fix local Hue as display below will use it immediately.
        }
        else if (.InputHSV in flags)
        {
            H = col[0];
            S = col[1];
            V = col[2];
            ColorConvertHSVtoRGB(H, S, V, R, G, B);
        }
    }

    style_alpha8 := IM_F32_TO_INT8_SAT(style.Alpha);
    col_black := IM_COL32(0,0,0,style_alpha8);
    col_white := IM_COL32(255,255,255,style_alpha8);
    col_midgrey := IM_COL32(128,128,128,style_alpha8);
    col_hues := [6 + 1]u32 { IM_COL32(255,0,0,style_alpha8), IM_COL32(255,255,0,style_alpha8), IM_COL32(0,255,0,style_alpha8), IM_COL32(0,255,255,style_alpha8), IM_COL32(0,0,255,style_alpha8), IM_COL32(255,0,255,style_alpha8), IM_COL32(255,0,0,style_alpha8) };

    hue_color_f := ImVec4(1, 1, 1, style.Alpha); ColorConvertHSVtoRGB(H, 1, 1, hue_color_f.x, hue_color_f.y, hue_color_f.z);
    hue_color32 := ColorConvertFloat4ToU32(hue_color_f);
    user_col32_striped_of_alpha := ColorConvertFloat4ToU32(ImVec4{R, G, B, style.Alpha}); // Important: this is still including the main rendering/style alpha!!

    sv_cursor_pos : ImVec2

    if (.PickerHueWheel in flags)
    {
        // Render Hue Wheel
        aeps := 0.5 / wheel_r_outer; // Half a pixel arc length in radians (2pi cancels out).
        segment_per_arc := ImMax(4, cast(i32) wheel_r_outer / 12);
        for n := 0; n < 6; n += 1
        {
            a0 := (n)     /6.0 * 2.0 * IM_PI - aeps;
            a1 := (n+1.0)/6.0 * 2.0 * IM_PI + aeps;
            vert_start_idx := len(draw_list.VtxBuffer);
            PathArcTo(draw_list, wheel_center, (wheel_r_inner + wheel_r_outer)*0.5, a0, a1, segment_per_arc);
            PathStroke(draw_list, col_white, 0, wheel_thickness);
            vert_end_idx := len(draw_list.VtxBuffer);

            // Paint colors over existing vertices
            gradient_p0 := ImVec2(wheel_center.x + math.cos(a0) * wheel_r_inner, wheel_center.y + math.sin(a0) * wheel_r_inner);
            gradient_p1 := ImVec2(wheel_center.x + math.cos(a1) * wheel_r_inner, wheel_center.y + math.sin(a1) * wheel_r_inner);
            ShadeVertsLinearColorGradientKeepAlpha(draw_list, vert_start_idx, vert_end_idx, gradient_p0, gradient_p1, col_hues[n], col_hues[n + 1]);
        }

        // Render Cursor + preview on Hue Wheel
        cos_hue_angle := math.cos(H * 2.0 * IM_PI);
        sin_hue_angle := math.sin(H * 2.0 * IM_PI);
        hue_cursor_pos := ImVec2(wheel_center.x + cos_hue_angle * (wheel_r_inner + wheel_r_outer) * 0.5, wheel_center.y + sin_hue_angle * (wheel_r_inner + wheel_r_outer) * 0.5);
        hue_cursor_rad := value_changed_h ? wheel_thickness * 0.65 : wheel_thickness * 0.55;
        hue_cursor_segments := draw_list._CalcCircleAutoSegmentCount(hue_cursor_rad); // Lock segment count so the +1 one matches others.
        draw_list.AddCircleFilled(hue_cursor_pos, hue_cursor_rad, hue_color32, hue_cursor_segments);
        draw_list.AddCircle(hue_cursor_pos, hue_cursor_rad + 1, col_midgrey, hue_cursor_segments);
        draw_list.AddCircle(hue_cursor_pos, hue_cursor_rad, col_white, hue_cursor_segments);

        // Render SV triangle (rotated according to hue)
        tra := wheel_center + ImRotate(triangle_pa, cos_hue_angle, sin_hue_angle);
        trb := wheel_center + ImRotate(triangle_pb, cos_hue_angle, sin_hue_angle);
        trc := wheel_center + ImRotate(triangle_pc, cos_hue_angle, sin_hue_angle);
        uv_white := GetFontTexUvWhitePixel();
        PrimReserve(draw_list, 3, 3);
        draw_list.PrimVtx(tra, uv_white, hue_color32);
        draw_list.PrimVtx(trb, uv_white, col_black);
        draw_list.PrimVtx(trc, uv_white, col_white);
        draw_list.AddTriangle(tra, trb, trc, col_midgrey, 1.5);
        sv_cursor_pos = ImLerp(ImLerp(trc, tra, ImSaturate(S)), trb, ImSaturate(1 - V));
    }
    else if (.PickerHueBar in flags)
    {
        // Render SV Square
        draw_list.AddRectFilledMultiColor(picker_pos, picker_pos + ImVec2{sv_picker_size, sv_picker_size}, col_white, hue_color32, hue_color32, col_white);
        draw_list.AddRectFilledMultiColor(picker_pos, picker_pos + ImVec2{sv_picker_size, sv_picker_size}, 0, 0, col_black, col_black);
        RenderFrameBorder(picker_pos, picker_pos + ImVec2{sv_picker_size, sv_picker_size}, 0.0);
        sv_cursor_pos.x = ImClamp(math.round(picker_pos.x + ImSaturate(S)     * sv_picker_size), picker_pos.x + 2, picker_pos.x + sv_picker_size - 2); // Sneakily prevent the circle to stick out too much
        sv_cursor_pos.y = ImClamp(math.round(picker_pos.y + ImSaturate(1 - V) * sv_picker_size), picker_pos.y + 2, picker_pos.y + sv_picker_size - 2);

        // Render Hue Bar
        for i := 0; i < 6; i += 1 {
            draw_list.AddRectFilledMultiColor(ImVec2{bar0_pos_x, picker_pos.y + i * (sv_picker_size / 6)}, ImVec2{bar0_pos_x + bars_width, picker_pos.y + (i + 1) * (sv_picker_size / 6)}, col_hues[i], col_hues[i], col_hues[i + 1], col_hues[i + 1]);
        }
        bar0_line_y := math.round(picker_pos.y + H * sv_picker_size);
        RenderFrameBorder(ImVec2{bar0_pos_x, picker_pos.y}, ImVec2{bar0_pos_x + bars_width, picker_pos.y + sv_picker_size}, 0.0);
        RenderArrowsForVerticalBar(draw_list, ImVec2{bar0_pos_x - 1, bar0_line_y}, ImVec2{bars_triangles_half_sz + 1, bars_triangles_half_sz}, bars_width + 2.0, style.Alpha);
    }

    // Render cursor/preview circle (clamp S/V within 0..1 range because floating points colors may lead HSV values to be out of range)
    sv_cursor_rad := value_changed_sv ? wheel_thickness * 0.55 : wheel_thickness * 0.40;
    sv_cursor_segments := draw_list._CalcCircleAutoSegmentCount(sv_cursor_rad); // Lock segment count so the +1 one matches others.
    draw_list.AddCircleFilled(sv_cursor_pos, sv_cursor_rad, user_col32_striped_of_alpha, sv_cursor_segments);
    draw_list.AddCircle(sv_cursor_pos, sv_cursor_rad + 1, col_midgrey, sv_cursor_segments);
    draw_list.AddCircle(sv_cursor_pos, sv_cursor_rad, col_white, sv_cursor_segments);

    // Render alpha bar
    if (alpha_bar)
    {
        alpha := ImSaturate(col[3]);
        bar1_bb := ImRect{ _r = {bar1_pos_x, picker_pos.y, bar1_pos_x + bars_width, picker_pos.y + sv_picker_size}};
        RenderColorRectWithAlphaCheckerboard(draw_list, bar1_bb.Min, bar1_bb.Max, 0, bar1_bb.GetWidth() / 2.0, ImVec2{0.0, 0.0});
        draw_list.AddRectFilledMultiColor(bar1_bb.Min, bar1_bb.Max, user_col32_striped_of_alpha, user_col32_striped_of_alpha, user_col32_striped_of_alpha & ~IM_COL32_A_MASK, user_col32_striped_of_alpha & ~IM_COL32_A_MASK);
        bar1_line_y := math.round(picker_pos.y + (1.0 - alpha) * sv_picker_size);
        RenderFrameBorder(bar1_bb.Min, bar1_bb.Max, 0.0);
        RenderArrowsForVerticalBar(draw_list, ImVec2{bar1_pos_x - 1, bar1_line_y}, ImVec2{bars_triangles_half_sz + 1, bars_triangles_half_sz}, bars_width + 2.0, style.Alpha);
    }

    EndGroup();

    if (value_changed && memcmp(backup_initial_col, col, components * size_of(f32)) == 0)   do value_changed = false
    if (value_changed && g.LastItemData.ID != 0) {// In case of ID collision, the second EndGroup() won't catch g.ActiveId
        MarkItemEdited(g.LastItemData.ID);
    }

    if (set_current_color_edit_id)   do g.ColorEditCurrentID = 0
    PopID();

    return value_changed;
}

// A little color square. Return true when clicked.
// FIXME: May want to display/ignore the alpha component in the color display? Yet show it in the tooltip.
// 'desc_id' is not called 'label' because we don't display it next to the button, but only in the tooltip.
// Note that 'col' may be encoded in HSV if ImGuiColorEditFlags_InputHSV is set.
// [forward declared comment]:
// display a color square/button, hover for details, return true when pressed.
ColorButton :: proc(desc_id : ^u8, col : ImVec4, flags : ImGuiColorEditFlags = {}, size_arg : ImVec2 = {}) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    id := GetID(window, desc_id);
    default_size := GetFrameHeight();
    size := ImVec2{size_arg.x == 0.0 ? default_size : size_arg.x, size_arg.y == 0.0 ? default_size : size_arg.y};
    bb := ImRect{ _v = {window.DC.CursorPos, window.DC.CursorPos + size}};
    ItemSize(bb, (size.y >= default_size) ? g.Style.FramePadding.y : 0.0);
    if (!ItemAdd(bb, id))   do return false

    hovered, held : bool
    pressed := ButtonBehavior(bb, id, &hovered, &held);

    if (.NoAlpha in flags) {
        flags &= ~(ImGuiColorEditFlags_AlphaPreview | ImGuiColorEditFlags_AlphaPreviewHalf);
    }

    col_rgb := col;
    if (.InputHSV in flags) {
        ColorConvertHSVtoRGB(col_rgb.x, col_rgb.y, col_rgb.z, col_rgb.x, col_rgb.y, col_rgb.z);
    }

    col_rgb_without_alpha := ImVec4(col_rgb.x, col_rgb.y, col_rgb.z, 1.0);
    grid_step := ImMin(size.x, size.y) / 2.99;
    rounding := ImMin(g.Style.FrameRounding, grid_step * 0.5);
    bb_inner := bb;
    off := 0.0;
    if ((.NoBorder not_in flags))
    {
        off = -0.75; // The border (using Col_FrameBg) tends to look off when color is near-opaque and rounding is enabled. This offset seemed like a good middle ground to reduce those artifacts.
        bb_inner.Expand(off);
    }
    if ((.AlphaPreviewHalf in flags) && col_rgb.w < 1.0)
    {
        mid_x := math.round((bb_inner.Min.x + bb_inner.Max.x) * 0.5);
        RenderColorRectWithAlphaCheckerboard(window.DrawList, ImVec2{bb_inner.Min.x + grid_step, bb_inner.Min.y}, bb_inner.Max, GetColorU32(col_rgb), grid_step, ImVec2{-grid_step + off, off}, rounding, ImDrawFlags_RoundCornersRight);
        AddRectFilled(window.DrawList, bb_inner.Min, ImVec2{mid_x, bb_inner.Max.y}, GetColorU32(col_rgb_without_alpha), rounding, ImDrawFlags_RoundCornersLeft);
    }
    else
    {
        // Because GetColorU32() multiplies by the global style Alpha and we don't want to display a checkerboard if the source code had no alpha
        col_source := (.AlphaPreview in flags) ? col_rgb : col_rgb_without_alpha;
        if (col_source.w < 1.0) {
            RenderColorRectWithAlphaCheckerboard(window.DrawList, bb_inner.Min, bb_inner.Max, GetColorU32(col_source), grid_step, ImVec2{off, off}, rounding);
        }
        else {
            AddRectFilled(window.DrawList, bb_inner.Min, bb_inner.Max, GetColorU32(col_source), rounding);
        }
    }
    RenderNavCursor(bb, id);
    if ((.NoBorder not_in flags))
    {
        if (g.Style.FrameBorderSize > 0.0) {
            RenderFrameBorder(bb.Min, bb.Max, rounding);
        }
        else {
            window.DrawList.AddRect(bb.Min, bb.Max, GetColorU32(ImGuiCol.FrameBg), rounding); // Color button are often in need of some sort of border
        }
    }

    // Drag and Drop Source
    // NB: The ActiveId test is merely an optional micro-optimization, BeginDragDropSource() does the same test.
    if (g.ActiveId == id && !(.NoDragDrop in flags) && BeginDragDropSource())
    {
        if (.NoAlpha in flags) {
            SetDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_3F, &col_rgb, size_of(f32) * 3, ImGuiCond_Once);
        }
        else {
            SetDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_4F, &col_rgb, size_of(f32) * 4, ImGuiCond_Once);
        }
        ColorButton(desc_id, col, flags);
        SameLine();
        TextEx("Color");
        EndDragDropSource();
    }

    // Tooltip
    if (!(.NoTooltip in flags) && hovered && IsItemHovered(ImGuiHoveredFlags_ForTooltip)) {
        ColorTooltip(desc_id, &col.x, flags & (ImGuiColorEditFlags_InputMask_ | ImGuiColorEditFlags_NoAlpha | ImGuiColorEditFlags_AlphaPreview | ImGuiColorEditFlags_AlphaPreviewHalf));
    }

    return pressed;
}

// Initialize/override default color options
// [forward declared comment]:
// initialize current options (generally on application startup) if you want to select a default format, picker type, etc. User will be able to change many settings, unless you pass the _NoOptions flag to your calls.
SetColorEditOptions :: proc(flags : ImGuiColorEditFlags)
{
    g := GImGui;
    if ((flags & ImGuiColorEditFlags_DisplayMask_) == 0) {
        flags |= ImGuiColorEditFlags_DefaultOptions_ & ImGuiColorEditFlags_DisplayMask_;
    }
    if ((flags & ImGuiColorEditFlags_DataTypeMask_) == 0) {
        flags |= ImGuiColorEditFlags_DefaultOptions_ & ImGuiColorEditFlags_DataTypeMask_;
    }
    if ((flags & ImGuiColorEditFlags_PickerMask_) == 0) {
        flags |= ImGuiColorEditFlags_DefaultOptions_ & ImGuiColorEditFlags_PickerMask_;
    }
    if ((flags & ImGuiColorEditFlags_InputMask_) == 0) {
        flags |= ImGuiColorEditFlags_DefaultOptions_ & ImGuiColorEditFlags_InputMask_;
    }
    assert(math.is_power_of_two(flags & ImGuiColorEditFlags_DisplayMask_));    // Check only 1 option is selected
    assert(math.is_power_of_two(flags & ImGuiColorEditFlags_DataTypeMask_));   // Check only 1 option is selected
    assert(math.is_power_of_two(flags & ImGuiColorEditFlags_PickerMask_));     // Check only 1 option is selected
    assert(math.is_power_of_two(flags & ImGuiColorEditFlags_InputMask_));      // Check only 1 option is selected
    g.ColorEditOptions = flags;
}

// Note: only access 3 floats if ImGuiColorEditFlags_NoAlpha flag is set.
ColorTooltip :: proc(text : ^u8, col : ^f32, flags : ImGuiColorEditFlags)
{
    g := GImGui;

    if (!BeginTooltipEx(ImGuiTooltipFlags_OverridePrevious, ImGuiWindowFlags_None))   do return
    text_end := text ? FindRenderedText(text, nil) : text;
    if (text_end > text)
    {
        TextEx(text, text_end);
        Separator();
    }

    sz := ImVec2{g.FontSize * 3 + g.Style.FramePadding.y * 2, g.FontSize * 3 + g.Style.FramePadding.y * 2};
    cf := ImVec4(col[0], col[1], col[2], (.NoAlpha in flags) ? 1.0 : col[3]);
    cr := IM_F32_TO_INT8_SAT(col[0]);
    cg := IM_F32_TO_INT8_SAT(col[1]);
    cb := IM_F32_TO_INT8_SAT(col[2]);
    ca := (.NoAlpha in flags) ? 255 : IM_F32_TO_INT8_SAT(col[3]);
    ColorButton("##preview", cf, (flags & (ImGuiColorEditFlags_InputMask_ | ImGuiColorEditFlags_NoAlpha | ImGuiColorEditFlags_AlphaPreview | ImGuiColorEditFlags_AlphaPreviewHalf)) | ImGuiColorEditFlags_NoTooltip, sz);
    SameLine();
    if ((.InputRGB in flags) || !(flags & ImGuiColorEditFlags_InputMask_))
    {
        if (.NoAlpha in flags) {
            Text("#%02X%02X%02X\nR: %d, G: %d, B: %d\n(%.3, %.3, %.3)", cr, cg, cb, cr, cg, cb, col[0], col[1], col[2]);
        }
        else {
            Text("#%02X%02X%02X%02X\nR:%d, G:%d, B:%d, A:%d\n(%.3, %.3, %.3, %.3)", cr, cg, cb, ca, cr, cg, cb, ca, col[0], col[1], col[2], col[3]);
        }
    }
    else if (.InputHSV in flags)
    {
        if (.NoAlpha in flags) {
            Text("H: %.3, S: %.3, V: %.3", col[0], col[1], col[2]);
        }
        else {
            Text("H: %.3, S: %.3, V: %.3, A: %.3", col[0], col[1], col[2], col[3]);
        }
    }
    EndTooltip();
}

ColorEditOptionsPopup :: proc(col : ^f32, flags : ImGuiColorEditFlags)
{
    allow_opt_inputs := !(flags & ImGuiColorEditFlags_DisplayMask_);
    allow_opt_datatype := !(flags & ImGuiColorEditFlags_DataTypeMask_);
    if ((!allow_opt_inputs && !allow_opt_datatype) || !BeginPopup("context"))   do return

    g := GImGui;
    PushItemFlag(ImGuiItemFlags_NoMarkEdited, true);
    opts := g.ColorEditOptions;
    if (allow_opt_inputs)
    {
        if (RadioButton("RGB", (opts & ImGuiColorEditFlags_DisplayRGB) != 0)) do opts = (opts & ~ImGuiColorEditFlags_DisplayMask_) | ImGuiColorEditFlags_DisplayRGB;
        if (RadioButton("HSV", (opts & ImGuiColorEditFlags_DisplayHSV) != 0)) do opts = (opts & ~ImGuiColorEditFlags_DisplayMask_) | ImGuiColorEditFlags_DisplayHSV;
        if (RadioButton("Hex", (opts & ImGuiColorEditFlags_DisplayHex) != 0)) do opts = (opts & ~ImGuiColorEditFlags_DisplayMask_) | ImGuiColorEditFlags_DisplayHex;
    }
    if (allow_opt_datatype)
    {
        if (allow_opt_inputs) do Separator();
        if (RadioButton("0..255",     (opts & ImGuiColorEditFlags_Uint8) != 0)) do opts = (opts & ~ImGuiColorEditFlags_DataTypeMask_) | ImGuiColorEditFlags_Uint8;
        if (RadioButton("0.00..1.00", (opts & ImGuiColorEditFlags_Float) != 0)) do opts = (opts & ~ImGuiColorEditFlags_DataTypeMask_) | ImGuiColorEditFlags_Float;
    }

    if (allow_opt_inputs || allow_opt_datatype)   do Separator()
    if (Button("Copy as..", ImVec2{-1, 0}))   do OpenPopup("Copy")
    if (BeginPopup("Copy"))
    {
        cr := IM_F32_TO_INT8_SAT(col[0])
        cg := IM_F32_TO_INT8_SAT(col[1])
        cb := IM_F32_TO_INT8_SAT(col[2])
        ca := (.NoAlpha in flags) ? 255 : IM_F32_TO_INT8_SAT(col[3]);
        buf : [64]u8
        ImFormatString(buf, len(buf), "(%.3f, %.3f, %.3f, %.3f)", col[0], col[1], col[2], (.NoAlpha in flags) ? 1.0 : col[3]);
        if (Selectable(buf))   do SetClipboardText(buf)
        ImFormatString(buf, len(buf), "(%d,%d,%d,%d)", cr, cg, cb, ca);
        if (Selectable(buf))   do SetClipboardText(buf)
        ImFormatString(buf, len(buf), "#%02X%02X%02X", cr, cg, cb);
        if (Selectable(buf))   do SetClipboardText(buf)
        if (!(.NoAlpha in flags))
        {
            ImFormatString(buf, len(buf), "#%02X%02X%02X%02X", cr, cg, cb, ca);
            if (Selectable(buf))   do SetClipboardText(buf)
        }
        EndPopup();
    }

    g.ColorEditOptions = opts;
    PopItemFlag();
    EndPopup();
}

ColorPickerOptionsPopup :: proc(ref_col : ^f32, flags : ImGuiColorEditFlags)
{
    allow_opt_picker := !(flags & ImGuiColorEditFlags_PickerMask_);
    allow_opt_alpha_bar := !(.NoAlpha in flags) && !(.AlphaBar in flags);
    if ((!allow_opt_picker && !allow_opt_alpha_bar) || !BeginPopup("context"))   do return

    g := GImGui;
    PushItemFlag(ImGuiItemFlags_NoMarkEdited, true);
    if (allow_opt_picker)
    {
        picker_size := ImVec2(g.FontSize * 8, ImMax(g.FontSize * 8 - (GetFrameHeight() + g.Style.ItemInnerSpacing.x), 1.0)); // FIXME: Picker size copied from main picker function
        PushItemWidth(picker_size.x);
        for picker_type := 0; picker_type < 2; picker_type += 1
        {
            // Draw small/thumbnail version of each picker type (over an invisible button for selection)
            if (picker_type > 0) do Separator();
            PushID(picker_type);
            picker_flags := ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_NoOptions | ImGuiColorEditFlags_NoLabel | ImGuiColorEditFlags_NoSidePreview | (.NoAlpha in flags);
            if (picker_type == 0) do picker_flags |= ImGuiColorEditFlags_PickerHueBar;
            if (picker_type == 1) do picker_flags |= ImGuiColorEditFlags_PickerHueWheel;
            backup_pos := GetCursorScreenPos();
            if (Selectable("##selectable", false, 0, picker_size)) {// By default, Selectable() is closing popup
                g.ColorEditOptions = (g.ColorEditOptions & ~ImGuiColorEditFlags_PickerMask_) | (picker_flags & ImGuiColorEditFlags_PickerMask_);
            }
            SetCursorScreenPos(backup_pos);
            previewing_ref_col : ImVec4
            memcpy(&previewing_ref_col, ref_col, size_of(f32) * ((.NoAlpha in picker_flags) ? 3 : 4));
            ColorPicker4("##previewing_picker", &previewing_ref_col.x, picker_flags);
            PopID();
        }
        PopItemWidth();
    }
    if (allow_opt_alpha_bar)
    {
        if (allow_opt_picker) do Separator();
        CheckboxFlags("Alpha Bar", &g.ColorEditOptions, ImGuiColorEditFlags_AlphaBar);
    }
    PopItemFlag();
    EndPopup();
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: TreeNode, CollapsingHeader, etc.
//-------------------------------------------------------------------------
// - TreeNode()
// - TreeNodeV()
// - TreeNodeEx()
// - TreeNodeExV()
// - TreeNodeBehavior() [Internal]
// - TreePush()
// - TreePop()
// - GetTreeNodeToLabelSpacing()
// - SetNextItemOpen()
// - CollapsingHeader()
//-------------------------------------------------------------------------

// [forward declared comment]:
// "
TreeNode_str :: proc(str_id : string, fmt : string, args : ..any) -> bool
{
    return TreeNodeEx(str_id, {}, fmt, args);
}

// [forward declared comment]:
// "
TreeNode_ptr :: proc(ptr_id : rawptr, fmt : string, args : ..any) -> bool
{
    return TreeNodeEx(ptr_id, {}, fmt, args);
}

// [forward declared comment]:
// "
TreeNode_basic :: proc(label : string) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false
    id := GetID(window, label);
    return TreeNodeBehavior(id, ImGuiTreeNodeFlags_None, label, nil);
}

TreeNode :: proc { TreeNode_basic, TreeNode_str, TreeNode_ptr, }

TreeNodeEx_basic :: proc(label : string, flags : ImGuiTreeNodeFlags) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false
    id := GetID(window, label);
    return TreeNodeBehavior(id, flags, label, nil);
}

TreeNodeEx_str :: proc(str_id : string, flags : ImGuiTreeNodeFlags, fmt : string, args : ..any) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    id := GetID(window, str_id);
    label := ImFormatStringToTempBuffer(fmt, args);
    return TreeNodeBehavior(id, flags, label, end(label));
}

TreeNodeEx_ptr :: proc(ptr_id : rawptr, flags : ImGuiTreeNodeFlags, fmt : string, args : ..any) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    id := GetID(window, ptr_id);
    label := ImFormatStringToTempBuffer(fmt, args);
    return TreeNodeBehavior(id, flags, label, end(label));
}

TreeNodeEx :: proc { TreeNodeEx_str, TreeNodeEx_ptr }

TreeNodeGetOpen :: proc(storage_id : ImGuiID) -> bool
{
    g := GImGui;
    storage := g.CurrentWindow.DC.StateStorage;
    return storage.GetInt(storage_id, 0) != 0;
}

TreeNodeSetOpen :: proc(storage_id : ImGuiID, open : bool)
{
    g := GImGui;
    storage := g.CurrentWindow.DC.StateStorage;
    storage.SetInt(storage_id, open ? 1 : 0);
}

// [forward declared comment]:
// Return open state. Consume previous SetNextItemOpen() data, if any. May return true when logging.
TreeNodeUpdateNextOpen :: proc(storage_id : ImGuiID, flags : ImGuiTreeNodeFlags) -> bool
{
    if (.Leaf in flags)   do return true

    // We only write to the tree storage if the user clicks, or explicitly use the SetNextItemOpen function
    g := GImGui;
    window := g.CurrentWindow;
    storage := window.DC.StateStorage;

    is_open : bool
    if (.HasOpen in g.NextItemData.HasFlags)
    {
        if (.Always in g.NextItemData.OpenCond)
        {
            is_open = g.NextItemData.OpenVal;
            TreeNodeSetOpen(storage_id, is_open);
        }
        else
        {
            // We treat ImGuiCond_Once and ImGuiCond_FirstUseEver the same because tree node state are not saved persistently.
            stored_value := GetInt(storage, storage_id, -1);
            if (stored_value == -1)
            {
                is_open = g.NextItemData.OpenVal;
                TreeNodeSetOpen(storage_id, is_open);
            }
            else
            {
                is_open = stored_value != 0;
            }
        }
    }
    else
    {
        is_open = GetInt(storage, storage_id, (.DefaultOpen in flags) ? 1 : 0) != 0;
    }

    // When logging is enabled, we automatically expand tree nodes (but *NOT* collapsing headers.. seems like sensible behavior).
    // NB- If we are above max depth we still allow manually opened nodes to be logged.
    if (g.LogEnabled && !(.NoAutoOpenOnLog in flags) && (i32(window.DC.TreeDepth) - g.LogDepthRef) < g.LogDepthToExpand)   do is_open = true

    return is_open;
}

// Store ImGuiTreeNodeStackData for just submitted node.
// Currently only supports 32 level deep and we are fine with (1 << Depth) overflowing into a zero, easy to increase.
TreeNodeStoreStackData :: proc(flags : ImGuiTreeNodeFlags)
{
    g := GImGui;
    window := g.CurrentWindow;

    resize(&g.TreeNodeStack, len(g.TreeNodeStack) + 1);
    tree_node_data := back(g.TreeNodeStack);
    tree_node_data.ID = g.LastItemData.ID;
    tree_node_data.TreeFlags = flags;
    tree_node_data.ItemFlags = g.LastItemData.ItemFlags;
    tree_node_data.NavRect = g.LastItemData.NavRect;
    window.DC.TreeHasStackDataDepthMask |= (1 << window.DC.TreeDepth);
}

// When using public API, currently 'id == storage_id' is always true, but we separate the values to facilitate advanced user code doing storage queries outside of UI loop.
TreeNodeBehavior :: proc(id : ImGuiID, flags : ImGuiTreeNodeFlags, label_ : string, label_end : ^u8) -> bool
{
    flags := flags
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    style := &g.Style;
    display_frame := .Framed in flags;
    padding := (display_frame || (.FramePadding in flags)) ? style.FramePadding : ImVec2{style.FramePadding.x, ImMin(window.DC.CurrLineTextBaseOffset, style.FramePadding.y)};

    label, _ := FindRenderedText(label);
    label_size := CalcTextSize(label, false);

    text_offset_x := g.FontSize + (display_frame ? padding.x * 3 : padding.x * 2);   // Collapsing arrow width + Spacing
    text_offset_y := ImMax(padding.y, window.DC.CurrLineTextBaseOffset);            // Latch before ItemSize changes it
    text_width := g.FontSize + label_size.x + padding.x * 2;                         // Include collapsing arrow

    // We vertically grow up to current line height up the typical widget height.
    frame_height := ImMax(ImMin(window.DC.CurrLineSize.y, g.FontSize + style.FramePadding.y * 2), label_size.y + padding.y * 2);
    span_all_columns := .SpanAllColumns in flags && (g.CurrentTable != nil);
    frame_bb : ImRect
    frame_bb.Min.x = span_all_columns ? window.ParentWorkRect.Min.x : (.SpanFullWidth in flags) ? window.WorkRect.Min.x : window.DC.CursorPos.x;
    frame_bb.Min.y = window.DC.CursorPos.y;
    frame_bb.Max.x = span_all_columns ? window.ParentWorkRect.Max.x : (.SpanTextWidth in flags) ? window.DC.CursorPos.x + text_width + padding.x : window.WorkRect.Max.x;
    frame_bb.Max.y = window.DC.CursorPos.y + frame_height;
    if (display_frame)
    {
        outer_extend := math.trunc(window.WindowPadding.x * 0.5); // Framed header expand a little outside of current limits
        frame_bb.Min.x -= outer_extend;
        frame_bb.Max.x += outer_extend;
    }

    text_pos := ImVec2{window.DC.CursorPos.x + text_offset_x, window.DC.CursorPos.y + text_offset_y};
    ItemSize(ImVec2{text_width, frame_height}, padding.y);

    // For regular tree nodes, we arbitrary allow to click past 2 worth of ItemSpacing
    interact_bb := frame_bb;
    if ((flags & {.Framed, .SpanAvailWidth, .SpanFullWidth, .SpanTextWidth, .SpanAllColumns}) == nil) {
        interact_bb.Max.x = frame_bb.Min.x + text_width + (label_size.x > 0.0 ? style.ItemSpacing.x * 2.0 : 0.0);
    }

    // Compute open and multi-select states before ItemAdd() as it clear NextItem data.
    storage_id := (.HasStorageID in g.NextItemData.HasFlags) ? g.NextItemData.StorageId : id;
    is_open := TreeNodeUpdateNextOpen(storage_id, flags);

    is_visible : bool
    if (span_all_columns)
    {
        // Modify ClipRect for the ItemAdd(), faster than doing a PushColumnsBackground/PushTableBackgroundChannel for every Selectable..
        backup_clip_rect_min_x := window.ClipRect.Min.x;
        backup_clip_rect_max_x := window.ClipRect.Max.x;
        window.ClipRect.Min.x = window.ParentWorkRect.Min.x;
        window.ClipRect.Max.x = window.ParentWorkRect.Max.x;
        is_visible = ItemAdd(interact_bb, id);
        window.ClipRect.Min.x = backup_clip_rect_min_x;
        window.ClipRect.Max.x = backup_clip_rect_max_x;
    }
    else
    {
        is_visible = ItemAdd(interact_bb, id);
    }
    g.LastItemData.StatusFlags |= {.HasDisplayRect};
    g.LastItemData.DisplayRect = frame_bb;

    // If a NavLeft request is happening and ImGuiTreeNodeFlags_NavLeftJumpsBackHere enabled:
    // Store data for the current depth to allow returning to this node from any child item.
    // For this purpose we essentially compare if g.NavIdIsAlive went from 0 to 1 between TreeNode() and TreePop().
    // It will become tempting to enable ImGuiTreeNodeFlags_NavLeftJumpsBackHere by default or move it to ImGuiStyle.
    store_tree_node_stack_data := false;
    if (!(.NoTreePushOnOpen in flags))
    {
        if ((.NavLeftJumpsBackHere in flags) && is_open && !g.NavIdIsAlive) {
            if (g.NavMoveDir == .Left && g.NavWindow == window && NavMoveRequestButNoResultYet()) {
                store_tree_node_stack_data = true;
            }
        }
    }

    is_leaf := .Leaf in flags
    if (!is_visible)
    {
        if (store_tree_node_stack_data && is_open) {
            TreeNodeStoreStackData(flags); // Call before TreePushOverrideID()
        }
        if (is_open && !(.NoTreePushOnOpen in flags))   do TreePushOverrideID(id)
when IMGUI_ENABLE_TEST_ENGINE {
        IMGUI_TEST_ENGINE_ITEM_INFO(g.LastItemData.ID, label, g.LastItemData.StatusFlags | (is_leaf ? nil : ImGuiItemStatusFlags{ .Openable }) | (is_open ? ImGuiItemStatusFlags{ .Opened } : nil));
}
        return is_open;
    }

    if (span_all_columns)
    {
        TablePushBackgroundChannel();
        g.LastItemData.StatusFlags |= {.HasClipRect};
        g.LastItemData.ClipRect = window.ClipRect;
    }

    button_flags : ImGuiButtonFlags;
    if ((.AllowOverlap in flags) || (cast(ImGuiItemFlag) ImGuiItemFlagsPrivate.AllowOverlap in g.LastItemData.ItemFlags)) {
        button_flags |= transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.AllowOverlap;
    }
    if (!is_leaf) {
        button_flags |= transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.PressedOnDragDropHold;
    }

    // We allow clicking on the arrow section with keyboard modifiers held, in order to easily
    // allow browsing a tree while preserving selection with code implementing multi-selection patterns.
    // When clicking on the rest of the tree node we always disallow keyboard modifiers.
    arrow_hit_x1 := (text_pos.x - text_offset_x) - style.TouchExtraPadding.x;
    arrow_hit_x2 := (text_pos.x - text_offset_x) + (g.FontSize + padding.x * 2.0) + style.TouchExtraPadding.x;
    is_mouse_x_over_arrow := (g.IO.MousePos.x >= arrow_hit_x1 && g.IO.MousePos.x < arrow_hit_x2);

    is_multi_select := (g.LastItemData.ItemFlags & transmute(ImGuiItemFlags) ImGuiItemFlagsPrivate.IsMultiSelect) != nil;
    if (is_multi_select) { // We absolutely need to distinguish open vs select so _OpenOnArrow comes by default
        flags |= (flags & transmute(ImGuiTreeNodeFlags) ImGuiTreeNodeFlagsPrivate.OpenOnMask_) == nil ? ImGuiTreeNodeFlags{.OpenOnArrow, .OpenOnDoubleClick} : {.OpenOnArrow};
    }

    // Open behaviors can be altered with the _OpenOnArrow and _OnOnDoubleClick flags.
    // Some alteration have subtle effects (e.g. toggle on MouseUp vs MouseDown events) due to requirements for multi-selection and drag and drop support.
    // - Single-click on label = Toggle on MouseUp (default, when _OpenOnArrow=0)
    // - Single-click on arrow = Toggle on MouseDown (when _OpenOnArrow=0)
    // - Single-click on arrow = Toggle on MouseDown (when _OpenOnArrow=1)
    // - Double-click on label = Toggle on MouseDoubleClick (when _OpenOnDoubleClick=1)
    // - Double-click on arrow = Toggle on MouseDoubleClick (when _OpenOnDoubleClick=1 and _OpenOnArrow=0)
    // It is rather standard that arrow click react on Down rather than Up.
    // We set ImGuiButtonFlags_PressedOnClickRelease on OpenOnDoubleClick because we want the item to be active on the initial MouseDown in order for drag and drop to work.
    if (is_mouse_x_over_arrow) {
        button_flags |= transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.PressedOnClick;
    }
    else if (.OpenOnDoubleClick in flags) {
        button_flags |= transmute(ImGuiButtonFlags) (ImGuiButtonFlagsPrivate.PressedOnClickRelease | ImGuiButtonFlagsPrivate.PressedOnDoubleClick);
    }
    else {
        button_flags |= transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.PressedOnClickRelease;
    }

    selected := .Selected in flags
    was_selected := selected;

    // Multi-selection support (header)
    if (is_multi_select)
    {
        // Handle multi-select + alter button flags for it
        MultiSelectItemHeader(id, &selected, &button_flags);
        if (is_mouse_x_over_arrow) {
            button_flags = (button_flags |  transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.PressedOnClick) &~ transmute(ImGuiButtonFlags)ImGuiButtonFlagsPrivate.PressedOnClickRelease;
        }
    }
    else
    {
        if (window != g.HoveredWindow || !is_mouse_x_over_arrow) {
            button_flags |= transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.NoKeyModsAllowed;
        }
    }

    hovered, held : bool
    pressed := ButtonBehavior(interact_bb, id, &hovered, &held, button_flags);
    toggled := false;
    if (!is_leaf)
    {
        if (pressed && g.DragDropHoldJustPressedId != id)
        {
            if ((flags & transmute(ImGuiTreeNodeFlags) ImGuiTreeNodeFlagsPrivate.OpenOnMask_) == nil || (g.NavActivateId == id && !is_multi_select)) {
                toggled = true; // Single click
            }
            if (.OpenOnArrow in flags) {
                toggled |= is_mouse_x_over_arrow && !g.NavHighlightItemUnderNav; // Lightweight equivalent of IsMouseHoveringRect() since ButtonBehavior() already did the job
            }
            if ((.OpenOnDoubleClick in flags) && g.IO.MouseClickedCount[0] == 2) {
                toggled = true; // Double click
            }
        }
        else if (pressed && g.DragDropHoldJustPressedId == id)
        {
            assert(button_flags & transmute(ImGuiButtonFlags) ImGuiButtonFlagsPrivate.PressedOnDragDropHold != nil);
            if (!is_open) { // When using Drag and Drop "hold to open" we keep the node highlighted after opening, but never close it again.
                toggled = true;
            }
            else {
                pressed = false; // Cancel press so it doesn't trigger selection.
            }
        }

        if (g.NavId == id && g.NavMoveDir == .Left && is_open)
        {
            toggled = true;
            NavClearPreferredPosForAxis(.X);
            NavMoveRequestCancel();
        }
        if (g.NavId == id && g.NavMoveDir == .Right && !is_open) // If there's something upcoming on the line we may want to give it the priority?
        {
            toggled = true;
            NavClearPreferredPosForAxis(.X);
            NavMoveRequestCancel();
        }

        if (toggled)
        {
            is_open = !is_open;
            SetInt(window.DC.StateStorage, storage_id, i32(is_open));
            g.LastItemData.StatusFlags |= { .ToggledOpen };
        }
    }

    // Multi-selection support (footer)
    if (is_multi_select)
    {
        pressed_copy := pressed && !toggled;
        MultiSelectItemFooter(id, &selected, &pressed_copy);
        if (pressed) do SetNavID(id, window.DC.NavLayerCurrent, g.CurrentFocusScopeId, interact_bb);
    }

    if (selected != was_selected) {
        g.LastItemData.StatusFlags |= { .ToggledSelection }
    }

    // Render
    {
        text_col := GetColorU32(ImGuiCol.Text);
        nav_render_cursor_flags := ImGuiNavRenderCursorFlags{ .Compact };
        if (is_multi_select) do nav_render_cursor_flags |= { .AlwaysDraw }; // Always show the nav rectangle
        if (display_frame)
        {
            // Framed type
            bg_col := GetColorU32((held && hovered) ? ImGuiCol.HeaderActive : hovered ? ImGuiCol.HeaderHovered : ImGuiCol.Header);
            RenderFrame(frame_bb.Min, frame_bb.Max, bg_col, true, style.FrameRounding);
            RenderNavCursor(frame_bb, id, nav_render_cursor_flags);
            if (.Bullet in flags) {
                RenderBullet(window.DrawList, ImVec2{text_pos.x - text_offset_x * 0.60, text_pos.y + g.FontSize * 0.5}, text_col);
            }
            else if (!is_leaf) {
                RenderArrow(window.DrawList, ImVec2{text_pos.x - text_offset_x + padding.x, text_pos.y}, text_col, is_open ? ((flags & transmute(ImGuiTreeNodeFlags) ImGuiTreeNodeFlagsPrivate.UpsideDownArrow != nil) ? ImGuiDir.Up : ImGuiDir.Down) : .Right, 1.0);
            }
            else {// Leaf without bullet, left-adjusted text
                text_pos.x -= text_offset_x - padding.x;
            }
            if (flags & transmute(ImGuiTreeNodeFlags) ImGuiTreeNodeFlagsPrivate.ClipLabelForTrailingButton != nil) {
                frame_bb.Max.x -= g.FontSize + style.FramePadding.x;
            }
            if (g.LogEnabled) {
                LogSetNextTextDecoration("###", "###");
            }
        }
        else
        {
            // Unframed typed for tree nodes
            if (hovered || selected)
            {
                bg_col := GetColorU32((held && hovered) ? ImGuiCol.HeaderActive : hovered ? ImGuiCol.HeaderHovered : ImGuiCol.Header);
                RenderFrame(frame_bb.Min, frame_bb.Max, bg_col, false);
            }
            RenderNavCursor(frame_bb, id, nav_render_cursor_flags);
            if (.Bullet in flags) {
                RenderBullet(window.DrawList, ImVec2{text_pos.x - text_offset_x * 0.5, text_pos.y + g.FontSize * 0.5}, text_col);
            }
            else if (!is_leaf) {
                RenderArrow(window.DrawList, ImVec2{text_pos.x - text_offset_x + padding.x, text_pos.y + g.FontSize * 0.15}, text_col, is_open ? ((flags & transmute(ImGuiTreeNodeFlags) ImGuiTreeNodeFlagsPrivate.UpsideDownArrow != nil) ? ImGuiDir.Up : ImGuiDir.Down) : .Right, 0.70);
            }
            if (g.LogEnabled) {
                LogSetNextTextDecoration(">", nil);
            }
        }

        if (span_all_columns) do TablePopBackgroundChannel();

        // Label
        if (display_frame) do RenderTextClipped(text_pos, frame_bb.Max, label, &label_size);
        else do RenderText(text_pos, label, false);
    }

    if (store_tree_node_stack_data && is_open) {
        TreeNodeStoreStackData(flags); // Call before TreePushOverrideID()
    }
    if (is_open && !(.NoTreePushOnOpen in flags)) {
        TreePushOverrideID(id); // Could use TreePush(label) but this avoid computing twice
    }

when IMGUI_ENABLE_TEST_ENGINE {
    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags | (is_leaf ? 0 : ImGuiItemStatusFlags.Openable) | (is_open ? ImGuiItemStatusFlags.Opened : 0));
}
    return is_open;
}

TreePush_str :: proc(str_id : ^u8)
{
    window := GetCurrentWindow();
    Indent();
    window.DC.TreeDepth += 1;
    PushID(str_id);
}

TreePush_ptr :: proc(ptr_id : rawptr)
{
    window := GetCurrentWindow();
    Indent();
    window.DC.TreeDepth += 1;
    PushID(ptr_id);
}

TreePush :: proc { TreePush_str, TreePush_ptr }

TreePushOverrideID :: proc(id : ImGuiID)
{
    g := GImGui;
    window := g.CurrentWindow;
    Indent();
    window.DC.TreeDepth += 1;
    PushOverrideID(id);
}

// [forward declared comment]:
// ~ Unindent()+PopID()
TreePop :: proc()
{
    g := GImGui;
    window := g.CurrentWindow;
    Unindent();

    window.DC.TreeDepth -= 1;
    tree_depth_mask : u32 = (1 << window.DC.TreeDepth);

    if (window.DC.TreeHasStackDataDepthMask & tree_depth_mask != 0) // Only set during request
    {
        data := back(g.TreeNodeStack);
        assert(data.ID == back(window.IDStack)^);
        if .NavLeftJumpsBackHere in data.TreeFlags
        {
            // Handle Left arrow to move to parent tree node (when ImGuiTreeNodeFlags_NavLeftJumpsBackHere is enabled)
            if (g.NavIdIsAlive && g.NavMoveDir == .Left && g.NavWindow == window && NavMoveRequestButNoResultYet()) {
                NavMoveRequestResolveWithPastTreeNode(&g.NavMoveResultLocal, data);
            }
        }
        pop(&g.TreeNodeStack);
        window.DC.TreeHasStackDataDepthMask &= ~tree_depth_mask;
    }

    assert(len(window.IDStack) > 1); // There should always be 1 element in the IDStack (pushed during window creation). If this triggers you called TreePop/PopID too much.
    PopID();
}

// Horizontal distance preceding label when using TreeNode() or Bullet()
// [forward declared comment]:
// horizontal distance preceding label when using TreeNode*() or Bullet() == (g.FontSize + style.FramePadding.x*2) for a regular unframed TreeNode
GetTreeNodeToLabelSpacing :: proc() -> f32
{
    g := GImGui;
    return g.FontSize + (g.Style.FramePadding.x * 2.0);
}

// Set next TreeNode/CollapsingHeader open state.
// [forward declared comment]:
// set next TreeNode/CollapsingHeader open state.
SetNextItemOpen :: proc(is_open : bool, cond : ImGuiCond = {})
{
    g := GImGui;
    if (g.CurrentWindow.SkipItems)   do return
    g.NextItemData.HasFlags |= ImGuiNextItemDataFlags_HasOpen;
    g.NextItemData.OpenVal = is_open;
    g.NextItemData.OpenCond = (u8)(cond ? cond : { .Always });
}

// Set next TreeNode/CollapsingHeader storage id.
// [forward declared comment]:
// set id to use for open/close storage (default to same as item id).
SetNextItemStorageID :: proc(storage_id : ImGuiID)
{
    g := GImGui;
    if (g.CurrentWindow.SkipItems)   do return
    g.NextItemData.HasFlags |= ImGuiNextItemDataFlags_HasStorageID;
    g.NextItemData.StorageId = storage_id;
}

// CollapsingHeader returns true when opened but do not indent nor push into the ID stack (because of the ImGuiTreeNodeFlags_NoTreePushOnOpen flag).
// This is basically the same as calling TreeNodeEx(label, ImGuiTreeNodeFlags_CollapsingHeader). You can remove the _NoTreePushOnOpen flag if you want behavior closer to normal TreeNode().
// [forward declared comment]:
// when 'p_visible != NULL': if '*p_visible==true' display an additional small close button on upper right of the header which will set the bool to false when clicked, if '*p_visible==false' don't display the header.
CollapsingHeader_basic :: proc(label : string, flags : ImGuiTreeNodeFlags) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false
    id := GetID(window, label);
    return TreeNodeBehavior(id, flags | ImGuiTreeNodeFlags_CollapsingHeader, label);
}

// p_visible == NULL                        : regular collapsing header
// p_visible != NULL && *p_visible == true  : show a small close button on the corner of the header, clicking the button will set *p_visible = false
// p_visible != NULL && *p_visible == false : do not show the header at all
// Do not mistake this with the Open state of the header itself, which you can adjust with SetNextItemOpen() or ImGuiTreeNodeFlags_DefaultOpen.
// [forward declared comment]:
// when 'p_visible != NULL': if '*p_visible==true' display an additional small close button on upper right of the header which will set the bool to false when clicked, if '*p_visible==false' don't display the header.
CollapsingHeader_ex :: proc(label : string, p_visible : ^bool, flags : ImGuiTreeNodeFlags = {}) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    if (p_visible != nil && !p_visible^)   do return false

    id := GetID(window, label);
    flags |= ImGuiTreeNodeFlags_CollapsingHeader;
    if (p_visible) do flags |= ImGuiTreeNodeFlags_AllowOverlap | ImGuiTreeNodeFlags_ClipLabelForTrailingButton;
    is_open := TreeNodeBehavior(id, flags, label);
    if (p_visible != nil)
    {
        // Create a small overlapping close button
        // FIXME: We can evolve this into user accessible helpers to add extra buttons on title bars, headers, etc.
        // FIXME: CloseButton can overlap into text, need find a way to clip the text somehow.
        g := GImGui;
        last_item_backup := g.LastItemData;
        button_size := g.FontSize;
        button_x := ImMax(g.LastItemData.Rect.Min.x, g.LastItemData.Rect.Max.x - g.Style.FramePadding.x - button_size);
        button_y := g.LastItemData.Rect.Min.y + g.Style.FramePadding.y;
        close_button_id := GetIDWithSeed("#CLOSE", nil, id);
        if (CloseButton(close_button_id, ImVec2{button_x, button_y}))   do p_visible^ = false
        g.LastItemData = last_item_backup;
    }

    return is_open;
}

CollapsingHeader :: proc { CollapsingHeader_basic, CollapsingHeader_ex }

//-------------------------------------------------------------------------
// [SECTION] Widgets: Selectable
//-------------------------------------------------------------------------
// - Selectable()
//-------------------------------------------------------------------------

// Tip: pass a non-visible label (e.g. "##hello") then you can use the space to draw other text or image.
// But you need to make sure the ID is unique, e.g. enclose calls in PushID/PopID or use ##unique_id.
// With this scheme, ImGuiSelectableFlags_SpanAllColumns and ImGuiSelectableFlags_AllowOverlap are also frequently used flags.
// FIXME: Selectable() with (size.x == 0.0f) and (SelectableTextAlign.x > 0.0f) followed by SameLine() is currently not supported.
// [forward declared comment]:
// "bool* p_selected" point to the selection state (read-write), as a convenient helper.
Selectable_val :: proc(label : string, selected : bool, flags : ImGuiSelectableFlags = {}, size_arg : ImVec2 = {}) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    style := &g.Style;

    // Submit label or explicit size to ItemSize(), whereas ItemAdd() will submit a larger/spanning rectangle.
    id := GetID(window, label);
    label_size := CalcTextSize(label, nil, true);
    size := ImVec2{size_arg.x != 0.0 ? size_arg.x : label_size.x, size_arg.y != 0.0 ? size_arg.y : label_size.y};
    pos := window.DC.CursorPos;
    pos.y += window.DC.CurrLineTextBaseOffset;
    ItemSize(size, 0.0);

    // Fill horizontal space
    // We don't support (size < 0.0f) in Selectable() because the ItemSpacing extension would make explicitly right-aligned sizes not visibly match other widgets.
    span_all_columns := (.SpanAllColumns in flags)
    min_x := span_all_columns ? window.ParentWorkRect.Min.x : pos.x;
    max_x := span_all_columns ? window.ParentWorkRect.Max.x : window.WorkRect.Max.x;
    if (size_arg.x == 0.0 || (.SpanAvailWidth in flags)) {
        size.x = ImMax(label_size.x, max_x - min_x);
    }

    // Text stays at the submission position, but bounding box may be extended on both sides
    text_min := pos;
    text_max := ImVec2{min_x + size.x, pos.y + size.y};

    // Selectables are meant to be tightly packed together with no click-gap, so we extend their box to cover spacing between selectable.
    // FIXME: Not part of layout so not included in clipper calculation, but ItemSize currently doesn't allow offsetting CursorPos.
    bb := ImRect{ _r = {min_x, pos.y, text_max.x, text_max.y}};
    if ((.NoPadWithHalfSpacing not_in flags))
    {
        spacing_x := span_all_columns ? 0.0 : style.ItemSpacing.x;
        spacing_y := style.ItemSpacing.y;
        spacing_L := math.trunc(spacing_x * 0.50);
        spacing_U := math.trunc(spacing_y * 0.50);
        bb.Min.x -= spacing_L;
        bb.Min.y -= spacing_U;
        bb.Max.x += (spacing_x - spacing_L);
        bb.Max.y += (spacing_y - spacing_U);
    }
    //if (g.IO.KeyCtrl) { AddRect(GetForegroundDrawList(), bb.Min, bb.Max, IM_COL32(0, 255, 0, 255)); }

    disabled_item := (.Disabled in flags)
    extra_item_flags := disabled_item ? ImGuiItemFlags_Disabled : ImGuiItemFlags_None;
    is_visible : bool
    if (span_all_columns)
    {
        // Modify ClipRect for the ItemAdd(), faster than doing a PushColumnsBackground/PushTableBackgroundChannel for every Selectable..
        backup_clip_rect_min_x := window.ClipRect.Min.x;
        backup_clip_rect_max_x := window.ClipRect.Max.x;
        window.ClipRect.Min.x = window.ParentWorkRect.Min.x;
        window.ClipRect.Max.x = window.ParentWorkRect.Max.x;
        is_visible = ItemAdd(bb, id, nil, extra_item_flags);
        window.ClipRect.Min.x = backup_clip_rect_min_x;
        window.ClipRect.Max.x = backup_clip_rect_max_x;
    }
    else
    {
        is_visible = ItemAdd(bb, id, nil, extra_item_flags);
    }

    is_multi_select := (.IsMultiSelect in g.LastItemData.ItemFlags) != 0;
    if (!is_visible) {
        if (!is_multi_select || !g.BoxSelectState.UnclipMode || !g.BoxSelectState.UnclipRect.Overlaps(bb)) { // Extra layer of "no logic clip" for box-select support (would be more overhead to add to ItemAdd) 
            return false
        }
    }

    disabled_global := (.Disabled in g.CurrentItemFlags) != 0;
    if (disabled_item && !disabled_global) {// Only testing this as an optimization
        BeginDisabled();
    }

    // FIXME: We can standardize the behavior of those two, we could also keep the fast path of override ClipRect + full push on render only,
    // which would be advantageous since most selectable are not selected.
    if (span_all_columns)
    {
        if (g.CurrentTable) do TablePushBackgroundChannel();
        else if (window.DC.CurrentColumns)   do PushColumnsBackground()
        g.LastItemData.StatusFlags |= ImGuiItemStatusFlags_HasClipRect;
        g.LastItemData.ClipRect = window.ClipRect;
    }

    // We use NoHoldingActiveID on menus so user can click and _hold_ on a menu then drag to browse child entries
    button_flags := 0;
    if (.NoHoldingActiveID in flags) { button_flags |= ImGuiButtonFlags_NoHoldingActiveId; }
    if (.NoSetKeyOwner in flags)     { button_flags |= ImGuiButtonFlags_NoSetKeyOwner; }
    if (.SelectOnClick in flags)     { button_flags |= ImGuiButtonFlags_PressedOnClick; }
    if (.SelectOnRelease in flags)   { button_flags |= ImGuiButtonFlags_PressedOnRelease; }
    if (.AllowDoubleClick in flags)  { button_flags |= ImGuiButtonFlags_PressedOnClickRelease | ImGuiButtonFlags_PressedOnDoubleClick; }
    if ((.AllowOverlap in flags) || (.AllowOverlap in g.LastItemData.ItemFlags)) { button_flags |= ImGuiButtonFlags_AllowOverlap; }

    // Multi-selection support (header)
    was_selected := selected;
    if (is_multi_select)
    {
        // Handle multi-select + alter button flags for it
        MultiSelectItemHeader(id, &selected, &button_flags);
    }

    hovered, held : bool
    pressed := ButtonBehavior(bb, id, &hovered, &held, button_flags);

    // Multi-selection support (footer)
    if (is_multi_select)
    {
        MultiSelectItemFooter(id, &selected, &pressed);
    }
    else
    {
        // Auto-select when moved into
        // - This will be more fully fleshed in the range-select branch
        // - This is not exposed as it won't nicely work with some user side handling of shift/control
        // - We cannot do 'if (g.NavJustMovedToId != id) { selected = false; pressed = was_selected; }' for two reasons
        //   - (1) it would require focus scope to be set, need exposing PushFocusScope() or equivalent (e.g. BeginSelection() calling PushFocusScope())
        //   - (2) usage will fail with clipped items
        //   The multi-select API aim to fix those issues, e.g. may be replaced with a BeginSelection() API.
        if ((.SelectOnNav in flags) && g.NavJustMovedToId != 0 && g.NavJustMovedToFocusScopeId == g.CurrentFocusScopeId) {
            if (g.NavJustMovedToId == id) {
                selected = true
                pressed = true
            }
        }
    }

    // Update NavId when clicking or when Hovering (this doesn't happen on most widgets), so navigation can be resumed with keyboard/gamepad
    if (pressed || (hovered && (.SetNavIdOnHover in flags)))
    {
        if (!g.NavHighlightItemUnderNav && g.NavWindow == window && g.NavLayer == window.DC.NavLayerCurrent)
        {
            SetNavID(id, window.DC.NavLayerCurrent, g.CurrentFocusScopeId, WindowRectAbsToRel(window, bb)); // (bb == NavRect)
            if (g.IO.ConfigNavCursorVisibleAuto) do g.NavCursorVisible = false;
        }
    }
    if (pressed)   do MarkItemEdited(id)

    if (selected != was_selected) {
        g.LastItemData.StatusFlags |= ImGuiItemStatusFlags_ToggledSelection;
    }

    // Render
    if (is_visible)
    {
        highlighted := hovered || (.Highlight in flags);
        if (highlighted || selected)
        {
            // Between 1.91.0 and 1.91.4 we made selected Selectable use an arbitrary lerp between _Header and _HeaderHovered. Removed that now. (#8106)
            col := GetColorU32((held && highlighted) ? ImGuiCol.HeaderActive : highlighted ? ImGuiCol.HeaderHovered : ImGuiCol.Header);
            RenderFrame(bb.Min, bb.Max, col, false, 0.0);
        }
        if (g.NavId == id)
        {
            nav_render_cursor_flags := ImGuiNavRenderCursorFlags_Compact | ImGuiNavRenderCursorFlags_NoRounding;
            if (is_multi_select) {
                nav_render_cursor_flags |= ImGuiNavRenderCursorFlags_AlwaysDraw; // Always show the nav rectangle
            }
            RenderNavCursor(bb, id, nav_render_cursor_flags);
        }
    }

    if (span_all_columns)
    {
        if (g.CurrentTable) do TablePopBackgroundChannel();
        else if (window.DC.CurrentColumns)   do PopColumnsBackground()
    }

    if (is_visible) do RenderTextClipped(text_min, text_max, label, nil, &label_size, style.SelectableTextAlign, &bb);

    // Automatically close popups
    if (pressed && (.Popup in window.Flags) && !(.NoAutoClosePopups in flags) && (.AutoClosePopups in g.LastItemData.ItemFlags))   do CloseCurrentPopup()

    if (disabled_item && !disabled_global)   do EndDisabled()

    // Selectable() always returns a pressed state!
    // Users of BeginMultiSelect()/EndMultiSelect() scope: you may call ImGui::IsItemToggledSelection() to retrieve
    // selection toggle, only useful if you need that state updated (e.g. for rendering purpose) before reaching EndMultiSelect().
    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags);
    return pressed; //-V1020
}

// [forward declared comment]:
// "bool* p_selected" point to the selection state (read-write), as a convenient helper.
Selectable_ref :: proc(label : string, p_selected : ^bool, flags : ImGuiSelectableFlags = {}, size_arg : ImVec2 = {}) -> bool
{
    if (Selectable(label, p_selected^, flags, size_arg))
    {
        p_selected^ = !p_selected^;
        return true;
    }
    return false;
}

Selectable :: proc { Selectable_val, Selectable_ref }


//-------------------------------------------------------------------------
// [SECTION] Widgets: Typing-Select support
//-------------------------------------------------------------------------

// [Experimental] Currently not exposed in public API.
// Consume character inputs and return search request, if any.
// This would typically only be called on the focused window or location you want to grab inputs for, e.g.
//   if (ImGui::IsWindowFocused(...))
//       if (ImGuiTypingSelectRequest* req = ImGui::GetTypingSelectRequest())
//           focus_idx = ImGui::TypingSelectFindMatch(req, my_items.size(), [](void*, int n) { return my_items[n]->Name; }, &my_items, -1);
// However the code is written in a way where calling it from multiple locations is safe (e.g. to obtain buffer).
GetTypingSelectRequest :: proc(flags : ImGuiTypingSelectFlags = nil) -> ^ImGuiTypingSelectRequest
{
    g := GImGui;
    data := &g.TypingSelectState;
    out_request := &data.Request;

    // Clear buffer
    TYPING_SELECT_RESET_TIMER := 1.80;          // FIXME: Potentially move to IO config.
    TYPING_SELECT_SINGLE_CHAR_COUNT_FOR_LOCK := 4; // Lock single char matching when repeating same char 4 times
    if (data.SearchBuffer[0] != 0)
    {
        clear_buffer := false;
        clear_buffer |= (g.NavFocusScopeId != data.FocusScope);
        clear_buffer |= (data.LastRequestTime + TYPING_SELECT_RESET_TIMER < g.Time);
        clear_buffer |= g.NavAnyRequest;
        clear_buffer |= g.ActiveId != 0 && g.NavActivateId == 0; // Allow temporary SPACE activation to not interfere
        clear_buffer |= IsKeyPressed(ImGuiKey.Escape) || IsKeyPressed(ImGuiKey.Enter);
        clear_buffer |= IsKeyPressed(ImGuiKey.Backspace) && (.AllowBackspace not_in flags);
        //if (clear_buffer) { IMGUI_DEBUG_LOG("GetTypingSelectRequest(): Clear SearchBuffer.\n"); }
        if (clear_buffer)   do data.Clear()
    }

    // Append to buffer
    buffer_max_len := len(data.SearchBuffer) - 1;
    buffer_len := cast(i32) strlen(data.SearchBuffer);
    select_request := false;
    for w in g.IO.InputQueueCharacters
    {
        w_len := ImTextCountUtf8BytesFromStr(&w, &w + 1);
        if (w < 32 || (buffer_len == 0 && ImCharIsBlankW(w)) || (buffer_len + w_len > buffer_max_len)) {// Ignore leading blanks
            continue;
        }
        w_buf : [5]u8
        ImTextCharToUtf8(w_buf, cast(u32) w);
        if (data.SingleCharModeLock && w_len == out_request.SingleCharSize && memcmp(w_buf, data.SearchBuffer, w_len) == 0)
        {
            select_request = true; // Same character: don't need to append to buffer.
            continue;
        }
        if (data.SingleCharModeLock)
        {
            data.Clear(); // Different character: clear
            buffer_len = 0;
        }
        memcpy(data.SearchBuffer + buffer_len, w_buf, w_len + 1); // Append
        buffer_len += w_len;
        select_request = true;
    }
    g.IO.InputQueueCharacters.resize(0);

    // Handle backspace
    if ((.AllowBackspace in flags) && IsKeyPressed(ImGuiKey.Backspace, ImGuiInputFlags_Repeat))
    {
        p := cast(^u8)cast(rawptr)ImTextFindPreviousUtf8Codepoint(data.SearchBuffer, data.SearchBuffer + buffer_len);
        p^ = 0;
        buffer_len = (i32)(p - data.SearchBuffer);
    }

    // Return request if any
    if (buffer_len == 0)   do return nil
    if (select_request)
    {
        data.FocusScope = g.NavFocusScopeId;
        data.LastRequestFrame = g.FrameCount;
        data.LastRequestTime = cast(f32) g.Time;
    }
    out_request.Flags = flags;
    out_request.SearchBufferLen = buffer_len;
    out_request.SearchBuffer = data.SearchBuffer;
    out_request.SelectRequest = (data.LastRequestFrame == g.FrameCount);
    out_request.SingleCharMode = false;
    out_request.SingleCharSize = 0;

    // Calculate if buffer contains the same character repeated.
    // - This can be used to implement a special search mode on first character.
    // - Performed on UTF-8 codepoint for correctness.
    // - SingleCharMode is always set for first input character, because it usually leads to a "next".
    if (.AllowSingleCharMode in flags)
    {
        buf_begin := out_request.SearchBuffer;
        buf_end := out_request.SearchBuffer + out_request.SearchBufferLen;
        c0_len := ImTextCountUtf8BytesFromChar(buf_begin, buf_end);
        p := buf_begin + c0_len;
        for ; p < buf_end; p += c0_len {
            if (memcmp(buf_begin, p, cast(int) c0_len) != 0)   do break
        }
        single_char_count := (p == buf_end) ? (out_request.SearchBufferLen / c0_len) : 0;
        out_request.SingleCharMode = (single_char_count > 0 || data.SingleCharModeLock);
        out_request.SingleCharSize = cast(i8) c0_len;
        data.SingleCharModeLock |= (single_char_count >= TYPING_SELECT_SINGLE_CHAR_COUNT_FOR_LOCK); // From now on we stop search matching to lock to single char mode.
    }

    return out_request;
}

ImStrimatchlen :: proc(s1 : ^u8, s1_end : ^u8, s2 : ^u8) -> i32
{
    match_len := 0;
    for (s1 < s1_end && ImToUpper(s1^) == ImToUpper(s2^)) {
        match_len += 1;
        s1 += 1
        s2 += 1
    }
    return match_len;
}

// Default handler for finding a result for typing-select. You may implement your own.
// You might want to display a tooltip to visualize the current request SearchBuffer
// When SingleCharMode is set:
// - it is better to NOT display a tooltip of other on-screen display indicator.
// - the index of the currently focused item is required.
//   if your SetNextItemSelectionUserData() values are indices, you can obtain it from ImGuiMultiSelectIO::NavIdItem, otherwise from g.NavLastValidSelectionUserData.
TypingSelectFindMatch :: proc(req : ^ImGuiTypingSelectRequest, items_count : i32, get_item_name_func : proc(rawptr, i32) -> ^u8, user_data : rawptr, nav_item_idx : i32) -> i32
{
    if (req == nil || req.SelectRequest == false) {// Support NULL parameter so both calls can be done from same spot.
        return -1;
    }
    idx := -1;
    if (req.SingleCharMode && (.AllowSingleCharMode in req.Flags)) {
        idx = TypingSelectFindNextSingleCharMatch(req, items_count, get_item_name_func, user_data, nav_item_idx);
    }
    else {
        idx = TypingSelectFindBestLeadingMatch(req, items_count, get_item_name_func, user_data);
    }
    if (idx != -1) {
        SetNavCursorVisibleAfterMove();
    }
    return idx;
}

// Special handling when a single character is repeated: perform search on a single letter and goes to next.
TypingSelectFindNextSingleCharMatch :: proc(req : ^ImGuiTypingSelectRequest, items_count : i32, get_item_name_func : proc(rawptr, i32) -> ^u8, user_data : rawptr, nav_item_idx : i32) -> i32
{
    // FIXME: Assume selection user data is index. Would be extremely practical.
    //if (nav_item_idx == -1)
    //    nav_item_idx = cast(int) g.NavLastValidSelectionUserData;

    first_match_idx := -1;
    return_next_match := false;
    for idx := 0; idx < items_count; idx += 1
    {
        item_name := get_item_name_func(user_data, idx);
        if (ImStrimatchlen(req.SearchBuffer, req.SearchBuffer + req.SingleCharSize, item_name) < req.SingleCharSize)   do continue
        if (return_next_match) {                           // Return next matching item after current item.
            return idx;
        }
        if (first_match_idx == -1 && nav_item_idx == -1) { // Return first match immediately if we don't have a nav_item_idx value.
            return idx;
        }
        if (first_match_idx == -1)  {                      // Record first match for wrapping.
            first_match_idx = idx;
        }
        if (nav_item_idx == idx)  {                        // Record that we encountering nav_item so we can return next match.
            return_next_match = true;
        }
    }
    return first_match_idx; // First result
}

TypingSelectFindBestLeadingMatch :: proc(req : ^ImGuiTypingSelectRequest, items_count : i32, get_item_name_func : proc(rawptr, i32) -> ^u8, user_data : rawptr) -> i32
{
    longest_match_idx := -1;
    longest_match_len := 0;
    for idx := 0; idx < items_count; idx += 1
    {
        item_name := get_item_name_func(user_data, idx);
        match_len := ImStrimatchlen(req.SearchBuffer, req.SearchBuffer + req.SearchBufferLen, item_name);
        if (match_len <= longest_match_len)   do continue
        longest_match_idx = idx;
        longest_match_len = match_len;
        if (match_len == req.SearchBufferLen)   do break
    }
    return longest_match_idx;
}

DebugNodeTypingSelectState :: proc(data : ^ImGuiTypingSelectState)
{
when !(IMGUI_DISABLE_DEBUG_TOOLS) {
    Text("SearchBuffer = \"%s\"", data.SearchBuffer);
    Text("SingleCharMode = %d, Size = %d, Lock = %d", data.Request.SingleCharMode, data.Request.SingleCharSize, data.SingleCharModeLock);
    Text("LastRequest = time: %.2, frame: %d", data.LastRequestTime, data.LastRequestFrame);
} else {
    _ = data;
}
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: Box-Select support
// This has been extracted away from Multi-Select logic in the hope that it could eventually be used elsewhere, but hasn't been yet.
//-------------------------------------------------------------------------
// Extra logic in MultiSelectItemFooter() and ImGuiListClipper::Step()
//-------------------------------------------------------------------------
// - BoxSelectPreStartDrag() [Internal]
// - BoxSelectActivateDrag() [Internal]
// - BoxSelectDeactivateDrag() [Internal]
// - BoxSelectScrollWithMouseDrag() [Internal]
// - BeginBoxSelect() [Internal]
// - EndBoxSelect() [Internal]
//-------------------------------------------------------------------------

// Call on the initial click.
BoxSelectPreStartDrag :: proc(id : ImGuiID, clicked_item : ImGuiSelectionUserData)
{
    g := GImGui;
    bs := &g.BoxSelectState;
    bs.ID = id;
    bs.IsStarting = true; // Consider starting box-select.
    bs.IsStartedFromVoid = (clicked_item == ImGuiSelectionUserData_Invalid);
    bs.IsStartedSetNavIdOnce = bs.IsStartedFromVoid;
    bs.KeyMods = g.IO.KeyMods;
    bs.EndPosRel = WindowPosAbsToRel(g.CurrentWindow, g.IO.MousePos);
    bs.StartPosRel = bs.EndPosRel
    bs.ScrollAccum = ImVec2{0.0, 0.0};
}

BoxSelectActivateDrag :: proc(bs : ^ImGuiBoxSelectState, window : ^ImGuiWindow)
{
    g := GImGui;
    IMGUI_DEBUG_LOG_SELECTION("[selection] BeginBoxSelect() 0X%08X: Activate\n", bs.ID);
    bs.IsActive = true;
    bs.Window = window;
    bs.IsStarting = false;
    SetActiveID(bs.ID, window);
    SetActiveIdUsingAllKeyboardKeys();
    if (bs.IsStartedFromVoid && (bs.KeyMods & (ImGuiKey.Mod_Ctrl | ImGuiKey.Mod_Shift)) == 0)   do bs.RequestClear = true
}

BoxSelectDeactivateDrag :: proc(bs : ^ImGuiBoxSelectState)
{
    g := GImGui;
    bs.IsActive = false
    bs.IsStarting = false;
    if (g.ActiveId == bs.ID)
    {
        IMGUI_DEBUG_LOG_SELECTION("[selection] BeginBoxSelect() 0X%08X: Deactivate\n", bs.ID);
        ClearActiveID();
    }
    bs.ID = 0;
}

BoxSelectScrollWithMouseDrag :: proc(bs : ^ImGuiBoxSelectState, window : ^ImGuiWindow, inner_r : ^ImRect)
{
    g := GImGui;
    assert(bs.Window == window);
    for n := 0; n < 2; n += 1 // each axis
    {
        mouse_pos := g.IO.MousePos[n];
        dist := (mouse_pos > inner_r.Max[n]) ? mouse_pos - inner_r.Max[n] : (mouse_pos < inner_r.Min[n]) ? mouse_pos - inner_r.Min[n] : 0.0;
        scroll_curr := window.Scroll[n];
        if (dist == 0.0 || (dist < 0.0 && scroll_curr < 0.0) || (dist > 0.0 && scroll_curr >= window.ScrollMax[n]))   do continue

        speed_multiplier := ImLinearRemapClamp(g.FontSize, g.FontSize * 5.0, 1.0, 4.0, ImAbs(dist)); // x1 to x4 depending on distance
        scroll_step := g.FontSize * 35.0 * speed_multiplier * ImSign(dist) * g.IO.DeltaTime;
        bs.ScrollAccum[n] += scroll_step;

        // Accumulate into a stored value so we can handle high-framerate
        scroll_step_i := ImFloor(bs.ScrollAccum[n]);
        if (scroll_step_i == 0.0)   do continue
        if (n == 0) do SetScrollX(window, scroll_curr + scroll_step_i);
        else do SetScrollY(window, scroll_curr + scroll_step_i);
        bs.ScrollAccum[n] -= scroll_step_i;
    }
}

BeginBoxSelect :: proc(scope_rect : ^ImRect, window : ^ImGuiWindow, box_select_id : ImGuiID, ms_flags : ImGuiMultiSelectFlags) -> bool
{
    g := GImGui;
    bs := &g.BoxSelectState;
    KeepAliveID(box_select_id);
    if (bs.ID != box_select_id)   do return false

    // IsStarting is set by MultiSelectItemFooter() when considering a possible box-select. We validate it here and lock geometry.
    bs.UnclipMode = false;
    bs.RequestClear = false;
    if (bs.IsStarting && IsMouseDragPastThreshold(0)) {
        BoxSelectActivateDrag(bs, window);
    }
    else if ((bs.IsStarting || bs.IsActive) && g.IO.MouseDown[0] == false) {
        BoxSelectDeactivateDrag(bs);
    }
    if (!bs.IsActive)   do return false

    // Current frame absolute prev/current rectangles are used to toggle selection.
    // They are derived from positions relative to scrolling space.
    start_pos_abs := WindowPosRelToAbs(window, bs.StartPosRel);
    prev_end_pos_abs := WindowPosRelToAbs(window, bs.EndPosRel); // Clamped already
    curr_end_pos_abs := g.IO.MousePos;
    if (.ScopeWindow in ms_flags) {// Box-select scrolling only happens with ScopeWindow
        curr_end_pos_abs = ImClamp(curr_end_pos_abs, scope_rect.Min, scope_rect.Max);
    }
    bs.BoxSelectRectPrev.Min = ImMin(start_pos_abs, prev_end_pos_abs);
    bs.BoxSelectRectPrev.Max = ImMax(start_pos_abs, prev_end_pos_abs);
    bs.BoxSelectRectCurr.Min = ImMin(start_pos_abs, curr_end_pos_abs);
    bs.BoxSelectRectCurr.Max = ImMax(start_pos_abs, curr_end_pos_abs);

    // Box-select 2D mode detects horizontal changes (vertical ones are already picked by Clipper)
    // Storing an extra rect used by widgets supporting box-select.
    if (.BoxSelect2d in ms_flags) {
        if (bs.BoxSelectRectPrev.Min.x != bs.BoxSelectRectCurr.Min.x || bs.BoxSelectRectPrev.Max.x != bs.BoxSelectRectCurr.Max.x)
        {
            bs.UnclipMode = true;
            bs.UnclipRect = bs.BoxSelectRectPrev; // FIXME-OPT: UnclipRect x coordinates could be intersection of Prev and Curr rect on X axis.
            bs.UnclipRect.Add(bs.BoxSelectRectCurr);
        }
    }

    //AddRect(GetForegroundDrawList(), bs.UnclipRect.Min, bs.UnclipRect.Max, IM_COL32(255,0,0,200), 0.0f, 0, 3.0f);
    //AddRect(GetForegroundDrawList(), bs.BoxSelectRectPrev.Min, bs.BoxSelectRectPrev.Max, IM_COL32(255,0,0,200), 0.0f, 0, 3.0f);
    //AddRect(GetForegroundDrawList(), bs.BoxSelectRectCurr.Min, bs.BoxSelectRectCurr.Max, IM_COL32(0,255,0,200), 0.0f, 0, 1.0f);
    return true;
}

EndBoxSelect :: proc(scope_rect : ^ImRect, ms_flags : ImGuiMultiSelectFlags)
{
    g := GImGui;
    window := g.CurrentWindow;
    bs := &g.BoxSelectState;
    assert(bs.IsActive);
    bs.UnclipMode = false;

    // Render selection rectangle
    bs.EndPosRel = WindowPosAbsToRel(window, ImClamp(g.IO.MousePos, scope_rect.Min, scope_rect.Max)); // Clamp stored position according to current scrolling view
    box_select_r := bs.BoxSelectRectCurr;
    box_select_r.ClipWith(scope_rect);
    AddRectFilled(window.DrawList, box_select_r.Min, box_select_r.Max, GetColorU32(ImGuiCol.SeparatorHovered, 0.30)); // FIXME-MULTISELECT: Styling
    window.DrawList.AddRect(box_select_r.Min, box_select_r.Max, GetColorU32(ImGuiCol.NavCursor)); // FIXME-MULTISELECT: Styling

    // Scroll
    enable_scroll := (.ScopeWindow in ms_flags) && (.BoxSelectNoScroll not_in ms_flags);
    if (enable_scroll)
    {
        scroll_r := scope_rect;
        scroll_r.Expand(-g.FontSize);
        //AddRect(GetForegroundDrawList(), scroll_r.Min, scroll_r.Max, IM_COL32(0, 255, 0, 255));
        if (!scroll_r.Contains(g.IO.MousePos)) {
            BoxSelectScrollWithMouseDrag(bs, window, scroll_r);
        }
    }
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: Multi-Select support
//-------------------------------------------------------------------------
// - DebugLogMultiSelectRequests() [Internal]
// - CalcScopeRect() [Internal]
// - BeginMultiSelect()
// - EndMultiSelect()
// - SetNextItemSelectionUserData()
// - MultiSelectItemHeader() [Internal]
// - MultiSelectItemFooter() [Internal]
// - DebugNodeMultiSelectState() [Internal]
//-------------------------------------------------------------------------

DebugLogMultiSelectRequests :: proc(function : ^u8, io : ^ImGuiMultiSelectIO)
{
    g := GImGui;
    _ = function;
    for &req in io.Requests
    {
        if (req.Type == ImGuiSelectionRequestType_SetAll)    do IMGUI_DEBUG_LOG_SELECTION("[selection] %s: Request: SetAll %d (= %s)\n", function, req.Selected, req.Selected ? "SelectAll" : "Clear");
        if (req.Type == ImGuiSelectionRequestType_SetRange)  do IMGUI_DEBUG_LOG_SELECTION("[selection] %s: Request: SetRange %v..%v (0x%x..0x%x) = %d (dir %d)\n", function, req.RangeFirstItem, req.RangeLastItem, req.RangeFirstItem, req.RangeLastItem, req.Selected, req.RangeDirection);
    }
}

CalcScopeRect :: proc(ms : ^ImGuiMultiSelectTempData, window : ^ImGuiWindow) -> ImRect
{
    g := GImGui;
    if (.ScopeRect in ms.Flags)
    {
        // Warning: this depends on CursorMaxPos so it means to be called by EndMultiSelect() only
        return ImRect(ms.ScopeRectMin, ImMax(window.DC.CursorMaxPos, ms.ScopeRectMin));
    }
    else
    {
        // When a table, pull HostClipRect, which allows us to predict ClipRect before first row/layout is performed. (#7970)
        scope_rect := window.InnerClipRect;
        if (g.CurrentTable != nil) do scope_rect = g.CurrentTable.HostClipRect;

        // Add inner table decoration (#7821) // FIXME: Why not baking in InnerClipRect?
        scope_rect.Min = ImMin(scope_rect.Min + ImVec2{window.DecoInnerSizeX1, window.DecoInnerSizeY1}, scope_rect.Max);
        return scope_rect;
    }
}

// Return ImGuiMultiSelectIO structure.
// Lifetime: don't hold on ImGuiMultiSelectIO* pointers over multiple frames or past any subsequent call to BeginMultiSelect() or EndMultiSelect().
// Passing 'selection_size' and 'items_count' parameters is currently optional.
// - 'selection_size' is useful to disable some shortcut routing: e.g. ImGuiMultiSelectFlags_ClearOnEscape won't claim Escape key when selection_size 0,
//    allowing a first press to clear selection THEN the second press to leave child window and return to parent.
// - 'items_count' is stored in ImGuiMultiSelectIO which makes it a convenient way to pass the information to your ApplyRequest() handler (but you may pass it differently).
// - If they are costly for you to compute (e.g. external intrusive selection without maintaining size), you may avoid them and pass -1.
//   - If you can easily tell if your selection is empty or not, you may pass 0/1, or you may enable ImGuiMultiSelectFlags_ClearOnEscape flag dynamically.
BeginMultiSelect :: proc(flags : ImGuiMultiSelectFlags, selection_size : i32 = -1, items_count : i32 = -1) -> ^ImGuiMultiSelectIO
{
    g := GImGui;
    window := g.CurrentWindow;

    g.MultiSelectTempDataStacked += 1
    if (g.MultiSelectTempDataStacked > g.MultiSelectTempData.Size) {
        g.MultiSelectTempData.resize(g.MultiSelectTempDataStacked, ImGuiMultiSelectTempData());
    }
    ms := &g.MultiSelectTempData[g.MultiSelectTempDataStacked - 1];
    #assert(offset_of(ImGuiMultiSelectTempData, IO) == 0); // Clear() relies on that.
    g.CurrentMultiSelect = ms;
    if ((flags & (ImGuiMultiSelectFlags_ScopeWindow | ImGuiMultiSelectFlags_ScopeRect)) == 0) {
        flags |= ImGuiMultiSelectFlags_ScopeWindow;
    }
    if (.SingleSelect in flags) {
        flags &= ~(ImGuiMultiSelectFlags_BoxSelect2d | ImGuiMultiSelectFlags_BoxSelect1d);
    }
    if (.BoxSelect2d in flags) {
        flags &= ~ImGuiMultiSelectFlags_BoxSelect1d;
    }

    // FIXME: Workaround to the fact we override CursorMaxPos, meaning size measurement are lost. (#8250)
    // They should perhaps be stacked properly?
    if table := g.CurrentTable; table != nil {
        if (table.CurrentColumn != -1) {
            TableEndCell(table); // This is currently safe to call multiple time. If that properly is lost we can extract the "save measurement" part of it.
        }
    }

    // FIXME: BeginFocusScope()
    id := window.IDStack.back();
    ms.Clear();
    ms.FocusScopeId = id;
    ms.Flags = flags;
    ms.IsFocused = (ms.FocusScopeId == g.NavFocusScopeId);
    ms.BackupCursorMaxPos = window.DC.CursorMaxPos;
    window.DC.CursorMaxPos = window.DC.CursorPos;
    ms.ScopeRectMin = window.DC.CursorPos;
    PushFocusScope(ms.FocusScopeId);
    if (.ScopeWindow in flags) {// Mark parent child window as navigable into, with highlight. Assume user will always submit interactive items.
        window.DC.NavLayersActiveMask |= 1 << ImGuiNavLayer_Main;
    }

    // Use copy of keyboard mods at the time of the request, otherwise we would requires mods to be held for an extra frame.
    ms.KeyMods = g.NavJustMovedToId ? (g.NavJustMovedToIsTabbing ? 0 : g.NavJustMovedToKeyMods) : g.IO.KeyMods;
    if (.NoRangeSelect in flags) {
        ms.KeyMods &= ~ImGuiKey.Mod_Shift;
    }

    // Bind storage
    storage := g.MultiSelectStorage.GetOrAddByKey(id);
    storage.ID = id;
    storage.LastFrameActive = g.FrameCount;
    storage.LastSelectionSize = selection_size;
    storage.Window = window;
    ms.Storage = storage;

    // Output to user
    ms.IO.Requests.resize(0);
    ms.IO.RangeSrcItem = storage.RangeSrcItem;
    ms.IO.NavIdItem = storage.NavIdItem;
    ms.IO.NavIdSelected = (storage.NavIdSelected == 1) ? true : false;
    ms.IO.ItemsCount = items_count;

    // Clear when using Navigation to move within the scope
    // (we compare FocusScopeId so it possible to use multiple selections inside a same window)
    request_clear := false;
    request_select_all := false;
    if (g.NavJustMovedToId != 0 && g.NavJustMovedToFocusScopeId == ms.FocusScopeId && g.NavJustMovedToHasSelectionData)
    {
        if (ms.KeyMods & ImGuiKey.Mod_Shift) {
            ms.IsKeyboardSetRange = true;
        }
        if (ms.IsKeyboardSetRange) {
            assert(storage.RangeSrcItem != ImGuiSelectionUserData_Invalid); // Not ready -> could clear?
        }
        if ((ms.KeyMods & (ImGuiKey.Mod_Ctrl | ImGuiKey.Mod_Shift)) == 0 && (flags & (ImGuiMultiSelectFlags_NoAutoClear | ImGuiMultiSelectFlags_NoAutoSelect)) == 0) {
            request_clear = true
        }
    }
    else if (g.NavJustMovedFromFocusScopeId == ms.FocusScopeId)
    {
        // Also clear on leaving scope (may be optional?)
        if ((ms.KeyMods & (ImGuiKey.Mod_Ctrl | ImGuiKey.Mod_Shift)) == 0 && (flags & (ImGuiMultiSelectFlags_NoAutoClear | ImGuiMultiSelectFlags_NoAutoSelect)) == 0) {
            request_clear = true
        }
    }

    // Box-select handling: update active state.
    bs := &g.BoxSelectState;
    if (flags & (ImGuiMultiSelectFlags_BoxSelect1d | ImGuiMultiSelectFlags_BoxSelect2d))
    {
        ms.BoxSelectId = GetID("##BoxSelect");
        if (BeginBoxSelect(CalcScopeRect(ms, window), window, ms.BoxSelectId, flags)) {
            request_clear |= bs.RequestClear;
        }
    }

    if (ms.IsFocused)
    {
        // Shortcut: Clear selection (Escape)
        // - Only claim shortcut if selection is not empty, allowing further presses on Escape to e.g. leave current child window.
        // - Box select also handle Escape and needs to pass an id to bypass ActiveIdUsingAllKeyboardKeys lock.
        if (.ClearOnEscape in flags)
        {
            if (selection_size != 0 || bs.IsActive) {
                if Shortcut(ImGuiKey.Escape, ImGuiInputFlags_None, bs.IsActive ? bs.ID : 0)
                {
                    request_clear = true;
                    if (bs.IsActive) do BoxSelectDeactivateDrag(bs);
                }
            }
        }

        // Shortcut: Select all (CTRL+A)
        if (!(.SingleSelect in flags) && !(.NoSelectAll in flags)) {
            if (Shortcut(ImGuiKey.Mod_Ctrl | ImGuiKey.A))   do request_select_all = true
        }
    }

    if (request_clear || request_select_all)
    {
        MultiSelectAddSetAll(ms, request_select_all);
        if (!request_select_all) do storage.LastSelectionSize = 0;
    }
    ms.LoopRequestSetAll = request_select_all ? 1 : request_clear ? 0 : -1;
    ms.LastSubmittedItem = ImGuiSelectionUserData_Invalid;

    if (.EventSelection in g.DebugLogFlags) {
        DebugLogMultiSelectRequests("BeginMultiSelect", &ms.IO);
    }

    return &ms.IO;
}

// Return updated ImGuiMultiSelectIO structure.
// Lifetime: don't hold on ImGuiMultiSelectIO* pointers over multiple frames or past any subsequent call to BeginMultiSelect() or EndMultiSelect().
EndMultiSelect :: proc() -> ^ImGuiMultiSelectIO
{
    g := GImGui;
    ms := g.CurrentMultiSelect;
    storage := ms.Storage;
    window := g.CurrentWindow;
    IM_ASSERT_USER_ERROR(ms.FocusScopeId == g.CurrentFocusScopeId, "EndMultiSelect() FocusScope mismatch!");
    assert(g.CurrentMultiSelect != nil && storage.Window == g.CurrentWindow);
    assert(g.MultiSelectTempDataStacked > 0 && &g.MultiSelectTempData[g.MultiSelectTempDataStacked - 1] == g.CurrentMultiSelect);

    scope_rect := CalcScopeRect(ms, window);
    if (ms.IsFocused)
    {
        // We currently don't allow user code to modify RangeSrcItem by writing to BeginIO's version, but that would be an easy change here.
        if (ms.IO.RangeSrcReset || (ms.RangeSrcPassedBy == false && ms.IO.RangeSrcItem != ImGuiSelectionUserData_Invalid)) // Can't read storage.RangeSrcItem here -> we want the state at begining of the scope (see tests for easy failure)
        {
            IMGUI_DEBUG_LOG_SELECTION("[selection] EndMultiSelect: Reset RangeSrcItem.\n"); // Will set be to NavId.
            storage.RangeSrcItem = ImGuiSelectionUserData_Invalid;
        }
        if (ms.NavIdPassedBy == false && storage.NavIdItem != ImGuiSelectionUserData_Invalid)
        {
            IMGUI_DEBUG_LOG_SELECTION("[selection] EndMultiSelect: Reset NavIdItem.\n");
            storage.NavIdItem = ImGuiSelectionUserData_Invalid;
            storage.NavIdSelected = -1;
        }

        if ((ms.Flags & (ImGuiMultiSelectFlags_BoxSelect1d | ImGuiMultiSelectFlags_BoxSelect2d)) && GetBoxSelectState(ms.BoxSelectId)) {
            EndBoxSelect(scope_rect, ms.Flags);
        }
    }

    if (ms.IsEndIO == false)   do ms.IO.Requests.resize(0)

    // Clear selection when clicking void?
    // We specifically test for IsMouseDragPastThreshold(0) == false to allow box-selection!
    // The InnerRect test is necessary for non-child/decorated windows.
    scope_hovered := IsWindowHovered() && window.InnerRect.Contains(g.IO.MousePos);
    if (scope_hovered && (.ScopeRect in ms.Flags)) {
        scope_hovered &= scope_rect.Contains(g.IO.MousePos);
    }
    if (scope_hovered && g.HoveredId == 0 && g.ActiveId == 0)
    {
        if (ms.Flags & (ImGuiMultiSelectFlags_BoxSelect1d | ImGuiMultiSelectFlags_BoxSelect2d))
        {
            if (!g.BoxSelectState.IsActive && !g.BoxSelectState.IsStarting && g.IO.MouseClickedCount[0] == 1)
            {
                BoxSelectPreStartDrag(ms.BoxSelectId, ImGuiSelectionUserData_Invalid);
                FocusWindow(window, ImGuiFocusRequestFlags_UnlessBelowModal);
                SetHoveredID(ms.BoxSelectId);
                if (.ScopeRect in ms.Flags) {
                    SetNavID(0, ImGuiNavLayer_Main, ms.FocusScopeId, ImRect{ _v = {g.IO.MousePos, g.IO.MousePos}}); // Automatically switch FocusScope for initial click from void to box-select.
                }
            }
        }

        if (.ClearOnClickVoid in ms.Flags) {
            if (IsMouseReleased(0) && IsMouseDragPastThreshold(0) == false && g.IO.KeyMods == ImGuiKey.Mod_None) {
                MultiSelectAddSetAll(ms, false);
            }
        }
    }

    // Courtesy nav wrapping helper flag
    if (.NavWrapX in ms.Flags)
    {
        assert(.ScopeWindow in ms.Flags); // Only supported at window scope
        NavMoveRequestTryWrapping(GetCurrentWindow(), ImGuiNavMoveFlags_WrapX);
    }

    // Unwind
    window.DC.CursorMaxPos = ImMax(ms.BackupCursorMaxPos, window.DC.CursorMaxPos);
    PopFocusScope();

    if (.EventSelection in g.DebugLogFlags) {
        DebugLogMultiSelectRequests("EndMultiSelect", &ms.IO);
    }

    ms.FocusScopeId = 0;
    ms.Flags = ImGuiMultiSelectFlags_None;
    g.MultiSelectTempDataStacked -= 1
    g.CurrentMultiSelect = (g.MultiSelectTempDataStacked > 0) ? &g.MultiSelectTempData[g.MultiSelectTempDataStacked - 1] : nil;

    return &ms.IO;
}

SetNextItemSelectionUserData :: proc(selection_user_data : ImGuiSelectionUserData)
{
    // Note that flags will be cleared by ItemAdd(), so it's only useful for Navigation code!
    // This designed so widgets can also cheaply set this before calling ItemAdd(), so we are not tied to MultiSelect api.
    g := GImGui;
    g.NextItemData.SelectionUserData = selection_user_data;
    g.NextItemData.FocusScopeId = g.CurrentFocusScopeId;

    if ms := g.CurrentMultiSelect; ms != nil
    {
        // Auto updating RangeSrcPassedBy for cases were clipper is not used (done before ItemAdd() clipping)
        g.NextItemData.ItemFlags |= ImGuiItemFlags_HasSelectionUserData | ImGuiItemFlags_IsMultiSelect;
        if (ms.IO.RangeSrcItem == selection_user_data) {
            ms.RangeSrcPassedBy = true;
        }
    }
    else
    {
        g.NextItemData.ItemFlags |= ImGuiItemFlags_HasSelectionUserData;
    }
}

// In charge of:
// - Applying SetAll for submitted items.
// - Applying SetRange for submitted items and record end points.
// - Altering button behavior flags to facilitate use with drag and drop.
MultiSelectItemHeader :: proc(id : ImGuiID, p_selected : ^bool, p_button_flags : ^ImGuiButtonFlags)
{
    g := GImGui;
    ms := g.CurrentMultiSelect;

    selected := p_selected^;
    if (ms.IsFocused)
    {
        storage := ms.Storage;
        item_data := g.NextItemData.SelectionUserData;
        assert(g.NextItemData.FocusScopeId == g.CurrentFocusScopeId, "Forgot to call SetNextItemSelectionUserData() prior to item, required in BeginMultiSelect()/EndMultiSelect() scope");

        // Apply SetAll (Clear/SelectAll) requests requested by BeginMultiSelect().
        // This is only useful if the user hasn't processed them already, and this only works if the user isn't using the clipper.
        // If you are using a clipper you need to process the SetAll request after calling BeginMultiSelect()
        if (ms.LoopRequestSetAll != -1) do selected = (ms.LoopRequestSetAll == 1);

        // When using SHIFT+Nav: because it can incur scrolling we cannot afford a frame of lag with the selection highlight (otherwise scrolling would happen before selection)
        // For this to work, we need someone to set 'RangeSrcPassedBy = true' at some point (either clipper either SetNextItemSelectionUserData() function)
        if (ms.IsKeyboardSetRange)
        {
            assert(id != 0 && (ms.KeyMods & ImGuiKeyChord(ImGuiKey.Mod_Shift)) != nil);
            is_range_dst := (ms.RangeDstPassedBy == false) && g.NavJustMovedToId == id;     // Assume that g.NavJustMovedToId is not clipped.
            if (is_range_dst) do ms.RangeDstPassedBy = true;
            if (is_range_dst && storage.RangeSrcItem == ImGuiSelectionUserData_Invalid) // If we don't have RangeSrc, assign RangeSrc = RangeDst
            {
                storage.RangeSrcItem = item_data;
                storage.RangeSelected = selected ? 1 : 0;
            }
            is_range_src := storage.RangeSrcItem == item_data;
            if (is_range_src || is_range_dst || ms.RangeSrcPassedBy != ms.RangeDstPassedBy)
            {
                // Apply range-select value to visible items
                assert(storage.RangeSrcItem != ImGuiSelectionUserData_Invalid && storage.RangeSelected != -1);
                selected = (storage.RangeSelected != 0);
            }
            else if ((ms.KeyMods & ImGuiKeyChord(ImGuiKey.Mod_Ctrl)) == nil && .NoAutoClear not_in ms.Flags)
            {
                // Clear other items
                selected = false;
            }
        }
        p_selected^ = selected;
    }

    // Alter button behavior flags
    // To handle drag and drop of multiple items we need to avoid clearing selection on click.
    // Enabling this test makes actions using CTRL+SHIFT delay their effect on MouseUp which is annoying, but it allows drag and drop of multiple items.
    if (p_button_flags != nil)
    {
        button_flags := p_button_flags^;
        button_flags |= ImGuiButtonFlags_NoHoveredOnFocus;
        if ((!selected || (g.ActiveId == id && g.ActiveIdHasBeenPressedBefore)) && !(.SelectOnClickRelease in ms.Flags)) {
            button_flags = (button_flags | ImGuiButtonFlags_PressedOnClick) & ~ImGuiButtonFlags_PressedOnClickRelease;
        }
        else {
            button_flags |= ImGuiButtonFlags_PressedOnClickRelease;
        }
        p_button_flags^ = button_flags;
    }
}

// In charge of:
// - Auto-select on navigation.
// - Box-select toggle handling.
// - Right-click handling.
// - Altering selection based on Ctrl/Shift modifiers, both for keyboard and mouse.
// - Record current selection state for RangeSrc
// This is all rather complex, best to run and refer to "widgets_multiselect_xxx" tests in imgui_test_suite.
MultiSelectItemFooter :: proc(id : ImGuiID, p_selected : ^bool, p_pressed : ^bool)
{
    g := GImGui;
    window := g.CurrentWindow;

    selected := p_selected^;
    pressed := p_pressed^;
    ms := g.CurrentMultiSelect;
    storage := ms.Storage;
    if (pressed)   do ms.IsFocused = true

    hovered := false;
    if (.HoveredRect in g.LastItemData.StatusFlags) {
        hovered = IsItemHovered(.AllowWhenBlockedByPopup);
    }
    if (!ms.IsFocused && !hovered)   do return

    item_data := g.NextItemData.SelectionUserData;

    flags := ms.Flags;
    is_singleselect := .SingleSelect in flags
    is_ctrl := (ms.KeyMods & ImGuiKey.Mod_Ctrl) != nil;
    is_shift := (ms.KeyMods & ImGuiKey.Mod_Shift) != nil;

    apply_to_range_src := false;

    if (g.NavId == id && storage.RangeSrcItem == ImGuiSelectionUserData_Invalid)   do apply_to_range_src = true
    if (ms.IsEndIO == false)
    {
        clear(&ms.IO.Requests);
        ms.IsEndIO = true;
    }

    // Auto-select as you navigate a list
    if (g.NavJustMovedToId == id)
    {
        if (.NoAutoSelect not_in flags)
        {
            if (is_ctrl && is_shift)   do pressed = true
            else if (!is_ctrl)  {
                selected = true
                pressed = true
            }
        }
        else
        {
            // With NoAutoSelect, using Shift+keyboard performs a write/copy
            if (is_shift)   do pressed = true
            else if (!is_ctrl) do apply_to_range_src = true; // Since if (pressed) {} main block is not running we update this
        }
    }

    if (apply_to_range_src)
    {
        storage.RangeSrcItem = item_data;
        storage.RangeSelected = selected; // Will be updated at the end of this function anyway.
    }

    // Box-select toggle handling
    if (ms.BoxSelectId != 0) {
        if bs := GetBoxSelectState(ms.BoxSelectId); bs != nil
        {
            rect_overlap_curr := bs.BoxSelectRectCurr.Overlaps(g.LastItemData.Rect);
            rect_overlap_prev := bs.BoxSelectRectPrev.Overlaps(g.LastItemData.Rect);
            if ((rect_overlap_curr && !rect_overlap_prev && !selected) || (rect_overlap_prev && !rect_overlap_curr))
            {
                if (storage.LastSelectionSize <= 0 && bs.IsStartedSetNavIdOnce)
                {
                    pressed = true; // First item act as a pressed: code below will emit selection request and set NavId (whatever we emit here will be overridden anyway)
                    bs.IsStartedSetNavIdOnce = false;
                }
                else
                {
                    selected = !selected;
                    MultiSelectAddSetRange(ms, selected, +1, item_data, item_data);
                }
                storage.LastSelectionSize = ImMax(storage.LastSelectionSize + 1, 1);
            }
        }
    }

    // Right-click handling.
    // FIXME-MULTISELECT: Currently filtered out by ImGuiMultiSelectFlags_NoAutoSelect but maybe should be moved to Selectable(). See https://github.com/ocornut/imgui/pull/5816
    if (hovered && IsMouseClicked(1) && (.NoAutoSelect not_in flags))
    {
        if (g.ActiveId != 0 && g.ActiveId != id)   do ClearActiveID()
        SetFocusID(id, window);
        if (!pressed && !selected)
        {
            pressed = true;
            is_ctrl = false
            is_shift = false;
        }
    }

    // Unlike Space, Enter doesn't alter selection (but can still return a press) unless current item is not selected.
    // The later, "unless current item is not select", may become optional? It seems like a better default if Enter doesn't necessarily open something
    // (unlike e.g. Windows explorer). For use case where Enter always open something, we might decide to make this optional?
    enter_pressed := pressed && (g.NavActivateId == id) && (.PreferInput in g.NavActivateFlags);

    // Alter selection
    if (pressed && (!enter_pressed || !selected))
    {
        // Box-select
        input_source := (g.NavJustMovedToId == id || g.NavActivateId == id) ? g.NavInputSource : .Mouse;
        if (flags & (ImGuiMultiSelectFlags_BoxSelect1d | ImGuiMultiSelectFlags_BoxSelect2d)) {
            if (selected == false && !g.BoxSelectState.IsActive && !g.BoxSelectState.IsStarting && input_source == .Mouse && g.IO.MouseClickedCount[0] == 1) {
                BoxSelectPreStartDrag(ms.BoxSelectId, item_data);
            }
        }

        //----------------------------------------------------------------------------------------
        // ACTION                      | Begin  | Pressed/Activated  | End
        //----------------------------------------------------------------------------------------
        // Keys Navigated:             | Clear  | Src=item, Sel=1               SetRange 1
        // Keys Navigated: Ctrl        | n/a    | n/a
        // Keys Navigated:      Shift  | n/a    | Dst=item, Sel=1,   => Clear + SetRange 1
        // Keys Navigated: Ctrl+Shift  | n/a    | Dst=item, Sel=Src  => Clear + SetRange Src-Dst
        // Keys Activated:             | n/a    | Src=item, Sel=1    => Clear + SetRange 1
        // Keys Activated: Ctrl        | n/a    | Src=item, Sel=!Sel =>         SetSange 1
        // Keys Activated:      Shift  | n/a    | Dst=item, Sel=1    => Clear + SetSange 1
        //----------------------------------------------------------------------------------------
        // Mouse Pressed:              | n/a    | Src=item, Sel=1,   => Clear + SetRange 1
        // Mouse Pressed:  Ctrl        | n/a    | Src=item, Sel=!Sel =>         SetRange 1
        // Mouse Pressed:       Shift  | n/a    | Dst=item, Sel=1,   => Clear + SetRange 1
        // Mouse Pressed:  Ctrl+Shift  | n/a    | Dst=item, Sel=!Sel =>         SetRange Src-Dst
        //----------------------------------------------------------------------------------------

        if ((.NoAutoClear not_in flags))
        {
            request_clear := false;
            if (is_singleselect) {
                request_clear = true
            }
            else if ((input_source == .Mouse || g.NavActivateId == id) && !is_ctrl) {
                request_clear = (.NoAutoClearOnReselect in flags) ? !selected : true;
            }
            else if ((input_source == .Keyboard || input_source == .Gamepad) && is_shift && !is_ctrl) {
                request_clear = true; // With is_shift==false the RequestClear was done in BeginIO, not necessary to do again.
            }
            if (request_clear) {
                MultiSelectAddSetAll(ms, false);
            }
        }

        range_direction : i32
        range_selected : bool
        if (is_shift && !is_singleselect)
        {
            //assert(storage.HasRangeSrc && storage.HasRangeValue);
            if (storage.RangeSrcItem == ImGuiSelectionUserData_Invalid) {
                storage.RangeSrcItem = item_data;
            }
            if ((.NoAutoSelect not_in flags))
            {
                // Shift+Arrow always select
                // Ctrl+Shift+Arrow copy source selection state (already stored by BeginMultiSelect() in storage.RangeSelected)
                range_selected = (is_ctrl && storage.RangeSelected != -1) ? (storage.RangeSelected != 0) : true;
            }
            else
            {
                // Shift+Arrow copy source selection state
                // Shift+Click always copy from target selection state
                if (ms.IsKeyboardSetRange) {
                    range_selected = (storage.RangeSelected != -1) ? (storage.RangeSelected != 0) : true;
                }
                else {
                    range_selected = !selected;
                }
            }
            range_direction = ms.RangeSrcPassedBy ? +1 : -1;
        }
        else
        {
            // Ctrl inverts selection, otherwise always select
            if ((.NoAutoSelect not_in flags)) {
                selected = is_ctrl ? !selected : true;
            }
            else {
                selected = !selected;
            }
            storage.RangeSrcItem = item_data;
            range_selected = selected;
            range_direction = +1;
        }
        MultiSelectAddSetRange(ms, range_selected, range_direction, storage.RangeSrcItem, item_data);
    }

    // Update/store the selection state of the Source item (used by CTRL+SHIFT, when Source is unselected we perform a range unselect)
    if (storage.RangeSrcItem == item_data) {
        storage.RangeSelected = selected ? 1 : 0;
    }

    // Update/store the selection state of focused item
    if (g.NavId == id)
    {
        storage.NavIdItem = item_data;
        storage.NavIdSelected = selected ? 1 : 0;
    }
    if (storage.NavIdItem == item_data)   do ms.NavIdPassedBy = true
    ms.LastSubmittedItem = item_data;

    p_selected^ = selected;
    p_pressed^ = pressed;
}

MultiSelectAddSetAll :: proc(ms : ^ImGuiMultiSelectTempData, selected : bool)
{
    req := { ImGuiSelectionRequestType_SetAll, selected, 0, ImGuiSelectionUserData_Invalid, ImGuiSelectionUserData_Invalid };
    ms.IO.Requests.resize(0);      // Can always clear previous requests
    ms.IO.Requests.append(req); // Add new request
}

MultiSelectAddSetRange :: proc(ms : ^ImGuiMultiSelectTempData, selected : bool, range_dir : i32, first_item : ImGuiSelectionUserData, last_item : ImGuiSelectionUserData)
{
    // Merge contiguous spans into same request (unless NoRangeSelect is set which guarantees single-item ranges)
    if (len(ms.IO.Requests) > 0 && first_item == last_item && (.NoRangeSelect not_in ms.Flags))
    {
        prev := &ms.IO.Requests.Data[len(ms.IO.Requests) - 1];
        if (prev.Type == ImGuiSelectionRequestType_SetRange && prev.RangeLastItem == ms.LastSubmittedItem && prev.Selected == selected)
        {
            prev.RangeLastItem = last_item;
            return;
        }
    }

    req := { ImGuiSelectionRequestType_SetRange, selected, cast(i8) range_dir, (range_dir > 0) ? first_item : last_item, (range_dir > 0) ? last_item : first_item };
    ms.IO.Requests.append(req); // Add new request
}

DebugNodeMultiSelectState :: proc(storage : ^ImGuiMultiSelectState)
{
when !(IMGUI_DISABLE_DEBUG_TOOLS) {
    is_active := (storage.LastFrameActive >= GetFrameCount() - 2); // Note that fully clipped early out scrolling tables will appear as inactive here.
    if (!is_active) { PushStyleColor(ImGuiCol.Text, GetStyleColorVec4(ImGuiCol.TextDisabled)); }
    open := TreeNode(cast(rawptr)storage.ID, "MultiSelect 0x%08X in '%s'%s", storage.ID, storage.Window ? storage.Window.Name : "N/A", is_active ? "" : " *Inactive*");
    if (!is_active) { PopStyleColor(); }
    if (!open)   do return
    Text("RangeSrcItem = %v (0x%x), RangeSelected = %d", storage.RangeSrcItem, storage.RangeSrcItem, storage.RangeSelected);
    Text("NavIdItem = %v (0x%x), NavIdSelected = %d", storage.NavIdItem, storage.NavIdItem, storage.NavIdSelected);
    Text("LastSelectionSize = %d", storage.LastSelectionSize); // Provided by user
    TreePop();
} else {
    _ = storage;
}
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: Multi-Select helpers
//-------------------------------------------------------------------------
// - ImGuiSelectionBasicStorage
// - ImGuiSelectionExternalStorage
//-------------------------------------------------------------------------

init_ImGuiSelectionBasicStorage :: proc(this : ^ImGuiSelectionBasicStorage)
{
    len(this) = 0;
    this.PreserveOrder = false;
    this.UserData = nil;
    this.AdapterIndexToStorageId = proc(_ : ^ImGuiSelectionBasicStorage, idx : i32) { return ImGuiID(idx); };
    this._SelectionOrder = 1; // Always >0
}

// [forward declared comment]:
// Clear all input and output.
ImGuiSelectionBasicStorage_Clear :: proc(this : ^ImGuiSelectionBasicStorage)
{
    Size = 0;
    _SelectionOrder = 1; // Always >0
    _Storage.Data.resize(0);
}

// [forward declared comment]:
// Swap two selections
Swap :: proc(this : ^ImGuiSelectionBasicStorage, r : ^ImGuiSelectionBasicStorage)
{
    ImSwap(Size, r.Size);
    ImSwap(_SelectionOrder, r._SelectionOrder);
    _Storage.Data.swap(r._Storage.Data);
}

// [forward declared comment]:
// Query if an item id is in selection.
Contains_sbs :: proc(this : ^ImGuiSelectionBasicStorage, id : ImGuiID) -> bool
{
    return GetInt(&this._Storage, id, 0) != 0;
}

PairComparerByValueInt :: proc(lhs, rhs : rawptr) -> i32
{
    lhs_v := (cast(^ImGuiStoragePair)lhs).val_i;
    rhs_v := (cast(^ImGuiStoragePair)rhs).val_i;
    return (lhs_v > rhs_v ? +1 : lhs_v < rhs_v ? -1 : 0);
}

// GetNextSelectedItem() is an abstraction allowing us to change our underlying actual storage system without impacting user.
// (e.g. store unselected vs compact down, compact down on demand, use raw ImVector<ImGuiID> instead of ImGuiStorage...)
// [forward declared comment]:
// Iterate selection with 'void* it = NULL; ImGuiID id; while (selection.GetNextSelectedItem(&it, &id)) { ... }'
GetNextSelectedItem :: proc(this : ^ImGuiSelectionBasicStorage, opaque_it : ^rawptr, out_id : ^ImGuiID) -> bool
{
    it := cast(^ImGuiStoragePair)opaque_it^;
    it_end := ed(this._Storage.Data);
    if (PreserveOrder && it == nil && it_end != nil) {
        ImQsort(_Storage.Data.Data, cast(int) _Storage.Data.Size, size_of(ImGuiStoragePair), PairComparerByValueInt); // ~ImGuiStorage::BuildSortByValueInt()
    }
    if (it == nil)   do it = _Storage.Data.Data
    assert(it >= _Storage.Data.Data && it <= it_end);
    if (it != it_end) {
        for (it.val_i == 0 && it < it_end) {
            it += 1;
        }
    }
    has_more := (it != it_end);
    opaque_it^ = has_more ? cast(^rawptr)(it + 1) : cast(^rawptr)(it);
    out_id^ = has_more ? it.key : 0;
    if (PreserveOrder && !has_more)   do _Storage.BuildSortByKey()
    return has_more;
}

// [forward declared comment]:
// Add/remove an item from selection (generally done by ApplyRequests() function)
SetItemSelected :: proc(this : ^ImGuiSelectionBasicStorage, id : ImGuiID, selected : bool)
{
    p_int := this._Storage.GetIntRef(id, 0);
    if (selected && p_int^ == 0) { this._SelectionOrder += 1; p_int^ = this._SelectionOrder; len(this) += 1; }
    else if (!selected && p_int^ != 0) { p_int^ = 0; len(this) -= 1; }
}

// Optimized for batch edits (with same value of 'selected')
ImGuiSelectionBasicStorage_BatchSetItemSelected :: proc(selection : ^ImGuiSelectionBasicStorage, id : ImGuiID, selected : bool, size_before_amends : i32, selection_order : i32)
{
    storage := &selection._Storage;
    it := ImLowerBound(storage.Data.Data, storage.Data.Data + size_before_amends, id);
    is_contained := (it != storage.Data.Data + size_before_amends) && (it.key == id);
    if (selected == (is_contained && it.val_i != 0))   do return
    if (selected && !is_contained) {
        storage.Data.append(ImGuiStoragePair(id, selection_order)); // Push unsorted at end of vector, will be sorted in SelectionMultiAmendsFinish()
    }
    else if (is_contained) {
        it.val_i = selected ? selection_order : 0; // Modify in-place.
    }
    len(selection) += selected ? +1 : -1;
}

ImGuiSelectionBasicStorage_BatchFinish :: proc(selection : ^ImGuiSelectionBasicStorage, selected : bool, size_before_amends : i32)
{
    storage := &selection._Storage;
    if (selected && len(selection) != size_before_amends) {
        storage.BuildSortByKey(); // When done selecting: sort everything
    }
}

// Apply requests coming from BeginMultiSelect() and EndMultiSelect().
// - Enable 'Demo.Tools.Debug Log.Selection' to see selection requests as they happen.
// - Honoring SetRange requests requires that you can iterate/interpolate between RangeFirstItem and RangeLastItem.
//   - In this demo we often submit indices to SetNextItemSelectionUserData() + store the same indices in persistent selection.
//   - Your code may do differently. If you store pointers or objects ID in ImGuiSelectionUserData you may need to perform
//     a lookup in order to have some way to iterate/interpolate between two items.
// - A full-featured application is likely to allow search/filtering which is likely to lead to using indices
//   and constructing a view index <> object id/ptr data structure anyway.
// WHEN YOUR APPLICATION SETTLES ON A CHOICE, YOU WILL PROBABLY PREFER TO GET RID OF THIS UNNECESSARY 'ImGuiSelectionBasicStorage' INDIRECTION LOGIC.
// Notice that with the simplest adapter (using indices everywhere), all functions return their parameters.
// The most simple implementation (using indices everywhere) would look like:
//   for &req in ms_io.Requests
//   {
//      if (req.Type == ImGuiSelectionRequestType_SetAll)    { Clear(); if (req.Selected) { for (int n = 0; n < items_count; n++) { SetItemSelected(n, true); } }
//      if (req.Type == ImGuiSelectionRequestType_SetRange)  { for (int n = cast(int) ms_io.RangeFirstItem; n <= cast(int) ms_io.RangeLastItem; n++) { SetItemSelected(n, ms_io.Selected); } }
//   }
// [forward declared comment]:
// Apply selection requests by using AdapterSetItemSelected() calls
ApplyRequests_basic :: proc(this : ^ImGuiSelectionBasicStorage, ms_io : ^ImGuiMultiSelectIO)
{
    // For convenience we obtain ItemsCount as passed to BeginMultiSelect(), which is optional.
    // It makes sense when using ImGuiSelectionBasicStorage to simply pass your items count to BeginMultiSelect().
    // Other scheme may handle SetAll differently.
    assert(ms_io.ItemsCount != -1, "Missing value for items_count in BeginMultiSelect() call!");
    assert(AdapterIndexToStorageId != nil);

    // This is optimized/specialized to cope with very large selections (e.g. 100k+ items)
    // - A simpler version could call SetItemSelected() directly instead of ImGuiSelectionBasicStorage_BatchSetItemSelected() + ImGuiSelectionBasicStorage_BatchFinish().
    // - Optimized select can append unsorted, then sort in a second pass. Optimized unselect can clear in-place then compact in a second pass.
    // - A more optimal version wouldn't even use ImGuiStorage but directly a ImVector<ImGuiID> to reduce bandwidth, but this is a reasonable trade off to reuse code.
    // - There are many ways this could be better optimized. The worse case scenario being: using BoxSelect2d in a grid, box-select scrolling down while wiggling
    //   left and right: it affects coarse clipping + can emit multiple SetRange with 1 item each.)
    // FIXME-OPT: For each block of consecutive SetRange request:
    // - add all requests to a sorted list, store ID, selected, offset in ImGuiStorage.
    // - rewrite sorted storage a single time.
    for &req in ms_io.Requests
    {
        if (req.Type == ImGuiSelectionRequestType_SetAll)
        {
            Clear();
            if (req.Selected)
            {
                _Storage.Data.reserve(ms_io.ItemsCount);
                size_before_amends := len(_Storage.Data);
                for idx := 0; idx < ms_io.ItemsCount; idx, _SelectionOrder = idx + 1, _SelectionOrder + 1 {
                    ImGuiSelectionBasicStorage_BatchSetItemSelected(this, GetStorageIdFromIndex(idx), req.Selected, size_before_amends, _SelectionOrder);
                }
                ImGuiSelectionBasicStorage_BatchFinish(this, req.Selected, size_before_amends);
            }
        }
        else if (req.Type == ImGuiSelectionRequestType_SetRange)
        {
            selection_changes := cast(i32) req.RangeLastItem - cast(i32) req.RangeFirstItem + 1;
            //g := &*GImGui; IMGUI_DEBUG_LOG_SELECTION("Req %d/%d: set %d to %d\n", ms_io.Requests.index_from_ptr(&req), ms_io.Requests.Size, selection_changes, req.Selected);
            if (selection_changes == 1 || (selection_changes < Size / 100))
            {
                // Multiple sorted insertion + copy likely to be faster.
                // Technically we could do a single copy with a little more work (sort sequential SetRange requests)
                for idx := cast(i32) req.RangeFirstItem; idx <= cast(i32) req.RangeLastItem; idx += 1 {
                    SetItemSelected(GetStorageIdFromIndex(idx), req.Selected);
                }
            }
            else
            {
                // Append insertion + single sort likely be faster.
                // Use req.RangeDirection to set order field so that shift+clicking from 1 to 5 is different than shift+clicking from 5 to 1
                size_before_amends := len(_Storage.Data);
                selection_order := _SelectionOrder + ((req.RangeDirection < 0) ? selection_changes - 1 : 0);
                for idx := cast(i32) req.RangeFirstItem; idx <= cast(i32) req.RangeLastItem; idx, selection_order  = idx + 1, selection_order + req.RangeDirection {
                    ImGuiSelectionBasicStorage_BatchSetItemSelected(this, GetStorageIdFromIndex(idx), req.Selected, size_before_amends, selection_order);
                }
                if (req.Selected) {
                    _SelectionOrder += selection_changes;
                }
                ImGuiSelectionBasicStorage_BatchFinish(this, req.Selected, size_before_amends);
            }
        }
    }
}

//-------------------------------------------------------------------------

init_ImGuiSelectionExternalStorage :: proc(this : ^ImGuiSelectionExternalStorage)
{
    UserData = nil;
    AdapterSetItemSelected = nil;
}

// Apply requests coming from BeginMultiSelect() and EndMultiSelect().
// We also pull 'ms_io.ItemsCount' as passed for BeginMultiSelect() for consistency with ImGuiSelectionBasicStorage
// This makes no assumption about underlying storage.
// [forward declared comment]:
// Apply selection requests by using AdapterSetItemSelected() calls
ApplyRequests_ex :: proc(this : ^ImGuiSelectionExternalStorage, ms_io : ^ImGuiMultiSelectIO)
{
    assert(AdapterSetItemSelected);
    for &req in ms_io.Requests
    {
        if (req.Type == ImGuiSelectionRequestType_SetAll) {
            for idx := 0; idx < ms_io.ItemsCount; idx += 1 {
                AdapterSetItemSelected(this, idx, req.Selected);
            }
        }
        if (req.Type == ImGuiSelectionRequestType_SetRange) {
            for idx := cast(i32) req.RangeFirstItem; idx <= cast(i32) req.RangeLastItem; idx += 1 {
                AdapterSetItemSelected(this, idx, req.Selected);
            }
        }
    }
}

ApplyRequests :: proc { ApplyRequests_ex, ApplyRequests_basic }

//-------------------------------------------------------------------------
// [SECTION] Widgets: ListBox
//-------------------------------------------------------------------------
// - BeginListBox()
// - EndListBox()
// - ListBox()
//-------------------------------------------------------------------------

// This is essentially a thin wrapper to using BeginChild/EndChild with the ImGuiChildFlags_FrameStyle flag for stylistic changes + displaying a label.
// This handle some subtleties with capturing info from the label.
// If you don't need a label you can pretty much directly use ImGui::BeginChild() with ImGuiChildFlags_FrameStyle.
// Tip: To have a list filling the entire window width, use size.x = -FLT_MIN and pass an non-visible label e.g. "##empty"
// Tip: If your vertical size is calculated from an item count (e.g. 10 * item_height) consider adding a fractional part to facilitate seeing scrolling boundaries (e.g. 10.5f * item_height).
// [forward declared comment]:
// open a framed scrolling region
BeginListBox :: proc(label : string, size_arg : ImVec2 = {}) -> bool
{
    g := GImGui;
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    style := &g.Style;
    id := GetID(label);
    label_size := CalcTextSize(label, nil, true);

    // Size default to hold ~7.25 items.
    // Fractional number of items helps seeing that we can scroll down/up without looking at scrollbar.
    size := ImTrunc(CalcItemSize(size_arg, CalcItemWidth(), GetTextLineHeightWithSpacing() * 7.25 + style.FramePadding.y * 2.0));
    frame_size := ImVec2{size.x, ImMax(size.y, label_size.y)};
    frame_bb := ImRect{ _v = {window.DC.CursorPos, window.DC.CursorPos + frame_size}};
    bb := ImRect(frame_bb.Min, frame_bb.Max + ImVec2{label_size.x > 0.0 ? style.ItemInnerSpacing.x + label_size.x : 0.0, 0.0});
    g.NextItemData.ClearFlags();

    if (!IsRectVisible(bb.Min, bb.Max))
    {
        ItemSize(bb.GetSize(), style.FramePadding.y);
        ItemAdd(bb, 0, &frame_bb);
        g.NextWindowData.ClearFlags(); // We behave like Begin() and need to consume those values
        return false;
    }

    // FIXME-OPT: We could omit the BeginGroup() if label_size.x == 0.0f but would need to omit the EndGroup() as well.
    BeginGroup();
    if (label_size.x > 0.0)
    {
        label_pos := ImVec2{frame_bb.Max.x + style.ItemInnerSpacing.x, frame_bb.Min.y + style.FramePadding.y};
        RenderText(label_pos, label);
        window.DC.CursorMaxPos = ImMax(window.DC.CursorMaxPos, label_pos + label_size);
        AlignTextToFramePadding();
    }

    BeginChild(id, frame_bb.GetSize(), ImGuiChildFlags_FrameStyle);
    return true;
}

// [forward declared comment]:
// only call EndListBox() if BeginListBox() returned true!
EndListBox :: proc()
{
    g := GImGui;
    window := g.CurrentWindow;
    assert((.ChildWindow in window.Flags), "Mismatched BeginListBox/EndListBox calls. Did you test the return value of BeginListBox?");
    _ = window;

    EndChild();
    EndGroup(); // This is only required to be able to do IsItemXXX query on the whole ListBox including label
}

ListBox_basic :: proc(label : string, current_item : ^i32, items : ^[]u8, items_count : i32, height_items : i32) -> bool
{
    value_changed := ListBox(label, current_item, Items_ArrayGetter, cast(rawptr) items, items_count, height_items);
    return value_changed;
}

// This is merely a helper around BeginListBox(), EndListBox().
// Considering using those directly to submit custom data or store selection differently.
ListBox_ex :: proc(label : string, current_item : ^i32, getter : proc(user_data : rawptr, idx : i32) -> ^u8, user_data : rawptr, items_count : i32, height_in_items : i32) -> bool
{
    g := GImGui;

    // Calculate size from "height_in_items"
    if (height_in_items < 0) {
        height_in_items = ImMin(items_count, 7);
    }
    height_in_items_f := height_in_items + 0.25;
    size := ImVec2(0.0, ImTrunc(GetTextLineHeightWithSpacing() * height_in_items_f + g.Style.FramePadding.y * 2.0));

    if (!BeginListBox(label, size))   do return false

    // Assume all items have even height (= 1 line of text). If you need items of different height,
    // you can create a custom version of ListBox() in your code without using the clipper.
    value_changed := false;
    clipper : ImGuiListClipper
    clipper.Begin(items_count, GetTextLineHeightWithSpacing()); // We know exactly our line height here so we pass it as a minor optimization, but generally you don't need to.
    IncludeItemByIndex(&clipper, current_item^);
    for (Step(&clipper)) {
        for i := clipper.DisplayStart; i < clipper.DisplayEnd; i += 1
        {
            item_text := getter(user_data, i);
            if (item_text == nil) do item_text = "*Unknown item*";

            PushID(i);
            item_selected := (i == current_item^);
            if (Selectable(item_text, item_selected))
            {
                current_item^ = i;
                value_changed = true;
            }
            if (item_selected)   do SetItemDefaultFocus()
            PopID();
        }
    }
    EndListBox();

    if (value_changed) do MarkItemEdited(g.LastItemData.ID);

    return value_changed;
}

ListBox :: proc { ListBox_ex, ListBox_basic }

//-------------------------------------------------------------------------
// [SECTION] Widgets: PlotLines, PlotHistogram
//-------------------------------------------------------------------------
// - PlotEx() [Internal]
// - PlotLines()
// - PlotHistogram()
//-------------------------------------------------------------------------
// Plot/Graph widgets are not very good.
// Consider writing your own, or using a third-party one, see:
// - ImPlot https://github.com/epezent/implot
// - others https://github.com/ocornut/imgui/wiki/Useful-Extensions
//-------------------------------------------------------------------------

PlotEx :: proc(plot_type : ImGuiPlotType, label : string, values_getter : proc(data : rawptr, idx : i32) -> f32, data : rawptr, values_count : i32, values_offset : i32, overlay_text : ^u8, scale_min : f32, scale_max : f32, size_arg : ImVec2) -> i32
{
    g := GImGui;
    window := GetCurrentWindow();
    if (window.SkipItems)   do return -1

    style := &g.Style;
    id := GetID(window, label);

    label_size := CalcTextSize(label, nil, true);
    frame_size := CalcItemSize(size_arg, CalcItemWidth(), label_size.y + style.FramePadding.y * 2.0);

    frame_bb := ImRect{ _v = {window.DC.CursorPos, window.DC.CursorPos + frame_size}};
    inner_bb := ImRect{ _v = {frame_bb.Min + style.FramePadding, frame_bb.Max - style.FramePadding}};
    total_bb := ImRect(frame_bb.Min, frame_bb.Max + ImVec2{label_size.x > 0.0 ? style.ItemInnerSpacing.x + label_size.x : 0.0, 0});
    ItemSize(total_bb, style.FramePadding.y);
    if (!ItemAdd(total_bb, id, &frame_bb, ImGuiItemFlags_NoNav))   do return -1
    hovered : bool
    ButtonBehavior(frame_bb, id, &hovered, nil);

    // Determine scale from values if not specified
    if (scale_min == math.F32_MAX || scale_max == math.F32_MAX)
    {
        v_min := math.F32_MAX;
        v_max := -math.F32_MAX;
        for i := 0; i < values_count; i += 1
        {
            v := values_getter(data, i);
            if (v != v) do continue // Ignore NaN values
            v_min = ImMin(v_min, v);
            v_max = ImMax(v_max, v);
        }
        if (scale_min == math.F32_MAX)   do scale_min = v_min
        if (scale_max == math.F32_MAX)   do scale_max = v_max
    }

    RenderFrame(frame_bb.Min, frame_bb.Max, GetColorU32(ImGuiCol.FrameBg), true, style.FrameRounding);

    values_count_min := (plot_type == ImGuiPlotType_Lines) ? 2 : 1;
    idx_hovered := -1;
    if (values_count >= values_count_min)
    {
        res_w := ImMin(cast(i32) frame_size.x, values_count) + ((plot_type == ImGuiPlotType_Lines) ? -1 : 0);
        item_count := values_count + ((plot_type == ImGuiPlotType_Lines) ? -1 : 0);

        // Tooltip on hover
        if (hovered && inner_bb.Contains(g.IO.MousePos))
        {
            t := ImClamp((g.IO.MousePos.x - inner_bb.Min.x) / (inner_bb.Max.x - inner_bb.Min.x), 0.0, 0.9999);
            v_idx := (i32)(t * item_count);
            assert(v_idx >= 0 && v_idx < values_count);

            v0 := values_getter(data, (v_idx + values_offset) % values_count);
            v1 := values_getter(data, (v_idx + 1 + values_offset) % values_count);
            if (plot_type == ImGuiPlotType_Lines) {
                SetTooltip("%d: %8.4g\n%d: %8.4g", v_idx, v0, v_idx + 1, v1);
            }
            else if (plot_type == ImGuiPlotType_Histogram) {
                SetTooltip("%d: %8.4g", v_idx, v0);
            }
            idx_hovered = v_idx;
        }

        t_step := 1.0 / cast(f32) res_w;
        inv_scale := (scale_min == scale_max) ? 0.0 : (1.0 / (scale_max - scale_min));

        v0 := values_getter(data, (0 + values_offset) % values_count);
        t0 := 0.0;
        tp0 := ImVec2{ t0, 1.0 - ImSaturate((v0 - scale_min) * inv_scale) };                       // Point in the normalized space of our target rectangle
        histogram_zero_line_t := (scale_min * scale_max < 0.0) ? (1 + scale_min * inv_scale) : (scale_min < 0.0 ? 0.0 : 1.0);   // Where does the zero line stands

        col_base := GetColorU32((plot_type == ImGuiPlotType_Lines) ? ImGuiCol.PlotLines : ImGuiCol.PlotHistogram);
        col_hovered := GetColorU32((plot_type == ImGuiPlotType_Lines) ? ImGuiCol.PlotLinesHovered : ImGuiCol.PlotHistogramHovered);

        for n := 0; n < res_w; n += 1
        {
            t1 := t0 + t_step;
            v1_idx := (i32)(t0 * item_count + 0.5);
            assert(v1_idx >= 0 && v1_idx < values_count);
            v1 := values_getter(data, (v1_idx + values_offset + 1) % values_count);
            tp1 := ImVec2{ t1, 1.0 - ImSaturate((v1 - scale_min) * inv_scale) };

            // NB: Draw calls are merged together by the DrawList system. Still, we should render our batch are lower level to save a bit of CPU.
            pos0 := ImLerp(inner_bb.Min, inner_bb.Max, tp0);
            pos1 := ImLerp(inner_bb.Min, inner_bb.Max, (plot_type == ImGuiPlotType_Lines) ? tp1 : ImVec2{tp1.x, histogram_zero_line_t});
            if (plot_type == ImGuiPlotType_Lines)
            {
                AddLine(window.DrawList, pos0, pos1, idx_hovered == v1_idx ? col_hovered : col_base);
            }
            else if (plot_type == ImGuiPlotType_Histogram)
            {
                if (pos1.x >= pos0.x + 2.0)   do pos1.x -= 1.0
                AddRectFilled(window.DrawList, pos0, pos1, idx_hovered == v1_idx ? col_hovered : col_base);
            }

            t0 = t1;
            tp0 = tp1;
        }
    }

    // Text overlay
    if (overlay_text) {
        RenderTextClipped(ImVec2{frame_bb.Min.x, frame_bb.Min.y + style.FramePadding.y}, frame_bb.Max, overlay_text, nil, nil, ImVec2{0.5, 0.0});
    }

    if (label_size.x > 0.0) {
        RenderText(ImVec2{frame_bb.Max.x + style.ItemInnerSpacing.x, inner_bb.Min.y}, label);
    }

    // Return hovered index or -1 if none are hovered.
    // This is currently not exposed in the public API because we need a larger redesign of the whole thing, but in the short-term we are making it available in PlotEx().
    return idx_hovered;
}

ImGuiPlotArrayGetterData :: struct
{
    Values : ^f32,
    Stride : i32,
};

Plot_ArrayGetter :: proc(data : rawptr, idx : i32) -> f32
{
    plot_data := cast(^ImGuiPlotArrayGetterData)data;
    v := (cast(^f32)cast(rawptr)(cast(^u8) plot_data.Values + cast(int) idx * plot_data.Stride))^;
    return v;
}

PlotLines_v :: proc(label : string, values : ^f32, values_count : i32, values_offset : i32, overlay_text : ^u8, scale_min : f32 = 0, scale_max : f32 = math.F32_MAX, graph_size : ImVec2 = {}, stride : i32 = size_of(f32))
{
    data := ImGuiPlotArrayGetterData(values, stride);
    PlotEx(ImGuiPlotType_Lines, label, &Plot_ArrayGetter, cast(rawptr) &data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size);
}

PlotLines_get :: proc(label : string, values_getter : proc(data : rawptr, idx : i32) -> f32, data : rawptr, values_count : i32, values_offset : i32 = 0, overlay_text : ^u8 = nil, scale_min : f32 = math.F32_MAX, scale_max : f32 = math.F32_MAX, graph_size : ImVec2 = {})
{
    PlotEx(ImGuiPlotType_Lines, label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size);
}

PlotLines :: proc { PlotLines_v, PlotLines_get }

PlotHistogram_v :: proc(label : string, values : [^]f32, values_count : i32, values_offset : i32 = 0, overlay_text : string = "", scale_min : f32 = math.F32_MAX, scale_max : f32 = math.F32_MAX, graph_size : ImVec2 = {}, stride : i32 = size_of(f32))
{
    data := ImGuiPlotArrayGetterData(values, stride);
    PlotEx(ImGuiPlotType_Histogram, label, &Plot_ArrayGetter, cast(rawptr) &data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size);
}

PlotHistogram_get :: proc(label : string, values_getter : proc(data : rawptr, idx : i32) -> f32, data : rawptr, values_count : i32, values_offset : i32 = 0, overlay_text : string = "", scale_min : f32 = math.F32_MAX, scale_max : f32 = math.F32_MAX, graph_size : ImVec2 = {})
{
    PlotEx(ImGuiPlotType_Histogram, label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size);
}

PlotHistogram :: proc { PlotHistogram_v, PlotHistogram_get }

//-------------------------------------------------------------------------
// [SECTION] Widgets: Value helpers
// Those is not very useful, legacy API.
//-------------------------------------------------------------------------
// - Value()
//-------------------------------------------------------------------------

Value_b :: proc(prefix : ^u8, b : bool)
{
    Text("%s: %s", prefix, (b ? "true" : "false"));
}

Value_i :: proc(prefix : ^u8, v : i32)
{
    Text("%s: %d", prefix, v);
}

Value_u :: proc(prefix : ^u8, v : u32)
{
    Text("%s: %d", prefix, v);
}

Value_f :: proc(prefix : ^u8, v : f32, float_format : ^u8 = nil)
{
    if (float_format)
    {
        fmt : [64]u8
        ImFormatString(fmt, len(fmt), "%%s: %s", float_format);
        Text(fmt, prefix, v);
    }
    else
    {
        Text("%s: %.3", prefix, v);
    }
}

Value :: proc {  Value_b, Value_i, Value_u, Value_f }

//-------------------------------------------------------------------------
// [SECTION] MenuItem, BeginMenu, EndMenu, etc.
//-------------------------------------------------------------------------
// - ImGuiMenuColumns [Internal]
// - BeginMenuBar()
// - EndMenuBar()
// - BeginMainMenuBar()
// - EndMainMenuBar()
// - BeginMenu()
// - EndMenu()
// - MenuItemEx() [Internal]
// - MenuItem()
//-------------------------------------------------------------------------

// Helpers for internal use
Update :: proc(this : ^ImGuiMenuColumns, spacing : f32, window_reappearing : bool)
{
    if (window_reappearing)  do memset(Widths, 0, size_of(Widths));
    Spacing = cast(u16) spacing;
    CalcNextTotalWidth(true);
    memset(Widths, 0, size_of(Widths));
    TotalWidth = NextTotalWidth;
    NextTotalWidth = 0;
}

CalcNextTotalWidth :: proc(this : ^ImGuiMenuColumns, update_offsets : bool)
{
    offset := 0;
    want_spacing := false;
    for i := 0; i < len(Widths); i += 1
    {
        width := Widths[i];
        if (want_spacing && width > 0)   do offset += Spacing
        want_spacing |= (width > 0);
        if (update_offsets)
        {
            if (i == 1) { OffsetLabel = offset; }
            if (i == 2) { OffsetShortcut = offset; }
            if (i == 3) { OffsetMark = offset; }
        }
        offset += width;
    }
    NextTotalWidth = offset;
}

DeclColumns :: proc(this : ^ImGuiMenuColumns, w_icon : f32, w_label : f32, w_shortcut : f32, w_mark : f32) -> f32
{
    Widths[0] = ImMax(Widths[0], cast(u16) w_icon);
    Widths[1] = ImMax(Widths[1], cast(u16) w_label);
    Widths[2] = ImMax(Widths[2], cast(u16) w_shortcut);
    Widths[3] = ImMax(Widths[3], cast(u16) w_mark);
    CalcNextTotalWidth(false);
    return cast(f32) ImMax(TotalWidth, NextTotalWidth);
}

// FIXME: Provided a rectangle perhaps e.g. a BeginMenuBarEx() could be used anywhere..
// Currently the main responsibility of this function being to setup clip-rect + horizontal layout + menu navigation layer.
// Ideally we also want this to be responsible for claiming space out of the main window scrolling rectangle, in which case ImGuiWindowFlags_MenuBar will become unnecessary.
// Then later the same system could be used for multiple menu-bars, scrollbars, side-bars.
// [forward declared comment]:
// append to menu-bar of current window (requires ImGuiWindowFlags_MenuBar flag set on parent window).
BeginMenuBar :: proc() -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false
    if (!(.MenuBar in window.Flags))   do return false

    assert(!window.DC.MenuBarAppending);
    BeginGroup(); // Backup position on layer 0 // FIXME: Misleading to use a group for that backup/restore
    PushID("##menubar");

    // We don't clip with current window clipping rectangle as it is already set to the area below. However we clip with window full rect.
    // We remove 1 worth of rounding to Max.x to that text in long menus and small windows don't tend to display over the lower-right rounded area, which looks particularly glitchy.
    bar_rect := window.MenuBarRect();
    clip_rect := ImRect(ImFloor(bar_rect.Min.x + window.WindowBorderSize), ImFloor(bar_rect.Min.y + window.WindowBorderSize), ImFloor(ImMax(bar_rect.Min.x, bar_rect.Max.x - ImMax(window.WindowRounding, window.WindowBorderSize))), ImFloor(bar_rect.Max.y));
    clip_rect.ClipWith(window.OuterRectClipped);
    PushClipRect(clip_rect.Min, clip_rect.Max, false);

    // We overwrite CursorMaxPos because BeginGroup sets it to CursorPos (essentially the .EmitItem hack in EndMenuBar() would need something analogous here, maybe a BeginGroupEx() with flags).
    window.DC.CursorMaxPos = ImVec2{bar_rect.Min.x + window.DC.MenuBarOffset.x, bar_rect.Min.y + window.DC.MenuBarOffset.y};
    window.DC.CursorPos = window.DC.CursorMaxPos
    window.DC.LayoutType = .Horizontal;
    window.DC.IsSameLine = false;
    window.DC.NavLayerCurrent = ImGuiNavLayer_Menu;
    window.DC.MenuBarAppending = true;
    AlignTextToFramePadding();
    return true;
}

// [forward declared comment]:
// only call EndMenuBar() if BeginMenuBar() returns true!
EndMenuBar :: proc()
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return
    g := GImGui;

    // Nav: When a move request within one of our child menu failed, capture the request to navigate among our siblings.
    if (NavMoveRequestButNoResultYet() && (g.NavMoveDir == .Left || g.NavMoveDir == .Right) && (.ChildMenu in g.NavWindow.Flags))
    {
        // Try to find out if the request is for one of our child menu
        nav_earliest_child := g.NavWindow;
        for (nav_earliest_child.ParentWindow && (nav_earliest_child.ParentWindow.Flags & ImGuiWindowFlags_ChildMenu)) {
            nav_earliest_child = nav_earliest_child.ParentWindow;
        }
        if (nav_earliest_child.ParentWindow == window && nav_earliest_child.DC.ParentLayoutType == .Horizontal && (.Forwarded not_in g.NavMoveFlags))
        {
            // To do so we claim focus back, restore NavId and then process the movement request for yet another frame.
            // This involve a one-frame delay which isn't very problematic in this situation. We could remove it by scoring in advance for multiple window (probably not worth bothering)
            layer := ImGuiNavLayer_Menu;
            assert(window.DC.NavLayersActiveMaskNext & (1 << layer)); // Sanity check (FIXME: Seems unnecessary)
            FocusWindow(window);
            SetNavID(window.NavLastIds[layer], layer, 0, window.NavRectRel[layer]);
            // FIXME-NAV: How to deal with this when not using g.IO.ConfigNavCursorVisibleAuto?
            if (g.NavCursorVisible)
            {
                g.NavCursorVisible = false; // Hide nav cursor for the current frame so we don't see the intermediary selection. Will be set again
                g.NavCursorHideFrames = 2;
            }
            g.NavHighlightItemUnderNav = true
            g.NavMousePosDirty = true;
            NavMoveRequestForward(g.NavMoveDir, g.NavMoveClipDir, g.NavMoveFlags, g.NavMoveScrollFlags); // Repeat
        }
    }

    assert(.MenuBar in window.Flags);
    assert(window.DC.MenuBarAppending);
    PopClipRect();
    PopID();
    window.DC.MenuBarOffset.x = window.DC.CursorPos.x - window.Pos.x; // Save horizontal position so next append can reuse it. This is kinda equivalent to a per-layer CursorPos.

    // FIXME: Extremely confusing, cleanup by (a) working on WorkRect stack system (b) not using a Group confusingly here.
    group_data := &g.GroupStack.back();
    group_data.EmitItem = false;
    restore_cursor_max_pos := group_data.BackupCursorMaxPos;
    window.DC.IdealMaxPos.x = ImMax(window.DC.IdealMaxPos.x, window.DC.CursorMaxPos.x - window.Scroll.x); // Convert ideal extents for scrolling layer equivalent.
    EndGroup(); // Restore position on layer 0 // FIXME: Misleading to use a group for that backup/restore
    window.DC.LayoutType = .Vertical;
    window.DC.IsSameLine = false;
    window.DC.NavLayerCurrent = ImGuiNavLayer_Main;
    window.DC.MenuBarAppending = false;
    window.DC.CursorMaxPos = restore_cursor_max_pos;
}

// Important: calling order matters!
// FIXME: Somehow overlapping with docking tech.
// FIXME: The "rect-cut" aspect of this could be formalized into a lower-level helper (rect-cut: https://halt.software/dead-simple-layouts)
BeginViewportSideBar :: proc(name : ^u8, viewport_p : ^ImGuiViewport, dir : ImGuiDir, axis_size : f32, window_flags : ImGuiWindowFlags) -> bool
{
    assert(dir != nil);

    bar_window := FindWindowByName(name);
    viewport := cast(^ImGuiViewportP)(rawptr)(viewport_p ? viewport_p : GetMainViewport());
    if (bar_window == nil || bar_window.BeginCount == 0)
    {
        // Calculate and set window size/position
        avail_rect := viewport.GetBuildWorkRect();
        axis := (dir == ImGuiDir.Up || dir == ImGuiDir.Down) ? ImGuiAxis.Y : ImGuiAxis.X;
        pos := avail_rect.Min;
        if (dir == .Right || dir == ImGuiDir.Down) {
            pos[axis] = avail_rect.Max[axis] - axis_size;
        }
        size := avail_rect.GetSize();
        size[axis] = axis_size;
        SetNextWindowPos(pos);
        SetNextWindowSize(size);

        // Report our size into work area (for next frame) using actual window size
        if (dir == ImGuiDir.Up || dir == .Left) {
            viewport.BuildWorkInsetMin[axis] += axis_size;
        }
        else if (dir == ImGuiDir.Down || dir == .Right) {
            viewport.BuildWorkInsetMax[axis] += axis_size;
        }
    }

    window_flags |= ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoDocking;
    SetNextWindowViewport(viewport.ID); // Enforce viewport so we don't create our own viewport when ImGuiConfigFlags_ViewportsNoMerge is set.
    PushStyleVar(ImGuiStyleVar_WindowRounding, 0.0);
    PushStyleVar(ImGuiStyleVar_WindowMinSize, ImVec2{0, 0}); // Lift normal size constraint
    is_open := Begin(name, nil, window_flags);
    PopStyleVar(2);

    return is_open;
}

// [forward declared comment]:
// create and append to a full screen menu-bar.
BeginMainMenuBar :: proc() -> bool
{
    g := GImGui;
    viewport := cast(^ImGuiViewportP)cast(rawptr)GetMainViewport();

    // Notify of viewport change so GetFrameHeight() can be accurate in case of DPI change
    SetCurrentViewport(nil, viewport);

    // For the main menu bar, which cannot be moved, we honor g.Style.DisplaySafeAreaPadding to ensure text can be visible on a TV set.
    // FIXME: This could be generalized as an opt-in way to clamp window.DC.CursorStartPos to avoid SafeArea?
    // FIXME: Consider removing support for safe area down the line... it's messy. Nowadays consoles have support for TV calibration in OS settings.
    g.NextWindowData.MenuBarOffsetMinVal = ImVec2{g.Style.DisplaySafeAreaPadding.x, ImMax(g.Style.DisplaySafeAreaPadding.y - g.Style.FramePadding.y, 0.0)};
    window_flags := ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_MenuBar;
    height := GetFrameHeight();
    is_open := BeginViewportSideBar("##MainMenuBar", viewport, ImGuiDir.Up, height, window_flags);
    g.NextWindowData.MenuBarOffsetMinVal = ImVec2{0.0, 0.0};

    if (is_open)   do BeginMenuBar()
    else do End();
    return is_open;
}

// [forward declared comment]:
// only call EndMainMenuBar() if BeginMainMenuBar() returns true!
EndMainMenuBar :: proc()
{
    EndMenuBar();

    // When the user has left the menu layer (typically: closed menus through activation of an item), we restore focus to the previous window
    // FIXME: With this strategy we won't be able to restore a NULL focus.
    g := GImGui;
    if (g.CurrentWindow == g.NavWindow && g.NavLayer == ImGuiNavLayer_Main && !g.NavAnyRequest) {
        FocusTopMostWindowUnderOne(g.NavWindow, nil, nil, ImGuiFocusRequestFlags_UnlessBelowModal | ImGuiFocusRequestFlags_RestoreFocusedChild);
    }

    End();
}

IsRootOfOpenMenuSet :: proc() -> bool
{
    g := GImGui;
    window := g.CurrentWindow;
    if ((len(g.OpenPopupStack) <= g.BeginPopupStack.Size) || (.ChildMenu in window.Flags))   do return false

    // Initially we used 'upper_popup.OpenParentId == window.IDStack.back()' to differentiate multiple menu sets from each others
    // (e.g. inside menu bar vs loose menu items) based on parent ID.
    // This would however prevent the use of e.g. PushID() user code submitting menus.
    // Previously this worked between popup and a first child menu because the first child menu always had the _ChildWindow flag,
    // making hovering on parent popup possible while first child menu was focused - but this was generally a bug with other side effects.
    // Instead we don't treat Popup specifically (in order to consistently support menu features in them), maybe the first child menu of a Popup
    // doesn't have the _ChildWindow flag, and we rely on this IsRootOfOpenMenuSet() check to allow hovering between root window/popup and first child menu.
    // In the end, lack of ID check made it so we could no longer differentiate between separate menu sets. To compensate for that, we at least check parent window nav layer.
    // This fixes the most common case of menu opening on hover when moving between window content and menu bar. Multiple different menu sets in same nav layer would still
    // open on hover, but that should be a lesser problem, because if such menus are close in proximity in window content then it won't feel weird and if they are far apart
    // it likely won't be a problem anyone runs into.
    upper_popup := &g.OpenPopupStack[g.BeginPopupStack.Size];
    if (window.DC.NavLayerCurrent != upper_popup.ParentNavLayer)   do return false
    return upper_popup.Window && (upper_popup.Window.Flags & ImGuiWindowFlags_ChildMenu) && IsWindowChildOf(upper_popup.Window, window, true, false);
}

BeginMenuEx :: proc(label : string, icon : ^u8, enabled : bool) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    style := &g.Style;
    id := GetID(window, label);
    menu_is_open := IsPopupOpen(id, ImGuiPopupFlags_None);

    // Sub-menus are ChildWindow so that mouse can be hovering across them (otherwise top-most popup menu would steal focus and not allow hovering on parent menu)
    // The first menu in a hierarchy isn't so hovering doesn't get across (otherwise e.g. resizing borders with ImGuiButtonFlags_FlattenChildren would react), but top-most BeginMenu() will bypass that limitation.
    window_flags := ImGuiWindowFlags_ChildMenu | ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoNavFocus;
    if (.ChildMenu in window.Flags) {
        window_flags |= ImGuiWindowFlags_ChildWindow;
    }

    // If a menu with same the ID was already submitted, we will append to it, matching the behavior of Begin().
    // We are relying on a O(N) search - so O(N log N) over the frame - which seems like the most efficient for the expected small amount of BeginMenu() calls per frame.
    // If somehow this is ever becoming a problem we can switch to use e.g. ImGuiStorage mapping key to last frame used.
    if (g.MenusIdSubmittedThisFrame.contains(id))
    {
        if (menu_is_open)  do menu_is_open = BeginPopupEx(id, window_flags); // menu_is_open can be 'false' when the popup is completely clipped (e.g. zero size display)
        else  do g.NextWindowData.ClearFlags();          // we behave like Begin() and need to consume those values
        return menu_is_open;
    }

    // Tag menu as used. Next time BeginMenu() with same ID is called it will append to existing menu
    g.MenusIdSubmittedThisFrame.append(id);

    label_size := CalcTextSize(label, nil, true);

    // Odd hack to allow hovering across menus of a same menu-set (otherwise we wouldn't be able to hover parent without always being a Child window)
    // This is only done for items for the menu set and not the full parent window.
    menuset_is_open := IsRootOfOpenMenuSet();
    if (menuset_is_open)  do PushItemFlag(ImGuiItemFlags_NoWindowHoverableCheck, true);

    // The reference position stored in popup_pos will be used by Begin() to find a suitable position for the child menu,
    // However the final position is going to be different! It is chosen by FindBestWindowPosForPopup().
    // e.g. Menus tend to overlap each other horizontally to amplify relative Z-ordering.
    popup_pos : ImVec2;
    pos := window.DC.CursorPos;
    PushID(label);
    if (!enabled)   do BeginDisabled()
    offsets := &window.DC.MenuColumns;
    pressed : bool

    // We use ImGuiSelectableFlags_NoSetKeyOwner to allow down on one menu item, move, up on another.
    selectable_flags := ImGuiSelectableFlags_NoHoldingActiveID | ImGuiSelectableFlags_NoSetKeyOwner | ImGuiSelectableFlags_SelectOnClick | ImGuiSelectableFlags_NoAutoClosePopups;
    if (window.DC.LayoutType == .Horizontal)
    {
        // Menu inside an horizontal menu bar
        // Selectable extend their highlight by half ItemSpacing in each direction.
        // For ChildMenu, the popup position will be overwritten by the call to FindBestWindowPosForPopup() in Begin()
        popup_pos = ImVec2{pos.x - 1.0 - math.trunc(style.ItemSpacing.x * 0.5), pos.y - style.FramePadding.y + window.MenuBarHeight};
        window.DC.CursorPos.x += math.trunc(style.ItemSpacing.x * 0.5);
        PushStyleVarX(ImGuiStyleVar_ItemSpacing, style.ItemSpacing.x * 2.0);
        w := label_size.x;
        text_pos := ImVec2{window.DC.CursorPos.x + offsets.OffsetLabel, window.DC.CursorPos.y + window.DC.CurrLineTextBaseOffset};
        pressed = Selectable("", menu_is_open, selectable_flags, ImVec2{w, label_size.y});
        LogSetNextTextDecoration("[", "]");
        RenderText(text_pos, label);
        PopStyleVar();
        window.DC.CursorPos.x += math.trunc(style.ItemSpacing.x * (-1.0 + 0.5)); // -1 spacing to compensate the spacing added when Selectable() did a SameLine(). It would also work to call SameLine() ourselves after the PopStyleVar().
    }
    else
    {
        // Menu inside a regular/vertical menu
        // (In a typical menu window where all items are BeginMenu() or MenuItem() calls, extra_w will always be 0.0f.
        //  Only when they are other items sticking out we're going to add spacing, yet only register minimum width into the layout system.
        popup_pos = ImVec2{pos.x, pos.y - style.WindowPadding.y};
        icon_w := (icon && icon[0]) ? CalcTextSize(icon, nil).x : 0.0;
        checkmark_w := math.trunc(g.FontSize * 1.20);
        min_w := window.DC.MenuColumns.DeclColumns(icon_w, label_size.x, 0.0, checkmark_w); // Feedback to next frame
        extra_w := ImMax(0.0, GetContentRegionAvail().x - min_w);
        text_pos := ImVec2{window.DC.CursorPos.x + offsets.OffsetLabel, window.DC.CursorPos.y + window.DC.CurrLineTextBaseOffset};
        pressed = Selectable("", menu_is_open, selectable_flags | ImGuiSelectableFlags_SpanAvailWidth, ImVec2{min_w, label_size.y});
        LogSetNextTextDecoration("", ">");
        RenderText(text_pos, label);
        if (icon_w > 0.0)  do RenderText(pos + ImVec2{offsets.OffsetIcon, 0.0}, icon);
        RenderArrow(window.DrawList, pos + ImVec2{offsets.OffsetMark + extra_w + g.FontSize * 0.30, 0.0}, GetColorU32(ImGuiCol.Text), .Right);
    }
    if (!enabled)   do EndDisabled()

    hovered := (g.HoveredId == id) && enabled && !g.NavHighlightItemUnderNav;
    if (menuset_is_open)   do PopItemFlag()

    want_open := false;
    want_open_nav_init := false;
    want_close := false;
    if (window.DC.LayoutType == .Vertical) // (window.Flags & (ImGuiWindowFlags_Popup|ImGuiWindowFlags_ChildMenu))
    {
        // Close menu when not hovering it anymore unless we are moving roughly in the direction of the menu
        // Implement http://bjk5.com/post/44698559168/breaking-down-amazons-mega-dropdown to avoid using timers, so menus feels more reactive.
        moving_toward_child_menu := false;
        child_popup := (len(g.BeginPopupStack) < g.OpenPopupStack.Size) ? &g.OpenPopupStack[g.BeginPopupStack.Size] : nil; // Popup candidate (testing below)
        child_menu_window := (child_popup && child_popup.Window && child_popup.Window.ParentWindow == window) ? child_popup.Window : nil;
        if (g.HoveredWindow == window && child_menu_window != nil)
        {
            ref_unit := g.FontSize; // FIXME-DPI
            child_dir := (window.Pos.x < child_menu_window.Pos.x) ? 1.0 : -1.0;
            next_window_rect := child_menu_Rect(window);
            ta := (g.IO.MousePos - g.IO.MouseDelta);
            tb := (child_dir > 0.0) ? next_window_rect.GetTL() : next_window_rect.GetTR();
            tc := (child_dir > 0.0) ? next_window_rect.GetBL() : next_window_rect.GetBR();
            pad_farmost_h := ImClamp(ImAbs(ta.x - tb.x) * 0.30, ref_unit * 0.5, ref_unit * 2.5); // Add a bit of extra slack.
            ta.x += child_dir * -0.5;
            tb.x += child_dir * ref_unit;
            tc.x += child_dir * ref_unit;
            tb.y = ta.y + ImMax((tb.y - pad_farmost_h) - ta.y, -ref_unit * 8.0); // Triangle has maximum height to limit the slope and the bias toward large sub-menus
            tc.y = ta.y + ImMin((tc.y + pad_farmost_h) - ta.y, +ref_unit * 8.0);
            moving_toward_child_menu = ImTriangleContainsPoint(ta, tb, tc, g.IO.MousePos);
            //GetForegroundDrawList()->AddTriangleFilled(ta, tb, tc, moving_toward_child_menu ? IM_COL32(0,128,0,128) : IM_COL32(128,0,0,128)); // [DEBUG]
        }

        // The 'HovereWindow == window' check creates an inconsistency (e.g. moving away from menu slowly tends to hit same window, whereas moving away fast does not)
        // But we also need to not close the top-menu menu when moving over void. Perhaps we should extend the triangle check to a larger polygon.
        // (Remember to test this on BeginPopup("A")->BeginMenu("B") sequence which behaves slightly differently as B isn't a Child of A and hovering isn't shared.)
        if (menu_is_open && !hovered && g.HoveredWindow == window && !moving_toward_child_menu && !g.NavHighlightItemUnderNav && g.ActiveId == 0)   do want_close = true

        // Open
        // (note: at this point 'hovered' actually includes the NavDisableMouseHover == false test)
        if (!menu_is_open && pressed) {// Click/activate to open
            want_open = true;
        }
        else if (!menu_is_open && hovered && !moving_toward_child_menu) {// Hover to open
            want_open = true;
        }
        else if (!menu_is_open && hovered && g.HoveredIdTimer >= 0.30 && g.MouseStationaryTimer >= 0.30) {// Hover to open (timer fallback)
            want_open = true
        }
        if (g.NavId == id && g.NavMoveDir == .Right) // Nav-Right to open
        {
            want_open = true
            want_open_nav_init = true;
            NavMoveRequestCancel();
            SetNavCursorVisibleAfterMove();
        }
    }
    else
    {
        // Menu bar
        if (menu_is_open && pressed && menuset_is_open) // Click an open menu again to close it
        {
            want_close = true;
            want_open = false
            menu_is_open = false;
        }
        else if (pressed || (hovered && menuset_is_open && !menu_is_open)) // First click to open, then hover to open others
        {
            want_open = true;
        }
        else if (g.NavId == id && g.NavMoveDir == ImGuiDir.Down) // Nav-Down to open
        {
            want_open = true;
            NavMoveRequestCancel();
        }
    }

    if (!enabled) {// explicitly close if an open menu becomes disabled, facilitate users code a lot in pattern such as 'if (BeginMenu("options", has_object)) { ..use object.. }'
        want_close = true;
    }
    if (want_close && IsPopupOpen(id, ImGuiPopupFlags_None)) {
        ClosePopupToLevel(g.BeginPopupStack.Size, true);
    }

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags | ImGuiItemStatusFlags_Openable | (menu_is_open ? ImGuiItemStatusFlags_Opened : 0));
    PopID();

    if (want_open && !menu_is_open && len(g.OpenPopupStack) > g.BeginPopupStack.Size)
    {
        // Don't reopen/recycle same menu level in the same frame if it is a different menu ID, first close the other menu and yield for a frame.
        OpenPopup(label);
    }
    else if (want_open)
    {
        menu_is_open = true;
        OpenPopup(label, ImGuiPopupFlags_NoReopen);// | (want_open_nav_init ? ImGuiPopupFlags_NoReopenAlwaysNavInit : 0));
    }

    if (menu_is_open)
    {
        last_item_in_parent := g.LastItemData;
        SetNextWindowPos(popup_pos, { .Always });                  // Note: misleading: the value will serve as reference for FindBestWindowPosForPopup(), not actual pos.
        PushStyleVar(ImGuiStyleVar_ChildRounding, style.PopupRounding); // First level will use _PopupRounding, subsequent will use _ChildRounding
        menu_is_open = BeginPopupEx(id, window_flags);                  // menu_is_open can be 'false' when the popup is completely clipped (e.g. zero size display)
        PopStyleVar();
        if (menu_is_open)
        {
            // Implement what ImGuiPopupFlags_NoReopenAlwaysNavInit would do:
            // Perform an init request in the case the popup was already open (via a previous mouse hover)
            if (want_open && want_open_nav_init && !g.NavInitRequest)
            {
                FocusWindow(g.CurrentWindow, ImGuiFocusRequestFlags_UnlessBelowModal);
                NavInitWindow(g.CurrentWindow, false);
            }

            // Restore LastItemData so IsItemXXXX functions can work after BeginMenu()/EndMenu()
            // (This fixes using IsItemClicked() and IsItemHovered(), but IsItemHovered() also relies on its support for ImGuiItemFlags_NoWindowHoverableCheck)
            g.LastItemData = last_item_in_parent;
            if (g.HoveredWindow == window) {
                g.LastItemData.StatusFlags |= ImGuiItemStatusFlags_HoveredWindow;
            }
        }
    }
    else
    {
        g.NextWindowData.ClearFlags(); // We behave like Begin() and need to consume those values
    }

    return menu_is_open;
}

// [forward declared comment]:
// create a sub-menu entry. only call EndMenu() if this returns true!
BeginMenu :: proc(label : string, enabled : bool = true) -> bool
{
    return BeginMenuEx(label, nil, enabled);
}

// [forward declared comment]:
// only call EndMenu() if BeginMenu() returns true!
EndMenu :: proc()
{
    // Nav: When a left move request our menu failed, close ourselves.
    g := GImGui;
    window := g.CurrentWindow;
    assert(.Popup in window.Flags);  // Mismatched BeginMenu()/EndMenu() calls
    parent_window := window.ParentWindow;  // Should always be != NULL is we passed assert.
    if (window.BeginCount == window.BeginCountPreviousFrame) {
        if (g.NavMoveDir == .Left && NavMoveRequestButNoResultYet()) {
            if (g.NavWindow && (g.NavWindow.RootWindowForNav == window) && parent_window.DC.LayoutType == .Vertical)
            {
                ClosePopupToLevel(len(g.BeginPopupStack) - 1, true);
                NavMoveRequestCancel();
            }
        }
    }

    EndPopup();
}

MenuItemEx :: proc(label : string, icon : ^u8, shortcut : ^u8, selected : bool, enabled : bool) -> bool
{
    window := GetCurrentWindow();
    if (window.SkipItems)   do return false

    g := GImGui;
    style := &g.Style;
    pos := window.DC.CursorPos;
    label_size := CalcTextSize(label, nil, true);

    // See BeginMenuEx() for comments about this.
    menuset_is_open := IsRootOfOpenMenuSet();
    if (menuset_is_open)   do PushItemFlag(ImGuiItemFlags_NoWindowHoverableCheck, true);

    // We've been using the equivalent of ImGuiSelectableFlags_SetNavIdOnHover on all Selectable() since early Nav system days (commit 43ee5d73),
    // but I am unsure whether this should be kept at all. For now moved it to be an opt-in feature used by menus only.
    pressed : bool
    PushID(label);
    if (!enabled)   do BeginDisabled()

    // We use ImGuiSelectableFlags_NoSetKeyOwner to allow down on one menu item, move, up on another.
    selectable_flags := ImGuiSelectableFlags_SelectOnRelease | ImGuiSelectableFlags_NoSetKeyOwner | ImGuiSelectableFlags_SetNavIdOnHover;
    offsets := &window.DC.MenuColumns;
    if (window.DC.LayoutType == .Horizontal)
    {
        // Mimic the exact layout spacing of BeginMenu() to allow MenuItem() inside a menu bar, which is a little misleading but may be useful
        // Note that in this situation: we don't render the shortcut, we render a highlight instead of the selected tick mark.
        w := label_size.x;
        window.DC.CursorPos.x += math.trunc(style.ItemSpacing.x * 0.5);
        text_pos := ImVec2{window.DC.CursorPos.x + offsets.OffsetLabel, window.DC.CursorPos.y + window.DC.CurrLineTextBaseOffset};
        PushStyleVarX(ImGuiStyleVar_ItemSpacing, style.ItemSpacing.x * 2.0);
        pressed = Selectable("", selected, selectable_flags, ImVec2{w, 0.0});
        PopStyleVar();
        if (.Visible in g.LastItemData.StatusFlags) {
            RenderText(text_pos, label);
        }
        window.DC.CursorPos.x += math.trunc(style.ItemSpacing.x * (-1.0 + 0.5)); // -1 spacing to compensate the spacing added when Selectable() did a SameLine(). It would also work to call SameLine() ourselves after the PopStyleVar().
    }
    else
    {
        // Menu item inside a vertical menu
        // (In a typical menu window where all items are BeginMenu() or MenuItem() calls, extra_w will always be 0.0f.
        //  Only when they are other items sticking out we're going to add spacing, yet only register minimum width into the layout system.
        icon_w := (icon && icon[0]) ? CalcTextSize(icon, nil).x : 0.0;
        shortcut_w := (shortcut && shortcut[0]) ? CalcTextSize(shortcut, nil).x : 0.0;
        checkmark_w := math.trunc(g.FontSize * 1.20);
        min_w := window.DC.MenuColumns.DeclColumns(icon_w, label_size.x, shortcut_w, checkmark_w); // Feedback for next frame
        stretch_w := ImMax(0.0, GetContentRegionAvail().x - min_w);
        pressed = Selectable("", false, selectable_flags | ImGuiSelectableFlags_SpanAvailWidth, ImVec2{min_w, label_size.y});
        if (.Visible in g.LastItemData.StatusFlags)
        {
            RenderText(pos + ImVec2{offsets.OffsetLabel, 0.0}, label);
            if (icon_w > 0.0) {
                RenderText(pos + ImVec2{offsets.OffsetIcon, 0.0}, icon);
            }
            if (shortcut_w > 0.0)
            {
                PushStyleColor(ImGuiCol.Text, style.Colors[ImGuiCol.TextDisabled]);
                LogSetNextTextDecoration("(", ")");
                RenderText(pos + ImVec2{offsets.OffsetShortcut + stretch_w, 0.0}, shortcut, nil, false);
                PopStyleColor();
            }
            if (selected) {
                RenderCheckMark(window.DrawList, pos + ImVec2{offsets.OffsetMark + stretch_w + g.FontSize * 0.40, g.FontSize * 0.134 * 0.5}, GetColorU32(ImGuiCol.Text), g.FontSize * 0.866);
            }
        }
    }
    IMGUI_TEST_ENGINE_ITEM_INFO(g.LastItemData.ID, label, g.LastItemData.StatusFlags | ImGuiItemStatusFlags_Checkable | (selected ? ImGuiItemStatusFlags_Checked : 0));
    if (!enabled)   do EndDisabled()
    PopID();
    if (menuset_is_open)   do PopItemFlag()

    return pressed;
}

// [forward declared comment]:
// return true when activated + toggle (*p_selected) if p_selected != NULL
MenuItem_v :: proc(label : string, shortcut : ^u8, selected : bool, enabled : bool = true) -> bool
{
    return MenuItemEx(label, nil, shortcut, selected, enabled);
}

// [forward declared comment]:
// return true when activated + toggle (*p_selected) if p_selected != NULL
MenuItem_p :: proc(label : string, shortcut : ^u8, p_selected : ^bool, enabled : bool = true) -> bool
{
    if (MenuItemEx(label, nil, shortcut, p_selected != nil ? p_selected^ : false, enabled))
    {
        if (p_selected != nil) do p_selected^ = !p_selected^;
        return true;
    }
    return false;
}

MenuItem :: proc { MenuItem_p, MenuItem_v }

//-------------------------------------------------------------------------
// [SECTION] Widgets: BeginTabBar, EndTabBar, etc.
//-------------------------------------------------------------------------
// - BeginTabBar()
// - BeginTabBarEx() [Internal]
// - EndTabBar()
// - TabBarLayout() [Internal]
// - TabBarCalcTabID() [Internal]
// - TabBarCalcMaxTabWidth() [Internal]
// - TabBarFindTabById() [Internal]
// - TabBarFindTabByOrder() [Internal]
// - TabBarFindMostRecentlySelectedTabForActiveWindow() [Internal]
// - TabBarGetCurrentTab() [Internal]
// - TabBarGetTabName() [Internal]
// - TabBarAddTab() [Internal]
// - TabBarRemoveTab() [Internal]
// - TabBarCloseTab() [Internal]
// - TabBarScrollClamp() [Internal]
// - TabBarScrollToTab() [Internal]
// - TabBarQueueFocus() [Internal]
// - TabBarQueueReorder() [Internal]
// - TabBarProcessReorderFromMousePos() [Internal]
// - TabBarProcessReorder() [Internal]
// - TabBarScrollingButtons() [Internal]
// - TabBarTabListPopupButton() [Internal]
//-------------------------------------------------------------------------

ImGuiTabBarSection :: struct
{
    TabCount : i32,               // Number of tabs in this section.
    Width : f32,                  // Sum of width of tabs in this section (after shrinking down)
    Spacing : f32,                // Horizontal spacing at the end of the section.
};

init_ImGuiTabBar :: proc(this : ^ImGuiTabBar)
{
    this^ = {};
    this.CurrFrameVisible = -1
    this.PrevFrameVisible = -1;
    this.LastTabItemIdx = -1;
}

TabItemGetSectionIdx :: #force_inline proc(tab : ^ImGuiTabItem) -> i32
{
    return (.Leading in tab.Flags) ? 0 : (.Trailing in tab.Flags) ? 2 : 1;
}

TabItemComparerBySection :: proc(lhs, rhs :rawptr) -> i32
{
    a := cast(^ImGuiTabItem)lhs;
    b := cast(^ImGuiTabItem)rhs;
    a_section := TabItemGetSectionIdx(a);
    b_section := TabItemGetSectionIdx(b);
    if (a_section != b_section)   do return a_section - b_section
    return (i32)(a.IndexDuringLayout - b.IndexDuringLayout);
}

TabItemComparerByBeginOrder :: proc(lhs, rhs : rawptr) -> i32
{
    a := cast(^ImGuiTabItem)lhs;
    b := cast(^ImGuiTabItem)rhs;
    return (i32)(a.BeginOrder - b.BeginOrder);
}

GetTabBarFromTabBarRef :: proc(ref : ^ImGuiPtrOrIndex) -> ^ImGuiTabBar
{
    g := GImGui;
    return ref.Ptr ? cast(^ImGuiTabBar)ref.Ptr : g.TabBars.GetByIndex(ref.Index);
}

GetTabBarRefFromTabBar :: proc(tab_bar : ^ImGuiTabBar) -> ImGuiPtrOrIndex
{
    g := GImGui;
    if (g.TabBars.Contains(tab_bar)) {
        return ImGuiPtrOrIndex(g.TabBars.GetIndex(tab_bar));
    }
    return ImGuiPtrOrIndex(tab_bar);
}

// [forward declared comment]:
// create and append into a TabBar
BeginTabBar :: proc(str_id : ^u8, flags : ImGuiTabBarFlags = {}) -> bool
{
    g := GImGui;
    window := g.CurrentWindow;
    if (window.SkipItems)   do return false

    id := GetID(window, str_id);
    tab_bar := g.TabBars.GetOrAddByKey(id);
    tab_bar_bb := ImRect{ _r = {window.DC.CursorPos.x, window.DC.CursorPos.y, window.WorkRect.Max.x, window.DC.CursorPos.y + g.FontSize + g.Style.FramePadding.y * 2}};
    tab_bar.ID = id;
    tab_bar.SeparatorMinX = tab_bar.BarRect.Min.x - math.trunc(window.WindowPadding.x * 0.5);
    tab_bar.SeparatorMaxX = tab_bar.BarRect.Max.x + math.trunc(window.WindowPadding.x * 0.5);
    //if (g.NavWindow && IsWindowChildOf(g.NavWindow, window, false, false))
    flags |= ImGuiTabBarFlags_IsFocused;
    return BeginTabBarEx(tab_bar, tab_bar_bb, flags);
}

BeginTabBarEx :: proc(tab_bar : ^ImGuiTabBar, tab_bar_bb : ^ImRect, flags : ImGuiTabBarFlags) -> bool
{
    g := GImGui;
    window := g.CurrentWindow;
    if (window.SkipItems)   do return false

    assert(tab_bar.ID != 0);
    if ((.DockNode not_in flags)) {
        PushOverrideID(tab_bar.ID);
    }

    // Add to stack
    g.CurrentTabBarStack.append(GetTabBarRefFromTabBar(tab_bar));
    g.CurrentTabBar = tab_bar;
    tab_bar.Window = window;

    // Append with multiple BeginTabBar()/EndTabBar() pairs.
    tab_bar.BackupCursorPos = window.DC.CursorPos;
    if (tab_bar.CurrFrameVisible == g.FrameCount)
    {
        window.DC.CursorPos = ImVec2{tab_bar.BarRect.Min.x, tab_bar.BarRect.Max.y + tab_bar.ItemSpacingY};
        tab_bar.BeginCount += 1;
        return true;
    }

    // Ensure correct ordering when toggling ImGuiTabBarFlags_Reorderable flag, or when a new tab was added while being not reorderable
    if ((.Reorderable in flags) != (.Reorderable in tab_bar.Flags) || (tab_bar.TabsAddedNew && !(.Reorderable in flags))) {
        if ((.DockNode not_in flags)) { // FIXME: TabBar with DockNode can now be hybrid
            ImQsort(tab_bar.Tabs.Data, tab_bar.Tabs.Size, size_of(ImGuiTabItem), TabItemComparerByBeginOrder);
        }
    }
    tab_bar.TabsAddedNew = false;

    // Flags
    if ((flags & ImGuiTabBarFlags_FittingPolicyMask_) == 0) {
        flags |= ImGuiTabBarFlags_FittingPolicyDefault_;
    }

    tab_bar.Flags = flags;
    tab_bar.BarRect = tab_bar_bb;
    tab_bar.WantLayout = true; // Layout will be done on the first call to ItemTab()
    tab_bar.PrevFrameVisible = tab_bar.CurrFrameVisible;
    tab_bar.CurrFrameVisible = g.FrameCount;
    tab_bar.PrevTabsContentsHeight = tab_bar.CurrTabsContentsHeight;
    tab_bar.CurrTabsContentsHeight = 0.0;
    tab_bar.ItemSpacingY = g.Style.ItemSpacing.y;
    tab_bar.FramePadding = g.Style.FramePadding;
    tab_bar.TabsActiveCount = 0;
    tab_bar.LastTabItemIdx = -1;
    tab_bar.BeginCount = 1;

    // Set cursor pos in a way which only be used in the off-chance the user erroneously submits item before BeginTabItem(): items will overlap
    window.DC.CursorPos = ImVec2{tab_bar.BarRect.Min.x, tab_bar.BarRect.Max.y + tab_bar.ItemSpacingY};

    // Draw separator
    // (it would be misleading to draw this in EndTabBar() suggesting that it may be drawn over tabs, as tab bar are appendable)
    col := GetColorU32((.IsFocused in flags) ? ImGuiCol.TabSelected : ImGuiCol.TabDimmedSelected);
    if (g.Style.TabBarBorderSize > 0.0)
    {
        y := tab_bar.BarRect.Max.y;
        AddRectFilled(window.DrawList, ImVec2{tab_bar.SeparatorMinX, y - g.Style.TabBarBorderSize}, ImVec2{tab_bar.SeparatorMaxX, y}, col);
    }
    return true;
}

// [forward declared comment]:
// only call EndTabBar() if BeginTabBar() returns true!
EndTabBar :: proc()
{
    g := GImGui;
    window := g.CurrentWindow;
    if (window.SkipItems)   do return

    tab_bar := g.CurrentTabBar;
    if (tab_bar == nil)
    {
        IM_ASSERT_USER_ERROR(tab_bar != nil, "Mismatched BeginTabBar()/EndTabBar()!");
        return;
    }

    // Fallback in case no TabItem have been submitted
    if (tab_bar.WantLayout)   do TabBarLayout(tab_bar)

    // Restore the last visible height if no tab is visible, this reduce vertical flicker/movement when a tabs gets removed without calling SetTabItemClosed().
    tab_bar_appearing := (tab_bar.PrevFrameVisible + 1 < g.FrameCount);
    if (tab_bar.VisibleTabWasSubmitted || tab_bar.VisibleTabId == 0 || tab_bar_appearing)
    {
        tab_bar.CurrTabsContentsHeight = ImMax(window.DC.CursorPos.y - tab_bar.BarRect.Max.y, tab_bar.CurrTabsContentsHeight);
        window.DC.CursorPos.y = tab_bar.BarRect.Max.y + tab_bar.CurrTabsContentsHeight;
    }
    else
    {
        window.DC.CursorPos.y = tab_bar.BarRect.Max.y + tab_bar.PrevTabsContentsHeight;
    }
    if (tab_bar.BeginCount > 1) {
        window.DC.CursorPos = tab_bar.BackupCursorPos;
    }

    tab_bar.LastTabItemIdx = -1;
    if ((.DockNode not_in tab_bar.Flags))   do PopID()

    g.CurrentTabBarStack.pop_back();
    g.CurrentTabBar = g.CurrentTabBarStack.empty() ? nil : GetTabBarFromTabBarRef(g.CurrentTabBarStack.back());
}

// Scrolling happens only in the central section (leading/trailing sections are not scrolling)
TabBarCalcScrollableWidth :: proc(tab_bar : ^ImGuiTabBar, sections : ^ImGuiTabBarSection) -> f32
{
    return tab_bar.BarRect.GetWidth() - sections[0].Width - sections[2].Width - sections[1].Spacing;
}

// This is called only once a frame before by the first call to ItemTab()
// The reason we're not calling it in BeginTabBar() is to leave a chance to the user to call the SetTabItemClosed() functions.
TabBarLayout :: proc(tab_bar : ^ImGuiTabBar)
{
    g := GImGui;
    tab_bar.WantLayout = false;

    // Garbage collect by compacting list
    // Detect if we need to sort out tab list (e.g. in rare case where a tab changed section)
    tab_dst_n := 0;
    need_sort_by_section := false;
    sections : [3]ImGuiTabBarSection // Layout sections: Leading, Central, Trailing
    for tab_src_n := 0; tab_src_n < len(tab_bar.Tabs); tab_src_n += 1
    {
        tab := &tab_bar.Tabs[tab_src_n];
        if (tab.LastFrameVisible < tab_bar.PrevFrameVisible || tab.WantClose)
        {
            // Remove tab
            if (tab_bar.VisibleTabId == tab.ID) { tab_bar.VisibleTabId = 0; }
            if (tab_bar.SelectedTabId == tab.ID) { tab_bar.SelectedTabId = 0; }
            if (tab_bar.NextSelectedTabId == tab.ID) { tab_bar.NextSelectedTabId = 0; }
            continue;
        }
        if (tab_dst_n != tab_src_n) {
            tab_bar.Tabs[tab_dst_n] = tab_bar.Tabs[tab_src_n];
        }

        tab = &tab_bar.Tabs[tab_dst_n];
        tab.IndexDuringLayout = cast(u16) tab_dst_n;

        // We will need sorting if tabs have changed section (e.g. moved from one of Leading/Central/Trailing to another)
        curr_tab_section_n := TabItemGetSectionIdx(tab);
        if (tab_dst_n > 0)
        {
            prev_tab := &tab_bar.Tabs[tab_dst_n - 1];
            prev_tab_section_n := TabItemGetSectionIdx(prev_tab);
            if (curr_tab_section_n == 0 && prev_tab_section_n != 0) {
                need_sort_by_section = true;
            }
            if (prev_tab_section_n == 2 && curr_tab_section_n != 2) {
                need_sort_by_section = true;
            }
        }

        sections[curr_tab_section_n].TabCount += 1;
        tab_dst_n += 1;
    }
    if (len(tab_bar.Tabs) != tab_dst_n) {
        tab_bar.Tabs.resize(tab_dst_n);
    }

    if (need_sort_by_section) {
        ImQsort(tab_bar.Tabs.Data, tab_bar.Tabs.Size, size_of(ImGuiTabItem), TabItemComparerBySection);
    }

    // Calculate spacing between sections
    sections[0].Spacing = sections[0].TabCount > 0 && (sections[1].TabCount + sections[2].TabCount) > 0 ? g.Style.ItemInnerSpacing.x : 0.0;
    sections[1].Spacing = sections[1].TabCount > 0 && sections[2].TabCount > 0 ? g.Style.ItemInnerSpacing.x : 0.0;

    // Setup next selected tab
    scroll_to_tab_id := 0;
    if (tab_bar.NextSelectedTabId)
    {
        tab_bar.SelectedTabId = tab_bar.NextSelectedTabId;
        tab_bar.NextSelectedTabId = 0;
        scroll_to_tab_id = tab_bar.SelectedTabId;
    }

    // Process order change request (we could probably process it when requested but it's just saner to do it in a single spot).
    if (tab_bar.ReorderRequestTabId != 0)
    {
        if (TabBarProcessReorder(tab_bar)) {
            if (tab_bar.ReorderRequestTabId == tab_bar.SelectedTabId) {
                scroll_to_tab_id = tab_bar.ReorderRequestTabId;
            }
        }
        tab_bar.ReorderRequestTabId = 0;
    }

    // Tab List Popup (will alter tab_bar.BarRect and therefore the available width!)
    tab_list_popup_button := (.TabListPopupButton in tab_bar.Flags) != 0;
    if (tab_list_popup_button) {
        if tab_to_select := TabBarTabListPopupButton(tab_bar); tab_to_select != nil { // NB: Will alter BarRect.Min.x!
            tab_bar.SelectedTabId = tab_to_select.ID;
            scroll_to_tab_id = tab_bar.SelectedTabId
        }
    }

    // Leading/Trailing tabs will be shrink only if central one aren't visible anymore, so layout the shrink data as: leading, trailing, central
    // (whereas our tabs are stored as: leading, central, trailing)
    shrink_buffer_indexes := [3]i32 { 0, sections[0].TabCount + sections[2].TabCount, sections[0].TabCount };
    g.ShrinkWidthBuffer.resize(tab_bar.Tabs.Size);

    // Compute ideal tabs widths + store them into shrink buffer
    most_recently_selected_tab := nil;
    curr_section_n := -1;
    found_selected_tab_id := false;
    for tab_n := 0; tab_n < len(tab_bar.Tabs); tab_n += 1
    {
        tab := &tab_bar.Tabs[tab_n];
        assert(tab.LastFrameVisible >= tab_bar.PrevFrameVisible);

        if ((most_recently_selected_tab == nil || most_recently_selected_tab.LastFrameSelected < tab.LastFrameSelected) && !(.Button in tab.Flags)) {
            most_recently_selected_tab = tab;
        }
        if (tab.ID == tab_bar.SelectedTabId) {
            found_selected_tab_id = true;
        }
        if (scroll_to_tab_id == 0 && g.NavJustMovedToId == tab.ID) {
            scroll_to_tab_id = tab.ID
        }

        // Refresh tab width immediately, otherwise changes of style e.g. style.FramePadding.x would noticeably lag in the tab bar.
        // Additionally, when using TabBarAddTab() to manipulate tab bar order we occasionally insert new tabs that don't have a width yet,
        // and we cannot wait for the next BeginTabItem() call. We cannot compute this width within TabBarAddTab() because font size depends on the active window.
        tab_name := TabBarGetTabName(tab_bar, tab);
        has_close_button_or_unsaved_marker := (.NoCloseButton not_in tab.Flags) || (.UnsavedDocument in tab.Flags);
        tab.ContentWidth = (tab.RequestedWidth >= 0.0) ? tab.RequestedWidth : TabItemCalcSize(tab_name, has_close_button_or_unsaved_marker).x;

        section_n := TabItemGetSectionIdx(tab);
        section := &sections[section_n];
        section.Width += tab.ContentWidth + (section_n == curr_section_n ? g.Style.ItemInnerSpacing.x : 0.0);
        curr_section_n = section_n;

        // Store data so we can build an array sorted by width if we need to shrink tabs down
        shrink_width_item := &g.ShrinkWidthBuffer[shrink_buffer_indexes[section_n]];
        shrink_buffer_indexes[section_n] += 1
        shrink_width_item.Index = tab_n;
        shrink_width_item.InitialWidth = tab.ContentWidth;
        shrink_width_item.Width = tab.ContentWidth;
        tab.Width = ImMax(tab.ContentWidth, 1.0);
    }

    // Compute total ideal width (used for e.g. auto-resizing a window)
    tab_bar.WidthAllTabsIdeal = 0.0;
    for section_n := 0; section_n < 3; section_n += 1 {
        tab_bar.WidthAllTabsIdeal += sections[section_n].Width + sections[section_n].Spacing;
    }

    // Horizontal scrolling buttons
    // (note that TabBarScrollButtons() will alter BarRect.Max.x)
    if ((tab_bar.WidthAllTabsIdeal > tab_bar.BarRect.GetWidth() && len(tab_bar.Tabs) > 1) && !(.NoTabListScrollingButtons in tab_bar.Flags) && (.FittingPolicyScroll in tab_bar.Flags)) {
        if scroll_and_select_tab := TabBarScrollingButtons(tab_bar); scroll_and_select_tab != nil
        {
            scroll_to_tab_id = scroll_and_select_tab.ID;
            if ((.Button not_in scroll_and_select_tab.Flags)) {
                tab_bar.SelectedTabId = scroll_to_tab_id;
            }
        }
    }

    // Shrink widths if full tabs don't fit in their allocated space
    section_0_w := sections[0].Width + sections[0].Spacing;
    section_1_w := sections[1].Width + sections[1].Spacing;
    section_2_w := sections[2].Width + sections[2].Spacing;
    central_section_is_visible := (section_0_w + section_2_w) < tab_bar.BarRect.GetWidth();
    width_excess : f32
    if (central_section_is_visible) {
        width_excess = ImMax(section_1_w - (tab_bar.BarRect.GetWidth() - section_0_w - section_2_w), 0.0); // Excess used to shrink central section
    }
    else {
        width_excess = (section_0_w + section_2_w) - tab_bar.BarRect.GetWidth(); // Excess used to shrink leading/trailing section
    }

    // With ImGuiTabBarFlags_FittingPolicyScroll policy, we will only shrink leading/trailing if the central section is not visible anymore
    if (width_excess >= 1.0 && ((.FittingPolicyResizeDown in tab_bar.Flags) || !central_section_is_visible))
    {
        shrink_data_count := (central_section_is_visible ? sections[1].TabCount : sections[0].TabCount + sections[2].TabCount);
        shrink_data_offset := (central_section_is_visible ? sections[0].TabCount + sections[2].TabCount : 0);
        ShrinkWidths(g.ShrinkWidthBuffer.Data + shrink_data_offset, shrink_data_count, width_excess);

        // Apply shrunk values into tabs and sections
        for tab_n := shrink_data_offset; tab_n < shrink_data_offset + shrink_data_count; tab_n += 1
        {
            tab := &tab_bar.Tabs[g.ShrinkWidthBuffer[tab_n].Index];
            shrinked_width := math.trunc(g.ShrinkWidthBuffer[tab_n].Width);
            if (shrinked_width < 0.0)   do continue

            shrinked_width = ImMax(1.0, shrinked_width);
            section_n := TabItemGetSectionIdx(tab);
            sections[section_n].Width -= (tab.Width - shrinked_width);
            tab.Width = shrinked_width;
        }
    }

    // Layout all active tabs
    section_tab_index := 0;
    tab_offset := 0.0;
    tab_bar.WidthAllTabs = 0.0;
    for section_n := 0; section_n < 3; section_n += 1
    {
        section := &sections[section_n];
        if (section_n == 2) {
            tab_offset = ImMin(ImMax(0.0, tab_bar.BarRect.GetWidth() - section.Width), tab_offset);
        }

        for tab_n := 0; tab_n < section.TabCount; tab_n += 1
        {
            tab := &tab_bar.Tabs[section_tab_index + tab_n];
            tab.Offset = tab_offset;
            tab.NameOffset = -1;
            tab_offset += tab.Width + (tab_n < section.TabCount - 1 ? g.Style.ItemInnerSpacing.x : 0.0);
        }
        tab_bar.WidthAllTabs += ImMax(section.Width + section.Spacing, 0.0);
        tab_offset += section.Spacing;
        section_tab_index += section.TabCount;
    }

    // Clear name buffers
    tab_bar.TabsNames.Buf.resize(0);

    // If we have lost the selected tab, select the next most recently active one
    if (found_selected_tab_id == false)   do tab_bar.SelectedTabId = 0
    if (tab_bar.SelectedTabId == 0 && tab_bar.NextSelectedTabId == 0 && most_recently_selected_tab != nil) {
        tab_bar.SelectedTabId = most_recently_selected_tab.ID;
        scroll_to_tab_id = tab_bar.SelectedTabId;
    }

    // Lock in visible tab
    tab_bar.VisibleTabId = tab_bar.SelectedTabId;
    tab_bar.VisibleTabWasSubmitted = false;

    // CTRL+TAB can override visible tab temporarily
    if (g.NavWindowingTarget != nil && g.NavWindowingTarget.DockNode && g.NavWindowingTarget.DockNode.TabBar == tab_bar) {
        scroll_to_tab_id = g.NavWindowingTarget.TabId;
        tab_bar.VisibleTabId = scroll_to_tab_id;
    }

    // Apply request requests
    if (scroll_to_tab_id != 0) {
        TabBarScrollToTab(tab_bar, scroll_to_tab_id, sections);
    }
    else if ((.FittingPolicyScroll in tab_bar.Flags) && IsMouseHoveringRect(tab_bar.BarRect.Min, tab_bar.BarRect.Max, true) && IsWindowContentHoverable(g.CurrentWindow))
    {
        wheel := g.IO.MouseWheelRequestAxisSwap ? g.IO.MouseWheel : g.IO.MouseWheelH;
        wheel_key := g.IO.MouseWheelRequestAxisSwap ? ImGuiKey.MouseWheelY : ImGuiKey.MouseWheelX;
        if (TestKeyOwner(wheel_key, tab_bar.ID) && wheel != 0.0)
        {
            scroll_step := wheel * TabBarCalcScrollableWidth(tab_bar, sections) / 3.0;
            tab_bar.ScrollingTargetDistToVisibility = 0.0;
            tab_bar.ScrollingTarget = TabBarScrollClamp(tab_bar, tab_bar.ScrollingTarget - scroll_step);
        }
        SetKeyOwner(wheel_key, tab_bar.ID);
    }

    // Update scrolling
    tab_bar.ScrollingAnim = TabBarScrollClamp(tab_bar, tab_bar.ScrollingAnim);
    tab_bar.ScrollingTarget = TabBarScrollClamp(tab_bar, tab_bar.ScrollingTarget);
    if (tab_bar.ScrollingAnim != tab_bar.ScrollingTarget)
    {
        // Scrolling speed adjust itself so we can always reach our target in 1/3 seconds.
        // Teleport if we are aiming far off the visible line
        tab_bar.ScrollingSpeed = ImMax(tab_bar.ScrollingSpeed, 70.0 * g.FontSize);
        tab_bar.ScrollingSpeed = ImMax(tab_bar.ScrollingSpeed, ImAbs(tab_bar.ScrollingTarget - tab_bar.ScrollingAnim) / 0.3);
        teleport := (tab_bar.PrevFrameVisible + 1 < g.FrameCount) || (tab_bar.ScrollingTargetDistToVisibility > 10.0 * g.FontSize);
        tab_bar.ScrollingAnim = teleport ? tab_bar.ScrollingTarget : ImLinearSweep(tab_bar.ScrollingAnim, tab_bar.ScrollingTarget, g.IO.DeltaTime * tab_bar.ScrollingSpeed);
    }
    else
    {
        tab_bar.ScrollingSpeed = 0.0;
    }
    tab_bar.ScrollingRectMinX = tab_bar.BarRect.Min.x + sections[0].Width + sections[0].Spacing;
    tab_bar.ScrollingRectMaxX = tab_bar.BarRect.Max.x - sections[2].Width - sections[1].Spacing;

    // Actual layout in host window (we don't do it in BeginTabBar() so as not to waste an extra frame)
    window := g.CurrentWindow;
    window.DC.CursorPos = tab_bar.BarRect.Min;
    ItemSize(ImVec2{tab_bar.WidthAllTabs, tab_bar.BarRect.GetHeight()}, tab_bar.FramePadding.y);
    window.DC.IdealMaxPos.x = ImMax(window.DC.IdealMaxPos.x, tab_bar.BarRect.Min.x + tab_bar.WidthAllTabsIdeal);
}

// Dockable windows uses Name/ID in the global namespace. Non-dockable items use the ID stack.
TabBarCalcTabID :: proc(tab_bar : ^ImGuiTabBar, label : string, docked_window : ^ImGuiWindow) -> u32
{
    if (docked_window != nil)
    {
        _ = tab_bar;
        assert(.DockNode in tab_bar.Flags);
        id := docked_window.TabId;
        KeepAliveID(id);
        return id;
    }
    else
    {
        window := GImGui.CurrentWindow;
        return GetID(window, label);
    }
}

TabBarCalcMaxTabWidth :: proc() -> f32
{
    g := GImGui;
    return g.FontSize * 20.0;
}

TabBarFindTabByID :: proc(tab_bar : ^ImGuiTabBar, tab_id : ImGuiID) -> ^ImGuiTabItem
{
    if (tab_id != 0) {
        for n := 0; n < len(tab_bar.Tabs); n += 1 {
            if (tab_bar.Tabs[n].ID == tab_id) {
                return &tab_bar.Tabs[n]
            }
        }
    }
    return nil;
}

// Order = visible order, not submission order! (which is tab.BeginOrder)
TabBarFindTabByOrder :: proc(tab_bar : ^ImGuiTabBar, order : i32) -> ^ImGuiTabItem
{
    if (order < 0 || order >= tab_bar.Tabs.Size)   do return nil
    return &tab_bar.Tabs[order];
}

// FIXME: See references to #2304 in TODO.txt
TabBarFindMostRecentlySelectedTabForActiveWindow :: proc(tab_bar : ^ImGuiTabBar) -> ^ImGuiTabItem
{
    most_recently_selected_tab := nil;
    for tab_n := 0; tab_n < len(tab_bar.Tabs); tab_n += 1
    {
        tab := &tab_bar.Tabs[tab_n];
        if (most_recently_selected_tab == nil || most_recently_selected_tab.LastFrameSelected < tab.LastFrameSelected) {
            if (tab.Window && tab.Window.WasActive) {
                most_recently_selected_tab = tab;
            }
        }
    }
    return most_recently_selected_tab;
}

TabBarGetCurrentTab :: proc(tab_bar : ^ImGuiTabBar) -> ^ImGuiTabItem
{
    if (tab_bar.LastTabItemIdx < 0 || tab_bar.LastTabItemIdx >= tab_bar.Tabs.Size)   do return nil
    return &tab_bar.Tabs[tab_bar.LastTabItemIdx];
}

TabBarGetTabName :: proc(tab_bar : ^ImGuiTabBar, tab : ^ImGuiTabItem) -> ^u8
{
    if (tab.Window)   do return tab.Window.Name
    if (tab.NameOffset == -1)   do return "N/A"
    assert(tab.NameOffset < tab_bar.TabsNames.Buf.Size);
    return tab_bar.TabsNames.Buf.Data + tab.NameOffset;
}

// The purpose of this call is to register tab in advance so we can control their order at the time they appear.
// Otherwise calling this is unnecessary as tabs are appending as needed by the BeginTabItem() function.
TabBarAddTab :: proc(tab_bar : ^ImGuiTabBar, tab_flags : ImGuiTabItemFlags, window : ^ImGuiWindow)
{
    g := GImGui;
    assert(TabBarFindTabByID(tab_bar, window.TabId) == nil);
    assert(g.CurrentTabBar != tab_bar);  // Can't work while the tab bar is active as our tab doesn't have an X offset yet, in theory we could/should test something like (tab_bar.CurrFrameVisible < g.FrameCount) but we'd need to solve why triggers the commented early-out assert in BeginTabBarEx() (probably dock node going from implicit to explicit in same frame)

    if (!window.HasCloseButton) {
        tab_flags |= ImGuiTabItemFlags_NoCloseButton;       // Set _NoCloseButton immediately because it will be used for first-frame width calculation.
    }

    new_tab : ImGuiTabItem
    new_tab.ID = window.TabId;
    new_tab.Flags = tab_flags;
    new_tab.LastFrameVisible = tab_bar.CurrFrameVisible;   // Required so BeginTabBar() doesn't ditch the tab
    if (new_tab.LastFrameVisible == -1) {
        new_tab.LastFrameVisible = g.FrameCount - 1;
    }
    new_tab.Window = window;                                // Required so tab bar layout can compute the tab width before tab submission
    tab_bar.Tabs.append(new_tab);
}

// The *TabId fields are already set by the docking system _before_ the actual TabItem was created, so we clear them regardless.
TabBarRemoveTab :: proc(tab_bar : ^ImGuiTabBar, tab_id : ImGuiID)
{
    if tab := TabBarFindTabByID(tab_bar, tab_id); tab != nil   do tab_bar.Tabs.erase(tab)
    if (tab_bar.VisibleTabId == tab_id)      { tab_bar.VisibleTabId = 0; }
    if (tab_bar.SelectedTabId == tab_id)     { tab_bar.SelectedTabId = 0; }
    if (tab_bar.NextSelectedTabId == tab_id) { tab_bar.NextSelectedTabId = 0; }
}

// Called on manual closure attempt
TabBarCloseTab :: proc(tab_bar : ^ImGuiTabBar, tab : ^ImGuiTabItem)
{
    if (.Button in tab.Flags)   do return // A button appended with TabItemButton().

    if ((tab.Flags & (ImGuiTabItemFlags_UnsavedDocument | ImGuiTabItemFlags_NoAssumedClosure)) == 0)
    {
        // This will remove a frame of lag for selecting another tab on closure.
        // However we don't run it in the case where the 'Unsaved' flag is set, so user gets a chance to fully undo the closure
        tab.WantClose = true;
        if (tab_bar.VisibleTabId == tab.ID)
        {
            tab.LastFrameVisible = -1;
            tab_bar.SelectedTabId = 0
            tab_bar.NextSelectedTabId = 0;
        }
    }
    else
    {
        // Actually select before expecting closure attempt (on an UnsavedDocument tab user is expect to e.g. show a popup)
        if (tab_bar.VisibleTabId != tab.ID) {
            TabBarQueueFocus(tab_bar, tab);
        }
    }
}

TabBarScrollClamp :: proc(tab_bar : ^ImGuiTabBar, scrolling : f32) -> f32
{
    scrolling = ImMin(scrolling, tab_bar.WidthAllTabs - tab_bar.BarRect.GetWidth());
    return ImMax(scrolling, 0.0);
}

// Note: we may scroll to tab that are not selected! e.g. using keyboard arrow keys
TabBarScrollToTab :: proc(tab_bar : ^ImGuiTabBar, tab_id : ImGuiID, sections : ^ImGuiTabBarSection)
{
    tab := TabBarFindTabByID(tab_bar, tab_id);
    if (tab == nil)   do return
    if (tab.Flags & ImGuiTabItemFlags_SectionMask_)   do return

    g := GImGui;
    margin := g.FontSize * 1.0; // When to scroll to make Tab N+1 visible always make a bit of N visible to suggest more scrolling area (since we don't have a scrollbar)
    order := TabBarGetTabOrder(tab_bar, tab);

    // Scrolling happens only in the central section (leading/trailing sections are not scrolling)
    scrollable_width := TabBarCalcScrollableWidth(tab_bar, sections);

    // We make all tabs positions all relative Sections[0].Width to make code simpler
    tab_x1 := tab.Offset - sections[0].Width + (order > sections[0].TabCount - 1 ? -margin : 0.0);
    tab_x2 := tab.Offset - sections[0].Width + tab.Width + (order + 1 < len(tab_bar.Tabs) - sections[2].TabCount ? margin : 1.0);
    tab_bar.ScrollingTargetDistToVisibility = 0.0;
    if (tab_bar.ScrollingTarget > tab_x1 || (tab_x2 - tab_x1 >= scrollable_width))
    {
        // Scroll to the left
        tab_bar.ScrollingTargetDistToVisibility = ImMax(tab_bar.ScrollingAnim - tab_x2, 0.0);
        tab_bar.ScrollingTarget = tab_x1;
    }
    else if (tab_bar.ScrollingTarget < tab_x2 - scrollable_width)
    {
        // Scroll to the right
        tab_bar.ScrollingTargetDistToVisibility = ImMax((tab_x1 - scrollable_width) - tab_bar.ScrollingAnim, 0.0);
        tab_bar.ScrollingTarget = tab_x2 - scrollable_width;
    }
}

TabBarQueueFocus_itm :: proc(tab_bar : ^ImGuiTabBar, tab : ^ImGuiTabItem)
{
    tab_bar.NextSelectedTabId = tab.ID;
}

TabBarQueueFocus_name :: proc(tab_bar : ^ImGuiTabBar, tab_name : ^u8)
{
    assert((.DockNode not_in tab_bar.Flags)); // Only supported for manual/explicit tab bars
    tab_id := TabBarCalcTabID(tab_bar, tab_name, nil);
    tab_bar.NextSelectedTabId = tab_id;
}

TabBarQueueFocus :: proc { TabBarQueueFocus_itm, TabBarQueueFocus_name }

TabBarQueueReorder :: proc(tab_bar : ^ImGuiTabBar, tab : ^ImGuiTabItem, offset : i32)
{
    assert(offset != 0);
    assert(tab_bar.ReorderRequestTabId == 0);
    tab_bar.ReorderRequestTabId = tab.ID;
    tab_bar.ReorderRequestOffset = cast(u16) offset;
}

TabBarQueueReorderFromMousePos :: proc(tab_bar : ^ImGuiTabBar, src_tab : ^ImGuiTabItem, mouse_pos : ImVec2)
{
    g := GImGui;
    assert(tab_bar.ReorderRequestTabId == 0);
    if ((.Reorderable not_in tab_bar.Flags))   do return

    is_central_section := (src_tab.Flags & ImGuiTabItemFlags_SectionMask_) == 0;
    bar_offset := tab_bar.BarRect.Min.x - (is_central_section ? tab_bar.ScrollingTarget : 0);

    // Count number of contiguous tabs we are crossing over
    dir := (bar_offset + src_tab.Offset) > mouse_pos.x ? -1 : +1;
    src_idx := tab_bar.Tabs.index_from_ptr(src_tab);
    dst_idx := src_idx;
    for i := src_idx; i >= 0 && i < len(tab_bar.Tabs); i += dir
    {
        // Reordered tabs must share the same section
        dst_tab := &tab_bar.Tabs[i];
        if (.NoReorder in dst_tab.Flags)   do break
        if ((dst_tab.Flags & ImGuiTabItemFlags_SectionMask_) != (src_tab.Flags & ImGuiTabItemFlags_SectionMask_))   do break
        dst_idx = i;

        // Include spacing after tab, so when mouse cursor is between tabs we would not continue checking further tabs that are not hovered.
        x1 := bar_offset + dst_tab.Offset - g.Style.ItemInnerSpacing.x;
        x2 := bar_offset + dst_tab.Offset + dst_tab.Width + g.Style.ItemInnerSpacing.x;
        //AddRect(GetForegroundDrawList(), ImVec2{x1, tab_bar.BarRect.Min.y}, ImVec2{x2, tab_bar.BarRect.Max.y}, IM_COL32(255, 0, 0, 255));
        if ((dir < 0 && mouse_pos.x > x1) || (dir > 0 && mouse_pos.x < x2))   do break
    }

    if (dst_idx != src_idx) {
        TabBarQueueReorder(tab_bar, src_tab, dst_idx - src_idx);
    }
}

TabBarProcessReorder :: proc(tab_bar : ^ImGuiTabBar) -> bool
{
    tab1 := TabBarFindTabByID(tab_bar, tab_bar.ReorderRequestTabId);
    if (tab1 == nil || (.NoReorder in tab1.Flags))   do return false

    //assert(tab_bar.Flags & ImGuiTabBarFlags_Reorderable); // <- this may happen when using debug tools
    tab2_order := TabBarGetTabOrder(tab_bar, tab1) + tab_bar.ReorderRequestOffset;
    if (tab2_order < 0 || tab2_order >= tab_bar.Tabs.Size)   do return false

    // Reordered tabs must share the same section
    // (Note: TabBarQueueReorderFromMousePos() also has a similar test but since we allow direct calls to TabBarQueueReorder() we do it here too)
    tab2 := &tab_bar.Tabs[tab2_order];
    if (.NoReorder in tab2.Flags)   do return false
    if ((tab1.Flags & ImGuiTabItemFlags_SectionMask_) != (tab2.Flags & ImGuiTabItemFlags_SectionMask_))   do return false

    item_tmp := tab1^;
    src_tab := (tab_bar.ReorderRequestOffset > 0) ? tab1 + 1 : tab2;
    dst_tab := (tab_bar.ReorderRequestOffset > 0) ? tab1 : tab2 + 1;
    move_count := (tab_bar.ReorderRequestOffset > 0) ? tab_bar.ReorderRequestOffset : -tab_bar.ReorderRequestOffset;
    memmove(dst_tab, src_tab, move_count * size_of(ImGuiTabItem));
    tab2^ = item_tmp;

    if (.SaveSettings in tab_bar.Flags)   do MarkIniSettingsDirty()
    return true;
}

TabBarScrollingButtons :: proc(tab_bar : ^ImGuiTabBar) -> ^ImGuiTabItem
{
    g := GImGui;
    window := g.CurrentWindow;

    arrow_button_size := ImVec2{g.FontSize - 2.0, g.FontSize + g.Style.FramePadding.y * 2.0};
    scrolling_buttons_width := arrow_button_size.x * 2.0;

    backup_cursor_pos := window.DC.CursorPos;
    //window.DrawList.AddRect(ImVec2{tab_bar.BarRect.Max.x - scrolling_buttons_width, tab_bar.BarRect.Min.y}, ImVec2{tab_bar.BarRect.Max.x, tab_bar.BarRect.Max.y}, IM_COL32(255,0,0,255));

    select_dir := 0;
    arrow_col := g.Style.Colors[ImGuiCol.Text];
    arrow_col.w *= 0.5;

    PushStyleColor(ImGuiCol.Text, arrow_col);
    PushStyleColor(ImGuiCol.Button, ImVec4{0, 0, 0, 0});
    PushItemFlag(ImGuiItemFlags_ButtonRepeat, true);
    backup_repeat_delay := g.IO.KeyRepeatDelay;
    backup_repeat_rate := g.IO.KeyRepeatRate;
    g.IO.KeyRepeatDelay = 0.250;
    g.IO.KeyRepeatRate = 0.200;
    x := ImMax(tab_bar.BarRect.Min.x, tab_bar.BarRect.Max.x - scrolling_buttons_width);
    window.DC.CursorPos = ImVec2{x, tab_bar.BarRect.Min.y};
    if (ArrowButtonEx("##<", .Left, arrow_button_size, ImGuiButtonFlags_PressedOnClick))   do select_dir = -1
    window.DC.CursorPos = ImVec2{x + arrow_button_size.x, tab_bar.BarRect.Min.y};
    if (ArrowButtonEx("##>", .Right, arrow_button_size, ImGuiButtonFlags_PressedOnClick))   do select_dir = +1
    PopItemFlag();
    PopStyleColor(2);
    g.IO.KeyRepeatRate = backup_repeat_rate;
    g.IO.KeyRepeatDelay = backup_repeat_delay;

    tab_to_scroll_to := nil;
    if (select_dir != 0) {
        if tab_item := TabBarFindTabByID(tab_bar, tab_bar.SelectedTabId); tab_itme != nil
        {
            selected_order := TabBarGetTabOrder(tab_bar, tab_item);
            target_order := selected_order + select_dir;

            // Skip tab item buttons until another tab item is found or end is reached
            for (tab_to_scroll_to == nil)
            {
                // If we are at the end of the list, still scroll to make our tab visible
                tab_to_scroll_to = &tab_bar.Tabs[(target_order >= 0 && target_order < tab_bar.Tabs.Size) ? target_order : selected_order];

                // Cross through buttons
                // (even if first/last item is a button, return it so we can update the scroll)
                if (.Button in tab_to_scroll_to.Flags)
                {
                    target_order += select_dir;
                    selected_order += select_dir;
                    tab_to_scroll_to = (target_order < 0 || target_order >= tab_bar.Tabs.Size) ? tab_to_scroll_to : nil;
                }
            }
        }
    }
    window.DC.CursorPos = backup_cursor_pos;
    tab_bar.BarRect.Max.x -= scrolling_buttons_width + 1.0;

    return tab_to_scroll_to;
}

TabBarTabListPopupButton :: proc(tab_bar : ^ImGuiTabBar) -> ^ImGuiTabItem
{
    g := GImGui;
    window := g.CurrentWindow;

    // We use g.Style.FramePadding.y to match the square ArrowButton size
    tab_list_popup_button_width := g.FontSize + g.Style.FramePadding.y;
    backup_cursor_pos := window.DC.CursorPos;
    window.DC.CursorPos = ImVec2{tab_bar.BarRect.Min.x - g.Style.FramePadding.y, tab_bar.BarRect.Min.y};
    tab_bar.BarRect.Min.x += tab_list_popup_button_width;

    arrow_col := g.Style.Colors[ImGuiCol.Text];
    arrow_col.w *= 0.5;
    PushStyleColor(ImGuiCol.Text, arrow_col);
    PushStyleColor(ImGuiCol.Button, ImVec4{0, 0, 0, 0});
    open := BeginCombo("##v", nil, ImGuiComboFlags_NoPreview | ImGuiComboFlags_HeightLargest);
    PopStyleColor(2);

    tab_to_select := nil;
    if (open)
    {
        for tab_n := 0; tab_n < len(tab_bar.Tabs); tab_n += 1
        {
            tab := &tab_bar.Tabs[tab_n];
            if (.Button in tab.Flags)   do continue

            tab_name := TabBarGetTabName(tab_bar, tab);
            if (Selectable(tab_name, tab_bar.SelectedTabId == tab.ID))   do tab_to_select = tab
        }
        EndCombo();
    }

    window.DC.CursorPos = backup_cursor_pos;
    return tab_to_select;
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: BeginTabItem, EndTabItem, etc.
//-------------------------------------------------------------------------
// - BeginTabItem()
// - EndTabItem()
// - TabItemButton()
// - TabItemEx() [Internal]
// - SetTabItemClosed()
// - TabItemCalcSize() [Internal]
// - TabItemBackground() [Internal]
// - TabItemLabelAndCloseButton() [Internal]
//-------------------------------------------------------------------------

// [forward declared comment]:
// create a Tab. Returns true if the Tab is selected.
BeginTabItem :: proc(label : string, p_open : ^bool = nil, flags : ImGuiTabItemFlags = {}) -> bool
{
    g := GImGui;
    window := g.CurrentWindow;
    if (window.SkipItems)   do return false

    tab_bar := g.CurrentTabBar;
    if (tab_bar == nil)
    {
        IM_ASSERT_USER_ERROR(tab_bar, "Needs to be called between BeginTabBar() and EndTabBar()!");
        return false;
    }
    assert((.Button not_in flags));             // BeginTabItem() Can't be used with button flags, use TabItemButton() instead!

    ret := TabItemEx(tab_bar, label, p_open, flags, nil);
    if (ret && !(.NoPushId in flags))
    {
        tab := &tab_bar.Tabs[tab_bar.LastTabItemIdx];
        PushOverrideID(tab.ID); // We already hashed 'label' so push into the ID stack directly instead of doing another hash through PushID(label)
    }
    return ret;
}

// [forward declared comment]:
// only call EndTabItem() if BeginTabItem() returns true!
EndTabItem :: proc()
{
    g := GImGui;
    window := g.CurrentWindow;
    if (window.SkipItems)   do return

    tab_bar := g.CurrentTabBar;
    if (tab_bar == nil)
    {
        IM_ASSERT_USER_ERROR(tab_bar != nil, "Needs to be called between BeginTabBar() and EndTabBar()!");
        return;
    }
    assert(tab_bar.LastTabItemIdx >= 0);
    tab := &tab_bar.Tabs[tab_bar.LastTabItemIdx];
    if (!(.NoPushId in tab.Flags))   do PopID()
}

// [forward declared comment]:
// create a Tab behaving like a button. return true when clicked. cannot be selected in the tab bar.
TabItemButton :: proc(label : string, flags : ImGuiTabItemFlags = {}) -> bool
{
    g := GImGui;
    window := g.CurrentWindow;
    if (window.SkipItems)   do return false

    tab_bar := g.CurrentTabBar;
    if (tab_bar == nil)
    {
        IM_ASSERT_USER_ERROR(tab_bar != nil, "Needs to be called between BeginTabBar() and EndTabBar()!");
        return false;
    }
    return TabItemEx(tab_bar, label, nil, flags | ImGuiTabItemFlags_Button | ImGuiTabItemFlags_NoReorder, nil);
}

TabItemEx :: proc(tab_bar : ^ImGuiTabBar, label : string, p_open : ^bool, flags : ImGuiTabItemFlags, docked_window : ^ImGuiWindow) -> bool
{
    // Layout whole tab bar if not already done
    g := GImGui;
    if (tab_bar.WantLayout)
    {
        backup_next_item_data := g.NextItemData;
        TabBarLayout(tab_bar);
        g.NextItemData = backup_next_item_data;
    }
    window := g.CurrentWindow;
    if (window.SkipItems)   do return false

    style := &g.Style;
    id := TabBarCalcTabID(tab_bar, label, docked_window);

    // If the user called us with *p_open == false, we early out and don't render.
    // We make a call to ItemAdd() so that attempts to use a contextual popup menu with an implicit ID won't use an older ID.
    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags);
    if (p_open != nil && !p_open^)
    {
        ItemAdd(ImRect(), id, nil, ImGuiItemFlags_NoNav);
        return false;
    }

    assert(!p_open || !(.Button in flags));
    assert((flags & (ImGuiTabItemFlags_Leading | ImGuiTabItemFlags_Trailing)) != (ImGuiTabItemFlags_Leading | ImGuiTabItemFlags_Trailing)); // Can't use both Leading and Trailing

    // Store into ImGuiTabItemFlags_NoCloseButton, also honor ImGuiTabItemFlags_NoCloseButton passed by user (although not documented)
    if (.NoCloseButton in flags) {
        p_open = nil
    }
    else if (p_open == nil) {
        flags |= ImGuiTabItemFlags_NoCloseButton;
    }

    // Acquire tab data
    tab := TabBarFindTabByID(tab_bar, id);
    tab_is_new := false;
    if (tab == nil)
    {
        tab_bar.Tabs.append(ImGuiTabItem());
        tab = &tab_bar.Tabs.back();
        tab.ID = id;
        tab_bar.TabsAddedNew = true
        tab_is_new = true;
    }
    tab_bar.LastTabItemIdx = cast(u16) tab_bar.Tabs.index_from_ptr(tab);

    // Calculate tab contents size
    size := TabItemCalcSize(label, (p_open != nil) || (.UnsavedDocument in flags));
    tab.RequestedWidth = -1.0;
    if (.HasWidth in g.NextItemData.HasFlags) {
        tab.RequestedWidth = g.NextItemData.Width;
        size.x = tab.RequestedWidth
    }
    if (tab_is_new) {
        tab.Width = ImMax(1.0, size.x);
    }
    tab.ContentWidth = size.x;
    tab_bar.TabsActiveCount += 1;
    tab.BeginOrder = tab_bar.TabsActiveCount

    tab_bar_appearing := (tab_bar.PrevFrameVisible + 1 < g.FrameCount);
    tab_bar_focused := (.IsFocused in tab_bar.Flags) != 0;
    tab_appearing := (tab.LastFrameVisible + 1 < g.FrameCount);
    tab_just_unsaved := (.UnsavedDocument in flags) && !(.UnsavedDocument in tab.Flags);
    is_tab_button := (.Button in flags)
    tab.LastFrameVisible = g.FrameCount;
    tab.Flags = flags;
    tab.Window = docked_window;

    // Append name _WITH_ the zero-terminator
    // (regular tabs are permitted in a DockNode tab bar, but window tabs not permitted in a non-DockNode tab bar)
    if (docked_window != nil)
    {
        assert(.DockNode in tab_bar.Flags);
        tab.NameOffset = -1;
    }
    else
    {
        tab.NameOffset = cast(i32) tab_bar.TabsNames.size();
        tab_bar.TabsNames.append(label, label + strlen(label) + 1);
    }

    // Update selected tab
    if (!is_tab_button)
    {
        if (tab_appearing && (.AutoSelectNewTabs in tab_bar.Flags) && tab_bar.NextSelectedTabId == 0) {
            if (!tab_bar_appearing || tab_bar.SelectedTabId == 0) {
                TabBarQueueFocus(tab_bar, tab); // New tabs gets activated
            }
        }
        if ((.SetSelected in flags) && (tab_bar.SelectedTabId != id)) { // _SetSelected can only be passed on explicit tab bar
            TabBarQueueFocus(tab_bar, tab);
        }
    }

    // Lock visibility
    // (Note: tab_contents_visible != tab_selected... because CTRL+TAB operations may preview some tabs without selecting them!)
    tab_contents_visible := (tab_bar.VisibleTabId == id);
    if (tab_contents_visible) {
        tab_bar.VisibleTabWasSubmitted = true;
    }

    // On the very first frame of a tab bar we let first tab contents be visible to minimize appearing glitches
    if (!tab_contents_visible && tab_bar.SelectedTabId == 0 && tab_bar_appearing && docked_window == nil) {
        if (len(tab_bar.Tabs) == 1 && !(.AutoSelectNewTabs in tab_bar.Flags)) {
            tab_contents_visible = true;
        }
    }

    // Note that tab_is_new is not necessarily the same as tab_appearing! When a tab bar stops being submitted
    // and then gets submitted again, the tabs will have 'tab_appearing=true' but 'tab_is_new=false'.
    if (tab_appearing && (!tab_bar_appearing || tab_is_new))
    {
        ItemAdd(ImRect(), id, nil, ImGuiItemFlags_NoNav);
        if (is_tab_button)   do return false
        return tab_contents_visible;
    }

    if (tab_bar.SelectedTabId == id) {
        tab.LastFrameSelected = g.FrameCount;
    }

    // Backup current layout position
    backup_main_cursor_pos := window.DC.CursorPos;

    // Layout
    is_central_section := (tab.Flags & ImGuiTabItemFlags_SectionMask_) == 0;
    size.x = tab.Width;
    if (is_central_section) {
        window.DC.CursorPos = tab_bar.BarRect.Min + ImVec2{math.trunc(tab.Offset - tab_bar.ScrollingAnim), 0.0};
    }
    else {
        window.DC.CursorPos = tab_bar.BarRect.Min + ImVec2{tab.Offset, 0.0};
    }
    pos := window.DC.CursorPos;
    bb := ImRect{ _v = {pos, pos + size}};

    // We don't have CPU clipping primitives to clip the CloseButton (until it becomes a texture), so need to add an extra draw call (temporary in the case of vertical animation)
    want_clip_rect := is_central_section && (bb.Min.x < tab_bar.ScrollingRectMinX || bb.Max.x > tab_bar.ScrollingRectMaxX);
    if (want_clip_rect) {
        PushClipRect(ImVec2{ImMax(bb.Min.x, tab_bar.ScrollingRectMinX), bb.Min.y - 1}, ImVec2{tab_bar.ScrollingRectMaxX, bb.Max.y}, true);
    }

    backup_cursor_max_pos := window.DC.CursorMaxPos;
    ItemSize(bb.GetSize(), style.FramePadding.y);
    window.DC.CursorMaxPos = backup_cursor_max_pos;

    if (!ItemAdd(bb, id))
    {
        if (want_clip_rect)   do PopClipRect()
        window.DC.CursorPos = backup_main_cursor_pos;
        return tab_contents_visible;
    }

    // Click to Select a tab
    button_flags := ((is_tab_button ? ImGuiButtonFlags_PressedOnClickRelease : ImGuiButtonFlags_PressedOnClick) | ImGuiButtonFlags_AllowOverlap);
    if (g.DragDropActive && !g.DragDropPayload.IsDataType(IMGUI_PAYLOAD_TYPE_WINDOW)) {// FIXME: May be an opt-in property of the payload to disable this
        button_flags |= ImGuiButtonFlags_PressedOnDragDropHold;
    }
    hovered, held : bool
    pressed := ButtonBehavior(bb, id, &hovered, &held, button_flags);
    if (pressed && !is_tab_button) {
        TabBarQueueFocus(tab_bar, tab);
    }

    // Transfer active id window so the active id is not owned by the dock host (as StartMouseMovingWindow()
    // will only do it on the drag). This allows FocusWindow() to be more conservative in how it clears active id.
    if (held && docked_window && g.ActiveId == id && g.ActiveIdIsJustActivated) {
        g.ActiveIdWindow = docked_window;
    }

    // Drag and drop a single floating window node moves it
    node := docked_window ? docked_window.DockNode : nil;
    single_floating_window_node := node && node.IsFloatingNode() && (len(node.Windows) == 1);
    if (held && single_floating_window_node && IsMouseDragging(0, 0.0))
    {
        // Move
        StartMouseMovingWindow(docked_window);
    }
    else if (held && !tab_appearing && IsMouseDragging(0))
    {
        // Drag and drop: re-order tabs
        drag_dir := 0;
        drag_distance_from_edge_x := 0.0;
        if (!g.DragDropActive && ((.Reorderable in tab_bar.Flags) || (docked_window != nil)))
        {
            // While moving a tab it will jump on the other side of the mouse, so we also test for MouseDelta.x
            if (g.IO.MouseDelta.x < 0.0 && g.IO.MousePos.x < bb.Min.x)
            {
                drag_dir = -1;
                drag_distance_from_edge_x = bb.Min.x - g.IO.MousePos.x;
                TabBarQueueReorderFromMousePos(tab_bar, tab, g.IO.MousePos);
            }
            else if (g.IO.MouseDelta.x > 0.0 && g.IO.MousePos.x > bb.Max.x)
            {
                drag_dir = +1;
                drag_distance_from_edge_x = g.IO.MousePos.x - bb.Max.x;
                TabBarQueueReorderFromMousePos(tab_bar, tab, g.IO.MousePos);
            }
        }

        // Extract a Dockable window out of it's tab bar
        can_undock := docked_window != nil && !(.NoMove in docked_window.Flags) && !(.NoUndocking in node.MergedFlags);
        if (can_undock)
        {
            // We use a variable threshold to distinguish dragging tabs within a tab bar and extracting them out of the tab bar
            undocking_tab := (g.DragDropActive && g.DragDropPayload.SourceId == id);
            if (!undocking_tab) //&& (!g.IO.ConfigDockingWithShift || g.IO.KeyShift)
            {
                threshold_base := g.FontSize;
                threshold_x := (threshold_base * 2.2);
                threshold_y := (threshold_base * 1.5) + ImClamp((ImAbs(g.IO.MouseDragMaxDistanceAbs[0].x) - threshold_base * 2.0) * 0.20, 0.0, threshold_base * 4.0);
                //AddRect(GetForegroundDrawList(), ImVec2{bb.Min.x - threshold_x, bb.Min.y - threshold_y}, ImVec2{bb.Max.x + threshold_x, bb.Max.y + threshold_y}, IM_COL32_WHITE); // [DEBUG]

                distance_from_edge_y := ImMax(bb.Min.y - g.IO.MousePos.y, g.IO.MousePos.y - bb.Max.y);
                if (distance_from_edge_y >= threshold_y)   do undocking_tab = true
                if (drag_distance_from_edge_x > threshold_x) {
                    if ((drag_dir < 0 && TabBarGetTabOrder(tab_bar, tab) == 0) || (drag_dir > 0 && TabBarGetTabOrder(tab_bar, tab) == len(tab_bar.Tabs) - 1)) {
                        undocking_tab = true
                    }
                }
            }

            if (undocking_tab)
            {
                // Undock
                // FIXME: refactor to share more code with e.g. StartMouseMovingWindow
                DockContextQueueUndockWindow(g, docked_window);
                g.MovingWindow = docked_window;
                SetActiveID(g.MovingWindow.MoveId, g.MovingWindow);
                g.ActiveIdClickOffset -= g.MovingWindow.Pos - bb.Min;
                g.ActiveIdNoClearOnFocusLoss = true;
                SetActiveIdUsingAllKeyboardKeys();
            }
        }
    }

when false {
    if (hovered && g.HoveredIdNotActiveTimer > TOOLTIP_DELAY && bb.GetWidth() < tab.ContentWidth)
    {
        // Enlarge tab display when hovering
        bb.Max.x = bb.Min.x + math.trunc(ImLerp(bb.GetWidth(), tab.ContentWidth, ImSaturate((g.HoveredIdNotActiveTimer - 0.40) * 6.0)));
        display_draw_list = GetForegroundDrawList(window);
        TabItemBackground(display_draw_list, bb, flags, GetColorU32(ImGuiCol.TitleBgActive));
    }
}

    // Render tab shape
    display_draw_list := window.DrawList;
    tab_col := GetColorU32((held || hovered) ? ImGuiCol.TabHovered : tab_contents_visible ? (tab_bar_focused ? ImGuiCol.TabSelected : ImGuiCol.TabDimmedSelected) : (tab_bar_focused ? ImGuiCol.Tab : ImGuiCol.TabDimmed));
    TabItemBackground(display_draw_list, bb, flags, tab_col);
    if (tab_contents_visible && (.DrawSelectedOverline in tab_bar.Flags) && style.TabBarOverlineSize > 0.0)
    {
        x_offset := math.trunc(0.4 * style.TabRounding);
        if (x_offset < 2.0 * g.CurrentDpiScale)   do x_offset = 0.0
        y_offset := 1.0 * g.CurrentDpiScale;
        display_draw_list.AddLine(bb.GetTL() + ImVec2{x_offset, y_offset}, bb.GetTR() + ImVec2{-x_offset, y_offset}, GetColorU32(tab_bar_focused ? ImGuiCol.TabSelectedOverline : ImGuiCol.TabDimmedSelectedOverline), style.TabBarOverlineSize);
    }
    RenderNavCursor(bb, id);

    // Select with right mouse button. This is so the common idiom for context menu automatically highlight the current widget.
    hovered_unblocked := IsItemHovered(ImGuiHoveredFlags_AllowWhenBlockedByPopup);
    if (tab_bar.SelectedTabId != tab.ID && hovered_unblocked && (IsMouseClicked(1) || IsMouseReleased(1)) && !is_tab_button) {
        TabBarQueueFocus(tab_bar, tab);
    }

    if (.NoCloseWithMiddleMouseButton in tab_bar.Flags) {
        flags |= ImGuiTabItemFlags_NoCloseWithMiddleMouseButton;
    }

    // Render tab label, process close button
    close_button_id := p_open ? GetIDWithSeed("#CLOSE", nil, docked_window ? docked_window.ID : id) : 0;
    just_closed : bool
    text_clipped : bool
    TabItemLabelAndCloseButton(display_draw_list, bb, tab_just_unsaved ? (flags & ~ImGuiTabItemFlags_UnsavedDocument) : flags, tab_bar.FramePadding, label, id, close_button_id, tab_contents_visible, &just_closed, &text_clipped);
    if (just_closed && p_open != nil)
    {
        p_open^ = false;
        TabBarCloseTab(tab_bar, tab);
    }

    // Forward Hovered state so IsItemHovered() after Begin() can work (even though we are technically hovering our parent)
    // That state is copied to window.DockTabItemStatusFlags by our caller.
    if (docked_window && (hovered || g.HoveredId == close_button_id)) {
        g.LastItemData.StatusFlags |= ImGuiItemStatusFlags_HoveredWindow;
    }

    // Restore main window position so user can draw there
    if (want_clip_rect)   do PopClipRect()
    window.DC.CursorPos = backup_main_cursor_pos;

    // Tooltip
    // (Won't work over the close button because ItemOverlap systems messes up with HoveredIdTimer-> seems ok)
    // (We test IsItemHovered() to discard e.g. when another item is active or drag and drop over the tab bar, which g.HoveredId ignores)
    // FIXME: This is a mess.
    // FIXME: We may want disabled tab to still display the tooltip?
    if (text_clipped && g.HoveredId == id && !held) {
        if (!(.NoTooltip in tab_bar.Flags) && !(.NoTooltip in tab.Flags)) {
            SetItemTooltip("%.*s", (i32)(FindRenderedText(label) - label), label);
        }
    }

    assert(!is_tab_button || !(tab_bar.SelectedTabId == tab.ID && is_tab_button)); // TabItemButton should not be selected
    if (is_tab_button)   do return pressed
    return tab_contents_visible;
}

// [Public] This is call is 100% optional but it allows to remove some one-frame glitches when a tab has been unexpectedly removed.
// To use it to need to call the function SetTabItemClosed() between BeginTabBar() and EndTabBar().
// Tabs closed by the close button will automatically be flagged to avoid this issue.
// [forward declared comment]:
// notify TabBar or Docking system of a closed tab/window ahead (useful to reduce visual flicker on reorderable tab bars). For tab-bar: call after BeginTabBar() and before Tab submissions. Otherwise call with a window name.
SetTabItemClosed :: proc(label : string)
{
    g := GImGui;
    is_within_manual_tab_bar := g.CurrentTabBar && !(.DockNode in g.CurrentTabBar.Flags);
    if (is_within_manual_tab_bar)
    {
        tab_bar := g.CurrentTabBar;
        tab_id := TabBarCalcTabID(tab_bar, label, nil);
        if tab := TabBarFindTabByID(tab_bar, tab_id); tab != nil {
            tab.WantClose = true; // Will be processed by next call to TabBarLayout()
        }
    }
    else if window := FindWindowByName(label); window != nil
    {
        if (window.DockIsActive) {
            if node := window.DockNode; node != nil
            {
                tab_id := TabBarCalcTabID(node.TabBar, label, window);
                TabBarRemoveTab(node.TabBar, tab_id);
                window.DockTabWantClose = true;
            }
        }
    }
}

TabItemCalcSize_ex :: proc(label : string, has_close_button_or_unsaved_marker : bool) -> ImVec2
{
    g := GImGui;
    label_size := CalcTextSize(label, nil, true);
    size := ImVec2{label_size.x + g.Style.FramePadding.x, label_size.y + g.Style.FramePadding.y * 2.0};
    if (has_close_button_or_unsaved_marker) {
        size.x += g.Style.FramePadding.x + (g.Style.ItemInnerSpacing.x + g.FontSize); // We use Y intentionally to fit the close button circle.
    }
    else {
        size.x += g.Style.FramePadding.x + 1.0;
    }
    return ImVec2{ImMin(size.x, TabBarCalcMaxTabWidth()), size.y};
}

TabItemCalcSize_basic :: proc(window : ^ImGuiWindow) -> ImVec2
{
    return TabItemCalcSize(window.Name, window.HasCloseButton || (.UnsavedDocument in window.Flags));
}

TabItemCalcSize :: proc { TabItemCalcSize_basic, TabItemCalcSize_ex }

TabItemBackground :: proc(draw_list : ^ImDrawList, bb : ^ImRect, flags : ImGuiTabItemFlags, col : u32)
{
    // While rendering tabs, we trim 1 pixel off the top of our bounding box so they can fit within a regular frame height while looking "detached" from it.
    g := GImGui;
    width := bb.GetWidth();
    _ = flags;
    assert(width > 0.0);
    rounding := ImMax(0.0, ImMin((.Button in flags) ? g.Style.FrameRounding : g.Style.TabRounding, width * 0.5 - 1.0));
    y1 := bb.Min.y + 1.0;
    y2 := bb.Max.y - g.Style.TabBarBorderSize;
    PathLineTo(draw_list, ImVec2{bb.Min.x, y2});
    PathArcToFast(draw_list, ImVec2{bb.Min.x + rounding, y1 + rounding}, rounding, 6, 9);
    PathArcToFast(draw_list, ImVec2{bb.Max.x - rounding, y1 + rounding}, rounding, 9, 12);
    PathLineTo(draw_list, ImVec2{bb.Max.x, y2});
    PathFillConvex(draw_list, col);
    if (g.Style.TabBorderSize > 0.0)
    {
        PathLineTo(draw_list, ImVec2{bb.Min.x + 0.5, y2});
        PathArcToFast(draw_list, ImVec2{bb.Min.x + rounding + 0.5, y1 + rounding + 0.5}, rounding, 6, 9);
        PathArcToFast(draw_list, ImVec2{bb.Max.x - rounding - 0.5, y1 + rounding + 0.5}, rounding, 9, 12);
        PathLineTo(draw_list, ImVec2{bb.Max.x - 0.5, y2});
        PathStroke(draw_list, GetColorU32(ImGuiCol.Border), 0, g.Style.TabBorderSize);
    }
}

// Render text label (with custom clipping) + Unsaved Document marker + Close Button logic
// We tend to lock style.FramePadding for a given tab-bar, hence the 'frame_padding' parameter.
TabItemLabelAndCloseButton :: proc(draw_list : ^ImDrawList, bb : ^ImRect, flags : ImGuiTabItemFlags, frame_padding : ImVec2, label : string, tab_id : ImGuiID, close_button_id : ImGuiID, is_contents_visible : bool, out_just_closed : ^bool, out_text_clipped : ^bool)
{
    g := GImGui;
    label_size := CalcTextSize(label, nil, true);

    if (out_just_closed)   do out_just_closed^ = false
    if (out_text_clipped)   do out_text_clipped^ = false

    if (bb.GetWidth() <= 1.0)   do return

    // In Style V2 we'll have full override of all colors per state (e.g. focused, selected)
    // But right now if you want to alter text color of tabs this is what you need to do.
when false {
    backup_alpha := g.Style.Alpha;
    if (!is_contents_visible)   do g.Style.Alpha *= 0.7
}

    // Render text label (with clipping + alpha gradient) + unsaved marker
    text_pixel_clip_bb := ImRect{ _r = {bb.Min.x + frame_padding.x, bb.Min.y + frame_padding.y, bb.Max.x - frame_padding.x, bb.Max.y}};
    text_ellipsis_clip_bb := text_pixel_clip_bb;

    // Return clipped state ignoring the close button
    if (out_text_clipped)
    {
        out_text_clipped^ = (text_ellipsis_clip_bb.Min.x + label_size.x) > text_pixel_clip_bb.Max.x;
        //draw_list.AddCircle(text_ellipsis_clip_bb.Min, 3.0f, *out_text_clipped ? IM_COL32(255, 0, 0, 255) : IM_COL32(0, 255, 0, 255));
    }

    button_sz := g.FontSize;
    button_pos := ImVec2(ImMax(bb.Min.x, bb.Max.x - frame_padding.x - button_sz), bb.Min.y + frame_padding.y);

    // Close Button & Unsaved Marker
    // We are relying on a subtle and confusing distinction between 'hovered' and 'g.HoveredId' which happens because we are using ImGuiButtonFlags_AllowOverlapMode + SetItemAllowOverlap()
    //  'hovered' will be true when hovering the Tab but NOT when hovering the close button
    //  'g.HoveredId==id' will be true when hovering the Tab including when hovering the close button
    //  'g.ActiveId==close_button_id' will be true when we are holding on the close button, in which case both hovered booleans are false
    close_button_pressed := false;
    close_button_visible := false;
    if (close_button_id != 0) {
        if (is_contents_visible || bb.GetWidth() >= ImMax(button_sz, g.Style.TabMinWidthForCloseButton)) {
            if (g.HoveredId == tab_id || g.HoveredId == close_button_id || g.ActiveId == tab_id || g.ActiveId == close_button_id) {
                close_button_visible = true;
            }
        }
    }
    unsaved_marker_visible := (.UnsavedDocument in flags) != 0 && (button_pos.x + button_sz <= bb.Max.x);

    if (close_button_visible)
    {
        last_item_backup := g.LastItemData;
        if (CloseButton(close_button_id, button_pos)) {
            close_button_pressed = true;
        }
        g.LastItemData = last_item_backup;

        // Close with middle mouse button
        if (!(.NoCloseWithMiddleMouseButton in flags) && IsMouseClicked(2)) {
            close_button_pressed = true;
        }
    }
    else if (unsaved_marker_visible)
    {
        bullet_bb := ImRect(button_pos, button_pos + ImVec2{button_sz, button_sz});
        RenderBullet(draw_list, bullet_bb.GetCenter(), GetColorU32(ImGuiCol.Text));
    }

    // This is all rather complicated
    // (the main idea is that because the close button only appears on hover, we don't want it to alter the ellipsis position)
    // FIXME: if FramePadding is noticeably large, ellipsis_max_x will be wrong here (e.g. #3497), maybe for consistency that parameter of RenderTextEllipsis() shouldn't exist..
    ellipsis_max_x := close_button_visible ? text_pixel_clip_bb.Max.x : bb.Max.x - 1.0;
    if (close_button_visible || unsaved_marker_visible)
    {
        text_pixel_clip_bb.Max.x -= close_button_visible ? (button_sz) : (button_sz * 0.80);
        text_ellipsis_clip_bb.Max.x -= unsaved_marker_visible ? (button_sz * 0.80) : 0.0;
        ellipsis_max_x = text_pixel_clip_bb.Max.x;
    }
    LogSetNextTextDecoration("/", "\\");
    RenderTextEllipsis(draw_list, text_ellipsis_clip_bb.Min, text_ellipsis_clip_bb.Max, text_pixel_clip_bb.Max.x, ellipsis_max_x, label, nil, &label_size);

when false {
    if (!is_contents_visible) {
        g.Style.Alpha = backup_alpha;
    }
}

    if (out_just_closed) {
        out_just_closed^ = close_button_pressed;
    }
}

