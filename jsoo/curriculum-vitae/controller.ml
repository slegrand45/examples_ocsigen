open Types
open Action

let update a ((r, f) : rp) =
  let (page, cv) = React.S.value r in
  let cv = match a with
    | Update_lang lang ->
      { cv with CV.lang = lang }
    | Portfolio_details _ 
    | Portfolio_summary _ -> cv
  in
  let page = match a with
    | Portfolio_details n ->
      let l = Page.portfolio page in
      let l = List.remove_assoc n l in
      let l = (n, Page.Details) :: l in
      let l = List.stable_sort (fun (i1, _) (i2, _) -> compare i1 i2) l in
      { Page.portfolio = l }
    | Portfolio_summary n ->
      let l = Page.portfolio page in
      let l = List.remove_assoc n l in
      let l = (n, Page.Summary) :: l in
      let l = List.stable_sort (fun (i1, _) (i2, _) -> compare i1 i2) l in
      { Page.portfolio = l }
    | Update_lang _ -> page
  in
  f (page, cv)
