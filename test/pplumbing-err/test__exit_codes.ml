(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let%expect_test "exit codes" =
  print_dyn (Err.Exit_code.ok |> Dyn.int);
  require (Cmdliner.Cmd.Exit.ok = Err.Exit_code.ok);
  [%expect {| 0 |}];
  print_dyn (Err.Exit_code.some_error |> Dyn.int);
  require (Cmdliner.Cmd.Exit.some_error = Err.Exit_code.some_error);
  [%expect {| 123 |}];
  print_dyn (Err.Exit_code.cli_error |> Dyn.int);
  require (Cmdliner.Cmd.Exit.cli_error = Err.Exit_code.cli_error);
  [%expect {| 124 |}];
  print_dyn (Err.Exit_code.internal_error |> Dyn.int);
  require (Cmdliner.Cmd.Exit.internal_error = Err.Exit_code.internal_error);
  [%expect {| 125 |}];
  ()
;;

let%expect_test "code" =
  let test exit_code = print_endline (Int.to_string exit_code) in
  test Err.Exit_code.ok;
  [%expect {| 0 |}];
  test Err.Exit_code.some_error;
  [%expect {| 123 |}];
  test Err.Exit_code.cli_error;
  [%expect {| 124 |}];
  test Err.Exit_code.internal_error;
  [%expect {| 125 |}];
  test 42;
  [%expect {| 42 |}];
  ()
;;

let%expect_test "exit" =
  let test f = Err.For_test.protect f in
  test ignore;
  [%expect {||}];
  test (fun () -> Err.exit Err.Exit_code.ok);
  [%expect {||}];
  test (fun () -> Err.exit Err.Exit_code.some_error);
  [%expect {| [123] |}];
  test (fun () -> Err.exit Err.Exit_code.cli_error);
  [%expect {| [124] |}];
  test (fun () -> Err.exit Err.Exit_code.internal_error);
  [%expect
    {|
    Backtrace: <backtrace disabled in tests>
    [125]
    |}];
  test (fun () -> Err.exit 42);
  [%expect {| [42] |}];
  ()
;;

let%expect_test "exit without handler" =
  require_does_raise (fun () -> Err.exit Err.Exit_code.ok);
  [%expect {| (exit_code 0) |}];
  require_does_raise (fun () -> Err.exit Err.Exit_code.some_error);
  [%expect {| (exit_code 123) |}];
  ()
;;

let%expect_test "exit_code in sexp" =
  let e = Err.create [ Pp.text "Hello Exit Code" ] in
  print_endline (Sexp.to_string_hum (Err.sexp_of_t e));
  [%expect {| "Hello Exit Code" |}];
  require_does_raise (fun () -> raise (Err.E e));
  [%expect {| "Hello Exit Code" |}];
  print_endline (Sexp.to_string_hum (Err.With_exit_code.sexp_of_t e));
  [%expect {| ("Hello Exit Code" (exit_code 123)) |}];
  ()
;;

let%expect_test "exit_code in dyn" =
  let e = Err.create [ Pp.text "Hello Exit Code" ] in
  print_dyn (Err.to_dyn e);
  [%expect {| { msgs = [ "Hello Exit Code" ] } |}];
  print_dyn (Err.With_exit_code.to_dyn e);
  [%expect {| { msgs = [ "Hello Exit Code" ]; exit_code = 123 } |}];
  ()
;;

let%expect_test "empty error to_dyn" =
  (* When an error has no paragraphs (e.g. created via [Err.exit]), the exit
     code is always included in [to_dyn], even without [With_exit_code]. *)
  let e = Err.create ~exit_code:Err.Exit_code.ok [] in
  print_dyn (Err.to_dyn e);
  [%expect {| { exit_code = 0 } |}];
  print_dyn (Err.With_exit_code.to_dyn e);
  [%expect {| { exit_code = 0 } |}];
  let e = Err.create ~exit_code:Err.Exit_code.some_error [] in
  print_dyn (Err.to_dyn e);
  [%expect {| { exit_code = 123 } |}];
  ()
;;
