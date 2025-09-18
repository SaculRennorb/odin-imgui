package test

fn0214 :: proc(path : ^u8)
{
	args1 : [^]^u8 = {"open", "--", path, nil}
	args2 : [^]^u8 = {"open", "--", path, nil}
}
