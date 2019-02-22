open Valet_core
open Valet_react

module QRReader : sig
  type t

  val create : unit -> t
  val id : t -> Uuidm.t
  val handler : t -> ([`QRCode of QRCode.t], [`QRCode of QRCode.t]) Handler.t
  val use : t -> string -> unit
end = struct
  type t =
    { id: Uuidm.t;
      handler: ([`QRCode of QRCode.t], [`QRCode of QRCode.t]) Handler.t;
    }

  let create () =
      {
        id = Uuidm.create `V4;
        handler = Handler.create_sensor ();
      }

  let id t = t.id
  let handler t = t.handler

  let use t qrcode =
    let qrcode = QRCode.create ~source:t.id ~value:qrcode in
    Handler.run t.handler @@ Event.qrcode qrcode
end

module Controller : sig
  type t

  val create : int SMap.t -> t
  val handler : t -> ([`QRCode of QRCode.t], [`User of User.t]) Handler.t
  val connect_readers : t -> QRReader.t list -> t
end = struct
  type t =
    {
      id: Uuidm.t;
      handler: ([`QRCode of QRCode.t], [`User of User.t]) Handler.t;
    }

  let create db =
    {
      id = Uuidm.create `V4;
      handler = Handler.create
          (fun evt -> match Event.event evt with
             | `QRCode qr ->
               let source = QRCode.source qr in
               let value = QRCode.value qr in
               (try Event.user @@
                  User.granted
                    ~id:(string_of_int @@ SMap.find value db)
                    ~source
                with Not_found -> Event.user `Unknown)
          );
    }

  let handler t = t.handler

  let connect_readers t rs =
    { t with handler = Handler.connect t.handler @@
               List.map QRReader.handler rs }
end

module Door : sig
  type t

  val create :
    readers:UuidSet.t ->
    action:(Uuidm.t -> string -> unit) -> t
  val connect_controller : t -> Controller.t -> t
end = struct
  type t =
    {
      id: Uuidm.t;
      readers: UuidSet.t;
      handler: ([`User of User.t], [`Nil]) Handler.t;
    }

  let create ~readers ~action =
    let id = Uuidm.create `V4 in
      {
        id;
        readers;
        handler = Handler.create
            (fun evt ->
               match Event.event evt with
               | `User v ->
                 let open User in
                 (match v with
                  | `Granted { id; source; } ->
                    if UuidSet.mem source readers then action source id;
                  | `Denied _ -> ()
                  | `Unknown -> ()
                 );
                 Event.nil ()
            );
      }

  let connect_controller t ctrl =
    { t with handler = Handler.connect_one t.handler @@ Controller.handler ctrl }
end
