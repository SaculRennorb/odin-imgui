package imgui

// dear imgui: Renderer for WebGPU
// This needs to be used along with a Platform Binding (e.g. GLFW)
// (Please note that WebGPU is currently experimental, will not run on non-beta browsers, and may break.)

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

// CHANGELOG
// (minor and older changes stripped away, please see git history for details)
//  2024-10-14: Update Dawn support for change of string usages. (#8082, #8083)
//  2024-10-07: Expose selected render state in ImGui_ImplWGPU_RenderState, which you can access in 'void* platform_io.Renderer_RenderState' during draw callbacks.
//  2024-10-07: Changed default texture sampler to Clamp instead of Repeat/Wrap.
//  2024-09-16: Added support for optional IMGUI_IMPL_WEBGPU_BACKEND_DAWN / IMGUI_IMPL_WEBGPU_BACKEND_WGPU define to handle ever-changing native implementations. (#7977)
//  2024-01-22: Added configurable PipelineMultisampleState struct. (#7240)
//  2024-01-22: (Breaking) ImGui_ImplWGPU_Init() now takes a ImGui_ImplWGPU_InitInfo structure instead of variety of parameters, allowing for easier further changes.
//  2024-01-22: Fixed pipeline layout leak. (#7245)
//  2024-01-17: Explicitly fill all of WGPUDepthStencilState since standard removed defaults.
//  2023-07-13: Use WGPUShaderModuleWGSLDescriptor's code instead of source. use WGPUMipmapFilterMode_Linear instead of WGPUFilterMode_Linear. (#6602)
//  2023-04-11: Align buffer sizes. Use WGSL shaders instead of precompiled SPIR-V.
//  2023-04-11: Reorganized backend to pull data from a single structure to facilitate usage with multiple-contexts (all g_XXXX access changed to bd->XXXX).
//  2023-01-25: Revert automatic pipeline layout generation (see https://github.com/gpuweb/gpuweb/issues/2470)
//  2022-11-24: Fixed validation error with default depth buffer settings.
//  2022-11-10: Fixed rendering when a depth buffer is enabled. Added 'WGPUTextureFormat depth_format' parameter to ImGui_ImplWGPU_Init().
//  2022-10-11: Using 'nullptr' instead of 'NULL' as per our switch to C++11.
//  2021-11-29: Passing explicit buffer sizes to wgpuRenderPassEncoderSetVertexBuffer()/wgpuRenderPassEncoderSetIndexBuffer().
//  2021-08-24: Fixed for latest specs.
//  2021-05-24: Add support for draw_data->FramebufferScale.
//  2021-05-19: Replaced direct access to ImDrawCmd::TextureId with a call to ImDrawCmd::GetTexID(). (will become a requirement)
//  2021-05-16: Update to latest WebGPU specs (compatible with Emscripten 2.0.20 and Chrome Canary 92).
//  2021-02-18: Change blending equation to preserve alpha in output buffer.
//  2021-01-28: Initial version.

// When targeting native platforms (i.e. NOT emscripten), one of IMGUI_IMPL_WEBGPU_BACKEND_DAWN
// or IMGUI_IMPL_WEBGPU_BACKEND_WGPU must be provided. See imgui_impl_wgpu.h for more details.
when !(__EMSCRIPTEN__) {
when defined(IMGUI_IMPL_WEBGPU_BACKEND_DAWN) == defined(IMGUI_IMPL_WEBGPU_BACKEND_WGPU) {
    #error exactly one of IMGUI_IMPL_WEBGPU_BACKEND_DAWN or IMGUI_IMPL_WEBGPU_BACKEND_WGPU must be defined!
}
} else {
when defined(IMGUI_IMPL_WEBGPU_BACKEND_DAWN) || defined(IMGUI_IMPL_WEBGPU_BACKEND_WGPU) {
    #error neither IMGUI_IMPL_WEBGPU_BACKEND_DAWN nor IMGUI_IMPL_WEBGPU_BACKEND_WGPU may be defined if targeting emscripten!
}
}

