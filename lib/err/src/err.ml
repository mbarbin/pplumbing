module Exit_code = struct
  type t = int

  let ok = 0
  let some_error = 123
  let cli_error = 124
  let internal_error = 125
end

module Appendable_list = struct
  include Stdune.Appendable_list

  let append = ( @ )
  let iter t ~f = List.iter f (to_list t)
end

module Prefix = struct
  type t =
    | Error
    | Warning
    | Info
    | Debug

  let to_string = function
    | Error -> "Error"
    | Warning -> "Warning"
    | Info -> "Info"
    | Debug -> "Debug"
  ;;

  let style : t -> Pp_tty.Style.t = function
    | Error -> Error
    | Warning -> Warning
    | Info -> Kwd
    | Debug -> Debug
  ;;
end

let stdune_loc (loc : Loc.t) =
  let { Loc.Lexbuf_loc.start; stop } = Loc.to_lexbuf_loc loc in
  Stdune.Loc.of_lexbuf_loc { start; stop }
;;

let make_message ~prefix ?loc ?hints paragraphs =
  Stdune.User_message.make
    ?loc:(Option.map stdune_loc loc)
    ?hints
    ~prefix:
      (Pp.seq
         (Pp.tag (Prefix.style prefix) (Pp.verbatim (Prefix.to_string prefix)))
         (Pp.char ':'))
    paragraphs
;;

(* The messages are sorted and printed in the order they were raised. For
   example, in [reraise], we insert the new message to the right most position
   of [t.messages]. *)
type t =
  { messages : Stdune.User_message.t Appendable_list.t
  ; exit_code : Exit_code.t
  }

let sexp_of_t { messages; exit_code } =
  Sexplib0.Sexp.List
    (List.map
       (fun message -> Sexplib0.Sexp.Atom (Stdune.User_message.to_string message))
       (Appendable_list.to_list messages)
     @ [ List [ Atom "Exit"; Atom (Int.to_string exit_code) ] ])
;;

exception E of t

let () =
  Sexplib0.Sexp_conv.Exn_converter.add [%extension_constructor E] (function
    | E t -> sexp_of_t t
    | _ -> assert false)
;;

let of_stdune_user_message ?(exit_code = Exit_code.some_error) t =
  { messages = Appendable_list.singleton t; exit_code }
;;

let create_error ?loc ?hints paragraphs =
  Stdune.User_error.make ?loc:(Option.map stdune_loc loc) ?hints paragraphs
;;

let create ?loc ?hints ?exit_code paragraphs =
  create_error ?loc ?hints paragraphs |> of_stdune_user_message ?exit_code
;;

let append ?exit_code t1 t2 =
  let exit_code =
    match exit_code with
    | Some e -> e
    | None -> t2.exit_code
  in
  { messages = Appendable_list.append t1.messages t2.messages; exit_code }
;;

let raise ?loc ?hints ?exit_code paragraphs =
  Stdlib.raise (E (create ?loc ?hints ?exit_code paragraphs))
;;

let reraise bt e ?loc ?hints ?(exit_code = Exit_code.some_error) paragraphs =
  let message = create_error ?loc ?hints paragraphs in
  Printexc.raise_with_backtrace
    (E
       { messages = Appendable_list.append e.messages (Appendable_list.singleton message)
       ; exit_code
       })
    bt
;;

let exit exit_code = Stdlib.raise (E { messages = Appendable_list.empty; exit_code })

let ok_exn = function
  | Ok x -> x
  | Error e -> Stdlib.raise (E e)
;;

let did_you_mean = Stdune.User_message.did_you_mean

let sexp sexp =
  let rec aux sexp =
    match (sexp : Sexplib0.Sexp.t) with
    | Atom s -> Pp.verbatim s
    | List [ sexp ] -> aux sexp
    | List _ -> Pp.verbatim (Sexplib0.Sexp.to_string_hum sexp)
  in
  match (sexp : Sexplib0.Sexp.t) with
  | List (Atom atom :: sexps) ->
    Pp.O.(Pp.verbatim atom ++ Pp.space ++ Pp.concat_map sexps ~f:aux)
  | sexp -> aux sexp
