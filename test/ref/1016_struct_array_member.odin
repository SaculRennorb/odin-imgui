package test

IM_UNICODE_CODEPOINT_MAX :: 256

A1016 :: struct {
	Used4kPagesMap : [(IM_UNICODE_CODEPOINT_MAX + 1) / 4096 / 8]u8,
}