when !(IMGUI_DISABLE) {

// Dear ImGui prototypes from imgui_internal.h
extern ImGuiID ImHashData(const rawptr data_p, int data_size, u32 seed = 0);
#define MEMALIGN(_SIZE,_ALIGN)        (((_SIZE) + ((_ALIGN) - 1)) & ~((_ALIGN) - 1))    // Memory align (copied from IM_ALIGN() macro).

// WebGPU data
RenderResources :: struct
{
    FontTexture := nullptr;          // Font texture
    FontTextureView := nullptr;      // Texture view for font texture
    Sampler := nullptr;              // Sampler for the font texture
    Uniforms := nullptr;             // Shader uniforms
    CommonBindGroup := nullptr;      // Resources bind-group to bind the common resources to pipeline
    ImageBindGroups : ImGuiStorage,                // Resources bind-group to bind the font/image resources to pipeline (this is a key->value map)
    ImageBindGroup := nullptr;       // Default font-resource of Dear ImGui
    ImageBindGroupLayout := nullptr; // Cache layout used for the image bind group. Avoids allocating unnecessary JS objects when working with WebASM
};

FrameResources :: struct
{
    IndexBuffer : WGPUBuffer,
    VertexBuffer : WGPUBuffer,
    IndexBufferHost : ^ImDrawIdx,
    VertexBufferHost : ^ImDrawVert,
    IndexBufferSize : i32,
    VertexBufferSize : i32,
};

Uniforms :: struct
{
    MVP : [4][4]f32,
    Gamma : f32,
};

ImGui_ImplWGPU_Data :: struct
{
    initInfo : ImGui_ImplWGPU_InitInfo,
    wgpuDevice := nullptr;
    defaultQueue := nullptr;
    renderTargetFormat := WGPUTextureFormat_Undefined;
    depthStencilFormat := WGPUTextureFormat_Undefined;
    pipelineState := nullptr;

    renderResources : RenderResources,
    pFrameResources := nullptr;
    numFramesInFlight := 0;
    frameIndex := UINT_MAX;
};

// Backend data stored in io.BackendRendererUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
ImGui_ImplWGPU_GetBackendData :: proc() -> ^ImGui_ImplWGPU_Data
{
    return GetCurrentContext() ? (ImGui_ImplWGPU_Data*)GetIO().BackendRendererUserData : nullptr;
}

//-----------------------------------------------------------------------------
// SHADERS
//-----------------------------------------------------------------------------

const u8 __shader_vert_wgsl[] = R"(
struct VertexInput {
    @location(0) position: vec2<f32>,
    @location(1) uv: vec2<f32>,
    @location(2) color: vec4<f32>,
};

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec4<f32>,
    @location(1) uv: vec2<f32>,
};

struct Uniforms {
    mvp: mat4x4<f32>,
    gamma: f32,
};

@group(0) @binding(0) var<uniform> uniforms: Uniforms;

@vertex
fn main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    out.position = uniforms.mvp * vec4<f32>(in.position, 0.0, 1.0);
    out.color = in.color;
    out.uv = in.uv;
    return out;
}
)";

const u8 __shader_frag_wgsl[] = R"(
struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec4<f32>,
    @location(1) uv: vec2<f32>,
};

struct Uniforms {
    mvp: mat4x4<f32>,
    gamma: f32,
};

@group(0) @binding(0) var<uniform> uniforms: Uniforms;
@group(0) @binding(1) var s: sampler;
@group(1) @binding(0) var t: texture_2d<f32>;

@fragment
fn main(in: VertexOutput) -> @location(0) vec4<f32> {
    color := in.color * textureSample(t, s, in.uv);
    corrected_color := pow(color.rgb, vec3<f32>(uniforms.gamma));
    return vec4<f32>(corrected_color, color.a);
}
)";

SafeRelease :: proc(res : ^^ImDrawIdx)
{
    if (res)
        delete[] res;
    res = nullptr;
}
SafeRelease :: proc(res : ^^ImDrawVert)
{
    if (res)
        delete[] res;
    res = nullptr;
}
SafeRelease :: proc(res : ^WGPUBindGroupLayout)
{
    if (res)
        wgpuBindGroupLayoutRelease(res);
    res = nullptr;
}
SafeRelease :: proc(res : ^WGPUBindGroup)
{
    if (res)
        wgpuBindGroupRelease(res);
    res = nullptr;
}
SafeRelease :: proc(res : ^WGPUBuffer)
{
    if (res)
        wgpuBufferRelease(res);
    res = nullptr;
}
SafeRelease :: proc(res : ^WGPUPipelineLayout)
{
    if (res)
        wgpuPipelineLayoutRelease(res);
    res = nullptr;
}
SafeRelease :: proc(res : ^WGPURenderPipeline)
{
    if (res)
        wgpuRenderPipelineRelease(res);
    res = nullptr;
}
SafeRelease :: proc(res : ^WGPUSampler)
{
    if (res)
        wgpuSamplerRelease(res);
    res = nullptr;
}
SafeRelease :: proc(res : ^WGPUShaderModule)
{
    if (res)
        wgpuShaderModuleRelease(res);
    res = nullptr;
}
SafeRelease :: proc(res : ^WGPUTextureView)
{
    if (res)
        wgpuTextureViewRelease(res);
    res = nullptr;
}
SafeRelease :: proc(res : ^WGPUTexture)
{
    if (res)
        wgpuTextureRelease(res);
    res = nullptr;
}

SafeRelease :: proc(res : ^RenderResources)
{
    SafeRelease(res.FontTexture);
    SafeRelease(res.FontTextureView);
    SafeRelease(res.Sampler);
    SafeRelease(res.Uniforms);
    SafeRelease(res.CommonBindGroup);
    SafeRelease(res.ImageBindGroup);
    SafeRelease(res.ImageBindGroupLayout);
};

SafeRelease :: proc(res : ^FrameResources)
{
    SafeRelease(res.IndexBuffer);
    SafeRelease(res.VertexBuffer);
    SafeRelease(res.IndexBufferHost);
    SafeRelease(res.VertexBufferHost);
}

