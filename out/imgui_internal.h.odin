package imgui

// dear imgui, v1.91.7 WIP
// (internal structures/api)

// You may use this file to debug, understand or extend Dear ImGui features but we don't provide any guarantee of forward compatibility.

/*

Index of this file:

// [SECTION] Header mess
// [SECTION] Forward declarations
// [SECTION] Context pointer
// [SECTION] STB libraries includes
// [SECTION] Macros
// [SECTION] Generic helpers
// [SECTION] ImDrawList support
// [SECTION] Data types support
// [SECTION] Widgets support: flags, enums, data structures
// [SECTION] Popup support
// [SECTION] Inputs support
// [SECTION] Clipper support
// [SECTION] Navigation support
// [SECTION] Typing-select support
// [SECTION] Columns support
// [SECTION] Box-select support
// [SECTION] Multi-select support
// [SECTION] Docking support
// [SECTION] Viewport support
// [SECTION] Settings support
// [SECTION] Localization support
// [SECTION] Error handling, State recovery support
// [SECTION] Metrics, Debug tools
// [SECTION] Generic context hooks
// [SECTION] ImGuiContext (main imgui context)
// [SECTION] ImGuiWindowTempData, ImGuiWindow
// [SECTION] Tab bar, Tab item support
// [SECTION] Table support
// [SECTION] ImGui internal API
// [SECTION] ImFontAtlas internal API
// [SECTION] Test Engine specific hooks (imgui_test_engine)

*/

when !(IMGUI_DISABLE) {

//-----------------------------------------------------------------------------
// [SECTION] Header mess
//-----------------------------------------------------------------------------

when !(IMGUI_VERSION) {
}


// Enable SSE intrinsics if available
when (defined __SSE__ || defined __x86_64__ || defined _M_X64 || (defined(_M_IX86_FP) && (_M_IX86_FP >= 1))) && !defined(IMGUI_DISABLE_SSE) {
IMGUI_ENABLE_SSE :: true
when (defined __AVX__ || defined __SSE4_2__) {
IMGUI_ENABLE_SSE4_2 :: true
}
}
// Emscripten has partial SSE 4.2 support where _mm_crc32_u32 is not available. See https://emscripten.org/docs/porting/simd.html#id11 and #8213
when defined(IMGUI_ENABLE_SSE4_2) && !defined(IMGUI_USE_LEGACY_CRC32_ADLER) && !defined(__EMSCRIPTEN__) {
IMGUI_ENABLE_SSE4_2_CRC :: true
}

// Visual Studio warnings
when _MSC_VER {
when defined(_MSC_VER) && _MSC_VER >= 1922 { // MSVC 2019 16.2 or later
}
}

// Clang/GCC warnings with -Weverything

// In 1.89.4, we moved the implementation of "courtesy maths operators" from imgui_internal.h in imgui.h
// As they are frequently requested, we do not want to encourage to many people using imgui_internal.h
when defined(IMGUI_DEFINE_MATH_OPERATORS) && !defined(IMGUI_DEFINE_MATH_OPERATORS_IMPLEMENTED) {
#error Please '#define IMGUI_DEFINE_MATH_OPERATORS' _BEFORE_ including imgui.h!
}

// Legacy defines

// Enable stb_truetype by default unless FreeType is enabled.
// You can compile with both by defining both IMGUI_ENABLE_FREETYPE and IMGUI_ENABLE_STB_TRUETYPE together.
when !(IMGUI_ENABLE_FREETYPE) {
IMGUI_ENABLE_STB_TRUETYPE :: true
}

//-----------------------------------------------------------------------------
// [SECTION] Forward declarations
//-----------------------------------------------------------------------------


// Enumerations
// Use your programming IDE "Go to definition" facility on the names of the center columns to find the actual flags/enum lists.

// Flags

//-----------------------------------------------------------------------------
// [SECTION] Context pointer
// See implementation of this variable in imgui.cpp for comments and details.
//-----------------------------------------------------------------------------

when !(GImGui) {
extern ImGuiContext* GImGui;  // Current implicit context pointer
}

//-----------------------------------------------------------------------------
// [SECTION] Macros
//-----------------------------------------------------------------------------

// Internal Drag and Drop payload types. String starting with '_' are reserved for Dear ImGui.
IMGUI_PAYLOAD_TYPE_WINDOW :: "_IMWINDOW"     // Payload == ImGuiWindow*

// Debug Printing Into TTY
// (since IMGUI_VERSION_NUM >= 18729: IMGUI_DEBUG_LOG was reworked into IMGUI_DEBUG_PRINTF (and removed framecount from it). If you were using a #define IMGUI_DEBUG_LOG please rename)
when !(IMGUI_DEBUG_PRINTF) {
when !(IMGUI_DISABLE_DEFAULT_FORMAT_FUNCTIONS) {
#define IMGUI_DEBUG_PRINTF(_FMT,...)    printf(_FMT, __VA_ARGS__)
} else {
#define IMGUI_DEBUG_PRINTF(_FMT,...)    ((void)0)
}
}

// Debug Logging for ShowDebugLogWindow(). This is designed for relatively rare events so please don't spam.
#define IMGUI_DEBUG_LOG_ERROR(...)      do { ImGuiContext& g2 = *GImGui; if (g2.DebugLogFlags & ImGuiDebugLogFlags_EventError) IMGUI_DEBUG_LOG(__VA_ARGS__); else g2.DebugLogSkippedErrors++; } while (0)
#define IMGUI_DEBUG_LOG_ACTIVEID(...)   do { if (g.DebugLogFlags & ImGuiDebugLogFlags_EventActiveId)    IMGUI_DEBUG_LOG(__VA_ARGS__); } while (0)
#define IMGUI_DEBUG_LOG_FOCUS(...)      do { if (g.DebugLogFlags & ImGuiDebugLogFlags_EventFocus)       IMGUI_DEBUG_LOG(__VA_ARGS__); } while (0)
#define IMGUI_DEBUG_LOG_POPUP(...)      do { if (g.DebugLogFlags & ImGuiDebugLogFlags_EventPopup)       IMGUI_DEBUG_LOG(__VA_ARGS__); } while (0)
#define IMGUI_DEBUG_LOG_NAV(...)        do { if (g.DebugLogFlags & ImGuiDebugLogFlags_EventNav)         IMGUI_DEBUG_LOG(__VA_ARGS__); } while (0)
#define IMGUI_DEBUG_LOG_SELECTION(...)  do { if (g.DebugLogFlags & ImGuiDebugLogFlags_EventSelection)   IMGUI_DEBUG_LOG(__VA_ARGS__); } while (0)
#define IMGUI_DEBUG_LOG_CLIPPER(...)    do { if (g.DebugLogFlags & ImGuiDebugLogFlags_EventClipper)     IMGUI_DEBUG_LOG(__VA_ARGS__); } while (0)
#define IMGUI_DEBUG_LOG_IO(...)         do { if (g.DebugLogFlags & ImGuiDebugLogFlags_EventIO)          IMGUI_DEBUG_LOG(__VA_ARGS__); } while (0)
#define IMGUI_DEBUG_LOG_FONT(...)       do { if (g.DebugLogFlags & ImGuiDebugLogFlags_EventFont)        IMGUI_DEBUG_LOG(__VA_ARGS__); } while (0)
#define IMGUI_DEBUG_LOG_INPUTROUTING(...) do{if (g.DebugLogFlags & ImGuiDebugLogFlags_EventInputRouting)IMGUI_DEBUG_LOG(__VA_ARGS__); } while (0)
#define IMGUI_DEBUG_LOG_DOCKING(...)    do { if (g.DebugLogFlags & ImGuiDebugLogFlags_EventDocking)     IMGUI_DEBUG_LOG(__VA_ARGS__); } while (0)
#define IMGUI_DEBUG_LOG_VIEWPORT(...)   do { if (g.DebugLogFlags & ImGuiDebugLogFlags_EventViewport)    IMGUI_DEBUG_LOG(__VA_ARGS__); } while (0)

// Static Asserts

// "Paranoid" Debug Asserts are meant to only be enabled during specific debugging/work, otherwise would slow down the code too much.
// We currently don't have many of those so the effect is currently negligible, but onward intent to add more aggressive ones in the code.
IMGUI_DEBUG_PARANOID :: false
when IMGUI_DEBUG_PARANOID {
} else {
}

// Misc Macros
IM_PI :: 3.14159265358979323846f
when _WIN32 {
IM_NEWLINE :: "\r\n"   // Play it nice with Windows users (Update: since 2018-05, Notepad finally appears to support Unix-style carriage returns!)
} else {
IM_NEWLINE :: "\n"
}
when !(IM_TABSIZE) {                      // Until we move this to runtime and/or add proper tab support, at least allow users to compile-time override
#define IM_TABSIZE                      (4)
}
#define IM_F32_TO_INT8_UNBOUND(_VAL)    ((int)((_VAL) * 255.0f + ((_VAL)>=0 ? 0.5f : -0.5f)))   // Unsaturated, for display purpose
#define IM_F32_TO_INT8_SAT(_VAL)        ((int)(ImSaturate(_VAL) * 255.0f + 0.5f))               // Saturated, always output 0..255
#define IM_STRINGIFY_HELPER(_X)         #_X
#define IM_STRINGIFY(_X)                IM_STRINGIFY_HELPER(_X)                                 // Preprocessor idiom to stringify e.g. an integer.

// Hint for branch prediction
when (defined(__cplusplus) && (__cplusplus >= 202002L)) || (defined(_MSVC_LANG) && (_MSVC_LANG >= 202002L)) {
} else {
}

// Enforce cdecl calling convention for functions called by the standard library, in case compilation settings changed the default to e.g. __vectorcall
when _MSC_VER {
} else {
}

// Warnings
when defined(_MSC_VER) && !defined(__clang__) {
} else {
}

// Debug Tools
// Use 'Metrics/Debugger->Tools->Item Picker' to break into the call-stack of a specific item.
// This will call IM_DEBUG_BREAK() which you may redefine yourself. See https://github.com/scottt/debugbreak for more reference.
when !(IM_DEBUG_BREAK) {
when defined (_MSC_VER) {
} else when defined(__GNUC__) && (defined(__i386__) || defined(__x86_64__)) {
} else when defined(__GNUC__) && defined(__thumb__) {
} else when defined(__GNUC__) && defined(__arm__) && !defined(__thumb__) {
} else {
}
} // #ifndef IM_DEBUG_BREAK

// Format specifiers, printing 64-bit hasn't been decently standardized...
// In a real application you should be using PRId64 and PRIu64 from <inttypes.h> (non-windows) and on Windows define them yourself.
when defined(_MSC_VER) && !defined(__clang__) {
IM_PRId64 :: "I64d"
IM_PRIu64 :: "I64u"
IM_PRIX64 :: "I64X"
} else {
IM_PRId64 :: "lld"
IM_PRIu64 :: "llu"
IM_PRIX64 :: "llX"
}

//-----------------------------------------------------------------------------
// [SECTION] Generic helpers
// Note that the ImXXX helpers functions are lower-level than ImGui functions.
// ImGui functions or the ImGui context are never called/used from other ImXXX functions.
//-----------------------------------------------------------------------------
// - Helpers: Hashing
// - Helpers: Sorting
// - Helpers: Bit manipulation
// - Helpers: String
// - Helpers: Formatting
// - Helpers: UTF-8 <> wchar conversions
// - Helpers: ImVec2/ImVec4 operators
// - Helpers: Maths
// - Helpers: Geometry
// - Helper: ImVec1
// - Helper: ImVec2ih
// - Helper: ImRect
// - Helper: ImBitArray
// - Helper: ImBitVector
// - Helper: ImSpan<>, ImSpanAllocator<>
// - Helper: ImPool<>
// - Helper: ImChunkStream<>
// - Helper: ImGuiTextIndex
// - Helper: ImGuiStorage
//-----------------------------------------------------------------------------

// Helpers: Hashing
ImHashData := ImGuiID(const rawptr data, int data_size, ImGuiID seed = 0);
ImHashStr := ImGuiID(const u8* data, int data_size = 0, ImGuiID seed = 0);

// Helpers: Sorting
when !(ImQsort) {
inline void      ImQsort(rawptr base, int count, int size_of_element, i32(IMGUI_CDECL *compare_func)(void const*, void const*)) { if (count > 1) qsort(base, count, size_of_element, compare_func); }
}

// Helpers: Color Blending
u32         ImAlphaBlendColors(u32 col_a, u32 col_b);

// Helpers: Bit manipulation
inline bool      math.is_power_of_two(i32 v)           { return v != 0 && (v & (v - 1)) == 0; }
inline bool      math.is_power_of_two(u64 v)         { return v != 0 && (v & (v - 1)) == 0; }
inline i32       ImUpperPowerOfTwo(i32 v)        { v -= 1; v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16; v += 1; return v; }

// Helpers: String
i32           ImStricmp(const u8* str1, const u8* str2);                      // Case insensitive compare.
i32           ImStrnicmp(const u8* str1, const u8* str2, int count);       // Case insensitive compare to a certain count.
void          ImStrncpy(u8* dst, const u8* src, int count);                // Copy to a certain count and always zero terminate (strncpy doesn't).
u8*         ImStrdup(const u8* str);                                          // Duplicate a string.
u8*         ImStrdupcpy(u8* dst, int* p_dst_size, const u8* str);        // Copy in provided buffer, recreate buffer if needed.
const u8*   ImStrchrRange(const u8* str_begin, const u8* str_end, u8 c);  // Find first occurrence of 'c' in string range.
const u8*   ImStreolRange(const u8* str, const u8* str_end);                // End end-of-line
const u8*   ImStristr(const u8* haystack, const u8* haystack_end, const u8* needle, const u8* needle_end);  // Find a substring in a string range.
void          ImStrTrimBlanks(u8* str);                                         // Remove leading and trailing blanks from a buffer.
const u8*   ImStrSkipBlank(const u8* str);                                    // Find first non-blank character.
i32           ImStrlenW(const ImWchar* str);                                      // Computer string length (ImWchar string)
const u8*   ImStrbol(const u8* buf_mid_line, const u8* buf_begin);          // Find beginning-of-line
inline u8      ImToUpper(u8 c)               { return (c >= 'a' && c <= 'z') ? c &= ~32 : c; }
inline bool      ImCharIsBlankA(u8 c)          { return c == ' ' || c == '\t'; }
inline bool      ImCharIsBlankW(u32 c)  { return c == ' ' || c == '\t' || c == 0x3000; }
inline bool      ImCharIsXdigitA(u8 c)         { return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f'); }

// Helpers: Formatting
i32           ImFormatString(u8* buf, int buf_size, const u8* fmt, ...) ;
i32           ImFormatStringV(u8* buf, int buf_size, const u8* fmt, va_list args) ;
void          ImFormatStringToTempBuffer(const u8** out_buf, const u8** out_buf_end, const u8* fmt, ...) ;
void          ImFormatStringToTempBufferV(const u8** out_buf, const u8** out_buf_end, const u8* fmt, va_list args) ;
const u8*   ImParseFormatFindStart(const u8* format);
const u8*   ImParseFormatFindEnd(const u8* format);
const u8*   ImParseFormatTrimDecorations(const u8* format, u8* buf, int buf_size);
void          ImParseFormatSanitizeForPrinting(const u8* fmt_in, u8* fmt_out, int fmt_out_size);
const u8*   ImParseFormatSanitizeForScanning(const u8* fmt_in, u8* fmt_out, int fmt_out_size);
i32           ImParseFormatPrecision(const u8* format, i32 default_value);

// Helpers: UTF-8 <> wchar conversions
const u8*   ImTextCharToUtf8(u8 out_buf[5], u32 c);                                                      // return out_buf
i32           ImTextStrToUtf8(u8* out_buf, i32 out_buf_size, const ImWchar* in_text, const ImWchar* in_text_end);   // return output UTF-8 bytes count
i32           ImTextCharFromUtf8(u32* out_char, const u8* in_text, const u8* in_text_end);               // read one character. return input UTF-8 bytes count
i32           ImTextStrFromUtf8(ImWchar* out_buf, i32 out_buf_size, const u8* in_text, const u8* in_text_end, const u8** in_remaining = nil);   // return input UTF-8 bytes count
i32           ImTextCountCharsFromUtf8(const u8* in_text, const u8* in_text_end);                                 // return number of UTF-8 code-points (NOT bytes count)
i32           ImTextCountUtf8BytesFromChar(const u8* in_text, const u8* in_text_end);                             // return number of bytes to express one char in UTF-8
i32           ImTextCountUtf8BytesFromStr(const ImWchar* in_text, const ImWchar* in_text_end);                        // return number of bytes to express string in UTF-8
const u8*   ImTextFindPreviousUtf8Codepoint(const u8* in_text_start, const u8* in_text_curr);                   // return previous UTF-8 code-point.
i32           ImTextCountLines(const u8* in_text, const u8* in_text_end);                                         // return number of lines taken by text. trailing carriage return doesn't count as an extra line.

// Helpers: File System
when IMGUI_DISABLE_FILE_FUNCTIONS {
IMGUI_DISABLE_DEFAULT_FILE_FUNCTIONS :: true
ImFileHandle :: rawptr
inline ImFileHandle  ImFileOpen(const u8*, const u8*)                    { return nil; }
inline bool          ImFileClose(ImFileHandle)                               { return false; }
inline u64         ImFileGetSize(ImFileHandle)                             { return (u64)-1; }
inline u64         ImFileRead(rawptr, u64, u64, ImFileHandle)           { return 0; }
inline u64         ImFileWrite(const rawptr, u64, u64, ImFileHandle)    { return 0; }
}
when !(IMGUI_DISABLE_DEFAULT_FILE_FUNCTIONS) {
ImFileHandle :: ^FILE
ImFileOpen := ImFileHandle(const u8* filename, const u8* mode);
bool              ImFileClose(ImFileHandle file);
u64             ImFileGetSize(ImFileHandle file);
u64             ImFileRead(rawptr data, u64 size, u64 count, ImFileHandle file);
u64             ImFileWrite(const rawptr data, u64 size, u64 count, ImFileHandle file);
} else {
IMGUI_DISABLE_TTY_FUNCTIONS :: true // Can't use stdout, fflush if we are not using default file functions
}
rawptr             ImFileLoadToMemory(const u8* filename, const u8* mode, int* out_file_size = nil, i32 padding_bytes = 0);

// Helpers: Maths
// - Wrapper for standard libs functions. (Note that imgui_demo.cpp does _not_ use them to keep the code easy to copy)
when !(IMGUI_DISABLE_DEFAULT_MATH_FUNCTIONS) {
#define ImFabs(X)           fabsf(X)
#define ImSqrt(X)           sqrtf(X)
#define ImFmod(X, Y)        fmodf((X), (Y))
#define ImCos(X)            cosf(X)
#define ImSin(X)            sinf(X)
#define ImAcos(X)           acosf(X)
#define ImAtan2(Y, X)       atan2f((Y), (X))
#define ImAtof(STR)         atof(STR)
#define ImCeil(X)           ceilf(X)
inline f32  ImPow(f32 x, f32 y)    { return powf(x, y); }          // DragBehaviorT/SliderBehaviorT uses ImPow with either float/double and need the precision
inline f64 ImPow(f64 x, f64 y)  { return pow(x, y); }
inline f32  ImLog(f32 x)             { return logf(x); }             // DragBehaviorT/SliderBehaviorT uses ImLog with either float/double and need the precision
inline f64 ImLog(f64 x)            { return log(x); }
inline i32    ImAbs(i32 x)               { return x < 0 ? -x : x; }
inline f32  ImAbs(f32 x)             { return fabsf(x); }
inline f64 ImAbs(f64 x)            { return fabs(x); }
inline f32  ImSign(f32 x)            { return (x < 0.0) ? -1.0 : (x > 0.0) ? 1.0 : 0.0; } // Sign operator - returns -1, 0 or 1 based on sign of argument
inline f64 ImSign(f64 x)           { return (x < 0.0) ? -1.0 : (x > 0.0) ? 1.0 : 0.0; }
when IMGUI_ENABLE_SSE {
inline f32  linalg.inverse_sqrt(f32 x)           { return _mm_cvtss_f32(_mm_rsqrt_ss(_mm_set_ss(x))); }
} else {
inline f32  linalg.inverse_sqrt(f32 x)           { return 1.0 / sqrtf(x); }
}
inline f64 linalg.inverse_sqrt(f64 x)          { return 1.0 / sqrt(x); }
}
// - ImMin/ImMax/ImClamp/ImLerp/ImSwap are used by widgets which support variety of types: signed/unsigned int/long long float/double
// (Exceptionally using templates here but we could also redefine them for those types)
template<typename T> static inline T ImMin(T lhs, T rhs)                        { return lhs < rhs ? lhs : rhs; }
template<typename T> static inline T ImMax(T lhs, T rhs)                        { return lhs >= rhs ? lhs : rhs; }
template<typename T> static inline T ImClamp(T v, T mn, T mx)                   { return (v < mn) ? mn : (v > mx) ? mx : v; }
template<typename T> static inline T ImLerp(T a, T b, f32 t)                  { return (T)(a + (b - a) * (T)t); }
template<typename T> static inline void ImSwap(T& a, T& b)                      { T tmp = a; a = b; b = tmp; }
template<typename T> static inline T ImAddClampOverflow(T a, T b, T mn, T mx)   { if (b < 0 && (a < mn - b)) return mn; if (b > 0 && (a > mx - b)) return mx; return a + b; }
template<typename T> static inline T ImSubClampOverflow(T a, T b, T mn, T mx)   { if (b > 0 && (a < mn + b)) return mn; if (b < 0 && (a > mx + b)) return mx; return a - b; }
// - Misc maths helpers
inline ImVec2 ImMin(const ImVec2& lhs, const ImVec2& rhs)                { return ImVec2{lhs.x < rhs.x ? lhs.x : rhs.x, lhs.y < rhs.y ? lhs.y : rhs.y}; }
inline ImVec2 ImMax(const ImVec2& lhs, const ImVec2& rhs)                { return ImVec2{lhs.x >= rhs.x ? lhs.x : rhs.x, lhs.y >= rhs.y ? lhs.y : rhs.y}; }
inline ImVec2 ImClamp(const ImVec2& v, const ImVec2&mn, const ImVec2&mx) { return ImVec2{(v.x < mn.x} ? mn.x : (v.x > mx.x) ? mx.x : v.x, (v.y < mn.y) ? mn.y : (v.y > mx.y) ? mx.y : v.y); }
inline ImVec2 ImLerp(const ImVec2& a, const ImVec2& b, f32 t)          { return ImVec2{a.x + (b.x - a.x} * t, a.y + (b.y - a.y) * t); }
inline ImVec2 ImLerp(const ImVec2& a, const ImVec2& b, const ImVec2& t)  { return ImVec2{a.x + (b.x - a.x} * t.x, a.y + (b.y - a.y) * t.y); }
inline ImVec4 ImLerp(const ImVec4& a, const ImVec4& b, f32 t)          { return ImVec4{a.x + (b.x - a.x} * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t, a.w + (b.w - a.w) * t); }
inline f32  ImSaturate(f32 f)                                        { return (f < 0.0) ? 0.0 : (f > 1.0) ? 1.0 : f; }
inline f32  ImLengthSqr(const ImVec2& lhs)                             { return (lhs.x * lhs.x) + (lhs.y * lhs.y); }
inline f32  ImLengthSqr(const ImVec4& lhs)                             { return (lhs.x * lhs.x) + (lhs.y * lhs.y) + (lhs.z * lhs.z) + (lhs.w * lhs.w); }
inline f32  ImInvLength(const ImVec2& lhs, f32 fail_value)           { f32 d = (lhs.x * lhs.x) + (lhs.y * lhs.y); if (d > 0.0) return linalg.inverse_sqrt(d); return fail_value; }
inline f32  ImTrunc(f32 f)                                           { return (f32)(i32)(f); }
inline ImVec2 ImTrunc(const ImVec2& v)                                   { return ImVec2{(f32}(i32)(v.x), (f32)(i32)(v.y)); }
inline f32  ImFloor(f32 f)                                           { return (f32)((f >= 0 || (f32)cast(i32) f == f) ? cast(t(2) 2) 2cast( 2c) st( 2c) s // Decent replacement for floorf()
inline ImVec2 ImFloor(const ImVec2& v)                                   { return ImVec2{ImFloor(v.x}, ImFloor(v.y)); }
inline i32    ImModPositive(i32 a, i32 b)                                { return (a + b) % b; }
inline f32  ImDot(const ImVec2& a, const ImVec2& b)                    { return a.x * b.x + a.y * b.y; }
inline ImVec2 ImRotate(const ImVec2& v, f32 cos_a, f32 sin_a)        { return ImVec2{v.x * cos_a - v.y * sin_a, v.x * sin_a + v.y * cos_a}; }
inline f32  ImLinearSweep(f32 current, f32 target, f32 speed)    { if (current < target) return ImMin(current + speed, target); if (current > target) return ImMax(current - speed, target); return current; }
inline f32  ImLinearRemapClamp(f32 s0, f32 s1, f32 d0, f32 d1, f32 x) { return ImSaturate((x - s0) / (s1 - s0)) * (d1 - d0) + d0; }
inline ImVec2 ImMul(const ImVec2& lhs, const ImVec2& rhs)                { return ImVec2{lhs.x * rhs.x, lhs.y * rhs.y}; }
inline bool   ImIsFloatAboveGuaranteedIntegerPrecision(f32 f)          { return f <= -16777216 || f >= 16777216; }
inline f32  ImExponentialMovingAverage(f32 avg, f32 sample, i32 n) { avg -= avg / n; avg += sample / n; return avg; }

// Helpers: Geometry
ImBezierCubicCalc := ImVec2{const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, f32 t};
ImBezierCubicClosestPoint := ImVec2{const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, const ImVec2& p, i32 num_segments};       // For curves with explicit number of segments
ImBezierCubicClosestPointCasteljau := ImVec2{const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, const ImVec2& p, f32 tess_tol};// For auto-tessellated curves you can use tess_tol = style.CurveTessellationTol
ImBezierQuadraticCalc := ImVec2{const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, f32 t};
ImLineClosestPoint := ImVec2{const ImVec2& a, const ImVec2& b, const ImVec2& p};
bool       ImTriangleContainsPoint(const ImVec2& a, const ImVec2& b, const ImVec2& c, const ImVec2& p);
ImTriangleClosestPoint := ImVec2{const ImVec2& a, const ImVec2& b, const ImVec2& c, const ImVec2& p};
void       ImTriangleBarycentricCoords(const ImVec2& a, const ImVec2& b, const ImVec2& c, const ImVec2& p, f32& out_u, f32& out_v, f32& out_w);
inline f32         ImTriangleArea(const ImVec2& a, const ImVec2& b, const ImVec2& c)          { return ImFabs((a.x * (b.y - c.y)) + (b.x * (c.y - a.y)) + (c.x * (a.y - b.y))) * 0.5; }
inline bool          ImTriangleIsClockwise(const ImVec2& a, const ImVec2& b, const ImVec2& c)   { return ((b.x - a.x) * (c.y - b.y)) - ((c.x - b.x) * (b.y - a.y)) > 0.0; }

// Helper: ImVec1 (1D vector)
// (this odd construct is used to facilitate the transition between 1D and 2D, and the maintenance of some branches/patches)
ImVec1 :: struct
{
    x : f32,
    constexpr ImVec1{)         : x(0.0} { }
    constexpr ImVec1{f32 _x} : x(_x) { }
};

// Helper: ImVec2ih (2D vector, half-size integer, for long-term packed storage)
ImVec2ih :: struct
{
    x, y : i16,
    constexpr ImVec2ih()                           : x(0), y(0) {}
    constexpr ImVec2ih(i16 _x, i16 _y)         : x(_x), y(_y) {}
    constexpr explicit ImVec2ih(const ImVec2& rhs) : x(cast(ast) ast) asty(cast(sty) cast(sty)
};

// Helper: ImRect (2D axis aligned bounding-box)
// NB: we can't rely on ImVec2 math operators being available here!
ImRect :: struct
{
    Min : ImVec2,    // Upper-left
    Max : ImVec2,    // Lower-right

    constexpr ImRect()                                        : Min(0.0, 0.0), Max(0.0, 0.0)  {}
    constexpr ImRect(const ImVec2& min, const ImVec2& max)    : Min(min), Max(max)                {}
    constexpr ImRect(const ImVec4& v)                         : Min(v.x, v.y), Max(v.z, v.w)      {}
    constexpr ImRect(f32 x1, f32 y1, f32 x2, f32 y2)  : Min(x1, y1), Max(x2, y2)          {}

    ImVec2      GetCenter() const                   { return ImVec2{(Min.x + Max.x} * 0.5, (Min.y + Max.y) * 0.5); }
    ImVec2      GetSize() const                     { return ImVec2{Max.x - Min.x, Max.y - Min.y}; }
    f32       GetWidth() const                    { return Max.x - Min.x; }
    f32       GetHeight() const                   { return Max.y - Min.y; }
    f32       GetArea() const                     { return (Max.x - Min.x) * (Max.y - Min.y); }
    ImVec2      GetTL() const                       { return Min; }                   // Top-left
    ImVec2      GetTR() const                       { return ImVec2{Max.x, Min.y}; }  // Top-right
    ImVec2      GetBL() const                       { return ImVec2{Min.x, Max.y}; }  // Bottom-left
    ImVec2      GetBR() const                       { return Max; }                   // Bottom-right
    bool        Contains(const ImVec2& p) const     { return p.x     >= Min.x && p.y     >= Min.y && p.x     <  Max.x && p.y     <  Max.y; }
    bool        Contains(const ImRect& r) const     { return r.Min.x >= Min.x && r.Min.y >= Min.y && r.Max.x <= Max.x && r.Max.y <= Max.y; }
    bool        ContainsWithPad(const ImVec2& p, const ImVec2& pad) const { return p.x >= Min.x - pad.x && p.y >= Min.y - pad.y && p.x < Max.x + pad.x && p.y < Max.y + pad.y; }
    bool        Overlaps(const ImRect& r) const     { return r.Min.y <  Max.y && r.Max.y >  Min.y && r.Min.x <  Max.x && r.Max.x >  Min.x; }
    void        Add(const ImVec2& p)                { if (Min.x > p.x)     Min.x = p.x;     if (Min.y > p.y)     Min.y = p.y;     if (Max.x < p.x)     Max.x = p.x;     if (Max.y < p.y)     Max.y = p.y; }
    void        Add(const ImRect& r)                { if (Min.x > r.Min.x) Min.x = r.Min.x; if (Min.y > r.Min.y) Min.y = r.Min.y; if (Max.x < r.Max.x) Max.x = r.Max.x; if (Max.y < r.Max.y) Max.y = r.Max.y; }
    void        Expand(const f32 amount)          { Min.x -= amount;   Min.y -= amount;   Max.x += amount;   Max.y += amount; }
    void        Expand(const ImVec2& amount)        { Min.x -= amount.x; Min.y -= amount.y; Max.x += amount.x; Max.y += amount.y; }
    void        Translate(const ImVec2& d)          { Min.x += d.x; Min.y += d.y; Max.x += d.x; Max.y += d.y; }
    void        TranslateX(f32 dx)                { Min.x += dx; Max.x += dx; }
    void        TranslateY(f32 dy)                { Min.y += dy; Max.y += dy; }
    void        ClipWith(const ImRect& r)           { Min = ImMax(Min, r.Min); Max = ImMin(Max, r.Max); }                   // Simple version, may lead to an inverted rectangle, which is fine for Contains/Overlaps test but not for display.
    void        ClipWithFull(const ImRect& r)       { Min = ImClamp(Min, r.Min, r.Max); Max = ImClamp(Max, r.Min, r.Max); } // Full version, ensure both points are fully clipped.
    void        Floor()                             { Min.x = math.trunc(Min.x); Min.y = math.trunc(Min.y); Max.x = math.trunc(Max.x); Max.y = math.trunc(Max.y); }
    bool        IsInverted() const                  { return Min.x > Max.x || Min.y > Max.y; }
    ImVec4      ToVec4() const                      { return ImVec4{Min.x, Min.y, Max.x, Max.y}; }
};

// Helper: ImBitArray
#define         IM_BITARRAY_TESTBIT(_ARRAY, _N)                 ((_ARRAY[(_N) >> 5] & ((ImU32)1 << ((_N) & 31))) != 0) // Macro version of ImBitArrayTestBit(): ensure args have side-effect or are costly!
#define         IM_BITARRAY_CLEARBIT(_ARRAY, _N)                ((_ARRAY[(_N) >> 5] &= ~((ImU32)1 << ((_N) & 31))))    // Macro version of ImBitArrayClearBit(): ensure args have side-effect or are costly!
inline int   ImBitArrayGetStorageSizeInBytes(i32 bitcount)   { return (int)((bitcount + 31) >> 5) << 2; }
inline void     ImBitArrayClearAllBits(u32* arr, i32 bitcount){ memset(arr, 0, ImBitArrayGetStorageSizeInBytes(bitcount)); }
inline bool     ImBitArrayTestBit(const u32* arr, i32 n)      { u32 mask = cast(ast) ast) an & 31); return (arr[n >> 5] & mask) != 0; }
inline void     ImBitArrayClearBit(u32* arr, i32 n)           { u32 mask = cast(ast) ast) an & 31); arr[n >> 5] &= ~mask; }
inline void     ImBitArraySetBit(u32* arr, i32 n)             { u32 mask = cast(ast) ast) an & 31); arr[n >> 5] |= mask; }
inline void     ImBitArraySetBitRange(u32* arr, i32 n, i32 n2) // Works on range [n..n2)
{
    n2 -= 1;
    for n <= n2
    {
        a_mod := (n & 31);
        b_mod := (n2 > (n | 31) ? 31 : (n2 & 31)) + 1;
        mask := (u32)((cast(ast) ast) a_mod) - 1) & ~(u32)((cast(2)() cast(2)() c - 1);
        arr[n >> 5] |= mask;
        n = (n + 32) & ~31;
    }
}

ImBitArrayPtr :: ^u32 // Name for use in structs

// Helper: ImBitArray class (wrapper over ImBitArray functions)
// Store 1-bit per value.
template<i32 BITCOUNT, i32 OFFSET = 0>
ImBitArray :: struct
{
    Storage : [(BITCOUNT + 31) >> 5]u32,
    ImBitArray()                                { ClearAllBits(); }
    void            ClearAllBits()              { memset(Storage, 0, size_of(Storage)); }
    void            SetAllBits()                { memset(Storage, 255, size_of(Storage)); }
    bool            TestBit(i32 n) const        { n += OFFSET; assert(n >= 0 && n < BITCOUNT); return IM_BITARRAY_TESTBIT(Storage, n); }
    void            SetBit(i32 n)               { n += OFFSET; assert(n >= 0 && n < BITCOUNT); ImBitArraySetBit(Storage, n); }
    void            ClearBit(i32 n)             { n += OFFSET; assert(n >= 0 && n < BITCOUNT); ImBitArrayClearBit(Storage, n); }
    void            SetBitRange(i32 n, i32 n2)  { n += OFFSET; n2 += OFFSET; assert(n >= 0 && n < BITCOUNT && n2 > n && n2 <= BITCOUNT); ImBitArraySetBitRange(Storage, n, n2); } // Works on range [n..n2)
    bool            operator[](i32 n) const     { n += OFFSET; assert(n >= 0 && n < BITCOUNT); return IM_BITARRAY_TESTBIT(Storage, n); }
};

