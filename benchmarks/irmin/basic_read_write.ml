(* Simple example of reading and writing in a Irmin-mem repository *)
open Lwt.Infix
open Printf

(* config for informing the system where the branches are created *)
(* module Config = struct
let root = "/tmp/irmin/test"

let init () =
  let _ = Sys.command (Printf.sprintf "rm -rf %s" root) in
  let _ = Sys.command (Printf.sprintf "mkdir -p %s" root) in
  ()

(* Install the FS listener. *)
end *)

let info msg = 
  let date = Int64.of_float (Unix.gettimeofday ()) in
  let author = Printf.sprintf "TESTS" in
  Irmin.Info.v ~date ~author msg

module Store = Irmin_mem.KV (Irmin.Contents.String) 

(* random number generation to create a uniform distribution of read and writes *)
let get_random num_iter = Random.int num_iter

let update t k v =
  let msg = sprintf "Updating /%s" (String.concat "/" k) in
  Store.set_exn t ~info:(fun () -> info msg) k v

let read_exn t k =
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

(* creates unique branch names *)
let branch_list num_branches =  make num_branches "branch"


let branch_clone src dst = (* gives out (Store.t, Store.t) Lwt.t *)
  Store.clone ~src:src ~dst:dst >>= fun dst -> Lwt.return (src, dst)

let n_branch_clone src num_branches = (* generates (Store.t, Store.t) list Lwt.t *)
  Lwt_list.map_p (branch_clone src) (branch_list num_branches)

let branch_update _src branch_dst key_list log_list = (* gives out (Store.t, Store.t) Lwt.t *)
  Lwt_list.map_p (fun (key, content) -> (* print_endline "branch_update"; *) update branch_dst key content) (zip key_list log_list) >>= fun _ -> Lwt.return_unit

let branch_merge src dst =
  Store.merge_into ~info:(fun () -> info "t: Merge with 'x'") dst ~into:src >>= function
  | Error _ -> failwith "conflict!"
  | Ok () -> Lwt.return_unit

let branch_read _src branch_dst key_list = 
  Lwt_list.map_p (fun key -> read_exn branch_dst key) key_list >>= fun _ -> Lwt.return_unit

(* does all the writes *)
let write_op key_list log_list src_dst_tuple_list =
  (* Printf.printf "writes\n"; *)
  Lwt_list.map_p (fun (src, branch_dst) -> branch_update src branch_dst key_list log_list) src_dst_tuple_list >>= fun _ ->
  Lwt.return(src_dst_tuple_list)

(* does all the reads *)
let read_op key_list src_dst_tuple_list =
  (* Printf.printf "reads\n"; *)
  Lwt_list.map_p (fun (src, branch_dst) -> branch_read src branch_dst key_list) src_dst_tuple_list

(* carries out the iterations in the benchmark *)
let benchmark_loop num_iter num_writes num_keys src_dst_tuple_list =
  (* print_endline "inside_repeat_stuff"; *)
  let log_list = make num_keys "content" in
  let key_list = (make num_keys ".txt") |> List.map (fun x -> ["root"; "misc"; x]) in
  let rec repeat_stuff' acc read_or_write_flag num_iter src_dst_tuple_list =
    (* Printf.printf "%d %d\n" num_iter num_writes;  *)
    match acc < num_iter with
    | true -> (match read_or_write_flag < num_writes with
              | true -> (* print_endline "before_writes";  *)
                         write_op key_list log_list src_dst_tuple_list >>= fun _ -> 
                        (* print_endline "repeat_stuff_inside";  *)
                         repeat_stuff' (acc + 1) (get_random num_iter) num_iter src_dst_tuple_list
              | false -> read_op key_list src_dst_tuple_list >>= fun _ -> 
                         repeat_stuff' (acc + 1) (get_random num_iter) num_iter src_dst_tuple_list);
    | false -> Lwt.return src_dst_tuple_list
  in
  repeat_stuff' 0 (get_random num_iter) num_iter src_dst_tuple_list

let main num_branches num_keys num_writes num_iter =
  let config = Irmin_mem.config () in
  Store.Repo.v config >>= fun repo ->
  (* print_endline "repo"; *)
  Store.master repo >>= fun t ->
  (* print_endline "clone"; *)
  n_branch_clone t num_branches >>= fun src_dst_tuple_list -> 
  (* print_endline "repeat_stuff_pre"; *)
  benchmark_loop num_iter num_writes num_keys src_dst_tuple_list >>= fun src_dst ->
  Lwt_list.map_p (fun (x,y) -> branch_merge x y) src_dst >>= fun _ -> Lwt.return_unit

let () =
  (* let _ = Sys.command (Printf.sprintf "rm -rf %s" Config.root) in *)
  let num_branches = Sys.argv.(1) |> int_of_string in
  let num_keys = Sys.argv.(2) |> int_of_string in
  let percent_writes = Sys.argv.(3) |> int_of_string in
  let num_iter = Sys.argv.(4) |> int_of_string in
  let num_writes = (percent_writes * num_iter) / 100 in
  (* Printf.printf "%d\n" num_writes; *)
  Lwt_main.run (main num_branches num_keys num_writes num_iter)
