package test

A1306 :: struct($T : typeid) {
	t : ^T,
}

B1306 :: struct {
	b : A1306(B1306_C),
}

B1306_C :: struct { c : i32, }

fn1306 :: proc()
{
	a : B1306
	a.b.t.c = 0
}
