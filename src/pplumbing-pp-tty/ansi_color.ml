(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

include Stdune.Ansi_color

type t = Style.t list Pp.t

(* The implementation for the Style handling was vendored from
   [Stdune.Ansi_color] version [3.16.1].

   See dune's LICENSE below:

   ----------------------------------------------------------------------------

   The MIT License

   Copyright (c) 2016 Jane Street Group, LLC <opensource@janestreet.com>

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.

   ----------------------------------------------------------------------------

   We vendored the code to be able to expose a simple [pp] function without the
   [Staged]/[make_printer] indirection.

   The tag_handler needs access to [Style.write_to_buffer] and helper functions
   that are not exposed by stdune's public interface. We reproduce the minimal
   set needed here.

   List of changes:

   - Split the styles between simple and non RGB styles.
*)

module Simple_style = struct
  type t =
    [ `Fg_default
    | `Fg_black
    | `Fg_red
    | `Fg_green
    | `Fg_yellow
    | `Fg_blue
    | `Fg_magenta
    | `Fg_cyan
    | `Fg_white
    | `Fg_bright_black
    | `Fg_bright_red
    | `Fg_bright_green
    | `Fg_bright_yellow
    | `Fg_bright_blue
    | `Fg_bright_magenta
    | `Fg_bright_cyan
    | `Fg_bright_white
    | `Bg_default
    | `Bg_black
    | `Bg_red
    | `Bg_green
    | `Bg_yellow
    | `Bg_blue
    | `Bg_magenta
    | `Bg_cyan
    | `Bg_white
    | `Bg_bright_black
    | `Bg_bright_red
    | `Bg_bright_green
    | `Bg_bright_yellow
    | `Bg_bright_blue
    | `Bg_bright_magenta
    | `Bg_bright_cyan
    | `Bg_bright_white
    | `Bold
    | `Dim
    | `Italic
    | `Underline
    ]

  let code t =
    match[@coverage off] (t : t) with
    | `Fg_default -> 39
    | `Fg_black -> 30
    | `Fg_red -> 31
    | `Fg_green -> 32
    | `Fg_yellow -> 33
    | `Fg_blue -> 34
    | `Fg_magenta -> 35
    | `Fg_cyan -> 36
    | `Fg_white -> 37
    | `Fg_bright_black -> 90
    | `Fg_bright_red -> 91
    | `Fg_bright_green -> 92
    | `Fg_bright_yellow -> 93
    | `Fg_bright_blue -> 94
    | `Fg_bright_magenta -> 95
    | `Fg_bright_cyan -> 96
    | `Fg_bright_white -> 97
    | `Bg_default -> 49
    | `Bg_black -> 40
    | `Bg_red -> 41
    | `Bg_green -> 42
    | `Bg_yellow -> 43
    | `Bg_blue -> 44
    | `Bg_magenta -> 45
    | `Bg_cyan -> 46
    | `Bg_white -> 47
    | `Bg_bright_black -> 100
    | `Bg_bright_red -> 101
    | `Bg_bright_green -> 102
    | `Bg_bright_yellow -> 103
    | `Bg_bright_blue -> 104
    | `Bg_bright_magenta -> 105
    | `Bg_bright_cyan -> 106
    | `Bg_bright_white -> 107
    | `Bold -> 1
    | `Dim -> 2
    | `Italic -> 3
    | `Underline -> 4
  ;;
end

module Vendor_style = struct
  let write_to_buffer buf style =
    match[@coverage off] (style : Style.t) with
    | #Simple_style.t as style ->
      Buffer.add_string buf (Int.to_string (Simple_style.code style))
    | `Fg_8_bit_color c ->
      Buffer.add_string buf "38;5;";
      Buffer.add_string buf (Int.to_string (RGB8.to_int c))
    | `Fg_24_bit_color rgb ->
      Buffer.add_string buf "38;2;";
      Buffer.add_string buf (Int.to_string (RGB24.red rgb));
      Buffer.add_char buf ';';
      Buffer.add_string buf (Int.to_string (RGB24.green rgb));
      Buffer.add_char buf ';';
      Buffer.add_string buf (Int.to_string (RGB24.blue rgb))
    | `Bg_8_bit_color c ->
      Buffer.add_string buf "48;5;";
      Buffer.add_string buf (Int.to_string (RGB8.to_int c))
    | `Bg_24_bit_color rgb ->
      Buffer.add_string buf "48;2;";
      Buffer.add_string buf (Int.to_string (RGB24.red rgb));
      Buffer.add_char buf ';';
      Buffer.add_string buf (Int.to_string (RGB24.green rgb));
      Buffer.add_char buf ';';
      Buffer.add_string buf (Int.to_string (RGB24.blue rgb))
  ;;

  let rec write_codes buf = function
    | [] -> ()
    | [ t ] -> write_to_buffer buf t
    | t :: ts ->
      write_to_buffer buf t;
      Buffer.add_char buf ';';
      write_codes buf ts
  ;;
end

let escape_sequence ~with_reset buf l =
  Buffer.add_string buf "\027[";
  if with_reset
  then (
    match l with
    | [] -> Buffer.add_char buf '0'
    | _ :: _ -> Buffer.add_string buf "0;");
  Vendor_style.write_codes buf l;
  Buffer.add_char buf 'm';
  let res = Buffer.contents buf in
  Buffer.clear buf;
  res
;;

let rec tag_handler buf current_styles ppf (styles : Style.t list) pp =
  Format.pp_print_as ppf 0 (escape_sequence ~with_reset:false buf styles);
  Pp.to_fmt_with_tags ppf pp ~tag_handler:(tag_handler buf (current_styles @ styles));
  Format.pp_print_as ppf 0 (escape_sequence ~with_reset:true buf current_styles)
;;

let pp fmt t =
  let buf = Buffer.create 16 in
  Pp.to_fmt_with_tags fmt t ~tag_handler:(tag_handler buf [])
;;

let to_string t = Format.asprintf "%a" (fun fmt t -> pp fmt t) t
