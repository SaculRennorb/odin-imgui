package test

fn0334 :: proc()
{
	a : bool
	b : i32

	// 0 1
	if a {
		/* 1 2 */
		// 1 3
		b = 0
	}
	else if a == 1 {
		// 2 1
		// 2 2
		b = 1
	}
	else {
		// 3 1
		// 3 2
		b = 2
	}
	// 4 1
}
