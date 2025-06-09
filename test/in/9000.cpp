typedef int ImGuiDockNodeFlags;

// Flags for ImGui::DockSpace(), shared/inherited by child nodes.
// (Some flags can be applied to individual nodes directly)
// FIXME-DOCK: Also see ImGuiDockNodeFlagsPrivate_ which may involve using the WIP and internal DockBuilder api.
enum ImGuiDockNodeFlags_
{
    ImGuiDockNodeFlags_None                         = 0,
    ImGuiDockNodeFlags_KeepAliveOnly                = 1 << 0,   //       // Don't display the dockspace node but keep it alive. Windows docked into this dockspace node won't be undocked.
    //ImGuiDockNodeFlags_NoCentralNode              = 1 << 1,   //       // Disable Central Node (the node which can stay empty)
    ImGuiDockNodeFlags_NoDockingOverCentralNode     = 1 << 2,   //       // Disable docking over the Central Node, which will be always kept empty.
    ImGuiDockNodeFlags_PassthruCentralNode          = 1 << 3,   //       // Enable passthru dockspace: 1) DockSpace() will render a ImGuiCol_WindowBg background covering everything excepted the Central Node when empty. Meaning the host window should probably use SetNextWindowBgAlpha(0.0f) prior to Begin() when using this. 2) When Central Node is empty: let inputs pass-through + won't display a DockingEmptyBg background. See demo for details.
    ImGuiDockNodeFlags_NoDockingSplit               = 1 << 4,   //       // Disable other windows/nodes from splitting this node.
    ImGuiDockNodeFlags_NoResize                     = 1 << 5,   // Saved // Disable resizing node using the splitter/separators. Useful with programmatically setup dockspaces.
    ImGuiDockNodeFlags_AutoHideTabBar               = 1 << 6,   //       // Tab bar will automatically hide when there is a single window in the dock node.
    ImGuiDockNodeFlags_NoUndocking                  = 1 << 7,   //       // Disable undocking this node.

#ifndef IMGUI_DISABLE_OBSOLETE_FUNCTIONS
    ImGuiDockNodeFlags_NoSplit                      = ImGuiDockNodeFlags_NoDockingSplit, // Renamed in 1.90
    ImGuiDockNodeFlags_NoDockingInCentralNode       = ImGuiDockNodeFlags_NoDockingOverCentralNode, // Renamed in 1.90
#endif
};

// Extend ImGuiDockNodeFlags_
enum ImGuiDockNodeFlagsPrivate_
{
    // [Internal]
    ImGuiDockNodeFlags_DockSpace                = 1 << 10,  // Saved // A dockspace is a node that occupy space within an existing user window. Otherwise the node is floating and create its own window.
    ImGuiDockNodeFlags_CentralNode              = 1 << 11,  // Saved // The central node has 2 main properties: stay visible when empty, only use "remaining" spaces from its neighbor.
    ImGuiDockNodeFlags_NoTabBar                 = 1 << 12,  // Saved // Tab bar is completely unavailable. No triangle in the corner to enable it back.
    ImGuiDockNodeFlags_HiddenTabBar             = 1 << 13,  // Saved // Tab bar is hidden, with a triangle in the corner to show it again (NB: actual tab-bar instance may be destroyed as this is only used for single-window tab bar)
    ImGuiDockNodeFlags_NoWindowMenuButton       = 1 << 14,  // Saved // Disable window/docking menu (that one that appears instead of the collapse button)
    ImGuiDockNodeFlags_NoCloseButton            = 1 << 15,  // Saved // Disable close button
    ImGuiDockNodeFlags_NoResizeX                = 1 << 16,  //       //
    ImGuiDockNodeFlags_NoResizeY                = 1 << 17,  //       //
    ImGuiDockNodeFlags_DockedWindowsInFocusRoute= 1 << 18,  //       // Any docked window will be automatically be focus-route chained (window->ParentWindowForFocusRoute set to this) so Shortcut() in this window can run when any docked window is focused.

