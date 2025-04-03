package test

A1012 :: struct {
}

A1012_B :: proc(this : ^A1012) -> ^i32 { return nil }

fn1012 :: proc()
{
	a : ^A1012
	b : ^i32 = A1012_B(a)
}
