module Color_mode = struct
  type t =
    [ `Always
    | `Auto
    | `Never
    ]
  [@@deriving equal, enumerate, sexp_of]
end

let%expect_test "color_mode" =
  List.iter Color_mode.all ~f:(fun color_mode ->
    Err.Private.color_mode := color_mode;
    let color_mode' = Err.color_mode () in
    require_equal [%here] (module Color_mode) color_mode color_mode';
    print_s [%sexp (color_mode' : Color_mode.t)]);
  [%expect
    {|
    Always
    Auto
    Never
    |}];
  Err.Private.color_mode := `Auto;
  ()
;;
