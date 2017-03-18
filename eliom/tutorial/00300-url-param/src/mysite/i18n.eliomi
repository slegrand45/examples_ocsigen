
[%%shared.start]

    type t

    val make : Language.t -> string -> t
    val translate : Language.t -> t list -> t option
    val to_string : t -> string
