package test

fn0301 :: proc()
{
	i : i32 = 0
	for ; i < 5; post_incr(&i) { }

	for i : i32 = 0; ; post_incr(&i) { }

	for i : i32 = 0; i < 5;  { }

	for { }
}
