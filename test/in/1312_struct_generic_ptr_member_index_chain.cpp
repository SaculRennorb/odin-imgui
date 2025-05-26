template<typename T>
struct A1312 {
	T* data;
};

struct B1312 {
	int b;
};

void fn1312()
{
	A1312<B1312> a;
	a.data[2].b = 3;
}
