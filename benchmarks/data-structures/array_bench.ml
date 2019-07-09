let create_array size =
  let a = Array.make size 0 in
  Array.mapi (fun i _ -> i) a

let length = 1000

let array_iter iterations =
  let a = create_array length in
  for i = 1 to iterations do
    Sys.opaque_identity
      (Array.iter (fun i -> if i > 2 * length then assert false) a)
  done

let array_forall iterations =
  let a = create_array length in
  for i = 1 to iterations do
    Sys.opaque_identity (assert (Array.for_all (fun i -> i < 2 * length) a))
  done

let array_fold iterations =
  let a = create_array length in
  for i = 1 to iterations do
    ignore (Sys.opaque_identity (Array.fold_left (fun c s -> c + s) 0 a))
  done

let () =
  let iterations = int_of_string Sys.argv.(2) in
  match Sys.argv.(1) with
  | "array_fold" ->
      array_fold iterations
  | "array_forall" ->
      array_forall iterations
  | "array_iter" ->
      array_iter iterations
  | _ ->
      ()
