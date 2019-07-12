module IntSet = Set.Make (struct
  type t = int

  let compare = compare
end)

let rec add_to_set s x =
  if x > 0 then add_to_set (IntSet.add x s) (x - 1) else s

let length = 1000

let create_set size =
  let s = IntSet.empty in
  add_to_set s size

let set_fold iterations =
  let s = create_set length in
  for i = 1 to iterations do
    ignore (Sys.opaque_identity (IntSet.fold (fun c s -> c + s) s 0))
  done

let set_mem iterations =
  let s = create_set length in
  for i = 1 to iterations do
    Sys.opaque_identity (assert (IntSet.mem i s == (i <= length)))
  done

let rec add_rem s n =
  if n == 0 then s
  else
    let with_n = IntSet.add n s in
    let without_n = IntSet.remove n with_n in
    add_rem without_n (n - 1)

let set_add_rem iterations =
  let s = create_set length in
  ignore (Sys.opaque_identity (add_rem s iterations))

let () =
  let iterations = int_of_string Sys.argv.(2) in
  match Sys.argv.(1) with
  | "set_fold" ->
      set_fold iterations
  | "set_mem" ->
      set_mem iterations
  | "set_add_rem" ->
      set_add_rem iterations
  | _ ->
      ()
