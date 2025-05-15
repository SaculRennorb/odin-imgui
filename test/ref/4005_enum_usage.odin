package test

E4005 :: enum i32 {
	A = 4,
	B,
	C,
}

fn4005 :: proc()
{
	a : i32 = E4005.A
	b : i32 = E4005.B
}

A4005 :: struct {
}

A4005_fn40052 :: proc(this : ^A4005)
{
	a : i32 = E4005.A
	b : i32 = E4005.B
}
