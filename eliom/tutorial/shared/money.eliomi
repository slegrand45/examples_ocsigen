
[%%shared.start]

    module Iso4217 : sig

      exception Unknown_code of string

      type usd
      type eur

      type 'a t

      type iso = Iso : 'a t -> iso

      val iso : 'a t -> iso

      val usd : usd t
      val eur : eur t

      val of_string : string -> iso
      val to_string : 'a t -> string
      val symbol : 'a t -> string

    end

    module Currency : sig

      type 'a t

      type amount = Amount : 'a t -> amount

      val of_num : Num.num -> 'a Iso4217.t -> 'a t
      val of_int : int -> 'a Iso4217.t -> 'a t
      val of_int64 : Int64.t -> 'a Iso4217.t -> 'a t

      val (+) : 'a t -> 'a t -> 'a t
      val mult_by_num : Num.num -> 'a t -> 'a t
      val div_by_num : Num.num -> 'a t -> 'a t

      val exchange : 'a Iso4217.t -> 'b t -> 'a t

      val to_string : 'a t -> string
      val to_string_fractional : 'a t -> string
      val to_string_decimal : int -> 'a t -> string
      val to_string_scientific : int -> 'a t -> string

      val symbol : 'a t -> string

      val filter_one_currency : 'a Iso4217.t -> amount list -> amount list
      val same_currency : 'a t -> 'a t -> bool

    end

    module Vat : sig

      type excl
      type incl

      type ('a, 'b) t

      type amount = Amount : ('a, 'b) t -> amount

      val (+) : ('a, 'b) t -> ('a, 'b) t -> ('a, 'b) t
      val mult_by_num : Num.num -> ('a, 'b) t -> ('a, 'b) t
      val div_by_num : Num.num -> ('a, 'b) t -> ('a, 'b) t

      val exchange : 'a Iso4217.t -> ('b, 'c) t -> ('a, 'c) t

      val to_string : ('a, 'b) t -> string
      val to_string_fractional : ('a, 'b) t -> string
      val to_string_decimal : int -> ('a, 'b) t -> string
      val to_string_scientific : int -> ('a, 'b) t -> string

      val excl : 'a Currency.t -> ('a, excl) t
      val incl : 'a Currency.t -> ('a, incl) t

      val to_excl : ('a, incl) t -> ('a, excl) t
      val to_incl : ('a, excl) t -> ('a, incl) t

      val symbol_currency : ('a, 'b) t -> string

      val filter_one_currency : 'a Iso4217.t -> amount list -> amount list

      val idiom : Language.t -> ('a, 'b) t -> I18n.t option

    end
