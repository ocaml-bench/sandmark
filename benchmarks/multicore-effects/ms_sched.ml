module MSQueue = Lockfree.MSQueue

effect Fork  : (unit -> unit) -> unit
effect Yield : unit
effect Exit : unit

let fork f = perform (Fork f)
let yield () = perform Yield
let exit () = perform Exit

let run_q = MSQueue.create ()

(* A concurrent round-robin scheduler *)
let run main =
  let exiting_flag = Atomic.make false in
  let enqueue k = MSQueue.push run_q k in
  let rec dequeue () =
    match MSQueue.pop run_q with
    | None ->
        if Atomic.get exiting_flag then () else (Domain.Sync.cpu_relax(); dequeue ())
    | Some(y) -> (continue y ())
  in
  let rec spawn f =
    match f () with
    | () -> dequeue ()
    | exception e ->
        ( print_string (Printexc.to_string e);
          dequeue () )
    | effect Yield k ->
        ( enqueue k; dequeue () )
    | effect (Fork f) k ->
        ( enqueue k; spawn f )
    | effect Exit _ ->
      ( Atomic.set exiting_flag true; dequeue () )
  in
  spawn main

let start n_domains f =
    let rec spawn_domain n =
      if n > 1 then
        begin
          Domain.spawn (fun _ -> run (fun _ -> ())) |> ignore;
          spawn_domain (n-1)
        end
      else if n == 1 then
        begin
          Domain.spawn (fun _ -> run f) |> Domain.join;
        end
      in spawn_domain n_domains