open Core
open Async

let command =
  Command.async_spec
    ~summary:"Echo test"
    Command.Spec.(
      empty 
      +> Echo_common.port_arg ()
      +> Echo_common.nbr_arg ()
      +> Echo_common.debug_arg ()
    )
    (fun port nbr debug () -> Echo_common.debug := debug; Echo_server.run ~port (Some nbr) ())

let () = Command.run command
