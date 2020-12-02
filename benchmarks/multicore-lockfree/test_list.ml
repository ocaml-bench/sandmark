let n = try int_of_string Sys.argv.(1) with _ -> 10000
let read_percent = try int_of_string Sys.argv.(2) with _ -> 50

module List = Lockfree.List

let l = List.create ()

let push_or_pop n () =
  for i = 1 to n do
    let r = Random.int 100 in
    if (r > read_percent) then
      List.push l i
    else
      List.pop l |> ignore
  done

let _ =
  push_or_pop n ()