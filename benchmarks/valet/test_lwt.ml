open Valet_core
open Test_lib
open Lwt

let doors_ref = ref None

module Person : sig
  type t

  val create : string -> int -> t
  val run : t -> QRReader.t array -> int -> unit Lwt.t
end = struct
  type t =
    {
      id: int;
      qrcode: string;
    }

  let create qrcode id = { id; qrcode; }

  let run t readers n =
    let open Lwt in
    let len = Array.length readers in
    let rec run = function
      | 0 -> return_unit
      | n ->
        let r = readers.(Random.int len) in
        QRReader.use r t.qrcode;
        Lwt_unix.yield () >>= fun () ->
        run @@ pred n
    in run n
end

let main n =
  let user_to_qr, qr_to_user = UserDB.create n in
  let readers = Array.init n (fun _ -> QRReader.create ()) in
  let controller =
    let controller = Controller.create qr_to_user in
    Controller.connect_readers controller @@ Array.to_list readers
  in
  let doors =
    let doors = Array.init n
        (fun i -> Door.create
            ~readers:(UuidSet.singleton @@ QRReader.id readers.(i))
            ~action:(fun _ _ -> ())) in
    Array.map (fun d -> Door.connect_controller d controller) doors
  in
  doors_ref := Some doors;
  let persons = Array.init n (fun id -> Person.create user_to_qr.(id) id) in
  Lwt.join @@
  Array.fold_left
    (fun a p -> (Person.run p readers n)::a) [] persons

let () =
  if Array.length Sys.argv < 2 then
    (Printf.eprintf "Usage: %s n\n" Sys.argv.(0);
     exit 1
    );
  Lwt_main.run @@ main @@ int_of_string Sys.argv.(1);
  try
    let fn = Sys.getenv "OCAML_GC_STATS" in
    let oc = open_out fn in
    Gc.print_stat oc
  with _ -> ()
