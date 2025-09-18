void fn0217(int& a)
{
	int* b = &a;
	int& c = *b;

	b = &a;
	c = *b;
}
