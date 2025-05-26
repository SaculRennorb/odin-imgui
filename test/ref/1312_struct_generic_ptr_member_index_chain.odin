package test

A1312 :: struct($T : typeid) {
	data : ^T,
}

B1312 :: struct {
	b : i32,
}

fn1312 :: proc()
{
	a : A1312(B1312)
	a.data[2].b = 3
}
