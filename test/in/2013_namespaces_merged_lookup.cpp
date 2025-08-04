namespace N2013 {
	int* fn2();
}

namespace N2013 {
	void fn1();
}

void N2013::fn1() {
	*fn2() = 3;
}
