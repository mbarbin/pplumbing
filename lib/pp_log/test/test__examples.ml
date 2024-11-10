(* In this file we check some of the examples given in the mli do compile. *)

let%expect_test "info" =
  let src = Logs.Src.create "test" ~doc:"Test logger" in
  Logs.Src.set_level src (Some Logs.Info);
  Logs.set_reporter (Logs_fmt.reporter ());
  let hello () =
    Logs.info ~src (fun m ->
      m "Hello %a World!" Fmt.(styled (`Fg `Blue) string) "Colored")
  in
  hello ();
  [%expect {| inline_test_runner_pp_log_test.exe: [INFO] Hello Colored World! |}];
  let hello () =
    Pp_log.info ~src (fun () ->
      Pp.O.
        [ Pp.text "Hello "
          ++ Pp_tty.ansi (module String) "Colored" [ `Fg_blue ]
          ++ Pp.text " World!"
        ])
  in
  hello ();
  [%expect {| inline_test_runner_pp_log_test.exe: [INFO] Hello Colored World! |}];
  ()
;;
