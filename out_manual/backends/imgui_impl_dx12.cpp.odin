package imgui

// dear imgui: Renderer Backend for DirectX12
// This needs to be used along with a Platform Backend (e.g. Win32)

// Implemented features:
//  [X] Renderer: User texture binding. Use 'D3D12_GPU_DESCRIPTOR_HANDLE' as ImTextureID. Read the FAQ about ImTextureID!
//  [X] Renderer: Large meshes support (64k+ vertices) even with 16-bit indices (ImGuiBackendFlags_RendererHasVtxOffset).
//  [X] Renderer: Expose selected render state for draw callbacks to use. Access in '(ImGui_ImplXXXX_RenderState*)GetPlatformIO().Renderer_RenderState'.
//  [X] Renderer: Multi-viewport support (multiple windows). Enable with 'io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable'.
//      FIXME: The transition from removing a viewport and moving the window in an existing hosted viewport tends to flicker.

// The aim of imgui_impl_dx12.h/.cpp is to be usable in your engine without any modification.
// IF YOU FEEL YOU NEED TO MAKE ANY CHANGE TO THIS CODE, please share them and your feedback at https://github.com/ocornut/imgui/

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// Learn about Dear ImGui:
// - FAQ                  https://dearimgui.com/faq
// - Getting Started      https://dearimgui.com/getting-started
// - Documentation        https://dearimgui.com/docs (same as your local docs/ folder).
// - Introduction, links and more at the top of imgui.cpp

// CHANGELOG
// (minor and older changes stripped away, please see git history for details)
//  2025-XX-XX: Platform: Added support for multiple windows via the ImGuiPlatformIO interface.
//  2024-12-09: DirectX12: Let user specifies the DepthStencilView format by setting ImGui_ImplDX12_InitInfo::DSVFormat.
//  2024-11-15: DirectX12: *BREAKING CHANGE* Changed ImGui_ImplDX12_Init() signature to take a ImGui_ImplDX12_InitInfo struct. Legacy ImGui_ImplDX12_Init() signature is still supported (will obsolete).
//  2024-11-15: DirectX12: *BREAKING CHANGE* User is now required to pass function pointers to allocate/free SRV Descriptors. We provide convenience legacy fields to pass a single descriptor, matching the old API, but upcoming features will want multiple.
//  2024-10-23: DirectX12: Unmap() call specify written range. The range is informational and may be used by debug tools.
//  2024-10-07: DirectX12: Changed default texture sampler to Clamp instead of Repeat/Wrap.
//  2024-10-07: DirectX12: Expose selected render state in ImGui_ImplDX12_RenderState, which you can access in 'void* platform_io.Renderer_RenderState' during draw callbacks.
//  2024-10-07: DirectX12: Compiling with '#define ImTextureID=ImU64' is unnecessary now that dear imgui defaults ImTextureID to u64 instead of void*.
//  2022-10-11: Using 'nullptr' instead of 'NULL' as per our switch to C++11.
//  2021-06-29: Reorganized backend to pull data from a single structure to facilitate usage with multiple-contexts (all g_XXXX access changed to bd->XXXX).
//  2021-05-19: DirectX12: Replaced direct access to ImDrawCmd::TextureId with a call to ImDrawCmd::GetTexID(). (will become a requirement)
//  2021-02-18: DirectX12: Change blending equation to preserve alpha in output buffer.
//  2021-01-11: DirectX12: Improve Windows 7 compatibility (for D3D12On7) by loading d3d12.dll dynamically.
//  2020-09-16: DirectX12: Avoid rendering calls with zero-sized scissor rectangle since it generates a validation layer warning.
//  2020-09-08: DirectX12: Clarified support for building on 32-bit systems by redefining ImTextureID.
//  2019-10-18: DirectX12: *BREAKING CHANGE* Added extra ID3D12DescriptorHeap parameter to ImGui_ImplDX12_Init() function.
//  2019-05-29: DirectX12: Added support for large mesh (64K+ vertices), enable ImGuiBackendFlags_RendererHasVtxOffset flag.
//  2019-04-30: DirectX12: Added support for special ImDrawCallback_ResetRenderState callback to reset render state.
//  2019-03-29: Misc: Various minor tidying up.
//  2018-12-03: Misc: Added #pragma comment statement to automatically link with d3dcompiler.lib when using D3DCompile().
//  2018-11-30: Misc: Setting up io.BackendRendererName so it can be displayed in the About Window.
//  2018-06-12: DirectX12: Moved the ID3D12GraphicsCommandList* parameter from NewFrame() to RenderDrawData().
//  2018-06-08: Misc: Extracted imgui_impl_dx12.cpp/.h away from the old combined DX12+Win32 example.
//  2018-06-08: DirectX12: Use draw_data->DisplayPos and draw_data->DisplaySize to setup projection matrix and clipping rectangle (to ease support for future multi-viewport).
//  2018-02-22: Merged into master with all Win32 code synchronized to other examples.

