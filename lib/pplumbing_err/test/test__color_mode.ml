(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let%expect_test "color_mode" =
  List.iter Err.Color_mode.all ~f:(fun color_mode ->
    Err.Private.color_mode := color_mode;
    let color_mode' = Err.color_mode () in
    require_equal [%here] (module Err.Color_mode) color_mode color_mode';
    print_s [%sexp (color_mode' : Err.Color_mode.t)]);
  [%expect
    {|
    Auto
    Always
    Never
    |}];
  Err.Private.color_mode := `Auto;
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
    require [%here] (Err.Color_mode.equal log_level log_level);
    require [%here] (0 = Err.Color_mode.compare log_level log_level));
  require [%here] (not (Err.Color_mode.equal `Never `Always));
  require [%here] (Err.Color_mode.compare `Never `Auto > 0);
  require [%here] (Err.Color_mode.compare `Auto `Always < 0);
  [%expect {||}];
  ()
;;
