struct A1019 {
	int a, b;
};

void fn1019() {
	A1019 a = { 1, 2 };
	A1019 b = {
#ifdef A
	 1,
#endif
	 2 // test
	};
}
