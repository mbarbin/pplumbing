(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Logs_level = struct
  type t = Logs.level =
    | App
    | Error
    | Warning
    | Info
    | Debug

  let equal : t -> t -> bool = Stdlib.( = )

  let to_dyn = function
    | App -> Dyn.variant "App" []
    | Error -> Dyn.variant "Error" []
    | Warning -> Dyn.variant "Warning" []
    | Info -> Dyn.variant "Info" []
    | Debug -> Dyn.variant "Debug" []
  ;;
end

module Log_level = struct
  type t = Log_cli.Log_level.t =
    | Quiet
    | App
    | Error
    | Warning
    | Info
    | Debug

  let equal = Log_cli.Log_level.equal

  let to_dyn = function
    | Quiet -> Dyn.variant "Quiet" []
    | App -> Dyn.variant "App" []
    | Error -> Dyn.variant "Error" []
    | Warning -> Dyn.variant "Warning" []
    | Info -> Dyn.variant "Info" []
    | Debug -> Dyn.variant "Debug" []
  ;;
end

module Color_mode = struct
  type t =
    [ `Always
    | `Auto
    | `Never
    ]

  let equal : t -> t -> bool = Stdlib.( = )

  let to_dyn = function
    | `Always -> Dyn.variant "Always" []
    | `Auto -> Dyn.variant "Auto" []
    | `Never -> Dyn.variant "Never" []
  ;;
end

module Fmt_style_renderer = struct
  type t =
    [ `Ansi_tty
    | `None
    ]

  let equal : t -> t -> bool = Stdlib.( = )

  let to_dyn = function
    | `Ansi_tty -> Dyn.variant "Ansi_tty" []
    | `None -> Dyn.variant "None" []
  ;;
end

module Config = struct
  module Internal = struct
    type t =
      { log_level : Log_level.t
      ; logs_level : Logs_level.t option
      ; color_mode : Color_mode.t
      ; fmt_style_renderer : Fmt_style_renderer.t option
      ; warn_error : bool
      }

    let to_dyn { log_level; logs_level; color_mode; fmt_style_renderer; warn_error } =
      Dyn.record
        [ "log_level", log_level |> Log_level.to_dyn
        ; "logs_level", logs_level |> Dyn.option Logs_level.to_dyn
        ; "color_mode", color_mode |> Color_mode.to_dyn
        ; "fmt_style_renderer", fmt_style_renderer |> Dyn.option Fmt_style_renderer.to_dyn
        ; "warn_error", warn_error |> Dyn.bool
        ]
    ;;

    let equal { log_level; logs_level; color_mode; fmt_style_renderer; warn_error } b =
      Log_level.equal log_level b.log_level
      && Option.equal Logs_level.equal logs_level b.logs_level
      && Color_mode.equal color_mode b.color_mode
      && Option.equal Fmt_style_renderer.equal fmt_style_renderer b.fmt_style_renderer
      && Bool.equal warn_error b.warn_error
    ;;
  end

  type t = Log_cli.Config.t

  let to_internal (t : t) : Internal.t =
    { log_level = Log_cli.Config.log_level t
    ; logs_level = Log_cli.Config.logs_level t
    ; color_mode = Log_cli.Config.color_mode t
    ; fmt_style_renderer = Log_cli.Config.fmt_style_renderer t
    ; warn_error = Log_cli.Config.warn_error t
    }
  ;;

  let to_dyn t = t |> to_internal |> Internal.to_dyn
  let equal t1 t2 = Internal.equal (to_internal t1) (to_internal t2)
end

let print_config ~args ~config =
  print_dyn
    (Dyn.record
       [ "args", args |> Dyn.list Dyn.string; "config", config |> Config.to_dyn ])
;;

let roundtrip_test original_config =
  let args = Log_cli.Config.to_args original_config in
  let term =
    let open Cmdliner.Term.Syntax in
    let+ config = Cmdlang_to_cmdliner.Translate.arg Log_cli.Config.arg in
    Log_cli.setup_config ~config;
    if Config.equal original_config config
    then print_config ~args ~config
    else
      print_dyn
        (Dyn.record
           [ "Roundtrip Failed", Dyn.string ""
           ; "args", args |> Dyn.list Dyn.string
           ; "original_config", original_config |> Config.to_dyn
           ; "config", config |> Config.to_dyn
           ]) [@coverage off]
  in
  let cmd = Cmdliner.Cmd.v (Cmdliner.Cmd.info "err_cli") term in
  match Cmdliner.Cmd.eval cmd ~argv:(Array.of_list ("err_cli" :: args)) with
  | 0 -> ()
  | exit_code ->
    print_dyn (Dyn.variant "Evaluation Failed" [ Dyn.int exit_code ]) [@coverage off]
  | exception e ->
    print_dyn
      (Dyn.variant "Evaluation Raised" [ Dyn.string (Stdlib.Printexc.to_string e) ])
    [@coverage off]
;;

let%expect_test "roundtrip" =
  roundtrip_test (Log_cli.Config.create ());
  [%expect
    {|
    { args = []
    ; config =
        { log_level = Warning
        ; logs_level = Some Warning
        ; color_mode = Auto
        ; fmt_style_renderer = None
        ; warn_error = false
        }
    }
    |}];
  roundtrip_test (Log_cli.Config.create ~log_level:Quiet ());
  [%expect
    {|
    { args = [ "--quiet" ]
    ; config =
        { log_level = Quiet
        ; logs_level = None
        ; color_mode = Auto
        ; fmt_style_renderer = None
        ; warn_error = false
        }
    }
    |}];
  roundtrip_test (Log_cli.Config.create ~log_level:App ());
  [%expect
    {|
    { args = [ "--verbosity"; "app" ]
    ; config =
        { log_level = App
        ; logs_level = Some App
        ; color_mode = Auto
        ; fmt_style_renderer = None
        ; warn_error = false
        }
    }
    |}];
  roundtrip_test (Log_cli.Config.create ~log_level:Error ());
  [%expect
    {|
    { args = [ "--verbosity"; "error" ]
    ; config =
        { log_level = Error
        ; logs_level = Some Error
        ; color_mode = Auto
        ; fmt_style_renderer = None
        ; warn_error = false
        }
    }
    |}];
  roundtrip_test (Log_cli.Config.create ~log_level:Warning ());
  [%expect
    {|
    { args = []
    ; config =
        { log_level = Warning
        ; logs_level = Some Warning
        ; color_mode = Auto
        ; fmt_style_renderer = None
        ; warn_error = false
        }
    }
    |}];
  roundtrip_test (Log_cli.Config.create ~log_level:Info ());
  [%expect
    {|
    { args = [ "--verbosity"; "info" ]
    ; config =
        { log_level = Info
        ; logs_level = Some Info
        ; color_mode = Auto
        ; fmt_style_renderer = None
        ; warn_error = false
        }
    }
    |}];
  roundtrip_test (Log_cli.Config.create ~log_level:Debug ());
  [%expect
    {|
    { args = [ "--verbosity"; "debug" ]
    ; config =
        { log_level = Debug
        ; logs_level = Some Debug
        ; color_mode = Auto
        ; fmt_style_renderer = None
        ; warn_error = false
        }
    }
    |}];
  roundtrip_test (Log_cli.Config.create ~color_mode:`Auto ());
  [%expect
    {|
    { args = []
    ; config =
        { log_level = Warning
        ; logs_level = Some Warning
        ; color_mode = Auto
        ; fmt_style_renderer = None
        ; warn_error = false
        }
    }
    |}];
  roundtrip_test (Log_cli.Config.create ~color_mode:`Always ());
  [%expect
    {|
    { args = [ "--color"; "always" ]
    ; config =
        { log_level = Warning
        ; logs_level = Some Warning
        ; color_mode = Always
        ; fmt_style_renderer = Some Ansi_tty
        ; warn_error = false
        }
    }
    |}];
  roundtrip_test (Log_cli.Config.create ~color_mode:`Never ());
  [%expect
    {|
    { args = [ "--color"; "never" ]
    ; config =
        { log_level = Warning
        ; logs_level = Some Warning
        ; color_mode = Never
        ; fmt_style_renderer = Some None
        ; warn_error = false
        }
    }
    |}];
  roundtrip_test (Log_cli.Config.create ~warn_error:true ());
  [%expect
    {|
    { args = [ "--warn-error" ]
    ; config =
        { log_level = Warning
        ; logs_level = Some Warning
        ; color_mode = Auto
        ; fmt_style_renderer = None
        ; warn_error = true
        }
    }
    |}];
  ()
;;

(* In addition to testing roundtrip, we also check the parsing of certain
   arguments that do not necessarily roundtrip (such as when there's another
   ways of expressing a certain config). *)
let parse args =
  let term =
    let open Cmdliner.Term.Syntax in
    let+ config = Cmdlang_to_cmdliner.Translate.arg Log_cli.Config.arg in
    Log_cli.setup_config ~config;
    print_config ~args ~config
  in
  let cmd = Cmdliner.Cmd.v (Cmdliner.Cmd.info "err_cli") term in
  match Cmdliner.Cmd.eval cmd ~argv:(Array.of_list ("err_cli" :: args)) with
  | 0 -> ()
  | exit_code ->
    print_dyn (Dyn.variant "Evaluation Failed" [ Dyn.int exit_code ]) [@coverage off]
  | exception e ->
    print_dyn
      (Dyn.variant "Evaluation Raised" [ Dyn.string (Stdlib.Printexc.to_string e) ])
    [@coverage off]
;;

let%expect_test "parse verbose count" =
  parse [];
  [%expect
    {|
    { args = []
    ; config =
        { log_level = Warning
        ; logs_level = Some Warning
        ; color_mode = Auto
        ; fmt_style_renderer = None
        ; warn_error = false
        }
    }
    |}];
  parse [ "-v" ];
  [%expect
    {|
    { args = [ "-v" ]
    ; config =
        { log_level = Info
        ; logs_level = Some Info
        ; color_mode = Auto
        ; fmt_style_renderer = None
        ; warn_error = false
        }
    }
    |}];
  parse [ "-v"; "-v" ];
  [%expect
    {|
    { args = [ "-v"; "-v" ]
    ; config =
        { log_level = Debug
        ; logs_level = Some Debug
        ; color_mode = Auto
        ; fmt_style_renderer = None
        ; warn_error = false
        }
    }
    |}];
  parse [ "-v"; "-v"; "-v" ];
  [%expect
    {|
    { args = [ "-v"; "-v"; "-v" ]
    ; config =
        { log_level = Debug
        ; logs_level = Some Debug
        ; color_mode = Auto
        ; fmt_style_renderer = None
        ; warn_error = false
        }
    }
    |}];
  ()
;;
