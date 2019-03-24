let stack = Treiber_stack.create ()

let items_to_stack = int_of_string Sys.argv.(1)

let () = 
    let start = Unix.gettimeofday () in
    for a = 0 to items_to_stack do
        Treiber_stack.push stack a
    done; 
    for b = 0 to items_to_stack do
        match Treiber_stack.pop stack with
        | None -> failwith ("Lost an item at " ^ (string_of_int b) ^ "\n")
        | Some(_) -> ()
    done;
    if Treiber_stack.pop stack != None then
        Printf.printf "Popped %d items and yet stack is not empty. Fail." items_to_stack
    else
        let duration = Unix.gettimeofday () -. start in
        Printf.printf "Pushed and popped %d items in %f seconds = %f/ms per item\n" items_to_stack duration (1000.0*.duration /. (float_of_int items_to_stack))