(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* We set up a custom [Logs] reporter that prints the header and the rendered
   body to stdout, so we can capture the output with [%expect]. *)

let test_reporter () =
  { Logs.report =
      (fun _src level ~over k msgf ->
        let k _ =
          over ();
          k ()
        in
        msgf (fun ?header ?tags:_ fmt ->
          ignore (header : string option);
          let level_str =
            match (level : Logs.level) with
            | App -> "APP"
            | Error -> "ERROR"
            | Warning -> "WARNING"
            | Info -> "INFO"
            | Debug -> "DEBUG"
          in
          Format.kfprintf k Format.std_formatter ("[%s] " ^^ fmt ^^ "\n") level_str))
  }
;;

let with_test_reporter f =
  let saved_reporter = Logs.reporter () in
  let saved_level = Logs.level () in
  Logs.set_reporter (test_reporter ());
  Logs.set_level (Some Debug);
  Fun.protect f ~finally:(fun () ->
    Logs.set_reporter saved_reporter;
    Logs.set_level saved_level)
;;

(* {1 Tests for rendering through the logging interface} *)

let%expect_test "single text" =
  with_test_reporter (fun () -> Log.info (fun () -> [ Pp.text "Hello World" ]));
  [%expect {| [INFO] Hello World |}];
  ()
;;

let%expect_test "multiple paragraphs" =
  with_test_reporter (fun () ->
    Log.info (fun () -> [ Pp.text "First line"; Pp.text "Second line" ]));
  [%expect
    {|
    [INFO] First line
           Second line
    |}];
  ()
;;

let%expect_test "empty list" =
  with_test_reporter (fun () -> Log.info (fun () -> []));
  [%expect {| [INFO] |}];
  ()
;;

let%expect_test "textf with formatting" =
  with_test_reporter (fun () ->
    Log.info (fun () -> [ Pp.textf "Hello %s, you have %d messages" "Alice" 42 ]));
  [%expect {| [INFO] Hello Alice, you have 42 messages |}];
  ()
;;

let%expect_test "concat with separator" =
  with_test_reporter (fun () ->
    Log.info (fun () ->
      [ Pp.concat
          ~sep:Pp.space
          [ Pp.verbatim "one"; Pp.verbatim "two"; Pp.verbatim "three" ]
      ]));
  [%expect {| [INFO] one two three |}];
  ()
;;

(* {1 Tests for the simple log interface} *)

let%expect_test "msg" =
  with_test_reporter (fun () -> Log.msg Logs.Info (fun () -> [ Pp.text "via msg" ]));
  [%expect {| [INFO] via msg |}];
  ()
;;

let%expect_test "app" =
  with_test_reporter (fun () -> Log.app (fun () -> [ Pp.text "application message" ]));
  [%expect {| [APP] application message |}];
  ()
;;

let%expect_test "err" =
  with_test_reporter (fun () -> Log.err (fun () -> [ Pp.text "error message" ]));
  [%expect {| [ERROR] error message |}];
  ()
;;

let%expect_test "warn" =
  with_test_reporter (fun () -> Log.warn (fun () -> [ Pp.text "warning message" ]));
  [%expect {| [WARNING] warning message |}];
  ()
;;

let%expect_test "info" =
  with_test_reporter (fun () -> Log.info (fun () -> [ Pp.text "info message" ]));
  [%expect {| [INFO] info message |}];
  ()
;;

let%expect_test "debug" =
  with_test_reporter (fun () -> Log.debug (fun () -> [ Pp.text "debug message" ]));
  [%expect {| [DEBUG] debug message |}];
  ()
;;

(* {1 Tests for the Logs-style interface} *)

let%expect_test "Logs.msg" =
  with_test_reporter (fun () ->
    Log.Logs.msg Logs.Warning (fun m -> m [ Pp.text "via Logs.msg" ]));
  [%expect {| [WARNING] via Logs.msg |}];
  ()
;;

let%expect_test "Logs.app" =
  with_test_reporter (fun () ->
    Log.Logs.app (fun m -> m [ Pp.text "application message" ]));
  [%expect {| [APP] application message |}];
  ()
;;

