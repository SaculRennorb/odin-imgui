package test

fn0303 :: proc()
{
	for i, j : i32 = {}, 1; i < 3; i, j = i + 1, j - 1 { }
}
