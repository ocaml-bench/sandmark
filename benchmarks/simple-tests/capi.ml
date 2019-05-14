let test_name = Sys.argv.(1)

let run_many_times f =
    let n = try int_of_string(Array.get Sys.argv 2) with _ -> 1_000_000_000 in
    for _ = 1 to n do
      ignore(Sys.opaque_identity f ())
    done

let () = match test_name with
    | "test_no_args_alloc" -> run_many_times (fun _ -> Ocamlcapi.test_no_args_alloc())
    | "test_no_args_noalloc" -> run_many_times (fun _ -> Ocamlcapi.test_no_args_noalloc())
    | "test_few_args_alloc" -> run_many_times (fun _ -> Ocamlcapi.test_few_args_alloc 1)
    | "test_few_args_noalloc" -> run_many_times (fun _ -> Ocamlcapi.test_few_args_noalloc 2)
    | "test_many_args_alloc" -> run_many_times (fun _ -> Ocamlcapi.test_many_args_alloc 1 2 3 4 5 6 7)
    | "test_many_args_noalloc" -> run_many_times (fun _ -> Ocamlcapi.test_many_args_noalloc 1 2 3 4 5 6 7)
    | _ -> failwith "unexpected test name"
