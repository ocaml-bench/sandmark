let queue = Ms_queue.create ()

let items_to_queue = int_of_string Sys.argv.(1)

let item_sum = ref 0

let () = 
    let start = Unix.gettimeofday () in
    for a = 0 to items_to_queue do
        Ms_queue.enqueue queue a;
        item_sum := !item_sum + a
    done; 
    for b = 0 to items_to_queue do
        match Ms_queue.dequeue queue with
        | None -> failwith ("Lost an item at " ^ (string_of_int b) ^ "\n")
        | Some(c) -> item_sum := !item_sum - c
    done; 
    let duration = Unix.gettimeofday () -. start in
    if !item_sum != 0 then
        Printf.printf "Item was lost - item sum was not 0: %d\n" !item_sum
    else
        Printf.printf "Queued and dequeued %d items in %f seconds = %f/ms per item\n" items_to_queue duration (1000.0*.duration /. (float_of_int items_to_queue))