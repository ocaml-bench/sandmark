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

let () =
  let n = 1_000_000 in
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
  | _ ->
      ()
