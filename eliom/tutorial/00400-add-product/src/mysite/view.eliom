open Eliom_content

type msg =
  | List of I18n.t list
  | Title_list
  | Back_to_list
  | Title_add
  | Add_product
  | No_product
  | Field_code
  | Field_name
  | Field_price
  | Save
  | Quit

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
      | Title_list -> [
          make Language.En "List of products" ;
          make Language.Fr "Liste des produits" ;
        ]
      | Back_to_list -> [
          make Language.En "Back to list" ;
          make Language.Fr "Retour à la liste" ;
        ]
      | Title_add -> [
          make Language.En "Add a product" ;
          make Language.Fr "Ajouter un produit" ;
        ]
      | Add_product -> [
          make Language.En "Add a product" ;
          make Language.Fr "Ajouter un produit" ;
        ]
      | No_product -> [
          make Language.En "No product" ;
          make Language.Fr "Aucun produit" ;
        ]
      | Field_code -> [
          make Language.En "Code" ;
          make Language.Fr "Code" ;
        ]
      | Field_name -> [
          make Language.En "Name" ;
          make Language.Fr "Nom" ;
        ]
      | Field_price -> [
          make Language.En "Unit price" ;
          make Language.Fr "Prix à l'unité" ;
        ]
      | Save -> [
          make Language.En "Save" ;
          make Language.Fr "Enregistrer" ;
        ]
      | Quit -> [
          make Language.En "Quit" ;
          make Language.Fr "Quitter" ;
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
          th [ pcdata (_t Field_code lang) ] ;
          th [ pcdata (_t Field_name lang) ] ;
          th ~a:[a_class ["price"]] [
            pcdata (_t Field_price lang) ;
            select_element ;
          ] ;
        ]
      ]) [
      tbody products
    ]
  )

let links_languages title lang iso4217 =
  let l = [(Language.En, "EN"); (Language.Fr, "FR")] in
  let service =
    match title with
    | Title_add -> fst Service.add
    | _ -> Service.main
  in
  let f acc (lang', s) =
    match lang' with
    | v when v = lang ->
      Html.F.(
        span ~a:[a_class ["level-item"]] [pcdata s]) :: acc
    | v ->
      Html.F.(
        span ~a:[a_class ["level-item"]] [a service [pcdata s] (Some v, Some iso4217)])
      :: acc
  in
  List.rev(List.fold_left f [] l)

let navigation page_title lang iso4217 =
  let bt =
    match page_title with
    | Title_add ->
        Html.F.(
          a ~a:[a_class ["button"]] ~service:Service.main [pcdata (_t Back_to_list lang)] (Some lang, Some iso4217)
        )
    | _ ->
        Html.F.(
          a ~a:[a_class ["button"]] ~service:(fst Service.add) [pcdata (_t Add_product lang)] (Some lang, Some iso4217)
        )
  in
  Html.F.(
    nav ~a:[a_class ["level is-mobile"]] [
      div ~a:[a_class ["level-left"]] [
        div ~a:[a_class ["level-item"]] [
          bt
        ]
      ] ;
      div ~a:[a_class ["level-center"]] [
        div ~a:[a_class ["level-item"]] [
          h1 ~a:[a_class ["title"]] [ pcdata (_t page_title lang) ]
        ]
      ] ;
      div ~a:[a_class ["level-right"]] (links_languages page_title lang iso4217) ;
    ]
  )

let list lang iso4217 () =
  let products = Model.get_products () in
  Html.F.(
    body [
      div ~a:[a_class ["container"]] [
        navigation Title_list lang iso4217 ;
        div [
          if List.length products = 0 then (
            p [ pcdata (_t No_product lang) ]
          ) else (
            table_of_products products lang iso4217
          )
        ]
      ]
    ]
  )

let add lang iso4217 (product_code, (product_name, product_price)) =
  let () =
    let price =
      match iso4217 with
      | Money.Iso4217.Iso iso ->
          Money.(Vat.Amount(Vat.excl(Currency.of_string product_price iso)))
    in
    let p = Product.(empty
      |> set_code product_code
      |> set_names [ I18n.make lang product_name ]
      |> set_prices [ price ])
    in
    Model.add_product p
  in
  list lang iso4217 ()

let create_form_add lang iso4217 (product_code, (product_name, product_price)) =
  Html.F.([
    div ~a:[a_class ["field"]] [
      label ~a:[a_class ["label"]] [ pcdata (_t Field_code lang) ] ;
      p ~a:[a_class ["control"]] [
        Form.input ~a:[a_class ["input"]]
          ~input_type:`Text ~name:product_code
          Form.string
      ]
    ] ;
    div ~a:[a_class ["field"]] [
      label ~a:[a_class ["label"]] [ pcdata (_t Field_name lang) ] ;
      p ~a:[a_class ["control"]] [
        Form.input ~a:[a_class ["input"]]
          ~input_type:`Text ~name:product_name
          Form.string
      ]
    ] ;
    div ~a:[a_class ["field"]] [
      label ~a:[a_class ["label"]] [ pcdata (_t Field_price lang) ] ;
      p ~a:[a_class ["control"]] [
        Form.input ~a:[a_class ["input"]]
          ~input_type:`Text ~name:product_price
          Form.string
      ]
    ] ;
    div ~a:[a_class ["field"; "is-grouped"]] [
      div ~a:[a_class ["control"; "is-expanded"]] [
        Form.input ~a:[a_class ["input"]]
          ~input_type:`Submit ~value:(_t Save lang)
          Form.string ;
      ] ;
      div ~a:[a_class ["control"; "is-expanded"]] [
        a ~a:[a_class ["button"; "is-fullwidth"]] ~service:Service.main [
          pcdata (_t Quit lang)
        ] (Some lang, Some iso4217)
      ]
    ]
  ])

let form_add lang iso4217 () =
  Html.F.(
    body [
      div ~a:[a_class ["container"]] [
        navigation Title_add lang iso4217 ;
        div [
          (* Use the POST service to manage the form submit *)
          Form.post_form ~service:(snd Service.add) (create_form_add lang iso4217) (Some lang, Some iso4217)
        ]
      ]
    ]
  )
