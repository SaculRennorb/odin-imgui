package test

A1170 :: struct {
	a : i32,
	next : ^A1170,
}


fn1170 :: proc()
{
	c : ^A1170
	if c.next.a == 0 { }
}
