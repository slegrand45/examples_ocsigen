open Types

let msg = [
    I18n.msg ~id:I18n.Contact_title ~l:[
      I18n.make ~lang:I18n.Fr ~s:"Me contacter" ;
      I18n.make ~lang:I18n.En ~s:"Contact me" ;
    ] ;
    I18n.msg ~id:I18n.Skill_title ~l:[
      I18n.make ~lang:I18n.Fr ~s:"Mes compétences" ;
      I18n.make ~lang:I18n.En ~s:"My skills" ;
    ] ;
    I18n.msg ~id:I18n.Language_title ~l:[
      I18n.make ~lang:I18n.Fr ~s:"Langues" ;
      I18n.make ~lang:I18n.En ~s:"Languages" ;
    ] ;
    I18n.msg ~id:I18n.Work_title ~l:[
      I18n.make ~lang:I18n.Fr ~s:"Expérience professionnelle" ;
      I18n.make ~lang:I18n.En ~s:"Work experience" ;
    ] ;
    I18n.msg ~id:I18n.Education_title ~l:[
      I18n.make ~lang:I18n.Fr ~s:"Formation" ;
      I18n.make ~lang:I18n.En ~s:"Education" ;
    ] ;
    I18n.msg ~id:I18n.Portfolio_title ~l:[
      I18n.make ~lang:I18n.Fr ~s:"Portfolio" ;
      I18n.make ~lang:I18n.En ~s:"Portfolio" ;
    ] ;
]

let id =
  let firstname = [
    I18n.make ~lang:I18n.Fr ~s:"Dark" ;
    I18n.make ~lang:I18n.En ~s:"Darth" ;
  ] in
  let lastname = [
    I18n.make ~lang:I18n.Fr ~s:"Vador" ;
    I18n.make ~lang:I18n.En ~s:"Vader" ;
  ] in
  let age = 0 in
  let phone = [
    I18n.make ~lang:I18n.Fr ~s:"800-5-21-1980" ;
    I18n.make ~lang:I18n.En ~s:"800-5-21-1980" ;
  ] in
  let address = [
    I18n.make ~lang:I18n.Fr ~s:"Etoile de la mort, Niveau 1" ;
    I18n.make ~lang:I18n.En ~s:"Death Star, Level 1" ;
  ] in
  let email = "darth.sithlord@gmail.com" in
  let github = "" in
  let web = "" in
  ID.make ~firstname ~lastname ~age ~phone ~address ~email ~github ~web

let skill = [
  Skill.make [
    I18n.make ~lang:I18n.Fr ~s:"Pilote TIE" ;
    I18n.make ~lang:I18n.En ~s:"TIE Pilot" ;
  ] 100 ;
  Skill.make [
    I18n.make ~lang:I18n.Fr ~s:"Ingénieur" ;
    I18n.make ~lang:I18n.En ~s:"Engineer" ;
  ] 83 ;
  Skill.make [
    I18n.make ~lang:I18n.Fr ~s:"Lord Sith" ;
    I18n.make ~lang:I18n.En ~s:"Sith Lord" ;
  ] 100 ;
  Skill.make [
    I18n.make ~lang:I18n.Fr ~s:"Duel au sabre laser" ;
    I18n.make ~lang:I18n.En ~s:"Lightsaber Dueling" ;
  ] 66 ;
  Skill.make [
    I18n.make ~lang:I18n.Fr ~s:"Persuasion" ;
    I18n.make ~lang:I18n.En ~s:"Persuasion" ;
  ] 83 ;
  Skill.make [
    I18n.make ~lang:I18n.Fr ~s:"Entretenir un comportement obscur" ;
    I18n.make ~lang:I18n.En ~s:"Maintaining a dark attitude" ;
  ] 100 ;
]

let language =
  let title = [
    I18n.make ~lang:I18n.Fr ~s:"Basic, Huttish, Binaire, Sith" ;
    I18n.make ~lang:I18n.En ~s:"Galactic Basic Standard, Huttese, Binary, Sith" ;
  ] in
  let description = [
    I18n.make ~lang:I18n.Fr ~s:"" ;
    I18n.make ~lang:I18n.En ~s:"" ;
  ] in
  [ Language.make ~title ~description ]

let experience =
  let empire =
    let date_start = None in
    let date_end = None in
    let title = [
      I18n.make ~lang:I18n.Fr
        ~s:"Empire Galactique" ;
      I18n.make ~lang:I18n.En
        ~s:"Galactic Empire" ;
    ] in
    let company = None in
    let location = None in
    let description = [
      I18n.make ~lang:I18n.Fr
        ~s:("Capture de la princesse Leia. "
          ^ "Supervision de la construction de l'Etoile de la Mort. "
          ^ "Réduction de 36% des coûts de main d'oeuvre grâce à une gestion obscure des ressources humaines.") ;
      I18n.make ~lang:I18n.En
        ~s:("Captured Princess Leia. "
          ^ "Oversaw construction of the Death Star. "
          ^ "Reduced operating costs by 36% through mass executions.") ;
    ] in
    Experience.make ~date_start ~date_end ~title ~company
      ~location ~description
  in
  let jedi =
    let date_start = None in
    let date_end = None in
    let title = [
      I18n.make ~lang:I18n.Fr
        ~s:"Conseil Jedi" ;
      I18n.make ~lang:I18n.En
        ~s:"Jedi Council" ;
    ] in
    let company = None in
    let location = None in
    let description = [
      I18n.make ~lang:I18n.Fr
        ~s:("Préparateur officiel du café pour Yoda. "
          ^ "Entraînement des padawans jedi. "
          ^ "Maintien de la paix.") ;
      I18n.make ~lang:I18n.En
        ~s:("Made coffee for Yoda. "
          ^ "Trained jedi padawans. "
          ^ "Maintained peace.") ;
    ] in
    Experience.make ~date_start ~date_end ~title ~company
      ~location ~description
  in
  [ empire; jedi ]

