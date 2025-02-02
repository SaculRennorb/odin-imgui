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

import "base:builtin"
import "base:intrinsics"
import "base:runtime"
import "core:math"
import "core:math/linalg"
import "core:fmt"
import "core:mem"
import "core:slice"
import "core:os"

// Enable SSE intrinsics if available
IMGUI_ENABLE_SSE :: intrinsics.has_target_feature("sse");
IMGUI_ENABLE_SSE4_2 :: true//intrinsics.has_target_feature("avx") || intrinsics.has_target_feature("sse4.2"); //TODO(Rennorb)

//NOTE(Rennorb): no access to the instructions afaict
IMGUI_ENABLE_SSE4_2_CRC :: false //IMGUI_ENABLE_SSE4_2 && !IMGUI_USE_LEGACY_CRC32_ADLER && ODIN_OS != .JS;


// Internal Drag and Drop payload types. String starting with '_' are reserved for Dear ImGui.
IMGUI_PAYLOAD_TYPE_WINDOW :: "_IMWINDOW"     // Payload == ImGuiWindow*

// Debug Printing Into TTY
when !IMGUI_DISABLE_DEFAULT_FORMAT_FUNCTIONS {
    IMGUI_DEBUG_PRINTF :: fmt.printf
} else {
    IMGUI_DEBUG_PRINTF :: proc(_FMT : string, args : ..any) {}
}

// Debug Logging for ShowDebugLogWindow(). This is designed for relatively rare events so please don't spam.
IMGUI_DEBUG_LOG_ERROR        :: #force_inline proc(g : ^ImGuiContext, args : ..any) { g2 := GImGui; if (.EventError in g2.DebugLogFlags) do IMGUI_DEBUG_LOG((cast(^string)args[0].data)^, args[1:]); else do g2.DebugLogSkippedErrors += 1; }
IMGUI_DEBUG_LOG_ACTIVEID     :: #force_inline proc(g : ^ImGuiContext, args : ..any) { if (.EventActiveId     in g.DebugLogFlags)  do IMGUI_DEBUG_LOG((cast(^string)args[0].data)^, args[1:]); }
IMGUI_DEBUG_LOG_FOCUS        :: #force_inline proc(g : ^ImGuiContext, args : ..any) { if (.EventFocus        in g.DebugLogFlags)  do IMGUI_DEBUG_LOG((cast(^string)args[0].data)^, args[1:]); }
IMGUI_DEBUG_LOG_POPUP        :: #force_inline proc(g : ^ImGuiContext, args : ..any) { if (.EventPopup        in g.DebugLogFlags)  do IMGUI_DEBUG_LOG((cast(^string)args[0].data)^, args[1:]); }
IMGUI_DEBUG_LOG_NAV          :: #force_inline proc(g : ^ImGuiContext, args : ..any) { if (.EventNav          in g.DebugLogFlags)  do IMGUI_DEBUG_LOG((cast(^string)args[0].data)^, args[1:]); }
IMGUI_DEBUG_LOG_SELECTION    :: #force_inline proc(g : ^ImGuiContext, args : ..any) { if (.EventSelection    in g.DebugLogFlags)  do IMGUI_DEBUG_LOG((cast(^string)args[0].data)^, args[1:]); }
IMGUI_DEBUG_LOG_CLIPPER      :: #force_inline proc(g : ^ImGuiContext, args : ..any) { if (.EventClipper      in g.DebugLogFlags)  do IMGUI_DEBUG_LOG((cast(^string)args[0].data)^, args[1:]); }
IMGUI_DEBUG_LOG_IO           :: #force_inline proc(g : ^ImGuiContext, args : ..any) { if (.EventIO           in g.DebugLogFlags)  do IMGUI_DEBUG_LOG((cast(^string)args[0].data)^, args[1:]); }
IMGUI_DEBUG_LOG_FONT         :: #force_inline proc(g : ^ImGuiContext, args : ..any) { if (.EventFont         in g.DebugLogFlags)  do IMGUI_DEBUG_LOG((cast(^string)args[0].data)^, args[1:]); }
IMGUI_DEBUG_LOG_INPUTROUTING :: #force_inline proc(g : ^ImGuiContext, args : ..any) { if (.EventInputRouting in g.DebugLogFlags)  do IMGUI_DEBUG_LOG((cast(^string)args[0].data)^, args[1:]); }
IMGUI_DEBUG_LOG_DOCKING      :: #force_inline proc(g : ^ImGuiContext, args : ..any) { if (.EventDocking      in g.DebugLogFlags)  do IMGUI_DEBUG_LOG((cast(^string)args[0].data)^, args[1:]); }
IMGUI_DEBUG_LOG_VIEWPORT     :: #force_inline proc(g : ^ImGuiContext, args : ..any) { if (.EventViewport     in g.DebugLogFlags)  do IMGUI_DEBUG_LOG((cast(^string)args[0].data)^, args[1:]); }

// Static Asserts

// "Paranoid" Debug Asserts are meant to only be enabled during specific debugging/work, otherwise would slow down the code too much.
// We currently don't have many of those so the effect is currently negligible, but onward intent to add more aggressive ones in the code.
IM_ASSERT_PARANOID :: #force_inline proc(_EXPR : bool, loc := #caller_location) {
    when IMGUI_DEBUG_PARANOID {
        assert(_EXPR)
    }
}

// Misc Macros
IM_PI :: math.PI
IM_NEWLINE :: "\n"

IM_TABSIZE :: 4

IM_F32_TO_INT8_UNBOUND :: #force_inline proc(_VAL : f32) -> int { return  (int((_VAL) * 255.0 + ((_VAL)>=0 ? 0.5 : -0.5))) }  // Unsaturated, for display purpose
IM_F32_TO_INT8_SAT :: #force_inline proc(_VAL : f32)     -> int { return      (int(ImSaturate(_VAL) * 255.0 + 0.5))            }   // Saturated, always output 0..255

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

ImFileHandle :: os.Handle

// Helpers: Sorting
ImQsort :: #force_inline proc(base : [^]$T, count : int, size_of_element : int, compare_func : proc(^T, ^T) -> i32)
{
    quick_sort_proc(base[:count], compare_func)
}


quick_sort_proc :: proc(array: $A/[]$T, f: proc(^T, ^T) -> i32) {
	assert(f != nil)
	a := array
	n := len(a)
	if n < 2 {
		return
	}

	p := a[n/2]
	i, j := 0, n-1

	loop: for {
		for f(&a[i], &p) < 0 { i += 1 }
		for f(&p, &a[j]) < 0 { j -= 1 }

		if i >= j {
			break loop
		}

		a[i], a[j] = a[j], a[i]
		i += 1
		j -= 1
	}

	quick_sort_proc(a[0:i], f)
	quick_sort_proc(a[i:n], f)
}




// Helpers: Bit manipulation
ImUpperPowerOfTwo :: #force_inline proc(v : int) -> int {
    v := v
    v -= 1; v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16; v += 1;
    return v;
}

// Helpers: String
ImToUpper       :: #force_inline proc(c : u8)  -> u8   { return (c >= 'a' && c <= 'z') ? c & ~u8(32) : c; }
ImCharIsBlankA  :: #force_inline proc(c : u8)  -> bool { return c == ' ' || c == '\t'; }
ImCharIsBlankW  :: #force_inline proc(c : u32) -> bool { return c == ' ' || c == '\t' || c == 0x3000; }
ImCharIsXdigitA ::  #force_inline proc(c : u8) -> bool { return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f'); }

