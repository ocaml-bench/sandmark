module Ctrie = struct
  (* Concurrent, hash array mapped trie based on -
      Prokopec, A. et al. (2011)
      Cache-Aware Lock-Free Concurrent Hash Tries. Technical Report, 2011. *)

  (* configuration parameters *)
  let shift = 5

  (* data definition *)
  type node =
    | Empty
    | Cnode of { map : int ; nodes : (node Atomic.t) array }
    | Inode of { key : int ; values : int list ; delete : bool }

  type t = node Atomic.t

  (* helper functions *)

  (* detect flag of key in map *)
  let flag k l _map =
    let i =
      (k lsr (l * shift))
      land
      ((1 lsl shift) - 1) in
    i

  (* check if flag is set *)
  let set i map =
    ((1 lsl i) land map) <> 0

  (* detect position in array *)
  let pos flag map =
    (Base.Int.popcount (((1 lsl flag) - 1) land map))

  (* create empty map *)
  let empty () = Atomic.make Empty

  (* insert key and value binding into map *)
  let rec insert_aux k v l t =
    match Atomic.get t with
    | Empty ->
        let i = flag k l 0 in
        let map = 1 lsl i in
        let nodes = [|
          (Atomic.make (Inode {key = k ; values = [v] ; delete = false}))
        |] in
        let new_node = Cnode { map ; nodes } in
        Atomic.compare_and_set t Empty new_node
    | Cnode { map ; nodes } as c ->
        let i = flag k l map in
        if (set i map) then begin
          let p = pos i map in
          insert_aux k v (l+1) nodes.(p)
        end else begin
          let map = (1 lsl i) lor (map) in
          let p = pos i map in
          let old_len = Array.length nodes in
          let new_nodes = Array.init (old_len + 1) (fun i ->
            if i < p then nodes.(i) else
              if i = p then
                Atomic.make (Inode {key = k; values = [v] ; delete = false})
              else
                nodes.(i-1)) in
          let new_node = Cnode { map ; nodes = new_nodes } in
          Atomic.compare_and_set t c new_node
        end
    | Inode { key ; values ; delete} as inode ->
        if key = k then begin
          let new_values = v :: values in
          let new_node = Inode { key ; values = new_values ; delete } in
          Atomic.compare_and_set t inode new_node
        end else begin
          let i = flag key l 0 in
          let ni = flag k l 0 in
          let map = (1 lsl i) lor 0 in
          let map = (1 lsl ni) lor map in
          let nodes = 
          if (ni > i) then
            ([|
              Atomic.make (Inode { key ; values ; delete }) ;
              Atomic.make (Inode { key = k ; values = [v] ; delete = false })
              |], true)
          else if (ni < i) then
            ([|
              Atomic.make (Inode { key = k ; values = [v] ; delete = false }) ;
              Atomic.make (Inode { key ; values ; delete })
              |], true)
          else begin
            let i = flag key (l+1) 0 in
            let nmap = (1 lsl i) lor 0 in
            let nnodes = [|Atomic.make (Inode {key ; values; delete})|] in
            ([|
              Atomic.make (Cnode { map = nmap ; nodes = nnodes })
            |], false)
          end in
          let (nodes, new_level) = nodes in
          let new_node = Cnode { map ; nodes } in
          Atomic.compare_and_set t inode new_node && new_level
        end

  let rec insert k v t = 
    if insert_aux k v 0 t then () else insert k v t

  (* check if key in map *)
  let rec mem k l t =
    match Atomic.get t with
    | Empty -> false
    | Cnode { map ; nodes } ->
        let f = flag k l map in
        if (set f map) then begin
          let p = pos f map in
          mem k (l+1) nodes.(p)
        end else begin
          false
        end
    | Inode { key ; _ } -> if key = k then true else false

  let mem k t = mem k 0 t
end

let num_elems   = try int_of_string Sys.argv.(1) with _ -> 10_000_000
let ins_percent = try int_of_string Sys.argv.(2) with _ -> 50

let state_key = Domain.DLS.new_key Random.State.make_self_init

let rand_int n =
  let state = Domain.DLS.get state_key in
  Random.State.int state n

let work tree _ =
  if rand_int 100 >= ins_percent then
    ignore (Ctrie.mem (rand_int 10000) tree)
  else
    ignore (Ctrie.insert (rand_int 10000) 0 tree)

let _ =
  let tree = Ctrie.empty () in
  let work = work tree in
  for i in range 0 to (num_elems - 1) do
    work i
  done
