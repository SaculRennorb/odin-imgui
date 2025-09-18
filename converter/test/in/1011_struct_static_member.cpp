struct A1011 {
	static int a;

	struct B1011 {
		static int b;
	};
};

void fn1011() {
	A1011::a = 3;
	A1011::B1011::b = 1;
}
