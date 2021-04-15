type 'a node = {value: 'a; next: 'a node option Atomic.t}

type 'a t = {top: 'a node option Atomic.t}

let create () = {top= Atomic.make None}

let rec add_node s n =
  let old_top = Atomic.get s.top in
  Atomic.set n.next old_top ;
  if Atomic.compare_and_set s.top old_top (Some n) then () else add_node s n

let push s x =
  let new_node = {value= x; next= Atomic.make None} in
  add_node s new_node

let rec remove_node s =
  let old_head = Atomic.get s.top in
  if old_head = None then None
  else
    match old_head with
    | None ->
        failwith "Internal inconsistency - got stack top with no value"
    | Some v ->
        if Atomic.compare_and_set s.top old_head (Atomic.get v.next) then
          Some v.value
        else remove_node s

let pop s = remove_node s
