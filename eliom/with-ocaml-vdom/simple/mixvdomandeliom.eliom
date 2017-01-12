
module Service = struct

  let random_value =
    Eliom_registration.Ocaml.create
      (* having a path is better to avoid broken links if the user doesn't refresh the page after a server restart *)
      ~path:(Eliom_service.Path ["rnd"])
      ~meth:(Eliom_service.Get (Eliom_parameter.unit))
      (fun () () ->
         let i = Random.int 200 in
         if i > 100 then
           Lwt.return_ok(Printf.sprintf "Ok: random value %u > 100" i)
         else
           Lwt.return_error(Printf.sprintf "Error: random value %u <= 100" i)
      )

end

[%%client

type 'msg Vdom.Cmd.t +=
  | Service of { on_ok: (string -> 'msg); on_error: (string -> 'msg) }

let create_service ~on_ok ~on_error = Service { on_ok; on_error }

let run_service ~on_ok ~on_error () =
  let%lwt v = Eliom_client.call_ocaml_service ~service:~%Service.random_value () () in
  match v with
  | Ok v -> on_ok v
  | Error v -> on_error v

let cmd_handler ctx = function
  | Service { on_ok; on_error } ->
    let _ = run_service 
        ~on_ok:(fun s -> Lwt.return(Vdom_blit.Cmd.send_msg ctx (on_ok s)))
        ~on_error:(fun s -> Lwt.return(Vdom_blit.Cmd.send_msg ctx (on_error s)))
        ()
    in
    true

let () = Vdom_blit.(register (cmd {Vdom_blit.Cmd.f = cmd_handler}))

type model = {
  counter_ok : int ;
  counter_error : int ;
  message : string ;
}

type action =
  | Call_service
  | Service_called_ok of string
  | Service_called_error of string

let update m = function
  | Call_service -> (
      Vdom.return m ~c:[create_service ~on_ok:(fun r -> Service_called_ok r) ~on_error:(fun r -> Service_called_error r)]
    )
  | Service_called_ok v -> Vdom.return { m with counter_ok = m.counter_ok + 1; message = v }
  | Service_called_error v -> Vdom.return { m with counter_error = m.counter_error + 1; message = v }

let init = Vdom.return { counter_ok = 0; counter_error = 0; message = "No message" }

let button txt msg =
  Vdom.(input [] ~a:[onclick msg; type_button; value txt])

let view m =
  Vdom.(
    div [
      div [
        button "Fetch a random value from server" Call_service
      ] ;
      div [
        text (Printf.sprintf "%u OK value(s)" m.counter_ok) ;
        text " / " ;
        text (Printf.sprintf "%u ERROR value(s)" m.counter_error) ;
      ] ;
      div [
        text m.message
      ] ;
    ]
  )

let app = Vdom.app ~init ~view ~update ()

let run () =
  Vdom_blit.run app
  |> Vdom_blit.dom
  |> Js_browser.Element.append_child (Js_browser.Document.body Js_browser.document)
let () = Js_browser.Window.set_onload Js_browser.window run
]

module Mixvdomandeliom_app =
  Eliom_registration.App (
  struct
    let application_name = "mixvdomandeliom"
    let global_data_path = None
  end)

let main_service =
  Eliom_service.create
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

let () =
  Mixvdomandeliom_app.register
    ~service:main_service
    (fun () () ->
       Lwt.return
         (Eliom_tools.F.html
            ~title:"mixvdomandeliom"
            ~css:[["css";"mixvdomandeliom.css"]]
            Eliom_content.Html.F.(body [
              h1 [pcdata "Demo mix Vdom / Eliom"];
            ])))
