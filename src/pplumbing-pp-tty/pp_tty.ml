(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Ansi_color = Ansi_color

module Style = struct
  type t =
    | Loc
    | Error
    | Warning
    | Kwd
    | Id
    | Prompt
    | Hint
    | Details
    | Ok
    | Debug
    | Success
    | Ansi_styles of Ansi_color.Style.t list
    | Original_sexp of Sexplib0.Sexp.t
    | Original_dyn of Dyn.t

  let of_stdune : Stdune.User_message.Style.t -> t = function
    | Loc -> Loc
    | Error -> Error
    | Warning -> Warning
    | Kwd -> Kwd
    | Id -> Id
    | Prompt -> Prompt
    | Hint -> Hint
    | Details -> Details
    | Ok -> Ok
    | Debug -> Debug
    | Success -> Success
    | Ansi_styles l -> Ansi_styles l
  ;;

  let to_stdune : t -> Stdune.User_message.Style.t = function
    | Loc -> Loc
    | Error -> Error
    | Warning -> Warning
    | Kwd -> Kwd
    | Id -> Id
    | Prompt -> Prompt
    | Hint -> Hint
    | Details -> Details
    | Ok -> Ok
    | Debug -> Debug
    | Success -> Success
    | Ansi_styles l -> Ansi_styles l
    | Original_sexp _ | Original_dyn _ -> Details
  ;;

  let to_dyn =
    let open Dyn in
    function
    | Loc -> variant "Loc" []
    | Error -> variant "Error" []
    | Warning -> variant "Warning" []
    | Kwd -> variant "Kwd" []
    | Id -> variant "Id" []
    | Prompt -> variant "Prompt" []
    | Hint -> variant "Hint" []
    | Details -> variant "Details" []
    | Ok -> variant "Ok" []
    | Debug -> variant "Debug" []
    | Success -> variant "Success" []
    | Ansi_styles l -> variant "Ansi_styles" [ list Ansi_color.Style.to_dyn l ]
    | Original_sexp _ -> variant "Original_sexp" [ string "<sexp>" ]
    | Original_dyn d -> variant "Original_dyn" [ d ]
  ;;

  let to_index = function
    | Loc -> 0
    | Error -> 1
    | Warning -> 2
    | Kwd -> 3
    | Id -> 4
    | Prompt -> 5
    | Hint -> 6
    | Details -> 7
    | Ok -> 8
    | Debug -> 9
    | Success -> 10
    | Ansi_styles _ -> 11
    | Original_sexp _ -> 12
    | Original_dyn _ -> 13
  ;;

  let compare t1 t2 : Ordering.t =
    match t1, t2 with
    | Ansi_styles _, Ansi_styles _ -> Eq
    | Original_sexp _, Original_sexp _ -> Eq
    | Original_dyn _, Original_dyn _ -> Eq
    | _ ->
      (match Int.compare (to_index t1) (to_index t2) with
       | x when x < 0 -> Lt
       | 0 -> Eq
       | _ -> Gt)
  ;;
end

module Print_config = struct
  type t = Style.t -> Ansi_color.Style.t list

  let default : t = function
    | Loc -> [ `Bold ]
    | Error -> [ `Bold; `Fg_red ]
    | Warning -> [ `Bold; `Fg_magenta ]
    | Kwd -> [ `Bold; `Fg_blue ]
    | Id -> [ `Bold; `Fg_yellow ]
    | Prompt -> [ `Bold; `Fg_green ]
    | Hint -> [ `Italic ]
    | Details -> [ `Dim ]
    | Ok -> [ `Fg_green ]
    | Debug -> [ `Underline; `Fg_bright_cyan ]
    | Success -> [ `Bold; `Fg_green ]
    | Ansi_styles l -> l
    | Original_sexp _ -> [ `Dim ]
    | Original_dyn _ -> [ `Dim ]
  ;;
end

type t = Style.t Pp.t

let print ?(config = Print_config.default) t = Ansi_color.print (Pp.map_tags t ~f:config)
let prerr ?(config = Print_config.default) t = Ansi_color.prerr (Pp.map_tags t ~f:config)
let pp_with_config ~config fmt t = Ansi_color.pp fmt (Pp.map_tags t ~f:config)
let pp fmt t = pp_with_config ~config:Print_config.default fmt t
let to_string_with_config ~config t = Ansi_color.to_string (Pp.map_tags t ~f:config)
let to_string t = to_string_with_config ~config:Print_config.default t
let tag = Pp.tag
let surround s1 s2 t = Pp.box ~indent:1 Pp.O.(Pp.verbatim s1 ++ t ++ Pp.verbatim s2)
let parens t = surround "(" ")" t
let brackets t = surround "[" "]" t
let braces t = surround "{" "}" t
let simple_quotes t = surround "'" "'" t
let double_quotes t = surround "\"" "\"" t

let stdune_loc (loc : Loc.t) =
  let { Loc.Lexbuf_loc.start; stop } = Loc.to_lexbuf_loc loc in
  Stdune.Loc.of_lexbuf_loc { start; stop }
;;

let loc loc =
  Stdune.Loc.pp (stdune_loc loc)
  |> Pp.map_tags ~f:(fun (Loc : Stdune.Loc.tag) -> Style.Loc)
;;

module type To_string = sig
  type t

  val to_string : t -> string
end

let id (type a) (module M : To_string with type t = a) x =
  Pp.tag Style.Id (Pp.verbatim (M.to_string x)) |> brackets
;;

let kwd (type a) (module M : To_string with type t = a) x =
  Pp.tag Style.Kwd (Pp.verbatim (M.to_string x)) |> brackets
;;

let ansi (type a) (module M : To_string with type t = a) x styles =
  Pp.tag (Style.Ansi_styles styles) (Pp.verbatim (M.to_string x))
;;

let path (type a) (module M : To_string with type t = a) x =
  Pp.tag (Style.Ansi_styles [ `Bold ]) (Pp.verbatim (M.to_string x)) |> double_quotes
;;
