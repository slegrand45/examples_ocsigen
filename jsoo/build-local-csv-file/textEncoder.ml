class type t = object
  method encode_uint8 : Js.js_string Js.t -> Typed_array.uint8Array Js.t Js.meth
end

let textEncoder = Js.Unsafe.global##._TextEncoder