ImGui_ImplWGPU_CreateShaderModule :: proc(wgsl_source : ^u8) -> WGPUProgrammableStageDescriptor
{
    bd := ImGui_ImplWGPU_GetBackendData();

when IMGUI_IMPL_WEBGPU_BACKEND_DAWN {
	WGPUShaderSourceWGSL wgsl_desc = {};
    wgsl_desc.chain.sType = WGPUSType_ShaderSourceWGSL;
	wgsl_desc.code = { wgsl_source, WGPU_STRLEN };
} else {
	WGPUShaderModuleWGSLDescriptor wgsl_desc = {};
    wgsl_desc.chain.sType = WGPUSType_ShaderModuleWGSLDescriptor;
	wgsl_desc.code = wgsl_source;
}

    desc := {};
    desc.nextInChain = reinterpret_cast<WGPUChainedStruct*>(&wgsl_desc);

    stage_desc := {};
    stage_desc.module = wgpuDeviceCreateShaderModule(bd.wgpuDevice, &desc);
when IMGUI_IMPL_WEBGPU_BACKEND_DAWN {
    stage_desc.entryPoint = { "main", WGPU_STRLEN };
} else {
    stage_desc.entryPoint = "main";
}
    return stage_desc;
}

ImGui_ImplWGPU_CreateImageBindGroup :: proc(layout : WGPUBindGroupLayout, texture : WGPUTextureView) -> WGPUBindGroup
{
    bd := ImGui_ImplWGPU_GetBackendData();
    WGPUBindGroupEntry image_bg_entries[] = { { nullptr, 0, 0, 0, 0, 0, texture } };

    image_bg_descriptor := {};
    image_bg_descriptor.layout = layout;
    image_bg_descriptor.entryCount = size_of(image_bg_entries) / size_of(WGPUBindGroupEntry);
    image_bg_descriptor.entries = image_bg_entries;
    return wgpuDeviceCreateBindGroup(bd.wgpuDevice, &image_bg_descriptor);
}

ImGui_ImplWGPU_SetupRenderState :: proc(draw_data : ^ImDrawData, ctx : WGPURenderPassEncoder, fr : ^FrameResources)
{
    bd := ImGui_ImplWGPU_GetBackendData();

    // Setup orthographic projection matrix into our constant buffer
    // Our visible imgui space lies from draw_data->DisplayPos (top left) to draw_data->DisplayPos+data_data->DisplaySize (bottom right).
    {
        L := draw_data.DisplayPos.x;
        R := draw_data.DisplayPos.x + draw_data.DisplaySize.x;
        T := draw_data.DisplayPos.y;
        B := draw_data.DisplayPos.y + draw_data.DisplaySize.y;
        f32 mvp[4][4] =
        {
            { 2.0/(R-L),   0.0,           0.0,       0.0 },
            { 0.0,         2.0/(T-B),     0.0,       0.0 },
            { 0.0,         0.0,           0.5,       0.0 },
            { (R+L)/(L-R),  (T+B)/(B-T),    0.5,       1.0 },
        };
        wgpuQueueWriteBuffer(bd.defaultQueue, bd.renderResources.Uniforms, offsetof(Uniforms, MVP), mvp, size_of(Uniforms::MVP));
        gamma : f32
        switch (bd.renderTargetFormat)
        {
        case WGPUTextureFormat_ASTC10x10UnormSrgb:
        case WGPUTextureFormat_ASTC10x5UnormSrgb:
        case WGPUTextureFormat_ASTC10x6UnormSrgb:
        case WGPUTextureFormat_ASTC10x8UnormSrgb:
        case WGPUTextureFormat_ASTC12x10UnormSrgb:
        case WGPUTextureFormat_ASTC12x12UnormSrgb:
        case WGPUTextureFormat_ASTC4x4UnormSrgb:
        case WGPUTextureFormat_ASTC5x5UnormSrgb:
        case WGPUTextureFormat_ASTC6x5UnormSrgb:
        case WGPUTextureFormat_ASTC6x6UnormSrgb:
        case WGPUTextureFormat_ASTC8x5UnormSrgb:
        case WGPUTextureFormat_ASTC8x6UnormSrgb:
        case WGPUTextureFormat_ASTC8x8UnormSrgb:
        case WGPUTextureFormat_BC1RGBAUnormSrgb:
        case WGPUTextureFormat_BC2RGBAUnormSrgb:
        case WGPUTextureFormat_BC3RGBAUnormSrgb:
        case WGPUTextureFormat_BC7RGBAUnormSrgb:
        case WGPUTextureFormat_BGRA8UnormSrgb:
        case WGPUTextureFormat_ETC2RGB8A1UnormSrgb:
        case WGPUTextureFormat_ETC2RGB8UnormSrgb:
        case WGPUTextureFormat_ETC2RGBA8UnormSrgb:
        case WGPUTextureFormat_RGBA8UnormSrgb:
            gamma = 2.2;
            break;
        case:
            gamma = 1.0;
        }
        wgpuQueueWriteBuffer(bd.defaultQueue, bd.renderResources.Uniforms, offsetof(Uniforms, Gamma), &gamma, size_of(Uniforms::Gamma));
    }

    // Setup viewport
    wgpuRenderPassEncoderSetViewport(ctx, 0, 0, draw_data.FramebufferScale.x * draw_data.DisplaySize.x, draw_data.FramebufferScale.y * draw_data.DisplaySize.y, 0, 1);

    // Bind shader and vertex buffers
    wgpuRenderPassEncoderSetVertexBuffer(ctx, 0, fr.VertexBuffer, 0, fr.VertexBufferSize * size_of(ImDrawVert));
    wgpuRenderPassEncoderSetIndexBuffer(ctx, fr.IndexBuffer, size_of(ImDrawIdx) == 2 ? WGPUIndexFormat_Uint16 : WGPUIndexFormat_Uint32, 0, fr.IndexBufferSize * size_of(ImDrawIdx));
    wgpuRenderPassEncoderSetPipeline(ctx, bd.pipelineState);
    wgpuRenderPassEncoderSetBindGroup(ctx, 0, bd.renderResources.CommonBindGroup, 0, nullptr);

    // Setup blend factor
    blend_color := { 0.f, 0.f, 0.f, 0.f };
    wgpuRenderPassEncoderSetBlendConstant(ctx, &blend_color);
}

