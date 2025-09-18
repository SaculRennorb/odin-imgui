package test

fn3002 :: proc() { }
when ! D3002 { /* @gen ifndef */

fn30022 :: proc()
{
	fn3002()
}

} // preproc endif