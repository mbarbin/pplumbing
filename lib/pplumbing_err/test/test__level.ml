(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let%expect_test "sexp_of_t" =
  List.iter Err.Level.all ~f:(fun log_level -> print_s [%sexp (log_level : Err.Level.t)]);
  [%expect
    {|
    Error
    Warning
    Info
    Debug
    |}];
  ()
;;

let%expect_test "to_string" =
  List.iter Err.Level.all ~f:(fun log_level ->
    print_endline (Err.Level.to_string log_level));
  [%expect
    {|
    error
    warning
    info
    debug
    |}];
  ()
;;

let%expect_test "compare" =
  List.iter Err.Level.all ~f:(fun log_level ->
    require [%here] (Err.Level.equal log_level log_level);
    require [%here] (0 = Err.Level.compare log_level log_level));
  require [%here] (not (Err.Level.equal Error Warning));
  require [%here] (Err.Level.compare Error Warning < 0);
  require [%here] (Err.Level.compare Debug Error > 0);
  [%expect {||}];
  ()
;;
