package test

// Flags for ImGui::DockSpace(), shared/inherited by child nodes.
// (Some flags can be applied to individual nodes directly)
// FIXME-DOCK: Also see ImGuiDockNodeFlagsPrivate_ which may involve using the WIP and internal DockBuilder api.
ImGuiDockNodeFlags_ :: enum i32 {
	ImGuiDockNodeFlags_None = 0,
	ImGuiDockNodeFlags_KeepAliveOnly = 1 << 0, //       // Don't display the dockspace node but keep it alive. Windows docked into this dockspace node won't be undocked.
	//ImGuiDockNodeFlags_NoCentralNode              = 1 << 1,   //       // Disable Central Node (the node which can stay empty)
	ImGuiDockNodeFlags_NoDockingOverCentralNode = 1 << 2, //       // Disable docking over the Central Node, which will be always kept empty.
	ImGuiDockNodeFlags_PassthruCentralNode = 1 << 3, //       // Enable passthru dockspace: 1) DockSpace() will render a ImGuiCol_WindowBg background covering everything excepted the Central Node when empty. Meaning the host window should probably use SetNextWindowBgAlpha(0.0f) prior to Begin() when using this. 2) When Central Node is empty: let inputs pass-through + won't display a DockingEmptyBg background. See demo for details.
	ImGuiDockNodeFlags_NoDockingSplit = 1 << 4, //       // Disable other windows/nodes from splitting this node.
	ImGuiDockNodeFlags_NoResize = 1 << 5, // Saved // Disable resizing node using the splitter/separators. Useful with programmatically setup dockspaces.
	ImGuiDockNodeFlags_AutoHideTabBar = 1 << 6, //       // Tab bar will automatically hide when there is a single window in the dock node.
	ImGuiDockNodeFlags_NoUndocking = 1 << 7, //       // Disable undocking this node.

when ! defined ( IMGUI_DISABLE_OBSOLETE_FUNCTIONS ) {
	ImGuiDockNodeFlags_NoSplit = ImGuiDockNodeFlags_NoDockingSplit, // Renamed in 1.90
	ImGuiDockNodeFlags_NoDockingInCentralNode = ImGuiDockNodeFlags_NoDockingOverCentralNode, // Renamed in 1.90
} // preproc endif
}

