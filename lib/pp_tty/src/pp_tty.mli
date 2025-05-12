(*_********************************************************************************)
(*_  pplumbing - Utility libraries to use with [pp]                               *)
(*_  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Build pretty printed documents for the user. *)

module Ansi_color = Ansi_color

(*_ The interface of this file was inspired by [Stdune.User_message] version
  [3.16.1].

  We extracted the part about symbolic styles to make it the default tag
  parameter for the main type [Pp_tty].

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

(** Symbolic styles that can be used inside messages. These styles are later
    converted to actual concrete styles depending on the output device. For
    instance, when printed to the terminal they are converted to ansi terminal
    styles ([Ansi_color.Style.t list] values). *)
module Style : sig
  type t = Stdune.User_message.Style.t =
    | Loc
    | Error
    | Warning
    | Kwd
    | Id
    | Prompt
    | Hint
    | Details
    | Ok
    | Debug
    | Success
    | Ansi_styles of Ansi_color.Style.t list

  val to_dyn : t -> Dyn.t
  val compare : t -> t -> Ordering.t
end

(** Styled document that can be printed to the console or in the log file. *)
type t = Style.t Pp.t

module Print_config : sig
  (** Associate ANSI terminal styles to symbolic styles *)
  type t = Style.t -> Ansi_color.Style.t list

  (** The default configuration *)
  val default : t
end

(** Print to [stdout] (not thread safe) *)
val print : ?config:Print_config.t -> t -> unit

(** Print to [stderr] (not thread safe) *)
val prerr : ?config:Print_config.t -> t -> unit

(*_ End of the section derived from [Stdune.User_message].

  ---------------------------------------------------------------------------- *)

(** An alias for [Pp.tag] dedicated to the expected [Style.t] type. Using this
    function allows to write the [Style.t] constructor without qualifying them,
    which may be more ergonomic. *)
val tag : Style.t -> t -> t

(** {1 Basic helpers} *)

val parens : 'a Pp.t -> 'a Pp.t
val brackets : 'a Pp.t -> 'a Pp.t
val braces : 'a Pp.t -> 'a Pp.t
val simple_quotes : 'a Pp.t -> 'a Pp.t
val double_quotes : 'a Pp.t -> 'a Pp.t

(** {1 Opinionated helpers} *)

(** A pretty printer for code locations. The uses a common syntax that is
    usually configured by editors to allow jumping to locations. If the file
    listed by the location is available, this will render a small quotation
    for the location, such as in:

    {[
      File "my-file", line 42, character 6-11:
      42 | Hello World
                 ^^^^^
    ]} *)
val loc : Loc.t -> t

module type To_string = sig
  type t

  val to_string : t -> string
end

(** A modular-explicit helper that uses {!brackets} and the [Id] symbolic style
    to format a stringable identifier. *)
val id : (module To_string with type t = 'a) -> 'a -> t

(** A modular-explicit helper that uses {!brackets} and the [Kwd] symbolic style
    to format a stringable keyword. *)
val kwd : (module To_string with type t = 'a) -> 'a -> t

(** A modular-explicit helper that uses {!double_quotes} and the [Bold]
    ansi style to format a stringable path. *)
val path : (module To_string with type t = 'a) -> 'a -> t

(** A modular-explicit helper that uses the ansi style to format a stringable
    variable. *)
val ansi : (module To_string with type t = 'a) -> 'a -> Ansi_color.Style.t list -> t
