external test_no_args_alloc : unit -> int = "test_no_args_alloc"
external test_no_args_noalloc : unit -> int = "test_no_args_no_alloc" [@@noalloc]
external test_few_args_alloc : int -> int = "test_few_args_alloc"
external test_few_args_noalloc : int -> int = "test_few_args_no_alloc" [@@noalloc]
external test_many_args_alloc : int -> int -> int -> int -> int -> int -> int -> int = "test_many_args_noalloc_bc" "test_many_args_alloc_nc"
external test_many_args_noalloc : int -> int -> int -> int -> int -> int -> int -> int = "test_many_args_noalloc_bc" "test_many_args_noalloc_nc" [@@noalloc]

let test_name = Sys.argv.(1)

let run_many_times f =
    for _ = 1 to 20000 do
        ignore(f())
    done

let () = match test_name with
    | "test_no_args_alloc" -> run_many_times (fun _ -> test_no_args_alloc())
    | "test_no_args_noalloc" -> run_many_times (fun _ -> test_no_args_noalloc())
    | "test_few_args_alloc" -> run_many_times (fun _ -> test_few_args_alloc 1)
    | "test_few_args_noalloc" -> run_many_times (fun _ -> test_few_args_noalloc 2)
    | "test_many_args_alloc" -> run_many_times (fun _ -> test_many_args_alloc 1 2 3 4 5 6 7)
    | "test_many_args_noalloc" -> run_many_times (fun _ -> test_many_args_noalloc 1 2 3 4 5 6 7)
    | _ -> failwith "unexpected test name"
