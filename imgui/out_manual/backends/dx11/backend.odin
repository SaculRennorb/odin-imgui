package im_dx11

import im "../../"
import dxgi "vendor:directx/dxgi"
import dx11 "vendor:directx/d3d11"
import dxc "vendor:directx/d3d_compiler"
import win32 "core:sys/windows"

// dear imgui: Renderer Backend for DirectX11
// This needs to be used along with a Platform Backend (e.g. Win32)

// Implemented features:
//  [X] Renderer: User texture binding. Use 'dx11.IShaderResourceView*' as ImTextureID. Read the FAQ about ImTextureID!
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
//  2025-01-06: DirectX11: Expose VertexConstantBuffer in RenderState. Reset projection matrix in ImDrawCallback_ResetRenderState handler.
//  2024-10-07: DirectX11: Changed default texture sampler to Clamp instead of Repeat/Wrap.
//  2024-10-07: DirectX11: Expose selected render state in RenderState, which you can access in 'void* platform_io.Renderer_RenderState' during draw callbacks.
//  2022-10-11: Using 'nullptr' instead of 'NULL' as per our switch to C++11.
//  2021-06-29: Reorganized backend to pull data from a single structure to facilitate usage with multiple-contexts (all g_XXXX access changed to bd->XXXX).
//  2021-05-19: DirectX11: Replaced direct access to ImDrawCmd::TextureId with a call to ImDrawCmd::GetTexID(). (will become a requirement)
//  2021-02-18: DirectX11: Change blending equation to preserve alpha in output buffer.
//  2019-08-01: DirectX11: Fixed code querying the Geometry Shader state (would generally error with Debug layer enabled).
//  2019-07-21: DirectX11: Backup, clear and restore Geometry Shader is any is bound when calling RenderDrawData. Clearing Hull/Domain/Compute shaders without backup/restore.
//  2019-05-29: DirectX11: Added support for large mesh (64K+ vertices), enable ImGuiBackendFlags_RendererHasVtxOffset flag.
//  2019-04-30: DirectX11: Added support for special ImDrawCallback_ResetRenderState callback to reset render state.
//  2018-12-03: Misc: Added #pragma comment statement to automatically link with d3dcompiler.lib when using D3DCompile().
//  2018-11-30: Misc: Setting up io.BackendRendererName so it can be displayed in the About Window.
//  2018-08-01: DirectX11: Querying for IDXGIFactory instead of IDXGIFactory1 to increase compatibility.
//  2018-07-13: DirectX11: Fixed unreleased resources in Init and Shutdown functions.
//  2018-06-08: Misc: Extracted imgui_impl_dx11.cpp/.h away from the old combined DX11+Win32 example.
//  2018-06-08: DirectX11: Use draw_data->DisplayPos and draw_data->DisplaySize to setup projection matrix and clipping rectangle.
//  2018-02-16: Misc: Obsoleted the io.RenderDrawListsFn callback and exposed RenderDrawData() in the .h file so you can call it yourself.
//  2018-02-06: Misc: Removed call to ImGui::Shutdown() which is not available from 1.60 WIP, user needs to call CreateContext/DestroyContext themselves.
//  2016-05-07: DirectX11: Disabling depth-write.


// dear imgui: Renderer Backend for DirectX11
// This needs to be used along with a Platform Backend (e.g. Win32)

// Implemented features:
//  [X] Renderer: User texture binding. Use 'dx11.IShaderResourceView*' as ImTextureID. Read the FAQ about ImTextureID!
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

// [BETA] Selected render state data shared with callbacks.
// This is temporarily stored in GetPlatformIO().Renderer_RenderState during the RenderDrawData() call.
// (Please open an issue if you feel you need access to more data)
RenderState :: struct {
	Device : ^dx11.IDevice,
	DeviceContext : ^dx11.IDeviceContext,
	SamplerDefault : ^dx11.ISamplerState,
	VertexConstantBuffer : ^dx11.IBuffer,
}

// DirectX

// DirectX11 data
Data :: struct {
	pd3dDevice : ^dx11.IDevice,
	pd3dDeviceContext : ^dx11.IDeviceContext,
	pFactory : ^dxgi.IFactory,
	pVB : ^dx11.IBuffer,
	pIB : ^dx11.IBuffer,
	pVertexShader : ^dx11.IVertexShader,
	pInputLayout : ^dx11.IInputLayout,
	pVertexConstantBuffer : ^dx11.IBuffer,
	pPixelShader : ^dx11.IPixelShader,
	pFontSampler : ^dx11.ISamplerState,
	pFontTextureView : ^dx11.IShaderResourceView,
	pRasterizerState : ^dx11.IRasterizerState,
	pBlendState : ^dx11.IBlendState,
	pDepthStencilState : ^dx11.IDepthStencilState,
	VertexBufferSize : i32,
	IndexBufferSize : i32,
}

Data_init :: proc(this : ^Data)
{
	this^ = {}
	this.VertexBufferSize = 5000
	this.IndexBufferSize = 10000
}

VERTEX_CONSTANT_BUFFER_DX11 :: struct {
	mvp : [4][4]f32,
}

