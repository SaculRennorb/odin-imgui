package imgui

// dear imgui: wrappers for C++ standard library (STL) types (std::string, etc.)
// This is also an example of how you may wrap your own similar types.

// Changelog:
// - v0.10: Initial version. Added InputText() / InputTextMultiline() calls with std::string

// See more C++ related extension (fmt, RAII, syntaxis sugar) on Wiki:
//   https://github.com/ocornut/imgui/wiki/Useful-Extensions#cness

when !(IMGUI_DISABLE) {

// Clang warnings with -Weverything

InputTextCallback_UserData :: struct
{
    std::string*            Str;
    ChainCallback : ImGuiInputTextCallback
    ChainCallbackUserData : rawptr
};

InputTextCallback :: proc(data : ^ImGuiInputTextCallbackData) -> int
{
    user_data := (InputTextCallback_UserData*)data.UserData;
    if (data.EventFlag == ImGuiInputTextFlags_CallbackResize)
    {
        // Resize string callback
        // If for some reason we refuse the new length (BufTextLen) and/or capacity (BufSize) we need to set them back to what we want.
        std::string* str = user_data.Str;
        assert(data.Buf == str.c_str());
        str.resize(data.BufTextLen);
        data.Buf = (char*)str.c_str();
    }
    else if (user_data->ChainCallback)
    {
        // Forward to user callback, if any
        data.UserData = user_data.ChainCallbackUserData;
        return user_data.ChainCallback(data);
    }
    return 0;
}

InputText :: proc(label : ^char, std::str : ^string, flags : ImGuiInputTextFlags, callback : ImGuiInputTextCallback = {}, user_data : rawptr = nullptr) -> bool
{
    assert((flags & ImGuiInputTextFlags_CallbackResize) == 0);
    flags |= ImGuiInputTextFlags_CallbackResize;

    cb_user_data : InputTextCallback_UserData
    cb_user_data.Str = str;
    cb_user_data.ChainCallback = callback;
    cb_user_data.ChainCallbackUserData = user_data;
    return InputText(label, (char*)str.c_str(), str.capacity() + 1, flags, InputTextCallback, &cb_user_data);
}

InputTextMultiline :: proc(label : ^char, std::str : ^string, size : ImVec2, flags : ImGuiInputTextFlags, callback : ImGuiInputTextCallback = {}, user_data : rawptr = {}) -> bool
{
    assert((flags & ImGuiInputTextFlags_CallbackResize) == 0);
    flags |= ImGuiInputTextFlags_CallbackResize;

    cb_user_data : InputTextCallback_UserData
    cb_user_data.Str = str;
    cb_user_data.ChainCallback = callback;
    cb_user_data.ChainCallbackUserData = user_data;
    return InputTextMultiline(label, (char*)str.c_str(), str.capacity() + 1, size, flags, InputTextCallback, &cb_user_data);
}

InputTextWithHint :: proc(label : ^char, hint : ^char, std::str : ^string, flags : ImGuiInputTextFlags, callback : ImGuiInputTextCallback, user_data : rawptr = {}) -> bool
{
    assert((flags & ImGuiInputTextFlags_CallbackResize) == 0);
    flags |= ImGuiInputTextFlags_CallbackResize;

    cb_user_data : InputTextCallback_UserData
    cb_user_data.Str = str;
    cb_user_data.ChainCallback = callback;
    cb_user_data.ChainCallbackUserData = user_data;
    return InputTextWithHint(label, hint, (char*)str.c_str(), str.capacity() + 1, flags, InputTextCallback, &cb_user_data);
}


} // #ifndef IMGUI_DISABLE
