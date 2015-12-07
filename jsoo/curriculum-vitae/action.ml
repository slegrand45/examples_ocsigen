open Types

type action =
    | Update_lang of I18n.lang
    | Portfolio_details of int
    | Portfolio_summary of int
