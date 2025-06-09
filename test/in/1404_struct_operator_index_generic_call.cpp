struct A1404 {
	int a;
};

template<typename T>
struct B1404 {
	T* data;

	T& operator[](int i) { return data[i]; }
};

void fn1404(B1404<A1404>& b)
{
	b[1].a = 1;
}
