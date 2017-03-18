
open Money

let p1 =
  let price_usd = Vat.excl(Currency.(of_int 19 Iso4217.usd)) in
  let price_eur = Vat.exchange Iso4217.eur price_usd in
  Product.(
    empty
    |> set_id (Id.of_int64 1L)
    |> set_code "WG04"
    |> set_names I18n.(
      [ make Language.En "Waffle gun"; make Language.Fr "Pistolet à gaufre"])
    |> set_prices Vat.([ Amount price_usd; Amount price_eur ])
  )

let p2 =
  let price_eur = Vat.excl(Currency.(of_int 5 Iso4217.eur)) in
  let price_usd = Vat.exchange Iso4217.usd price_eur in
  Product.(
    empty
    |> set_id (Id.of_int64 2L)
    |> set_code "EW-2000"
    |> set_names I18n.(
      [ make Language.En "Electric whisker"; make Language.Fr "Tourniquette"])
    |> set_prices Vat.([ Amount price_usd; Amount price_eur ])
  )

let p3 =
  let price_usd = Vat.excl(Currency.(of_int 599 Iso4217.usd)) in
  let price_eur = Vat.exchange Iso4217.eur price_usd in
  Product.(
    empty
    |> set_id (Id.of_int64 3L)
    |> set_code "PROGLAGLA"
    |> set_names I18n.(
      [ make Language.En "Refrigerator"; make Language.Fr "Frigidaire"])
    |> set_prices Vat.([ Amount price_usd; Amount price_eur ])
  )

let products = [
  p1; p2; p3
]
