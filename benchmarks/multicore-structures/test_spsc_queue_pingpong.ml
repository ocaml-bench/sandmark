open Printf

let num_threads = int_of_string Sys.argv.(1)
let num_messages = int_of_string Sys.argv.(2)

type message = Ping of int | Bye

let queue_size = num_messages+1
let last_queue : message Spsc_queue.t ref = ref (Spsc_queue.create queue_size)
let first_queue = !last_queue

let rec spinning_enqueue q m =
    match Spsc_queue.enqueue q m with
    | true -> ()
    | false -> Domain.Sync.cpu_relax(); spinning_enqueue q m

let rec ping_pong_messages n in_queue out_queue =
    match Spsc_queue.dequeue in_queue with
    | None -> Domain.Sync.cpu_relax(); ping_pong_messages n in_queue out_queue
    | Some(m) -> 
    begin
        spinning_enqueue out_queue m;
        if m == Bye then
            ()
        else
            ping_pong_messages n in_queue out_queue
    end

let populate_first_queue () = for n = 0 to num_messages-1 do
    spinning_enqueue first_queue (if n < num_messages-1 then Ping(n) else Bye)
done

let rec start_domains n lim domains =
    if n == lim then
        List.rev domains
    else
        let new_out_queue = Spsc_queue.create queue_size in
            let new_in_queue = !last_queue in
                let new_domain = Domain.spawn (fun _ -> ping_pong_messages n new_in_queue new_out_queue) in
                begin
                    last_queue := new_out_queue;
                    start_domains (n+1) lim (new_domain::domains)
                end

let () = populate_first_queue (); let domains = start_domains 0 num_threads [] in
            ignore(List.map (fun domain -> Domain.join domain) domains)