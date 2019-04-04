let queue = Spsc_queue.create 100001

let items_to_queue = int_of_string Sys.argv.(1)

let () = 
    let start = Unix.gettimeofday () in
    Domain.spawn (fun _ ->
    let items_queued = ref 0 in
    while !items_queued < items_to_queue do
        if Spsc_queue.enqueue queue !items_queued then
            incr items_queued;
    done) |> ignore;
    Domain.spawn (fun _ -> begin
        let c = ref 0 in
        while !c < items_to_queue do
        match Spsc_queue.dequeue queue with
        | None -> ()
        | Some(_) -> incr c
        done;
    let duration = Unix.gettimeofday () -. start in
    if !c != items_to_queue then
        Printf.printf "Item was lost - only found %d items\n" !c
    else
        Printf.printf "Queued and dequeued %d items in %f seconds = %f/ns per item\n" items_to_queue duration (1000000000.0*.duration /. (float_of_int items_to_queue))
    end) |> Domain.join |> ignore