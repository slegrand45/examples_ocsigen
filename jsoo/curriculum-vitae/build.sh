
ocamlbuild -use-ocamlfind \
  -pkgs lwt.syntax,js_of_ocaml,js_of_ocaml.syntax,js_of_ocaml.tyxml,tyxml,react,reactiveData \
  -syntax camlp4o \
  main.byte ;

js_of_ocaml +weak.js --opt 3 -o js/main.js main.byte
