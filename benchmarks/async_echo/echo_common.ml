open Core

let debug = ref false

let debug_arg () =
  Command.Spec.(
    flag "-debug" no_arg ~doc: " Print debug infos"
  )

let port_arg () =
  Command.Spec.(
    flag "-port" (optional_with_default 8765 int)
      ~doc:" Server's port"
  )

let nbr_arg () =
  Command.Spec.(
    flag "-nbr" (optional_with_default 1000 int)
      ~doc:" Number of string send to the server"
  )
