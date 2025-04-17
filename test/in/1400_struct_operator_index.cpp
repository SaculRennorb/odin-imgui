struct A1400 {
	int a;
	inline int& operator[](int i) { return a; }
};
