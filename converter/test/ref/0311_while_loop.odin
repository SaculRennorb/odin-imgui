package test

fn0311 :: proc()
{
	i : i32 = 5
	for {
		j : i32 = post_decr(&i)
		if !(j) { break }

		// do thing
	}
}