// Helper: ImBitVector
// Store 1-bit per value.
ImBitVector :: struct
{
    Storage : [dynamic]u32,
    void            Create(i32 sz)              { Storage.resize((sz + 31) >> 5); memset(Storage.Data, 0, cast(ast) ast) get) ge * size_of(Storage.Data[0])); }
    void            Clear()                     { Storage.clear(); }
    bool            TestBit(i32 n) const        { assert(n < (Storage.Size << 5)); return IM_BITARRAY_TESTBIT(Storage.Data, n); }
    void            SetBit(i32 n)               { assert(n < (Storage.Size << 5)); ImBitArraySetBit(Storage.Data, n); }
    void            ClearBit(i32 n)             { assert(n < (Storage.Size << 5)); ImBitArrayClearBit(Storage.Data, n); }
};

// Helper: ImSpan<>
// Pointing to a span of data we don't own.
template<typename T>
ImSpan :: struct
{
    Data : ^T,
    DataEnd : ^T,

    // Constructors, destructor
    inline ImSpan()                                 { Data = DataEnd = nil; }
    inline ImSpan(T* data, i32 size)                { Data = data; DataEnd = data + size; }
    inline ImSpan(T* data, T* data_end)             { Data = data; DataEnd = data_end; }

    inline void         set(T* data, i32 size)      { Data = data; DataEnd = data + size; }
    inline void         set(T* data, T* data_end)   { Data = data; DataEnd = data_end; }
    inline i32          size() const                { return (i32)(ptrdiff_t)(DataEnd - Data); }
    inline i32          size_in_bytes() const       { return (i32)(ptrdiff_t)(DataEnd - Data) * cast(ast) ast) oft) of}
    inline T&           operator[](i32 i)           { T* p = Data + i; assert(p >= Data && p < DataEnd); return *p; }
    inline const T&     operator[](i32 i) const     { const T* p = Data + i; assert(p >= Data && p < DataEnd); return *p; }

    inline T*           begin()                     { return Data; }
    inline const T*     begin() const               { return Data; }
    inline T*           end()                       { return DataEnd; }
    inline const T*     end() const                 { return DataEnd; }

    // Utilities
    inline i32  index_from_ptr(const T* it) const   { assert(it >= Data && it < DataEnd); const ptrdiff_t off = it - Data; return cast(ast) ast) a
};

// Helper: ImSpanAllocator<>
// Facilitate storing multiple chunks into a single large block (the "arena")
// - Usage: call Reserve() N times, allocate GetArenaSizeInBytes() worth, pass it to SetArenaBasePtr(), call GetSpan() N times to retrieve the aligned ranges.
template<i32 CHUNKS>
ImSpanAllocator :: struct
{
    BasePtr : ^u8,
    CurrOff : i32,
    CurrIdx : i32,
    Offsets : [CHUNKS]i32,
    Sizes : [CHUNKS]i32,

    ImSpanAllocator()                               { memset(this, 0, size_of(*this)); }
    inline void  Reserve(i32 n, int sz, i32 a=4) { assert(n == CurrIdx && n < CHUNKS); CurrOff = mem.align_backward(CurrOff, a); Offsets[n] = CurrOff; Sizes[n] = cast(ast) ast) asrIdx += 1; CurrOff += cast( +=) cast(
    inline i32   GetArenaSizeInBytes()              { return CurrOff; }
    inline void  SetArenaBasePtr(rawptr base_ptr)    { BasePtr = (u8*)base_ptr; }
    inline rawptr GetSpanPtrBegin(i32 n)             { assert(n >= 0 && n < CHUNKS && CurrIdx == CHUNKS); return (rawptr)(BasePtr + Offsets[n]); }
    inline rawptr GetSpanPtrEnd(i32 n)               { assert(n >= 0 && n < CHUNKS && CurrIdx == CHUNKS); return (rawptr)(BasePtr + Offsets[n] + Sizes[n]); }
    template<typename T>
    inline void  GetSpan(i32 n, ImSpan<T>* span)    { span.set((T*)GetSpanPtrBegin(n), (T*)GetSpanPtrEnd(n)); }
};

// Helper: ImPool<>
// Basic keyed storage for contiguous instances, slow/amortized insertion, O(1) indexable, O(Log N) queries by ID over a dense/hot buffer,
// Honor constructor/destructor. Add/remove invalidate all pointers. Indexes have the same lifetime as the associated object.
ImPoolIdx :: i32
template<typename T>
ImPool :: struct
{
    Buf : [dynamic]T,        // Contiguous data
    Map : ImGuiStorage,        // ID->Index
    FreeIdx : ImPoolIdx,    // Next free idx to use
    AliveCount : ImPoolIdx, // Number of active/alive items (for display purpose)

    ImPool()    { FreeIdx = AliveCount = 0; }
    ~ImPool()   { Clear(); }
    T*          GetByKey(ImGuiID key)               { i32 idx = Map.GetInt(key, -1); return (idx != -1) ? &Buf[idx] : nil; }
    T*          GetByIndex(ImPoolIdx n)             { return &Buf[n]; }
    ImPoolIdx   GetIndex(const T* p) const          { assert(p >= Buf.Data && p < Buf.Data + Buf.Size); return (ImPoolIdx)(p - Buf.Data); }
    T*          GetOrAddByKey(ImGuiID key)          { i32* p_idx = Map.GetIntRef(key, -1); if (*p_idx != -1) return &Buf[*p_idx]; *p_idx = FreeIdx; return Add(); }
    bool        Contains(const T* p) const          { return (p >= Buf.Data && p < Buf.Data + Buf.Size); }
    void        Clear()                             { for (i32 n = 0; n < Map.Data.Size; n++) { i32 idx = Map.Data[n].val_i; if (idx != -1) Buf[idx].~T(); } Map.Clear(); Buf.clear(); FreeIdx = AliveCount = 0; }
    T*          Add()                               { i32 idx = FreeIdx; if (idx == Buf.Size) { Buf.resize(Buf.Size + 1); FreeIdx += 1; } else { FreeIdx = *(i32*)&Buf[idx]; } IM_PLACEMENT_NEW(&Buf[idx]) T(); AliveCount += 1; return &Buf[idx]; }
    void        Remove(ImGuiID key, const T* p)     { Remove(key, GetIndex(p)); }
    void        Remove(ImGuiID key, ImPoolIdx idx)  { Buf[idx].~T(); *(i32*)&Buf[idx] = FreeIdx; FreeIdx = idx; Map.SetInt(key, -1); AliveCount -= 1; }
    void        Reserve(i32 capacity)               { Buf.reserve(capacity); Map.Data.reserve(capacity); }

    // To iterate a ImPool: for (int n = 0; n < pool.GetMapSize(); n++) if (T* t = pool.TryGetMapData(n)) { ... }
    // Can be avoided if you know .Remove() has never been called on the pool, or AliveCount == GetMapSize()
    i32         GetAliveCount() const               { return AliveCount; }      // Number of active/alive items in the pool (for display purpose)
    i32         GetBufSize() const                  { return Buf.Size; }
    i32         GetMapSize() const                  { return Map.Data.Size; }   // It is the map we need iterate to find valid items, since we don't have "alive" storage anywhere
    T*          TryGetMapData(ImPoolIdx n)          { i32 idx = Map.Data[n].val_i; if (idx == -1) return nil; return GetByIndex(idx); }
};

// Helper: ImChunkStream<>
// Build and iterate a contiguous stream of variable-sized structures.
// This is used by Settings to store persistent data while reducing allocation count.
// We store the chunk size first, and align the final size on 4 bytes boundaries.
// The tedious/zealous amount of casting is to avoid -Wcast-align warnings.
template<typename T>
ImChunkStream :: struct
{
    Buf : [dynamic]u8,

    void    clear()                     { Buf.clear(); }
    bool    empty() const               { return Buf.Size == 0; }
    i32     size() const                { return Buf.Size; }
    T*      alloc_chunk(int sz)      { int HDR_SZ = 4; sz = mem.align_backward(HDR_SZ + sz, 4u); i32 off = Buf.Size; Buf.resize(off + cast(ast) ast) asi32*)(rawptr)(Buf.Data + off))[0] = cast(] =) cast(] =) caT*)(rawptr)(Buf.Data + off + cast( + ) ff + cast(
    T*      begin()                     { int HDR_SZ = 4; if (!Buf.Data) return nil; return (T*)(rawptr)(Buf.Data + HDR_SZ); }
    T*      next_chunk(T* p)            { int HDR_SZ = 4; assert(p >= begin() && p < end()); p = (T*)(rawptr)((u8*)(rawptr)p + chunk_size(p)); if (p == (T*)(rawptr)((u8*)end() + HDR_SZ)) return (T*)0; assert(p < end()); return p; }
    i32     chunk_size(const T* p)      { return ((const i32*)p)[-1]; }
    T*      end()                       { return (T*)(rawptr)(Buf.Data + Buf.Size); }
    i32     offset_from_ptr(const T* p) { assert(p >= begin() && p < end()); const ptrdiff_t off = (const u8*)p - Buf.Data; return cast(ast) ast) a
    T*      ptr_from_offset(i32 off)    { assert(off >= 4 && off < Buf.Size); return (T*)(rawptr)(Buf.Data + off); }
    void    swap(ImChunkStream<T>& rhs) { rhs.Buf.swap(Buf); }
};

// Helper: ImGuiTextIndex
// Maintain a line index for a text buffer. This is a strong candidate to be moved into the public API.
ImGuiTextIndex :: struct
{
    LineOffsets : [dynamic]i32,
    EndOffset := 0;                          // Because we don't own text buffer we need to maintain EndOffset (may bake in LineOffsets?)

    void            clear()                                 { LineOffsets.clear(); EndOffset = 0; }
    i32             size()                                  { return LineOffsets.Size; }
    const u8*     get_line_begin(const u8* base, i32 n) { return base + LineOffsets[n]; }
    const u8*     get_line_end(const u8* base, i32 n)   { return base + (n + 1 < LineOffsets.Size ? (LineOffsets[n + 1] - 1) : EndOffset); }
    void            append(const u8* base, i32 old_size, i32 new_size);
};

// Helper: ImGuiStorage
ImGuiStoragePair* ImLowerBound(ImGuiStoragePair* in_begin, ImGuiStoragePair* in_end, ImGuiID key);
//-----------------------------------------------------------------------------
// [SECTION] ImDrawList support
//-----------------------------------------------------------------------------

// ImDrawList: Helper function to calculate a circle's segment count given its radius and a "maximum error" value.
// Estimation of number of circle segment based on error is derived using method described in https://stackoverflow.com/a/2244088/15194693
// Number of segments (N) is calculated using equation:
//   N = ceil ( pi / acos(1 - error / r) )     where r > 0, error <= r
// Our equation is significantly simpler that one in the post thanks for choosing segment that is
// perpendicular to X axis. Follow steps in the article from this starting condition and you will
// will get this result.
//
// Rendering circles with an odd number of segments, while mathematically correct will produce
// asymmetrical results on the raster grid. Therefore we're rounding N to next even number (7->8, 8->8, 9->10 etc.)
IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN :: 4
IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX :: 512
#define IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(_RAD,_MAXERROR)    ImClamp(IM_ROUNDUP_TO_EVEN((int)ImCeil(IM_PI / ImAcos(1 - ImMin((_MAXERROR), (_RAD)) / (_RAD)))), IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN, IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX)

// Raw equation from IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC rewritten for 'r' and 'error'.
#define IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R(_N,_MAXERROR)    ((_MAXERROR) / (1 - ImCos(IM_PI / ImMax((float)(_N), IM_PI))))
#define IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_ERROR(_N,_RAD)     ((1 - ImCos(IM_PI / ImMax((float)(_N), IM_PI))) / (_RAD))

// ImDrawList: Lookup table size for adaptive arc drawing, cover full circle.
when !(IM_DRAWLIST_ARCFAST_TABLE_SIZE) {
IM_DRAWLIST_ARCFAST_TABLE_SIZE :: 48 // Number of samples in lookup table.
}
IM_DRAWLIST_ARCFAST_SAMPLE_MAX :: IM_DRAWLIST_ARCFAST_TABLE_SIZE // Sample index _PathArcToFastEx() for 360 angle.

// Data shared between all ImDrawList instances
// Conceptually this could have been called e.g. ImDrawListSharedContext
// Typically one ImGui context would create and maintain one of this.
// You may want to create your own instance of you try to ImDrawList completely without ImGui. In that case, watch out for future changes to this structure.
ImDrawListSharedData :: struct
{
    TexUvWhitePixel : ImVec2,            // UV of white pixel in the atlas
    TexUvLines : ^ImVec4,                 // UV of anti-aliased lines in the atlas
    Font : ^ImFont,                       // Current/default font (optional, for simplified AddText overload)
    FontSize : f32,                   // Current/default font size (optional, for simplified AddText overload)
    FontScale : f32,                  // Current/default font scale (== FontSize / Font->FontSize)
    CurveTessellationTol : f32,       // Tessellation tolerance when using PathBezierCurveTo()
    CircleSegmentMaxError : f32,      // Number of circle segments to use per pixel of radius for AddCircle() etc
    ClipRectFullscreen : ImVec4,         // Value for PushClipRectFullscreen()
    InitialFlags : ImDrawListFlags,               // Initial flags at the beginning of the frame (it is possible to alter flags on a per-drawlist basis afterwards)
    TempBuffer : [dynamic]ImVec2,                // Temporary write buffer

    // Lookup tables
    ArcFastVtx : [IM_DRAWLIST_ARCFAST_TABLE_SIZE]ImVec2, // Sample points on the quarter of the circle.
    ArcFastRadiusCutoff : f32,                        // Cutoff radius after which arc drawing will fallback to slower PathArcTo()
    CircleSegmentCounts : [64]u8,    // Precomputed segment count for given radius before we calculate it dynamically (to avoid calculation overhead)

    ImDrawListSharedData();
    void SetCircleTessellationMaxError(f32 max_error);
};

ImDrawDataBuilder :: struct
{
    Layers : [2]^[dynamic]^ImDrawList,      // Pointers to global layers for: regular, tooltip. LayersP[0] is owned by DrawData.
    LayerData1 : [dynamic]^ImDrawList,

    ImDrawDataBuilder()                     { memset(this, 0, size_of(*this)); }
};

//-----------------------------------------------------------------------------
// [SECTION] Data types support
//-----------------------------------------------------------------------------

ImGuiDataVarInfo :: struct
{
    Type : ImGuiDataType,
    Count : u32,      // 1+
    Offset : u32,     // Offset in parent structure
    rawptr GetVarPtr(rawptr parent) const { return (rawptr)((u8*)parent + Offset); }
};

ImGuiDataTypeStorage :: struct
{
    Data : [8]u8,        // Opaque storage to fit any data up to ImGuiDataType_COUNT
};

// Type information associated to one ImGuiDataType. Retrieve with DataTypeGetInfo().
ImGuiDataTypeInfo :: struct
{
    Size : int,           // Size in bytes
    Name : ^u8,           // Short descriptive name for the type, for debugging
    PrintFmt : ^u8,       // Default printf format for the type
    ScanFmt : ^u8,        // Default scanf format for the type
};

// Extend ImGuiDataType_
ImGuiDataTypePrivate_ :: enum i32
{
    ImGuiDataType_Pointer = ImGuiDataType_COUNT + 1,
    ImGuiDataType_ID,
};

//-----------------------------------------------------------------------------
// [SECTION] Widgets support: flags, enums, data structures
//-----------------------------------------------------------------------------

// Extend ImGuiItemFlags
// - input: PushItemFlag() manipulates g.CurrentItemFlags, g.NextItemData.ItemFlags, ItemAdd() calls may add extra flags too.
// - output: stored in g.LastItemData.ItemFlags
ImGuiItemFlagsPrivate_ :: enum i32
{
    // Controlled by user
    ImGuiItemFlags_Disabled                 = 1 << 10, // false     // Disable interactions (DOES NOT affect visuals. DO NOT mix direct use of this with BeginDisabled(). See BeginDisabled()/EndDisabled() for full disable feature, and github #211).
    ImGuiItemFlags_ReadOnly                 = 1 << 11, // false     // [ALPHA] Allow hovering interactions but underlying value is not changed.
    ImGuiItemFlags_MixedValue               = 1 << 12, // false     // [BETA] Represent a mixed/indeterminate value, generally multi-selection where values differ. Currently only supported by Checkbox() (later should support all sorts of widgets)
    ImGuiItemFlags_NoWindowHoverableCheck   = 1 << 13, // false     // Disable hoverable check in ItemHoverable()
    ImGuiItemFlags_AllowOverlap             = 1 << 14, // false     // Allow being overlapped by another widget. Not-hovered to Hovered transition deferred by a frame.
    ImGuiItemFlags_NoNavDisableMouseHover   = 1 << 15, // false     // Nav keyboard/gamepad mode doesn't disable hover highlight (behave as if NavHighlightItemUnderNav==false).
    ImGuiItemFlags_NoMarkEdited             = 1 << 16, // false     // Skip calling MarkItemEdited()

    // Controlled by widget code
    ImGuiItemFlags_Inputable                = 1 << 20, // false     // [WIP] Auto-activate input mode when tab focused. Currently only used and supported by a few items before it becomes a generic feature.
    ImGuiItemFlags_HasSelectionUserData     = 1 << 21, // false     // Set by SetNextItemSelectionUserData()
    ImGuiItemFlags_IsMultiSelect            = 1 << 22, // false     // Set by SetNextItemSelectionUserData()

    ImGuiItemFlags_Default_                 = ImGuiItemFlags_AutoClosePopups,    // Please don't change, use PushItemFlag() instead.

    // Obsolete
    //ImGuiItemFlags_SelectableDontClosePopup = !ImGuiItemFlags_AutoClosePopups, // Can't have a redirect as we inverted the behavior
};

// Status flags for an already submitted item
// - output: stored in g.LastItemData.StatusFlags
ImGuiItemStatusFlags :: bit_set[ImGuiItemStatusFlag; i32]
ImGuiItemStatusFlag :: enum
{
    // [removed] -> nil: None               = 0,
    HoveredRect        = 0,   // Mouse position is within item rectangle (does NOT mean that the window is in correct z-order and can be hovered!, this is only one part of the most-common IsItemHovered test)
    HasDisplayRect     = 1,   // g.LastItemData.DisplayRect is valid
    Edited             = 2,   // Value exposed by item was edited in the current frame (should match the bool return value of most widgets)
    ToggledSelection   = 3,   // Set when Selectable(), TreeNode() reports toggling a selection. We can't report "Selected", only state changes, in order to easily handle clipping with less issues.
    ToggledOpen        = 4,   // Set when TreeNode() reports toggling their open state.
    HasDeactivated     = 5,   // Set if the widget/group is able to provide data for the ImGuiItemStatusFlags_Deactivated flag.
    Deactivated        = 6,   // Only valid if ImGuiItemStatusFlags_HasDeactivated is set.
    HoveredWindow      = 7,   // Override the HoveredWindow test to allow cross-window hover testing.
    Visible            = 8,   // [WIP] Set when item is overlapping the current clipping rectangle (Used internally. Please don't use yet: API/system will change as we refactor Itemadd()).
    HasClipRect        = 9,   // g.LastItemData.ClipRect is valid.
    HasShortcut        = 10,  // g.LastItemData.Shortcut valid. Set by SetNextItemShortcut() -> ItemAdd().

    // Additional status + semantic for ImGuiTestEngine
when IMGUI_ENABLE_TEST_ENGINE {
    Openable           = 20,  // Item is an openable (e.g. TreeNode)
    Opened             = 21,  // Opened status
    Checkable          = 22,  // Item is a checkable (e.g. CheckBox, MenuItem)
    Checked            = 23,  // Checked status
    Inputable          = 24,  // Item is a text-inputable (e.g. InputText, SliderXXX, DragXXX)
}
};

// Extend ImGuiHoveredFlags_
ImGuiHoveredFlagsPrivate_ :: enum i32
{
    ImGuiHoveredFlags_DelayMask_                    = ImGuiHoveredFlags_DelayNone | ImGuiHoveredFlags_DelayShort | ImGuiHoveredFlags_DelayNormal | ImGuiHoveredFlags_NoSharedDelay,
    ImGuiHoveredFlags_AllowedMaskForIsWindowHovered = ImGuiHoveredFlags_ChildWindows | ImGuiHoveredFlags_RootWindow | ImGuiHoveredFlags_AnyWindow | ImGuiHoveredFlags_NoPopupHierarchy | ImGuiHoveredFlags_DockHierarchy | ImGuiHoveredFlags_AllowWhenBlockedByPopup | ImGuiHoveredFlags_AllowWhenBlockedByActiveItem | ImGuiHoveredFlags_ForTooltip | ImGuiHoveredFlags_Stationary,
    ImGuiHoveredFlags_AllowedMaskForIsItemHovered   = ImGuiHoveredFlags_AllowWhenBlockedByPopup | ImGuiHoveredFlags_AllowWhenBlockedByActiveItem | ImGuiHoveredFlags_AllowWhenOverlapped | ImGuiHoveredFlags_AllowWhenDisabled | ImGuiHoveredFlags_NoNavOverride | ImGuiHoveredFlags_ForTooltip | ImGuiHoveredFlags_Stationary | ImGuiHoveredFlags_DelayMask_,
};

// Extend ImGuiInputTextFlags_
ImGuiInputTextFlagsPrivate_ :: enum i32
{
    // [Internal]
    ImGuiInputTextFlags_Multiline           = 1 << 26,  // For internal use by InputTextMultiline()
    ImGuiInputTextFlags_MergedItem          = 1 << 27,  // For internal use by TempInputText(), will skip calling ItemAdd(). Require bounding-box to strictly match.
    ImGuiInputTextFlags_LocalizeDecimalPoint= 1 << 28,  // For internal use by InputScalar() and TempInputScalar()
};

// Extend ImGuiButtonFlags_
ImGuiButtonFlagsPrivate_ :: enum i32
{
    ImGuiButtonFlags_PressedOnClick         = 1 << 4,   // return true on click (mouse down event)
    ImGuiButtonFlags_PressedOnClickRelease  = 1 << 5,   // [Default] return true on click + release on same item <-- this is what the majority of Button are using
    ImGuiButtonFlags_PressedOnClickReleaseAnywhere = 1 << 6, // return true on click + release even if the release event is not done while hovering the item
    ImGuiButtonFlags_PressedOnRelease       = 1 << 7,   // return true on release (default requires click+release)
    ImGuiButtonFlags_PressedOnDoubleClick   = 1 << 8,   // return true on double-click (default requires click+release)
    ImGuiButtonFlags_PressedOnDragDropHold  = 1 << 9,   // return true when held into while we are drag and dropping another item (used by e.g. tree nodes, collapsing headers)
    //ImGuiButtonFlags_Repeat               = 1 << 10,  // hold to repeat -> use ImGuiItemFlags_ButtonRepeat instead.
    ImGuiButtonFlags_FlattenChildren        = 1 << 11,  // allow interactions even if a child window is overlapping
    ImGuiButtonFlags_AllowOverlap           = 1 << 12,  // require previous frame HoveredId to either match id or be null before being usable.
    //ImGuiButtonFlags_DontClosePopups      = 1 << 13,  // disable automatically closing parent popup on press
    //ImGuiButtonFlags_Disabled             = 1 << 14,  // disable interactions -> use BeginDisabled() or ImGuiItemFlags_Disabled
    ImGuiButtonFlags_AlignTextBaseLine      = 1 << 15,  // vertically align button to match text baseline - ButtonEx() only // FIXME: Should be removed and handled by SmallButton(), not possible currently because of DC.CursorPosPrevLine
    ImGuiButtonFlags_NoKeyModsAllowed       = 1 << 16,  // disable mouse interaction if a key modifier is held
    ImGuiButtonFlags_NoHoldingActiveId      = 1 << 17,  // don't set ActiveId while holding the mouse (ImGuiButtonFlags_PressedOnClick only)
    ImGuiButtonFlags_NoNavFocus             = 1 << 18,  // don't override navigation focus when activated (FIXME: this is essentially used every time an item uses ImGuiItemFlags_NoNav, but because legacy specs don't requires LastItemData to be set ButtonBehavior(), we can't poll g.LastItemData.ItemFlags)
    ImGuiButtonFlags_NoHoveredOnFocus       = 1 << 19,  // don't report as hovered when nav focus is on this item
    ImGuiButtonFlags_NoSetKeyOwner          = 1 << 20,  // don't set key/input owner on the initial click (note: mouse buttons are keys! often, the key in question will be ImGuiKey_MouseLeft!)
    ImGuiButtonFlags_NoTestKeyOwner         = 1 << 21,  // don't test key/input owner when polling the key (note: mouse buttons are keys! often, the key in question will be ImGuiKey_MouseLeft!)
    ImGuiButtonFlags_PressedOnMask_         = ImGuiButtonFlags_PressedOnClick | ImGuiButtonFlags_PressedOnClickRelease | ImGuiButtonFlags_PressedOnClickReleaseAnywhere | ImGuiButtonFlags_PressedOnRelease | ImGuiButtonFlags_PressedOnDoubleClick | ImGuiButtonFlags_PressedOnDragDropHold,
    ImGuiButtonFlags_PressedOnDefault_      = ImGuiButtonFlags_PressedOnClickRelease,
};

// Extend ImGuiComboFlags_
ImGuiComboFlagsPrivate_ :: enum i32
{
    ImGuiComboFlags_CustomPreview           = 1 << 20,  // enable BeginComboPreview()
};

// Extend ImGuiSliderFlags_
ImGuiSliderFlagsPrivate_ :: enum i32
{
    ImGuiSliderFlags_Vertical               = 1 << 20,  // Should this slider be orientated vertically?
    ImGuiSliderFlags_ReadOnly               = 1 << 21,  // Consider using g.NextItemData.ItemFlags |= ImGuiItemFlags_ReadOnly instead.
};

// Extend ImGuiSelectableFlags_
ImGuiSelectableFlagsPrivate_ :: enum i32
{
    // NB: need to be in sync with last value of ImGuiSelectableFlags_
    ImGuiSelectableFlags_NoHoldingActiveID      = 1 << 20,
    ImGuiSelectableFlags_SelectOnNav            = 1 << 21,  // (WIP) Auto-select when moved into. This is not exposed in public API as to handle multi-select and modifiers we will need user to explicitly control focus scope. May be replaced with a BeginSelection() API.
    ImGuiSelectableFlags_SelectOnClick          = 1 << 22,  // Override button behavior to react on Click (default is Click+Release)
    ImGuiSelectableFlags_SelectOnRelease        = 1 << 23,  // Override button behavior to react on Release (default is Click+Release)
    ImGuiSelectableFlags_SpanAvailWidth         = 1 << 24,  // Span all avail width even if we declared less for layout purpose. FIXME: We may be able to remove this (added in 6251d379, 2bcafc86 for menus)
    ImGuiSelectableFlags_SetNavIdOnHover        = 1 << 25,  // Set Nav/Focus ID on mouse hover (used by MenuItem)
    ImGuiSelectableFlags_NoPadWithHalfSpacing   = 1 << 26,  // Disable padding each side with ItemSpacing * 0.5f
    ImGuiSelectableFlags_NoSetKeyOwner          = 1 << 27,  // Don't set key/input owner on the initial click (note: mouse buttons are keys! often, the key in question will be ImGuiKey_MouseLeft!)
};

// Extend ImGuiTreeNodeFlags_
ImGuiTreeNodeFlagsPrivate_ :: enum i32
{
    ImGuiTreeNodeFlags_ClipLabelForTrailingButton = 1 << 28,// FIXME-WIP: Hard-coded for CollapsingHeader()
    ImGuiTreeNodeFlags_UpsideDownArrow            = 1 << 29,// FIXME-WIP: Turn Down arrow into an Up arrow, for reversed trees (#6517)
    ImGuiTreeNodeFlags_OpenOnMask_                = ImGuiTreeNodeFlags_OpenOnDoubleClick | ImGuiTreeNodeFlags_OpenOnArrow,
};

ImGuiSeparatorFlags :: bit_set[ImGuiSeparatorFlag; i32]
ImGuiSeparatorFlag :: enum
{
    // [removed] -> nil: None                    = 0,
    Horizontal              = 0,   // Axis default to current layout type, so generally Horizontal unless e.g. in a menu bar
    Vertical                = 1,
    SpanAllColumns          = 2,   // Make separator cover all columns of a legacy Columns() set.
};

// Flags for FocusWindow(). This is not called ImGuiFocusFlags to avoid confusion with public-facing ImGuiFocusedFlags.
// FIXME: Once we finishing replacing more uses of GetTopMostPopupModal()+IsWindowWithinBeginStackOf()
// and FindBlockingModal() with this, we may want to change the flag to be opt-out instead of opt-in.
ImGuiFocusRequestFlags :: bit_set[ImGuiFocusRequestFlag; i32]
ImGuiFocusRequestFlag :: enum
{
    // [removed] -> nil: None                 = 0,
    RestoreFocusedChild  = 0,   // Find last focused child (if any) and focus it instead.
    UnlessBelowModal     = 1,   // Do not set focus if the window is below a modal.
};

ImGuiTextFlags :: bit_set[ImGuiTextFlag; i32]
ImGuiTextFlag :: enum
{
    // [removed] -> nil: None                         = 0,
    NoWidthForLargeClippedText   = 0,
};

ImGuiTooltipFlags :: bit_set[ImGuiTooltipFlag; i32]
ImGuiTooltipFlag :: enum
{
    // [removed] -> nil: None                      = 0,
    OverridePrevious          = 1,   // Clear/ignore previously submitted tooltip (defaults to append)
};

// FIXME: this is in development, not exposed/functional as a generic feature yet.
// Horizontal/Vertical enums are fixed to 0/1 so they may be used to index ImVec2
ImGuiLayoutType_ :: enum i32
{
    Horizontal = 0,
    Vertical = 1
};

// Flags for LogBegin() text capturing function
ImGuiLogFlags :: bit_set[ImGuiLogFlag; i32]
ImGuiLogFlag :: enum
{
    // [removed] -> nil: None = 0,

    OutputTTY         = 0,
    OutputFile        = 1,
    OutputBuffer      = 2,
    OutputClipboard   = 3,
    // [moved] OutputMask_       = OutputTTY | OutputFile | OutputBuffer | OutputClipboard,
};
ImGuiLogFlags_OutputMask_ :: { OutputTTY , OutputFile , OutputBuffer , OutputClipboard }

// X/Y enums are fixed to 0/1 so they may be used to index ImVec2
ImGuiAxis :: enum i32
{
    // [removed] -> nil: None = -1,
    X = 0,
    Y = 1
};

ImGuiPlotType :: enum i32
{
    Lines,
    Histogram,
};

// Stacked color modifier, backup of modified data so we can restore it
ImGuiColorMod :: struct
{
    Col : ImGuiCol,
    BackupValue : ImVec4,
};

// Stacked style modifier, backup of modified data so we can restore it. Data type inferred from the variable.
ImGuiStyleMod :: struct
{
    VarIdx : ImGuiStyleVar,
    union           { i32 BackupInt[2]; f32 BackupFloat[2]; };
    ImGuiStyleMod(ImGuiStyleVar idx, i32 v)     { VarIdx = idx; BackupInt[0] = v; }
    ImGuiStyleMod(ImGuiStyleVar idx, f32 v)   { VarIdx = idx; BackupFloat[0] = v; }
    ImGuiStyleMod(ImGuiStyleVar idx, ImVec2 v)  { VarIdx = idx; BackupFloat[0] = v.x; BackupFloat[1] = v.y; }
};

// Storage data for BeginComboPreview()/EndComboPreview()
ImGuiComboPreviewData :: struct
{
    PreviewRect : ImRect,
    BackupCursorPos : ImVec2,
    BackupCursorMaxPos : ImVec2,
    BackupCursorPosPrevLine : ImVec2,
    BackupPrevLineTextBaseOffset : f32,
    BackupLayout : ImGuiLayoutType,

    ImGuiComboPreviewData() { memset(this, 0, size_of(*this)); }
};

// Stacked storage data for BeginGroup()/EndGroup()
ImGuiGroupData :: struct
{
    WindowID : ImGuiID,
    BackupCursorPos : ImVec2,
    BackupCursorMaxPos : ImVec2,
    BackupCursorPosPrevLine : ImVec2,
    BackupIndent : ImVec1,
    BackupGroupOffset : ImVec1,
    BackupCurrLineSize : ImVec2,
    BackupCurrLineTextBaseOffset : f32,
    BackupActiveIdIsAlive : ImGuiID,
    BackupActiveIdPreviousFrameIsAlive : bool,
    BackupHoveredIdIsAlive : bool,
    BackupIsSameLine : bool,
    EmitItem : bool,
};

// Simple column measurement, currently used for MenuItem() only.. This is very short-sighted/throw-away code and NOT a generic helper.
ImGuiMenuColumns :: struct
{
    TotalWidth : u32,
    NextTotalWidth : u32,
    Spacing : u16,
    OffsetIcon : u16,         // Always zero for now
    OffsetLabel : u16,        // Offsets are locked in Update()
    OffsetShortcut : u16,
    OffsetMark : u16,
    Widths : [4]u16,          // Width of:   Icon, Label, Shortcut, Mark  (accumulators for current frame)

    ImGuiMenuColumns() { memset(this, 0, size_of(*this)); }
    void        Update(f32 spacing, bool window_reappearing);
    f32       DeclColumns(f32 w_icon, f32 w_label, f32 w_shortcut, f32 w_mark);
    void        CalcNextTotalWidth(bool update_offsets);
};

// Internal temporary state for deactivating InputText() instances.
ImGuiInputTextDeactivatedState :: struct
{
    ID : ImGuiID,              // widget id owning the text state (which just got deactivated)
    TextA : [dynamic]u8,           // text buffer

    ImGuiInputTextDeactivatedState()    { memset(this, 0, size_of(*this)); }
    void    ClearFreeMemory()           { ID = 0; TextA.clear(); }
};

// Forward declare imstb_textedit.h structure + make its main configuration define accessible
#undef IMSTB_TEXTEDIT_STRING
#undef IMSTB_TEXTEDIT_CHARTYPE
IMSTB_TEXTEDIT_STRING :: ImGuiInputTextState
IMSTB_TEXTEDIT_CHARTYPE :: char
#define IMSTB_TEXTEDIT_GETWIDTH_NEWLINE   (-1.0f)
IMSTB_TEXTEDIT_UNDOSTATECOUNT :: 99
IMSTB_TEXTEDIT_UNDOCHARCOUNT :: 999
namespace ImStb { struct STB_TexteditState; }
ImStbTexteditState :: ImStb::STB_TexteditState

// Internal state of the currently focused/edited text input box
// For a given item ID, access with ImGui::GetInputTextState()
ImGuiInputTextState :: struct
{
    Ctx : ^ImGuiContext,                    // parent UI context (needs to be set explicitly by parent).
    Stb : ^ImStbTexteditState,                    // State for stb_textedit.h
    Flags : ImGuiInputTextFlags,                  // copy of InputText() flags. may be used to check if e.g. ImGuiInputTextFlags_Password is set.
    ID : ImGuiID,                     // widget id owning the text state
    TextLen : i32,                // UTF-8 length of the string in TextA (in bytes)
    TextSrc : ^u8,                // == TextA.Data unless read-only, in which case == buf passed to InputText(). Field only set and valid _inside_ the call InputText() call.
    TextA : [dynamic]u8,                  // main UTF8 buffer. TextA.Size is a buffer size! Should always be >= buf_size passed by user (and of course >= CurLenA + 1).
    TextToRevertTo : [dynamic]u8,         // value to revert to when pressing Escape = backup of end-user buffer at the time of focus (in UTF-8, unaltered)
    CallbackTextBackup : [dynamic]u8,     // temporary storage for callback to support automatic reconcile of undo-stack
    BufCapacity : i32,            // end-user buffer capacity (include zero terminator)
    Scroll : ImVec2,                 // horizontal offset (managed manually) + vertical scrolling (pulled from child window's own Scroll.y)
    CursorAnim : f32,             // timer for cursor blink, reset on every user action so the cursor reappears immediately
    CursorFollow : bool,           // set when we want scrolling to follow the current cursor position (not always!)
    SelectedAllMouseLock : bool,   // after a double-click to select all, we ignore further mouse drags to update selection
    Edited : bool,                 // edited this frame
    WantReloadUserBuf : bool,      // force a reload of user buf so it may be modified externally. may be automatic in future version.
    ReloadSelectionStart : i32,
    ReloadSelectionEnd : i32,

    ImGuiInputTextState();
    ~ImGuiInputTextState();
    void        ClearText()                 { TextLen = 0; TextA[0] = 0; CursorClamp(); }
    void        ClearFreeMemory()           { TextA.clear(); TextToRevertTo.clear(); }
    void        OnKeyPressed(i32 key);      // Cannot be inline because we call in code in stb_textedit.h implementation
    void        OnCharPressed(u32 c);

    // Cursor & Selection
    void        CursorAnimReset();
    void        CursorClamp();
    bool        HasSelection() const;
    void        ClearSelection();
    i32         GetCursorPos() const;
    i32         GetSelectionStart() const;
    i32         GetSelectionEnd() const;
    void        SelectAll();

    // Reload user buf (WIP #2890)
    // If you modify underlying user-passed const char* while active you need to call this (InputText V2 may lift this)
    //   strcpy(my_buf, "hello");
    //   if (ImGuiInputTextState* state = ImGui::GetInputTextState(id)) // id may be ImGui::GetItemID() is last item
    //       state->ReloadUserBufAndSelectAll();
    void        ReloadUserBufAndSelectAll();
    void        ReloadUserBufAndKeepSelection();
    void        ReloadUserBufAndMoveToEnd();
};

ImGuiWindowRefreshFlags :: bit_set[ImGuiWindowRefreshFlag; i32]
ImGuiWindowRefreshFlag :: enum
{
    // [removed] -> nil: None                = 0,
    TryToAvoidRefresh   = 0,   // [EXPERIMENTAL] Try to keep existing contents, USER MUST NOT HONOR BEGIN() RETURNING FALSE AND NOT APPEND.
    RefreshOnHover      = 1,   // [EXPERIMENTAL] Always refresh on hover
    RefreshOnFocus      = 2,   // [EXPERIMENTAL] Always refresh on focus
    // Refresh policy/frequency, Load Balancing etc.
};

ImGuiNextWindowDataFlags :: bit_set[ImGuiNextWindowDataFlag; i32]
ImGuiNextWindowDataFlag :: enum
{
    // [removed] -> nil: None               = 0,
    HasPos             = 0,
    HasSize            = 1,
    HasContentSize     = 2,
    HasCollapsed       = 3,
    HasSizeConstraint  = 4,
    HasFocus           = 5,
    HasBgAlpha         = 6,
    HasScroll          = 7,
    HasChildFlags      = 8,
    HasRefreshPolicy   = 9,
    HasViewport        = 10,
    HasDock            = 11,
    HasWindowClass     = 12,
};

// Storage for SetNexWindow** functions
ImGuiNextWindowData :: struct
{
    Flags : ImGuiNextWindowDataFlags,
    PosCond : ImGuiCond,
    SizeCond : ImGuiCond,
    CollapsedCond : ImGuiCond,
    DockCond : ImGuiCond,
    PosVal : ImVec2,
    PosPivotVal : ImVec2,
    SizeVal : ImVec2,
    ContentSizeVal : ImVec2,
    ScrollVal : ImVec2,
    ChildFlags : ImGuiChildFlags,
    PosUndock : bool,
    CollapsedVal : bool,
    SizeConstraintRect : ImRect,
    SizeCallback : ImGuiSizeCallback,
    SizeCallbackUserData : rawptr,
    BgAlphaVal : f32,             // Override background alpha
    ViewportId : ImGuiID,
    DockId : ImGuiID,
    WindowClass : ImGuiWindowClass,
    MenuBarOffsetMinVal : ImVec2,    // (Always on) This is not exposed publicly, so we don't clear it and it doesn't have a corresponding flag (could we? for consistency?)
    RefreshFlagsVal : ImGuiWindowRefreshFlags,

    ImGuiNextWindowData()       { memset(this, 0, size_of(*this)); }
    inline void ClearFlags()    { Flags = ImGuiNextWindowDataFlags_None; }
};

ImGuiNextItemDataFlags :: bit_set[ImGuiNextItemDataFlag; i32]
ImGuiNextItemDataFlag :: enum
{
    // [removed] -> nil: None         = 0,
    HasWidth     = 0,
    HasOpen      = 1,
    HasShortcut  = 2,
    HasRefVal    = 3,
    HasStorageID = 4,
};

ImGuiNextItemData :: struct
{
    HasFlags : ImGuiNextItemDataFlags,           // Called HasFlags instead of Flags to avoid mistaking this
    ItemFlags : ImGuiItemFlags,          // Currently only tested/used for ImGuiItemFlags_AllowOverlap and ImGuiItemFlags_HasSelectionUserData.
    // Non-flags members are NOT cleared by ItemAdd() meaning they are still valid during NavProcessItem()
    FocusScopeId : ImGuiID,       // Set by SetNextItemSelectionUserData()
    SelectionUserData : ImGuiSelectionUserData,  // Set by SetNextItemSelectionUserData() (note that NULL/0 is a valid value, we use -1 == ImGuiSelectionUserData_Invalid to mark invalid values)
    Width : f32,              // Set by SetNextItemWidth()
    Shortcut : ImGuiKeyChord,           // Set by SetNextItemShortcut()
    ShortcutFlags : ImGuiInputFlags,      // Set by SetNextItemShortcut()
    OpenVal : bool,            // Set by SetNextItemOpen()
    OpenCond : u8,           // Set by SetNextItemOpen()
    RefVal : ImGuiDataTypeStorage,             // Not exposed yet, for ImGuiInputTextFlags_ParseEmptyAsRefVal
    StorageId : ImGuiID,          // Set by SetNextItemStorageID()

    ImGuiNextItemData()         { memset(this, 0, size_of(*this)); SelectionUserData = -1; }
    inline void ClearFlags()    { HasFlags = ImGuiNextItemDataFlags_None; ItemFlags = ImGuiItemFlags_None; } // Also cleared manually by ItemAdd()!
};

// Status storage for the last submitted item
ImGuiLastItemData :: struct
{
    ID : ImGuiID,
    ItemFlags : ImGuiItemFlags,          // See ImGuiItemFlags_
    StatusFlags : ImGuiItemStatusFlags,        // See ImGuiItemStatusFlags_
    Rect : ImRect,               // Full rectangle
    NavRect : ImRect,            // Navigation scoring rectangle (not displayed)
    // Rarely used fields are not explicitly cleared, only valid when the corresponding ImGuiItemStatusFlags ar set.
    DisplayRect : ImRect,        // Display rectangle. ONLY VALID IF (StatusFlags & ImGuiItemStatusFlags_HasDisplayRect) is set.
    ClipRect : ImRect,           // Clip rectangle at the time of submitting item. ONLY VALID IF (StatusFlags & ImGuiItemStatusFlags_HasClipRect) is set..
    Shortcut : ImGuiKeyChord,           // Shortcut at the time of submitting item. ONLY VALID IF (StatusFlags & ImGuiItemStatusFlags_HasShortcut) is set..

    ImGuiLastItemData()     { memset(this, 0, size_of(*this)); }
};

// Store data emitted by TreeNode() for usage by TreePop()
// - To implement ImGuiTreeNodeFlags_NavLeftJumpsBackHere: store the minimum amount of data
//   which we can't infer in TreePop(), to perform the equivalent of NavApplyItemToResult().
//   Only stored when the node is a potential candidate for landing on a Left arrow jump.
ImGuiTreeNodeStackData :: struct
{
    ID : ImGuiID,
    TreeFlags : ImGuiTreeNodeFlags,
    ItemFlags : ImGuiItemFlags,  // Used for nav landing
    NavRect : ImRect,    // Used for nav landing
};

// sizeof() = 20
ImGuiErrorRecoveryState :: struct
{
    SizeOfWindowStack : i16,
    SizeOfIDStack : i16,
    SizeOfTreeStack : i16,
    SizeOfColorStack : i16,
    SizeOfStyleVarStack : i16,
    SizeOfFontStack : i16,
    SizeOfFocusScopeStack : i16,
    SizeOfGroupStack : i16,
    SizeOfItemFlagsStack : i16,
    SizeOfBeginPopupStack : i16,
    SizeOfDisabledStack : i16,

    ImGuiErrorRecoveryState() { memset(this, 0, size_of(*this)); }
};

// Data saved for each window pushed into the stack
ImGuiWindowStackData :: struct
{
    Window : ^ImGuiWindow,
    ParentLastItemDataBackup : ImGuiLastItemData,
    StackSizesInBegin : ImGuiErrorRecoveryState,          // Store size of various stacks for asserting
    DisabledOverrideReenable : bool,   // Non-child window override disabled flag
};

ImGuiShrinkWidthItem :: struct
{
    Index : i32,
    Width : f32,
    InitialWidth : f32,
};

ImGuiPtrOrIndex :: struct
{
    Ptr : rawptr,            // Either field can be set, not both. e.g. Dock node tab bars are loose while BeginTabBar() ones are in a pool.
    Index : i32,          // Usually index in a main pool.

    ImGuiPtrOrIndex(rawptr ptr)  { Ptr = ptr; Index = -1; }
    ImGuiPtrOrIndex(i32 index)  { Ptr = nil; Index = index; }
};

//-----------------------------------------------------------------------------
// [SECTION] Popup support
//-----------------------------------------------------------------------------

ImGuiPopupPositionPolicy :: enum i32
{
    Default,
    ComboBox,
    Tooltip,
};

// Storage for popup stacks (g.OpenPopupStack and g.BeginPopupStack)
ImGuiPopupData :: struct
{
    PopupId : ImGuiID,        // Set on OpenPopup()
    Window : ^ImGuiWindow,         // Resolved on BeginPopup() - may stay unresolved if user never calls OpenPopup()
    RestoreNavWindow : ^ImGuiWindow,// Set on OpenPopup(), a NavWindow that will be restored on popup close
    ParentNavLayer : i32, // Resolved on BeginPopup(). Actually a ImGuiNavLayer type (declared down below), initialized to -1 which is not part of an enum, but serves well-enough as "not any of layers" value
    OpenFrameCount : i32, // Set on OpenPopup()
    OpenParentId : ImGuiID,   // Set on OpenPopup(), we need this to differentiate multiple menu sets from each others (e.g. inside menu bar vs loose menu items)
    OpenPopupPos : ImVec2,   // Set on OpenPopup(), preferred popup position (typically == OpenMousePos when using mouse)
    OpenMousePos : ImVec2,   // Set on OpenPopup(), copy of mouse position at the time of opening popup

    ImGuiPopupData()    { memset(this, 0, size_of(*this)); ParentNavLayer = OpenFrameCount = -1; }
};

//-----------------------------------------------------------------------------
// [SECTION] Inputs support
//-----------------------------------------------------------------------------

// Bit array for named keys
ImBitArrayForNamedKeys :: ImBitArray<ImGuiKey_NamedKey_COUNT, -ImGuiKey_NamedKey_BEGIN>

// [Internal] Key ranges
ImGuiKey_LegacyNativeKey_BEGIN :: 0
ImGuiKey_LegacyNativeKey_END :: 512
#define ImGuiKey_Keyboard_BEGIN         (ImGuiKey_NamedKey_BEGIN)
#define ImGuiKey_Keyboard_END           (ImGuiKey_GamepadStart)
#define ImGuiKey_Gamepad_BEGIN          (ImGuiKey_GamepadStart)
#define ImGuiKey_Gamepad_END            (ImGuiKey_GamepadRStickDown + 1)
#define ImGuiKey_Mouse_BEGIN            (ImGuiKey_MouseLeft)
#define ImGuiKey_Mouse_END              (ImGuiKey_MouseWheelY + 1)
#define ImGuiKey_Aliases_BEGIN          (ImGuiKey_Mouse_BEGIN)
#define ImGuiKey_Aliases_END            (ImGuiKey_Mouse_END)

// [Internal] Named shortcuts for Navigation
ImGuiKey_NavKeyboardTweakSlow :: ImGuiMod_Ctrl
ImGuiKey_NavKeyboardTweakFast :: ImGuiMod_Shift
ImGuiKey_NavGamepadTweakSlow :: ImGuiKey_GamepadL1
ImGuiKey_NavGamepadTweakFast :: ImGuiKey_GamepadR1
#define ImGuiKey_NavGamepadActivate     (g.IO.ConfigNavSwapGamepadButtons ? ImGuiKey_GamepadFaceRight : ImGuiKey_GamepadFaceDown)
#define ImGuiKey_NavGamepadCancel       (g.IO.ConfigNavSwapGamepadButtons ? ImGuiKey_GamepadFaceDown : ImGuiKey_GamepadFaceRight)
ImGuiKey_NavGamepadMenu :: ImGuiKey_GamepadFaceLeft
ImGuiKey_NavGamepadInput :: ImGuiKey_GamepadFaceUp

ImGuiInputEventType :: enum i32
{
    // [removed] -> nil: None = 0,
    MousePos,
    MouseWheel,
    MouseButton,
    MouseViewport,
    Key,
    Text,
    Focus,
    _COUNT,
};

ImGuiInputSource :: enum i32
{
    // [removed] -> nil: None = 0,
    Mouse,         // Note: may be Mouse or TouchScreen or Pen. See io.MouseSource to distinguish them.
    Keyboard,
    Gamepad,
    _COUNT,
};

// FIXME: Structures in the union below need to be declared as anonymous unions appears to be an extension?
// Using ImVec2() would fail on Clang 'union member 'MousePos' has a non-trivial default constructor'
struct ImGuiInputEventMousePos      { f32 PosX, PosY; ImGuiMouseSource MouseSource; };
struct ImGuiInputEventMouseWheel    { f32 WheelX, WheelY; ImGuiMouseSource MouseSource; };
struct ImGuiInputEventMouseButton   { i32 Button; bool Down; ImGuiMouseSource MouseSource; };
struct ImGuiInputEventMouseViewport { ImGuiID HoveredViewportID; };
struct ImGuiInputEventKey           { ImGuiKey Key; bool Down; f32 AnalogValue; };
struct ImGuiInputEventText          { u32 Char; };
struct ImGuiInputEventAppFocused    { bool Focused; };

ImGuiInputEvent :: struct
{
    Type : ImGuiInputEventType,
    Source : ImGuiInputSource,
    EventId : u32,        // Unique, sequential increasing integer to identify an event (if you need to correlate them to other data).
    union
    {
        MousePos : ImGuiInputEventMousePos,       // if Type == ImGuiInputEventType_MousePos
        MouseWheel : ImGuiInputEventMouseWheel,     // if Type == ImGuiInputEventType_MouseWheel
        MouseButton : ImGuiInputEventMouseButton,    // if Type == .MouseButton
        MouseViewport : ImGuiInputEventMouseViewport, // if Type == .MouseViewport
        Key : ImGuiInputEventKey,            // if Type == .Key
        Text : ImGuiInputEventText,           // if Type == ImGuiInputEventType_Text
        AppFocused : ImGuiInputEventAppFocused,     // if Type == ImGuiInputEventType_Focus
    };
    AddedByTestEngine : bool

    ImGuiInputEvent() { memset(this, 0, size_of(*this)); }
};

// Input function taking an 'ImGuiID owner_id' argument defaults to (ImGuiKeyOwner_Any == 0) aka don't test ownership, which matches legacy behavior.
#define ImGuiKeyOwner_Any           ((ImGuiID)0)    // Accept key that have an owner, UNLESS a call to SetKeyOwner() explicitly used ImGuiInputFlags_LockThisFrame or ImGuiInputFlags_LockUntilRelease.
#define ImGuiKeyOwner_NoOwner       ((ImGuiID)-1)   // Require key to have no owner.
//#define ImGuiKeyOwner_None ImGuiKeyOwner_NoOwner  // We previously called this 'ImGuiKeyOwner_None' but it was inconsistent with our pattern that _None values == 0 and quite dangerous. Also using _NoOwner makes the IsKeyPressed() calls more explicit.

ImGuiKeyRoutingIndex :: u16

// Routing table entry (sizeof() == 16 bytes)
ImGuiKeyRoutingData :: struct
{
    NextEntryIndex : ImGuiKeyRoutingIndex,
    Mods : u16,               // Technically we'd only need 4-bits but for simplify we store ImGuiMod_ values which need 16-bits.
    RoutingCurrScore : u8,   // [DEBUG] For debug display
    RoutingNextScore : u8,   // Lower is better (0: perfect score)
    RoutingCurr : ImGuiID,
    RoutingNext : ImGuiID,

    ImGuiKeyRoutingData()           { NextEntryIndex = -1; Mods = 0; RoutingCurrScore = RoutingNextScore = 255; RoutingCurr = RoutingNext = ImGuiKeyOwner_NoOwner; }
};

// Routing table: maintain a desired owner for each possible key-chord (key + mods), and setup owner in NewFrame() when mods are matching.
// Stored in main context (1 instance)
ImGuiKeyRoutingTable :: struct
{
    Index : [ImGuiKey_NamedKey_COUNT]ImGuiKeyRoutingIndex, // Index of first entry in Entries[]
    Entries : [dynamic]ImGuiKeyRoutingData,
    EntriesNext : [dynamic]ImGuiKeyRoutingData,                    // Double-buffer to avoid reallocation (could use a shared buffer)

    ImGuiKeyRoutingTable()          { Clear(); }
    void Clear()                    { for (i32 n = 0; n < len(Index); n++) Index[n] = -1; Entries.clear(); EntriesNext.clear(); }
};

// This extends ImGuiKeyData but only for named keys (legacy keys don't support the new features)
// Stored in main context (1 per named key). In the future it might be merged into ImGuiKeyData.
ImGuiKeyOwnerData :: struct
{
    OwnerCurr : ImGuiID,
    OwnerNext : ImGuiID,
    LockThisFrame : bool,      // Reading this key requires explicit owner id (until end of frame). Set by ImGuiInputFlags_LockThisFrame.
    LockUntilRelease : bool,   // Reading this key requires explicit owner id (until key is released). Set by ImGuiInputFlags_LockUntilRelease. When this is true LockThisFrame is always true as well.

    ImGuiKeyOwnerData()             { OwnerCurr = OwnerNext = ImGuiKeyOwner_NoOwner; LockThisFrame = LockUntilRelease = false; }
};

// Extend ImGuiInputFlags_
// Flags for extended versions of IsKeyPressed(), IsMouseClicked(), Shortcut(), SetKeyOwner(), SetItemKeyOwner()
// Don't mistake with ImGuiInputTextFlags! (which is for ImGui::InputText() function)
ImGuiInputFlagsPrivate_ :: enum i32
{
    // Flags for IsKeyPressed(), IsKeyChordPressed(), IsMouseClicked(), Shortcut()
    // - Repeat mode: Repeat rate selection
    ImGuiInputFlags_RepeatRateDefault           = 1 << 1,   // Repeat rate: Regular (default)
    ImGuiInputFlags_RepeatRateNavMove           = 1 << 2,   // Repeat rate: Fast
    ImGuiInputFlags_RepeatRateNavTweak          = 1 << 3,   // Repeat rate: Faster
    // - Repeat mode: Specify when repeating key pressed can be interrupted.
    // - In theory ImGuiInputFlags_RepeatUntilOtherKeyPress may be a desirable default, but it would break too many behavior so everything is opt-in.
    ImGuiInputFlags_RepeatUntilRelease          = 1 << 4,   // Stop repeating when released (default for all functions except Shortcut). This only exists to allow overriding Shortcut() default behavior.
    ImGuiInputFlags_RepeatUntilKeyModsChange    = 1 << 5,   // Stop repeating when released OR if keyboard mods are changed (default for Shortcut)
    ImGuiInputFlags_RepeatUntilKeyModsChangeFromNone = 1 << 6,  // Stop repeating when released OR if keyboard mods are leaving the None state. Allows going from Mod+Key to Key by releasing Mod.
    ImGuiInputFlags_RepeatUntilOtherKeyPress    = 1 << 7,   // Stop repeating when released OR if any other keyboard key is pressed during the repeat

    // Flags for SetKeyOwner(), SetItemKeyOwner()
    // - Locking key away from non-input aware code. Locking is useful to make input-owner-aware code steal keys from non-input-owner-aware code. If all code is input-owner-aware locking would never be necessary.
    ImGuiInputFlags_LockThisFrame               = 1 << 20,  // Further accesses to key data will require EXPLICIT owner ID (ImGuiKeyOwner_Any/0 will NOT accepted for polling). Cleared at end of frame.
    ImGuiInputFlags_LockUntilRelease            = 1 << 21,  // Further accesses to key data will require EXPLICIT owner ID (ImGuiKeyOwner_Any/0 will NOT accepted for polling). Cleared when the key is released or at end of each frame if key is released.

    // - Condition for SetItemKeyOwner()
    ImGuiInputFlags_CondHovered                 = 1 << 22,  // Only set if item is hovered (default to both)
    ImGuiInputFlags_CondActive                  = 1 << 23,  // Only set if item is active (default to both)
    ImGuiInputFlags_CondDefault_                = ImGuiInputFlags_CondHovered | ImGuiInputFlags_CondActive,

    // [Internal] Mask of which function support which flags
    ImGuiInputFlags_RepeatRateMask_             = ImGuiInputFlags_RepeatRateDefault | ImGuiInputFlags_RepeatRateNavMove | ImGuiInputFlags_RepeatRateNavTweak,
    ImGuiInputFlags_RepeatUntilMask_            = ImGuiInputFlags_RepeatUntilRelease | ImGuiInputFlags_RepeatUntilKeyModsChange | ImGuiInputFlags_RepeatUntilKeyModsChangeFromNone | ImGuiInputFlags_RepeatUntilOtherKeyPress,
    ImGuiInputFlags_RepeatMask_                 = ImGuiInputFlags_Repeat | ImGuiInputFlags_RepeatRateMask_ | ImGuiInputFlags_RepeatUntilMask_,
    ImGuiInputFlags_CondMask_                   = ImGuiInputFlags_CondHovered | ImGuiInputFlags_CondActive,
    ImGuiInputFlags_RouteTypeMask_              = ImGuiInputFlags_RouteActive | ImGuiInputFlags_RouteFocused | ImGuiInputFlags_RouteGlobal | ImGuiInputFlags_RouteAlways,
    ImGuiInputFlags_RouteOptionsMask_           = ImGuiInputFlags_RouteOverFocused | ImGuiInputFlags_RouteOverActive | ImGuiInputFlags_RouteUnlessBgFocused | ImGuiInputFlags_RouteFromRootWindow,
    ImGuiInputFlags_SupportedByIsKeyPressed     = ImGuiInputFlags_RepeatMask_,
    ImGuiInputFlags_SupportedByIsMouseClicked   = ImGuiInputFlags_Repeat,
    ImGuiInputFlags_SupportedByShortcut         = ImGuiInputFlags_RepeatMask_ | ImGuiInputFlags_RouteTypeMask_ | ImGuiInputFlags_RouteOptionsMask_,
    ImGuiInputFlags_SupportedBySetNextItemShortcut = ImGuiInputFlags_RepeatMask_ | ImGuiInputFlags_RouteTypeMask_ | ImGuiInputFlags_RouteOptionsMask_ | ImGuiInputFlags_Tooltip,
    ImGuiInputFlags_SupportedBySetKeyOwner      = ImGuiInputFlags_LockThisFrame | ImGuiInputFlags_LockUntilRelease,
    ImGuiInputFlags_SupportedBySetItemKeyOwner  = ImGuiInputFlags_SupportedBySetKeyOwner | ImGuiInputFlags_CondMask_,
};

//-----------------------------------------------------------------------------
// [SECTION] Clipper support
//-----------------------------------------------------------------------------

// Note that Max is exclusive, so perhaps should be using a Begin/End convention.
ImGuiListClipperRange :: struct
{
    Min : i32,
    Max : i32,
    PosToIndexConvert : bool,      // Begin/End are absolute position (will be converted to indices later)
    PosToIndexOffsetMin : i8,    // Add to Min after converting to indices
    PosToIndexOffsetMax : i8,    // Add to Min after converting to indices

    static ImGuiListClipperRange    FromIndices(i32 min, i32 max)                               { ImGuiListClipperRange r = { min, max, false, 0, 0 }; return r; }
    static ImGuiListClipperRange    FromPositions(f32 y1, f32 y2, i32 off_min, i32 off_max) { ImGuiListClipperRange r = { cast(ast) ast) as2)y2, true, cast(ue)  cast(ue)  cast(umax }; return r; }
};

