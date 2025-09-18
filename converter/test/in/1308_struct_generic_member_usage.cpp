template<class T>
struct A1308 {
	T t;
	T& get() { return t; }
};

struct D1308 {
	int d;
};

struct B1308 {
	D1308 b;
};

struct C1308 {
	A1308<B1308> a;

	void fn(){ a.get().b.d = 0; }
};
