package test

M3110 :: #force_inline proc "contextless" (A : $T0, B : $T1) //TODO @gen: Validate the parameters were not passed by reference.
{
	A.Fn();
	B(A);
}