// Temporary clipper data, buffers shared/reused between instances
ImGuiListClipperData :: struct
{
    ListClipper : ^ImGuiListClipper,
    LossynessOffset : f32,
    StepNo : i32,
    ItemsFrozen : i32,
    Ranges : [dynamic]ImGuiListClipperRange,

    ImGuiListClipperData()          { memset(this, 0, size_of(*this)); }
    void                            Reset(ImGuiListClipper* clipper) { ListClipper = clipper; StepNo = ItemsFrozen = 0; Ranges.resize(0); }
};

//-----------------------------------------------------------------------------
// [SECTION] Navigation support
//-----------------------------------------------------------------------------

ImGuiActivateFlags :: bit_set[ImGuiActivateFlag; i32]
ImGuiActivateFlag :: enum
{
    // [removed] -> nil: None                 = 0,
    PreferInput          = 0,       // Favor activation that requires keyboard text input (e.g. for Slider/Drag). Default for Enter key.
    PreferTweak          = 1,       // Favor activation for tweaking with arrows or gamepad (e.g. for Slider/Drag). Default for Space key and if keyboard is not used.
    TryToPreserveState   = 2,       // Request widget to preserve state if it can (e.g. InputText will try to preserve cursor/selection)
    FromTabbing          = 3,       // Activation requested by a tabbing request
    FromShortcut         = 4,       // Activation requested by an item shortcut via SetNextItemShortcut() function.
};

// Early work-in-progress API for ScrollToItem()
ImGuiScrollFlags :: bit_set[ImGuiScrollFlag; i32]
ImGuiScrollFlag :: enum
{
    // [removed] -> nil: None                   = 0,
    KeepVisibleEdgeX       = 0,       // If item is not visible: scroll as little as possible on X axis to bring item back into view [default for X axis]
    KeepVisibleEdgeY       = 1,       // If item is not visible: scroll as little as possible on Y axis to bring item back into view [default for Y axis for windows that are already visible]
    KeepVisibleCenterX     = 2,       // If item is not visible: scroll to make the item centered on X axis [rarely used]
    KeepVisibleCenterY     = 3,       // If item is not visible: scroll to make the item centered on Y axis
    AlwaysCenterX          = 4,       // Always center the result item on X axis [rarely used]
    AlwaysCenterY          = 5,       // Always center the result item on Y axis [default for Y axis for appearing window)
    NoScrollParent         = 6,       // Disable forwarding scrolling to parent window if required to keep item/rect visible (only scroll window the function was applied to).
    // [moved] MaskX_                 = KeepVisibleEdgeX | KeepVisibleCenterX | AlwaysCenterX,
    // [moved] MaskY_                 = KeepVisibleEdgeY | KeepVisibleCenterY | AlwaysCenterY,
};
ImGuiScrollFlags_MaskX_ :: { KeepVisibleEdgeX , KeepVisibleCenterX , AlwaysCenterX }
ImGuiScrollFlags_MaskY_ :: { KeepVisibleEdgeY , KeepVisibleCenterY , AlwaysCenterY }

ImGuiNavRenderCursorFlags :: bit_set[ImGuiNavRenderCursorFlag; i32]
ImGuiNavRenderCursorFlag :: enum
{
    // [removed] -> nil: None          = 0,
    Compact       = 1,       // Compact highlight, no padding/distance from focused item
    AlwaysDraw    = 2,       // Draw rectangular highlight if (g.NavId == id) even when g.NavCursorVisible == false, aka even when using the mouse.
    NoRounding    = 3,
};

ImGuiNavMoveFlags :: bit_set[ImGuiNavMoveFlag; i32]
ImGuiNavMoveFlag :: enum
{
    // [removed] -> nil: None                  = 0,
    LoopX                 = 0,   // On failed request, restart from opposite side
    LoopY                 = 1,
    WrapX                 = 2,   // On failed request, request from opposite side one line down (when NavDir==right) or one line up (when NavDir==left)
    WrapY                 = 3,   // This is not super useful but provided for completeness
    // [moved] WrapMask_             = LoopX | LoopY | WrapX | WrapY,
    AllowCurrentNavId     = 4,   // Allow scoring and considering the current NavId as a move target candidate. This is used when the move source is offset (e.g. pressing PageDown actually needs to send a Up move request, if we are pressing PageDown from the bottom-most item we need to stay in place)
    AlsoScoreVisibleSet   = 5,   // Store alternate result in NavMoveResultLocalVisible that only comprise elements that are already fully visible (used by PageUp/PageDown)
    ScrollToEdgeY         = 6,   // Force scrolling to min/max (used by Home/End) // FIXME-NAV: Aim to remove or reword, probably unnecessary
    Forwarded             = 7,
    DebugNoResult         = 8,   // Dummy scoring for debug purpose, don't apply result
    FocusApi              = 9,   // Requests from focus API can land/focus/activate items even if they are marked with _NoTabStop (see NavProcessItemForTabbingRequest() for details)
    IsTabbing             = 10,  // == Focus + Activate if item is Inputable + DontChangeNavHighlight
    IsPageMove            = 11,  // Identify a PageDown/PageUp request.
    Activate              = 12,  // Activate/select target item.
    NoSelect              = 13,  // Don't trigger selection by not setting g.NavJustMovedTo
    NoSetNavCursorVisible = 14,  // Do not alter the nav cursor visible state
    NoClearActiveId       = 15,  // (Experimental) Do not clear active id when applying move result
};
ImGuiNavMoveFlags_WrapMask_ :: { LoopX , LoopY , WrapX , WrapY }

ImGuiNavLayer :: enum i32
{
    Main  = 0,    // Main scrolling layer
    Menu  = 1,    // Menu layer (access with Alt)
    _COUNT,
};

// Storage for navigation query/results
ImGuiNavItemData :: struct
{
    Window : ^ImGuiWindow,         // Init,Move    // Best candidate window (result->ItemWindow->RootWindowForNav == request->Window)
    ID : ImGuiID,             // Init,Move    // Best candidate item ID
    FocusScopeId : ImGuiID,   // Init,Move    // Best candidate focus scope ID
    RectRel : ImRect,        // Init,Move    // Best candidate bounding box in window relative space
    ItemFlags : ImGuiItemFlags,      // ????,Move    // Best candidate item flags
    DistBox : f32,        //      Move    // Best candidate box distance to current NavId
    DistCenter : f32,     //      Move    // Best candidate center distance to current NavId
    DistAxial : f32,      //      Move    // Best candidate axial distance to current NavId
    SelectionUserData : ImGuiSelectionUserData,//I+Mov    // Best candidate SetNextItemSelectionUserData() value. Valid if (ItemFlags & ImGuiItemFlags_HasSelectionUserData)

    ImGuiNavItemData()  { Clear(); }
    void Clear()        { Window = nil; ID = FocusScopeId = 0; ItemFlags = 0; SelectionUserData = -1; DistBox = DistCenter = DistAxial = math.F32_MAX; }
};

// Storage for PushFocusScope(), g.FocusScopeStack[], g.NavFocusRoute[]
ImGuiFocusScopeData :: struct
{
    ID : ImGuiID,
    WindowID : ImGuiID,
};

//-----------------------------------------------------------------------------
// [SECTION] Typing-select support
//-----------------------------------------------------------------------------

// Flags for GetTypingSelectRequest()
ImGuiTypingSelectFlags :: bit_set[ImGuiTypingSelectFlag; i32]
ImGuiTypingSelectFlag :: enum
{
    // [removed] -> nil: None                 = 0,
    AllowBackspace       = 0,   // Backspace to delete character inputs. If using: ensure GetTypingSelectRequest() is not called more than once per frame (filter by e.g. focus state)
    AllowSingleCharMode  = 1,   // Allow "single char" search mode which is activated when pressing the same character multiple times.
};

// Returned by GetTypingSelectRequest(), designed to eventually be public.
ImGuiTypingSelectRequest :: struct
{
    Flags : ImGuiTypingSelectFlags,              // Flags passed to GetTypingSelectRequest()
    SearchBufferLen : i32,
    SearchBuffer : ^u8,       // Search buffer contents (use full string. unless SingleCharMode is set, in which case use SingleCharSize).
    SelectRequest : bool,      // Set when buffer was modified this frame, requesting a selection.
    SingleCharMode : bool,     // Notify when buffer contains same character repeated, to implement special mode. In this situation it preferred to not display any on-screen search indication.
    SingleCharSize : i8,     // Length in bytes of first letter codepoint (1 for ascii, 2-4 for UTF-8). If (SearchBufferLen==RepeatCharSize) only 1 letter has been input.
};

