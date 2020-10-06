let threads = int_of_string Sys.argv.(1)
let insert_percent = int_of_string Sys.argv.(2)
let num_opers = int_of_string Sys.argv.(3) / threads

let state_key = Domain.DLS.new_key Random.State.make_self_init

let tree = Ctrie.empty ()

let work () =
  let state = Domain.DLS.get state_key in
  let rand_int n = Random.State.int state n in
  for _ = 1 to num_opers do
    if rand_int 100 > insert_percent then
      ignore (Ctrie.mem (rand_int 1000000) tree)
    else
      Ctrie.insert (rand_int 1000000) 0 tree 
  done

let () =
    let rec spawn_thread n =
        match n with
        | 0 -> []
        | _ -> (Domain.spawn work) :: spawn_thread (n-1)
    in
    let threads = spawn_thread (threads - 1) in
    ignore (work ());
    ignore (List.map (fun d -> Domain.join d) threads)
