# Use URL parameters

## What you will learn

  In this tutorial, we will see how to use URL parameters to change the language and the currency of our products list.


## Define service parameters

  We have two URL parameters:

  - `lang`

    `en` for the english translation, `fr` for the french translation.

  - `iso4217`

    `usd` for US dollar, `eur` for Euro.

  Each of these parameters is optional. The default values are defined in `config.eliom`.

  The service is created in `service.eliom`:

```ocaml
  Eliom_service.create
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get(
      Eliom_parameter.(
        (opt(
           user_type
             ~client_to_and_of:([%client { Eliom_parameter.of_string = Language.of_string; Eliom_parameter.to_string = Language.to_string } ])
             ~of_string:Language.of_string
             ~to_string:Language.to_string
             "lang"))
        **
        (opt(
           user_type
             ~client_to_and_of:([%client { Eliom_parameter.of_string = Money.Iso4217.of_string;
                                           Eliom_parameter.to_string = (fun v -> match v with Money.Iso4217.Iso iso -> Money.Iso4217.to_string iso) } ])
             ~of_string:Money.Iso4217.of_string
             ~to_string:(fun v -> match v with Money.Iso4217.Iso iso -> Money.Iso4217.to_string iso)
             "iso4217"))
      )
    ))
    ()

```

  We use 3 functions of `Eliom_parameter` module to define the URL parameters:

  - `opt` to specify that the parameter is optional

  - `**` to define a pair of parameters

  - `user_type` to be able to use our custom types `Language.t` and `Money.Iso4217.iso`. The last argument is the name of the parameter in the URL. The other arguments define the functions used to convert a value to a string and vice versa.


## Display a select element and set an onchanges handler

  We need to display a list of available currencies. And if the user chooses a new currency, we refresh the page to display the right prices.

  In `view.eliom`, we create the select element:

```ocaml
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

```

  Note that we use `Html.D` instead of `Html.F` because we bind the `onchanges` event to this select element:

```ocaml
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

```

  As this binding is obviously only on the browser side, we put the code in a `[%client ... ]` section. Next, we use `Lwt_js_events.changes` to execute a function each time a change event happens on the select element.
  

## Display a link with parameter





## Next step

  In the next tutorial, we will see how to add a new product.