when !(IMGUI_DISABLE) {

// DirectX
when _MSC_VER {
#pragma comment(lib, "d3dcompiler") // Automatically link with d3dcompiler.lib as we are using D3DCompile() below.
}

// DirectX12 data

ImGui_ImplDX12_Texture :: struct
{
    pTextureResource : ^ID3D12Resource,
    hFontSrvCpuDescHandle : D3D12_CPU_DESCRIPTOR_HANDLE,
    hFontSrvGpuDescHandle : D3D12_GPU_DESCRIPTOR_HANDLE,

    ImGui_ImplDX12_Texture()    { memset((rawptr)this, 0, size_of(*this)); }
};

ImGui_ImplDX12_Data :: struct
{
    InitInfo : ImGui_ImplDX12_InitInfo,
    pd3dDevice : ^ID3D12Device,
    pRootSignature : ^ID3D12RootSignature,
    pPipelineState : ^ID3D12PipelineState,
    RTVFormat : DXGI_FORMAT,
    DSVFormat : DXGI_FORMAT,
    pd3dSrvDescHeap : ^ID3D12DescriptorHeap,
    numFramesInFlight : UINT,
    FontTexture : ImGui_ImplDX12_Texture,
    LegacySingleDescriptorUsed : bool,

    ImGui_ImplDX12_Data()       { memset((rawptr)this, 0, size_of(*this)); }
};

// Backend data stored in io.BackendRendererUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
ImGui_ImplDX12_GetBackendData :: proc() -> ^ImGui_ImplDX12_Data
{
    return GetCurrentContext() ? (ImGui_ImplDX12_Data*)GetIO().BackendRendererUserData : nullptr;
}

// Buffers used during the rendering of a frame
ImGui_ImplDX12_RenderBuffers :: struct
{
    IndexBuffer : ^ID3D12Resource,
    VertexBuffer : ^ID3D12Resource,
    IndexBufferSize : int,
    VertexBufferSize : int,
};

// Buffers used for secondary viewports created by the multi-viewports systems
ImGui_ImplDX12_FrameContext :: struct
{
    CommandAllocator : ^ID3D12CommandAllocator,
    RenderTarget : ^ID3D12Resource,
    RenderTargetCpuDescriptors : D3D12_CPU_DESCRIPTOR_HANDLE,
};

// Helper structure we store in the void* RendererUserData field of each ImGuiViewport to easily retrieve our backend data.
// Main viewport created by application will only use the Resources field.
// Secondary viewports created by this backend will use all the fields (including Window fields),
ImGui_ImplDX12_ViewportData :: struct
{
    // Window
    CommandQueue : ^ID3D12CommandQueue,
    CommandList : ^ID3D12GraphicsCommandList,
    RtvDescHeap : ^ID3D12DescriptorHeap,
    SwapChain : ^IDXGISwapChain3,
    Fence : ^ID3D12Fence,
    FenceSignaledValue : UINT64,
    FenceEvent : HANDLE,
    NumFramesInFlight : UINT,
    FrameCtx : ^ImGui_ImplDX12_FrameContext,

    // Render buffers
    FrameIndex : UINT,
    FrameRenderBuffers : ^ImGui_ImplDX12_RenderBuffers,

    ImGui_ImplDX12_ViewportData(UINT num_frames_in_flight)
    {
        CommandQueue = nullptr;
        CommandList = nullptr;
        RtvDescHeap = nullptr;
        SwapChain = nullptr;
        Fence = nullptr;
        FenceSignaledValue = 0;
        FenceEvent = nullptr;
        NumFramesInFlight = num_frames_in_flight;
        FrameCtx = new ImGui_ImplDX12_FrameContext[NumFramesInFlight];
        FrameIndex = UINT_MAX;
        FrameRenderBuffers = new ImGui_ImplDX12_RenderBuffers[NumFramesInFlight];

        for UINT i = 0; i < NumFramesInFlight; ++i
        {
            FrameCtx[i].CommandAllocator = nullptr;
            FrameCtx[i].RenderTarget = nullptr;

            // Create buffers with a default size (they will later be grown as needed)
            FrameRenderBuffers[i].IndexBuffer = nullptr;
            FrameRenderBuffers[i].VertexBuffer = nullptr;
            FrameRenderBuffers[i].VertexBufferSize = 5000;
            FrameRenderBuffers[i].IndexBufferSize = 10000;
        }
    }
    ~ImGui_ImplDX12_ViewportData()
    {
        assert(CommandQueue == nullptr && CommandList == nullptr);
        assert(RtvDescHeap == nullptr);
        assert(SwapChain == nullptr);
        assert(Fence == nullptr);
        assert(FenceEvent == nullptr);

        for UINT i = 0; i < NumFramesInFlight; ++i
        {
            assert(FrameCtx[i].CommandAllocator == nullptr && FrameCtx[i].RenderTarget == nullptr);
            assert(FrameRenderBuffers[i].IndexBuffer == nullptr && FrameRenderBuffers[i].VertexBuffer == nullptr);
        }

        delete[] FrameCtx; FrameCtx = nullptr;
        delete[] FrameRenderBuffers; FrameRenderBuffers = nullptr;
    }
};

VERTEX_CONSTANT_BUFFER_DX12 :: struct
{
    f32   mvp[4][4];
};

// Forward Declarations
void ImGui_ImplDX12_InitPlatformInterface();
void ImGui_ImplDX12_ShutdownPlatformInterface();

// Functions
ImGui_ImplDX12_SetupRenderState :: proc(draw_data : ^ImDrawData, command_list : ^ID3D12GraphicsCommandList, fr : ^ImGui_ImplDX12_RenderBuffers)
{
    bd := ImGui_ImplDX12_GetBackendData();

    // Setup orthographic projection matrix into our constant buffer
    // Our visible imgui space lies from draw_data->DisplayPos (top left) to draw_data->DisplayPos+data_data->DisplaySize (bottom right).
    vertex_constant_buffer : VERTEX_CONSTANT_BUFFER_DX12
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
        memcpy(&vertex_constant_buffer.mvp, mvp, size_of(mvp));
    }

    // Setup viewport
    vp : D3D12_VIEWPORT
    memset(&vp, 0, size_of(D3D12_VIEWPORT));
    vp.Width = draw_data.DisplaySize.x;
    vp.Height = draw_data.DisplaySize.y;
    vp.MinDepth = 0.0;
    vp.MaxDepth = 1.0;
    vp.TopLeftX = vp.TopLeftY = 0.0;
    command_list.RSSetViewports(1, &vp);

    // Bind shader and vertex buffers
    stride := size_of(ImDrawVert);
    offset := 0;
    vbv : D3D12_VERTEX_BUFFER_VIEW
    memset(&vbv, 0, size_of(D3D12_VERTEX_BUFFER_VIEW));
    vbv.BufferLocation = fr.VertexBuffer.GetGPUVirtualAddress() + offset;
    vbv.SizeInBytes = fr.VertexBufferSize * stride;
    vbv.StrideInBytes = stride;
    command_list.IASetVertexBuffers(0, 1, &vbv);
    ibv : D3D12_INDEX_BUFFER_VIEW
    memset(&ibv, 0, size_of(D3D12_INDEX_BUFFER_VIEW));
    ibv.BufferLocation = fr.IndexBuffer.GetGPUVirtualAddress();
    ibv.SizeInBytes = fr.IndexBufferSize * size_of(ImDrawIdx);
    ibv.Format = size_of(ImDrawIdx) == 2 ? DXGI_FORMAT_R16_UINT : DXGI_FORMAT_R32_UINT;
    command_list.IASetIndexBuffer(&ibv);
    command_list.IASetPrimitiveTopology(D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    command_list.SetPipelineState(bd.pPipelineState);
    command_list.SetGraphicsRootSignature(bd.pRootSignature);
    command_list.SetGraphicsRoot32BitConstants(0, 16, &vertex_constant_buffer, 0);

    // Setup blend factor
    const f32 blend_factor[4] = { 0.f, 0.f, 0.f, 0.f };
    command_list.OMSetBlendFactor(blend_factor);
}

template<typename T>
inline void SafeRelease(T*& res)
{
    if (res)   do res.Release()
    res = nullptr;
}

// Render function
ImGui_ImplDX12_RenderDrawData :: proc(draw_data : ^ImDrawData, command_list : ^ID3D12GraphicsCommandList)
{
    // Avoid rendering when minimized
    if (draw_data.DisplaySize.x <= 0.0 || draw_data.DisplaySize.y <= 0.0)   do return

    bd := ImGui_ImplDX12_GetBackendData();
    vd := (ImGui_ImplDX12_ViewportData*)draw_data.OwnerViewport.RendererUserData;
    vd.FrameIndex += 1;
    fr := &vd.FrameRenderBuffers[vd.FrameIndex % bd.numFramesInFlight];

    // Create and grow vertex/index buffers if needed
    if (fr.VertexBuffer == nullptr || fr.VertexBufferSize < draw_data.TotalVtxCount)
    {
        SafeRelease(fr.VertexBuffer);
        fr.VertexBufferSize = draw_data.TotalVtxCount + 5000;
        props : D3D12_HEAP_PROPERTIES
        memset(&props, 0, size_of(D3D12_HEAP_PROPERTIES));
        props.Type = D3D12_HEAP_TYPE_UPLOAD;
        props.CPUPageProperty = D3D12_CPU_PAGE_PROPERTY_UNKNOWN;
        props.MemoryPoolPreference = D3D12_MEMORY_POOL_UNKNOWN;
        desc : D3D12_RESOURCE_DESC
        memset(&desc, 0, size_of(D3D12_RESOURCE_DESC));
        desc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
        desc.Width = fr.VertexBufferSize * size_of(ImDrawVert);
        desc.Height = 1;
        desc.DepthOrArraySize = 1;
        desc.MipLevels = 1;
        desc.Format = DXGI_FORMAT_UNKNOWN;
        desc.SampleDesc.Count = 1;
        desc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
        desc.Flags = D3D12_RESOURCE_FLAG_NONE;
        if (bd.pd3dDevice.CreateCommittedResource(&props, D3D12_HEAP_FLAG_NONE, &desc, D3D12_RESOURCE_STATE_GENERIC_READ, nullptr, IID_PPV_ARGS(&fr.VertexBuffer)) < 0)   do return
    }
    if (fr.IndexBuffer == nullptr || fr.IndexBufferSize < draw_data.TotalIdxCount)
    {
        SafeRelease(fr.IndexBuffer);
        fr.IndexBufferSize = draw_data.TotalIdxCount + 10000;
        props : D3D12_HEAP_PROPERTIES
        memset(&props, 0, size_of(D3D12_HEAP_PROPERTIES));
        props.Type = D3D12_HEAP_TYPE_UPLOAD;
        props.CPUPageProperty = D3D12_CPU_PAGE_PROPERTY_UNKNOWN;
        props.MemoryPoolPreference = D3D12_MEMORY_POOL_UNKNOWN;
        desc : D3D12_RESOURCE_DESC
        memset(&desc, 0, size_of(D3D12_RESOURCE_DESC));
        desc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
        desc.Width = fr.IndexBufferSize * size_of(ImDrawIdx);
        desc.Height = 1;
        desc.DepthOrArraySize = 1;
        desc.MipLevels = 1;
        desc.Format = DXGI_FORMAT_UNKNOWN;
        desc.SampleDesc.Count = 1;
        desc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
        desc.Flags = D3D12_RESOURCE_FLAG_NONE;
        if (bd.pd3dDevice.CreateCommittedResource(&props, D3D12_HEAP_FLAG_NONE, &desc, D3D12_RESOURCE_STATE_GENERIC_READ, nullptr, IID_PPV_ARGS(&fr.IndexBuffer)) < 0)   do return
    }

    // Upload vertex/index data into a single contiguous GPU buffer
    // During Map() we specify a null read range (as per DX12 API, this is informational and for tooling only)
    rawptr vtx_resource, *idx_resource;
    range := { 0, 0 };
    if (fr.VertexBuffer.Map(0, &range, &vtx_resource) != S_OK)   do return
    if (fr.IndexBuffer.Map(0, &range, &idx_resource) != S_OK)   do return
    vtx_dst := (ImDrawVert*)vtx_resource;
    idx_dst := (ImDrawIdx*)idx_resource;
    for int n = 0; n < draw_data.CmdListsCount; n += 1
    {
        const ImDrawList* draw_list = draw_data.CmdLists[n];
        memcpy(vtx_dst, draw_list.VtxBuffer.Data, len(draw_list.VtxBuffer) * size_of(ImDrawVert));
        memcpy(idx_dst, draw_list.IdxBuffer.Data, len(draw_list.IdxBuffer) * size_of(ImDrawIdx));
        vtx_dst += len(draw_list.VtxBuffer);
        idx_dst += len(draw_list.IdxBuffer);
    }

    // During Unmap() we specify the written range (as per DX12 API, this is informational and for tooling only)
    range.End = (SIZE_T)((rawptr)vtx_dst - (rawptr)vtx_resource);
    assert(range.End == draw_data.TotalVtxCount * size_of(ImDrawVert));
    fr.VertexBuffer.Unmap(0, &range);
    range.End = (SIZE_T)((rawptr)idx_dst - (rawptr)idx_resource);
    assert(range.End == draw_data.TotalIdxCount * size_of(ImDrawIdx));
    fr.IndexBuffer.Unmap(0, &range);

    // Setup desired DX state
    ImGui_ImplDX12_SetupRenderState(draw_data, command_list, fr);

    // Setup render state structure (for callbacks and custom texture bindings)
    platform_io := &GetPlatformIO();
    render_state : ImGui_ImplDX12_RenderState
    render_state.Device = bd.pd3dDevice;
    render_state.CommandList = command_list;
    platform_io.Renderer_RenderState = &render_state;

    // Render command lists
    // (Because we merged all buffers into a single one, we maintain our own offset into them)
    global_vtx_offset := 0;
    global_idx_offset := 0;
    clip_off := draw_data.DisplayPos;
    for int n = 0; n < draw_data.CmdListsCount; n += 1
    {
        const ImDrawList* draw_list = draw_data.CmdLists[n];
        for int cmd_i = 0; cmd_i < len(draw_list.CmdBuffer); cmd_i += 1
        {
            const ImDrawCmd* pcmd = &draw_list.CmdBuffer[cmd_i];
            if (pcmd.UserCallback != nullptr)
            {
                // User callback, registered via ImDrawList::AddCallback()
                // (ImDrawCallback_ResetRenderState is a special callback value used by the user to request the renderer to reset render state.)
                if (pcmd.UserCallback == ImDrawCallback_ResetRenderState)
                    ImGui_ImplDX12_SetupRenderState(draw_data, command_list, fr);
                else
                    pcmd.UserCallback(draw_list, pcmd);
            }
            else
            {
                // Project scissor/clipping rectangles into framebuffer space
                clip_min := ImVec2{pcmd.ClipRect.x - clip_off.x, pcmd.ClipRect.y - clip_off.y};
                clip_max := ImVec2{pcmd.ClipRect.z - clip_off.x, pcmd.ClipRect.w - clip_off.y};
                if (clip_max.x <= clip_min.x || clip_max.y <= clip_min.y)   do continue

                // Apply scissor/clipping rectangle
                r := { (LONG)clip_min.x, (LONG)clip_min.y, (LONG)clip_max.x, (LONG)clip_max.y };
                command_list.RSSetScissorRects(1, &r);

                // Bind texture, Draw
                texture_handle := {};
                texture_handle.ptr = (UINT64)pcmd.GetTexID();
                command_list.SetGraphicsRootDescriptorTable(1, texture_handle);
                command_list.DrawIndexedInstanced(pcmd.ElemCount, 1, pcmd.IdxOffset + global_idx_offset, pcmd.VtxOffset + global_vtx_offset, 0);
            }
        }
        global_idx_offset += len(draw_list.IdxBuffer);
        global_vtx_offset += len(draw_list.VtxBuffer);
    }
    platform_io.Renderer_RenderState = nullptr;
}

ImGui_ImplDX12_CreateFontsTexture :: proc()
{
    // Build texture atlas
    io := GetIO();
    bd := ImGui_ImplDX12_GetBackendData();
    pixels : ^u8
    width, height : i32
    io.Fonts.GetTexDataAsRGBA32(&pixels, &width, &height);

    // Upload texture to graphics system
    font_tex := &bd.FontTexture;
    {
        props : D3D12_HEAP_PROPERTIES
        memset(&props, 0, size_of(D3D12_HEAP_PROPERTIES));
        props.Type = D3D12_HEAP_TYPE_DEFAULT;
        props.CPUPageProperty = D3D12_CPU_PAGE_PROPERTY_UNKNOWN;
        props.MemoryPoolPreference = D3D12_MEMORY_POOL_UNKNOWN;

        desc : D3D12_RESOURCE_DESC
        ZeroMemory(&desc, size_of(desc));
        desc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
        desc.Alignment = 0;
        desc.Width = width;
        desc.Height = height;
        desc.DepthOrArraySize = 1;
        desc.MipLevels = 1;
        desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
        desc.SampleDesc.Count = 1;
        desc.SampleDesc.Quality = 0;
        desc.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
        desc.Flags = D3D12_RESOURCE_FLAG_NONE;

        pTexture := nullptr;
        bd.pd3dDevice.CreateCommittedResource(&props, D3D12_HEAP_FLAG_NONE, &desc,
            D3D12_RESOURCE_STATE_COPY_DEST, nullptr, IID_PPV_ARGS(&pTexture));

        uploadPitch := (width * 4 + D3D12_TEXTURE_DATA_PITCH_ALIGNMENT - 1u) & ~(D3D12_TEXTURE_DATA_PITCH_ALIGNMENT - 1u);
        uploadSize := height * uploadPitch;
        desc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
        desc.Alignment = 0;
        desc.Width = uploadSize;
        desc.Height = 1;
        desc.DepthOrArraySize = 1;
        desc.MipLevels = 1;
        desc.Format = DXGI_FORMAT_UNKNOWN;
        desc.SampleDesc.Count = 1;
        desc.SampleDesc.Quality = 0;
        desc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
        desc.Flags = D3D12_RESOURCE_FLAG_NONE;

        props.Type = D3D12_HEAP_TYPE_UPLOAD;
        props.CPUPageProperty = D3D12_CPU_PAGE_PROPERTY_UNKNOWN;
        props.MemoryPoolPreference = D3D12_MEMORY_POOL_UNKNOWN;

        uploadBuffer := nullptr;
        hr := bd.pd3dDevice.CreateCommittedResource(&props, D3D12_HEAP_FLAG_NONE, &desc,
            D3D12_RESOURCE_STATE_GENERIC_READ, nullptr, IID_PPV_ARGS(&uploadBuffer));
        assert(SUCCEEDED(hr));

        mapped := nullptr;
        range := { 0, uploadSize };
        hr = uploadBuffer.Map(0, &range, &mapped);
        assert(SUCCEEDED(hr));
        for y := 0; y < height; y += 1
            memcpy((rawptr) ((urawptr) mapped + y * uploadPitch), pixels + y * width * 4, width * 4);
        uploadBuffer.Unmap(0, &range);

        srcLocation := {};
        srcLocation.pResource = uploadBuffer;
        srcLocation.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
        srcLocation.PlacedFootprint.Footprint.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
        srcLocation.PlacedFootprint.Footprint.Width = width;
        srcLocation.PlacedFootprint.Footprint.Height = height;
        srcLocation.PlacedFootprint.Footprint.Depth = 1;
        srcLocation.PlacedFootprint.Footprint.RowPitch = uploadPitch;

        dstLocation := {};
        dstLocation.pResource = pTexture;
        dstLocation.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
        dstLocation.SubresourceIndex = 0;

        barrier := {};
        barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
        barrier.Flags = D3D12_RESOURCE_BARRIER_FLAG_NONE;
        barrier.Transition.pResource   = pTexture;
        barrier.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
        barrier.Transition.StateBefore = D3D12_RESOURCE_STATE_COPY_DEST;
        barrier.Transition.StateAfter  = D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE;

        fence := nullptr;
        hr = bd.pd3dDevice.CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&fence));
        assert(SUCCEEDED(hr));

        event := ::CreateEvent(0, 0, 0, 0);
        assert(event != nullptr);

        queueDesc := {};
        queueDesc.Type     = D3D12_COMMAND_LIST_TYPE_DIRECT;
        queueDesc.Flags    = D3D12_COMMAND_QUEUE_FLAG_NONE;
        queueDesc.NodeMask = 1;

        cmdQueue := nullptr;
        hr = bd.pd3dDevice.CreateCommandQueue(&queueDesc, IID_PPV_ARGS(&cmdQueue));
        assert(SUCCEEDED(hr));

        cmdAlloc := nullptr;
        hr = bd.pd3dDevice.CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&cmdAlloc));
        assert(SUCCEEDED(hr));

        cmdList := nullptr;
        hr = bd.pd3dDevice.CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, cmdAlloc, nullptr, IID_PPV_ARGS(&cmdList));
        assert(SUCCEEDED(hr));

        cmdList.CopyTextureRegion(&dstLocation, 0, 0, 0, &srcLocation, nullptr);
        cmdList.ResourceBarrier(1, &barrier);

        hr = cmdList.Close();
        assert(SUCCEEDED(hr));

        cmdQueue.ExecuteCommandLists(1, (ID3D12CommandList* const*)&cmdList);
        hr = cmdQueue.Signal(fence, 1);
        assert(SUCCEEDED(hr));

        fence.SetEventOnCompletion(1, event);
        ::WaitForSingleObject(event, INFINITE);

        cmdList.Release();
        cmdAlloc.Release();
        cmdQueue.Release();
        ::CloseHandle(event);
        fence.Release();
        uploadBuffer.Release();

        // Create texture view
        srvDesc : D3D12_SHADER_RESOURCE_VIEW_DESC
        ZeroMemory(&srvDesc, size_of(srvDesc));
        srvDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
        srvDesc.ViewDimension = D3D12_SRV_DIMENSION_TEXTURE2D;
        srvDesc.Texture2D.MipLevels = desc.MipLevels;
        srvDesc.Texture2D.MostDetailedMip = 0;
        srvDesc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
        bd.pd3dDevice.CreateShaderResourceView(pTexture, &srvDesc, font_tex.hFontSrvCpuDescHandle);
        SafeRelease(font_tex.pTextureResource);
        font_tex.pTextureResource = pTexture;
    }

    // Store our identifier
    io.Fonts.SetTexID((ImTextureID)font_tex.hFontSrvGpuDescHandle.ptr);
}

