
type 'a t =
  S: { data: 'a option Atomic.t array
     ; hash: 'a -> int
     ; eq: 'a -> 'a -> bool
     ; maxload: float
     }
    -> 'a t

exception Full

type 'a hashset = 'a t

let make ~hash ~eq ~capacity ~maxload =
  S { data = Array.init capacity (fun _ -> Atomic.make None)
    ; hash = hash
    ; eq = eq
    ; maxload = maxload
    }

let size (S s) =
  Seqbasis.reduce 10000 (+) 0 (0, Array.length s.data) (fun i ->
    if Option.is_some (Atomic.get s.data.(i)) then 1 else 0)

let capacity (S s) =
  Array.length s.data

let insert' (S s) x force =
  let n = Array.length s.data in
  let tolerance = 2 * Float.to_int (Float.ceil (1.0 /. (1.0 -. s.maxload))) in
  let rec loop i probes =
    if not force && probes >= tolerance then
      raise Full
    else if i >= n then
      loop 0 probes
    else begin
      let cell = s.data.(i) in
      let current = Atomic.get cell in
      match current with
      | Some y ->
          if s.eq x y then
            false
          else
            loop (i+1) (probes+1)
      | None ->
          if Atomic.compare_and_set cell current (Some x) then
            true
          else
            loop i probes
    end
  in
  let start = (s.hash x) mod (Array.length s.data) in
  loop start 0


let insert s x = insert' s x false


let resize input =
  let S s = input in
  let newcap = 2 * capacity input in
  let result = make ~hash:s.hash ~eq:s.eq ~maxload:s.maxload ~capacity:newcap in
  Forkjoin.parfor 1000 (0, Array.length s.data) (fun i ->
    match Atomic.get (s.data.(i)) with
    | None -> ()
    | Some x -> (insert' result x true |> ignore)
  );
  result


let to_list (S s) =
  let push_Some cell xs =
    match Atomic.get cell with
    | Some x -> x :: xs
    | None -> xs
  in
  Array.fold_right push_Some s.data []

