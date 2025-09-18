package test

defined :: #force_inline proc($I) -> bool { I }

pre_decr :: #force_inline proc(p : ^$T) -> (new : T) { p^ -= 1; return p }
pre_incr :: #force_inline proc(p : ^$T) -> (new : T) { p^ += 1; return p }
post_decr :: #force_inline proc(p : ^$T) -> (old : T) { old = p; p^ -= 1; return }
post_incr :: #force_inline proc(p : ^$T) -> (old : T) { old = p; p^ += 1; return }

va_arg :: #force_inline proc(args : ^[]any, $T : typeid) -> (r : T) { r = (cast(T^) args[0])^; args^ = args[1:] }
