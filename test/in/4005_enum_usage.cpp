enum E4005 {
	A = 4,
	B,
	C,
};

void fn4005()
{
	int a = A;
	int b = E4005::B;
}

struct A4005 {
	void fn40052()
	{
		int a = A;
		int b = E4005::B;
	}
};
