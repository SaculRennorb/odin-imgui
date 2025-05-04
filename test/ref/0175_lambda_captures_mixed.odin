package test

fn0173 :: proc()
{
	a : i32; b : i32
	l := __l_0_captures {
		__l_0_function,
		&a, b,
	}
	__l_0_captures :: struct {
		__invoke : type_of(__l_0_function),
		a : ^i32, b : i32,
	}
	__l_0_function :: proc(__l : ^__l_0_captures) -> i32 { using __l; return a + b }

	l->__invoke()
}
