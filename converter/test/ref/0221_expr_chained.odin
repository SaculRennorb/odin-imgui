package test

fn0221 :: proc()
{
	a : i32; b : i32
	c : ^i32
	a += c[0]; b += a
	a += c[0]; b += a
}