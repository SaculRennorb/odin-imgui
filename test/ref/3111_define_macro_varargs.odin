package test

M3111 :: #force_inline proc "contextless" (args : ..any) //TODO @gen: Validate the parameters were not passed by reference.
{
	A(__VA_ARGS__)
}
