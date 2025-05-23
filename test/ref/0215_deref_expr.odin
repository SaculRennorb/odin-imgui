package test

fn0215a :: proc(b : i32) -> i32 { return 1 }

fn0215b :: proc()
{
	b : ^i32
	fn0215a(b^)
}
