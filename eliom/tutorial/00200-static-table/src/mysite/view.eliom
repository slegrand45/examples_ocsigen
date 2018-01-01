open Eliom_content

type msg =
  | List of I18n.t list
  | Title
  | No_product
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
      | No_product -> [
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

let table_of_products lp =
  let products =
    let f acc e =
      let product_code = Product.get_code e in
      let product_name = _t (List(Product.get_names e)) Config.default_language in
      let product_price = price_to_string Config.default_language (Product.get_prices e) Config.default_iso4217 in
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
  Html.F.(    
    tablex
      ~a:[a_class ["table"; "is-striped"]]
      ~thead:(thead [
        tr [
          th [ pcdata (_t Col_code Config.default_language) ] ;
          th [ pcdata (_t Col_name Config.default_language) ] ;
          th ~a:[a_class ["price"]] [ pcdata (_t Col_price Config.default_language) ] ;
        ]
      ]) [
      tbody products
    ]
  )

let body =
  Html.F.(
    body [
      div ~a:[a_class ["columns"]] [
        div ~a:[a_class ["column is-8 is-offset-2"]] [
          h1 ~a:[a_class ["title"]] [ pcdata (_t Title Config.default_language) ] ;
          div [
            if List.length Model.products = 0 then (
              p [ pcdata (_t No_product Config.default_language)]
            ) else (
              table_of_products Model.products
            )
          ]
        ]
      ]
    ]
  )
