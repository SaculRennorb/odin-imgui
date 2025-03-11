struct A111 {
	int* B() { return nullptr; }
};
struct B111 : A111 {
	int* B() { return nullptr; }
};

void fn1111()
{
	B111 a;
	int* b = a.B();
}
