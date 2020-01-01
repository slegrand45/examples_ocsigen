open Lwt.Infix
open Types
open Js_of_ocaml

let main _ =
  let doc = Dom_html.document in
  let parent =
    Js.Opt.get (doc##getElementById(Js.string "main"))
      (fun () -> assert false)
  in
  let m = Model.empty_game in
  let rp = React.S.create m in
  Dom.appendChild parent (Js_of_ocaml_tyxml.Tyxml_js.To_dom.of_div (View.view rp)) ;
  Lwt.return ()

let _ = Js_of_ocaml_lwt.Lwt_js_events.onload () >>= main