// Storage for GetTypingSelectRequest()
ImGuiTypingSelectState :: struct
{
    Request : ImGuiTypingSelectRequest,           // User-facing data
    SearchBuffer : [64]u8,           // Search buffer: no need to make dynamic as this search is very transient.
    FocusScope : ImGuiID,
    LastRequestFrame := 0;
    LastRequestTime := 0.0;
    SingleCharModeLock := false; // After a certain single char repeat count we lock into SingleCharMode. Two benefits: 1) buffer never fill, 2) we can provide an immediate SingleChar mode without timer elapsing.

    ImGuiTypingSelectState() { memset(this, 0, size_of(*this)); }
    void            Clear()  { SearchBuffer[0] = 0; SingleCharModeLock = false; } // We preserve remaining data for easier debugging
};

//-----------------------------------------------------------------------------
// [SECTION] Columns support
//-----------------------------------------------------------------------------

// Flags for internal's BeginColumns(). This is an obsolete API. Prefer using BeginTable() nowadays!
ImGuiOldColumnFlags :: bit_set[ImGuiOldColumnFlag; i32]
ImGuiOldColumnFlag :: enum
{
    // [removed] -> nil: None                    = 0,
    NoBorder                = 0,   // Disable column dividers
    NoResize                = 1,   // Disable resizing columns when clicking on the dividers
    NoPreserveWidths        = 2,   // Disable column width preservation when adjusting columns
    NoForceWithinWindow     = 3,   // Disable forcing columns to fit within window
    GrowParentContentsSize  = 4,   // Restore pre-1.51 behavior of extending the parent window contents size but _without affecting the columns width at all_. Will eventually remove.

    // Obsolete names (will be removed)
};

ImGuiOldColumnData :: struct
{
    OffsetNorm : f32,             // Column start offset, normalized 0.0 (far left) -> 1.0 (far right)
    OffsetNormBeforeResize : f32,
    Flags : ImGuiOldColumnFlags,                  // Not exposed
    ClipRect : ImRect,

    ImGuiOldColumnData() { memset(this, 0, size_of(*this)); }
};

ImGuiOldColumns :: struct
{
    ID : ImGuiID,
    Flags : ImGuiOldColumnFlags,
    IsFirstFrame : bool,
    IsBeingResized : bool,
    Current : i32,
    Count : i32,
    OffMinX, OffMaxX : f32,       // Offsets from HostWorkRect.Min.x
    LineMinY, LineMaxY : f32,
    HostCursorPosY : f32,         // Backup of CursorPos at the time of BeginColumns()
    HostCursorMaxPosX : f32,      // Backup of CursorMaxPos at the time of BeginColumns()
    HostInitialClipRect : ImRect,    // Backup of ClipRect at the time of BeginColumns()
    HostBackupClipRect : ImRect,     // Backup of ClipRect during PushColumnsBackground()/PopColumnsBackground()
    HostBackupParentWorkRect : ImRect,//Backup of WorkRect at the time of BeginColumns()
    Columns : [dynamic]ImGuiOldColumnData,
    Splitter : ImDrawListSplitter,

    ImGuiOldColumns()   { memset(this, 0, size_of(*this)); }
};

//-----------------------------------------------------------------------------
// [SECTION] Box-select support
//-----------------------------------------------------------------------------

ImGuiBoxSelectState :: struct
{
    // Active box-selection data (persistent, 1 active at a time)
    ID : ImGuiID,
    IsActive : bool,
    IsStarting : bool,
    IsStartedFromVoid : bool,  // Starting click was not from an item.
    IsStartedSetNavIdOnce : bool,
    RequestClear : bool,
    ImGuiKeyChord           KeyMods : 16;       // Latched key-mods for box-select logic.
    StartPosRel : ImVec2,        // Start position in window-contents relative space (to support scrolling)
    EndPosRel : ImVec2,          // End position in window-contents relative space
    ScrollAccum : ImVec2,        // Scrolling accumulator (to behave at high-frame spaces)
    Window : ^ImGuiWindow,

    // Temporary/Transient data
    UnclipMode : bool,         // (Temp/Transient, here in hot area). Set/cleared by the BeginMultiSelect()/EndMultiSelect() owning active box-select.
    UnclipRect : ImRect,         // Rectangle where ItemAdd() clipping may be temporarily disabled. Need support by multi-select supporting widgets.
    BoxSelectRectPrev : ImRect,  // Selection rectangle in absolute coordinates (derived every frame from BoxSelectStartPosRel and MousePos)
    BoxSelectRectCurr : ImRect,

    ImGuiBoxSelectState()   { memset(this, 0, size_of(*this)); }
};

//-----------------------------------------------------------------------------
// [SECTION] Multi-select support
//-----------------------------------------------------------------------------

// We always assume that -1 is an invalid value (which works for indices and pointers)
#define ImGuiSelectionUserData_Invalid        ((ImGuiSelectionUserData)-1)

// Temporary storage for multi-select
ImGuiMultiSelectTempData :: struct
{
    IO : ImGuiMultiSelectIO,                 // MUST BE FIRST FIELD. Requests are set and returned by BeginMultiSelect()/EndMultiSelect() + written to by user during the loop.
    Storage : ^ImGuiMultiSelectState,
    FocusScopeId : ImGuiID,       // Copied from g.CurrentFocusScopeId (unless another selection scope was pushed manually)
    Flags : ImGuiMultiSelectFlags,
    ScopeRectMin : ImVec2,
    BackupCursorMaxPos : ImVec2,
    LastSubmittedItem : ImGuiSelectionUserData,  // Copy of last submitted item data, used to merge output ranges.
    BoxSelectId : ImGuiID,
    KeyMods : ImGuiKeyChord,
    LoopRequestSetAll : i8,  // -1: no operation, 0: clear all, 1: select all.
    IsEndIO : bool,            // Set when switching IO from BeginMultiSelect() to EndMultiSelect() state.
    IsFocused : bool,          // Set if currently focusing the selection scope (any item of the selection). May be used if you have custom shortcut associated to selection.
    IsKeyboardSetRange : bool, // Set by BeginMultiSelect() when using Shift+Navigation. Because scrolling may be affected we can't afford a frame of lag with Shift+Navigation.
    NavIdPassedBy : bool,
    RangeSrcPassedBy : bool,   // Set by the item that matches RangeSrcItem.
    RangeDstPassedBy : bool,   // Set by the item that matches NavJustMovedToId when IsSetRange is set.

    ImGuiMultiSelectTempData()  { Clear(); }
    void Clear()            { int io_sz = size_of(IO); ClearIO(); memset((rawptr)(&IO + 1), 0, size_of(*this) - io_sz); } // Zero-clear except IO as we preserve IO.Requests[] buffer allocation.
    void ClearIO()          { IO.Requests.resize(0); IO.RangeSrcItem = IO.NavIdItem = ImGuiSelectionUserData_Invalid; IO.NavIdSelected = IO.RangeSrcReset = false; }
};

// Persistent storage for multi-select (as long as selection is alive)
ImGuiMultiSelectState :: struct
{
    Window : ^ImGuiWindow,
    ID : ImGuiID,
    LastFrameActive : i32,    // Last used frame-count, for GC.
    LastSelectionSize : i32,  // Set by BeginMultiSelect() based on optional info provided by user. May be -1 if unknown.
    RangeSelected : i8,      // -1 (don't have) or true/false
    NavIdSelected : i8,      // -1 (don't have) or true/false
    RangeSrcItem : ImGuiSelectionUserData,       //
    NavIdItem : ImGuiSelectionUserData,          // SetNextItemSelectionUserData() value for NavId (if part of submitted items)

    ImGuiMultiSelectState() { Window = nil; ID = 0; LastFrameActive = LastSelectionSize = 0; RangeSelected = NavIdSelected = -1; RangeSrcItem = NavIdItem = ImGuiSelectionUserData_Invalid; }
};

//-----------------------------------------------------------------------------
// [SECTION] Docking support
//-----------------------------------------------------------------------------

DOCKING_HOST_DRAW_CHANNEL_BG :: 0  // Dock host: background fill
DOCKING_HOST_DRAW_CHANNEL_FG :: 1  // Dock host: decorations and contents

when IMGUI_HAS_DOCK {

// Extend ImGuiDockNodeFlags_
ImGuiDockNodeFlagsPrivate_ :: enum i32
{
    // [Internal]
    ImGuiDockNodeFlags_DockSpace                = 1 << 10,  // Saved // A dockspace is a node that occupy space within an existing user window. Otherwise the node is floating and create its own window.
    ImGuiDockNodeFlags_CentralNode              = 1 << 11,  // Saved // The central node has 2 main properties: stay visible when empty, only use "remaining" spaces from its neighbor.
    ImGuiDockNodeFlags_NoTabBar                 = 1 << 12,  // Saved // Tab bar is completely unavailable. No triangle in the corner to enable it back.
    ImGuiDockNodeFlags_HiddenTabBar             = 1 << 13,  // Saved // Tab bar is hidden, with a triangle in the corner to show it again (NB: actual tab-bar instance may be destroyed as this is only used for single-window tab bar)
    ImGuiDockNodeFlags_NoWindowMenuButton       = 1 << 14,  // Saved // Disable window/docking menu (that one that appears instead of the collapse button)
    ImGuiDockNodeFlags_NoCloseButton            = 1 << 15,  // Saved // Disable close button
    ImGuiDockNodeFlags_NoResizeX                = 1 << 16,  //       //
    ImGuiDockNodeFlags_NoResizeY                = 1 << 17,  //       //
    ImGuiDockNodeFlags_DockedWindowsInFocusRoute= 1 << 18,  //       // Any docked window will be automatically be focus-route chained (window->ParentWindowForFocusRoute set to this) so Shortcut() in this window can run when any docked window is focused.

    // Disable docking/undocking actions in this dockspace or individual node (existing docked nodes will be preserved)
    // Those are not exposed in public because the desirable sharing/inheriting/copy-flag-on-split behaviors are quite difficult to design and understand.
    // The two public flags ImGuiDockNodeFlags_NoDockingOverCentralNode/ImGuiDockNodeFlags_NoDockingSplit don't have those issues.
    ImGuiDockNodeFlags_NoDockingSplitOther      = 1 << 19,  //       // Disable this node from splitting other windows/nodes.
    ImGuiDockNodeFlags_NoDockingOverMe          = 1 << 20,  //       // Disable other windows/nodes from being docked over this node.
    ImGuiDockNodeFlags_NoDockingOverOther       = 1 << 21,  //       // Disable this node from being docked over another window or non-empty node.
    ImGuiDockNodeFlags_NoDockingOverEmpty       = 1 << 22,  //       // Disable this node from being docked over an empty node (e.g. DockSpace with no other windows)
    ImGuiDockNodeFlags_NoDocking                = ImGuiDockNodeFlags_NoDockingOverMe | ImGuiDockNodeFlags_NoDockingOverOther | ImGuiDockNodeFlags_NoDockingOverEmpty | ImGuiDockNodeFlags_NoDockingSplit | ImGuiDockNodeFlags_NoDockingSplitOther,

    // Masks
    ImGuiDockNodeFlags_SharedFlagsInheritMask_  = ~0,
    ImGuiDockNodeFlags_NoResizeFlagsMask_       = cast(ast) ast) DockNodeFlags_NoResizeesizeGuiDockNodeFlags_NoResizeX | ImGuiDockNodeFlags_NoResizeY,

    // When splitting, those local flags are moved to the inheriting child, never duplicated
    ImGuiDockNodeFlags_LocalFlagsTransferMask_  = cast(ast) ast) DockNodeFlags_NoDockingSplitSplitGuiDockNodeFlags_NoResizeFlagsMask_ | cast(_ |) cast(_ |) odeFlags_AutoHideTabBarHideTabBarckNodeFlags_CentralNode | ImGuiDockNodeFlags_NoTabBar | ImGuiDockNodeFlags_HiddenTabBar | ImGuiDockNodeFlags_NoWindowMenuButton | ImGuiDockNodeFlags_NoCloseButton,
    ImGuiDockNodeFlags_SavedFlagsMask_          = ImGuiDockNodeFlags_NoResizeFlagsMask_ | ImGuiDockNodeFlags_DockSpace | ImGuiDockNodeFlags_CentralNode | ImGuiDockNodeFlags_NoTabBar | ImGuiDockNodeFlags_HiddenTabBar | ImGuiDockNodeFlags_NoWindowMenuButton | ImGuiDockNodeFlags_NoCloseButton,
};

// Store the source authority (dock node vs window) of a field
ImGuiDataAuthority_ :: enum i32
{
    Auto,
    DockNode,
    Window,
};

ImGuiDockNodeState :: enum i32
{
    Unknown,
    HostWindowHiddenBecauseSingleWindow,
    HostWindowHiddenBecauseWindowsAreResizing,
    HostWindowVisible,
};

// sizeof() 156~192
ImGuiDockNode :: struct
{
    ID : ImGuiID,
    SharedFlags : ImGuiDockNodeFlags,                // (Write) Flags shared by all nodes of a same dockspace hierarchy (inherited from the root node)
    LocalFlags : ImGuiDockNodeFlags,                 // (Write) Flags specific to this node
    LocalFlagsInWindows : ImGuiDockNodeFlags,        // (Write) Flags specific to this node, applied from windows
    MergedFlags : ImGuiDockNodeFlags,                // (Read)  Effective flags (== SharedFlags | LocalFlagsInNode | LocalFlagsInWindows)
    State : ImGuiDockNodeState,
    ParentNode : ^ImGuiDockNode,
    ChildNodes : [2]^ImGuiDockNode,              // [Split node only] Child nodes (left/right or top/bottom). Consider switching to an array.
    Windows : [dynamic]^ImGuiWindow,                    // Note: unordered list! Iterate TabBar->Tabs for user-order.
    TabBar : ^ImGuiTabBar,
    Pos : ImVec2,                        // Current position
    Size : ImVec2,                       // Current size
    SizeRef : ImVec2,                    // [Split node only] Last explicitly written-to size (overridden when using a splitter affecting the node), used to calculate Size.
    SplitAxis : ImGuiAxis,                  // [Split node only] Split axis (X or Y)
    WindowClass : ImGuiWindowClass,                // [Root node only]
    LastBgColor : u32,

    HostWindow : ^ImGuiWindow,
    VisibleWindow : ^ImGuiWindow,              // Generally point to window which is ID is == SelectedTabID, but when CTRL+Tabbing this can be a different window.
    CentralNode : ^ImGuiDockNode,                // [Root node only] Pointer to central node.
    OnlyNodeWithWindows : ^ImGuiDockNode,        // [Root node only] Set when there is a single visible node within the hierarchy.
    CountNodeWithWindows : i32,       // [Root node only]
    LastFrameAlive : i32,             // Last frame number the node was updated or kept alive explicitly with DockSpace() + ImGuiDockNodeFlags_KeepAliveOnly
    LastFrameActive : i32,            // Last frame number the node was updated.
    LastFrameFocused : i32,           // Last frame number the node was focused.
    LastFocusedNodeId : ImGuiID,          // [Root node only] Which of our child docking node (any ancestor in the hierarchy) was last focused.
    SelectedTabId : ImGuiID,              // [Leaf node only] Which of our tab/window is selected.
    WantCloseTabId : ImGuiID,             // [Leaf node only] Set when closing a specific tab/window.
    RefViewportId : ImGuiID,              // Reference viewport ID from visible window when HostWindow == NULL.
    ImGuiDataAuthority      AuthorityForPos         :3;
    ImGuiDataAuthority      AuthorityForSize        :3;
    ImGuiDataAuthority      AuthorityForViewport    :3;
    bool                    IsVisible               :1; // Set to false when the node is hidden (usually disabled as it has no active window)
    bool                    IsFocused               :1;
    bool                    IsBgDrawnThisFrame      :1;
    bool                    HasCloseButton          :1; // Provide space for a close button (if any of the docked window has one). Note that button may be hidden on window without one.
    bool                    HasWindowMenuButton     :1;
    bool                    HasCentralNodeChild     :1;
    bool                    WantCloseAll            :1; // Set when closing all tabs at once.
    bool                    WantLockSizeOnce        :1;
    bool                    WantMouseMove           :1; // After a node extraction we need to transition toward moving the newly created host window
    bool                    WantHiddenTabBarUpdate  :1;
    bool                    WantHiddenTabBarToggle  :1;

    ImGuiDockNode(ImGuiID id);
    ~ImGuiDockNode();
    bool                    IsRootNode() const      { return ParentNode == nil; }
    bool                    IsDockSpace() const     { return (MergedFlags & ImGuiDockNodeFlags_DockSpace) != 0; }
    bool                    IsFloatingNode() const  { return ParentNode == nil && (MergedFlags & ImGuiDockNodeFlags_DockSpace) == 0; }
    bool                    IsCentralNode() const   { return (MergedFlags & ImGuiDockNodeFlags_CentralNode) != 0; }
    bool                    IsHiddenTabBar() const  { return (MergedFlags & ImGuiDockNodeFlags_HiddenTabBar) != 0; } // Hidden tab bar can be shown back by clicking the small triangle
    bool                    IsNoTabBar() const      { return (MergedFlags & ImGuiDockNodeFlags_NoTabBar) != 0; }     // Never show a tab bar
    bool                    IsSplitNode() const     { return ChildNodes[0] != nil; }
    bool                    IsLeafNode() const      { return ChildNodes[0] == nil; }
    bool                    IsEmpty() const         { return ChildNodes[0] == nil && Windows.Size == 0; }
    ImRect                  Rect() const            { return ImRect(Pos.x, Pos.y, Pos.x + Size.x, Pos.y + Size.y); }

    void                    SetLocalFlags(ImGuiDockNodeFlags flags) { LocalFlags = flags; UpdateMergedFlags(); }
    void                    UpdateMergedFlags()     { MergedFlags = SharedFlags | LocalFlags | LocalFlagsInWindows; }
};

// List of colors that are stored at the time of Begin() into Docked Windows.
// We currently store the packed colors in a simple array window->DockStyle.Colors[].
// A better solution may involve appending into a log of colors in ImGuiContext + store offsets into those arrays in ImGuiWindow,
// but it would be more complex as we'd need to double-buffer both as e.g. drop target may refer to window from last frame.
ImGuiWindowDockStyleCol :: enum i32
{
    Text,
    TabHovered,
    TabFocused,
    TabSelected,
    TabSelectedOverline,
    TabDimmed,
    TabDimmedSelected,
    TabDimmedSelectedOverline,
    _COUNT,
};

// We don't store style.Alpha: dock_node->LastBgColor embeds it and otherwise it would only affect the docking tab, which intuitively I would say we don't want to.
ImGuiWindowDockStyle :: struct
{
    Colors : [ImGuiWindowDockStyleCol_COUNT]u32,
};

ImGuiDockContext :: struct
{
    Nodes : ImGuiStorage,          // Map ID -> ImGuiDockNode*: Active nodes
    Requests : [dynamic]ImGuiDockRequest,
    NodesSettings : [dynamic]ImGuiDockNodeSettings,
    WantFullRebuild : bool,
    ImGuiDockContext()              { memset(this, 0, size_of(*this)); }
};

} // #ifdef IMGUI_HAS_DOCK

//-----------------------------------------------------------------------------
// [SECTION] Viewport support
//-----------------------------------------------------------------------------

// ImGuiViewport Private/Internals fields (cardinal sin: we are using inheritance!)
// Every instance of ImGuiViewport is in fact a ImGuiViewportP.
struct ImGuiViewportP : public ImGuiViewport
{
    Window : ^ImGuiWindow                 // Set when the viewport is owned by a window (and ImGuiViewportFlags_CanHostOtherWindows is NOT set)
    Idx : i32
    LastFrameActive : i32        // Last frame number this viewport was activated by a window
    LastFocusedStampCount : i32  // Last stamp number from when a window hosted by this viewport was focused (by comparing this value between two viewport we have an implicit viewport z-order we use as fallback)
    LastNameHash : ImGuiID
    LastPos : ImVec2
    LastSize : ImVec2
    Alpha : f32                  // Window opacity (when dragging dockable windows/viewports we make them transparent)
    LastAlpha : f32
    LastFocusedHadNavWindow : bool// Instead of maintaining a LastFocusedWindow (which may harder to correctly maintain), we merely store weither NavWindow != NULL last time the viewport was focused.
    PlatformMonitor : i16
    BgFgDrawListsLastFrame : [2]i32 // Last frame number the background (0) and foreground (1) draw lists were used
    BgFgDrawLists : [2]^ImDrawList       // Convenience background (0) and foreground (1) draw lists. We use them to draw software mouser cursor when io.MouseDrawCursor is set and to draw most debug overlays.
    DrawDataP : ImDrawData
    DrawDataBuilder : ImDrawDataBuilder        // Temporary data while building final ImDrawData
    LastPlatformPos : ImVec2
    LastPlatformSize : ImVec2
    LastRendererSize : ImVec2

    // Per-viewport work area
    // - Insets are >= 0.0f values, distance from viewport corners to work area.
    // - BeginMainMenuBar() and DockspaceOverViewport() tend to use work area to avoid stepping over existing contents.
    // - Generally 'safeAreaInsets' in iOS land, 'DisplayCutout' in Android land.
    WorkInsetMin : ImVec2           // Work Area inset locked for the frame. GetWorkRect() always fits within GetMainRect().
    WorkInsetMax : ImVec2           // "
    BuildWorkInsetMin : ImVec2      // Work Area inset accumulator for current frame, to become next frame's WorkInset
    BuildWorkInsetMax : ImVec2      // "

    ImGuiViewportP()                    { Window = nil; Idx = -1; LastFrameActive = BgFgDrawListsLastFrame[0] = BgFgDrawListsLastFrame[1] = LastFocusedStampCount = -1; LastNameHash = 0; Alpha = LastAlpha = 1.0; LastFocusedHadNavWindow = false; PlatformMonitor = -1; BgFgDrawLists[0] = BgFgDrawLists[1] = nil; LastPlatformPos = LastPlatformSize = LastRendererSize = ImVec2{math.F32_MAX, math.F32_MAX}; }
    ~ImGuiViewportP()                   { if (BgFgDrawLists[0]) IM_DELETE(BgFgDrawLists[0]); if (BgFgDrawLists[1]) IM_DELETE(BgFgDrawLists[1]); }
    void    ClearRequestFlags()         { PlatformRequestClose = PlatformRequestMove = PlatformRequestResize = false; }

