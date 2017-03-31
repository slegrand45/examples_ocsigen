
type t

val empty : t

val get_id : t -> Id.t
val set_id : Id.t -> t -> t

val get_code : t -> string
val set_code : string -> t -> t

val get_names : t -> I18n.t list
val set_names : I18n.t list -> t -> t

val get_prices : t -> Money.Vat.amount list
val set_prices : Money.Vat.amount list -> t -> t
