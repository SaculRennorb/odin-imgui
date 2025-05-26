template<typename T>
struct A1310 {
	T* data;
};

void fn1310()
{
	A1310<int> a;
	a.data[2] = 3;
}
