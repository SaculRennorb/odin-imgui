struct A110 {
	int* B() { return nullptr; }
};
struct B110 : A110 {
};

void fn1110()
{
	B110 a;
	int* b = a.B();
}
