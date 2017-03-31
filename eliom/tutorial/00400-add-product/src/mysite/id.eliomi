type t

val empty : t
val of_int64 : Int64.t -> t
val to_string : t -> string
val compare : t -> t -> int
val succ : t -> t