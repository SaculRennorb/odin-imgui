namespace N2015 {
	struct A2015 {
		void B2015() {}
	};
}

void fn2015() {
	using namespace N2015;
	A2015 a;
	a.B2015();
}

