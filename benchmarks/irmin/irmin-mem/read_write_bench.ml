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

module Store = Irmin_mem.KV (Irmin.Contents.String) (* right now using Irmin_unix.Git.FS, Change to Irmin_mem before commit. *)

let update t k v =
  let msg = sprintf "Updating /%s" (String.concat "/" k) in
  print_endline msg;
  Store.set_exn t ~info:(info "%s" msg) k v

let read_exn t k =
  let msg = sprintf "Reading /%s" (String.concat "/" k) in
  print_endline msg;
  Store.get t k

let make n x = 
  let rec make' acc n x =
    match n with 
    | 0 -> [] 
    | _ -> make' (((string_of_int n) ^ x) :: acc) (n-1) x
  in
  make' [] n x

let zip a b =
  let rec zip' acc a b =
    match (a, b) with
    | (hd1 :: tl1, hd2 :: tl2) -> zip' ((hd1, hd2) :: acc) tl1 tl2
    | (_, _) -> []
  in
  zip' [] a b

let branch_list num_branches =  make num_branches "branch"

let c_clone src dst = (* gives out (Store.t, Store.t) Lwt.t *)
  Store.clone ~src:src ~dst:dst >>= fun dst -> print_endline "cloning ..."; Lwt.return (src, dst)

let n_c_clone src num_branches = (* generates (Store.t, Store.t) list Lwt.t *)
  Lwt_list.map_p (c_clone src) (branch_list num_branches)

let c_update _src branch_dst key_list log_list = (* gives out (Store.t, Store.t) Lwt.t *)
  Lwt_list.map_p (fun (key, content) -> update branch_dst key content) (zip key_list log_list) >>= fun _ -> Lwt.return_unit

let c_merge src dst =
  Store.merge_into ~info:(info "t: Merge with 'x'") dst ~into:src >>= function
  | Error _ -> failwith "conflict!"
  | Ok () -> print_endline "merging ..."; Lwt.return_unit


let c_read _src branch_dst key_list = 
  Lwt_list.map_p (fun key -> read_exn branch_dst key) key_list >>= fun _ -> Lwt.return_unit


let writes key_list log_list src_dst_tuple_list =
  Lwt_list.map_p (fun (src, branch_dst) -> c_update src branch_dst key_list log_list) src_dst_tuple_list >>= fun _ ->
  Lwt.return(src_dst_tuple_list)

let reads key_list src_dst_tuple_list =
  Lwt_list.map_p (fun (src, branch_dst) -> c_read src branch_dst key_list) src_dst_tuple_list

let repeat_stuff num_iter num_writes num_keys src_dst_tuple_list =
  let num_writes = (num_writes / 100) * num_iter in
  let log_list = make num_keys "content" in
  let key_list = (make num_keys ".txt") |> List.map (fun x -> ["root"; "misc"; x]) in
  let rec repeat_stuff' acc num_iter src_dst_tuple_list =
    match acc < num_iter with
    | true -> (match acc < num_writes with
              | true -> ignore (writes key_list log_list src_dst_tuple_list); repeat_stuff' (acc + 1) num_iter src_dst_tuple_list
              | false -> ignore (reads key_list src_dst_tuple_list); repeat_stuff' (acc + 1) num_iter src_dst_tuple_list);
    | false -> Lwt.return src_dst_tuple_list
  in
  repeat_stuff' 0 num_iter src_dst_tuple_list

let main num_branches num_keys num_writes num_iter =
  Config.init ();
  let config = Irmin_git.config ~bare:true Config.root in
  Store.Repo.v config >>= fun repo ->
  Store.master repo >>= fun t ->
  n_c_clone t num_branches >>= fun src_dst_tuple_list -> 
  repeat_stuff num_iter num_writes num_keys src_dst_tuple_list >>= fun src_dst ->
  Lwt_list.map_p (fun (x,y) -> c_merge x y) src_dst >>= fun _ -> Lwt.return_unit

let () =
  Printf.printf
    "This example creates a Git/mem repository in %s and use it to read \n\
     and write data:\n"
    Config.root;
  let _ = Sys.command (Printf.sprintf "rm -rf %s" Config.root) in
  let num_branches = Sys.argv.(1) |> int_of_string in
  let num_keys = Sys.argv.(2) |> int_of_string in
  let num_writes = Sys.argv.(3) |> int_of_string in
  let num_iter = Sys.argv.(4) |> int_of_string in

  let main' () = main num_branches num_keys num_writes num_iter in

  Printf.printf "number-reads == %d\n number-writes == %d\n" (num_writes) (100 - num_writes);
  
  Lwt_main.run (main' ());

  Printf.printf "You can now run `cd %s && tig` to inspect the store (if using git filesystem).\n"
    Config.root
