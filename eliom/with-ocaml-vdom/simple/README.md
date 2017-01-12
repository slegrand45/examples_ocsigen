How to use Eliom services with OCaml Vdom. Tested with Eliom 6.1 and OCaml Vdom 0.1.
It's mainly a proof of concept. Nonetheless, it could be an interesting lighter approach compared to a classic Eliom project. One downside is that you loose the safety given by TyXML. But the client code is simpler.
Note that `Makefile` and `Makefile.options` are different from the default files:
- In `Makefile` you must add `-no-check-prims -jsopt +gen_js_api/ojs_runtime.js` to `JS_OF_ELIOM`
- In `Makefile.options` you must add `ocaml-vdom` to `CLIENT_PACKAGES`

