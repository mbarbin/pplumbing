(*_********************************************************************************)
(*_  pplumbing - Utility libraries to use with [pp]                               *)
(*_  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

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

val phys_equal : 'a -> 'a -> bool
val print : _ Pp.t -> unit
val print_dyn : Dyn.t -> unit
val print_endline : string -> unit
val require : bool -> unit
val require_does_raise : (unit -> 'a) -> unit
val require_equal : (module With_equal_and_dyn.S with type t = 'a) -> 'a -> 'a -> unit
