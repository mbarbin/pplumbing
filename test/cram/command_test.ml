(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

open Command.Std

let logs_cmd =
  Command.make
    ~summary:"Use the logs library."
    (let+ () = Log_cli.set_config ()
     and+ no_error = Arg.flag [ "no-error" ] ~doc:"Do not produce an error." in
     Logs.app (fun m -> m "Hello app");
     if not no_error then Logs.err (fun m -> m "Hello err");
     Logs.warn (fun m -> m "Hello warn");
     Logs.info (fun m -> m "Hello info");
     Logs.debug (fun m -> m "Hello debug");
     Err.exit (if Logs.err_count () > 0 then 1 else 0))
;;

let write_cmd =
  Command.make
    ~summary:"Write to an error-log."
    (let+ () = Log_cli.set_config ()
     and+ file = Arg.named [ "file" ] Param.string ~docv:"FILE" ~doc:"File."
     and+ line = Arg.named [ "line" ] Param.int ~docv:"N" ~doc:"Line number."
     and+ pos_cnum =
       Arg.named [ "pos-cnum" ] Param.int ~docv:"N" ~doc:"Character position."
     and+ pos_bol = Arg.named [ "pos-bol" ] Param.int ~docv:"N" ~doc:"Beginning of line."
     and+ length = Arg.named [ "length" ] Param.int ~docv:"N" ~doc:"Length of range."
     and+ level =
       Arg.named_with_default
         [ "level" ]
         (Param.enumerated (module Err.Level))
         ~default:Error
         ~docv:"LEVEL"
         ~doc:"The level of the message to emit."
     and+ uncaught_exception =
       Arg.flag [ "uncaught-exception" ] ~doc:"Raise an uncaught exception."
     and+ err_raise = Arg.flag [ "err-raise" ] ~doc:"Raise an error with [Err.raise]." in
     let loc =
       let p = { Lexing.pos_fname = file; pos_lnum = line; pos_cnum; pos_bol } in
       Loc.create (p, { p with pos_cnum = pos_cnum + length })
     in
     if uncaught_exception then failwith "Raising an exception!";
     if err_raise
     then
       Err.raise ~loc [ Pp.text "Hello [Err.raise]!" ] [@coverage off]
       (* Out-edge bisect_ppx issue. *);
     let msg = Err.create ~loc [ Pp.textf "%s message." (Err.Level.to_string level) ] in
     Err.emit msg ~level)
;;

let print_styles_cmd =
  Command.make
    ~summary:"Print each Pp_tty.Style with a sample text."
    (let+ () = Log_cli.set_config () in
     let styles =
       [ "Loc", Pp_tty.Style.Loc
       ; "Error", Error
       ; "Warning", Warning
       ; "Kwd", Kwd
       ; "Id", Id
       ; "Prompt", Prompt
       ; "Hint", Hint
       ; "Details", Details
       ; "Ok", Ok
       ; "Debug", Debug
       ; "Success", Success
       ; "Ansi_styles", Ansi_styles [ `Bold; `Fg_red ]
       ]
     in
     let print_styled pp =
       (match Err.color_mode () with
        | `Never -> Format.printf "%a%!" Pp.to_fmt pp
        | `Auto -> Pp_tty.print pp [@coverage off]
        | `Always -> print_string (Pp_tty.to_string pp));
       print_char '\n'
     in
     List.iter styles ~f:(fun (name, style) ->
       print_styled (Pp_tty.tag style (Pp.verbatim name))))
;;

let emit_error_cmd =
  Command.make
    ~summary:"Emit a simple error message to stderr."
    (let+ () = Log_cli.set_config () in
     Err.error [ Pp.text "error message." ])
;;

let main =
  Command.group
    ~summary:"Test pplumbing libs from the command line."
    [ "emit-error", emit_error_cmd
    ; "logs", logs_cmd
    ; "print-styles", print_styles_cmd
    ; "write", write_cmd
    ]
;;
