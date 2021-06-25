module Msqueue = Lockfree.MSQueue

let num_domains = try int_of_string Sys.argv.(1) with _ -> 4
let num_items = try int_of_string Sys.argv.(2) with _ -> 10000000
let read_percent = try int_of_string Sys.argv.(3) with _ -> 50
let items_per_domain = num_items / num_domains

let enqueue_or_dequeue msq n () =
  for i = 1 to n do
    let r = Random.int 100 in
    if (r > read_percent) then
      Msqueue.push msq i
    else
      Msqueue.pop msq |> ignore
  done

let queue = Msqueue.create ()

let _ =
  let d = Array.init (num_domains - 1) (fun _ -> Domain.spawn(enqueue_or_dequeue queue items_per_domain)) in
  enqueue_or_dequeue queue items_per_domain ();
  Array.iter Domain.join d