package test

A1017 :: struct {
}

A1017_deinit :: proc(this : ^A1017)
{}

fn1017 :: proc()
{
	a : A1017; b : ^A1017
	deinit(&a)
	deinit(b)
}



deinit :: proc { A1017_deinit }
