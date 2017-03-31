val list : Language.t -> Money.Iso4217.iso -> unit -> [ `Body ] Eliom_content.Html.elt
val form_add : Language.t -> Money.Iso4217.iso -> unit -> [ `Body ] Eliom_content.Html.elt
val add : Language.t -> Money.Iso4217.iso -> (string * (string * string)) -> [ `Body ] Eliom_content.Html.elt