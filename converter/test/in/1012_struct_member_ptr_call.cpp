struct A1012 {
	int* B() { return nullptr; }
};

void fn1012()
{
	A1012* a;
	int* b = a->B();
}
