
ocamlbuild -use-ocamlfind \
  -pkgs lwt.ppx,js_of_ocaml,js_of_ocaml.ppx,js_of_ocaml.tyxml,tyxml,ppx_deriving,js_of_ocaml.deriving.ppx,js_of_ocaml.deriving,react,reactiveData \
  main.byte ;

js_of_ocaml +weak.js --opt 3 -o js/main.js main.byte
