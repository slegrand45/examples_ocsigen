open Types
open Tyxml_js

let part_header (r, f) =
  Html5.(
    header ~a:[a_class ["mdl-layout__header"]] [
        div ~a:[a_class ["mdl-layout__header-row"]] [          
          div ~a:[a_class ["mdl-layout-spacer"]] [] ;
          span ~a:[a_class ["mdl-layout-title"]] [
            a ~a:[
                a_href "#" ;
                a_onclick (fun _ -> (Controller.update (Action.Update_lang I18n.En) (r, f)); true)
              ] [ txt "En" ] ;
            txt " | " ;
            a ~a:[
                a_href "#" ;
                a_onclick (fun _ -> (Controller.update (Action.Update_lang I18n.Fr) (r, f)); true)
              ] [ txt "Fr" ] ;
          ] ;
        ]
      ])

let part_contact (r, _) =
  let rl_title = React.S.map (fun (_, cv) -> I18n.translate (CV.lang cv) (I18n.get_msg I18n.Contact_title Model.msg)) r in
  let rl_email = React.S.map (fun (_, cv) -> let id = CV.id cv in (ID.email id)) r in
  let part_without_href icon (cv, v) =
    Html5.(
      let v = I18n.translate (CV.lang cv) v in
      if v <> "" then
        p [ i ~a:[a_class ["material-icons"; "red-text"]] [ txt icon] ;
            txt v ; br () ]
      else
        p [ txt "" ]
    )
  in
  let part_with_href icon prefix v =
    Html5.(
      if v <> "" then
        p [ i ~a:[a_class ["material-icons"; "red-text"]] [ txt icon] ;
            a ~a:[a_href (prefix ^ v)] [ txt v ] ; br () ]
      else
        p [ txt "" ]
    )
  in
  let rl_address = ReactiveData.RList.from_signal (React.S.map (fun (_, cv) -> let id = CV.id cv in [(cv, ID.address id)]) r) in
  let rl_address = ReactiveData.RList.map (part_without_href "place") rl_address in
  let rl_phone = ReactiveData.RList.from_signal (React.S.map (fun (_, cv) -> let id = CV.id cv in [(cv, ID.phone id)]) r) in
  let rl_phone = ReactiveData.RList.map (part_without_href "smartphone") rl_phone in
  let rl_github = ReactiveData.RList.from_signal (React.S.map (fun (_, cv) -> let id = CV.id cv in [ID.github id]) r) in
  let rl_github = ReactiveData.RList.map (part_with_href "link" "https://") rl_github in
  let rl_web = ReactiveData.RList.from_signal (React.S.map (fun (_, cv) -> let id = CV.id cv in [ID.web id]) r) in
  let rl_web = ReactiveData.RList.map (part_with_href "link" "https://") rl_web in
  Html5.(
    div ~a:[a_class ["block"]] [
      h5 [
        i ~a:[a_class ["material-icons"]] [ txt "message"] ;
        R.Html5.txt rl_title ;
      ] ;
      R.Html5.div rl_address ;
      R.Html5.div rl_phone ;
      p [
        i ~a:[a_class ["material-icons"; "red-text"]] [ txt "email"] ;
        a ~a:[R.Html5.a_href (React.S.map (fun email -> "mailto:" ^ email) rl_email)] [
          R.Html5.txt rl_email
        ] ;
        br () ;
      ] ;
      R.Html5.div rl_github ;
      R.Html5.div rl_web ;
    ] ;
  )

let one_skill (cv, s) =
  let width = Printf.sprintf "width: %d%%;" s.Skill.percent in
  Html5.(
    div [
      h6 [ txt (I18n.translate (CV.lang cv) s.Skill.title) ] ;
      div ~a:[a_class ["progress"]] [
        div ~a:[a_class ["progress-bar"]; a_style width] []
      ] ;
      br () ;
    ]
  )

let part_skill (r, _) =
  let rl_title = React.S.map (fun (_, cv) -> I18n.translate (CV.lang cv) (I18n.get_msg I18n.Skill_title Model.msg)) r in
  let rl = ReactiveData.RList.from_signal (React.S.map (fun (_, cv) -> List.map (fun e -> cv, e) (CV.skill cv)) r) in
  let rl = ReactiveData.RList.map one_skill rl in
  Html5.(
    div ~a:[a_class ["block"]] [
      h5 [
        i ~a:[a_class ["material-icons"]] [ txt "stars"] ;
        R.Html5.txt rl_title ;
      ] ;
      R.Html5.div rl
    ]
  )

let one_language (cv, l) =
  Html5.(
    div [
      h6 [ txt (I18n.translate (CV.lang cv) l.Language.title) ] ;
      p [ txt (I18n.translate (CV.lang cv) l.Language.description) ] ;
      br () ;
    ]
  )

