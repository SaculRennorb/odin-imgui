template<class T>
struct A1306 {
	T t;
};

struct B1306 {
	A1306<int> a;
	A1306<int> b;
};
