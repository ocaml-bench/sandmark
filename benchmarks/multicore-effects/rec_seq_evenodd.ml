(* even-odd MLton benchmark adapted *)

let rec even n =
  if n = 0 then true
  else odd (n-1)
and odd n =
  if n = 0 then false
  else even (n-1)

let rec repeat f acc n =
  if n = 1 then let x = f () in (Printf.printf "%B\n%!" x; x)
  else repeat f ((f ()) || acc) (n-1)

let run f n = ignore (Sys.opaque_identity (repeat f false n))

let _ =
  let iters = try int_of_string Sys.argv.(1) with _ -> 2 in
  let n = try int_of_string Sys.argv.(2) with _ -> 500_000_000 in
  (* expect result to be true for even numbers *)

  run (fun () -> (even n) && (not (odd n))) iters
