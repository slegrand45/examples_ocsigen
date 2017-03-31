# Add a new product

## What you will learn

  In this tutorial, we will see how to use a basic form in order to add a new product.


## Define the services

  We need to define two new services in `service.eliom`:

  - One `GET` service to display the form.

  - One `POST` service to add the product after a form submit.

  Each of those services have the same access path `/product/add`. The POST service defines three parameters: the product code, the product name and the product price.

```ocaml

let add =
  let path = Eliom_service.Path ["product"; "add"] in
  (Eliom_service.create ~path
    ~meth:(Eliom_service.Get lang_and_iso4217_parameters)
    (),
  Eliom_service.create ~path
    ~meth:(Eliom_service.Post (lang_and_iso4217_parameters,
      Eliom_parameter.(
        (string "code") ** (string "name") ** (string "price"))))
    ())

```


## Register the handlers

  Then we have to register the new services in `mysite.eliom`:

```ocaml
Mysite_app.register
    ~service:(fst Service.add) (* GET to display the form *)
    ~error_handler:(error_handler View.form_add ())
    (register View.form_add) ;
  Mysite_app.register
    ~service:(snd Service.add) (* POST to add the product *)
    ~error_handler:(error_handler View.add ("", ("", "")))
    (register View.add) ;
```


## Form views

  We define a simple form in `view.eliom` with three input fields, a button to submit the form and a button to go back to the products list:
  
```ocaml
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

```

  When the user submits this form, the `POST` service is used:

```ocaml
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
```

  And after adding the product, we display the new products list:

```ocaml
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
```


## Products store

  For this tutorial, we simply store the products in a non persistent session variable initialized in `model.eliom`:

```ocaml
let products = Eliom_reference.Volatile.eref
  ~scope:Eliom_common.default_session_scope
  [ p1; p2; p3 ]
```

  If you restart the server, the variable content is reset.


## Next step

  For now, the form is really raw. For instance, there is no field validation and you can't set several prices in different currencies. In the next tutorial, we will see how to add these features.
