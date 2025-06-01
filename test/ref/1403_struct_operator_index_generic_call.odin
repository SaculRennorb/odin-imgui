package test

A1403 :: struct {
	using _0 : struct #raw_union { a : i32, b : f32, },
}

B1403 :: struct($T : typeid) {
	data : ^T,

}

fn1403 :: proc()
{
	b : B1403(A1403)
	c : f32 = b[1].b
}
