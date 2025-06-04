template<class T>
struct A1307 {
	T t;
};

struct B1307 {
	A1307<int*> a;

	void fn(){ a.t = 0; }
	void fn2(){ a.t = 0; }
};
