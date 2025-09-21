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
  [@@deriving equal, sexp_of]
end

module Log_level = struct
  type t = Log_cli.Log_level.t =
    | Quiet
    | App
    | Error
    | Warning
    | Info
    | Debug
  [@@deriving equal, sexp_of]
end

module Color_mode = struct
  type t =
    [ `Always
    | `Auto
    | `Never
    ]
  [@@deriving equal, sexp_of]
end

module Fmt_style_renderer = struct
  type t =
    [ `Ansi_tty
    | `None
    ]
  [@@deriving equal, sexp_of]
end

module Config_with_sexp = struct
  module Internal = struct
    type t =
      { log_level : Log_level.t
      ; logs_level : Logs_level.t option
      ; color_mode : Color_mode.t
      ; fmt_style_renderer : Fmt_style_renderer.t option
      ; warn_error : bool
      }
    [@@deriving equal, sexp_of]
  end

  type t = Log_cli.Config.t

  let to_internal t =
    { Internal.log_level = Log_cli.Config.log_level t
    ; logs_level = Log_cli.Config.logs_level t
    ; color_mode = Log_cli.Config.color_mode t
    ; fmt_style_renderer = Log_cli.Config.fmt_style_renderer t
    ; warn_error = Log_cli.Config.warn_error t
    }
  ;;

  let equal t1 t2 = Internal.equal (to_internal t1) (to_internal t2)
  let sexp_of_t (t : t) = [%sexp (to_internal t : Internal.t)]
end

let roundtrip_test original_config =
  let args = Log_cli.Config.to_args original_config in
  let term =
    let open Cmdliner.Term.Syntax in
    let+ config = Cmdlang_to_cmdliner.Translate.arg Log_cli.Config.arg in
    Log_cli.setup_config ~config;
    if Config_with_sexp.equal original_config config
    then print_s [%sexp { args : string list; config : Config_with_sexp.t }]
    else
      print_s
        [%sexp
          "Roundtrip Failed"
        , { args : string list
          ; original_config : Config_with_sexp.t
          ; config : Config_with_sexp.t
          }] [@coverage off]
  in
  let cmd = Cmdliner.Cmd.v (Cmdliner.Cmd.info "err_cli") term in
  match Cmdliner.Cmd.eval cmd ~argv:(Array.of_list ("err_cli" :: args)) with
  | 0 -> ()
  | exit_code -> print_s [%sexp "Evaluation Failed", { exit_code : int }] [@coverage off]
  | exception e -> print_s [%sexp "Evaluation Raised", (e : Exn.t)] [@coverage off]
;;

let%expect_test "roundtrip" =
  roundtrip_test (Log_cli.Config.create ());
  [%expect
    {|
    ((args ())
     (config (
       (log_level Warning)
       (logs_level (Warning))
       (color_mode Auto)
       (fmt_style_renderer ())
       (warn_error false))))
    |}];
  roundtrip_test (Log_cli.Config.create ~log_level:Quiet ());
  [%expect
    {|
    ((args (--quiet))
     (config (
       (log_level Quiet)
       (logs_level ())
       (color_mode Auto)
       (fmt_style_renderer ())
       (warn_error false))))
    |}];
  roundtrip_test (Log_cli.Config.create ~log_level:App ());
  [%expect
    {|
    ((args (--verbosity app))
     (config (
       (log_level App)
       (logs_level (App))
       (color_mode Auto)
       (fmt_style_renderer ())
       (warn_error false))))
    |}];
  roundtrip_test (Log_cli.Config.create ~log_level:Error ());
  [%expect
    {|
    ((args (--verbosity error))
     (config (
       (log_level Error)
       (logs_level (Error))
       (color_mode Auto)
       (fmt_style_renderer ())
       (warn_error false))))
    |}];
  roundtrip_test (Log_cli.Config.create ~log_level:Warning ());
  [%expect
    {|
    ((args ())
     (config (
       (log_level Warning)
       (logs_level (Warning))
       (color_mode Auto)
       (fmt_style_renderer ())
       (warn_error false))))
    |}];
  roundtrip_test (Log_cli.Config.create ~log_level:Info ());
  [%expect
    {|
    ((args (--verbosity info))
     (config (
       (log_level Info)
       (logs_level (Info))
       (color_mode Auto)
       (fmt_style_renderer ())
       (warn_error false))))
    |}];
  roundtrip_test (Log_cli.Config.create ~log_level:Debug ());
  [%expect
    {|
    ((args (--verbosity debug))
     (config (
       (log_level Debug)
       (logs_level (Debug))
       (color_mode Auto)
       (fmt_style_renderer ())
       (warn_error false))))
    |}];
  roundtrip_test (Log_cli.Config.create ~color_mode:`Auto ());
  [%expect
    {|
    ((args ())
     (config (
       (log_level Warning)
       (logs_level (Warning))
       (color_mode Auto)
       (fmt_style_renderer ())
       (warn_error false))))
    |}];
  roundtrip_test (Log_cli.Config.create ~color_mode:`Always ());
  [%expect
    {|
    ((args (--color always))
     (config (
       (log_level Warning)
       (logs_level (Warning))
       (color_mode Always)
       (fmt_style_renderer (Ansi_tty))
       (warn_error false))))
    |}];
  roundtrip_test (Log_cli.Config.create ~color_mode:`Never ());
  [%expect
    {|
    ((args (--color never))
     (config (
       (log_level Warning)
       (logs_level (Warning))
       (color_mode Never)
       (fmt_style_renderer (None))
       (warn_error false))))
    |}];
  roundtrip_test (Log_cli.Config.create ~warn_error:true ());
  [%expect
    {|
    ((args (--warn-error))
     (config (
       (log_level Warning)
       (logs_level (Warning))
       (color_mode Auto)
       (fmt_style_renderer ())
       (warn_error true))))
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
    print_s [%sexp { args : string list; config : Config_with_sexp.t }]
  in
  let cmd = Cmdliner.Cmd.v (Cmdliner.Cmd.info "err_cli") term in
  match Cmdliner.Cmd.eval cmd ~argv:(Array.of_list ("err_cli" :: args)) with
  | 0 -> ()
  | exit_code -> print_s [%sexp "Evaluation Failed", { exit_code : int }] [@coverage off]
  | exception e -> print_s [%sexp "Evaluation Raised", (e : Exn.t)] [@coverage off]
;;

let%expect_test "parse verbose count" =
  parse [];
  [%expect
    {|
    ((args ())
     (config (
       (log_level Warning)
       (logs_level (Warning))
       (color_mode Auto)
       (fmt_style_renderer ())
       (warn_error false))))
    |}];
  parse [ "-v" ];
  [%expect
    {|
    ((args (-v))
     (config (
       (log_level Info)
       (logs_level (Info))
       (color_mode Auto)
       (fmt_style_renderer ())
       (warn_error false))))
    |}];
  parse [ "-v"; "-v" ];
  [%expect
    {|
    ((args (-v -v))
     (config (
       (log_level Debug)
       (logs_level (Debug))
       (color_mode Auto)
       (fmt_style_renderer ())
       (warn_error false))))
    |}];
  parse [ "-v"; "-v"; "-v" ];
  [%expect
    {|
    ((args (-v -v -v))
     (config (
       (log_level Debug)
       (logs_level (Debug))
       (color_mode Auto)
       (fmt_style_renderer ())
       (warn_error false))))
    |}];
  ()
;;
