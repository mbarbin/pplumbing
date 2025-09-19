(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let run ?exn_handler cmd ~name ~version =
  match
    Err.protect ?exn_handler (fun () ->
      Climate.Command.run
        (Cmdlang_to_climate.Translate.command cmd)
        ~program_name:(Literal name)
        ~version)
  with
  | Ok () -> ()
  | Error code -> exit code
;;