let part_language (r, _) =
  let rl_title = React.S.map (fun (_, cv) -> I18n.translate (CV.lang cv) (I18n.get_msg I18n.Language_title Model.msg)) r in
  let rl = ReactiveData.RList.from_signal (React.S.map (fun (_, cv) -> List.map (fun e -> cv, e) (CV.language cv)) r) in
  let rl = ReactiveData.RList.map one_language rl in
  Html5.(
    div ~a:[a_class ["block"]] [
      h5 [
        i ~a:[a_class ["material-icons"]] [ txt "language"] ;
        R.Html5.txt rl_title ;
      ] ;
      R.Html5.div rl
    ]
  )

let one_work (cv, w) =
  let f e =
    match e with
    | None -> ""
    | Some v -> I18n.translate (CV.lang cv) v
  in
  let company = f w.Experience.company in
  let location = f w.Experience.location in
  let s_company_location =
    match company, location with
    | "", "" -> ""
    | v, "" | "", v -> v
    | v1, v2 -> v1 ^ " - " ^ v2
  in
  let html_company_location =
    match s_company_location with
    | "" -> []
    | _ -> Html5.([
        i ~a:[a_class ["material-icons"; "red-text"]] [ txt "place"] ;
        txt s_company_location ;
      ])
  in
  let s_date = Date.translate_start_end (CV.lang cv) 
    w.Experience.date_start w.Experience.date_end
  in
  let html_date =
    match s_date with
    | "" -> []
    | _ -> Html5.([
        i ~a:[a_class ["material-icons"; "red-text"]] [ txt "date_range"] ;
        txt s_date ;
      ])
  in
  Html5.(
    div ~a:[a_class ["block"]] [
      h5 [ txt (I18n.translate (CV.lang cv) w.Experience.title) ] ;
      p (html_company_location @ html_date) ;
      p [
        txt (I18n.translate (CV.lang cv) w.Experience.description)
      ]
    ]
  )

let part_work (r, _) =
  let rl_title = React.S.map (fun (_, cv) -> I18n.translate (CV.lang cv) (I18n.get_msg I18n.Work_title Model.msg)) r in
  let rl = ReactiveData.RList.from_signal (React.S.map (fun (_, cv) -> List.map (fun e -> cv, e) (CV.experience cv)) r) in
  let rl = ReactiveData.RList.map one_work rl in
  Html5.([
    h3 [
      i ~a:[a_class ["material-icons"]] [ txt "group" ] ;
        R.Html5.txt rl_title ;
    ] ;
    R.Html5.div rl
  ])

let one_education (cv, e) =
  let f e =
    match e with
    | None -> ""
    | Some v -> I18n.translate (CV.lang cv) v
  in
  let s_school = f e.Education.school in
  let html_school =
    match s_school with
    | "" -> []
    | _ -> Html5.([
        i ~a:[a_class ["material-icons"; "red-text"]] [ txt "place"] ;
        txt s_school ;
      ])
  in
  let s_date = Date.translate_start_end (CV.lang cv) 
    e.Education.date_start e.Education.date_end
  in
  let html_date =
    match s_date with
    | "" -> []
    | _ -> Html5.([
        i ~a:[a_class ["material-icons"; "red-text"]] [ txt "date_range"] ;
        txt s_date ;
      ])
  in
  Html5.(
    div ~a:[a_class ["block"]] [
      h5 [ txt (I18n.translate (CV.lang cv) e.Education.title) ] ;
      p (html_school @ html_date) ;
      p [
        txt (I18n.translate (CV.lang cv) e.Education.description)      
      ]
    ]
  )

let part_education (r, _) =
  let rl_title = React.S.map (fun (_, cv) ->
    I18n.translate (CV.lang cv) (I18n.get_msg I18n.Education_title Model.msg)) r
  in
  let rl f =
    let l = ReactiveData.RList.from_signal (React.S.map (fun (_, cv) ->
      List.map (fun e -> cv, e) (f (CV.education cv))) r)
    in
    ReactiveData.RList.map one_education l
  in
  Html5.([
    h3 [
      i ~a:[a_class ["material-icons"]] [ txt "school" ] ;
        R.Html5.txt rl_title ;
    ] ;
    R.Html5.div (rl Education.diploma) ;
  ])

let one_portfolio_details cv n info (r, f) =
  Html5.(
    div ~a:[a_class ["mdl-cell"; "mdl-cell--4-col"; "block"]] [
      div ~a:[a_class ["mdl-card"; "mdl-shadow--2dp"]] [
        div ~a:[a_class ["mdl-card__actions"; "mdl-card--border"]] [
          div ~a:[a_class ["mdl-layout-spacer"]] [] ;
          i ~a:[a_class ["material-icons"] ;
            a_onclick (fun _ -> (Controller.update (Action.Portfolio_summary n) (r, f)); true)]
            [ txt "close" ]
        ] ;
        div ~a:[a_class ["mdl-card__supporting-text"]] [
          txt (I18n.translate (CV.lang cv) (info.Portfolio.description))
        ] ;        
      ]
    ]
  )