// (Exceptionally using templates here but we could also redefine them for those types)
ImSwap :: #force_inline proc(a, b : ^$T)                      { tmp := a^; a^ = b^; b^ = tmp; }
ImAddClampOverflow :: #force_inline proc(a, b, mn, mx : $T) -> T   { if (b < 0 && (a < mn - b)) do return mn; if (b > 0 && (a > mx - b)) do return mx; return a + b; }
ImSubClampOverflow :: #force_inline proc(a, b, mn, mx : $T) -> T   { if (b > 0 && (a < mn + b)) do return mn; if (b < 0 && (a > mx + b)) do return mx; return a - b; }
// - Misc maths helpers
ImCeil :: math.ceil
ImAcos :: math.acos
ImAbs :: math.abs
ImMin :: linalg.min_double
ImMax :: linalg.max_double
ImClamp :: linalg.clamp
ImLerp :: math.lerp
ImSaturate :: math.saturate
ImLengthSqr :: linalg.length2
ImFmod :: #force_inline proc(x, y : f32) -> f32 { return x - ImTrunc(x / y) * y; }
ImInvLength :: #force_inline proc(lhs : ImVec2, fail_value : f32) -> f32 {
    d := linalg.length2(lhs);
    return d > 0.0 ? linalg.inverse_sqrt(d) : fail_value;
}
ImTrunc_v2 :: proc(#no_broadcast v : ImVec2) -> ImVec2 { return { math.trunc(v.x), math.trunc(v.y) } }
ImTrunc :: proc { math.trunc_f32, ImTrunc_v2 }
ImFloor_v2 :: proc(#no_broadcast v : ImVec2) -> ImVec2 { return { math.floor(v.x), math.floor(v.y) } }
ImFloor :: proc { math.floor_f32, ImFloor_v2 }
ImModPositive :: #force_inline proc(a, b : $T) -> T  { return (a + b) % b; }
ImDot :: linalg.dot
ImRotate :: #force_inline proc(v : ImVec2, cos_a, sin_a : f32) -> ImVec2        { return ImVec2{v.x * cos_a - v.y * sin_a, v.x * sin_a + v.y * cos_a}; }
ImLinearSweep :: #force_inline proc(current, target, speed : f32) -> f32    { if (current < target) do return ImMin(current + speed, target); if (current > target) do return ImMax(current - speed, target); return current; }
ImLinearRemapClamp :: #force_inline proc(s0, s1, d0, d1, x : f32) -> f32 { return ImSaturate((x - s0) / (s1 - s0)) * (d1 - d0) + d0; }
ImMul :: #force_inline proc(a, b : $T) -> T where intrinsics.type_is_array(T) { return a * b }
ImIsFloatAboveGuaranteedIntegerPrecision :: #force_inline proc(f : f32) -> bool          { return f <= -16777216 || f >= 16777216; }
ImExponentialMovingAverage :: #force_inline proc(avg, sample : f32, n : int) -> f32 { avg := avg; avg -= avg / f32(n); avg += sample / f32(n); return avg; }

// Helpers: Geometry
ImTriangleArea :: #force_inline proc(a, b, c : ImVec2) -> f32          { return ImAbs((a.x * (b.y - c.y)) + (b.x * (c.y - a.y)) + (c.x * (a.y - b.y))) * 0.5; }
ImTriangleIsClockwise :: #force_inline proc(a, b, c : ImVec2) -> bool   { return ((b.x - a.x) * (c.y - b.y)) - ((c.x - b.x) * (b.y - a.y)) > 0.0; }

// Helper: ImVec1 (1D vector)
// (this odd construct is used to facilitate the transition between 1D and 2D, and the maintenance of some branches/patches)
ImVec1 :: [1]f32

// Helper: ImVec2ih (2D vector, half-size integer, for long-term packed storage)
ImVec2ih :: [2]i16

// Important: never called automatically! 
clear_destruct :: #force_inline proc(v : ^[dynamic]$T)
{
    for &e in v {
        __destructors(&e)
    }
    clear(v)
}

empty_v :: #force_inline proc(v : []$T) -> bool { return len(v) == 0; }
empty_d :: #force_inline proc(v : [dynamic]$T) -> bool { return len(v) == 0; }

swap_d :: proc (v1, v2 : ^[dynamic]$T) {
    raw1 := transmute(^runtime.Raw_Dynamic_Array)v1
    raw2 := transmute(^runtime.Raw_Dynamic_Array)v2

    ImSwap(&raw1.cap, &raw2.cap)
    ImSwap(&raw1.len, &raw2.len)
    ImSwap(&raw1.data, &raw2.data)
}

// Important: never called automatically! 
clear_delete :: #force_inline proc(v : ^[dynamic]$T)
{
    for &e in v {
        IM_DELETE(e);
    }
    clear(v);
}

erase :: #force_inline proc(this : ^[dynamic]$T, it : ^T) -> ^T
{
    raw := transmute(^runtime.Raw_Dynamic_Array) this;
    data := cast(^T) raw.data
    assert(it >= data && it < mem.ptr_offset(data, len(this)));
    off := mem.ptr_sub(it, data);
    memmove(it, mem.ptr_offset(it, 1), (len(this) - off) * size_of(T));
    raw.len -= 1;
    return it
}

find_erase :: #force_inline proc(this : ^[dynamic]$T, v : ^T) -> bool
{
    it := &this[0];
    for (it < end(this^)) {
        if it == v {
            erase(this, v);
            return true
        }
    }
    return false;
}

shrink_to :: #force_inline proc(this : ^[dynamic]$T, #any_int new_size : int)
{
    raw := transmute(^runtime.Raw_Dynamic_Array) this;
    raw.len = new_size
}

shrink_by :: #force_inline proc(this : ^[dynamic]$T, #any_int shrink_amount : int)
{
    raw := transmute(^runtime.Raw_Dynamic_Array) this;
    raw.len -= shrink_amount
}

reserve_discard :: #force_inline proc(this : ^[dynamic]$T, #any_int new_capacity : int)
{
    if (new_capacity <= cap(this)) do return;
    clear(this)
    reserve(this, new_capacity)
}

resize_fill :: proc(this : ^[dynamic]$T, #any_int new_size : int, fill : T)
{
    old_size := len(this)
    non_zero_resize_dynamic_array(this, new_size)
    for &e in this[old_size:] {
        e = fill
    }
}

// inserts an element before "before"
insert :: proc (this : ^[dynamic]$T, before : ^T, el : T) -> (inserted : ^T, err: runtime.Allocator_Error) #no_bounds_check #optional_allocator_error
{
    assert(before <= end(this^))
    index := mem.ptr_sub(before, cast(^T) raw_data(this^))

    resize(this, len(this) + 1) or_return  //TODO @perf

    copy(this[index + 1:], this[index:])
    this[index] = el
    return &this[index], nil
}

index_from_ptr :: #force_inline proc(this : $S/[]$T, ptr : ^T) -> i32
{
    return cast(i32) mem.ptr_sub(ptr, cast(^T) raw_data(this^))
}



// Helper: ImRect (2D axis aligned bounding-box)
// NB: we can't rely on ImVec2 math operators being available here!
ImRect :: struct #raw_union {
    using _r : ImVec4,
    using _v : _ImRect2
};
_ImRect2 :: struct
{
    Min : ImVec2,    // Upper-left
    Max : ImVec2,    // Lower-right
};

GetCenter_r :: proc(this : ImRect)                                -> ImVec2 { return ImVec2{(this.Min.x + this.Max.x) * 0.5, (this.Min.y + this.Max.y) * 0.5}; }
GetCenter :: proc { GetCenter_r, GetCenter_v }
GetSize :: proc(this : ImRect)                                   -> ImVec2 { return ImVec2{this.Max.x - this.Min.x, this.Max.y - this.Min.y}; }
GetWidth :: proc(this : ImRect)                                  -> f32    { return this.Max.x - this.Min.x; }
GetHeight :: proc(this : ImRect)                                -> f32    { return this.Max.y - this.Min.y; }
GetArea :: proc(this : ImRect)                                  -> f32    { return (this.Max.x - this.Min.x) * (this.Max.y - this.Min.y); }
GetTL :: proc(this : ImRect)                                    -> ImVec2 { return this.Min; }                   // Top-left
GetTR :: proc(this : ImRect)                                    -> ImVec2 { return ImVec2{this.Max.x, this.Min.y}; }  // Top-right
GetBL :: proc(this : ImRect)                                    -> ImVec2 { return ImVec2{this.Min.x, this.Max.y}; }  // Bottom-left
GetBR :: proc(this : ImRect)                                    -> ImVec2 { return this.Max; }                   // Bottom-right
Contains_p :: proc(this : ImRect, p : ImVec2)                     -> bool   { return p.x     >= this.Min.x && p.y     >= this.Min.y && p.x     <  this.Max.x && p.y     <  this.Max.y; }
Contains_r :: proc(this : ImRect, r : ImRect)                     -> bool   { return r.Min.x >= this.Min.x && r.Min.y >= this.Min.y && r.Max.x <= this.Max.x && r.Max.y <= this.Max.y; }
Contains :: proc { Contains_p, Contains_r, Contains_pool, Contains_sbs }
ContainsWithPad :: proc(this : ImRect, p : ImVec2, pad : ImVec2)-> bool   { return p.x >= this.Min.x - pad.x && p.y >= this.Min.y - pad.y && p.x < this.Max.x + pad.x && p.y < this.Max.y + pad.y; }
Overlaps :: proc(this : ImRect, r : ImRect)                     -> bool   { return r.Min.y <  this.Max.y && r.Max.y >  this.Min.y && r.Min.x <  this.Max.x && r.Max.x >  this.Min.x; }
Add_p :: proc(this : ^ImRect, p : ImVec2)                                    { if (this.Min.x > p.x)     do this.Min.x = p.x;     if (this.Min.y > p.y)     do this.Min.y = p.y;     if (this.Max.x < p.x)     do this.Max.x = p.x;     if (this.Max.y < p.y)     do this.Max.y = p.y; }
Add_r :: proc(this : ^ImRect, r : ImRect)                                    { if (this.Min.x > r.Min.x) do this.Min.x = r.Min.x; if (this.Min.y > r.Min.y) do this.Min.y = r.Min.y; if (this.Max.x < r.Max.x) do this.Max.x = r.Max.x; if (this.Max.y < r.Max.y) do this.Max.y = r.Max.y; }
Add :: proc{ Add_p, Add_r, Add_pool }
Expand_f :: proc(this : ^ImRect, amount : f32)                               { this.Min.x -= amount;   this.Min.y -= amount;   this.Max.x += amount;   this.Max.y += amount; }
Expand_v :: proc(this : ^ImRect, amount : ImVec2)                            { this.Min.x -= amount.x; this.Min.y -= amount.y; this.Max.x += amount.x; this.Max.y += amount.y; }
Expand :: proc { Expand_f, Expand_v }
Translate :: proc(this : ^ImRect, d : ImVec2)                              { this.Min.x += d.x; this.Min.y += d.y; this.Max.x += d.x; this.Max.y += d.y; }
TranslateX :: proc(this : ^ImRect, dx : f32)                               { this.Min.x += dx; this.Max.x += dx; }
TranslateY :: proc(this : ^ImRect, dy : f32)                               { this.Min.y += dy; this.Max.y += dy; }
ClipWith :: proc(this : ^ImRect, r : ImRect)                               { this.Min = ImMax(this.Min, r.Min); this.Max = ImMin(this.Max, r.Max); }                   // Simple version, may lead to an inverted rectangle, which is fine for Contains/Overlaps test but not for display.
ClipWithFull :: proc(this : ^ImRect, r : ImRect)                           { this.Min = ImClamp(this.Min, r.Min, r.Max); this.Max = ImClamp(this.Max, r.Min, r.Max); } // Full version, ensure both points are fully clipped.
Floor :: proc(this : ^ImRect)                                              { this.Min.x = math.trunc(this.Min.x); this.Min.y = math.trunc(this.Min.y); this.Max.x = math.trunc(this.Max.x); this.Max.y = math.trunc(this.Max.y); }
IsInverted :: proc(this : ImRect)                               -> bool   { return this.Min.x > this.Max.x || this.Min.y > this.Max.y; }
ToVec4 :: proc(this : ImRect)                                   -> ImVec4 { return ImVec4{this.Min.x, this.Min.y, this.Max.x, this.Max.y}; }


// Helper: ImBitArray
IM_BITARRAY_TESTBIT :: #force_inline proc(_ARRAY : [^]u32, #any_int _N :  int) -> bool { return _ARRAY[(_N) >> 5] & (u32(1) << ((_N) & 31)) != 0  } // Macro version of ImBitArrayTestBit(): ensure args have side-effect or are costly!
IM_BITARRAY_CLEARBIT :: #force_inline proc(_ARRAY : [^]u32, #any_int _N : int)        {  _ARRAY[(_N) >> 5] &= ~(u32(1) << ((_N) & 31))  }    // Macro version of ImBitArrayClearBit(): ensure args have side-effect or are costly!
ImBitArrayGetStorageSizeInBytes :: #force_inline proc(bitcount : int) -> int    { return (int)((bitcount + 31) >> 5) << 2; }
ImBitArrayClearAllBits :: #force_inline proc(arr : ^u32, #any_int bitcount : int){ memset(arr, 0, ImBitArrayGetStorageSizeInBytes(bitcount)); }
ImBitArrayTestBit :: #force_inline proc(arr : ^u32, #any_int n : int) -> bool      { mask := u32(1) << (n & 31); return (arr[n >> 5] & mask) != 0; }
ImBitArrayClearBit :: #force_inline proc(arr : ^u32, #any_int n : int)           { mask := u32(1) << (n & 31); arr[n >> 5] &= ~mask; }
ImBitArraySetBit :: #force_inline proc(arr : ^u32, #any_int n : int)             { mask := u32(1) << (n & 31); arr[n >> 5] |= mask; }
ImBitArraySetBitRange :: #force_inline proc(arr : ^u32, n : int, n2 : int) // Works on range [n..n2)
{
    n := n; n2 := n2
    n2 -= 1;
    for (n <= n2)
    {
        a_mod := (n & 31);
        b_mod := (n2 > (n | 31) ? 31 : (n2 & 31)) + 1;
        mask := u32((u64(1) << b_mod) - 1) & ~(ImU32)((u64(1) << a_mod) - 1);
        arr[n >> 5] |= mask;
        n = (n + 32) & ~31;
    }
}

ImBitArrayPtr :: [^]u32 // Name for use in structs

// Helper: ImBitArray class (wrapper over ImBitArray functions)
// Store 1-bit per value.
ImBitArray :: struct($BITCOUNT : int, $OFFSET : int = 0)
{
    Storage : [(BITCOUNT + 31) >> 5]u32,
};

init_ImBitArray :: proc(this : ^ImBitArray) {
    this^ = {}
}
ClearAllBits :: proc(this : ^ImBitArray) {
    this^ = {}
}
SetAllBits :: proc(this : ^ImBitArray) {
    this^ = {}
}

TestBit_a :: proc(this : ^ImBitArray, #any_int n : int) -> bool       { n += OFFSET; assert(n >= 0 && n < BITCOUNT); return IM_BITARRAY_TESTBIT(this.Storage, n); }
SetBit_a :: proc(this : ^ImBitArray, #any_int n : int)                { n += OFFSET; assert(n >= 0 && n < BITCOUNT); ImBitArraySetBit(this.Storage, n); }
ClearBit_a :: proc(this : ^ImBitArray, #any_int n : int)              { n += OFFSET; assert(n >= 0 && n < BITCOUNT); ImBitArrayClearBit(this.Storage, n); }
SetBitRange :: proc(this : ^ImBitArray, #any_int n : int, #any_int n2 : int) { n += OFFSET; n2 += OFFSET; assert(n >= 0 && n < BITCOUNT && n2 > n && n2 <= BITCOUNT); ImBitArraySetBitRange(this.Storage, n, n2); } // Works on range [n..n2)

// Helper: ImBitVector
// Store 1-bit per value.
ImBitVector :: struct
{
    Storage : [dynamic]u32,
};

Create :: proc(this : ^ImBitVector, #any_int sz : int)              { this.Storage.resize((sz + 31) >> 5); memset(this.Storage.Data, 0, len(this.Storage) * size_of(this.Storage.Data[0])); }
ImBitVector_Clear :: proc(this : ^ImBitVector)                         { clear(&this.Storage) }
TestBit_v :: proc(this : ^ImBitVector, #any_int n : int) -> bool      { assert(n < (len(this.Storage) << 5)); return IM_BITARRAY_TESTBIT(this.Storage.Data, n); }
SetBit_v :: proc(this : ^ImBitVector, #any_int n : int)               { assert(n < (len(this.Storage) << 5)); ImBitArraySetBit(this.Storage.Data, n); }
ClearBit_v :: proc(this : ^ImBitVector, #any_int n : int)             { assert(n < (len(this.Storage) << 5)); ImBitArrayClearBit(this.Storage.Data, n); }

TestBit :: proc { TestBit_a, TestBit_v }
SetBit :: proc { SetBit_a, SetBit_v, SetBit_fgrb }
ClearBit :: proc { ClearBit_a, ClearBit_v }

// Helper: ImSpanAllocator<>
// Facilitate storing multiple chunks into a single large block (the "arena")
// - Usage: call Reserve() N times, allocate GetArenaSizeInBytes() worth, pass it to SetArenaBasePtr(), call GetSpan() N times to retrieve the aligned ranges.
ImSpanAllocator :: struct($CHUNKS : i32)
{
    BasePtr : rawptr,
    CurrOff : i32,
    CurrIdx : i32,
    Offsets : [CHUNKS]i32,
    Sizes : [CHUNKS]i32,
};

init_ImSpanAllocator :: proc(this : ^ImSpanAllocator) { this^ = {} }
Reserve_span :: proc(this : ^ImSpanAllocator($CHUNKS), n : i32, sz : i32, a : int = 4) {
    assert(n == this.CurrIdx && n < CHUNKS);
    this.CurrOff = i32(mem.align_backward_int(int(this.CurrOff), a))
    this.Offsets[n] = this.CurrOff;
    this.Sizes[n] = sz;
    this.CurrIdx += 1;
    this.CurrOff += sz;
}
GetArenaSizeInBytes :: proc(this : $S/^ImSpanAllocator) -> i32          { return this.CurrOff; }
SetArenaBasePtr :: proc(this : $S/^ImSpanAllocator, base_ptr : rawptr)  { this.BasePtr = base_ptr; }
GetSpanPtrBegin :: proc(this : ^ImSpanAllocator($CHUNKS), n : i32) -> rawptr
{
    assert(n >= 0 && n < CHUNKS && this.CurrIdx == CHUNKS);
    return mem.ptr_offset(cast(^u8) this.BasePtr, cast(int) this.Offsets[n]);
}
GetSpanPtrEnd :: proc(this : ^ImSpanAllocator($CHUNKS), n : i32) -> rawptr
{
    assert(n >= 0 && n < CHUNKS && this.CurrIdx == CHUNKS);
    return mem.ptr_offset(cast(^u8) this.BasePtr, int(this.Offsets[n] + this.Sizes[n]));
}
GetSpan :: proc(this : $S/^ImSpanAllocator, n : i32, out_span : ^[]$T)
{
    raw := transmute(^runtime.Raw_Slice) out_span
    raw.data = GetSpanPtrBegin(this, n)
    end := GetSpanPtrEnd(this, n)
    raw.len = transmute(int) (uintptr(end) - uintptr(raw.data))
}

// Helper: ImPool<>
// Basic keyed storage for contiguous instances, slow/amortized insertion, O(1) indexable, O(Log N) queries by ID over a dense/hot buffer,
// Honor constructor/destructor. Add/remove invalidate all pointers. Indexes have the same lifetime as the associated object.
ImPoolIdx :: i32

ImPool :: struct($T : typeid)
{
    Buf : [dynamic]T,        // Contiguous data
    Map : ImGuiStorage,        // ID.Index
    FreeIdx : ImPoolIdx,    // Next free idx to use
    AliveCount : ImPoolIdx, // Number of active/alive items (for display purpose)
};

deinit_ImPool :: proc(this : ^ImPool($T))   { Clear(this); }
GetByKey      :: proc(this : ^ImPool($T), key : ImGuiID)                  -> ^T  { idx := GetInt(&this.Map, key, -1); return (idx != -1) ? &this.Buf[idx] : nil; }
GetByIndex    :: proc(this : ^ImPool($T), n : ImPoolIdx)                  -> ^T  { return &this.Buf[n]; }
GetIndex      :: proc(this : ^ImPool($T), p : ^T)                         -> ImPoolIdx   { assert(p >= cast(^T) raw_data(this.Buf) && p < end(this.Buf)); return ImPoolIdx(mem.ptr_sub(p, cast(^T) raw_data(this.Buf))); }
GetOrAddByKey :: proc(this : ^ImPool($T), key : ImGuiID)                  -> ^T  { p_idx := GetIntRef(&this.Map, key, -1); if (p_idx^ != -1) do return &this.Buf[p_idx^]; p_idx^ = this.FreeIdx; return Add(this); }
Contains_pool :: proc(this : ^ImPool($T), p : ^T)                         -> bool   { return (p >= this.Buf.Data && p < this.Buf.Data + this.Buf.Size); }
Pool_Clear    :: proc(this : ^ImPool($T))                                          {
    for n := 0; n < len(this.Map.Data); n += 1 {
        idx := this.Map.Data[n].val_i;
        if (idx != -1) do __destructors(cast(^T) &this.Buf[idx]);
    }
    this.Map.Clear();
    this.Buf.clear();
    this.FreeIdx = 0;
    this.AliveCount = 0;
}
Add_pool      :: proc(this : ^ImPool($T)) -> ^T  {
    idx := this.FreeIdx;
    if (cast(int) idx == len(this.Buf)) {
        resize(&this.Buf, len(this.Buf) + 1);
        this.FreeIdx += 1;
    }
    else {
        this.FreeIdx = (cast(^i32)&this.Buf[idx])^;
    }
    __inplace_constructors(cast(^T) &this.Buf[idx]);
    this.AliveCount += 1;
    return &this.Buf[idx];
}
Remove_ptr    :: proc(this : ^ImPool($T), key : ImGuiID, p : ^T)             { Remove(this, key, GetIndex(this, p)); }
Remove_idx    :: proc(this : ^ImPool($T), key : ImGuiID, idx : ImPoolIdx)    {
    __destructors(cast(^$T) &this.Buf[idx])
    (cast(^int) &this.Buf[idx])^ = this.FreeIdx;
    this.FreeIdx = idx;
    this.Map.SetInt(key, -1);
    this.AliveCount -= 1;
}
Remove :: proc { Remove_ptr, Remove_idx }
Reserve_pool       :: proc(this : ^ImPool($T), capacity : int)                    { this.Buf.reserve(capacity); this.Map.Data.reserve(capacity); }

// To iterate a ImPool: for (int n = 0; n < pool.GetMapSize(); n++) if (T* t = pool.TryGetMapData(n)) { ... }
// Can be avoided if you know .Remove() has never been called on the pool, or AliveCount == GetMapSize()
GetAliveCount :: proc(this : ImPool($T))  -> int               { return this.AliveCount; }      // Number of active/alive items in the pool (for display purpose)
GetBufSize    :: proc(this : ImPool($T))  -> int               { return len(this.Buf); }
GetMapSize    :: proc(this : ImPool($T))  -> int               { return len(this.Map.Data); }   // It is the map we need iterate to find valid items, since we don't have "alive" storage anywhere
TryGetMapData :: proc(this : ^ImPool($T), n : ImPoolIdx) -> ^T  { idx := this.Map.Data[n].val_i; if (idx == -1) do return nil; return GetByIndex(this, idx); }

// Helper: ImChunkStream<>
// Build and iterate a contiguous stream of variable-sized structures.
// This is used by Settings to store persistent data while reducing allocation count.
// We store the chunk size first, and align the final size on 4 bytes boundaries.
// The tedious/zealous amount of casting is to avoid -Wcast-align warnings.
ImChunkStream :: struct($T : typeid)
{
    Buf : [dynamic]u8,
};

ImChunkStream_Clear :: proc(this : ^ImChunkStream($T))                       { this.Buf.clear(); }
ImChunkStream_empty :: proc(this : ^ImChunkStream($T))               -> bool { return len(this.Buf) == 0; }
ImChunkStream_Size  :: proc(this : ^ImChunkStream($T))               -> int  { return len(this.Buf); }
alloc_chunk     :: proc(this : ^ImChunkStream($T), sz : int)     -> ^T   { HDR_SZ := 4; sz := mem.align_backward(HDR_SZ + sz, 4); off := len(this.Buf); this.Buf.resize(off + sz); (cast(^int) (this.Buf.Data + off))[0] = sz; return cast(^T)(this.Buf.Data + off + HDR_SZ); }
begin           :: proc(this : ^ImChunkStream($T))               -> ^T   { HDR_SZ := 4; if (!this.Buf.Data) do return nil; return cast(^T) this.Buf.Data + HDR_SZ; }
next_chunk      :: proc(this : ^ImChunkStream($T), p : ^T)       -> ^T   { HDR_SZ := 4; assert(p >= begin() && p < end()); p = cast(^T) (cast(rawptr) p + chunk_size(p)); if (p == cast(^T)(cast(rawptr)end(this) + HDR_SZ)) do return nil; assert(p < end(this)); return p; }
chunk_size      :: proc(this : ^ImChunkStream($T), p : ^T)       -> int  { return (cast(^int)p)[-1]; }
ChunkStream_end :: proc(this : ^ImChunkStream($T))               -> ^T   { return cast(^T) (this.Buf.Data + this.Buf.Size); }
offset_from_ptr :: proc(this : ^ImChunkStream($T), p : ^T)       -> int  { assert(p >= begin() && p < end()); off := cast(rawptr) p - this.Buf.Data; return off; }
ptr_from_offset :: proc(this : ^ImChunkStream($T), off : int)    -> ^T   { assert(off >= 4 && off < this.Buf.Size); return cast(^T) this.Buf.Data + off; }
swap_c            :: proc(this : ^ImChunkStream($T), rhs : T)             { rhs.Buf.swap(this.Buf); }

// Helper: ImGuiTextIndex
// Maintain a line index for a text buffer. This is a strong candidate to be moved into the public API.
ImGuiTextIndex :: struct
{
    LineOffsets : [dynamic]i32,
    EndOffset : i32,                          // Because we don't own text buffer we need to maintain EndOffset (may bake in LineOffsets?)
};

ImGuiTextIndex_Clear :: proc(this : ^ImGuiTextIndex)                                { this.LineOffsets.clear(); this.EndOffset = 0; }
ImGuiTextIndex_Size :: proc(this : ^ImGuiTextIndex) -> i32                          { return len(this.LineOffsets); }
get_line_begin :: proc(this : ^ImGuiTextIndex, base : ^u8, n : i32) -> ^u8 { return base + this.LineOffsets[n]; }
get_line_end :: proc(this : ^ImGuiTextIndex, base : ^u8, n : i32) -> ^u8   { return base + (n + 1 < len(this.LineOffsets) ? (this.LineOffsets[n + 1] - 1) : this.EndOffset); }

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
IM_ROUNDUP_TO_EVEN :: #force_inline proc(_V : $T) -> T { return ((_V + 1) / 2) * 2 }
IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN :: 4
IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX :: 512
IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC :: #force_inline proc(_RAD, _MAXERROR : f32) -> int {
    return ImClamp(IM_ROUNDUP_TO_EVEN(cast(int) ImCeil(IM_PI / ImAcos(1 - ImMin((_MAXERROR), (_RAD)) / (_RAD)))), IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN, IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX)
}

// Raw equation from IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC rewritten for 'r' and 'error'.
IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R     :: #force_inline proc(_N : int, _MAXERROR : f32) -> f32 { return  ((_MAXERROR) / (1 - math.cos(IM_PI / ImMax(f32(_N), IM_PI)))) }
IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_ERROR :: #force_inline proc(_N : int, _RAD : f32) -> f32  { return  ((1 - math.cos(IM_PI / ImMax(f32(_N), IM_PI))) / (_RAD)) }

// ImDrawList: Lookup table size for adaptive arc drawing, cover full circle.
IM_DRAWLIST_ARCFAST_TABLE_SIZE :: 48
IM_DRAWLIST_ARCFAST_SAMPLE_MAX :: IM_DRAWLIST_ARCFAST_TABLE_SIZE

// Data shared between all ImDrawList instances
// Conceptually this could have been called e.g. ImDrawListSharedContext
// Typically one ImGui context would create and maintain one of this.
// You may want to create your own instance of you try to ImDrawList completely without ImGui. In that case, watch out for future changes to this structure.
ImDrawListSharedData :: struct
{
    TexUvWhitePixel : ImVec2,            // UV of white pixel in the atlas
    TexUvLines : [^]ImVec4,                 // UV of anti-aliased lines in the atlas
    Font : ^ImFont,                       // Current/default font (optional, for simplified AddText overload)
    FontSize : f32,                   // Current/default font size (optional, for simplified AddText overload)
    FontScale : f32,                  // Current/default font scale (== FontSize / Font.FontSize)
    CurveTessellationTol : f32,       // Tessellation tolerance when using PathBezierCurveTo()
    CircleSegmentMaxError : f32,      // Number of circle segments to use per pixel of radius for AddCircle() etc
    ClipRectFullscreen : ImVec4,         // Value for PushClipRectFullscreen()
    InitialFlags : ImDrawListFlags,               // Initial flags at the beginning of the frame (it is possible to alter flags on a per-drawlist basis afterwards)
    TempBuffer : [dynamic]ImVec2,                // Temporary write buffer

    // Lookup tables
    ArcFastVtx : [IM_DRAWLIST_ARCFAST_TABLE_SIZE]ImVec2, // Sample points on the quarter of the circle.
    ArcFastRadiusCutoff : f32,                        // Cutoff radius after which arc drawing will fallback to slower PathArcTo()
    CircleSegmentCounts : [64]u8,    // Precomputed segment count for given radius before we calculate it dynamically (to avoid calculation overhead)
};

ImDrawDataBuilder :: struct
{
    Layers : [2]^[dynamic]^ImDrawList,      // Pointers to global layers for: regular, tooltip. LayersP[0] is owned by DrawData.
    LayerData1 : [dynamic]^ImDrawList,
};

//-----------------------------------------------------------------------------
// [SECTION] Data types support
//-----------------------------------------------------------------------------

ImGuiDataVarInfo :: struct
{
    Type : ImGuiDataType,
    Count : u32,      // 1+
    Offset : u32,     // Offset in parent structure
};
GetVarPtr :: proc(this : ^ImGuiDataVarInfo, parent : rawptr) -> rawptr { return mem.ptr_offset(cast(^u8) parent, int(this.Offset)) }

ImGuiDataTypeStorage :: struct
{
    Data : [8]u8,        // Opaque storage to fit any data up to ImGuiDataType.COUNT
};

// Type information associated to one ImGuiDataType. Retrieve with DataTypeGetInfo().
ImGuiDataTypeInfo :: struct
{
    Size : int,           // Size in bytes
    Name : string,           // Short descriptive name for the type, for debugging
    PrintFmt : string,       // Default printf format for the type
    ScanFmt : string,        // Default scanf format for the type
};

// Extend ImGuiDataType.
ImGuiDataTypePrivate :: enum i32
{
    Pointer = len(ImGuiDataType) + 1,
    ID,
};

//-----------------------------------------------------------------------------
// [SECTION] Widgets support: flags, enums, data structures
//-----------------------------------------------------------------------------

// Extend ImGuiItemFlags
// - input: PushItemFlag() manipulates g.CurrentItemFlags, g.NextItemData.ItemFlags, ItemAdd() calls may add extra flags too.
// - output: stored in g.LastItemData.ItemFlags
ImGuiItemFlagsPrivate :: enum i32
{
    // Controlled by user
    Disabled                 = 1 << 10, // false     // Disable interactions (DOES NOT affect visuals. DO NOT mix direct use of this with BeginDisabled(). See BeginDisabled()/EndDisabled() for full disable feature, and github #211).
    ReadOnly                 = 1 << 11, // false     // [ALPHA] Allow hovering interactions but underlying value is not changed.
    MixedValue               = 1 << 12, // false     // [BETA] Represent a mixed/indeterminate value, generally multi-selection where values differ. Currently only supported by Checkbox() (later should support all sorts of widgets)
    NoWindowHoverableCheck   = 1 << 13, // false     // Disable hoverable check in ItemHoverable()
    AllowOverlap             = 1 << 14, // false     // Allow being overlapped by another widget. Not-hovered to Hovered transition deferred by a frame.
    NoNavDisableMouseHover   = 1 << 15, // false     // Nav keyboard/gamepad mode doesn't disable hover highlight (behave as if NavHighlightItemUnderNav==false).
    NoMarkEdited             = 1 << 16, // false     // Skip calling MarkItemEdited()

    // Controlled by widget code
    Inputable                = 1 << 20, // false     // [WIP] Auto-activate input mode when tab focused. Currently only used and supported by a few items before it becomes a generic feature.
    HasSelectionUserData     = 1 << 21, // false     // Set by SetNextItemSelectionUserData()
    IsMultiSelect            = 1 << 22, // false     // Set by SetNextItemSelectionUserData()

    Default_                 = cast(i32)ImGuiItemFlags.AutoClosePopups,    // Please don't change, use PushItemFlag() instead.

    // Obsolete
    //SelectableDontClosePopup = !AutoClosePopups, // Can't have a redirect as we inverted the behavior
};

// Status flags for an already submitted item
// - output: stored in g.LastItemData.StatusFlags
ImGuiItemStatusFlags :: bit_set[ImGuiItemStatusFlag; i32]
when IMGUI_ENABLE_TEST_ENGINE {
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
        Openable           = 20,  // Item is an openable (e.g. TreeNode)
        Opened             = 21,  // Opened status
        Checkable          = 22,  // Item is a checkable (e.g. CheckBox, MenuItem)
        Checked            = 23,  // Checked status
        Inputable          = 24,  // Item is a text-inputable (e.g. InputText, SliderXXX, DragXXX)
    }
}
else {
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
    }
}

// Extend ImGuiHoveredFlags_
ImGuiHoveredFlagsPrivate :: enum i32
{
    DelayMask_                    = cast(i32) ImGuiHoveredFlags{ .DelayNone , .DelayShort , .DelayNormal , .NoSharedDelay },
    AllowedMaskForIsWindowHovered = cast(i32) ImGuiHoveredFlags{ .ChildWindows , .RootWindow , .AnyWindow , .NoPopupHierarchy , .DockHierarchy , .AllowWhenBlockedByPopup , .AllowWhenBlockedByActiveItem , .ForTooltip , .Stationary },
    AllowedMaskForIsItemHovered   = i32(ImGuiHoveredFlags{ .AllowWhenBlockedByPopup , .AllowWhenBlockedByActiveItem }) | i32(ImGuiHoveredFlags_AllowWhenOverlapped) | i32(ImGuiHoveredFlags{ .AllowWhenDisabled , .NoNavOverride , .ForTooltip , .Stationary }) | i32(DelayMask_),
};

// Extend ImGuiInputTextFlags_
ImGuiInputTextFlagsPrivate :: enum i32
{
    // [Internal]
    Multiline           = 1 << 26,  // For internal use by InputTextMultiline()
    MergedItem          = 1 << 27,  // For internal use by TempInputText(), will skip calling ItemAdd(). Require bounding-box to strictly match.
    LocalizeDecimalPoint= 1 << 28,  // For internal use by InputScalar() and TempInputScalar()
};

// Extend ImGuiButtonFlags_
ImGuiButtonFlagsPrivate :: enum i32
{
    PressedOnClick         = 1 << 4,   // return true on click (mouse down event)
    PressedOnClickRelease  = 1 << 5,   // [Default] return true on click + release on same item <-- this is what the majority of Button are using
    PressedOnClickReleaseAnywhere = 1 << 6, // return true on click + release even if the release event is not done while hovering the item
    PressedOnRelease       = 1 << 7,   // return true on release (default requires click+release)
    PressedOnDoubleClick   = 1 << 8,   // return true on double-click (default requires click+release)
    PressedOnDragDropHold  = 1 << 9,   // return true when held into while we are drag and dropping another item (used by e.g. tree nodes, collapsing headers)
    //Repeat               = 1 << 10,  // hold to repeat -> use ImGuiItemFlags_ButtonRepeat instead.
    FlattenChildren        = 1 << 11,  // allow interactions even if a child window is overlapping
    AllowOverlap           = 1 << 12,  // require previous frame HoveredId to either match id or be null before being usable.
    //DontClosePopups      = 1 << 13,  // disable automatically closing parent popup on press
    //Disabled             = 1 << 14,  // disable interactions -> use BeginDisabled() or ImGuiItemFlags_Disabled
    AlignTextBaseLine      = 1 << 15,  // vertically align button to match text baseline - ButtonEx() only // FIXME: Should be removed and handled by SmallButton(), not possible currently because of DC.CursorPosPrevLine
    NoKeyModsAllowed       = 1 << 16,  // disable mouse interaction if a key modifier is held
    NoHoldingActiveId      = 1 << 17,  // don't set ActiveId while holding the mouse (PressedOnClick only)
    NoNavFocus             = 1 << 18,  // don't override navigation focus when activated (FIXME: this is essentially used every time an item uses ImGuiItemFlags_NoNav, but because legacy specs don't requires LastItemData to be set ButtonBehavior(), we can't poll g.LastItemData.ItemFlags)
    NoHoveredOnFocus       = 1 << 19,  // don't report as hovered when nav focus is on this item
    NoSetKeyOwner          = 1 << 20,  // don't set key/input owner on the initial click (note: mouse buttons are keys! often, the key in question will be ImGuiKey.MouseLeft!)
    NoTestKeyOwner         = 1 << 21,  // don't test key/input owner when polling the key (note: mouse buttons are keys! often, the key in question will be ImGuiKey.MouseLeft!)
    PressedOnMask_         = PressedOnClick | PressedOnClickRelease | PressedOnClickReleaseAnywhere | PressedOnRelease | PressedOnDoubleClick | PressedOnDragDropHold,
    PressedOnDefault_      = PressedOnClickRelease,
};

// Extend ImGuiComboFlags_
ImGuiComboFlagsPrivate :: enum i32
{
    CustomPreview           = 1 << 20,  // enable BeginComboPreview()
};

// Extend ImGuiSliderFlags_
ImGuiSliderFlagsPrivate :: enum i32
{
    Vertical               = 1 << 20,  // Should this slider be orientated vertically?
    ReadOnly               = 1 << 21,  // Consider using g.NextItemData.ItemFlags |= ImGuiItemFlags_ReadOnly instead.
};

// Extend ImGuiSelectableFlags_
ImGuiSelectableFlagsPrivate :: enum i32
{
    // NB: need to be in sync with last value of ImGuiSelectableFlags_
    NoHoldingActiveID      = 1 << 20,
    SelectOnNav            = 1 << 21,  // (WIP) Auto-select when moved into. This is not exposed in public API as to handle multi-select and modifiers we will need user to explicitly control focus scope. May be replaced with a BeginSelection() API.
    SelectOnClick          = 1 << 22,  // Override button behavior to react on Click (default is Click+Release)
    SelectOnRelease        = 1 << 23,  // Override button behavior to react on Release (default is Click+Release)
    SpanAvailWidth         = 1 << 24,  // Span all avail width even if we declared less for layout purpose. FIXME: We may be able to remove this (added in 6251d379, 2bcafc86 for menus)
    SetNavIdOnHover        = 1 << 25,  // Set Nav/Focus ID on mouse hover (used by MenuItem)
    NoPadWithHalfSpacing   = 1 << 26,  // Disable padding each side with ItemSpacing * 0.5f
    NoSetKeyOwner          = 1 << 27,  // Don't set key/input owner on the initial click (note: mouse buttons are keys! often, the key in question will be ImGuiKey.MouseLeft!)
};

// Extend ImGuiTreeNodeFlags_
ImGuiTreeNodeFlagsPrivate :: enum i32
{
    ClipLabelForTrailingButton = 1 << 28,// FIXME-WIP: Hard-coded for CollapsingHeader()
    UpsideDownArrow            = 1 << 29,// FIXME-WIP: Turn Down arrow into an Up arrow, for reversed trees (#6517)
    OpenOnMask_                = cast(i32) ImGuiTreeNodeFlags{.OpenOnDoubleClick , .OpenOnArrow},
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
ImGuiLayoutType :: enum i32
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
ImGuiLogFlags_OutputMask_ :: ImGuiLogFlags{ .OutputTTY , .OutputFile , .OutputBuffer , .OutputClipboard }

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
    using _ : struct #raw_union { BackupInt : [2]i32, BackupFloat : [2]f32 },
};


init_ImGuiStyleMod_i :: proc(this : ^ImGuiStyleMod, idx : ImGuiStyleVar, v : i32)     { this.VarIdx = idx; this.BackupInt[0] = v; }
init_ImGuiStyleMod_f :: proc(this : ^ImGuiStyleMod, idx : ImGuiStyleVar, v : f32)   { this.VarIdx = idx; this.BackupFloat[0] = v; }
init_ImGuiStyleMod_v :: proc(this : ^ImGuiStyleMod, idx : ImGuiStyleVar, v : ImVec2)  { this.VarIdx = idx; this.BackupFloat[0] = v.x; this.BackupFloat[1] = v.y; }

init_ImGuiStyleMod :: proc { init_ImGuiStyleMod_i, init_ImGuiStyleMod_f, init_ImGuiStyleMod_v }

make_ImGuiStyleMod_i :: proc(idx : ImGuiStyleVar, v : i32) -> (m : ImGuiStyleMod) {  init_ImGuiStyleMod_i(&m, idx, v) }
make_ImGuiStyleMod_f :: proc(idx : ImGuiStyleVar, v : f32) -> (m : ImGuiStyleMod) {  init_ImGuiStyleMod_f(&m, idx, v) }
make_ImGuiStyleMod_v :: proc(idx : ImGuiStyleVar, v : ImVec2) -> (m : ImGuiStyleMod) {  init_ImGuiStyleMod_v(&m, idx, v) }

make_ImGuiStyleMod :: proc { make_ImGuiStyleMod_i, make_ImGuiStyleMod_f, make_ImGuiStyleMod_v }


// Storage data for BeginComboPreview()/EndComboPreview()
ImGuiComboPreviewData :: struct
{
    PreviewRect : ImRect,
    BackupCursorPos : ImVec2,
    BackupCursorMaxPos : ImVec2,
    BackupCursorPosPrevLine : ImVec2,
    BackupPrevLineTextBaseOffset : f32,
    BackupLayout : ImGuiLayoutType,
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
};

// Internal temporary state for deactivating InputText() instances.
ImGuiInputTextDeactivatedState :: struct
{
    ID : ImGuiID,              // widget id owning the text state (which just got deactivated)
    TextA : [dynamic]u8,           // text buffer
};

ImGuiInputTextDeactivatedState_ClearFreeMemory :: proc(this : ^ImGuiInputTextDeactivatedState)           { this.ID = 0; this.TextA.clear(); }

// Forward declare imstb_textedit.h structure + make its main configuration define accessible
IMSTB_TEXTEDIT_STRING :: ImGuiInputTextState
IMSTB_TEXTEDIT_CHARTYPE :: u8
IMSTB_TEXTEDIT_GETWIDTH_NEWLINE :: -1.0
IMSTB_TEXTEDIT_UNDOSTATECOUNT :: 99
IMSTB_TEXTEDIT_UNDOCHARCOUNT :: 999
ImStbTexteditState :: STB_TexteditState

// Internal state of the currently focused/edited text input box
// For a given item ID, access with ImGui::GetInputTextState()
ImGuiInputTextState :: struct
{
    Ctx : ^ImGuiContext,                    // parent UI context (needs to be set explicitly by parent).
    Stb : ^ImStbTexteditState,                    // State for stb_textedit.h
    Flags : ImGuiInputTextFlags,                  // copy of InputText() flags. may be used to check if e.g. ImGuiInputTextFlags_Password is set.
    ID : ImGuiID,                     // widget id owning the text state
    TextLen : i32,                // UTF-8 length of the string in TextA (in bytes)
    TextSrc : [^]u8,                // == TextA.Data unless read-only, in which case == buf passed to InputText(). Field only set and valid _inside_ the call InputText() call.
    TextA : [dynamic]u8,                  // main UTF8 buffer. len(TextA) is a buffer size! Should always be >= buf_size passed by user (and of course >= CurLenA + 1).
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

    // Reload user buf (WIP #2890)
    // If you modify underlying user-passed const char* while active you need to call this (InputText V2 may lift this)
    //   strcpy(my_buf, "hello");
    //   if (ImGuiInputTextState* state = ImGui::GetInputTextState(id)) // id may be ImGui::GetItemID() is last item
    //       state.ReloadUserBufAndSelectAll();
};

ClearText :: proc(this : ^ImGuiInputTextState)                 { this.TextLen = 0; this.TextA[0] = 0; this.CursorClamp(); }
ImGuiInputTextState_ClearFreeMemory :: proc(this : ^ImGuiInputTextState)           { clear(&this.TextA);  clear(&this.TextToRevertTo); }


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

    //inline void ClearFlags()    { Flags = ImGuiNextWindowDataFlags_None; }
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
};

init_ImGuiNextItemData :: proc(this : ^ImGuiNextItemData) {
    this^ = {}
    SelectionUserData = -1;
}
ClearFlags :: #force_inline proc(this : ^ImGuiNextWindowData) {
    this.HasFlags = nil;
    this.ItemFlags = nil;
} // Also cleared manually by ItemAdd()!

// Status storage for the last submitted item
ImGuiLastItemData :: struct
{
    ID : ImGuiID,
    ItemFlags : ImGuiItemFlags,          // See ImGuiItemFlags_
    StatusFlags : ImGuiItemStatusFlags,        // See ImGuiItemStatusFlags_
    Rect : ImRect,               // Full rectangle
    NavRect : ImRect,            // Navigation scoring rectangle (not displayed)
    // Rarely used fields are not explicitly cleared, only valid when the corresponding ImGuiItemStatusFlags ar set.
    DisplayRect : ImRect,        // Display rectangle. ONLY VALID IF (.HasDisplayRect in StatusFlags) is set.
    ClipRect : ImRect,           // Clip rectangle at the time of submitting item. ONLY VALID IF (.HasClipRect in StatusFlags) is set..
    Shortcut : ImGuiKeyChord,           // Shortcut at the time of submitting item. ONLY VALID IF (.HasShortcut in StatusFlags) is set..
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

// size_of() = 20
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
};

init_ImGuiPtrOrIndex_a :: proc(this : ^ImGuiPtrOrIndex, ptr : rawptr)  { this.Ptr = ptr; this.Index = -1; }
init_ImGuiPtrOrIndex_b :: proc(this : ^ImGuiPtrOrIndex, index : i32)  { this.Ptr = nil; this.Index = index; }

init_ImGuiPtrOrIndex :: proc { init_ImGuiPtrOrIndex_a, init_ImGuiPtrOrIndex_b }

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
    ParentNavLayer : ImGuiNavLayer, // Resolved on BeginPopup(). Actually a ImGuiNavLayer type (declared down below), initialized to -1 which is not part of an enum, but serves well-enough as "not any of layers" value
    OpenFrameCount : i32, // Set on OpenPopup()
    OpenParentId : ImGuiID,   // Set on OpenPopup(), we need this to differentiate multiple menu sets from each others (e.g. inside menu bar vs loose menu items)
    OpenPopupPos : ImVec2,   // Set on OpenPopup(), preferred popup position (typically == OpenMousePos when using mouse)
    OpenMousePos : ImVec2,   // Set on OpenPopup(), copy of mouse position at the time of opening popup
};

init_ImGuiPopupData :: proc(this : ^ImGuiPopupData) {
    this^ = {}
    this.ParentNavLayer = -1;
    this.OpenFrameCount = -1;
}

//-----------------------------------------------------------------------------
// [SECTION] Inputs support
//-----------------------------------------------------------------------------

// Bit array for named keys
ImBitArrayForNamedKeys :: ImBitArray(cast(int)ImGuiKey.NamedKey_COUNT, -cast(int)ImGuiKey.NamedKey_BEGIN)

// [Internal] Key ranges
ImGuiKey_LegacyNativeKey_BEGIN :: ImGuiKey(0)
ImGuiKey_LegacyNativeKey_END :: ImGuiKey(512)
ImGuiKey_Keyboard_BEGIN    ::     ImGuiKey.NamedKey_BEGIN
ImGuiKey_Keyboard_END      ::     ImGuiKey.GamepadStart
ImGuiKey_Gamepad_BEGIN     ::     ImGuiKey.GamepadStart
ImGuiKey_Gamepad_END       ::     ImGuiKey(i32(ImGuiKey.GamepadRStickDown) + 1)
ImGuiKey_Mouse_BEGIN       ::     ImGuiKey.MouseLeft
ImGuiKey_Mouse_END         ::     ImGuiKey(i32(ImGuiKey.MouseWheelY) + 1)
ImGuiKey_Aliases_BEGIN     ::     ImGuiKey_Mouse_BEGIN
ImGuiKey_Aliases_END       ::     ImGuiKey_Mouse_END

// [Internal] Named shortcuts for Navigation
ImGuiKey_NavKeyboardTweakSlow :: ImGuiKey.Mod_Ctrl
ImGuiKey_NavKeyboardTweakFast :: ImGuiKey.Mod_Shift
ImGuiKey_NavGamepadTweakSlow :: ImGuiKey.GamepadL1
ImGuiKey_NavGamepadTweakFast :: ImGuiKey.GamepadR1
ImGuiKey_NavGamepadActivate  :: proc(g : ^ImGuiContext) -> ImGuiKey { return (g.IO.ConfigNavSwapGamepadButtons ? .GamepadFaceRight : .GamepadFaceDown) }
ImGuiKey_NavGamepadCancel    :: proc(g : ^ImGuiContext) -> ImGuiKey { return (g.IO.ConfigNavSwapGamepadButtons ? .GamepadFaceDown : .GamepadFaceRight) }
ImGuiKey_NavGamepadMenu  :: ImGuiKey.GamepadFaceLeft
ImGuiKey_NavGamepadInput :: ImGuiKey.GamepadFaceUp

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
ImGuiInputEventMousePos      :: struct{ PosX, PosY : f32, MouseSource : ImGuiMouseSource }
ImGuiInputEventMouseWheel    :: struct{ WheelX, WheelY : f32, MouseSource : ImGuiMouseSource }
ImGuiInputEventMouseButton   :: struct{ Button : ImGuiMouseButton, Down : bool, MouseSource : ImGuiMouseSource }
ImGuiInputEventMouseViewport :: struct{ HoveredViewportID : ImGuiID }
ImGuiInputEventKey           :: struct{ Key : ImGuiKey, Down : bool, AnalogValue : f32 }
ImGuiInputEventText          :: struct{ Char : u32 }
ImGuiInputEventAppFocused    :: struct{ Focused : bool }

ImGuiInputEvent :: struct
{
    Type : ImGuiInputEventType,
    Source : ImGuiInputSource,
    EventId : u32,        // Unique, sequential increasing integer to identify an event (if you need to correlate them to other data).
    using _ : struct #raw_union
    {
        MousePos : ImGuiInputEventMousePos,       // if Type == ImGuiInputEventType_MousePos
        MouseWheel : ImGuiInputEventMouseWheel,     // if Type == .MouseWheel
        MouseButton : ImGuiInputEventMouseButton,    // if Type == .MouseButton
        MouseViewport : ImGuiInputEventMouseViewport, // if Type == .MouseViewport
        Key : ImGuiInputEventKey,            // if Type == .Key
        Text : ImGuiInputEventText,           // if Type == ImGuiInputEventType_Text
        AppFocused : ImGuiInputEventAppFocused,     // if Type == .Focus
    },
    AddedByTestEngine : bool,
};

// Input function taking an 'ImGuiID owner_id' argument defaults to (ImGuiKeyOwner_Any == 0) aka don't test ownership, which matches legacy behavior.
ImGuiKeyOwner_Any      ::       ImGuiID(0)    // Accept key that have an owner, UNLESS a call to SetKeyOwner() explicitly used ImGuiInputFlags_LockThisFrame or ImGuiInputFlags_LockUntilRelease.
ImGuiKeyOwner_NoOwner  ::       transmute(ImGuiID)i32(-1)   // Require key to have no owner.
//#define ImGuiKeyOwner_None ImGuiKeyOwner_NoOwner  // We previously called this 'ImGuiKeyOwner_None' but it was inconsistent with our pattern that _None values == 0 and quite dangerous. Also using _NoOwner makes the IsKeyPressed() calls more explicit.

ImGuiKeyRoutingIndex :: u16

// Routing table entry (size_of() == 16 bytes)
ImGuiKeyRoutingData :: struct
{
    NextEntryIndex : ImGuiKeyRoutingIndex,
    Mods : u16,               // Technically we'd only need 4-bits but for simplify we store ImGuiMod_ values which need 16-bits.
    RoutingCurrScore : u8,   // [DEBUG] For debug display
    RoutingNextScore : u8,   // Lower is better (0: perfect score)
    RoutingCurr : ImGuiID,
    RoutingNext : ImGuiID,
};

init_ImGuiKeyRoutingData :: proc(this : ^ImGuiKeyRoutingData) { this.NextEntryIndex = -1; this.Mods = 0; this.RoutingCurrScore = 255; this.RoutingNextScore = 255; this.RoutingCurr = ImGuiKeyOwner_NoOwner; this.RoutingNext = ImGuiKeyOwner_NoOwner; }


// Routing table: maintain a desired owner for each possible key-chord (key + mods), and setup owner in NewFrame() when mods are matching.
// Stored in main context (1 instance)
ImGuiKeyRoutingTable :: struct
{
    Index : [ImGuiKey.NamedKey_COUNT]ImGuiKeyRoutingIndex, // Index of first entry in Entries[]
    Entries : [dynamic]ImGuiKeyRoutingData,
    EntriesNext : [dynamic]ImGuiKeyRoutingData,                    // Double-buffer to avoid reallocation (could use a shared buffer)
};

init_ImGuiKeyRoutingTable :: proc(this : ^ImGuiKeyRoutingTable) { Clear(this); }
ImGuiKeyRoutingTable_Clear :: proc(this : ^ImGuiKeyRoutingTable) {
    this.Index = -1;
    this.Entries.clear();
    this.EntriesNext.clear();
}

// This extends ImGuiKeyData but only for named keys (legacy keys don't support the new features)
// Stored in main context (1 per named key). In the future it might be merged into ImGuiKeyData.
ImGuiKeyOwnerData :: struct
{
    OwnerCurr : ImGuiID,
    OwnerNext : ImGuiID,
    LockThisFrame : bool,      // Reading this key requires explicit owner id (until end of frame). Set by ImGuiInputFlags_LockThisFrame.
    LockUntilRelease : bool,   // Reading this key requires explicit owner id (until key is released). Set by ImGuiInputFlags_LockUntilRelease. When this is true LockThisFrame is always true as well.

};

init_ImGuiKeyOwnerData :: proc(this : ^ImGuiKeyOwnerData) {
    this.OwnerCurr = ImGuiKeyOwner_NoOwner;
    this.OwnerNext = ImGuiKeyOwner_NoOwner;
    this.LockThisFrame = false;
    LockUntilRelease = false;
}


// Extend ImGuiInputFlags_
// Flags for extended versions of IsKeyPressed(), IsMouseClicked(), Shortcut(), SetKeyOwner(), SetItemKeyOwner()
// Don't mistake with ImGuiInputTextFlags! (which is for ImGui::InputText() function)
ImGuiInputFlagsPrivate :: enum i32
{
    // Flags for IsKeyPressed(), IsKeyChordPressed(), IsMouseClicked(), Shortcut()
    // - Repeat mode: Repeat rate selection
    RepeatRateDefault           = 1 << 1,   // Repeat rate: Regular (default)
    RepeatRateNavMove           = 1 << 2,   // Repeat rate: Fast
    RepeatRateNavTweak          = 1 << 3,   // Repeat rate: Faster
    // - Repeat mode: Specify when repeating key pressed can be interrupted.
    // - In theory RepeatUntilOtherKeyPress may be a desirable default, but it would break too many behavior so everything is opt-in.
    RepeatUntilRelease          = 1 << 4,   // Stop repeating when released (default for all functions except Shortcut). This only exists to allow overriding Shortcut() default behavior.
    RepeatUntilKeyModsChange    = 1 << 5,   // Stop repeating when released OR if keyboard mods are changed (default for Shortcut)
    RepeatUntilKeyModsChangeFromNone = 1 << 6,  // Stop repeating when released OR if keyboard mods are leaving the None state. Allows going from Mod+Key to Key by releasing Mod.
    RepeatUntilOtherKeyPress    = 1 << 7,   // Stop repeating when released OR if any other keyboard key is pressed during the repeat

    // Flags for SetKeyOwner(), SetItemKeyOwner()
    // - Locking key away from non-input aware code. Locking is useful to make input-owner-aware code steal keys from non-input-owner-aware code. If all code is input-owner-aware locking would never be necessary.
    LockThisFrame               = 1 << 20,  // Further accesses to key data will require EXPLICIT owner ID (ImGuiKeyOwner_Any/0 will NOT accepted for polling). Cleared at end of frame.
    LockUntilRelease            = 1 << 21,  // Further accesses to key data will require EXPLICIT owner ID (ImGuiKeyOwner_Any/0 will NOT accepted for polling). Cleared when the key is released or at end of each frame if key is released.

    // - Condition for SetItemKeyOwner()
    CondHovered                 = 1 << 22,  // Only set if item is hovered (default to both)
    CondActive                  = 1 << 23,  // Only set if item is active (default to both)
    CondDefault_                = CondHovered | CondActive,

    // [Internal] Mask of which function support which flags
    RepeatRateMask_             = RepeatRateDefault | RepeatRateNavMove | RepeatRateNavTweak,
    RepeatUntilMask_            = RepeatUntilRelease | RepeatUntilKeyModsChange | RepeatUntilKeyModsChangeFromNone | RepeatUntilOtherKeyPress,
    RepeatMask_                 = i32(ImGuiInputFlags.Repeat) | i32(RepeatRateMask_ | RepeatUntilMask_),
    CondMask_                   = CondHovered | CondActive,
    RouteTypeMask_              = i32(ImGuiInputFlags{.RouteActive, .RouteFocused, .RouteGlobal, .RouteAlways }),
    RouteOptionsMask_           = i32(ImGuiInputFlags{ .RouteOverFocused, .RouteOverActive, .RouteUnlessBgFocused, .RouteFromRootWindow }),
    SupportedByIsKeyPressed     = RepeatMask_,
    SupportedByIsMouseClicked   = i32(ImGuiInputFlags.Repeat),
    SupportedByShortcut         = RepeatMask_ | RouteTypeMask_ | RouteOptionsMask_,
    SupportedBySetNextItemShortcut = i32(RepeatMask_ | RouteTypeMask_ | RouteOptionsMask_) | i32(ImGuiInputFlags.Tooltip),
    SupportedBySetKeyOwner      = LockThisFrame | LockUntilRelease,
    SupportedBySetItemKeyOwner  = SupportedBySetKeyOwner | CondMask_,
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
};

ImGuiListClipperRange_FromIndices :: proc(min, max : i32) -> ImGuiListClipperRange                               { return ImGuiListClipperRange{ min, max, false, 0, 0 } }
ImGuiListClipperRange_FromPositions :: proc(y1, y2 : f32, off_min, off_max : i32) -> ImGuiListClipperRange { return ImGuiListClipperRange{ cast(i32) y1, cast(i32) y2, true, cast(i8) off_min, cast(i8) off_max } }

// Temporary clipper data, buffers shared/reused between instances
ImGuiListClipperData :: struct
{
    ListClipper : ^ImGuiListClipper,
    LossynessOffset : f32,
    StepNo : i32,
    ItemsFrozen : i32,
    Ranges : [dynamic]ImGuiListClipperRange,
};

Reset :: proc(this : ^ImGuiListClipperData, clipper : ^ImGuiListClipper) { this.ListClipper = clipper; this.StepNo = 0; this.ItemsFrozen = 0; clear(&this.Ranges); }

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
ImGuiScrollFlags_MaskX_ :: ImGuiScrollFlags{ .KeepVisibleEdgeX , .KeepVisibleCenterX , .AlwaysCenterX }
ImGuiScrollFlags_MaskY_ :: ImGuiScrollFlags{ .KeepVisibleEdgeY , .KeepVisibleCenterY , .AlwaysCenterY }

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
ImGuiNavMoveFlags_WrapMask_ :: ImGuiNavMoveFlags{ .LoopX , .LoopY , .WrapX , .WrapY }

ImGuiNavLayer :: enum u32
{
    Main  = 0,    // Main scrolling layer
    Menu  = 1,    // Menu layer (access with Alt)
};

// Storage for navigation query/results
ImGuiNavItemData :: struct
{
    Window : ^ImGuiWindow,         // Init,Move    // Best candidate window (result.ItemWindow.RootWindowForNav == request.Window)
    ID : ImGuiID,             // Init,Move    // Best candidate item ID
    FocusScopeId : ImGuiID,   // Init,Move    // Best candidate focus scope ID
    RectRel : ImRect,        // Init,Move    // Best candidate bounding box in window relative space
    ItemFlags : ImGuiItemFlags,      // ????,Move    // Best candidate item flags
    DistBox : f32,        //      Move    // Best candidate box distance to current NavId
    DistCenter : f32,     //      Move    // Best candidate center distance to current NavId
    DistAxial : f32,      //      Move    // Best candidate axial distance to current NavId
    SelectionUserData : ImGuiSelectionUserData,//I+Mov    // Best candidate SetNextItemSelectionUserData() value. Valid if (.HasSelectionUserData in ItemFlags)
};

init_ImGuiNavItemData :: proc(this : ^ImGuiNavItemData)  { Clear(this); }
ImGuiNavItemData_Clear :: proc(this : ^ImGuiNavItemData)        { this.Window = nil; this.ID = 0; this.FocusScopeId = 0; this.ItemFlags = 0; this.SelectionUserData = -1; this.DistBox = math.F32_MAX; this.DistCenter = math.F32_MAX; this.DistAxial = math.F32_MAX; }

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
    LastRequestFrame : i32,
    LastRequestTime : f32,
    SingleCharModeLock : bool, // After a certain single char repeat count we lock into SingleCharMode. Two benefits: 1) buffer never fill, 2) we can provide an immediate SingleChar mode without timer elapsing.
};

ImGuiTypingSelectState_Clear :: proc(this : ^ImGuiTypingSelectState)  { this.SearchBuffer[0] = 0; this.SingleCharModeLock = false; } // We preserve remaining data for easier debugging

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
    using _ : bit_field u16 {
        KeyMods : ImGuiKeyChord | 16,       // Latched key-mods for box-select logic.
    },
    StartPosRel : ImVec2,        // Start position in window-contents relative space (to support scrolling)
    EndPosRel : ImVec2,          // End position in window-contents relative space
    ScrollAccum : ImVec2,        // Scrolling accumulator (to behave at high-frame spaces)
    Window : ^ImGuiWindow,

    // Temporary/Transient data
    UnclipMode : bool,         // (Temp/Transient, here in hot area). Set/cleared by the BeginMultiSelect()/EndMultiSelect() owning active box-select.
    UnclipRect : ImRect,         // Rectangle where ItemAdd() clipping may be temporarily disabled. Need support by multi-select supporting widgets.
    BoxSelectRectPrev : ImRect,  // Selection rectangle in absolute coordinates (derived every frame from BoxSelectStartPosRel and MousePos)
    BoxSelectRectCurr : ImRect,
};

//-----------------------------------------------------------------------------
// [SECTION] Multi-select support
//-----------------------------------------------------------------------------

// We always assume that -1 is an invalid value (which works for indices and pointers)
ImGuiSelectionUserData_Invalid ::      ImGuiSelectionUserData(-1)

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
};

init_ImGuiMultiSelectTempData :: proc(this : ^ImGuiMultiSelectTempData)  { Clear(this); }
ImGuiMultiSelectTempData_Clear :: proc(this : ^ImGuiMultiSelectTempData)  // Zero-clear except IO as we preserve IO.Requests[] buffer allocation.
{
    io_sz := size_of(IO);
    ClearIO(this);
    memset((rawptr)(mem.ptr_offset(&this.IO, 1)), 0, size_of(this^) - io_sz);
}
ClearIO :: proc(this : ^ImGuiMultiSelectTempData)
{
    clear(&this.IO.Requests)
    this.IO.RangeSrcItem = ImGuiSelectionUserData_Invalid;
    this.IO.NavIdItem = ImGuiSelectionUserData_Invalid;
    this.IO.NavIdSelected = false;
    this.IO.RangeSrcReset = false;
}

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
};

