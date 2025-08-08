package test

A1035 :: struct {
}

A1035_fn1 :: proc(this : ^A1035) { }

A1035_fn2 :: proc(this : ^A1035) { A1035_fn1(this) }