// Backend data stored in io.BackendRendererUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
GetBackendData :: proc() -> ^Data
{
	return im.GetCurrentContext() != nil ? cast(^Data) im.GetIO().BackendRendererUserData : nil
}

// Functions
SetupRenderState :: proc(draw_data : ^im.ImDrawData, device_ctx : ^dx11.IDeviceContext)
{
	bd : ^Data = GetBackendData()

	// Setup viewport
	vp : dx11.VIEWPORT
	vp.Width = draw_data.DisplaySize.x
	vp.Height = draw_data.DisplaySize.y
	vp.MinDepth = 0.0
	vp.MaxDepth = 1.0
	vp.TopLeftY = 0; vp.TopLeftX = vp.TopLeftY
	device_ctx->RSSetViewports(1, &vp)

	// Setup orthographic projection matrix into our constant buffer
	// Our visible imgui space lies from draw_data->DisplayPos (top left) to draw_data->DisplayPos+data_data->DisplaySize (bottom right). DisplayPos is (0,0) for single viewport apps.
	mapped_resource : dx11.MAPPED_SUBRESOURCE
	if device_ctx->Map(bd.pVertexConstantBuffer, 0, dx11.MAP.WRITE_DISCARD, {}, &mapped_resource) == win32.S_OK {
		constant_buffer : ^VERTEX_CONSTANT_BUFFER_DX11 = cast(^VERTEX_CONSTANT_BUFFER_DX11) mapped_resource.pData
		L : f32 = draw_data.DisplayPos.x
		R : f32 = draw_data.DisplayPos.x + draw_data.DisplaySize.x
		T : f32 = draw_data.DisplayPos.y
		B : f32 = draw_data.DisplayPos.y + draw_data.DisplaySize.y
		mvp : [4][4]f32 = {
			{2.0 / (R - L), 0.0, 0.0, 0.0},
			{0.0, 2.0 / (T - B), 0.0, 0.0},
			{0.0, 0.0, 0.5, 0.0},
			{(R + L) / (L - R), (T + B) / (B - T), 0.5, 1.0},
		}
		constant_buffer.mvp = mvp
		device_ctx->Unmap(bd.pVertexConstantBuffer, 0)
	}

	// Setup shader and vertex buffers
	stride : u32 = size_of(im.ImDrawVert)
	offset : u32 = 0
	device_ctx->IASetInputLayout(bd.pInputLayout)
	device_ctx->IASetVertexBuffers(0, 1, &bd.pVB, &stride, &offset)
	device_ctx->IASetIndexBuffer(bd.pIB, size_of(im.ImDrawIdx) == 2 ? .R16_UINT : .R32_UINT, 0)
	device_ctx->IASetPrimitiveTopology(.TRIANGLELIST)
	device_ctx->VSSetShader(bd.pVertexShader, nil, 0)
	device_ctx->VSSetConstantBuffers(0, 1, &bd.pVertexConstantBuffer)
	device_ctx->PSSetShader(bd.pPixelShader, nil, 0)
	device_ctx->PSSetSamplers(0, 1, &bd.pFontSampler)
	device_ctx->GSSetShader(nil, nil, 0)
	device_ctx->HSSetShader(nil, nil, 0); // In theory we should backup and restore this as well.. very infrequently used..
	device_ctx->DSSetShader(nil, nil, 0); // In theory we should backup and restore this as well.. very infrequently used..
	device_ctx->CSSetShader(nil, nil, 0); // In theory we should backup and restore this as well.. very infrequently used..

	// Setup render state
	blend_factor : [4]f32 = {0., 0., 0., 0.}
	device_ctx->OMSetBlendState(bd.pBlendState, &blend_factor, 0xffffffff)
	device_ctx->OMSetDepthStencilState(bd.pDepthStencilState, 0)
	device_ctx->RSSetState(bd.pRasterizerState)
}

