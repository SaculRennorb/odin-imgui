package test

fn3002 :: proc() { }
when ! defined ( D3002 ) {

fn30022 :: proc()
{
	fn3002()
}

} // preproc endif