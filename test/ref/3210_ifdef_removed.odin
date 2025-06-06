package test


when ! REMOVED_IF {
a3210 : i32
} // preproc endif


when ! defined ( REMOVED_IF ) {
d3210 : i32; // comment
} // preproc endif
