

struct A {
	int a;
};


int main(const int argc, char const** argv)
{
	int a = 5;
	int b = a + 3;
	auto& c = argv[b];

	int d, *e;

	char const* arg = argv[a];
	const char* arg2 = argv[a];

	return 0;
}