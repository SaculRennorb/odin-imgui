template<typename T>
struct A1303
{
	int s;

	A1303(A1303<T>& s) {  }
	void swap(A1303<T> r) { int a = r.s; }
};
