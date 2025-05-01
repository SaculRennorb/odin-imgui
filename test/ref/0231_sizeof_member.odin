package test

A0231 :: struct {
	a : i32,
}

fn0231 :: proc()
{
	b : A0231
	a : uint = size_of(b.a)
}
