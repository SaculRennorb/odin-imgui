package test

M3111 :: #force_inline proc "contextless" (A : $T0, args : ..[]any) //TODO: validate those args are not by-ref
{
	A.Fn();
	B(A);
}