init_ImGuiMultiSelectState :: proc(this : ^ImGuiMultiSelectState) {
    this.Window = nil;
    this.ID = 0;
    this.LastFrameActive = 0;
    LastSelectionSize = 0;
    RangeSelected = -1;
    NavIdSelected = -1;
    RangeSrcItem = ImGuiSelectionUserData_Invalid;;
    NavIdItem = ImGuiSelectionUserData_Invalid;
}


//-----------------------------------------------------------------------------
// [SECTION] Docking support
//-----------------------------------------------------------------------------

DOCKING_HOST_DRAW_CHANNEL_BG :: 0  // Dock host: background fill
DOCKING_HOST_DRAW_CHANNEL_FG :: 1  // Dock host: decorations and contents

when IMGUI_HAS_DOCK {

// Extend ImGuiDockNodeFlags_
ImGuiDockNodeFlagsPrivate :: enum i32
{
    // [Internal]
    DockSpace                = 1 << 10,  // Saved // A dockspace is a node that occupy space within an existing user window. Otherwise the node is floating and create its own window.
    CentralNode              = 1 << 11,  // Saved // The central node has 2 main properties: stay visible when empty, only use "remaining" spaces from its neighbor.
    NoTabBar                 = 1 << 12,  // Saved // Tab bar is completely unavailable. No triangle in the corner to enable it back.
    HiddenTabBar             = 1 << 13,  // Saved // Tab bar is hidden, with a triangle in the corner to show it again (NB: actual tab-bar instance may be destroyed as this is only used for single-window tab bar)
    NoWindowMenuButton       = 1 << 14,  // Saved // Disable window/docking menu (that one that appears instead of the collapse button)
    NoCloseButton            = 1 << 15,  // Saved // Disable close button
    NoResizeX                = 1 << 16,  //       //
    NoResizeY                = 1 << 17,  //       //
    DockedWindowsInFocusRoute= 1 << 18,  //       // Any docked window will be automatically be focus-route chained (window.ParentWindowForFocusRoute set to this) so Shortcut() in this window can run when any docked window is focused.

    // Disable docking/undocking actions in this dockspace or individual node (existing docked nodes will be preserved)
    // Those are not exposed in public because the desirable sharing/inheriting/copy-flag-on-split behaviors are quite difficult to design and understand.
    // The two public flags ImGuiDockNodeFlags_NoDockingOverCentralNode/ImGuiDockNodeFlags_NoDockingSplit don't have those issues.
    NoDockingSplitOther      = 1 << 19,  //       // Disable this node from splitting other windows/nodes.
    NoDockingOverMe          = 1 << 20,  //       // Disable other windows/nodes from being docked over this node.
    NoDockingOverOther       = 1 << 21,  //       // Disable this node from being docked over another window or non-empty node.
    NoDockingOverEmpty       = 1 << 22,  //       // Disable this node from being docked over an empty node (e.g. DockSpace with no other windows)
    NoDocking                = i32(NoDockingOverMe | NoDockingOverOther | NoDockingOverEmpty) | i32(ImGuiDockNodeFlags.NoDockingSplit) | i32(NoDockingSplitOther),

    // Masks
    SharedFlagsInheritMask_  = ~i32(0),
    NoResizeFlagsMask_       = i32(ImGuiDockNodeFlags.NoResize) | i32(NoResizeX | NoResizeY),

    // When splitting, those local flags are moved to the inheriting child, never duplicated
    LocalFlagsTransferMask_  = i32(ImGuiDockNodeFlags.NoDockingSplit) | i32(NoResizeFlagsMask_) | i32(ImGuiDockNodeFlags.AutoHideTabBar) | i32(CentralNode | NoTabBar | HiddenTabBar | NoWindowMenuButton | NoCloseButton),
    SavedFlagsMask_          = NoResizeFlagsMask_ | DockSpace | CentralNode | NoTabBar | HiddenTabBar | NoWindowMenuButton | NoCloseButton,
};

// Store the source authority (dock node vs window) of a field
ImGuiDataAuthority :: enum i32
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

// size_of() 156~192
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
    Windows : [dynamic]^ImGuiWindow,                    // Note: unordered list! Iterate TabBar.Tabs for user-order.
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
    using _ : bit_field u32 {
        AuthorityForPos        : ImGuiDataAuthority  | 3,
        AuthorityForSize       : ImGuiDataAuthority  | 3,
        AuthorityForViewport   : ImGuiDataAuthority  | 3,
        IsVisible              : bool                | 1, // Set to false when the node is hidden (usually disabled as it has no active window)
        IsFocused              : bool                | 1,
        IsBgDrawnThisFrame     : bool                | 1,
        HasCloseButton         : bool                | 1, // Provide space for a close button (if any of the docked window has one). Note that button may be hidden on window without one.
        HasWindowMenuButton    : bool                | 1,
        HasCentralNodeChild    : bool                | 1,
        WantCloseAll           : bool                | 1, // Set when closing all tabs at once.
        WantLockSizeOnce       : bool                | 1,
        WantMouseMove          : bool                | 1, // After a node extraction we need to transition toward moving the newly created host window
        WantHiddenTabBarUpdate : bool                | 1,
        WantHiddenTabBarToggle : bool                | 1,
    },
};
IsRootNode     :: proc(this : ^ImGuiDockNode) -> bool   { return this.ParentNode == nil; }
IsDockSpace    :: proc(this : ^ImGuiDockNode) -> bool   { return (this.MergedFlags & .DockSpace) != 0; }
IsFloatingNode :: proc(this : ^ImGuiDockNode) -> bool   { return this.ParentNode == nil && (this.MergedFlags & .DockSpace) == 0; }
IsCentralNode  :: proc(this : ^ImGuiDockNode) -> bool   { return (this.MergedFlags & .CentralNode) != 0; }
IsHiddenTabBar :: proc(this : ^ImGuiDockNode) -> bool   { return (this.MergedFlags & .HiddenTabBar) != 0; } // Hidden tab bar can be shown back by clicking the small triangle
IsNoTabBar     :: proc(this : ^ImGuiDockNode) -> bool   { return (this.MergedFlags & .NoTabBar) != 0; }     // Never show a tab bar
IsSplitNode    :: proc(this : ^ImGuiDockNode) -> bool   { return this.ChildNodes[0] != nil; }
IsLeafNode     :: proc(this : ^ImGuiDockNode) -> bool   { return this.ChildNodes[0] == nil; }
IsEmpty        :: proc(this : ^ImGuiDockNode) -> bool   { return this.ChildNodes[0] == nil && len(this.Windows) == 0; }
ImGuiDockNode_Rect:: proc(this : ^ImGuiDockNode) -> ImRect { return ImRect{ _r = {this.Pos.x, this.Pos.y, this.Pos.x + this.Size.x, this.Pos.y + this.Size.y}}; }

