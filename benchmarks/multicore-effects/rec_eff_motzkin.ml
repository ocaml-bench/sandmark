(*
   "the n'th Motzkin number is the number of different ways of drawing
   non-intersecting chords between n points on a circle
   (not necessarily touching every point by a chord)."
    https://en.wikipedia.org/wiki/Motzkin_number
    See here for input/outputs: https://oeis.org/A001006/list
*)

effect E : unit

let rec sum f i stop acc =
	if i > stop then acc
  else sum f (i+1) stop (acc + (f i))

let rec motz n =
	if n <= 1 then 1
	else begin
		let limit = n - 2 in
		let product i =
        (try motz i with effect E _ -> assert false)
      * (try motz (limit -i) with effect E _ -> assert false)
    in
		(try motz (n-1) with effect E _ -> assert false) +
    (try sum product 0 limit 0 with effect E _ -> assert false)
	end

let rec repeat f acc n =
  if n = 1 then let x = f () in (Printf.printf "%d\n%!" x; x)
  else repeat f (acc + (f ())) (n-1)

let run f n = ignore (Sys.opaque_identity (repeat f 0 n))

let _ =
  let iters = try int_of_string Sys.argv.(1) with _ -> 4 in
  let n = try int_of_string Sys.argv.(2) with _ -> 21 in
  (* default output should be 142547559 *)

  run (fun () -> motz n) iters

