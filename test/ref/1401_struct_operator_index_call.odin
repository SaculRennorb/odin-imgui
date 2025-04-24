package test

A1401 :: struct {
	a : i32,
}

A1401_get :: proc(this : ^A1401) -> i32 { return this.a }

B1401 :: struct {
}

fn1401 :: proc()
{
	a : B1401
	get(a[2])
}
