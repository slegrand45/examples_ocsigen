let list t =
  let open ReactiveData.RList in
  make_from
    (React.S.value t)
    (React.E.map (fun e -> Set e) (React.S.changes t))