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

  let page f lang iso4217 params =
    Eliom_tools.F.html
      ~title:"mysite"
      ~other_head:[css_bulma; css_mysite]
      (f lang iso4217 params)
  in
  let error_handler f params l =
    let html =
      match l with
      | []
      | ("lang", Language.Unknown_language _) :: [] ->
          page f Config.default_language Config.default_iso4217 params
      | ("iso4217", Money.Iso4217.Unknown_code _) :: [] ->
          page f Config.default_language Config.default_iso4217 params
      | (_, e) :: _ -> raise e
    in
    Lwt.return html
  in
  let register f (lang, iso4217) params =
    let html = 
      match lang, iso4217 with
      | None, None -> page f Config.default_language Config.default_iso4217 params
      | Some vl, None -> page f vl Config.default_iso4217 params
      | None, Some vi -> page f Config.default_language vi params
      | Some vl, Some vi -> page f vl vi params
    in
    Lwt.return html
  in
  Mysite_app.register
    ~service:Service.main
    ~error_handler:(error_handler View.list ())
    (register View.list) ;
  Mysite_app.register
    ~service:(fst Service.add) (* GET to display the form *)
    ~error_handler:(error_handler View.form_add ())
    (register View.form_add) ;
  Mysite_app.register
    ~service:(snd Service.add) (* POST to add the product *)
    ~error_handler:(error_handler View.add ("", ("", "")))
    (register View.add) ;
