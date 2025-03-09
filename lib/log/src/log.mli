(** An interface to [Logs] using [Pp_tty].

    This module can be used in places where you'd use functions from [Logs] when
    you wish to build your formatted document with [Pp_tty] rather than with
    [Format].

    For example:

    {[
      let hello ?src () =
        Log.info ?src (fun () -> [ Pp.textf "Hello %s World!" "Friendly" ])
      ;;
    ]}

    Styles may be injected in the document using [Pp_tty]. For example:

    {[
      let hello ?src () =
        Log.info ?src (fun () ->
          [ Pp.concat
              ~sep:Pp.space
              [ Pp.text "Hello"
              ; Pp_tty.tag (Ansi_styles [ `Fg_blue ]) (Pp.verbatim "Colored")
              ; Pp.text "World!"
              ]
          ])
      ;;
    ]} *)

(** {1 Logs types aliases} *)

type level = Logs.level
type src = Logs.src

(** {1 Logging functions} *)

(** {2 Log interface}

    We've looked through sherlocode to get some sense of how the [Logs]
    interface is used. In the most common cases, the function [m] is applied
    directly without [header] nor [tags]. When the headers or tags are used,
    they are usually constant values for headers, and for tags, either a constant
    or a function from unit to tags, applied in the body of [m].

    Based on this remarks and on the fact that we don't need a format string
    anymore, we've proposed an interface where the [m] auxiliary function is
    removed.

    We this interface, the previous example can be written as:

    {[
      let hello ?src ?header ?tags () =
        Log.info ?src ?header ?tags (fun () ->
          [ Pp.concat
              ~sep:Pp.space
              [ Pp.text "Hello"
              ; Pp_tty.tag (Ansi_styles [ `Fg_blue ]) (Pp.verbatim "Colored")
              ; Pp.text "World!"
              ]
          ])
      ;;
    ]} *)

type log =
  ?header:string -> ?tags:(unit -> Logs.Tag.set) -> (unit -> Pp_tty.t list) -> unit

val msg : ?src:src -> level -> log
val app : ?src:src -> log
val err : ?src:src -> log
val warn : ?src:src -> log
val info : ?src:src -> log
val debug : ?src:src -> log

(** {2 Logs Interface} *)

module Logs : sig
  (** Interface in the style of [Logs].

      These call the functions of the same name from [Logs]. They are direct
      translation, where the only difference is that the format is a pp value
      instead.

      For example, the following [Logs] style logging:

      {[
        let hello ?src () = Logs.info ?src (fun m -> m "Hello %s!" "World")
      ]}

      Can be written with [Log.Logs] as:

      {[
        let hello ?src () =
          Log.Logs.info ?src (fun m -> m [ Pp.textf "Hello %s!" "World" ])
        ;;
      ]} *)

  type msgf = ?header:string -> ?tags:Logs.Tag.set -> Pp_tty.t list -> unit
  type log = (msgf -> unit) -> unit

  val msg : ?src:src -> level -> log
  val app : ?src:src -> log
  val err : ?src:src -> log
  val warn : ?src:src -> log
  val info : ?src:src -> log
  val debug : ?src:src -> log
end
