open Valet_core
open Test_lib
open Core.Std
open Async.Std

let doors_ref = ref None

module Person : sig
  type t

  val create : string -> int -> t
  val run : t -> QRReader.t array -> int -> unit Async_kernel.Deferred.t
end = struct
  type t =
    {
      id: int;
      qrcode: string;
    }

  let create qrcode id = { id; qrcode; }

  let run t readers n =
    let open Async.Std in
    let len = Array.length readers in
    let rec run = function
      | 0 -> Deferred.unit
      | n ->
        let r = readers.(Random.int len) in
        QRReader.use r t.qrcode;
        Scheduler.yield () >>= fun () ->
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
  Deferred.all_ignore @@
  Array.fold
    ~f:(fun a p -> (Person.run p readers n)::a) ~init:[] persons >>= fun () ->
  (try
    Sys.getenv "OCAML_GC_STATS" |> function
    | Some fn -> Out_channel.with_file fn ~f:(fun oc -> Gc.print_stat oc)
    | _ -> ()
  with _ -> ());
  Shutdown.exit 1


let () =
  if Array.length Sys.argv < 2 then
    (Printf.eprintf "Usage: %s n\n" Sys.argv.(0);
     Pervasives.exit 1
    );
  don't_wait_for @@ main @@ int_of_string Sys.argv.(1);
  never_returns @@ Scheduler.go ()

