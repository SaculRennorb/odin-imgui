package test

A0200 :: struct {
	a : i32,
}

fn0200 :: proc()
{
	a : ^A0200
	b : i32 = a[2].a
}