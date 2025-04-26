package test

A1018 :: struct {
	a : i32, b : i32,
}

A1018_init :: proc(this : ^A1018, _a : i32, _b : i32)
{
}

B1018 :: struct {
	a : A1018,
}

B1018_init :: proc(this : ^B1018)
{

	init(&this.a, 1, 2)
}
