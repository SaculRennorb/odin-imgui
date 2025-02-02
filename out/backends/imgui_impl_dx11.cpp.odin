package imgui

// dear imgui: Renderer Backend for DirectX11
// This needs to be used along with a Platform Backend (e.g. Win32)

// Implemented features:
//  [X] Renderer: User texture binding. Use 'ID3D11ShaderResourceView*' as ImTextureID. Read the FAQ about ImTextureID!
//  [X] Renderer: Large meshes support (64k+ vertices) even with 16-bit indices (ImGuiBackendFlags_RendererHasVtxOffset).
//  [X] Renderer: Expose selected render state for draw callbacks to use. Access in '(ImGui_ImplXXXX_RenderState*)GetPlatformIO().Renderer_RenderState'.
//  [X] Renderer: Multi-viewport support (multiple windows). Enable with 'io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable'.

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
//  2025-01-06: DirectX11: Expose VertexConstantBuffer in ImGui_ImplDX11_RenderState. Reset projection matrix in ImDrawCallback_ResetRenderState handler.
//  2024-10-07: DirectX11: Changed default texture sampler to Clamp instead of Repeat/Wrap.
//  2024-10-07: DirectX11: Expose selected render state in ImGui_ImplDX11_RenderState, which you can access in 'void* platform_io.Renderer_RenderState' during draw callbacks.
//  2022-10-11: Using 'nullptr' instead of 'NULL' as per our switch to C++11.
//  2021-06-29: Reorganized backend to pull data from a single structure to facilitate usage with multiple-contexts (all g_XXXX access changed to bd->XXXX).
//  2021-05-19: DirectX11: Replaced direct access to ImDrawCmd::TextureId with a call to ImDrawCmd::GetTexID(). (will become a requirement)
//  2021-02-18: DirectX11: Change blending equation to preserve alpha in output buffer.
//  2019-08-01: DirectX11: Fixed code querying the Geometry Shader state (would generally error with Debug layer enabled).
//  2019-07-21: DirectX11: Backup, clear and restore Geometry Shader is any is bound when calling ImGui_ImplDX11_RenderDrawData. Clearing Hull/Domain/Compute shaders without backup/restore.
//  2019-05-29: DirectX11: Added support for large mesh (64K+ vertices), enable ImGuiBackendFlags_RendererHasVtxOffset flag.
//  2019-04-30: DirectX11: Added support for special ImDrawCallback_ResetRenderState callback to reset render state.
//  2018-12-03: Misc: Added #pragma comment statement to automatically link with d3dcompiler.lib when using D3DCompile().
//  2018-11-30: Misc: Setting up io.BackendRendererName so it can be displayed in the About Window.
//  2018-08-01: DirectX11: Querying for IDXGIFactory instead of IDXGIFactory1 to increase compatibility.
//  2018-07-13: DirectX11: Fixed unreleased resources in Init and Shutdown functions.
//  2018-06-08: Misc: Extracted imgui_impl_dx11.cpp/.h away from the old combined DX11+Win32 example.
//  2018-06-08: DirectX11: Use draw_data->DisplayPos and draw_data->DisplaySize to setup projection matrix and clipping rectangle.
//  2018-02-16: Misc: Obsoleted the io.RenderDrawListsFn callback and exposed ImGui_ImplDX11_RenderDrawData() in the .h file so you can call it yourself.
//  2018-02-06: Misc: Removed call to ImGui::Shutdown() which is not available from 1.60 WIP, user needs to call CreateContext/DestroyContext themselves.
//  2016-05-07: DirectX11: Disabling depth-write.

