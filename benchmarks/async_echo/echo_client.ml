open Core
open Async

let send_stuff nbr_stuff state r w =
  let size = 27 in
  let str = String.make size 'a' in
  let buffer = Bytes.create size in
  let rec send_stuffs i =
    if i = nbr_stuff then return ()
    else
      let len = (Random.State.int state (size - 1)) + 1 in
      Writer.write ~pos:0 ~len w str;
      if !Echo_common.debug then Log.Global.printf "(Client-%i) send '%s'." i str;
      Reader.read r buffer
      >>= function
      | `Eof -> return ()
      | `Ok _ ->
        if !Echo_common.debug then Log.Global.printf "(Client-%i) received '%s'." i buffer;
        send_stuffs (i + 1)
  in
  send_stuffs 0

let run ~port ~nbr () =
  Random.init 42;
  let state = Random.State.default in
  Tcp.with_connection
    (Tcp.Where_to_connect.of_host_and_port
       {host="127.0.0.1"; port=port})
    (fun _ r w ->
       if !Echo_common.debug then Log.Global.printf "(Client) Connected to server.";
       send_stuff nbr (Random.State.copy state) r w
       >>= fun() -> Reader.close r
       >>= fun () -> Writer.close w)
