package test

A201 :: struct {
}

A201_B :: proc(this : ^A201) -> ^i32
{
	return nil
}

fn0202 :: proc()
{
	a : A201
	b : ^i32 = A201_B(&a)
}
