module Hash = Lockfree.Hash

let threads = int_of_string Sys.argv.(1)
let read_percent = int_of_string Sys.argv.(2)
let num_opers = int_of_string Sys.argv.(3)

let () = Random.init 42

let h = Hash.create()

let do_stuff_with_hash () =
  for _ = 1 to num_opers do
    if Random.int 100 > read_percent then
        Hash.add h (Random.int 1000) 0
    else
        ignore(Hash.find h (Random.int 1000))
  done

let () =
    let rec spawn_thread n =
        match n with
        | 0 -> []
        | _ -> (Domain.spawn do_stuff_with_hash) :: spawn_thread (n-1)
    in
        ignore(List.map (fun d -> Domain.join d) (spawn_thread threads))