// Render function
RenderDrawData :: proc(draw_data : ^im.ImDrawData)
{
	// Avoid rendering when minimized
	if draw_data.DisplaySize.x <= 0.0 || draw_data.DisplaySize.y <= 0.0 { return }

	bd : ^Data = GetBackendData()
	device : ^dx11.IDeviceContext = bd.pd3dDeviceContext

	// Create and grow vertex/index buffers if needed
	if bd.pVB == nil || bd.VertexBufferSize < draw_data.TotalVtxCount {
		if bd.pVB != nil { bd.pVB->Release(); bd.pVB = nil }
		bd.VertexBufferSize = draw_data.TotalVtxCount + 5000
		desc : dx11.BUFFER_DESC
		desc.Usage = .DYNAMIC
		desc.ByteWidth = u32(bd.VertexBufferSize) * size_of(im.ImDrawVert)
		desc.BindFlags = { .VERTEX_BUFFER }
		desc.CPUAccessFlags = { .WRITE }
		desc.MiscFlags = {}
		if bd.pd3dDevice->CreateBuffer(&desc, nil, &bd.pVB) < 0 { return }
	}
	if bd.pIB == nil || bd.IndexBufferSize < draw_data.TotalIdxCount {
		if bd.pIB != nil { bd.pIB->Release(); bd.pIB = nil }
		bd.IndexBufferSize = draw_data.TotalIdxCount + 10000
		desc : dx11.BUFFER_DESC
		desc.Usage = .DYNAMIC
		desc.ByteWidth = u32(bd.IndexBufferSize) * size_of(im.ImDrawIdx)
		desc.BindFlags = {.INDEX_BUFFER}
		desc.CPUAccessFlags = { .WRITE }
		if bd.pd3dDevice->CreateBuffer(&desc, nil, &bd.pIB) < 0 { return }
	}

	// Upload vertex/index data into a single contiguous GPU buffer
	vtx_resource : dx11.MAPPED_SUBRESOURCE; idx_resource : dx11.MAPPED_SUBRESOURCE
	if device->Map(bd.pVB, 0, .WRITE_DISCARD, {}, &vtx_resource) != win32.S_OK { return }
	if device->Map(bd.pIB, 0, .WRITE_DISCARD, {}, &idx_resource) != win32.S_OK { return }
	vtx_dst := cast([^]im.ImDrawVert) vtx_resource.pData
	idx_dst := cast([^]im.ImDrawIdx) idx_resource.pData
	for n : i32 = 0; n < draw_data.CmdListsCount; n += 1 {
		draw_list := draw_data.CmdLists.Data[n]
		im.memcpy(vtx_dst, draw_list.VtxBuffer.Data, int(draw_list.VtxBuffer.Size) * size_of(im.ImDrawVert))
		im.memcpy(idx_dst, draw_list.IdxBuffer.Data, int(draw_list.IdxBuffer.Size) * size_of(im.ImDrawIdx))
		vtx_dst = vtx_dst[draw_list.VtxBuffer.Size:]
		idx_dst = idx_dst[draw_list.IdxBuffer.Size:]
	}

	device->Unmap(bd.pVB, 0)
	device->Unmap(bd.pIB, 0)

	// Backup DX state that will be modified to restore it afterwards (unfortunately this is very ugly looking and verbose. Close your eyes!)
BACKUP_DX11_STATE :: struct {
		ScissorRectsCount : win32.UINT, ViewportsCount : win32.UINT,
		ScissorRects : [dx11.VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE]dx11.RECT,
		Viewports : [dx11.VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE]dx11.VIEWPORT,
		RS : ^dx11.IRasterizerState,
		BlendState : ^dx11.IBlendState,
		BlendFactor : [4]f32,
		SampleMask : dx11.COLOR_WRITE_ENABLE_MASK,
		StencilRef : win32.UINT,
		DepthStencilState : ^dx11.IDepthStencilState,
		PSShaderResource : ^dx11.IShaderResourceView,
		PSSampler : ^dx11.ISamplerState,
		PS : ^dx11.IPixelShader,
		VS : ^dx11.IVertexShader,
		GS : ^dx11.IGeometryShader,
		PSInstancesCount : win32.UINT, VSInstancesCount : win32.UINT, GSInstancesCount : win32.UINT,
		PSInstances : [256]^dx11.IClassInstance, VSInstances : [256]^dx11.IClassInstance, GSInstances : [256]^dx11.IClassInstance, // 256 is max according to PSSetShader documentation
		PrimitiveTopology : dx11.PRIMITIVE_TOPOLOGY,
		IndexBuffer : ^dx11.IBuffer, VertexBuffer : ^dx11.IBuffer, VSConstantBuffer : ^dx11.IBuffer,
		IndexBufferOffset : win32.UINT, VertexBufferStride : win32.UINT, VertexBufferOffset : win32.UINT,
		IndexBufferFormat : dxgi.FORMAT,
		InputLayout : ^dx11.IInputLayout,
	}
	old : BACKUP_DX11_STATE = {}
	old.ViewportsCount = dx11.VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE; old.ScissorRectsCount = old.ViewportsCount
	device->RSGetScissorRects(&old.ScissorRectsCount, raw_data(&old.ScissorRects))
	device->RSGetViewports(&old.ViewportsCount, raw_data(&old.Viewports))
	device->RSGetState(&old.RS)
	device->OMGetBlendState(&old.BlendState, &old.BlendFactor, &old.SampleMask)
	device->OMGetDepthStencilState(&old.DepthStencilState, &old.StencilRef)
	device->PSGetShaderResources(0, 1, &old.PSShaderResource)
	device->PSGetSamplers(0, 1, &old.PSSampler)
	old.GSInstancesCount = 256; old.VSInstancesCount = old.GSInstancesCount; old.PSInstancesCount = old.VSInstancesCount
	device->PSGetShader(&old.PS, raw_data(&old.PSInstances), &old.PSInstancesCount)
	device->VSGetShader(&old.VS, raw_data(&old.VSInstances), &old.VSInstancesCount)
	device->VSGetConstantBuffers(0, 1, &old.VSConstantBuffer)
	device->GSGetShader(&old.GS, raw_data(&old.GSInstances), &old.GSInstancesCount)

	device->IAGetPrimitiveTopology(&old.PrimitiveTopology)
	device->IAGetIndexBuffer(&old.IndexBuffer, &old.IndexBufferFormat, &old.IndexBufferOffset)
	device->IAGetVertexBuffers(0, 1, &old.VertexBuffer, &old.VertexBufferStride, &old.VertexBufferOffset)
	device->IAGetInputLayout(&old.InputLayout)

	// Setup desired DX state
	SetupRenderState(draw_data, device)

	// Setup render state structure (for callbacks and custom texture bindings)
	platform_io := im.GetPlatformIO()
	render_state : RenderState
	render_state.Device = bd.pd3dDevice
	render_state.DeviceContext = bd.pd3dDeviceContext
	render_state.SamplerDefault = bd.pFontSampler
	render_state.VertexConstantBuffer = bd.pVertexConstantBuffer
	platform_io.Renderer_RenderState = &render_state

	// Render command lists
	// (Because we merged all buffers into a single one, we maintain our own offset into them)
	global_idx_offset : i32 = 0
	global_vtx_offset : i32 = 0
	clip_off := draw_data.DisplayPos
	for n : i32 = 0; n < draw_data.CmdListsCount; n += 1 {
		draw_list := draw_data.CmdLists.Data[n]
		for cmd_i : i32 = 0; cmd_i < draw_list.CmdBuffer.Size; cmd_i += 1 {
			pcmd := &draw_list.CmdBuffer.Data[cmd_i]
			if pcmd.UserCallback != nil {
				// User callback, registered via ImDrawList::AddCallback()
				// (ImDrawCallback_ResetRenderState is a special callback value used by the user to request the renderer to reset render state.)
				if pcmd.UserCallback == im.ImDrawCallback_ResetRenderState { SetupRenderState(draw_data, device) }
				else { pcmd.UserCallback(draw_list, pcmd) }
			}
			else {
				// Project scissor/clipping rectangles into framebuffer space
				clip_min : im.ImVec2 = { pcmd.ClipRect.x - clip_off.x, pcmd.ClipRect.y - clip_off.y }
				clip_max : im.ImVec2 = { pcmd.ClipRect.z - clip_off.x, pcmd.ClipRect.w - clip_off.y }
				if clip_max.x <= clip_min.x || clip_max.y <= clip_min.y { continue }

				// Apply scissor/clipping rectangle
				r : dx11.RECT = {cast(win32.LONG) clip_min.x, cast(win32.LONG) clip_min.y, cast(win32.LONG) clip_max.x, cast(win32.LONG) clip_max.y}
				device->RSSetScissorRects(1, &r)

				// Bind texture, Draw
				texture_srv := cast(^dx11.IShaderResourceView) cast(uintptr) im.GetTexID(pcmd)
				device->PSSetShaderResources(0, 1, &texture_srv)
				device->DrawIndexed(pcmd.ElemCount, pcmd.IdxOffset + u32(global_idx_offset), i32(pcmd.VtxOffset) + global_vtx_offset)
			}
		}

		global_idx_offset += draw_list.IdxBuffer.Size
		global_vtx_offset += draw_list.VtxBuffer.Size
	}

	platform_io.Renderer_RenderState = nil

	// Restore modified DX state
	device->RSSetScissorRects(old.ScissorRectsCount, raw_data(&old.ScissorRects))
	device->RSSetViewports(old.ViewportsCount, raw_data(&old.Viewports))
	device->RSSetState(old.RS); if old.RS != nil { old.RS->Release() }
	device->OMSetBlendState(old.BlendState, &old.BlendFactor, transmute(u32)old.SampleMask); if old.BlendState != nil { old.BlendState->Release() }
	device->OMSetDepthStencilState(old.DepthStencilState, old.StencilRef); if old.DepthStencilState != nil { old.DepthStencilState->Release() }
	device->PSSetShaderResources(0, 1, &old.PSShaderResource); if old.PSShaderResource != nil { old.PSShaderResource->Release() }
	device->PSSetSamplers(0, 1, &old.PSSampler); if old.PSSampler != nil { old.PSSampler->Release() }
	device->PSSetShader(old.PS, raw_data(&old.PSInstances), old.PSInstancesCount); if old.PS != nil { old.PS->Release() }
	for i : win32.UINT = 0; i < old.PSInstancesCount; i += 1 { if old.PSInstances[i] != nil { old.PSInstances[i]->Release() } }

	device->VSSetShader(old.VS, raw_data(&old.VSInstances), old.VSInstancesCount); if old.VS != nil { old.VS->Release() }
	device->VSSetConstantBuffers(0, 1, &old.VSConstantBuffer); if old.VSConstantBuffer != nil { old.VSConstantBuffer->Release() }
	device->GSSetShader(old.GS, raw_data(&old.GSInstances), old.GSInstancesCount); if old.GS != nil { old.GS->Release() }
	for i : win32.UINT = 0; i < old.VSInstancesCount; i += 1 { if old.VSInstances[i] != nil { old.VSInstances[i]->Release() } }

	device->IASetPrimitiveTopology(old.PrimitiveTopology)
	device->IASetIndexBuffer(old.IndexBuffer, old.IndexBufferFormat, old.IndexBufferOffset); if old.IndexBuffer != nil { old.IndexBuffer->Release() }
	device->IASetVertexBuffers(0, 1, &old.VertexBuffer, &old.VertexBufferStride, &old.VertexBufferOffset); if old.VertexBuffer != nil { old.VertexBuffer->Release() }
	device->IASetInputLayout(old.InputLayout); if old.InputLayout != nil { old.InputLayout->Release() }
}

