
[%%shared.start]

    exception Unknown_language of string

    type t =
      | En
      | Fr

    let of_string = function
      | "en" -> En
      | "fr" -> Fr
      | s -> raise(Unknown_language s)

    let to_string = function
      | En -> "en"
      | Fr -> "fr"