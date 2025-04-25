template<class T, class T2>
struct A1305 {
	T t;
};

struct B1305 {
	A1305<int*, int**> a;
};
