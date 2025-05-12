(*_********************************************************************************)
(*_  pplumbing - Utility libraries to use with [pp]                               *)
(*_  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Build pretty printed documents with ansi colors. *)

(*_ The interface of this file was copied from [Stdune.Ansi_color] version
  [3.16.1].

  We added a [type t] definition and replace its definition by its name in the
  various functions that operate on it.

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
  SOFTWARE. *)

module RGB8 : sig
  (** 8 bit RGB color *)
  type t = Stdune.Ansi_color.RGB8.t

  (** [RGB8.to_int t] returns the [int] value of [t] as an 8 bit integer. *)
  val to_int : t -> int

  (** [RGB8.of_int i] creates an [RGB8.t] from an [int] considered as an 8 bit integer.
      The first 24 bits are discarded. *)
  val of_int : int -> t

  (** [RGB8.of_char c] creates an [RGB8.t] from a [char] considered as an 8 bit integer.
  *)
  val of_char : char -> t

  (** [RGB8.to_char t] returns the [char] value of [t] considered as an 8 bit integer. *)
  val to_char : t -> char
end

module RGB24 : sig
  (** 24 bit RGB color *)
  type t = Stdune.Ansi_color.RGB24.t

  (** [RGB24.red t] returns the red component of [t] *)
  val red : t -> int

  (** [RGB24.green t] returns the green component of [t] *)
  val green : t -> int

  (** [RGB24.blue t] returns the blue component of [t] *)
  val blue : t -> int

  (** [RGB24.make ~red ~green ~blue] creates an [RGB24.t] from the given components *)
  val make : red:int -> green:int -> blue:int -> t

  (** [RGB24.to_int t] returns the [int] value of [t] as a 24 bit integer. *)
  val to_int : t -> int

  (** [RGB24.of_int i] creates an [RGB24.t] from an [int] considered as a 24 bit integer.
      The first 8 bits are discarded. *)
  val of_int : int -> t
end

module Style : sig
  (** ANSI terminal styles *)
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
    | `Fg_8_bit_color of RGB8.t
    | `Fg_24_bit_color of RGB24.t
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
    | `Bg_8_bit_color of RGB8.t
    | `Bg_24_bit_color of RGB24.t
    | `Bold
    | `Dim
    | `Italic
    | `Underline
    ]

  val to_dyn : t -> Dyn.t
  val compare : t -> t -> Ordering.t

  (** Ansi escape sequence that set the terminal style to exactly these styles *)
  val escape_sequence : t list -> string
end

type t = Style.t list Pp.t

module Staged : sig
  type +'a t

  val unstage : 'a t -> 'a
end

val make_printer : bool Lazy.t -> Format.formatter -> (t -> unit) Staged.t

(** Print to [Format.std_formatter] *)
val print : t -> unit

(** Print to [Format.err_formatter] *)
val prerr : t -> unit

(** Whether [stdout]/[stderr] support colors *)
val stdout_supports_color : bool Lazy.t

val stderr_supports_color : bool Lazy.t
val output_is_a_tty : bool Lazy.t

(** Filter out escape sequences in a string *)
val strip : string -> string

(** Parse a string containing ANSI escape sequences *)
val parse : string -> t
