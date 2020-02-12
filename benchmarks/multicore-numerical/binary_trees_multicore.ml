module C = Domainslib.Chan

type message = Do of (unit -> unit) | Quit

type chan = {req: message C.t; resp: unit C.t}

let num_domains = try int_of_string Sys.argv.(2) with _ -> 1

let channels =
  Array.init num_domains (fun _ -> {req= C.make 1; resp= C.make 0})

type 'a tree = Empty | Node of 'a tree * 'a tree

let rec make d =
(* if d = 0 then Empty *)
  if d = 0 then Node(Empty, Empty)
  else let d = d - 1 in Node(make d, make d)

let rec check = function Empty -> 0 | Node(l, r) -> 1 + check l + check r

let min_depth = 4
let max_depth = (let n = try int_of_string(Array.get Sys.argv 1) with _ -> 10 in
                 max (min_depth + 2) n)
let stretch_depth = max_depth + 1

let () =
  (* Gc.set { (Gc.get()) with Gc.minor_heap_size = 1024 * 1024; max_overhead = -1; }; *)
  let c = check (make stretch_depth) in
  Printf.printf "stretch tree of depth %i\t check: %i\n" stretch_depth c

let long_lived_tree = make max_depth

let eva d st en =
   for i = st to en do
     let d = d + i * 2 in
     let niter = 1 lsl (max_depth - d + min_depth) in
     let c = ref 0 in
       for _ = 1 to niter do c := !c + check (make d) done;
       Printf.printf "%i\t trees of depth %i\t check: %i\t d = %i\n" niter d !c d;
     done

let loop_depths d =
  let  e = (max_depth - d)/2 + 1 in
  let job i () = eva d (i * e / num_domains) (((i + 1) * e / num_domains) - 1)
  in
  Array.iteri (fun i c -> C.send c.req (Do (job i))) channels ;
  Array.iter (fun c -> C.recv c.resp) channels

let rec worker c () =
  match C.recv c.req with
  | Do f ->
      f () ; C.send c.resp () ; worker c ()
  | Quit ->
      ()

let () =
  let domains = Array.map (fun c -> Domain.spawn (worker c)) channels in
  flush stdout;
  loop_depths min_depth;
  Printf.printf "long lived tree of depth %i\t check: %i\n"
      max_depth (check long_lived_tree);
  Array.iter (fun c -> C.send c.req Quit) channels ;
  Array.iter Domain.join domains
