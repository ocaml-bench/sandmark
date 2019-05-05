let num_domains = 16
let tasks_to_spawn = 10_000
let list_length = 10_000

let rec create_list f n = match n with
  | 0 -> []
  | _ -> (f n) :: (create_list f (n-1))
  
let start_task () =
    for n = 0 to tasks_to_spawn do
        Ms_sched.fork (fun _ -> ignore (Sys.opaque_identity create_list (fun n -> (n+1)) list_length))
    done;
    Ms_sched.exit ()

let () =
    Ms_sched.start num_domains start_task |> ignore
