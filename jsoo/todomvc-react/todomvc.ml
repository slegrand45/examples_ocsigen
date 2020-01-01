open Lwt.Infix
open Js_of_ocaml

(* Utility module for local storage. *)
module Storage = struct

  open Js

  let storage =
    Optdef.case Dom_html.window##.localStorage
      (fun () -> failwith "Storage is not supported by this browser")
      (fun v -> v)

  let key = string "jsoo-todo-state"

  let find () =
    let r = storage##getItem key in
    Opt.to_option @@ Opt.map r to_string

  let set v = storage##setItem key (string v)

  let init default = match find () with
    | None -> set default ; default
    | Some v -> v

end

(* Application data *)
module Model = struct

  type visibility =
      Completed | Active | All
        [@@deriving json]

  type task = {
    description : string ;
    (* backup field keep the previous description to restore it when ESC key is pressed *)
    backup : string ;
    completed : bool ;
    editing : bool ;
    id : int ;
  } [@@deriving json]

  type t = {
    tasks : task list ;
    field : string ;
    uid : int ;
    visibility : visibility ;
  } [@@deriving json] (* to save/restore the state in JSON *)

  let empty = {
    tasks = [] ;
    field = "" ;
    uid = 0 ;
    visibility = All ;
  }

  let new_task desc id = {
    description = desc ;
    backup = desc ;
    completed = false ;
    editing = false ;
    id = id
  }

  let string_of_visibility v =
    match v with
    | Completed -> "Completed"
    | Active -> "Active"
    | All -> "All"

  let from_json s =
    Deriving_Json.from_string [%json: t] s

  let to_json m =
    Deriving_Json.to_string [%json: t] m

end

type rs = Model.t React.signal
type rf = ?step:React.step -> Model.t -> unit
type rp = rs * rf

(* User interface actions *)
module Action = struct

  type action =
    | Update_field of Js.js_string Js.t
    | Editing_task of (int * bool)
    | Update_task of (int * Js.js_string Js.t)
    | Add
    | Delete of int
    | Delete_complete
    | Check of (int * bool)
    | Check_all of bool
    | Change_visibility of Model.visibility
    | Escape of int

end

(* Manage actions, refresh view if needed and save the state in local storage *)
module Controller = struct

  let update a ((r, f) : rp) =
    let open Action in
    let open Model in
    let m = React.S.value r in
    let m =
      match a with
      | Add ->
        let uid = m.uid + 1 in
        let tasks =
          let v = String.trim m.field in
          if v = "" then m.tasks
          else (new_task v m.uid) :: m.tasks
        in
        { m with uid = uid; field = "" ; tasks = tasks }
      | Update_field field ->
        { m with field = Js.to_string field }
      | Editing_task (id, is_edit) ->
        let update_task t =
          if (t.id = id) then
            let v = String.trim t.description in
            { t with editing = is_edit ; description = v ; backup = v }
          else t
        in
        let l = List.map update_task m.tasks in
        let l = List.filter (fun e -> e.description <> "") l in
        { m with tasks = l }
      | Update_task (id, task) ->
        let update_task t =
          if (t.id = id) then { t with description = Js.to_string task }
          else t
        in
        { m with tasks = List.map update_task m.tasks }
      | Delete id ->
        { m with tasks = List.filter (fun e -> e.id <> id) m.tasks }
      | Delete_complete ->
        { m with tasks = List.filter (fun e -> not e.completed) m.tasks }
      | Check (id, is_compl) ->
        let update_task t =
          if (t.id = id) then { t with completed = is_compl }
          else t
        in
        { m with tasks = List.map update_task m.tasks }
      | Check_all is_compl ->
        let update_task t =
          { t with completed = is_compl }
        in
        { m with tasks = List.map update_task m.tasks }
      | Change_visibility visibility ->
        { m with visibility = visibility }
      | Escape id ->
        let unedit_task t =
          if (t.id = id) then
            { t with editing = false ; description = t.backup }
          else t
        in
        { m with tasks = List.map unedit_task m.tasks }
    in
    Storage.set @@ Model.to_json m ;
    f m

end

