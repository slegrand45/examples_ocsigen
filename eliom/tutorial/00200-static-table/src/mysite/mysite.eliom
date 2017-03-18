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

let main_service =
  Eliom_service.create
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

let () =
  let css_bulma =
    Eliom_content.Html.F.(
      css_link
        ~uri:(
          make_uri
            ~service:(Eliom_service.static_dir ())
            ~https:true ~hostname:"cdnjs.cloudflare.com"
            ["ajax"; "libs"; "bulma"; "0.3.1"; "css"; "bulma.min.css"]
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
  Mysite_app.register
    ~service:main_service
    (fun () () ->
       Lwt.return
         (Eliom_tools.F.html
            ~title:"mysite"
            ~other_head:[css_bulma; css_mysite]
            View.body))
