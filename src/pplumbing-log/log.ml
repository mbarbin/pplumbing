(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type level = Logs.level
type src = Logs.src

let render fmt pps =
  let pp = Pp.vbox (Pp.concat_map pps ~sep:Pp.cut ~f:Pp.box) in
  if fmt == Format.std_formatter
  then Pp_tty.Ansi_color.print (Pp.map_tags pp ~f:Pp_tty.Print_config.default)
  else if fmt == Format.err_formatter
  then Pp_tty.Ansi_color.prerr (Pp.map_tags pp ~f:Pp_tty.Print_config.default)
  else Pp.to_fmt fmt pp
;;

type log =
  ?header:string -> ?tags:(unit -> Logs.Tag.set) -> (unit -> Pp_tty.t list) -> unit

let msg ?src level ?header ?tags f =
  Logs.msg ?src level (fun m ->
    m ?header ?tags:(Option.map (fun tags -> tags ()) tags) "%a" render (f ()))
;;

let app ?src ?header ?tags f = msg ?src App ?header ?tags f
let err ?src ?header ?tags f = msg ?src Error ?header ?tags f
let warn ?src ?header ?tags f = msg ?src Warning ?header ?tags f
let info ?src ?header ?tags f = msg ?src Info ?header ?tags f
let debug ?src ?header ?tags f = msg ?src Debug ?header ?tags f

module Logs = struct
  type msgf = ?header:string -> ?tags:Logs.Tag.set -> Pp_tty.t list -> unit
  type log = (msgf -> unit) -> unit

  let msg ?src level f =
    Logs.msg ?src level (fun m ->
      f (fun ?header ?tags pp -> m ?header ?tags "%a" render pp))
  ;;

  let app ?src f = msg ?src App f
  let err ?src f = msg ?src Error f
  let warn ?src f = msg ?src Warning f
  let info ?src f = msg ?src Info f
  let debug ?src f = msg ?src Debug f
end
