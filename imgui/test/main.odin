package test_im

import "base:runtime"
import "core:fmt"
import "core:os"
import win32 "core:sys/windows"
import win32_ex "../out_manual/backends/win32/win32_ex"
import "vendor:directx/d3d11"
import "vendor:directx/dxgi"
import im "../out_manual"
import im_dx11 "../out_manual/backends/dx11"
import im_win32 "../out_manual/backends/win32"

g_device : ^d3d11.IDevice;
g_deviceContext : ^d3d11.IDeviceContext;
g_swapChain : ^dxgi.ISwapChain;
g_swapChainOccluded : bool
g_resizeWidth, g_resizeHeight : u32
g_mainRenderTargetView : ^d3d11.IRenderTargetView;

main :: proc() {
	im_win32.EnableDpiAwareness()
	main_scale := im_win32.GetDpiScaleForMonitor(win32.MonitorFromPoint({0, 0}, .MONITOR_DEFAULTTOPRIMARY))

	wc := win32.WNDCLASSEXW {size_of(win32.WNDCLASSEXW), win32.CS_CLASSDC, wnd_proc, 0, 0, cast(win32.HANDLE) win32.GetModuleHandleW(nil), nil, nil, nil, nil, "Test Class", nil }
	class := win32.RegisterClassExW(&wc); defer win32.UnregisterClassW(wc.lpszClassName, wc.hInstance)

	c := context
	hwnd := win32.CreateWindowW(wc.lpszClassName, "Test", win32.WS_OVERLAPPEDWINDOW, 100, 100, i32(1280 * main_scale), i32(800 * main_scale), nil, nil, wc.hInstance, &c); defer win32.DestroyWindow(hwnd)

	device_ok := create_device(hwnd); defer cleanup_device()
	if !device_ok { os.exit(1) }

	win32.ShowWindow(hwnd, win32.SW_SHOWDEFAULT)
	win32.UpdateWindow(hwnd)

	im.CHECKVERSION()
	im.CreateContext(); defer im.DestroyContext()
	io := im.GetIO()
	io.ConfigFlags |= .ConfigFlags_NavEnableKeyboard
	io.ConfigFlags |= .ConfigFlags_NavEnableGamepad

	im.StyleColorsDark()

	style := im.GetStyle()

	im_win32.Init(hwnd); defer im_win32.Shutdown()
	im_dx11.Init(g_device, g_deviceContext); defer im_dx11.Shutdown()

	show_demo := true
	show_other := false
	clear_color := im.Vec4{.45, .55, .60, 1}

	for done := false; !done; {
		msg : win32.MSG
		for win32.PeekMessageW(&msg, nil, 0, 0, win32.PM_REMOVE) {
			win32.TranslateMessage(&msg)
			win32.DispatchMessageW(&msg)
			if msg.message == win32.WM_QUIT { done = true }
		}
		if done { break }

		if g_swapChainOccluded && g_swapChain->Present(0, { .TEST }) == dxgi.STATUS_OCCLUDED {
			win32.Sleep(10)
			continue
		}
		g_swapChainOccluded = false

		if g_resizeWidth != 0 && g_resizeHeight != 0 {
			cleanup_render_target()
			g_swapChain->ResizeBuffers(0, g_resizeWidth, g_resizeHeight, .UNKNOWN, {})
			g_resizeWidth = 0
			g_resizeHeight = 0
			create_render_target()
		}

		im_dx11.NewFrame()
		im_win32.NewFrame()
		im.NewFrame()

		if show_demo { im.ShowDebugLogWindow(&show_demo) }

		{
			@(static) f : f32 = 0.0
			@(static) counter := 0

			im.Begin("Hello, world!");                          // Create a window called "Hello, world!" and append into it.

			im.Text("This is some useful text.");               // Display some text (you can use a format strings too)
			im.Checkbox("Demo Window", &show_demo);      // Edit bools storing our window open/close state
			im.Checkbox("Another Window", &show_other);

			im.SliderFloat("float", &f, 0, 1);            // Edit 1 float using a slider from 0.0f to 1.0f
			im.ColorEdit3("clear color", cast(^[3]f32)&clear_color); // Edit 3 floats representing a color

			if im.Button("Button") { counter += 1 }           // Buttons return true when clicked (most widgets return true when edited/activated)

			im.SameLine();
			im.Text("counter = %d", counter);

			im.Text("Application average %.3f ms/frame (%.1f FPS)", 1000 / io.Framerate, io.Framerate);
			im.End();
		}

		if (show_other)
		{
			im.Begin("Another Window", &show_other);   // Pass a pointer to our bool variable (the window will have a closing button that will clear the bool when clicked)
			im.Text("Hello from another window!");
			if im.Button("Close Me") { show_other = false }
			im.End();
		}

		im.Render()
		clear_color_with_alpha := [4]f32{ clear_color.x * clear_color.w, clear_color.y * clear_color.w, clear_color.z * clear_color.w, clear_color.w }
		g_deviceContext->OMSetRenderTargets(1, &g_mainRenderTargetView, nil)
		g_deviceContext->ClearRenderTargetView(g_mainRenderTargetView, &clear_color_with_alpha)
		im_dx11.RenderDrawData(im.GetDrawData())

		g_swapChainOccluded = g_swapChain->Present(1, {}) == dxgi.STATUS_OCCLUDED // vsync
	}
}

