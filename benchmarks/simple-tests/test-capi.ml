let test_name = Sys.argv.(1)

let run_many_times f =
  for _ = 1 to 20000 do
    ignore(Sys.opaque_identity f ())
  done

let () = match test_name with
    | "test_no_args_alloc" -> run_many_times (fun _ -> test_no_args_alloc())
    | "test_no_args_noalloc" -> run_many_times (fun _ -> test_no_args_noalloc())
    | "test_few_args_alloc" -> run_many_times (fun _ -> test_few_args_alloc 1)
    | "test_few_args_noalloc" -> run_many_times (fun _ -> test_few_args_noalloc 2)
    | "test_many_args_alloc" -> run_many_times (fun _ -> test_many_args_alloc 1 2 3 4 5 6 7)
    | "test_many_args_noalloc" -> run_many_times (fun _ -> test_many_args_noalloc 1 2 3 4 5 6 7)
    | _ -> failwith "unexpected test name"