SetLocalFlags :: proc(this : ^ImGuiDockNode, flags : ImGuiDockNodeFlags) { this.LocalFlags = flags; UpdateMergedFlags(this); }
UpdateMergedFlags :: proc(this : ^ImGuiDockNode)     { this.MergedFlags = this.SharedFlags | this.LocalFlags | this.LocalFlagsInWindows; }


// List of colors that are stored at the time of Begin() into Docked Windows.
// We currently store the packed colors in a simple array window.DockStyle.Colors[].
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
};

// We don't store style.Alpha: dock_node.LastBgColor embeds it and otherwise it would only affect the docking tab, which intuitively I would say we don't want to.
ImGuiWindowDockStyle :: struct
{
    Colors : [ImGuiWindowDockStyleCol]u32,
};

ImGuiDockContext :: struct
{
    Nodes : ImGuiStorage,          // Map ID -> ImGuiDockNode*: Active nodes
    Requests : [dynamic]ImGuiDockRequest,
    NodesSettings : [dynamic]ImGuiDockNodeSettings,
    WantFullRebuild : bool,
};

} // #ifdef IMGUI_HAS_DOCK

//-----------------------------------------------------------------------------
// [SECTION] Viewport support
//-----------------------------------------------------------------------------

// ImGuiViewport Private/Internals fields (cardinal sin: we are using inheritance!)
// Every instance of ImGuiViewport is in fact a ImGuiViewportP.
ImGuiViewportP :: struct
{
    using _viewpoert : ImGuiViewport,
    Window : ^ImGuiWindow,                 // Set when the viewport is owned by a window (and ImGuiViewportFlags_CanHostOtherWindows is NOT set)
    Idx : i32,
    LastFrameActive : i32,        // Last frame number this viewport was activated by a window
    LastFocusedStampCount : i32,  // Last stamp number from when a window hosted by this viewport was focused (by comparing this value between two viewport we have an implicit viewport z-order we use as fallback)
    LastNameHash : ImGuiID,
    LastPos : ImVec2,
    LastSize : ImVec2,
    Alpha : f32,                  // Window opacity (when dragging dockable windows/viewports we make them transparent)
    LastAlpha : f32,
    LastFocusedHadNavWindow : bool, // Instead of maintaining a LastFocusedWindow (which may harder to correctly maintain), we merely store weither NavWindow != NULL last time the viewport was focused.
    PlatformMonitor : i16,
    BgFgDrawListsLastFrame : [2]i32, // Last frame number the background (0) and foreground (1) draw lists were used
    BgFgDrawLists : [2]^ImDrawList,       // Convenience background (0) and foreground (1) draw lists. We use them to draw software mouser cursor when io.MouseDrawCursor is set and to draw most debug overlays.
    DrawDataP : ImDrawData,
    DrawDataBuilder : ImDrawDataBuilder,        // Temporary data while building final ImDrawData
    LastPlatformPos : ImVec2,
    LastPlatformSize : ImVec2,
    LastRendererSize : ImVec2,

    // Per-viewport work area
    // - Insets are >= 0.0f values, distance from viewport corners to work area.
    // - BeginMainMenuBar() and DockspaceOverViewport() tend to use work area to avoid stepping over existing contents.
    // - Generally 'safeAreaInsets' in iOS land, 'DisplayCutout' in Android land.
    WorkInsetMin : ImVec2,           // Work Area inset locked for the frame. GetWorkRect() always fits within GetMainRect().
    WorkInsetMax : ImVec2,           // "
    BuildWorkInsetMin : ImVec2,      // Work Area inset accumulator for current frame, to become next frame's WorkInset
    BuildWorkInsetMax : ImVec2,      // "
};

