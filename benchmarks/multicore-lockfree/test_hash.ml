module Hash = Lockfree.Hash_Custom(struct
  let load = 3;;
  let nb_bucket = 526;;
  let hash_function i = i;;
end)

let read_percent = try int_of_string Sys.argv.(2) with _ -> 50
let num_opers = try int_of_string Sys.argv.(1) with _ -> 1000000

let () = Random.init 42

let h = Hash.create()

let add_or_remove_entries ht n () =
    for i = 1 to n do 
      let r = Random.int 100 in
      let key = Random.int n in
      if (r > read_percent) then
        Hash.add ht key i
      else
        Hash.find ht key |> ignore
      done

let () =
    add_or_remove_entries h num_opers ()