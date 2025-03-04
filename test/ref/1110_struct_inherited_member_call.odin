package test

A211 :: struct {
}

A211_B :: proc(this : ^A211) -> ^i32
{
	return nil
}

B211 :: struct {
	using __base_a211 : A211,
}

fn1110 :: proc()
{
	a : B211
	b : ^i32 = A211_B(&a)
}
