let hello_world = [%sexp "Hello, World!"]

let print_cmd =
  Command.make
    ~summary:"print hello world"
    (let%map_open.Command () = Arg.return () in
     print_s hello_world)
;;

let main = Command.group ~summary:"" [ "print", print_cmd ]
