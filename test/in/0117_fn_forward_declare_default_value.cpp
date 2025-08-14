namespace N0117 {
	void fn(int a = 1);
}

struct A0117 {
	void fn2(int a = 1);
};

void N0117::fn(int a) { }
void A0117::fn2(int a) { }