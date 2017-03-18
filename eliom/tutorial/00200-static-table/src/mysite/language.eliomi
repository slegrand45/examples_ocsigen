
[%%shared.start]

    exception Unknown_language of string

    type t =
      | En
      | Fr

    val of_string : string -> t
    val to_string : t -> string