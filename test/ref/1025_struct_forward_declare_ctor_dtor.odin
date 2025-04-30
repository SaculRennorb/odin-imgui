package test

A1025 :: struct {
	a : i32,
}

A1025_init :: proc(this : ^A1025)
{
this.a = 1
}

A1025_deinit :: proc(this : ^A1025)
{this.a = 0}

