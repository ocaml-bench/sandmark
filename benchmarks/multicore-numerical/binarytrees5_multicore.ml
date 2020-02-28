let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
let max_depth = try int_of_string Sys.argv.(2) with _ -> 10

type 'a tree = Empty | Node of 'a tree * 'a tree

let rec make d =
(* if d = 0 then Empty *)
  if d = 0 then Node(Empty, Empty)
  else let d = d - 1 in Node(make d, make d)

let rec check = function Empty -> 0 | Node(l, r) -> 1 + check l + check r

let min_depth = 4
let max_depth = max (min_depth + 2) max_depth
let stretch_depth = max_depth + 1

let () =
  (* Gc.set { (Gc.get()) with Gc.minor_heap_size = 1024 * 1024; max_overhead = -1; }; *)
  let c = check (make stretch_depth) in
  Printf.printf "stretch tree of depth %i\t check: %i\n" stretch_depth c

let long_lived_tree = make max_depth

let calculate d st en =
  (* Printf.printf "st = %d en = %d\n" st en; *)
  let c = ref 0 in
  for _ = st to en do
  c := !c + check (make d)
  done;
  !c

(* let vals = Array.init num_domains 0 *)
let rec worker d n st inc =
(* Printf.printf "worker "; *)
  if n = 0 then []
  else Domain.spawn (fun _ -> calculate d st (st + inc))
  :: worker d (n-1) (st+inc) inc

let rec worker' d n st inc =
(* Printf.printf "worker "; *)
  if n = 0 then []
  else calculate d st (st + inc)
  :: worker' d (n-1) (st+inc) inc

let loop_depths d =
  for i = 0 to  ((max_depth - d) / 2 + 1) - 1 do
    let d = d + i * 2 in
    let niter = 1 lsl (max_depth - d + min_depth) in
    let domains = worker d (num_domains) 0 (niter/num_domains) in
    let sum = List.fold_left (+) 0 (List.map Domain.join domains) in
    (* let sum = calculate d 1 niter in *)
      Printf.printf "%i\t trees of depth %i\t check: %i\n" niter d sum ;
  done

let () =
  flush stdout;
  loop_depths min_depth;
  Printf.printf "long lived tree of depth %i\t check: %i\n"
    max_depth (check long_lived_tree);
