struct A211 {
	int* B() { return nullptr; }
};
struct B211 : A211 {
};

void fn1110()
{
	B211 a;
	int* b = a.B();
}
