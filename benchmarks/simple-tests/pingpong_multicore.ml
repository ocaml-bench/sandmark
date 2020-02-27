open Printf

module C = Domainslib.Chan

let num_domains = try int_of_string Sys.argv.(1) with _ -> 2
let chan_size = try int_of_string Sys.argv.(2) with _ -> 1
let total_messages = try int_of_string Sys.argv.(3) with _ -> 1000000

let messages_per_domain = total_messages / num_domains

type message = int ref

let queues = Array.init (num_domains-1) (fun i -> C.make chan_size)

let worker (in_queue : message C.t) (out_queue : message C.t) () =
    let rec loop iterations =
        if iterations > 0 then
            let msg_in = C.recv in_queue in
                incr msg_in;
                C.send out_queue msg_in;
                loop (iterations-1)
        else
            ()
    in loop messages_per_domain

let intermediate_consumers = Array.init (num_domains-2) (fun i -> Domain.spawn (worker queues.(i) queues.(i+1)))

let end_consumer () =
    let consume_queue = queues.(num_domains-2) in
        let rec consume_loop iterations = 
            if iterations > 0 then
                let msg = C.recv consume_queue in
                    if !msg == (num_domains-2) then
                        consume_loop (iterations-1)
                    else
                        failwith "Got message with wrong counter!"
            else
                ()
        in
            consume_loop messages_per_domain


let () =
    let produce_queue = queues.(0) in
        let rec produce_loop iterations =
            if iterations > 0 then
                begin
                    C.send produce_queue (ref 0);
                    produce_loop (iterations-1)
                end
            else
                ()
        in 
            
            begin
                let end_consumer_domain = Domain.spawn end_consumer in
                    produce_loop messages_per_domain;
                    Array.iter Domain.join intermediate_consumers;
                    Domain.join end_consumer_domain;
            end
    
