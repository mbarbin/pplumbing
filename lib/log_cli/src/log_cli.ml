(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Color_mode = struct
  include Err.Color_mode

  let to_fmt_style_renderer = function
    | `Auto -> None
    | `Always -> Some `Ansi_tty
    | `Never -> Some `None
  ;;
end

module Log_level = struct
  include Err.Log_level

  let of_logs_level : Logs.level option -> t = function
    | None -> Quiet
    | Some App -> App
    | Some Error -> Error
    | Some Warning -> Warning
    | Some Info -> Info
    | Some Debug -> Debug
  ;;

  let to_logs_level : t -> Logs.level option = function
    | Quiet -> None
    | App -> Some App
    | Error -> Some Error
    | Warning -> Some Warning
    | Info -> Some Info
    | Debug -> Some Debug
  ;;
end

module Config = struct
  let log_level_arg =
    let open Command.Std in
    let+ verbose_count =
      Arg.flag_count
        [ "verbose"; "v" ]
        ~doc:"Increase verbosity. Repeatable, but more than twice does not bring more."
    and+ verbosity =
      Arg.named_opt
        [ "log-level"; "verbosity" ]
        (Param.enumerated (module Log_level))
        ~docv:"LEVEL"
        ~doc:"Be more or less verbose. Takes over $(b,v)."
    and+ quiet =
      Arg.flag [ "quiet"; "q" ] ~doc:"Be quiet. Takes over $(b,v) and $(b,--verbosity)."
    in
    if quiet
    then Log_level.Quiet
    else (
      match verbosity with
      | Some verbosity -> verbosity
      | None ->
        (match verbose_count with
         | 0 -> Log_level.Warning
         | 1 -> Log_level.Info
         | _ -> Log_level.Debug))
  ;;

  let color_mode_arg =
    let open Command.Std in
    Arg.named_with_default
      [ "color" ]
      (Param.enumerated (module Color_mode))
      ~default:`Auto
      ~docv:"WHEN"
      ~doc:"Colorize the output."
  ;;

  type t =
    { log_level : Log_level.t
    ; color_mode : Color_mode.t
    ; warn_error : bool
    }

  let default = { log_level = Log_level.Warning; color_mode = `Auto; warn_error = false }

  let create
        ?(log_level = default.log_level)
        ?(color_mode = default.color_mode)
        ?(warn_error = default.warn_error)
        ()
    =
    { log_level; color_mode; warn_error }
  ;;

  let log_level t = t.log_level
  let logs_level t = Log_level.to_logs_level t.log_level
  let color_mode t = t.color_mode
  let fmt_style_renderer t = Color_mode.to_fmt_style_renderer t.color_mode
  let warn_error t = t.warn_error

  let arg =
    let open Command.Std in
    let+ warn_error = Arg.flag [ "warn-error" ] ~doc:"Treat warnings as errors."
    and+ log_level = log_level_arg
    and+ color_mode = color_mode_arg in
    { log_level; color_mode; warn_error }
  ;;

  let to_args { log_level; color_mode; warn_error } =
    List.concat
      [ (match Log_level.to_logs_level log_level with
         | None -> [ "--quiet" ]
         | Some level ->
           (match level with
            | App -> [ "--verbosity"; "app" ]
            | Error -> [ "--verbosity"; "error" ]
            | Warning -> []
            | Info -> [ "--verbosity"; "info" ]
            | Debug -> [ "--verbosity"; "debug" ]))
      ; (match color_mode with
         | `Auto -> []
         | `Always -> [ "--color"; "always" ]
         | `Never -> [ "--color"; "never" ])
      ; (if warn_error then [ "--warn-error" ] else [])
      ]
  ;;
end

let setup_log ~(config : Config.t) =
  Fmt_tty.setup_std_outputs
    ?style_renderer:(Color_mode.to_fmt_style_renderer config.color_mode)
    ();
  let () = Err.Private.color_mode := config.color_mode in
  Logs.set_level (Log_level.to_logs_level config.log_level);
  let () =
    Err.Private.set_log_level
      ~get:(fun () -> Log_level.of_logs_level (Logs.level ()))
      ~set:(fun level -> (Logs.set_level (Log_level.to_logs_level level) [@coverage off]))
  in
  Logs.set_reporter (Logs_fmt.reporter ())
;;

let setup_config ~config =
  setup_log ~config;
  Err.Private.warn_error := config.warn_error;
  Err.Private.set_log_counts ~err_count:Logs.err_count ~warn_count:Logs.warn_count;
  ()
;;

let set_config () =
  let open Command.Std in
  let+ config = Config.arg in
  setup_config ~config
;;
