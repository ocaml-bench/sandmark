(*
   Sudan function, which is recursive but not primitive recursive:
      https://en.wikipedia.org/wiki/Sudan_function
*)

let rec sudan n x y =
  if n = 0 then x + y
  else if y = 0 then x
  else begin
  	let inner = sudan n x (y-1) in
  	sudan (n-1) inner (inner+y)
  end

let rec repeat f acc n =
  if n = 1 then let x = f () in (Printf.printf "%d\n%!" x; x)
  else repeat f (acc + (f ())) (n-1)

let run f n = ignore (Sys.opaque_identity (repeat f 0 n))

let _ =
  let iters = try int_of_string Sys.argv.(1) with _ -> 10_000_000 in
  let n = try int_of_string Sys.argv.(2) with _ -> 2 in
  let x = try int_of_string Sys.argv.(3) with _ -> 2 in
  let y = try int_of_string Sys.argv.(4) with _ -> 2 in
  (* default output should be 15569256417 *)

  run (fun () -> sudan n x y) iters
