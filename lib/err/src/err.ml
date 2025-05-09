module Exit_code = struct
  type t = int

  let ok = 0
  let some_error = 123
  let cli_error = 124
  let internal_error = 125
end

let sexp sexp = Pp.verbatim (Sexplib0.Sexp.to_string_hum sexp)
let exn e = sexp (Sexplib0.Sexp_conv.sexp_of_exn e)

module Paragraph = struct
  type t = Pp_tty.t

  let recognize_sexp t =
    match Pp.to_ast t with
    | Verbatim str ->
      (match Parsexp.Single.parse_string str with
       | Ok sexp -> Some sexp
       | Error _ -> None)
    | _ -> None
  ;;

  let sexp_of_t t =
    match recognize_sexp t with
    | Some sexp -> sexp
    | None ->
      let str = Format.asprintf "%a" Pp.to_fmt (Pp.hbox t) in
      Sexplib0.Sexp.Atom str
  ;;

  let rec simplify_sexp sexp =
    match (sexp : Sexplib0.Sexp.t) with
    | (Atom _ | List []) as sexp -> sexp
    | List [ sexp ] -> simplify_sexp sexp
    | List [ (Atom str as atom); List (List _ :: _ as sexps) ]
      when not (String.contains str ' ') -> List (atom :: List.map simplify_sexp sexps)
    | List sexps -> List (List.map simplify_sexp sexps)
  ;;

  let default_sexp_rendering = sexp

  (* Future plans involve coloring the sexps when rendering to the console. *)
  let pp_sexp sexp =
    let sexp = simplify_sexp sexp in
    let pp =
      (* This is an heuristic to improve the rendering of errors built with the
         [%sexp] extension, such as:

         {[
           [%sexp "Error message", { fields }]
         }]
      *)
      match (sexp : Sexplib0.Sexp.t) with
      | List (Atom atom :: (List _ :: _ as sexps)) when String.contains atom ' ' ->
        Pp.O.(
          Pp.verbatim atom ++ Pp.space ++ Pp.concat_map sexps ~f:default_sexp_rendering)
      | sexp -> default_sexp_rendering sexp
    in
    Pp.box pp
  ;;

  let pp t =
    match recognize_sexp t with
    | Some sexp -> pp_sexp sexp
    | None -> t
  ;;
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

let make_message ~prefix ?loc ?(context = []) ?(hints = []) paragraphs =
  Stdune.User_message.make
    ?loc:(Option.map stdune_loc loc)
    ~hints
    ~prefix:
      (Pp.seq
         (Pp.tag (Prefix.style prefix) (Pp.verbatim (Prefix.to_string prefix)))
         (Pp.char ':'))
    (List.map Paragraph.pp (List.concat [ context; paragraphs ]))
;;

type t =
  { loc : Loc.t option
  ; context : Paragraph.t list
  ; paragraphs : Paragraph.t list
  ; hints : Pp_tty.t list
  ; exit_code : Exit_code.t
  }

let to_sexps { loc; context; paragraphs; hints; exit_code = _ } =
  List.concat
    [ (match loc with
       | None -> []
       | Some loc ->
         if Loc.include_sexp_of_locs.contents
         then [ Sexplib0.Sexp.Atom (Loc.to_string loc) ]
         else [])
    ; (if List.is_empty context
       then List.map Paragraph.sexp_of_t paragraphs
       else
         [ List (Atom "context" :: List.map Paragraph.sexp_of_t context)
         ; List (Atom "error" :: List.map Paragraph.sexp_of_t paragraphs)
         ])
    ; (match hints with
       | [] -> []
       | _ :: _ -> [ List (Atom "hints" :: List.map Paragraph.sexp_of_t hints) ])
    ]
;;

let to_stdune_user_message ~prefix { loc; context; paragraphs; hints; exit_code = _ } =
  if
    List.is_empty paragraphs
    && Option.is_none loc
    && List.is_empty context
    && List.is_empty hints
  then None
  else Some (make_message ~prefix ?loc ~context ~hints paragraphs)
;;

let sexp_of_t_internal ~include_exit_code t =
  let sexps = to_sexps t in
  let list =
    List.concat
      [ sexps
      ; (if include_exit_code || List.is_empty sexps
         then [ List [ Atom "exit_code"; Atom (Int.to_string t.exit_code) ] ]
         else [])
      ]
  in
  match list with
  | [ sexp ] -> sexp
  | _ -> Sexplib0.Sexp.List list
;;

let sexp_of_t t = sexp_of_t_internal ~include_exit_code:false t
let to_string_hum t = Sexplib0.Sexp.to_string_hum (sexp_of_t t)

module With_exit_code = struct
  type nonrec t = t

  let sexp_of_t t = sexp_of_t_internal ~include_exit_code:true t
end

exception E of t

let () =
  Sexplib0.Sexp_conv.Exn_converter.add [%extension_constructor E] (function
    | E t -> sexp_of_t t
    | _ -> assert false)
;;

let create
      ?loc
      ?(context = [])
      ?(hints = [])
      ?(exit_code = Exit_code.some_error)
      paragraphs
  =
  { loc; context; paragraphs; hints; exit_code }
;;

let add_context t context = { t with context = context @ t.context }

let raise ?loc ?hints ?exit_code paragraphs =
  Stdlib.raise (E (create ?loc ?hints ?exit_code paragraphs))
;;

let reraise_with_context t bt context =
  Printexc.raise_with_backtrace (E (add_context t context)) bt
;;

let exit exit_code =
  Stdlib.raise (E { loc = None; context = []; paragraphs = []; hints = []; exit_code })
;;

let ok_exn = function
  | Ok x -> x
  | Error e -> Stdlib.raise (E e)
;;

let of_exn e =
  match (e : exn) with
  | E e -> e
  | e -> create [ exn e ]
;;

let did_you_mean = Stdune.User_message.did_you_mean

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
  Option.iter prerr_message (to_stdune_user_message ~prefix:Error t)
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

let handle_messages_and_exit ~err:({ exit_code; _ } as t) ~backtrace =
  Option.iter prerr_message (to_stdune_user_message ~prefix:Error t);
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

let reraise_s bt e ?loc:_ ?hints:_ ?exit_code:_ desc s =
  reraise_with_context e bt [ Pp.text desc; sexp s ] [@coverage off]
;;

let pp_of_sexp = sexp
