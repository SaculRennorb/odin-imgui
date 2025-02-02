package imgui

// dear imgui: Renderer Backend for Vulkan
// This needs to be used along with a Platform Backend (e.g. GLFW, SDL, Win32, custom..)

// Implemented features:
//  [!] Renderer: User texture binding. Use 'VkDescriptorSet' as ImTextureID. Call ImGui_ImplVulkan_AddTexture() to register one. Read the FAQ about ImTextureID! See https://github.com/ocornut/imgui/pull/914 for discussions.
//  [X] Renderer: Large meshes support (64k+ vertices) even with 16-bit indices (ImGuiBackendFlags_RendererHasVtxOffset).
//  [X] Renderer: Expose selected render state for draw callbacks to use. Access in '(ImGui_ImplXXXX_RenderState*)GetPlatformIO().Renderer_RenderState'.
//  [x] Renderer: Multi-viewport / platform windows. With issues (flickering when creating a new viewport).

// The aim of imgui_impl_vulkan.h/.cpp is to be usable in your engine without any modification.
// IF YOU FEEL YOU NEED TO MAKE ANY CHANGE TO THIS CODE, please share them and your feedback at https://github.com/ocornut/imgui/

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// Learn about Dear ImGui:
// - FAQ                  https://dearimgui.com/faq
// - Getting Started      https://dearimgui.com/getting-started
// - Documentation        https://dearimgui.com/docs (same as your local docs/ folder).
// - Introduction, links and more at the top of imgui.cpp

// Important note to the reader who wish to integrate imgui_impl_vulkan.cpp/.h in their own engine/app.
// - Common ImGui_ImplVulkan_XXX functions and structures are used to interface with imgui_impl_vulkan.cpp/.h.
//   You will use those if you want to use this rendering backend in your engine/app.
// - Helper ImGui_ImplVulkanH_XXX functions and structures are only used by this example (main.cpp) and by
//   the backend itself (imgui_impl_vulkan.cpp), but should PROBABLY NOT be used by your own engine/app code.
// Read comments in imgui_impl_vulkan.h.

