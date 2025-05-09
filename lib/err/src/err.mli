(** Err is an abstraction to report located errors and warnings to the user.

    The canonical syntax for an error produced by this lib is:

    {[
      File "my-file", line 42, character 6-11:
      42 | Hello World
                 ^^^^^
      Error: Some message that gives a general explanation of the issue.
      Followed by more details.
    ]}

    It is heavily inspired by dune's user_messages and uses dune's error message
    rendering under the hood. *)

(** A value of type [t] is an immutable piece of information that the programmer
    intends to report to the user, in a way that breaks flow. To give some
    concrete examples:

    - A message (or several) reporting an error condition in a program
    - A request to exit the program with an exit code. *)
type t

(** The exception that is raised to break the control flow of programs using
    [Err].

    Examples:

    {ul
     {- When reporting an error:
        {[
          if had_error then Err.raise [ Pp.text "An error occurred" ]
        ]}
     }
    }

    {ul
     {- When requesting an exit code:
        {[
          if shall_exit_42 then Err.exit 42
        ]}
     }
    }

    The standard usage for this library is to wrap entire sections in a
    {!val:protect}, which takes care of catching [E] and handling it
    accordingly. You may also catch this exception manually if you need, for
    more advanced uses (in which case you'll take care of recording and
    re-raising backtraces, etc). *)
exception E of t

(** Return a [Sexp] to inspect what inside [t]. Note the sexp is not meant for
    supporting any kind of round trip serialization (there is no [t_of_sexp]).
    Rather, this is for interoperability with other error handling mechanisms
    based on sexps. We think exposing this can help accommodating some use
    cases, making it easier to write expect tests involving [Err], etc.

    Note that the exit code contained in [t] is not shown by {!sexp_of_t}. See
    {!With_exit_code.sexp_of_t} if needed. *)
val sexp_of_t : t -> Sexplib0.Sexp.t

(** {1 Exit codes}

    This part allows breaking the control flow with an exception indicating a
    request to end the program with a given exit code. *)

module Exit_code : sig
  (** The handling of exit code is based on [Cmdliner] conventions. *)

  type t = int

  val ok : int
  val some_error : int
  val cli_error : int
  val internal_error : int
end

(** Request the termination of the program with the provided exit code. Make
    sure you have documented that particular exit code in the man page of your
    CLI. We recommend to stick to the error codes exposed by
    {!module:Exit_code}, which are documented by default and pervasively used
    by existing CLIs built with cmdliner. Raises {!exception:E}. *)
val exit : Exit_code.t -> _

module With_exit_code : sig
  type nonrec t = t

  (** Same as [sexp_of_t] but augmented with the requested exit code. *)
  val sexp_of_t : t -> Sexplib0.Sexp.t
end

(** {1 Raising errors} *)

(** Raise a user error. You may override [exit_code] with the requested exit
    code to end the program with. It defaults to {!val:Exit_code.some_error}.

    Example:
    {[
      let unknown_var var =
        Err.raise
          ~loc
          [ Pp.textf "Unknown variable '%s'" var ]
          ~hints:(Err.did_you_mean var ~candidates:[ "foo"; "bar"; "baz" ])
      ;;
    ]} *)
val raise
  :  ?loc:Loc.t
  -> ?hints:Pp_tty.t list
  -> ?exit_code:Exit_code.t
  -> Pp_tty.t list
  -> _

(** Create a err and return it, instead of raising it right away. *)
val create
  :  ?loc:Loc.t
  -> ?context:Pp_tty.t list
  -> ?hints:Pp_tty.t list
  -> ?exit_code:Exit_code.t
  -> Pp_tty.t list
  -> t

(** [sexp s] is the preferred way to embed some context of type [Sexp.t] into a
    [_ Pp.t] paragraph as part of a error. *)
val sexp : Sexplib0.Sexp.t -> _ Pp.t

(** [exn e] is the preferred way to embed an exception into a [_ Pp.t] paragraph
    as part of an error. *)
val exn : exn -> _ Pp.t

