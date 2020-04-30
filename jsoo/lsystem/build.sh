for f in `find . -name '*.ml*'` ; \
do ( \
	ocp-indent -i $f; \
); \
done

ocamlbuild -use-ocamlfind \
  -pkgs lwt_ppx,js_of_ocaml-lwt,js_of_ocaml-ppx,js_of_ocaml-tyxml,tyxml,react,reactiveData \
  lsystem.byte ;

js_of_ocaml --opt 3 -o www/js/lsystem.js lsystem.byte
