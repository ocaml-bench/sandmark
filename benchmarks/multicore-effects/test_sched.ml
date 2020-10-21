let num_domains = int_of_string Sys.argv.(1)

let tasks_to_spawn = int_of_string Sys.argv.(2)

let list_length = int_of_string Sys.argv.(3)

let rec create_list f n =
  match n with 0 -> [] | _ -> f n :: create_list f (n - 1)

let start_task () =
  for _n = 1 to tasks_to_spawn do
    Ms_sched.fork (fun _ ->
        ignore (Sys.opaque_identity create_list (fun n -> n + 1) list_length)
    )
  done ;
  Ms_sched.exit ()

let () = ignore(Ms_sched.start num_domains start_task)
