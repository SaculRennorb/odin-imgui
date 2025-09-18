void fn0173() {
	int a;
	auto l = [&a](int b){ return a + b; };

	l(1);
}
