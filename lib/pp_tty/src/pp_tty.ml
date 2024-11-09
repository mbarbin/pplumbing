module Ansi_color = Ansi_color
module Style = Stdune.User_message.Style
module Print_config = Stdune.User_message.Print_config

type t = Style.t Pp.t

let print ?(config = Print_config.default) t = Ansi_color.print (Pp.map_tags t ~f:config)
let prerr ?(config = Print_config.default) t = Ansi_color.prerr (Pp.map_tags t ~f:config)

module O = struct
  let ( ++ ) = Pp.O.( ++ )
  let v = Pp.verbatim
end

let surround s1 s2 t = Pp.box ~indent:1 O.(v s1 ++ t ++ v s2)
let parens t = surround "(" ")" t
let brackets t = surround "[" "]" t
let braces t = surround "{" "}" t
let simple_quotes t = surround "'" "'" t
let double_quotes t = surround "\"" "\"" t

module type To_string = sig
  type t

  val to_string : t -> string
end

let id (type a) (module M : To_string with type t = a) x =
  Pp.tag Style.Id (O.v (M.to_string x)) |> brackets
;;

let kwd (type a) (module M : To_string with type t = a) x =
  Pp.tag Style.Kwd (O.v (M.to_string x)) |> brackets
;;

let ansi (type a) (module M : To_string with type t = a) x styles =
  Pp.tag (Style.Ansi_styles styles) (O.v (M.to_string x))
;;

let path (type a) (module M : To_string with type t = a) x =
  Pp.tag (Style.Ansi_styles [ `Bold ]) (O.v (M.to_string x)) |> double_quotes
;;