when !(IMGUI_DISABLE) {

// DirectX
when _MSC_VER {
#pragma comment(lib, "d3dcompiler") // Automatically link with d3dcompiler.lib as we are using D3DCompile() below.
}

// DirectX11 data
ImGui_ImplDX11_Data :: struct
{
    pd3dDevice : ^ID3D11Device,
    pd3dDeviceContext : ^ID3D11DeviceContext,
    pFactory : ^IDXGIFactory,
    pVB : ^ID3D11Buffer,
    pIB : ^ID3D11Buffer,
    pVertexShader : ^ID3D11VertexShader,
    pInputLayout : ^ID3D11InputLayout,
    pVertexConstantBuffer : ^ID3D11Buffer,
    pPixelShader : ^ID3D11PixelShader,
    pFontSampler : ^ID3D11SamplerState,
    pFontTextureView : ^ID3D11ShaderResourceView,
    pRasterizerState : ^ID3D11RasterizerState,
    pBlendState : ^ID3D11BlendState,
    pDepthStencilState : ^ID3D11DepthStencilState,
    VertexBufferSize : i32,
    IndexBufferSize : i32,

    ImGui_ImplDX11_Data()       { memset((rawptr)this, 0, size_of(*this)); VertexBufferSize = 5000; IndexBufferSize = 10000; }
};

VERTEX_CONSTANT_BUFFER_DX11 :: struct
{
    mvp : [4][4]f32,
};

// Backend data stored in io.BackendRendererUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
ImGui_ImplDX11_GetBackendData :: proc() -> ^ImGui_ImplDX11_Data
{
    return GetCurrentContext() ? (ImGui_ImplDX11_Data*)GetIO().BackendRendererUserData : nullptr;
}

// Forward Declarations
void ImGui_ImplDX11_InitMultiViewportSupport();
void ImGui_ImplDX11_ShutdownMultiViewportSupport();

// Functions
ImGui_ImplDX11_SetupRenderState :: proc(draw_data : ^ImDrawData, device_ctx : ^ID3D11DeviceContext)
{
    bd := ImGui_ImplDX11_GetBackendData();

    // Setup viewport
    vp : D3D11_VIEWPORT
    memset(&vp, 0, size_of(D3D11_VIEWPORT));
    vp.Width = draw_data.DisplaySize.x;
    vp.Height = draw_data.DisplaySize.y;
    vp.MinDepth = 0.0;
    vp.MaxDepth = 1.0;
    vp.TopLeftX = vp.TopLeftY = 0;
    device_ctx.RSSetViewports(1, &vp);

    // Setup orthographic projection matrix into our constant buffer
    // Our visible imgui space lies from draw_data->DisplayPos (top left) to draw_data->DisplayPos+data_data->DisplaySize (bottom right). DisplayPos is (0,0) for single viewport apps.
    mapped_resource : D3D11_MAPPED_SUBRESOURCE
    if (device_ctx.Map(bd.pVertexConstantBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, &mapped_resource) == S_OK)
    {
        constant_buffer := (VERTEX_CONSTANT_BUFFER_DX11*)mapped_resource.pData;
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
        memcpy(&constant_buffer.mvp, mvp, size_of(mvp));
        device_ctx.Unmap(bd.pVertexConstantBuffer, 0);
    }

    // Setup shader and vertex buffers
    stride := size_of(ImDrawVert);
    offset := 0;
    device_ctx.IASetInputLayout(bd.pInputLayout);
    device_ctx.IASetVertexBuffers(0, 1, &bd.pVB, &stride, &offset);
    device_ctx.IASetIndexBuffer(bd.pIB, size_of(ImDrawIdx) == 2 ? DXGI_FORMAT_R16_UINT : DXGI_FORMAT_R32_UINT, 0);
    device_ctx.IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    device_ctx.VSSetShader(bd.pVertexShader, nullptr, 0);
    device_ctx.VSSetConstantBuffers(0, 1, &bd.pVertexConstantBuffer);
    device_ctx.PSSetShader(bd.pPixelShader, nullptr, 0);
    device_ctx.PSSetSamplers(0, 1, &bd.pFontSampler);
    device_ctx.GSSetShader(nullptr, nullptr, 0);
    device_ctx.HSSetShader(nullptr, nullptr, 0); // In theory we should backup and restore this as well.. very infrequently used..
    device_ctx.DSSetShader(nullptr, nullptr, 0); // In theory we should backup and restore this as well.. very infrequently used..
    device_ctx.CSSetShader(nullptr, nullptr, 0); // In theory we should backup and restore this as well.. very infrequently used..

    // Setup render state
    const f32 blend_factor[4] = { 0.f, 0.f, 0.f, 0.f };
    device_ctx.OMSetBlendState(bd.pBlendState, blend_factor, 0xffffffff);
    device_ctx.OMSetDepthStencilState(bd.pDepthStencilState, 0);
    device_ctx.RSSetState(bd.pRasterizerState);
}

// Render function
ImGui_ImplDX11_RenderDrawData :: proc(draw_data : ^ImDrawData)
{
    // Avoid rendering when minimized
    if (draw_data.DisplaySize.x <= 0.0 || draw_data.DisplaySize.y <= 0.0)
        return;

    bd := ImGui_ImplDX11_GetBackendData();
    device := bd.pd3dDeviceContext;

    // Create and grow vertex/index buffers if needed
    if (!bd.pVB || bd.VertexBufferSize < draw_data.TotalVtxCount)
    {
        if (bd.pVB) { bd.pVB->Release(); bd.pVB = nullptr; }
        bd.VertexBufferSize = draw_data.TotalVtxCount + 5000;
        desc : D3D11_BUFFER_DESC
        memset(&desc, 0, size_of(D3D11_BUFFER_DESC));
        desc.Usage = D3D11_USAGE_DYNAMIC;
        desc.ByteWidth = bd.VertexBufferSize * size_of(ImDrawVert);
        desc.BindFlags = D3D11_BIND_VERTEX_BUFFER;
        desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
        desc.MiscFlags = 0;
        if (bd.pd3dDevice->CreateBuffer(&desc, nullptr, &bd.pVB) < 0)
            return;
    }
    if (!bd.pIB || bd.IndexBufferSize < draw_data.TotalIdxCount)
    {
        if (bd.pIB) { bd.pIB->Release(); bd.pIB = nullptr; }
        bd.IndexBufferSize = draw_data.TotalIdxCount + 10000;
        desc : D3D11_BUFFER_DESC
        memset(&desc, 0, size_of(D3D11_BUFFER_DESC));
        desc.Usage = D3D11_USAGE_DYNAMIC;
        desc.ByteWidth = bd.IndexBufferSize * size_of(ImDrawIdx);
        desc.BindFlags = D3D11_BIND_INDEX_BUFFER;
        desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
        if (bd.pd3dDevice->CreateBuffer(&desc, nullptr, &bd.pIB) < 0)
            return;
    }

    // Upload vertex/index data into a single contiguous GPU buffer
    vtx_resource, idx_resource : D3D11_MAPPED_SUBRESOURCE
    if (device.Map(bd.pVB, 0, D3D11_MAP_WRITE_DISCARD, 0, &vtx_resource) != S_OK)
        return;
    if (device.Map(bd.pIB, 0, D3D11_MAP_WRITE_DISCARD, 0, &idx_resource) != S_OK)
        return;
    vtx_dst := (ImDrawVert*)vtx_resource.pData;
    idx_dst := (ImDrawIdx*)idx_resource.pData;
    for i32 n = 0; n < draw_data.CmdListsCount; n++
    {
        draw_list := draw_data.CmdLists[n];
        memcpy(vtx_dst, draw_list.VtxBuffer.Data, draw_list.VtxBuffer.Size * size_of(ImDrawVert));
        memcpy(idx_dst, draw_list.IdxBuffer.Data, draw_list.IdxBuffer.Size * size_of(ImDrawIdx));
        vtx_dst += draw_list.VtxBuffer.Size;
        idx_dst += draw_list.IdxBuffer.Size;
    }
    device.Unmap(bd.pVB, 0);
    device.Unmap(bd.pIB, 0);

    // Backup DX state that will be modified to restore it afterwards (unfortunately this is very ugly looking and verbose. Close your eyes!)
    BACKUP_DX11_STATE :: struct
    {
        ScissorRectsCount, ViewportsCount : UINT,
        ScissorRects : [D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE]D3D11_RECT,
        Viewports : [D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE]D3D11_VIEWPORT,
        RS : ^ID3D11RasterizerState,
        BlendState : ^ID3D11BlendState,
        BlendFactor : [4]FLOAT,
        SampleMask : UINT,
        StencilRef : UINT,
        DepthStencilState : ^ID3D11DepthStencilState,
        PSShaderResource : ^ID3D11ShaderResourceView,
        PSSampler : ^ID3D11SamplerState,
        PS : ^ID3D11PixelShader,
        VS : ^ID3D11VertexShader,
        GS : ^ID3D11GeometryShader,
        PSInstancesCount, VSInstancesCount, GSInstancesCount : UINT,
        ID3D11ClassInstance         *PSInstances[256], *VSInstances[256], *GSInstances[256];   // 256 is max according to PSSetShader documentation
        PrimitiveTopology : D3D11_PRIMITIVE_TOPOLOGY,
        ID3D11Buffer*               IndexBuffer, *VertexBuffer, *VSConstantBuffer;
        IndexBufferOffset, VertexBufferStride, VertexBufferOffset : UINT,
        IndexBufferFormat : DXGI_FORMAT,
        InputLayout : ^ID3D11InputLayout,
    };
    old := {};
    old.ScissorRectsCount = old.ViewportsCount = D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE;
    device.RSGetScissorRects(&old.ScissorRectsCount, old.ScissorRects);
    device.RSGetViewports(&old.ViewportsCount, old.Viewports);
    device.RSGetState(&old.RS);
    device.OMGetBlendState(&old.BlendState, old.BlendFactor, &old.SampleMask);
    device.OMGetDepthStencilState(&old.DepthStencilState, &old.StencilRef);
    device.PSGetShaderResources(0, 1, &old.PSShaderResource);
    device.PSGetSamplers(0, 1, &old.PSSampler);
    old.PSInstancesCount = old.VSInstancesCount = old.GSInstancesCount = 256;
    device.PSGetShader(&old.PS, old.PSInstances, &old.PSInstancesCount);
    device.VSGetShader(&old.VS, old.VSInstances, &old.VSInstancesCount);
    device.VSGetConstantBuffers(0, 1, &old.VSConstantBuffer);
    device.GSGetShader(&old.GS, old.GSInstances, &old.GSInstancesCount);

    device.IAGetPrimitiveTopology(&old.PrimitiveTopology);
    device.IAGetIndexBuffer(&old.IndexBuffer, &old.IndexBufferFormat, &old.IndexBufferOffset);
    device.IAGetVertexBuffers(0, 1, &old.VertexBuffer, &old.VertexBufferStride, &old.VertexBufferOffset);
    device.IAGetInputLayout(&old.InputLayout);

    // Setup desired DX state
    ImGui_ImplDX11_SetupRenderState(draw_data, device);

    // Setup render state structure (for callbacks and custom texture bindings)
    ImGuiPlatformIO& platform_io = GetPlatformIO();
    render_state : ImGui_ImplDX11_RenderState
    render_state.Device = bd.pd3dDevice;
    render_state.DeviceContext = bd.pd3dDeviceContext;
    render_state.SamplerDefault = bd.pFontSampler;
    render_state.VertexConstantBuffer = bd.pVertexConstantBuffer;
    platform_io.Renderer_RenderState = &render_state;

    // Render command lists
    // (Because we merged all buffers into a single one, we maintain our own offset into them)
    global_idx_offset := 0;
    global_vtx_offset := 0;
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
                    ImGui_ImplDX11_SetupRenderState(draw_data, device);
                else
                    pcmd.UserCallback(draw_list, pcmd);
            }
            else
            {
                // Project scissor/clipping rectangles into framebuffer space
                clip_min := ImVec2{pcmd.ClipRect.x - clip_off.x, pcmd.ClipRect.y - clip_off.y};
                clip_max := ImVec2{pcmd.ClipRect.z - clip_off.x, pcmd.ClipRect.w - clip_off.y};
                if (clip_max.x <= clip_min.x || clip_max.y <= clip_min.y)
                    continue;

                // Apply scissor/clipping rectangle
                r := { (LONG)clip_min.x, (LONG)clip_min.y, (LONG)clip_max.x, (LONG)clip_max.y };
                device.RSSetScissorRects(1, &r);

                // Bind texture, Draw
                texture_srv := (ID3D11ShaderResourceView*)pcmd.GetTexID();
                device.PSSetShaderResources(0, 1, &texture_srv);
                device.DrawIndexed(pcmd.ElemCount, pcmd.IdxOffset + global_idx_offset, pcmd.VtxOffset + global_vtx_offset);
            }
        }
        global_idx_offset += draw_list.IdxBuffer.Size;
        global_vtx_offset += draw_list.VtxBuffer.Size;
    }
    platform_io.Renderer_RenderState = nullptr;

    // Restore modified DX state
    device.RSSetScissorRects(old.ScissorRectsCount, old.ScissorRects);
    device.RSSetViewports(old.ViewportsCount, old.Viewports);
    device.RSSetState(old.RS); if (old.RS) old.RS.Release();
    device.OMSetBlendState(old.BlendState, old.BlendFactor, old.SampleMask); if (old.BlendState) old.BlendState.Release();
    device.OMSetDepthStencilState(old.DepthStencilState, old.StencilRef); if (old.DepthStencilState) old.DepthStencilState.Release();
    device.PSSetShaderResources(0, 1, &old.PSShaderResource); if (old.PSShaderResource) old.PSShaderResource.Release();
    device.PSSetSamplers(0, 1, &old.PSSampler); if (old.PSSampler) old.PSSampler.Release();
    device.PSSetShader(old.PS, old.PSInstances, old.PSInstancesCount); if (old.PS) old.PS.Release();
    for (UINT i = 0; i < old.PSInstancesCount; i++) if (old.PSInstances[i]) old.PSInstances[i]->Release();
    device.VSSetShader(old.VS, old.VSInstances, old.VSInstancesCount); if (old.VS) old.VS.Release();
    device.VSSetConstantBuffers(0, 1, &old.VSConstantBuffer); if (old.VSConstantBuffer) old.VSConstantBuffer.Release();
    device.GSSetShader(old.GS, old.GSInstances, old.GSInstancesCount); if (old.GS) old.GS.Release();
    for (UINT i = 0; i < old.VSInstancesCount; i++) if (old.VSInstances[i]) old.VSInstances[i]->Release();
    device.IASetPrimitiveTopology(old.PrimitiveTopology);
    device.IASetIndexBuffer(old.IndexBuffer, old.IndexBufferFormat, old.IndexBufferOffset); if (old.IndexBuffer) old.IndexBuffer.Release();
    device.IASetVertexBuffers(0, 1, &old.VertexBuffer, &old.VertexBufferStride, &old.VertexBufferOffset); if (old.VertexBuffer) old.VertexBuffer.Release();
    device.IASetInputLayout(old.InputLayout); if (old.InputLayout) old.InputLayout.Release();
}

