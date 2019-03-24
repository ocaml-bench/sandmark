let queue = Spsc_queue.create 100001

let items_to_queue = int_of_string Sys.argv.(1)

let runs = 1000

let item_sum = ref 0

let () = 
    let start = Unix.gettimeofday () in
    for run = 0 to runs do
        for a = 0 to items_to_queue do
            Spsc_queue.enqueue queue a |> ignore;
            item_sum := !item_sum + a
        done; 
        for b = 0 to items_to_queue do
            match Spsc_queue.dequeue queue with
            | None -> failwith ("Lost an item at " ^ (string_of_int b) ^ "\n")
            | Some(c) -> item_sum := !item_sum - c
        done;
        if !item_sum != 0 then
        begin
            Printf.printf "Item was lost - item sum was not 0: %d\n" !item_sum;
            failwith "Lost item"
        end
    done;
    let duration = Unix.gettimeofday () -. start in
        Printf.printf "Queued and dequeued %d items in %f seconds = %f/ns per item\n" (runs*items_to_queue) duration (1000000000.0*.duration /. (float_of_int (runs*items_to_queue)))
