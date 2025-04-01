package test

fn0320 :: proc()
{
	i : i32 = 0
	for {
		i += 1

		if !(i < 5) { break }
	}
}
