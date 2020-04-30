(* The Computer Language Benchmarks Game
 * https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
 *
 * Contributed by Sebastien Loisel
 * Cleanup by Troestler Christophe
 * Modified by Mauricio Fernandez
 *)

module C = Domainslib.Chan

let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
let n = try int_of_string Sys.argv.(2) with _ -> 2000

type message = Do of (unit -> unit) | Quit
type chan = {req: message C.t; resp: unit C.t}

let channels =
  Array.init (num_domains - 1) (fun _ -> {req= C.make_bounded 1; resp= C.make_bounded 1})

let eval_A i j = 1. /. float (((i + j) * (i + j + 1) / 2) + i + 1)

let eval_A_times_u u v s e =
  let n = Array.length v - 1 in
  for i = s to e do
    let vi = ref 0. in
    for j = 0 to n do
      vi := !vi +. (eval_A i j *. u.(j))
    done ;
    v.(i) <- !vi
  done

let divvy_up1 u v =
  let job i () =
    eval_A_times_u u v (i * n / num_domains) (((i + 1) * n / num_domains) - 1)
  in
  Array.iteri (fun i c -> C.send c.req (Do (job i))) channels ;
  job (num_domains - 1) ();
  Array.iter (fun c -> C.recv c.resp) channels

let eval_At_times_u u v s e =
  let n = Array.length v - 1 in
  for i = s to e do
    let vi = ref 0. in
    for j = 0 to n do
      vi := !vi +. (eval_A j i *. u.(j))
    done ;
    v.(i) <- !vi
  done

let divvy_up2 u v =
  let job i () =
    eval_At_times_u u v (i * n / num_domains) (((i + 1) * n / num_domains) - 1)
  in
  Array.iteri (fun i c -> C.send c.req (Do (job i))) channels ;
  job (num_domains - 1) ();
  Array.iter (fun c -> C.recv c.resp) channels

let eval_AtA_times_u u v =
  let w = Array.make (Array.length u) 0.0 in
  divvy_up1 u w ; divvy_up2 w v

let rec worker c () =
  match C.recv c.req with
  | Do f ->
      f () ; C.send c.resp () ; worker c ()
  | Quit ->
      ()

let () =
  let domains = Array.map (fun c -> Domain.spawn (worker c)) channels in
  let u = Array.make n 1.0 and v = Array.make n 0.0 in
  for _i = 0 to 9 do
    eval_AtA_times_u u v ; eval_AtA_times_u v u
  done ;
  let vv = ref 0.0 and vBv = ref 0.0 in
  for i = 0 to n - 1 do
    vv := !vv +. (v.(i) *. v.(i)) ;
    vBv := !vBv +. (u.(i) *. v.(i))
  done ;
  Array.iter (fun c -> C.send c.req Quit) channels ;
  Array.iter Domain.join domains ;
  Printf.printf "%0.9f\n" (sqrt (!vBv /. !vv))