    // Calculate work rect pos/size given a set of offset (we have 1 pair of offset for rect locked from last frame data, and 1 pair for currently building rect)
    CalcWorkRectPos := ImVec2{const ImVec2& inset_min} const                           { return ImVec2{Pos.x + inset_min.x, Pos.y + inset_min.y}; }
    CalcWorkRectSize := CalcWo(o(nst ImVec2& inset_min, const ImVec2& inset_max) const { return ImVec2{ImMax(0.0, Size.x - inset_min.x - inset_max.x}, ImMax(0.0, Size.y - inset_min.y - inset_max.y)); }
    void    UpdateWorkRect()            { WorkPos = CalcWorkRectPos(WorkInsetMin); WorkSize = CalcWorkRectSize(WorkInsetMin, WorkInsetMax); } // Update public fields

    // Helpers to retrieve ImRect (we don't need to store BuildWorkRect as every access tend to change it, hence the code asymmetry)
    GetMainRect := ImRect() const         { return ImRect(Pos.x, Pos.y, Pos.x + Size.x, Pos.y + Size.y); }
    GetWorkRect := ImRect() const         { return ImRect(WorkPos.x, WorkPos.y, WorkPos.x + WorkSize.x, WorkPos.y + WorkSize.y); }
    GetBuildWorkRect := ImRect() const    { ImVec2 pos = CalcWorkRectPos(BuildWorkInsetMin); ImVec2 size = CalcWorkRectSize(BuildWorkInsetMin, BuildWorkInsetMax); return ImRect(pos.x, pos.y, pos.x + size.x, pos.y + size.y); }
};

//-----------------------------------------------------------------------------
// [SECTION] Settings support
//-----------------------------------------------------------------------------

// Windows data saved in imgui.ini file
// Because we never destroy or rename ImGuiWindowSettings, we can store the names in a separate buffer easily.
// (this is designed to be stored in a ImChunkStream buffer, with the variable-length Name following our structure)
ImGuiWindowSettings :: struct
{
    ID : ImGuiID,
    Pos : ImVec2ih,            // NB: Settings position are stored RELATIVE to the viewport! Whereas runtime ones are absolute positions.
    Size : ImVec2ih,
    ViewportPos : ImVec2ih,
    ViewportId : ImGuiID,
    DockId : ImGuiID,         // ID of last known DockNode (even if the DockNode is invisible because it has only 1 active window), or 0 if none.
    ClassId : ImGuiID,        // ID of window class if specified
    DockOrder : i16,      // Order of the last time the window was visible within its DockNode. This is used to reorder windows that are reappearing on the same frame. Same value between windows that were active and windows that were none are possible.
    Collapsed : bool,
    IsChild : bool,
    WantApply : bool,      // Set when loaded from .ini data (to enable merging/loading .ini data into an already running context)
    WantDelete : bool,     // Set to invalidate/delete the settings entry

    ImGuiWindowSettings()       { memset(this, 0, size_of(*this)); DockOrder = -1; }
    u8* GetName()             { return (u8*)(this + 1); }
};

ImGuiSettingsHandler :: struct
{
    TypeName : ^u8,       // Short description stored in .ini file. Disallowed characters: '[' ']'
    TypeHash : ImGuiID,       // == ImHashStr(TypeName)
    void        (*ClearAllFn)(ImGuiContext* ctx, ImGuiSettingsHandler* handler);                                // Clear all settings data
    void        (*ReadInitFn)(ImGuiContext* ctx, ImGuiSettingsHandler* handler);                                // Read: Called before reading (in registration order)
    rawptr       (*ReadOpenFn)(ImGuiContext* ctx, ImGuiSettingsHandler* handler, const u8* name);              // Read: Called when entering into a new ini entry e.g. "[Window][Name]"
    void        (*ReadLineFn)(ImGuiContext* ctx, ImGuiSettingsHandler* handler, rawptr entry, const u8* line); // Read: Called for every line of text within an ini entry
    void        (*ApplyAllFn)(ImGuiContext* ctx, ImGuiSettingsHandler* handler);                                // Read: Called after reading (in registration order)
    void        (*WriteAllFn)(ImGuiContext* ctx, ImGuiSettingsHandler* handler, ImGuiTextBuffer* out_buf);      // Write: Output every entries into 'out_buf'
    UserData : rawptr,

    ImGuiSettingsHandler() { memset(this, 0, size_of(*this)); }
};

//-----------------------------------------------------------------------------
// [SECTION] Localization support
//-----------------------------------------------------------------------------

// This is experimental and not officially supported, it'll probably fall short of features, if/when it does we may backtrack.
ImGuiLocKey :: enum i32
{
    ImGuiLocKey_VersionStr,
    ImGuiLocKey_TableSizeOne,
    ImGuiLocKey_TableSizeAllFit,
    ImGuiLocKey_TableSizeAllDefault,
    ImGuiLocKey_TableResetOrder,
    ImGuiLocKey_WindowingMainMenuBar,
    ImGuiLocKey_WindowingPopup,
    ImGuiLocKey_WindowingUntitled,
    ImGuiLocKey_OpenLink_s,
    ImGuiLocKey_CopyLink,
    ImGuiLocKey_DockingHideTabBar,
    ImGuiLocKey_DockingHoldShiftToDock,
    ImGuiLocKey_DockingDragToUndockOrMoveNode,
    ImGuiLocKey_COUNT
};

ImGuiLocEntry :: struct
{
    Key : ImGuiLocKey,
    Text : ^u8,
};

//-----------------------------------------------------------------------------
// [SECTION] Error handling, State recovery support
//-----------------------------------------------------------------------------

// Macros used by Recoverable Error handling
// - Only dispatch error if _EXPR: evaluate as assert (similar to an assert macro).
// - The message will always be a string literal, in order to increase likelihood of being display by an assert handler.
// - See 'Demo->Configuration->Error Handling' and ImGuiIO definitions for details on error handling.
// - Read https://github.com/ocornut/imgui/wiki/Error-Handling for details on error handling.
when !(IM_ASSERT_USER_ERROR) {
}

// The error callback is currently not public, as it is expected that only advanced users will rely on it.
ImGuiErrorCallback :: #type proc(ctx : ^ImGuiContext, user_data : rawptr, msg : ^u8) // Function signature for g.ErrorCallback

//-----------------------------------------------------------------------------
// [SECTION] Metrics, Debug Tools
//-----------------------------------------------------------------------------

// See IMGUI_DEBUG_LOG() and IMGUI_DEBUG_LOG_XXX() macros.
ImGuiDebugLogFlags :: bit_set[ImGuiDebugLogFlag; i32]
ImGuiDebugLogFlag :: enum
{
    // Event types
    // [removed] -> nil: None                 = 0,
    EventError           = 0,   // Error submitted by IM_ASSERT_USER_ERROR()
    EventActiveId        = 1,
    EventFocus           = 2,
    EventPopup           = 3,
    EventNav             = 4,
    EventClipper         = 5,
    EventSelection       = 6,
    EventIO              = 7,
    EventFont            = 8,
    EventInputRouting    = 9,
    EventDocking         = 10,
    EventViewport        = 11,

    // [moved] EventMask_           = EventError | EventActiveId | EventFocus | EventPopup | EventNav | EventClipper | EventSelection | EventIO | EventFont | EventInputRouting | EventDocking | EventViewport,
    OutputToTTY          = 20,  // Also send output to TTY
    OutputToTestEngine   = 21,  // Also send output to Test Engine
};
ImGuiDebugLogFlags_EventMask_ :: { EventError , EventActiveId , EventFocus , EventPopup , EventNav , EventClipper , EventSelection , EventIO , EventFont , EventInputRouting , EventDocking , EventViewport }

ImGuiDebugAllocEntry :: struct
{
    FrameCount : i32,
    AllocCount : u16,
    FreeCount : u16,
};

ImGuiDebugAllocInfo :: struct
{
    TotalAllocCount : i32,            // Number of call to MemAlloc().
    TotalFreeCount : i32,
    LastEntriesIdx : u16,             // Current index in buffer
    LastEntriesBuf : [6]ImGuiDebugAllocEntry, // Track last 6 frames that had allocations

    ImGuiDebugAllocInfo() { memset(this, 0, size_of(*this)); }
};

ImGuiMetricsConfig :: struct
{
    ShowDebugLog := false;
    ShowIDStackTool := false;
    ShowWindowsRects := false;
    ShowWindowsBeginOrder := false;
    ShowTablesRects := false;
    ShowDrawCmdMesh := true;
    ShowDrawCmdBoundingBoxes := true;
    ShowTextEncodingViewer := false;
    ShowAtlasTintedWithTextColor := false;
    ShowDockingNodes := false;
    ShowWindowsRectsType := -1;
    ShowTablesRectsType := -1;
    HighlightMonitorIdx := -1;
    HighlightViewportID := 0;
};

ImGuiStackLevelInfo :: struct
{
    ID : ImGuiID,
    QueryFrameCount : i8,            // >= 1: Query in progress
    QuerySuccess : bool,               // Obtained result from DebugHookIdInfo()
    ImGuiDataType           DataType : 8;
    Desc : [57]u8,                   // Arbitrarily sized buffer to hold a result (FIXME: could replace Results[] with a chunk stream?) FIXME: Now that we added CTRL+C this should be fixed.

    ImGuiStackLevelInfo()   { memset(this, 0, size_of(*this)); }
};

// State for ID Stack tool queries
ImGuiIDStackTool :: struct
{
    LastActiveFrame : i32,
    StackLevel : i32,                 // -1: query stack and resize Results, >= 0: individual stack level
    QueryId : ImGuiID,                    // ID to query details for
    Results : [dynamic]ImGuiStackLevelInfo,
    CopyToClipboardOnCtrlC : bool,
    CopyToClipboardLastTime : f32,

    ImGuiIDStackTool()      { memset(this, 0, size_of(*this)); CopyToClipboardLastTime = -math.F32_MAX; }
};

//-----------------------------------------------------------------------------
// [SECTION] Generic context hooks
//-----------------------------------------------------------------------------

ImGuiContextHookCallback :: #type proc(ctx : ^ImGuiContext, hook : ^ImGuiContextHook)
enum ImGuiContextHookType { ImGuiContextHookType_NewFramePre, ImGuiContextHookType_NewFramePost, ImGuiContextHookType_EndFramePre, ImGuiContextHookType_EndFramePost, ImGuiContextHookType_RenderPre, ImGuiContextHookType_RenderPost, ImGuiContextHookType_Shutdown, ImGuiContextHookType_PendingRemoval_ };

ImGuiContextHook :: struct
{
    HookId : ImGuiID,     // A unique ID assigned by AddContextHook()
    Type : ImGuiContextHookType,
    Owner : ImGuiID,
    Callback : ImGuiContextHookCallback,
    UserData : rawptr,

    ImGuiContextHook()          { memset(this, 0, size_of(*this)); }
};

//-----------------------------------------------------------------------------
// [SECTION] ImGuiContext (main Dear ImGui context)
//-----------------------------------------------------------------------------

ImGuiContext :: struct
{
    Initialized : bool,
    FontAtlasOwnedByContext : bool,            // IO.Fonts-> is owned by the ImGuiContext and will be destructed along with it.
    IO : ImGuiIO,
    PlatformIO : ImGuiPlatformIO,
    Style : ImGuiStyle,
    ConfigFlagsCurrFrame : ImGuiConfigFlags,               // = g.IO.ConfigFlags at the time of NewFrame()
    ConfigFlagsLastFrame : ImGuiConfigFlags,
    Font : ^ImFont,                               // (Shortcut) == FontStack.empty() ? IO.Font : FontStack.back()
    FontSize : f32,                           // (Shortcut) == FontBaseSize * g.CurrentWindow->FontWindowScale == window->FontSize(). Text height for current window.
    FontBaseSize : f32,                       // (Shortcut) == IO.FontGlobalScale * Font->Scale * Font->FontSize. Base text height.
    FontScale : f32,                          // == FontSize / Font->FontSize
    CurrentDpiScale : f32,                    // Current window/viewport DpiScale == CurrentViewport->DpiScale
    DrawListSharedData : ImDrawListSharedData,
    Time : f64,
    FrameCount : i32,
    FrameCountEnded : i32,
    FrameCountPlatformEnded : i32,
    FrameCountRendered : i32,
    WithinEndChildID : ImGuiID,                   // Set within EndChild()
    WithinFrameScope : bool,                   // Set by NewFrame(), cleared by EndFrame()
    WithinFrameScopeWithImplicitWindow : bool, // Set by NewFrame(), cleared by EndFrame() when the implicit debug window has been pushed
    GcCompactAll : bool,                       // Request full GC
    TestEngineHookItems : bool,                // Will call test engine hooks: ImGuiTestEngineHook_ItemAdd(), ImGuiTestEngineHook_ItemInfo(), ImGuiTestEngineHook_Log()
    TestEngine : rawptr,                         // Test engine user data
    ContextName : [16]u8,                    // Storage for a context name (to facilitate debugging multi-context setups)

    // Inputs
    InputEventsQueue : [dynamic]ImGuiInputEvent,                 // Input events which will be trickled/written into IO structure.
    InputEventsTrail : [dynamic]ImGuiInputEvent,                 // Past input events processed in NewFrame(). This is to allow domain-specific application to access e.g mouse/pen trail.
    InputEventsNextMouseSource : ImGuiMouseSource,
    InputEventsNextEventId : u32,

    // Windows state
    Windows : [dynamic]^ImGuiWindow,                            // Windows, sorted in display order, back to front
    WindowsFocusOrder : [dynamic]^ImGuiWindow,                  // Root windows, sorted in focus order, back to front.
    WindowsTempSortBuffer : [dynamic]^ImGuiWindow,              // Temporary buffer used in EndFrame() to reorder windows so parents are kept before their child
    CurrentWindowStack : [dynamic]ImGuiWindowStackData,
    WindowsById : ImGuiStorage,                        // Map window's ImGuiID to ImGuiWindow*
    WindowsActiveCount : i32,                 // Number of unique windows submitted by frame
    WindowsHoverPadding : ImVec2,                // Padding around resizable windows for which hovering on counts as hovering the window == ImMax(style.TouchExtraPadding, WINDOWS_HOVER_PADDING).
    DebugBreakInWindow : ImGuiID,                 // Set to break in Begin() call.
    CurrentWindow : ^ImGuiWindow,                      // Window being drawn into
    HoveredWindow : ^ImGuiWindow,                      // Window the mouse is hovering. Will typically catch mouse inputs.
    HoveredWindowUnderMovingWindow : ^ImGuiWindow,     // Hovered window ignoring MovingWindow. Only set if MovingWindow is set.
    HoveredWindowBeforeClear : ^ImGuiWindow,           // Window the mouse is hovering. Filled even with _NoMouse. This is currently useful for multi-context compositors.
    MovingWindow : ^ImGuiWindow,                       // Track the window we clicked on (in order to preserve focus). The actual window that is moved is generally MovingWindow->RootWindowDockTree.
    WheelingWindow : ^ImGuiWindow,                     // Track the window we started mouse-wheeling on. Until a timer elapse or mouse has moved, generally keep scrolling the same window even if during the course of scrolling the mouse ends up hovering a child window.
    WheelingWindowRefMousePos : ImVec2,
    WheelingWindowStartFrame : i32,           // This may be set one frame before WheelingWindow is != NULL
    WheelingWindowScrolledFrame : i32,
    WheelingWindowReleaseTimer : f32,
    WheelingWindowWheelRemainder : ImVec2,
    WheelingAxisAvg : ImVec2,

    // Item/widgets state and tracking information
    DebugDrawIdConflicts : ImGuiID,               // Set when we detect multiple items with the same identifier
    DebugHookIdInfo : ImGuiID,                    // Will call core hooks: DebugHookIdInfo() from GetID functions, used by ID Stack Tool [next HoveredId/ActiveId to not pull in an extra cache-line]
    HoveredId : ImGuiID,                          // Hovered widget, filled during the frame
    HoveredIdPreviousFrame : ImGuiID,
    HoveredIdPreviousFrameItemCount : i32,    // Count numbers of items using the same ID as last frame's hovered id
    HoveredIdTimer : f32,                     // Measure contiguous hovering time
    HoveredIdNotActiveTimer : f32,            // Measure contiguous hovering time where the item has not been active
    HoveredIdAllowOverlap : bool,
    HoveredIdIsDisabled : bool,                // At least one widget passed the rect test, but has been discarded by disabled flag or popup inhibit. May be true even if HoveredId == 0.
    ItemUnclipByLog : bool,                    // Disable ItemAdd() clipping, essentially a memory-locality friendly copy of LogEnabled
    ActiveId : ImGuiID,                           // Active widget
    ActiveIdIsAlive : ImGuiID,                    // Active widget has been seen this frame (we can't use a bool as the ActiveId may change within the frame)
    ActiveIdTimer : f32,
    ActiveIdIsJustActivated : bool,            // Set at the time of activation for one frame
    ActiveIdAllowOverlap : bool,               // Active widget allows another widget to steal active id (generally for overlapping widgets, but not always)
    ActiveIdNoClearOnFocusLoss : bool,         // Disable losing active id if the active id window gets unfocused.
    ActiveIdHasBeenPressedBefore : bool,       // Track whether the active id led to a press (this is to allow changing between PressOnClick and PressOnRelease without pressing twice). Used by range_select branch.
    ActiveIdHasBeenEditedBefore : bool,        // Was the value associated to the widget Edited over the course of the Active state.
    ActiveIdHasBeenEditedThisFrame : bool,
    ActiveIdFromShortcut : bool,
    i32                     ActiveIdMouseButton : 8;
    ActiveIdClickOffset : ImVec2,                // Clicked offset from upper-left corner, if applicable (currently only set by ButtonBehavior)
    ActiveIdWindow : ^ImGuiWindow,
    ActiveIdSource : ImGuiInputSource,                     // Activating source: .Mouse OR ImGuiInputSource_Keyboard OR ImGuiInputSource_Gamepad
    ActiveIdPreviousFrame : ImGuiID,
    ActiveIdPreviousFrameIsAlive : bool,
    ActiveIdPreviousFrameHasBeenEditedBefore : bool,
    ActiveIdPreviousFrameWindow : ^ImGuiWindow,
    ActiveIdValueOnActivation : ImGuiDataTypeStorage,          // Backup of initial value at the time of activation. ONLY SET BY SPECIFIC WIDGETS: DragXXX and SliderXXX.
    LastActiveId : ImGuiID,                       // Store the last non-zero ActiveId, useful for animation.
    LastActiveIdTimer : f32,                  // Store the last non-zero ActiveId timer since the beginning of activation, useful for animation.

    // Key/Input Ownership + Shortcut Routing system
    // - The idea is that instead of "eating" a given key, we can link to an owner.
    // - Input query can then read input by specifying ImGuiKeyOwner_Any (== 0), ImGuiKeyOwner_NoOwner (== -1) or a custom ID.
    // - Routing is requested ahead of time for a given chord (Key + Mods) and granted in NewFrame().
    LastKeyModsChangeTime : f64,              // Record the last time key mods changed (affect repeat delay when using shortcut logic)
    LastKeyModsChangeFromNoneTime : f64,      // Record the last time key mods changed away from being 0 (affect repeat delay when using shortcut logic)
    LastKeyboardKeyPressTime : f64,           // Record the last time a keyboard key (ignore mouse/gamepad ones) was pressed.
    KeysMayBeCharInput : ImBitArrayForNamedKeys,                 // Lookup to tell if a key can emit char input, see IsKeyChordPotentiallyCharInput(). sizeof() = 20 bytes
    KeysOwnerData : [ImGuiKey_NamedKey_COUNT]ImGuiKeyOwnerData,
    KeysRoutingTable : ImGuiKeyRoutingTable,
    ActiveIdUsingNavDirMask : u32,            // Active widget will want to read those nav move requests (e.g. can activate a button and move away from it)
    ActiveIdUsingAllKeyboardKeys : bool,       // Active widget will want to read all keyboard keys inputs. (this is a shortcut for not taking ownership of 100+ keys, frequently used by drag operations)
    DebugBreakInShortcutRouting : ImGuiKeyChord,        // Set to break in SetShortcutRouting()/Shortcut() calls.
    //ImU32                 ActiveIdUsingNavInputMask;          // [OBSOLETE] Since (IMGUI_VERSION_NUM >= 18804) : 'g.ActiveIdUsingNavInputMask |= (1 << ImGuiNavInput_Cancel);' becomes --> 'SetKeyOwner(ImGuiKey_Escape, g.ActiveId) and/or SetKeyOwner(ImGuiKey_NavGamepadCancel, g.ActiveId);'

    // Next window/item data
    CurrentFocusScopeId : ImGuiID,                // Value for currently appending items == g.FocusScopeStack.back(). Not to be mistaken with g.NavFocusScopeId.
    CurrentItemFlags : ImGuiItemFlags,                   // Value for currently appending items == g.ItemFlagsStack.back()
    DebugLocateId : ImGuiID,                      // Storage for DebugLocateItemOnHover() feature: this is read by ItemAdd() so we keep it in a hot/cached location
    NextItemData : ImGuiNextItemData,                       // Storage for SetNextItem** functions
    LastItemData : ImGuiLastItemData,                       // Storage for last submitted item (setup by ItemAdd)
    NextWindowData : ImGuiNextWindowData,                     // Storage for SetNextWindow** functions
    DebugShowGroupRects : bool,

    // Shared stacks
    DebugFlashStyleColorIdx : ImGuiCol,    // (Keep close to ColorStack to share cache line)
    ColorStack : [dynamic]ImGuiColorMod,                 // Stack for PushStyleColor()/PopStyleColor() - inherited by Begin()
    StyleVarStack : [dynamic]ImGuiStyleMod,              // Stack for PushStyleVar()/PopStyleVar() - inherited by Begin()
    FontStack : [dynamic]^ImFont,                  // Stack for PushFont()/PopFont() - inherited by Begin()
    FocusScopeStack : [dynamic]ImGuiFocusScopeData,            // Stack for PushFocusScope()/PopFocusScope() - inherited by BeginChild(), pushed into by Begin()
    ItemFlagsStack : [dynamic]ImGuiItemFlags,             // Stack for PushItemFlag()/PopItemFlag() - inherited by Begin()
    GroupStack : [dynamic]ImGuiGroupData,                 // Stack for BeginGroup()/EndGroup() - not inherited by Begin()
    OpenPopupStack : [dynamic]ImGuiPopupData,             // Which popups are open (persistent)
    BeginPopupStack : [dynamic]ImGuiPopupData,            // Which level of BeginPopup() we are in (reset every frame)
    ImVector<ImGuiTreeNodeStackData>TreeNodeStack;              // Stack for TreeNode()

    // Viewports
    Viewports : [dynamic]^ImGuiViewportP,                        // Active viewports (always 1+, and generally 1 unless multi-viewports are enabled). Each viewports hold their copy of ImDrawData.
    CurrentViewport : ^ImGuiViewportP,                    // We track changes of viewport (happening in Begin) so we can call Platform_OnChangedViewport()
    MouseViewport : ^ImGuiViewportP,
    MouseLastHoveredViewport : ^ImGuiViewportP,           // Last known viewport that was hovered by mouse (even if we are not hovering any viewport any more) + honoring the _NoInputs flag.
    PlatformLastFocusedViewportId : ImGuiID,
    FallbackMonitor : ImGuiPlatformMonitor,                    // Virtual monitor used as fallback if backend doesn't provide monitor information.
    PlatformMonitorsFullWorkRect : ImRect,       // Bounding box of all platform monitors
    ViewportCreatedCount : i32,               // Unique sequential creation counter (mostly for testing/debugging)
    PlatformWindowsCreatedCount : i32,        // Unique sequential creation counter (mostly for testing/debugging)
    ViewportFocusedStampCount : i32,          // Every time the front-most window changes, we stamp its viewport with an incrementing counter

    // Keyboard/Gamepad Navigation
    NavCursorVisible : bool,                   // Nav focus cursor/rectangle is visible? We hide it after a mouse click. We show it after a nav move.
    NavHighlightItemUnderNav : bool,           // Disable mouse hovering highlight. Highlight navigation focused item instead of mouse hovered item.
    //bool                  NavDisableHighlight;                // Old name for !g.NavCursorVisible before 1.91.4 (2024/10/18). OPPOSITE VALUE (g.NavDisableHighlight == !g.NavCursorVisible)
    //bool                  NavDisableMouseHover;               // Old name for g.NavHighlightItemUnderNav before 1.91.1 (2024/10/18) this was called When user starts using keyboard/gamepad, we hide mouse hovering highlight until mouse is touched again.
    NavMousePosDirty : bool,                   // When set we will update mouse position if io.ConfigNavMoveSetMousePos is set (not enabled by default)
    NavIdIsAlive : bool,                       // Nav widget has been seen this frame ~~ NavRectRel is valid
    NavId : ImGuiID,                              // Focused item for navigation
    NavWindow : ^ImGuiWindow,                          // Focused window for navigation. Could be called 'FocusedWindow'
    NavFocusScopeId : ImGuiID,                    // Focused focus scope (e.g. selection code often wants to "clear other items" when landing on an item of the same scope)
    NavLayer : ImGuiNavLayer,                           // Focused layer (main scrolling layer, or menu/title bar layer)
    NavActivateId : ImGuiID,                      // ~~ (g.ActiveId == 0) && (IsKeyPressed(ImGuiKey_Space) || IsKeyDown(ImGuiKey_Enter) || IsKeyPressed(ImGuiKey_NavGamepadActivate)) ? NavId : 0, also set when calling ActivateItem()
    NavActivateDownId : ImGuiID,                  // ~~ IsKeyDown(ImGuiKey_Space) || IsKeyDown(ImGuiKey_Enter) || IsKeyDown(ImGuiKey_NavGamepadActivate) ? NavId : 0
    NavActivatePressedId : ImGuiID,               // ~~ IsKeyPressed(ImGuiKey_Space) || IsKeyPressed(ImGuiKey_Enter) || IsKeyPressed(ImGuiKey_NavGamepadActivate) ? NavId : 0 (no repeat)
    NavActivateFlags : ImGuiActivateFlags,
    NavFocusRoute : [dynamic]ImGuiFocusScopeData,                // Reversed copy focus scope stack for NavId (should contains NavFocusScopeId). This essentially follow the window->ParentWindowForFocusRoute chain.
    NavHighlightActivatedId : ImGuiID,
    NavHighlightActivatedTimer : f32,
    NavNextActivateId : ImGuiID,                  // Set by ActivateItem(), queued until next frame.
    NavNextActivateFlags : ImGuiActivateFlags,
    NavInputSource : ImGuiInputSource,                     // Keyboard or Gamepad mode? THIS CAN ONLY BE ImGuiInputSource_Keyboard or .Mouse
    NavLastValidSelectionUserData : ImGuiSelectionUserData,      // Last valid data passed to SetNextItemSelectionUser(), or -1. For current window. Not reset when focusing an item that doesn't have selection data.
    NavCursorHideFrames : i8,

    // Navigation: Init & Move Requests
    NavAnyRequest : bool,                      // ~~ NavMoveRequest || NavInitRequest this is to perform early out in ItemAdd()
    NavInitRequest : bool,                     // Init request for appearing window to select first item
    NavInitRequestFromMove : bool,
    NavInitResult : ImGuiNavItemData,                      // Init request result (first item of the window, or one for which SetItemDefaultFocus() was called)
    NavMoveSubmitted : bool,                   // Move request submitted, will process result on next NewFrame()
    NavMoveScoringItems : bool,                // Move request submitted, still scoring incoming items
    NavMoveForwardToNextFrame : bool,
    NavMoveFlags : ImGuiNavMoveFlags,
    NavMoveScrollFlags : ImGuiScrollFlags,
    NavMoveKeyMods : ImGuiKeyChord,
    NavMoveDir : ImGuiDir,                         // Direction of the move request (left/right/up/down)
    NavMoveDirForDebug : ImGuiDir,
    NavMoveClipDir : ImGuiDir,                     // FIXME-NAV: Describe the purpose of this better. Might want to rename?
    NavScoringRect : ImRect,                     // Rectangle used for scoring, in screen space. Based of window->NavRectRel[], modified for directional navigation scoring.
    NavScoringNoClipRect : ImRect,               // Some nav operations (such as PageUp/PageDown) enforce a region which clipper will attempt to always keep submitted
    NavScoringDebugCount : i32,               // Metrics for debugging
    NavTabbingDir : i32,                      // Generally -1 or +1, 0 when tabbing without a nav id
    NavTabbingCounter : i32,                  // >0 when counting items for tabbing
    NavMoveResultLocal : ImGuiNavItemData,                 // Best move request candidate within NavWindow
    NavMoveResultLocalVisible : ImGuiNavItemData,          // Best move request candidate within NavWindow that are mostly visible (when using ImGuiNavMoveFlags_AlsoScoreVisibleSet flag)
    NavMoveResultOther : ImGuiNavItemData,                 // Best move request candidate within NavWindow's flattened hierarchy (when using ImGuiWindowFlags_NavFlattened flag)
    NavTabbingResultFirst : ImGuiNavItemData,              // First tabbing request candidate within NavWindow and flattened hierarchy

    // Navigation: record of last move request
    NavJustMovedFromFocusScopeId : ImGuiID,       // Just navigated from this focus scope id (result of a successfully MoveRequest).
    NavJustMovedToId : ImGuiID,                   // Just navigated to this id (result of a successfully MoveRequest).
    NavJustMovedToFocusScopeId : ImGuiID,         // Just navigated to this focus scope id (result of a successfully MoveRequest).
    NavJustMovedToKeyMods : ImGuiKeyChord,
    NavJustMovedToIsTabbing : bool,            // Copy of ImGuiNavMoveFlags_IsTabbing. Maybe we should store whole flags.
    NavJustMovedToHasSelectionData : bool,     // Copy of move result's ItemFlags & ImGuiItemFlags_HasSelectionUserData). Maybe we should just store ImGuiNavItemData.

    // Navigation: Windowing (CTRL+TAB for list, or Menu button + keys or directional pads to move/resize)
    ConfigNavWindowingKeyNext : ImGuiKeyChord,          // = ImGuiMod_Ctrl | ImGuiKey_Tab (or ImGuiMod_Super | ImGuiKey_Tab on OS X). For reconfiguration (see #4828)
    ConfigNavWindowingKeyPrev : ImGuiKeyChord,          // = ImGuiMod_Ctrl | ImGuiMod_Shift | ImGuiKey_Tab (or ImGuiMod_Super | ImGuiMod_Shift | ImGuiKey_Tab on OS X)
    NavWindowingTarget : ^ImGuiWindow,                 // Target window when doing CTRL+Tab (or Pad Menu + FocusPrev/Next), this window is temporarily displayed top-most!
    NavWindowingTargetAnim : ^ImGuiWindow,             // Record of last valid NavWindowingTarget until DimBgRatio and NavWindowingHighlightAlpha becomes 0.0f, so the fade-out can stay on it.
    NavWindowingListWindow : ^ImGuiWindow,             // Internal window actually listing the CTRL+Tab contents
    NavWindowingTimer : f32,
    NavWindowingHighlightAlpha : f32,
    NavWindowingToggleLayer : bool,
    NavWindowingToggleKey : ImGuiKey,
    NavWindowingAccumDeltaPos : ImVec2,
    NavWindowingAccumDeltaSize : ImVec2,

    // Render
    DimBgRatio : f32,                         // 0.0..1.0 animation when fading in a dimming background (for modal window and CTRL+TAB list)

    // Drag and Drop
    DragDropActive : bool,
    DragDropWithinSource : bool,               // Set when within a BeginDragDropXXX/EndDragDropXXX block for a drag source.
    DragDropWithinTarget : bool,               // Set when within a BeginDragDropXXX/EndDragDropXXX block for a drag target.
    DragDropSourceFlags : ImGuiDragDropFlags,
    DragDropSourceFrameCount : i32,
    DragDropMouseButton : i32,
    DragDropPayload : ImGuiPayload,
    DragDropTargetRect : ImRect,                 // Store rectangle of current target candidate (we favor small targets when overlapping)
    DragDropTargetClipRect : ImRect,             // Store ClipRect at the time of item's drawing
    DragDropTargetId : ImGuiID,
    DragDropAcceptFlags : ImGuiDragDropFlags,
    DragDropAcceptIdCurrRectSurface : f32,    // Target item surface (we resolve overlapping targets by prioritizing the smaller surface)
    DragDropAcceptIdCurr : ImGuiID,               // Target item id (set at the time of accepting the payload)
    DragDropAcceptIdPrev : ImGuiID,               // Target item id from previous frame (we need to store this to allow for overlapping drag and drop targets)
    DragDropAcceptFrameCount : i32,           // Last time a target expressed a desire to accept the source
    DragDropHoldJustPressedId : ImGuiID,          // Set when holding a payload just made ButtonBehavior() return a press.
    DragDropPayloadBufHeap : [dynamic]u8,             // We don't expose the ImVector<> directly, ImGuiPayload only holds pointer+size
    DragDropPayloadBufLocal : [16]u8,        // Local buffer for small payloads

    // Clipper
    ClipperTempDataStacked : i32,
    ClipperTempData : [dynamic]ImGuiListClipperData,

    // Tables
    CurrentTable : ^ImGuiTable,
    DebugBreakInTable : ImGuiID,          // Set to break in BeginTable() call.
    TablesTempDataStacked : i32,      // Temporary table data size (because we leave previous instances undestructed, we generally don't use TablesTempData.Size)
    TablesTempData : [dynamic]ImGuiTableTempData,             // Temporary table data (buffers reused/shared across instances, support nesting)
    Tables : ImPool<ImGuiTable>,                     // Persistent table data
    TablesLastTimeActive : [dynamic]f32,       // Last used timestamp of each tables (SOA, for efficient GC)
    DrawChannelsTempMergeBuffer : [dynamic]ImDrawChannel,

    // Tab bars
    CurrentTabBar : ^ImGuiTabBar,
    TabBars : ImPool<ImGuiTabBar>,
    CurrentTabBarStack : [dynamic]ImGuiPtrOrIndex,
    ShrinkWidthBuffer : [dynamic]ImGuiShrinkWidthItem,

    // Multi-Select state
    BoxSelectState : ImGuiBoxSelectState,
    CurrentMultiSelect : ^ImGuiMultiSelectTempData,
    MultiSelectTempDataStacked : i32, // Temporary multi-select data size (because we leave previous instances undestructed, we generally don't use MultiSelectTempData.Size)
    MultiSelectTempData : [dynamic]ImGuiMultiSelectTempData,
    MultiSelectStorage : ImPool<ImGuiMultiSelectState>,

    // Hover Delay system
    HoverItemDelayId : ImGuiID,
    HoverItemDelayIdPreviousFrame : ImGuiID,
    HoverItemDelayTimer : f32,                // Currently used by IsItemHovered()
    HoverItemDelayClearTimer : f32,           // Currently used by IsItemHovered(): grace time before g.TooltipHoverTimer gets cleared.
    HoverItemUnlockedStationaryId : ImGuiID,      // Mouse has once been stationary on this item. Only reset after departing the item.
    HoverWindowUnlockedStationaryId : ImGuiID,    // Mouse has once been stationary on this window. Only reset after departing the window.

    // Mouse state
    MouseCursor : ImGuiMouseCursor,
    MouseStationaryTimer : f32,               // Time the mouse has been stationary (with some loose heuristic)
    MouseLastValidPos : ImVec2,

    // Widget state
    InputTextState : ImGuiInputTextState,
    InputTextDeactivatedState : ImGuiInputTextDeactivatedState,
    InputTextPasswordFont : ImFont,
    TempInputId : ImGuiID,                        // Temporary text input when CTRL+clicking on a slider, etc.
    DataTypeZeroValue : ImGuiDataTypeStorage,                  // 0 for all data types
    BeginMenuDepth : i32,
    BeginComboDepth : i32,
    ColorEditOptions : ImGuiColorEditFlags,                   // Store user options for color edit widgets
    ColorEditCurrentID : ImGuiID,                 // Set temporarily while inside of the parent-most ColorEdit4/ColorPicker4 (because they call each others).
    ColorEditSavedID : ImGuiID,                   // ID we are saving/restoring HS for
    ColorEditSavedHue : f32,                  // Backup of last Hue associated to LastColor, so we can restore Hue in lossy RGB<>HSV round trips
    ColorEditSavedSat : f32,                  // Backup of last Saturation associated to LastColor, so we can restore Saturation in lossy RGB<>HSV round trips
    ColorEditSavedColor : u32,                // RGB value with alpha set to 0.
    ColorPickerRef : ImVec4,                     // Initial/reference color at the time of opening the color picker.
    ComboPreviewData : ImGuiComboPreviewData,
    WindowResizeBorderExpectedRect : ImRect,     // Expected border rect, switch to relative edit if moving
    WindowResizeRelativeMode : bool,
    ScrollbarSeekMode : i16,                  // 0: scroll to clicked location, -1/+1: prev/next page.
    ScrollbarClickDeltaToGrabCenter : f32,    // When scrolling to mouse location: distance between mouse and center of grab box, normalized in parent space.
    SliderGrabClickOffset : f32,
    SliderCurrentAccum : f32,                 // Accumulated slider delta when using navigation controls.
    SliderCurrentAccumDirty : bool,            // Has the accumulated slider delta changed since last time we tried to apply it?
    DragCurrentAccumDirty : bool,
    DragCurrentAccum : f32,                   // Accumulator for dragging modification. Always high-precision, not rounded by end-user precision settings
    DragSpeedDefaultRatio : f32,              // If speed == 0.0f, uses (max-min) * DragSpeedDefaultRatio
    DisabledAlphaBackup : f32,                // Backup for style.Alpha for BeginDisabled()
    DisabledStackSize : i16,
    TooltipOverrideCount : i16,
    TooltipPreviousWindow : ^ImGuiWindow,              // Window of last tooltip submitted during the frame
    ClipboardHandlerData : [dynamic]u8,               // If no custom clipboard handler is defined
    MenusIdSubmittedThisFrame : [dynamic]ImGuiID,          // A list of menu IDs that were rendered at least once
    TypingSelectState : ImGuiTypingSelectState,                  // State for GetTypingSelectRequest()

    // Platform support
    PlatformImeData : ImGuiPlatformImeData,                    // Data updated by current frame
    PlatformImeDataPrev : ImGuiPlatformImeData,                // Previous frame data. When changed we call the platform_io.Platform_SetImeDataFn() handler.
    PlatformImeViewport : ImGuiID,

    // Extensions
    // FIXME: We could provide an API to register one slot in an array held in ImGuiContext?
    DockContext : ImGuiDockContext,
    void                    (*DockNodeWindowMenuHandler)(ImGuiContext* ctx, ImGuiDockNode* node, ImGuiTabBar* tab_bar);

    // Settings
    SettingsLoaded : bool,
    SettingsDirtyTimer : f32,                 // Save .ini Settings to memory when time reaches zero
    SettingsIniData : ImGuiTextBuffer,                    // In memory .ini settings
    SettingsHandlers : [dynamic]ImGuiSettingsHandler,       // List of .ini settings handlers
    SettingsWindows : ImChunkStream<ImGuiWindowSettings>,        // ImGuiWindow .ini settings entries
    SettingsTables : ImChunkStream<ImGuiTableSettings>,         // ImGuiTable .ini settings entries
    Hooks : [dynamic]ImGuiContextHook,                  // Hooks for extensions (e.g. test engine)
    HookIdNext : ImGuiID,             // Next available HookId

    // Localization
    LocalizationTable : [ImGuiLocKey_COUNT]^u8,

    // Capture/Logging
    LogEnabled : bool,                         // Currently capturing
    LogFlags : ImGuiLogFlags,                           // Capture flags/type
    LogWindow : ^ImGuiWindow,
    LogFile : ImFileHandle,                            // If != NULL log to stdout/ file
    LogBuffer : ImGuiTextBuffer,                          // Accumulation buffer when log to clipboard. This is pointer so our GImGui static constructor doesn't call heap allocators.
    LogNextPrefix : ^u8,
    LogNextSuffix : ^u8,
    LogLinePosY : f32,
    LogLineFirstItem : bool,
    LogDepthRef : i32,
    LogDepthToExpand : i32,
    LogDepthToExpandDefault : i32,            // Default/stored value for LogDepthMaxExpand if not specified in the LogXXX function call.

    // Error Handling
    ErrorCallback : ImGuiErrorCallback,                      // = NULL. May be exposed in public API eventually.
    ErrorCallbackUserData : rawptr,              // = NULL
    ErrorTooltipLockedPos : ImVec2,
    ErrorFirst : bool,
    ErrorCountCurrentFrame : i32,             // [Internal] Number of errors submitted this frame.
    StackSizesInNewFrame : ImGuiErrorRecoveryState,               // [Internal]
    ImGuiErrorRecoveryState*StackSizesInBeginForCurrentWindow;  // [Internal]

    // Debug Tools
    // (some of the highly frequently used data are interleaved in other structures above: DebugBreakXXX fields, DebugHookIdInfo, DebugLocateId etc.)
    DebugDrawIdConflictsCount : i32,          // Locked count (preserved when holding CTRL)
    DebugLogFlags : ImGuiDebugLogFlags,
    DebugLogBuf : ImGuiTextBuffer,
    DebugLogIndex : ImGuiTextIndex,
    DebugLogSkippedErrors : i32,
    DebugLogAutoDisableFlags : ImGuiDebugLogFlags,
    DebugLogAutoDisableFrames : u8,
    DebugLocateFrames : u8,                  // For DebugLocateItemOnHover(). This is used together with DebugLocateId which is in a hot/cached spot above.
    DebugBreakInLocateId : bool,               // Debug break in ItemAdd() call for g.DebugLocateId.
    DebugBreakKeyChord : ImGuiKeyChord,                 // = ImGuiKey_Pause
    DebugBeginReturnValueCullDepth : i8,     // Cycle between 0..9 then wrap around.
    DebugItemPickerActive : bool,              // Item picker is active (started with DebugStartItemPicker())
    DebugItemPickerMouseButton : u8,
    DebugItemPickerBreakId : ImGuiID,             // Will call IM_DEBUG_BREAK() when encountering this ID
    DebugFlashStyleColorTime : f32,
    DebugFlashStyleColorBackup : ImVec4,
    DebugMetricsConfig : ImGuiMetricsConfig,
    DebugIDStackTool : ImGuiIDStackTool,
    DebugAllocInfo : ImGuiDebugAllocInfo,
    DebugHoveredDockNode : ^ImGuiDockNode,               // Hovered dock node.

    // Misc
    FramerateSecPerFrame : [60]f32,           // Calculate estimate of framerate for user over the last 60 frames..
    FramerateSecPerFrameIdx : i32,
    FramerateSecPerFrameCount : i32,
    FramerateSecPerFrameAccum : f32,
    WantCaptureMouseNextFrame : i32,          // Explicit capture override via SetNextFrameWantCaptureMouse()/SetNextFrameWantCaptureKeyboard(). Default to -1.
    WantCaptureKeyboardNextFrame : i32,       // "
    WantTextInputNextFrame : i32,
    TempBuffer : [dynamic]u8,                         // Temporary text buffer
    TempKeychordName : [64]u8,

    ImGuiContext(ImFontAtlas* shared_font_atlas);
};

//-----------------------------------------------------------------------------
// [SECTION] ImGuiWindowTempData, ImGuiWindow
//-----------------------------------------------------------------------------

// Transient per-window data, reset at the beginning of the frame. This used to be called ImGuiDrawContext, hence the DC variable name in ImGuiWindow.
// (That's theory, in practice the delimitation between ImGuiWindow and ImGuiWindowTempData is quite tenuous and could be reconsidered..)
// (This doesn't need a constructor because we zero-clear it as part of ImGuiWindow and all frame-temporary data are setup on Begin)
ImGuiWindowTempData :: struct
{
    // Layout
    CursorPos : ImVec2,              // Current emitting position, in absolute coordinates.
    CursorPosPrevLine : ImVec2,
    CursorStartPos : ImVec2,         // Initial position after Begin(), generally ~ window position + WindowPadding.
    CursorMaxPos : ImVec2,           // Used to implicitly calculate ContentSize at the beginning of next frame, for scrolling range and auto-resize. Always growing during the frame.
    IdealMaxPos : ImVec2,            // Used to implicitly calculate ContentSizeIdeal at the beginning of next frame, for auto-resize only. Always growing during the frame.
    CurrLineSize : ImVec2,
    PrevLineSize : ImVec2,
    CurrLineTextBaseOffset : f32, // Baseline offset (0.0f by default on a new line, generally == style.FramePadding.y when a framed item has been added).
    PrevLineTextBaseOffset : f32,
    IsSameLine : bool,
    IsSetPos : bool,
    Indent : ImVec1,                 // Indentation / start position from left of window (increased by TreePush/TreePop, etc.)
    ColumnsOffset : ImVec1,          // Offset to the current column (if ColumnsCurrent > 0). FIXME: This and the above should be a stack to allow use cases like Tree->Column->Tree. Need revamp columns API.
    GroupOffset : ImVec1,
    CursorStartPosLossyness : ImVec2,// Record the loss of precision of CursorStartPos due to really large scrolling amount. This is used by clipper to compensate and fix the most common use case of large scroll area.

    // Keyboard/Gamepad navigation
    NavLayerCurrent : ImGuiNavLayer,        // Current layer, 0..31 (we currently only use 0..1)
    NavLayersActiveMask : i16,    // Which layers have been written to (result from previous frame)
    NavLayersActiveMaskNext : i16,// Which layers have been written to (accumulator for current frame)
    NavIsScrollPushableX : bool,   // Set when current work location may be scrolled horizontally when moving left / right. This is generally always true UNLESS within a column.
    NavHideHighlightOneFrame : bool,
    NavWindowHasScrollY : bool,    // Set per window when scrolling can be used (== ScrollMax.y > 0.0f)

    // Miscellaneous
    MenuBarAppending : bool,       // FIXME: Remove this
    MenuBarOffset : ImVec2,          // MenuBarOffset.x is sort of equivalent of a per-layer CursorPos.x, saved/restored as we switch to the menu bar. The only situation when MenuBarOffset.y is > 0 if when (SafeAreaPadding.y > FramePadding.y), often used on TVs.
    MenuColumns : ImGuiMenuColumns,            // Simplified columns storage for menu items measurement
    TreeDepth : i32,              // Current tree depth.
    TreeHasStackDataDepthMask : u32, // Store whether given depth has ImGuiTreeNodeStackData data. Could be turned into a ImU64 if necessary.
    ChildWindows : [dynamic]^ImGuiWindow,
    StateStorage : ^ImGuiStorage,           // Current persistent per-window storage (store e.g. tree node open/close state)
    CurrentColumns : ^ImGuiOldColumns,         // Current columns set
    CurrentTableIdx : i32,        // Current table index (into g.Tables)
    LayoutType : ImGuiLayoutType,
    ParentLayoutType : ImGuiLayoutType,       // Layout type of parent window at the time of Begin()
    ModalDimBgColor : u32,

    // Local parameters stacks
    // We store the current settings outside of the vectors to increase memory locality (reduce cache misses). The vectors are rarely modified. Also it allows us to not heap allocate for short-lived windows which are not using those settings.
    ItemWidth : f32,              // Current item width (>0.0: width in pixels, <0.0: align xx pixels to the right of window).
    TextWrapPos : f32,            // Current text wrap pos.
    ItemWidthStack : [dynamic]f32,         // Store item widths to restore (attention: .back() is not == ItemWidth)
    TextWrapPosStack : [dynamic]f32,       // Store text wrap pos to restore (attention: .back() is not == TextWrapPos)
};

// Storage for one window
ImGuiWindow :: struct
{
    Ctx : ^ImGuiContext,                                // Parent UI context (needs to be set explicitly by parent).
    Name : ^u8,                               // Window name, owned by the window.
    ID : ImGuiID,                                 // == ImHashStr(Name)
    Flags, FlagsPreviousFrame : ImGuiWindowFlags,          // See enum ImGuiWindowFlags_
    ChildFlags : ImGuiChildFlags,                         // Set when window is a child window. See enum ImGuiChildFlags_
    WindowClass : ImGuiWindowClass,                        // Advanced users only. Set with SetNextWindowClass()
    Viewport : ^ImGuiViewportP,                           // Always set in Begin(). Inactive windows may have a NULL value here if their viewport was discarded.
    ViewportId : ImGuiID,                         // We backup the viewport id (since the viewport may disappear or never be created if the window is inactive)
    ViewportPos : ImVec2,                        // We backup the viewport position (since the viewport may disappear or never be created if the window is inactive)
    ViewportAllowPlatformMonitorExtend : i32, // Reset to -1 every frame (index is guaranteed to be valid between NewFrame..EndFrame), only used in the Appearing frame of a tooltip/popup to enforce clamping to a given monitor
    Pos : ImVec2,                                // Position (always rounded-up to nearest pixel)
    Size : ImVec2,                               // Current size (==SizeFull or collapsed title bar size)
    SizeFull : ImVec2,                           // Size when non collapsed
    ContentSize : ImVec2,                        // Size of contents/scrollable client area (calculated from the extents reach of the cursor) from previous frame. Does not include window decoration or window padding.
    ContentSizeIdeal : ImVec2,
    ContentSizeExplicit : ImVec2,                // Size of contents/scrollable client area explicitly request by the user via SetNextWindowContentSize().
    WindowPadding : ImVec2,                      // Window padding at the time of Begin().
    WindowRounding : f32,                     // Window rounding at the time of Begin(). May be clamped lower to avoid rendering artifacts with title bar, menu bar etc.
    WindowBorderSize : f32,                   // Window border size at the time of Begin().
    TitleBarHeight, MenuBarHeight : f32,      // Note that those used to be function before 2024/05/28. If you have old code calling TitleBarHeight() you can change it to TitleBarHeight.
    DecoOuterSizeX1, DecoOuterSizeY1 : f32,   // Left/Up offsets. Sum of non-scrolling outer decorations (X1 generally == 0.0f. Y1 generally = TitleBarHeight + MenuBarHeight). Locked during Begin().
    DecoOuterSizeX2, DecoOuterSizeY2 : f32,   // Right/Down offsets (X2 generally == ScrollbarSize.x, Y2 == ScrollbarSizes.y).
    DecoInnerSizeX1, DecoInnerSizeY1 : f32,   // Applied AFTER/OVER InnerRect. Specialized for Tables as they use specialized form of clipping and frozen rows/columns are inside InnerRect (and not part of regular decoration sizes).
    NameBufLen : i32,                         // Size of buffer storing Name. May be larger than strlen(Name)!
    MoveId : ImGuiID,                             // == window->GetID("#MOVE")
    TabId : ImGuiID,                              // == window->GetID("#TAB")
    ChildId : ImGuiID,                            // ID of corresponding item in parent window (for navigation to return from child window to parent window)
    PopupId : ImGuiID,                            // ID in the popup stack when this window is used as a popup/menu (because we use generic Name/ID for recycling)
    Scroll : ImVec2,
    ScrollMax : ImVec2,
    ScrollTarget : ImVec2,                       // target scroll position. stored as cursor position with scrolling canceled out, so the highest point is always 0.0f. (FLT_MAX for no change)
    ScrollTargetCenterRatio : ImVec2,            // 0.0f = scroll so that target position is at top, 0.5f = scroll so that target position is centered
    ScrollTargetEdgeSnapDist : ImVec2,           // 0.0f = no snapping, >0.0f snapping threshold
    ScrollbarSizes : ImVec2,                     // Size taken by each scrollbars on their smaller axis. Pay attention! ScrollbarSizes.x == width of the vertical scrollbar, ScrollbarSizes.y = height of the horizontal scrollbar.
    ScrollbarX, ScrollbarY : bool,             // Are scrollbars visible?
    ViewportOwned : bool,
    Active : bool,                             // Set to true on Begin(), unless Collapsed
    WasActive : bool,
    WriteAccessed : bool,                      // Set to true when any widget access the current window
    Collapsed : bool,                          // Set when collapsing window to become only title-bar
    WantCollapseToggle : bool,
    SkipItems : bool,                          // Set when items can safely be all clipped (e.g. window not visible or collapsed)
    SkipRefresh : bool,                        // [EXPERIMENTAL] Reuse previous frame drawn contents, Begin() returns false.
    Appearing : bool,                          // Set during the frame where the window is appearing (or re-appearing)
    Hidden : bool,                             // Do not display (== HiddenFrames*** > 0)
    IsFallbackWindow : bool,                   // Set on the "Debug##Default" window.
    IsExplicitChild : bool,                    // Set when passed _ChildWindow, left to false by BeginDocked()
    HasCloseButton : bool,                     // Set when the window has a close button (p_open != NULL)
    ResizeBorderHovered : i8,                // Current border being hovered for resize (-1: none, otherwise 0-3)
    ResizeBorderHeld : i8,                   // Current border being held for resize (-1: none, otherwise 0-3)
    BeginCount : i16,                         // Number of Begin() during the current frame (generally 0 or 1, 1+ if appending via multiple Begin/End pairs)
    BeginCountPreviousFrame : i16,            // Number of Begin() during the previous frame
    BeginOrderWithinParent : i16,             // Begin() order within immediate parent window, if we are a child window. Otherwise 0.
    BeginOrderWithinContext : i16,            // Begin() order within entire imgui context. This is mostly used for debugging submission order related issues.
    FocusOrder : i16,                         // Order within WindowsFocusOrder[], altered when windows are focused.
    AutoFitFramesX, AutoFitFramesY : i8,
    AutoFitOnlyGrows : bool,
    AutoPosLastDirection : ImGuiDir,
    HiddenFramesCanSkipItems : i8,           // Hide the window for N frames
    HiddenFramesCannotSkipItems : i8,        // Hide the window for N frames while allowing items to be submitted so we can measure their size
    HiddenFramesForRenderOnly : i8,          // Hide the window until frame N at Render() time only
    DisableInputsFrames : i8,                // Disable window interactions for N frames
    ImGuiCond               SetWindowPosAllowFlags : 8;         // store acceptable condition flags for SetNextWindowPos() use.
    ImGuiCond               SetWindowSizeAllowFlags : 8;        // store acceptable condition flags for SetNextWindowSize() use.
    ImGuiCond               SetWindowCollapsedAllowFlags : 8;   // store acceptable condition flags for SetNextWindowCollapsed() use.
    ImGuiCond               SetWindowDockAllowFlags : 8;        // store acceptable condition flags for SetNextWindowDock() use.
    SetWindowPosVal : ImVec2,                    // store window position when using a non-zero Pivot (position set needs to be processed when we know the window size)
    SetWindowPosPivot : ImVec2,                  // store window pivot for positioning. ImVec2(0, 0) when positioning from top-left corner; ImVec2(0.5f, 0.5f) for centering; ImVec2(1, 1) for bottom right.

    IDStack : [dynamic]ImGuiID,                            // ID stack. ID are hashes seeded with the value at the top of the stack. (In theory this should be in the TempData structure)
    DC : ImGuiWindowTempData,                                 // Temporary per-window data, reset at the beginning of the frame. This used to be called ImGuiDrawContext, hence the "DC" variable name.

    // The best way to understand what those rectangles are is to use the 'Metrics->Tools->Show Windows Rectangles' viewer.
    // The main 'OuterRect', omitted as a field, is window->Rect().
    OuterRectClipped : ImRect,                   // == Window->Rect() just after setup in Begin(). == window->Rect() for root window.
    InnerRect : ImRect,                          // Inner rectangle (omit title bar, menu bar, scroll bar)
    InnerClipRect : ImRect,                      // == InnerRect shrunk by WindowPadding*0.5f on each side, clipped within viewport or parent clip rect.
    WorkRect : ImRect,                           // Initially covers the whole scrolling region. Reduced by containers e.g columns/tables when active. Shrunk by WindowPadding*1.0f on each side. This is meant to replace ContentRegionRect over time (from 1.71+ onward).
    ParentWorkRect : ImRect,                     // Backup of WorkRect before entering a container such as columns/tables. Used by e.g. SpanAllColumns functions to easily access. Stacked containers are responsible for maintaining this. // FIXME-WORKRECT: Could be a stack?
    ClipRect : ImRect,                           // Current clipping/scissoring rectangle, evolve as we are using PushClipRect(), etc. == DrawList->clip_rect_stack.back().
    ContentRegionRect : ImRect,                  // FIXME: This is currently confusing/misleading. It is essentially WorkRect but not handling of scrolling. We currently rely on it as right/bottom aligned sizing operation need some size to rely on.
    HitTestHoleSize : ImVec2ih,                    // Define an optional rectangular hole where mouse will pass-through the window.
    HitTestHoleOffset : ImVec2ih,

    LastFrameActive : i32,                    // Last frame number the window was Active.
    LastFrameJustFocused : i32,               // Last frame number the window was made Focused.
    LastTimeActive : f32,                     // Last timestamp the window was Active (using float as we don't need high precision there)
    ItemWidthDefault : f32,
    StateStorage : ImGuiStorage,
    ColumnsStorage : [dynamic]ImGuiOldColumns,
    FontWindowScale : f32,                    // User scale multiplier per-window, via SetWindowFontScale()
    FontDpiScale : f32,
    SettingsOffset : i32,                     // Offset into SettingsWindows[] (offsets are always valid as we only grow the array from the back)

    DrawList : ^ImDrawList,                           // == &DrawListInst (for backward compatibility reason with code using imgui_internal.h we keep this a pointer)
    DrawListInst : ImDrawList,
    ParentWindow : ^ImGuiWindow,                       // If we are a child _or_ popup _or_ docked window, this is pointing to our parent. Otherwise NULL.
    ParentWindowInBeginStack : ^ImGuiWindow,
    RootWindow : ^ImGuiWindow,                         // Point to ourself or first ancestor that is not a child window. Doesn't cross through popups/dock nodes.
    RootWindowPopupTree : ^ImGuiWindow,                // Point to ourself or first ancestor that is not a child window. Cross through popups parent<>child.
    RootWindowDockTree : ^ImGuiWindow,                 // Point to ourself or first ancestor that is not a child window. Cross through dock nodes.
    RootWindowForTitleBarHighlight : ^ImGuiWindow,     // Point to ourself or first ancestor which will display TitleBgActive color when this window is active.
    RootWindowForNav : ^ImGuiWindow,                   // Point to ourself or first ancestor which doesn't have the NavFlattened flag.
    ParentWindowForFocusRoute : ^ImGuiWindow,          // Set to manual link a window to its logical parent so that Shortcut() chain are honoerd (e.g. Tool linked to Document)

    NavLastChildNavWindow : ^ImGuiWindow,              // When going to the menu bar, we remember the child window we came from. (This could probably be made implicit if we kept g.Windows sorted by last focused including child window.)
    NavLastIds : [ImGuiNavLayer_COUNT]ImGuiID,    // Last known NavId for this window, per layer (0/1)
    NavRectRel : [ImGuiNavLayer_COUNT]ImRect,    // Reference rectangle, in window relative space
    NavPreferredScoringPosRel : [ImGuiNavLayer_COUNT]ImVec2, // Preferred X/Y position updated when moving on a given axis, reset to FLT_MAX.
    NavRootFocusScopeId : ImGuiID,                // Focus Scope ID at the time of Begin()

    MemoryDrawListIdxCapacity : i32,          // Backup of last idx/vtx count, so when waking up the window we can preallocate and avoid iterative alloc/copy
    MemoryDrawListVtxCapacity : i32,
    MemoryCompacted : bool,                    // Set when window extraneous data have been garbage collected

    // Docking
    bool                    DockIsActive        :1;             // When docking artifacts are actually visible. When this is set, DockNode is guaranteed to be != NULL. ~~ (DockNode != NULL) && (DockNode->Windows.Size > 1).
    bool                    DockNodeIsVisible   :1;
    bool                    DockTabIsVisible    :1;             // Is our window visible this frame? ~~ is the corresponding tab selected?
    bool                    DockTabWantClose    :1;
    DockOrder : i16,                          // Order of the last time the window was visible within its DockNode. This is used to reorder windows that are reappearing on the same frame. Same value between windows that were active and windows that were none are possible.
    DockStyle : ImGuiWindowDockStyle,
    DockNode : ^ImGuiDockNode,                           // Which node are we docked into. Important: Prefer testing DockIsActive in many cases as this will still be set when the dock node is hidden.
    DockNodeAsHost : ^ImGuiDockNode,                     // Which node are we owning (for parent windows)
    DockId : ImGuiID,                             // Backup of last valid DockNode->ID, so single window remember their dock node id even when they are not bound any more
    DockTabItemStatusFlags : ImGuiItemStatusFlags,
    DockTabItemRect : ImRect,

public:
    ImGuiWindow(ImGuiContext* context, const u8* name);
    ~ImGuiWindow();

    ImGuiID     GetID(const u8* str, const u8* str_end = nil);
    ImGuiID     GetID(const rawptr ptr);
    ImGuiID     GetID(i32 n);
    ImGuiID     GetIDFromPos(const ImVec2& p_abs);
    ImGuiID     GetIDFromRectangle(const ImRect& r_abs);

    // We don't use g.FontSize because the window may be != g.CurrentWindow.
    ImRect      Rect() const            { return ImRect(Pos.x, Pos.y, Pos.x + Size.x, Pos.y + Size.y); }
    f32       CalcFontSize() const    { ImGuiContext& g = *Ctx; f32 scale = g.FontBaseSize * FontWindowScale * FontDpiScale; if (ParentWindow) scale *= ParentWindow.FontWindowScale; return scale; }
    ImRect      TitleBarRect() const    { return ImRect(Pos, ImVec2{Pos.x + SizeFull.x, Pos.y + TitleBarHeight}); }
    ImRect      MenuBarRect() const     { f32 y1 = Pos.y + TitleBarHeight; return ImRect(Pos.x, y1, Pos.x + SizeFull.x, y1 + MenuBarHeight); }
};

//-----------------------------------------------------------------------------
// [SECTION] Tab bar, Tab item support
//-----------------------------------------------------------------------------

// Extend ImGuiTabBarFlags_
ImGuiTabBarFlagsPrivate_ :: enum i32
{
    ImGuiTabBarFlags_DockNode                   = 1 << 20,  // Part of a dock node [we don't use this in the master branch but it facilitate branch syncing to keep this around]
    ImGuiTabBarFlags_IsFocused                  = 1 << 21,
    ImGuiTabBarFlags_SaveSettings               = 1 << 22,  // FIXME: Settings are handled by the docking system, this only request the tab bar to mark settings dirty when reordering tabs
};

// Extend ImGuiTabItemFlags_
ImGuiTabItemFlagsPrivate_ :: enum i32
{
    ImGuiTabItemFlags_SectionMask_              = ImGuiTabItemFlags_Leading | ImGuiTabItemFlags_Trailing,
    ImGuiTabItemFlags_NoCloseButton             = 1 << 20,  // Track whether p_open was set or not (we'll need this info on the next frame to recompute ContentWidth during layout)
    ImGuiTabItemFlags_Button                    = 1 << 21,  // Used by TabItemButton, change the tab item behavior to mimic a button
    ImGuiTabItemFlags_Unsorted                  = 1 << 22,  // [Docking] Trailing tabs with the _Unsorted flag will be sorted based on the DockOrder of their Window.
};

// Storage for one active tab item (sizeof() 48 bytes)
ImGuiTabItem :: struct
{
    ID : ImGuiID,
    Flags : ImGuiTabItemFlags,
    Window : ^ImGuiWindow,                 // When TabItem is part of a DockNode's TabBar, we hold on to a window.
    LastFrameVisible : i32,
    LastFrameSelected : i32,      // This allows us to infer an ordered list of the last activated tabs with little maintenance
    Offset : f32,                 // Position relative to beginning of tab
    Width : f32,                  // Width currently displayed
    ContentWidth : f32,           // Width of label, stored during BeginTabItem() call
    RequestedWidth : f32,         // Width optionally requested by caller, -1.0f is unused
    NameOffset : i32,             // When Window==NULL, offset to name within parent ImGuiTabBar::TabsNames
    BeginOrder : u16,             // BeginTabItem() order, used to re-order tabs after toggling ImGuiTabBarFlags_Reorderable
    IndexDuringLayout : u16,      // Index only used during TabBarLayout(). Tabs gets reordered so 'Tabs[n].IndexDuringLayout == n' but may mismatch during additions.
    WantClose : bool,              // Marked as closed by SetTabItemClosed()

    ImGuiTabItem()      { memset(this, 0, size_of(*this)); LastFrameVisible = LastFrameSelected = -1; RequestedWidth = -1.0; NameOffset = -1; BeginOrder = IndexDuringLayout = -1; }
};

// Storage for a tab bar (sizeof() 160 bytes)
ImGuiTabBar :: struct
{
    Window : ^ImGuiWindow,
    Tabs : [dynamic]ImGuiTabItem,
    Flags : ImGuiTabBarFlags,
    ID : ImGuiID,                     // Zero for tab-bars used by docking
    SelectedTabId : ImGuiID,          // Selected tab/window
    NextSelectedTabId : ImGuiID,      // Next selected tab/window. Will also trigger a scrolling animation
    VisibleTabId : ImGuiID,           // Can occasionally be != SelectedTabId (e.g. when previewing contents for CTRL+TAB preview)
    CurrFrameVisible : i32,
    PrevFrameVisible : i32,
    BarRect : ImRect,
    CurrTabsContentsHeight : f32,
    PrevTabsContentsHeight : f32, // Record the height of contents submitted below the tab bar
    WidthAllTabs : f32,           // Actual width of all tabs (locked during layout)
    WidthAllTabsIdeal : f32,      // Ideal width if all tabs were visible and not clipped
    ScrollingAnim : f32,
    ScrollingTarget : f32,
    ScrollingTargetDistToVisibility : f32,
    ScrollingSpeed : f32,
    ScrollingRectMinX : f32,
    ScrollingRectMaxX : f32,
    SeparatorMinX : f32,
    SeparatorMaxX : f32,
    ReorderRequestTabId : ImGuiID,
    ReorderRequestOffset : u16,
    BeginCount : i8,
    WantLayout : bool,
    VisibleTabWasSubmitted : bool,
    TabsAddedNew : bool,           // Set to true when a new tab item or button has been added to the tab bar during last frame
    TabsActiveCount : u16,        // Number of tabs submitted this frame.
    LastTabItemIdx : u16,         // Index of last BeginTabItem() tab for use by EndTabItem()
    ItemSpacingY : f32,
    FramePadding : ImVec2,           // style.FramePadding locked at the time of BeginTabBar()
    BackupCursorPos : ImVec2,
    TabsNames : ImGuiTextBuffer,              // For non-docking tab bar we re-append names in a contiguous buffer.

    ImGuiTabBar();
};

//-----------------------------------------------------------------------------
// [SECTION] Table support
//-----------------------------------------------------------------------------

#define IM_COL32_DISABLE                IM_COL32(0,0,0,1)   // Special sentinel code which cannot be used as a regular color.
IMGUI_TABLE_MAX_COLUMNS :: 512                 // May be further lifted

// Our current column maximum is 64 but we may raise that in the future.
ImGuiTableColumnIdx :: u16
ImGuiTableDrawChannelIdx :: u16

// [Internal] sizeof() ~ 112
// We use the terminology "Enabled" to refer to a column that is not Hidden by user/api.
// We use the terminology "Clipped" to refer to a column that is out of sight because of scrolling/clipping.
// This is in contrast with some user-facing api such as IsItemVisible() / IsRectVisible() which use "Visible" to mean "not clipped".
ImGuiTableColumn :: struct
{
    Flags : ImGuiTableColumnFlags,                          // Flags after some patching (not directly same as provided by user). See ImGuiTableColumnFlags_
    WidthGiven : f32,                     // Final/actual width visible == (MaxX - MinX), locked in TableUpdateLayout(). May be > WidthRequest to honor minimum width, may be < WidthRequest to honor shrinking columns down in tight space.
    MinX : f32,                           // Absolute positions
    MaxX : f32,
    WidthRequest : f32,                   // Master width absolute value when !(Flags & _WidthStretch). When Stretch this is derived every frame from StretchWeight in TableUpdateLayout()
    WidthAuto : f32,                      // Automatic width
    WidthMax : f32,                       // Maximum width (FIXME: overwritten by each instance)
    StretchWeight : f32,                  // Master width weight when (Flags & _WidthStretch). Often around ~1.0f initially.
    InitStretchWeightOrWidth : f32,       // Value passed to TableSetupColumn(). For Width it is a content width (_without padding_).
    ClipRect : ImRect,                       // Clipping rectangle for the column
    UserID : ImGuiID,                         // Optional, value passed to TableSetupColumn()
    WorkMinX : f32,                       // Contents region min ~(MinX + CellPaddingX + CellSpacingX1) == cursor start position when entering column
    WorkMaxX : f32,                       // Contents region max ~(MaxX - CellPaddingX - CellSpacingX2)
    ItemWidth : f32,                      // Current item width for the column, preserved across rows
    ContentMaxXFrozen : f32,              // Contents maximum position for frozen rows (apart from headers), from which we can infer content width.
    ContentMaxXUnfrozen : f32,
    ContentMaxXHeadersUsed : f32,         // Contents maximum position for headers rows (regardless of freezing). TableHeader() automatically softclip itself + report ideal desired size, to avoid creating extraneous draw calls
    ContentMaxXHeadersIdeal : f32,
    NameOffset : u16,                     // Offset into parent ColumnsNames[]
    DisplayOrder : ImGuiTableColumnIdx,                   // Index within Table's IndexToDisplayOrder[] (column may be reordered by users)
    IndexWithinEnabledSet : ImGuiTableColumnIdx,          // Index within enabled/visible set (<= IndexToDisplayOrder)
    PrevEnabledColumn : ImGuiTableColumnIdx,              // Index of prev enabled/visible column within Columns[], -1 if first enabled/visible column
    NextEnabledColumn : ImGuiTableColumnIdx,              // Index of next enabled/visible column within Columns[], -1 if last enabled/visible column
    SortOrder : ImGuiTableColumnIdx,                      // Index of this column within sort specs, -1 if not sorting on this column, 0 for single-sort, may be >0 on multi-sort
    DrawChannelCurrent : ImGuiTableDrawChannelIdx,            // Index within DrawSplitter.Channels[]
    DrawChannelFrozen : ImGuiTableDrawChannelIdx,             // Draw channels for frozen rows (often headers)
    DrawChannelUnfrozen : ImGuiTableDrawChannelIdx,           // Draw channels for unfrozen rows
    IsEnabled : bool,                      // IsUserEnabled && (Flags & ImGuiTableColumnFlags_Disabled) == 0
    IsUserEnabled : bool,                  // Is the column not marked Hidden by the user? (unrelated to being off view, e.g. clipped by scrolling).
    IsUserEnabledNextFrame : bool,
    IsVisibleX : bool,                     // Is actually in view (e.g. overlapping the host window clipping rectangle, not scrolled).
    IsVisibleY : bool,
    IsRequestOutput : bool,                // Return value for TableSetColumnIndex() / TableNextColumn(): whether we request user to output contents or not.
    IsSkipItems : bool,                    // Do we want item submissions to this column to be completely ignored (no layout will happen).
    IsPreserveWidthAuto : bool,
    NavLayerCurrent : i8,                // ImGuiNavLayer in 1 byte
    AutoFitQueue : u8,                   // Queue of 8 values for the next 8 frames to request auto-fit
    CannotSkipItemsQueue : u8,           // Queue of 8 values for the next 8 frames to disable Clipped/SkipItem
    u8                    SortDirection : 2;              // ImGuiSortDirection_Ascending or ImGuiSortDirection_Descending
    u8                    SortDirectionsAvailCount : 2;   // Number of available sort directions (0 to 3)
    u8                    SortDirectionsAvailMask : 4;    // Mask of available sort directions (1-bit each)
    SortDirectionsAvailList : u8,        // Ordered list of available sort directions (2-bits each, total 8-bits)

    ImGuiTableColumn()
    {
        memset(this, 0, size_of(*this));
        StretchWeight = WidthRequest = -1.0;
        NameOffset = -1;
        DisplayOrder = IndexWithinEnabledSet = -1;
        PrevEnabledColumn = NextEnabledColumn = -1;
        SortOrder = -1;
        SortDirection = ImGuiSortDirection_None;
        DrawChannelCurrent = DrawChannelFrozen = DrawChannelUnfrozen = (u8)-1;
    }
};

// Transient cell data stored per row.
// sizeof() ~ 6 bytes
ImGuiTableCellData :: struct
{
    BgColor : u32,    // Actual color
    Column : ImGuiTableColumnIdx,     // Column number
};

// Parameters for TableAngledHeadersRowEx()
// This may end up being refactored for more general purpose.
// sizeof() ~ 12 bytes
ImGuiTableHeaderData :: struct
{
    Index : ImGuiTableColumnIdx,      // Column index
    TextColor : u32,
    BgColor0 : u32,
    BgColor1 : u32,
};

// Per-instance data that needs preserving across frames (seemingly most others do not need to be preserved aside from debug needs. Does that means they could be moved to ImGuiTableTempData?)
// sizeof() ~ 24 bytes
ImGuiTableInstanceData :: struct
{
    TableInstanceID : ImGuiID,
    LastOuterHeight : f32,            // Outer height from last frame
    LastTopHeadersRowHeight : f32,    // Height of first consecutive header rows from last frame (FIXME: this is used assuming consecutive headers are in same frozen set)
    LastFrozenHeight : f32,           // Height of frozen section from last frame
    HoveredRowLast : i32,             // Index of row which was hovered last frame.
    HoveredRowNext : i32,             // Index of row hovered this frame, set after encountering it.

    ImGuiTableInstanceData()    { TableInstanceID = 0; LastOuterHeight = LastTopHeadersRowHeight = LastFrozenHeight = 0.0; HoveredRowLast = HoveredRowNext = -1; }
};

// sizeof() ~ 592 bytes + heap allocs described in TableBeginInitMemory()
ImGuiTable :: struct
{
    ID : ImGuiID,
    Flags : ImGuiTableFlags,
    RawData : rawptr,                    // Single allocation to hold Columns[], DisplayOrderToIndex[] and RowCellData[]
    TempData : ^ImGuiTableTempData,                   // Transient data while table is active. Point within g.CurrentTableStack[]
    Columns : ImSpan<ImGuiTableColumn>,                    // Point within RawData[]
    DisplayOrderToIndex : ImSpan<ImGuiTableColumnIdx>,        // Point within RawData[]. Store display order of columns (when not reordered, the values are 0...Count-1)
    RowCellData : ImSpan<ImGuiTableCellData>,                // Point within RawData[]. Store cells background requests for current row.
    EnabledMaskByDisplayOrder : ImBitArrayPtr,  // Column DisplayOrder -> IsEnabled map
    EnabledMaskByIndex : ImBitArrayPtr,         // Column Index -> IsEnabled map (== not hidden by user/api) in a format adequate for iterating column without touching cold data
    VisibleMaskByIndex : ImBitArrayPtr,         // Column Index -> IsVisibleX|IsVisibleY map (== not hidden by user/api && not hidden by scrolling/cliprect)
    SettingsLoadedFlags : ImGuiTableFlags,        // Which data were loaded from the .ini file (e.g. when order is not altered we won't save order)
    SettingsOffset : i32,             // Offset in g.SettingsTables
    LastFrameActive : i32,
    ColumnsCount : i32,               // Number of columns declared in BeginTable()
    CurrentRow : i32,
    CurrentColumn : i32,
    InstanceCurrent : u16,            // Count of BeginTable() calls with same ID in the same frame (generally 0). This is a little bit similar to BeginCount for a window, but multiple table with same ID look are multiple tables, they are just synched.
    InstanceInteracted : u16,         // Mark which instance (generally 0) of the same ID is being interacted with
    RowPosY1 : f32,
    RowPosY2 : f32,
    RowMinHeight : f32,               // Height submitted to TableNextRow()
    RowCellPaddingY : f32,            // Top and bottom padding. Reloaded during row change.
    RowTextBaseline : f32,
    RowIndentOffsetX : f32,
    ImGuiTableRowFlags          RowFlags : 16;              // Current row flags, see ImGuiTableRowFlags_
    ImGuiTableRowFlags          LastRowFlags : 16;
    RowBgColorCounter : i32,          // Counter for alternating background colors (can be fast-forwarded by e.g clipper), not same as CurrentRow because header rows typically don't increase this.
    RowBgColor : [2]u32,              // Background color override for current row.
    BorderColorStrong : u32,
    BorderColorLight : u32,
    BorderX1 : f32,
    BorderX2 : f32,
    HostIndentX : f32,
    MinColumnWidth : f32,
    OuterPaddingX : f32,
    CellPaddingX : f32,               // Padding from each borders. Locked in BeginTable()/Layout.
    CellSpacingX1 : f32,              // Spacing between non-bordered cells. Locked in BeginTable()/Layout.
    CellSpacingX2 : f32,
    InnerWidth : f32,                 // User value passed to BeginTable(), see comments at the top of BeginTable() for details.
    ColumnsGivenWidth : f32,          // Sum of current column width
    ColumnsAutoFitWidth : f32,        // Sum of ideal column width in order nothing to be clipped, used for auto-fitting and content width submission in outer window
    ColumnsStretchSumWeights : f32,   // Sum of weight of all enabled stretching columns
    ResizedColumnNextWidth : f32,
    ResizeLockMinContentsX2 : f32,    // Lock minimum contents width while resizing down in order to not create feedback loops. But we allow growing the table.
    RefScale : f32,                   // Reference scale to be able to rescale columns on font/dpi changes.
    AngledHeadersHeight : f32,        // Set by TableAngledHeadersRow(), used in TableUpdateLayout()
    AngledHeadersSlope : f32,         // Set by TableAngledHeadersRow(), used in TableUpdateLayout()
    OuterRect : ImRect,                  // Note: for non-scrolling table, OuterRect.Max.y is often FLT_MAX until EndTable(), unless a height has been specified in BeginTable().
    InnerRect : ImRect,                  // InnerRect but without decoration. As with OuterRect, for non-scrolling tables, InnerRect.Max.y is
    WorkRect : ImRect,
    InnerClipRect : ImRect,
    BgClipRect : ImRect,                 // We use this to cpu-clip cell background color fill, evolve during the frame as we cross frozen rows boundaries
    Bg0ClipRectForDrawCmd : ImRect,      // Actual ImDrawCmd clip rect for BG0/1 channel. This tends to be == OuterWindow->ClipRect at BeginTable() because output in BG0/BG1 is cpu-clipped
    Bg2ClipRectForDrawCmd : ImRect,      // Actual ImDrawCmd clip rect for BG2 channel. This tends to be a correct, tight-fit, because output to BG2 are done by widgets relying on regular ClipRect.
    HostClipRect : ImRect,               // This is used to check if we can eventually merge our columns draw calls into the current draw call of the current window.
    HostBackupInnerClipRect : ImRect,    // Backup of InnerWindow->ClipRect during PushTableBackground()/PopTableBackground()
    OuterWindow : ^ImGuiWindow,                // Parent window for the table
    InnerWindow : ^ImGuiWindow,                // Window holding the table data (== OuterWindow or a child window)
    ColumnsNames : ImGuiTextBuffer,               // Contiguous buffer holding columns names
    DrawSplitter : ^ImDrawListSplitter,               // Shortcut to TempData->DrawSplitter while in table. Isolate draw commands per columns to avoid switching clip rect constantly
    InstanceDataFirst : ImGuiTableInstanceData,
    InstanceDataExtra : [dynamic]ImGuiTableInstanceData,  // FIXME-OPT: Using a small-vector pattern would be good.
    SortSpecsSingle : ImGuiTableColumnSortSpecs,
    SortSpecsMulti : [dynamic]ImGuiTableColumnSortSpecs,     // FIXME-OPT: Using a small-vector pattern would be good.
    SortSpecs : ImGuiTableSortSpecs,                  // Public facing sorts specs, this is what we return in TableGetSortSpecs()
    SortSpecsCount : ImGuiTableColumnIdx,
    ColumnsEnabledCount : ImGuiTableColumnIdx,        // Number of enabled columns (<= ColumnsCount)
    ColumnsEnabledFixedCount : ImGuiTableColumnIdx,   // Number of enabled columns using fixed width (<= ColumnsCount)
    DeclColumnsCount : ImGuiTableColumnIdx,           // Count calls to TableSetupColumn()
    AngledHeadersCount : ImGuiTableColumnIdx,         // Count columns with angled headers
    HoveredColumnBody : ImGuiTableColumnIdx,          // Index of column whose visible region is being hovered. Important: == ColumnsCount when hovering empty region after the right-most column!
    HoveredColumnBorder : ImGuiTableColumnIdx,        // Index of column whose right-border is being hovered (for resizing).
    HighlightColumnHeader : ImGuiTableColumnIdx,      // Index of column which should be highlighted.
    AutoFitSingleColumn : ImGuiTableColumnIdx,        // Index of single column requesting auto-fit.
    ResizedColumn : ImGuiTableColumnIdx,              // Index of column being resized. Reset when InstanceCurrent==0.
    LastResizedColumn : ImGuiTableColumnIdx,          // Index of column being resized from previous frame.
    HeldHeaderColumn : ImGuiTableColumnIdx,           // Index of column header being held.
    ReorderColumn : ImGuiTableColumnIdx,              // Index of column being reordered. (not cleared)
    ReorderColumnDir : ImGuiTableColumnIdx,           // -1 or +1
    LeftMostEnabledColumn : ImGuiTableColumnIdx,      // Index of left-most non-hidden column.
    RightMostEnabledColumn : ImGuiTableColumnIdx,     // Index of right-most non-hidden column.
    LeftMostStretchedColumn : ImGuiTableColumnIdx,    // Index of left-most stretched column.
    RightMostStretchedColumn : ImGuiTableColumnIdx,   // Index of right-most stretched column.
    ContextPopupColumn : ImGuiTableColumnIdx,         // Column right-clicked on, of -1 if opening context menu from a neutral/empty spot
    FreezeRowsRequest : ImGuiTableColumnIdx,          // Requested frozen rows count
    FreezeRowsCount : ImGuiTableColumnIdx,            // Actual frozen row count (== FreezeRowsRequest, or == 0 when no scrolling offset)
    FreezeColumnsRequest : ImGuiTableColumnIdx,       // Requested frozen columns count
    FreezeColumnsCount : ImGuiTableColumnIdx,         // Actual frozen columns count (== FreezeColumnsRequest, or == 0 when no scrolling offset)
    RowCellDataCurrent : ImGuiTableColumnIdx,         // Index of current RowCellData[] entry in current row
    DummyDrawChannel : ImGuiTableDrawChannelIdx,           // Redirect non-visible columns here.
    Bg2DrawChannelCurrent : ImGuiTableDrawChannelIdx,      // For Selectable() and other widgets drawing across columns after the freezing line. Index within DrawSplitter.Channels[]
    Bg2DrawChannelUnfrozen : ImGuiTableDrawChannelIdx,
    IsLayoutLocked : bool,             // Set by TableUpdateLayout() which is called when beginning the first row.
    IsInsideRow : bool,                // Set when inside TableBeginRow()/TableEndRow().
    IsInitializing : bool,
    IsSortSpecsDirty : bool,
    IsUsingHeaders : bool,             // Set when the first row had the ImGuiTableRowFlags_Headers flag.
    IsContextPopupOpen : bool,         // Set when default context menu is open (also see: ContextPopupColumn, InstanceInteracted).
    DisableDefaultContextMenu : bool,  // Disable default context menu contents. You may submit your own using TableBeginContextMenuPopup()/EndPopup()
    IsSettingsRequestLoad : bool,
    IsSettingsDirty : bool,            // Set when table settings have changed and needs to be reported into ImGuiTableSetttings data.
    IsDefaultDisplayOrder : bool,      // Set when display order is unchanged from default (DisplayOrder contains 0...Count-1)
    IsResetAllRequest : bool,
    IsResetDisplayOrderRequest : bool,
    IsUnfrozenRows : bool,             // Set when we got past the frozen row.
    IsDefaultSizingPolicy : bool,      // Set if user didn't explicitly set a sizing policy in BeginTable()
    IsActiveIdAliveBeforeTable : bool,
    IsActiveIdInTable : bool,
    HasScrollbarYCurr : bool,          // Whether ANY instance of this table had a vertical scrollbar during the current frame.
    HasScrollbarYPrev : bool,          // Whether ANY instance of this table had a vertical scrollbar during the previous.
    MemoryCompacted : bool,
    HostSkipItems : bool,              // Backup of InnerWindow->SkipItem at the end of BeginTable(), because we will overwrite InnerWindow->SkipItem on a per-column basis

    ImGuiTable()                { memset(this, 0, size_of(*this)); LastFrameActive = -1; }
    ~ImGuiTable()               { IM_FREE(RawData); }
};

// Transient data that are only needed between BeginTable() and EndTable(), those buffers are shared (1 per level of stacked table).
// - Accessing those requires chasing an extra pointer so for very frequently used data we leave them in the main table structure.
// - We also leave out of this structure data that tend to be particularly useful for debugging/metrics.
// FIXME-TABLE: more transient data could be stored in a stacked ImGuiTableTempData: e.g. SortSpecs.
// sizeof() ~ 136 bytes.
ImGuiTableTempData :: struct
{
    TableIndex : i32,                 // Index in g.Tables.Buf[] pool
    LastTimeActive : f32,             // Last timestamp this structure was used
    AngledHeadersExtraWidth : f32,    // Used in EndTable()
    AngledHeadersRequests : [dynamic]ImGuiTableHeaderData,   // Used in TableAngledHeadersRow()

    UserOuterSize : ImVec2,              // outer_size.x passed to BeginTable()
    DrawSplitter : ImDrawListSplitter,

    HostBackupWorkRect : ImRect,         // Backup of InnerWindow->WorkRect at the end of BeginTable()
    HostBackupParentWorkRect : ImRect,   // Backup of InnerWindow->ParentWorkRect at the end of BeginTable()
    HostBackupPrevLineSize : ImVec2,     // Backup of InnerWindow->DC.PrevLineSize at the end of BeginTable()
    HostBackupCurrLineSize : ImVec2,     // Backup of InnerWindow->DC.CurrLineSize at the end of BeginTable()
    HostBackupCursorMaxPos : ImVec2,     // Backup of InnerWindow->DC.CursorMaxPos at the end of BeginTable()
    HostBackupColumnsOffset : ImVec1,    // Backup of OuterWindow->DC.ColumnsOffset at the end of BeginTable()
    HostBackupItemWidth : f32,        // Backup of OuterWindow->DC.ItemWidth at the end of BeginTable()
    HostBackupItemWidthStackSize : i32,//Backup of OuterWindow->DC.ItemWidthStack.Size at the end of BeginTable()

    ImGuiTableTempData()        { memset(this, 0, size_of(*this)); LastTimeActive = -1.0; }
};

// sizeof() ~ 12
ImGuiTableColumnSettings :: struct
{
    WidthOrWeight : f32,
    UserID : ImGuiID,
    Index : ImGuiTableColumnIdx,
    DisplayOrder : ImGuiTableColumnIdx,
    SortOrder : ImGuiTableColumnIdx,
    u8                    SortDirection : 2;
    u8                    IsEnabled : 1; // "Visible" in ini file
    u8                    IsStretch : 1;

    ImGuiTableColumnSettings()
    {
        WidthOrWeight = 0.0;
        UserID = 0;
        Index = -1;
        DisplayOrder = SortOrder = -1;
        SortDirection = ImGuiSortDirection_None;
        IsEnabled = 1;
        IsStretch = 0;
    }
};

// This is designed to be stored in a single ImChunkStream (1 header followed by N ImGuiTableColumnSettings, etc.)
ImGuiTableSettings :: struct
{
    ID : ImGuiID,                     // Set to 0 to invalidate/delete the setting
    SaveFlags : ImGuiTableFlags,              // Indicate data we want to save using the Resizable/Reorderable/Sortable/Hideable flags (could be using its own flags..)
    RefScale : f32,               // Reference scale to be able to rescale columns on font/dpi changes.
    ColumnsCount : ImGuiTableColumnIdx,
    ColumnsCountMax : ImGuiTableColumnIdx,        // Maximum number of columns this settings instance can store, we can recycle a settings instance with lower number of columns but not higher
    WantApply : bool,              // Set when loaded from .ini data (to enable merging/loading .ini data into an already running context)

    ImGuiTableSettings()        { memset(this, 0, size_of(*this)); }
    ImGuiTableColumnSettings*   GetColumnSettings()     { return (ImGuiTableColumnSettings*)(this + 1); }
};

//-----------------------------------------------------------------------------
// [SECTION] ImGui internal API
// No guarantee of forward compatibility here!
//-----------------------------------------------------------------------------

namespace ImGui
{
    // Windows
    // We should always have a CurrentWindow in the stack (there is an implicit "Debug" window)
    // If this ever crashes because g.CurrentWindow is NULL, it means that either:
    // - ImGui::NewFrame() has never been called, which is illegal.
    // - You are calling ImGui functions after ImGui::EndFrame()/ImGui::Render() and before the next ImGui::NewFrame(), which is also illegal.
    ImGuiIO&         GetIOEx(ImGuiContext* ctx);
    ImGuiPlatformIO& GetPlatformIOEx(ImGuiContext* ctx);
    inline    ImGuiWindow*  GetCurrentWindowRead()      { ImGuiContext& g = *GImGui; return g.CurrentWindow; }
    inline    ImGuiWindow*  GetCurrentWindow()          { ImGuiContext& g = *GImGui; g.CurrentWindow.WriteAccessed = true; return g.CurrentWindow; }
    ImGuiWindow*  FindWindowByID(ImGuiID id);
    ImGuiWindow*  FindWindowByName(const u8* name);
    void          UpdateWindowParentAndRootLinks(ImGuiWindow* window, ImGuiWindowFlags flags, ImGuiWindow* parent_window);
    void          UpdateWindowSkipRefresh(ImGuiWindow* window);
    CalcWindowNextAutoFitSize := ImVec2{ImGuiWindow* window};
    bool          IsWindowChildOf(ImGuiWindow* window, ImGuiWindow* potential_parent, bool popup_hierarchy, bool dock_hierarchy);
    bool          IsWindowWithinBeginStackOf(ImGuiWindow* window, ImGuiWindow* potential_parent);
    bool          IsWindowAbove(ImGuiWindow* potential_above, ImGuiWindow* potential_below);
    bool          IsWindowNavFocusable(ImGuiWindow* window);
    void          SetWindowPos(ImGuiWindow* window, const ImVec2& pos, ImGuiCond cond = 0);
    void          SetWindowSize(ImGuiWindow* window, const ImVec2& size, ImGuiCond cond = 0);
    void          SetWindowCollapsed(ImGuiWindow* window, bool collapsed, ImGuiCond cond = 0);
    void          SetWindowHitTestHole(ImGuiWindow* window, const ImVec2& pos, const ImVec2& size);
    void          SetWindowHiddenAndSkipItemsForCurrentFrame(ImGuiWindow* window);
    inline void             SetWindowParentWindowForFocusRoute(ImGuiWindow* window, ImGuiWindow* parent_window) { window.ParentWindowForFocusRoute = parent_window; } // You may also use SetNextWindowClass()'s FocusRouteParentWindowId field.
    inline ImRect           WindowRectAbsToRel(ImGuiWindow* window, const ImRect& r) { ImVec2 off = window.DC.CursorStartPos; return ImRect(r.Min.x - off.x, r.Min.y - off.y, r.Max.x - off.x, r.Max.y - off.y); }
    inline ImRect           WindowRectRelToAbs(ImGuiWindow* window, const ImRect& r) { ImVec2 off = window.DC.CursorStartPos; return ImRect(r.Min.x + off.x, r.Min.y + off.y, r.Max.x + off.x, r.Max.y + off.y); }
    inline ImVec2           WindowPosAbsToRel(ImGuiWindow* window, const ImVec2& p)  { ImVec2 off = window.DC.CursorStartPos; return ImVec2{p.x - off.x, p.y - off.y}; }
    inline ImVec2           WindowPosRelToAbs(ImGuiWindow* window, const ImVec2& p)  { ImVec2 off = window.DC.CursorStartPos; return ImVec2{p.x + off.x, p.y + off.y}; }

