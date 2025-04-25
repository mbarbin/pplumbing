(** [Log_cli] contains functions to work with [Err] on the side of end
    programs (such as a command line tool, as opposed to libraries).

    It defines a command line parser to configure the [Err] library, while
    taking take of setting the [Logs] and [Fmt] style rendering. *)

(** {1 Configuration} *)

module Color_mode : sig
  include module type of struct
    include Err.Color_mode
  end
end

module Log_level : sig
  include module type of struct
    include Err.Log_level
  end

  val of_logs_level : Logs.level option -> t
  val to_logs_level : t -> Logs.level option
end

module Config : sig
  type t

  val create
    :  ?log_level:Log_level.t
    -> ?color_mode:Color_mode.t
    -> ?warn_error:bool
    -> unit
    -> t

  (** {1 Getters} *)

  val log_level : t -> Log_level.t
  val color_mode : t -> Color_mode.t
  val warn_error : t -> bool

  (** {1 Arg builders} *)

  val log_level_arg : Log_level.t Command.Arg.t
  val color_mode_arg : Color_mode.t Command.Arg.t
  val arg : t Command.Arg.t
  val to_args : t -> string list

  (** {1 Deprecated API}

      The following getters are meant to be marked for deprecation in
      a future version. *)

  val logs_level : t -> Logs.level option
  val fmt_style_renderer : t -> Fmt.style_renderer option
end

(** Perform global side effects to modules such as [Err], [Logs] & [Fmt] to
    configure how to do error rendering in the terminal, set log levels, etc. If
    you wish to do this automatically from the arguments parsed in a command
    line, see also {!val:set_config}. *)
val setup_config : config:Config.t -> unit

(** Adding this argument to your command line will make it support [Err]
    configuration and takes care of setting the global configuration with
    specification coming from the command line. This is designed to work well
    with project using [Err], [Logs] and [Fmt].

    {[
      let open Command.Std in
      let+ () = Log_cli.set_config () in ...
    ]} *)
val set_config : unit -> unit Command.Arg.t
