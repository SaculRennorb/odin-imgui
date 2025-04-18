package imgui

// dear imgui: wrappers for C++ standard library (STL) types (std::string, etc.)
// This is also an example of how you may wrap your own similar types.

// Changelog:
// - v0.10: Initial version. Added InputText() / InputTextMultiline() calls with std::string

// See more C++ related extension (fmt, RAII, syntaxis sugar) on Wiki:
//   https://github.com/ocornut/imgui/wiki/Useful-Extensions#cness


when !(IMGUI_DISABLE) {


namespace ImGui
{
    // ImGui::InputText() with std::string
    // Because text input needs dynamic resizing, we need to setup a callback to grow the capacity
    bool  InputText(const char* label, std::string* str, ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = nullptr, rawptr user_data = nullptr);
    bool  InputTextMultiline(const char* label, std::string* str, const size := &ImVec2{0, 0}, ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = nullptr, rawptr user_data = nullptr);
    bool  InputTextWithHint(const char* label, const char* hint, std::string* str, ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = nullptr, rawptr user_data = nullptr);
}

} // #ifndef IMGUI_DISABLE
