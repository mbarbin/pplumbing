module Ansi_color = Ansi_color
module Style = Stdune.User_message.Style
module Print_config = Stdune.User_message.Print_config

type t = Style.t Pp.t

let print ?(config = Print_config.default) t = Ansi_color.print (Pp.map_tags t ~f:config)
let prerr ?(config = Print_config.default) t = Ansi_color.prerr (Pp.map_tags t ~f:config)
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
