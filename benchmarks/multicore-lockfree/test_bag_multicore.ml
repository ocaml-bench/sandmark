let num_domains = try int_of_string Sys.argv.(1) with _ -> 4
let num_entries = try int_of_string Sys.argv.(2) with _ -> 1000000
let read_percent = try int_of_string Sys.argv.(3) with _ -> 50
let entries_per_dom = num_entries / num_domains

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
  let d = Array.init (num_domains - 1) (fun _ -> Domain.spawn(add_or_remove_entries entries_per_dom)) in
  add_or_remove_entries entries_per_dom ();
  Array.iter Domain.join d