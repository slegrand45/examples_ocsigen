
[%%shared.start]

    module Iso4217 = struct

      exception Unknown_code of string

      type usd
      type eur

      type 'a t =
        | Usd : usd t
        | Eur : eur t

      type iso = Iso : 'a t -> iso

      let iso v = Iso v

      let usd : usd t = Usd

      let eur : eur t = Eur

      let of_string (type a) (s:string) : iso =
        match s with
        | "usd" -> Iso Usd
        | "eur" -> Iso Eur
        | _ -> raise(Unknown_code s)

      let to_string (type a) (v:a t) : string =
        match v with
        | Usd -> "usd"
        | Eur -> "eur"

      let one = Num.num_of_int 1

      let exchange_rate (type a b) ~(for_one:a t) ~(get:b t) : Num.num =
        match for_one, get with
        | Usd, Eur -> Num.num_of_string "934813/1000000"
        | Eur, Usd -> Num.num_of_string "106951/100000"
        | Usd, Usd -> one
        | Eur, Eur -> one

      let symbol (type a) (v:a t) : string =
        match v with
        | Eur -> "€"
        | Usd -> "$"

      let eq (type a b) (v1:a t) (v2:b t) : bool =
        match v1, v2 with
        | Eur, Eur -> true
        | Usd, Usd -> true
        | _ -> false

    end

    module Currency = struct

      type 'a t = Num.num * 'a Iso4217.t

      type amount = Amount : 'a t -> amount

      let of_num (v:Num.num) (iso:'a Iso4217.t) : 'a t =
        (v, iso)

      let of_int v iso =
        of_num (Num.num_of_int v) iso

      let of_int64 v iso =
        of_num (Num.num_of_string(Int64.to_string v)) iso

      let of_string v iso =
        let accuracy_float = 10000. in
        let accuracy_int = 10000 in
        let x =
          (float_of_string v) *. accuracy_float
          |> Int64.of_float
          |> Int64.to_string
          |> Num.num_of_string
        in
        let x = Num.div_num x (Num.num_of_int accuracy_int) in
        of_num x iso

      let (+) (v1:'a t) (v2:'a t) : 'a t =
        let x1, iso = v1 in
        let x2, iso = v2 in
        (Num.add_num x1 x2, iso)

      let op_num op (n:Num.num) (v:'a t) : 'a t =
        let x, iso = v in
        (op x n, iso)

      let mult_by_num n v =
        op_num Num.mult_num n v

      let div_by_num n v =
        op_num Num.div_num n v

      let exchange (type a b) (to_iso: b Iso4217.t) (v: a t) : b t =
        let x, from_iso = v in
        (Num.mult_num x (Iso4217.exchange_rate ~for_one:from_iso ~get:to_iso), to_iso)

      let to_string_x f (x, _) =
        f x

      let to_string v =
        let f v =
          let s = Num.approx_num_fix 2 v in
          let s = String.sub s 1 ((String.length s) - 1) in
          if Num.sign_num v < 0 then
            "- " ^ s
          else
            s
        in
        to_string_x f v

      let to_string_fractional v =
        to_string_x Num.string_of_num v

      let to_string_decimal digits v =
        to_string_x (Num.approx_num_fix digits) v

      let to_string_scientific digits v =
        to_string_x (Num.approx_num_exp digits) v

      let symbol (_, iso) =
        Iso4217.symbol iso

      let filter_one_currency iso l =
        let f v =
          match v with
          | Amount (_, x) -> Iso4217.eq x iso
        in
        List.filter f l

      let same_currency (_, iso1) (_, iso2) =
        Iso4217.eq iso1 iso2

    end

    module Vat = struct

      type excl
      type incl

      type ('a, 'b) t =
        | Excl : 'a Currency.t -> ('a, excl) t
        | Incl : 'a Currency.t -> ('a, incl) t

      type amount = Amount : ('a, 'b) t -> amount

      let apply1_x (type b) f (v:('a, b) t) =
        match v with
        | Incl v -> f v
        | Excl v -> f v

      let apply1 (type b) f (v:('a, b) t) : ('a, b) t =
        match v with
        | Incl v -> Incl(f v)
        | Excl v -> Excl(f v)

      let apply2 (type b) f (v1:('a, b) t) (v2:('a, b) t) : ('a, b) t =
        match v1, v2 with
        | Incl v1, Incl v2 -> Incl(f v1 v2)
        | Excl v1, Excl v2 -> Excl(f v1 v2)

      let (+) v1 v2 =
        apply2 Currency.(+) v1 v2

      let mult_by_num x v =
        apply1 (Currency.mult_by_num x) v

      let div_by_num x v =
        apply1 (Currency.div_by_num x) v

      let exchange (type a b c) iso (v:(a, b) t) : (c, b) t =
        match v with
        | Incl v -> Incl(Currency.exchange iso v)
        | Excl v -> Excl(Currency.exchange iso v)

      let to_string v =
        apply1_x Currency.to_string v

      let to_string_fractional v =
        apply1_x Currency.to_string_fractional v

      let to_string_decimal digits =
        apply1_x (Currency.to_string_decimal digits)

      let to_string_scientific digits =
        apply1_x (Currency.to_string_scientific digits)

      let excl v = Excl v
      let incl v = Incl v

      let tax_rate =
        Num.num_of_string "120/100"

      let to_excl (v:('a, incl) t) : ('a, excl) t =
        match v with
        | Incl v -> Excl(Currency.div_by_num tax_rate v)

      let to_incl (v:('a, excl) t) : ('a, incl) t =
        match v with
        | Excl v -> Incl(Currency.mult_by_num tax_rate v)

      let symbol_currency (type b) (v:('a, b) t) = 
        apply1_x Currency.symbol v

      let filter_one_currency iso l =
        let f v =
          match v with
          | Amount a ->
            match a with
            | Incl i -> Currency.same_currency i (Currency.of_int 0 iso)
            | Excl e -> Currency.same_currency e (Currency.of_int 0 iso)
        in
        List.filter f l

      let idiom (type b) lang (v:('a, b) t) : I18n.t option =
        let l =
          match v with
          | Excl _ -> [
              I18n.make Language.En "excl. VAT" ;
              I18n.make Language.Fr "HT" ;
            ]
          | Incl _ -> [
              I18n.make Language.En "incl. VAT" ;
              I18n.make Language.Fr "TTC" ;
            ]
        in
        I18n.translate lang l

    end