// Render function
// (this used to be set in io.RenderDrawListsFn and called by ImGui::Render(), but you can now call this directly from your main loop)
ImGui_ImplWGPU_RenderDrawData :: proc(draw_data : ^ImDrawData, pass_encoder : WGPURenderPassEncoder)
{
    // Avoid rendering when minimized
    fb_width := (i32)(draw_data.DisplaySize.x * draw_data.FramebufferScale.x);
    fb_height := (i32)(draw_data.DisplaySize.y * draw_data.FramebufferScale.y);
    if (fb_width <= 0 || fb_height <= 0 || draw_data.CmdListsCount == 0)
        return;

    // FIXME: Assuming that this only gets called once per frame!
    // If not, we can't just re-allocate the IB or VB, we'll have to do a proper allocator.
    bd := ImGui_ImplWGPU_GetBackendData();
    bd.frameIndex = bd.frameIndex + 1;
    fr := &bd.pFrameResources[bd.frameIndex % bd.numFramesInFlight];

    // Create and grow vertex/index buffers if needed
    if (fr.VertexBuffer == nullptr || fr.VertexBufferSize < draw_data.TotalVtxCount)
    {
        if (fr.VertexBuffer)
        {
            wgpuBufferDestroy(fr.VertexBuffer);
            wgpuBufferRelease(fr.VertexBuffer);
        }
        SafeRelease(fr.VertexBufferHost);
        fr.VertexBufferSize = draw_data.TotalVtxCount + 5000;

        vb_desc :=
        {
            nullptr,
            "Dear ImGui Vertex buffer",
when IMGUI_IMPL_WEBGPU_BACKEND_DAWN {
            WGPU_STRLEN,
}
            WGPUBufferUsage_CopyDst | WGPUBufferUsage_Vertex,
            MEMALIGN(fr.VertexBufferSize * size_of(ImDrawVert), 4),
            false
        };
        fr.VertexBuffer = wgpuDeviceCreateBuffer(bd.wgpuDevice, &vb_desc);
        if (!fr.VertexBuffer)
            return;

        fr.VertexBufferHost = new ImDrawVert[fr.VertexBufferSize];
    }
    if (fr.IndexBuffer == nullptr || fr.IndexBufferSize < draw_data.TotalIdxCount)
    {
        if (fr.IndexBuffer)
        {
            wgpuBufferDestroy(fr.IndexBuffer);
            wgpuBufferRelease(fr.IndexBuffer);
        }
        SafeRelease(fr.IndexBufferHost);
        fr.IndexBufferSize = draw_data.TotalIdxCount + 10000;

        ib_desc :=
        {
            nullptr,
            "Dear ImGui Index buffer",
when IMGUI_IMPL_WEBGPU_BACKEND_DAWN {
            WGPU_STRLEN,
}
            WGPUBufferUsage_CopyDst | WGPUBufferUsage_Index,
            MEMALIGN(fr.IndexBufferSize * size_of(ImDrawIdx), 4),
            false
        };
        fr.IndexBuffer = wgpuDeviceCreateBuffer(bd.wgpuDevice, &ib_desc);
        if (!fr.IndexBuffer)
            return;

        fr.IndexBufferHost = new ImDrawIdx[fr.IndexBufferSize];
    }

    // Upload vertex/index data into a single contiguous GPU buffer
    vtx_dst := (ImDrawVert*)fr.VertexBufferHost;
    idx_dst := (ImDrawIdx*)fr.IndexBufferHost;
    for i32 n = 0; n < draw_data.CmdListsCount; n++
    {
        draw_list := draw_data.CmdLists[n];
        memcpy(vtx_dst, draw_list.VtxBuffer.Data, draw_list.VtxBuffer.Size * size_of(ImDrawVert));
        memcpy(idx_dst, draw_list.IdxBuffer.Data, draw_list.IdxBuffer.Size * size_of(ImDrawIdx));
        vtx_dst += draw_list.VtxBuffer.Size;
        idx_dst += draw_list.IdxBuffer.Size;
    }
    vb_write_size := MEMALIGN((u8*)vtx_dst - (u8*)fr.VertexBufferHost, 4);
    ib_write_size := MEMALIGN((u8*)idx_dst - (u8*)fr.IndexBufferHost, 4);
    wgpuQueueWriteBuffer(bd.defaultQueue, fr.VertexBuffer, 0, fr.VertexBufferHost, vb_write_size);
    wgpuQueueWriteBuffer(bd.defaultQueue, fr.IndexBuffer,  0, fr.IndexBufferHost,  ib_write_size);

    // Setup desired render state
    ImGui_ImplWGPU_SetupRenderState(draw_data, pass_encoder, fr);

    // Setup render state structure (for callbacks and custom texture bindings)
    ImGuiPlatformIO& platform_io = GetPlatformIO();
    render_state : ImGui_ImplWGPU_RenderState
    render_state.Device = bd.wgpuDevice;
    render_state.RenderPassEncoder = pass_encoder;
    platform_io.Renderer_RenderState = &render_state;

    // Render command lists
    // (Because we merged all buffers into a single one, we maintain our own offset into them)
    global_vtx_offset := 0;
    global_idx_offset := 0;
    clip_scale := draw_data.FramebufferScale;
    clip_off := draw_data.DisplayPos;
    for i32 n = 0; n < draw_data.CmdListsCount; n++
    {
        draw_list := draw_data.CmdLists[n];
        for i32 cmd_i = 0; cmd_i < draw_list.CmdBuffer.Size; cmd_i++
        {
            pcmd := &draw_list.CmdBuffer[cmd_i];
            if (pcmd.UserCallback != nullptr)
            {
                // User callback, registered via ImDrawList::AddCallback()
                // (ImDrawCallback_ResetRenderState is a special callback value used by the user to request the renderer to reset render state.)
                if (pcmd.UserCallback == ImDrawCallback_ResetRenderState)
                    ImGui_ImplWGPU_SetupRenderState(draw_data, pass_encoder, fr);
                else
                    pcmd.UserCallback(draw_list, pcmd);
            }
            else
            {
                // Bind custom texture
                tex_id := pcmd.GetTexID();
                tex_id_hash := ImHashData(&tex_id, size_of(tex_id));
                bind_group := bd.renderResources.ImageBindGroups.GetVoidPtr(tex_id_hash);
                if (bind_group)
                {
                    wgpuRenderPassEncoderSetBindGroup(pass_encoder, 1, (WGPUBindGroup)bind_group, 0, nullptr);
                }
                else
                {
                    image_bind_group := ImGui_ImplWGPU_CreateImageBindGroup(bd.renderResources.ImageBindGroupLayout, (WGPUTextureView)tex_id);
                    bd.renderResources.ImageBindGroups.SetVoidPtr(tex_id_hash, image_bind_group);
                    wgpuRenderPassEncoderSetBindGroup(pass_encoder, 1, image_bind_group, 0, nullptr);
                }

                // Project scissor/clipping rectangles into framebuffer space
                clip_min := ImVec2{(pcmd.ClipRect.x - clip_off.x} * clip_scale.x, (pcmd.ClipRect.y - clip_off.y) * clip_scale.y);
                clip_max := ImVec2{(pcmd.ClipRect.z - clip_off.x} * clip_scale.x, (pcmd.ClipRect.w - clip_off.y) * clip_scale.y);

                // Clamp to viewport as wgpuRenderPassEncoderSetScissorRect() won't accept values that are off bounds
                if (clip_min.x < 0.0) { clip_min.x = 0.0; }
                if (clip_min.y < 0.0) { clip_min.y = 0.0; }
                if (clip_max.x > fb_width) { clip_max.x = cast(ast) ast) dth) d
                if (clip_max.y > fb_height) { clip_max.y = cast(ast) ast) ight ig
                if (clip_max.x <= clip_min.x || clip_max.y <= clip_min.y)
                    continue;

                // Apply scissor/clipping rectangle, Draw
                wgpuRenderPassEncoderSetScissorRect(pass_encoder, cast(ast) ast) min) minu32)clip_min.y, (u32)(clip_max.x - clip_min.x), (u32)(clip_max.y - clip_min.y));
                wgpuRenderPassEncoderDrawIndexed(pass_encoder, pcmd.ElemCount, 1, pcmd.IdxOffset + global_idx_offset, pcmd.VtxOffset + global_vtx_offset, 0);
            }
        }
        global_idx_offset += draw_list.IdxBuffer.Size;
        global_vtx_offset += draw_list.VtxBuffer.Size;
    }
    platform_io.Renderer_RenderState = nullptr;
}

