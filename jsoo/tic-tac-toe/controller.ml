open Types

let update a ((r, f) : rp) =
  let m = React.S.value r in
  let m =
    match a with
    | Action.Click_cell cell ->
      match m with
      | Player_x_to_move (board, valid_moves) ->
        if (Model.cell_in_valid_moves_x valid_moves cell) then
          let new_game_board = { cells = Model.update_cell board cell Player_x } in
          let new_valid_moves = Model.valid_moves_for_player new_game_board (fun e -> Player_o_pos e) in
          if (Model.game_won_by_player new_game_board Player_x) then Game_won (new_game_board, Player_x)
          else match new_valid_moves with
            | [] -> Game_tied new_game_board
            | _ -> Player_o_to_move (new_game_board, new_valid_moves)          
        else m
      | Player_o_to_move (board, valid_moves) ->
        if (Model.cell_in_valid_moves_o valid_moves cell) then
          let new_game_board = { cells = Model.update_cell board cell Player_o } in
          let new_valid_moves = Model.valid_moves_for_player new_game_board (fun e -> Player_x_pos e) in
          if (Model.game_won_by_player new_game_board Player_o) then Game_won (new_game_board, Player_o)
          else match new_valid_moves with
            | [] -> Game_tied new_game_board
            | _ -> Player_x_to_move (new_game_board, new_valid_moves)
        else m
      | Game_won _
      | Game_tied _ -> m
  in
  f m