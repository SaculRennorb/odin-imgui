package test

fn0338 :: proc()
{
	a : i32
	b : ^i32
	c : struct #raw_union { }
	if a == 0 { }
	if a < 0 { }
	if a == 0 { }
	if a != 0 { }
	if b != nil { }
	if b == nil { }
	if b == nil { }
	if (b + a) != nil { }
	if b^ != 0 { }
	if c == {} { }
	if c != {} { }
	if (c & 3) != {} { }
	if c == {} { }
	d : i32 = &a > b ? a : b^
}