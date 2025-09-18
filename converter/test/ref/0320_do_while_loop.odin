package test

fn0320 :: proc()
{
	i : i32 = 0
	for {
		post_incr(&i)

		if !(i < 5) { break }
	}
}
