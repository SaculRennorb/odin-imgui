package test

A111 :: struct {
}

A111_B :: proc(this : ^A111) -> ^i32 { return nil }

B111 :: struct {
	using __base_a111 : A111,
}

B111_B :: proc(this : ^B111) -> ^i32 { return nil }

fn1111 :: proc()
{
	a : B111
	b : ^i32 = B111_B(&a)
}
