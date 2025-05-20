struct A1403 {
	union { int a; float b; };
};

template<typename T>
struct B1403 {
	T* data;

	T& operator[](int i) { return data[i]; }
};

void fn1403()
{
	B1403<A1403> b;
	float c = b[1].b;
}