when !(IMGUI_DISABLE) {

// [Configuration] in order to use a custom Vulkan function loader:
// (1) You'll need to disable default Vulkan function prototypes.
//     We provide a '#define IMGUI_IMPL_VULKAN_NO_PROTOTYPES' convenience configuration flag.
//     In order to make sure this is visible from the imgui_impl_vulkan.cpp compilation unit:
//     - Add '#define IMGUI_IMPL_VULKAN_NO_PROTOTYPES' in your imconfig.h file
//     - Or as a compilation flag in your build system
//     - Or uncomment here (not recommended because you'd be modifying imgui sources!)
//     - Do not simply add it in a .cpp file!
// (2) Call ImGui_ImplVulkan_LoadFunctions() before ImGui_ImplVulkan_Init() with your custom function.
// If you have no idea what this is, leave it alone!
IMGUI_IMPL_VULKAN_NO_PROTOTYPES :: false

// Convenience support for Volk
// (you can also technically use IMGUI_IMPL_VULKAN_NO_PROTOTYPES + wrap Volk via ImGui_ImplVulkan_LoadFunctions().)
IMGUI_IMPL_VULKAN_USE_VOLK :: false

when defined(IMGUI_IMPL_VULKAN_NO_PROTOTYPES) && !defined(VK_NO_PROTOTYPES) {
VK_NO_PROTOTYPES :: true
}
when defined(VK_USE_PLATFORM_WIN32_KHR) && !defined(NOMINMAX) {
NOMINMAX :: true
}

// Vulkan includes
when IMGUI_IMPL_VULKAN_USE_VOLK {
} else {
}
when defined(VK_VERSION_1_3) || defined(VK_KHR_dynamic_rendering) {
IMGUI_IMPL_VULKAN_HAS_DYNAMIC_RENDERING :: true
}

// Initialization data, for ImGui_ImplVulkan_Init()
// [Please zero-clear before use!]
// - About descriptor pool:
//   - A VkDescriptorPool should be created with VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT,
//     and must contain a pool size large enough to hold a small number of VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER descriptors.
//   - As an convenience, by setting DescriptorPoolSize > 0 the backend will create one for you.
//   - Current version of the backend use 1 descriptor for the font atlas + as many as additional calls done to ImGui_ImplVulkan_AddTexture().
//   - It is expected that as early as Q1 2025 the backend will use a few more descriptors, so aim at 10 + number of desierd calls to ImGui_ImplVulkan_AddTexture().
// - About dynamic rendering:
//   - When using dynamic rendering, set UseDynamicRendering=true and fill PipelineRenderingCreateInfo structure.
ImGui_ImplVulkan_InitInfo :: struct
{
    Instance : VkInstance,
    PhysicalDevice : VkPhysicalDevice,
    Device : VkDevice,
    QueueFamily : u32,
    Queue : VkQueue,
    DescriptorPool : VkDescriptorPool,               // See requirements in note above; ignored if using DescriptorPoolSize > 0
    RenderPass : VkRenderPass,                   // Ignored if using dynamic rendering
    MinImageCount : u32,                // >= 2
    ImageCount : u32,                   // >= MinImageCount
    MSAASamples : VkSampleCountFlagBits,                  // 0 defaults to VK_SAMPLE_COUNT_1_BIT

    // (Optional)
    PipelineCache : VkPipelineCache,
    Subpass : u32,

    // (Optional) Set to create internal descriptor pool instead of using DescriptorPool
    DescriptorPoolSize : u32,

    // (Optional) Dynamic Rendering
    // Need to explicitly enable VK_KHR_dynamic_rendering extension to use this, even for Vulkan 1.3.
    UseDynamicRendering : bool,
when IMGUI_IMPL_VULKAN_HAS_DYNAMIC_RENDERING {
    PipelineRenderingCreateInfo : VkPipelineRenderingCreateInfoKHR,
}

    // (Optional) Allocation, Debugging
    Allocator : ^VkAllocationCallbacks,
    void                            (*CheckVkResultFn)(VkResult err);
    MinAllocationSize : VkDeviceSize,      // Minimum allocation size. Set to 1024*1024 to satisfy zealous best practices validation layer and waste a little memory.
};

// Follow "Getting Started" link and check examples/ folder to learn about using backends!
IMGUI_IMPL_API bool             ImGui_ImplVulkan_Init(ImGui_ImplVulkan_InitInfo* info);
IMGUI_IMPL_API void             ImGui_ImplVulkan_Shutdown();
IMGUI_IMPL_API void             ImGui_ImplVulkan_NewFrame();
IMGUI_IMPL_API void             ImGui_ImplVulkan_RenderDrawData(ImDrawData* draw_data, VkCommandBuffer command_buffer, VkPipeline pipeline = VK_NULL_HANDLE);
IMGUI_IMPL_API bool             ImGui_ImplVulkan_CreateFontsTexture();
IMGUI_IMPL_API void             ImGui_ImplVulkan_DestroyFontsTexture();
IMGUI_IMPL_API void             ImGui_ImplVulkan_SetMinImageCount(u32 min_image_count); // To override MinImageCount after initialization (e.g. if swap chain is recreated)

// Register a texture (VkDescriptorSet == ImTextureID)
// FIXME: This is experimental in the sense that we are unsure how to best design/tackle this problem
// Please post to https://github.com/ocornut/imgui/pull/914 if you have suggestions.
IMGUI_IMPL_API VkDescriptorSet  ImGui_ImplVulkan_AddTexture(VkSampler sampler, VkImageView image_view, VkImageLayout image_layout);
IMGUI_IMPL_API void             ImGui_ImplVulkan_RemoveTexture(VkDescriptorSet descriptor_set);

// Optional: load Vulkan functions with a custom function loader
// This is only useful with IMGUI_IMPL_VULKAN_NO_PROTOTYPES / VK_NO_PROTOTYPES
IMGUI_IMPL_API bool             ImGui_ImplVulkan_LoadFunctions(PFN_vkVoidFunction(*loader_func)(const u8* function_name, rawptr user_data), rawptr user_data = nullptr);

// [BETA] Selected render state data shared with callbacks.
// This is temporarily stored in GetPlatformIO().Renderer_RenderState during the ImGui_ImplVulkan_RenderDrawData() call.
// (Please open an issue if you feel you need access to more data)
ImGui_ImplVulkan_RenderState :: struct
{
    CommandBuffer : VkCommandBuffer,
    Pipeline : VkPipeline,
    PipelineLayout : VkPipelineLayout,
};

//-------------------------------------------------------------------------
// Internal / Miscellaneous Vulkan Helpers
//-------------------------------------------------------------------------
// Used by example's main.cpp. Used by multi-viewport features. PROBABLY NOT used by your own engine/app.
//
// You probably do NOT need to use or care about those functions.
// Those functions only exist because:
//   1) they facilitate the readability and maintenance of the multiple main.cpp examples files.
//   2) the multi-viewport / platform window implementation needs them internally.
// Generally we avoid exposing any kind of superfluous high-level helpers in the backends,
// but it is too much code to duplicate everywhere so we exceptionally expose them.
//
// Your engine/app will likely _already_ have code to setup all that stuff (swap chain,
// render pass, frame buffers, etc.). You may read this code if you are curious, but
// it is recommended you use you own custom tailored code to do equivalent work.
//
// We don't provide a strong guarantee that we won't change those functions API.
//
// The ImGui_ImplVulkanH_XXX functions should NOT interact with any of the state used
// by the regular ImGui_ImplVulkan_XXX functions).
//-------------------------------------------------------------------------


// Helpers
IMGUI_IMPL_API void                 ImGui_ImplVulkanH_CreateOrResizeWindow(VkInstance instance, VkPhysicalDevice physical_device, VkDevice device, ImGui_ImplVulkanH_Window* wd, u32 queue_family, const VkAllocationCallbacks* allocator, i32 w, i32 h, u32 min_image_count);
IMGUI_IMPL_API void                 ImGui_ImplVulkanH_DestroyWindow(VkInstance instance, VkDevice device, ImGui_ImplVulkanH_Window* wd, const VkAllocationCallbacks* allocator);
IMGUI_IMPL_API VkSurfaceFormatKHR   ImGui_ImplVulkanH_SelectSurfaceFormat(VkPhysicalDevice physical_device, VkSurfaceKHR surface, const VkFormat* request_formats, i32 request_formats_count, VkColorSpaceKHR request_color_space);
IMGUI_IMPL_API VkPresentModeKHR     ImGui_ImplVulkanH_SelectPresentMode(VkPhysicalDevice physical_device, VkSurfaceKHR surface, const VkPresentModeKHR* request_modes, i32 request_modes_count);
IMGUI_IMPL_API VkPhysicalDevice     ImGui_ImplVulkanH_SelectPhysicalDevice(VkInstance instance);
IMGUI_IMPL_API u32             ImGui_ImplVulkanH_SelectQueueFamilyIndex(VkPhysicalDevice physical_device);
IMGUI_IMPL_API i32                  ImGui_ImplVulkanH_GetMinImageCountFromPresentMode(VkPresentModeKHR present_mode);

// Helper structure to hold the data needed by one rendering frame
// (Used by example's main.cpp. Used by multi-viewport features. Probably NOT used by your own engine/app.)
// [Please zero-clear before use!]
ImGui_ImplVulkanH_Frame :: struct
{
    CommandPool : VkCommandPool,
    CommandBuffer : VkCommandBuffer,
    Fence : VkFence,
    Backbuffer : VkImage,
    BackbufferView : VkImageView,
    Framebuffer : VkFramebuffer,
};

ImGui_ImplVulkanH_FrameSemaphores :: struct
{
    ImageAcquiredSemaphore : VkSemaphore,
    RenderCompleteSemaphore : VkSemaphore,
};

// Helper structure to hold the data needed by one rendering context into one OS window
// (Used by example's main.cpp. Used by multi-viewport features. Probably NOT used by your own engine/app.)
ImGui_ImplVulkanH_Window :: struct
{
    Width : i32,
    Height : i32,
    Swapchain : VkSwapchainKHR,
    Surface : VkSurfaceKHR,
    SurfaceFormat : VkSurfaceFormatKHR,
    PresentMode : VkPresentModeKHR,
    RenderPass : VkRenderPass,
    UseDynamicRendering : bool,
    ClearEnable : bool,
    ClearValue : VkClearValue,
    FrameIndex : u32,             // Current frame being rendered to (0 <= FrameIndex < FrameInFlightCount)
    ImageCount : u32,             // Number of simultaneous in-flight frames (returned by vkGetSwapchainImagesKHR, usually derived from min_image_count)
    SemaphoreCount : u32,         // Number of simultaneous in-flight frames + 1, to be able to use it in vkAcquireNextImageKHR
    SemaphoreIndex : u32,         // Current set of swapchain wait semaphores we're using (needs to be distinct from per frame data)
    Frames : ^ImGui_ImplVulkanH_Frame,
    FrameSemaphores : ^ImGui_ImplVulkanH_FrameSemaphores,

    ImGui_ImplVulkanH_Window()
    {
        memset((rawptr)this, 0, size_of(*this));
        PresentMode = (VkPresentModeKHR)~0;     // Ensure we get an error if user doesn't set this.
        ClearEnable = true;
    }
};

} // #ifndef IMGUI_DISABLE
