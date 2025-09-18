struct A0204 {
	int a;
};

struct B0204 {
	A0204 aa[4];
};

void fn0204()
{
	B0204 b;
	b.aa[2].a = 2;
}