ImGui_ImplDX11_CreateFontsTexture :: proc()
{
    // Build texture atlas
    ImGuiIO& io = GetIO();
    bd := ImGui_ImplDX11_GetBackendData();
    pixels : ^u8
    width, height : i32
    io.Fonts.GetTexDataAsRGBA32(&pixels, &width, &height);

    // Upload texture to graphics system
    {
        desc : D3D11_TEXTURE2D_DESC
        ZeroMemory(&desc, size_of(desc));
        desc.Width = width;
        desc.Height = height;
        desc.MipLevels = 1;
        desc.ArraySize = 1;
        desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
        desc.SampleDesc.Count = 1;
        desc.Usage = D3D11_USAGE_DEFAULT;
        desc.BindFlags = D3D11_BIND_SHADER_RESOURCE;
        desc.CPUAccessFlags = 0;

        pTexture := nullptr;
        subResource : D3D11_SUBRESOURCE_DATA
        subResource.pSysMem = pixels;
        subResource.SysMemPitch = desc.Width * 4;
        subResource.SysMemSlicePitch = 0;
        bd.pd3dDevice->CreateTexture2D(&desc, &subResource, &pTexture);
        assert(pTexture != nullptr);

        // Create texture view
        srvDesc : D3D11_SHADER_RESOURCE_VIEW_DESC
        ZeroMemory(&srvDesc, size_of(srvDesc));
        srvDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
        srvDesc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;
        srvDesc.Texture2D.MipLevels = desc.MipLevels;
        srvDesc.Texture2D.MostDetailedMip = 0;
        bd.pd3dDevice->CreateShaderResourceView(pTexture, &srvDesc, &bd.pFontTextureView);
        pTexture.Release();
    }

    // Store our identifier
    io.Fonts.SetTexID((ImTextureID)bd.pFontTextureView);
}

