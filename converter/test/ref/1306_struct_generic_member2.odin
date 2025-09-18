package test

A1306 :: struct($T : typeid) {
	t : T,
}

B1306 :: struct {
	a : A1306(i32),
	b : A1306(i32),
}