// Extend ImGuiDockNodeFlags_
ImGuiDockNodeFlagsPrivate_ :: enum i32 {
	// [Internal]
	ImGuiDockNodeFlags_DockSpace = 1 << 10, // Saved // A dockspace is a node that occupy space within an existing user window. Otherwise the node is floating and create its own window.
	ImGuiDockNodeFlags_CentralNode = 1 << 11, // Saved // The central node has 2 main properties: stay visible when empty, only use "remaining" spaces from its neighbor.
	ImGuiDockNodeFlags_NoTabBar = 1 << 12, // Saved // Tab bar is completely unavailable. No triangle in the corner to enable it back.
	ImGuiDockNodeFlags_HiddenTabBar = 1 << 13, // Saved // Tab bar is hidden, with a triangle in the corner to show it again (NB: actual tab-bar instance may be destroyed as this is only used for single-window tab bar)
	ImGuiDockNodeFlags_NoWindowMenuButton = 1 << 14, // Saved // Disable window/docking menu (that one that appears instead of the collapse button)
	ImGuiDockNodeFlags_NoCloseButton = 1 << 15, // Saved // Disable close button
	ImGuiDockNodeFlags_NoResizeX = 1 << 16, //       //
	ImGuiDockNodeFlags_NoResizeY = 1 << 17, //       //
	ImGuiDockNodeFlags_DockedWindowsInFocusRoute = 1 << 18, //       // Any docked window will be automatically be focus-route chained (window->ParentWindowForFocusRoute set to this) so Shortcut() in this window can run when any docked window is focused.

	// Disable docking/undocking actions in this dockspace or individual node (existing docked nodes will be preserved)
	// Those are not exposed in public because the desirable sharing/inheriting/copy-flag-on-split behaviors are quite difficult to design and understand.
	// The two public flags ImGuiDockNodeFlags_NoDockingOverCentralNode/ImGuiDockNodeFlags_NoDockingSplit don't have those issues.
	ImGuiDockNodeFlags_NoDockingSplitOther = 1 << 19, //       // Disable this node from splitting other windows/nodes.
	ImGuiDockNodeFlags_NoDockingOverMe = 1 << 20, //       // Disable other windows/nodes from being docked over this node.
	ImGuiDockNodeFlags_NoDockingOverOther = 1 << 21, //       // Disable this node from being docked over another window or non-empty node.
	ImGuiDockNodeFlags_NoDockingOverEmpty = 1 << 22, //       // Disable this node from being docked over an empty node (e.g. DockSpace with no other windows)
	ImGuiDockNodeFlags_NoDocking = ImGuiDockNodeFlags_NoDockingOverMe | ImGuiDockNodeFlags_NoDockingOverOther | ImGuiDockNodeFlags_NoDockingOverEmpty | ImGuiDockNodeFlags_NoDockingSplit | ImGuiDockNodeFlags_NoDockingSplitOther,

	// Masks
	ImGuiDockNodeFlags_SharedFlagsInheritMask_ = !0,
	ImGuiDockNodeFlags_NoResizeFlagsMask_ = cast(i32) ImGuiDockNodeFlags_NoResize | ImGuiDockNodeFlags_NoResizeX | ImGuiDockNodeFlags_NoResizeY,

	// When splitting, those local flags are moved to the inheriting child, never duplicated
	ImGuiDockNodeFlags_LocalFlagsTransferMask_ = cast(i32) ImGuiDockNodeFlags_NoDockingSplit | ImGuiDockNodeFlags_NoResizeFlagsMask_ | cast(i32) ImGuiDockNodeFlags_AutoHideTabBar | ImGuiDockNodeFlags_CentralNode | ImGuiDockNodeFlags_NoTabBar | ImGuiDockNodeFlags_HiddenTabBar | ImGuiDockNodeFlags_NoWindowMenuButton | ImGuiDockNodeFlags_NoCloseButton,
	ImGuiDockNodeFlags_SavedFlagsMask_ = ImGuiDockNodeFlags_NoResizeFlagsMask_ | ImGuiDockNodeFlags_DockSpace | ImGuiDockNodeFlags_CentralNode | ImGuiDockNodeFlags_NoTabBar | ImGuiDockNodeFlags_HiddenTabBar | ImGuiDockNodeFlags_NoWindowMenuButton | ImGuiDockNodeFlags_NoCloseButton,
}

ImVector :: struct(T : typeid) {
	Data : ^T,
	Size : i32,
}

ImVec2 :: struct { x : f32, y : f32,}

