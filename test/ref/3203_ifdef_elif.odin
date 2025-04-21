package test

when A {
A3203 :: struct {
	a : i32,
}
} else when B {
A3203 :: struct {
	b : i32,
}
} else { // preproc else
A3203 :: struct {
	c : i32,
}
} // preproc endif