ImGui_ImplDX12_CreateDeviceObjects :: proc() -> bool
{
    bd := ImGui_ImplDX12_GetBackendData();
    if (!bd || !bd.pd3dDevice)   do return false
    if (bd.pPipelineState)
        ImGui_ImplDX12_InvalidateDeviceObjects();

    // Create the root signature
    {
        descRange := {};
        descRange.RangeType = D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
        descRange.NumDescriptors = 1;
        descRange.BaseShaderRegister = 0;
        descRange.RegisterSpace = 0;
        descRange.OffsetInDescriptorsFromTableStart = 0;

        D3D12_ROOT_PARAMETER param[2] = {};

        param[0].ParameterType = D3D12_ROOT_PARAMETER_TYPE_32BIT_CONSTANTS;
        param[0].Constants.ShaderRegister = 0;
        param[0].Constants.RegisterSpace = 0;
        param[0].Constants.Num32BitValues = 16;
        param[0].ShaderVisibility = D3D12_SHADER_VISIBILITY_VERTEX;

        param[1].ParameterType = D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE;
        param[1].DescriptorTable.NumDescriptorRanges = 1;
        param[1].DescriptorTable.pDescriptorRanges = &descRange;
        param[1].ShaderVisibility = D3D12_SHADER_VISIBILITY_PIXEL;

        // Bilinear sampling is required by default. Set 'io.Fonts.Flags |= ImFontAtlasFlags_NoBakedLines' or 'style.AntiAliasedLinesUseTex = false' to allow point/nearest sampling.
        staticSampler := {};
        staticSampler.Filter = D3D12_FILTER_MIN_MAG_MIP_LINEAR;
        staticSampler.AddressU = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
        staticSampler.AddressV = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
        staticSampler.AddressW = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
        staticSampler.MipLODBias = 0.0
        staticSampler.MaxAnisotropy = 0;
        staticSampler.ComparisonFunc = D3D12_COMPARISON_FUNC_ALWAYS;
        staticSampler.BorderColor = D3D12_STATIC_BORDER_COLOR_TRANSPARENT_BLACK;
        staticSampler.MinLOD = 0.0
        staticSampler.MaxLOD = 0.0
        staticSampler.ShaderRegister = 0;
        staticSampler.RegisterSpace = 0;
        staticSampler.ShaderVisibility = D3D12_SHADER_VISIBILITY_PIXEL;

        desc := {};
        desc.NumParameters = _countof(param);
        desc.pParameters = param;
        desc.NumStaticSamplers = 1;
        desc.pStaticSamplers = &staticSampler;
        desc.Flags =
            D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT |
            D3D12_ROOT_SIGNATURE_FLAG_DENY_HULL_SHADER_ROOT_ACCESS |
            D3D12_ROOT_SIGNATURE_FLAG_DENY_DOMAIN_SHADER_ROOT_ACCESS |
            D3D12_ROOT_SIGNATURE_FLAG_DENY_GEOMETRY_SHADER_ROOT_ACCESS;

        // Load d3d12.dll and D3D12SerializeRootSignature() function address dynamically to facilitate using with D3D12On7.
        // See if any version of d3d12.dll is already loaded in the process. If so, give preference to that.
        static HINSTANCE d3d12_dll = ::GetModuleHandleA("d3d12.dll");
        if (d3d12_dll == nullptr)
        {
            // Attempt to load d3d12.dll from local directories. This will only succeed if
            // (1) the current OS is Windows 7, and
            // (2) there exists a version of d3d12.dll for Windows 7 (D3D12On7) in one of the following directories.
            // See https://github.com/ocornut/imgui/pull/3696 for details.
            const u8* localD3d12Paths[] = { ".\\d3d12.dll", ".\\d3d12on7\\d3d12.dll", ".\\12on7\\d3d12.dll" }; // A. current directory, B. used by some games, C. used in Microsoft D3D12On7 sample
            for int i = 0; i < len(localD3d12Paths); i += 1
                if ((d3d12_dll = ::LoadLibraryA(localD3d12Paths[i])) != nullptr)   do break

            // If failed, we are on Windows >= 10.
            if (d3d12_dll == nullptr) {
                d3d12_dll = ::LoadLibraryA("d3d12.dll");
            }

            if (d3d12_dll == nullptr)   do return false
        }

        D3D12SerializeRootSignatureFn := (PFN_D3D12_SERIALIZE_ROOT_SIGNATURE)::GetProcAddress(d3d12_dll, "D3D12SerializeRootSignature");
        if (D3D12SerializeRootSignatureFn == nullptr)   do return false

        blob := nullptr;
        if (D3D12SerializeRootSignatureFn(&desc, D3D_ROOT_SIGNATURE_VERSION_1, &blob, nullptr) != S_OK)   do return false

        bd.pd3dDevice.CreateRootSignature(0, blob.GetBufferPointer(), blob.GetBufferSize(), IID_PPV_ARGS(&bd.pRootSignature));
        blob.Release();
    }

    // By using D3DCompile() from <d3dcompiler.h> / d3dcompiler.lib, we introduce a dependency to a given version of d3dcompiler_XX.dll (see D3DCOMPILER_DLL_A)
    // If you would like to use this DX12 sample code but remove this dependency you can:
    //  1) compile once, save the compiled shader blobs into a file or source code and assign them to psoDesc.VS/PS [preferred solution]
    //  2) use code to detect any version of the DLL and grab a pointer to D3DCompile from the DLL.
    // See https://github.com/ocornut/imgui/pull/638 for sources and details.

    psoDesc : D3D12_GRAPHICS_PIPELINE_STATE_DESC
    memset(&psoDesc, 0, size_of(D3D12_GRAPHICS_PIPELINE_STATE_DESC));
    psoDesc.NodeMask = 1;
    psoDesc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
    psoDesc.pRootSignature = bd.pRootSignature;
    psoDesc.SampleMask = UINT_MAX;
    psoDesc.NumRenderTargets = 1;
    psoDesc.RTVFormats[0] = bd.RTVFormat;
    psoDesc.DSVFormat = bd.DSVFormat;
    psoDesc.SampleDesc.Count = 1;
    psoDesc.Flags = D3D12_PIPELINE_STATE_FLAG_NONE;

    vertexShaderBlob : ^ID3DBlob
    pixelShaderBlob : ^ID3DBlob

    // Create the vertex shader
    {
        static const char* vertexShader =
            "cbuffer vertexBuffer : register(b0) \
            {\
              ProjectionMatrix : float4x4
            };\
            struct VS_INPUT\
            {\
              float2 pos : POSITION;\
              float4 col : COLOR0;\
              float2 uv  : TEXCOORD0;\
            };\
            \
            struct PS_INPUT\
            {\
              float4 pos : SV_POSITION;\
              float4 col : COLOR0;\
              float2 uv  : TEXCOORD0;\
            };\
            \
            PS_INPUT main(VS_INPUT input)\
            {\
              output : PS_INPUT
              output.pos = mul( ProjectionMatrix, float4(input.pos.xy, 0.f, 1.f));\
              output.col = input.col;\
              output.uv  = input.uv;\
              return output;\
            }";

        if (FAILED(D3DCompile(vertexShader, strlen(vertexShader), nullptr, nullptr, nullptr, "main", "vs_5_0", 0, 0, &vertexShaderBlob, nullptr)))   do return false // NB: Pass ID3DBlob* pErrorBlob to D3DCompile() to get error showing in (const char*)pErrorBlob.GetBufferPointer(). Make sure to Release() the blob!
        psoDesc.VS = { vertexShaderBlob.GetBufferPointer(), vertexShaderBlob.GetBufferSize() };

        // Create the input layout
        static D3D12_INPUT_ELEMENT_DESC local_layout[] =
        {
            { "POSITION", 0, DXGI_FORMAT_R32G32_FLOAT,   0, (UINT)offset_of(ImDrawVert, pos), D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
            { "TEXCOORD", 0, DXGI_FORMAT_R32G32_FLOAT,   0, (UINT)offset_of(ImDrawVert, uv),  D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
            { "COLOR",    0, DXGI_FORMAT_R8G8B8A8_UNORM, 0, (UINT)offset_of(ImDrawVert, col), D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
        };
        psoDesc.InputLayout = { local_layout, 3 };
    }

    // Create the pixel shader
    {
        static const char* pixelShader =
            "struct PS_INPUT\
            {\
              float4 pos : SV_POSITION;\
              float4 col : COLOR0;\
              float2 uv  : TEXCOORD0;\
            };\
            SamplerState sampler0 : register(s0);\
            Texture2D texture0 : register(t0);\
            \
            float4 main(PS_INPUT input) : SV_Target\
            {\
              out_col := input.col * texture0.Sample(sampler0, input.uv); \
              return out_col; \
            }";

        if (FAILED(D3DCompile(pixelShader, strlen(pixelShader), nullptr, nullptr, nullptr, "main", "ps_5_0", 0, 0, &pixelShaderBlob, nullptr)))
        {
            vertexShaderBlob.Release();
            return false; // NB: Pass ID3DBlob* pErrorBlob to D3DCompile() to get error showing in (const char*)pErrorBlob.GetBufferPointer(). Make sure to Release() the blob!
        }
        psoDesc.PS = { pixelShaderBlob.GetBufferPointer(), pixelShaderBlob.GetBufferSize() };
    }

    // Create the blending setup
    {
        desc := &psoDesc.BlendState;
        desc.AlphaToCoverageEnable = false;
        desc.RenderTarget[0].BlendEnable = true;
        desc.RenderTarget[0].SrcBlend = D3D12_BLEND_SRC_ALPHA;
        desc.RenderTarget[0].DestBlend = D3D12_BLEND_INV_SRC_ALPHA;
        desc.RenderTarget[0].BlendOp = D3D12_BLEND_OP_ADD;
        desc.RenderTarget[0].SrcBlendAlpha = D3D12_BLEND_ONE;
        desc.RenderTarget[0].DestBlendAlpha = D3D12_BLEND_INV_SRC_ALPHA;
        desc.RenderTarget[0].BlendOpAlpha = D3D12_BLEND_OP_ADD;
        desc.RenderTarget[0].RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;
    }

    // Create the rasterizer state
    {
        desc := &psoDesc.RasterizerState;
        desc.FillMode = D3D12_FILL_MODE_SOLID;
        desc.CullMode = D3D12_CULL_MODE_NONE;
        desc.FrontCounterClockwise = FALSE;
        desc.DepthBias = D3D12_DEFAULT_DEPTH_BIAS;
        desc.DepthBiasClamp = D3D12_DEFAULT_DEPTH_BIAS_CLAMP;
        desc.SlopeScaledDepthBias = D3D12_DEFAULT_SLOPE_SCALED_DEPTH_BIAS;
        desc.DepthClipEnable = true;
        desc.MultisampleEnable = FALSE;
        desc.AntialiasedLineEnable = FALSE;
        desc.ForcedSampleCount = 0;
        desc.ConservativeRaster = D3D12_CONSERVATIVE_RASTERIZATION_MODE_OFF;
    }

    // Create depth-stencil State
    {
        desc := &psoDesc.DepthStencilState;
        desc.DepthEnable = false;
        desc.DepthWriteMask = D3D12_DEPTH_WRITE_MASK_ALL;
        desc.DepthFunc = D3D12_COMPARISON_FUNC_ALWAYS;
        desc.StencilEnable = false;
        desc.FrontFace.StencilFailOp = desc.FrontFace.StencilDepthFailOp = desc.FrontFace.StencilPassOp = D3D12_STENCIL_OP_KEEP;
        desc.FrontFace.StencilFunc = D3D12_COMPARISON_FUNC_ALWAYS;
        desc.BackFace = desc.FrontFace;
    }

    result_pipeline_state := bd.pd3dDevice.CreateGraphicsPipelineState(&psoDesc, IID_PPV_ARGS(&bd.pPipelineState));
    vertexShaderBlob.Release();
    pixelShaderBlob.Release();
    if (result_pipeline_state != S_OK)   do return false

    ImGui_ImplDX12_CreateFontsTexture();

    return true;
}

ImGui_ImplDX12_DestroyRenderBuffers :: proc(render_buffers : ^ImGui_ImplDX12_RenderBuffers)
{
    SafeRelease(render_buffers.IndexBuffer);
    SafeRelease(render_buffers.VertexBuffer);
    render_buffers.IndexBufferSize = render_buffers.VertexBufferSize = 0;
}

ImGui_ImplDX12_InvalidateDeviceObjects :: proc()
{
    bd := ImGui_ImplDX12_GetBackendData();
    if (!bd || !bd.pd3dDevice)   do return

    io := GetIO();
    SafeRelease(bd.pRootSignature);
    SafeRelease(bd.pPipelineState);

    // Free SRV descriptor used by texture
    font_tex := &bd.FontTexture;
    bd.InitInfo.SrvDescriptorFreeFn(&bd.InitInfo, font_tex.hFontSrvCpuDescHandle, font_tex.hFontSrvGpuDescHandle);
    SafeRelease(font_tex.pTextureResource);
    io.Fonts.SetTexID(0); // We copied bd.hFontSrvGpuDescHandle to io.Fonts.TexID so let's clear that as well.
}

ImGui_ImplDX12_Init :: proc(init_info : ^ImGui_ImplDX12_InitInfo) -> bool
{
    io := GetIO();
    IMGUI_CHECKVERSION();
    assert(io.BackendRendererUserData == nullptr, "Already initialized a renderer backend!");

    // Setup backend capabilities flags
    bd := IM_NEW(ImGui_ImplDX12_Data)();
    bd.InitInfo = *init_info; // Deep copy
    init_info = &bd.InitInfo;

    bd.pd3dDevice = init_info.Device;
    bd.RTVFormat = init_info.RTVFormat;
    bd.DSVFormat = init_info.DSVFormat;
    bd.numFramesInFlight = init_info.NumFramesInFlight;
    bd.pd3dSrvDescHeap = init_info.SrvDescriptorHeap;

    io.BackendRendererUserData = cast(rawptr) bd;
    io.BackendRendererName = "imgui_impl_dx12";
    io.BackendFlags |= ImGuiBackendFlags_RendererHasVtxOffset;  // We can honor the ImDrawCmd::VtxOffset field, allowing for large meshes.
    io.BackendFlags |= ImGuiBackendFlags_RendererHasViewports;  // We can create multi-viewports on the Renderer side (optional)
    if (.ViewportsEnable in io.ConfigFlags)
        ImGui_ImplDX12_InitPlatformInterface();

    // Create a dummy ImGui_ImplDX12_ViewportData holder for the main viewport,
    // Since this is created and managed by the application, we will only use the ->Resources[] fields.
    main_viewport := GetMainViewport();
    main_viewport.RendererUserData = IM_NEW(ImGui_ImplDX12_ViewportData)(bd.numFramesInFlight);


    // Allocate 1 SRV descriptor for the font texture
    assert(init_info.SrvDescriptorAllocFn != nullptr && init_info.SrvDescriptorFreeFn != nullptr);
    init_info.SrvDescriptorAllocFn(&bd.InitInfo, &bd.FontTexture.hFontSrvCpuDescHandle, &bd.FontTexture.hFontSrvGpuDescHandle);

    return true;
}


ImGui_ImplDX12_Shutdown :: proc()
{
    bd := ImGui_ImplDX12_GetBackendData();
    assert(bd != nullptr, "No renderer backend to shutdown, or already shutdown?");
    io := GetIO();

    // Manually delete main viewport render resources in-case we haven't initialized for viewports
    main_viewport := GetMainViewport();
    if (ImGui_ImplDX12_ViewportData* vd = (ImGui_ImplDX12_ViewportData*)main_viewport.RendererUserData)
    {
        // We could just call ImGui_ImplDX12_DestroyWindow(main_viewport) as a convenience but that would be misleading since we only use data.Resources[]
        for UINT i = 0; i < bd.numFramesInFlight; i += 1
            ImGui_ImplDX12_DestroyRenderBuffers(&vd.FrameRenderBuffers[i]);
        IM_DELETE(vd);
        main_viewport.RendererUserData = nullptr;
    }

    // Clean up windows and device objects
    ImGui_ImplDX12_ShutdownPlatformInterface();
    ImGui_ImplDX12_InvalidateDeviceObjects();

    io.BackendRendererName = nullptr;
    io.BackendRendererUserData = nullptr;
    io.BackendFlags &= ~(ImGuiBackendFlags_RendererHasVtxOffset | ImGuiBackendFlags_RendererHasViewports);
    IM_DELETE(bd);
}

ImGui_ImplDX12_NewFrame :: proc()
{
    bd := ImGui_ImplDX12_GetBackendData();
    assert(bd != nullptr, "Context or backend not initialized! Did you call ImGui_ImplDX12_Init()?");

    if (!bd.pPipelineState)
        ImGui_ImplDX12_CreateDeviceObjects();
}

//--------------------------------------------------------------------------------------------------------
// MULTI-VIEWPORT / PLATFORM INTERFACE SUPPORT
// This is an _advanced_ and _optional_ feature, allowing the backend to create and handle multiple viewports simultaneously.
// If you are new to dear imgui or creating a new binding for dear imgui, it is recommended that you completely ignore this section first..
//--------------------------------------------------------------------------------------------------------

ImGui_ImplDX12_CreateWindow :: proc(viewport : ^ImGuiViewport)
{
    bd := ImGui_ImplDX12_GetBackendData();
    vd := IM_NEW(ImGui_ImplDX12_ViewportData)(bd.numFramesInFlight);
    viewport.RendererUserData = vd;

    // PlatformHandleRaw should always be a HWND, whereas PlatformHandle might be a higher-level handle (e.g. GLFWWindow*, SDL_Window*).
    // Some backends will leave PlatformHandleRaw == 0, in which case we assume PlatformHandle will contain the HWND.
    hwnd := viewport.PlatformHandleRaw ? (HWND)viewport.PlatformHandleRaw : (HWND)viewport.PlatformHandle;
    assert(hwnd != 0);

    vd.FrameIndex = UINT_MAX;

    // Create command queue.
    queue_desc := {};
    queue_desc.Flags = D3D12_COMMAND_QUEUE_FLAG_NONE;
    queue_desc.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;

    res := S_OK;
    res = bd.pd3dDevice.CreateCommandQueue(&queue_desc, IID_PPV_ARGS(&vd.CommandQueue));
    assert(res == S_OK);

    // Create command allocator.
    for UINT i = 0; i < bd.numFramesInFlight; ++i
    {
        res = bd.pd3dDevice.CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&vd.FrameCtx[i].CommandAllocator));
        assert(res == S_OK);
    }

    // Create command list.
    res = bd.pd3dDevice.CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, vd.FrameCtx[0].CommandAllocator, nullptr, IID_PPV_ARGS(&vd.CommandList));
    assert(res == S_OK);
    vd.CommandList.Close();

    // Create fence.
    res = bd.pd3dDevice.CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&vd.Fence));
    assert(res == S_OK);

    vd.FenceEvent = CreateEvent(nullptr, FALSE, FALSE, nullptr);
    assert(vd.FenceEvent != nullptr);

    // Create swap chain
    // FIXME-VIEWPORT: May want to copy/inherit swap chain settings from the user/application.
    sd1 : DXGI_SWAP_CHAIN_DESC1
    ZeroMemory(&sd1, size_of(sd1));
    sd1.BufferCount = bd.numFramesInFlight;
    sd1.Width = (UINT)viewport.Size.x;
    sd1.Height = (UINT)viewport.Size.y;
    sd1.Format = bd.RTVFormat;
    sd1.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd1.SampleDesc.Count = 1;
    sd1.SampleDesc.Quality = 0;
    sd1.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
    sd1.AlphaMode = DXGI_ALPHA_MODE_UNSPECIFIED;
    sd1.Scaling = DXGI_SCALING_NONE;
    sd1.Stereo = FALSE;

    dxgi_factory := nullptr;
    res = ::CreateDXGIFactory1(IID_PPV_ARGS(&dxgi_factory));
    assert(res == S_OK);

    swap_chain := nullptr;
    res = dxgi_factory.CreateSwapChainForHwnd(vd.CommandQueue, hwnd, &sd1, nullptr, nullptr, &swap_chain);
    assert(res == S_OK);

    dxgi_factory.Release();

    // Or swapChain.As(&mSwapChain)
    assert(vd.SwapChain == nullptr);
    swap_chain.QueryInterface(IID_PPV_ARGS(&vd.SwapChain));
    swap_chain.Release();

    // Create the render targets
    if (vd.SwapChain)
    {
        desc := {};
        desc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_RTV;
        desc.NumDescriptors = bd.numFramesInFlight;
        desc.Flags = D3D12_DESCRIPTOR_HEAP_FLAG_NONE;
        desc.NodeMask = 1;

        hr := bd.pd3dDevice.CreateDescriptorHeap(&desc, IID_PPV_ARGS(&vd.RtvDescHeap));
        assert(hr == S_OK);

        rtv_descriptor_size := bd.pd3dDevice.GetDescriptorHandleIncrementSize(D3D12_DESCRIPTOR_HEAP_TYPE_RTV);
        rtv_handle := vd.RtvDescHeap.GetCPUDescriptorHandleForHeapStart();
        for UINT i = 0; i < bd.numFramesInFlight; i += 1
        {
            vd.FrameCtx[i].RenderTargetCpuDescriptors = rtv_handle;
            rtv_handle.ptr += rtv_descriptor_size;
        }

        back_buffer : ^ID3D12Resource
        for UINT i = 0; i < bd.numFramesInFlight; i += 1
        {
            assert(vd.FrameCtx[i].RenderTarget == nullptr);
            vd.SwapChain.GetBuffer(i, IID_PPV_ARGS(&back_buffer));
            bd.pd3dDevice.CreateRenderTargetView(back_buffer, nullptr, vd.FrameCtx[i].RenderTargetCpuDescriptors);
            vd.FrameCtx[i].RenderTarget = back_buffer;
        }
    }

    for UINT i = 0; i < bd.numFramesInFlight; i += 1
        ImGui_ImplDX12_DestroyRenderBuffers(&vd.FrameRenderBuffers[i]);
}

