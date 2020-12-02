let num_domain = try int_of_string Sys.argv.(1) with _ -> 4
let n = try int_of_string Sys.argv.(2) with _ -> 10000
let read_percent = try int_of_string Sys.argv.(3) with _ -> 50
let items_per_dom = n / num_domain

module List = Lockfree.List
let k = Domain.DLS.new_key Random.State.make_self_init
let l = List.create ()

let push_or_pop n () =
  let state = Domain.DLS.get k in
  for i = 1 to n do
    let r = Random.State.int state 100 in
    if (r > read_percent) then
      List.push l i
    else
      List.pop l |> ignore
  done

let _ =
  let d = Array.init (num_domain - 1) (fun _ -> Domain.spawn(push_or_pop items_per_dom)) in
  push_or_pop items_per_dom ();
  Array.iter Domain.join d