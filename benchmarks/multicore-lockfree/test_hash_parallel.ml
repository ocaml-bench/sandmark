let num_domains = try int_of_string Sys.argv.(1) with _ -> 4
let num_entries = try int_of_string Sys.argv.(2) with _ -> 100000
let entries_per_dom = num_entries / num_domains
let read_percent = try int_of_string Sys.argv.(3) with _ -> 50

module Hash = Lockfree.Hash_Custom(struct
  let load = 3;;
  let nb_bucket = 526;;
  let hash_function i = i;;
end)

let k = Domain.DLS.new_key Random.State.make_self_init

let add_or_remove_entries ht n () =
  let state = Domain.DLS.get k in
  for i = 1 to n do 
    let r = Random.State.int state 100 in
    let key = Random.State.int state n in
    if (r > read_percent) then
      Hash.add ht key i
    else
      Hash.find ht key |> ignore
    done
    
let () =
  let ht = Hash.create () in
  let d = Array.init (num_domains - 1) (fun _ -> Domain.spawn(add_or_remove_entries ht entries_per_dom)) in
  add_or_remove_entries ht entries_per_dom ();
  Array.iter Domain.join d