    // Disable docking/undocking actions in this dockspace or individual node (existing docked nodes will be preserved)
    // Those are not exposed in public because the desirable sharing/inheriting/copy-flag-on-split behaviors are quite difficult to design and understand.
    // The two public flags ImGuiDockNodeFlags_NoDockingOverCentralNode/ImGuiDockNodeFlags_NoDockingSplit don't have those issues.
    ImGuiDockNodeFlags_NoDockingSplitOther      = 1 << 19,  //       // Disable this node from splitting other windows/nodes.
    ImGuiDockNodeFlags_NoDockingOverMe          = 1 << 20,  //       // Disable other windows/nodes from being docked over this node.
    ImGuiDockNodeFlags_NoDockingOverOther       = 1 << 21,  //       // Disable this node from being docked over another window or non-empty node.
    ImGuiDockNodeFlags_NoDockingOverEmpty       = 1 << 22,  //       // Disable this node from being docked over an empty node (e.g. DockSpace with no other windows)
    ImGuiDockNodeFlags_NoDocking                = ImGuiDockNodeFlags_NoDockingOverMe | ImGuiDockNodeFlags_NoDockingOverOther | ImGuiDockNodeFlags_NoDockingOverEmpty | ImGuiDockNodeFlags_NoDockingSplit | ImGuiDockNodeFlags_NoDockingSplitOther,

    // Masks
    ImGuiDockNodeFlags_SharedFlagsInheritMask_  = ~0,
    ImGuiDockNodeFlags_NoResizeFlagsMask_       = (int)ImGuiDockNodeFlags_NoResize | ImGuiDockNodeFlags_NoResizeX | ImGuiDockNodeFlags_NoResizeY,

    // When splitting, those local flags are moved to the inheriting child, never duplicated
    ImGuiDockNodeFlags_LocalFlagsTransferMask_  = (int)ImGuiDockNodeFlags_NoDockingSplit | ImGuiDockNodeFlags_NoResizeFlagsMask_ | (int)ImGuiDockNodeFlags_AutoHideTabBar | ImGuiDockNodeFlags_CentralNode | ImGuiDockNodeFlags_NoTabBar | ImGuiDockNodeFlags_HiddenTabBar | ImGuiDockNodeFlags_NoWindowMenuButton | ImGuiDockNodeFlags_NoCloseButton,
    ImGuiDockNodeFlags_SavedFlagsMask_          = ImGuiDockNodeFlags_NoResizeFlagsMask_ | ImGuiDockNodeFlags_DockSpace | ImGuiDockNodeFlags_CentralNode | ImGuiDockNodeFlags_NoTabBar | ImGuiDockNodeFlags_HiddenTabBar | ImGuiDockNodeFlags_NoWindowMenuButton | ImGuiDockNodeFlags_NoCloseButton,
};

template<typename T>
struct ImVector {
    T* Data;
    int Size;
};

struct ImVec2 { float x, y; };

// sizeof() 156~192
struct ImGuiDockNode
{
    ImGuiID                 ID;
    ImGuiDockNodeFlags      SharedFlags;                // (Write) Flags shared by all nodes of a same dockspace hierarchy (inherited from the root node)
    ImGuiDockNodeFlags      LocalFlags;                 // (Write) Flags specific to this node
    ImGuiDockNodeFlags      LocalFlagsInWindows;        // (Write) Flags specific to this node, applied from windows
    ImGuiDockNodeFlags      MergedFlags;                // (Read)  Effective flags (== SharedFlags | LocalFlagsInNode | LocalFlagsInWindows)
    ImGuiDockNodeState      State;
    ImGuiDockNode*          ParentNode;
    ImGuiDockNode*          ChildNodes[2];              // [Split node only] Child nodes (left/right or top/bottom). Consider switching to an array.
    ImVector<ImGuiWindow*>  Windows;                    // Note: unordered list! Iterate TabBar->Tabs for user-order.
    ImGuiTabBar*            TabBar;
    ImVec2                  Pos;                        // Current position
    ImVec2                  Size;                       // Current size
    ImVec2                  SizeRef;                    // [Split node only] Last explicitly written-to size (overridden when using a splitter affecting the node), used to calculate Size.
    ImGuiAxis               SplitAxis;                  // [Split node only] Split axis (X or Y)
    ImGuiWindowClass        WindowClass;                // [Root node only]
    ImU32                   LastBgColor;

