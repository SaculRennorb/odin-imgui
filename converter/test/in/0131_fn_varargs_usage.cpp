void fn0131(int a, ...)
{
	va_list args;
	va_start(args, a);
	fn0131v(args);
	va_end(args);
}

void fn0131v(va_list args)
{
	const char* a = va_arg(args, const char*); 
	int b = va_arg(args, int); 
}
