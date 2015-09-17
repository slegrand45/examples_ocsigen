type horiz_position = Left | Middle | Right
type vert_position = Top | Center | Bottom
type diag_position = Left_top_right_bottom | Right_top_left_bottom
type cell_position = horiz_position * vert_position
type player = Player_x | Player_o
type cell_state = Played of player | Empty
type cell = { pos : cell_position; state : cell_state }
type game_board = { cells : cell list }
type player_x_pos = Player_x_pos of cell_position
type player_o_pos = Player_o_pos of cell_position
type valid_moves_for_player_x = player_x_pos list
type valid_moves_for_player_o = player_o_pos list
type game_state = 
    Player_x_to_move of game_board * valid_moves_for_player_x
  | Player_o_to_move of game_board * valid_moves_for_player_o
  | Game_won of game_board * player
  | Game_tied of game_board

type rs = game_state React.signal
type rf = ?step:React.step -> game_state -> unit
type rp = rs * rf