ImGui_WaitForPendingOperations :: proc(vd : ^ImGui_ImplDX12_ViewportData)
{
    hr := S_FALSE;
    if (vd && vd.CommandQueue && vd.Fence && vd.FenceEvent)
    {
        hr = vd.CommandQueue.Signal(vd.Fence, ++vd.FenceSignaledValue);
        assert(hr == S_OK);
        ::WaitForSingleObject(vd.FenceEvent, 0); // Reset any forgotten waits
        hr = vd.Fence.SetEventOnCompletion(vd.FenceSignaledValue, vd.FenceEvent);
        assert(hr == S_OK);
        ::WaitForSingleObject(vd.FenceEvent, INFINITE);
    }
}

ImGui_ImplDX12_DestroyWindow :: proc(viewport : ^ImGuiViewport)
{
    // The main viewport (owned by the application) will always have RendererUserData == 0 since we didn't create the data for it.
    bd := ImGui_ImplDX12_GetBackendData();
    if (ImGui_ImplDX12_ViewportData* vd = (ImGui_ImplDX12_ViewportData*)viewport.RendererUserData)
    {
        ImGui_WaitForPendingOperations(vd);

        SafeRelease(vd.CommandQueue);
        SafeRelease(vd.CommandList);
        SafeRelease(vd.SwapChain);
        SafeRelease(vd.RtvDescHeap);
        SafeRelease(vd.Fence);
        ::CloseHandle(vd.FenceEvent);
        vd.FenceEvent = nullptr;

        for UINT i = 0; i < bd.numFramesInFlight; i += 1
        {
            SafeRelease(vd.FrameCtx[i].RenderTarget);
            SafeRelease(vd.FrameCtx[i].CommandAllocator);
            ImGui_ImplDX12_DestroyRenderBuffers(&vd.FrameRenderBuffers[i]);
        }
        IM_DELETE(vd);
    }
    viewport.RendererUserData = nullptr;
}

