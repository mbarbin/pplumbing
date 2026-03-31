(*********************************************************************************)
(*  pplumbing - Utility libraries to use with [pp]                               *)
(*  SPDX-FileCopyrightText: 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let%expect_test "pp_of_dyn" =
  Err.For_test.wrap
  @@ fun () ->
  let test dyn =
    let err = Err.create [ Err.dyn dyn ] in
    print_endline "========= sexp ==========";
    print_endline (Sexp.to_string_hum (Err.sexp_of_t err));
    print_endline "========== dyn ==========";
    print_dyn (Err.to_dyn err);
    print_endline "======== console ========";
    Err.prerr err ~reset_separator:true
  in
  test (Dyn.List []);
  [%expect
    {|
    ========= sexp ==========
    []
    ========== dyn ==========
    { msgs = [ [] ] }
    ======== console ========
    Error: []
    |}];
  test (Dyn.String "Hello");
  [%expect
    {|
    ========= sexp ==========
    "\"Hello\""
    ========== dyn ==========
    { msgs = [ "Hello" ] }
    ======== console ========
    Error: "Hello"
    |}];
  test (Dyn.record [ "x", Dyn.int 42 ]);
  [%expect
    {|
    ========= sexp ==========
    "{ x = 42 }"
    ========== dyn ==========
    { msgs = [ { x = 42 } ] }
    ======== console ========
    Error: { x = 42 }
    |}];
  test (Dyn.record [ "x", Dyn.int 42; "y", Dyn.string "why" ]);
  [%expect
    {|
    ========= sexp ==========
    "{ x = 42; y = \"why\" }"
    ========== dyn ==========
    { msgs = [ { x = 42; y = "why" } ] }
    ======== console ========
    Error: { x = 42; y = "why" }
    |}];
  test (Dyn.Variant ("Hello_error", [ Dyn.record [ "x", Dyn.int 42 ] ]));
  [%expect
    {|
    ========= sexp ==========
    "Hello_error { x = 42 }"
    ========== dyn ==========
    { msgs = [ Hello_error { x = 42 } ] }
    ======== console ========
    Error: Hello_error { x = 42 }
    |}];
  ()
;;

let dyn_vs_prerr err =
  print_endline "========= sexp ==========";
  print_endline (Sexp.to_string_hum (Err.sexp_of_t err));
  print_endline "========== dyn ==========";
  print_dyn (Err.to_dyn err);
  print_endline "======== console ========";
  Err.prerr err ~reset_separator:true
;;

let%expect_test "dyn vs prerr" =
  Err.For_test.wrap
  @@ fun () ->
  let test = dyn_vs_prerr in
  let err = Err.create [ Pp.verbatim "Hello World" ] in
  test err;
  [%expect
    {|
    ========= sexp ==========
    "Hello World"
    ========== dyn ==========
    { msgs = [ "Hello World" ] }
    ======== console ========
    Error: Hello World
    |}];
  let err = Err.add_context err [ Pp.text "Hello Context!" ] in
  test err;
  [%expect
    {|
    ========= sexp ==========
    ((context "Hello Context!") (error "Hello World"))
    ========== dyn ==========
    { context = [ "Hello Context!" ]; msgs = [ "Hello World" ] }
    ======== console ========
    Context: Hello Context!
    Error: Hello World
    |}];
  let err =
    Err.add_context
      err
      [ Err.dyn
          (Dyn.Variant
             ( "And_even_more_context"
             , [ Dyn.record [ "x", Dyn.int 42; "y", Dyn.string "Foo" ] ] ))
      ]
  in
  test err;
  [%expect
    {|
    ========= sexp ==========
    ((context "And_even_more_context { x = 42; y = \"Foo\" }" "Hello Context!")
     (error "Hello World"))
    ========== dyn ==========
    { context = [ And_even_more_context { x = 42; y = "Foo" }; "Hello Context!" ]
    ; msgs = [ "Hello World" ]
    }
    ======== console ========
    Context: And_even_more_context { x = 42; y = "Foo" }
    Hello Context!
    Error: Hello World
    |}];
  ()
;;

let%expect_test "with positions" =
  Err.For_test.wrap
  @@ fun () ->
  let file_cache =
    Loc.File_cache.create
      ~path:(Fpath.v "foo.txt")
      ~file_contents:
        {|
Hello File
With Multiple lines
|}
  in
  let loc = Loc.of_file_line ~file_cache ~line:1 in
  let err =
    Err.create ~loc [ Pp.text "Hello Located Error" ] ~hints:[ Pp.text "With hints too!" ]
  in
  let test = dyn_vs_prerr in
  test err;
  [%expect
    {|
    ========= sexp ==========
    ("Hello Located Error" (hints "With hints too!"))
    ========== dyn ==========
    { msgs = [ "Hello Located Error" ]; hints = [ "With hints too!" ] }
    ======== console ========
    File "foo.txt", line 1, characters 0-0:
    Error: Hello Located Error
    Hint: With hints too!
    |}];
  Ref.set_temporarily Loc.include_sexp_of_locs true ~f:(fun () -> test err);
  [%expect
    {|
    ========= sexp ==========
    ("File \"foo.txt\", line 1, characters 0-0:" "Hello Located Error"
     (hints "With hints too!"))
    ========== dyn ==========
    { loc = "File \"foo.txt\", line 1, characters 0-0:"
    ; msgs = [ "Hello Located Error" ]
    ; hints = [ "With hints too!" ]
    }
    ======== console ========
    File "foo.txt", line 1, characters 0-0:
    Error: Hello Located Error
    Hint: With hints too!
    |}];
  ()
;;
