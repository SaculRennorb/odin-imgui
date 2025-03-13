struct A1110 {
	int* B() { return nullptr; }
};
struct B1110 : A1110 {
};

void fn11110()
{
	B1110 a;
	int* b = a.B();
}
