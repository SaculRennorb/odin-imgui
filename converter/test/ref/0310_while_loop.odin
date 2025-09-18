package test

fn0310 :: proc()
{
	i : i32 = 0
	for i < 5 {
		post_incr(&i)
	}
}
