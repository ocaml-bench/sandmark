(* Simple example of reading and writing in a Irmin-mem repository *)
open Lwt.Infix
open Printf

module Config = struct
let root = "/tmp/irmin/test"

let init () =
  let _ = Sys.command (Printf.sprintf "rm -rf %s" root) in
  let _ = Sys.command (Printf.sprintf "mkdir -p %s" root) in
  ()

(* Install the FS listener. *)
let () = Irmin_unix.set_listen_dir_hook ()
end

let info = Irmin_unix.info

module Store = Irmin_mem.KV (Irmin.Contents.String)

let update t k v =
  let msg = sprintf "Updating /%s" (String.concat "/" k) in
  print_endline msg;
  Store.set_exn t ~info:(info "%s" msg) k v

let read_exn t k =
  let msg = sprintf "Reading /%s" (String.concat "/" k) in
  print_endline msg;
  Store.get t k

let main () =
  let rec make n x = match n with 0 -> [] | _ -> ((string_of_int n) ^ x) :: make (n-1) x in
  let c_clone src dst = (* gives out (Store.t, Store.t) Lwt.t *)
    Store.clone ~src:src ~dst:dst >>= fun dst -> print_endline "cloning ..."; Lwt.return (src, dst)
  in
  
  let n_c_clone src = (* generates (Store.t, Store.t) list Lwt.t *)
    Lwt_list.map_p (c_clone src) (make 10 "test")
  in
  
  let c_update src dst branch_str content = (* gives out (Store.t, Store.t) Lwt.t *)
    update dst branch_str content >>= fun () -> Lwt.return (src, dst)
  in

  let n_c_update src_dst_tuple_list branch_str_list content_list =
    let rec zip a b c =
      match (a, b, c) with
      | ((a1, a2) :: tl1 , b :: tl2, c :: tl3) -> (a1, a2, b, c) :: zip tl1 tl2 tl3
      | (_, _, _) -> []
    in
    Lwt_list.map_p (fun (w, x, y, z) -> c_update w x y z) (zip src_dst_tuple_list branch_str_list content_list)
  in

  let c_merge src dst =
    Store.merge_into ~info:(info "t: Merge with 'x'") dst ~into:src >>= function
    | Error _ -> failwith "conflict!"
    | Ok () -> print_endline "merging ..."; Lwt.return_unit
  in
  
  Config.init ();
  let config = Irmin_git.config ~bare:true Config.root in
  Store.Repo.v config >>= fun repo ->
  Store.master repo >>= fun t ->
  n_c_clone t >>= fun src_dst_tuple_list -> 
  n_c_update src_dst_tuple_list (make 10 ".txt" |> List.map (fun x -> ["root"; "misc"; x])) (make 10 "content") >>= fun src_dst ->
  Lwt_list.map_p (fun (x,y) -> c_merge x y) src_dst >>= fun _ -> Lwt.return_unit

let () =
  Printf.printf
    "This example creates a Git repository in %s and use it to read \n\
     and write data:\n"
    Config.root;
  let _ = Sys.command (Printf.sprintf "rm -rf %s" Config.root) in
  Lwt_main.run (main ());
  Printf.printf "You can now run `cd %s && tig` to inspect the store.\n"
    Config.root
