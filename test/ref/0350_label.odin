package test

fn0350 :: proc()
{
	a : i32 = 0
	loop: for {

		post_incr(&a)
		if a < 5 { continue loop /* @gen goto: validate direction */ }
		b : i32

		break
	}
}
