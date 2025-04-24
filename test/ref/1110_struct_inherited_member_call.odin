package test

A1110 :: struct {
}

A1110_B :: proc(this : ^A1110) -> ^i32 { return nil }

B1110 :: struct {
	using __base_a1110 : A1110,
}

fn11110 :: proc()
{
	a : B1110
	b : ^i32 = B(&a)
}
