(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let%expect_test "color_mode" =
  List.iter Err.Color_mode.all ~f:(fun color_mode ->
    Atomic.set Err.Private.color_mode color_mode;
    let color_mode' = Err.color_mode () in
    require_equal (module Err.Color_mode) color_mode color_mode';
    print_endline (Sexp.to_string_hum (Err.Color_mode.sexp_of_t color_mode')));
  [%expect
    {|
    Auto
    Always
    Never
    |}];
  Atomic.set Err.Private.color_mode `Auto;
  ()
;;

let%expect_test "to_dyn" =
  List.iter Err.Color_mode.all ~f:(fun color_mode ->
    print_dyn (Err.Color_mode.to_dyn color_mode));
  [%expect
    {|
    Auto
    Always
    Never
    |}];
  ()
;;

let%expect_test "to_string" =
  List.iter Err.Color_mode.all ~f:(fun log_level ->
    print_endline (Err.Color_mode.to_string log_level));
  [%expect
    {|
    auto
    always
    never
    |}];
  ()
;;

let%expect_test "compare" =
  List.iter Err.Color_mode.all ~f:(fun log_level ->
    require (Err.Color_mode.equal log_level log_level);
    require (0 = Err.Color_mode.compare log_level log_level));
  require (not (Err.Color_mode.equal `Never `Always));
  require (Err.Color_mode.compare `Never `Auto > 0);
  require (Err.Color_mode.compare `Auto `Always < 0);
  [%expect {||}];
  ()
;;
