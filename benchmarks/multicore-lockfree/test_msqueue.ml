module Msqueue = Lockfree.MSQueue

let num_items = try int_of_string Sys.argv.(1) with _ -> 10000000
let read_percent = try int_of_string Sys.argv.(2) with _ -> 50

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
  enqueue_or_dequeue queue num_items ()