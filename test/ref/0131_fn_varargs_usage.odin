package test

fn0131 :: proc(a : i32, args : ..[]any)
{
	args : []any
	va_start(args, a)
	fn0131v(args)
	va_end(args)
}

fn0131v :: proc(args : []any)
{
	a : ^u8 = va_arg(args, ^u8)
	b : i32 = va_arg(args, i32)
}