init_ImGuiViewportP :: proc(this : ^ImGuiViewportP) {
    init_ImGuiViewport(&this._viewport)
    this.Window = nil
    this.Idx = -1
    this.LastFrameActive = -1;
    this.BgFgDrawListsLastFrame[0] = -1;
    this.BgFgDrawListsLastFrame[1] = -1;
    this.LastFocusedStampCount = -1
    this.LastNameHash = 0
    this.Alpha = 1.0;
    LastAlpha = 1.0
    this.LastFocusedHadNavWindow = false
    this.PlatformMonitor = -1
    this.BgFgDrawLists[0] = nil;
    this.BgFgDrawLists[1] = nil
    maxf := ImVec2{math.F32_MAX, math.F32_MAX}
    this.LastPlatformPos = maxf;
    this.LastPlatformSize = maxf;
    this.LastRendererSize = maxf
}
deinit_ImGuiViewportP :: proc(this : ^ImGuiViewportP)                   { if (this.BgFgDrawLists[0]) do IM_DELETE(this.BgFgDrawLists[0]); if (this.BgFgDrawLists[1]) do IM_DELETE(this.BgFgDrawLists[1]); }
ClearRequestFlags :: proc(this : ^ImGuiViewportP)         { this.PlatformRequestClose = false; this.PlatformRequestMove = false; this.PlatformRequestResize = false; }