CreateFontsTexture :: proc()
{
	// Build texture atlas
	io := im.GetIO()
	bd : ^Data = GetBackendData()
	pixels : ^u8
	width : i32; height : i32
	im.GetTexDataAsRGBA32(io.Fonts, &pixels, &width, &height)

	// Upload texture to graphics system
	{
	desc : dx11.TEXTURE2D_DESC
	desc.Width = u32(width)
	desc.Height = u32(height)
	desc.MipLevels = 1
	desc.ArraySize = 1
	desc.Format = .R8G8B8A8_UNORM
	desc.SampleDesc.Count = 1
	desc.Usage = .DEFAULT
	desc.BindFlags = { .SHADER_RESOURCE }
	desc.CPUAccessFlags = {}

	pTexture : ^dx11.ITexture2D = nil
	subResource : dx11.SUBRESOURCE_DATA
	subResource.pSysMem = pixels
	subResource.SysMemPitch = desc.Width * 4
	subResource.SysMemSlicePitch = 0
	bd.pd3dDevice->CreateTexture2D(&desc, &subResource, &pTexture)
	im.IM_ASSERT(pTexture != nil)

	// Create texture view
	srvDesc : dx11.SHADER_RESOURCE_VIEW_DESC
	srvDesc.Format = .R8G8B8A8_UNORM
	srvDesc.ViewDimension = .TEXTURE2D
	srvDesc.Texture2D.MipLevels = desc.MipLevels
	srvDesc.Texture2D.MostDetailedMip = 0
	bd.pd3dDevice->CreateShaderResourceView(pTexture, &srvDesc, &bd.pFontTextureView)
	pTexture->Release()
	}

	// Store our identifier
	im.SetTexID(io.Fonts, cast(im.ImTextureID) cast(uintptr)bd.pFontTextureView)
}

