package test

A1024 :: struct {
}

A1024_init :: proc(this : ^A1024, _a : i32, _b : i32) { }

fn1024 :: proc()
{
	a : A1024; init(&a, 1, 2)
}