// Calculate work rect pos/size given a set of offset (we have 1 pair of offset for rect locked from last frame data, and 1 pair for currently building rect)
CalcWorkRectPos :: proc(this : ^ImGuiViewportP, inset_min : ImVec2)                     -> ImVec2 { return this.Pos + inset_min; }
CalcWorkRectSize :: proc(this : ^ImGuiViewportP, inset_min, inset_max : ImVec2) -> ImVec2 { return ImVec2{ImMax(0.0, this.Size.x - inset_min.x - inset_max.x), ImMax(0.0, this.Size.y - inset_min.y - inset_max.y)}; }
UpdateWorkRect :: proc(this : ^ImGuiViewportP)            { this.WorkPos = CalcWorkRectPos(this, this.WorkInsetMin); this.WorkSize = CalcWorkRectSize(this, this.WorkInsetMin, this.WorkInsetMax); } // Update public fields

// Helpers to retrieve ImRect (we don't need to store BuildWorkRect as every access tend to change it, hence the code asymmetry)
GetMainRect :: proc(this : ^ImGuiViewportP)  -> ImRect       { return ImRect{ _r = {this.Pos.x, this.Pos.y, this.Pos.x + Size.x, this.Pos.y + Size.y}}; }
GetWorkRect :: proc(this : ^ImGuiViewportP)  -> ImRect       { return ImRect{ _r = {this.WorkPos.x, this.WorkPos.y, this.WorkPos.x + this.WorkSize.x, this.WorkPos.y + this.WorkSize.y}}; }
GetBuildWorkRect :: proc(this : ^ImGuiViewportP)  -> ImRect  { pos := CalcWorkRectPos(this, this.BuildWorkInsetMin); size := CalcWorkRectSize(this, this.BuildWorkInsetMin, this.BuildWorkInsetMax); return ImRect{ _r = {pos.x, pos.y, pos.x + size.x, pos.y + size.y}}; }

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
};

init_ImGuiWindowSettings :: proc(this : ^ImGuiWindowSettings)       { this^ = {}; this.DockOrder = -1; }
GetName :: proc(this : ^ImGuiWindowSettings) -> ^u8             { return cast(^u8)(this + 1); }

ImGuiSettingsHandler :: struct
{
    TypeName : string,       // Short description stored in .ini file. Disallowed characters: '[' ']'
    TypeHash : ImGuiID,       // == ImHashStr(TypeName)
    ClearAllFn : proc(ctx : ^ImGuiContext, handler : ^ImGuiSettingsHandler),                                // Clear all settings data
    ReadInitFn : proc(ctx : ^ImGuiContext, handler : ^ImGuiSettingsHandler),                                // Read: Called before reading (in registration order)
    ReadOpenFn : proc(ctx : ^ImGuiContext, handler : ^ImGuiSettingsHandler, name : ^u8) -> rawptr,              // Read: Called when entering into a new ini entry e.g. "[Window][Name]"
    ReadLineFn : proc(ctx : ^ImGuiContext, handler : ^ImGuiSettingsHandler, entry : rawptr, line : ^u8), // Read: Called for every line of text within an ini entry
    ApplyAllFn : proc(ctx : ^ImGuiContext, handler : ^ImGuiSettingsHandler),                                // Read: Called after reading (in registration order)
    WriteAllFn : proc(ctx : ^ImGuiContext, handler : ^ImGuiSettingsHandler, out_buf : ^ImGuiTextBuffer),      // Write: Output every entries into 'out_buf'
    UserData : rawptr,
};

//-----------------------------------------------------------------------------
// [SECTION] Localization support
//-----------------------------------------------------------------------------

// This is experimental and not officially supported, it'll probably fall short of features, if/when it does we may backtrack.
ImGuiLocKey :: enum i32
{
    VersionStr,
    TableSizeOne,
    TableSizeAllFit,
    TableSizeAllDefault,
    TableResetOrder,
    WindowingMainMenuBar,
    WindowingPopup,
    WindowingUntitled,
    OpenLink_s,
    CopyLink,
    DockingHideTabBar,
    DockingHoldShiftToDock,
    DockingDragToUndockOrMoveNode,
};

ImGuiLocEntry :: struct
{
    Key : ImGuiLocKey,
    Text : string,
};

//-----------------------------------------------------------------------------
// [SECTION] Error handling, State recovery support
//-----------------------------------------------------------------------------

// Macros used by Recoverable Error handling
// - Only dispatch error if _EXPR: evaluate as assert (similar to an assert macro).
// - The message will always be a string literal, in order to increase likelihood of being display by an assert handler.
// - See 'Demo->Configuration->Error Handling' and ImGuiIO definitions for details on error handling.
// - Read https://github.com/ocornut/imgui/wiki/Error-Handling for details on error handling.

IM_ASSERT_USER_ERROR :: proc(_EXPR : bool, _MSG := #caller_expression) // Recoverable User Error
{
    if (!_EXPR && ErrorLog(_MSG)) { assert(_EXPR, _MSG); }
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
ImGuiDebugLogFlags_EventMask_ :: ImGuiDebugLogFlags{ .EventError , .EventActiveId , .EventFocus , .EventPopup , .EventNav , .EventClipper , .EventSelection , .EventIO , .EventFont , .EventInputRouting , .EventDocking , .EventViewport }

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
};

ImGuiMetricsConfig :: struct
{
    ShowDebugLog : bool,
    ShowIDStackTool : bool,
    ShowWindowsRects : bool,
    ShowWindowsBeginOrder : bool,
    ShowTablesRects : bool,
    ShowDrawCmdMesh : bool,
    ShowDrawCmdBoundingBoxes : bool,
    ShowTextEncodingViewer : bool,
    ShowAtlasTintedWithTextColor : bool,
    ShowDockingNodes : bool,
    ShowWindowsRectsType : i32,
    ShowTablesRectsType : i32,
    HighlightMonitorIdx : i32,
    HighlightViewportID : ImGuiID,
};

init_ImGuiMetricsConfig :: proc(this : ^ImGuiMetricsConfig) {
    this^ = {}
    this.ShowDrawCmdMesh = true;
    this.ShowDrawCmdBoundingBoxes = true;
    this.ShowWindowsRectsType = -1;
    this.ShowTablesRectsType = -1;
    this.HighlightMonitorIdx = -1;
}

ImGuiStackLevelInfo :: struct
{
    ID : ImGuiID,
    QueryFrameCount : i8,            // >= 1: Query in progress
    QuerySuccess : bool,               // Obtained result from DebugHookIdInfo()
    using _ : bit_field u8 {
        DataType : ImGuiDataType | 8,
    },
    Desc : [57]u8,                   // Arbitrarily sized buffer to hold a result (FIXME: could replace Results[] with a chunk stream?) FIXME: Now that we added CTRL+C this should be fixed.
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
};

init_ImGuiIDStackTool :: proc(this : ^ImGuiIDStackTool)      { this^ = {}; this.CopyToClipboardLastTime = -math.F32_MAX; }

//-----------------------------------------------------------------------------
// [SECTION] Generic context hooks
//-----------------------------------------------------------------------------

ImGuiContextHookCallback :: #type proc(ctx : ^ImGuiContext, hook : ^ImGuiContextHook)
ImGuiContextHookType :: enum {
    NewFramePre,
    NewFramePost,
    EndFramePre,
    EndFramePost,
    RenderPre,
    RenderPost,
    Shutdown,
    PendingRemoval_
};

ImGuiContextHook :: struct
{
    HookId : ImGuiID,     // A unique ID assigned by AddContextHook()
    Type : ImGuiContextHookType,
    Owner : ImGuiID,
    Callback : ImGuiContextHookCallback,
    UserData : rawptr,
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
    FontSize : f32,                           // (Shortcut) == FontBaseSize * g.CurrentWindow.FontWindowScale == window.FontSize(). Text height for current window.
    FontBaseSize : f32,                       // (Shortcut) == IO.FontGlobalScale * Font.Scale * Font.FontSize. Base text height.
    FontScale : f32,                          // == FontSize / Font.FontSize
    CurrentDpiScale : f32,                    // Current window/viewport DpiScale == CurrentViewport.DpiScale
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
    MovingWindow : ^ImGuiWindow,                       // Track the window we clicked on (in order to preserve focus). The actual window that is moved is generally MovingWindow.RootWindowDockTree.
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
    using _ : bit_field u8 {
        ActiveIdMouseButton : i32 | 8,
    },
    ActiveIdClickOffset : ImVec2,                // Clicked offset from upper-left corner, if applicable (currently only set by ButtonBehavior)
    ActiveIdWindow : ^ImGuiWindow,
    ActiveIdSource : ImGuiInputSource,                     // Activating source: .Mouse OR .Keyboard OR .Gamepad
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
    KeysMayBeCharInput : ImBitArrayForNamedKeys,                 // Lookup to tell if a key can emit char input, see IsKeyChordPotentiallyCharInput(). size_of() = 20 bytes
    KeysOwnerData : [ImGuiKey.NamedKey_COUNT]ImGuiKeyOwnerData,
    KeysRoutingTable : ImGuiKeyRoutingTable,
    ActiveIdUsingNavDirMask : u32,            // Active widget will want to read those nav move requests (e.g. can activate a button and move away from it)
    ActiveIdUsingAllKeyboardKeys : bool,       // Active widget will want to read all keyboard keys inputs. (this is a shortcut for not taking ownership of 100+ keys, frequently used by drag operations)
    DebugBreakInShortcutRouting : ImGuiKeyChord,        // Set to break in SetShortcutRouting()/Shortcut() calls.
    //ImU32                 ActiveIdUsingNavInputMask;          // [OBSOLETE] Since (IMGUI_VERSION_NUM >= 18804) : 'g.ActiveIdUsingNavInputMask |= (1 << ImGuiNavInput_Cancel);' becomes --> 'SetKeyOwner(ImGuiKey.Escape, g.ActiveId) and/or SetKeyOwner(ImGuiKey.NavGamepadCancel, g.ActiveId);'

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
    TreeNodeStack : [dynamic]ImGuiTreeNodeStackData,              // Stack for TreeNode()

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
    NavActivateId : ImGuiID,                      // ~~ (g.ActiveId == 0) && (IsKeyPressed(ImGuiKey.Space) || IsKeyDown(ImGuiKey.Enter) || IsKeyPressed(ImGuiKey_NavGamepadActivate(g))) ? NavId : 0, also set when calling ActivateItem()
    NavActivateDownId : ImGuiID,                  // ~~ IsKeyDown(ImGuiKey.Space) || IsKeyDown(ImGuiKey.Enter) || IsKeyDown(ImGuiKey_NavGamepadActivate(g)) ? NavId : 0
    NavActivatePressedId : ImGuiID,               // ~~ IsKeyPressed(ImGuiKey.Space) || IsKeyPressed(ImGuiKey.Enter) || IsKeyPressed(ImGuiKey_NavGamepadActivate(g)) ? NavId : 0 (no repeat)
    NavActivateFlags : ImGuiActivateFlags,
    NavFocusRoute : [dynamic]ImGuiFocusScopeData,                // Reversed copy focus scope stack for NavId (should contains NavFocusScopeId). This essentially follow the window.ParentWindowForFocusRoute chain.
    NavHighlightActivatedId : ImGuiID,
    NavHighlightActivatedTimer : f32,
    NavNextActivateId : ImGuiID,                  // Set by ActivateItem(), queued until next frame.
    NavNextActivateFlags : ImGuiActivateFlags,
    NavInputSource : ImGuiInputSource,                     // Keyboard or Gamepad mode? THIS CAN ONLY BE .Keyboard or .Mouse
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
    NavScoringRect : ImRect,                     // Rectangle used for scoring, in screen space. Based of window.NavRectRel[], modified for directional navigation scoring.
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
    ConfigNavWindowingKeyNext : ImGuiKeyChord,          // = ImGuiKey.Mod_Ctrl | ImGuiKey.Tab (or ImGuiKey.Mod_Super | ImGuiKey.Tab on OS X). For reconfiguration (see #4828)
    ConfigNavWindowingKeyPrev : ImGuiKeyChord,          // = ImGuiKey.Mod_Ctrl | ImGuiKey.Mod_Shift | ImGuiKey.Tab (or ImGuiKey.Mod_Super | ImGuiKey.Mod_Shift | ImGuiKey.Tab on OS X)
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
    Tables : ImPool(ImGuiTable),                     // Persistent table data
    TablesLastTimeActive : [dynamic]f32,       // Last used timestamp of each tables (SOA, for efficient GC)
    DrawChannelsTempMergeBuffer : [dynamic]ImDrawChannel,

    // Tab bars
    CurrentTabBar : ^ImGuiTabBar,
    TabBars : ImPool(ImGuiTabBar),
    CurrentTabBarStack : [dynamic]ImGuiPtrOrIndex,
    ShrinkWidthBuffer : [dynamic]ImGuiShrinkWidthItem,

    // Multi-Select state
    BoxSelectState : ImGuiBoxSelectState,
    CurrentMultiSelect : ^ImGuiMultiSelectTempData,
    MultiSelectTempDataStacked : i32, // Temporary multi-select data size (because we leave previous instances undestructed, we generally don't use MultiSelectTempData.Size)
    MultiSelectTempData : [dynamic]ImGuiMultiSelectTempData,
    MultiSelectStorage : ImPool(ImGuiMultiSelectState),

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
    DockNodeWindowMenuHandler : proc(ctx : ^ImGuiContext, node : ^ImGuiDockNode, tab_bar : ^ImGuiTabBar),

    // Settings
    SettingsLoaded : bool,
    SettingsDirtyTimer : f32,                 // Save .ini Settings to memory when time reaches zero
    SettingsIniData : ImGuiTextBuffer,                    // In memory .ini settings
    SettingsHandlers : [dynamic]ImGuiSettingsHandler,       // List of .ini settings handlers
    SettingsWindows : ImChunkStream(ImGuiWindowSettings),        // ImGuiWindow .ini settings entries
    SettingsTables : ImChunkStream(ImGuiTableSettings),         // ImGuiTable .ini settings entries
    Hooks : [dynamic]ImGuiContextHook,                  // Hooks for extensions (e.g. test engine)
    HookIdNext : ImGuiID,             // Next available HookId

    // Localization
    LocalizationTable : [ImGuiLocKey]string,

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
    StackSizesInBeginForCurrentWindow : ^ImGuiErrorRecoveryState,  // [Internal]

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
    DebugBreakKeyChord : ImGuiKeyChord,                 // = ImGuiKey.Pause
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
    ColumnsOffset : ImVec1,          // Offset to the current column (if ColumnsCurrent > 0). FIXME: This and the above should be a stack to allow use cases like Tree.Column.Tree. Need revamp columns API.
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
    TreeDepth : u32, //i32,              // Current tree depth.
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
    Name : string,                               // Window name, owned by the window.
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
    //NameBufLen : i32,                         // Size of buffer storing Name. May be larger than strlen(Name)!
    MoveId : ImGuiID,                             // == GetID(window, "#MOVE")
    TabId : ImGuiID,                              // == GetID(window, "#TAB")
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
    using _ : bit_field u32 {
        SetWindowPosAllowFlags       : ImGuiCond | 8, // store acceptable condition flags for SetNextWindowPos() use.
        SetWindowSizeAllowFlags      : ImGuiCond | 8, // store acceptable condition flags for SetNextWindowSize() use.
        SetWindowCollapsedAllowFlags : ImGuiCond | 8, // store acceptable condition flags for SetNextWindowCollapsed() use.
        SetWindowDockAllowFlags      : ImGuiCond | 8, // store acceptable condition flags for SetNextWindowDock() use.
    },
    SetWindowPosVal : ImVec2,                    // store window position when using a non-zero Pivot (position set needs to be processed when we know the window size)
    SetWindowPosPivot : ImVec2,                  // store window pivot for positioning. ImVec2{0, 0} when positioning from top-left corner; ImVec2{0.5f, 0.5f} for centering; ImVec2{1, 1} for bottom right.

    IDStack : [dynamic]ImGuiID,                            // ID stack. ID are hashes seeded with the value at the top of the stack. (In theory this should be in the TempData structure)
    DC : ImGuiWindowTempData,                                 // Temporary per-window data, reset at the beginning of the frame. This used to be called ImGuiDrawContext, hence the "DC" variable name.

    // The best way to understand what those rectangles are is to use the 'Metrics.Tools.Show Windows Rectangles' viewer.
    // The main 'OuterRect', omitted as a field, is Rect(window).
    OuterRectClipped : ImRect,                   // == Window.Rect() just after setup in Begin(). == Rect(window) for root window.
    InnerRect : ImRect,                          // Inner rectangle (omit title bar, menu bar, scroll bar)
    InnerClipRect : ImRect,                      // == InnerRect shrunk by WindowPadding*0.5f on each side, clipped within viewport or parent clip rect.
    WorkRect : ImRect,                           // Initially covers the whole scrolling region. Reduced by containers e.g columns/tables when active. Shrunk by WindowPadding*1.0f on each side. This is meant to replace ContentRegionRect over time (from 1.71+ onward).
    ParentWorkRect : ImRect,                     // Backup of WorkRect before entering a container such as columns/tables. Used by e.g. SpanAllColumns functions to easily access. Stacked containers are responsible for maintaining this. // FIXME-WORKRECT: Could be a stack?
    ClipRect : ImRect,                           // Current clipping/scissoring rectangle, evolve as we are using PushClipRect(), etc. == DrawList.clip_rect_stack.back().
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
    NavLastIds : [ImGuiNavLayer]ImGuiID,    // Last known NavId for this window, per layer (0/1)
    NavRectRel : [ImGuiNavLayer]ImRect,    // Reference rectangle, in window relative space
    NavPreferredScoringPosRel : [ImGuiNavLayer]ImVec2, // Preferred X/Y position updated when moving on a given axis, reset to FLT_MAX.
    NavRootFocusScopeId : ImGuiID,                // Focus Scope ID at the time of Begin()

    MemoryDrawListIdxCapacity : i32,          // Backup of last idx/vtx count, so when waking up the window we can preallocate and avoid iterative alloc/copy
    MemoryDrawListVtxCapacity : i32,
    MemoryCompacted : bool,                    // Set when window extraneous data have been garbage collected

    // Docking
    using _1 : bit_field u8 {
        DockIsActive        : bool | 1,             // When docking artifacts are actually visible. When this is set, DockNode is guaranteed to be != NULL. ~~ (DockNode != NULL) && (len(DockNode.Windows) > 1).
        DockNodeIsVisible   : bool | 1,
        DockTabIsVisible    : bool | 1,             // Is our window visible this frame? ~~ is the corresponding tab selected?
        DockTabWantClose    : bool | 1,
    },
    DockOrder : i16,                          // Order of the last time the window was visible within its DockNode. This is used to reorder windows that are reappearing on the same frame. Same value between windows that were active and windows that were none are possible.
    DockStyle : ImGuiWindowDockStyle,
    DockNode : ^ImGuiDockNode,                           // Which node are we docked into. Important: Prefer testing DockIsActive in many cases as this will still be set when the dock node is hidden.
    DockNodeAsHost : ^ImGuiDockNode,                     // Which node are we owning (for parent windows)
    DockId : ImGuiID,                             // Backup of last valid DockNode.ID, so single window remember their dock node id even when they are not bound any more
    DockTabItemStatusFlags : ImGuiItemStatusFlags,
    DockTabItemRect : ImRect,
};

// We don't use g.FontSize because the window may be != g.CurrentWindow.
ImGuiWindow_Rect :: proc(this : ^ImGuiWindow) -> ImRect  { return ImRect{ _r = {this.Pos.x, this.Pos.y, this.Pos.x + this.Size.x, this.Pos.y + this.Size.y}}; }
CalcFontSize :: proc(this : ^ImGuiWindow) -> f32     { g := this.Ctx; scale := g.FontBaseSize * this.FontWindowScale * this.FontDpiScale; if (this.ParentWindow != nil) do scale *= this.ParentWindow.FontWindowScale; return scale; }
TitleBarRect :: proc(this : ^ImGuiWindow) -> ImRect  { return ImRect{ _v = {Pos, ImVec2{Pos.x + SizeFull.x, Pos.y + TitleBarHeight}}}; }
MenuBarRect  :: proc(this : ^ImGuiWindow) -> ImRect  { y1 := this.Pos.y + this.TitleBarHeight; return ImRect{ _r = {this.Pos.x, y1, this.Pos.x + this.SizeFull.x, y1 + this.MenuBarHeight}}; }


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
ImGuiTabItemFlagsPrivate :: enum i32
{
    ImGuiTabItemFlags_SectionMask_              = i32(ImGuiTabItemFlags.Leading | ImGuiTabItemFlags.Trailing),
    ImGuiTabItemFlags_NoCloseButton             = 1 << 20,  // Track whether p_open was set or not (we'll need this info on the next frame to recompute ContentWidth during layout)
    ImGuiTabItemFlags_Button                    = 1 << 21,  // Used by TabItemButton, change the tab item behavior to mimic a button
    ImGuiTabItemFlags_Unsorted                  = 1 << 22,  // [Docking] Trailing tabs with the _Unsorted flag will be sorted based on the DockOrder of their Window.
};

// Storage for one active tab item (size_of() 48 bytes)
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

};

