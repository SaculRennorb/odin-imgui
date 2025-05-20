package test

A1402 :: struct {
	using _0 : struct #raw_union { a : i32, b : f32, },
}

fn1402 :: proc()
{
	a : A1402
	b : f32 = a.b
}
