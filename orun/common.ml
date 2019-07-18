type source_line =
  { filename: string option
  ; function_name: string option
  ; line: int
  ; offset: int }

type sample =
  { current: source_line
  ; call_stack: source_line list
  ; timestamp: int
  ; thread_id: int
  ; cpu: int
  ; id: int }

type counts = {mutable self_time: int; mutable total_time: int}

type aggregate_result = (source_line, counts) Hashtbl.t

type compressed_sample =
  {stack: int list; timestamp: int; thread_id: int; cpu: int; id: int}

let rec take l n =
  match (l, n) with
  | [], _ ->
      []
  | _, 0 ->
      []
  | h :: tl, _ ->
      h :: take tl (n - 1)

let get_or d o = match o with None -> d | Some x -> x

let invert_hashtbl h =
  Hashtbl.fold
    (fun k v c -> Hashtbl.add c v k ; c)
    h
    (Hashtbl.create (Hashtbl.length h))
