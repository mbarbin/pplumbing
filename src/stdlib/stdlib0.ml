(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Code_error = Code_error0
module Dyn = Dyn0
module Err = Err0
module Int = Int0
module List = List0
module Loc = Loc0
module Ordering = Ordering0
module Pp = Pp0
module Pp_tty = Pp_tty0
module Ref = Ref0
module Sexp = Sexp0
module String = String0
module With_equal_and_dyn = With_equal_and_dyn0

let phys_equal = Stdlib.( == )
let print pp = Format.printf "%a@." Pp.to_fmt pp
let print_dyn dyn = print (Dyn.pp dyn)
let print_endline = Stdlib.print_endline
let require cond = if not cond then failwith "Required condition does not hold"

let require_does_raise f =
  match f () with
  | _ -> Code_error.raise "Did not raise." []
  | exception e -> print_endline (Printexc.to_string e)
;;

let require_equal
      (type a)
      (module M : With_equal_and_dyn.S with type t = a)
      (v1 : a)
      (v2 : a)
  =
  if not (M.equal v1 v2)
  then
    Code_error.raise
      "Values are not equal."
      [ "v1", v1 |> M.to_dyn; "v2", v2 |> M.to_dyn ]
;;
