package test

PI :: 3.14159265358979323846
fn3003 :: proc()
{
	a : f32 = PI / 2
}

A3003 :: struct {
	b : f32,
}

A3003_init :: proc(this : ^A3003)
{
	this.b = 2 * (PI / 4)
}