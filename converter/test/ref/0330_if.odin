package test

fn0330 :: proc()
{
	a : bool
	b : i32

	if a { b = 0 }
	if a {
		//comment
		b = 0
	}
}
