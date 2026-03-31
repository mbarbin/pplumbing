(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

include Ordering

let to_dyn = function
  | Lt -> Dyn.Variant ("Lt", [])
  | Eq -> Dyn.Variant ("Eq", [])
  | Gt -> Dyn.Variant ("Gt", [])
;;
