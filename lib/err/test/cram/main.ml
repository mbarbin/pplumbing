(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

open Command.Std

let logs_cmd =
  Command.make
    ~summary:"use the logs library"
    (let+ () = Log_cli.set_config () in
     Logs.app (fun m -> m "Hello app");
     Logs.err (fun m -> m "Hello err");
     Logs.warn (fun m -> m "Hello warn");
     Logs.info (fun m -> m "Hello info");
     Logs.debug (fun m -> m "Hello debug");
     Err.exit (if Logs.err_count () > 0 then 1 else 0))
;;

let write_cmd =
  Command.make
    ~summary:"write to an error-log"
    (let+ () = Log_cli.set_config ()
     and+ file = Arg.named [ "file" ] Param.string ~docv:"FILE" ~doc:"file"
     and+ line = Arg.named [ "line" ] Param.int ~docv:"N" ~doc:"line number"
     and+ pos_cnum =
       Arg.named [ "pos-cnum" ] Param.int ~docv:"N" ~doc:"character position"
     and+ pos_bol = Arg.named [ "pos-bol" ] Param.int ~docv:"N" ~doc:"beginning of line"
     and+ length = Arg.named [ "length" ] Param.int ~docv:"N" ~doc:"length of range"
     and+ level =
       Arg.named_with_default
         [ "level" ]
         (Param.enumerated (module Err.Level))
         ~default:Error
         ~docv:"LEVEL"
         ~doc:"The level of the message to emit."
     and+ raise = Arg.flag [ "raise" ] ~doc:"raise an exception" in
     let loc =
       let p = { Lexing.pos_fname = file; pos_lnum = line; pos_cnum; pos_bol } in
       Loc.create (p, { p with pos_cnum = pos_cnum + length })
     in
     if raise then failwith "Raising an exception!";
     let msg = Err.create ~loc [ Pp.textf "%s message" (Err.Level.to_string level) ] in
     Err.emit msg ~level)
;;

let main =
  Command.group
    ~summary:"test err from the command line"
    [ "logs", logs_cmd; "write", write_cmd ]
;;

let () = Cmdlang_cmdliner_runner.run main ~name:"main" ~version:"%%VERSION%%"
