(* 
	Trick to get the type:
		1 - use (_, _, _, _, _, _, _, _, _, _, _) Eliom_service.t
		2 - copy-paste the type from the compiler error message
*)

val main : (Language.t option * Money.Iso4217.iso option,
            unit,
            Eliom_service.get,
            Eliom_service.att,
            Eliom_service.non_co,
            Eliom_service.non_ext,
            Eliom_service.reg,
            [ `WithoutSuffix ],
            [ `One of Language.t ] Eliom_parameter.param_name * [ `One of Money.Iso4217.iso ] Eliom_parameter.param_name,
            unit,
            Eliom_service.non_ocaml)
    Eliom_service.t

val add : (Language.t option * Money.Iso4217.iso option, unit,
            Eliom_service.get, Eliom_service.att, Eliom_service.non_co,
            Eliom_service.non_ext, Eliom_service.reg, [ `WithoutSuffix ],
            [ `One of Language.t ] Eliom_parameter.param_name *
            [ `One of Money.Iso4217.iso ] Eliom_parameter.param_name, 
            unit, Eliom_service.non_ocaml)
      Eliom_service.t *
           (Language.t option * Money.Iso4217.iso option,
            string * (string * string), Eliom_service.post,
            Eliom_service.att, Eliom_service.non_co, Eliom_service.non_ext,
            Eliom_service.reg, [ `WithoutSuffix ],
            [ `One of Language.t ] Eliom_parameter.param_name *
            [ `One of Money.Iso4217.iso ] Eliom_parameter.param_name,
            [ `One of string ] Eliom_parameter.param_name *
            ([ `One of string ] Eliom_parameter.param_name *
             [ `One of string ] Eliom_parameter.param_name),
            Eliom_service.non_ocaml)
      Eliom_service.t
