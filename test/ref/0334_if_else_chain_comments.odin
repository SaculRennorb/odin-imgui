package test

fn0334 :: proc()
{
	a : bool
	b : i32

	// 1
	if a {
		/* 1 */
		// 1
		b = 0
	}
	else if a == 1 {
		// 2
		// 2
		b = 1
	}
	else {
		// 3
		// 3
		b = 2
	}
	// 4
}
