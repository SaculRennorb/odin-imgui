package test

A1019 :: struct {
	a : i32, b : i32,
}

fn1019 :: proc()
{
	a : A1019 = {1, 2}
	b : A1019 = {
		when defined ( A ) {
		1,
		} // preproc endif
		2, // test
	}
}