ImGui_ImplDX11_DestroyFontsTexture :: proc()
{
    bd := ImGui_ImplDX11_GetBackendData();
    if (bd.pFontTextureView)
    {
        bd.pFontTextureView->Release();
        bd.pFontTextureView = nullptr;
        GetIO().Fonts.SetTexID(0); // We copied data->pFontTextureView to io.Fonts->TexID so let's clear that as well.
    }
}

ImGui_ImplDX11_CreateDeviceObjects :: proc() -> bool
{
    bd := ImGui_ImplDX11_GetBackendData();
    if (!bd.pd3dDevice)
        return false;
    if (bd.pFontSampler)
        ImGui_ImplDX11_InvalidateDeviceObjects();

    // By using D3DCompile() from <d3dcompiler.h> / d3dcompiler.lib, we introduce a dependency to a given version of d3dcompiler_XX.dll (see D3DCOMPILER_DLL_A)
    // If you would like to use this DX11 sample code but remove this dependency you can:
    //  1) compile once, save the compiled shader blobs into a file or source code and pass them to CreateVertexShader()/CreatePixelShader() [preferred solution]
    //  2) use code to detect any version of the DLL and grab a pointer to D3DCompile from the DLL.
    // See https://github.com/ocornut/imgui/pull/638 for sources and details.

    // Create the vertex shader
    {
        static const u8* vertexShader =
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

        vertexShaderBlob : ^ID3DBlob
        if (FAILED(D3DCompile(vertexShader, strlen(vertexShader), nullptr, nullptr, nullptr, "main", "vs_4_0", 0, 0, &vertexShaderBlob, nullptr)))
            return false; // NB: Pass ID3DBlob* pErrorBlob to D3DCompile() to get error showing in (const char*)pErrorBlob->GetBufferPointer(). Make sure to Release() the blob!
        if (bd.pd3dDevice->CreateVertexShader(vertexShaderBlob.GetBufferPointer(), vertexShaderBlob.GetBufferSize(), nullptr, &bd.pVertexShader) != S_OK)
        {
            vertexShaderBlob.Release();
            return false;
        }

        // Create the input layout
        D3D11_INPUT_ELEMENT_DESC local_layout[] =
        {
            { "POSITION", 0, DXGI_FORMAT_R32G32_FLOAT,   0, (UINT)offsetof(ImDrawVert, pos), D3D11_INPUT_PER_VERTEX_DATA, 0 },
            { "TEXCOORD", 0, DXGI_FORMAT_R32G32_FLOAT,   0, (UINT)offsetof(ImDrawVert, uv),  D3D11_INPUT_PER_VERTEX_DATA, 0 },
            { "COLOR",    0, DXGI_FORMAT_R8G8B8A8_UNORM, 0, (UINT)offsetof(ImDrawVert, col), D3D11_INPUT_PER_VERTEX_DATA, 0 },
        };
        if (bd.pd3dDevice->CreateInputLayout(local_layout, 3, vertexShaderBlob.GetBufferPointer(), vertexShaderBlob.GetBufferSize(), &bd.pInputLayout) != S_OK)
        {
            vertexShaderBlob.Release();
            return false;
        }
        vertexShaderBlob.Release();

        // Create the constant buffer
        {
            desc : D3D11_BUFFER_DESC
            desc.ByteWidth = size_of(VERTEX_CONSTANT_BUFFER_DX11);
            desc.Usage = D3D11_USAGE_DYNAMIC;
            desc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
            desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
            desc.MiscFlags = 0;
            bd.pd3dDevice->CreateBuffer(&desc, nullptr, &bd.pVertexConstantBuffer);
        }
    }

    // Create the pixel shader
    {
        static const u8* pixelShader =
            "struct PS_INPUT\
            {\
            float4 pos : SV_POSITION;\
            float4 col : COLOR0;\
            float2 uv  : TEXCOORD0;\
            };\
            sampler0 : sampler
            texture0 : Texture2D
            \
            float4 main(PS_INPUT input) : SV_Target\
            {\
            out_col := input.col * texture0.Sample(sampler0, input.uv); \
            return out_col; \
            }";

        pixelShaderBlob : ^ID3DBlob
        if (FAILED(D3DCompile(pixelShader, strlen(pixelShader), nullptr, nullptr, nullptr, "main", "ps_4_0", 0, 0, &pixelShaderBlob, nullptr)))
            return false; // NB: Pass ID3DBlob* pErrorBlob to D3DCompile() to get error showing in (const char*)pErrorBlob->GetBufferPointer(). Make sure to Release() the blob!
        if (bd.pd3dDevice->CreatePixelShader(pixelShaderBlob.GetBufferPointer(), pixelShaderBlob.GetBufferSize(), nullptr, &bd.pPixelShader) != S_OK)
        {
            pixelShaderBlob.Release();
            return false;
        }
        pixelShaderBlob.Release();
    }

    // Create the blending setup
    {
        desc : D3D11_BLEND_DESC
        ZeroMemory(&desc, size_of(desc));
        desc.AlphaToCoverageEnable = false;
        desc.RenderTarget[0].BlendEnable = true;
        desc.RenderTarget[0].SrcBlend = D3D11_BLEND_SRC_ALPHA;
        desc.RenderTarget[0].DestBlend = D3D11_BLEND_INV_SRC_ALPHA;
        desc.RenderTarget[0].BlendOp = D3D11_BLEND_OP_ADD;
        desc.RenderTarget[0].SrcBlendAlpha = D3D11_BLEND_ONE;
        desc.RenderTarget[0].DestBlendAlpha = D3D11_BLEND_INV_SRC_ALPHA;
        desc.RenderTarget[0].BlendOpAlpha = D3D11_BLEND_OP_ADD;
        desc.RenderTarget[0].RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALL;
        bd.pd3dDevice->CreateBlendState(&desc, &bd.pBlendState);
    }

    // Create the rasterizer state
    {
        desc : D3D11_RASTERIZER_DESC
        ZeroMemory(&desc, size_of(desc));
        desc.FillMode = D3D11_FILL_SOLID;
        desc.CullMode = D3D11_CULL_NONE;
        desc.ScissorEnable = true;
        desc.DepthClipEnable = true;
        bd.pd3dDevice->CreateRasterizerState(&desc, &bd.pRasterizerState);
    }

    // Create depth-stencil State
    {
        desc : D3D11_DEPTH_STENCIL_DESC
        ZeroMemory(&desc, size_of(desc));
        desc.DepthEnable = false;
        desc.DepthWriteMask = D3D11_DEPTH_WRITE_MASK_ALL;
        desc.DepthFunc = D3D11_COMPARISON_ALWAYS;
        desc.StencilEnable = false;
        desc.FrontFace.StencilFailOp = desc.FrontFace.StencilDepthFailOp = desc.FrontFace.StencilPassOp = D3D11_STENCIL_OP_KEEP;
        desc.FrontFace.StencilFunc = D3D11_COMPARISON_ALWAYS;
        desc.BackFace = desc.FrontFace;
        bd.pd3dDevice->CreateDepthStencilState(&desc, &bd.pDepthStencilState);
    }

    // Create texture sampler
    // (Bilinear sampling is required by default. Set 'io.Fonts->Flags |= ImFontAtlasFlags_NoBakedLines' or 'style.AntiAliasedLinesUseTex = false' to allow point/nearest sampling)
    {
        desc : D3D11_SAMPLER_DESC
        ZeroMemory(&desc, size_of(desc));
        desc.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
        desc.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
        desc.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
        desc.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
        desc.MipLODBias = 0.f;
        desc.ComparisonFunc = D3D11_COMPARISON_ALWAYS;
        desc.MinLOD = 0.f;
        desc.MaxLOD = 0.f;
        bd.pd3dDevice->CreateSamplerState(&desc, &bd.pFontSampler);
    }

    ImGui_ImplDX11_CreateFontsTexture();

    return true;
}