;;

module Color_mode = struct
  type t =
    [ `Auto
    | `Always
    | `Never
    ]

  let all : t list = [ `Auto; `Always; `Never ]

  let to_string : t -> string = function
    | `Auto -> "auto"
    | `Always -> "always"
    | `Never -> "never"
  ;;
end

let color_mode_value : Color_mode.t ref = ref `Auto
let color_mode () = !color_mode_value

(* I've tried testing the following, which doesn't work as expected:

   {v
   let%expect_test "am_running_test" =
     print_s [%sexp { am_running_inline_test : bool; am_running_test : bool }];
     [%expect {| ((am_running_inline_test false) (am_running_test false)) |}];
     ()
   ;;
   v}

   Thus been using this variable to avoid the printer to produce styles in expect
   tests when running in the GitHub Actions environment.
*)
let am_running_test_value = ref false
let am_running_test () = !am_running_test_value
let log_err_count_value = ref (fun () -> (0 [@coverage off]))
let log_warn_count_value = ref (fun () -> (0 [@coverage off]))
let error_count_value = ref 0
let warning_count_value = ref 0

let error_count () =
  if am_running_test ()
  then !error_count_value
  else !error_count_value + log_err_count_value.contents ()
;;

let had_errors () = error_count () > 0

let warning_count () =
  if am_running_test ()
  then !warning_count_value
  else !warning_count_value + log_warn_count_value.contents ()
;;

let no_style_printer pp = Stdlib.prerr_string (Format.asprintf "%a" Pp.to_fmt pp)
let include_separator = ref false

let reset_counts () =
  error_count_value := 0;
  warning_count_value := 0
;;

let reset_separator () = include_separator := false