DestroyFontsTexture :: proc()
{
	bd : ^Data = GetBackendData()
	if bd.pFontTextureView != nil {
		bd.pFontTextureView->Release()
		bd.pFontTextureView = nil
		im.SetTexID(im.GetIO().Fonts, 0); // We copied data->pFontTextureView to io.Fonts->TexID so let's clear that as well.
	}
}

// Use if you want to reset your rendering device without losing Dear ImGui state.
CreateDeviceObjects :: proc() -> bool
{
	bd : ^Data = GetBackendData()
	if bd.pd3dDevice == nil { return false }
	if bd.pFontSampler != nil { InvalidateDeviceObjects() }

	// By using D3DCompile() from <d3dcompiler.h> / d3dcompiler.lib, we introduce a dependency to a given version of d3dcompiler_XX.dll (see D3DCOMPILER_DLL_A)
	// If you would like to use this DX11 sample code but remove this dependency you can:
	//  1) compile once, save the compiled shader blobs into a file or source code and pass them to CreateVertexShader()/CreatePixelShader() [preferred solution]
	//  2) use code to detect any version of the DLL and grab a pointer to D3DCompile from the DLL.
	// See https://github.com/ocornut/imgui/pull/638 for sources and details.

	// Create the vertex shader
	{
	vertexShader := `cbuffer vertexBuffer : register(b0) 
	{
		float4x4 ProjectionMatrix; 
	};
	struct VS_INPUT
	{
		float2 pos : POSITION;
		float4 col : COLOR0;
		float2 uv  : TEXCOORD0;
	};
	
	struct PS_INPUT
	{
		float4 pos : SV_POSITION;
		float4 col : COLOR0;
		float2 uv  : TEXCOORD0;
	};
	
	PS_INPUT main(VS_INPUT input)
	{
		PS_INPUT output;
		output.pos = mul( ProjectionMatrix, float4(input.pos.xy, 0.f, 1.f));
		output.col = input.col;
		output.uv  = input.uv;
		return output;
	}`

	vertexShaderBlob : ^dx11.IBlob
	if win32.FAILED(dxc.Compile(raw_data(vertexShader), len(vertexShader), nil, nil, nil, "main", "vs_4_0", 0, 0, &vertexShaderBlob, nil)) {
		// NB: Pass ID3DBlob* pErrorBlob to D3DCompile() to get error showing in (const char*)pErrorBlob->GetBufferPointer(). Make sure to Release() the blob!
		return false
	}
	if bd.pd3dDevice->CreateVertexShader(vertexShaderBlob->GetBufferPointer(), vertexShaderBlob->GetBufferSize(), nil, &bd.pVertexShader) != win32.S_OK {
		vertexShaderBlob->Release()
		return false
	}

	// Create the input layout
	local_layout := [?]dx11.INPUT_ELEMENT_DESC {
		{"POSITION", 0, .R32G32_FLOAT, 0, cast(win32.UINT) offset_of(im.ImDrawVert, pos), .VERTEX_DATA, 0},
		{"TEXCOORD", 0, .R32G32_FLOAT, 0, cast(win32.UINT) offset_of(im.ImDrawVert, uv), .VERTEX_DATA, 0},
		{"COLOR", 0, .R8G8B8A8_UNORM, 0, cast(win32.UINT) offset_of(im.ImDrawVert, col), .VERTEX_DATA, 0},
	}
	if bd.pd3dDevice->CreateInputLayout(raw_data(&local_layout), len(local_layout), vertexShaderBlob->GetBufferPointer(), vertexShaderBlob->GetBufferSize(), &bd.pInputLayout) != win32.S_OK {
		vertexShaderBlob->Release()
		return false
	}
	vertexShaderBlob->Release()

	// Create the constant buffer
	{
	desc : dx11.BUFFER_DESC
	desc.ByteWidth = size_of(VERTEX_CONSTANT_BUFFER_DX11)
	desc.Usage = .DYNAMIC
	desc.BindFlags = { .CONSTANT_BUFFER }
	desc.CPUAccessFlags = { .WRITE }
	desc.MiscFlags = {}
	bd.pd3dDevice->CreateBuffer(&desc, nil, &bd.pVertexConstantBuffer)
	}
	}

	// Create the pixel shader
	{
	pixelShader := `struct PS_INPUT
	{
		float4 pos : SV_POSITION;
		float4 col : COLOR0;
		float2 uv  : TEXCOORD0;
	};
	sampler sampler0;
	Texture2D texture0;
	
	float4 main(PS_INPUT input) : SV_Target
	{
		float4 out_col = input.col * texture0.Sample(sampler0, input.uv); 
		return out_col; 
	}`

	pixelShaderBlob : ^dx11.IBlob
	if win32.FAILED(dxc.Compile(raw_data(pixelShader), len(pixelShader), nil, nil, nil, "main", "ps_4_0", 0, 0, &pixelShaderBlob, nil)) {
		// NB: Pass ID3DBlob* pErrorBlob to D3DCompile() to get error showing in (const char*)pErrorBlob->GetBufferPointer(). Make sure to Release() the blob!
		return false
	}
	if bd.pd3dDevice->CreatePixelShader(pixelShaderBlob->GetBufferPointer(), pixelShaderBlob->GetBufferSize(), nil, &bd.pPixelShader) != win32.S_OK {
		pixelShaderBlob->Release()
		return false
	}
	pixelShaderBlob->Release()
	}

	// Create the blending setup
	{
	desc : dx11.BLEND_DESC
	desc.AlphaToCoverageEnable = false
	desc.RenderTarget[0].BlendEnable = true
	desc.RenderTarget[0].SrcBlend = .SRC_ALPHA
	desc.RenderTarget[0].DestBlend = .INV_SRC_ALPHA
	desc.RenderTarget[0].BlendOp = .ADD
	desc.RenderTarget[0].SrcBlendAlpha = .ONE
	desc.RenderTarget[0].DestBlendAlpha = .INV_SRC_ALPHA
	desc.RenderTarget[0].BlendOpAlpha = .ADD
	desc.RenderTarget[0].RenderTargetWriteMask = u8(dx11.COLOR_WRITE_ENABLE_ALL)
	bd.pd3dDevice->CreateBlendState(&desc, &bd.pBlendState)
	}

	// Create the rasterizer state
	{
	desc : dx11.RASTERIZER_DESC
	desc.FillMode = .SOLID
	desc.CullMode = .NONE
	desc.ScissorEnable = true
	desc.DepthClipEnable = true
	bd.pd3dDevice->CreateRasterizerState(&desc, &bd.pRasterizerState)
	}

	// Create depth-stencil State
	{
	desc : dx11.DEPTH_STENCIL_DESC
	desc.DepthEnable = false
	desc.DepthWriteMask = .ALL
	desc.DepthFunc = .ALWAYS
	desc.StencilEnable = false
	desc.FrontFace.StencilPassOp = .KEEP; desc.FrontFace.StencilDepthFailOp = desc.FrontFace.StencilPassOp; desc.FrontFace.StencilFailOp = desc.FrontFace.StencilDepthFailOp
	desc.FrontFace.StencilFunc = .ALWAYS
	desc.BackFace = desc.FrontFace
	bd.pd3dDevice->CreateDepthStencilState(&desc, &bd.pDepthStencilState)
	}

	// Create texture sampler
	// (Bilinear sampling is required by default. Set 'io.Fonts->Flags |= ImFontAtlasFlags_NoBakedLines' or 'style.AntiAliasedLinesUseTex = false' to allow point/nearest sampling)
	{
	desc : dx11.SAMPLER_DESC
	desc.Filter = .MIN_MAG_MIP_LINEAR
	desc.AddressU = .CLAMP
	desc.AddressV = .CLAMP
	desc.AddressW = .CLAMP
	desc.MipLODBias = 0.
	desc.ComparisonFunc = .ALWAYS
	desc.MinLOD = 0.
	desc.MaxLOD = 0.
	bd.pd3dDevice->CreateSamplerState(&desc, &bd.pFontSampler)
	}

	CreateFontsTexture()

	return true
}