let one_portfolio_summary cv n info (r, f) =
  Html5.(
    div ~a:[a_class ["mdl-cell"; "mdl-cell--4-col"; "block"]] [
      div ~a:[a_class ["mdl-card"; "mdl-shadow--2dp"]] [
        div ~a:[a_class ["mdl-card__media"]] [
          img ~a:[a_class ["portfolio-img"]]
                    ~src:(info.Portfolio.image)
                    ~alt:"Portfolio image" ()
        ] ;
        div ~a:[a_class ["mdl-card__actions"; "mdl-card--border"]] [
          txt (I18n.translate (CV.lang cv) (info.Portfolio.title)) ;
          div ~a:[a_class ["mdl-layout-spacer"]] [] ;
          i ~a:[a_class ["material-icons"] ;
            a_onclick (fun _ -> (Controller.update (Action.Portfolio_details n) (r, f)); true)]
            [ txt "more_vert" ]
        ] ;
      ]
    ]
  )

let part_portfolio (r, f) =
  let rl_title = React.S.map (fun (_, cv) ->
    I18n.translate (CV.lang cv) (I18n.get_msg I18n.Portfolio_title Model.msg)) r
  in
  let rlp = ReactiveData.RList.from_signal (
    React.S.map (fun (page, cv) ->
      let portfolio = CV.portfolio cv in
      let l = Page.portfolio page in
      let f' (i, p) =
        let info = List.nth portfolio i in
        match p with
        | Page.Summary -> one_portfolio_summary cv i info (r, f)
        | Page.Details -> one_portfolio_details cv i info (r, f)
      in
      List.map f' l
    ) r
  ) in
  Html5.([
    h3 [
      i ~a:[a_class ["material-icons"]] [ txt "apps" ] ;
        R.Html5.txt rl_title ;
    ] ;
    R.Html5.div ~a:[a_class ["mdl-grid"; "portfolio"]] rlp
  ])

let part_footer () =
  Html5.(
    footer ~a:[a_class ["mdl-mini-footer"]] [
      div ~a:[a_class ["mdl-mini-footer__left-section"]] [
        div ~a:[a_class ["mdl-logo"]] [
          txt "Credits: " ;
          a ~a:[a_href "http://articles.novoresume.com/luke-who-is-searching-for-a-job/"]
            [ txt "Novorésumé - Darth Vader Résumé" ] ;
          txt ", " ;
          a ~a:[a_href "http://demo.themesafari.net/materialize-responsive-resume/"]
            [ txt "Materialize responsive résumé template" ] ;
          txt ", " ;
          a ~a:[a_href "http://media.photobucket.com/user/bdpopeye/media/popeyes%20pix/DarthVader1-1.jpg.html"]
            [ txt "Darth Vader photo" ] ;
          txt ", " ;
          a ~a:[a_href "http://www.freedigitalphotos.net"]
            [ txt "Portfolio images courtesy of Apolonia, stockimages and zole4 at FreeDigitalPhotos.net" ] ;
        ]
      ] ;
      div ~a:[a_class ["mdl-mini-footer__right-section"]] [
        div ~a:[a_class ["mdl-logo"]] []
      ] ;
    ]
  )

let view (r, f) =
  let rl_name = React.S.map (fun (_, cv) ->
    let id = CV.id cv in
    (I18n.translate (CV.lang cv) (ID.firstname id))
    ^ " " ^ (I18n.translate (CV.lang cv) (ID.lastname id))) r
  in
  let rl_title = React.S.map (fun (_, cv) -> I18n.translate (CV.lang cv) (CV.title cv)) r in
  let rl_description = React.S.map (fun (_, cv) -> I18n.translate (CV.lang cv) (CV.description cv)) r in
  Html5.(
    div ~a:[a_class ["mdl-layout"; "mdl-js-layout"; "mdl-layout--fixed-header"]] [
      part_header (r, f) ;
      div ~a:[a_class ["container"]] [
        div ~a:[a_class ["content"]] [
          div (* main *) ~a:[a_class ["mdl-layout__content"]] [
            div ~a:[a_class ["page-content"]] [
              div ~a:[a_class ["mdl-grid"]] [
                div ~a:[a_class ["mdl-cell"; "mdl-cell--3-col"; "left-side"]] [
                  img ~a:[a_class ["circle"; "user-img"; "responsive-img"]]
                    ~src:"img/darth-vader.jpg"
                    ~alt:"Selfie" () ;
                  div ~a:[a_class ["block"]] [
                    h5 ~a:[a_class ["center"; "red-text"]] [ R.Html5.txt rl_name ] ;
                    p ~a:[a_class ["light"]] [ R.Html5.txt rl_title ] ;
                  ] ;
                  hr ();
                  div ~a:[a_class ["block"; "center"]] [
                    h5 [ R.Html5.txt rl_description ] ;
                  ] ;
                  part_contact (r, f) ;
                  part_skill (r, f) ;
                  part_language (r, f) ;
                ] ;
                div ~a:[a_class ["mdl-cell"; "mdl-cell--9-col"; "right-side"]] (
                  (part_work (r, f)) @ (part_education (r, f)) @ (part_portfolio (r, f))
                )
              ]
            ]
          ]
        ]
      ] ;
      part_footer () ;
    ])
