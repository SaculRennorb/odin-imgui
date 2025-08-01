package test

A0200 :: struct {
	b : i32,
}

fn0200 :: proc()
{
	a : ^A0200
	c : i32 = a[2].b
}