InvalidateDeviceObjects :: proc()
{
	bd : ^Data = GetBackendData()
	if bd.pd3dDevice == nil { return }

	DestroyFontsTexture()

	if bd.pFontSampler != nil { bd.pFontSampler->Release(); bd.pFontSampler = nil }
	if bd.pIB != nil { bd.pIB->Release(); bd.pIB = nil }
	if bd.pVB != nil { bd.pVB->Release(); bd.pVB = nil }
	if bd.pBlendState != nil { bd.pBlendState->Release(); bd.pBlendState = nil }
	if bd.pDepthStencilState != nil { bd.pDepthStencilState->Release(); bd.pDepthStencilState = nil }
	if bd.pRasterizerState != nil { bd.pRasterizerState->Release(); bd.pRasterizerState = nil }
	if bd.pPixelShader != nil { bd.pPixelShader->Release(); bd.pPixelShader = nil }
	if bd.pVertexConstantBuffer != nil { bd.pVertexConstantBuffer->Release(); bd.pVertexConstantBuffer = nil }
	if bd.pInputLayout != nil { bd.pInputLayout->Release(); bd.pInputLayout = nil }
	if bd.pVertexShader != nil { bd.pVertexShader->Release(); bd.pVertexShader = nil }
}

// Follow "Getting Started" link and check examples/ folder to learn about using backends!
Init :: proc(device : ^dx11.IDevice, device_context : ^dx11.IDeviceContext) -> bool
{
	io := im.GetIO()
	im.CHECKVERSION()
	im.IM_ASSERT(io.BackendRendererUserData == nil, "Already initialized a renderer backend!")

	// Setup backend capabilities flags
	bd : ^Data = im.IM_NEW_MEM(Data); Data_init(bd)
	io.BackendRendererUserData = cast(rawptr) bd
	io.BackendRendererName = "imgui_impl_dx11"
	io.BackendFlags |= .ImGuiBackendFlags_RendererHasVtxOffset; // We can honor the ImDrawCmd::VtxOffset field, allowing for large meshes.
	io.BackendFlags |= .ImGuiBackendFlags_RendererHasViewports; // We can create multi-viewports on the Renderer side (optional)

	// Get factory from device
	pDXGIDevice : ^dxgi.IDevice = nil
	pDXGIAdapter : ^dxgi.IAdapter = nil
	pFactory : ^dxgi.IFactory = nil

	if device->QueryInterface(dxgi.IDevice_UUID, (^rawptr)(&pDXGIDevice)) == win32.S_OK {
		if pDXGIDevice->GetParent(dxgi.IAdapter_UUID, (^rawptr)(&pDXGIAdapter)) == win32.S_OK {
			if pDXGIAdapter->GetParent(dxgi.IFactory_UUID, (^rawptr)(&pFactory)) == win32.S_OK {
				bd.pd3dDevice = device
				bd.pd3dDeviceContext = device_context
				bd.pFactory = pFactory
			}
		}
	}
	if pDXGIDevice != nil { pDXGIDevice->Release() }
	if pDXGIAdapter != nil { pDXGIAdapter->Release() }
	bd.pd3dDevice->AddRef()
	bd.pd3dDeviceContext->AddRef()

	InitMultiViewportSupport()

	return true
}

