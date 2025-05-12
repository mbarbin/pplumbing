(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let%expect_test "sexp_of_t" =
  List.iter Err.Log_level.all ~f:(fun log_level ->
    print_s [%sexp (log_level : Err.Log_level.t)]);
  [%expect
    {|
    Quiet
    App
    Error
    Warning
    Info
    Debug
    |}];
  ()
;;

let%expect_test "to_string" =
  List.iter Err.Log_level.all ~f:(fun log_level ->
    print_endline (Err.Log_level.to_string log_level));
  [%expect
    {|
    quiet
    app
    error
    warning
    info
    debug
    |}];
  ()
;;

let%expect_test "compare" =
  List.iter Err.Log_level.all ~f:(fun log_level ->
    require [%here] (Err.Log_level.equal log_level log_level);
    require [%here] (0 = Err.Log_level.compare log_level log_level));
  require [%here] (not (Err.Log_level.equal Error Warning));
  require [%here] (Err.Log_level.compare Error Warning < 0);
  require [%here] (Err.Log_level.compare Debug Error > 0);
  [%expect {||}];
  ()
;;

let%expect_test "log levels" =
  Err.Private.reset_counts ();
  Err.For_test.wrap
  @@ fun () ->
  let test level =
    Err.For_test.protect (fun () ->
      Logs.set_level level;
      Err.error [ Pp.text "Hello Error1" ];
      Err.warning [ Pp.text "Hello Warning1" ];
      Err.info [ Pp.text "Hello Info1" ];
      Err.debug (lazy [ Pp.text "Hello Debug1" ]))
  in
  (* [Logs.set_level] on its own is not sufficient to impact the [Err] library.
     You must either set both levels consistently, or use
     [Log_cli.setup_config]. *)
  test (Some Warning);
  [%expect
    {|
    Error: Hello Error1

    Warning: Hello Warning1
    [123]
    |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| true |}];
  test (Some Info);
  [%expect
    {|
    Error: Hello Error1

    Warning: Hello Warning1
    [123]
    |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| true |}];
  test (Some Debug);
  [%expect
    {|
    Error: Hello Error1

    Warning: Hello Warning1
    [123]
    |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| true |}];
  (* In this section we set both levels consistently ourselves. *)
  Err.Private.set_log_level
    ~get:(fun () ->
      match Logs.level () with
      | None -> Quiet
      | Some App -> App
      | Some Error -> Error
      | Some Warning -> Warning
      | Some Info -> Info
      | Some Debug -> Debug)
    ~set:(fun level ->
      (Logs.set_level
         (match level with
          | Quiet -> None
          | App -> Some App
          | Error -> Some Error
          | Warning -> Some Warning
          | Info -> Some Info
          | Debug -> Some Debug) [@coverage off]));
  test None;
  [%expect {||}];
  (* Note how disabling the errors causes [had_errors] to return [false]. *)
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| false |}];
  test (Some App);
  [%expect {| |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| false |}];
  test (Some Error);
  [%expect
    {|
    Error: Hello Error1
    [123]
    |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| true |}];
  test (Some Warning);
  [%expect
    {|
    Error: Hello Error1

    Warning: Hello Warning1
    [123]
    |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| true |}];
  test (Some Info);
  [%expect
    {|
    Error: Hello Error1

    Warning: Hello Warning1

    Info: Hello Info1
    [123]
    |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| true |}];
  test (Some Debug);
  [%expect
    {|
    Error: Hello Error1

    Warning: Hello Warning1

    Info: Hello Info1

    Debug: Hello Debug1
    [123]
    |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| true |}];
  (* In this section we go through [Log_cli]. *)
  let test level =
    Err.For_test.protect (fun () ->
      Log_cli.setup_config ~config:(Log_cli.Config.create ~log_level:level ());
      Err.error [ Pp.text "Hello Error1" ];
      Err.warning [ Pp.text "Hello Warning1" ];
      Err.info [ Pp.text "Hello Info1" ];
      Err.debug (lazy [ Pp.text "Hello Debug1" ]))
  in
  test Quiet;
  [%expect {||}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| false |}];
  test App;
  [%expect {| |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| false |}];
  test Error;
  [%expect
    {|
    Error: Hello Error1
    [123]
    |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| true |}];
  test Warning;
  [%expect
    {|
    Error: Hello Error1

    Warning: Hello Warning1
    [123]
    |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| true |}];
  test Info;
  [%expect
    {|
    Error: Hello Error1

    Warning: Hello Warning1

    Info: Hello Info1
    [123]
    |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| true |}];
  test Debug;
  [%expect
    {|
    Error: Hello Error1

    Warning: Hello Warning1

    Info: Hello Info1

    Debug: Hello Debug1
    [123]
    |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| true |}];
  ()
;;

let%expect_test "error when quiet" =
  (* When the logs level is set to [quiet] errors are not shown, and not
     accounted for in the [error_count] and [had_errors]. *)
  Err.For_test.protect (fun () ->
    let set_log_level log_level =
      Log_cli.setup_config ~config:(Log_cli.Config.create ~log_level ())
    in
    set_log_level Quiet;
    Err.error [ Pp.text "Hello Exn1" ]);
  [%expect {||}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| false |}];
  ()
;;

let%expect_test "raise when quiet" =
  (* When the logs level is set to [quiet], raising errors will be non impacted
     and behaves as usual. *)
  Err.For_test.protect (fun () ->
    let set_log_level log_level =
      Log_cli.setup_config ~config:(Log_cli.Config.create ~log_level ())
    in
    set_log_level Quiet;
    Err.raise [ Pp.text "Hello Exn1" ]);
  [%expect
    {|
    Error: Hello Exn1
    [123]
    |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| false |}];
  ()
;;
