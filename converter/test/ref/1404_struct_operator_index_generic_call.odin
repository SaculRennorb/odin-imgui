package test

A1404 :: struct {
	a : i32,
}

B1404 :: struct($T : typeid) {
	data : ^T,

}

fn1404 :: proc(b : ^B1404(A1404))
{
	b[1].a = 1
}
