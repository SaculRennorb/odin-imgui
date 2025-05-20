package test

A0204 :: struct {
	a : i32,
}

B0204 :: struct {
	aa : [4]A0204,
}

fn0204 :: proc()
{
	b : B0204
	b.aa[2].a = 2
}
