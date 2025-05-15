package test

A1011 :: struct {
	arr : [A1011_E0.C]i32,
}

A1011_E0 :: enum i32 { A, B, C, }

A1011_fn1 :: proc(this : ^A1011)
{
	a : bool = A1011_E0.B == 3
	b : bool = A1011_E0.C == 3
}