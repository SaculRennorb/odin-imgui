package program

preprocess :: proc(preprocessed : ^[dynamic][]AstNode, inputs : map[string][]AstNode, initial_index : string)
{
	append(preprocessed, inputs[initial_index])
}