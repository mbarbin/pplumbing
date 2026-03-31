(*_********************************************************************************)
(*_  pplumbing - Utility libraries to use with [pp]                               *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

include module type of struct
  include ListLabels
end

val iter : 'a t -> f:('a -> unit) -> unit