(* Build HTML and send user actions *)
module View = struct

  open Model
  open Action
  open Js_of_ocaml_tyxml.Tyxml_js

  module Ev = Js_of_ocaml_lwt.Lwt_js_events
  let bind_event ev elem handler =
    let handler evt _ = handler evt in
    Ev.(async @@ (fun () -> ev elem handler))

  let focus_todo_item id =
    let e = Dom_html.getElementById(Printf.sprintf "todo-%u" id) in
    Js.Opt.case (Dom_html.CoerceTo.input e)
      (fun e -> ()) (fun e -> e##focus)

  (* New task input field *)
  let task_input =
    Html5.(input ~a:[
        a_input_type `Text ;
        a_class ["new-todo"] ;
        a_placeholder "What needs to be done?" ;
        a_autofocus () ;
      ] ())

  let task_input_dom =
    To_dom.of_input task_input

  let set_task_input v =
    task_input_dom##.value := Js.string v

  let focus_task_input () =
    task_input_dom##focus

  let task_entry ((r, f) : rp) =
    bind_event Ev.keypresses task_input_dom (fun evt ->
        Lwt.return @@
        if evt##.keyCode = 13 then (
          Controller.update Add (r, f) ;
          set_task_input ""
        )
      ) ;

    bind_event Ev.inputs task_input_dom (fun _ ->
        Lwt.return @@
        (Controller.update (Update_field task_input_dom##.value) (r, f))) ;

    Html5.(header ~a:[a_class ["header"]] [
        h1 [ txt "todos" ];
        task_input
      ])

  (* One item in the tasks list *)
  let todo_item ((r, f) : rp) (todo:Model.task) =
    let input_check =
      Html5.(input ~a:(
          let l = [
            a_input_type `Checkbox ;
            a_class ["toggle"] ;
            a_onclick (fun _ ->
                Controller.update (Check (todo.id, (not todo.completed))) (r, f) ;
                focus_task_input () ;
                true
              )]
          in if todo.completed then a_checked () :: l else l
        ) ())
    in

    let key_handler evt =
      if evt##.keyCode = 13 then (
        let tgt = Dom_html.CoerceTo.input(Dom.eventTarget evt) in
        Js.Opt.case tgt
          (fun () -> ())
          (fun e -> Controller.update (Update_task (todo.id, e##.value)) (r, f)) ;
        Controller.update
          (Editing_task (todo.id, false)) (r, f) ;
        focus_task_input () ;
        true
      )
      else if evt##.keyCode = 27 then (
        Controller.update (Action.Escape todo.id) (r, f) ;
        focus_task_input () ;
        true
      )
      else true
    in

    let input_edit ((r, f) : rp) =
      Html5.(input ~a:[
          a_input_type `Text ;
          a_class ["edit"] ;
          a_value todo.description ;
          a_id (Printf.sprintf "todo-%u" todo.id) ;
          a_onblur (fun _ ->
              Controller.update (Editing_task (todo.id, false)) (r, f) ;
              focus_task_input () ;
              true
            ) ;
          a_onchange (fun evt ->
              let tgt = Dom_html.CoerceTo.input(Dom.eventTarget evt) in
              Js.Opt.case tgt
                (fun () -> true)
                (fun e -> Controller.update (Update_task (todo.id, e##.value)) (r, f); true)) ;
          a_onkeypress (fun evt -> key_handler evt) ;
          a_onkeydown (fun evt -> key_handler evt) ;
        ] ())
    in

    let css_class l =
      let l = if todo.completed then "completed"::l else l in
      if todo.editing then "editing"::l else l
    in

    Html5.(li ~a:[a_class (css_class [])] [
        div ~a:[a_class ["view"]] [
          input_check;
          label ~a:[a_ondblclick (fun _ ->
              Controller.update (Editing_task (todo.id, true)) (r, f) ;
              focus_todo_item todo.id ;
              true
            )] [txt todo.description];
          button ~a:[a_class ["destroy"]; a_onclick (fun evt ->
              Controller.update (Delete todo.id) (r, f) ;
              focus_task_input () ;
              true
            )] []
        ];
        input_edit (r, f);
      ])

  (* Build the tasks list *)
  let task_list ((r, f) : rp) =
    let css_visibility tasks =
      match tasks with
      | [] -> "visibility: hidden;"
      | _ -> "visibility: visible;"
    in
    let toggle_input_checked tasks =
      List.for_all (fun e -> e.Model.completed) tasks
    in
    let list_of_visible_tasks m =
      let visibility = m.Model.visibility in
      let is_visible todo =
        match visibility with
        | Model.Completed -> todo.Model.completed
        | Active -> not todo.completed
        | All -> true
      in
      List.filter is_visible m.Model.tasks
    in
    let react_tasks = React.S.map (fun m -> m.Model.tasks) r in
    let rl = ReactiveData.RList.from_signal (React.S.map list_of_visible_tasks r) in
    let rl = ReactiveData.RList.map (todo_item (r, f)) rl in
    Html5.(section ~a:[a_class ["main"]; R.Html5.a_style (React.S.map css_visibility react_tasks) ] [
        Html5.input
          ~a:( (R.filter_attrib (a_checked ()) (React.S.map toggle_input_checked react_tasks)) :: [
              a_input_type `Checkbox ;
              a_class ["toggle-all"] ;
              a_onclick (fun _ ->
                  let m = React.S.value r in
                  Controller.update (Check_all (not (toggle_input_checked m.Model.tasks))) (r, f) ;
                  focus_task_input () ;
                  true
                ) ;
            ]) () ;
        label ~a:[a_label_for "toggle-all"] [txt "Mark all as complete"] ;
        R.Html5.ul ~a:[a_class ["todo-list"]] rl
      ])

  let visibility_swap m ((r, f) : rp) acc (uri, visibility)  =
    let actual_visibility = m.Model.visibility in
    let css =
      if visibility = actual_visibility then ["selected"] else []
    in
    Html5.(li ~a:[a_onclick (fun _ ->
        Controller.update (Change_visibility visibility) (r, f) ;
        focus_task_input () ;
        true)] [
        a ~a:[a_href uri; a_class css]
          [txt (Model.string_of_visibility visibility)]
      ]) :: acc

  let controls ((r, f) : rp) =
    let open Html5 in
    let footer_hidden tasks =
      match tasks with
      | [] -> true
      | _ -> false
    in
    let a_button = [a_class ["clear-completed"]; a_onclick (fun evt ->
        Controller.update (Delete_complete) (r, f) ;
        focus_task_input () ;
        true
      )] in
    let button_hidden tasks =
      let tasks_completed, _ = List.partition (fun e -> e.Model.completed) tasks in
      match tasks_completed with
      | [] -> true
      | _ -> false
    in
    let nb_left tasks =
      let _, tasks_left = List.partition (fun e -> e.Model.completed) tasks in
      string_of_int (List.length tasks_left)
    in
    let item_left tasks =
      let _, tasks_left = List.partition (fun e -> e.Model.completed) tasks in
      if (List.length tasks_left = 1) then " item left" else " items left"
    in
    let vswap m =
      List.rev(List.fold_left (visibility_swap m (r, f)) []
                 [("#/", Model.All); ("#/active", Model.Active); ("#/completed", Model.Completed)])
    in
    let react_tasks = React.S.map (fun m -> m.Model.tasks) r in
    let html =
      footer ~a:[a_class ["footer"];
                 (R.filter_attrib (a_hidden ()) (React.S.map footer_hidden react_tasks))] [
        span ~a:[a_class ["todo-count"]] [
          strong ~a:[] [R.Html5.txt (React.S.map nb_left react_tasks)] ;
          R.Html5.txt (React.S.map item_left react_tasks)
        ];
        R.Html5.ul ~a:[a_class ["filters"]]
          (ReactiveData.RList.from_signal (React.S.map vswap r)) ;
        button
          ~a:((R.filter_attrib (a_hidden ()) (React.S.map button_hidden react_tasks)) :: a_button) [
          txt "Clear completed"
        ];
      ]
    in
    html

  let info_footer =
    Html5.(footer ~a:[a_class ["info"]] [
        p [txt "Double-click to edit a todo"] ;
        p [
          txt "Written by " ;
          a ~a:[a_href "https://stephanelegrand.wordpress.com/"] [txt "Stéphane Legrand"]
        ];
        p [
          txt "Various code improvements from " ;
          a ~a:[a_href "https://github.com/Drup"] [txt "Gabriel Radanne"]
        ];
        p [
          txt "Based on " ;
          a ~a:[a_href "https://github.com/evancz"] [txt "Elm implementation by Evan Czaplicki"]
        ];
        p [
          txt "Part of " ;
          a ~a:[a_href "http://todomvc.com"] [txt "TodoMVC"]
        ]
      ])

  (* Build the HTML for the application *)
  let view (r, f) =
    Html5.(
      div ~a:[a_class ["todomvc-wrapper"]] [
        section ~a:[a_class ["todoapp"]] [
          task_entry (r, f) ;
          task_list (r, f) ;
          controls (r, f)
        ];
        info_footer
      ])

end

let main _ =
  let doc = Dom_html.document in
  let parent =
    Js.Opt.get (doc##getElementById (Js.string "todomvc"))
      (fun () -> assert false)
  in
  (* restore the saved state or empty state if not found *)
  let m = Model.from_json @@ Storage.init @@ Model.to_json Model.empty in
  (* set the visibility by looking at the current url *)
  let m =
    match Url.Current.get() with
    | None -> m
    | Some u ->
      let fragment =
        match u with
        | Url.Http h
        | Url.Https h -> h.Url.hu_fragment
        | Url.File f -> f.Url.fu_fragment
      in
      match fragment with
      | "/" -> { m with Model.visibility = Model.All }
      | "/active" -> { m with Model.visibility = Model.Active }
      | "/completed" -> { m with Model.visibility = Model.Completed }
      | _ -> m
  in
  let rp = React.S.create m in
  Dom.appendChild parent (Js_of_ocaml_tyxml.Tyxml_js.To_dom.of_div (View.view rp)) ;
  View.set_task_input m.Model.field ;
  View.focus_task_input () ;
  Lwt.return ()

let _ = Js_of_ocaml_lwt.Lwt_js_events.onload () >>= main