let education =
  let palpatine =
    let category = Education.Diploma in
    let date_start = None in
    let date_end = None in
    let title = [
      I18n.make ~lang:I18n.Fr
        ~s:"Institut Palpatine des Etudes du Côté Obscur" ;
      I18n.make ~lang:I18n.En
        ~s:"Palpatine Institute of Dark Side Studies" ;
    ] in
    let school = None in
    let description = [
      I18n.make ~lang:I18n.Fr
        ~s:("Stratégie de domination galactique. "
          ^ "Etude du côté obscur de la Force. "
          ^ "Techniques de strangulation à main libre. "
          ^ "Comment adopter un style de vie cyborg.") ;
      I18n.make ~lang:I18n.En
        ~s:("Strategic Galaxy Domination. "
          ^ "Dark Side Force. "
          ^ "Handsfree Strangulation Techniques. "
          ^ "Cyborg Lifestyle.") ;
    ] in
    Education.make ~category ~date_start ~date_end ~title ~school
       ~description
  in
  let kenobi =
    let category = Education.Diploma in
    let date_start = None in
    let date_end = None in
    let title = [
      I18n.make ~lang:I18n.Fr
        ~s:"Académie Obi-Wan Kenobi de Formation Avancée Jedi" ;
      I18n.make ~lang:I18n.En
        ~s:"Obi-Wan Kenobi Academy of Advanced Jedi Training" ;
    ] in
    let school = None in
    let description = [
      I18n.make ~lang:I18n.Fr
        ~s:("Ethique de la Force. "
          ^ "Maniement du sabre laser et techniques de duel. "
          ^ "Histoire Jedi.") ;
      I18n.make ~lang:I18n.En
        ~s:("Ethics of force use. "
          ^ "Lightsaber wielding and dueling. "
          ^ "Jedi history.") ;
    ] in
    Education.make ~category ~date_start ~date_end ~title ~school
       ~description
  in
  [ palpatine; kenobi ]

let portfolio =
  let jedi =
    let title = [
      I18n.make ~lang:I18n.Fr ~s:"Magazine Jedi" ;
      I18n.make ~lang:I18n.En ~s:"Jedi magazine" ;
    ] in
    let description = [
      I18n.make ~lang:I18n.Fr ~s:"Sélectionné dans Magazine Jedi comme le plus influent Lord Sith de la Galaxie." ;
      I18n.make ~lang:I18n.En ~s:"Featured in Jedi magazine as the Galaxy's most influential Sith Lord." ;
    ] in
    let image = "img/ID-100165338.jpg" in
    Portfolio.make ~title ~description ~image
  in
  let times =
    let title = [
      I18n.make ~lang:I18n.Fr ~s:"Tatooine Times" ;
      I18n.make ~lang:I18n.En ~s:"Tatooine Times" ;
    ] in
    let description = [
      I18n.make ~lang:I18n.Fr ~s:"Elu père de l'année par Tatooine Times." ;
      I18n.make ~lang:I18n.En ~s:"Voted father of the year by Tatooine Times." ;
    ] in
    let image = "img/ID-100209817.jpg" in
    Portfolio.make ~title ~description ~image
  in
  let vogue =
    let title = [
      I18n.make ~lang:I18n.Fr ~s:"Vogue Obscure" ;
      I18n.make ~lang:I18n.En ~s:"DarkVogue" ;
    ] in
    let description = [
      I18n.make ~lang:I18n.Fr ~s:"Meilleur look de l'année par Vogue Obscure." ;
      I18n.make ~lang:I18n.En ~s:"Best look of the month by DarkVogue." ;
    ] in
    let image = "img/ID-100371977.jpg" in
    Portfolio.make ~title ~description ~image
  in
  [ jedi; times; vogue ]

let cv lang =
  let title = [
    I18n.make ~lang:I18n.Fr
      ~s:"" ;
    I18n.make ~lang:I18n.En
      ~s:"" ;
  ] in
  let description = [
    I18n.make ~lang:I18n.Fr
      ~s:"Lord Sith et père affectueux" ;
    I18n.make ~lang:I18n.En
      ~s:"Sith Lord and loving father" ;
  ] in
  CV.make ~lang ~title ~description ~id ~skill ~language ~experience ~education ~portfolio

let page =
  Page.make ~portfolio:[
    (0, Page.Summary) ;
    (1, Page.Summary) ;
    (2, Page.Summary) ;
  ]

let init lang = 
  (page, cv lang)
