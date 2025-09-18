package test

A1310 :: struct($T : typeid) {
	data : ^T,
}

fn1310 :: proc()
{
	a : A1310(i32)
	a.data[2] = 3
}
