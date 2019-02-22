open Valet_core
open React

module Handler : sig
  type ('a, 'b) t
  val create : ('a Event.t -> 'b Event.t) -> ('a, 'b) t
  val create_sensor : unit -> ('a, 'a) t
  val run : ?step:step -> ('a, 'b) t -> 'a Event.t -> unit
  val connect : ('a, 'b) t -> ('c, 'a) t list -> ('a, 'b) t
  val connect_one : ('a, 'b) t -> ('c, 'a) t -> ('a, 'b) t
end = struct
  type ('a, 'b) t =
    {
      evt: 'b Event.t event;
      send: ?step:step -> 'a Event.t -> unit;
      action: ('a Event.t -> 'b Event.t); (* we need it for later *)
    }

  let create action =
    let evt, send = E.create () in
    let evt = E.map action evt
    in
    {
      evt; send; action;
    }

  let create_sensor () =
    let evt, send = E.create () in
    { evt; send; action = fun e -> e; }

  let run ?step t e = t.send ?step e

  let connect t others =
    let evts = List.map
        (fun o -> E.map t.action o.evt)
        others in
    let evt = E.select @@ t.evt :: evts in
    {
      t with evt;
    }

  let connect_one t t' = connect t [t']
end
