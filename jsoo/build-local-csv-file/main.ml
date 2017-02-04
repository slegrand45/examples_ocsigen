
(*
  Polyfill for the Encoding Living Standard's API:
    https://github.com/inexorabletash/text-encoding
*)

open Lwt.Infix

module Model = struct

  type t =
    (* tiny href * big href *)
    Js.js_string Js.t option * Js.js_string Js.t option

  let csv_sep = ","

  let nb_lines_tiny = 3
  let nb_cols_tiny = 4

  let nb_lines_big = 400
  let nb_cols_big = 20

  let make_data nb_lines nb_cols =
    let data = Array.make_matrix nb_lines nb_cols "" in
    for i = 0 to (nb_lines - 1) do
      for j = 0 to (nb_cols - 1) do
        data.(i).(j) <- Printf.sprintf "Cell é è ç à ù € ∀ ◉ %u.%u" i j
      done ;
    done ;
    data

  let data_tiny = make_data nb_lines_tiny nb_cols_tiny

  let data_big = make_data nb_lines_big nb_cols_big

  let empty = (None, None)

  let csv_headers data =
    let nb_cols = Array.length data.(0) in
    let s = ref "" in
    for i = 0 to (nb_cols - 1) do
      if i = (nb_cols - 1) then
        s := !s ^ (Printf.sprintf "Column %u" i)
      else
        s := !s ^ (Printf.sprintf "Column %u%s" i csv_sep)
    done ;
    !s

  let csv_body data =
    let nb_cols = Array.length data.(0) in
    let s = ref "" in
    let column i v =
      if i > 0 && i < nb_cols then
        s := !s ^ csv_sep ^ v
      else
        s := !s ^ v
    in
    let line l =      
      Array.iteri column l ;
      s := !s ^ "\n"
    in
    Array.iter line data ;
    !s

  let csv data =
    (csv_headers data) ^ "\n" ^ (csv_body data)

end

type rs = Model.t React.signal
type rf = ?step:React.step -> Model.t -> unit
type rp = rs * rf

module Action = struct

  type t =
    | Download_tiny_csv
    | Download_big_csv

end

module Controller = struct

  open Action

  let encode_href href v =
    let blob = Blob.blob_uint8 in
    let encoder = TextEncoder.textEncoder in
    let url = (Dom_html.window)##._URL in

    let () =
      match href with
      | None -> ()
      | Some h -> url##revokeObjectURL h
    in

    (* add BOM as first character to force the right encoding
       when the url is opened by the spreadsheet software *)
    let utf8_bom = new%js Typed_array.uint8Array 3 in
    let () = Typed_array.set utf8_bom 0 0xEF  in
    let () = Typed_array.set utf8_bom 1 0xBB  in
    let () = Typed_array.set utf8_bom 2 0xBF  in

    let opt = object%js
      val _type = "text/csv;charset=utf-8"
    end in
    let e = new%js encoder in
    let data = e##encode_uint8 (Js.string v) in
    let o = new%js blob (Js.array [| utf8_bom; data |]) opt in
    let url = url##createObjectURL o in
    url

  let update a ((rs, rf) : rp) =
    let href_tiny, href_big = React.S.value rs in
    let m =
      match a with
      | Download_tiny_csv ->
        let csv = Model.(csv data_tiny) in
        let href_tiny = encode_href href_tiny csv in
        (Some href_tiny, href_big)
      | Download_big_csv ->
        let csv = Model.(csv data_big) in
        let href_big = encode_href href_big csv in
        (href_tiny, Some href_big)
    in
    rf m

end

module View = struct

  open Action
  open Tyxml_js

  let link_tiny_csv (rs, rf) =
    let onclick evt =
      Controller.update Download_tiny_csv (rs, rf) ;
      true (* return true because we must follow the link *)
    in
    let href = React.S.map (fun (v, _) -> match v with None -> "#" | Some h -> Js.to_string h) rs in
    Html.(a ~a:[a_onclick onclick; a_download (Some "tinyfile.csv");
                R.Html.a_href href] [pcdata "Get CSV from above"])

  let link_big_csv (rs, rf) =
    let onclick evt =
      Controller.update Download_big_csv (rs, rf) ;
      true (* return true because we must follow the link *)
    in
    let href = React.S.map (fun (_, v) -> match v with None -> "#" | Some h -> Js.to_string h) rs in
    Html.(a ~a:[a_onclick onclick; a_download (Some "bigfile.csv");
                R.Html.a_href href] [pcdata "Get bigger CSV (not displayed)"])

  let table (rs, rf) =
    let cells data =
      let line (acc, i) l =
        let f (acc, j) v =
          let td = Html.(td [pcdata v]) in
          (td :: acc, j + 1)
        in
        let (ltd, _) = Array.fold_left f ([], 0) l in
        let ltd = List.rev ltd in
        (Html.(tr ltd) :: acc, i + 1)
      in
      let (ltd, _) = Array.fold_left line ([], 0) data in
      List.rev ltd
    in
    Html.(tablex [ Html.tbody (cells Model.data_tiny) ])

  let view (rs, rf) =
    let cells = table (rs, rf) in
    Html.(
      div [
        p ~a:[a_class ["comments"]] [
          pcdata "How to build and download a CSV file without any server processing and only from client side data." ;
          br () ;
          pcdata "This demo has been tested with Firefox, Chrome and Edge. But please note that a " ;
          a ~a:[a_href "https://github.com/inexorabletash/text-encoding"] [ pcdata "polyfill" ] ;
          pcdata " is necessary for Edge." ;
        ] ;
        div ~a:[a_class ["cells"]] [ cells ] ;
        div ~a:[a_class ["tiny-csv"]] [ link_tiny_csv (rs, rf) ] ;
        div ~a:[a_class ["big-csv"]] [ link_big_csv (rs, rf) ] ;
      ]
    )

end

let main _ =
  let doc = Dom_html.document in
  let parent =
    Js.Opt.get (doc##getElementById(Js.string "main"))
      (fun () -> assert false)
  in
  let m = Model.empty in
  let rp = React.S.create m in
  Dom.appendChild parent (Tyxml_js.To_dom.of_div (View.view rp)) ;
  Lwt.return ()

let _ = Lwt_js_events.onload () >>= main