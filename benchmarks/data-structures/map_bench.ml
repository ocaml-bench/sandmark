let size = 10_000

let alist = List.init size (fun i -> (i, i))

module IntMap = Map.Make (struct
  type t = int

  let compare = compare
end)

let map = List.fold_left (fun m (i, j) -> IntMap.add i j m) IntMap.empty alist

let map_iter iterations =
  for i = 1 to iterations do
    IntMap.iter (fun key data_ -> Sys.opaque_identity ()) map
  done

let map_add iterations =
  assert (not (IntMap.mem size map)) ;
  let rec add m n = if n == 0 then m else add (IntMap.add n n m) (n - 1) in
  add IntMap.empty iterations

let map_add_duplicate iterations =
  let rec add m n =
    if n == 0 then m else add (IntMap.add n n (IntMap.add n n m)) (n - 1)
  in
  add IntMap.empty iterations

let map_remove iterations =
  let rec r o n =
    let m = if IntMap.is_empty o then map else o in
    if n == 0 then m
    else
      let deep_key = fst (IntMap.min_binding map) in
      r (IntMap.remove deep_key m) (n - 1)
  in
  r map iterations

let map_fold iterations =
  for i = 1 to iterations do
    ignore (Sys.opaque_identity (IntMap.fold (fun c k v -> c + k + v) map 0))
  done

let map_for_all iterations =
  for i = 1 to iterations do
    ignore
      (Sys.opaque_identity
         (IntMap.for_all (fun x y -> x < size && y < size) map))
  done

let map_find iterations =
  for i = 1 to iterations do
    ignore (Sys.opaque_identity (IntMap.find_opt i map))
  done

let map_map iterations =
  for i = 1 to iterations do
    ignore (Sys.opaque_identity (IntMap.map (fun a -> 2 * a) map))
  done

let () =
  let iterations = int_of_string Sys.argv.(2) in
  match Sys.argv.(1) with
  | "map_iter" ->
      map_iter iterations
  | "map_add" ->
      ignore (map_add iterations)
  | "map_add_duplicate" ->
      ignore (map_add_duplicate iterations)
  | "map_remove" ->
      ignore (map_remove iterations)
  | "map_fold" ->
      ignore (map_fold iterations)
  | "map_for_all" ->
      ignore (map_for_all iterations)
  | "map_find" ->
      ignore (map_find iterations)
  | "map_map" ->
      ignore (map_map iterations)
  | _ ->
      ()
