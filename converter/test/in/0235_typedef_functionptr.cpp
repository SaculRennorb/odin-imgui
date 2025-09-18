typedef void* (*fn0235)(int a, int b);

fn0235 fn0235_ptr;

void fn02352(int a)
{
	void* m = (*fn0235_ptr)(a, 2);
}
