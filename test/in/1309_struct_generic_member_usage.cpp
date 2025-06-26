template<class T>
struct A1306 {
	T* t;
};

struct B1306 {
	struct C { int c; };
	A1306<C> b;
};

void fn1306()
{
	B1306 a;
	a.b.t->c = 0;
}
