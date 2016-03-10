(* http://ifeanyi.co/posts/client-side-haskell/ *)

open Lwt.Infix

module Model = struct

  type point = {
    x : float ;
    y : float ;
  }

  type player_data = {
    paddle_position : point ;
    score : int ;
  }

  type player = Player_one of player_data
              | Player_two of player_data

  type status = Playing | Not_playing

  type t = {
    ball_position : point ;
    ball_speed : point ;
    player_one : player ;
    player_two : player ;
    status : status ;
  }

  let width = 650.
  let height = 600.
  let margin_paddle = 25.
  let ball_size = 10.
  let paddle_height = 110.
  let paddle_width = 10.
  let step_paddle_move = 11.
  let score_text_color = "#39FF14"
  let menu_text_color = "#39FF14"
  let bgcolor = "black"
  let paddle_color = "#39FF14"
  let ball_color = "#39FF14"

  let create_point x y = { x; y }

  let init_paddle_pos_one =
    create_point margin_paddle ((height /. 2.) -. (paddle_height /. 2.))

  let init_paddle_pos_two =
    create_point (width -. (margin_paddle +. paddle_width))
      ((height /. 2.) -. (paddle_height /. 2.))

  let create_player_data paddle_position score = {
    paddle_position; score
  }

  let reset_player_pos p =
    match p with
    | Player_one p ->
      let paddle_position = init_paddle_pos_one in
      Player_one { p with paddle_position }
    | Player_two p -> 
      let paddle_position = init_paddle_pos_two in
      Player_two { p with paddle_position }

  let inc_score p =
    match p with
    | Player_one p ->
      let score = p.score + 1 in
      Player_one { p with score }
    | Player_two p ->
      let score = p.score + 1 in
      Player_two { p with score }

  let init_ball_speed () =
    let sign_x =
      if Random.bool () then (-. 1.) else 1.
    in
    let sign_y =
      if Random.bool () then (-. 1.) else 1.
    in
    create_point (sign_x *. (ball_size /. 3.)) (sign_y *. (ball_size /. 4.))

  let init_ball_x = width /. 2.

  let init_ball_y = height /. 2.

  let empty = {
    ball_position = create_point init_ball_x init_ball_y ;
    ball_speed = init_ball_speed () ;
    player_one = Player_one (create_player_data init_paddle_pos_one 0) ;
    player_two = Player_two (create_player_data init_paddle_pos_two 0) ;
    status = Not_playing
  }

end

type rs = Model.t React.signal
type rf = ?step:React.step -> Model.t -> unit
type rp = rs * rf

module Action = struct

  type action =
    | Move_ball
    | Start_game
    | Stop_game
    | Move_paddle_up
    | Move_paddle_down

end

module Controller = struct

  let update a ((r, f) : rp) =
    let open Action in
    let open Model in
    let m = React.S.value r in
    let m =
      match a with
      | Move_ball ->
        let pos = m.ball_position in
        let speed = m.ball_speed in
        let (player_one_x, player_one_y) =
          let p = m.player_one in
          match p with
          | Player_one p -> 
            let pos = p.paddle_position in
            (pos.x, pos.y)
          | Player_two _ -> assert false
        in
        let (player_two_x, player_two_y) =
          let p = m.player_two in
          match p with
          | Player_two p -> 
            let pos = p.paddle_position in
            (pos.x, pos.y)
          | Player_one _ -> assert false
        in
        let new_x, new_y, new_speed =
          if ((pos.y +. ball_size >= height)
              || (pos.y <= 0.)) then (
            (* ball hits bottom or up wall *)
            let new_speed = create_point speed.x (speed.y *. (-1.)) in
            let new_x = pos.x +. new_speed.x in
            let new_y = pos.y +. new_speed.y in
            (new_x, new_y, new_speed)
          ) else if (pos.x +. speed.x <= player_one_x +. paddle_width
                     && pos.x +. speed.x > player_one_x
                     && pos.y >= player_one_y -. ball_size
                     && pos.y <= player_one_y +. paddle_height) then (
            (* ball hits player one (left side) paddle *)
            let new_speed = create_point (speed.x *. (-1.)) speed.y in          	
            let new_x = pos.x +. new_speed.x in
            let new_y = pos.y +. new_speed.y in
            (new_x, new_y, new_speed)
          ) else if (pos.x +. ball_size +. speed.x >= player_two_x
                     && pos.x +. ball_size +. speed.x < player_two_x +. paddle_width
                     && pos.y >= player_two_y -. ball_size
                     && pos.y <= player_two_y +. paddle_height) then (
            (* ball hits player two (right side) paddle *)
            let new_speed = create_point (speed.x *. (-1.)) speed.y in          	
            let new_x = pos.x +. new_speed.x in
            let new_y = pos.y +. new_speed.y in
            (new_x, new_y, new_speed)
          ) else (
            (* no hit *)
            let new_x = pos.x +. speed.x in
            let new_y = pos.y +. speed.y in
            (new_x, new_y, speed)
          )
        in
        (* ball out of game *)
        let (new_x, new_y, new_speed, new_player_one, new_player_two) =
          if new_x <= 0. then
            (init_ball_x, init_ball_y, init_ball_speed (),
             reset_player_pos m.player_one,
             reset_player_pos m.player_two |> inc_score)
          else if new_x >= width then
            (init_ball_x, init_ball_y, init_ball_speed (),
             reset_player_pos m.player_one |> inc_score,
             reset_player_pos m.player_two)
          else
            (new_x, new_y, new_speed, m.player_one, m.player_two)
        in
        let new_pos = create_point new_x new_y in
        { m with ball_position = new_pos; ball_speed = new_speed;
                 player_one = new_player_one; player_two = new_player_two }
      | Move_paddle_up -> (
          let speed = m.ball_speed in
          let p =
            if speed.x > 0. then m.player_two else m.player_one
          in
          let calc_new_y y =
            let new_y = y -. step_paddle_move in
            if (new_y <= 0.) then 0. else new_y
          in
          match p with
          | Player_one p -> (
              let pos = p.Model.paddle_position in
              let new_y = calc_new_y pos.y in
              let new_pos = create_point pos.x new_y in
              let new_player = Player_one { p with paddle_position = new_pos } in
              { m with player_one = new_player }
            )
          | Player_two p -> (
              let pos = p.Model.paddle_position in
              let new_y = calc_new_y pos.y in
              let new_pos = create_point pos.x new_y in
              let new_player = Player_two { p with paddle_position = new_pos } in
              { m with player_two = new_player }
            )
        )
      | Move_paddle_down -> (
          let speed = m.ball_speed in
          let p =
            if speed.x > 0. then m.player_two else m.player_one
          in
          let calc_new_y y =
            let new_y = y +. step_paddle_move in
            if (new_y +. paddle_height >= height) then
              height -. paddle_height
            else
              new_y
          in
          match p with
          | Player_one p -> (
              let pos = p.Model.paddle_position in
              let new_y = calc_new_y pos.y in
              let new_pos = create_point pos.x new_y in
              let new_player = Player_one { p with paddle_position = new_pos } in
              { m with player_one = new_player }
            )
          | Player_two p -> (
              let pos = p.Model.paddle_position in
              let new_y = calc_new_y pos.y in
              let new_pos = create_point pos.x new_y in
              let new_player = Player_two { p with paddle_position = new_pos } in
              { m with player_two = new_player }
            )
        )
      | Start_game ->
        { m with status = Playing }
      | Stop_game ->
        empty
    in
    f m

end

module View = struct

  let set_ctx_text ctx =
    ctx##.font := Js.string "32px Arial" ;
    ctx##.textAlign := Js.string "center" ;
    ctx##.textBaseline := Js.string "middle" ;
    ctx

  let menu ctx =
    let text = Js.string "Click here to play" in
    let ctx = set_ctx_text ctx in
    let measure = ctx##measureText text in
    let width = measure##.width in
    let height = 32. +. 8. in (* font size + delta *)
    (* let height = measure##.actualBoundingBoxAscent +. measure##.actualBoundingBoxDescent in *)
    let x = Model.width /. 2. in
    let y = Model.height /. 3. in
    (text, width, height, x, y)

  let handler_start canvas ctx (r, f) =
    let (_, width, height, x, y) = menu ctx in
    canvas##.onclick := Dom_html.handler (fun evt ->
        let rect = canvas##getBoundingClientRect in
        let mouse_x = (float_of_int evt##.clientX) -. rect##.left in
        let mouse_y = (float_of_int evt##.clientY) -. rect##.top in
        (* x and y are the center of text *)
        if mouse_x >= (x -. (width /. 2.)) && mouse_x <= (x +. (width /. 2.))
           && mouse_y >= (y -. (height /. 2.)) && mouse_y <= (y +. (height /. 2.)) then (
          Controller.update Action.Start_game (r, f)
        ) ;
        Js._false
      ) ;
    canvas

  let handler_keys canvas (r, f) =
    let w = Dom_html.window in
    let f evt =
      match evt##.keyCode with
      | 32 ->
        Controller.update Action.Stop_game (r, f) ;
        Js._false
      | 38 ->
        Controller.update Action.Move_paddle_up (r, f) ;
        Js._false
      | 40 ->
        Controller.update Action.Move_paddle_down (r, f) ;
        Js._false
      | _ -> Js._true
    in
    w##.onkeypress := Dom_html.handler f ;
    w##.onkeydown := Dom_html.handler f ;
    canvas

  let create_canvas node (r, f) =
    let doc = Dom_html.document in
    let canvas = Dom_html.createCanvas doc in
    canvas##.width := int_of_float Model.width ;
    canvas##.height := int_of_float Model.height ;
    let ctx = canvas##getContext Dom_html._2d_ in
    ctx##.fillStyle := Js.string Model.bgcolor ;
    ctx##fillRect 0. 0. Model.width Model.height ;
    let canvas = handler_start canvas ctx (r, f) in
    let canvas = handler_keys canvas (r, f) in
    Dom.appendChild node canvas ;
    canvas

  let ball pos ctx =
    let x = pos.Model.x in
    let y = pos.Model.y in
    ctx##.fillStyle := Js.string Model.ball_color ;
    ctx##fillRect x y Model.ball_size Model.ball_size

  let paddle player ctx =
    Model.(
      let (x, y) =
        match player with
        | Player_one p | Player_two p ->
          (p.paddle_position.x, p.paddle_position.y)
      in
      ctx##.fillStyle := Js.string paddle_color ;
      ctx##fillRect x y paddle_width paddle_height
    )

  let play_field ctx =
    ctx##.fillStyle := Js.string Model.bgcolor ;
    ctx##fillRect 0. 0. Model.width Model.height

  let display_score player ctx =
    let score = match player with
      | Model.Player_one p | Model.Player_two p ->
        p.Model.score
    in
    let score = Js.string (string_of_int score) in
    let ctx = set_ctx_text ctx in
    ctx##.fillStyle := Js.string Model.score_text_color ;
    let x = match player with
      | Model.Player_one _ -> Model.width /. 4.
      | Model.Player_two _ -> (Model.width /. 4.) *. 3.
    in
    ctx##fillText score x 40.

  let display_menu ctx =
    let (text, _, _, x, y) = menu ctx in
    let ctx = set_ctx_text ctx in
    ctx##.fillStyle := Js.string Model.menu_text_color ;
    ctx##fillText text x y ;
    ctx##.font := Js.string "18px Arial" ;
    ctx##fillText (Js.string "Use ↑ and ↓ keys to move paddles")
      (Model.width /. 2.) (Model.height /. 1.5) ;
    ctx##fillText (Js.string "Press SPACE key to end the game")
      (Model.width /. 2.) (Model.height /. 1.35)

  let draw canvas m =
    let ctx = canvas##getContext Dom_html._2d_ in
    play_field ctx ;
    paddle m.Model.player_one ctx ;
    paddle m.Model.player_two ctx ;
    ball m.Model.ball_position ctx ;
    display_score m.Model.player_one ctx ;
    display_score m.Model.player_two ctx ;
    match m.Model.status with
    | Model.Playing -> ()
    | Model.Not_playing -> display_menu ctx

end

let start node =
  let m = Model.empty in
  let (r, f) = React.S.create m in
  let c = View.create_canvas node (r, f) in
  let () = View.draw c m in
  let w = Dom_html.window in
  let t = ref 0. in
  let status = ref Model.Not_playing in
  let rec frame t' =
    let m = React.S.value r in
    let () =
      match m.Model.status with
      | Model.Playing ->
        if (t' -. !t >= 0.04) then (
          if !status <> Model.Playing then (
            status := Model.Playing
          ) ;
          View.draw c m ;
          Controller.update Action.Move_ball (r, f);
        )
      | Model.Not_playing ->
        if !status = Model.Playing then (
          View.draw c m ;
          status := Model.Not_playing ;
        )
    in
    t := t' ;
    let _ = w##requestAnimationFrame (Js.wrap_callback frame) in
    ()
  in
  let _ = w##requestAnimationFrame (Js.wrap_callback frame) in
  Lwt.return ()

let main _ =
  let () = Random.self_init () in
  let doc = Dom_html.document in
  Js.Opt.case (doc##getElementById(Js.string "pong"))
    (fun _ -> assert false)
    (fun e -> start e)

let _ = Lwt_js_events.onload () >>= main
