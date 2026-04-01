(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
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
       ; "Italic_Magenta", Ansi_styles [ `Italic; `Fg_magenta ]
       ; "Fg_8bit", Ansi_styles [ `Fg_8_bit_color (Pp_tty.Ansi_color.RGB8.of_int 42) ]
       ; ( "Fg_24bit"
         , Ansi_styles
             [ `Fg_24_bit_color (Pp_tty.Ansi_color.RGB24.make ~red:255 ~green:128 ~blue:0)
             ] )
       ; ( "Bold_White_on_Bg24bit"
         , Ansi_styles
             [ `Bold
             ; `Fg_white
             ; `Bg_24_bit_color (Pp_tty.Ansi_color.RGB24.make ~red:0 ~green:0 ~blue:128)
             ] )
       ; "Original_sexp", Original_sexp (List [ Atom "key"; Atom "value" ])
       ; "Original_dyn", Original_dyn (Dyn.String "hello")
       ]
     in
     let print_styled pp =
       let fmt = Format.std_formatter in
       (if Err.should_enable_color Unix.stdout
        then Pp_tty.pp fmt pp
        else Pp.to_fmt fmt pp);
       Format.pp_print_newline fmt ();
       Format.pp_print_flush fmt ()
     in
     List.iter styles ~f:(fun (name, style) ->
       print_styled (Pp_tty.tag style (Pp.verbatim name)));
     (* Nested tags: italic text containing an inner underline+red word,
        exercises the [with_reset:true] path with non-empty [current_styles]. *)
     print_styled
       (Pp_tty.tag
          (Pp_tty.Style.Ansi_styles [ `Italic ])
          Pp.O.(
            Pp.verbatim "Italic_"
            ++ Pp_tty.tag (Ansi_styles [ `Underline; `Fg_red ]) (Pp.verbatim "UnderRed")
            ++ Pp.verbatim "_Italic")))
;;

let sexp_and_dyn_cmd =
  Command.make
    ~summary:"Demonstrate error messages embedding sexp and dyn data."
    (let+ () = Log_cli.set_config () in
     let sexp_data : Sexp.t =
       List
         [ Atom "config"
         ; List [ Atom "timeout"; Atom "30" ]
         ; List [ Atom "retries"; Atom "3" ]
         ]
     in
     let dyn_data : Dyn.t =
       Record
         [ "name", String "widget"
         ; "count", Int 42
         ; "tags", List [ String "alpha"; String "beta" ]
         ]
     in
     Err.error [ Pp.text "Invalid configuration."; Err.sexp sexp_data ];
     Err.error [ Pp.text "Unexpected value."; Err.dyn dyn_data ];
     Err.error
       ~hints:[ Pp.text "Check the config file." ]
       [ Pp.text "Multiple embedded values."; Err.sexp sexp_data; Err.dyn dyn_data ])
;;

let emit_error_cmd =
  Command.make
    ~summary:"Emit a simple error message to stderr."
    (let+ () = Log_cli.set_config () in
     Err.error [ Pp.text "error message." ])
;;

let log_styled_cmd =
  Command.make
    ~summary:"Emit a styled log message."
    (let+ () = Log_cli.set_config () in
     Log.app (fun () ->
       [ Pp.concat
           ~sep:Pp.space
           [ Pp.text "Hello"
           ; Pp_tty.tag (Ansi_styles [ `Fg_blue ]) (Pp.verbatim "Colored")
           ; Pp.text "World!"
           ]
       ]))
;;

let main =
  Command.group
    ~summary:"Test pplumbing libs from the command line."
    [ "emit-error", emit_error_cmd
    ; "log-styled", log_styled_cmd
    ; "logs", logs_cmd
    ; "print-styles", print_styles_cmd
    ; "sexp-and-dyn", sexp_and_dyn_cmd
    ; "write", write_cmd
    ]
;;
