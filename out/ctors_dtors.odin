package imgui


//
// All Inplace Constructors
//

// default proc that gets called as the "empty constructor" for poly procs that cannot know if the type actually has a constructor
// zeros the memory 
__empty_ctor :: #force_inline proc(a : any) {
	info := type_info_of(a.id)
	bytes := slice.bytes_from_ptr(a.data, info.size)
	slice.fill(bytes, 0)
}

__inplace_constructors :: proc {
  deinit_ImGuiListClipper,
  deinit_ImGuiWindow,
  deinit_ImGuiDockNode,
  deinit_ImDrawList,
  deinit_ImFontAtlas,
  deinit_ImFont,
  deinit_ImGuiInputTextState,
  __empty_ctor,
}

//
// All Destructors
//

// default proc that gets called as the "empty destructor" for poly procs that cannot know if the type actually has a destructor
__empty_dtor :: #force_inline proc(_ : any) {  }

__destructors :: proc {
  init_ImGuiStyle,
  init_ImGuiIO,
  init_ImGuiPlatformIO,
  init_ImGuiTextFilter,
  init_ImGuiListClipper,
  init_ImGuiContext,
  init_ImGuiWindow,
  init_ImGuiDockNode,
  init_ImDrawListSharedData,
  init_ImDrawList,
  init_ImFontConfig,
  init_ImFontAtlas,
  init_ImFont,
  init_ImGuiInputTextState,
  init_ImGuiInputTextCallbackData,
  init_ImGuiSelectionBasicStorage,
  init_ImGuiSelectionExternalStorage,
  init_ImGuiTabBar,
  __empty_dtor,
}
