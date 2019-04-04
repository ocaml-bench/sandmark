type 'a node = { mutable value : 'a option; next : 'a node option Atomic.t }

type 'a t = {
    head: 'a node Atomic.t;
    tail: 'a node Atomic.t
}

let create () = 
    let first_node = { value = None ; next = Atomic.make None } in   
    { head = (Atomic.make first_node); tail = (Atomic.make first_node) }

let rec add_node q n =
    let tail = Atomic.get q.tail in
        let tail_next = Atomic.get tail.next in
            if tail == Atomic.get q.tail then
                match tail_next with
                | None -> 
                    if Atomic.compare_and_set tail.next tail_next (Some n) then
                        begin
                            ignore(Atomic.compare_and_set q.tail tail n);
                            ()
                        end
                    else
                        add_node q n
                | Some(tail_next_node) -> 
                    begin 
                        ignore(Atomic.compare_and_set q.tail tail tail_next_node);
                        add_node q n
                    end
            else
                add_node q n

let enqueue q x = 
    let new_node = { value = (Some x) ; next = Atomic.make None } in
        add_node q new_node

let rec remove_node q =
    let head = Atomic.get q.head in
        let tail = Atomic.get q.tail in 
            let next = Atomic.get head.next in
                if head == Atomic.get q.head then
                    if head == tail then (* list is probably empty *)
                        match next with
                        | None -> None (* list is definitely empty *)
                        | Some(next_node) -> (* tail has fallen behind *)
                            begin (* try to advance it *)
                                ignore(Atomic.compare_and_set q.tail tail next_node);
                                remove_node q
                            end
                    else
                        match next with 
                        | None -> failwith "Internal inconsistency - next should never be None if queue non-empty"
                        | Some(next_node) -> if Atomic.compare_and_set q.head head next_node then
                                                let value = next_node.value in
                                                    begin
                                                        next_node.value <- None;
                                                        match value with
                                                        | None -> failwith "Internal inconsistency - have extracted dummy node"
                                                        | Some(v) -> Some(v)
                                                    end
                                            else
                                                remove_node q
                else
                    remove_node q
                
let dequeue q =
    remove_node q