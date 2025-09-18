template<typename T>
struct A5005 {
	T* a;
};

typedef A5005<int>* B5005;

void fn5005()
{
	B5005 b;
	b->a[0] = 2;
}
