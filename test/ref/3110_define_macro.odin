package test

M3110 :: #force_inline proc "contextless" (A : $T0, B : $T1) //TODO: validate those args are not by-ref
{
	A.Fn();
	B(A);
}
