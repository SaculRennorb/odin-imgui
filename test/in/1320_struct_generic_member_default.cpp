template<class T, int L = 1>
struct A1320 {
	T t[L];
};

struct B1320 {
	A1320<int*> a;
	A1320<int*, 2> b;

	void fn(){ a.t[0] = 0; }
	void fn2(){ b.t[0] = 0; }
};