let%expect_test "Logs.err" =
  with_test_reporter (fun () -> Log.Logs.err (fun m -> m [ Pp.text "error message" ]));
  [%expect {| [ERROR] error message |}];
  ()
;;

let%expect_test "Logs.warn" =
  with_test_reporter (fun () -> Log.Logs.warn (fun m -> m [ Pp.text "warning message" ]));
  [%expect {| [WARNING] warning message |}];
  ()
;;

let%expect_test "Logs.info" =
  with_test_reporter (fun () -> Log.Logs.info (fun m -> m [ Pp.text "info message" ]));
  [%expect {| [INFO] info message |}];
  ()
;;

let%expect_test "Logs.debug" =
  with_test_reporter (fun () -> Log.Logs.debug (fun m -> m [ Pp.text "debug message" ]));
  [%expect {| [DEBUG] debug message |}];
  ()
;;

(* {1 Tests for level filtering} *)

let%expect_test "level filtering" =
  let saved_reporter = Logs.reporter () in
  let saved_level = Logs.level () in
  Logs.set_reporter (test_reporter ());
  Fun.protect
    (fun () ->
       (* At Warning level, Info and Debug should be filtered out. *)
       Logs.set_level (Some Warning);
       Log.err (fun () -> [ Pp.text "shown" ]);
       Log.warn (fun () -> [ Pp.text "shown" ]);
       Log.info (fun () -> (assert false [@coverage off]));
       Log.debug (fun () -> (assert false [@coverage off])))
    ~finally:(fun () ->
      Logs.set_reporter saved_reporter;
      Logs.set_level saved_level);
  [%expect
    {|
    [ERROR] shown
    [WARNING] shown
    |}];
  ()
;;

(* {1 Tests with tags} *)

let test_tag : string Logs.Tag.def =
  Logs.Tag.def "test-tag" ~doc:"a test tag" Format.pp_print_string
;;

let tags_reporter () =
  { Logs.report =
      (fun _src level ~over k msgf ->
        let k _ =
          over ();
          k ()
        in
        msgf (fun ?header ?tags fmt ->
          ignore (header : string option);
          let level_str =
            match (level : Logs.level) with
            | Info -> "INFO"
            | _ -> assert false [@coverage off]
          in
          let tag_str =
            match tags with
            | None -> "<no-tags>"
            | Some tags ->
              (match Logs.Tag.find test_tag tags with
               | None -> assert false [@coverage off]
               | Some v -> v)
          in
          Format.kfprintf
            k
            Format.std_formatter
            ("[%s] [%s] " ^^ fmt ^^ "\n")
            level_str
            tag_str))
  }
;;

let with_tags_reporter f =
  let saved_reporter = Logs.reporter () in
  let saved_level = Logs.level () in
  Logs.set_reporter (tags_reporter ());
  Logs.set_level (Some Debug);
  Fun.protect f ~finally:(fun () ->
    Logs.set_reporter saved_reporter;
    Logs.set_level saved_level)
;;

let%expect_test "msg with tags" =
  with_tags_reporter (fun () ->
    Log.info
      ~tags:(fun () -> Logs.Tag.(empty |> add test_tag "my-value"))
      (fun () -> [ Pp.text "tagged message" ]));
  [%expect {| [INFO] [my-value] tagged message |}];
  ()
;;

let%expect_test "msg without tags" =
  with_tags_reporter (fun () -> Log.info (fun () -> [ Pp.text "untagged message" ]));
  [%expect {| [INFO] [<no-tags>] untagged message |}];
  ()
;;

let%expect_test "Logs.msg with tags" =
  with_tags_reporter (fun () ->
    Log.Logs.info (fun m ->
      m ~tags:Logs.Tag.(empty |> add test_tag "logs-style") [ Pp.text "tagged" ]));
  [%expect {| [INFO] [logs-style] tagged |}];
  ()
;;

(* {1 Tests with a custom source} *)

let%expect_test "msg with src" =
  with_test_reporter (fun () ->
    let src = Logs.Src.create "test.src" in
    Logs.Src.set_level src (Some Debug);
    Log.info ~src (fun () -> [ Pp.text "from custom source" ]));
  [%expect {| [INFO] from custom source |}];
  ()
;;
