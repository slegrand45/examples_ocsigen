# Display a static HTML table

## What you will learn

  In this tutorial, we will see how to build a static HTML table in order to display a list of products.

## Files structure

  This structure is not mandatory. Eliom doesn't require any specific structure so you are free to organize your code as you want.

  - `product.*`

    These files define a product record. Note that the `.eliomi` file defines the interface (this is the counterpart of the `.mli` file with OCaml).

    Each product has an identifier, a code, a list of names and a list of prices. The names are localized so they can be translated in several languages. The prices are localized too so they can be displayed in several currencies.

  - `i18n.*`, `id.*`, `money.*`, `language.*`

    Helper files for the product fields.

  - `model.*`

    Contains the list of products. For now, this list is static.

  - `view.*`

    Functions to build the HTML for the web page.

  - `mysite.eliom`

    The default main file for the application.

## Add the style sheets

We use the [Bulma](http://bulma.io/) CSS framework. Pure CSS frameworks like this one are easier to integrate with an Eliom application. Indeed, Eliom can be used to dynamically modify some parts of the web page on the client side. And there is a risk of bad interferences with other CSS frameworks which include some Javascript code.

In `mysite.eliom`, we create an external CSS link to download the Bulma style sheet:

```ocaml
  let css_bulma =
    Eliom_content.Html.F.(
      css_link
        ~uri:(
          make_uri
            ~service:(Eliom_service.static_dir ())
            ~https:true ~hostname:"cdnjs.cloudflare.com"
            ["ajax"; "libs"; "bulma"; "0.3.1"; "css"; "bulma.min.css"]
        ) ()
    )
```

And to download our local CSS file, we create a local CSS link:

```ocaml
  let css_mysite =
    Eliom_content.Html.F.(
      css_link
        ~uri:(
          make_uri
            ~service:(Eliom_service.static_dir ())
            ~absolute:true
            ["css";"mysite.css"]
        ) ()
    )
```

Then we include these links in the head part of the main page thanks to the `other_head` argument:

```ocaml
  Mysite_app.register
    ~service:main_service
    (fun () () ->
       Lwt.return
         (Eliom_tools.F.html
            ~title:"mysite"
            ~other_head:[css_bulma; css_mysite]
            View.body))
```

## Add packages

As we need the `Num` package in `money.*` code, both on the server side and on the client side, we have to add this package in `Makefile.options`:

```
  SERVER_PACKAGES := num lwt.ppx js_of_ocaml.deriving.ppx
  CLIENT_PACKAGES := num lwt.ppx js_of_ocaml.ppx js_of_ocaml.deriving.ppx
```

We also need to include the missing primitives of `Num` for js_of_ocaml with the `+nat.js` option in `Makefile`:

```
  JS_OF_ELIOM := js_of_eliom -ppx -jsopt +nat.js
```

## How to build the HTML

All the HTML for the page is built in `view.eliom` with functions from `Eliom_content.​Html.F`. Under the hood, this module uses [TyXML](http://ocsigen.org/tyxml/) which is, like Eliom, a part of the [Ocsigen project](http://ocsigen.org/). `TyXML` stands for `Typed XML` and is a library for building statically correct HTML5 and SVG documents. Indeed, thanks to the strong typing of OCaml language, the library is able to forbid invalid HTML5 or SVG code at compile time.

As an example, to build a `tr` in a table, we use this code:

```ocaml
  tr [
    td [ pcdata product_code ] ;
    td [ pcdata product_name ] ;
    td ~a:[a_class ["price"]] [ pcdata product_price ] ;
  ]
```

`tr`, `td`, `pcdata` and `a_class` are functions coming from `TyXML`. The optional argument `~a` can be used to add attributes to the HTML entity (a class name for instance). The `pcdata` function is used to add plain text.

Obviously, `TyXML` needs a multitude of functions to be able to build all the HTML5 entities and attributes. In most of the cases, the function name is the same than the HTML5 entity or argument. You can consult [this page](http://ocsigen.org/tyxml/dev/api/index_values) to have a complete list and find the right function.

## Test the application

  As usual, run the Eliom server in test mode with one of these commands:

```
  $ make test.byte
```

  or

```
  $ make test.opt
```

  Then go to [http://localhost:8080/](http://localhost:8080/). You should see the products list.


## Next step

  In the [next tutorial](../00300-url-param/), we will see how to use a parameter in the URL to set the language and how to add an input select to choose the currency.