ImGui_ImplWGPU_CreateFontsTexture :: proc()
{
    // Build texture atlas
    bd := ImGui_ImplWGPU_GetBackendData();
    ImGuiIO& io = GetIO();
    pixels : ^u8
    width, height, size_pp : i32
    io.Fonts.GetTexDataAsRGBA32(&pixels, &width, &height, &size_pp);

    // Upload texture to graphics system
    {
        tex_desc := {};
when IMGUI_IMPL_WEBGPU_BACKEND_DAWN {
        tex_desc.label = { "Dear ImGui Font Texture", WGPU_STRLEN };
} else {
        tex_desc.label = "Dear ImGui Font Texture";
}
        tex_desc.dimension = WGPUTextureDimension_2D;
        tex_desc.size.width = width;
        tex_desc.size.height = height;
        tex_desc.size.depthOrArrayLayers = 1;
        tex_desc.sampleCount = 1;
        tex_desc.format = WGPUTextureFormat_RGBA8Unorm;
        tex_desc.mipLevelCount = 1;
        tex_desc.usage = WGPUTextureUsage_CopyDst | WGPUTextureUsage_TextureBinding;
        bd.renderResources.FontTexture = wgpuDeviceCreateTexture(bd.wgpuDevice, &tex_desc);

        tex_view_desc := {};
        tex_view_desc.format = WGPUTextureFormat_RGBA8Unorm;
        tex_view_desc.dimension = WGPUTextureViewDimension_2D;
        tex_view_desc.baseMipLevel = 0;
        tex_view_desc.mipLevelCount = 1;
        tex_view_desc.baseArrayLayer = 0;
        tex_view_desc.arrayLayerCount = 1;
        tex_view_desc.aspect = WGPUTextureAspect_All;
        bd.renderResources.FontTextureView = wgpuTextureCreateView(bd.renderResources.FontTexture, &tex_view_desc);
    }

    // Upload texture data
    {
        dst_view := {};
        dst_view.texture = bd.renderResources.FontTexture;
        dst_view.mipLevel = 0;
        dst_view.origin = { 0, 0, 0 };
        dst_view.aspect = WGPUTextureAspect_All;
        layout := {};
        layout.offset = 0;
        layout.bytesPerRow = width * size_pp;
        layout.rowsPerImage = height;
        size := { cast(ast) ast) ast) 2)height, 1 };
        wgpuQueueWriteTexture(bd.defaultQueue, &dst_view, pixels, (u32)(width * size_pp * height), &layout, &size);
    }

    // Create the associated sampler
    // (Bilinear sampling is required by default. Set 'io.Fonts->Flags |= ImFontAtlasFlags_NoBakedLines' or 'style.AntiAliasedLinesUseTex = false' to allow point/nearest sampling)
    {
        sampler_desc := {};
        sampler_desc.minFilter = WGPUFilterMode_Linear;
        sampler_desc.magFilter = WGPUFilterMode_Linear;
        sampler_desc.mipmapFilter = WGPUMipmapFilterMode_Linear;
        sampler_desc.addressModeU = WGPUAddressMode_ClampToEdge;
        sampler_desc.addressModeV = WGPUAddressMode_ClampToEdge;
        sampler_desc.addressModeW = WGPUAddressMode_ClampToEdge;
        sampler_desc.maxAnisotropy = 1;
        bd.renderResources.Sampler = wgpuDeviceCreateSampler(bd.wgpuDevice, &sampler_desc);
    }

    // Store our identifier
    static_assert(size_of(ImTextureID) >= size_of(bd.renderResources.FontTexture), "Can't pack descriptor handle into TexID, 32-bit not supported yet.");
    io.Fonts.SetTexID((ImTextureID)bd.renderResources.FontTextureView);
}