    // Windows: Display Order and Focus Order
    void          FocusWindow(ImGuiWindow* window, ImGuiFocusRequestFlags flags = 0);
    void          FocusTopMostWindowUnderOne(ImGuiWindow* under_this_window, ImGuiWindow* ignore_window, ImGuiViewport* filter_viewport, ImGuiFocusRequestFlags flags);
    void          BringWindowToFocusFront(ImGuiWindow* window);
    void          BringWindowToDisplayFront(ImGuiWindow* window);
    void          BringWindowToDisplayBack(ImGuiWindow* window);
    void          BringWindowToDisplayBehind(ImGuiWindow* window, ImGuiWindow* above_window);
    i32           FindWindowDisplayIndex(ImGuiWindow* window);
    ImGuiWindow*  FindBottomMostVisibleWindowWithinBeginStack(ImGuiWindow* window);

    // Windows: Idle, Refresh Policies [EXPERIMENTAL]
    void          SetNextWindowRefreshPolicy(ImGuiWindowRefreshFlags flags);

    // Fonts, drawing
    void          SetCurrentFont(ImFont* font);
    inline ImFont*          GetDefaultFont() { ImGuiContext& g = *GImGui; return g.IO.FontDefault ? g.IO.FontDefault : g.IO.Fonts.Fonts[0]; }
    inline ImDrawList*      GetForegroundDrawList(ImGuiWindow* window) { return GetForegroundDrawList(window.Viewport); }
    void          AddDrawListToDrawDataEx(ImDrawData* draw_data, ImVector<ImDrawList*>* out_list, ImDrawList* draw_list);

