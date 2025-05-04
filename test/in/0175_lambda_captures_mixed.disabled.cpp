void fn0172() {
	int a, b;
	auto l = [&a, b](){ return a + b; };

	l();
}
