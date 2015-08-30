open Lwt.Infix

module ReactList = struct

    let list t =
      let open ReactiveData.RList in
      make_from
      (React.S.value t)
      (React.E.map (fun e -> Set e) (React.S.changes t))

end

(** Utility module for local storage. *)
module Storage = struct

  open Js

  let storage =
    Optdef.case (Dom_html.window##localStorage)
      (fun () -> failwith "Storage is not supported by this browser")
      (fun v -> v)

  let key = string "jsoo-todo-state"

  let find () =
    let r = storage##getItem(key) in
    Opt.to_option @@ Opt.map r to_string

  let set v = storage##setItem(key, string v)

  let init default = match find () with
    | None -> set default ; default
    | Some v -> v

end

(** Application data *)
module Model = struct

  type visibility =
    Completed | Active | All
    deriving (Json)

  type task = {
    description : string ;
    (* backup field keep the previous description to restore it when ESC key is pressed *)
    backup : string ;
    completed : bool ;
    editing : bool ;
    id : int ;
  } deriving (Json)

  type t = {
    tasks : task list ;
    field : string ;
    uid : int ;
    visibility : visibility ;
  } deriving (Json) (* to save/restore the state in JSON *)

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
    Json.from_string<t> s

  let to_json m =
    Json.to_string<t> m

end

type rs = Model.t React.signal
type rf = ?step:React.step -> Model.t -> unit
type rp = rs * rf

(** User interface actions *)
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

(** Manage actions, refresh view if needed and save the state in local storage *)
module Controler = struct

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
          if (t.id = id) then { t with editing = false ; description = t.backup }
          else t
        in
        { m with tasks = List.map unedit_task m.tasks }
    in
    Storage.set @@ Model.to_json m ;
    f m

end

(** Build HTML and send user actions *)
module View = struct

  open Action
  open Tyxml_js

  module Ev = Lwt_js_events
  let bind_event ev elem handler =
    let handler evt _ = handler evt in
    Ev.(async @@ (fun () -> ev elem handler))

  (* New task input field *)
  let task_entry ((r, f) : rp) =
    let task_input =
      Html5.(input ~a:[
          a_input_type `Text ;
          a_class ["new-todo"] ;
          a_placeholder "What needs to be done?" ;
          a_autofocus `Autofocus ;
          R.Html5.a_value (React.S.map (fun m -> m.Model.field) r) ;
          a_onkeypress (fun evt -> if evt##keyCode = 13 then (Controler.update Add (r, f)); true) ;
        ] ())
    in
    let task_input_dom = To_dom.of_input task_input in

    bind_event Ev.inputs task_input_dom (fun _ ->
      Lwt.return @@ (Controler.update (Update_field task_input_dom##value) (r, f))) ;

    Html5.(header ~a:[a_class ["header"]] [
        h1 [ pcdata "todos" ];
        task_input
      ])

  (** One item in the tasks list *)
  let todo_item ((r, f) : rp) acc (todo:Model.task) =
    let input_check =
      Html5.(input ~a:(
          let l = [
            a_input_type `Checkbox ;
            a_class ["toggle"] ;
            a_onclick (fun _ ->
              (Controler.update (Check (todo.id, (not todo.completed))) (r, f)); true
            )]
          in if todo.completed then a_checked `Checked :: l else l
        ) ())
    in

    let key_handler evt =
      if evt##keyCode = 13 then (
        let tgt = Dom_html.CoerceTo.input(Dom.eventTarget evt) in
        Js.Opt.case tgt (fun () -> ()) (fun e -> Controler.update (Update_task (todo.id, e##value)) (r, f)) ;
        Controler.update (Editing_task (todo.id, false)) (r, f) ;
        true
      )
      else if evt##keyCode = 27 then (Controler.update (Action.Escape todo.id) (r, f); true)
      else true
    in

    let input_edit ((r, f) : rp) =
      Html5.(input ~a:[
          a_input_type `Text ;
          a_class ["edit"] ;
          a_value todo.description ;
          a_id (Printf.sprintf "todo-%u" todo.id) ;
          a_onblur (fun _ ->
            (Controler.update (Editing_task (todo.Model.id, false)) (r, f)); true ) ;
          a_onchange (fun evt ->
            let tgt = Dom_html.CoerceTo.input(Dom.eventTarget evt) in
            Js.Opt.case tgt (fun () -> true) (fun e -> Controler.update (Update_task (todo.id, e##value)) (r, f); true)) ;
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
        label ~a:[a_ondblclick (
            fun evt -> (Controler.update (Editing_task (todo.id, true)) (r, f)); true;
          )] [pcdata todo.Model.description];
        button ~a:[a_class ["destroy"]; a_onclick (
            fun evt -> (Controler.update (Delete todo.Model.id) (r, f)); true;
          )] []
      ];
      input_edit (r, f);
    ]) :: acc

  (** Build the tasks list *)
  let task_list ((r, f) : rp) =
    let css_visibility m =
      let tasks = m.Model.tasks in
      match tasks with
      | [] -> "visibility: hidden;"
      | _ -> "visibility: visible;"
    in
    let toggle_input_checked m =
      let tasks = m.Model.tasks in
      List.for_all (fun e -> e.Model.completed) tasks
    in
    let visible_tasks m =
      let visibility = m.Model.visibility in
      let is_visible todo =
        match visibility with
        | Model.Completed -> todo.Model.completed
        | Active -> not todo.completed
        | All -> true
      in
      let tasks = List.filter is_visible m.Model.tasks in
      List.rev(List.fold_left (todo_item (r, f)) [] tasks)
    in
    let rl = ReactList.list (React.S.map visible_tasks r) in
    Html5.(section ~a:[a_class ["main"]; R.Html5.a_style (React.S.map css_visibility r) ] [
      Html5.input ~a:( (R.filter_attrib (a_checked `Checked) (React.S.map toggle_input_checked r)) :: [
          a_input_type `Checkbox ;
          a_class ["toggle-all"] ;
          a_onclick (fun _ ->
            Controler.update (Check_all (not (toggle_input_checked (React.S.value r)))) (r, f) ; true) ;
        ]) () ;
      label ~a:[a_for "toggle-all"] [pcdata "Mark all as complete"] ;
      R.Html5.ul ~a:[a_class ["todo-list"]] rl
    ])

  let visibility_swap m ((r, f) : rp) acc (uri, visibility)  =
    let actual_visibility = m.Model.visibility in
    let css =
      if visibility = actual_visibility then ["selected"] else []
    in
    Html5.(li ~a:[a_onclick (fun _ -> Controler.update (Change_visibility visibility) (r, f); true)] [
        a ~a:[a_href uri; a_class css]
          [pcdata (Model.string_of_visibility visibility)]
      ]) :: acc

  let controls ((r, f) : rp) =
    let open Html5 in
    let footer_hidden m =
      let tasks = m.Model.tasks in
      match tasks with
      | [] -> true
      | _ -> false
    in
    let a_button = [a_class ["clear-completed"]; a_onclick (
      fun evt -> (Controler.update (Delete_complete) (r, f)); true;
    )] in
    let button_hidden m =
      let tasks = m.Model.tasks in
      let tasks_completed, _ = List.partition (fun e -> e.Model.completed) tasks in
      match tasks_completed with
      | [] -> true
      | _ -> false
    in
    let nb_left m =
      let tasks = m.Model.tasks in
      let _, tasks_left = List.partition (fun e -> e.Model.completed) tasks in
      string_of_int (List.length tasks_left)
    in
    let item_left m =
      let tasks = m.Model.tasks in
      let _, tasks_left = List.partition (fun e -> e.Model.completed) tasks in
      if (List.length tasks_left = 1) then " item left" else " items left"
    in
    let vswap m =
      List.rev(List.fold_left (visibility_swap m (r, f)) []
        [("#/", Model.All); ("#/active", Model.Active); ("#/completed", Model.Completed)])
    in
    let html =
      footer ~a:[a_class ["footer"]; (R.filter_attrib (a_hidden `Hidden) (React.S.map footer_hidden r))] [
        span ~a:[a_class ["todo-count"]] [
          strong ~a:[] [R.Html5.pcdata (React.S.map nb_left r)] ;
          R.Html5.pcdata (React.S.map item_left r)
        ];
        R.Html5.ul ~a:[a_class ["filters"]]
          (ReactList.list (React.S.map vswap r)) ;
        button ~a:((R.filter_attrib (a_hidden `Hidden) (React.S.map button_hidden r)) :: a_button) [
          pcdata "Clear completed"
        ];
      ]
    in
    html

  let info_footer =
    Html5.(footer ~a:[a_class ["info"]] [
        p [pcdata "Double-click to edit a todo"] ;
        p [
          pcdata "Written by " ;
          a ~a:[a_href "https://stephanelegrand.wordpress.com/"] [pcdata "Stéphane Legrand"]
        ];
        p [
          pcdata "Various code improvements from " ;
          a ~a:[a_href "https://github.com/Drup"] [pcdata "Gabriel Radanne"]
        ];
        p [
          pcdata "Based on " ;
          a ~a:[a_href "https://github.com/evancz"] [pcdata "Elm implementation by Evan Czaplicki"]
        ];
        p [
          pcdata "Part of " ;
          a ~a:[a_href "http://todomvc.com"] [pcdata "TodoMVC"]
        ]
      ])

  (** Build the HTML for the application *)
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
    Js.Opt.get (doc##getElementById(Js.string "todomvc"))
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
        | Url.Https h -> h.hu_fragment
        | Url.File f -> f.fu_fragment
      in
      match fragment with
      | "/" -> { m with Model.visibility = Model.All }
      | "/active" -> { m with Model.visibility = Model.Active }
      | "/completed" -> { m with Model.visibility = Model.Completed }
      | _ -> m
  in
  let rp = React.S.create m in
  Dom.appendChild parent (Tyxml_js.To_dom.of_div (View.view rp)) ;
  Lwt.return ()

let _ = Lwt_js_events.onload () >>= main
