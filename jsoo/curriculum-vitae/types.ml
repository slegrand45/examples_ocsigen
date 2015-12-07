module I18n = struct
  type lang = En | Fr

  type t = (lang * string)

  type translation = t list

  type msg = 
    Contact_title
    | Skill_title
    | Language_title
    | Work_title
    | Education_title
    | Portfolio_title

  let make ~lang ~s =
    (lang, s)

  let msg ~id ~l =
    (id, l)

  let translate lang l =
    try
      List.assoc lang l
    with
    | Not_found -> ""

  let get_msg id l =
    List.assoc id l
end

module Calendar = struct
  type t = {
    day : int option ;
    month : int option ;
    year : int ;
  }

  let make ~day ~month ~year =
    { day; month; year }

  let translate lang cal =
    match cal.day, cal.month with
    | None, None -> (
        Printf.sprintf "%04d" cal.year
      )
    | Some day, Some month -> (
        match lang with
        | I18n.Fr -> Printf.sprintf "%02d/%02d/%04d"
          day month cal.year
        | I18n.En -> Printf.sprintf "%04d/%02d/%02d"
          cal.year month day
      )
    | None, Some month -> (
        match lang with
        | I18n.Fr -> Printf.sprintf "%02d/%04d"
          month cal.year
        | I18n.En -> Printf.sprintf "%04d/%02d"
          cal.year month
      )
    | Some _, None -> (
        assert false
      )
end

module Date = struct
  type t =
      Now
    | Date of Calendar.t

  let translate_date lang d =
    match d with
    | None -> ""
    | Some v -> (
        match v with
        | Now -> (
            match lang with
            | I18n.Fr -> "aujourd'hui"
            | I18n.En -> "now"
          )
        | Date cal -> Calendar.translate lang cal
      )

  let translate_start_end lang date_start date_end =
    if date_start = date_end then
      Printf.sprintf "%s" (translate_date lang date_start)
    else
      match lang with
      | I18n.Fr -> Printf.sprintf "de %s à %s"
        (translate_date lang date_start) (translate_date lang date_end)
    | I18n.En -> Printf.sprintf "from %s to %s"
        (translate_date lang date_start) (translate_date lang date_end)
end

module ID = struct
  type t = {
    firstname : I18n.translation ;
    lastname : I18n.translation ;
    age : int ;
    phone : I18n.translation ;
    address : I18n.translation ;
    email : string ;
    github : string ;
    web : string ;
  }

  let make ~firstname ~lastname ~age ~phone ~address ~email ~github ~web =
    { firstname; lastname; age; phone; address; email; github; web }

  let firstname id = id.firstname

  let lastname id = id.lastname

  let age id = id.age

  let phone id = id.phone

  let address id = id.address

  let email id = id.email

  let github id = id.github

  let web id = id.web
end

module Skill = struct
  type t = {
    title : I18n.translation ;
    percent : int ;
  }

  let make title percent =
    { title; percent }
end

module Experience = struct
  type t = {
    date_start : Date.t option ;
    date_end : Date.t option ;
    title : I18n.translation ;
    company : I18n.translation option ;
    location : I18n.translation option ;
    description : I18n.translation ;	
  }

  let make ~date_start ~date_end ~title ~company ~location ~description =
    { date_start; date_end; title; company; location; description }
end

module Education = struct
  type category = Diploma | Certification | Vocational_training

  type t = {
    category : category ;
    date_start : Date.t option ;
    date_end : Date.t option ;
    title : I18n.translation ;
    school : I18n.translation option ;
    description : I18n.translation ;  
  }

  let translate_category lang cat = 
    match cat with
    | Diploma -> (
        match lang with
        | I18n.Fr -> "Diplômantes"
        | I18n.En -> "Diploma"
      )
    | Certification -> (
        match lang with
        | I18n.Fr -> "Certifiantes"
        | I18n.En -> "Certification"
      )
    | Vocational_training -> (
        match lang with
        | I18n.Fr -> "Continues"
        | I18n.En -> "Vocational training"
      )

  let make ~category ~date_start ~date_end ~title ~school ~description =
    { category; date_start; date_end; title; school; description }

  let diploma edu =
    List.filter (fun e -> match e.category with Diploma -> true | _ -> false) edu

  let certification edu =
    List.filter (fun e -> match e.category with Certification -> true | _ -> false) edu

  let vocational_training edu =
    List.filter (fun e -> match e.category with Vocational_training -> true | _ -> false) edu
end

module Language = struct
  type t = {
    title : I18n.translation ;
    description : I18n.translation ;  
  }

  let make ~title ~description =
    { title; description }
end

module Portfolio = struct
  type t = {
    title : I18n.translation ;
    description : I18n.translation ;
    image : string ;
  }

  let make ~title ~description ~image =
    { title; description; image }
end

module CV = struct
  type t = {
    lang : I18n.lang ;
    title : I18n.translation ;
    description : I18n.translation ;
    id : ID.t ;
    skill : Skill.t list ;
    experience : Experience.t list ;
    education : Education.t list ;
    language : Language.t list ;
    portfolio : Portfolio.t list ;
  }

  let make ~lang ~title ~description ~id ~skill ~experience ~education ~language ~portfolio =
    { lang; title; description; id; skill; experience; education; language; portfolio }

  let lang cv = cv.lang

  let title cv = cv.title

  let description cv = cv.description

  let id cv = cv.id

  let skill cv = cv.skill

  let experience cv = cv.experience

  let education cv = cv.education

  let language cv = cv.language

  let portfolio cv = cv.portfolio
end

module Page = struct
  type status = Summary | Details

  type t = {
    portfolio : (int * status) list
  }

  let make ~portfolio =
    { portfolio }

  let portfolio p = p.portfolio
end

type t = (Page.t * CV.t)

type rs = t React.signal
type rf = ?step:React.step -> t -> unit
type rp = rs * rf
