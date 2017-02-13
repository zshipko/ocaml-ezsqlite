ccopt=-std=c99

all: lib.byte lib.native

lib.native:
	$(CC) $(ccopt) -c -o lib/sqlite.o lib/ezsqlite_stubs.o lib/ezsqlite_stubs.c -I `ocamlc -where`
	ar rcs libezsqlite_stubs.a lib/ezsqlite_stubs.o
	ocamlopt -ccopt "$(ccopt)" -a -o ezsqlite.cmxa -I . -cclib -lezsqlite_stubs lib/ezsqlite.ml

lib.byte:
	rm -f libezsqlite_stubs.a
	$(CC) $(ccopt) -shared -fPIC -o dllezsqlite_stubs.so lib/sqlite.o lib/ezsqlite_stubs.c -I `ocamlc -where`
	ocamlc -ccopt "$(ccopt)" -a -o ezsqlite.cma -I . -dllib -lezsqlite_stubs lib/ezsqlite.ml

install:
	make uninstall || :
	ocamlfind install ezsqlite META ezsqlite.cmxa ezsqlite.cmx ezsqlite.cmi ezsqlite.a libezsqlite_stubs.a dllezsqlite_stubs.so ezsqlite.cma

uninstall:
	ocamlfind remove ezsqlite

clean:
	rm -f *.o *.cm* *.so *.a *.mli
