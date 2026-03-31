(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* {1 Tests for RGB8} *)

let%expect_test "RGB8 roundtrip via int" =
  for i = 0 to 255 do
    let c = Pp_tty.Ansi_color.RGB8.of_int i in
    require (Pp_tty.Ansi_color.RGB8.to_int c = i)
  done;
  [%expect {||}];
  ()
;;

let%expect_test "RGB8 roundtrip via char" =
  for i = 0 to 255 do
    let ch = Char.chr i in
    let c = Pp_tty.Ansi_color.RGB8.of_char ch in
    require (Pp_tty.Ansi_color.RGB8.to_char c = ch)
  done;
  [%expect {||}];
  ()
;;

let%expect_test "RGB8 of_int discards upper bits" =
  let c = Pp_tty.Ansi_color.RGB8.of_int 0x1FF in
  print_int (Pp_tty.Ansi_color.RGB8.to_int c);
  [%expect {| 255 |}];
  ()
;;

(* {1 Tests for RGB24} *)

let%expect_test "RGB24 make and accessors" =
  let c = Pp_tty.Ansi_color.RGB24.make ~red:10 ~green:20 ~blue:30 in
  Printf.printf
    "red=%d green=%d blue=%d"
    (Pp_tty.Ansi_color.RGB24.red c)
    (Pp_tty.Ansi_color.RGB24.green c)
    (Pp_tty.Ansi_color.RGB24.blue c);
  [%expect {| red=10 green=20 blue=30 |}];
  ()
;;

let%expect_test "RGB24 roundtrip via int" =
  let i = (128 lsl 16) lor (64 lsl 8) lor 32 in
  let c = Pp_tty.Ansi_color.RGB24.of_int i in
  require (Pp_tty.Ansi_color.RGB24.to_int c = i);
  Printf.printf
    "red=%d green=%d blue=%d"
    (Pp_tty.Ansi_color.RGB24.red c)
    (Pp_tty.Ansi_color.RGB24.green c)
    (Pp_tty.Ansi_color.RGB24.blue c);
  [%expect {| red=128 green=64 blue=32 |}];
  ()
;;

(* {1 Tests for Style} *)

let%expect_test "Style.escape_sequence" =
  let s = Pp_tty.Ansi_color.Style.escape_sequence [ `Bold; `Fg_red ] in
  (* The escape sequence should start with ESC[ and end with m. *)
  require (String.length s > 0);
  (* Stripping should produce an empty string since it's only escape codes. *)
  print_string (Pp_tty.Ansi_color.strip s);
  [%expect {||}];
  ()
;;

let%expect_test "Style.to_dyn" =
  let test style = print_endline (Dyn.to_string (Pp_tty.Ansi_color.Style.to_dyn style)) in
  test `Bold;
  [%expect {| Bold |}];
  test `Fg_red;
  [%expect {| Fg_red |}];
  test `Underline;
  [%expect {| Underline |}];
  ()
;;

let%expect_test "Style.compare" =
  require (Ordering.is_eq (Pp_tty.Ansi_color.Style.compare `Bold `Bold));
  require (not (Ordering.is_eq (Pp_tty.Ansi_color.Style.compare `Bold `Italic)));
  [%expect {||}];
  ()
;;

(* {1 Tests for strip and parse} *)

let%expect_test "strip - plain string" =
  print_string (Pp_tty.Ansi_color.strip "hello world");
  [%expect {| hello world |}];
  ()
;;

let%expect_test "strip - with escape sequences" =
  let styled =
    Pp_tty.Ansi_color.Style.escape_sequence [ `Fg_red ]
    ^ "red text"
    ^ Pp_tty.Ansi_color.Style.escape_sequence []
  in
  print_string (Pp_tty.Ansi_color.strip styled);
  [%expect {| red text |}];
  ()
;;

let%expect_test "parse - plain string" =
  let pp = Pp_tty.Ansi_color.parse "plain text" in
  Pp_tty.Ansi_color.print pp;
  [%expect {| plain text |}];
  ()
;;

let%expect_test "parse then strip roundtrip" =
  let styled =
    Pp_tty.Ansi_color.Style.escape_sequence [ `Bold ]
    ^ "bold"
    ^ Pp_tty.Ansi_color.Style.escape_sequence []
    ^ " normal"
  in
  let stripped = Pp_tty.Ansi_color.strip styled in
  print_string stripped;
  [%expect {| bold normal |}];
  ()
;;

(* {1 Tests for print and prerr} *)

let%expect_test "print" =
  Pp_tty.Ansi_color.print (Pp.verbatim "ansi to stdout");
  [%expect {| ansi to stdout |}];
  ()
;;

let%expect_test "prerr" =
  Pp_tty.Ansi_color.prerr (Pp.verbatim "ansi to stderr");
  [%expect {| ansi to stderr |}];
  ()
;;
