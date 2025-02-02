package imgui

//TODO(Rennorb): All of this is untested

//-----------------------------------------------------------------------------
// [SECTION] PLATFORM DEPENDENT HELPERS
//-----------------------------------------------------------------------------
// - Default clipboard handlers
// - Default shell function handlers
// - Default IME handlers
//-----------------------------------------------------------------------------

when IMGUI_ENABLE_OSX_DEFAULT_CLIPBOARD_FUNCTIONS {

	main_clipboard : PasteboardRef = 0;

	// OSX clipboard implementation
	// If you enable this you will need to add '-framework ApplicationServices' to your linker command-line!
	Platform_SetClipboardTextFn_DefaultImpl :: proc(_ : ^ImGuiContext, text : ^u8)
	{
		if (!main_clipboard) {
			PasteboardCreate(kPasteboardClipboard, &main_clipboard);
		}

		PasteboardClear(main_clipboard);
		cf_data := CFDataCreate(kCFAllocatorDefault, cast(^u8)text, strlen(text));
		if (cf_data)
		{
			PasteboardPutItemFlavor(main_clipboard, cast(PasteboardItemID)1, CFSTR("public.utf8-plain-text"), cf_data, 0);
			CFRelease(cf_data);
		}
	}

	Platform_GetClipboardTextFn_DefaultImpl :: proc(ctx : ^ImGuiContext) -> ^u8
	{
		g := ctx;
		if (!main_clipboard) {
			PasteboardCreate(kPasteboardClipboard, &main_clipboard);
		}

		PasteboardSynchronize(main_clipboard);

		item_count := 0;
		PasteboardGetItemCount(main_clipboard, &item_count);
		for i : ItemCount = 0; i < item_count; i += 1
		{
			item_id := 0;
			PasteboardGetItemIdentifier(main_clipboard, i + 1, &item_id);
			flavor_type_array := 0;
			PasteboardCopyItemFlavors(main_clipboard, item_id, &flavor_type_array);
			for j, nj : CFIndex = CFArrayGetCount(flavor_type_array); j < nj; j += 1
			{
				cf_data : CFDataRef
				if (PasteboardCopyItemFlavorData(main_clipboard, item_id, CFSTR("public.utf8-plain-text"), &cf_data) == noErr)
				{
					g.ClipboardHandlerData.clear();
					length := cast(i32) CFDataGetLength(cf_data);
					g.ClipboardHandlerData.resize(length + 1);
					CFDataGetBytes(cf_data, CFRangeMake(0, length), cast(^u8)g.ClipboardHandlerData.Data);
					g.ClipboardHandlerData[length] = 0;
					CFRelease(cf_data);
					return g.ClipboardHandlerData.Data;
				}
			}
		}
		return nil;
	}

}