Shutdown :: proc()
{
	bd : ^Data = GetBackendData()
	im.IM_ASSERT(bd != nil, "No renderer backend to shutdown, or already shutdown?")
	io := im.GetIO()

	ShutdownMultiViewportSupport()
	InvalidateDeviceObjects()
	if bd.pFactory != nil { bd.pFactory->Release() }
	if bd.pd3dDevice != nil { bd.pd3dDevice->Release() }
	if bd.pd3dDeviceContext != nil { bd.pd3dDeviceContext->Release() }
	io.BackendRendererName = ""
	io.BackendRendererUserData = nil
	io.BackendFlags &= cast(im.ImGuiBackendFlags)~cast(i32)(im.ImGuiBackendFlags_.ImGuiBackendFlags_RendererHasVtxOffset | im.ImGuiBackendFlags_.ImGuiBackendFlags_RendererHasViewports)
	im.IM_FREE(bd)
}

NewFrame :: proc()
{
	bd : ^Data = GetBackendData()
	im.IM_ASSERT(bd != nil, "Context or backend not initialized! Did you call Init()?")

	if bd.pFontSampler == nil { CreateDeviceObjects() }
}

//--------------------------------------------------------------------------------------------------------
// MULTI-VIEWPORT / PLATFORM INTERFACE SUPPORT
// This is an _advanced_ and _optional_ feature, allowing the backend to create and handle multiple viewports simultaneously.
// If you are new to dear imgui or creating a new binding for dear imgui, it is recommended that you completely ignore this section first..
//--------------------------------------------------------------------------------------------------------

// Helper structure we store in the void* RendererUserData field of each ImGuiViewport to easily retrieve our backend data.
ViewportData :: struct {
	SwapChain : ^dxgi.ISwapChain,
	RTView : ^dx11.IRenderTargetView,
}

ViewportData_deinit :: proc(this : ^ViewportData)
{im.IM_ASSERT(this.SwapChain == nil && this.RTView == nil)}

