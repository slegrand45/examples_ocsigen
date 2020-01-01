open Js_of_ocaml
open Lwt.Infix
open Types

(* https://github.com/ocsigen/js_of_ocaml/blob/master/examples/hyperbolic/hypertree.ml *)
let default_language () =
  Js.to_string(
    (Js.Optdef.get (Dom_html.window##.navigator##.language)
       (fun () -> Js.Optdef.get (Dom_html.window##.navigator##.userLanguage)
           (fun () -> Js.string "en"))
    )##substring 0 2)

let main _ =
  let doc = Dom_html.document in
  let parent =
    Js.Opt.get (doc##getElementById(Js.string "main"))
      (fun () -> assert false)
  in
  let lang = 
    match default_language () with
    | "en" -> I18n.En
    | _ -> I18n.Fr
  in
  let m = Model.init lang in
  let rp = React.S.create m in
  Dom.appendChild parent (Js_of_ocaml_tyxml.Tyxml_js.To_dom.of_div (View.view rp)) ;
  Lwt.return ()

let _ = Js_of_ocaml_lwt.Lwt_js_events.onload () >>= main
