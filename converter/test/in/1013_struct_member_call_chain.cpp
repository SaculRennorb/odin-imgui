struct A1013 {
	int A() { return 0; }
};
struct B1013 {
	A1013* B() { return nullptr; }
};

void fn1013()
{
	B1013 b;
	int c = b.B()->A();
}
