package test

fn0172 :: proc()
{
	a : i32
	l := __l_0_captures {
		__l_0_function,
		a,
	}
	__l_0_captures :: struct {
		__invoke : type_of(__l_0_function),
		a : i32,
	}
	__l_0_function :: proc(__l : ^__l_0_captures, b : i32) -> i32 { using __l; return a + b }

	l->__invoke()
}
