class type options = object
  method _type : string Js.readonly_prop
end

val blob_uint8 : (Typed_array.uint8Array Js.t Js.js_array Js.t -> options Js.t -> File.blob Js.t) Js.constr