
ocamlbuild -use-ocamlfind \
  -pkgs js_of_ocaml,js_of_ocaml.ppx,js_of_ocaml.tyxml,tyxml,react,reactiveData \
  main.byte ;

js_of_ocaml +weak.js --opt 3 -o js/main.js main.byte
