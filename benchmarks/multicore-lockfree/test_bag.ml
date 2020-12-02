let num_entries = try int_of_string Sys.argv.(1) with _ -> 1000000
let read_percent = try int_of_string Sys.argv.(2) with _ -> 50

module Bag = Lockfree.Bag

let bag = Bag.create ()

let add_or_remove_entries n () =
  for _ = 1 to n do
  let r = Random.int 100 in
  if (r > read_percent) then
    Bag.push bag (Random.int n)
  else 
    Bag.pop bag |> ignore
  done
  
let _ = 
  add_or_remove_entries num_entries ()