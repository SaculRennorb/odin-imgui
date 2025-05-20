struct A1402 {
	union { int a; float b; };
};

void fn1402()
{
	A1402 a;
	float b = a.b;
}
