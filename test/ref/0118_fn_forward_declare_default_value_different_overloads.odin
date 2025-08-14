package test

A0118 :: struct {
}

N0118_fn_0 :: proc(a : i32 = 1) { }
N0118_fn_1 :: proc(a : f32 = 2) { }

A0118_fn_0 :: proc(this : ^A0118, a : i32 = 1) { }
A0118_fn_1 :: proc(this : ^A0118, a : f32 = 2) { }

// Overload indices are wrong here, don't want to bother right now
fn0118 :: proc(a : i32 = 1) { }
fn0118 :: proc(a : f32 = 2) { }


fn :: proc { N0118_fn_0, N0118_fn_1, A0118_fn_0, A0118_fn_1 }
