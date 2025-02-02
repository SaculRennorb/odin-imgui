package imgui

// dear imgui: Renderer for WebGPU
// This needs to be used along with a Platform Binding (e.g. GLFW)
// (Please note that WebGPU is currently experimental, will not run on non-beta browsers, and may break.)

// Important note to dawn and/or wgpu users: when targeting native platforms (i.e. NOT emscripten),
// one of IMGUI_IMPL_WEBGPU_BACKEND_DAWN or IMGUI_IMPL_WEBGPU_BACKEND_WGPU must be provided.
// Add #define to your imconfig.h file, or as a compilation flag in your build system.
// This requirement will be removed once WebGPU stabilizes and backends converge on a unified interface.
IMGUI_IMPL_WEBGPU_BACKEND_DAWN :: false
IMGUI_IMPL_WEBGPU_BACKEND_WGPU :: false

// Implemented features:
//  [X] Renderer: User texture binding. Use 'WGPUTextureView' as ImTextureID. Read the FAQ about ImTextureID!
//  [X] Renderer: Large meshes support (64k+ vertices) even with 16-bit indices (ImGuiBackendFlags_RendererHasVtxOffset).
//  [X] Renderer: Expose selected render state for draw callbacks to use. Access in '(ImGui_ImplXXXX_RenderState*)GetPlatformIO().Renderer_RenderState'.
// Missing features:
//  [ ] Renderer: Multi-viewport support (multiple windows). Not meaningful on the web.

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// Learn about Dear ImGui:
// - FAQ                  https://dearimgui.com/faq
// - Getting Started      https://dearimgui.com/getting-started
// - Documentation        https://dearimgui.com/docs (same as your local docs/ folder).
// - Introduction, links and more at the top of imgui.cpp

when !(IMGUI_DISABLE) {


// Initialization data, for ImGui_ImplWGPU_Init()
ImGui_ImplWGPU_InitInfo :: struct
{
    Device : WGPUDevice,
    NumFramesInFlight := 3;
    RenderTargetFormat := WGPUTextureFormat_Undefined;
    DepthStencilFormat := WGPUTextureFormat_Undefined;
    PipelineMultisampleState := {};

    ImGui_ImplWGPU_InitInfo()
    {
        PipelineMultisampleState.count = 1;
        PipelineMultisampleState.mask = UINT32_MAX;
        PipelineMultisampleState.alphaToCoverageEnabled = false;
    }
};

// Follow "Getting Started" link and check examples/ folder to learn about using backends!
IMGUI_IMPL_API bool ImGui_ImplWGPU_Init(ImGui_ImplWGPU_InitInfo* init_info);
IMGUI_IMPL_API void ImGui_ImplWGPU_Shutdown();
IMGUI_IMPL_API void ImGui_ImplWGPU_NewFrame();
IMGUI_IMPL_API void ImGui_ImplWGPU_RenderDrawData(ImDrawData* draw_data, WGPURenderPassEncoder pass_encoder);

// Use if you want to reset your rendering device without losing Dear ImGui state.
IMGUI_IMPL_API bool ImGui_ImplWGPU_CreateDeviceObjects();
IMGUI_IMPL_API void ImGui_ImplWGPU_InvalidateDeviceObjects();

// [BETA] Selected render state data shared with callbacks.
// This is temporarily stored in GetPlatformIO().Renderer_RenderState during the ImGui_ImplWGPU_RenderDrawData() call.
// (Please open an issue if you feel you need access to more data)
ImGui_ImplWGPU_RenderState :: struct
{
    Device : WGPUDevice,
    RenderPassEncoder : WGPURenderPassEncoder,
};

} // #ifndef IMGUI_DISABLE
