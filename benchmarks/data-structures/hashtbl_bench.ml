module IntHash = struct
  type t = int

  let equal i j = i = j

  let hash i = i land max_int
end

module IntHashtbl = Hashtbl.Make (IntHash)

let gen_test_int_replace_and_find n tbl =
  let replace () =
    for i = 0 to n - 1 do
      Hashtbl.replace tbl i i
    done
  in
  let find () =
    for i = 0 to n - 1 do
      let (_ : int option) = Hashtbl.find_opt tbl i in
      ()
    done
  in
  (replace, find)

let gen_test_int_replace_and_find_int_hash n tbl =
  let replace () =
    for i = 0 to n - 1 do
      IntHashtbl.replace tbl i i
    done
  in
  let find () =
    for i = 0 to n - 1 do
      let (_ : int option) = IntHashtbl.find_opt tbl i in
      ()
    done
  in
  (replace, find)

let n = 1_000_000

let create_hashtbl size =
  let h = Hashtbl.create size in
    for i = 1 to size do
      Hashtbl.add h i i
    done; h

let hashtbl_iter iterations =
  let h = create_hashtbl n in
  for i = 1 to iterations do
    Hashtbl.iter (fun key data_ -> Sys.opaque_identity ()) h
  done

let hashtbl_fold iterations =
  let h = create_hashtbl n in
    for i = 1 to iterations do
      ignore (Sys.opaque_identity (Hashtbl.fold (fun c k v -> c + k + v) h 0))
    done

let hashtbl_add sized iterations =
  let h = Hashtbl.create (if sized then iterations else 1) in
    for i = 1 to iterations do
      Hashtbl.add h i i
    done

let hashtbl_add_duplicate iterations =
  let h = Hashtbl.create 1 in
    for i = 1 to iterations do
      Hashtbl.add h i i;
      Hashtbl.add h i i
    done

let hashtbl_remove iterations =
  for _ = 1 to (iterations/n + 1) do
  let h = create_hashtbl n in
    for i = 1 to n do
      Hashtbl.remove h i
    done
  done

let hashtbl_find iterations =
  let h = create_hashtbl n in
  for i = 1 to iterations do
    ignore (Sys.opaque_identity (Hashtbl.find_opt h i))
  done

let hashtbl_filter_map iterations =
  let h = create_hashtbl n in
  for i = 1 to iterations do
    Hashtbl.filter_map_inplace (fun a b -> Some(2 * b)) h
  done

let () =
  let int_tbl_replace1, int_tbl_find1 =
    gen_test_int_replace_and_find n (Hashtbl.create (2 * n))
  in
  let int_tbl_replace2, int_tbl_find2 =
    gen_test_int_replace_and_find_int_hash n (IntHashtbl.create (2 * n))
  in
  let caml_hashtbl_hash () =
    for i = 0 to n - 1 do
      let (_ : int) = Hashtbl.hash i in
      ()
    done
  in
  let iterations = int_of_string Sys.argv.(2) in
  match Sys.argv.(1) with
  | "int_replace1" ->
      for _ = 0 to iterations do
        Sys.opaque_identity (int_tbl_replace1 ())
      done
  | "int_find1" ->
      for _ = 0 to iterations do
        Sys.opaque_identity (int_tbl_find1 ())
      done
  | "int_replace2" ->
      for _ = 0 to iterations do
        Sys.opaque_identity (int_tbl_replace2 ())
      done
  | "int_find2" ->
      for _ = 0 to iterations do
        Sys.opaque_identity (int_tbl_find2 ())
      done
  | "caml_hash" ->
      for _ = 0 to iterations do
        Sys.opaque_identity (caml_hashtbl_hash ())
      done
  | "hashtbl_iter" ->
      hashtbl_iter iterations
  | "hashtbl_fold" ->
      hashtbl_fold iterations
  | "hashtbl_add_resizing" ->
      hashtbl_add false iterations
  | "hashtbl_add_sized" ->
      hashtbl_add true iterations
  | "hashtbl_add_duplicate" ->
      hashtbl_add_duplicate iterations
  | "hashtbl_remove" ->
      hashtbl_remove iterations
  | "hashtbl_find" ->
      hashtbl_find iterations
  | "hashtbl_filter_map" ->
      hashtbl_filter_map iterations
  | _ ->
      ()
