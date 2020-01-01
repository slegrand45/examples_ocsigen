(* See "The Algorithmic Beauty of Plants"
   by Przemyslaw Prusinkiewicz and Aristid Lindenmayer.
   http://algorithmicbotany.org/papers/abop/abop.pdf *)

open Lwt.Infix
open Js_of_ocaml

module Config = struct

  type t = {
    width : float ;
    height : float ;
    branch_length : float ;
    theta : float ;
  }

  let init width height =
    let branch_length = height *. 0.0175 in
    let theta = 22.5 in
    { width; height; branch_length; theta }

end

module Model = struct

  type alphabet =	Plus | Minus | Push | Pop | F

  type turtle = (float * float * float) (* x, y, alpha *)

  let rules char =
    match char with
    | F -> [F; F; Minus; Push; Minus; F; Plus; F; Plus; F; Pop; Plus; Push; Plus; F; Minus; F; Minus; F; Pop]
    | Plus -> [Plus]
    | Minus -> [Minus]
    | Push -> [Push]
    | Pop -> [Pop]

  let apply rules n l =
    let replace acc e =
      let v = rules e in
      List.rev_append v acc
    in
    let rec f acc n =
      if n > 0 then (
        let l = List.rev(List.fold_left replace [] acc) in
        f l (n - 1)
      )
      else
        acc
    in
    f l n

  let init = [F]

  let empty conf =
    let turtle = (conf.Config.width /. 2., conf.Config.height, 90.) in
    let stack : turtle Stack.t = Stack.create () in
    (turtle, stack, 0, [])

end

module View = struct

  let depth_to_class d =
    Printf.sprintf "depth%d" d

  let tree conf l =
    let open Model in
    let open Config in
    let pi = acos (- 1.) in
    let f ((x, y, alpha), stack, depth, lines) e =
      let d = conf.branch_length in
      let theta = conf.theta in
      match e with
      | F ->
        (* degree to radian *)
        let alpha' = pi *. (alpha /. 180.) in
        let x' = x +. (d *. (cos alpha')) in
        let y' = abs_float(((abs_float(y -. conf.height)) +. (d *. (sin alpha'))) -. conf.height) in
        let line = Js_of_ocaml_tyxml.Tyxml_js.Svg.(
            line ~a:[a_class [(depth_to_class depth)];
                     a_x1 (x, Some `Px); a_y1 (y, Some `Px); a_x2 (x', Some `Px); a_y2 (y', Some `Px)] []
          )
        in
        ((x', y', alpha), stack, depth, line :: lines)
      | Plus ->
        ((x, y, alpha +. theta), stack, depth, lines)
      | Minus ->
        ((x, y, alpha -. theta), stack, depth, lines)
      | Push ->
        let () = Stack.push (x, y, alpha) stack in
        ((x, y, alpha), stack, depth + 1, lines)
      | Pop ->
        let (x', y', alpha') = Stack.pop stack in
        ((x', y', alpha'), stack, depth - 1, lines)
    in
    List.fold_left f (Model.empty conf) l

  let draw conf node l =
    let (_, _, _, lines) = tree conf l in
    let svg = Js_of_ocaml_tyxml.Tyxml_js.Html5.(svg lines) in
    Dom.appendChild node (Js_of_ocaml_tyxml.Tyxml_js.To_dom.of_node svg)

end

let start conf node =
  let l =
    try
      Model.apply Model.rules 4 Model.init
    with
    | e -> Firebug.console##debug e; raise e;
  in
  View.draw conf node l ;
  Lwt.return ()

let main _ =
  let doc = Dom_html.document in
  Js.Opt.case (doc##getElementById(Js.string "lsystem"))
    (fun _ -> assert false)
    (fun e ->
       let width = float_of_int e##.clientWidth in
       let height = float_of_int e##.clientHeight in
       let conf = Config.init width height in
       start conf e)

let _ = Js_of_ocaml_lwt.Lwt_js_events.onload () >>= main
