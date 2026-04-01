(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

include Stdlib.Atomic

let set_temporarily t a ~f =
  let x = get t in
  set t a;
  Fun.protect ~finally:(fun () -> set t x) f
;;
