open Js_of_ocaml

class type t = object
  method encode_uint8 : Js.js_string Js.t -> Typed_array.uint8Array Js.t Js.meth
end

val textEncoder : t Js.t Js.constr