package test

A1301 :: struct($T : typeid) {
	t : T,
}

A1301_get :: proc(this : ^A1301($T)) -> ^T { return &this.t }
