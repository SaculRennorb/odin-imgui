package test

fn0217 :: proc(a : ^i32)
{
	b : ^i32 = a
	c : ^i32 = b

	b = a
	c = b
}