ImGui_ImplDX11_InvalidateDeviceObjects :: proc()
{
    bd := ImGui_ImplDX11_GetBackendData();
    if (!bd.pd3dDevice)
        return;

    ImGui_ImplDX11_DestroyFontsTexture();

    if (bd.pFontSampler)           { bd.pFontSampler->Release(); bd.pFontSampler = nullptr; }
    if (bd.pIB)                    { bd.pIB->Release(); bd.pIB = nullptr; }
    if (bd.pVB)                    { bd.pVB->Release(); bd.pVB = nullptr; }
    if (bd.pBlendState)            { bd.pBlendState->Release(); bd.pBlendState = nullptr; }
    if (bd.pDepthStencilState)     { bd.pDepthStencilState->Release(); bd.pDepthStencilState = nullptr; }
    if (bd.pRasterizerState)       { bd.pRasterizerState->Release(); bd.pRasterizerState = nullptr; }
    if (bd.pPixelShader)           { bd.pPixelShader->Release(); bd.pPixelShader = nullptr; }
    if (bd.pVertexConstantBuffer)  { bd.pVertexConstantBuffer->Release(); bd.pVertexConstantBuffer = nullptr; }
    if (bd.pInputLayout)           { bd.pInputLayout->Release(); bd.pInputLayout = nullptr; }
    if (bd.pVertexShader)          { bd.pVertexShader->Release(); bd.pVertexShader = nullptr; }
}