ImGui_ImplWGPU_CreateUniformBuffer :: proc()
{
    bd := ImGui_ImplWGPU_GetBackendData();
    ub_desc :=
    {
        nullptr,
        "Dear ImGui Uniform buffer",
when IMGUI_IMPL_WEBGPU_BACKEND_DAWN {
        WGPU_STRLEN,
}
        WGPUBufferUsage_CopyDst | WGPUBufferUsage_Uniform,
        MEMALIGN(size_of(Uniforms), 16),
        false
    };
    bd.renderResources.Uniforms = wgpuDeviceCreateBuffer(bd.wgpuDevice, &ub_desc);
}

ImGui_ImplWGPU_CreateDeviceObjects :: proc() -> bool
{
    bd := ImGui_ImplWGPU_GetBackendData();
    if (!bd.wgpuDevice)
        return false;
    if (bd.pipelineState)
        ImGui_ImplWGPU_InvalidateDeviceObjects();

    // Create render pipeline
    graphics_pipeline_desc := {};
    graphics_pipeline_desc.primitive.topology = WGPUPrimitiveTopology_TriangleList;
    graphics_pipeline_desc.primitive.stripIndexFormat = WGPUIndexFormat_Undefined;
    graphics_pipeline_desc.primitive.frontFace = WGPUFrontFace_CW;
    graphics_pipeline_desc.primitive.cullMode = WGPUCullMode_None;
    graphics_pipeline_desc.multisample = bd.initInfo.PipelineMultisampleState;

    // Bind group layouts
    WGPUBindGroupLayoutEntry common_bg_layout_entries[2] = {};
    common_bg_layout_entries[0].binding = 0;
    common_bg_layout_entries[0].visibility = WGPUShaderStage_Vertex | WGPUShaderStage_Fragment;
    common_bg_layout_entries[0].buffer.type = WGPUBufferBindingType_Uniform;
    common_bg_layout_entries[1].binding = 1;
    common_bg_layout_entries[1].visibility = WGPUShaderStage_Fragment;
    common_bg_layout_entries[1].sampler.type = WGPUSamplerBindingType_Filtering;

    WGPUBindGroupLayoutEntry image_bg_layout_entries[1] = {};
    image_bg_layout_entries[0].binding = 0;
    image_bg_layout_entries[0].visibility = WGPUShaderStage_Fragment;
    image_bg_layout_entries[0].texture.sampleType = WGPUTextureSampleType_Float;
    image_bg_layout_entries[0].texture.viewDimension = WGPUTextureViewDimension_2D;

    common_bg_layout_desc := {};
    common_bg_layout_desc.entryCount = 2;
    common_bg_layout_desc.entries = common_bg_layout_entries;

    image_bg_layout_desc := {};
    image_bg_layout_desc.entryCount = 1;
    image_bg_layout_desc.entries = image_bg_layout_entries;

    bg_layouts : [2]WGPUBindGroupLayout
    bg_layouts[0] = wgpuDeviceCreateBindGroupLayout(bd.wgpuDevice, &common_bg_layout_desc);
    bg_layouts[1] = wgpuDeviceCreateBindGroupLayout(bd.wgpuDevice, &image_bg_layout_desc);

    layout_desc := {};
    layout_desc.bindGroupLayoutCount = 2;
    layout_desc.bindGroupLayouts = bg_layouts;
    graphics_pipeline_desc.layout = wgpuDeviceCreatePipelineLayout(bd.wgpuDevice, &layout_desc);

    // Create the vertex shader
    vertex_shader_desc := ImGui_ImplWGPU_CreateShaderModule(__shader_vert_wgsl);
    graphics_pipeline_desc.vertex.module = vertex_shader_desc.module;
    graphics_pipeline_desc.vertex.entryPoint = vertex_shader_desc.entryPoint;

    // Vertex input configuration
    WGPUVertexAttribute attribute_desc[] =
    {
        { WGPUVertexFormat_Float32x2, cast(ast) ast) tof) tofawVert, pos), 0 },
        { WGPUVertexFormat_Float32x2, cast(ast) ast) tof) tofawVert, uv),  1 },
        { WGPUVertexFormat_Unorm8x4,  cast(ast) ast) tof) tofawVert, col), 2 },
    };

    buffer_layouts : [1]WGPUVertexBufferLayout
    buffer_layouts[0].arrayStride = size_of(ImDrawVert);
    buffer_layouts[0].stepMode = WGPUVertexStepMode_Vertex;
    buffer_layouts[0].attributeCount = 3;
    buffer_layouts[0].attributes = attribute_desc;

    graphics_pipeline_desc.vertex.bufferCount = 1;
    graphics_pipeline_desc.vertex.buffers = buffer_layouts;

    // Create the pixel shader
    pixel_shader_desc := ImGui_ImplWGPU_CreateShaderModule(__shader_frag_wgsl);

    // Create the blending setup
    blend_state := {};
    blend_state.alpha.operation = WGPUBlendOperation_Add;
    blend_state.alpha.srcFactor = WGPUBlendFactor_One;
    blend_state.alpha.dstFactor = WGPUBlendFactor_OneMinusSrcAlpha;
    blend_state.color.operation = WGPUBlendOperation_Add;
    blend_state.color.srcFactor = WGPUBlendFactor_SrcAlpha;
    blend_state.color.dstFactor = WGPUBlendFactor_OneMinusSrcAlpha;

    color_state := {};
    color_state.format = bd.renderTargetFormat;
    color_state.blend = &blend_state;
    color_state.writeMask = WGPUColorWriteMask_All;

    fragment_state := {};
    fragment_state.module = pixel_shader_desc.module;
    fragment_state.entryPoint = pixel_shader_desc.entryPoint;
    fragment_state.targetCount = 1;
    fragment_state.targets = &color_state;

    graphics_pipeline_desc.fragment = &fragment_state;

    // Create depth-stencil State
    depth_stencil_state := {};
    depth_stencil_state.format = bd.depthStencilFormat;