let prerr_message (t : Stdune.User_message.t) =
  let use_no_style_printer =
    !am_running_test_value
    ||
    match !color_mode_value with
    | `Never -> true
    | `Always | `Auto -> false
  in
  let () =
    if !include_separator then Stdlib.prerr_newline () else include_separator := true
  in
  t.loc
  |> Option.iter (fun loc ->
    (if use_no_style_printer then no_style_printer else Stdune.Ansi_color.prerr)
      (Stdune.Loc.pp loc
       |> Pp.map_tags ~f:(fun (Loc : Stdune.Loc.tag) ->
         Stdune.User_message.Print_config.default Loc)));
  let message = { t with loc = None } in
  if use_no_style_printer
  then no_style_printer (Stdune.User_message.pp message)
  else Stdune.User_message.prerr message
;;

let prerr ?(reset_separator = false) (t : t) =
  if reset_separator then include_separator := false;
  Appendable_list.iter t.messages ~f:prerr_message
;;

module Log_level = struct
  type t =
    | Quiet
    | App
    | Error
    | Warning
    | Info
    | Debug

  let all = [ Quiet; App; Error; Warning; Info; Debug ]

  let to_index = function
    | Quiet -> 0
    | App -> 1
    | Error -> 2
    | Warning -> 3
    | Info -> 4
    | Debug -> 5
  ;;

  let compare l1 l2 = Int.compare (to_index l1) (to_index l2)

  let to_string = function
    | Quiet -> "quiet"
    | App -> "app"
    | Error -> "error"
    | Warning -> "warning"
    | Info -> "info"
    | Debug -> "debug"
  ;;
end

let warn_error_value = ref false

let log_level_get_value, log_level_set_value =
  let value = ref Log_level.Warning in
  ref (fun () -> (!value [@coverage off])), ref (fun v -> value := (v [@coverage off]))
;;

let log_level () = log_level_get_value.contents ()
let log_enables level = Log_level.compare (log_level ()) level >= 0

let error ?loc ?hints paragraphs =
  if log_enables Error
  then (
    let message = make_message ~prefix:Error ?loc ?hints paragraphs in
    incr error_count_value;
    prerr_message message)
;;

let warning ?loc ?hints paragraphs =
  if log_enables Warning
  then (
    let message = make_message ~prefix:Warning ?loc ?hints paragraphs in
    incr warning_count_value;
    prerr_message message)
;;

let info ?loc ?hints paragraphs =
  if log_enables Info
  then (
    let message = make_message ~prefix:Info ?loc ?hints paragraphs in
    prerr_message message)
;;

let debug ?loc ?hints paragraphs =
  if log_enables Debug
  then (
    let message = make_message ~prefix:Debug ?loc ?hints (Lazy.force paragraphs) in
    prerr_message message)
;;

let pp_backtrace backtrace =
  if am_running_test ()
  then [ "<backtrace disabled in tests>" ]
  else
    String.split_on_char '\n' (Printexc.raw_backtrace_to_string backtrace)
    |> List.filter (fun s -> not (String.length s = 0))
;;

let handle_messages_and_exit ~err:{ messages; exit_code } ~backtrace =
  Appendable_list.iter messages ~f:prerr_message;
  if Int.equal exit_code Exit_code.internal_error
  then (
    let message =
      let prefix = Pp.seq (Pp_tty.tag Error (Pp.verbatim "Backtrace")) (Pp.char ':') in
      let backtrace = pp_backtrace backtrace in
      Stdune.User_message.make
        ~prefix
        [ Pp.concat_map ~sep:(Pp.break ~nspaces:1 ~shift:0) backtrace ~f:Pp.verbatim ]
    in
    prerr_message message);
  Error exit_code
;;

let had_errors_or_warn_errors () =
  error_count () > 0 || (!warn_error_value && warning_count () > 0)
;;

let protect ?(exn_handler = Fun.const None) f =
  reset_counts ();
  reset_separator ();
  match f () with
  | ok -> if had_errors_or_warn_errors () then Error Exit_code.some_error else Ok ok
  | exception E err ->
    let backtrace = Printexc.get_raw_backtrace () in
    handle_messages_and_exit ~err ~backtrace
  | exception exn ->
    let backtrace = Printexc.get_raw_backtrace () in
    (match exn_handler exn with
     | Some err -> handle_messages_and_exit ~err ~backtrace
     | None ->
       let message =
         let prefix =
           Pp.seq (Pp_tty.tag Error (Pp.verbatim "Internal Error")) (Pp.char ':')
         in
         let backtrace = pp_backtrace backtrace in
         Stdune.User_message.make
           ~prefix
           [ Pp.concat_map
               ~sep:(Pp.break ~nspaces:1 ~shift:0)
               (Printexc.to_string exn :: backtrace)
               ~f:Pp.verbatim
           ]
       in
       prerr_message message;
       Error Exit_code.internal_error)
;;

module For_test = struct
  let wrap f =
    let init = am_running_test () in
    am_running_test_value := true;
    let init_level = log_level_get_value.contents () in
    log_level_set_value.contents Log_level.Warning;
    Fun.protect
      ~finally:(fun () ->
        am_running_test_value := init;
        log_level_set_value.contents init_level)
      f
  ;;

  let protect ?exn_handler f =
    match wrap (fun () -> protect f ?exn_handler) with
    | Ok () -> ()
    | Error code -> if code <> 0 then Stdlib.prerr_endline (Printf.sprintf "[%d]" code)
  ;;
end

module Private = struct
  let am_running_test = am_running_test_value

  let reset_counts () =
    error_count_value := 0;
    warning_count_value := 0
  ;;

  let reset_separator () = include_separator := false
  let color_mode = color_mode_value

  let set_log_level ~get ~set =
    log_level_get_value := get;
    log_level_set_value := set;
    ()
  ;;

  let warn_error = warn_error_value

  let set_log_counts ~err_count ~warn_count =
    log_err_count_value := err_count;
    log_warn_count_value := warn_count;
    ()
  ;;
end

let create_s ?loc ?hints ?exit_code desc s =
  create ?loc ?hints ?exit_code [ Pp.text desc; sexp s ] [@coverage off]
;;

let raise_s ?loc ?hints ?exit_code desc s =
  raise ?loc ?hints ?exit_code [ Pp.text desc; sexp s ] [@coverage off]
;;

let reraise_s bt e ?loc ?hints ?exit_code desc s =
  reraise bt e ?loc ?hints ?exit_code [ Pp.text desc; sexp s ] [@coverage off]
;;

let pp_of_sexp = sexp
