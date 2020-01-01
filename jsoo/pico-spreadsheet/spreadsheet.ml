(* http://rvlasveld.github.io/blog/2013/07/02/creating-interactive-graphs-with-svg-part-1/ *)

open Lwt.Infix
open Js_of_ocaml

module Model = struct

  let nb_lines = 3
  let nb_cols = 4

  type t =
    (* data table, sums line, input value *)
    (float * bool) array array * float array * float

  let calc_sums tab =
    let nb_cols = Array.length tab.(0) in
    let sums = Array.make nb_cols 0. in
    let line l =
      let f j (v, _) =
        sums.(j) <- sums.(j) +. v
      in
      Array.iteri f l
    in
    Array.iter line tab ;
    sums

  let empty =
    let values = Array.make_matrix nb_lines nb_cols (0., false) in
    values.(0).(0) <- (10., false) ; values.(0).(1) <- (25., false) ;
    values.(0).(2) <- (15., false) ; values.(0).(3) <- (40., false) ;
    values.(1).(0) <- (2.5, false) ; values.(1).(1) <- (1.25, false) ;
    values.(1).(2) <- (23., false) ; values.(1).(3) <- (78.12, false) ;
    values.(2).(0) <- (70., false) ; values.(2).(1) <- (56., false) ;
    values.(2).(2) <- (97., false) ; values.(2).(3) <- (6., false) ;
    (values, calc_sums values, 0.)

  let copy_values v =
    let nv = Array.make_matrix nb_lines nb_cols (0., false) in
    let line i l =
      let f j e =
        nv.(i).(j) <- e
      in
      Array.iteri f l
    in
    Array.iteri line v ;
    nv

  let unedit_values v =
    let line i l =
      let f j (e, _) =
        v.(i).(j) <- (e, false)
      in
      Array.iteri f l
    in
    Array.iteri line v

end

type rs = Model.t React.signal
type rf = ?step:React.step -> Model.t -> unit
type rp = rs * rf

module Action = struct

  type t =
      Click_cell of (int * int)
    | Unclick_cell of (int * int)
    | Update_cell of (int * int * string)

end

module Controller = struct

  open Action

  let update a ((rs, rf) : rp) =
    let (values, sums, input_edit) = React.S.value rs in
    let m =
      match a with
      | Click_cell (i, j) ->
        let copy = Model.copy_values values in
        let (v, _) = copy.(i).(j) in
        Model.unedit_values copy ;
        copy.(i).(j) <- (v, true) ;
        (copy, sums, input_edit)
      | Unclick_cell (i, j) ->
        let copy = Model.copy_values values in
        let (v, _) = copy.(i).(j) in
        copy.(i).(j) <- (v, false) ;
        (copy, sums, input_edit)
      | Update_cell (i, j, s) ->
        let (old, _) = values.(i).(j) in
        let v =
          try
            let v = float_of_string s in
            if v < 0. then old else v
          with
          | _ -> old
        in
        let copy = Model.copy_values values in
        copy.(i).(j) <- (v, false) ;
        (copy, Model.calc_sums copy, input_edit)
    in
    rf m

end

module View = struct

  open Action
  open Js_of_ocaml_tyxml.Tyxml_js

  let width = 300.
  let height = 150.
  let stroke_width = 3.
  let r = 5.

  let calc_x_y_circle sums i v =
    let max =
      Array.fold_left (fun acc v -> if v > acc then v else acc) min_float sums
    in
    let pixel_value = max /. height in
    let sep_width = width /. (float_of_int (Array.length sums - 1)) in
    let x = sep_width *. i in
    let x =
      if x <= 0. then x +. r +. (stroke_width /. 2.)
      else if x >= width then x -. r -. (stroke_width /. 2.)
      else x
    in
    let y = abs_float((v /. pixel_value) -. height) in
    let y =
      if y <= 0. then y +. r +. (stroke_width /. 2.)
      else if y >= height then y -. r -. (stroke_width /. 2.)
      else y
    in
    (v, x, y, r)

  let graph (rs, rf) =
    let x_y_circles sums =
      let f (l, i) e =
        (calc_x_y_circle sums i e :: l, i +. 1.)
      in
      let (l, _) = Array.fold_left f ([], 0.) sums in
      List.rev l
    in
    let svg_circles (_, sums, _) =
      let circles acc (v, x, y, r) =
        let c = Js_of_ocaml_tyxml.Tyxml_js.Svg.(
            circle ~a:[a_cx (x, Some `Px); a_cy (y, Some `Px); a_r (r, Some `Px)] [
              title (txt (Printf.sprintf "%.02f" v))
            ]
          )
        in
        c :: acc
      in
      List.fold_left circles [] (x_y_circles sums)
    in
    let svg_surface (_, sums, _) =
      let string_path (acc, i) (v, x, y, _) =
        let x = if i = 0 then 0. else x in
        let x = if (i = (Array.length sums) - 1) then width else x in
        (Printf.sprintf "%s L%f,%f" acc x y, i + 1)
      in
      let (s, _) = List.fold_left string_path ("", 0) (x_y_circles sums) in
      let s = Printf.sprintf "M%d,%f %s L%f,%f Z" 0 height s width height in
      let path = Js_of_ocaml_tyxml.Tyxml_js.Svg.(path ~a:[a_d s] []) in
      [path]
    in
    let rl_svg_circles = ReactiveData.RList.from_signal (React.S.map svg_circles rs) in
    let rl_svg_surface = ReactiveData.RList.from_signal (React.S.map svg_surface rs) in
    let svg = Html5.(svg [ R.Svg.g rl_svg_surface; R.Svg.g rl_svg_circles ]) in
    svg

  let table (rs, rf) =
    let editable_cells (values, _, _) =
      let line (acc, i) l =
        let f (acc, j) (e, edit) =
          let cell_id = Printf.sprintf "cell-%u-%u" i j in
          let s = Printf.sprintf "%.02f" e in
          let key_handler evt =
            if evt##.keyCode = 13 then (
              let tgt = Dom_html.CoerceTo.input(Dom.eventTarget evt) in
              Js.Opt.case tgt
                (fun () -> ())
                (fun e -> Controller.update (Update_cell (i, j, Js.to_string e##.value)) (rs, rf) ;
                  Controller.update (Unclick_cell (i, j)) (rs, rf)) ;
              false
            ) else true
          in
          let blur_handler evt =
            Controller.update (Unclick_cell (i, j)) (rs, rf) ;
            false
          in
          let onclick evt =
            Controller.update (Click_cell (i, j)) (rs, rf) ;
            let doc = Dom_html.document in
            let input = Js.Opt.get (doc##getElementById(Js.string cell_id))
                (fun () -> assert false)
            in
            let tgt = Dom_html.CoerceTo.input input in
            Js.Opt.case tgt
              (fun () -> ())
              (fun e -> e##focus) ;
            false
          in
          let in_td =
            if edit then (
              Html5.(input ~a:[
                  a_id cell_id ;
                  a_input_type `Text ;
                  a_value s ;
                  a_onkeypress key_handler ;
                  a_onkeydown key_handler ;
                  a_onblur blur_handler ;
                ] ())
            ) else
              Html5.txt s
          in
          let td = Html5.td ~a:[Html5.a_onclick onclick] [in_td] in
          (td :: acc, j + 1)
        in
        let (ltd, _) = Array.fold_left f ([], 0) l in
        let ltd = List.rev ltd in
        (Html5.(tr ltd) :: acc, i + 1)
      in
      let (ltd, _) = Array.fold_left line ([], 0) values in
      List.rev ltd
    in
    let sum_cells (_, sums, _) =
      let f acc e =
        let s = Printf.sprintf "%.02f" e in
        (Html5.(td [txt s])) :: acc
      in
      let ltd = List.rev(Array.fold_left f [] sums) in
      Html5.([tr ltd])
    in
    let rl_values = ReactiveData.RList.from_signal (React.S.map editable_cells rs) in
    let rl_sums = ReactiveData.RList.from_signal (React.S.map sum_cells rs) in
    Html5.(tablex ~tfoot:(R.Html5.tfoot rl_sums) [ R.Html5.tbody rl_values ])

  let view (rs, rf) =
    let cells = table (rs, rf) in
    let graph = graph (rs, rf) in
    Html5.(
      div [
        div ~a:[a_class ["comments"]] [
          p [
            txt "Click on a cell. Then type in a positive number and validate with the ENTER key."
          ] ;
          p [
            txt "The sums and the chart will be automatically updated."
          ] ;
        ] ;
        div ~a:[a_class ["graph"]] [ graph ] ;
        div ~a:[a_class ["cells"]] [ cells ] ;
      ]
    )

end

let main _ =
  let doc = Dom_html.document in
  let parent =
    Js.Opt.get (doc##getElementById(Js.string "spreadsheet"))
      (fun () -> assert false)
  in
  let m = Model.empty in
  let rp = React.S.create m in
  Dom.appendChild parent (Js_of_ocaml_tyxml.Tyxml_js.To_dom.of_div (View.view rp)) ;
  Lwt.return ()

let _ = Js_of_ocaml_lwt.Lwt_js_events.onload () >>= main