when IMGUI_IMPL_WEBGPU_BACKEND_DAWN {
    depth_stencil_state.depthWriteEnabled = WGPUOptionalBool_False;
} else {
    depth_stencil_state.depthWriteEnabled = false;
}
    depth_stencil_state.depthCompare = WGPUCompareFunction_Always;
    depth_stencil_state.stencilFront.compare = WGPUCompareFunction_Always;
    depth_stencil_state.stencilFront.failOp = WGPUStencilOperation_Keep;
    depth_stencil_state.stencilFront.depthFailOp = WGPUStencilOperation_Keep;
    depth_stencil_state.stencilFront.passOp = WGPUStencilOperation_Keep;
    depth_stencil_state.stencilBack.compare = WGPUCompareFunction_Always;
    depth_stencil_state.stencilBack.failOp = WGPUStencilOperation_Keep;
    depth_stencil_state.stencilBack.depthFailOp = WGPUStencilOperation_Keep;
    depth_stencil_state.stencilBack.passOp = WGPUStencilOperation_Keep;

    // Configure disabled depth-stencil state
    graphics_pipeline_desc.depthStencil = (bd.depthStencilFormat == WGPUTextureFormat_Undefined) ? nullptr :  &depth_stencil_state;

    bd.pipelineState = wgpuDeviceCreateRenderPipeline(bd.wgpuDevice, &graphics_pipeline_desc);

    ImGui_ImplWGPU_CreateFontsTexture();
    ImGui_ImplWGPU_CreateUniformBuffer();

    // Create resource bind group
    WGPUBindGroupEntry common_bg_entries[] =
    {
        { nullptr, 0, bd.renderResources.Uniforms, 0, MEMALIGN(size_of(Uniforms), 16), 0, 0 },
        { nullptr, 1, 0, 0, 0, bd.renderResources.Sampler, 0 },
    };

    common_bg_descriptor := {};
    common_bg_descriptor.layout = bg_layouts[0];
    common_bg_descriptor.entryCount = size_of(common_bg_entries) / size_of(WGPUBindGroupEntry);
    common_bg_descriptor.entries = common_bg_entries;
    bd.renderResources.CommonBindGroup = wgpuDeviceCreateBindGroup(bd.wgpuDevice, &common_bg_descriptor);

    image_bind_group := ImGui_ImplWGPU_CreateImageBindGroup(bg_layouts[1], bd.renderResources.FontTextureView);
    bd.renderResources.ImageBindGroup = image_bind_group;
    bd.renderResources.ImageBindGroupLayout = bg_layouts[1];
    bd.renderResources.ImageBindGroups.SetVoidPtr(ImHashData(&bd.renderResources.FontTextureView, size_of(ImTextureID)), image_bind_group);

    SafeRelease(vertex_shader_desc.module);
    SafeRelease(pixel_shader_desc.module);
    SafeRelease(graphics_pipeline_desc.layout);
    SafeRelease(bg_layouts[0]);

    return true;
}

