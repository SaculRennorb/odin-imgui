package test

fn1600 :: proc()
{
	A1600 :: struct {
		a : i32,
	}

	A1600_init :: proc(this : ^A1600, a_ : i32) { this.a = a_ }

	a : A1600; init(&a, 1)
}
