(*_********************************************************************************)
(*_  pplumbing - Utility libraries to use with [pp]                               *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Color mode type and detection logic.

    This is a [Private] module of [Pp_tty]. Its interface may change in breaking
    ways at any time without prior notice, and outside of the guidelines set by
    semver. *)

type t =
  [ `Auto
  | `Always
  | `Never
  ]

val variant_constructor_name : t -> string
val all : t list
val compare : t -> t -> int
val equal : t -> t -> bool
val to_string : t -> string

(** The current color mode setting. Set by [Err.Private.color_mode] (via
    [Log_cli.set_config]) to reflect the [--color] flag. Defaults to [`Auto]. *)
val value : t Atomic.t

(** Return the effective color mode, taking into account the user setting and
    environment variables.

    When the user setting is [`Auto], this partially resolves it using
    environment variables:

    - [CLICOLOR_FORCE] set to a non-["0"] value forces [`Always].
    - [TERM] equal to ["dumb"] or [CLICOLOR] equal to ["0"] forces [`Never].
    - Otherwise, [`Auto] is returned (the caller still needs to check whether
      the output is a TTY).

    When the user setting is [`Always] or [`Never], it is returned as-is. *)
val color_mode : unit -> t

(** Resolve whether color output should be enabled for the given file
    descriptor.

    This combines {!color_mode} with a [Unix.isatty] check on [fd]:

    - [`Always] returns [true].
    - [`Never] returns [false].
    - [`Auto] returns [Unix.isatty fd]. *)
val should_enable_color : Unix.file_descr -> bool