ImGui_ImplDX12_SetWindowSize :: proc(viewport : ^ImGuiViewport, size : ImVec2)
{
    bd := ImGui_ImplDX12_GetBackendData();
    vd := (ImGui_ImplDX12_ViewportData*)viewport.RendererUserData;

    ImGui_WaitForPendingOperations(vd);

    for UINT i = 0; i < bd.numFramesInFlight; i += 1
        SafeRelease(vd.FrameCtx[i].RenderTarget);

    if (vd.SwapChain)
    {
        back_buffer := nullptr;
        vd.SwapChain.ResizeBuffers(0, (UINT)size.x, (UINT)size.y, DXGI_FORMAT_UNKNOWN, 0);
        for UINT i = 0; i < bd.numFramesInFlight; i += 1
        {
            vd.SwapChain.GetBuffer(i, IID_PPV_ARGS(&back_buffer));
            bd.pd3dDevice.CreateRenderTargetView(back_buffer, nullptr, vd.FrameCtx[i].RenderTargetCpuDescriptors);
            vd.FrameCtx[i].RenderTarget = back_buffer;
        }
    }
}

ImGui_ImplDX12_RenderWindow :: proc(viewport : ^ImGuiViewport, rawptr)
{
    bd := ImGui_ImplDX12_GetBackendData();
    vd := (ImGui_ImplDX12_ViewportData*)viewport.RendererUserData;

    frame_context := &vd.FrameCtx[vd.FrameIndex % bd.numFramesInFlight];
    back_buffer_idx := vd.SwapChain.GetCurrentBackBufferIndex();

    clear_color := ImVec4{0.0, 0.0, 0.0, 1.0};
    barrier := {};
    barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
    barrier.Flags = D3D12_RESOURCE_BARRIER_FLAG_NONE;
    barrier.Transition.pResource = vd.FrameCtx[back_buffer_idx].RenderTarget;
    barrier.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
    barrier.Transition.StateBefore = D3D12_RESOURCE_STATE_PRESENT;
    barrier.Transition.StateAfter = D3D12_RESOURCE_STATE_RENDER_TARGET;

    // Draw
    cmd_list := vd.CommandList;

    frame_context.CommandAllocator.Reset();
    cmd_list.Reset(frame_context.CommandAllocator, nullptr);
    cmd_list.ResourceBarrier(1, &barrier);
    cmd_list.OMSetRenderTargets(1, &vd.FrameCtx[back_buffer_idx].RenderTargetCpuDescriptors, FALSE, nullptr);
    if (!(.NoRendererClear in viewport.Flags)) {
        cmd_list.ClearRenderTargetView(vd.FrameCtx[back_buffer_idx].RenderTargetCpuDescriptors, (float*)&clear_color, 0, nullptr);
    }

    cmd_list.SetDescriptorHeaps(1, &bd.pd3dSrvDescHeap);

    ImGui_ImplDX12_RenderDrawData(viewport.DrawData, cmd_list);

    barrier.Transition.StateBefore = D3D12_RESOURCE_STATE_RENDER_TARGET;
    barrier.Transition.StateAfter = D3D12_RESOURCE_STATE_PRESENT;
    cmd_list.ResourceBarrier(1, &barrier);
    cmd_list.Close();

    vd.CommandQueue.Wait(vd.Fence, vd.FenceSignaledValue);
    vd.CommandQueue.ExecuteCommandLists(1, (ID3D12CommandList* const*)&cmd_list);
    vd.CommandQueue.Signal(vd.Fence, ++vd.FenceSignaledValue);
}

ImGui_ImplDX12_SwapBuffers :: proc(viewport : ^ImGuiViewport, rawptr)
{
    vd := (ImGui_ImplDX12_ViewportData*)viewport.RendererUserData;

    vd.SwapChain.Present(0, 0);
    for (vd.Fence.GetCompletedValue() < vd.FenceSignaledValue)
        ::SwitchToThread();
}

ImGui_ImplDX12_InitPlatformInterface :: proc()
{
    platform_io := &GetPlatformIO();
    platform_io.Renderer_CreateWindow = ImGui_ImplDX12_CreateWindow;
    platform_io.Renderer_DestroyWindow = ImGui_ImplDX12_DestroyWindow;
    platform_io.Renderer_SetWindowSize = ImGui_ImplDX12_SetWindowSize;
    platform_io.Renderer_RenderWindow = ImGui_ImplDX12_RenderWindow;
    platform_io.Renderer_SwapBuffers = ImGui_ImplDX12_SwapBuffers;
}

ImGui_ImplDX12_ShutdownPlatformInterface :: proc()
{
    DestroyPlatformWindows();
}

//-----------------------------------------------------------------------------

} // #ifndef IMGUI_DISABLE