ImGui_ImplDX11_Init :: proc(device : ^ID3D11Device, device_context : ^ID3D11DeviceContext) -> bool
{
    ImGuiIO& io = GetIO();
    IMGUI_CHECKVERSION();
    assert(io.BackendRendererUserData == nullptr, "Already initialized a renderer backend!");

    // Setup backend capabilities flags
    bd := IM_NEW(ImGui_ImplDX11_Data)();
    io.BackendRendererUserData = (rawptr)bd;
    io.BackendRendererName = "imgui_impl_dx11";
    io.BackendFlags |= ImGuiBackendFlags_RendererHasVtxOffset;  // We can honor the ImDrawCmd::VtxOffset field, allowing for large meshes.
    io.BackendFlags |= ImGuiBackendFlags_RendererHasViewports;  // We can create multi-viewports on the Renderer side (optional)

    // Get factory from device
    pDXGIDevice := nullptr;
    pDXGIAdapter := nullptr;
    pFactory := nullptr;

    if (device.QueryInterface(IID_PPV_ARGS(&pDXGIDevice)) == S_OK)
        if (pDXGIDevice.GetParent(IID_PPV_ARGS(&pDXGIAdapter)) == S_OK)
            if (pDXGIAdapter.GetParent(IID_PPV_ARGS(&pFactory)) == S_OK)
            {
                bd.pd3dDevice = device;
                bd.pd3dDeviceContext = device_context;
                bd.pFactory = pFactory;
            }
    if (pDXGIDevice) pDXGIDevice.Release();
    if (pDXGIAdapter) pDXGIAdapter.Release();
    bd.pd3dDevice->AddRef();
    bd.pd3dDeviceContext->AddRef();

    ImGui_ImplDX11_InitMultiViewportSupport();

    return true;
}

