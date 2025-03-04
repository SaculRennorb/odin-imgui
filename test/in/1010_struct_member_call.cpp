struct A201 {
	int* B() { return nullptr; }
};

void fn0202()
{
	A201 a;
	int* b = a.B();
}