ImGui_ImplWGPU_InvalidateDeviceObjects :: proc()
{
    bd := ImGui_ImplWGPU_GetBackendData();
    if (!bd.wgpuDevice)
        return;

    SafeRelease(bd.pipelineState);
    SafeRelease(bd.renderResources);

    ImGuiIO& io = GetIO();
    io.Fonts.SetTexID(0); // We copied g_pFontTextureView to io.Fonts->TexID so let's clear that as well.

    for u32 i = 0; i < bd.numFramesInFlight; i++
        SafeRelease(bd.pFrameResources[i]);
}

ImGui_ImplWGPU_Init :: proc(init_info : ^ImGui_ImplWGPU_InitInfo) -> bool
{
    ImGuiIO& io = GetIO();
    IMGUI_CHECKVERSION();
    assert(io.BackendRendererUserData == nullptr, "Already initialized a renderer backend!");

    // Setup backend capabilities flags
    bd := IM_NEW(ImGui_ImplWGPU_Data)();
    io.BackendRendererUserData = (rawptr)bd;
when defined(__EMSCRIPTEN__) {
    io.BackendRendererName = "imgui_impl_webgpu_emscripten";
} else when defined(IMGUI_IMPL_WEBGPU_BACKEND_DAWN) {
    io.BackendRendererName = "imgui_impl_webgpu_dawn";
} else when defined(IMGUI_IMPL_WEBGPU_BACKEND_WGPU) {
    io.BackendRendererName = "imgui_impl_webgpu_wgpu";
} else {
    io.BackendRendererName = "imgui_impl_webgpu";
}
    io.BackendFlags |= ImGuiBackendFlags_RendererHasVtxOffset;  // We can honor the ImDrawCmd::VtxOffset field, allowing for large meshes.

    bd.initInfo = *init_info;
    bd.wgpuDevice = init_info.Device;
    bd.defaultQueue = wgpuDeviceGetQueue(bd.wgpuDevice);
    bd.renderTargetFormat = init_info.RenderTargetFormat;
    bd.depthStencilFormat = init_info.DepthStencilFormat;
    bd.numFramesInFlight = init_info.NumFramesInFlight;
    bd.frameIndex = UINT_MAX;

    bd.renderResources.FontTexture = nullptr;
    bd.renderResources.FontTextureView = nullptr;
    bd.renderResources.Sampler = nullptr;
    bd.renderResources.Uniforms = nullptr;
    bd.renderResources.CommonBindGroup = nullptr;
    bd.renderResources.ImageBindGroups.Data.reserve(100);
    bd.renderResources.ImageBindGroup = nullptr;
    bd.renderResources.ImageBindGroupLayout = nullptr;

    // Create buffers with a default size (they will later be grown as needed)
    bd.pFrameResources = new FrameResources[bd.numFramesInFlight];
    for u32 i = 0; i < bd.numFramesInFlight; i++
    {
        fr := &bd.pFrameResources[i];
        fr.IndexBuffer = nullptr;
        fr.VertexBuffer = nullptr;
        fr.IndexBufferHost = nullptr;
        fr.VertexBufferHost = nullptr;
        fr.IndexBufferSize = 10000;
        fr.VertexBufferSize = 5000;
    }

    return true;
}

ImGui_ImplWGPU_Shutdown :: proc()
{
    bd := ImGui_ImplWGPU_GetBackendData();
    assert(bd != nullptr, "No renderer backend to shutdown, or already shutdown?");
    ImGuiIO& io = GetIO();

    ImGui_ImplWGPU_InvalidateDeviceObjects();
    delete[] bd.pFrameResources;
    bd.pFrameResources = nullptr;
    wgpuQueueRelease(bd.defaultQueue);
    bd.wgpuDevice = nullptr;
    bd.numFramesInFlight = 0;
    bd.frameIndex = UINT_MAX;

    io.BackendRendererName = nullptr;
    io.BackendRendererUserData = nullptr;
    io.BackendFlags &= ~ImGuiBackendFlags_RendererHasVtxOffset;
    IM_DELETE(bd);
}

ImGui_ImplWGPU_NewFrame :: proc()
{
    bd := ImGui_ImplWGPU_GetBackendData();
    if (!bd.pipelineState)
        ImGui_ImplWGPU_CreateDeviceObjects();
}

//-----------------------------------------------------------------------------

} // #ifndef IMGUI_DISABLE
