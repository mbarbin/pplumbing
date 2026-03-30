(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* {1 Tests for surround helpers} *)

let%expect_test "parens" =
  print (Pp_tty.parens (Pp.verbatim "hello"));
  [%expect {| (hello) |}];
  ()
;;

let%expect_test "brackets" =
  print (Pp_tty.brackets (Pp.verbatim "hello"));
  [%expect {| [hello] |}];
  ()
;;

let%expect_test "braces" =
  print (Pp_tty.braces (Pp.verbatim "hello"));
  [%expect {| {hello} |}];
  ()
;;

let%expect_test "simple_quotes" =
  print (Pp_tty.simple_quotes (Pp.verbatim "hello"));
  [%expect {| 'hello' |}];
  ()
;;

let%expect_test "double_quotes" =
  print (Pp_tty.double_quotes (Pp.verbatim "hello"));
  [%expect {| "hello" |}];
  ()
;;

(* {1 Tests for tag} *)

let%expect_test "tag" =
  let pp = Pp_tty.tag Pp_tty.Style.Id (Pp.verbatim "identifier") in
  (* [Pp.to_fmt] drops tags, so the text content is preserved. *)
  print pp;
  [%expect {| identifier |}];
  ()
;;

(* {1 Tests for opinionated helpers} *)

let%expect_test "id" =
  print (Pp_tty.id (module String) "my_var");
  [%expect {| [my_var] |}];
  ()
;;

let%expect_test "kwd" =
  print (Pp_tty.kwd (module String) "let");
  [%expect {| [let] |}];
  ()
;;

let%expect_test "path" =
  print (Pp_tty.path (module String) "/usr/bin/ocaml");
  [%expect {| "/usr/bin/ocaml" |}];
  ()
;;

let%expect_test "ansi" =
  let pp = Pp_tty.ansi (module String) "colored" [ `Fg_red; `Bold ] in
  print pp;
  [%expect {| colored |}];
  ()
;;

(* {1 Tests for print and prerr} *)

let%expect_test "print" =
  Pp_tty.print (Pp.verbatim "to stdout");
  [%expect {| to stdout |}];
  ()
;;

let%expect_test "prerr" =
  Pp_tty.prerr (Pp.verbatim "to stderr");
  [%expect {| to stderr |}];
  ()
;;

let%expect_test "print with style tag" =
  Pp_tty.print (Pp_tty.tag Pp_tty.Style.Error (Pp.verbatim "error text"));
  [%expect {| error text |}];
  ()
;;

(* {1 Tests for loc} *)

let%expect_test "loc - of_pos" =
  let loc = Loc.of_pos ("test-file.ml", 10, 5, 15) in
  let pp = Pp_tty.loc loc in
  print pp;
  [%expect {| File "test-file.ml", line 10, characters 5-15: |}];
  ()
;;

(* {1 Tests for Style} *)

let%expect_test "Style.to_dyn" =
  let test style = print_dyn (Pp_tty.Style.to_dyn style) in
  test Loc;
  [%expect {| Loc |}];
  test Error;
  [%expect {| Error |}];
  test Warning;
  [%expect {| Warning |}];
  test Kwd;
  [%expect {| Kwd |}];
  test Id;
  [%expect {| Id |}];
  test Prompt;
  [%expect {| Prompt |}];
  test Hint;
  [%expect {| Hint |}];
  test Details;
  [%expect {| Details |}];
  test Ok;
  [%expect {| Ok |}];
  test Debug;
  [%expect {| Debug |}];
  test Success;
  [%expect {| Success |}];
  test (Ansi_styles [ `Bold; `Fg_red ]);
  [%expect {| Ansi_styles [ Bold; Fg_red ] |}];
  ()
;;

let%expect_test "Style.compare" =
  let print_cmp a b = print_dyn (Pp_tty.Style.compare a b |> Ordering.to_dyn) in
  print_cmp Pp_tty.Style.Error Pp_tty.Style.Error;
  [%expect {| Eq |}];
  print_cmp Pp_tty.Style.Error Pp_tty.Style.Warning;
  [%expect {| Lt |}];
  ()
;;
