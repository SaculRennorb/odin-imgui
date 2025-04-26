package test

M3111 :: #force_inline proc "contextless" (A : $T0, args : ..[]any) //TODO @gen: Validate the parameters were not passed by reference.
{
	A.Fn();
	B(A);
}