ViewportData_init :: proc(this : ^ViewportData)
{
	this.SwapChain = nil; this.RTView = nil
}

CreateWindow :: proc(viewport : ^im.ImGuiViewport)
{
	bd : ^Data = GetBackendData()
	vd : ^ViewportData = im.IM_NEW_MEM(ViewportData); ViewportData_init(vd)
	viewport.RendererUserData = vd

	// PlatformHandleRaw should always be a HWND, whereas PlatformHandle might be a higher-level handle (e.g. GLFWWindow*, SDL_Window*).
	// Some backends will leave PlatformHandleRaw == 0, in which case we assume PlatformHandle will contain the HWND.
	hwnd := viewport.PlatformHandleRaw != nil ? cast(win32.HWND) viewport.PlatformHandleRaw : cast(win32.HWND) viewport.PlatformHandle
	im.IM_ASSERT(hwnd != {})

	// Create swap chain
	sd : dxgi.SWAP_CHAIN_DESC
	sd.BufferDesc.Width = cast(win32.UINT) viewport.Size.x
	sd.BufferDesc.Height = cast(win32.UINT) viewport.Size.y
	sd.BufferDesc.Format = .R8G8B8A8_UNORM
	sd.SampleDesc.Count = 1
	sd.SampleDesc.Quality = 0
	sd.BufferUsage = { .RENDER_TARGET_OUTPUT }
	sd.BufferCount = 1
	sd.OutputWindow = hwnd
	sd.Windowed = win32.TRUE
	sd.SwapEffect = .DISCARD
	sd.Flags = {}

	im.IM_ASSERT(vd.SwapChain == nil && vd.RTView == nil)
	bd.pFactory->CreateSwapChain(bd.pd3dDevice, &sd, &vd.SwapChain)

	// Create the render target
	if vd.SwapChain != nil {
		pBackBuffer : ^dx11.ITexture2D
		vd.SwapChain->GetBuffer(0, dx11.ITexture2D_UUID, (^rawptr)(&pBackBuffer))
		bd.pd3dDevice->CreateRenderTargetView(pBackBuffer, nil, &vd.RTView)
		pBackBuffer->Release()
	}
}

DestroyWindow :: proc(viewport : ^im.ImGuiViewport)
{
	// The main viewport (owned by the application) will always have RendererUserData == nullptr since we didn't create the data for it.
	if vd := cast(^ViewportData) viewport.RendererUserData; vd != nil {
		if vd.SwapChain != nil { vd.SwapChain->Release() }
		vd.SwapChain = nil
		if vd.RTView != nil { vd.RTView->Release() }
		vd.RTView = nil
		ViewportData_deinit(vd); im.IM_FREE(vd)
	}
	viewport.RendererUserData = nil
}

SetWindowSize :: proc(viewport : ^im.ImGuiViewport, size : im.ImVec2)
{
	bd : ^Data = GetBackendData()
	vd := cast(^ViewportData) viewport.RendererUserData
	if vd.RTView != nil {
		vd.RTView->Release()
		vd.RTView = nil
	}
	if vd.SwapChain != nil {
		pBackBuffer : ^dx11.ITexture2D = nil
		vd.SwapChain->ResizeBuffers(0, cast(win32.UINT) size.x, cast(win32.UINT) size.y, .UNKNOWN, {})
		vd.SwapChain->GetBuffer(0, dx11.ITexture2D_UUID, (^rawptr)(&pBackBuffer))
		if pBackBuffer == nil {
			im.IM_ASSERT(false, "SetWindowSize() failed creating buffers.\n")
			return
		}
		bd.pd3dDevice->CreateRenderTargetView(pBackBuffer, nil, &vd.RTView)
		pBackBuffer->Release()
	}
}

RenderWindow :: proc(viewport : ^im.ImGuiViewport, _ : rawptr)
{
	bd := GetBackendData()
	vd := cast(^ViewportData) viewport.RendererUserData
	clear_color := im.ImVec4{0.0, 0.0, 0.0, 1.0}
	bd.pd3dDeviceContext->OMSetRenderTargets(1, &vd.RTView, nil)
	if (viewport.Flags & .ImGuiViewportFlags_NoRendererClear) == {} { bd.pd3dDeviceContext->ClearRenderTargetView(vd.RTView, &clear_color) }
	RenderDrawData(viewport.DrawData)
}

SwapBuffers :: proc(viewport : ^im.ImGuiViewport, _ : rawptr)
{
	vd := cast(^ViewportData) viewport.RendererUserData
	vd.SwapChain->Present(0, {}); // Present without vsync
}

// Forward Declarations
InitMultiViewportSupport :: proc()
{
	platform_io := im.GetPlatformIO()
	platform_io.Renderer_CreateWindow = CreateWindow
	platform_io.Renderer_DestroyWindow = DestroyWindow
	platform_io.Renderer_SetWindowSize = SetWindowSize
	platform_io.Renderer_RenderWindow = RenderWindow
	platform_io.Renderer_SwapBuffers = SwapBuffers
}

ShutdownMultiViewportSupport :: proc()
{
	im.DestroyPlatformWindows()
}
