let list_length = int_of_string Sys.argv.(1)
let iterations = int_of_string Sys.argv.(2)

let rec add_lazy l n =
  if n == 0 then
    l
  else
    let new_head = lazy (1 + (Lazy.force (List.hd l))) in
    new_head :: add_lazy l (n-1)

let create_list () =
  add_lazy [Lazy.from_val 0] list_length

let () = 
  for _ = 0 to iterations do
    let l = create_list() in
    let list_head = List.hd l in
    ignore(Lazy.force list_head)
  done
