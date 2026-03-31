(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let%expect_test "sexp_of_t" =
  List.iter Err.Level.all ~f:(fun log_level ->
    print_endline (Sexp.to_string_hum (Err.Level.sexp_of_t log_level)));
  [%expect
    {|
    Error
    Warning
    Info
    Debug
    |}];
  ()
;;

let%expect_test "to_dyn" =
  List.iter Err.Level.all ~f:(fun log_level -> print_dyn (Err.Level.to_dyn log_level));
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
    require (Err.Level.equal log_level log_level);
    require (0 = Err.Level.compare log_level log_level));
  require (not (Err.Level.equal Error Warning));
  require (Err.Level.compare Error Warning < 0);
  require (Err.Level.compare Debug Error > 0);
  [%expect {||}];
  ()
;;
