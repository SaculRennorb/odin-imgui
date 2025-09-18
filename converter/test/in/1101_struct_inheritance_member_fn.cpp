struct A11 {
	int a;
};

struct B11 : A11 {
	int C() { return a; }
};