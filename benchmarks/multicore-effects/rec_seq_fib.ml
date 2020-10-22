(* compute fib recursively *)

let rec fib n =
  match n with
  | 0 -> 0
  | 1 -> 1
  | n -> (fib (n-1) + fib (n-2))

let rec repeat f acc n =
  if n = 1 then let x = f () in (Printf.printf "%d\n%!" x; x)
  else repeat f (acc + (f ())) (n-1)

let run f n = ignore (Sys.opaque_identity (repeat f 0 n))

let _ =
  let iters = try int_of_string Sys.argv.(1) with _ -> 4 in
  let n = try int_of_string Sys.argv.(2) with _ -> 40 in
  (* default output should be 102334155 *)

  run (fun () -> fib n) iters