create_device :: proc(hwnd : win32.HWND) -> (ok : bool)
{
	sd : dxgi.SWAP_CHAIN_DESC
	sd.BufferCount = 2
	sd.BufferDesc.Width = 0
	sd.BufferDesc.Height = 0
	sd.BufferDesc.Format = .R8G8B8A8_UNORM
	sd.BufferDesc.RefreshRate = { Numerator = 60, Denominator = 1 }
	sd.Flags = { .ALLOW_MODE_SWITCH }
	sd.BufferUsage = { .RENDER_TARGET_OUTPUT }
	sd.OutputWindow = hwnd
	sd.SampleDesc.Count = 1
	sd.SampleDesc.Quality = 0
	sd.Windowed = true
	sd.SwapEffect = .DISCARD

	flags : d3d11.CREATE_DEVICE_FLAGS
	flevels := [?]d3d11.FEATURE_LEVEL{ ._11_0, ._10_0 }
	
	flevel : d3d11.FEATURE_LEVEL
	res := d3d11.CreateDeviceAndSwapChain(nil, .HARDWARE, nil, flags, raw_data(&flevels), cast(u32)len(flevels), d3d11.SDK_VERSION, &sd, &g_swapChain, &g_device, &flevel, &g_deviceContext)
	if res == dxgi.ERROR_UNSUPPORTED {
		res = d3d11.CreateDeviceAndSwapChain(nil, .WARP, nil, flags, raw_data(&flevels), cast(u32)len(flevels), d3d11.SDK_VERSION, &sd, &g_swapChain, &g_device, &flevel, &g_deviceContext)
	}
	if res != win32.S_OK { return false }

	create_render_target()
	return true
}

cleanup_device :: proc()
{
	cleanup_render_target()
	if g_swapChain != nil { g_swapChain->Release(); g_swapChain = nil }
	if g_deviceContext != nil { g_deviceContext->Release(); g_deviceContext = nil }
	if g_device != nil { g_device->Release(); g_device = nil }
}

create_render_target :: proc()
{
	back_buffer : ^d3d11.ITexture2D
	g_swapChain->GetBuffer(0, d3d11.ITexture2D_UUID, cast(^rawptr)&back_buffer)
	g_device->CreateRenderTargetView(back_buffer, nil, &g_mainRenderTargetView)
	back_buffer->Release()
}

cleanup_render_target :: proc()
{
	if g_mainRenderTargetView != nil { g_mainRenderTargetView->Release(); g_mainRenderTargetView = nil }
}

wnd_proc :: proc "system" (hWnd : win32.HWND, msg : win32.UINT, wParam : win32.WPARAM, lParam : win32.LPARAM) -> win32.LRESULT
{
	@(static) c : runtime.Context
	if msg == win32.WM_NCCREATE { c = (cast(^runtime.Context)((cast(^win32.CREATESTRUCTW)uintptr(lParam)).lpCreateParams))^ }
	context = c

	if im_win32.WndProcHandler(hWnd, msg, wParam, lParam) != {} { return 1 }

	switch msg {
		case win32.WM_SIZE:
			if wParam != win32.SIZE_MINIMIZED {
				g_resizeWidth = cast(u32)win32.LOWORD(lParam)
				g_resizeHeight = cast(u32)win32.HIWORD(lParam)
			}
			return 0

		case win32.WM_SYSCOMMAND:
			if (wParam & 0xfff0) == win32.SC_KEYMENU { return 0 } // Disable ALT application menu
			
		case win32.WM_DESTROY:
			win32.PostQuitMessage(0)
			return 0
	}

	return win32.DefWindowProcW(hWnd, msg, wParam, lParam)
}