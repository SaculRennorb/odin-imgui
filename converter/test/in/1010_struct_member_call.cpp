struct A201 {
	int* B() { return nullptr; }
	int a;
};

void fn0202()
{
	A201 a;
	int* b = a.B();
	bool c = a.a == 4;
}
