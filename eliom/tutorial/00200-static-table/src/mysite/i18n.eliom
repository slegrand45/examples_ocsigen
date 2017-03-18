
[%%shared.start]

    type t = Language.t * string

    let make lang s = (lang, s)

    let translate lang (l: t list) =
      try
        let s = List.assoc lang l in
        Some (lang, s)
      with
      | Not_found -> None

    let to_string (_, s) = s
