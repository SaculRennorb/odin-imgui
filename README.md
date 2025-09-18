# The first actual [Odin](https://odin-lang.org/) port of [Dear ImGui](https://github.com/ocornut/imgui)

- based on the tables + docking branch of imgui
- actual port instead of just linking against a prebuilt lib, including some signature changes
- does not depend on libc
- including (some of) the preproc customization from the original
- focus on the win32 / dx11 backends

There are three main "commands" in this repo:
- `odin run converter/src` - will convert the fils in `imgui/in/` to `imgui/out/`.
- `odin test converter/test` - will run converter tests.
- `odin run imgui/test` - will run a small imgui test. That directory also contains the cpp demo file for imgui to compare against.

The general conversion process is as follows:
1. Run the converter, produces `imgui/out`
2. Copy `imgui/out` to `imgui/out_manual`
3. Manually fix everything the converter didn't catch in `imgui/out_manual`
4. Repeat ad absurdum

---

My goal was to gain access to the "just goto definition a and see what the code does" kind of exploration the original library uses, and to not be forced into any specific allocator, as well as not linking against any libraries. This port is not hand written, although much hand-fixing was needed.


Realistically speaking, i made one major mistake in this project:  
Right now, the source is tokenized, an ast is formed and then it gets converted to odin and immediately written to the output. 
Type resolution should really happen in the ast phase, not in the conversion phase:  
- There are a few cases where proper parsing requires knowledge of wether or not a identifier is a type.
- The converter only generates type information as it outputs the odin code, meaning information cannot retroactively change the output further up:
	Figuring out wether or not a pointer is actually a multipointer for example requires inspecting the usage of the pointer, but by then the type has already been written and can no longer be changed.
- The type living in the converter means that logic has to be copied over should i want to output to a different language, even though the type information comes from the source, not the target language.


The nature of this codebase being ~45k LOC makes this port inherently unstable, and it is expected to be wired and break. 
As of writing this readme i've just reached a point where I could not find any immediate obvious bugs or leaks.
