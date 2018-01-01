let lang_and_iso4217_parameters =
  Eliom_parameter.(
    (opt(
       user_type
         ~client_to_and_of:([%client { Eliom_parameter.of_string = Language.of_string; Eliom_parameter.to_string = Language.to_string } ])
         ~of_string:Language.of_string
         ~to_string:Language.to_string
         "lang"))
    **
    (opt(
       user_type
         ~client_to_and_of:([%client { Eliom_parameter.of_string = Money.Iso4217.of_string;
                                       Eliom_parameter.to_string = (fun v -> match v with Money.Iso4217.Iso iso -> Money.Iso4217.to_string iso) } ])
         ~of_string:Money.Iso4217.of_string
         ~to_string:(fun v -> match v with Money.Iso4217.Iso iso -> Money.Iso4217.to_string iso)
         "iso4217"))
  )

let main =
  Eliom_service.create
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get lang_and_iso4217_parameters)
    ()

let add =
  let path = Eliom_service.Path ["product"; "add"] in
  (Eliom_service.create ~path
    ~meth:(Eliom_service.Get lang_and_iso4217_parameters)
    (),
  Eliom_service.create ~path
    ~meth:(Eliom_service.Post (lang_and_iso4217_parameters,
      Eliom_parameter.(
        (string "code") ** (string "name") ** (string "price"))))
    ())
