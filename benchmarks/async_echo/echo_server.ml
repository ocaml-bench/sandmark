open Core
open Async

let print_infos addr input = 
  if !Echo_common.debug then Log.Global.printf "(Server) received %i bytes from (%s)" 
    (String.length input)
    (Socket.Address.to_string addr);
  input

let run ~port opt () =
  if !Echo_common.debug then Log.Global.info "Starting server...";
  Tcp.Server.create
    ~on_handler_error:`Raise
    (Tcp.Where_to_listen.of_port port)
    (fun addr r w ->
       if !Echo_common.debug then Log.Global.printf "(Server) Connection from (%s)" 
         (Socket.Address.to_string addr);
       Pipe.transfer (Reader.pipe r) (Writer.pipe w) ~f:(print_infos addr))
  >>= fun server ->
  let serv_port = Tcp.Server.listening_on server in
  if !Echo_common.debug then Log.Global.info "Server started on %d, waiting for close" serv_port;
  match opt with
  | None -> Deferred.never ()
  | Some nbr -> Echo_client.run ~port:serv_port ~nbr ()