init_ImGuiTabItem :: proc(this : ^ImGuiTabItem)      { this^ = {}; this.LastFrameVisible = -1; this.LastFrameSelected = -1; this.RequestedWidth = -1.0; this.NameOffset = -1; this.BeginOrder = -1; this.IndexDuringLayout = -1; }

// Storage for a tab bar (size_of() 160 bytes)
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
};

//-----------------------------------------------------------------------------
// [SECTION] Table support
//-----------------------------------------------------------------------------

IM_COL32_DISABLE ::     0x01000000           //IM_COL32(0,0,0,1)   // Special sentinel code which cannot be used as a regular color.
IMGUI_TABLE_MAX_COLUMNS :: 512                 // May be further lifted

// Our current column maximum is 64 but we may raise that in the future.
ImGuiTableColumnIdx :: i16
ImGuiTableDrawChannelIdx :: u16

// [Internal] size_of() ~ 112
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
    NameOffset : i16,                     // Offset into parent ColumnsNames[]
    DisplayOrder : ImGuiTableColumnIdx,                   // Index within Table's IndexToDisplayOrder[] (column may be reordered by users)
    IndexWithinEnabledSet : ImGuiTableColumnIdx,          // Index within enabled/visible set (<= IndexToDisplayOrder)
    PrevEnabledColumn : ImGuiTableColumnIdx,              // Index of prev enabled/visible column within Columns[], -1 if first enabled/visible column
    NextEnabledColumn : ImGuiTableColumnIdx,              // Index of next enabled/visible column within Columns[], -1 if last enabled/visible column
    SortOrder : ImGuiTableColumnIdx,                      // Index of this column within sort specs, -1 if not sorting on this column, 0 for single-sort, may be >0 on multi-sort
    DrawChannelCurrent : ImGuiTableDrawChannelIdx,            // Index within DrawSplitter.Channels[]
    DrawChannelFrozen : ImGuiTableDrawChannelIdx,             // Draw channels for frozen rows (often headers)
    DrawChannelUnfrozen : ImGuiTableDrawChannelIdx,           // Draw channels for unfrozen rows
    IsEnabled : bool,                      // IsUserEnabled && (.Disabled not_in flags)
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
    using _ : bit_field u8 {
        SortDirection            : u8 | 2,              // ImGuiSortDirection_Ascending or ImGuiSortDirection_Descending
        SortDirectionsAvailCount : u8 | 2,   // Number of available sort directions (0 to 3)
        SortDirectionsAvailMask  : u8 | 4,    // Mask of available sort directions (1-bit each)
    },
    SortDirectionsAvailList : u8,        // Ordered list of available sort directions (2-bits each, total 8-bits)
};

init_ImGuiTableColumn :: proc(this : ^ImGuiTableColumn)
{
    this^ = {}
    this.StretchWeight = -1;
    this.WidthRequest = -1.0;
    this.NameOffset = -1;
    this.DisplayOrder = -1;
    this.IndexWithinEnabledSet = -1;
    this.PrevEnabledColumn = -1;
    this.NextEnabledColumn = -1;
    this.SortOrder = -1;
    this.SortDirection = 0;
    this.DrawChannelCurrent  = ~u16(0);
    this.DrawChannelFrozen   = ~u16(0);
    this.DrawChannelUnfrozen = ~u16(0);
}

make_ImGuiTableColumn :: #force_inline proc() -> (tc : ImGuiTableColumn)
{
    init_ImGuiTableColumn(&tc)
    return
}

// Transient cell data stored per row.
// size_of() ~ 6 bytes
ImGuiTableCellData :: struct
{
    BgColor : u32,    // Actual color
    Column : ImGuiTableColumnIdx,     // Column number
};

// Parameters for TableAngledHeadersRowEx()
// This may end up being refactored for more general purpose.
// size_of() ~ 12 bytes
ImGuiTableHeaderData :: struct
{
    Index : ImGuiTableColumnIdx,      // Column index
    TextColor : u32,
    BgColor0 : u32,
    BgColor1 : u32,
};

// Per-instance data that needs preserving across frames (seemingly most others do not need to be preserved aside from debug needs. Does that means they could be moved to ImGuiTableTempData?)
// size_of() ~ 24 bytes
ImGuiTableInstanceData :: struct
{
    TableInstanceID : ImGuiID,
    LastOuterHeight : f32,            // Outer height from last frame
    LastTopHeadersRowHeight : f32,    // Height of first consecutive header rows from last frame (FIXME: this is used assuming consecutive headers are in same frozen set)
    LastFrozenHeight : f32,           // Height of frozen section from last frame
    HoveredRowLast : i32,             // Index of row which was hovered last frame.
    HoveredRowNext : i32,             // Index of row hovered this frame, set after encountering it.
};

init_ImGuiTableInstanceData :: proc(this : ^ImGuiTableInstanceData) {
    this^ = {}
    this.HoveredRowLast = -1
    this.HoveredRowNext = -1
}

make_ImGuiTableInstanceData :: proc() -> (tid : ImGuiTableInstanceData)
{
    init_ImGuiTableInstanceData(&tid)
    return
}


// size_of() ~ 592 bytes + heap allocs described in TableBeginInitMemory()
ImGuiTable :: struct
{
    ID : ImGuiID,
    Flags : ImGuiTableFlags,
    RawData : rawptr,                    // Single allocation to hold Columns[], DisplayOrderToIndex[] and RowCellData[]
    TempData : ^ImGuiTableTempData,                   // Transient data while table is active. Point within g.CurrentTableStack[]
    Columns : []ImGuiTableColumn,                    // Point within RawData[]
    DisplayOrderToIndex : []ImGuiTableColumnIdx,        // Point within RawData[]. Store display order of columns (when not reordered, the values are 0...Count-1)
    RowCellData : []ImGuiTableCellData,                // Point within RawData[]. Store cells background requests for current row.
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
    RowFlags     : ImGuiTableRowFlags,              // Current row flags, see ImGuiTableRowFlags_
    LastRowFlags : ImGuiTableRowFlags,
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
    Bg0ClipRectForDrawCmd : ImRect,      // Actual ImDrawCmd clip rect for BG0/1 channel. This tends to be == OuterWindow.ClipRect at BeginTable() because output in BG0/BG1 is cpu-clipped
    Bg2ClipRectForDrawCmd : ImRect,      // Actual ImDrawCmd clip rect for BG2 channel. This tends to be a correct, tight-fit, because output to BG2 are done by widgets relying on regular ClipRect.
    HostClipRect : ImRect,               // This is used to check if we can eventually merge our columns draw calls into the current draw call of the current window.
    HostBackupInnerClipRect : ImRect,    // Backup of InnerWindow.ClipRect during PushTableBackground()/PopTableBackground()
    OuterWindow : ^ImGuiWindow,                // Parent window for the table
    InnerWindow : ^ImGuiWindow,                // Window holding the table data (== OuterWindow or a child window)
    ColumnsNames : ImGuiTextBuffer,               // Contiguous buffer holding columns names
    DrawSplitter : ^ImDrawListSplitter,               // Shortcut to TempData.DrawSplitter while in table. Isolate draw commands per columns to avoid switching clip rect constantly
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
    HostSkipItems : bool,              // Backup of InnerWindow.SkipItem at the end of BeginTable(), because we will overwrite InnerWindow.SkipItem on a per-column basis
};

init_ImGuiTable :: proc(this : ^ImGuiTable) { this^ = {}; this.LastFrameActive = -1; }
deinit_ImGuiTable :: proc(this : ^ImGuiTable) { IM_FREE(this.RawData); }

// Transient data that are only needed between BeginTable() and EndTable(), those buffers are shared (1 per level of stacked table).
// - Accessing those requires chasing an extra pointer so for very frequently used data we leave them in the main table structure.
// - We also leave out of this structure data that tend to be particularly useful for debugging/metrics.
// FIXME-TABLE: more transient data could be stored in a stacked ImGuiTableTempData: e.g. SortSpecs.
// size_of() ~ 136 bytes.
ImGuiTableTempData :: struct
{
    TableIndex : i32,                 // Index in g.Tables.Buf[] pool
    LastTimeActive : f32,             // Last timestamp this structure was used
    AngledHeadersExtraWidth : f32,    // Used in EndTable()
    AngledHeadersRequests : [dynamic]ImGuiTableHeaderData,   // Used in TableAngledHeadersRow()

    UserOuterSize : ImVec2,              // outer_size.x passed to BeginTable()
    DrawSplitter : ImDrawListSplitter,

    HostBackupWorkRect : ImRect,         // Backup of InnerWindow.WorkRect at the end of BeginTable()
    HostBackupParentWorkRect : ImRect,   // Backup of InnerWindow.ParentWorkRect at the end of BeginTable()
    HostBackupPrevLineSize : ImVec2,     // Backup of InnerWindow.DC.PrevLineSize at the end of BeginTable()
    HostBackupCurrLineSize : ImVec2,     // Backup of InnerWindow.DC.CurrLineSize at the end of BeginTable()
    HostBackupCursorMaxPos : ImVec2,     // Backup of InnerWindow.DC.CursorMaxPos at the end of BeginTable()
    HostBackupColumnsOffset : ImVec1,    // Backup of OuterWindow.DC.ColumnsOffset at the end of BeginTable()
    HostBackupItemWidth : f32,        // Backup of OuterWindow.DC.ItemWidth at the end of BeginTable()
    HostBackupItemWidthStackSize : i32,//Backup of len(OuterWindow.DC.ItemWidthStack) at the end of BeginTable()
};

init_ImGuiTableTempData :: proc(this : ^ImGuiTableTempData) { this^ = {}; this.LastTimeActive = -1.0; }
make_ImGuiTableTempData :: proc() -> (ttd : ImGuiTableTempData) {
    init_ImGuiTableTempData(&ttd)
    return
}

// size_of() ~ 12
ImGuiTableColumnSettings :: struct
{
    WidthOrWeight : f32,
    UserID : ImGuiID,
    Index : ImGuiTableColumnIdx,
    DisplayOrder : ImGuiTableColumnIdx,
    SortOrder : ImGuiTableColumnIdx,
    using _ : bit_field u8 {
        SortDirection : u8 | 2,
        IsEnabled     : bool | 1, // "Visible" in ini file
        IsStretch     : bool | 1,
    }
};

