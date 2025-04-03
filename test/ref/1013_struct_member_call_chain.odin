package test

A1013 :: struct {
}

A1013_A :: proc(this : ^A1013) -> i32 { return 0 }

B1013 :: struct {
}

B1013_B :: proc(this : ^B1013) -> ^A1013 { return nil }

fn1013 :: proc()
{
	b : B1013
	c : i32 = A1013_A(B1013_B(&b))
}
