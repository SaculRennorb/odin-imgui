struct A1018 {
	int a, b;

	A1018(int _a, int _b) {}
};

struct B1018 {
	A1018 a;

	B1018() : a(1, 2) {}
};