init_ImGuiTableColumnSettings :: proc(this : ^ImGuiTableColumnSettings)
{
    this.WidthOrWeight = 0.0;
    this.UserID = 0;
    this.Index = -1;
    this.DisplayOrder = -1;
    this.SortOrder = -1;
    this.SortDirection = nil;
    this.IsEnabled = 1;
    this.IsStretch = 0;
}

// This is designed to be stored in a single ImChunkStream (1 header followed by N ImGuiTableColumnSettings, etc.)
ImGuiTableSettings :: struct
{
    ID : ImGuiID,                     // Set to 0 to invalidate/delete the setting
    SaveFlags : ImGuiTableFlags,              // Indicate data we want to save using the Resizable/Reorderable/Sortable/Hideable flags (could be using its own flags..)
    RefScale : f32,               // Reference scale to be able to rescale columns on font/dpi changes.
    ColumnsCount : ImGuiTableColumnIdx,
    ColumnsCountMax : ImGuiTableColumnIdx,        // Maximum number of columns this settings instance can store, we can recycle a settings instance with lower number of columns but not higher
    WantApply : bool,              // Set when loaded from .ini data (to enable merging/loading .ini data into an already running context)
};
GetColumnSettings :: proc(this : ^ImGuiTableSettings) -> [^]ImGuiTableColumnSettings     {
    return cast([^]ImGuiTableColumnSettings) mem.ptr_offset(this, 1);
}

//-----------------------------------------------------------------------------
// [SECTION] ImGui internal API
// No guarantee of forward compatibility here!
//-----------------------------------------------------------------------------

// Windows
// We should always have a CurrentWindow in the stack (there is an implicit "Debug" window)
// If this ever crashes because g.CurrentWindow is NULL, it means that either:
// - ImGui::NewFrame() has never been called, which is illegal.
// - You are calling ImGui functions after ImGui::EndFrame()/ImGui::Render() and before the next ImGui::NewFrame(), which is also illegal.
GetCurrentWindowRead :: #force_inline proc() -> ^ImGuiWindow      { g := GImGui; return g.CurrentWindow; }
GetCurrentWindow :: #force_inline proc() -> ^ImGuiWindow          { g := GImGui; g.CurrentWindow.WriteAccessed = true; return g.CurrentWindow; }
SetWindowParentWindowForFocusRoute :: #force_inline proc(window, parent_window : ^ImGuiWindow) { window.ParentWindowForFocusRoute = parent_window; } // You may also use SetNextWindowClass()'s FocusRouteParentWindowId field.
WindowRectAbsToRel :: #force_inline proc(window : ^ImGuiWindow,  r : ImRect) -> ImRect { off := window.DC.CursorStartPos; return ImRect{ _r = {r.Min.x - off.x, r.Min.y - off.y, r.Max.x - off.x, r.Max.y - off.y}}; }
WindowRectRelToAbs :: #force_inline proc(window : ^ImGuiWindow,  r : ImRect) -> ImRect { off := window.DC.CursorStartPos; return ImRect{ _r = {r.Min.x + off.x, r.Min.y + off.y, r.Max.x + off.x, r.Max.y + off.y}}; }
WindowPosAbsToRel  :: #force_inline proc(window : ^ImGuiWindow,  p : ImVec2) -> ImVec2 { off := window.DC.CursorStartPos; return ImVec2{p.x - off.x, p.y - off.y}; }
WindowPosRelToAbs  :: #force_inline proc(window : ^ImGuiWindow,  p : ImVec2) -> ImVec2 { off := window.DC.CursorStartPos; return ImVec2{p.x + off.x, p.y + off.y}; }

GetDefaultFont :: #force_inline proc() -> ^ImFont { g := GImGui; return g.IO.FontDefault ? g.IO.FontDefault : g.IO.Fonts.Fonts[0]; }
ImGuiWindow_GetForegroundDrawList :: #force_inline proc(window : ^ImGuiWindow) -> ^ImDrawList { return GetForegroundDrawList(window.Viewport); }

LocalizeGetMsg :: #force_inline proc(key : ImGuiLocKey) -> string { g := GImGui;  msg := g.LocalizationTable[key]; return msg != "" ? msg : "*Missing Text*"; }

ScrollToBringRectIntoView :: #force_inline proc(window : ^ImGuiWindow,  rect : ImRect) { ScrollToRect(window, rect, ImGuiScrollFlags_KeepVisibleEdgeY); }

GetItemStatusFlags :: #force_inline proc() -> ImGuiItemStatusFlags { g := GImGui; return g.LastItemData.StatusFlags; }
GetItemFlags :: #force_inline proc() -> ImGuiItemFlags  { g := GImGui; return g.LastItemData.ItemFlags; }
GetActiveID :: #force_inline proc() -> ImGuiID   { g := GImGui; return g.ActiveId; }
GetFocusID :: #force_inline proc() -> ImGuiID    { g := GImGui; return g.NavId; }

ImRect_ItemSize :: #force_inline proc(bb : ImRect, text_baseline_y : f32 = -1.0) { ItemSize(GetSize(bb), text_baseline_y); } // FIXME: This is a misleading API since we expect CursorPos to be bb.Min.

// FIXME: Eventually we should aim to move e.g. IsActiveIdUsingKey() into IsKeyXXX functions.
IsNamedKey      :: #force_inline proc(key : ImGuiKey) -> bool            { return key >= ImGuiKey.NamedKey_BEGIN && key < ImGuiKey.NamedKey_END; }
IsNamedKeyOrMod :: #force_inline proc(key : ImGuiKey) -> bool            { return (key >= ImGuiKey.NamedKey_BEGIN && key < ImGuiKey.NamedKey_END) || key == .Mod_Ctrl || key == .Mod_Shift || key == .Mod_Alt || key == .Mod_Super; }
IsLegacyKey     :: #force_inline proc(key : ImGuiKey) -> bool            { return key >= ImGuiKey.LegacyNativeKey_BEGIN && key < ImGuiKey.LegacyNativeKey_END; }
IsKeyboardKey   :: #force_inline proc(key : ImGuiKey) -> bool            { return key >= ImGuiKey.Keyboard_BEGIN && key < ImGuiKey.Keyboard_END; }
IsGamepadKey    :: #force_inline proc(key : ImGuiKey) -> bool            { return key >= ImGuiKey.Gamepad_BEGIN && key < ImGuiKey.Gamepad_END; }
IsMouseKey      :: #force_inline proc(key : ImGuiKey) -> bool            { return key >= ImGuiKey.Mouse_BEGIN && key < ImGuiKey.Mouse_END; }
IsAliasKey      :: #force_inline proc(key : ImGuiKey) -> bool            { return key >= ImGuiKey.Aliases_BEGIN && key < ImGuiKey.Aliases_END; }
IsLRModKey      :: #force_inline proc(key : ImGuiKey) -> bool            { return key >= ImGuiKey.LeftCtrl && key <= ImGuiKey.RightSuper; }
ConvertSingleModFlagToKey :: #force_inline proc(key : ImGuiKey) -> ImGuiKey
{
    if (key == ImGuiKey.Mod_Ctrl)  do return ImGuiKey.ReservedForModCtrl;
    if (key == ImGuiKey.Mod_Shift) do return ImGuiKey.ReservedForModShift;
    if (key == ImGuiKey.Mod_Alt)   do return ImGuiKey.ReservedForModAlt;
    if (key == ImGuiKey.Mod_Super) do return ImGuiKey.ReservedForModSuper;
    return key;
}

GetKeyData_g          :: #force_inline proc(key : ImGuiKey)            -> ^ImGuiKeyData   { g := &GImGui; return GetKeyData(g, key); }
MouseButtonToKey      :: #force_inline proc(button : ImGuiMouseButton) -> ImGuiKey        { assert(transmute(i32) button >= 0 && button < ImGuiMouseButton.COUNT); return ImGuiKey(i32(ImGuiKey.MouseLeft) + i32(button)); }
IsActiveIdUsingNavDir :: #force_inline proc(dir : ImGuiDir)            -> bool            { g := &GImGui; return (g.ActiveIdUsingNavDirMask & (1 << dir)) != 0; }

GetKeyData :: proc { GetKeyData_g, GetKeyData_ctx }

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
GetKeyOwnerData :: #force_inline proc(ctx : ^ImGuiContext, key : ImGuiKey) -> ^ImGuiKeyOwnerData          { key := key; if (key & ImGuiKey.Mod_Mask_) do key = ConvertSingleModFlagToKey(key); assert(IsNamedKey(key)); return &ctx.KeysOwnerData[key - ImGuiKey.NamedKey_BEGIN]; }

// [EXPERIMENTAL] High-Level: Input Access functions w/ support for Key/Input Ownership
// - Important: legacy IsKeyPressed(ImGuiKey, bool repeat=true) _DEFAULTS_ to repeat, new IsKeyPressed() requires _EXPLICIT_ ImGuiInputFlags_Repeat flag.
// - Expected to be later promoted to public API, the prototypes are designed to replace existing ones (since owner_id can default to Any == 0)
// - Specifying a value for 'ImGuiID owner' will test that EITHER the key is NOT owned (UNLESS locked), EITHER the key is owned by 'owner'.
//   Legacy functions use ImGuiKeyOwner_Any meaning that they typically ignore ownership, unless a call to SetKeyOwner() explicitly used ImGuiInputFlags_LockThisFrame or ImGuiInputFlags_LockUntilRelease.
// - Binding generators may want to ignore those for now, or suffix them with Ex() until we decide if this gets moved into public API.

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

// Docking
// (some functions are only declared in imgui.cpp, see Docking section)
DockNodeGetRootNode           :: #force_inline proc(node : ^ImGuiDockNode)                          -> ^ImGuiDockNode { node := node; for (node.ParentNode) do node = node.ParentNode; return node; }
DockNodeIsInHierarchyOf       :: #force_inline proc(node : ^ImGuiDockNode, parent : ^ImGuiDockNode) -> bool           { for (node) { if (node == parent) do return true; node = node.ParentNode; } return false; }
DockNodeGetDepth              :: #force_inline proc(node : ^ImGuiDockNode)                          -> i32            { depth : i32 = 0; for (node.ParentNode) { node = node.ParentNode; depth += 1; } return depth; }
DockNodeGetWindowMenuButtonId :: #force_inline proc(node : ^ImGuiDockNode)                          -> ImGuiID        { return ImHashStr("#COLLAPSE", 0, node.ID); }
GetWindowDockNode             :: #force_inline proc()                                               -> ^ImGuiDockNode { g := GImGui; return g.CurrentWindow.DockNode; }

// Docking - Builder function needs to be generally called before the node is used/submitted.
// - The DockBuilderXXX functions are designed to _eventually_ become a public API, but it is too early to expose it and guarantee stability.
// - Do not hold on ImGuiDockNode* pointers! They may be invalidated by any split/merge/remove operation and every frame.
// - To create a DockSpace() node, make sure to set the ImGuiDockNodeFlags_DockSpace flag when calling DockBuilderAddNode().
//   You can create dockspace nodes (attached to a window) _or_ floating nodes (carry its own window) with this API.
// - DockBuilderSplitNode() create 2 child nodes within 1 node. The initial node becomes a parent node.
// - If you intend to split the node immediately after creation using DockBuilderSplitNode(), make sure
//   to call DockBuilderSetNodeSize() beforehand. If you don't, the resulting split sizes may not be reliable.
// - Call DockBuilderFinish() after you are done.
DockBuilderGetCentralNode :: #force_inline proc(node_id : ImGuiID) -> ^ImGuiDockNode              { node := DockBuilderGetNode(node_id); if (!node) do return nil; return DockNodeGetRootNode(node)->CentralNode; }

// [EXPERIMENTAL] Focus Scope
// This is generally used to identify a unique input location (for e.g. a selection set)
// There is one per window (automatically set in Begin), but:
// - Selection patterns generally need to react (e.g. clear a selection) when landing on one item of the set.
//   So in order to identify a set multiple lists in same window may each need a focus scope.
//   If you imagine an hypothetical BeginSelectionGroup()/EndSelectionGroup() api, it would likely call PushFocusScope()/EndFocusScope()
// - Shortcut routing also use focus scope as a default location identifier if an owner is not provided.
// We don't use the ID Stack for this as it is common to want them separate.
GetCurrentFocusScope :: #force_inline proc() -> ImGuiID { g := GImGui; return g.CurrentFocusScopeId; }   // Focus scope we are outputting into, set by PushFocusScope()

// Typing-Select API
// (provide Windows Explorer style "select items by typing partial name" + "cycle through items by typing same letter" feature)
// (this is currently not documented nor used by main library, but should work. See "widgets_typingselect" in imgui_test_suite for usage code. Please let us know if you use this!)

// Multi-Select API
GetBoxSelectState   :: #force_inline proc(id : ImGuiID) -> ^ImGuiBoxSelectState   { g := GImGui; return (id != 0 && g.BoxSelectState.ID == id && g.BoxSelectState.IsActive) ? &g.BoxSelectState : nil; }
GetMultiSelectState :: #force_inline proc(id : ImGuiID) -> ^ImGuiMultiSelectState { g := GImGui; return g.MultiSelectStorage.GetByKey(id); }

// Tables: Internals
GetCurrentTable :: #force_inline proc() -> ^ImGuiTable { g := GImGui; return g.CurrentTable; }
TableGetInstanceData :: #force_inline proc(table : ^ImGuiTable, #any_int instance_no : i32) -> ^ImGuiTableInstanceData { if (instance_no == 0) do return &table.InstanceDataFirst; return &table.InstanceDataExtra[instance_no - 1]; }
TableGetInstanceID :: #force_inline proc(table : ^ImGuiTable, #any_int instance_no : i32) -> ImGuiID   { return TableGetInstanceData(table, instance_no).TableInstanceID; }

// Tab Bars
GetCurrentTabBar :: #force_inline proc() -> ^ImGuiTabBar { g := GImGui; return g.CurrentTabBar; }
TabBarGetTabOrder :: #force_inline proc(tab_bar : ^ImGuiTabBar, tab : ^ImGuiTabItem) -> i32 { return tab_bar.Tabs.index_from_ptr(tab); }

// InputText
TempInputIsActive :: #force_inline proc(id : ImGuiID) -> bool       { g := GImGui; return (g.ActiveId == id && g.TempInputId == id); }
GetInputTextState :: #force_inline proc(id : ImGuiID) -> ^ImGuiInputTextState   { g := GImGui; return (id != 0 && g.InputTextState.ID == id) ? &g.InputTextState : nil; } // Get input text state if active


//-----------------------------------------------------------------------------
// [SECTION] ImFontAtlas internal API
//-----------------------------------------------------------------------------

// This structure is likely to evolve as we add support for incremental atlas updates.
// Conceptually this could be in ImGuiPlatformIO, but we are far from ready to make this public.
ImFontBuilderIO :: struct
{
    FontBuilder_Build : proc(atlas : ^ImFontAtlas) -> bool,
};

//-----------------------------------------------------------------------------
// [SECTION] Test Engine specific hooks (imgui_test_engine)
//-----------------------------------------------------------------------------

when IMGUI_ENABLE_TEST_ENGINE {

// In IMGUI_VERSION_NUM >= 18934: changed IMGUI_TEST_ENGINE_ITEM_ADD(bb,id) to IMGUI_TEST_ENGINE_ITEM_ADD(id,bb,item_data);
    IMGUI_TEST_ENGINE_ITEM_ADD :: #force_inline proc (_ID : ImGuiID, _BB : ImRect, _ITEM_DATA : rawptr)      { if (g.TestEngineHookItems) do ImGuiTestEngineHook_ItemAdd(g, _ID, _BB, _ITEM_DATA) }  // Register item bounding box
    IMGUI_TEST_ENGINE_ITEM_INFO :: #force_inline proc (_ID : ImGuiID, _LABEL : string, _FLAGS : ImGuiItemStatusFlags)      { if (g.TestEngineHookItems) do ImGuiTestEngineHook_ItemInfo(g, _ID, _LABEL, _FLAGS) }  // Register item label and status flags (optional)
    IMGUI_TEST_ENGINE_LOG :: #force_inline proc (_FMT : string, args : ..any)      { ImGuiTestEngineHook_Log(g, _FMT, args)                                      }  // Custom log entry from user land into test log
} else {
    IMGUI_TEST_ENGINE_ITEM_ADD :: #force_inline proc(_BB, _ID : ImGuiID)                 { }
    IMGUI_TEST_ENGINE_ITEM_INFO :: #force_inline proc(_ID : ImGuiID, _LABEL : string, _FLAGS : ImGuiItemStatusFlags)      { }
}

