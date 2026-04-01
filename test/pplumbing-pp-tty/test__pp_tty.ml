(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
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

(* {1 Tests for pp and to_string} *)

let%expect_test "pp - plain text" =
  Pp_tty.pp Format.std_formatter (Pp.verbatim "hello via pp");
  [%expect {| hello via pp |}];
  ()
;;

let%expect_test "pp - with style tag" =
  let t = Pp_tty.tag Pp_tty.Style.Error (Pp.verbatim "error") in
  let s = Pp_tty.to_string t in
  print_string (Pp_tty.Ansi_color.strip s);
  [%expect {| error |}];
  ()
;;

let%expect_test "to_string - plain text" =
  let s = Pp_tty.to_string (Pp.verbatim "plain") in
  print_string s;
  [%expect {| plain |}];
  ()
;;

let%expect_test "to_string - with style produces escape sequences" =
  let t = Pp_tty.tag Pp_tty.Style.Warning (Pp.verbatim "warn") in
  let s = Pp_tty.to_string t in
  require (String.length s > String.length "warn");
  print_string (Pp_tty.Ansi_color.strip s);
  [%expect {| warn |}];
  ()
;;

let%expect_test "to_string - Ansi_styles" =
  let t =
    Pp_tty.tag (Pp_tty.Style.Ansi_styles [ `Fg_red; `Bold ]) (Pp.verbatim "red bold")
  in
  let s = Pp_tty.to_string t in
  require (String.length s > String.length "red bold");
  print_string (Pp_tty.Ansi_color.strip s);
  [%expect {| red bold |}];
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
  test (Original_sexp (List [ Atom "key"; Atom "value" ]));
  [%expect {| Original_sexp "<sexp>" |}];
  test (Original_dyn (Dyn.variant "Hello" [ Dyn.int 42 ]));
  [%expect {| Original_dyn (Hello 42) |}];
  ()
;;

(* {1 Tests for sexp and dyn helpers} *)

let%expect_test "sexp" =
  let pp = Pp_tty.sexp (List [ Atom "key"; Atom "value" ]) in
  print pp;
  [%expect {| (key value) |}];
  ()
;;

let%expect_test "dyn" =
  let pp = Pp_tty.dyn (Dyn.variant "Hello" [ Dyn.int 42 ]) in
  print pp;
  [%expect {| Hello 42 |}];
  ()
;;

(* {1 Tests for stdune tag mapping} *)

let%expect_test "Style.of_stdune - all tags" =
  let test (stdune_tag : Stdune.User_message.Style.t) =
    let tag = Pp_tty.Style.of_stdune stdune_tag in
    print_dyn (Pp_tty.Style.to_dyn tag)
  in
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

let%expect_test "Style.to_stdune - all tags" =
  let module Stdune_style = Stdune.User_message.Style in
  let test tag =
    match Pp_tty.Style.to_stdune tag with
    | Some stdune_tag -> print_dyn (Stdune_style.to_dyn stdune_tag)
    | None -> print_endline "None"
  in
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
  (* Original_sexp and Original_dyn have no Stdune equivalent. *)
  test (Original_sexp (Atom "x"));
  [%expect {| None |}];
  test (Original_dyn (Dyn.int 0));
  [%expect {| None |}];
  ()
;;

let%expect_test "Style.of_stdune roundtrip" =
  let test (stdune_tag : Stdune.User_message.Style.t) =
    let tag = Pp_tty.Style.of_stdune stdune_tag in
    let back =
      match Pp_tty.Style.to_stdune tag with
      | Some t -> t
      | None -> assert false
    in
    require_equal
      (module struct
        type t = Stdune.User_message.Style.t

        let equal a b = Stdune.User_message.Style.compare a b = Eq
        let to_dyn = Stdune.User_message.Style.to_dyn
      end)
      stdune_tag
      back
  in
  test Loc;
  test Error;
  test Warning;
  test Kwd;
  test Id;
  test Prompt;
  test Hint;
  test Details;
  test Ok;
  test Debug;
  test Success;
  test (Ansi_styles [ `Bold; `Fg_red ]);
  [%expect {||}];
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
