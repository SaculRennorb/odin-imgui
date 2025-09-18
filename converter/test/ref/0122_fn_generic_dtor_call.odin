package test

fn0122 :: proc($T : typeid, p : ^T) -> i32
{
	deinit(p)
	return 0
}
