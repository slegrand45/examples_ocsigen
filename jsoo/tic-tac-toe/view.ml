open Action
open Types
open Tyxml_js

let cell_row (r, f) board row cells_won = 
  let cells = Model.get_cells_row board row in
  let cell_class cell = 
    let won = 
      if (List.mem cell cells_won) then
        ["cellWon"]
      else []
    in
    match cell.state with
    | Played Player_x -> won @ ["cellX"]
    | Played Player_o -> won @ ["cellO"]
    | Empty -> won @ ["cellEmpty"]
  in
  let f acc e = 
    let s = Model.string_of_cell e in
    let cell_class = cell_class e in
    (Html5.(td ~a:[
         a_onclick (fun evt -> (Controller.update (Click_cell e) (r, f)); true) ;
         a_class cell_class
       ] [pcdata s])) :: acc
  in
  let ltd = List.rev(List.fold_left f [] cells) in
  Html5.(tr ltd)

let table_board ((r, f) : rp) =
  let cells m =
    let board = Model.get_game_board m in
    let cells_won = 
      match m with
      | Game_won (b, p) -> Model.cells_game_won b p
      | _ -> []
    in
    [cell_row (r, f) board Top cells_won ;
     cell_row (r, f) board Center cells_won ;
     cell_row (r, f) board Bottom cells_won]
  in
  let rl = Rl.list (React.S.map cells r) in
  Html5.(section ~a:[a_class ["main"]] [
      R.Html5.table ~a:[a_class ["board"]] rl
    ])

let info_header =
  Html5.(header ~a:[a_class ["info"]] [
      p [pcdata "Reload the page (F5) to restart the game"]
    ])

let info_footer =
  Html5.(footer ~a:[a_class ["info"]] [
      p [
        pcdata "Tic-Tac-Toe - Written by " ;
        a ~a:[a_href "https://stephanelegrand.wordpress.com/"] [pcdata "Stéphane Legrand"]
      ] ;
    ])

let view (r, f) =
  Html5.(
    div [
      info_header ;
      section [table_board (r, f)] ;
      info_footer
    ])
