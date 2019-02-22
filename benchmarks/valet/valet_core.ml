module QRCode = struct
  type t =
    {
      source: Uuidm.t;
      value: string;
    }
  let create ~source ~value = { source; value; }
  let check t s = t.value = s
  let compare = compare
  let source t = t.source
  let value t = t.value
end

module User = struct
  type _t =
    {
      id: string;
      source: Uuidm.t;
    }

  type t = [ `Granted of _t | `Denied of _t | `Unknown ]

  let granted ~id ~source = `Granted { id; source; }
  let denied ~id ~source = `Denied { id; source; }
end

module Event : sig
  type kind = [`QRCode of QRCode.t | `User of User.t | `Nil]
  type qrcode = [ `QRCode of QRCode.t ]
  type user = [ `User of User.t ]
  type nil = [ `Nil ]
  type 'a t

  val event : 'a t -> 'a
  val qrcode : QRCode.t -> [> qrcode] t
  val user : User.t -> [> user] t
  val nil : unit -> [> nil] t
end = struct
  type kind = [`QRCode of QRCode.t | `User of User.t | `Nil]
  type qrcode = [ `QRCode of QRCode.t ]
  type user = [ `User of User.t ]
  type nil = [ `Nil ]

  type 'a t =
    {
      event: 'a;
      timestamp: float;
    }

  let create event =
    {
      event = event;
      timestamp = Unix.gettimeofday ();
    }

  let event t = t.event
  let qrcode qr = create @@ `QRCode qr
  let user u = create @@ `User u
  let nil () = create `Nil
end

module SMap = Map.Make(String)
module UuidMap = Map.Make(Uuidm)
module UuidSet = Set.Make(Uuidm)

module UserDB : sig
  val create : int -> string array * int SMap.t
end = struct
  let random_string len =
    let true_len = len / 8 * 8 + 8 in
    let b = Bytes.create true_len in
    for i = 0 to true_len / 8 - 1 do
      EndianBytes.BigEndian.set_int64 b (i*8) @@
      Random.int64 Int64.max_int
    done;
    Bytes.(sub b 0 len |> unsafe_to_string)

  let create n =
    let user_to_qr = Array.make n "" in
    let rec generate a = function
      | 0 -> a
      | n ->
          let qrcode = random_string 10 in
          user_to_qr.(n-1) <- qrcode;
          generate
            (SMap.add qrcode (n-1) a) @@ pred n
    in
    user_to_qr, generate SMap.empty n
end
