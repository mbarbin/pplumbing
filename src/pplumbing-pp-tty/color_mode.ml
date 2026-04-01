(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type t =
  [ `Auto
  | `Always
  | `Never
  ]

let variant_constructor_name : t -> string = function
  | `Auto -> "Auto"
  | `Always -> "Always"
  | `Never -> "Never"
;;

let all : t list = [ `Auto; `Always; `Never ]

let to_index = function
  | `Auto -> 0
  | `Always -> 1
  | `Never -> 2
;;

let compare l1 l2 = Int.compare (to_index l1) (to_index l2)
let equal l1 l2 = Int.equal (to_index l1) (to_index l2)

let to_string : t -> string = function
  | `Auto -> "auto"
  | `Always -> "always"
  | `Never -> "never"
;;

let value : t ref = ref `Auto

let env_color_mode =
  lazy
    (let clicolor_force =
       match Sys.getenv_opt "CLICOLOR_FORCE" with
       | None | Some "0" -> false
       | _ -> true
     in
     if clicolor_force
     then `Always
     else (
       let is_dumb =
         match Sys.getenv_opt "TERM" with
         | Some "dumb" -> true
         | _ -> false
       in
       let clicolor =
         match Sys.getenv_opt "CLICOLOR" with
         | Some "0" -> false
         | _ -> true
       in
       if (not is_dumb) && clicolor then `Auto else `Never))
;;

let color_mode () =
  match !value with
  | (`Always | `Never) as mode -> mode
  | `Auto -> Lazy.force env_color_mode
;;

let should_enable_color fd =
  match color_mode () with
  | `Always -> true
  | `Never -> false
  | `Auto -> Unix.isatty fd
;;