ImGui_ImplDX11_Shutdown :: proc()
{
    bd := ImGui_ImplDX11_GetBackendData();
    assert(bd != nullptr, "No renderer backend to shutdown, or already shutdown?");
    ImGuiIO& io = GetIO();

    ImGui_ImplDX11_ShutdownMultiViewportSupport();
    ImGui_ImplDX11_InvalidateDeviceObjects();
    if (bd.pFactory)             { bd.pFactory->Release(); }
    if (bd.pd3dDevice)           { bd.pd3dDevice->Release(); }
    if (bd.pd3dDeviceContext)    { bd.pd3dDeviceContext->Release(); }
    io.BackendRendererName = nullptr;
    io.BackendRendererUserData = nullptr;
    io.BackendFlags &= ~(ImGuiBackendFlags_RendererHasVtxOffset | ImGuiBackendFlags_RendererHasViewports);
    IM_DELETE(bd);
}

ImGui_ImplDX11_NewFrame :: proc()
{
    bd := ImGui_ImplDX11_GetBackendData();
    assert(bd != nullptr, "Context or backend not initialized! Did you call ImGui_ImplDX11_Init()?");

    if (!bd.pFontSampler)
        ImGui_ImplDX11_CreateDeviceObjects();
}

//--------------------------------------------------------------------------------------------------------
// MULTI-VIEWPORT / PLATFORM INTERFACE SUPPORT
// This is an _advanced_ and _optional_ feature, allowing the backend to create and handle multiple viewports simultaneously.
// If you are new to dear imgui or creating a new binding for dear imgui, it is recommended that you completely ignore this section first..
//--------------------------------------------------------------------------------------------------------

// Helper structure we store in the void* RendererUserData field of each ImGuiViewport to easily retrieve our backend data.
ImGui_ImplDX11_ViewportData :: struct
{
    SwapChain : ^IDXGISwapChain,
    RTView : ^ID3D11RenderTargetView,

    ImGui_ImplDX11_ViewportData()   { SwapChain = nullptr; RTView = nullptr; }
    ~ImGui_ImplDX11_ViewportData()  { assert(SwapChain == nullptr && RTView == nullptr); }
};