    // Init
    void          Initialize();
    void          Shutdown();    // Since 1.60 this is a _private_ function. You can call DestroyContext() to destroy the context created by CreateContext().

    // NewFrame
    void          UpdateInputEvents(bool trickle_fast_inputs);
    void          UpdateHoveredWindowAndCaptureFlags();
    void          FindHoveredWindowEx(const ImVec2& pos, bool find_first_and_in_any_viewport, ImGuiWindow** out_hovered_window, ImGuiWindow** out_hovered_window_under_moving_window);
    void          StartMouseMovingWindow(ImGuiWindow* window);
    void          StartMouseMovingWindowOrNode(ImGuiWindow* window, ImGuiDockNode* node, bool undock);
    void          UpdateMouseMovingWindowNewFrame();
    void          UpdateMouseMovingWindowEndFrame();

    // Generic context hooks
    AddContextHook := ImGuiID(ImGuiContext* context, const ImGuiContextHook* hook);
    void          RemoveContextHook(ImGuiContext* context, ImGuiID hook_to_remove);
    void          CallContextHooks(ImGuiContext* context, ImGuiContextHookType type);

    // Viewports
    void          TranslateWindowsInViewport(ImGuiViewportP* viewport, const ImVec2& old_pos, const ImVec2& new_pos, const ImVec2& old_size, const ImVec2& new_size);
    void          ScaleWindowsInViewport(ImGuiViewportP* viewport, f32 scale);
    void          DestroyPlatformWindow(ImGuiViewportP* viewport);
    void          SetWindowViewport(ImGuiWindow* window, ImGuiViewportP* viewport);
    void          SetCurrentViewport(ImGuiWindow* window, ImGuiViewportP* viewport);
    const ImGuiPlatformMonitor*   GetViewportPlatformMonitor(ImGuiViewport* viewport);
    ImGuiViewportP*               FindHoveredViewportFromPlatformWindowStack(const ImVec2& mouse_platform_pos);

    // Settings
    void                  MarkIniSettingsDirty();
    void                  MarkIniSettingsDirty(ImGuiWindow* window);
    void                  ClearIniSettings();
    void                  AddSettingsHandler(const ImGuiSettingsHandler* handler);
    void                  RemoveSettingsHandler(const u8* type_name);
    ImGuiSettingsHandler* FindSettingsHandler(const u8* type_name);

    // Settings - Windows
    ImGuiWindowSettings*  CreateNewWindowSettings(const u8* name);
    ImGuiWindowSettings*  FindWindowSettingsByID(ImGuiID id);
    ImGuiWindowSettings*  FindWindowSettingsByWindow(ImGuiWindow* window);
    void                  ClearWindowSettings(const u8* name);

    // Localization
    void          LocalizeRegisterEntries(const ImGuiLocEntry* entries, i32 count);
    inline const u8*      LocalizeGetMsg(ImGuiLocKey key) { ImGuiContext& g = *GImGui; const u8* msg = g.LocalizationTable[key]; return msg ? msg : "*Missing Text*"; }

    // Scrolling
    void          SetScrollX(ImGuiWindow* window, f32 scroll_x);
    void          SetScrollY(ImGuiWindow* window, f32 scroll_y);
    void          SetScrollFromPosX(ImGuiWindow* window, f32 local_x, f32 center_x_ratio);
    void          SetScrollFromPosY(ImGuiWindow* window, f32 local_y, f32 center_y_ratio);

    // Early work-in-progress API (ScrollToItem() will become public)
    void          ScrollToItem(ImGuiScrollFlags flags = 0);
    void          ScrollToRect(ImGuiWindow* window, const ImRect& rect, ImGuiScrollFlags flags = 0);
    ScrollToRectEx := ImVec2{ImGuiWindow* window, const ImRect& rect, ImGuiScrollFlags flags = 0};
//#ifndef IMGUI_DISABLE_OBSOLETE_FUNCTIONS
    inline void             ScrollToBringRectIntoView(ImGuiWindow* window, const ImRect& rect) { ScrollToRect(window, rect, ImGuiScrollFlags_KeepVisibleEdgeY); }
//#endif

    // Basic Accessors
    inline ImGuiItemStatusFlags GetItemStatusFlags() { ImGuiContext& g = *GImGui; return g.LastItemData.StatusFlags; }
    inline ImGuiItemFlags   GetItemFlags()  { ImGuiContext& g = *GImGui; return g.LastItemData.ItemFlags; }
    inline ImGuiID          GetActiveID()   { ImGuiContext& g = *GImGui; return g.ActiveId; }
    inline ImGuiID          GetFocusID()    { ImGuiContext& g = *GImGui; return g.NavId; }
    void          SetActiveID(ImGuiID id, ImGuiWindow* window);
    void          SetFocusID(ImGuiID id, ImGuiWindow* window);
    void          ClearActiveID();
    GetHoveredID := ImGuiID();
    void          SetHoveredID(ImGuiID id);
    void          KeepAliveID(ImGuiID id);
    void          MarkItemEdited(ImGuiID id);     // Mark data associated to given item as "edited", used by IsItemDeactivatedAfterEdit() function.
    void          PushOverrideID(ImGuiID id);     // Push given value as-is at the top of the ID stack (whereas PushID combines old and new hashes)
    GetIDWithSeed := ImGuiID(const u8* str_id_begin, const u8* str_id_end, ImGuiID seed);
    GetIDWithSeed := ImGuiID(i32 n, ImGuiID seed);

    // Basic Helpers for widget code
    void          ItemSize(const ImVec2& size, f32 text_baseline_y = -1.0);
    inline void             ItemSize(const ImRect& bb, f32 text_baseline_y = -1.0) { ItemSize(bb.GetSize(), text_baseline_y); } // FIXME: This is a misleading API since we expect CursorPos to be bb.Min.
    bool          ItemAdd(const ImRect& bb, ImGuiID id, const ImRect* nav_bb = nil, ImGuiItemFlags extra_flags = 0);
    bool          ItemHoverable(const ImRect& bb, ImGuiID id, ImGuiItemFlags item_flags);
    bool          IsWindowContentHoverable(ImGuiWindow* window, ImGuiHoveredFlags flags = 0);
    bool          IsClippedEx(const ImRect& bb, ImGuiID id);
    void          SetLastItemData(ImGuiID item_id, ImGuiItemFlags in_flags, ImGuiItemStatusFlags status_flags, const ImRect& item_rect);
    CalcItemSize := ImVec2{ImVec2 size, f32 default_w, f32 default_h};
    f32         CalcWrapWidthForPos(const ImVec2& pos, f32 wrap_pos_x);
    void          PushMultiItemsWidths(i32 components, f32 width_full);
    void          ShrinkWidths(ImGuiShrinkWidthItem* items, i32 count, f32 width_excess);

    // Parameter stacks (shared)
    const ImGuiDataVarInfo* GetStyleVarInfo(ImGuiStyleVar idx);
    void          BeginDisabledOverrideReenable();
    void          EndDisabledOverrideReenable();

    // Logging/Capture
    void          LogBegin(ImGuiLogFlags flags, i32 auto_open_depth);         // -> BeginCapture() when we design v2 api, for now stay under the radar by using the old name.
    void          LogToBuffer(i32 auto_open_depth = -1);                      // Start logging/capturing to internal buffer
    void          LogRenderedText(const ImVec2* ref_pos, const u8* text, const u8* text_end = nil);
    void          LogSetNextTextDecoration(const u8* prefix, const u8* suffix);

    // Childs
    bool          BeginChildEx(const u8* name, ImGuiID id, const ImVec2& size_arg, ImGuiChildFlags child_flags, ImGuiWindowFlags window_flags);

    // Popups, Modals
    bool          BeginPopupEx(ImGuiID id, ImGuiWindowFlags extra_window_flags);
    void          OpenPopupEx(ImGuiID id, ImGuiPopupFlags popup_flags = ImGuiPopupFlags_None);
    void          ClosePopupToLevel(i32 remaining, bool restore_focus_to_window_under_popup);
    void          ClosePopupsOverWindow(ImGuiWindow* ref_window, bool restore_focus_to_window_under_popup);
    void          ClosePopupsExceptModals();
    bool          IsPopupOpen(ImGuiID id, ImGuiPopupFlags popup_flags);
    GetPopupAllowedExtentRect := ImRect(ImGuiWindow* window);
    ImGuiWindow*  GetTopMostPopupModal();
    ImGuiWindow*  GetTopMostAndVisiblePopupModal();
    ImGuiWindow*  FindBlockingModal(ImGuiWindow* window);
    FindBestWindowPosForPopup := ImVec2{ImGuiWindow* window};
    FindBestWindowPosForPopupEx := ImVec2{const ImVec2& ref_pos, const ImVec2& size, ImGuiDir* last_dir, const ImRect& r_outer, const ImRect& r_avoid, ImGuiPopupPositionPolicy policy};

    // Tooltips
    bool          BeginTooltipEx(ImGuiTooltipFlags tooltip_flags, ImGuiWindowFlags extra_window_flags);
    bool          BeginTooltipHidden();

    // Menus
    bool          BeginViewportSideBar(const u8* name, ImGuiViewport* viewport, ImGuiDir dir, f32 size, ImGuiWindowFlags window_flags);
    bool          BeginMenuEx(const u8* label, const u8* icon, bool enabled = true);
    bool          MenuItemEx(const u8* label, const u8* icon, const u8* shortcut = nil, bool selected = false, bool enabled = true);

    // Combos
    bool          BeginComboPopup(ImGuiID popup_id, const ImRect& bb, ImGuiComboFlags flags);
    bool          BeginComboPreview();
    void          EndComboPreview();

    // Keyboard/Gamepad Navigation
    void          NavInitWindow(ImGuiWindow* window, bool force_reinit);
    void          NavInitRequestApplyResult();
    bool          NavMoveRequestButNoResultYet();
    void          NavMoveRequestSubmit(ImGuiDir move_dir, ImGuiDir clip_dir, ImGuiNavMoveFlags move_flags, ImGuiScrollFlags scroll_flags);
    void          NavMoveRequestForward(ImGuiDir move_dir, ImGuiDir clip_dir, ImGuiNavMoveFlags move_flags, ImGuiScrollFlags scroll_flags);
    void          NavMoveRequestResolveWithLastItem(ImGuiNavItemData* result);
    void          NavMoveRequestResolveWithPastTreeNode(ImGuiNavItemData* result, ImGuiTreeNodeStackData* tree_node_data);
    void          NavMoveRequestCancel();
    void          NavMoveRequestApplyResult();
    void          NavMoveRequestTryWrapping(ImGuiWindow* window, ImGuiNavMoveFlags move_flags);
    void          NavHighlightActivated(ImGuiID id);
    void          NavClearPreferredPosForAxis(ImGuiAxis axis);
    void          SetNavCursorVisibleAfterMove();
    void          NavUpdateCurrentWindowIsScrollPushableX();
    void          SetNavWindow(ImGuiWindow* window);
    void          SetNavID(ImGuiID id, ImGuiNavLayer nav_layer, ImGuiID focus_scope_id, const ImRect& rect_rel);
    void          SetNavFocusScope(ImGuiID focus_scope_id);

    // Focus/Activation
    // This should be part of a larger set of API: FocusItem(offset = -1), FocusItemByID(id), ActivateItem(offset = -1), ActivateItemByID(id) etc. which are
    // much harder to design and implement than expected. I have a couple of private branches on this matter but it's not simple. For now implementing the easy ones.
    void          FocusItem();                    // Focus last item (no selection/activation).
    void          ActivateItemByID(ImGuiID id);   // Activate an item by ID (button, checkbox, tree node etc.). Activation is queued and processed on the next frame when the item is encountered again.

    // Inputs
    // FIXME: Eventually we should aim to move e.g. IsActiveIdUsingKey() into IsKeyXXX functions.
    inline bool             IsNamedKey(ImGuiKey key)                    { return key >= ImGuiKey_NamedKey_BEGIN && key < ImGuiKey_NamedKey_END; }
    inline bool             IsNamedKeyOrMod(ImGuiKey key)               { return (key >= ImGuiKey_NamedKey_BEGIN && key < ImGuiKey_NamedKey_END) || key == ImGuiMod_Ctrl || key == ImGuiMod_Shift || key == ImGuiMod_Alt || key == ImGuiMod_Super; }
    inline bool             IsLegacyKey(ImGuiKey key)                   { return key >= ImGuiKey_LegacyNativeKey_BEGIN && key < ImGuiKey_LegacyNativeKey_END; }
    inline bool             IsKeyboardKey(ImGuiKey key)                 { return key >= ImGuiKey_Keyboard_BEGIN && key < ImGuiKey_Keyboard_END; }
    inline bool             IsGamepadKey(ImGuiKey key)                  { return key >= ImGuiKey_Gamepad_BEGIN && key < ImGuiKey_Gamepad_END; }
    inline bool             IsMouseKey(ImGuiKey key)                    { return key >= ImGuiKey_Mouse_BEGIN && key < ImGuiKey_Mouse_END; }
    inline bool             IsAliasKey(ImGuiKey key)                    { return key >= ImGuiKey_Aliases_BEGIN && key < ImGuiKey_Aliases_END; }
    inline bool             IsLRModKey(ImGuiKey key)                    { return key >= ImGuiKey_LeftCtrl && key <= ImGuiKey_RightSuper; }
    FixupKeyChord := ImGuiKeyChord(ImGuiKeyChord key_chord);
    inline ImGuiKey         ConvertSingleModFlagToKey(ImGuiKey key)
    {
        if (key == ImGuiMod_Ctrl) return ImGuiKey_ReservedForModCtrl;
        if (key == ImGuiMod_Shift) return ImGuiKey_ReservedForModShift;
        if (key == ImGuiMod_Alt) return ImGuiKey_ReservedForModAlt;
        if (key == ImGuiMod_Super) return ImGuiKey_ReservedForModSuper;
        return key;
    }

    ImGuiKeyData* GetKeyData(ImGuiContext* ctx, ImGuiKey key);
    inline ImGuiKeyData*    GetKeyData(ImGuiKey key)                                    { ImGuiContext& g = *GImGui; return GetKeyData(&g, key); }
    const u8*   GetKeyChordName(ImGuiKeyChord key_chord);
    inline ImGuiKey         MouseButtonToKey(ImGuiMouseButton button)                   { assert(button >= 0 && button < ImGuiMouseButton_COUNT); return (ImGuiKey)(ImGuiKey_MouseLeft + button); }
    bool          IsMouseDragPastThreshold(ImGuiMouseButton button, f32 lock_threshold = -1.0);
    GetKeyMagnitude2d := ImVec2{ImGuiKey key_left, ImGuiKey key_right, ImGuiKey key_up, ImGuiKey key_down};
    f32         GetNavTweakPressedAmount(ImGuiAxis axis);
    i32           CalcTypematicRepeatAmount(f32 t0, f32 t1, f32 repeat_delay, f32 repeat_rate);
    void          GetTypematicRepeatRate(ImGuiInputFlags flags, f32* repeat_delay, f32* repeat_rate);
    void          TeleportMousePos(const ImVec2& pos);
    void          SetActiveIdUsingAllKeyboardKeys();
    inline bool             IsActiveIdUsingNavDir(ImGuiDir dir)                         { ImGuiContext& g = *GImGui; return (g.ActiveIdUsingNavDirMask & (1 << dir)) != 0; }

    // [EXPERIMENTAL] Low-Level: Key/Input Ownership
    // - The idea is that instead of "eating" a given input, we can link to an owner id.
    // - Ownership is most often claimed as a result of reacting to a press/down event (but occasionally may be claimed ahead).
    // - Input queries can then read input by specifying ImGuiKeyOwner_Any (== 0), ImGuiKeyOwner_NoOwner (== -1) or a custom ID.
    // - Legacy input queries (without specifying an owner or _Any or _None) are equivalent to using ImGuiKeyOwner_Any (== 0).
    // - Input ownership is automatically released on the frame after a key is released. Therefore:
    //   - for ownership registration happening as a result of a down/press event, the SetKeyOwner() call may be done once (common case).
    //   - for ownership registration happening ahead of a down/press event, the SetKeyOwner() call needs to be made every frame (happens if e.g. claiming ownership on hover).
    // - SetItemKeyOwner() is a shortcut for common simple case. A custom widget will probably want to call SetKeyOwner() multiple times directly based on its interaction state.
    // - This is marked experimental because not all widgets are fully honoring the Set/Test idioms. We will need to move forward step by step.
    //   Please open a GitHub Issue to submit your usage scenario or if there's a use case you need solved.
    GetKeyOwner := ImGuiID(ImGuiKey key);
    void          SetKeyOwner(ImGuiKey key, ImGuiID owner_id, ImGuiInputFlags flags = 0);
    void          SetKeyOwnersForKeyChord(ImGuiKeyChord key, ImGuiID owner_id, ImGuiInputFlags flags = 0);
    void          SetItemKeyOwner(ImGuiKey key, ImGuiInputFlags flags);       // Set key owner to last item if it is hovered or active. Equivalent to 'if (IsItemHovered() || IsItemActive()) { SetKeyOwner(key, GetItemID());'.
    bool          TestKeyOwner(ImGuiKey key, ImGuiID owner_id);               // Test that key is either not owned, either owned by 'owner_id'
    inline ImGuiKeyOwnerData* GetKeyOwnerData(ImGuiContext* ctx, ImGuiKey key)          { if (key & ImGuiMod_Mask_) key = ConvertSingleModFlagToKey(key); assert(IsNamedKey(key)); return &ctx.KeysOwnerData[key - ImGuiKey_NamedKey_BEGIN]; }

    // [EXPERIMENTAL] High-Level: Input Access functions w/ support for Key/Input Ownership
    // - Important: legacy IsKeyPressed(ImGuiKey, bool repeat=true) _DEFAULTS_ to repeat, new IsKeyPressed() requires _EXPLICIT_ ImGuiInputFlags_Repeat flag.
    // - Expected to be later promoted to public API, the prototypes are designed to replace existing ones (since owner_id can default to Any == 0)
    // - Specifying a value for 'ImGuiID owner' will test that EITHER the key is NOT owned (UNLESS locked), EITHER the key is owned by 'owner'.
    //   Legacy functions use ImGuiKeyOwner_Any meaning that they typically ignore ownership, unless a call to SetKeyOwner() explicitly used ImGuiInputFlags_LockThisFrame or ImGuiInputFlags_LockUntilRelease.
    // - Binding generators may want to ignore those for now, or suffix them with Ex() until we decide if this gets moved into public API.
    bool          IsKeyDown(ImGuiKey key, ImGuiID owner_id);
    bool          IsKeyPressed(ImGuiKey key, ImGuiInputFlags flags, ImGuiID owner_id = 0);    // Important: when transitioning from old to new IsKeyPressed(): old API has "bool repeat = true", so would default to repeat. New API requiress explicit ImGuiInputFlags_Repeat.
    bool          IsKeyReleased(ImGuiKey key, ImGuiID owner_id);
    bool          IsKeyChordPressed(ImGuiKeyChord key_chord, ImGuiInputFlags flags, ImGuiID owner_id = 0);
    bool          IsMouseDown(ImGuiMouseButton button, ImGuiID owner_id);
    bool          IsMouseClicked(ImGuiMouseButton button, ImGuiInputFlags flags, ImGuiID owner_id = 0);
    bool          IsMouseReleased(ImGuiMouseButton button, ImGuiID owner_id);
    bool          IsMouseDoubleClicked(ImGuiMouseButton button, ImGuiID owner_id);

    // Shortcut Testing & Routing
    // - Set Shortcut() and SetNextItemShortcut() in imgui.h
    // - When a policy (except for ImGuiInputFlags_RouteAlways *) is set, Shortcut() will register itself with SetShortcutRouting(),
    //   allowing the system to decide where to route the input among other route-aware calls.
    //   (* using ImGuiInputFlags_RouteAlways is roughly equivalent to calling IsKeyChordPressed(key) and bypassing route registration and check)
    // - When using one of the routing option:
    //   - The default route is ImGuiInputFlags_RouteFocused (accept inputs if window is in focus stack. Deep-most focused window takes inputs. ActiveId takes inputs over deep-most focused window.)
    //   - Routes are requested given a chord (key + modifiers) and a routing policy.
    //   - Routes are resolved during NewFrame(): if keyboard modifiers are matching current ones: SetKeyOwner() is called + route is granted for the frame.
    //   - Each route may be granted to a single owner. When multiple requests are made we have policies to select the winning route (e.g. deep most window).
    //   - Multiple read sites may use the same owner id can all access the granted route.
    //   - When owner_id is 0 we use the current Focus Scope ID as a owner ID in order to identify our location.
    // - You can chain two unrelated windows in the focus stack using SetWindowParentWindowForFocusRoute()
    //   e.g. if you have a tool window associated to a document, and you want document shortcuts to run when the tool is focused.
    bool          Shortcut(ImGuiKeyChord key_chord, ImGuiInputFlags flags, ImGuiID owner_id);
    bool          SetShortcutRouting(ImGuiKeyChord key_chord, ImGuiInputFlags flags, ImGuiID owner_id); // owner_id needs to be explicit and cannot be 0
    bool          TestShortcutRouting(ImGuiKeyChord key_chord, ImGuiID owner_id);
    ImGuiKeyRoutingData* GetShortcutRoutingData(ImGuiKeyChord key_chord);

    // Docking
    // (some functions are only declared in imgui.cpp, see Docking section)
    void          DockContextInitialize(ImGuiContext* ctx);
    void          DockContextShutdown(ImGuiContext* ctx);
    void          DockContextClearNodes(ImGuiContext* ctx, ImGuiID root_id, bool clear_settings_refs); // Use root_id==0 to clear all
    void          DockContextRebuildNodes(ImGuiContext* ctx);
    void          DockContextNewFrameUpdateUndocking(ImGuiContext* ctx);
    void          DockContextNewFrameUpdateDocking(ImGuiContext* ctx);
    void          DockContextEndFrame(ImGuiContext* ctx);
    DockContextGenNodeID := ImGuiID(ImGuiContext* ctx);
    void          DockContextQueueDock(ImGuiContext* ctx, ImGuiWindow* target, ImGuiDockNode* target_node, ImGuiWindow* payload, ImGuiDir split_dir, f32 split_ratio, bool split_outer);
    void          DockContextQueueUndockWindow(ImGuiContext* ctx, ImGuiWindow* window);
    void          DockContextQueueUndockNode(ImGuiContext* ctx, ImGuiDockNode* node);
    void          DockContextProcessUndockWindow(ImGuiContext* ctx, ImGuiWindow* window, bool clear_persistent_docking_ref = true);
    void          DockContextProcessUndockNode(ImGuiContext* ctx, ImGuiDockNode* node);
    bool          DockContextCalcDropPosForDocking(ImGuiWindow* target, ImGuiDockNode* target_node, ImGuiWindow* payload_window, ImGuiDockNode* payload_node, ImGuiDir split_dir, bool split_outer, ImVec2* out_pos);
    ImGuiDockNode*DockContextFindNodeByID(ImGuiContext* ctx, ImGuiID id);
    void          DockNodeWindowMenuHandler_Default(ImGuiContext* ctx, ImGuiDockNode* node, ImGuiTabBar* tab_bar);
    bool          DockNodeBeginAmendTabBar(ImGuiDockNode* node);
    void          DockNodeEndAmendTabBar();
    inline ImGuiDockNode*   DockNodeGetRootNode(ImGuiDockNode* node)                 { for (node.ParentNode) node = node.ParentNode; return node; }
    inline bool             DockNodeIsInHierarchyOf(ImGuiDockNode* node, ImGuiDockNode* parent) { for (node) { if (node == parent) return true; node = node.ParentNode; } return false; }
    inline i32              DockNodeGetDepth(const ImGuiDockNode* node)              { i32 depth = 0; for (node.ParentNode) { node = node.ParentNode; depth += 1; } return depth; }
    inline ImGuiID          DockNodeGetWindowMenuButtonId(const ImGuiDockNode* node) { return ImHashStr("#COLLAPSE", 0, node.ID); }
    inline ImGuiDockNode*   GetWindowDockNode()                                      { ImGuiContext& g = *GImGui; return g.CurrentWindow.DockNode; }
    bool          GetWindowAlwaysWantOwnTabBar(ImGuiWindow* window);
    void          BeginDocked(ImGuiWindow* window, bool* p_open);
    void          BeginDockableDragDropSource(ImGuiWindow* window);
    void          BeginDockableDragDropTarget(ImGuiWindow* window);
    void          SetWindowDock(ImGuiWindow* window, ImGuiID dock_id, ImGuiCond cond);

