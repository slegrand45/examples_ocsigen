[%%shared
open Eliom_lib
open Eliom_content
open Html.D
]

module Mysite_app =
  Eliom_registration.App (
  struct
    let application_name = "mysite"
    let global_data_path = None
  end)

let () =
  let css_bulma =
    Eliom_content.Html.F.(
      css_link
        ~uri:(
          make_uri
            ~service:(Eliom_service.static_dir ())
            ~https:true ~hostname:"cdnjs.cloudflare.com"
            ["ajax"; "libs"; "bulma"; "0.4.0"; "css"; "bulma.min.css"]
        ) ()
    )
  in
  let css_mysite =
    Eliom_content.Html.F.(
      css_link
        ~uri:(
          make_uri
            ~service:(Eliom_service.static_dir ())
            ~absolute:true
            ["css";"mysite.css"]
        ) ()
    )
  in

  let page lang iso4217 =
    Eliom_tools.F.html
      ~title:"mysite"
      ~other_head:[css_bulma; css_mysite]
      (View.body lang iso4217)
  in
  Mysite_app.register
    ~service:Service.main
    ~error_handler:(fun l ->
      match l with
      | []
      | ("lang", Language.Unknown_language _) :: [] -> Lwt.return(page Config.default_language Config.default_iso4217)
      | ("iso4217", Money.Iso4217.Unknown_code _) :: [] -> Lwt.return(page Config.default_language Config.default_iso4217)
      | (_, e) :: _ -> raise e
    )
    (fun (lang, iso4217) () ->
       match lang, iso4217 with
       | None, None -> Lwt.return(page Config.default_language Config.default_iso4217)
       | Some vl, None -> Lwt.return(page vl Config.default_iso4217)
       | None, Some vi -> Lwt.return(page Config.default_language vi)
       | Some vl, Some vi -> Lwt.return(page vl vi))
