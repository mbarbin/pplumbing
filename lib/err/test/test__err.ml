(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let%expect_test "return" =
  Err.For_test.protect (fun () -> ());
  [%expect {||}];
  ()
;;

let%expect_test "am_running_test" =
  let am_running_test () = print_s [%sexp (Err.am_running_test () : bool)] in
  am_running_test ();
  [%expect {| false |}];
  Err.For_test.wrap (fun () ->
    am_running_test ();
    [%expect {| true |}]);
  Err.For_test.protect (fun () ->
    am_running_test ();
    [%expect {| true |}]);
  ()
;;

let%expect_test "raise" =
  Err.For_test.protect (fun () ->
    Err.raise
      ~loc:(Loc.of_file ~path:(Fpath.v "path/to/my-file.txt"))
      ~hints:(Err.did_you_mean "bah" ~candidates:[ "bar"; "foo" ])
      [ Pp.text "Hello Raise" ]);
  [%expect
    {|
    File "path/to/my-file.txt", line 1, characters 0-0:
    Error: Hello Raise
    Hint: did you mean bar?
    [123]
    |}];
  ()
;;

let%expect_test "of_exn" =
  let e = Err.create [ Pp.text "Hello of_exn" ] in
  let e' = Err.of_exn (Err.E e) in
  require [%here] (phys_equal e e');
  [%expect {||}];
  let e =
    try failwith "Hello Exn!" with
    | e -> Err.of_exn e
  in
  print_s [%sexp (e : Err.t)];
  [%expect {| (Failure "Hello Exn!") |}];
  ()
;;

let%expect_test "exit" =
  Err.For_test.protect (fun () -> Err.exit 0);
  [%expect {||}];
  Err.For_test.protect (fun () -> Err.exit Err.Exit_code.some_error);
  [%expect {| [123] |}];
  ()
;;

let%expect_test "reraise" =
  Err.For_test.protect (fun () ->
    match
      Err.raise
        ~loc:(Loc.of_file ~path:(Fpath.v "path/to/my-file.txt"))
        ~hints:(Err.did_you_mean "bah" ~candidates:[ "bar"; "foo" ])
        [ Pp.text "Hello Raise" ]
    with
    | _ -> assert false
    | exception Err.E e ->
      let bt = Stdlib.Printexc.get_raw_backtrace () in
      Err.reraise_with_context e bt [ Pp.text "Re raised with context"; Pp.verbatim "x" ]);
  [%expect
    {|
    File "path/to/my-file.txt", line 1, characters 0-0:
    Context: Re raised with context
    x
    Error: Hello Raise
    Hint: did you mean bar?
    [123]
    |}];
  ()
;;

let%expect_test "create" =
  let err =
    Err.create
      ~loc:(Loc.of_file ~path:(Fpath.v "path/to/my-file.txt"))
      ~hints:(Err.did_you_mean "bah" ~candidates:[ "bar"; "foo" ])
      [ Pp.text "Hello Make" ]
  in
  Err.For_test.protect (fun () -> raise (Err.E err));
  [%expect
    {|
    File "path/to/my-file.txt", line 1, characters 0-0:
    Error: Hello Make
    Hint: did you mean bar?
    [123]
    |}];
  ()
;;

let%expect_test "sexp_of_t" =
  let err =
    Err.create
      ~loc:(Loc.of_file ~path:(Fpath.v "path/to/my-file.txt"))
      ~hints:(Err.did_you_mean "bah" ~candidates:[ "bar"; "foo" ])
      [ Pp.text "Hello Sexp"; Err.sexp [%sexp { a = Hello; b = 42 }] ]
  in
  print_s [%sexp (err : Err.t)];
  [%expect
    {|
    ("Hello Sexp"
      ((a Hello)
       (b 42))
      (hints "did you mean bar?"))
    |}];
  print_endline (Err.to_string_hum err);
  [%expect {| ("Hello Sexp" ((a Hello) (b 42)) (hints "did you mean bar?")) |}];
  ()
;;

let%expect_test "add_context" =
  let err1 =
    Err.create
      ~loc:(Loc.of_file ~path:(Fpath.v "path/to/my-file-1.txt"))
      ~exit_code:41
      [ Pp.text "Hello Error 1" ]
  in
  let err2 = Err.add_context err1 [ Pp.text "Hello Context 1" ] in
  Err.For_test.protect (fun () -> raise (Err.E err2));
  [%expect
    {|
    File "path/to/my-file-1.txt", line 1, characters 0-0:
    Context: Hello Context 1
    Error: Hello Error 1
    [41]
    |}];
  let err3 =
    Err.add_context err2 [ Pp.text "Hello Context 2"; Err.sexp [%sexp Hello Sexp] ]
  in
  Err.For_test.protect (fun () -> raise (Err.E err3));
  [%expect
    {|
    File "path/to/my-file-1.txt", line 1, characters 0-0:
    Context: Hello Context 2
    (Hello Sexp)
    Hello Context 1
    Error: Hello Error 1
    [41]
    |}];
  ()
;;

let%expect_test "ok_exn" =
  let err =
    Err.create
      ~loc:(Loc.of_file ~path:(Fpath.v "path/to/my-file.txt"))
      ~hints:(Err.did_you_mean "bah" ~candidates:[ "bar"; "foo" ])
      [ Pp.text "Hello Make" ]
  in
  Err.For_test.protect (fun () -> Err.ok_exn (Ok ()));
  [%expect {||}];
  Err.For_test.protect (fun () -> Err.ok_exn (Error err));
  [%expect
    {|
    File "path/to/my-file.txt", line 1, characters 0-0:
    Error: Hello Make
    Hint: did you mean bar?
    [123]
    |}];
  ()
;;

let%expect_test "create_s" =
  let err =
    Err.create
      ~loc:(Loc.of_file ~path:(Fpath.v "path/to/my-file.txt"))
      ~hints:(Err.did_you_mean "bah" ~candidates:[ "bar"; "foo" ])
      [ Pp.text "The summary of the error."
      ; Err.sexp [%sexp { x = 42; y = Some "msg"; var = "bah" }]
      ]
  in
  Err.For_test.protect (fun () -> raise (Err.E err));
  [%expect
    {|
    File "path/to/my-file.txt", line 1, characters 0-0:
    Error: The summary of the error.
    ((x 42) (y (Some msg)) (var bah))
    Hint: did you mean bar?
    [123]
    |}];
  ()
;;

let%expect_test "raise with sexp" =
  Err.For_test.protect (fun () ->
    Err.raise
      ~loc:(Loc.of_file ~path:(Fpath.v "path/to/my-file.txt"))
      ~hints:(Err.did_you_mean "bah" ~candidates:[ "bar"; "foo" ])
      [ Pp.text "Hello Raise"; Err.sexp [%sexp { hello = 42 }] ]);
  [%expect
    {|
    File "path/to/my-file.txt", line 1, characters 0-0:
    Error: Hello Raise
    (hello 42)
    Hint: did you mean bar?
    [123]
    |}];
  Err.For_test.protect (fun () ->
    Err.raise
      ~loc:(Loc.of_file ~path:(Fpath.v "path/to/my-file.txt"))
      ~hints:(Err.did_you_mean "bah" ~candidates:[ "bar"; "foo" ])
      Pp.O.[ Pp.text "Hello Raise " ++ Err.sexp [%sexp { hello = 42 }] ]);
  [%expect
    {|
    File "path/to/my-file.txt", line 1, characters 0-0:
    Error: Hello Raise ((hello 42))
    Hint: did you mean bar?
    [123]
    |}];
  ()
;;

let%expect_test "reraise_with_context" =
  Err.For_test.protect (fun () ->
    match
      Err.raise
        ~loc:(Loc.of_file ~path:(Fpath.v "path/to/my-file.txt"))
        ~hints:(Err.did_you_mean "bah" ~candidates:[ "bar"; "foo" ])
        [ Pp.text "Hello Raise"; Err.sexp [%sexp { hello = 42 }] ]
    with
    | _ -> assert false
    | exception Err.E e ->
      let bt = Stdlib.Printexc.get_raw_backtrace () in
      Err.reraise_with_context
        e
        bt
        [ Pp.text "Re raised with context"; Err.sexp [%sexp { x = 42 }] ]);
  [%expect
    {|
    File "path/to/my-file.txt", line 1, characters 0-0:
    Context: Re raised with context
    (x 42)
    Error: Hello Raise
    (hello 42)
    Hint: did you mean bar?
    [123]
    |}];
  ()
;;

let%expect_test "prerr" =
  let err1 =
    Err.create
      ~loc:(Loc.of_file ~path:(Fpath.v "path/to/my-file-1.txt"))
      ~exit_code:41
      [ Pp.text "Hello Error 1" ]
  in
  let err2 =
    Err.create
      ~loc:(Loc.of_file ~path:(Fpath.v "path/to/my-file-2.txt"))
      ~exit_code:42
      [ Pp.text "Hello Error 2" ]
  in
  Err.For_test.protect (fun () ->
    Err.prerr err1;
    Err.prerr err2);
  [%expect
    {|
    File "path/to/my-file-1.txt", line 1, characters 0-0:
    Error: Hello Error 1

    File "path/to/my-file-2.txt", line 1, characters 0-0:
    Error: Hello Error 2
    |}];
  (* The fact is that [%expect _] strips the output to compare, so the leading
     blank line is not visible here. *)
  Err.For_test.protect (fun () ->
    Err.prerr err1;
    Err.prerr err2 ~reset_separator:true);
  [%expect
    {|
    File "path/to/my-file-1.txt", line 1, characters 0-0:
    Error: Hello Error 1
    File "path/to/my-file-2.txt", line 1, characters 0-0:
    Error: Hello Error 2
    |}];
  ()
;;

let am_running_test () = print_s [%sexp (Err.am_running_test () : bool)]

let%expect_test "multiple errors" =
  Err.For_test.protect (fun () ->
    Err.error ~loc:(Loc.of_file ~path:(Fpath.v "my/file1")) [ Pp.text "Hello Error1" ];
    Err.error ~loc:(Loc.of_file ~path:(Fpath.v "my/file2")) [ Pp.text "Hello Error1" ];
    ());
  [%expect
    {|
    File "my/file1", line 1, characters 0-0:
    Error: Hello Error1

    File "my/file2", line 1, characters 0-0:
    Error: Hello Error1
    [123]
    |}];
  ()
;;

let%expect_test "wrap" =
  (* [wrap] acts on [Err.am_running_test]. *)
  Err.For_test.wrap (fun () ->
    am_running_test ();
    [%expect {| true |}];
    Err.Private.am_running_test := false;
    am_running_test ();
    [%expect {| false |}];
    Err.Private.am_running_test := true;
    am_running_test ();
    [%expect {| true |}]);
  (* The [am_running_test] is returned to its internal value after [wrap] returns. *)
  am_running_test ();
  [%expect {| false |}];
  ()
;;

let%expect_test "error" =
  Err.For_test.wrap
  @@ fun () ->
  Err.For_test.protect (fun () ->
    am_running_test ();
    [%expect {| true |}];
    print_s [%sexp (Err.had_errors () : bool)];
    [%expect {| false |}];
    Err.error [ Pp.text "Hello Error1" ];
    [%expect {| Error: Hello Error1 |}];
    Err.error [ Pp.text "Hello Error2" ];
    [%expect {| Error: Hello Error2 |}];
    ());
  [%expect {| [123] |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| true |}];
  print_s
    [%sexp
      { err_count = (Err.error_count () : int)
      ; warn_count = (Err.warning_count () : int)
      }];
  [%expect
    {|
    ((err_count  2)
     (warn_count 0))
    |}];
  ()
;;

let%expect_test "error handler" =
  Err.For_test.protect (fun () -> Err.error [ Pp.text "Hello Error1" ]);
  [%expect
    {|
    Error: Hello Error1
    [123]
    |}];
  ()
;;

let%expect_test "warning" =
  Err.For_test.wrap
  @@ fun () ->
  Err.For_test.protect (fun () ->
    am_running_test ();
    [%expect {| true |}];
    print_s [%sexp (Err.had_errors () : bool)];
    [%expect {| false |}];
    Err.warning [ Pp.text "Hello Warning1" ];
    [%expect {| Warning: Hello Warning1 |}];
    Err.warning [ Pp.text "Hello Warning2" ];
    [%expect {| Warning: Hello Warning2 |}];
    ());
  [%expect {||}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| false |}];
  print_s
    [%sexp
      { err_count = (Err.error_count () : int)
      ; warn_count = (Err.warning_count () : int)
      }];
  [%expect
    {|
    ((err_count  0)
     (warn_count 2))
    |}];
  ()
;;

let%expect_test "warning handler" =
  Err.For_test.protect (fun () -> Err.warning [ Pp.text "Hello Warning1" ]);
  [%expect {| Warning: Hello Warning1 |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| false |}];
  print_s
    [%sexp
      { err_count = (Err.error_count () : int)
      ; warn_count = (Err.warning_count () : int)
      }];
  [%expect
    {|
    ((err_count  0)
     (warn_count 1))
    |}];
  Ref.set_temporarily Err.Private.warn_error true ~f:(fun () ->
    Err.For_test.protect (fun () -> Err.warning [ Pp.text "Hello Warning1" ]));
  [%expect
    {|
    Warning: Hello Warning1
    [123]
    |}];
  print_s [%sexp (Err.had_errors () : bool)];
  [%expect {| false |}];
  print_s
    [%sexp
      { err_count = (Err.error_count () : int)
      ; warn_count = (Err.warning_count () : int)
      }];
  [%expect
    {|
    ((err_count  0)
     (warn_count 1))
    |}];
  ()
;;

let%expect_test "exn_handler" =
  Err.For_test.protect (fun () -> failwith "Hello Exn");
  [%expect
    {|
    Internal Error: Failure("Hello Exn") <backtrace disabled in tests>
    [125]
    |}];
  let exn_handler = function
    | Failure msg -> Some (Err.create [ Pp.text msg ])
    | _ -> None
  in
  Err.For_test.protect ~exn_handler (fun () -> failwith "Hello Exn");
  [%expect
    {|
    Error: Hello Exn
    [123]
    |}];
  Err.For_test.protect ~exn_handler (fun () -> invalid_arg "Hello Exn");
  [%expect
    {|
    Internal Error: Invalid_argument("Hello Exn") <backtrace disabled in tests>
    [125]
    |}];
  ()
;;

let%expect_test "protect and reset" =
  (* This monitors for a regression of a bug where [Err.protect] would set
     [am_running_test] to false, cancelling the effect intended by
     [Err.For_test.wrap]. *)
  Err.For_test.wrap
  @@ fun () ->
  let result =
    Err.protect (fun () ->
      am_running_test ();
      [%expect {| true |}])
  in
  print_s [%sexp (result : (unit, int) Result.t)];
  [%expect {| (Ok ()) |}];
  ()
;;

let%expect_test "non-test handler" =
  Err.For_test.wrap
  @@ fun () ->
  let result =
    Err.protect
      (fun () -> failwith "Hello Exn")
      ~exn_handler:(function
        | Failure msg -> Some (Err.create [ Pp.text msg ])
        | _ -> None [@coverage off])
  in
  [%expect {| Error: Hello Exn |}];
  print_s [%sexp (result : (unit, int) Result.t)];
  [%expect {| (Error 123) |}];
  ()
;;

let%expect_test "raise without handler" =
  require_does_raise [%here] (fun () -> Err.raise [ Pp.text "Hello" ]);
  [%expect {| Hello |}];
  ()
;;

let%expect_test "reset separator" =
  (* By default, consecutive messages are separated by a blank line. *)
  Err.For_test.protect (fun () ->
    Err.error ~loc:(Loc.of_file ~path:(Fpath.v "my/file1")) [ Pp.text "Hello Error1" ];
    Err.error ~loc:(Loc.of_file ~path:(Fpath.v "my/file2")) [ Pp.text "Hello Error1" ];
    ());
  [%expect
    {|
    File "my/file1", line 1, characters 0-0:
    Error: Hello Error1

    File "my/file2", line 1, characters 0-0:
    Error: Hello Error1
    [123]
    |}];
  (* However, this behavior can be tweaked from companion libraries in certain
     context. They are using [reset_separator] for this. *)
  Err.For_test.protect (fun () ->
    Err.error ~loc:(Loc.of_file ~path:(Fpath.v "my/file1")) [ Pp.text "Hello Error1" ];
    Err.Private.reset_separator ();
    Err.error ~loc:(Loc.of_file ~path:(Fpath.v "my/file2")) [ Pp.text "Hello Error1" ];
    ());
  [%expect
    {|
    File "my/file1", line 1, characters 0-0:
    Error: Hello Error1
    File "my/file2", line 1, characters 0-0:
    Error: Hello Error1
    [123]
    |}];
  ()
;;
