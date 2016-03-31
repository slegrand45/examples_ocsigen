for f in `find . -name '*.ml*'` ; \
do ( \
	ocp-indent -i $f; \
); \
done

ocamlbuild -use-ocamlfind \
  -pkgs lwt.ppx,js_of_ocaml,js_of_ocaml.ppx,js_of_ocaml.tyxml,tyxml,react,reactiveData \
  spreadsheet.byte ;

js_of_ocaml +weak.js --opt 3 -o www/js/spreadsheet.js spreadsheet.byte
