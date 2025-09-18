struct A1042 {
	int a, b;

	A1042(int _a, int _b) {}
};

struct B1042 {
	A1042 a;

	B1042() : a(1, 2) {}
};
