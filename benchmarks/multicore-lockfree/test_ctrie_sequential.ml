let threads = 1
let insert_percent = int_of_string Sys.argv.(1)
let num_opers = int_of_string Sys.argv.(2)

let () = Random.init 42

let tree = Ctrie.empty ()

let work () =
  for _ = 1 to num_opers do
    if Random.int 100 > insert_percent then
      ignore (Ctrie.mem (Random.int 1000000) tree)
    else
      Ctrie.insert (Random.int 1000000) 0 tree 
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
