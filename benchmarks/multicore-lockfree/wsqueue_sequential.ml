module WSQueue = Lockfree.WSQueue

let num_threads = int_of_string Sys.argv.(1)
let num_items = int_of_string Sys.argv.(2)

let () = Random.init 42

let loop_and_drain_queue wsq_array thread_num () =
  let rec drain_queue wsq_array thread_num =
    let q_num = Random.int num_threads in
      let wsq = Array.get wsq_array q_num in
        let item = if q_num == thread_num then
          WSQueue.pop wsq
        else
          WSQueue.steal wsq
        in match item with
        | None when q_num == thread_num -> ()
        | _ -> drain_queue wsq_array thread_num
  in drain_queue wsq_array thread_num

let make_and_populate_wsq _ =
  let q = WSQueue.create () in
    for i = 1 to num_items do
      WSQueue.push q i
    done; q

let () =
  for _ = 1 to 32 do
    let wsq_array = Array.init num_threads make_and_populate_wsq in
      let rec spawn_thread n =
          match n with
          | -1 -> []
          | _ -> (Domain.spawn (loop_and_drain_queue wsq_array n)) :: spawn_thread (n-1)
      in
          ignore(List.map (fun d -> Domain.join d) (spawn_thread (num_threads-1)))
  done
