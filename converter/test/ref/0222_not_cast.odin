package test

fn0222 :: proc()
{
	a : i32
	b : i32 = cast(i32) &a
	c : i32 = (a) & 0x3f
}
