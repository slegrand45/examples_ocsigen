
type t = {
  id : Id.t ;
  code : string ;
  names : I18n.t list ;
  prices : Money.Vat.amount list ;
}

let empty = {
  id = Id.empty ;
  code = "" ;
  names = [] ;
  prices = [] ;
}

let get_id v = v.id

let set_id id v = { v with id }

let get_code v = v.code

let set_code code v = { v with code }

let get_names v = v.names

let set_names names v = { v with names }

let get_prices v = v.prices

let set_prices prices v = { v with prices }