    // Docking - Builder function needs to be generally called before the node is used/submitted.
    // - The DockBuilderXXX functions are designed to _eventually_ become a public API, but it is too early to expose it and guarantee stability.
    // - Do not hold on ImGuiDockNode* pointers! They may be invalidated by any split/merge/remove operation and every frame.
    // - To create a DockSpace() node, make sure to set the ImGuiDockNodeFlags_DockSpace flag when calling DockBuilderAddNode().
    //   You can create dockspace nodes (attached to a window) _or_ floating nodes (carry its own window) with this API.
    // - DockBuilderSplitNode() create 2 child nodes within 1 node. The initial node becomes a parent node.
    // - If you intend to split the node immediately after creation using DockBuilderSplitNode(), make sure
    //   to call DockBuilderSetNodeSize() beforehand. If you don't, the resulting split sizes may not be reliable.
    // - Call DockBuilderFinish() after you are done.
    void          DockBuilderDockWindow(const u8* window_name, ImGuiID node_id);
    ImGuiDockNode*DockBuilderGetNode(ImGuiID node_id);
    inline ImGuiDockNode*   DockBuilderGetCentralNode(ImGuiID node_id)              { ImGuiDockNode* node = DockBuilderGetNode(node_id); if (!node) return nil; return DockNodeGetRootNode(node)->CentralNode; }
    DockBuilderAddNode := ImGuiID(ImGuiID node_id = 0, ImGuiDockNodeFlags flags = 0);
    void          DockBuilderRemoveNode(ImGuiID node_id);                 // Remove node and all its child, undock all windows
    void          DockBuilderRemoveNodeDockedWindows(ImGuiID node_id, bool clear_settings_refs = true);
    void          DockBuilderRemoveNodeChildNodes(ImGuiID node_id);       // Remove all split/hierarchy. All remaining docked windows will be re-docked to the remaining root node (node_id).
    void          DockBuilderSetNodePos(ImGuiID node_id, ImVec2 pos);
    void          DockBuilderSetNodeSize(ImGuiID node_id, ImVec2 size);
    DockBuilderSplitNode := ImGuiID(ImGuiID node_id, ImGuiDir split_dir, f32 size_ratio_for_node_at_dir, ImGuiID* out_id_at_dir, ImGuiID* out_id_at_opposite_dir); // Create 2 child nodes in this parent node.
    void          DockBuilderCopyDockSpace(ImGuiID src_dockspace_id, ImGuiID dst_dockspace_id, ImVector<const u8*>* in_window_remap_pairs);
    void          DockBuilderCopyNode(ImGuiID src_node_id, ImGuiID dst_node_id, ImVector<ImGuiID>* out_node_remap_pairs);
    void          DockBuilderCopyWindowSettings(const u8* src_name, const u8* dst_name);
    void          DockBuilderFinish(ImGuiID node_id);

    // [EXPERIMENTAL] Focus Scope
    // This is generally used to identify a unique input location (for e.g. a selection set)
    // There is one per window (automatically set in Begin), but:
    // - Selection patterns generally need to react (e.g. clear a selection) when landing on one item of the set.
    //   So in order to identify a set multiple lists in same window may each need a focus scope.
    //   If you imagine an hypothetical BeginSelectionGroup()/EndSelectionGroup() api, it would likely call PushFocusScope()/EndFocusScope()
    // - Shortcut routing also use focus scope as a default location identifier if an owner is not provided.
    // We don't use the ID Stack for this as it is common to want them separate.
    void          PushFocusScope(ImGuiID id);
    void          PopFocusScope();
    inline ImGuiID          GetCurrentFocusScope() { ImGuiContext& g = *GImGui; return g.CurrentFocusScopeId; }   // Focus scope we are outputting into, set by PushFocusScope()

    // Drag and Drop
    bool          IsDragDropActive();
    bool          BeginDragDropTargetCustom(const ImRect& bb, ImGuiID id);
    void          ClearDragDrop();
    bool          IsDragDropPayloadBeingAccepted();
    void          RenderDragDropTargetRect(const ImRect& bb, const ImRect& item_clip_rect);

    // Typing-Select API
    // (provide Windows Explorer style "select items by typing partial name" + "cycle through items by typing same letter" feature)
    // (this is currently not documented nor used by main library, but should work. See "widgets_typingselect" in imgui_test_suite for usage code. Please let us know if you use this!)
    ImGuiTypingSelectRequest* GetTypingSelectRequest(ImGuiTypingSelectFlags flags = ImGuiTypingSelectFlags_None);
    i32           TypingSelectFindMatch(ImGuiTypingSelectRequest* req, i32 items_count, const u8* (*get_item_name_func)(rawptr, i32), rawptr user_data, i32 nav_item_idx);
    i32           TypingSelectFindNextSingleCharMatch(ImGuiTypingSelectRequest* req, i32 items_count, const u8* (*get_item_name_func)(rawptr, i32), rawptr user_data, i32 nav_item_idx);
    i32           TypingSelectFindBestLeadingMatch(ImGuiTypingSelectRequest* req, i32 items_count, const u8* (*get_item_name_func)(rawptr, i32), rawptr user_data);

    // Box-Select API
    bool          BeginBoxSelect(const ImRect& scope_rect, ImGuiWindow* window, ImGuiID box_select_id, ImGuiMultiSelectFlags ms_flags);
    void          EndBoxSelect(const ImRect& scope_rect, ImGuiMultiSelectFlags ms_flags);

    // Multi-Select API
    void          MultiSelectItemHeader(ImGuiID id, bool* p_selected, ImGuiButtonFlags* p_button_flags);
    void          MultiSelectItemFooter(ImGuiID id, bool* p_selected, bool* p_pressed);
    void          MultiSelectAddSetAll(ImGuiMultiSelectTempData* ms, bool selected);
    void          MultiSelectAddSetRange(ImGuiMultiSelectTempData* ms, bool selected, i32 range_dir, ImGuiSelectionUserData first_item, ImGuiSelectionUserData last_item);
    inline ImGuiBoxSelectState*     GetBoxSelectState(ImGuiID id)   { ImGuiContext& g = *GImGui; return (id != 0 && g.BoxSelectState.ID == id && g.BoxSelectState.IsActive) ? &g.BoxSelectState : nil; }
    inline ImGuiMultiSelectState*   GetMultiSelectState(ImGuiID id) { ImGuiContext& g = *GImGui; return g.MultiSelectStorage.GetByKey(id); }

    // Internal Columns API (this is not exposed because we will encourage transitioning to the Tables API)
    void          SetWindowClipRectBeforeSetChannel(ImGuiWindow* window, const ImRect& clip_rect);
    void          BeginColumns(const u8* str_id, i32 count, ImGuiOldColumnFlags flags = 0); // setup number of columns. use an identifier to distinguish multiple column sets. close with EndColumns().
    void          EndColumns();                                                               // close columns
    void          PushColumnClipRect(i32 column_index);
    void          PushColumnsBackground();
    void          PopColumnsBackground();
    GetColumnsID := ImGuiID(const u8* str_id, i32 count);
    ImGuiOldColumns* FindOrCreateColumns(ImGuiWindow* window, ImGuiID id);
    f32         GetColumnOffsetFromNorm(const ImGuiOldColumns* columns, f32 offset_norm);
    f32         GetColumnNormFromOffset(const ImGuiOldColumns* columns, f32 offset);

    // Tables: Candidates for public API
    void          TableOpenContextMenu(i32 column_n = -1);
    void          TableSetColumnWidth(i32 column_n, f32 width);
    void          TableSetColumnSortDirection(i32 column_n, ImGuiSortDirection sort_direction, bool append_to_sort_specs);
    i32           TableGetHoveredRow();       // Retrieve *PREVIOUS FRAME* hovered row. This difference with TableGetHoveredColumn() is the reason why this is not public yet.
    f32         TableGetHeaderRowHeight();
    f32         TableGetHeaderAngledMaxLabelWidth();
    void          TablePushBackgroundChannel();
    void          TablePopBackgroundChannel();
    void          TableAngledHeadersRowEx(ImGuiID row_id, f32 angle, f32 max_label_width, const ImGuiTableHeaderData* data, i32 data_count);

    // Tables: Internals
    inline    ImGuiTable*   GetCurrentTable() { ImGuiContext& g = *GImGui; return g.CurrentTable; }
    ImGuiTable*   TableFindByID(ImGuiID id);
    bool          BeginTableEx(const u8* name, ImGuiID id, i32 columns_count, ImGuiTableFlags flags = 0, const ImVec2& outer_size = ImVec2{0, 0}, f32 inner_width = 0.0);
    void          TableBeginInitMemory(ImGuiTable* table, i32 columns_count);
    void          TableBeginApplyRequests(ImGuiTable* table);
    void          TableSetupDrawChannels(ImGuiTable* table);
    void          TableUpdateLayout(ImGuiTable* table);
    void          TableUpdateBorders(ImGuiTable* table);
    void          TableUpdateColumnsWeightFromWidth(ImGuiTable* table);
    void          TableDrawBorders(ImGuiTable* table);
    void          TableDrawDefaultContextMenu(ImGuiTable* table, ImGuiTableFlags flags_for_section_to_display);
    bool          TableBeginContextMenuPopup(ImGuiTable* table);
    void          TableMergeDrawChannels(ImGuiTable* table);
    inline ImGuiTableInstanceData*  TableGetInstanceData(ImGuiTable* table, i32 instance_no) { if (instance_no == 0) return &table.InstanceDataFirst; return &table.InstanceDataExtra[instance_no - 1]; }
    inline ImGuiID                  TableGetInstanceID(ImGuiTable* table, i32 instance_no)   { return TableGetInstanceData(table, instance_no)->TableInstanceID; }
    void          TableSortSpecsSanitize(ImGuiTable* table);
    void          TableSortSpecsBuild(ImGuiTable* table);
    TableGetColumnNextSortDirection := ImGuiSortDirection(ImGuiTableColumn* column);
    void          TableFixColumnSortDirection(ImGuiTable* table, ImGuiTableColumn* column);
    f32         TableGetColumnWidthAuto(ImGuiTable* table, ImGuiTableColumn* column);
    void          TableBeginRow(ImGuiTable* table);
    void          TableEndRow(ImGuiTable* table);
    void          TableBeginCell(ImGuiTable* table, i32 column_n);
    void          TableEndCell(ImGuiTable* table);
    TableGetCellBgRect := ImRect(const ImGuiTable* table, i32 column_n);
    const u8*   TableGetColumnName(const ImGuiTable* table, i32 column_n);
    TableGetColumnResizeID := ImGuiID(ImGuiTable* table, i32 column_n, i32 instance_no = 0);
    f32         TableCalcMaxColumnWidth(const ImGuiTable* table, i32 column_n);
    void          TableSetColumnWidthAutoSingle(ImGuiTable* table, i32 column_n);
    void          TableSetColumnWidthAutoAll(ImGuiTable* table);
    void          TableRemove(ImGuiTable* table);
    void          TableGcCompactTransientBuffers(ImGuiTable* table);
    void          TableGcCompactTransientBuffers(ImGuiTableTempData* table);
    void          TableGcCompactSettings();

    // Tables: Settings
    void                  TableLoadSettings(ImGuiTable* table);
    void                  TableSaveSettings(ImGuiTable* table);
    void                  TableResetSettings(ImGuiTable* table);
    ImGuiTableSettings*   TableGetBoundSettings(ImGuiTable* table);
    void                  TableSettingsAddSettingsHandler();
    ImGuiTableSettings*   TableSettingsCreate(ImGuiID id, i32 columns_count);
    ImGuiTableSettings*   TableSettingsFindByID(ImGuiID id);

    // Tab Bars
    inline    ImGuiTabBar*  GetCurrentTabBar() { ImGuiContext& g = *GImGui; return g.CurrentTabBar; }
    bool          BeginTabBarEx(ImGuiTabBar* tab_bar, const ImRect& bb, ImGuiTabBarFlags flags);
    ImGuiTabItem* TabBarFindTabByID(ImGuiTabBar* tab_bar, ImGuiID tab_id);
    ImGuiTabItem* TabBarFindTabByOrder(ImGuiTabBar* tab_bar, i32 order);
    ImGuiTabItem* TabBarFindMostRecentlySelectedTabForActiveWindow(ImGuiTabBar* tab_bar);
    ImGuiTabItem* TabBarGetCurrentTab(ImGuiTabBar* tab_bar);
    inline i32              TabBarGetTabOrder(ImGuiTabBar* tab_bar, ImGuiTabItem* tab) { return tab_bar.Tabs.index_from_ptr(tab); }
    const u8*   TabBarGetTabName(ImGuiTabBar* tab_bar, ImGuiTabItem* tab);
    void          TabBarAddTab(ImGuiTabBar* tab_bar, ImGuiTabItemFlags tab_flags, ImGuiWindow* window);
    void          TabBarRemoveTab(ImGuiTabBar* tab_bar, ImGuiID tab_id);
    void          TabBarCloseTab(ImGuiTabBar* tab_bar, ImGuiTabItem* tab);
    void          TabBarQueueFocus(ImGuiTabBar* tab_bar, ImGuiTabItem* tab);
    void          TabBarQueueFocus(ImGuiTabBar* tab_bar, const u8* tab_name);
    void          TabBarQueueReorder(ImGuiTabBar* tab_bar, ImGuiTabItem* tab, i32 offset);
    void          TabBarQueueReorderFromMousePos(ImGuiTabBar* tab_bar, ImGuiTabItem* tab, ImVec2 mouse_pos);
    bool          TabBarProcessReorder(ImGuiTabBar* tab_bar);
    bool          TabItemEx(ImGuiTabBar* tab_bar, const u8* label, bool* p_open, ImGuiTabItemFlags flags, ImGuiWindow* docked_window);
    TabItemCalcSize := ImVec2{const u8* label, bool has_close_button_or_unsaved_marker};
    TabItemCalcSize := ImVec2{ImGuiWindow* window};
    void          TabItemBackground(ImDrawList* draw_list, const ImRect& bb, ImGuiTabItemFlags flags, u32 col);
    void          TabItemLabelAndCloseButton(ImDrawList* draw_list, const ImRect& bb, ImGuiTabItemFlags flags, ImVec2 frame_padding, const u8* label, ImGuiID tab_id, ImGuiID close_button_id, bool is_contents_visible, bool* out_just_closed, bool* out_text_clipped);

    // Render helpers
    // AVOID USING OUTSIDE OF IMGUI.CPP! NOT FOR PUBLIC CONSUMPTION. THOSE FUNCTIONS ARE A MESS. THEIR SIGNATURE AND BEHAVIOR WILL CHANGE, THEY NEED TO BE REFACTORED INTO SOMETHING DECENT.
    // NB: All position are in absolute pixels coordinates (we are never using window coordinates internally)
    void          RenderText(ImVec2 pos, const u8* text, const u8* text_end = nil, bool hide_text_after_hash = true);
    void          RenderTextWrapped(ImVec2 pos, const u8* text, const u8* text_end, f32 wrap_width);
    void          RenderTextClipped(const ImVec2& pos_min, const ImVec2& pos_max, const u8* text, const u8* text_end, const ImVec2* text_size_if_known, const ImVec2& align = ImVec2{0, 0}, const ImRect* clip_rect = nil);
    void          RenderTextClippedEx(ImDrawList* draw_list, const ImVec2& pos_min, const ImVec2& pos_max, const u8* text, const u8* text_end, const ImVec2* text_size_if_known, const ImVec2& align = ImVec2{0, 0}, const ImRect* clip_rect = nil);
    void          RenderTextEllipsis(ImDrawList* draw_list, const ImVec2& pos_min, const ImVec2& pos_max, f32 clip_max_x, f32 ellipsis_max_x, const u8* text, const u8* text_end, const ImVec2* text_size_if_known);
    void          RenderFrame(ImVec2 p_min, ImVec2 p_max, u32 fill_col, bool borders = true, f32 rounding = 0.0);
    void          RenderFrameBorder(ImVec2 p_min, ImVec2 p_max, f32 rounding = 0.0);
    void          RenderColorRectWithAlphaCheckerboard(ImDrawList* draw_list, ImVec2 p_min, ImVec2 p_max, u32 fill_col, f32 grid_step, ImVec2 grid_off, f32 rounding = 0.0, ImDrawFlags flags = 0);
    void          RenderNavCursor(const ImRect& bb, ImGuiID id, ImGuiNavRenderCursorFlags flags = ImGuiNavRenderCursorFlags_None); // Navigation highlight
    const u8*   FindRenderedTextEnd(const u8* text, const u8* text_end = nil); // Find the optional ## from which we stop displaying text.
    void          RenderMouseCursor(ImVec2 pos, f32 scale, ImGuiMouseCursor mouse_cursor, u32 col_fill, u32 col_border, u32 col_shadow);

    // Render helpers (those functions don't access any ImGui state!)
    void          RenderArrow(ImDrawList* draw_list, ImVec2 pos, u32 col, ImGuiDir dir, f32 scale = 1.0);
    void          RenderBullet(ImDrawList* draw_list, ImVec2 pos, u32 col);
    void          RenderCheckMark(ImDrawList* draw_list, ImVec2 pos, u32 col, f32 sz);
    void          RenderArrowPointingAt(ImDrawList* draw_list, ImVec2 pos, ImVec2 half_sz, ImGuiDir direction, u32 col);
    void          RenderArrowDockMenu(ImDrawList* draw_list, ImVec2 p_min, f32 sz, u32 col);
    void          RenderRectFilledRangeH(ImDrawList* draw_list, const ImRect& rect, u32 col, f32 x_start_norm, f32 x_end_norm, f32 rounding);
    void          RenderRectFilledWithHole(ImDrawList* draw_list, const ImRect& outer, const ImRect& inner, u32 col, f32 rounding);
    CalcRoundingFlagsForRectInRect := ImDrawFlags(const ImRect& r_in, const ImRect& r_outer, f32 threshold);

    // Widgets
    void          TextEx(const u8* text, const u8* text_end = nil, ImGuiTextFlags flags = 0);
    bool          ButtonEx(const u8* label, const ImVec2& size_arg = ImVec2{0, 0}, ImGuiButtonFlags flags = 0);
    bool          ArrowButtonEx(const u8* str_id, ImGuiDir dir, ImVec2 size_arg, ImGuiButtonFlags flags = 0);
    bool          ImageButtonEx(ImGuiID id, ImTextureID user_texture_id, const ImVec2& image_size, const ImVec2& uv0, const ImVec2& uv1, const ImVec4& bg_col, const ImVec4& tint_col, ImGuiButtonFlags flags = 0);
    void          SeparatorEx(ImGuiSeparatorFlags flags, f32 thickness = 1.0);
    void          SeparatorTextEx(ImGuiID id, const u8* label, const u8* label_end, f32 extra_width);
    bool          CheckboxFlags(const u8* label, i64* flags, i64 flags_value);
    bool          CheckboxFlags(const u8* label, u64* flags, u64 flags_value);

    // Widgets: Window Decorations
    bool          CloseButton(ImGuiID id, const ImVec2& pos);
    bool          CollapseButton(ImGuiID id, const ImVec2& pos, ImGuiDockNode* dock_node);
    void          Scrollbar(ImGuiAxis axis);
    bool          ScrollbarEx(const ImRect& bb, ImGuiID id, ImGuiAxis axis, i64* p_scroll_v, i64 avail_v, i64 contents_v, ImDrawFlags draw_rounding_flags = 0);
    GetWindowScrollbarRect := ImRect(ImGuiWindow* window, ImGuiAxis axis);
    GetWindowScrollbarID := ImGuiID(ImGuiWindow* window, ImGuiAxis axis);
    GetWindowResizeCornerID := ImGuiID(ImGuiWindow* window, i32 n); // 0..3: corners
    GetWindowResizeBorderID := ImGuiID(ImGuiWindow* window, ImGuiDir dir);

    // Widgets low-level behaviors
    bool          ButtonBehavior(const ImRect& bb, ImGuiID id, bool* out_hovered, bool* out_held, ImGuiButtonFlags flags = 0);
    bool          DragBehavior(ImGuiID id, ImGuiDataType data_type, rawptr p_v, f32 v_speed, const rawptr p_min, const rawptr p_max, const u8* format, ImGuiSliderFlags flags);
    bool          SliderBehavior(const ImRect& bb, ImGuiID id, ImGuiDataType data_type, rawptr p_v, const rawptr p_min, const rawptr p_max, const u8* format, ImGuiSliderFlags flags, ImRect* out_grab_bb);
    bool          SplitterBehavior(const ImRect& bb, ImGuiID id, ImGuiAxis axis, f32* size1, f32* size2, f32 min_size1, f32 min_size2, f32 hover_extend = 0.0, f32 hover_visibility_delay = 0.0, u32 bg_col = 0);

    // Widgets: Tree Nodes
    bool          TreeNodeBehavior(ImGuiID id, ImGuiTreeNodeFlags flags, const u8* label, const u8* label_end = nil);
    void          TreePushOverrideID(ImGuiID id);
    bool          TreeNodeGetOpen(ImGuiID storage_id);
    void          TreeNodeSetOpen(ImGuiID storage_id, bool open);
    bool          TreeNodeUpdateNextOpen(ImGuiID storage_id, ImGuiTreeNodeFlags flags);   // Return open state. Consume previous SetNextItemOpen() data, if any. May return true when logging.

    // Template functions are instantiated in imgui_widgets.cpp for a finite number of types.
    // To use them externally (for custom widget) you may need an "extern template" statement in your code in order to link to existing instances and silence Clang warnings (see #2036).
    // e.g. " extern template IMGUI_API float RoundScalarWithFormatT<float, float>(const char* format, ImGuiDataType data_type, float v); "
    template<typename T, typename SIGNED_T, typename FLOAT_T>   f32 ScaleRatioFromValueT(ImGuiDataType data_type, T v, T v_min, T v_max, bool is_logarithmic, f32 logarithmic_zero_epsilon, f32 zero_deadzone_size);
    template<typename T, typename SIGNED_T, typename FLOAT_T>   T     ScaleValueFromRatioT(ImGuiDataType data_type, f32 t, T v_min, T v_max, bool is_logarithmic, f32 logarithmic_zero_epsilon, f32 zero_deadzone_size);
    template<typename T, typename SIGNED_T, typename FLOAT_T>   bool  DragBehaviorT(ImGuiDataType data_type, T* v, f32 v_speed, T v_min, T v_max, const u8* format, ImGuiSliderFlags flags);
    template<typename T, typename SIGNED_T, typename FLOAT_T>   bool  SliderBehaviorT(const ImRect& bb, ImGuiID id, ImGuiDataType data_type, T* v, T v_min, T v_max, const u8* format, ImGuiSliderFlags flags, ImRect* out_grab_bb);
    template<typename T>                                        T     RoundScalarWithFormatT(const u8* format, ImGuiDataType data_type, T v);
    template<typename T>                                        bool  CheckboxFlagsT(const u8* label, T* flags, T flags_value);

    // Data type helpers
    const ImGuiDataTypeInfo*  DataTypeGetInfo(ImGuiDataType data_type);
    i32           DataTypeFormatString(u8* buf, i32 buf_size, ImGuiDataType data_type, const rawptr p_data, const u8* format);
    void          DataTypeApplyOp(ImGuiDataType data_type, i32 op, rawptr output, const rawptr arg_1, const rawptr arg_2);
    bool          DataTypeApplyFromText(const u8* buf, ImGuiDataType data_type, rawptr p_data, const u8* format, rawptr p_data_when_empty = nil);
    i32           DataTypeCompare(ImGuiDataType data_type, const rawptr arg_1, const rawptr arg_2);
    bool          DataTypeClamp(ImGuiDataType data_type, rawptr p_data, const rawptr p_min, const rawptr p_max);
    bool          DataTypeIsZero(ImGuiDataType data_type, const rawptr p_data);

    // InputText
    bool          InputTextEx(const u8* label, const u8* hint, u8* buf, i32 buf_size, const ImVec2& size_arg, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback = nil, rawptr user_data = nil);
    void          InputTextDeactivateHook(ImGuiID id);
    bool          TempInputText(const ImRect& bb, ImGuiID id, const u8* label, u8* buf, i32 buf_size, ImGuiInputTextFlags flags);
    bool          TempInputScalar(const ImRect& bb, ImGuiID id, const u8* label, ImGuiDataType data_type, rawptr p_data, const u8* format, const rawptr p_clamp_min = nil, const rawptr p_clamp_max = nil);
    inline bool             TempInputIsActive(ImGuiID id)       { ImGuiContext& g = *GImGui; return (g.ActiveId == id && g.TempInputId == id); }
    inline ImGuiInputTextState* GetInputTextState(ImGuiID id)   { ImGuiContext& g = *GImGui; return (id != 0 && g.InputTextState.ID == id) ? &g.InputTextState : nil; } // Get input text state if active
    void          SetNextItemRefVal(ImGuiDataType data_type, rawptr p_data);

    // Color
    void          ColorTooltip(const u8* text, const f32* col, ImGuiColorEditFlags flags);
    void          ColorEditOptionsPopup(const f32* col, ImGuiColorEditFlags flags);
    void          ColorPickerOptionsPopup(const f32* ref_col, ImGuiColorEditFlags flags);

    // Plot
    i32           PlotEx(ImGuiPlotType plot_type, const u8* label, f32 (*values_getter)(rawptr data, i32 idx), rawptr data, i32 values_count, i32 values_offset, const u8* overlay_text, f32 scale_min, f32 scale_max, const ImVec2& size_arg);

    // Shade functions (write over already created vertices)
    void          ShadeVertsLinearColorGradientKeepAlpha(ImDrawList* draw_list, i32 vert_start_idx, i32 vert_end_idx, ImVec2 gradient_p0, ImVec2 gradient_p1, u32 col0, u32 col1);
    void          ShadeVertsLinearUV(ImDrawList* draw_list, i32 vert_start_idx, i32 vert_end_idx, const ImVec2& a, const ImVec2& b, const ImVec2& uv_a, const ImVec2& uv_b, bool clamp);
    void          ShadeVertsTransformPos(ImDrawList* draw_list, i32 vert_start_idx, i32 vert_end_idx, const ImVec2& pivot_in, f32 cos_a, f32 sin_a, const ImVec2& pivot_out);

    // Garbage collection
    void          GcCompactTransientMiscBuffers();
    void          GcCompactTransientWindowBuffers(ImGuiWindow* window);
    void          GcAwakeTransientWindowBuffers(ImGuiWindow* window);

    // Error handling, State Recovery
    bool          ErrorLog(const u8* msg);
    void          ErrorRecoveryStoreState(ImGuiErrorRecoveryState* state_out);
    void          ErrorRecoveryTryToRecoverState(const ImGuiErrorRecoveryState* state_in);
    void          ErrorRecoveryTryToRecoverWindowState(const ImGuiErrorRecoveryState* state_in);
    void          ErrorCheckUsingSetCursorPosToExtendParentBoundaries();
    void          ErrorCheckEndFrameFinalizeErrorTooltip();
    bool          BeginErrorTooltip();
    void          EndErrorTooltip();

    // Debug Tools
    void          DebugAllocHook(ImGuiDebugAllocInfo* info, i32 frame_count, rawptr ptr, int size); // size >= 0 : alloc, size = -1 : free
    void          DebugDrawCursorPos(u32 col = IM_COL32(255, 0, 0, 255));
    void          DebugDrawLineExtents(u32 col = IM_COL32(255, 0, 0, 255));
    void          DebugDrawItemRect(u32 col = IM_COL32(255, 0, 0, 255));
    void          DebugTextUnformattedWithLocateItem(const u8* line_begin, const u8* line_end);
    void          DebugLocateItem(ImGuiID target_id);                     // Call sparingly: only 1 at the same time!
    void          DebugLocateItemOnHover(ImGuiID target_id);              // Only call on reaction to a mouse Hover: because only 1 at the same time!
    void          DebugLocateItemResolveWithLastItem();
    void          DebugBreakClearData();
    bool          DebugBreakButton(const u8* label, const u8* description_of_location);
    void          DebugBreakButtonTooltip(bool keyboard_only, const u8* description_of_location);
    void          ShowFontAtlas(ImFontAtlas* atlas);
    void          DebugHookIdInfo(ImGuiID id, ImGuiDataType data_type, const rawptr data_id, const rawptr data_id_end);
    void          DebugNodeColumns(ImGuiOldColumns* columns);
    void          DebugNodeDockNode(ImGuiDockNode* node, const u8* label);
    void          DebugNodeDrawList(ImGuiWindow* window, ImGuiViewportP* viewport, const ImDrawList* draw_list, const u8* label);
    void          DebugNodeDrawCmdShowMeshAndBoundingBox(ImDrawList* out_draw_list, const ImDrawList* draw_list, const ImDrawCmd* draw_cmd, bool show_mesh, bool show_aabb);
    void          DebugNodeFont(ImFont* font);
    void          DebugNodeFontGlyph(ImFont* font, const ImFontGlyph* glyph);
    void          DebugNodeStorage(ImGuiStorage* storage, const u8* label);
    void          DebugNodeTabBar(ImGuiTabBar* tab_bar, const u8* label);
    void          DebugNodeTable(ImGuiTable* table);
    void          DebugNodeTableSettings(ImGuiTableSettings* settings);
    void          DebugNodeInputTextState(ImGuiInputTextState* state);
    void          DebugNodeTypingSelectState(ImGuiTypingSelectState* state);
    void          DebugNodeMultiSelectState(ImGuiMultiSelectState* state);
    void          DebugNodeWindow(ImGuiWindow* window, const u8* label);
    void          DebugNodeWindowSettings(ImGuiWindowSettings* settings);
    void          DebugNodeWindowsList(ImVector<ImGuiWindow*>* windows, const u8* label);
    void          DebugNodeWindowsListByBeginStackParent(ImGuiWindow** windows, i32 windows_size, ImGuiWindow* parent_in_begin_stack);
    void          DebugNodeViewport(ImGuiViewportP* viewport);
    void          DebugNodePlatformMonitor(ImGuiPlatformMonitor* monitor, const u8* label, i32 idx);
    void          DebugRenderKeyboardPreview(ImDrawList* draw_list);
    void          DebugRenderViewportThumbnail(ImDrawList* draw_list, ImGuiViewportP* viewport, const ImRect& bb);

    // Obsolete functions

} // namespace ImGui


//-----------------------------------------------------------------------------
// [SECTION] ImFontAtlas internal API
//-----------------------------------------------------------------------------

// This structure is likely to evolve as we add support for incremental atlas updates.
// Conceptually this could be in ImGuiPlatformIO, but we are far from ready to make this public.
ImFontBuilderIO :: struct
{
    bool    (*FontBuilder_Build)(ImFontAtlas* atlas);
};

// Helper for font builder
when IMGUI_ENABLE_STB_TRUETYPE {
const ImFontBuilderIO* ImFontAtlasGetBuilderForStbTruetype();
}
void      ImFontAtlasUpdateConfigDataPointers(ImFontAtlas* atlas);
void      ImFontAtlasBuildInit(ImFontAtlas* atlas);
void      ImFontAtlasBuildSetupFont(ImFontAtlas* atlas, ImFont* font, ImFontConfig* font_config, f32 ascent, f32 descent);
void      ImFontAtlasBuildPackCustomRects(ImFontAtlas* atlas, rawptr stbrp_context_opaque);
void      ImFontAtlasBuildFinish(ImFontAtlas* atlas);
void      ImFontAtlasBuildRender8bppRectFromString(ImFontAtlas* atlas, i32 x, i32 y, i32 w, i32 h, const u8* in_str, u8 in_marker_char, u8 in_marker_pixel_value);
void      ImFontAtlasBuildRender32bppRectFromString(ImFontAtlas* atlas, i32 x, i32 y, i32 w, i32 h, const u8* in_str, u8 in_marker_char, u32 in_marker_pixel_value);
void      ImFontAtlasBuildMultiplyCalcLookupTable(u8 out_table[256], f32 in_multiply_factor);
void      ImFontAtlasBuildMultiplyRectAlpha8(const u8 table[256], u8* pixels, i32 x, i32 y, i32 w, i32 h, i32 stride);

//-----------------------------------------------------------------------------
// [SECTION] Test Engine specific hooks (imgui_test_engine)
//-----------------------------------------------------------------------------

when IMGUI_ENABLE_TEST_ENGINE {
extern void         ImGuiTestEngineHook_ItemAdd(ImGuiContext* ctx, ImGuiID id, const ImRect& bb, const ImGuiLastItemData* item_data);           // item_data may be NULL
extern void         ImGuiTestEngineHook_ItemInfo(ImGuiContext* ctx, ImGuiID id, const u8* label, ImGuiItemStatusFlags flags);
extern void         ImGuiTestEngineHook_Log(ImGuiContext* ctx, const u8* fmt, ...);
extern const u8*  ImGuiTestEngine_FindItemDebugLabel(ImGuiContext* ctx, ImGuiID id);

// In IMGUI_VERSION_NUM >= 18934: changed IMGUI_TEST_ENGINE_ITEM_ADD(bb,id) to IMGUI_TEST_ENGINE_ITEM_ADD(id,bb,item_data);
#define IMGUI_TEST_ENGINE_ITEM_ADD(_ID,_BB,_ITEM_DATA)      if (g.TestEngineHookItems) ImGuiTestEngineHook_ItemAdd(&g, _ID, _BB, _ITEM_DATA)    // Register item bounding box
#define IMGUI_TEST_ENGINE_ITEM_INFO(_ID,_LABEL,_FLAGS)      if (g.TestEngineHookItems) ImGuiTestEngineHook_ItemInfo(&g, _ID, _LABEL, _FLAGS)    // Register item label and status flags (optional)
#define IMGUI_TEST_ENGINE_LOG(_FMT,...)                     ImGuiTestEngineHook_Log(&g, _FMT, __VA_ARGS__)                                      // Custom log entry from user land into test log
} else {
#define IMGUI_TEST_ENGINE_ITEM_ADD(_BB,_ID)                 ((void)0)
#define IMGUI_TEST_ENGINE_ITEM_INFO(_ID,_LABEL,_FLAGS)      ((void)g)
}

//-----------------------------------------------------------------------------


when _MSC_VER {
}

} // #ifndef IMGUI_DISABLE
