package test

A110 :: struct {
}

A110_B :: proc(this : ^A110) -> ^i32
{
	return nil
}

B110 :: struct {
	using __base_a110 : A110,
}

fn1110 :: proc()
{
	a : B110
	b : ^i32 = A110_B(&a)
}