// sizeof() 156~192
ImGuiDockNode :: struct {
	ID : ImGuiID,
	SharedFlags : ImGuiDockNodeFlags, // (Write) Flags shared by all nodes of a same dockspace hierarchy (inherited from the root node)
	LocalFlags : ImGuiDockNodeFlags, // (Write) Flags specific to this node
	LocalFlagsInWindows : ImGuiDockNodeFlags, // (Write) Flags specific to this node, applied from windows
	MergedFlags : ImGuiDockNodeFlags, // (Read)  Effective flags (== SharedFlags | LocalFlagsInNode | LocalFlagsInWindows)
	State : ImGuiDockNodeState,
	ParentNode : ^ImGuiDockNode,
	ChildNodes : [2]^ImGuiDockNode, // [Split node only] Child nodes (left/right or top/bottom). Consider switching to an array.
	Windows : ^ImVector_ImGuiWindow, // Note: unordered list! Iterate TabBar->Tabs for user-order.
	TabBar : ^ImGuiTabBar,
	Pos : ImVec2, // Current position
	Size : ImVec2, // Current size
	SizeRef : ImVec2, // [Split node only] Last explicitly written-to size (overridden when using a splitter affecting the node), used to calculate Size.
	SplitAxis : ImGuiAxis, // [Split node only] Split axis (X or Y)
	WindowClass : ImGuiWindowClass, // [Root node only]
	LastBgColor : ImU32,

	HostWindow : ^ImGuiWindow,
	VisibleWindow : ^ImGuiWindow, // Generally point to window which is ID is == SelectedTabID, but when CTRL+Tabbing this can be a different window.
	CentralNode : ^ImGuiDockNode, // [Root node only] Pointer to central node.
	OnlyNodeWithWindows : ^ImGuiDockNode, // [Root node only] Set when there is a single visible node within the hierarchy.
	CountNodeWithWindows : i32, // [Root node only]
	LastFrameAlive : i32, // Last frame number the node was updated or kept alive explicitly with DockSpace() + ImGuiDockNodeFlags_KeepAliveOnly
	LastFrameActive : i32, // Last frame number the node was updated.
	LastFrameFocused : i32, // Last frame number the node was focused.
	LastFocusedNodeId : ImGuiID, // [Root node only] Which of our child docking node (any ancestor in the hierarchy) was last focused.
	SelectedTabId : ImGuiID, // [Leaf node only] Which of our tab/window is selected.
	WantCloseTabId : ImGuiID, // [Leaf node only] Set when closing a specific tab/window.
	RefViewportId : ImGuiID, // Reference viewport ID from visible window when HostWindow == NULL.
	using _0 : bit_field u8 {
		AuthorityForPos : ImGuiDataAuthority | 3,
		AuthorityForSize : ImGuiDataAuthority | 3,
		AuthorityForViewport : ImGuiDataAuthority | 3,
		IsVisible : bool | 1, // Set to false when the node is hidden (usually disabled as it has no active window)
		IsFocused : bool | 1,
		IsBgDrawnThisFrame : bool | 1,
		HasCloseButton : bool | 1, // Provide space for a close button (if any of the docked window has one). Note that button may be hidden on window without one.
		HasWindowMenuButton : bool | 1,
		HasCentralNodeChild : bool | 1,
		WantCloseAll : bool | 1, // Set when closing all tabs at once.
		WantLockSizeOnce : bool | 1,
		WantMouseMove : bool | 1, // After a node extraction we need to transition toward moving the newly created host window
		WantHiddenTabBarUpdate : bool | 1,
		WantHiddenTabBarToggle : bool | 1,
	},
}

ImGuiDockNode_IsRootNode :: proc(this : ^ImGuiDockNode) -> bool { return this.ParentNode == nil }

ImGuiDockNode_IsDockSpace :: proc(this : ^ImGuiDockNode) -> bool { return this.MergedFlags & ImGuiDockNodeFlags_DockSpace != 0 }

ImGuiDockNode_IsFloatingNode :: proc(this : ^ImGuiDockNode) -> bool { return this.ParentNode == nil && this.MergedFlags & ImGuiDockNodeFlags_DockSpace == 0 }

ImGuiDockNode_IsCentralNode :: proc(this : ^ImGuiDockNode) -> bool { return this.MergedFlags & ImGuiDockNodeFlags_CentralNode != 0 }

// Hidden tab bar can be shown back by clicking the small triangle
ImGuiDockNode_IsHiddenTabBar :: proc(this : ^ImGuiDockNode) -> bool { return this.MergedFlags & ImGuiDockNodeFlags_HiddenTabBar != 0 }

// Never show a tab bar
ImGuiDockNode_IsNoTabBar :: proc(this : ^ImGuiDockNode) -> bool { return this.MergedFlags & ImGuiDockNodeFlags_NoTabBar != 0 }

ImGuiDockNode_IsSplitNode :: proc(this : ^ImGuiDockNode) -> bool { return this.ChildNodes[0] != nil }

ImGuiDockNode_IsLeafNode :: proc(this : ^ImGuiDockNode) -> bool { return this.ChildNodes[0] == nil }

ImGuiDockNode_IsEmpty :: proc(this : ^ImGuiDockNode) -> bool { return this.ChildNodes[0] == nil && this.Windows.Size == 0 }

ImGuiDockNode_Rect :: proc(this : ^ImGuiDockNode) -> ImRect { return ImRect(this.Pos.x, this.Pos.y, this.Pos.x + this.Size.x, this.Pos.y + this.Size.y) }

ImGuiDockNode_SetLocalFlags :: proc(this : ^ImGuiDockNode, flags : ImGuiDockNodeFlags)
{this.LocalFlags = flags; UpdateMergedFlags()}

ImGuiDockNode_UpdateMergedFlags :: proc(this : ^ImGuiDockNode) { this.MergedFlags = this.SharedFlags | this.LocalFlags | this.LocalFlagsInWindows }
