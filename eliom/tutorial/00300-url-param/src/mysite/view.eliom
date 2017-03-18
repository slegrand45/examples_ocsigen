open Eliom_content

type msg =
  | List of I18n.t list
  | Title
  | NoProduct
  | Col_code
  | Col_name
  | Col_price

let price_to_string lang l iso4217 =
  let string_idiom p =
    match Money.Vat.idiom lang p with
    | None -> (
        match Money.Vat.idiom Config.default_language p with
        | None -> assert false
        | Some v -> I18n.to_string v
      )
    | Some v -> I18n.to_string v
  in
  match iso4217 with
  | Money.Iso4217.Iso v ->
    match Money.Vat.filter_one_currency v l with
    | [] -> "price not available"
    | e :: [] -> (
        let open Money.Vat in
        match e with
        | Amount p -> (
            Printf.sprintf "%s %s %s"
              (to_string p) (symbol_currency p) (string_idiom p)
          )
      )
    | _ -> "price not available" (* several prices !!?? *)

let _t msg lang =
  let l =
    I18n.(
      match msg with
      | List v -> v
      | Title -> [
          make Language.En "List of products" ;
          make Language.Fr "Liste des produits" ;
        ]
      | NoProduct -> [
          make Language.En "No product" ;
          make Language.Fr "Aucun produit" ;
        ]
      | Col_code -> [
          make Language.En "Code" ;
          make Language.Fr "Code" ;
        ]
      | Col_name -> [
          make Language.En "Name" ;
          make Language.Fr "Nom" ;
        ]
      | Col_price -> [
          make Language.En "Unit price" ;
          make Language.Fr "Prix à l'unité" ;
        ]
    )
  in
  match (I18n.translate lang l) with
  | None -> "translation not available"
  | Some v -> I18n.to_string v

let select_iso4217 iso4217 =
  let selected v =
    if (Money.Iso4217.iso v) = iso4217 then
      [Html.D.a_selected ()]
    else
      []
  in
  (*
    /!\ Use Html.D instead of Html.F
    Otherwise the event binding with Lwt_js_events.changes doesn't work
  *)
  Html.D.(Raw.select [
    option ~a:(Money.Iso4217.([a_value (to_string usd)] @ (selected usd))) (pcdata Money.Iso4217.(to_string usd)) ;
    option ~a:(Money.Iso4217.([a_value (to_string eur)] @ (selected eur))) (pcdata Money.Iso4217.(to_string eur)) ;
  ])

let table_of_products lp lang iso4217 =
  let products =
    let f acc e =
      let product_code = Product.get_code e in
      let product_name = _t (List(Product.get_names e)) lang in
      let product_price = price_to_string lang (Product.get_prices e) iso4217 in
      let tr =
        Html.F.(
          tr [
            td [ pcdata product_code ] ;
            td [ pcdata product_name ] ;
            td ~a:[a_class ["price"]] [ pcdata product_price ] ;
          ]
        )
      in
      tr :: acc
    in
    List.rev(List.fold_left f [] lp)
  in
  (* create only one select element and use it everywhere *)
  let select_element = select_iso4217 iso4217 in
  let _ = [%client
  (Lwt.async (fun () ->
     Lwt_js_events.changes (Eliom_content.Html.To_dom.of_element ~%select_element)
       (fun evt _ ->
          (* let _ = Lwt_log_js.log "Select changes!" in *)
          let iso4217 =
            let tgt = Dom_html.CoerceTo.select(Dom.eventTarget evt) in
            Js.Opt.case tgt
              (fun () -> assert false)
              (fun e ->
                 let option = e##.options##item e##.selectedIndex in
                 Js.Opt.case option
                   (fun () -> assert false)
                   (fun e ->
                      try
                        Money.Iso4217.(of_string (Js.to_string e##.value))
                      with
                      | _ -> ~%Config.default_iso4217))
          in
          let _ = Eliom_client.change_page ~replace:true ~service:~%Service.main (Some ~%lang, Some iso4217) () in
          Lwt.return ()))
   : unit)
  ] in
  Html.F.(
    tablex
      ~a:[a_class ["table"; "is-striped"]]
      ~thead:(thead [
        tr [
          th [ pcdata (_t Col_code lang) ] ;
          th [ pcdata (_t Col_name lang) ] ;
          th ~a:[a_class ["price"]] [
            pcdata (_t Col_price lang) ;
            select_element ;
          ] ;
        ]
      ]) [
      tbody products
    ]
  )

let links_languages lang iso4217 =
  let l = [(Language.En, "EN"); (Language.Fr, "FR")] in
  let f acc (lang', s) =
    match lang' with
    | v when v = lang ->
      Html.F.(
        span ~a:[a_class ["level-item"]] [pcdata s]) :: acc
    | v ->
      Html.F.(
        span ~a:[a_class ["level-item"]] [a Service.main [pcdata s] (Some v, Some iso4217)])
      :: acc
  in
  List.rev(List.fold_left f [] l)

let navigation lang iso4217 =
  Html.F.(
    nav ~a:[a_class ["level is-mobile"]] [
      div ~a:[a_class ["level-left"]] [
        div ~a:[a_class ["level-item"]] [
          h1 ~a:[a_class ["title"]] [ pcdata (_t Title lang) ]
        ]
      ] ;
      div ~a:[a_class ["level-right"]] (links_languages lang iso4217) ;
    ]
  )

let body lang iso4217 =
  Html.F.(
    body [
      div ~a:[a_class ["container"]] [
        navigation lang iso4217 ;
        div [
          if List.length Model.products = 0 then (
            p [ pcdata (_t NoProduct lang)]
          ) else (
            table_of_products Model.products lang iso4217
          )
        ]
      ]
    ]
  )
