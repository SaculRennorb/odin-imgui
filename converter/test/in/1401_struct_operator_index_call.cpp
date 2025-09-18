struct A1401 {
	int a;
	int get() { return a; }
};

struct B1401 {
	A1401* operator[](int i) { return 0; }
};

void fn1401() {
	B1401 a;
	a[2]->get();
}
