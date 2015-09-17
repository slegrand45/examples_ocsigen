open Types

let valid_moves_for_player board player = 
  let f e = match e.state with
    | Empty -> true
    | _ -> false
  in
  board.cells 
  |> List.filter f
  |> List.map (fun e -> player e.pos)

let empty_board = 
  let f_horizontal acc horizontal = 
    let f_vertical acc vertical = 
      (horizontal, vertical) :: acc
    in
    let row = List.rev(List.fold_left f_vertical [] [Top; Center; Bottom]) in
    row @ acc
  in
  let l = List.rev(List.fold_left f_horizontal [] [Left; Middle; Right]) in
  { cells = l |> List.map (fun e -> { pos = e; state = Empty }) }

let empty_game = 
  Player_x_to_move (empty_board, 
                    valid_moves_for_player empty_board (fun e -> Player_x_pos e))

let get_game_board game = 
  match game with
  | Player_x_to_move (board, _)
  | Player_o_to_move (board, _)
  | Game_won (board, _)
  | Game_tied board -> board

let get_cells_row board row =
  let f e = match e.pos with
    | (_, vertical) when row = vertical -> true
    | _ -> false
  in
  board.cells |> List.filter f

let string_of_cell cell = 
  match cell.state with
  | Played Player_x -> "✖"
  | Played Player_o -> "⃝"
  | Empty -> " "

let update_cell board cell player = 
  let f e = 
    if e = cell then { e with state = Played player }
    else e
  in
  board.cells |> List.map f

let cell_in_valid_moves_x moves cell = 
  let f e = 
    match e with
    | Player_x_pos pos -> cell.pos = pos
  in
  List.exists f moves

let cell_in_valid_moves_o moves cell = 
  let f e = 
    match e with
    | Player_o_pos pos -> cell.pos = pos
  in
  List.exists f moves

let cells_in_row board row = 
  let f e = 
    let (_, vertical) = e.pos in
    if vertical = row then
      true
    else false
  in
  board.cells |> List.filter f

let cells_in_col board col = 
  let f e = 
    let (horizontal, _) = e.pos in
    if horizontal = col then
      true
    else false
  in
  board.cells |> List.filter f

let cells_in_diag board diag = 
  let l = 
    match diag with
    | Left_top_right_bottom -> [(Left, Top); (Middle, Center); (Right, Bottom)]
    | Right_top_left_bottom -> [(Right, Top); (Middle, Center); (Left, Bottom)]
  in
  let f e =
    if (List.mem e.pos l) then
      true
    else false
  in
  board.cells |> List.filter f

let cells_played_by cells player = 
  let f e = 
    match e.state with
    | Played p when p = player -> true
    | _ -> false
  in
  cells |> List.filter f

let check_won board player = 
  let l = [
    cells_in_row board Top; cells_in_row board Center; cells_in_row board Bottom;
    cells_in_col board Left; cells_in_col board Middle; cells_in_col board Right;
    cells_in_diag board Left_top_right_bottom; cells_in_diag board Right_top_left_bottom;
  ] in
  try
    List.find (fun e -> cells_played_by e player = e) l
  with
  | Not_found -> []

let game_won_by_player board player = 
  match (check_won board player) with
  | [] -> false
  | _ -> true

let cells_game_won board player = 
  check_won board player