    ImGuiWindow*            HostWindow;
    ImGuiWindow*            VisibleWindow;              // Generally point to window which is ID is == SelectedTabID, but when CTRL+Tabbing this can be a different window.
    ImGuiDockNode*          CentralNode;                // [Root node only] Pointer to central node.
    ImGuiDockNode*          OnlyNodeWithWindows;        // [Root node only] Set when there is a single visible node within the hierarchy.
    int                     CountNodeWithWindows;       // [Root node only]
    int                     LastFrameAlive;             // Last frame number the node was updated or kept alive explicitly with DockSpace() + ImGuiDockNodeFlags_KeepAliveOnly
    int                     LastFrameActive;            // Last frame number the node was updated.
    int                     LastFrameFocused;           // Last frame number the node was focused.
    ImGuiID                 LastFocusedNodeId;          // [Root node only] Which of our child docking node (any ancestor in the hierarchy) was last focused.
    ImGuiID                 SelectedTabId;              // [Leaf node only] Which of our tab/window is selected.
    ImGuiID                 WantCloseTabId;             // [Leaf node only] Set when closing a specific tab/window.
    ImGuiID                 RefViewportId;              // Reference viewport ID from visible window when HostWindow == NULL.
    ImGuiDataAuthority      AuthorityForPos         :3;
    ImGuiDataAuthority      AuthorityForSize        :3;
    ImGuiDataAuthority      AuthorityForViewport    :3;
    bool                    IsVisible               :1; // Set to false when the node is hidden (usually disabled as it has no active window)
    bool                    IsFocused               :1;
    bool                    IsBgDrawnThisFrame      :1;
    bool                    HasCloseButton          :1; // Provide space for a close button (if any of the docked window has one). Note that button may be hidden on window without one.
    bool                    HasWindowMenuButton     :1;
    bool                    HasCentralNodeChild     :1;
    bool                    WantCloseAll            :1; // Set when closing all tabs at once.
    bool                    WantLockSizeOnce        :1;
    bool                    WantMouseMove           :1; // After a node extraction we need to transition toward moving the newly created host window
    bool                    WantHiddenTabBarUpdate  :1;
    bool                    WantHiddenTabBarToggle  :1;

    ImGuiDockNode(ImGuiID id);
    ~ImGuiDockNode();
    bool                    IsRootNode() const      { return ParentNode == NULL; }
    bool                    IsDockSpace() const     { return (MergedFlags & ImGuiDockNodeFlags_DockSpace) != 0; }
    bool                    IsFloatingNode() const  { return ParentNode == NULL && (MergedFlags & ImGuiDockNodeFlags_DockSpace) == 0; }
    bool                    IsCentralNode() const   { return (MergedFlags & ImGuiDockNodeFlags_CentralNode) != 0; }
    bool                    IsHiddenTabBar() const  { return (MergedFlags & ImGuiDockNodeFlags_HiddenTabBar) != 0; } // Hidden tab bar can be shown back by clicking the small triangle
    bool                    IsNoTabBar() const      { return (MergedFlags & ImGuiDockNodeFlags_NoTabBar) != 0; }     // Never show a tab bar
    bool                    IsSplitNode() const     { return ChildNodes[0] != NULL; }
    bool                    IsLeafNode() const      { return ChildNodes[0] == NULL; }
    bool                    IsEmpty() const         { return ChildNodes[0] == NULL && Windows.Size == 0; }
    ImRect                  Rect() const            { return ImRect(Pos.x, Pos.y, Pos.x + Size.x, Pos.y + Size.y); }

    void                    SetLocalFlags(ImGuiDockNodeFlags flags) { LocalFlags = flags; UpdateMergedFlags(); }
    void                    UpdateMergedFlags()     { MergedFlags = SharedFlags | LocalFlags | LocalFlagsInWindows; }
};
