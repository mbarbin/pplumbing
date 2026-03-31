(*_********************************************************************************)
(*_  pplumbing - Utility libraries to use with [pp]                               *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

module type S = sig
  type t

  val equal : t -> t -> bool
  val to_dyn : t -> Dyn.t
end