(** {1 Context} *)

(** [add_context t items] prepends the supplied items to the context of [t].
    This approach reflects the idea of a stack: new context items are added to
    the front, representing the most recent layer of context.

    When rendered in the console, context items are displayed before the main
    error paragraphs, with the most recently added context item appearing first.
    This mirrors the reverse navigation of the program's call stack, as context
    is typically added at the point where an error is caught and additional
    information is provided.

    This mechanism is useful for incrementally building a high-level "stack
    trace" of user-defined context, helping to clarify the sequence of events
    leading to the error. See also {!reraise_with_context}. *)
val add_context : t -> Pp_tty.t list -> t

(** Reraise with added context. See also {!add_context}. Usage:

    {[
      match do_x (Y.to_x y) with
      | exception Err.E e ->
        let bt = Printexc.get_raw_backtrace () in
        Err.reraise_with_context e bt [ Pp.text "Trying to do x with y"; Y.pp y ]
    ]} *)
val reraise_with_context : t -> Printexc.raw_backtrace -> Pp_tty.t list -> _

(** {1 Result} *)

(** Helper to raise a user error from a result type.
    - [ok_exn (Ok x)] is [x]
    - [ok_exn (Error msg)] is [Stdlib.raise (E msg)] *)
val ok_exn : ('a, t) result -> 'a

(** Build an error from an exception. This retrieves [e] if the exception is
    [Err.E e], otherwise this creates a new error using the sexp of the
    supplied exception. *)
val of_exn : exn -> t

(** {1 Hints} *)

(** Produces a "Did you mean ...?" hint *)
val did_you_mean : string -> candidates:string list -> Pp_tty.t list

(** {1 State Getters} *)

(** Set by the {!val:For_test.wrap} when wrapping sections for tests, accessed
    by libraries if needed. *)
val am_running_test : unit -> bool

(** This return the number of errors that have been emitted via [Err.error]
    since the last [reset_counts]. Beware, note that errors raised as
    exceptions via functions such as [Err.raise] do not affect the error
    count. The motivation is to allow exceptions to be caught without
    impacting the overall exit code. *)
val error_count : unit -> int

(** A convenient wrapper for [Err.error_count () > 0].

    This is useful if you are trying not to stop at the first error encountered,
    but still want to stop the execution at a specific breakpoint after some
    numbers of errors. To be used in places where you want to stop the flow at a
    given point rather than returning meaningless data. *)
val had_errors : unit -> bool

(** Return the number of warnings that have been emitted via [Err.warning] since
    the last [reset_counts]. *)
val warning_count : unit -> int

(** {2 Color mode}

    Inspired by the [git diff --color=<WHEN>] command line parameter, this
    library allows to access the rendering mode that should be used to style the
    output aimed for the user, in the terminal or perhaps using a pager.

    If you use [Log_cli.set_config], your cli will also support the same
    [--color] flag as [git diff]. You can access the value that was set via the
    {!color_mode} getter. The default mode is [`Auto].

    Even though it is traditionally called "color"-mode, this goes beyond simply
    colors and controls all forms of style rendering construct, such as bold,
    italic, and other ansi special characters. *)

module Color_mode : sig
  type t =
    [ `Auto
    | `Always
    | `Never
    ]

  val all : t list
  val to_string : t -> string
end

val color_mode : unit -> Color_mode.t

(** {2 Log Level}

    Inspired by logging conventions in many CLI tools, this library provides a
    mechanism to control the verbosity of log messages based on their severity
    level. This allows users to filter messages, ensuring that only relevant
    information is displayed during program execution.

    The log level can be set programmatically or via command-line flags using
    [Log_cli]. The default log level is [Warning], meaning only warnings and
    errors will be displayed unless a more verbose level is explicitly set.

    The available log levels are:

    - [Quiet]: Suppresses all log messages, including errors.
    - [Error]: Displays only error messages.
    - [Warning]: Displays warnings and errors (default).
    - [Info]: Displays informational messages, warnings, and errors.
    - [Debug]: Displays all messages, including debug information.

    Programs can query the current log level using {!log_level} and check
    whether a specific level is enabled using {!log_enables}. This is useful for
    conditionally executing code that should only run at certain verbosity
    levels.

    Example usage:

    {[
      if Err.log_enables Debug
      then (
        (* Perform expensive debugging operations *)
        let debug_data = compute_debug_data () in
        Err.debug (lazy [ Pp.textf "Debug data: %s" debug_data ]))
    ]}

    Note: Functions such as {!Err.info}, {!Err.warning}, and {!Err.debug}
    automatically check the log level before emitting messages. You do not need
    to call {!log_enables} before using them.

    When using [Log_cli], the log level can be set via a command-line flag
    (e.g., [--verbosity=debug]). This ensures consistent behavior across
    applications using this library.

    Note: A level named [App] has been added to ensure compatibility with the
    [Logs] library, as this constructor is part of [Logs.level]. However, this
    module does not differentiate between the [Quiet] and [App] levels. The
    [App] level is primarily included to facilitate interoperability with
    third-party libraries that rely on [Logs]. *)

module Log_level : sig
  type t =
    | Quiet
    | App
    | Error
    | Warning
    | Info
    | Debug

  val all : t list
  val compare : t -> t -> int
  val to_string : t -> string
end

(** Access the current log level. *)
val log_level : unit -> Log_level.t

(** Tell whether the current log level enables the output of messages of the
    supplied level. *)
val log_enables : Log_level.t -> bool

(** {1 Printing messages} *)

(** Print to [stderr] (not thread safe). By default, [prerr] will start by
    writing a blank line on [stderr] if [Err] messages have already been
    emitted during the lifetime of the program. That is a reasonable default
    to ensure that err messages are always nicely separated by an empty line,
    to make them more readable. However, if you structure your output
    manually, perhaps you do not want this. If [reset_separator=true], this
    behavior is turned off, and the first message of this batch will be
    printed directly without a leading blank line. *)
val prerr : ?reset_separator:bool -> t -> unit

(** [to_string_hum t] is shorthand to [Sexp.to_string_hum (sexp_of_t t)]. This
    may be used if you want to embed [t] as a string. Note you'll lose all
    colors and other style formatting. For pretty printing of errors to the
    console, see {!prerr}. *)
val to_string_hum : t -> string

(** {1 Non-raising user errors}

    This part of the library allows the production of messages that do not
    raise.

    For example: - Emitting multiple errors before terminating - Non fatal
    Warnings - Debug and Info messages

    Errors and warnings are going to affect [error_count] (and resp.
    [warning_count]), which is going to be used by {!val:protect} to impact the
    exit code of the application. Use with care. *)

(** Emit an error on stderr and increase the global error count. *)
val error : ?loc:Loc.t -> ?hints:Pp_tty.t list -> Pp_tty.t list -> unit

(** Emit a warning on stderr and increase the global warning count. *)
val warning : ?loc:Loc.t -> ?hints:Pp_tty.t list -> Pp_tty.t list -> unit

(** Emit a information message on stderr. Required verbosity level of [Info] or
    more, disabled by default. *)
val info : ?loc:Loc.t -> ?hints:Pp_tty.t list -> Pp_tty.t list -> unit

(** The last argument to [debug] is lazy in order to avoid the allocation when
    debug messages are disabled. This isn't done with the other functions,
    because we don't expect other logging functions to be used in a way that
    impacts the program's performance, and using lazy causes added programming
    friction. *)
val debug : ?loc:Loc.t -> ?hints:Pp_tty.t list -> Pp_tty.t list Lazy.t -> unit

(** {1 Handler}

    To be used by command line handlers, as well as tests. *)

(** [protect f] will take care of running [f], and catch any user error. If the
    exit code must be affected it is returned as an [Error]. This also takes
    care of catching uncaught exceptions and printing them to the screen. You
    may provide [exn_handler] to match on custom exceptions and turn them into
    [Err] for display and exit code. Any uncaught exception will be reported
    as an internal errors with a backtrace. When [Err.am_running_test ()] is
    true the backtrace is redacted to avoid making expect test traces too
    brittle. [protect] starts by performing a reset of the error and warning
    counts with a call to [reset_counts]. *)
val protect : ?exn_handler:(exn -> t option) -> (unit -> 'a) -> ('a, int) Result.t

module For_test : sig
  (** Same as [protect], but won't return the exit code, rather print the code
      at the end in case of a non zero code, like in cram tests. *)
  val protect : ?exn_handler:(exn -> t option) -> (unit -> unit) -> unit

  (** Wrap the execution of a function under an environment proper for test
      execution. For example, it will turn down the colors in user messages.
      {!val:For_test.protect} already does a [wrap] - this is exposed if you'd
      like to run some test outside of a [protect] handler. *)
  val wrap : (unit -> 'a) -> 'a
end

(** {1 Private} *)

module Private : sig
  (** [Private] is used by [Log_cli]. We mean both libraries to work as
      companion libs. Note any of this can change without notice and without
      requiring a semver bump, so use at your own risk (or don't). *)

  val am_running_test : bool ref
  val reset_counts : unit -> unit
  val reset_separator : unit -> unit
  val color_mode : Color_mode.t ref

  (** Since [Err] does not depend on [Logs], the [Err] and [Logs] levels must be
      set independently. However, this is done for you consistently if you are
      using [Log_cli]. *)
  val set_log_level : get:(unit -> Log_level.t) -> set:(Log_level.t -> unit) -> unit

  val warn_error : bool ref

  (** To avoid making this library depend on [Logs] we inject the dependency
      into the functions we need instead. To be called with [Logs.err_count]
      and [Logs.warn_count]. *)
  val set_log_counts : err_count:(unit -> int) -> warn_count:(unit -> int) -> unit
end

(** {1 Deprecated}

    This part of the API is, or will be soon, deprecated. We have added
    [ocamlmig] annotations to help with migrating existing code. *)

(** This is deprecated - use [Err.create] instead. *)
val create_s
  :  ?loc:Loc.t
  -> ?hints:Pp_tty.t list
  -> ?exit_code:Exit_code.t
  -> string
  -> Sexplib0.Sexp.t
  -> t
[@@migrate
  { repl =
      (fun ?loc ?hints ?exit_code msg sexp ->
        Rel.create
          ?loc
          ?hints
          ?exit_code
          [ (Pp.text msg [@commutes]); (Rel.sexp sexp [@commutes]) ])
  ; libraries = [ "pp" ]
  }]

(** This is deprecated - use [Err.raise] instead. *)
val raise_s
  :  ?loc:Loc.t
  -> ?hints:Pp_tty.t list
  -> ?exit_code:Exit_code.t
  -> string
  -> Sexplib0.Sexp.t
  -> _
[@@migrate
  { repl =
      (fun ?loc ?hints ?exit_code msg sexp ->
        Rel.raise
          ?loc
          ?hints
          ?exit_code
          [ (Pp.text msg [@commutes]); (Rel.sexp sexp [@commutes]) ])
  ; libraries = [ "pp" ]
  }]

(** This is deprecated - use [Err.reraise_with_context] instead. *)
val reraise_s
  :  Printexc.raw_backtrace
  -> t
  -> ?loc:Loc.t
  -> ?hints:Pp_tty.t list
  -> ?exit_code:Exit_code.t
  -> string
  -> Sexplib0.Sexp.t
  -> _
[@@migrate
  { repl =
      (fun bt e ?loc ?hints ?exit_code msg sexp ->
        Rel.reraise_with_context
          e
          bt
          [ (Pp.text msg [@commutes]); (Rel.sexp sexp [@commutes]) ])
  ; libraries = [ "pp" ]
  }]

(** This was renamed [Err.sexp]. *)
val pp_of_sexp : Sexplib0.Sexp.t -> _ Pp.t
[@@migrate { repl = Rel.sexp }]
