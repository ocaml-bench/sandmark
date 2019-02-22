all: contrast

contrast: contrast.ml
	ocamlfind ocamlopt -linkpkg -package camlimages.all_formats -o $@ $^

run:
	./contrast example1.jpg ex1

clean:
	rm -f *.cm* *.o contrast
