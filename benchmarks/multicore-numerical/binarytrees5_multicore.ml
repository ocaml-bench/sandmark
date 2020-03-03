module C = Domainslib.Chan

type message = Do of (unit -> unit) | Quit

type chan = {req: message C.t; resp: unit C.t}

let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
let max_depth = try int_of_string Sys.argv.(2) with _ -> 10

let channels =
  Array.init (num_domains - 1) (fun _ -> {req= C.make 1; resp= C.make 1})


type 'a tree = Empty | Node of 'a tree * 'a tree

let rec make d =
(* if d = 0 then Empty *)
  if d = 0 then Node(Empty, Empty)
  else let d = d - 1 in Node(make d, make d)

let rec check t =
  Domain.Sync.poll ();
  match t with
  | Empty -> 0
  | Node(l, r) -> 1 + check l + check r

let min_depth = 4
let max_depth = max (min_depth + 2) max_depth
let stretch_depth = max_depth + 1

let () =
  (* Gc.set { (Gc.get()) with Gc.minor_heap_size = 1024 * 1024; max_overhead = -1; }; *)
  let c = check (make stretch_depth) in
  Printf.printf "stretch tree of depth %i\t check: %i\n" stretch_depth c

let long_lived_tree = make max_depth

let values = Array.make num_domains 0

let calculate d st en ind =
  (* Printf.printf "st = %d en = %d\n" st en; *)
  let c = ref 0 in
  for _ = st to en do
  c := !c + check (make d)
  done;
  values.(ind) <- !c

let rec worker c () =
  match C.recv c.req with
  | Do f ->
      f () ; C.send c.resp () ; worker c ()
  | Quit ->
      ()

let loop_depths d =
  for i = 0 to  ((max_depth - d) / 2 + 1) - 1 do
    let d = d + i * 2 in
    let niter = 1 lsl (max_depth - d + min_depth) in
    let job i () = calculate d (i * niter / num_domains) (((i + 1) * niter / num_domains) - 1) i in
    Array.iteri (fun i c -> C.send c.req (Do (job i))) channels ;
    job (num_domains - 1) ();
    Array.iter (fun c -> C.recv c.resp) channels;
    let sum = Array.fold_left (+) 0 values in

    (* let domains = worker d (num_domains) 1 (niter/num_domains) in
    let sum = List.fold_left (+) 0 (List.map Domain.join domains) in *)
    (* let sum = calculate d 1 niter in *)
      Printf.printf "%i\t trees of depth %i\t check: %i\n" niter d sum ;
  done

let () =
  let domains = Array.map (fun c -> Domain.spawn (worker c)) channels in
  flush stdout;
  loop_depths min_depth;
  Printf.printf "long lived tree of depth %i\t check: %i\n"
    max_depth (check long_lived_tree);
    Array.iter (fun c -> C.send c.req Quit) channels ;
    Array.iter Domain.join domains
