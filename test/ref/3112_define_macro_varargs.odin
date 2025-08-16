package test

M3112 :: #force_inline proc "contextless" (A : $T0, args : ..any) //TODO @gen: Validate the parameters were not passed by reference.
{
	A.Fn();
	B(A);
}
