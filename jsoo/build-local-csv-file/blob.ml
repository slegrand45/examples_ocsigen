class type options = object
  method _type : string Js.readonly_prop
end

let blob_uint8 = Js.Unsafe.global##._Blob