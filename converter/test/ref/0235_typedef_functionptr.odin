package test

fn0235 :: proc(a : i32, b : i32) -> rawptr

fn0235_ptr : fn0235

fn02352 :: proc(a : i32)
{
	m : rawptr = fn0235_ptr(a, 2)
}