ImGui_ImplDX11_CreateWindow :: proc(viewport : ^ImGuiViewport)
{
    bd := ImGui_ImplDX11_GetBackendData();
    vd := IM_NEW(ImGui_ImplDX11_ViewportData)();
    viewport.RendererUserData = vd;

    // PlatformHandleRaw should always be a HWND, whereas PlatformHandle might be a higher-level handle (e.g. GLFWWindow*, SDL_Window*).
    // Some backends will leave PlatformHandleRaw == 0, in which case we assume PlatformHandle will contain the HWND.
    hwnd := viewport.PlatformHandleRaw ? (HWND)viewport.PlatformHandleRaw : (HWND)viewport.PlatformHandle;
    assert(hwnd != 0);

    // Create swap chain
    sd : DXGI_SWAP_CHAIN_DESC
    ZeroMemory(&sd, size_of(sd));
    sd.BufferDesc.Width = (UINT)viewport.Size.x;
    sd.BufferDesc.Height = (UINT)viewport.Size.y;
    sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.SampleDesc.Count = 1;
    sd.SampleDesc.Quality = 0;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.BufferCount = 1;
    sd.OutputWindow = hwnd;
    sd.Windowed = TRUE;
    sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
    sd.Flags = 0;

    assert(vd.SwapChain == nullptr && vd.RTView == nullptr);
    bd.pFactory->CreateSwapChain(bd.pd3dDevice, &sd, &vd.SwapChain);

    // Create the render target
    if (vd.SwapChain)
    {
        pBackBuffer : ^ID3D11Texture2D
        vd.SwapChain->GetBuffer(0, IID_PPV_ARGS(&pBackBuffer));
        bd.pd3dDevice->CreateRenderTargetView(pBackBuffer, nullptr, &vd.RTView);
        pBackBuffer.Release();
    }
}

ImGui_ImplDX11_DestroyWindow :: proc(viewport : ^ImGuiViewport)
{
    // The main viewport (owned by the application) will always have RendererUserData == nullptr since we didn't create the data for it.
    if (ImGui_ImplDX11_ViewportData* vd = (ImGui_ImplDX11_ViewportData*)viewport.RendererUserData)
    {
        if (vd.SwapChain)
            vd.SwapChain->Release();
        vd.SwapChain = nullptr;
        if (vd.RTView)
            vd.RTView->Release();
        vd.RTView = nullptr;
        IM_DELETE(vd);
    }
    viewport.RendererUserData = nullptr;
}

ImGui_ImplDX11_SetWindowSize :: proc(viewport : ^ImGuiViewport, size : ImVec2)
{
    bd := ImGui_ImplDX11_GetBackendData();
    vd := (ImGui_ImplDX11_ViewportData*)viewport.RendererUserData;
    if (vd.RTView)
    {
        vd.RTView->Release();
        vd.RTView = nullptr;
    }
    if (vd.SwapChain)
    {
        pBackBuffer := nullptr;
        vd.SwapChain->ResizeBuffers(0, (UINT)size.x, (UINT)size.y, DXGI_FORMAT_UNKNOWN, 0);
        vd.SwapChain->GetBuffer(0, IID_PPV_ARGS(&pBackBuffer));
        if (pBackBuffer == nullptr) { fprintf(stderr, "ImGui_ImplDX11_SetWindowSize() failed creating buffers.\n"); return; }
        bd.pd3dDevice->CreateRenderTargetView(pBackBuffer, nullptr, &vd.RTView);
        pBackBuffer.Release();
    }
}

ImGui_ImplDX11_RenderWindow :: proc(viewport : ^ImGuiViewport, rawptr)
{
    bd := ImGui_ImplDX11_GetBackendData();
    vd := (ImGui_ImplDX11_ViewportData*)viewport.RendererUserData;
    clear_color := ImVec4{0.0, 0.0, 0.0, 1.0};
    bd.pd3dDeviceContext->OMSetRenderTargets(1, &vd.RTView, nullptr);
    if (!(viewport.Flags & ImGuiViewportFlags_NoRendererClear))
        bd.pd3dDeviceContext->ClearRenderTargetView(vd.RTView, (f32*)&clear_color);
    ImGui_ImplDX11_RenderDrawData(viewport.DrawData);
}

ImGui_ImplDX11_SwapBuffers :: proc(viewport : ^ImGuiViewport, rawptr)
{
    vd := (ImGui_ImplDX11_ViewportData*)viewport.RendererUserData;
    vd.SwapChain->Present(0, 0); // Present without vsync
}

ImGui_ImplDX11_InitMultiViewportSupport :: proc()
{
    ImGuiPlatformIO& platform_io = GetPlatformIO();
    platform_io.Renderer_CreateWindow = ImGui_ImplDX11_CreateWindow;
    platform_io.Renderer_DestroyWindow = ImGui_ImplDX11_DestroyWindow;
    platform_io.Renderer_SetWindowSize = ImGui_ImplDX11_SetWindowSize;
    platform_io.Renderer_RenderWindow = ImGui_ImplDX11_RenderWindow;
    platform_io.Renderer_SwapBuffers = ImGui_ImplDX11_SwapBuffers;
}

ImGui_ImplDX11_ShutdownMultiViewportSupport :: proc()
{
    DestroyPlatformWindows();
}

//-----------------------------------------------------------------------------

} // #ifndef IMGUI_DISABLE
