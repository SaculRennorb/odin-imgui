package test


when ! REMOVED_IF {
a3210 : i32
} // preproc endif


when ! REMOVED_IF { /* @gen ifndef */
d3210 : i32; // comment
} // preproc endif
