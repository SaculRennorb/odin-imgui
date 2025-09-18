package test

fn0211 :: proc()
{
	a : ^f32
	b : ^i32 = cast(^i32) cast(rawptr) a
}