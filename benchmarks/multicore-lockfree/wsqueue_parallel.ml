module WSQueue = Lockfree.WSQueue

let num_items = try int_of_string Sys.argv.(1) with _ -> 10000000

let make_and_populate_wsq _ =
  let q = WSQueue.create () in
    for i = 1 to num_items do
      WSQueue.push q i
    done; q

let loop_and_drain_queue wsq n () =
  let d = (Domain.self () :> int) in
  if (d = 0) then begin
    for _ = 1 to n do 
      WSQueue.pop wsq |> ignore
    done
  end else begin
    for _ = 1 to n do 
      WSQueue.steal wsq |> ignore
    done
  end
  
let () =
  let q = make_and_populate_wsq () in
  let t = Unix.gettimeofday () in
  loop_and_drain_queue q num_items ();
  Printf.printf "%f" (Unix.gettimeofday () -. t)