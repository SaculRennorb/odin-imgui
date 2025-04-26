package test

M3120 :: #force_inline proc "contextless" (e : $T0, __e_str := #caller_expression(e)) //TODO @gen: Validate the parameters were not passed by reference.
{
	_ = e // Silence warnings in case the param is no longer used because of stringification changes. @gen
	__e_str
}

