package test

fn_T :: proc() -> i32

fn02092 :: proc() -> fn_T { return 0 }

fn0209 :: proc()
{
	q : i32 = fn02092()()
}