let%expect_test "pp_of_sexp" =
  let test sexp =
    let err = Err.create [ Err.sexp sexp ] in
    print_endline "========= sexp ==========";
    print_endline (Sexp.to_string_hum (Err.sexp_of_t err));
    print_endline "======== console ========";
    Err.prerr err ~reset_separator:true
  in
  test [%sexp ()];
  [%expect
    {|
    ========= sexp ==========
    ()
    ======== console ========
    Error: ()
    |}];
  test [%sexp "Hello"];
  [%expect
    {|
    ========= sexp ==========
    Hello
    ======== console ========
    Error: Hello
    |}];
  test [%sexp "Hello error", { x = 42 }];
  [%expect
    {|
    ========= sexp ==========
    ("Hello error" ((x 42)))
    ======== console ========
    Error: Hello error (x 42)
    |}];
  test [%sexp { x = 42 }];
  [%expect
    {|
    ========= sexp ==========
    ((x 42))
    ======== console ========
    Error: (x 42)
    |}];
  test [%sexp { x = 42; y = "why" }];
  [%expect
    {|
    ========= sexp ==========
    ((x 42) (y why))
    ======== console ========
    Error: ((x 42) (y why))
    |}];
  test [%sexp "Hello error", { x = 42 }];
  [%expect
    {|
    ========= sexp ==========
    ("Hello error" ((x 42)))
    ======== console ========
    Error: Hello error (x 42)
    |}];
  test [%sexp "Hello error", { x = 42; y = "why" }];
  [%expect
    {|
    ========= sexp ==========
    ("Hello error" ((x 42) (y why)))
    ======== console ========
    Error: Hello error ((x 42) (y why))
    |}];
  test [%sexp Var { x = 42; y = "why" }];
  [%expect
    {|
    ========= sexp ==========
    (Var ((x 42) (y why)))
    ======== console ========
    Error: (Var (x 42) (y why))
    |}];
  ()
;;

let sexp_vs_prerr err =
  print_endline "========= sexp ==========";
  print_s (Err.sexp_of_t err);
  print_endline "======== console ========";
  Err.prerr err ~reset_separator:true
;;

let%expect_test "sexp vs prerr" =
  let test = sexp_vs_prerr in
  let err = Err.create [ Pp.verbatim "Hello World" ] in
  test err;
  [%expect
    {|
    ========= sexp ==========
    "Hello World"
    ======== console ========
    Error: Hello World
    |}];
  let err = Err.add_context err [ Pp.text "Hello Context!" ] in
  test err;
  [%expect
    {|
    ========= sexp ==========
    ((context "Hello Context!")
     (error   "Hello World"))
    ======== console ========
    Error: Hello Context!
    Hello World
    |}];
  let err =
    Err.add_context
      err
      [ Err.sexp [%sexp "And even more context", { x = 42; y = "Foo" }] ]
  in
  test err;
  [%expect
    {|
    ========= sexp ==========
    ((context
       ("And even more context" (
         (x 42)
         (y Foo)))
       "Hello Context!")
     (error "Hello World"))
    ======== console ========
    Error: And even more context ((x 42) (y Foo))
    Hello Context!
    Hello World
    |}];
  ()
;;

let%expect_test "with positions" =
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
  let test = sexp_vs_prerr in
  test err;
  [%expect
    {|
    ========= sexp ==========
    ("Hello Located Error" (hints "With hints too!"))
    ======== console ========
    File "foo.txt", line 1, characters 0-0:
    Error: Hello Located Error
    Hint: With hints too!
    |}];
  Ref.set_temporarily Loc.include_sexp_of_locs true ~f:(fun () -> test err);
  [%expect
    {|
    ========= sexp ==========
    ("File \"foo.txt\", line 1, characters 0-0:"
     "Hello Located Error"
     (hints "With hints too!"))
    ======== console ========
    File "foo.txt", line 1, characters 0-0:
    Error: Hello Located Error
    Hint: With hints too!
    |}];
  ()
;;
