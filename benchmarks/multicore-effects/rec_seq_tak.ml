(* compute tak function *)

let rec tak x y z =
  if y < x then tak (tak (x-1) y z) (tak (y-1) z x) (tak (z-1) x y)
           else z

let rec repeat f acc n =
  if n = 1 then let x = f () in (Printf.printf "%d\n%!" x; x)
  else repeat f (acc + (f ())) (n-1)

let run f n = ignore (Sys.opaque_identity (repeat f 0 n))

let _ =
  let iters = try int_of_string Sys.argv.(1) with _ -> 1 in
  let x = try int_of_string Sys.argv.(2) with _ -> 40 in
  let y = try int_of_string Sys.argv.(3) with _ -> 20 in
  let z = try int_of_string Sys.argv.(4) with _ -> 11 in
  (* default output should be 12 *)

  run (fun () -> tak x y z) iters
