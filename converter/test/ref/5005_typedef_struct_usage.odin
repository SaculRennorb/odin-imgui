package test

A5005 :: struct($T : typeid) {
	a : ^T,
}

B5005 :: ^A5005(i32)

fn5005 :: proc()
{
	b : B5005
	b.a[0] = 2
}
